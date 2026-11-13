// The folder list's own parts, as Outlook Express has them: the "Folders" caption over the tree with its close box,
// and, while View > Folder List is off, the drop-down of the folder bar that holds the tree, with a pushpin that keeps
// the list beside the messages again. The tree is the mailbox's own window, moved into the drop-down and back.
#include "app.h"

namespace {

const wchar_t* kCaptionClass = L"InboxClassicPaneCaption";
const wchar_t* kDropClass = L"InboxClassicFolderDrop";

// the drop-down while it is open, the tree it holds, and the window the tree goes back to
HWND g_drop = nullptr;
HWND g_dropTree = nullptr;
HWND g_dropOwner = nullptr;

// a caption's button: the close box (×), or the pushpin of the drop-down
bool IsPin(HWND caption) {
    return GetWindowLongPtrW(caption, GWLP_USERDATA) != 0;
}

int ButtonSize() {
    return Scale(16);
}

// a pushpin lying on its side, its point to the left, as Outlook Express's: drawn in the button text color
void DrawPin(HDC dc, const RECT& box) {
    int cx = (box.left + box.right) / 2, cy = (box.top + box.bottom) / 2, unit = std::max(1, Scale(1));
    HPEN pen = CreatePen(PS_SOLID, unit, GetSysColor(COLOR_BTNTEXT));
    HGDIOBJ oldPen = SelectObject(dc, pen);
    HGDIOBJ oldBrush = SelectObject(dc, GetSysColorBrush(COLOR_BTNFACE));
    // the needle, the collar and the head
    MoveToEx(dc, cx - 6 * unit, cy, nullptr);
    LineTo(dc, cx - 1 * unit, cy);
    MoveToEx(dc, cx - 1 * unit, cy - 4 * unit, nullptr);
    LineTo(dc, cx - 1 * unit, cy + 5 * unit);
    Rectangle(dc, cx, cy - 2 * unit, cx + 5 * unit, cy + 3 * unit);
    MoveToEx(dc, cx + 5 * unit, cy - 3 * unit, nullptr);
    LineTo(dc, cx + 5 * unit, cy + 4 * unit);
    SelectObject(dc, oldBrush);
    SelectObject(dc, oldPen);
    DeleteObject(pen);
}

// the button flat on the caption, its edge raised while pressed shows sunk
void DrawCaptionButton(const DRAWITEMSTRUCT& item, bool pin) {
    RECT box = item.rcItem;
    FillRect(item.hDC, &box, GetSysColorBrush(COLOR_BTNFACE));
    bool pressed = (item.itemState & ODS_SELECTED) != 0;
    if (pressed) {
        DrawEdge(item.hDC, &box, BDR_SUNKENOUTER, BF_RECT);
        OffsetRect(&box, 1, 1);
    }
    if (pin) {
        DrawPin(item.hDC, box);
    } else {
        DrawMarlettGlyph(item.hDC, box, L'r', box.bottom - box.top - Scale(4), GetSysColor(COLOR_BTNTEXT));
    }
    if (item.itemState & ODS_FOCUS) {
        RECT focus = item.rcItem;
        InflateRect(&focus, -2, -2);
        DrawFocusRect(item.hDC, &focus);
    }
}

void PaintCaption(HWND caption) {
    PAINTSTRUCT paint;
    HDC dc = BeginPaint(caption, &paint);
    RECT area;
    GetClientRect(caption, &area);
    FillRect(dc, &area, GetSysColorBrush(COLOR_BTNFACE));
    DrawEdge(dc, &area, BDR_RAISEDINNER, BF_RECT);
    RECT words = area;
    words.left += Scale(6);
    words.right -= ButtonSize() + Scale(6);
    auto font = reinterpret_cast<HGDIOBJ>(SendMessageW(caption, WM_GETFONT, 0, 0));
    HGDIOBJ old = SelectObject(dc, font ? font : GetStockObject(DEFAULT_GUI_FONT));
    SetBkMode(dc, TRANSPARENT);
    SetTextColor(dc, GetSysColor(COLOR_BTNTEXT));
    // the words once: the language changes only with a restart
    static const std::wstring text = core::T(PE_TEXT_UI_FOLDERS);
    DrawTextW(dc, text.c_str(), static_cast<int>(text.size()), &words,
              DT_LEFT | DT_VCENTER | DT_SINGLELINE | DT_END_ELLIPSIS | DT_NOPREFIX);
    SelectObject(dc, old);
    EndPaint(caption, &paint);
}

LRESULT CALLBACK CaptionProc(HWND caption, UINT message, WPARAM wParam, LPARAM lParam) {
    switch (message) {
    case WM_CREATE: {
        auto* create = reinterpret_cast<CREATESTRUCTW*>(lParam);
        bool pin = create->lpCreateParams != nullptr;
        SetWindowLongPtrW(caption, GWLP_USERDATA, pin ? 1 : 0);
        // its words are its name for screen readers and its tooltip
        std::wstring words = core::T(pin ? PE_TEXT_WIN_FOLDERS_PIN : PE_TEXT_WIN_FOLDERS_HIDE);
        HWND button = CreateChild(caption, L"BUTTON", words.c_str(), BS_OWNERDRAW, IDC_FOLDER_CAPTION_BUTTON, {});
        AddTip(caption, button, words);
        return 0;
    }
    case WM_SIZE: {
        int width = LOWORD(lParam), height = HIWORD(lParam), size = ButtonSize();
        MoveWindow(GetDlgItem(caption, IDC_FOLDER_CAPTION_BUTTON), width - size - Scale(3), (height - size) / 2, size, size,
                   TRUE);
        return 0;
    }
    case WM_PAINT:
        PaintCaption(caption);
        return 0;
    case WM_SETFONT:
        SetWindowLongPtrW(caption, 0, static_cast<LONG_PTR>(wParam));
        return 0;
    case WM_GETFONT:
        return GetWindowLongPtrW(caption, 0);
    case WM_DRAWITEM:
        DrawCaptionButton(*reinterpret_cast<const DRAWITEMSTRUCT*>(lParam), IsPin(caption));
        return TRUE;
    case WM_COMMAND:
        if (LOWORD(wParam) == IDC_FOLDER_CAPTION_BUTTON && HIWORD(wParam) == BN_CLICKED) {
            // the main window turns the folder list on or off, which also closes the drop-down (the drop-down passes
            // its commands on to the main window)
            PostMessageW(GetParent(caption), WM_COMMAND, IDM_FOLDER_LIST, 0);
        }
        return 0;
    }
    return DefWindowProcW(caption, message, wParam, lParam);
}

// the tree's click on a folder (not its + or - box) chooses it: the drop-down closes after the selection is taken
bool ClickedFolder(HWND tree) {
    TVHITTESTINFO hit = {};
    GetCursorPos(&hit.pt);
    ScreenToClient(tree, &hit.pt);
    return TreeView_HitTest(tree, &hit) && (hit.flags & TVHT_ONITEM);
}

LRESULT CALLBACK DropProc(HWND drop, UINT message, WPARAM wParam, LPARAM lParam) {
    switch (message) {
    case WM_NOTIFY: {
        // the tree's notifications are the main window's, as when the tree is there
        LRESULT result = SendMessageW(g_dropOwner, WM_NOTIFY, wParam, lParam);
        auto* header = reinterpret_cast<NMHDR*>(lParam);
        if (header->hwndFrom == g_dropTree) {
            if (header->code == NM_CLICK && ClickedFolder(g_dropTree)) {
                PostMessageW(drop, WM_CLOSE, 0, 0);
            } else if (header->code == TVN_KEYDOWN) {
                WORD key = reinterpret_cast<NMTVKEYDOWN*>(lParam)->wVKey;
                if (key == VK_RETURN || key == VK_ESCAPE) {
                    PostMessageW(drop, WM_CLOSE, 0, 0);
                }
            }
        }
        return result;
    }
    case WM_COMMAND:
    case WM_CONTEXTMENU:
        // the tree's commands and the menu key's menu are the main window's too
        return SendMessageW(g_dropOwner, message, wParam, lParam);
    case WM_ACTIVATE:
        // a click anywhere else closes it, as a menu closes
        if (LOWORD(wParam) == WA_INACTIVE && g_drop == drop) {
            PostMessageW(drop, WM_CLOSE, 0, 0);
        }
        return 0;
    case WM_CLOSE:
        CloseFolderDrop();
        return 0;
    }
    return DefWindowProcW(drop, message, wParam, lParam);
}

void Register() {
    static bool registered = false;
    if (registered) {
        return;
    }
    registered = true;
    WNDCLASSEXW caption = {sizeof(caption)};
    caption.lpfnWndProc = CaptionProc;
    caption.hInstance = GetModuleHandleW(nullptr);
    caption.hCursor = LoadCursorW(nullptr, IDC_ARROW);
    caption.hbrBackground = reinterpret_cast<HBRUSH>(COLOR_BTNFACE + 1);
    caption.lpszClassName = kCaptionClass;
    caption.cbWndExtra = sizeof(LONG_PTR);
    RegisterClassExW(&caption);
    WNDCLASSEXW drop = {sizeof(drop)};
    drop.lpfnWndProc = DropProc;
    drop.hInstance = GetModuleHandleW(nullptr);
    drop.hCursor = LoadCursorW(nullptr, IDC_ARROW);
    drop.hbrBackground = reinterpret_cast<HBRUSH>(COLOR_BTNFACE + 1);
    drop.lpszClassName = kDropClass;
    drop.style = CS_DROPSHADOW;
    RegisterClassExW(&drop);
}

}  // namespace

