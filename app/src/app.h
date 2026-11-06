// Shared pieces of the windows: DPI scaling, child controls, text formatting and the small dialogs. Everything shown
// comes from the core (core.h) already decoded; nothing here parses mail data.
#pragma once

#include <windows.h>

#include <commctrl.h>
#include <functional>
#include <optional>

#include <cstdint>
#include <string>
#include <unordered_map>
#include <unordered_set>
#include <vector>

#include "commands.h"
#include "core.h"
#include "preview.h"

// ---- ui.cpp ----

// the window whose DPI Scale() uses
void SetScaleWindow(HWND window);
// pixels at 96 DPI to pixels at the DPI of the main window
int Scale(int value);
HWND CreateChild(HWND parent, const wchar_t* className, const wchar_t* text, DWORD style, int id, const RECT& bounds,
                 DWORD exStyle = 0);
std::wstring GetWindowString(HWND window);
// a UTF-8 string from the core, NULL as empty
std::wstring Text(const char* utf8);
// a date in seconds since the Unix epoch in the user's short date and time format, local time
std::wstring FormatDate(int64_t seconds);
// a time of day as the user's settings write it, without seconds: of `local`, or now
std::wstring FormatTime(const SYSTEMTIME& local);
// seconds since the Unix epoch as a SYSTEMTIME, the reader's local time when `local`, else UTC; false for a date
// Windows can not hold
bool UnixToSystemTime(int64_t seconds, bool local, SYSTEMTIME& time);
std::wstring TimeNow();
// 1.2 KB, 3 MB
std::wstring FormatSize(uint64_t bytes);
// the brush of dialog backgrounds, for WM_CTLCOLORSTATIC
LRESULT ButtonFaceColor(HDC dc);

// the Move and Copy window (folderpicker.cpp): its rows and their filtering come from the core (pe_move_targets)
struct FolderPick {
    PeCore* core = nullptr;
    std::wstring title;
    std::wstring prompt;
    // the button: Move or Copy
    std::wstring verb;
    // the folder the messages are all in, 0 for several
    int64_t current = 0;
    // New Folder in `parent` (0: at the top of `account`), from the window `owner`
    std::function<void(HWND owner, int64_t account, int64_t parent)> newFolder;
};
// shows it until a folder is chosen (its id) or it is cancelled (0)
int64_t PickFolder(HWND owner, FolderPick& pick);
// the open one shows its folders again (they changed), with `highlight` highlighted when not 0
void RefreshFolderPick(int64_t highlight);

struct FormField {
    enum class Kind { Text, Password, Number, Choice };
    std::wstring label;
    std::wstring value;
    Kind kind = Kind::Text;
    // for Choice: the options; `value` is the chosen one, `chosen` its position (-1 for none), which tells apart
    // options that read the same
    std::vector<std::wstring> choices;
    int chosen = -1;
};

// a column of a report list view, `width` at 96 DPI
void AddColumn(HWND list, int index, const wchar_t* name, int width, int format = LVCFMT_LEFT);
// the list of a dialog (Accounts, Outbox): one row selected at a time, full rows, columns that do not sort
HWND CreateReportList(HWND parent, int id, const RECT& bounds);
// a row with the text of its first column; its index
int AddRow(HWND list, int index, const std::wstring& text);
void SetCell(HWND list, int row, int column, const std::wstring& text);
// selects and focuses `row`, or the last one when there are fewer
void SelectRow(HWND list, int row);

// the icon strips of app/res/toolbar (icons.h): their image list at the size closest to the DPI, loaded once
enum class IconSet { Toolbar, Format, Folders, List };
HIMAGELIST IconList(IconSet set);
// text for a menu item: a & in it stays a & rather than making the next character a shortcut
std::wstring MenuText(std::wstring text);
// a menu item of the catalogs (`&` marking its letter) with its shortcut, the key names in the language in use:
// MenuItem(PE_TEXT_CMD_PRINT, L"Ctrl+P") is "&Drucken...\tStrg+P" in German
std::wstring MenuItem(PeText text, std::wstring_view keys = {});
// a flat toolbar, a child of `hwnd`; `style` adds CCS_* and TBSTYLE_* styles. Its icons (icons.h): the big ones with
// the label under them (main and compose windows), or the small ones of the format bar, the label as the tooltip
enum class BarIcons { Big, Small };
HWND CreateBar(HWND hwnd, DWORD style, int id, BarIcons icons);
// a button on a bar of CreateBar, with its icon (icons.h) or I_IMAGENONE; id 0 is a separator
void AddButton(HWND bar, int id, const wchar_t* text, BYTE style = BTNS_BUTTON, int image = I_IMAGENONE);

// a tree row with its text, data, boldness and icon of the folder strip, last under `parent`
HTREEITEM InsertItem(HWND tree, HTREEITEM parent, const std::wstring& text, LPARAM data, bool bold, int icon);
// how wide the words of a control are in `font` (the dialog font when NULL), its & left out
int TextWidth(HWND control, HFONT font);

