// The Move and Copy window: the folders of every account in a tree, a filter box over it, the folders used last on
// top, New Folder, and a button that says what it does. The core gives the words and the folders; this shows them.
#include "app.h"

#include <algorithm>
#include <cwctype>

#include "icons.h"

namespace {

const wchar_t* kPickerClass = L"InboxClassicFolderPicker";

constexpr int IDC_PICKER_FILTER = 101;
constexpr int IDC_PICKER_TREE = 102;
constexpr int IDC_PICKER_NEW = 103;
// the Recent group's own row, which is no folder
constexpr LPARAM kRecentRow = 0;
// an image index past the folder strip: the Recent row has no icon
constexpr int kNoIcon = 1000;

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
    // what each folder is: the choosable ones, those shown grey
    std::unordered_map<int64_t, const PickerFolder*> folders;
};

// the one open picker, for RefreshFolderPick
PickerState* g_open = nullptr;

std::wstring Lower(std::wstring text) {
    std::transform(text.begin(), text.end(), text.begin(), [](wchar_t c) { return static_cast<wchar_t>(std::towlower(c)); });
    return text;
}

HTREEITEM AddItem(HWND tree, HTREEITEM parent, const std::wstring& text, LPARAM data, int icon, bool bold = false) {
    TVINSERTSTRUCTW insert = {};
    insert.hParent = parent;
    insert.hInsertAfter = TVI_LAST;
    insert.item.mask = TVIF_TEXT | TVIF_PARAM | TVIF_IMAGE | TVIF_SELECTEDIMAGE | TVIF_STATE;
    insert.item.pszText = const_cast<wchar_t*>(text.c_str());
    insert.item.lParam = data;
    insert.item.iImage = icon;
    insert.item.iSelectedImage = icon;
    insert.item.stateMask = TVIS_BOLD;
    insert.item.state = bold ? TVIS_BOLD : 0;
    return TreeView_InsertItem(tree, &insert);
}

LPARAM ItemData(HWND tree, HTREEITEM item) {
    TVITEMW data = {};
    data.mask = TVIF_PARAM;
    data.hItem = item;
    return item && TreeView_GetItem(tree, &data) ? data.lParam : kRecentRow;
}

bool Choosable(const PickerState& state, LPARAM data) {
    auto folder = state.folders.find(static_cast<int64_t>(data));
    return data > 0 && folder != state.folders.end() && folder->second->choosable;
}

// the folder highlighted when it can be chosen, 0 otherwise
int64_t ChosenFolder(const PickerState& state) {
    LPARAM data = ItemData(state.tree, TreeView_GetSelection(state.tree));
    return Choosable(state, data) ? static_cast<int64_t>(data) : 0;
}

void UpdateButtons(PickerState& state) {
    EnableWindow(state.ok, ChosenFolder(state) != 0);
    // New Folder goes in the folder or account highlighted
    EnableWindow(state.newFolder, ItemData(state.tree, TreeView_GetSelection(state.tree)) != kRecentRow);
}

