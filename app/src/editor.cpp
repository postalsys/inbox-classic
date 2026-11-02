// The compose window's editor. Unlike the preview this WebView2 runs a script, the page's own (see editor.h); the
// rest is locked down the same way: no network, no navigation, no dev tools, no host objects, and none of the browser
// keys that could reload the page and lose what was written.
#include "editor.h"

#include "webview.h"

using Microsoft::WRL::Callback;
using Microsoft::WRL::ComPtr;

namespace {

const wchar_t* kHostClass = L"InboxClassicEditor";
// where the page is served from memory (webview.h); .invalid never resolves, nothing else is served for it
const wchar_t* kPageUrl = L"https://compose.inboxclassic.invalid/";

// `value` as a JavaScript string literal: everything but plain letters and digits escaped, so no value can end the
// string
std::wstring JsString(const std::wstring& value) {
    std::wstring out = L"'";
    for (wchar_t c : value) {
        if ((c >= L'a' && c <= L'z') || (c >= L'A' && c <= L'Z') || (c >= L'0' && c <= L'9') || c == L' ') {
            out += c;
        } else {
            wchar_t escaped[8];
            swprintf_s(escaped, L"\\u%04x", static_cast<unsigned>(c));
            out += escaped;
        }
    }
    return out + L"'";
}

}  // namespace

LRESULT CALLBACK Editor::HostProc(HWND hwnd, UINT message, WPARAM wParam, LPARAM lParam) {
    auto* editor = reinterpret_cast<Editor*>(GetWindowLongPtrW(hwnd, GWLP_USERDATA));
    if (message == WM_SETFOCUS && editor) {
        // Tab from the fields lands on the host: the editor takes it
        editor->Focus();
        return 0;
    }
    if (message == WM_GETDLGCODE) {
        return DLGC_WANTALLKEYS;
    }
    return DefWindowProcW(hwnd, message, wParam, lParam);
}

HWND Editor::Create(HWND parent, int id, const std::wstring& document, Handlers handlers) {
    static bool registered = false;
    if (!registered) {
        WNDCLASSEXW windowClass = {sizeof(windowClass)};
        windowClass.lpfnWndProc = HostProc;
        windowClass.hInstance = GetModuleHandleW(nullptr);
        windowClass.hCursor = LoadCursorW(nullptr, IDC_IBEAM);
        windowClass.hbrBackground = reinterpret_cast<HBRUSH>(COLOR_WINDOW + 1);
        windowClass.lpszClassName = kHostClass;
        RegisterClassExW(&windowClass);
        registered = true;
    }
    document_ = document;
    handlers_ = std::move(handlers);
    host_ = CreateWindowExW(WS_EX_CLIENTEDGE, kHostClass, nullptr, WS_CHILD | WS_VISIBLE | WS_TABSTOP | WS_CLIPCHILDREN, 0, 0, 0, 0,
                            parent, reinterpret_cast<HMENU>(static_cast<INT_PTR>(id)), GetModuleHandleW(nullptr), nullptr);
    SetWindowLongPtrW(host_, GWLP_USERDATA, reinterpret_cast<LONG_PTR>(this));
    webview::Create(
        host_,
        [this](ICoreWebView2Environment* environment, ICoreWebView2Controller* controller) {
            environment_ = environment;
            controller_ = controller;
            controller_->get_CoreWebView2(&view_);
            Configure();
        },
        [this](const std::wstring& error) { handlers_.error(error + L" Messages can not be written."); });
    return host_;
}

