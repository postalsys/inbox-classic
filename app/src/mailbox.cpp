// The folder tree, the message list and the reading pane. The list is virtual: rows come from the core a page at a
// time when the list view asks for them. Every string shown was decoded by the core; the message body is the
// sanitized document the core made, shown in the WebView2 as it is.
#include "app.h"
#include "icons.h"
#include "webview.h"

#include <commdlg.h>
#include <shellapi.h>

#include <algorithm>
#include <array>
#include <span>
#include <utility>

namespace {

constexpr uint64_t kPageSize = 100;
// pages kept around while the list scrolls
constexpr size_t kPagesKept = 8;
constexpr int kHeaderLines = 4;

// as Outlook Express has them: the envelope (read or not), the paper clip and the flag, then the text columns
enum Column { COL_READ, COL_ATTACH, COL_FLAG, COL_FROM, COL_SUBJECT, COL_RECEIVED, COL_SIZE, COL_FOLDER };

// what the Find box takes, shown when the mouse rests on it
const wchar_t* kFindTip =
    L"Finds words in the subject, the people, the file names and the text of messages.\r\n"
    L"\"exact phrase\"    -leave out    this OR that\r\n"
    L"from:ann    to:bob    subject:report    filename:pdf\r\n"
    L"is:unread    is:read    is:starred    has:attachment\r\n"
    L"in:inbox    in:sent    in:anywhere    in:<folder name>\r\n"
    L"before:2025/01/31    after:2025/01/01    older_than:2d    newer_than:1m\r\n"
    L"larger:5M    smaller:100k";

// what the empty search field says, grey, until it has the focus
const wchar_t* kFindHint = L"Search mail";

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
        DrawTextW(dc, kFindHint, -1, &area, DT_LEFT | DT_VCENTER | DT_SINGLELINE | DT_NOPREFIX);
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
    return CreateChild(parent, L"InboxClassicSearchField", L"", WS_CLIPCHILDREN, IDC_FIND_FIELD, {}, WS_EX_CLIENTEDGE);
}

// the name Outlook Express gives a special folder, the folder's own name otherwise
std::wstring FolderName(const PeFolder& folder) {
    switch (folder.special_use) {
    case PE_SPECIAL_USE_INBOX:
        return L"Inbox";
    case PE_SPECIAL_USE_SENT:
        return L"Sent Items";
    case PE_SPECIAL_USE_TRASH:
        return L"Deleted Items";
    case PE_SPECIAL_USE_DRAFTS:
        return L"Drafts";
    case PE_SPECIAL_USE_JUNK:
        return L"Junk E-mail";
    default:
        return Text(folder.name);
    }
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
    case COL_SIZE:
        return PE_SORT_FIELD_SIZE;
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

// a column that shows an icon of the list strip in its header (the paper clip, the flag) and nothing else
void IconColumn(HWND list, int index, int icon) {
    AddColumn(list, index, L"", 28);
    LVCOLUMNW column = {};
    column.mask = LVCF_FMT | LVCF_IMAGE;
    column.fmt = LVCFMT_IMAGE;
    column.iImage = icon;
    ListView_SetColumn(list, index, &column);
}

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

}  // namespace

void Mailbox::Create(HWND parent, PeCore* core) {
    parent_ = parent;
    core_ = core;
    tree_ = CreateChild(parent, WC_TREEVIEWW, nullptr,
                        WS_TABSTOP | TVS_HASLINES | TVS_HASBUTTONS | TVS_LINESATROOT | TVS_SHOWSELALWAYS, IDC_TREE, {},
                        WS_EX_CLIENTEDGE);
    list_ = CreateChild(parent, WC_LISTVIEWW, nullptr,
                        WS_TABSTOP | LVS_REPORT | LVS_SHOWSELALWAYS | LVS_SINGLESEL | LVS_OWNERDATA, IDC_LIST, {},
                        WS_EX_CLIENTEDGE);
    ListView_SetExtendedListViewStyle(list_, LVS_EX_FULLROWSELECT);
    // the icons of the list: for the headers of the paper clip and flag columns, and drawn on the rows in CustomDraw
    listIcons_ = IconList(IconSet::List);
    ImageList_GetIconSize(listIcons_, &iconSize_, &iconSize_);
    ListView_SetImageList(list_, listIcons_, LVSIL_SMALL);
    TreeView_SetImageList(tree_, IconList(IconSet::Folders), TVSIL_NORMAL);
    // the search field: a white sunken window with the magnifier, the box without a border of its own, and the clear
    // button once there is something to clear
    findField_ = CreateFindField(parent);
    findIcon_ = CreateChild(findField_, L"STATIC", L"", SS_OWNERDRAW, IDC_FIND_ICON, {});
    findEdit_ = CreateChild(findField_, L"EDIT", L"", WS_TABSTOP | ES_AUTOHSCROLL, IDC_FIND, {});
    SetWindowSubclass(findEdit_, FindEditProc, 0, 0);
    // what a screen reader says for it
    SetAccessibleDescription(findEdit_, L"Search mail");
    findClear_ = CreateChild(findField_, L"BUTTON", L"Clear search", BS_OWNERDRAW, IDC_FIND_CLEAR, {});
    ShowWindow(findClear_, SW_HIDE);
    // what the box takes, when the mouse rests on it
    HWND tip = CreateWindowExW(WS_EX_TOPMOST, TOOLTIPS_CLASSW, nullptr, WS_POPUP | TTS_ALWAYSTIP | TTS_NOPREFIX, CW_USEDEFAULT,
                               CW_USEDEFAULT, CW_USEDEFAULT, CW_USEDEFAULT, parent, nullptr, GetModuleHandleW(nullptr), nullptr);
    SendMessageW(tip, TTM_SETMAXTIPWIDTH, 0, Scale(520));
    SendMessageW(tip, TTM_SETDELAYTIME, TTDT_AUTOPOP, 30000);
    TOOLINFOW tool = {sizeof(tool)};
    tool.uFlags = TTF_IDISHWND | TTF_SUBCLASS;
    tool.hwnd = parent;
    tool.lpszText = const_cast<wchar_t*>(kFindTip);
    for (HWND window : {findField_, findEdit_}) {
        tool.uId = reinterpret_cast<UINT_PTR>(window);
        SendMessageW(tip, TTM_ADDTOOLW, 0, reinterpret_cast<LPARAM>(&tool));
    }
    AddColumn(list_, COL_READ, L"", 24);
    IconColumn(list_, COL_ATTACH, LIST_ATTACH);
    IconColumn(list_, COL_FLAG, LIST_FLAG);
    AddColumn(list_, COL_FROM, L"From", 180);
    AddColumn(list_, COL_SUBJECT, L"Subject", 320);
    AddColumn(list_, COL_RECEIVED, L"Received", 130);
    AddColumn(list_, COL_SIZE, L"Size", 84, LVCFMT_RIGHT);

    // not drawn over the Unsubscribe link that lies on it
    header_ = CreateChild(parent, L"STATIC", L"", SS_LEFT | SS_NOPREFIX | SS_SUNKEN | WS_CLIPSIBLINGS, 0, {});
    unsubscribe_ = CreateChild(parent, L"STATIC", L"Unsubscribe", SS_NOTIFY | SS_RIGHT | SS_NOPREFIX, IDC_UNSUBSCRIBE, {});
    ShowWindow(unsubscribe_, SW_HIDE);
    invitation_ = CreateChild(parent, L"STATIC", L"", SS_OWNERDRAW | WS_BORDER | WS_CLIPSIBLINGS, IDC_INVITATION, {});
    logo_ = CreateChild(parent, L"STATIC", L"", SS_OWNERDRAW, IDC_LOGO, {});
    ShowWindow(logo_, SW_HIDE);
    openCalendar_ = CreateChild(parent, L"BUTTON", L"Open in Calendar", WS_TABSTOP | BS_PUSHBUTTON, IDC_OPEN_CALENDAR, {});
    ShowWindow(invitation_, SW_HIDE);
    ShowWindow(openCalendar_, SW_HIDE);
    // the paper clip at the right of the header, as Outlook Express has it: the files of the message in its menu
    attachments_ = CreateBar(parent, CCS_NODIVIDER | CCS_NOPARENTALIGN | CCS_NORESIZE, IDC_ATTACHMENTS, BarIcons::Big);
    // a label from the start, so the bar keeps a row for it under the icon ("2 files" once a message is shown)
    AddButton(attachments_, IDC_ATTACHMENTS, L"1 file", BTNS_WHOLEDROPDOWN, ICON_ATTACH);
    // the information bar of Outlook Express over a message whose pictures on the internet are blocked; a click
    // shows them
    pictures_ = CreateChild(parent, L"STATIC",
                            L" Some pictures have been blocked to help prevent the sender from identifying your computer. "
                            L"Click here to download pictures.",
                            SS_LEFT | SS_NOTIFY | SS_CENTERIMAGE | SS_NOPREFIX | SS_ENDELLIPSIS | WS_BORDER, IDC_PICTURES, {});
    ShowWindow(attachments_, SW_HIDE);
    ShowWindow(pictures_, SW_HIDE);
    // the same bar over a message that could not be downloaded: a click tries again
    core::String note(pe_retry_note());
    std::wstring retry = L" " + Text(note.get()) + L" Click here to try again.";
    retry_ = CreateChild(parent, L"STATIC", retry.c_str(), SS_LEFT | SS_NOTIFY | SS_CENTERIMAGE | SS_NOPREFIX | SS_ENDELLIPSIS | WS_BORDER,
                         IDC_RETRY, {});
    ShowWindow(retry_, SW_HIDE);
    // over the list while searching, in the colors of the information bar: what was found, and a link to end it
    searchBar_ = CreateChild(parent, L"STATIC", L"", SS_OWNERDRAW | WS_BORDER | WS_CLIPSIBLINGS, IDC_SEARCH_BAR, {});
    searchClear_ = CreateChild(parent, L"STATIC", L"Clear search", SS_NOTIFY | SS_CENTERIMAGE | SS_CENTER | SS_NOPREFIX,
                               IDC_SEARCH_CLEAR, {});
    ShowWindow(searchBar_, SW_HIDE);
    ShowWindow(searchClear_, SW_HIDE);
    previewHost_ = CreateChild(parent, L"STATIC", nullptr, SS_SUNKEN | WS_CLIPCHILDREN, 0, {});
    preview_.Create(previewHost_, [this](const std::wstring& error) { SetWindowTextW(previewHost_, error.c_str()); });

    LOGFONTW font = {};
    GetObjectW(GetStockObject(DEFAULT_GUI_FONT), sizeof(font), &font);
    font.lfUnderline = TRUE;
    link_ = CreateFontIndirectW(&font);
    SendMessageW(searchClear_, WM_SETFONT, reinterpret_cast<WPARAM>(link_), FALSE);
    SendMessageW(unsubscribe_, WM_SETFONT, reinterpret_cast<WPARAM>(link_), FALSE);
    font.lfUnderline = FALSE;
    font.lfWeight = FW_BOLD;
    bold_ = CreateFontIndirectW(&font);
    ClearReader();
    Reload();
}

