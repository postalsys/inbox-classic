// The message body pane: a WebView2 that shows HTML documents with scripts off and no network access
#pragma once

#include <windows.h>

#include <functional>
#include <map>
#include <string>
#include <vector>

#include <wrl.h>

#include <WebView2.h>

#include "inbox_classic.h"

class Preview {
public:
    // creates the WebView2 in `parent` (asynchronously), `onError` gets a message when that fails
    // a find waits for its count on the timer `findTimer` of `owner`, which hands it to FindSettled (none for a view
    // that never finds, the help)
    void Create(HWND parent, std::function<void(const std::wstring&)> onError, HWND owner = nullptr, UINT_PTR findTimer = 0);
    // remoteImages lets images from the network load, for this document only. `parts`: the documents of a page of
    // parts (a signed or encrypted message, UTF-8), each in a frame of its own that asks for `part-N` beside the page;
    // their frames are sized to their documents once it loaded and on each Measure()
    // `previewToken`: the token of the view whose document it is (PeMessageInfo.preview_token), whose previews' pictures
    // its page asks for under /pv/ (ServePreviews); the previews of the document before are ended
    // `keepScroll`: the same message's document again (Show in Message, the whole message after its text), shown where
    // the one before was scrolled to (pe_scroll_script read first, pe_scroll_to_script once it has loaded)
    void Show(const std::wstring& html, bool remoteImages = false, std::vector<std::string> parts = {}, const char* previewToken = nullptr,
              bool keepScroll = false);
    // before Create: the pictures of the previews of attachments its documents show, asked of `core` (pe_preview_ask)
    // and answered once the core has them (Answered), never waited for on the window thread
    void ServePreviews(PeCore* core) { core_ = core; }
    // a PreviewAnswered of the core: the Preview that keeps that ask answers its page, with the picture or "not found";
    // an ask no Preview keeps any more (its document gone) is taken from the core all the same
    static void Answered(PeCore* core, uint64_t ask);
    // the UI test's look at the previews of the document shown, as TestFrames: `query` "state" (how many pictures,
    // how many of them loaded, how many are PDF pages, and whether the section has a notice), "photo"/"second"/"last"
    // (the middle of the first, second or last file's first picture, scrolled into view, on the screen), "more" (the
    // link to all of a PDF file's pages, likewise), "overflow" (how far the page is wider than the pane); -1 before
    // there is an answer; "tiles" (the files shown as tiles times 100, plus how many of them say why), "scroll" (how
    // far down the document is scrolled, plus 1), "scroll:N" (scrolled to N, then as "scroll"), "text:WORDS" (2
    // when the document's text has the words, letters, digits and spaces only, else 1), "inline" (the pictures of the
    // text: 100,000 for each with a data: or cid: address, plus 10,000 when the first is served from /pv/, plus its
    // width once loaded), "banner" (the middle of the text's first picture, as "photo"), "menu" (the items of the last
    // context menu after TrimMenu: 1,000, plus 100 with Copy Link, 10 with Copy Image, 1 with any other image item)
    int64_t TestPreviews(const std::wstring& query);
    // the frames of the page shown sized again to their documents (the core's script, run by the app with the page's
    // own scripts off), when it is a page of parts
    void Measure();
    // the UI test's look at the frames of the page shown: the answer to the last look (how many frames, plus 100 when
    // each is as tall as its document, plus 1000 times their heights in pixels; -1 before there is one), and looks
    // again
    int64_t TestFrames();
    // the requests to the internet the document shown made (allowed or refused), for the UI test
    int RemoteRequests() const { return remoteRequests_; }
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
    // Alt with a letter while it has the keyboard clicks the button of its window that has that letter (ClickMnemonic)
    void TakeMnemonics() { mnemonics_ = true; }
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
    // a document to show (Show), held while the scroll of the one shown is read
    struct Next {
        std::wstring html;
        bool remoteImages = false;
        std::vector<std::string> parts;
        std::string previewToken;
    };
    // `next` shown in place of the document shown, scrolled to `scrollTo` once it has loaded (none when negative)
    void Put(Next next, double scrollTo);
    // DOMContentLoaded: the document loading scrolled to scrollTo_, when it is the one that keeps the scroll
    void Scrolled();
    // the document given (document_) loaded, at an address of its own
    void Load();
    // a request of the page for a preview's picture (under /pv/): kept until the core answers it (Answered), or
    // answered "not found" now; true when it was one
    bool AskPreview(const wchar_t* uri, ICoreWebView2WebResourceRequestedEventArgs* args);
    // the picture of `ask` given to the page (NULL: "not found"), its request finished
    void Answer(uint64_t ask, const PePreviewPicture* picture);
    // the document shown no longer: the core told, its requests still waiting finished with "not found"
    void EndPreviews();
    // the empty "not found" answer to a request (null without the environment)
    Microsoft::WRL::ComPtr<ICoreWebView2WebResourceResponse> NotFound() const;
    // the reading pane's own menu: the browser's items for saving or opening a picture the core drew taken off (the
    // picture is Inbox Classic's copy, not the file), and those of a preview's link; a link to the web keeps its own
    void TrimMenu();

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
    // documents asked for (Show): a scroll read for one that is not the newest is dropped
    unsigned asked_ = 0;
    // where the document loading is scrolled to once its DOM is there (none when negative), and its address
    double scrollTo_ = -1;
    std::wstring scrollPage_;
    bool remoteImages_ = false;
    // the documents of the parts of the page shown, in frames sized by Measure(); none for another page
    std::vector<std::string> parts_;
    // the core its previews are asked of (none: the help, which has none), the token of the document shown, and its
    // requests waiting for their pictures, by their asks
    PeCore* core_ = nullptr;
    std::string previewToken_;
    struct Waiting {
        Microsoft::WRL::ComPtr<ICoreWebView2WebResourceRequestedEventArgs> args;
        Microsoft::WRL::ComPtr<ICoreWebView2Deferral> deferral;
    };
    std::map<uint64_t, Waiting> waiting_;
    std::map<std::wstring, int64_t> testPreviews_;
    // what the last context menu offered, for the UI test ("menu")
    int64_t testMenu_ = -1;
    int remoteRequests_ = 0;
    int64_t testFrames_ = -1;
    bool textZoom_ = true;
    bool mnemonics_ = false;
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
