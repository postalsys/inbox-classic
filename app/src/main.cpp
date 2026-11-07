// Inbox Classic: the main window in the Outlook Express layout, folders on the left, the message list on the top
// right and the reading pane below it, with splitters between them. All mail data comes from the Rust core
// (core.h); this file draws the frame and hands the core's events to the panes.
#include <objbase.h>
#include <shellapi.h>
#include <shlobj.h>
#include <shobjidl.h>
#include <windowsx.h>
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
// where the main toolbar's buttons end with all of them shown, and which are separators (FitToolbar)
struct ToolbarEdge {
    int right;
    bool separator;
};
std::vector<ToolbarEdge> g_toolbarEdges;
void Layout();

void UpdateJunkButton() {
    if (!SetJunkButton(g_toolbar, g_mailbox.InJunk())) {
        return;
    }
    // the Find box and the buttons fitted to the row again
    g_toolbarEdges.clear();
    Layout();
}

// the toolbar's buttons for one message off while several are selected
void UpdateSelectionButtons() {
    bool one = g_mailbox.SelectedCount() <= 1;
    bool any = g_mailbox.SelectedCount() > 0;
    int count = static_cast<int>(SendMessageW(g_toolbar, TB_BUTTONCOUNT, 0, 0));
    for (int i = 0; i < count; i++) {
        TBBUTTON button = {};
        SendMessageW(g_toolbar, TB_GETBUTTON, i, reinterpret_cast<LPARAM>(&button));
        if (button.idCommand == IDM_ARCHIVE) {
            SendMessageW(g_toolbar, TB_ENABLEBUTTON, IDM_ARCHIVE, MAKELONG(g_mailbox.CanArchive() ? TRUE : FALSE, 0));
        } else if (CommandNeedsOne(static_cast<unsigned>(button.idCommand))) {
            SendMessageW(g_toolbar, TB_ENABLEBUTTON, button.idCommand, MAKELONG(one ? TRUE : FALSE, 0));
        } else if (CommandNeedsSome(static_cast<unsigned>(button.idCommand))) {
            SendMessageW(g_toolbar, TB_ENABLEBUTTON, button.idCommand, MAKELONG(any ? TRUE : FALSE, 0));
        }
    }
}

// an edit control has the keyboard: Ctrl+A and Ctrl+Z are its own there (the Find box)
HWND FocusedEdit() {
    HWND focus = GetFocus();
    wchar_t name[16] = L"";
    if (focus && GetClassNameW(focus, name, 16) && _wcsicmp(name, WC_EDITW) == 0) {
        return focus;
    }
    return nullptr;
}

// the Edit and Message menus as they open: Undo names what it takes back, and with several messages selected what
// works on one message alone is off
// whether `menu` itself has an item `id` (not one of its submenus, which MF_BYCOMMAND would search too)
bool HasOwnItem(HMENU menu, UINT id) {
    for (int i = 0, count = GetMenuItemCount(menu); i < count; i++) {
        if (GetMenuItemID(menu, i) == id) {
            return true;
        }
    }
    return false;
}

void UpdateMenu(HMENU menu) {
    // the Flag submenu as it opens; the menu it is in is updated as any other
    if (HasOwnItem(menu, IDM_FLAG_CLEAR)) {
        g_mailbox.UpdateFlagMenu(menu);
        return;
    }
    bool several = g_mailbox.SelectedCount() > 1;
    for (int i = 0, count = GetMenuItemCount(menu); i < count; i++) {
        UINT id = GetMenuItemID(menu, i);
        if (id == IDM_ARCHIVE) {
            EnableMenuItem(menu, id, MF_BYCOMMAND | (g_mailbox.CanArchive() ? MF_ENABLED : MF_GRAYED));
        } else if (id == IDM_EMPTY_FOLDER) {
            EnableMenuItem(menu, id, MF_BYCOMMAND | (g_mailbox.CanEmptyFolder() ? MF_ENABLED : MF_GRAYED));
        } else if (CommandNeedsOne(id)) {
            EnableMenuItem(menu, id, MF_BYCOMMAND | (several ? MF_GRAYED : MF_ENABLED));
        } else if (CommandNeedsSome(id)) {
            EnableMenuItem(menu, id, MF_BYCOMMAND | (g_mailbox.SelectedCount() > 0 ? MF_ENABLED : MF_GRAYED));
        }
    }
    if (GetMenuState(menu, IDM_UNDO, MF_BYCOMMAND) == static_cast<UINT>(-1)) {
        return;
    }
    // in the Find box, its own undo
    bool inEdit = FocusedEdit() != nullptr;
    std::wstring label = inEdit ? std::wstring() : g_mailbox.UndoLabel();
    bool can = inEdit || !label.empty();
    std::wstring text = label.empty() ? MenuItem(PE_TEXT_CMD_UNDO, L"Ctrl+Z") : L"&" + label + L"\t" + Shortcut(L"Ctrl+Z");
    ModifyMenuW(menu, IDM_UNDO, MF_BYCOMMAND | MF_STRING | (can ? MF_ENABLED : MF_GRAYED), IDM_UNDO, text.c_str());
}

void ShowCounts() {
    std::wstring counts = g_mailbox.Counts();
    SendMessageW(g_status, SB_SETTEXTW, 2, reinterpret_cast<LPARAM>(counts.c_str()));
    // the folder bar says how many a search found
    ShowFolderName();
}

// the selection of the list taken, or another folder: Junk or Not Junk, the buttons for one message, the counts
void OnSelectionTaken() {
    UpdateJunkButton();
    UpdateSelectionButtons();
    ShowCounts();
}

// ---- the tray ----