// how big `text` is in the dialog font, its & left out: one line, or wrapped at `wrapWidth` when it is not 0
SIZE MeasureText(const std::wstring& text, int wrapWidth = 0);
// a push button wide enough for the longest of `labels`, at least `least` pixels at 96 DPI
int ButtonWidth(std::initializer_list<std::wstring> labels, int least = 80);

// a modal form with a label and an input for each field; true with the values filled in when OK was clicked.
// `validate` gets the values and returns an error to show, or an empty string to accept them.
// `okLabel`: the default button, OK when null. `focus`: the field to start in
bool FormDialog(HWND owner, const std::wstring& title, const std::wstring& intro, std::vector<FormField>& fields,
                bool (*validate)(const std::vector<FormField>&, std::wstring& error) = nullptr, const wchar_t* okLabel = nullptr,
                size_t focus = 0);
// an owner-drawn button (CreateLinkButton) drawn as a link: underlined, in the link color, a focus rectangle around
// the words
void DrawLinkButton(const DRAWITEMSTRUCT& item);
// a button that looks like a link (draw it with DrawLinkButton); Tab reaches it and Enter or Space clicks it
HWND CreateLinkButton(HWND parent, const wchar_t* text, int id, const RECT& bounds);
// for WM_SETCURSOR of the window with the links: the hand over a link; true when it set it
bool SetLinkCursor(HWND hwnd, WPARAM wParam);
// what a screen reader says about a control besides its name (the reason a button is turned off)
void SetAccessibleDescription(HWND control, const std::wstring& text);
// a dialog window centered on the window of `owner`, owned by it, with this client size; RunModal shows it, runs it
// until `done` and destroys it, the owner disabled meanwhile
HWND CreateModalWindow(HWND owner, const wchar_t* className, const wchar_t* title, int clientWidth, int clientHeight);
void RunModal(HWND dialog, HWND focus, const bool& done);
// the path to save an attachment to, starting from the safe name the core made; empty when cancelled
// (title and filter those of an attachment when null)
std::wstring SaveFileDialog(HWND owner, const std::wstring& name, const wchar_t* title = nullptr, const wchar_t* filter = nullptr,
                           const wchar_t* extension = nullptr);
// the filter of a file dialog (lpstrFilter): each kind a name and its patterns, "*.eml" or "*.png;*.gif"
std::wstring FileFilter(std::initializer_list<std::pair<std::wstring, std::wstring>> kinds);
// `text` with its line breaks as CRLF, as an edit box shows them
std::wstring WithCrlf(const std::wstring& text);
// a modal window that can be resized with `text` (a message's source) in a fixed-width font to read and copy, Save
// As (`save`, given the window) and Close
void SourceDialog(HWND owner, const std::wstring& title, const std::wstring& text, const std::function<void(HWND)>& save);
// a modal window with `text` to read and copy in a box that can not be edited, and OK (Message Properties)
void TextDialog(HWND owner, const std::wstring& title, const std::wstring& intro, const std::wstring& text);
// a PNG picture of the exe's resources (RCDATA, app.rc) as a bitmap `height` pixels high over `background`, as wide
// (`width`) as that keeps its proportions; NULL, and `width` left as it was, when it can not be made
constexpr int IDR_GOOGLE_SIGN_IN = 3;
constexpr int IDR_MICROSOFT_SIGN_IN = 4;
HBITMAP LoadPicture(int resource, int height, COLORREF background, int& width);
// registers a window class of a dialog (button face background, arrow cursor) once
void RegisterDialogClass(const wchar_t* name, WNDPROC proc);
// the app's icon (app.rc): the small one of the title bar, or the large one of Alt+Tab
HICON AppIcon(bool titleBar);
// both for a window class
void SetAppIcons(WNDCLASSEXW& windowClass);
// a folder chosen in the Windows folder picker, empty when cancelled
std::wstring FolderDialog(HWND owner, const wchar_t* title);
// the files chosen in an Open dialog that takes several, none when cancelled
std::vector<std::wstring> OpenFilesDialog(HWND owner, const wchar_t* title, const wchar_t* filter);
bool WriteFileBytes(const std::wstring& path, const uint8_t* data, size_t size);
// marks a saved file (an attachment, a message) as from the internet, for SmartScreen and Office's Protected View
void MarkFromInternet(const std::wstring& path);

// ---- dragdrop.cpp: messages as files with OLE ----

struct IDataObject;
struct IDropTarget;

