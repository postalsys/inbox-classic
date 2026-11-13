// The reading pane (reader.h): the header, the bars under it and the message in the WebView2, for the main window and
// the message windows alike.
#include "app.h"
#include "icons.h"
#include "webview.h"

#include <shellapi.h>

#include <algorithm>
#include <vector>

namespace {

constexpr int kHeaderLines = 4;

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

// an instant as the reader's local time, or as written (floating: in no zone the invitation defines)
bool EventTime(int64_t seconds, bool floating, SYSTEMTIME& time) {
    return UnixToSystemTime(seconds, !floating, time);
}

std::wstring LongDate(const SYSTEMTIME& time) {
    wchar_t date[96] = L"";
    GetDateFormatEx(LOCALE_NAME_USER_DEFAULT, DATE_LONGDATE, &time, nullptr, date, 96, nullptr);
    return date;
}

}  // namespace

// the days and times of the event cards as the windows show dates: the user's long date and short time
static size_t FormatInstant(void*, int64_t seconds, bool floating, bool time, char* out, size_t capacity) {
    SYSTEMTIME at;
    if (!EventTime(seconds, floating, at)) {
        return 0;
    }
    std::string words = core::Narrow(time ? FormatTime(at) : LongDate(at));
    size_t length = std::min(words.size(), capacity);
    memcpy(out, words.data(), length);
    return length;
}

void SetInstantFormat() {
    pe_set_instant_format(FormatInstant, nullptr);
}

WORD ReadingKey(UINT key) {
    bool control = (GetKeyState(VK_CONTROL) & 0x8000) != 0;
    bool others = (GetKeyState(VK_SHIFT) & 0x8000) != 0 || (GetKeyState(VK_MENU) & 0x8000) != 0;
    if (others) {
        return 0;
    }
    if (!control) {
        return key == VK_F3 ? WORD{IDM_FIND_IN_MESSAGE} : WORD{0};
    }
    if (key == VK_OEM_PERIOD) {
        return IDM_NEXT_MESSAGE;
    }
    return key == VK_OEM_COMMA ? WORD{IDM_PREVIOUS_MESSAGE} : WORD{0};
}

namespace {

// the window under the message's WebView2: Tab into it (or SetFocus) gives the message the keyboard
LRESULT CALLBACK BodyHostProc(HWND hwnd, UINT message, WPARAM wParam, LPARAM lParam, UINT_PTR, DWORD_PTR data) {
    switch (message) {
    case WM_SETFOCUS: {
        auto* preview = reinterpret_cast<Preview*>(data);
        if (GetKeyState(VK_TAB) < 0) {
            preview->Focus(GetKeyState(VK_SHIFT) < 0 ? Preview::FocusFrom::End : Preview::FocusFrom::Start);
        } else {
            preview->Focus(Preview::FocusFrom::Program);
        }
        return 0;
    }
    case WM_NCDESTROY:
        RemoveWindowSubclass(hwnd, BodyHostProc, 0);
        break;
    }
    return DefSubclassProc(hwnd, message, wParam, lParam);
}

}  // namespace

