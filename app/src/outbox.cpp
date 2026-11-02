// Tools > Outbox: the messages that wait to be sent, with why the last try did not work; Send All Now, Delete. What
// is in the Outbox comes from the core as it stores it; this window only lists it.
#include "app.h"

namespace {

const wchar_t* kOutboxClass = L"PostalExpressOutbox";

enum OutboxId : WORD { IDC_OUTBOX_LIST = 450, IDC_OUTBOX_SEND, IDC_OUTBOX_DELETE, IDC_OUTBOX_CLOSE };

struct OutboxState {
    PeCore* core;
    HWND list = nullptr;
    std::vector<int64_t> ids;
    bool done = false;
};

void FillOutbox(OutboxState* state) {
    SendMessageW(state->list, LB_RESETCONTENT, 0, 0);
    state->ids.clear();
    core::Outbox outbox(pe_outbox(state->core));
    for (size_t i = 0; i < pe_outbox_count(outbox.get()); i++) {
        const PeQueued* queued = pe_outbox_get(outbox.get(), i);
        std::wstring subject = Text(queued->subject);
        std::wstring line = (subject.empty() ? L"(no subject)" : subject) + L"  to " + Text(queued->recipients);
        if (queued->problem) {
            line += L"  (not sent: " + Text(queued->problem) + L")";
        }
        SendMessageW(state->list, LB_ADDSTRING, 0, reinterpret_cast<LPARAM>(line.c_str()));
        state->ids.push_back(queued->id);
    }
    if (state->ids.empty()) {
        SendMessageW(state->list, LB_ADDSTRING, 0, reinterpret_cast<LPARAM>(L"The Outbox is empty."));
    } else {
        SendMessageW(state->list, LB_SETCURSEL, 0, 0);
    }
}

LRESULT CALLBACK OutboxProc(HWND hwnd, UINT message, WPARAM wParam, LPARAM lParam) {
    auto* state = reinterpret_cast<OutboxState*>(GetWindowLongPtrW(hwnd, GWLP_USERDATA));
    if (!state) {
        return DefWindowProcW(hwnd, message, wParam, lParam);
    }
    switch (message) {
    case WM_COMMAND:
        switch (LOWORD(wParam)) {
        case IDC_OUTBOX_SEND:
            pe_outbox_send(state->core);
            state->done = true;
            return 0;
        case IDC_OUTBOX_DELETE: {
            LRESULT index = SendMessageW(state->list, LB_GETCURSEL, 0, 0);
            if (index >= 0 && static_cast<size_t>(index) < state->ids.size() &&
                MessageBoxW(hwnd, L"Delete this message without sending it?", L"Outbox", MB_YESNO | MB_ICONWARNING | MB_DEFBUTTON2) == IDYES) {
                pe_outbox_delete(state->core, state->ids[index]);
                FillOutbox(state);
            }
            return 0;
        }
        case IDC_OUTBOX_CLOSE:
        case IDCANCEL:
            state->done = true;
            return 0;
        }
        return 0;
    case WM_CLOSE:
        state->done = true;
        return 0;
    }
    return DefWindowProcW(hwnd, message, wParam, lParam);
}

}  // namespace

void OutboxDialog(HWND owner, PeCore* core) {
    static bool registered = false;
    if (!registered) {
        WNDCLASSEXW windowClass = {sizeof(windowClass)};
        windowClass.lpfnWndProc = OutboxProc;
        windowClass.hInstance = GetModuleHandleW(nullptr);
        windowClass.hCursor = LoadCursorW(nullptr, IDC_ARROW);
        windowClass.hbrBackground = reinterpret_cast<HBRUSH>(COLOR_BTNFACE + 1);
        windowClass.lpszClassName = kOutboxClass;
        RegisterClassExW(&windowClass);
        registered = true;
    }
    int pad = Scale(10);
    int width = Scale(560);
    int height = Scale(260);
    HWND dialog = CreateModalWindow(owner, kOutboxClass, L"Outbox", width, height);
    OutboxState state{core};
    SetWindowLongPtrW(dialog, GWLP_USERDATA, reinterpret_cast<LONG_PTR>(&state));
    int buttonWidth = Scale(110);
    state.list = CreateChild(dialog, L"LISTBOX", L"", WS_TABSTOP | WS_VSCROLL | WS_HSCROLL | LBS_NOINTEGRALHEIGHT, IDC_OUTBOX_LIST,
                             {pad, pad, width - pad - buttonWidth - pad, height - pad}, WS_EX_CLIENTEDGE);
    SendMessageW(state.list, LB_SETHORIZONTALEXTENT, Scale(1200), 0);
    CreateChild(dialog, L"BUTTON", L"&Send All Now", WS_TABSTOP, IDC_OUTBOX_SEND,
                {width - pad - buttonWidth, pad, width - pad, pad + Scale(25)});
    CreateChild(dialog, L"BUTTON", L"&Delete", WS_TABSTOP, IDC_OUTBOX_DELETE,
                {width - pad - buttonWidth, pad + Scale(31), width - pad, pad + Scale(56)});
    CreateChild(dialog, L"BUTTON", L"Close", WS_TABSTOP | BS_DEFPUSHBUTTON, IDC_OUTBOX_CLOSE,
                {width - pad - buttonWidth, height - pad - Scale(25), width - pad, height - pad});
    FillOutbox(&state);
    RunModal(dialog, state.list, state.done);
}
