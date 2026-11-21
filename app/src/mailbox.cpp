// The folder tree, the message list and the reading pane. The list is virtual: rows come from the core a page at a
// time when the list view asks for them. Every string shown was decoded by the core; the message body is the
// sanitized document the core made, shown in the WebView2 as it is.
#include "app.h"
#include "icons.h"
#include "webview.h"

#include <commdlg.h>
#include <shellapi.h>
#include <shlwapi.h>

#include <algorithm>
#include <cwctype>
#include <filesystem>
#include <fstream>
#include <limits>
#include <span>
#include <string_view>
#include <thread>
#include <utility>

namespace {

// a folder name, asked for; empty when cancelled
std::wstring AskFolderName(HWND owner, PeText title, const std::wstring& intro, const std::wstring& name) {
    std::vector<FormField> fields = {{core::T(PE_TEXT_UI_FOLDER_NAME), name}};
    return FormDialog(owner, core::Title(title), intro, fields) ? fields[0].value : L"";
}

// the reason the core gave, shown
void ShowRefusal(HWND owner, char* reason, PeText fallback) {
    MessageBoxW(owner, ReasonText(reason, fallback).c_str(), L"Inbox Classic", MB_OK | MB_ICONWARNING);
}

// Tools > Options: a row a conversation (on unless turned off)
const wchar_t* kThreadsPreference = L"GroupByConversation";
// View > Hide Ignored Conversations (off unless turned on)
const wchar_t* kHideIgnoredPreference = L"HideIgnoredConversations";
const wchar_t* kUnreadOnlyPreference = L"HideReadMessages";
// Tools > Options > Show senders' pictures in the message list (on unless turned off)
const wchar_t* kListPicturesPreference = L"ListPictures";

constexpr uint64_t kPageSize = 100;
// pages kept around while the list scrolls
constexpr size_t kPagesKept = 8;
// the keys of the rows of the tree the user opened or closed the other way than they start, kept for the next start
// ("inboxes", "sent", "account:3"; versions before kept "all" for All Inboxes and the ids of closed accounts)
const wchar_t* kClosedRowsPreference = L"ClosedFolderRows";

// as Outlook Express has them: the paper clip, the flag and the Watch column (glasses, or the sign of an ignored
// conversation), then the text columns; no read and unread column: bold says it
enum Column { COL_ATTACH, COL_FLAG, COL_SECURE, COL_FROM, COL_SUBJECT, COL_RECEIVED, COL_FOLDER };

// what the Find box takes, shown when the mouse rests on it: the words of the query syntax are the same in every
// language
const wchar_t* kFindSyntax =
    L"\"exact phrase\"    -leave out    this OR that\r\n"
    L"from:ann    to:bob    subject:report    filename:pdf\r\n"
    L"is:unread    is:read    is:starred    has:attachment\r\n"
    L"in:inbox    in:sent    in:anywhere    in:<folder name>\r\n"
    L"before:2025/01/31    after:2025/01/01    older_than:2d    newer_than:1m\r\n"
    L"larger:5M    smaller:100k";


// the Find box: as an edit, with the grey hint drawn over it while it is empty and not focused
LRESULT CALLBACK FindEditProc(HWND hwnd, UINT message, WPARAM wParam, LPARAM lParam, UINT_PTR, DWORD_PTR) {
    LRESULT result = DefSubclassProc(hwnd, message, wParam, lParam);
    if (message == WM_SETFOCUS || message == WM_KILLFOCUS) {
        InvalidateRect(hwnd, nullptr, TRUE);
    } else if (message == WM_PAINT && GetWindowTextLengthW(hwnd) == 0 && GetFocus() != hwnd) {
        HDC dc = GetDC(hwnd);
        HGDIOBJ old = SelectObject(dc, reinterpret_cast<HFONT>(SendMessageW(hwnd, WM_GETFONT, 0, 0)));
        SetTextColor(dc, GetSysColor(COLOR_GRAYTEXT));
        SetBkMode(dc, TRANSPARENT);
        RECT area;
        GetClientRect(hwnd, &area);
        area.left += LOWORD(SendMessageW(hwnd, EM_GETMARGINS, 0, 0));
        DrawTextW(dc, core::T(PE_TEXT_UI_FIND_HINT).c_str(), -1, &area, DT_LEFT | DT_VCENTER | DT_SINGLELINE | DT_NOPREFIX);
        SelectObject(dc, old);
        ReleaseDC(hwnd, dc);
    }
    return result;
}

// the search field: the window the Find box, its magnifier and its clear button are in. A click anywhere in it gives
// the box the focus; what its controls send goes on to the main window
LRESULT CALLBACK FindFieldProc(HWND hwnd, UINT message, WPARAM wParam, LPARAM lParam) {
    switch (message) {
    case WM_LBUTTONDOWN:
        SendMessageW(GetParent(hwnd), WM_COMMAND, MAKEWPARAM(IDC_FIND_FIELD, STN_CLICKED), reinterpret_cast<LPARAM>(hwnd));
        return 0;
    case WM_SETCURSOR:
        if (reinterpret_cast<HWND>(wParam) == hwnd || GetDlgCtrlID(reinterpret_cast<HWND>(wParam)) == IDC_FIND_ICON) {
            SetCursor(LoadCursorW(nullptr, IDC_IBEAM));
            return TRUE;
        }
        break;
    case WM_COMMAND:
    case WM_DRAWITEM:
    case WM_CTLCOLOREDIT:
    case WM_CTLCOLORSTATIC:
    case WM_CTLCOLORBTN:
        return SendMessageW(GetParent(hwnd), message, wParam, lParam);
    }
    return DefWindowProcW(hwnd, message, wParam, lParam);
}

HWND CreateFindField(HWND parent) {
    static bool registered = false;
    if (!registered) {
        WNDCLASSEXW windowClass = {sizeof(windowClass)};
        windowClass.lpfnWndProc = FindFieldProc;
        windowClass.hInstance = GetModuleHandleW(nullptr);
        windowClass.hCursor = LoadCursorW(nullptr, IDC_IBEAM);
        windowClass.hbrBackground = reinterpret_cast<HBRUSH>(COLOR_WINDOW + 1);
        windowClass.lpszClassName = L"InboxClassicSearchField";
        RegisterClassExW(&windowClass);
        registered = true;
    }
    // a control parent, so Tab goes into its box
    return CreateChild(parent, L"InboxClassicSearchField", L"", WS_CLIPCHILDREN, IDC_FIND_FIELD, {}, WS_EX_CLIENTEDGE | WS_EX_CONTROLPARENT);
}

// the data of a tree row: its index in the rows of the tree, -1 for none
LPARAM RowData(HWND tree, HTREEITEM item) {
    TVITEMW data = {};
    data.mask = TVIF_PARAM;
    data.hItem = item;
    return TreeView_GetItem(tree, &data) ? data.lParam : -1;
}

// a row's name with an unread count after it, when there is one
std::wstring CountedLabel(const std::wstring& name, uint64_t unread) {
    return unread > 0 ? name + L" (" + std::to_wstring(unread) + L")" : name;
}

PeSortField SortOf(int column) {
    switch (column) {
    case COL_FROM:
        return PE_SORT_FIELD_FROM;
    case COL_SUBJECT:
        return PE_SORT_FIELD_SUBJECT;
    default:
        return PE_SORT_FIELD_DATE;
    }
}

// the message list: its keys and clicks for the conversations first
LRESULT CALLBACK ListProc(HWND hwnd, UINT message, WPARAM wParam, LPARAM lParam, UINT_PTR, DWORD_PTR data) {
    if (reinterpret_cast<Mailbox*>(data)->OnListInput(message, wParam, lParam)) {
        return 0;
    }
    LRESULT result = DefSubclassProc(hwnd, message, wParam, lParam);
    // the selected rows change colour with the focus, the start of their first column too
    if (message == WM_SETFOCUS || message == WM_KILLFOCUS) {
        InvalidateRect(hwnd, nullptr, FALSE);
    }
    return result;
}

// the columns that show an icon of the list strip in their header and nothing else, and what each stands for (its
// header's tooltip, the same word on every platform); a click on one sorts nothing
struct IconColumnOf {
    int column;
    int icon;
    PeText tip;
};
constexpr IconColumnOf kIconColumns[] = {
    {COL_ATTACH, LIST_ATTACH, PE_TEXT_UI_ROW_ATTACHMENTS},
    {COL_FLAG, LIST_FLAG, PE_TEXT_UI_ROW_FLAGGED},
    {COL_SECURE, LIST_LOCK_CLOSED, PE_TEXT_HEADER_SECURITY},
};

bool IsIconColumn(int column) {
    return std::ranges::any_of(kIconColumns, [column](const IconColumnOf& icon) { return icon.column == column; });
}

// a column that shows an icon of the list strip in its header (the paper clip, the flag, the lock) and nothing else
void IconColumn(HWND list, int index, int icon) {
    AddColumn(list, index, L"", 28);
    LVCOLUMNW column = {};
    column.mask = LVCF_FMT | LVCF_IMAGE;
    column.fmt = LVCFMT_IMAGE;
    column.iImage = icon;
    ListView_SetColumn(list, index, &column);
}

}  // namespace

HTREEITEM InsertItem(HWND tree, HTREEITEM parent, const std::wstring& text, LPARAM data, bool bold, int icon) {
    TVINSERTSTRUCTW insert = {};
    insert.hParent = parent;
    insert.hInsertAfter = TVI_LAST;
    insert.item.mask = TVIF_TEXT | TVIF_PARAM | TVIF_STATE | TVIF_IMAGE | TVIF_SELECTEDIMAGE;
    insert.item.iImage = icon;
    insert.item.iSelectedImage = icon;
    insert.item.pszText = const_cast<wchar_t*>(text.c_str());
    insert.item.lParam = data;
    insert.item.stateMask = TVIS_BOLD;
    insert.item.state = bold ? TVIS_BOLD : 0;
    return TreeView_InsertItem(tree, &insert);
}


void Mailbox::Create(HWND parent, PeCore* core) {
    parent_ = parent;
    core_ = core;
    tree_ = CreateChild(parent, WC_TREEVIEWW, nullptr,
                        WS_TABSTOP | TVS_HASLINES | TVS_HASBUTTONS | TVS_LINESATROOT | TVS_SHOWSELALWAYS, IDC_TREE, {},
                        WS_EX_CLIENTEDGE);
    list_ = CreateChild(parent, WC_LISTVIEWW, nullptr,
                        WS_TABSTOP | LVS_REPORT | LVS_SHOWSELALWAYS | LVS_OWNERDATA, IDC_LIST, {},
                        WS_EX_CLIENTEDGE);
    ListView_SetExtendedListViewStyle(list_, LVS_EX_FULLROWSELECT);
    SetWindowSubclass(list_, ListProc, 0, reinterpret_cast<DWORD_PTR>(this));
    pe_list_view_set_grouped(view_.get(), GetPreference(kThreadsPreference, 1) != 0);
    hideIgnored_ = GetPreference(kHideIgnoredPreference, 0) != 0;
    pe_list_view_set_hide_ignored(view_.get(), hideIgnored_);
    unreadOnly_ = GetPreference(kUnreadOnlyPreference, 0) != 0;
    pictures_.Init(core);
    listPictures_ = GetPreference(kListPicturesPreference, 1) != 0;
    pe_list_view_set_show(view_.get(), unreadOnly_ ? PE_SHOW_UNREAD : PE_SHOW_ALL);
    // the icons of the list: for the headers of the paper clip and flag columns, and drawn on the rows in CustomDraw
    listIcons_ = IconList(IconSet::List);
    ImageList_GetIconSize(listIcons_, &iconSize_, &iconSize_);
    ListView_SetImageList(list_, listIcons_, LVSIL_SMALL);
    TreeView_SetImageList(tree_, IconList(IconSet::Folders), TVSIL_NORMAL);
    // messages dragged onto a folder, .eml files dragged onto a folder or the list
    treeSite_.mailbox = this;
    listSite_.mailbox = this;
    treeTarget_ = RegisterDropSite(tree_, &treeSite_);
    listTarget_ = RegisterDropSite(list_, &listSite_);
    // the search field: a white sunken window with the magnifier, the box without a border of its own, and the clear
    // button once there is something to clear
    findField_ = CreateFindField(parent);
    findIcon_ = CreateChild(findField_, L"STATIC", L"", SS_OWNERDRAW, IDC_FIND_ICON, {});
    findEdit_ = CreateChild(findField_, L"EDIT", L"", WS_TABSTOP | ES_AUTOHSCROLL, IDC_FIND, {});
    SetWindowSubclass(findEdit_, FindEditProc, 0, 0);
    // what a screen reader says for it
    SetAccessibleDescription(findEdit_, core::T(PE_TEXT_UI_FIND_HINT));
    findClear_ = CreateChild(findField_, L"BUTTON", core::T(PE_TEXT_UI_CLEAR_SEARCH).c_str(), BS_OWNERDRAW, IDC_FIND_CLEAR, {});
    ShowWindow(findClear_, SW_HIDE);
    // what the box takes, when the mouse rests on it
    HWND tip = CreateWindowExW(WS_EX_TOPMOST, TOOLTIPS_CLASSW, nullptr, WS_POPUP | TTS_ALWAYSTIP | TTS_NOPREFIX, CW_USEDEFAULT,
                               CW_USEDEFAULT, CW_USEDEFAULT, CW_USEDEFAULT, parent, nullptr, GetModuleHandleW(nullptr), nullptr);
    SendMessageW(tip, TTM_SETMAXTIPWIDTH, 0, Scale(520));
    SendMessageW(tip, TTM_SETDELAYTIME, TTDT_AUTOPOP, 30000);
    TOOLINFOW tool = {sizeof(tool)};
    tool.uFlags = TTF_IDISHWND | TTF_SUBCLASS;
    tool.hwnd = parent;
    // the tooltip keeps a copy
    std::wstring findTip = core::T(PE_TEXT_UI_FIND_TIP) + L"\r\n" + kFindSyntax;
    tool.lpszText = findTip.data();
    for (HWND window : {findField_, findEdit_}) {
        tool.uId = reinterpret_cast<UINT_PTR>(window);
        SendMessageW(tip, TTM_ADDTOOLW, 0, reinterpret_cast<LPARAM>(&tool));
    }
    // the Columns layout's "Sorted by" over the list (SetColumns shows it)
    sortButton_ = CreateChild(parent, L"BUTTON", SortedByText().c_str(), WS_TABSTOP | BS_OWNERDRAW, IDC_SORT_BUTTON, {});
    ShowWindow(sortButton_, SW_HIDE);
    for (const IconColumnOf& icon : kIconColumns) {
        IconColumn(list_, icon.column, icon.icon);
    }
    AddHeaderTips();
    AddColumn(list_, COL_FROM, core::T(PE_TEXT_UI_COL_FROM).c_str(), 200);
    AddColumn(list_, COL_SUBJECT, core::T(PE_TEXT_UI_COL_SUBJECT).c_str(), 320);
    AddColumn(list_, COL_RECEIVED, core::T(PE_TEXT_UI_COL_RECEIVED).c_str(), 130);
    UpdateSortArrow();

    reader_.Create(parent, core);
    reader_.onShown = [this] { OnMessageShown(); };
    reader_.onFound = [this](const std::wstring& said) { Say(said); };
    reader_.onBouncedMessage = [this](int64_t folder, uint64_t uid) { ShowMessage(folder, uid); };
    // the keys for reading also while the message has the keyboard, sent as the accelerators send them
    reader_.SetKeys([parent](UINT key) {
        WORD id = ReadingKey(key);
        if (id) {
            PostMessageW(parent, WM_COMMAND, MAKEWPARAM(id, 1), 0);
        }
        return id != 0;
    });
    // over the list while searching, in the colors of the information bar: what was found, and the push buttons that
    // make a rule of it and end it
    searchBar_ = CreateChild(parent, L"STATIC", L"", SS_OWNERDRAW | WS_BORDER | WS_CLIPSIBLINGS, IDC_SEARCH_BAR, {});
    searchClear_ = CreateChild(parent, L"BUTTON", core::T(PE_TEXT_UI_CLEAR_SEARCH).c_str(), WS_TABSTOP | BS_PUSHBUTTON, IDC_SEARCH_CLEAR, {});
    searchRule_ = CreateChild(parent, L"BUTTON", core::Plain(PE_TEXT_UI_CREATE_RULE).c_str(), WS_TABSTOP | BS_PUSHBUTTON, IDC_SEARCH_RULE, {});
    ShowWindow(searchBar_, SW_HIDE);
    ShowWindow(searchClear_, SW_HIDE);
    ShowWindow(searchRule_, SW_HIDE);
    // over the list when the server did not do an action: why, in the core's words, and a button that closes it
    undoneBar_ = CreateChild(parent, L"STATIC", L"", SS_OWNERDRAW | WS_BORDER | WS_CLIPSIBLINGS, IDC_UNDONE_BAR, {});
    undoneClose_ = CreateChild(parent, L"BUTTON", core::T(PE_TEXT_UI_CLOSE).c_str(), WS_TABSTOP | BS_OWNERDRAW, IDC_UNDONE_CLOSE, {});
    ShowWindow(undoneBar_, SW_HIDE);
    ShowWindow(undoneClose_, SW_HIDE);

    LOGFONTW font = {};
    GetObjectW(UiFont(), sizeof(font), &font);
    font.lfWeight = FW_BOLD;
    bold_ = CreateFontIndirectW(&font);
    // the list's own (a stock font, not deleted)
    normal_ = reinterpret_cast<HFONT>(SendMessageW(list_, WM_GETFONT, 0, 0));
    if (!normal_) {
        normal_ = UiFont();
    }
    LOGFONTW listFont = {};
    GetObjectW(normal_, sizeof(listFont), &listFont);
    listFont.lfItalic = TRUE;
    italic_ = CreateFontIndirectW(&listFont);
    ClearReader();
    Reload();
}

// a small triangle pointing up (`up`) or down, in the gray of disabled text on the button face, as the heading draws a
// bitmap on its right: the header of the classic controls has no sort arrows of its own (they come with Common
// Controls 6, which the app leaves out for the classic look)
static HBITMAP SortArrowBitmap(bool up) {
    int width = Scale(9), height = Scale(5);
    HDC screen = GetDC(nullptr);
    HDC dc = CreateCompatibleDC(screen);
    HBITMAP bitmap = CreateCompatibleBitmap(screen, width, height);
    ReleaseDC(nullptr, screen);
    HGDIOBJ old = SelectObject(dc, bitmap);
    RECT all = {0, 0, width, height};
    FillRect(dc, &all, GetSysColorBrush(COLOR_BTNFACE));
    int base = up ? height - 1 : 0, tip = up ? 0 : height - 1;
    POINT points[3] = {{0, base}, {width - 1, base}, {(width - 1) / 2, tip}};
    HGDIOBJ brush = SelectObject(dc, GetSysColorBrush(COLOR_GRAYTEXT));
    HGDIOBJ pen = SelectObject(dc, GetStockObject(NULL_PEN));
    Polygon(dc, points, 3);
    SelectObject(dc, pen);
    SelectObject(dc, brush);
    SelectObject(dc, old);
    DeleteDC(dc);
    return bitmap;
}

void Mailbox::UpdateSortArrow() {
    HWND header = ListView_GetHeader(list_);
    if (!header) {
        return;
    }
    int sorted = -1;
    switch (sort_) {
    case PE_SORT_FIELD_FROM:
        sorted = COL_FROM;
        break;
    case PE_SORT_FIELD_SUBJECT:
        sorted = COL_SUBJECT;
        break;
    case PE_SORT_FIELD_DATE:
    case PE_SORT_FIELD_RECEIVED:
        sorted = COL_RECEIVED;
        break;
    default:
        break;
    }
    HBITMAP& arrow = sortArrows_[ascending_ ? 0 : 1];
    if (!arrow) {
        arrow = SortArrowBitmap(ascending_);
    }
    for (int i = 0, count = Header_GetItemCount(header); i < count; i++) {
        HDITEMW item = {};
        item.mask = HDI_FORMAT;
        Header_GetItem(header, i, &item);
        item.mask = HDI_FORMAT | HDI_BITMAP;
        item.fmt &= ~(HDF_BITMAP | HDF_BITMAP_ON_RIGHT);
        item.hbm = nullptr;
        if (i == sorted) {
            item.fmt |= HDF_BITMAP | HDF_BITMAP_ON_RIGHT;
            item.hbm = arrow;
        }
        Header_SetItem(header, i, &item);
    }
}

void Mailbox::Destroy() {
    for (HBITMAP& arrow : sortArrows_) {
        if (arrow) {
            DeleteObject(std::exchange(arrow, nullptr));
        }
    }
    if (pictureDc_) {
        DeleteDC(std::exchange(pictureDc_, nullptr));
    }
    pictures_.Clear();
    if (rowSpacer_) {
        // the list lets go of it first: it would destroy the image list it has when it goes
        ListView_SetImageList(list_, listIcons_, LVSIL_SMALL);
        ImageList_Destroy(rowSpacer_);
        rowSpacer_ = nullptr;
    }
    RevokeDropSite(tree_, treeTarget_);
    RevokeDropSite(list_, listTarget_);
    CancelLoads();
    reader_.Destroy();
    pages_.clear();
    DeleteObject(bold_);
    bold_ = nullptr;
    DeleteObject(italic_);
    italic_ = nullptr;
}

void Mailbox::Layout(const RECT& tree, const RECT& list, const RECT& reader) {
    // none while the folder list is hidden (or in the folder bar's drop-down)
    if (!IsRectEmpty(&tree)) {
        MoveWindow(tree_, tree.left, tree.top, tree.right - tree.left, tree.bottom - tree.top, TRUE);
    }
    listArea_ = list;
    LayoutList();
    reader_.Layout(reader);
}

// the bar of an action the server did not do at the top of `list`, as tall as its words wrapped to the width left of
// the close button (a line at least); `list` keeps the room under it
void Mailbox::LayoutUndoneBar(RECT& list) {
    if (!IsWindowVisible(undoneBar_)) {
        return;
    }
    int width = list.right - list.left;
    int edge = GetSystemMetrics(SM_CXBORDER), pad = Scale(6), button = Scale(22);
    RECT words = {0, 0, std::max(Scale(80), width - 3 * pad - iconSize_ - button), 0};
    HDC dc = GetDC(undoneBar_);
    HGDIOBJ old = SelectObject(dc, normal_);
    DrawTextW(dc, undoneText_.c_str(), -1, &words, DT_WORDBREAK | DT_NOPREFIX | DT_CALCRECT);
    SelectObject(dc, old);
    ReleaseDC(undoneBar_, dc);
    int height = std::max<int>(Scale(22), words.bottom + Scale(8));
    MoveWindow(undoneBar_, list.left, list.top, width, height, TRUE);
    MoveWindow(undoneClose_, list.right - edge - button, list.top + edge, button, std::min(button, height - 2 * edge), TRUE);
    SetWindowPos(undoneClose_, HWND_TOP, 0, 0, 0, 0, SWP_NOMOVE | SWP_NOSIZE | SWP_NOACTIVATE);
    list.top += height + Scale(2);
}

