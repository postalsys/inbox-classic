// Encryption keys: the Encryption Keys window (Tools) with the user's own OpenPGP keys and their contacts' keys, New
// Key, Back Up Key, Import with the passphrase of a protected key, Key Properties, Verify Key, and the Security part of
// Account Properties. The keys, their words and every decision are the core's (pe_pgp_*); this file shows them, and
// moves the bytes of key files between the disk and the core without looking into them.
#include "app.h"

#include <algorithm>

std::string ReadSecret(HWND edit) {
    int length = GetWindowTextLengthW(edit);
    std::vector<wchar_t> typed(static_cast<size_t>(length) + 1, L'\0');
    GetWindowTextW(edit, typed.data(), length + 1);
    std::string secret = core::Narrow({typed.data(), static_cast<size_t>(length)});
    SecureZeroMemory(typed.data(), typed.size() * sizeof(wchar_t));
    return secret;
}

void Wipe(std::string& secret) {
    SecureZeroMemory(secret.data(), secret.size());
    secret.clear();
}

int WarningNote(HWND dialog, int id, const std::wstring& text, int left, int top, int right) {
    int icon = GetSystemMetrics(SM_CXSMICON);
    // a system icon is shared: not destroyed
    auto warning = static_cast<HICON>(LoadImageW(nullptr, IDI_WARNING, IMAGE_ICON, icon, icon, LR_SHARED));
    HWND sign = CreateChild(dialog, L"STATIC", nullptr, SS_ICON | SS_REALSIZECONTROL, 0, {left, top, left + icon, top + icon});
    SendMessageW(sign, STM_SETICON, reinterpret_cast<WPARAM>(warning), 0);
    int textLeft = left + icon + Scale(6);
    int height = std::max(icon, static_cast<int>(MeasureText(text, right - textLeft).cy));
    CreateChild(dialog, L"STATIC", text.c_str(), SS_LEFT | SS_NOPREFIX, id, {textLeft, top, right, top + height});
    return height;
}

void BottomButtons(HWND dialog, int width, int top, const std::wstring& ok, const std::wstring& cancel, bool cancelDefault) {
    int pad = Scale(10), buttonWidth = ButtonWidth({ok, cancel});
    CreateChild(dialog, L"BUTTON", ok.c_str(), WS_TABSTOP | (cancelDefault ? 0 : BS_DEFPUSHBUTTON), IDOK,
                {width - pad - 2 * buttonWidth - Scale(6), top, width - pad - buttonWidth - Scale(6), top + Scale(25)});
    CreateChild(dialog, L"BUTTON", cancel.c_str(), WS_TABSTOP | (cancelDefault ? BS_DEFPUSHBUTTON : 0), IDCANCEL,
                {width - pad - buttonWidth, top, width - pad, top + Scale(25)});
}

void WipeFields(HWND dialog, std::initializer_list<int> ids) {
    for (int id : ids) {
        if (HWND edit = GetDlgItem(dialog, id)) {
            int length = GetWindowTextLengthW(edit);
            SetWindowTextW(edit, std::wstring(static_cast<size_t>(length), L' ').c_str());
            SetWindowTextW(edit, L"");
        }
    }
}

bool ShowPassphraseFeedback(HWND dialog, int first, int again, int line) {
    std::string typed = ReadSecret(GetDlgItem(dialog, first));
    std::string retyped = ReadSecret(GetDlgItem(dialog, again));
    bool acceptable = false;
    core::String said(pe_passphrase_feedback(typed.c_str(), retyped.c_str(), &acceptable));
    Wipe(typed);
    Wipe(retyped);
    std::wstring words = said ? Text(said.get()) : L"";
    HWND note = GetDlgItem(dialog, line);
    if (GetWindowString(note) != words) {
        SetWindowTextW(note, words.c_str());
    }
    // the words and the warning sign before them
    ShowWindow(note, words.empty() ? SW_HIDE : SW_SHOW);
    ShowWindow(GetWindow(note, GW_HWNDPREV), words.empty() ? SW_HIDE : SW_SHOW);
    SetAccessibleDescription(GetDlgItem(dialog, again), words);
    return acceptable;
}

namespace {

// a key file is a few kilobytes, a whole keyring a few hundred: anything larger is no key file
constexpr DWORD kMostKeyBytes = 16 * 1024 * 1024;

// the shortest passphrase a backup takes
HWND Item(HWND dialog, int id) {
    return GetDlgItem(dialog, id);
}

// the window's title of a key action's message boxes
std::wstring KeysTitle() {
    return core::Plain(PE_TEXT_UI_KEYS_TITLE);
}

// the filter of the file windows: OpenPGP key files (and every file, to open one named otherwise)
std::wstring KeyFilter(bool anyFile) {
    std::wstring keys = core::T(PE_TEXT_UI_KEYS_FILE_FILTER);
    if (anyFile) {
        return FileFilter({{keys, L"*.asc;*.gpg;*.pgp;*.key"}, {core::T(PE_TEXT_UI_FILTER_ALL), L"*.*"}});
    }
    return FileFilter({{keys, L"*.asc"}});
}

// the bytes of the file at `path` (none when it can not be read, or is too large to be a key file): the core says
// what they are
std::vector<uint8_t> ReadKeyFile(const std::wstring& path) {
    std::vector<uint8_t> bytes;
    HANDLE file = CreateFileW(path.c_str(), GENERIC_READ, FILE_SHARE_READ, nullptr, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, nullptr);
    if (file == INVALID_HANDLE_VALUE) {
        return bytes;
    }
    LARGE_INTEGER size = {};
    if (GetFileSizeEx(file, &size) && size.QuadPart > 0 && size.QuadPart <= kMostKeyBytes) {
        bytes.resize(static_cast<size_t>(size.QuadPart));
        DWORD read = 0;
        if (!ReadFile(file, bytes.data(), static_cast<DWORD>(bytes.size()), &read, nullptr)) {
            read = 0;
        }
        bytes.resize(read);
    }
    CloseHandle(file);
    return bytes;
}

// `text` the core gave written to `path`; false with the system's reason in `why`
bool WriteKeyFile(const std::wstring& path, const char* text, std::wstring& why) {
    HANDLE file = CreateFileW(path.c_str(), GENERIC_WRITE, 0, nullptr, CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, nullptr);
    DWORD written = 0;
    DWORD size = static_cast<DWORD>(strlen(text));
    bool done = file != INVALID_HANDLE_VALUE && WriteFile(file, text, size, &written, nullptr) && written == size;
    DWORD error = done ? 0 : GetLastError();
    if (file != INVALID_HANDLE_VALUE) {
        CloseHandle(file);
    }
    if (!done) {
        wchar_t* words = nullptr;
        FormatMessageW(FORMAT_MESSAGE_ALLOCATE_BUFFER | FORMAT_MESSAGE_FROM_SYSTEM | FORMAT_MESSAGE_IGNORE_INSERTS, nullptr, error, 0,
                       reinterpret_cast<wchar_t*>(&words), 0, nullptr);
        why = words ? words : core::T(PE_TEXT_UI_UNKNOWN_REASON);
        // the system's words end with a line break
        why.erase(why.find_last_not_of(L" \r\n") + 1);
        LocalFree(words);
    }
    return done;
}


// a dialog that is done with OK or Cancel: `Done` has `done` and `accepted`
template <typename Done>
LRESULT CALLBACK SimpleProc(HWND hwnd, UINT message, WPARAM wParam, LPARAM lParam) {
    auto* state = reinterpret_cast<Done*>(GetWindowLongPtrW(hwnd, GWLP_USERDATA));
    switch (message) {
    case WM_COMMAND:
        if (state && (LOWORD(wParam) == IDOK || LOWORD(wParam) == IDCANCEL)) {
            state->accepted = LOWORD(wParam) == IDOK;
            state->done = true;
        }
        return 0;
    case WM_CLOSE:
        if (state) {
            state->done = true;
        }
        return 0;
    case WM_CTLCOLORSTATIC:
        return ButtonFaceColor(reinterpret_cast<HDC>(wParam));
    }
    return DefWindowProcW(hwnd, message, wParam, lParam);
}

// ---- a question with answers of its own ----

const wchar_t* kAskClass = L"InboxClassicAsk";

struct AskState {
    bool done = false;
    bool accepted = false;
};

}  // namespace

