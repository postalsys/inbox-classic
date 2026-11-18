#include "webview.h"

#include <cstdio>
#include <vector>

#include "core.h"

#include <share.h>
#include <shellapi.h>
#include <shlobj.h>
#include <shlwapi.h>

using Microsoft::WRL::Callback;
using Microsoft::WRL::ComPtr;

namespace webview {

namespace {

// every document served from memory: never kept in the web view's cache on disk (a part's document, the page and the
// printout can carry what was decrypted)
const wchar_t* kDocumentHeaders = L"Content-Type: text/html; charset=utf-8\r\nCache-Control: no-store";

// the links of a test run (SetOpenedLinksLog), written there in place of opening them
std::wstring g_openedLinksLog;

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
    if (!IsLinkScheme(uri)) {
        return;
    }
    if (g_openedLinksLog.empty()) {
        ShellExecuteW(nullptr, L"open", uri, nullptr, nullptr, SW_SHOWNORMAL);
        return;
    }
    // shared, so the test can read it while a line is written
    if (FILE* log = _wfsopen(g_openedLinksLog.c_str(), L"ab", _SH_DENYNO)) {
        std::string line = Utf8(uri) + "\n";
        fwrite(line.data(), 1, line.size(), log);
        fclose(log);
    }
}

void SetOpenedLinksLog(const std::wstring& path) {
    g_openedLinksLog = path;
}

bool IsOwnPage(const wchar_t* uri, const wchar_t* url) {
    if (!uri) {
        return false;
    }
    size_t length = wcslen(url);
    if (StartsWith(uri, L"about:")) {
        // about:blank and about:srcdoc of its frames
        return true;
    }
    if (_wcsnicmp(uri, url, length) != 0) {
        return false;
    }
    // the page, the page with a query (a new document), or the page in a folder of its own named by a number (a new
    // document whose frames have addresses beside it)
    const wchar_t* rest = uri + length;
    if (*rest == L'\0' || *rest == L'?') {
        return true;
    }
    const wchar_t* digits = rest;
    while (*rest >= L'0' && *rest <= L'9') {
        rest++;
    }
    return rest > digits && rest[0] == L'/' && rest[1] == L'\0';
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
    // the size is View > Text Size's, not Ctrl with the wheel or a pinch
    settings->put_IsZoomControlEnabled(FALSE);
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
                    std::function<const std::wstring&()> serve, std::function<bool(const wchar_t*, COREWEBVIEW2_WEB_RESOURCE_CONTEXT)> allow,
                    std::function<bool(const wchar_t* uri, std::string& document)> part,
                    std::function<bool(const wchar_t* uri, ICoreWebView2WebResourceRequestedEventArgs* args)> later) {
    ComPtr<ICoreWebView2Environment> env = environment;
    std::wstring page = url;
    view->AddWebResourceRequestedFilter(L"*", COREWEBVIEW2_WEB_RESOURCE_CONTEXT_ALL);
    view->add_WebResourceRequested(
        Callback<ICoreWebView2WebResourceRequestedEventHandler>([env, page, serve, allow, part, later](ICoreWebView2*,
                                                                                                     ICoreWebView2WebResourceRequestedEventArgs* args) {
            ComPtr<ICoreWebView2WebResourceRequest> request;
            args->get_Request(&request);
            LPWSTR uri = nullptr;
            request->get_Uri(&uri);
            if (later && uri && later(uri, args)) {
                CoTaskMemFree(uri);
                return S_OK;
            }
            COREWEBVIEW2_WEB_RESOURCE_CONTEXT context = COREWEBVIEW2_WEB_RESOURCE_CONTEXT_ALL;
            args->get_ResourceContext(&context);
            ComPtr<ICoreWebView2WebResourceResponse> response;
            std::string partDocument;
            if (part && StartsWith(uri, page.c_str()) && !IsOwnPage(uri, page.c_str()) && part(uri, partDocument)) {
                if (partDocument.empty()) {
                    env->CreateWebResourceResponse(nullptr, 404, L"Not Found", L"", &response);
                } else {
                    ComPtr<IStream> stream;
                    stream.Attach(SHCreateMemStream(reinterpret_cast<const BYTE*>(partDocument.data()), static_cast<UINT>(partDocument.size())));
                    env->CreateWebResourceResponse(stream.Get(), 200, L"OK", kDocumentHeaders, &response);
                }
            } else if (context == COREWEBVIEW2_WEB_RESOURCE_CONTEXT_DOCUMENT && IsOwnPage(uri, page.c_str()) && !StartsWith(uri, L"about:")) {
                std::string body = Utf8(serve());
                ComPtr<IStream> stream;
                stream.Attach(SHCreateMemStream(reinterpret_cast<const BYTE*>(body.data()), static_cast<UINT>(body.size())));
                env->CreateWebResourceResponse(stream.Get(), 200, L"OK", kDocumentHeaders, &response);
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

namespace {

double g_textZoom = 1.0;
// held, so a view that goes without UntrackTextZoom is never called through a pointer that is gone
std::vector<ComPtr<ICoreWebView2Controller>> g_zoomed;

}  // namespace

void SetTextZoom(double zoom) {
    g_textZoom = zoom;
    for (const ComPtr<ICoreWebView2Controller>& controller : g_zoomed) {
        controller->put_ZoomFactor(zoom);
    }
}

void TrackTextZoom(ICoreWebView2Controller* controller) {
    controller->put_ZoomFactor(g_textZoom);
    g_zoomed.push_back(controller);
}

void UntrackTextZoom(ICoreWebView2Controller* controller) {
    std::erase_if(g_zoomed, [controller](const ComPtr<ICoreWebView2Controller>& held) { return held.Get() == controller; });
}

int TestTextZoom() {
    double zoom = 0;
    if (g_zoomed.empty() || FAILED(g_zoomed.front()->get_ZoomFactor(&zoom))) {
        return 0;
    }
    return static_cast<int>(zoom * 100 + 0.5);
}

}  // namespace webview
