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

// the reason the core gave for a refusal, or `fallback` when it gave none
std::wstring ReasonText(char* reason, PeText fallback) {
    core::String why(reason);
    return why ? Text(why.get()) : core::T(fallback);
}

// a folder name, asked for; empty when cancelled
std::wstring AskFolderName(HWND owner, PeText title, const std::wstring& intro, const std::wstring& name) {
    std::vector<FormField> fields = {{core::T(PE_TEXT_WIN_FOLDER_NAME), name}};
    return FormDialog(owner, core::Plain(title), intro, fields) ? fields[0].value : L"";
}

// the reason the core gave, shown
void ShowRefusal(HWND owner, char* reason, PeText fallback) {
    MessageBoxW(owner, ReasonText(reason, fallback).c_str(), L"Inbox Classic", MB_OK | MB_ICONWARNING);
}

constexpr uint64_t kPageSize = 100;
// pages kept around while the list scrolls
constexpr size_t kPagesKept = 8;
constexpr int kHeaderLines = 4;
// the data of the All Inboxes item: neither a folder (positive) nor an account (a negated id)
constexpr LPARAM kAllInboxesItem = std::numeric_limits<LPARAM>::min();
std::wstring AllInboxes() {
    return core::T(PE_TEXT_WIN_ALL_INBOXES);
}

