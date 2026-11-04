// Inbox Classic: the main window in the Outlook Express layout, folders on the left, the message list on the top
// right and the reading pane below it, with splitters between them. All mail data comes from the Rust core
// (core.h); this file draws the frame and hands the core's events to the panes.
#include <objbase.h>
#include <shellapi.h>
#include <shlobj.h>
#include <shobjidl.h>
#include <wrl/client.h>

#include <algorithm>
#include <functional>
#include <set>

#include "app.h"
#include "icons.h"

#define WIDEN2(text) L##text
#define WIDEN(text) WIDEN2(text)
#define APP_VERSION_W WIDEN(APP_VERSION)

namespace {

const wchar_t* kMainClass = L"InboxClassicMain";
const wchar_t* kTitle = L"Inbox Classic";
// sync every account this often, in milliseconds
constexpr UINT kSyncInterval = 10 * 60 * 1000;
constexpr UINT_PTR TIMER_SYNC = 2;

HWND g_main = nullptr;
HWND g_toolbar = nullptr;
HWND g_status = nullptr;
// the band under the toolbar with the name of the selected folder, as Outlook Express has it
HWND g_folderBar = nullptr;
// its dark grey, under white text
constexpr COLORREF kFolderBarColor = RGB(0x80, 0x80, 0x80);
HFONT g_folderFont = nullptr;
HBRUSH g_folderBrush = nullptr;
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
                                 event->message ? core::Widen(event->message) : std::wstring(),
                                 event->detail ? std::string(event->detail) : std::string(), event->count};
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

// the selected folder in the folder bar and the title: "Inbox - Inbox Classic"
void ShowFolderName() {
    std::wstring name = g_mailbox.SelectedName();
    SetWindowTextW(g_folderBar, (L" " + name).c_str());
    g_mailbox.UpdateSearchBar();
    SetWindowTextW(g_main, name.empty() ? kTitle : (name + L" - " + kTitle).c_str());
}

// the toolbar's Junk button, Not Junk for a message in a Junk folder
void UpdateJunkButton() {
    bool inJunk = g_mailbox.InJunk();
    int from = inJunk ? IDM_JUNK : IDM_NOT_JUNK, to = inJunk ? IDM_NOT_JUNK : IDM_JUNK;
    if (SendMessageW(g_toolbar, TB_COMMANDTOINDEX, from, 0) < 0) {
        return;
    }
    TBBUTTONINFOW info = {sizeof(info)};
    info.dwMask = TBIF_COMMAND | TBIF_TEXT | TBIF_IMAGE;
    info.idCommand = to;
    info.pszText = const_cast<wchar_t*>(inJunk ? L"Not Junk" : L"Junk");
    info.iImage = inJunk ? ICON_MAIL_CHECKMARK : ICON_MAIL_PROHIBITED;
    SendMessageW(g_toolbar, TB_SETBUTTONINFOW, from, reinterpret_cast<LPARAM>(&info));
    // the row of buttons as wide as their labels again
    SendMessageW(g_toolbar, TB_AUTOSIZE, 0, 0);
}

void ShowCounts() {
    std::wstring counts = g_mailbox.Counts();
    SendMessageW(g_status, SB_SETTEXTW, 2, reinterpret_cast<LPARAM>(counts.c_str()));
    // the folder bar says how many a search found
    ShowFolderName();
}

// ---- the tray ----

// File > Exit, the tray's Exit or Windows shutting down: closing ends the app rather than hiding it in the tray
bool g_exiting = false;

const wchar_t* kNotifyPreference = L"NewMailNotifications";
// Tools > Notify of New Mail, read once
bool g_notify = GetPreference(kNotifyPreference, 1) != 0;
const wchar_t* kTrayNotePreference = L"TrayNoteShown";

// the window back from the tray (or the taskbar), in front
void ShowMain() {
    if (IsIconic(g_main)) {
        ShowWindow(g_main, SW_RESTORE);
    } else {
        ShowWindow(g_main, SW_SHOW);
    }
    SetForegroundWindow(g_main);
}

// the window's close button: the app keeps checking mail from the tray; the first time it says so
void HideToTray() {
    ShowWindow(g_main, SW_HIDE);
    if (!GetPreference(kTrayNotePreference, 0)) {
        SetPreference(kTrayNotePreference, 1);
        TrayNotify(g_main, L"Inbox Classic is still running",
                   L"It keeps checking for new mail here. Click the icon to open it, or right-click it to exit.", 0, 0);
    }
}

// new mail: a notification, unless the window is in front (the list shows it) or notifications are off
void NotifyNewMail(const UiEvent& event) {
    if (!g_notify) {
        return;
    }
    if (IsWindowVisible(g_main) && !IsIconic(g_main) && GetForegroundWindow() == g_main) {
        return;
    }
    std::wstring subject = core::Widen(event.detail.c_str());
    if (subject.empty()) {
        subject = L"(no subject)";
    }
    if (event.count <= 1) {
        TrayNotify(g_main, event.message, subject, event.folder, event.uid);
    } else {
        TrayNotify(g_main, std::to_wstring(event.count) + L" new messages", L"The newest from " + event.message + L": " + subject, event.folder,
                   event.uid);
    }
}

