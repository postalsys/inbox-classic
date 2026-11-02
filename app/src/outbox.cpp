// Tools > Outbox: the messages that wait to be sent, with why the last try did not work; Send All Now, Delete. What
// is in the Outbox comes from the core as it stores it; this window only lists it.
#include "app.h"

#include <algorithm>

namespace {

const wchar_t* kOutboxClass = L"InboxClassicOutbox";

enum OutboxId : WORD { IDC_OUTBOX_LIST = 450, IDC_OUTBOX_SEND, IDC_OUTBOX_DELETE, IDC_OUTBOX_CLOSE };

struct OutboxState {
    PeCore* core;
    HWND list = nullptr;
    HWND send = nullptr;
    HWND remove = nullptr;
    HWND close = nullptr;
    std::vector<int64_t> ids;
    bool done = false;
};

enum OutboxColumn { COL_SUBJECT, COL_TO, COL_QUEUED, COL_STATUS };

void SetCell(HWND list, int row, int column, const std::wstring& text) {
    ListView_SetItemText(list, row, column, const_cast<wchar_t*>(text.c_str()));
}

// a row per message: subject, recipients, when it was queued, and whether it waits or why it did not go
void FillOutbox(OutboxState* state, int select = 0) {
    ListView_DeleteAllItems(state->list);
    state->ids.clear();
    core::Outbox outbox(pe_outbox(state->core));
    for (size_t i = 0; i < pe_outbox_count(outbox.get()); i++) {
        const PeQueued* queued = pe_outbox_get(outbox.get(), i);
        std::wstring subject = Text(queued->subject);
        LVITEMW item = {};
        item.mask = LVIF_TEXT;
        item.iItem = static_cast<int>(i);
        item.pszText = const_cast<wchar_t*>(subject.empty() ? L"(no subject)" : subject.c_str());
        int row = ListView_InsertItem(state->list, &item);
        SetCell(state->list, row, COL_TO, Text(queued->recipients));
        SetCell(state->list, row, COL_QUEUED, FormatDate(queued->created));
        SetCell(state->list, row, COL_STATUS, queued->problem ? L"Not sent: " + Text(queued->problem) : L"Waiting");
        state->ids.push_back(queued->id);
    }
    bool any = !state->ids.empty();
    if (any) {
        int row = std::min(select, static_cast<int>(state->ids.size()) - 1);
        ListView_SetItemState(state->list, row, LVIS_SELECTED | LVIS_FOCUSED, LVIS_SELECTED | LVIS_FOCUSED);
    }
    // nothing to send or delete in an empty Outbox; a button about to be disabled hands the focus to Close first
    HWND focus = GetFocus();
    if (!any && (focus == state->send || focus == state->remove)) {
        SetFocus(state->close);
    }
    EnableWindow(state->send, any);
    EnableWindow(state->remove, any);
}

void DeleteSelected(HWND hwnd, OutboxState* state) {
    int index = ListView_GetNextItem(state->list, -1, LVNI_SELECTED);
    if (index >= 0 && static_cast<size_t>(index) < state->ids.size() &&
        MessageBoxW(hwnd, L"Delete this message without sending it?", L"Outbox", MB_YESNO | MB_ICONWARNING | MB_DEFBUTTON2) == IDYES) {
        pe_outbox_delete(state->core, state->ids[index]);
        // the next one selected, where the deleted one was
        FillOutbox(state, index);
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
        case IDC_OUTBOX_DELETE:
            DeleteSelected(hwnd, state);
            return 0;
        case IDC_OUTBOX_CLOSE:
        case IDCANCEL:
            state->done = true;
            return 0;
        }
        return 0;
    case WM_NOTIFY: {
        auto* header = reinterpret_cast<NMHDR*>(lParam);
        // Delete in the list
        if (header->hwndFrom == state->list && header->code == LVN_KEYDOWN &&
            reinterpret_cast<NMLVKEYDOWN*>(lParam)->wVKey == VK_DELETE) {
            DeleteSelected(hwnd, state);
        }
        return 0;
    }
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
    int width = Scale(640);
    int height = Scale(260);
    HWND dialog = CreateModalWindow(owner, kOutboxClass, L"Outbox", width, height);
    OutboxState state{core};
    SetWindowLongPtrW(dialog, GWLP_USERDATA, reinterpret_cast<LONG_PTR>(&state));
    int buttonWidth = Scale(110);
    state.list = CreateChild(dialog, WC_LISTVIEWW, nullptr, WS_TABSTOP | LVS_REPORT | LVS_SINGLESEL | LVS_SHOWSELALWAYS | LVS_NOSORTHEADER,
                             IDC_OUTBOX_LIST, {pad, pad, width - pad - buttonWidth - pad, height - pad}, WS_EX_CLIENTEDGE);
    ListView_SetExtendedListViewStyle(state.list, LVS_EX_FULLROWSELECT);
    AddColumn(state.list, COL_SUBJECT, L"Subject", 150);
    AddColumn(state.list, COL_TO, L"To", 110);
    AddColumn(state.list, COL_QUEUED, L"Queued", 100);
    AddColumn(state.list, COL_STATUS, L"Status", 100);
    // the last column takes the rest of the width, no wider
    ListView_SetColumnWidth(state.list, COL_STATUS, LVSCW_AUTOSIZE_USEHEADER);
    state.send = CreateChild(dialog, L"BUTTON", L"&Send All Now", WS_TABSTOP, IDC_OUTBOX_SEND,
                             {width - pad - buttonWidth, pad, width - pad, pad + Scale(25)});
    state.remove = CreateChild(dialog, L"BUTTON", L"&Delete", WS_TABSTOP, IDC_OUTBOX_DELETE,
                               {width - pad - buttonWidth, pad + Scale(31), width - pad, pad + Scale(56)});
    state.close = CreateChild(dialog, L"BUTTON", L"Close", WS_TABSTOP | BS_DEFPUSHBUTTON, IDC_OUTBOX_CLOSE,
                {width - pad - buttonWidth, height - pad - Scale(25), width - pad, height - pad});
    FillOutbox(&state);
    RunModal(dialog, state.list, state.done);
}