// the tree again, with what matches `filter` (each folder that does, and the folders above it), all of it otherwise;
// the folder highlighted before stays highlighted when it is still there
void Fill(PickerState& state) {
    const FolderPick& pick = *state.pick;
    std::wstring filter = Lower(GetWindowString(state.filter));
    state.folders.clear();
    for (const auto& account : pick.accounts) {
        for (const auto& folder : account.folders) {
            state.folders[folder.id] = &folder;
        }
    }
    auto matches = [&](const std::wstring& name) { return filter.empty() || Lower(name).find(filter) != std::wstring::npos; };
    SendMessageW(state.tree, WM_SETREDRAW, FALSE, 0);
    TreeView_DeleteAllItems(state.tree);
    HTREEITEM toSelect = nullptr;
    std::vector<HTREEITEM> parents;
    auto remember = [&](HTREEITEM item, int64_t id) {
        if (id == state.highlighted && !toSelect) {
            toSelect = item;
        }
    };
    // the folders used last, on top
    std::vector<const PickerRecent*> recent;
    for (const auto& r : pick.recent) {
        if (matches(r.label)) {
            recent.push_back(&r);
        }
    }
    if (!recent.empty()) {
        HTREEITEM group = AddItem(state.tree, TVI_ROOT, L"Recent", kRecentRow, kNoIcon, true);
        for (const auto* r : recent) {
            auto folder = state.folders.find(r->folder);
            int icon = folder != state.folders.end() ? folder->second->icon : FOLDER_FOLDER;
            remember(AddItem(state.tree, group, r->label, static_cast<LPARAM>(r->folder), icon), r->folder);
        }
        TreeView_Expand(state.tree, group, TVE_EXPAND);
    }
    for (const auto& account : pick.accounts) {
        // what shows: the matching folders and every folder above one
        std::vector<bool> shown(account.folders.size(), filter.empty());
        if (!filter.empty()) {
            for (size_t i = 0; i < account.folders.size(); i++) {
                if (!matches(account.folders[i].name)) {
                    continue;
                }
                shown[i] = true;
                // the folders above it: the last one at each smaller depth before it
                size_t depth = account.folders[i].depth;
                for (size_t j = i; j-- > 0 && depth > 0;) {
                    if (account.folders[j].depth < depth) {
                        shown[j] = true;
                        depth = account.folders[j].depth;
                    }
                }
            }
            if (std::find(shown.begin(), shown.end(), true) == shown.end()) {
                continue;
            }
        }
        HTREEITEM root = AddItem(state.tree, TVI_ROOT, account.title, static_cast<LPARAM>(-account.id), FOLDER_MAILBOX);
        parents.assign(1, root);
        for (size_t i = 0; i < account.folders.size(); i++) {
            const PickerFolder& folder = account.folders[i];
            size_t depth = std::min(folder.depth, parents.size() - 1);
            parents.resize(depth + 1);
            if (!shown[i]) {
                // a hidden folder's folders are hidden with it; keep the depth for them
                parents.push_back(parents.back());
                continue;
            }
            std::wstring label = folder.current ? folder.name + L" (current)" : folder.name;
            HTREEITEM item = AddItem(state.tree, parents[depth], label, static_cast<LPARAM>(folder.id), folder.icon);
            remember(item, folder.id);
            parents.push_back(item);
        }
        // every level open, so a folder is never hidden in a collapsed one
        for (HTREEITEM item = root; item; item = TreeView_GetNextItem(state.tree, item, TVGN_NEXTVISIBLE)) {
            TreeView_Expand(state.tree, item, TVE_EXPAND);
        }
    }
    // nothing highlighted before, or it is filtered out: the first folder that can be chosen
    if (!toSelect) {
        for (HTREEITEM item = TreeView_GetRoot(state.tree); item; item = TreeView_GetNextItem(state.tree, item, TVGN_NEXTVISIBLE)) {
            if (!filter.empty() && Choosable(state, ItemData(state.tree, item))) {
                toSelect = item;
                break;
            }
        }
    }
    SendMessageW(state.tree, WM_SETREDRAW, TRUE, 0);
    TreeView_SelectItem(state.tree, toSelect);
    if (toSelect) {
        TreeView_EnsureVisible(state.tree, toSelect);
    } else if (HTREEITEM first = TreeView_GetRoot(state.tree)) {
        TreeView_EnsureVisible(state.tree, first);
    }
    UpdateButtons(state);
}

