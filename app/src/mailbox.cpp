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
#include <limits>
#include <span>
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
// the data of the All Inboxes item: neither a folder (positive) nor an account (a negated id)
constexpr LPARAM kAllInboxesItem = std::numeric_limits<LPARAM>::min();
// the data of a row under All Inboxes: its folder id with this bit, so it is told from the account's row of the folder
static_assert(sizeof(LPARAM) == 8);
constexpr LPARAM kUnderAllInboxes = LPARAM{1} << 62;
// the rows of the tree the user closed, kept for the next start: "all" for All Inboxes and the ids of accounts
const wchar_t* kClosedRowsPreference = L"ClosedFolderRows";

// what a tree row is, from its data
struct TreePlace {
    int64_t folder = 0;
    int64_t account = 0;
    bool allInboxes = false;
    bool underAllInboxes = false;
};
TreePlace PlaceOf(LPARAM data) {
    TreePlace place;
    if (data == kAllInboxesItem) {
        place.allInboxes = true;
    } else if (data < 0) {
        place.account = -data;
    } else {
        place.underAllInboxes = (data & kUnderAllInboxes) != 0;
        place.folder = data & ~kUnderAllInboxes;
    }
    return place;
}
std::wstring AllInboxes() {
    return core::T(PE_TEXT_UI_ALL_INBOXES);
}

// as Outlook Express has them: the paper clip, the flag and the Watch column (glasses, or the sign of an ignored
// conversation), then the text columns; no read and unread column: bold says it
enum Column { COL_ATTACH, COL_FLAG, COL_FROM, COL_SUBJECT, COL_RECEIVED, COL_FOLDER };

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

