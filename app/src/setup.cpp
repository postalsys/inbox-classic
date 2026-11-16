// File > Export Settings and Accounts and Import Settings and Accounts: the setup file to take to another computer.
// The core writes and reads the file and words what it holds (pe_setup_*); these windows show that, hand back what is
// chosen, and carry the app preferences between the registry and the core by the names the three apps share.
#include "app.h"

#include <algorithm>

namespace {

const wchar_t* kExportClass = L"InboxClassicSetupExport";
const wchar_t* kImportClass = L"InboxClassicSetupImport";
const wchar_t* kDoneClass = L"InboxClassicSetupDone";

// the parts in the core's order (Parts::EACH), with the names the windows give them
struct Part {
    uint32_t flag;
    PeText name;
};
const Part kParts[] = {
    {PE_SETUP_ACCOUNTS, PE_TEXT_UI_SETUP_PART_ACCOUNTS}, {PE_SETUP_SIGN_IN_APPS, PE_TEXT_UI_SETUP_PART_SIGN_IN_APPS},
    {PE_SETUP_SETTINGS, PE_TEXT_UI_SETUP_PART_SETTINGS}, {PE_SETUP_PREFERENCES, PE_TEXT_UI_SETUP_PART_PREFERENCES},
    {PE_SETUP_CONTACTS, PE_TEXT_UI_SETUP_PART_CONTACTS}, {PE_SETUP_KEYS, PE_TEXT_UI_SETUP_PART_KEYS},
    {PE_SETUP_RULES, PE_TEXT_UI_SETUP_PART_RULES},       {PE_SETUP_TRUSTED_SENDERS, PE_TEXT_UI_SETUP_PART_TRUSTED},
};

// the place of the part `flag` in kParts, -1 for none
int PartIndex(uint32_t flag) {
    for (int i = 0; i < static_cast<int>(std::size(kParts)); i++) {
        if (kParts[i].flag == flag) {
            return i;
        }
    }
    return -1;
}

// the app preferences a setup carries, by their shared names, and where this app keeps them: the registry values of
// main.cpp (notifications, the folder list, the layout), mailbox.cpp (the list) and options.cpp (the language), with
// what each is when it is not set
struct Pref {
    const char* name;
    const wchar_t* value;
    DWORD fallback;
};
const Pref kPrefs[] = {
    {"notify_new_mail", L"NewMailNotifications", 1},
    {"codes_in_notifications", L"CodesInNotifications", 0},
    {"group_by_conversation", L"GroupByConversation", 1},
    {"hide_ignored", L"HideIgnoredConversations", 0},
    {"hide_read", L"HideReadMessages", 0},
    {"folder_list", L"FolderList", 1},
    {"list_pictures", L"ListPictures", 1},
    {"layout", L"Layout", PE_LAYOUT_MODE_AUTOMATIC},
};
const wchar_t* kLanguageValue = L"Language";

// the app preferences as they are now, handed to an export by the names the core knows
void HandPrefs(PeSetupExport* setup) {
    core::SetupPrefNames names(pe_setup_pref_names());
    for (size_t i = 0; i < pe_setup_pref_names_count(names.get()); i++) {
        const PeSetupPrefName* name = pe_setup_pref_names_get(names.get(), i);
        std::string value;
        if (name->kind == PE_SETUP_PREF_KIND_LANGUAGE) {
            value = core::Narrow(GetTextPreference(kLanguageValue));
        } else {
            auto found = std::find_if(std::begin(kPrefs), std::end(kPrefs), [&](const Pref& p) { return strcmp(p.name, name->name) == 0; });
            if (found == std::end(kPrefs)) {
                continue;
            }
            value = std::to_string(GetPreference(found->value, found->fallback));
        }
        pe_setup_export_set_pref(setup, name->name, value.c_str());
    }
}

HWND Item(HWND dialog, int id) {
    return GetDlgItem(dialog, id);
}

bool Checked(HWND dialog, int id) {
    return SendMessageW(Item(dialog, id), BM_GETCHECK, 0, 0) == BST_CHECKED;
}

// a check box as wide as its words
int CheckWidth(const std::wstring& text) {
    return static_cast<int>(MeasureText(text).cx) + GetSystemMetrics(SM_CXMENUCHECK) + Scale(10);
}

// the small system icon `icon` (IDI_WARNING, IDI_INFORMATION) in a static at `left`, `top`; shared, not destroyed
HWND SmallIcon(HWND dialog, const wchar_t* icon, int id, int left, int top) {
    int size = GetSystemMetrics(SM_CXSMICON);
    auto picture = static_cast<HICON>(LoadImageW(nullptr, icon, IMAGE_ICON, size, size, LR_SHARED));
    HWND sign = CreateChild(dialog, L"STATIC", nullptr, SS_ICON | SS_REALSIZECONTROL, id, {left, top, left + size, top + size});
    SendMessageW(sign, STM_SETICON, reinterpret_cast<WPARAM>(picture), 0);
    return sign;
}

// the default button `ok` and Cancel at the bottom right of a window `width` wide, their top at `top`
void BottomButtons(HWND dialog, int width, int top, const std::wstring& ok, const std::wstring& cancel) {
    int pad = Scale(10), buttonWidth = ButtonWidth({ok, cancel});
    CreateChild(dialog, L"BUTTON", ok.c_str(), WS_TABSTOP | BS_DEFPUSHBUTTON, IDOK,
                {width - pad - 2 * buttonWidth - Scale(6), top, width - pad - buttonWidth - Scale(6), top + Scale(25)});
    CreateChild(dialog, L"BUTTON", cancel.c_str(), WS_TABSTOP, IDCANCEL, {width - pad - buttonWidth, top, width - pad, top + Scale(25)});
}

// ---- what was done: the lines of the core, and Done ----

struct DoneState {
    bool done = false;
};

LRESULT CALLBACK DoneProc(HWND hwnd, UINT message, WPARAM wParam, LPARAM lParam) {
    auto* state = reinterpret_cast<DoneState*>(GetWindowLongPtrW(hwnd, GWLP_USERDATA));
    if (state && ((message == WM_COMMAND && (LOWORD(wParam) == IDOK || LOWORD(wParam) == IDCANCEL)) || message == WM_CLOSE)) {
        state->done = true;
        return 0;
    }
    if (message == WM_CTLCOLORSTATIC) {
        return ButtonFaceColor(reinterpret_cast<HDC>(wParam));
    }
    return DefWindowProcW(hwnd, message, wParam, lParam);
}

// the lines of an export or an import with Done: `intro` over them when not empty; a part's line as its name beside
// what it holds, what was added and skipped as they are, a note with the information sign before it
void DoneDialog(HWND owner, const std::wstring& title, const std::wstring& intro, const PeSetupLines* lines) {
    RegisterDialogClass(kDoneClass, DoneProc);
    int pad = Scale(12), width = Scale(460), gap = Scale(6);
    int icon = GetSystemMetrics(SM_CXSMICON) + Scale(6);
    size_t count = pe_setup_lines_count(lines);
    std::vector<std::wstring> names;
    for (size_t i = 0; i < count; i++) {
        const PeSetupLine* line = pe_setup_lines_get(lines, i);
        if (line->kind == PE_SETUP_LINE_KIND_PART && PartIndex(line->part) >= 0) {
            names.push_back(core::T(kParts[PartIndex(line->part)].name));
        }
    }
    int nameWidth = names.empty() ? 0 : LabelWidth(names, 60, 16);
    // each line's place and height first, then the window as tall as they need
    struct Row {
        const PeSetupLine* line;
        int top;
        int height;
    };
    std::vector<Row> rows;
    int introHeight = intro.empty() ? 0 : static_cast<int>(MeasureText(intro, width - 2 * pad).cy) + Scale(10);
    int top = pad + introHeight;
    for (size_t i = 0; i < count; i++) {
        const PeSetupLine* line = pe_setup_lines_get(lines, i);
        std::wstring text = Text(line->text);
        int left = line->kind == PE_SETUP_LINE_KIND_PART ? nameWidth : line->kind == PE_SETUP_LINE_KIND_NOTE ? icon : 0;
        int height = static_cast<int>(MeasureText(text, width - 2 * pad - left).cy);
        if (line->kind == PE_SETUP_LINE_KIND_NOTE) {
            height = std::max(height, GetSystemMetrics(SM_CYSMICON));
        }
        rows.push_back({line, top, height});
        top += height + gap;
    }
    int height = top + Scale(10) + Scale(25) + pad;
    HWND dialog = CreateModalWindow(owner, kDoneClass, title.c_str(), width, height);
    DoneState state;
    if (!intro.empty()) {
        CreateChild(dialog, L"STATIC", intro.c_str(), SS_LEFT | SS_NOPREFIX, 0, {pad, pad, width - pad, pad + introHeight});
    }
    for (const Row& row : rows) {
        std::wstring text = Text(row.line->text);
        int left = pad;
        if (row.line->kind == PE_SETUP_LINE_KIND_PART && PartIndex(row.line->part) >= 0) {
            std::wstring name = core::T(kParts[PartIndex(row.line->part)].name);
            CreateChild(dialog, L"STATIC", name.c_str(), SS_LEFT | SS_NOPREFIX, 0, {pad, row.top, pad + nameWidth, row.top + row.height});
            left += nameWidth;
        } else if (row.line->kind == PE_SETUP_LINE_KIND_NOTE) {
            SmallIcon(dialog, IDI_INFORMATION, 0, pad, row.top);
            left += icon;
        }
        CreateChild(dialog, L"STATIC", text.c_str(), SS_LEFT | SS_NOPREFIX, 0, {left, row.top, width - pad, row.top + row.height});
    }
    std::wstring done = core::T(PE_TEXT_UI_SETUP_DONE);
    int buttonWidth = ButtonWidth({done});
    HWND button = CreateChild(dialog, L"BUTTON", done.c_str(), WS_TABSTOP | BS_DEFPUSHBUTTON, IDOK,
                              {width - pad - buttonWidth, height - pad - Scale(25), width - pad, height - pad});
    SetWindowLongPtrW(dialog, GWLP_USERDATA, reinterpret_cast<LONG_PTR>(&state));
    RunModal(dialog, button, state.done);
}

// ---- Export ----

struct ExportState {
    PeCore* core = nullptr;
    std::wstring title;
    // the file written and what the core said it holds
    std::wstring path;
    core::SetupLines lines;
    bool done = false;
};

uint32_t ChosenParts(HWND dialog) {
    uint32_t parts = 0;
    for (int i = 0; i < static_cast<int>(std::size(kParts)); i++) {
        if (Item(dialog, IDC_SETUP_PART + i) && Checked(dialog, IDC_SETUP_PART + i)) {
            parts |= kParts[i].flag;
        }
    }
    return parts;
}

// the core's words for what is wrong with the passphrase typed, as it is typed: too short once something is typed,
// typed differently once the second field has something; and whether it can be taken
std::wstring PassphraseProblem(HWND dialog, bool& good) {
    std::string first = ReadSecret(Item(dialog, IDC_SETUP_PASSPHRASE));
    std::string again = ReadSecret(Item(dialog, IDC_SETUP_PASSPHRASE_AGAIN));
    core::String alone(pe_pgp_passphrase_problem(first.c_str(), first.c_str()));
    core::String both(pe_pgp_passphrase_problem(first.c_str(), again.c_str()));
    good = !first.empty() && !both;
    std::wstring problem = first.empty() ? L"" : alone ? Text(alone.get()) : !again.empty() && both ? Text(both.get()) : L"";
    Wipe(first);
    Wipe(again);
    return problem;
}

// the window as what is chosen and typed allows: the passphrase fields with the check box, why a passphrase is not
// taken under them, Export only with a part and, when wanted, a passphrase that can be taken
void UpdateExport(HWND dialog) {
    bool protect = Checked(dialog, IDC_SETUP_USE_PASSPHRASE);
    for (int id : {IDC_SETUP_PASSPHRASE, IDC_SETUP_PASSPHRASE_AGAIN}) {
        EnableWindow(Item(dialog, id), protect);
        // the label before the field
        EnableWindow(GetWindow(Item(dialog, id), GW_HWNDPREV), protect);
    }
    bool good = true;
    std::wstring problem = protect ? PassphraseProblem(dialog, good) : L"";
    HWND words = Item(dialog, IDC_SETUP_PROBLEM);
    if (GetWindowString(words) != problem) {
        SetWindowTextW(words, problem.c_str());
    }
    ShowWindow(words, problem.empty() ? SW_HIDE : SW_SHOW);
    ShowWindow(GetWindow(words, GW_HWNDPREV), problem.empty() ? SW_HIDE : SW_SHOW);
    SetAccessibleDescription(Item(dialog, IDC_SETUP_PASSPHRASE_AGAIN), problem);
    EnableWindow(Item(dialog, IDOK), ChosenParts(dialog) != 0 && good);
}

// the fields' own copies written over before the window goes, as far as the edit control lets them be
void WipeFields(HWND dialog) {
    for (int id : {IDC_SETUP_PASSPHRASE, IDC_SETUP_PASSPHRASE_AGAIN}) {
        HWND edit = Item(dialog, id);
        int length = GetWindowTextLengthW(edit);
        SetWindowTextW(edit, std::wstring(static_cast<size_t>(length), L' ').c_str());
        SetWindowTextW(edit, L"");
    }
}

// Export: where to save asked, then the file written with what is chosen; the window stays when it could not be
void WriteExport(HWND dialog, ExportState& state) {
    uint32_t parts = ChosenParts(dialog);
    core::SetupExport setup(pe_setup_export_new(parts));
    HandPrefs(setup.get());
    std::wstring filter = FileFilter({{core::T(PE_TEXT_UI_SETUP_FILE_FILTER), L"*.inboxclassic"}});
    std::wstring path = SaveFileDialog(dialog, L"Inbox Classic.inboxclassic", state.title.c_str(), filter.c_str(), L"inboxclassic");
    if (path.empty()) {
        return;
    }
    if (Checked(dialog, IDC_SETUP_USE_PASSPHRASE)) {
        std::string passphrase = ReadSecret(Item(dialog, IDC_SETUP_PASSPHRASE));
        pe_setup_export_set_passphrase(setup.get(), passphrase.c_str());
        Wipe(passphrase);
    }
    HCURSOR old = SetCursor(LoadCursorW(nullptr, IDC_WAIT));
    char* error = nullptr;
    core::SetupLines lines(pe_setup_export_write(state.core, setup.get(), core::Narrow(path).c_str(), &error));
    SetCursor(old);
    // the passphrase leaves memory with the export
    setup.reset();
    if (!lines) {
        MessageBoxW(dialog, ReasonText(error, PE_TEXT_UI_UNKNOWN_REASON).c_str(), state.title.c_str(), MB_OK | MB_ICONWARNING);
        return;
    }
    core::String unused(error);
    state.path = path;
    state.lines = std::move(lines);
    state.done = true;
    WipeFields(dialog);
}

LRESULT CALLBACK ExportProc(HWND hwnd, UINT message, WPARAM wParam, LPARAM lParam) {
    auto* state = reinterpret_cast<ExportState*>(GetWindowLongPtrW(hwnd, GWLP_USERDATA));
    if (!state) {
        return DefWindowProcW(hwnd, message, wParam, lParam);
    }
    switch (message) {
    case WM_COMMAND: {
        WORD id = LOWORD(wParam);
        if (id == IDOK) {
            // Enter with Export turned off does nothing
            if (IsWindowEnabled(Item(hwnd, IDOK))) {
                WriteExport(hwnd, *state);
            }
        } else if (id == IDCANCEL) {
            WipeFields(hwnd);
            state->done = true;
        } else if (HIWORD(wParam) == EN_CHANGE || HIWORD(wParam) == BN_CLICKED) {
            UpdateExport(hwnd);
        }
        return 0;
    }
    case WM_CLOSE:
        WipeFields(hwnd);
        state->done = true;
        return 0;
    case WM_CTLCOLORSTATIC:
        return ButtonFaceColor(reinterpret_cast<HDC>(wParam));
    }
    return DefWindowProcW(hwnd, message, wParam, lParam);
}

// ---- Import ----

struct ImportState {
    PeCore* core = nullptr;
    const PeSetupFile* file = nullptr;
    std::wstring title;
    // the file's account of each account check box, and whether it can be chosen
    std::vector<size_t> accounts;
    std::vector<bool> choosable;
    uint32_t parts = 0;
    core::SetupLines lines;
    bool done = false;
};

// the Accounts part and its accounts kept together after the check box `id` was clicked: the part ticks or unticks
// every account that can be imported, an account ticks the part while one is ticked; Import only with a part
void UpdateImport(HWND dialog, const ImportState& state, int id) {
    int accountsPart = IDC_SETUP_PART + PartIndex(PE_SETUP_ACCOUNTS);
    int count = static_cast<int>(state.accounts.size());
    if (id == accountsPart) {
        bool on = Checked(dialog, accountsPart);
        for (int i = 0; i < count; i++) {
            if (state.choosable[i]) {
                SendMessageW(Item(dialog, IDC_SETUP_ACCOUNT + i), BM_SETCHECK, on ? BST_CHECKED : BST_UNCHECKED, 0);
            }
        }
    } else if (id >= IDC_SETUP_ACCOUNT && id < IDC_SETUP_ACCOUNT + count) {
        bool any = false;
        for (int i = 0; i < count; i++) {
            any = any || (state.choosable[i] && Checked(dialog, IDC_SETUP_ACCOUNT + i));
        }
        SendMessageW(Item(dialog, accountsPart), BM_SETCHECK, any ? BST_CHECKED : BST_UNCHECKED, 0);
    }
    EnableWindow(Item(dialog, IDOK), ChosenParts(dialog) != 0);
}

// Import: what is chosen imported; the window stays when nothing could be
void RunImport(HWND dialog, ImportState& state) {
    uint32_t parts = ChosenParts(dialog);
    std::vector<size_t> accounts;
    if (parts & PE_SETUP_ACCOUNTS) {
        for (size_t i = 0; i < state.accounts.size(); i++) {
            if (state.choosable[i] && Checked(dialog, IDC_SETUP_ACCOUNT + static_cast<int>(i))) {
                accounts.push_back(state.accounts[i]);
            }
        }
    }
    HCURSOR old = SetCursor(LoadCursorW(nullptr, IDC_WAIT));
    char* error = nullptr;
    core::SetupLines lines(pe_setup_import(state.core, state.file, parts, accounts.data(), accounts.size(), &error));
    SetCursor(old);
    if (!lines) {
        MessageBoxW(dialog, ReasonText(error, PE_TEXT_UI_UNKNOWN_REASON).c_str(), state.title.c_str(), MB_OK | MB_ICONWARNING);
        return;
    }
    core::String unused(error);
    state.parts = parts;
    state.lines = std::move(lines);
    state.done = true;
}

LRESULT CALLBACK ImportProc(HWND hwnd, UINT message, WPARAM wParam, LPARAM lParam) {
    auto* state = reinterpret_cast<ImportState*>(GetWindowLongPtrW(hwnd, GWLP_USERDATA));
    if (!state) {
        return DefWindowProcW(hwnd, message, wParam, lParam);
    }
    switch (message) {
    case WM_COMMAND: {
        WORD id = LOWORD(wParam);
        if (id == IDOK) {
            if (IsWindowEnabled(Item(hwnd, IDOK))) {
                RunImport(hwnd, *state);
            }
        } else if (id == IDCANCEL) {
            state->done = true;
        } else if (HIWORD(wParam) == BN_CLICKED) {
            UpdateImport(hwnd, *state, id);
        }
        return 0;
    }
    case WM_CLOSE:
        state->done = true;
        return 0;
    case WM_CTLCOLORSTATIC:
        return ButtonFaceColor(reinterpret_cast<HDC>(wParam));
    }
    return DefWindowProcW(hwnd, message, wParam, lParam);
}

// the setup file at `path` read, its passphrase asked for while the core wants one; NULL when it could not be read
// (said) or the passphrase was not given
core::SetupFile ReadSetup(HWND owner, PeCore* core, const std::wstring& path, const std::wstring& title) {
    std::string utf8 = core::Narrow(path);
    std::string passphrase;
    bool asked = false;
    for (;;) {
        PeSetupError kind = PE_SETUP_ERROR_NONE;
        char* error = nullptr;
        core::SetupFile file(pe_setup_read(core, utf8.c_str(), asked ? passphrase.c_str() : nullptr, &kind, &error));
        Wipe(passphrase);
        std::wstring said = ReasonText(error, PE_TEXT_UI_UNKNOWN_REASON);
        if (file) {
            return file;
        }
        if (kind != PE_SETUP_ERROR_NEEDS_PASSPHRASE && kind != PE_SETUP_ERROR_WRONG_PASSPHRASE) {
            MessageBoxW(owner, said.c_str(), title.c_str(), MB_OK | MB_ICONWARNING);
            return nullptr;
        }
        // asked again after a wrong one, with the core's words for it
        std::wstring problem = kind == PE_SETUP_ERROR_WRONG_PASSPHRASE ? said : L"";
        if (!PassphraseDialog(owner, title, core::T(PE_TEXT_UI_SETUP_ASK_PASSPHRASE), problem, false, passphrase)) {
            return nullptr;
        }
        asked = true;
    }
}

// the import window over the file read: what it holds to choose from; true with what was imported in `state`
bool ChooseImport(HWND owner, ImportState& state) {
    RegisterDialogClass(kImportClass, ImportProc);
    const PeSetupInfo* info = pe_setup_file_info(state.file);
    std::wstring intro = core::T(PE_TEXT_UI_SETUP_IMPORT_INTRO);
    std::wstring from = core::T(PE_TEXT_UI_SETUP_FROM, {{"version", Text(info->app_version)}, {"date", Text(info->created_text)}});
    int pad = Scale(12), width = Scale(500), gap = Scale(4), checkHeight = Scale(20), indent = Scale(20);
    int warning = GetSystemMetrics(SM_CXSMICON) + Scale(6);

    // the parts the file holds, their names a column before the core's words for what each holds
    size_t partCount = pe_setup_file_part_count(state.file);
    std::vector<const PeSetupLine*> parts;
    int nameWidth = 0;
    for (size_t i = 0; i < partCount; i++) {
        const PeSetupLine* part = pe_setup_file_part(state.file, i);
        if (PartIndex(part->part) >= 0) {
            parts.push_back(part);
            nameWidth = std::max(nameWidth, CheckWidth(core::T(kParts[PartIndex(part->part)].name)) + Scale(12));
        }
    }
    nameWidth = std::min(nameWidth, (width - 2 * pad) / 2);
    int wordsWidth = width - 2 * pad - nameWidth;
    // each account: its check box, its servers and how it signs in, and what an import does with it
    struct AccountRows {
        std::wstring label, servers, note;
        int noteHeight;
    };
    std::vector<AccountRows> accountRows;
    int textLeft = indent + GetSystemMetrics(SM_CXMENUCHECK) + Scale(4);
    for (size_t i = 0; i < pe_setup_file_account_count(state.file); i++) {
        const PeSetupAccount* account = pe_setup_file_account(state.file, i);
        std::wstring email = Text(account->email), title = Text(account->title);
        std::wstring label = title.empty() || title == email ? email : title + L" (" + email + L")";
        std::wstring servers = Text(account->imap) + L", " + Text(account->smtp) + L", " + Text(account->sign_in);
        std::wstring note = Text(account->problem ? account->problem : account->note);
        int noteHeight = note.empty() ? 0 : static_cast<int>(MeasureText(note, width - 2 * pad - textLeft).cy);
        accountRows.push_back({label, servers, note, noteHeight});
        state.accounts.push_back(account->index);
        state.choosable.push_back(!account->here && !account->problem);
    }
    std::vector<std::wstring> notes;
    for (size_t i = 0; i < pe_setup_file_note_count(state.file); i++) {
        notes.push_back(Text(pe_setup_file_note(state.file, i)));
    }

    // the height of everything, to make the window as tall
    int introHeight = static_cast<int>(MeasureText(intro, width - 2 * pad).cy);
    int fromHeight = static_cast<int>(MeasureText(from, width - 2 * pad).cy);
    int lineHeight = static_cast<int>(MeasureText(L"Ag").cy);
    int height = pad + introHeight + Scale(6) + fromHeight + Scale(12);
    for (const PeSetupLine* part : parts) {
        height += std::max(checkHeight, static_cast<int>(MeasureText(Text(part->text), wordsWidth).cy) + Scale(3)) + gap;
        if (part->part == PE_SETUP_ACCOUNTS) {
            for (const AccountRows& row : accountRows) {
                height += checkHeight + lineHeight + row.noteHeight + Scale(8);
            }
        }
    }
    for (const std::wstring& note : notes) {
        height += std::max(GetSystemMetrics(SM_CYSMICON), static_cast<int>(MeasureText(note, width - 2 * pad - warning).cy)) + Scale(6);
    }
    height += Scale(10) + Scale(25) + pad;

    HWND dialog = CreateModalWindow(owner, kImportClass, state.title.c_str(), width, height);
    int top = pad;
    CreateChild(dialog, L"STATIC", intro.c_str(), SS_LEFT | SS_NOPREFIX, 0, {pad, top, width - pad, top + introHeight});
    top += introHeight + Scale(6);
    CreateChild(dialog, L"STATIC", from.c_str(), SS_LEFT | SS_NOPREFIX, IDC_SETUP_FROM, {pad, top, width - pad, top + fromHeight});
    top += fromHeight + Scale(12);
    HWND first = nullptr;
    for (const PeSetupLine* part : parts) {
        std::wstring words = Text(part->text);
        int rowHeight = std::max(checkHeight, static_cast<int>(MeasureText(words, wordsWidth).cy) + Scale(3));
        HWND check = CreateChild(dialog, L"BUTTON", core::T(kParts[PartIndex(part->part)].name).c_str(), WS_TABSTOP | BS_AUTOCHECKBOX,
                                 IDC_SETUP_PART + PartIndex(part->part), {pad, top, pad + nameWidth - Scale(8), top + checkHeight});
        SendMessageW(check, BM_SETCHECK, BST_CHECKED, 0);
        SetAccessibleDescription(check, words);
        first = first ? first : check;
        CreateChild(dialog, L"STATIC", words.c_str(), SS_LEFT | SS_NOPREFIX, 0,
                    {pad + nameWidth, top + Scale(3), width - pad, top + rowHeight});
        top += rowHeight + gap;
        if (part->part != PE_SETUP_ACCOUNTS) {
            continue;
        }
        for (size_t i = 0; i < accountRows.size(); i++) {
            const AccountRows& row = accountRows[i];
            HWND box = CreateChild(dialog, L"BUTTON", row.label.c_str(), WS_TABSTOP | BS_AUTOCHECKBOX | (state.choosable[i] ? 0 : WS_DISABLED), IDC_SETUP_ACCOUNT + static_cast<int>(i),
                                   {pad + indent, top, width - pad, top + checkHeight});
            SendMessageW(box, BM_SETCHECK, state.choosable[i] ? BST_CHECKED : BST_UNCHECKED, 0);
            SetAccessibleDescription(box, row.servers + L". " + row.note);
            top += checkHeight;
            CreateChild(dialog, L"STATIC", row.servers.c_str(), SS_LEFT | SS_NOPREFIX | SS_ENDELLIPSIS, 0,
                        {pad + textLeft, top, width - pad, top + lineHeight});
            top += lineHeight;
            if (!row.note.empty()) {
                CreateChild(dialog, L"STATIC", row.note.c_str(), SS_LEFT | SS_NOPREFIX, 0, {pad + textLeft, top, width - pad, top + row.noteHeight});
                top += row.noteHeight;
            }
            top += Scale(8);
        }
    }
    for (const std::wstring& note : notes) {
        int noteHeight = std::max(GetSystemMetrics(SM_CYSMICON), static_cast<int>(MeasureText(note, width - 2 * pad - warning).cy));
        SmallIcon(dialog, IDI_WARNING, 0, pad, top);
        CreateChild(dialog, L"STATIC", note.c_str(), SS_LEFT | SS_NOPREFIX, 0, {pad + warning, top, width - pad, top + noteHeight});
        top += noteHeight + Scale(6);
    }
    BottomButtons(dialog, width, height - pad - Scale(25), core::T(PE_TEXT_UI_SETUP_IMPORT_BUTTON), core::T(PE_TEXT_UI_CANCEL));
    SetWindowLongPtrW(dialog, GWLP_USERDATA, reinterpret_cast<LONG_PTR>(&state));
    // with no account that can be imported (all here already, or with a problem), Accounts is unticked and off; its
    // accounts stay listed with what keeps each out
    if (std::find(state.choosable.begin(), state.choosable.end(), true) == state.choosable.end()) {
        HWND accountsPart = Item(dialog, IDC_SETUP_PART + PartIndex(PE_SETUP_ACCOUNTS));
        SendMessageW(accountsPart, BM_SETCHECK, BST_UNCHECKED, 0);
        EnableWindow(accountsPart, FALSE);
    }
    UpdateImport(dialog, state, 0);
    // Enter imports what is chosen; Tab goes through the parts first
    RunModal(dialog, Item(dialog, IDOK), state.done);
    return state.lines != nullptr;
}

}  // namespace

