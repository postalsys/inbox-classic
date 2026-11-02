// The Print window: the message, as the reading pane shows it, in a window over the whole app, where WebView2's print
// preview (printer, pages, a live preview) opens at once and fills it. The page is the core's (pe_print_page): the same
// sanitized document with one script of the core's, allowed by a nonce, that says "done" once the preview is closed,
// printed or cancelled, which closes the window. The reading pane's own preview would only fill the pane, and the
// Windows Print dialog of Windows 11 has no preview for it.
#include "app.h"
#include "webview.h"

using Microsoft::WRL::Callback;
using Microsoft::WRL::ComPtr;

namespace {

const wchar_t* kPrintClass = L"InboxClassicPrint";
// where the page is served from memory (webview.h); .invalid never resolves, nothing else is served for it
const wchar_t* kPageUrl = L"https://print.inboxclassic.invalid/";

struct PrintState {
    std::wstring page;
    bool remoteImages = false;
    ComPtr<ICoreWebView2Environment> environment;
    ComPtr<ICoreWebView2Controller> controller;
    ComPtr<ICoreWebView2> view;
};

void Configure(HWND hwnd, PrintState* state) {
    // the page's own script and its one message; no context menu
    webview::LockDown(state->view.Get(), false);
    // the page from memory; from the network only the pictures the user allowed for this message
    webview::FilterRequests(
        state->view.Get(), state->environment.Get(), kPageUrl, [state]() -> const std::wstring& { return state->page; },
        [state](const wchar_t* uri, COREWEBVIEW2_WEB_RESOURCE_CONTEXT context) {
            return state->remoteImages && webview::IsRemoteImage(uri, context, kPageUrl);
        });
    // nothing navigates away from the page, no window opens from it
    webview::StayOnPage(state->view.Get(), kPageUrl);
    // the page there: WebView2's print preview over all of the window (the page's own print() would open the system
    // dialog of Windows 11, which has no preview for it)
    state->view->add_NavigationCompleted(
        Callback<ICoreWebView2NavigationCompletedEventHandler>([state](ICoreWebView2*, ICoreWebView2NavigationCompletedEventArgs* args) {
            BOOL success = FALSE;
            args->get_IsSuccess(&success);
            ComPtr<ICoreWebView2_16> printing;
            if (success && SUCCEEDED(state->view.As(&printing))) {
                printing->ShowPrintUI(COREWEBVIEW2_PRINT_DIALOG_KIND_BROWSER);
            }
            return S_OK;
        }).Get(),
        nullptr);
    // printed or cancelled: the window has done its job
    state->view->add_WebMessageReceived(
        Callback<ICoreWebView2WebMessageReceivedEventHandler>([hwnd](ICoreWebView2*, ICoreWebView2WebMessageReceivedEventArgs* args) {
            LPWSTR text = nullptr;
            if (SUCCEEDED(args->TryGetWebMessageAsString(&text)) && text) {
                if (std::wstring(text) == L"done") {
                    PostMessageW(hwnd, WM_CLOSE, 0, 0);
                }
                CoTaskMemFree(text);
            }
            return S_OK;
        }).Get(),
        nullptr);
    RECT bounds;
    GetClientRect(hwnd, &bounds);
    state->controller->put_Bounds(bounds);
    state->controller->put_IsVisible(TRUE);
    state->view->Navigate(kPageUrl);
}

LRESULT CALLBACK PrintProc(HWND hwnd, UINT message, WPARAM wParam, LPARAM lParam) {
    auto* state = reinterpret_cast<PrintState*>(GetWindowLongPtrW(hwnd, GWLP_USERDATA));
    switch (message) {
    case WM_SIZE:
        if (state && state->controller) {
            RECT bounds;
            GetClientRect(hwnd, &bounds);
            state->controller->put_Bounds(bounds);
        }
        return 0;
    case WM_DESTROY:
        if (state && state->controller) {
            state->controller->Close();
        }
        return 0;
    case WM_NCDESTROY:
        delete state;
        SetWindowLongPtrW(hwnd, GWLP_USERDATA, 0);
        break;
    }
    return DefWindowProcW(hwnd, message, wParam, lParam);
}

}  // namespace

void OpenPrintWindow(HWND owner, ICoreWebView2Environment* environment, const char* document, bool remoteImages, const std::wstring& subject) {
    core::String page(pe_print_page(document));
    if (!page) {
        MessageBoxW(owner, L"The message could not be printed.", L"Inbox Classic", MB_OK | MB_ICONERROR);
        return;
    }
    static bool registered = false;
    if (!registered) {
        WNDCLASSEXW windowClass = {sizeof(windowClass)};
        windowClass.lpfnWndProc = PrintProc;
        windowClass.hInstance = GetModuleHandleW(nullptr);
        windowClass.hCursor = LoadCursorW(nullptr, IDC_ARROW);
        SetAppIcons(windowClass);
        windowClass.hbrBackground = reinterpret_cast<HBRUSH>(COLOR_WINDOW + 1);
        windowClass.lpszClassName = kPrintClass;
        RegisterClassExW(&windowClass);
        registered = true;
    }
    // over the app, the size of its window, as large as the preview can be
    RECT area;
    GetWindowRect(owner, &area);
    std::wstring title = subject.empty() ? L"Print" : L"Print - " + subject;
    HWND hwnd = CreateWindowExW(0, kPrintClass, title.c_str(), WS_OVERLAPPEDWINDOW | WS_CLIPCHILDREN, area.left, area.top,
                                area.right - area.left, area.bottom - area.top, owner, nullptr, GetModuleHandleW(nullptr), nullptr);
    if (!hwnd) {
        return;
    }
    auto* state = new PrintState{Text(page.get()), remoteImages};
    SetWindowLongPtrW(hwnd, GWLP_USERDATA, reinterpret_cast<LONG_PTR>(state));
    ShowWindow(hwnd, SW_SHOW);
    auto ready = [hwnd, state](ICoreWebView2Environment* created, ICoreWebView2Controller* controller) {
        state->environment = created;
        state->controller = controller;
        controller->get_CoreWebView2(&state->view);
        Configure(hwnd, state);
    };
    auto failed = [hwnd](const std::wstring& error) {
        MessageBoxW(hwnd, error.c_str(), L"Inbox Classic", MB_OK | MB_ICONERROR);
        DestroyWindow(hwnd);
    };
    // the reading pane's environment when there is one: the browser process is there already
    if (environment) {
        webview::CreateIn(hwnd, environment, ready, failed);
    } else {
        webview::Create(hwnd, ready, failed);
    }
}
