// The Move and Copy window: the folders of every account in a tree, a Find box over it, the folders used last on top,
// New Folder, and a button that says what it does. The core gives the words and the rows (pe_move_targets, which also
// filters them by what is typed); this shows them.
#include "app.h"

#include <algorithm>
#include <string>

#include "icons.h"

namespace {

const wchar_t* kPickerClass = L"InboxClassicFolderPicker";

constexpr int IDC_PICKER_FILTER = 101;
constexpr int IDC_PICKER_TREE = 102;
constexpr int IDC_PICKER_NEW = 103;

// a row of the window as the core gave it
struct Row {
    PeTargetKind kind;
    int64_t account;
    int64_t folder;
    bool choosable;
};

struct PickerState {
    FolderPick* pick = nullptr;
    HWND dialog = nullptr;
    HWND prompt = nullptr;
    HWND findLabel = nullptr;
    HWND filter = nullptr;
    HWND tree = nullptr;
    HWND newFolder = nullptr;
    HWND ok = nullptr;
    HWND cancel = nullptr;
    bool done = false;
    int64_t chosen = 0;
    // the folder highlighted, kept while the tree is filled again
    int64_t highlighted = 0;
    // filled once: the first time, the folder used last is highlighted, so Enter moves there
    bool filled = false;
    // the rows shown, by the index each tree item carries
    std::vector<Row> rows;
};

// the one open picker, for RefreshFolderPick
PickerState* g_open = nullptr;

// the folder strip's icon for the core's name of one; the heading and a plain folder have the plain folder
int IconOf(PeTargetKind kind, const char* icon) {
    if (kind == PE_TARGET_KIND_ACCOUNT) {
        return FOLDER_MAILBOX;
    }
    static const std::pair<const char*, int> kIcons[] = {
        {"inbox", FOLDER_MAIL_INBOX}, {"sent", FOLDER_SEND},    {"drafts", FOLDER_DRAFTS},
        {"deleted", FOLDER_DELETE},   {"junk", FOLDER_MAIL_PROHIBITED}, {"archive", FOLDER_ARCHIVE},
    };
    std::string name = icon ? icon : "";
    for (const auto& [known, index] : kIcons) {
        if (name == known) {
            return index;
        }
    }
    return FOLDER_FOLDER;
}

const Row* RowOf(const PickerState& state, HTREEITEM item) {
    TVITEMW data = {};
    data.mask = TVIF_PARAM;
    data.hItem = item;
    if (!item || !TreeView_GetItem(state.tree, &data) || static_cast<size_t>(data.lParam) >= state.rows.size()) {
        return nullptr;
    }
    return &state.rows[static_cast<size_t>(data.lParam)];
}

// the folder highlighted when it can be chosen, 0 otherwise
int64_t ChosenFolder(const PickerState& state) {
    const Row* row = RowOf(state, TreeView_GetSelection(state.tree));
    return row && row->choosable ? row->folder : 0;
}

void UpdateButtons(PickerState& state) {
    EnableWindow(state.ok, ChosenFolder(state) != 0);
    // New Folder goes in the folder or account highlighted
    const Row* row = RowOf(state, TreeView_GetSelection(state.tree));
    EnableWindow(state.newFolder, row && (row->kind == PE_TARGET_KIND_ACCOUNT || row->kind == PE_TARGET_KIND_FOLDER));
}

// the tree again from the core's rows for what is typed in Find; the folder highlighted before stays highlighted when
// it is still there, otherwise the first one that can be chosen while something is typed
void Fill(PickerState& state) {
    std::string filter = core::Narrow(GetWindowString(state.filter));
    core::TargetList targets(pe_move_targets(state.pick->core, state.pick->current, filter.c_str()));
    state.rows.clear();
    SendMessageW(state.tree, WM_SETREDRAW, FALSE, 0);
    TreeView_DeleteAllItems(state.tree);
    HTREEITEM toSelect = nullptr, firstChoosable = nullptr, heading = nullptr;
    // the last item at each depth of the account being filled, the parent of the next deeper one
    std::vector<HTREEITEM> parents;
    for (size_t i = 0; i < pe_target_list_count(targets.get()); i++) {
        const PeTarget* target = pe_target_list_get(targets.get(), i);
        state.rows.push_back({target->kind, target->account, target->folder, target->choosable});
        HTREEITEM parent = TVI_ROOT;
        if (target->kind == PE_TARGET_KIND_RECENT && heading) {
            parent = heading;
        } else if (target->kind == PE_TARGET_KIND_FOLDER && !parents.empty()) {
            parent = parents[std::min<size_t>(std::max<uint32_t>(target->depth, 1), parents.size()) - 1];
        }
        bool bold = target->kind == PE_TARGET_KIND_HEADING;
        HTREEITEM item = InsertItem(state.tree, parent, Text(target->label), static_cast<LPARAM>(i), bold,
                                    IconOf(target->kind, target->icon));
        if (target->kind == PE_TARGET_KIND_HEADING) {
            heading = item;
        } else if (target->kind == PE_TARGET_KIND_ACCOUNT) {
            parents.assign(1, item);
        } else if (target->kind == PE_TARGET_KIND_FOLDER && !parents.empty()) {
            parents.resize(std::min<size_t>(std::max<uint32_t>(target->depth, 1), parents.size()));
            parents.push_back(item);
        }
        bool firstRecent = !state.filled && target->kind == PE_TARGET_KIND_RECENT && !toSelect;
        if (target->choosable && !toSelect && (target->folder == state.highlighted || firstRecent)) {
            toSelect = item;
        }
        if (target->choosable && !firstChoosable) {
            firstChoosable = item;
        }
    }
    // every level open, so a folder is never hidden in a collapsed one
    for (HTREEITEM item = TreeView_GetRoot(state.tree); item; item = TreeView_GetNextItem(state.tree, item, TVGN_NEXTVISIBLE)) {
        TreeView_Expand(state.tree, item, TVE_EXPAND);
    }
    if (!toSelect && !filter.empty()) {
        toSelect = firstChoosable;
    }
    state.filled = true;
    SendMessageW(state.tree, WM_SETREDRAW, TRUE, 0);
    TreeView_SelectItem(state.tree, toSelect);
    TreeView_EnsureVisible(state.tree, toSelect ? toSelect : TreeView_GetRoot(state.tree));
    UpdateButtons(state);
}

void Layout(PickerState& state) {
    RECT client;
    GetClientRect(state.dialog, &client);
    int pad = Scale(10);
    int row = Scale(22);
    int buttonHeight = Scale(25);
    int width = client.right - 2 * pad;
    int top = pad;
    MoveWindow(state.prompt, pad, top, width, Scale(18), TRUE);
    top += Scale(22);
    int labelWidth = TextWidth(state.findLabel, nullptr) + Scale(6);
    MoveWindow(state.findLabel, pad, top + Scale(3), labelWidth, row - Scale(3), TRUE);
    MoveWindow(state.filter, pad + labelWidth, top, width - labelWidth, row, TRUE);
    top += row + Scale(6);
    int buttonTop = client.bottom - pad - buttonHeight;
    MoveWindow(state.tree, pad, top, width, buttonTop - Scale(10) - top, TRUE);
    // the buttons as wide as their words need, at least the usual width
    auto widthOf = [](HWND button) { return ButtonWidth({GetWindowString(button)}); };
    int cancelWidth = widthOf(state.cancel), okWidth = widthOf(state.ok), newWidth = widthOf(state.newFolder);
    MoveWindow(state.cancel, client.right - pad - cancelWidth, buttonTop, cancelWidth, buttonHeight, TRUE);
    MoveWindow(state.ok, client.right - pad - cancelWidth - Scale(6) - okWidth, buttonTop, okWidth, buttonHeight, TRUE);
    MoveWindow(state.newFolder, pad, buttonTop, newWidth, buttonHeight, TRUE);
}

void Accept(PickerState& state) {
    if (int64_t folder = ChosenFolder(state)) {
        state.chosen = folder;
        state.done = true;
    }
}

// typing in the tree goes to Find, as the tree has no search of its own worth having here; Enter chooses
LRESULT CALLBACK TreeKeysProc(HWND hwnd, UINT message, WPARAM wParam, LPARAM lParam, UINT_PTR, DWORD_PTR data) {
    auto* state = reinterpret_cast<PickerState*>(data);
    if (message == WM_CHAR && wParam >= L' ' && wParam != 0x7F && state) {
        SetFocus(state->filter);
        SendMessageW(state->filter, WM_CHAR, wParam, lParam);
        return 0;
    }
    if (message == WM_KEYDOWN && wParam == VK_RETURN && state) {
        Accept(*state);
        return 0;
    }
    return DefSubclassProc(hwnd, message, wParam, lParam);
}

// Down in Find goes on to the tree
LRESULT CALLBACK FilterKeysProc(HWND hwnd, UINT message, WPARAM wParam, LPARAM lParam, UINT_PTR, DWORD_PTR data) {
    auto* state = reinterpret_cast<PickerState*>(data);
    if (message == WM_KEYDOWN && wParam == VK_DOWN && state) {
        SetFocus(state->tree);
        return 0;
    }
    return DefSubclassProc(hwnd, message, wParam, lParam);
}

LRESULT CALLBACK PickerProc(HWND hwnd, UINT message, WPARAM wParam, LPARAM lParam) {
    auto* state = reinterpret_cast<PickerState*>(GetWindowLongPtrW(hwnd, GWLP_USERDATA));
    if (!state) {
        return DefWindowProcW(hwnd, message, wParam, lParam);
    }
    switch (message) {
    case WM_COMMAND:
        switch (LOWORD(wParam)) {
        case IDOK:
            Accept(*state);
            return 0;
        case IDCANCEL:
            state->done = true;
            return 0;
        case IDC_PICKER_FILTER:
            if (HIWORD(wParam) == EN_CHANGE) {
                Fill(*state);
            }
            return 0;
        case IDC_PICKER_NEW:
            if (const Row* row = RowOf(*state, TreeView_GetSelection(state->tree)); row && state->pick->newFolder) {
                state->pick->newFolder(hwnd, row->account, row->kind == PE_TARGET_KIND_FOLDER ? row->folder : 0);
            }
            return 0;
        }
        break;
    case WM_NOTIFY: {
        auto* header = reinterpret_cast<NMHDR*>(lParam);
        if (header->hwndFrom != state->tree) {
            break;
        }
        if (header->code == TVN_SELCHANGEDW) {
            const Row* row = RowOf(*state, reinterpret_cast<NMTREEVIEWW*>(lParam)->itemNew.hItem);
            state->highlighted = row ? row->folder : 0;
            UpdateButtons(*state);
        } else if (header->code == NM_DBLCLK && ChosenFolder(*state)) {
            Accept(*state);
            return TRUE;
        } else if (header->code == NM_CUSTOMDRAW) {
            auto* draw = reinterpret_cast<NMTVCUSTOMDRAW*>(lParam);
            if (draw->nmcd.dwDrawStage == CDDS_PREPAINT) {
                return CDRF_NOTIFYITEMDRAW;
            }
            if (draw->nmcd.dwDrawStage == CDDS_ITEMPREPAINT) {
                auto index = static_cast<size_t>(draw->nmcd.lItemlParam);
                // a folder that can not be chosen (the one they are in, one that holds no messages) in grey
                if (index < state->rows.size() && state->rows[index].kind == PE_TARGET_KIND_FOLDER &&
                    !state->rows[index].choosable && !(draw->nmcd.uItemState & CDIS_SELECTED)) {
                    draw->clrText = GetSysColor(COLOR_GRAYTEXT);
                }
                return CDRF_DODEFAULT;
            }
        }
        break;
    }
    case WM_SIZE:
        Layout(*state);
        return 0;
    case WM_GETMINMAXINFO: {
        auto* limits = reinterpret_cast<MINMAXINFO*>(lParam);
        limits->ptMinTrackSize = {Scale(340), Scale(320)};
        return 0;
    }
    case WM_CTLCOLORSTATIC:
        return ButtonFaceColor(reinterpret_cast<HDC>(wParam));
    case WM_CLOSE:
        state->done = true;
        return 0;
    }
    return DefWindowProcW(hwnd, message, wParam, lParam);
}

}  // namespace