// what a drag over a window of the app carries: messages of its own list, .eml files (only), or nothing it takes
enum class DropFrom { Nothing, Messages, Files };
// a window that takes drops: where it would go and what the drag does there, and the drop
struct DropSite {
    virtual ~DropSite() = default;
    // the effect a drag of `from` would have at `screen` (DROPEFFECT_*), the place highlighted
    virtual DWORD Over(DropFrom from, POINT screen, DWORD keys, DWORD allowed) = 0;
    virtual void Leave() = 0;
    virtual DWORD Dropped(IDataObject* data, DropFrom from, POINT screen, DWORD keys, DWORD allowed) = 0;
};
DropFrom DropKind(IDataObject* data);
// the files of a drop (CF_HDROP), none when it has none
std::vector<std::wstring> DroppedFiles(IDataObject* data);
// `window` takes drops through `site` (RegisterDragDrop); its target, to revoke and to hide the drag image with
IDropTarget* RegisterDropSite(HWND window, DropSite* site);
// `window` takes no more drops; `target` released and cleared
void RevokeDropSite(HWND window, IDropTarget*& target);
// the texts of a list of the core, released after
std::vector<std::wstring> Texts(const core::TextList& list);
// a copy of `selection`, for work on another thread or in a drag while the list's own selection changes
core::Selection CopyOf(const PeSelection* selection);
void ShowDragImage(IDropTarget* target, bool show);
// the selected messages as the data of a drag: the app's own format for the folder tree, and for Explorer the files,
// written now with the Mark of the Web when all are downloaded, or else named now and fetched when a drop asks
IDataObject* MessagesData(PeCore* core, const PeSelection* selection);
// what the drag shows: the subject as the selected row, and how many for several
HBITMAP DragImage(HFONT font, const std::wstring& subject, size_t count, SIZE& size);
// DoDragDrop of `data` with `image` (taken over) under the cursor at `offset`; the effect of the drop
DWORD RunDrag(IDataObject* data, HBITMAP image, SIZE size, POINT offset);
// what Explorer does with a drop of `data` into the folder `dir` (for the UI test): the files written there, -1 for data
// without any
int WriteDataInto(IDataObject* data, const std::wstring& dir);
// files as Explorer hands them over in a drag (for the UI test)
IDataObject* FilesData(const std::vector<std::wstring>& paths);

// ---- accounts.cpp ----

// asks for a new account and adds it to the core; its id, or 0 when cancelled
int64_t NewAccountDialog(HWND owner, PeCore* core);
// the main window hands AutoconfigDone, SignInDone and SignInAppChecked events to the window waiting for one
void RequestDone(uint64_t request);
// waits for the event of `request` with a small window titled `title` that says `text` and can cancel it; false when
// it was cancelled
bool WaitForRequest(HWND owner, PeCore* core, uint64_t request, void (*cancel)(const PeCore*, uint64_t),
                    const std::wstring& text, const std::wstring& title);
// what a sign-in uses: a built-in client (GOOGLE, MICROSOFT) or the sign-in app `app` (APP)
struct SignInChoice {
    PeOAuthProvider provider = PE_O_AUTH_PROVIDER_NONE;
    int64_t app = 0;
};
// signs in with `with` for `email` in the browser; the finished sign-in request, 0 when it did not work
uint64_t SignInWithBrowser(HWND owner, PeCore* core, SignInChoice with, const std::wstring& email);
// test runs (--sign-in-page-file): the sign-in page is written to this file for the test to open, not to the browser
void SetSignInPageFile(const std::wstring& path);
// File > Accounts: the accounts listed, to add, change (Properties) or remove; true when one changed
bool AccountsDialog(HWND owner, PeCore* core);
// asks for the password of an account; false when cancelled
bool PasswordDialog(HWND owner, const std::wstring& account, std::wstring& password);

// ---- signinapps.cpp ----

// File > Accounts > Sign-in Apps: the built-in clients and the added sign-in apps, to turn on and off, add, change
// or remove
void SignInAppsDialog(HWND owner, PeCore* core);
// the editor of a sign-in app: a new one when `app` is NULL; the id of the app saved, 0 when cancelled
int64_t SignInAppEditor(HWND owner, PeCore* core, const PeSignInApp* app);

// ---- agents.cpp ----

// a question of an AI agent for the user (the AgentAsk event): a program that connects for the first time, or a
// message an agent wants to send
void AgentQuestion(HWND owner, PeCore* core, uint64_t request);
// Tools > AI Agents: whether agents may connect, the programs let in or turned away, what agents did
void AgentsDialog(HWND owner, PeCore* core);
// what agents did changed (AgentLogChanged): an open AI Agents window shows it
void AgentsChanged();
// main.cpp: the store given with --store, NULL for the usual one (for the setup of an agent)
const char* StoreArgument();

// ---- outbox.cpp ----

// Tools > Outbox: what waits to be sent, to send now or delete
void OutboxDialog(HWND owner, PeCore* core);

// ---- print.cpp ----

// File > Print: a window over `owner` with the message `document` (the core's, PeMessageInfo.document) where the print
// preview opens; it closes once the preview does
// (`environment`: the reading pane's WebView2 environment to start from, or NULL for one of its own)
void OpenPrintWindow(HWND owner, ICoreWebView2Environment* environment, const char* document, bool remoteImages, const std::wstring& subject);

// ---- help.cpp ----

// opens the help window, or brings it to the front
void OpenHelp();
void CloseHelp();

// ---- compose.cpp ----

// opens a window to write a message from `account`, with the fields of `draft` (NULL for a new message)
// a compose window of its own on the taskbar, not owned by `main` (so the main window can come in front of it); it
// tells `main` when it is gone
void OpenCompose(HWND main, PeCore* core, int64_t account, const PeDraftInfo* draft);
// the main window closing: each compose window is asked to close, a message with changes asks whether to save it.
// Closed when they all went; Saving when some close once their draft is saved (WM_COMPOSE_CLOSED follows); Kept when
// the user kept one open
enum class ComposeClose { Closed, Saving, Kept };
ComposeClose CloseComposeWindows();
// whether any compose window is open
bool ComposeWindowsOpen();
// ---- tray.cpp ----