bool Ask(HWND owner, const std::wstring& title, const std::wstring& text, const std::wstring& yes, const std::wstring& no,
         bool safeDefault) {
    RegisterDialogClass(kAskClass, SimpleProc<AskState>);
    int pad = Scale(12), icon = GetSystemMetrics(SM_CXICON);
    int textWidth = Scale(330);
    int textHeight = static_cast<int>(MeasureText(text, textWidth).cy);
    int buttonWidth = ButtonWidth({yes, no});
    int width = std::max(pad + icon + pad + textWidth + pad, Scale(10) + 2 * buttonWidth + Scale(6) + Scale(10));
    int height = pad + std::max(icon, textHeight) + Scale(20) + Scale(25) + Scale(10);
    HWND dialog = CreateModalWindow(owner, kAskClass, title.c_str(), width, height);
    AskState state;
    HWND sign = CreateChild(dialog, L"STATIC", nullptr, SS_ICON, 0, {pad, pad, pad + icon, pad + icon});
    SendMessageW(sign, STM_SETICON, reinterpret_cast<WPARAM>(LoadIconW(nullptr, IDI_QUESTION)), 0);
    // words shorter than the sign beside its middle
    int textTop = pad + std::max(0, (icon - textHeight) / 2);
    CreateChild(dialog, L"STATIC", text.c_str(), SS_LEFT | SS_NOPREFIX, 0, {pad + icon + pad, textTop, width - pad, textTop + textHeight});
    BottomButtons(dialog, width, height - Scale(10) - Scale(25), yes, no, safeDefault);
    SetWindowLongPtrW(dialog, GWLP_USERDATA, reinterpret_cast<LONG_PTR>(&state));
    MessageBeep(MB_ICONQUESTION);
    RunModal(dialog, Item(dialog, safeDefault ? IDCANCEL : IDOK), state.done);
    return state.accepted;
}

namespace {

// ---- Back Up Key and Import Key: a passphrase ----

const wchar_t* kPassphraseClass = L"InboxClassicPassphrase";

struct PassphraseState {
    std::wstring title;
    // a backup's: typed twice, as long as the core wants
    bool twice = false;
    std::string passphrase;
    bool done = false;
    bool accepted = false;
};


// OK: the passphrase taken; a backup's only once the core takes it (OK is off until then, as Enter may still come)
void TakePassphrase(HWND dialog, PassphraseState& state) {
    if (!IsWindowEnabled(Item(dialog, IDOK))) {
        return;
    }
    state.passphrase = ReadSecret(Item(dialog, IDC_KEY_PASSPHRASE));
    state.accepted = true;
    state.done = true;
    WipeFields(dialog, {IDC_KEY_PASSPHRASE, IDC_KEY_PASSPHRASE_AGAIN});
}

LRESULT CALLBACK PassphraseProc(HWND hwnd, UINT message, WPARAM wParam, LPARAM lParam) {
    auto* state = reinterpret_cast<PassphraseState*>(GetWindowLongPtrW(hwnd, GWLP_USERDATA));
    if (state && message == WM_COMMAND && LOWORD(wParam) == IDOK) {
        TakePassphrase(hwnd, *state);
        return 0;
    }
    // a backup's passphrase as it is typed: what the core says of it, OK once it takes it
    if (state && state->twice && message == WM_COMMAND && HIWORD(wParam) == EN_CHANGE) {
        EnableWindow(Item(hwnd, IDOK), ShowPassphraseFeedback(hwnd, IDC_KEY_PASSPHRASE, IDC_KEY_PASSPHRASE_AGAIN, IDC_KEY_PROBLEM));
        return 0;
    }
    if (state && ((message == WM_COMMAND && LOWORD(wParam) == IDCANCEL) || message == WM_CLOSE)) {
        WipeFields(hwnd, {IDC_KEY_PASSPHRASE, IDC_KEY_PASSPHRASE_AGAIN});
    }
    return SimpleProc<PassphraseState>(hwnd, message, wParam, lParam);
}

}  // namespace

bool PassphraseDialog(HWND owner, const std::wstring& title, const std::wstring& intro, const std::wstring& problem, bool twice,
                      std::string& passphrase) {
    RegisterDialogClass(kPassphraseClass, PassphraseProc);
    std::wstring label = core::T(PE_TEXT_UI_KEYS_PASSPHRASE), againLabel = core::T(PE_TEXT_UI_KEYS_PASSPHRASE_AGAIN);
    int pad = Scale(10), width = Scale(420), row = Scale(22), gap = Scale(6);
    int labelWidth = twice ? LabelWidth({label, againLabel}, 90) : LabelWidth({label}, 90);
    int introHeight = static_cast<int>(MeasureText(intro, width - 2 * pad).cy);
    int iconWidth = GetSystemMetrics(SM_CXSMICON) + Scale(6);
    int problemHeight = problem.empty() ? 0 : std::max(GetSystemMetrics(SM_CYSMICON), static_cast<int>(MeasureText(problem, width - 2 * pad - iconWidth).cy)) + Scale(10);
    int fields = twice ? 2 : 1;
    // a backup's: room under the fields for the longest of what the core says while it is typed
    core::String longest(twice ? pe_passphrase_feedback_longest() : nullptr);
    std::wstring feedback = longest ? Text(longest.get()) : L"";
    int feedbackHeight =
        twice ? std::max(GetSystemMetrics(SM_CYSMICON), static_cast<int>(MeasureText(feedback, width - 2 * pad - labelWidth - iconWidth).cy)) : 0;
    int height = pad + introHeight + Scale(10) + problemHeight + fields * (row + gap) + feedbackHeight + Scale(10) + Scale(25) + pad;
    HWND dialog = CreateModalWindow(owner, kPassphraseClass, title.c_str(), width, height);
    PassphraseState state{title, twice};
    int top = pad;
    CreateChild(dialog, L"STATIC", intro.c_str(), SS_LEFT | SS_NOPREFIX, 0, {pad, top, width - pad, top + introHeight});
    top += introHeight + Scale(10);
    if (!problem.empty()) {
        WarningNote(dialog, IDC_KEY_PROBLEM, problem, pad, top, width - pad);
        top += problemHeight;
    }
    const std::pair<const std::wstring*, int> rows[] = {{&label, IDC_KEY_PASSPHRASE}, {&againLabel, IDC_KEY_PASSPHRASE_AGAIN}};
    for (int i = 0; i < fields; i++) {
        CreateChild(dialog, L"STATIC", rows[i].first->c_str(), SS_LEFT, 0, {pad, top + Scale(3), pad + labelWidth, top + row});
        CreateChild(dialog, L"EDIT", L"", WS_TABSTOP | ES_AUTOHSCROLL | ES_PASSWORD, rows[i].second, {pad + labelWidth, top, width - pad, top + row},
                    WS_EX_CLIENTEDGE);
        top += row + gap;
    }
    if (twice) {
        WarningNote(dialog, IDC_KEY_PROBLEM, feedback, pad + labelWidth, top, width - pad);
    }
    BottomButtons(dialog, width, height - pad - Scale(25), core::T(PE_TEXT_UI_OK), core::T(PE_TEXT_UI_CANCEL));
    if (twice) {
        EnableWindow(Item(dialog, IDOK), ShowPassphraseFeedback(dialog, IDC_KEY_PASSPHRASE, IDC_KEY_PASSPHRASE_AGAIN, IDC_KEY_PROBLEM));
    }
    SetWindowLongPtrW(dialog, GWLP_USERDATA, reinterpret_cast<LONG_PTR>(&state));
    RunModal(dialog, Item(dialog, IDC_KEY_PASSPHRASE), state.done);
    passphrase = std::move(state.passphrase);
    return state.accepted;
}