// the search bar over the list while it is shown, the list under it
void Mailbox::LayoutList() {
    RECT list = listArea_;
    int width = list.right - list.left;
    LayoutUndoneBar(list);
    if (IsWindowVisible(searchBar_)) {
        // as the reading pane's bars, Create Rule left of Clear search
        list.top += PlaceBar(searchBar_, {searchClear_, searchRule_}, list.left, list.top, width) + Scale(2);
    }
    // the Columns list has no headings: "Sorted by" over it says the order, and changes it
    ShowWindow(sortButton_, columns_ ? SW_SHOW : SW_HIDE);
    if (columns_) {
        int height = Scale(20);
        MoveWindow(sortButton_, list.left, list.top, std::min(width, SortButtonWidth()), height, TRUE);
        list.top += height + Scale(2);
    }
    MoveWindow(list_, list.left, list.top, width, list.bottom - list.top, TRUE);
    FitSubjectColumn();
}

void Mailbox::AddHeaderTips() {
    HWND header = ListView_GetHeader(list_);
    headerTip_ = CreateWindowExW(WS_EX_TOPMOST, TOOLTIPS_CLASSW, nullptr, WS_POPUP | TTS_ALWAYSTIP | TTS_NOPREFIX, CW_USEDEFAULT,
                                 CW_USEDEFAULT, CW_USEDEFAULT, CW_USEDEFAULT, parent_, nullptr, GetModuleHandleW(nullptr), nullptr);
    for (const IconColumnOf& icon : kIconColumns) {
        // the classic tooltips take the size of their first version (ui.cpp AddTip): a larger one is refused
        TOOLINFOW tool = {TTTOOLINFOW_V2_SIZE};
        tool.uFlags = TTF_SUBCLASS;
        tool.hwnd = header;
        tool.uId = static_cast<UINT_PTR>(icon.column);
        // the tooltip keeps a copy
        std::wstring text = core::T(icon.tip);
        tool.lpszText = text.data();
        SendMessageW(headerTip_, TTM_ADDTOOLW, 0, reinterpret_cast<LPARAM>(&tool));
    }
    PlaceHeaderTips();
}

void Mailbox::PlaceHeaderTips() {
    HWND header = ListView_GetHeader(list_);
    if (!headerTip_ || !header) {
        return;
    }
    for (const IconColumnOf& icon : kIconColumns) {
        TOOLINFOW tool = {TTTOOLINFOW_V2_SIZE};
        tool.hwnd = header;
        tool.uId = static_cast<UINT_PTR>(icon.column);
        Header_GetItemRect(header, icon.column, &tool.rect);
        SendMessageW(headerTip_, TTM_NEWTOOLRECTW, 0, reinterpret_cast<LPARAM>(&tool));
    }
}

// the Subject column takes the width the other columns leave, so a long subject has the room
void Mailbox::FitSubjectColumn() {
    RECT client;
    GetClientRect(list_, &client);
    HWND header = ListView_GetHeader(list_);
    int count = Header_GetItemCount(header);
    // the Columns rows are drawn whole: the other columns out of the way (their widths kept for Classic), Subject the
    // width of the list, so a click anywhere on a row is on it and nothing scrolls sideways
    if (columns_ || !classicWidths_.empty()) {
        classicWidths_.resize(std::max(classicWidths_.size(), static_cast<size_t>(count)), 0);
        for (int column = 0; column < count; column++) {
            int width = ListView_GetColumnWidth(list_, column);
            if (column == COL_SUBJECT) {
                continue;
            }
            if (columns_ && width > 0) {
                classicWidths_[column] = width;
                ListView_SetColumnWidth(list_, column, 0);
            } else if (!columns_ && classicWidths_[column] > 0) {
                ListView_SetColumnWidth(list_, column, classicWidths_[column]);
            }
        }
        if (columns_) {
            ListView_SetColumnWidth(list_, COL_SUBJECT, static_cast<int>(client.right));
            return;
        }
        classicWidths_.clear();
    }
    int others = 0;
    for (int column = 0; column < count; column++) {
        if (column != COL_SUBJECT) {
            others += ListView_GetColumnWidth(list_, column);
        }
    }
    ListView_SetColumnWidth(list_, COL_SUBJECT, std::max(Scale(120), static_cast<int>(client.right) - others));
}

void Mailbox::UpdateSearchBar() {
    std::wstring summary;
    if (Searching()) {
        // what was found, for what, where: the words stay in view while the list changes under them
        std::wstring count = std::to_wstring(total_);
        if (findPlace_.empty()) {
            summary = core::T(PE_TEXT_WIN_SEARCH_FOUND_ALL, {{"count", count}, {"words", find_}});
        } else {
            summary = core::T(PE_TEXT_WIN_SEARCH_FOUND_IN, {{"count", count}, {"words", find_}, {"folder", findPlace_}});
        }
        if (uint64_t left = pe_search_unindexed_count(core_)) {
            // the words of these are found once their text is in (subjects, people and file names are found already)
            summary += L"  \u00B7  " + core::T(PE_TEXT_WIN_SEARCH_INDEXING, {{"count", std::to_wstring(left)}});
        }
    }
    bool shown = IsWindowVisible(searchBar_) != FALSE;
    if (summary != searchSummary_) {
        searchSummary_ = summary;
        SetWindowTextW(searchBar_, summary.c_str());
        InvalidateRect(searchBar_, nullptr, TRUE);
    }
    if (shown != !summary.empty()) {
        ShowWindow(searchBar_, summary.empty() ? SW_HIDE : SW_SHOW);
        ShowWindow(searchClear_, summary.empty() ? SW_HIDE : SW_SHOW);
        ShowWindow(searchRule_, summary.empty() ? SW_HIDE : SW_SHOW);
        LayoutList();
    }
}

bool Mailbox::OnSetCursor(HWND window) {
    return reader_.OnSetCursor(window);
}

bool Mailbox::OnCtlColor(HWND window, HDC dc, LRESULT& brush) {
    return reader_.OnCtlColor(window, dc, brush);
}

// ---- the folder tree ----

Mailbox::TreeRow Mailbox::RowFrom(const PeTreeRow& row) {
    TreeRow made;
    made.kind = row.kind;
    made.key = row.key ? row.key : "";
    made.account = row.account;
    made.folder = row.folder;
    made.depth = row.depth;
    made.label = Text(row.label);
    made.title = Text(row.title);
    made.count = row.count;
    made.countCollapsed = row.count_collapsed;
    made.bold = row.bold;
    made.boldCollapsed = row.bold_collapsed;
    made.dropTarget = row.drop_target;
    made.reordersAccounts = row.reorders_accounts;
    made.menu = row.menu;
    made.list = row.list;
    made.parent = row.parent;
    made.startsOpen = row.starts_open;
    made.remembersOpen = row.remembers_open;
    made.newFolderAccount = row.new_folder_account;
    made.newFolderParent = row.new_folder_parent;
    made.icon = FolderIcon(row.icon);
    return made;
}

std::vector<Mailbox::TreeRow> Mailbox::RowsOf(const PeTree* tree) {
    std::vector<TreeRow> rows;
    size_t count = pe_tree_count(tree);
    rows.reserve(count);
    for (size_t i = 0; i < count; i++) {
        if (const PeTreeRow* row = pe_tree_get(tree, i)) {
            rows.push_back(RowFrom(*row));
        }
    }
    return rows;
}

const Mailbox::TreeRow* Mailbox::RowAt(HTREEITEM item) const {
    if (!item) {
        return nullptr;
    }
    LPARAM index = RowData(tree_, item);
    return index >= 0 && static_cast<size_t>(index) < treeRows_.size() ? &treeRows_[static_cast<size_t>(index)] : nullptr;
}

const Mailbox::TreeRow* Mailbox::SelectedTreeRow() const {
    return RowAt(TreeView_GetSelection(tree_));
}

HTREEITEM Mailbox::FindRow(const std::string& key) const {
    for (size_t i = 0; i < treeRows_.size(); i++) {
        if (treeRows_[i].key == key) {
            return treeItems_[i];
        }
    }
    return nullptr;
}

int64_t Mailbox::SelectedAccount() const {
    const TreeRow* row = SelectedTreeRow();
    return row && row->kind == PE_TREE_ROW_KIND_ACCOUNT ? row->account : 0;
}

bool Mailbox::CanNewFolder() const {
    const TreeRow* row = SelectedTreeRow();
    return row && row->newFolderAccount;
}

void Mailbox::Reload() {
    core::FolderTree tree(pe_folder_tree(core_));
    Rebuild(tree.get(), RowsOf(tree.get()));
}

void Mailbox::Rebuild(const PeTree* tree, std::vector<TreeRow> rows) {
    std::wstring shown = SelectedName();
    const TreeRow* selected = SelectedTreeRow();
    std::string key = selected ? selected->key : "";
    // deleting the items changes the selection: not a folder the user picked
    reloading_ = true;
    treeBuilds_++;
    TreeView_DeleteAllItems(tree_);
    reloading_ = false;
    treeRows_.clear();
    treeItems_.clear();
    accountNames_.clear();
    accountEmails_.clear();
    accountSignIns_.clear();
    folderAccounts_.clear();
    folderNames_.clear();
    unselectable_.clear();
    draftFolders_.clear();
    inboxFolders_.clear();
    junkFolders_.clear();
    emptiableFolders_.clear();
    firstAccount_ = 0;
    core::AccountList accounts(pe_accounts(core_));
    size_t count = pe_account_list_count(accounts.get());
    std::vector<int64_t> ids;
    for (size_t i = 0; i < count; i++) {
        const PeAccount* account = pe_account_list_get(accounts.get(), i);
        ids.push_back(account->id);
        accountNames_[account->id] = Text(account->title);
        accountEmails_[account->id] = Text(account->email);
        accountSignIns_[account->id] = {account->oauth, account->app};
        if (!firstAccount_) {
            firstAccount_ = account->id;
        }
        LoadFolderFacts(account->id);
    }
    LoadFlippedRows(ids);
    FillTree(std::move(rows));
    Reselect(tree, key);
    // the folder bar and the title follow a row whose title changed ("Inbox - Work" became "Inbox")
    if (SelectedName() != shown) {
        SendMessageW(parent_, WM_COMMAND, MAKEWPARAM(IDC_TREE, 0), 0);
    }
}

void Mailbox::FillTree(std::vector<TreeRow> rows) {
    treeRows_ = std::move(rows);
    // the last item at each depth, the parent of the next deeper one
    std::vector<HTREEITEM> parents;
    for (size_t i = 0; i < treeRows_.size(); i++) {
        const TreeRow& row = treeRows_[i];
        size_t depth = std::min<size_t>(row.depth, parents.size());
        HTREEITEM item = InsertItem(tree_, depth ? parents[depth - 1] : TVI_ROOT, row.label, static_cast<LPARAM>(i), false, row.icon);
        treeItems_.push_back(item);
        parents.resize(depth);
        parents.push_back(item);
    }
    // a row opens as the core says it starts (All Sent and All Drafts closed), or the other way when the user turned it
    // so; TVM_EXPAND sends no TVN_ITEMEXPANDED, so every row's label and bold are set here
    for (size_t i = 0; i < treeRows_.size(); i++) {
        const TreeRow& row = treeRows_[i];
        bool open = row.startsOpen != (row.remembersOpen && flippedRows_.contains(row.key));
        if (row.parent && open) {
            TreeView_Expand(tree_, treeItems_[i], TVE_EXPAND);
        }
        ShowRow(treeItems_[i]);
    }
}

void Mailbox::Reselect(const PeTree* tree, const std::string& key) {
    if (key.empty()) {
        return;
    }
    // the same row, or what the core says stands for it now (All Inboxes gone with one account left: its Inbox)
    int64_t at = pe_tree_reselect(tree, key.c_str());
    if (at >= 0 && static_cast<size_t>(at) < treeItems_.size()) {
        // the same row again is no folder the user picked; the Inbox in place of All Inboxes is shown
        reloading_ = treeRows_[static_cast<size_t>(at)].key == key;
        ChooseRow(treeItems_[static_cast<size_t>(at)]);
        reloading_ = false;
        return;
    }
    // the folder is gone
    if (!OnFolderSelected(0, PE_TREE_LIST_NONE)) {
        SendMessageW(parent_, WM_COMMAND, MAKEWPARAM(IDC_TREE, 0), 0);
    }
}

void Mailbox::LoadFolderFacts(int64_t account) {
    core::FolderList folders(pe_folders(core_, account));
    size_t count = pe_folder_list_count(folders.get());
    for (size_t i = 0; i < count; i++) {
        const PeFolder* folder = pe_folder_list_get(folders.get(), i);
        folderAccounts_[folder->id] = account;
        folderNames_[folder->id] = {Text(folder->name), folder->fixed};
        if (!folder->selectable) {
            unselectable_.insert(folder->id);
        }
        if (folder->special_use == PE_SPECIAL_USE_DRAFTS) {
            draftFolders_.insert(folder->id);
        }
        if (folder->special_use == PE_SPECIAL_USE_INBOX) {
            inboxFolders_.insert(folder->id);
        }
        if (folder->special_use == PE_SPECIAL_USE_JUNK) {
            junkFolders_.insert(folder->id);
        }
        if (folder->emptiable) {
            emptiableFolders_.insert(folder->id);
        }
    }
}

void Mailbox::LoadFlippedRows(const std::vector<int64_t>& accounts) {
    flippedRows_.clear();
    std::wstring kept = GetTextPreference(kClosedRowsPreference);
    size_t start = 0;
    bool dropped = false;
    while (start < kept.size()) {
        size_t end = kept.find(L',', start);
        std::string key = core::Narrow(kept.substr(start, end == std::wstring::npos ? std::wstring::npos : end - start));
        start = end == std::wstring::npos ? kept.size() : end + 1;
        // the keeping of versions before: All Inboxes closed as "all", an account closed as its id
        if (key == "all") {
            key = "inboxes";
        } else if (!key.empty() && std::all_of(key.begin(), key.end(), [](char c) { return c >= '0' && c <= '9'; })) {
            key = "account:" + key;
        }
        // a removed account's entry is dropped
        if (key.starts_with("account:")) {
            int64_t id = _strtoi64(key.c_str() + 8, nullptr, 10);
            if (std::find(accounts.begin(), accounts.end(), id) == accounts.end()) {
                dropped = true;
                continue;
            }
        }
        flippedRows_.insert(key);
    }
    if (dropped) {
        SaveFlippedRows();
    }
}

void Mailbox::SaveFlippedRows() const {
    std::vector<std::string> keys(flippedRows_.begin(), flippedRows_.end());
    std::sort(keys.begin(), keys.end());
    std::wstring kept;
    for (const std::string& key : keys) {
        kept += (kept.empty() ? L"" : L",") + core::Widen(key);
    }
    SetTextPreference(kClosedRowsPreference, kept);
}

// a row opened or closed by the user: its unread count shown again, and kept when the core says so (All Inboxes, All
// Sent, All Drafts, the accounts)
void Mailbox::OnRowExpanded(const NMTREEVIEWW& change) {
    ShowRow(change.itemNew.hItem);
    const TreeRow* row = RowAt(change.itemNew.hItem);
    if (!row || revealing_ || !row->remembersOpen || (change.action != TVE_EXPAND && change.action != TVE_COLLAPSE)) {
        return;
    }
    bool open = change.action == TVE_EXPAND;
    if (open != row->startsOpen) {
        flippedRows_.insert(row->key);
    } else {
        flippedRows_.erase(row->key);
    }
    SaveFlippedRows();
}

void Mailbox::ChooseRow(HTREEITEM item) {
    revealing_ = true;
    TreeView_EnsureVisible(tree_, item);
    revealing_ = false;
    // the rows opened above it count their own unread messages again, whether or not the tree told of the opening
    for (HTREEITEM above = TreeView_GetParent(tree_, item); above; above = TreeView_GetParent(tree_, above)) {
        ShowRow(above);
    }
    TreeView_SelectItem(tree_, item);
}

// a row with its unread count: its own while expanded, with what it hides while collapsed, bold as the core says
void Mailbox::ShowRow(HTREEITEM item) {
    const TreeRow* row = RowAt(item);
    if (!row) {
        return;
    }
    bool collapsed = (TreeView_GetItemState(tree_, item, TVIS_EXPANDED) & TVIS_EXPANDED) == 0;
    uint64_t count = collapsed ? row->countCollapsed : row->count;
    std::wstring label = CountedLabel(row->label, count);
    TVITEMW update = {};
    update.mask = TVIF_TEXT | TVIF_STATE | TVIF_IMAGE | TVIF_SELECTEDIMAGE;
    update.hItem = item;
    update.pszText = label.data();
    update.stateMask = TVIS_BOLD;
    update.state = (collapsed ? row->boldCollapsed : row->bold) ? TVIS_BOLD : 0;
    update.iImage = row->icon;
    update.iSelectedImage = row->icon;
    TreeView_SetItem(tree_, &update);
}

void Mailbox::ScheduleCounts() {
    // left running while more changes come: the counts follow within a moment, once for all of them
    if (!countsPending_) {
        countsPending_ = true;
        SetTimer(parent_, TIMER_COUNTS, 250, nullptr);
    }
}

void Mailbox::ScheduleReload() {
    // left running while more changes come: the list follows within PE_LIST_GATHER_MS, once for all of them, and not
    // later
    if (!reloadPending_) {
        reloadPending_ = true;
        SetTimer(parent_, TIMER_RELOAD, PE_LIST_GATHER_MS, nullptr);
    }
}

void Mailbox::UpdateCounts() {
    core::FolderTree tree(pe_folder_tree(core_));
    std::vector<TreeRow> rows = RowsOf(tree.get());
    auto sameShape = [](const TreeRow& a, const TreeRow& b) { return a.key == b.key && a.depth == b.depth; };
    if (!std::equal(rows.begin(), rows.end(), treeRows_.begin(), treeRows_.end(), sameShape)) {
        // a folder or an account came or went
        Rebuild(tree.get(), std::move(rows));
        return;
    }
    HTREEITEM selected = TreeView_GetSelection(tree_);
    bool retitled = false;
    for (size_t i = 0; i < rows.size(); i++) {
        TreeRow& row = treeRows_[i];
        const TreeRow& now = rows[i];
        if (row.label == now.label && row.title == now.title && row.count == now.count &&
            row.countCollapsed == now.countCollapsed && row.bold == now.bold && row.boldCollapsed == now.boldCollapsed &&
            row.icon == now.icon) {
            continue;
        }
        retitled |= treeItems_[i] == selected && row.title != now.title;
        row = std::move(rows[i]);
        ShowRow(treeItems_[i]);
    }
    // the folder bar and the title name the selected row as it is called now
    if (retitled) {
        SendMessageW(parent_, WM_COMMAND, MAKEWPARAM(IDC_TREE, 0), 0);
    }
}

std::wstring Mailbox::AccountName(int64_t account) const {
    auto name = accountNames_.find(account);
    return name != accountNames_.end() ? name->second : core::T(PE_TEXT_UI_THE_ACCOUNT);
}

std::wstring Mailbox::AccountEmail(int64_t account) const {
    auto email = accountEmails_.find(account);
    return email != accountEmails_.end() ? email->second : L"";
}

SignInChoice Mailbox::SignIn(int64_t account) const {
    auto found = accountSignIns_.find(account);
    return found != accountSignIns_.end() ? found->second : SignInChoice{};
}

int64_t Mailbox::CurrentAccount() const {
    // the account of the message shown (in a search of every folder, not the selected folder's), else of the folder
    if (int64_t account = AccountOf(reader_.Folder() ? reader_.Folder() : folder_)) {
        return account;
    }
    int64_t selected = SelectedAccount();
    return selected ? selected : firstAccount_;
}

int64_t Mailbox::AccountOf(int64_t folder) const {
    auto account = folderAccounts_.find(folder);
    return account != folderAccounts_.end() ? account->second : 0;
}

void Mailbox::OpenSelected() {
    FlushSelection();
    int64_t folder = reader_.Folder();
    uint64_t uid = reader_.Uid();
    if (!uid) {
        return;
    }
    if (!draftFolders_.contains(folder)) {
        OpenMessageWindow(parent_, core_, this, ListOrder(), folder, uid, SelectedRow());
        return;
    }
    // read off the window thread, the compose window opened once it is (ReadDone)
    draftMessage_ = {folder, uid};
    draftAccount_ = CurrentAccount();
    if (!draftRead_.Start(core_, pe_draft_open_start(core_, folder, uid))) {
        // not fetched yet: MessageReady follows
        openWhenReady_ = true;
    }
}

void Mailbox::OpenDraftRead(uint64_t request) {
    core::Draft draft(pe_draft_result(core_, request));
    if (!draft) {
        // not fetched yet: MessageReady follows, while it is the message shown
        openWhenReady_ = draftMessage_ == std::pair{reader_.Folder(), reader_.Uid()};
        return;
    }
    OpenCompose(parent_, core_, draftAccount_, pe_draft_info(draft.get()));
}

bool Mailbox::DraftOfShown(PeDraftKind kind, std::function<void(core::Draft, int64_t)> done) {
    // from the account of the message shown, as it is now
    int64_t account = CurrentAccount();
    return reader_.DraftOf(kind, 0, [done = std::move(done), account](core::Draft draft) { done(std::move(draft), account); });
}

// ---- the message list ----

MessageListOrder Mailbox::ListOrder() const {
    // a message window goes through the messages one by one, the conversations left out. Words typed search every
    // folder of every account (in: narrows that); without, the list is the folder's, or every Inbox's
    MessageListOrder order;
    order.view.reset(pe_list_view_clone(view_.get()));
    pe_list_view_set_grouped(order.view.get(), false);
    order.folder = Searching() ? 0 : folder_;
    order.allInboxes = !Searching() && shownList_ == PE_TREE_LIST_ALL_INBOXES;
    return order;
}

bool Mailbox::Searching() const {
    return pe_list_view_searching(view_.get());
}

bool Mailbox::SeveralFolders() const {
    return pe_list_view_several_folders(view_.get());
}

// the Folder column while the list has messages of several folders, and not otherwise; in All Inboxes, whose rows are
// all in an Inbox, the Account column
void Mailbox::ShowFolderColumn() {
    bool wanted = SeveralFolders();
    std::wstring title = core::T(pe_list_view_gathers_accounts(view_.get()) ? PE_TEXT_UI_COL_ACCOUNT : PE_TEXT_UI_COL_FOLDER);
    if (wanted && folderColumn_) {
        SetColumnTitle(list_, COL_FOLDER, title);
    }
    if (wanted == folderColumn_) {
        return;
    }
    folderColumn_ = wanted;
    // the Subject column gives the Folder column its room, and gets it back: the list stays as wide as its pane
    if (wanted) {
        AddColumn(list_, COL_FOLDER, title.c_str(), 130);
    } else {
        ListView_DeleteColumn(list_, COL_FOLDER);
    }
    FitSubjectColumn();
}