void TrayMenu() {
    HMENU menu = CreatePopupMenu();
    AppendMenuW(menu, MF_STRING, IDM_OPEN, L"&Open Inbox Classic");
    SetMenuDefaultItem(menu, IDM_OPEN, FALSE);
    AppendMenuW(menu, MF_STRING, IDM_SYNC, L"&Check for New Mail");
    AppendMenuW(menu, MF_STRING | (g_notify ? MF_CHECKED : 0), IDM_NOTIFY, L"&Notify of New Mail");
    AppendMenuW(menu, MF_SEPARATOR, 0, nullptr);
    AppendMenuW(menu, MF_STRING, IDM_EXIT, L"E&xit");
    POINT at;
    GetCursorPos(&at);
    // in front, or the menu would not close when clicked away from
    SetForegroundWindow(g_main);
    TrackPopupMenu(menu, TPM_RIGHTBUTTON | TPM_BOTTOMALIGN, at.x, at.y, 0, g_main, nullptr);
    PostMessageW(g_main, WM_NULL, 0, 0);
    DestroyMenu(menu);
}

// the last message sent, as the outgoing pane says it once the Outbox is empty
std::wstring g_lastSent;
// the app closes once the compose windows that were saving on closing are gone
bool g_quitAfterCompose = false;
// the control that had the keyboard when the main window went to the background, to have it again on coming back
HWND g_lastFocus = nullptr;

// "Subject" in quotes, or "(no subject)"
std::wstring Quoted(const std::wstring& subject) {
    return subject.empty() ? L"(no subject)" : L"\u201C" + subject + L"\u201D";
}

// the outgoing pane of the status bar, which other work does not write over: what is being sent, what waits in the
// Outbox and why, or the last message sent
void ShowOutbox() {
    core::Outbox outbox(pe_outbox(g_core.get()));
    size_t waiting = pe_outbox_count(outbox.get());
    std::wstring text = g_lastSent;
    if (waiting > 0) {
        const PeQueued* first = pe_outbox_get(outbox.get(), 0);
        std::wstring subject = first && first->subject ? Text(first->subject) : L"";
        bool failed = first && first->problem && *first->problem;
        if (waiting > 1) {
            text = std::to_wstring(waiting) + L" messages in the Outbox";
        } else if (failed) {
            text = Quoted(subject) + L" waits in the Outbox";
        } else {
            text = L"Sending " + Quoted(subject) + L"...";
        }
    }
    SendMessageW(g_status, SB_SETTEXTW, 1, reinterpret_cast<LPARAM>(text.c_str()));
    // the whole text as the pane's tip, as a long subject is cut short
    SendMessageW(g_status, SB_SETTIPTEXTW, 1, reinterpret_cast<LPARAM>(text.c_str()));
}

void SyncAll() {
    core::AccountList accounts(pe_accounts(g_core.get()));
    for (size_t i = 0; i < pe_account_list_count(accounts.get()); i++) {
        pe_sync(g_core.get(), pe_account_list_get(accounts.get(), i)->id);
    }
}

// a new message from `account`, or from the account of the selected folder when 0
void NewMessage(int64_t account = 0);

// the menu beside Create Mail (a message from one account) or Send/Recv (all accounts, or one), under the button
void AccountMenu(const NMTOOLBARW* button) {
    bool sync = button->iItem == IDM_SYNC;
    HMENU menu = CreatePopupMenu();
    if (sync) {
        AppendMenuW(menu, MF_STRING, 1, L"Send and Receive &All\tF5");
        AppendMenuW(menu, MF_SEPARATOR, 0, nullptr);
    }
    core::AccountList accounts(pe_accounts(g_core.get()));
    size_t count = pe_account_list_count(accounts.get());
    const UINT first = 100;
    for (size_t i = 0; i < count; i++) {
        const PeAccount* account = pe_account_list_get(accounts.get(), i);
        std::wstring item = MenuText((sync ? L"" : L"From ") + Text(account->label));
        AppendMenuW(menu, MF_STRING, first + static_cast<UINT>(i), item.c_str());
    }
    if (count == 0) {
        AppendMenuW(menu, MF_STRING | MF_GRAYED, 0, L"No accounts yet");
    }
    RECT bounds = button->rcButton;
    MapWindowPoints(g_toolbar, nullptr, reinterpret_cast<POINT*>(&bounds), 2);
    UINT chosen = TrackPopupMenu(menu, TPM_RETURNCMD | TPM_LEFTALIGN | TPM_TOPALIGN, bounds.left, bounds.bottom, 0, g_main, nullptr);
    DestroyMenu(menu);
    if (chosen == 1) {
        SyncAll();
    } else if (chosen >= first && chosen < first + count) {
        int64_t account = pe_account_list_get(accounts.get(), chosen - first)->id;
        if (sync) {
            pe_sync(g_core.get(), account);
        } else {
            NewMessage(account);
        }
    }
}

// an account that signs in through the browser signs in again
void SignInAgain(int64_t account) {
    std::wstring text = L"The sign-in of " + g_mailbox.AccountName(account) + L" was refused or ran out.\n\nSign in again in the browser?";
    if (MessageBoxW(g_main, text.c_str(), kTitle, MB_YESNO | MB_ICONQUESTION) != IDYES) {
        return;
    }
    uint64_t request =
        SignInWithBrowser(g_main, g_core.get(), g_mailbox.SignIn(account), g_mailbox.AccountEmail(account));
    if (!request) {
        return;
    }
    char* why = nullptr;
    if (pe_account_reauthorize(g_core.get(), account, request, &why)) {
        pe_sync(g_core.get(), account);
        return;
    }
    core::String reason(why);
    std::wstring refused = L"Signing in again did not work: " + (reason ? Text(reason.get()) : L"unknown reason");
    MessageBoxW(g_main, refused.c_str(), kTitle, MB_OK | MB_ICONWARNING);
}

