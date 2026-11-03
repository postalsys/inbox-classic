// The window a message is written in: the address fields, a format bar in the manner of Outlook Express and the HTML
// editor (editor.h). The fields go to the core as typed and the editor's HTML as it comes: the core parses and checks
// the recipients, sanitizes the HTML, adds the quoted message, reads the attached files and builds the message, so
// this file only edits.
#include "app.h"
#include "editor.h"
#include "icons.h"

#include <commdlg.h>
#include <shellapi.h>
#include <windowsx.h>

#include <algorithm>
#include <utility>

namespace {

const wchar_t* kComposeClass = L"InboxClassicCompose";

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

struct Compose {
    PeCore* core;
    int64_t account;
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
    Editor editor;
    // what to do with the editor's HTML once it comes: send, save in Drafts, or save and close the window
    enum class Pending { None, Send, Save, SaveAndClose } pending = Pending::None;
    std::wstring html;
    // where the quote is (see EditorQuote), and the quote as the user left it once unfolded
    EditorQuote quoteState = EditorQuote::Folded;
    std::string editedQuote;
    // something was typed: closing asks first
    bool dirty = false;
    bool filling = true;
    COLORREF colors[16] = {};
    HWND toolbar = nullptr;
    HWND formatBar = nullptr;
    HWND font = nullptr;
    HWND size = nullptr;
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

// the columns of the Attach row narrower as there are more files, down to a readable width
void FitFiles(Compose* state) {
    RECT row;
    GetClientRect(state->attached, &row);
    int each = state->files.empty() ? row.right : static_cast<int>(row.right / static_cast<LONG>(state->files.size()));
    SendMessageW(state->attached, LB_SETCOLUMNWIDTH, std::clamp(each, Scale(120), Scale(240)), 0);
}

void Layout(HWND hwnd, Compose* state) {
    RECT client;
    GetClientRect(hwnd, &client);
    SendMessageW(state->toolbar, TB_AUTOSIZE, 0, 0);
    RECT bar;
    GetWindowRect(state->toolbar, &bar);
    int pad = Scale(6);
    int labelWidth = Scale(60);
    int rowHeight = Scale(22);
    int y = bar.bottom - bar.top + pad;
    HWND fields[] = {state->from, state->to, state->cc, state->bcc, state->subject, state->attached};
    static_assert(std::size(fields) == Compose::kRows);
    // From, To and Subject always; Cc and Bcc when they have something or were opened; Attach once there are files
    bool shown[] = {true, true, state->showCc, state->showBcc, true, !state->files.empty()};
    // the Cc and Bcc buttons at the end of the To row, for the rows not shown yet
    int buttonWidth = Scale(40);
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
        MoveWindow(state->labels[i], pad, y + Scale(3), labelWidth, rowHeight, TRUE);
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
    // the format bar: font, size, then the buttons
    int x = pad;
    MoveWindow(state->font, x, y, Scale(150), Scale(300), TRUE);
    x += Scale(154);
    MoveWindow(state->size, x, y, Scale(48), Scale(300), TRUE);
    x += Scale(54);
    MoveWindow(state->formatBar, x, y - Scale(1), client.right - x - pad, Scale(26), TRUE);
    y += Scale(28);
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
            state->dirty = true;
        }
    }
    ShowFiles(state);
}