// From, or To in Sent Items and Drafts (the core says which, and sorts a From sort by the recipients there): its
// title and its values follow, and the date column is Sent there, as Outlook Express names it
void Mailbox::ShowPersonColumn(bool wanted) {
    if (wanted == recipientsColumn_) {
        return;
    }
    recipientsColumn_ = wanted;
    SetColumnTitle(list_, COL_FROM, core::T(wanted ? PE_TEXT_UI_COL_TO : PE_TEXT_UI_COL_FROM));
    SetColumnTitle(list_, COL_RECEIVED, core::T(wanted ? PE_TEXT_UI_COL_SENT : PE_TEXT_UI_COL_RECEIVED));
}

// the folder of a row in a list of several folders: its name, with its account's when there are several accounts; in
// All Inboxes, All Sent and All Drafts the account alone, as the tree names it
std::wstring Mailbox::RowFolder(int64_t folder) const {
    auto account = folderAccounts_.find(folder);
    if (pe_list_view_gathers_accounts(view_.get())) {
        return account != folderAccounts_.end() ? AccountName(account->second) : L"";
    }
    auto name = folderNames_.find(folder);
    std::wstring text = name != folderNames_.end() ? name->second.first : L"";
    if (accountNames_.size() > 1 && account != folderAccounts_.end()) {
        text += L" (" + AccountName(account->second) + L")";
    }
    return text;
}

void Mailbox::ReloadList(bool dim) {
    LoadList(LoadPlan{}, dim);
}

void Mailbox::LoadList(const LoadPlan& asked, bool dim) {
    // a folder chosen waits for its paint: its load reads the list as it is then, and selects the message asked for
    if (newList_ && listPending_ && !loadRequest_) {
        if (asked.selectUid) {
            startMessage_ = {asked.selectFolder, asked.selectUid};
        }
        return;
    }
    // a reload while another load waits reads with what that one was for (the row after a delete, a message to select)
    bool plain = !asked.selectUid && asked.after < 0;
    LoadPlan plan = loadRequest_ && plain ? loadPlan_ : asked;
    if (dim && !listPending_) {
        BeginWait(false);
    }
    StartLoad(plan);
}

void Mailbox::StartLoad(const LoadPlan& plan) {
    // the changes a reload was waiting for are read with this one
    if (std::exchange(reloadPending_, false)) {
        KillTimer(parent_, TIMER_RELOAD);
    }
    // a selection the user made that TIMER_SELECTION has not taken yet: taken now, for the load to find it again
    if (!newList_ && std::exchange(selectionPending_, false)) {
        KillTimer(parent_, TIMER_SELECTION);
        OnSelectionChanged();
    }
    // a newer load of the view drops the one before and the pages asked for: their events do not come
    DropLoads();
    loadPlan_ = plan;
    loadPlan_.selectionAt = selectionChanges_;
    // an account's own item lists nothing
    if (!pe_list_view_active(view_.get())) {
        ShowList(nullptr, PeListLoadInfo{.focus = -1});
        return;
    }
    // what is selected, found again by the core where it is now: the message the app chose, the one message shown
    // (a conversation's row too) with its row to look near first, or the selection (a list chosen just now has none)
    core::Selection chosen;
    const PeSelection* selected = newList_ ? nullptr : selection_.get();
    int64_t hint = -1;
    auto one = [&](int64_t folder, uint64_t uid) {
        chosen.reset(pe_selection_new());
        pe_selection_add(chosen.get(), folder, uid);
        selected = chosen.get();
    };
    if (plan.selectUid) {
        one(plan.selectFolder, plan.selectUid);
    } else if (selected && reader_.Uid() && ListView_GetSelectedCount(list_) == 1) {
        hint = ListView_GetNextItem(list_, -1, LVNI_SELECTED);
        keptInSight_ = ListView_IsItemVisible(list_, static_cast<int>(hint)) != FALSE;
        one(reader_.Folder(), reader_.Uid());
    }
    // a list chosen just now with no message of the app's: the core selects the one it showed when it was left, else
    // its newest
    bool arrived = newList_ && !plan.selectUid && plan.after < 0;
    loadRequest_ = pe_list_view_load(core_, view_.get(), selected, hint, plan.after, undoPending_, arrived);
    if (!loadRequest_) {
        // the core is closing: the list stays as it is
        ListNotRead(L"");
    }
}

void Mailbox::OnListLoaded(uint64_t request) {
    // a load replaced by a newer one is not drawn
    core::ListLoad load(pe_list_load_result(core_, request));
    if (!loadRequest_ || request != loadRequest_) {
        return;
    }
    loadRequest_ = 0;
    const PeListLoadInfo* info = pe_list_load_info(load.get());
    if (!info || info->failed) {
        core::String why(pe_list_load_error(load.get()));
        ListNotRead(why ? Text(why.get()) : L"");
        return;
    }
    // the user chose other messages while it was read: read again for those. Not for a list chosen: the rows clicked
    // meanwhile were the list before's (and read again it would wait for a paint that came already, for good)
    if (!newList_ && loadPlan_.selectionAt != selectionChanges_) {
        ReloadList();
        return;
    }
    ShowList(load.get(), *info);
}

void Mailbox::OnPageLoaded(uint64_t request) {
    core::ListLoad load(pe_list_load_result(core_, request));
    // a page of the list as it is drawn now: its rows drawn
    if (std::erase_if(pageRequests_, [request](const auto& asked) { return asked.second == request; }) == 0 || loadRequest_) {
        return;
    }
    const PeListLoadInfo* info = pe_list_load_info(load.get());
    if (!info || info->failed || info->offset >= rowCount_ || CachedRow(static_cast<int>(info->offset))) {
        return;
    }
    uint64_t offset = info->offset;
    KeepPage({offset, core::MessageList(pe_list_load_messages(load.get()))});
    int last = static_cast<int>(std::min<uint64_t>(std::min<uint64_t>(offset + kPageSize, rowCount_), INT_MAX)) - 1;
    RepaintRows(static_cast<int>(offset), last);
    AskOnScreen();
}

void Mailbox::ListNotRead(const std::wstring& why) {
    // the list shown stays, taking input again; the status bar says why
    newList_ = false;
    if (listPending_) {
        EndPending();
        InvalidateRect(list_, nullptr, FALSE);
    }
    AskOnScreen();
    if (!why.empty()) {
        Say(why);
    }
    RunDeferred();
}

void Mailbox::ShowRows(const PeListLoadInfo& info, Page first) {
    pages_.clear();
    pageRequests_.clear();
    // the core counts them: a folder from its indexes, a search, All Inboxes and a folder without its ignored
    // conversations what they find. The status bar counts messages; grouped by conversation the list has fewer rows
    total_ = info.total;
    unread_ = info.unread;
    rowCount_ = info.rows;
    if (first.rows) {
        pages_.push_back(std::move(first));
    }
    ShowFolderColumn();
    ShowPersonColumn(info.lists_recipients);
    ListView_SetItemCountEx(list_, static_cast<int>(std::min<uint64_t>(rowCount_, INT_MAX)), LVSICF_NOSCROLL);
    // the scroll bar comes and goes with the rows: Subject fits the width that leaves
    FitSubjectColumn();
    // an empty list says why, and that may have changed with the same count
    InvalidateRect(list_, nullptr, TRUE);
}

void Mailbox::ShowList(const PeListLoad* load, const PeListLoadInfo& info) {
    newList_ = false;
    if (listPending_) {
        EndPending();
    }
    KillTimer(parent_, TIMER_SELECTION);
    selectionPending_ = false;
    reloading_ = true;
    ShowRows(info, {info.offset, core::MessageList(pe_list_load_messages(load))});
    // the rows the core selected for what was selected (the message shown, several, Select All), or in its place for
    // the message the app chose, the row after a removal or what Undo brought back
    int count = ListView_GetItemCount(list_);
    ListView_SetItemState(list_, -1, 0, LVIS_SELECTED | LVIS_FOCUSED);
    if (info.reselection == PE_RESELECTION_ALL) {
        ListView_SetItemState(list_, -1, LVIS_SELECTED, LVIS_SELECTED);
    } else {
        core::Positions rows(pe_list_load_selected(load));
        SelectPositions(rows.get());
    }
    if (info.focus >= 0 && info.focus < count) {
        int focus = static_cast<int>(info.focus);
        ListView_SetItemState(list_, focus, LVIS_FOCUSED, LVIS_FOCUSED);
        // the message kept is scrolled to only when it was in sight: else the list stays where the user scrolled it
        if (info.reselection != PE_RESELECTION_KEPT || keptInSight_) {
            ListView_EnsureVisible(list_, focus, FALSE);
        }
    }
    reloading_ = false;
    InvalidateRect(list_, nullptr, FALSE);
    AskOnScreen();
    if (!pe_list_load_selection(load, selection_.get())) {
        pe_selection_clear(selection_.get());
    }
    if (info.reselection == PE_RESELECTION_RESTORED) {
        undoPending_ = false;
    }
    const LoadPlan& plan = loadPlan_;
    // chosen by the app, not clicked through: the list has the keyboard
    if (plan.selectUid && info.reselection != PE_RESELECTION_NONE) {
        SetFocus(list_);
    }
    // the selection is the load's: one message shown stays shown, its numbers taken again. Grouped, one row is all the
    // messages of its conversation, taken from the row (the core gives them)
    OnSelectionChanged(Grouped() && info.reselection != PE_RESELECTION_ALL && ListView_GetSelectedCount(list_) == 1);
    SendMessageW(parent_, WM_COMMAND, MAKEWPARAM(IDC_TREE, 0), 0);
    // a message the list does not have: its folder, and the message in it
    if (plan.selectUid && info.reselection == PE_RESELECTION_NONE && plan.chooseFolder) {
        if (HTREEITEM row = RowOf(plan.selectFolder)) {
            ChooseRow(row);
            SelectInList(plan.selectFolder, plan.selectUid);
        }
    }
    RunDeferred();
}

bool Mailbox::DeferCommand(WORD id, WORD code) {
    if (!listPending_) {
        return false;
    }
    deferred_.emplace_back(id, code);
    return true;
}

void Mailbox::RunDeferred() {
    for (auto [id, code] : std::exchange(deferred_, {})) {
        PostMessageW(parent_, WM_COMMAND, MAKEWPARAM(id, code), 0);
    }
}

void Mailbox::DropLoads() {
    if (loadRequest_) {
        pe_list_load_cancel(core_, std::exchange(loadRequest_, 0));
    }
    for (const auto& [offset, request] : pageRequests_) {
        pe_list_load_cancel(core_, request);
    }
    pageRequests_.clear();
}

void Mailbox::CancelLoads() {
    DropLoads();
    DropSummary();
    draftRead_.Reset();
}

void Mailbox::SelectPositions(const PePositions* positions) {
    size_t count = pe_positions_count(positions);
    for (size_t i = 0; i < count; i++) {
        uint64_t at = pe_positions_get(positions, i);
        if (at < static_cast<uint64_t>(INT_MAX)) {
            ListView_SetItemState(list_, static_cast<int>(at), LVIS_SELECTED, LVIS_SELECTED);
        }
    }
}

void Mailbox::KeepPage(Page page) {
    if (pages_.size() >= kPagesKept) {
        pages_.erase(pages_.begin());
    }
    pages_.push_back(std::move(page));
}

const PeMessage* Mailbox::CachedRow(int index) const {
    if (index < 0 || static_cast<uint64_t>(index) >= rowCount_) {
        return nullptr;
    }
    uint64_t offset = static_cast<uint64_t>(index) / kPageSize * kPageSize;
    auto page = std::find_if(pages_.begin(), pages_.end(), [offset](const Page& p) { return p.offset == offset; });
    if (page == pages_.end()) {
        return nullptr;
    }
    return pe_message_list_get(page->rows.get(), static_cast<size_t>(static_cast<uint64_t>(index) - offset));
}

const PeMessage* Mailbox::Row(int index) {
    if (index < 0 || static_cast<uint64_t>(index) >= rowCount_) {
        return nullptr;
    }
    uint64_t offset = static_cast<uint64_t>(index) / kPageSize * kPageSize;
    auto page = std::find_if(pages_.begin(), pages_.end(), [offset](const Page& p) { return p.offset == offset; });
    if (page == pages_.end()) {
        // not here: a blank row until it is, read off the window thread with the page after it (the list is scrolled
        // that way), and none while the list itself loads, whose first page comes with it. Only for a row on screen:
        // the list asks for the text of every row a Shift range selects, and reading each of their pages kept the
        // page on screen waiting behind all of them
        if (!listPending_ && !loadRequest_ && InSight(index)) {
            RequestPage(offset);
            if (offset + kPageSize < rowCount_) {
                RequestPage(offset + kPageSize);
            }
        }
        return nullptr;
    }
    if (page != pages_.end() - 1) {
        // the most recently used page goes last, the least recently used is dropped first
        std::rotate(page, page + 1, pages_.end());
    }
    return pe_message_list_get(pages_.back().rows.get(), static_cast<size_t>(static_cast<uint64_t>(index) - offset));
}

bool Mailbox::InSight(int index) const {
    int top = ListView_GetTopIndex(list_);
    return index >= top && index <= top + ListView_GetCountPerPage(list_);
}

void Mailbox::AskOnScreen() {
    // a row asks for its page as it is painted, but not while the list itself loads (its first page comes with it):
    // painted then, it stays blank until something paints it again. So once the list is drawn and as pages come, the
    // pages of the rows in sight are asked for, whenever they were painted
    if (listPending_ || loadRequest_) {
        return;
    }
    int count = ListView_GetItemCount(list_);
    int top = ListView_GetTopIndex(list_);
    int last = std::min(count, top + ListView_GetCountPerPage(list_) + 1);
    for (int row = top; row < last; row++) {
        if (!CachedRow(row)) {
            RequestPage(static_cast<uint64_t>(row) / kPageSize * kPageSize);
        }
    }
}

void Mailbox::RequestPage(uint64_t offset) {
    if (pageRequests_.contains(offset) || offset > static_cast<uint64_t>(INT_MAX) || CachedRow(static_cast<int>(offset))) {
        return;
    }
    if (uint64_t request = pe_list_view_load_page(core_, view_.get(), offset)) {
        pageRequests_[offset] = request;
    }
}

const PeMessage* Mailbox::RowNow(int index) {
    if (const PeMessage* row = CachedRow(index)) {
        return row;
    }
    // while the list loads the view lists what it will show, not these rows
    if (listPending_ || loadRequest_ || index < 0 || static_cast<uint64_t>(index) >= rowCount_) {
        return nullptr;
    }
    uint64_t offset = static_cast<uint64_t>(index) / kPageSize * kPageSize;
    KeepPage({offset, core::MessageList(pe_list_view_messages(core_, view_.get(), offset, kPageSize))});
    return pe_message_list_get(pages_.back().rows.get(), static_cast<size_t>(static_cast<uint64_t>(index) - offset));
}

const PeMessage* Mailbox::SelectedRow() {
    return RowNow(ListView_GetNextItem(list_, -1, LVNI_SELECTED));
}

void Mailbox::DisplayInfo(NMLVDISPINFOW* info) {
    const PeMessage* row = Row(info->item.iItem);
    if (info->item.mask & LVIF_IMAGE) {
        // none of the list's own: the icons are drawn in CustomDraw
        info->item.iImage = -1;
    }
    if (!(info->item.mask & LVIF_TEXT)) {
        return;
    }
    cell_.clear();
    if (row) {
        switch (info->item.iSubItem) {
        case COL_ATTACH:
            // in the Columns layout the row as a screen reader says it: the list has its first column only for that
            if (columns_) {
                cell_ = ColumnsRowText(*row);
            }
            break;
        case COL_FROM:
            cell_ = Text(recipientsColumn_ ? row->recipients : row->from);
            break;
        case COL_SUBJECT:
            cell_ = Text(row->subject);
            break;
        case COL_RECEIVED:
            cell_ = row->has_date ? FormatDate(row->date) : L"";
            break;
        case COL_FOLDER:
            cell_ = RowFolder(row->folder);
            break;
        }
    }
    info->item.pszText = cell_.data();
}

void Mailbox::CustomDraw(NMLVCUSTOMDRAW* draw, LRESULT& result) {
    result = CDRF_DODEFAULT;
    int index = static_cast<int>(draw->nmcd.dwItemSpec);
    if (draw->nmcd.dwDrawStage == CDDS_PREPAINT) {
        result = CDRF_NOTIFYITEMDRAW | CDRF_NOTIFYPOSTPAINT;
        if (columns_) {
            ColumnsPaintStarts();
        }
    } else if (draw->nmcd.dwDrawStage == CDDS_POSTPAINT) {
        if (listPending_) {
            DrawPending(draw->nmcd.hdc);
        } else if (ListView_GetItemCount(list_) == 0) {
            DrawEmptyList(draw->nmcd.hdc);
        }
    } else if (draw->nmcd.dwDrawStage == CDDS_ITEMPREPAINT && columns_) {
        // the Columns layout: the row drawn whole, three lines (columnrow.cpp)
        if (const PeMessage* row = Row(index)) {
            DrawColumnsRow(draw->nmcd.hdc, index, *row);
        }
        result = CDRF_SKIPDEFAULT;
    } else if (draw->nmcd.dwDrawStage == CDDS_ITEMPREPAINT) {
        // unread messages in bold, as Outlook Express shows them; the icons once the row is painted. Grouped by
        // conversation, the Subject cell is drawn here, the font then chosen for each cell
        const PeMessage* row = Row(index);
        result = CDRF_NOTIFYPOSTPAINT | CDRF_NOTIFYSUBITEMDRAW;
        if (row && row->bold) {
            SelectObject(draw->nmcd.hdc, bold_);
            result |= CDRF_NEWFONT;
        }
        RowColors(draw, index, row);
    } else if (draw->nmcd.dwDrawStage == (CDDS_ITEMPREPAINT | CDDS_SUBITEM)) {
        const PeMessage* row = Row(index);
        if (row && draw->iSubItem == COL_SUBJECT) {
            DrawSubject(draw->nmcd.hdc, index, *row);
            result = CDRF_SKIPDEFAULT;
            return;
        }
        SelectObject(draw->nmcd.hdc, row ? RowFont(*row) : normal_);
        RowColors(draw, index, row);
        result = CDRF_NEWFONT;
    } else if (draw->nmcd.dwDrawStage == CDDS_ITEMPOSTPAINT) {
        if (const PeMessage* row = Row(index)) {
            DrawRowIcons(draw->nmcd.hdc, index, *row);
        }
    }
}

// the colours of the flags, close to Windows' own palette: red, orange, yellow, green, blue, purple, gray
COLORREF FlagRgb(int color) {
    static const COLORREF colors[] = {RGB(232, 17, 35),  RGB(247, 99, 12),  RGB(234, 168, 0),  RGB(16, 137, 62),
                                      RGB(0, 120, 215), RGB(136, 23, 152), RGB(118, 118, 118)};
    return colors[(color >= 1 && color <= 7) ? color - 1 : 0];
}

// a flag in `rgb` in the square at `left`, `top` of `size` pixels: its pole and its cloth
void DrawFlag(HDC dc, int left, int top, int size, COLORREF rgb) {
    int pole = std::max(1, size / 12), cloth = size * 3 / 4;
    int x = left + size / 5, y = top + size / 8, bottom = top + size - size / 10;
    POINT shape[] = {{x, y}, {x + cloth, y + cloth / 4}, {x, y + cloth / 2}};
    HBRUSH fill = CreateSolidBrush(rgb);
    HPEN line = CreatePen(PS_SOLID, 1, rgb);
    HGDIOBJ oldPen = SelectObject(dc, line);
    HGDIOBJ oldBrush = SelectObject(dc, fill);
    Polygon(dc, shape, 3);
    RECT staff = {x, y, x + pole, bottom};
    FillRect(dc, &staff, fill);
    SelectObject(dc, oldBrush);
    SelectObject(dc, oldPen);
    DeleteObject(line);
    DeleteObject(fill);
}

int SecurityIcon(const PeMessage& row) {
    switch (row.protection) {
    case PE_PROTECTION_ENCRYPTED:
        return LIST_LOCK_CLOSED;
    case PE_PROTECTION_SIGNED:
        return LIST_RIBBON;
    case PE_PROTECTION_NONE:
        return -1;
    }
    return -1;
}

namespace {

// the plate of the list's background a mark of a selected row is drawn on
void DrawMarkPlate(HDC dc, int left, int top, int size) {
    HGDIOBJ oldBrush = SelectObject(dc, GetSysColorBrush(COLOR_WINDOW));
    HGDIOBJ oldPen = SelectObject(dc, GetStockObject(NULL_PEN));
    RoundRect(dc, left, top, left + size + 1, top + size + 1, 4, 4);
    SelectObject(dc, oldPen);
    SelectObject(dc, oldBrush);
}

}  // namespace

void DrawFlagMark(HDC dc, int left, int top, int size, bool selected, int color) {
    if (selected) {
        DrawMarkPlate(dc, left, top, size);
    }
    DrawFlag(dc, left, top, size, FlagRgb(color ? color : 1));
}

void DrawListMark(HDC dc, HIMAGELIST strip, int icon, int left, int top, int size, bool selected) {
    if (selected) {
        DrawMarkPlate(dc, left, top, size);
    }
    ImageList_Draw(strip, icon, dc, left, top, ILD_TRANSPARENT);
}

namespace {

// a menu picture in `color` on the menu's background, made once: its flag, or (`checked`) a check mark in it, the mark
// a menu item with a picture of its own would otherwise not show
HBITMAP FlagBitmap(int color, bool checked) {
    static HBITMAP made[2][8] = {};
    HBITMAP& bitmap = made[checked][color];
    if (!bitmap) {
        int size = GetSystemMetrics(SM_CYMENUCHECK);
        HDC screen = GetDC(nullptr);
        HDC dc = CreateCompatibleDC(screen);
        bitmap = CreateCompatibleBitmap(screen, size, size);
        HGDIOBJ old = SelectObject(dc, bitmap);
        RECT all = {0, 0, size, size};
        FillRect(dc, &all, GetSysColorBrush(COLOR_MENU));
        if (checked) {
            HPEN pen = CreatePen(PS_SOLID, std::max(2, size / 6), FlagRgb(color));
            HGDIOBJ oldPen = SelectObject(dc, pen);
            POINT mark[] = {{size / 6, size / 2}, {size * 5 / 12, size * 3 / 4}, {size * 5 / 6, size / 4}};
            Polyline(dc, mark, 3);
            SelectObject(dc, oldPen);
            DeleteObject(pen);
        } else {
            DrawFlag(dc, 0, 0, size, FlagRgb(color));
        }
        SelectObject(dc, old);
        DeleteDC(dc);
        ReleaseDC(nullptr, screen);
    }
    return bitmap;
}

} // namespace

