// The window a message is written in. The fields go to the core as typed: the core parses and checks the
// recipients, reads the attached files and builds the message, so this file only edits text.
#include "app.h"

#include <commdlg.h>

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
};

struct Compose {
    PeCore* core;
    int64_t account;
    std::string inReplyTo;
    std::string references;
    std::vector<std::wstring> files;
    HWND toolbar = nullptr;
    HWND labels[5] = {};
    HWND to = nullptr;
    HWND cc = nullptr;
    HWND bcc = nullptr;
    HWND subject = nullptr;
    HWND attached = nullptr;
    HWND body = nullptr;
};

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
    MoveWindow(state->body, pad, y, client.right - 2 * pad, std::max(0L, client.bottom - y - pad), TRUE);
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
    std::vector<wchar_t> buffer(32768, L'\0');
    OPENFILENAMEW dialog = {sizeof(dialog)};
    dialog.hwndOwner = hwnd;
    dialog.lpstrFilter = L"All files (*.*)\0*.*\0";
    dialog.lpstrFile = buffer.data();
    dialog.nMaxFile = static_cast<DWORD>(buffer.size());
    dialog.lpstrTitle = L"Insert Attachment";
    dialog.Flags = OFN_EXPLORER | OFN_FILEMUSTEXIST | OFN_ALLOWMULTISELECT | OFN_NOCHANGEDIR;
    if (!GetOpenFileNameW(&dialog)) {
        return;
    }
    // one file is a full path, several are the directory followed by the names
    std::vector<std::wstring> parts;
    for (const wchar_t* part = buffer.data(); *part; part += wcslen(part) + 1) {
        parts.push_back(part);
    }
    if (parts.size() == 1) {
        state->files.push_back(parts[0]);
    }
    for (size_t i = 1; i < parts.size(); i++) {
        state->files.push_back(parts[0] + L"\\" + parts[i]);
    }
    ShowFiles(state);
}

void Send(HWND hwnd, Compose* state) {
    std::string to = core::Narrow(GetWindowString(state->to));
    std::string cc = core::Narrow(GetWindowString(state->cc));
    std::string bcc = core::Narrow(GetWindowString(state->bcc));
    std::string subject = core::Narrow(GetWindowString(state->subject));
    std::string text = core::Narrow(GetWindowString(state->body));
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
    outgoing.text = text.c_str();
    outgoing.in_reply_to = state->inReplyTo.empty() ? nullptr : state->inReplyTo.c_str();
    outgoing.references = state->references.c_str();
    outgoing.attachments = attachments.data();
    outgoing.attachment_count = attachments.size();
    char* reason = nullptr;
    if (!pe_message_send(state->core, state->account, &outgoing, &reason)) {
        // a typo in an address or a file that is gone: the message stays open to fix it
        core::String error(reason);
        std::wstring why = error ? Text(error.get()) : L"The message could not be sent.";
        MessageBoxW(hwnd, why.c_str(), L"PostalExpress", MB_OK | MB_ICONWARNING);
        return;
    }
    // the main window shows whether the server took it
    DestroyWindow(hwnd);
}

void CreateFields(HWND hwnd, Compose* state) {
    state->toolbar = CreateWindowExW(0, TOOLBARCLASSNAMEW, nullptr,
                                     WS_CHILD | WS_VISIBLE | TBSTYLE_FLAT | TBSTYLE_LIST | CCS_NODIVIDER | CCS_TOP, 0, 0, 0,
                                     0, hwnd, nullptr, GetModuleHandleW(nullptr), nullptr);
    SendMessageW(state->toolbar, TB_BUTTONSTRUCTSIZE, sizeof(TBBUTTON), 0);
    SendMessageW(state->toolbar, TB_SETEXTENDEDSTYLE, 0, TBSTYLE_EX_MIXEDBUTTONS);
    for (auto [id, text] : {std::pair{IDC_SEND, L"Send"}, std::pair{IDC_ATTACH, L"Attach"}}) {
        TBBUTTON button = {};
        button.iBitmap = I_IMAGENONE;
        button.idCommand = id;
        button.fsState = TBSTATE_ENABLED;
        button.fsStyle = BTNS_BUTTON | BTNS_AUTOSIZE | BTNS_SHOWTEXT;
        button.iString = reinterpret_cast<INT_PTR>(text);
        SendMessageW(state->toolbar, TB_ADDBUTTONSW, 1, reinterpret_cast<LPARAM>(&button));
    }
    const wchar_t* labels[] = {L"To:", L"Cc:", L"Bcc:", L"Subject:", L"Attach:"};
    for (int i = 0; i < 5; i++) {
        state->labels[i] = CreateChild(hwnd, L"STATIC", labels[i], SS_LEFT, 0, {});
    }
    state->to = CreateChild(hwnd, L"EDIT", L"", WS_TABSTOP | ES_AUTOHSCROLL, IDC_TO, {}, WS_EX_CLIENTEDGE);
    state->cc = CreateChild(hwnd, L"EDIT", L"", WS_TABSTOP | ES_AUTOHSCROLL, IDC_CC, {}, WS_EX_CLIENTEDGE);
    state->bcc = CreateChild(hwnd, L"EDIT", L"", WS_TABSTOP | ES_AUTOHSCROLL, IDC_BCC, {}, WS_EX_CLIENTEDGE);
    state->subject = CreateChild(hwnd, L"EDIT", L"", WS_TABSTOP | ES_AUTOHSCROLL, IDC_SUBJECT, {}, WS_EX_CLIENTEDGE);
    state->attached = CreateChild(hwnd, L"EDIT", L"", ES_AUTOHSCROLL | ES_READONLY, IDC_FILES, {}, WS_EX_CLIENTEDGE);
    state->body = CreateChild(hwnd, L"EDIT", L"", WS_TABSTOP | ES_MULTILINE | ES_WANTRETURN | ES_AUTOVSCROLL | WS_VSCROLL,
                              IDC_BODY, {}, WS_EX_CLIENTEDGE);
    // a message can be long, the default limit of an edit control is 32k characters
    SendMessageW(state->body, EM_SETLIMITTEXT, 0, 0);
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
        if (state && LOWORD(wParam) == IDC_SEND) {
            Send(hwnd, state);
            return 0;
        }
        if (state && LOWORD(wParam) == IDC_ATTACH) {
            Attach(hwnd, state);
            return 0;
        }
        break;
    case WM_CTLCOLORSTATIC:
        return ButtonFaceColor(reinterpret_cast<HDC>(wParam));
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
                                CW_USEDEFAULT, CW_USEDEFAULT, Scale(720), Scale(560), owner, nullptr, GetModuleHandleW(nullptr), nullptr);
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
        SetWindowTextW(state->body, Text(draft->text).c_str());
        state->inReplyTo = draft->in_reply_to ? draft->in_reply_to : "";
        state->references = draft->references ? draft->references : "";
    }
    Layout(hwnd, state);
    ShowWindow(hwnd, SW_SHOW);
    // the cursor where the user writes: the top of the reply, or the To field of a new message
    SetFocus(draft && draft->to && *draft->to ? state->body : state->to);
}
