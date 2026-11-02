// Shared pieces of the windows: DPI scaling, child controls, text formatting and the small dialogs. Everything shown
// comes from the core (core.h) already decoded; nothing here parses mail data.
#pragma once

#include <windows.h>

#include <commctrl.h>

#include <cstdint>
#include <string>
#include <unordered_map>
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
    // for Choice: the options; `value` is the chosen one
    std::vector<std::wstring> choices;
};

// a modal form with a label and an input for each field; true with the values filled in when OK was clicked.
// `validate` gets the values and returns an error to show, or an empty string to accept them.
bool FormDialog(HWND owner, const std::wstring& title, const std::wstring& intro, std::vector<FormField>& fields,
                bool (*validate)(const std::vector<FormField>&, std::wstring& error) = nullptr);
// the path to save an attachment to, starting from the safe name the core made; empty when cancelled
std::wstring SaveFileDialog(HWND owner, const std::wstring& name);
bool WriteFileBytes(const std::wstring& path, const uint8_t* data, size_t size);

// ---- accounts.cpp ----

// asks for a new account and adds it to the core; its id, or 0 when cancelled
int64_t NewAccountDialog(HWND owner, PeCore* core);
// the main window hands AutoconfigDone and SignInDone events to the account form waiting for one
void RequestDone(uint64_t request);
// signs in to `provider` for `email` in the browser; the finished sign-in request, 0 when it did not work
uint64_t SignInWithBrowser(HWND owner, PeCore* core, PeOAuthProvider provider, const std::wstring& email);
// asks for the password of an account; false when cancelled
bool PasswordDialog(HWND owner, const std::wstring& account, std::wstring& password);

// ---- compose.cpp ----

// opens a window to write a message from `account`, with the fields of `draft` (NULL for a new message)
void OpenCompose(HWND owner, PeCore* core, int64_t account, const PeDraftInfo* draft);

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
    bool OnCommand(WORD id);
    void OnTimer(UINT_PTR id);
    void OnEvent(const UiEvent& event);
    // the accounts changed: builds the tree again
    void Reload();
    void MarkSelected(bool seen);
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
    void OnSelectionChanged();
    void OnFolderSelected(LPARAM folder);
    void ShowMessage();
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
    int64_t firstAccount_ = 0;
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
    IDC_TREE = 200,
    IDC_LIST,
    IDC_ATTACHMENTS,
    IDC_PICTURES,
};

constexpr UINT_PTR TIMER_MARK_READ = 1;