// what the tray icon sends the main window, and what a message of it asks for
constexpr UINT WM_TRAY = WM_APP + 60;
enum class TrayAction { None, Handled, Open, Menu };
// the icon in the notification area, from the window's creation until it is gone
void TrayCreate(HWND main);
void TrayRemove(HWND main);
// how many messages are unread in the Inboxes: the icon's tooltip and a count on the taskbar button
void TrayCount(HWND main, uint64_t unread);
// a Windows notification from the icon; a click on it asks for the message `uid` of `folder` (Open)
void TrayNotify(HWND main, const std::wstring& title, const std::wstring& text, int64_t folder, uint64_t uid);
// a message of the main window that may be the tray's: what it asks for; for Open, the message of a clicked
// notification in `folder` and `uid` (0 for none)
TrayAction TrayMessage(HWND main, UINT message, WPARAM wParam, LPARAM lParam, int64_t& folder, uint64_t& uid);

// a plain preference of the app (HKEY_CURRENT_USER\Software\Postal Systems\InboxClassic), `fallback` when it is
// not set
DWORD GetPreference(const wchar_t* name, DWORD fallback);
void SetPreference(const wchar_t* name, DWORD value);
// a text preference there, empty when it is not set
std::wstring GetTextPreference(const wchar_t* name);
void SetTextPreference(const wchar_t* name, const std::wstring& value);

// ---- options.cpp ----

// the language of the windows, before the first window reads a word: `forced` (--language), else the one chosen in
// Options, else the first of Windows' display languages there is a catalog of
void StartLanguage(const std::wstring& forced);
// Tools > Options: the language and the new mail notifications (`notify`, changed when OK is clicked). True when the
// user chose to restart now for a new language
bool OptionsDialog(HWND owner, bool& notify);

// ---- complete.cpp ----

// completes the address the cursor is in, in an address field (To, Cc, Bcc), from the people written to and heard
// from: a list under the field as you type, arrows to choose, Enter or Tab to take one, Esc to close it, Shift+Delete
// to forget someone
void CompleteAddresses(HWND edit, PeCore* core);

// the signature of an account in an editor of its own (Accounts > Signature); whether it was saved
bool EditSignature(HWND owner, PeCore* core, int64_t account, const std::wstring& name);
// the compose windows, gone without asking, before the core they use is
void DestroyComposeWindows();
// the save of the draft `messageId` finished, `problem` empty when it worked: the window that saved it says so;
// false when that window is no longer open
bool ComposeDraftSaved(const std::string& messageId, const std::wstring& problem);
// Ctrl+S in a compose window (its fields; the editor has its own): saves the message in Drafts; true when handled
bool ComposeKey(const MSG& msg);

// ---- mailbox.cpp ----

// an event of the core, copied on the worker thread and posted to the window thread
struct UiEvent {
    PeEventKind kind;
    int64_t account;
    int64_t folder;
    uint64_t uid;
    PeFailureKind failure;
    std::wstring message;
    // the Message-ID of a draft, for DraftSaved; the subject, for NewMail
    std::string detail;
    // how many messages, for NewMail
    uint64_t count = 0;
};

