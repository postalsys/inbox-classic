// AI agents: the questions only the user answers (a program that connects for the first time, every message an
// agent wants to send, the mailing lists an agent wants to leave) and Tools > AI Agents, with the programs let in and what agents did. The rules, the words and
// the decisions' effects are the core's (pe-core agents.rs); these windows show them and pass the answers on.
#include <windowsx.h>

#include <algorithm>

#include "app.h"

namespace {

const wchar_t* kAccessClass = L"InboxClassicAgentAccess";
const wchar_t* kSendClass = L"InboxClassicAgentSend";
const wchar_t* kUnsubscribeClass = L"InboxClassicAgentUnsubscribe";
const wchar_t* kAgentsClass = L"InboxClassicAgents";
const wchar_t* kUndoSinceClass = L"InboxClassicAgentUndoSince";

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

// one line, cut with "..." should it not fit; with `wrap`, its words wrap over as many lines as `bounds` has room for
HWND Heading(HWND parent, const std::wstring& text, const RECT& bounds, bool wrap = false) {
    HWND heading = CreateChild(parent, L"STATIC", text.c_str(), SS_LEFT | SS_NOPREFIX | (wrap ? 0 : SS_ENDELLIPSIS), 0, bounds);
    SendMessageW(heading, WM_SETFONT, reinterpret_cast<WPARAM>(HeadingFont()), FALSE);
    return heading;
}

// the height a static text of `text` takes at `width`, in `font` (the dialogs' own when none); with `breakWords`, a
// word longer than a line broken as a static text with SS_EDITCONTROL breaks it
int TextHeight(HWND parent, const std::wstring& text, int width, HFONT font = nullptr, bool breakWords = false) {
    HDC dc = GetDC(parent);
    HGDIOBJ old = SelectObject(dc, font ? font : GetStockObject(DEFAULT_GUI_FONT));
    RECT bounds = {0, 0, width, 0};
    DrawTextW(dc, text.c_str(), -1, &bounds, DT_CALCRECT | DT_WORDBREAK | DT_NOPREFIX | (breakWords ? DT_EDITCONTROL : 0));
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
    // the words under it name a terminal's program and the --name argument, a long word in any language
    int detailHeight = TextHeight(owner, detail, inner, nullptr, true);
    // the heading wraps when it is long: "Programs started from a terminal (WindowsTerminal) want to use your mail"
    int headingHeight = std::max(Scale(22), TextHeight(owner, heading, inner, HeadingFont()));
    // a level's words wrap under their check box when they are long (Organize names everything it lets an agent do)
    std::wstring labels[PE_AGENT_LEVEL_COUNT];
    int rows[PE_AGENT_LEVEL_COUNT] = {};
    int levelsHeight = 0;
    for (size_t i = 0; i < PE_AGENT_LEVEL_COUNT; i++) {
        labels[i] = Text(pe_agent_level_label(i));
        rows[i] = std::max(Scale(20), TextHeight(owner, labels[i], inner - Scale(4) - Scale(20)) + Scale(4));
        levelsHeight += rows[i] + Scale(2);
    }
    int height = pad + headingHeight + Scale(2) + detailHeight + Scale(10) + Scale(18) + Scale(10) + Scale(20) + levelsHeight + Scale(10) + Scale(18) +
                 Scale(92) + Scale(16) + Scale(25) + pad;
    HWND dialog = CreateModalWindow(owner, kAccessClass, core::Plain(mode == AccessMode::Ask ? PE_TEXT_UI_AI_AGENT : PE_TEXT_UI_AI_AGENT_ACCESS).c_str(), width, height);
    AccessState state{core};
    SetWindowLongPtrW(dialog, GWLP_USERDATA, reinterpret_cast<LONG_PTR>(&state));
    int y = pad;
    Heading(dialog, heading, {pad, y, width - pad, y + headingHeight}, true);
    y += headingHeight + Scale(2);
    CreateChild(dialog, L"STATIC", detail.c_str(), SS_LEFT | SS_NOPREFIX | SS_EDITCONTROL, 0, {pad, y, width - pad, y + detailHeight});
    y += detailHeight + Scale(10);
    std::wstring program = core::T(PE_TEXT_UI_PROGRAM_PATH, {{"path", path}});
    HWND file = CreateChild(dialog, L"STATIC", program.c_str(), SS_LEFT | SS_NOPREFIX | SS_PATHELLIPSIS, IDC_AGENT_PATH,
                            {pad, y, width - pad, y + Scale(16)});
    SetAccessibleDescription(file, path);
    y += Scale(18) + Scale(10);
    CreateChild(dialog, L"STATIC", core::T(PE_TEXT_UI_IT_MAY).c_str(), SS_LEFT | SS_NOPREFIX, 0, {pad, y, width - pad, y + Scale(16)});
    y += Scale(20);
    for (size_t i = 0; i < PE_AGENT_LEVEL_COUNT; i++) {
        DWORD wrap = rows[i] > Scale(20) ? BS_MULTILINE | BS_TOP : 0;
        state.levels[i] = CreateChild(dialog, L"BUTTON", labels[i].c_str(),
                                      WS_TABSTOP | BS_AUTOCHECKBOX | wrap | (i == 0 ? WS_GROUP : 0), IDC_AGENT_LEVEL + static_cast<int>(i),
                                      {pad + Scale(4), y, width - pad, y + rows[i]});
        Button_SetCheck(state.levels[i], (levels & pe_agent_level_bit(i)) ? BST_CHECKED : BST_UNCHECKED);
        y += rows[i] + Scale(2);
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

// ---- the questions of an agent: a message to send, mailing lists to leave ----

// what a question shows and what its answer was: the button pressed (`safe` when it was closed)
struct QuestionState {
    bool done = false;
    int safe = IDCANCEL;
    int answer = IDCANCEL;
    // the answer that comes on after a moment (Send, Unsubscribe)
    HWND delayed = nullptr;
    HWND warning = nullptr;
    // the lists to leave, their addresses bold
    HWND lists = nullptr;
    HFONT bold = nullptr;
};

constexpr UINT_PTR kDelayTimer = 1;

// the addresses bold, so who each list is reads first; where the request goes dim
LRESULT DrawListCell(QuestionState& state, NMLVCUSTOMDRAW& draw) {
    switch (draw.nmcd.dwDrawStage) {
    case CDDS_PREPAINT:
        return CDRF_NOTIFYITEMDRAW;
    case CDDS_ITEMPREPAINT:
        return CDRF_NOTIFYSUBITEMDRAW;
    case CDDS_ITEMPREPAINT | CDDS_SUBITEM: {
        bool selected = ListView_GetItemState(state.lists, static_cast<int>(draw.nmcd.dwItemSpec), LVIS_SELECTED) != 0 &&
                        GetFocus() == state.lists;
        SelectObject(draw.nmcd.hdc, draw.iSubItem == 0 && state.bold ? state.bold : reinterpret_cast<HFONT>(SendMessageW(state.lists, WM_GETFONT, 0, 0)));
        draw.clrText = draw.iSubItem == 3 && !selected ? GetSysColor(COLOR_GRAYTEXT) : CLR_DEFAULT;
        return CDRF_NEWFONT;
    }
    }
    return CDRF_DODEFAULT;
}

LRESULT CALLBACK QuestionProc(HWND hwnd, UINT message, WPARAM wParam, LPARAM lParam) {
    auto* state = reinterpret_cast<QuestionState*>(GetWindowLongPtrW(hwnd, GWLP_USERDATA));
    if (!state) {
        return DefWindowProcW(hwnd, message, wParam, lParam);
    }
    switch (message) {
    case WM_COMMAND:
        if (HIWORD(wParam) == BN_CLICKED) {
            // Esc gives the safe answer
            state->answer = LOWORD(wParam) == IDCANCEL ? state->safe : LOWORD(wParam);
            state->done = true;
        }
        return 0;
    case WM_NOTIFY: {
        auto* header = reinterpret_cast<NMHDR*>(lParam);
        if (state->lists && header->hwndFrom == state->lists && header->code == NM_CUSTOMDRAW) {
            return DrawListCell(*state, *reinterpret_cast<NMLVCUSTOMDRAW*>(lParam));
        }
        return 0;
    }
    case WM_TIMER:
        // Send or Unsubscribe comes on after a moment, so a key pressed for another window does not answer
        if (wParam == kDelayTimer) {
            KillTimer(hwnd, kDelayTimer);
            EnableWindow(state->delayed, TRUE);
        }
        return 0;
    case WM_CLOSE:
        state->answer = state->safe;
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

// the question's heading and the words under it, from the top; where the rest starts
int QuestionTop(HWND dialog, int pad, int width, const std::wstring& title, const std::wstring& detail, int detailHeight) {
    int y = pad;
    Heading(dialog, title, {pad, y, width - pad, y + Scale(22)});
    y += Scale(24);
    CreateChild(dialog, L"STATIC", detail.c_str(), SS_LEFT | SS_NOPREFIX, 0, {pad, y, width - pad, y + detailHeight});
    return y + detailHeight;
}

// the answers at the bottom right, left to right, the last the safe one and the default; the first comes on after a
// moment. The safe one, to run the window with.
HWND AnswerButtons(HWND dialog, QuestionState& state, int pad, int width, int y, const std::vector<std::pair<std::wstring, int>>& answers) {
    std::vector<std::wstring> labels;
    for (const auto& answer : answers) {
        labels.push_back(answer.first);
    }
    int button = ButtonWidth(labels, 110);
    int count = static_cast<int>(answers.size());
    HWND safe = nullptr;
    for (int i = 0; i < count; i++) {
        int right = width - pad - (count - 1 - i) * (button + Scale(8));
        bool last = i == count - 1;
        DWORD style = WS_TABSTOP | (i == 0 ? WS_DISABLED : 0) | (last ? BS_DEFPUSHBUTTON : 0);
        HWND made = CreateChild(dialog, L"BUTTON", answers[i].first.c_str(), style, answers[i].second, {right - button, y, right, y + Scale(25)});
        if (i == 0) {
            state.delayed = made;
        }
        if (last) {
            safe = made;
            state.safe = state.answer = answers[i].second;
        }
    }
    SetTimer(dialog, kDelayTimer, 1500, nullptr);
    return safe;
}

// the widest of `texts` in `font` on `control`, at least `least`
int BoldTextWidth(HWND control, HFONT font, const std::vector<std::wstring>& texts, int least) {
    HDC dc = GetDC(control);
    HGDIOBJ before = SelectObject(dc, font);
    int widest = least;
    for (const auto& text : texts) {
        SIZE size = {};
        GetTextExtentPoint32W(dc, text.c_str(), static_cast<int>(text.size()), &size);
        widest = std::max(widest, static_cast<int>(size.cx) + Scale(16));
    }
    SelectObject(dc, before);
    ReleaseDC(control, dc);
    return widest;
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
    RegisterDialogClass(kSendClass, QuestionProc);
    int pad = Scale(12);
    int width = Scale(600);
    int inner = width - 2 * pad;
    std::wstring detail = Text(send->detail);
    std::wstring warning = Text(send->warning);
    std::wstring original = Text(send->original);
    std::wstring files = Text(send->files);
    // an answer to a calendar invitation: what it answers and when the answer counts, over the text
    std::wstring invitation = Text(send->invitation);
    int detailHeight = TextHeight(owner, detail, inner);
    int invitationHeight = invitation.empty() ? 0 : TextHeight(owner, invitation, inner) + Scale(6);
    int recipients = static_cast<int>(pe_agent_send_recipient_count(info.get()));
    int listHeight = Scale(26) + std::min(recipients, 5) * Scale(18);
    int height = pad + Scale(24) + detailHeight + Scale(8) + (warning.empty() ? 0 : Scale(22)) + Scale(20) + listHeight + Scale(8) +
                 Scale(20) * (original.empty() ? 1 : 2) + Scale(4) + invitationHeight + Scale(200) + (files.empty() ? 0 : Scale(22)) + Scale(14) +
                 Scale(25) + pad;
    HWND dialog = CreateModalWindow(owner, kSendClass, core::Plain(PE_TEXT_UI_SEND_MESSAGE_ASK).c_str(), width, height);
    QuestionState state;
    SetWindowLongPtrW(dialog, GWLP_USERDATA, reinterpret_cast<LONG_PTR>(&state));
    int y = QuestionTop(dialog, pad, width, Text(send->title), detail, detailHeight) + Scale(8);
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
    if (!invitation.empty()) {
        CreateChild(dialog, L"STATIC", invitation.c_str(), SS_LEFT | SS_NOPREFIX, IDC_AGENT_INVITATION, {pad, y, width - pad, y + invitationHeight - Scale(6)});
        y += invitationHeight;
    }
    CreateChild(dialog, L"EDIT", WithCrlf(Text(send->text)).c_str(), WS_TABSTOP | WS_VSCROLL | ES_MULTILINE | ES_READONLY | ES_AUTOVSCROLL, IDC_AGENT_BODY,
                {pad, y, width - pad, y + Scale(200)}, WS_EX_CLIENTEDGE);
    y += Scale(200);
    if (!files.empty()) {
        y += Scale(6);
        CreateChild(dialog, L"STATIC", files.c_str(), SS_LEFT | SS_NOPREFIX | SS_ENDELLIPSIS, 0, {pad, y, width - pad, y + Scale(16)});
        y += Scale(16);
    }
    y += Scale(14);
    // an invitation's answer has no Edit First: its calendar file is the core's
    std::vector<std::pair<std::wstring, int>> answers = {{core::T(PE_TEXT_WIN_SEND), IDC_AGENT_SEND}};
    if (send->can_edit) {
        answers.push_back({core::T(PE_TEXT_UI_EDIT_FIRST), IDC_AGENT_COMPOSE});
    }
    answers.push_back({core::T(PE_TEXT_WIN_DONT_SEND), IDC_AGENT_DONT_SEND});
    HWND dontSend = AnswerButtons(dialog, state, pad, width, y, answers);
    int64_t account = send->account;
    RunModal(dialog, dontSend, state.done);
    PeAgentSendAnswer answer = state.answer == IDC_AGENT_SEND      ? PE_AGENT_SEND_ANSWER_SEND
                               : state.answer == IDC_AGENT_COMPOSE ? PE_AGENT_SEND_ANSWER_COMPOSE
                                                                   : PE_AGENT_SEND_ANSWER_DONT_SEND;
    core::Draft draft(pe_agent_answer_send(core, request, answer));
    if (draft) {
        OpenCompose(GetAncestor(owner, GA_ROOT), core, account, pe_draft_info(draft.get()));
    }
}

void UnsubscribeDialog(HWND owner, PeCore* core, uint64_t request) {
    core::AgentUnsubscribe info(pe_agent_unsubscribe_info(core, request));
    const PeAgentUnsubscribe* ask = pe_agent_unsubscribe(info.get());
    if (!ask) {
        return;
    }
    RegisterDialogClass(kUnsubscribeClass, QuestionProc);
    int pad = Scale(12);
    int width = Scale(680);
    int inner = width - 2 * pad;
    std::wstring detail = Text(ask->detail);
    int detailHeight = TextHeight(owner, detail, inner);
    int count = static_cast<int>(pe_agent_unsubscribe_list_count(info.get()));
    // room for up to eight lists, then it scrolls (an agent may name up to 30 a day)
    int listHeight = Scale(26) + std::clamp(count, 3, 8) * Scale(18);
    int height = pad + Scale(24) + detailHeight + Scale(12) + listHeight + Scale(16) + Scale(25) + pad;
    HWND dialog = CreateModalWindow(owner, kUnsubscribeClass, core::Plain(PE_TEXT_UI_AI_AGENT).c_str(), width, height);
    QuestionState state;
    SetWindowLongPtrW(dialog, GWLP_USERDATA, reinterpret_cast<LONG_PTR>(&state));
    int y = QuestionTop(dialog, pad, width, Text(ask->title), detail, detailHeight) + Scale(12);
    // one row a list: the sender's address first, whole, so a name can never hide who it is, then the name, the
    // subject it came with, and the host the request goes to
    state.lists = CreateReportList(dialog, IDC_AGENT_LISTS, {pad, y, width - pad, y + listHeight});
    // a name or subject too long for its column shows whole under the mouse
    ListView_SetExtendedListViewStyle(state.lists, LVS_EX_FULLROWSELECT | LVS_EX_LABELTIP);
    LOGFONTW face = {};
    GetObjectW(reinterpret_cast<HFONT>(SendMessageW(state.lists, WM_GETFONT, 0, 0)), sizeof(face), &face);
    face.lfWeight = FW_BOLD;
    state.bold = CreateFontIndirectW(&face);
    AddColumn(state.lists, 0, core::T(PE_TEXT_UI_COL_FROM).c_str(), 200);
    AddColumn(state.lists, 1, core::T(PE_TEXT_UI_COL_NAME).c_str(), 140);
    AddColumn(state.lists, 2, core::T(PE_TEXT_UI_COL_SUBJECT).c_str(), 170);
    AddColumn(state.lists, 3, L"", 110);
    std::vector<std::wstring> addresses;
    for (int i = 0; i < count; i++) {
        const PeAgentList* list = pe_agent_unsubscribe_list(info.get(), static_cast<size_t>(i));
        addresses.push_back(Text(list->address));
        int row = AddRow(state.lists, i, addresses.back());
        SetCell(state.lists, row, 1, Text(list->name));
        SetCell(state.lists, row, 2, Text(list->subject));
        SetCell(state.lists, row, 3, Text(list->target_label));
    }
    // the address column as wide as the longest address in bold, the list scrolling sideways past the dialog
    ListView_SetColumnWidth(state.lists, 0, BoldTextWidth(state.lists, state.bold, addresses, Scale(200)));
    ListView_SetColumnWidth(state.lists, 3, LVSCW_AUTOSIZE_USEHEADER);
    y += listHeight + Scale(16);
    HWND dontUnsubscribe = AnswerButtons(dialog, state, pad, width, y,
                                         {{core::T(PE_TEXT_WIN_UNSUBSCRIBE), IDC_AGENT_UNSUBSCRIBE},
                                          {core::T(PE_TEXT_WIN_DONT_UNSUBSCRIBE), IDC_AGENT_DONT_UNSUBSCRIBE}});
    RunModal(dialog, dontUnsubscribe, state.done);
    DeleteObject(state.bold);
    pe_agent_answer_unsubscribe(core, request, state.answer == IDC_AGENT_UNSUBSCRIBE);
}

// ---- Tools > AI Agents ----

// a row of the log as the window keeps it: the entry Undo takes back, or the program and hour of a row of reads
struct LogRow {
    int64_t id = 0;
    bool canUndo = false;
    bool reads = false;
    int64_t host = 0;
    int64_t hour = 0;
};

struct AgentsState {
    PeCore* core;
    HWND enabled = nullptr;
    HWND hosts = nullptr;
    HWND change = nullptr;
    HWND remove = nullptr;
    HWND undoSince = nullptr;
    HWND log = nullptr;
    HWND undo = nullptr;
    HWND clear = nullptr;
    // under the log: what the selected row of reads covers
    HWND readsLabel = nullptr;
    HWND reads = nullptr;
    std::vector<int64_t> hostIds;
    // what each program may do, as its row says it: the tip of a row whose words do not fit
    std::vector<std::wstring> hostAccess;
    std::vector<LogRow> entries;
    // the row of reads shown under the log, so a refresh keeps the list as it is when it is the same
    std::pair<int64_t, int64_t> shownReads = {0, -1};
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
    EnableWindow(state->undoSince, host >= 0);
    int entry = Selected(state->log);
    EnableWindow(state->undo, entry >= 0 && static_cast<size_t>(entry) < state->entries.size() && state->entries[entry].canUndo);
    EnableWindow(state->clear, !state->entries.empty());
}

// the hour from `hour` on, as a time: "14:00"
std::wstring HourTime(int64_t hour) {
    SYSTEMTIME local;
    return UnixToSystemTime(hour, true, local) ? FormatTime(local) : std::wstring();
}

// under the log, what the selected row of reads covers, each read with its time: the subjects, searches and folders
// (the core never gives what a message says); for another row, the words that say to select one
void ShowReads(AgentsState* state) {
    int entry = Selected(state->log);
    const LogRow* row = entry >= 0 && static_cast<size_t>(entry) < state->entries.size() && state->entries[entry].reads ? &state->entries[entry] : nullptr;
    std::pair<int64_t, int64_t> shown = row ? std::pair{row->host, row->hour} : std::pair<int64_t, int64_t>{0, -1};
    std::wstring label = row ? core::T(PE_TEXT_WIN_AGENT_READS, {{"from", HourTime(row->hour)}, {"to", HourTime(row->hour + 3600)}})
                             : core::T(PE_TEXT_WIN_AGENT_READS_HINT);
    SetWindowTextW(state->readsLabel, label.c_str());
    // the reads of an hour only grow: refilled, the list keeps where it was scrolled to
    int top = shown == state->shownReads ? ListView_GetTopIndex(state->reads) : 0;
    state->shownReads = shown;
    SendMessageW(state->reads, WM_SETREDRAW, FALSE, 0);
    ListView_DeleteAllItems(state->reads);
    if (row) {
        core::AgentReads reads(pe_agent_reads(state->core, row->host, row->hour));
        for (size_t i = 0; i < pe_agent_reads_count(reads.get()); i++) {
            const PeAgentRead* read = pe_agent_reads_get(reads.get(), i);
            SYSTEMTIME local;
            int at = AddRow(state->reads, static_cast<int>(i), UnixToSystemTime(read->at, true, local) ? FormatTime(local) : L"");
            SetCell(state->reads, at, 1, Text(read->text));
        }
    }
    ListView_SetColumnWidth(state->reads, 1, LVSCW_AUTOSIZE_USEHEADER);
    RECT first = {};
    if (top > 0 && ListView_GetItemRect(state->reads, 0, &first, LVIR_BOUNDS)) {
        ListView_Scroll(state->reads, 0, top * (first.bottom - first.top));
    }
    SendMessageW(state->reads, WM_SETREDRAW, TRUE, 0);
    InvalidateRect(state->reads, nullptr, TRUE);
}

// the width a column needs for `words` in `list`: the words with the room the list keeps around a cell's text
int CellWidth(HWND list, const std::wstring& words) {
    return ListView_GetStringWidth(list, words.c_str()) + Scale(16);
}

// the programs' columns: Program and Last used as wide as their words, Permissions the rest of the list
void FitHostColumns(AgentsState* state) {
    int widths[] = {0, 0, 0};
    for (int column : {0, 2}) {
        wchar_t title[128] = L"";
        LVCOLUMNW header = {};
        header.mask = LVCF_TEXT;
        header.pszText = title;
        header.cchTextMax = static_cast<int>(std::size(title));
        ListView_GetColumn(state->hosts, column, &header);
        widths[column] = CellWidth(state->hosts, title);
        for (int row = 0; row < ListView_GetItemCount(state->hosts); row++) {
            wchar_t cell[256] = L"";
            ListView_GetItemText(state->hosts, row, column, cell, static_cast<int>(std::size(cell)));
            widths[column] = std::max(widths[column], CellWidth(state->hosts, cell));
        }
    }
    RECT client;
    GetClientRect(state->hosts, &client);
    widths[1] = std::max(Scale(120), static_cast<int>(client.right) - widths[0] - widths[2]);
    for (int column = 0; column < 3; column++) {
        ListView_SetColumnWidth(state->hosts, column, widths[column]);
    }
}

// the widest that the programs' three columns need for the programs there are now, so the window can be made that
// wide ("Programs started from a terminal (WindowsTerminal)" is a long name), with room for a scroll bar
int HostColumnsWidth(PeCore* core) {
    int program = std::max(Scale(120) - Scale(16), static_cast<int>(MeasureText(core::T(PE_TEXT_UI_COL_PROGRAM)).cx));
    int access = static_cast<int>(MeasureText(core::T(PE_TEXT_UI_COL_MAY)).cx);
    int used = std::max(Scale(110) - Scale(16), static_cast<int>(MeasureText(core::T(PE_TEXT_UI_COL_LAST_USED)).cx));
    core::AgentHostList hosts(pe_agent_hosts(core));
    for (size_t i = 0; i < pe_agent_host_list_count(hosts.get()); i++) {
        const PeAgentHost* host = pe_agent_host_list_get(hosts.get(), i);
        program = std::max(program, static_cast<int>(MeasureText(Text(host->name)).cx));
        access = std::max(access, static_cast<int>(MeasureText(Text(host->access)).cx));
        std::wstring last = host->last_used ? FormatDate(host->last_used) : core::T(PE_TEXT_UI_NEVER);
        used = std::max(used, static_cast<int>(MeasureText(last).cx));
    }
    return program + access + used + 3 * Scale(16) + GetSystemMetrics(SM_CXVSCROLL);
}

void FillAgents(AgentsState* state) {
    int host = std::max(0, Selected(state->hosts));
    int entry = std::max(0, Selected(state->log));
    Button_SetCheck(state->enabled, pe_agents_enabled(state->core) ? BST_CHECKED : BST_UNCHECKED);
    ListView_DeleteAllItems(state->hosts);
    state->hostIds.clear();
    state->hostAccess.clear();
    core::AgentHostList hosts(pe_agent_hosts(state->core));
    for (size_t i = 0; i < pe_agent_host_list_count(hosts.get()); i++) {
        const PeAgentHost* agent = pe_agent_host_list_get(hosts.get(), i);
        int row = AddRow(state->hosts, static_cast<int>(i), Text(agent->name));
        state->hostAccess.push_back(Text(agent->access));
        SetCell(state->hosts, row, 1, state->hostAccess.back());
        SetCell(state->hosts, row, 2, agent->last_used ? FormatDate(agent->last_used) : core::T(PE_TEXT_UI_NEVER));
        state->hostIds.push_back(agent->id);
    }
    if (!state->hostIds.empty()) {
        SelectRow(state->hosts, host);
    }
    FitHostColumns(state);
    ListView_DeleteAllItems(state->log);
    state->entries.clear();
    core::AgentLog log(pe_agent_log(state->core, 500));
    for (size_t i = 0; i < pe_agent_log_count(log.get()); i++) {
        const PeAgentLogEntry* done = pe_agent_log_get(log.get(), i);
        int row = AddRow(state->log, static_cast<int>(i), FormatDate(done->at));
        SetCell(state->log, row, 1, Text(done->host));
        SetCell(state->log, row, 2, Text(done->summary));
        state->entries.push_back({done->id, done->can_undo, done->reads, done->host_id, done->reads_hour});
    }
    if (!state->entries.empty()) {
        SelectRow(state->log, std::min(entry, static_cast<int>(state->entries.size()) - 1));
    }
    UpdateButtons(state);
    ShowReads(state);
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
    core::String why(pe_agent_undo(state->core, state->entries[index].id));
    if (why) {
        MessageBoxW(hwnd, Text(why.get()).c_str(), core::Plain(PE_TEXT_UI_AI_AGENTS).c_str(), MB_OK | MB_ICONINFORMATION);
    }
    FillAgents(state);
}

// ---- Undo Since: take back what a program did in a span ----

struct UndoSinceState {
    PeCore* core;
    int64_t host;
    HWND span = nullptr;
    HWND title = nullptr;
    HWND detail = nullptr;
    HWND takeBack = nullptr;
    HWND cancel = nullptr;
    // the moment the question shown reaches back to, and how many changes it takes back
    int64_t since = 0;
    uint64_t count = 0;
    bool taken = false;
    bool done = false;
};

// the question of the span picked: with changes, Take Back beside Cancel; without, only Close
void ShowUndoQuestion(UndoSinceState& state) {
    int index = static_cast<int>(SendMessageW(state.span, CB_GETCURSEL, 0, 0));
    core::AgentUndoQuestion info(pe_agent_undo_question(state.core, state.host, static_cast<size_t>(std::max(0, index))));
    const PeAgentUndoQuestion* question = pe_agent_undo_question_get(info.get());
    state.count = question ? question->count : 0;
    state.since = question ? question->since : 0;
    SetWindowTextW(state.title, question ? Text(question->title).c_str() : L"");
    // what taking back does, only when there is something to take back
    SetWindowTextW(state.detail, question && state.count ? Text(question->detail).c_str() : L"");
    ShowWindow(state.takeBack, state.count ? SW_SHOW : SW_HIDE);
    SetWindowTextW(state.cancel, core::T(state.count ? PE_TEXT_UI_CANCEL : PE_TEXT_UI_CLOSE).c_str());
}

LRESULT CALLBACK UndoSinceProc(HWND hwnd, UINT message, WPARAM wParam, LPARAM lParam) {
    auto* state = reinterpret_cast<UndoSinceState*>(GetWindowLongPtrW(hwnd, GWLP_USERDATA));
    if (!state) {
        return DefWindowProcW(hwnd, message, wParam, lParam);
    }
    switch (message) {
    case WM_COMMAND:
        switch (LOWORD(wParam)) {
        case IDC_AGENT_UNDO_SPAN:
            if (HIWORD(wParam) == CBN_SELCHANGE) {
                ShowUndoQuestion(*state);
            }
            return 0;
        case IDC_AGENT_TAKE_BACK:
            state->taken = state->count > 0;
            state->done = true;
            return 0;
        case IDCANCEL:
            state->done = true;
            return 0;
        }
        return 0;
    case WM_CLOSE:
        state->done = true;
        return 0;
    case WM_CTLCOLORSTATIC:
        return ButtonFaceColor(reinterpret_cast<HDC>(wParam));
    }
    return DefWindowProcW(hwnd, message, wParam, lParam);
}

// asks which span to take back, shows how many changes that is, and takes them back on Take Back: the report then in
// a message box over the log, refreshed
void UndoSince(HWND hwnd, AgentsState* state) {
    int selected = Selected(state->hosts);
    if (selected < 0 || static_cast<size_t>(selected) >= state->hostIds.size()) {
        return;
    }
    RegisterDialogClass(kUndoSinceClass, UndoSinceProc);
    UndoSinceState undo{state->core, state->hostIds[selected]};
    int pad = Scale(12);
    int width = Scale(480);
    int inner = width - 2 * pad;
    std::wstring label = core::T(PE_TEXT_UI_UNDO_SINCE_SPAN);
    // the heading as tall as the longest of the spans' questions (the program's name, the count), the words under it
    // as tall as they are
    std::vector<std::wstring> spans;
    int titleHeight = Scale(22);
    std::wstring detail;
    for (size_t i = 0; i < PE_AGENT_UNDO_SPAN_COUNT; i++) {
        spans.push_back(Text(core::String(pe_agent_undo_span_label(i)).get()));
        core::AgentUndoQuestion info(pe_agent_undo_question(state->core, undo.host, i));
        if (const PeAgentUndoQuestion* question = pe_agent_undo_question_get(info.get())) {
            titleHeight = std::max(titleHeight, TextHeight(hwnd, Text(question->title), inner, HeadingFont()));
            detail = Text(question->detail);
        }
    }
    int labelHeight = TextHeight(hwnd, label, inner);
    // a word longer than a line broken, as SS_EDITCONTROL breaks it
    int detailHeight = TextHeight(hwnd, detail, inner, nullptr, true);
    std::wstring takeBack = core::T(PE_TEXT_WIN_TAKE_BACK), cancel = core::T(PE_TEXT_UI_CANCEL), close = core::T(PE_TEXT_UI_CLOSE);
    int button = ButtonWidth({takeBack, cancel, close}, 100);
    int height = pad + labelHeight + Scale(4) + Scale(24) + Scale(16) + titleHeight + Scale(6) + detailHeight + Scale(18) + Scale(25) + pad;
    std::wstring windowTitle = core::Plain(PE_TEXT_WIN_UNDO_SINCE);
    // the command's name without the dots that say it asks first (in the pseudo-language before its padding)
    for (const std::wstring dots : {L"...", L"…"}) {
        if (size_t at = windowTitle.find(dots); at != std::wstring::npos) {
            windowTitle.erase(at, dots.size());
        }
    }
    HWND dialog = CreateModalWindow(hwnd, kUndoSinceClass, windowTitle.c_str(), width, height);
    SetWindowLongPtrW(dialog, GWLP_USERDATA, reinterpret_cast<LONG_PTR>(&undo));
    int y = pad;
    CreateChild(dialog, L"STATIC", label.c_str(), SS_LEFT | SS_NOPREFIX, 0, {pad, y, width - pad, y + labelHeight});
    y += labelHeight + Scale(4);
    int spanWidth = std::min(inner, LabelWidth(spans, 160, 40));
    undo.span = CreateChild(dialog, L"COMBOBOX", nullptr, WS_TABSTOP | WS_VSCROLL | CBS_DROPDOWNLIST, IDC_AGENT_UNDO_SPAN,
                            {pad, y, pad + spanWidth, y + Scale(200)});
    for (const std::wstring& span : spans) {
        SendMessageW(undo.span, CB_ADDSTRING, 0, reinterpret_cast<LPARAM>(span.c_str()));
    }
    // the shortest span first: the least it can take back
    SendMessageW(undo.span, CB_SETCURSEL, 0, 0);
    y += Scale(24) + Scale(16);
    undo.title = Heading(dialog, L"", {pad, y, width - pad, y + titleHeight}, true);
    SetWindowLongPtrW(undo.title, GWLP_ID, IDC_AGENT_UNDO_TITLE);
    y += titleHeight + Scale(6);
    undo.detail = CreateChild(dialog, L"STATIC", L"", SS_LEFT | SS_NOPREFIX | SS_EDITCONTROL, IDC_AGENT_UNDO_DETAIL, {pad, y, width - pad, y + detailHeight});
    y = height - pad - Scale(25);
    // Cancel the default, as for anything that changes many messages at once
    undo.takeBack = CreateChild(dialog, L"BUTTON", takeBack.c_str(), WS_TABSTOP, IDC_AGENT_TAKE_BACK,
                                {width - pad - 2 * button - Scale(8), y, width - pad - button - Scale(8), y + Scale(25)});
    undo.cancel = CreateChild(dialog, L"BUTTON", cancel.c_str(), WS_TABSTOP | BS_DEFPUSHBUTTON, IDCANCEL, {width - pad - button, y, width - pad, y + Scale(25)});
    ShowUndoQuestion(undo);
    RunModal(dialog, undo.span, undo.done);
    if (!undo.taken) {
        return;
    }
    core::String report(pe_agent_undo_since(state->core, undo.host, undo.since));
    FillAgents(state);
    if (report) {
        MessageBoxW(hwnd, Text(report.get()).c_str(), core::Plain(PE_TEXT_UI_AI_AGENTS).c_str(), MB_OK | MB_ICONINFORMATION);
    }
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
        case IDC_AGENTS_UNDO_SINCE:
            UndoSince(hwnd, state);
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
            // another row of the log selected: what it read, or nothing
            auto* change = reinterpret_cast<NMLISTVIEW*>(lParam);
            if (header->hwndFrom == state->log && (change->uNewState & LVIS_SELECTED) && !(change->uOldState & LVIS_SELECTED)) {
                ShowReads(state);
            }
        } else if (header->hwndFrom == state->hosts && header->code == LVN_ITEMACTIVATE) {
            ChangeHost(hwnd, state);
        } else if (header->hwndFrom == state->hosts && header->code == LVN_GETINFOTIPW) {
            // the whole of what the program may do, should a narrow screen cut it
            auto* tip = reinterpret_cast<NMLVGETINFOTIPW*>(lParam);
            if (tip->iItem >= 0 && static_cast<size_t>(tip->iItem) < state->hostAccess.size() && tip->cchTextMax > 0) {
                wcsncpy_s(tip->pszText, tip->cchTextMax, state->hostAccess[tip->iItem].c_str(), _TRUNCATE);
            }
        }
        return 0;
    }
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
    case PE_AGENT_ASK_KIND_UNSUBSCRIBE:
        UnsubscribeDialog(owner, core, request);
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
    HelpScope help("agents");
    RegisterDialogClass(kAgentsClass, AgentsProc);
    int pad = Scale(12);
    std::wstring change = core::T(PE_TEXT_WIN_CHANGE), remove = core::T(PE_TEXT_UI_REMOVE), undo = core::T(PE_TEXT_CMD_UNDO);
    std::wstring clear = core::T(PE_TEXT_UI_CLEAR_BUTTON), close = core::T(PE_TEXT_UI_CLOSE), setup = core::T(PE_TEXT_UI_HOW_TO_CONNECT);
    std::wstring undoSince = core::T(PE_TEXT_WIN_UNDO_SINCE);
    int button = ButtonWidth({change, remove, undoSince, undo, clear, close}, 100);
    // wide enough for what each program may do beside its name and when it was last used, within the screen
    RECT screen = {};
    SystemParametersInfoW(SPI_GETWORKAREA, 0, &screen, 0);
    int wanted = 2 * pad + button + Scale(10) + Scale(4) + HostColumnsWidth(core);
    int width = std::clamp(wanted, Scale(680), std::max(Scale(680), static_cast<int>(screen.right - screen.left) - Scale(40)));
    int height = Scale(620);
    HWND dialog = CreateModalWindow(owner, kAgentsClass, core::Plain(PE_TEXT_UI_AI_AGENTS).c_str(), width, height);
    AgentsState state{core};
    SetWindowLongPtrW(dialog, GWLP_USERDATA, reinterpret_cast<LONG_PTR>(&state));
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
    ListView_SetExtendedListViewStyle(state.hosts, LVS_EX_FULLROWSELECT | LVS_EX_INFOTIP);
    state.change = CreateChild(dialog, L"BUTTON", change.c_str(), WS_TABSTOP, IDC_AGENTS_CHANGE, {width - pad - button, y, width - pad, y + Scale(25)});
    state.remove = CreateChild(dialog, L"BUTTON", remove.c_str(), WS_TABSTOP, IDC_AGENTS_REMOVE,
                               {width - pad - button, y + Scale(31), width - pad, y + Scale(56)});
    // what the selected program did in a span, taken back at once (the log's Undo takes back one row)
    state.undoSince = CreateChild(dialog, L"BUTTON", undoSince.c_str(), WS_TABSTOP, IDC_AGENTS_UNDO_SINCE,
                                  {width - pad - button, y + Scale(62), width - pad, y + Scale(87)});
    y += Scale(120) + Scale(14);
    CreateChild(dialog, L"STATIC", core::T(PE_TEXT_WIN_WHAT_AGENTS_DID).c_str(), SS_LEFT, 0, {pad, y, listRight, y + Scale(16)});
    y += Scale(18);
    // the log over the reads of its selected row, as the message list over the preview
    int readsHeight = Scale(110);
    int readsTop = height - pad - Scale(25) - Scale(12) - readsHeight;
    int logBottom = readsTop - Scale(8) - Scale(18);
    state.log = CreateReportList(dialog, IDC_AGENTS_LOG, {pad, y, listRight, logBottom});
    AddColumn(state.log, 0, core::T(PE_TEXT_UI_COL_WHEN).c_str(), 110);
    AddColumn(state.log, 1, core::T(PE_TEXT_UI_COL_PROGRAM).c_str(), 90);
    AddColumn(state.log, 2, core::T(PE_TEXT_UI_COL_WHAT).c_str(), 320);
    ListView_SetColumnWidth(state.log, 2, LVSCW_AUTOSIZE_USEHEADER);
    state.undo = CreateChild(dialog, L"BUTTON", undo.c_str(), WS_TABSTOP, IDC_AGENTS_UNDO, {width - pad - button, y, width - pad, y + Scale(25)});
    state.clear = CreateChild(dialog, L"BUTTON", clear.c_str(), WS_TABSTOP, IDC_AGENTS_CLEAR,
                              {width - pad - button, y + Scale(31), width - pad, y + Scale(56)});
    state.readsLabel = CreateChild(dialog, L"STATIC", L"", SS_LEFT | SS_NOPREFIX | SS_ENDELLIPSIS, IDC_AGENTS_READS_LABEL,
                                   {pad, logBottom + Scale(8), listRight, logBottom + Scale(8) + Scale(16)});
    state.reads = CreateReportList(dialog, IDC_AGENTS_READS, {pad, readsTop, listRight, readsTop + readsHeight});
    AddColumn(state.reads, 0, core::T(PE_TEXT_UI_COL_WHEN).c_str(), 110);
    AddColumn(state.reads, 1, core::T(PE_TEXT_UI_COL_WHAT).c_str(), 320);
    int bottom = height - pad - Scale(25);
    // a push button at the left of the row, as the Mac and Linux have it: it opens the help on connecting one
    int setupWidth = ButtonWidth({setup});
    CreateChild(dialog, L"BUTTON", setup.c_str(), WS_TABSTOP | BS_PUSHBUTTON, IDC_AGENTS_SETUP, {pad, bottom, pad + setupWidth, height - pad});
    CreateChild(dialog, L"BUTTON", close.c_str(), WS_TABSTOP | BS_DEFPUSHBUTTON, IDOK, {width - pad - button, bottom, width - pad, height - pad});
    FillAgents(&state);
    g_agents = dialog;
    RunModal(dialog, state.hosts, state.done);
    g_agents = nullptr;
}
