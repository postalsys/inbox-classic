// The help window, as HTML Help showed it: a toolbar (Hide or Show, Back, Forward, Home, Print), the Contents and
// Search tabs at the left, and the topic at the right in a WebView2 like a message's (scripts off, nothing from the
// network). The contents, the search and every page come from the core (pe_help_contents, pe_help_search,
// pe_help_topic); a link to another topic (`topic:<id>`, pe_help_link_topic) opens it here, any other in the browser.
// One window: F1 again brings it to the front at the topic of the window F1 was pressed in.
#include "app.h"

#include <algorithm>

namespace {

const wchar_t* kHelpClass = L"InboxClassicHelp";
// the help context a dialog was made with (HelpScope), as a window property
const wchar_t* kContextProperty = L"InboxClassic.HelpContext";
// the pages of this platform: its keys, its words, the parts of the others left out
const char* kPlatform = "windows";
// the link of a page to another topic, opened once WebView2's event is over
constexpr UINT WM_HELP_LINK = WM_APP + 70;
// the gap between the panes that drags as the splitter, and the margin around them, at 96 DPI
constexpr int kGap = 5;
constexpr int kMargin = 4;

// the context of the dialogs made now (HelpScope), null outside one
const char* g_scope = nullptr;

struct Topic {
    std::string id;
    HTREEITEM item = nullptr;
};

struct HelpWindow {
    HWND hwnd = nullptr;
    HWND toolbar = nullptr;
    HWND tabs = nullptr;
    HWND tree = nullptr;
    // the Search tab: what it says above the box, the box, its button, the topics found, and "nothing found"
    HWND prompt = nullptr;
    HWND query = nullptr;
    HWND search = nullptr;
    HWND results = nullptr;
    HWND none = nullptr;
    // the parent of the WebView2, which shows why when it cannot start
    HWND host = nullptr;
    Preview* preview = nullptr;
    // the topics of the contents in order, each with its row of the tree
    std::vector<Topic> topics;
    // the ids of the topics found, a row of the results each
    std::vector<std::string> found;
    // the topics shown, and which of them is shown now
    std::vector<std::string> history;
    size_t at = 0;
    // a search was made: an empty list then says nothing was found
    bool searched = false;
    // the topic of a link clicked, until WM_HELP_LINK opens it
    std::string link;
    // the left pane shown, and how wide it is at 96 DPI
    bool pane = true;
    int paneWidth = 250;
    bool dragging = false;
    // the tree selected the topic shown: no topic to open for that
    bool following = false;
};

HelpWindow g_window;

// ---- what is shown ----

void UpdateButtons() {
    HelpWindow& w = g_window;
    SendMessageW(w.toolbar, TB_ENABLEBUTTON, IDC_HELP_BACK, MAKELPARAM(w.at > 0 && !w.history.empty(), 0));
    SendMessageW(w.toolbar, TB_ENABLEBUTTON, IDC_HELP_FORWARD, MAKELPARAM(w.at + 1 < w.history.size(), 0));
}

// the row of the topic shown selected in the contents, its section opened
void FollowInTree(const std::string& id) {
    HelpWindow& w = g_window;
    auto topic = std::find_if(w.topics.begin(), w.topics.end(), [&](const Topic& t) { return t.id == id; });
    if (topic == w.topics.end()) {
        return;
    }
    w.following = true;
    TreeView_SelectItem(w.tree, topic->item);
    TreeView_EnsureVisible(w.tree, topic->item);
    w.following = false;
}

void ShowPage(const std::string& id) {
    HelpWindow& w = g_window;
    core::String page(pe_help_topic(kPlatform, id.c_str()));
    w.preview->Show(page ? core::Widen(page.get()) : L"<p>" + core::T(PE_TEXT_UI_HELP_MISSING) + L"</p>");
    FollowInTree(id);
    UpdateButtons();
}

// the topic `id` shown, after the one shown now in the history (what was ahead of it is forgotten)
void Open(const std::string& id) {
    HelpWindow& w = g_window;
    if (!w.history.empty() && w.history[w.at] == id) {
        FollowInTree(id);
        return;
    }
    if (!w.history.empty()) {
        w.history.resize(w.at + 1);
    }
    w.history.push_back(id);
    w.at = w.history.size() - 1;
    ShowPage(id);
}

void Step(int by) {
    HelpWindow& w = g_window;
    if ((by < 0 && w.at == 0) || (by > 0 && w.at + 1 >= w.history.size())) {
        return;
    }
    w.at = by < 0 ? w.at - 1 : w.at + 1;
    ShowPage(w.history[w.at]);
}

// ---- the left pane ----

void FillContents() {
    HelpWindow& w = g_window;
    PeHelpList* list = pe_help_contents(kPlatform);
    std::string section;
    HTREEITEM parent = TVI_ROOT;
    size_t count = pe_help_list_count(list);
    for (size_t i = 0; i < count; i++) {
        const PeHelpRow* row = pe_help_list_get(list, i);
        std::string title = row->section ? row->section : "";
        if (parent == TVI_ROOT || title != section) {
            section = title;
            std::wstring text = core::Widen(title);
            TVINSERTSTRUCTW insert = {};
            insert.hParent = TVI_ROOT;
            insert.hInsertAfter = TVI_LAST;
            insert.item.mask = TVIF_TEXT | TVIF_PARAM;
            insert.item.pszText = text.data();
            insert.item.lParam = 0;
            parent = TreeView_InsertItem(w.tree, &insert);
        }
        std::wstring text = Text(row->title);
        TVINSERTSTRUCTW insert = {};
        insert.hParent = parent;
        insert.hInsertAfter = TVI_LAST;
        insert.item.mask = TVIF_TEXT | TVIF_PARAM;
        insert.item.pszText = text.data();
        // the topic's place in `topics`, plus one: 0 is a section
        insert.item.lParam = static_cast<LPARAM>(w.topics.size() + 1);
        HTREEITEM item = TreeView_InsertItem(w.tree, &insert);
        w.topics.push_back({row->topic ? row->topic : "", item});
    }
    pe_help_list_free(list);
}

// the Contents (0) or the Search (1) tab's controls shown
void ShowTab(int tab) {
    HelpWindow& w = g_window;
    TabCtrl_SetCurSel(w.tabs, tab);
    int contents = tab == 0 && w.pane ? SW_SHOW : SW_HIDE;
    int search = tab == 1 && w.pane ? SW_SHOW : SW_HIDE;
    ShowWindow(w.tree, contents);
    for (HWND control : {w.prompt, w.query, w.search, w.results}) {
        ShowWindow(control, search);
    }
    ShowWindow(w.none, search == SW_SHOW && w.searched && w.found.empty() ? SW_SHOW : SW_HIDE);
}

// the topics with every word of the box listed, the best first
void Search() {
    HelpWindow& w = g_window;
    std::string words = core::Narrow(GetWindowString(w.query));
    PeHelpList* list = pe_help_search(kPlatform, words.c_str());
    SendMessageW(w.results, LB_RESETCONTENT, 0, 0);
    w.found.clear();
    size_t count = pe_help_list_count(list);
    for (size_t i = 0; i < count; i++) {
        const PeHelpRow* row = pe_help_list_get(list, i);
        w.found.push_back(row->topic ? row->topic : "");
        SendMessageW(w.results, LB_ADDSTRING, 0, reinterpret_cast<LPARAM>(Text(row->title).c_str()));
    }
    pe_help_list_free(list);
    w.searched = words.find_first_not_of(" \t") != std::string::npos;
    ShowTab(1);
    SetFocus(w.found.empty() ? w.query : w.results);
}

// ---- layout ----

int ToolbarHeight() {
    RECT bar;
    GetWindowRect(g_window.toolbar, &bar);
    return bar.bottom - bar.top;
}

// the left pane's right edge in the client area, where the splitter starts
int PaneRight() {
    return Scale(kMargin) + Scale(g_window.paneWidth);
}

void Layout() {
    HelpWindow& w = g_window;
    SendMessageW(w.toolbar, TB_AUTOSIZE, 0, 0);
    RECT client;
    GetClientRect(w.hwnd, &client);
    int margin = Scale(kMargin);
    int top = ToolbarHeight() + margin;
    int bottom = std::max(top, static_cast<int>(client.bottom) - margin);
    int left = margin;
    if (w.pane) {
        int right = PaneRight();
        MoveWindow(w.tabs, left, top, right - left, bottom - top, TRUE);
        RECT inside = {left, top, right, bottom};
        TabCtrl_AdjustRect(w.tabs, FALSE, &inside);
        InflateRect(&inside, -Scale(2), -Scale(2));
        MoveWindow(w.tree, inside.left, inside.top, inside.right - inside.left, inside.bottom - inside.top, TRUE);
        int line = Scale(14);
        int box = Scale(21);
        int button = Scale(25);
        int width = inside.right - inside.left;
        int y = inside.top;
        MoveWindow(w.prompt, inside.left, y, width, line, TRUE);
        y += line + Scale(2);
        MoveWindow(w.query, inside.left, y, width, box, TRUE);
        y += box + Scale(6);
        int buttonWidth = ButtonWidth({core::T(PE_TEXT_HELP_SEARCH)});
        MoveWindow(w.search, inside.right - buttonWidth, y, buttonWidth, button, TRUE);
        y += button + Scale(6);
        MoveWindow(w.results, inside.left, y, width, std::max(0, static_cast<int>(inside.bottom) - y), TRUE);
        MoveWindow(w.none, inside.left + Scale(4), y + Scale(4), width - Scale(8), Scale(40), TRUE);
        left = right + Scale(kGap);
    }
    MoveWindow(w.host, left, top, std::max(0, static_cast<int>(client.right) - margin - left), bottom - top, TRUE);
    RECT inner;
    GetClientRect(w.host, &inner);
    w.preview->Resize(inner);
}

bool OverSplitter(POINT point) {
    HelpWindow& w = g_window;
    if (!w.pane) {
        return false;
    }
    int right = PaneRight();
    return point.x >= right && point.x < right + Scale(kGap) && point.y >= ToolbarHeight();
}

void SetPane(bool shown) {
    HelpWindow& w = g_window;
    w.pane = shown;
    ShowWindow(w.tabs, shown ? SW_SHOW : SW_HIDE);
    ShowTab(TabCtrl_GetCurSel(w.tabs));
    std::wstring label = core::T(shown ? PE_TEXT_HELP_HIDE : PE_TEXT_HELP_SHOW);
    TBBUTTONINFOW info = {sizeof(info)};
    info.dwMask = TBIF_TEXT;
    info.pszText = label.data();
    SendMessageW(w.toolbar, TB_SETBUTTONINFOW, IDC_HELP_PANE, reinterpret_cast<LPARAM>(&info));
    Layout();
}

void Print() {
    g_window.preview->Print();
}

// ---- the window ----

// Enter in the search box searches, also where no dialog loop gives the window the key
LRESULT CALLBACK QueryProc(HWND hwnd, UINT message, WPARAM wParam, LPARAM lParam, UINT_PTR, DWORD_PTR) {
    if (message == WM_KEYDOWN && wParam == VK_RETURN) {
        Search();
        return 0;
    }
    if (message == WM_CHAR && wParam == L'\r') {
        return 0;
    }
    return DefSubclassProc(hwnd, message, wParam, lParam);
}

void CreateControls(HWND hwnd) {
    HelpWindow& w = g_window;
    // a classic toolbar of words, as HTML Help had it
    w.toolbar = CreateWindowExW(0, TOOLBARCLASSNAMEW, nullptr, WS_CHILD | WS_VISIBLE | TBSTYLE_FLAT | TBSTYLE_LIST | CCS_TOP, 0, 0, 0, 0, hwnd,
                                reinterpret_cast<HMENU>(static_cast<INT_PTR>(IDC_HELP_TOOLBAR)), GetModuleHandleW(nullptr), nullptr);
    SendMessageW(w.toolbar, TB_BUTTONSTRUCTSIZE, sizeof(TBBUTTON), 0);
    SendMessageW(w.toolbar, WM_SETFONT, reinterpret_cast<WPARAM>(GetStockObject(DEFAULT_GUI_FONT)), FALSE);
    struct Button {
        WORD id;
        PeText text;
    };
    const Button buttons[] = {{IDC_HELP_PANE, PE_TEXT_HELP_HIDE}, {0, PE_TEXT_HELP_HIDE},       {IDC_HELP_BACK, PE_TEXT_HELP_BACK},
                              {IDC_HELP_FORWARD, PE_TEXT_HELP_FORWARD}, {IDC_HELP_HOME, PE_TEXT_HELP_HOME}, {0, PE_TEXT_HELP_HIDE},
                              {IDC_HELP_PRINT, PE_TEXT_HELP_PRINT}};
    for (const Button& button : buttons) {
        std::wstring label = button.id ? core::T(button.text) : std::wstring();
        AddButton(w.toolbar, button.id, button.id ? label.c_str() : nullptr);
    }
    SendMessageW(w.toolbar, TB_AUTOSIZE, 0, 0);

    // the tab control under the pages' controls, which are its siblings
    w.tabs = CreateChild(hwnd, WC_TABCONTROLW, nullptr, WS_CLIPSIBLINGS | WS_TABSTOP, IDC_HELP_TABS, {});
    std::wstring names[] = {core::T(PE_TEXT_HELP_CONTENTS), core::T(PE_TEXT_HELP_SEARCH)};
    for (int i = 0; i < 2; i++) {
        TCITEMW item = {};
        item.mask = TCIF_TEXT;
        item.pszText = names[i].data();
        TabCtrl_InsertItem(w.tabs, i, &item);
    }
    w.tree = CreateChild(hwnd, WC_TREEVIEWW, nullptr,
                         WS_TABSTOP | TVS_HASBUTTONS | TVS_HASLINES | TVS_LINESATROOT | TVS_SHOWSELALWAYS | TVS_SINGLEEXPAND, IDC_HELP_TREE,
                         {}, WS_EX_CLIENTEDGE);
    w.prompt = CreateChild(hwnd, L"STATIC", core::T(PE_TEXT_HELP_SEARCH_PLACEHOLDER).c_str(), SS_NOPREFIX, 0, {});
    w.query = CreateChild(hwnd, L"EDIT", nullptr, WS_TABSTOP | ES_AUTOHSCROLL, IDC_HELP_QUERY, {}, WS_EX_CLIENTEDGE);
    SetWindowSubclass(w.query, QueryProc, 0, 0);
    w.search = CreateChild(hwnd, L"BUTTON", core::T(PE_TEXT_HELP_SEARCH).c_str(), WS_TABSTOP | BS_DEFPUSHBUTTON, IDC_HELP_SEARCH, {});
    w.results = CreateChild(hwnd, L"LISTBOX", nullptr, WS_TABSTOP | WS_VSCROLL | LBS_NOTIFY | LBS_NOINTEGRALHEIGHT, IDC_HELP_RESULTS, {},
                            WS_EX_CLIENTEDGE);
    // "nothing found" over the empty list
    w.none = CreateChild(hwnd, L"STATIC", core::T(PE_TEXT_HELP_NO_RESULTS).c_str(), SS_NOPREFIX, IDC_HELP_NONE, {});
    SetWindowPos(w.none, HWND_TOP, 0, 0, 0, 0, SWP_NOMOVE | SWP_NOSIZE);
    SetWindowPos(w.tabs, HWND_BOTTOM, 0, 0, 0, 0, SWP_NOMOVE | SWP_NOSIZE);
    FillContents();

    w.host = CreateChild(hwnd, L"STATIC", nullptr, WS_CLIPCHILDREN, 0, {}, WS_EX_CLIENTEDGE);
    w.preview = new Preview();
    w.preview->KeepOwnSize();
    w.preview->Create(w.host, [](const std::wstring& error) { SetWindowTextW(g_window.host, error.c_str()); });
    // a link to another topic opens it here, once WebView2's event is over; any other goes to the browser
    w.preview->SetLinks([](const wchar_t* uri) {
        core::String topic(pe_help_link_topic(core::Narrow(uri).c_str()));
        if (!topic) {
            return false;
        }
        g_window.link = topic.get();
        PostMessageW(g_window.hwnd, WM_HELP_LINK, 0, 0);
        return true;
    });
    ShowTab(0);
}

void OnCommand(WORD id, WORD code) {
    HelpWindow& w = g_window;
    switch (id) {
    case IDC_HELP_PANE:
        SetPane(!w.pane);
        break;
    case IDC_HELP_BACK:
        Step(-1);
        break;
    case IDC_HELP_FORWARD:
        Step(1);
        break;
    case IDC_HELP_HOME: {
        core::String home(pe_help_context("main"));
        if (home) {
            Open(home.get());
        }
        break;
    }
    case IDC_HELP_PRINT:
        Print();
        break;
    case IDOK:
        // Enter, which the dialog loop turns into OK: a search from the search box only
        if (GetFocus() == w.query) {
            Search();
        }
        break;
    case IDC_HELP_SEARCH:
        if (code == BN_CLICKED) {
            Search();
        }
        break;
    case IDC_HELP_RESULTS:
        if (code == LBN_SELCHANGE || code == LBN_DBLCLK) {
            LRESULT row = SendMessageW(w.results, LB_GETCURSEL, 0, 0);
            if (row >= 0 && static_cast<size_t>(row) < w.found.size()) {
                Open(w.found[static_cast<size_t>(row)]);
            }
        }
        break;
    }
}

LRESULT OnNotify(NMHDR* header) {
    HelpWindow& w = g_window;
    if (header->hwndFrom == w.tabs && header->code == TCN_SELCHANGE) {
        int tab = TabCtrl_GetCurSel(w.tabs);
        ShowTab(tab);
        SetFocus(tab == 0 ? w.tree : w.query);
    } else if (header->hwndFrom == w.tree && header->code == TVN_SELCHANGEDW && !w.following) {
        auto* changed = reinterpret_cast<NMTREEVIEWW*>(header);
        size_t index = static_cast<size_t>(changed->itemNew.lParam);
        if (index > 0 && index <= w.topics.size()) {
            Open(w.topics[index - 1].id);
        }
    }
    return 0;
}

LRESULT CALLBACK HelpProc(HWND hwnd, UINT message, WPARAM wParam, LPARAM lParam) {
    HelpWindow& w = g_window;
    switch (message) {
    case WM_SIZE:
        if (wParam != SIZE_MINIMIZED) {
            Layout();
        }
        return 0;
    case WM_COMMAND:
        OnCommand(LOWORD(wParam), HIWORD(wParam));
        return 0;
    case WM_NOTIFY:
        return OnNotify(reinterpret_cast<NMHDR*>(lParam));
    case DM_GETDEFID:
        // Enter in the search box (the dialog loop asks the window) is the Search button
        return GetFocus() == w.query ? MAKELRESULT(IDC_HELP_SEARCH, DC_HASDEFID) : 0;
    case WM_HELP_LINK:
        if (!w.link.empty()) {
            Open(std::exchange(w.link, {}));
        }
        return 0;
    case WM_SETFOCUS:
        if (!w.pane) {
            w.preview->Focus(Preview::FocusFrom::Program);
        } else {
            SetFocus(TabCtrl_GetCurSel(w.tabs) == 0 ? w.tree : w.query);
        }
        return 0;
    case WM_CTLCOLORSTATIC:
        return ButtonFaceColor(reinterpret_cast<HDC>(wParam));
    case WM_SETCURSOR: {
        POINT point;
        GetCursorPos(&point);
        ScreenToClient(hwnd, &point);
        if (reinterpret_cast<HWND>(wParam) == hwnd && OverSplitter(point)) {
            SetCursor(LoadCursorW(nullptr, IDC_SIZEWE));
            return TRUE;
        }
        break;
    }
    case WM_LBUTTONDOWN: {
        POINT point = {static_cast<short>(LOWORD(lParam)), static_cast<short>(HIWORD(lParam))};
        w.dragging = OverSplitter(point);
        if (w.dragging) {
            SetCapture(hwnd);
        }
        return 0;
    }
    case WM_MOUSEMOVE:
        if (w.dragging) {
            int x = static_cast<short>(LOWORD(lParam)) - Scale(kMargin);
            RECT client;
            GetClientRect(hwnd, &client);
            int dpi = static_cast<int>(GetDpiForWindow(hwnd));
            int most = std::max(160, MulDiv(client.right, 96, dpi) - 200);
            w.paneWidth = std::clamp(MulDiv(x, 96, dpi), 140, most);
            Layout();
        }
        return 0;
    case WM_LBUTTONUP:
    case WM_CAPTURECHANGED:
        if (w.dragging) {
            w.dragging = false;
            if (message == WM_LBUTTONUP) {
                ReleaseCapture();
            }
        }
        return 0;
    case WM_DESTROY: {
        if (w.preview) {
            w.preview->Close();
            delete w.preview;
        }
        // the next window starts as a new one, the pane as wide as it was
        int paneWidth = w.paneWidth;
        w = HelpWindow{};
        w.paneWidth = paneWidth;
        return 0;
    }
    }
    return DefWindowProcW(hwnd, message, wParam, lParam);
}

bool CreateHelpWindow() {
    static bool registered = false;
    if (!registered) {
        WNDCLASSEXW windowClass = {sizeof(windowClass)};
        windowClass.lpfnWndProc = HelpProc;
        windowClass.hInstance = GetModuleHandleW(nullptr);
        windowClass.hCursor = LoadCursorW(nullptr, IDC_ARROW);
        SetAppIcons(windowClass);
        windowClass.hbrBackground = reinterpret_cast<HBRUSH>(COLOR_BTNFACE + 1);
        windowClass.lpszClassName = kHelpClass;
        RegisterClassExW(&windowClass);
        registered = true;
    }
    // not owned by the main window: the help stays usable while a dialog of the main window is open
    HWND hwnd = CreateWindowExW(WS_EX_CONTROLPARENT, kHelpClass, core::Plain(PE_TEXT_HELP_TITLE).c_str(), WS_OVERLAPPEDWINDOW | WS_CLIPCHILDREN,
                                CW_USEDEFAULT, CW_USEDEFAULT, Scale(940), Scale(700), nullptr, nullptr, GetModuleHandleW(nullptr), nullptr);
    if (!hwnd) {
        return false;
    }
    g_window.hwnd = hwnd;
    CreateControls(hwnd);
    Layout();
    ShowWindow(hwnd, SW_SHOW);
    return true;
}

// the context of the window F1 was pressed in: its own, or that of the window that owns it, the main window's when
// none has one; null in the help itself
const char* ContextOf(HWND window) {
    for (HWND at = GetAncestor(window, GA_ROOT); at; at = GetWindow(at, GW_OWNER)) {
        if (at == g_window.hwnd) {
            return nullptr;
        }
        if (auto context = static_cast<const char*>(GetPropW(at, kContextProperty))) {
            return context;
        }
        wchar_t name[64] = L"";
        GetClassNameW(at, name, 64);
        if (wcscmp(name, L"InboxClassicCompose") == 0) {
            return "compose";
        }
        if (wcscmp(name, L"InboxClassicAddressBook") == 0) {
            return "address-book";
        }
    }
    return "main";
}

}  // namespace

HelpScope::HelpScope(const char* context) : previous_(std::exchange(g_scope, context)) {}

HelpScope::~HelpScope() {
    g_scope = previous_;
}

void SetHelpContext(HWND window) {
    if (g_scope) {
        SetPropW(window, kContextProperty, const_cast<char*>(g_scope));
    }
}

void ClearHelpContext(HWND window) {
    RemovePropW(window, kContextProperty);
}

void OpenHelp(const char* context) {
    core::String topic(pe_help_context(context));
    if (!topic) {
        return;
    }
    if (g_window.hwnd) {
        if (IsIconic(g_window.hwnd)) {
            ShowWindow(g_window.hwnd, SW_RESTORE);
        }
        SetForegroundWindow(g_window.hwnd);
    } else if (!CreateHelpWindow()) {
        return;
    }
    Open(topic.get());
}

void HelpKey(HWND window) {
    if (const char* context = ContextOf(window)) {
        OpenHelp(context);
    }
}

void CloseHelp() {
    if (g_window.hwnd) {
        DestroyWindow(g_window.hwnd);
    }
}