void Editor::Configure() {
    ComPtr<ICoreWebView2Settings> settings;
    view_->get_Settings(&settings);
    settings->put_IsScriptEnabled(TRUE);
    settings->put_IsWebMessageEnabled(TRUE);
    settings->put_AreDefaultScriptDialogsEnabled(FALSE);
    settings->put_AreHostObjectsAllowed(FALSE);
    settings->put_AreDevToolsEnabled(FALSE);
    settings->put_IsStatusBarEnabled(FALSE);
    settings->put_IsBuiltInErrorPageEnabled(FALSE);
    // cut, copy, paste and the spelling suggestions stay in the context menu
    settings->put_AreDefaultContextMenusEnabled(TRUE);
    ComPtr<ICoreWebView2Settings3> settings3;
    if (SUCCEEDED(settings.As(&settings3))) {
        // F5 would reload the page and throw the text away, Ctrl+P and Ctrl+F open browser windows
        settings3->put_AreBrowserAcceleratorKeysEnabled(FALSE);
    }

    // the page from memory, nothing from the network, pasted pictures from the web included
    webview::FilterRequests(
        view_.Get(), environment_.Get(), kPageUrl, [this]() -> const std::wstring& { return document_; },
        [](const wchar_t*, COREWEBVIEW2_WEB_RESOURCE_CONTEXT) { return false; });

    // the page and the frame of the quote are all there is; links are not followed while writing
    auto stay = Callback<ICoreWebView2NavigationStartingEventHandler>([](ICoreWebView2*, ICoreWebView2NavigationStartingEventArgs* args) {
        LPWSTR uri = nullptr;
        args->get_Uri(&uri);
        if (!webview::IsOwnPage(uri, kPageUrl)) {
            args->put_Cancel(TRUE);
        }
        CoTaskMemFree(uri);
        return S_OK;
    });
    view_->add_NavigationStarting(stay.Get(), nullptr);
    view_->add_FrameNavigationStarting(stay.Get(), nullptr);
    view_->add_NewWindowRequested(
        Callback<ICoreWebView2NewWindowRequestedEventHandler>([](ICoreWebView2*, ICoreWebView2NewWindowRequestedEventArgs* args) {
            args->put_Handled(TRUE);
            return S_OK;
        }).Get(),
        nullptr);

    view_->add_WebMessageReceived(
        Callback<ICoreWebView2WebMessageReceivedEventHandler>([this](ICoreWebView2*, ICoreWebView2WebMessageReceivedEventArgs* args) {
            LPWSTR text = nullptr;
            if (FAILED(args->TryGetWebMessageAsString(&text)) || !text) {
                return S_OK;
            }
            std::wstring message = text;
            CoTaskMemFree(text);
            if (message.rfind(L"html:", 0) == 0) {
                handlers_.html(message.substr(5), false);
            } else if (message.rfind(L"full:", 0) == 0) {
                handlers_.html(message.substr(5), true);
            } else if (message.rfind(L"state:", 0) == 0) {
                handlers_.state(message.substr(6));
            } else if (message == L"dirty") {
                handlers_.dirty();
            }
            return S_OK;
        }).Get(),
        nullptr);

    controller_->add_AcceleratorKeyPressed(
        Callback<ICoreWebView2AcceleratorKeyPressedEventHandler>([this](ICoreWebView2Controller*, ICoreWebView2AcceleratorKeyPressedEventArgs* args) {
            COREWEBVIEW2_KEY_EVENT_KIND kind;
            UINT key = 0;
            args->get_KeyEventKind(&kind);
            args->get_VirtualKey(&key);
            bool control = GetKeyState(VK_CONTROL) & 0x8000;
            if (kind == COREWEBVIEW2_KEY_EVENT_KIND_KEY_DOWN && control && key == VK_RETURN) {
                args->put_Handled(TRUE);
                handlers_.send();
            } else if (kind == COREWEBVIEW2_KEY_EVENT_KIND_KEY_DOWN && control && key == 'S') {
                args->put_Handled(TRUE);
                handlers_.save();
            }
            return S_OK;
        }).Get(),
        nullptr);

    RECT bounds;
    GetClientRect(host_, &bounds);
    controller_->put_Bounds(bounds);
    controller_->put_IsVisible(TRUE);
    view_->Navigate(kPageUrl);
    if (focusWhenReady_) {
        Focus();
    }
}

void Editor::Script(const std::wstring& code) {
    if (view_) {
        view_->ExecuteScript(code.c_str(), nullptr);
    }
}

void Editor::Exec(const wchar_t* command, const std::wstring& value) {
    Script(L"pe.exec(" + JsString(command) + L"," + JsString(value) + L")");
}

void Editor::Link(const std::wstring& url) {
    Script(L"pe.link(" + JsString(url) + L")");
}

void Editor::Html() {
    Script(L"pe.send()");
}

void Editor::Clean() {
    Script(L"pe.clean()");
}

void Editor::Focus() {
    if (!controller_) {
        focusWhenReady_ = true;
        return;
    }
    controller_->MoveFocus(COREWEBVIEW2_MOVE_FOCUS_REASON_PROGRAMMATIC);
    Script(L"window.pe && pe.focus()");
}

void Editor::Resize(const RECT& bounds) {
    MoveWindow(host_, bounds.left, bounds.top, bounds.right - bounds.left, bounds.bottom - bounds.top, TRUE);
    if (controller_) {
        RECT inner;
        GetClientRect(host_, &inner);
        controller_->put_Bounds(inner);
    }
}

void Editor::Close() {
    if (controller_) {
        controller_->Close();
    }
    view_.Reset();
    controller_.Reset();
    environment_.Reset();
}
