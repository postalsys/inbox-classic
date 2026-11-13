// The window a message is written in: the address fields, a format bar in the manner of Outlook Express and the HTML
// editor (editor.h). The fields go to the core as typed and the editor's HTML as it comes: the core parses and checks
// the recipients, sanitizes the HTML, adds the quoted message, reads the attached files and builds the message, so
// this file only edits.
#include "app.h"
#include "editor.h"
#include "icons.h"
#include "webview.h"

#include <commdlg.h>
#include <shellapi.h>
#include <windowsx.h>

#include <algorithm>
#include <utility>
#include <vector>

namespace {

const wchar_t* kComposeClass = L"InboxClassicCompose";

// the compose windows open, in the order they opened
std::vector<HWND> g_composeWindows;

enum ComposeId : WORD {
    IDC_SEND = 300,
    IDC_ATTACH,
    IDC_TO,
    IDC_CC,
    IDC_BCC,
    IDC_SUBJECT,
    IDC_BODY,
    IDC_FILES,
    // 308 was Send Later; the ids after it stay as the UI test knows them
    IDC_SAVE = 309,
    IDC_FROM,
    // the buttons at the end of the To row that open the Cc and Bcc rows
    IDC_SHOW_CC,
    IDC_SHOW_BCC,
    // the To, Cc and Bcc labels, buttons that open Select Recipients
    IDC_PICK_TO_BUTTON,
    IDC_PICK_CC_BUTTON,
    IDC_PICK_BCC_BUTTON,
    IDC_FONT = 320,
    IDC_FONT_SIZE,
    IDC_FORMATBAR,
    // the buttons of the format bar
    IDF_BOLD = 330,
    IDF_ITALIC,
    IDF_UNDERLINE,
    IDF_COLOR,
    IDF_NUMBERS,
    IDF_BULLETS,
    IDF_OUTDENT,
    IDF_INDENT,
    IDF_LEFT,
    IDF_CENTER,
    IDF_RIGHT,
    IDF_LINK,
    IDF_LINE,
    IDF_PICTURE,
};

// the buttons whose state the page reports, in the order of its flags: keep in step with STATE in
// core/crates/pe-html/src/editor.js
const ComposeId kStateButtons[] = {IDF_BOLD, IDF_ITALIC, IDF_UNDERLINE, IDF_NUMBERS, IDF_BULLETS, IDF_LEFT, IDF_CENTER, IDF_RIGHT};

const wchar_t* kFonts[] = {L"Arial", L"Arial Black", L"Comic Sans MS", L"Courier New", L"Georgia", L"Segoe UI",
                           L"Tahoma", L"Times New Roman", L"Trebuchet MS", L"Verdana"};
// the sizes of <font size>, 1 to 7, in points
const wchar_t* kSizes[] = {L"8", L"10", L"12", L"14", L"18", L"24", L"36"};

// what a window that writes formatted text has: the editor, and the format bar over it (the compose window, the
// signature editor)
struct Writing {
    Editor editor;
    HWND formatBar = nullptr;
    HWND font = nullptr;
    HWND size = nullptr;
    // the custom colors of the color dialog
    COLORREF colors[16] = {};
};

struct Compose : Writing {
    PeCore* core;
    int64_t account;
    // the main window, told when this one is gone
    HWND main = nullptr;
    // the status bar at the bottom: whether the draft is saved, or while the cursor is in a link or the mouse over one,
    // where it goes
    HWND status = nullptr;
    std::wstring statusText;
    std::string inReplyTo;
    std::string references;
    std::string quote;
    // the quoted message was plain text: with nothing formatted written, the message goes as plain text (the core
    // decides), with this as its quote while the user left the quote folded
    bool quotePlain = false;
    std::string quoteText;
    // the attached files, with what the Attach row shows for each: the name and the size when it was added
    struct File {
        std::wstring path;
        std::wstring label;
    };
    std::vector<File> files;
    // the Message-ID of the draft saved in Drafts, empty before the first save
    std::string messageId;
    // the account whose Drafts has that copy, 0 before the first save; another than `account` once From changed, and
    // the core moves the copy over with the next save or send
    int64_t draftAccount = 0;
    // what to do with the editor's HTML once it comes: send, save in Drafts, or save and close the window
    enum class Pending { None, Send, Save, SaveAndClose } pending = Pending::None;
    std::wstring html;
    // where the quote is (see EditorQuote), and the quote as the user left it once unfolded
    EditorQuote quoteState = EditorQuote::Folded;
    std::string editedQuote;
    // something was typed: closing asks first
    bool dirty = false;
    bool filling = true;
    HWND toolbar = nullptr;
    // the rows of fields: From, To, Cc, Bcc, Subject, Attach
    static constexpr int kRows = 6;
    HWND labels[kRows] = {};
    // the Cc and Bcc rows are shown when they have something in them or were opened; the Attach row with files
    bool showCc = false;
    bool showBcc = false;
    HWND ccButton = nullptr;
    HWND bccButton = nullptr;
    // the accounts it can go from, in the order of the From list
    std::vector<int64_t> fromAccounts;
    HWND from = nullptr;
    HWND to = nullptr;
    HWND cc = nullptr;
    HWND bcc = nullptr;
    HWND subject = nullptr;
    HWND attached = nullptr;
    HWND body = nullptr;
};

COLORREF g_lastColor = RGB(0x00, 0x33, 0x66);

// the editor's HTML arrived (in Compose::html): send it, outside the WebView2 event that brought it
constexpr UINT WM_SEND_HTML = WM_APP + 1;

Compose* StateOf(HWND hwnd) {
    return reinterpret_cast<Compose*>(GetWindowLongPtrW(hwnd, GWLP_USERDATA));
}

// what the status bar of the window says about the draft
void SetComposeStatus(Compose* state, const std::wstring& text) {
    state->statusText = text;
    SendMessageW(state->status, SB_SETTEXTW, 0, reinterpret_cast<LPARAM>(text.c_str()));
}

// where the link under the mouse, or else the one the cursor is in, goes; the status as it was without either
void ShowLink(Compose* state, const std::wstring& link) {
    std::wstring text = link.empty() ? state->statusText : link + L"    " + core::T(PE_TEXT_WIN_CTRL_CLICK_TO_OPEN, {{"ctrl", core::Plain(PE_TEXT_KEY_CTRL)}});
    SendMessageW(state->status, SB_SETTEXTW, 0, reinterpret_cast<LPARAM>(text.c_str()));
}

// the message changed since it was sent to Drafts or opened: a "saved" status no longer holds
void Changed(Compose* state) {
    if (!state->dirty && !state->filling) {
        SetComposeStatus(state, L"");
    }
    state->dirty = true;
}

// a file of the Attach row, its name after the margin the edit fields keep before their text
void DrawFile(const Compose* state, const DRAWITEMSTRUCT& item) {
    if (item.itemID == static_cast<UINT>(-1)) {
        return;
    }
    bool selected = (item.itemState & ODS_SELECTED) != 0;
    FillRect(item.hDC, &item.rcItem, GetSysColorBrush(selected ? COLOR_HIGHLIGHT : COLOR_WINDOW));
    size_t length = static_cast<size_t>(SendMessageW(item.hwndItem, LB_GETTEXTLEN, item.itemID, 0));
    std::wstring label(length + 1, L'\0');
    SendMessageW(item.hwndItem, LB_GETTEXT, item.itemID, reinterpret_cast<LPARAM>(label.data()));
    label.resize(length);
    RECT text = item.rcItem;
    // where the Subject field's text starts inside its border: its formatting rectangle, margin included
    RECT field = {};
    SendMessageW(state->subject, EM_GETRECT, 0, reinterpret_cast<LPARAM>(&field));
    text.left += field.left;
    SetBkMode(item.hDC, TRANSPARENT);
    SetTextColor(item.hDC, GetSysColor(selected ? COLOR_HIGHLIGHTTEXT : COLOR_WINDOWTEXT));
    DrawTextW(item.hDC, label.c_str(), -1, &text, DT_LEFT | DT_VCENTER | DT_SINGLELINE | DT_NOPREFIX | DT_END_ELLIPSIS);
    if (item.itemState & ODS_FOCUS) {
        DrawFocusRect(item.hDC, &item.rcItem);
    }
}

// the columns of the Attach row narrower as there are more files, down to a readable width
void FitFiles(Compose* state) {
    RECT row;
    GetClientRect(state->attached, &row);
    int each = state->files.empty() ? row.right : static_cast<int>(row.right / static_cast<LONG>(state->files.size()));
    SendMessageW(state->attached, LB_SETCOLUMNWIDTH, std::clamp(each, Scale(120), Scale(240)), 0);
}

int PlaceFormatBar(Writing* state, int left, int top, int right);

// the rows whose label is a button that opens Select Recipients: To, Cc and Bcc
bool IsPickRow(int row) {
    return row >= 1 && row <= 3;
}

void Layout(HWND hwnd, Compose* state) {
    RECT client;
    GetClientRect(hwnd, &client);
    SendMessageW(state->toolbar, TB_AUTOSIZE, 0, 0);
    RECT bar;
    GetWindowRect(state->toolbar, &bar);
    SendMessageW(state->status, WM_SIZE, 0, 0);
    RECT statusBar;
    GetWindowRect(state->status, &statusBar);
    client.bottom -= statusBar.bottom - statusBar.top;
    int pad = Scale(6);
    // the label column as wide as the longest label shown, the To, Cc and Bcc buttons with room for their frame
    int labelWidth = Scale(60);
    for (int i = 0; i < Compose::kRows; i++) {
        labelWidth = std::max(labelWidth, TextWidth(state->labels[i], nullptr) + Scale(IsPickRow(i) ? 22 : 6));
    }
    int rowHeight = Scale(22);
    int y = bar.bottom - bar.top + pad;
    HWND fields[] = {state->from, state->to, state->cc, state->bcc, state->subject, state->attached};
    static_assert(std::size(fields) == Compose::kRows);
    // From, To and Subject always; Cc and Bcc when they have something or were opened; Attach once there are files
    bool shown[] = {true, true, state->showCc, state->showBcc, true, !state->files.empty()};
    // the Cc and Bcc buttons at the end of the To row, for the rows not shown yet
    int buttonWidth = ButtonWidth({GetWindowString(state->ccButton), GetWindowString(state->bccButton)}, 40);
    int buttons = (state->showCc ? 0 : 1) + (state->showBcc ? 0 : 1);
    int right = client.right - pad;
    int toRight = right - buttons * (buttonWidth + Scale(4));
    int toTop = y;
    for (int i = 0; i < Compose::kRows; i++) {
        ShowWindow(state->labels[i], shown[i] ? SW_SHOW : SW_HIDE);
        ShowWindow(fields[i], shown[i] ? SW_SHOW : SW_HIDE);
        if (!shown[i]) {
            continue;
        }
        if (fields[i] == state->to) {
            toTop = y;
        }
        if (IsPickRow(i)) {
            MoveWindow(state->labels[i], pad, y, labelWidth - Scale(6), rowHeight, TRUE);
        } else {
            MoveWindow(state->labels[i], pad, y + Scale(3), labelWidth, rowHeight, TRUE);
        }
        // a combo box's height is that of its open list
        int height = fields[i] == state->from ? Scale(200) : rowHeight;
        int fieldRight = fields[i] == state->to ? toRight : right;
        MoveWindow(fields[i], pad + labelWidth, y, fieldRight - pad - labelWidth, height, TRUE);
        y += rowHeight + Scale(4);
    }
    int buttonLeft = toRight + Scale(4);
    for (auto [button, wanted] : {std::pair{state->ccButton, !state->showCc}, std::pair{state->bccButton, !state->showBcc}}) {
        ShowWindow(button, wanted ? SW_SHOW : SW_HIDE);
        if (wanted) {
            MoveWindow(button, buttonLeft, toTop, buttonWidth, rowHeight, TRUE);
            buttonLeft += buttonWidth + Scale(4);
        }
    }
    y = PlaceFormatBar(state, pad, y, client.right - pad);
    state->editor.Resize({pad, y, client.right - pad, std::max(y, static_cast<int>(client.bottom) - pad)});
    FitFiles(state);
}

// the attached files in the Attach row, side by side; the row is there only with files
void ShowFiles(Compose* state) {
    SendMessageW(state->attached, LB_RESETCONTENT, 0, 0);
    for (const Compose::File& file : state->files) {
        SendMessageW(state->attached, LB_ADDSTRING, 0, reinterpret_cast<LPARAM>(file.label.c_str()));
    }
    Layout(GetParent(state->attached), state);
}

// adds a file that is there (not a folder); false otherwise
bool AddFile(Compose* state, const std::wstring& path) {
    WIN32_FILE_ATTRIBUTE_DATA data;
    if (!GetFileAttributesExW(path.c_str(), GetFileExInfoStandard, &data) || (data.dwFileAttributes & FILE_ATTRIBUTE_DIRECTORY)) {
        return false;
    }
    size_t slash = path.find_last_of(L"\\/");
    std::wstring name = slash == std::wstring::npos ? path : path.substr(slash + 1);
    uint64_t size = (static_cast<uint64_t>(data.nFileSizeHigh) << 32) | data.nFileSizeLow;
    state->files.push_back({path, name + L" (" + FormatSize(size) + L")"});
    return true;
}

void AddFiles(Compose* state, const std::vector<std::wstring>& files) {
    for (const std::wstring& file : files) {
        if (AddFile(state, file)) {
            Changed(state);
        }
    }
    ShowFiles(state);
}

void Attach(HWND hwnd, Compose* state) {
    AddFiles(state, OpenFilesDialog(hwnd, core::Plain(PE_TEXT_UI_INSERT_ATTACHMENT).c_str()));
}

// files dragged from Explorer onto the window
void DropFiles(Compose* state, HDROP drop) {
    std::vector<std::wstring> files;
    UINT count = DragQueryFileW(drop, 0xFFFFFFFF, nullptr, 0);
    for (UINT i = 0; i < count; i++) {
        std::wstring path(DragQueryFileW(drop, i, nullptr, 0), L'\0');
        DragQueryFileW(drop, i, path.data(), static_cast<UINT>(path.size() + 1));
        files.push_back(path);
    }
    DragFinish(drop);
    AddFiles(state, files);
}

// the selected file of the Attach row taken off the message
void RemoveSelectedFile(Compose* state) {
    LRESULT index = SendMessageW(state->attached, LB_GETCURSEL, 0, 0);
    if (index < 0 || static_cast<size_t>(index) >= state->files.size()) {
        return;
    }
    state->files.erase(state->files.begin() + index);
    Changed(state);
    ShowFiles(state);
    size_t left = state->files.size();
    if (left > 0) {
        SendMessageW(state->attached, LB_SETCURSEL, std::min(static_cast<size_t>(index), left - 1), 0);
    }
}

// right-click on a file of the Attach row: Remove
void FileMenu(HWND hwnd, Compose* state, LPARAM at) {
    POINT point;
    if (at == static_cast<LPARAM>(-1)) {
        // from the keyboard (Shift+F10): at the field
        RECT bounds;
        GetWindowRect(state->attached, &bounds);
        point = {bounds.left, bounds.bottom};
    } else {
        point = {GET_X_LPARAM(at), GET_Y_LPARAM(at)};
        POINT client = point;
        ScreenToClient(state->attached, &client);
        LRESULT hit = SendMessageW(state->attached, LB_ITEMFROMPOINT, 0, MAKELPARAM(client.x, client.y));
        if (HIWORD(hit)) {
            return;
        }
        SendMessageW(state->attached, LB_SETCURSEL, LOWORD(hit), 0);
    }
    if (SendMessageW(state->attached, LB_GETCURSEL, 0, 0) < 0) {
        return;
    }
    HMENU menu = CreatePopupMenu();
    AppendMenuW(menu, MF_STRING, 1, MenuItem(PE_TEXT_UI_REMOVE, L"Del").c_str());
    UINT chosen = TrackPopupMenu(menu, TPM_RETURNCMD | TPM_RIGHTBUTTON, point.x, point.y, 0, hwnd, nullptr);
    DestroyMenu(menu);
    if (chosen == 1) {
        RemoveSelectedFile(state);
    }
}

// the message as the core takes it, from the fields and the editor's HTML; `outgoing` points into the strings here
struct Fields {
    std::string to, cc, bcc, subject, body;
    std::vector<std::string> paths;
    std::vector<const char*> attachments;
    PeOutgoing outgoing = {};

