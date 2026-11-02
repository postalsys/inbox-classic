// PostalExpress: the main window in the Outlook Express layout, folders on the left, the message list on the top
// right and the reading pane below it, with splitters between them. All mail data comes from the Rust core
// (core.h); this file draws the frame and hands the core's events to the panes.
#include <objbase.h>
#include <shellapi.h>
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
// accounts whose last sync failed: their failure stays in the status bar
std::set<int64_t> g_failing;

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

// an account that signs in through the browser signs in again
void SignInAgain(int64_t account) {
    std::wstring text = L"The sign-in of " + g_mailbox.AccountName(account) + L" was refused or ran out.\n\nSign in again in the browser?";
    if (MessageBoxW(g_main, text.c_str(), kTitle, MB_YESNO | MB_ICONQUESTION) != IDYES) {
        return;
    }
    uint64_t request =
        SignInWithBrowser(g_main, g_core.get(), g_mailbox.OAuthProvider(account), g_mailbox.AccountEmail(account));
    if (request && pe_account_reauthorize(g_core.get(), account, request)) {
        pe_sync(g_core.get(), account);
    }
}

void AskPassword(int64_t account) {
    if (!g_prompting.insert(account).second) {
        return;
    }
    if (g_mailbox.OAuthProvider(account) != PE_O_AUTH_PROVIDER_NONE) {
        SignInAgain(account);
        g_prompting.erase(account);
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
        g_failing.erase(event.account);
        SetStatus(L"Checking for new messages on " + g_mailbox.AccountName(event.account) + L"...");
        break;
    case PE_EVENT_KIND_SYNC_FINISHED:
        // a failure stays in the status bar until the account syncs without one
        if (g_failing.empty()) {
            SetStatus(L"Done");
        }
        break;
    case PE_EVENT_KIND_AUTOCONFIG_DONE:
    case PE_EVENT_KIND_SIGN_IN_DONE:
        RequestDone(event.uid);
        break;
    case PE_EVENT_KIND_MESSAGE_SENT:
        SetStatus(L"Message sent.");
        break;
    case PE_EVENT_KIND_FAILED:
        g_failing.insert(event.account);
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
    HMENU compose = CreatePopupMenu();
    AppendMenuW(compose, MF_STRING, IDM_NEW_MAIL, L"&New Message\tCtrl+N");
    AppendMenuW(compose, MF_SEPARATOR, 0, nullptr);
    AppendMenuW(compose, MF_STRING, IDM_REPLY, L"&Reply to Sender\tCtrl+R");
    AppendMenuW(compose, MF_STRING, IDM_REPLY_ALL, L"Reply to &All\tCtrl+Shift+R");
    AppendMenuW(compose, MF_STRING, IDM_FORWARD, L"&Forward\tCtrl+F");
    HMENU edit = CreatePopupMenu();
    AppendMenuW(edit, MF_STRING, IDM_MARK_READ, L"Mark as &Read\tCtrl+Q");
    AppendMenuW(edit, MF_STRING, IDM_MARK_UNREAD, L"Mark as &Unread");
    HMENU view = CreatePopupMenu();
    AppendMenuW(view, MF_STRING, IDM_PICTURES, L"Download &Pictures");
    HMENU tools = CreatePopupMenu();
    AppendMenuW(tools, MF_STRING, IDM_SYNC, L"Send and Recei&ve All\tF5");
    HMENU help = CreatePopupMenu();
    AppendMenuW(help, MF_STRING, IDM_HELP, L"&Contents\tF1");
    AppendMenuW(help, MF_SEPARATOR, 0, nullptr);
    AppendMenuW(help, MF_STRING, IDM_ABOUT, L"&About PostalExpress");
    HMENU bar = CreateMenu();
    AppendMenuW(bar, MF_POPUP, reinterpret_cast<UINT_PTR>(file), L"&File");
    AppendMenuW(bar, MF_POPUP, reinterpret_cast<UINT_PTR>(edit), L"&Edit");
    AppendMenuW(bar, MF_POPUP, reinterpret_cast<UINT_PTR>(view), L"&View");
    AppendMenuW(bar, MF_POPUP, reinterpret_cast<UINT_PTR>(tools), L"&Tools");
    AppendMenuW(bar, MF_POPUP, reinterpret_cast<UINT_PTR>(compose), L"&Message");
    AppendMenuW(bar, MF_POPUP, reinterpret_cast<UINT_PTR>(help), L"&Help");
    return bar;
}

HACCEL BuildAccelerators() {
    ACCEL keys[] = {
        {FVIRTKEY, VK_F5, IDM_SYNC},
        {FVIRTKEY, VK_F1, IDM_HELP},
        {FVIRTKEY | FCONTROL, 'Q', IDM_MARK_READ},
        {FVIRTKEY | FCONTROL, 'N', IDM_NEW_MAIL},
        {FVIRTKEY | FCONTROL, 'R', IDM_REPLY},
        {FVIRTKEY | FCONTROL | FSHIFT, 'R', IDM_REPLY_ALL},
        {FVIRTKEY | FCONTROL, 'F', IDM_FORWARD},
    };
    return CreateAcceleratorTableW(keys, static_cast<int>(std::size(keys)));
}

void CreateToolbar(HWND hwnd) {
    g_toolbar = CreateBar(hwnd, CCS_NODIVIDER | CCS_TOP, 0);
    struct Button {
        WORD id;
        const wchar_t* text;
    };
    Button buttons[] = {{IDM_NEW_MAIL, L"Create Mail"}, {IDM_REPLY, L"Reply"}, {IDM_REPLY_ALL, L"Reply All"},
                        {IDM_FORWARD, L"Forward"}, {IDM_SYNC, L"Send/Recv"}, {IDM_MARK_READ, L"Mark Read"}, {IDM_MARK_UNREAD, L"Mark Unread"}, {IDM_NEW_ACCOUNT, L"New Account"}};
    for (const Button& button : buttons) {
        AddButton(g_toolbar, button.id, button.text);
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

// the command line, options for test runs: --store <file> uses another mail store, --memory-passwords keeps
// passwords for this run only, --pin-certificate <file> trusts only that server certificate (see res/help.html)
struct Arguments {
    std::wstring store;
    std::wstring certificate;
    bool memoryPasswords = false;
};
Arguments g_arguments;

void ReadArguments() {
    int count = 0;
    LPWSTR* argv = CommandLineToArgvW(GetCommandLineW(), &count);
    for (int i = 1; argv && i < count; i++) {
        std::wstring arg = argv[i];
        if (arg == L"--store" && i + 1 < count) {
            g_arguments.store = argv[++i];
        } else if (arg == L"--pin-certificate" && i + 1 < count) {
            g_arguments.certificate = argv[++i];
        } else if (arg == L"--memory-passwords") {
            g_arguments.memoryPasswords = true;
        }
    }
    LocalFree(argv);
}

bool OpenCore(HWND hwnd) {
    std::string path = core::Narrow(g_arguments.store.empty() ? StorePath() : g_arguments.store);
    uint32_t flags = g_arguments.memoryPasswords ? PE_OPEN_MEMORY_PASSWORDS : 0;
    std::string certificate = core::Narrow(g_arguments.certificate);
    g_core.reset(pe_core_open_with(path.c_str(), flags, certificate.empty() ? nullptr : certificate.c_str(), OnCoreEvent, hwnd));
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

void NewMessage() {
    int64_t account = g_mailbox.CurrentAccount();
    if (!account) {
        MessageBoxW(g_main, L"Add a mail account first.", kTitle, MB_OK | MB_ICONINFORMATION);
        return;
    }
    OpenCompose(g_main, g_core.get(), account, nullptr);
}

void Reply(PeDraftKind kind) {
    core::Draft draft = g_mailbox.DraftOfShown(kind);
    if (!draft) {
        MessageBoxW(g_main, L"Select a message first.", kTitle, MB_OK | MB_ICONINFORMATION);
        return;
    }
    OpenCompose(g_main, g_core.get(), g_mailbox.CurrentAccount(), pe_draft_info(draft.get()));
}

void OnCommand(WORD id) {
    switch (id) {
    case IDM_NEW_MAIL:
        NewMessage();
        return;
    case IDM_REPLY:
        Reply(PE_DRAFT_KIND_REPLY);
        return;
    case IDM_REPLY_ALL:
        Reply(PE_DRAFT_KIND_REPLY_ALL);
        return;
    case IDM_FORWARD:
        Reply(PE_DRAFT_KIND_FORWARD);
        return;
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
    case IDM_HELP:
        OpenHelp();
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
            const wchar_t* why = g_arguments.certificate.empty() ? L"The mail store could not be opened."
                                                                 : L"The mail store or the certificate file could not be opened.";
            MessageBoxW(hwnd, why, kTitle, MB_OK | MB_ICONERROR);
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
        // the WebView2s go before COM does, the core before its events are dropped
        CloseHelp();
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
    ReadArguments();
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
        if (TranslateAcceleratorW(hwnd, g_accelerators, &msg)) {
            continue;
        }
        // Tab moves between the panes of the main window and the fields of a compose window
        HWND active = GetActiveWindow();
        if (active && IsDialogMessageW(active, &msg)) {
            continue;
        }
        TranslateMessage(&msg);
        DispatchMessageW(&msg);
    }
    DestroyAcceleratorTable(g_accelerators);
    CoUninitialize();
    return static_cast<int>(msg.wParam);
}
