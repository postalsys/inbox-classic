// DPI scaling, child controls, formatting and the modal form the dialogs are built from
#include "app.h"
#include "icons.h"

#include <cderr.h>
#include <commdlg.h>
#include <oleacc.h>
#include <shlobj.h>
#include <shobjidl.h>
#include <wincodec.h>
#include <wrl/client.h>

#include <algorithm>
#include <fstream>
#include <span>

namespace {

HWND g_scaleWindow = nullptr;
const wchar_t* kFormClass = L"InboxClassicForm";

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
                MessageBoxW(hwnd, error.c_str(), L"Inbox Classic", MB_OK | MB_ICONWARNING);
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

void RegisterDialogClass(const wchar_t* name, WNDPROC proc) {
    WNDCLASSEXW windowClass = {sizeof(windowClass)};
    if (GetClassInfoExW(GetModuleHandleW(nullptr), name, &windowClass)) {
        return;
    }
    windowClass = {sizeof(windowClass)};
    windowClass.lpfnWndProc = proc;
    windowClass.hInstance = GetModuleHandleW(nullptr);
    windowClass.hCursor = LoadCursorW(nullptr, IDC_ARROW);
    windowClass.hbrBackground = reinterpret_cast<HBRUSH>(COLOR_BTNFACE + 1);
    windowClass.lpszClassName = name;
    RegisterClassExW(&windowClass);
}

namespace {
// `text` without its menu letter marks, measured in `font` (the dialog font when null), wrapped at `wrapWidth` if set
SIZE Measure(HDC dc, HFONT font, const std::wstring& text, int wrapWidth = 0) {
    std::wstring plain = text;
    plain.erase(std::remove(plain.begin(), plain.end(), L'&'), plain.end());
    HGDIOBJ old = SelectObject(dc, font ? font : GetStockObject(DEFAULT_GUI_FONT));
    RECT bounds = {0, 0, wrapWidth > 0 ? wrapWidth : 0, 0};
    DrawTextW(dc, plain.c_str(), static_cast<int>(plain.size()), &bounds,
              DT_CALCRECT | DT_NOPREFIX | (wrapWidth > 0 ? DT_WORDBREAK : DT_SINGLELINE));
    SelectObject(dc, old);
    return {bounds.right - bounds.left, bounds.bottom - bounds.top};
}

// the widest of `labels` plus `margin`, at least `least`, measured in one screen DC
template <typename Labels>
int Widest(const Labels& labels, int least, int margin) {
    HDC dc = GetDC(nullptr);
    int width = Scale(least);
    for (const std::wstring& label : labels) {
        width = std::max(width, static_cast<int>(Measure(dc, nullptr, label).cx) + Scale(margin));
    }
    ReleaseDC(nullptr, dc);
    return width;
}
}  // namespace

int TextWidth(HWND control, HFONT font) {
    HDC dc = GetDC(control);
    int width = static_cast<int>(Measure(dc, font, GetWindowString(control)).cx);
    ReleaseDC(control, dc);
    return width;
}

SIZE MeasureText(const std::wstring& text, int wrapWidth) {
    HDC dc = GetDC(nullptr);
    SIZE size = Measure(dc, nullptr, text, wrapWidth);
    ReleaseDC(nullptr, dc);
    return size;
}

int ButtonWidth(std::initializer_list<std::wstring> labels, int least) {
    return Widest(labels, least, 20);
}

int ButtonWidth(const std::vector<std::wstring>& labels, int least) {
    return Widest(labels, least, 20);
}

int LabelWidth(std::initializer_list<std::wstring> labels, int least, int margin) {
    return Widest(labels, least, margin);
}

int LabelWidth(const std::vector<std::wstring>& labels, int least, int margin) {
    return Widest(labels, least, margin);
}

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

bool UnixToSystemTime(int64_t seconds, bool local, SYSTEMTIME& time) {
    // the dates FILETIME holds, 1601 to 30827; a sender can write any date
    constexpr int64_t kFrom1601 = 11644473600LL;
    constexpr int64_t kLast = 910692730085LL;
    if (seconds < -kFrom1601 || seconds > kLast) {
        return false;
    }
    // seconds since 1970 to 100 ns intervals since 1601
    ULARGE_INTEGER ticks;
    ticks.QuadPart = static_cast<ULONGLONG>(seconds + kFrom1601) * 10000000ULL;
    FILETIME utc = {ticks.LowPart, ticks.HighPart};
    SYSTEMTIME universal;
    if (!FileTimeToSystemTime(&utc, &universal)) {
        return false;
    }
    if (!local) {
        time = universal;
        return true;
    }
    return SystemTimeToTzSpecificLocalTime(nullptr, &universal, &time) != FALSE;
}

std::wstring FormatDate(int64_t seconds) {
    SYSTEMTIME local;
    if (!UnixToSystemTime(seconds, true, local)) {
        return {};
    }
    wchar_t date[64] = L"";
    GetDateFormatEx(LOCALE_NAME_USER_DEFAULT, DATE_SHORTDATE, &local, nullptr, date, 64, nullptr);
    return std::wstring(date) + L" " + FormatTime(local);
}

std::wstring FormatTime(const SYSTEMTIME& local) {
    wchar_t time[64] = L"";
    GetTimeFormatEx(LOCALE_NAME_USER_DEFAULT, TIME_NOSECONDS, &local, nullptr, time, 64);
    return time;
}

std::wstring TimeNow() {
    SYSTEMTIME now;
    GetLocalTime(&now);
    return FormatTime(now);
}

bool CopyText(HWND owner, const std::wstring& text) {
    if (!OpenClipboard(owner)) {
        return false;
    }
    EmptyClipboard();
    size_t bytes = (text.size() + 1) * sizeof(wchar_t);
    HGLOBAL memory = GlobalAlloc(GMEM_MOVEABLE, bytes);
    bool done = false;
    if (memory) {
        if (void* to = GlobalLock(memory)) {
            memcpy(to, text.c_str(), bytes);
            GlobalUnlock(memory);
            // the clipboard owns the memory once it took it
            done = SetClipboardData(CF_UNICODETEXT, memory) != nullptr;
        }
        if (!done) {
            GlobalFree(memory);
        }
    }
    CloseClipboard();
    return done;
}

std::wstring FormatSize(uint64_t bytes) {
    // the same words on every platform: the core makes them
    core::String text(pe_format_size(bytes));
    return Text(text.get());
}

LRESULT ButtonFaceColor(HDC dc) {
    SetBkColor(dc, GetSysColor(COLOR_BTNFACE));
    return reinterpret_cast<LRESULT>(GetSysColorBrush(COLOR_BTNFACE));
}

void DrawLinkButton(const DRAWITEMSTRUCT& item) {
    FillRect(item.hDC, &item.rcItem, GetSysColorBrush(COLOR_BTNFACE));
    // the dialog font, underlined; made once for the font the button has
    static HFONT base = nullptr, underlined = nullptr;
    auto font = reinterpret_cast<HFONT>(SendMessageW(item.hwndItem, WM_GETFONT, 0, 0));
    if (font != base || !underlined) {
        LOGFONTW logFont = {};
        GetObjectW(font ? font : GetStockObject(DEFAULT_GUI_FONT), sizeof(logFont), &logFont);
        logFont.lfUnderline = TRUE;
        if (underlined) {
            DeleteObject(underlined);
        }
        underlined = CreateFontIndirectW(&logFont);
        base = font;
    }
    std::wstring text = GetWindowString(item.hwndItem);
    HGDIOBJ old = SelectObject(item.hDC, underlined);
    SetBkMode(item.hDC, TRANSPARENT);
    SetTextColor(item.hDC, GetSysColor((item.itemState & ODS_DISABLED) ? COLOR_GRAYTEXT : COLOR_HOTLIGHT));
    RECT area = item.rcItem;
    DrawTextW(item.hDC, text.c_str(), -1, &area, DT_LEFT | DT_VCENTER | DT_SINGLELINE | DT_NOPREFIX);
    if ((item.itemState & ODS_FOCUS) && !(item.itemState & ODS_NOFOCUSRECT)) {
        RECT measured = item.rcItem;
        DrawTextW(item.hDC, text.c_str(), -1, &measured, DT_LEFT | DT_SINGLELINE | DT_NOPREFIX | DT_CALCRECT);
        measured.top = item.rcItem.top;
        measured.bottom = item.rcItem.bottom;
        DrawFocusRect(item.hDC, &measured);
    }
    SelectObject(item.hDC, old);
}

bool SetLinkCursor(HWND hwnd, WPARAM wParam) {
    auto target = reinterpret_cast<HWND>(wParam);
    if (target == hwnd || !IsWindowEnabled(target) || !GetPropW(target, L"InboxClassicLink")) {
        return false;
    }
    SetCursor(LoadCursorW(nullptr, IDC_HAND));
    return true;
}

HWND CreateLinkButton(HWND parent, const wchar_t* text, int id, const RECT& bounds) {
    HWND link = CreateChild(parent, L"BUTTON", text, WS_TABSTOP | BS_OWNERDRAW, id, bounds);
    SetPropW(link, L"InboxClassicLink", reinterpret_cast<HANDLE>(1));
    return link;
}

namespace {

LRESULT CALLBACK KeyboardLinkProc(HWND hwnd, UINT message, WPARAM wParam, LPARAM lParam, UINT_PTR, DWORD_PTR) {
    switch (message) {
    case WM_GETDLGCODE: {
        // Enter is the label's, not the window's default button
        const auto* msg = reinterpret_cast<const MSG*>(lParam);
        if (msg && msg->message == WM_KEYDOWN && msg->wParam == VK_RETURN) {
            return DefSubclassProc(hwnd, message, wParam, lParam) | DLGC_WANTMESSAGE;
        }
        break;
    }
    case WM_KEYDOWN:
        if (wParam == VK_RETURN || wParam == VK_SPACE) {
            SendMessageW(GetParent(hwnd), WM_COMMAND, MAKEWPARAM(GetDlgCtrlID(hwnd), STN_CLICKED), reinterpret_cast<LPARAM>(hwnd));
            return 0;
        }
        break;
    case WM_SETFOCUS:
    case WM_KILLFOCUS:
        InvalidateRect(hwnd, nullptr, TRUE);
        break;
    case WM_PAINT: {
        LRESULT result = DefSubclassProc(hwnd, message, wParam, lParam);
        if (GetFocus() == hwnd) {
            HDC dc = GetDC(hwnd);
            RECT area;
            GetClientRect(hwnd, &area);
            InflateRect(&area, -1, -1);
            DrawFocusRect(dc, &area);
            ReleaseDC(hwnd, dc);
        }
        return result;
    }
    case WM_NCDESTROY:
        RemoveWindowSubclass(hwnd, KeyboardLinkProc, 0);
        break;
    }
    return DefSubclassProc(hwnd, message, wParam, lParam);
}

}  // namespace

void KeyboardLink(HWND label) {
    SetWindowLongPtrW(label, GWL_STYLE, GetWindowLongPtrW(label, GWL_STYLE) | WS_TABSTOP);
    SetWindowSubclass(label, KeyboardLinkProc, 0, 0);
}

void SetAccessibleDescription(HWND control, const std::wstring& text) {
    // PROPID_ACC_DESCRIPTION of oleacc.h, which only declares it
    constexpr GUID kDescription = {0x4d48dfe4, 0xbd3f, 0x491f, {0xa6, 0x48, 0x49, 0x2d, 0x6f, 0x20, 0xc5, 0x88}};
    Microsoft::WRL::ComPtr<IAccPropServices> services;
    if (SUCCEEDED(CoCreateInstance(__uuidof(CAccPropServices), nullptr, CLSCTX_INPROC_SERVER, IID_PPV_ARGS(&services)))) {
        services->SetHwndPropStr(control, static_cast<DWORD>(OBJID_CLIENT), CHILDID_SELF, kDescription, text.c_str());
    }
}

bool FormDialog(HWND owner, const std::wstring& title, const std::wstring& intro, std::vector<FormField>& fields,
                bool (*validate)(const std::vector<FormField>&, std::wstring&), const wchar_t* okLabel, size_t focus) {
    RegisterDialogClass(kFormClass, FormProc);
    std::wstring ok = okLabel ? okLabel : core::T(PE_TEXT_UI_OK);
    std::wstring cancel = core::T(PE_TEXT_UI_CANCEL);
    int pad = Scale(10);
    // the label column as wide as the longest label, the inputs keep at least their usual width
    int labelWidth = Scale(130);
    for (const FormField& field : fields) {
        labelWidth = std::max(labelWidth, static_cast<int>(MeasureText(field.label).cx) + Scale(8));
    }
    int buttonWidth = ButtonWidth({ok, cancel});
    int clientWidth = std::max({Scale(420), pad + labelWidth + Scale(280) + pad, pad + 2 * buttonWidth + Scale(6) + pad});
    int rowHeight = Scale(22);
    int introHeight = 0;
    if (!intro.empty()) {
        introHeight = std::max(Scale(36), static_cast<int>(MeasureText(intro, clientWidth - 2 * pad).cy) + Scale(8));
    }
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
    int buttonTop = clientHeight - pad - Scale(25);
    CreateChild(dialog, L"BUTTON", ok.c_str(), WS_TABSTOP | BS_DEFPUSHBUTTON, IDOK,
                {clientWidth - pad - 2 * buttonWidth - Scale(6), buttonTop, clientWidth - pad - buttonWidth - Scale(6),
                 buttonTop + Scale(25)});
    CreateChild(dialog, L"BUTTON", cancel.c_str(), WS_TABSTOP, IDCANCEL,
                {clientWidth - pad - buttonWidth, buttonTop, clientWidth - pad, buttonTop + Scale(25)});

    RunModal(dialog, focus < state.inputs.size() ? state.inputs[focus] : nullptr, state.done);
    return state.accepted;
}

std::wstring FileFilter(std::initializer_list<std::pair<std::wstring, std::wstring>> kinds) {
    std::wstring filter;
    for (const auto& [name, patterns] : kinds) {
        filter += name + L" (" + patterns + L")" + L'\0' + patterns + L'\0';
    }
    // the string's own terminator ends the list
    return filter;
}

std::wstring SaveFileDialog(HWND owner, const std::wstring& name, const wchar_t* title, const wchar_t* filter,
                           const wchar_t* extension) {
    // the core made the name safe to save under; the user may still pick another
    wchar_t buffer[MAX_PATH] = L"";
    wcsncpy_s(buffer, name.c_str(), _TRUNCATE);
    OPENFILENAMEW dialog = {sizeof(dialog)};
    std::wstring allFiles = FileFilter({{core::T(PE_TEXT_UI_FILTER_ALL), L"*.*"}});
    std::wstring attachment = core::Plain(PE_TEXT_UI_SAVE_ATTACHMENT_AS);
    dialog.hwndOwner = owner;
    dialog.lpstrFilter = filter ? filter : allFiles.c_str();
    dialog.lpstrFile = buffer;
    dialog.nMaxFile = MAX_PATH;
    dialog.lpstrTitle = title ? title : attachment.c_str();
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

namespace {

const wchar_t* kTextClass = L"InboxClassicText";

LRESULT CALLBACK TextProc(HWND hwnd, UINT message, WPARAM wParam, LPARAM lParam) {
    auto* done = reinterpret_cast<bool*>(GetWindowLongPtrW(hwnd, GWLP_USERDATA));
    if (done && ((message == WM_COMMAND && (LOWORD(wParam) == IDOK || LOWORD(wParam) == IDCANCEL)) || message == WM_CLOSE)) {
        *done = true;
        return 0;
    }
    if (message == WM_CTLCOLORSTATIC) {
        return ButtonFaceColor(reinterpret_cast<HDC>(wParam));
    }
    return DefWindowProcW(hwnd, message, wParam, lParam);
}

}  // namespace

namespace {

const wchar_t* kSourceClass = L"InboxClassicSource";

struct SourceState {
    bool done = false;
    HWND box = nullptr;
    HWND close = nullptr;
    HWND save = nullptr;
    HFONT font = nullptr;
    const std::function<void(HWND)>* saveAs = nullptr;
};

// the text fills the window, Close stays in its corner
void LayoutSource(HWND hwnd, const SourceState& state) {
    RECT client;
    GetClientRect(hwnd, &client);
    int pad = Scale(10);
    int buttonHeight = Scale(25);
    MoveWindow(state.box, pad, pad, client.right - 2 * pad, client.bottom - 3 * pad - buttonHeight, TRUE);
    int buttonTop = client.bottom - pad - buttonHeight;
    int closeWidth = ButtonWidth({GetWindowString(state.close)});
    MoveWindow(state.close, client.right - pad - closeWidth, buttonTop, closeWidth, buttonHeight, TRUE);
    // a button that does not close the window on the other side
    MoveWindow(state.save, pad, buttonTop, ButtonWidth({GetWindowString(state.save)}, 90), buttonHeight, TRUE);
}

LRESULT CALLBACK SourceProc(HWND hwnd, UINT message, WPARAM wParam, LPARAM lParam) {
    auto* state = reinterpret_cast<SourceState*>(GetWindowLongPtrW(hwnd, GWLP_USERDATA));
    if (!state) {
        return DefWindowProcW(hwnd, message, wParam, lParam);
    }
    switch (message) {
    case WM_COMMAND:
        if (LOWORD(wParam) == IDOK || LOWORD(wParam) == IDCANCEL) {
            state->done = true;
        } else if (LOWORD(wParam) == IDM_SAVE_AS) {
            (*state->saveAs)(hwnd);
        }
        return 0;
    case WM_CLOSE:
        state->done = true;
        return 0;
    case WM_SIZE:
        LayoutSource(hwnd, *state);
        return 0;
    case WM_GETMINMAXINFO: {
        auto* limits = reinterpret_cast<MINMAXINFO*>(lParam);
        limits->ptMinTrackSize = {Scale(360), Scale(240)};
        return 0;
    }
    case WM_CTLCOLORSTATIC:
        // the read-only box white, as a document is
        SetBkColor(reinterpret_cast<HDC>(wParam), GetSysColor(COLOR_WINDOW));
        return reinterpret_cast<LRESULT>(GetSysColorBrush(COLOR_WINDOW));
    }
    return DefWindowProcW(hwnd, message, wParam, lParam);
}

}  // namespace

std::wstring WithCrlf(const std::wstring& text) {
    std::wstring shown;
    shown.reserve(text.size() + text.size() / 32);
    for (wchar_t c : text) {
        if (c == L'\n' && (shown.empty() || shown.back() != L'\r')) {
            shown += L'\r';
        }
        shown += c;
    }
    return shown;
}

void SourceDialog(HWND owner, const std::wstring& title, const std::wstring& text, const std::function<void(HWND)>& save) {
    RegisterDialogClass(kSourceClass, SourceProc);
    HWND dialog = CreateModalWindow(owner, kSourceClass, title.c_str(), Scale(760), Scale(560));
    // a window to read a long text in: it can be made larger
    SetWindowLongPtrW(dialog, GWL_STYLE, GetWindowLongPtrW(dialog, GWL_STYLE) | WS_THICKFRAME | WS_MAXIMIZEBOX);
    SetWindowPos(dialog, nullptr, 0, 0, 0, 0, SWP_NOMOVE | SWP_NOSIZE | SWP_NOZORDER | SWP_FRAMECHANGED);
    SourceState state;
    state.saveAs = &save;
    SetWindowLongPtrW(dialog, GWLP_USERDATA, reinterpret_cast<LONG_PTR>(&state));
    state.box = CreateChild(dialog, L"EDIT", L"",
                            WS_TABSTOP | WS_VSCROLL | WS_HSCROLL | ES_MULTILINE | ES_READONLY | ES_AUTOVSCROLL | ES_AUTOHSCROLL, 0, {},
                            WS_EX_CLIENTEDGE);
    // the whole message fits: the box takes more than its usual 32K characters
    SendMessageW(state.box, EM_SETLIMITTEXT, 0, 0);
    state.font = CreateFontW(-Scale(13), 0, 0, 0, FW_NORMAL, FALSE, FALSE, FALSE, DEFAULT_CHARSET, OUT_DEFAULT_PRECIS, CLIP_DEFAULT_PRECIS,
                             CLEARTYPE_QUALITY, FIXED_PITCH | FF_MODERN, L"Consolas");
    SendMessageW(state.box, WM_SETFONT, reinterpret_cast<WPARAM>(state.font), FALSE);
    SetWindowTextW(state.box, text.c_str());
    state.save = CreateChild(dialog, L"BUTTON", core::T(PE_TEXT_WIN_SAVE_AS_BUTTON).c_str(), WS_TABSTOP, IDM_SAVE_AS, {});
    state.close = CreateChild(dialog, L"BUTTON", core::T(PE_TEXT_UI_CLOSE).c_str(), WS_TABSTOP | BS_DEFPUSHBUTTON, IDOK, {});
    LayoutSource(dialog, state);
    RunModal(dialog, state.box, state.done);
    DeleteObject(state.font);
}

void TextDialog(HWND owner, const std::wstring& title, const std::wstring& intro, const std::wstring& text) {
    RegisterDialogClass(kTextClass, TextProc);
    int pad = Scale(10);
    int width = Scale(520);
    int height = Scale(420);
    HWND dialog = CreateModalWindow(owner, kTextClass, title.c_str(), width, height);
    bool done = false;
    SetWindowLongPtrW(dialog, GWLP_USERDATA, reinterpret_cast<LONG_PTR>(&done));
    CreateChild(dialog, L"STATIC", intro.c_str(), SS_LEFT | SS_NOPREFIX, 0, {pad, pad, width - pad, pad + Scale(18)});
    HWND box = CreateChild(dialog, L"EDIT", text.c_str(),
                           WS_TABSTOP | WS_VSCROLL | WS_HSCROLL | ES_MULTILINE | ES_READONLY | ES_AUTOVSCROLL | ES_AUTOHSCROLL, 0,
                           {pad, pad + Scale(22), width - pad, height - pad - Scale(35)}, WS_EX_CLIENTEDGE);
    std::wstring ok = core::T(PE_TEXT_UI_OK);
    CreateChild(dialog, L"BUTTON", ok.c_str(), WS_TABSTOP | BS_DEFPUSHBUTTON, IDOK,
                {width - pad - ButtonWidth({ok}), height - pad - Scale(25), width - pad, height - pad});
    RunModal(dialog, box, done);
}

std::wstring FolderDialog(HWND owner, const wchar_t* title) {
    Microsoft::WRL::ComPtr<IFileOpenDialog> dialog;
    if (FAILED(CoCreateInstance(CLSID_FileOpenDialog, nullptr, CLSCTX_INPROC_SERVER, IID_PPV_ARGS(&dialog)))) {
        return L"";
    }
    FILEOPENDIALOGOPTIONS options = 0;
    dialog->GetOptions(&options);
    dialog->SetOptions(options | FOS_PICKFOLDERS | FOS_FORCEFILESYSTEM | FOS_PATHMUSTEXIST);
    dialog->SetTitle(title);
    // Downloads the first time, as the Save dialogs; after that Windows starts where the user picked last
    Microsoft::WRL::ComPtr<IShellItem> downloads;
    if (SUCCEEDED(SHGetKnownFolderItem(FOLDERID_Downloads, KF_FLAG_DEFAULT, nullptr, IID_PPV_ARGS(&downloads)))) {
        dialog->SetDefaultFolder(downloads.Get());
    }
    Microsoft::WRL::ComPtr<IShellItem> chosen;
    PWSTR path = nullptr;
    if (FAILED(dialog->Show(owner)) || FAILED(dialog->GetResult(&chosen)) || FAILED(chosen->GetDisplayName(SIGDN_FILESYSPATH, &path))) {
        return L"";
    }
    std::wstring folder = path;
    CoTaskMemFree(path);
    return folder;
}

namespace {

// the first frame of a PNG resource, decoded by WIC
Microsoft::WRL::ComPtr<IWICBitmapFrameDecode> PictureFrame(IWICImagingFactory* factory, int resource) {
    HMODULE module = GetModuleHandleW(nullptr);
    HRSRC found = FindResourceW(module, MAKEINTRESOURCEW(resource), MAKEINTRESOURCEW(10));  // RT_RCDATA
    HGLOBAL loaded = found ? LoadResource(module, found) : nullptr;
    auto* data = static_cast<BYTE*>(loaded ? LockResource(loaded) : nullptr);
    Microsoft::WRL::ComPtr<IWICStream> stream;
    Microsoft::WRL::ComPtr<IWICBitmapDecoder> decoder;
    Microsoft::WRL::ComPtr<IWICBitmapFrameDecode> frame;
    if (!data || FAILED(factory->CreateStream(&stream)) ||
        FAILED(stream->InitializeFromMemory(data, SizeofResource(module, found))) ||
        FAILED(factory->CreateDecoderFromStream(stream.Get(), nullptr, WICDecodeMetadataCacheOnLoad, &decoder)) ||
        FAILED(decoder->GetFrame(0, &frame))) {
        return nullptr;
    }
    return frame;
}

}  // namespace

HBITMAP LoadPicture(int resource, int height, COLORREF background, int& width) {
    Microsoft::WRL::ComPtr<IWICImagingFactory> factory;
    CoCreateInstance(CLSID_WICImagingFactory, nullptr, CLSCTX_INPROC_SERVER, IID_PPV_ARGS(&factory));
    auto frame = factory ? PictureFrame(factory.Get(), resource) : nullptr;
    UINT naturalWidth = 0, naturalHeight = 0;
    if (!frame || FAILED(frame->GetSize(&naturalWidth, &naturalHeight)) || !naturalHeight || height <= 0) {
        return nullptr;
    }
    width = MulDiv(height, static_cast<int>(naturalWidth), static_cast<int>(naturalHeight));
    Microsoft::WRL::ComPtr<IWICBitmapScaler> scaler;
    Microsoft::WRL::ComPtr<IWICFormatConverter> converter;
    if (FAILED(factory->CreateBitmapScaler(&scaler)) ||
        FAILED(scaler->Initialize(frame.Get(), width, height, WICBitmapInterpolationModeHighQualityCubic)) ||
        FAILED(factory->CreateFormatConverter(&converter)) ||
        FAILED(converter->Initialize(scaler.Get(), GUID_WICPixelFormat32bppPBGRA, WICBitmapDitherTypeNone, nullptr, 0,
                                     WICBitmapPaletteTypeCustom))) {
        return nullptr;
    }
    BITMAPINFO info = {};
    info.bmiHeader = {sizeof(BITMAPINFOHEADER), width, -height, 1, 32, BI_RGB};
    void* bits = nullptr;
    HBITMAP bitmap = CreateDIBSection(nullptr, &info, DIB_RGB_COLORS, &bits, nullptr, 0);
    UINT stride = static_cast<UINT>(width) * 4;
    if (!bitmap || FAILED(converter->CopyPixels(nullptr, stride, stride * static_cast<UINT>(height), static_cast<BYTE*>(bits)))) {
        if (bitmap) {
            DeleteObject(bitmap);
        }
        return nullptr;
    }
    // laid over the background: premultiplied, so each channel gets the background's share the picture leaves
    const BYTE under[3] = {GetBValue(background), GetGValue(background), GetRValue(background)};
    auto* pixel = static_cast<BYTE*>(bits);
    for (int i = 0; i < width * height; i++, pixel += 4) {
        for (int channel = 0; channel < 3; channel++) {
            pixel[channel] = static_cast<BYTE>(pixel[channel] + under[channel] * (255 - pixel[3]) / 255);
        }
        pixel[3] = 255;
    }
    return bitmap;
}

HICON AppIcon(bool titleBar) {
    int size = GetSystemMetricsForDpi(titleBar ? SM_CXSMICON : SM_CXICON, GetDpiForSystem());
    return static_cast<HICON>(LoadImageW(GetModuleHandleW(nullptr), MAKEINTRESOURCEW(100), IMAGE_ICON, size, size, LR_SHARED));
}

namespace {
// the installer's own key, which the uninstaller removes
const wchar_t* kPreferencesKey = L"Software\\Postal Systems\\InboxClassic";
}

DWORD GetPreference(const wchar_t* name, DWORD fallback) {
    DWORD value = 0, size = sizeof(value);
    if (RegGetValueW(HKEY_CURRENT_USER, kPreferencesKey, name, RRF_RT_REG_DWORD, nullptr, &value, &size) != ERROR_SUCCESS) {
        return fallback;
    }
    return value;
}

void SetPreference(const wchar_t* name, DWORD value) {
    RegSetKeyValueW(HKEY_CURRENT_USER, kPreferencesKey, name, REG_DWORD, &value, sizeof(value));
}

std::wstring GetTextPreference(const wchar_t* name) {
    // a short code: a value longer than this is not one the app wrote
    wchar_t value[64] = L"";
    DWORD size = sizeof(value);
    if (RegGetValueW(HKEY_CURRENT_USER, kPreferencesKey, name, RRF_RT_REG_SZ, nullptr, value, &size) != ERROR_SUCCESS) {
        return L"";
    }
    return value;
}

void SetTextPreference(const wchar_t* name, const std::wstring& value) {
    RegSetKeyValueW(HKEY_CURRENT_USER, kPreferencesKey, name, REG_SZ, value.c_str(),
                    static_cast<DWORD>((value.size() + 1) * sizeof(wchar_t)));
}

void SetAppIcons(WNDCLASSEXW& windowClass) {
    windowClass.hIcon = AppIcon(false);
    windowClass.hIconSm = AppIcon(true);
}

void MarkFromInternet(const std::wstring& path) {
    // the Mark of the Web (zone 3) in the file's NTFS stream, as the core puts on what Save Attachments writes:
    // opened later, the file gets SmartScreen and Office's Protected View
    std::ofstream stream(path + L":Zone.Identifier", std::ios::binary | std::ios::trunc);
    stream << "[ZoneTransfer]\r\nZoneId=3\r\n";
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

void SetColumnTitle(HWND list, int index, const std::wstring& title) {
    LVCOLUMNW column = {};
    column.mask = LVCF_TEXT;
    column.pszText = const_cast<wchar_t*>(title.c_str());
    ListView_SetColumn(list, index, &column);
}

// ---- toolbars ----

HIMAGELIST IconList(IconSet set) {
    std::span<const IconStrip> strips = set == IconSet::Toolbar ? std::span<const IconStrip>(kToolbarStrips)
                                         : set == IconSet::Format ? std::span<const IconStrip>(kFormatStrips)
                                         : set == IconSet::Folders ? std::span<const IconStrip>(kFolderStrips)
                                                                   : std::span<const IconStrip>(kListStrips);
    // the strip closest to the DPI, at least as large
    const IconStrip* chosen = &strips.back();
    for (const IconStrip& strip : strips) {
        if (strip.size >= Scale(strips.front().size)) {
            chosen = &strip;
            break;
        }
    }
    // one image list a strip, for all the windows, as long as the app runs
    static std::unordered_map<int, HIMAGELIST> lists;
    HIMAGELIST& list = lists[chosen->resource];
    if (!list) {
        // what the icons were drawn over is the transparent color: the smoothed edges blend into what is around them
        COLORREF transparent = RGB(chosen->background >> 16, (chosen->background >> 8) & 0xFF, chosen->background & 0xFF);
        list = ImageList_LoadImageW(GetModuleHandleW(nullptr), MAKEINTRESOURCEW(chosen->resource), chosen->size, 0, transparent,
                                    IMAGE_BITMAP, LR_CREATEDIBSECTION);
    }
    return list;
}

std::wstring MenuText(std::wstring text) {
    for (size_t at = text.find(L'&'); at != std::wstring::npos; at = text.find(L'&', at + 2)) {
        text.insert(at, 1, L'&');
    }
    return text;
}

std::wstring Shortcut(std::wstring_view keys) {
    static const std::pair<const wchar_t*, PeText> names[] = {
        {L"Ctrl", PE_TEXT_KEY_CTRL}, {L"Shift", PE_TEXT_KEY_SHIFT}, {L"Alt", PE_TEXT_KEY_ALT},
        {L"Del", PE_TEXT_KEY_DEL},   {L"Enter", PE_TEXT_KEY_ENTER},
    };
    std::wstring shortcut;
    size_t start = 0;
    while (start <= keys.size()) {
        size_t end = keys.find(L'+', start);
        std::wstring_view part = keys.substr(start, end == std::wstring_view::npos ? std::wstring_view::npos : end - start);
        std::wstring word(part);
        for (const auto& [english, id] : names) {
            if (part == english) {
                word = core::Plain(id);
            }
        }
        shortcut += (shortcut.empty() ? L"" : L"+") + word;
        if (end == std::wstring_view::npos) {
            break;
        }
        start = end + 1;
    }
    return shortcut;
}

std::wstring MenuItem(PeText text, std::wstring_view keys) {
    std::wstring item = core::T(text);
    return keys.empty() ? item : item + L"\t" + Shortcut(keys);
}

std::wstring DialogMenuItem(PeText text, std::wstring_view keys) {
    std::wstring item = core::T(text);
    if (!item.ends_with(L"...") && !item.ends_with(L"\u2026")) {
        item += L"...";
    }
    return keys.empty() ? item : item + L"\t" + Shortcut(keys);
}

std::wstring ReasonText(char* reason, PeText fallback) {
    core::String why(reason);
    return why ? Text(why.get()) : core::T(fallback);
}

bool SetJunkButton(HWND toolbar, bool inJunk) {
    int from = inJunk ? IDM_JUNK : IDM_NOT_JUNK, to = inJunk ? IDM_NOT_JUNK : IDM_JUNK;
    if (SendMessageW(toolbar, TB_COMMANDTOINDEX, from, 0) < 0) {
        return false;
    }
    TBBUTTONINFOW info = {sizeof(info)};
    info.dwMask = TBIF_COMMAND | TBIF_TEXT | TBIF_IMAGE;
    info.idCommand = to;
    std::wstring label = core::T(inJunk ? PE_TEXT_UI_TB_NOT_JUNK : PE_TEXT_UI_TB_JUNK);
    info.pszText = label.data();
    info.iImage = inJunk ? ICON_MAIL_CHECKMARK : ICON_MAIL_PROHIBITED;
    SendMessageW(toolbar, TB_SETBUTTONINFOW, from, reinterpret_cast<LPARAM>(&info));
    // the row of buttons as wide as their labels again
    SendMessageW(toolbar, TB_AUTOSIZE, 0, 0);
    return true;
}

HWND CreateBar(HWND hwnd, DWORD style, int id, BarIcons icons) {
    // big icons with the label under them, as Outlook Express has it; small ones beside nothing, the label a tooltip
    DWORD layout = icons == BarIcons::Big ? 0 : TBSTYLE_LIST | TBSTYLE_TOOLTIPS;
    HWND bar = CreateWindowExW(0, TOOLBARCLASSNAMEW, nullptr, WS_CHILD | WS_VISIBLE | TBSTYLE_FLAT | layout | style, 0, 0, 0, 0, hwnd,
                               reinterpret_cast<HMENU>(static_cast<INT_PTR>(id)), GetModuleHandleW(nullptr), nullptr);
    SendMessageW(bar, TB_BUTTONSTRUCTSIZE, sizeof(TBBUTTON), 0);
    // the small bar's labels are tooltips; a big button can have a menu beside it (BTNS_DROPDOWN)
    SendMessageW(bar, TB_SETEXTENDEDSTYLE, 0, icons == BarIcons::Small ? TBSTYLE_EX_MIXEDBUTTONS : TBSTYLE_EX_DRAWDDARROWS);
    SendMessageW(bar, TB_SETIMAGELIST, 0, reinterpret_cast<LPARAM>(IconList(icons == BarIcons::Big ? IconSet::Toolbar : IconSet::Format)));
    return bar;
}

// ---- report lists ----

HWND CreateReportList(HWND parent, int id, const RECT& bounds) {
    HWND list = CreateChild(parent, WC_LISTVIEWW, nullptr, WS_TABSTOP | LVS_REPORT | LVS_SINGLESEL | LVS_SHOWSELALWAYS | LVS_NOSORTHEADER, id,
                            bounds, WS_EX_CLIENTEDGE);
    ListView_SetExtendedListViewStyle(list, LVS_EX_FULLROWSELECT);
    return list;
}

int AddRow(HWND list, int index, const std::wstring& text) {
    LVITEMW item = {};
    item.mask = LVIF_TEXT;
    item.iItem = index;
    item.pszText = const_cast<wchar_t*>(text.c_str());
    return ListView_InsertItem(list, &item);
}

void SetCell(HWND list, int row, int column, const std::wstring& text) {
    ListView_SetItemText(list, row, column, const_cast<wchar_t*>(text.c_str()));
}

void SelectRow(HWND list, int row) {
    int count = ListView_GetItemCount(list);
    if (count > 0) {
        row = std::clamp(row, 0, count - 1);
        ListView_SetItemState(list, row, LVIS_SELECTED | LVIS_FOCUSED, LVIS_SELECTED | LVIS_FOCUSED);
    }
}

void AddButton(HWND bar, int id, const wchar_t* text, BYTE style, int image) {
    TBBUTTON button = {};
    button.idCommand = id;
    if (id == 0) {
        button.fsStyle = BTNS_SEP;
        SendMessageW(bar, TB_ADDBUTTONSW, 1, reinterpret_cast<LPARAM>(&button));
        return;
    }
    button.iBitmap = image;
    button.fsState = TBSTATE_ENABLED;
    // the text of a button with an icon is the tooltip on the format bar (mixed buttons) and the label under the icon
    // on the others, where it shows anyway; a button without an icon shows its text
    button.fsStyle = static_cast<BYTE>(style | BTNS_AUTOSIZE | (image == I_IMAGENONE ? BTNS_SHOWTEXT : 0));
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

namespace {

// the button marked the default (BS_DEFPUSHBUTTON) when the window opens
int DefaultButtonId(HWND dialog) {
    for (HWND child = GetWindow(dialog, GW_CHILD); child; child = GetWindow(child, GW_HWNDNEXT)) {
        wchar_t className[16] = L"";
        GetClassNameW(child, className, 16);
        if (_wcsicmp(className, L"Button") == 0 && (GetWindowLongPtrW(child, GWL_STYLE) & BS_TYPEMASK) == BS_DEFPUSHBUTTON) {
            return GetDlgCtrlID(child);
        }
    }
    return 0;
}

// What a dialog's own window procedure would answer: IsDialogMessage asks for the default button (Enter in a field),
// and a multi-line edit asks the window to move the focus on Tab. A plain window answers neither, so Enter would take
// IDOK whichever button is the default, and Tab would stay in the edit.
LRESULT CALLBACK ModalProc(HWND hwnd, UINT message, WPARAM wParam, LPARAM lParam, UINT_PTR, DWORD_PTR defaultId) {
    switch (message) {
    case DM_GETDEFID:
        if (defaultId) {
            return MAKELRESULT(defaultId, DC_HASDEFID);
        }
        break;
    case WM_NEXTDLGCTL: {
        HWND next = LOWORD(lParam) ? reinterpret_cast<HWND>(wParam) : GetNextDlgTabItem(hwnd, GetFocus(), wParam != 0);
        if (next) {
            SetFocus(next);
            // as Tab into a field selects its text
            if (SendMessageW(next, WM_GETDLGCODE, 0, 0) & DLGC_HASSETSEL) {
                SendMessageW(next, EM_SETSEL, 0, -1);
            }
        }
        return 0;
    }
    }
    return DefSubclassProc(hwnd, message, wParam, lParam);
}

}  // namespace

void RunModal(HWND dialog, HWND focus, const bool& done) {
    SetWindowSubclass(dialog, ModalProc, 0, static_cast<DWORD_PTR>(DefaultButtonId(dialog)));
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
        // Enter on an owner-drawn button clicks it: it can not be the default button, so the dialog would take IDOK
        if (msg.message == WM_KEYDOWN && msg.wParam == VK_RETURN && IsChild(dialog, msg.hwnd) &&
            (GetWindowLongPtrW(msg.hwnd, GWL_STYLE) & BS_TYPEMASK) == BS_OWNERDRAW) {
            wchar_t className[16] = L"";
            GetClassNameW(msg.hwnd, className, 16);
            if (_wcsicmp(className, L"Button") == 0) {
                SendMessageW(msg.hwnd, BM_CLICK, 0, 0);
                continue;
            }
        }
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
    RemoveWindowSubclass(dialog, ModalProc, 0);
    DestroyWindow(dialog);
    if (wasEnabled) {
        SetActiveWindow(root);
    }
}

std::vector<std::wstring> OpenFilesDialog(HWND owner, const wchar_t* title, const wchar_t* filter) {
    std::vector<wchar_t> buffer(65536, L'\0');
    OPENFILENAMEW dialog = {sizeof(dialog)};
    std::wstring allFiles = FileFilter({{core::T(PE_TEXT_UI_FILTER_ALL), L"*.*"}});
    dialog.hwndOwner = owner;
    dialog.lpstrFilter = filter ? filter : allFiles.c_str();
    dialog.lpstrFile = buffer.data();
    dialog.nMaxFile = static_cast<DWORD>(buffer.size());
    dialog.lpstrTitle = title;
    dialog.Flags = OFN_EXPLORER | OFN_FILEMUSTEXIST | OFN_ALLOWMULTISELECT | OFN_NOCHANGEDIR;
    if (!GetOpenFileNameW(&dialog)) {
        if (CommDlgExtendedError() == FNERR_BUFFERTOOSMALL) {
            MessageBoxW(owner, core::T(PE_TEXT_WIN_TOO_MANY_FILES).c_str(), title, MB_OK | MB_ICONWARNING);
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
