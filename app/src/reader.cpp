// The reading pane (reader.h): the header, the bars under it and the message in the WebView2, for the main window and
// the message windows alike.
#include "app.h"
#include "icons.h"
#include "webview.h"

#include <share.h>
#include <shellapi.h>
#include <windowsx.h>

#include <algorithm>
#include <cstdio>
#include <memory>
#include <utility>
#include <vector>

namespace {

// the readers whose views are built again one after the other (Reader::Rebuild), the core building one at a time
std::vector<Reader*> g_rebuilds;

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

// how tall a line of the header is, in its font (the static control draws its lines that far apart)
int HeaderLine(HWND header) {
    HDC dc = GetDC(header);
    HGDIOBJ old = SelectObject(dc, reinterpret_cast<HFONT>(SendMessageW(header, WM_GETFONT, 0, 0)));
    TEXTMETRICW metrics = {};
    GetTextMetricsW(dc, &metrics);
    SelectObject(dc, old);
    ReleaseDC(header, dc);
    return metrics.tmHeight;
}

// the Reactions line's words: its label as the header's are written, then one chip a person
std::wstring ReactionsLabel() {
    return L" " + core::Plain(PE_TEXT_UI_REACTIONS_LABEL) + L"  ";
}

// the room between two people's chips
constexpr const wchar_t* kChipGap = L"   ";

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

// the security bar: its Details button is its child, whose click goes on to the reading pane's window; the bar draws
// all of itself (WM_DRAWITEM)
LRESULT CALLBACK SecurityBarProc(HWND hwnd, UINT message, WPARAM wParam, LPARAM lParam, UINT_PTR, DWORD_PTR) {
    switch (message) {
    case WM_COMMAND:
        return SendMessageW(GetParent(hwnd), message, wParam, lParam);
    case WM_ERASEBKGND:
        return TRUE;
    case WM_NCDESTROY:
        RemoveWindowSubclass(hwnd, SecurityBarProc, 0);
        break;
    }
    return DefSubclassProc(hwnd, message, wParam, lParam);
}

// the attachment strip's frame: what its list view tells goes on to the reading pane's window; its background is the
// list's
LRESULT CALLBACK StripFrameProc(HWND hwnd, UINT message, WPARAM wParam, LPARAM lParam, UINT_PTR, DWORD_PTR) {
    switch (message) {
    case WM_NOTIFY:
    case WM_COMMAND:
        return SendMessageW(GetParent(hwnd), message, wParam, lParam);
    case WM_ERASEBKGND:
        return TRUE;
    case WM_PAINT: {
        PAINTSTRUCT paint;
        HDC dc = BeginPaint(hwnd, &paint);
        FillRect(dc, &paint.rcPaint, GetSysColorBrush(COLOR_WINDOW));
        EndPaint(hwnd, &paint);
        return 0;
    }
    case WM_NCDESTROY:
        RemoveWindowSubclass(hwnd, StripFrameProc, 0);
        break;
    }
    return DefSubclassProc(hwnd, message, wParam, lParam);
}

// the Details button's height and its margin from the bar's right end
int DetailsHeight() {
    return Scale(23);
}

int DetailsMargin() {
    return Scale(4);
}

// the icon of the strip for a file's kind, as the core gave it
int KindIcon(PeFileKind kind) {
    switch (kind) {
    case PE_FILE_KIND_IMAGE: return KIND_IMAGE;
    case PE_FILE_KIND_PDF: return KIND_DOCUMENT_PDF;
    case PE_FILE_KIND_DOCUMENT: return KIND_DOCUMENT_TEXT;
    case PE_FILE_KIND_SPREADSHEET: return KIND_DOCUMENT_TABLE;
    case PE_FILE_KIND_PRESENTATION: return KIND_SLIDE_TEXT;
    case PE_FILE_KIND_ARCHIVE: return KIND_FOLDER_ZIP;
    case PE_FILE_KIND_AUDIO: return KIND_MUSIC_NOTE_2;
    case PE_FILE_KIND_VIDEO: return KIND_VIDEO;
    case PE_FILE_KIND_CALENDAR: return KIND_CALENDAR_LTR;
    case PE_FILE_KIND_CONTACT: return KIND_CONTACT_CARD;
    case PE_FILE_KIND_KEY: return KIND_KEY;
    case PE_FILE_KIND_TEXT: return KIND_DOCUMENT_ONE_PAGE;
    case PE_FILE_KIND_MAIL: return KIND_MAIL;
    case PE_FILE_KIND_PROGRAM: return KIND_WINDOW_SHIELD;
    case PE_FILE_KIND_OTHER: return KIND_DOCUMENT;
    }
    return KIND_DOCUMENT;
}

// the label of a file of the strip: its name, shortened by Windows when it is wider than `width` in the font of `dc`
// (its start and its extension kept, the end of the rest left out: DrawText's own ellipsis, which leaves out the
// middle only of a path; the whole name is the item's tooltip), and its size, as Outlook Express wrote its Attach line
// ("report.pdf (240 KB)")
std::wstring StripLabel(HDC dc, const PeAttachment& attachment, int width) {
    std::wstring name = Text(attachment.filename);
    size_t dot = name.rfind(L'.');
    std::wstring extension = dot != std::wstring::npos && dot > 0 && name.size() - dot <= 10 ? name.substr(dot) : L"";
    SIZE extent = {};
    GetTextExtentPoint32W(dc, extension.c_str(), static_cast<int>(extension.size()), &extent);
    // the rest, with room for the ellipsis Windows writes into it
    std::wstring stem = name.substr(0, name.size() - extension.size());
    std::vector<wchar_t> buffer(stem.begin(), stem.end());
    buffer.resize(buffer.size() + 5, L'\0');
    RECT box = {0, 0, std::max(1, width - static_cast<int>(extent.cx)), 1};
    DrawTextExW(dc, buffer.data(), -1, &box, DT_SINGLELINE | DT_NOPREFIX | DT_END_ELLIPSIS | DT_MODIFYSTRING, nullptr);
    std::wstring start(buffer.data());
    // after the ellipsis, the extension without its dot: "walking wee...docx", not four dots
    std::wstring end = start != stem && !extension.empty() ? extension.substr(1) : extension;
    return start + end + L" (" + Text(attachment.size_text) + L")";
}

constexpr UINT WM_STRIP_OPENED = WM_APP + 80;
// on the strip: what Import Key did, from its thread
constexpr UINT WM_STRIP_IMPORTED = WM_APP + 81;
// on the strip: an open that takes a while shows on its item
constexpr UINT_PTR TIMER_STRIP_BUSY = 1;

// the opened files of a test run (--opened-files-log), written there in place of opening them
std::wstring g_openedFilesLog;

// a file the core wrote for opening, opened with its program (Windows asks which, for a kind none opens)
void OpenWithSystem(HWND owner, const std::wstring& path) {
    if (g_openedFilesLog.empty()) {
        ShellExecuteW(owner, L"open", path.c_str(), nullptr, nullptr, SW_SHOWNORMAL);
        return;
    }
    // shared, so the test can read it while a line is written
    if (FILE* log = _wfsopen(g_openedFilesLog.c_str(), L"ab", _SH_DENYNO)) {
        std::string line = core::Narrow(path) + "\n";
        fwrite(line.data(), 1, line.size(), log);
        fclose(log);
    }
}

}  // namespace

// what the thread of an open hands back to the strip (WM_STRIP_OPENED): the file to open and the note to show first,
// or why there is none (`refused`; neither for a message not here)
struct StripOpened {
    int item = -1;
    std::wstring path;
    std::wstring note;
    std::wstring refused;
};

// what the thread of Import Key hands back to the strip (WM_STRIP_IMPORTED): how it ended and the core's words
struct StripImported {
    PeImportOutcome outcome = PE_IMPORT_OUTCOME_INVALID;
    std::wstring said;
};

void SetOpenedFilesLog(const std::wstring& path) {
    g_openedFilesLog = path;
    // and the links a message's links would open in the browser, in the same file
    webview::SetOpenedLinksLog(path);
}

