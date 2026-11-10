// Tools > Options: the language of the windows, the new mail notifications and the list grouped by conversation; and the language the app starts in.
// The words come from the core's catalogs; the language is read once, at start, so another one takes a restart.
#include "app.h"

#include <windowsx.h>

#include <algorithm>

namespace {

const wchar_t* kOptionsClass = L"InboxClassicOptions";
const wchar_t* kRestartClass = L"InboxClassicRestart";
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
    bool done = false;
    bool accepted = false;
    // Options: its controls, and what they had when OK was clicked
    HWND combo = nullptr;
    HWND check = nullptr;
    HWND threadsCheck = nullptr;
    HWND codesCheck = nullptr;
    int picked = 0;
    bool notify = false;
    bool threads = false;
    bool codes = false;
};

LRESULT CALLBACK OptionsProc(HWND hwnd, UINT message, WPARAM wParam, LPARAM lParam) {
    auto* state = reinterpret_cast<OptionsState*>(GetWindowLongPtrW(hwnd, GWLP_USERDATA));
    if (state && ((message == WM_COMMAND && (LOWORD(wParam) == IDOK || LOWORD(wParam) == IDCANCEL)) || message == WM_CLOSE)) {
        state->accepted = message == WM_COMMAND && LOWORD(wParam) == IDOK;
        if (state->accepted && state->combo) {
            state->picked = static_cast<int>(SendMessageW(state->combo, CB_GETCURSEL, 0, 0));
            state->notify = Button_GetCheck(state->check) == BST_CHECKED;
            state->threads = Button_GetCheck(state->threadsCheck) == BST_CHECKED;
            state->codes = Button_GetCheck(state->codesCheck) == BST_CHECKED;
        }
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

bool OptionsDialog(HWND owner, bool& notify, bool& threads, bool& codes) {
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
    std::wstring codesText = core::T(PE_TEXT_UI_CODES_IN_NOTIFICATIONS);
    std::wstring ok = core::T(PE_TEXT_UI_OK), cancel = core::T(PE_TEXT_UI_CANCEL);
    int pad = Scale(12), row = Scale(22);
    int labelWidth = static_cast<int>(MeasureText(label).cx) + Scale(8);
    // wide enough for the longest language name and the check boxes' words
    int inner = std::max({Scale(360), labelWidth + Scale(200), static_cast<int>(MeasureText(notifyText).cx) + Scale(24),
                          static_cast<int>(MeasureText(threadsText).cx) + Scale(24),
                          static_cast<int>(MeasureText(codesText).cx) + Scale(48)});
    int width = 2 * pad + inner;
    int noteHeight = std::max(Scale(16), static_cast<int>(MeasureText(note, inner - labelWidth).cy));
    // the language and its note, a line, the notifications (with their codes under them) and the conversations, the
    // buttons
    int height = pad + row + Scale(4) + noteHeight + Scale(12) + 2 + Scale(12) + 3 * row + 2 * Scale(4) + Scale(16) + Scale(25) + pad;
    HWND dialog = CreateModalWindow(owner, kOptionsClass, core::Title(PE_TEXT_CMD_OPTIONS).c_str(), width, height);
    OptionsState state;

    int left = pad, right = width - pad, y = pad;
    CreateChild(dialog, L"STATIC", label.c_str(), SS_LEFT, 0, {left, y + Scale(3), left + labelWidth, y + row});
    HWND combo = CreateChild(dialog, L"COMBOBOX", L"", WS_TABSTOP | WS_VSCROLL | CBS_DROPDOWNLIST, IDC_OPTIONS_LANGUAGE,
                             {left + labelWidth, y, right, y + Scale(200)});
    // the first item follows Windows, and says which language that is now
    std::wstring systemItem = core::T(PE_TEXT_UI_OPTIONS_SYSTEM_DEFAULT, {{"language", nameOf(system)}});
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
    int buttonWidth = ButtonWidth({ok, cancel}), buttonTop = height - pad - Scale(25);
    CreateChild(dialog, L"BUTTON", ok.c_str(), WS_TABSTOP | BS_DEFPUSHBUTTON, IDOK,
                {width - pad - 2 * buttonWidth - Scale(6), buttonTop, width - pad - buttonWidth - Scale(6), buttonTop + Scale(25)});
    CreateChild(dialog, L"BUTTON", cancel.c_str(), WS_TABSTOP, IDCANCEL, {width - pad - buttonWidth, buttonTop, width - pad, buttonTop + Scale(25)});

    state.combo = combo;
    state.check = check;
    state.threadsCheck = threadsCheck;
    state.codesCheck = codesCheck;
    SetWindowLongPtrW(dialog, GWLP_USERDATA, reinterpret_cast<LONG_PTR>(&state));
    RunModal(dialog, combo, state.done);
    if (!state.accepted) {
        return false;
    }
    notify = state.notify;
    threads = state.threads;
    codes = state.codes;
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