    Fields(const Compose* state, const std::wstring& html)
        : to(core::Narrow(GetWindowString(state->to))),
          cc(core::Narrow(GetWindowString(state->cc))),
          bcc(core::Narrow(GetWindowString(state->bcc))),
          subject(core::Narrow(GetWindowString(state->subject))),
          body(core::Narrow(html)) {
        for (const Compose::File& file : state->files) {
            paths.push_back(core::Narrow(file.path));
        }
        for (const std::string& path : paths) {
            attachments.push_back(path.c_str());
        }
        outgoing.to = to.c_str();
        outgoing.cc = cc.c_str();
        outgoing.bcc = bcc.c_str();
        outgoing.subject = subject.c_str();
        outgoing.html = body.c_str();
        // the draft's quote while folded, the user's once unfolded, none once deleted; its plain text (from a plain
        // text original) only for the draft's own
        bool folded = state->quoteState == EditorQuote::Folded;
        const std::string& quote = folded ? state->quote : state->editedQuote;
        outgoing.quote = quote.empty() || state->quoteState == EditorQuote::Removed ? nullptr : quote.c_str();
        outgoing.quote_text = folded && !state->quoteText.empty() ? state->quoteText.c_str() : nullptr;
        outgoing.in_reply_to = state->inReplyTo.empty() ? nullptr : state->inReplyTo.c_str();
        outgoing.references = state->references.c_str();
        outgoing.attachments = attachments.data();
        outgoing.attachment_count = attachments.size();
        outgoing.message_id = state->messageId.empty() ? nullptr : state->messageId.c_str();
        // saved in another account's Drafts before From changed: the core moves it once this account has it
        outgoing.draft_account = state->draftAccount != state->account ? state->draftAccount : 0;
        outgoing.quote_plain = state->quotePlain;
    }
    Fields(const Fields&) = delete;
    Fields& operator=(const Fields&) = delete;
};

// the reason the core gave, or `fallback`
void ShowRefusal(HWND hwnd, char* reason, PeText fallback) {
    core::String error(reason);
    std::wstring why = error ? Text(error.get()) : core::T(fallback);
    MessageBoxW(hwnd, why.c_str(), L"Inbox Classic", MB_OK | MB_ICONWARNING);
}

// sends with the HTML the editor gave, now or with the next Send/Recv
void Send(HWND hwnd, Compose* state, const std::wstring& html) {
    Fields fields(state, html);
    char* reason = nullptr;
    if (!pe_message_send(state->core, state->account, &fields.outgoing, &reason)) {
        // a typo in an address or a file that is gone: the message stays open to fix it
        ShowRefusal(hwnd, reason, PE_TEXT_UI_NOT_SENT);
        return;
    }
    // the main window shows whether the server took it
    state->dirty = false;
    DestroyWindow(hwnd);
}

// saves in Drafts with the HTML the editor gave, in place of the copy saved before; closes the window after when
// `close`
void Save(HWND hwnd, Compose* state, const std::wstring& html, bool close) {
    Fields fields(state, html);
    char* messageId = nullptr;
    char* reason = nullptr;
    if (!pe_draft_save(state->core, state->account, &fields.outgoing, &messageId, &reason)) {
        ShowRefusal(hwnd, reason, PE_TEXT_UI_NOT_SAVED);
        // not closing after all: the main window does not wait for it
        if (close) {
            PostMessageW(state->main, WM_COMPOSE_KEPT, 0, 0);
        }
        return;
    }
    core::String id(messageId);
    state->draftAccount = state->account;
    state->messageId = id ? id.get() : "";
    state->dirty = false;
    state->editor.Clean();
    // the server's answer follows (ComposeDraftSaved)
    SetComposeStatus(state, core::T(PE_TEXT_UI_SAVING_DRAFT));
    if (close) {
        DestroyWindow(hwnd);
    }
}

// the editor's HTML is asked for first, the action follows when it comes
void Request(Compose* state, Compose::Pending action) {
    if (state->pending == Compose::Pending::None) {
        state->pending = action;
        state->editor.Html();
    }
}

void ChooseTextColor(HWND hwnd, Writing* state) {
    CHOOSECOLORW dialog = {sizeof(dialog)};
    dialog.hwndOwner = hwnd;
    dialog.rgbResult = g_lastColor;
    dialog.lpCustColors = state->colors;
    dialog.Flags = CC_RGBINIT | CC_FULLOPEN;
    if (ChooseColorW(&dialog)) {
        g_lastColor = dialog.rgbResult;
        wchar_t color[8];
        swprintf_s(color, L"#%02x%02x%02x", GetRValue(g_lastColor), GetGValue(g_lastColor), GetBValue(g_lastColor));
        state->editor.Exec(L"foreColor", color);
    }
}

// a link address the dialog takes: a web address or an e-mail link, with more than the scheme
bool ValidLink(const std::wstring& url, std::wstring& error) {
    // something after "https://" or "mailto:"
    if (webview::IsLinkScheme(url.c_str()) && url.find_first_not_of(L'/', url.find(L':') + 1) != std::wstring::npos) {
        return true;
    }
    error = core::T(PE_TEXT_UI_LINK_INVALID);
    return false;
}

// the Link button and Ctrl+K: a new link on the selection, or with the cursor in a link its address to change, or to
// empty to take the link off
void InsertLink(HWND hwnd, Writing* state) {
    const std::wstring& current = state->editor.CaretLink();
    bool editing = !current.empty();
    std::vector<FormField> fields = {{core::T(PE_TEXT_UI_LINK_ADDRESS), editing ? current : L"https://"}};
    bool (*newLink)(const std::vector<FormField>&, std::wstring&) = [](const std::vector<FormField>& values, std::wstring& error) {
        return ValidLink(values[0].value, error);
    };
    // an emptied address takes the link off
    bool (*changedLink)(const std::vector<FormField>&, std::wstring&) = [](const std::vector<FormField>& values, std::wstring& error) {
        return values[0].value.empty() || ValidLink(values[0].value, error);
    };
    if (FormDialog(hwnd, core::Plain(editing ? PE_TEXT_UI_EDIT_HYPERLINK : PE_TEXT_UI_HYPERLINK),
                   core::T(editing ? PE_TEXT_UI_EDIT_HYPERLINK_INTRO : PE_TEXT_UI_HYPERLINK_INTRO), fields,
                   editing ? changedLink : newLink)) {
        state->editor.Link(fields[0].value);
    }
}

// the picture file at `path` put in the text at the cursor; false when it is no picture the core takes
bool InsertPictureFile(Writing* state, const std::wstring& path) {
    // the core reads the file and checks that it is a picture
    core::String uri(pe_picture_uri(core::Narrow(path).c_str()));
    if (uri) {
        state->editor.Exec(L"insertImage", Text(uri.get()));
    }
    return uri != nullptr;
}

// files dropped on the text: each picture goes in where they were dropped, as Insert Picture puts one; other files (and
// pictures too large to go inline) are attached, as when dropped on the rest of the window
void DropOnText(Compose* state, const std::vector<std::wstring>& paths) {
    std::vector<std::wstring> attach;
    for (const std::wstring& path : paths) {
        if (!InsertPictureFile(state, path)) {
            attach.push_back(path);
        }
    }
    if (!attach.empty()) {
        AddFiles(state, attach);
    }
}

void InsertPicture(HWND hwnd, Writing* state) {
    std::wstring filter = FileFilter({{core::T(PE_TEXT_UI_FILTER_PICTURES), L"*.png;*.jpg;*.jpeg;*.gif"}});
    std::wstring title = core::Plain(PE_TEXT_UI_INSERT_PICTURE);
    std::wstring path = OpenFileDialog(hwnd, title.c_str(), filter.c_str());
    if (path.empty()) {
        return;
    }
    if (!InsertPictureFile(state, path)) {
        MessageBoxW(hwnd, core::T(PE_TEXT_UI_NOT_A_PICTURE).c_str(), title.c_str(), MB_OK | MB_ICONWARNING);
    }
}

// the buttons of the format bar that are one command of the page
struct PageCommand {
    WORD id;
    const wchar_t* command;
};
const PageCommand kPageCommands[] = {
    {IDF_BOLD, L"bold"},          {IDF_ITALIC, L"italic"},         {IDF_UNDERLINE, L"underline"},
    {IDF_NUMBERS, L"insertOrderedList"}, {IDF_BULLETS, L"insertUnorderedList"}, {IDF_OUTDENT, L"outdent"},
    {IDF_INDENT, L"indent"},      {IDF_LEFT, L"justifyLeft"},      {IDF_CENTER, L"justifyCenter"},
    {IDF_RIGHT, L"justifyRight"}, {IDF_LINE, L"insertHorizontalRule"},
};

// a button of the format bar
bool Format(HWND hwnd, Writing* state, WORD id) {
    for (const PageCommand& command : kPageCommands) {
        if (command.id == id) {
            state->editor.Exec(command.command);
            return true;
        }
    }
    switch (id) {
    case IDF_COLOR:
        ChooseTextColor(hwnd, state);
        return true;
    case IDF_LINK:
        InsertLink(hwnd, state);
        return true;
    case IDF_PICTURE:
        InsertPicture(hwnd, state);
        return true;
    }
    return false;
}

// the pressed state of the bar's buttons, from the page's flags
void ShowState(Writing* state, const std::wstring& flags) {
    for (size_t i = 0; i < std::size(kStateButtons) && i < flags.size(); i++) {
        SendMessageW(state->formatBar, TB_CHECKBUTTON, kStateButtons[i], MAKELONG(flags[i] == L'1', 0));
    }
}

// a font or size chosen on the format bar (WM_COMMAND); false for other commands
bool PickFont(Writing* state, WPARAM wParam, LPARAM lParam) {
    if (HIWORD(wParam) != CBN_SELCHANGE || (LOWORD(wParam) != IDC_FONT && LOWORD(wParam) != IDC_FONT_SIZE)) {
        return false;
    }
    LRESULT chosen = SendMessageW(reinterpret_cast<HWND>(lParam), CB_GETCURSEL, 0, 0);
    if (LOWORD(wParam) == IDC_FONT && chosen >= 0 && chosen < static_cast<LRESULT>(std::size(kFonts))) {
        state->editor.Exec(L"fontName", kFonts[chosen]);
    } else if (LOWORD(wParam) == IDC_FONT_SIZE && chosen >= 0 && chosen < static_cast<LRESULT>(std::size(kSizes))) {
        state->editor.Exec(L"fontSize", std::to_wstring(chosen + 1));
    }
    return true;
}

// the format bar from `left` to `right` at `top`: font, size, then the buttons; where the editor under it starts
int PlaceFormatBar(Writing* state, int left, int top, int right) {
    int x = left;
    MoveWindow(state->font, x, top, Scale(150), Scale(300), TRUE);
    x += Scale(154);
    MoveWindow(state->size, x, top, Scale(48), Scale(300), TRUE);
    x += Scale(54);
    MoveWindow(state->formatBar, x, top - Scale(1), right - x, Scale(26), TRUE);
    return top + Scale(28);
}

void CreateFormatBar(HWND hwnd, Writing* state) {
    state->font = CreateChild(hwnd, L"COMBOBOX", L"", CBS_DROPDOWNLIST | WS_VSCROLL | WS_TABSTOP, IDC_FONT, {});
    for (const wchar_t* font : kFonts) {
        SendMessageW(state->font, CB_ADDSTRING, 0, reinterpret_cast<LPARAM>(font));
    }
    SendMessageW(state->font, CB_SETCURSEL, 0, 0);
    state->size = CreateChild(hwnd, L"COMBOBOX", L"", CBS_DROPDOWNLIST | WS_VSCROLL | WS_TABSTOP, IDC_FONT_SIZE, {});
    for (const wchar_t* size : kSizes) {
        SendMessageW(state->size, CB_ADDSTRING, 0, reinterpret_cast<LPARAM>(size));
    }
    SendMessageW(state->size, CB_SETCURSEL, 1, 0);
    state->formatBar = CreateBar(hwnd, CCS_NODIVIDER | CCS_NOPARENTALIGN | CCS_NORESIZE, IDC_FORMATBAR, BarIcons::Small);
    struct Button {
        int id;
        // the tooltip
        PeText text;
        BYTE style;
        int icon;
    };
    Button buttons[] = {
        {IDF_BOLD, PE_TEXT_WIN_FORMAT_BOLD, BTNS_CHECK, FORMAT_TEXT_BOLD},
        {IDF_ITALIC, PE_TEXT_WIN_FORMAT_ITALIC, BTNS_CHECK, FORMAT_TEXT_ITALIC},
        {IDF_UNDERLINE, PE_TEXT_WIN_FORMAT_UNDERLINE, BTNS_CHECK, FORMAT_TEXT_UNDERLINE},
        {IDF_COLOR, PE_TEXT_UI_FORMAT_COLOR, 0, FORMAT_TEXT_COLOR},
        {0, PE_TEXT_MENU_FILE, 0, 0},
        {IDF_NUMBERS, PE_TEXT_UI_FORMAT_NUMBERS, BTNS_CHECK, FORMAT_TEXT_NUMBER_LIST_LTR},
        {IDF_BULLETS, PE_TEXT_UI_FORMAT_BULLETS, BTNS_CHECK, FORMAT_TEXT_BULLET_LIST_LTR},
        {IDF_OUTDENT, PE_TEXT_UI_FORMAT_OUTDENT, 0, FORMAT_TEXT_INDENT_DECREASE_LTR},
        {IDF_INDENT, PE_TEXT_UI_FORMAT_INDENT, 0, FORMAT_TEXT_INDENT_INCREASE_LTR},
        {0, PE_TEXT_MENU_FILE, 0, 0},
        {IDF_LEFT, PE_TEXT_UI_FORMAT_LEFT, BTNS_CHECK, FORMAT_TEXT_ALIGN_LEFT},
        {IDF_CENTER, PE_TEXT_UI_FORMAT_CENTER, BTNS_CHECK, FORMAT_TEXT_ALIGN_CENTER},
        {IDF_RIGHT, PE_TEXT_UI_FORMAT_RIGHT, BTNS_CHECK, FORMAT_TEXT_ALIGN_RIGHT},
        {0, PE_TEXT_MENU_FILE, 0, 0},
        {IDF_LINK, PE_TEXT_WIN_FORMAT_LINK, 0, FORMAT_LINK},
        {IDF_LINE, PE_TEXT_UI_FORMAT_LINE, 0, FORMAT_LINE_HORIZONTAL_1},
        {IDF_PICTURE, PE_TEXT_UI_INSERT_PICTURE, 0, FORMAT_IMAGE},
    };
    for (const Button& button : buttons) {
        std::wstring tip = button.id ? core::T(button.text, {{"ctrl", core::Plain(PE_TEXT_KEY_CTRL)}}) : std::wstring();
        AddButton(state->formatBar, button.id, button.id ? tip.c_str() : nullptr, static_cast<BYTE>(BTNS_BUTTON | button.style),
                  button.icon);
    }
}

void CreateFields(HWND hwnd, Compose* state) {
    state->status = CreateWindowExW(0, STATUSCLASSNAMEW, nullptr, WS_CHILD | WS_VISIBLE | SBARS_SIZEGRIP, 0, 0, 0, 0, hwnd,
                                    nullptr, GetModuleHandleW(nullptr), nullptr);
    state->toolbar = CreateBar(hwnd, CCS_NODIVIDER | CCS_TOP, 0, BarIcons::Big);
    AddButton(state->toolbar, IDC_SEND, core::T(PE_TEXT_UI_TB_SEND).c_str(), BTNS_BUTTON, ICON_SEND);
    AddButton(state->toolbar, 0, nullptr);
    AddButton(state->toolbar, IDC_SAVE, core::T(PE_TEXT_UI_TB_SAVE).c_str(), BTNS_BUTTON, ICON_SAVE);
    AddButton(state->toolbar, 0, nullptr);
    AddButton(state->toolbar, IDC_ATTACH, core::T(PE_TEXT_UI_TB_ATTACH).c_str(), BTNS_BUTTON, ICON_ATTACH);
    PeText labels[] = {PE_TEXT_UI_FIELD_FROM,    PE_TEXT_UI_FIELD_TO,      PE_TEXT_UI_FIELD_CC,
                       PE_TEXT_UI_FIELD_BCC,     PE_TEXT_UI_FIELD_SUBJECT, PE_TEXT_UI_FIELD_ATTACH};
    static_assert(std::size(labels) == Compose::kRows);
    // To, Cc and Bcc are buttons that open the Address Book's people, as in Outlook Express; not in the Tab order,
    // which goes from field to field
    HWND tip = CreateWindowExW(0, TOOLTIPS_CLASSW, nullptr, WS_POPUP | TTS_ALWAYSTIP, CW_USEDEFAULT, CW_USEDEFAULT, CW_USEDEFAULT,
                               CW_USEDEFAULT, hwnd, nullptr, GetModuleHandleW(nullptr), nullptr);
    std::wstring tipText = core::T(PE_TEXT_UI_PICK_TIP);
    for (int i = 0; i < Compose::kRows; i++) {
        if (!IsPickRow(i)) {
            state->labels[i] = CreateChild(hwnd, L"STATIC", core::T(labels[i]).c_str(), SS_LEFT, 0, {});
            continue;
        }
        state->labels[i] = CreateChild(hwnd, L"BUTTON", core::T(labels[i]).c_str(), BS_PUSHBUTTON, IDC_PICK_TO_BUTTON + i - 1, {});
        // the classic tooltips take the size of their first version
        TOOLINFOW info = {};
        info.cbSize = TTTOOLINFOW_V2_SIZE;
        info.uFlags = TTF_IDISHWND | TTF_SUBCLASS;
        info.hwnd = hwnd;
        info.uId = reinterpret_cast<UINT_PTR>(state->labels[i]);
        info.lpszText = tipText.data();
        SendMessageW(tip, TTM_ADDTOOLW, 0, reinterpret_cast<LPARAM>(&info));
        SetAccessibleDescription(state->labels[i], tipText);
    }
    // who the message goes from: always shown, so it is clear even with one account, and the account it is sent with
    state->from = CreateChild(hwnd, L"COMBOBOX", L"", CBS_DROPDOWNLIST | WS_VSCROLL | WS_TABSTOP, IDC_FROM, {});
    state->to = CreateChild(hwnd, L"EDIT", L"", WS_TABSTOP | ES_AUTOHSCROLL, IDC_TO, {}, WS_EX_CLIENTEDGE);
    // Cc and Bcc wait behind these until needed (Alt+C, Alt+B), as most mail programs have it now
    state->ccButton = CreateChild(hwnd, L"BUTTON", core::T(PE_TEXT_WIN_SHOW_CC).c_str(), BS_PUSHBUTTON, IDC_SHOW_CC, {});
    state->bccButton = CreateChild(hwnd, L"BUTTON", core::T(PE_TEXT_WIN_SHOW_BCC).c_str(), BS_PUSHBUTTON, IDC_SHOW_BCC, {});
    state->cc = CreateChild(hwnd, L"EDIT", L"", WS_TABSTOP | ES_AUTOHSCROLL, IDC_CC, {}, WS_EX_CLIENTEDGE);
    state->bcc = CreateChild(hwnd, L"EDIT", L"", WS_TABSTOP | ES_AUTOHSCROLL, IDC_BCC, {}, WS_EX_CLIENTEDGE);
    // the people written to and heard from, completed as an address is typed
    for (HWND field : {state->to, state->cc, state->bcc}) {
        CompleteAddresses(field, state->core);
    }
    state->subject = CreateChild(hwnd, L"EDIT", L"", WS_TABSTOP | ES_AUTOHSCROLL, IDC_SUBJECT, {}, WS_EX_CLIENTEDGE);
    // the files side by side; Delete or a right-click takes one off
    // drawn here (DrawFile), so its names start where the text of the fields above does
    state->attached = CreateChild(hwnd, L"LISTBOX", L"",
                                  WS_TABSTOP | LBS_MULTICOLUMN | LBS_NOINTEGRALHEIGHT | LBS_WANTKEYBOARDINPUT | LBS_OWNERDRAWFIXED | LBS_HASSTRINGS,
                                  IDC_FILES, {}, WS_EX_CLIENTEDGE);
    SendMessageW(state->attached, LB_SETITEMHEIGHT, 0, MeasureText(L"Ag").cy);
    CreateFormatBar(hwnd, state);
}

// Select Recipients: the people and groups chosen go into To, Cc and Bcc, whose rows open when they get someone
void PickRecipients(HWND hwnd, Compose* state) {
    HWND fields[] = {state->to, state->cc, state->bcc};
    std::wstring texts[3];
    for (int i = 0; i < 3; i++) {
        texts[i] = GetWindowString(fields[i]);
    }
    if (!SelectRecipients(hwnd, state->core, texts)) {
        return;
    }
    for (int i = 0; i < 3; i++) {
        if (texts[i] != GetWindowString(fields[i])) {
            SetWindowTextW(fields[i], texts[i].c_str());
        }
    }
    state->showCc = state->showCc || !texts[1].empty();
    state->showBcc = state->showBcc || !texts[2].empty();
    Layout(hwnd, state);
}

// the From list: each account as "Name <address>", the one the message goes from selected
void FillFrom(Compose* state) {
    core::AccountList accounts(pe_accounts(state->core));
    for (size_t i = 0; i < pe_account_list_count(accounts.get()); i++) {
        const PeAccount* account = pe_account_list_get(accounts.get(), i);
        std::wstring item = Text(account->label);
        SendMessageW(state->from, CB_ADDSTRING, 0, reinterpret_cast<LPARAM>(item.c_str()));
        state->fromAccounts.push_back(account->id);
        if (account->id == state->account) {
            SendMessageW(state->from, CB_SETCURSEL, i, 0);
        }
    }
}

// another account chosen in From: the message goes from it, with its servers, Sent Items and Drafts
void ChooseFrom(Compose* state) {
    LRESULT chosen = SendMessageW(state->from, CB_GETCURSEL, 0, 0);
    if (chosen >= 0 && static_cast<size_t>(chosen) < state->fromAccounts.size() && state->fromAccounts[chosen] != state->account) {
        state->account = state->fromAccounts[chosen];
        // its signature in place of the other's
        core::String signature(pe_signature_block(state->core, state->account));
        state->editor.Signature(signature ? Text(signature.get()) : L"");
        Changed(state);
    }
}

// the editor with the quote of the draft; its messages come back to the window
void CreateEditor(HWND hwnd, Compose* state, const PeDraftInfo* draft) {
    // a saved draft opened again goes on with what was written; anything new (a mailto: link's text too) starts with
    // the account's signature
    bool saved = draft && draft->message_id && *draft->message_id;
    std::string body = draft && draft->body ? draft->body : "";
    if (!saved) {
        core::String signature(pe_signature_block(state->core, state->account));
        if (signature) {
            body += signature.get();
        }
    }
    core::String page(pe_editor_document(draft ? draft->quote : nullptr, draft && draft->quote_folded, body.c_str()));
    Editor::Handlers handlers;
    handlers.error = [hwnd](const std::wstring& error) { MessageBoxW(hwnd, error.c_str(), L"Inbox Classic", MB_OK | MB_ICONERROR); };
    handlers.html = [hwnd, state](const std::wstring& html, EditorQuote quote, const std::wstring& edited) {
        state->html = html;
        state->quoteState = quote;
        state->editedQuote = core::Narrow(edited);
        PostMessageW(hwnd, WM_SEND_HTML, 0, 0);
    };
    handlers.state = [state](const std::wstring& flags) { ShowState(state, flags); };
    handlers.dirty = [state] { Changed(state); };
    handlers.send = [state] { Request(state, Compose::Pending::Send); };
    handlers.save = [state] { Request(state, Compose::Pending::Save); };
    handlers.dropped = [state](const std::vector<std::wstring>& paths) { DropOnText(state, paths); };
    handlers.link = [state](const std::wstring& link) { ShowLink(state, link); };
    handlers.editLink = [hwnd, state] { InsertLink(hwnd, state); };
    state->body = state->editor.Create(hwnd, IDC_BODY, page ? Text(page.get()) : L"", std::move(handlers));
}

// whether the window may close now: when nothing changed since it was sent or saved, or the user does not want it
// saved. Yes saves it in Drafts and closes the window after.
bool MayClose(HWND hwnd, Compose* state) {
    if (!state->dirty) {
        return true;
    }
    switch (MessageBoxW(hwnd, core::T(PE_TEXT_UI_SAVE_CHANGES_ASK).c_str(), L"Inbox Classic", MB_YESNOCANCEL | MB_ICONQUESTION)) {
    case IDYES:
        Request(state, Compose::Pending::SaveAndClose);
        return false;
    case IDNO:
        return true;
    default:
        return false;
    }
}

LRESULT CALLBACK ComposeProc(HWND hwnd, UINT message, WPARAM wParam, LPARAM lParam) {
    Compose* state = StateOf(hwnd);
    switch (message) {
    case WM_SIZE:
        if (state) {
            Layout(hwnd, state);
        }
        return 0;
    case WM_COMMAND:
        if (!state) {
            break;
        }
        if (LOWORD(wParam) == IDC_SEND) {
            Request(state, Compose::Pending::Send);
            return 0;
        }
        if (LOWORD(wParam) == IDC_SAVE) {
            Request(state, Compose::Pending::Save);
            return 0;
        }
        if (LOWORD(wParam) == IDC_SHOW_CC || LOWORD(wParam) == IDC_SHOW_BCC) {
            // the row opens and takes the cursor; its button goes
            bool cc = LOWORD(wParam) == IDC_SHOW_CC;
            (cc ? state->showCc : state->showBcc) = true;
            Layout(hwnd, state);
            SetFocus(cc ? state->cc : state->bcc);
            return 0;
        }
        if (LOWORD(wParam) == IDC_ATTACH) {
            Attach(hwnd, state);
            return 0;
        }
        if (LOWORD(wParam) >= IDC_PICK_TO_BUTTON && LOWORD(wParam) <= IDC_PICK_BCC_BUTTON) {
            PickRecipients(hwnd, state);
            return 0;
        }
        if (HIWORD(wParam) == CBN_SELCHANGE && LOWORD(wParam) == IDC_FROM) {
            ChooseFrom(state);
            return 0;
        }
        if (PickFont(state, wParam, lParam)) {
            return 0;
        }
        if (HIWORD(wParam) == EN_CHANGE && !state->filling) {
            if (LOWORD(wParam) == IDC_SUBJECT) {
                // the window named by its subject as it is typed, as one opened with a subject is
                std::wstring subject = GetWindowString(state->subject);
                SetWindowTextW(hwnd, subject.empty() ? core::Plain(PE_TEXT_UI_NEW_MESSAGE_TITLE).c_str() : subject.c_str());
            }
            Changed(state);
            return 0;
        }
        if (Format(hwnd, state, LOWORD(wParam))) {
            return 0;
        }
        break;
    case WM_SEND_HTML:
        if (state) {
            std::wstring html = std::exchange(state->html, {});
            using Pending = Compose::Pending;
            switch (Pending pending = std::exchange(state->pending, Pending::None)) {
            case Pending::Send:
                Send(hwnd, state, html);
                break;
            case Pending::Save:
            case Pending::SaveAndClose:
                Save(hwnd, state, html, pending == Pending::SaveAndClose);
                break;
            case Pending::None:
                break;
            }
        }
        return 0;
    case WM_VKEYTOITEM:
        // Delete in the Attach row takes the file off
        if (state && reinterpret_cast<HWND>(lParam) == state->attached && LOWORD(wParam) == VK_DELETE) {
            RemoveSelectedFile(state);
            return -2;
        }
        return -1;
    case WM_DRAWITEM:
        if (state && wParam == IDC_FILES) {
            DrawFile(state, *reinterpret_cast<DRAWITEMSTRUCT*>(lParam));
            return TRUE;
        }
        break;
    case WM_CONTEXTMENU:
        if (state && reinterpret_cast<HWND>(wParam) == state->attached) {
            FileMenu(hwnd, state, lParam);
            return 0;
        }
        break;
    case WM_DROPFILES:
        if (state) {
            DropFiles(state, reinterpret_cast<HDROP>(wParam));
        }
        return 0;
    case WM_CTLCOLORSTATIC:
        return ButtonFaceColor(reinterpret_cast<HDC>(wParam));
    case WM_CLOSE:
        if (state && !MayClose(hwnd, state)) {
            return 0;
        }
        break;
    case WM_DESTROY:
        if (state) {
            state->editor.Close();
            // not owned, so Windows would hand the keyboard to whatever window is next: back to the main window, as
            // when it was the owner, unless it is minimized
            if (GetForegroundWindow() == hwnd && IsWindowVisible(state->main) && !IsIconic(state->main)) {
                SetForegroundWindow(state->main);
            }
        }
        break;
    case WM_NCDESTROY:
        std::erase(g_composeWindows, hwnd);
        if (state) {
            PostMessageW(state->main, WM_COMPOSE_CLOSED, 0, 0);
        }
        delete state;
        SetWindowLongPtrW(hwnd, GWLP_USERDATA, 0);
        break;
    }
    return DefWindowProcW(hwnd, message, wParam, lParam);
}

// ---- the signature editor ----

const wchar_t* kSignatureClass = L"InboxClassicSignature";

struct Signature : Writing {
    PeCore* core = nullptr;
    int64_t account = 0;
    HWND hint = nullptr;
    HWND ok = nullptr;
    HWND cancel = nullptr;
    bool done = false;
    bool saved = false;
    // OK pressed: saved once the page gave its HTML
    bool saving = false;
};

void LayoutSignature(HWND hwnd, Signature* state) {
    RECT client;
    GetClientRect(hwnd, &client);
    int pad = Scale(10), buttonWidth = ButtonWidth({GetWindowString(state->ok), GetWindowString(state->cancel)}, 88),
        buttonHeight = Scale(25);
    int top = PlaceFormatBar(state, pad, pad, client.right - pad);
    int buttons = client.bottom - pad - buttonHeight;
    state->editor.Resize({pad, top, client.right - pad, std::max(top, buttons - pad)});
    MoveWindow(state->cancel, client.right - pad - buttonWidth, buttons, buttonWidth, buttonHeight, TRUE);
    MoveWindow(state->ok, client.right - pad - 2 * buttonWidth - Scale(6), buttons, buttonWidth, buttonHeight, TRUE);
    MoveWindow(state->hint, pad, buttons, client.right - 3 * pad - 2 * buttonWidth, buttonHeight, TRUE);
}

LRESULT CALLBACK SignatureProc(HWND hwnd, UINT message, WPARAM wParam, LPARAM lParam) {
    auto* state = reinterpret_cast<Signature*>(GetWindowLongPtrW(hwnd, GWLP_USERDATA));
    switch (message) {
    case WM_SIZE:
        if (state) {
            LayoutSignature(hwnd, state);
        }
        return 0;
    case WM_COMMAND:
        if (!state) {
            break;
        }
        if (LOWORD(wParam) == IDOK) {
            // the page's HTML first; it is saved when it comes
            if (!state->saving) {
                state->saving = true;
                state->editor.Html();
            }
            return 0;
        }
        if (LOWORD(wParam) == IDCANCEL) {
            DestroyWindow(hwnd);
            return 0;
        }
        if (PickFont(state, wParam, lParam) || Format(hwnd, state, LOWORD(wParam))) {
            return 0;
        }
        break;
    case WM_DESTROY:
        if (state) {
            state->editor.Close();
            state->done = true;
        }
        break;
    }
    return DefWindowProcW(hwnd, message, wParam, lParam);
}

}  // namespace

