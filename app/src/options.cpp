// Tools > Options: the language of the windows, the new mail notifications and the list grouped by conversation; and the language the app starts in.
// The words come from the core's catalogs; the language is read once, at start, so another one takes a restart.
#include "app.h"

#include <shellapi.h>
#include <shobjidl.h>
#include <windowsx.h>
#include <wrl/client.h>

#include <algorithm>

namespace {

const wchar_t* kOptionsClass = L"InboxClassicOptions";
const wchar_t* kRestartClass = L"InboxClassicRestart";
const wchar_t* kTrustedClass = L"InboxClassicTrustedSenders";
// what the installer registers .eml files to and the app as (installer/inbox-classic.nsi: EMLCLASS, PRODUCT)
const wchar_t* kEmlClass = L"InboxClassic.eml";
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

struct OptionsState {
    PeCore* core = nullptr;
    bool done = false;
    bool accepted = false;
    // Options: its controls, and what they had when OK was clicked
    HWND combo = nullptr;
    HWND check = nullptr;
    HWND threadsCheck = nullptr;
    HWND codesCheck = nullptr;
    HWND picturesCheck = nullptr;
    HWND listPicturesCheck = nullptr;
    HWND aheadCombo = nullptr;
    HWND limitCombo = nullptr;
    HWND layoutCombo = nullptr;
    HWND sendDelayCombo = nullptr;
    int picked = 0;
    int sendDelay = 0;
    int layout = 0;
    int ahead = 0;
    int limit = 0;
    bool notify = false;
    bool threads = false;
    bool codes = false;
    bool listPictures = true;
    bool pictures = false;
};

// ---- Trusted Senders ----

struct TrustedState {
    PeCore* core = nullptr;
    bool done = false;
    HWND list = nullptr;
    HWND remove = nullptr;
    HWND empty = nullptr;
    // the senders' ids, a row each
    std::vector<int64_t> ids;
};

// the list from the core again; with none, the words that say so in its place
void FillTrusted(TrustedState& state) {
    ListView_DeleteAllItems(state.list);
    state.ids.clear();
    PeTrustedSenderList* senders = pe_trusted_senders(state.core);
    for (size_t i = 0; i < pe_trusted_sender_list_count(senders); i++) {
        const PeTrustedSender* sender = pe_trusted_sender_list_get(senders, i);
        std::wstring label = Text(sender->label);
        LVITEMW item = {LVIF_TEXT};
        item.iItem = static_cast<int>(i);
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
            pe_untrust_sender(state.core, state.ids[row]);
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

// the senders whose pictures load by themselves, each with Remove
void TrustedSendersDialog(HWND owner, PeCore* core) {
    RegisterDialogClass(kTrustedClass, TrustedProc);
    std::wstring note = core::T(PE_TEXT_UI_TRUSTED_SENDERS_NOTE), remove = core::T(PE_TEXT_UI_REMOVE);
    std::wstring close = core::T(PE_TEXT_UI_CLOSE);
    int pad = Scale(12), width = Scale(400), inner = width - 2 * pad;
    int noteHeight = static_cast<int>(MeasureText(note, inner).cy), listHeight = Scale(180);
    int height = pad + noteHeight + Scale(8) + listHeight + Scale(12) + Scale(25) + pad;
    HWND dialog = CreateModalWindow(owner, kTrustedClass, core::Title(PE_TEXT_UI_TRUSTED_SENDERS_TITLE).c_str(), width, height);
    TrustedState state;
    state.core = core;
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

// Open .eml Files with Inbox Classic: Windows lets only the user choose it, in Settings, where the installer listed
// the app; said so when it is chosen already, or when this copy was not installed
void MakeDefaultEmlApp(HWND owner) {
    Microsoft::WRL::ComPtr<IApplicationAssociationRegistration> associations;
    LPWSTR current = nullptr;
    if (SUCCEEDED(CoCreateInstance(CLSID_ApplicationAssociationRegistration, nullptr, CLSCTX_INPROC_SERVER, IID_PPV_ARGS(&associations))) &&
        SUCCEEDED(associations->QueryCurrentDefault(L".eml", AT_FILEEXTENSION, AL_EFFECTIVE, &current))) {
        bool ours = _wcsicmp(current, kEmlClass) == 0;
        CoTaskMemFree(current);
        if (ours) {
            MessageBoxW(owner, core::T(PE_TEXT_UI_EML_DEFAULT_DONE).c_str(), L"Inbox Classic", MB_OK | MB_ICONINFORMATION);
            return;
        }
    }
    DWORD size = 0;
    if (RegGetValueW(HKEY_CURRENT_USER, L"Software\\RegisteredApplications", kRegisteredName, RRF_RT_REG_SZ, nullptr, nullptr, &size) !=
        ERROR_SUCCESS) {
        std::wstring text = core::T(PE_TEXT_UI_EML_DEFAULT_FAILED, {{"reason", core::T(PE_TEXT_WIN_DEFAULT_APP_NOT_INSTALLED)}});
        MessageBoxW(owner, text.c_str(), L"Inbox Classic", MB_OK | MB_ICONINFORMATION);
        return;
    }
    ShellExecuteW(owner, L"open", L"ms-settings:defaultapps?registeredAppUser=Inbox%20Classic", nullptr, nullptr, SW_SHOWNORMAL);
}

LRESULT CALLBACK OptionsProc(HWND hwnd, UINT message, WPARAM wParam, LPARAM lParam) {
    auto* state = reinterpret_cast<OptionsState*>(GetWindowLongPtrW(hwnd, GWLP_USERDATA));
    if (state && ((message == WM_COMMAND && (LOWORD(wParam) == IDOK || LOWORD(wParam) == IDCANCEL)) || message == WM_CLOSE)) {
        state->accepted = message == WM_COMMAND && LOWORD(wParam) == IDOK;
        if (state->accepted && state->combo) {
            state->picked = static_cast<int>(SendMessageW(state->combo, CB_GETCURSEL, 0, 0));
            state->notify = Button_GetCheck(state->check) == BST_CHECKED;
            state->threads = Button_GetCheck(state->threadsCheck) == BST_CHECKED;
            state->codes = Button_GetCheck(state->codesCheck) == BST_CHECKED;
            state->pictures = Button_GetCheck(state->picturesCheck) == BST_CHECKED;
            state->ahead = static_cast<int>(SendMessageW(state->aheadCombo, CB_GETCURSEL, 0, 0));
            state->limit = static_cast<int>(SendMessageW(state->limitCombo, CB_GETCURSEL, 0, 0));
            state->layout = static_cast<int>(SendMessageW(state->layoutCombo, CB_GETCURSEL, 0, 0));
            state->sendDelay = static_cast<int>(SendMessageW(state->sendDelayCombo, CB_GETCURSEL, 0, 0));
            state->listPictures = Button_GetCheck(state->listPicturesCheck) == BST_CHECKED;
        }
        state->done = true;
        return 0;
    }
    if (state && message == WM_COMMAND && LOWORD(wParam) == IDC_OPTIONS_TRUSTED) {
        TrustedSendersDialog(hwnd, state->core);
        return 0;
    }
    if (state && message == WM_COMMAND && LOWORD(wParam) == IDC_OPTIONS_EML) {
        MakeDefaultEmlApp(hwnd);
        return 0;
    }
    if (message == WM_CTLCOLORSTATIC) {
        return ButtonFaceColor(reinterpret_cast<HDC>(wParam));
    }
    return DefWindowProcW(hwnd, message, wParam, lParam);
}

// asks whether to restart now for the language `name`: true for Restart Now, false for Later
bool AskRestart(HWND owner, const std::wstring& name) {
    RegisterDialogClass(kRestartClass, OptionsProc);
    std::wstring text = core::T(PE_TEXT_WIN_RESTART_ASK, {{"language", name}});
    std::wstring now = core::T(PE_TEXT_UI_RESTART_NOW), later = core::T(PE_TEXT_UI_RESTART_LATER);
    int pad = Scale(12), width = Scale(360);
    int textHeight = std::max(Scale(32), static_cast<int>(MeasureText(text, width - 2 * pad).cy));
    int buttonWidth = ButtonWidth({now, later});
    int height = pad + textHeight + Scale(14) + Scale(25) + pad;
    HWND dialog = CreateModalWindow(owner, kRestartClass, core::Title(PE_TEXT_CMD_OPTIONS).c_str(), width, height);
    OptionsState state;
    SetWindowLongPtrW(dialog, GWLP_USERDATA, reinterpret_cast<LONG_PTR>(&state));
    CreateChild(dialog, L"STATIC", text.c_str(), SS_LEFT | SS_NOPREFIX, 0, {pad, pad, width - pad, pad + textHeight});
    int top = height - pad - Scale(25);
    HWND restart = CreateChild(dialog, L"BUTTON", now.c_str(), WS_TABSTOP | BS_DEFPUSHBUTTON, IDOK,
                               {width - pad - 2 * buttonWidth - Scale(6), top, width - pad - buttonWidth - Scale(6), top + Scale(25)});
    CreateChild(dialog, L"BUTTON", later.c_str(), WS_TABSTOP, IDCANCEL, {width - pad - buttonWidth, top, width - pad, top + Scale(25)});
    RunModal(dialog, restart, state.done);
    return state.accepted;
}

}  // namespace

void StartLanguage(const std::wstring& forced) {
    std::wstring code = !forced.empty() ? forced : GetTextPreference(kLanguagePreference);
    if (code.empty()) {
        code = SystemLanguage();
    }
    core::SetLanguage(code);
}

bool OptionsDialog(HWND owner, PeCore* core, bool& notify, bool& threads, bool& codes, int& layout, bool& listPictures) {
    HelpScope help("options");
    RegisterDialogClass(kOptionsClass, OptionsProc);
    std::vector<Language> languages = Languages();
    std::wstring chosen = GetTextPreference(kLanguagePreference);
    std::wstring system = SystemLanguage();
    auto nameOf = [&](const std::wstring& code) {
        auto found = std::find_if(languages.begin(), languages.end(), [&](const Language& l) { return l.code == code; });
        return found != languages.end() ? found->name : code;
    };

    std::wstring label = core::T(PE_TEXT_WIN_OPTIONS_LANGUAGE_LABEL), note = core::T(PE_TEXT_WIN_OPTIONS_RESTART_NOTE);
    std::wstring notifyText = core::T(PE_TEXT_WIN_OPTIONS_NOTIFY);
    std::wstring threadsText = core::T(PE_TEXT_UI_GROUP_BY_CONVERSATION);
    // View > Layout's three, in the order of PeLayoutMode
    std::wstring layoutText = core::T(PE_TEXT_UI_LAYOUT_LABEL);
    std::vector<std::wstring> layoutItems = {core::Plain(PE_TEXT_CMD_LAYOUT_AUTOMATIC), core::Plain(PE_TEXT_CMD_LAYOUT_CLASSIC),
                                             core::Plain(PE_TEXT_CMD_LAYOUT_COLUMNS)};
    std::wstring codesText = core::T(PE_TEXT_UI_CODES_IN_NOTIFICATIONS);
    std::wstring listPicturesText = core::T(PE_TEXT_UI_LIST_PICTURES), listPicturesNote = core::T(PE_TEXT_UI_LIST_PICTURES_NOTE);
    std::wstring picturesText = core::T(PE_TEXT_UI_PICTURES_ALWAYS_OPTION), warning = core::T(PE_TEXT_UI_PICTURES_ALWAYS_WARNING);
    std::wstring trustedText = core::T(PE_TEXT_UI_TRUSTED_SENDERS_BUTTON), emlText = core::T(PE_TEXT_UI_EML_DEFAULT);
    std::wstring ok = core::T(PE_TEXT_UI_OK), cancel = core::T(PE_TEXT_UI_CANCEL);
    // Downloading: two lists with their labels, and what they mean under them
    std::wstring aheadText = core::T(PE_TEXT_UI_DOWNLOAD_AHEAD), limitText = core::T(PE_TEXT_UI_DOWNLOAD_LIMIT);
    std::wstring downloadNote = core::T(PE_TEXT_UI_DOWNLOAD_NOTE);
    // in the order of PeDownloadAhead
    std::vector<std::wstring> aheadItems = {core::T(PE_TEXT_UI_DOWNLOAD_AHEAD_RECENT), core::T(PE_TEXT_UI_DOWNLOAD_AHEAD_ALL),
                                            core::T(PE_TEXT_UI_DOWNLOAD_AHEAD_NEVER)};
    std::wstring sendDelayText = core::T(PE_TEXT_UI_SEND_DELAY), sendDelayNote = core::T(PE_TEXT_UI_SEND_DELAY_NOTE);
    std::vector<std::wstring> sendDelayItems;
    for (size_t i = 0; i < pe_send_delay_count(); i++) {
        core::String text(pe_send_delay_text(i));
        sendDelayItems.push_back(text ? Text(text.get()) : L"");
    }
    std::vector<std::wstring> limitItems;
    for (size_t i = 0; i < pe_download_limit_count(); i++) {
        core::String text(pe_download_limit_text(i));
        limitItems.push_back(text ? Text(text.get()) : L"");
    }
    int pad = Scale(12), row = Scale(22);
    int labelWidth = static_cast<int>(MeasureText(label).cx) + Scale(8);
    // the first item follows Windows, and says which language that is now
    std::wstring systemItem = core::T(PE_TEXT_UI_OPTIONS_SYSTEM_DEFAULT, {{"language", nameOf(system)}});
    // the list as wide as its longest entry, with room for its arrow
    int longest = static_cast<int>(MeasureText(systemItem).cx);
    for (const Language& language : languages) {
        longest = std::max(longest, static_cast<int>(MeasureText(language.name).cx));
    }
    int comboWidth = std::max(Scale(200), longest + GetSystemMetrics(SM_CXVSCROLL) + Scale(12));
    // the layout and download lists: their labels in a column, the lists as wide as their longest entry
    int comboLabel = static_cast<int>(std::max({MeasureText(aheadText).cx, MeasureText(limitText).cx, MeasureText(layoutText).cx,
                                                MeasureText(sendDelayText).cx})) +
                        Scale(8);
    int downloadListWidth = 0;
    for (const auto* items : {&aheadItems, &limitItems}) {
        for (const std::wstring& item : *items) {
            downloadListWidth = std::max(downloadListWidth, static_cast<int>(MeasureText(item).cx));
        }
    }
    downloadListWidth += GetSystemMetrics(SM_CXVSCROLL) + Scale(12);
    // wide enough for the language list and the check boxes' words
    int inner = std::max({Scale(360), labelWidth + comboWidth, static_cast<int>(MeasureText(notifyText).cx) + Scale(24),
                          static_cast<int>(MeasureText(threadsText).cx) + Scale(24),
                          static_cast<int>(MeasureText(codesText).cx) + Scale(48),
                          static_cast<int>(MeasureText(picturesText).cx) + Scale(24),
                          static_cast<int>(MeasureText(listPicturesText).cx) + Scale(24),
                          ButtonWidth({trustedText}) + Scale(6) + ButtonWidth({emlText}), comboLabel + downloadListWidth});
    int width = 2 * pad + inner;
    int noteHeight = std::max(Scale(16), static_cast<int>(MeasureText(note, inner - labelWidth).cy));
    int warningHeight = std::max(Scale(16), static_cast<int>(MeasureText(warning, inner - Scale(17)).cy));
    int listNoteHeight = std::max(Scale(16), static_cast<int>(MeasureText(listPicturesNote, inner - Scale(17)).cy));
    int downloadNoteHeight = std::max(Scale(16), static_cast<int>(MeasureText(downloadNote, inner).cy));
    int sendNoteHeight = std::max(Scale(16), static_cast<int>(MeasureText(sendDelayNote, inner - comboLabel).cy));
    // the language and its note, a line, the notifications (with their codes under them) and the conversations, a
    // line, reading: pictures with their warning, Trusted Senders and .eml files; the buttons
    int reading = Scale(12) + 2 + Scale(12) + row + warningHeight + Scale(8) + Scale(25);
    // a line, then downloading: the two lists and the note
    int downloading = Scale(12) + 2 + Scale(12) + 2 * row + 2 * Scale(4) + downloadNoteHeight;
    // the wait before sending, with its note, under the layout
    int sending = row + sendNoteHeight + Scale(8);
    int height = pad + row + Scale(4) + noteHeight + Scale(12) + 2 + Scale(12) + 5 * row + 3 * Scale(4) + Scale(8) + listNoteHeight + sending +
                 reading + downloading +
                 Scale(16) + Scale(25) + pad;
    HWND dialog = CreateModalWindow(owner, kOptionsClass, core::Title(PE_TEXT_CMD_OPTIONS).c_str(), width, height);
    OptionsState state;

    int left = pad, right = width - pad, y = pad;
    CreateChild(dialog, L"STATIC", label.c_str(), SS_LEFT, 0, {left, y + Scale(3), left + labelWidth, y + row});
    HWND combo = CreateChild(dialog, L"COMBOBOX", L"", WS_TABSTOP | WS_VSCROLL | CBS_DROPDOWNLIST, IDC_OPTIONS_LANGUAGE,
                             {left + labelWidth, y, right, y + Scale(200)});
    SendMessageW(combo, CB_ADDSTRING, 0, reinterpret_cast<LPARAM>(systemItem.c_str()));
    int selected = 0;
    for (size_t i = 0; i < languages.size(); i++) {
        SendMessageW(combo, CB_ADDSTRING, 0, reinterpret_cast<LPARAM>(languages[i].name.c_str()));
        if (languages[i].code == chosen) {
            selected = static_cast<int>(i) + 1;
        }
    }
    SendMessageW(combo, CB_SETCURSEL, selected, 0);
    y += row + Scale(4);
    // under the list, as a note to it
    CreateChild(dialog, L"STATIC", note.c_str(), SS_LEFT | SS_NOPREFIX, IDC_OPTIONS_NOTE, {left + labelWidth, y, right, y + noteHeight});
    y += noteHeight + Scale(12);
    CreateChild(dialog, L"STATIC", L"", SS_ETCHEDHORZ, 0, {left, y, right, y + 2});
    y += 2 + Scale(12);
    HWND check = CreateChild(dialog, L"BUTTON", notifyText.c_str(), WS_TABSTOP | BS_AUTOCHECKBOX, IDC_OPTIONS_NOTIFY,
                             {left, y, right, y + row});
    Button_SetCheck(check, notify ? BST_CHECKED : BST_UNCHECKED);
    y += row + Scale(4);
    // under the notifications, as a choice of theirs
    HWND codesCheck = CreateChild(dialog, L"BUTTON", codesText.c_str(), WS_TABSTOP | BS_AUTOCHECKBOX, IDC_OPTIONS_CODES,
                                  {left + Scale(24), y, right, y + row});
    Button_SetCheck(codesCheck, codes ? BST_CHECKED : BST_UNCHECKED);
    y += row + Scale(4);
    HWND threadsCheck = CreateChild(dialog, L"BUTTON", threadsText.c_str(), WS_TABSTOP | BS_AUTOCHECKBOX, IDC_OPTIONS_THREADS,
                                    {left, y, right, y + row});
    Button_SetCheck(threadsCheck, threads ? BST_CHECKED : BST_UNCHECKED);
    y += row + Scale(4);
    // the layout of the main window, as View > Layout has it
    CreateChild(dialog, L"STATIC", layoutText.c_str(), SS_LEFT, 0, {left, y + Scale(3), left + comboLabel, y + row});
    HWND layoutCombo = CreateChild(dialog, L"COMBOBOX", L"", WS_TABSTOP | WS_VSCROLL | CBS_DROPDOWNLIST, IDC_OPTIONS_LAYOUT,
                                   {left + comboLabel, y, right, y + Scale(200)});
    for (const std::wstring& item : layoutItems) {
        SendMessageW(layoutCombo, CB_ADDSTRING, 0, reinterpret_cast<LPARAM>(item.c_str()));
    }
    SendMessageW(layoutCombo, CB_SETCURSEL, std::clamp(layout, 0, 2), 0);
    y += row + Scale(4);
    // how long a message sent waits to be taken back (Undo Send), and what that is for under it
    CreateChild(dialog, L"STATIC", sendDelayText.c_str(), SS_LEFT, 0, {left, y + Scale(3), left + comboLabel, y + row});
    HWND sendDelayCombo = CreateChild(dialog, L"COMBOBOX", L"", WS_TABSTOP | WS_VSCROLL | CBS_DROPDOWNLIST, IDC_OPTIONS_SEND_DELAY,
                                      {left + comboLabel, y, right, y + Scale(200)});
    for (const std::wstring& item : sendDelayItems) {
        SendMessageW(sendDelayCombo, CB_ADDSTRING, 0, reinterpret_cast<LPARAM>(item.c_str()));
    }
    SendMessageW(sendDelayCombo, CB_SETCURSEL, static_cast<WPARAM>(pe_send_delay_index(core)), 0);
    y += row;
    CreateChild(dialog, L"STATIC", sendDelayNote.c_str(), SS_LEFT | SS_NOPREFIX, IDC_OPTIONS_SEND_DELAY_NOTE,
                {left + comboLabel, y, right, y + sendNoteHeight});
    y += sendNoteHeight + Scale(8);
    // the senders' pictures of the Columns list, and what they are under the check box's words
    HWND listPicturesCheck = CreateChild(dialog, L"BUTTON", listPicturesText.c_str(), WS_TABSTOP | BS_AUTOCHECKBOX,
                                         IDC_OPTIONS_LIST_PICTURES, {left, y, right, y + row});
    Button_SetCheck(listPicturesCheck, listPictures ? BST_CHECKED : BST_UNCHECKED);
    y += row;
    CreateChild(dialog, L"STATIC", listPicturesNote.c_str(), SS_LEFT | SS_NOPREFIX, IDC_OPTIONS_LIST_PICTURES_NOTE,
                {left + Scale(17), y, right, y + listNoteHeight});
    y += listNoteHeight + Scale(12);
    CreateChild(dialog, L"STATIC", L"", SS_ETCHEDHORZ, 0, {left, y, right, y + 2});
    y += 2 + Scale(12);
    HWND picturesCheck = CreateChild(dialog, L"BUTTON", picturesText.c_str(), WS_TABSTOP | BS_AUTOCHECKBOX, IDC_OPTIONS_PICTURES,
                                     {left, y, right, y + row});
    Button_SetCheck(picturesCheck, pe_always_load_pictures(core) ? BST_CHECKED : BST_UNCHECKED);
    y += row;
    // under the check box's words, as a note to it
    CreateChild(dialog, L"STATIC", warning.c_str(), SS_LEFT | SS_NOPREFIX, IDC_OPTIONS_PICTURES_NOTE,
                {left + Scale(17), y, right, y + warningHeight});
    y += warningHeight + Scale(8);
    int trustedWidth = ButtonWidth({trustedText}), emlWidth = ButtonWidth({emlText});
    CreateChild(dialog, L"BUTTON", trustedText.c_str(), WS_TABSTOP, IDC_OPTIONS_TRUSTED, {left, y, left + trustedWidth, y + Scale(25)});
    CreateChild(dialog, L"BUTTON", emlText.c_str(), WS_TABSTOP, IDC_OPTIONS_EML,
                {left + trustedWidth + Scale(6), y, left + trustedWidth + Scale(6) + emlWidth, y + Scale(25)});
    y += Scale(25) + Scale(12);
    CreateChild(dialog, L"STATIC", L"", SS_ETCHEDHORZ, 0, {left, y, right, y + 2});
    y += 2 + Scale(12);
    auto addDownloadList = [&](const std::wstring& text, int id, const std::vector<std::wstring>& items, int selected) {
        CreateChild(dialog, L"STATIC", text.c_str(), SS_LEFT, 0, {left, y + Scale(3), left + comboLabel, y + row});
        HWND list = CreateChild(dialog, L"COMBOBOX", L"", WS_TABSTOP | WS_VSCROLL | CBS_DROPDOWNLIST, id,
                                {left + comboLabel, y, right, y + Scale(200)});
        for (const std::wstring& item : items) {
            SendMessageW(list, CB_ADDSTRING, 0, reinterpret_cast<LPARAM>(item.c_str()));
        }
        SendMessageW(list, CB_SETCURSEL, selected, 0);
        y += row + Scale(4);
        return list;
    };
    HWND aheadCombo = addDownloadList(aheadText, IDC_OPTIONS_DOWNLOAD_AHEAD, aheadItems, static_cast<int>(pe_download_ahead(core)));
    HWND limitCombo = addDownloadList(limitText, IDC_OPTIONS_DOWNLOAD_LIMIT, limitItems, static_cast<int>(pe_download_limit_index(core)));
    CreateChild(dialog, L"STATIC", downloadNote.c_str(), SS_LEFT | SS_NOPREFIX, IDC_OPTIONS_DOWNLOAD_NOTE,
                {left, y, right, y + downloadNoteHeight});
    int buttonWidth = ButtonWidth({ok, cancel}), buttonTop = height - pad - Scale(25);
    CreateChild(dialog, L"BUTTON", ok.c_str(), WS_TABSTOP | BS_DEFPUSHBUTTON, IDOK,
                {width - pad - 2 * buttonWidth - Scale(6), buttonTop, width - pad - buttonWidth - Scale(6), buttonTop + Scale(25)});
    CreateChild(dialog, L"BUTTON", cancel.c_str(), WS_TABSTOP, IDCANCEL, {width - pad - buttonWidth, buttonTop, width - pad, buttonTop + Scale(25)});

    state.combo = combo;
    state.check = check;
    state.threadsCheck = threadsCheck;
    state.codesCheck = codesCheck;
    state.picturesCheck = picturesCheck;
    state.aheadCombo = aheadCombo;
    state.limitCombo = limitCombo;
    state.layoutCombo = layoutCombo;
    state.sendDelayCombo = sendDelayCombo;
    state.listPicturesCheck = listPicturesCheck;
    state.core = core;
    SetWindowLongPtrW(dialog, GWLP_USERDATA, reinterpret_cast<LONG_PTR>(&state));
    RunModal(dialog, combo, state.done);
    if (!state.accepted) {
        return false;
    }
    notify = state.notify;
    threads = state.threads;
    codes = state.codes;
    if (state.layout >= 0) {
        layout = state.layout;
    }
    listPictures = state.listPictures;
    pe_set_always_load_pictures(core, state.pictures);
    if (state.ahead >= 0) {
        pe_set_download_ahead(core, static_cast<PeDownloadAhead>(state.ahead));
    }
    if (state.limit >= 0) {
        pe_set_download_limit_index(core, static_cast<size_t>(state.limit));
    }
    if (state.sendDelay >= 0) {
        pe_set_send_delay_index(core, static_cast<size_t>(state.sendDelay));
    }
    int picked = state.picked;
    std::wstring code = picked > 0 && static_cast<size_t>(picked) <= languages.size() ? languages[picked - 1].code : L"";
    if (code == chosen) {
        return false;
    }
    SetTextPreference(kLanguagePreference, code);
    // the language the windows will have, and whether that is the one they have now
    std::wstring next = code.empty() ? system : code;
    core::String current(pe_language());
    if (current && next == Text(current.get())) {
        return false;
    }
    return AskRestart(owner, nameOf(next));
}
