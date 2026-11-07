// The reading pane: a message's header (the brand's logo at its left, the Unsubscribe link and the paper clip of its
// files at its right), the bars under it (a download that failed, an invitation, blocked pictures) and the message
// itself in the locked-down WebView2 (preview.h). The main window has one under its list, each message window one of
// its own. Every string shown was decoded by the core; the body is the sanitized document the core made.
#pragma once

#include <windows.h>

#include <commctrl.h>

#include <cstdint>
#include <functional>
#include <string>

#include "core.h"
#include "preview.h"

struct UiEvent;

class Reader {
public:
    // its controls, children of `parent`; the window hands it what they send (OnCommand, OnNotify, OnDrawItem,
    // OnSetCursor, OnCtlColor), the timers it set on it (OnTimer) and the core's events (OnEvent)
    void Create(HWND parent, PeCore* core);
    // releases the WebView2, the logo and the fonts, before COM is shut down
    void Destroy();
    // places it in `area` of its window, or again where it is
    void Layout(const RECT& area);
    void Layout();
    // the message `uid` of `folder` (of `account`) asked for: the header at once from its row of the list (NULL when
    // there is none), the message once the core has it (MessageReady), or why it can not (MessageFailed)
    void Open(int64_t folder, uint64_t uid, int64_t account, const PeMessage* row);
    // emptied; with "There is no message selected." in it unless a message is `loading`
    void Clear(bool loading = false);
    // a page of the core's in place of a message (how many are selected)
    void ShowPage(const std::wstring& html);
    int64_t Folder() const { return folder_; }
    uint64_t Uid() const { return uid_; }
    // the view of the message shown, NULL until it is there
    const PeMessageInfo* Info() const;
    // its pictures from the internet loaded, once asked
    void LoadPictures();
    // the message as it is shown, with the pictures the user allowed, in the Print window over `owner`
    void Print(HWND owner);
    // a reply, reply to all or forward of the message shown, empty while it is not shown
    core::Draft DraftOf(PeDraftKind kind) const;
    // the Unsubscribe link, after asking over `owner`: what the status bar says; a mailto: link to write a message to
    // in `mailto` when the list wants one
    std::wstring Unsubscribe(HWND owner, std::wstring& mailto);
    // the one-click unsubscribe `request` done, or not for `problem`: what the status bar says, empty for another
    std::wstring Unsubscribed(uint64_t request, const std::wstring& problem);
    // the keys pressed while the message has the keyboard that its window handles (Esc, Delete, the shortcuts with
    // Ctrl): true when handled
    void SetKeys(std::function<bool(UINT key)> keys) { preview_.SetKeys(std::move(keys)); }
    // Find in This Message: the words asked for over `owner` (the last ones filled in), then found and marked; with
    // `again` (F3) while a find of this message goes on, its next place
    void FindInMessage(HWND owner, bool again);
    // called once the message is shown (the main window marks it read a moment later)
    std::function<void()> onShown;
    // called once a find is done: what to say, empty when the words were found
    std::function<void(const std::wstring& said)> onFound;

    void OnEvent(const UiEvent& event);
    bool OnCommand(WORD id, WORD code);
    bool OnNotify(NMHDR* header, LRESULT& result);
    bool OnDrawItem(const DRAWITEMSTRUCT& item);
    bool OnSetCursor(HWND window) const;
    bool OnCtlColor(HWND window, HDC dc, LRESULT& brush) const;
    bool OnTimer(UINT_PTR id);

private:
    // asks the core for the view of the message, built on a worker; ShowView() shows it when it comes
    void StartView();
    void ShowView();
    void ShowHeader(const PeMessageInfo* info);
    void ShowBars(bool files, bool pictures);
    // the bar over a message that could not be downloaded, shown or not
    void ShowRetry(bool shown);
    // Try Again, or the account synced again after the message could not be downloaded
    void Retry();
    void ShowLogo(bool wanted);
    void ShowInvitation(const PeInvitation* event);
    void OpenInCalendar();
    void ChooseAttachment();
    void SaveAllAttachments();

    PeCore* core_ = nullptr;
    HWND parent_ = nullptr;
    RECT area_ = {};
    HWND header_ = nullptr;
    // the paper clip button (a toolbar of one), the information bar of blocked pictures, the one of a failed download
    HWND attachments_ = nullptr;
    HWND pictures_ = nullptr;
    HWND retry_ = nullptr;
    HWND previewHost_ = nullptr;
    HFONT bold_ = nullptr;
    HFONT link_ = nullptr;
    // the icons the invitation bar draws, and their size
    HIMAGELIST icons_ = nullptr;
    int iconSize_ = 16;
    // the Unsubscribe link, and how the message shown lets its reader leave its list (PeMessageInfo)
    HWND unsubscribe_ = nullptr;
    PeUnsubscribe unsubscribeKind_ = PE_UNSUBSCRIBE_NONE;
    std::wstring unsubscribeLink_;
    std::wstring unsubscribeTarget_;
    uint64_t unsubscribeRequest_ = 0;
    // the BIMI logo of the message shown, once the core drew it, and the request it was drawn for
    HWND logo_ = nullptr;
    HBITMAP logoBitmap_ = nullptr;
    uint64_t logoRequest_ = 0;
    int logoSize_ = 0;
    // the event of the message shown, its two lines as the bar shows them
    HWND invitation_ = nullptr;
    HWND openCalendar_ = nullptr;
    std::wstring invitationTitle_;
    std::wstring invitationDetails_;
    Preview preview_;
    // the message shown, its folder and the account of that, 0 for none
    uint64_t uid_ = 0;
    int64_t folder_ = 0;
    int64_t account_ = 0;
    bool remoteImages_ = false;
    core::MessageView view_;
    // the view being built, 0 for none
    uint64_t viewRequest_ = 0;
    // the words of the last Find in This Message
    std::wstring findWords_;
};

// the keys for reading that work while a message has the keyboard as in the list (F3, Ctrl+. and Ctrl+,): the
// command, sent with 1 as its code as the accelerators send theirs; 0 for another key
WORD ReadingKey(UINT key);
