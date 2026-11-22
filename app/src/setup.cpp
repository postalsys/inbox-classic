// File > Export Settings and Accounts and Import Settings and Accounts: the setup file to take to another computer.
// The core writes and reads the file and words what it holds (pe_setup_*); these windows show that, hand back what is
// chosen, and carry the app preferences between the registry and the core by the names the three apps share. Reading,
// writing and importing run on a thread of their own (a sealed file's key takes a moment, an import reaches the
// sign-in services), the window waiting meanwhile.
#include "app.h"

#include <algorithm>
#include <atomic>
#include <thread>

namespace {

const wchar_t* kExportClass = L"InboxClassicSetupExport";
const wchar_t* kImportClass = L"InboxClassicSetupImport";
const wchar_t* kDoneClass = L"InboxClassicSetupDone";

// the parts in the core's order (pe_setup_parts): a part's check box is IDC_SETUP_PART + its place here
std::vector<uint32_t> PartFlags() {
    std::vector<uint32_t> flags;
    core::SetupLines parts(pe_setup_parts());
    for (size_t i = 0; i < pe_setup_lines_count(parts.get()); i++) {
        flags.push_back(pe_setup_lines_get(parts.get(), i)->part);
    }
    return flags;
}

// the check box of the part `flag`, 0 for a flag the core does not list
int PartId(uint32_t flag) {
    static const std::vector<uint32_t> flags = PartFlags();
    auto found = std::find(flags.begin(), flags.end(), flag);
    return found == flags.end() ? 0 : IDC_SETUP_PART + static_cast<int>(found - flags.begin());
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

void Check(HWND dialog, int id, bool on) {
    SendMessageW(Item(dialog, id), BM_SETCHECK, on ? BST_CHECKED : BST_UNCHECKED, 0);
}

// a check box as wide as its words
int CheckWidth(const std::wstring& text) {
    return static_cast<int>(MeasureText(text).cx) + GetSystemMetrics(SM_CXMENUCHECK) + Scale(10);
}

// `text` wrapped in `width`: its height
int Wrapped(const std::wstring& text, int width) {
    return static_cast<int>(MeasureText(text, width).cy);
}

HWND Label(HWND dialog, const std::wstring& text, int id, int left, int top, int right, int height) {
    return CreateChild(dialog, L"STATIC", text.c_str(), SS_LEFT | SS_NOPREFIX, id, {left, top, right, top + height});
}

// a window laid out top to bottom: each row measured once, the window made as tall as they are, then each made at its
// place
struct Row {
    int height;
    // the room under it
    int gap;
    std::function<void(HWND dialog, int top)> make;
};

int RowsHeight(const std::vector<Row>& rows) {
    int height = 0;
    for (const Row& row : rows) {
        height += row.height + row.gap;
    }
    return height;
}

void PlaceRows(HWND dialog, const std::vector<Row>& rows, int top) {
    for (const Row& row : rows) {
        row.make(dialog, top);
        top += row.height + row.gap;
    }
}

// `work` on a thread of its own while the window `waiting` waits for it: it keeps painting, takes no input meanwhile
// (its OK button off, the wait cursor over it), and goes on once the thread is done
void RunWaiting(HWND waiting, const std::function<void()>& work) {
    HWND ok = Item(waiting, IDOK);
    bool okOn = ok && IsWindowEnabled(ok);
    if (ok) {
        EnableWindow(ok, FALSE);
    }
    std::atomic<bool> finished = false;
    DWORD windowThread = GetCurrentThreadId();
    std::thread worker([&] {
        work();
        finished = true;
        // wakes the loop below
        PostThreadMessageW(windowThread, WM_NULL, 0, 0);
    });
    HCURSOR wait = LoadCursorW(nullptr, IDC_WAIT);
    SetCursor(wait);
    MSG msg = {};
    bool quit = false;
    while (!finished && !quit) {
        if (GetMessageW(&msg, nullptr, 0, 0) <= 0) {
            quit = true;
            break;
        }
        bool keys = msg.message >= WM_KEYFIRST && msg.message <= WM_KEYLAST;
        bool mouse = (msg.message >= WM_MOUSEFIRST && msg.message <= WM_MOUSELAST) || (msg.message >= WM_NCMOUSEMOVE && msg.message <= WM_NCXBUTTONDBLCLK);
        if (keys || mouse) {
            if (msg.message == WM_MOUSEMOVE || msg.message == WM_NCMOUSEMOVE) {
                SetCursor(wait);
            }
            continue;
        }
        TranslateMessage(&msg);
        DispatchMessageW(&msg);
    }
    worker.join();
    if (quit) {
        // kept for the main loop
        PostQuitMessage(static_cast<int>(msg.wParam));
    }
    if (ok) {
        EnableWindow(ok, okOn);
    }
    SetCursor(LoadCursorW(nullptr, IDC_ARROW));
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

// the small system icon `icon` (IDI_INFORMATION) in a static at `left`, `top`; shared, not destroyed
void SmallIcon(HWND dialog, const wchar_t* icon, int left, int top) {
    int size = GetSystemMetrics(SM_CXSMICON);
    auto picture = static_cast<HICON>(LoadImageW(nullptr, icon, IMAGE_ICON, size, size, LR_SHARED));
    HWND sign = CreateChild(dialog, L"STATIC", nullptr, SS_ICON | SS_REALSIZECONTROL, 0, {left, top, left + size, top + size});
    SendMessageW(sign, STM_SETICON, reinterpret_cast<WPARAM>(picture), 0);
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
        if (line->kind == PE_SETUP_LINE_KIND_PART) {
            names.push_back(Text(line->name));
        }
    }
    int nameWidth = names.empty() ? 0 : LabelWidth(names, 60, 16);
    std::vector<Row> rows;
    if (!intro.empty()) {
        int height = Wrapped(intro, width - 2 * pad);
        rows.push_back({height, Scale(10), [=](HWND dialog, int top) { Label(dialog, intro, 0, pad, top, width - pad, height); }});
    }
    for (size_t i = 0; i < count; i++) {
        const PeSetupLine* line = pe_setup_lines_get(lines, i);
        std::wstring text = Text(line->text), name = Text(line->name);
        bool part = line->kind == PE_SETUP_LINE_KIND_PART, note = line->kind == PE_SETUP_LINE_KIND_NOTE;
        int left = pad + (part ? nameWidth : note ? icon : 0);
        int height = Wrapped(text, width - pad - left);
        if (note) {
            height = std::max(height, GetSystemMetrics(SM_CYSMICON));
        }
        rows.push_back({height, gap, [=](HWND dialog, int top) {
                            if (part) {
                                Label(dialog, name, 0, pad, top, pad + nameWidth, height);
                            } else if (note) {
                                SmallIcon(dialog, IDI_INFORMATION, pad, top);
                            }
                            Label(dialog, text, 0, left, top, width - pad, height);
                        }});
    }
    int height = pad + RowsHeight(rows) + Scale(10) + Scale(25) + pad;
    HWND dialog = CreateModalWindow(owner, kDoneClass, title.c_str(), width, height);
    DoneState state;
    PlaceRows(dialog, rows, pad);
    std::wstring done = core::T(PE_TEXT_UI_SETUP_DONE);
    int buttonWidth = ButtonWidth({done});
    HWND button = CreateChild(dialog, L"BUTTON", done.c_str(), WS_TABSTOP | BS_DEFPUSHBUTTON, IDOK,
                              {width - pad - buttonWidth, height - pad - Scale(25), width - pad, height - pad});
    SetWindowLongPtrW(dialog, GWLP_USERDATA, reinterpret_cast<LONG_PTR>(&state));
    RunModal(dialog, button, state.done);
}

// the parts whose check boxes are ticked
uint32_t ChosenParts(HWND dialog) {
    uint32_t parts = 0;
    core::SetupLines all(pe_setup_parts());
    for (size_t i = 0; i < pe_setup_lines_count(all.get()); i++) {
        uint32_t flag = pe_setup_lines_get(all.get(), i)->part;
        if (Item(dialog, PartId(flag)) && Checked(dialog, PartId(flag))) {
            parts |= flag;
        }
    }
    return parts;
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

const std::initializer_list<int> kExportFields = {IDC_SETUP_PASSPHRASE, IDC_SETUP_PASSPHRASE_AGAIN};

// the window as what is chosen and typed allows: the passphrase fields with the check box, what the core says of the
// passphrase under them, Export only with a part and, when wanted, a passphrase the core takes
void UpdateExport(HWND dialog) {
    bool protect = Checked(dialog, IDC_SETUP_USE_PASSPHRASE);
    for (int id : kExportFields) {
        EnableWindow(Item(dialog, id), protect);
        // the label before the field
        EnableWindow(GetWindow(Item(dialog, id), GW_HWNDPREV), protect);
    }
    bool good = true;
    if (protect) {
        good = ShowPassphraseFeedback(dialog, IDC_SETUP_PASSPHRASE, IDC_SETUP_PASSPHRASE_AGAIN, IDC_SETUP_PROBLEM);
    } else {
        ShowWindow(Item(dialog, IDC_SETUP_PROBLEM), SW_HIDE);
        ShowWindow(GetWindow(Item(dialog, IDC_SETUP_PROBLEM), GW_HWNDPREV), SW_HIDE);
    }
    EnableWindow(Item(dialog, IDOK), ChosenParts(dialog) != 0 && good);
}

// Export: where to save asked, then the file written with what is chosen; the window stays when it could not be
void WriteExport(HWND dialog, ExportState& state) {
    core::SetupExport setup(pe_setup_export_new(ChosenParts(dialog)));
    HandPrefs(setup.get());
    std::wstring extension = Text(pe_setup_extension());
    std::wstring filter = FileFilter({{core::T(PE_TEXT_UI_SETUP_FILE_FILTER), L"*." + extension}});
    core::String name(pe_setup_default_name());
    std::wstring path = SaveFileDialog(dialog, Text(name.get()), state.title.c_str(), filter.c_str(), extension.c_str());
    if (path.empty()) {
        return;
    }
    if (Checked(dialog, IDC_SETUP_USE_PASSPHRASE)) {
        std::string passphrase = ReadSecret(Item(dialog, IDC_SETUP_PASSPHRASE));
        pe_setup_export_set_passphrase(setup.get(), passphrase.c_str());
        Wipe(passphrase);
    }
    std::string utf8 = core::Narrow(path);
    char* error = nullptr;
    core::SetupLines lines;
    RunWaiting(dialog, [&] { lines.reset(pe_setup_export_write(state.core, setup.get(), utf8.c_str(), &error)); });
    // the passphrase leaves memory with the export
    setup.reset();
    if (!lines) {
        MessageBoxApp(dialog, ReasonText(error, PE_TEXT_UI_UNKNOWN_REASON).c_str(), state.title.c_str(), MB_OK | MB_ICONWARNING);
        return;
    }
    core::String unused(error);
    state.path = path;
    state.lines = std::move(lines);
    state.done = true;
    WipeFields(dialog, kExportFields);
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
            WipeFields(hwnd, kExportFields);
            state->done = true;
        } else if (HIWORD(wParam) == EN_CHANGE || HIWORD(wParam) == BN_CLICKED) {
            UpdateExport(hwnd);
        }
        return 0;
    }
    case WM_CLOSE:
        WipeFields(hwnd, kExportFields);
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
    // the file's account of each account check box, and whether an import can add it
    std::vector<size_t> accounts;
    std::vector<bool> importable;
    uint32_t parts = 0;
    core::SetupLines lines;
    bool done = false;
};

// after the check box `id` was clicked: Accounts ticks or unticks every account an import can add, and is ticked while
// one of them is; Import only with a part or an account
void UpdateImport(HWND dialog, const ImportState& state, int id) {
    int accountsPart = PartId(PE_SETUP_ACCOUNTS);
    int count = static_cast<int>(state.accounts.size());
    bool any = false;
    for (int i = 0; i < count; i++) {
        if (state.importable[i] && id == accountsPart) {
            Check(dialog, IDC_SETUP_ACCOUNT + i, Checked(dialog, accountsPart));
        }
        any = any || (state.importable[i] && Checked(dialog, IDC_SETUP_ACCOUNT + i));
    }
    if (Item(dialog, accountsPart)) {
        Check(dialog, accountsPart, any);
    }
    EnableWindow(Item(dialog, IDOK), ChosenParts(dialog) != 0);
}

// Import: what is chosen imported, on a thread of its own (it reaches the sign-in services); the window stays when
// nothing could be
void RunImport(HWND dialog, ImportState& state) {
    // Accounts comes from the accounts named
    uint32_t parts = ChosenParts(dialog) & ~static_cast<uint32_t>(PE_SETUP_ACCOUNTS);
    std::vector<size_t> accounts;
    for (size_t i = 0; i < state.accounts.size(); i++) {
        if (state.importable[i] && Checked(dialog, IDC_SETUP_ACCOUNT + static_cast<int>(i))) {
            accounts.push_back(state.accounts[i]);
        }
    }
    char* error = nullptr;
    core::SetupLines lines;
    RunWaiting(dialog, [&] { lines.reset(pe_setup_import(state.core, state.file, parts, accounts.data(), accounts.size(), &error)); });
    if (!lines) {
        MessageBoxApp(dialog, ReasonText(error, PE_TEXT_UI_UNKNOWN_REASON).c_str(), state.title.c_str(), MB_OK | MB_ICONWARNING);
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

// the setup file at `path` read on a thread of its own (a sealed file's key takes a moment), its passphrase asked for
// while the core wants one; NULL when it could not be read (said) or the passphrase was not given
core::SetupFile ReadSetup(HWND owner, PeCore* core, const std::wstring& path, const std::wstring& title) {
    std::string utf8 = core::Narrow(path);
    std::string passphrase;
    bool asked = false;
    for (;;) {
        PeSetupError kind = PE_SETUP_ERROR_NONE;
        char* error = nullptr;
        core::SetupFile file;
        RunWaiting(owner, [&] { file.reset(pe_setup_read(core, utf8.c_str(), asked ? passphrase.c_str() : nullptr, &kind, &error)); });
        Wipe(passphrase);
        std::wstring said = ReasonText(error, PE_TEXT_UI_UNKNOWN_REASON);
        if (file) {
            return file;
        }
        if (kind != PE_SETUP_ERROR_NEEDS_PASSPHRASE && kind != PE_SETUP_ERROR_WRONG_PASSPHRASE) {
            MessageBoxApp(owner, said.c_str(), title.c_str(), MB_OK | MB_ICONWARNING);
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

// the rows of an account: its check box (ticked and on only when an import can add it), its servers, and what an
// import does with it
void AccountRows(std::vector<Row>& rows, const PeSetupAccount* account, int id, int left, int right) {
    int checkHeight = Scale(20), textLeft = left + GetSystemMetrics(SM_CXMENUCHECK) + Scale(4);
    std::wstring label = Text(account->label), servers = Text(account->servers), note = Text(account->note);
    bool importable = account->importable;
    rows.push_back({checkHeight, 0, [=](HWND dialog, int top) {
                        HWND box = CreateChild(dialog, L"BUTTON", label.c_str(), WS_TABSTOP | BS_AUTOCHECKBOX | (importable ? 0 : WS_DISABLED),
                                               id, {left, top, right, top + checkHeight});
                        SendMessageW(box, BM_SETCHECK, importable ? BST_CHECKED : BST_UNCHECKED, 0);
                        SetAccessibleDescription(box, servers + L". " + note);
                    }});
    int serversHeight = static_cast<int>(MeasureText(servers).cy);
    rows.push_back({serversHeight, 0, [=](HWND dialog, int top) {
                        CreateChild(dialog, L"STATIC", servers.c_str(), SS_LEFT | SS_NOPREFIX | SS_ENDELLIPSIS, 0,
                                    {textLeft, top, right, top + serversHeight});
                    }});
    int noteHeight = note.empty() ? 0 : Wrapped(note, right - textLeft);
    rows.push_back({noteHeight, Scale(8), [=](HWND dialog, int top) {
                        if (!note.empty()) {
                            Label(dialog, note, 0, textLeft, top, right, noteHeight);
                        }
                    }});
}

// the import window over the file read: what it holds to choose from; true with what was imported in `state`
bool ChooseImport(HWND owner, ImportState& state) {
    RegisterDialogClass(kImportClass, ImportProc);
    const PeSetupInfo* info = pe_setup_file_info(state.file);
    std::wstring intro = core::T(PE_TEXT_UI_SETUP_IMPORT_INTRO);
    std::wstring from = core::T(PE_TEXT_UI_SETUP_FROM, {{"version", Text(info->app_version)}, {"date", Text(info->created_text)}});
    int pad = Scale(12), width = Scale(500), checkHeight = Scale(20), indent = Scale(20);

    // the parts the file holds something in, their names a column before the core's words for what each holds
    std::vector<const PeSetupLine*> parts;
    int nameWidth = 0;
    for (size_t i = 0; i < pe_setup_file_part_count(state.file); i++) {
        const PeSetupLine* part = pe_setup_file_part(state.file, i);
        if (PartId(part->part)) {
            parts.push_back(part);
            nameWidth = std::max(nameWidth, CheckWidth(Text(part->name)) + Scale(12));
        }
    }
    nameWidth = std::min(nameWidth, (width - 2 * pad) / 2);
    int wordsWidth = width - 2 * pad - nameWidth;

    std::vector<Row> rows;
    int introHeight = Wrapped(intro, width - 2 * pad), fromHeight = Wrapped(from, width - 2 * pad);
    rows.push_back({introHeight, Scale(6), [=](HWND dialog, int top) { Label(dialog, intro, 0, pad, top, width - pad, introHeight); }});
    rows.push_back({fromHeight, Scale(12), [=](HWND dialog, int top) { Label(dialog, from, IDC_SETUP_FROM, pad, top, width - pad, fromHeight); }});
    for (const PeSetupLine* part : parts) {
        std::wstring name = Text(part->name), words = Text(part->text);
        int id = PartId(part->part);
        int height = std::max(checkHeight, Wrapped(words, wordsWidth) + Scale(3));
        rows.push_back({height, Scale(4), [=](HWND dialog, int top) {
                            HWND check = CreateChild(dialog, L"BUTTON", name.c_str(), WS_TABSTOP | BS_AUTOCHECKBOX, id,
                                                     {pad, top, pad + nameWidth - Scale(8), top + checkHeight});
                            SendMessageW(check, BM_SETCHECK, BST_CHECKED, 0);
                            SetAccessibleDescription(check, words);
                            Label(dialog, words, 0, pad + nameWidth, top + Scale(3), width - pad, height - Scale(3));
                        }});
        if (part->part != PE_SETUP_ACCOUNTS) {
            continue;
        }
        for (size_t i = 0; i < pe_setup_file_account_count(state.file); i++) {
            const PeSetupAccount* account = pe_setup_file_account(state.file, i);
            AccountRows(rows, account, IDC_SETUP_ACCOUNT + static_cast<int>(i), pad + indent, width - pad);
            state.accounts.push_back(account->index);
            state.importable.push_back(account->importable);
        }
    }
    // what the file holds that can not be used
    for (const std::wstring& note : Texts(core::TextList(pe_setup_file_notes(state.file)))) {
        int warning = GetSystemMetrics(SM_CXSMICON) + Scale(6);
        int height = std::max(GetSystemMetrics(SM_CYSMICON), Wrapped(note, width - 2 * pad - warning));
        rows.push_back({height, Scale(6), [=](HWND dialog, int top) { WarningNote(dialog, 0, note, pad, top, width - pad); }});
    }
    int height = pad + RowsHeight(rows) + Scale(10) + Scale(25) + pad;

    HWND dialog = CreateModalWindow(owner, kImportClass, state.title.c_str(), width, height);
    PlaceRows(dialog, rows, pad);
    BottomButtons(dialog, width, height - pad - Scale(25), core::T(PE_TEXT_UI_SETUP_IMPORT_BUTTON), core::T(PE_TEXT_UI_CANCEL));
    SetWindowLongPtrW(dialog, GWLP_USERDATA, reinterpret_cast<LONG_PTR>(&state));
    // with no account an import can add, Accounts is unticked and off; its accounts stay listed with why
    if (std::find(state.importable.begin(), state.importable.end(), true) == state.importable.end()) {
        EnableWindow(Item(dialog, PartId(PE_SETUP_ACCOUNTS)), FALSE);
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
    core::String longest(pe_passphrase_feedback_longest());
    std::wstring feedback = longest ? Text(longest.get()) : L"";
    int pad = Scale(12), width = Scale(460), checkHeight = Scale(20), field = Scale(22), indent = Scale(20);
    int labelWidth = LabelWidth({label, againLabel}, 90);
    int warning = GetSystemMetrics(SM_CXSMICON) + Scale(6);

    std::vector<Row> rows;
    int introHeight = Wrapped(intro, width - 2 * pad);
    rows.push_back({introHeight, Scale(10), [=](HWND dialog, int top) { Label(dialog, intro, 0, pad, top, width - pad, introHeight); }});
    // a check box for each part, all ticked
    core::SetupLines parts(pe_setup_parts());
    for (size_t i = 0; i < pe_setup_lines_count(parts.get()); i++) {
        const PeSetupLine* part = pe_setup_lines_get(parts.get(), i);
        std::wstring name = Text(part->name);
        int id = PartId(part->part);
        rows.push_back({checkHeight, 0, [=](HWND dialog, int top) {
                            CreateChild(dialog, L"BUTTON", name.c_str(), WS_TABSTOP | BS_AUTOCHECKBOX, id, {pad, top, width - pad, top + checkHeight});
                            Check(dialog, id, true);
                        }});
    }
    // a line between the parts and the passphrase, with room over it
    rows.push_back({Scale(12) + 2, Scale(10), [=](HWND dialog, int top) {
                        CreateChild(dialog, L"STATIC", L"", SS_ETCHEDHORZ, 0, {pad, top + Scale(12), width - pad, top + Scale(12) + 2});
                    }});
    rows.push_back({checkHeight, Scale(2), [=](HWND dialog, int top) {
                        CreateChild(dialog, L"BUTTON", protect.c_str(), WS_TABSTOP | BS_AUTOCHECKBOX, IDC_SETUP_USE_PASSPHRASE,
                                    {pad, top, width - pad, top + checkHeight});
                    }});
    int noteHeight = Wrapped(note, width - 2 * pad - indent);
    rows.push_back({noteHeight, Scale(8), [=](HWND dialog, int top) {
                        Label(dialog, note, IDC_SETUP_PASSPHRASE_NOTE, pad + indent, top, width - pad, noteHeight);
                    }});
    for (const auto& [text, id] : {std::pair{label, IDC_SETUP_PASSPHRASE}, std::pair{againLabel, IDC_SETUP_PASSPHRASE_AGAIN}}) {
        rows.push_back({field, Scale(6), [=, text = text, id = id](HWND dialog, int top) {
                            CreateChild(dialog, L"STATIC", text.c_str(), SS_LEFT, 0, {pad + indent, top + Scale(3), pad + indent + labelWidth, top + field});
                            CreateChild(dialog, L"EDIT", L"", WS_TABSTOP | ES_AUTOHSCROLL | ES_PASSWORD, id,
                                        {pad + indent + labelWidth, top, width - pad, top + field}, WS_EX_CLIENTEDGE);
                        }});
    }
    // room for the longest of what the core says of the passphrase, so the window keeps its size while typing
    int feedbackHeight = std::max(GetSystemMetrics(SM_CYSMICON), Wrapped(feedback, width - pad - (pad + indent + warning)));
    rows.push_back({feedbackHeight, Scale(14), [=](HWND dialog, int top) {
                        WarningNote(dialog, IDC_SETUP_PROBLEM, feedback, pad + indent, top, width - pad);
                    }});
    int height = pad + RowsHeight(rows) + Scale(25) + pad;
    HWND dialog = CreateModalWindow(owner, kExportClass, state.title.c_str(), width, height);
    PlaceRows(dialog, rows, pad);
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
    std::wstring extension = Text(pe_setup_extension());
    std::wstring filter = FileFilter({{core::T(PE_TEXT_UI_SETUP_FILE_FILTER), L"*." + extension}, {core::T(PE_TEXT_UI_FILTER_ALL), L"*.*"}});
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
            result.prefs.push_back({pref->name, pref->value, pref->restart});
        }
    }
    DoneDialog(owner, title, L"", state.lines.get());
    return result;
}