// the folder tree, the message list and the reading pane
class Mailbox {
public:
    void Create(HWND parent, PeCore* core);
    // releases the WebView2 and the fonts, before COM is shut down
    void Destroy();
    // places the panes: the tree in `tree`, the list and the reading pane in `list` and `reader`
    void Layout(const RECT& tree, const RECT& list, const RECT& reader);
    // WM_NOTIFY and WM_COMMAND of the panes; true when handled
    bool OnNotify(NMHDR* header, LRESULT& result);
    bool OnCommand(WORD id, WORD code);
    // the Find box: placed at the right of the toolbar row, focused (Ctrl+Shift+F), cleared (Esc)
    void PlaceFind(const RECT& row, int buttonsRight);
    // the UI test's stand-ins for what the system does: a drag of the selected messages dropped into the folder `dir`
    // as Explorer drops it (the files written, -1 for none), and files dropped onto the tree item `item`; the effect
    int TestDragOut(const std::wstring& dir);
    DWORD TestDropFiles(HTREEITEM item, const std::vector<std::wstring>& paths);
    // what a background save or forward of several messages finished with (WM_FILES_DONE)
    void FilesDone(LPARAM done);
    // files dropped onto a folder, imported after the drop (WM_IMPORT_DROPPED)
    void ImportDropped(WPARAM folder, LPARAM files);
    // several messages saved into a folder each as its own file, or forwarded attached to one message, off the window
    // thread
    void SaveSelectedInto(HWND owner);
    void ForwardSelected();
    // WM_DRAWITEM of the search field's magnifier and clear button; false for other controls
    bool OnDrawItem(const DRAWITEMSTRUCT& item);
    void FocusFind();
    // File > Save As (the message shown, as an .eml), Print (the message shown), Import Messages (into the folder)
    void SaveShownAs(HWND owner);
    void PrintShown();
    // File > Properties (Alt+Enter): the Internet headers of the message shown
    void ShowProperties(HWND owner);
    // View Source: the whole message as the server has it
    void ShowSource(HWND owner);
    // the message list's right-click menu at `screen`, or at the selected row for (-1, -1) (the menu key)
    void MessageMenu(POINT screen);
    HWND List() const { return list_; }
    // the right-click menu while it is open, for the UI test
    HMENU OpenMenu() const { return lastMenu_; }
    void Import(HWND owner);
    bool ClearFind();
    void ResetFind();
    void OnTimer(UINT_PTR id);
    void OnEvent(const UiEvent& event);
    // the accounts changed: builds the tree again
    void Reload();
    // what the last action on messages did, for the status bar (IDC_LIST, kSaid)
    const std::wstring& Said() const { return said_; }
    // the selected messages read or unread
    void MarkSelected(bool seen);
    // how many messages are selected, and what they are in numbers (count 0 with none)
    size_t SelectedCount() const;
    const PeSelectionSummary& Summary() const { return summary_; }
    // Edit > Select All: every message of the list
    void SelectAll();
    // Edit > Undo: the last move, delete or junk taken back; what the menu calls it, empty when there is nothing
    void Undo();
    std::wstring UndoLabel() const;
    // every message of the selected folder read, or of every Inbox from All Inboxes (Edit > Mark All Read, the folder's
    // menu); nothing while searching
    void MarkAllRead();
    // the message `uid` of `folder` shown: its folder chosen in the tree, the message selected in the list
    void ShowMessage(int64_t folder, uint64_t uid);
    // the window shown the first time: All Inboxes (two or more accounts) or the first account's Inbox chosen, and its
    // newest message selected
    void SelectStart();
    // the selected messages junk ($Junk, into the Junk folder) or not junk ($NotJunk, into the Inbox)
    void MarkJunk(bool junk);
    // whether the selected messages, or else the folder, are in a Junk folder: the toolbar offers Not Junk there
    bool InJunk() const;
    // the Unsubscribe link of the message shown, after asking: what the status bar says; a mailto: link to write a
    // message to in `mailto` when the list wants one
    std::wstring Unsubscribe(std::wstring& mailto);
    // the one-click unsubscribe `request` done, or not for `problem`: what the status bar says, empty for another
    std::wstring Unsubscribed(uint64_t request, const std::wstring& problem);
    // the selected messages into Deleted Items (for good from there, asked first), the next one selected
    void DeleteSelected();
    // asks for a folder of their account and moves the selected messages there
    // Move to Folder, or Copy to Folder with `copy`
    void MoveSelected(HWND owner, bool copy = false);
    // flags the selected messages, or takes their flags away when all of them have one
    void FlagSelected();
    // flags the selected messages in colour `color` (1 red to 7 gray, Apple Mail's), or takes flag and colour away
    // (0)
    void FlagColor(int color);
    // the Flag submenu: the seven colours with their flags, then Clear Flag (IDM_FLAG_COLOR + n, IDM_FLAG_CLEAR);
    // owned by the menu it is put in
    HMENU FlagMenu();
    // its items as the selection is now: the colour every selected message has checked, Clear Flag when one is flagged
    void UpdateFlagMenu(HMENU menu);
    // a folder in the selected one (at the top of the selected account), renaming and deleting the selected one
    void NewFolder(HWND owner);
    void RenameFolder(HWND owner);
    void DeleteFolder(HWND owner);
    void LoadPictures();
    // WM_SETCURSOR and WM_CTLCOLORSTATIC of the main window for the information bar of blocked pictures (a hand, the
    // information colors); false for other windows
    bool OnSetCursor(HWND window);
    bool OnCtlColor(HWND window, HDC dc, LRESULT& brush);
    // "12 messages, 3 unread" for the status bar, with ", 2 selected" when more than one is
    std::wstring Counts() const;
    // the name of the selected folder (or account), for the folder bar and the title; empty with nothing selected.
    // While searching, where it looks: "All folders", or the one folder named (in:sent)
    std::wstring SelectedName() const;
    // the bar over the list while searching: what was found for which words (and how many messages the search does
    // not know the text of yet); shown or hidden, the list laid out again when that changes
    void UpdateSearchBar();
    std::wstring AccountName(int64_t account) const;
    std::wstring AccountEmail(int64_t account) const;
    // the provider the account signs in to through the browser, NONE for a password
    // what the account signs in with through the browser; NONE for a password
    SignInChoice SignIn(int64_t account) const;
    // the account of the selected folder, the first account without one; 0 when there is none
    int64_t CurrentAccount() const;
    // a reply, reply to all or forward of the message shown, empty when no message is shown
    core::Draft DraftOfShown(PeDraftKind kind) const;
    // the selected message of a Drafts folder in a compose window, to go on writing it (double-click or Enter); once
    // it is fetched when it is not yet
    void OpenSelected();

private:
    struct Page {
        uint64_t offset = 0;
        core::MessageList rows;
    };

