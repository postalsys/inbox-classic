// DPI scaling, child controls, formatting and the modal form the dialogs are built from
#include "app.h"

#include <cderr.h>
#include <commdlg.h>
#include <shlobj.h>

#include <fstream>

namespace {

HWND g_scaleWindow = nullptr;
const wchar_t* kFormClass = L"PostalExpressForm";

struct FormState {
    std::vector<FormField>* fields;
    bool (*validate)(const std::vector<FormField>&, std::wstring&);
    std::vector<HWND> inputs;
    bool done = false;
    bool accepted = false;
};

std::wstring InputValue(const FormField& field, HWND input) {
    if (field.kind != FormField::Kind::Choice) {
        return GetWindowString(input);
    }
    LRESULT index = SendMessageW(input, CB_GETCURSEL, 0, 0);
    return index >= 0 && static_cast<size_t>(index) < field.choices.size() ? field.choices[index] : L"";
}

LRESULT CALLBACK FormProc(HWND hwnd, UINT message, WPARAM wParam, LPARAM lParam) {
    auto* state = reinterpret_cast<FormState*>(GetWindowLongPtrW(hwnd, GWLP_USERDATA));
    switch (message) {
    case WM_COMMAND:
        if (state && LOWORD(wParam) == IDCANCEL) {
            state->done = true;
            return 0;
        }
        if (state && LOWORD(wParam) == IDOK) {
            std::vector<FormField> values = *state->fields;
            for (size_t i = 0; i < values.size(); i++) {
                values[i].value = InputValue(values[i], state->inputs[i]);
                if (values[i].kind == FormField::Kind::Choice) {
                    values[i].chosen = static_cast<int>(SendMessageW(state->inputs[i], CB_GETCURSEL, 0, 0));
                }
            }
            std::wstring error;
            if (state->validate && !state->validate(values, error)) {
                MessageBoxW(hwnd, error.c_str(), L"PostalExpress", MB_OK | MB_ICONWARNING);
                return 0;
            }
            // moved, so no copy of a password is left behind
            *state->fields = std::move(values);
            state->accepted = true;
            state->done = true;
            return 0;
        }
        break;
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

void RegisterFormClass() {
    static bool registered = false;
    if (registered) {
        return;
    }
    WNDCLASSEXW windowClass = {sizeof(windowClass)};
    windowClass.lpfnWndProc = FormProc;
    windowClass.hInstance = GetModuleHandleW(nullptr);
    windowClass.hCursor = LoadCursorW(nullptr, IDC_ARROW);
    windowClass.hbrBackground = reinterpret_cast<HBRUSH>(COLOR_BTNFACE + 1);
    windowClass.lpszClassName = kFormClass;
    RegisterClassExW(&windowClass);
    registered = true;
}

HWND CreateInput(HWND dialog, const FormField& field, int id, const RECT& bounds) {
    if (field.kind == FormField::Kind::Choice) {
        RECT dropped = bounds;
        dropped.bottom += Scale(120);
        HWND combo = CreateChild(dialog, WC_COMBOBOXW, L"", WS_TABSTOP | WS_VSCROLL | CBS_DROPDOWNLIST, id, dropped);
        for (size_t i = 0; i < field.choices.size(); i++) {
            SendMessageW(combo, CB_ADDSTRING, 0, reinterpret_cast<LPARAM>(field.choices[i].c_str()));
            if (field.choices[i] == field.value) {
                SendMessageW(combo, CB_SETCURSEL, i, 0);
            }
        }
        return combo;
    }
    DWORD style = WS_TABSTOP | ES_AUTOHSCROLL;
    if (field.kind == FormField::Kind::Password) {
        style |= ES_PASSWORD;
    } else if (field.kind == FormField::Kind::Number) {
        style |= ES_NUMBER;
    }
    return CreateChild(dialog, L"EDIT", field.value.c_str(), style, id, bounds, WS_EX_CLIENTEDGE);
}

}  // namespace

void SetScaleWindow(HWND window) {
    g_scaleWindow = window;
}

int Scale(int value) {
    UINT dpi = g_scaleWindow ? GetDpiForWindow(g_scaleWindow) : 96;
    return MulDiv(value, static_cast<int>(dpi ? dpi : 96), 96);
}

HWND CreateChild(HWND parent, const wchar_t* className, const wchar_t* text, DWORD style, int id, const RECT& bounds,
                 DWORD exStyle) {
    HWND child = CreateWindowExW(exStyle, className, text, WS_CHILD | WS_VISIBLE | style, bounds.left, bounds.top,
                                 bounds.right - bounds.left, bounds.bottom - bounds.top, parent,
                                 reinterpret_cast<HMENU>(static_cast<INT_PTR>(id)), GetModuleHandleW(nullptr), nullptr);
    SendMessageW(child, WM_SETFONT, reinterpret_cast<WPARAM>(GetStockObject(DEFAULT_GUI_FONT)), FALSE);
    return child;
}

std::wstring GetWindowString(HWND window) {
    int length = GetWindowTextLengthW(window);
    std::wstring text(static_cast<size_t>(length) + 1, L'\0');
    GetWindowTextW(window, text.data(), length + 1);
    text.resize(static_cast<size_t>(length));
    return text;
}

std::wstring Text(const char* utf8) {
    return utf8 ? core::Widen(utf8) : std::wstring();
}

std::wstring FormatDate(int64_t seconds) {
    // the dates FILETIME holds, 1601 to 30827; a sender can write any date
    constexpr int64_t kFrom1601 = 11644473600LL;
    constexpr int64_t kLast = 910692730085LL;
    if (seconds < -kFrom1601 || seconds > kLast) {
        return {};
    }
    // seconds since 1970 to 100 ns intervals since 1601
    ULARGE_INTEGER ticks;
    ticks.QuadPart = static_cast<ULONGLONG>(seconds + kFrom1601) * 10000000ULL;
    FILETIME utc = {ticks.LowPart, ticks.HighPart};
    SYSTEMTIME universal;
    SYSTEMTIME local;
    if (!FileTimeToSystemTime(&utc, &universal) ||
        !SystemTimeToTzSpecificLocalTime(nullptr, &universal, &local)) {
        return {};
    }
    wchar_t date[64] = L"";
    wchar_t time[64] = L"";
    GetDateFormatEx(LOCALE_NAME_USER_DEFAULT, DATE_SHORTDATE, &local, nullptr, date, 64, nullptr);
    GetTimeFormatEx(LOCALE_NAME_USER_DEFAULT, TIME_NOSECONDS, &local, nullptr, time, 64);
    return std::wstring(date) + L" " + time;
}

std::wstring FormatSize(uint64_t bytes) {
    if (bytes < 1024) {
        return std::to_wstring(bytes) + L" bytes";
    }
    if (bytes < 1024 * 1024) {
        return std::to_wstring((bytes + 1023) / 1024) + L" KB";
    }
    wchar_t text[32];
    swprintf_s(text, L"%.1f MB", static_cast<double>(bytes) / (1024.0 * 1024.0));
    return text;
}

LRESULT ButtonFaceColor(HDC dc) {
    SetBkColor(dc, GetSysColor(COLOR_BTNFACE));
    return reinterpret_cast<LRESULT>(GetSysColorBrush(COLOR_BTNFACE));
}

bool FormDialog(HWND owner, const std::wstring& title, const std::wstring& intro, std::vector<FormField>& fields,
                bool (*validate)(const std::vector<FormField>&, std::wstring&), const wchar_t* okLabel) {
    RegisterFormClass();
    int pad = Scale(10);
    int labelWidth = Scale(130);
    int clientWidth = Scale(420);
    int rowHeight = Scale(22);
    int introHeight = intro.empty() ? 0 : Scale(36);
    int clientHeight = pad + introHeight + static_cast<int>(fields.size()) * (rowHeight + Scale(6)) + Scale(32) + pad;

    HWND dialog = CreateModalWindow(owner, kFormClass, title.c_str(), clientWidth, clientHeight);
    FormState state{&fields, validate};
    SetWindowLongPtrW(dialog, GWLP_USERDATA, reinterpret_cast<LONG_PTR>(&state));

    int top = pad;
    if (!intro.empty()) {
        CreateChild(dialog, L"STATIC", intro.c_str(), SS_LEFT | SS_NOPREFIX, 0, {pad, top, clientWidth - pad, top + introHeight});
        top += introHeight;
    }
    for (size_t i = 0; i < fields.size(); i++) {
        CreateChild(dialog, L"STATIC", fields[i].label.c_str(), SS_LEFT, 0,
                    {pad, top + Scale(3), pad + labelWidth, top + rowHeight});
        state.inputs.push_back(
            CreateInput(dialog, fields[i], 100 + static_cast<int>(i), {pad + labelWidth, top, clientWidth - pad, top + rowHeight}));
        top += rowHeight + Scale(6);
    }
    int buttonWidth = Scale(80);
    int buttonTop = clientHeight - pad - Scale(25);
    CreateChild(dialog, L"BUTTON", okLabel, WS_TABSTOP | BS_DEFPUSHBUTTON, IDOK,
                {clientWidth - pad - 2 * buttonWidth - Scale(6), buttonTop, clientWidth - pad - buttonWidth - Scale(6),
                 buttonTop + Scale(25)});
    CreateChild(dialog, L"BUTTON", L"Cancel", WS_TABSTOP, IDCANCEL,
                {clientWidth - pad - buttonWidth, buttonTop, clientWidth - pad, buttonTop + Scale(25)});

    RunModal(dialog, state.inputs.empty() ? nullptr : state.inputs[0], state.done);
    return state.accepted;
}

std::wstring SaveFileDialog(HWND owner, const std::wstring& name, const wchar_t* title, const wchar_t* filter,
                           const wchar_t* extension) {
    // the core made the name safe to save under; the user may still pick another
    wchar_t buffer[MAX_PATH] = L"";
    wcsncpy_s(buffer, name.c_str(), _TRUNCATE);
    OPENFILENAMEW dialog = {sizeof(dialog)};
    dialog.hwndOwner = owner;
    dialog.lpstrFilter = filter;
    dialog.lpstrFile = buffer;
    dialog.nMaxFile = MAX_PATH;
    dialog.lpstrTitle = title;
    // added to a name typed without an extension
    dialog.lpstrDefExt = extension;
    // Downloads the first time; after that Windows starts where the user saved last
    PWSTR downloads = nullptr;
    if (SUCCEEDED(SHGetKnownFolderPath(FOLDERID_Downloads, 0, nullptr, &downloads))) {
        dialog.lpstrInitialDir = downloads;
    }
    dialog.Flags = OFN_EXPLORER | OFN_OVERWRITEPROMPT | OFN_PATHMUSTEXIST | OFN_NOREADONLYRETURN | OFN_NOCHANGEDIR;
    std::wstring chosen = GetSaveFileNameW(&dialog) ? buffer : L"";
    CoTaskMemFree(downloads);
    return chosen;
}

bool WriteFileBytes(const std::wstring& path, const uint8_t* data, size_t size) {
    std::ofstream stream(path, std::ios::binary | std::ios::trunc);
    stream.write(reinterpret_cast<const char*>(data), static_cast<std::streamsize>(size));
    return stream.good();
}

void AddColumn(HWND list, int index, const wchar_t* name, int width, int format) {
    LVCOLUMNW column = {};
    column.mask = LVCF_TEXT | LVCF_WIDTH | LVCF_FMT;
    column.fmt = format;
    column.pszText = const_cast<wchar_t*>(name);
    column.cx = Scale(width);
    ListView_InsertColumn(list, index, &column);
}

// ---- toolbars ----

HWND CreateBar(HWND hwnd, DWORD style, int id) {
    HWND bar = CreateWindowExW(0, TOOLBARCLASSNAMEW, nullptr, WS_CHILD | WS_VISIBLE | TBSTYLE_FLAT | TBSTYLE_LIST | style, 0, 0, 0, 0,
                               hwnd, reinterpret_cast<HMENU>(static_cast<INT_PTR>(id)), GetModuleHandleW(nullptr), nullptr);
    SendMessageW(bar, TB_BUTTONSTRUCTSIZE, sizeof(TBBUTTON), 0);
    SendMessageW(bar, TB_SETEXTENDEDSTYLE, 0, TBSTYLE_EX_MIXEDBUTTONS);
    return bar;
}

void AddButton(HWND bar, int id, const wchar_t* text, BYTE style) {
    TBBUTTON button = {};
    button.idCommand = id;
    if (id == 0) {
        button.fsStyle = BTNS_SEP;
        SendMessageW(bar, TB_ADDBUTTONSW, 1, reinterpret_cast<LPARAM>(&button));
        return;
    }
    button.iBitmap = I_IMAGENONE;
    button.fsState = TBSTATE_ENABLED;
    button.fsStyle = static_cast<BYTE>(style | BTNS_AUTOSIZE | BTNS_SHOWTEXT);
    button.iString = reinterpret_cast<INT_PTR>(text);
    SendMessageW(bar, TB_ADDBUTTONSW, 1, reinterpret_cast<LPARAM>(&button));
}

// ---- modal windows ----

HWND CreateModalWindow(HWND owner, const wchar_t* className, const wchar_t* title, int clientWidth, int clientHeight) {
    RECT frame = {0, 0, clientWidth, clientHeight};
    DWORD style = WS_POPUP | WS_CAPTION | WS_SYSMENU | WS_CLIPCHILDREN;
    AdjustWindowRectEx(&frame, style, FALSE, WS_EX_DLGMODALFRAME);
    HWND root = GetAncestor(owner, GA_ROOT);
    RECT ownerRect;
    GetWindowRect(root, &ownerRect);
    int width = frame.right - frame.left;
    int height = frame.bottom - frame.top;
    int x = ownerRect.left + (ownerRect.right - ownerRect.left - width) / 2;
    int y = ownerRect.top + (ownerRect.bottom - ownerRect.top - height) / 2;
    return CreateWindowExW(WS_EX_DLGMODALFRAME | WS_EX_CONTROLPARENT, className, title, style, x, y, width, height, root, nullptr,
                           GetModuleHandleW(nullptr), nullptr);
}

void RunModal(HWND dialog, HWND focus, const bool& done) {
    HWND root = GetWindow(dialog, GW_OWNER);
    // a window opened while another one is open leaves its owner disabled when it closes
    bool wasEnabled = IsWindowEnabled(root);
    EnableWindow(root, FALSE);
    ShowWindow(dialog, SW_SHOW);
    if (focus) {
        SetFocus(focus);
    }
    MSG msg = {};
    while (!done && GetMessageW(&msg, nullptr, 0, 0) > 0) {
        if (!IsDialogMessageW(dialog, &msg)) {
            TranslateMessage(&msg);
            DispatchMessageW(&msg);
        }
    }
    if (msg.message == WM_QUIT) {
        // keep the quit for the main loop
        PostQuitMessage(static_cast<int>(msg.wParam));
    }
    EnableWindow(root, wasEnabled);
    SetWindowLongPtrW(dialog, GWLP_USERDATA, 0);
    DestroyWindow(dialog);
    if (wasEnabled) {
        SetActiveWindow(root);
    }
}

std::vector<std::wstring> OpenFilesDialog(HWND owner, const wchar_t* title, const wchar_t* filter) {
    std::vector<wchar_t> buffer(65536, L'\0');
    OPENFILENAMEW dialog = {sizeof(dialog)};
    dialog.hwndOwner = owner;
    dialog.lpstrFilter = filter;
    dialog.lpstrFile = buffer.data();
    dialog.nMaxFile = static_cast<DWORD>(buffer.size());
    dialog.lpstrTitle = title;
    dialog.Flags = OFN_EXPLORER | OFN_FILEMUSTEXIST | OFN_ALLOWMULTISELECT | OFN_NOCHANGEDIR;
    if (!GetOpenFileNameW(&dialog)) {
        if (CommDlgExtendedError() == FNERR_BUFFERTOOSMALL) {
            MessageBoxW(owner, L"Too many files at once: choose fewer.", title, MB_OK | MB_ICONWARNING);
        }
        return {};
    }
    // one file is a full path, several are the directory followed by the names
    std::vector<std::wstring> parts;
    for (const wchar_t* part = buffer.data(); *part; part += wcslen(part) + 1) {
        parts.push_back(part);
    }
    if (parts.size() == 1) {
        return parts;
    }
    std::vector<std::wstring> files;
    for (size_t i = 1; i < parts.size(); i++) {
        files.push_back(parts[0] + L"\\" + parts[i]);
    }
    return files;
}
