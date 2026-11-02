// What the WebView2 of the reading pane (preview.cpp) and of the editor (editor.cpp) share: creating one, refusing the
// network, and handing it documents. A document is served for a made-up https address from memory rather than with
// NavigateToString, which takes at most 2 MB, too little for a message with pictures.
#pragma once

#include <windows.h>

#include <functional>
#include <string>

#include <wrl.h>

#include <WebView2.h>

namespace webview {

bool StartsWith(const wchar_t* text, const wchar_t* prefix);

// creates the environment and a controller in `parent`; `ready` gets both, `failed` a message for the user
void Create(HWND parent, std::function<void(ICoreWebView2Environment*, ICoreWebView2Controller*)> ready,
            std::function<void(const std::wstring&)> failed);

// answers every request: `serve` gives the document for the address of the page (`url` is its prefix), anything else
// from the network is refused unless `allow` says otherwise
void FilterRequests(ICoreWebView2* view, ICoreWebView2Environment* environment, const wchar_t* url,
                    std::function<const std::wstring&()> serve, std::function<bool(const wchar_t* uri, COREWEBVIEW2_WEB_RESOURCE_CONTEXT)> allow);

// a picture from the internet, which a page loads only when the user allowed it for the message shown: http(s), an
// image, not the page's own address `url`
bool IsRemoteImage(const wchar_t* uri, COREWEBVIEW2_WEB_RESOURCE_CONTEXT context, const wchar_t* url);

// the settings of a page that runs its own script (the editor, the Print window): its script and its messages to the
// window, and none of dev tools, host objects, script dialogs, the status bar, error pages or the browser keys (F5
// would reload the page, Ctrl+P and Ctrl+F open browser windows); the context menu only when `contextMenu`
void LockDown(ICoreWebView2* view, bool contextMenu);

// the page at `url` is all the view shows: navigation elsewhere is cancelled and no window opens from it
void StayOnPage(ICoreWebView2* view, const wchar_t* url);

// whether `uri` is the page itself (`url`, with or without a query) or one of the documents a page has of its own
bool IsOwnPage(const wchar_t* uri, const wchar_t* url);

}  // namespace webview
