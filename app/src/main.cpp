// PostalExpress: the main window in the Outlook Express layout, folders on the left, the message list on the top
// right and the preview below it. All mail data comes from the Rust core (core.h); this file only draws it.
#include <windows.h>

#include <commctrl.h>
#include <objbase.h>

#include <algorithm>

#include "core.h"
#include "preview.h"

#define WIDEN2(text) L##text
#define WIDEN(text) WIDEN2(text)
#define APP_VERSION_W WIDEN(APP_VERSION)

namespace {

enum MenuId {
    IDM_EXIT = 100,
    IDM_ABOUT,
};

const wchar_t* kMainClass = L"PostalExpressMain";
const wchar_t* kTitle = L"PostalExpress";

// pane sizes in pixels at 96 DPI, scaled by Scale()
constexpr int kFolderWidth = 200;
constexpr int kGap = 4;

HWND g_main = nullptr;
HWND g_folders = nullptr;
HWND g_list = nullptr;
// the WebView2 lives in this sunken static, which also shows the error when WebView2 is not available
HWND g_previewHost = nullptr;
HWND g_status = nullptr;
Preview g_preview;

int Scale(int value) {
    return MulDiv(value, static_cast<int>(GetDpiForWindow(g_main)), 96);
}

HMENU BuildMenu() {
    HMENU file = CreatePopupMenu();
    AppendMenuW(file, MF_STRING, IDM_EXIT, L"E&xit");
    HMENU help = CreatePopupMenu();
    AppendMenuW(help, MF_STRING, IDM_ABOUT, L"&About PostalExpress");
    HMENU bar = CreateMenu();
    AppendMenuW(bar, MF_POPUP, reinterpret_cast<UINT_PTR>(file), L"&File");
    AppendMenuW(bar, MF_POPUP, reinterpret_cast<UINT_PTR>(help), L"&Help");
    return bar;
}

HTREEITEM AddFolder(HTREEITEM parent, const wchar_t* name) {
    TVINSERTSTRUCTW insert = {};
    insert.hParent = parent;
    insert.hInsertAfter = TVI_LAST;
    insert.item.mask = TVIF_TEXT;
    insert.item.pszText = const_cast<wchar_t*>(name);
    return reinterpret_cast<HTREEITEM>(SendMessageW(g_folders, TVM_INSERTITEMW, 0, reinterpret_cast<LPARAM>(&insert)));
}

void AddColumn(int index, const wchar_t* name, int width) {
    LVCOLUMNW column = {};
    column.mask = LVCF_TEXT | LVCF_WIDTH;
    column.pszText = const_cast<wchar_t*>(name);
    column.cx = Scale(width);
    SendMessageW(g_list, LVM_INSERTCOLUMNW, index, reinterpret_cast<LPARAM>(&column));
}

void AddRow(const wchar_t* from, const wchar_t* subject, const wchar_t* received) {
    LVITEMW item = {};
    item.mask = LVIF_TEXT;
    item.iItem = static_cast<int>(SendMessageW(g_list, LVM_GETITEMCOUNT, 0, 0));
    item.pszText = const_cast<wchar_t*>(L"");
    int row = static_cast<int>(SendMessageW(g_list, LVM_INSERTITEMW, 0, reinterpret_cast<LPARAM>(&item)));
    const wchar_t* cells[] = {from, subject, received};
    for (int i = 0; i < 3; i++) {
        item.iItem = row;
        item.iSubItem = i + 1;
        item.pszText = const_cast<wchar_t*>(cells[i]);
        SendMessageW(g_list, LVM_SETITEMTEXTW, row, reinterpret_cast<LPARAM>(&item));
    }
}

// placeholder content until the core has a store: the welcome message goes through the same sanitizer as real mail,
// the script and the handler in it are removed by the core
void ShowWelcome() {
    AddRow(L"PostalExpress Team", L"Welcome to PostalExpress", L"");
    std::string html =
        "<h2 style=\"font-family:Arial\">Welcome to PostalExpress</h2>"
        "<p onclick=\"alert('not run')\">This message was sanitized by the Rust core version " +
        core::Narrow(core::Version()) +
        ".</p><script>document.body.innerHTML='scripts run'</script>";
    std::wstring document = core::RenderHtml(html, false);
    g_preview.Show(document.empty() ? L"<p>The core could not render this message.</p>" : document);
}

void Layout() {
    RECT client;
    GetClientRect(g_main, &client);
    SendMessageW(g_status, WM_SIZE, 0, 0);
    RECT status;
    GetWindowRect(g_status, &status);
    int height = client.bottom - (status.bottom - status.top);
    int folderWidth = std::min(Scale(kFolderWidth), static_cast<int>(client.right / 2));
    int gap = Scale(kGap);
    int right = folderWidth + gap;
    int listHeight = height * 2 / 5;
    MoveWindow(g_folders, 0, 0, folderWidth, height, TRUE);
    MoveWindow(g_list, right, 0, client.right - right, listHeight, TRUE);
    MoveWindow(g_previewHost, right, listHeight + gap, client.right - right, height - listHeight - gap, TRUE);
    RECT inner;
    GetClientRect(g_previewHost, &inner);
    g_preview.Resize(inner);
}

void CreateChildren(HWND hwnd) {
    HINSTANCE instance = GetModuleHandleW(nullptr);
    HFONT font = static_cast<HFONT>(GetStockObject(DEFAULT_GUI_FONT));

    g_folders = CreateWindowExW(WS_EX_CLIENTEDGE, WC_TREEVIEWW, nullptr,
                                WS_CHILD | WS_VISIBLE | WS_TABSTOP | TVS_HASLINES | TVS_HASBUTTONS | TVS_LINESATROOT |
                                    TVS_SHOWSELALWAYS,
                                0, 0, 0, 0, hwnd, nullptr, instance, nullptr);
    g_list = CreateWindowExW(WS_EX_CLIENTEDGE, WC_LISTVIEWW, nullptr,
                             WS_CHILD | WS_VISIBLE | WS_TABSTOP | LVS_REPORT | LVS_SHOWSELALWAYS | LVS_SINGLESEL, 0, 0, 0,
                             0, hwnd, nullptr, instance, nullptr);
    g_previewHost = CreateWindowExW(0, L"STATIC", nullptr, WS_CHILD | WS_VISIBLE | SS_SUNKEN | WS_CLIPCHILDREN, 0, 0, 0, 0,
                                    hwnd, nullptr, instance, nullptr);
    g_status = CreateWindowExW(0, STATUSCLASSNAMEW, nullptr, WS_CHILD | WS_VISIBLE | SBARS_SIZEGRIP, 0, 0, 0, 0, hwnd,
                               nullptr, instance, nullptr);
    for (HWND control : {g_folders, g_list, g_previewHost, g_status}) {
        SendMessageW(control, WM_SETFONT, reinterpret_cast<WPARAM>(font), FALSE);
    }
    SendMessageW(g_list, LVM_SETEXTENDEDLISTVIEWSTYLE, LVS_EX_FULLROWSELECT, LVS_EX_FULLROWSELECT);

    HTREEITEM local = AddFolder(TVI_ROOT, L"Local Folders");
    for (const wchar_t* name : {L"Inbox", L"Outbox", L"Sent Items", L"Deleted Items", L"Drafts"}) {
        AddFolder(local, name);
    }
    SendMessageW(g_folders, TVM_EXPAND, TVE_EXPAND, reinterpret_cast<LPARAM>(local));

    AddColumn(0, L"!", 22);
    AddColumn(1, L"From", 180);
    AddColumn(2, L"Subject", 320);
    AddColumn(3, L"Received", 140);

    g_preview.Create(g_previewHost, [](const std::wstring& error) { SetWindowTextW(g_previewHost, error.c_str()); });
    ShowWelcome();
    SendMessageW(g_status, SB_SETTEXTW, 0, reinterpret_cast<LPARAM>(L"1 message(s), 0 unread"));
}

void ShowAbout() {
    std::wstring text = std::wstring(L"PostalExpress ") + APP_VERSION_W + L"\nCore " + core::Version() + L"\n\nPostal Systems OÜ";
    MessageBoxW(g_main, text.c_str(), L"About PostalExpress", MB_OK | MB_ICONINFORMATION);
}

LRESULT CALLBACK MainProc(HWND hwnd, UINT message, WPARAM wParam, LPARAM lParam) {
    switch (message) {
    case WM_CREATE:
        g_main = hwnd;
        CreateChildren(hwnd);
        return 0;
    case WM_SIZE:
        Layout();
        return 0;
    case WM_DPICHANGED: {
        const RECT* suggested = reinterpret_cast<const RECT*>(lParam);
        SetWindowPos(hwnd, nullptr, suggested->left, suggested->top, suggested->right - suggested->left,
                     suggested->bottom - suggested->top, SWP_NOZORDER | SWP_NOACTIVATE);
        return 0;
    }
    case WM_COMMAND:
        switch (LOWORD(wParam)) {
        case IDM_EXIT:
            DestroyWindow(hwnd);
            return 0;
        case IDM_ABOUT:
            ShowAbout();
            return 0;
        }
        break;
    case WM_DESTROY:
        PostQuitMessage(0);
        return 0;
    }
    return DefWindowProcW(hwnd, message, wParam, lParam);
}

}  // namespace