namespace {

// ---- New Key ----

const wchar_t* kNewKeyClass = L"InboxClassicNewKey";

struct NewKeyState {
    PeCore* core = nullptr;
    // the account of each row of the choice
    std::vector<int64_t> accounts;
    std::string made;
    bool done = false;
    bool accepted = false;
};

// Make Key: the key made for the chosen account (a moment), or the reason it was not
void MakeKey(HWND dialog, NewKeyState& state) {
    auto index = static_cast<int>(SendMessageW(Item(dialog, IDC_KEY_ACCOUNT), CB_GETCURSEL, 0, 0));
    if (index < 0 || static_cast<size_t>(index) >= state.accounts.size()) {
        return;
    }
    HCURSOR old = SetCursor(LoadCursorW(nullptr, IDC_WAIT));
    char* error = nullptr;
    core::String made(pe_pgp_generate(state.core, state.accounts[index], &error));
    SetCursor(old);
    if (!made) {
        MessageBoxW(dialog, ReasonText(error, PE_TEXT_UI_UNKNOWN_REASON).c_str(), core::Plain(PE_TEXT_UI_KEYS_NEW_TITLE).c_str(),
                    MB_OK | MB_ICONWARNING);
        return;
    }
    core::String unused(error);
    state.made = made.get();
    state.accepted = true;
    state.done = true;
}

LRESULT CALLBACK NewKeyProc(HWND hwnd, UINT message, WPARAM wParam, LPARAM lParam) {
    auto* state = reinterpret_cast<NewKeyState*>(GetWindowLongPtrW(hwnd, GWLP_USERDATA));
    if (state && message == WM_COMMAND && LOWORD(wParam) == IDOK) {
        MakeKey(hwnd, *state);
        return 0;
    }
    return SimpleProc<NewKeyState>(hwnd, message, wParam, lParam);
}

// New Key: an account chosen (the only one, or `account` when not 0) and a key made for it; its fingerprint, empty
// when cancelled
std::string NewKeyDialog(HWND owner, PeCore* core, int64_t account = 0) {
    RegisterDialogClass(kNewKeyClass, NewKeyProc);
    NewKeyState state{core};
    core::AccountList list(pe_accounts(core));
    std::vector<std::wstring> labels;
    int chosen = 0;
    for (size_t i = 0; i < pe_account_list_count(list.get()); i++) {
        const PeAccount* row = pe_account_list_get(list.get(), i);
        if (row->id == account) {
            chosen = static_cast<int>(i);
        }
        labels.push_back(Text(row->label));
        state.accounts.push_back(row->id);
    }
    std::wstring forLabel = core::T(PE_TEXT_UI_KEYS_NEW_FOR);
    std::wstring note = state.accounts.empty() ? core::T(PE_TEXT_UI_KEYS_NO_ACCOUNT)
                        : pe_pgp_private_keys_kept(core) ? L""
                                                          : core::T(PE_TEXT_UI_KEYS_MEMORY_ONLY);
    int pad = Scale(10), width = Scale(440), row = Scale(22);
    int labelWidth = LabelWidth({forLabel}, 90);
    int iconWidth = GetSystemMetrics(SM_CXSMICON) + Scale(6);
    int noteHeight = note.empty() ? 0 : std::max(GetSystemMetrics(SM_CYSMICON), static_cast<int>(MeasureText(note, width - 2 * pad - iconWidth).cy)) + Scale(12);
    int height = pad + row + Scale(12) + noteHeight + Scale(6) + Scale(25) + pad;
    HWND dialog = CreateModalWindow(owner, kNewKeyClass, core::Plain(PE_TEXT_UI_KEYS_NEW_TITLE).c_str(), width, height);
    int top = pad;
    CreateChild(dialog, L"STATIC", forLabel.c_str(), SS_LEFT, 0, {pad, top + Scale(3), pad + labelWidth, top + row});
    HWND choice = CreateChild(dialog, L"COMBOBOX", nullptr, WS_TABSTOP | WS_VSCROLL | CBS_DROPDOWNLIST, IDC_KEY_ACCOUNT,
                              {pad + labelWidth, top, width - pad, top + Scale(200)});
    for (const std::wstring& label : labels) {
        SendMessageW(choice, CB_ADDSTRING, 0, reinterpret_cast<LPARAM>(label.c_str()));
    }
    SendMessageW(choice, CB_SETCURSEL, chosen, 0);
    EnableWindow(choice, !state.accounts.empty());
    top += row + Scale(12);
    if (!note.empty()) {
        WarningNote(dialog, IDC_KEY_NOTE, note, pad + labelWidth, top, width - pad);
    }
    BottomButtons(dialog, width, height - pad - Scale(25), core::T(PE_TEXT_UI_KEYS_NEW_MAKE), core::T(PE_TEXT_UI_CANCEL));
    EnableWindow(Item(dialog, IDOK), !state.accounts.empty());
    SetWindowLongPtrW(dialog, GWLP_USERDATA, reinterpret_cast<LONG_PTR>(&state));
    RunModal(dialog, state.accounts.empty() ? Item(dialog, IDCANCEL) : Item(dialog, IDOK), state.done);
    return state.made;
}

// ---- backups, imports and exports ----

// Back Up: a passphrase asked twice, the key protected by it, saved where the user chooses
void BackUpKey(HWND owner, PeCore* core, const std::string& fingerprint) {
    std::wstring title = core::Plain(PE_TEXT_UI_KEYS_BACKUP_TITLE);
    std::string passphrase;
    if (!PassphraseDialog(owner, title, core::T(PE_TEXT_UI_KEYS_BACKUP_INTRO), L"", true, passphrase)) {
        return;
    }
    char* error = nullptr;
    core::String backup(pe_pgp_backup(core, fingerprint.c_str(), passphrase.c_str(), &error));
    Wipe(passphrase);
    if (!backup) {
        MessageBoxW(owner, ReasonText(error, PE_TEXT_UI_UNKNOWN_REASON).c_str(), title.c_str(), MB_OK | MB_ICONWARNING);
        return;
    }
    core::String unused(error);
    core::String name(pe_pgp_file_name(core, fingerprint.c_str(), true));
    std::wstring filter = KeyFilter(false);
    std::wstring path = SaveFileDialog(owner, Text(name.get()), core::Title(PE_TEXT_UI_KEYS_BACKUP_NOW).c_str(), filter.c_str(), L"asc");
    if (path.empty()) {
        return;
    }
    std::wstring why;
    if (!WriteKeyFile(path, backup.get(), why)) {
        MessageBoxW(owner, why.c_str(), title.c_str(), MB_OK | MB_ICONWARNING);
        return;
    }
    MessageBoxW(owner, core::T(PE_TEXT_UI_KEYS_BACKUP_SAVED).c_str(), title.c_str(), MB_OK | MB_ICONINFORMATION);
}

// right after a key was made: a backup offered, the only way back for it should this computer be lost
void OfferBackup(HWND owner, PeCore* core, const std::string& fingerprint) {
    if (Ask(owner, core::Plain(PE_TEXT_UI_KEYS_NEW_TITLE), core::T(PE_TEXT_UI_KEYS_BACKUP_OFFER), core::T(PE_TEXT_UI_KEYS_BACKUP_NOW),
            core::T(PE_TEXT_UI_KEYS_LATER))) {
        BackUpKey(owner, core, fingerprint);
    }
}

// own addresses an imported private key holds that have no key yet: used for it when the user says so (a key file can
// come from anyone, so it never takes them by itself)
void OfferUnclaimed(HWND owner, PeCore* core) {
    core::String question(pe_pgp_unclaimed_question(core));
    if (question && Ask(owner, core::Plain(PE_TEXT_UI_KEYS_IMPORT_TITLE), Text(question.get()), core::T(PE_TEXT_UI_KEYS_USE),
                        core::T(PE_TEXT_UI_KEYS_NOT_NOW))) {
        pe_pgp_claim_unclaimed(core);
    }
}

// Import: a key file chosen and handed to the core, its passphrase asked for while the core wants one; what was
// imported (or why nothing was) said. True when keys came in
bool ImportKeys(HWND owner, PeCore* core) {
    std::wstring filter = KeyFilter(true);
    std::wstring path = OpenFileDialog(owner, core::Title(PE_TEXT_UI_KEYS_IMPORT).c_str(), filter.c_str());
    if (path.empty()) {
        return false;
    }
    std::vector<uint8_t> bytes = ReadKeyFile(path);
    std::wstring title = core::Plain(PE_TEXT_UI_KEYS_IMPORT_TITLE);
    std::string passphrase;
    bool asked = false;
    PeImportOutcome outcome = PE_IMPORT_OUTCOME_INVALID;
    std::wstring said;
    for (;;) {
        char* message = nullptr;
        outcome = pe_pgp_import(core, bytes.data(), bytes.size(), asked ? passphrase.c_str() : nullptr, PE_KEY_SOURCE_FILE, &message);
        Wipe(passphrase);
        said = ReasonText(message, PE_TEXT_UI_UNKNOWN_REASON);
        if (outcome != PE_IMPORT_OUTCOME_NEEDS_PASSPHRASE && outcome != PE_IMPORT_OUTCOME_WRONG_PASSPHRASE) {
            break;
        }
        // asked again after a wrong one, with the core's words for it
        std::wstring problem = outcome == PE_IMPORT_OUTCOME_WRONG_PASSPHRASE ? said : L"";
        if (!PassphraseDialog(owner, title, core::T(PE_TEXT_UI_KEYS_IMPORT_PASSPHRASE), problem, false, passphrase)) {
            SecureZeroMemory(bytes.data(), bytes.size());
            return false;
        }
        asked = true;
    }
    SecureZeroMemory(bytes.data(), bytes.size());
    if (outcome != PE_IMPORT_OUTCOME_IMPORTED) {
        MessageBoxW(owner, said.c_str(), title.c_str(), MB_OK | MB_ICONWARNING);
        return false;
    }
    MessageBoxW(owner, said.c_str(), title.c_str(), MB_OK | MB_ICONINFORMATION);
    OfferUnclaimed(owner, core);
    return true;
}

// Export: the public key saved where the user chooses
void ExportKey(HWND owner, PeCore* core, const std::string& fingerprint) {
    core::String text(pe_pgp_export(core, fingerprint.c_str()));
    if (!text) {
        return;
    }
    core::String name(pe_pgp_file_name(core, fingerprint.c_str(), false));
    std::wstring filter = KeyFilter(false);
    std::wstring title = core::Title(PE_TEXT_UI_KEYS_EXPORT);
    std::wstring path = SaveFileDialog(owner, Text(name.get()), title.c_str(), filter.c_str(), L"asc");
    std::wstring why;
    if (!path.empty() && !WriteKeyFile(path, text.get(), why)) {
        MessageBoxW(owner, why.c_str(), title.c_str(), MB_OK | MB_ICONWARNING);
    }
}

// ---- Verify Key ----

const wchar_t* kVerifyClass = L"InboxClassicVerify";

struct VerifyState {
    PeCore* core = nullptr;
    std::string fingerprint;
    std::wstring name;
    HFONT font = nullptr;
    bool changed = false;
    bool done = false;
    bool accepted = false;
};

LRESULT CALLBACK VerifyProc(HWND hwnd, UINT message, WPARAM wParam, LPARAM lParam) {
    auto* state = reinterpret_cast<VerifyState*>(GetWindowLongPtrW(hwnd, GWLP_USERDATA));
    if (state && message == WM_COMMAND) {
        switch (LOWORD(wParam)) {
        case IDC_VERIFY_MATCH:
        case IDC_VERIFY_UNMARK:
            pe_pgp_set_key_verified(state->core, state->fingerprint.c_str(), LOWORD(wParam) == IDC_VERIFY_MATCH);
            state->changed = true;
            state->done = true;
            return 0;
        case IDC_VERIFY_DIFFER:
            // not marked: the key they have is another
            MessageBoxW(hwnd, core::T(PE_TEXT_UI_VERIFY_DIFFERS, {{"name", state->name}}).c_str(), core::Plain(PE_TEXT_UI_VERIFY_TITLE).c_str(),
                        MB_OK | MB_ICONWARNING);
            state->done = true;
            return 0;
        }
    }
    // the fingerprint in its box white, as a document is
    if (state && message == WM_CTLCOLORSTATIC && reinterpret_cast<HWND>(lParam) == Item(hwnd, IDC_KEY_FINGERPRINT)) {
        SetBkColor(reinterpret_cast<HDC>(wParam), GetSysColor(COLOR_WINDOW));
        return reinterpret_cast<LRESULT>(GetSysColorBrush(COLOR_WINDOW));
    }
    return SimpleProc<VerifyState>(hwnd, message, wParam, lParam);
}

}  // namespace