// every cell's colours from whether the row is selected now: the state custom draw hands over can be stale for a
// list of owner data. The list then paints no highlight of its own; an ignored conversation's row in grey
void Mailbox::RowColors(NMLVCUSTOMDRAW* draw, int index, const PeMessage* row) const {
    bool selected = (ListView_GetItemState(list_, index, LVIS_SELECTED) & LVIS_SELECTED) != 0;
    draw->nmcd.uItemState &= ~CDIS_SELECTED;
    draw->clrTextBk = GetSysColor(selected ? SelectionColor() : COLOR_WINDOW);
    draw->clrText = GetSysColor(RowTextColor(index, row));
}

int Mailbox::RowTextColor(int index, const PeMessage* row) const {
    bool selected = (ListView_GetItemState(list_, index, LVIS_SELECTED) & LVIS_SELECTED) != 0;
    if (selected) {
        return GetFocus() == list_ ? COLOR_HIGHLIGHTTEXT : COLOR_BTNTEXT;
    }
    return row && row->dimmed ? COLOR_GRAYTEXT : COLOR_WINDOWTEXT;
}

HFONT Mailbox::RowFont(const PeMessage& row) const {
    return row.bold ? bold_ : normal_;
}

RECT Mailbox::SubjectCell(int index) const {
    RECT cell = {};
    ListView_GetSubItemRect(list_, index, COL_SUBJECT, LVIR_BOUNDS, &cell);
    return cell;
}

RECT Mailbox::ThreadBox(const RECT& cell) {
    // odd, so that the + and - are in its middle
    int size = Scale(9) | 1;
    int left = cell.left + Scale(4), top = cell.top + (cell.bottom - cell.top - size) / 2;
    return {left, top, left + size, top + size};
}

// as Outlook Express draws a conversation: a small box with a + (closed) or a - (open) before its first message, the
// messages under it indented; the colours the list gives a row, selected (with the keyboard or not) or not
void Mailbox::DrawSubject(HDC dc, int index, const PeMessage& row) {
    RECT cell = SubjectCell(index);
    bool selected = (ListView_GetItemState(list_, index, LVIS_SELECTED) & LVIS_SELECTED) != 0;
    int back = !selected ? COLOR_WINDOW : SelectionColor();
    int fore = RowTextColor(index, &row);
    FillRect(dc, &cell, GetSysColorBrush(back));
    RECT box = ThreadBox(cell);
    if (row.thread_opens) {
        DrawThreadBox(dc, box, row.thread_collapsed);
    }
    // the replies of an open conversation under its first message's subject
    RECT text = cell;
    text.left = box.right + Scale(5) + (row.thread_depth > 0 ? Scale(12) : 0);
    text.right -= Scale(4);
    std::wstring words = Text(row.subject);
    if (row.thread_opens) {
        words += L" (" + std::to_wstring(row.thread_count) + L")";
    }
    HGDIOBJ old = SelectObject(dc, RowFont(row));
    SetBkMode(dc, TRANSPARENT);
    SetTextColor(dc, GetSysColor(fore));
    DrawTextW(dc, words.c_str(), -1, &text, DT_LEFT | DT_VCENTER | DT_SINGLELINE | DT_NOPREFIX | DT_END_ELLIPSIS);
    SelectObject(dc, old);
}

// the small box of a conversation, with a + (closed, `collapsed`) or a - (open), as Outlook Express draws it
void Mailbox::DrawThreadBox(HDC dc, const RECT& box, bool collapsed) {
    FillRect(dc, &box, GetSysColorBrush(COLOR_WINDOW));
    FrameRect(dc, &box, GetSysColorBrush(COLOR_BTNSHADOW));
    int middleX = (box.left + box.right) / 2, middleY = (box.top + box.bottom) / 2, arm = (box.right - box.left) / 2 - Scale(2);
    RECT across = {middleX - arm, middleY, middleX + arm + 1, middleY + 1};
    FillRect(dc, &across, GetSysColorBrush(COLOR_WINDOWTEXT));
    if (collapsed) {
        RECT down = {middleX, middleY - arm, middleX + 1, middleY + arm + 1};
        FillRect(dc, &down, GetSysColorBrush(COLOR_WINDOWTEXT));
    }
}

// the paper clip (or a bounce's mark), the flag and the lock or seal of a row, drawn over the row as the list painted it:
// the list itself would dither the images of a selected row, and does not highlight those of other columns
void Mailbox::DrawRowIcons(HDC dc, int index, const PeMessage& row) {
    bool selected = (ListView_GetItemState(list_, index, LVIS_SELECTED) & LVIS_SELECTED) != 0;
    FillRowStart(dc, index, selected);
    auto draw = [&](int column, int icon) {
        RECT cell;
        ListView_GetSubItemRect(list_, index, column, LVIR_BOUNDS, &cell);
        // the first column's bounds are the whole row's: its width is the column's
        int width = ListView_GetColumnWidth(list_, column);
        DrawListMark(dc, listIcons_, icon, cell.left + (width - iconSize_) / 2, cell.top + (cell.bottom - cell.top - iconSize_) / 2,
                     iconSize_, selected);
    };
    // a bounce's mark in the paper clip's place, also when it has files
    if (row.bounce) {
        draw(COL_ATTACH, LIST_MAIL_ERROR);
    } else if (row.has_attachments) {
        draw(COL_ATTACH, LIST_ATTACH);
    }
    if (int security = SecurityIcon(row); security >= 0) {
        draw(COL_SECURE, security);
    }
    if (row.flagged) {
        // the flag in its colour (red when it has none); on the selected row's highlight on a plate of the list's own
        // background, so that a colour close to the highlight's (blue on blue) can still be seen
        RECT cell;
        ListView_GetSubItemRect(list_, index, COL_FLAG, LVIR_BOUNDS, &cell);
        int width = ListView_GetColumnWidth(list_, COL_FLAG);
        int left = cell.left + (width - iconSize_) / 2, top = cell.top + (cell.bottom - cell.top - iconSize_) / 2;
        DrawFlagMark(dc, left, top, iconSize_, selected, row.flag_color);
    }
}

// the list highlights a selected row from where the first column's text would start, after the room it keeps for an
// icon: the rest of the row highlighted too, as Outlook Express shows it, and plain again when it is not
void Mailbox::FillRowStart(HDC dc, int index, bool selected) const {
    RECT row = {LVIR_BOUNDS}, highlighted = {LVIR_LABEL};
    SendMessageW(list_, LVM_GETITEMRECT, index, reinterpret_cast<LPARAM>(&row));
    SendMessageW(list_, LVM_GETITEMRECT, index, reinterpret_cast<LPARAM>(&highlighted));
    row.right = highlighted.left;
    if (row.right > row.left) {
        FillRect(dc, &row, GetSysColorBrush(selected ? SelectionColor() : COLOR_WINDOW));
    }
}

// the list repaints only the text of a row whose selection changed: the whole row, the start of the first column too
void Mailbox::RepaintRows(int from, int to) const {
    if (from < 0) {
        InvalidateRect(list_, nullptr, FALSE);
        return;
    }
    RECT first = {LVIR_BOUNDS}, last = {LVIR_BOUNDS};
    if (SendMessageW(list_, LVM_GETITEMRECT, from, reinterpret_cast<LPARAM>(&first)) &&
        SendMessageW(list_, LVM_GETITEMRECT, to, reinterpret_cast<LPARAM>(&last))) {
        UnionRect(&first, &first, &last);
        InvalidateRect(list_, &first, FALSE);
    }
}

// the colour of a selected row: the highlight while the list has the keyboard, grey without it
int Mailbox::SelectionColor() const {
    return GetFocus() == list_ ? COLOR_HIGHLIGHT : COLOR_BTNFACE;
}

// ---- the reading pane ----

void Mailbox::ClearReader(bool loading) {
    reader_.Clear(loading);
    openWhenReady_ = false;
    KillTimer(parent_, TIMER_MARK_READ);
    summaryPage_.clear();
}

int Mailbox::TestShown(const std::wstring& subject) {
    // a selection the list has not handed on yet (TIMER_SELECTION) shows its message only after
    if (selectionPending_) {
        return 0;
    }
    if (subject.empty()) {
        const PeMessage* row = SelectedCount() == 1 ? SelectedRow() : nullptr;
        if (!row || row->uid != reader_.Uid() || row->folder != reader_.Folder()) {
            return 0;
        }
    }
    return reader_.TestShown(subject);
}

void Mailbox::OnMessageShown() {
    // read after a moment on screen, not while the user moves through the list
    SetTimer(parent_, TIMER_MARK_READ, 1000, nullptr);
}

void Mailbox::OnSelectionChanged(bool rebuild) {
    TakeSelection(rebuild);
    // the main window: the buttons and counts for what is selected now
    SendMessageW(parent_, WM_COMMAND, MAKEWPARAM(IDC_LIST, kSelectionTaken), 0);
    if (SelectedCount() > 1) {
        return;
    }
    const PeMessage* row = SelectedRow();
    uint64_t uid = row ? row->uid : 0;
    int64_t folder = row ? row->folder : 0;
    // the same message, or still none; the page that counted several selected goes once they are not
    if (uid == reader_.Uid() && folder == reader_.Folder() && (uid || summaryPage_.empty())) {
        return;
    }
    ClearReader(uid != 0);
    if (!uid) {
        return;
    }
    // for the list to open with it when it is come back to
    pe_list_view_shown(core_, view_.get(), folder, uid);
    reader_.Open(folder, uid, AccountOf(folder), row);
}

void Mailbox::ScheduleSelection() {
    // the user chose: what Undo brings back is not selected over it, nor a list read before for the selection before
    undoPending_ = false;
    selectionChanges_++;
    selectionPending_ = true;
    SetTimer(parent_, TIMER_SELECTION, USER_TIMER_MINIMUM, nullptr);
}

void Mailbox::FlushSelection() {
    if (std::exchange(selectionPending_, false)) {
        KillTimer(parent_, TIMER_SELECTION);
        OnSelectionChanged();
    }
}

size_t Mailbox::SelectedCount() const {
    // the dimmed rows of the list before are not the folder's: a list that has not loaded has nothing selected
    return listPending_ ? 0 : static_cast<size_t>(ListView_GetSelectedCount(list_));
}

std::vector<int> Mailbox::SelectedRows() const {
    std::vector<int> rows;
    for (int i = ListView_GetNextItem(list_, -1, LVNI_SELECTED); i >= 0; i = ListView_GetNextItem(list_, i, LVNI_SELECTED)) {
        rows.push_back(i);
    }
    return rows;
}

void Mailbox::TakeSelection(bool rebuild) {
    size_t count = SelectedCount();
    if (!rebuild) {
        // the selection a list load found again (pe_list_load_selection): only its numbers taken
    } else if (count == 1 && !Grouped()) {
        pe_selection_clear(selection_.get());
        if (const PeMessage* row = SelectedRow()) {
            pe_selection_add(selection_.get(), row->folder, row->uid);
        }
    } else if (count == 0) {
        pe_selection_clear(selection_.get());
    } else if (count > 1 && count == rowCount_) {
        // every row (Select All): every message of the list, counted without listing them
        pe_list_view_select_all(core_, view_.get(), selection_.get());
    } else {
        // the selected rows as ranges of positions: Select All on a long list is one range, not every row. Grouped by
        // conversation a single row too: the core gives every message of a collapsed row
        std::vector<uint64_t> starts, ends;
        for (int i : SelectedRows()) {
            if (!ends.empty() && ends.back() == static_cast<uint64_t>(i)) {
                ends.back()++;
            } else {
                starts.push_back(static_cast<uint64_t>(i));
                ends.push_back(static_cast<uint64_t>(i) + 1);
            }
        }
        pe_list_view_select_ranges(core_, view_.get(), selection_.get(), starts.data(), ends.data(), starts.size());
    }
    RefreshSummary();
    if (count <= 1) {
        return;
    }
    // several: none of them is opened, the pane says how many (again only when that changed)
    if (reader_.Uid()) {
        ClearReader();
        // the header without the logo and bars of the message that was shown
        reader_.Layout();
    }
    ShowSummaryPage();
}

void Mailbox::ShowSummaryPage() {
    if (SelectedCount() <= 1) {
        return;
    }
    core::String page(pe_selection_page(&summary_));
    std::wstring html = page ? core::Widen(page.get()) : L"";
    if (html != summaryPage_) {
        summaryPage_ = html;
        reader_.ShowPage(html);
    }
}

bool Mailbox::OnFolderSelected(int64_t folder, PeTreeList list) {
    if (folder == folder_ && list == shownList_) {
        return false;
    }
    // the message of the folder before is not this folder's, nor is the search; what Show shows stays
    folder_ = folder;
    shownList_ = list;
    undoPending_ = false;
    // the view closes the conversations opened, which were the folder's
    pe_list_view_set_list(view_.get(), list, folder);
    ResetFind();
    ClearReader();
    DeferList();
    SendMessageW(parent_, WM_COMMAND, MAKEWPARAM(IDC_TREE, 0), 0);
    return true;
}

void Mailbox::BeginWait(bool clearSelection) {
    listPending_ = true;
    // from the first click: a second one before the list was read does not start the wait again
    SetTimer(parent_, TIMER_LIST_LOADING, PE_LIST_LOADING_MS, nullptr);
    // its rows drawn again, dimmed; an empty list keeps saying why it was empty rather than blink
    if (ListView_GetItemCount(list_) > 0) {
        InvalidateRect(list_, nullptr, FALSE);
    }
    if (clearSelection) {
        pe_selection_clear(selection_.get());
        DropSummary();
        summary_ = {};
    }
    // nothing selected meanwhile: the menus and buttons for messages are off until the list is read
    SendMessageW(parent_, WM_COMMAND, MAKEWPARAM(IDC_LIST, kSelectionTaken), 0);
}

void Mailbox::DeferList() {
    // a selection of the list before not taken yet is no longer wanted: the view lists the new folder now
    KillTimer(parent_, TIMER_SELECTION);
    selectionPending_ = false;
    // a load of the list before is not this one's, nor are the pages asked for
    DropLoads();
    if (!listPending_) {
        BeginWait(true);
    } else {
        pe_selection_clear(selection_.get());
        DropSummary();
        summary_ = {};
    }
    newList_ = true;
    highlightPainted_ = false;
    testListOrder_ = -1;
    // a message to select in the folder chosen before: not this one's (SelectInList sets it again after choosing)
    startMessage_ = {};
    // WM_TIMER comes once the windows are painted; set again, the newest click is the one read. Stopped by EndPending
    // only; the UI test's hold sets it when it lets go
    if (!holdList_) {
        SetTimer(parent_, TIMER_LOAD_LIST, USER_TIMER_MINIMUM, nullptr);
    }
}

void Mailbox::LoadPendingList() {
    KillTimer(parent_, TIMER_LOAD_LIST);
    if (!listPending_ || loadRequest_ || !newList_) {
        return;
    }
    // what is still to be painted of the click first, should a timer have come before it
    UpdateWindow(tree_);
    // the message to select in it (the window's first list: its newest message)
    LoadPlan plan;
    auto [folder, uid] = std::exchange(startMessage_, {});
    plan.selectFolder = folder;
    plan.selectUid = uid;
    StartLoad(plan);
}

void Mailbox::TestHoldList(bool hold) {
    holdList_ = hold;
    if (!hold && listPending_) {
        SetTimer(parent_, TIMER_LOAD_LIST, USER_TIMER_MINIMUM, nullptr);
    }
}

void Mailbox::EndPending() {
    listPending_ = false;
    listLoadingShown_ = false;
    KillTimer(parent_, TIMER_LOAD_LIST);
    KillTimer(parent_, TIMER_LIST_LOADING);
    if (testListOrder_ == -1) {
        testListOrder_ = highlightPainted_ ? 2 : 1;
    }
}

void Mailbox::TreeCustomDraw(NMTVCUSTOMDRAW* draw, LRESULT& result) {
    result = CDRF_DODEFAULT;
    if (!listPending_ || highlightPainted_) {
        return;
    }
    if (draw->nmcd.dwDrawStage == CDDS_PREPAINT) {
        result = CDRF_NOTIFYITEMDRAW;
    } else if (draw->nmcd.dwDrawStage == CDDS_ITEMPREPAINT &&
               reinterpret_cast<HTREEITEM>(draw->nmcd.dwItemSpec) == TreeView_GetSelection(tree_)) {
        highlightPainted_ = true;
    }
}

void Mailbox::DrawPending(HDC dc) const {
    RECT area;
    GetClientRect(list_, &area);
    if (HWND header = ListView_GetHeader(list_); header && IsWindowVisible(header)) {
        RECT box;
        GetWindowRect(header, &box);
        area.top += box.bottom - box.top;
    }
    // the rows faded towards the window colour, as a list that is not for now
    HDC memory = CreateCompatibleDC(dc);
    HBITMAP pixel = CreateCompatibleBitmap(dc, 1, 1);
    HGDIOBJ old = SelectObject(memory, pixel);
    SetPixel(memory, 0, 0, GetSysColor(COLOR_WINDOW));
    BLENDFUNCTION blend = {AC_SRC_OVER, 0, static_cast<BYTE>(PE_LIST_DIM * 255 + 0.5), 0};
    AlphaBlend(dc, area.left, area.top, area.right - area.left, area.bottom - area.top, memory, 0, 0, 1, 1, blend);
    SelectObject(memory, old);
    DeleteObject(pixel);
    DeleteDC(memory);
    if (!listLoadingShown_) {
        return;
    }
    // a small box in the middle of the rows, clear of the one being read
    std::wstring text = core::T(PE_TEXT_WIN_LIST_LOADING);
    HGDIOBJ font = SelectObject(dc, normal_);
    RECT box = {};
    DrawTextW(dc, text.c_str(), -1, &box, DT_SINGLELINE | DT_NOPREFIX | DT_CALCRECT);
    int width = box.right + Scale(24), height = box.bottom + Scale(10);
    box.left = (area.left + area.right - width) / 2;
    box.top = (area.top + area.bottom - height) / 2;
    box.right = box.left + width;
    box.bottom = box.top + height;
    FillRect(dc, &box, GetSysColorBrush(COLOR_WINDOW));
    FrameRect(dc, &box, GetSysColorBrush(COLOR_BTNSHADOW));
    SetTextColor(dc, GetSysColor(COLOR_WINDOWTEXT));
    SetBkMode(dc, TRANSPARENT);
    DrawTextW(dc, text.c_str(), -1, &box, DT_CENTER | DT_VCENTER | DT_SINGLELINE | DT_NOPREFIX);
    SelectObject(dc, font);
}

void Mailbox::LoadPictures() {
    reader_.LoadPictures();
}

bool Mailbox::CanMarkAllRead() const {
    return pe_list_view_marks_all_read(view_.get());
}

void Mailbox::MarkAllRead() {
    if (!CanMarkAllRead()) {
        return;
    }
    // a folder's list marks the folder, All Inboxes every Inbox; off the window thread, the list read again once done
    int64_t folder = pe_list_view_own_folder(view_.get());
    uint64_t request = folder ? pe_mark_read_start(core_, PE_MARK_READ_FOLDER, folder) : pe_mark_read_start(core_, PE_MARK_READ_ALL_INBOXES, 0);
    if (request) {
        actions_[request] = -1;
    } else {
        Say(core::T(PE_TEXT_UI_MESSAGES_NOT_CHANGED));
    }
}

void Mailbox::MarkAccountRead(int64_t account) {
    if (uint64_t request = pe_mark_read_start(core_, PE_MARK_READ_ACCOUNT, account)) {
        actions_[request] = -1;
    } else {
        Say(core::T(PE_TEXT_UI_MESSAGES_NOT_CHANGED));
    }
}

void Mailbox::ShowMessage(int64_t folder, uint64_t uid) {
    HTREEITEM row = RowOf(folder);
    if (!row) {
        return;
    }
    // All Inboxes, All Sent or All Drafts stays when it has the message (of one of its folders), its list up to date
    // with it; else the folder is chosen once the list is read
    if (pe_list_view_gathers_accounts(view_.get())) {
        SelectInList(folder, uid, true);
        return;
    }
    // the folder (which ends a search), then the message in it; the folder selected already does not change, its
    // search is ended here
    if (Searching() && shownList_ == PE_TREE_LIST_FOLDER && folder_ == folder) {
        ClearFind();
    }
    ChooseRow(row);
    if (folder_ == folder) {
        SelectInList(folder, uid);
    }
}

void Mailbox::SelectInList(int64_t folder, uint64_t uid, bool chooseFolder) {
    // a message hidden in a collapsed conversation (Next Unread finds those): the conversation opened first. A folder
    // chosen just now is read with it; else the selection made is taken from the rows as they are shown first
    if (!newList_ || !listPending_) {
        FlushSelection();
    }
    pe_list_view_reveal(core_, view_.get(), folder, uid);
    // the list read again with it (off the window thread), and its row selected: chosen by the app, not clicked
    // through, so followed at once
    LoadPlan plan;
    plan.selectFolder = folder;
    plan.selectUid = uid;
    plan.chooseFolder = chooseFolder;
    LoadList(plan, false);
}

void Mailbox::SelectOnly(int row) {
    ListView_SetItemState(list_, -1, 0, LVIS_SELECTED);
    ListView_SetItemState(list_, row, LVIS_SELECTED | LVIS_FOCUSED, LVIS_SELECTED | LVIS_FOCUSED);
    ListView_EnsureVisible(list_, row, FALSE);
    FlushSelection();
}

void Mailbox::SelectStart() {
    if (started_) {
        return;
    }
    started_ = true;
    // the row the app was closed on, its list opening with the message it showed (the core selects it)
    if (shownList_ == PE_TREE_LIST_NONE) {
        core::String key(pe_tree_start(core_));
        if (HTREEITEM item = key ? FindRow(key.get()) : nullptr) {
            ChooseRow(item);
            return;
        }
    }
    bool allInboxes = false;
    int64_t folder = 0;
    uint64_t uid = 0;
    if (shownList_ != PE_TREE_LIST_NONE || !pe_start_message(core_, &allInboxes, &folder, &uid)) {
        return;
    }
    HTREEITEM item = allInboxes ? FindRow("inboxes") : RowOf(folder);
    if (!item) {
        return;
    }
    // the window with its row highlighted, the folder bar and the title painted first, then the list read (as after a
    // click) with the message selected
    ChooseRow(item);
    SelectInList(folder, uid);
}

std::wstring Mailbox::Unsubscribe(core::Draft& draft) {
    return reader_.Unsubscribe(parent_, draft);
}

bool Mailbox::CanUnsubscribe() const {
    return SelectedCount() == 1 && reader_.CanUnsubscribe();
}

int64_t Mailbox::ShownAccount() const {
    return reader_.Uid() ? AccountOf(reader_.Folder()) : 0;
}

std::wstring Mailbox::Unsubscribed(uint64_t request, const std::wstring& problem) {
    return reader_.Unsubscribed(request, problem);
}

void Mailbox::MarkJunk(bool junk) {
    Act(junk ? PE_ACTION_JUNK : PE_ACTION_NOT_JUNK);
}