    void FillAccount(HTREEITEM root, int64_t account);
    void UpdateFolders(int64_t account);
    void ShowRow(HTREEITEM item);
    void ReloadList(bool keepSelection);
    // what the list shows: the folder (or every folder), the Show choice and the words of the Find box
    PeSearch Search() const;
    // whether the list has what words typed found, in every folder (with a Folder column), rather than a folder
    bool Searching() const;
    void ShowFolderColumn();
    std::wstring RowFolder(int64_t folder) const;
    const PeMessage* Row(int index);
    const PeMessage* SelectedRow();
    // the reading pane emptied; with "There is no message selected." in it unless a message is `loading`
    void ClearReader(bool loading = false);
    // in the middle of the list while it has no rows: why, and what to do about it
    void DrawEmptyList(HDC dc) const;
    void SelectAfterRemoval(int index);
    // the selection taken from the list again (a message, or the positions of several), its summary, and with several
    // the reading pane saying how many
    void TakeSelection(bool rebuild);
    std::vector<int> SelectedRows() const;
    // the rows at `positions` selected, the first focused and in view with `focusFirst`; false for none
    bool SelectPositions(const PePositions* positions, bool focusFirst);
    // `action` done to the selected messages, the status bar told what was done, and the row after them selected when
    // they left the list; true when it was done
    bool Act(PeAction action, int64_t to = 0);
    void Say(const std::wstring& text);
    // the list changed its selection: taken once it is done changing it (TIMER_SELECTION)
    void ScheduleSelection();
    // the row the selection is replaced by once the selected rows left the list: the one after the last of them
    int RowAfterSelection() const;
    void FolderMenu();
    // the name and whether it is the Inbox or a special folder (not renamed or deleted); false when not found
    bool FolderOf(int64_t folder, std::wstring& name, bool& fixed) const;
    // the selection taken again; with `rebuild` false the messages selected stay as they were (a reload selected them
    // again where they are now) and only their numbers are taken
    void OnSelectionChanged(bool rebuild = true);
    // another folder (or All Inboxes) shown; false when it was already the one shown (and the main window was not told)
    bool OnFolderSelected(int64_t folder, bool allInboxes = false);
    // whether the list has messages of several folders: a search, or All Inboxes (with a Folder column)
    bool SeveralFolders() const;
    // the row of the message `uid` of `folder` selected in the list; false when it is not there
    bool SelectInList(int64_t folder, uint64_t uid);
    // asks the core for the view of the selected message, built on a worker; ShowView() shows it when it comes
    void ShowMessage();
    void ShowView();
    void ShowHeader(const PeMessageInfo* info);
    void ChooseAttachment();
    void SaveAllAttachments();
    void LayoutReader();
    void ShowReaderBars(bool files, bool pictures);
    // the bar over a message that could not be downloaded, shown or not
    void ShowRetry(bool shown);
    // Try Again, or the account synced again after the message could not be downloaded
    void RetryDownload();
    void CustomDraw(NMLVCUSTOMDRAW* draw, LRESULT& result);
    void DrawRowIcons(HDC dc, int index, const PeMessage& row);
    void DisplayInfo(NMLVDISPINFOW* info);
    bool OnListNotify(NMHDR* header, LRESULT& result);

