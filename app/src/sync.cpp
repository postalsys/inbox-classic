// Settings sync's windows (Tools > Options > Sync): Set Up Sync, two steps in one window as a small wizard (where the
// vault is, looked at by the core; then the passphrase that starts a new one or joins the one there, the name of this
// computer and what to sync), Computers (the vault's, read by the core, each but this one with Remove) and History (the
// edits another computer's replaced, each with Restore, and the restore points, each opened in the import window).
// The core does the work and words what is shown (pe_settings_sync_*); these windows show it and hand back what is
// chosen.
#include "app.h"
#include "settings.h"

#include <shellapi.h>
#include <windowsx.h>

#include <algorithm>
#include <atomic>
#include <thread>

namespace {

const wchar_t* kSetUpClass = L"InboxClassicSyncSetUp";
const wchar_t* kComputersClass = L"InboxClassicSyncComputers";
const wchar_t* kHistoryClass = L"InboxClassicSyncHistory";

// the probe's answer looked for again while it is not there (the core's SettingsSyncChanged looks at once)
constexpr UINT_PTR kProbeTimer = 1;
// SyncWindowsChanged to an open window: look at what the core has now
constexpr UINT WM_SYNC_CHANGED = WM_APP + 70;

constexpr int kRow = 23;
constexpr int kButton = 25;
constexpr int kGap = 6;
constexpr int kCheckIndent = 18;

// the problem lines, in the red of an error
constexpr COLORREF kProblemColor = RGB(0xC0, 0x00, 0x00);

HWND Item(HWND dialog, int id) {
    return GetDlgItem(dialog, id);
}

// a window with group boxes painted under its controls: a group box leaves its inside to the window, which must not
// clip it away
void PaintUnderChildren(HWND dialog) {
    SetWindowLongPtrW(dialog, GWL_STYLE, GetWindowLongPtrW(dialog, GWL_STYLE) & ~static_cast<LONG_PTR>(WS_CLIPCHILDREN));
}

bool Checked(HWND dialog, int id) {
    return Button_GetCheck(Item(dialog, id)) == BST_CHECKED;
}

int Wrapped(const std::wstring& text, int width) {
    return static_cast<int>(MeasureText(text, width, DT_NOPREFIX | DT_EDITCONTROL).cy);
}

// what is typed in a field, trimmed, as UTF-8
std::string Field(HWND dialog, int id) {
    std::wstring text = GetWindowString(Item(dialog, id));
    size_t start = text.find_first_not_of(L" \t"), end = text.find_last_not_of(L" \t");
    return start == std::wstring::npos ? std::string() : core::Narrow(text.substr(start, end - start + 1));
}

// the name of this computer as Windows shows it (its host name, as it was typed)
std::wstring ComputerName() {
    wchar_t name[256] = L"";
    DWORD size = 256;
    if (GetComputerNameExW(ComputerNameDnsHostname, name, &size) && name[0]) {
        return name;
    }
    size = 256;
    return GetComputerNameW(name, &size) ? name : L"";
}

// the What to sync check boxes in the order of core/settings.toml, and which starts the second column
std::vector<const PeSettingInfo*> SyncSwitches() {
    std::vector<const PeSettingInfo*> switches;
    for (const PeSettingInfo& info : kSettings) {
        if (info.group == PE_SETTINGS_GROUP_SYNC_WHAT && info.kind == PE_SETTING_KIND_SWITCH) {
            switches.push_back(&info);
        }
    }
    return switches;
}

size_t SecondColumn(const std::vector<const PeSettingInfo*>& switches) {
    for (size_t i = switches.size() / 2; i < switches.size(); i++) {
        if (!switches[i]->hasParent) {
            return i;
        }
    }
    return switches.size();
}

int WhatId(PeSetting setting) {
    return IDC_SYNC_WHAT + (setting - PE_SETTING_SYNC_ACCOUNTS);
}

// ---- Set Up Sync ----

// a place as the core takes it, its strings kept while it is looked at
struct Place {
    bool folder = true;
    std::string path, endpoint, region, bucket, prefix, access, secret;

    PeSyncPlace View() const {
        auto text = [](const std::string& s) { return s.empty() ? nullptr : s.c_str(); };
        PeSyncPlace place = {};
        place.kind = folder ? PE_SYNC_PLACE_KIND_FOLDER : PE_SYNC_PLACE_KIND_BUCKET;
        place.path = text(path);
        place.endpoint = text(endpoint);
        place.region = text(region);
        place.bucket = text(bucket);
        place.prefix = text(prefix);
        place.access_key = text(access);
        return place;
    }

