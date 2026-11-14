// The message body pane: a WebView2 that shows HTML documents with scripts off and no network access
#pragma once

#include <windows.h>

#include <functional>
#include <string>

#include <wrl.h>

#include <WebView2.h>

#include "inbox_classic.h"

class Preview {
public:
    // creates the WebView2 in `parent` (asynchronously), `onError` gets a message when that fails
    // a find waits for its count on the timer `findTimer` of `owner`, which hands it to FindSettled (none for a view
    // that never finds, the help)
    void Create(HWND parent, std::function<void(const std::wstring&)> onError, HWND owner = nullptr, UINT_PTR findTimer = 0);
    // remoteImages lets images from the network load, for this document only
    void Show(const std::wstring& html, bool remoteImages = false);
    // empty; with "There is no message selected." centered in it, as Outlook Express has it, when `noMessage`
    void Clear(bool noMessage = false);
    // the core's page for a message that is not here: being downloaded, or why it could not be (`reason` in UTF-8)
    // `size`: of the message being downloaded, for PE_READER_STATE_DOWNLOADING (0 when not known)
    void ShowState(PeReaderState state, PeFailureKind failure = PE_FAILURE_KIND_NONE, const std::string& reason = {},
                   uint64_t size = 0);
    // its environment once it is there, NULL before: other views (the Print window) start from it
    ICoreWebView2Environment* Environment() const { return environment_.Get(); }
    // closes the WebView2 and lets go of it, before COM is shut down
    void Close();
    void Resize(const RECT& bounds);
    // WebView2's print preview of the document shown, over the view (the help's Print)
    void Print();
    // WebView2 stops drawing while its window is hidden, the page tells it when it is on screen again
    void SetVisible(bool visible);
    // the keys that do not type (Esc, Delete, those with Ctrl or Alt) pressed while it has the keyboard, for its window:
    // true when the window handled one, which the page then does not get
    void SetKeys(std::function<bool(UINT key)> keys) { keys_ = std::move(keys); }
    // before Create: not at View > Text Size's size, which is for messages (the help keeps its own)
    void KeepOwnSize() { textZoom_ = false; }
    // a link clicked in the document that its window follows itself (the bounce card's): true when it took it, which
    // the browser then does not open
    void SetLinks(std::function<bool(const wchar_t* uri)> links) { links_ = std::move(links); }
    // `words` found in the document shown with WebView2's own find, every place marked and the first in view (no script
    // runs for it); `done` gets how many places there are, 0 for none, -1 when this WebView2 can not find
    void Find(const std::wstring& words, std::function<void(int count)> done);
    // the next place of the words found, while the document they were found in is shown; false when there is none
    bool FindNext();
    // whether words were found in the document shown, for F3 to go to their next place
    bool Finding() const { return find_ && found_ > 0; }
    // the timer of Create: the count of a find is told as it is now
    void FindSettled();
    // the keyboard to the document: at its first link (Tab into it), its last (Shift+Tab), or the document itself; once
    // the WebView2 is there, when it is not yet
    enum class FocusFrom { Start, End, Program };
    void Focus(FocusFrom from);

private:
    void Configure();

    HWND parent_ = nullptr;
    RECT bounds_ = {};
    // the document shown, served when the page asks for it (webview.h)
    std::wstring document_;
    // a document was given before the WebView2 was ready
    bool pending_ = false;
    // the keyboard was given to it before the WebView2 was ready
    bool focusPending_ = false;
    // documents shown, for an address of each
    unsigned shown_ = 0;
    bool remoteImages_ = false;
    bool textZoom_ = true;
    std::function<void(const std::wstring&)> onError_;
    std::function<bool(UINT key)> keys_;
    std::function<bool(const wchar_t* uri)> links_;
    // a link clicked: to the window when it is one of its own, else to the browser
    void Follow(const wchar_t* uri);
    // the find going on in the document shown, and what is told how many places it found once that is known
    Microsoft::WRL::ComPtr<ICoreWebView2Find> find_;
    std::function<void(int count)> findDone_;
    // how many places it found, 0 until it is known
    int found_ = 0;
    HWND owner_ = nullptr;
    UINT_PTR findTimer_ = 0;
    void StopFind();
    // the count told: as soon as there is a place, else once it settled (FindSettled, a moment after the find started)
    void FoundCount(int count, bool settled);
    Microsoft::WRL::ComPtr<ICoreWebView2Environment> environment_;
    Microsoft::WRL::ComPtr<ICoreWebView2Controller> controller_;
    Microsoft::WRL::ComPtr<ICoreWebView2> view_;
};