void AskPassword(int64_t account) {
    if (!g_prompting.insert(account).second) {
        return;
    }
    if (g_mailbox.SignIn(account).provider != PE_O_AUTH_PROVIDER_NONE) {
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
        // how much text the search still has to read
        ShowFolderName();
        break;
    case PE_EVENT_KIND_AUTOCONFIG_DONE:
    case PE_EVENT_KIND_SIGN_IN_DONE:
    case PE_EVENT_KIND_SIGN_IN_APP_CHECKED:
        RequestDone(event.uid);
        break;
    case PE_EVENT_KIND_NEW_MAIL:
        NotifyNewMail(event);
        break;
    case PE_EVENT_KIND_UNSUBSCRIBED:
        if (std::wstring said = g_mailbox.Unsubscribed(event.uid, event.message); !said.empty()) {
            SetStatus(said);
        }
        break;
    case PE_EVENT_KIND_MESSAGE_SENT:
        // shown by the OutboxChanged that follows it
        g_lastSent = L"Sent " + Quoted(event.message) + L" at " + TimeNow();
        break;
    case PE_EVENT_KIND_DRAFT_SAVED:
        // the window that saved it says so; one that closed after saving leaves it to the status bar
        if (!ComposeDraftSaved(event.detail, event.message)) {
            SetStatus(event.message.empty() ? L"Message saved in Drafts." : L"The message was not saved in Drafts: " + event.message);
        }
        break;
    case PE_EVENT_KIND_OUTBOX_CHANGED:
        ShowOutbox();
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
    // the tray and the taskbar button: what is unread in the Inboxes, when a folder changed
    if (event.kind == PE_EVENT_KIND_FOLDER_CHANGED || event.kind == PE_EVENT_KIND_SYNC_FINISHED) {
        TrayCount(g_main, pe_inbox_unread(g_core.get()));
    }
    ShowCounts();
}

// ---- the frame ----

HMENU BuildMenu() {
    HMENU file = CreatePopupMenu();
    AppendMenuW(file, MF_STRING, IDM_NEW_ACCOUNT, L"&New Account...");
    AppendMenuW(file, MF_STRING, IDM_ACCOUNTS, L"&Accounts...");
    HMENU folder = CreatePopupMenu();
    AppendMenuW(folder, MF_STRING, IDM_NEW_FOLDER, L"&New Folder...");
    AppendMenuW(folder, MF_STRING, IDM_RENAME_FOLDER, L"&Rename...");
    AppendMenuW(folder, MF_STRING, IDM_DELETE_FOLDER, L"&Delete");
    AppendMenuW(file, MF_POPUP, reinterpret_cast<UINT_PTR>(folder), L"&Folder");
    AppendMenuW(file, MF_SEPARATOR, 0, nullptr);
    AppendMenuW(file, MF_STRING, IDM_SAVE_AS, L"&Save As...");
    AppendMenuW(file, MF_STRING, IDM_IMPORT, L"&Import Messages...");
    AppendMenuW(file, MF_STRING, IDM_PRINT, L"&Print...\tCtrl+P");
    AppendMenuW(file, MF_SEPARATOR, 0, nullptr);
    AppendMenuW(file, MF_STRING, IDM_PROPERTIES, L"P&roperties\tAlt+Enter");
    AppendMenuW(file, MF_SEPARATOR, 0, nullptr);
    AppendMenuW(file, MF_STRING, IDM_EXIT, L"E&xit");
    HMENU compose = CreatePopupMenu();
    AppendMenuW(compose, MF_STRING, IDM_NEW_MAIL, L"&New Message\tCtrl+N");
    AppendMenuW(compose, MF_SEPARATOR, 0, nullptr);
    AppendMenuW(compose, MF_STRING, IDM_REPLY, L"&Reply to Sender\tCtrl+R");
    AppendMenuW(compose, MF_STRING, IDM_REPLY_ALL, L"Reply to &All\tCtrl+Shift+R");
    AppendMenuW(compose, MF_STRING, IDM_FORWARD, L"&Forward\tCtrl+F");
    AppendMenuW(compose, MF_SEPARATOR, 0, nullptr);
    AppendMenuW(compose, MF_STRING, IDM_FLAG, L"F&lag Message");
    AppendMenuW(compose, MF_SEPARATOR, 0, nullptr);
    AppendMenuW(compose, MF_STRING, IDM_JUNK, L"Mark as &Junk\tCtrl+J");
    AppendMenuW(compose, MF_STRING, IDM_NOT_JUNK, L"Mark as N&ot Junk");
    HMENU edit = CreatePopupMenu();
    AppendMenuW(edit, MF_STRING, IDM_FIND, L"&Find Message\tCtrl+Shift+F");
    AppendMenuW(edit, MF_SEPARATOR, 0, nullptr);
    AppendMenuW(edit, MF_STRING, IDM_MARK_READ, L"Mark as &Read\tCtrl+Q");
    AppendMenuW(edit, MF_STRING, IDM_MARK_UNREAD, L"Mark as &Unread");
    AppendMenuW(edit, MF_STRING, IDM_MARK_ALL_READ, L"Mark &All Read\tCtrl+Shift+A");
    AppendMenuW(edit, MF_SEPARATOR, 0, nullptr);
    AppendMenuW(edit, MF_STRING, IDM_MOVE, L"Mo&ve to Folder...\tCtrl+Shift+V");
    AppendMenuW(edit, MF_STRING, IDM_DELETE, L"&Delete Message\tDel");
    HMENU view = CreatePopupMenu();
    AppendMenuW(view, MF_STRING, IDM_PICTURES, L"Download &Pictures");
    HMENU tools = CreatePopupMenu();
    AppendMenuW(tools, MF_STRING, IDM_SYNC, L"Send and Recei&ve All\tF5");
    AppendMenuW(tools, MF_STRING, IDM_OUTBOX, L"&Outbox...");
    AppendMenuW(tools, MF_SEPARATOR, 0, nullptr);
    AppendMenuW(tools, MF_STRING | (g_notify ? MF_CHECKED : 0), IDM_NOTIFY, L"&Notify of New Mail");
    AppendMenuW(tools, MF_STRING, IDM_DEFAULT_APP, L"Make &Default Mail App...");
    HMENU help = CreatePopupMenu();
    AppendMenuW(help, MF_STRING, IDM_HELP, L"&Contents\tF1");
    AppendMenuW(help, MF_SEPARATOR, 0, nullptr);
    AppendMenuW(help, MF_STRING, IDM_ABOUT, L"&About Inbox Classic");
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
        {FVIRTKEY | FCONTROL, 'Q', IDM_MARK_READ},
        {FVIRTKEY | FCONTROL, 'J', IDM_JUNK},
        {FVIRTKEY | FCONTROL | FSHIFT, 'A', IDM_MARK_ALL_READ},
        {FVIRTKEY | FCONTROL, 'N', IDM_NEW_MAIL},
        {FVIRTKEY | FCONTROL, 'R', IDM_REPLY},
        {FVIRTKEY | FCONTROL | FSHIFT, 'R', IDM_REPLY_ALL},
        {FVIRTKEY | FCONTROL, 'F', IDM_FORWARD},
        {FVIRTKEY | FCONTROL | FSHIFT, 'V', IDM_MOVE},
        {FVIRTKEY | FCONTROL | FSHIFT, 'F', IDM_FIND},
        {FVIRTKEY | FCONTROL, 'P', IDM_PRINT},
        {FVIRTKEY | FALT, VK_RETURN, IDM_PROPERTIES},
    };
    return CreateAcceleratorTableW(keys, static_cast<int>(std::size(keys)));
}