// as Outlook Express has them: the envelope (read or not), the paper clip and the flag, then the text columns
// no read and unread column: bold says it
enum Column { COL_ATTACH, COL_FLAG, COL_FROM, COL_SUBJECT, COL_RECEIVED, COL_SIZE, COL_FOLDER };

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
        DrawTextW(dc, core::T(PE_TEXT_WIN_FIND_HINT).c_str(), -1, &area, DT_LEFT | DT_VCENTER | DT_SINGLELINE | DT_NOPREFIX);
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
        return core::T(PE_TEXT_FOLDER_INBOX);
    case PE_SPECIAL_USE_SENT:
        return core::T(PE_TEXT_FOLDER_SENT);
    case PE_SPECIAL_USE_TRASH:
        return core::T(PE_TEXT_FOLDER_DELETED);
    case PE_SPECIAL_USE_DRAFTS:
        return core::T(PE_TEXT_FOLDER_DRAFTS);
    case PE_SPECIAL_USE_JUNK:
        return core::T(PE_TEXT_FOLDER_JUNK);
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
    SetAccessibleDescription(findEdit_, core::T(PE_TEXT_WIN_FIND_HINT));
    findClear_ = CreateChild(findField_, L"BUTTON", core::T(PE_TEXT_WIN_CLEAR_SEARCH).c_str(), BS_OWNERDRAW, IDC_FIND_CLEAR, {});
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
    std::wstring findTip = core::T(PE_TEXT_WIN_FIND_TIP) + L"\r\n" + kFindSyntax;
    tool.lpszText = findTip.data();
    for (HWND window : {findField_, findEdit_}) {
        tool.uId = reinterpret_cast<UINT_PTR>(window);
        SendMessageW(tip, TTM_ADDTOOLW, 0, reinterpret_cast<LPARAM>(&tool));
    }
    IconColumn(list_, COL_ATTACH, LIST_ATTACH);
    IconColumn(list_, COL_FLAG, LIST_FLAG);
    AddColumn(list_, COL_FROM, core::T(PE_TEXT_WIN_COL_FROM).c_str(), 200);
    AddColumn(list_, COL_SUBJECT, core::T(PE_TEXT_WIN_COL_SUBJECT).c_str(), 320);
    AddColumn(list_, COL_RECEIVED, core::T(PE_TEXT_WIN_COL_RECEIVED).c_str(), 130);
    AddColumn(list_, COL_SIZE, core::T(PE_TEXT_WIN_COL_SIZE).c_str(), 84, LVCFMT_RIGHT);

    // not drawn over the Unsubscribe link that lies on it
    header_ = CreateChild(parent, L"STATIC", L"", SS_LEFT | SS_NOPREFIX | SS_SUNKEN | WS_CLIPSIBLINGS, 0, {});
    unsubscribe_ = CreateChild(parent, L"STATIC", core::T(PE_TEXT_WIN_UNSUBSCRIBE).c_str(), SS_NOTIFY | SS_RIGHT | SS_NOPREFIX, IDC_UNSUBSCRIBE, {});
    ShowWindow(unsubscribe_, SW_HIDE);
    invitation_ = CreateChild(parent, L"STATIC", L"", SS_OWNERDRAW | WS_BORDER | WS_CLIPSIBLINGS, IDC_INVITATION, {});
    logo_ = CreateChild(parent, L"STATIC", L"", SS_OWNERDRAW, IDC_LOGO, {});
    ShowWindow(logo_, SW_HIDE);
    openCalendar_ = CreateChild(parent, L"BUTTON", core::T(PE_TEXT_WIN_OPEN_IN_CALENDAR).c_str(), WS_TABSTOP | BS_PUSHBUTTON, IDC_OPEN_CALENDAR, {});
    ShowWindow(invitation_, SW_HIDE);
    ShowWindow(openCalendar_, SW_HIDE);
    // the paper clip at the right of the header, as Outlook Express has it: the files of the message in its menu
    attachments_ = CreateBar(parent, CCS_NODIVIDER | CCS_NOPARENTALIGN | CCS_NORESIZE, IDC_ATTACHMENTS, BarIcons::Big);
    // a label from the start, so the bar keeps a row for it under the icon ("2 files" once a message is shown)
    AddButton(attachments_, IDC_ATTACHMENTS, core::T(PE_TEXT_WIN_FILES, {{"count", L"1"}}).c_str(), BTNS_WHOLEDROPDOWN, ICON_ATTACH);
    // the information bar of Outlook Express over a message whose pictures on the internet are blocked; a click
    // shows them
    std::wstring blocked = L" " + core::T(PE_TEXT_WIN_PICTURES_BLOCKED);
    pictures_ = CreateChild(parent, L"STATIC", blocked.c_str(),
                            SS_LEFT | SS_NOTIFY | SS_CENTERIMAGE | SS_NOPREFIX | SS_ENDELLIPSIS | WS_BORDER, IDC_PICTURES, {});
    ShowWindow(attachments_, SW_HIDE);
    ShowWindow(pictures_, SW_HIDE);
    // the same bar over a message that could not be downloaded: a click tries again
    core::String note(pe_retry_note());
    std::wstring retry = L" " + Text(note.get()) + L" " + core::T(PE_TEXT_WIN_CLICK_TO_RETRY);
    retry_ = CreateChild(parent, L"STATIC", retry.c_str(), SS_LEFT | SS_NOTIFY | SS_CENTERIMAGE | SS_NOPREFIX | SS_ENDELLIPSIS | WS_BORDER,
                         IDC_RETRY, {});
    ShowWindow(retry_, SW_HIDE);
    // over the list while searching, in the colors of the information bar: what was found, and a link to end it
    searchBar_ = CreateChild(parent, L"STATIC", L"", SS_OWNERDRAW | WS_BORDER | WS_CLIPSIBLINGS, IDC_SEARCH_BAR, {});
    searchClear_ = CreateChild(parent, L"STATIC", core::T(PE_TEXT_WIN_CLEAR_SEARCH).c_str(), SS_NOTIFY | SS_CENTERIMAGE | SS_CENTER | SS_NOPREFIX,
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
    RevokeDropSite(tree_, treeTarget_);
    RevokeDropSite(list_, listTarget_);
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
    MoveWindow(list_, list.left, list.top, width, list.bottom - list.top, TRUE);
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
    bool allSelected = allInboxes_;
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
    allInboxesItem_ = nullptr;
    draftFolders_.clear();
    junkFolders_.clear();
    firstAccount_ = 0;
    core::AccountList accounts(pe_accounts(core_));
    size_t count = pe_account_list_count(accounts.get());
    if (pe_all_inboxes_shown(count)) {
        // above the accounts, the mail of every Inbox; its unread count as a folder's
        allInboxesItem_ = InsertItem(tree_, TVI_ROOT, AllInboxes(), kAllInboxesItem, false, FOLDER_MAIL_INBOX);
        rows_[allInboxesItem_] = {AllInboxes(), pe_inbox_unread(core_), 0};
        ShowRow(allInboxesItem_);
    }
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
    } else if (auto item = items_.find(selected); item != items_.end()) {
        target = item->second;
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
    if (allInboxesItem_) {
        rows_[allInboxesItem_].own = pe_inbox_unread(core_);
        ShowRow(allInboxesItem_);
    }
}

