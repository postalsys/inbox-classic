#include "webview.h"

#include "core.h"

#include <shellapi.h>
#include <shlobj.h>
#include <shlwapi.h>

using Microsoft::WRL::Callback;
using Microsoft::WRL::ComPtr;

namespace webview {

namespace {

std::wstring UserDataFolder() {
    PWSTR local = nullptr;
    std::wstring folder;
    if (SUCCEEDED(SHGetKnownFolderPath(FOLDERID_LocalAppData, 0, nullptr, &local))) {
        folder = std::wstring(local) + L"\\InboxClassic\\WebView2";
    }
    CoTaskMemFree(local);
    return folder;
}

std::string Utf8(const std::wstring& text) {
    if (text.empty()) {
        return {};
    }
    int size = WideCharToMultiByte(CP_UTF8, 0, text.data(), static_cast<int>(text.size()), nullptr, 0, nullptr, nullptr);
    std::string out(static_cast<size_t>(size), '\0');
    WideCharToMultiByte(CP_UTF8, 0, text.data(), static_cast<int>(text.size()), out.data(), size, nullptr, nullptr);
    return out;
}

}  // namespace

bool StartsWith(const wchar_t* text, const wchar_t* prefix) {
    return text && _wcsnicmp(text, prefix, wcslen(prefix)) == 0;
}

bool IsLinkScheme(const wchar_t* uri) {
    return StartsWith(uri, L"http://") || StartsWith(uri, L"https://") || StartsWith(uri, L"mailto:");
}

void OpenExternally(const wchar_t* uri) {
    if (IsLinkScheme(uri)) {
        ShellExecuteW(nullptr, L"open", uri, nullptr, nullptr, SW_SHOWNORMAL);
    }
}

bool IsOwnPage(const wchar_t* uri, const wchar_t* url) {
    if (!uri) {
        return false;
    }
    size_t length = wcslen(url);
    // the page, the page with a query (a new document), or about:blank and about:srcdoc of its frames
    return (_wcsnicmp(uri, url, length) == 0 && (uri[length] == L'\0' || uri[length] == L'?')) || StartsWith(uri, L"about:");
}

bool IsRemoteImage(const wchar_t* uri, COREWEBVIEW2_WEB_RESOURCE_CONTEXT context, const wchar_t* url) {
    return context == COREWEBVIEW2_WEB_RESOURCE_CONTEXT_IMAGE && (StartsWith(uri, L"http://") || StartsWith(uri, L"https://")) &&
           !StartsWith(uri, url);
}

void LockDown(ICoreWebView2* view, bool contextMenu) {
    ComPtr<ICoreWebView2Settings> settings;
    view->get_Settings(&settings);
    settings->put_IsScriptEnabled(TRUE);
    settings->put_IsWebMessageEnabled(TRUE);
    settings->put_AreDefaultScriptDialogsEnabled(FALSE);
    settings->put_AreHostObjectsAllowed(FALSE);
    settings->put_AreDevToolsEnabled(FALSE);
    settings->put_IsStatusBarEnabled(FALSE);
    settings->put_IsBuiltInErrorPageEnabled(FALSE);
    settings->put_AreDefaultContextMenusEnabled(contextMenu ? TRUE : FALSE);
    ComPtr<ICoreWebView2Settings3> settings3;
    if (SUCCEEDED(settings.As(&settings3))) {
        settings3->put_AreBrowserAcceleratorKeysEnabled(FALSE);
    }
}

void StayOnPage(ICoreWebView2* view, const wchar_t* url) {
    auto stay = Callback<ICoreWebView2NavigationStartingEventHandler>([url](ICoreWebView2*, ICoreWebView2NavigationStartingEventArgs* args) {
        LPWSTR uri = nullptr;
        args->get_Uri(&uri);
        if (!IsOwnPage(uri, url)) {
            args->put_Cancel(TRUE);
        }
        CoTaskMemFree(uri);
        return S_OK;
    });
    view->add_NavigationStarting(stay.Get(), nullptr);
    view->add_FrameNavigationStarting(stay.Get(), nullptr);
    view->add_NewWindowRequested(
        Callback<ICoreWebView2NewWindowRequestedEventHandler>([](ICoreWebView2*, ICoreWebView2NewWindowRequestedEventArgs* args) {
            args->put_Handled(TRUE);
            return S_OK;
        }).Get(),
        nullptr);
}

void CreateIn(HWND parent, ICoreWebView2Environment* environment,
              std::function<void(ICoreWebView2Environment*, ICoreWebView2Controller*)> ready, std::function<void(const std::wstring&)> failed) {
    ComPtr<ICoreWebView2Environment> kept = environment;
    HRESULT hr = environment->CreateCoreWebView2Controller(
        parent, Callback<ICoreWebView2CreateCoreWebView2ControllerCompletedHandler>(
                    [kept, ready, failed](HRESULT created, ICoreWebView2Controller* controller) {
                        if (FAILED(created) || !controller) {
                            failed(core::T(PE_TEXT_WIN_WEBVIEW_FAILED));
                        } else {
                            ready(kept.Get(), controller);
                        }
                        return S_OK;
                    })
                    .Get());
    if (FAILED(hr)) {
        failed(core::T(PE_TEXT_WIN_WEBVIEW_FAILED));
    }
}

void Create(HWND parent, std::function<void(ICoreWebView2Environment*, ICoreWebView2Controller*)> ready,
            std::function<void(const std::wstring&)> failed) {
    std::wstring folder = UserDataFolder();
    HRESULT hr = CreateCoreWebView2EnvironmentWithOptions(
        nullptr, folder.c_str(), nullptr,
        Callback<ICoreWebView2CreateCoreWebView2EnvironmentCompletedHandler>(
            [parent, ready, failed](HRESULT result, ICoreWebView2Environment* environment) {
                if (FAILED(result) || !environment) {
                    failed(core::T(PE_TEXT_WIN_WEBVIEW_MISSING));
                    return S_OK;
                }
                CreateIn(parent, environment, ready, failed);
                return S_OK;
            })
            .Get());
    if (FAILED(hr)) {
        failed(core::T(PE_TEXT_WIN_WEBVIEW_MISSING));
    }
}

void FilterRequests(ICoreWebView2* view, ICoreWebView2Environment* environment, const wchar_t* url,
                    std::function<const std::wstring&()> serve, std::function<bool(const wchar_t*, COREWEBVIEW2_WEB_RESOURCE_CONTEXT)> allow) {
    ComPtr<ICoreWebView2Environment> env = environment;
    std::wstring page = url;
    view->AddWebResourceRequestedFilter(L"*", COREWEBVIEW2_WEB_RESOURCE_CONTEXT_ALL);
    view->add_WebResourceRequested(
        Callback<ICoreWebView2WebResourceRequestedEventHandler>([env, page, serve, allow](ICoreWebView2*, ICoreWebView2WebResourceRequestedEventArgs* args) {
            ComPtr<ICoreWebView2WebResourceRequest> request;
            args->get_Request(&request);
            LPWSTR uri = nullptr;
            request->get_Uri(&uri);
            COREWEBVIEW2_WEB_RESOURCE_CONTEXT context = COREWEBVIEW2_WEB_RESOURCE_CONTEXT_ALL;
            args->get_ResourceContext(&context);
            ComPtr<ICoreWebView2WebResourceResponse> response;
            if (context == COREWEBVIEW2_WEB_RESOURCE_CONTEXT_DOCUMENT && IsOwnPage(uri, page.c_str()) && !StartsWith(uri, L"about:")) {
                std::string body = Utf8(serve());
                ComPtr<IStream> stream;
                stream.Attach(SHCreateMemStream(reinterpret_cast<const BYTE*>(body.data()), static_cast<UINT>(body.size())));
                env->CreateWebResourceResponse(stream.Get(), 200, L"OK", L"Content-Type: text/html; charset=utf-8", &response);
            } else if (!allow(uri, context) && (StartsWith(uri, L"http://") || StartsWith(uri, L"https://") || StartsWith(uri, L"ftp://") ||
                                                StartsWith(uri, L"file:"))) {
                env->CreateWebResourceResponse(nullptr, 403, L"Blocked", L"", &response);
            }
            if (response) {
                args->put_Response(response.Get());
            }
            CoTaskMemFree(uri);
            return S_OK;
        }).Get(),
        nullptr);
}

}  // namespace webview
