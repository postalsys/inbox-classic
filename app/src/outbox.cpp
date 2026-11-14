// Tools > Outbox: the messages that wait to be sent, with why the last try did not work; Send All Now, Delete. What
// is in the Outbox comes from the core as it stores it; this window only lists it.
#include <algorithm>

#include "app.h"

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
    // each row's status in full, for its tip where the column cuts it short
    std::vector<std::wstring> statuses;
    bool done = false;
};

enum OutboxColumn { COL_SUBJECT, COL_TO, COL_QUEUED, COL_STATUS };

// a row per message: subject, recipients, when it was queued, and whether it waits or why it did not go
void FillOutbox(OutboxState* state, int select = 0) {
    ListView_DeleteAllItems(state->list);
    state->ids.clear();
    state->statuses.clear();
    core::Outbox outbox(pe_outbox(state->core));
    for (size_t i = 0; i < pe_outbox_count(outbox.get()); i++) {
        const PeQueued* queued = pe_outbox_get(outbox.get(), i);
        std::wstring subject = Text(queued->subject);
        int row = AddRow(state->list, static_cast<int>(i), subject.empty() ? core::T(PE_TEXT_UI_NO_SUBJECT) : subject);
        SetCell(state->list, row, COL_TO, Text(queued->recipients));
        SetCell(state->list, row, COL_QUEUED, FormatDate(queued->created));
        // one an AI agent sent waits a moment, while it can still be deleted
        std::wstring status = core::T(PE_TEXT_UI_OUTBOX_STATUS_WAITING);
        SYSTEMTIME at;
        if (queued->problem) {
            status = core::T(PE_TEXT_UI_OUTBOX_STATUS_NOT_SENT, {{"reason", Text(queued->problem)}});
        } else if (queued->not_before && UnixToSystemTime(queued->not_before, true, at)) {
            // the user's while Undo Send can take it back, else an AI agent's wait
            status = core::T(queued->undoable ? PE_TEXT_UI_OUTBOX_STATUS_UNDO : PE_TEXT_UI_OUTBOX_STATUS_AGENT, {{"time", FormatTime(at)}});
        }
        SetCell(state->list, row, COL_STATUS, status);
        state->ids.push_back(queued->id);
        state->statuses.push_back(status);
    }
    bool any = !state->ids.empty();
    SelectRow(state->list, select);
    // nothing to send or delete in an empty Outbox; a button about to be disabled hands the focus to Close first
    HWND focus = GetFocus();
    if (!any && (focus == state->send || focus == state->remove)) {
        SetFocus(state->close);
    }
    EnableWindow(state->send, any);
    EnableWindow(state->remove, any);
}

// the columns as wide as what they show, Subject and To no wider than a fair share, and Status the rest
void FitColumns(HWND list) {
    ListView_SetColumnWidth(list, COL_QUEUED, LVSCW_AUTOSIZE_USEHEADER);
    for (int column : {COL_SUBJECT, COL_TO}) {
        ListView_SetColumnWidth(list, column, LVSCW_AUTOSIZE_USEHEADER);
        ListView_SetColumnWidth(list, column, std::min(ListView_GetColumnWidth(list, column), Scale(170)));
    }
    // exactly what is left, so a long reason is cut (its tip has it) rather than scrolled to
    RECT client;
    GetClientRect(list, &client);
    int used = 0;
    for (int column : {COL_SUBJECT, COL_TO, COL_QUEUED}) {
        used += ListView_GetColumnWidth(list, column);
    }
    ListView_SetColumnWidth(list, COL_STATUS, std::max(Scale(100), static_cast<int>(client.right) - used));
}

// the row's whole status as its tip, why it did not go where the column is too narrow for it
void StatusTip(OutboxState* state, NMLVGETINFOTIPW* tip) {
    if (tip->iItem >= 0 && static_cast<size_t>(tip->iItem) < state->statuses.size() && tip->cchTextMax > 0) {
        wcsncpy_s(tip->pszText, tip->cchTextMax, state->statuses[tip->iItem].c_str(), _TRUNCATE);
    }
}

void DeleteSelected(HWND hwnd, OutboxState* state) {
    int index = ListView_GetNextItem(state->list, -1, LVNI_SELECTED);
    if (index >= 0 && static_cast<size_t>(index) < state->ids.size() &&
        MessageBoxW(hwnd, core::T(PE_TEXT_UI_OUTBOX_DELETE_ASK).c_str(), core::Plain(PE_TEXT_UI_OUTBOX_TITLE).c_str(), MB_YESNO | MB_ICONWARNING | MB_DEFBUTTON2) == IDYES) {
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
        if (header->hwndFrom == state->list && header->code == LVN_GETINFOTIPW) {
            StatusTip(state, reinterpret_cast<NMLVGETINFOTIPW*>(lParam));
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
    int width = Scale(760);
    int height = Scale(260);
    HWND dialog = CreateModalWindow(owner, kOutboxClass, core::Plain(PE_TEXT_UI_OUTBOX_TITLE).c_str(), width, height);
    OutboxState state{core};
    SetWindowLongPtrW(dialog, GWLP_USERDATA, reinterpret_cast<LONG_PTR>(&state));
    int buttonWidth = Scale(110);
    state.list = CreateReportList(dialog, IDC_OUTBOX_LIST, {pad, pad, width - pad - buttonWidth - pad, height - pad});
    AddColumn(state.list, COL_SUBJECT, core::T(PE_TEXT_UI_COL_SUBJECT).c_str(), 150);
    AddColumn(state.list, COL_TO, core::T(PE_TEXT_UI_COL_TO).c_str(), 110);
    AddColumn(state.list, COL_QUEUED, core::T(PE_TEXT_UI_COL_QUEUED).c_str(), 100);
    AddColumn(state.list, COL_STATUS, core::T(PE_TEXT_UI_COL_STATUS).c_str(), 100);
    ListView_SetExtendedListViewStyle(state.list, LVS_EX_FULLROWSELECT | LVS_EX_INFOTIP);
    state.send = CreateChild(dialog, L"BUTTON", core::T(PE_TEXT_UI_OUTBOX_SEND_ALL).c_str(), WS_TABSTOP, IDC_OUTBOX_SEND,
                             {width - pad - buttonWidth, pad, width - pad, pad + Scale(25)});
    state.remove = CreateChild(dialog, L"BUTTON", core::T(PE_TEXT_WIN_DELETE_BUTTON).c_str(), WS_TABSTOP, IDC_OUTBOX_DELETE,
                               {width - pad - buttonWidth, pad + Scale(31), width - pad, pad + Scale(56)});
    state.close = CreateChild(dialog, L"BUTTON", core::T(PE_TEXT_UI_CLOSE).c_str(), WS_TABSTOP | BS_DEFPUSHBUTTON, IDC_OUTBOX_CLOSE,
                {width - pad - buttonWidth, height - pad - Scale(25), width - pad, height - pad});
    FillOutbox(&state);
    FitColumns(state.list);
    RunModal(dialog, state.list, state.done);
}
