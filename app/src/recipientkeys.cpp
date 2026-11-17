// Recipients' Keys: the window over a compose window with Encrypt on that shows each recipient and the key their copy is
// encrypted to, with Find Key, Remove from Message, the decision about a key that waits, and Send Without Encryption.
// Send opens it when someone has no key. The recipients, their keys, the words and what may be done are the core's
// (pe_compose_security); this file shows them and hands the clicks to the compose window.
#include "app.h"
#include "icons.h"

#include <algorithm>

namespace {

const wchar_t* kRecipientKeysClass = L"InboxClassicRecipientKeys";

// to an open Recipients' Keys: read the recipients again
constexpr UINT WM_REFRESH_KEYS = WM_APP + 30;

// the security strips in the order of the list's pictures: four pictures (SecureIcon) each
const IconSet kPictureSets[] = {IconSet::SecureVerified, IconSet::SecureGood, IconSet::SecureWarning, IconSet::SecureNeutral};
constexpr int kPicturesPerSet = 4;

struct RecipientKeysState {
    PeCore* core = nullptr;
    const RecipientKeysCalls* calls = nullptr;
    HWND list = nullptr;
    HIMAGELIST pictures = nullptr;
    // the address of each row
    std::vector<std::string> addresses;
    // the rows being made again: their selection changes are not the user's
    bool filling = false;
    bool done = false;
    RecipientKeysAnswer answer = RecipientKeysAnswer::Cancel;
};

// the pictures of the four tones' strips in one list, for the rows: a strip's picture is drawn over its tone's fill,
// which is light enough to sit on the list's white
HIMAGELIST MakePictures() {
    int cx = 0, cy = 0;
    ImageList_GetIconSize(IconList(IconSet::SecureNeutral), &cx, &cy);
    HIMAGELIST pictures = ImageList_Create(cx, cy, ILC_COLOR24 | ILC_MASK, kPicturesPerSet * 4, 0);
    for (IconSet set : kPictureSets) {
        for (int i = 0; i < kPicturesPerSet; i++) {
            HICON icon = ImageList_GetIcon(IconList(set), i, ILD_TRANSPARENT);
            ImageList_ReplaceIcon(pictures, -1, icon);
            DestroyIcon(icon);
        }
    }
    return pictures;
}

int PictureOf(const PeComposeRecipient& recipient) {
    IconSet set = RecipientKeySet(recipient);
    int index = static_cast<int>(std::find(std::begin(kPictureSets), std::end(kPictureSets), set) - std::begin(kPictureSets));
    return index * kPicturesPerSet + RecipientKeyPicture(recipient);
}

HWND Item(HWND dialog, int id) {
    return GetDlgItem(dialog, id);
}

// the selected row's recipient as the compose window has it now, found by its address (the rows are read again a
// moment after it changed)
const PeComposeRecipient* Selected(const RecipientKeysState& state) {
    int row = ListView_GetNextItem(state.list, -1, LVNI_SELECTED);
    const PeComposeSecurity* security = state.calls->security();
    if (row < 0 || static_cast<size_t>(row) >= state.addresses.size() || !security) {
        return nullptr;
    }
    for (size_t i = 0; i < pe_compose_security_count(security); i++) {
        const PeComposeRecipient* recipient = pe_compose_security_recipient(security, i);
        if (recipient->address == state.addresses[static_cast<size_t>(row)]) {
            return recipient;
        }
    }
    return nullptr;
}

constexpr int kWidth = 640;

int ListHeight(HWND list) {
    int rows = std::clamp(ListView_GetItemCount(list), 3, 8);
    RECT row = {};
    int rowHeight = ListView_GetItemCount(list) > 0 && ListView_GetItemRect(list, 0, &row, LVIR_BOUNDS) ? static_cast<int>(row.bottom - row.top)
                                                                                                       : static_cast<int>(MeasureText(L"Ag").cy) + Scale(4);
    RECT header = {};
    GetWindowRect(ListView_GetHeader(list), &header);
    // the header has its height once the list was first sized
    int headerHeight = header.bottom > header.top ? static_cast<int>(header.bottom - header.top) : rowHeight + Scale(4);
    return rows * rowHeight + headerHeight + 2 * GetSystemMetrics(SM_CYEDGE) + Scale(2);
}

// the controls placed top down for what they say now, the window as tall as they need
void Layout(HWND dialog, RecipientKeysState& state) {
    int width = Scale(kWidth), pad = Scale(10), button = Scale(25), gap = Scale(8);
    int y = pad;
    HWND intro = Item(dialog, IDC_RKEYS_INTRO);
    int introHeight = static_cast<int>(MeasureText(GetWindowString(intro), width - 2 * pad).cy);
    MoveWindow(intro, pad, y, width - 2 * pad, introHeight, TRUE);
    y += introHeight + gap;
    // as tall as its rows, three to eight of them, then it scrolls
    int listHeight = ListHeight(state.list);
    MoveWindow(state.list, pad, y, width - 2 * pad, listHeight, TRUE);
    y += listHeight + Scale(6);
    // the selected recipient's buttons under the list, at its left
    int x = pad;
    for (int id : {IDC_RKEYS_FIND, IDC_RKEYS_REMOVE}) {
        int w = ButtonWidth({GetWindowString(Item(dialog, id))});
        MoveWindow(Item(dialog, id), x, y, w, button, TRUE);
        x += w + Scale(6);
    }
    y += button + gap;
    // a key that waits for a decision: the warning sign, the sentence and its two answers
    HWND pending = Item(dialog, IDC_RKEYS_PENDING);
    HWND sign = GetWindow(pending, GW_HWNDPREV);
    bool waiting = IsWindowVisible(pending) != FALSE;
    if (waiting) {
        int icon = GetSystemMetrics(SM_CXSMICON), textLeft = pad + icon + Scale(6);
        int height = std::max(icon, static_cast<int>(MeasureText(GetWindowString(pending), width - pad - textLeft).cy));
        MoveWindow(sign, pad, y, icon, icon, TRUE);
        MoveWindow(pending, textLeft, y, width - pad - textLeft, height, TRUE);
        y += height + Scale(6);
        x = textLeft;
        for (int id : {IDC_RKEYS_USE_NEW, IDC_RKEYS_KEEP}) {
            int w = ButtonWidth({GetWindowString(Item(dialog, id))});
            MoveWindow(Item(dialog, id), x, y, w, button, TRUE);
            x += w + Scale(6);
        }
        y += button + gap;
    }
    // why it can not go unencrypted, over the button that would
    HWND note = Item(dialog, IDC_RKEYS_UNENCRYPTED_NOTE);
    if (IsWindowVisible(note)) {
        int height = static_cast<int>(MeasureText(GetWindowString(note), width - 2 * pad).cy);
        MoveWindow(note, pad, y, width - 2 * pad, height, TRUE);
        y += height + Scale(6);
    }
    // Send Without Encryption at the left, apart from Send and Cancel at the right
    int unencrypted = ButtonWidth({GetWindowString(Item(dialog, IDC_RKEYS_SEND_UNENCRYPTED))});
    MoveWindow(Item(dialog, IDC_RKEYS_SEND_UNENCRYPTED), pad, y, unencrypted, button, TRUE);
    int each = ButtonWidth({GetWindowString(Item(dialog, IDOK)), GetWindowString(Item(dialog, IDCANCEL))});
    MoveWindow(Item(dialog, IDCANCEL), width - pad - each, y, each, button, TRUE);
    MoveWindow(Item(dialog, IDOK), width - pad - 2 * each - Scale(6), y, each, button, TRUE);
    y += button + pad;
    // the window as tall as that
    RECT frame = {0, 0, width, y};
    AdjustWindowRectEx(&frame, static_cast<DWORD>(GetWindowLongPtrW(dialog, GWL_STYLE)), FALSE,
                       static_cast<DWORD>(GetWindowLongPtrW(dialog, GWL_EXSTYLE)));
    SetWindowPos(dialog, nullptr, 0, 0, frame.right - frame.left, frame.bottom - frame.top, SWP_NOMOVE | SWP_NOZORDER | SWP_NOACTIVATE);
    InvalidateRect(dialog, nullptr, TRUE);
}

void ShowText(HWND control, const std::wstring& text) {
    if (GetWindowString(control) != text) {
        SetWindowTextW(control, text.c_str());
    }
}

// the selected recipient's buttons, and the key that waits for their decision
void ShowSelected(HWND dialog, RecipientKeysState& state) {
    const PeComposeRecipient* recipient = Selected(state);
    EnableWindow(Item(dialog, IDC_RKEYS_FIND), recipient && recipient->can_find);
    EnableWindow(Item(dialog, IDC_RKEYS_REMOVE), recipient != nullptr);
    bool waiting = recipient && recipient->pending;
    HWND pending = Item(dialog, IDC_RKEYS_PENDING);
    ShowText(pending, waiting ? Text(recipient->pending) : L"");
    for (HWND control : {pending, GetWindow(pending, GW_HWNDPREV), Item(dialog, IDC_RKEYS_USE_NEW), Item(dialog, IDC_RKEYS_KEEP)}) {
        ShowWindow(control, waiting ? SW_SHOW : SW_HIDE);
    }
    Layout(dialog, state);
}

// the recipients read again, the selection kept on the same address (or the first without a key)
void Fill(HWND dialog, RecipientKeysState& state) {
    int selectedRow = ListView_GetNextItem(state.list, -1, LVNI_SELECTED);
    std::string selected = selectedRow >= 0 && static_cast<size_t>(selectedRow) < state.addresses.size() ? state.addresses[static_cast<size_t>(selectedRow)] : "";
    selectedRow = std::max(0, selectedRow);
    const PeComposeSecurity* security = state.calls->security();
    const PeComposeSecurityInfo* info = security ? pe_compose_security_info(security) : nullptr;
    if (!info) {
        return;
    }
    ShowText(Item(dialog, IDC_RKEYS_INTRO), Text(info->keys_intro));
    SendMessageW(state.list, WM_SETREDRAW, FALSE, 0);
    state.filling = true;
    ListView_DeleteAllItems(state.list);
    state.addresses.clear();
    size_t count = pe_compose_security_count(security);
    int select = -1, firstMissing = -1;
    for (size_t i = 0; i < count; i++) {
        const PeComposeRecipient* recipient = pe_compose_security_recipient(security, i);
        int row = static_cast<int>(i);
        std::wstring label = Text(recipient->label);
        std::wstring address = Text(recipient->address);
        // the name with the address after it, as an address is written
        std::wstring shown = label == address ? address : label + L" <" + address + L">";
        LVITEMW item = {};
        item.mask = LVIF_TEXT | LVIF_IMAGE;
        item.iItem = row;
        item.pszText = shown.data();
        item.iImage = PictureOf(*recipient);
        ListView_InsertItem(state.list, &item);
        SetCell(state.list, row, 1, Text(recipient->text));
        state.addresses.push_back(recipient->address);
        if (recipient->address == selected) {
            select = row;
        }
        if (firstMissing < 0 && !recipient->has_key) {
            firstMissing = row;
        }
    }
    if (select < 0) {
        select = selected.empty() && firstMissing >= 0 ? firstMissing : selectedRow;
    }
    SelectRow(state.list, select);
    state.filling = false;
    SendMessageW(state.list, WM_SETREDRAW, TRUE, 0);
    // Send once everyone has a key; the core says whether Send or Cancel is the default, never Send Without Encryption
    EnableWindow(Item(dialog, IDOK), info->can_send);
    HWND unencrypted = Item(dialog, IDC_RKEYS_SEND_UNENCRYPTED);
    EnableWindow(unencrypted, info->can_send_unencrypted && count > 0);
    std::wstring why = info->can_send_unencrypted ? L"" : Text(info->unencrypted_text);
    HWND note = Item(dialog, IDC_RKEYS_UNENCRYPTED_NOTE);
    ShowText(note, why);
    ShowWindow(note, why.empty() ? SW_HIDE : SW_SHOW);
    SetAccessibleDescription(unencrypted, why);
    HWND focus = GetFocus();
    SetDefaultButton(dialog, info->send_default ? IDOK : IDCANCEL);
    // the focus off a button that was turned off, onto the list
    if (focus && !IsWindowEnabled(focus)) {
        SetFocus(state.list);
    }
    ShowSelected(dialog, state);
}

void OnCommand(HWND dialog, RecipientKeysState& state, WORD id) {
    const PeComposeRecipient* recipient = Selected(state);
    // the address outlives the rows, which a refill replaces
    std::string address = recipient ? recipient->address : "";
    switch (id) {
    case IDC_RKEYS_FIND:
        if (!address.empty()) {
            state.calls->findKey(address);
        }
        return;
    case IDC_RKEYS_REMOVE:
        if (!address.empty()) {
            state.calls->remove(address);
        }
        return;
    case IDC_RKEYS_USE_NEW:
    case IDC_RKEYS_KEEP:
        if (!address.empty()) {
            pe_pgp_decide(state.core, address.c_str(), id == IDC_RKEYS_USE_NEW);
            state.calls->changed();
        }
        return;
    case IDC_RKEYS_SEND_UNENCRYPTED:
        if (IsWindowEnabled(Item(dialog, id))) {
            state.answer = RecipientKeysAnswer::SendUnencrypted;
            state.done = true;
        }
        return;
    case IDOK:
        // Enter takes the default, which is Send only while it can go
        if (IsWindowEnabled(Item(dialog, IDOK))) {
            state.answer = RecipientKeysAnswer::Send;
            state.done = true;
        }
        return;
    case IDCANCEL:
        state.done = true;
        return;
    }
}

LRESULT CALLBACK RecipientKeysProc(HWND hwnd, UINT message, WPARAM wParam, LPARAM lParam) {
    auto* state = reinterpret_cast<RecipientKeysState*>(GetWindowLongPtrW(hwnd, GWLP_USERDATA));
    if (!state) {
        return DefWindowProcW(hwnd, message, wParam, lParam);
    }
    switch (message) {
    case WM_COMMAND:
        OnCommand(hwnd, *state, LOWORD(wParam));
        return 0;
    case WM_NOTIFY: {
        const auto* header = reinterpret_cast<const NMHDR*>(lParam);
        if (header->hwndFrom == state->list && header->code == LVN_ITEMCHANGED && !state->filling &&
            (reinterpret_cast<const NMLISTVIEW*>(lParam)->uChanged & LVIF_STATE)) {
            ShowSelected(hwnd, *state);
        }
        return 0;
    }
    case WM_REFRESH_KEYS:
        Fill(hwnd, *state);
        return 0;
    case WM_CLOSE:
        state->done = true;
        return 0;
    case WM_CTLCOLORSTATIC:
        return ButtonFaceColor(reinterpret_cast<HDC>(wParam));
    }
    return DefWindowProcW(hwnd, message, wParam, lParam);
}

}  // namespace

