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

// whether `uri` is the page itself (`url`, with or without a query) or one of the documents a page has of its own
bool IsOwnPage(const wchar_t* uri, const wchar_t* url);

}  // namespace webview