void CreateToolbar(HWND hwnd) {
    g_toolbar = CreateBar(hwnd, CCS_NODIVIDER | CCS_TOP, 0, BarIcons::Big);
    struct Button {
        WORD id;
        const wchar_t* text;
        int icon;
        // BTNS_DROPDOWN: a menu of the accounts beside it, as Outlook Express has
        BYTE style = BTNS_BUTTON;
    };
    // in groups as Outlook Express has them: writing, answering, the message, getting mail, read state (0 separates)
    Button buttons[] = {
        {IDM_NEW_MAIL, L"Create Mail", ICON_MAIL_ADD, BTNS_DROPDOWN},
        {0, nullptr, 0},
        {IDM_REPLY, L"Reply", ICON_ARROW_REPLY},
        {IDM_REPLY_ALL, L"Reply All", ICON_ARROW_REPLY_ALL},
        {IDM_FORWARD, L"Forward", ICON_ARROW_FORWARD},
        {0, nullptr, 0},
        {IDM_PRINT, L"Print", ICON_PRINT},
        {IDM_DELETE, L"Delete", ICON_DELETE},
        // Not Junk in place of it in a Junk folder (UpdateJunkButton)
        {IDM_JUNK, L"Junk", ICON_MAIL_PROHIBITED},
        {0, nullptr, 0},
        {IDM_SYNC, L"Send/Recv", ICON_ARROW_SYNC, BTNS_DROPDOWN},
        {0, nullptr, 0},
        {IDM_MARK_READ, L"Mark Read", ICON_MAIL_READ},
        {IDM_MARK_UNREAD, L"Mark Unread", ICON_MAIL_UNREAD},
    };
    for (const Button& button : buttons) {
        AddButton(g_toolbar, button.id, button.text, button.style, button.icon);
    }
    SendMessageW(g_toolbar, TB_AUTOSIZE, 0, 0);
}

// the area between the toolbar and the status bar
int FolderBarHeight() {
    return Scale(26);
}