    PeCore* core_ = nullptr;
    HWND parent_ = nullptr;
    HWND tree_ = nullptr;
    HWND list_ = nullptr;
    HWND header_ = nullptr;
    // the paper clip button (a toolbar of one) and the information bar of blocked pictures
    HWND attachments_ = nullptr;
    HWND pictures_ = nullptr;
    HWND retry_ = nullptr;
    RECT reader_ = {};
    HWND previewHost_ = nullptr;
    HFONT bold_ = nullptr;
    HFONT link_ = nullptr;
    // where the list goes, with the search bar over it while searching
    RECT listArea_ = {};
    HWND searchBar_ = nullptr;
    // the Unsubscribe link, and how the message shown lets its reader leave its list (PeMessageInfo)
    HWND unsubscribe_ = nullptr;
    // the BIMI logo of the message shown, once the core drew it, and the request it was drawn for
    HWND logo_ = nullptr;
    HBITMAP logoBitmap_ = nullptr;
    uint64_t logoRequest_ = 0;
    int logoSize_ = 0;
    void ShowLogo(bool wanted);
    // the event of the message shown, its two lines as the bar shows them
    HWND invitation_ = nullptr;
    HWND openCalendar_ = nullptr;
    std::wstring invitationTitle_;
    std::wstring invitationDetails_;
    void ShowInvitation(const PeInvitation* event);
    void OpenInCalendar();
    PeUnsubscribe unsubscribeKind_ = PE_UNSUBSCRIBE_NONE;
    std::wstring unsubscribeLink_;
    std::wstring unsubscribeTarget_;
    uint64_t unsubscribeRequest_ = 0;
    HWND searchClear_ = nullptr;
    std::wstring searchSummary_;
    // the one folder the words typed name (in:sent), empty for every folder
    std::wstring findPlace_;
    void LayoutList();
    int LinkWidth(HWND link) const;
    // the icons the list draws on its rows, and their size
    HIMAGELIST listIcons_ = nullptr;
    int iconSize_ = 16;
    Preview preview_;
    // the tree items of the folders, by folder id; a tree item's data is its folder id, 0 for an account
    std::unordered_map<int64_t, HTREEITEM> items_;
    // the account's own item of each account
    std::unordered_map<int64_t, HTREEITEM> accountItems_;
    // what each row of the tree shows: its name, its own unread messages and those of the folders under it
    struct TreeRow {
        std::wstring name;
        uint64_t own = 0;
        uint64_t below = 0;
    };
    std::unordered_map<HTREEITEM, TreeRow> rows_;
    HMENU lastMenu_ = nullptr;
    std::unordered_map<int64_t, std::wstring> accountNames_;
    std::unordered_map<int64_t, std::wstring> accountEmails_;
    std::unordered_map<int64_t, SignInChoice> accountSignIns_;
    // the account of each folder, and the first account
    std::unordered_map<int64_t, int64_t> folderAccounts_;
    // the name of each folder in the tree, and whether it is the Inbox or a special folder
    std::unordered_map<int64_t, std::pair<std::wstring, bool>> folderNames_;
    // the folders that hold no messages (only other folders)
    std::unordered_set<int64_t> unselectable_;
    // All Inboxes at the top of the tree (two or more accounts), and whether it is selected
    HTREEITEM allInboxesItem_ = nullptr;
    bool allInboxes_ = false;
    // a drag over the tree: the item under it and since when (one held over opens), where it would go
    struct DragOver {
        HTREEITEM over = nullptr;
        ULONGLONG overSince = 0;
        bool opened = false;
        int64_t target = 0;
        // since when it is held at the tree's top or bottom edge, and when it scrolled last
        ULONGLONG edgeSince = 0;
        ULONGLONG scrolled = 0;
    };
    DragOver dragOver_;
    // the folder the messages of the list's own drag come from (a drop there does nothing), 0 when none is dragged
    int64_t dragFrom_ = 0;
    // the tree and the list take drops through these
    struct TreeSite : DropSite {
        Mailbox* mailbox = nullptr;
        DWORD Over(DropFrom from, POINT screen, DWORD keys, DWORD allowed) override;
        void Leave() override;
        DWORD Dropped(IDataObject* data, DropFrom from, POINT screen, DWORD keys, DWORD allowed) override;
    };
    struct ListSite : DropSite {
        Mailbox* mailbox = nullptr;
        DWORD Over(DropFrom from, POINT screen, DWORD keys, DWORD allowed) override;
        void Leave() override {}
        DWORD Dropped(IDataObject* data, DropFrom from, POINT screen, DWORD keys, DWORD allowed) override;
    };
    TreeSite treeSite_;
    ListSite listSite_;
    IDropTarget* treeTarget_ = nullptr;
    IDropTarget* listTarget_ = nullptr;
    // .eml files into `folder` as Import does; the reasons of those that were not
    void ImportFiles(int64_t folder, const std::vector<std::wstring>& files, HWND owner);

    // a folder made with New Folder in the Move and Copy window: highlighted there once it exists (FolderCreated)
    bool newInPick_ = false;
    // the selected messages, as the core knows them: kept when the list changes under them, so an action reaches the
    // messages that were selected; and what they are in numbers
    core::Selection selection_{pe_selection_new()};
    PeSelectionSummary summary_ = {};
    // the page the reading pane shows over several messages, empty when it shows another
    std::wstring summaryPage_;
    std::wstring said_;
    // the list changed its selection and TIMER_SELECTION has not taken it yet; taken at once before anything acts on it
    bool selectionPending_ = false;
    void FlushSelection();
    // Undo brought messages back: they are selected once the list has them again
    bool undoPending_ = false;
    // the messages Undo brought back selected, once they are in the list again; false while none is there yet
    bool SelectRestored(const PeSearch& search);
    // a drag of the selected messages out of the list (the row `index` picked up): onto a folder, or out of the app
    void BeginDrag(int index);
    // the folder under `screen` a drag of `from` can go to, 0 for none; the item under it in `over`
    int64_t DropFolder(DropFrom from, POINT screen, HTREEITEM& over) const;
    // the tree changed under the drag image (highlighted, scrolled, opened) without the image smearing over it
    void ChangeTreeUnderDrag(const std::function<void()>& change);
    // the Drafts folders, whose messages open in a compose window
    std::unordered_set<int64_t> draftFolders_;
    // the Junk folders of the accounts
    std::unordered_set<int64_t> junkFolders_;
    // the selected draft opens once its source is fetched
    bool openWhenReady_ = false;
    int64_t firstAccount_ = 0;
    // the account whose own item is selected in the tree, 0 when a folder is
    int64_t selectedAccount_ = 0;
    // what the Find box searches for, empty when the list is the folder's
    std::wstring find_;
    std::string findUtf8_;
    // the search field: a white sunken window with the magnifier, the box and the clear button in it
    HWND findField_ = nullptr;
    HWND findIcon_ = nullptr;
    HWND findEdit_ = nullptr;
    HWND findClear_ = nullptr;
    bool folderColumn_ = false;
    int64_t folder_ = 0;
    uint64_t total_ = 0;
    uint64_t unread_ = 0;
    PeSortField sort_ = PE_SORT_FIELD_DATE;
    bool ascending_ = false;
    // the pages of the list, the most recently used last
    std::vector<Page> pages_;
    // true while the list is reloaded: its selection changes are the reload's, not the user's
    bool reloading_ = false;
    // SelectStart has run: later showings of the window keep what is selected
    bool started_ = false;
    // the message shown and its folder (its row's: in a search of every folder not the selected one), 0 for none
    uint64_t uid_ = 0;
    int64_t messageFolder_ = 0;
    bool remoteImages_ = false;
    core::MessageView view_;
    // the view being built for the reading pane, 0 for none
    uint64_t viewRequest_ = 0;
    // the text of the list cells, kept until the list asks for the next one
    std::wstring cell_;
};