bool VerifyKeyDialog(HWND owner, PeCore* core, const std::string& fingerprint) {
    core::KeyList found(pe_pgp_key(core, fingerprint.c_str()));
    const PeKey* key = pe_pgp_key_list_get(found.get(), 0);
    if (!key) {
        return false;
    }
    HelpScope help("verify-key");
    RegisterDialogClass(kVerifyClass, VerifyProc);
    VerifyState state{core, fingerprint, Text(key->name)};
    std::wstring intro = core::T(PE_TEXT_UI_VERIFY_INTRO, {{"name", state.name}});
    std::wstring label = core::T(PE_TEXT_UI_VERIFY_FINGERPRINT);
    std::wstring lines = WithCrlf(Text(key->fingerprint_lines));
    int lineCount = 1 + static_cast<int>(std::count(lines.begin(), lines.end(), L'\n'));
    // about twice the size of the words around it, in a font whose 0 and O, 1 and l differ
    state.font = CreateFontW(-Scale(22), 0, 0, 0, FW_NORMAL, FALSE, FALSE, FALSE, DEFAULT_CHARSET, OUT_DEFAULT_PRECIS, CLIP_DEFAULT_PRECIS,
                             CLEARTYPE_QUALITY, FIXED_PITCH | FF_MODERN, L"Consolas");
    int pad = Scale(10), width = Scale(500);
    int introHeight = static_cast<int>(MeasureText(intro, width - 2 * pad).cy);
    int boxHeight = lineCount * Scale(28) + Scale(16);
    // not verified yet: under the box, every address They Match marks, so one that is not theirs is seen
    std::wstring marks = key->verified ? L"" : Text(key->verify_marks);
    int marksHeight = marks.empty() ? 0 : static_cast<int>(MeasureText(marks, width - 2 * pad).cy) + Scale(10);
    int height = pad + introHeight + Scale(12) + Scale(18) + boxHeight + marksHeight + Scale(16) + Scale(25) + pad;
    HWND dialog = CreateModalWindow(owner, kVerifyClass, core::Plain(PE_TEXT_UI_VERIFY_TITLE).c_str(), width, height);
    int top = pad;
    CreateChild(dialog, L"STATIC", intro.c_str(), SS_LEFT | SS_NOPREFIX, 0, {pad, top, width - pad, top + introHeight});
    top += introHeight + Scale(12);
    CreateChild(dialog, L"STATIC", label.c_str(), SS_LEFT | SS_NOPREFIX, 0, {pad, top, width - pad, top + Scale(16)});
    top += Scale(18);
    // a box that can not be changed, but can be selected and copied
    HWND box = CreateChild(dialog, L"EDIT", lines.c_str(), WS_TABSTOP | ES_MULTILINE | ES_READONLY | ES_CENTER, IDC_KEY_FINGERPRINT,
                           {pad, top, width - pad, top + boxHeight}, WS_EX_CLIENTEDGE);
    SendMessageW(box, WM_SETFONT, reinterpret_cast<WPARAM>(state.font), FALSE);
    // the lines in the middle of the box, top to bottom too
    RECT inside = {0, (boxHeight - lineCount * Scale(28)) / 2 - Scale(2), width - 2 * pad - Scale(4), boxHeight};
    SendMessageW(box, EM_SETRECT, 0, reinterpret_cast<LPARAM>(&inside));
    if (!marks.empty()) {
        top += boxHeight + Scale(10);
        CreateChild(dialog, L"STATIC", marks.c_str(), SS_LEFT | SS_NOPREFIX, 0, {pad, top, width - pad, top + marksHeight - Scale(10)});
    }
    // already verified: it can be taken back; otherwise the two answers, Cancel the default as a mark is no small thing
    struct Button {
        int id;
        std::wstring text;
    };
    std::vector<Button> buttons;
    if (key->verified) {
        buttons = {{IDC_VERIFY_UNMARK, core::T(PE_TEXT_UI_VERIFY_UNMARK)}, {IDCANCEL, core::T(PE_TEXT_UI_CLOSE)}};
    } else {
        buttons = {{IDC_VERIFY_MATCH, core::T(PE_TEXT_UI_VERIFY_MATCH)},
                   {IDC_VERIFY_DIFFER, core::T(PE_TEXT_UI_VERIFY_DIFFER)},
                   {IDCANCEL, core::T(PE_TEXT_UI_CANCEL)}};
    }
    std::vector<std::wstring> words;
    for (const Button& button : buttons) {
        words.push_back(button.text);
    }
    int buttonWidth = ButtonWidth(words);
    int left = width - pad - static_cast<int>(buttons.size()) * (buttonWidth + Scale(6)) + Scale(6);
    int buttonTop = height - pad - Scale(25);
    for (const Button& button : buttons) {
        DWORD style = WS_TABSTOP | (button.id == IDCANCEL ? BS_DEFPUSHBUTTON : 0);
        CreateChild(dialog, L"BUTTON", button.text.c_str(), style, button.id, {left, buttonTop, left + buttonWidth, buttonTop + Scale(25)});
        left += buttonWidth + Scale(6);
    }
    SetWindowLongPtrW(dialog, GWLP_USERDATA, reinterpret_cast<LONG_PTR>(&state));
    // the focus on the default button: Enter on another would press that one
    RunModal(dialog, Item(dialog, IDCANCEL), state.done);
    DeleteObject(state.font);
    return state.changed;
}