void Mailbox::Destroy() {
    if (logoBitmap_) {
        DeleteObject(logoBitmap_);
        logoBitmap_ = nullptr;
    }
    preview_.Close();
    view_.reset();
    pages_.clear();
    DeleteObject(bold_);
    bold_ = nullptr;
    DeleteObject(link_);
    link_ = nullptr;
}

void Mailbox::Layout(const RECT& tree, const RECT& list, const RECT& reader) {
    MoveWindow(tree_, tree.left, tree.top, tree.right - tree.left, tree.bottom - tree.top, TRUE);
    listArea_ = list;
    LayoutList();
    reader_ = reader;
    LayoutReader();
}

// how wide the words of a link are, in the link font
int Mailbox::LinkWidth(HWND link) const {
    std::wstring words = GetWindowString(link);
    HDC dc = GetDC(link);
    HGDIOBJ old = SelectObject(dc, link_);
    SIZE size = {};
    GetTextExtentPoint32W(dc, words.c_str(), static_cast<int>(words.size()), &size);
    SelectObject(dc, old);
    ReleaseDC(link, dc);
    return size.cx;
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
    MoveWindow(list_, list.left, list.top, width, list.bottom - list.top, TRUE);
}

void Mailbox::UpdateSearchBar() {
    std::wstring summary;
    if (Searching()) {
        // what was found, for what, where: the words stay in view while the list changes under them
        summary = total_ == 0 ? L"No results" : std::to_wstring(total_) + (total_ == 1 ? L" result" : L" results");
        summary += L" for \u201C" + find_ + L"\u201D " + (findPlace_.empty() ? L"in all folders" : L"in " + findPlace_);
        if (uint64_t left = pe_search_unindexed_count(core_)) {
            // the words of these are found once their text is in (subjects, people and file names are found already)
            summary += L"  \u00B7  still indexing the text of " + std::to_wstring(left) + (left == 1 ? L" message" : L" messages");
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

// the paper clip and the information bar shown or not, the pane laid out again only when that changes
void Mailbox::ShowReaderBars(bool files, bool pictures) {
    bool changed = (IsWindowVisible(attachments_) != FALSE) != files || (IsWindowVisible(pictures_) != FALSE) != pictures;
    ShowWindow(attachments_, files ? SW_SHOW : SW_HIDE);
    ShowWindow(pictures_, pictures ? SW_SHOW : SW_HIDE);
    if (changed || files) {
        LayoutReader();
    }
}

void Mailbox::ShowRetry(bool shown) {
    if ((IsWindowVisible(retry_) != FALSE) != shown) {
        ShowWindow(retry_, shown ? SW_SHOW : SW_HIDE);
        LayoutReader();
    }
}

bool Mailbox::OnSetCursor(HWND window) {
    if (window != pictures_ && window != retry_ && window != searchClear_ && window != unsubscribe_) {
        return false;
    }
    // the information bar is clicked like a link
    SetCursor(LoadCursorW(nullptr, IDC_HAND));
    return true;
}

bool Mailbox::OnCtlColor(HWND window, HDC dc, LRESULT& brush) {
    if (window == unsubscribe_ || window == searchClear_) {
        // a link, on the header or on the information bar
        int background = window == unsubscribe_ ? COLOR_BTNFACE : COLOR_INFOBK;
        SetTextColor(dc, GetSysColor(COLOR_HOTLIGHT));
        SetBkColor(dc, GetSysColor(background));
        brush = reinterpret_cast<LRESULT>(GetSysColorBrush(background));
        return true;
    }
    if (window != pictures_ && window != retry_) {
        return false;
    }
    // the colors of tooltips and information bars of the Windows scheme
    SetTextColor(dc, GetSysColor(COLOR_INFOTEXT));
    SetBkColor(dc, GetSysColor(COLOR_INFOBK));
    brush = reinterpret_cast<LRESULT>(GetSysColorBrush(COLOR_INFOBK));
    return true;
}

// the reading pane: the header, with the paper clip at its right when the message has files; the information bar
// under it when pictures are blocked; the message below
void Mailbox::LayoutReader() {
    const RECT& reader = reader_;
    int headerHeight = kHeaderLines * Scale(15) + Scale(8);
    int width = reader.right - reader.left;
    bool files = IsWindowVisible(attachments_);
    RECT button = {};
    if (files) {
        SendMessageW(attachments_, TB_AUTOSIZE, 0, 0);
        SendMessageW(attachments_, TB_GETITEMRECT, 0, reinterpret_cast<LPARAM>(&button));
    }
    // the header to the paper clip, which is as wide as its button; the brand's logo, when there is one, at its left
    int clipWidth = files ? static_cast<int>(button.right - button.left) + Scale(8) : 0;
    int logoWidth = 0;
    if (IsWindowVisible(logo_)) {
        logoWidth = logoSize_ + Scale(12);
        MoveWindow(logo_, reader.left, reader.top, logoWidth - Scale(4), headerHeight, TRUE);
    }
    MoveWindow(header_, reader.left + logoWidth, reader.top, width - clipWidth - logoWidth, headerHeight, TRUE);
    // Unsubscribe at the right end of the Subject line, inside the header's edge
    if (IsWindowVisible(unsubscribe_)) {
        int linkWidth = LinkWidth(unsubscribe_) + Scale(8), edge = GetSystemMetrics(SM_CXEDGE);
        MoveWindow(unsubscribe_, reader.left + width - clipWidth - linkWidth - edge - Scale(4), reader.top + headerHeight - edge - Scale(26),
                   linkWidth, Scale(16), TRUE);
        SetWindowPos(unsubscribe_, HWND_TOP, 0, 0, 0, 0, SWP_NOMOVE | SWP_NOSIZE | SWP_NOACTIVATE);
    }
    if (files) {
        int buttonHeight = button.bottom - button.top;
        MoveWindow(attachments_, reader.right - clipWidth, reader.top + std::max(0, (headerHeight - buttonHeight) / 2), clipWidth, buttonHeight,
                   TRUE);
    }
    int top = reader.top + headerHeight + Scale(2);
    if (IsWindowVisible(retry_)) {
        int barHeight = Scale(22);
        MoveWindow(retry_, reader.left, top, width, barHeight, TRUE);
        top += barHeight + Scale(2);
    }
    if (IsWindowVisible(invitation_)) {
        int barHeight = Scale(40), buttonWidth = Scale(120), buttonHeight = Scale(25);
        MoveWindow(invitation_, reader.left, top, width, barHeight, TRUE);
        MoveWindow(openCalendar_, reader.left + width - buttonWidth - Scale(8), top + (barHeight - buttonHeight) / 2, buttonWidth, buttonHeight,
                   TRUE);
        SetWindowPos(openCalendar_, HWND_TOP, 0, 0, 0, 0, SWP_NOMOVE | SWP_NOSIZE | SWP_NOACTIVATE);
        top += barHeight + Scale(2);
    }
    if (IsWindowVisible(pictures_)) {
        int barHeight = Scale(22);
        MoveWindow(pictures_, reader.left, top, width, barHeight, TRUE);
        top += barHeight + Scale(2);
    }
    MoveWindow(previewHost_, reader.left, top, width, std::max(0L, reader.bottom - top), TRUE);
    RECT inner;
    GetClientRect(previewHost_, &inner);
    preview_.Resize(inner);
}

// ---- the folder tree ----

void Mailbox::Reload() {
    int64_t selected = folder_;
    // deleting the items changes the selection: not a folder the user picked
    reloading_ = true;
    TreeView_DeleteAllItems(tree_);
    reloading_ = false;
    items_.clear();
    rows_.clear();
    accountItems_.clear();
    accountNames_.clear();
    folderAccounts_.clear();
    folderNames_.clear();
    unselectable_.clear();
    draftFolders_.clear();
    junkFolders_.clear();
    firstAccount_ = 0;
    core::AccountList accounts(pe_accounts(core_));
    size_t count = pe_account_list_count(accounts.get());
    for (size_t i = 0; i < count; i++) {
        const PeAccount* account = pe_account_list_get(accounts.get(), i);
        accountNames_[account->id] = Text(account->name);
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
        // TVM_EXPAND sends no TVN_ITEMEXPANDED: the account's row is shown expanded here
        TreeView_Expand(tree_, root, TVE_EXPAND);
        ShowRow(root);
    }
    auto item = items_.find(selected);
    if (item != items_.end()) {
        reloading_ = true;
        TreeView_SelectItem(tree_, item->second);
        reloading_ = false;
    } else if (selected) {
        // the folder is gone
        OnFolderSelected(0);
    }
}

void Mailbox::FillAccount(HTREEITEM root, int64_t account) {
    core::FolderList folders(pe_folders(core_, account));
    size_t count = pe_folder_list_count(folders.get());
    // the last item at each depth, the parent of the next deeper one
    std::vector<HTREEITEM> parents = {root};
    for (size_t i = 0; i < count; i++) {
        const PeFolder* folder = pe_folder_list_get(folders.get(), i);
        size_t depth = std::min<size_t>(folder->depth, parents.size() - 1);
        HTREEITEM item = InsertItem(tree_, parents[depth], CountedLabel(FolderName(*folder), folder->unread), static_cast<LPARAM>(folder->id),
                                    folder->unread > 0, IconOfFolder(folder->special_use));
        items_[folder->id] = item;
        rows_[item] = {FolderName(*folder), folder->unread, folder->unread_below};
        folderAccounts_[folder->id] = account;
        folderNames_[folder->id] = {FolderName(*folder), folder->fixed};
        if (!folder->selectable) {
            unselectable_.insert(folder->id);
        }
        if (folder->special_use == PE_SPECIAL_USE_DRAFTS) {
            draftFolders_.insert(folder->id);
        }
        if (folder->special_use == PE_SPECIAL_USE_JUNK) {
            junkFolders_.insert(folder->id);
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
        rows_[item->second] = {FolderName(*folder), folder->unread, folder->unread_below};
        ShowRow(item->second);
    }
    auto root = accountItems_.find(account);
    if (root != accountItems_.end()) {
        rows_[root->second].below = pe_folder_list_unread(folders.get());
        ShowRow(root->second);
    }
}

std::wstring Mailbox::AccountName(int64_t account) const {
    auto name = accountNames_.find(account);
    return name != accountNames_.end() ? name->second : L"the account";
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
    auto account = folderAccounts_.find(messageFolder_ ? messageFolder_ : folder_);
    if (account != folderAccounts_.end()) {
        return account->second;
    }
    return selectedAccount_ ? selectedAccount_ : firstAccount_;
}

void Mailbox::OpenSelected() {
    if (!uid_ || !draftFolders_.contains(messageFolder_)) {
        return;
    }
    core::Draft draft(pe_draft_open(core_, messageFolder_, uid_));
    if (!draft) {
        // not fetched yet: MessageReady follows
        openWhenReady_ = true;
        return;
    }
    OpenCompose(parent_, core_, CurrentAccount(), pe_draft_info(draft.get()));
}

core::Draft Mailbox::DraftOfShown(PeDraftKind kind) const {
    if (!uid_ || !view_) {
        return core::Draft();
    }
    return core::Draft(pe_message_draft(core_, messageFolder_, uid_, kind));
}

// ---- the message list ----

// words typed search every folder of every account (in: narrows that); without, the list is the folder's
PeSearch Mailbox::Search() const {
    return {Searching() ? 0 : folder_, PE_SHOW_ALL, findUtf8_.c_str()};
}

bool Mailbox::Searching() const {
    return !find_.empty();
}

// the Folder column while the list has messages of several folders, and not otherwise
void Mailbox::ShowFolderColumn() {
    bool wanted = Searching();
    if (wanted == folderColumn_) {
        return;
    }
    folderColumn_ = wanted;
    // the Subject column gives the Folder column its room, and gets it back: the list stays as wide as its pane
    int subject = ListView_GetColumnWidth(list_, COL_SUBJECT);
    int folder = Scale(130);
    if (wanted) {
        AddColumn(list_, COL_FOLDER, L"Folder", 130);
        ListView_SetColumnWidth(list_, COL_SUBJECT, std::max(Scale(120), subject - folder));
    } else {
        folder = ListView_GetColumnWidth(list_, COL_FOLDER);
        ListView_DeleteColumn(list_, COL_FOLDER);
        ListView_SetColumnWidth(list_, COL_SUBJECT, subject + folder);
    }
}

// the folder of a row in a list of several folders: its name, with its account's when there are several accounts
std::wstring Mailbox::RowFolder(int64_t folder) const {
    auto name = folderNames_.find(folder);
    std::wstring text = name != folderNames_.end() ? name->second.first : L"";
    auto account = folderAccounts_.find(folder);
    if (accountNames_.size() > 1 && account != folderAccounts_.end()) {
        text += L" (" + AccountName(account->second) + L")";
    }
    return text;
}

void Mailbox::ReloadList(bool keepSelection) {
    pages_.clear();
    total_ = 0;
    unread_ = 0;
    ShowFolderColumn();
    PeSearch search = Search();
    // the counts of the folder come from its indexes; a search, of every folder, counts what it finds. An account's own
    // item lists nothing
    if (Searching()) {
        pe_message_count(core_, &search, &total_, &unread_);
    } else if (folder_) {
        pe_folder_counts(core_, folder_, &total_, &unread_);
    }
    // the selection follows the message to where it is now, without a flicker of the reading pane
    int64_t index = keepSelection && uid_ ? pe_message_index(core_, &search, sort_, ascending_, messageFolder_, uid_) : -1;
    reloading_ = true;
    ListView_SetItemCountEx(list_, static_cast<int>(std::min<uint64_t>(total_, INT_MAX)), LVSICF_NOSCROLL);
    // an empty list says why, and that may have changed with the same count
    InvalidateRect(list_, nullptr, TRUE);
    ListView_SetItemState(list_, -1, 0, LVIS_SELECTED | LVIS_FOCUSED);
    if (index >= 0) {
        ListView_SetItemState(list_, static_cast<int>(index), LVIS_SELECTED | LVIS_FOCUSED, LVIS_SELECTED | LVIS_FOCUSED);
        ListView_EnsureVisible(list_, static_cast<int>(index), FALSE);
    }
    reloading_ = false;
    InvalidateRect(list_, nullptr, FALSE);
    OnSelectionChanged();
}

const PeMessage* Mailbox::Row(int index) {
    if (index < 0 || static_cast<uint64_t>(index) >= total_) {
        return nullptr;
    }
    uint64_t offset = static_cast<uint64_t>(index) / kPageSize * kPageSize;
    auto page = std::find_if(pages_.begin(), pages_.end(), [offset](const Page& p) { return p.offset == offset; });
    if (page == pages_.end()) {
        if (pages_.size() >= kPagesKept) {
            pages_.erase(pages_.begin());
        }
        PeSearch search = Search();
        pages_.push_back({offset, core::MessageList(pe_messages(core_, &search, sort_, ascending_, offset, kPageSize))});
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
        case COL_FROM:
            cell_ = Text(row->from);
            break;
        case COL_SUBJECT:
            cell_ = Text(row->subject);
            break;
        case COL_RECEIVED:
            cell_ = row->has_date ? FormatDate(row->date) : L"";
            break;
        case COL_SIZE:
            cell_ = FormatSize(row->size);
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
    } else if (draw->nmcd.dwDrawStage == CDDS_POSTPAINT) {
        if (ListView_GetItemCount(list_) == 0) {
            DrawEmptyList(draw->nmcd.hdc);
        }
    } else if (draw->nmcd.dwDrawStage == CDDS_ITEMPREPAINT) {
        // unread messages in bold, as Outlook Express shows them; the icons once the row is painted
        const PeMessage* row = Row(index);
        result = CDRF_NOTIFYPOSTPAINT;
        if (row && !row->seen) {
            SelectObject(draw->nmcd.hdc, bold_);
            result |= CDRF_NEWFONT;
        }
    } else if (draw->nmcd.dwDrawStage == CDDS_ITEMPOSTPAINT) {
        if (const PeMessage* row = Row(index)) {
            DrawRowIcons(draw->nmcd.hdc, index, *row);
        }
    }
}

// the envelope (closed until read), the paper clip and the flag of a row, drawn over the row as the list painted it:
// the list itself would dither the images of a selected row, and does not highlight those of other columns
void Mailbox::DrawRowIcons(HDC dc, int index, const PeMessage& row) {
    auto draw = [&](int column, int icon) {
        RECT cell;
        ListView_GetSubItemRect(list_, index, column, LVIR_BOUNDS, &cell);
        // the first column's bounds are the whole row's: its width is the column's
        int width = ListView_GetColumnWidth(list_, column);
        ImageList_Draw(listIcons_, icon, dc, cell.left + (width - iconSize_) / 2, cell.top + (cell.bottom - cell.top - iconSize_) / 2,
                       ILD_TRANSPARENT);
    };
    draw(COL_READ, row.seen ? LIST_MAIL_READ : LIST_MAIL);
    if (row.has_attachments) {
        draw(COL_ATTACH, LIST_ATTACH);
    }
    if (row.flagged) {
        draw(COL_FLAG, LIST_FLAG);
    }
}

// ---- the reading pane ----

namespace {

// the header's lines (Cc, when there is one, beside To), from a message's view or its row in the list
std::wstring HeaderText(const char* from, bool hasDate, int64_t date, const char* to, const char* cc, const char* subject) {
    std::wstring header = L" From:  " + Text(from) + L"\r\n Date:  " + (hasDate ? FormatDate(date) : L"") + L"\r\n To:  " + Text(to);
    if (cc && *cc) {
        header += L"    Cc:  " + Text(cc);
    }
    return header + L"\r\n Subject:  " + Text(subject);
}

}  // namespace

void Mailbox::ClearReader(bool loading) {
    if (viewRequest_) {
        pe_message_view_cancel(core_, viewRequest_);
        viewRequest_ = 0;
    }
    uid_ = 0;
    messageFolder_ = 0;
    openWhenReady_ = false;
    remoteImages_ = false;
    view_.reset();
    KillTimer(parent_, TIMER_MARK_READ);
    KillTimer(parent_, TIMER_DOWNLOADING);
    ShowRetry(false);
    // the bars of the message before stay while the next one loads, and go when it is there without them: the
    // message does not jump down and up again
    if (!loading) {
        ShowReaderBars(false, false);
    }
    SetWindowTextW(header_, L"");
    unsubscribeKind_ = PE_UNSUBSCRIBE_NONE;
    ShowWindow(unsubscribe_, SW_HIDE);
    ShowInvitation(nullptr);
    ShowLogo(false);
    // says so rather than a blank pane, unless a message is about to be shown
    preview_.Clear(!loading);
}

void Mailbox::OnSelectionChanged() {
    const PeMessage* row = SelectedRow();
    uint64_t uid = row ? row->uid : 0;
    int64_t folder = row ? row->folder : 0;
    if (uid == uid_ && folder == messageFolder_) {
        return;
    }
    ClearReader(uid != 0);
    if (!uid) {
        return;
    }
    uid_ = uid;
    messageFolder_ = folder;
    // the header from the list at once; the pane says the message is being downloaded a moment later, should it not
    // be here yet
    SetWindowTextW(header_, HeaderText(row->from, row->has_date, row->date, row->recipients, nullptr, row->subject).c_str());
    SetTimer(parent_, TIMER_DOWNLOADING, 250, nullptr);
    // MessageReady follows, right away when the message is cached, or MessageFailed
    pe_message_open(core_, folder, uid);
}

void Mailbox::RetryDownload() {
    if (!uid_) {
        return;
    }
    ShowRetry(false);
    preview_.ShowState(PE_READER_STATE_DOWNLOADING);
    pe_message_open(core_, messageFolder_, uid_);
}

bool Mailbox::OnFolderSelected(LPARAM folder) {
    if (folder == folder_) {
        return false;
    }
    // the message of the folder before is not this folder's, nor is the search; what Show shows stays
    folder_ = folder;
    ResetFind();
    ClearReader();
    ReloadList(false);
    SendMessageW(parent_, WM_COMMAND, MAKEWPARAM(IDC_TREE, 0), 0);
    return true;
}

void Mailbox::ShowMessage() {
    // fetched now: a draft that was double-clicked before opens
    if (std::exchange(openWhenReady_, false)) {
        OpenSelected();
    }
    // parsing, folding and sanitizing a large message takes a while: on a worker, ViewReady follows
    if (viewRequest_) {
        pe_message_view_cancel(core_, viewRequest_);
    }
    viewRequest_ = pe_message_view_start(core_, messageFolder_, uid_, remoteImages_);
    if (!viewRequest_) {
        SetWindowTextW(header_, L" The message could not be shown.");
    }
}

void Mailbox::ShowView() {
    view_.reset(pe_message_view_result(core_, viewRequest_));
    viewRequest_ = 0;
    const PeMessageInfo* info = pe_message_view_info(view_.get());
    if (!info) {
        SetWindowTextW(header_, L" The message could not be shown.");
        ShowReaderBars(false, false);
        return;
    }
    ShowHeader(info);
    // a mailing list that says how to leave it
    unsubscribeKind_ = info->unsubscribe;
    unsubscribeLink_ = Text(info->unsubscribe_link);
    unsubscribeTarget_ = Text(info->unsubscribe_target);
    ShowWindow(unsubscribe_, unsubscribeKind_ != PE_UNSUBSCRIBE_NONE ? SW_SHOW : SW_HIDE);
    ShowInvitation(info->invitation);
    ShowLogo(info->has_logo);
    LayoutReader();
    InvalidateRect(unsubscribe_, nullptr, TRUE);
    preview_.Show(Text(info->document), remoteImages_);
    // offered only for a message with pictures on the internet, until they are shown
    ShowReaderBars(info->attachment_count > 0, info->remote_images && !remoteImages_);
    // read after a moment on screen, not while the user moves through the list
    SetTimer(parent_, TIMER_MARK_READ, 1000, nullptr);
}

void Mailbox::ShowHeader(const PeMessageInfo* info) {
    SetWindowTextW(header_, HeaderText(info->from, info->has_date, info->date, info->to, info->cc, info->subject).c_str());
    if (info->attachment_count > 0) {
        // the paper clip says how many files there are
        std::wstring label = info->attachment_count == 1 ? L"1 file" : std::to_wstring(info->attachment_count) + L" files";
        TBBUTTONINFOW button = {sizeof(button)};
        button.dwMask = TBIF_TEXT;
        button.pszText = label.data();
        SendMessageW(attachments_, TB_SETBUTTONINFOW, IDC_ATTACHMENTS, reinterpret_cast<LPARAM>(&button));
    }
}

void Mailbox::ChooseAttachment() {
    const PeMessageInfo* info = pe_message_view_info(view_.get());
    if (!info) {
        return;
    }
    // each file to save (the name the sender gave, its size), then all of them into a folder, as Outlook Express
    // has it; files are saved, never opened from here
    HMENU menu = CreatePopupMenu();
    for (size_t i = 0; i < info->attachment_count; i++) {
        const PeAttachment* attachment = pe_message_view_attachment(view_.get(), i);
        if (!attachment) {
            continue;
        }
        std::wstring label = MenuText(Text(attachment->filename) + L" (" + FormatSize(attachment->size) + L")");
        AppendMenuW(menu, MF_STRING, 1 + i, label.c_str());
    }
    // after the files' own items
    const UINT kSaveAll = static_cast<UINT>(info->attachment_count) + 1;
    AppendMenuW(menu, MF_SEPARATOR, 0, nullptr);
    AppendMenuW(menu, MF_STRING, kSaveAll, L"&Save Attachments...");
    RECT button;
    GetWindowRect(attachments_, &button);
    UINT chosen = TrackPopupMenu(menu, TPM_RETURNCMD | TPM_RIGHTALIGN | TPM_TOPALIGN, button.right, button.bottom, 0, parent_, nullptr);
    DestroyMenu(menu);
    if (chosen == kSaveAll) {
        SaveAllAttachments();
        return;
    }
    if (chosen == 0) {
        return;
    }
    size_t length = 0;
    char* name = nullptr;
    uint8_t* data = pe_attachment_data(core_, messageFolder_, uid_, static_cast<size_t>(chosen - 1), &length, &name);
    core::String safeName(name);
    if (!data) {
        MessageBoxW(parent_, L"The attachment could not be read.", L"Inbox Classic", MB_OK | MB_ICONERROR);
        return;
    }
    std::wstring path = SaveFileDialog(parent_, Text(safeName.get()));
    if (!path.empty()) {
        if (WriteFileBytes(path, data, length)) {
            MarkFromInternet(path);
        } else {
            MessageBoxW(parent_, L"The attachment could not be saved.", L"Inbox Classic", MB_OK | MB_ICONERROR);
        }
    }
    pe_bytes_free(data, length);
}

void Mailbox::SaveAllAttachments() {
    std::wstring folder = FolderDialog(parent_, L"Save Attachments");
    if (folder.empty()) {
        return;
    }
    // the core saves them all from one reading of the message, a file already there kept and the new one numbered
    size_t saved = 0;
    size_t total = 0;
    std::string dir = core::Narrow(folder);
    if (!pe_save_attachments(core_, messageFolder_, uid_, dir.c_str(), &saved, &total)) {
        MessageBoxW(parent_, L"The message is not downloaded yet.", L"Inbox Classic", MB_OK | MB_ICONINFORMATION);
    } else if (saved < total) {
        std::wstring text = std::to_wstring(total - saved) + L" of the " + std::to_wstring(total) + L" files could not be saved.";
        MessageBoxW(parent_, text.c_str(), L"Inbox Classic", MB_OK | MB_ICONERROR);
    }
}

void Mailbox::LoadPictures() {
    if (uid_ && view_ && !remoteImages_) {
        remoteImages_ = true;
        ShowMessage();
    }
}

void Mailbox::MarkAllRead() {
    if (folder_ && !Searching()) {
        pe_folder_mark_all_read(core_, folder_);
    }
}

void Mailbox::ShowMessage(int64_t folder, uint64_t uid) {
    auto item = items_.find(folder);
    if (item == items_.end()) {
        return;
    }
    // the folder (which ends a search), then the message in it
    TreeView_SelectItem(tree_, item->second);
    if (folder_ != folder) {
        return;
    }
    PeSearch search = Search();
    int64_t index = pe_message_index(core_, &search, sort_, ascending_, folder, uid);
    if (index >= 0 && index <= INT_MAX) {
        int row = static_cast<int>(index);
        ListView_SetItemState(list_, -1, 0, LVIS_SELECTED);
        ListView_SetItemState(list_, row, LVIS_SELECTED | LVIS_FOCUSED, LVIS_SELECTED | LVIS_FOCUSED);
        ListView_EnsureVisible(list_, row, FALSE);
        SetFocus(list_);
    }
}

void Mailbox::SelectStart() {
    if (started_) {
        return;
    }
    started_ = true;
    int64_t folder = 0;
    uint64_t uid = 0;
    if (!folder_ && pe_start_message(core_, &folder, &uid)) {
        ShowMessage(folder, uid);
    }
}

std::wstring Mailbox::Unsubscribe(std::wstring& mailto) {
    const std::wstring& target = unsubscribeTarget_;
    switch (unsubscribeKind_) {
    case PE_UNSUBSCRIBE_ONE_CLICK: {
        std::wstring question = L"Leave this mailing list?\n\nInbox Classic asks " + target +
                                L" to stop sending it to you. No page opens and no message is sent.";
        if (MessageBoxW(parent_, question.c_str(), L"Unsubscribe", MB_YESNO | MB_ICONQUESTION) != IDYES) {
            return L"";
        }
        unsubscribeRequest_ = pe_unsubscribe(core_, messageFolder_, uid_);
        return unsubscribeRequest_ ? L"Unsubscribing from " + target + L"..." : L"This message can not unsubscribe you.";
    }
    case PE_UNSUBSCRIBE_MAIL: {
        std::wstring question = L"Leave this mailing list?\n\nThe list wants a message to " + target +
                                L". Inbox Classic writes it for you; send it to unsubscribe.";
        if (MessageBoxW(parent_, question.c_str(), L"Unsubscribe", MB_OKCANCEL | MB_ICONQUESTION) == IDOK) {
            mailto = unsubscribeLink_;
        }
        return L"";
    }
    case PE_UNSUBSCRIBE_WEB: {
        std::wstring question = L"Leave this mailing list?\n\nThe list's page for it opens in your browser (" + target + L").";
        if (MessageBoxW(parent_, question.c_str(), L"Unsubscribe", MB_OKCANCEL | MB_ICONQUESTION) == IDOK) {
            webview::OpenExternally(unsubscribeLink_.c_str());
        }
        return L"";
    }
    default:
        return L"";
    }
}

std::wstring Mailbox::Unsubscribed(uint64_t request, const std::wstring& problem) {
    if (request != unsubscribeRequest_) {
        return L"";
    }
    unsubscribeRequest_ = 0;
    return problem.empty() ? L"Unsubscribed. The list says it will stop sending this mail." : L"Could not unsubscribe: " + problem;
}

namespace {
// an instant as the reader's local time, or as written (floating: in no zone the invitation defines)
bool EventTime(int64_t seconds, bool floating, SYSTEMTIME& time) {
    return UnixToSystemTime(seconds, !floating, time);
}

std::wstring LongDate(const SYSTEMTIME& time) {
    wchar_t date[96] = L"";
    GetDateFormatEx(LOCALE_NAME_USER_DEFAULT, DATE_LONGDATE, &time, nullptr, date, 96, nullptr);
    return date;
}

bool SameDay(const SYSTEMTIME& a, const SYSTEMTIME& b) {
    return a.wYear == b.wYear && a.wMonth == b.wMonth && a.wDay == b.wDay;
}

// when an event is, in words: its day (or days) and times
std::wstring When(const PeInvitation& event) {
    SYSTEMTIME start, end;
    if (!event.has_start || !EventTime(event.start, event.floating, start)) {
        return L"";
    }
    bool hasEnd = event.has_end && EventTime(event.end - (event.all_day ? 86400 : 0), event.floating, end);
    if (event.all_day) {
        return hasEnd && !SameDay(start, end) ? LongDate(start) + L" to " + LongDate(end) : LongDate(start);
    }
    std::wstring when = LongDate(start) + L", " + FormatTime(start);
    if (hasEnd) {
        when += SameDay(start, end) ? L" to " + FormatTime(end) : L" to " + LongDate(end) + L", " + FormatTime(end);
    }
    return event.floating ? when + L" (the sender's time)" : when;
}
}  // namespace

// the logo is asked for when the message has one the server passed, and shown once it is drawn (LogoReady)
void Mailbox::ShowLogo(bool wanted) {
    if (logoBitmap_) {
        DeleteObject(logoBitmap_);
        logoBitmap_ = nullptr;
    }
    logoRequest_ = 0;
    ShowWindow(logo_, SW_HIDE);
    if (wanted) {
        logoSize_ = Scale(48);
        logoRequest_ = pe_logo_start(core_, messageFolder_, uid_, static_cast<uint32_t>(logoSize_));
    }
}

void Mailbox::ShowInvitation(const PeInvitation* event) {
    if (!event) {
        ShowWindow(invitation_, SW_HIDE);
        ShowWindow(openCalendar_, SW_HIDE);
        return;
    }
    const wchar_t* kinds[] = {L"Invitation: ", L"Updated invitation: ", L"Canceled: ", L"Answer to an invitation: "};
    std::wstring summary = Text(event->summary);
    invitationTitle_ = kinds[std::clamp(static_cast<int>(event->kind), 0, 3)] + (summary.empty() ? std::wstring(L"(no title)") : summary);
    std::vector<std::wstring> parts = {When(*event), Text(event->location)};
    if (std::wstring organizer = Text(event->organizer); !organizer.empty()) {
        parts.push_back(L"Organizer: " + organizer);
    }
    parts.push_back(Text(event->repeats));
    if (event->attendees > 0) {
        parts.push_back(std::to_wstring(event->attendees) + (event->attendees == 1 ? L" attendee" : L" attendees"));
    }
    invitationDetails_.clear();
    for (const std::wstring& part : parts) {
        if (!part.empty()) {
            invitationDetails_ += (invitationDetails_.empty() ? L"" : L"   \u00B7   ") + part;
        }
    }
    ShowWindow(invitation_, SW_SHOW);
    ShowWindow(openCalendar_, SW_SHOW);
    InvalidateRect(invitation_, nullptr, TRUE);
}

// the calendar part as a file of its own (the core writes it, and only it), for the calendar program
void Mailbox::OpenInCalendar() {
    wchar_t temp[MAX_PATH] = L"";
    GetTempPathW(MAX_PATH, temp);
    std::wstring dir = std::wstring(temp) + L"InboxClassic\\Invitations";
    core::String path(pe_invitation_file(core_, messageFolder_, uid_, core::Narrow(dir).c_str()));
    if (!path) {
        MessageBoxW(parent_, L"The invitation could not be read.", L"Inbox Classic", MB_OK | MB_ICONERROR);
        return;
    }
    // marked as from the internet by the core, which wrote it
    std::wstring file = Text(path.get());
    if (reinterpret_cast<INT_PTR>(ShellExecuteW(parent_, L"open", file.c_str(), nullptr, nullptr, SW_SHOWNORMAL)) <= 32) {
        MessageBoxW(parent_, L"No calendar program on this computer opens invitations (.ics files).", L"Inbox Classic", MB_OK | MB_ICONINFORMATION);
    }
}

void Mailbox::MarkJunk(bool junk) {
    const PeMessage* row = SelectedRow();
    if (!row) {
        return;
    }
    if (!pe_message_mark_junk(core_, row->folder, row->uid, junk)) {
        MessageBoxW(parent_, junk ? L"This account has no Junk E-mail folder to move the message to." : L"The message could not be moved to the Inbox.",
                    L"Inbox Classic", MB_OK | MB_ICONINFORMATION);
    }
}

bool Mailbox::InJunk() const {
    return junkFolders_.contains(uid_ ? messageFolder_ : folder_);
}

void Mailbox::MarkSelected(bool seen) {
    if (uid_) {
        pe_message_set_seen(core_, messageFolder_, uid_, seen);
    }
}

// after a message left the list: the one that took its place selected, or the last one
void Mailbox::SelectAfterRemoval(int index) {
    ReloadList(false);
    if (index >= 0 && total_ > 0) {
        int next = std::min(index, static_cast<int>(std::min<uint64_t>(total_, INT_MAX)) - 1);
        ListView_SetItemState(list_, next, LVIS_SELECTED | LVIS_FOCUSED, LVIS_SELECTED | LVIS_FOCUSED);
        ListView_EnsureVisible(list_, next, FALSE);
    }
}

void Mailbox::DeleteSelected() {
    int index = ListView_GetNextItem(list_, -1, LVNI_SELECTED);
    const PeMessage* row = Row(index);
    if (!row) {
        return;
    }
    uint64_t uid = row->uid;
    int64_t folder = row->folder;
    // from Deleted Items, or an account without one, it is gone for good: asked first, as Outlook Express does
    if (pe_folder_deletes_for_good(core_, folder) &&
        MessageBoxW(parent_, L"This message will be deleted for good. Delete it?", L"Inbox Classic",
                    MB_YESNO | MB_ICONWARNING | MB_DEFBUTTON2) != IDYES) {
        return;
    }
    if (pe_message_delete(core_, folder, uid)) {
        SelectAfterRemoval(index);
    }
}

void Mailbox::MoveSelected(HWND owner) {
    int index = ListView_GetNextItem(list_, -1, LVNI_SELECTED);
    const PeMessage* row = Row(index);
    if (!row) {
        return;
    }
    uint64_t uid = row->uid;
    int64_t from = row->folder;
    // the other folders of its account that hold messages
    std::vector<int64_t> ids;
    FormField field{L"Folder:", L"", FormField::Kind::Choice};
    auto account = folderAccounts_.find(from);
    core::FolderList folders(pe_folders(core_, account != folderAccounts_.end() ? account->second : CurrentAccount()));
    for (size_t i = 0; i < pe_folder_list_count(folders.get()); i++) {
        const PeFolder* folder = pe_folder_list_get(folders.get(), i);
        if (folder && folder->selectable && folder->id != from) {
            ids.push_back(folder->id);
            // a special folder by its usual name, the others by their whole path: two folders 2024 in Work and
            // in Personal are not the same
            field.choices.push_back(folder->special_use != PE_SPECIAL_USE_NONE ? FolderName(*folder) : Text(folder->path));
        }
    }
    if (ids.empty()) {
        return;
    }
    field.value = field.choices[0];
    std::vector<FormField> fields = {field};
    if (!FormDialog(owner, L"Move", L"Move the selected message to the folder:", fields)) {
        return;
    }
    int chosen = fields[0].chosen;
    if (chosen >= 0 && static_cast<size_t>(chosen) < ids.size() && pe_message_move(core_, from, uid, ids[chosen])) {
        SelectAfterRemoval(index);
    }
}

void Mailbox::FlagSelected() {
    const PeMessage* row = SelectedRow();
    if (row) {
        pe_message_set_flagged(core_, row->folder, row->uid, !row->flagged);
    }
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
    HMENU menu = CreatePopupMenu();
    // Mark All Read first, as Outlook Express has it, for a folder with unread messages
    uint64_t total = 0, unread = 0;
    bool someUnread = folder_ && pe_folder_counts(core_, folder_, &total, &unread) && unread > 0;
    AppendMenuW(menu, someUnread ? MF_STRING : MF_STRING | MF_GRAYED, IDM_MARK_ALL_READ, L"Mark &All Read");
    AppendMenuW(menu, MF_SEPARATOR, 0, nullptr);
    AppendMenuW(menu, MF_STRING, IDM_NEW_FOLDER, L"&New Folder...");
    std::wstring name;
    bool fixed = true;
    UINT special = folder_ && FolderOf(folder_, name, fixed) && !fixed ? MF_STRING : MF_STRING | MF_GRAYED;
    AppendMenuW(menu, special, IDM_RENAME_FOLDER, L"&Rename...");
    AppendMenuW(menu, special, IDM_DELETE_FOLDER, L"&Delete");
    TrackPopupMenu(menu, TPM_RIGHTBUTTON, screen.x, screen.y, 0, parent_, nullptr);
    DestroyMenu(menu);
}

std::wstring Mailbox::SelectedName() const {
    if (Searching()) {
        // where the search looks; what it found is on the search bar
        return findPlace_.empty() ? L"All folders" : findPlace_;
    }
    if (auto found = folderNames_.find(folder_); found != folderNames_.end()) {
        return found->second.first;
    }
    if (auto account = accountNames_.find(selectedAccount_); account != accountNames_.end()) {
        return account->second;
    }
    return L"";
}

// what an empty list says in its middle: why there is nothing, and what to do about it
void Mailbox::DrawEmptyList(HDC dc) const {
    std::wstring title, more;
    if (Searching()) {
        title = L"No messages match \u201C" + find_ + L"\u201D.";
        more = L"The search looks at the subject, the people, the file names and the text of the messages " +
               (findPlace_.empty() ? std::wstring(L"in every folder") : L"in " + findPlace_) +
               L". Check the spelling, or try fewer words.";
        if (uint64_t left = pe_search_unindexed_count(core_)) {
            more += L"\n\nThe text of " + std::to_wstring(left) + (left == 1 ? L" message is" : L" messages are") +
                    L" still being indexed, so more may be found soon.";
        }
    } else if (folder_) {
        title = L"There are no items in this view.";
    } else if (selectedAccount_) {
        title = L"Choose a folder to see its messages.";
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

// a folder name, asked for; empty when cancelled
std::wstring AskFolderName(HWND owner, const wchar_t* title, const std::wstring& intro, const std::wstring& name) {
    std::vector<FormField> fields = {{L"Folder name:", name}};
    return FormDialog(owner, title, intro, fields) ? fields[0].value : L"";
}

// the reason the core gave, shown
void ShowRefusal(HWND owner, char* reason, const wchar_t* fallback) {
    core::String why(reason);
    std::wstring text = why ? Text(why.get()) : fallback;
    MessageBoxW(owner, text.c_str(), L"Inbox Classic", MB_OK | MB_ICONWARNING);
}

void Mailbox::NewFolder(HWND owner) {
    int64_t account = CurrentAccount();
    if (!account) {
        return;
    }
    std::wstring where = folder_ ? L"The new folder goes in the selected folder." : L"The new folder goes at the top of the account.";
    std::wstring name = AskFolderName(owner, L"New Folder", where, L"");
    if (name.empty()) {
        return;
    }
    char* reason = nullptr;
    if (!pe_folder_create(core_, account, folder_, core::Narrow(name).c_str(), &reason)) {
        ShowRefusal(owner, reason, L"The folder could not be created.");
    }
}

void Mailbox::RenameFolder(HWND owner) {
    if (!folder_) {
        return;
    }
    std::wstring current;
    bool fixed = false;
    FolderOf(folder_, current, fixed);
    std::wstring name = AskFolderName(owner, L"Rename Folder", L"The new name of the folder " + current + L".", current);
    if (name.empty() || name == current) {
        return;
    }
    char* reason = nullptr;
    if (!pe_folder_rename(core_, folder_, core::Narrow(name).c_str(), &reason)) {
        ShowRefusal(owner, reason, L"The folder could not be renamed.");
    }
}

void Mailbox::DeleteFolder(HWND owner) {
    std::wstring name;
    bool fixed = false;
    if (!folder_ || !FolderOf(folder_, name, fixed)) {
        return;
    }
    std::wstring question = L"Delete the folder \"" + name + L"\" with its messages and the folders in it? It is deleted on the server too.";
    if (MessageBoxW(owner, question.c_str(), L"Inbox Classic", MB_YESNO | MB_ICONWARNING | MB_DEFBUTTON2) != IDYES) {
        return;
    }
    char* reason = nullptr;
    if (!pe_folder_delete(core_, folder_, &reason)) {
        ShowRefusal(owner, reason, L"The folder could not be deleted.");
    }
}

std::wstring Mailbox::Counts() const {
    if (Searching() && total_ == 0) {
        return L"No messages found";
    }
    if (Searching()) {
        return std::to_wstring(total_) + L" found, " + std::to_wstring(unread_) + L" unread";
    }
    if (!folder_) {
        return L"";
    }
    return std::to_wstring(total_) + L" message(s), " + std::to_wstring(unread_) + L" unread";
}

// ---- messages from the controls and the core ----

bool Mailbox::OnNotify(NMHDR* header, LRESULT& result) {
    if (header->hwndFrom == tree_) {
        if (header->code == TVN_SELCHANGEDW && !reloading_) {
            auto* change = reinterpret_cast<NMTREEVIEWW*>(header);
            LPARAM item = change->itemNew.hItem ? change->itemNew.lParam : 0;
            // an account has no messages of its own
            selectedAccount_ = item < 0 ? -item : 0;
            // the folder bar and the title name what is selected: an account too, from another account's item
            if (!OnFolderSelected(item > 0 ? item : 0)) {
                SendMessageW(parent_, WM_COMMAND, MAKEWPARAM(IDC_TREE, 0), 0);
            }
        }
        if (header->code == TVN_ITEMEXPANDEDW) {
            // collapsed, a row shows the unread messages it hides; expanded, its folders show them again
            ShowRow(reinterpret_cast<NMTREEVIEWW*>(header)->itemNew.hItem);
        }
        if (header->code == NM_RCLICK) {
            FolderMenu();
            // handled: no WM_CONTEXTMENU after it
            result = 1;
            return true;
        }
        return header->code == TVN_SELCHANGEDW;
    }
    if (header->hwndFrom == attachments_ && header->code == TBN_DROPDOWN) {
        ChooseAttachment();
        result = TBDDRET_DEFAULT;
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
    case LVN_ITEMCHANGED:
        if (!reloading_ && (reinterpret_cast<NMLISTVIEW*>(header)->uChanged & LVIF_STATE)) {
            OnSelectionChanged();
        }
        return true;
    case LVN_BEGINDRAG: {
        auto* begin = reinterpret_cast<NMLISTVIEW*>(header);
        BeginDrag(begin->iItem, begin->ptAction);
        return true;
    }
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
        return true;
    case LVN_COLUMNCLICK: {
        PeSortField sort = SortOf(reinterpret_cast<NMLISTVIEW*>(header)->iSubItem);
        // the same column again turns the order around; dates and sizes start with the largest
        ascending_ = sort == sort_ ? !ascending_ : sort != PE_SORT_FIELD_DATE && sort != PE_SORT_FIELD_SIZE;
        sort_ = sort;
        ReloadList(true);
        return true;
    }
    }
    return false;
}

// ---- files and printing ----

void Mailbox::SaveShownAs(HWND owner) {
    if (!uid_) {
        return;
    }
    size_t length = 0;
    char* name = nullptr;
    uint8_t* data = pe_message_source(core_, messageFolder_, uid_, &length, &name);
    core::String safeName(name);
    if (!data) {
        MessageBoxW(owner, L"The message is not downloaded yet.", L"Inbox Classic", MB_OK | MB_ICONINFORMATION);
        return;
    }
    std::wstring path = SaveFileDialog(owner, Text(safeName.get()), L"Save Message As", L"Mail messages (*.eml)\0*.eml\0All files (*.*)\0*.*\0",
                                       L"eml");
    if (!path.empty()) {
        if (WriteFileBytes(path, data, length)) {
            MarkFromInternet(path);
        } else {
            MessageBoxW(owner, L"The message could not be saved.", L"Inbox Classic", MB_OK | MB_ICONERROR);
        }
    }
    pe_bytes_free(data, length);
}

void Mailbox::ShowProperties(HWND owner) {
    if (!uid_) {
        MessageBoxW(owner, L"Select a message first.", L"Inbox Classic", MB_OK | MB_ICONINFORMATION);
        return;
    }
    core::String headers(pe_message_headers(core_, messageFolder_, uid_));
    if (!headers) {
        MessageBoxW(owner, L"The message is not downloaded yet.", L"Inbox Classic", MB_OK | MB_ICONINFORMATION);
        return;
    }
    const PeMessageInfo* info = pe_message_view_info(view_.get());
    std::wstring subject = info ? Text(info->subject) : L"";
    TextDialog(owner, subject.empty() ? L"Properties" : subject + L" Properties", L"Internet headers for this message:", Text(headers.get()));
}

void Mailbox::ShowSource(HWND owner) {
    if (!uid_) {
        MessageBoxW(owner, L"Select a message first.", L"Inbox Classic", MB_OK | MB_ICONINFORMATION);
        return;
    }
    char* title = nullptr;
    core::String text(pe_message_source_text(core_, messageFolder_, uid_, &title));
    core::String titleText(title);
    if (!text) {
        MessageBoxW(owner, L"The message is not downloaded yet.", L"Inbox Classic", MB_OK | MB_ICONINFORMATION);
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
        ListView_SetItemState(list_, -1, 0, LVIS_SELECTED);
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
    bool draft = draftFolders_.contains(message->folder);
    HMENU menu = CreatePopupMenu();
    if (draft) {
        AppendMenuW(menu, MF_STRING, IDOK, L"&Open");
        SetMenuDefaultItem(menu, IDOK, FALSE);
        AppendMenuW(menu, MF_SEPARATOR, 0, nullptr);
    }
    AppendMenuW(menu, MF_STRING, IDM_REPLY, L"&Reply to Sender");
    AppendMenuW(menu, MF_STRING, IDM_REPLY_ALL, L"Reply to A&ll");
    AppendMenuW(menu, MF_STRING, IDM_FORWARD, L"&Forward");
    AppendMenuW(menu, MF_SEPARATOR, 0, nullptr);
    AppendMenuW(menu, MF_STRING, message->seen ? IDM_MARK_UNREAD : IDM_MARK_READ, message->seen ? L"Mark as &Unread" : L"Mark as &Read");
    AppendMenuW(menu, MF_STRING, IDM_FLAG, message->flagged ? L"Clear Fla&g" : L"Fla&g Message");
    bool junk = junkFolders_.contains(message->folder);
    AppendMenuW(menu, MF_STRING, junk ? IDM_NOT_JUNK : IDM_JUNK, junk ? L"Mark as &Not Junk" : L"Mark as &Junk");
    AppendMenuW(menu, MF_STRING, IDM_MOVE, L"&Move to Folder...");
    AppendMenuW(menu, MF_STRING, IDM_DELETE, L"&Delete");
    AppendMenuW(menu, MF_SEPARATOR, 0, nullptr);
    AppendMenuW(menu, MF_STRING, IDM_SAVE_AS, L"Save &As...");
    AppendMenuW(menu, MF_STRING, IDM_PRINT, L"&Print...");
    AppendMenuW(menu, MF_SEPARATOR, 0, nullptr);
    AppendMenuW(menu, MF_STRING, IDM_VIEW_SOURCE, L"View &Source");
    AppendMenuW(menu, MF_STRING, IDM_PROPERTIES, L"Propert&ies");
    lastMenu_ = menu;
    TrackPopupMenu(menu, TPM_RIGHTBUTTON, screen.x, screen.y, 0, parent_, nullptr);
    lastMenu_ = nullptr;
    DestroyMenu(menu);
}

void Mailbox::PrintShown() {
    if (const PeMessageInfo* info = uid_ ? pe_message_view_info(view_.get()) : nullptr) {
        // the message as it is shown, with the pictures the user allowed
        OpenPrintWindow(parent_, preview_.Environment(), info->document, remoteImages_, Text(info->subject));
    }
}

void Mailbox::Import(HWND owner) {
    if (!folder_) {
        MessageBoxW(owner, L"Choose the folder to put the messages in first.", L"Import Messages", MB_OK | MB_ICONINFORMATION);
        return;
    }
    std::vector<std::wstring> files = OpenFilesDialog(owner, L"Import Messages", L"Mail messages (*.eml)\0*.eml\0All files (*.*)\0*.*\0");
    std::wstring problems;
    for (const std::wstring& file : files) {
        char* reason = nullptr;
        if (!pe_message_import(core_, folder_, core::Narrow(file).c_str(), &reason)) {
            core::String why(reason);
            problems += (why ? Text(why.get()) : file) + L"\n";
        }
    }
    if (!problems.empty()) {
        MessageBoxW(owner, (L"These were not imported:\n\n" + problems).c_str(), L"Import Messages", MB_OK | MB_ICONWARNING);
    }
}

// ---- the Find box ----

void Mailbox::PlaceFind(const RECT& row) {
    int height = Scale(26), width = Scale(280), edge = GetSystemMetrics(SM_CXEDGE);
    MoveWindow(findField_, row.right - width - Scale(8), row.top + (row.bottom - row.top - height) / 2, width, height, TRUE);
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
}

bool Mailbox::OnDrawItem(const DRAWITEMSTRUCT& item) {
    if (item.hwndItem == logo_) {
        // the logo, its own transparency kept, in the middle of its place beside the header
        FillRect(item.hDC, &item.rcItem, GetSysColorBrush(COLOR_BTNFACE));
        if (logoBitmap_) {
            HDC source = CreateCompatibleDC(item.hDC);
            HGDIOBJ old = SelectObject(source, logoBitmap_);
            BLENDFUNCTION blend = {AC_SRC_OVER, 0, 255, AC_SRC_ALPHA};
            int x = (item.rcItem.left + item.rcItem.right - logoSize_) / 2;
            int y = (item.rcItem.top + item.rcItem.bottom - logoSize_) / 2;
            AlphaBlend(item.hDC, x, y, logoSize_, logoSize_, source, 0, 0, logoSize_, logoSize_, blend);
            SelectObject(source, old);
            DeleteDC(source);
        }
        return true;
    }
    if (item.hwndItem == invitation_) {
        // the calendar, then the event in two lines, on the information bar's yellow
        RECT area = item.rcItem;
        FillRect(item.hDC, &area, GetSysColorBrush(COLOR_INFOBK));
        int pad = Scale(8);
        ImageList_Draw(listIcons_, LIST_CALENDAR_LTR, item.hDC, area.left + pad, (area.top + area.bottom - iconSize_) / 2, ILD_TRANSPARENT);
        area.left += pad + iconSize_ + pad;
        RECT button;
        GetWindowRect(openCalendar_, &button);
        area.right -= (button.right - button.left) + 2 * pad;
        SetTextColor(item.hDC, GetSysColor(COLOR_INFOTEXT));
        SetBkMode(item.hDC, TRANSPARENT);
        UINT format = DT_LEFT | DT_SINGLELINE | DT_NOPREFIX | DT_END_ELLIPSIS;
        int middle = (area.top + area.bottom) / 2;
        RECT title = {area.left, area.top + Scale(3), area.right, middle};
        HGDIOBJ old = SelectObject(item.hDC, bold_);
        DrawTextW(item.hDC, invitationTitle_.c_str(), -1, &title, format | DT_BOTTOM);
        SelectObject(item.hDC, reinterpret_cast<HFONT>(SendMessageW(list_, WM_GETFONT, 0, 0)));
        RECT details = {area.left, middle + Scale(1), area.right, area.bottom - Scale(3)};
        DrawTextW(item.hDC, invitationDetails_.c_str(), -1, &details, format | DT_TOP);
        SelectObject(item.hDC, old);
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
    findUtf8_.clear();
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
    switch (id) {
    case IDC_ATTACHMENTS:
        ChooseAttachment();
        return true;
    case IDC_PICTURES:
        LoadPictures();
        return true;
    case IDC_RETRY:
        RetryDownload();
        return true;
    case IDC_SEARCH_CLEAR:
        ClearFind();
        return true;
    case IDC_OPEN_CALENDAR:
        OpenInCalendar();
        return true;
    }
    return false;
}

// ---- dragging a message onto a folder ----

namespace {
// the cursors of a drag and drop as Explorer shows them (OLE's own), the system's where those are missing
HCURSOR DragCursor(int effect) {
    // in ole32: 1 is no drop, 2 move, 3 copy; loaded once
    static const std::array<HCURSOR, 3> cursors = [] {
        std::array<HCURSOR, 3> loaded = {};
        HMODULE ole = GetModuleHandleW(L"ole32.dll");
        for (int i = 0; i < 3; i++) {
            HCURSOR cursor = ole ? LoadCursorW(ole, MAKEINTRESOURCEW(i + 1)) : nullptr;
            loaded[i] = cursor ? cursor : LoadCursorW(nullptr, i == 0 ? IDC_NO : IDC_ARROW);
        }
        return loaded;
    }();
    return cursors[std::clamp(effect, 1, 3) - 1];
}

// where the drag image is drawn: in the coordinates of the window's own rectangle
POINT InWindow(HWND window, POINT screen) {
    RECT bounds;
    GetWindowRect(window, &bounds);
    return {screen.x - bounds.left, screen.y - bounds.top};
}
}  // namespace

void Mailbox::BeginDrag(int index, POINT at) {
    const PeMessage* row = Row(index);
    if (!row || drag_) {
        return;
    }
    drag_.emplace();
    drag_->folder = row->folder;
    drag_->uid = row->uid;
    drag_->index = index;
    // the row as it looks, under the cursor where it was picked up
    POINT origin = {};
    drag_->image = ListView_CreateDragImage(list_, index, &origin);
    if (drag_->image) {
        ImageList_BeginDrag(drag_->image, 0, at.x - origin.x, at.y - origin.y);
        POINT screen = at;
        ClientToScreen(list_, &screen);
        POINT inside = InWindow(parent_, screen);
        ImageList_DragEnter(parent_, inside.x, inside.y);
    }
    SetCapture(parent_);
    SetTimer(parent_, TIMER_DRAG, 50, nullptr);
    SetCursor(DragCursor(1));
}

int64_t Mailbox::DropTarget(POINT screen, HTREEITEM& over) const {
    over = nullptr;
    if (WindowFromPoint(screen) != tree_) {
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
    TVITEMW item = {};
    item.mask = TVIF_PARAM;
    item.hItem = over;
    TreeView_GetItem(tree_, &item);
    // an account's own item (its id negated), the folder the message is in, one of another account, or one that
    // holds no messages: not there
    int64_t folder = static_cast<int64_t>(item.lParam);
    auto from = folderAccounts_.find(drag_->folder), to = folderAccounts_.find(folder);
    if (folder <= 0 || folder == drag_->folder || unselectable_.count(folder) || from == folderAccounts_.end() ||
        to == folderAccounts_.end() || from->second != to->second) {
        return 0;
    }
    return folder;
}

void Mailbox::DragTo(POINT screen) {
    HTREEITEM over = nullptr;
    int64_t target = DropTarget(screen, over);
    if (over != drag_->over) {
        drag_->over = over;
        drag_->overSince = GetTickCount64();
        drag_->opened = false;
    }
    if (target != drag_->target) {
        drag_->target = target;
        // the folder it would go to highlighted
        ChangeTreeUnderDrag([&] { TreeView_SelectDropTarget(tree_, target ? over : nullptr); });
    }
    if (drag_->image) {
        POINT inside = InWindow(parent_, screen);
        ImageList_DragMove(inside.x, inside.y);
    }
    // Ctrl copies, as in Explorer
    SetCursor(DragCursor(!target ? 1 : (GetKeyState(VK_CONTROL) < 0 ? 3 : 2)));
}

void Mailbox::ChangeTreeUnderDrag(const std::function<void()>& change) {
    ImageList_DragShowNolock(FALSE);
    change();
    UpdateWindow(tree_);
    ImageList_DragShowNolock(TRUE);
}

void Mailbox::EndDrag(bool drop) {
    if (!drag_) {
        return;
    }
    Drag drag = *drag_;
    drag_.reset();
    KillTimer(parent_, TIMER_DRAG);
    if (drag.image) {
        ImageList_DragLeave(parent_);
        ImageList_EndDrag();
        ImageList_Destroy(drag.image);
    }
    TreeView_SelectDropTarget(tree_, nullptr);
    if (GetCapture() == parent_) {
        ReleaseCapture();
    }
    if (!drop || !drag.target) {
        return;
    }
    // Ctrl copies, as in Explorer; a move selects the message after it, as Move to Folder does
    bool copy = GetKeyState(VK_CONTROL) < 0;
    if (copy) {
        pe_message_copy(core_, drag.folder, drag.uid, drag.target);
    } else if (pe_message_move(core_, drag.folder, drag.uid, drag.target) && drag.folder == messageFolder_ && drag.uid == uid_) {
        SelectAfterRemoval(drag.index);
    }
}

bool Mailbox::OnDragMouse(UINT message) {
    if (!drag_) {
        return false;
    }
    POINT screen;
    GetCursorPos(&screen);
    if (message == WM_MOUSEMOVE) {
        DragTo(screen);
    } else {
        // let go over a folder: there; the capture lost (another window, Alt+Tab): nowhere
        EndDrag(message == WM_LBUTTONUP);
    }
    return true;
}

void Mailbox::OnTimer(UINT_PTR id) {
    if (id == TIMER_DRAG) {
        if (!drag_) {
            KillTimer(parent_, TIMER_DRAG);
            return;
        }
        if (GetKeyState(VK_ESCAPE) < 0) {
            EndDrag(false);
            return;
        }
        POINT screen;
        GetCursorPos(&screen);
        RECT tree;
        GetWindowRect(tree_, &tree);
        // at the top or bottom edge of the tree it scrolls, to the folders out of view
        if (screen.x >= tree.left && screen.x < tree.right) {
            int edge = Scale(16);
            WPARAM scroll = screen.y < tree.top + edge ? SB_LINEUP : screen.y >= tree.bottom - edge ? SB_LINEDOWN : SB_ENDSCROLL;
            if (scroll != SB_ENDSCROLL) {
                ChangeTreeUnderDrag([&] { SendMessageW(tree_, WM_VSCROLL, scroll, 0); });
                DragTo(screen);
            }
        }
        // a folder held over for a moment opens, to the folders in it
        if (drag_->over && !drag_->opened && GetTickCount64() - drag_->overSince > 800) {
            ChangeTreeUnderDrag([&] { TreeView_Expand(tree_, drag_->over, TVE_EXPAND); });
            drag_->opened = true;
        }
        // Ctrl pressed or let go changes the cursor at once, without the mouse moving
        SetCursor(DragCursor(!drag_->target ? 1 : (GetKeyState(VK_CONTROL) < 0 ? 3 : 2)));
        return;
    }
    if (id == TIMER_DOWNLOADING) {
        KillTimer(parent_, TIMER_DOWNLOADING);
        preview_.ShowState(PE_READER_STATE_DOWNLOADING);
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
            findUtf8_ = core::Narrow(find_);
            core::String place(pe_search_place(findUtf8_.c_str()));
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
    if (row && row->uid == uid_ && !row->seen) {
        MarkSelected(true);
    }
}

void Mailbox::OnEvent(const UiEvent& event) {
    switch (event.kind) {
    case PE_EVENT_KIND_FOLDERS_CHANGED:
        Reload();
        break;
    case PE_EVENT_KIND_FOLDER_CHANGED:
        UpdateFolders(event.account);
        if (event.folder == folder_ && !Searching()) {
            ReloadList(true);
        } else if (Searching()) {
            // a list of several folders has messages of any of them
            SetTimer(parent_, TIMER_RELOAD, 300, nullptr);
        }
        break;
    case PE_EVENT_KIND_MESSAGE_READY:
        if (event.folder == messageFolder_ && event.uid == uid_) {
            KillTimer(parent_, TIMER_DOWNLOADING);
            ShowRetry(false);
            ShowMessage();
        }
        break;
    case PE_EVENT_KIND_MESSAGE_FAILED:
        if (event.folder == messageFolder_ && event.uid == uid_) {
            KillTimer(parent_, TIMER_DOWNLOADING);
            ShowReaderBars(false, false);
            ShowRetry(true);
            preview_.ShowState(PE_READER_STATE_FAILED, event.failure, core::Narrow(event.message));
        }
        break;
    case PE_EVENT_KIND_SYNC_FINISHED:
        // the account is back: a message it could not give is tried again
        if (event.failure == PE_FAILURE_KIND_NONE && IsWindowVisible(retry_)) {
            auto account = folderAccounts_.find(messageFolder_);
            if (account != folderAccounts_.end() && account->second == event.account) {
                RetryDownload();
            }
        }
        break;
    case PE_EVENT_KIND_VIEW_READY:
        // a view for a message that is no longer selected was cancelled, its event is not this one
        if (viewRequest_ && event.uid == viewRequest_) {
            ShowView();
        }
        break;
    case PE_EVENT_KIND_LOGO_READY:
        if (logoRequest_ && event.uid == logoRequest_) {
            logoRequest_ = 0;
            size_t length = 0;
            uint8_t* pixels = pe_logo_result(core_, event.uid, &length);
            size_t expected = static_cast<size_t>(logoSize_) * logoSize_ * 4;
            if (pixels && length == expected) {
                // the core's pixels, BGRA with the alpha multiplied in, as AlphaBlend takes them
                BITMAPINFO info = {};
                info.bmiHeader = {sizeof(BITMAPINFOHEADER), logoSize_, -logoSize_, 1, 32, BI_RGB};
                void* bits = nullptr;
                logoBitmap_ = CreateDIBSection(nullptr, &info, DIB_RGB_COLORS, &bits, nullptr, 0);
                if (logoBitmap_ && bits) {
                    memcpy(bits, pixels, expected);
                    ShowWindow(logo_, SW_SHOW);
                    LayoutReader();
                    InvalidateRect(logo_, nullptr, TRUE);
                }
            }
            if (pixels) {
                pe_bytes_free(pixels, length);
            }
        }
        break;
    default:
        break;
    }
}