void Reader::Create(HWND parent, PeCore* core) {
    parent_ = parent;
    core_ = core;
    header_ = CreateChild(parent, L"STATIC", L"", SS_LEFT | SS_NOPREFIX | SS_SUNKEN | WS_CLIPSIBLINGS, 0, {});
    // the Reactions line, over the header's room for a fifth line when the message has reactions: drawn here, Tab
    // reaches it, its menu (right-click, the menu key, Shift+F10) on each person
    reactions_ = CreateChild(parent, L"STATIC", L"", SS_OWNERDRAW | SS_NOTIFY | SS_NOPREFIX | WS_TABSTOP | WS_CLIPSIBLINGS, IDC_REACTIONS, {});
    SetWindowSubclass(reactions_, ReactionsProc, 0, reinterpret_cast<DWORD_PTR>(this));
    ShowWindow(reactions_, SW_HIDE);
    logo_ = CreateChild(parent, L"STATIC", L"", SS_OWNERDRAW, IDC_LOGO, {});
    ShowWindow(logo_, SW_HIDE);
    // the paper clip at the right of the header, as Outlook Express has it: the files of the message in its menu, its
    // label beside it, so it is no taller than the header's buttons
    attachments_ = CreateBar(parent, CCS_NODIVIDER | CCS_NOPARENTALIGN | CCS_NORESIZE | TBSTYLE_LIST, IDC_ATTACHMENTS, BarIcons::Big);
    // a label from the start, so the bar keeps room for it ("2 files" once a message is shown)
    AddButton(attachments_, IDC_ATTACHMENTS, core::T(PE_TEXT_WIN_FILES, {{"count", L"1"}}).c_str(), BTNS_WHOLEDROPDOWN, ICON_ATTACH);
    // the security bar of a signed or encrypted message, first under the header (and first for a screen reader, its
    // words its name), its Details button at its right end: Tab and Alt with its letter reach it
    security_ = CreateChild(parent, L"STATIC", L"", SS_OWNERDRAW | SS_NOPREFIX | WS_CLIPCHILDREN | WS_CLIPSIBLINGS, IDC_SECURITY_BAR, {},
                            WS_EX_CONTROLPARENT);
    SetWindowSubclass(security_, SecurityBarProc, 0, 0);
    securityDetails_ = CreateChild(security_, L"BUTTON", core::T(PE_TEXT_UI_PROTECTION_DETAILS).c_str(), WS_TABSTOP | BS_PUSHBUTTON,
                                   IDC_SECURITY_DETAILS, {});
    ShowWindow(security_, SW_HIDE);
    EnableWindow(securityDetails_, FALSE);
    // the strip of the files under the header and the security bar, an item a file with its icon, name and size, in
    // columns as wide as the widest (a list view's List mode, as Explorer's): a double-click or Enter opens one, its
    // menu saves it. After the security bar's Details for Tab
    // (in a frame of its own, which shows its edge and a margin around the items, and keeps out of sight the room the
    // list view keeps under them for a scroll bar it may not need)
    stripFrame_ = CreateChild(parent, L"STATIC", L"", WS_CLIPCHILDREN | WS_CLIPSIBLINGS, IDC_ATTACHMENT_FRAME, {},
                              WS_EX_CLIENTEDGE | WS_EX_CONTROLPARENT);
    SetWindowSubclass(stripFrame_, StripFrameProc, 0, 0);
    strip_ = CreateChild(stripFrame_, WC_LISTVIEWW, L"", WS_TABSTOP | LVS_LIST | LVS_SINGLESEL | LVS_SHAREIMAGELISTS,
                         IDC_ATTACHMENT_STRIP, {});
    ListView_SetExtendedListViewStyle(strip_, LVS_EX_INFOTIP);
    ListView_SetImageList(strip_, IconList(IconSet::Files), LVSIL_SMALL);
    // the lock over a file that came from an encrypted part: overlay 1 of the list the strips share
    ImageList_SetOverlayImage(IconList(IconSet::Files), KIND_LOCK_BADGE, 1);
    SetAccessibleName(strip_, core::T(PE_TEXT_UI_ATTACHMENTS_STRIP));
    SetWindowSubclass(strip_, StripProc, 0, reinterpret_cast<DWORD_PTR>(this));
    ShowWindow(stripFrame_, SW_HIDE);
    // the information bar of Outlook Express over a message whose pictures on the internet are blocked; a click
    // shows them
    std::wstring blocked = L" " + core::T(PE_TEXT_UI_PICTURES_BLOCKED);
    pictures_ = CreateChild(parent, L"STATIC", blocked.c_str(),
                            SS_LEFT | SS_CENTERIMAGE | SS_NOPREFIX | SS_ENDELLIPSIS | WS_BORDER | WS_CLIPSIBLINGS, IDC_PICTURES_BAR, {});
    // its Download Pictures at its right end, and the drop-down arrow beside it, as Outlook's bar has: the Always
    // choices
    picturesButton_ = CreateChild(parent, L"BUTTON", core::Plain(PE_TEXT_CMD_PICTURES).c_str(), WS_TABSTOP | BS_PUSHBUTTON, IDC_PICTURES, {});
    picturesMenu_ = CreateChild(parent, L"BUTTON", L"", WS_TABSTOP | BS_OWNERDRAW, IDC_PICTURES_MENU, {});
    ShowWindow(attachments_, SW_HIDE);
    ShowWindow(pictures_, SW_HIDE);
    ShowWindow(picturesButton_, SW_HIDE);
    ShowWindow(picturesMenu_, SW_HIDE);
    // the same bar over a message that could not be downloaded, with Try Again
    core::String note(pe_retry_note());
    std::wstring retry = L" " + Text(note.get());
    retry_ = CreateChild(parent, L"STATIC", retry.c_str(), SS_LEFT | SS_CENTERIMAGE | SS_NOPREFIX | SS_ENDELLIPSIS | WS_BORDER | WS_CLIPSIBLINGS,
                         IDC_RETRY_BAR, {});
    retryButton_ = CreateChild(parent, L"BUTTON", core::T(PE_TEXT_UI_TRY_AGAIN).c_str(), WS_TABSTOP | BS_PUSHBUTTON, IDC_RETRY, {});
    ShowWindow(retry_, SW_HIDE);
    ShowWindow(retryButton_, SW_HIDE);
    // the same bar over a message of a mailing list, with a push button at its right end (not drawn over it)
    listBar_ = CreateChild(parent, L"STATIC", L"", SS_LEFT | SS_CENTERIMAGE | SS_NOPREFIX | SS_ENDELLIPSIS | WS_BORDER | WS_CLIPSIBLINGS,
                           IDC_LIST_BAR, {});
    listButton_ = CreateChild(parent, L"BUTTON", core::T(PE_TEXT_UI_UNSUBSCRIBE_ASK).c_str(), WS_TABSTOP | BS_PUSHBUTTON, IDC_UNSUBSCRIBE, {});
    ShowWindow(listBar_, SW_HIDE);
    ShowWindow(listButton_, SW_HIDE);
    // the message itself is a Tab stop too: its host hands the keyboard to the WebView2
    previewHost_ = CreateChild(parent, L"STATIC", nullptr, SS_SUNKEN | WS_CLIPCHILDREN | WS_TABSTOP, 0, {});
    SetWindowSubclass(previewHost_, BodyHostProc, 0, reinterpret_cast<DWORD_PTR>(&preview_));
    preview_.TakeMnemonics();
    preview_.ServePreviews(core);
    preview_.Create(previewHost_, [this](const std::wstring& error) { SetWindowTextW(previewHost_, error.c_str()); }, parent,
                    TIMER_FIND_SETTLED);
    preview_.SetLinks([this](const wchar_t* uri) { return FollowLink(uri); });
    ConversationStack::Hooks hooks;
    hooks.findTimer = TIMER_FIND_SETTLED;
    hooks.click = [this](PeConversationClick click, size_t index) { ConversationClick(click, index); };
    hooks.command = [this](WORD command, int64_t folder, uint64_t uid) {
        SelectFrame(folder, uid);
        PostMessageW(GetAncestor(parent_, GA_ROOT), WM_COMMAND, MAKEWPARAM(command, 0), 0);
    };
    hooks.more = [this](int64_t folder, uint64_t uid, POINT screen) {
        SelectFrame(folder, uid);
        FrameMenu(folder ? folder : folder_, uid ? uid : uid_, screen);
    };
    hooks.edit = [this](int64_t folder, uint64_t uid) {
        if (onEditDraft) {
            onEditDraft(folder ? folder : folder_, uid ? uid : uid_);
        }
    };
    hooks.openWindow = [this](int64_t folder, uint64_t uid) {
        if (onOpenMessage && (uid || uid_)) {
            onOpenMessage(folder ? folder : folder_, uid ? uid : uid_);
        }
    };
    hooks.links = [this](const wchar_t* uri) { return FollowLink(uri); };
    hooks.keys = [this](UINT key) { return keys_ && keys_(key); };
    // the selected frame's own: its Reactions line and its strip of files, moved into the stack
    hooks.placeReactions = [this](int left, int top, int width) {
        if (!reactionList_) {
            ShowWindow(reactions_, SW_HIDE);
            return 0;
        }
        if (GetParent(reactions_) != stack_.Hwnd()) {
            SetParent(reactions_, stack_.Hwnd());
        }
        int line = HeaderLine(header_) + Scale(4);
        MoveWindow(reactions_, left, top, width, line, TRUE);
        ShowWindow(reactions_, SW_SHOW);
        InvalidateRect(reactions_, nullptr, FALSE);
        return line;
    };
    hooks.placeFiles = [this](int left, int top, int width) {
        if (stripFiles_.empty()) {
            ShowWindow(stripFrame_, SW_HIDE);
            return 0;
        }
        if (GetParent(stripFrame_) != stack_.Hwnd()) {
            SetParent(stripFrame_, stack_.Hwnd());
        }
        ShowWindow(stripFrame_, SW_SHOW);
        return PlaceStrip(left, top, width);
    };
    hooks.placeClip = [this](int right, int middle) {
        if (stripFiles_.empty()) {
            ShowWindow(attachments_, SW_HIDE);
            return 0;
        }
        if (GetParent(attachments_) != stack_.Hwnd()) {
            SetParent(attachments_, stack_.Hwnd());
            // as big as its button where the stack puts it, never as wide as the stack (a toolbar sizes itself to its
            // parent otherwise, over the frame's buttons)
            SetWindowLongPtrW(attachments_, GWL_STYLE, GetWindowLongPtrW(attachments_, GWL_STYLE) | CCS_NORESIZE | CCS_NOPARENTALIGN);
        }
        RECT button = {};
        SendMessageW(attachments_, TB_AUTOSIZE, 0, 0);
        SendMessageW(attachments_, TB_GETITEMRECT, 0, reinterpret_cast<LPARAM>(&button));
        int width = button.right - button.left, height = button.bottom - button.top;
        MoveWindow(attachments_, right - width, middle - height / 2, width, height, TRUE);
        ShowWindow(attachments_, SW_SHOW);
        return width;
    };
    stack_.Create(parent, core, std::move(hooks));

    LOGFONTW font = {};
    GetObjectW(UiFont(), sizeof(font), &font);
    font.lfWeight = FW_BOLD;
    bold_ = CreateFontIndirectW(&font);
}

