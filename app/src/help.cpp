// The help window: the core's help page (pe_help_page, core/crates/pe-html/src/help.html), shown in a WebView2 like a message (scripts off, links
// opened in the browser). One window; F1 again brings it to the front.
#include "app.h"

namespace {

const wchar_t* kHelpClass = L"InboxClassicHelp";

HWND g_help = nullptr;
HWND g_host = nullptr;  // the parent of the preview, it shows why when WebView2 cannot start
Preview* g_preview = nullptr;

std::wstring HelpDocument() {
    // one help for every platform, the core leaves out the parts of the others
    core::String page(pe_help_page("windows"));
    if (!page) {
        return L"<p>" + core::T(PE_TEXT_WIN_HELP_MISSING) + L"</p>";
    }
    return core::Widen(page.get());
}

void Layout(HWND hwnd) {
    RECT client;
    GetClientRect(hwnd, &client);
    MoveWindow(g_host, 0, 0, client.right, client.bottom, TRUE);
    RECT inner;
    GetClientRect(g_host, &inner);
    if (g_preview) {
        g_preview->Resize(inner);
    }
}

LRESULT CALLBACK HelpProc(HWND hwnd, UINT message, WPARAM wParam, LPARAM lParam) {
    switch (message) {
    case WM_SIZE:
        Layout(hwnd);
        return 0;
    case WM_DESTROY:
        if (g_preview) {
            g_preview->Close();
            delete g_preview;
            g_preview = nullptr;
        }
        g_help = nullptr;
        return 0;
    }
    return DefWindowProcW(hwnd, message, wParam, lParam);
}

}  // namespace

void OpenHelp() {
    if (g_help) {
        ShowWindow(g_help, SW_RESTORE);
        SetForegroundWindow(g_help);
        return;
    }
    static bool registered = false;
    if (!registered) {
        WNDCLASSEXW windowClass = {sizeof(windowClass)};
        windowClass.lpfnWndProc = HelpProc;
        windowClass.hInstance = GetModuleHandleW(nullptr);
        windowClass.hCursor = LoadCursorW(nullptr, IDC_ARROW);
        SetAppIcons(windowClass);
        windowClass.hbrBackground = reinterpret_cast<HBRUSH>(COLOR_WINDOW + 1);
        windowClass.lpszClassName = kHelpClass;
        RegisterClassExW(&windowClass);
        registered = true;
    }
    // not owned by the main window: the help stays usable while a dialog of the main window is open
    g_help = CreateWindowExW(0, kHelpClass, core::T(PE_TEXT_WIN_HELP_TITLE).c_str(), WS_OVERLAPPEDWINDOW | WS_CLIPCHILDREN, CW_USEDEFAULT,
                             CW_USEDEFAULT, Scale(820), Scale(700), nullptr, nullptr, GetModuleHandleW(nullptr), nullptr);
    if (!g_help) {
        return;
    }
    g_host = CreateChild(g_help, L"STATIC", nullptr, WS_CLIPCHILDREN, 0, {});
    g_preview = new Preview();
    g_preview->Create(g_host, [](const std::wstring& error) { SetWindowTextW(g_host, error.c_str()); });
    g_preview->Show(HelpDocument());
    Layout(g_help);
    ShowWindow(g_help, SW_SHOW);
}

void CloseHelp() {
    if (g_help) {
        DestroyWindow(g_help);
    }
}
