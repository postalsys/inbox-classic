#include "webview.h"

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
        folder = std::wstring(local) + L"\\PostalExpress\\WebView2";
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

bool IsOwnPage(const wchar_t* uri, const wchar_t* url) {
    if (!uri) {
        return false;
    }
    size_t length = wcslen(url);
    // the page, the page with a query (a new document), or about:blank and about:srcdoc of its frames
    return (_wcsnicmp(uri, url, length) == 0 && (uri[length] == L'\0' || uri[length] == L'?')) || StartsWith(uri, L"about:");
}

void Create(HWND parent, std::function<void(ICoreWebView2Environment*, ICoreWebView2Controller*)> ready,
            std::function<void(const std::wstring&)> failed) {
    std::wstring folder = UserDataFolder();
    HRESULT hr = CreateCoreWebView2EnvironmentWithOptions(
        nullptr, folder.c_str(), nullptr,
        Callback<ICoreWebView2CreateCoreWebView2EnvironmentCompletedHandler>(
            [parent, ready, failed](HRESULT result, ICoreWebView2Environment* environment) {
                if (FAILED(result) || !environment) {
                    failed(L"The WebView2 runtime is not available.");
                    return S_OK;
                }
                ComPtr<ICoreWebView2Environment> kept = environment;
                environment->CreateCoreWebView2Controller(
                    parent, Callback<ICoreWebView2CreateCoreWebView2ControllerCompletedHandler>(
                                [kept, ready, failed](HRESULT created, ICoreWebView2Controller* controller) {
                                    if (FAILED(created) || !controller) {
                                        failed(L"Creating the WebView2 failed.");
                                    } else {
                                        ready(kept.Get(), controller);
                                    }
                                    return S_OK;
                                })
                                .Get());
                return S_OK;
            })
            .Get());
    if (FAILED(hr)) {
        failed(L"The WebView2 runtime is not available.");
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
