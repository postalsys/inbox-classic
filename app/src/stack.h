// The reading pane's message, or its whole conversation, as a native stack (docs/conversation-view-plan.md): a child
// window of the pane that draws the conversation's rows and the headers of its frames itself, in the classic look,
// with a push button for each thing a frame offers (Reply, Reply All, Forward, More; Edit for a draft) and a WebView2
// for each open message's body (preview.h) as tall as its document, the stack scrolling as one. The words and the
// choices are the core's (pe_conversation_entry); a click is handed to the reader, which asks the core
// (pe_conversation_click) and shows the view again, the frames of the same messages kept with their WebView2s.
#pragma once

#include <windows.h>

#include <cstdint>
#include <functional>
#include <map>
#include <memory>
#include <string>
#include <vector>

#include "core.h"
#include "preview.h"

class ListPictures;

class ConversationStack {
public:
    ConversationStack();
    ~ConversationStack();
    // what the stack asks of the reader
    struct Hooks {
        // the timer of the owner window that tells a body's Find it has settled (Preview::FindSettled)
        UINT_PTR findTimer = 0;
        // a click on a row, a frame or an arrow, the folded middle's row, Left and Right: `index` the entry's
        std::function<void(PeConversationClick click, size_t index)> click;
        // a frame's Reply, Reply All or Forward (`command` its IDM_), its More menu at `screen`, a draft's Edit, a
        // double-click: on the message `folder`/`uid` (0, 0 for a message shown alone: the reader's own)
        std::function<void(WORD command, int64_t folder, uint64_t uid)> command;
        std::function<void(int64_t folder, uint64_t uid, POINT screen)> more;
        std::function<void(int64_t folder, uint64_t uid)> edit;
        std::function<void(int64_t folder, uint64_t uid)> openWindow;
        // a link clicked in a frame's document: true when the reader took it
        std::function<bool(const wchar_t* uri)> links;
        // the keys a body hands to its window (Esc, Delete, the shortcuts with Ctrl): true when handled
        std::function<bool(UINT key)> keys;
        // the selected frame's own: the Reactions line under its header and the strip of its files under its body,
        // placed at `left`, `top`, `width` wide in the stack's client area; their height, 0 when hidden
        std::function<int(int left, int top, int width)> placeReactions;
        std::function<int(int left, int top, int width)> placeFiles;
        // the selected frame's paper clip (its files' menu), placed with its right edge at `right`, vertically centered
        // on `middle`; its width, 0 when hidden
        std::function<int(int right, int middle)> placeClip;
    };

    void Create(HWND parent, PeCore* core, Hooks hooks);
    // the WebView2s let go, before COM is shut down
    void Destroy();
    // `view` (its selected message's, owned by the reader and kept while shown) as rows and frames; `pictures` lets the
    // selected message's pictures through; `start` scrolls to the selected message (a conversation shown anew)
    void Show(PeMessageView* view, bool pictures, bool start);
    // nothing shown: the frames and their WebView2s let go
    void Clear();
    // placed at `bounds` of the pane's window, shown or hidden
    void Move(const RECT& bounds);
    void SetVisible(bool visible);
    bool Visible() const { return IsWindowVisible(hwnd_) != FALSE; }
    HWND Hwnd() const { return hwnd_; }
    // the selected frame's body: Find, Print, the keyboard and the UI test act on it; NULL while it is not made
    Preview* SelectedBody();
    // the UI test's look at the selected body's previews (Preview::TestPreviews), the stack standing in for the page's
    // own scroll: "scroll" and "scroll:N" are the stack's, measured from the body's top, "tall" the body's height and
    // whether it scrolls by itself, and a point outside what is seen is scrolled to first (-1 then, the test asks again)
    int64_t TestPreviews(const std::wstring& query);
    // a picture the core drew (PictureReady): the rows and frames with its key drawn again
    void PictureReady(uint64_t request);
    // the selected message's own picture, drawn for its view (a message alone: its brand's logo, its contact's
    // picture), `size` pixels square; owned by the reader, NULL when it lets it go
    void SetSelectedPicture(HBITMAP bitmap, int size);
    // the UI test (kTestStack): "shown" says what the stack shows (frames * 100 + rows * 10 + the selected one's place
    // among the frames, 1000 more when every frame's body is as tall as its message), "select N", "toggle N" and
    // "button N name" act on the Nth message of the stack as a click does, "middle" clicks the folded middle's row,
    // "text N words" says whether message N's document has them; -1 for nothing to act on
    int64_t Test(const std::wstring& ask);

private:
    struct Entry {
        int64_t folder = 0;
        uint64_t uid = 0;
        size_t index = 0;
        std::wstring from, when, words, to, inFolder, foundIn, note, reactions, initials, hiddenText;
        int64_t date = 0;
        bool draft = false, unread = false, open = false, selected = false, attachments = false;
        uint64_t picture = 0;
        size_t hiddenBefore = 0;
    };
    struct Frame {
        Entry entry;
        // the view its body shows (the reader's, or the conversation's open message's own, owned by the reader's view)
        PeMessageView* view = nullptr;
        std::wstring document;
        std::wstring token;
        bool pictures = false;
        // the names of its files, which it shows under its body while it is not selected; empty for none
        std::wstring files;
        // the window its WebView2 is in, and the WebView2, made near what is seen and let go far from it
        HWND host = nullptr;
        std::unique_ptr<Preview> body;
        // the body's height, as measured last (kept while it is let go); the measuring timer's ticks since it was last
        // asked to measure, how many slow readings in a row found the same height, and whether it is settled (measured
        // no more until something can change its height)
        int height = 0;
        // its document is taller than a body is made (pe_stack_body_max): the body scrolls by itself, the wheel over
        // it its own
        bool scrollsItself = false;
        int measured = 0;
        int steady = 0;
        bool settled = false;
        // its buttons, in order, and the commands they are
        std::vector<std::pair<HWND, WORD>> buttons;
        // where it is in the stack (its top at 0 of the stack's whole height), its header's top and height, and where
        // its body is, as Layout placed them
        RECT rect = {};
        int headerTop = 0;
        int header = 0;
        RECT bodyRect = {};
    };
    struct Row {
        Entry entry;
        RECT rect = {};
        // the first and the last of the rows next to each other, one sunken box; the box's top, on the last
        bool first = false;
        bool last = false;
        int boxTop = 0;
    };
    struct Gap {
        size_t index = 0;
        std::wstring words;
        RECT rect = {};
    };
    struct Key {
        int64_t folder;
        uint64_t uid;
        bool operator<(const Key& other) const { return folder != other.folder ? folder < other.folder : uid < other.uid; }
    };