RecipientKeysAnswer RecipientKeysDialog(HWND owner, PeCore* core, const RecipientKeysCalls& calls, HWND& open) {
    RegisterDialogClass(kRecipientKeysClass, RecipientKeysProc);
    HelpScope help("recipient-keys");
    RecipientKeysState state;
    state.core = core;
    state.calls = &calls;
    int width = Scale(kWidth);
    HWND dialog = CreateModalWindow(owner, kRecipientKeysClass, core::Plain(PE_TEXT_UI_RECIPIENT_KEYS_TITLE).c_str(), width, Scale(320));
    // made in the order Tab goes: the list, its buttons, the decision, then the buttons at the bottom
    CreateChild(dialog, L"STATIC", L"", SS_LEFT | SS_NOPREFIX, IDC_RKEYS_INTRO, {});
    state.list = CreateReportList(dialog, IDC_RKEYS_LIST, {});
    state.pictures = MakePictures();
    ListView_SetImageList(state.list, state.pictures, LVSIL_SMALL);
    // a key's words cut off in their column show whole in a tooltip
    ListView_SetExtendedListViewStyle(state.list, LVS_EX_FULLROWSELECT | LVS_EX_INFOTIP);
    int listWidth = width - 2 * Scale(10) - GetSystemMetrics(SM_CXVSCROLL) - Scale(4);
    LVCOLUMNW column = {};
    column.mask = LVCF_TEXT | LVCF_WIDTH;
    std::wstring recipientColumn = core::Plain(PE_TEXT_UI_RECIPIENT_COL_RECIPIENT), keyColumn = core::Plain(PE_TEXT_UI_RECIPIENT_COL_KEY);
    column.pszText = recipientColumn.data();
    column.cx = listWidth * 40 / 100;
    ListView_InsertColumn(state.list, 0, &column);
    column.pszText = keyColumn.data();
    column.cx = listWidth - listWidth * 40 / 100;
    ListView_InsertColumn(state.list, 1, &column);
    CreateChild(dialog, L"BUTTON", core::T(PE_TEXT_UI_RECIPIENT_FIND_KEY).c_str(), WS_TABSTOP | BS_PUSHBUTTON, IDC_RKEYS_FIND, {});
    CreateChild(dialog, L"BUTTON", core::T(PE_TEXT_UI_RECIPIENT_REMOVE).c_str(), WS_TABSTOP | BS_PUSHBUTTON, IDC_RKEYS_REMOVE, {});
    int icon = GetSystemMetrics(SM_CXSMICON);
    // a system icon is shared: not destroyed
    auto warning = static_cast<HICON>(LoadImageW(nullptr, IDI_WARNING, IMAGE_ICON, icon, icon, LR_SHARED));
    HWND sign = CreateChild(dialog, L"STATIC", nullptr, SS_ICON | SS_REALSIZECONTROL, 0, {});
    SendMessageW(sign, STM_SETICON, reinterpret_cast<WPARAM>(warning), 0);
    CreateChild(dialog, L"STATIC", L"", SS_LEFT | SS_NOPREFIX, IDC_RKEYS_PENDING, {});
    CreateChild(dialog, L"BUTTON", core::T(PE_TEXT_UI_CONTACT_KEY_USE_NEW).c_str(), WS_TABSTOP | BS_PUSHBUTTON, IDC_RKEYS_USE_NEW, {});
    CreateChild(dialog, L"BUTTON", core::T(PE_TEXT_UI_CONTACT_KEY_KEEP).c_str(), WS_TABSTOP | BS_PUSHBUTTON, IDC_RKEYS_KEEP, {});
    CreateChild(dialog, L"STATIC", L"", SS_LEFT | SS_NOPREFIX, IDC_RKEYS_UNENCRYPTED_NOTE, {});
    CreateChild(dialog, L"BUTTON", core::T(PE_TEXT_UI_SEND_UNENCRYPTED).c_str(), WS_TABSTOP | BS_PUSHBUTTON, IDC_RKEYS_SEND_UNENCRYPTED, {});
    CreateChild(dialog, L"BUTTON", core::T(PE_TEXT_UI_TB_SEND).c_str(), WS_TABSTOP | BS_PUSHBUTTON, IDOK, {});
    CreateChild(dialog, L"BUTTON", core::T(PE_TEXT_UI_CANCEL).c_str(), WS_TABSTOP | BS_DEFPUSHBUTTON, IDCANCEL, {});
    SetWindowLongPtrW(dialog, GWLP_USERDATA, reinterpret_cast<LONG_PTR>(&state));
    Fill(dialog, state);
    open = dialog;
    RunModal(dialog, state.list, state.done);
    open = nullptr;
    // the pictures went with the list
    return state.answer;
}

void RefreshRecipientKeys(HWND dialog) {
    if (dialog && IsWindow(dialog)) {
        PostMessageW(dialog, WM_REFRESH_KEYS, 0, 0);
    }
}
