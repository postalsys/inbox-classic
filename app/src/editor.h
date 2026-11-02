// The editor of the compose window: a WebView2 with the page of pe_editor_document, whose own script (allowed by a
// nonce, nothing else can run) makes the message editable. The page talks back with plain strings: "html:<body>" or
// "full:<body>" (the quote unfolded into it) after Html(), "state:<flags>" for the format bar and "dirty" on the
// first change. Network requests are refused and nothing navigates, as in the preview.
#pragma once

#include <windows.h>

#include <functional>
#include <string>

#include <wrl.h>

#include <WebView2.h>

class Editor {
public:
    struct Handlers {
        std::function<void(const std::wstring&)> error;
        // the body as HTML, after Html(); `full` when the quote is in it already (unfolded), so it is not added again
        std::function<void(const std::wstring&, bool full)> html;
        // one '0' or '1' per format of the bar: bold, italic, underline, numbers, bullets, left, center, right
        std::function<void(const std::wstring&)> state;
        std::function<void()> dirty;
        // Ctrl+Enter
        std::function<void()> send;
    };

    // creates the host window, a child of `parent` with the control id `id`, and the WebView2 in it
    HWND Create(HWND parent, int id, const std::wstring& document, Handlers handlers);
    void Close();
    void Resize(const RECT& bounds);
    // a formatting command of the page (bold, fontName, foreColor, insertImage...); `value` is passed as a string
    void Exec(const wchar_t* command, const std::wstring& value = L"");
    void Link(const std::wstring& url);
    // asks the page for the body; it comes to Handlers::html
    void Html();
    void Focus();

private:
    void Configure();
    void Script(const std::wstring& code);
    static LRESULT CALLBACK HostProc(HWND hwnd, UINT message, WPARAM wParam, LPARAM lParam);

    HWND host_ = nullptr;
    std::wstring document_;
    bool focusWhenReady_ = false;
    Handlers handlers_;
    Microsoft::WRL::ComPtr<ICoreWebView2Environment> environment_;
    Microsoft::WRL::ComPtr<ICoreWebView2Controller> controller_;
    Microsoft::WRL::ComPtr<ICoreWebView2> view_;
};