    void Wipe() {
        ::Wipe(secret);
    }
};

struct SetUpState {
    PeCore* core = nullptr;
    HWND dialog = nullptr;
    bool done = false;
    bool on = false;
    // the second step is shown (its controls made for it, gone with Back), and whether it joins a vault there
    bool second = false;
    bool join = false;
    bool probing = false;
    Place place;
    // the first step's controls; the second's
    std::vector<HWND> first;
    std::vector<HWND> made;
    // where the steps' controls go, and how wide the window is
    int pad = 0;
    int width = 0;
    int top = 0;
    // the control the second step's go after, in the Tab order
    HWND before = nullptr;
};

SetUpState* g_setUp = nullptr;

const std::initializer_list<int> kSecretFields = {IDC_SYNC_SECRET_KEY, IDC_SYNC_PASSPHRASE, IDC_SYNC_PASSPHRASE_AGAIN};

// a problem said under the fields in red, or none
void ShowProblem(SetUpState& state, const std::wstring& text) {
    HWND problem = Item(state.dialog, IDC_SYNC_PROBLEM);
    SetWindowTextW(problem, text.c_str());
    ShowWindow(problem, text.empty() ? SW_HIDE : SW_SHOW);
}

// the place typed, false while something it needs is missing
bool ReadPlace(SetUpState& state) {
    HWND dialog = state.dialog;
    Place& place = state.place;
    place.Wipe();
    place = Place{};
    place.folder = Checked(dialog, IDC_SYNC_KIND_FOLDER);
    if (place.folder) {
        place.path = Field(dialog, IDC_SYNC_FOLDER);
        return !place.path.empty();
    }
    place.endpoint = Field(dialog, IDC_SYNC_ENDPOINT);
    place.region = Field(dialog, IDC_SYNC_REGION);
    place.bucket = Field(dialog, IDC_SYNC_BUCKET);
    std::string prefix = Field(dialog, IDC_SYNC_PREFIX);
    size_t start = prefix.find_first_not_of('/'), end = prefix.find_last_not_of('/');
    place.prefix = start == std::string::npos ? "" : prefix.substr(start, end - start + 1);
    place.access = Field(dialog, IDC_SYNC_ACCESS_KEY);
    place.secret = ReadSecret(Item(dialog, IDC_SYNC_SECRET_KEY));
    return !place.endpoint.empty() && !place.bucket.empty() && !place.access.empty() && !place.secret.empty();
}

// the first step as the kind chosen: the folder's field or the bucket's, Next on once the place is complete
void UpdateFirst(SetUpState& state) {
    bool folder = Checked(state.dialog, IDC_SYNC_KIND_FOLDER);
    for (int id = IDC_SYNC_FOLDER; id <= IDC_SYNC_SECRET_KEY; id++) {
        bool shown = (id == IDC_SYNC_FOLDER || id == IDC_SYNC_CHOOSE) == folder;
        ShowWindow(Item(state.dialog, id), shown ? SW_SHOW : SW_HIDE);
        // the label before the field (Choose has none of its own)
        if (id != IDC_SYNC_CHOOSE) {
            ShowWindow(GetWindow(Item(state.dialog, id), GW_HWNDPREV), shown ? SW_SHOW : SW_HIDE);
        }
    }
    bool complete = ReadPlace(state);
    state.place.Wipe();
    EnableWindow(Item(state.dialog, IDOK), complete && !state.probing);
}

// the second step's Turn On Sync on once a passphrase is typed (twice and as the core takes it, to start) and the
// computer has a name
void UpdateSecond(SetUpState& state) {
    HWND dialog = state.dialog;
    bool typed = false;
    if (state.join) {
        typed = GetWindowTextLengthW(Item(dialog, IDC_SYNC_PASSPHRASE)) > 0;
    } else {
        typed = ShowPassphraseFeedback(dialog, IDC_SYNC_PASSPHRASE, IDC_SYNC_PASSPHRASE_AGAIN, IDC_SYNC_FEEDBACK);
    }
    for (const PeSettingInfo* info : SyncSwitches()) {
        if (info->hasParent) {
            EnableWindow(Item(dialog, WhatId(info->setting)), Checked(dialog, WhatId(info->dependsOn)));
        }
    }
    EnableWindow(Item(dialog, IDOK), typed && !Field(dialog, IDC_SYNC_NAME).empty());
}

// a control of the second step, after the one made before it in the Tab order
HWND Make(SetUpState& state, const wchar_t* className, const std::wstring& text, DWORD style, int id, const RECT& bounds,
          DWORD exStyle = 0) {
    HWND control = CreateChild(state.dialog, className, text.c_str(), style, id, bounds, exStyle);
    SetWindowPos(control, state.before, 0, 0, 0, 0, SWP_NOMOVE | SWP_NOSIZE | SWP_NOACTIVATE);
    state.before = control;
    state.made.push_back(control);
    return control;
}

// the What to sync group box at `top` from `left` to `right`, its check boxes in two columns (each under the one it
// depends on, indented), its note under them: its height. Made only with `state`, else measured
int WhatGroup(SetUpState* state, int left, int top, int right) {
    std::vector<const PeSettingInfo*> switches = SyncSwitches();
    size_t second = SecondColumn(switches);
    int margin = Scale(10), inner = right - left - 2 * margin, column = (inner - Scale(kGap * 2)) / 2;
    if (state) {
        Make(*state, L"BUTTON", core::T(PE_TEXT_UI_SYNC_WHAT), BS_GROUPBOX, 0, {left, top, right, top});
    }
    HWND box = state ? state->before : nullptr;
    int y = top + Scale(20), columnTop = y, firstEnd = 0;
    for (size_t i = 0; i < switches.size(); i++) {
        const PeSettingInfo* info = switches[i];
        if (i == second) {
            firstEnd = y;
            y = columnTop;
        }
        int x = left + margin + (i >= second ? column + Scale(kGap * 2) : 0) + (info->hasParent ? Scale(kCheckIndent) : 0);
        int x1 = left + margin + (i >= second ? inner : column);
        std::wstring text = core::T(info->label);
        int height = std::max(Scale(16), static_cast<int>(MeasureText(text, x1 - x - Scale(kCheckIndent + 2)).cy) + Scale(2));
        if (state) {
            HWND check = Make(*state, L"BUTTON", text, WS_TABSTOP | BS_AUTOCHECKBOX | BS_MULTILINE | BS_TOP, WhatId(info->setting),
                              {x, y, x1, y + height});
            Button_SetCheck(check, BST_CHECKED);
        }
        y += height + Scale(4);
    }
    y = std::max(y, firstEnd) + Scale(2);
    std::wstring note = core::T(PE_TEXT_UI_SYNC_WHAT_NOTE);
    int noteHeight = Wrapped(note, inner);
    if (state) {
        Make(*state, L"STATIC", note, SS_LEFT | SS_NOPREFIX | SS_EDITCONTROL, 0, {left + margin, y, right - margin, y + noteHeight});
    }
    y += noteHeight + margin;
    if (box) {
        // made while the window shows: drawn at its size
        MoveWindow(box, left, top, right - left, y - top, TRUE);
    }
    return y - top;
}

// the second step from `state.top` down: what it is (Start Sync or Join Sync), the passphrase (twice to start, with
// what the core says of it), the name of this computer (with the note of joining), What to sync; its height. Made only
// with `make`, else measured
int SecondStep(SetUpState& state, bool join, bool make) {
    int pad = state.pad, width = state.width, row = Scale(kRow);
    std::wstring note = core::T(join ? PE_TEXT_UI_SYNC_JOIN_NOTE : PE_TEXT_UI_SYNC_START_NOTE);
    // the fields' labels without their letters, as Export's: T is Turn On Sync's here
    std::wstring passphrase = core::Plain(PE_TEXT_UI_KEYS_PASSPHRASE), again = core::Plain(PE_TEXT_UI_KEYS_PASSPHRASE_AGAIN);
    std::wstring name = core::T(PE_TEXT_UI_SYNC_NAME), merge = core::T(PE_TEXT_UI_SYNC_MERGE_NOTE);
    int labelWidth = LabelWidth({passphrase, again, name}, 90);
    int field = pad + labelWidth;
    int y = state.top;
    int noteHeight = Wrapped(note, width - 2 * pad);
    if (make) {
        Make(state, L"STATIC", note, SS_LEFT | SS_NOPREFIX | SS_EDITCONTROL, IDC_SYNC_NOTE, {pad, y, width - pad, y + noteHeight});
    }
    y += noteHeight + Scale(10);
    auto fieldRow = [&](const std::wstring& label, int id, DWORD style) {
        if (make) {
            Make(state, L"STATIC", label, SS_LEFT, 0, {pad, y + Scale(3), field - Scale(4), y + row});
            Make(state, L"EDIT", L"", WS_TABSTOP | ES_AUTOHSCROLL | style, id, {field, y, width - pad, y + row}, WS_EX_CLIENTEDGE);
        }
        y += row + Scale(kGap);
    };
    fieldRow(passphrase, IDC_SYNC_PASSPHRASE, ES_PASSWORD);
    if (!join) {
        fieldRow(again, IDC_SYNC_PASSPHRASE_AGAIN, ES_PASSWORD);
        // room for the longest of what the core says, so nothing moves while typing
        core::String longest(pe_passphrase_feedback_longest());
        std::wstring feedback = longest ? Text(longest.get()) : L"";
        int warning = GetSystemMetrics(SM_CXSMICON) + Scale(6);
        int height = std::max(GetSystemMetrics(SM_CYSMICON), static_cast<int>(MeasureText(feedback, width - pad - field - warning).cy));
        if (make) {
            WarningNote(state.dialog, IDC_SYNC_FEEDBACK, feedback, field, y, width - pad);
            // the sign and the words, after the fields in the Tab order (neither takes the focus)
            HWND words = Item(state.dialog, IDC_SYNC_FEEDBACK), sign = GetWindow(words, GW_HWNDPREV);
            for (HWND made : {sign, words}) {
                SetWindowPos(made, state.before, 0, 0, 0, 0, SWP_NOMOVE | SWP_NOSIZE | SWP_NOACTIVATE);
                state.before = made;
                state.made.push_back(made);
            }
        }
        y += height + Scale(kGap);
    }
    fieldRow(name, IDC_SYNC_NAME, 0);
    if (join) {
        int mergeHeight = Wrapped(merge, width - pad - field);
        if (make) {
            Make(state, L"STATIC", merge, SS_LEFT | SS_NOPREFIX | SS_EDITCONTROL, IDC_SYNC_MERGE_NOTE, {field, y, width - pad, y + mergeHeight});
        }
        y += mergeHeight + Scale(kGap);
    }
    y += Scale(6);
    if (make) {
        y += WhatGroup(&state, pad, y, width - pad);
    } else {
        y += WhatGroup(nullptr, pad, y, width - pad);
    }
    return y - state.top;
}

// the step shown: the first one's controls, or the second's made for it; Back and the default button's words with it
void ShowStep(SetUpState& state, bool second) {
    state.second = second;
    for (HWND control : state.first) {
        ShowWindow(control, second ? SW_HIDE : SW_SHOW);
    }
    if (!second) {
        UpdateFirst(state);
    }
    ShowWindow(Item(state.dialog, IDC_SYNC_BACK), second ? SW_SHOW : SW_HIDE);
    std::wstring words = second ? core::T(PE_TEXT_UI_SYNC_TURN_ON) : core::T(PE_TEXT_WIN_NEXT);
    SetWindowTextW(Item(state.dialog, IDOK), words.c_str());
    ShowProblem(state, L"");
}

// back to the first step: the second's controls gone, the passphrase typed wiped first
void Back(SetUpState& state) {
    WipeFields(state.dialog, {IDC_SYNC_PASSPHRASE, IDC_SYNC_PASSPHRASE_AGAIN});
    for (HWND control : state.made) {
        DestroyWindow(control);
    }
    state.made.clear();
    ShowStep(state, false);
    SetFocus(Item(state.dialog, Checked(state.dialog, IDC_SYNC_KIND_FOLDER) ? IDC_SYNC_FOLDER : IDC_SYNC_ENDPOINT));
}

// the place looked at: Start Sync for an empty one, Join Sync for one with a vault in it
void GoToSecond(SetUpState& state, bool join) {
    state.join = join;
    state.before = Item(state.dialog, IDC_SYNC_PROBLEM);
    SecondStep(state, join, true);
    ShowStep(state, true);
    SetWindowTextW(Item(state.dialog, IDC_SYNC_NAME), ComputerName().c_str());
    UpdateSecond(state);
    SetFocus(Item(state.dialog, IDC_SYNC_PASSPHRASE));
}

// what the probe found, once it has: a problem said, or the second step
void CheckProbe(SetUpState& state) {
    if (!state.probing) {
        return;
    }
    char* error = nullptr;
    PeSyncProbe found = pe_settings_sync_probe(state.core, &error);
    if (found == PE_SYNC_PROBE_WAITING) {
        core::String unused(error);
        return;
    }
    KillTimer(state.dialog, kProbeTimer);
    state.probing = false;
    SetCursor(LoadCursorW(nullptr, IDC_ARROW));
    if (found == PE_SYNC_PROBE_PROBLEM) {
        ShowProblem(state, ReasonText(error, PE_TEXT_UI_UNKNOWN_REASON));
        UpdateFirst(state);
        return;
    }
    core::String unused(error);
    GoToSecond(state, found == PE_SYNC_PROBE_VAULT);
}

// Next: the place looked at on the core's runtime, the answer awaited
void Probe(SetUpState& state) {
    if (!ReadPlace(state)) {
        state.place.Wipe();
        return;
    }
    ShowProblem(state, L"");
    state.probing = true;
    EnableWindow(Item(state.dialog, IDOK), FALSE);
    SetCursor(LoadCursorW(nullptr, IDC_WAIT));
    PeSyncPlace place = state.place.View();
    pe_settings_sync_probe_start(state.core, &place, state.place.folder ? nullptr : state.place.secret.c_str());
    SetTimer(state.dialog, kProbeTimer, 200, nullptr);
}

// Turn On Sync: on with what the second step holds, the window closed; or why not, in red
void TurnOn(SetUpState& state) {
    HWND dialog = state.dialog;
    PeSyncChoice choice = pe_sync_choice_default();
    for (const PeSettingInfo* info : SyncSwitches()) {
        if (bool* flag = SyncChoiceFlag(choice, info->setting)) {
            *flag = Checked(dialog, WhatId(info->setting));
        }
    }
    std::string passphrase = ReadSecret(Item(dialog, IDC_SYNC_PASSPHRASE));
    std::string name = Field(dialog, IDC_SYNC_NAME);
    PeSyncPlace place = state.place.View();
    const char* secret = state.place.folder ? nullptr : state.place.secret.c_str();
    char* error = nullptr;
    bool on = false;
    RunWaiting(dialog, [&] { on = pe_settings_sync_turn_on(state.core, &place, secret, passphrase.c_str(), name.c_str(), choice, &error); });
    Wipe(passphrase);
    if (!on) {
        ShowProblem(state, ReasonText(error, PE_TEXT_UI_UNKNOWN_REASON));
        UpdateSecond(state);
        SetFocus(Item(dialog, IDC_SYNC_PASSPHRASE));
        return;
    }
    core::String unused(error);
    state.on = true;
    state.done = true;
    SayInStatusBar(core::T(PE_TEXT_UI_SYNC_ON));
}

void Close(SetUpState& state) {
    KillTimer(state.dialog, kProbeTimer);
    WipeFields(state.dialog, kSecretFields);
    state.done = true;
}

void SetUpCommand(SetUpState& state, int id, int code) {
    switch (id) {
    case IDOK:
        // Enter with the button off does nothing
        if (!IsWindowEnabled(Item(state.dialog, IDOK))) {
            return;
        }
        if (state.second) {
            TurnOn(state);
        } else {
            Probe(state);
        }
        return;
    case IDCANCEL:
        Close(state);
        return;
    case IDC_SYNC_BACK:
        Back(state);
        return;
    case IDC_SYNC_CHOOSE: {
        std::wstring folder = FolderDialog(state.dialog, core::Plain(PE_TEXT_UI_SYNC_CHOOSE_FOLDER_TITLE).c_str());
        if (!folder.empty()) {
            SetWindowTextW(Item(state.dialog, IDC_SYNC_FOLDER), folder.c_str());
        }
        return;
    }
    }
    if (code != EN_CHANGE && code != BN_CLICKED) {
        return;
    }
    if (state.second) {
        UpdateSecond(state);
        return;
    }
    if (id == IDC_SYNC_KIND_FOLDER || id == IDC_SYNC_KIND_BUCKET) {
        ShowProblem(state, L"");
    }
    UpdateFirst(state);
}

LRESULT CALLBACK SetUpProc(HWND hwnd, UINT message, WPARAM wParam, LPARAM lParam) {
    auto* state = reinterpret_cast<SetUpState*>(GetWindowLongPtrW(hwnd, GWLP_USERDATA));
    if (!state) {
        return DefWindowProcW(hwnd, message, wParam, lParam);
    }
    switch (message) {
    case WM_COMMAND:
        SetUpCommand(*state, LOWORD(wParam), HIWORD(wParam));
        return 0;
    case WM_TIMER:
    case WM_SYNC_CHANGED:
        CheckProbe(*state);
        return 0;
    case WM_SETCURSOR:
        if (state->probing) {
            SetCursor(LoadCursorW(nullptr, IDC_APPSTARTING));
            return TRUE;
        }
        break;
    case WM_CLOSE:
        Close(*state);
        return 0;
    case WM_CTLCOLORSTATIC: {
        LRESULT brush = ButtonFaceColor(reinterpret_cast<HDC>(wParam));
        if (reinterpret_cast<HWND>(lParam) == Item(hwnd, IDC_SYNC_PROBLEM)) {
            SetTextColor(reinterpret_cast<HDC>(wParam), kProblemColor);
        }
        return brush;
    }
    }
    return DefWindowProcW(hwnd, message, wParam, lParam);
}

// the first step from `top` down: Where to keep it (A folder or S3-compatible storage, each with its note), then the
// folder with Choose or the bucket's six fields in the same place; its height
int FirstStep(SetUpState& state) {
    HWND dialog = state.dialog;
    int pad = state.pad, width = state.width, row = Scale(kRow), margin = Scale(10), indent = Scale(kCheckIndent);
    auto keep = [&](HWND control) {
        state.first.push_back(control);
        return control;
    };
    int y = state.top;
    HWND box = keep(CreateChild(dialog, L"BUTTON", core::T(PE_TEXT_UI_SYNC_WHERE).c_str(), BS_GROUPBOX, 0, {pad, y, width - pad, y}));
    int inner = y + Scale(20);
    const std::pair<int, std::pair<PeText, PeText>> kinds[] = {
        {IDC_SYNC_KIND_FOLDER, {PE_TEXT_UI_SYNC_FOLDER, PE_TEXT_UI_SYNC_FOLDER_NOTE}},
        {IDC_SYNC_KIND_BUCKET, {PE_TEXT_UI_SYNC_BUCKET, PE_TEXT_UI_SYNC_BUCKET_NOTE}},
    };
    for (const auto& [id, words] : kinds) {
        DWORD style = BS_AUTORADIOBUTTON | (id == IDC_SYNC_KIND_FOLDER ? WS_GROUP | WS_TABSTOP : 0);
        keep(CreateChild(dialog, L"BUTTON", core::T(words.first).c_str(), style, id, {pad + margin, inner, width - pad - margin, inner + Scale(16)}));
        inner += Scale(16) + Scale(1);
        std::wstring note = core::T(words.second);
        int height = Wrapped(note, width - 2 * pad - 2 * margin - indent);
        keep(CreateChild(dialog, L"STATIC", note.c_str(), SS_LEFT | SS_NOPREFIX | SS_EDITCONTROL, 0,
                         {pad + margin + indent, inner, width - pad - margin, inner + height}));
        inner += height + Scale(8);
    }
    Button_SetCheck(Item(dialog, IDC_SYNC_KIND_FOLDER), BST_CHECKED);
    inner += margin - Scale(8);
    MoveWindow(box, pad, y, width - 2 * pad, inner - y, FALSE);
    y = inner + Scale(12);

    // the labels a column, the fields beside them; a label's letter moves the focus to its field
    const std::pair<PeText, int> bucket[] = {
        {PE_TEXT_UI_SYNC_ENDPOINT, IDC_SYNC_ENDPOINT}, {PE_TEXT_UI_SYNC_REGION, IDC_SYNC_REGION},
        {PE_TEXT_UI_SYNC_BUCKET_NAME, IDC_SYNC_BUCKET}, {PE_TEXT_UI_SYNC_PREFIX, IDC_SYNC_PREFIX},
        {PE_TEXT_UI_SYNC_ACCESS_KEY, IDC_SYNC_ACCESS_KEY}, {PE_TEXT_UI_SYNC_SECRET_KEY, IDC_SYNC_SECRET_KEY},
    };
    std::vector<std::wstring> labels = {core::T(PE_TEXT_UI_SYNC_FOLDER_LABEL)};
    for (const auto& [text, id] : bucket) {
        labels.push_back(core::T(text));
    }
    int field = pad + LabelWidth(labels, 90);
    std::wstring choose = core::T(PE_TEXT_UI_SYNC_CHOOSE_FOLDER);
    int chooseWidth = ButtonWidth({choose});
    // WS_GROUP ends the radio buttons' group
    keep(CreateChild(dialog, L"STATIC", labels[0].c_str(), SS_LEFT | WS_GROUP, 0, {pad, y + Scale(3), field - Scale(4), y + row}));
    keep(CreateChild(dialog, L"EDIT", L"", WS_TABSTOP | ES_AUTOHSCROLL, IDC_SYNC_FOLDER, {field, y, width - pad - chooseWidth - Scale(kGap), y + row},
                     WS_EX_CLIENTEDGE));
    keep(CreateChild(dialog, L"BUTTON", choose.c_str(), WS_TABSTOP, IDC_SYNC_CHOOSE,
                     {width - pad - chooseWidth, y - Scale(1), width - pad, y - Scale(1) + Scale(kButton)}));
    for (size_t i = 0; i < std::size(bucket); i++) {
        int id = bucket[i].second;
        keep(CreateChild(dialog, L"STATIC", labels[i + 1].c_str(), SS_LEFT | (i == 0 ? WS_GROUP : 0), 0,
                         {pad, y + Scale(3), field - Scale(4), y + row}));
        keep(CreateChild(dialog, L"EDIT", id == IDC_SYNC_ENDPOINT ? L"https://" : L"",
                         WS_TABSTOP | ES_AUTOHSCROLL | (id == IDC_SYNC_SECRET_KEY ? ES_PASSWORD : 0), id, {field, y, width - pad, y + row},
                         WS_EX_CLIENTEDGE));
        y += row + Scale(kGap);
    }
    return y - Scale(kGap) - state.top;
}

}  // namespace