namespace {

// ---- Key Properties ----

const wchar_t* kKeyPropertiesClass = L"InboxClassicKeyProperties";

struct PropertiesState {
    PeCore* core = nullptr;
    std::string fingerprint;
    HFONT mono = nullptr;
    bool changed = false;
    bool done = false;
    bool accepted = false;
};

LRESULT CALLBACK PropertiesProc(HWND hwnd, UINT message, WPARAM wParam, LPARAM lParam) {
    auto* state = reinterpret_cast<PropertiesState*>(GetWindowLongPtrW(hwnd, GWLP_USERDATA));
    if (state && message == WM_COMMAND && LOWORD(wParam) == IDC_KEY_VERIFY) {
        if (VerifyKeyDialog(hwnd, state->core, state->fingerprint)) {
            state->changed = true;
            // what it says now
            core::KeyList found(pe_pgp_key(state->core, state->fingerprint.c_str()));
            if (const PeKey* key = pe_pgp_key_list_get(found.get(), 0)) {
                SetWindowTextW(Item(hwnd, IDC_KEY_STATUS), Text(key->status).c_str());
                SetWindowTextW(Item(hwnd, IDC_KEY_ADDRESSES), WithCrlf(Text(key->address_lines)).c_str());
            }
        }
        return 0;
    }
    return SimpleProc<PropertiesState>(hwnd, message, wParam, lParam);
}

// Key Properties: what there is to know of a key, a label and a value a row; Verify for a contact's key. True when it
// was verified (or no longer) there
bool KeyPropertiesDialog(HWND owner, PeCore* core, const std::string& fingerprint) {
    core::KeyList found(pe_pgp_key(core, fingerprint.c_str()));
    const PeKey* key = pe_pgp_key_list_get(found.get(), 0);
    if (!key) {
        return false;
    }
    RegisterDialogClass(kKeyPropertiesClass, PropertiesProc);
    PropertiesState state{core, fingerprint};
    std::wstring names = WithCrlf(Text(key->user_ids));
    std::wstring addresses = WithCrlf(Text(key->address_lines));
    int nameLines = 1 + static_cast<int>(std::count(names.begin(), names.end(), L'\n'));
    int addressLines = std::max(1, 1 + static_cast<int>(std::count(addresses.begin(), addresses.end(), L'\n')));
    struct Row {
        PeText label;
        int id;
        std::wstring value;
        int lines;
    };
    const Row rows[] = {
        {PE_TEXT_UI_KEY_NAMES, IDC_KEY_NAMES, names, nameLines},
        {PE_TEXT_UI_KEY_FINGERPRINT, IDC_KEY_FINGERPRINT, Text(key->grouped), 1},
        {PE_TEXT_UI_KEY_STATUS, IDC_KEY_STATUS, Text(key->status), 1},
        {PE_TEXT_UI_KEY_CREATED, IDC_KEY_CREATED, Text(key->created_text), 1},
        {PE_TEXT_UI_KEY_EXPIRES, IDC_KEY_EXPIRES, Text(key->expires_text), 1},
        {PE_TEXT_UI_KEY_ALGORITHM, IDC_KEY_ALGORITHM, Text(key->algorithm), 1},
        {PE_TEXT_UI_KEY_SOURCE, IDC_KEY_SOURCE, Text(key->source), 1},
        {PE_TEXT_UI_KEY_ADDRESSES, IDC_KEY_ADDRESSES, addresses, addressLines},
    };
    std::vector<std::wstring> labels;
    for (const Row& row : rows) {
        labels.push_back(core::T(row.label));
    }
    int pad = Scale(10), width = Scale(500), line = Scale(16), gap = Scale(8);
    int labelWidth = LabelWidth(labels, 90, 12);
    int height = pad;
    for (const Row& row : rows) {
        height += row.lines * line + gap;
    }
    height += Scale(8) + Scale(25) + pad;
    HWND dialog = CreateModalWindow(owner, kKeyPropertiesClass, core::Plain(PE_TEXT_UI_KEY_PROPERTIES_TITLE).c_str(), width, height);
    state.mono = CreateFontW(-Scale(13), 0, 0, 0, FW_NORMAL, FALSE, FALSE, FALSE, DEFAULT_CHARSET, OUT_DEFAULT_PRECIS, CLIP_DEFAULT_PRECIS,
                             CLEARTYPE_QUALITY, FIXED_PITCH | FF_MODERN, L"Consolas");
    int top = pad;
    for (size_t i = 0; i < std::size(rows); i++) {
        const Row& row = rows[i];
        int bottom = top + row.lines * line;
        CreateChild(dialog, L"STATIC", labels[i].c_str(), SS_LEFT | SS_NOPREFIX, 0, {pad, top, pad + labelWidth, top + line});
        RECT value = {pad + labelWidth, top, width - pad, bottom};
        if (row.id == IDC_KEY_FINGERPRINT) {
            // to select and copy: a box that looks like the words around it
            HWND box = CreateChild(dialog, L"EDIT", row.value.c_str(), WS_TABSTOP | ES_READONLY | ES_AUTOHSCROLL, row.id,
                                   {value.left, value.top - Scale(1), value.right, value.bottom + Scale(1)});
            SendMessageW(box, WM_SETFONT, reinterpret_cast<WPARAM>(state.mono), FALSE);
            // its words where the other values' start
            SendMessageW(box, EM_SETMARGINS, EC_LEFTMARGIN | EC_RIGHTMARGIN, 0);
        } else {
            CreateChild(dialog, L"STATIC", row.value.c_str(), SS_LEFT | SS_NOPREFIX, row.id, value);
        }
        top = bottom + gap;
    }
    std::wstring close = core::T(PE_TEXT_UI_CLOSE);
    int buttonTop = height - pad - Scale(25);
    int closeWidth = ButtonWidth({close});
    // Verify apart, at the left: it opens a window rather than closing this one
    if (!key->own) {
        std::wstring verify = core::T(PE_TEXT_UI_KEYS_VERIFY);
        CreateChild(dialog, L"BUTTON", verify.c_str(), WS_TABSTOP, IDC_KEY_VERIFY, {pad, buttonTop, pad + ButtonWidth({verify}), buttonTop + Scale(25)});
    }
    CreateChild(dialog, L"BUTTON", close.c_str(), WS_TABSTOP | BS_DEFPUSHBUTTON, IDCANCEL,
                {width - pad - closeWidth, buttonTop, width - pad, buttonTop + Scale(25)});
    SetWindowLongPtrW(dialog, GWLP_USERDATA, reinterpret_cast<LONG_PTR>(&state));
    RunModal(dialog, Item(dialog, IDCANCEL), state.done);
    DeleteObject(state.mono);
    return state.changed;
}

// ---- the Encryption Keys window ----

const wchar_t* kKeysClass = L"InboxClassicKeys";

enum KeysColumn { KEYS_NAME, KEYS_ADDRESS, KEYS_KIND, KEYS_STATUS };

struct KeysState {
    PeCore* core = nullptr;
    HWND list = nullptr;
    core::KeyList keys;
    bool done = false;
};

const PeKey* KeyAt(const KeysState& state, int row) {
    return row >= 0 ? pe_pgp_key_list_get(state.keys.get(), static_cast<size_t>(row)) : nullptr;
}

int SelectedIndex(const KeysState& state) {
    return ListView_GetNextItem(state.list, -1, LVNI_SELECTED);
}

// the buttons for the selected key where they apply: Back Up an own key that can be opened, Verify a contact's
void ShowSelected(HWND hwnd, const KeysState& state) {
    const PeKey* key = KeyAt(state, SelectedIndex(state));
    EnableWindow(Item(hwnd, IDC_KEYS_EXPORT), key != nullptr);
    EnableWindow(Item(hwnd, IDC_KEYS_BACKUP), key && key->can_back_up);
    EnableWindow(Item(hwnd, IDC_KEYS_VERIFY), key && key->can_verify);
    EnableWindow(Item(hwnd, IDC_KEYS_PROPERTIES), key != nullptr);
    EnableWindow(Item(hwnd, IDC_KEYS_REMOVE), key != nullptr);
}

// a row per key, own keys first; the key `select` selected when it is there, else the row `row`
void FillKeys(HWND hwnd, KeysState& state, const std::string& select = "", int row = 0) {
    ListView_DeleteAllItems(state.list);
    state.keys.reset(pe_pgp_keys(state.core));
    for (size_t i = 0; i < pe_pgp_key_list_count(state.keys.get()); i++) {
        const PeKey* key = pe_pgp_key_list_get(state.keys.get(), i);
        int added = AddRow(state.list, static_cast<int>(i), Text(key->name));
        std::wstring addresses = Text(key->addresses);
        SetCell(state.list, added, KEYS_ADDRESS, addresses.substr(0, addresses.find(L'\n')));
        SetCell(state.list, added, KEYS_KIND, core::T(key->own ? PE_TEXT_UI_KEYS_KIND_OWN : PE_TEXT_UI_KEYS_KIND_CONTACT));
        SetCell(state.list, added, KEYS_STATUS, Text(key->status));
        if (!select.empty() && select == key->fingerprint) {
            row = added;
        }
    }
    SelectRow(state.list, row);
    ShowSelected(hwnd, state);
    // the empty list's words drawn again, or taken away
    InvalidateRect(state.list, nullptr, TRUE);
}

// in the middle of the list while it has no key: how to get one
void DrawEmptyKeys(HWND list, HDC dc) {
    RECT area;
    GetClientRect(list, &area);
    RECT header;
    GetWindowRect(ListView_GetHeader(list), &header);
    area.top += (header.bottom - header.top) + Scale(24);
    InflateRect(&area, -Scale(16), 0);
    std::wstring text = core::T(PE_TEXT_UI_KEYS_EMPTY);
    HGDIOBJ old = SelectObject(dc, reinterpret_cast<HFONT>(SendMessageW(list, WM_GETFONT, 0, 0)));
    SetTextColor(dc, GetSysColor(COLOR_GRAYTEXT));
    SetBkMode(dc, TRANSPARENT);
    DrawTextW(dc, text.c_str(), -1, &area, DT_CENTER | DT_WORDBREAK | DT_NOPREFIX);
    SelectObject(dc, old);
}

// Remove, asked first in words that say what goes with the key
void RemoveKey(HWND hwnd, KeysState& state, const PeKey& key, int index) {
    std::wstring question = Text(key.remove_question);
    if (MessageBoxW(hwnd, question.c_str(), KeysTitle().c_str(), MB_YESNO | MB_ICONWARNING | MB_DEFBUTTON2) != IDYES) {
        return;
    }
    pe_pgp_remove(state.core, key.fingerprint);
    FillKeys(hwnd, state, "", index);
    SetFocus(state.list);
}

void OnKeysCommand(HWND hwnd, KeysState& state, WORD id) {
    int index = SelectedIndex(state);
    const PeKey* key = KeyAt(state, index);
    // the key's fingerprint outlives the rows, which a refill replaces
    std::string fingerprint = key ? key->fingerprint : "";
    switch (id) {
    case IDC_KEYS_NEW: {
        std::string made = NewKeyDialog(hwnd, state.core);
        if (!made.empty()) {
            FillKeys(hwnd, state, made);
            OfferBackup(hwnd, state.core, made);
        }
        return;
    }
    case IDC_KEYS_IMPORT:
        if (ImportKeys(hwnd, state.core)) {
            FillKeys(hwnd, state, fingerprint, index);
        }
        return;
    case IDC_KEYS_EXPORT:
        if (key) {
            ExportKey(hwnd, state.core, fingerprint);
        }
        return;
    case IDC_KEYS_BACKUP:
        if (key && key->own) {
            BackUpKey(hwnd, state.core, fingerprint);
        }
        return;
    case IDC_KEYS_VERIFY:
        if (key && !key->own && VerifyKeyDialog(hwnd, state.core, fingerprint)) {
            FillKeys(hwnd, state, fingerprint);
        }
        return;
    case IDC_KEYS_PROPERTIES:
        if (key && KeyPropertiesDialog(hwnd, state.core, fingerprint)) {
            FillKeys(hwnd, state, fingerprint);
        }
        return;
    case IDC_KEYS_REMOVE:
        if (key) {
            RemoveKey(hwnd, state, *key, index);
        }
        return;
    case IDC_KEYS_CLOSE:
    case IDCANCEL:
        state.done = true;
        return;
    }
}

LRESULT CALLBACK KeysProc(HWND hwnd, UINT message, WPARAM wParam, LPARAM lParam) {
    auto* state = reinterpret_cast<KeysState*>(GetWindowLongPtrW(hwnd, GWLP_USERDATA));
    switch (message) {
    case WM_COMMAND:
        if (state) {
            // Enter in the list is IDOK of the window: Properties of the selected key
            WORD id = LOWORD(wParam) == IDOK && GetFocus() == state->list ? static_cast<WORD>(IDC_KEYS_PROPERTIES) : LOWORD(wParam);
            OnKeysCommand(hwnd, *state, id);
        }
        return 0;
    case WM_NOTIFY: {
        auto* header = reinterpret_cast<NMHDR*>(lParam);
        if (!state || header->hwndFrom != state->list) {
            return 0;
        }
        if (header->code == NM_CUSTOMDRAW) {
            auto* draw = reinterpret_cast<NMLVCUSTOMDRAW*>(lParam);
            if (draw->nmcd.dwDrawStage == CDDS_PREPAINT) {
                return CDRF_NOTIFYPOSTPAINT;
            }
            if (draw->nmcd.dwDrawStage == CDDS_POSTPAINT && ListView_GetItemCount(state->list) == 0) {
                DrawEmptyKeys(state->list, draw->nmcd.hdc);
            }
            return CDRF_DODEFAULT;
        }
        if (header->code == LVN_ITEMCHANGED) {
            auto* change = reinterpret_cast<NMLISTVIEW*>(lParam);
            if ((change->uChanged & LVIF_STATE) && ((change->uNewState ^ change->uOldState) & LVIS_SELECTED)) {
                ShowSelected(hwnd, *state);
            }
        } else if (header->code == LVN_ITEMACTIVATE) {
            OnKeysCommand(hwnd, *state, IDC_KEYS_PROPERTIES);
        } else if (header->code == LVN_KEYDOWN && reinterpret_cast<NMLVKEYDOWN*>(lParam)->wVKey == VK_DELETE) {
            OnKeysCommand(hwnd, *state, IDC_KEYS_REMOVE);
        }
        return 0;
    }
    case WM_CLOSE:
        if (state) {
            state->done = true;
        }
        return 0;
    case WM_CTLCOLORSTATIC:
        return ButtonFaceColor(reinterpret_cast<HDC>(wParam));
    }
    return DefWindowProcW(hwnd, message, wParam, lParam);
}

// ---- Account Properties > Security ----

class AccountSecurity : public FormPart {
public:
    AccountSecurity(PeCore* core, int64_t account) : core_(core), account_(account) {
        // the key the account's own address uses, and whether its mail carries it
        core::String key(pe_pgp_account_key(core, account, &autocrypt_));
        chosen_ = key ? key.get() : "";
    }