void ExportSetupDialog(HWND owner, PeCore* core) {
    HelpScope help("setup");
    RegisterDialogClass(kExportClass, ExportProc);
    ExportState state{core, core::Plain(PE_TEXT_UI_SETUP_EXPORT_TITLE)};
    std::wstring intro = core::T(PE_TEXT_UI_SETUP_EXPORT_INTRO), protect = core::T(PE_TEXT_UI_SETUP_USE_PASSPHRASE);
    std::wstring note = core::T(PE_TEXT_UI_SETUP_PASSPHRASE_NOTE);
    // the fields' labels without their letters: P is Protect's here
    std::wstring label = core::Plain(PE_TEXT_UI_KEYS_PASSPHRASE), againLabel = core::Plain(PE_TEXT_UI_KEYS_PASSPHRASE_AGAIN);
    int pad = Scale(12), width = Scale(460), checkHeight = Scale(20), row = Scale(22), gap = Scale(6), indent = Scale(20);
    int warning = GetSystemMetrics(SM_CXSMICON) + Scale(6);
    int introHeight = static_cast<int>(MeasureText(intro, width - 2 * pad).cy);
    int noteHeight = static_cast<int>(MeasureText(note, width - 2 * pad - indent).cy);
    int labelWidth = LabelWidth({label, againLabel}, 90);
    // room under the fields for the longer of the two refusals, so the window keeps its size while typing
    core::String shortWords(pe_pgp_passphrase_problem("", ""));
    core::String differWords(pe_pgp_passphrase_problem("passphrase one", "passphrase two"));
    int problemHeight = GetSystemMetrics(SM_CYSMICON);
    for (const core::String* words : {&shortWords, &differWords}) {
        if (*words) {
            problemHeight = std::max(problemHeight, static_cast<int>(MeasureText(Text(words->get()), width - 2 * pad - indent - warning).cy));
        }
    }
    int partsHeight = static_cast<int>(std::size(kParts)) * checkHeight;
    int height = pad + introHeight + Scale(10) + partsHeight + Scale(12) + 2 + Scale(10) + checkHeight + Scale(2) + noteHeight + Scale(8) +
                 2 * (row + gap) + problemHeight + Scale(14) + Scale(25) + pad;
    HWND dialog = CreateModalWindow(owner, kExportClass, state.title.c_str(), width, height);

    int top = pad;
    CreateChild(dialog, L"STATIC", intro.c_str(), SS_LEFT | SS_NOPREFIX, 0, {pad, top, width - pad, top + introHeight});
    top += introHeight + Scale(10);
    for (int i = 0; i < static_cast<int>(std::size(kParts)); i++) {
        HWND check = CreateChild(dialog, L"BUTTON", core::T(kParts[i].name).c_str(), WS_TABSTOP | BS_AUTOCHECKBOX, IDC_SETUP_PART + i,
                                 {pad, top, width - pad, top + checkHeight});
        SendMessageW(check, BM_SETCHECK, BST_CHECKED, 0);
        top += checkHeight;
    }
    top += Scale(12);
    CreateChild(dialog, L"STATIC", L"", SS_ETCHEDHORZ, 0, {pad, top, width - pad, top + 2});
    top += 2 + Scale(10);
    CreateChild(dialog, L"BUTTON", protect.c_str(), WS_TABSTOP | BS_AUTOCHECKBOX, IDC_SETUP_USE_PASSPHRASE, {pad, top, width - pad, top + checkHeight});
    top += checkHeight + Scale(2);
    CreateChild(dialog, L"STATIC", note.c_str(), SS_LEFT | SS_NOPREFIX, IDC_SETUP_PASSPHRASE_NOTE,
                {pad + indent, top, width - pad, top + noteHeight});
    top += noteHeight + Scale(8);
    const std::pair<const std::wstring*, int> fields[] = {{&label, IDC_SETUP_PASSPHRASE}, {&againLabel, IDC_SETUP_PASSPHRASE_AGAIN}};
    for (const auto& [text, id] : fields) {
        CreateChild(dialog, L"STATIC", text->c_str(), SS_LEFT, 0, {pad + indent, top + Scale(3), pad + indent + labelWidth, top + row});
        CreateChild(dialog, L"EDIT", L"", WS_TABSTOP | ES_AUTOHSCROLL | ES_PASSWORD, id, {pad + indent + labelWidth, top, width - pad, top + row},
                    WS_EX_CLIENTEDGE);
        top += row + gap;
    }
    SmallIcon(dialog, IDI_WARNING, 0, pad + indent, top);
    CreateChild(dialog, L"STATIC", L"", SS_LEFT | SS_NOPREFIX, IDC_SETUP_PROBLEM, {pad + indent + warning, top, width - pad, top + problemHeight});
    BottomButtons(dialog, width, height - pad - Scale(25), core::T(PE_TEXT_UI_SETUP_EXPORT_BUTTON), core::T(PE_TEXT_UI_CANCEL));
    SetWindowLongPtrW(dialog, GWLP_USERDATA, reinterpret_cast<LONG_PTR>(&state));
    UpdateExport(dialog);
    RunModal(dialog, Item(dialog, IDOK), state.done);
    if (state.lines) {
        DoneDialog(owner, state.title, state.path, state.lines.get());
    }
}

