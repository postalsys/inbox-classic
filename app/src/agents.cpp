// AI agents: the questions only the user answers (a program that connects for the first time, every message an
// agent wants to send) and Tools > AI Agents, with the programs let in and what agents did. The rules, the words and
// the decisions' effects are the core's (pe-core agents.rs); these windows show them and pass the answers on.
#include <windowsx.h>

#include "app.h"

namespace {

const wchar_t* kAccessClass = L"InboxClassicAgentAccess";
const wchar_t* kSendClass = L"InboxClassicAgentSend";
const wchar_t* kAgentsClass = L"InboxClassicAgents";

// the dialog's heading: the message font, larger and bold
HFONT HeadingFont() {
    static HFONT font = [] {
        LOGFONTW face = {};
        GetObjectW(GetStockObject(DEFAULT_GUI_FONT), sizeof(face), &face);
        face.lfHeight = -Scale(15);
        face.lfWeight = FW_BOLD;
        return CreateFontIndirectW(&face);
    }();
    return font;
}

HWND Heading(HWND parent, const std::wstring& text, const RECT& bounds) {
    HWND heading = CreateChild(parent, L"STATIC", text.c_str(), SS_LEFT | SS_NOPREFIX | SS_ENDELLIPSIS, 0, bounds);
    SendMessageW(heading, WM_SETFONT, reinterpret_cast<WPARAM>(HeadingFont()), FALSE);
    return heading;
}

// the height a static text of `text` takes at `width`
int TextHeight(HWND parent, const std::wstring& text, int width) {
    HDC dc = GetDC(parent);
    HGDIOBJ old = SelectObject(dc, GetStockObject(DEFAULT_GUI_FONT));
    RECT bounds = {0, 0, width, 0};
    DrawTextW(dc, text.c_str(), -1, &bounds, DT_CALCRECT | DT_WORDBREAK | DT_NOPREFIX);
    SelectObject(dc, old);
    ReleaseDC(parent, dc);
    return bounds.bottom;
}

// ---- what a program may do: the first question, and Change in Tools > AI Agents ----

struct AccessState {
    PeCore* core;
    // a check box for each level the core offers (pe_agent_level_label)
    HWND levels[PE_AGENT_LEVEL_COUNT] = {};
    HWND accounts = nullptr;
    std::vector<int64_t> ids;
    // IDOK let in (with what is checked), IDNO turned away, IDCANCEL nothing decided
    int answer = IDCANCEL;
    // what was checked, read before the window goes
    uint32_t chosenLevels = 0;
    std::vector<int64_t> chosenAccounts;
    bool done = false;
};

void ReadAccess(AccessState& state);

LRESULT CALLBACK AccessProc(HWND hwnd, UINT message, WPARAM wParam, LPARAM lParam) {
    auto* state = reinterpret_cast<AccessState*>(GetWindowLongPtrW(hwnd, GWLP_USERDATA));
    if (!state) {
        return DefWindowProcW(hwnd, message, wParam, lParam);
    }
    switch (message) {
    case WM_COMMAND:
        switch (LOWORD(wParam)) {
        case IDOK:
        case IDNO:
        case IDCANCEL:
            state->answer = LOWORD(wParam);
            ReadAccess(*state);
            state->done = true;
            return 0;
        case IDC_AGENT_LEVEL:
            // reading is what everything else builds on: without it the rest goes too
            if (HIWORD(wParam) == BN_CLICKED && Button_GetCheck(state->levels[0]) != BST_CHECKED) {
                for (HWND level : state->levels) {
                    Button_SetCheck(level, BST_UNCHECKED);
                }
            }
            return 0;
        }
        return 0;
    case WM_CLOSE:
        state->answer = IDCANCEL;
        state->done = true;
        return 0;
    case WM_CTLCOLORSTATIC:
        return ButtonFaceColor(reinterpret_cast<HDC>(wParam));
    }
    return DefWindowProcW(hwnd, message, wParam, lParam);
}

// the levels checked (the core keeps none of them without reading) and the accounts ticked
void ReadAccess(AccessState& state) {
    uint32_t& levels = state.chosenLevels;
    std::vector<int64_t>& accounts = state.chosenAccounts;
    levels = 0;
    for (size_t i = 0; i < PE_AGENT_LEVEL_COUNT; i++) {
        if (Button_GetCheck(state.levels[i]) == BST_CHECKED) {
            levels |= pe_agent_level_bit(i);
        }
    }
    accounts.clear();
    for (size_t i = 0; i < state.ids.size(); i++) {
        if (ListView_GetCheckState(state.accounts, static_cast<int>(i))) {
            accounts.push_back(state.ids[i]);
        }
    }
}

enum class AccessMode { Ask, Change };

// the form: heading, words, the program's file, what it may do, which accounts; IDOK, IDNO or IDCANCEL, and what was
// chosen. `has` tells which accounts start ticked.
int AccessDialog(HWND owner, PeCore* core, AccessMode mode, const std::wstring& heading, const std::wstring& detail,
                 const std::wstring& path, uint32_t& levels, std::vector<int64_t>& accounts,
                 const std::function<bool(int64_t)>& has) {
    RegisterDialogClass(kAccessClass, AccessProc);
    int pad = Scale(12);
    int width = Scale(500);
    int inner = width - 2 * pad;
    int detailHeight = TextHeight(owner, detail, inner);
    int height = pad + Scale(24) + detailHeight + Scale(10) + Scale(18) + Scale(10) + Scale(20) + 4 * Scale(22) + Scale(10) + Scale(18) +
                 Scale(92) + Scale(16) + Scale(25) + pad;
    HWND dialog = CreateModalWindow(owner, kAccessClass, core::Plain(mode == AccessMode::Ask ? PE_TEXT_UI_AI_AGENT : PE_TEXT_UI_AI_AGENT_ACCESS).c_str(), width, height);
    AccessState state{core};
    SetWindowLongPtrW(dialog, GWLP_USERDATA, reinterpret_cast<LONG_PTR>(&state));
    int y = pad;
    Heading(dialog, heading, {pad, y, width - pad, y + Scale(22)});
    y += Scale(24);
    CreateChild(dialog, L"STATIC", detail.c_str(), SS_LEFT | SS_NOPREFIX, 0, {pad, y, width - pad, y + detailHeight});
    y += detailHeight + Scale(10);
    std::wstring program = core::T(PE_TEXT_UI_PROGRAM_PATH, {{"path", path}});
    HWND file = CreateChild(dialog, L"STATIC", program.c_str(), SS_LEFT | SS_NOPREFIX | SS_PATHELLIPSIS, IDC_AGENT_PATH,
                            {pad, y, width - pad, y + Scale(16)});
    SetAccessibleDescription(file, path);
    y += Scale(18) + Scale(10);
    CreateChild(dialog, L"STATIC", core::T(PE_TEXT_UI_IT_MAY).c_str(), SS_LEFT | SS_NOPREFIX, 0, {pad, y, width - pad, y + Scale(16)});
    y += Scale(20);
    for (size_t i = 0; i < PE_AGENT_LEVEL_COUNT; i++) {
        state.levels[i] = CreateChild(dialog, L"BUTTON", Text(pe_agent_level_label(i)).c_str(),
                                      WS_TABSTOP | BS_AUTOCHECKBOX | (i == 0 ? WS_GROUP : 0), IDC_AGENT_LEVEL + static_cast<int>(i),
                                      {pad + Scale(4), y, width - pad, y + Scale(20)});
        Button_SetCheck(state.levels[i], (levels & pe_agent_level_bit(i)) ? BST_CHECKED : BST_UNCHECKED);
        y += Scale(22);
    }
    y += Scale(10);
    CreateChild(dialog, L"STATIC", core::T(PE_TEXT_UI_ACCOUNTS_IT_MAY_USE).c_str(), SS_LEFT | SS_NOPREFIX, 0, {pad, y, width - pad, y + Scale(16)});
    y += Scale(18);
    state.accounts = CreateChild(dialog, WC_LISTVIEWW, L"", WS_TABSTOP | LVS_REPORT | LVS_NOCOLUMNHEADER | LVS_SINGLESEL | LVS_SHOWSELALWAYS,
                                 IDC_AGENT_ACCOUNTS, {pad, y, width - pad, y + Scale(92)}, WS_EX_CLIENTEDGE);
    ListView_SetExtendedListViewStyle(state.accounts, LVS_EX_CHECKBOXES | LVS_EX_FULLROWSELECT);
    AddColumn(state.accounts, 0, core::T(PE_TEXT_UI_COL_ACCOUNT).c_str(), 400);
    ListView_SetColumnWidth(state.accounts, 0, LVSCW_AUTOSIZE_USEHEADER);
    core::AccountList list(pe_accounts(core));
    for (size_t i = 0; i < pe_account_list_count(list.get()); i++) {
        const PeAccount* account = pe_account_list_get(list.get(), i);
        int row = AddRow(state.accounts, static_cast<int>(i), Text(account->label));
        ListView_SetCheckState(state.accounts, row, has(account->id));
        state.ids.push_back(account->id);
    }
    y += Scale(92) + Scale(16);
    std::wstring allow = core::T(PE_TEXT_UI_ALLOW), dontAllow = core::T(PE_TEXT_WIN_DONT_ALLOW);
    std::wstring turnAway = core::T(PE_TEXT_UI_TURN_AWAY), cancel = core::T(PE_TEXT_UI_CANCEL);
    int button = ButtonWidth({allow, dontAllow, turnAway, cancel}, 100);
    // Enter does not let a program in: the safe answer is the default
    if (mode == AccessMode::Ask) {
        CreateChild(dialog, L"BUTTON", allow.c_str(), WS_TABSTOP, IDOK, {width - pad - 2 * button - Scale(8), y, width - pad - button - Scale(8), y + Scale(25)});
        CreateChild(dialog, L"BUTTON", dontAllow.c_str(), WS_TABSTOP | BS_DEFPUSHBUTTON, IDNO, {width - pad - button, y, width - pad, y + Scale(25)});
    } else {
        CreateChild(dialog, L"BUTTON", turnAway.c_str(), WS_TABSTOP, IDNO, {pad, y, pad + button, y + Scale(25)});
        CreateChild(dialog, L"BUTTON", allow.c_str(), WS_TABSTOP | BS_DEFPUSHBUTTON, IDOK,
                    {width - pad - 2 * button - Scale(8), y, width - pad - button - Scale(8), y + Scale(25)});
        CreateChild(dialog, L"BUTTON", cancel.c_str(), WS_TABSTOP, IDCANCEL, {width - pad - button, y, width - pad, y + Scale(25)});
    }
    RunModal(dialog, state.levels[0], state.done);
    levels = state.chosenLevels;
    accounts = state.chosenAccounts;
    return state.answer;
}

// ---- a message to send ----

struct SendState {
    bool done = false;
    PeAgentSendAnswer answer = PE_AGENT_SEND_ANSWER_DONT_SEND;
    HWND send = nullptr;
    HWND warning = nullptr;
};

constexpr UINT_PTR kSendTimer = 1;

LRESULT CALLBACK SendProc(HWND hwnd, UINT message, WPARAM wParam, LPARAM lParam) {
    auto* state = reinterpret_cast<SendState*>(GetWindowLongPtrW(hwnd, GWLP_USERDATA));
    if (!state) {
        return DefWindowProcW(hwnd, message, wParam, lParam);
    }
    switch (message) {
    case WM_COMMAND:
        switch (LOWORD(wParam)) {
        case IDC_AGENT_SEND:
            state->answer = PE_AGENT_SEND_ANSWER_SEND;
            state->done = true;
            return 0;
        case IDC_AGENT_COMPOSE:
            state->answer = PE_AGENT_SEND_ANSWER_COMPOSE;
            state->done = true;
            return 0;
        case IDCANCEL:
        case IDC_AGENT_DONT_SEND:
            state->answer = PE_AGENT_SEND_ANSWER_DONT_SEND;
            state->done = true;
            return 0;
        }
        return 0;
    case WM_TIMER:
        // Send comes on after a moment, so a key pressed for another window does not send
        if (wParam == kSendTimer) {
            KillTimer(hwnd, kSendTimer);
            EnableWindow(state->send, TRUE);
        }
        return 0;
    case WM_CLOSE:
        state->answer = PE_AGENT_SEND_ANSWER_DONT_SEND;
        state->done = true;
        return 0;
    case WM_CTLCOLORSTATIC:
        if (reinterpret_cast<HWND>(lParam) == state->warning) {
            SetTextColor(reinterpret_cast<HDC>(wParam), RGB(0xb0, 0x00, 0x00));
        }
        // the read-only body white, as a message is
        if (GetDlgCtrlID(reinterpret_cast<HWND>(lParam)) == IDC_AGENT_BODY) {
            SetBkColor(reinterpret_cast<HDC>(wParam), GetSysColor(COLOR_WINDOW));
            return reinterpret_cast<LRESULT>(GetSysColorBrush(COLOR_WINDOW));
        }
        return ButtonFaceColor(reinterpret_cast<HDC>(wParam));
    }
    return DefWindowProcW(hwnd, message, wParam, lParam);
}

// a label and its value on one line of the message's header
void HeaderLine(HWND dialog, int pad, int& y, int width, int labelWidth, const std::wstring& label, const std::wstring& value,
                int id = 0) {
    CreateChild(dialog, L"STATIC", label.c_str(), SS_RIGHT | SS_NOPREFIX, 0, {pad, y, pad + labelWidth, y + Scale(16)});
    CreateChild(dialog, L"STATIC", value.c_str(), SS_LEFT | SS_NOPREFIX | SS_ENDELLIPSIS, id, {pad + labelWidth + Scale(8), y, width - pad, y + Scale(16)});
    y += Scale(20);
}

void SendDialog(HWND owner, PeCore* core, uint64_t request) {
    core::AgentSend info(pe_agent_send_info(core, request));
    const PeAgentSend* send = pe_agent_send(info.get());
    if (!send) {
        return;
    }
    RegisterDialogClass(kSendClass, SendProc);
    int pad = Scale(12);
    int width = Scale(600);
    int inner = width - 2 * pad;
    std::wstring detail = Text(send->detail);
    std::wstring warning = Text(send->warning);
    std::wstring original = Text(send->original);
    std::wstring files = Text(send->files);
    int detailHeight = TextHeight(owner, detail, inner);
    int recipients = static_cast<int>(pe_agent_send_recipient_count(info.get()));
    int listHeight = Scale(26) + std::min(recipients, 5) * Scale(18);
    int height = pad + Scale(24) + detailHeight + Scale(8) + (warning.empty() ? 0 : Scale(22)) + Scale(20) + listHeight + Scale(8) +
                 Scale(20) * (original.empty() ? 1 : 2) + Scale(4) + Scale(200) + (files.empty() ? 0 : Scale(22)) + Scale(14) + Scale(25) + pad;
    HWND dialog = CreateModalWindow(owner, kSendClass, core::Plain(PE_TEXT_UI_SEND_MESSAGE_ASK).c_str(), width, height);
    SendState state;
    SetWindowLongPtrW(dialog, GWLP_USERDATA, reinterpret_cast<LONG_PTR>(&state));
    int y = pad;
    Heading(dialog, Text(send->title), {pad, y, width - pad, y + Scale(22)});
    y += Scale(24);
    CreateChild(dialog, L"STATIC", detail.c_str(), SS_LEFT | SS_NOPREFIX, 0, {pad, y, width - pad, y + detailHeight});
    y += detailHeight + Scale(8);
    if (!warning.empty()) {
        state.warning = CreateChild(dialog, L"STATIC", warning.c_str(), SS_LEFT | SS_NOPREFIX | SS_ENDELLIPSIS, IDC_AGENT_WARNING,
                                    {pad, y, width - pad, y + Scale(16)});
        y += Scale(22);
    }
    int labelWidth = LabelWidth({core::T(PE_TEXT_UI_FIELD_FROM), core::T(PE_TEXT_UI_FIELD_SUBJECT)}, 64, 4);
    HeaderLine(dialog, pad, y, width, labelWidth, core::T(PE_TEXT_UI_FIELD_FROM), Text(send->from));
    // every recipient on a row of its own, address first, so a name can not hide where it goes
    HWND list = CreateReportList(dialog, IDC_AGENT_RECIPIENTS, {pad, y, width - pad, y + listHeight});
    AddColumn(list, 0, L"", 40);
    AddColumn(list, 1, core::T(PE_TEXT_WIN_COL_ADDRESS).c_str(), 230);
    AddColumn(list, 2, core::T(PE_TEXT_UI_COL_NAME).c_str(), 160);
    // which of them are new: the red line above names one, not which of several
    AddColumn(list, 3, core::T(PE_TEXT_UI_COL_STATUS).c_str(), 120);
    for (int i = 0; i < recipients; i++) {
        const PeAgentRecipient* recipient = pe_agent_send_recipient(info.get(), static_cast<size_t>(i));
        int row = AddRow(list, i, Text(recipient->field) + L":");
        SetCell(list, row, 1, Text(recipient->address));
        SetCell(list, row, 2, Text(recipient->name));
        SetCell(list, row, 3, recipient->new_address ? core::T(PE_TEXT_WIN_NEVER_WRITTEN_TO) : L"");
    }
    ListView_SetColumnWidth(list, 3, LVSCW_AUTOSIZE_USEHEADER);
    y += listHeight + Scale(8);
    HeaderLine(dialog, pad, y, width, labelWidth, core::T(PE_TEXT_UI_FIELD_SUBJECT), Text(send->subject));
    if (!original.empty()) {
        HeaderLine(dialog, pad, y, width, labelWidth, L"", original);
    }
    y += Scale(4);
    CreateChild(dialog, L"EDIT", WithCrlf(Text(send->text)).c_str(), WS_TABSTOP | WS_VSCROLL | ES_MULTILINE | ES_READONLY | ES_AUTOVSCROLL, IDC_AGENT_BODY,
                {pad, y, width - pad, y + Scale(200)}, WS_EX_CLIENTEDGE);
    y += Scale(200);
    if (!files.empty()) {
        y += Scale(6);
        CreateChild(dialog, L"STATIC", files.c_str(), SS_LEFT | SS_NOPREFIX | SS_ENDELLIPSIS, 0, {pad, y, width - pad, y + Scale(16)});
        y += Scale(16);
    }
    y += Scale(14);
    std::wstring sendLabel = core::T(PE_TEXT_WIN_SEND), editFirst = core::T(PE_TEXT_UI_EDIT_FIRST), dontSend = core::T(PE_TEXT_WIN_DONT_SEND);
    int button = ButtonWidth({sendLabel, editFirst, dontSend}, 110);
    state.send = CreateChild(dialog, L"BUTTON", sendLabel.c_str(), WS_TABSTOP | WS_DISABLED, IDC_AGENT_SEND,
                             {width - pad - 3 * button - 2 * Scale(8), y, width - pad - 2 * button - 2 * Scale(8), y + Scale(25)});
    CreateChild(dialog, L"BUTTON", editFirst.c_str(), WS_TABSTOP, IDC_AGENT_COMPOSE,
                {width - pad - 2 * button - Scale(8), y, width - pad - button - Scale(8), y + Scale(25)});
    HWND dontSendButton = CreateChild(dialog, L"BUTTON", dontSend.c_str(), WS_TABSTOP | BS_DEFPUSHBUTTON, IDC_AGENT_DONT_SEND,
                                      {width - pad - button, y, width - pad, y + Scale(25)});
    SetTimer(dialog, kSendTimer, 1500, nullptr);
    int64_t account = send->account;
    RunModal(dialog, dontSendButton, state.done);
    core::Draft draft(pe_agent_answer_send(core, request, state.answer));
    if (draft) {
        OpenCompose(GetAncestor(owner, GA_ROOT), core, account, pe_draft_info(draft.get()));
    }
}

// ---- Tools > AI Agents ----

struct AgentsState {
    PeCore* core;
    HWND enabled = nullptr;
    HWND hosts = nullptr;
    HWND change = nullptr;
    HWND remove = nullptr;
    HWND log = nullptr;
    HWND undo = nullptr;
    HWND clear = nullptr;
    std::vector<int64_t> hostIds;
    std::vector<std::pair<int64_t, bool>> entries;
    bool done = false;
};

HWND g_agents = nullptr;
constexpr UINT WM_AGENTS_REFRESH = WM_APP + 70;

int Selected(HWND list) {
    return ListView_GetNextItem(list, -1, LVNI_SELECTED);
}

void UpdateButtons(AgentsState* state) {
    int host = Selected(state->hosts);
    EnableWindow(state->change, host >= 0);
    EnableWindow(state->remove, host >= 0);
    int entry = Selected(state->log);
    EnableWindow(state->undo, entry >= 0 && static_cast<size_t>(entry) < state->entries.size() && state->entries[entry].second);
    EnableWindow(state->clear, !state->entries.empty());
}

void FillAgents(AgentsState* state) {
    int host = std::max(0, Selected(state->hosts));
    int entry = std::max(0, Selected(state->log));
    Button_SetCheck(state->enabled, pe_agents_enabled(state->core) ? BST_CHECKED : BST_UNCHECKED);
    ListView_DeleteAllItems(state->hosts);
    state->hostIds.clear();
    core::AgentHostList hosts(pe_agent_hosts(state->core));
    for (size_t i = 0; i < pe_agent_host_list_count(hosts.get()); i++) {
        const PeAgentHost* agent = pe_agent_host_list_get(hosts.get(), i);
        int row = AddRow(state->hosts, static_cast<int>(i), Text(agent->name));
        SetCell(state->hosts, row, 1, Text(agent->access));
        SetCell(state->hosts, row, 2, agent->last_used ? FormatDate(agent->last_used) : core::T(PE_TEXT_UI_NEVER));
        state->hostIds.push_back(agent->id);
    }
    if (!state->hostIds.empty()) {
        SelectRow(state->hosts, host);
    }
    ListView_DeleteAllItems(state->log);
    state->entries.clear();
    core::AgentLog log(pe_agent_log(state->core, 500));
    for (size_t i = 0; i < pe_agent_log_count(log.get()); i++) {
        const PeAgentLogEntry* done = pe_agent_log_get(log.get(), i);
        int row = AddRow(state->log, static_cast<int>(i), FormatDate(done->at));
        SetCell(state->log, row, 1, Text(done->host));
        SetCell(state->log, row, 2, Text(done->summary));
        state->entries.emplace_back(done->id, done->can_undo);
    }
    if (!state->entries.empty()) {
        SelectRow(state->log, entry);
    }
    UpdateButtons(state);
}

void ChangeHost(HWND hwnd, AgentsState* state) {
    int index = Selected(state->hosts);
    if (index < 0 || static_cast<size_t>(index) >= state->hostIds.size()) {
        return;
    }
    core::AgentHostList hosts(pe_agent_hosts(state->core));
    const PeAgentHost* host = nullptr;
    size_t position = 0;
    for (; position < pe_agent_host_list_count(hosts.get()); position++) {
        host = pe_agent_host_list_get(hosts.get(), position);
        if (host->id == state->hostIds[index]) {
            break;
        }
        host = nullptr;
    }
    if (!host) {
        return;
    }
    uint32_t levels = host->allowed ? host->levels : PE_AGENT_DEFAULT;
    std::vector<int64_t> accounts;
    PeAgentHostList* list = hosts.get();
    int answer = AccessDialog(hwnd, state->core, AccessMode::Change, Text(host->change_title), Text(host->change_detail),
                              Text(host->path), levels, accounts,
                              [&](int64_t account) { return pe_agent_host_list_has_account(list, position, account); });
    if (answer == IDOK) {
        pe_agent_host_update(state->core, host->id, true, levels, accounts.data(), accounts.size());
    } else if (answer == IDNO) {
        pe_agent_host_update(state->core, host->id, false, 0, nullptr, 0);
    }
    FillAgents(state);
}

void RemoveHost(HWND hwnd, AgentsState* state) {
    int index = Selected(state->hosts);
    if (index >= 0 && static_cast<size_t>(index) < state->hostIds.size() &&
        MessageBoxW(hwnd, core::T(PE_TEXT_WIN_FORGET_PROGRAM_ASK).c_str(), core::Plain(PE_TEXT_UI_AI_AGENTS).c_str(), MB_YESNO | MB_ICONQUESTION | MB_DEFBUTTON2) == IDYES) {
        pe_agent_host_remove(state->core, state->hostIds[index]);
        FillAgents(state);
    }
}

void UndoEntry(HWND hwnd, AgentsState* state) {
    int index = Selected(state->log);
    if (index < 0 || static_cast<size_t>(index) >= state->entries.size()) {
        return;
    }
    core::String why(pe_agent_undo(state->core, state->entries[index].first));
    if (why) {
        MessageBoxW(hwnd, Text(why.get()).c_str(), core::Plain(PE_TEXT_UI_AI_AGENTS).c_str(), MB_OK | MB_ICONINFORMATION);
    }
    FillAgents(state);
}

void ShowSetup(HWND hwnd, PeCore* core);

LRESULT CALLBACK AgentsProc(HWND hwnd, UINT message, WPARAM wParam, LPARAM lParam) {
    auto* state = reinterpret_cast<AgentsState*>(GetWindowLongPtrW(hwnd, GWLP_USERDATA));
    if (!state) {
        return DefWindowProcW(hwnd, message, wParam, lParam);
    }
    switch (message) {
    case WM_COMMAND:
        switch (LOWORD(wParam)) {
        case IDC_AGENTS_ENABLED:
            pe_agents_set_enabled(state->core, Button_GetCheck(state->enabled) == BST_CHECKED);
            return 0;
        case IDC_AGENTS_CHANGE:
            ChangeHost(hwnd, state);
            return 0;
        case IDC_AGENTS_REMOVE:
            RemoveHost(hwnd, state);
            return 0;
        case IDC_AGENTS_UNDO:
            UndoEntry(hwnd, state);
            return 0;
        case IDC_AGENTS_CLEAR:
            if (MessageBoxW(hwnd, core::T(PE_TEXT_WIN_CLEAR_LOG_ASK).c_str(), core::Plain(PE_TEXT_UI_AI_AGENTS).c_str(),
                            MB_YESNO | MB_ICONQUESTION | MB_DEFBUTTON2) == IDYES) {
                pe_agent_log_clear(state->core);
                FillAgents(state);
            }
            return 0;
        case IDC_AGENTS_SETUP:
            ShowSetup(hwnd, state->core);
            return 0;
        case IDOK:
        case IDCANCEL:
            state->done = true;
            return 0;
        }
        return 0;
    case WM_NOTIFY: {
        auto* header = reinterpret_cast<NMHDR*>(lParam);
        if (header->code == LVN_ITEMCHANGED) {
            UpdateButtons(state);
        } else if (header->hwndFrom == state->hosts && header->code == LVN_ITEMACTIVATE) {
            ChangeHost(hwnd, state);
        }
        return 0;
    }
    case WM_DRAWITEM:
        DrawLinkButton(*reinterpret_cast<DRAWITEMSTRUCT*>(lParam));
        return TRUE;
    case WM_SETCURSOR:
        if (SetLinkCursor(hwnd, wParam)) {
            return TRUE;
        }
        break;
    case WM_AGENTS_REFRESH:
        FillAgents(state);
        return 0;
    case WM_CLOSE:
        state->done = true;
        return 0;
    case WM_CTLCOLORSTATIC:
        return ButtonFaceColor(reinterpret_cast<HDC>(wParam));
    }
    return DefWindowProcW(hwnd, message, wParam, lParam);
}

void ShowSetup(HWND hwnd, PeCore*) {
    core::String config(pe_mcp_config(StoreArgument()));
    TextDialog(hwnd, core::Plain(PE_TEXT_UI_CONNECT_AGENT), core::T(PE_TEXT_UI_CONNECT_AGENT_INTRO),
               WithCrlf(Text(config.get())));
}

}  // namespace