bool* SyncChoiceFlag(PeSyncChoice& choice, int setting) {
    switch (setting) {
    case PE_SETTING_SYNC_ACCOUNTS:
        return &choice.accounts;
    case PE_SETTING_SYNC_PASSWORDS:
        return &choice.passwords;
    case PE_SETTING_SYNC_SIGN_INS:
        return &choice.sign_ins;
    case PE_SETTING_SYNC_SIGN_IN_APPS:
        return &choice.sign_in_apps;
    case PE_SETTING_SYNC_APP_SECRETS:
        return &choice.app_secrets;
    case PE_SETTING_SYNC_CONTACTS:
        return &choice.contacts;
    case PE_SETTING_SYNC_KEYS:
        return &choice.keys;
    case PE_SETTING_SYNC_PRIVATE_KEYS:
        return &choice.private_keys;
    case PE_SETTING_SYNC_RULES:
        return &choice.rules;
    case PE_SETTING_SYNC_TRUSTED:
        return &choice.trusted;
    case PE_SETTING_SYNC_SETTINGS:
        return &choice.settings;
    case PE_SETTING_SYNC_PREFERENCES:
        return &choice.preferences;
    default:
        return nullptr;
    }
}

bool SetUpSyncDialog(HWND owner, PeCore* core) {
    HelpScope help("options");
    RegisterDialogClass(kSetUpClass, SetUpProc);
    SetUpState state;
    state.core = core;
    state.pad = Scale(12);
    state.width = Scale(470);
    state.top = state.pad;
    // as tall as the taller step, either way the second one goes
    int stepHeight = std::max(SecondStep(state, false, false), SecondStep(state, true, false));
    int problemHeight = 2 * static_cast<int>(MeasureText(L"Ag").cy);
    std::wstring next = core::T(PE_TEXT_WIN_NEXT), turnOn = core::T(PE_TEXT_UI_SYNC_TURN_ON), back = core::T(PE_TEXT_WIN_SYNC_BACK);
    std::wstring cancel = core::T(PE_TEXT_UI_CANCEL);
    // the window made first to lay the first step in it, sized once that is measured
    state.dialog = CreateModalWindow(owner, kSetUpClass, core::Title(PE_TEXT_UI_SYNC_SET_UP).c_str(), state.width, Scale(400));
    PaintUnderChildren(state.dialog);
    stepHeight = std::max(stepHeight, FirstStep(state));
    int problemTop = state.top + stepHeight + Scale(10);
    HWND problem = CreateChild(state.dialog, L"STATIC", L"", SS_LEFT | SS_NOPREFIX | SS_EDITCONTROL, IDC_SYNC_PROBLEM,
                               {state.pad, problemTop, state.width - state.pad, problemTop + problemHeight});
    ShowWindow(problem, SW_HIDE);
    int height = problemTop + problemHeight + Scale(10) + Scale(kButton) + state.pad;
    // a line over the buttons, as a wizard has
    int line = problemTop + problemHeight + Scale(4);
    CreateChild(state.dialog, L"STATIC", L"", SS_ETCHEDHORZ, 0, {0, line, state.width, line + 2});
    int buttonWidth = ButtonWidth({next, turnOn, back, cancel}), buttonTop = height - state.pad - Scale(kButton);
    int x = state.width - state.pad - 3 * buttonWidth - Scale(kGap);
    // < Back and Next > side by side, as a wizard's, Cancel apart from them
    CreateChild(state.dialog, L"BUTTON", back.c_str(), WS_TABSTOP, IDC_SYNC_BACK, {x, buttonTop, x + buttonWidth, buttonTop + Scale(kButton)});
    x += buttonWidth;
    CreateChild(state.dialog, L"BUTTON", next.c_str(), WS_TABSTOP | BS_DEFPUSHBUTTON, IDOK, {x, buttonTop, x + buttonWidth, buttonTop + Scale(kButton)});
    x += buttonWidth + Scale(kGap);
    CreateChild(state.dialog, L"BUTTON", cancel.c_str(), WS_TABSTOP, IDCANCEL, {x, buttonTop, x + buttonWidth, buttonTop + Scale(kButton)});
    RECT frame = {0, 0, state.width, height};
    AdjustWindowRectEx(&frame, static_cast<DWORD>(GetWindowLongPtrW(state.dialog, GWL_STYLE)), FALSE,
                       static_cast<DWORD>(GetWindowLongPtrW(state.dialog, GWL_EXSTYLE)));
    RECT now;
    GetWindowRect(state.dialog, &now);
    int outerHeight = frame.bottom - frame.top;
    SetWindowPos(state.dialog, nullptr, now.left, now.top - (outerHeight - (now.bottom - now.top)) / 2, frame.right - frame.left, outerHeight,
                 SWP_NOZORDER | SWP_NOACTIVATE);
    SetWindowLongPtrW(state.dialog, GWLP_USERDATA, reinterpret_cast<LONG_PTR>(&state));
    ShowStep(state, false);
    g_setUp = &state;
    RunModal(state.dialog, Item(state.dialog, IDC_SYNC_FOLDER), state.done);
    g_setUp = nullptr;
    state.place.Wipe();
    return state.on;
}