void Mailbox::ArchiveSelected() {
    // whether they can be archived is in a whole list's numbers, counted off the window thread
    FlushSelection();
    if (AfterSummary([this] { ArchiveSelected(); })) {
        return;
    }
    if (CanArchive()) {
        Act(PE_ACTION_ARCHIVE);
    }
}

bool Mailbox::CanArchive() const {
    return summary_.archivable;
}

bool Mailbox::InJunk() const {
    if (summary_.count > 0) {
        return summary_.in_junk;
    }
    return junkFolders_.contains(folder_);
}

void Mailbox::MarkSelected(bool seen) {
    Act(seen ? PE_ACTION_READ : PE_ACTION_UNREAD);
}

bool Mailbox::Act(PeAction action, int64_t to) {
    FlushSelection();
    if (pe_selection_count(selection_.get()) == 0) {
        return false;
    }
    // a whole list's numbers counted off the window thread first
    if (AfterSummary([this, action, to] { Act(action, to); })) {
        return true;
    }
    // what takes the place of rows that leave the list: the row after the last of them. The core says which actions
    // take them out, from the selection as it is now (Ignore while ignored conversations are hidden)
    bool leaves = pe_list_view_leaves_list(view_.get(), &summary_, action, to);
    // the same rows taken out twice before the list shows the first time: the second is not done
    if (leaves && std::ranges::any_of(actions_, [](const auto& started) { return started.second >= 0; })) {
        return false;
    }
    // done in the store and handed to the server off the window thread: what was done said once it is (Acted)
    uint64_t request = pe_selection_act_start(core_, selection_.get(), action, to);
    if (!request) {
        Say(core::T(PE_TEXT_UI_MESSAGES_NOT_CHANGED));
        return false;
    }
    actions_[request] = leaves ? std::max(RowAfterSelection(), 0) : -1;
    return true;
}

void Mailbox::OnActed(const UiEvent& event) {
    auto started = actions_.find(event.uid);
    if (started == actions_.end()) {
        return;
    }
    int after = started->second;
    actions_.erase(started);
    Say(event.message.empty() ? core::T(PE_TEXT_UI_MESSAGES_NOT_CHANGED) : event.message);
    if (event.failure != PE_FAILURE_KIND_NONE) {
        return;
    }
    // read, flagged or marked at once, not with the changes of a sync a moment later; rows that left the list give
    // their place to the one after them
    LoadPlan plan;
    plan.after = after;
    LoadList(plan, false);
}

void Mailbox::RefreshSummary() {
    DropSummary();
    summary_ = {};
    uint64_t count = pe_selection_count(selection_.get());
    if (count == 0) {
        return;
    }
    // a whole list's counted where its messages are, off the window thread: its count is known at once
    if (pe_selection_is_all(selection_.get())) {
        summary_.count = count;
        summaryRequest_ = pe_selection_summary_start(core_, selection_.get());
        if (summaryRequest_) {
            return;
        }
    }
    pe_selection_summary(core_, selection_.get(), &summary_);
}

void Mailbox::DropSummary() {
    if (summaryRequest_) {
        pe_read_cancel(core_, std::exchange(summaryRequest_, 0));
    }
    // what waited for it is dropped, never run on a later one
    whenSummed_.clear();
}

bool Mailbox::AfterSummary(std::function<void()> then) {
    if (!summaryRequest_) {
        return false;
    }
    whenSummed_.push_back(std::move(then));
    return true;
}

void Mailbox::SummaryDone(uint64_t request) {
    // Select All's numbers: the menus, the buttons and the reading pane's page follow them, then what waited for them
    summaryRequest_ = 0;
    auto waiting = std::exchange(whenSummed_, {});
    PeSelectionSummary counted = {};
    if (!pe_selection_summary_result(core_, request, &counted)) {
        return;
    }
    summary_ = counted;
    ShowSummaryPage();
    SendMessageW(parent_, WM_COMMAND, MAKEWPARAM(IDC_LIST, kSelectionTaken), 0);
    for (auto& then : waiting) {
        then();
    }
}

void Mailbox::ListSelection() {
    if (pe_selection_is_all(selection_.get())) {
        pe_selection_list(core_, selection_.get());
    }
}

void Mailbox::ShowUndone(const std::wstring& text) {
    undoneText_ = text;
    SetWindowTextW(undoneBar_, text.c_str());
    ShowWindow(undoneBar_, text.empty() ? SW_HIDE : SW_SHOW);
    ShowWindow(undoneClose_, text.empty() ? SW_HIDE : SW_SHOW);
    InvalidateRect(undoneBar_, nullptr, TRUE);
    LayoutList();
}

void Mailbox::Say(const std::wstring& text) {
    said_ = text;
    SendMessageW(parent_, WM_COMMAND, MAKEWPARAM(IDC_LIST, kSaid), 0);
}

int Mailbox::RowAfterSelection() const {
    // every row: the first takes their place
    if (rowCount_ > 0 && static_cast<uint64_t>(ListView_GetSelectedCount(list_)) == rowCount_) {
        return 0;
    }
    // every selected row before the one after the last of them goes: it moves up by as many, less the last itself
    std::vector<int> rows = SelectedRows();
    return rows.empty() ? -1 : rows.back() - static_cast<int>(rows.size()) + 1;
}

void Mailbox::SelectAll() {
    if (ListView_GetItemCount(list_) == 0) {
        return;
    }
    // every message of the list (pe_list_view_select_all, TakeSelection): counted at once, its summary off the window
    // thread
    reloading_ = true;
    ListView_SetItemState(list_, -1, LVIS_SELECTED, LVIS_SELECTED);
    reloading_ = false;
    KillTimer(parent_, TIMER_SELECTION);
    selectionPending_ = false;
    undoPending_ = false;
    selectionChanges_++;
    SetFocus(list_);
    OnSelectionChanged();
}

void Mailbox::Undo() {
    char* reason = nullptr;
    core::String done(pe_undo(core_, &reason));
    // selected once the list has them again
    undoPending_ = done != nullptr;
    Say(done ? Text(done.get()) : ReasonText(reason, PE_TEXT_NOTHING_TO_UNDO));
}

std::wstring Mailbox::UndoLabel() const {
    core::String label(pe_undo_label(core_));
    return label ? Text(label.get()) : L"";
}

void Mailbox::DeleteSelected() {
    FlushSelection();
    if (pe_selection_count(selection_.get()) == 0) {
        return;
    }
    // from Deleted Items, or an account without one, they are gone for good: asked first, as Outlook Express does (a
    // whole list's numbers counted off the window thread first)
    if (AfterSummary([this] { DeleteSelected(); })) {
        return;
    }
    core::String question(pe_selection_delete_question(&summary_));
    if (question && MessageBoxW(parent_, Text(question.get()).c_str(), L"Inbox Classic", MB_YESNO | MB_ICONWARNING | MB_DEFBUTTON2) != IDYES) {
        return;
    }
    Act(PE_ACTION_DELETE);
}

void Mailbox::MoveSelected(HWND owner, bool copy) {
    FlushSelection();
    if (pe_selection_count(selection_.get()) == 0 || AfterSummary([this, owner, copy] { MoveSelected(owner, copy); })) {
        return;
    }
    // the folder of the first of them; a whole list's (not listed) is its folder's
    int64_t first = pe_list_view_own_folder(view_.get());
    int64_t folder = 0;
    uint64_t uid = 0;
    if (pe_selection_get(selection_.get(), 0, &folder, &uid)) {
        first = folder;
    }
    FolderPick pick;
    pick.core = core_;
    pick.title = Text(core::String(pe_selection_move_text(&summary_, copy, false)).get());
    pick.prompt = Text(core::String(pe_selection_move_text(&summary_, copy, true)).get());
    pick.verb = core::T(copy ? PE_TEXT_UI_BUTTON_COPY : PE_TEXT_UI_BUTTON_MOVE);
    // the folder they are all in is shown but not offered; from several folders, any
    pick.current = summary_.folders == 1 ? first : 0;
    pick.newFolder = [this](HWND window, int64_t account, int64_t parent) {
        std::wstring where = core::T(parent ? PE_TEXT_WIN_NEW_FOLDER_IN_HIGHLIGHTED : PE_TEXT_UI_NEW_FOLDER_AT_TOP);
        std::wstring name = AskFolderName(window, PE_TEXT_CMD_NEW_FOLDER, where, L"");
        if (name.empty()) {
            return;
        }
        char* reason = nullptr;
        if (!pe_folder_create(core_, account, parent, core::Narrow(name).c_str(), &reason)) {
            ShowRefusal(window, reason, PE_TEXT_UI_FOLDER_NOT_CREATED);
            return;
        }
        // highlighted once the server made it (FolderCreated)
        newInPick_ = true;
    };
    newInPick_ = false;
    int64_t to = PickFolder(owner, pick);
    newInPick_ = false;
    if (to) {
        Act(copy ? PE_ACTION_COPY : PE_ACTION_MOVE, to);
    }
}

void Mailbox::FlagSelected() {
    // flagged when any of them is not, the flags taken away when all have one
    Act(PE_ACTION_TOGGLE_FLAG);
}

void Mailbox::FlagColor(int color) {
    if (color == 0) {
        Act(PE_ACTION_UNFLAG);
    } else {
        Act(PE_ACTION_FLAG_COLOR, color);
    }
}

HMENU Mailbox::FlagMenu() {
    HMENU menu = CreatePopupMenu();
    std::wstring used;
    for (int color = 1; color <= 7; color++) {
        core::String name(pe_flag_color_name(static_cast<uint8_t>(color)));
        std::wstring label = Text(name.get());
        // each by a letter of its own: Gray after Green takes its second
        for (size_t at = 0; at < label.size(); at++) {
            wchar_t letter = static_cast<wchar_t>(towlower(label[at]));
            if (iswalpha(letter) && used.find(letter) == std::wstring::npos) {
                used += letter;
                label.insert(at, L"&");
                break;
            }
        }
        MENUITEMINFOW item = {sizeof item};
        // its flag where the check mark goes, a check mark in its colour once checked
        item.fMask = MIIM_ID | MIIM_STRING | MIIM_CHECKMARKS;
        item.wID = IDM_FLAG_COLOR + color;
        item.dwTypeData = label.data();
        item.hbmpUnchecked = FlagBitmap(color, false);
        item.hbmpChecked = FlagBitmap(color, true);
        InsertMenuItemW(menu, color - 1, TRUE, &item);
    }
    AppendMenuW(menu, MF_SEPARATOR, 0, nullptr);
    AppendMenuW(menu, MF_STRING, IDM_FLAG_CLEAR, MenuItem(PE_TEXT_UI_CLEAR_FLAG).c_str());
    // its checks and greying as it opens (WM_INITMENUPOPUP)
    return menu;
}

void Mailbox::UpdateFlagMenu(HMENU menu) {
    // a list waiting to be read stays waiting for a menu: nothing is selected in it
    if (!listPending_) {
        FlushSelection();
    }
    bool some = SelectedCount() > 0;
    for (int color = 1; color <= 7; color++) {
        EnableMenuItem(menu, IDM_FLAG_COLOR + color, MF_BYCOMMAND | (some ? MF_ENABLED : MF_GRAYED));
        CheckMenuItem(menu, IDM_FLAG_COLOR + color,
                      MF_BYCOMMAND | (some && summary_.flag_color == color ? MF_CHECKED : MF_UNCHECKED));
    }
    EnableMenuItem(menu, IDM_FLAG_CLEAR, MF_BYCOMMAND | (some && summary_.flagged > 0 ? MF_ENABLED : MF_GRAYED));
}

// ---- folders ----

void Mailbox::FolderMenu() {
    // the item under the mouse is the one the menu is for
    TVHITTESTINFO hit = {};
    GetCursorPos(&hit.pt);
    POINT screen = hit.pt;
    ScreenToClient(tree_, &hit.pt);
    if (HTREEITEM item = TreeView_HitTest(tree_, &hit)) {
        TreeView_SelectItem(tree_, item);
    }
    const TreeRow* row = SelectedTreeRow();
    if (!row || row->menu == PE_TREE_MENU_NONE) {
        // Flagged, All Sent and All Drafts list messages of several folders: no folder commands, nothing to mark read
        // as a whole
        return;
    }
    if (row->menu == PE_TREE_MENU_ACCOUNT) {
        AccountMenu(screen);
        return;
    }
    HMENU menu = CreatePopupMenu();
    // Mark All Read first, as Outlook Express has it, for a folder (or All Inboxes) with unread messages
    AppendMenuW(menu, row->count > 0 ? MF_STRING : MF_STRING | MF_GRAYED, IDM_MARK_ALL_READ, MenuItem(PE_TEXT_CMD_MARK_ALL_READ).c_str());
    if (row->menu == PE_TREE_MENU_FOLDER) {
        AppendMenuW(menu, MF_SEPARATOR, 0, nullptr);
        AppendMenuW(menu, row->newFolderAccount ? MF_STRING : MF_STRING | MF_GRAYED, IDM_NEW_FOLDER, MenuItem(PE_TEXT_CMD_NEW_FOLDER).c_str());
        std::wstring name;
        bool fixed = true;
        UINT special = FolderOf(row->folder, name, fixed) && !fixed ? MF_STRING : MF_STRING | MF_GRAYED;
        AppendMenuW(menu, special, IDM_RENAME_FOLDER, MenuItem(PE_TEXT_WIN_RENAME).c_str());
        AppendMenuW(menu, special, IDM_DELETE_FOLDER, MenuItem(PE_TEXT_WIN_DELETE_BUTTON).c_str());
        // Deleted Items and Junk E-mail can be emptied, as in Outlook Express
        if (emptiableFolders_.contains(row->folder)) {
            AppendMenuW(menu, MF_SEPARATOR, 0, nullptr);
            AppendMenuW(menu, CanEmptyFolder() ? MF_STRING : MF_STRING | MF_GRAYED, IDM_EMPTY_FOLDER, MenuItem(PE_TEXT_CMD_EMPTY_FOLDER).c_str());
        }
    }
    // an Inbox under All Inboxes stands for its account there: its place in the accounts' order
    if (row->reordersAccounts) {
        AppendMenuW(menu, MF_SEPARATOR, 0, nullptr);
        AppendMoveItems(menu);
    }
    TrackPopupMenu(menu, TPM_RIGHTBUTTON, screen.x, screen.y, 0, parent_, nullptr);
    DestroyMenu(menu);
}

void Mailbox::AccountMenu(POINT screen) {
    // Mark All Read while some folder of the account has unread mail, as its row counts it collapsed
    const TreeRow* row = SelectedTreeRow();
    bool someUnread = row && row->countCollapsed > 0;
    HMENU menu = CreatePopupMenu();
    AppendMenuW(menu, MF_STRING, IDM_ACCOUNT_SYNC, core::T(PE_TEXT_UI_ACCOUNT_SYNC).c_str());
    AppendMenuW(menu, someUnread ? MF_STRING : MF_STRING | MF_GRAYED, IDM_ACCOUNT_MARK_ALL_READ, MenuItem(PE_TEXT_CMD_MARK_ALL_READ).c_str());
    AppendMenuW(menu, MF_SEPARATOR, 0, nullptr);
    AppendMenuW(menu, row && row->newFolderAccount ? MF_STRING : MF_STRING | MF_GRAYED, IDM_NEW_FOLDER, MenuItem(PE_TEXT_CMD_NEW_FOLDER).c_str());
    if (row && row->reordersAccounts) {
        AppendMenuW(menu, MF_SEPARATOR, 0, nullptr);
        AppendMoveItems(menu);
    }
    AppendMenuW(menu, MF_SEPARATOR, 0, nullptr);
    AppendMenuW(menu, MF_STRING, IDM_ACCOUNT_PROPERTIES, core::T(PE_TEXT_UI_ACCOUNT_PROPERTIES).c_str());
    TrackPopupMenu(menu, TPM_RIGHTBUTTON, screen.x, screen.y, 0, parent_, nullptr);
    DestroyMenu(menu);
}

// ---- the accounts' order ----

namespace {

// no place to drop at
constexpr size_t kNoGap = std::numeric_limits<size_t>::max();
// while an account is dragged: a moment to scroll the tree when held at its top or bottom edge
constexpr UINT_PTR kDragScrollTimer = 0x41434354;

}  // namespace

int64_t Mailbox::AccountOfRow(HTREEITEM item) const {
    const TreeRow* row = RowAt(item);
    return row && row->reordersAccounts ? row->account : 0;
}

std::vector<HTREEITEM> Mailbox::SiblingRows(HTREEITEM item) const {
    std::vector<HTREEITEM> rows;
    const TreeRow* of = RowAt(item);
    HTREEITEM parent = TreeView_GetParent(tree_, item);
    for (HTREEITEM row = parent ? TreeView_GetChild(tree_, parent) : TreeView_GetRoot(tree_); of && row; row = TreeView_GetNextSibling(tree_, row)) {
        // those that order the accounts: not All Inboxes or Flagged among them
        if (const TreeRow* sibling = RowAt(row); sibling && sibling->reordersAccounts) {
            rows.push_back(row);
        }
    }
    return rows;
}

std::vector<int64_t> Mailbox::AccountOrder() const {
    std::vector<int64_t> order;
    for (const TreeRow& row : treeRows_) {
        if (row.kind == PE_TREE_ROW_KIND_ACCOUNT) {
            order.push_back(row.account);
        }
    }
    return order;
}

void Mailbox::AppendMoveItems(HMENU menu) const {
    std::vector<int64_t> order = AccountOrder();
    auto at = std::find(order.begin(), order.end(), AccountOfRow(TreeView_GetSelection(tree_)));
    bool up = at != order.end() && at != order.begin();
    bool down = at != order.end() && at + 1 != order.end();
    AppendMenuW(menu, up ? MF_STRING : MF_STRING | MF_GRAYED, IDM_ACCOUNT_MOVE_UP, core::T(PE_TEXT_UI_ACCOUNT_MOVE_UP).c_str());
    AppendMenuW(menu, down ? MF_STRING : MF_STRING | MF_GRAYED, IDM_ACCOUNT_MOVE_DOWN, core::T(PE_TEXT_UI_ACCOUNT_MOVE_DOWN).c_str());
}

void Mailbox::MoveAccount(int step) {
    HTREEITEM selected = TreeView_GetSelection(tree_);
    const TreeRow* row = RowAt(selected);
    int64_t account = AccountOfRow(selected);
    std::vector<int64_t> order = AccountOrder();
    auto at = std::find(order.begin(), order.end(), account);
    if (at == order.end()) {
        return;
    }
    ptrdiff_t index = (at - order.begin()) + step;
    if (index < 0 || index >= static_cast<ptrdiff_t>(order.size())) {
        return;
    }
    PlaceAccount(account, static_cast<size_t>(index), row->key);
}

void Mailbox::PlaceAccount(int64_t account, size_t index, std::string key) {
    if (!pe_account_move(core_, account, static_cast<uint32_t>(index))) {
        return;
    }
    Reload();
    // the row moved selected (it may have been another), and in view
    if (HTREEITEM item = FindRow(key)) {
        ChooseRow(item);
    }
}

size_t Mailbox::DropGap(const std::vector<HTREEITEM>& rows, POINT client) const {
    // before the first row whose middle is below the pointer: over an account's folders, after that account
    size_t gap = 0;
    for (HTREEITEM row : rows) {
        RECT rect;
        if (!TreeView_GetItemRect(tree_, row, &rect, FALSE) || client.y < (rect.top + rect.bottom) / 2) {
            break;
        }
        gap++;
    }
    return gap;
}

void Mailbox::ShowGap(const std::vector<HTREEITEM>& rows, size_t gap) {
    if (gap == kNoGap) {
        TreeView_SetInsertMark(tree_, nullptr, FALSE);
    } else if (gap < rows.size()) {
        TreeView_SetInsertMark(tree_, rows[gap], FALSE);
    } else {
        // after the last row and the folders open under it
        HTREEITEM last = rows.back();
        while (TreeView_GetItemState(tree_, last, TVIS_EXPANDED) & TVIS_EXPANDED) {
            HTREEITEM child = TreeView_GetChild(tree_, last);
            if (!child) {
                break;
            }
            while (HTREEITEM next = TreeView_GetNextSibling(tree_, child)) {
                child = next;
            }
            last = child;
        }
        TreeView_SetInsertMark(tree_, last, TRUE);
    }
}

void Mailbox::DragAccount(const NMTREEVIEWW& drag) {
    HTREEITEM item = drag.itemNew.hItem;
    int64_t account = AccountOfRow(item);
    const TreeRow* dragged = RowAt(item);
    std::string key = dragged ? dragged->key : "";
    std::vector<HTREEITEM> rows = account ? SiblingRows(item) : std::vector<HTREEITEM>{};
    size_t from = std::find(rows.begin(), rows.end(), item) - rows.begin();
    if (rows.size() < 2 || from == rows.size()) {
        return;
    }
    uint64_t builds = treeBuilds_;
    size_t gap = kNoGap;
    ULONGLONG edgeSince = 0;
    ULONGLONG scrolled = 0;
    // where the pointer is now: the gap it would drop in (none where the row would stay), the cursor saying so
    auto follow = [&] {
        POINT client;
        GetCursorPos(&client);
        ScreenToClient(tree_, &client);
        RECT bounds;
        GetClientRect(tree_, &bounds);
        bool inside = PtInRect(&bounds, client);
        size_t now = inside ? DropGap(rows, client) : kNoGap;
        if (now == from || now == from + 1) {
            now = kNoGap;
        }
        SetCursor(LoadCursorW(nullptr, inside ? IDC_ARROW : IDC_NO));
        if (now != gap) {
            gap = now;
            ShowGap(rows, gap);
        }
        return client;
    };
    // held at the top or bottom edge, the tree scrolls a line at a time to the rows out of view
    auto scroll = [&](POINT client) {
        RECT bounds;
        GetClientRect(tree_, &bounds);
        int edge = Scale(16);
        bool inside = client.x >= bounds.left && client.x < bounds.right;
        bool up = client.y < bounds.top + edge;
        bool down = client.y >= bounds.bottom - edge;
        ULONGLONG now = GetTickCount64();
        if (!inside || (!up && !down)) {
            edgeSince = 0;
        } else if (!edgeSince) {
            edgeSince = now;
        } else if (now - edgeSince > 400 && now - scrolled > 100) {
            SendMessageW(tree_, WM_VSCROLL, up ? SB_LINEUP : SB_LINEDOWN, 0);
            scrolled = now;
            follow();
        }
    };
    SetCapture(tree_);
    SetTimer(tree_, kDragScrollTimer, 50, nullptr);
    follow();
    bool drop = false;
    MSG msg;
    // a loop of its own until the button is let go, as DoDragDrop has: the rows stay as they are under it
    while (GetCapture() == tree_) {
        if (!GetMessageW(&msg, nullptr, 0, 0)) {
            PostQuitMessage(static_cast<int>(msg.wParam));
            break;
        }
        if (msg.message == WM_LBUTTONUP) {
            drop = true;
            break;
        }
        if ((msg.message == WM_KEYDOWN && msg.wParam == VK_ESCAPE) || msg.message == WM_RBUTTONDOWN) {
            break;
        }
        if (msg.message == WM_MOUSEMOVE) {
            scroll(follow());
            continue;
        }
        if (msg.message == WM_TIMER && msg.hwnd == tree_ && msg.wParam == kDragScrollTimer) {
            POINT client;
            GetCursorPos(&client);
            ScreenToClient(tree_, &client);
            scroll(client);
            continue;
        }
        TranslateMessage(&msg);
        DispatchMessageW(&msg);
        // the tree built again meanwhile (the accounts or their folders changed): its rows are gone, the drag too
        if (treeBuilds_ != builds) {
            break;
        }
    }
    KillTimer(tree_, kDragScrollTimer);
    if (GetCapture() == tree_) {
        ReleaseCapture();
    }
    if (treeBuilds_ != builds) {
        return;
    }
    TreeView_SetInsertMark(tree_, nullptr, FALSE);
    if (!drop || gap == kNoGap) {
        return;
    }
    // the account goes before the account of the row at the gap, or after the last one's
    std::vector<int64_t> order = AccountOrder();
    std::erase(order, account);
    bool after = gap == rows.size();
    int64_t neighbour = AccountOfRow(rows[after ? rows.size() - 1 : gap]);
    auto at = std::find(order.begin(), order.end(), neighbour);
    if (at == order.end()) {
        return;
    }
    PlaceAccount(account, static_cast<size_t>(at - order.begin()) + (after ? 1 : 0), key);
}

