// The window a message is written in: the address fields, a format bar in the manner of Outlook Express and the HTML
// editor (editor.h). The fields go to the core as typed and the editor's HTML as it comes: the core parses and checks
// the recipients, sanitizes the HTML, adds the quoted message, reads the attached files and builds the message, so
// this file only edits.
#include "app.h"
#include "editor.h"

#include <commdlg.h>

#include <utility>

namespace {

const wchar_t* kComposeClass = L"PostalExpressCompose";

enum ComposeId : WORD {
    IDC_SEND = 300,
    IDC_ATTACH,
    IDC_TO,
    IDC_CC,
    IDC_BCC,
    IDC_SUBJECT,
    IDC_BODY,
    IDC_FILES,
    IDC_SEND_LATER,
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
    std::vector<std::wstring> files;
    Editor editor;
    // the editor's HTML was asked for, the message goes when it comes
    bool sending = false;
    // Send Later: into the Outbox, sent with the next Send/Recv
    bool later = false;
    std::wstring html;
    // the quote was unfolded into the text: it goes as the user left it, not added again
    bool quoteInText = false;
    // something was typed: closing asks first
    bool dirty = false;
    bool filling = true;
    COLORREF colors[16] = {};
    HWND toolbar = nullptr;
    HWND formatBar = nullptr;
    HWND font = nullptr;
    HWND size = nullptr;
    HWND labels[5] = {};
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
    HWND fields[] = {state->to, state->cc, state->bcc, state->subject, state->attached};
    for (int i = 0; i < 5; i++) {
        MoveWindow(state->labels[i], pad, y + Scale(3), labelWidth, rowHeight, TRUE);
        MoveWindow(fields[i], pad + labelWidth, y, client.right - 2 * pad - labelWidth, rowHeight, TRUE);
        y += rowHeight + Scale(4);
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
}

void ShowFiles(Compose* state) {
    std::wstring list;
    for (const std::wstring& file : state->files) {
        size_t slash = file.find_last_of(L"\\/");
        list += (list.empty() ? L"" : L"; ") + (slash == std::wstring::npos ? file : file.substr(slash + 1));
    }
    SetWindowTextW(state->attached, list.c_str());
}

void Attach(HWND hwnd, Compose* state) {
    for (const std::wstring& file : OpenFilesDialog(hwnd, L"Insert Attachment", L"All files (*.*)\0*.*\0")) {
        state->files.push_back(file);
    }
    ShowFiles(state);
}

// sends with the HTML the editor gave
void Send(HWND hwnd, Compose* state, const std::wstring& html) {
    state->sending = false;
    std::string to = core::Narrow(GetWindowString(state->to));
    std::string cc = core::Narrow(GetWindowString(state->cc));
    std::string bcc = core::Narrow(GetWindowString(state->bcc));
    std::string subject = core::Narrow(GetWindowString(state->subject));
    std::string body = core::Narrow(html);
    std::vector<std::string> paths;
    for (const std::wstring& file : state->files) {
        paths.push_back(core::Narrow(file));
    }
    std::vector<const char*> attachments;
    for (const std::string& path : paths) {
        attachments.push_back(path.c_str());
    }
    PeOutgoing outgoing = {};
    outgoing.to = to.c_str();
    outgoing.cc = cc.c_str();
    outgoing.bcc = bcc.c_str();
    outgoing.subject = subject.c_str();
    outgoing.html = body.c_str();
    outgoing.quote = state->quote.empty() || state->quoteInText ? nullptr : state->quote.c_str();
    outgoing.in_reply_to = state->inReplyTo.empty() ? nullptr : state->inReplyTo.c_str();
    outgoing.references = state->references.c_str();
    outgoing.attachments = attachments.data();
    outgoing.attachment_count = attachments.size();
    char* reason = nullptr;
    if (!pe_message_send(state->core, state->account, &outgoing, state->later, &reason)) {
        // a typo in an address or a file that is gone: the message stays open to fix it
        core::String error(reason);
        std::wstring why = error ? Text(error.get()) : L"The message could not be sent.";
        MessageBoxW(hwnd, why.c_str(), L"PostalExpress", MB_OK | MB_ICONWARNING);
        return;
    }
    // the main window shows whether the server took it
    state->dirty = false;
    DestroyWindow(hwnd);
}

// Send: the editor's HTML is asked for first, Send() follows when it comes
void RequestSend(Compose* state, bool later = false) {
    if (!state->sending) {
        state->sending = true;
        state->later = later;
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
    state->formatBar = CreateBar(hwnd, CCS_NODIVIDER | CCS_NOPARENTALIGN | CCS_NORESIZE | TBSTYLE_TOOLTIPS, IDC_FORMATBAR);
    struct Button {
        int id;
        const wchar_t* text;
        BYTE style;
    };
    Button buttons[] = {
        {IDF_BOLD, L"B", BTNS_CHECK},     {IDF_ITALIC, L"I", BTNS_CHECK},   {IDF_UNDERLINE, L"U", BTNS_CHECK},
        {IDF_COLOR, L"Color", 0},         {0, nullptr, 0},                  {IDF_NUMBERS, L"1.", BTNS_CHECK},
        {IDF_BULLETS, L"\x2022", BTNS_CHECK}, {IDF_OUTDENT, L"\x00AB", 0},  {IDF_INDENT, L"\x00BB", 0},
        {0, nullptr, 0},                  {IDF_LEFT, L"Left", BTNS_CHECK}, {IDF_CENTER, L"Center", BTNS_CHECK},
        {IDF_RIGHT, L"Right", BTNS_CHECK}, {0, nullptr, 0},                 {IDF_LINK, L"Link", 0},
        {IDF_LINE, L"Line", 0},           {IDF_PICTURE, L"Picture", 0},
    };
    for (const Button& button : buttons) {
        AddButton(state->formatBar, button.id, button.text, static_cast<BYTE>(BTNS_BUTTON | button.style));
    }
}

void CreateFields(HWND hwnd, Compose* state) {
    state->toolbar = CreateBar(hwnd, CCS_NODIVIDER | CCS_TOP, 0);
    AddButton(state->toolbar, IDC_SEND, L"Send");
    AddButton(state->toolbar, IDC_SEND_LATER, L"Send Later");
    AddButton(state->toolbar, IDC_ATTACH, L"Attach");
    const wchar_t* labels[] = {L"To:", L"Cc:", L"Bcc:", L"Subject:", L"Attach:"};
    for (int i = 0; i < 5; i++) {
        state->labels[i] = CreateChild(hwnd, L"STATIC", labels[i], SS_LEFT, 0, {});
    }
    state->to = CreateChild(hwnd, L"EDIT", L"", WS_TABSTOP | ES_AUTOHSCROLL, IDC_TO, {}, WS_EX_CLIENTEDGE);
    state->cc = CreateChild(hwnd, L"EDIT", L"", WS_TABSTOP | ES_AUTOHSCROLL, IDC_CC, {}, WS_EX_CLIENTEDGE);
    state->bcc = CreateChild(hwnd, L"EDIT", L"", WS_TABSTOP | ES_AUTOHSCROLL, IDC_BCC, {}, WS_EX_CLIENTEDGE);
    state->subject = CreateChild(hwnd, L"EDIT", L"", WS_TABSTOP | ES_AUTOHSCROLL, IDC_SUBJECT, {}, WS_EX_CLIENTEDGE);
    state->attached = CreateChild(hwnd, L"EDIT", L"", ES_AUTOHSCROLL | ES_READONLY, IDC_FILES, {}, WS_EX_CLIENTEDGE);
    CreateFormatBar(hwnd, state);
}

// the editor with the quote of the draft; its messages come back to the window
void CreateEditor(HWND hwnd, Compose* state, const PeDraftInfo* draft) {
    core::String page(pe_editor_document(draft ? draft->quote : nullptr, draft && draft->quote_folded));
    Editor::Handlers handlers;
    handlers.error = [hwnd](const std::wstring& error) { MessageBoxW(hwnd, error.c_str(), L"PostalExpress", MB_OK | MB_ICONERROR); };
    handlers.html = [hwnd, state](const std::wstring& html, bool full) {
        state->html = html;
        state->quoteInText = full;
        PostMessageW(hwnd, WM_SEND_HTML, 0, 0);
    };
    handlers.state = [state](const std::wstring& flags) { ShowState(state, flags); };
    handlers.dirty = [state] { state->dirty = true; };
    handlers.send = [state] { RequestSend(state); };
    state->body = state->editor.Create(hwnd, IDC_BODY, page ? Text(page.get()) : L"", std::move(handlers));
}

// whether the window may close: after asking, when something was written and not sent
bool MayClose(HWND hwnd, Compose* state) {
    return !state->dirty || MessageBoxW(hwnd, L"Close this message without sending it? What you wrote will be lost.", L"PostalExpress",
                                        MB_YESNO | MB_ICONQUESTION | MB_DEFBUTTON2) == IDYES;
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
            RequestSend(state);
            return 0;
        }
        if (LOWORD(wParam) == IDC_SEND_LATER) {
            RequestSend(state, true);
            return 0;
        }
        if (LOWORD(wParam) == IDC_ATTACH) {
            Attach(hwnd, state);
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
        if (state && state->sending) {
            Send(hwnd, state, std::exchange(state->html, {}));
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

void OpenCompose(HWND owner, PeCore* core, int64_t account, const PeDraftInfo* draft) {
    static bool registered = false;
    if (!registered) {
        WNDCLASSEXW windowClass = {sizeof(windowClass)};
        windowClass.lpfnWndProc = ComposeProc;
        windowClass.hInstance = GetModuleHandleW(nullptr);
        windowClass.hCursor = LoadCursorW(nullptr, IDC_ARROW);
        windowClass.hIcon = LoadIconW(nullptr, IDI_APPLICATION);
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
    if (draft) {
        SetWindowTextW(state->to, Text(draft->to).c_str());
        SetWindowTextW(state->cc, Text(draft->cc).c_str());
        SetWindowTextW(state->subject, Text(draft->subject).c_str());
        state->inReplyTo = draft->in_reply_to ? draft->in_reply_to : "";
        state->references = draft->references ? draft->references : "";
        state->quote = draft->quote ? draft->quote : "";
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