    static LRESULT CALLBACK Proc(HWND hwnd, UINT message, WPARAM wParam, LPARAM lParam);
    static LRESULT CALLBACK MouseHook(int code, WPARAM wParam, LPARAM lParam);
    // whether `under` is in the window of a body that scrolls by itself
    bool ScrollsItself(HWND under) const;
    LRESULT Handle(UINT message, WPARAM wParam, LPARAM lParam);
    // every row, gap and frame placed for the client width, the scroll bar set, the children moved
    void Layout();
    // the children (buttons, bodies, the selected frame's own) moved where the scroll puts them
    void PlaceChildren();
    void Paint(HDC dc, const RECT& dirty);
    void PaintFrame(HDC dc, const Frame& frame, int offset);
    void PaintRow(HDC dc, const Row& row, int offset);
    void PaintPicture(HDC dc, const RECT& box, const Entry& entry, bool framed);
    int PictureLeft(int boxLeft) const;
    int HeaderRight(int boxRight) const;
    void ScrollTo(int y);
    // the bodies near what is seen made, those far from it let go
    void Live();
    void MakeBody(Frame& frame);
    // the frame's document (frame.document) shown in its body, `info` the frame's view's
    void LoadBody(Frame& frame, const PeMessageInfo* info);
    void LetGo(Frame& frame);
    // the bodies not settled measured (the measuring timer), their heights changed laid out once after
    void MeasureBodies();
    // the frame's body measured again, often at first (made, another document, its width or text size changed, a click
    // in it), the measuring timer started
    void Unsettle(Frame& frame);
    // the hovered row `row` (-1 for none) drawn again
    void InvalidateRow(int row);
    Frame* SelectedFrame();
    // what is at `point` of the client area: the frame or row, and whether it is its arrow; NULL for none
    const Entry* Hit(POINT point, bool* arrow, bool* gap = nullptr);
    void Click(POINT point, bool twice);
    static Entry Copy(const PeConversationEntry& entry);

    HWND hwnd_ = nullptr;
    PeCore* core_ = nullptr;
    Hooks hooks_;
    HFONT bold_ = nullptr;
    HFONT title_ = nullptr;
    PeMessageView* view_ = nullptr;
    // whether `view_` is a conversation's (not a message alone, which has no arrows)
    bool conversation_ = false;
    std::wstring subject_, summary_;
    std::map<Key, Frame> frames_;
    std::vector<Row> rows_;
    std::vector<Gap> gaps_;
    // the order of what is shown: a frame's key, or a row's or gap's place in rows_ or gaps_
    struct Item {
        enum Kind { FrameItem, RowItem, GapItem } kind;
        Key key{0, 0};
        size_t place = 0;
    };
    std::vector<Item> items_;
    int scroll_ = 0;
    int total_ = 0;
    int titleHeight_ = 0;
    // the client width the bodies were measured at, and whether a layout for their new heights is posted
    int width_ = 0;
    bool placePosted_ = false;
    WORD nextId_ = 100;
    std::unique_ptr<ListPictures> pictures_;
    HDC pictureDc_ = nullptr;
    // the row the mouse is over, for its highlight; -1 for none
    int hot_ = -1;
    HBITMAP selectedPicture_ = nullptr;
    int selectedPictureSize_ = 0;
};
