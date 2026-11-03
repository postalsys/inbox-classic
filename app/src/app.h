// Shared pieces of the windows: DPI scaling, child controls, text formatting and the small dialogs. Everything shown
// comes from the core (core.h) already decoded; nothing here parses mail data.
#pragma once

#include <windows.h>

#include <commctrl.h>

#include <cstdint>
#include <string>
#include <unordered_map>
#include <unordered_set>
#include <vector>

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
std::wstring TimeNow();
// 1.2 KB, 3 MB
std::wstring FormatSize(uint64_t bytes);
// the brush of dialog backgrounds, for WM_CTLCOLORSTATIC
LRESULT ButtonFaceColor(HDC dc);

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
// a flat toolbar, a child of `hwnd`; `style` adds CCS_* and TBSTYLE_* styles. Its icons (icons.h): the big ones with
// the label under them (main and compose windows), or the small ones of the format bar, the label as the tooltip
enum class BarIcons { Big, Small };
HWND CreateBar(HWND hwnd, DWORD style, int id, BarIcons icons);
// a button on a bar of CreateBar, with its icon (icons.h) or I_IMAGENONE; id 0 is a separator
void AddButton(HWND bar, int id, const wchar_t* text, BYTE style = BTNS_BUTTON, int image = I_IMAGENONE);