void Attach(HWND hwnd, Compose* state) {
    AddFiles(state, OpenFilesDialog(hwnd, L"Insert Attachment", L"All files (*.*)\0*.*\0"));
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
    state->dirty = true;
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
    AppendMenuW(menu, MF_STRING, 1, L"&Remove\tDel");
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
void ShowRefusal(HWND hwnd, char* reason, const wchar_t* fallback) {
    core::String error(reason);
    std::wstring why = error ? Text(error.get()) : fallback;
    MessageBoxW(hwnd, why.c_str(), L"Inbox Classic", MB_OK | MB_ICONWARNING);
}

// sends with the HTML the editor gave, now or with the next Send/Recv
void Send(HWND hwnd, Compose* state, const std::wstring& html) {
    Fields fields(state, html);
    char* reason = nullptr;
    if (!pe_message_send(state->core, state->account, &fields.outgoing, &reason)) {
        // a typo in an address or a file that is gone: the message stays open to fix it
        ShowRefusal(hwnd, reason, L"The message could not be sent.");
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
        ShowRefusal(hwnd, reason, L"The message could not be saved.");
        return;
    }
    core::String id(messageId);
    state->draftAccount = state->account;
    state->messageId = id ? id.get() : "";
    state->dirty = false;
    state->editor.Clean();
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

void ChooseTextColor(HWND hwnd, Compose* state) {
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

void InsertLink(HWND hwnd, Compose* state) {
    std::vector<FormField> fields = {{L"Address:", L"https://"}};
    auto valid = [](const std::vector<FormField>& values, std::wstring& error) {
        const std::wstring& url = values[0].value;
        for (const wchar_t* scheme : {L"https://", L"http://", L"mailto:"}) {
            if (url.size() > wcslen(scheme) && _wcsnicmp(url.c_str(), scheme, wcslen(scheme)) == 0) {
                return true;
            }
        }
        error = L"Type a web address (https://...) or an e-mail link (mailto:...).";
        return false;
    };
    if (FormDialog(hwnd, L"Hyperlink", L"The address the selected text links to.", fields, valid)) {
        state->editor.Link(fields[0].value);
    }
}

void InsertPicture(HWND hwnd, Compose* state) {
    wchar_t path[MAX_PATH] = L"";
    OPENFILENAMEW dialog = {sizeof(dialog)};
    dialog.hwndOwner = hwnd;
    dialog.lpstrFilter = L"Pictures (*.png;*.jpg;*.jpeg;*.gif)\0*.png;*.jpg;*.jpeg;*.gif\0";
    dialog.lpstrFile = path;
    dialog.nMaxFile = MAX_PATH;
    dialog.lpstrTitle = L"Insert Picture";
    dialog.Flags = OFN_EXPLORER | OFN_FILEMUSTEXIST | OFN_NOCHANGEDIR;
    if (!GetOpenFileNameW(&dialog)) {
        return;
    }
    // the core reads the file and checks that it is a picture
    std::string utf8 = core::Narrow(path);
    core::String uri(pe_picture_uri(utf8.c_str()));
    if (!uri) {
        MessageBoxW(hwnd, L"This file is not a PNG, JPEG or GIF picture, or it is larger than 10 MB.", L"Insert Picture",
                    MB_OK | MB_ICONWARNING);
        return;
    }
    state->editor.Exec(L"insertImage", Text(uri.get()));
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
bool Format(HWND hwnd, Compose* state, WORD id) {
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
void ShowState(Compose* state, const std::wstring& flags) {
    for (size_t i = 0; i < std::size(kStateButtons) && i < flags.size(); i++) {
        SendMessageW(state->formatBar, TB_CHECKBUTTON, kStateButtons[i], MAKELONG(flags[i] == L'1', 0));
    }
}

void CreateFormatBar(HWND hwnd, Compose* state) {
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
        const wchar_t* text;
        BYTE style;
        int icon;
    };
    Button buttons[] = {
        {IDF_BOLD, L"Bold (Ctrl+B)", BTNS_CHECK, FORMAT_TEXT_BOLD},
        {IDF_ITALIC, L"Italic (Ctrl+I)", BTNS_CHECK, FORMAT_TEXT_ITALIC},
        {IDF_UNDERLINE, L"Underline (Ctrl+U)", BTNS_CHECK, FORMAT_TEXT_UNDERLINE},
        {IDF_COLOR, L"Font Color", 0, FORMAT_TEXT_COLOR},
        {0, nullptr, 0, 0},
        {IDF_NUMBERS, L"Numbered List", BTNS_CHECK, FORMAT_TEXT_NUMBER_LIST_LTR},
        {IDF_BULLETS, L"Bulleted List", BTNS_CHECK, FORMAT_TEXT_BULLET_LIST_LTR},
        {IDF_OUTDENT, L"Decrease Indent", 0, FORMAT_TEXT_INDENT_DECREASE_LTR},
        {IDF_INDENT, L"Increase Indent", 0, FORMAT_TEXT_INDENT_INCREASE_LTR},
        {0, nullptr, 0, 0},
        {IDF_LEFT, L"Align Left", BTNS_CHECK, FORMAT_TEXT_ALIGN_LEFT},
        {IDF_CENTER, L"Center", BTNS_CHECK, FORMAT_TEXT_ALIGN_CENTER},
        {IDF_RIGHT, L"Align Right", BTNS_CHECK, FORMAT_TEXT_ALIGN_RIGHT},
        {0, nullptr, 0, 0},
        {IDF_LINK, L"Insert Hyperlink", 0, FORMAT_LINK},
        {IDF_LINE, L"Insert Horizontal Line", 0, FORMAT_LINE_HORIZONTAL_1},
        {IDF_PICTURE, L"Insert Picture", 0, FORMAT_IMAGE},
    };
    for (const Button& button : buttons) {
        AddButton(state->formatBar, button.id, button.text, static_cast<BYTE>(BTNS_BUTTON | button.style), button.icon);
    }
}

void CreateFields(HWND hwnd, Compose* state) {
    state->toolbar = CreateBar(hwnd, CCS_NODIVIDER | CCS_TOP, 0, BarIcons::Big);
    AddButton(state->toolbar, IDC_SEND, L"Send", BTNS_BUTTON, ICON_SEND);
    AddButton(state->toolbar, 0, nullptr);
    AddButton(state->toolbar, IDC_SAVE, L"Save", BTNS_BUTTON, ICON_SAVE);
    AddButton(state->toolbar, 0, nullptr);
    AddButton(state->toolbar, IDC_ATTACH, L"Attach", BTNS_BUTTON, ICON_ATTACH);
    const wchar_t* labels[] = {L"From:", L"To:", L"Cc:", L"Bcc:", L"Subject:", L"Attach:"};
    static_assert(std::size(labels) == Compose::kRows);
    for (int i = 0; i < Compose::kRows; i++) {
        state->labels[i] = CreateChild(hwnd, L"STATIC", labels[i], SS_LEFT, 0, {});
    }
    // who the message goes from: always shown, so it is clear even with one account, and the account it is sent with
    state->from = CreateChild(hwnd, L"COMBOBOX", L"", CBS_DROPDOWNLIST | WS_VSCROLL | WS_TABSTOP, IDC_FROM, {});
    state->to = CreateChild(hwnd, L"EDIT", L"", WS_TABSTOP | ES_AUTOHSCROLL, IDC_TO, {}, WS_EX_CLIENTEDGE);
    // Cc and Bcc wait behind these until needed (Alt+C, Alt+B), as most mail programs have it now
    state->ccButton = CreateChild(hwnd, L"BUTTON", L"&Cc", BS_PUSHBUTTON, IDC_SHOW_CC, {});
    state->bccButton = CreateChild(hwnd, L"BUTTON", L"&Bcc", BS_PUSHBUTTON, IDC_SHOW_BCC, {});
    state->cc = CreateChild(hwnd, L"EDIT", L"", WS_TABSTOP | ES_AUTOHSCROLL, IDC_CC, {}, WS_EX_CLIENTEDGE);
    state->bcc = CreateChild(hwnd, L"EDIT", L"", WS_TABSTOP | ES_AUTOHSCROLL, IDC_BCC, {}, WS_EX_CLIENTEDGE);
    state->subject = CreateChild(hwnd, L"EDIT", L"", WS_TABSTOP | ES_AUTOHSCROLL, IDC_SUBJECT, {}, WS_EX_CLIENTEDGE);
    // the files side by side; Delete or a right-click takes one off
    state->attached = CreateChild(hwnd, L"LISTBOX", L"", WS_TABSTOP | LBS_MULTICOLUMN | LBS_NOINTEGRALHEIGHT | LBS_WANTKEYBOARDINPUT,
                                  IDC_FILES, {}, WS_EX_CLIENTEDGE);
    CreateFormatBar(hwnd, state);
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
        state->dirty = true;
    }
}

// the editor with the quote of the draft; its messages come back to the window
void CreateEditor(HWND hwnd, Compose* state, const PeDraftInfo* draft) {
    core::String page(pe_editor_document(draft ? draft->quote : nullptr, draft && draft->quote_folded, draft ? draft->body : nullptr));
    Editor::Handlers handlers;
    handlers.error = [hwnd](const std::wstring& error) { MessageBoxW(hwnd, error.c_str(), L"Inbox Classic", MB_OK | MB_ICONERROR); };
    handlers.html = [hwnd, state](const std::wstring& html, EditorQuote quote, const std::wstring& edited) {
        state->html = html;
        state->quoteState = quote;
        state->editedQuote = core::Narrow(edited);
        PostMessageW(hwnd, WM_SEND_HTML, 0, 0);
    };
    handlers.state = [state](const std::wstring& flags) { ShowState(state, flags); };
    handlers.dirty = [state] { state->dirty = true; };
    handlers.send = [state] { Request(state, Compose::Pending::Send); };
    handlers.save = [state] { Request(state, Compose::Pending::Save); };
    state->body = state->editor.Create(hwnd, IDC_BODY, page ? Text(page.get()) : L"", std::move(handlers));
}

// whether the window may close now: when nothing changed since it was sent or saved, or the user does not want it
// saved. Yes saves it in Drafts and closes the window after.
bool MayClose(HWND hwnd, Compose* state) {
    if (!state->dirty) {
        return true;
    }
    switch (MessageBoxW(hwnd, L"Do you want to save changes to this message in Drafts?", L"Inbox Classic", MB_YESNOCANCEL | MB_ICONQUESTION)) {
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
        if (HIWORD(wParam) == CBN_SELCHANGE && LOWORD(wParam) == IDC_FROM) {
            ChooseFrom(state);
            return 0;
        }
        if (HIWORD(wParam) == CBN_SELCHANGE && (LOWORD(wParam) == IDC_FONT || LOWORD(wParam) == IDC_FONT_SIZE)) {
            HWND list = reinterpret_cast<HWND>(lParam);
            LRESULT chosen = SendMessageW(list, CB_GETCURSEL, 0, 0);
            if (LOWORD(wParam) == IDC_FONT && chosen >= 0 && chosen < static_cast<LRESULT>(std::size(kFonts))) {
                state->editor.Exec(L"fontName", kFonts[chosen]);
            } else if (chosen >= 0 && chosen < static_cast<LRESULT>(std::size(kSizes))) {
                state->editor.Exec(L"fontSize", std::to_wstring(chosen + 1));
            }
            return 0;
        }
        if (HIWORD(wParam) == EN_CHANGE && !state->filling) {
            state->dirty = true;
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
        }
        break;
    case WM_NCDESTROY:
        delete state;
        SetWindowLongPtrW(hwnd, GWLP_USERDATA, 0);
        break;
    }
    return DefWindowProcW(hwnd, message, wParam, lParam);
}

}  // namespace

bool ComposeKey(const MSG& msg) {
    if (msg.message != WM_KEYDOWN || msg.wParam != 'S' || !(GetKeyState(VK_CONTROL) & 0x8000)) {
        return false;
    }
    HWND root = GetAncestor(msg.hwnd, GA_ROOT);
    wchar_t className[64] = L"";
    if (!root || !GetClassNameW(root, className, static_cast<int>(std::size(className))) || wcscmp(className, kComposeClass) != 0) {
        return false;
    }
    PostMessageW(root, WM_COMMAND, MAKEWPARAM(IDC_SAVE, 0), 0);
    return true;
}

void OpenCompose(HWND owner, PeCore* core, int64_t account, const PeDraftInfo* draft) {
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
    std::wstring title = draft && draft->subject && *draft->subject ? Text(draft->subject) : L"New Message";
    HWND hwnd = CreateWindowExW(WS_EX_CONTROLPARENT, kComposeClass, title.c_str(), WS_OVERLAPPEDWINDOW | WS_CLIPCHILDREN,
                                CW_USEDEFAULT, CW_USEDEFAULT, Scale(760), Scale(620), owner, nullptr, GetModuleHandleW(nullptr), nullptr);
    if (!hwnd) {
        return;
    }
    auto* state = new Compose{core, account};
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
