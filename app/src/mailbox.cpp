// The folder tree, the message list and the reading pane. The list is virtual: rows come from the core a page at a
// time when the list view asks for them. Every string shown was decoded by the core; the message body is the
// sanitized document the core made, shown in the WebView2 as it is.
#include "app.h"

#include <algorithm>

namespace {

constexpr uint64_t kPageSize = 100;
// pages kept around while the list scrolls
constexpr size_t kPagesKept = 8;
constexpr int kHeaderLines = 4;

enum Column { COL_MARKS, COL_FROM, COL_SUBJECT, COL_RECEIVED, COL_SIZE };

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

HTREEITEM InsertItem(HWND tree, HTREEITEM parent, const std::wstring& text, LPARAM data, bool bold) {
    TVINSERTSTRUCTW insert = {};
    insert.hParent = parent;
    insert.hInsertAfter = TVI_LAST;
    insert.item.mask = TVIF_TEXT | TVIF_PARAM | TVIF_STATE;
    insert.item.pszText = const_cast<wchar_t*>(text.c_str());
    insert.item.lParam = data;
    insert.item.stateMask = TVIS_BOLD;
    insert.item.state = bold ? TVIS_BOLD : 0;
    return TreeView_InsertItem(tree, &insert);
}

void AddColumn(HWND list, int index, const wchar_t* name, int width, int format = LVCFMT_LEFT) {
    LVCOLUMNW column = {};
    column.mask = LVCF_TEXT | LVCF_WIDTH | LVCF_FMT;
    column.fmt = format;
    column.pszText = const_cast<wchar_t*>(name);
    column.cx = Scale(width);
    ListView_InsertColumn(list, index, &column);
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
    AddColumn(list_, COL_MARKS, L"!", 28);
    AddColumn(list_, COL_FROM, L"From", 180);
    AddColumn(list_, COL_SUBJECT, L"Subject", 320);
    AddColumn(list_, COL_RECEIVED, L"Received", 130);
    AddColumn(list_, COL_SIZE, L"Size", 70, LVCFMT_RIGHT);

    header_ = CreateChild(parent, L"STATIC", L"", SS_LEFT | SS_NOPREFIX | SS_SUNKEN, 0, {});
    attachments_ = CreateChild(parent, L"BUTTON", L"", WS_TABSTOP, IDC_ATTACHMENTS, {});
    pictures_ = CreateChild(parent, L"BUTTON", L"Download pictures", WS_TABSTOP, IDC_PICTURES, {});
    ShowWindow(attachments_, SW_HIDE);
    ShowWindow(pictures_, SW_HIDE);
    previewHost_ = CreateChild(parent, L"STATIC", nullptr, SS_SUNKEN | WS_CLIPCHILDREN, 0, {});
    preview_.Create(previewHost_, [this](const std::wstring& error) { SetWindowTextW(previewHost_, error.c_str()); });

    LOGFONTW font = {};
    GetObjectW(GetStockObject(DEFAULT_GUI_FONT), sizeof(font), &font);
    font.lfWeight = FW_BOLD;
    bold_ = CreateFontIndirectW(&font);
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
    int headerHeight = kHeaderLines * Scale(15) + Scale(8);
    int buttonWidth = Scale(130);
    int width = reader.right - reader.left;
    MoveWindow(header_, reader.left, reader.top, width - buttonWidth - Scale(4), headerHeight, TRUE);
    int x = reader.right - buttonWidth;
    MoveWindow(attachments_, x, reader.top, buttonWidth, Scale(24), TRUE);
    MoveWindow(pictures_, x, reader.top + Scale(28), buttonWidth, Scale(24), TRUE);
    int top = reader.top + headerHeight + Scale(4);
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
    core::AccountList accounts(pe_accounts(core_));
    size_t count = pe_account_list_count(accounts.get());
    for (size_t i = 0; i < count; i++) {
        const PeAccount* account = pe_account_list_get(accounts.get(), i);
        accountNames_[account->id] = Text(account->name);
        HTREEITEM root = InsertItem(tree_, TVI_ROOT, Text(account->name), 0, false);
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
        HTREEITEM item = InsertItem(tree_, parents[depth], FolderLabel(*folder), static_cast<LPARAM>(folder->id), folder->unread > 0);
        items_[folder->id] = item;
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

// ---- the message list ----

void Mailbox::ReloadList(bool keepSelection) {
    pages_.clear();
    total_ = 0;
    unread_ = 0;
    if (folder_) {
        pe_folder_counts(core_, folder_, &total_, &unread_);
    }
    // the selection follows the message to where it is now, without a flicker of the reading pane
    int64_t index = keepSelection && uid_ ? pe_message_index(core_, folder_, sort_, ascending_, uid_) : -1;
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
        pages_.push_back({offset, core::MessageList(pe_messages(core_, folder_, sort_, ascending_, offset, kPageSize))});
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
    if (!(info->item.mask & LVIF_TEXT)) {
        return;
    }
    const PeMessage* row = Row(info->item.iItem);
    cell_.clear();
    if (row) {
        switch (info->item.iSubItem) {
        case COL_MARKS:
            // ! for flagged, @ for attachments, until the list has icons
            cell_ = std::wstring(row->flagged ? L"!" : L"") + (row->has_attachments ? L"@" : L"");
            break;
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
    if (draw->nmcd.dwDrawStage == CDDS_PREPAINT) {
        result = CDRF_NOTIFYITEMDRAW;
    } else if (draw->nmcd.dwDrawStage == CDDS_ITEMPREPAINT) {
        // unread messages in bold, as Outlook Express shows them
        const PeMessage* row = Row(static_cast<int>(draw->nmcd.dwItemSpec));
        if (row && !row->seen) {
            SelectObject(draw->nmcd.hdc, bold_);
            result = CDRF_NEWFONT;
        }
    }
}

// ---- the reading pane ----

void Mailbox::ClearReader() {
    uid_ = 0;
    remoteImages_ = false;
    view_.reset();
    KillTimer(parent_, TIMER_MARK_READ);
    ShowWindow(attachments_, SW_HIDE);
    ShowWindow(pictures_, SW_HIDE);
    SetWindowTextW(header_, L"");
    preview_.Clear();
}

void Mailbox::OnSelectionChanged() {
    const PeMessage* row = SelectedRow();
    uint64_t uid = row ? row->uid : 0;
    if (uid == uid_) {
        return;
    }
    ClearReader();
    if (!uid) {
        return;
    }
    uid_ = uid;
    SetWindowTextW(header_, L" Loading the message...");
    // MessageReady follows, right away when the message is cached
    pe_message_open(core_, folder_, uid);
}

void Mailbox::OnFolderSelected(LPARAM folder) {
    if (folder == folder_) {
        return;
    }
    // the message of the folder before is not this folder's
    folder_ = folder;
    ClearReader();
    ReloadList(false);
    SendMessageW(parent_, WM_COMMAND, MAKEWPARAM(IDC_TREE, 0), 0);
}

void Mailbox::ShowMessage() {
    view_.reset(pe_message_view(core_, folder_, uid_, remoteImages_));
    const PeMessageInfo* info = pe_message_view_info(view_.get());
    if (!info) {
        SetWindowTextW(header_, L" The message could not be shown.");
        return;
    }
    ShowHeader(info);
    preview_.Show(Text(info->document), remoteImages_);
    ShowWindow(pictures_, remoteImages_ ? SW_HIDE : SW_SHOW);
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
        std::wstring label = L"Attachments (" + std::to_wstring(info->attachment_count) + L")";
        SetWindowTextW(attachments_, label.c_str());
        ShowWindow(attachments_, SW_SHOW);
    }
}

void Mailbox::ChooseAttachment() {
    const PeMessageInfo* info = pe_message_view_info(view_.get());
    if (!info) {
        return;
    }
    HMENU menu = CreatePopupMenu();
    for (size_t i = 0; i < info->attachment_count; i++) {
        const PeAttachment* attachment = pe_message_view_attachment(view_.get(), i);
        if (!attachment) {
            continue;
        }
        std::wstring label = L"Save " + Text(attachment->filename) + L" (" + FormatSize(attachment->size) + L")...";
        // & would make the next character a shortcut
        for (size_t at = label.find(L'&'); at != std::wstring::npos; at = label.find(L'&', at + 2)) {
            label.insert(at, 1, L'&');
        }
        AppendMenuW(menu, MF_STRING, 1 + i, label.c_str());
    }
    RECT button;
    GetWindowRect(attachments_, &button);
    int chosen = TrackPopupMenu(menu, TPM_RETURNCMD | TPM_RIGHTALIGN | TPM_TOPALIGN, button.right, button.bottom, 0, parent_, nullptr);
    DestroyMenu(menu);
    if (chosen <= 0) {
        return;
    }
    size_t length = 0;
    char* name = nullptr;
    uint8_t* data = pe_attachment_data(core_, folder_, uid_, static_cast<size_t>(chosen - 1), &length, &name);
    core::String safeName(name);
    if (!data) {
        MessageBoxW(parent_, L"The attachment could not be read.", L"PostalExpress", MB_OK | MB_ICONERROR);
        return;
    }
    std::wstring path = SaveFileDialog(parent_, Text(safeName.get()));
    if (!path.empty() && !WriteFileBytes(path, data, length)) {
        MessageBoxW(parent_, L"The attachment could not be saved.", L"PostalExpress", MB_OK | MB_ICONERROR);
    }
    pe_bytes_free(data, length);
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

std::wstring Mailbox::Counts() const {
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
            // an account has no messages of its own
            OnFolderSelected(change->itemNew.hItem ? change->itemNew.lParam : 0);
        }
        return header->code == TVN_SELCHANGEDW;
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

bool Mailbox::OnCommand(WORD id) {
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
    default:
        break;
    }
}