bool EditSignature(HWND owner, PeCore* core, int64_t account, const std::wstring& name) {
    RegisterDialogClass(kSignatureClass, SignatureProc);
    core::String current(pe_account_signature(core, account));
    if (!current) {
        return false;
    }
    HWND dialog = CreateModalWindow(owner, kSignatureClass, core::T(PE_TEXT_WIN_SIGNATURE_TITLE, {{"account", name}}).c_str(), Scale(620), Scale(330));
    Signature state;
    state.core = core;
    state.account = account;
    CreateFormatBar(dialog, &state);
    core::String page(pe_editor_document(nullptr, false, current.get()));
    Editor::Handlers handlers;
    handlers.error = [dialog](const std::wstring& error) { MessageBoxW(dialog, error.c_str(), L"Inbox Classic", MB_OK | MB_ICONERROR); };
    handlers.html = [dialog, &state](const std::wstring& html, EditorQuote, const std::wstring&) {
        state.saved = pe_account_set_signature(state.core, state.account, core::Narrow(html).c_str());
        if (!state.saved) {
            MessageBoxW(dialog, core::T(PE_TEXT_UI_SIGNATURE_NOT_SAVED).c_str(), core::Plain(PE_TEXT_UI_SIGNATURE).c_str(), MB_OK | MB_ICONERROR);
            state.saving = false;
            return;
        }
        // saved: the editor closes
        PostMessageW(dialog, WM_CLOSE, 0, 0);
    };
    handlers.state = [&state](const std::wstring& flags) { ShowState(&state, flags); };
    handlers.save = [dialog] { PostMessageW(dialog, WM_COMMAND, IDOK, 0); };
    handlers.dropped = [&state](const std::vector<std::wstring>& paths) {
        // pictures go in where they were dropped; a signature has no attachments
        for (const std::wstring& path : paths) {
            InsertPictureFile(&state, path);
        }
    };
    handlers.editLink = [dialog, &state] { InsertLink(dialog, &state); };
    state.editor.Create(dialog, IDC_BODY, page ? Text(page.get()) : L"", std::move(handlers));
    // made after the editor, so Tab goes from the format bar to the signature and then to the buttons, as they are laid out
    state.hint = CreateChild(dialog, L"STATIC", core::T(PE_TEXT_UI_SIGNATURE_HINT).c_str(),
                             SS_LEFT | SS_CENTERIMAGE | SS_ENDELLIPSIS, 0, {});
    state.ok = CreateChild(dialog, L"BUTTON", core::T(PE_TEXT_UI_OK).c_str(), WS_TABSTOP | BS_DEFPUSHBUTTON, IDOK, {});
    state.cancel = CreateChild(dialog, L"BUTTON", core::T(PE_TEXT_UI_CANCEL).c_str(), WS_TABSTOP, IDCANCEL, {});
    SetWindowLongPtrW(dialog, GWLP_USERDATA, reinterpret_cast<LONG_PTR>(&state));
    LayoutSignature(dialog, &state);
    state.editor.Focus();
    RunModal(dialog, nullptr, state.done);
    return state.saved;
}

