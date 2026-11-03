// The editor of the compose window: a WebView2 with the page of pe_editor_document, whose own script (allowed by a
// nonce, nothing else can run) makes the message editable. The page talks back with plain strings: "html:<body>" or
// "full:<body>" (the quote unfolded into it) after Html(), "state:<flags>" for the format bar, "dirty" on the
// first change (after Clean(), the first change since), "drop" with the files dragged onto it, and the addresses of
// the link at the cursor and under the mouse ("caret:", "hover:"). Ctrl+click on a link, or Open Link in its menu,
// opens it in the browser. Network requests are refused and nothing navigates, as in the preview.
#pragma once

#include <windows.h>

#include <functional>
#include <string>
#include <vector>

#include <wrl.h>

#include <WebView2.h>

// where the quoted message is when the page gives its HTML: still folded (the draft's goes with the message), unfolded
// and maybe edited (`edited`, apart from what was written), or unfolded and deleted
enum class EditorQuote { Folded, Edited, Removed };

class Editor {
public:
    struct Handlers {
        std::function<void(const std::wstring&)> error;
        // the body as HTML, after Html(): what was written, and the quote as the page has it (see EditorQuote)
        std::function<void(const std::wstring& html, EditorQuote quote, const std::wstring& edited)> html;
        // one '0' or '1' per format of the bar: bold, italic, underline, numbers, bullets, left, center, right
        std::function<void(const std::wstring&)> state;
        std::function<void()> dirty;
        // Ctrl+Enter
        std::function<void()> send;
        // Ctrl+S
        std::function<void()> save;
        // files dragged from Explorer onto the text, the cursor now where they were dropped
        std::function<void(const std::vector<std::wstring>& paths)> dropped;
        // the address of the link under the mouse, or else of the one the cursor is in, when that changes; empty for none
        std::function<void(const std::wstring& link)> link;
        // Ctrl+K, or Edit Link in the menu of a link: the Link dialog
        std::function<void()> editLink;
    };

    // creates the host window, a child of `parent` with the control id `id`, and the WebView2 in it
    HWND Create(HWND parent, int id, const std::wstring& document, Handlers handlers);
    void Close();
    void Resize(const RECT& bounds);
    // a formatting command of the page (bold, fontName, foreColor, insertImage...); `value` is passed as a string
    void Exec(const wchar_t* command, const std::wstring& value = L"");
    void Link(const std::wstring& url);
    // the signature block (pe_signature_block) of another account in place of the one in the text
    void Signature(const std::wstring& block);
    // asks the page for the body; it comes to Handlers::html
    void Html();
    // the body was saved: the next change is reported as "dirty" again
    void Clean();
    void Focus();
    // the address of the link the cursor is in, empty when none
    const std::wstring& CaretLink() const { return caretLink_; }

private:
    void Configure();
    void Script(const std::wstring& code);
    static std::vector<std::wstring> DroppedFiles(ICoreWebView2WebMessageReceivedEventArgs* args);
    void LinkMenu();
    std::wstring caretLink_;
    std::wstring hoverLink_;
    static LRESULT CALLBACK HostProc(HWND hwnd, UINT message, WPARAM wParam, LPARAM lParam);

    HWND host_ = nullptr;
    std::wstring document_;
    bool focusWhenReady_ = false;
    Handlers handlers_;
    Microsoft::WRL::ComPtr<ICoreWebView2Environment> environment_;
    Microsoft::WRL::ComPtr<ICoreWebView2Controller> controller_;
    Microsoft::WRL::ComPtr<ICoreWebView2> view_;
};
