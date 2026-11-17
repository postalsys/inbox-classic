// Tools > Options: a property sheet of the pages of core/settings.toml (settings.h), each a tab with its groups; and the
// language the app starts in. OK and Apply set what the pages show, Cancel leaves everything as the last Apply did. The
// words come from the core's catalogs; the language is read once, at start, so another one takes a restart.
#include "app.h"
#include "settings.h"

#include <shellapi.h>
#include <shobjidl.h>
#include <windowsx.h>
#include <wrl/client.h>

#include <algorithm>
#include <array>
#include <cwctype>

// a setting of core/settings.toml that AddSetting's switch leaves out fails the build
#pragma warning(error : 4062)

namespace {

const wchar_t* kOptionsClass = L"InboxClassicOptions";
const wchar_t* kRestartClass = L"InboxClassicRestart";
const wchar_t* kTrustedClass = L"InboxClassicTrustedSenders";
// what the installer registers .eml files and mailto links to, and the app as (installer/inbox-classic.nsi: EMLCLASS,
// MAILTOCLASS, PRODUCT)
const wchar_t* kEmlClass = L"InboxClassic.eml";
const wchar_t* kMailtoClass = L"InboxClassic.mailto";
const wchar_t* kRegisteredName = L"Inbox Classic";
// the code chosen in Options (`de`), set by the installer on a first install too; empty or missing: Windows' language
const wchar_t* kLanguagePreference = L"Language";

// the language of Windows' display languages, most preferred first, there is a catalog of (`en` when none)
std::wstring SystemLanguage() {
    ULONG count = 0, size = 0;
    if (!GetUserPreferredUILanguages(MUI_LANGUAGE_NAME, &count, nullptr, &size) || size == 0) {
        return L"en";
    }
    std::vector<wchar_t> names(size);
    if (!GetUserPreferredUILanguages(MUI_LANGUAGE_NAME, &count, names.data(), &size)) {
        return L"en";
    }
    // a list of strings ended by an empty one
    std::vector<std::string> codes;
    for (const wchar_t* name = names.data(); *name; name += wcslen(name) + 1) {
        codes.push_back(core::Narrow(name));
    }
    std::vector<const char*> pointers;
    for (const std::string& code : codes) {
        pointers.push_back(code.c_str());
    }
    core::String resolved(pe_resolve_language(pointers.data(), pointers.size()));
    return resolved ? Text(resolved.get()) : L"en";
}

struct Language {
    std::wstring code;
    std::wstring name;
};

// the languages there is a catalog of, by their own names
std::vector<Language> Languages() {
    std::vector<Language> languages;
    PeLanguageList* list = pe_languages();
    for (size_t i = 0; i < pe_language_list_count(list); i++) {
        const PeLanguage* language = pe_language_list_get(list, i);
        languages.push_back({Text(language->code), Text(language->name)});
    }
    pe_language_list_free(list);
    return languages;
}

// ---- Trusted Senders ----

struct TrustedState {
    PeCore* core = nullptr;
    bool done = false;
    HWND list = nullptr;
    HWND remove = nullptr;
    HWND empty = nullptr;
    // the senders' ids, a row each
    std::vector<int64_t> ids;
    // the senders removed, untrusted when Options' OK or Apply is clicked
    std::vector<int64_t>* removed = nullptr;
};

// the list from the core again, without the senders removed; with none, the words that say so in its place
void FillTrusted(TrustedState& state) {
    ListView_DeleteAllItems(state.list);
    state.ids.clear();
    PeTrustedSenderList* senders = pe_trusted_senders(state.core);
    for (size_t i = 0; i < pe_trusted_sender_list_count(senders); i++) {
        const PeTrustedSender* sender = pe_trusted_sender_list_get(senders, i);
        if (std::find(state.removed->begin(), state.removed->end(), sender->id) != state.removed->end()) {
            continue;
        }
        std::wstring label = Text(sender->label);
        LVITEMW item = {LVIF_TEXT};
        item.iItem = static_cast<int>(state.ids.size());
        item.pszText = label.data();
        ListView_InsertItem(state.list, &item);
        state.ids.push_back(sender->id);
    }
    pe_trusted_sender_list_free(senders);
    bool none = state.ids.empty();
    ShowWindow(state.list, none ? SW_HIDE : SW_SHOW);
    ShowWindow(state.empty, none ? SW_SHOW : SW_HIDE);
    EnableWindow(state.remove, FALSE);
}

void RemoveTrusted(TrustedState& state) {
    for (int row = -1; (row = ListView_GetNextItem(state.list, row, LVNI_SELECTED)) >= 0;) {
        if (static_cast<size_t>(row) < state.ids.size()) {
            state.removed->push_back(state.ids[row]);
        }
    }
    FillTrusted(state);
    SetFocus(state.ids.empty() ? GetDlgItem(GetParent(state.list), IDOK) : state.list);
}

LRESULT CALLBACK TrustedProc(HWND hwnd, UINT message, WPARAM wParam, LPARAM lParam) {
    auto* state = reinterpret_cast<TrustedState*>(GetWindowLongPtrW(hwnd, GWLP_USERDATA));
    if (!state) {
        return DefWindowProcW(hwnd, message, wParam, lParam);
    }
    switch (message) {
    case WM_CLOSE:
        state->done = true;
        return 0;
    case WM_COMMAND:
        if (LOWORD(wParam) == IDOK || LOWORD(wParam) == IDCANCEL) {
            state->done = true;
        } else if (LOWORD(wParam) == IDC_TRUSTED_REMOVE) {
            RemoveTrusted(*state);
        }
        return 0;
    case WM_NOTIFY: {
        auto* header = reinterpret_cast<NMHDR*>(lParam);
        if (header->hwndFrom == state->list && header->code == LVN_ITEMCHANGED) {
            EnableWindow(state->remove, ListView_GetSelectedCount(state->list) > 0);
        } else if (header->hwndFrom == state->list && header->code == LVN_KEYDOWN &&
                   reinterpret_cast<NMLVKEYDOWN*>(lParam)->wVKey == VK_DELETE) {
            RemoveTrusted(*state);
        }
        return 0;
    }
    case WM_CTLCOLORSTATIC:
        return ButtonFaceColor(reinterpret_cast<HDC>(wParam));
    }
    return DefWindowProcW(hwnd, message, wParam, lParam);
}

// the senders whose pictures load by themselves, each with Remove; the ones removed are added to `removed`, for
// Options to untrust on OK or Apply
void TrustedSendersDialog(HWND owner, PeCore* core, std::vector<int64_t>& removed) {
    RegisterDialogClass(kTrustedClass, TrustedProc);
    std::wstring note = core::T(PE_TEXT_UI_TRUSTED_SENDERS_NOTE), remove = core::T(PE_TEXT_UI_REMOVE);
    std::wstring close = core::T(PE_TEXT_UI_CLOSE);
    int pad = Scale(12), width = Scale(400), inner = width - 2 * pad;
    int noteHeight = static_cast<int>(MeasureText(note, inner).cy), listHeight = Scale(180);
    int height = pad + noteHeight + Scale(8) + listHeight + Scale(12) + Scale(25) + pad;
    HWND dialog = CreateModalWindow(owner, kTrustedClass, core::Title(PE_TEXT_UI_TRUSTED_SENDERS_TITLE).c_str(), width, height);
    TrustedState state;
    state.core = core;
    state.removed = &removed;
    int y = pad;
    CreateChild(dialog, L"STATIC", note.c_str(), SS_LEFT | SS_NOPREFIX, 0, {pad, y, width - pad, y + noteHeight});
    y += noteHeight + Scale(8);
    RECT box = {pad, y, width - pad, y + listHeight};
    state.list = CreateChild(dialog, WC_LISTVIEWW, nullptr, WS_TABSTOP | LVS_REPORT | LVS_NOCOLUMNHEADER | LVS_SHOWSELALWAYS | LVS_NOSORTHEADER,
                             IDC_TRUSTED_LIST, box, WS_EX_CLIENTEDGE);
    ListView_SetExtendedListViewStyle(state.list, LVS_EX_FULLROWSELECT);
    LVCOLUMNW column = {LVCF_WIDTH};
    column.cx = inner - GetSystemMetrics(SM_CXVSCROLL) - Scale(6);
    ListView_InsertColumn(state.list, 0, &column);
    // in the list's place while there is nobody in it
    std::wstring none = core::T(PE_TEXT_UI_TRUSTED_SENDERS_EMPTY);
    state.empty = CreateChild(dialog, L"STATIC", none.c_str(), SS_CENTER | SS_NOPREFIX | SS_SUNKEN, IDC_TRUSTED_EMPTY,
                              {box.left, box.top, box.right, box.top + Scale(40)});
    int buttonWidth = ButtonWidth({remove, close}), buttonTop = height - pad - Scale(25);
    state.remove = CreateChild(dialog, L"BUTTON", remove.c_str(), WS_TABSTOP, IDC_TRUSTED_REMOVE,
                               {pad, buttonTop, pad + buttonWidth, buttonTop + Scale(25)});
    HWND closeButton = CreateChild(dialog, L"BUTTON", close.c_str(), WS_TABSTOP | BS_DEFPUSHBUTTON, IDOK,
                                   {width - pad - buttonWidth, buttonTop, width - pad, buttonTop + Scale(25)});
    FillTrusted(state);
    SetWindowLongPtrW(dialog, GWLP_USERDATA, reinterpret_cast<LONG_PTR>(&state));
    RunModal(dialog, state.ids.empty() ? closeButton : state.list, state.done);
}

// ---- default apps ----

// whether `name` (a file extension or a link's protocol, of `type`) opens with `ours` now
bool OpensWithUs(const wchar_t* name, ASSOCIATIONTYPE type, const wchar_t* ours) {
    Microsoft::WRL::ComPtr<IApplicationAssociationRegistration> associations;
    LPWSTR current = nullptr;
    if (FAILED(CoCreateInstance(CLSID_ApplicationAssociationRegistration, nullptr, CLSCTX_INPROC_SERVER, IID_PPV_ARGS(&associations))) ||
        FAILED(associations->QueryCurrentDefault(name, type, AL_EFFECTIVE, &current))) {
        return false;
    }
    bool same = _wcsicmp(current, ours) == 0;
    CoTaskMemFree(current);
    return same;
}

// whether the installer listed this copy among the apps Windows' Default Apps settings offer
bool Registered() {
    DWORD size = 0;
    return RegGetValueW(HKEY_CURRENT_USER, L"Software\\RegisteredApplications", kRegisteredName, RRF_RT_REG_SZ, nullptr, nullptr, &size) ==
           ERROR_SUCCESS;
}

void OpenDefaultAppsSettings(HWND owner) {
    ShellExecuteW(owner, L"open", L"ms-settings:defaultapps?registeredAppUser=Inbox%20Classic", nullptr, nullptr, SW_SHOWNORMAL);
}

void Tell(HWND owner, const std::wstring& text) {
    MessageBoxW(owner, text.c_str(), L"Inbox Classic", MB_OK | MB_ICONINFORMATION);
}

// Open .eml Files with Inbox Classic: Windows lets only the user choose it, in Settings, where the installer listed
// the app; said so when it is chosen already, or when this copy was not installed
void MakeDefaultEmlApp(HWND owner) {
    if (OpensWithUs(L".eml", AT_FILEEXTENSION, kEmlClass)) {
        Tell(owner, core::T(PE_TEXT_UI_EML_DEFAULT_DONE));
    } else if (!Registered()) {
        Tell(owner, core::T(PE_TEXT_UI_EML_DEFAULT_FAILED, {{"reason", core::T(PE_TEXT_WIN_DEFAULT_APP_NOT_INSTALLED)}}));
    } else {
        OpenDefaultAppsSettings(owner);
    }
}

// ---- the restart question ----

struct RestartState {
    bool done = false;
    bool accepted = false;
};

LRESULT CALLBACK RestartProc(HWND hwnd, UINT message, WPARAM wParam, LPARAM lParam) {
    auto* state = reinterpret_cast<RestartState*>(GetWindowLongPtrW(hwnd, GWLP_USERDATA));
    if (state && ((message == WM_COMMAND && (LOWORD(wParam) == IDOK || LOWORD(wParam) == IDCANCEL)) || message == WM_CLOSE)) {
        state->accepted = message == WM_COMMAND && LOWORD(wParam) == IDOK;
        state->done = true;
        return 0;
    }
    if (message == WM_CTLCOLORSTATIC) {
        return ButtonFaceColor(reinterpret_cast<HDC>(wParam));
    }
    return DefWindowProcW(hwnd, message, wParam, lParam);
}

// asks whether to restart now for the language `name`: true for Restart Now, false for Later
bool AskRestart(HWND owner, const std::wstring& name) {
    RegisterDialogClass(kRestartClass, RestartProc);
    std::wstring text = core::T(PE_TEXT_UI_RESTART_ASK, {{"language", name}});
    std::wstring now = core::T(PE_TEXT_UI_RESTART_NOW), later = core::T(PE_TEXT_UI_RESTART_LATER);
    int pad = Scale(12), width = Scale(360);
    int textHeight = std::max(Scale(32), static_cast<int>(MeasureText(text, width - 2 * pad).cy));
    int buttonWidth = ButtonWidth({now, later});
    int height = pad + textHeight + Scale(14) + Scale(25) + pad;
    HWND dialog = CreateModalWindow(owner, kRestartClass, core::Title(PE_TEXT_CMD_OPTIONS).c_str(), width, height);
    RestartState state;
    SetWindowLongPtrW(dialog, GWLP_USERDATA, reinterpret_cast<LONG_PTR>(&state));
    CreateChild(dialog, L"STATIC", text.c_str(), SS_LEFT | SS_NOPREFIX, 0, {pad, pad, width - pad, pad + textHeight});
    int top = height - pad - Scale(25);
    HWND restart = CreateChild(dialog, L"BUTTON", now.c_str(), WS_TABSTOP | BS_DEFPUSHBUTTON, IDOK,
                               {width - pad - 2 * buttonWidth - Scale(6), top, width - pad - buttonWidth - Scale(6), top + Scale(25)});
    CreateChild(dialog, L"BUTTON", later.c_str(), WS_TABSTOP, IDCANCEL, {width - pad - buttonWidth, top, width - pad, top + Scale(25)});
    RunModal(dialog, restart, state.done);
    return state.accepted;
}

// ---- Options: what it shows and sets ----

// what the pages show: the main window's settings, the core's, and the language (0 System default, else its place in
// Languages() plus one)
struct OptionValues {
    WindowOptions window;
    int language = 0;
    int sendDelay = 0;
    int ahead = 0;
    int limit = 0;
    bool pictures = false;
    bool operator==(const OptionValues&) const = default;
};

struct OptionsState {
    PeCore* core = nullptr;
    HWND dialog = nullptr;
    HWND tabs = nullptr;
    bool done = false;
    // OK clicked, and the language it chose (empty: Windows' own), asked about once the window is closed
    bool accepted = false;
    std::wstring language;
    // Restart Now chosen for the language Apply set
    bool restart = false;
    std::vector<Language> languages;
    // what OK or Apply set last; before that, what was set when the window opened
    OptionValues applied;
    // the trusted senders removed in their window, untrusted by OK or Apply
    std::vector<int64_t> untrusted;
    std::function<void(const WindowOptions&)> applyWindow;
    // each page's controls, shown with its tab
    std::array<std::vector<HWND>, PE_SETTINGS_PAGE_COUNT> pages;
    // the height of a drop-down list in the dialog font, which its label is centered on
    int comboHeight = 0;
};

// the place of the language chosen in Options in the list (0: System default)
int LanguageIndex(const std::vector<Language>& languages) {
    std::wstring chosen = GetTextPreference(kLanguagePreference);
    for (size_t i = 0; i < languages.size(); i++) {
        if (languages[i].code == chosen) {
            return static_cast<int>(i) + 1;
        }
    }
    return 0;
}

OptionValues CurrentValues(PeCore* core, const WindowOptions& window, const std::vector<Language>& languages) {
    OptionValues values;
    values.window = window;
    values.language = LanguageIndex(languages);
    values.sendDelay = static_cast<int>(pe_send_delay_index(core));
    values.ahead = static_cast<int>(pe_download_ahead(core));
    values.limit = static_cast<int>(pe_download_limit_index(core));
    values.pictures = pe_always_load_pictures(core);
    return values;
}

bool Checked(HWND dialog, int id) {
    return Button_GetCheck(GetDlgItem(dialog, id)) == BST_CHECKED;
}

// the place chosen in a list, or `fallback` with none
int Selected(HWND dialog, int id, int fallback) {
    int index = static_cast<int>(SendDlgItemMessageW(dialog, id, CB_GETCURSEL, 0, 0));
    return index >= 0 ? index : fallback;
}

// what the pages show now
OptionValues ShownValues(const OptionsState& state) {
    HWND d = state.dialog;
    const OptionValues& was = state.applied;
    OptionValues values;
    values.window.notify = Checked(d, IDC_OPTIONS_NOTIFY);
    values.window.codes = Checked(d, IDC_OPTIONS_CODES);
    values.window.threads = Checked(d, IDC_OPTIONS_THREADS);
    values.window.layout = Selected(d, IDC_OPTIONS_LAYOUT, was.window.layout);
    values.window.listPictures = Checked(d, IDC_OPTIONS_LIST_PICTURES);
    values.language = Selected(d, IDC_OPTIONS_LANGUAGE, was.language);
    values.sendDelay = Selected(d, IDC_OPTIONS_SEND_DELAY, was.sendDelay);
    values.ahead = Selected(d, IDC_OPTIONS_DOWNLOAD_AHEAD, was.ahead);
    values.limit = Selected(d, IDC_OPTIONS_DOWNLOAD_LIMIT, was.limit);
    values.pictures = Checked(d, IDC_OPTIONS_PICTURES);
    return values;
}

// Apply enabled while the pages show something OK would change; the codes only with the notifications on
void UpdateOptions(const OptionsState& state) {
    EnableWindow(GetDlgItem(state.dialog, IDC_OPTIONS_CODES), Checked(state.dialog, IDC_OPTIONS_NOTIFY));
    bool changed = !(ShownValues(state) == state.applied) || !state.untrusted.empty();
    HWND apply = GetDlgItem(state.dialog, IDC_OPTIONS_APPLY);
    if (!changed && GetFocus() == apply) {
        // a disabled button can not keep the focus: OK takes it, as the default button
        SendMessageW(state.dialog, WM_NEXTDLGCTL, reinterpret_cast<WPARAM>(GetDlgItem(state.dialog, IDOK)), TRUE);
    }
    EnableWindow(apply, changed);
}

// what the pages show set (OK, Apply), but the language: the code it is to be, empty for Windows' own
std::wstring ApplyOptions(OptionsState& state) {
    OptionValues values = ShownValues(state);
    state.applyWindow(values.window);
    pe_set_always_load_pictures(state.core, values.pictures);
    pe_set_download_ahead(state.core, static_cast<PeDownloadAhead>(values.ahead));
    pe_set_download_limit_index(state.core, static_cast<size_t>(values.limit));
    pe_set_send_delay_index(state.core, static_cast<size_t>(values.sendDelay));
    for (int64_t id : state.untrusted) {
        pe_untrust_sender(state.core, id);
    }
    state.untrusted.clear();
    state.applied = values;
    UpdateOptions(state);
    int picked = values.language;
    return picked > 0 && static_cast<size_t>(picked) <= state.languages.size() ? state.languages[picked - 1].code : L"";
}

// ---- Options: the pages ----

// the tab `page` and its controls shown, the others' hidden; the focus on the tab strip if it was on a control hidden
void ShowPage(OptionsState& state, int page) {
    TabCtrl_SetCurSel(state.tabs, page);
    for (int p = 0; p < PE_SETTINGS_PAGE_COUNT; p++) {
        for (HWND control : state.pages[p]) {
            ShowWindow(control, p == page ? SW_SHOW : SW_HIDE);
        }
    }
    HWND focus = GetFocus();
    if (!focus || !IsWindowVisible(focus)) {
        SetFocus(state.tabs);
    }
}

// a group's title from its label: without the access key and the colon of a list's label ("&Language:")
std::wstring GroupTitle(PeText label) {
    std::wstring title = core::Plain(label);
    while (!title.empty() && (title.back() == L':' || title.back() == L'：' || title.back() == L' ' || iswspace(title.back()))) {
        title.pop_back();
    }
    return title;
}

// one page's controls laid out: its groups one under the other, each control under the one before it
struct PageBuilder {
    OptionsState& state;
    PeSettingsPage page;
    // the page's area, and where the next control goes
    int left = 0;
    int right = 0;
    int y = 0;
    // the edges of the group's controls
    int x0 = 0;
    int x1 = 0;
    // the column of the lists' labels, the lists to its right; 0 when the labels go above their lists
    int labelColumn = 0;
    // a list beside its label too narrow for its longest entry: the page is built again with the labels above
    bool cramped = false;
    // the right edge of the row of buttons going on, the next button to its right; -1 when none is
    int buttonRight = -1;
    int buttonTop = 0;
};

// the space between controls; the indent of the words beside a check box, and of a check box under the one it
// depends on; a group box's margins and the space between groups
constexpr int kGap = 6;
constexpr int kCheckIndent = 18;
constexpr int kGroupMargin = 10;
constexpr int kGroupTop = 20;
constexpr int kGroupGap = 8;
constexpr int kButtonHeight = 25;

HWND AddControl(PageBuilder& b, const wchar_t* className, const std::wstring& text, DWORD style, int id, const RECT& bounds) {
    HWND control = CreateChild(b.state.dialog, className, text.c_str(), style, id, bounds);
    b.state.pages[b.page].push_back(control);
    return control;
}

void EndButtons(PageBuilder& b) {
    b.buttonRight = -1;
}

// a note from `x` to the group's right edge, its words wrapped as an edit control wraps them: a word longer than the
// line is broken rather than cut off
void AddNote(PageBuilder& b, const std::wstring& note, int x, int id) {
    HDC dc = GetDC(nullptr);
    HGDIOBJ old = SelectObject(dc, GetStockObject(DEFAULT_GUI_FONT));
    RECT bounds = {0, 0, b.x1 - x, 0};
    DrawTextW(dc, note.c_str(), static_cast<int>(note.size()), &bounds, DT_CALCRECT | DT_NOPREFIX | DT_WORDBREAK | DT_EDITCONTROL);
    SelectObject(dc, old);
    ReleaseDC(nullptr, dc);
    AddControl(b, L"STATIC", note, SS_LEFT | SS_NOPREFIX | SS_EDITCONTROL, id, {x, b.y, b.x1, b.y + bounds.bottom});
    b.y += bounds.bottom;
}

// a control's note, if it has one, under it from `x`; then the space before the next control
void EndRow(PageBuilder& b, const PeSettingInfo& info, int x, int noteId) {
    if (info.hasNote) {
        b.y += Scale(2);
        AddNote(b, core::T(info.note), x, noteId);
    }
    b.y += Scale(kGap);
}

// a check box, its words wrapped to the group's width; one that depends on another under it, indented
void AddSwitch(PageBuilder& b, const PeSettingInfo& info, int id, int noteId, bool checked) {
    EndButtons(b);
    int x = b.x0 + (info.hasParent ? Scale(kCheckIndent) : 0);
    std::wstring text = core::T(info.label);
    int height = std::max(Scale(16), static_cast<int>(MeasureText(text, b.x1 - x - Scale(kCheckIndent + 2)).cy) + Scale(2));
    HWND box = AddControl(b, L"BUTTON", text, WS_TABSTOP | BS_AUTOCHECKBOX | BS_MULTILINE | BS_TOP, id, {x, b.y, b.x1, b.y + height});
    Button_SetCheck(box, checked ? BST_CHECKED : BST_UNCHECKED);
    b.y += height;
    EndRow(b, info, x + Scale(kCheckIndent - 1), noteId);
}

// a drop-down list with its label in the page's column before it (or above it), its note under the list
void AddChoice(PageBuilder& b, const PeSettingInfo& info, int id, int noteId, const std::vector<std::wstring>& items, int selected) {
    EndButtons(b);
    std::wstring label = core::T(info.label);
    int listLeft = b.x0 + b.labelColumn;
    // the label first: its access key moves the focus to the control after it
    if (b.labelColumn) {
        int textHeight = static_cast<int>(MeasureText(label).cy);
        int top = b.y + (b.state.comboHeight - textHeight) / 2;
        AddControl(b, L"STATIC", label, SS_LEFT, 0, {b.x0, top, listLeft - Scale(kGap), top + textHeight});
    } else {
        int height = static_cast<int>(MeasureText(label, b.x1 - b.x0).cy);
        AddControl(b, L"STATIC", label, SS_LEFT, 0, {b.x0, b.y, b.x1, b.y + height});
        b.y += height + Scale(3);
    }
    HWND list = AddControl(b, L"COMBOBOX", L"", WS_TABSTOP | WS_VSCROLL | CBS_DROPDOWNLIST, id, {listLeft, b.y, b.x1, b.y + Scale(200)});
    for (const std::wstring& item : items) {
        SendMessageW(list, CB_ADDSTRING, 0, reinterpret_cast<LPARAM>(item.c_str()));
    }
    SendMessageW(list, CB_SETCURSEL, static_cast<WPARAM>(selected), 0);
    for (const std::wstring& item : items) {
        b.cramped |= static_cast<int>(MeasureText(item).cx) + GetSystemMetrics(SM_CXVSCROLL) + Scale(8) > b.x1 - listLeft;
    }
    b.y += b.state.comboHeight;
    EndRow(b, info, listLeft, noteId);
}

// a push button as wide as its words, beside the button before it while they fit on the row, else under it
void AddButton(PageBuilder& b, const PeSettingInfo& info, int id) {
    std::wstring text = core::T(info.label);
    int width = ButtonWidth({text});
    if (b.buttonRight < 0 || b.buttonRight + Scale(kGap) + width > b.x1) {
        b.buttonRight = b.x0 - Scale(kGap);
        b.buttonTop = b.y;
        b.y += Scale(kButtonHeight) + Scale(kGap);
    }
    int x = b.buttonRight + Scale(kGap);
    AddControl(b, L"BUTTON", text, WS_TABSTOP, id, {x, b.buttonTop, x + width, b.buttonTop + Scale(kButtonHeight)});
    b.buttonRight = x + width;
}

// the words of a list the core makes: `count` of them, each from `text`
std::vector<std::wstring> CoreItems(size_t (*count)(), char* (*text)(size_t)) {
    std::vector<std::wstring> items;
    for (size_t i = 0; i < count(); i++) {
        core::String item(text(i));
        items.push_back(item ? Text(item.get()) : L"");
    }
    return items;
}

// System default, saying which language that is now, then the languages by their own names
std::vector<std::wstring> LanguageItems(const OptionsState& state) {
    std::wstring system = SystemLanguage();
    std::wstring name = system;
    std::vector<std::wstring> items = {L""};
    for (const Language& language : state.languages) {
        items.push_back(language.name);
        if (language.code == system) {
            name = language.name;
        }
    }
    items[0] = core::T(PE_TEXT_UI_OPTIONS_SYSTEM_DEFAULT, {{"language", name}});
    return items;
}

// each setting's control, its id (app.h, which the UI test finds it by) and what it shows
void AddSetting(PageBuilder& b, const PeSettingInfo& info) {
    const OptionValues& v = b.state.applied;
    switch (info.setting) {
    case PE_SETTING_LANGUAGE:
        AddChoice(b, info, IDC_OPTIONS_LANGUAGE, IDC_OPTIONS_NOTE, LanguageItems(b.state), v.language);
        return;
    case PE_SETTING_NOTIFY_NEW_MAIL:
        AddSwitch(b, info, IDC_OPTIONS_NOTIFY, 0, v.window.notify);
        return;
    case PE_SETTING_CODES_IN_NOTIFICATIONS:
        AddSwitch(b, info, IDC_OPTIONS_CODES, 0, v.window.codes);
        return;
    case PE_SETTING_SEND_DELAY:
        AddChoice(b, info, IDC_OPTIONS_SEND_DELAY, IDC_OPTIONS_SEND_DELAY_NOTE, CoreItems(pe_send_delay_count, pe_send_delay_text),
                  v.sendDelay);
        return;
    case PE_SETTING_DEFAULT_MAIL_APP:
        AddButton(b, info, IDC_OPTIONS_DEFAULT_APP);
        return;
    case PE_SETTING_EML_DEFAULT:
        AddButton(b, info, IDC_OPTIONS_EML);
        return;
    case PE_SETTING_LAYOUT:
        // View > Layout's three, in the order of PeLayoutMode
        AddChoice(b, info, IDC_OPTIONS_LAYOUT, 0,
                  {core::Plain(PE_TEXT_CMD_LAYOUT_AUTOMATIC), core::Plain(PE_TEXT_CMD_LAYOUT_CLASSIC), core::Plain(PE_TEXT_CMD_LAYOUT_COLUMNS)},
                  std::clamp(v.window.layout, 0, 2));
        return;
    case PE_SETTING_GROUP_BY_CONVERSATION:
        AddSwitch(b, info, IDC_OPTIONS_THREADS, 0, v.window.threads);
        return;
    case PE_SETTING_LIST_PICTURES:
        AddSwitch(b, info, IDC_OPTIONS_LIST_PICTURES, IDC_OPTIONS_LIST_PICTURES_NOTE, v.window.listPictures);
        return;
    case PE_SETTING_PICTURES_ALWAYS:
        AddSwitch(b, info, IDC_OPTIONS_PICTURES, IDC_OPTIONS_PICTURES_NOTE, v.pictures);
        return;
    case PE_SETTING_TRUSTED_SENDERS:
        AddButton(b, info, IDC_OPTIONS_TRUSTED);
        return;
    case PE_SETTING_DOWNLOAD_AHEAD:
        // in the order of PeDownloadAhead
        AddChoice(b, info, IDC_OPTIONS_DOWNLOAD_AHEAD, 0,
                  {core::T(PE_TEXT_UI_DOWNLOAD_AHEAD_RECENT), core::T(PE_TEXT_UI_DOWNLOAD_AHEAD_ALL), core::T(PE_TEXT_UI_DOWNLOAD_AHEAD_NEVER)},
                  v.ahead);
        return;
    case PE_SETTING_DOWNLOAD_LIMIT:
        AddChoice(b, info, IDC_OPTIONS_DOWNLOAD_LIMIT, 0, CoreItems(pe_download_limit_count, pe_download_limit_text), v.limit);
        return;
    case PE_SETTING_COUNT:
        return;
    }
}

// a group in a group box titled by it, its controls inside; the page's one untitled group without a box, as its tab
// titles it. The group's note at its end
void AddGroup(PageBuilder& b, const PeSettingsGroupInfo& group) {
    HWND box = nullptr;
    int top = b.y;
    int margin = group.titled ? Scale(kGroupMargin) : 0;
    b.x0 = b.left + margin;
    b.x1 = b.right - margin;
    if (group.titled) {
        box = AddControl(b, L"BUTTON", GroupTitle(group.label), BS_GROUPBOX, 0, {b.left, top, b.right, top + Scale(kGroupTop)});
        b.y = top + Scale(kGroupTop);
    }
    for (const PeSettingInfo& info : kSettings) {
        if (info.group == group.group) {
            AddSetting(b, info);
        }
    }
    EndButtons(b);
    if (group.hasNote) {
        AddNote(b, core::T(group.note), b.x0, group.group == PE_SETTINGS_GROUP_DOWNLOADING ? IDC_OPTIONS_DOWNLOAD_NOTE : 0);
        b.y += Scale(kGap);
    }
    // the space after the last control becomes the box's bottom margin
    b.y += margin - Scale(kGap);
    if (box) {
        MoveWindow(box, b.left, top, b.right - b.left, b.y - top, FALSE);
    }
    b.y += Scale(kGroupGap);
}

// the labels' column of a page's lists: as wide as the longest label, unless that leaves too little of `width` for the
// lists, when the labels go above them (0)
int LabelColumn(PeSettingsPage page, int width) {
    int widest = 0;
    for (const PeSettingInfo& info : kSettings) {
        if (info.page == page && info.kind == PE_SETTING_KIND_CHOICE) {
            widest = std::max(widest, static_cast<int>(MeasureText(core::T(info.label)).cx));
        }
    }
    int column = widest + Scale(kGap) + Scale(4);
    return width - column >= Scale(160) ? column : 0;
}

// page `page` built from `top` down between left and right, the lists beside their labels in `labelColumn` (0: under
// them); the bottom of its last group. Again with the labels above the lists when a list was too narrow beside its label
int BuildPage(OptionsState& state, PeSettingsPage page, int left, int right, int top, int labelColumn) {
    PageBuilder b{state, page};
    b.left = left;
    b.right = right;
    b.y = top;
    b.labelColumn = labelColumn;
    for (const PeSettingsGroupInfo& group : kSettingsGroups) {
        if (group.page == page) {
            AddGroup(b, group);
        }
    }
    if (b.cramped && labelColumn) {
        for (HWND control : state.pages[page]) {
            DestroyWindow(control);
        }
        state.pages[page].clear();
        return BuildPage(state, page, left, right, top, 0);
    }
    return b.y - Scale(kGroupGap);
}

// Ctrl+Tab and Ctrl+PageDown to the next page, Ctrl+Shift+Tab and Ctrl+PageUp to the one before, as in a property
// sheet; true when the key was one of them
bool PageKey(OptionsState& state, WPARAM key) {
    if (GetKeyState(VK_CONTROL) >= 0) {
        return false;
    }
    int step = 0;
    if (key == VK_TAB) {
        step = GetKeyState(VK_SHIFT) < 0 ? -1 : 1;
    } else if (key == VK_NEXT) {
        step = 1;
    } else if (key == VK_PRIOR) {
        step = -1;
    }
    if (step == 0) {
        return false;
    }
    ShowPage(state, (TabCtrl_GetCurSel(state.tabs) + step + PE_SETTINGS_PAGE_COUNT) % PE_SETTINGS_PAGE_COUNT);
    return true;
}

void OptionsCommand(OptionsState& state, WORD id, WORD code) {
    switch (id) {
    case IDOK:
        // the restart is asked once the window is closed
        state.language = ApplyOptions(state);
        state.accepted = true;
        state.done = true;
        return;
    case IDCANCEL:
        // what Apply set stays; the senders removed since are trusted still
        state.done = true;
        return;
    case IDC_OPTIONS_APPLY:
        if (ChooseLanguage(state.dialog, ApplyOptions(state))) {
            state.restart = true;
            state.done = true;
        }
        return;
    case IDC_OPTIONS_TRUSTED:
        TrustedSendersDialog(state.dialog, state.core, state.untrusted);
        UpdateOptions(state);
        return;
    case IDC_OPTIONS_EML:
        MakeDefaultEmlApp(state.dialog);
        return;
    case IDC_OPTIONS_DEFAULT_APP:
        MakeDefaultMailApp(state.dialog);
        return;
    }
    if (code == BN_CLICKED || code == CBN_SELCHANGE) {
        UpdateOptions(state);
    }
}

LRESULT CALLBACK OptionsProc(HWND hwnd, UINT message, WPARAM wParam, LPARAM lParam) {
    auto* state = reinterpret_cast<OptionsState*>(GetWindowLongPtrW(hwnd, GWLP_USERDATA));
    if (!state) {
        return DefWindowProcW(hwnd, message, wParam, lParam);
    }
    switch (message) {
    case WM_CLOSE:
        OptionsCommand(*state, IDCANCEL, 0);
        return 0;
    case WM_COMMAND:
        OptionsCommand(*state, LOWORD(wParam), HIWORD(wParam));
        return 0;
    case WM_NOTIFY: {
        auto* header = reinterpret_cast<NMHDR*>(lParam);
        if (header->hwndFrom == state->tabs && header->code == TCN_SELCHANGE) {
            ShowPage(*state, TabCtrl_GetCurSel(state->tabs));
        }
        return 0;
    }
    case WM_MODAL_KEY:
        return PageKey(*state, wParam);
    case WM_CTLCOLORSTATIC:
        return ButtonFaceColor(reinterpret_cast<HDC>(wParam));
    }
    return DefWindowProcW(hwnd, message, wParam, lParam);
}

// the height of a drop-down list in the dialog font, from one made and thrown away
int ComboHeight(HWND dialog) {
    HWND probe = CreateChild(dialog, L"COMBOBOX", L"", CBS_DROPDOWNLIST, 0, {0, 0, Scale(100), Scale(200)});
    RECT bounds;
    GetWindowRect(probe, &bounds);
    DestroyWindow(probe);
    return bounds.bottom - bounds.top;
}

// the window's client area made `width` by `height`, its center where it was
void ResizeClient(HWND window, int width, int height) {
    RECT frame = {0, 0, width, height};
    AdjustWindowRectEx(&frame, static_cast<DWORD>(GetWindowLongPtrW(window, GWL_STYLE)), FALSE,
                       static_cast<DWORD>(GetWindowLongPtrW(window, GWL_EXSTYLE)));
    RECT now;
    GetWindowRect(window, &now);
    int outerWidth = frame.right - frame.left, outerHeight = frame.bottom - frame.top;
    int x = (now.left + now.right - outerWidth) / 2, y = (now.top + now.bottom - outerHeight) / 2;
    SetWindowPos(window, nullptr, x, y, outerWidth, outerHeight, SWP_NOZORDER | SWP_NOACTIVATE);
}

// the width of the Options window's client area, whatever the language: long words wrap
constexpr int kOptionsWidth = 432;

// the tab strip with a tab for each page, every page's controls on it, and OK, Cancel and Apply at the bottom right;
// the window as tall as the tallest page
void BuildOptions(OptionsState& state) {
    HWND dialog = state.dialog;
    int pad = Scale(8), width = Scale(kOptionsWidth);
    state.comboHeight = ComboHeight(dialog);
    RECT tabBounds = {pad, pad, width - pad, pad + Scale(400)};
    // under the pages' controls, which are its siblings; first in the Tab order, as a property sheet's tabs are
    state.tabs = CreateChild(dialog, WC_TABCONTROLW, nullptr, WS_CLIPSIBLINGS | WS_TABSTOP, IDC_OPTIONS_TABS, tabBounds);
    for (const PeSettingsPageInfo& page : kSettingsPages) {
        std::wstring label = core::Plain(page.label);
        TCITEMW item = {};
        item.mask = TCIF_TEXT;
        item.pszText = label.data();
        TabCtrl_InsertItem(state.tabs, static_cast<int>(page.page), &item);
    }
    RECT display = tabBounds;
    TabCtrl_AdjustRect(state.tabs, FALSE, &display);
    int inset = Scale(8), bottom = 0;
    for (const PeSettingsPageInfo& page : kSettingsPages) {
        int left = display.left + inset, right = display.right - inset;
        int column = LabelColumn(page.page, right - left - 2 * Scale(kGroupMargin));
        bottom = std::max(bottom, BuildPage(state, page.page, left, right, display.top + inset, column));
    }
    // the tab strip's frame under the tallest page
    tabBounds.bottom = bottom + inset + (tabBounds.bottom - display.bottom);
    MoveWindow(state.tabs, tabBounds.left, tabBounds.top, tabBounds.right - tabBounds.left, tabBounds.bottom - tabBounds.top, FALSE);
    std::wstring ok = core::T(PE_TEXT_UI_OK), cancel = core::T(PE_TEXT_UI_CANCEL), apply = core::T(PE_TEXT_UI_APPLY);
    int buttonWidth = ButtonWidth({ok, cancel, apply}), top = tabBounds.bottom + Scale(8);
    int x = width - pad - 3 * buttonWidth - 2 * Scale(kGap);
    const std::pair<int, const std::wstring*> buttons[] = {{IDOK, &ok}, {IDCANCEL, &cancel}, {IDC_OPTIONS_APPLY, &apply}};
    for (const auto& [id, text] : buttons) {
        HWND button = CreateChild(dialog, L"BUTTON", text->c_str(), WS_TABSTOP | (id == IDOK ? BS_DEFPUSHBUTTON : 0), id,
                                  {x, top, x + buttonWidth, top + Scale(kButtonHeight)});
        // nothing to apply yet
        EnableWindow(button, id != IDC_OPTIONS_APPLY);
        x += buttonWidth + Scale(kGap);
    }
    ResizeClient(dialog, width, top + Scale(kButtonHeight) + pad);
    EnableWindow(GetDlgItem(dialog, IDC_OPTIONS_CODES), state.applied.window.notify);
    ShowPage(state, PE_SETTINGS_PAGE_GENERAL);
}

}  // namespace