// a modal form with a label and an input for each field; true with the values filled in when OK was clicked.
// `validate` gets the values and returns an error to show, or an empty string to accept them.
// `focus`: the field to start in
bool FormDialog(HWND owner, const std::wstring& title, const std::wstring& intro, std::vector<FormField>& fields,
                bool (*validate)(const std::vector<FormField>&, std::wstring& error) = nullptr, const wchar_t* okLabel = L"OK",
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
std::wstring SaveFileDialog(HWND owner, const std::wstring& name, const wchar_t* title = L"Save Attachment As",
                           const wchar_t* filter = L"All files (*.*)\0*.*\0", const wchar_t* extension = nullptr);
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

// ---- accounts.cpp ----

// asks for a new account and adds it to the core; its id, or 0 when cancelled
int64_t NewAccountDialog(HWND owner, PeCore* core);
// the main window hands AutoconfigDone, SignInDone and SignInAppChecked events to the window waiting for one
void RequestDone(uint64_t request);
// waits for the event of `request` with a small window titled `title` that says `text` and can cancel it; false when
// it was cancelled
bool WaitForRequest(HWND owner, PeCore* core, uint64_t request, void (*cancel)(const PeCore*, uint64_t),
                    const std::wstring& text, const wchar_t* title);
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
    // the Message-ID of a draft, for DraftSaved
    std::string detail;
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
    void PlaceFind(const RECT& row);
    void FocusFind();
    // File > Save As (the message shown, as an .eml), Print (the message shown), Import Messages (into the folder)
    void SaveShownAs(HWND owner);
    void PrintShown();
    // File > Properties (Alt+Enter): the Internet headers of the message shown
    void ShowProperties(HWND owner);
    void Import(HWND owner);
    bool ClearFind();
    void ResetFind();
    void OnTimer(UINT_PTR id);
    void OnEvent(const UiEvent& event);
    // the accounts changed: builds the tree again
    void Reload();
    void MarkSelected(bool seen);
    // the selected message into Deleted Items (for good when it is in there), the next one selected
    void DeleteSelected();
    // asks for a folder of the account and moves the selected message there
    void MoveSelected(HWND owner);
    // flags the selected message, or takes its flag away
    void FlagSelected();
    // a folder in the selected one (at the top of the selected account), renaming and deleting the selected one
    void NewFolder(HWND owner);
    void RenameFolder(HWND owner);
    void DeleteFolder(HWND owner);
    void LoadPictures();
    // WM_SETCURSOR and WM_CTLCOLORSTATIC of the main window for the information bar of blocked pictures (a hand, the
    // information colors); false for other windows
    bool OnSetCursor(HWND window);
    bool OnCtlColor(HWND window, HDC dc, LRESULT& brush);
    // "12 message(s), 3 unread" for the status bar
    std::wstring Counts() const;
    // the name of the selected folder (or account), for the folder bar and the title; empty with nothing selected
    std::wstring SelectedName() const;
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
    void ReloadList(bool keepSelection);
    const PeMessage* Row(int index);
    const PeMessage* SelectedRow();
    // the reading pane emptied; with "There is no message selected." in it unless a message is `loading`
    void ClearReader(bool loading = false);
    void SelectAfterRemoval(int index);
    void FolderMenu();
    // the name and whether it is the Inbox or a special folder (not renamed or deleted); false when not found
    bool FolderOf(int64_t folder, std::wstring& name, bool& fixed) const;
    void OnSelectionChanged();
    // another folder shown; false when it was already the one shown (and the main window was not told)
    bool OnFolderSelected(LPARAM folder);
    // asks the core for the view of the selected message, built on a worker; ShowView() shows it when it comes
    void ShowMessage();
    void ShowView();
    void ShowHeader(const PeMessageInfo* info);
    void ChooseAttachment();
    void SaveAllAttachments();
    void LayoutReader();
    void ShowReaderBars(bool files, bool pictures);
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
    RECT reader_ = {};
    HWND previewHost_ = nullptr;
    HFONT bold_ = nullptr;
    // the icons the list draws on its rows, and their size
    HIMAGELIST listIcons_ = nullptr;
    int iconSize_ = 16;
    Preview preview_;
    // the tree items of the folders, by folder id; a tree item's data is its folder id, 0 for an account
    std::unordered_map<int64_t, HTREEITEM> items_;
    std::unordered_map<int64_t, std::wstring> accountNames_;
    std::unordered_map<int64_t, std::wstring> accountEmails_;
    std::unordered_map<int64_t, SignInChoice> accountSignIns_;
    // the account of each folder, and the first account
    std::unordered_map<int64_t, int64_t> folderAccounts_;
    // the name of each folder in the tree, and whether it is the Inbox or a special folder
    std::unordered_map<int64_t, std::pair<std::wstring, bool>> folderNames_;
    // the Drafts folders, whose messages open in a compose window
    std::unordered_set<int64_t> draftFolders_;
    // the selected draft opens once its source is fetched
    bool openWhenReady_ = false;
    int64_t firstAccount_ = 0;
    // the account whose own item is selected in the tree, 0 when a folder is
    int64_t selectedAccount_ = 0;
    // what the list is narrowed to (the Find box), empty for all; the folder's own total beside it
    std::wstring find_;
    std::string findUtf8_;
    uint64_t folderTotal_ = 0;
    HWND findLabel_ = nullptr;
    HWND findEdit_ = nullptr;
    int64_t folder_ = 0;
    uint64_t total_ = 0;
    uint64_t unread_ = 0;
    PeSortField sort_ = PE_SORT_FIELD_DATE;
    bool ascending_ = false;
    // the pages of the list, the most recently used last
    std::vector<Page> pages_;
    // true while the list is reloaded: its selection changes are the reload's, not the user's
    bool reloading_ = false;
    // the message shown, 0 for none
    uint64_t uid_ = 0;
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

enum CommandId : WORD {
    IDM_NEW_ACCOUNT = 100,
    IDM_EXIT,
    IDM_SYNC,
    IDM_MARK_READ,
    IDM_MARK_UNREAD,
    IDM_PICTURES,
    IDM_ABOUT,
    IDM_NEW_MAIL,
    IDM_REPLY,
    IDM_REPLY_ALL,
    IDM_FORWARD,
    IDM_HELP,
    IDM_DELETE,
    IDM_MOVE,
    IDM_FLAG,
    IDM_NEW_FOLDER,
    IDM_RENAME_FOLDER,
    IDM_DELETE_FOLDER,
    IDM_ACCOUNTS,
    IDC_TREE = 200,
    IDC_LIST,
    IDC_ATTACHMENTS,
    IDC_PICTURES,
    IDC_FIND,
    IDM_FIND = 120,
    IDM_SAVE_AS,
    IDM_PRINT,
    IDM_IMPORT,
    IDM_OUTBOX,
    IDM_PROPERTIES,
};

constexpr UINT_PTR TIMER_MARK_READ = 1;
// a moment after typing in the Find box, the list follows it
constexpr UINT_PTR TIMER_FIND = 3;