int WINAPI wWinMain(HINSTANCE instance, HINSTANCE, PWSTR, int show) {
    if (FAILED(CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED))) {
        return 1;
    }
    INITCOMMONCONTROLSEX controls = {sizeof(controls), ICC_TREEVIEW_CLASSES | ICC_LISTVIEW_CLASSES | ICC_BAR_CLASSES};
    InitCommonControlsEx(&controls);

    WNDCLASSEXW windowClass = {sizeof(windowClass)};
    windowClass.lpfnWndProc = MainProc;
    windowClass.hInstance = instance;
    windowClass.hCursor = LoadCursorW(nullptr, IDC_ARROW);
    windowClass.hIcon = LoadIconW(nullptr, IDI_APPLICATION);
    windowClass.hbrBackground = reinterpret_cast<HBRUSH>(COLOR_BTNFACE + 1);
    windowClass.lpszClassName = kMainClass;
    RegisterClassExW(&windowClass);

    HWND hwnd = CreateWindowExW(0, kMainClass, kTitle, WS_OVERLAPPEDWINDOW | WS_CLIPCHILDREN, CW_USEDEFAULT, CW_USEDEFAULT, 1000, 700, nullptr,
                                BuildMenu(), instance, nullptr);
    if (!hwnd) {
        return 1;
    }
    ShowWindow(hwnd, show);
    UpdateWindow(hwnd);

    MSG msg;
    while (GetMessageW(&msg, nullptr, 0, 0) > 0) {
        TranslateMessage(&msg);
        DispatchMessageW(&msg);
    }
    CoUninitialize();
    return static_cast<int>(msg.wParam);
}