bool ComposeKey(const MSG& msg) {
    if (msg.message != WM_KEYDOWN || msg.wParam != 'S' || !(GetKeyState(VK_CONTROL) & 0x8000)) {
        return false;
    }
    HWND root = GetAncestor(msg.hwnd, GA_ROOT);
    if (std::find(g_composeWindows.begin(), g_composeWindows.end(), root) == g_composeWindows.end()) {
        return false;
    }
    PostMessageW(root, WM_COMMAND, MAKEWPARAM(IDC_SAVE, 0), 0);
    return true;
}

void OpenCompose(HWND main, PeCore* core, int64_t account, const PeDraftInfo* draft) {
    static bool registered = false;
    if (!registered) {
        WNDCLASSEXW windowClass = {sizeof(windowClass)};
        windowClass.lpfnWndProc = ComposeProc;
        windowClass.hInstance = GetModuleHandleW(nullptr);
        windowClass.hCursor = LoadCursorW(nullptr, IDC_ARROW);
        SetAppIcons(windowClass);
        windowClass.hbrBackground = reinterpret_cast<HBRUSH>(COLOR_BTNFACE + 1);
        windowClass.lpszClassName = kComposeClass;
        RegisterClassExW(&windowClass);
        registered = true;
    }
    std::wstring title = draft && draft->subject && *draft->subject ? Text(draft->subject) : core::Plain(PE_TEXT_UI_NEW_MESSAGE_TITLE);
    // no owner: a window of its own, as in Outlook Express, that the main window can come in front of
    HWND hwnd = CreateWindowExW(WS_EX_CONTROLPARENT | WS_EX_APPWINDOW, kComposeClass, title.c_str(),
                                WS_OVERLAPPEDWINDOW | WS_CLIPCHILDREN, CW_USEDEFAULT, CW_USEDEFAULT, Scale(760), Scale(620), nullptr,
                                nullptr, GetModuleHandleW(nullptr), nullptr);
    if (!hwnd) {
        return;
    }
    g_composeWindows.push_back(hwnd);
    auto* state = new Compose{{}, core, account, main};
    SetWindowLongPtrW(hwnd, GWLP_USERDATA, reinterpret_cast<LONG_PTR>(state));
    CreateFields(hwnd, state);
    FillFrom(state);
    // files dropped from Explorer are attached
    DragAcceptFiles(hwnd, TRUE);
    if (draft) {
        SetWindowTextW(state->to, Text(draft->to).c_str());
        SetWindowTextW(state->cc, Text(draft->cc).c_str());
        SetWindowTextW(state->bcc, Text(draft->bcc).c_str());
        // a reply to all with others in Cc, a draft with Bcc: those rows are open
        state->showCc = draft->cc && *draft->cc;
        state->showBcc = draft->bcc && *draft->bcc;
        SetWindowTextW(state->subject, Text(draft->subject).c_str());
        state->inReplyTo = draft->in_reply_to ? draft->in_reply_to : "";
        state->references = draft->references ? draft->references : "";
        state->quote = draft->quote ? draft->quote : "";
        state->quoteText = draft->quote_text ? draft->quote_text : "";
        state->quotePlain = draft->quote_text != nullptr;
        // a saved draft opened again: its files, and its Message-ID so the next save replaces it
        state->messageId = draft->message_id ? draft->message_id : "";
        state->draftAccount = account;
        for (size_t i = 0; i < draft->attachment_count; i++) {
            AddFile(state, Text(draft->attachments[i]));
        }
        ShowFiles(state);
    }
    CreateEditor(hwnd, state, draft);
    state->filling = false;
    Layout(hwnd, state);
    ShowWindow(hwnd, SW_SHOW);
    // the cursor where the user writes: the top of the reply, or the To field of a new message
    if (draft && draft->to && *draft->to) {
        state->editor.Focus();
    } else {
        SetFocus(state->to);
    }
}

