// Address completion in the To, Cc and Bcc fields: the address being typed (the text between the commas around the
// cursor) is looked up in the core (the Address Book's people and groups, then those written to and heard from), and
// what it found is listed under the field. The list never
// takes the focus: the keys stay with the field, which moves the choice, takes it or closes the list.
#include "app.h"
#include "core.h"

#include <algorithm>
#include <string>
#include <utility>
#include <vector>

namespace {

// how many people the list shows at most
constexpr size_t kShown = 8;

struct Completion {
    PeCore* core = nullptr;
    HWND edit = nullptr;
    HWND list = nullptr;
    // the rows of the list: what goes in the field, and the address to forget (none for a group of the Address
    // Book, which is listed by its name and puts its members in the field)
    struct Row {
        std::wstring label;
        std::wstring address;
        bool group = false;
    };
    std::vector<Row> rows;
    // a key the list took (Enter, Tab, Esc): its character does not go in the field either
    bool swallow = false;
};

bool IsSeparator(wchar_t c) {
    return c == L',' || c == L';';
}

// the address the cursor is in: from after the comma before it to the comma after it, without the spaces around it
void TokenAt(const std::wstring& text, size_t caret, size_t& start, size_t& end) {
    caret = std::min(caret, text.size());
    start = caret;
    while (start > 0 && !IsSeparator(text[start - 1])) {
        start--;
    }
    while (start < caret && text[start] == L' ') {
        start++;
    }
    end = caret;
    while (end < text.size() && !IsSeparator(text[end])) {
        end++;
    }
}

size_t Caret(HWND edit) {
    DWORD from = 0, to = 0;
    SendMessageW(edit, EM_GETSEL, reinterpret_cast<WPARAM>(&from), reinterpret_cast<LPARAM>(&to));
    return to;
}

void Hide(Completion* state) {
    if (state->list) {
        ShowWindow(state->list, SW_HIDE);
    }
}

bool Shown(const Completion* state) {
    return state->list && IsWindowVisible(state->list);
}

// the person chosen in the list in place of what was typed, a comma after it for the next one
void Take(Completion* state, int index) {
    if (index < 0 || static_cast<size_t>(index) >= state->rows.size()) {
        return;
    }
    const std::wstring& label = state->rows[index].label;
    std::wstring text = GetWindowString(state->edit);
    size_t start = 0, end = 0;
    TokenAt(text, Caret(state->edit), start, end);
    // what follows keeps its comma; at the end a comma and a space wait for the next address
    std::wstring after = text.substr(end);
    std::wstring inserted = label + (after.empty() ? L", " : L"");
    text = text.substr(0, start) + inserted + after;
    SetWindowTextW(state->edit, text.c_str());
    size_t caret = start + inserted.size();
    SendMessageW(state->edit, EM_SETSEL, caret, caret);
    // the field changed as typing changes it
    SendMessageW(GetParent(state->edit), WM_COMMAND, MAKEWPARAM(GetDlgCtrlID(state->edit), EN_CHANGE), reinterpret_cast<LPARAM>(state->edit));
    Hide(state);
}

// the row under the mouse at `point` (lParam of a mouse message), -1 for none
int ItemAt(HWND list, LPARAM point) {
    LRESULT hit = SendMessageW(list, LB_ITEMFROMPOINT, 0, point);
    return HIWORD(hit) ? -1 : static_cast<int>(LOWORD(hit));
}

LRESULT CALLBACK ListProc(HWND hwnd, UINT message, WPARAM wParam, LPARAM lParam, UINT_PTR, DWORD_PTR data) {
    auto* state = reinterpret_cast<Completion*>(data);
    switch (message) {
    case WM_MOUSEACTIVATE:
        // a click on the list leaves the keyboard in the field
        return MA_NOACTIVATE;
    case WM_MOUSEMOVE: {
        int row = ItemAt(hwnd, lParam);
        if (row >= 0 && row != SendMessageW(hwnd, LB_GETCURSEL, 0, 0)) {
            SendMessageW(hwnd, LB_SETCURSEL, row, 0);
        }
        return 0;
    }
    case WM_LBUTTONDOWN:
        return 0;
    case WM_LBUTTONUP:
        Take(state, ItemAt(hwnd, lParam));
        return 0;
    }
    return DefSubclassProc(hwnd, message, wParam, lParam);
}

void CreateList(Completion* state) {
    HWND owner = GetAncestor(state->edit, GA_ROOT);
    state->list = CreateWindowExW(WS_EX_TOOLWINDOW | WS_EX_NOACTIVATE | WS_EX_TOPMOST, L"LISTBOX", nullptr,
                                  WS_POPUP | WS_BORDER | WS_VSCROLL | LBS_NOINTEGRALHEIGHT | LBS_NOTIFY, 0, 0, 0, 0, owner, nullptr,
                                  GetModuleHandleW(nullptr), nullptr);
    SendMessageW(state->list, WM_SETFONT, SendMessageW(state->edit, WM_GETFONT, 0, 0), FALSE);
    SetWindowSubclass(state->list, ListProc, 0, reinterpret_cast<DWORD_PTR>(state));
}

// the people for what is typed now, under the field; the list gone when there are none
void Update(Completion* state) {
    std::wstring text = GetWindowString(state->edit);
    size_t start = 0, end = 0;
    size_t caret = Caret(state->edit);
    TokenAt(text, caret, start, end);
    std::wstring typed = text.substr(start, caret - start);
    // a whole address typed with its brackets is not looked up again
    if (typed.empty() || typed.find(L'<') != std::wstring::npos) {
        Hide(state);
        return;
    }
    core::ContactList found(pe_contacts(state->core, core::Narrow(typed).c_str(), kShown));
    size_t count = pe_contact_list_count(found.get());
    if (count == 0) {
        Hide(state);
        return;
    }
    if (!state->list) {
        CreateList(state);
    }
    SendMessageW(state->list, WM_SETREDRAW, FALSE, 0);
    SendMessageW(state->list, LB_RESETCONTENT, 0, 0);
    state->rows.clear();
    for (size_t i = 0; i < count; i++) {
        const PeContact* contact = pe_contact_list_get(found.get(), i);
        state->rows.push_back({Text(contact->label), Text(contact->address), contact->group});
        std::wstring shown = contact->group ? Text(contact->name) : state->rows.back().label;
        SendMessageW(state->list, LB_ADDSTRING, 0, reinterpret_cast<LPARAM>(shown.c_str()));
    }
    // the best one chosen: Enter or Tab takes it
    SendMessageW(state->list, LB_SETCURSEL, 0, 0);
    SendMessageW(state->list, WM_SETREDRAW, TRUE, 0);
    RECT field;
    GetWindowRect(state->edit, &field);
    int itemHeight = static_cast<int>(SendMessageW(state->list, LB_GETITEMHEIGHT, 0, 0));
    int height = itemHeight * static_cast<int>(count) + 2 * GetSystemMetrics(SM_CYBORDER);
    SetWindowPos(state->list, HWND_TOPMOST, field.left, field.bottom, field.right - field.left, height, SWP_NOACTIVATE | SWP_SHOWWINDOW);
    InvalidateRect(state->list, nullptr, TRUE);
}

void Move(Completion* state, int by) {
    int count = static_cast<int>(SendMessageW(state->list, LB_GETCOUNT, 0, 0));
    int current = static_cast<int>(SendMessageW(state->list, LB_GETCURSEL, 0, 0));
    SendMessageW(state->list, LB_SETCURSEL, std::clamp(current + by, 0, count - 1), 0);
}

// Shift+Delete on a person in the list: out of those written to and heard from for good (not a group, nor someone of
// the Address Book, who stays)
void Forget(Completion* state) {
    int index = static_cast<int>(SendMessageW(state->list, LB_GETCURSEL, 0, 0));
    if (index >= 0 && static_cast<size_t>(index) < state->rows.size() && !state->rows[index].group) {
        pe_contact_forget(state->core, core::Narrow(state->rows[index].address).c_str());
        Update(state);
    }
}

LRESULT CALLBACK FieldProc(HWND hwnd, UINT message, WPARAM wParam, LPARAM lParam, UINT_PTR, DWORD_PTR data) {
    auto* state = reinterpret_cast<Completion*>(data);
    switch (message) {
    case WM_GETDLGCODE:
        // while the list is open, Enter, Tab and Esc are the field's, not the window's
        if (Shown(state)) {
            return DefSubclassProc(hwnd, message, wParam, lParam) | DLGC_WANTALLKEYS;
        }
        break;
    case WM_KEYDOWN:
        if (Shown(state)) {
            state->swallow = wParam == VK_RETURN || wParam == VK_TAB || wParam == VK_ESCAPE;
            switch (wParam) {
            case VK_DOWN:
                Move(state, 1);
                return 0;
            case VK_UP:
                Move(state, -1);
                return 0;
            case VK_RETURN:
            case VK_TAB:
                Take(state, static_cast<int>(SendMessageW(state->list, LB_GETCURSEL, 0, 0)));
                return 0;
            case VK_ESCAPE:
                Hide(state);
                return 0;
            case VK_DELETE:
                if (GetKeyState(VK_SHIFT) < 0) {
                    Forget(state);
                    return 0;
                }
                break;
            }
        }
        break;
    case WM_CHAR: {
        if (std::exchange(state->swallow, false)) {
            return 0;
        }
        LRESULT result = DefSubclassProc(hwnd, message, wParam, lParam);
        Update(state);
        return result;
    }
    case WM_KILLFOCUS:
    case WM_WINDOWPOSCHANGED:
        Hide(state);
        break;
    case WM_NCDESTROY: {
        RemoveWindowSubclass(hwnd, FieldProc, 0);
        if (state->list) {
            DestroyWindow(state->list);
        }
        delete state;
        return DefSubclassProc(hwnd, message, wParam, lParam);
    }
    }
    return DefSubclassProc(hwnd, message, wParam, lParam);
}

}  // namespace

void CompleteAddresses(HWND edit, PeCore* core) {
    auto* state = new Completion{core, edit};
    SetWindowSubclass(edit, FieldProc, 0, reinterpret_cast<DWORD_PTR>(state));
}