void StartLanguage(const std::wstring& forced) {
    std::wstring code = !forced.empty() ? forced : GetTextPreference(kLanguagePreference);
    if (code.empty()) {
        code = SystemLanguage();
    }
    core::SetLanguage(code);
}

bool OptionsDialog(HWND owner, PeCore* core, const WindowOptions& window, const std::function<void(const WindowOptions&)>& apply) {
    HelpScope help("options");
    RegisterDialogClass(kOptionsClass, OptionsProc);
    OptionsState state;
    state.core = core;
    state.languages = Languages();
    state.applied = CurrentValues(core, window, state.languages);
    state.applyWindow = apply;
    state.dialog = CreateModalWindow(owner, kOptionsClass, core::Title(PE_TEXT_CMD_OPTIONS).c_str(), Scale(kOptionsWidth), Scale(400));
    BuildOptions(state);
    SetWindowLongPtrW(state.dialog, GWLP_USERDATA, reinterpret_cast<LONG_PTR>(&state));
    RunModal(state.dialog, state.tabs, state.done);
    if (state.restart) {
        return true;
    }
    return state.accepted && ChooseLanguage(owner, state.language);
}

bool ChooseLanguage(HWND owner, const std::wstring& code) {
    if (code == GetTextPreference(kLanguagePreference)) {
        return false;
    }
    SetTextPreference(kLanguagePreference, code);
    // the language the windows will have, and whether that is the one they have now
    std::wstring next = code.empty() ? SystemLanguage() : code;
    core::String current(pe_language());
    if (current && next == Text(current.get())) {
        return false;
    }
    std::vector<Language> languages = Languages();
    auto found = std::find_if(languages.begin(), languages.end(), [&](const Language& l) { return l.code == next; });
    return AskRestart(owner, found != languages.end() ? found->name : next);
}

void MakeDefaultMailApp(HWND owner) {
    if (OpensWithUs(L"mailto", AT_URLPROTOCOL, kMailtoClass)) {
        Tell(owner, core::T(PE_TEXT_UI_DEFAULT_APP_IS));
    } else if (!Registered()) {
        Tell(owner, core::T(PE_TEXT_WIN_DEFAULT_APP_NOT_INSTALLED));
    } else {
        Tell(owner, core::T(PE_TEXT_WIN_DEFAULT_APP_SETTINGS));
        OpenDefaultAppsSettings(owner);
    }
}