// ---- Computers and History ----

namespace {

struct ListState {
    PeCore* core = nullptr;
    HWND dialog = nullptr;
    HWND list = nullptr;
    HWND act = nullptr;
    HWND empty = nullptr;
    bool done = false;
    // Computers: each row's device, and whether it is this computer; History: each row's edit
    std::vector<std::string> devices;
    std::vector<bool> self;
    std::vector<int64_t> edits;
    // History's restore points: the list, Open, what is said with none, and each row's path
    HWND points = nullptr;
    HWND open = nullptr;
    HWND none = nullptr;
    std::vector<std::string> paths;
    // a computer was removed: read the computers again once the core says it is done
    bool reread = false;
};

ListState* g_computers = nullptr;

// a list of two columns without headings (the name and what is said of it), one row selected at a time
HWND TwoColumnList(HWND dialog, int id, const RECT& box, double first) {
    HWND list = CreateChild(dialog, WC_LISTVIEWW, nullptr, WS_TABSTOP | LVS_REPORT | LVS_SINGLESEL | LVS_NOCOLUMNHEADER | LVS_SHOWSELALWAYS, id,
                            box, WS_EX_CLIENTEDGE);
    ListView_SetExtendedListViewStyle(list, LVS_EX_FULLROWSELECT);
    int inner = box.right - box.left - GetSystemMetrics(SM_CXVSCROLL) - Scale(6);
    LVCOLUMNW column = {LVCF_WIDTH};
    column.cx = static_cast<int>(inner * first);
    ListView_InsertColumn(list, 0, &column);
    if (first < 1) {
        column.cx = inner - column.cx;
        ListView_InsertColumn(list, 1, &column);
    }
    return list;
}

// what is said in a list's place while it has no rows: shown or hidden with the list
void ShowEmpty(HWND list, HWND empty, const std::wstring& words) {
    bool none = ListView_GetItemCount(list) == 0;
    if (!words.empty()) {
        SetWindowTextW(empty, words.c_str());
    }
    ShowWindow(list, none ? SW_HIDE : SW_SHOW);
    ShowWindow(empty, none ? SW_SHOW : SW_HIDE);
}

int SelectedRow(HWND list) {
    return ListView_GetNextItem(list, -1, LVNI_SELECTED);
}

using Computers = std::unique_ptr<PeSyncComputers, core::Deleter<pe_settings_sync_computers_free>>;
using History = std::unique_ptr<PeSyncHistory, core::Deleter<pe_settings_sync_history_free>>;
using RestorePoints = std::unique_ptr<PeSyncRestorePoints, core::Deleter<pe_settings_sync_restore_points_free>>;

// the computers read (this one first, as the core lists them), or that they are being read
void FillComputers(ListState& state) {
    ListView_DeleteAllItems(state.list);
    state.devices.clear();
    state.self.clear();
    Computers computers(pe_settings_sync_computers(state.core));
    for (size_t i = 0; computers && i < pe_settings_sync_computers_count(computers.get()); i++) {
        const PeSyncComputer* computer = pe_settings_sync_computers_get(computers.get(), i);
        std::wstring seen = computer->this_ ? core::T(PE_TEXT_UI_SYNC_THIS_COMPUTER) : core::T(PE_TEXT_UI_SYNC_SEEN, {{"when", Text(computer->seen)}});
        int row = AddRow(state.list, static_cast<int>(i), Text(computer->name));
        SetCell(state.list, row, 1, seen);
        state.devices.push_back(computer->device ? computer->device : "");
        state.self.push_back(computer->this_);
    }
    ShowEmpty(state.list, state.empty, computers ? L"" : core::T(PE_TEXT_UI_SYNC_LOADING));
    EnableWindow(state.act, FALSE);
}

void RemoveComputer(ListState& state) {
    int row = SelectedRow(state.list);
    if (row < 0 || static_cast<size_t>(row) >= state.devices.size() || state.self[row]) {
        return;
    }
    wchar_t name[256] = L"";
    ListView_GetItemText(state.list, row, 0, name, 256);
    if (Ask(state.dialog, core::Title(PE_TEXT_UI_SYNC_COMPUTERS_TITLE), core::T(PE_TEXT_UI_SYNC_REMOVE_ASK, {{"name", name}}),
            core::T(PE_TEXT_UI_REMOVE), core::T(PE_TEXT_UI_CANCEL), true)) {
        state.reread = true;
        pe_settings_sync_remove_computer(state.core, state.devices[row].c_str());
    }
}

// the edits another computer's replaced, newest first: what each was an edit of with the value it set, and where and
// when it came from
void FillHistory(ListState& state) {
    ListView_DeleteAllItems(state.list);
    state.edits.clear();
    History history(pe_settings_sync_history(state.core));
    for (size_t i = 0; history && i < pe_settings_sync_history_count(history.get()); i++) {
        const PeSyncHistoryRow* edit = pe_settings_sync_history_get(history.get(), i);
        std::wstring value = Text(edit->value), heading = Text(edit->item);
        if (!value.empty()) {
            heading += L": " + value;
        }
        int row = AddRow(state.list, static_cast<int>(i), heading);
        SetCell(state.list, row, 1, core::T(PE_TEXT_UI_SYNC_HISTORY_ROW, {{"source", Text(edit->source)}, {"when", Text(edit->when)}}));
        state.edits.push_back(edit->id);
    }
    ShowEmpty(state.list, state.empty, L"");
    EnableWindow(state.act, FALSE);
}

// the restore points, newest first, by when each was made
void FillPoints(ListState& state) {
    ListView_DeleteAllItems(state.points);
    state.paths.clear();
    RestorePoints points(pe_settings_sync_restore_points(state.core));
    for (size_t i = 0; points && i < pe_settings_sync_restore_points_count(points.get()); i++) {
        const PeSyncRestorePoint* point = pe_settings_sync_restore_points_get(points.get(), i);
        AddRow(state.points, static_cast<int>(i), Text(point->when));
        state.paths.push_back(point->path ? point->path : "");
    }
    ShowEmpty(state.points, state.none, L"");
    EnableWindow(state.open, FALSE);
}

void RestoreEdit(ListState& state) {
    int row = SelectedRow(state.list);
    if (row < 0 || static_cast<size_t>(row) >= state.edits.size()) {
        return;
    }
    core::SetupExport prefs = AppPrefsExport();
    pe_settings_sync_restore(state.core, state.edits[row], prefs.get());
    FillHistory(state);
    SetFocus(ListView_GetItemCount(state.list) ? state.list : GetDlgItem(state.dialog, IDOK));
}

// a restore point read by the core (a moment, its key) and opened in the import window
void OpenPoint(ListState& state) {
    int row = SelectedRow(state.points);
    if (row < 0 || static_cast<size_t>(row) >= state.paths.size()) {
        return;
    }
    char* error = nullptr;
    core::SetupFile file;
    RunWaiting(state.dialog, [&] { file.reset(pe_settings_sync_restore_point_read(state.core, state.paths[row].c_str(), &error)); });
    if (!file) {
        MessageBoxApp(state.dialog, ReasonText(error, PE_TEXT_UI_UNKNOWN_REASON).c_str(), core::Title(PE_TEXT_UI_SYNC_HISTORY_TITLE).c_str(),
                      MB_OK | MB_ICONWARNING);
        return;
    }
    core::String unused(error);
    ImportRestorePoint(state.dialog, std::move(file));
}

LRESULT CALLBACK ListProc(HWND hwnd, UINT message, WPARAM wParam, LPARAM lParam) {
    auto* state = reinterpret_cast<ListState*>(GetWindowLongPtrW(hwnd, GWLP_USERDATA));
    if (!state) {
        return DefWindowProcW(hwnd, message, wParam, lParam);
    }
    switch (message) {
    case WM_CLOSE:
        state->done = true;
        return 0;
    case WM_COMMAND:
        switch (LOWORD(wParam)) {
        case IDOK:
        case IDCANCEL:
            state->done = true;
            break;
        case IDC_SYNC_ACT:
            if (state->points) {
                RestoreEdit(*state);
            } else {
                RemoveComputer(*state);
            }
            break;
        case IDC_SYNC_OPEN_POINT:
            OpenPoint(*state);
            break;
        }
        return 0;
    case WM_SYNC_CHANGED:
        if (state->reread) {
            state->reread = false;
            pe_settings_sync_computers_start(state->core);
        }
        FillComputers(*state);
        return 0;
    case WM_NOTIFY: {
        auto* header = reinterpret_cast<NMHDR*>(lParam);
        if (header->code == LVN_ITEMCHANGED && header->hwndFrom == state->list) {
            int row = SelectedRow(state->list);
            bool can = row >= 0 && (state->points || (static_cast<size_t>(row) < state->self.size() && !state->self[row]));
            EnableWindow(state->act, can);
        } else if (header->code == LVN_ITEMCHANGED && header->hwndFrom == state->points) {
            EnableWindow(state->open, SelectedRow(state->points) >= 0);
        } else if (header->code == NM_DBLCLK && header->hwndFrom == state->points) {
            OpenPoint(*state);
        }
        return 0;
    }
    case WM_CTLCOLORSTATIC: {
        auto control = reinterpret_cast<HWND>(lParam);
        if (control == state->empty || (state->none && control == state->none)) {
            auto dc = reinterpret_cast<HDC>(wParam);
            SetBkColor(dc, GetSysColor(COLOR_WINDOW));
            SetTextColor(dc, GetSysColor(COLOR_GRAYTEXT));
            return reinterpret_cast<LRESULT>(GetSysColorBrush(COLOR_WINDOW));
        }
        return ButtonFaceColor(reinterpret_cast<HDC>(wParam));
    }
    }
    return DefWindowProcW(hwnd, message, wParam, lParam);
}

// a section of a list window from `top`: its note, its list with its button beside it (`button` the widest of the
// window's), and the words of none in the list's place; the bottom of the list
int ListSection(HWND dialog, int top, int pad, int width, int button, const std::wstring& note, int listHeight, int listId,
                const std::wstring& act, int actId, int emptyId, const std::wstring& none, double first, HWND& list, HWND& actButton,
                HWND& empty) {
    int noteHeight = Wrapped(note, width - 2 * pad);
    CreateChild(dialog, L"STATIC", note.c_str(), SS_LEFT | SS_NOPREFIX | SS_EDITCONTROL, 0, {pad, top, width - pad, top + noteHeight});
    top += noteHeight + Scale(8);
    RECT box = {pad, top, width - pad - button - Scale(kGap), top + listHeight};
    list = TwoColumnList(dialog, listId, box, first);
    actButton = CreateChild(dialog, L"BUTTON", act.c_str(), WS_TABSTOP, actId, {box.right + Scale(kGap), top, width - pad, top + Scale(kButton)});
    // in the list's place, as an empty list with the words in its middle
    empty = CreateChild(dialog, L"STATIC", none.c_str(), SS_CENTER | SS_CENTERIMAGE | SS_NOPREFIX, emptyId, box, WS_EX_CLIENTEDGE);
    return box.bottom;
}

}  // namespace