RECT ContentArea() {
    RECT client;
    GetClientRect(g_main, &client);
    RECT bar;
    GetWindowRect(g_toolbar, &bar);
    client.top += bar.bottom - bar.top + FolderBarHeight();
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
    RECT bar;
    GetClientRect(g_toolbar, &bar);
    g_mailbox.PlaceFind(bar);
    MoveWindow(g_folderBar, 0, bar.bottom, bar.right, FolderBarHeight(), TRUE);
    SendMessageW(g_status, WM_SIZE, 0, 0);
    Panes panes = Measure();
    const RECT& area = panes.area;
    int gap = Scale(kGap);
    int right = area.left + panes.treeWidth + gap;
    RECT tree = {area.left, area.top, area.left + panes.treeWidth, area.bottom};
    RECT list = {right, area.top, area.right, area.top + panes.listHeight};
    RECT reader = {right, list.bottom + gap, area.right, area.bottom};
    g_mailbox.Layout(tree, list, reader);
    int width = static_cast<int>(area.right - area.left);
    // the status, the outgoing mail (wide enough for a subject), the counts
    int parts[] = {std::max(0, width - Scale(560)), std::max(0, width - Scale(220)), -1};
    SendMessageW(g_status, SB_SETPARTS, 3, reinterpret_cast<LPARAM>(parts));
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
        dir = std::wstring(base) + L"\\InboxClassic";
    }
    CoTaskMemFree(base);
    CreateDirectoryW(dir.c_str(), nullptr);
    return dir + L"\\store.db";
}

// the command line, options for test runs: --store <file> uses another mail store, --memory-passwords keeps
// passwords for this run only, --pin-certificate <file> trusts only that server certificate (see res/help.html),
// --sign-in-page-file <file> writes the page of a browser sign-in there for the test to open instead of the browser
struct Arguments {
    std::wstring store;
    std::wstring certificate;
    bool memoryPasswords = false;
    // a mailto: link Windows hands the default mail program, a new message to write
    std::wstring mailto;
};
Arguments g_arguments;

// where a mailto: link starts in the command line, npos for none
size_t MailtoStart(const std::wstring& line) {
    for (size_t at = line.find(L':'); at != std::wstring::npos; at = line.find(L':', at + 1)) {
        if (at >= 6 && _wcsnicmp(line.c_str() + at - 6, L"mailto", 6) == 0) {
            return at - 6;
        }
    }
    return std::wstring::npos;
}