// the icon of a folder in the tree, by what it is for
int IconOfFolder(PeSpecialUse use) {
    switch (use) {
    case PE_SPECIAL_USE_INBOX:
        return FOLDER_MAIL_INBOX;
    case PE_SPECIAL_USE_SENT:
        return FOLDER_SEND;
    case PE_SPECIAL_USE_DRAFTS:
        return FOLDER_DRAFTS;
    case PE_SPECIAL_USE_TRASH:
        return FOLDER_DELETE;
    case PE_SPECIAL_USE_JUNK:
        return FOLDER_MAIL_PROHIBITED;
    case PE_SPECIAL_USE_ARCHIVE:
        return FOLDER_ARCHIVE;
    case PE_SPECIAL_USE_FLAGGED:
        return FOLDER_FLAG;
    case PE_SPECIAL_USE_ALL:
        return FOLDER_MAIL_MULTIPLE;
    default:
        return FOLDER_FOLDER;
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

// a column that shows an icon of the list strip in its header (the paper clip, the flag, the glasses) and nothing else
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
    IconColumn(list_, COL_ATTACH, LIST_ATTACH);
    IconColumn(list_, COL_FLAG, LIST_FLAG);
    AddColumn(list_, COL_FROM, core::T(PE_TEXT_UI_COL_FROM).c_str(), 200);
    AddColumn(list_, COL_SUBJECT, core::T(PE_TEXT_UI_COL_SUBJECT).c_str(), 320);
    AddColumn(list_, COL_RECEIVED, core::T(PE_TEXT_UI_COL_RECEIVED).c_str(), 130);

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
    // over the list while searching, in the colors of the information bar: what was found, and a link to end it
    searchBar_ = CreateChild(parent, L"STATIC", L"", SS_OWNERDRAW | WS_BORDER | WS_CLIPSIBLINGS, IDC_SEARCH_BAR, {});
    searchClear_ = CreateChild(parent, L"STATIC", core::T(PE_TEXT_UI_CLEAR_SEARCH).c_str(), SS_NOTIFY | SS_CENTERIMAGE | SS_CENTER | SS_NOPREFIX,
                               IDC_SEARCH_CLEAR, {});
    ShowWindow(searchBar_, SW_HIDE);
    ShowWindow(searchClear_, SW_HIDE);

    LOGFONTW font = {};
    GetObjectW(GetStockObject(DEFAULT_GUI_FONT), sizeof(font), &font);
    font.lfUnderline = TRUE;
    link_ = CreateFontIndirectW(&font);
    SendMessageW(searchClear_, WM_SETFONT, reinterpret_cast<WPARAM>(link_), FALSE);
    font.lfUnderline = FALSE;
    font.lfWeight = FW_BOLD;
    bold_ = CreateFontIndirectW(&font);
    // the list's own (a stock font, not deleted)
    normal_ = reinterpret_cast<HFONT>(SendMessageW(list_, WM_GETFONT, 0, 0));
    if (!normal_) {
        normal_ = static_cast<HFONT>(GetStockObject(DEFAULT_GUI_FONT));
    }
    ClearReader();
    Reload();
}

void Mailbox::Destroy() {
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
    reader_.Destroy();
    pages_.clear();
    DeleteObject(bold_);
    bold_ = nullptr;
    DeleteObject(link_);
    link_ = nullptr;
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

// how wide the words of a link are, in the link font
int Mailbox::LinkWidth(HWND link) const {
    return TextWidth(link, link_);
}

// the search bar over the list while it is shown, the list under it
void Mailbox::LayoutList() {
    RECT list = listArea_;
    int width = list.right - list.left;
    if (IsWindowVisible(searchBar_)) {
        int height = Scale(22), edge = GetSystemMetrics(SM_CXBORDER);
        MoveWindow(searchBar_, list.left, list.top, width, height, TRUE);
        // the link inside the bar's border, at its right, as wide as its words
        int linkWidth = LinkWidth(searchClear_) + Scale(16);
        MoveWindow(searchClear_, list.right - edge - linkWidth, list.top + edge, linkWidth, height - 2 * edge, TRUE);
        SetWindowPos(searchClear_, HWND_TOP, 0, 0, 0, 0, SWP_NOMOVE | SWP_NOSIZE | SWP_NOACTIVATE);
        list.top += height + Scale(2);
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
        LayoutList();
    }
}

bool Mailbox::OnSetCursor(HWND window) {
    if (reader_.OnSetCursor(window)) {
        return true;
    }
    if (window != searchClear_) {
        return false;
    }
    // the link on the information bar
    SetCursor(LoadCursorW(nullptr, IDC_HAND));
    return true;
}

bool Mailbox::OnCtlColor(HWND window, HDC dc, LRESULT& brush) {
    if (reader_.OnCtlColor(window, dc, brush)) {
        return true;
    }
    if (window != searchClear_) {
        return false;
    }
    // a link on the information bar
    SetTextColor(dc, GetSysColor(COLOR_HOTLIGHT));
    SetBkColor(dc, GetSysColor(COLOR_INFOBK));
    brush = reinterpret_cast<LRESULT>(GetSysColorBrush(COLOR_INFOBK));
    return true;
}

// ---- the folder tree ----

void Mailbox::Reload() {
    int64_t selected = folder_;
    bool allSelected = allInboxes_;
    bool underSelected = underAllInboxes_;
    int64_t accountSelected = selectedAccount_;
    // deleting the items changes the selection: not a folder the user picked
    reloading_ = true;
    treeBuilds_++;
    TreeView_DeleteAllItems(tree_);
    reloading_ = false;
    items_.clear();
    inboxItems_.clear();
    inboxTitles_.clear();
    rows_.clear();
    accountItems_.clear();
    accountNames_.clear();
    folderAccounts_.clear();
    folderNames_.clear();
    unselectable_.clear();
    allInboxesItem_ = nullptr;
    draftFolders_.clear();
    inboxFolders_.clear();
    junkFolders_.clear();
    emptiableFolders_.clear();
    firstAccount_ = 0;
    core::AccountList accounts(pe_accounts(core_));
    size_t count = pe_account_list_count(accounts.get());
    std::vector<int64_t> ids;
    for (size_t i = 0; i < count; i++) {
        ids.push_back(pe_account_list_get(accounts.get(), i)->id);
    }
    LoadClosedRows(ids);
    if (pe_all_inboxes_shown(count)) {
        // above the accounts, the mail of every Inbox, with each account's Inbox under it; its unread count is theirs,
        // shown while it is closed as a folder's with closed subfolders
        allInboxesItem_ = InsertItem(tree_, TVI_ROOT, AllInboxes(), kAllInboxesItem, false, FOLDER_MAIL_INBOX);
        rows_[allInboxesItem_] = {AllInboxes(), 0, pe_inbox_unread(core_)};
        FillAllInboxes();
        if (!allInboxesClosed_) {
            TreeView_Expand(tree_, allInboxesItem_, TVE_EXPAND);
        }
        ShowRow(allInboxesItem_);
    }
    for (size_t i = 0; i < count; i++) {
        const PeAccount* account = pe_account_list_get(accounts.get(), i);
        accountNames_[account->id] = Text(account->title);
        accountEmails_[account->id] = Text(account->email);
        accountSignIns_[account->id] = {account->oauth, account->app};
        if (!firstAccount_) {
            firstAccount_ = account->id;
        }
        // an account's own item carries its id negated, so selecting it tells which account it is
        HTREEITEM root = InsertItem(tree_, TVI_ROOT, Text(account->title), static_cast<LPARAM>(-account->id), false, FOLDER_MAILBOX);
        accountItems_[account->id] = root;
        rows_[root] = {Text(account->title), 0, 0};
        FillAccount(root, account->id);
        // open unless the user closed it; TVM_EXPAND sends no TVN_ITEMEXPANDED, so the row is shown here
        if (!closedAccounts_.contains(account->id)) {
            TreeView_Expand(tree_, root, TVE_EXPAND);
        }
        ShowRow(root);
    }
    // what was selected, again; All Inboxes gone with one account left: that account's Inbox (as the window starts)
    HTREEITEM target = nullptr;
    bool same = true;
    if (allSelected && allInboxesItem_) {
        target = allInboxesItem_;
    } else if (allSelected) {
        bool all = false;
        int64_t inbox = 0;
        uint64_t uid = 0;
        if (pe_start_message(core_, &all, &inbox, &uid) && items_.contains(inbox)) {
            target = items_[inbox];
            same = false;
        }
    } else if (auto inbox = inboxItems_.find(selected); underSelected && inbox != inboxItems_.end()) {
        target = inbox->second;
    } else if (auto item = items_.find(selected); item != items_.end()) {
        target = item->second;
        // a row under All Inboxes gone with All Inboxes: the account's row is another place
        same = !underSelected;
    } else if (auto root = accountItems_.find(accountSelected); !selected && root != accountItems_.end()) {
        target = root->second;
    }
    if (target) {
        // the same folder again is no folder the user picked; the Inbox in place of All Inboxes is shown
        reloading_ = same;
        TreeView_SelectItem(tree_, target);
        reloading_ = false;
    } else if (selected || allSelected) {
        // the folder is gone
        OnFolderSelected(0);
    }
}

void Mailbox::FillAllInboxes() {
    core::SpecialFolderList inboxes(pe_special_folders(core_, PE_SPECIAL_FOLDER_KIND_INBOX));
    size_t count = pe_special_folder_list_count(inboxes.get());
    for (size_t i = 0; i < count; i++) {
        const PeSpecialFolder* inbox = pe_special_folder_list_get(inboxes.get(), i);
        // named as the account; no subfolders here, those are under the account
        std::wstring name = Text(inbox->name);
        HTREEITEM item = InsertItem(tree_, allInboxesItem_, CountedLabel(name, inbox->unread), static_cast<LPARAM>(inbox->folder) | kUnderAllInboxes,
                                    inbox->unread > 0, FOLDER_MAIL_INBOX);
        inboxItems_[inbox->folder] = item;
        inboxTitles_[inbox->folder] = Text(inbox->title);
        rows_[item] = {name, inbox->unread, 0};
    }
}

void Mailbox::LoadClosedRows(const std::vector<int64_t>& accounts) {
    allInboxesClosed_ = false;
    closedAccounts_.clear();
    std::wstring kept = GetTextPreference(kClosedRowsPreference);
    size_t start = 0;
    bool dropped = false;
    while (start < kept.size()) {
        size_t end = kept.find(L',', start);
        std::wstring part = kept.substr(start, end == std::wstring::npos ? std::wstring::npos : end - start);
        start = end == std::wstring::npos ? kept.size() : end + 1;
        if (part == L"all") {
            allInboxesClosed_ = true;
            continue;
        }
        int64_t id = _wcstoi64(part.c_str(), nullptr, 10);
        // a removed account's entry is dropped
        if (std::find(accounts.begin(), accounts.end(), id) != accounts.end()) {
            closedAccounts_.insert(id);
        } else {
            dropped = true;
        }
    }
    if (dropped) {
        SaveClosedRows();
    }
}

void Mailbox::SaveClosedRows() const {
    std::wstring kept = allInboxesClosed_ ? L"all" : L"";
    std::vector<int64_t> ids(closedAccounts_.begin(), closedAccounts_.end());
    std::sort(ids.begin(), ids.end());
    for (int64_t id : ids) {
        kept += (kept.empty() ? L"" : L",") + std::to_wstring(id);
    }
    SetTextPreference(kClosedRowsPreference, kept);
}

// a row opened or closed by the user: its unread count shown again, and All Inboxes and the accounts remembered
void Mailbox::OnRowExpanded(const NMTREEVIEWW& change) {
    ShowRow(change.itemNew.hItem);
    if (change.action != TVE_EXPAND && change.action != TVE_COLLAPSE) {
        return;
    }
    bool closed = change.action == TVE_COLLAPSE;
    TreePlace place = PlaceOf(change.itemNew.lParam);
    if (place.allInboxes) {
        allInboxesClosed_ = closed;
    } else if (place.account && closed) {
        closedAccounts_.insert(place.account);
    } else if (place.account) {
        closedAccounts_.erase(place.account);
    } else {
        return;
    }
    SaveClosedRows();
}

void Mailbox::FillAccount(HTREEITEM root, int64_t account) {
    core::FolderList folders(pe_folders(core_, account));
    size_t count = pe_folder_list_count(folders.get());
    // the last item at each depth, the parent of the next deeper one
    std::vector<HTREEITEM> parents = {root};
    for (size_t i = 0; i < count; i++) {
        const PeFolder* folder = pe_folder_list_get(folders.get(), i);
        size_t depth = std::min<size_t>(folder->depth, parents.size() - 1);
        HTREEITEM item = InsertItem(tree_, parents[depth], CountedLabel(Text(folder->name), folder->unread), static_cast<LPARAM>(folder->id),
                                    folder->unread > 0, IconOfFolder(folder->special_use));
        items_[folder->id] = item;
        rows_[item] = {Text(folder->name), folder->unread, folder->unread_below};
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
        parents.resize(depth + 1);
        parents.push_back(item);
    }
    rows_[root].below = pe_folder_list_unread(folders.get());
}

// a row with its unread count: its own while expanded, with what it hides while collapsed (an account's row has
// none of its own), bold when there is one
void Mailbox::ShowRow(HTREEITEM item) {
    auto row = rows_.find(item);
    if (row == rows_.end()) {
        return;
    }
    bool expanded = (TreeView_GetItemState(tree_, item, TVIS_EXPANDED) & TVIS_EXPANDED) != 0;
    uint64_t unread = row->second.own + (expanded ? 0 : row->second.below);
    std::wstring label = CountedLabel(row->second.name, unread);
    TVITEMW update = {};
    update.mask = TVIF_TEXT | TVIF_STATE;
    update.hItem = item;
    update.pszText = label.data();
    update.stateMask = TVIS_BOLD;
    update.state = unread > 0 ? TVIS_BOLD : 0;
    TreeView_SetItem(tree_, &update);
}

// the labels and bold states of the folders of an account; a folder the tree does not have yet builds it again
void Mailbox::UpdateFolders(int64_t account) {
    core::FolderList folders(pe_folders(core_, account));
    size_t count = pe_folder_list_count(folders.get());
    for (size_t i = 0; i < count; i++) {
        const PeFolder* folder = pe_folder_list_get(folders.get(), i);
        auto item = items_.find(folder->id);
        if (item == items_.end()) {
            Reload();
            return;
        }
        rows_[item->second] = {Text(folder->name), folder->unread, folder->unread_below};
        ShowRow(item->second);
        // its row under All Inboxes, with the same count
        if (auto inbox = inboxItems_.find(folder->id); inbox != inboxItems_.end()) {
            rows_[inbox->second].own = folder->unread;
            ShowRow(inbox->second);
        }
    }
    auto root = accountItems_.find(account);
    if (root != accountItems_.end()) {
        rows_[root->second].below = pe_folder_list_unread(folders.get());
        ShowRow(root->second);
    }
    if (allInboxesItem_) {
        rows_[allInboxesItem_].below = pe_inbox_unread(core_);
        ShowRow(allInboxesItem_);
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
    return selectedAccount_ ? selectedAccount_ : firstAccount_;
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
    core::Draft draft(pe_draft_open(core_, folder, uid));
    if (!draft) {
        // not fetched yet: MessageReady follows
        openWhenReady_ = true;
        return;
    }
    OpenCompose(parent_, core_, CurrentAccount(), pe_draft_info(draft.get()));
}

core::Draft Mailbox::DraftOfShown(PeDraftKind kind) const {
    return reader_.DraftOf(kind);
}

// ---- the message list ----

MessageListOrder Mailbox::ListOrder() const {
    // a message window goes through the messages one by one, the conversations left out. Words typed search every
    // folder of every account (in: narrows that); without, the list is the folder's, or every Inbox's
    MessageListOrder order;
    order.view.reset(pe_list_view_clone(view_.get()));
    pe_list_view_set_grouped(order.view.get(), false);
    order.folder = Searching() ? 0 : folder_;
    order.allInboxes = !Searching() && allInboxes_;
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
    std::wstring title = core::T(Searching() ? PE_TEXT_UI_COL_FOLDER : PE_TEXT_UI_COL_ACCOUNT);
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
void Mailbox::ShowPersonColumn() {
    bool wanted = pe_list_view_lists_recipients(core_, view_.get());
    if (wanted == recipientsColumn_) {
        return;
    }
    recipientsColumn_ = wanted;
    SetColumnTitle(list_, COL_FROM, core::T(wanted ? PE_TEXT_UI_COL_TO : PE_TEXT_UI_COL_FROM));
    SetColumnTitle(list_, COL_RECEIVED, core::T(wanted ? PE_TEXT_UI_COL_SENT : PE_TEXT_UI_COL_RECEIVED));
}

// the folder of a row in a list of several folders: its name, with its account's when there are several accounts; in
// All Inboxes the account alone, as the tree names it
std::wstring Mailbox::RowFolder(int64_t folder) const {
    auto account = folderAccounts_.find(folder);
    if (allInboxes_ && !Searching()) {
        auto title = account != folderAccounts_.end() ? accountItems_.find(account->second) : accountItems_.end();
        auto row = title != accountItems_.end() ? rows_.find(title->second) : rows_.end();
        return row != rows_.end() ? row->second.name : L"";
    }
    auto name = folderNames_.find(folder);
    std::wstring text = name != folderNames_.end() ? name->second.first : L"";
    if (accountNames_.size() > 1 && account != folderAccounts_.end()) {
        text += L" (" + AccountName(account->second) + L")";
    }
    return text;
}

void Mailbox::ReloadList(bool keepSelection) {
    // a selection the user just made and TIMER_SELECTION has not taken yet: taken from the rows as they were shown,
    // before the list changes under it
    bool pending = keepSelection && std::exchange(selectionPending_, false);
    if (pending) {
        KillTimer(parent_, TIMER_SELECTION);
        pe_selection_clear(selection_.get());
        for (int i : SelectedRows()) {
            if (const PeMessage* row = Row(i)) {
                pe_selection_add(selection_.get(), row->folder, row->uid);
            }
        }
    }
    pages_.clear();
    total_ = 0;
    unread_ = 0;
    rowCount_ = 0;
    ShowFolderColumn();
    ShowPersonColumn();
    // the core counts them: a folder from its indexes, a search, All Inboxes and a folder without its ignored
    // conversations what they find. An account's own item lists nothing. The status bar counts messages; grouped by
    // conversation the list has fewer rows
    if (pe_list_view_active(view_.get())) {
        pe_list_view_counts(core_, view_.get(), &total_, &unread_);
        rowCount_ = pe_list_view_row_count(core_, view_.get());
    }
    // the selection follows the message to where it is now, without a flicker of the reading pane; several selected
    // messages are found again where they are now
    uint64_t shown = reader_.Uid();
    int64_t index = keepSelection && shown && !pending ? pe_list_view_index(core_, view_.get(), reader_.Folder(), shown) : -1;
    core::Positions several(keepSelection && (pending || !shown) && pe_selection_count(selection_.get()) > 0
                                ? pe_list_view_positions(core_, view_.get(), selection_.get())
                                : nullptr);
    reloading_ = true;
    ListView_SetItemCountEx(list_, static_cast<int>(std::min<uint64_t>(rowCount_, INT_MAX)), LVSICF_NOSCROLL);
    // the scroll bar comes and goes with the rows: Subject fits the width that leaves
    FitSubjectColumn();
    // an empty list says why, and that may have changed with the same count
    InvalidateRect(list_, nullptr, TRUE);
    ListView_SetItemState(list_, -1, 0, LVIS_SELECTED | LVIS_FOCUSED);
    if (index >= 0) {
        ListView_SetItemState(list_, static_cast<int>(index), LVIS_SELECTED | LVIS_FOCUSED, LVIS_SELECTED | LVIS_FOCUSED);
        ListView_EnsureVisible(list_, static_cast<int>(index), FALSE);
    }
    // the messages selected before are still the selection where they are now: only their numbers change
    bool kept = SelectPositions(several.get(), false);
    if (undoPending_ && SelectRestored()) {
        undoPending_ = false;
        kept = false;
    }
    reloading_ = false;
    InvalidateRect(list_, nullptr, FALSE);
    KillTimer(parent_, TIMER_SELECTION);
    selectionPending_ = false;
    OnSelectionChanged(!kept);
}

bool Mailbox::SelectPositions(const PePositions* positions, bool focusFirst) {
    size_t count = pe_positions_count(positions);
    for (size_t i = 0; i < count; i++) {
        uint64_t at = pe_positions_get(positions, i);
        UINT state = LVIS_SELECTED | (focusFirst && i == 0 ? LVIS_FOCUSED : 0);
        if (at < static_cast<uint64_t>(INT_MAX)) {
            ListView_SetItemState(list_, static_cast<int>(at), state, state);
        }
    }
    if (focusFirst && count > 0) {
        ListView_EnsureVisible(list_, static_cast<int>(std::min<uint64_t>(pe_positions_get(positions, 0), INT_MAX)), FALSE);
    }
    return count > 0;
}

const PeMessage* Mailbox::Row(int index) {
    if (index < 0 || static_cast<uint64_t>(index) >= rowCount_) {
        return nullptr;
    }
    uint64_t offset = static_cast<uint64_t>(index) / kPageSize * kPageSize;
    auto page = std::find_if(pages_.begin(), pages_.end(), [offset](const Page& p) { return p.offset == offset; });
    if (page == pages_.end()) {
        if (pages_.size() >= kPagesKept) {
            pages_.erase(pages_.begin());
        }
        pages_.push_back({offset, core::MessageList(pe_list_view_messages(core_, view_.get(), offset, kPageSize))});
    } else if (page != pages_.end() - 1) {
        // the most recently used page goes last, the least recently used is dropped first
        std::rotate(page, page + 1, pages_.end());
    }
    return pe_message_list_get(pages_.back().rows.get(), static_cast<size_t>(static_cast<uint64_t>(index) - offset));
}

const PeMessage* Mailbox::SelectedRow() {
    return Row(ListView_GetNextItem(list_, -1, LVNI_SELECTED));
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
        if (ListView_GetItemCount(list_) == 0) {
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

void DrawFlagMark(HDC dc, int left, int top, int size, bool selected, int color) {
    if (selected) {
        HGDIOBJ oldBrush = SelectObject(dc, GetSysColorBrush(COLOR_WINDOW));
        HGDIOBJ oldPen = SelectObject(dc, GetStockObject(NULL_PEN));
        RoundRect(dc, left, top, left + size + 1, top + size + 1, 4, 4);
        SelectObject(dc, oldPen);
        SelectObject(dc, oldBrush);
    }
    DrawFlag(dc, left, top, size, FlagRgb(color ? color : 1));
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

// the paper clip (or a bounce's mark) and the flag of a row, drawn over the row as the list painted it:
// the list itself would dither the images of a selected row, and does not highlight those of other columns
void Mailbox::DrawRowIcons(HDC dc, int index, const PeMessage& row) {
    bool selected = (ListView_GetItemState(list_, index, LVIS_SELECTED) & LVIS_SELECTED) != 0;
    FillRowStart(dc, index, selected);
    auto draw = [&](int column, int icon) {
        RECT cell;
        ListView_GetSubItemRect(list_, index, column, LVIR_BOUNDS, &cell);
        // the first column's bounds are the whole row's: its width is the column's
        int width = ListView_GetColumnWidth(list_, column);
        ImageList_Draw(listIcons_, icon, dc, cell.left + (width - iconSize_) / 2, cell.top + (cell.bottom - cell.top - iconSize_) / 2,
                       ILD_TRANSPARENT);
    };
    // a bounce's mark in the paper clip's place, also when it has files
    if (row.bounce) {
        draw(COL_ATTACH, LIST_MAIL_ERROR);
    } else if (row.has_attachments) {
        draw(COL_ATTACH, LIST_ATTACH);
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
    if (uid == reader_.Uid() && folder == reader_.Folder()) {
        return;
    }
    ClearReader(uid != 0);
    if (!uid) {
        return;
    }
    reader_.Open(folder, uid, AccountOf(folder), row);
}

void Mailbox::ScheduleSelection() {
    // the user chose: what Undo brings back is not selected over it
    undoPending_ = false;
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
    return static_cast<size_t>(ListView_GetSelectedCount(list_));
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
    if (count == 1 && !Grouped()) {
        pe_selection_clear(selection_.get());
        if (const PeMessage* row = SelectedRow()) {
            pe_selection_add(selection_.get(), row->folder, row->uid);
        }
    } else if (count == 0) {
        pe_selection_clear(selection_.get());
    } else if (rebuild || count == 1) {
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
    core::String page(pe_selection_page(&summary_));
    std::wstring html = page ? core::Widen(page.get()) : L"";
    if (html != summaryPage_) {
        summaryPage_ = html;
        reader_.ShowPage(html);
    }
}

bool Mailbox::SelectRestored() {
    core::Selection restored(pe_selection_new());
    if (!pe_undo_restored(core_, restored.get()) || pe_selection_count(restored.get()) == 0) {
        return false;
    }
    core::Positions at(pe_list_view_positions(core_, view_.get(), restored.get()));
    if (pe_positions_count(at.get()) == 0) {
        return false;
    }
    ListView_SetItemState(list_, -1, 0, LVIS_SELECTED | LVIS_FOCUSED);
    // the first of them in view
    return SelectPositions(at.get(), true);
}

bool Mailbox::OnFolderSelected(int64_t folder, bool allInboxes) {
    if (folder == folder_ && allInboxes == allInboxes_) {
        return false;
    }
    // the message of the folder before is not this folder's, nor is the search; what Show shows stays
    folder_ = folder;
    allInboxes_ = allInboxes;
    undoPending_ = false;
    // the view closes the conversations opened, which were the folder's
    pe_list_view_set_scope(view_.get(), folder, allInboxes);
    ResetFind();
    ClearReader();
    ReloadList(false);
    SendMessageW(parent_, WM_COMMAND, MAKEWPARAM(IDC_TREE, 0), 0);
    return true;
}

void Mailbox::LoadPictures() {
    reader_.LoadPictures();
}

void Mailbox::MarkAllRead() {
    if (Searching()) {
        return;
    }
    if (allInboxes_) {
        pe_mark_all_inboxes_read(core_);
    } else if (folder_) {
        pe_folder_mark_all_read(core_, folder_);
    }
}

HTREEITEM Mailbox::RowOf(int64_t folder) const {
    if (allInboxes_ || underAllInboxes_) {
        if (auto inbox = inboxItems_.find(folder); inbox != inboxItems_.end()) {
            return inbox->second;
        }
    }
    auto item = items_.find(folder);
    return item != items_.end() ? item->second : nullptr;
}

void Mailbox::ShowMessage(int64_t folder, uint64_t uid) {
    HTREEITEM row = RowOf(folder);
    if (!row) {
        return;
    }
    // All Inboxes stays when it has the message (of an Inbox), its list up to date with it
    if (allInboxes_ && !Searching()) {
        KillTimer(parent_, TIMER_RELOAD);
        ReloadList(true);
        if (SelectInList(folder, uid)) {
            return;
        }
    }
    // the folder (which ends a search), then the message in it; the folder selected already does not change, its
    // search is ended here
    if (Searching() && !allInboxes_ && folder_ == folder) {
        ClearFind();
    }
    TreeView_SelectItem(tree_, row);
    if (folder_ == folder) {
        SelectInList(folder, uid);
    }
}

bool Mailbox::SelectInList(int64_t folder, uint64_t uid) {
    // a message hidden in a collapsed conversation (Next Unread finds those): the conversation opened first
    FlushSelection();
    if (pe_list_view_reveal(core_, view_.get(), folder, uid)) {
        ReloadList(true);
    }
    int64_t index = pe_list_view_index(core_, view_.get(), folder, uid);
    if (index < 0 || index > INT_MAX) {
        return false;
    }
    SetFocus(list_);
    // chosen by the app, not clicked through: followed at once
    SelectOnly(static_cast<int>(index));
    return true;
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
    bool allInboxes = false;
    int64_t folder = 0;
    uint64_t uid = 0;
    if (folder_ || allInboxes_ || !pe_start_message(core_, &allInboxes, &folder, &uid)) {
        return;
    }
    if (!allInboxes) {
        ShowMessage(folder, uid);
    } else if (allInboxesItem_) {
        TreeView_SelectItem(tree_, allInboxesItem_);
        SelectInList(folder, uid);
    }
}

std::wstring Mailbox::Unsubscribe(std::wstring& mailto) {
    return reader_.Unsubscribe(parent_, mailto);
}

std::wstring Mailbox::Unsubscribed(uint64_t request, const std::wstring& problem) {
    return reader_.Unsubscribed(request, problem);
}

void Mailbox::MarkJunk(bool junk) {
    Act(junk ? PE_ACTION_JUNK : PE_ACTION_NOT_JUNK);
}

void Mailbox::ArchiveSelected() {
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
    // what takes the place of rows that leave the list: the row after the last of them. The core says which actions
    // take them out, from the selection as it is now (Ignore while ignored conversations are hidden)
    RefreshSummary();
    bool leaves = pe_list_view_leaves_list(view_.get(), &summary_, action, to);
    int after = leaves ? RowAfterSelection() : -1;
    char* reason = nullptr;
    core::String done(pe_selection_act(core_, selection_.get(), action, to, &reason));
    Say(done ? Text(done.get()) : ReasonText(reason, PE_TEXT_UI_MESSAGES_NOT_CHANGED));
    if (done && leaves) {
        SelectAfterRemoval(after);
    }
    return done != nullptr;
}

void Mailbox::RefreshSummary() {
    summary_ = {};
    if (pe_selection_count(selection_.get()) > 0) {
        pe_selection_summary(core_, selection_.get(), &summary_);
    }
}

void Mailbox::Say(const std::wstring& text) {
    said_ = text;
    SendMessageW(parent_, WM_COMMAND, MAKEWPARAM(IDC_LIST, kSaid), 0);
}

int Mailbox::RowAfterSelection() const {
    // every selected row before the one after the last of them goes: it moves up by as many, less the last itself
    std::vector<int> rows = SelectedRows();
    return rows.empty() ? -1 : rows.back() - static_cast<int>(rows.size()) + 1;
}

void Mailbox::SelectAll() {
    if (ListView_GetItemCount(list_) > 0) {
        ListView_SetItemState(list_, -1, LVIS_SELECTED, LVIS_SELECTED);
        SetFocus(list_);
    }
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

// after a message left the list: the one that took its place selected, or the last one
void Mailbox::SelectAfterRemoval(int index) {
    ReloadList(false);
    if (index >= 0 && rowCount_ > 0) {
        int next = std::min(index, static_cast<int>(std::min<uint64_t>(rowCount_, INT_MAX)) - 1);
        ListView_SetItemState(list_, next, LVIS_SELECTED | LVIS_FOCUSED, LVIS_SELECTED | LVIS_FOCUSED);
        ListView_EnsureVisible(list_, next, FALSE);
        FlushSelection();
    }
}

void Mailbox::DeleteSelected() {
    FlushSelection();
    if (pe_selection_count(selection_.get()) == 0) {
        return;
    }
    // from Deleted Items, or an account without one, they are gone for good: asked first, as Outlook Express does
    core::String question(pe_selection_delete_question(&summary_));
    if (question && MessageBoxW(parent_, Text(question.get()).c_str(), L"Inbox Classic", MB_YESNO | MB_ICONWARNING | MB_DEFBUTTON2) != IDYES) {
        return;
    }
    Act(PE_ACTION_DELETE);
}

void Mailbox::MoveSelected(HWND owner, bool copy) {
    FlushSelection();
    int64_t first = 0;
    uint64_t uid = 0;
    if (!pe_selection_get(selection_.get(), 0, &first, &uid)) {
        return;
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
    FlushSelection();
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
    if (selectedAccount_ && !folder_ && !allInboxes_) {
        AccountMenu(screen);
        return;
    }
    HMENU menu = CreatePopupMenu();
    // Mark All Read first, as Outlook Express has it, for a folder with unread messages
    uint64_t total = 0, unread = 0;
    bool someUnread = allInboxes_ ? pe_inbox_unread(core_) > 0
                                  : folder_ && pe_folder_counts(core_, folder_, &total, &unread) && unread > 0;
    AppendMenuW(menu, someUnread ? MF_STRING : MF_STRING | MF_GRAYED, IDM_MARK_ALL_READ, MenuItem(PE_TEXT_CMD_MARK_ALL_READ).c_str());
    // All Inboxes is no folder of one account: the folder commands never apply to it, so it has none
    if (!allInboxes_) {
        AppendMenuW(menu, MF_SEPARATOR, 0, nullptr);
        AppendMenuW(menu, MF_STRING, IDM_NEW_FOLDER, MenuItem(PE_TEXT_CMD_NEW_FOLDER).c_str());
        std::wstring name;
        bool fixed = true;
        UINT special = folder_ && FolderOf(folder_, name, fixed) && !fixed ? MF_STRING : MF_STRING | MF_GRAYED;
        AppendMenuW(menu, special, IDM_RENAME_FOLDER, MenuItem(PE_TEXT_WIN_RENAME).c_str());
        AppendMenuW(menu, special, IDM_DELETE_FOLDER, MenuItem(PE_TEXT_WIN_DELETE_BUTTON).c_str());
        // Deleted Items and Junk E-mail can be emptied, as in Outlook Express
        if (emptiableFolders_.contains(folder_)) {
            AppendMenuW(menu, MF_SEPARATOR, 0, nullptr);
            AppendMenuW(menu, CanEmptyFolder() ? MF_STRING : MF_STRING | MF_GRAYED, IDM_EMPTY_FOLDER, MenuItem(PE_TEXT_CMD_EMPTY_FOLDER).c_str());
        }
    }
    // an Inbox under All Inboxes stands for its account there: its place in the accounts' order
    if (underAllInboxes_) {
        AppendMenuW(menu, MF_SEPARATOR, 0, nullptr);
        AppendMoveItems(menu);
    }
    TrackPopupMenu(menu, TPM_RIGHTBUTTON, screen.x, screen.y, 0, parent_, nullptr);
    DestroyMenu(menu);
}

void Mailbox::AccountMenu(POINT screen) {
    // Mark All Read while some folder of the account has unread mail, as its row counts it
    auto root = accountItems_.find(selectedAccount_);
    bool someUnread = root != accountItems_.end() && rows_.contains(root->second) && rows_.at(root->second).below > 0;
    HMENU menu = CreatePopupMenu();
    AppendMenuW(menu, MF_STRING, IDM_ACCOUNT_SYNC, core::T(PE_TEXT_UI_ACCOUNT_SYNC).c_str());
    AppendMenuW(menu, someUnread ? MF_STRING : MF_STRING | MF_GRAYED, IDM_ACCOUNT_MARK_ALL_READ, MenuItem(PE_TEXT_CMD_MARK_ALL_READ).c_str());
    AppendMenuW(menu, MF_SEPARATOR, 0, nullptr);
    AppendMenuW(menu, MF_STRING, IDM_NEW_FOLDER, MenuItem(PE_TEXT_CMD_NEW_FOLDER).c_str());
    AppendMenuW(menu, MF_SEPARATOR, 0, nullptr);
    AppendMoveItems(menu);
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

// the data of a tree row
LPARAM RowData(HWND tree, HTREEITEM item) {
    TVITEMW data = {};
    data.mask = TVIF_PARAM;
    data.hItem = item;
    return TreeView_GetItem(tree, &data) ? data.lParam : 0;
}

}  // namespace

int64_t Mailbox::AccountOfRow(LPARAM data) const {
    TreePlace place = PlaceOf(data);
    if (place.account) {
        return place.account;
    }
    return place.underAllInboxes ? AccountOf(place.folder) : 0;
}

std::vector<HTREEITEM> Mailbox::SiblingRows(HTREEITEM item) const {
    std::vector<HTREEITEM> rows;
    HTREEITEM parent = TreeView_GetParent(tree_, item);
    for (HTREEITEM row = parent ? TreeView_GetChild(tree_, parent) : TreeView_GetRoot(tree_); row; row = TreeView_GetNextSibling(tree_, row)) {
        if (row != allInboxesItem_) {
            rows.push_back(row);
        }
    }
    return rows;
}

std::vector<int64_t> Mailbox::AccountOrder() const {
    std::vector<int64_t> order;
    for (HTREEITEM row = TreeView_GetRoot(tree_); row; row = TreeView_GetNextSibling(tree_, row)) {
        if (int64_t account = PlaceOf(RowData(tree_, row)).account) {
            order.push_back(account);
        }
    }
    return order;
}

void Mailbox::AppendMoveItems(HMENU menu) const {
    std::vector<int64_t> order = AccountOrder();
    int64_t account = selectedAccount_ ? selectedAccount_ : AccountOf(folder_);
    auto at = std::find(order.begin(), order.end(), account);
    bool up = at != order.end() && at != order.begin();
    bool down = at != order.end() && at + 1 != order.end();
    AppendMenuW(menu, up ? MF_STRING : MF_STRING | MF_GRAYED, IDM_ACCOUNT_MOVE_UP, core::T(PE_TEXT_UI_ACCOUNT_MOVE_UP).c_str());
    AppendMenuW(menu, down ? MF_STRING : MF_STRING | MF_GRAYED, IDM_ACCOUNT_MOVE_DOWN, core::T(PE_TEXT_UI_ACCOUNT_MOVE_DOWN).c_str());
}

void Mailbox::MoveAccount(int step) {
    HTREEITEM selected = TreeView_GetSelection(tree_);
    LPARAM row = selected ? RowData(tree_, selected) : 0;
    int64_t account = selected ? AccountOfRow(row) : 0;
    std::vector<int64_t> order = AccountOrder();
    auto at = std::find(order.begin(), order.end(), account);
    if (at == order.end()) {
        return;
    }
    ptrdiff_t index = (at - order.begin()) + step;
    if (index < 0 || index >= static_cast<ptrdiff_t>(order.size())) {
        return;
    }
    PlaceAccount(account, static_cast<size_t>(index), row);
}

void Mailbox::PlaceAccount(int64_t account, size_t index, LPARAM row) {
    if (!pe_account_move(core_, account, static_cast<uint32_t>(index))) {
        return;
    }
    Reload();
    // the row moved selected (it may have been another), and in view
    TreePlace place = PlaceOf(row);
    auto& rows = place.account ? accountItems_ : inboxItems_;
    auto found = rows.find(place.account ? place.account : place.folder);
    if (found != rows.end()) {
        TreeView_SelectItem(tree_, found->second);
        TreeView_EnsureVisible(tree_, found->second);
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
    LPARAM data = RowData(tree_, item);
    int64_t account = AccountOfRow(data);
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
    int64_t neighbour = AccountOfRow(RowData(tree_, rows[after ? rows.size() - 1 : gap]));
    auto at = std::find(order.begin(), order.end(), neighbour);
    if (at == order.end()) {
        return;
    }
    PlaceAccount(account, static_cast<size_t>(at - order.begin()) + (after ? 1 : 0), data);
}

std::wstring Mailbox::SelectedName() const {
    if (Searching()) {
        // where the search looks; what it found is on the search bar
        return findPlace_.empty() ? core::T(PE_TEXT_UI_ALL_FOLDERS) : findPlace_;
    }
    if (allInboxes_) {
        return AllInboxes();
    }
    if (auto found = folderNames_.find(folder_); found != folderNames_.end()) {
        // a row under All Inboxes names its account too: "Inbox - Gmail"
        if (auto title = inboxTitles_.find(folder_); underAllInboxes_ && title != inboxTitles_.end()) {
            return title->second;
        }
        return found->second.first;
    }
    // an account by its row's name, its Account name when it has one
    if (auto root = accountItems_.find(selectedAccount_); root != accountItems_.end() && rows_.contains(root->second)) {
        return rows_.at(root->second).name;
    }
    return L"";
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
    } else if ((folder_ || allInboxes_) && unreadOnly_) {
        title = core::T(PE_TEXT_UI_NO_UNREAD);
    } else if (folder_ || allInboxes_) {
        title = core::T(PE_TEXT_UI_NO_ITEMS);
    } else if (selectedAccount_) {
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
    int64_t account = CurrentAccount();
    if (!account || allInboxes_) {
        return;
    }
    std::wstring where = core::T(folder_ ? PE_TEXT_UI_NEW_FOLDER_IN_SELECTED : PE_TEXT_UI_NEW_FOLDER_AT_TOP);
    std::wstring name = AskFolderName(owner, PE_TEXT_CMD_NEW_FOLDER, where, L"");
    if (name.empty()) {
        return;
    }
    char* reason = nullptr;
    if (!pe_folder_create(core_, account, folder_, core::Narrow(name).c_str(), &reason)) {
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
    TreeView_SelectItem(tree_, row);
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
    auto item = items_.find(PickFolder(owner, pick));
    if (item != items_.end()) {
        TreeView_SelectItem(tree_, item->second);
        SetFocus(list_);
    }
}

void Mailbox::FindInMessage(HWND owner, bool again) {
    FlushSelection();
    reader_.FindInMessage(owner, again);
}

bool Mailbox::CanEmptyFolder() const {
    return !allInboxes_ && !Searching() && emptiableFolders_.contains(folder_) && total_ > 0;
}

void Mailbox::SetThreadExpanded(int64_t thread, bool open) {
    // the selection taken from the rows as they are shown, before they change
    FlushSelection();
    if (open ? pe_list_view_expand(view_.get(), thread) : pe_list_view_collapse(view_.get(), thread)) {
        ReloadList(true);
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
    // the selection as the core knows it now: an action since it was taken may have changed the marks
    FlushSelection();
    RefreshSummary();
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
        const PeMessage* row = Row(index);
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
    const PeMessage* row = Row(hit.iItem);
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
    const PeMessage* row = Row(ListView_GetNextItem(list_, -1, LVNI_FOCUSED));
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
            TreePlace place = change->itemNew.hItem ? PlaceOf(change->itemNew.lParam) : TreePlace{};
            // an account has no messages of its own
            selectedAccount_ = place.account;
            underAllInboxes_ = place.underAllInboxes;
            // the folder bar and the title name what is selected: an account too, from another account's item, and
            // the same Inbox from its other row
            if (!OnFolderSelected(place.folder, place.allInboxes)) {
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
        PeSortField sort = SortOf(reinterpret_cast<NMLISTVIEW*>(header)->iSubItem);
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
    const PeMessage* message = index >= 0 ? Row(index) : nullptr;
    if (!message) {
        return;
    }
    // the menu is for the selection as it is now
    FlushSelection();
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
    if (!folder_) {
        MessageBoxW(owner, core::T(PE_TEXT_UI_IMPORT_CHOOSE_FOLDER).c_str(), core::Title(PE_TEXT_CMD_IMPORT).c_str(), MB_OK | MB_ICONINFORMATION);
        return;
    }
    std::vector<std::wstring> files = OpenFilesDialog(owner, core::Title(PE_TEXT_CMD_IMPORT).c_str(),
        FileFilter({{core::T(PE_TEXT_UI_FILTER_MESSAGES), L"*.eml"}, {core::T(PE_TEXT_UI_FILTER_ALL), L"*.*"}}).c_str());
    if (!files.empty()) {
        ImportFiles(folder_, files, owner);
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
        RECT link;
        GetWindowRect(searchClear_, &link);
        area.right -= (link.right - link.left) + pad;
        HGDIOBJ old = SelectObject(item.hDC, reinterpret_cast<HFONT>(SendMessageW(list_, WM_GETFONT, 0, 0)));
        SetTextColor(item.hDC, GetSysColor(COLOR_INFOTEXT));
        SetBkMode(item.hDC, TRANSPARENT);
        DrawTextW(item.hDC, searchSummary_.c_str(), -1, &area, DT_LEFT | DT_VCENTER | DT_SINGLELINE | DT_NOPREFIX | DT_END_ELLIPSIS);
        SelectObject(item.hDC, old);
        return true;
    }
    if (item.hwndItem != findIcon_ && item.hwndItem != findClear_) {
        return false;
    }
    FillRect(item.hDC, &item.rcItem, GetSysColorBrush(COLOR_WINDOW));
    int icon = item.hwndItem == findIcon_ ? LIST_SEARCH : LIST_DISMISS;
    int pushed = (item.itemState & ODS_SELECTED) ? 1 : 0;
    int x = (item.rcItem.left + item.rcItem.right - iconSize_) / 2 + pushed;
    int y = (item.rcItem.top + item.rcItem.bottom - iconSize_) / 2 + pushed;
    ImageList_Draw(listIcons_, icon, item.hDC, x, y, ILD_TRANSPARENT);
    return true;
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
    return reader_.OnCommand(id, code);
}

// ---- dragging messages: onto a folder, out of the app as files, files into a folder ----

void Mailbox::BeginDrag(int index) {
    FlushSelection();
    const PeMessage* row = Row(index);
    if (!row || pe_selection_count(selection_.get()) == 0) {
        return;
    }
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
    // an account's own item (its id negated), All Inboxes, the folder they are all in, or one that holds no messages:
    // not there. A folder of another account takes them too, the core moves them across; a row under All Inboxes is
    // that account's Inbox
    int64_t folder = PlaceOf(RowData(tree_, over)).folder;
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
    // files go into the folder shown; not into All Inboxes or a search, which are no one folder
    Mailbox& box = *mailbox;
    bool oneFolder = box.folder_ && !box.allInboxes_ && box.find_.empty();
    return from == DropFrom::Files && oneFolder && !box.unselectable_.count(box.folder_) ? (allowed & DROPEFFECT_COPY) : DROPEFFECT_NONE;
}

DWORD Mailbox::ListSite::Dropped(IDataObject* data, DropFrom from, POINT screen, DWORD keys, DWORD allowed) {
    if (!Over(from, screen, keys, allowed)) {
        return DROPEFFECT_NONE;
    }
    PostMessageW(mailbox->parent_, WM_IMPORT_DROPPED, static_cast<WPARAM>(mailbox->folder_),
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
    if (id == TIMER_RELOAD) {
        KillTimer(parent_, TIMER_RELOAD);
        ReloadList(true);
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
        UpdateFolders(event.account);
        if (event.folder == folder_ && !Searching()) {
            ReloadList(true);
        } else if (SeveralFolders()) {
            // a list of several folders has messages of any of them
            SetTimer(parent_, TIMER_RELOAD, 300, nullptr);
        }
        break;
    case PE_EVENT_KIND_PICTURE_READY:
        PictureReady(event.uid);
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