void SyncComputersDialog(HWND owner, PeCore* core) {
    HelpScope help("options");
    RegisterDialogClass(kComputersClass, ListProc);
    std::wstring note = core::T(PE_TEXT_UI_SYNC_COMPUTERS_NOTE), remove = core::T(PE_TEXT_UI_REMOVE), close = core::T(PE_TEXT_UI_CLOSE);
    int pad = Scale(12), width = Scale(500), button = ButtonWidth({remove, close});
    int noteHeight = Wrapped(note, width - 2 * pad), listHeight = Scale(150);
    int height = pad + noteHeight + Scale(8) + listHeight + Scale(14) + Scale(kButton) + pad;
    ListState state;
    state.core = core;
    state.dialog = CreateModalWindow(owner, kComputersClass, core::Title(PE_TEXT_UI_SYNC_COMPUTERS_TITLE).c_str(), width, height);
    ListSection(state.dialog, pad, pad, width, button, note, listHeight, IDC_SYNC_LIST, remove, IDC_SYNC_ACT, IDC_SYNC_EMPTY, L"", 0.35,
                state.list, state.act, state.empty);
    int top = height - pad - Scale(kButton);
    HWND closeButton = CreateChild(state.dialog, L"BUTTON", close.c_str(), WS_TABSTOP | BS_DEFPUSHBUTTON, IDOK,
                                   {width - pad - button, top, width - pad, top + Scale(kButton)});
    pe_settings_sync_computers_start(core);
    FillComputers(state);
    SetWindowLongPtrW(state.dialog, GWLP_USERDATA, reinterpret_cast<LONG_PTR>(&state));
    g_computers = &state;
    RunModal(state.dialog, closeButton, state.done);
    g_computers = nullptr;
}