void Reader::Destroy() {
    // not built again after it is gone; the next one waiting is, should this one have been built
    std::erase(g_rebuilds, this);
    if (std::exchange(rebuilding_, false)) {
        RebuildNext();
    }
    StopOpening();
    CancelReads();
    ForgetPrint();
    if (viewRequest_) {
        pe_message_view_cancel(core_, viewRequest_);
        viewRequest_ = 0;
    }
    if (logoBitmap_) {
        DeleteObject(logoBitmap_);
        logoBitmap_ = nullptr;
    }
    stack_.Destroy();
    preview_.Close();
    view_.reset();
    DeleteObject(bold_);
    bold_ = nullptr;
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
    case PE_READER_LINK_PART: {
        // a part's label: the Details window at that part, once the WebView2's event is over (the link names the
        // part's number after its prefix)
        const wchar_t* number = wcsrchr(uri, L'-');
        detailsPart_ = number ? _wtoi(number + 1) : -1;
        PostMessageW(parent_, WM_COMMAND, MAKEWPARAM(IDC_SECURITY_DETAILS, 0), 0);
        return true;
    }
    case PE_READER_LINK_ATTACHMENT: {
        // a preview of the view this reader shows (its token): its file opened as a double-click in the strip opens
        // it, once the WebView2's event is over (a file that can not open says why in a message box)
        const PeMessageInfo* info = Info();
        previewOpen_ = info ? pe_preview_link(core_, core::Narrow(uri).c_str(), info->preview_token) : -1;
        if (previewOpen_ >= 0) {
            PostMessageW(parent_, WM_COMMAND, MAKEWPARAM(IDC_OPEN_PREVIEW, 0), 0);
        }
        return true;
    }
    case PE_READER_LINK_FIND_KEY:
        FindSignerKey(uri);
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

int Reader::TestShown(const std::wstring& subject) const {
    const PeMessageInfo* info = Info();
    if (!info || !const_cast<Reader*>(this)->Body().Loaded()) {
        return 0;
    }
    return subject.empty() || Text(info->subject) == subject ? 1 : 0;
}

// the paper clip and the information bar shown or not, the pane laid out again only when that changes
void Reader::ShowBars(bool files, bool pictures) {
    // the arrow only when its menu has more than the bar's own click: an Always, or why there is none (encrypted mail
    // has neither, its pictures load for a click only)
    const PeMessageInfo* info = Info();
    bool arrow = pictures && info &&
                 ((info->pictures_always_sender && *info->pictures_always_sender) || (info->pictures_always_domain && *info->pictures_always_domain) ||
                  (info->pictures_unconfirmed && *info->pictures_unconfirmed));
    if (!pictures && (GetFocus() == picturesButton_ || GetFocus() == picturesMenu_)) {
        SetFocus(previewHost_);
    }
    bool changed = (IsWindowVisible(attachments_) != FALSE) != files || (IsWindowVisible(pictures_) != FALSE) != pictures ||
                   (IsWindowVisible(picturesMenu_) != FALSE) != arrow;
    if (!files && GetFocus() == strip_) {
        SetFocus(previewHost_);
    }
    ShowWindow(attachments_, files ? SW_SHOW : SW_HIDE);
    ShowWindow(stripFrame_, files ? SW_SHOW : SW_HIDE);
    ShowWindow(pictures_, pictures ? SW_SHOW : SW_HIDE);
    ShowWindow(picturesButton_, pictures ? SW_SHOW : SW_HIDE);
    ShowWindow(picturesMenu_, arrow ? SW_SHOW : SW_HIDE);
    if (changed || files) {
        Layout();
    }
}

void Reader::ShowSecurity(const PeMessageInfo* info) {
    bool shown = info && info->protection != PE_PROTECTION_TONE_NONE;
    securityTone_ = shown ? info->protection : PE_PROTECTION_TONE_NONE;
    securityLock_ = shown && info->protection_encrypted;
    std::wstring words = shown ? Text(info->protection_text) : L"";
    SetWindowTextW(security_, words.c_str());
    // a screen reader on the button says what it is about
    SetAccessibleDescription(securityDetails_, words);
    EnableWindow(securityDetails_, shown);
    if ((IsWindowVisible(security_) != FALSE) != shown) {
        if (!shown && GetFocus() == securityDetails_) {
            SetFocus(previewHost_);
        }
        ShowWindow(security_, shown ? SW_SHOW : SW_HIDE);
        Layout();
    }
}

int Reader::SecurityHeight(int width) const {
    if (!IsWindowVisible(security_)) {
        return 0;
    }
    int reserved = ButtonWidth({GetWindowString(securityDetails_)}) + DetailsMargin();
    return SecurityBarHeight(securityTone_, securityLock_, GetWindowString(security_), bold_, width, reserved);
}

void Reader::ShowSecurityDetails(int part) {
    const PeMessageInfo* info = Info();
    if (!info || info->protection == PE_PROTECTION_TONE_NONE) {
        return;
    }
    SecurityDetailsDialog(parent_, info->protection, info->protection_encrypted, Text(info->protection_text), Text(info->protection_details),
                          part);
}

void Reader::ShowRetry(bool shown) {
    if ((IsWindowVisible(retry_) != FALSE) != shown) {
        if (!shown && GetFocus() == retryButton_) {
            SetFocus(previewHost_);
        }
        ShowWindow(retry_, shown ? SW_SHOW : SW_HIDE);
        ShowWindow(retryButton_, shown ? SW_SHOW : SW_HIDE);
        Layout();
    }
}

bool Reader::OnSetCursor(HWND) const {
    // a reply or an attachment that takes long to read
    return BusyCursor();
}

bool Reader::OnCtlColor(HWND window, HDC dc, LRESULT& brush) const {
    if (window != pictures_ && window != retry_ && window != listBar_) {
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

// the header, with the paper clip at its right when the message has files; the security bar, the strip of the
// files and the information bars under it; the message below
void Reader::Layout() {
    // ShowInfo lays the pane out once, at its end
    if (holdLayout_) {
        return;
    }
    const RECT& reader = area_;
    // the message, or its conversation, in the stack: the bars over it, the frames say who and when
    if (stack_.Visible()) {
        int width = reader.right - reader.left;
        int top = reader.top;
        if (int barHeight = SecurityHeight(width); barHeight > 0) {
            MoveWindow(security_, reader.left, top, width, barHeight, TRUE);
            int buttonWidth = ButtonWidth({GetWindowString(securityDetails_)});
            MoveWindow(securityDetails_, width - buttonWidth - DetailsMargin(), (barHeight - DetailsHeight()) / 2, buttonWidth, DetailsHeight(),
                       TRUE);
            InvalidateRect(security_, nullptr, FALSE);
            top += barHeight + Scale(2);
        }
        if (IsWindowVisible(retry_)) {
            top += PlaceBar(retry_, {retryButton_}, reader.left, top, width) + Scale(2);
        }
        if (IsWindowVisible(pictures_)) {
            top += PlaceBar(pictures_, {picturesMenu_, picturesButton_}, reader.left, top, width) + Scale(2);
        }
        if (IsWindowVisible(listBar_)) {
            top += PlaceBar(listBar_, {listButton_}, reader.left, top, width) + Scale(2);
        }
        stack_.Move({reader.left, top, reader.right, std::max(top, static_cast<int>(reader.bottom))});
        return;
    }
    int headerHeight = kHeaderLines * Scale(15) + Scale(8);
    // a line more for the reactions, as tall as the header's own lines
    int line = HeaderLine(header_);
    if (reactionList_) {
        headerHeight = std::max(headerHeight + Scale(15), (kHeaderLines + 1) * line + Scale(8));
    }
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
    if (reactionList_) {
        // inside the header's edge, where its fifth line would be: its label starts where From's does
        RECT inside;
        GetClientRect(header_, &inside);
        MapWindowPoints(header_, parent_, reinterpret_cast<POINT*>(&inside), 2);
        int top = inside.top + kHeaderLines * line;
        // just above the header, so the header does not paint over it and Tab reaches it where the header is
        HWND above = GetWindow(header_, GW_HWNDPREV);
        UINT order = above == reactions_ ? SWP_NOZORDER : 0;
        SetWindowPos(reactions_, above ? above : HWND_TOP, inside.left, top, inside.right - inside.left,
                     std::max(0, std::min(line + Scale(2), static_cast<int>(inside.bottom) - top)), SWP_NOACTIVATE | order);
        InvalidateRect(reactions_, nullptr, FALSE);
    }
    if (files) {
        int buttonHeight = button.bottom - button.top;
        MoveWindow(attachments_, reader.right - clipWidth, reader.top + std::max(0, (headerHeight - buttonHeight) / 2), clipWidth, buttonHeight,
                   TRUE);
    }
    int top = reader.top + headerHeight + Scale(2);
    if (int barHeight = SecurityHeight(width); barHeight > 0) {
        MoveWindow(security_, reader.left, top, width, barHeight, TRUE);
        int buttonWidth = ButtonWidth({GetWindowString(securityDetails_)});
        MoveWindow(securityDetails_, width - buttonWidth - DetailsMargin(), (barHeight - DetailsHeight()) / 2, buttonWidth, DetailsHeight(), TRUE);
        InvalidateRect(security_, nullptr, FALSE);
        top += barHeight + Scale(2);
    }
    if (int stripHeight = PlaceStrip(reader.left, top, width); stripHeight > 0) {
        top += stripHeight + Scale(2);
    }
    // the bars in one order: the download that failed, the pictures (Download Pictures and its arrow), the mailing list
    if (IsWindowVisible(retry_)) {
        top += PlaceBar(retry_, {retryButton_}, reader.left, top, width) + Scale(2);
    }
    if (IsWindowVisible(pictures_)) {
        top += PlaceBar(pictures_, {picturesMenu_, picturesButton_}, reader.left, top, width) + Scale(2);
    }
    if (IsWindowVisible(listBar_)) {
        top += PlaceBar(listBar_, {listButton_}, reader.left, top, width) + Scale(2);
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
    // a view built again that is not waited for any more: the next reader's
    if (std::exchange(rebuilding_, false)) {
        RebuildNext();
    }
    uid_ = 0;
    folder_ = 0;
    account_ = 0;
    remoteImages_ = false;
    file_.clear();
    // the stack keeps showing the message before until the next one is here: its view kept for it
    if (loading && stack_.Visible()) {
        stackView_ = std::move(view_);
    }
    view_.reset();
    documentShown_ = false;
    ForgetPrint();
    KillTimer(parent_, TIMER_DOWNLOADING);
    ShowRetry(false);
    // the security bar never stays over another message than its own
    ShowSecurity(nullptr);
    // the bars of the message before stay while the next one loads, and go when it is there without them: the
    // message does not jump down and up again
    if (!loading) {
        ShowBars(false, false);
    }
    SetWindowTextW(header_, L"");
    LoadReactions();
    unsubscribeKind_ = PE_UNSUBSCRIBE_NONE;
    ShowListBar(L"", L"");
    ShowLogo(false, 0);
    // says so rather than a blank pane; a message about to be shown takes the place of the one before in the stack, its
    // WebView2 kept for it
    if (!loading || !stack_.Visible()) {
        ShowStack(false);
        stackView_.reset();
        preview_.Clear(!loading);
    }
}

void Reader::ShowStack(bool shown) {
    if (stack_.Visible() == shown) {
        return;
    }
    if (!shown) {
        stack_.Clear();
        stackView_.reset();
        // the selected frame's controls back with the pane
        for (HWND own : {reactions_, stripFrame_, attachments_}) {
            if (GetParent(own) != parent_) {
                SetParent(own, parent_);
                ShowWindow(own, SW_HIDE);
            }
        }
    }
    stack_.SetVisible(shown);
    ShowWindow(previewHost_, shown ? SW_HIDE : SW_SHOW);
    ShowWindow(header_, shown ? SW_HIDE : SW_SHOW);
    if (shown) {
        ShowWindow(logo_, SW_HIDE);
    }
    Layout();
}

Preview& Reader::Body() {
    if (stack_.Visible()) {
        if (Preview* body = stack_.SelectedBody()) {
            return *body;
        }
    }
    return preview_;
}

void Reader::SelectFrame(int64_t folder, uint64_t uid) {
    if (!uid || (folder == folder_ && uid == uid_) || !view_) {
        return;
    }
    const PeMessageInfo* info = pe_message_view_info(view_.get());
    for (size_t i = 0; info && i < info->conversation_entry_count; i++) {
        const PeConversationEntry* entry = pe_conversation_entry(view_.get(), i);
        if (entry && entry->folder == folder && entry->uid == uid) {
            ConversationClick(PE_CONVERSATION_CLICK_SELECT, entry->index);
            return;
        }
    }
}

void Reader::FrameMenu(int64_t folder, uint64_t uid, POINT screen) {
    enum : UINT { Print = 1, MarkUnread, Delete, OpenWindow, Source };
    HMENU menu = CreatePopupMenu();
    AppendMenuW(menu, MF_STRING, Print, core::T(PE_TEXT_CMD_PRINT).c_str());
    AppendMenuW(menu, MF_SEPARATOR, 0, nullptr);
    AppendMenuW(menu, MF_STRING, MarkUnread, core::T(PE_TEXT_CMD_MARK_UNREAD).c_str());
    AppendMenuW(menu, MF_STRING, Delete, core::T(PE_TEXT_UI_TB_DELETE).c_str());
    AppendMenuW(menu, MF_SEPARATOR, 0, nullptr);
    AppendMenuW(menu, MF_STRING, OpenWindow, core::T(PE_TEXT_UI_MENU_OPEN).c_str());
    AppendMenuW(menu, MF_STRING, Source, core::T(PE_TEXT_UI_MENU_VIEW_SOURCE).c_str());
    HWND root = GetAncestor(parent_, GA_ROOT);
    UINT chosen = TrackPopupMenu(menu, TPM_RETURNCMD | TPM_RIGHTBUTTON, screen.x, screen.y, 0, root, nullptr);
    DestroyMenu(menu);
    switch (chosen) {
    case Print:
        PostMessageW(root, WM_COMMAND, MAKEWPARAM(IDM_PRINT, 0), 0);
        break;
    case Source:
        PostMessageW(root, WM_COMMAND, MAKEWPARAM(IDM_VIEW_SOURCE, 0), 0);
        break;
    case MarkUnread:
    case Delete:
        if (onFrameAction) {
            onFrameAction(folder, uid, chosen == MarkUnread ? PE_ACTION_UNREAD : PE_ACTION_DELETE);
        }
        break;
    case OpenWindow:
        if (onOpenMessage) {
            onOpenMessage(folder, uid);
        }
        break;
    default:
        break;
    }
}

void Reader::ShowPage(const std::wstring& html) {
    documentShown_ = false;
    ShowStack(false);
    preview_.Show(html);
}

void Reader::Open(int64_t folder, uint64_t uid, int64_t account, const PeMessage* row) {
    uid_ = uid;
    size_ = row ? row->size : 0;
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
    documentShown_ = false;
    ShowStack(false);
    preview_.ShowState(PE_READER_STATE_DOWNLOADING, PE_FAILURE_KIND_NONE, {}, size_);
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
    viewRequest_ = conversation_ ? pe_conversation_view_start(core_, folder_, uid_, remoteImages_, ConversationNewestFirst())
                                 : pe_message_view_start(core_, folder_, uid_, remoteImages_);
    if (!viewRequest_) {
        SetWindowTextW(header_, (L" " + core::T(PE_TEXT_UI_NOT_SHOWN)).c_str());
    }
}

void Reader::ShowView() {
    core::MessageView view(pe_message_view_result(core_, std::exchange(viewRequest_, 0)));
    // none, as the core builds one view at a time and dropped this one for a newer one (another window's of the same
    // message): the view shown stays
    if (view || !view_) {
        view_ = std::move(view);
        ShowInfo();
    }
    if (std::exchange(rebuilding_, false)) {
        RebuildNext();
    }
}

void Reader::ShowInfo() {
    const PeMessageInfo* info = pe_message_view_info(view_.get());
    bool file = !file_.empty();
    if (!info) {
        SetWindowTextW(header_, (L" " + core::T(PE_TEXT_UI_NOT_SHOWN)).c_str());
        ShowBars(false, false);
        return;
    }
    // what changes below (the logo, the security bar, the strip, the bars) laid out once, at the end
    holdLayout_ = true;
    ShowHeader(info);
    LoadReactions();
    ShowSecurity(info);
    // a mailing list that says how to leave it
    unsubscribeKind_ = file ? PE_UNSUBSCRIBE_NONE : info->unsubscribe;
    unsubscribeLink_ = Text(info->unsubscribe_link);
    unsubscribeTarget_ = Text(info->unsubscribe_target);
    ShowListBar(Text(info->list_bar), Text(info->list_button));
    ShowLogo(info->has_logo && !file, file ? 0 : info->picture);
    // the message, or its conversation, in the stack: a frame for each open message, its body a WebView2 of its own
    // sized to its document, the frames of the same messages kept (the same view again stays where it was)
    bool again = std::exchange(documentShown_, true);
    FillStrip(info);
    ShowStack(true);
    stack_.Show(view_.get(), info->pictures_loaded || remoteImages_, !again);
    // the frames point into the new view now
    stackView_.reset();
    // offered while an open message has pictures on the internet not shown: the selected one, else another one that is
    // neither signed nor encrypted (their pictures load on a click of their own), until they are shown
    bool blocked = info->remote_images && !info->pictures_loaded && !remoteImages_;
    for (size_t i = 0; !blocked && i < info->conversation_entry_count; i++) {
        const PeConversationEntry* entry = pe_conversation_entry(view_.get(), i);
        const PeMessageInfo* own = entry && entry->open && !entry->selected ? pe_message_view_info(pe_conversation_entry_view(view_.get(), i)) : nullptr;
        blocked = own && own->remote_images && !own->pictures_loaded && own->protection == PE_PROTECTION_TONE_NONE;
    }
    ShowBars(info->attachment_count > 0, blocked);
    holdLayout_ = false;
    Layout();
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

void Reader::LoadReactions() {
    std::shared_ptr<PeReactions> list;
    if (uid_ && file_.empty()) {
        list.reset(pe_reactions(core_, folder_, uid_), pe_reactions_free);
    }
    size_t count = pe_reactions_count(list.get());
    // its words are also its name for screen readers, and what the UI test reads
    std::wstring text;
    for (size_t i = 0; i < count; i++) {
        if (const PeReaction* reaction = pe_reactions_get(list.get(), i)) {
            text += (text.empty() ? ReactionsLabel() : kChipGap) + Text(reaction->text);
        }
    }
    bool was = reactionList_ != nullptr;
    reactionList_ = text.empty() ? nullptr : std::move(list);
    if (text != GetWindowString(reactions_)) {
        SetWindowTextW(reactions_, text.c_str());
        InvalidateRect(reactions_, nullptr, FALSE);
    }
    if (was == (reactionList_ != nullptr)) {
        return;
    }
    if (!reactionList_ && GetFocus() == reactions_) {
        // the line goes from under the keyboard: to the message
        SetFocus(previewHost_);
    }
    ShowWindow(reactions_, reactionList_ ? SW_SHOW : SW_HIDE);
    Layout();
}

void Reader::DrawReactions(const DRAWITEMSTRUCT& item) {
    HDC dc = item.hDC;
    FillRect(dc, &item.rcItem, GetSysColorBrush(COLOR_BTNFACE));
    reactionSpans_.clear();
    size_t count = pe_reactions_count(reactionList_.get());
    if (!count) {
        return;
    }
    HFONT font = reinterpret_cast<HFONT>(SendMessageW(header_, WM_GETFONT, 0, 0));
    HGDIOBJ old = SelectObject(dc, font);
    SetBkMode(dc, TRANSPARENT);
    SetTextColor(dc, GetSysColor(COLOR_BTNTEXT));
    // how wide `words` are, as DrawText draws them (the emoji in the face Windows falls back to)
    auto width = [dc, font](const std::wstring& words) { return static_cast<int>(Measure(dc, font, words, 0, DT_NOPREFIX).cx); };
    auto draw = [&](const std::wstring& words, int left) {
        RECT place = {left, item.rcItem.top, item.rcItem.right, item.rcItem.bottom};
        DrawTextW(dc, words.c_str(), static_cast<int>(words.size()), &place, DT_LEFT | DT_TOP | DT_SINGLELINE | DT_NOPREFIX | DT_END_ELLIPSIS);
    };
    std::wstring label = ReactionsLabel();
    draw(label, item.rcItem.left);
    int x = item.rcItem.left + width(label), gap = width(kChipGap);
    for (size_t i = 0; i < count && x < item.rcItem.right; i++) {
        const PeReaction* reaction = pe_reactions_get(reactionList_.get(), i);
        std::wstring chip = reaction ? Text(reaction->text) : L"";
        int right = std::min(x + width(chip), static_cast<int>(item.rcItem.right));
        draw(chip, x);
        reactionSpans_.emplace_back(x, right);
        x = right + gap;
    }
    SelectObject(dc, old);
    if (GetFocus() == item.hwndItem && !reactionSpans_.empty()) {
        RECT focus = {reactionSpans_.front().first - Scale(2), item.rcItem.top, reactionSpans_.back().second + Scale(2), item.rcItem.bottom};
        DrawFocusRect(dc, &focus);
    }
}

int Reader::ReactionAt(int x) const {
    for (size_t i = 0; i < reactionSpans_.size(); i++) {
        if (x >= reactionSpans_[i].first && x < reactionSpans_[i].second) {
            return static_cast<int>(i);
        }
    }
    return -1;
}

void Reader::ReactionsMenu(int chip, POINT screen) {
    // the list it is made from, kept while the menu is open: a reaction coming meanwhile reads the core's list again
    std::shared_ptr<PeReactions> list = reactionList_;
    size_t count = pe_reactions_count(list.get());
    if (!count) {
        return;
    }
    // a person's items: Open Reaction Email (the default, as a double-click does), Show as Email, and when they reacted
    auto items = [&](HMENU menu, size_t index) {
        const PeReaction* reaction = pe_reactions_get(list.get(), index);
        UINT open = static_cast<UINT>(1 + 2 * index);
        AppendMenuW(menu, MF_STRING, open, core::T(PE_TEXT_UI_REACTION_OPEN_EMAIL).c_str());
        AppendMenuW(menu, MF_STRING, open + 1, core::T(PE_TEXT_UI_REACTION_SHOW_AS_EMAIL).c_str());
        if (reaction && reaction->when && *reaction->when) {
            AppendMenuW(menu, MF_SEPARATOR, 0, nullptr);
            AppendMenuW(menu, MF_STRING | MF_GRAYED, 0, MenuText(core::T(PE_TEXT_UI_REACTION_WHEN, {{"when", Text(reaction->when)}})).c_str());
        }
        SetMenuDefaultItem(menu, open, FALSE);
    };
    HMENU menu = CreatePopupMenu();
    if (chip >= 0 || count == 1) {
        // the person under the mouse, or the only one
        items(menu, chip >= 0 ? static_cast<size_t>(chip) : 0);
    } else {
        // a submenu a person, named by their chip
        for (size_t i = 0; i < count; i++) {
            const PeReaction* reaction = pe_reactions_get(list.get(), i);
            HMENU person = CreatePopupMenu();
            items(person, i);
            AppendMenuW(menu, MF_POPUP, reinterpret_cast<UINT_PTR>(person), MenuText(reaction ? Text(reaction->text) : L"").c_str());
        }
    }
    if (screen.x == -1 && screen.y == -1) {
        // the keyboard's: under the chip, or under the chips
        RECT line;
        GetWindowRect(reactions_, &line);
        int left = reactionSpans_.empty() ? 0 : reactionSpans_[chip >= 0 ? static_cast<size_t>(chip) : 0].first;
        screen = {line.left + left, line.bottom};
    }
    UINT command = static_cast<UINT>(TrackPopupMenu(menu, TPM_RETURNCMD | TPM_RIGHTBUTTON | TPM_LEFTALIGN | TPM_TOPALIGN, screen.x,
                                                    screen.y, 0, parent_, nullptr));
    DestroyMenu(menu);
    if (command == 0) {
        return;
    }
    size_t index = (command - 1) / 2;
    if ((command - 1) % 2 == 0) {
        OpenReactionEmail(list, index);
        return;
    }
    // listed again for good, the reaction off the message: the line read again at once
    pe_reactions_show_as_email(core_, list.get(), index);
    LoadReactions();
}

void Reader::OpenReactionEmail(const std::shared_ptr<PeReactions>& list, size_t chip) {
    core::String path(pe_reactions_email_file(core_, list.get(), chip));
    if (!path) {
        // no longer kept (gone from the server)
        MessageBoxApp(parent_, core::T(PE_TEXT_UI_NOT_SHOWN).c_str(), L"Inbox Classic", MB_OK | MB_ICONINFORMATION);
        return;
    }
    if (onOpenFile) {
        onOpenFile(Text(path.get()));
    }
}

// the Reactions line's own mouse and keys: the menu on a person (right-click), or the one of everyone (the menu key,
// Shift+F10, a right-click between chips); a double-click on a person opens their reaction email; the focus drawn
LRESULT CALLBACK Reader::ReactionsProc(HWND hwnd, UINT message, WPARAM wParam, LPARAM lParam, UINT_PTR, DWORD_PTR data) {
    auto* reader = reinterpret_cast<Reader*>(data);
    switch (message) {
    case WM_CONTEXTMENU: {
        POINT screen = {GET_X_LPARAM(lParam), GET_Y_LPARAM(lParam)};
        int chip = -1;
        if (screen.x != -1 || screen.y != -1) {
            POINT inside = screen;
            ScreenToClient(hwnd, &inside);
            chip = reader->ReactionAt(inside.x);
        }
        reader->ReactionsMenu(chip, screen);
        return 0;
    }
    case WM_LBUTTONDOWN:
    case WM_RBUTTONDOWN:
        SetFocus(hwnd);
        break;
    case WM_LBUTTONDBLCLK:
        if (int chip = reader->ReactionAt(GET_X_LPARAM(lParam)); chip >= 0 && reader->reactionList_) {
            reader->OpenReactionEmail(reader->reactionList_, static_cast<size_t>(chip));
        }
        return 0;
    case WM_SETFOCUS:
    case WM_KILLFOCUS:
        InvalidateRect(hwnd, nullptr, FALSE);
        break;
    case WM_NCDESTROY:
        RemoveWindowSubclass(hwnd, ReactionsProc, 0);
        break;
    }
    return DefSubclassProc(hwnd, message, wParam, lParam);
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
    if (chosen != 0) {
        SaveAttachment(static_cast<size_t>(chosen - 1));
    }
}

void Reader::SaveAttachment(size_t index) {
    if (!file_.empty()) {
        size_t length = 0;
        char* name = nullptr;
        uint8_t* data = pe_file_attachment_data(core_, core::Narrow(file_).c_str(), index, &length, &name);
        SaveRead(data, length, name);
        return;
    }
    // read (and decrypted) off the window thread: the dialog once it is here (ReadDone)
    if (!saveRead_.Start(core_, pe_attachment_data_start(core_, folder_, uid_, index))) {
        SayNotHere();
    }
}

void Reader::SaveRead(uint8_t* data, size_t length, char* name) {
    core::String safeName(name);
    if (!data) {
        SayNotHere();
        return;
    }
    std::wstring path = SaveFileDialog(parent_, Text(safeName.get()));
    if (!path.empty()) {
        if (WriteFileBytes(path, data, length)) {
            MarkFromInternet(path);
        } else {
            MessageBoxApp(parent_, core::T(PE_TEXT_UI_ATTACHMENT_NOT_SAVED).c_str(), L"Inbox Classic", MB_OK | MB_ICONERROR);
        }
    }
    pe_bytes_free(data, length);
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
        MessageBoxApp(parent_, core::T(PE_TEXT_UI_NOT_DOWNLOADED).c_str(), L"Inbox Classic", MB_OK | MB_ICONINFORMATION);
    } else if (saved < total) {
        std::wstring text =
            core::T(PE_TEXT_WIN_FILES_NOT_SAVED, {{"failed", std::to_wstring(total - saved)}, {"count", std::to_wstring(total)}});
        MessageBoxApp(parent_, text.c_str(), L"Inbox Classic", MB_OK | MB_ICONERROR);
    }
}

// ---- the attachment strip ----

const PeAttachment* Reader::StripAttachment(int item, size_t* index) const {
    LVITEMW row = {};
    row.mask = LVIF_PARAM;
    row.iItem = item;
    if (item < 0 || !ListView_GetItem(strip_, &row)) {
        return nullptr;
    }
    if (index) {
        *index = static_cast<size_t>(row.lParam);
    }
    return pe_message_view_attachment(view_.get(), static_cast<size_t>(row.lParam));
}

int Reader::StripItemOf(int64_t index) const {
    int count = ListView_GetItemCount(strip_);
    for (int item = 0; index >= 0 && item < count; item++) {
        LVITEMW row = {};
        row.mask = LVIF_PARAM;
        row.iItem = item;
        if (ListView_GetItem(strip_, &row) && row.lParam == static_cast<LPARAM>(index)) {
            return item;
        }
    }
    return -1;
}

void Reader::SayNotHere() {
    // a large message shows its text before the rest of it is here
    bool downloading = file_.empty() && pe_message_downloading(core_, folder_, uid_);
    std::wstring why = core::T(downloading ? PE_TEXT_UI_ATTACHMENT_DOWNLOADING : PE_TEXT_UI_ATTACHMENT_NOT_READ);
    MessageBoxApp(parent_, why.c_str(), L"Inbox Classic", MB_OK | (downloading ? MB_ICONINFORMATION : MB_ICONERROR));
}

void Reader::FillStrip(const PeMessageInfo* info) {
    // the same files as shown (the message shown again, with its pictures, say): the strip as it is, its choice kept
    std::vector<std::wstring> files;
    for (size_t i = 0; info && i < info->attachment_count; i++) {
        if (const PeAttachment* attachment = pe_message_view_attachment(view_.get(), i)) {
            files.push_back(Text(attachment->filename) + L"\n" + Text(attachment->size_text) + L"\n" +
                            std::to_wstring(static_cast<int>(attachment->kind)) + L"\n" + Text(attachment->part_text));
        }
    }
    if (files == stripFiles_) {
        return;
    }
    stripFiles_ = std::move(files);
    SendMessageW(strip_, WM_SETREDRAW, FALSE, 0);
    ListView_DeleteAllItems(strip_);
    // one DC for every label, in the strip's font
    HDC dc = CreateCompatibleDC(nullptr);
    HGDIOBJ font = SelectObject(dc, reinterpret_cast<HFONT>(SendMessageW(strip_, WM_GETFONT, 0, 0)));
    int widest = 0;
    for (size_t i = 0; info && i < info->attachment_count; i++) {
        const PeAttachment* attachment = pe_message_view_attachment(view_.get(), i);
        if (!attachment) {
            continue;
        }
        std::wstring label = StripLabel(dc, *attachment, Scale(220));
        LVITEMW item = {};
        item.mask = LVIF_TEXT | LVIF_IMAGE | LVIF_PARAM | LVIF_STATE;
        item.iItem = ListView_GetItemCount(strip_);
        item.pszText = label.data();
        item.iImage = KindIcon(attachment->kind);
        item.lParam = static_cast<LPARAM>(i);
        // a file of an encrypted part has the lock of the part's label (shown decrypted, not encrypted now)
        item.stateMask = LVIS_OVERLAYMASK;
        item.state = attachment->protection == PE_PROTECTION_ENCRYPTED ? INDEXTOOVERLAYMASK(1) : 0;
        int inserted = ListView_InsertItem(strip_, &item);
        // its part for a screen reader ("From part 2: Encrypted. Not signed"), as the end of its tooltip says
        SetAccessibleDescription(strip_, Text(attachment->part_text), inserted + 1);
        widest = std::max(widest, ListView_GetStringWidth(strip_, label.c_str()));
    }
    SelectObject(dc, font);
    DeleteDC(dc);
    // the columns as wide as the widest label with its icon, and a gap
    int icon = 0;
    ImageList_GetIconSize(IconList(IconSet::Files), &icon, &icon);
    ListView_SetColumnWidth(strip_, 0, std::max(Scale(120), widest + icon + Scale(24)));
    SendMessageW(strip_, WM_SETREDRAW, TRUE, 0);
    InvalidateRect(strip_, nullptr, TRUE);
}

// as few rows as its columns fit in at this width, four at most (it scrolls sideways past them), in its frame with a
// margin: the frame's height, 0 when it is hidden. In its List mode the list view lays out as many rows as fit above
// a scroll bar, whether one is shown or not; the frame shows that room only when the bar is in it.
int Reader::PlaceStrip(int left, int top, int width) {
    int count = ListView_GetItemCount(strip_);
    if (!IsWindowVisible(stripFrame_) || count == 0) {
        return 0;
    }
    constexpr int kMostRows = 4;
    RECT item = {};
    ListView_GetItemRect(strip_, 0, &item, LVIR_BOUNDS);
    int rowHeight = std::max(1L, item.bottom - item.top);
    int columnWidth = std::max(1, ListView_GetColumnWidth(strip_, 0));
    int edges = 2 * GetSystemMetrics(SM_CXEDGE);
    int margin = Scale(3);
    int inner = std::max(1, width - edges - 2 * margin);
    int across = std::max(1, inner / columnWidth);
    int rows = std::min((count + across - 1) / across, kMostRows);
    int scrollBar = GetSystemMetrics(SM_CYHSCROLL);
    int listHeight = rows * rowHeight + scrollBar;
    bool scrolls = count > rows * across;
    int shown = scrolls ? listHeight : rows * rowHeight;
    MoveWindow(stripFrame_, left, top, width, shown + 2 * margin + edges, TRUE);
    MoveWindow(strip_, margin, margin, inner, listHeight, TRUE);
    return shown + 2 * margin + edges;
}

void Reader::OpenAttachment(int item) {
    size_t index = 0;
    const PeAttachment* attachment = StripAttachment(item, &index);
    if (!attachment) {
        return;
    }
    // a file that can run code: refused from its row, in the core's words
    if (!attachment->can_open) {
        MessageBoxApp(parent_, Text(attachment->refusal).c_str(), L"Inbox Classic", MB_OK | MB_ICONWARNING);
        return;
    }
    // one at a time: a double-click while one is opened waits for it
    if (openingItem_ >= 0) {
        return;
    }
    if (opener_.joinable()) {
        opener_.join();
    }
    openingItem_ = item;
    SetTimer(strip_, TIMER_STRIP_BUSY, PE_LIST_LOADING_MS, nullptr);
    // reading (and decrypting) the message and writing the file off the window thread: a folder's message by the core
    // (ReadDone), a message file on a thread of its own whose result comes back to the strip, or is dropped with it
    // when the window closed first
    if (file_.empty()) {
        openRequest_ = pe_attachment_open_start(core_, folder_, uid_, index);
        if (!openRequest_) {
            OpenDone(new StripOpened{item, L"", L"", L""});
        }
        return;
    }
    opener_ = std::thread([strip = strip_, core = core_, file = core::Narrow(file_), index, item] {
        char* note = nullptr;
        char* error = nullptr;
        char* written = pe_file_attachment_open(core, file.c_str(), index, &note, &error);
        core::String path(written), noted(note), refused(error);
        auto* opened = new StripOpened{item, Text(path.get()), Text(noted.get()), Text(refused.get())};
        if (!PostMessageW(strip, WM_STRIP_OPENED, 0, reinterpret_cast<LPARAM>(opened))) {
            delete opened;
        }
    });
}

void Reader::OpenDone(StripOpened* opened) {
    std::unique_ptr<StripOpened> done(opened);
    KillTimer(strip_, TIMER_STRIP_BUSY);
    ListView_SetItemState(strip_, openingItem_, 0, LVIS_CUT);
    openingItem_ = -1;
    if (done->path.empty()) {
        if (!done->refused.empty()) {
            MessageBoxApp(parent_, done->refused.c_str(), L"Inbox Classic", MB_OK | MB_ICONWARNING);
        } else {
            SayNotHere();
        }
        return;
    }
    // an encrypted message's file, the first time: it is stored decrypted while it is open
    if (!done->note.empty()) {
        MessageBoxApp(parent_, done->note.c_str(), core::T(PE_TEXT_UI_ATTACHMENT_NOTE_TITLE).c_str(), MB_OK | MB_ICONINFORMATION);
    }
    OpenWithSystem(parent_, done->path);
}

void Reader::StopOpening() {
    if (openRequest_) {
        pe_read_cancel(core_, std::exchange(openRequest_, 0));
    }
    if (opener_.joinable()) {
        opener_.join();
    }
    if (importer_.joinable()) {
        importer_.join();
    }
    // the results they posted, which the strip would never take (an import's keys are in the key book all the same)
    MSG posted;
    while (PeekMessageW(&posted, strip_, WM_STRIP_OPENED, WM_STRIP_OPENED, PM_REMOVE)) {
        delete reinterpret_cast<StripOpened*>(posted.lParam);
    }
    while (PeekMessageW(&posted, strip_, WM_STRIP_IMPORTED, WM_STRIP_IMPORTED, PM_REMOVE)) {
        delete reinterpret_cast<StripImported*>(posted.lParam);
    }
}

void Reader::StripMenu(POINT screen) {
    int item = -1;
    if (screen.x == -1 && screen.y == -1) {
        // the keyboard's menu: at the item that has the focus, under its icon
        item = ListView_GetNextItem(strip_, -1, LVNI_FOCUSED);
        RECT icon = {};
        if (item < 0 || !ListView_GetItemRect(strip_, item, &icon, LVIR_ICON)) {
            return;
        }
        screen = {icon.left, icon.bottom};
        ClientToScreen(strip_, &screen);
    } else {
        LVHITTESTINFO hit = {};
        hit.pt = screen;
        ScreenToClient(strip_, &hit.pt);
        item = ListView_HitTest(strip_, &hit);
    }
    size_t index = 0;
    const PeAttachment* attachment = StripAttachment(item, &index);
    if (!attachment) {
        return;
    }
    enum : UINT { kOpen = 1, kSaveAs, kSaveAll, kShowInMessage, kImportKey };
    HMENU menu = CreatePopupMenu();
    // greyed for a file that can run code, which is only saved
    AppendMenuW(menu, MF_STRING | (attachment->can_open ? 0 : MF_GRAYED), kOpen, core::T(PE_TEXT_UI_ATTACHMENT_OPEN).c_str());
    if (attachment->can_open) {
        SetMenuDefaultItem(menu, kOpen, FALSE);
    }
    AppendMenuW(menu, MF_STRING, kSaveAs, core::T(PE_TEXT_UI_ATTACHMENT_SAVE_AS).c_str());
    AppendMenuW(menu, MF_SEPARATOR, 0, nullptr);
    AppendMenuW(menu, MF_STRING, kSaveAll, core::T(PE_TEXT_UI_ATTACHMENT_SAVE_ALL).c_str());
    // a file the core read as public keys (not one merely named so): into Encryption Keys
    if (attachment->is_key) {
        AppendMenuW(menu, MF_SEPARATOR, 0, nullptr);
        AppendMenuW(menu, MF_STRING, kImportKey, core::T(PE_TEXT_UI_ATTACHMENT_IMPORT_KEY).c_str());
    }
    // a picture or PDF file: drawn in the message or not (checked when it is), greyed for one that can not be
    PeShowInMessage shown = attachment->show_in_message;
    if (shown != PE_SHOW_IN_MESSAGE_NONE) {
        UINT state = (shown == PE_SHOW_IN_MESSAGE_ON ? MF_CHECKED : 0) | (shown == PE_SHOW_IN_MESSAGE_UNAVAILABLE ? MF_GRAYED : 0);
        AppendMenuW(menu, MF_SEPARATOR, 0, nullptr);
        AppendMenuW(menu, MF_STRING | state, kShowInMessage, core::T(PE_TEXT_UI_ATTACHMENT_SHOW_IN_MESSAGE).c_str());
    }
    UINT chosen = TrackPopupMenu(menu, TPM_RETURNCMD | TPM_LEFTALIGN | TPM_TOPALIGN | TPM_RIGHTBUTTON, screen.x, screen.y, 0, parent_, nullptr);
    DestroyMenu(menu);
    switch (chosen) {
    case kOpen:
        OpenAttachment(item);
        break;
    case kSaveAs:
        SaveAttachment(index);
        break;
    case kSaveAll:
        SaveAllAttachments();
        break;
    case kShowInMessage:
        ShowInMessage(index, shown != PE_SHOW_IN_MESSAGE_ON);
        break;
    case kImportKey:
        ImportAttachedKey(index);
        break;
    }
}

void Reader::ImportAttachedKey(size_t index) {
    // one at a time: the core reads (and decrypts) the message on a thread of its own, the busy pointer over the strip
    if (importing_) {
        return;
    }
    if (importer_.joinable()) {
        importer_.join();
    }
    importing_ = true;
    std::string file = file_.empty() ? std::string() : core::Narrow(file_);
    importer_ = std::thread([strip = strip_, core = core_, file, folder = folder_, uid = uid_, index] {
        char* message = nullptr;
        PeImportOutcome outcome = pe_pgp_import_attachment(core, file.empty() ? nullptr : file.c_str(), folder, uid, index, &message);
        core::String words(message);
        auto* imported = new StripImported{outcome, words ? Text(words.get()) : L""};
        if (!PostMessageW(strip, WM_STRIP_IMPORTED, 0, reinterpret_cast<LPARAM>(imported))) {
            delete imported;
        }
    });
}

void Reader::ImportDone(StripImported* imported) {
    std::unique_ptr<StripImported> done(imported);
    importing_ = false;
    std::wstring said = done->said.empty() ? core::T(PE_TEXT_UI_UNKNOWN_REASON) : done->said;
    std::wstring title = core::Plain(PE_TEXT_UI_KEYS_IMPORT_TITLE);
    bool ok = done->outcome == PE_IMPORT_OUTCOME_IMPORTED;
    MessageBoxApp(parent_, said.c_str(), title.c_str(), MB_OK | (ok ? MB_ICONINFORMATION : MB_ICONWARNING));
    if (!ok) {
        return;
    }
    OfferUnclaimed(parent_, core_);
    // a signature by that key names its signer now
    if (Info()) {
        StartView();
    }
}

void Reader::FindSignerKey(const wchar_t* uri) {
    // one at a time: a second click while it is asked waits for the first
    if (keyLookup_) {
        return;
    }
    keyLookup_ = pe_pgp_find_handle(core_, core::Narrow(uri).c_str());
    if (keyLookup_ && onKeyLookup) {
        onKeyLookup(core::T(PE_TEXT_PGP_RECIPIENT_LOOKING), false);
    }
}

void Reader::SignerKeyFound(uint64_t request) {
    if (!keyLookup_ || request != keyLookup_) {
        return;
    }
    keyLookup_ = 0;
    core::String said(pe_pgp_find_result(core_, request));
    // the label names the signer now, when the key was found
    if (Info()) {
        StartView();
    }
    if (said && onKeyLookup) {
        onKeyLookup(Text(said.get()), true);
    }
}

void Reader::ShowInMessage(size_t index, bool show) {
    // the view built again with the file drawn or taken out (ShowInfo keeps the text where it was)
    const PeMessageInfo* info = Info();
    if (info && pe_preview_show(core_, info->preview_token, index, show)) {
        StartView();
    }
}

void Reader::PreviewsPrepared(const std::string& token) {
    // the files that were "Preparing..." in the view shown are described now: it is built again with their previews,
    // its text where it was (as after Show in Message); another view's (another window's, or one no longer shown) is
    // not this one's
    const PeMessageInfo* info = Info();
    if (info && info->preview_token && *info->preview_token && token == info->preview_token) {
        StartView();
    }
}

// the strip's own keys: Enter opens the file chosen (not the window's default button), the menu key and Shift+F10
// its menu, as a right-click does (the list view sends WM_CONTEXTMENU to itself after NM_RCLICK); the result of an
// open, and the busy look of one that takes a while
LRESULT CALLBACK Reader::StripProc(HWND hwnd, UINT message, WPARAM wParam, LPARAM lParam, UINT_PTR, DWORD_PTR data) {
    auto* reader = reinterpret_cast<Reader*>(data);
    switch (message) {
    case WM_GETDLGCODE: {
        LRESULT code = DefSubclassProc(hwnd, message, wParam, lParam);
        const auto* key = reinterpret_cast<const MSG*>(lParam);
        if (key && key->message == WM_KEYDOWN && key->wParam == VK_RETURN) {
            code |= DLGC_WANTMESSAGE;
        }
        return code;
    }
    case WM_KEYDOWN:
        if (wParam == VK_RETURN) {
            reader->OpenAttachment(ListView_GetNextItem(hwnd, -1, LVNI_FOCUSED));
            return 0;
        }
        break;
    case WM_CHAR:
        // no beep for the Enter handled above
        if (wParam == L'\r') {
            return 0;
        }
        break;
    case WM_SETFOCUS: {
        LRESULT result = DefSubclassProc(hwnd, message, wParam, lParam);
        // Tab into it: the first file chosen, so the focus shows on one
        if (ListView_GetNextItem(hwnd, -1, LVNI_FOCUSED) < 0 && ListView_GetItemCount(hwnd) > 0) {
            ListView_SetItemState(hwnd, 0, LVIS_FOCUSED | LVIS_SELECTED, LVIS_FOCUSED | LVIS_SELECTED);
        }
        return result;
    }
    case WM_CONTEXTMENU:
        reader->StripMenu({GET_X_LPARAM(lParam), GET_Y_LPARAM(lParam)});
        return 0;
    case WM_STRIP_OPENED:
        reader->OpenDone(reinterpret_cast<StripOpened*>(lParam));
        return 0;
    case WM_STRIP_IMPORTED:
        reader->ImportDone(reinterpret_cast<StripImported*>(lParam));
        return 0;
    case WM_TIMER:
        if (wParam == TIMER_STRIP_BUSY) {
            // still opening: its icon dimmed and the busy pointer over the strip until it is done
            KillTimer(hwnd, TIMER_STRIP_BUSY);
            ListView_SetItemState(hwnd, reader->openingItem_, LVIS_CUT, LVIS_CUT);
            SetCursor(LoadCursorW(nullptr, IDC_APPSTARTING));
            return 0;
        }
        break;
    case WM_SETCURSOR:
        if (reader->importing_ ||
            (reader->openingItem_ >= 0 && (ListView_GetItemState(hwnd, reader->openingItem_, LVIS_CUT) & LVIS_CUT))) {
            SetCursor(LoadCursorW(nullptr, IDC_APPSTARTING));
            return TRUE;
        }
        break;
    case WM_NCDESTROY:
        RemoveWindowSubclass(hwnd, StripProc, 0);
        break;
    }
    return DefSubclassProc(hwnd, message, wParam, lParam);
}

void Reader::FindInMessage(HWND owner, bool again) {
    if (!Info()) {
        return;
    }
    if (again && Body().Finding() && Body().FindNext()) {
        return;
    }
    // no answer yet, from the moment the words are asked for
    testFound_ = -1;
    std::vector<FormField> fields = {{core::T(PE_TEXT_WIN_FIND_LABEL), findWords_}};
    if (!FormDialog(owner, core::Title(PE_TEXT_CMD_FIND_IN_MESSAGE), core::T(PE_TEXT_UI_FIND_IN_MESSAGE_HINT), fields) ||
        fields[0].value.empty()) {
        return;
    }
    findWords_ = fields[0].value;
    Body().Find(findWords_, [this, words = findWords_](int count) {
        testFound_ = count >= 0 ? count : -2;
        if (onFound && count >= 0) {
            onFound(count > 0 ? L"" : core::T(PE_TEXT_UI_FIND_NOT_FOUND, {{"words", words}}));
        }
    });
}

void Reader::Rebuild(std::vector<Reader*> readers) {
    g_rebuilds = std::move(readers);
    RebuildNext();
}

void Reader::RebuildNext() {
    while (!g_rebuilds.empty()) {
        Reader* reader = g_rebuilds.front();
        g_rebuilds.erase(g_rebuilds.begin());
        if ((reader->uid_ || !reader->file_.empty()) && reader->view_) {
            // a message file's view is built right here, a folder's message's on a worker (ShowView goes on)
            reader->rebuilding_ = reader->file_.empty();
            reader->StartView();
            reader->rebuilding_ = reader->rebuilding_ && reader->viewRequest_;
            if (reader->rebuilding_) {
                return;
            }
        }
    }
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

namespace {

// the printouts a reader stopped waiting for (another message shown, the window closed): taken from the core and
// dropped once they are made
std::vector<uint64_t> g_droppedPrints;

}  // namespace

void Reader::Print(HWND owner) {
    const PeMessageInfo* info = Info();
    if (!info) {
        return;
    }
    // a message with previews: its pictures put in by the core off the window thread (PrintReady), the busy pointer
    // meanwhile; another Print while it is made waits for the same printout
    if (printRequest_) {
        printOwner_ = owner;
        return;
    }
    if (info->preview_token && *info->preview_token) {
        if (uint64_t request = pe_print_start(core_, info->preview_token)) {
            printRequest_ = request;
            printOwner_ = owner;
            BusyStart();
            return;
        }
    }
    // the message as it is shown, with the pictures the user allowed or the core loaded
    OpenPrintWindow(owner, preview_.Environment(), info->print_document, PicturesShown(), Text(info->subject));
}

void Reader::PrintConversation(HWND owner) {
    if (!Info() || !uid_) {
        return;
    }
    if (printRequest_) {
        printOwner_ = owner;
        return;
    }
    // made off the window thread (PrintReady), the busy pointer meanwhile; outside a conversation, the message alone
    uint64_t request = pe_conversation_print_start(core_, folder_, uid_, ConversationNewestFirst());
    if (!request) {
        Print(owner);
        return;
    }
    printRequest_ = request;
    printOwner_ = owner;
    BusyStart();
}

bool Reader::ShowsConversation() const {
    const PeMessageInfo* info = pe_message_view_info(view_.get());
    return info && info->conversation_count > 0;
}

void Reader::ConversationClick(PeConversationClick click, size_t index) {
    int64_t folder = 0;
    uint64_t uid = 0;
    if (!uid_ || !pe_conversation_click(core_, folder_, uid_, click, index, &folder, &uid)) {
        return;
    }
    // the same message: its conversation built again where it was; another: downloaded first when it is not yet,
    // then shown in place (MessageReady)
    if (folder == folder_ && uid == uid_) {
        StartView();
        return;
    }
    folder_ = folder;
    uid_ = uid;
    // the pictures asked for are another message's: never carried to this one (a signed or encrypted message loads its own only on a click of its own)
    remoteImages_ = false;
    pe_message_open(core_, folder, uid);
}

bool Reader::ConversationCommand(WORD id) {
    switch (id) {
    case IDM_NEXT_IN_CONVERSATION:
        ConversationClick(PE_CONVERSATION_CLICK_NEXT);
        return true;
    case IDM_PREVIOUS_IN_CONVERSATION:
        ConversationClick(PE_CONVERSATION_CLICK_PREVIOUS);
        return true;
    case IDM_OPEN_ALL_MESSAGES:
        ConversationClick(PE_CONVERSATION_CLICK_OPEN_ALL);
        return true;
    case IDM_FOLD_ALL_MESSAGES:
        ConversationClick(PE_CONVERSATION_CLICK_FOLD_ALL);
        return true;
    default:
        return false;
    }
}

void Reader::PrintReady(uint64_t request) {
    if (std::erase(g_droppedPrints, request) > 0) {
        core::String dropped(pe_print_result(core_, request));
        return;
    }
    if (!printRequest_ || request != printRequest_) {
        return;
    }
    printRequest_ = 0;
    BusyEnd();
    core::String document(pe_print_result(core_, request));
    const PeMessageInfo* info = Info();
    if (document && info && IsWindow(printOwner_)) {
        OpenPrintWindow(printOwner_, preview_.Environment(), document.get(), PicturesShown(), Text(info->subject));
    }
}

void Reader::ForgetPrint() {
    if (printRequest_) {
        g_droppedPrints.push_back(std::exchange(printRequest_, 0));
        BusyEnd();
    }
}

bool Reader::DraftOf(PeDraftKind kind, int64_t account, std::function<void(core::Draft)> done) {
    if (!file_.empty() && view_) {
        done(core::Draft(pe_file_draft(core_, core::Narrow(file_).c_str(), account, kind)));
        return true;
    }
    if (!uid_ || !view_) {
        return false;
    }
    // the message read (and decrypted) off the window thread: `done` once it is (ReadDone)
    if (!draftRead_.Start(core_, pe_message_draft_start(core_, folder_, uid_, kind))) {
        done(core::Draft());
        return true;
    }
    draftDone_ = std::move(done);
    return true;
}

void Reader::CancelReads() {
    draftRead_.Reset();
    saveRead_.Reset();
    draftDone_ = nullptr;
}

std::wstring Reader::Unsubscribe(HWND owner, core::Draft& draft) {
    if (!CanUnsubscribe()) {
        return L"";
    }
    const std::wstring& target = unsubscribeTarget_;
    std::wstring detail;
    switch (unsubscribeKind_) {
    case PE_UNSUBSCRIBE_ONE_CLICK:
        detail = core::T(PE_TEXT_UI_LEAVE_ONE_CLICK, {{"target", target}});
        break;
    case PE_UNSUBSCRIBE_MAIL:
        detail = core::T(PE_TEXT_UI_LEAVE_MAIL, {{"target", target}});
        break;
    case PE_UNSUBSCRIBE_WEB:
        detail = core::T(PE_TEXT_UI_LEAVE_WEB, {{"target", target}});
        break;
    default:
        return L"";
    }
    // the classic message box: Yes and No, as every question of the Windows app asks
    std::wstring question = core::T(PE_TEXT_UI_LEAVE_LIST) + L"\n\n" + detail;
    if (MessageBoxApp(owner, question.c_str(), core::T(PE_TEXT_UI_UNSUBSCRIBE).c_str(), MB_YESNO | MB_ICONQUESTION) != IDYES) {
        return L"";
    }
    switch (unsubscribeKind_) {
    case PE_UNSUBSCRIBE_ONE_CLICK:
        unsubscribeRequest_ = pe_unsubscribe(core_, folder_, uid_);
        return unsubscribeRequest_ ? core::T(PE_TEXT_UI_UNSUBSCRIBING, {{"target", target}}) : core::T(PE_TEXT_UI_CANNOT_UNSUBSCRIBE);
    case PE_UNSUBSCRIBE_MAIL:
        draft.reset(pe_unsubscribe_draft(core_, folder_, uid_));
        return draft ? L"" : core::T(PE_TEXT_UI_CANNOT_UNSUBSCRIBE);
    default:
        webview::OpenExternally(unsubscribeLink_.c_str());
        pe_unsubscribe_opened(core_, folder_, uid_);
        return L"";
    }
}

bool Reader::CanUnsubscribe() const {
    return IsWindowVisible(listBar_) && IsWindowVisible(listButton_);
}

void Reader::ShowListBar(const std::wstring& text, const std::wstring& button) {
    bool shown = !text.empty(), offered = shown && !button.empty();
    if (!offered && GetFocus() == listButton_) {
        SetFocus(previewHost_);
    }
    SetWindowTextW(listBar_, (L" " + text).c_str());
    SetWindowTextW(listButton_, button.c_str());
    // a screen reader on the button says what it is about
    SetAccessibleDescription(listButton_, text);
    bool changed = (IsWindowVisible(listBar_) != FALSE) != shown || (IsWindowVisible(listButton_) != FALSE) != offered;
    ShowWindow(listBar_, shown ? SW_SHOW : SW_HIDE);
    ShowWindow(listButton_, offered ? SW_SHOW : SW_HIDE);
    if (changed || offered) {
        Layout();
    }
}

void Reader::ListsChanged() {
    if (!uid_ || unsubscribeKind_ == PE_UNSUBSCRIBE_NONE) {
        return;
    }
    PeListBar bar = pe_list_bar(core_, folder_, uid_);
    ShowListBar(Text(bar.text), Text(bar.button));
    pe_list_bar_free(bar);
}

std::wstring Reader::Unsubscribed(uint64_t request, const std::wstring& problem) {
    if (!request || request != unsubscribeRequest_) {
        return L"";
    }
    unsubscribeRequest_ = 0;
    return problem.empty() ? core::T(PE_TEXT_UI_UNSUBSCRIBED) : core::T(PE_TEXT_UI_NOT_UNSUBSCRIBED, {{"reason", problem}});
}

// the logo is asked for when the message has one the server passed, and shown once it is drawn (LogoReady); without
// one, the sender's picture of the Address Book in its place (PictureReady)
void Reader::ShowLogo(bool logo, uint64_t picture) {
    stack_.SetSelectedPicture(nullptr, 0);
    if (logoBitmap_) {
        DeleteObject(logoBitmap_);
        logoBitmap_ = nullptr;
    }
    logoRequest_ = 0;
    // the header back over the logo's place, which would stay empty beside it
    if (ShowWindow(logo_, SW_HIDE)) {
        Layout();
    }
    logoSize_ = Scale(48);
    contactPicture_ = !logo && picture;
    if (logo) {
        logoRequest_ = pe_logo_start(core_, folder_, uid_, static_cast<uint32_t>(logoSize_));
    } else if (picture) {
        logoRequest_ = pe_picture_start(core_, picture, static_cast<uint32_t>(logoSize_));
    }
}

// the logo's or the picture's pixels from the core, BGRA with the alpha multiplied in, beside the header
void Reader::ShowDrawn(uint8_t* pixels, size_t length) {
    logoBitmap_ = CoreBitmap(pixels, length, logoSize_);
    // the message shown in the stack: its frame's picture, not the header's
    if (logoBitmap_ && stack_.Visible()) {
        stack_.SetSelectedPicture(logoBitmap_, logoSize_);
        return;
    }
    if (logoBitmap_) {
        ShowWindow(logo_, SW_SHOW);
        Layout();
        InvalidateRect(logo_, nullptr, TRUE);
    }
}

// the calendar part as a file of its own (the core writes it, and only it), for the calendar program
void Reader::OpenInCalendar() {
    // a private folder of the user's, which the core cleans once a day old
    core::String dir(pe_private_folder(core_, "invitations"));
    core::String path(!dir                ? nullptr
                      : file_.empty()     ? pe_invitation_file(core_, folder_, uid_, dir.get())
                                          : pe_file_invitation_file(core_, core::Narrow(file_).c_str(), dir.get()));
    if (!path) {
        MessageBoxApp(parent_, core::T(PE_TEXT_UI_INVITATION_NOT_READ).c_str(), L"Inbox Classic", MB_OK | MB_ICONERROR);
        return;
    }
    // marked as from the internet by the core, which wrote it
    std::wstring file = Text(path.get());
    if (reinterpret_cast<INT_PTR>(ShellExecuteW(parent_, L"open", file.c_str(), nullptr, nullptr, SW_SHOWNORMAL)) <= 32) {
        MessageBoxApp(parent_, core::T(PE_TEXT_UI_NO_CALENDAR).c_str(), L"Inbox Classic", MB_OK | MB_ICONINFORMATION);
    }
}

bool Reader::OnDrawItem(const DRAWITEMSTRUCT& item) {
    if (item.hwndItem == picturesMenu_) {
        // a push button with a small arrow down, the drop-down part beside Download Pictures
        RECT face = item.rcItem;
        bool pushed = (item.itemState & ODS_SELECTED) != 0;
        DrawFrameControl(item.hDC, &face, DFC_BUTTON, DFCS_BUTTONPUSH | (pushed ? DFCS_PUSHED : 0));
        if (item.itemState & ODS_FOCUS) {
            RECT focus = item.rcItem;
            InflateRect(&focus, -Scale(3), -Scale(3));
            DrawFocusRect(item.hDC, &focus);
        }
        int shift = pushed ? 1 : 0;
        int cx = (item.rcItem.left + item.rcItem.right) / 2 + shift, cy = (item.rcItem.top + item.rcItem.bottom) / 2 + shift;
        int half = Scale(4);
        POINT points[] = {{cx - half, cy - half / 2}, {cx + half + 1, cy - half / 2}, {cx, cy + half / 2 + 1}};
        HBRUSH ink = CreateSolidBrush(GetSysColor(COLOR_BTNTEXT));
        HGDIOBJ oldBrush = SelectObject(item.hDC, ink);
        HGDIOBJ oldPen = SelectObject(item.hDC, GetStockObject(NULL_PEN));
        Polygon(item.hDC, points, 3);
        SelectObject(item.hDC, oldPen);
        SelectObject(item.hDC, oldBrush);
        DeleteObject(ink);
        return true;
    }
    if (item.hwndItem == security_) {
        int reserved = ButtonWidth({GetWindowString(securityDetails_)}) + DetailsMargin();
        DrawSecurityBar(item.hDC, item.rcItem, securityTone_, securityLock_, GetWindowString(security_), bold_, reserved);
        return true;
    }
    if (item.hwndItem == reactions_) {
        DrawReactions(item);
        return true;
    }
    if (item.hwndItem == logo_) {
        // the logo, its own transparency kept, in the middle of its place beside the header
        FillRect(item.hDC, &item.rcItem, GetSysColorBrush(COLOR_BTNFACE));
        if (logoBitmap_) {
            int x = (item.rcItem.left + item.rcItem.right - logoSize_) / 2;
            int y = (item.rcItem.top + item.rcItem.bottom - logoSize_) / 2;
            DrawPremultiplied(item.hDC, x, y, logoBitmap_, logoSize_);
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
    if (header->hwndFrom != strip_) {
        return false;
    }
    if (header->code == LVN_ITEMACTIVATE) {
        // a double-click (Enter is the strip's own, StripProc)
        OpenAttachment(reinterpret_cast<NMITEMACTIVATE*>(header)->iItem);
        return true;
    }
    if (header->code == LVN_GETINFOTIPW) {
        // the core's: the whole name and size, and for a file that can run code why it does not open
        auto* tip = reinterpret_cast<NMLVGETINFOTIPW*>(header);
        const PeAttachment* attachment = StripAttachment(tip->iItem);
        if (attachment && tip->pszText && tip->cchTextMax > 0) {
            std::wstring text = WithCrlf(Text(attachment->tooltip));
            wcsncpy_s(tip->pszText, static_cast<size_t>(tip->cchTextMax), text.c_str(), _TRUNCATE);
        }
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
    case IDC_SECURITY_DETAILS:
        ShowSecurityDetails(std::exchange(detailsPart_, -1));
        return true;
    case IDC_OPEN_PREVIEW:
        OpenAttachment(StripItemOf(std::exchange(previewOpen_, -1)));
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
        Body().FindSettled();
        return true;
    }
    if (id != TIMER_DOWNLOADING) {
        return false;
    }
    KillTimer(parent_, TIMER_DOWNLOADING);
    ShowDownloading();
    return true;
}

// a read this pane started is done (another's is not its own)
void Reader::OnReadDone(uint64_t request) {
    if (!request) {
        return;
    }
    if (draftRead_.Done(request)) {
        auto done = std::exchange(draftDone_, nullptr);
        core::Draft draft(pe_draft_result(core_, request));
        if (done) {
            done(std::move(draft));
        }
    } else if (saveRead_.Done(request)) {
        size_t length = 0;
        char* name = nullptr;
        uint8_t* data = pe_attachment_data_result(core_, request, &length, &name);
        SaveRead(data, length, name);
    } else if (request == openRequest_) {
        openRequest_ = 0;
        char* note = nullptr;
        char* error = nullptr;
        core::String path(pe_attachment_open_result(core_, request, &note, &error)), noted(note), refused(error);
        OpenDone(new StripOpened{openingItem_, Text(path.get()), Text(noted.get()), Text(refused.get())});
    }
}

void Reader::OnEvent(const UiEvent& event) {
    switch (event.kind) {
    case PE_EVENT_KIND_LISTS_CHANGED:
        ListsChanged();
        break;
    case PE_EVENT_KIND_FOLDER_CHANGED:
        // a reaction came for the message shown, or was shown as an email
        if (uid_ && file_.empty() && event.folder == folder_) {
            LoadReactions();
        }
        break;
    case PE_EVENT_KIND_MESSAGE_READY:
        if (uid_ && event.folder == folder_ && event.uid == uid_) {
            KillTimer(parent_, TIMER_DOWNLOADING);
            ShowRetry(false);
            StartView();
        } else if (view_ && pe_message_view_waits_for(view_.get(), event.folder, event.uid)) {
            // an open message of the conversation shown is downloaded: the conversation built again, where it was
            StartView();
        }
        break;
    case PE_EVENT_KIND_MESSAGE_FAILED:
        if (uid_ && event.folder == folder_ && event.uid == uid_) {
            KillTimer(parent_, TIMER_DOWNLOADING);
            ShowBars(false, false);
            ShowRetry(true);
            documentShown_ = false;
            ShowStack(false);
            preview_.ShowState(PE_READER_STATE_FAILED, event.failure, core::Narrow(event.message));
        }
        break;
    case PE_EVENT_KIND_SYNC_FINISHED:
        // the account is back: a message it could not give is tried again
        if (event.failure == PE_FAILURE_KIND_NONE && IsWindowVisible(retry_) && account_ && account_ == event.account) {
            Retry();
        }
        break;
    case PE_EVENT_KIND_READ_DONE:
        OnReadDone(event.uid);
        break;
    case PE_EVENT_KIND_PRINT_READY:
        PrintReady(event.uid);
        break;
    case PE_EVENT_KIND_KEYS_FOUND:
        SignerKeyFound(event.uid);
        break;
    case PE_EVENT_KIND_VIEW_READY:
        // a view for a message that is no longer shown was cancelled, its event is not this one
        if (viewRequest_ && event.uid == viewRequest_) {
            ShowView();
        }
        break;
    case PE_EVENT_KIND_PREVIEWS_PREPARED:
        PreviewsPrepared(event.detail);
        break;
    case PE_EVENT_KIND_LOGO_READY:
    case PE_EVENT_KIND_PICTURE_READY:
        if (event.kind == PE_EVENT_KIND_PICTURE_READY) {
            stack_.PictureReady(event.uid);
        }
        // the request is the one asked for, of its kind (the list's pictures have requests of their own)
        if (logoRequest_ && event.uid == logoRequest_ && (event.kind == PE_EVENT_KIND_PICTURE_READY) == contactPicture_) {
            logoRequest_ = 0;
            size_t length = 0;
            uint8_t* pixels = contactPicture_ ? pe_picture_result(core_, event.uid, &length) : pe_logo_result(core_, event.uid, &length);
            ShowDrawn(pixels, length);
        }
        break;
    default:
        break;
    }
}