void AgentQuestion(HWND owner, PeCore* core, uint64_t request) {
    switch (pe_agent_ask_kind(core, request)) {
    case PE_AGENT_ASK_KIND_CONNECT: {
        core::AgentConnect info(pe_agent_connect_info(core, request));
        const PeAgentConnect* connect = pe_agent_connect(info.get());
        if (!connect) {
            return;
        }
        uint32_t levels = PE_AGENT_DEFAULT;
        std::vector<int64_t> accounts;
        int answer = AccessDialog(owner, core, AccessMode::Ask, Text(connect->title), Text(connect->detail), Text(connect->path), levels,
                                  accounts, [](int64_t) { return true; });
        // closed without an answer: asked again the next time it connects, not turned away
        if (answer == IDCANCEL) {
            return;
        }
        pe_agent_answer_connect(core, request, answer == IDOK, levels, accounts.data(), accounts.size());
        break;
    }
    case PE_AGENT_ASK_KIND_SEND:
        SendDialog(owner, core, request);
        break;
    default:
        break;
    }
}

void AgentsChanged() {
    if (g_agents) {
        PostMessageW(g_agents, WM_AGENTS_REFRESH, 0, 0);
    }
}

void AgentsDialog(HWND owner, PeCore* core) {
    RegisterDialogClass(kAgentsClass, AgentsProc);
    int pad = Scale(12);
    int width = Scale(680);
    int height = Scale(500);
    HWND dialog = CreateModalWindow(owner, kAgentsClass, core::Plain(PE_TEXT_UI_AI_AGENTS).c_str(), width, height);
    AgentsState state{core};
    SetWindowLongPtrW(dialog, GWLP_USERDATA, reinterpret_cast<LONG_PTR>(&state));
    std::wstring change = core::T(PE_TEXT_WIN_CHANGE), remove = core::T(PE_TEXT_UI_REMOVE), undo = core::T(PE_TEXT_CMD_UNDO);
    std::wstring clear = core::T(PE_TEXT_UI_CLEAR_BUTTON), close = core::T(PE_TEXT_UI_CLOSE), setup = core::T(PE_TEXT_WIN_HOW_TO_CONNECT);
    int button = ButtonWidth({change, remove, undo, clear, close}, 100);
    int listRight = width - pad - button - Scale(10);
    int y = pad;
    state.enabled = CreateChild(dialog, L"BUTTON", core::T(PE_TEXT_UI_LET_AGENTS_CONNECT).c_str(), WS_TABSTOP | BS_AUTOCHECKBOX, IDC_AGENTS_ENABLED,
                                {pad, y, width - pad, y + Scale(20)});
    y += Scale(28);
    CreateChild(dialog, L"STATIC", core::T(PE_TEXT_WIN_AGENT_PROGRAMS).c_str(), SS_LEFT, 0, {pad, y, listRight, y + Scale(16)});
    y += Scale(18);
    state.hosts = CreateReportList(dialog, IDC_AGENTS_HOSTS, {pad, y, listRight, y + Scale(120)});
    AddColumn(state.hosts, 0, core::T(PE_TEXT_UI_COL_PROGRAM).c_str(), 120);
    AddColumn(state.hosts, 1, core::T(PE_TEXT_UI_COL_MAY).c_str(), 290);
    AddColumn(state.hosts, 2, core::T(PE_TEXT_UI_COL_LAST_USED).c_str(), 110);
    ListView_SetColumnWidth(state.hosts, 2, LVSCW_AUTOSIZE_USEHEADER);
    state.change = CreateChild(dialog, L"BUTTON", change.c_str(), WS_TABSTOP, IDC_AGENTS_CHANGE, {width - pad - button, y, width - pad, y + Scale(25)});
    state.remove = CreateChild(dialog, L"BUTTON", remove.c_str(), WS_TABSTOP, IDC_AGENTS_REMOVE,
                               {width - pad - button, y + Scale(31), width - pad, y + Scale(56)});
    y += Scale(120) + Scale(14);
    CreateChild(dialog, L"STATIC", core::T(PE_TEXT_WIN_WHAT_AGENTS_DID).c_str(), SS_LEFT, 0, {pad, y, listRight, y + Scale(16)});
    y += Scale(18);
    int logBottom = height - pad - Scale(25) - Scale(12);
    state.log = CreateReportList(dialog, IDC_AGENTS_LOG, {pad, y, listRight, logBottom});
    AddColumn(state.log, 0, core::T(PE_TEXT_UI_COL_WHEN).c_str(), 110);
    AddColumn(state.log, 1, core::T(PE_TEXT_UI_COL_PROGRAM).c_str(), 90);
    AddColumn(state.log, 2, core::T(PE_TEXT_UI_COL_WHAT).c_str(), 320);
    ListView_SetColumnWidth(state.log, 2, LVSCW_AUTOSIZE_USEHEADER);
    state.undo = CreateChild(dialog, L"BUTTON", undo.c_str(), WS_TABSTOP, IDC_AGENTS_UNDO, {width - pad - button, y, width - pad, y + Scale(25)});
    state.clear = CreateChild(dialog, L"BUTTON", clear.c_str(), WS_TABSTOP, IDC_AGENTS_CLEAR,
                              {width - pad - button, y + Scale(31), width - pad, y + Scale(56)});
    int bottom = height - pad - Scale(25);
    int setupWidth = std::max(Scale(200), static_cast<int>(MeasureText(setup).cx) + Scale(12));
    CreateLinkButton(dialog, setup.c_str(), IDC_AGENTS_SETUP, {pad, bottom + Scale(4), pad + setupWidth, bottom + Scale(21)});
    CreateChild(dialog, L"BUTTON", close.c_str(), WS_TABSTOP | BS_DEFPUSHBUTTON, IDOK, {width - pad - button, bottom, width - pad, height - pad});
    FillAgents(&state);
    g_agents = dialog;
    RunModal(dialog, state.hosts, state.done);
    g_agents = nullptr;
}