namespace {

// a copy of the open compose windows, as closing one changes g_composeWindows
std::vector<HWND> ComposeWindows() {
    return g_composeWindows;
}

}  // namespace

ComposeClose CloseComposeWindows() {
    bool saving = false;
    for (HWND hwnd : ComposeWindows()) {
        SendMessageW(hwnd, WM_CLOSE, 0, 0);
        if (!IsWindow(hwnd)) {
            continue;
        }
        // still open: saving before it closes (Yes), or kept open (Cancel), which keeps the app too
        Compose* state = StateOf(hwnd);
        if (!state || state->pending != Compose::Pending::SaveAndClose) {
            return ComposeClose::Kept;
        }
        saving = true;
    }
    return saving ? ComposeClose::Saving : ComposeClose::Closed;
}

bool ComposeWindowsOpen() {
    return !ComposeWindows().empty();
}

void DestroyComposeWindows() {
    for (HWND hwnd : ComposeWindows()) {
        DestroyWindow(hwnd);
    }
}

bool ComposeDraftSaved(const std::string& messageId, const std::wstring& problem) {
    for (HWND hwnd : ComposeWindows()) {
        Compose* state = StateOf(hwnd);
        if (!state || messageId.empty() || state->messageId != messageId) {
            continue;
        }
        if (!problem.empty()) {
            SetComposeStatus(state, core::T(PE_TEXT_UI_COMPOSE_NOT_SAVED, {{"reason", problem}}));
            return true;
        }
        SetComposeStatus(state, core::T(PE_TEXT_UI_COMPOSE_SAVED_AT, {{"time", TimeNow()}}));
        return true;
    }
    return false;
}