std::wstring Mailbox::SelectedName() const {
    if (Searching()) {
        // where the search looks; what it found is on the search bar
        return findPlace_.empty() ? core::T(PE_TEXT_UI_ALL_FOLDERS) : findPlace_;
    }
    // as the core titles the selected row: a folder with its account's name when there are several ("Inbox - Gmail")
    const TreeRow* row = RowAt(TreeView_GetSelection(tree_));
    return row ? row->title : L"";
}

// what an empty list says in its middle: why there is nothing, and what to do about it
void Mailbox::DrawEmptyList(HDC dc) const {
    std::wstring title, more;
    if (Searching()) {
        title = core::T(PE_TEXT_UI_NO_MATCH, {{"words", find_}});
        more = findPlace_.empty() ? core::T(PE_TEXT_UI_NO_MATCH_ALL) : core::T(PE_TEXT_UI_NO_MATCH_IN, {{"folder", findPlace_}});
        if (uint64_t left = pe_search_unindexed_count(core_)) {
            more += L"\n\n" + core::T(PE_TEXT_WIN_NO_MATCH_INDEXING, {{"count", std::to_wstring(left)}});
        }
    } else if (shownList_ != PE_TREE_LIST_NONE && unreadOnly_) {
        title = core::T(PE_TEXT_UI_NO_UNREAD);
    } else if (shownList_ != PE_TREE_LIST_NONE) {
        title = core::T(PE_TEXT_UI_NO_ITEMS);
    } else if (SelectedAccount()) {
        title = core::T(PE_TEXT_UI_CHOOSE_FOLDER);
    } else {
        return;
    }
    RECT area;
    GetClientRect(list_, &area);
    RECT header;
    GetWindowRect(ListView_GetHeader(list_), &header);
    area.top += (header.bottom - header.top) + Scale(28);
    // a short measure, centered, so the lines are easy to read in a wide list
    int width = std::min<int>(area.right - area.left - Scale(48), Scale(420));
    area.left = (area.left + area.right - width) / 2;
    area.right = area.left + width;
    HGDIOBJ old = SelectObject(dc, bold_);
    SetTextColor(dc, GetSysColor(COLOR_GRAYTEXT));
    SetBkMode(dc, TRANSPARENT);
    UINT format = DT_CENTER | DT_WORDBREAK | DT_NOPREFIX;
    RECT line = area;
    DrawTextW(dc, title.c_str(), -1, &line, format | DT_CALCRECT);
    line.left = area.left;
    line.right = area.right;
    DrawTextW(dc, title.c_str(), -1, &line, format);
    if (!more.empty()) {
        SelectObject(dc, reinterpret_cast<HFONT>(SendMessageW(list_, WM_GETFONT, 0, 0)));
        RECT rest = {area.left, line.bottom + Scale(8), area.right, area.bottom};
        DrawTextW(dc, more.c_str(), -1, &rest, format);
    }
    SelectObject(dc, old);
}

bool Mailbox::FolderOf(int64_t folder, std::wstring& name, bool& fixed) const {
    auto found = folderNames_.find(folder);
    if (found == folderNames_.end()) {
        return false;
    }
    name = found->second.first;
    fixed = found->second.second;
    return true;
}

void Mailbox::NewFolder(HWND owner) {
    // where the core says for the selected row: in the folder, or at the account's top (from the Inbox, which holds no
    // folders in the tree, an account's heading, or Flagged with one account)
    const TreeRow* row = SelectedTreeRow();
    if (!row || !row->newFolderAccount) {
        return;
    }
    int64_t account = row->newFolderAccount;
    int64_t parent = row->newFolderParent;
    std::wstring where = core::T(parent ? PE_TEXT_UI_NEW_FOLDER_IN_SELECTED : PE_TEXT_UI_NEW_FOLDER_AT_TOP);
    std::wstring name = AskFolderName(owner, PE_TEXT_CMD_NEW_FOLDER, where, L"");
    if (name.empty()) {
        return;
    }
    char* reason = nullptr;
    if (!pe_folder_create(core_, account, parent, core::Narrow(name).c_str(), &reason)) {
        ShowRefusal(owner, reason, PE_TEXT_UI_FOLDER_NOT_CREATED);
    }
}

void Mailbox::RenameFolder(HWND owner) {
    if (!folder_) {
        return;
    }
    std::wstring current;
    bool fixed = false;
    FolderOf(folder_, current, fixed);
    std::wstring name = AskFolderName(owner, PE_TEXT_CMD_RENAME_FOLDER, core::T(PE_TEXT_UI_RENAME_FOLDER_INTRO, {{"folder", current}}), current);
    if (name.empty() || name == current) {
        return;
    }
    char* reason = nullptr;
    if (!pe_folder_rename(core_, folder_, core::Narrow(name).c_str(), &reason)) {
        ShowRefusal(owner, reason, PE_TEXT_UI_FOLDER_NOT_RENAMED);
    }
}

void Mailbox::DeleteFolder(HWND owner) {
    std::wstring name;
    bool fixed = false;
    if (!folder_ || !FolderOf(folder_, name, fixed)) {
        return;
    }
    std::wstring question = core::T(PE_TEXT_WIN_DELETE_FOLDER_ASK, {{"folder", name}});
    if (MessageBoxW(owner, question.c_str(), L"Inbox Classic", MB_YESNO | MB_ICONWARNING | MB_DEFBUTTON2) != IDYES) {
        return;
    }
    char* reason = nullptr;
    if (!pe_folder_delete(core_, folder_, &reason)) {
        ShowRefusal(owner, reason, PE_TEXT_UI_FOLDER_NOT_DELETED);
    }
}

void Mailbox::EmptyFolder(HWND owner) {
    if (!CanEmptyFolder()) {
        return;
    }
    // the core words the question, with how many go; none when there is nothing to empty
    core::String question(pe_folder_empty_question(core_, folder_));
    if (!question || MessageBoxW(owner, Text(question.get()).c_str(), L"Inbox Classic", MB_YESNO | MB_ICONWARNING | MB_DEFBUTTON2) != IDYES) {
        return;
    }
    char* reason = nullptr;
    core::String done(pe_folder_empty(core_, folder_, &reason));
    Say(done ? Text(done.get()) : ReasonText(reason, PE_TEXT_UI_MESSAGES_NOT_CHANGED));
}

void Mailbox::SelectNeighbour(bool forward) {
    FlushSelection();
    int count = static_cast<int>(std::min<uint64_t>(rowCount_, INT_MAX));
    int focused = ListView_GetNextItem(list_, -1, LVNI_FOCUSED);
    int at = focused < 0 ? (forward ? 0 : -1) : focused + (forward ? 1 : -1);
    if (at < 0 || at >= count) {
        return;
    }
    SelectOnly(at);
}

void Mailbox::NextUnread(HWND owner) {
    FlushSelection();
    int64_t folder = 0;
    uint64_t uid = 0;
    char* question = nullptr;
    PeNextUnread step = pe_list_view_next_unread_step(core_, view_.get(), reader_.Folder(), reader_.Uid(), &folder, &uid, &question);
    core::String asked(question);
    if (step == PE_NEXT_UNREAD_MESSAGE) {
        SelectInList(folder, uid);
        return;
    }
    HTREEITEM row = RowOf(folder);
    if (step != PE_NEXT_UNREAD_ASK || !asked || !row) {
        Say(core::T(PE_TEXT_NO_UNREAD_LEFT));
        return;
    }
    // none left here: on to the folder the core names, after asking, from its top
    if (MessageBoxW(owner, Text(asked.get()).c_str(), L"Inbox Classic", MB_YESNO | MB_ICONQUESTION) != IDYES) {
        return;
    }
    ChooseRow(row);
    int64_t first = folder;
    char* again = nullptr;
    step = pe_list_view_next_unread_step(core_, view_.get(), first, 0, &folder, &uid, &again);
    core::String unused(again);
    if (step == PE_NEXT_UNREAD_MESSAGE) {
        SelectInList(folder, uid);
    }
}

void Mailbox::GoToFolder(HWND owner) {
    FolderPick pick;
    pick.core = core_;
    pick.title = core::Title(PE_TEXT_CMD_GO_TO_FOLDER);
    pick.prompt = core::T(PE_TEXT_UI_GO_TO_PROMPT);
    pick.verb = core::T(PE_TEXT_UI_OK);
    if (HTREEITEM item = RowOf(PickFolder(owner, pick))) {
        ChooseRow(item);
        SetFocus(list_);
    }
}

void Mailbox::FindInMessage(HWND owner, bool again) {
    FlushSelection();
    reader_.FindInMessage(owner, again);
}

bool Mailbox::CanEmptyFolder() const {
    return emptiableFolders_.contains(pe_list_view_own_folder(view_.get())) && total_ > 0;
}

void Mailbox::SetThreadExpanded(int64_t thread, bool open) {
    // the selection taken from the rows as they are shown, before they change
    FlushSelection();
    if (open ? pe_list_view_expand(view_.get(), thread) : pe_list_view_collapse(view_.get(), thread)) {
        ReloadList();
    }
}

void Mailbox::ExpandAll(bool open) {
    if (!Grouped()) {
        return;
    }
    FlushSelection();
    if (open ? pe_list_view_expand_all(core_, view_.get()) : pe_list_view_collapse_all(view_.get())) {
        ReloadList(true);
    }
}

void Mailbox::MarkConversations(PeAction action) {
    Act(action);
}

void Mailbox::UpdateConversationMarks(HMENU menu) {
    // the selection as the core knows it now: an action since it was taken may have changed the marks. A list waiting to
    // be read stays waiting for a menu: nothing is selected in it
    if (!listPending_) {
        FlushSelection();
    }
    // a whole list's numbers come off the window thread, as they are when Select All counted them
    if (!pe_selection_is_all(selection_.get())) {
        RefreshSummary();
    }
    CheckMenuItem(menu, IDM_WATCH_CONVERSATION, MF_BYCOMMAND | (summary_.watched ? MF_CHECKED : MF_UNCHECKED));
    CheckMenuItem(menu, IDM_IGNORE_CONVERSATION, MF_BYCOMMAND | (summary_.ignored ? MF_CHECKED : MF_UNCHECKED));
}

void Mailbox::SetHideIgnored(bool on) {
    if (on == hideIgnored_) {
        return;
    }
    SetPreference(kHideIgnoredPreference, on ? 1 : 0);
    hideIgnored_ = on;
    FlushSelection();
    pe_list_view_set_hide_ignored(view_.get(), on);
    ReloadList(true);
}

void Mailbox::SetUnreadOnly(bool on) {
    if (on == unreadOnly_) {
        return;
    }
    SetPreference(kUnreadOnlyPreference, on ? 1 : 0);
    unreadOnly_ = on;
    FlushSelection();
    pe_list_view_set_show(view_.get(), on ? PE_SHOW_UNREAD : PE_SHOW_ALL);
    ReloadList(true);
}

void Mailbox::SetListPictures(bool on) {
    if (on == listPictures_) {
        return;
    }
    SetPreference(kListPicturesPreference, on ? 1 : 0);
    listPictures_ = on;
    InvalidateRect(list_, nullptr, TRUE);
}

void Mailbox::SetGrouped(bool on) {
    if (on == Grouped()) {
        return;
    }
    SetPreference(kThreadsPreference, on ? 1 : 0);
    FlushSelection();
    // the view closes every conversation
    pe_list_view_set_grouped(view_.get(), on);
    ReloadList(true);
}

bool Mailbox::OnListInput(UINT message, WPARAM wParam, LPARAM lParam) {
    // the dimmed list of the folder before takes no clicks, keys or scrolling while the clicked one's waits
    if (listPending_ && ((message >= WM_LBUTTONDOWN && message <= WM_MOUSELAST) || (message >= WM_KEYFIRST && message <= WM_KEYLAST))) {
        return true;
    }
    if (!Grouped()) {
        return false;
    }
    if (message == WM_LBUTTONDOWN || message == WM_LBUTTONDBLCLK) {
        return OnThreadClick({static_cast<short>(LOWORD(lParam)), static_cast<short>(HIWORD(lParam))});
    }
    if (message != WM_KEYDOWN || (wParam != VK_RIGHT && wParam != VK_LEFT) || GetKeyState(VK_CONTROL) < 0 || GetKeyState(VK_SHIFT) < 0 ||
        GetKeyState(VK_MENU) < 0) {
        return false;
    }
    return OnThreadArrow(wParam == VK_RIGHT);
}

// a click on a + or - box (or left of it) opens or closes the conversation, the selection as it was
bool Mailbox::OnThreadClick(POINT at) {
    if (columns_) {
        LVHITTESTINFO hit = {};
        hit.pt = at;
        int index = ListView_HitTest(list_, &hit);
        const PeMessage* row = RowNow(index);
        RECT box = index >= 0 ? ColumnsThreadBox(ColumnsRowRect(index)) : RECT{};
        InflateRect(&box, Scale(4), Scale(4));
        if (!row || !row->thread_opens || !PtInRect(&box, at)) {
            return false;
        }
        SetFocus(list_);
        SetThreadExpanded(row->thread, row->thread_collapsed);
        return true;
    }
    LVHITTESTINFO hit = {};
    hit.pt = at;
    if (ListView_SubItemHitTest(list_, &hit) < 0 || hit.iSubItem != COL_SUBJECT) {
        return false;
    }
    const PeMessage* row = RowNow(hit.iItem);
    if (!row || !row->thread_opens || at.x > ThreadBox(SubjectCell(hit.iItem)).right + Scale(3)) {
        return false;
    }
    SetFocus(list_);
    SetThreadExpanded(row->thread, row->thread_collapsed);
    return true;
}

// as in a tree: Right opens a conversation, then goes to its first reply; Left closes it, from a reply too. Closed,
// the list is shown again with the message of the reading pane selected where it is now: a reply's conversation row
bool Mailbox::OnThreadArrow(bool right) {
    const PeMessage* row = RowNow(ListView_GetNextItem(list_, -1, LVNI_FOCUSED));
    if (!row || (row->thread_depth == 0 && !row->thread_opens)) {
        return false;
    }
    if (right) {
        if (!row->thread_opens) {
            return false;
        }
        if (row->thread_collapsed) {
            SetThreadExpanded(row->thread, true);
        } else {
            SelectNeighbour(true);
        }
        return true;
    }
    if (row->thread_collapsed) {
        return false;
    }
    SetThreadExpanded(row->thread, false);
    return true;
}

std::wstring Mailbox::Counts() const {
    if (!pe_list_view_active(view_.get())) {
        return L"";
    }
    core::String counts(pe_list_counts(total_, unread_, SelectedCount(), Searching()));
    return counts ? Text(counts.get()) : L"";
}

// ---- messages from the controls and the core ----

bool Mailbox::OnNotify(NMHDR* header, LRESULT& result) {
    if (header->hwndFrom == tree_) {
        if (header->code == TVN_SELCHANGEDW && !reloading_) {
            auto* change = reinterpret_cast<NMTREEVIEWW*>(header);
            const TreeRow* row = RowAt(change->itemNew.hItem);
            TreeRow none;
            const TreeRow& place = row ? *row : none;
            // the row to start with next time; a heading lists nothing
            if (row && row->list != PE_TREE_LIST_NONE) {
                pe_tree_chosen(core_, row->key.c_str());
            }
            // an account has no messages of its own (folder 0); the folder bar and the title name what is selected: an account too, from another account's item, and
            // the same Inbox from its other row. Clicked or chosen with a key, the highlight is painted before the list is
            // read; chosen by the app, the list is read at once for what follows
            if (!OnFolderSelected(place.folder, place.list)) {
                SendMessageW(parent_, WM_COMMAND, MAKEWPARAM(IDC_TREE, 0), 0);
            }
        }
        if (header->code == TVN_ITEMEXPANDEDW) {
            // collapsed, a row shows the unread messages it hides; expanded, its folders show them again
            OnRowExpanded(*reinterpret_cast<NMTREEVIEWW*>(header));
        }
        if (header->code == TVN_BEGINDRAGW) {
            DragAccount(*reinterpret_cast<NMTREEVIEWW*>(header));
        }
        if (header->code == NM_CUSTOMDRAW) {
            TreeCustomDraw(reinterpret_cast<NMTVCUSTOMDRAW*>(header), result);
            return true;
        }
        if (header->code == NM_RCLICK) {
            FolderMenu();
            // handled: no WM_CONTEXTMENU after it
            result = 1;
            return true;
        }
        return header->code == TVN_SELCHANGEDW;
    }
    if (reader_.OnNotify(header, result)) {
        return true;
    }
    if (header->hwndFrom == ListView_GetHeader(list_) && (header->code == HDN_ITEMCHANGEDW || header->code == HDN_ITEMCHANGEDA)) {
        // a column made wider or narrower moves the headers after it, by the user or by the layout (the list sends this
        // for ListView_SetColumnWidth too): the one place the tooltips follow them
        PlaceHeaderTips();
        return false;
    }
    return header->hwndFrom == list_ && OnListNotify(header, result);
}

bool Mailbox::OnListNotify(NMHDR* header, LRESULT& result) {
    switch (header->code) {
    case LVN_GETDISPINFOW:
        DisplayInfo(reinterpret_cast<NMLVDISPINFOW*>(header));
        return true;
    case NM_CUSTOMDRAW:
        CustomDraw(reinterpret_cast<NMLVCUSTOMDRAW*>(header), result);
        return true;
    case LVN_ITEMCHANGED: {
        auto* changed = reinterpret_cast<NMLISTVIEW*>(header);
        if ((changed->uChanged & LVIF_STATE) && ((changed->uOldState ^ changed->uNewState) & LVIS_SELECTED)) {
            RepaintRows(changed->iItem, changed->iItem);
        }
        if (!reloading_ && (changed->uChanged & LVIF_STATE)) {
            ScheduleSelection();
        }
        return true;
    }
    case LVN_ODSTATECHANGED: {
        // a range of rows selected at once (Shift+click) in the list of owner data
        auto* range = reinterpret_cast<NMLVODSTATECHANGE*>(header);
        RepaintRows(range->iFrom, range->iTo);
        if (!reloading_) {
            ScheduleSelection();
        }
        return true;
    }
    case LVN_BEGINDRAG:
        BeginDrag(reinterpret_cast<NMLISTVIEW*>(header)->iItem);
        return true;
    case NM_RCLICK: {
        POINT screen;
        GetCursorPos(&screen);
        MessageMenu(screen);
        result = 1;
        return true;
    }
    case LVN_ITEMACTIVATE:
        // double-click; Enter comes as IDOK of the window (OnCommand)
        OpenSelected();
        return true;
    case LVN_KEYDOWN:
        // Delete in the list, not as a shortcut of the window: in a text field it deletes text
        if (reinterpret_cast<NMLVKEYDOWN*>(header)->wVKey == VK_DELETE) {
            DeleteSelected();
        }
        // A archives, as in Thunderbird; with Ctrl or Alt it is another command's
        if (reinterpret_cast<NMLVKEYDOWN*>(header)->wVKey == 'A' && GetKeyState(VK_CONTROL) >= 0 && GetKeyState(VK_MENU) >= 0) {
            ArchiveSelected();
        }
        // N goes to the next unread message, W watches the conversation and K ignores it (Thunderbird's keys), only
        // without Ctrl, Alt or Shift
        if (GetKeyState(VK_CONTROL) >= 0 && GetKeyState(VK_MENU) >= 0 && GetKeyState(VK_SHIFT) >= 0) {
            switch (reinterpret_cast<NMLVKEYDOWN*>(header)->wVKey) {
            case 'N':
                NextUnread(parent_);
                break;
            case 'W':
                MarkConversations(PE_ACTION_WATCH);
                break;
            case 'K':
                MarkConversations(PE_ACTION_IGNORE);
                break;
            }
        }
        return true;
    case LVN_COLUMNCLICK: {
        int column = reinterpret_cast<NMLISTVIEW*>(header)->iSubItem;
        if (IsIconColumn(column)) {
            return true;
        }
        PeSortField sort = SortOf(column);
        // the same column again turns the order around; another starts its own way (dates and sizes the largest first)
        if (sort == sort_) {
            SetAscending(!ascending_);
        } else {
            SortBy(sort);
        }
        return true;
    }
    }
    return false;
}

// ---- files and printing ----

namespace {

// what a save or forward of several messages off the window thread finished with
struct FilesDoneInfo {
    // a forward: the new message, from `account`
    core::Draft draft;
    int64_t account = 0;
    // a save: how many went into the folder `place`
    size_t saved = 0;
    std::wstring place;
    // why not, when it did not
    std::wstring problem;
};

}  // namespace

void Mailbox::SaveSelectedInto(HWND owner) {
    FlushSelection();
    // a whole list's messages listed, to go through them one by one
    ListSelection();
    std::wstring dir = FolderDialog(owner, core::Plain(PE_TEXT_UI_SAVE_MESSAGES_IN).c_str());
    if (dir.empty()) {
        return;
    }
    // those not downloaded yet come first: said in the status bar meanwhile
    if (core::String downloading(pe_selection_downloading_text(core_, selection_.get())); downloading) {
        Say(Text(downloading.get()));
    }
    std::thread([core = core_, selection = CopyOf(selection_.get()), dir, window = parent_]() mutable {
        auto done = std::make_unique<FilesDoneInfo>();
        done->place = dir;
        char* reason = nullptr;
        if (PeTextList* paths = pe_selection_save(core, selection.get(), core::Narrow(dir).c_str(), 120000, &reason)) {
            done->saved = pe_text_list_count(paths);
            pe_text_list_free(paths);
        } else {
            done->problem = ReasonText(reason, PE_TEXT_WIN_MESSAGES_NOT_SAVED);
        }
        PostMessageW(window, WM_FILES_DONE, 0, reinterpret_cast<LPARAM>(done.release()));
    }).detach();
}