// how wide the words of a control are in the dialog font, its & left out
int TextWidth(HWND control) {
    std::wstring text = GetWindowString(control);
    text.erase(std::remove(text.begin(), text.end(), L'&'), text.end());
    HDC dc = GetDC(control);
    HGDIOBJ old = SelectObject(dc, GetStockObject(DEFAULT_GUI_FONT));
    SIZE size = {};
    GetTextExtentPoint32W(dc, text.c_str(), static_cast<int>(text.size()), &size);
    SelectObject(dc, old);
    ReleaseDC(control, dc);
    return static_cast<int>(size.cx);
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
    int labelWidth = TextWidth(state.findLabel) + Scale(6);
    MoveWindow(state.findLabel, pad, top + Scale(3), labelWidth, row - Scale(3), TRUE);
    MoveWindow(state.filter, pad + labelWidth, top, width - labelWidth, row, TRUE);
    top += row + Scale(6);
    int buttonTop = client.bottom - pad - buttonHeight;
    MoveWindow(state.tree, pad, top, width, buttonTop - Scale(10) - top, TRUE);
    // the buttons as wide as their words need, at least the usual width
    auto widthOf = [](HWND button) { return std::max(Scale(80), TextWidth(button) + Scale(24)); };
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

// typing in the tree goes to the filter, as the tree has no search of its own worth having here
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

// Down in the filter goes on to the tree
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
        case IDC_PICKER_NEW: {
            LPARAM data = ItemData(state->tree, TreeView_GetSelection(state->tree));
            int64_t parent = data > 0 ? static_cast<int64_t>(data) : 0;
            int64_t account = data < 0 ? -static_cast<int64_t>(data) : 0;
            if (parent) {
                auto folder = state->folders.find(parent);
                account = folder != state->folders.end() ? folder->second->account : 0;
            }
            if (account && state->pick->newFolder) {
                state->pick->newFolder(hwnd, account, parent);
            }
            return 0;
        }
        }
        break;
    case WM_NOTIFY: {
        auto* header = reinterpret_cast<NMHDR*>(lParam);
        if (header->hwndFrom != state->tree) {
            break;
        }
        if (header->code == TVN_SELCHANGEDW) {
            state->highlighted = static_cast<int64_t>(reinterpret_cast<NMTREEVIEWW*>(lParam)->itemNew.lParam);
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
                auto data = static_cast<LPARAM>(draw->nmcd.lItemlParam);
                // a folder that can not be chosen (the one they are in, one that holds no messages) in grey
                if (data > 0 && !Choosable(*state, data) && !(draw->nmcd.uItemState & CDIS_SELECTED)) {
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
    state.highlighted = pick.highlight;
    state.prompt = CreateChild(dialog, L"STATIC", pick.prompt.c_str(), SS_LEFT | SS_NOPREFIX, 0, {});
    state.findLabel = CreateChild(dialog, L"STATIC", L"&Find:", SS_LEFT, 0, {});
    state.filter = CreateChild(dialog, L"EDIT", L"", WS_TABSTOP | ES_AUTOHSCROLL, IDC_PICKER_FILTER, {}, WS_EX_CLIENTEDGE);
    state.tree = CreateChild(dialog, WC_TREEVIEWW, nullptr,
                             WS_TABSTOP | TVS_HASLINES | TVS_HASBUTTONS | TVS_LINESATROOT | TVS_SHOWSELALWAYS, IDC_PICKER_TREE, {},
                             WS_EX_CLIENTEDGE);
    TreeView_SetImageList(state.tree, IconList(IconSet::Folders), TVSIL_NORMAL);
    state.newFolder = CreateChild(dialog, L"BUTTON", L"&New Folder...", WS_TABSTOP, IDC_PICKER_NEW, {});
    state.ok = CreateChild(dialog, L"BUTTON", pick.verb.c_str(), WS_TABSTOP | BS_DEFPUSHBUTTON, IDOK, {});
    state.cancel = CreateChild(dialog, L"BUTTON", L"Cancel", WS_TABSTOP, IDCANCEL, {});
    SetWindowSubclass(state.tree, TreeKeysProc, 0, reinterpret_cast<DWORD_PTR>(&state));
    SetWindowSubclass(state.filter, FilterKeysProc, 0, reinterpret_cast<DWORD_PTR>(&state));
    SetWindowLongPtrW(dialog, GWLP_USERDATA, reinterpret_cast<LONG_PTR>(&state));
    Layout(state);
    Fill(state);
    g_open = &state;
    // the tree has the focus, on the folder used last: Enter moves there, typing finds another
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

bool FolderPickOpen() {
    return g_open != nullptr;
}
