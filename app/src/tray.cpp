// The notification area and the taskbar: the app's icon in the tray while it runs (the main window hides there when
// closed), its tooltip and a count on the taskbar button saying how many messages are unread in the Inboxes, and a
// Windows notification when new mail comes in. Nothing here reads mail: the core gives the count and the words.
#include "app.h"

#include <shellapi.h>
#include <shobjidl.h>
#include <wrl/client.h>

#include <algorithm>
#include <string>

namespace {

constexpr UINT kTrayId = 1;

// Explorer started again (the icon has to be added again), and the taskbar button is there (its overlay can be set)
UINT g_taskbarCreated = 0;
UINT g_buttonCreated = 0;
Microsoft::WRL::ComPtr<ITaskbarList3> g_taskbar;
HICON g_badge = nullptr;
uint64_t g_unread = 0;
// the message a click on the last notification opens
int64_t g_noteFolder = 0;
uint64_t g_noteUid = 0;

NOTIFYICONDATAW Data(HWND main) {
    NOTIFYICONDATAW data = {sizeof(data)};
    data.hWnd = main;
    data.uID = kTrayId;
    return data;
}

std::wstring UnreadText(uint64_t unread);

// the icon's tooltip
void SetTip(NOTIFYICONDATAW& data) {
    data.uFlags |= NIF_TIP | NIF_SHOWTIP;
    wcsncpy_s(data.szTip, (L"Inbox Classic\n" + UnreadText(g_unread)).c_str(), _TRUNCATE);
}

std::wstring UnreadText(uint64_t unread) {
    if (unread == 0) {
        return L"No unread messages";
    }
    return std::to_wstring(unread) + (unread == 1 ? L" unread message" : L" unread messages");
}

// the count, white on a red disc, for the taskbar button
HICON Badge(uint64_t count) {
    int size = GetSystemMetrics(SM_CXSMICON);
    BITMAPINFO info = {};
    info.bmiHeader = {sizeof(BITMAPINFOHEADER), size, -size, 1, 32, BI_RGB};
    void* bits = nullptr;
    HDC screen = GetDC(nullptr);
    HDC dc = CreateCompatibleDC(screen);
    ReleaseDC(nullptr, screen);
    HBITMAP color = CreateDIBSection(dc, &info, DIB_RGB_COLORS, &bits, nullptr, 0);
    if (!color) {
        DeleteDC(dc);
        return nullptr;
    }
    HGDIOBJ oldBitmap = SelectObject(dc, color);
    HBRUSH red = CreateSolidBrush(RGB(0xC4, 0x2B, 0x1C));
    HGDIOBJ oldBrush = SelectObject(dc, red);
    HGDIOBJ oldPen = SelectObject(dc, GetStockObject(NULL_PEN));
    Ellipse(dc, 0, 0, size + 1, size + 1);
    std::wstring text = count > 99 ? L"99+" : std::to_wstring(count);
    HFONT font = CreateFontW(-size * (text.size() > 2 ? 6 : 8) / 10, 0, 0, 0, FW_BOLD, FALSE, FALSE, FALSE, DEFAULT_CHARSET, OUT_DEFAULT_PRECIS,
                             CLIP_DEFAULT_PRECIS, NONANTIALIASED_QUALITY, DEFAULT_PITCH, L"Segoe UI");
    HGDIOBJ oldFont = SelectObject(dc, font);
    SetTextColor(dc, RGB(0xFF, 0xFF, 0xFF));
    SetBkMode(dc, TRANSPARENT);
    RECT area = {0, 0, size, size};
    DrawTextW(dc, text.c_str(), -1, &area, DT_CENTER | DT_VCENTER | DT_SINGLELINE | DT_NOPREFIX);
    GdiFlush();
    // GDI leaves the alpha at 0: what it drew on is opaque, the rest stays clear
    auto* pixel = static_cast<uint32_t*>(bits);
    for (int i = 0; i < size * size; i++) {
        if (pixel[i] & 0x00FFFFFF) {
            pixel[i] |= 0xFF000000;
        }
    }
    SelectObject(dc, oldFont);
    SelectObject(dc, oldPen);
    SelectObject(dc, oldBrush);
    SelectObject(dc, oldBitmap);
    DeleteObject(font);
    DeleteObject(red);
    DeleteDC(dc);
    HBITMAP mask = CreateBitmap(size, size, 1, 1, nullptr);
    ICONINFO icon = {TRUE, 0, 0, mask, color};
    HICON badge = CreateIconIndirect(&icon);
    DeleteObject(mask);
    DeleteObject(color);
    return badge;
}

void Add(HWND main) {
    NOTIFYICONDATAW data = Data(main);
    data.uFlags = NIF_MESSAGE | NIF_ICON;
    data.uCallbackMessage = WM_TRAY;
    data.hIcon = AppIcon(true);
    SetTip(data);
    Shell_NotifyIconW(NIM_ADD, &data);
    data.uVersion = NOTIFYICON_VERSION_4;
    Shell_NotifyIconW(NIM_SETVERSION, &data);
}

void ShowBadge(HWND main) {
    if (!g_taskbar) {
        return;
    }
    if (g_badge) {
        DestroyIcon(g_badge);
        g_badge = nullptr;
    }
    if (g_unread > 0) {
        g_badge = Badge(g_unread);
    }
    g_taskbar->SetOverlayIcon(main, g_badge, g_unread > 0 ? UnreadText(g_unread).c_str() : L"");
}

}  // namespace