int FolderCaptionHeight() {
    return Scale(20);
}

HWND CreateFolderCaption(HWND parent, bool pin, HFONT font) {
    Register();
    HWND caption = CreateWindowExW(0, kCaptionClass, nullptr, WS_CHILD | WS_VISIBLE | WS_CLIPCHILDREN, 0, 0, 0, 0, parent,
                                   reinterpret_cast<HMENU>(static_cast<INT_PTR>(IDC_FOLDER_CAPTION)), GetModuleHandleW(nullptr),
                                   pin ? reinterpret_cast<void*>(1) : nullptr);
    SendMessageW(caption, WM_SETFONT, reinterpret_cast<WPARAM>(font), FALSE);
    return caption;
}

bool FolderDropOpen() {
    return g_drop != nullptr;
}

void OpenFolderDrop(HWND owner, HWND tree, const RECT& under, int width, int height) {
    if (g_drop) {
        return;
    }
    Register();
    g_dropOwner = owner;
    g_dropTree = tree;
    int captionHeight = FolderCaptionHeight();
    g_drop = CreateWindowExW(WS_EX_TOOLWINDOW, kDropClass, nullptr, WS_POPUP | WS_BORDER | WS_CLIPCHILDREN, under.left,
                             under.bottom, width, height, owner, nullptr, GetModuleHandleW(nullptr), nullptr);
    HWND caption = CreateFolderCaption(g_drop, true, reinterpret_cast<HFONT>(SendMessageW(tree, WM_GETFONT, 0, 0)));
    RECT inside;
    GetClientRect(g_drop, &inside);
    MoveWindow(caption, 0, 0, inside.right, captionHeight, TRUE);
    SetParent(tree, g_drop);
    MoveWindow(tree, 0, captionHeight, inside.right, inside.bottom - captionHeight, TRUE);
    ShowWindow(tree, SW_SHOW);
    ShowWindow(g_drop, SW_SHOW);
    SetFocus(tree);
    // the selected folder in view, as the drop-down opens on it
    if (HTREEITEM selected = TreeView_GetSelection(tree)) {
        TreeView_EnsureVisible(tree, selected);
    }
}

void CloseFolderDrop() {
    if (!g_drop) {
        return;
    }
    HWND drop = std::exchange(g_drop, nullptr);
    ShowWindow(g_dropTree, SW_HIDE);
    SetParent(g_dropTree, g_dropOwner);
    // the keyboard back where the messages are
    if (GetActiveWindow() == drop || GetForegroundWindow() == drop) {
        SetActiveWindow(g_dropOwner);
    }
    DestroyWindow(drop);
}
