// Message rules: the Message Rules window (Tools) with the rules that sort the new mail of the Inboxes, each turned
// on or off, in their order, and the editor of one. What a rule matches, how many it matches now and why a query can
// not be a rule's all come from the core; this file only shows them and hands back what was typed.
#include "app.h"

namespace {

// the words for the Find box the editor's Show asked for, put there once the rule windows are closed
std::wstring g_showWords;

// the search of Show, once the windows that asked for it are gone
void ShowPendingSearch() {
    if (g_showWords.empty()) {
        return;
    }
    std::wstring words;
    words.swap(g_showWords);
    SearchFor(words);
}

// ---- the editor ----

const wchar_t* kEditorClass = L"InboxClassicRule";

// a moment after the query or the account changed, the count of what it matches follows
constexpr UINT_PTR TIMER_COUNT = 1;

// the action check boxes under "Do this:", Move it to first (its folder beside it)
constexpr int kActionIds[] = {IDC_RULE_MOVE, IDC_RULE_MARK_READ, IDC_RULE_FLAG, IDC_RULE_ARCHIVE, IDC_RULE_JUNK, IDC_RULE_DELETE, IDC_RULE_QUIET};
constexpr PeText kActionTexts[] = {PE_TEXT_UI_RULE_MOVE, PE_TEXT_UI_RULE_MARK_READ, PE_TEXT_UI_RULE_FLAG, PE_TEXT_UI_RULE_ARCHIVE,
                                   PE_TEXT_UI_RULE_JUNK, PE_TEXT_UI_RULE_DELETE, PE_TEXT_UI_RULE_QUIET};

// the actions that send a message away, of which one at most is ticked
constexpr int kAwayIds[] = {IDC_RULE_MOVE, IDC_RULE_ARCHIVE, IDC_RULE_JUNK, IDC_RULE_DELETE};

struct EditorState {
    PeCore* core = nullptr;
    // the rule changed, 0 for a new one, and whether it is on
    int64_t id = 0;
    bool enabled = true;
    // the account of each row of the account choice, 0 (All accounts) first
    std::vector<int64_t> accounts;
    core::RuleTargetList targets;
    // the folder of each row of the Move it to choice
    std::vector<int64_t> shown;
    int64_t saved = 0;
    bool done = false;
};

HWND Item(HWND dialog, int id) {
    return GetDlgItem(dialog, id);
}

bool Checked(HWND dialog, int id) {
    return SendMessageW(Item(dialog, id), BM_GETCHECK, 0, 0) == BST_CHECKED;
}

void SetChecked(HWND dialog, int id, bool on) {
    SendMessageW(Item(dialog, id), BM_SETCHECK, on ? BST_CHECKED : BST_UNCHECKED, 0);
}

int64_t ChosenAccount(HWND dialog, const EditorState& state) {
    auto index = static_cast<int>(SendMessageW(Item(dialog, IDC_RULE_ACCOUNT), CB_GETCURSEL, 0, 0));
    return index >= 0 && static_cast<size_t>(index) < state.accounts.size() ? state.accounts[index] : 0;
}

int64_t ChosenFolder(HWND dialog, const EditorState& state) {
    auto index = static_cast<int>(SendMessageW(Item(dialog, IDC_RULE_MOVE_TO), CB_GETCURSEL, 0, 0));
    return index >= 0 && static_cast<size_t>(index) < state.shown.size() ? state.shown[index] : 0;
}

// the folders Move it to offers: the chosen account's, or every account's for All accounts; `folder` chosen when it
// is one of them
void FillTargets(HWND dialog, EditorState& state, int64_t folder) {
    HWND combo = Item(dialog, IDC_RULE_MOVE_TO);
    SendMessageW(combo, CB_RESETCONTENT, 0, 0);
    state.shown.clear();
    int64_t account = ChosenAccount(dialog, state);
    for (size_t i = 0; i < pe_rule_targets_count(state.targets.get()); i++) {
        const PeRuleTarget* target = pe_rule_targets_get(state.targets.get(), i);
        if (account && target->account != account) {
            continue;
        }
        SendMessageW(combo, CB_ADDSTRING, 0, reinterpret_cast<LPARAM>(Text(target->label).c_str()));
        if (target->folder == folder) {
            SendMessageW(combo, CB_SETCURSEL, state.shown.size(), 0);
        }
        state.shown.push_back(target->folder);
    }
    // none chosen: the first is shown, also while greyed, as on the Mac and Linux
    if (SendMessageW(combo, CB_GETCURSEL, 0, 0) < 0) {
        SendMessageW(combo, CB_SETCURSEL, 0, 0);
    }
}

// the folder choice is for Move it to alone; Show for a query that can be a rule's
void UpdateEnabled(HWND dialog) {
    bool move = Checked(dialog, IDC_RULE_MOVE);
    HWND combo = Item(dialog, IDC_RULE_MOVE_TO);
    EnableWindow(combo, move);
}

// how many messages in the Inbox the query matches now, or why it can not be a rule's
void UpdateCount(HWND dialog, const EditorState& state) {
    std::string query = core::Narrow(GetWindowString(Item(dialog, IDC_RULE_QUERY)));
    std::wstring said;
    bool usable = query.find_first_not_of(" \t") != std::string::npos;
    if (usable) {
        core::String problem(pe_rule_query_problem(state.core, query.c_str()));
        if (problem) {
            said = Text(problem.get());
            usable = false;
        } else {
            uint64_t count = pe_rule_matches(state.core, query.c_str(), ChosenAccount(dialog, state));
            said = core::T(PE_TEXT_UI_RULE_COUNT, {{"count", std::to_wstring(count)}});
        }
    }
    SetWindowTextW(Item(dialog, IDC_RULE_COUNT), said.c_str());
    EnableWindow(Item(dialog, IDC_RULE_SHOW), usable);
}

// OK: the rule saved, and applied to the Inbox when asked; false when the editor stays open (with the reason shown)
bool SaveRule(HWND dialog, EditorState& state) {
    std::string name = core::Narrow(GetWindowString(Item(dialog, IDC_RULE_NAME)));
    std::string query = core::Narrow(GetWindowString(Item(dialog, IDC_RULE_QUERY)));
    // a rule without a name is called by what it matches
    if (name.find_first_not_of(" \t") == std::string::npos) {
        name = query;
    }
    PeRule rule = {};
    rule.id = state.id;
    rule.enabled = state.enabled;
    rule.name = name.c_str();
    rule.account = ChosenAccount(dialog, state);
    rule.query = query.c_str();
    rule.move_to = Checked(dialog, IDC_RULE_MOVE) ? ChosenFolder(dialog, state) : 0;
    rule.mark_read = Checked(dialog, IDC_RULE_MARK_READ);
    rule.flag = Checked(dialog, IDC_RULE_FLAG);
    rule.archive = Checked(dialog, IDC_RULE_ARCHIVE);
    rule.junk = Checked(dialog, IDC_RULE_JUNK);
    rule.remove = Checked(dialog, IDC_RULE_DELETE);
    rule.quiet = Checked(dialog, IDC_RULE_QUIET);
    char* error = nullptr;
    int64_t saved = pe_rule_save(state.core, &rule, &error);
    if (!saved) {
        MessageBoxW(dialog, ReasonText(error, PE_TEXT_UI_UNKNOWN_REASON).c_str(), core::Plain(PE_TEXT_UI_RULE_TITLE).c_str(), MB_OK | MB_ICONWARNING);
        SetFocus(Item(dialog, IDC_RULE_QUERY));
        return false;
    }
    if (Checked(dialog, IDC_RULE_APPLY_NOW)) {
        pe_rule_apply_now(state.core, saved);
    }
    state.saved = saved;
    return true;
}

void OnEditorCommand(HWND dialog, EditorState& state, int id, int code) {
    switch (id) {
    case IDC_RULE_QUERY:
        if (code == EN_CHANGE) {
            SetTimer(dialog, TIMER_COUNT, 300, nullptr);
        }
        return;
    case IDC_RULE_ACCOUNT:
        if (code == CBN_SELCHANGE) {
            FillTargets(dialog, state, ChosenFolder(dialog, state));
            UpdateEnabled(dialog);
            SetTimer(dialog, TIMER_COUNT, 0, nullptr);
        }
        return;
    case IDC_RULE_MOVE:
    case IDC_RULE_ARCHIVE:
    case IDC_RULE_JUNK:
    case IDC_RULE_DELETE:
        // a message goes to one place: the other three are unticked
        if (Checked(dialog, id)) {
            for (int other : kAwayIds) {
                if (other != id) {
                    SetChecked(dialog, other, false);
                }
            }
        }
        UpdateEnabled(dialog);
        return;
    case IDC_RULE_SHOW: {
        // what the query matches in the Inboxes, in the main window's list: the rule windows close for it
        std::string query = core::Narrow(GetWindowString(Item(dialog, IDC_RULE_QUERY)));
        core::String words(pe_rule_search_text(state.core, query.c_str()));
        g_showWords = words ? Text(words.get()) : L"";
        state.done = !g_showWords.empty();
        return;
    }
    case IDOK:
        state.done = SaveRule(dialog, state);
        return;
    case IDCANCEL:
        state.done = true;
        return;
    }
}

LRESULT CALLBACK EditorProc(HWND hwnd, UINT message, WPARAM wParam, LPARAM lParam) {
    auto* state = reinterpret_cast<EditorState*>(GetWindowLongPtrW(hwnd, GWLP_USERDATA));
    switch (message) {
    case WM_COMMAND:
        if (state) {
            OnEditorCommand(hwnd, *state, LOWORD(wParam), HIWORD(wParam));
        }
        return 0;
    case WM_TIMER:
        KillTimer(hwnd, wParam);
        if (state && wParam == TIMER_COUNT) {
            UpdateCount(hwnd, *state);
        }
        return 0;
    case WM_CLOSE:
        if (state) {
            state->done = true;
        }
        return 0;
    case WM_CTLCOLORSTATIC: {
        auto dc = reinterpret_cast<HDC>(wParam);
        // the hint under the query is quieter than the labels
        if (reinterpret_cast<HWND>(lParam) == Item(hwnd, IDC_RULE_HINT)) {
            SetTextColor(dc, GetSysColor(COLOR_GRAYTEXT));
        }
        return ButtonFaceColor(dc);
    }
    }
    return DefWindowProcW(hwnd, message, wParam, lParam);
}

// the editor of `rule` (id 0 for a new one, its fields filled in as given); the id saved, 0 when cancelled
int64_t RuleEditor(HWND owner, PeCore* core, const PeRule& rule) {
    HelpScope help("message-rules");
    RegisterDialogClass(kEditorClass, EditorProc);
    EditorState state{core, rule.id, rule.enabled};
    state.targets.reset(pe_rule_targets(core));
    std::wstring nameLabel = core::T(PE_TEXT_UI_RULE_NAME), accountLabel = core::T(PE_TEXT_UI_RULE_ACCOUNT);
    std::wstring queryLabel = core::T(PE_TEXT_UI_RULE_QUERY), hint = core::T(PE_TEXT_UI_RULE_QUERY_HINT);
    std::wstring show = core::T(PE_TEXT_UI_RULE_SHOW), apply = core::T(PE_TEXT_UI_RULE_APPLY_NOW);
    std::wstring ok = core::T(PE_TEXT_UI_OK), cancel = core::T(PE_TEXT_UI_CANCEL);
    int pad = Scale(10), width = Scale(500), row = Scale(28), check = Scale(22);
    int labelWidth = LabelWidth({nameLabel, accountLabel, queryLabel}, 110);
    int right = width - pad, left = pad + labelWidth;
    int hintHeight = static_cast<int>(MeasureText(hint, right - left).cy);
    int showWidth = ButtonWidth({show});
    // the actions' check boxes in from the labels; Move it to with its folder at the inputs' left, or after its words
    int indent = pad + Scale(12);
    int moveRight = std::max(left, indent + static_cast<int>(MeasureText(core::T(PE_TEXT_UI_RULE_MOVE)).cx) + Scale(28));
    int actions = static_cast<int>(std::size(kActionIds));
    // the three fields and the hint, the count (two lines at most), "Do this:" and the actions, Apply now, the buttons
    int height = pad + 2 * row + Scale(25) + hintHeight + Scale(6) + Scale(46) + Scale(10) + Scale(20) + Scale(26) + (actions - 1) * check +
                 Scale(20) + check + Scale(16) + Scale(25) + pad;
    HWND dialog = CreateModalWindow(owner, kEditorClass, core::Plain(PE_TEXT_UI_RULE_TITLE).c_str(), width, height);
    SetWindowLongPtrW(dialog, GWLP_USERDATA, 0);

    auto label = [&](const std::wstring& text, int top) {
        CreateChild(dialog, L"STATIC", text.c_str(), SS_LEFT, 0, {pad, top + Scale(3), left, top + Scale(22)});
    };
    int top = pad;
    label(nameLabel, top);
    HWND name = CreateChild(dialog, L"EDIT", Text(rule.name).c_str(), WS_TABSTOP | ES_AUTOHSCROLL, IDC_RULE_NAME, {left, top, right, top + Scale(22)},
                            WS_EX_CLIENTEDGE);
    top += row;
    label(accountLabel, top);
    HWND accounts = CreateChild(dialog, L"COMBOBOX", nullptr, WS_TABSTOP | WS_VSCROLL | CBS_DROPDOWNLIST, IDC_RULE_ACCOUNT,
                                {left, top, right, top + Scale(200)});
    SendMessageW(accounts, CB_ADDSTRING, 0, reinterpret_cast<LPARAM>(core::Plain(PE_TEXT_UI_RULE_ALL_ACCOUNTS).c_str()));
    state.accounts.push_back(0);
    core::AccountList list(pe_accounts(core));
    for (size_t i = 0; i < pe_account_list_count(list.get()); i++) {
        const PeAccount* account = pe_account_list_get(list.get(), i);
        SendMessageW(accounts, CB_ADDSTRING, 0, reinterpret_cast<LPARAM>(Text(account->label).c_str()));
        if (account->id == rule.account) {
            SendMessageW(accounts, CB_SETCURSEL, state.accounts.size(), 0);
        }
        state.accounts.push_back(account->id);
    }
    if (SendMessageW(accounts, CB_GETCURSEL, 0, 0) < 0) {
        SendMessageW(accounts, CB_SETCURSEL, 0, 0);
    }
    top += row;
    label(queryLabel, top);
    CreateChild(dialog, L"EDIT", Text(rule.query).c_str(), WS_TABSTOP | ES_AUTOHSCROLL, IDC_RULE_QUERY, {left, top, right, top + Scale(22)},
                WS_EX_CLIENTEDGE);
    top += Scale(25);
    CreateChild(dialog, L"STATIC", hint.c_str(), SS_LEFT | SS_NOPREFIX, IDC_RULE_HINT, {left, top, right, top + hintHeight});
    top += hintHeight + Scale(6);
    // the count beside Show; a query that can not be a rule's says why there, in up to two lines
    CreateChild(dialog, L"STATIC", L"", SS_LEFT | SS_NOPREFIX, IDC_RULE_COUNT, {left, top + Scale(5), right - showWidth - Scale(8), top + Scale(36)});
    CreateChild(dialog, L"BUTTON", show.c_str(), WS_TABSTOP, IDC_RULE_SHOW, {right - showWidth, top, right, top + Scale(25)});
    top += Scale(36) + Scale(10);
    CreateChild(dialog, L"STATIC", L"", SS_ETCHEDHORZ, 0, {pad, top, right, top + 2});
    top += Scale(10);
    CreateChild(dialog, L"STATIC", core::T(PE_TEXT_UI_RULE_ACTIONS).c_str(), SS_LEFT | SS_NOPREFIX, 0, {pad, top, right, top + Scale(16)});
    top += Scale(20);
    bool on[] = {rule.move_to != 0, rule.mark_read, rule.flag, rule.archive, rule.junk, rule.remove, rule.quiet};
    for (int i = 0; i < actions; i++) {
        int boxRight = i == 0 ? moveRight - Scale(4) : right;
        CreateChild(dialog, L"BUTTON", core::T(kActionTexts[i]).c_str(), WS_TABSTOP | BS_AUTOCHECKBOX, kActionIds[i],
                    {indent, top + (i == 0 ? Scale(1) : 0), boxRight, top + (i == 0 ? Scale(23) : check)});
        SetChecked(dialog, kActionIds[i], on[i]);
        if (i == 0) {
            CreateChild(dialog, L"COMBOBOX", nullptr, WS_TABSTOP | WS_VSCROLL | CBS_DROPDOWNLIST, IDC_RULE_MOVE_TO,
                        {moveRight, top, right, top + Scale(240)});
            top += Scale(26);
        } else {
            top += check;
        }
    }
    top += Scale(10);
    CreateChild(dialog, L"STATIC", L"", SS_ETCHEDHORZ, 0, {pad, top, right, top + 2});
    top += Scale(10);
    CreateChild(dialog, L"BUTTON", apply.c_str(), WS_TABSTOP | BS_AUTOCHECKBOX, IDC_RULE_APPLY_NOW, {pad, top, right, top + check});

    int buttonTop = height - pad - Scale(25);
    int buttonWidth = ButtonWidth({ok, cancel});
    CreateChild(dialog, L"BUTTON", ok.c_str(), WS_TABSTOP | BS_DEFPUSHBUTTON, IDOK,
                {right - 2 * buttonWidth - Scale(6), buttonTop, right - buttonWidth - Scale(6), buttonTop + Scale(25)});
    CreateChild(dialog, L"BUTTON", cancel.c_str(), WS_TABSTOP, IDCANCEL, {right - buttonWidth, buttonTop, right, buttonTop + Scale(25)});

    FillTargets(dialog, state, rule.move_to);
    UpdateEnabled(dialog);
    UpdateCount(dialog, state);
    SetWindowLongPtrW(dialog, GWLP_USERDATA, reinterpret_cast<LONG_PTR>(&state));
    SendMessageW(name, EM_SETSEL, 0, -1);
    RunModal(dialog, name, state.done);
    return state.saved;
}

// ---- the Message Rules window ----

const wchar_t* kRulesClass = L"InboxClassicRules";

enum RulesColumn { RULES_NAME, RULES_MATCHES };

// the rows filled again once the list's notification of a check box is over (wParam: the row to select)
constexpr UINT WM_REFILL = WM_APP + 10;

struct RulesState {
    PeCore* core;
    HWND list = nullptr;
    core::RuleList rules;
    // while the rows are filled, their check boxes changing is not the user turning a rule on or off
    bool filling = false;
    bool done = false;
};

const PeRule* RuleAt(const RulesState& state, int row) {
    return row >= 0 ? pe_rules_get(state.rules.get(), static_cast<size_t>(row)) : nullptr;
}

int SelectedIndex(const RulesState& state) {
    return ListView_GetNextItem(state.list, -1, LVNI_SELECTED);
}

// Edit and Delete for a selected rule, Move Up and Move Down where it can go
void ShowSelected(HWND hwnd, const RulesState& state) {
    int index = SelectedIndex(state);
    int count = ListView_GetItemCount(state.list);
    EnableWindow(GetDlgItem(hwnd, IDC_RULES_EDIT), index >= 0);
    EnableWindow(GetDlgItem(hwnd, IDC_RULES_DELETE), index >= 0);
    EnableWindow(GetDlgItem(hwnd, IDC_RULES_UP), index > 0);
    EnableWindow(GetDlgItem(hwnd, IDC_RULES_DOWN), index >= 0 && index < count - 1);
}

// a row per rule in their order, checked when it is on; `select` stays selected
void FillRules(HWND hwnd, RulesState& state, int select = 0) {
    state.filling = true;
    ListView_DeleteAllItems(state.list);
    state.rules.reset(pe_rules(state.core));
    for (size_t i = 0; i < pe_rules_count(state.rules.get()); i++) {
        const PeRule* rule = pe_rules_get(state.rules.get(), i);
        int row = AddRow(state.list, static_cast<int>(i), Text(rule->name));
        SetCell(state.list, row, RULES_MATCHES, Text(rule->query));
        ListView_SetCheckState(state.list, row, rule->enabled);
    }
    SelectRow(state.list, select);
    state.filling = false;
    ShowSelected(hwnd, state);
    // the empty list's words drawn again, or taken away
    InvalidateRect(state.list, nullptr, TRUE);
}

// a check box changed: the rule turned on or off, saved at once
void OnChecked(HWND hwnd, RulesState& state, int row) {
    const PeRule* rule = RuleAt(state, row);
    bool on = ListView_GetCheckState(state.list, row);
    if (!rule || rule->enabled == on) {
        return;
    }
    PeRule changed = *rule;
    changed.enabled = on;
    char* error = nullptr;
    if (!pe_rule_save(state.core, &changed, &error)) {
        MessageBoxW(hwnd, ReasonText(error, PE_TEXT_UI_UNKNOWN_REASON).c_str(), core::Plain(PE_TEXT_UI_RULES_TITLE).c_str(), MB_OK | MB_ICONWARNING);
    }
    PostMessageW(hwnd, WM_REFILL, static_cast<WPARAM>(row), 0);
}

// in the middle of the list while it has no rule: how to make one
void DrawEmptyRules(HWND list, HDC dc) {
    RECT area;
    GetClientRect(list, &area);
    RECT header;
    GetWindowRect(ListView_GetHeader(list), &header);
    area.top += (header.bottom - header.top) + Scale(24);
    InflateRect(&area, -Scale(16), 0);
    std::wstring text = core::T(PE_TEXT_UI_RULES_NONE);
    HGDIOBJ old = SelectObject(dc, reinterpret_cast<HFONT>(SendMessageW(list, WM_GETFONT, 0, 0)));
    SetTextColor(dc, GetSysColor(COLOR_GRAYTEXT));
    SetBkMode(dc, TRANSPARENT);
    DrawTextW(dc, text.c_str(), -1, &area, DT_CENTER | DT_WORDBREAK | DT_NOPREFIX);
    SelectObject(dc, old);
}

void OnRulesCommand(HWND hwnd, RulesState& state, WORD id) {
    int index = SelectedIndex(state);
    const PeRule* rule = RuleAt(state, index);
    switch (id) {
    case IDC_RULES_NEW: {
        PeRule blank = {};
        blank.enabled = true;
        blank.name = "";
        blank.query = "";
        if (RuleEditor(hwnd, state.core, blank)) {
            FillRules(hwnd, state, static_cast<int>(pe_rules_count(state.rules.get())));
        }
        break;
    }
    case IDC_RULES_EDIT:
        if (rule && RuleEditor(hwnd, state.core, *rule)) {
            FillRules(hwnd, state, index);
        }
        break;
    case IDC_RULES_DELETE: {
        if (!rule) {
            return;
        }
        std::wstring question = core::T(PE_TEXT_UI_RULE_DELETE_ASK, {{"name", Text(rule->name)}});
        if (MessageBoxW(hwnd, question.c_str(), core::Plain(PE_TEXT_UI_RULES_TITLE).c_str(), MB_YESNO | MB_ICONWARNING | MB_DEFBUTTON2) != IDYES) {
            return;
        }
        pe_rule_delete(state.core, rule->id);
        FillRules(hwnd, state, index);
        SetFocus(state.list);
        return;
    }
    case IDC_RULES_UP:
    case IDC_RULES_DOWN:
        if (rule && pe_rule_move(state.core, rule->id, id == IDC_RULES_UP)) {
            FillRules(hwnd, state, index + (id == IDC_RULES_UP ? -1 : 1));
        }
        return;
    case IDC_RULES_CLOSE:
    case IDCANCEL:
        state.done = true;
        return;
    }
    // Show in the editor closes this window too
    if (!g_showWords.empty()) {
        state.done = true;
    }
}

LRESULT CALLBACK RulesProc(HWND hwnd, UINT message, WPARAM wParam, LPARAM lParam) {
    auto* state = reinterpret_cast<RulesState*>(GetWindowLongPtrW(hwnd, GWLP_USERDATA));
    switch (message) {
    case WM_COMMAND:
        if (state) {
            // Enter in the list is IDOK of the window: Edit of the selected rule
            WORD id = LOWORD(wParam) == IDOK && GetFocus() == state->list ? static_cast<WORD>(IDC_RULES_EDIT) : LOWORD(wParam);
            OnRulesCommand(hwnd, *state, id);
        }
        return 0;
    case WM_NOTIFY: {
        auto* header = reinterpret_cast<NMHDR*>(lParam);
        if (!state || header->hwndFrom != state->list) {
            return 0;
        }
        if (header->code == NM_CUSTOMDRAW) {
            auto* draw = reinterpret_cast<NMLVCUSTOMDRAW*>(lParam);
            if (draw->nmcd.dwDrawStage == CDDS_PREPAINT) {
                return CDRF_NOTIFYPOSTPAINT;
            }
            if (draw->nmcd.dwDrawStage == CDDS_POSTPAINT && ListView_GetItemCount(state->list) == 0) {
                DrawEmptyRules(state->list, draw->nmcd.hdc);
            }
            return CDRF_DODEFAULT;
        }
        if (state->filling) {
            return 0;
        }
        if (header->code == LVN_ITEMCHANGED) {
            auto* change = reinterpret_cast<NMLISTVIEW*>(lParam);
            if ((change->uChanged & LVIF_STATE) && ((change->uNewState ^ change->uOldState) & LVIS_STATEIMAGEMASK)) {
                OnChecked(hwnd, *state, change->iItem);
            } else if ((change->uChanged & LVIF_STATE) && ((change->uNewState ^ change->uOldState) & LVIS_SELECTED)) {
                ShowSelected(hwnd, *state);
            }
        } else if (header->code == LVN_ITEMACTIVATE) {
            OnRulesCommand(hwnd, *state, IDC_RULES_EDIT);
        } else if (header->code == LVN_KEYDOWN && reinterpret_cast<NMLVKEYDOWN*>(lParam)->wVKey == VK_DELETE) {
            OnRulesCommand(hwnd, *state, IDC_RULES_DELETE);
        }
        return 0;
    }
    case WM_REFILL:
        if (state) {
            FillRules(hwnd, *state, static_cast<int>(wParam));
        }
        return 0;
    case WM_CLOSE:
        if (state) {
            state->done = true;
        }
        return 0;
    case WM_CTLCOLORSTATIC:
        return ButtonFaceColor(reinterpret_cast<HDC>(wParam));
    }
    return DefWindowProcW(hwnd, message, wParam, lParam);
}

}  // namespace

