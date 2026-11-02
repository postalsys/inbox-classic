// PostalExpress: the main window in the Outlook Express layout, folders on the left, the message list on the top
// right and the reading pane below it, with splitters between them. All mail data comes from the Rust core
// (core.h); this file draws the frame and hands the core's events to the panes.
#include <objbase.h>
#include <shlobj.h>

#include <algorithm>
#include <set>

#include "app.h"

#define WIDEN2(text) L##text
#define WIDEN(text) WIDEN2(text)
#define APP_VERSION_W WIDEN(APP_VERSION)

namespace {

const wchar_t* kMainClass = L"PostalExpressMain";
const wchar_t* kTitle = L"PostalExpress";
// sync every account this often, in milliseconds
constexpr UINT kSyncInterval = 10 * 60 * 1000;
constexpr UINT_PTR TIMER_SYNC = 2;

HWND g_main = nullptr;
HWND g_toolbar = nullptr;
HWND g_status = nullptr;
HACCEL g_accelerators = nullptr;
core::Core g_core;
Mailbox g_mailbox;

// pane sizes in pixels at 96 DPI
int g_treeWidth = 200;
int g_listHeight = 260;
constexpr int kGap = 4;
// the splitter being dragged: 0 none, 1 between the tree and the rest, 2 between the list and the reading pane
int g_dragging = 0;
// accounts whose password prompt is open, so a second failure does not open another
std::set<int64_t> g_prompting;

// ---- the core's events ----

// called on a worker thread: copies the event and posts it to the window thread, never waits
void OnCoreEvent(void* context, const PeEvent* event) noexcept {
    try {
        auto* copy = new UiEvent{event->kind, event->account, event->folder, event->uid, event->failure,
                                 event->message ? core::Widen(event->message) : std::wstring()};
        if (!PostMessageW(static_cast<HWND>(context), WM_CORE_EVENT, 0, reinterpret_cast<LPARAM>(copy))) {
            delete copy;
        }
    } catch (...) {
        // out of memory: the event is lost, the next sync shows the state again
    }
}

void SetStatus(const std::wstring& text) {
    SendMessageW(g_status, SB_SETTEXTW, 0, reinterpret_cast<LPARAM>(text.c_str()));
}

void ShowCounts() {
    std::wstring counts = g_mailbox.Counts();
    SendMessageW(g_status, SB_SETTEXTW, 1, reinterpret_cast<LPARAM>(counts.c_str()));
}

void SyncAll() {
    core::AccountList accounts(pe_accounts(g_core.get()));
    for (size_t i = 0; i < pe_account_list_count(accounts.get()); i++) {
        pe_sync(g_core.get(), pe_account_list_get(accounts.get(), i)->id);
    }
}

void AskPassword(int64_t account) {
    if (!g_prompting.insert(account).second) {
        return;
    }
    std::wstring password;
    if (PasswordDialog(g_main, g_mailbox.AccountName(account), password)) {
        std::string utf8 = core::Narrow(password);
        pe_account_set_password(g_core.get(), account, utf8.c_str());
        SecureZeroMemory(utf8.data(), utf8.size());
        SecureZeroMemory(password.data(), password.size() * sizeof(wchar_t));
        pe_sync(g_core.get(), account);
    }
    g_prompting.erase(account);
}

void OnEvent(const UiEvent& event) {
    switch (event.kind) {
    case PE_EVENT_KIND_SYNC_STARTED:
        SetStatus(L"Checking for new messages on " + g_mailbox.AccountName(event.account) + L"...");
        break;
    case PE_EVENT_KIND_SYNC_FINISHED:
        SetStatus(L"Done");
        break;
    case PE_EVENT_KIND_FAILED:
        SetStatus(g_mailbox.AccountName(event.account) + L": " + event.message);
        if (event.failure == PE_FAILURE_KIND_AUTHENTICATION) {
            AskPassword(event.account);
        }
        break;
    default:
        break;
    }
    g_mailbox.OnEvent(event);
    ShowCounts();
}

// ---- the frame ----

HMENU BuildMenu() {
    HMENU file = CreatePopupMenu();
    AppendMenuW(file, MF_STRING, IDM_NEW_ACCOUNT, L"&New Account...");
    AppendMenuW(file, MF_SEPARATOR, 0, nullptr);
    AppendMenuW(file, MF_STRING, IDM_EXIT, L"E&xit");
    HMENU edit = CreatePopupMenu();
    AppendMenuW(edit, MF_STRING, IDM_MARK_READ, L"Mark as &Read\tCtrl+Q");
    AppendMenuW(edit, MF_STRING, IDM_MARK_UNREAD, L"Mark as &Unread");
    HMENU view = CreatePopupMenu();
    AppendMenuW(view, MF_STRING, IDM_PICTURES, L"Download &Pictures");
    HMENU tools = CreatePopupMenu();
    AppendMenuW(tools, MF_STRING, IDM_SYNC, L"Send and Recei&ve All\tF5");
    HMENU help = CreatePopupMenu();
    AppendMenuW(help, MF_STRING, IDM_ABOUT, L"&About PostalExpress");
    HMENU bar = CreateMenu();
    AppendMenuW(bar, MF_POPUP, reinterpret_cast<UINT_PTR>(file), L"&File");
    AppendMenuW(bar, MF_POPUP, reinterpret_cast<UINT_PTR>(edit), L"&Edit");
    AppendMenuW(bar, MF_POPUP, reinterpret_cast<UINT_PTR>(view), L"&View");
    AppendMenuW(bar, MF_POPUP, reinterpret_cast<UINT_PTR>(tools), L"&Tools");
    AppendMenuW(bar, MF_POPUP, reinterpret_cast<UINT_PTR>(help), L"&Help");
    return bar;
}

HACCEL BuildAccelerators() {
    ACCEL keys[] = {
        {FVIRTKEY, VK_F5, IDM_SYNC},
        {FVIRTKEY | FCONTROL, 'Q', IDM_MARK_READ},
    };
    return CreateAcceleratorTableW(keys, static_cast<int>(std::size(keys)));
}

void CreateToolbar(HWND hwnd) {
    g_toolbar = CreateWindowExW(0, TOOLBARCLASSNAMEW, nullptr,
                                WS_CHILD | WS_VISIBLE | TBSTYLE_FLAT | TBSTYLE_LIST | CCS_NODIVIDER | CCS_TOP, 0, 0, 0, 0, hwnd,
                                nullptr, GetModuleHandleW(nullptr), nullptr);
    SendMessageW(g_toolbar, TB_BUTTONSTRUCTSIZE, sizeof(TBBUTTON), 0);
    SendMessageW(g_toolbar, TB_SETEXTENDEDSTYLE, 0, TBSTYLE_EX_MIXEDBUTTONS);
    struct Button {
        WORD id;
        const wchar_t* text;
    };
    Button buttons[] = {{IDM_SYNC, L"Send/Recv"}, {IDM_MARK_READ, L"Mark Read"}, {IDM_MARK_UNREAD, L"Mark Unread"}, {IDM_NEW_ACCOUNT, L"New Account"}};
    for (const Button& button : buttons) {
        TBBUTTON item = {};
        item.iBitmap = I_IMAGENONE;
        item.idCommand = button.id;
        item.fsState = TBSTATE_ENABLED;
        item.fsStyle = BTNS_BUTTON | BTNS_AUTOSIZE | BTNS_SHOWTEXT;
        item.iString = reinterpret_cast<INT_PTR>(button.text);
        SendMessageW(g_toolbar, TB_ADDBUTTONSW, 1, reinterpret_cast<LPARAM>(&item));
    }
    SendMessageW(g_toolbar, TB_AUTOSIZE, 0, 0);
}

// the area between the toolbar and the status bar
RECT ContentArea() {
    RECT client;
    GetClientRect(g_main, &client);
    RECT bar;
    GetWindowRect(g_toolbar, &bar);
    client.top += bar.bottom - bar.top;
    GetWindowRect(g_status, &bar);
    client.bottom -= bar.bottom - bar.top;
    return client;
}

// where the panes go: the tree width and the list height as Layout clamps them, in pixels
struct Panes {
    RECT area;
    int treeWidth;
    int listHeight;
};

Panes Measure() {
    RECT area = ContentArea();
    int width = area.right - area.left;
    int height = area.bottom - area.top;
    int treeWidth = std::clamp(Scale(g_treeWidth), Scale(80), std::max(Scale(80), width - Scale(200)));
    int listHeight = std::clamp(Scale(g_listHeight), Scale(60), std::max(Scale(60), height - Scale(120)));
    return {area, treeWidth, listHeight};
}

void Layout() {
    SendMessageW(g_toolbar, TB_AUTOSIZE, 0, 0);
    SendMessageW(g_status, WM_SIZE, 0, 0);
    Panes panes = Measure();
    const RECT& area = panes.area;
    int gap = Scale(kGap);
    int right = area.left + panes.treeWidth + gap;
    RECT tree = {area.left, area.top, area.left + panes.treeWidth, area.bottom};
    RECT list = {right, area.top, area.right, area.top + panes.listHeight};
    RECT reader = {right, list.bottom + gap, area.right, area.bottom};
    g_mailbox.Layout(tree, list, reader);
    int parts[] = {std::max(0, static_cast<int>(area.right - area.left) - Scale(220)), -1};
    SendMessageW(g_status, SB_SETPARTS, 2, reinterpret_cast<LPARAM>(parts));
}

// which splitter is under a point of the client area: 0 none, 1 beside the tree, 2 below the list
int SplitterAt(POINT point) {
    Panes panes = Measure();
    int gap = Scale(kGap);
    int treeRight = panes.area.left + panes.treeWidth;
    if (point.y >= panes.area.top && point.y < panes.area.bottom && point.x >= treeRight && point.x < treeRight + gap) {
        return 1;
    }
    int listBottom = panes.area.top + panes.listHeight;
    if (point.x >= treeRight + gap && point.y >= listBottom && point.y < listBottom + gap) {
        return 2;
    }
    return 0;
}

void DragSplitter(POINT point) {
    RECT area = ContentArea();
    int dpi = static_cast<int>(GetDpiForWindow(g_main));
    if (g_dragging == 1) {
        g_treeWidth = std::max(80, MulDiv(point.x - area.left, 96, dpi));
    } else {
        g_listHeight = std::max(60, MulDiv(point.y - area.top, 96, dpi));
    }
    Layout();
}

std::wstring StorePath() {
    PWSTR base = nullptr;
    std::wstring dir;
    if (SUCCEEDED(SHGetKnownFolderPath(FOLDERID_LocalAppData, 0, nullptr, &base))) {
        dir = std::wstring(base) + L"\\PostalExpress";
    }
    CoTaskMemFree(base);
    CreateDirectoryW(dir.c_str(), nullptr);
    return dir + L"\\store.db";
}

bool OpenCore(HWND hwnd) {
    std::string path = core::Narrow(StorePath());
    g_core.reset(pe_core_open(path.c_str(), OnCoreEvent, hwnd));
    return g_core != nullptr;
}

void CreateChildren(HWND hwnd) {
    CreateToolbar(hwnd);
    g_status = CreateWindowExW(0, STATUSCLASSNAMEW, nullptr, WS_CHILD | WS_VISIBLE | SBARS_SIZEGRIP, 0, 0, 0, 0, hwnd, nullptr,
                               GetModuleHandleW(nullptr), nullptr);
    g_mailbox.Create(hwnd, g_core.get());
}

void AddAccount() {
    if (NewAccountDialog(g_main, g_core.get())) {
        g_mailbox.Reload();
        SyncAll();
    }
}

void ShowAbout() {
    std::wstring text = std::wstring(L"PostalExpress ") + APP_VERSION_W + L"\nCore " + core::Version() + L"\n\nPostal Systems OÜ";
    MessageBoxW(g_main, text.c_str(), L"About PostalExpress", MB_OK | MB_ICONINFORMATION);
}

void OnCommand(WORD id) {
    switch (id) {
    case IDM_NEW_ACCOUNT:
        AddAccount();
        return;
    case IDM_EXIT:
        DestroyWindow(g_main);
        return;
    case IDM_SYNC:
        SyncAll();
        return;
    case IDM_MARK_READ:
        g_mailbox.MarkSelected(true);
        return;
    case IDM_MARK_UNREAD:
        g_mailbox.MarkSelected(false);
        return;
    case IDM_PICTURES:
        g_mailbox.LoadPictures();
        return;
    case IDM_ABOUT:
        ShowAbout();
        return;
    case IDC_TREE:
        ShowCounts();
        return;
    }
    g_mailbox.OnCommand(id);
}

// the events still queued when the core is closed are dropped
void DropQueuedEvents() {
    MSG msg;
    while (PeekMessageW(&msg, g_main, WM_CORE_EVENT, WM_CORE_EVENT, PM_REMOVE)) {
        delete reinterpret_cast<UiEvent*>(msg.lParam);
    }
}

LRESULT CALLBACK MainProc(HWND hwnd, UINT message, WPARAM wParam, LPARAM lParam) {
    switch (message) {
    case WM_CREATE:
        g_main = hwnd;
        SetScaleWindow(hwnd);
        if (!OpenCore(hwnd)) {
            MessageBoxW(hwnd, L"The mail store could not be opened.", kTitle, MB_OK | MB_ICONERROR);
            return -1;
        }
        CreateChildren(hwnd);
        SetTimer(hwnd, TIMER_SYNC, kSyncInterval, nullptr);
        return 0;
    case WM_SIZE:
        Layout();
        return 0;
    case WM_SETCURSOR: {
        POINT point;
        GetCursorPos(&point);
        ScreenToClient(hwnd, &point);
        int splitter = reinterpret_cast<HWND>(wParam) == hwnd ? SplitterAt(point) : 0;
        if (splitter) {
            SetCursor(LoadCursorW(nullptr, splitter == 1 ? IDC_SIZEWE : IDC_SIZENS));
            return TRUE;
        }
        break;
    }
    case WM_LBUTTONDOWN: {
        POINT point = {static_cast<short>(LOWORD(lParam)), static_cast<short>(HIWORD(lParam))};
        g_dragging = SplitterAt(point);
        if (g_dragging) {
            SetCapture(hwnd);
        }
        return 0;
    }
    case WM_MOUSEMOVE:
        if (g_dragging) {
            DragSplitter({static_cast<short>(LOWORD(lParam)), static_cast<short>(HIWORD(lParam))});
        }
        return 0;
    case WM_LBUTTONUP:
    case WM_CAPTURECHANGED:
        if (g_dragging) {
            g_dragging = 0;
            if (message == WM_LBUTTONUP) {
                ReleaseCapture();
            }
        }
        return 0;
    case WM_DPICHANGED: {
        const RECT* suggested = reinterpret_cast<const RECT*>(lParam);
        SetWindowPos(hwnd, nullptr, suggested->left, suggested->top, suggested->right - suggested->left,
                     suggested->bottom - suggested->top, SWP_NOZORDER | SWP_NOACTIVATE);
        return 0;
    }
    case WM_NOTIFY: {
        LRESULT result = 0;
        if (g_mailbox.OnNotify(reinterpret_cast<NMHDR*>(lParam), result)) {
            return result;
        }
        break;
    }
    case WM_COMMAND:
        OnCommand(LOWORD(wParam));
        return 0;
    case WM_TIMER:
        if (wParam == TIMER_SYNC) {
            SyncAll();
        } else {
            g_mailbox.OnTimer(wParam);
        }
        return 0;
    case WM_CORE_EVENT: {
        std::unique_ptr<UiEvent> event(reinterpret_cast<UiEvent*>(lParam));
        OnEvent(*event);
        return 0;
    }
    case WM_CTLCOLORSTATIC:
        return ButtonFaceColor(reinterpret_cast<HDC>(wParam));
    case WM_DESTROY:
        KillTimer(hwnd, TIMER_SYNC);
        // the WebView2 goes before COM does, the core before its events are dropped
        g_mailbox.Destroy();
        g_core.reset();
        DropQueuedEvents();
        PostQuitMessage(0);
        return 0;
    }
    return DefWindowProcW(hwnd, message, wParam, lParam);
}

// the first start: an account to read mail from
void FirstRun() {
    core::AccountList accounts(pe_accounts(g_core.get()));
    if (pe_account_list_count(accounts.get()) == 0) {
        AddAccount();
    } else {
        SyncAll();
    }
}

}  // namespace

int WINAPI wWinMain(HINSTANCE instance, HINSTANCE, PWSTR, int show) {
    // DLLs only from System32 and the app's own directory, never from the current directory
    SetDefaultDllDirectories(LOAD_LIBRARY_SEARCH_DEFAULT_DIRS);
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

    HWND hwnd = CreateWindowExW(0, kMainClass, kTitle, WS_OVERLAPPEDWINDOW | WS_CLIPCHILDREN, CW_USEDEFAULT, CW_USEDEFAULT, 1100,
                                760, nullptr, BuildMenu(), instance, nullptr);
    if (!hwnd) {
        return 1;
    }
    g_accelerators = BuildAccelerators();
    ShowWindow(hwnd, show);
    UpdateWindow(hwnd);
    FirstRun();

    MSG msg;
    while (GetMessageW(&msg, nullptr, 0, 0) > 0) {
        if (!TranslateAcceleratorW(hwnd, g_accelerators, &msg)) {
            TranslateMessage(&msg);
            DispatchMessageW(&msg);
        }
    }
    DestroyAcceleratorTable(g_accelerators);
    CoUninitialize();
    return static_cast<int>(msg.wParam);
}
