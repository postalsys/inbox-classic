// The reading pane: a message's header (the brand's logo at its left, the paper clip of its files at its right), the
// strip of its files under it, the bars under that (a signed or encrypted message's security bar, a download that
// failed, blocked pictures, a mailing list) and the message itself in the locked-down WebView2 (preview.h). The main window has one under its
// list, each message window one of its own. Every string shown was decoded by the core; the body is the sanitized
// document the core made.
#pragma once

#include <windows.h>

#include <commctrl.h>

#include <cstdint>
#include <functional>
#include <memory>
#include <string>
#include <thread>
#include <vector>

#include "core.h"
#include "preview.h"
#include "stack.h"

struct UiEvent;
struct StripOpened;
struct StripImported;

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
    // a message file (.eml) opened from File Explorer, of no folder: false with why in `error` for a file that is no
    // message the core can read. Its files are saved as a folder's message's are; it has no logo and no Unsubscribe.
    bool OpenFile(const std::wstring& path, std::wstring& error);
    // the message file shown, empty for a message of a folder
    const std::wstring& File() const { return file_; }
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
    // the views of the messages `readers` show built again, after a setting they follow changed (the previews of their
    // files): one after the other, as the core builds one view at a time and drops one started before the newest
    static void Rebuild(std::vector<Reader*> readers);
    // whether the message shown shows its pictures from the internet: asked for, or loaded by themselves (Options'
    // setting, a trusted sender the provider confirmed)
    bool PicturesShown() const;
    // the message as it is shown, with the pictures the user allowed, in the Print window over `owner`
    void Print(HWND owner);
    // File > Print Conversation: every message of the conversation shown, one after another; the message alone
    // outside one
    void PrintConversation(HWND owner);
    // the next message opened is shown in its conversation (Show the whole conversation), not alone
    void SetConversation(bool on) { conversation_ = on; }
    // the view shown is a conversation's
    bool ShowsConversation() const;
    // a reply, reply to all or forward of the message shown, made off the window thread (a message file's at once, from
    // `account`): `done` gets it, empty when the message is not here; false while no message is shown. A newer one
    // replaces one not done yet
    bool DraftOf(PeDraftKind kind, int64_t account, std::function<void(core::Draft)> done);
    // the mailing-list bar's button and Message > Unsubscribe from List, after asking over `owner`: what the status bar
    // says; in `draft` the message to write when the list wants one (the core remembers the list once it is sent)
    std::wstring Unsubscribe(HWND owner, core::Draft& draft);
    // the mailing-list bar offers its button: Unsubscribe from List is on
    bool CanUnsubscribe() const;
    // the one-click unsubscribe `request` done, or not for `problem`: what the status bar says, empty for another
    std::wstring Unsubscribed(uint64_t request, const std::wstring& problem);
    // the keys pressed while the message has the keyboard that its window handles (Esc, Delete, the shortcuts with
    // Ctrl): true when handled
    void SetKeys(std::function<bool(UINT key)> keys) {
        keys_ = keys;
        preview_.SetKeys(std::move(keys));
    }
    // the keyboard to the message itself: the stack's, or the pane's page
    void FocusBody() { SetFocus(stack_.Visible() ? stack_.Hwnd() : previewHost_); }
    // a click in the conversation shown, or Next and Previous Message in Conversation, Open All and Fold All Messages:
    // the core says which message is selected now, and the conversation is shown again where it was
    void ConversationClick(PeConversationClick click, size_t index = 0);
    // Next and Previous Message in Conversation, Open All and Fold All Messages as their clicks; false for another command
    bool ConversationCommand(WORD id);
    // a frame's More menu asks the window the reader is in to act on its one message (Mark as Unread, Delete), to open
    // it in a window of its own, and a draft's Edit to finish it
    std::function<void(int64_t folder, uint64_t uid, PeAction action)> onFrameAction;
    std::function<void(int64_t folder, uint64_t uid)> onOpenMessage;
    std::function<void(int64_t folder, uint64_t uid)> onEditDraft;
    // the UI test's look at the stack (stack.h)
    int64_t TestStack(const std::wstring& ask) { return stack_.Test(ask); }
    // Find in This Message: the words asked for over `owner` (the last ones filled in), then found and marked; with
    // `again` (F3) while a find of this message goes on, its next place
    void FindInMessage(HWND owner, bool again);
    // called once the message is shown (the main window marks it read a moment later)
    std::function<void()> onShown;
    // called once a find is done: what to say, empty when the words were found
    std::function<void(const std::wstring& said)> onFound;
    // Find Key of a signature whose key is not known: what to say while it is looked up, and (`done`) what was found
    std::function<void(const std::wstring& said, bool done)> onKeyLookup;
    // a link clicked in the message: true when it is one of the document's own cards, which this follows
    bool FollowLink(const wchar_t* uri);
    // called when the bounce card's "Show the message that bounced" is clicked, with the message it names
    std::function<void(int64_t folder, uint64_t uid)> onBouncedMessage;
    // called with the path of a message file to open in a message window (Open Reaction Email)
    std::function<void(const std::wstring& path)> onOpenFile;
    // the UI test's look at the parts' frames of the message shown and its requests to the internet (preview.h)
    int64_t TestFrames() { return Body().TestFrames(); }
    int RemoteRequests() const { return const_cast<Reader*>(this)->Body().RemoteRequests(); }
    int64_t TestPreviews(const std::wstring& query) {
        return stack_.Visible() ? stack_.TestPreviews(query) : Body().TestPreviews(query);
    }
    // the UI test's look at the last Find in This Message: how many places it found, -1 before it answered, -2 when
    // this WebView2 can not find
    int TestFound() const { return testFound_; }
    // the UI test's look at the message shown: 1 when one is shown, its document loaded, and its subject is `subject`
    // (any, when empty), else 0
    int TestShown(const std::wstring& subject) const;

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
    // the view in view_ shown: its header, bars and document
    void ShowInfo();
    void ShowHeader(const PeMessageInfo* info);
    // the Reactions line under the header, read again from the core for the message shown (hidden when it has none)
    void LoadReactions();
    // the Reactions line drawn: its label in the header's label column, then one chip a person; where each chip is
    void DrawReactions(const DRAWITEMSTRUCT& item);
    // the chip at `x` of the Reactions line (its client area), -1 for none
    int ReactionAt(int x) const;
    // the menu of the chip `chip` (-1: the keyboard's, a submenu a person when there are several) at `screen`, (-1,
    // -1) for under the line: Open Reaction Email, Show as Email and when they reacted
    void ReactionsMenu(int chip, POINT screen);
    void OpenReactionEmail(const std::shared_ptr<PeReactions>& list, size_t chip);
    static LRESULT CALLBACK ReactionsProc(HWND hwnd, UINT message, WPARAM wParam, LPARAM lParam, UINT_PTR, DWORD_PTR data);
    void ShowBars(bool files, bool pictures);
    // the security bar of a signed or encrypted message, shown or hidden as `info` has it (none: hidden)
    void ShowSecurity(const PeMessageInfo* info);
    // its height `width` wide, 0 when it is hidden
    int SecurityHeight(int width) const;
    // the Details window of the message shown, at part `part` (-1 for the top)
    void ShowSecurityDetails(int part);
    // the menu of the pictures bar's arrow: Always from the sender or from everyone at their domain (only when the
    // provider confirmed the sender, else why not), and Download Pictures
    void ChoosePictures();
    // the bar over a message that could not be downloaded, shown or not
    void ShowRetry(bool shown);
    // the mailing-list bar with the core's words and its button's (none hides it); after ListsChanged as it is then
    void ShowListBar(const std::wstring& text, const std::wstring& button);
    void ListsChanged();
    void ShowDownloading();
    // Try Again, or the account synced again after the message could not be downloaded
    void Retry();
    // the brand's logo when `logo`, else the sender's picture of the Address Book (`picture`, a key of the core's, 0
    // for none), beside the header once drawn
    void ShowLogo(bool logo, uint64_t picture);
    void ShowDrawn(uint8_t* pixels, size_t length);
    void OpenInCalendar();
    void ChooseAttachment();
    void SaveAllAttachments();
    // file `index` of the message saved where the user says, with the Save As dialog once the core read it off the
    // window thread (SaveRead)
    void SaveAttachment(size_t index);
    void SaveRead(uint8_t* data, size_t length, char* name);
    // the reads off the window thread not waited for any more, the window closing
    void CancelReads();
    // the attachment strip: an item a file of `info` (none hides it); placed at `left`, `top`, `width` wide, its
    // height, 0 when it is hidden
    void FillStrip(const PeMessageInfo* info);
    int PlaceStrip(int left, int top, int width);
    // the attachment of item `item` of the strip, NULL for none; its place in the message in `index`
    const PeAttachment* StripAttachment(int item, size_t* index = nullptr) const;
    // the item of the strip of file `index` of the message, -1 for none
    int StripItemOf(int64_t index) const;
    // why a file of the message is not here: it is still being downloaded, or could not be read
    void SayNotHere();
    // the file of an item of the strip opened with the system's program, from the private folder the core wrote it
    // into off the window thread (OpenDone takes the result): a note shown first when the core has one; a file that
    // can run code refused from its row, in the core's words. One at a time; StopOpening waits for it
    void OpenAttachment(int item);
    void OpenDone(StripOpened* opened);
    void StopOpening();
    // the menu of an item of the strip (Open, Save As..., Save All..., Show in Message for a picture or PDF file) at
    // `screen`, (-1, -1) for the keyboard's
    void StripMenu(POINT screen);
    // Show in Message chosen for file `index`: drawn in the message (`show`) or taken out, the view built again
    void ShowInMessage(size_t index, bool show);
    // Import Key chosen for file `index`, a key someone attached: imported as a key file's are, off the window thread;
    // ImportDone says what was imported and builds the view again (a signature by that key now names its signer)
    void ImportAttachedKey(size_t index);
    void ImportDone(StripImported* imported);
    // Find Key on the label of a part signed by a key not known here (`uri` the link): looked up by its fingerprint;
    // KeysFound takes what was found and builds the view again
    void FindSignerKey(const wchar_t* uri);
    void SignerKeyFound(uint64_t request);
    // PreviewsPrepared of the view with this `preview_token`: built again, when it is the one shown
    void PreviewsPrepared(const std::string& token);
    // the printout started by Print is made (PrintReady): printed in the Print window, when it is this reader's
    void PrintReady(uint64_t request);
    // the printout waited for is not any more (another message shown, the pane closing)
    void ForgetPrint();
    static LRESULT CALLBACK StripProc(HWND hwnd, UINT message, WPARAM wParam, LPARAM lParam, UINT_PTR, DWORD_PTR data);
    // a ReadDone: the reply, the file to save or the file to open it was for, if it was this pane's
    void OnReadDone(uint64_t request);
    // the core's calls for the files of the message shown, from its folder or from the message file
    bool SaveAttachments(const std::string& dir, size_t& saved, size_t& total) const;

    PeCore* core_ = nullptr;
    HWND parent_ = nullptr;
    RECT area_ = {};
    HWND header_ = nullptr;
    // the Reactions line under the header's lines (owner-drawn, its words its text for screen readers), the core's
    // list of who reacted it shows (shared, so a menu open keeps the one it was made from) and where each chip is
    HWND reactions_ = nullptr;
    std::shared_ptr<PeReactions> reactionList_;
    std::vector<std::pair<int, int>> reactionSpans_;
    // the paper clip button (a toolbar of one), the information bar of blocked pictures, the one of a failed download
    HWND attachments_ = nullptr;
    // the strip of the files under the header (a list view of small icons), an item a file
    HWND strip_ = nullptr;
    HWND stripFrame_ = nullptr;
    // the files the strip shows (name, size and kind), so it is filled again only when they change
    std::vector<std::wstring> stripFiles_;
    // the open under way and its item, -1 for none: a message file's on a thread of its own, a folder's message's a
    // read of the core (pe_attachment_open_start)
    std::thread opener_;
    // Import Key's thread, and whether it runs
    std::thread importer_;
    bool importing_ = false;
    int openingItem_ = -1;
    uint64_t openRequest_ = 0;
    // the reads of the core waited for (ReadDone): a reply or forward and what takes it, a file to save
    PendingRead draftRead_;
    std::function<void(core::Draft)> draftDone_;
    PendingRead saveRead_;
    // ShowInfo lays the pane out once, at its end
    bool holdLayout_ = false;
    // the bars' words and their push buttons
    HWND pictures_ = nullptr;
    HWND picturesButton_ = nullptr;
    HWND picturesMenu_ = nullptr;
    HWND retry_ = nullptr;
    HWND retryButton_ = nullptr;
    // the security bar over a signed or encrypted message (owner-drawn, its words its text) with its Details button,
    // the state it shows, and the part whose label was clicked for the Details window it opens
    HWND security_ = nullptr;
    HWND securityDetails_ = nullptr;
    PeProtectionTone securityTone_ = PE_PROTECTION_TONE_NONE;
    bool securityLock_ = false;
    int detailsPart_ = -1;
    HWND previewHost_ = nullptr;
    HFONT bold_ = nullptr;
    // the bar over a message of a mailing list (the core's words: the list's domain, or when it was asked) and its
    // button; how the message shown lets its reader leave its list (PeMessageInfo)
    HWND listBar_ = nullptr;
    HWND listButton_ = nullptr;
    PeUnsubscribe unsubscribeKind_ = PE_UNSUBSCRIBE_NONE;
    std::wstring unsubscribeLink_;
    std::wstring unsubscribeTarget_;
    uint64_t unsubscribeRequest_ = 0;
    // the BIMI logo of the message shown, once the core drew it, and the request it was drawn for
    HWND logo_ = nullptr;
    HBITMAP logoBitmap_ = nullptr;
    uint64_t logoRequest_ = 0;
    // the request is the contact's picture (PictureReady), not the logo (LogoReady)
    bool contactPicture_ = false;
    int logoSize_ = 0;
    Preview preview_;
    // the message shown, its folder and the account of that, 0 for none
    uint64_t uid_ = 0;
    // its size from the list, for the page shown while it is downloaded
    uint64_t size_ = 0;
    int64_t folder_ = 0;
    int64_t account_ = 0;
    bool remoteImages_ = false;
    // the message file shown in place of a folder's message
    std::wstring file_;
    core::MessageView view_;
    // the view the stack still shows while the next message loads (its frames point into it), let go once the next
    // view is shown
    core::MessageView stackView_;
    // the view being built, 0 for none
    uint64_t viewRequest_ = 0;
    // its view is built again (Rebuild): the next reader's is started once it is shown
    bool rebuilding_ = false;
    static void RebuildNext();
    // the file of the message whose preview was clicked, opened once the WebView2's event is over; -1 for none
    int64_t previewOpen_ = -1;
    // opened in its conversation
    bool conversation_ = false;
    // the message, or its conversation, as a native stack of rows and frames
    ConversationStack stack_;
    std::function<bool(UINT key)> keys_;
    // the web view of the message shown: the selected frame's, or the pane's own page
    Preview& Body();
    // the message `folder`/`uid` of the conversation shown made the selected one at once, as a frame's button acts on
    // the reader's message; its accent follows when the view is built again
    void SelectFrame(int64_t folder, uint64_t uid);
    // a frame's More menu at `screen`: what else can be done with that one message
    void FrameMenu(int64_t folder, uint64_t uid, POINT screen);
    // the stack in the pane's place, or the pane's own page in the stack's; the selected frame's controls (the
    // Reactions line, the strip) back with the pane when it is not shown
    void ShowStack(bool shown);
    // the preview shows a document of the message shown (not a page of the pane's own): one built again keeps its
    // scroll
    bool documentShown_ = false;
    // the printout of the message with its pictures, made by the core (0 for none), and the window it opens over
    uint64_t printRequest_ = 0;
    HWND printOwner_ = nullptr;
    // the words of the last Find in This Message
    std::wstring findWords_;
    // the lookup Find Key started, 0 for none
    uint64_t keyLookup_ = 0;
    // what the last find answered (TestFound)
    int testFound_ = -1;
};

// the keys for reading that work while a message has the keyboard as in the list (F3, Ctrl+. and Ctrl+,): the
// command, sent with 1 as its code as the accelerators send theirs; 0 for another key
WORD ReadingKey(UINT key);