void Mailbox::ForwardSelected() {
    FlushSelection();
    // a whole list's messages listed, to go through them one by one
    ListSelection();
    int64_t folder = 0;
    uint64_t uid = 0;
    if (!pe_selection_get(selection_.get(), 0, &folder, &uid)) {
        return;
    }
    // from the account of the first of them
    auto found = folderAccounts_.find(folder);
    int64_t account = found != folderAccounts_.end() ? found->second : CurrentAccount();
    if (core::String downloading(pe_selection_downloading_text(core_, selection_.get())); downloading) {
        Say(Text(downloading.get()));
    }
    std::thread([core = core_, selection = CopyOf(selection_.get()), account, window = parent_]() mutable {
        auto done = std::make_unique<FilesDoneInfo>();
        done->account = account;
        char* reason = nullptr;
        done->draft.reset(pe_selection_forward(core, selection.get(), 120000, &reason));
        if (!done->draft) {
            done->problem = ReasonText(reason, PE_TEXT_WIN_MESSAGES_NOT_FORWARDED);
        }
        PostMessageW(window, WM_FILES_DONE, 0, reinterpret_cast<LPARAM>(done.release()));
    }).detach();
}

void Mailbox::FilesDone(LPARAM lParam) {
    std::unique_ptr<FilesDoneInfo> done(reinterpret_cast<FilesDoneInfo*>(lParam));
    if (!done->problem.empty()) {
        Say(L"");
        MessageBoxW(parent_, done->problem.c_str(), L"Inbox Classic", MB_OK | MB_ICONWARNING);
        return;
    }
    if (done->draft) {
        Say(L"");
        OpenCompose(parent_, core_, done->account, pe_draft_info(done->draft.get()));
        return;
    }
    Say(Text(core::String(pe_saved_text(done->saved, core::Narrow(done->place).c_str())).get()));
}

void Mailbox::SaveShownAs(HWND owner) {
    if (!reader_.Uid()) {
        return;
    }
    size_t length = 0;
    char* name = nullptr;
    uint8_t* data = pe_message_source(core_, reader_.Folder(), reader_.Uid(), &length, &name);
    core::String safeName(name);
    if (!data) {
        MessageBoxW(owner, core::T(PE_TEXT_UI_NOT_DOWNLOADED).c_str(), L"Inbox Classic", MB_OK | MB_ICONINFORMATION);
        return;
    }
    std::wstring filter = FileFilter({{core::T(PE_TEXT_UI_FILTER_MESSAGES), L"*.eml"}, {core::T(PE_TEXT_UI_FILTER_ALL), L"*.*"}});
    std::wstring path = SaveFileDialog(owner, Text(safeName.get()), core::Plain(PE_TEXT_UI_SAVE_MESSAGE_AS).c_str(), filter.c_str(), L"eml");
    if (!path.empty()) {
        if (WriteFileBytes(path, data, length)) {
            MarkFromInternet(path);
        } else {
            MessageBoxW(owner, core::T(PE_TEXT_UI_NOT_SAVED).c_str(), L"Inbox Classic", MB_OK | MB_ICONERROR);
        }
    }
    pe_bytes_free(data, length);
}

void Mailbox::ShowProperties(HWND owner) {
    if (!reader_.Uid()) {
        MessageBoxW(owner, core::T(PE_TEXT_UI_SELECT_MESSAGE_FIRST).c_str(), L"Inbox Classic", MB_OK | MB_ICONINFORMATION);
        return;
    }
    core::String headers(pe_message_headers(core_, reader_.Folder(), reader_.Uid()));
    if (!headers) {
        MessageBoxW(owner, core::T(PE_TEXT_UI_NOT_DOWNLOADED).c_str(), L"Inbox Classic", MB_OK | MB_ICONINFORMATION);
        return;
    }
    const PeMessageInfo* info = reader_.Info();
    std::wstring subject = info ? Text(info->subject) : L"";
    TextDialog(owner, subject.empty() ? core::Title(PE_TEXT_CMD_PROPERTIES) : core::T(PE_TEXT_UI_PROPERTIES_OF, {{"subject", subject}}),
               core::T(PE_TEXT_UI_INTERNET_HEADERS), Text(headers.get()));
}

void Mailbox::AddSenderToBook(HWND owner) {
    if (!reader_.Uid()) {
        MessageBoxW(owner, core::T(PE_TEXT_UI_SELECT_MESSAGE_FIRST).c_str(), L"Inbox Classic", MB_OK | MB_ICONINFORMATION);
        return;
    }
    bool added = false;
    char* status = nullptr;
    pe_book_add_sender(core_, reader_.Folder(), reader_.Uid(), &added, &status);
    core::String said(status);
    Say(said ? Text(said.get()) : L"");
    if (added) {
        AddressBookChanged();
    }
}

void Mailbox::CreateRuleFromShown(HWND owner) {
    if (!reader_.Uid()) {
        MessageBoxW(owner, core::T(PE_TEXT_UI_SELECT_MESSAGE_FIRST).c_str(), L"Inbox Classic", MB_OK | MB_ICONINFORMATION);
        return;
    }
    core::String query(pe_rule_query_of_message(core_, reader_.Folder(), reader_.Uid()));
    NewRuleDialog(owner, core_, query ? Text(query.get()) : L"");
}

void Mailbox::ShowSource(HWND owner) {
    if (!reader_.Uid()) {
        MessageBoxW(owner, core::T(PE_TEXT_UI_SELECT_MESSAGE_FIRST).c_str(), L"Inbox Classic", MB_OK | MB_ICONINFORMATION);
        return;
    }
    char* title = nullptr;
    core::String text(pe_message_source_text(core_, reader_.Folder(), reader_.Uid(), &title));
    core::String titleText(title);
    if (!text) {
        MessageBoxW(owner, core::T(PE_TEXT_UI_NOT_DOWNLOADED).c_str(), L"Inbox Classic", MB_OK | MB_ICONINFORMATION);
        return;
    }
    // Save As from here saves the message shown, as File > Save As does
    SourceDialog(owner, Text(titleText.get()), Text(text.get()), [this](HWND window) { SaveShownAs(window); });
}

// the right-click menu of the message list: the actions on the message under the mouse (selected first), as Outlook
// Express has them, with the choices that fit it (Mark as Unread for a read one, Not Junk in Junk E-mail)
void Mailbox::MessageMenu(POINT screen) {
    POINT asked = screen;
    int index = ListView_GetNextItem(list_, -1, LVNI_SELECTED);
    if (screen.x != -1 || screen.y != -1) {
        LVHITTESTINFO hit = {};
        hit.pt = screen;
        ScreenToClient(list_, &hit.pt);
        index = ListView_HitTest(list_, &hit);
        if (index < 0) {
            return;
        }
        // a row of the selection keeps it; another row is selected alone
        if (!(ListView_GetItemState(list_, index, LVIS_SELECTED) & LVIS_SELECTED)) {
            ListView_SetItemState(list_, -1, 0, LVIS_SELECTED);
        }
        ListView_SetItemState(list_, index, LVIS_SELECTED | LVIS_FOCUSED, LVIS_SELECTED | LVIS_FOCUSED);
    } else if (index >= 0) {
        // the menu key: the menu at the selected row
        RECT row = {LVIR_LABEL};
        ListView_GetItemRect(list_, index, &row, LVIR_LABEL);
        screen = {row.left + Scale(8), row.bottom};
        ClientToScreen(list_, &screen);
    }
    const PeMessage* message = index >= 0 ? RowNow(index) : nullptr;
    if (!message) {
        return;
    }
    // the menu is for the selection as it is now, a whole list's counted for it off the window thread first
    FlushSelection();
    if (AfterSummary([this, asked] { MessageMenu(asked); })) {
        return;
    }
    // with several selected, what works on one message alone is there but off (as the menu opens), so the menu does not
    // change shape
    bool draft = SelectedCount() == 1 && draftFolders_.contains(message->folder);
    HMENU menu = CreatePopupMenu();
    if (draft) {
        AppendMenuW(menu, MF_STRING, IDOK, MenuItem(PE_TEXT_UI_MENU_OPEN).c_str());
        SetMenuDefaultItem(menu, IDOK, FALSE);
        AppendMenuW(menu, MF_SEPARATOR, 0, nullptr);
    }
    AppendMenuW(menu, MF_STRING, IDM_REPLY, MenuItem(PE_TEXT_CMD_REPLY).c_str());
    AppendMenuW(menu, MF_STRING, IDM_REPLY_ALL, MenuItem(PE_TEXT_CMD_REPLY_ALL).c_str());
    AppendMenuW(menu, MF_STRING, IDM_FORWARD, MenuItem(PE_TEXT_CMD_FORWARD).c_str());
    AppendMenuW(menu, MF_SEPARATOR, 0, nullptr);
    // read when any of them is unread
    bool read = summary_.unread == 0;
    AppendMenuW(menu, MF_STRING, read ? IDM_MARK_UNREAD : IDM_MARK_READ, MenuItem(read ? PE_TEXT_CMD_MARK_UNREAD : PE_TEXT_CMD_MARK_READ).c_str());
    // the colours and Clear Flag (the menu bar keeps Flag Message, its shortcut, beside it)
    AppendMenuW(menu, MF_POPUP, reinterpret_cast<UINT_PTR>(FlagMenu()), MenuItem(PE_TEXT_UI_MENU_FLAG).c_str());
    // whether the conversations are watched or ignored: the check marks say it, as the list has no column for it
    AppendMenuW(menu, MF_STRING | (summary_.watched ? MF_CHECKED : 0), IDM_WATCH_CONVERSATION,
                MenuItem(PE_TEXT_CMD_WATCH_CONVERSATION, L"W").c_str());
    AppendMenuW(menu, MF_STRING | (summary_.ignored ? MF_CHECKED : 0), IDM_IGNORE_CONVERSATION,
                MenuItem(PE_TEXT_CMD_IGNORE_CONVERSATION, L"K").c_str());
    AppendMenuW(menu, MF_STRING | (CanArchive() ? 0 : MF_GRAYED), IDM_ARCHIVE, MenuItem(PE_TEXT_CMD_ARCHIVE, L"A").c_str());
    bool junk = summary_.in_junk;
    AppendMenuW(menu, MF_STRING, junk ? IDM_NOT_JUNK : IDM_JUNK, MenuItem(junk ? PE_TEXT_CMD_NOT_JUNK : PE_TEXT_CMD_JUNK).c_str());
    AppendMenuW(menu, MF_STRING | (SelectedCount() > 1 ? MF_GRAYED : 0), IDM_CREATE_RULE_FROM_MESSAGE,
                MenuItem(PE_TEXT_CMD_CREATE_RULE_FROM_MESSAGE).c_str());
    // the message shown is of a mailing list whose bar offers leaving it
    if (CanUnsubscribe()) {
        AppendMenuW(menu, MF_STRING, IDM_UNSUBSCRIBE, MenuItem(PE_TEXT_CMD_UNSUBSCRIBE).c_str());
    }
    AppendMenuW(menu, MF_STRING, IDM_MOVE, MenuItem(PE_TEXT_CMD_MOVE).c_str());
    AppendMenuW(menu, MF_STRING, IDM_COPY, MenuItem(PE_TEXT_CMD_COPY).c_str());
    AppendMenuW(menu, MF_STRING, IDM_DELETE, MenuItem(PE_TEXT_WIN_DELETE_BUTTON).c_str());
    AppendMenuW(menu, MF_SEPARATOR, 0, nullptr);
    AppendMenuW(menu, MF_STRING, IDM_SAVE_AS, MenuItem(PE_TEXT_WIN_SAVE_AS_BUTTON).c_str());
    AppendMenuW(menu, MF_STRING, IDM_PRINT, MenuItem(PE_TEXT_CMD_PRINT).c_str());
    AppendMenuW(menu, MF_SEPARATOR, 0, nullptr);
    AppendMenuW(menu, MF_STRING | (SelectedCount() > 1 ? MF_GRAYED : 0), IDM_ADD_SENDER_TO_BOOK, MenuItem(PE_TEXT_CMD_ADD_SENDER_TO_BOOK).c_str());
    AppendMenuW(menu, MF_SEPARATOR, 0, nullptr);
    AppendMenuW(menu, MF_STRING, IDM_VIEW_SOURCE, MenuItem(PE_TEXT_UI_MENU_VIEW_SOURCE).c_str());
    AppendMenuW(menu, MF_STRING, IDM_PROPERTIES, DialogMenuItem(PE_TEXT_UI_PROPERTIES).c_str());
    lastMenu_ = menu;
    TrackPopupMenu(menu, TPM_RIGHTBUTTON, screen.x, screen.y, 0, parent_, nullptr);
    lastMenu_ = nullptr;
    DestroyMenu(menu);
}

void Mailbox::PrintShown() {
    reader_.Print(parent_);
}

void Mailbox::Import(HWND owner) {
    int64_t folder = pe_list_view_own_folder(view_.get());
    if (!folder) {
        MessageBoxW(owner, core::T(PE_TEXT_UI_IMPORT_CHOOSE_FOLDER).c_str(), core::Title(PE_TEXT_CMD_IMPORT).c_str(), MB_OK | MB_ICONINFORMATION);
        return;
    }
    std::vector<std::wstring> files = OpenFilesDialog(owner, core::Title(PE_TEXT_CMD_IMPORT).c_str(),
        FileFilter({{core::T(PE_TEXT_UI_FILTER_MESSAGES), L"*.eml"}, {core::T(PE_TEXT_UI_FILTER_ALL), L"*.*"}}).c_str());
    if (!files.empty()) {
        ImportFiles(folder, files, owner);
    }
}

// ---- the Find box ----

int Mailbox::PlaceFind(const RECT& row, int buttonsRight) {
    // its usual width, narrower down to a minimum where the toolbar's buttons need the room
    int width = std::clamp(static_cast<int>(row.right) - buttonsRight - Scale(16), Scale(150), Scale(280));
    int height = Scale(26), edge = GetSystemMetrics(SM_CXEDGE);
    int left = static_cast<int>(row.right) - width - Scale(8);
    MoveWindow(findField_, left, row.top + (row.bottom - row.top - height) / 2, width, height, TRUE);
    // over the toolbar the row is part of
    SetWindowPos(findField_, HWND_TOP, 0, 0, 0, 0, SWP_NOMOVE | SWP_NOSIZE | SWP_NOACTIVATE);
    // in the field: the magnifier, the box (as high as its text, centered) and the clear button
    int inner = height - 2 * edge, icon = iconSize_ + Scale(8), clear = iconSize_ + Scale(8);
    MoveWindow(findIcon_, 0, 0, icon, inner, TRUE);
    HDC dc = GetDC(findEdit_);
    HGDIOBJ old = SelectObject(dc, reinterpret_cast<HFONT>(SendMessageW(findEdit_, WM_GETFONT, 0, 0)));
    TEXTMETRICW metrics = {};
    GetTextMetricsW(dc, &metrics);
    SelectObject(dc, old);
    ReleaseDC(findEdit_, dc);
    int text = metrics.tmHeight + Scale(2);
    MoveWindow(findEdit_, icon, (inner - text) / 2, width - 2 * edge - icon - clear, text, TRUE);
    MoveWindow(findClear_, width - 2 * edge - clear, 0, clear, inner, TRUE);
    return left;
}

bool Mailbox::OnDrawItem(const DRAWITEMSTRUCT& item) {
    if (reader_.OnDrawItem(item)) {
        return true;
    }
    if (item.hwndItem == sortButton_) {
        DrawSortButton(item);
        return true;
    }
    if (item.hwndItem == searchBar_) {
        // the magnifier, then what was found, on the information bar's yellow
        RECT area = item.rcItem;
        FillRect(item.hDC, &area, GetSysColorBrush(COLOR_INFOBK));
        int pad = Scale(6);
        ImageList_Draw(listIcons_, LIST_SEARCH, item.hDC, area.left + pad, (area.top + area.bottom - iconSize_) / 2, ILD_TRANSPARENT);
        area.left += pad + iconSize_ + pad;
        RECT clear, rule;
        GetWindowRect(searchClear_, &clear);
        GetWindowRect(searchRule_, &rule);
        area.right -= (clear.right - clear.left) + (rule.right - rule.left) + pad;
        HGDIOBJ old = SelectObject(item.hDC, reinterpret_cast<HFONT>(SendMessageW(list_, WM_GETFONT, 0, 0)));
        SetTextColor(item.hDC, GetSysColor(COLOR_INFOTEXT));
        SetBkMode(item.hDC, TRANSPARENT);
        DrawTextW(item.hDC, searchSummary_.c_str(), -1, &area, DT_LEFT | DT_VCENTER | DT_SINGLELINE | DT_NOPREFIX | DT_END_ELLIPSIS);
        SelectObject(item.hDC, old);
        return true;
    }
    if (item.hwndItem == undoneBar_) {
        DrawUndoneBar(item);
        return true;
    }
    if (item.hwndItem != findIcon_ && item.hwndItem != findClear_ && item.hwndItem != undoneClose_) {
        return false;
    }
    FillRect(item.hDC, &item.rcItem, GetSysColorBrush(item.hwndItem == undoneClose_ ? COLOR_INFOBK : COLOR_WINDOW));
    int icon = item.hwndItem == findIcon_ ? LIST_SEARCH : LIST_DISMISS;
    int pushed = (item.itemState & ODS_SELECTED) ? 1 : 0;
    int x = (item.rcItem.left + item.rcItem.right - iconSize_) / 2 + pushed;
    int y = (item.rcItem.top + item.rcItem.bottom - iconSize_) / 2 + pushed;
    ImageList_Draw(listIcons_, icon, item.hDC, x, y, ILD_TRANSPARENT);
    return true;
}

// the mail with the error mark, then why, wrapped, on the information bar's yellow as the search bar has it
void Mailbox::DrawUndoneBar(const DRAWITEMSTRUCT& item) const {
    RECT area = item.rcItem;
    FillRect(item.hDC, &area, GetSysColorBrush(COLOR_INFOBK));
    int pad = Scale(6);
    ImageList_Draw(listIcons_, LIST_MAIL_ERROR, item.hDC, area.left + pad, area.top + Scale(3), ILD_TRANSPARENT);
    area.left += pad + iconSize_ + pad;
    area.right -= Scale(22) + pad;
    area.top += Scale(4);
    HGDIOBJ old = SelectObject(item.hDC, normal_);
    SetTextColor(item.hDC, GetSysColor(COLOR_INFOTEXT));
    SetBkMode(item.hDC, TRANSPARENT);
    DrawTextW(item.hDC, undoneText_.c_str(), -1, &area, DT_LEFT | DT_WORDBREAK | DT_NOPREFIX);
    SelectObject(item.hDC, old);
}

void Mailbox::FocusFind() {
    SetFocus(findEdit_);
    SendMessageW(findEdit_, EM_SETSEL, 0, -1);
}

// the Find box emptied and the search dropped, without the list following it (the caller reloads)
void Mailbox::ResetFind() {
    SetWindowTextW(findEdit_, L"");
    // emptying the box fires EN_CHANGE, which starts the timer again
    KillTimer(parent_, TIMER_FIND);
    find_.clear();
    pe_list_view_set_text(view_.get(), nullptr);
    findPlace_.clear();
}

void Mailbox::Search(const std::wstring& words) {
    SetWindowTextW(findEdit_, words.c_str());
    ShowWindow(findClear_, words.empty() ? SW_HIDE : SW_SHOW);
    // at once, not a moment after the last key
    OnTimer(TIMER_FIND);
    SetFocus(list_);
}

bool Mailbox::ClearFind() {
    if (find_.empty() && GetWindowTextLengthW(findEdit_) == 0) {
        return false;
    }
    ResetFind();
    SendMessageW(parent_, WM_COMMAND, MAKEWPARAM(IDC_TREE, 0), 0);
    ReloadList(true);
    SetFocus(list_);
    return true;
}

bool Mailbox::OnCommand(WORD id, WORD code) {
    if (id == IDC_SORT_BUTTON) {
        ShowSortMenu();
        return true;
    }
    if (id == IDC_FIND) {
        if (code == EN_CHANGE) {
            // a moment after the last key, not for each
            SetTimer(parent_, TIMER_FIND, 250, nullptr);
            ShowWindow(findClear_, GetWindowTextLengthW(findEdit_) > 0 ? SW_SHOW : SW_HIDE);
        }
        return true;
    }
    if (id == IDC_FIND_CLEAR) {
        // the search ends, and the box is ready for another
        ClearFind();
        SetFocus(findEdit_);
        return true;
    }
    if (id == IDC_FIND_FIELD && code == STN_CLICKED) {
        // a click in the field but beside the box: the caret at the end of what is typed
        SetFocus(findEdit_);
        SendMessageW(findEdit_, EM_SETSEL, GetWindowTextLengthW(findEdit_), -1);
        return true;
    }
    if (id == IDOK && GetFocus() == list_) {
        OpenSelected();
        return true;
    }
    if (id == IDC_SEARCH_CLEAR) {
        ClearFind();
        return true;
    }
    if (id == IDC_UNDONE_CLOSE) {
        ShowUndone(L"");
        SetFocus(list_);
        return true;
    }
    if (id == IDC_SEARCH_RULE) {
        // the words searched for, as the rule's: the editor says why when they can not be one's
        NewRuleDialog(parent_, core_, find_);
        return true;
    }
    return reader_.OnCommand(id, code);
}

// ---- dragging messages: onto a folder, out of the app as files, files into a folder ----

void Mailbox::BeginDrag(int index) {
    FlushSelection();
    const PeMessage* row = RowNow(index);
    if (!row || pe_selection_count(selection_.get()) == 0) {
        return;
    }
    ListSelection();
    // the folder they are all in takes nothing; from several folders any takes them
    int64_t folder = 0;
    uint64_t uid = 0;
    pe_selection_get(selection_.get(), 0, &folder, &uid);
    dragFrom_ = summary_.folders <= 1 ? folder : 0;
    IDataObject* data = MessagesData(core_, selection_.get());
    SIZE size = {};
    HBITMAP image = DragImage(reinterpret_cast<HFONT>(SendMessageW(list_, WM_GETFONT, 0, 0)), Text(row->subject),
                              pe_selection_count(selection_.get()), size);
    // the cursor a little inside the image's left edge, as where the row was picked up
    RunDrag(data, image, size, {Scale(12), size.cy / 2});
    data->Release();
    dragFrom_ = 0;
}