void MessageRulesDialog(HWND owner, PeCore* core) {
    HelpScope help("message-rules");
    RegisterDialogClass(kRulesClass, RulesProc);
    int pad = Scale(10), width = Scale(560), height = Scale(340);
    struct Button {
        WORD id;
        std::wstring text;
    };
    Button buttons[] = {{IDC_RULES_NEW, core::T(PE_TEXT_UI_RULE_NEW)},
                        {IDC_RULES_EDIT, core::T(PE_TEXT_UI_RULE_EDIT)},
                        {IDC_RULES_DELETE, core::T(PE_TEXT_UI_RULE_DELETE_BUTTON)},
                        {IDC_RULES_UP, core::T(PE_TEXT_UI_ACCOUNT_MOVE_UP)},
                        {IDC_RULES_DOWN, core::T(PE_TEXT_UI_ACCOUNT_MOVE_DOWN)}};
    std::wstring close = core::T(PE_TEXT_UI_CLOSE), intro = core::T(PE_TEXT_UI_RULES_INTRO);
    int buttonWidth = ButtonWidth({buttons[0].text, buttons[1].text, buttons[2].text, buttons[3].text, buttons[4].text, close}, 100);
    int introHeight = static_cast<int>(MeasureText(intro, width - 2 * pad).cy);
    HWND dialog = CreateModalWindow(owner, kRulesClass, core::Plain(PE_TEXT_UI_RULES_TITLE).c_str(), width, height);
    RulesState state{core};
    int listRight = width - pad - buttonWidth - pad;
    int top = pad;
    CreateChild(dialog, L"STATIC", intro.c_str(), SS_LEFT | SS_NOPREFIX, 0, {pad, top, width - pad, top + introHeight});
    top += introHeight + Scale(10);
    state.list = CreateReportList(dialog, IDC_RULES_LIST, {pad, top, listRight, height - pad});
    ListView_SetExtendedListViewStyleEx(state.list, LVS_EX_CHECKBOXES, LVS_EX_CHECKBOXES);
    AddColumn(state.list, RULES_NAME, core::T(PE_TEXT_UI_COL_NAME).c_str(), 180);
    AddColumn(state.list, RULES_MATCHES, core::T(PE_TEXT_UI_COL_RULE_MATCHES).c_str(), 160);
    ListView_SetColumnWidth(state.list, RULES_MATCHES, LVSCW_AUTOSIZE_USEHEADER);
    int buttonTop = top;
    for (size_t i = 0; i < std::size(buttons); i++) {
        // Move Up and Move Down apart from the others
        if (i == 3) {
            buttonTop += Scale(12);
        }
        CreateChild(dialog, L"BUTTON", buttons[i].text.c_str(), WS_TABSTOP, buttons[i].id,
                    {width - pad - buttonWidth, buttonTop, width - pad, buttonTop + Scale(25)});
        buttonTop += Scale(31);
    }
    CreateChild(dialog, L"BUTTON", close.c_str(), WS_TABSTOP | BS_DEFPUSHBUTTON, IDC_RULES_CLOSE,
                {width - pad - buttonWidth, height - pad - Scale(25), width - pad, height - pad});
    SetWindowLongPtrW(dialog, GWLP_USERDATA, reinterpret_cast<LONG_PTR>(&state));
    FillRules(dialog, state);
    RunModal(dialog, state.list, state.done);
    ShowPendingSearch();
}

int64_t NewRuleDialog(HWND owner, PeCore* core, const std::wstring& query) {
    std::string words = core::Narrow(query);
    PeRule rule = {};
    rule.enabled = true;
    rule.name = words.c_str();
    rule.query = words.c_str();
    int64_t saved = RuleEditor(owner, core, rule);
    ShowPendingSearch();
    return saved;
}