void SyncHistoryDialog(HWND owner, PeCore* core) {
    HelpScope help("options");
    RegisterDialogClass(kHistoryClass, ListProc);
    std::wstring note = core::T(PE_TEXT_UI_SYNC_HISTORY_NOTE), restore = core::T(PE_TEXT_UI_SYNC_RESTORE);
    std::wstring heading = core::T(PE_TEXT_UI_SYNC_RESTORE_POINTS), pointsNote = core::T(PE_TEXT_UI_SYNC_RESTORE_POINTS_NOTE);
    std::wstring open = core::T(PE_TEXT_UI_SYNC_OPEN_POINT), close = core::T(PE_TEXT_UI_CLOSE);
    int pad = Scale(12), width = Scale(480), button = ButtonWidth({restore, open, close});
    int listHeight = Scale(120), pointsHeight = Scale(90);
    int height = pad + Wrapped(note, width - 2 * pad) + Scale(8) + listHeight + Scale(16) + Scale(20) + Wrapped(pointsNote, width - 2 * pad - 2 * Scale(10)) +
                 Scale(8) + pointsHeight + Scale(10) + Scale(12) + Scale(kButton) + pad;
    ListState state;
    state.core = core;
    state.dialog = CreateModalWindow(owner, kHistoryClass, core::Title(PE_TEXT_UI_SYNC_HISTORY_TITLE).c_str(), width, height);
    PaintUnderChildren(state.dialog);
    int y = ListSection(state.dialog, pad, pad, width, button, note, listHeight, IDC_SYNC_LIST, restore, IDC_SYNC_ACT, IDC_SYNC_EMPTY,
                        core::T(PE_TEXT_UI_SYNC_HISTORY_EMPTY), 0.55, state.list, state.act, state.empty);
    // the restore points in a group box of their own under the replaced changes
    y += Scale(16);
    int boxTop = y, margin = Scale(10);
    HWND box = CreateChild(state.dialog, L"BUTTON", heading.c_str(), BS_GROUPBOX, 0, {pad, y, width - pad, y});
    int bottom = ListSection(state.dialog, y + Scale(20), pad + margin, width, button, pointsNote, pointsHeight,
                             IDC_SYNC_POINTS, open, IDC_SYNC_OPEN_POINT, IDC_SYNC_POINTS_EMPTY, core::T(PE_TEXT_UI_SYNC_RESTORE_POINTS_EMPTY), 1.0,
                             state.points, state.open, state.none);
    MoveWindow(box, pad, boxTop, width - 2 * pad, bottom + margin - boxTop, FALSE);
    int top = height - pad - Scale(kButton);
    HWND closeButton = CreateChild(state.dialog, L"BUTTON", close.c_str(), WS_TABSTOP | BS_DEFPUSHBUTTON, IDOK,
                                   {width - pad - button, top, width - pad, top + Scale(kButton)});
    FillHistory(state);
    FillPoints(state);
    SetWindowLongPtrW(state.dialog, GWLP_USERDATA, reinterpret_cast<LONG_PTR>(&state));
    RunModal(state.dialog, closeButton, state.done);
}