constexpr UINT WM_CORE_EVENT = WM_APP + 1;
// to the main window from a compose window: it is gone (WM_COMPOSE_CLOSED), or it stays open after all, its save on
// closing having failed (WM_COMPOSE_KEPT)
constexpr UINT WM_COMPOSE_CLOSED = WM_APP + 2;
constexpr UINT WM_COMPOSE_KEPT = WM_APP + 3;
// a save or forward of several messages done on another thread: lParam a FilesDoneInfo the window takes over
constexpr UINT WM_FILES_DONE = WM_APP + 4;
// files dropped onto a folder, imported once the drop is over: wParam the folder, lParam a std::vector<std::wstring>
// of their paths the window takes over
constexpr UINT WM_IMPORT_DROPPED = WM_APP + 5;

// the commands of the menus, toolbar and tray (IDM_*) come from core/commands.toml, shared with the Mac and Linux
// windows; the ids of the controls are this app's own
enum ControlId : WORD {
    IDC_TREE = 200,
    IDC_LIST,
    IDC_ATTACHMENTS,
    IDC_PICTURES,
    IDC_FIND,
    // the search field the Find box is in, with its magnifier and clear button
    IDC_FIND_FIELD,
    IDC_FIND_ICON,
    IDC_FIND_CLEAR,
    // over the list while searching: what was found, and a link that ends the search
    IDC_SEARCH_BAR,
    IDC_SEARCH_CLEAR,
    // at the right of the message header: leaving the message's mailing list
    IDC_UNSUBSCRIBE,
    // under the header of a message with a calendar part: the event, and a button that opens it in the calendar
    IDC_INVITATION,
    IDC_OPEN_CALENDAR,
    // at the left of the message header: the brand's BIMI logo
    IDC_LOGO,
    // under the header of a message that could not be downloaded: a click tries again
    IDC_RETRY,
};

// the items of the Flag submenu: IDM_FLAG_COLOR + 1 (red) to + 7 (gray), and Clear Flag
constexpr WORD IDM_FLAG_COLOR = 900;
constexpr WORD IDM_FLAG_CLEAR = 908;

// what the message list tells the main window with WM_COMMAND of IDC_LIST: its selection was taken (the buttons and
// counts follow it), or an action on messages was done (Mailbox::Said for the status bar)
constexpr WORD kSelectionTaken = 1;
constexpr WORD kSaid = 2;

// the controls of the AI agents' windows (agents.cpp), which the UI test finds by them
enum AgentControlId : WORD {
    // what a program may do: the first of the four levels (the others follow it), the accounts, its file
    IDC_AGENT_LEVEL = 600,
    IDC_AGENT_ACCOUNTS = 610,
    IDC_AGENT_PATH,
    // a message to send: the recipients, the text, the warning, and the three answers
    IDC_AGENT_RECIPIENTS,
    IDC_AGENT_BODY,
    IDC_AGENT_WARNING,
    IDC_AGENT_SEND,
    IDC_AGENT_COMPOSE,
    IDC_AGENT_DONT_SEND,
    // Tools > AI Agents
    IDC_AGENTS_ENABLED = 630,
    IDC_AGENTS_HOSTS,
    IDC_AGENTS_CHANGE,
    IDC_AGENTS_REMOVE,
    IDC_AGENTS_LOG,
    IDC_AGENTS_UNDO,
    IDC_AGENTS_CLEAR,
    IDC_AGENTS_SETUP,
};

// the controls of Tools > Options (options.cpp), which the UI test finds by them
enum OptionsControlId : WORD {
    IDC_OPTIONS_LANGUAGE = 660,
    IDC_OPTIONS_NOTIFY,
    IDC_OPTIONS_NOTE,
};

constexpr UINT_PTR TIMER_MARK_READ = 1;
// a moment after typing in the Find box, the list follows it
constexpr UINT_PTR TIMER_FIND = 3;
// a list of several folders follows their changes once a sync of many of them is done, not after each
constexpr UINT_PTR TIMER_RELOAD = 4;
// while a message is dragged: the keys (Esc, Ctrl), scrolling the tree at its edges, opening a folder held over
// a moment after a message is asked for, the pane says it is being downloaded (one that is cached shows first)
constexpr UINT_PTR TIMER_DOWNLOADING = 6;
// the selection of the message list taken once the list has done changing it: a click or a key in a list of several
// selected rows takes every row away first, which is no change the reading pane should follow
constexpr UINT_PTR TIMER_SELECTION = 7;
