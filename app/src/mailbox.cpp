// The folder tree, the message list and the reading pane. The list is virtual: rows come from the core a page at a
// time when the list view asks for them. Every string shown was decoded by the core; the message body is the
// sanitized document the core made, shown in the WebView2 as it is.
#include "app.h"
#include "icons.h"

#include <commdlg.h>

#include <algorithm>
#include <utility>

namespace {

constexpr uint64_t kPageSize = 100;
// pages kept around while the list scrolls
constexpr size_t kPagesKept = 8;
constexpr int kHeaderLines = 4;

// as Outlook Express has them: the envelope (read or not), the paper clip and the flag, then the text columns
enum Column { COL_READ, COL_ATTACH, COL_FLAG, COL_FROM, COL_SUBJECT, COL_RECEIVED, COL_SIZE };

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

std::wstring FolderLabel(const PeFolder& folder) {
    std::wstring label = FolderName(folder);
    if (folder.unread > 0) {
        label += L" (" + std::to_wstring(folder.unread) + L")";
    }
    return label;
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
    findLabel_ = CreateChild(parent, L"STATIC", L"Find:", SS_RIGHT | SS_CENTERIMAGE, 0, {});
    findEdit_ = CreateChild(parent, L"EDIT", L"", WS_TABSTOP | ES_AUTOHSCROLL, IDC_FIND, {}, WS_EX_CLIENTEDGE);
    AddColumn(list_, COL_READ, L"", 24);
    IconColumn(list_, COL_ATTACH, LIST_ATTACH);
    IconColumn(list_, COL_FLAG, LIST_FLAG);
    AddColumn(list_, COL_FROM, L"From", 180);
    AddColumn(list_, COL_SUBJECT, L"Subject", 320);
    AddColumn(list_, COL_RECEIVED, L"Received", 130);
    AddColumn(list_, COL_SIZE, L"Size", 84, LVCFMT_RIGHT);

    header_ = CreateChild(parent, L"STATIC", L"", SS_LEFT | SS_NOPREFIX | SS_SUNKEN, 0, {});
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
    previewHost_ = CreateChild(parent, L"STATIC", nullptr, SS_SUNKEN | WS_CLIPCHILDREN, 0, {});
    preview_.Create(previewHost_, [this](const std::wstring& error) { SetWindowTextW(previewHost_, error.c_str()); });

    LOGFONTW font = {};
    GetObjectW(GetStockObject(DEFAULT_GUI_FONT), sizeof(font), &font);
    font.lfWeight = FW_BOLD;
    bold_ = CreateFontIndirectW(&font);
    ClearReader();
    Reload();
}

void Mailbox::Destroy() {
    preview_.Close();
    view_.reset();
    pages_.clear();
    DeleteObject(bold_);
    bold_ = nullptr;
}

void Mailbox::Layout(const RECT& tree, const RECT& list, const RECT& reader) {
    MoveWindow(tree_, tree.left, tree.top, tree.right - tree.left, tree.bottom - tree.top, TRUE);
    MoveWindow(list_, list.left, list.top, list.right - list.left, list.bottom - list.top, TRUE);
    reader_ = reader;
    LayoutReader();
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

bool Mailbox::OnSetCursor(HWND window) {
    if (window != pictures_) {
        return false;
    }
    // the information bar is clicked like a link
    SetCursor(LoadCursorW(nullptr, IDC_HAND));
    return true;
}

bool Mailbox::OnCtlColor(HWND window, HDC dc, LRESULT& brush) {
    if (window != pictures_) {
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
    // the header to the paper clip, which is as wide as its button
    int clipWidth = files ? static_cast<int>(button.right - button.left) + Scale(8) : 0;
    MoveWindow(header_, reader.left, reader.top, width - clipWidth, headerHeight, TRUE);
    if (files) {
        int buttonHeight = button.bottom - button.top;
        MoveWindow(attachments_, reader.right - clipWidth, reader.top + std::max(0, (headerHeight - buttonHeight) / 2), clipWidth, buttonHeight,
                   TRUE);
    }
    int top = reader.top + headerHeight + Scale(2);
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
    accountNames_.clear();
    folderAccounts_.clear();
    folderNames_.clear();
    draftFolders_.clear();
    firstAccount_ = 0;
    core::AccountList accounts(pe_accounts(core_));
    size_t count = pe_account_list_count(accounts.get());
    for (size_t i = 0; i < count; i++) {
        const PeAccount* account = pe_account_list_get(accounts.get(), i);
        accountNames_[account->id] = Text(account->name);
        accountEmails_[account->id] = Text(account->email);
        accountOAuth_[account->id] = account->oauth;
        if (!firstAccount_) {
            firstAccount_ = account->id;
        }
        // an account's own item carries its id negated, so selecting it tells which account it is
        HTREEITEM root = InsertItem(tree_, TVI_ROOT, Text(account->title), static_cast<LPARAM>(-account->id), false, FOLDER_MAILBOX);
        FillAccount(root, account->id);
        TreeView_Expand(tree_, root, TVE_EXPAND);
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
        HTREEITEM item = InsertItem(tree_, parents[depth], FolderLabel(*folder), static_cast<LPARAM>(folder->id), folder->unread > 0,
                                       IconOfFolder(folder->special_use));
        items_[folder->id] = item;
        folderAccounts_[folder->id] = account;
        folderNames_[folder->id] = {FolderName(*folder), folder->fixed};
        if (folder->special_use == PE_SPECIAL_USE_DRAFTS) {
            draftFolders_.insert(folder->id);
        }
        parents.resize(depth + 1);
        parents.push_back(item);
    }
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
        std::wstring label = FolderLabel(*folder);
        TVITEMW update = {};
        update.mask = TVIF_TEXT | TVIF_STATE;
        update.hItem = item->second;
        update.pszText = label.data();
        update.stateMask = TVIS_BOLD;
        update.state = folder->unread > 0 ? TVIS_BOLD : 0;
        TreeView_SetItem(tree_, &update);
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

PeOAuthProvider Mailbox::OAuthProvider(int64_t account) const {
    auto oauth = accountOAuth_.find(account);
    return oauth != accountOAuth_.end() ? oauth->second : PE_O_AUTH_PROVIDER_NONE;
}

int64_t Mailbox::CurrentAccount() const {
    auto account = folderAccounts_.find(folder_);
    if (account != folderAccounts_.end()) {
        return account->second;
    }
    return selectedAccount_ ? selectedAccount_ : firstAccount_;
}

void Mailbox::OpenSelected() {
    if (!uid_ || !draftFolders_.contains(folder_)) {
        return;
    }
    core::Draft draft(pe_draft_open(core_, folder_, uid_));
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
    return core::Draft(pe_message_draft(core_, folder_, uid_, kind));
}

// ---- the message list ----

void Mailbox::ReloadList(bool keepSelection) {
    pages_.clear();
    total_ = 0;
    unread_ = 0;
    folderTotal_ = 0;
    if (folder_) {
        pe_folder_counts(core_, folder_, &total_, &unread_);
        folderTotal_ = total_;
        // the counts of the folder come from its indexes; a search counts what it finds
        if (!find_.empty()) {
            pe_message_count(core_, folder_, findUtf8_.c_str(), &total_, &unread_);
        }
    }
    // the selection follows the message to where it is now, without a flicker of the reading pane
    int64_t index = keepSelection && uid_ ? pe_message_index(core_, folder_, sort_, ascending_, findUtf8_.c_str(), uid_) : -1;
    reloading_ = true;
    ListView_SetItemCountEx(list_, static_cast<int>(std::min<uint64_t>(total_, INT_MAX)), LVSICF_NOSCROLL);
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
        pages_.push_back({offset, core::MessageList(pe_messages(core_, folder_, sort_, ascending_, findUtf8_.c_str(), offset, kPageSize))});
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
        }
    }
    info->item.pszText = cell_.data();
}

void Mailbox::CustomDraw(NMLVCUSTOMDRAW* draw, LRESULT& result) {
    result = CDRF_DODEFAULT;
    int index = static_cast<int>(draw->nmcd.dwItemSpec);
    if (draw->nmcd.dwDrawStage == CDDS_PREPAINT) {
        result = CDRF_NOTIFYITEMDRAW;
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

void Mailbox::ClearReader(bool loading) {
    if (viewRequest_) {
        pe_message_view_cancel(core_, viewRequest_);
        viewRequest_ = 0;
    }
    uid_ = 0;
    openWhenReady_ = false;
    remoteImages_ = false;
    view_.reset();
    KillTimer(parent_, TIMER_MARK_READ);
    // the bars of the message before stay while the next one loads, and go when it is there without them: the
    // message does not jump down and up again
    if (!loading) {
        ShowReaderBars(false, false);
    }
    SetWindowTextW(header_, L"");
    // says so rather than a blank pane, unless a message is about to be shown
    preview_.Clear(!loading);
}

void Mailbox::OnSelectionChanged() {
    const PeMessage* row = SelectedRow();
    uint64_t uid = row ? row->uid : 0;
    if (uid == uid_) {
        return;
    }
    ClearReader(uid != 0);
    if (!uid) {
        return;
    }
    uid_ = uid;
    SetWindowTextW(header_, L" Loading the message...");
    // MessageReady follows, right away when the message is cached
    pe_message_open(core_, folder_, uid);
}

bool Mailbox::OnFolderSelected(LPARAM folder) {
    if (folder == folder_) {
        return false;
    }
    // the message of the folder before is not this folder's, nor is the search
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
    viewRequest_ = pe_message_view_start(core_, folder_, uid_, remoteImages_);
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
    preview_.Show(Text(info->document), remoteImages_);
    // offered only for a message with pictures on the internet, until they are shown
    ShowReaderBars(info->attachment_count > 0, info->remote_images && !remoteImages_);
    // read after a moment on screen, not while the user moves through the list
    SetTimer(parent_, TIMER_MARK_READ, 1000, nullptr);
}

void Mailbox::ShowHeader(const PeMessageInfo* info) {
    std::wstring header = L" From:  " + Text(info->from) + L"\r\n Date:  " + (info->has_date ? FormatDate(info->date) : L"") +
                          L"\r\n To:  " + Text(info->to);
    if (info->cc && *info->cc) {
        header += L"    Cc:  " + Text(info->cc);
    }
    header += L"\r\n Subject:  " + Text(info->subject);
    SetWindowTextW(header_, header.c_str());
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
    uint8_t* data = pe_attachment_data(core_, folder_, uid_, static_cast<size_t>(chosen - 1), &length, &name);
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
    if (!pe_save_attachments(core_, folder_, uid_, dir.c_str(), &saved, &total)) {
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

void Mailbox::MarkSelected(bool seen) {
    if (uid_) {
        pe_message_set_seen(core_, folder_, uid_, seen);
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
    // from Deleted Items, or an account without one, it is gone for good: asked first, as Outlook Express does
    if (pe_folder_deletes_for_good(core_, folder_) &&
        MessageBoxW(parent_, L"This message will be deleted for good. Delete it?", L"Inbox Classic",
                    MB_YESNO | MB_ICONWARNING | MB_DEFBUTTON2) != IDYES) {
        return;
    }
    if (pe_message_delete(core_, folder_, uid)) {
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
    // the other folders of the account that hold messages
    std::vector<int64_t> ids;
    FormField field{L"Folder:", L"", FormField::Kind::Choice};
    core::FolderList folders(pe_folders(core_, CurrentAccount()));
    for (size_t i = 0; i < pe_folder_list_count(folders.get()); i++) {
        const PeFolder* folder = pe_folder_list_get(folders.get(), i);
        if (folder && folder->selectable && folder->id != folder_) {
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
    if (chosen >= 0 && static_cast<size_t>(chosen) < ids.size() && pe_message_move(core_, folder_, uid, ids[chosen])) {
        SelectAfterRemoval(index);
    }
}

void Mailbox::FlagSelected() {
    const PeMessage* row = SelectedRow();
    if (row) {
        pe_message_set_flagged(core_, folder_, row->uid, !row->flagged);
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
    if (auto found = folderNames_.find(folder_); found != folderNames_.end()) {
        return found->second.first;
    }
    if (auto found = accountNames_.find(selectedAccount_); found != accountNames_.end()) {
        return found->second;
    }
    return L"";
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
    if (!folder_) {
        return L"";
    }
    if (!find_.empty()) {
        return std::to_wstring(total_) + L" of " + std::to_wstring(folderTotal_) + L" found, " + std::to_wstring(unread_) + L" unread";
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
    uint8_t* data = pe_message_source(core_, folder_, uid_, &length, &name);
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
    core::String headers(pe_message_headers(core_, folder_, uid_));
    if (!headers) {
        MessageBoxW(owner, L"The message is not downloaded yet.", L"Inbox Classic", MB_OK | MB_ICONINFORMATION);
        return;
    }
    const PeMessageInfo* info = pe_message_view_info(view_.get());
    std::wstring subject = info ? Text(info->subject) : L"";
    TextDialog(owner, subject.empty() ? L"Properties" : subject + L" Properties", L"Internet headers for this message:", Text(headers.get()));
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
    int height = Scale(22);
    int width = Scale(220);
    int top = row.top + (row.bottom - row.top - height) / 2;
    MoveWindow(findEdit_, row.right - width - Scale(6), top, width, height, TRUE);
    MoveWindow(findLabel_, row.right - width - Scale(46), top, Scale(36), height, TRUE);
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
}

bool Mailbox::ClearFind() {
    if (find_.empty() && GetWindowTextLengthW(findEdit_) == 0) {
        return false;
    }
    ResetFind();
    ReloadList(true);
    SetFocus(list_);
    return true;
}

bool Mailbox::OnCommand(WORD id, WORD code) {
    if (id == IDC_FIND) {
        if (code == EN_CHANGE) {
            // a moment after the last key, not for each
            SetTimer(parent_, TIMER_FIND, 250, nullptr);
        }
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
    }
    return false;
}

void Mailbox::OnTimer(UINT_PTR id) {
    if (id == TIMER_FIND) {
        KillTimer(parent_, TIMER_FIND);
        std::wstring text = GetWindowString(findEdit_);
        // what only has spaces finds everything, as the core reads it
        size_t first = text.find_first_not_of(L" \t");
        text = first == std::wstring::npos ? L"" : text.substr(first, text.find_last_not_of(L" \t") - first + 1);
        if (text != find_) {
            find_ = text;
            findUtf8_ = core::Narrow(find_);
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
        if (event.folder == folder_) {
            ReloadList(true);
        }
        break;
    case PE_EVENT_KIND_MESSAGE_READY:
        if (event.folder == folder_ && event.uid == uid_) {
            ShowMessage();
        }
        break;
    case PE_EVENT_KIND_VIEW_READY:
        // a view for a message that is no longer selected was cancelled, its event is not this one
        if (viewRequest_ && event.uid == viewRequest_) {
            ShowView();
        }
        break;
    default:
        break;
    }
}