    int Height(int width) const override {
        int inner = width - 2 * Scale(10);
        int intro = static_cast<int>(MeasureText(core::T(PE_TEXT_UI_ACCOUNT_SECURITY_INTRO), inner).cy);
        // the line apart from the fields, the heading, the intro, the key and New Key, Autocrypt
        return Scale(10) + Scale(20) + intro + Scale(10) + Scale(25) + Scale(8) + Scale(20);
    }

    void Create(HWND form, const RECT& area) override {
        // apart from the account's fields above, as the rule editor sets its actions apart
        int left = area.left, right = area.right;
        int top = area.top + Scale(4);
        CreateChild(form, L"STATIC", L"", SS_ETCHEDHORZ, 0, {left, top, right, top + 2});
        top += Scale(6);
        CreateChild(form, L"STATIC", core::T(PE_TEXT_UI_ACCOUNT_SECURITY).c_str(), SS_LEFT | SS_NOPREFIX, 0, {left, top, right, top + Scale(16)});
        top += Scale(20);
        std::wstring intro = core::T(PE_TEXT_UI_ACCOUNT_SECURITY_INTRO);
        int introHeight = static_cast<int>(MeasureText(intro, right - left).cy);
        CreateChild(form, L"STATIC", intro.c_str(), SS_LEFT | SS_NOPREFIX, 0, {left, top, right, top + introHeight});
        top += introHeight + Scale(10);
        std::wstring label = core::T(PE_TEXT_UI_ACCOUNT_KEY), newKey = core::T(PE_TEXT_UI_ACCOUNT_KEY_NEW);
        int labelWidth = LabelWidth({label}, 60);
        int buttonWidth = ButtonWidth({newKey});
        CreateChild(form, L"STATIC", label.c_str(), SS_LEFT, 0, {left, top + Scale(4), left + labelWidth, top + Scale(22)});
        CreateChild(form, L"COMBOBOX", nullptr, WS_TABSTOP | WS_VSCROLL | CBS_DROPDOWNLIST, IDC_ACCOUNT_KEY,
                    {left + labelWidth, top + Scale(1), right - buttonWidth - Scale(6), top + Scale(200)});
        CreateChild(form, L"BUTTON", newKey.c_str(), WS_TABSTOP, IDC_ACCOUNT_KEY_NEW, {right - buttonWidth, top, right, top + Scale(25)});
        top += Scale(25) + Scale(8);
        HWND autocrypt = CreateChild(form, L"BUTTON", core::T(PE_TEXT_UI_ACCOUNT_AUTOCRYPT).c_str(), WS_TABSTOP | BS_AUTOCHECKBOX,
                                     IDC_ACCOUNT_AUTOCRYPT, {left, top, right, top + Scale(20)});
        SendMessageW(autocrypt, BM_SETCHECK, autocrypt_ ? BST_CHECKED : BST_UNCHECKED, 0);
        FillChoice(form);
    }