int64_t Mailbox::DropFolder(DropFrom from, POINT screen, HTREEITEM& over) const {
    over = nullptr;
    if (from == DropFrom::Nothing) {
        return 0;
    }
    TVHITTESTINFO hit = {};
    hit.pt = screen;
    ScreenToClient(tree_, &hit.pt);
    over = TreeView_HitTest(tree_, &hit);
    if (!over || !(hit.flags & (TVHT_ONITEM | TVHT_ONITEMRIGHT | TVHT_ONITEMINDENT))) {
        over = nullptr;
        return 0;
    }
    // a row the core says takes no messages (an account's own, All Inboxes, Flagged), the folder they are all in, or
    // one that holds no messages: not there. A folder of another account takes them too, the core moves them across
    const TreeRow* row = RowAt(over);
    int64_t folder = row && row->dropTarget ? row->folder : 0;
    if (folder <= 0 || unselectable_.count(folder) || !folderAccounts_.contains(folder)) {
        return 0;
    }
    if (from == DropFrom::Messages && folder == dragFrom_) {
        return 0;
    }
    return folder;
}

void Mailbox::ChangeTreeUnderDrag(const std::function<void()>& change) {
    ShowDragImage(treeTarget_, false);
    change();
    UpdateWindow(tree_);
    ShowDragImage(treeTarget_, true);
}

DWORD Mailbox::TreeSite::Over(DropFrom from, POINT screen, DWORD keys, DWORD allowed) {
    Mailbox& box = *mailbox;
    HTREEITEM over = nullptr;
    int64_t target = box.DropFolder(from, screen, over);
    DragOver& drag = box.dragOver_;
    if (over != drag.over) {
        drag.over = over;
        drag.overSince = GetTickCount64();
        drag.opened = false;
    }
    if (target != drag.target) {
        drag.target = target;
        // the folder it would go to highlighted
        box.ChangeTreeUnderDrag([&] { TreeView_SelectDropTarget(box.tree_, target ? over : nullptr); });
    }
    // held at the top or bottom edge of the tree it scrolls, a line at a time, to the folders out of view
    RECT tree;
    GetWindowRect(box.tree_, &tree);
    int edge = Scale(16);
    bool atEdge = screen.y < tree.top + edge || screen.y >= tree.bottom - edge;
    ULONGLONG now = GetTickCount64();
    if (!atEdge) {
        drag.edgeSince = 0;
    } else if (!drag.edgeSince) {
        drag.edgeSince = now;
    } else if (now - drag.edgeSince > 400 && now - drag.scrolled > 100) {
        WPARAM scroll = screen.y < tree.top + edge ? SB_LINEUP : SB_LINEDOWN;
        box.ChangeTreeUnderDrag([&] { SendMessageW(box.tree_, WM_VSCROLL, scroll, 0); });
        drag.scrolled = now;
    }
    // a folder held over for a moment opens, to the folders in it
    if (drag.over && !drag.opened && GetTickCount64() - drag.overSince > 800) {
        box.ChangeTreeUnderDrag([&] { TreeView_Expand(box.tree_, drag.over, TVE_EXPAND); });
        drag.opened = true;
    }
    if (!target) {
        return DROPEFFECT_NONE;
    }
    // files are put in; messages move, and with Ctrl are copied, as in Explorer
    if (from == DropFrom::Files) {
        return allowed & DROPEFFECT_COPY;
    }
    DWORD wanted = (keys & MK_CONTROL) ? DROPEFFECT_COPY : DROPEFFECT_MOVE;
    return allowed & wanted;
}

void Mailbox::TreeSite::Leave() {
    Mailbox& box = *mailbox;
    box.dragOver_ = {};
    box.ChangeTreeUnderDrag([&] { TreeView_SelectDropTarget(box.tree_, nullptr); });
}

DWORD Mailbox::TreeSite::Dropped(IDataObject* data, DropFrom from, POINT screen, DWORD keys, DWORD allowed) {
    Mailbox& box = *mailbox;
    DWORD effect = Over(from, screen, keys, allowed);
    int64_t target = box.dragOver_.target;
    Leave();
    if (!effect || !target) {
        return DROPEFFECT_NONE;
    }
    if (from == DropFrom::Files) {
        // put in once the drop is over, not while the program the files come from waits for it
        PostMessageW(box.parent_, WM_IMPORT_DROPPED, static_cast<WPARAM>(target),
                     reinterpret_cast<LPARAM>(new std::vector<std::wstring>(DroppedFiles(data))));
        return DROPEFFECT_COPY;
    }
    // the list's own drag carries the selection; a move selects the message after them, as Move to Folder does
    box.Act(effect == DROPEFFECT_COPY ? PE_ACTION_COPY : PE_ACTION_MOVE, target);
    return effect;
}

DWORD Mailbox::ListSite::Over(DropFrom from, POINT, DWORD, DWORD allowed) {
    // files go into the folder shown; not into a list of several folders (All Inboxes, a search)
    int64_t folder = pe_list_view_own_folder(mailbox->view_.get());
    return from == DropFrom::Files && folder && !mailbox->unselectable_.count(folder) ? (allowed & DROPEFFECT_COPY) : DROPEFFECT_NONE;
}

DWORD Mailbox::ListSite::Dropped(IDataObject* data, DropFrom from, POINT screen, DWORD keys, DWORD allowed) {
    if (!Over(from, screen, keys, allowed)) {
        return DROPEFFECT_NONE;
    }
    PostMessageW(mailbox->parent_, WM_IMPORT_DROPPED, static_cast<WPARAM>(pe_list_view_own_folder(mailbox->view_.get())),
                 reinterpret_cast<LPARAM>(new std::vector<std::wstring>(DroppedFiles(data))));
    return DROPEFFECT_COPY;
}

void Mailbox::ImportFiles(int64_t folder, const std::vector<std::wstring>& files, HWND owner) {
    std::vector<std::string> paths;
    for (const std::wstring& file : files) {
        paths.push_back(core::Narrow(file));
    }
    std::vector<const char*> pointers;
    for (const std::string& path : paths) {
        pointers.push_back(path.c_str());
    }
    // what went in for the status bar, and what did not, as the core says them
    char* said = nullptr;
    char* report = nullptr;
    pe_import_files(core_, folder, pointers.data(), pointers.size(), &said, &report);
    if (core::String text(said); text) {
        Say(Text(text.get()));
    }
    if (core::String told(report); told) {
        MessageBoxW(owner, Text(told.get()).c_str(), core::Title(PE_TEXT_CMD_IMPORT).c_str(), MB_OK | MB_ICONWARNING);
    }
}

void Mailbox::ImportDropped(WPARAM folder, LPARAM files) {
    std::unique_ptr<std::vector<std::wstring>> paths(reinterpret_cast<std::vector<std::wstring>*>(files));
    ImportFiles(static_cast<int64_t>(folder), *paths, parent_);
}

int Mailbox::TestDragOut(const std::wstring& dir) {
    FlushSelection();
    // a whole list's messages listed, to go through them one by one
    ListSelection();
    if (pe_selection_count(selection_.get()) == 0) {
        return -1;
    }
    IDataObject* data = MessagesData(core_, selection_.get());
    int written = WriteDataInto(data, dir);
    data->Release();
    return written;
}

DWORD Mailbox::TestDropFiles(HTREEITEM item, const std::vector<std::wstring>& paths) {
    IDataObject* data = FilesData(paths);
    if (!data) {
        return DROPEFFECT_NONE;
    }
    // where a drop onto the item lands: its middle, as the mouse would let go there
    RECT box = {};
    TreeView_GetItemRect(tree_, item, &box, TRUE);
    POINT screen = {(box.left + box.right) / 2, (box.top + box.bottom) / 2};
    ClientToScreen(tree_, &screen);
    DWORD effect = treeSite_.Dropped(data, DropKind(data), screen, 0, DROPEFFECT_COPY | DROPEFFECT_MOVE);
    data->Release();
    return effect;
}

void Mailbox::OnTimer(UINT_PTR id) {
    if (id == TIMER_SELECTION) {
        FlushSelection();
        return;
    }
    if (reader_.OnTimer(id)) {
        return;
    }
    if (id == TIMER_COUNTS) {
        KillTimer(parent_, TIMER_COUNTS);
        countsPending_ = false;
        UpdateCounts();
        return;
    }
    if (id == TIMER_LOAD_LIST) {
        if (!holdList_) {
            LoadPendingList();
        }
        return;
    }
    if (id == TIMER_LIST_LOADING) {
        KillTimer(parent_, TIMER_LIST_LOADING);
        listLoadingShown_ = listPending_;
        InvalidateRect(list_, nullptr, FALSE);
        return;
    }
    if (id == TIMER_RELOAD) {
        KillTimer(parent_, TIMER_RELOAD);
        reloadPending_ = false;
        // the UI test holds a list waiting: read with it once let go. A list the user's own command read again since
        // the changes is up to date already
        if ((holdList_ && listPending_) || !pe_list_view_stale(core_, view_.get())) {
            return;
        }
        ReloadList();
        SendMessageW(parent_, WM_COMMAND, MAKEWPARAM(IDC_TREE, 0), 0);
        return;
    }
    if (id == TIMER_FIND) {
        KillTimer(parent_, TIMER_FIND);
        std::wstring text = GetWindowString(findEdit_);
        // what only has spaces finds everything, as the core reads it
        size_t first = text.find_first_not_of(L" \t");
        text = first == std::wstring::npos ? L"" : text.substr(first, text.find_last_not_of(L" \t") - first + 1);
        if (text != find_) {
            find_ = text;
            std::string utf8 = core::Narrow(find_);
            // new words close every conversation the view has open
            pe_list_view_set_text(view_.get(), utf8.c_str());
            core::String place(pe_search_place(utf8.c_str()));
            findPlace_ = place ? Text(place.get()) : L"";
            ReloadList(true);
            SendMessageW(parent_, WM_COMMAND, MAKEWPARAM(IDC_TREE, 0), 0);
        }
        return;
    }
    if (id != TIMER_MARK_READ) {
        return;
    }
    KillTimer(parent_, TIMER_MARK_READ);
    const PeMessage* row = SelectedRow();
    if (row && row->uid == reader_.Uid() && row->folder == reader_.Folder() && !row->seen) {
        // read after a moment on screen: no word of it in the status bar
        pe_message_set_seen(core_, row->folder, row->uid, true);
        ReloadList();
    }
}

void Mailbox::OnEvent(const UiEvent& event) {
    switch (event.kind) {
    case PE_EVENT_KIND_FOLDERS_CHANGED:
        Reload();
        // an open Move and Copy window shows the folders as they are now
        RefreshFolderPick(0);
        break;
    case PE_EVENT_KIND_FOLDER_CREATED:
        if (newInPick_) {
            newInPick_ = false;
            RefreshFolderPick(event.folder);
        }
        break;
    case PE_EVENT_KIND_FOLDER_CHANGED:
        ScheduleCounts();
        // the folder shown, or a list of several folders, which has messages of any of them
        if ((event.folder == folder_ && !Searching()) || SeveralFolders()) {
            ScheduleReload();
        }
        break;
    case PE_EVENT_KIND_PICTURE_READY:
        PictureReady(event.uid);
        break;
    case PE_EVENT_KIND_LIST_READY:
        OnListLoaded(event.uid);
        break;
    case PE_EVENT_KIND_LIST_PAGE_READY:
        OnPageLoaded(event.uid);
        break;
    case PE_EVENT_KIND_ACTED:
        OnActed(event);
        break;
    case PE_EVENT_KIND_ACTION_UNDONE:
        // the rows are back already (FolderChanged): why, over the list; the status bar no longer says it was done
        ShowUndone(event.message);
        Say(L"");
        // the messages back in the list now, and selected there as what Undo brings back is
        undoPending_ = true;
        ReloadList();
        break;
    case PE_EVENT_KIND_READ_DONE:
        if (summaryRequest_ && event.uid == summaryRequest_) {
            SummaryDone(event.uid);
        } else if (draftRead_.Done(event.uid)) {
            OpenDraftRead(event.uid);
        }
        break;
    case PE_EVENT_KIND_MESSAGE_READY:
        // fetched now: a draft that was double-clicked before opens
        if (event.folder == reader_.Folder() && event.uid == reader_.Uid() && std::exchange(openWhenReady_, false)) {
            OpenSelected();
        }
        break;
    default:
        break;
    }
    reader_.OnEvent(event);
}

// ---- the deep test's driver (--test-hooks only) ----

namespace {

// `text` as a JSON string, quotes included
std::string JsonString(std::string_view text) {
    std::string out = "\"";
    for (unsigned char c : text) {
        switch (c) {
        case '"': out += "\\\""; break;
        case '\\': out += "\\\\"; break;
        case '\n': out += "\\n"; break;
        case '\r': out += "\\r"; break;
        case '\t': out += "\\t"; break;
        default:
            if (c < 0x20) {
                char escaped[8];
                snprintf(escaped, sizeof escaped, "\\u%04x", c);
                out += escaped;
            } else {
                out += static_cast<char>(c);
            }
        }
    }
    return out + "\"";
}

std::vector<std::wstring> SplitTabs(const std::wstring& text) {
    std::vector<std::wstring> words;
    size_t start = 0;
    for (;;) {
        size_t tab = text.find(L'\t', start);
        words.push_back(text.substr(start, tab == std::wstring::npos ? std::wstring::npos : tab - start));
        if (tab == std::wstring::npos) {
            return words;
        }
        start = tab + 1;
    }
}

// a folder's path as the user reads it (each level's modified UTF-7 decoded)
std::string DecodedPath(const char* path) {
    core::String decoded(pe_folder_path_decoded(path));
    return decoded ? decoded.get() : "";
}

} // namespace

std::string Mailbox::DeepNotes() const {
    // the list's own state, for the report beside a failure: what it waits for and what it holds
    std::string notes = "load " + std::to_string(loadRequest_) + (listPending_ ? " pending" : "") +
                        (newList_ ? " new" : "") + (reloadPending_ ? " reload" : "") + " rows " +
                        std::to_string(rowCount_) + " top " + std::to_string(ListView_GetTopIndex(list_)) + "; pages";
    for (const Page& page : pages_) {
        notes += " " + std::to_string(page.offset);
    }
    notes += "; asked";
    for (const auto& [offset, request] : pageRequests_) {
        notes += " " + std::to_string(offset) + ":" + std::to_string(request);
    }
    return notes;
}

bool Mailbox::DrawnCurrent() {
    // the rows in sight as drawn: each the message there, or blank while its page is not read
    int count = ListView_GetItemCount(list_);
    int top = ListView_GetTopIndex(list_);
    int last = std::min(count, top + ListView_GetCountPerPage(list_) + 1);
    std::vector<PeDrawnRow> drawn;
    for (int row = top; row < last; row++) {
        const PeMessage* m = CachedRow(row);
        drawn.push_back({static_cast<uint64_t>(row), m ? m->folder : 0, m ? m->uid : 0});
    }
    return pe_list_view_drawn_current(core_, view_.get(), static_cast<uint64_t>(count), drawn.data(), drawn.size());
}

LRESULT Mailbox::TestDeep(const std::wstring& request) {
    std::vector<std::wstring> words = SplitTabs(request);
    const std::wstring& verb = words[0];
    auto word = [&](size_t i) { return i < words.size() ? core::Narrow(words[i]) : std::string(); };
    // a number of the request, 0 for none or one that does not read as a number (never an exception in the window
    // procedure)
    auto number = [&](size_t i) -> int {
        return i < words.size() ? static_cast<int>(std::wcstol(words[i].c_str(), nullptr, 10)) : 0;
    };
    // the account named so, 0 for none
    auto accountNamed = [&](const std::string& name) -> int64_t {
        for (const auto& [id, title] : accountNames_) {
            if (core::Narrow(title) == name) {
                return id;
            }
        }
        return 0;
    };
    // the folder of the account named `account` at `path`, 0 for none
    auto folderAt = [&](const std::string& account, const std::string& path) -> int64_t {
        int64_t id = accountNamed(account);
        core::FolderList folders(pe_folders(core_, id));
        for (size_t i = 0; i < pe_folder_list_count(folders.get()); i++) {
            const PeFolder* folder = pe_folder_list_get(folders.get(), i);
            if (folder && DecodedPath(folder->path) == path) {
                return folder->id;
            }
        }
        return 0;
    };
    if (verb == L"ping") {
        return 11;
    }
    if (verb == L"account" && words.size() >= 7) {
        std::string name = word(1), email = word(2), user = word(3), password = word(4);
        PeAccountSettings settings{.name = name.c_str(),
                                   .email = email.c_str(),
                                   .username = user.c_str(),
                                   .imap_host = "127.0.0.1",
                                   .imap_port = static_cast<uint16_t>(number(5)),
                                   .imap_security = PE_SECURITY_PLAIN,
                                   .smtp_host = "127.0.0.1",
                                   .smtp_port = static_cast<uint16_t>(number(6)),
                                   // ImapKit's SMTP server takes AUTH after STARTTLS only
                                   .smtp_security = PE_SECURITY_START_TLS};
        int64_t id = pe_account_add(core_, &settings, password.c_str());
        if (id <= 0) {
            // 2: the core did not add it
            return 2;
        }
        pe_account_set_name(core_, id, name.c_str());
        // a message sent goes at once
        pe_set_send_delay_index(core_, 0);
        pe_sync(core_, id);
        Reload();
        return static_cast<LRESULT>(id + 10);
    }
    if (verb == L"open" && words.size() >= 2) {
        std::string key = word(1);
        if (key == "folder") {
            key = "folder:" + std::to_string(folderAt(word(2), word(3)));
        }
        HTREEITEM item = FindRow(key);
        if (!item) {
            return 10;
        }
        ChooseRow(item);
        return 11;
    }
    if (verb == L"move" && words.size() >= 3) {
        int64_t to = folderAt(word(1), word(2));
        return to && Act(PE_ACTION_MOVE, to) ? 11 : 10;
    }
    if (verb == L"group" && words.size() >= 2) {
        SetGrouped(words[1] == L"1");
        return 11;
    }
    if (verb == L"select" && words.size() >= 3) {
        int from = number(1), to = number(2);
        SetFocus(list_);
        ListView_SetItemState(list_, -1, 0, LVIS_SELECTED);
        for (int row = std::min(from, to); row <= std::max(from, to); row++) {
            ListView_SetItemState(list_, row, LVIS_SELECTED, LVIS_SELECTED);
        }
        ListView_SetItemState(list_, to, LVIS_FOCUSED, LVIS_FOCUSED);
        ListView_EnsureVisible(list_, to, FALSE);
        return 11;
    }
    if (verb == L"scroll" && words.size() >= 2) {
        // the row at the top: to the end first, then back up to it, as a scroll bar dragged leaves it
        int row = number(1);
        int count = ListView_GetItemCount(list_);
        if (count > 0) {
            ListView_EnsureVisible(list_, count - 1, FALSE);
            ListView_EnsureVisible(list_, std::clamp(row, 0, count - 1), FALSE);
        }
        return 11;
    }
    if (verb == L"barrier") {
        pe_sync_barrier(core_);
        return 11;
    }
    if (verb == L"quiet") {
        // the core quiet and no load of the list under way (it selects again)
        return pe_quiet(core_) && !loadRequest_ ? 11 : 10;
    }
    if (verb == L"current") {
        // the rows drawn the list as the store has it now: whatever is still on its way to the window (an event, a
        // reload gathering changes, a page, a paint) leaves them other than the core reads them
        return DrawnCurrent() ? 11 : 10;
    }
    if (verb == L"observe" && words.size() >= 2) {
        // the folders' places, for the messages' account and path
        std::unordered_map<int64_t, std::pair<std::string, std::string>> places;
        std::string tree;
        for (const auto& [id, title] : accountNames_) {
            core::FolderList folders(pe_folders(core_, id));
            for (size_t i = 0; i < pe_folder_list_count(folders.get()); i++) {
                const PeFolder* folder = pe_folder_list_get(folders.get(), i);
                if (!folder) {
                    continue;
                }
                std::string path = DecodedPath(folder->path);
                places[folder->id] = {core::Narrow(title), path};
                tree += (tree.empty() ? "" : ",") + std::string("[") + JsonString(core::Narrow(title)) + "," +
                        JsonString(path) + "," + std::to_string(folder->unread) + "]";
            }
        }
        auto message = [&](int64_t folder, uint64_t uid) -> std::string {
            auto place = places.find(folder);
            if (place == places.end() || !uid) {
                return "null";
            }
            return "{\"account\":" + JsonString(place->second.first) + ",\"path\":" + JsonString(place->second.second) +
                   ",\"uid\":" + std::to_string(uid) + "}";
        };
        std::string list = "null";
        switch (shownList_) {
        case PE_TREE_LIST_ALL_INBOXES: list = "\"inboxes\""; break;
        case PE_TREE_LIST_FLAGGED: list = "\"flagged\""; break;
        case PE_TREE_LIST_ALL_SENT: list = "\"sent\""; break;
        case PE_TREE_LIST_ALL_DRAFTS: list = "\"drafts\""; break;
        case PE_TREE_LIST_FOLDER:
            if (auto place = places.find(folder_); place != places.end()) {
                list = "{\"account\":" + JsonString(place->second.first) + ",\"path\":" + JsonString(place->second.second) + "}";
            }
            break;
        default: break;
        }
        int count = ListView_GetItemCount(list_);
        int top = ListView_GetTopIndex(list_);
        int last = std::min(count, top + ListView_GetCountPerPage(list_) + 1);
        std::string sight;
        for (int row = top; row < last; row++) {
            const PeMessage* m = CachedRow(row);
            sight += (sight.empty() ? "" : ",") + std::string("{\"row\":") + std::to_string(row);
            if (m) {
                sight += ",\"blank\":false,\"message\":" + message(m->folder, m->uid) + ",\"subject\":" +
                         JsonString(m->subject ? m->subject : "") + ",\"date\":" + std::to_string(m->has_date ? m->date : 0);
            } else {
                sight += ",\"blank\":true";
            }
            sight += "}";
        }
        std::string selected;
        for (int row = ListView_GetNextItem(list_, -1, LVNI_SELECTED); row >= 0; row = ListView_GetNextItem(list_, row, LVNI_SELECTED)) {
            selected += (selected.empty() ? "" : ",") + std::to_string(row);
        }
        std::string seen = "{\"list\":" + list + ",\"rows\":" + std::to_string(count) + ",\"sight\":[" + sight +
                           "],\"selected\":[" + selected + "],\"shown\":" + message(reader_.Folder(), reader_.Uid()) +
                           ",\"grouped\":" + (Grouped() ? "true" : "false") + ",\"unreadOnly\":" +
                           (UnreadOnly() ? "true" : "false") + ",\"tree\":[" + tree + "]" +
                           // a list chosen and not read yet: the rows drawn, dimmed, are still the list before's
                           ",\"pending\":" + (newList_ ? "true" : "false") + ",\"notes\":" + JsonString(DeepNotes()) + "}";
        std::ofstream out(std::filesystem::path(words[1]), std::ios::binary);
        out << seen;
        return out.good() ? 11 : 10;
    }
    return 0;
}