SetupImported ImportSetupDialog(HWND owner, PeCore* core) {
    HelpScope help("setup");
    SetupImported result;
    std::wstring title = core::Plain(PE_TEXT_UI_SETUP_IMPORT_TITLE);
    std::wstring filter =
        FileFilter({{core::T(PE_TEXT_UI_SETUP_FILE_FILTER), L"*.inboxclassic"}, {core::T(PE_TEXT_UI_FILTER_ALL), L"*.*"}});
    std::wstring path = OpenFileDialog(owner, title.c_str(), filter.c_str());
    if (path.empty()) {
        return result;
    }
    core::SetupFile file = ReadSetup(owner, core, path, title);
    if (!file) {
        return result;
    }
    ImportState state{core, file.get(), title};
    if (!ChooseImport(owner, state)) {
        return result;
    }
    result.imported = true;
    size_t count = 0;
    if (const int64_t* added = pe_setup_lines_accounts(state.lines.get(), &count)) {
        result.accounts.assign(added, added + count);
    }
    if (state.parts & PE_SETUP_PREFERENCES) {
        for (size_t i = 0; i < pe_setup_file_pref_count(file.get()); i++) {
            const PeSetupPref* pref = pe_setup_file_pref(file.get(), i);
            result.prefs.emplace_back(pref->name, pref->value);
        }
    }
    DoneDialog(owner, title, L"", state.lines.get());
    return result;
}
