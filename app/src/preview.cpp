// WebView2 for message bodies. The documents come from the Rust core (pe_html_render) sanitized and with a
// Content-Security-Policy that allows only embedded images; on top of that scripts are off, every http(s) request is
// refused here and links open in the default browser instead of in the pane. The C++ side never changes a document.
#include "preview.h"

#include <shellapi.h>

#include "core.h"
#include "webview.h"

using Microsoft::WRL::Callback;
using Microsoft::WRL::ComPtr;
using webview::OpenExternally;
using webview::StartsWith;

namespace {

// where the documents are served from memory (webview.h); .invalid never resolves
const wchar_t* kPageUrl = L"https://preview.inboxclassic.invalid/";


}  // namespace

void Preview::Create(HWND parent, std::function<void(const std::wstring&)> onError) {
    parent_ = parent;
    onError_ = std::move(onError);
    webview::Create(
        parent_,
        [this](ICoreWebView2Environment* environment, ICoreWebView2Controller* controller) {
            environment_ = environment;
            controller_ = controller;
            controller_->get_CoreWebView2(&view_);
            Configure();
        },
        [this](const std::wstring& error) { onError_(error + L" Message bodies can not be shown."); });
}

void Preview::Configure() {
    ComPtr<ICoreWebView2Settings> settings;
    view_->get_Settings(&settings);
    settings->put_IsScriptEnabled(FALSE);
    settings->put_AreDefaultScriptDialogsEnabled(FALSE);
    settings->put_IsWebMessageEnabled(FALSE);
    settings->put_AreHostObjectsAllowed(FALSE);
    settings->put_AreDevToolsEnabled(FALSE);
    settings->put_IsStatusBarEnabled(FALSE);
    settings->put_IsZoomControlEnabled(TRUE);

    // the document from memory; nothing from the network, also not what a CSP would let through, but images when the
    // user asked for them
    webview::FilterRequests(
        view_.Get(), environment_.Get(), kPageUrl, [this]() -> const std::wstring& { return document_; },
        [this](const wchar_t* uri, COREWEBVIEW2_WEB_RESOURCE_CONTEXT context) {
            return remoteImages_ && webview::IsRemoteImage(uri, context, kPageUrl);
        });

    // links open in the browser, the pane only ever shows the documents it is given
    view_->add_NavigationStarting(
        Callback<ICoreWebView2NavigationStartingEventHandler>([](ICoreWebView2*, ICoreWebView2NavigationStartingEventArgs* args) {
            LPWSTR uri = nullptr;
            args->get_Uri(&uri);
            if (!webview::IsOwnPage(uri, kPageUrl)) {
                args->put_Cancel(TRUE);
                BOOL user = FALSE;
                args->get_IsUserInitiated(&user);
                // a relative link of the message points into the made-up address, not anywhere
                if (user && !StartsWith(uri, kPageUrl)) {
                    OpenExternally(uri);
                }
            }
            CoTaskMemFree(uri);
            return S_OK;
        }).Get(),
        nullptr);
    view_->add_NewWindowRequested(
        Callback<ICoreWebView2NewWindowRequestedEventHandler>([](ICoreWebView2*, ICoreWebView2NewWindowRequestedEventArgs* args) {
            LPWSTR uri = nullptr;
            args->get_Uri(&uri);
            args->put_Handled(TRUE);
            OpenExternally(uri);
            CoTaskMemFree(uri);
            return S_OK;
        }).Get(),
        nullptr);

    controller_->put_Bounds(bounds_);
    controller_->put_IsVisible(IsWindowVisible(parent_) ? TRUE : FALSE);
    if (pending_) {
        Show(document_, remoteImages_);
    } else {
        Clear();
    }
}

void Preview::Show(const std::wstring& html, bool remoteImages) {
    remoteImages_ = remoteImages;
    document_ = html;
    if (!view_) {
        pending_ = true;
        return;
    }
    pending_ = false;
    // a new address for each document, so it is loaded again rather than taken from history
    std::wstring url = std::wstring(kPageUrl) + L"?" + std::to_wstring(++shown_);
    view_->Navigate(url.c_str());
}

void Preview::Clear(bool noMessage) {
    if (noMessage) {
        ShowState(PE_READER_STATE_NO_MESSAGE);
        return;
    }
    // white like the documents of messages, also when Windows uses dark mode
    Show(L"<!doctype html><html><head><meta name=\"color-scheme\" content=\"light\"><style>html{background:#fff}</style>"
         L"</head><body></body></html>");
}

void Preview::ShowState(PeReaderState state, PeFailureKind failure, const std::string& reason) {
    core::String page(pe_reader_page(state, failure, reason.c_str()));
    Show(page ? core::Widen(page.get()) : L"");
}

void Preview::SetVisible(bool visible) {
    if (controller_) {
        controller_->put_IsVisible(visible ? TRUE : FALSE);
    }
}

void Preview::Resize(const RECT& bounds) {
    bounds_ = bounds;
    if (controller_) {
        controller_->put_Bounds(bounds);
    }
}

void Preview::Close() {
    if (controller_) {
        controller_->Close();
    }
    view_.Reset();
    controller_.Reset();
    environment_.Reset();
}