void TrayCreate(HWND main) {
    g_taskbarCreated = RegisterWindowMessageW(L"TaskbarCreated");
    g_buttonCreated = RegisterWindowMessageW(L"TaskbarButtonCreated");
    Add(main);
}

void TrayRemove(HWND main) {
    NOTIFYICONDATAW data = Data(main);
    Shell_NotifyIconW(NIM_DELETE, &data);
    if (g_badge) {
        DestroyIcon(g_badge);
        g_badge = nullptr;
    }
    g_taskbar.Reset();
}

void TrayCount(HWND main, uint64_t unread) {
    if (unread == g_unread) {
        return;
    }
    g_unread = unread;
    NOTIFYICONDATAW data = Data(main);
    SetTip(data);
    Shell_NotifyIconW(NIM_MODIFY, &data);
    ShowBadge(main);
}

void TrayNotify(HWND main, const std::wstring& title, const std::wstring& text, int64_t folder, uint64_t uid) {
    g_noteFolder = folder;
    g_noteUid = uid;
    NOTIFYICONDATAW data = Data(main);
    data.uFlags = NIF_INFO;
    wcsncpy_s(data.szInfoTitle, title.c_str(), _TRUNCATE);
    wcsncpy_s(data.szInfo, text.empty() ? L" " : text.c_str(), _TRUNCATE);
    data.dwInfoFlags = NIIF_USER | NIIF_LARGE_ICON;
    data.hBalloonIcon = AppIcon(false);
    Shell_NotifyIconW(NIM_MODIFY, &data);
}

TrayAction TrayMessage(HWND main, UINT message, WPARAM, LPARAM lParam, int64_t& folder, uint64_t& uid) {
    if (message == g_taskbarCreated && g_taskbarCreated) {
        Add(main);
        ShowBadge(main);
        return TrayAction::Handled;
    }
    if (message == g_buttonCreated && g_buttonCreated) {
        if (!g_taskbar && SUCCEEDED(CoCreateInstance(CLSID_TaskbarList, nullptr, CLSCTX_INPROC_SERVER, IID_PPV_ARGS(&g_taskbar)))) {
            g_taskbar->HrInit();
        }
        ShowBadge(main);
        return TrayAction::Handled;
    }
    if (message != WM_TRAY) {
        return TrayAction::None;
    }
    switch (LOWORD(lParam)) {
    case WM_LBUTTONUP:
    case NIN_SELECT:
    case NIN_KEYSELECT:
        // the window, no message of its own
        folder = 0;
        return TrayAction::Open;
    case WM_CONTEXTMENU:
        return TrayAction::Menu;
    case NIN_BALLOONUSERCLICK:
        folder = g_noteFolder;
        uid = g_noteUid;
        return TrayAction::Open;
    }
    return TrayAction::Handled;
}