    void Command(HWND form, int id, int code) override {
        if (id != IDC_ACCOUNT_KEY_NEW || code != BN_CLICKED) {
            return;
        }
        // a key made for this account at once, and chosen; a backup offered as anywhere a key is made
        std::string made = NewKeyDialog(form, core_, account_);
        if (made.empty()) {
            return;
        }
        chosen_ = made;
        FillChoice(form);
        OfferBackup(form, core_, made);
    }

    void Accept(HWND form) override {
        auto index = static_cast<int>(SendMessageW(Item(form, IDC_ACCOUNT_KEY), CB_GETCURSEL, 0, 0));
        chosen_ = index >= 0 && static_cast<size_t>(index) < offered_.size() ? offered_[index] : "";
        autocrypt_ = SendMessageW(Item(form, IDC_ACCOUNT_AUTOCRYPT), BM_GETCHECK, 0, 0) == BST_CHECKED;
    }

    // the chosen key made the account's; None takes it away (the core changes nothing when neither it nor Autocrypt
    // changed, and leaves other addresses with a key of their own alone)
    void Apply() const {
        pe_pgp_set_account_key(core_, account_, chosen_.c_str(), autocrypt_);
    }

private:
    // None, then each own key by its name and the end of its fingerprint; the chosen one selected
    void FillChoice(HWND form) {
        HWND choice = Item(form, IDC_ACCOUNT_KEY);
        SendMessageW(choice, CB_RESETCONTENT, 0, 0);
        offered_ = {""};
        SendMessageW(choice, CB_ADDSTRING, 0, reinterpret_cast<LPARAM>(core::T(PE_TEXT_UI_ACCOUNT_KEY_NONE).c_str()));
        int selected = 0;
        core::KeyList keys(pe_pgp_keys(core_));
        for (size_t i = 0; i < pe_pgp_key_list_count(keys.get()); i++) {
            const PeKey* key = pe_pgp_key_list_get(keys.get(), i);
            if (!key->own) {
                continue;
            }
            SendMessageW(choice, CB_ADDSTRING, 0, reinterpret_cast<LPARAM>(Text(key->choice).c_str()));
            if (chosen_ == key->fingerprint) {
                selected = static_cast<int>(offered_.size());
            }
            offered_.push_back(key->fingerprint);
        }
        SendMessageW(choice, CB_SETCURSEL, selected, 0);
    }