void SyncWindowsChanged() {
    if (g_setUp && g_setUp->probing) {
        PostMessageW(g_setUp->dialog, WM_SYNC_CHANGED, 0, 0);
    }
    if (g_computers) {
        PostMessageW(g_computers->dialog, WM_SYNC_CHANGED, 0, 0);
    }
}

int64_t WaitForSyncedAccount(HWND owner, PeCore* core) {
    int64_t found = 0;
    RunWaiting(owner, [&] {
        for (int i = 0; i < 600 && !found; i++) {
            core::AccountList accounts(pe_accounts(core));
            if (pe_account_list_count(accounts.get()) > 0) {
                found = pe_account_list_get(accounts.get(), 0)->id;
            } else {
                Sleep(100);
            }
        }
    });
    return found;
}

// ---- the UI test's second computer ----

namespace {

struct Second {
    PeCore* core = nullptr;
    std::atomic<bool> ready = false;
    std::wstring dir;

    ~Second() {
        if (core) {
            pe_core_close(core);
        }
        if (!dir.empty()) {
            std::wstring files = dir + L'\0';
            SHFILEOPSTRUCTW remove = {nullptr, FO_DELETE, files.c_str(), nullptr, FOF_NO_UI};
            SHFileOperationW(&remove);
        }
    }
};

std::unique_ptr<Second> g_second;

void SecondEvent(void* context, const PeEvent* event) noexcept {
    if (event->kind == PE_EVENT_KIND_SETTINGS_SYNC_READY) {
        static_cast<Second*>(context)->ready = true;
    }
}

bool WaitUntil(const std::function<bool()>& condition, int seconds) {
    for (int i = 0; i < seconds * 10; i++) {
        if (condition()) {
            return true;
        }
        Sleep(100);
    }
    return condition();
}

bool SecondBusy() {
    using State = std::unique_ptr<PeSyncStateHandle, core::Deleter<pe_settings_sync_state_free>>;
    State state(pe_settings_sync_state(g_second->core));
    const PeSyncState* now = pe_settings_sync_state_get(state.get());
    return now && now->busy;
}

// one whole sync of the second computer, answered as a window answers it (with no preferences)
bool SecondSync(bool start) {
    if (start) {
        g_second->ready = false;
        pe_settings_sync_now(g_second->core);
    }
    if (!WaitUntil([] { return g_second->ready.load(); }, 30)) {
        return false;
    }
    g_second->ready = false;
    pe_settings_sync_continue(g_second->core, nullptr);
    return WaitUntil([] { return !SecondBusy(); }, 30);
}

}  // namespace

