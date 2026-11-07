// A message in a window of its own, as Outlook Express opens one on a double-click: a toolbar to answer it, print it,
// delete, archive or junk it and to go to the message before or after it in the list it came from, over the reading
// pane (reader.h) that shows it as the main window does. Several can be open at once, each with its own taskbar
// button. What a message is, and which one comes before or after it, the core says.
#include "app.h"
#include "icons.h"

#include <algorithm>
#include <utility>
#include <vector>

namespace {

const wchar_t* kMessageClass = L"InboxClassicMessage";
const wchar_t* kTitle = L"Inbox Classic";
// a find in the message found nothing: said in a message box, outside the WebView2 event
constexpr UINT WM_NOT_FOUND = WM_APP + 70;

struct MessageWindow {
    HWND hwnd = nullptr;
    // the main window, which says in its status bar what was done here, through the mailbox
    HWND main = nullptr;
    PeCore* core = nullptr;
    Mailbox* mailbox = nullptr;
    // the list it was opened from: Previous and Next go through it
    MessageListOrder order;
    // the message shown, and the ones before and after it in that list (0 for none)
    int64_t folder = 0;
    uint64_t uid = 0;
    int64_t previousFolder = 0;
    uint64_t previousUid = 0;
    int64_t nextFolder = 0;
    uint64_t nextUid = 0;
    std::wstring subject;
    HWND toolbar = nullptr;
    // the etched line between the toolbar and the message
    HWND rule = nullptr;
    // the tooltips of Previous and Next, kept while the toolbar may ask for them
    std::wstring previousTip;
    std::wstring nextTip;
    // what a find that found nothing says (WM_NOT_FOUND)
    std::wstring notFound;
    Reader reader;
};

// the message windows open, in the order they opened
std::vector<HWND> g_messageWindows;

MessageWindow* StateOf(HWND hwnd) {
    return reinterpret_cast<MessageWindow*>(GetWindowLongPtrW(hwnd, GWLP_USERDATA));
}

// the messages before and after it in its list, while the list has it; one that left it (read, in a list of unread
// ones) keeps those it had
void FindNeighbours(MessageWindow* state) {
    int64_t previousFolder = 0, nextFolder = 0;
    uint64_t previousUid = 0, nextUid = 0;
    if (pe_list_view_neighbours(state->core, state->order.view.get(), state->folder, state->uid, &previousFolder, &previousUid,
                                &nextFolder, &nextUid)) {
        state->previousFolder = previousFolder;
        state->previousUid = previousFolder ? previousUid : 0;
        state->nextFolder = nextFolder;
        state->nextUid = nextFolder ? nextUid : 0;
    }
}

// whether the list it came from can have messages of `folder`: its own, every Inbox for All Inboxes, any for a search
bool ListHas(const MessageWindow* state, int64_t folder) {
    if (folder == state->folder || (state->order.folder == 0 && !state->order.allInboxes)) {
        return true;
    }
    return state->order.allInboxes ? state->mailbox->IsInbox(folder) : folder == state->order.folder;
}

// the message alone as a selection, and what it is in numbers
core::Selection SelectionOf(const MessageWindow* state, PeSelectionSummary& summary) {
    core::Selection selection(pe_selection_new());
    pe_selection_add(selection.get(), state->folder, state->uid);
    summary = {};
    pe_selection_summary(state->core, selection.get(), &summary);
    return selection;
}

// the subject and the app's name, the app's name alone until the subject is known
void ShowTitle(MessageWindow* state, bool known) {
    std::wstring subject = state->subject.empty() ? core::T(PE_TEXT_UI_NO_SUBJECT) : state->subject;
    SetWindowTextW(state->hwnd, known ? (subject + L" - " + kTitle).c_str() : kTitle);
}

// Previous and Next off at the ends of the list, Archive where the message can be archived (`summary`), Not Junk in
// place of Junk for a message in a Junk folder
void UpdateButtons(MessageWindow* state, const PeSelectionSummary& summary) {
    HWND bar = state->toolbar;
    SendMessageW(bar, TB_ENABLEBUTTON, IDC_PREVIOUS, MAKELONG(state->previousUid ? TRUE : FALSE, 0));
    SendMessageW(bar, TB_ENABLEBUTTON, IDC_NEXT, MAKELONG(state->nextUid ? TRUE : FALSE, 0));
    SendMessageW(bar, TB_ENABLEBUTTON, IDM_ARCHIVE, MAKELONG(summary.archivable ? TRUE : FALSE, 0));
    SetJunkButton(bar, summary.in_junk);
}

void Layout(MessageWindow* state) {
    RECT client;
    GetClientRect(state->hwnd, &client);
    SendMessageW(state->toolbar, TB_AUTOSIZE, 0, 0);
    RECT bar;
    GetWindowRect(state->toolbar, &bar);
    int pad = Scale(4), top = bar.bottom - bar.top;
    MoveWindow(state->rule, 0, top, client.right, 2, TRUE);
    state->reader.Layout({pad, top + 2 + pad, client.right - pad, client.bottom - pad});
}

// the message `uid` of `folder` shown in the window, and marked read; the header from `row` (NULL for none) until the
// message is there
void Show(MessageWindow* state, int64_t folder, uint64_t uid, const PeMessage* row = nullptr) {
    state->folder = folder;
    state->uid = uid;
    state->previousFolder = state->nextFolder = 0;
    state->previousUid = state->nextUid = 0;
    FindNeighbours(state);
    state->subject = row ? Text(row->subject) : L"";
    state->reader.Clear(true);
    state->reader.Open(folder, uid, state->mailbox->AccountOf(folder), row);
    PeSelectionSummary summary;
    SelectionOf(state, summary);
    if (summary.unread > 0) {
        pe_message_set_seen(state->core, folder, uid, true);
    }
    ShowTitle(state, row != nullptr);
    UpdateButtons(state, summary);
    Layout(state);
}

// the next unread message of its list; at the end of it, the main window says none is left (the window stays in its
// list, it does not go on to another folder)
void NextUnread(MessageWindow* state) {
    int64_t folder = 0;
    uint64_t uid = 0;
    char* question = nullptr;
    PeNextUnread step =
        pe_list_view_next_unread_step(state->core, state->order.view.get(), state->folder, state->uid, &folder, &uid, &question);
    core::String unused(question);
    if (step == PE_NEXT_UNREAD_MESSAGE && uid) {
        Show(state, folder, uid);
    } else {
        state->mailbox->Say(core::T(PE_TEXT_NO_UNREAD_LEFT));
    }
}

void Go(MessageWindow* state, bool forward) {
    int64_t folder = forward ? state->nextFolder : state->previousFolder;
    uint64_t uid = forward ? state->nextUid : state->previousUid;
    if (uid) {
        Show(state, folder, uid);
    }
}

// Delete, Archive, Junk or Not Junk done to the message, the main window's status bar told; then the next message of
// the list shown (the one before it at the end), or the window closed when there is none
void Act(MessageWindow* state, PeAction action) {
    PeSelectionSummary summary;
    core::Selection selection = SelectionOf(state, summary);
    if (summary.count == 0 || (action == PE_ACTION_ARCHIVE && !summary.archivable)) {
        return;
    }
    if (action == PE_ACTION_DELETE) {
        // from Deleted Items, or an account without one, it is gone for good: asked first, as in the main window
        core::String question(pe_selection_delete_question(&summary));
        if (question &&
            MessageBoxW(state->hwnd, Text(question.get()).c_str(), kTitle, MB_YESNO | MB_ICONWARNING | MB_DEFBUTTON2) != IDYES) {
            return;
        }
    }
    // where to go once it left the list: found before, as the list no longer has it after
    FindNeighbours(state);
    bool forward = state->nextUid != 0;
    char* reason = nullptr;
    core::String done(pe_selection_act(state->core, selection.get(), action, 0, &reason));
    state->mailbox->Say(done ? Text(done.get()) : ReasonText(reason, PE_TEXT_UI_MESSAGES_NOT_CHANGED));
    if (!done) {
        return;
    }
    if (state->nextUid || state->previousUid) {
        Go(state, forward);
    } else {
        DestroyWindow(state->hwnd);
    }
}

void Reply(MessageWindow* state, PeDraftKind kind) {
    core::Draft draft = state->reader.DraftOf(kind);
    if (!draft) {
        MessageBoxW(state->hwnd, core::T(PE_TEXT_UI_NOT_DOWNLOADED).c_str(), kTitle, MB_OK | MB_ICONINFORMATION);
        return;
    }
    OpenCompose(state->main, state->core, state->mailbox->AccountOf(state->folder), pe_draft_info(draft.get()));
}

// the Unsubscribe link: asked first; what it did in the main window's status bar, a message to write for a mailto:
// link
void Unsubscribe(MessageWindow* state) {
    std::wstring mailto;
    if (std::wstring said = state->reader.Unsubscribe(state->hwnd, mailto); !said.empty()) {
        state->mailbox->Say(said);
    }
    if (!mailto.empty()) {
        OpenMailto(mailto, state->mailbox->AccountOf(state->folder));
    }
}

// the command of a shortcut of the window, 0 for a key that is none: Esc closes it, the others are the main window's
WORD ShortcutCommand(UINT key) {
    // Esc with any keys held (Ctrl+Esc never reaches a window): a modifier the window thinks is still held does not
    // keep it open
    if (key == VK_ESCAPE) {
        return IDCANCEL;
    }
    bool control = (GetKeyState(VK_CONTROL) & 0x8000) != 0;
    bool shift = (GetKeyState(VK_SHIFT) & 0x8000) != 0;
    bool alt = (GetKeyState(VK_MENU) & 0x8000) != 0;
    if (alt) {
        return 0;
    }
    if (!control) {
        if (shift) {
            return 0;
        }
        // N: the next unread message, as in the list
        return key == VK_DELETE ? WORD{IDM_DELETE} : key == 'N' ? WORD{IDM_NEXT_UNREAD} : WORD{0};
    }
    if (key == 'R') {
        return shift ? WORD{IDM_REPLY_ALL} : WORD{IDM_REPLY};
    }
    if (shift) {
        return 0;
    }
    if (key == 'F') {
        return IDM_FORWARD;
    }
    return key == 'P' ? WORD{IDM_PRINT} : WORD{0};
}

// the WM_COMMAND of a key of the window, 0 for none: the keys for reading come with code 1, as from accelerators
WPARAM KeyCommand(UINT key) {
    if (WORD reading = ReadingKey(key)) {
        return MAKEWPARAM(reading, 1);
    }
    return ShortcutCommand(key);
}

bool OnCommand(MessageWindow* state, WORD id, WORD code) {
    switch (id) {
    case IDCANCEL:
        PostMessageW(state->hwnd, WM_CLOSE, 0, 0);
        return true;
    case IDC_PREVIOUS:
    case IDC_NEXT:
    case IDM_PREVIOUS_MESSAGE:
    case IDM_NEXT_MESSAGE:
        Go(state, id == IDC_NEXT || id == IDM_NEXT_MESSAGE);
        return true;
    case IDM_FIND_IN_MESSAGE:
        state->reader.FindInMessage(state->hwnd, code == 1);
        return true;
    case IDM_NEXT_UNREAD:
        NextUnread(state);
        return true;
    case IDM_REPLY:
        Reply(state, PE_DRAFT_KIND_REPLY);
        return true;
    case IDM_REPLY_ALL:
        Reply(state, PE_DRAFT_KIND_REPLY_ALL);
        return true;
    case IDM_FORWARD:
        Reply(state, PE_DRAFT_KIND_FORWARD);
        return true;
    case IDM_PRINT:
        state->reader.Print(state->hwnd);
        return true;
    case IDM_DELETE:
        Act(state, PE_ACTION_DELETE);
        return true;
    case IDM_ARCHIVE:
        Act(state, PE_ACTION_ARCHIVE);
        return true;
    case IDM_JUNK:
    case IDM_NOT_JUNK:
        Act(state, id == IDM_JUNK ? PE_ACTION_JUNK : PE_ACTION_NOT_JUNK);
        return true;
    case IDC_UNSUBSCRIBE:
        if (code == STN_CLICKED) {
            Unsubscribe(state);
        }
        return true;
    }
    return state->reader.OnCommand(id, code);
}

LRESULT CALLBACK MessageProc(HWND hwnd, UINT message, WPARAM wParam, LPARAM lParam) {
    MessageWindow* state = StateOf(hwnd);
    if (!state) {
        return DefWindowProcW(hwnd, message, wParam, lParam);
    }
    switch (message) {
    case WM_SIZE:
        Layout(state);
        return 0;
    case WM_COMMAND:
        if (OnCommand(state, LOWORD(wParam), HIWORD(wParam))) {
            return 0;
        }
        break;
    case WM_NOTIFY: {
        auto* header = reinterpret_cast<NMHDR*>(lParam);
        if (header->code == TTN_GETDISPINFOW && (header->idFrom == IDC_PREVIOUS || header->idFrom == IDC_NEXT)) {
            auto* tip = reinterpret_cast<NMTTDISPINFOW*>(lParam);
            tip->lpszText = (header->idFrom == IDC_PREVIOUS ? state->previousTip : state->nextTip).data();
            return 0;
        }
        LRESULT result = 0;
        if (state->reader.OnNotify(header, result)) {
            return result;
        }
        break;
    }
    case WM_TIMER:
        state->reader.OnTimer(wParam);
        return 0;
    case WM_NOT_FOUND:
        if (!state->notFound.empty()) {
            MessageBoxW(hwnd, std::exchange(state->notFound, {}).c_str(), core::Title(PE_TEXT_CMD_FIND_IN_MESSAGE).c_str(),
                        MB_OK | MB_ICONINFORMATION);
        }
        return 0;
    case WM_DRAWITEM:
        if (state->reader.OnDrawItem(*reinterpret_cast<const DRAWITEMSTRUCT*>(lParam))) {
            return TRUE;
        }
        break;
    case WM_SETCURSOR:
        if (state->reader.OnSetCursor(reinterpret_cast<HWND>(wParam))) {
            return TRUE;
        }
        break;
    case WM_CTLCOLORSTATIC:
        if (LRESULT brush = 0; state->reader.OnCtlColor(reinterpret_cast<HWND>(lParam), reinterpret_cast<HDC>(wParam), brush)) {
            return brush;
        }
        return ButtonFaceColor(reinterpret_cast<HDC>(wParam));
    case WM_DESTROY:
        state->reader.Destroy();
        // not owned, so Windows would hand the keyboard to whatever window is next: back to the main window, as a
        // compose window does, unless it is minimized or in the tray
        if (GetForegroundWindow() == hwnd && IsWindowVisible(state->main) && !IsIconic(state->main)) {
            SetForegroundWindow(state->main);
        }
        break;
    case WM_NCDESTROY:
        std::erase(g_messageWindows, hwnd);
        delete state;
        SetWindowLongPtrW(hwnd, GWLP_USERDATA, 0);
        break;
    }
    return DefWindowProcW(hwnd, message, wParam, lParam);
}

void CreateToolbar(MessageWindow* state) {
    // the labels under the icons as in the main window; Previous and Next have a tooltip that says what they go to
    state->toolbar = CreateBar(state->hwnd, CCS_NODIVIDER | CCS_TOP | TBSTYLE_TOOLTIPS, IDC_MESSAGE_TOOLBAR, BarIcons::Big);
    struct Button {
        WORD id;
        PeText text;
        int icon;
    };
    // in groups as Outlook Express has them: answering, the message, going through the list (0 separates)
    const Button buttons[] = {
        {IDM_REPLY, PE_TEXT_UI_TB_REPLY, ICON_ARROW_REPLY},
        {IDM_REPLY_ALL, PE_TEXT_UI_TB_REPLY_ALL, ICON_ARROW_REPLY_ALL},
        {IDM_FORWARD, PE_TEXT_UI_TB_FORWARD, ICON_ARROW_FORWARD},
        {0, PE_TEXT_MENU_FILE, 0},
        {IDM_PRINT, PE_TEXT_UI_TB_PRINT, ICON_PRINT},
        {IDM_DELETE, PE_TEXT_UI_TB_DELETE, ICON_DELETE},
        {IDM_ARCHIVE, PE_TEXT_UI_TB_ARCHIVE, ICON_ARCHIVE},
        // Not Junk in place of it in a Junk folder (UpdateButtons)
        {IDM_JUNK, PE_TEXT_UI_TB_JUNK, ICON_MAIL_PROHIBITED},
        {0, PE_TEXT_MENU_FILE, 0},
        {IDC_PREVIOUS, PE_TEXT_UI_TB_PREVIOUS, ICON_ARROW_UP},
        {IDC_NEXT, PE_TEXT_UI_TB_NEXT, ICON_ARROW_DOWN},
    };
    for (const Button& button : buttons) {
        std::wstring label = button.id ? core::T(button.text) : std::wstring();
        AddButton(state->toolbar, button.id, button.id ? label.c_str() : nullptr, BTNS_BUTTON, button.icon);
    }
    state->rule = CreateChild(state->hwnd, L"STATIC", L"", SS_ETCHEDHORZ, 0, {});
    state->previousTip = core::T(PE_TEXT_UI_PREVIOUS_TIP);
    state->nextTip = core::T(PE_TEXT_UI_NEXT_TIP);
    SendMessageW(state->toolbar, TB_AUTOSIZE, 0, 0);
}

// a copy of the open message windows, as closing one changes g_messageWindows
std::vector<HWND> MessageWindows() {
    return g_messageWindows;
}

}  // namespace