// File > Exit, the tray's Exit or Windows shutting down: closing ends the app rather than hiding it in the tray
bool g_exiting = false;
// Options chose another language and Restart Now: the app starts again once it has closed
bool g_restart = false;

const wchar_t* kNotifyPreference = L"NewMailNotifications";
// Tools > Notify of New Mail, read once
bool g_notify = GetPreference(kNotifyPreference, 1) != 0;
const wchar_t* kTrayNotePreference = L"TrayNoteShown";

// the new mail notifications on or off (Tools, the tray's menu, Options), kept for the next start
void SetNotify(bool on) {
    g_notify = on;
    SetPreference(kNotifyPreference, on ? 1 : 0);
    CheckMenuItem(GetMenu(g_main), IDM_NOTIFY, MF_BYCOMMAND | (on ? MF_CHECKED : MF_UNCHECKED));
}

}  // namespace

// the window back from the tray (or the taskbar), in front
void ShowMain() {
    if (IsIconic(g_main)) {
        ShowWindow(g_main, SW_RESTORE);
    } else {
        ShowWindow(g_main, SW_SHOW);
    }
    SetForegroundWindow(g_main);
    // started in the tray: shown now for the first time
    g_mailbox.SelectStart();
}

namespace {

// the window's close button: the app keeps checking mail from the tray; the first time it says so
void HideToTray() {
    ShowWindow(g_main, SW_HIDE);
    if (!GetPreference(kTrayNotePreference, 0)) {
        SetPreference(kTrayNotePreference, 1);
        TrayNotify(g_main, core::T(PE_TEXT_UI_STILL_RUNNING), core::T(PE_TEXT_WIN_STILL_RUNNING_DETAIL), 0, 0);
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
        subject = core::T(PE_TEXT_UI_NO_SUBJECT);
    }
    if (event.count <= 1) {
        TrayNotify(g_main, event.message, subject, event.folder, event.uid);
    } else {
        TrayNotify(g_main, core::T(PE_TEXT_WIN_NEW_MESSAGES, {{"count", std::to_wstring(event.count)}}),
                   core::T(PE_TEXT_UI_NEWEST_FROM, {{"sender", event.message}, {"subject", subject}}), event.folder, event.uid);
    }
}

void TrayMenu() {
    HMENU menu = CreatePopupMenu();
    AppendMenuW(menu, MF_STRING, IDM_OPEN, MenuItem(PE_TEXT_CMD_OPEN).c_str());
    SetMenuDefaultItem(menu, IDM_OPEN, FALSE);
    AppendMenuW(menu, MF_STRING, IDM_SYNC, MenuItem(PE_TEXT_TRAY_CHECK).c_str());
    AppendMenuW(menu, MF_STRING | (g_notify ? MF_CHECKED : 0), IDM_NOTIFY, MenuItem(PE_TEXT_CMD_NOTIFY).c_str());
    AppendMenuW(menu, MF_SEPARATOR, 0, nullptr);
    AppendMenuW(menu, MF_STRING, IDM_EXIT, MenuItem(PE_TEXT_CMD_EXIT).c_str());
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
    return subject.empty() ? core::T(PE_TEXT_UI_NO_SUBJECT) : core::T(PE_TEXT_UI_QUOTED, {{"subject", subject}});
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
            text = core::T(PE_TEXT_UI_OUTBOX_WAITING, {{"count", std::to_wstring(waiting)}});
        } else if (failed) {
            text = core::T(PE_TEXT_UI_OUTBOX_WAITS, {{"subject", Quoted(subject)}});
        } else {
            text = core::T(PE_TEXT_UI_OUTBOX_SENDING, {{"subject", Quoted(subject)}});
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
        AppendMenuW(menu, MF_STRING, 1, MenuItem(PE_TEXT_CMD_SYNC, L"F5").c_str());
        AppendMenuW(menu, MF_SEPARATOR, 0, nullptr);
    }
    core::AccountList accounts(pe_accounts(g_core.get()));
    size_t count = pe_account_list_count(accounts.get());
    const UINT first = 100;
    for (size_t i = 0; i < count; i++) {
        const PeAccount* account = pe_account_list_get(accounts.get(), i);
        std::wstring label = MenuText(Text(account->label));
        std::wstring item = sync ? label : core::T(PE_TEXT_UI_FROM_ACCOUNT, {{"account", label}});
        AppendMenuW(menu, MF_STRING, first + static_cast<UINT>(i), item.c_str());
    }
    if (count == 0) {
        AppendMenuW(menu, MF_STRING | MF_GRAYED, 0, core::T(PE_TEXT_TRAY_NO_ACCOUNTS).c_str());
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
    std::wstring text = core::T(PE_TEXT_UI_SIGN_IN_REFUSED, {{"account", g_mailbox.AccountName(account)}}) + L"\n\n" +
                        core::T(PE_TEXT_UI_SIGN_IN_AGAIN_ASK);
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
    std::wstring refused = core::T(PE_TEXT_UI_SIGN_IN_AGAIN_FAILED,
                                   {{"reason", reason ? Text(reason.get()) : core::T(PE_TEXT_UI_UNKNOWN_REASON)}});
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
        SetStatus(core::T(PE_TEXT_UI_CHECKING, {{"account", g_mailbox.AccountName(event.account)}}));
        break;
    case PE_EVENT_KIND_SYNC_FINISHED:
        // a failure stays in the status bar until the account syncs without one
        if (g_failing.empty()) {
            SetStatus(core::T(PE_TEXT_UI_DONE));
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
        g_lastSent = core::T(PE_TEXT_UI_SENT_AT, {{"subject", Quoted(event.message)}, {"time", TimeNow()}});
        break;
    case PE_EVENT_KIND_DRAFT_SAVED:
        // the window that saved it says so; one that closed after saving leaves it to the status bar
        if (!ComposeDraftSaved(event.detail, event.message)) {
            SetStatus(event.message.empty() ? core::T(PE_TEXT_UI_DRAFT_SAVED)
                                            : core::T(PE_TEXT_UI_DRAFT_NOT_SAVED, {{"reason", event.message}}));
        }
        break;
    case PE_EVENT_KIND_OUTBOX_CHANGED:
        ShowOutbox();
        break;
    case PE_EVENT_KIND_AGENT_ASK:
        // the question with the window it is about, in front
        ShowMain();
        AgentQuestion(g_main, g_core.get(), event.uid);
        break;
    case PE_EVENT_KIND_AGENT_LOG_CHANGED:
        AgentsChanged();
        break;
    case PE_EVENT_KIND_TRANSFERRING:
        // how far messages going to another account are, and what was done once they all went
        SetStatus(event.message);
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
    // the messages open in windows of their own: shown once ready, closed once gone
    MessageWindowsEvent(event);
    // the tray and the taskbar button: what is unread in the Inboxes, when a folder changed
    if (event.kind == PE_EVENT_KIND_FOLDER_CHANGED || event.kind == PE_EVENT_KIND_SYNC_FINISHED) {
        TrayCount(g_main, pe_inbox_unread(g_core.get()));
    }
    ShowCounts();
}

// ---- the frame ----

HMENU BuildMenu() {
    HMENU file = CreatePopupMenu();
    AppendMenuW(file, MF_STRING, IDM_NEW_ACCOUNT, MenuItem(PE_TEXT_CMD_NEW_ACCOUNT).c_str());
    AppendMenuW(file, MF_STRING, IDM_ACCOUNTS, MenuItem(PE_TEXT_CMD_ACCOUNTS).c_str());
    HMENU folder = CreatePopupMenu();
    AppendMenuW(folder, MF_STRING, IDM_NEW_FOLDER, MenuItem(PE_TEXT_CMD_NEW_FOLDER).c_str());
    AppendMenuW(folder, MF_STRING, IDM_RENAME_FOLDER, MenuItem(PE_TEXT_CMD_RENAME_FOLDER).c_str());
    AppendMenuW(folder, MF_STRING, IDM_DELETE_FOLDER, MenuItem(PE_TEXT_CMD_DELETE_FOLDER).c_str());
    AppendMenuW(folder, MF_SEPARATOR, 0, nullptr);
    AppendMenuW(folder, MF_STRING, IDM_EMPTY_FOLDER, MenuItem(PE_TEXT_CMD_EMPTY_FOLDER).c_str());
    AppendMenuW(file, MF_POPUP, reinterpret_cast<UINT_PTR>(folder), MenuItem(PE_TEXT_MENU_FOLDER).c_str());
    AppendMenuW(file, MF_SEPARATOR, 0, nullptr);
    AppendMenuW(file, MF_STRING, IDM_SAVE_AS, MenuItem(PE_TEXT_CMD_SAVE_AS).c_str());
    AppendMenuW(file, MF_STRING, IDM_IMPORT, MenuItem(PE_TEXT_CMD_IMPORT).c_str());
    AppendMenuW(file, MF_STRING, IDM_PRINT, MenuItem(PE_TEXT_CMD_PRINT, L"Ctrl+P").c_str());
    AppendMenuW(file, MF_SEPARATOR, 0, nullptr);
    AppendMenuW(file, MF_STRING, IDM_PROPERTIES, MenuItem(PE_TEXT_CMD_PROPERTIES, L"Alt+Enter").c_str());
    AppendMenuW(file, MF_SEPARATOR, 0, nullptr);
    AppendMenuW(file, MF_STRING, IDM_EXIT, MenuItem(PE_TEXT_CMD_EXIT).c_str());
    HMENU compose = CreatePopupMenu();
    AppendMenuW(compose, MF_STRING, IDM_NEW_MAIL, MenuItem(PE_TEXT_CMD_NEW_MAIL, L"Ctrl+N").c_str());
    AppendMenuW(compose, MF_SEPARATOR, 0, nullptr);
    AppendMenuW(compose, MF_STRING, IDM_REPLY, MenuItem(PE_TEXT_CMD_REPLY, L"Ctrl+R").c_str());
    AppendMenuW(compose, MF_STRING, IDM_REPLY_ALL, MenuItem(PE_TEXT_CMD_REPLY_ALL, L"Ctrl+Shift+R").c_str());
    AppendMenuW(compose, MF_STRING, IDM_FORWARD, MenuItem(PE_TEXT_CMD_FORWARD, L"Ctrl+F").c_str());
    AppendMenuW(compose, MF_SEPARATOR, 0, nullptr);
    AppendMenuW(compose, MF_STRING, IDM_FLAG, MenuItem(PE_TEXT_CMD_FLAG).c_str());
    AppendMenuW(compose, MF_POPUP, reinterpret_cast<UINT_PTR>(g_mailbox.FlagMenu()), MenuItem(PE_TEXT_UI_MENU_FLAG).c_str());
    AppendMenuW(compose, MF_SEPARATOR, 0, nullptr);
    AppendMenuW(compose, MF_STRING, IDM_ARCHIVE, MenuItem(PE_TEXT_CMD_ARCHIVE, L"A").c_str());
    AppendMenuW(compose, MF_STRING, IDM_JUNK, MenuItem(PE_TEXT_CMD_JUNK, L"Ctrl+J").c_str());
    AppendMenuW(compose, MF_STRING, IDM_NOT_JUNK, MenuItem(PE_TEXT_CMD_NOT_JUNK).c_str());
    HMENU edit = CreatePopupMenu();
    AppendMenuW(edit, MF_STRING | MF_GRAYED, IDM_UNDO, MenuItem(PE_TEXT_CMD_UNDO, L"Ctrl+Z").c_str());
    AppendMenuW(edit, MF_SEPARATOR, 0, nullptr);
    AppendMenuW(edit, MF_STRING, IDM_SELECT_ALL, MenuItem(PE_TEXT_CMD_SELECT_ALL, L"Ctrl+A").c_str());
    AppendMenuW(edit, MF_STRING, IDM_FIND, MenuItem(PE_TEXT_CMD_FIND, L"Ctrl+Shift+F").c_str());
    AppendMenuW(edit, MF_STRING, IDM_FIND_IN_MESSAGE, MenuItem(PE_TEXT_CMD_FIND_IN_MESSAGE, L"F3").c_str());
    AppendMenuW(edit, MF_SEPARATOR, 0, nullptr);
    AppendMenuW(edit, MF_STRING, IDM_MARK_READ, MenuItem(PE_TEXT_CMD_MARK_READ, L"Ctrl+Q").c_str());
    AppendMenuW(edit, MF_STRING, IDM_MARK_UNREAD, MenuItem(PE_TEXT_CMD_MARK_UNREAD).c_str());
    AppendMenuW(edit, MF_STRING, IDM_MARK_ALL_READ, MenuItem(PE_TEXT_CMD_MARK_ALL_READ, L"Ctrl+Shift+A").c_str());
    AppendMenuW(edit, MF_SEPARATOR, 0, nullptr);
    AppendMenuW(edit, MF_STRING, IDM_MOVE, MenuItem(PE_TEXT_CMD_MOVE, L"Ctrl+Shift+V").c_str());
    AppendMenuW(edit, MF_STRING, IDM_COPY, MenuItem(PE_TEXT_CMD_COPY).c_str());
    AppendMenuW(edit, MF_STRING, IDM_DELETE, MenuItem(PE_TEXT_CMD_DELETE, L"Del").c_str());
    HMENU view = CreatePopupMenu();
    AppendMenuW(view, MF_STRING, IDM_NEXT_MESSAGE, MenuItem(PE_TEXT_CMD_NEXT_MESSAGE, L"Ctrl+.").c_str());
    AppendMenuW(view, MF_STRING, IDM_PREVIOUS_MESSAGE, MenuItem(PE_TEXT_CMD_PREVIOUS_MESSAGE, L"Ctrl+,").c_str());
    AppendMenuW(view, MF_STRING, IDM_NEXT_UNREAD, MenuItem(PE_TEXT_CMD_NEXT_UNREAD, L"N").c_str());
    AppendMenuW(view, MF_STRING, IDM_GO_TO_FOLDER, MenuItem(PE_TEXT_CMD_GO_TO_FOLDER, L"Ctrl+Y").c_str());
    AppendMenuW(view, MF_SEPARATOR, 0, nullptr);
    AppendMenuW(view, MF_STRING, IDM_PICTURES, MenuItem(PE_TEXT_CMD_PICTURES).c_str());
    AppendMenuW(view, MF_SEPARATOR, 0, nullptr);
    AppendMenuW(view, MF_STRING, IDM_VIEW_SOURCE, MenuItem(PE_TEXT_CMD_VIEW_SOURCE, L"Ctrl+U").c_str());
    HMENU tools = CreatePopupMenu();
    AppendMenuW(tools, MF_STRING, IDM_SYNC, MenuItem(PE_TEXT_CMD_SYNC, L"F5").c_str());
    AppendMenuW(tools, MF_STRING, IDM_OUTBOX, MenuItem(PE_TEXT_CMD_OUTBOX).c_str());
    AppendMenuW(tools, MF_SEPARATOR, 0, nullptr);
    AppendMenuW(tools, MF_STRING, IDM_AI_AGENTS, MenuItem(PE_TEXT_CMD_AI_AGENTS).c_str());
    AppendMenuW(tools, MF_SEPARATOR, 0, nullptr);
    AppendMenuW(tools, MF_STRING | (g_notify ? MF_CHECKED : 0), IDM_NOTIFY, MenuItem(PE_TEXT_CMD_NOTIFY).c_str());
    AppendMenuW(tools, MF_STRING, IDM_DEFAULT_APP, MenuItem(PE_TEXT_CMD_DEFAULT_APP).c_str());
    AppendMenuW(tools, MF_SEPARATOR, 0, nullptr);
    AppendMenuW(tools, MF_STRING, IDM_OPTIONS, MenuItem(PE_TEXT_CMD_OPTIONS).c_str());
    HMENU help = CreatePopupMenu();
    AppendMenuW(help, MF_STRING, IDM_HELP, MenuItem(PE_TEXT_CMD_HELP, L"F1").c_str());
    AppendMenuW(help, MF_SEPARATOR, 0, nullptr);
    AppendMenuW(help, MF_STRING, IDM_ABOUT, MenuItem(PE_TEXT_CMD_ABOUT).c_str());
    HMENU bar = CreateMenu();
    AppendMenuW(bar, MF_POPUP, reinterpret_cast<UINT_PTR>(file), MenuItem(PE_TEXT_MENU_FILE).c_str());
    AppendMenuW(bar, MF_POPUP, reinterpret_cast<UINT_PTR>(edit), MenuItem(PE_TEXT_MENU_EDIT).c_str());
    AppendMenuW(bar, MF_POPUP, reinterpret_cast<UINT_PTR>(view), MenuItem(PE_TEXT_MENU_VIEW).c_str());
    AppendMenuW(bar, MF_POPUP, reinterpret_cast<UINT_PTR>(tools), MenuItem(PE_TEXT_MENU_TOOLS).c_str());
    AppendMenuW(bar, MF_POPUP, reinterpret_cast<UINT_PTR>(compose), MenuItem(PE_TEXT_MENU_MESSAGE).c_str());
    AppendMenuW(bar, MF_POPUP, reinterpret_cast<UINT_PTR>(help), MenuItem(PE_TEXT_MENU_HELP).c_str());
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
        {FVIRTKEY | FCONTROL, 'U', IDM_VIEW_SOURCE},
        {FVIRTKEY | FCONTROL, 'A', IDM_SELECT_ALL},
        {FVIRTKEY | FCONTROL, 'Z', IDM_UNDO},
        {FVIRTKEY | FCONTROL, VK_OEM_PERIOD, IDM_NEXT_MESSAGE},
        {FVIRTKEY | FCONTROL, VK_OEM_COMMA, IDM_PREVIOUS_MESSAGE},
        {FVIRTKEY | FCONTROL, 'Y', IDM_GO_TO_FOLDER},
        {FVIRTKEY, VK_F3, IDM_FIND_IN_MESSAGE},
    };
    return CreateAcceleratorTableW(keys, static_cast<int>(std::size(keys)));
}

void CreateToolbar(HWND hwnd) {
    // the search field lies on the toolbar: clipped out of it, so a repaint of the buttons never covers the field
    g_toolbar = CreateBar(hwnd, CCS_NODIVIDER | CCS_TOP | WS_CLIPSIBLINGS, 0, BarIcons::Big);
    struct Button {
        WORD id;
        PeText text;
        int icon;
        // BTNS_DROPDOWN: a menu of the accounts beside it, as Outlook Express has
        BYTE style = BTNS_BUTTON;
    };
    // in groups as Outlook Express has them: writing, answering, the message, getting mail, read state (0 separates)
    Button buttons[] = {
        {IDM_NEW_MAIL, PE_TEXT_UI_TB_CREATE_MAIL, ICON_MAIL_ADD, BTNS_DROPDOWN},
        {0, PE_TEXT_MENU_FILE, 0},
        {IDM_REPLY, PE_TEXT_UI_TB_REPLY, ICON_ARROW_REPLY},
        {IDM_REPLY_ALL, PE_TEXT_UI_TB_REPLY_ALL, ICON_ARROW_REPLY_ALL},
        {IDM_FORWARD, PE_TEXT_UI_TB_FORWARD, ICON_ARROW_FORWARD},
        {0, PE_TEXT_MENU_FILE, 0},
        {IDM_PRINT, PE_TEXT_UI_TB_PRINT, ICON_PRINT},
        {IDM_DELETE, PE_TEXT_UI_TB_DELETE, ICON_DELETE},
        {IDM_ARCHIVE, PE_TEXT_UI_TB_ARCHIVE, ICON_ARCHIVE},
        // Not Junk in place of it in a Junk folder (UpdateJunkButton)
        {IDM_JUNK, PE_TEXT_UI_TB_JUNK, ICON_MAIL_PROHIBITED},
        {0, PE_TEXT_MENU_FILE, 0},
        {IDM_SYNC, PE_TEXT_UI_TB_SYNC, ICON_ARROW_SYNC, BTNS_DROPDOWN},
        {0, PE_TEXT_MENU_FILE, 0},
        {IDM_MARK_READ, PE_TEXT_UI_TB_MARK_READ, ICON_MAIL_READ},
        {IDM_MARK_UNREAD, PE_TEXT_UI_TB_MARK_UNREAD, ICON_MAIL_UNREAD},
    };
    for (const Button& button : buttons) {
        std::wstring label = button.id ? core::T(button.text) : std::wstring();
        AddButton(g_toolbar, button.id, button.id ? label.c_str() : nullptr, button.style, button.icon);
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

// the Find box gives way to the buttons' longer words in other languages, down to its least width; the buttons that
// still run under it are hidden from the end, as their commands are all in the menus too
void FitToolbar(const RECT& bar) {
    // by index: the separators share the command id 0
    auto stateOf = [](int index) {
        TBBUTTON button = {};
        SendMessageW(g_toolbar, TB_GETBUTTON, index, reinterpret_cast<LPARAM>(&button));
        return button;
    };
    auto setHidden = [&](int index, bool hidden) {
        BYTE now = stateOf(index).fsState;
        BYTE wanted = hidden ? (now | TBSTATE_HIDDEN) : (now & ~TBSTATE_HIDDEN);
        if (wanted != now) {
            TBBUTTONINFOW info = {sizeof(info), TBIF_BYINDEX | TBIF_STATE};
            info.fsState = wanted;
            SendMessageW(g_toolbar, TB_SETBUTTONINFOW, index, reinterpret_cast<LPARAM>(&info));
        }
    };
    int buttons = static_cast<int>(SendMessageW(g_toolbar, TB_BUTTONCOUNT, 0, 0));
    // where each button ends with all of them shown, measured again only when the buttons change
    if (static_cast<int>(g_toolbarEdges.size()) != buttons) {
        g_toolbarEdges.clear();
        for (int i = 0; i < buttons; i++) {
            setHidden(i, false);
        }
        for (int i = 0; i < buttons; i++) {
            RECT item = {};
            SendMessageW(g_toolbar, TB_GETITEMRECT, i, reinterpret_cast<LPARAM>(&item));
            g_toolbarEdges.push_back({static_cast<int>(item.right), (stateOf(i).fsStyle & BTNS_SEP) != 0});
        }
    }
    int findLeft = g_mailbox.PlaceFind(bar, buttons > 0 ? g_toolbarEdges.back().right : 0) - Scale(4);
    // from the end: every button under the box, and a separator that would be left last
    int shown = buttons;
    while (shown > 0 && (g_toolbarEdges[shown - 1].right > findLeft || (shown < buttons && g_toolbarEdges[shown - 1].separator))) {
        shown--;
    }
    for (int i = 0; i < buttons; i++) {
        setHidden(i, i >= shown);
    }
}

void Layout() {
    SendMessageW(g_toolbar, TB_AUTOSIZE, 0, 0);
    RECT bar;
    GetClientRect(g_toolbar, &bar);
    FitToolbar(bar);
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
    // --version: print it and exit
    bool version = false;
    // a mailto: link Windows hands the default mail program, a new message to write
    std::wstring mailto;
    // --mcp: relay an AI agent's MCP connection to the app that is running (started when it is not), no window
    bool mcp = false;
    // --background: started for an agent (by --mcp), in the tray without its window
    bool background = false;
    // --test-hooks: the UI test drops and drags in place of Explorer (WM_COPYDATA kTestDragOut, kTestDropFiles)
    bool testHooks = false;
    // --language <code>: the windows in that language (`de`; `qps` the pseudo-language of the UI test), whatever
    // Options says
    std::wstring language;
    // the options again, for a restart in another language: without a mailto: link (it was handled) and without
    // --background (the window is in use)
    std::wstring restart;
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

// `arg` as CommandLineToArgvW reads it back: in quotes, a quote and the backslashes before one escaped
std::wstring QuoteArgument(const std::wstring& arg) {
    std::wstring quoted = L"\"";
    size_t backslashes = 0;
    for (wchar_t c : arg) {
        if (c == L'\\') {
            backslashes++;
            continue;
        }
        quoted.append(c == L'"' ? 2 * backslashes + 1 : backslashes, L'\\');
        backslashes = 0;
        quoted += c;
    }
    quoted.append(2 * backslashes, L'\\');
    return quoted + L"\"";
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
    // what a restart passes on: the options this start had, but for --background and --language (a restart is how
    // a language picked in Options takes effect)
    auto keep = [](const std::wstring& arg) { g_arguments.restart += L" " + QuoteArgument(arg); };
    for (int i = 1; argv && i < count; i++) {
        std::wstring arg = argv[i];
        if (arg == L"--language" && i + 1 < count) {
            g_arguments.language = argv[++i];
            continue;
        }
        if (arg != L"--background") {
            keep(arg);
        }
        if (arg == L"--store" && i + 1 < count) {
            g_arguments.store = argv[++i];
            keep(g_arguments.store);
        } else if (arg == L"--pin-certificate" && i + 1 < count) {
            g_arguments.certificate = argv[++i];
            keep(g_arguments.certificate);
        } else if (arg == L"--sign-in-page-file" && i + 1 < count) {
            keep(argv[++i]);
            SetSignInPageFile(argv[i]);
        } else if (arg == L"--memory-passwords") {
            g_arguments.memoryPasswords = true;
        } else if (arg == L"--version") {
            g_arguments.version = true;
        } else if (arg == L"--mcp") {
            g_arguments.mcp = true;
        } else if (arg == L"--background") {
            g_arguments.background = true;
        } else if (arg == L"--test-hooks") {
            g_arguments.testHooks = true;
        }
    }
    LocalFree(argv);
}

bool OpenCore(HWND hwnd) {
    std::string path = core::Narrow(g_arguments.store.empty() ? StorePath() : g_arguments.store);
    uint32_t flags = g_arguments.memoryPasswords ? PE_OPEN_MEMORY_PASSWORDS : 0;
    std::string certificate = core::Narrow(g_arguments.certificate);
    g_core.reset(pe_core_open_with(path.c_str(), flags, certificate.empty() ? nullptr : certificate.c_str(), OnCoreEvent, hwnd));
    if (g_core) {
        // where the user's AI agents reach this app (--mcp); another app with this store open keeps them
        pe_mcp_start(g_core.get());
    }
    return g_core != nullptr;
}

}  // namespace

const char* StoreArgument() {
    static std::string store;
    store = core::Narrow(g_arguments.store);
    return store.empty() ? nullptr : store.c_str();
}

namespace {

// --mcp: the relay of an agent's MCP server, to the app that has this store open; the app is started in the
// background when it is not running
int RelayMcp() {
    std::string store = core::Narrow(g_arguments.store.empty() ? StorePath() : g_arguments.store);
    return pe_mcp_relay(store.c_str(), StoreArgument());
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
    std::wstring text = std::wstring(L"Inbox Classic ") + APP_VERSION_W + L"\n" +
                        core::T(PE_TEXT_UI_ABOUT_CORE, {{"version", core::Version()}}) + L"\n\nPostal Systems OÜ";
    MessageBoxW(g_main, text.c_str(), core::Plain(PE_TEXT_CMD_ABOUT).c_str(), MB_OK | MB_ICONINFORMATION);
}

void NewMessage(int64_t account) {
    account = account ? account : g_mailbox.CurrentAccount();
    if (!account) {
        MessageBoxW(g_main, core::T(PE_TEXT_UI_ADD_ACCOUNT_FIRST).c_str(), kTitle, MB_OK | MB_ICONINFORMATION);
        return;
    }
    OpenCompose(g_main, g_core.get(), account, nullptr);
}

}  // namespace

void OpenMailto(const std::wstring& link, int64_t account) {
    core::Draft draft(pe_mailto_draft(core::Narrow(link).c_str()));
    if (!draft) {
        return;
    }
    account = account ? account : g_mailbox.CurrentAccount();
    if (!account) {
        MessageBoxW(g_main, core::T(PE_TEXT_UI_ADD_ACCOUNT_FIRST_LINK).c_str(), kTitle, MB_OK | MB_ICONINFORMATION);
        return;
    }
    OpenCompose(g_main, g_core.get(), account, pe_draft_info(draft.get()));
}

namespace {

// ---- one app for each mail store ----

// the window property that names the mail store a main window has open, so another start for it hands over to it
const wchar_t* kStoreProperty = L"InboxClassic.Store";
// WM_COPYDATA from another start: a mailto: link to write, or empty to show the window
constexpr ULONG_PTR kCopyMailto = 1;
// with --test-hooks only: the selected messages dragged into a folder (its path), files dropped onto a tree item
// ("<item>|<path>|<path>..."); the result is what the message returns
constexpr ULONG_PTR kTestDragOut = 0x44524F55;
constexpr ULONG_PTR kTestDropFiles = 0x44524F50;
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
            MessageBoxW(g_main, core::T(PE_TEXT_UI_DEFAULT_APP_IS).c_str(), kTitle, MB_OK | MB_ICONINFORMATION);
            return;
        }
    }
    DWORD size = 0;
    if (RegGetValueW(HKEY_CURRENT_USER, L"Software\\RegisteredApplications", kRegisteredName, RRF_RT_REG_SZ, nullptr, nullptr, &size) !=
        ERROR_SUCCESS) {
        MessageBoxW(g_main, core::T(PE_TEXT_WIN_DEFAULT_APP_NOT_INSTALLED).c_str(),
                    kTitle, MB_OK | MB_ICONINFORMATION);
        return;
    }
    MessageBoxW(g_main, core::T(PE_TEXT_WIN_DEFAULT_APP_SETTINGS).c_str(), kTitle,
                MB_OK | MB_ICONINFORMATION);
    ShellExecuteW(g_main, L"open", L"ms-settings:defaultapps?registeredAppUser=Inbox%20Classic", nullptr, nullptr, SW_SHOWNORMAL);
}

void Reply(PeDraftKind kind) {
    core::Draft draft = g_mailbox.DraftOfShown(kind);
    if (!draft) {
        MessageBoxW(g_main, core::T(PE_TEXT_UI_SELECT_MESSAGE_FIRST).c_str(), kTitle, MB_OK | MB_ICONINFORMATION);
        return;
    }
    OpenCompose(g_main, g_core.get(), g_mailbox.CurrentAccount(), pe_draft_info(draft.get()));
}

void OnCommand(WORD id, WORD code) {
    // a colour of the Flag submenu, or Clear Flag
    if (id > IDM_FLAG_COLOR && id <= IDM_FLAG_CLEAR) {
        g_mailbox.FlagColor(id == IDM_FLAG_CLEAR ? 0 : id - IDM_FLAG_COLOR);
        return;
    }
    switch (id) {
    case IDM_FIND:
        g_mailbox.FocusFind();
        return;
    case IDM_SAVE_AS:
        // several: into a folder, each named after its subject
        if (g_mailbox.SelectedCount() > 1) {
            g_mailbox.SaveSelectedInto(g_main);
        } else {
            g_mailbox.SaveShownAs(g_main);
        }
        return;
    case IDM_PRINT:
        g_mailbox.PrintShown();
        return;
    case IDM_PROPERTIES:
        g_mailbox.ShowProperties(g_main);
        return;
    case IDM_VIEW_SOURCE:
        g_mailbox.ShowSource(g_main);
        return;
    case IDM_AI_AGENTS:
        AgentsDialog(g_main, g_core.get());
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
        // several: one new message with them attached
        if (g_mailbox.SelectedCount() > 1) {
            g_mailbox.ForwardSelected();
        } else {
            Reply(PE_DRAFT_KIND_FORWARD);
        }
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
        SetNotify(!g_notify);
        return;
    case IDM_OPTIONS: {
        bool notify = g_notify;
        bool restart = OptionsDialog(g_main, notify);
        SetNotify(notify);
        if (restart) {
            // as File > Exit, the messages being written asked first; started again once the window is gone
            g_restart = true;
            g_exiting = true;
            PostMessageW(g_main, WM_CLOSE, 0, 0);
        }
        return;
    }
    case IDM_SYNC:
        SyncAll();
        return;
    case IDM_SELECT_ALL:
        if (HWND edit = FocusedEdit()) {
            SendMessageW(edit, EM_SETSEL, 0, -1);
        } else {
            g_mailbox.SelectAll();
        }
        return;
    case IDM_UNDO:
        if (HWND edit = FocusedEdit()) {
            SendMessageW(edit, WM_UNDO, 0, 0);
        } else {
            g_mailbox.Undo();
        }
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
    case IDM_ARCHIVE:
        g_mailbox.ArchiveSelected();
        return;
    case IDM_MOVE:
    case IDM_COPY:
        g_mailbox.MoveSelected(g_main, id == IDM_COPY);
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
    case IDM_EMPTY_FOLDER:
        g_mailbox.EmptyFolder(g_main);
        return;
    case IDM_PICTURES:
        g_mailbox.LoadPictures();
        return;
    case IDM_NEXT_MESSAGE:
    case IDM_PREVIOUS_MESSAGE:
        g_mailbox.SelectNeighbour(id == IDM_NEXT_MESSAGE);
        return;
    case IDM_NEXT_UNREAD:
        g_mailbox.NextUnread(g_main);
        return;
    case IDM_GO_TO_FOLDER:
        g_mailbox.GoToFolder(g_main);
        return;
    case IDM_FIND_IN_MESSAGE:
        // F3 again finds the next place; the menu asks for the words
        g_mailbox.FindInMessage(g_main, code == 1);
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
    case IDC_LIST:
        // the list's selection taken, or what an action on messages did
        if (code == kSaid) {
            SetStatus(g_mailbox.Said());
        }
        OnSelectionTaken();
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
            std::wstring why = core::T(g_arguments.certificate.empty() ? PE_TEXT_UI_STORE_NOT_OPENED : PE_TEXT_UI_STORE_OR_CERT_NOT_OPENED);
            MessageBoxW(hwnd, why.c_str(), kTitle, MB_OK | MB_ICONERROR);
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
        if (g_arguments.testHooks && (data->dwData == kTestDragOut || data->dwData == kTestDropFiles) &&
            data->cbData % sizeof(wchar_t) == 0) {
            std::wstring text(static_cast<const wchar_t*>(data->lpData), data->cbData / sizeof(wchar_t));
            if (data->dwData == kTestDragOut) {
                return g_mailbox.TestDragOut(text);
            }
            std::vector<std::wstring> parts;
            for (size_t start = 0, bar; start <= text.size(); start = bar + 1) {
                bar = text.find(L'|', start);
                if (bar == std::wstring::npos) {
                    bar = text.size();
                }
                parts.push_back(text.substr(start, bar - start));
            }
            auto item = reinterpret_cast<HTREEITEM>(static_cast<INT_PTR>(_wtoi64(parts[0].c_str())));
            return g_mailbox.TestDropFiles(item, std::vector<std::wstring>(parts.begin() + 1, parts.end()));
        }
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
        if (g_dragging) {
            DragSplitter({static_cast<short>(LOWORD(lParam)), static_cast<short>(HIWORD(lParam))});
        }
        return 0;
    case WM_LBUTTONUP:
    case WM_CAPTURECHANGED:
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
    case WM_INITMENUPOPUP:
        UpdateMenu(reinterpret_cast<HMENU>(wParam));
        break;
    case WM_CONTEXTMENU:
        // the menu key or Shift+F10 in the message list (a right click comes as NM_RCLICK)
        if (reinterpret_cast<HWND>(wParam) == g_mailbox.List()) {
            g_mailbox.MessageMenu({GET_X_LPARAM(lParam), GET_Y_LPARAM(lParam)});
            return 0;
        }
        break;
    case WM_NOTIFY: {
        auto* header = reinterpret_cast<NMHDR*>(lParam);
        if (header->hwndFrom == g_toolbar && header->code == TBN_DROPDOWN) {
            AccountMenu(reinterpret_cast<NMTOOLBARW*>(lParam));
            return TBDDRET_DEFAULT;
        }
        LRESULT result = 0;
        if (g_mailbox.OnNotify(header, result)) {
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
            // a reload or a search changes the counts
            ShowCounts();
        }
        return 0;
    case WM_FILES_DONE:
        g_mailbox.FilesDone(lParam);
        return 0;
    case WM_IMPORT_DROPPED:
        g_mailbox.ImportDropped(wParam, lParam);
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
            g_restart = false;
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
        g_restart = false;
        return 0;
    case WM_DESTROY:
        RemovePropW(hwnd, kStoreProperty);
        KillTimer(hwnd, TIMER_SYNC);
        TrayRemove(hwnd);
        DestroyComposeWindows();
        DestroyMessageWindows();
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

// the app again with the options of this run (Options, another language): its window and core are gone, so it is
// the one the new one finds running
void Restart() {
    wchar_t exe[MAX_PATH] = L"";
    if (!GetModuleFileNameW(nullptr, exe, MAX_PATH)) {
        return;
    }
    std::wstring line = QuoteArgument(exe) + g_arguments.restart;
    STARTUPINFOW startup = {sizeof(startup)};
    PROCESS_INFORMATION process = {};
    if (CreateProcessW(exe, line.data(), nullptr, nullptr, FALSE, 0, nullptr, nullptr, &startup, &process)) {
        CloseHandle(process.hThread);
        CloseHandle(process.hProcess);
    }
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
    // OLE for dragging messages out of the app and files into it (COM in a single-threaded apartment with it)
    if (FAILED(OleInitialize(nullptr))) {
        return 1;
    }
    ReadArguments();
    // the version to standard output (redirected when a script runs it: the release's boot test), no window
    if (g_arguments.version) {
        std::string text = "Inbox Classic " + std::string(pe_version()) + "\n";
        DWORD written = 0;
        WriteFile(GetStdHandle(STD_OUTPUT_HANDLE), text.data(), static_cast<DWORD>(text.size()), &written, nullptr);
        OleUninitialize();
        return 0;
    }
    if (g_arguments.mcp) {
        int result = RelayMcp();
        OleUninitialize();
        return result;
    }
    // the app is open already for this mail store: it takes the link, or comes to the front (not for a start in the
    // background: the agent that asked for it finds it running)
    if (g_arguments.background ? RunningWindow() != nullptr : HandOver()) {
        OleUninitialize();
        return 0;
    }
    // the words of every window in the language in use, from here on
    StartLanguage(g_arguments.language);
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
    // started for an agent: in the tray, where it checks mail as it does with its window closed
    if (!g_arguments.background) {
        ShowWindow(hwnd, show);
        UpdateWindow(hwnd);
        g_mailbox.SelectStart();
        FirstRun();
    }
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
        if (ComposeKey(msg) || MessageWindowKey(msg)) {
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
    OleUninitialize();
    if (g_restart) {
        Restart();
    }
    return static_cast<int>(msg.wParam);
}