    PeCore* core_;
    int64_t account_;
    // the fingerprint of each row of the choice, "" for None
    std::vector<std::string> offered_;
    std::string chosen_;
    bool autocrypt_ = true;
};

}  // namespace

void EncryptionKeysDialog(HWND owner, PeCore* core) {
    HelpScope help("encryption-keys");
    RegisterDialogClass(kKeysClass, KeysProc);
    int pad = Scale(10), width = Scale(640), height = Scale(360);
    struct Button {
        WORD id;
        std::wstring text;
    };
    Button buttons[] = {{IDC_KEYS_NEW, core::T(PE_TEXT_UI_KEYS_NEW)},
                        {IDC_KEYS_IMPORT, core::T(PE_TEXT_UI_KEYS_IMPORT)},
                        {IDC_KEYS_EXPORT, core::T(PE_TEXT_UI_KEYS_EXPORT)},
                        {IDC_KEYS_BACKUP, core::T(PE_TEXT_UI_KEYS_BACKUP)},
                        {IDC_KEYS_VERIFY, core::T(PE_TEXT_UI_KEYS_VERIFY)},
                        {IDC_KEYS_PROPERTIES, core::T(PE_TEXT_WIN_PROPERTIES_BUTTON)},
                        {IDC_KEYS_REMOVE, core::T(PE_TEXT_UI_REMOVE)}};
    std::wstring close = core::T(PE_TEXT_UI_CLOSE), intro = core::T(PE_TEXT_UI_KEYS_INTRO);
    std::vector<std::wstring> words = {close};
    for (const Button& button : buttons) {
        words.push_back(button.text);
    }
    int buttonWidth = ButtonWidth(words, 100);
    int introHeight = static_cast<int>(MeasureText(intro, width - 2 * pad).cy);
    HWND dialog = CreateModalWindow(owner, kKeysClass, core::Plain(PE_TEXT_UI_KEYS_TITLE).c_str(), width, height);
    KeysState state{core};
    int listRight = width - pad - buttonWidth - pad;
    int top = pad;
    CreateChild(dialog, L"STATIC", intro.c_str(), SS_LEFT | SS_NOPREFIX, 0, {pad, top, width - pad, top + introHeight});
    top += introHeight + Scale(10);
    state.list = CreateReportList(dialog, IDC_KEYS_LIST, {pad, top, listRight, height - pad});
    // the status the rest: "Valid until 3 May 2027" and the reason a key can not be used are its longest words
    AddColumn(state.list, KEYS_NAME, core::T(PE_TEXT_UI_KEYS_COL_NAME).c_str(), 120);
    AddColumn(state.list, KEYS_ADDRESS, core::T(PE_TEXT_UI_KEYS_COL_ADDRESS).c_str(), 150);
    AddColumn(state.list, KEYS_KIND, core::T(PE_TEXT_UI_KEYS_COL_KIND).c_str(), 75);
    AddColumn(state.list, KEYS_STATUS, core::T(PE_TEXT_UI_KEYS_COL_STATUS).c_str(), 100);
    ListView_SetColumnWidth(state.list, KEYS_STATUS, LVSCW_AUTOSIZE_USEHEADER);
    int buttonTop = top;
    for (size_t i = 0; i < std::size(buttons); i++) {
        // the buttons for the selected key apart from New Key and Import
        if (i == 2) {
            buttonTop += Scale(12);
        }
        CreateChild(dialog, L"BUTTON", buttons[i].text.c_str(), WS_TABSTOP, buttons[i].id,
                    {width - pad - buttonWidth, buttonTop, width - pad, buttonTop + Scale(25)});
        buttonTop += Scale(31);
    }
    CreateChild(dialog, L"BUTTON", close.c_str(), WS_TABSTOP | BS_DEFPUSHBUTTON, IDC_KEYS_CLOSE,
                {width - pad - buttonWidth, height - pad - Scale(25), width - pad, height - pad});
    SetWindowLongPtrW(dialog, GWLP_USERDATA, reinterpret_cast<LONG_PTR>(&state));
    FillKeys(dialog, state);
    RunModal(dialog, state.list, state.done);
}

std::unique_ptr<FormPart> AccountSecurityPart(PeCore* core, int64_t account) {
    return std::make_unique<AccountSecurity>(core, account);
}

void ApplyAccountSecurity(FormPart& part) {
    static_cast<AccountSecurity&>(part).Apply();
}

std::string NewKeyFor(HWND owner, PeCore* core, int64_t account) {
    std::string made = NewKeyDialog(owner, core, account);
    if (!made.empty()) {
        OfferBackup(owner, core, made);
    }
    return made;
}