int64_t PickFolder(HWND owner, FolderPick& pick) {
    RegisterDialogClass(kPickerClass, PickerProc);
    HWND dialog = CreateModalWindow(owner, kPickerClass, pick.title.c_str(), Scale(400), Scale(440));
    // a window for long folder lists: it can be made larger
    SetWindowLongPtrW(dialog, GWL_STYLE, GetWindowLongPtrW(dialog, GWL_STYLE) | WS_THICKFRAME);
    SetWindowPos(dialog, nullptr, 0, 0, 0, 0, SWP_NOMOVE | SWP_NOSIZE | SWP_NOZORDER | SWP_FRAMECHANGED);
    PickerState state;
    state.pick = &pick;
    state.dialog = dialog;
    state.prompt = CreateChild(dialog, L"STATIC", pick.prompt.c_str(), SS_LEFT | SS_NOPREFIX, 0, {});
    state.findLabel = CreateChild(dialog, L"STATIC", core::T(PE_TEXT_WIN_FIND_LABEL).c_str(), SS_LEFT, 0, {});
    state.filter = CreateChild(dialog, L"EDIT", L"", WS_TABSTOP | ES_AUTOHSCROLL, IDC_PICKER_FILTER, {}, WS_EX_CLIENTEDGE);
    state.tree = CreateChild(dialog, WC_TREEVIEWW, nullptr,
                             WS_TABSTOP | TVS_HASLINES | TVS_HASBUTTONS | TVS_LINESATROOT | TVS_SHOWSELALWAYS, IDC_PICKER_TREE, {},
                             WS_EX_CLIENTEDGE);
    TreeView_SetImageList(state.tree, IconList(IconSet::Folders), TVSIL_NORMAL);
    state.newFolder = CreateChild(dialog, L"BUTTON", core::T(PE_TEXT_CMD_NEW_FOLDER).c_str(), WS_TABSTOP, IDC_PICKER_NEW, {});
    // Go to Folder makes none
    if (!pick.newFolder) {
        ShowWindow(state.newFolder, SW_HIDE);
    }
    state.ok = CreateChild(dialog, L"BUTTON", pick.verb.c_str(), WS_TABSTOP | BS_DEFPUSHBUTTON, IDOK, {});
    state.cancel = CreateChild(dialog, L"BUTTON", core::T(PE_TEXT_UI_CANCEL).c_str(), WS_TABSTOP, IDCANCEL, {});
    SetWindowSubclass(state.tree, TreeKeysProc, 0, reinterpret_cast<DWORD_PTR>(&state));
    SetWindowSubclass(state.filter, FilterKeysProc, 0, reinterpret_cast<DWORD_PTR>(&state));
    SetWindowLongPtrW(dialog, GWLP_USERDATA, reinterpret_cast<LONG_PTR>(&state));
    Layout(state);
    Fill(state);
    g_open = &state;
    RunModal(dialog, state.tree, state.done);
    g_open = nullptr;
    return state.chosen;
}

void RefreshFolderPick(int64_t highlight) {
    if (!g_open) {
        return;
    }
    if (highlight) {
        g_open->highlighted = highlight;
    }
    Fill(*g_open);
    if (highlight) {
        SetFocus(g_open->tree);
    }
}
