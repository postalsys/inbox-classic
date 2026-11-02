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

// a flat toolbar of text buttons, a child of `hwnd`; `style` adds CCS_* and TBSTYLE_* styles
HWND CreateBar(HWND hwnd, DWORD style, int id);
// a button with a text on a bar of CreateBar; id 0 is a separator
void AddButton(HWND bar, int id, const wchar_t* text, BYTE style = BTNS_BUTTON);

// a modal form with a label and an input for each field; true with the values filled in when OK was clicked.
// `validate` gets the values and returns an error to show, or an empty string to accept them.
bool FormDialog(HWND owner, const std::wstring& title, const std::wstring& intro, std::vector<FormField>& fields,
                bool (*validate)(const std::vector<FormField>&, std::wstring& error) = nullptr);
// a dialog window centered on the window of `owner`, owned by it, with this client size; RunModal shows it, runs it
// until `done` and destroys it, the owner disabled meanwhile
HWND CreateModalWindow(HWND owner, const wchar_t* className, const wchar_t* title, int clientWidth, int clientHeight);
void RunModal(HWND dialog, HWND focus, const bool& done);
// the path to save an attachment to, starting from the safe name the core made; empty when cancelled
std::wstring SaveFileDialog(HWND owner, const std::wstring& name, const wchar_t* title = L"Save Attachment As",
                           const wchar_t* filter = L"All files (*.*)\0*.*\0", const wchar_t* extension = nullptr);
// the files chosen in an Open dialog that takes several, none when cancelled
std::vector<std::wstring> OpenFilesDialog(HWND owner, const wchar_t* title, const wchar_t* filter);
bool WriteFileBytes(const std::wstring& path, const uint8_t* data, size_t size);

// ---- accounts.cpp ----

// asks for a new account and adds it to the core; its id, or 0 when cancelled
int64_t NewAccountDialog(HWND owner, PeCore* core);
// the main window hands AutoconfigDone and SignInDone events to the account form waiting for one
void RequestDone(uint64_t request);
// signs in to `provider` for `email` in the browser; the finished sign-in request, 0 when it did not work
uint64_t SignInWithBrowser(HWND owner, PeCore* core, PeOAuthProvider provider, const std::wstring& email);
// File > Accounts: the accounts listed, to add, change (Properties) or remove; true when one changed
bool AccountsDialog(HWND owner, PeCore* core);
// asks for the password of an account; false when cancelled
bool PasswordDialog(HWND owner, const std::wstring& account, std::wstring& password);

// ---- outbox.cpp ----

// Tools > Outbox: what waits to be sent, to send now or delete
void OutboxDialog(HWND owner, PeCore* core);

// ---- help.cpp ----

// opens the help window, or brings it to the front
void OpenHelp();
void CloseHelp();

// ---- compose.cpp ----

// opens a window to write a message from `account`, with the fields of `draft` (NULL for a new message)
void OpenCompose(HWND owner, PeCore* core, int64_t account, const PeDraftInfo* draft);
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
    // "12 message(s), 3 unread" for the status bar
    std::wstring Counts() const;
    std::wstring AccountName(int64_t account) const;
    std::wstring AccountEmail(int64_t account) const;
    // the provider the account signs in to through the browser, NONE for a password
    PeOAuthProvider OAuthProvider(int64_t account) const;
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
    void ClearReader();
    void SelectAfterRemoval(int index);
    void FolderMenu();
    // the name and whether it is the Inbox or a special folder (not renamed or deleted); false when not found
    bool FolderOf(int64_t folder, std::wstring& name, bool& fixed) const;
    void OnSelectionChanged();
    void OnFolderSelected(LPARAM folder);
    // asks the core for the view of the selected message, built on a worker; ShowView() shows it when it comes
    void ShowMessage();
    void ShowView();
    void ShowHeader(const PeMessageInfo* info);
    void ChooseAttachment();
    void CustomDraw(NMLVCUSTOMDRAW* draw, LRESULT& result);
    void DisplayInfo(NMLVDISPINFOW* info);
    bool OnListNotify(NMHDR* header, LRESULT& result);

    PeCore* core_ = nullptr;
    HWND parent_ = nullptr;
    HWND tree_ = nullptr;
    HWND list_ = nullptr;
    HWND header_ = nullptr;
    HWND attachments_ = nullptr;
    HWND pictures_ = nullptr;
    HWND previewHost_ = nullptr;
    HFONT bold_ = nullptr;
    Preview preview_;
    // the tree items of the folders, by folder id; a tree item's data is its folder id, 0 for an account
    std::unordered_map<int64_t, HTREEITEM> items_;
    std::unordered_map<int64_t, std::wstring> accountNames_;
    std::unordered_map<int64_t, std::wstring> accountEmails_;
    std::unordered_map<int64_t, PeOAuthProvider> accountOAuth_;
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
};

constexpr UINT_PTR TIMER_MARK_READ = 1;
// a moment after typing in the Find box, the list follows it
constexpr UINT_PTR TIMER_FIND = 3;