void Reader::Create(HWND parent, PeCore* core) {
    parent_ = parent;
    core_ = core;
    // not drawn over the Unsubscribe link that lies on it
    header_ = CreateChild(parent, L"STATIC", L"", SS_LEFT | SS_NOPREFIX | SS_SUNKEN | WS_CLIPSIBLINGS, 0, {});
    unsubscribe_ = CreateChild(parent, L"STATIC", core::T(PE_TEXT_UI_UNSUBSCRIBE).c_str(), SS_NOTIFY | SS_RIGHT | SS_NOPREFIX, IDC_UNSUBSCRIBE, {});
    ShowWindow(unsubscribe_, SW_HIDE);
    logo_ = CreateChild(parent, L"STATIC", L"", SS_OWNERDRAW, IDC_LOGO, {});
    ShowWindow(logo_, SW_HIDE);
    // the paper clip at the right of the header, as Outlook Express has it: the files of the message in its menu
    attachments_ = CreateBar(parent, CCS_NODIVIDER | CCS_NOPARENTALIGN | CCS_NORESIZE, IDC_ATTACHMENTS, BarIcons::Big);
    // a label from the start, so the bar keeps a row for it under the icon ("2 files" once a message is shown)
    AddButton(attachments_, IDC_ATTACHMENTS, core::T(PE_TEXT_WIN_FILES, {{"count", L"1"}}).c_str(), BTNS_WHOLEDROPDOWN, ICON_ATTACH);
    // the information bar of Outlook Express over a message whose pictures on the internet are blocked; a click
    // shows them
    std::wstring blocked = L" " + core::T(PE_TEXT_UI_PICTURES_BLOCKED);
    pictures_ = CreateChild(parent, L"STATIC", blocked.c_str(),
                            SS_LEFT | SS_NOTIFY | SS_CENTERIMAGE | SS_NOPREFIX | SS_ENDELLIPSIS | WS_BORDER, IDC_PICTURES, {});
    // its drop-down arrow at its right end, as Outlook's bar has: the Always choices
    picturesMenu_ = CreateChild(parent, L"STATIC", L"", SS_OWNERDRAW | SS_NOTIFY | WS_BORDER, IDC_PICTURES_MENU, {});
    ShowWindow(attachments_, SW_HIDE);
    ShowWindow(pictures_, SW_HIDE);
    ShowWindow(picturesMenu_, SW_HIDE);
    // the same bar over a message that could not be downloaded: a click tries again
    core::String note(pe_retry_note());
    std::wstring retry = L" " + Text(note.get()) + L" " + core::T(PE_TEXT_WIN_CLICK_TO_RETRY);
    retry_ = CreateChild(parent, L"STATIC", retry.c_str(), SS_LEFT | SS_NOTIFY | SS_CENTERIMAGE | SS_NOPREFIX | SS_ENDELLIPSIS | WS_BORDER,
                         IDC_RETRY, {});
    ShowWindow(retry_, SW_HIDE);
    // the links of the pane: Tab reaches them, Enter clicks them
    for (HWND link : {unsubscribe_, pictures_, picturesMenu_, retry_}) {
        KeyboardLink(link);
    }
    // the message itself is a Tab stop too: its host hands the keyboard to the WebView2
    previewHost_ = CreateChild(parent, L"STATIC", nullptr, SS_SUNKEN | WS_CLIPCHILDREN | WS_TABSTOP, 0, {});
    SetWindowSubclass(previewHost_, BodyHostProc, 0, reinterpret_cast<DWORD_PTR>(&preview_));
    preview_.Create(previewHost_, [this](const std::wstring& error) { SetWindowTextW(previewHost_, error.c_str()); }, parent,
                    TIMER_FIND_SETTLED);
    preview_.SetLinks([this](const wchar_t* uri) { return FollowLink(uri); });

    LOGFONTW font = {};
    GetObjectW(GetStockObject(DEFAULT_GUI_FONT), sizeof(font), &font);
    font.lfUnderline = TRUE;
    link_ = CreateFontIndirectW(&font);
    SendMessageW(unsubscribe_, WM_SETFONT, reinterpret_cast<WPARAM>(link_), FALSE);
    font.lfUnderline = FALSE;
    font.lfWeight = FW_BOLD;
    bold_ = CreateFontIndirectW(&font);
}

void Reader::Destroy() {
    if (viewRequest_) {
        pe_message_view_cancel(core_, viewRequest_);
        viewRequest_ = 0;
    }
    if (logoBitmap_) {
        DeleteObject(logoBitmap_);
        logoBitmap_ = nullptr;
    }
    preview_.Close();
    view_.reset();
    DeleteObject(bold_);
    bold_ = nullptr;
    DeleteObject(link_);
    link_ = nullptr;
}