LRESULT TestSyncSecond(PeCore* core, const std::wstring& request) {
    std::vector<std::string> words;
    std::string text = core::Narrow(request);
    for (size_t start = 0, tab; start <= text.size(); start = tab + 1) {
        tab = text.find('\t', start);
        if (tab == std::string::npos) {
            tab = text.size();
        }
        words.push_back(text.substr(start, tab - start));
    }
    if (words[0] == "close") {
        g_second.reset();
        return 11;
    }
    if (words[0] == "has" && words.size() == 2) {
        core::CardList cards(pe_cards(core, words[1].c_str()));
        return cards && pe_card_list_count(cards.get()) > 0 ? 11 : 10;
    }
    if (words[0] == "card" && words.size() == 2 && g_second) {
        const char* addresses[] = {words[1].c_str()};
        PeCard card = {};
        card.name = "Sync Friend";
        card.addresses = addresses;
        card.address_count = 1;
        char* error = nullptr;
        bool saved = pe_card_save(g_second->core, &card, &error) > 0;
        core::String unused(error);
        return saved && SecondSync(true) ? 11 : 10;
    }
    if (words[0] == "join" && words.size() == 3) {
        g_second = std::make_unique<Second>();
        wchar_t temp[MAX_PATH] = L"";
        GetTempPathW(MAX_PATH, temp);
        g_second->dir = std::wstring(temp) + L"inbox-classic-second-" + std::to_wstring(GetCurrentProcessId());
        CreateDirectoryW(g_second->dir.c_str(), nullptr);
        std::string store = core::Narrow(g_second->dir + L"\\store.db");
        g_second->core = pe_core_open_with(store.c_str(), PE_OPEN_MEMORY_PASSWORDS, nullptr, SecondEvent, g_second.get());
        if (!g_second->core) {
            return 9;
        }
        PeSyncPlace place = {};
        place.kind = PE_SYNC_PLACE_KIND_FOLDER;
        place.path = words[1].c_str();
        char* error = nullptr;
        // a wrong passphrase first, which must not join
        bool wrong = pe_settings_sync_turn_on(g_second->core, &place, nullptr, "not it", "Laptop", pe_sync_choice_default(), &error);
        core::String said(error);
        error = nullptr;
        if (wrong || !pe_settings_sync_turn_on(g_second->core, &place, nullptr, words[2].c_str(), "Laptop", pe_sync_choice_default(), &error)) {
            core::String unused(error);
            return 9;
        }
        core::String unused(error);
        // the first sync starts by itself
        if (!SecondSync(false)) {
            return 9;
        }
        core::AccountList accounts(pe_accounts(g_second->core));
        return static_cast<LRESULT>(pe_account_list_count(accounts.get()) + 10);
    }
    return 0;
}