void OpenMessageWindow(HWND main, PeCore* core, Mailbox* mailbox, MessageListOrder order, int64_t folder, uint64_t uid,
                       const PeMessage* row) {
    // open already: brought to the front
    for (HWND hwnd : g_messageWindows) {
        MessageWindow* state = StateOf(hwnd);
        if (state && state->folder == folder && state->uid == uid) {
            if (IsIconic(hwnd)) {
                ShowWindow(hwnd, SW_RESTORE);
            }
            SetForegroundWindow(hwnd);
            return;
        }
    }
    static bool registered = false;
    if (!registered) {
        WNDCLASSEXW windowClass = {sizeof(windowClass)};
        windowClass.lpfnWndProc = MessageProc;
        windowClass.hInstance = GetModuleHandleW(nullptr);
        windowClass.hCursor = LoadCursorW(nullptr, IDC_ARROW);
        SetAppIcons(windowClass);
        windowClass.hbrBackground = reinterpret_cast<HBRUSH>(COLOR_BTNFACE + 1);
        windowClass.lpszClassName = kMessageClass;
        RegisterClassExW(&windowClass);
        registered = true;
    }
    // no owner: a window of its own, as in Outlook Express, that the main window can come in front of
    HWND hwnd = CreateWindowExW(WS_EX_CONTROLPARENT | WS_EX_APPWINDOW, kMessageClass, kTitle, WS_OVERLAPPEDWINDOW | WS_CLIPCHILDREN,
                                CW_USEDEFAULT, CW_USEDEFAULT, Scale(800), Scale(640), nullptr, nullptr, GetModuleHandleW(nullptr), nullptr);
    if (!hwnd) {
        return;
    }
    auto* state = new MessageWindow;
    state->hwnd = hwnd;
    state->main = main;
    state->core = core;
    state->mailbox = mailbox;
    state->order = std::move(order);
    CreateToolbar(state);
    state->reader.Create(hwnd, core);
    // what the window does on a key also while the message has the keyboard
    state->reader.SetKeys([hwnd](UINT key) {
        WPARAM command = KeyCommand(key);
        if (command) {
            PostMessageW(hwnd, WM_COMMAND, command, 0);
        }
        return command != 0;
    });
    // words not found: said once the find is over (not in the WebView2 event that tells it)
    state->reader.onFound = [state](const std::wstring& said) {
        state->notFound = said;
        if (!said.empty()) {
            PostMessageW(state->hwnd, WM_NOT_FOUND, 0, 0);
        }
    };
    // the message a bounce names: selected in the main window, which comes to the front
    state->reader.onBouncedMessage = [state](int64_t folder, uint64_t uid) {
        ShowMain();
        state->mailbox->ShowMessage(folder, uid);
    };
    // the subject from the message itself once it is there
    state->reader.onShown = [state] {
        if (const PeMessageInfo* info = state->reader.Info()) {
            state->subject = Text(info->subject);
            ShowTitle(state, true);
        }
    };
    SetWindowLongPtrW(hwnd, GWLP_USERDATA, reinterpret_cast<LONG_PTR>(state));
    g_messageWindows.push_back(hwnd);
    Show(state, folder, uid, row);
    ShowWindow(hwnd, SW_SHOW);
    SetForegroundWindow(hwnd);
    SetFocus(hwnd);
}