// the links of the document's own cards: the core says which link it is, the view has what it needs. The bounce
// card's message is selected after the WebView2's event, as selecting it shows another document in this view; the
// code card's Copy puts the code on the clipboard and says so. False for a link of the message (the browser opens it).
bool Reader::FollowLink(const wchar_t* uri) {
    switch (pe_reader_link(core::Narrow(uri).c_str())) {
    case PE_READER_LINK_BOUNCED_MESSAGE:
        PostMessageW(parent_, WM_COMMAND, MAKEWPARAM(IDC_BOUNCED_MESSAGE, 0), 0);
        return true;
    case PE_READER_LINK_OPEN_CALENDAR:
        OpenInCalendar();
        return true;
    case PE_READER_LINK_COPY_CODE:
        if (const PeMessageInfo* info = Info(); info && info->otp_code && *info->otp_code &&
                                                CopyText(parent_, core::Widen(info->otp_code)) && onFound) {
            onFound(core::T(PE_TEXT_UI_CODE_COPIED));
        }
        return true;
    default:
        return false;
    }
}

const PeMessageInfo* Reader::Info() const {
    return uid_ || !file_.empty() ? pe_message_view_info(view_.get()) : nullptr;
}

// the paper clip and the information bar shown or not, the pane laid out again only when that changes
void Reader::ShowBars(bool files, bool pictures) {
    bool changed = (IsWindowVisible(attachments_) != FALSE) != files || (IsWindowVisible(pictures_) != FALSE) != pictures;
    ShowWindow(attachments_, files ? SW_SHOW : SW_HIDE);
    ShowWindow(pictures_, pictures ? SW_SHOW : SW_HIDE);
    ShowWindow(picturesMenu_, pictures ? SW_SHOW : SW_HIDE);
    if (changed || files) {
        Layout();
    }
}

void Reader::ShowRetry(bool shown) {
    if ((IsWindowVisible(retry_) != FALSE) != shown) {
        ShowWindow(retry_, shown ? SW_SHOW : SW_HIDE);
        Layout();
    }
}

bool Reader::OnSetCursor(HWND window) const {
    if (window != pictures_ && window != picturesMenu_ && window != retry_ && window != unsubscribe_) {
        return false;
    }
    // the information bar is clicked like a link
    SetCursor(LoadCursorW(nullptr, IDC_HAND));
    return true;
}