void ReadArguments() {
    // a mailto: link is the rest of the command line, whatever it has in it: a link made up to look like more
    // arguments ("... --store ...") stays part of the link, and only what comes before it is read as options
    std::wstring line = GetCommandLineW();
    if (size_t start = MailtoStart(line); start != std::wstring::npos) {
        g_arguments.mailto = line.substr(start);
        while (!g_arguments.mailto.empty() && (g_arguments.mailto.back() == L'"' || g_arguments.mailto.back() == L' ')) {
            g_arguments.mailto.pop_back();
        }
        line.resize(start);
    }
    int count = 0;
    LPWSTR* argv = CommandLineToArgvW(line.c_str(), &count);
    for (int i = 1; argv && i < count; i++) {
        std::wstring arg = argv[i];
        if (arg == L"--store" && i + 1 < count) {
            g_arguments.store = argv[++i];
        } else if (arg == L"--pin-certificate" && i + 1 < count) {
            g_arguments.certificate = argv[++i];
        } else if (arg == L"--sign-in-page-file" && i + 1 < count) {
            SetSignInPageFile(argv[++i]);
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
    // the Show and In choices lie over its right end
    g_folderBar = CreateChild(hwnd, L"STATIC", L"", SS_LEFT | SS_CENTERIMAGE | SS_NOPREFIX | SS_ENDELLIPSIS | WS_CLIPSIBLINGS, 0, {});
    NONCLIENTMETRICSW metrics = {sizeof(metrics)};
    SystemParametersInfoForDpi(SPI_GETNONCLIENTMETRICS, sizeof(metrics), &metrics, 0, GetDpiForWindow(hwnd));
    metrics.lfMessageFont.lfHeight = -Scale(16);
    metrics.lfMessageFont.lfWeight = FW_BOLD;
    g_folderFont = CreateFontIndirectW(&metrics.lfMessageFont);
    g_folderBrush = CreateSolidBrush(kFolderBarColor);
    SendMessageW(g_folderBar, WM_SETFONT, reinterpret_cast<WPARAM>(g_folderFont), FALSE);
    // tips: the whole text of a pane that is cut short (a long subject in the outgoing pane)
    g_status = CreateWindowExW(0, STATUSCLASSNAMEW, nullptr, WS_CHILD | WS_VISIBLE | SBARS_SIZEGRIP | SBARS_TOOLTIPS, 0, 0, 0, 0, hwnd, nullptr,
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
    std::wstring text = std::wstring(L"Inbox Classic ") + APP_VERSION_W + L"\nCore " + core::Version() + L"\n\nPostal Systems OÜ";
    MessageBoxW(g_main, text.c_str(), L"About Inbox Classic", MB_OK | MB_ICONINFORMATION);
}

void NewMessage(int64_t account) {
    account = account ? account : g_mailbox.CurrentAccount();
    if (!account) {
        MessageBoxW(g_main, L"Add a mail account first.", kTitle, MB_OK | MB_ICONINFORMATION);
        return;
    }
    OpenCompose(g_main, g_core.get(), account, nullptr);
}

// a new message from a mailto: link, from the account of what is shown (the core reads the link)
void OpenMailto(const std::wstring& link) {
    core::Draft draft(pe_mailto_draft(core::Narrow(link).c_str()));
    if (!draft) {
        return;
    }
    int64_t account = g_mailbox.CurrentAccount();
    if (!account) {
        MessageBoxW(g_main, L"Add a mail account first, then click the e-mail link again.", kTitle, MB_OK | MB_ICONINFORMATION);
        return;
    }
    OpenCompose(g_main, g_core.get(), account, pe_draft_info(draft.get()));
}

// ---- one app for each mail store ----

// the window property that names the mail store a main window has open, so another start for it hands over to it
const wchar_t* kStoreProperty = L"InboxClassic.Store";
// WM_COPYDATA from another start: a mailto: link to write, or empty to show the window
constexpr ULONG_PTR kCopyMailto = 1;
// the link it handed over, opened once WM_COPYDATA returned
constexpr UINT WM_OPEN_MAILTO = WM_APP + 61;
std::wstring g_pendingMailto;

HANDLE StoreTag() {
    std::wstring store = g_arguments.store.empty() ? StorePath() : g_arguments.store;
    CharLowerBuffW(store.data(), static_cast<DWORD>(store.size()));
    return reinterpret_cast<HANDLE>(static_cast<uintptr_t>(std::hash<std::wstring>{}(store) | 1));
}

// the main window of another start of the app with the same mail store, nullptr when there is none
HWND RunningWindow() {
    struct Search {
        HANDLE tag;
        HWND found = nullptr;
    } search{StoreTag()};
    EnumWindows(
        [](HWND hwnd, LPARAM param) -> BOOL {
            auto* search = reinterpret_cast<Search*>(param);
            wchar_t name[64] = L"";
            GetClassNameW(hwnd, name, 64);
            if (wcscmp(name, kMainClass) == 0 && GetPropW(hwnd, kStoreProperty) == search->tag) {
                search->found = hwnd;
                return FALSE;
            }
            return TRUE;
        },
        reinterpret_cast<LPARAM>(&search));
    return search.found;
}

// hands what this start was for to the one already running: true when there is one
bool HandOver() {
    HWND running = RunningWindow();
    if (!running) {
        return false;
    }
    DWORD process = 0;
    GetWindowThreadProcessId(running, &process);
    AllowSetForegroundWindow(process);
    COPYDATASTRUCT data = {kCopyMailto, static_cast<DWORD>(g_arguments.mailto.size() * sizeof(wchar_t)),
                           const_cast<wchar_t*>(g_arguments.mailto.c_str())};
    SendMessageTimeoutW(running, WM_COPYDATA, 0, reinterpret_cast<LPARAM>(&data), SMTO_ABORTIFHUNG, 5000, nullptr);
    return true;
}

// what the installer registers the app as (installer/inbox-classic.nsi: MAILTOCLASS, PRODUCT)
const wchar_t* kMailtoClass = L"InboxClassic.mailto";
const wchar_t* kRegisteredName = L"Inbox Classic";

// Tools > Make Default Mail App: Windows lets only the user choose it, in Settings, where the installer listed the app
void MakeDefaultMailApp() {
    Microsoft::WRL::ComPtr<IApplicationAssociationRegistration> associations;
    LPWSTR current = nullptr;
    if (SUCCEEDED(CoCreateInstance(CLSID_ApplicationAssociationRegistration, nullptr, CLSCTX_INPROC_SERVER, IID_PPV_ARGS(&associations))) &&
        SUCCEEDED(associations->QueryCurrentDefault(L"mailto", AT_URLPROTOCOL, AL_EFFECTIVE, &current))) {
        bool ours = _wcsicmp(current, kMailtoClass) == 0;
        CoTaskMemFree(current);
        if (ours) {
            MessageBoxW(g_main, L"Inbox Classic is your default mail app: e-mail links open a new message here.", kTitle, MB_OK | MB_ICONINFORMATION);
            return;
        }
    }
    DWORD size = 0;
    if (RegGetValueW(HKEY_CURRENT_USER, L"Software\\RegisteredApplications", kRegisteredName, RRF_RT_REG_SZ, nullptr, nullptr, &size) !=
        ERROR_SUCCESS) {
        MessageBoxW(g_main, L"This copy of Inbox Classic was not installed, so Windows does not list it as a mail app. Install it to choose it.",
                    kTitle, MB_OK | MB_ICONINFORMATION);
        return;
    }
    MessageBoxW(g_main, L"Windows opens its Default apps settings for Inbox Classic. Choose it for MAILTO there.", kTitle,
                MB_OK | MB_ICONINFORMATION);
    ShellExecuteW(g_main, L"open", L"ms-settings:defaultapps?registeredAppUser=Inbox%20Classic", nullptr, nullptr, SW_SHOWNORMAL);
}

void Reply(PeDraftKind kind) {
    core::Draft draft = g_mailbox.DraftOfShown(kind);
    if (!draft) {
        MessageBoxW(g_main, L"Select a message first.", kTitle, MB_OK | MB_ICONINFORMATION);
        return;
    }
    OpenCompose(g_main, g_core.get(), g_mailbox.CurrentAccount(), pe_draft_info(draft.get()));
}

void OnCommand(WORD id, WORD code) {
    switch (id) {
    case IDM_FIND:
        g_mailbox.FocusFind();
        return;
    case IDM_SAVE_AS:
        g_mailbox.SaveShownAs(g_main);
        return;
    case IDM_PRINT:
        g_mailbox.PrintShown();
        return;
    case IDM_PROPERTIES:
        g_mailbox.ShowProperties(g_main);
        return;
    case IDM_IMPORT:
        g_mailbox.Import(g_main);
        return;
    case IDM_OUTBOX:
        OutboxDialog(g_main, g_core.get());
        ShowOutbox();
        return;
    case IDCANCEL:
        // Esc: the search goes first
        if (g_mailbox.ClearFind()) {
            ShowCounts();
        }
        return;
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
        // the messages being written may ask first (WM_CLOSE)
        g_exiting = true;
        PostMessageW(g_main, WM_CLOSE, 0, 0);
        return;
    case IDM_OPEN:
        ShowMain();
        return;
    case IDM_DEFAULT_APP:
        MakeDefaultMailApp();
        return;
    case IDC_UNSUBSCRIBE: {
        if (code != STN_CLICKED) {
            return;
        }
        std::wstring mailto;
        if (std::wstring said = g_mailbox.Unsubscribe(mailto); !said.empty()) {
            SetStatus(said);
        }
        if (!mailto.empty()) {
            OpenMailto(mailto);
        }
        return;
    }
    case IDM_NOTIFY:
        g_notify = !g_notify;
        SetPreference(kNotifyPreference, g_notify ? 1 : 0);
        CheckMenuItem(GetMenu(g_main), IDM_NOTIFY, MF_BYCOMMAND | (g_notify ? MF_CHECKED : MF_UNCHECKED));
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
    case IDM_MARK_ALL_READ:
        g_mailbox.MarkAllRead();
        return;
    case IDM_JUNK:
    case IDM_NOT_JUNK:
        g_mailbox.MarkJunk(id == IDM_JUNK);
        return;
    case IDM_DELETE:
        g_mailbox.DeleteSelected();
        return;
    case IDM_MOVE:
        g_mailbox.MoveSelected(g_main);
        return;
    case IDM_FLAG:
        g_mailbox.FlagSelected();
        return;
    case IDM_ACCOUNTS:
        if (AccountsDialog(g_main, g_core.get())) {
            g_mailbox.Reload();
            SyncAll();
        }
        return;
    case IDM_NEW_FOLDER:
        g_mailbox.NewFolder(g_main);
        return;
    case IDM_RENAME_FOLDER:
        g_mailbox.RenameFolder(g_main);
        return;
    case IDM_DELETE_FOLDER:
        g_mailbox.DeleteFolder(g_main);
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
        ShowFolderName();
        return;
    }
    g_mailbox.OnCommand(id, code);
}

// the events still queued when the core is closed are dropped
void DropQueuedEvents() {
    MSG msg;
    while (PeekMessageW(&msg, g_main, WM_CORE_EVENT, WM_CORE_EVENT, PM_REMOVE)) {
        delete reinterpret_cast<UiEvent*>(msg.lParam);
    }
}

LRESULT CALLBACK MainProc(HWND hwnd, UINT message, WPARAM wParam, LPARAM lParam) {
    int64_t noteFolder = 0;
    uint64_t noteUid = 0;
    switch (TrayMessage(hwnd, message, wParam, lParam, noteFolder, noteUid)) {
    case TrayAction::None:
        break;
    case TrayAction::Handled:
        return 0;
    case TrayAction::Open:
        ShowMain();
        g_mailbox.ShowMessage(noteFolder, noteUid);
        return 0;
    case TrayAction::Menu:
        TrayMenu();
        return 0;
    }
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
        // what waits from the last run
        ShowOutbox();
        SetTimer(hwnd, TIMER_SYNC, kSyncInterval, nullptr);
        TrayCreate(hwnd);
        TrayCount(hwnd, pe_inbox_unread(g_core.get()));
        // another start of the app for this mail store hands over to this one
        SetPropW(hwnd, kStoreProperty, StoreTag());
        return 0;
    case WM_COPYDATA: {
        auto* data = reinterpret_cast<const COPYDATASTRUCT*>(lParam);
        if (data->dwData != kCopyMailto || data->cbData % sizeof(wchar_t) != 0 || data->cbData > 64 * 1024 * sizeof(wchar_t)) {
            return FALSE;
        }
        std::wstring link(static_cast<const wchar_t*>(data->lpData), data->cbData / sizeof(wchar_t));
        ShowMain();
        // after this message returns, so the other start is not kept waiting by the compose window
        if (!link.empty()) {
            g_pendingMailto = link;
            PostMessageW(hwnd, WM_OPEN_MAILTO, 0, 0);
        }
        return TRUE;
    }
    case WM_OPEN_MAILTO:
        OpenMailto(std::exchange(g_pendingMailto, {}));
        return 0;
    case WM_QUERYENDSESSION:
        // Windows is shutting down or signing out: the app ends with it
        g_exiting = true;
        return TRUE;
    case WM_SIZE:
        Layout();
        return 0;
    case WM_SETCURSOR: {
        if (g_mailbox.OnSetCursor(reinterpret_cast<HWND>(wParam))) {
            return TRUE;
        }
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
        if (g_mailbox.OnDragMouse(message)) {
            return 0;
        }
        if (g_dragging) {
            DragSplitter({static_cast<short>(LOWORD(lParam)), static_cast<short>(HIWORD(lParam))});
        }
        return 0;
    case WM_LBUTTONUP:
    case WM_CAPTURECHANGED:
        if (g_mailbox.OnDragMouse(message)) {
            return 0;
        }
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
        auto* header = reinterpret_cast<NMHDR*>(lParam);
        if (header->hwndFrom == g_toolbar && header->code == TBN_DROPDOWN) {
            AccountMenu(reinterpret_cast<NMTOOLBARW*>(lParam));
            return TBDDRET_DEFAULT;
        }
        LRESULT result = 0;
        if (g_mailbox.OnNotify(header, result)) {
            // another message or folder: Junk or Not Junk
            if (header->code == LVN_ITEMCHANGED || header->code == TVN_SELCHANGEDW) {
                UpdateJunkButton();
            }
            return result;
        }
        break;
    }
    case WM_COMMAND:
        OnCommand(LOWORD(wParam), HIWORD(wParam));
        return 0;
    case WM_TIMER:
        if (wParam == TIMER_SYNC) {
            SyncAll();
        } else {
            g_mailbox.OnTimer(wParam);
            // a reload or a search changes the counts; a drag does not
            if (wParam != TIMER_DRAG) {
                ShowCounts();
            }
        }
        return 0;
    case WM_CORE_EVENT: {
        std::unique_ptr<UiEvent> event(reinterpret_cast<UiEvent*>(lParam));
        OnEvent(*event);
        return 0;
    }
    case WM_DRAWITEM:
        if (g_mailbox.OnDrawItem(*reinterpret_cast<const DRAWITEMSTRUCT*>(lParam))) {
            return TRUE;
        }
        break;
    case WM_CTLCOLORSTATIC:
        if (LRESULT brush = 0; g_mailbox.OnCtlColor(reinterpret_cast<HWND>(lParam), reinterpret_cast<HDC>(wParam), brush)) {
            return brush;
        }
        if (reinterpret_cast<HWND>(lParam) == g_folderBar) {
            // white on dark grey, as the folder bar of Outlook Express
            SetTextColor(reinterpret_cast<HDC>(wParam), RGB(0xFF, 0xFF, 0xFF));
            SetBkColor(reinterpret_cast<HDC>(wParam), kFolderBarColor);
            return reinterpret_cast<LRESULT>(g_folderBrush);
        }
        return ButtonFaceColor(reinterpret_cast<HDC>(wParam));
    case WM_CLOSE:
        // the close button: into the tray, where it goes on checking mail
        if (!g_exiting) {
            HideToTray();
            return 0;
        }
        // the messages being written first: each may ask to be saved, and the app stays while one is kept open or
        // saved
        switch (CloseComposeWindows()) {
        case ComposeClose::Closed:
            break;
        case ComposeClose::Saving:
            g_quitAfterCompose = true;
            return 0;
        case ComposeClose::Kept:
            g_exiting = false;
            return 0;
        }
        break;
    case WM_ACTIVATE:
        if (LOWORD(wParam) == WA_INACTIVE) {
            HWND focus = GetFocus();
            g_lastFocus = focus && IsChild(hwnd, focus) ? focus : nullptr;
        } else if (!HIWORD(wParam) && g_lastFocus && IsWindow(g_lastFocus)) {
            // back to the list (or the tree, or Find) it left, not to the window itself
            SetFocus(g_lastFocus);
            return 0;
        }
        break;
    case WM_COMPOSE_CLOSED:
        if (g_quitAfterCompose && !ComposeWindowsOpen()) {
            PostMessageW(hwnd, WM_CLOSE, 0, 0);
        }
        return 0;
    case WM_COMPOSE_KEPT:
        g_quitAfterCompose = false;
        return 0;
    case WM_DESTROY:
        RemovePropW(hwnd, kStoreProperty);
        KillTimer(hwnd, TIMER_SYNC);
        TrayRemove(hwnd);
        DestroyComposeWindows();
        // the WebView2s go before COM does, the core before its events are dropped
        CloseHelp();
        g_mailbox.Destroy();
        g_core.reset();
        DropQueuedEvents();
        DeleteObject(g_folderFont);
        DeleteObject(g_folderBrush);
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
    // the app is open already for this mail store: it takes the link, or comes to the front
    if (HandOver()) {
        CoUninitialize();
        return 0;
    }
    INITCOMMONCONTROLSEX controls = {sizeof(controls), ICC_TREEVIEW_CLASSES | ICC_LISTVIEW_CLASSES | ICC_BAR_CLASSES};
    InitCommonControlsEx(&controls);

    WNDCLASSEXW windowClass = {sizeof(windowClass)};
    windowClass.lpfnWndProc = MainProc;
    windowClass.hInstance = instance;
    windowClass.hCursor = LoadCursorW(nullptr, IDC_ARROW);
    SetAppIcons(windowClass);
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
    if (!g_arguments.mailto.empty()) {
        OpenMailto(g_arguments.mailto);
    }

    MSG msg;
    while (GetMessageW(&msg, nullptr, 0, 0) > 0) {
        // F1 is the help from every window
        if (msg.message == WM_KEYDOWN && msg.wParam == VK_F1) {
            OpenHelp();
            continue;
        }
        // the main window's shortcuts in the main window only: Ctrl+F in a compose window is not Forward
        if (GetAncestor(msg.hwnd, GA_ROOT) == hwnd && TranslateAcceleratorW(hwnd, g_accelerators, &msg)) {
            continue;
        }
        if (ComposeKey(msg)) {
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
