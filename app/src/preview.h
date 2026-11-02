// The message body pane: a WebView2 that shows HTML documents with scripts off and no network access
#pragma once

#include <windows.h>

#include <functional>
#include <string>

#include <wrl.h>

#include <WebView2.h>

class Preview {
public:
    // creates the WebView2 in `parent` (asynchronously), `onError` gets a message when that fails
    void Create(HWND parent, std::function<void(const std::wstring&)> onError);
    // remoteImages lets images from the network load, for this document only
    void Show(const std::wstring& html, bool remoteImages = false);
    // empty; with "There is no message selected." centered in it, as Outlook Express has it, when `noMessage`
    void Clear(bool noMessage = false);
    // closes the WebView2 and lets go of it, before COM is shut down
    void Close();
    void Resize(const RECT& bounds);
    // WebView2 stops drawing while its window is hidden, the page tells it when it is on screen again
    void SetVisible(bool visible);

private:
    void Configure();

    HWND parent_ = nullptr;
    RECT bounds_ = {};
    // the document shown, served when the page asks for it (webview.h)
    std::wstring document_;
    // a document was given before the WebView2 was ready
    bool pending_ = false;
    // documents shown, for an address of each
    unsigned shown_ = 0;
    bool remoteImages_ = false;
    std::function<void(const std::wstring&)> onError_;
    Microsoft::WRL::ComPtr<ICoreWebView2Environment> environment_;
    Microsoft::WRL::ComPtr<ICoreWebView2Controller> controller_;
    Microsoft::WRL::ComPtr<ICoreWebView2> view_;
};