bool Reader::OnCtlColor(HWND window, HDC dc, LRESULT& brush) const {
    if (window == unsubscribe_) {
        // a link on the header
        SetTextColor(dc, GetSysColor(COLOR_HOTLIGHT));
        SetBkColor(dc, GetSysColor(COLOR_BTNFACE));
        brush = reinterpret_cast<LRESULT>(GetSysColorBrush(COLOR_BTNFACE));
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

void Reader::Layout(const RECT& area) {
    area_ = area;
    Layout();
}

// the header, with the paper clip at its right when the message has files; the information bars under it; the
// message below
void Reader::Layout() {
    const RECT& reader = area_;
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
        int linkWidth = TextWidth(unsubscribe_, link_) + Scale(8), edge = GetSystemMetrics(SM_CXEDGE);
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
    if (IsWindowVisible(pictures_)) {
        int barHeight = Scale(22);
        // the arrow's border over the bar's right one
        int arrowWidth = Scale(22);
        MoveWindow(pictures_, reader.left, top, width - arrowWidth + 1, barHeight, TRUE);
        MoveWindow(picturesMenu_, reader.left + width - arrowWidth, top, arrowWidth, barHeight, TRUE);
        top += barHeight + Scale(2);
    }
    MoveWindow(previewHost_, reader.left, top, width, std::max(0L, reader.bottom - top), TRUE);
    RECT inner;
    GetClientRect(previewHost_, &inner);
    preview_.Resize(inner);
}

void Reader::Clear(bool loading) {
    if (viewRequest_) {
        pe_message_view_cancel(core_, viewRequest_);
        viewRequest_ = 0;
    }
    uid_ = 0;
    folder_ = 0;
    account_ = 0;
    remoteImages_ = false;
    file_.clear();
    view_.reset();
    KillTimer(parent_, TIMER_DOWNLOADING);
    ShowRetry(false);
    // the bars of the message before stay while the next one loads, and go when it is there without them: the
    // message does not jump down and up again
    if (!loading) {
        ShowBars(false, false);
    }
    SetWindowTextW(header_, L"");
    unsubscribeKind_ = PE_UNSUBSCRIBE_NONE;
    ShowWindow(unsubscribe_, SW_HIDE);
    ShowLogo(false);
    // says so rather than a blank pane, unless a message is about to be shown
    preview_.Clear(!loading);
}

void Reader::ShowPage(const std::wstring& html) {
    preview_.Show(html);
}

void Reader::Open(int64_t folder, uint64_t uid, int64_t account, const PeMessage* row) {
    uid_ = uid;
    folder_ = folder;
    account_ = account;
    // the header from the list at once; the pane says the message is being downloaded a moment later, should it not
    // be here yet
    if (row) {
        SetWindowTextW(header_, HeaderText(row->from, row->has_date, row->date, row->recipients, nullptr, row->subject).c_str());
    }
    SetTimer(parent_, TIMER_DOWNLOADING, 250, nullptr);
    // MessageReady follows, right away when the message is cached, or MessageFailed
    pe_message_open(core_, folder, uid);
}

// the pane says the message is being downloaded, and how large it is
void Reader::ShowDownloading() {
    core::String page(pe_message_downloading_page(core_, folder_, uid_));
    preview_.Show(page ? core::Widen(page.get()) : L"");
}

void Reader::Retry() {
    if (!uid_) {
        return;
    }
    ShowRetry(false);
    ShowDownloading();
    pe_message_open(core_, folder_, uid_);
}

bool Reader::OpenFile(const std::wstring& path, std::wstring& error) {
    file_ = path;
    char* reason = nullptr;
    view_.reset(pe_file_view(core_, core::Narrow(path).c_str(), remoteImages_, &reason));
    core::String why(reason);
    if (!view_) {
        error = Text(why.get());
        return false;
    }
    ShowInfo();
    return true;
}

void Reader::StartView() {
    // a message file is read right here: it is no larger than an import takes
    if (!file_.empty()) {
        std::wstring error;
        if (!OpenFile(file_, error)) {
            SetWindowTextW(header_, (L" " + core::T(PE_TEXT_UI_NOT_SHOWN)).c_str());
        }
        return;
    }
    // parsing, folding and sanitizing a large message takes a while: on a worker, ViewReady follows
    if (viewRequest_) {
        pe_message_view_cancel(core_, viewRequest_);
    }
    viewRequest_ = pe_message_view_start(core_, folder_, uid_, remoteImages_);
    if (!viewRequest_) {
        SetWindowTextW(header_, (L" " + core::T(PE_TEXT_UI_NOT_SHOWN)).c_str());
    }
}

void Reader::ShowView() {
    view_.reset(pe_message_view_result(core_, viewRequest_));
    viewRequest_ = 0;
    ShowInfo();
}

void Reader::ShowInfo() {
    const PeMessageInfo* info = pe_message_view_info(view_.get());
    bool file = !file_.empty();
    if (!info) {
        SetWindowTextW(header_, (L" " + core::T(PE_TEXT_UI_NOT_SHOWN)).c_str());
        ShowBars(false, false);
        return;
    }
    ShowHeader(info);
    // a mailing list that says how to leave it
    unsubscribeKind_ = file ? PE_UNSUBSCRIBE_NONE : info->unsubscribe;
    unsubscribeLink_ = Text(info->unsubscribe_link);
    unsubscribeTarget_ = Text(info->unsubscribe_target);
    ShowWindow(unsubscribe_, unsubscribeKind_ != PE_UNSUBSCRIBE_NONE ? SW_SHOW : SW_HIDE);
    ShowLogo(info->has_logo && !file);
    Layout();
    InvalidateRect(unsubscribe_, nullptr, TRUE);
    preview_.Show(Text(info->document), info->pictures_loaded || remoteImages_);
    // offered only for a message with pictures on the internet, until they are shown (asked for, or by themselves)
    ShowBars(info->attachment_count > 0, info->remote_images && !info->pictures_loaded && !remoteImages_);
    if (onShown) {
        onShown();
    }
}

void Reader::ShowHeader(const PeMessageInfo* info) {
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

void Reader::ChooseAttachment() {
    const PeMessageInfo* info = Info();
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
    uint8_t* data = AttachmentData(static_cast<size_t>(chosen - 1), length, name);
    core::String safeName(name);
    if (!data) {
        // a large message shows its text before the rest of it is here
        bool downloading = file_.empty() && pe_message_downloading(core_, folder_, uid_);
        std::wstring why = core::T(downloading ? PE_TEXT_UI_ATTACHMENT_DOWNLOADING : PE_TEXT_UI_ATTACHMENT_NOT_READ);
        MessageBoxW(parent_, why.c_str(), L"Inbox Classic", MB_OK | (downloading ? MB_ICONINFORMATION : MB_ICONERROR));
        return;
    }
    std::wstring path = SaveFileDialog(parent_, Text(safeName.get()));
    if (!path.empty()) {
        if (WriteFileBytes(path, data, length)) {
            MarkFromInternet(path);
        } else {
            MessageBoxW(parent_, core::T(PE_TEXT_UI_ATTACHMENT_NOT_SAVED).c_str(), L"Inbox Classic", MB_OK | MB_ICONERROR);
        }
    }
    pe_bytes_free(data, length);
}

// the files of the message shown, of its folder or of the message file
uint8_t* Reader::AttachmentData(size_t index, size_t& length, char*& name) const {
    if (!file_.empty()) {
        return pe_file_attachment_data(core_, core::Narrow(file_).c_str(), index, &length, &name);
    }
    return pe_attachment_data(core_, folder_, uid_, index, &length, &name);
}

bool Reader::SaveAttachments(const std::string& dir, size_t& saved, size_t& total) const {
    if (!file_.empty()) {
        return pe_file_save_attachments(core_, core::Narrow(file_).c_str(), dir.c_str(), &saved, &total);
    }
    return pe_save_attachments(core_, folder_, uid_, dir.c_str(), &saved, &total);
}

void Reader::SaveAllAttachments() {
    std::wstring folder = FolderDialog(parent_, core::Title(PE_TEXT_WIN_SAVE_ATTACHMENTS).c_str());
    if (folder.empty()) {
        return;
    }
    // the core saves them all from one reading of the message, a file already there kept and the new one numbered
    size_t saved = 0;
    size_t total = 0;
    std::string dir = core::Narrow(folder);
    if (!SaveAttachments(dir, saved, total)) {
        MessageBoxW(parent_, core::T(PE_TEXT_UI_NOT_DOWNLOADED).c_str(), L"Inbox Classic", MB_OK | MB_ICONINFORMATION);
    } else if (saved < total) {
        std::wstring text =
            core::T(PE_TEXT_WIN_FILES_NOT_SAVED, {{"failed", std::to_wstring(total - saved)}, {"count", std::to_wstring(total)}});
        MessageBoxW(parent_, text.c_str(), L"Inbox Classic", MB_OK | MB_ICONERROR);
    }
}

void Reader::FindInMessage(HWND owner, bool again) {
    if (!Info()) {
        return;
    }
    if (again && preview_.Finding() && preview_.FindNext()) {
        return;
    }
    std::vector<FormField> fields = {{core::T(PE_TEXT_WIN_FIND_LABEL), findWords_}};
    if (!FormDialog(owner, core::Title(PE_TEXT_CMD_FIND_IN_MESSAGE), core::T(PE_TEXT_UI_FIND_IN_MESSAGE_HINT), fields) ||
        fields[0].value.empty()) {
        return;
    }
    findWords_ = fields[0].value;
    preview_.Find(findWords_, [this, words = findWords_](int count) {
        if (onFound && count >= 0) {
            onFound(count > 0 ? L"" : core::T(PE_TEXT_UI_FIND_NOT_FOUND, {{"words", words}}));
        }
    });
}

void Reader::LoadPictures() {
    if ((uid_ || !file_.empty()) && view_ && !remoteImages_) {
        remoteImages_ = true;
        StartView();
    }
}

bool Reader::PicturesShown() const {
    const PeMessageInfo* info = Info();
    return remoteImages_ || (info && info->pictures_loaded);
}

void Reader::ChoosePictures() {
    const PeMessageInfo* info = Info();
    if (!info) {
        return;
    }
    enum : UINT { kSender = 1, kDomain, kDownload };
    std::string sender = info->sender ? info->sender : "";
    std::string domain = info->sender_domain ? info->sender_domain : "";
    std::wstring alwaysSender = Text(info->pictures_always_sender), alwaysDomain = Text(info->pictures_always_domain);
    std::wstring unconfirmed = Text(info->pictures_unconfirmed);
    HMENU menu = CreatePopupMenu();
    if (!alwaysSender.empty()) {
        AppendMenuW(menu, MF_STRING, kSender, MenuText(alwaysSender).c_str());
    }
    if (!alwaysDomain.empty()) {
        AppendMenuW(menu, MF_STRING, kDomain, MenuText(alwaysDomain).c_str());
    }
    // a sender the provider did not confirm: why there is no Always
    if (alwaysSender.empty() && alwaysDomain.empty() && !unconfirmed.empty()) {
        AppendMenuW(menu, MF_STRING | MF_GRAYED, 0, MenuText(unconfirmed).c_str());
    }
    if (GetMenuItemCount(menu) > 0) {
        AppendMenuW(menu, MF_SEPARATOR, 0, nullptr);
    }
    AppendMenuW(menu, MF_STRING, kDownload, MenuItem(PE_TEXT_CMD_PICTURES).c_str());
    RECT arrow;
    GetWindowRect(picturesMenu_, &arrow);
    UINT chosen = TrackPopupMenu(menu, TPM_RETURNCMD | TPM_RIGHTALIGN | TPM_TOPALIGN, arrow.right, arrow.bottom, 0, parent_, nullptr);
    DestroyMenu(menu);
    if (chosen == kDownload) {
        LoadPictures();
    } else if (chosen == kSender || chosen == kDomain) {
        bool whole = chosen == kDomain;
        // shown again: the core now loads them by itself, as it will for the sender's next messages
        if (pe_trust_sender(core_, (whole ? domain : sender).c_str(), whole) && (uid_ || !file_.empty())) {
            StartView();
        } else {
            LoadPictures();
        }
    }
}

void Reader::Print(HWND owner) {
    if (const PeMessageInfo* info = Info()) {
        // the message as it is shown, with the pictures the user allowed or the core loaded
        OpenPrintWindow(owner, preview_.Environment(), info->document, PicturesShown(), Text(info->subject));
    }
}

core::Draft Reader::DraftOf(PeDraftKind kind, int64_t account) const {
    if (!file_.empty() && view_) {
        return core::Draft(pe_file_draft(core_, core::Narrow(file_).c_str(), account, kind));
    }
    if (!uid_ || !view_) {
        return core::Draft();
    }
    return core::Draft(pe_message_draft(core_, folder_, uid_, kind));
}

std::wstring Reader::Unsubscribe(HWND owner, std::wstring& mailto) {
    const std::wstring& target = unsubscribeTarget_;
    switch (unsubscribeKind_) {
    case PE_UNSUBSCRIBE_ONE_CLICK: {
        std::wstring question = core::T(PE_TEXT_UI_LEAVE_LIST) + L"\n\n" + core::T(PE_TEXT_UI_LEAVE_ONE_CLICK, {{"target", target}});
        if (MessageBoxW(owner, question.c_str(), core::T(PE_TEXT_UI_UNSUBSCRIBE).c_str(), MB_YESNO | MB_ICONQUESTION) != IDYES) {
            return L"";
        }
        unsubscribeRequest_ = pe_unsubscribe(core_, folder_, uid_);
        return unsubscribeRequest_ ? core::T(PE_TEXT_UI_UNSUBSCRIBING, {{"target", target}}) : core::T(PE_TEXT_UI_CANNOT_UNSUBSCRIBE);
    }
    case PE_UNSUBSCRIBE_MAIL: {
        std::wstring question = core::T(PE_TEXT_UI_LEAVE_LIST) + L"\n\n" + core::T(PE_TEXT_UI_LEAVE_MAIL, {{"target", target}});
        if (MessageBoxW(owner, question.c_str(), core::T(PE_TEXT_UI_UNSUBSCRIBE).c_str(), MB_OKCANCEL | MB_ICONQUESTION) == IDOK) {
            mailto = unsubscribeLink_;
        }
        return L"";
    }
    case PE_UNSUBSCRIBE_WEB: {
        std::wstring question = core::T(PE_TEXT_UI_LEAVE_LIST) + L"\n\n" + core::T(PE_TEXT_UI_LEAVE_WEB, {{"target", target}});
        if (MessageBoxW(owner, question.c_str(), core::T(PE_TEXT_UI_UNSUBSCRIBE).c_str(), MB_OKCANCEL | MB_ICONQUESTION) == IDOK) {
            webview::OpenExternally(unsubscribeLink_.c_str());
        }
        return L"";
    }
    default:
        return L"";
    }
}

std::wstring Reader::Unsubscribed(uint64_t request, const std::wstring& problem) {
    if (!request || request != unsubscribeRequest_) {
        return L"";
    }
    unsubscribeRequest_ = 0;
    return problem.empty() ? core::T(PE_TEXT_UI_UNSUBSCRIBED) : core::T(PE_TEXT_UI_NOT_UNSUBSCRIBED, {{"reason", problem}});
}

// the logo is asked for when the message has one the server passed, and shown once it is drawn (LogoReady)
void Reader::ShowLogo(bool wanted) {
    if (logoBitmap_) {
        DeleteObject(logoBitmap_);
        logoBitmap_ = nullptr;
    }
    logoRequest_ = 0;
    // the header back over the logo's place, which would stay empty beside it
    if (ShowWindow(logo_, SW_HIDE)) {
        Layout();
    }
    if (wanted) {
        logoSize_ = Scale(48);
        logoRequest_ = pe_logo_start(core_, folder_, uid_, static_cast<uint32_t>(logoSize_));
    }
}

// the calendar part as a file of its own (the core writes it, and only it), for the calendar program
void Reader::OpenInCalendar() {
    wchar_t temp[MAX_PATH] = L"";
    GetTempPathW(MAX_PATH, temp);
    std::wstring dir = std::wstring(temp) + L"InboxClassic\\Invitations";
    std::string target = core::Narrow(dir);
    core::String path(file_.empty() ? pe_invitation_file(core_, folder_, uid_, target.c_str())
                                    : pe_file_invitation_file(core_, core::Narrow(file_).c_str(), target.c_str()));
    if (!path) {
        MessageBoxW(parent_, core::T(PE_TEXT_UI_INVITATION_NOT_READ).c_str(), L"Inbox Classic", MB_OK | MB_ICONERROR);
        return;
    }
    // marked as from the internet by the core, which wrote it
    std::wstring file = Text(path.get());
    if (reinterpret_cast<INT_PTR>(ShellExecuteW(parent_, L"open", file.c_str(), nullptr, nullptr, SW_SHOWNORMAL)) <= 32) {
        MessageBoxW(parent_, core::T(PE_TEXT_UI_NO_CALENDAR).c_str(), L"Inbox Classic", MB_OK | MB_ICONINFORMATION);
    }
}

bool Reader::OnDrawItem(const DRAWITEMSTRUCT& item) {
    if (item.hwndItem == picturesMenu_) {
        // a small arrow down on the bar's color, as a drop-down button's
        FillRect(item.hDC, &item.rcItem, GetSysColorBrush(COLOR_INFOBK));
        int cx = (item.rcItem.left + item.rcItem.right) / 2, cy = (item.rcItem.top + item.rcItem.bottom) / 2;
        int half = Scale(4);
        POINT points[] = {{cx - half, cy - half / 2}, {cx + half + 1, cy - half / 2}, {cx, cy + half / 2 + 1}};
        HBRUSH ink = CreateSolidBrush(GetSysColor(COLOR_INFOTEXT));
        HGDIOBJ oldBrush = SelectObject(item.hDC, ink);
        HGDIOBJ oldPen = SelectObject(item.hDC, GetStockObject(NULL_PEN));
        Polygon(item.hDC, points, 3);
        SelectObject(item.hDC, oldPen);
        SelectObject(item.hDC, oldBrush);
        DeleteObject(ink);
        return true;
    }
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
    return false;
}

bool Reader::OnNotify(NMHDR* header, LRESULT& result) {
    if (header->hwndFrom == attachments_ && header->code == TBN_DROPDOWN) {
        ChooseAttachment();
        result = TBDDRET_DEFAULT;
        return true;
    }
    return false;
}

bool Reader::OnCommand(WORD id, WORD) {
    switch (id) {
    case IDC_ATTACHMENTS:
        ChooseAttachment();
        return true;
    case IDC_PICTURES:
        LoadPictures();
        return true;
    case IDC_PICTURES_MENU:
        ChoosePictures();
        return true;
    case IDC_RETRY:
        Retry();
        return true;
    case IDC_BOUNCED_MESSAGE:
        if (const PeMessageInfo* info = Info(); info && info->has_bounced_message && onBouncedMessage) {
            onBouncedMessage(info->bounced_folder, info->bounced_uid);
        }
        return true;
    }
    return false;
}

bool Reader::OnTimer(UINT_PTR id) {
    if (id == TIMER_FIND_SETTLED) {
        preview_.FindSettled();
        return true;
    }
    if (id != TIMER_DOWNLOADING) {
        return false;
    }
    KillTimer(parent_, TIMER_DOWNLOADING);
    ShowDownloading();
    return true;
}

void Reader::OnEvent(const UiEvent& event) {
    switch (event.kind) {
    case PE_EVENT_KIND_MESSAGE_READY:
        if (uid_ && event.folder == folder_ && event.uid == uid_) {
            KillTimer(parent_, TIMER_DOWNLOADING);
            ShowRetry(false);
            StartView();
        }
        break;
    case PE_EVENT_KIND_MESSAGE_FAILED:
        if (uid_ && event.folder == folder_ && event.uid == uid_) {
            KillTimer(parent_, TIMER_DOWNLOADING);
            ShowBars(false, false);
            ShowRetry(true);
            preview_.ShowState(PE_READER_STATE_FAILED, event.failure, core::Narrow(event.message));
        }
        break;
    case PE_EVENT_KIND_SYNC_FINISHED:
        // the account is back: a message it could not give is tried again
        if (event.failure == PE_FAILURE_KIND_NONE && IsWindowVisible(retry_) && account_ && account_ == event.account) {
            Retry();
        }
        break;
    case PE_EVENT_KIND_VIEW_READY:
        // a view for a message that is no longer shown was cancelled, its event is not this one
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
                    Layout();
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