std::wstring Mailbox::AccountName(int64_t account) const {
    auto name = accountNames_.find(account);
    return name != accountNames_.end() ? name->second : core::T(PE_TEXT_WIN_THE_ACCOUNT);
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
    FlushSelection();
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

// words typed search every folder of every account (in: narrows that); without, the list is the folder's, or every
// Inbox's
PeSearch Mailbox::Search() const {
    return {Searching() ? 0 : folder_, !Searching() && allInboxes_, PE_SHOW_ALL, findUtf8_.c_str()};
}

bool Mailbox::Searching() const {
    return !find_.empty();
}

bool Mailbox::SeveralFolders() const {
    return Searching() || allInboxes_;
}

// the Folder column while the list has messages of several folders, and not otherwise; in All Inboxes, whose rows are
// all in an Inbox, the Account column
void Mailbox::ShowFolderColumn() {
    bool wanted = SeveralFolders();
    std::wstring title = core::T(Searching() ? PE_TEXT_WIN_COL_FOLDER : PE_TEXT_WIN_COL_ACCOUNT);
    if (wanted && folderColumn_) {
        LVCOLUMNW column = {};
        column.mask = LVCF_TEXT;
        column.pszText = title.data();
        ListView_SetColumn(list_, COL_FOLDER, &column);
    }
    if (wanted == folderColumn_) {
        return;
    }
    folderColumn_ = wanted;
    // the Subject column gives the Folder column its room, and gets it back: the list stays as wide as its pane
    int subject = ListView_GetColumnWidth(list_, COL_SUBJECT);
    int folder = Scale(130);
    if (wanted) {
        AddColumn(list_, COL_FOLDER, title.c_str(), 130);
        ListView_SetColumnWidth(list_, COL_SUBJECT, std::max(Scale(120), subject - folder));
    } else {
        folder = ListView_GetColumnWidth(list_, COL_FOLDER);
        ListView_DeleteColumn(list_, COL_FOLDER);
        ListView_SetColumnWidth(list_, COL_SUBJECT, subject + folder);
    }
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
    ShowFolderColumn();
    PeSearch search = Search();
    // the counts of the folder come from its indexes; a search, of every folder, and All Inboxes count what they find.
    // An account's own item lists nothing
    if (SeveralFolders()) {
        pe_message_count(core_, &search, &total_, &unread_);
    } else if (folder_) {
        pe_folder_counts(core_, folder_, &total_, &unread_);
    }
    // the selection follows the message to where it is now, without a flicker of the reading pane; several selected
    // messages are found again where they are now
    int64_t index = keepSelection && uid_ && !pending ? pe_message_index(core_, &search, sort_, ascending_, messageFolder_, uid_) : -1;
    core::Positions several(keepSelection && (pending || !uid_) && pe_selection_count(selection_.get()) > 0
                                ? pe_selection_positions(core_, selection_.get(), &search, sort_, ascending_)
                                : nullptr);
    reloading_ = true;
    ListView_SetItemCountEx(list_, static_cast<int>(std::min<uint64_t>(total_, INT_MAX)), LVSICF_NOSCROLL);
    // an empty list says why, and that may have changed with the same count
    InvalidateRect(list_, nullptr, TRUE);
    ListView_SetItemState(list_, -1, 0, LVIS_SELECTED | LVIS_FOCUSED);
    if (index >= 0) {
        ListView_SetItemState(list_, static_cast<int>(index), LVIS_SELECTED | LVIS_FOCUSED, LVIS_SELECTED | LVIS_FOCUSED);
        ListView_EnsureVisible(list_, static_cast<int>(index), FALSE);
    }
    // the messages selected before are still the selection where they are now: only their numbers change
    bool kept = SelectPositions(several.get(), false);
    if (undoPending_ && SelectRestored(search)) {
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

namespace {

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

// the paper clip and the flag of a row, drawn over the row as the list painted it:
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
    if (row.has_attachments) {
        draw(COL_ATTACH, LIST_ATTACH);
    }
    if (row.flagged) {
        // the flag in its colour (red when it has none); white on the selected row's highlight, as the Mac shows it,
        // where a colour (blue on blue) could not be seen
        RECT cell;
        ListView_GetSubItemRect(list_, index, COL_FLAG, LVIR_BOUNDS, &cell);
        int width = ListView_GetColumnWidth(list_, COL_FLAG);
        bool selected = ListView_GetItemState(list_, index, LVIS_SELECTED) != 0;
        COLORREF rgb = selected ? GetSysColor(COLOR_HIGHLIGHTTEXT) : FlagRgb(row.flag_color ? row.flag_color : 1);
        DrawFlag(dc, cell.left + (width - iconSize_) / 2, cell.top + (cell.bottom - cell.top - iconSize_) / 2, iconSize_,
                 rgb);
    }
}

// ---- the reading pane ----

namespace {

// the header's lines (Cc, when there is one, beside To), from a message's view or its row in the list
std::wstring HeaderText(const char* from, bool hasDate, int64_t date, const char* to, const char* cc, const char* subject) {
    auto label = [](PeText name) { return core::Plain(name) + L":  "; };
    std::wstring header = L" " + label(PE_TEXT_HEADER_FROM) + Text(from) + L"\r\n " + label(PE_TEXT_HEADER_DATE) +
                          (hasDate ? FormatDate(date) : L"") + L"\r\n " + label(PE_TEXT_HEADER_TO) + Text(to);
    if (cc && *cc) {
        header += L"    " + label(PE_TEXT_HEADER_CC) + Text(cc);
    }
    return header + L"\r\n " + label(PE_TEXT_HEADER_SUBJECT) + Text(subject);
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
    summaryPage_.clear();
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
    if (count == 1) {
        pe_selection_clear(selection_.get());
        if (const PeMessage* row = SelectedRow()) {
            pe_selection_add(selection_.get(), row->folder, row->uid);
        }
    } else if (count == 0) {
        pe_selection_clear(selection_.get());
    } else if (rebuild) {
        // the selected rows as ranges of positions: Select All on a long list is one range, not every row
        std::vector<uint64_t> starts, ends;
        for (int i : SelectedRows()) {
            if (!ends.empty() && ends.back() == static_cast<uint64_t>(i)) {
                ends.back()++;
            } else {
                starts.push_back(static_cast<uint64_t>(i));
                ends.push_back(static_cast<uint64_t>(i) + 1);
            }
        }
        PeSearch search = Search();
        pe_selection_set_ranges(core_, selection_.get(), &search, sort_, ascending_, starts.data(), ends.data(), starts.size());
    }
    summary_ = {};
    if (pe_selection_count(selection_.get()) > 0) {
        pe_selection_summary(core_, selection_.get(), &summary_);
    }
    if (count <= 1) {
        return;
    }
    // several: none of them is opened, the pane says how many (again only when that changed)
    if (uid_) {
        ClearReader();
        // the header without the logo and bars of the message that was shown
        LayoutReader();
    }
    core::String page(pe_selection_page(&summary_));
    std::wstring html = page ? core::Widen(page.get()) : L"";
    if (html != summaryPage_) {
        summaryPage_ = html;
        preview_.Show(html);
    }
}

bool Mailbox::SelectRestored(const PeSearch& search) {
    core::Selection restored(pe_selection_new());
    if (!pe_undo_restored(core_, restored.get()) || pe_selection_count(restored.get()) == 0) {
        return false;
    }
    core::Positions at(pe_selection_positions(core_, restored.get(), &search, sort_, ascending_));
    if (pe_positions_count(at.get()) == 0) {
        return false;
    }
    ListView_SetItemState(list_, -1, 0, LVIS_SELECTED | LVIS_FOCUSED);
    // the first of them in view
    return SelectPositions(at.get(), true);
}

void Mailbox::RetryDownload() {
    if (!uid_) {
        return;
    }
    ShowRetry(false);
    preview_.ShowState(PE_READER_STATE_DOWNLOADING);
    pe_message_open(core_, messageFolder_, uid_);
}

bool Mailbox::OnFolderSelected(int64_t folder, bool allInboxes) {
    if (folder == folder_ && allInboxes == allInboxes_) {
        return false;
    }
    // the message of the folder before is not this folder's, nor is the search; what Show shows stays
    folder_ = folder;
    allInboxes_ = allInboxes;
    undoPending_ = false;
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
        SetWindowTextW(header_, (L" " + core::T(PE_TEXT_WIN_NOT_SHOWN)).c_str());
    }
}

void Mailbox::ShowView() {
    view_.reset(pe_message_view_result(core_, viewRequest_));
    viewRequest_ = 0;
    const PeMessageInfo* info = pe_message_view_info(view_.get());
    if (!info) {
        SetWindowTextW(header_, (L" " + core::T(PE_TEXT_WIN_NOT_SHOWN)).c_str());
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
        std::wstring label = core::T(PE_TEXT_WIN_FILES, {{"count", std::to_wstring(info->attachment_count)}});
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
    AppendMenuW(menu, MF_STRING, kSaveAll, MenuItem(PE_TEXT_WIN_SAVE_ATTACHMENTS).c_str());
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
        MessageBoxW(parent_, core::T(PE_TEXT_WIN_ATTACHMENT_NOT_READ).c_str(), L"Inbox Classic", MB_OK | MB_ICONERROR);
        return;
    }
    std::wstring path = SaveFileDialog(parent_, Text(safeName.get()));
    if (!path.empty()) {
        if (WriteFileBytes(path, data, length)) {
            MarkFromInternet(path);
        } else {
            MessageBoxW(parent_, core::T(PE_TEXT_WIN_ATTACHMENT_NOT_SAVED).c_str(), L"Inbox Classic", MB_OK | MB_ICONERROR);
        }
    }
    pe_bytes_free(data, length);
}

void Mailbox::SaveAllAttachments() {
    std::wstring folder = FolderDialog(parent_, core::Plain(PE_TEXT_WIN_SAVE_ATTACHMENTS).c_str());
    if (folder.empty()) {
        return;
    }
    // the core saves them all from one reading of the message, a file already there kept and the new one numbered
    size_t saved = 0;
    size_t total = 0;
    std::string dir = core::Narrow(folder);
    if (!pe_save_attachments(core_, messageFolder_, uid_, dir.c_str(), &saved, &total)) {
        MessageBoxW(parent_, core::T(PE_TEXT_WIN_NOT_DOWNLOADED).c_str(), L"Inbox Classic", MB_OK | MB_ICONINFORMATION);
    } else if (saved < total) {
        std::wstring text =
            core::T(PE_TEXT_WIN_FILES_NOT_SAVED, {{"failed", std::to_wstring(total - saved)}, {"count", std::to_wstring(total)}});
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
    if (Searching()) {
        return;
    }
    if (allInboxes_) {
        pe_mark_all_inboxes_read(core_);
    } else if (folder_) {
        pe_folder_mark_all_read(core_, folder_);
    }
}

void Mailbox::ShowMessage(int64_t folder, uint64_t uid) {
    auto item = items_.find(folder);
    if (item == items_.end()) {
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
    // the folder (which ends a search), then the message in it
    TreeView_SelectItem(tree_, item->second);
    if (folder_ == folder) {
        SelectInList(folder, uid);
    }
}

bool Mailbox::SelectInList(int64_t folder, uint64_t uid) {
    PeSearch search = Search();
    int64_t index = pe_message_index(core_, &search, sort_, ascending_, folder, uid);
    if (index < 0 || index > INT_MAX) {
        return false;
    }
    int row = static_cast<int>(index);
    ListView_SetItemState(list_, -1, 0, LVIS_SELECTED);
    ListView_SetItemState(list_, row, LVIS_SELECTED | LVIS_FOCUSED, LVIS_SELECTED | LVIS_FOCUSED);
    ListView_EnsureVisible(list_, row, FALSE);
    SetFocus(list_);
    // chosen by the app, not clicked through: followed at once
    FlushSelection();
    return true;
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
    const std::wstring& target = unsubscribeTarget_;
    switch (unsubscribeKind_) {
    case PE_UNSUBSCRIBE_ONE_CLICK: {
        std::wstring question = core::T(PE_TEXT_WIN_LEAVE_LIST) + L"\n\n" + core::T(PE_TEXT_WIN_LEAVE_ONE_CLICK, {{"target", target}});
        if (MessageBoxW(parent_, question.c_str(), core::T(PE_TEXT_WIN_UNSUBSCRIBE).c_str(), MB_YESNO | MB_ICONQUESTION) != IDYES) {
            return L"";
        }
        unsubscribeRequest_ = pe_unsubscribe(core_, messageFolder_, uid_);
        return unsubscribeRequest_ ? core::T(PE_TEXT_WIN_UNSUBSCRIBING, {{"target", target}}) : core::T(PE_TEXT_WIN_CANNOT_UNSUBSCRIBE);
    }
    case PE_UNSUBSCRIBE_MAIL: {
        std::wstring question = core::T(PE_TEXT_WIN_LEAVE_LIST) + L"\n\n" + core::T(PE_TEXT_WIN_LEAVE_MAIL, {{"target", target}});
        if (MessageBoxW(parent_, question.c_str(), core::T(PE_TEXT_WIN_UNSUBSCRIBE).c_str(), MB_OKCANCEL | MB_ICONQUESTION) == IDOK) {
            mailto = unsubscribeLink_;
        }
        return L"";
    }
    case PE_UNSUBSCRIBE_WEB: {
        std::wstring question = core::T(PE_TEXT_WIN_LEAVE_LIST) + L"\n\n" + core::T(PE_TEXT_WIN_LEAVE_WEB, {{"target", target}});
        if (MessageBoxW(parent_, question.c_str(), core::T(PE_TEXT_WIN_UNSUBSCRIBE).c_str(), MB_OKCANCEL | MB_ICONQUESTION) == IDOK) {
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
    return problem.empty() ? core::T(PE_TEXT_WIN_UNSUBSCRIBED) : core::T(PE_TEXT_WIN_NOT_UNSUBSCRIBED, {{"reason", problem}});
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
        return hasEnd && !SameDay(start, end) ? core::T(PE_TEXT_WIN_EVENT_SPAN, {{"start", LongDate(start)}, {"end", LongDate(end)}})
                                              : LongDate(start);
    }
    std::wstring when = LongDate(start) + L", " + FormatTime(start);
    if (hasEnd) {
        std::wstring until = SameDay(start, end) ? FormatTime(end) : LongDate(end) + L", " + FormatTime(end);
        when = core::T(PE_TEXT_WIN_EVENT_SPAN, {{"start", when}, {"end", until}});
    }
    return event.floating ? core::T(PE_TEXT_WIN_EVENT_FLOATING, {{"when", when}}) : when;
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
    PeText kinds[] = {PE_TEXT_WIN_INVITATION, PE_TEXT_WIN_INVITATION_UPDATED, PE_TEXT_WIN_INVITATION_CANCELED,
                      PE_TEXT_WIN_INVITATION_ANSWER};
    std::wstring summary = Text(event->summary);
    invitationTitle_ = core::T(kinds[std::clamp(static_cast<int>(event->kind), 0, 3)],
                               {{"title", summary.empty() ? core::T(PE_TEXT_WIN_NO_TITLE) : summary}});
    std::vector<std::wstring> parts = {When(*event), Text(event->location)};
    if (std::wstring organizer = Text(event->organizer); !organizer.empty()) {
        parts.push_back(core::T(PE_TEXT_WIN_ORGANIZER, {{"name", organizer}}));
    }
    parts.push_back(Text(event->repeats));
    if (event->attendees > 0) {
        parts.push_back(core::T(PE_TEXT_WIN_ATTENDEES, {{"count", std::to_wstring(event->attendees)}}));
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
        MessageBoxW(parent_, core::T(PE_TEXT_WIN_INVITATION_NOT_READ).c_str(), L"Inbox Classic", MB_OK | MB_ICONERROR);
        return;
    }
    // marked as from the internet by the core, which wrote it
    std::wstring file = Text(path.get());
    if (reinterpret_cast<INT_PTR>(ShellExecuteW(parent_, L"open", file.c_str(), nullptr, nullptr, SW_SHOWNORMAL)) <= 32) {
        MessageBoxW(parent_, core::T(PE_TEXT_WIN_NO_CALENDAR).c_str(), L"Inbox Classic", MB_OK | MB_ICONINFORMATION);
    }
}

void Mailbox::MarkJunk(bool junk) {
    Act(junk ? PE_ACTION_JUNK : PE_ACTION_NOT_JUNK);
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
    // what takes the place of rows that leave the list: the row after the last of them
    bool leaves = action == PE_ACTION_DELETE || action == PE_ACTION_MOVE || action == PE_ACTION_JUNK || action == PE_ACTION_NOT_JUNK;
    int after = leaves ? RowAfterSelection() : -1;
    char* reason = nullptr;
    core::String done(pe_selection_act(core_, selection_.get(), action, to, &reason));
    Say(done ? Text(done.get()) : ReasonText(reason, PE_TEXT_WIN_MESSAGES_NOT_CHANGED));
    if (done && leaves) {
        SelectAfterRemoval(after);
    }
    return done != nullptr;
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
    if (index >= 0 && total_ > 0) {
        int next = std::min(index, static_cast<int>(std::min<uint64_t>(total_, INT_MAX)) - 1);
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
    pick.verb = core::T(copy ? PE_TEXT_WIN_COPY_BUTTON : PE_TEXT_WIN_MOVE_BUTTON);
    // the folder they are all in is shown but not offered; from several folders, any
    pick.current = summary_.folders == 1 ? first : 0;
    pick.newFolder = [this](HWND window, int64_t account, int64_t parent) {
        std::wstring where = core::T(parent ? PE_TEXT_WIN_NEW_FOLDER_IN_HIGHLIGHTED : PE_TEXT_WIN_NEW_FOLDER_AT_TOP);
        std::wstring name = AskFolderName(window, PE_TEXT_CMD_NEW_FOLDER, where, L"");
        if (name.empty()) {
            return;
        }
        char* reason = nullptr;
        if (!pe_folder_create(core_, account, parent, core::Narrow(name).c_str(), &reason)) {
            ShowRefusal(window, reason, PE_TEXT_WIN_FOLDER_NOT_CREATED);
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
    AppendMenuW(menu, MF_STRING, IDM_FLAG_CLEAR, MenuItem(PE_TEXT_WIN_CLEAR_FLAG).c_str());
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
    }
    TrackPopupMenu(menu, TPM_RIGHTBUTTON, screen.x, screen.y, 0, parent_, nullptr);
    DestroyMenu(menu);
}

std::wstring Mailbox::SelectedName() const {
    if (Searching()) {
        // where the search looks; what it found is on the search bar
        return findPlace_.empty() ? core::T(PE_TEXT_WIN_ALL_FOLDERS) : findPlace_;
    }
    if (allInboxes_) {
        return AllInboxes();
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
        title = core::T(PE_TEXT_WIN_NO_MATCH, {{"words", find_}});
        more = findPlace_.empty() ? core::T(PE_TEXT_WIN_NO_MATCH_ALL) : core::T(PE_TEXT_WIN_NO_MATCH_IN, {{"folder", findPlace_}});
        if (uint64_t left = pe_search_unindexed_count(core_)) {
            more += L"\n\n" + core::T(PE_TEXT_WIN_NO_MATCH_INDEXING, {{"count", std::to_wstring(left)}});
        }
    } else if (folder_ || allInboxes_) {
        title = core::T(PE_TEXT_WIN_NO_ITEMS);
    } else if (selectedAccount_) {
        title = core::T(PE_TEXT_WIN_CHOOSE_FOLDER);
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
    std::wstring where = core::T(folder_ ? PE_TEXT_WIN_NEW_FOLDER_IN_SELECTED : PE_TEXT_WIN_NEW_FOLDER_AT_TOP);
    std::wstring name = AskFolderName(owner, PE_TEXT_CMD_NEW_FOLDER, where, L"");
    if (name.empty()) {
        return;
    }
    char* reason = nullptr;
    if (!pe_folder_create(core_, account, folder_, core::Narrow(name).c_str(), &reason)) {
        ShowRefusal(owner, reason, PE_TEXT_WIN_FOLDER_NOT_CREATED);
    }
}

void Mailbox::RenameFolder(HWND owner) {
    if (!folder_) {
        return;
    }
    std::wstring current;
    bool fixed = false;
    FolderOf(folder_, current, fixed);
    std::wstring name = AskFolderName(owner, PE_TEXT_CMD_RENAME_FOLDER, core::T(PE_TEXT_WIN_RENAME_FOLDER_INTRO, {{"folder", current}}), current);
    if (name.empty() || name == current) {
        return;
    }
    char* reason = nullptr;
    if (!pe_folder_rename(core_, folder_, core::Narrow(name).c_str(), &reason)) {
        ShowRefusal(owner, reason, PE_TEXT_WIN_FOLDER_NOT_RENAMED);
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
        ShowRefusal(owner, reason, PE_TEXT_WIN_FOLDER_NOT_DELETED);
    }
}

std::wstring Mailbox::Counts() const {
    if (!Searching() && !folder_ && !allInboxes_) {
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
            LPARAM item = change->itemNew.hItem ? change->itemNew.lParam : 0;
            bool allInboxes = item == kAllInboxesItem;
            // an account has no messages of its own
            selectedAccount_ = item < 0 && !allInboxes ? -item : 0;
            // the folder bar and the title name what is selected: an account too, from another account's item
            if (!OnFolderSelected(item > 0 ? item : 0, allInboxes)) {
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
            ScheduleSelection();
        }
        return true;
    case LVN_ODSTATECHANGED:
        // a range of rows selected at once (Shift+click) in the list of owner data
        if (!reloading_) {
            ScheduleSelection();
        }
        return true;
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
    std::wstring dir = FolderDialog(owner, core::Plain(PE_TEXT_WIN_SAVE_MESSAGES_IN).c_str());
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
    if (!uid_) {
        return;
    }
    size_t length = 0;
    char* name = nullptr;
    uint8_t* data = pe_message_source(core_, messageFolder_, uid_, &length, &name);
    core::String safeName(name);
    if (!data) {
        MessageBoxW(owner, core::T(PE_TEXT_WIN_NOT_DOWNLOADED).c_str(), L"Inbox Classic", MB_OK | MB_ICONINFORMATION);
        return;
    }
    std::wstring filter = FileFilter({{core::T(PE_TEXT_WIN_FILTER_MESSAGES), L"*.eml"}, {core::T(PE_TEXT_WIN_FILTER_ALL), L"*.*"}});
    std::wstring path = SaveFileDialog(owner, Text(safeName.get()), core::Plain(PE_TEXT_WIN_SAVE_MESSAGE_AS).c_str(), filter.c_str(), L"eml");
    if (!path.empty()) {
        if (WriteFileBytes(path, data, length)) {
            MarkFromInternet(path);
        } else {
            MessageBoxW(owner, core::T(PE_TEXT_WIN_NOT_SAVED).c_str(), L"Inbox Classic", MB_OK | MB_ICONERROR);
        }
    }
    pe_bytes_free(data, length);
}

void Mailbox::ShowProperties(HWND owner) {
    if (!uid_) {
        MessageBoxW(owner, core::T(PE_TEXT_WIN_SELECT_MESSAGE_FIRST).c_str(), L"Inbox Classic", MB_OK | MB_ICONINFORMATION);
        return;
    }
    core::String headers(pe_message_headers(core_, messageFolder_, uid_));
    if (!headers) {
        MessageBoxW(owner, core::T(PE_TEXT_WIN_NOT_DOWNLOADED).c_str(), L"Inbox Classic", MB_OK | MB_ICONINFORMATION);
        return;
    }
    const PeMessageInfo* info = pe_message_view_info(view_.get());
    std::wstring subject = info ? Text(info->subject) : L"";
    TextDialog(owner, subject.empty() ? core::Plain(PE_TEXT_CMD_PROPERTIES) : core::T(PE_TEXT_WIN_PROPERTIES_OF, {{"subject", subject}}),
               core::T(PE_TEXT_WIN_INTERNET_HEADERS), Text(headers.get()));
}

void Mailbox::ShowSource(HWND owner) {
    if (!uid_) {
        MessageBoxW(owner, core::T(PE_TEXT_WIN_SELECT_MESSAGE_FIRST).c_str(), L"Inbox Classic", MB_OK | MB_ICONINFORMATION);
        return;
    }
    char* title = nullptr;
    core::String text(pe_message_source_text(core_, messageFolder_, uid_, &title));
    core::String titleText(title);
    if (!text) {
        MessageBoxW(owner, core::T(PE_TEXT_WIN_NOT_DOWNLOADED).c_str(), L"Inbox Classic", MB_OK | MB_ICONINFORMATION);
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
        AppendMenuW(menu, MF_STRING, IDOK, MenuItem(PE_TEXT_WIN_OPEN).c_str());
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
    AppendMenuW(menu, MF_POPUP, reinterpret_cast<UINT_PTR>(FlagMenu()), MenuItem(PE_TEXT_WIN_FLAG_MENU).c_str());
    bool junk = summary_.in_junk;
    AppendMenuW(menu, MF_STRING, junk ? IDM_NOT_JUNK : IDM_JUNK, MenuItem(junk ? PE_TEXT_CMD_NOT_JUNK : PE_TEXT_CMD_JUNK).c_str());
    AppendMenuW(menu, MF_STRING, IDM_MOVE, MenuItem(PE_TEXT_CMD_MOVE).c_str());
    AppendMenuW(menu, MF_STRING, IDM_COPY, MenuItem(PE_TEXT_CMD_COPY).c_str());
    AppendMenuW(menu, MF_STRING, IDM_DELETE, MenuItem(PE_TEXT_WIN_DELETE_BUTTON).c_str());
    AppendMenuW(menu, MF_SEPARATOR, 0, nullptr);
    AppendMenuW(menu, MF_STRING, IDM_SAVE_AS, MenuItem(PE_TEXT_WIN_SAVE_AS_BUTTON).c_str());
    AppendMenuW(menu, MF_STRING, IDM_PRINT, MenuItem(PE_TEXT_CMD_PRINT).c_str());
    AppendMenuW(menu, MF_SEPARATOR, 0, nullptr);
    AppendMenuW(menu, MF_STRING, IDM_VIEW_SOURCE, MenuItem(PE_TEXT_WIN_VIEW_SOURCE).c_str());
    AppendMenuW(menu, MF_STRING, IDM_PROPERTIES, MenuItem(PE_TEXT_WIN_PROPERTIES).c_str());
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
        MessageBoxW(owner, core::T(PE_TEXT_WIN_IMPORT_CHOOSE_FOLDER).c_str(), core::Plain(PE_TEXT_CMD_IMPORT).c_str(), MB_OK | MB_ICONINFORMATION);
        return;
    }
    std::vector<std::wstring> files = OpenFilesDialog(owner, core::Plain(PE_TEXT_CMD_IMPORT).c_str(),
        FileFilter({{core::T(PE_TEXT_WIN_FILTER_MESSAGES), L"*.eml"}, {core::T(PE_TEXT_WIN_FILTER_ALL), L"*.*"}}).c_str());
    if (!files.empty()) {
        ImportFiles(folder_, files, owner);
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
    TVITEMW item = {};
    item.mask = TVIF_PARAM;
    item.hItem = over;
    TreeView_GetItem(tree_, &item);
    // an account's own item (its id negated), All Inboxes, the folder they are all in, or one that holds no messages:
    // not there. A folder of another account takes them too, the core moves them across
    int64_t folder = static_cast<int64_t>(item.lParam);
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
        MessageBoxW(owner, Text(told.get()).c_str(), core::Plain(PE_TEXT_CMD_IMPORT).c_str(), MB_OK | MB_ICONWARNING);
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
        // read after a moment on screen: no word of it in the status bar
        pe_message_set_seen(core_, messageFolder_, uid_, true);
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