void MessageWindowsEvent(const UiEvent& event) {
    for (HWND hwnd : MessageWindows()) {
        MessageWindow* state = StateOf(hwnd);
        if (!state) {
            continue;
        }
        state->reader.OnEvent(event);
        switch (event.kind) {
        case PE_EVENT_KIND_UNSUBSCRIBED:
            if (std::wstring said = state->reader.Unsubscribed(event.uid, event.message); !said.empty()) {
                state->mailbox->Say(said);
            }
            break;
        case PE_EVENT_KIND_FOLDER_CHANGED:
        case PE_EVENT_KIND_FOLDERS_CHANGED: {
            // a folder its list can not have
            if (event.kind == PE_EVENT_KIND_FOLDER_CHANGED && !ListHas(state, event.folder)) {
                break;
            }
            // moved or deleted elsewhere: the window goes with it
            if ((event.kind == PE_EVENT_KIND_FOLDERS_CHANGED || event.folder == state->folder) &&
                !pe_message_exists(state->core, state->folder, state->uid)) {
                DestroyWindow(hwnd);
                break;
            }
            // the list changed around it
            FindNeighbours(state);
            PeSelectionSummary summary;
            SelectionOf(state, summary);
            UpdateButtons(state, summary);
            break;
        }
        default:
            break;
        }
    }
}

bool MessageWindowKey(const MSG& msg) {
    if (msg.message != WM_KEYDOWN) {
        return false;
    }
    HWND root = GetAncestor(msg.hwnd, GA_ROOT);
    if (std::find(g_messageWindows.begin(), g_messageWindows.end(), root) == g_messageWindows.end()) {
        return false;
    }
    WPARAM command = KeyCommand(static_cast<UINT>(msg.wParam));
    if (!command) {
        return false;
    }
    PostMessageW(root, WM_COMMAND, command, 0);
    return true;
}

void DestroyMessageWindows() {
    for (HWND hwnd : MessageWindows()) {
        DestroyWindow(hwnd);
    }
}
