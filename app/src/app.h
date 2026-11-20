// Shared pieces of the windows: DPI scaling, child controls, text formatting and the small dialogs. Everything shown
// comes from the core (core.h) already decoded; nothing here parses mail data.
#pragma once

#include <windows.h>

#include <commctrl.h>
#include <functional>
#include <map>
#include <optional>

#include <cstdint>
#include <string>
#include <unordered_map>
#include <unordered_set>
#include <vector>

#include "commands.h"
#include "core.h"
#include "preview.h"
#include "reader.h"

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
// the date of `local` in the user's short date format
std::wstring FormatDay(const SYSTEMTIME& local);
// seconds since the Unix epoch, now
int64_t UnixNow();
// a time of day as the user's settings write it, without seconds: of `local`, or now
std::wstring FormatTime(const SYSTEMTIME& local);
// the event cards of the core word their days and times as the windows show dates
void SetInstantFormat();
// seconds since the Unix epoch as a SYSTEMTIME, the reader's local time when `local`, else UTC; false for a date
// Windows can not hold
bool UnixToSystemTime(int64_t seconds, bool local, SYSTEMTIME& time);
std::wstring TimeNow();
// 1.2 KB, 3 MB
std::wstring FormatSize(uint64_t bytes);
// `text` on the clipboard, `owner` owning it; false when the clipboard could not be had
bool CopyText(HWND owner, const std::wstring& text);
// the brush of dialog backgrounds, for WM_CTLCOLORSTATIC
LRESULT ButtonFaceColor(HDC dc);
// the reason the core gave for a refusal (freed here), or `fallback` when it gave none
std::wstring ReasonText(char* reason, PeText fallback);
// WM_SETCURSOR of a window of the app: the busy pointer set while it is shown; false when it is not
bool BusyCursor();
// the Junk button of a toolbar (main and message windows) as Not Junk for messages in a Junk folder (`inJunk`), or
// back as Junk; true when it changed, the toolbar sized again then
bool SetJunkButton(HWND toolbar, bool inJunk);

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
// the folder strip's icon for the core's word for a folder list row ("inbox", "account"; a plain folder for any other)
int FolderIcon(const char* word);
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
void SetColumnTitle(HWND list, int index, const std::wstring& title);
// the list of a dialog (Accounts, Outbox): one row selected at a time, full rows, columns that do not sort
HWND CreateReportList(HWND parent, int id, const RECT& bounds);
// a row with the text of its first column; its index
int AddRow(HWND list, int index, const std::wstring& text);
void SetCell(HWND list, int row, int column, const std::wstring& text);
// selects and focuses `row`, or the last one when there are fewer
void SelectRow(HWND list, int row);

// the icon strips of app/res/toolbar (icons.h): their image list at the size closest to the DPI, loaded once
// the security bar's are drawn over the fill of its tone, in the color of its words
// the attachment strip's are a file of each kind the core names
enum class IconSet { Toolbar, Format, Folders, List, Files, SecureVerified, SecureGood, SecureWarning, SecureNeutral };
HIMAGELIST IconList(IconSet set);
// text for a menu item: a & in it stays a & rather than making the next character a shortcut
std::wstring MenuText(std::wstring text);
// a menu item of the catalogs (`&` marking its letter) with its shortcut, the key names in the language in use:
// Shortcut(L"Ctrl+Shift+R") in the language's key names: "Strg+Umschalt+R" in German
std::wstring Shortcut(std::wstring_view keys);
// MenuItem(PE_TEXT_CMD_PRINT, L"Ctrl+P") is "&Drucken...\tStrg+P" in German
std::wstring MenuItem(PeText text, std::wstring_view keys = {});
// a menu item that opens a dialog, with the ellipsis that says so where the catalog's word has none
std::wstring DialogMenuItem(PeText text, std::wstring_view keys = {});
// a flat toolbar, a child of `hwnd`; `style` adds CCS_* and TBSTYLE_* styles. Its icons (icons.h): the big ones with
// the label under them (main and compose windows), or the small ones of the format bar, the label as the tooltip
enum class BarIcons { Big, Small };
HWND CreateBar(HWND hwnd, DWORD style, int id, BarIcons icons);
// a button on a bar of CreateBar, with its icon (icons.h) or I_IMAGENONE; id 0 is a separator
void AddButton(HWND bar, int id, const wchar_t* text, BYTE style = BTNS_BUTTON, int image = I_IMAGENONE);

// a tree row with its text, data, boldness and icon of the folder strip, last under `parent`
HTREEITEM InsertItem(HWND tree, HTREEITEM parent, const std::wstring& text, LPARAM data, bool bold, int icon);
// the colour of a flag (1 red to 7 gray, Apple Mail's), and a flag of `size` pixels in it at `left`, `top`
COLORREF FlagRgb(int color);
void DrawFlag(HDC dc, int left, int top, int size, COLORREF rgb);
// a row's flag in its colour (red for none, 0), on a selected row on a plate of the list's background so that a
// colour close to the highlight's can still be seen
void DrawFlagMark(HDC dc, int left, int top, int size, bool selected, int color);
// a mark of the list strip (the paper clip, the lock) of `size` pixels at `left`, `top`; on a selected row on the same
// plate as the flag, so its smoothed edges and dark ink do not sit on the highlight
void DrawListMark(HDC dc, HIMAGELIST strip, int icon, int left, int top, int size, bool selected);
// the mark of a row's protection in the list strip, as the security bar shows it: the lock for an encrypted message
// (also when it is signed inside), the seal for a signed one; -1 for neither
int SecurityIcon(const PeMessage& row);
// the field of a View > Sort By item, and the item of a field (columnrow.cpp)
PeSortField SortFieldOfItem(WORD id);
WORD SortItemOf(PeSortField field);
// one glyph of the Marlett font (the symbols of the system's own buttons: "r" a close box, "6" a down arrow) centered
// in `box`, `height` pixels high
void DrawMarlettGlyph(HDC dc, const RECT& box, wchar_t glyph, int height, COLORREF color);
// the core's pixels of a picture (`size` x `size` BGRA with the alpha multiplied in, `length` bytes) as a bitmap;
// nullptr when they are not that
HBITMAP PremultipliedBitmap(const uint8_t* pixels, size_t length, int size);
// PremultipliedBitmap of pixels the core handed over, which are freed here (pe_bytes_free), NULL taken as none
HBITMAP CoreBitmap(uint8_t* pixels, size_t length, int size);
// such a bitmap drawn at `x`, `y` with its own transparency, through `memory` when given (a DC kept for many
// pictures), else one made for it
void DrawPremultiplied(HDC dc, int x, int y, HBITMAP bitmap, int size, HDC memory = nullptr);
// a tooltip of `text` over the child `tool` of `owner`
void AddTip(HWND owner, HWND tool, const std::wstring& text);
// how wide the words of a control are in `font` (the dialog font when NULL), its & left out
int TextWidth(HWND control, HFONT font);

// how big `text` is in the dialog font, its & left out: one line, or wrapped at `wrapWidth` when it is not 0. `flags`
// are DrawText's more (DT_EDITCONTROL); with DT_NOPREFIX the & are measured as they are
SIZE MeasureText(const std::wstring& text, int wrapWidth = 0, UINT flags = 0);
// a push button wide enough for the longest of `labels`, at least `least` pixels at 96 DPI
int ButtonWidth(std::initializer_list<std::wstring> labels, int least = 80);
int ButtonWidth(const std::vector<std::wstring>& labels, int least = 80);
// a column of labels as wide as its widest label plus `margin`, at least `least` (both unscaled)
int LabelWidth(std::initializer_list<std::wstring> labels, int least, int margin = 8);
int LabelWidth(const std::vector<std::wstring>& labels, int least, int margin = 8);

// a part of a form under its fields with controls of its own (Account Properties > Security): made in the form, told
// of their commands, and what they hold taken when OK is accepted, before the form is gone
struct FormPart {
    virtual ~FormPart() = default;
    // its height in a form `width` wide
    virtual int Height(int width) const = 0;
    virtual void Create(HWND form, const RECT& area) = 0;
    virtual void Command(HWND form, int id, int code) = 0;
    virtual void Accept(HWND form) = 0;
};

// a modal form with a label and an input for each field; true with the values filled in when OK was clicked.
// `validate` gets the values and returns an error to show, or an empty string to accept them.
// `okLabel`: the default button, OK when null. `focus`: the field to start in. `part`: controls under the fields
bool FormDialog(HWND owner, const std::wstring& title, const std::wstring& intro, std::vector<FormField>& fields,
                bool (*validate)(const std::vector<FormField>&, std::wstring& error) = nullptr, const wchar_t* okLabel = nullptr,
                size_t focus = 0, FormPart* part = nullptr);
// an owner-drawn button (CreateLinkButton) drawn as a link: underlined, in the link color, a focus rectangle around
// the words
void DrawLinkButton(const DRAWITEMSTRUCT& item);
// a button that looks like a link (draw it with DrawLinkButton); Tab reaches it and Enter or Space clicks it
HWND CreateLinkButton(HWND parent, const wchar_t* text, int id, const RECT& bounds);
// a label clicked as a link (SS_NOTIFY) that the keyboard reaches too: a Tab stop with a focus rectangle, Enter or Space
// clicks it (STN_CLICKED to its window)
void KeyboardLink(HWND label);
// Alt with a letter in a window that is no dialog (the main window, a message window): the push button anywhere in
// `root` whose text marks that letter (&Details...), visible and enabled, clicked; false when there is none
bool ClickMnemonic(HWND root, wchar_t letter);
// for WM_SETCURSOR of the window with the links: the hand over a link; true when it set it
bool SetLinkCursor(HWND hwnd, WPARAM wParam);
// what a screen reader says about a control besides its name (the reason a button is turned off); of one of its items
// with `child` (a list view's item from 1)
void SetAccessibleDescription(HWND control, const std::wstring& text, long child = CHILDID_SELF);
// the name a screen reader gives a control that has no label of its own
void SetAccessibleName(HWND control, const std::wstring& text);
// a dialog window centered on the window of `owner`, owned by it, with this client size; RunModal shows it, runs it
// until `done` and destroys it, the owner disabled meanwhile
HWND CreateModalWindow(HWND owner, const wchar_t* className, const wchar_t* title, int clientWidth, int clientHeight);
void RunModal(HWND dialog, HWND focus, const bool& done);
// RunModal sends it to the dialog with each key pressed in it (wParam the key, as WM_KEYDOWN has it) before the dialog
// keys: a dialog that answers TRUE took the key (Options' Ctrl+Tab)
constexpr UINT WM_MODAL_KEY = WM_APP + 90;
// the button `id` of a dialog RunModal runs made its default, the one Enter clicks, in place of the one before
void SetDefaultButton(HWND dialog, int id);
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
// the PNG resource named `resource` at `height`, on `background`; `width` its width then
HBITMAP LoadPicture(const wchar_t* resource, int height, COLORREF background, int& width);
// registers a window class of a dialog (button face background, arrow cursor) once
void RegisterDialogClass(const wchar_t* name, WNDPROC proc);
// the app's icon (app.rc): the small one of the title bar, or the large one of Alt+Tab
HICON AppIcon(bool titleBar);
// both for a window class
void SetAppIcons(WNDCLASSEXW& windowClass);
// a folder chosen in the Windows folder picker, empty when cancelled
std::wstring FolderDialog(HWND owner, const wchar_t* title);
// the files chosen in an Open dialog that takes several, none when cancelled
std::vector<std::wstring> OpenFilesDialog(HWND owner, const wchar_t* title, const wchar_t* filter = nullptr);
// the one file chosen in an Open dialog, empty when cancelled
std::wstring OpenFileDialog(HWND owner, const wchar_t* title, const wchar_t* filter);
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
// test runs (--opened-files-log): an attachment opened is written to this file, a line of its path, not opened; a
// link opened in the browser too, a line of its address
void SetOpenedFilesLog(const std::wstring& path);
// File > Accounts: the accounts listed, to add, change (Properties) or remove; true when one changed
bool AccountsDialog(HWND owner, PeCore* core);
// the Properties of one account, as File > Accounts > Properties opens them (the account row's menu); true when saved
bool AccountPropertiesDialog(HWND owner, PeCore* core, int64_t account);
// asks for the password of an account; false when cancelled
bool PasswordDialog(HWND owner, const std::wstring& account, std::wstring& password);

// ---- signinapps.cpp ----

// File > Accounts > Sign-in Apps: the built-in clients and the added sign-in apps, to turn on and off, add, change
// or remove
void SignInAppsDialog(HWND owner, PeCore* core);
// the editor of a sign-in app: a new one when `app` is NULL; the id of the app saved, 0 when cancelled
int64_t SignInAppEditor(HWND owner, PeCore* core, const PeSignInApp* app);

// ---- rules.cpp ----

// Tools > Message Rules: the rules that sort new mail, to turn on and off, add, change, order and delete
void MessageRulesDialog(HWND owner, PeCore* core);
// the editor of a new rule that matches `query`, named after it (Create Rule from Message, the search bar's Create
// Rule); the id of the rule saved, 0 when cancelled
int64_t NewRuleDialog(HWND owner, PeCore* core, const std::wstring& query);

// ---- keys.cpp ----

// Tools > Encryption Keys: the user's own OpenPGP keys and their contacts', to make, import, export, back up, verify,
// look at and remove
void EncryptionKeysDialog(HWND owner, PeCore* core);
// Verify Key: the fingerprint of `fingerprint` large, to compare with its owner and mark the key verified, or no
// longer; true when that changed
bool VerifyKeyDialog(HWND owner, PeCore* core, const std::string& fingerprint);
// a key's status as the windows say it: the core's words, with "verified" for a contact's key the user verified
// Account Properties > Security of `account`: the key of its addresses and whether its mail carries the key
// (Autocrypt); what OK took is applied by ApplyAccountSecurity once the account is saved
std::unique_ptr<FormPart> AccountSecurityPart(PeCore* core, int64_t account);
void ApplyAccountSecurity(FormPart& part);
// asks for a passphrase: `intro` over it, `problem` (why the last one was not taken) between them when not empty, and
// with `twice` a second field to type it again; true with it in `passphrase` (the caller wipes it)
bool PassphraseDialog(HWND owner, const std::wstring& title, const std::wstring& intro, const std::wstring& problem, bool twice,
                      std::string& passphrase);
// what is typed in the hidden field `edit` as UTF-8, its copies here wiped; and a secret gone from memory
std::string ReadSecret(HWND edit);
void Wipe(std::string& secret);
// the fields `ids` of `dialog` written over before the window goes, as far as the edit control lets them be
void WipeFields(HWND dialog, std::initializer_list<int> ids);
// what the core says of the passphrase typed in the fields `first` and `again`, shown in the warning note `line`
// (hidden while there is nothing to say); whether the core takes it
bool ShowPassphraseFeedback(HWND dialog, int first, int again, int line);
// a note with the system's warning sign before it, `text` wrapped between `left` and `right`: its height. A warning
// to keep in mind, not an error
int WarningNote(HWND dialog, int id, const std::wstring& text, int left, int top, int right);
// OK and Cancel (or the words given) at the bottom right of a window `width` wide, their top at `top`; the first is
// the default unless `cancelDefault`
void BottomButtons(HWND dialog, int width, int top, const std::wstring& ok, const std::wstring& cancel, bool cancelDefault = false);
// a question as a message box asks it, with the answers `yes` and `no` on its buttons (& marks their letters): `yes`
// the default, or `no` with `safeDefault` (Esc is always `no`); true for `yes`
bool Ask(HWND owner, const std::wstring& title, const std::wstring& text, const std::wstring& yes, const std::wstring& no,
         bool safeDefault = false);
// New Key for `account` (chosen in it), and a backup offered once it is made: its fingerprint, empty when cancelled
std::string NewKeyFor(HWND owner, PeCore* core, int64_t account);

// ---- setup.cpp ----

// File > Export Settings and Accounts: the parts chosen, a passphrase when wanted, the file written where the user
// chooses, and what it holds said
void ExportSetupDialog(HWND owner, PeCore* core);
// what an import did, for the main window to show: the accounts added (they sync), and the app preferences of the
// file by their shared names when Window preferences were imported
struct SetupPref {
    std::string name;
    // checked by the core, ready to set
    std::string value;
    // it counts once the app starts again (the language)
    bool restart = false;
};
struct SetupImported {
    bool imported = false;
    std::vector<int64_t> accounts;
    std::vector<SetupPref> prefs;
};
// File > Import Settings and Accounts: a setup file chosen, its passphrase asked for when it has one, what it holds
// chosen and imported, and what was added and skipped said
SetupImported ImportSetupDialog(HWND owner, PeCore* core);

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
// the UI test's look at the newest Print window: the pictures its page has as data: addresses that have loaded, times
// 10, plus 1 when its page has `text`; -1 without one or before the first answer (each look answers the one before)
int64_t TestPrint(const std::wstring& text);

// ---- securitybar.cpp ----

// the security bar of a signed or encrypted message's state (`tone`, not NONE) drawn in `area`: the tone's fill and
// frame, the lock when `encrypted` and the tone's own picture (a shield with a check, a ribbon, a warning sign; none
// for neutral), and `words` wrapped in `font`, leaving `reserved` pixels free at its right (the Details button)
void DrawSecurityBar(HDC dc, const RECT& area, PeProtectionTone tone, bool encrypted, const std::wstring& words, HFONT font, int reserved);
// the height of that bar `width` wide: one line keeps the same height from message to message, more lines make it taller
int SecurityBarHeight(PeProtectionTone tone, bool encrypted, const std::wstring& words, HFONT font, int width, int reserved);
// the Security Details window over `owner`: the state as the bar shows it (`summary`), the core's `details` of each
// part to read and copy, Close; F1 opens the help of signed and encrypted mail. `part`: the part whose label was
// clicked (0 the first) at the top of the text, -1 for the top
void SecurityDetailsDialog(HWND owner, PeProtectionTone tone, bool encrypted, const std::wstring& summary, const std::wstring& details,
                           int part);

// ---- help.cpp ----

// opens the help window at the topic of `context` (pe_help_context: `main`, `account-form`, `options`...), or brings
// it to the front and shows that topic there
void OpenHelp(const char* context = "main");
void CloseHelp();
// F1 in `window`: the help at the topic of its context, or of the window that owns it (the main window's when none has
// one); nothing in the help itself
void HelpKey(HWND window);
// the windows CreateModalWindow makes while it lives have the help context `context` (a string literal), which F1 in
// them and in the windows they own opens
class HelpScope {
public:
    explicit HelpScope(const char* context);
    ~HelpScope();
    HelpScope(const HelpScope&) = delete;
    HelpScope& operator=(const HelpScope&) = delete;

private:
    const char* previous_;
};
// CreateModalWindow and RunModal: the context of the scope given to a new dialog, taken away before it is destroyed
void SetHelpContext(HWND window);
void ClearHelpContext(HWND window);

// ---- compose.cpp ----

// opens a window to write a message from `account`, with the fields of `draft` (NULL for a new message)
// a compose window of its own on the taskbar, not owned by `main` (so the main window can come in front of it); it
// tells `main` when it is gone
HWND OpenCompose(HWND main, PeCore* core, int64_t account, const PeDraftInfo* draft);
// opens again the messages that were being written when the app last ended without closing them
void OpenRecoveredCompose(HWND main, PeCore* core);
// the UI test's crash (--test-hooks): every compose window gone without closing, then those kept for a crash opened
// again; how many are open after
size_t TestAbandonCompose(HWND main, PeCore* core);
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
// for the UI test: the count the taskbar button's overlay shows (0 for none), -1 before the button is there, -2 when
// Windows refused the overlay
int64_t TrayBadge();
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
// what Tools > Options sets of the main window: the new mail notifications and whether they name sign-in codes, the
// list grouped by conversation, the layout (a PeLayoutMode) and the senders' pictures in the list
struct WindowOptions {
    bool notify = false;
    bool codes = false;
    bool threads = false;
    int layout = 0;
    bool listPictures = true;
    // the core's, set by the window as the views of the messages shown are built again with them
    bool previews = true;
    bool pdfPreviews = true;
    bool operator==(const WindowOptions&) const = default;
};
// Tools > Options, a tab for each page of core/settings.toml, the main window's settings from `window`; OK and Apply
// hand `apply` what it is to set, Cancel undoes what was changed since the last Apply. True when the user chose to
// restart now for a new language
bool OptionsDialog(HWND owner, PeCore* core, const WindowOptions& window, const std::function<void(const WindowOptions&)>& apply);
// the core turned PDF previews off (PdfPreviewsOff): an open Options shows it so, as set
void OptionsPdfPreviewsOff();
// Tools > Make Default Mail App, and its button in Options: Windows' Default Apps settings, where only the user can
// choose it, or what says it is chosen already
void MakeDefaultMailApp(HWND owner);
// the language of the windows set to `code` (empty: Windows' own), as Options sets it; true when the user chose to
// restart now for it (asked only when it is not the language of the windows now)
bool ChooseLanguage(HWND owner, const std::wstring& code);

// ---- addressbook.cpp ----

// Tools > Address Book: a window of its own with the groups and the people, brought to the front when it is open
void OpenAddressBook(PeCore* core);
// the book changed outside the window (Add Sender, an import): an open Address Book shows it again
void AddressBookChanged();
// the Address Book window, gone, before the core it uses is
void DestroyAddressBook();
// Select Recipients of a compose window: the book's people and groups put into To, Cc and Bcc (`fields`, their texts,
// changed in place); true when OK was clicked
bool SelectRecipients(HWND owner, PeCore* core, std::wstring (&fields)[3]);
// File > Import Address Book and Export Address Book: what the status bar says, empty when cancelled (a failure is
// told in a message box)
std::wstring ImportAddressBook(HWND owner, PeCore* core);
std::wstring ExportAddressBook(HWND owner, PeCore* core);

// ---- complete.cpp ----

// completes the address the cursor is in, in an address field (To, Cc, Bcc), from the address book and the people
// written to and heard from: a list under the field as you type, arrows to choose, Enter or Tab to take one, Esc to
// close it, Shift+Delete to forget someone
void CompleteAddresses(HWND edit, PeCore* core);

// the signature of an account in an editor of its own (Accounts > Signature); whether it was saved
bool EditSignature(HWND owner, PeCore* core, int64_t account, const std::wstring& name);
// the compose windows, gone without asking, before the core they use is
void DestroyComposeWindows();
// the save of the draft `messageId` finished, `problem` empty when it worked: the window that saved it says so;
// false when that window is no longer open
bool ComposeDraftSaved(const std::string& messageId, const std::wstring& problem);
// the keys of a compose window that its fields do not take (the editor has its own): Ctrl+S saves the message in
// Drafts, Ctrl+Shift+D and Ctrl+Shift+E are Digitally Sign and Encrypt; true when handled
bool ComposeKey(const MSG& msg);
// a lookup of keys ended (the KeysFound event, `request` its uid): the compose window that asked takes what it found
// (and says so in its status bar), and every compose window shows its recipients' keys again
void ComposeKeysFound(uint64_t request);

// ---- recipientkeys.cpp ----

// what Recipients' Keys asks of the compose window it is over
struct RecipientKeysCalls {
    // the window's signing and encrypting now (pe_compose_security of its message), owned by the window: read it
    // anew each time, as the window replaces it whenever the message changes
    std::function<const PeComposeSecurity*()> security;
    // Find Key for one recipient, Remove from Message
    std::function<void(const std::string& address)> findKey;
    std::function<void(const std::string& address)> remove;
    // a key's use decided (Use the New Key, Keep the Current One): the window shows it
    std::function<void()> changed;
    // each of these ends in RefreshRecipientKeys, which reads the recipients again
};
enum class RecipientKeysAnswer { Cancel, Send, SendUnencrypted };
// Recipients' Keys over a compose window: each recipient with their key, Find Key, Remove from Message, the waiting
// key's decision, and Send Without Encryption or Send. `open` holds the window while it is open, for
// RefreshRecipientKeys
RecipientKeysAnswer RecipientKeysDialog(HWND owner, PeCore* core, const RecipientKeysCalls& calls, HWND& open);
// the message or a key changed: the open Recipients' Keys reads its recipients again
void RefreshRecipientKeys(HWND dialog);
// the picture of a recipient's key in the security strips: a warning for none, else the lock, in its tone's strip
IconSet RecipientKeySet(const PeComposeRecipient& recipient);
int RecipientKeyPicture(const PeComposeRecipient& recipient);
// the colors of the security bar's tone (securitybar.cpp): its fill, frame and words
struct ToneColors {
    COLORREF frame;
    COLORREF fill;
    COLORREF words;
};
ToneColors TonePalette(PeProtectionTone tone);

// ---- messagewindow.cpp ----

class Mailbox;
// the list a message window was opened from, for Previous and Next: a copy of the main window's list view, one message
// a row; and the folder it shows (0 with neither it nor All Inboxes: a search), for which messages it can have
struct MessageListOrder {
    core::ListView view;
    int64_t folder = 0;
    bool allInboxes = false;
};
// the message `uid` of `folder` in a window of its own (double-click or Enter in the list), marked read; brought to the
// front when it is open already. A window of its own on the taskbar, as a compose window is; what it does to the
// message the status bar of `main` says (through `mailbox`)
// (`row`: its row of the list, for the header until the message is there; NULL for none)
void OpenMessageWindow(HWND main, PeCore* core, Mailbox* mailbox, MessageListOrder order, int64_t folder, uint64_t uid,
                       const PeMessage* row);
// a message file (.eml) opened from File Explorer in a window of its own: Reply, Reply All and Forward (from the
// account the main window has), Print and Save As; it is no folder's, so it can not be moved, flagged or deleted.
// Brought to the front when it is open already; false with what to say over `main` for a file that is no message.
bool OpenMessageFile(HWND main, PeCore* core, Mailbox* mailbox, const std::wstring& path, std::wstring& error);
// an event of the core for the open message windows: their message ready or failed, gone from its folder
void MessageWindowsEvent(const UiEvent& event);
// the readers of the open message windows, to build their views again after a setting they follow changed (the
// previews: Reader::Rebuild)
std::vector<Reader*> MessageWindowReaders();
// the UI test's look at the previews of the message in the first message window (Preview::TestPreviews), -1 for none
int64_t MessageWindowTestPreviews(const std::wstring& query);
// a key in a message window that is one of its shortcuts (Esc, Delete, Ctrl+R, Ctrl+Shift+R, Ctrl+F, Ctrl+P): true when
// handled
bool MessageWindowKey(const MSG& msg);
// the message windows, gone, before the core and the mailbox they use are
void DestroyMessageWindows();

// ---- folderpane.cpp ----

// the height of the "Folders" caption over the folder list
int FolderCaptionHeight();
// the caption, a child of `parent`, in `font`: its button the close box (View > Folder List off), or with `pin` the
// drop-down's pushpin (View > Folder List on again). The button posts IDM_FOLDER_LIST to the main window
HWND CreateFolderCaption(HWND parent, bool pin, HFONT font);
// while the folder list is hidden: the folder `tree` (a child of `owner`) in a drop-down under the screen rectangle
// `under`, `width` by `height`; it closes when a folder is clicked, with Enter or Esc, or a click elsewhere, the tree
// then back in `owner`, hidden
void OpenFolderDrop(HWND owner, HWND tree, const RECT& under, int width, int height);
void CloseFolderDrop();
bool FolderDropOpen();

// ---- main.cpp ----

// the main window back from the tray (or the taskbar), in front
void ShowMain();
// a card's picture was set or taken away (Contact Properties): the list's rows of its address show it again
void ContactPictureChanged();
// a new message from a mailto: link (the core reads it), from `account`, or from the account of what the main window
// shows when 0
void OpenMailto(const std::wstring& link, int64_t account = 0);
// a new message to `to` (as it goes in the To field), from the account of what the main window shows (Write To)
void WriteTo(const std::wstring& to);
// the words put into the Find box of the main window, which searches for them at once (the rule editor's Show)
void SearchFor(const std::wstring& words);
// File > Import Settings and Accounts (and Add Mail Account's link before the first account): the import, then the
// app preferences it brought set (what else it changed comes as the core's events); the first account added, 0 for
// none
int64_t ImportSetup(HWND owner);

// ---- mailbox.cpp ----

// an event of the core, copied on the worker thread and posted to the window thread
struct UiEvent {
    PeEventKind kind;
    int64_t account;
    int64_t folder;
    uint64_t uid;
    PeFailureKind failure;
    std::wstring message;
    // the Message-ID of a draft, for DraftSaved; the notification's text, for NewMail (`message` its title)
    std::string detail;
    // how many messages, for NewMail and RulesApplied
    uint64_t count = 0;
};

// ---- listpictures.cpp ----

// the senders' pictures of the Columns list, drawn by the core once for each key and size and kept for the run
class ListPictures {
public:
    ~ListPictures();
    void Init(PeCore* core) { core_ = core; }
    // the picture `key` drawn `size` pixels square; nullptr while the core draws it (asked once) or when there is none
    HBITMAP Get(uint64_t key, int size);
    // a PictureReady of `request`: the key whose picture is now there, 0 for none
    uint64_t Ready(uint64_t request);
    void Clear();

private:
    struct Picture {
        HBITMAP bitmap = nullptr;
        // the core is drawing it: not let go of
        bool pending = false;
        // when it was last drawn, for letting go of the oldest
        uint64_t used = 0;
    };
    void Trim();

    PeCore* core_ = nullptr;
    // by key and size
    std::map<std::pair<uint64_t, int>, Picture> pictures_;
    // the requests the core is drawing, and what for
    std::unordered_map<uint64_t, std::pair<uint64_t, int>> requests_;
    uint64_t clock_ = 0;
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
    // places the Find box at the right of the toolbar row, as wide as the buttons leave room for; returns its left
    int PlaceFind(const RECT& row, int buttonsRight);
    // the UI test's stand-ins for what the system does: a drag of the selected messages dropped into the folder `dir`
    // as Explorer drops it (the files written, -1 for none), and files dropped onto the tree item `item`; the effect
    int TestDragOut(const std::wstring& dir);
    // the UI test's click on a link of the message shown: whether it was one of the document's own
    bool TestLink(const std::wstring& uri) { return reader_.FollowLink(uri.c_str()); }
    // the UI test's look at the parts of a signed or encrypted message shown (Reader::TestFrames)
    int64_t TestFrames() { return reader_.TestFrames(); }
    // the UI test's look at the last Find in This Message (Reader::TestFound), and at the message shown: 1 when it has
    // loaded with this subject, or with none given when it is the message of the selected row (Reader::TestShown)
    int TestFound() const { return reader_.TestFound(); }
    int TestShown(const std::wstring& subject);
    // the UI test's count of requests of the message shown to the internet (Preview::RemoteRequests)
    int TestRemoteRequests() const { return reader_.RemoteRequests(); }
    // the UI test's look at the previews of the message shown (Preview::TestPreviews)
    int64_t TestPreviews(const std::wstring& query) { return reader_.TestPreviews(query); }
    // the reader of the message shown, to build its view again after a setting it follows changed (Reader::Rebuild)
    Reader* MessageReader() { return &reader_; }
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
    // Add Sender to Address Book: the sender of the message shown, what was done said in the status bar
    void AddSenderToBook(HWND owner);
    // the message list's right-click menu at `screen`, or at the selected row for (-1, -1) (the menu key)
    void MessageMenu(POINT screen);
    HWND List() const { return list_; }
    HWND Tree() const { return tree_; }
    // the right-click menu while it is open, for the UI test
    HMENU OpenMenu() const { return lastMenu_; }
    void Import(HWND owner);
    bool ClearFind();
    void ResetFind();
    void OnTimer(UINT_PTR id);
    void OnEvent(const UiEvent& event);
    // a folder was clicked, or the list's order or grouping changed, and its list is read off the window thread
    // (pe_list_view_load, after the click is painted): meanwhile the list before stays, dimmed, and the status bar
    // keeps its counts
    bool ListPending() const { return listPending_; }
    // a command of the menus, toolbar or keys that acts on the list (`id`, `code` of its WM_COMMAND) while that list
    // waits: run once it is drawn (or could not be read); false when it does not wait
    bool DeferCommand(WORD id, WORD code);
    // the UI test's look at the list: 9 a load of it not here yet, else of the last folder clicked: 10 none clicked, 11
    // its list read before the highlight was painted, 12 the highlight painted first
    int TestListOrder() const { return listPending_ || loadRequest_ ? 9 : testListOrder_ + 10; }
    // the UI test holds the list of a folder clicked unread (`hold`), to see it waiting, and lets it go
    void TestHoldList(bool hold);
    // the accounts changed: builds the tree again
    void Reload();
    // a contact's picture changed: the rows (and their picture keys) read again, the selection kept
    void ReloadRows() { ReloadList(); }
    // what the last action on messages did, for the status bar (IDC_LIST, kSaid)
    const std::wstring& Said() const { return said_; }
    // the selected messages read or unread
    void MarkSelected(bool seen);
    // how many messages are selected, and what they are in numbers (count 0 with none); none while a list waits
    size_t SelectedCount() const;
    const PeSelectionSummary& Summary() const { return summary_; }
    // Edit > Select All: every message of the list
    void SelectAll();
    // Edit > Undo: the last move, delete or junk taken back; what the menu calls it, empty when there is nothing
    void Undo();
    std::wstring UndoLabel() const;
    // every message of the selected folder read, or of every Inbox from All Inboxes (Edit > Mark All Read, the folder's
    // menu); nothing while searching. Off the window thread, the status bar told once done (Acted)
    void MarkAllRead();
    // every message of `account` read (the account row's menu), as MarkAllRead
    void MarkAccountRead(int64_t account);
    // the message `uid` of `folder` shown: its folder chosen in the tree, the message selected in the list
    void ShowMessage(int64_t folder, uint64_t uid);
    // the window shown the first time: All Inboxes (two or more accounts) or the first account's Inbox chosen, and its
    // newest message selected
    void SelectStart();
    // the selected messages junk ($Junk, into the Junk folder) or not junk ($NotJunk, into the Inbox)
    void MarkJunk(bool junk);
    // out of the Inbox into the account's Archive (on Gmail every label taken off)
    void ArchiveSelected();
    // Create Rule from Message: the editor of a new rule for the sender or the mailing list of the message shown
    void CreateRuleFromShown(HWND owner);
    // the words put into the Find box, searched for at once
    void Search(const std::wstring& words);
    // every selected message can be archived
    bool CanArchive() const;
    // whether the selected messages, or else the folder, are in a Junk folder: the toolbar offers Not Junk there
    bool InJunk() const;
    // the Unsubscribe link of the message shown, after asking: what the status bar says; a mailto: link to write a
    // message to in `mailto` when the list wants one
    std::wstring Unsubscribe(std::wstring& mailto);
    // the one-click unsubscribe `request` done, or not for `problem`: what the status bar says, empty for another
    std::wstring Unsubscribed(uint64_t request, const std::wstring& problem);
    // what was done to messages, in the main window's status bar (the message windows say it there too)
    void Say(const std::wstring& text);
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
    // Deleted Items or Junk E-mail emptied for good, after asking
    void EmptyFolder(HWND owner);
    // the message below the one shown in the list (`forward`), or above it, selected and shown as a click would
    void SelectNeighbour(bool forward);
    // the next unread message of the list after the one shown; with none, after asking, the next folder with unread
    // mail and its first unread message
    void NextUnread(HWND owner);
    // a folder chosen in the Move and Copy window's tree of every account, selected in the tree
    void GoToFolder(HWND owner);
    // Find in This Message in the reading pane (`again`: F3, the next place of the words)
    void FindInMessage(HWND owner, bool again);
    // the folder shown is Deleted Items or Junk E-mail with messages in it
    bool CanEmptyFolder() const;
    // Edit > Mark All Read applies to the list shown: a folder's or All Inboxes'
    bool CanMarkAllRead() const;
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
    // the account whose own row is selected in the tree (the account row's menu is for it), 0 when another row is
    int64_t SelectedAccount() const;
    // File > Folder > New Folder applies to the row selected in the tree
    bool CanNewFolder() const;
    // the selected account row, or the selected Inbox under All Inboxes, moved `step` places in the accounts' order (-1
    // up, 1 down): the account menu's Move Up and Move Down
    void MoveAccount(int step);
    // the account `folder` is in, 0 when it is not known
    int64_t AccountOf(int64_t folder) const;
    // whether `folder` is the Inbox of its account
    bool IsInbox(int64_t folder) const { return inboxFolders_.contains(folder); }
    // a reply, reply to all or forward of the message shown, made off the window thread: `done` gets it (empty when the
    // message is not here) with the account to write from; false when no message is shown
    bool DraftOfShown(PeDraftKind kind, std::function<void(core::Draft, int64_t)> done);
    // the selected message in a window of its own (double-click or Enter); a draft in a compose window instead, to go
    // on writing it, once it is fetched when it is not yet
    void OpenSelected();
    // the saved draft read for OpenSelected is here (ReadDone `request`): in a compose window
    void OpenDraftRead(uint64_t request);
    // the list as it is now: what it shows and in which order, for Previous and Next in a message window
    MessageListOrder ListOrder() const;
    // whether the list has a row a conversation (Tools > Options, kept for the next start), and turning that on or off
    bool Grouped() const { return pe_list_view_grouped(view_.get()); }
    void SetGrouped(bool on);
    // View > Expand All Conversations (`open`) and Collapse All Conversations
    void ExpandAll(bool open);
    // Message > Watch Conversation (PE_ACTION_WATCH) and Ignore Conversation (PE_ACTION_IGNORE) on the selected
    // messages' conversations, or the mark taken away when all of them have it; the status bar says what was done
    void MarkConversations(PeAction action);
    // the check marks of those two in `menu`: checked when every selected message has the mark
    void UpdateConversationMarks(HMENU menu);
    // View > Hide Ignored Conversations, kept for the next start, and turning it on or off
    bool HideIgnored() const { return hideIgnored_; }
    void SetHideIgnored(bool on);
    // View > Hide Read Messages and the toolbar's Unread: every folder's unread messages only, kept for the next
    // start; a message read stays listed until the list shows another folder (the core keeps it)
    bool UnreadOnly() const { return unreadOnly_; }
    void SetUnreadOnly(bool on);
    // the list subclassed for the conversations: Right and Left, and a click on a + or - box; true when handled
    bool OnListInput(UINT message, WPARAM wParam, LPARAM lParam);
    // the Columns layout (`on`): the list a row of three lines a message, without column headings, "Sorted by" over
    // it; or the classic columns. The selection, the open conversations and the row in view stay
    void SetColumns(bool on);
    bool Columns() const { return columns_; }
    // Tools > Options > Show senders' pictures in the message list: a brand's logo or the initials beside each row of
    // the Columns list, kept for the next start
    bool ListPicturesShown() const { return listPictures_; }
    void SetListPictures(bool on);
    // the UI test's look at the row of the message `subject`: 12 its picture drawn, 11 its initials, 10 neither, 0 no
    // such row shown
    int TestRowPicture(const std::wstring& subject);
    // the UI test's look at where the list's top row starts: 1000 plus its top in the list's client area (the header's
    // room above it, if any); 0 for an empty list
    int TestListTop() const;
    // View > Sort By: by `field` (starting its own way when it is another field), and which way
    void SortBy(PeSortField field);
    void SetAscending(bool ascending);
    // the Sort By menu, for the View menu and the "Sorted by" button (owned by the menu it is put in), and its check
    // marks as the list is sorted now
    static HMENU SortMenu();
    void UpdateSortMenu(HMENU menu) const;

private:
    struct Page {
        uint64_t offset = 0;
        core::MessageList rows;
    };

    // what each row of the tree is, as the core gives it (pe_folder_tree): a tree item's data is its index in treeRows_
    struct TreeRow {
        PeTreeRowKind kind = PE_TREE_ROW_KIND_FOLDER;
        // the same from one reading to the next ("folder:12"): the shape of the tree and the row to select again
        std::string key;
        int64_t account = 0;
        int64_t folder = 0;
        // how far in: 0 at the top
        uint32_t depth = 0;
        std::wstring label;
        // what the folder bar and the title say while it is selected ("Inbox - Work")
        std::wstring title;
        // the count shown while open, and while collapsed
        uint64_t count = 0;
        uint64_t countCollapsed = 0;
        bool bold = false;
        bool boldCollapsed = false;
        bool dropTarget = false;
        bool reordersAccounts = false;
        PeTreeMenu menu = PE_TREE_MENU_NONE;
        // what it lists when selected (pe_list_view_set_list with `folder`)
        PeTreeList list = PE_TREE_LIST_NONE;
        // it has rows under it, which show when it starts open; the user's opening and closing of it kept by `key`
        bool parent = false;
        bool startsOpen = false;
        bool remembersOpen = false;
        // where New Folder makes a folder with this row selected: the account (0: not here) and the parent (0: the top)
        int64_t newFolderAccount = 0;
        int64_t newFolderParent = 0;
        int icon = 0;
    };
    static TreeRow RowFrom(const PeTreeRow& row);
    // the rows of a reading of the folder list, in their order
    static std::vector<TreeRow> RowsOf(const PeTree* tree);
    // the tree built again from `rows`, read from `tree`, the row selected before selected again
    void Rebuild(const PeTree* tree, std::vector<TreeRow> rows);
    // the rows inserted into the tree, each under the last row one level up
    void FillTree(std::vector<TreeRow> rows);
    // what the account's folders are for (drafts, Inbox, junk, emptiable), their names and their account
    void LoadFolderFacts(int64_t account);
    // the row of a tree item, nullptr for none
    const TreeRow* RowAt(HTREEITEM item) const;
    // the row selected in the tree, nullptr for none
    const TreeRow* SelectedTreeRow() const;
    // the row of `key` selected again after the tree was built from `tree` (or what the core says stands for it now)
    void Reselect(const PeTree* tree, const std::string& key);
    // the item of the row with `key`, nullptr when the tree has none
    HTREEITEM FindRow(const std::string& key) const;
    // the row a folder chosen from outside the tree is selected on (an account's Inbox is under All Inboxes with
    // several accounts); nullptr when the tree has none
    HTREEITEM RowOf(int64_t folder) const { return FindRow("folder:" + std::to_string(folder)); }
    // the right-click menu of an account's own row
    void AccountMenu(POINT screen);
    // Move Up and Move Down in `menu` for the selected account row or Inbox under All Inboxes, greyed at the ends
    void AppendMoveItems(HMENU menu) const;
    // the accounts' order: an account's own row, or its Inbox under All Inboxes, dragged above or below another of
    // the same level (TVN_BEGINDRAG); an insert mark shows where it goes, Esc or a right click cancels
    void DragAccount(const NMTREEVIEWW& drag);
    // the rows a drag of `item` moves it among: the accounts' own rows, or the Inboxes under All Inboxes
    std::vector<HTREEITEM> SiblingRows(HTREEITEM item) const;
    // the account a row orders: an account's own row or its Inbox under All Inboxes; 0 for another row
    int64_t AccountOfRow(HTREEITEM item) const;
    // the account ids in their order, as the tree shows them
    std::vector<int64_t> AccountOrder() const;
    // where among `rows` a drop at `client` (the tree's pixels) puts the row: before the row at that index, or after
    // the last one at rows.size()
    size_t DropGap(const std::vector<HTREEITEM>& rows, POINT client) const;
    // the insert mark at the gap `gap` among `rows`, none for kNoGap
    void ShowGap(const std::vector<HTREEITEM>& rows, size_t gap);
    // `account` put at `index` of the accounts' order, the tree built again with the row of `key` selected
    void PlaceAccount(int64_t account, size_t index, std::string key);
    // the rows opened or closed the other way than they start, kept for the next start by their keys; read in Reload,
    // written when a row is opened or closed
    void LoadFlippedRows(const std::vector<int64_t>& accounts);
    void SaveFlippedRows() const;
    void OnRowExpanded(const NMTREEVIEWW& change);
    // the counts and bold of the rows from the core's rows again; the tree built again when its rows changed
    void UpdateCounts();
    // a folder changed: the counts updated a moment later, once for many changes (TIMER_COUNTS)
    void ScheduleCounts();
    void ShowRow(HTREEITEM item);
    // a row chosen by the app (not clicked): every closed row above it opened so it is seen, which is not kept as the
    // user's opening, then selected
    void ChooseRow(HTREEITEM item);
    // what a list load selects in place of the selection, which the core finds again where it is now otherwise (the
    // message shown, several, Select All): the message `selectUid` of `selectFolder` (opening the folder's row when the
    // list does not have it, with `chooseFolder`), or the row `after` (where the rows an action took out of the list
    // were). What Undo brought back is selected in their place while undoPending_
    struct LoadPlan {
        int64_t selectFolder = 0;
        uint64_t selectUid = 0;
        bool chooseFolder = false;
        int after = -1;
        // selectionChanges_ when it started: the user chose other messages while it was read when it is not that
        uint64_t selectionAt = 0;
    };
    // the list read again off the window thread, the selection kept; with `dim` the list before dimmed meanwhile, as it
    // is going to show something else (another order, a search, the conversations grouped)
    void ReloadList(bool dim = false);
    // the list read off the window thread (pe_list_view_load) for `plan`; with `dim` the list before dimmed and not
    // taking input until it is drawn (the order, the grouping, what it shows changed)
    void LoadList(const LoadPlan& plan, bool dim);
    // the load for `plan` asked of the core with what is selected, the one before dropped
    void StartLoad(const LoadPlan& plan);
    // ListReady and ListPageReady of `request`
    void OnListLoaded(uint64_t request);
    void OnPageLoaded(uint64_t request);
    // the load `load` (NULL: an empty list) drawn with the rows it selected
    void ShowList(const PeListLoad* load, const PeListLoadInfo& info);
    // the counts and the rows of a load, `first` its first page
    void ShowRows(const PeListLoadInfo& info, Page first);
    // a load that could not be read: the list shown stays, the status bar says `why` (empty: nothing)
    void ListNotRead(const std::wstring& why);
    // the commands that waited for the list (DeferCommand) run
    void RunDeferred();
    // the load and the pages asked for not waited for any more
    void DropLoads();
    // a page read kept, the least recently used dropped when there are too many
    void KeepPage(Page page);
    // the list dimmed while it waits for a load (step 1's wait), the selection cleared too with `clearSelection`
    void BeginWait(bool clearSelection);
    // the page of rows at `offset` asked for, unless it is here or asked for already
    void RequestPage(uint64_t offset);
    // the loads and reads not waited for any more: the window closes
    void CancelLoads();
    // whether the list has what words typed found, in every folder (with a Folder column), rather than a folder
    bool Searching() const;
    void ShowFolderColumn();
    // From or To as the core says (`recipients`: Sent Items and Drafts list To)
    void ShowPersonColumn(bool recipients);
    std::wstring RowFolder(int64_t folder) const;
    // the row `index` for drawing: nullptr while its page is not here, which is then asked for (with the page after it)
    // off the window thread, its rows drawn once it is here
    const PeMessage* Row(int index);
    // the row `index` if its page is read already, nullptr otherwise; reads nothing
    const PeMessage* CachedRow(int index) const;
    // the row `index` for a command: its page read now when it is not here (nullptr while the list itself loads)
    const PeMessage* RowNow(int index);
    const PeMessage* SelectedRow();
    // the reading pane emptied; with "There is no message selected." in it unless a message is `loading`
    void ClearReader(bool loading = false);
    // the message of the reading pane marked read a moment after it is shown (TIMER_MARK_READ)
    void OnMessageShown();
    // in the middle of the list while it has no rows: why, and what to do about it
    void DrawEmptyList(HDC dc) const;
    // the selection taken from the list again (a message, or the positions of several), its summary, and with several
    // the reading pane saying how many
    void TakeSelection(bool rebuild);
    std::vector<int> SelectedRows() const;
    // the rows at `positions` selected
    void SelectPositions(const PePositions* positions);
    // `action` done to the selected messages off the window thread (pe_selection_act_start); once done (Acted) the status
    // bar told what was done, and the row after them selected when they left the list; true when it was started
    bool Act(PeAction action, int64_t to = 0);
    // an Acted of an action started here
    void OnActed(const UiEvent& event);
    // a command that needs the numbers of a whole list's selection (Select All), counted off the window thread: `then`
    // kept for when they are here (SummaryDone) and true; false when they are here, the caller going on at once
    bool AfterSummary(std::function<void()> then);
    // the count of a whole list's selection done (ReadDone `request`): what waited for it run, or dropped when it failed
    void SummaryDone(uint64_t request);
    // that count not waited for any more, and what waited for it dropped
    void DropSummary();
    // the reading pane's page saying how many messages are selected, with several
    void ShowSummaryPage();
    // the messages of a whole list's selection listed, for what goes through them one by one (a drag, a save)
    void ListSelection();
    // ActionUndone: the core's words in a bar over the list, until its close button is clicked (`text` empty hides it)
    void ShowUndone(const std::wstring& text);
    // the list changed its selection: taken once it is done changing it (TIMER_SELECTION)
    void ScheduleSelection();
    // the row the selection is replaced by once the selected rows left the list: the one after the last of them
    int RowAfterSelection() const;
    void FolderMenu();
    // the name and whether it is the Inbox or a special folder (not renamed or deleted); false when not found
    bool FolderOf(int64_t folder, std::wstring& name, bool& fixed) const;
    // the selection taken again; with `rebuild` false the messages selected stay as they were (a list load selected
    // them again where they are now) and only their numbers are taken
    void OnSelectionChanged(bool rebuild = true);
    // another folder (or All Inboxes) shown; false when it was already the one shown (and the main window was not told).
    // Its list is read after the paint (DeferList)
    bool OnFolderSelected(int64_t folder, PeTreeList list);
    // the list of the folder chosen read once the tree's highlight, the folder bar and the title are painted; the list
    // before dimmed meanwhile. A newer click replaces it
    void DeferList();
    // TIMER_LOAD_LIST: the load of the list deferred started
    void LoadPendingList();
    // the list ends waiting: its timers stopped, the UI test told whether the highlight was painted first
    void EndPending();
    // over the list while it waits: the window colour at PE_LIST_DIM, and "Loading..." once it waited PE_LIST_LOADING_MS
    void DrawPending(HDC dc) const;
    // the tree's NM_CUSTOMDRAW while a list waits: whether the row chosen was painted highlighted
    void TreeCustomDraw(NMTVCUSTOMDRAW* draw, LRESULT& result);
    // a folder changed: the list read again once for the changes of PE_LIST_GATHER_MS (TIMER_RELOAD), unless it is up
    // to date by then
    void ScheduleReload();
    // whether the list has messages of several folders: a search, or All Inboxes (with a Folder column)
    bool SeveralFolders() const;
    // the row of the message `uid` of `folder` selected in the list once it is read again (its conversation opened);
    // with `chooseFolder`, its folder chosen in the tree when the list does not have it
    void SelectInList(int64_t folder, uint64_t uid, bool chooseFolder = false);
    void CustomDraw(NMLVCUSTOMDRAW* draw, LRESULT& result);
    // a row's font: bold as the core says (unread, or a collapsed conversation with an unread message), or the list's
    HFONT RowFont(const PeMessage& row) const;
    // the selected messages in numbers (summary_), as the core knows them now: a whole list's counted off the window
    // thread
    void RefreshSummary();
    // the text of an ignored conversation's row grey, unless the row is selected
    void RowColors(NMLVCUSTOMDRAW* draw, int index, const PeMessage* row) const;
    // the Subject cell of a list grouped by conversation, drawn whole: a conversation's + or - box, the subject indented
    // under its first message, and how many messages it has
    void DrawSubject(HDC dc, int index, const PeMessage& row);
    // the Subject cell of the row `index`, and where the + or - box is in such a cell
    RECT SubjectCell(int index) const;
    static RECT ThreadBox(const RECT& cell);
    static void DrawThreadBox(HDC dc, const RECT& box, bool collapsed);
    // a click at `at` on a + or - box, and Right (`right`) or Left on the focused row; true when handled
    bool OnThreadClick(POINT at);
    bool OnThreadArrow(bool right);
    // the row `row` alone selected, focused and in view, and followed at once
    void SelectOnly(int row);
    // the conversation `thread` opened or closed, the list shown again
    void SetThreadExpanded(int64_t thread, bool open);
    void DrawRowIcons(HDC dc, int index, const PeMessage& row);
    void FillRowStart(HDC dc, int index, bool selected) const;
    void RepaintRows(int from, int to) const;
    int SelectionColor() const;
    void DisplayInfo(NMLVDISPINFOW* info);
    // the Columns layout (columnrow.cpp): a row drawn whole, its + or - box, what a screen reader says for it, its date
    void DrawColumnsRow(HDC dc, int index, const PeMessage& row);
    // the whole width of row `index`, and where its + or - box is in such a row
    RECT ColumnsRowRect(int index) const;
    static RECT ColumnsThreadBox(const RECT& row);
    std::wstring ColumnsRowText(const PeMessage& row) const;
    // a paint of the list starts: the time and the time zone its dates are written for, once a paint
    void ColumnsPaintStarts();
    // the sender's picture of a row in `box`: its logo, or its initials on a quiet square
    void DrawRowPicture(HDC dc, const RECT& box, const PeMessage& row, bool selected);
    // a picture the core drew: the rows showing it drawn again
    void PictureReady(uint64_t request);
    // who a row is for: the sender, or "To:" and the recipients in Sent Items and Drafts
    std::wstring RowPerson(const PeMessage& row) const;
    // the system colour of a row's text: selected (with the keyboard or not), grey for an ignored conversation
    int RowTextColor(int index, const PeMessage* row) const;
    // the row height of the Columns list: three lines and their padding
    int ColumnsRowHeight() const;
    // the list sorted as sort_ and ascending_ say, its heading's arrow and the "Sorted by" button following
    void ApplySort();
    // the classic header's sort arrow on the sorted column's heading (none for Size, which has no column)
    void UpdateSortArrow();
    // "Sorted by Date"
    std::wstring SortedByText() const;
    void DrawSortButton(const DRAWITEMSTRUCT& item) const;
    void ShowSortMenu();
    // the "Sorted by" button's words and width after the order changed, and that width
    void UpdateSortButton();
    int SortButtonWidth() const;
    bool OnListNotify(NMHDR* header, LRESULT& result);

    PeCore* core_ = nullptr;
    HWND parent_ = nullptr;
    HWND tree_ = nullptr;
    HWND list_ = nullptr;
    // the reading pane under the list, with the message shown and its folder (its row's: in a search of every folder
    // not the selected one)
    Reader reader_;
    HFONT bold_ = nullptr;
    // the list's font, for the rows not in bold
    HFONT normal_ = nullptr;
    // the list's font in italics: a line that says a message's state ("Encrypted message"), not its sender's words
    HFONT italic_ = nullptr;
    HFONT link_ = nullptr;
    // where the list goes, with the search bar over it while searching
    RECT listArea_ = {};
    HWND searchBar_ = nullptr;
    HWND searchClear_ = nullptr;
    // Create Rule on the search bar, left of Clear search
    HWND searchRule_ = nullptr;
    std::wstring searchSummary_;
    // the one folder the words typed name (in:sent), empty for every folder
    std::wstring findPlace_;
    void LayoutList();
    // the bar of an action the server did not do (ShowUndone): placed at the top of `list`, which is left the rest; drawn
    void LayoutUndoneBar(RECT& list);
    void DrawUndoneBar(const DRAWITEMSTRUCT& item) const;
    void FitSubjectColumn();
    // the tooltips of the icon columns' headers (what the paper clip, the flag and the lock stand for), over where
    // those headers are now
    void AddHeaderTips();
    void PlaceHeaderTips();
    HWND headerTip_ = nullptr;
    int LinkWidth(HWND link) const;
    // the icons the list draws on its rows, and their size
    HIMAGELIST listIcons_ = nullptr;
    int iconSize_ = 16;
    // the rows of the tree as the core gave them, and their items, by the same index
    std::vector<TreeRow> treeRows_;
    std::vector<HTREEITEM> treeItems_;
    // the keys of the rows the user opened or closed the other way than they start (All Inboxes, All Sent, All
    // Drafts, the accounts)
    std::unordered_set<std::string> flippedRows_;
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
    // the list shown: a folder's, or All Inboxes', All Sent's, All Drafts' or Flagged's (two or more accounts but
    // Flagged); none for a heading
    PeTreeList shownList_ = PE_TREE_LIST_NONE;
    // a folder changed and TIMER_COUNTS will update the tree's counts
    bool countsPending_ = false;
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
    // Undo brought messages back, or the store took back a refused action's: they are selected once the list has them
    // again (a load's PE_RESELECTION_RESTORED)
    bool undoPending_ = false;
    // how many times the user changed the selection: a list load started before is read again
    uint64_t selectionChanges_ = 0;
    // the commands waiting for the list (DeferCommand): their ids and codes
    std::vector<std::pair<WORD, WORD>> deferred_;
    // a drag of the selected messages out of the list (the row `index` picked up): onto a folder, or out of the app
    void BeginDrag(int index);
    // the folder under `screen` a drag of `from` can go to, 0 for none; the item under it in `over`
    int64_t DropFolder(DropFrom from, POINT screen, HTREEITEM& over) const;
    // the tree changed under the drag image (highlighted, scrolled, opened) without the image smearing over it
    void ChangeTreeUnderDrag(const std::function<void()>& change);
    // the Drafts folders, whose messages open in a compose window
    std::unordered_set<int64_t> draftFolders_;
    // the Inboxes and the Junk folders of the accounts
    std::unordered_set<int64_t> inboxFolders_;
    std::unordered_set<int64_t> junkFolders_;
    // the selected draft opens once its source is fetched
    bool openWhenReady_ = false;
    // the saved draft being read to open in a compose window (pe_draft_open_start), its message and account
    PendingRead draftRead_;
    std::pair<int64_t, uint64_t> draftMessage_{};
    int64_t draftAccount_ = 0;
    // the summary of a whole list's selection being counted (pe_selection_summary_start), and what waits for it
    uint64_t summaryRequest_ = 0;
    std::vector<std::function<void()>> whenSummed_;
    // the actions started and not done yet, by request: the row to select once done when the messages left the list
    // (-1: they stay, the list read again with the selection kept)
    std::unordered_map<uint64_t, int> actions_;
    // the bar over the list when the server did not do an action: its words and its close button
    HWND undoneBar_ = nullptr;
    HWND undoneClose_ = nullptr;
    std::wstring undoneText_;
    int64_t firstAccount_ = 0;
    // what the Find box searches for, empty when the list is the folder's
    std::wstring find_;
    // the search field: a white sunken window with the magnifier, the box and the clear button in it
    HWND findField_ = nullptr;
    HWND findIcon_ = nullptr;
    HWND findEdit_ = nullptr;
    HWND findClear_ = nullptr;
    bool folderColumn_ = false;
    // Deleted Items and Junk E-mail of every account: Empty Folder applies to them
    std::unordered_set<int64_t> emptiableFolders_;
    // Sent Items and Drafts: the person column is To, with the recipients
    bool recipientsColumn_ = false;
    int64_t folder_ = 0;
    uint64_t total_ = 0;
    uint64_t unread_ = 0;
    // the rows of the list: the messages, or with conversations grouped the conversations and the open ones' replies
    uint64_t rowCount_ = 0;
    // what the list shows, kept by the core: the folder, the words of the Find box, the order, a row a conversation or
    // a message, ignored conversations hidden, and the conversations opened
    core::ListView view_{pe_list_view_new()};
    // View > Hide Ignored Conversations, as the view has it
    bool hideIgnored_ = false;
    // View > Hide Read Messages, as the view has it
    bool unreadOnly_ = false;
    // the order of the list, as the view has it: the column sorted by, and which way
    PeSortField sort_ = PE_SORT_FIELD_DATE;
    bool ascending_ = false;
    // the Columns layout: rows of three lines, a dummy image list making them that tall, the "Sorted by" button
    bool columns_ = false;
    HIMAGELIST rowSpacer_ = nullptr;
    // the sort arrows of the header, up and down, made once
    HBITMAP sortArrows_[2] = {};
    HWND sortButton_ = nullptr;
    // the widths of the columns but Subject while Columns has them out of the way, to give back in Classic
    std::vector<int> classicWidths_;
    // the senders' pictures beside the Columns rows, and whether they are shown
    ListPictures pictures_;
    bool listPictures_ = true;
    // a memory DC the rows' pictures are drawn through, kept for the run
    HDC pictureDc_ = nullptr;
    // the time and the time zone (seconds east of UTC) of the paint under way, for the rows' dates
    int64_t paintNow_ = 0;
    int64_t paintOffset_ = 0;
    // the pages of the list, the most recently used last
    std::vector<Page> pages_;
    // true while the list is reloaded: its selection changes are the reload's, not the user's
    bool reloading_ = false;
    // a folder clicked whose list waits for the paint and its load (DeferList), or a list loaded again with its order
    // or what it shows changed; the list before is shown dimmed and takes no input, and its rows are only those already
    // read
    bool listPending_ = false;
    // the list waited for is another list (a folder chosen): nothing selected in the one before stays selected
    bool newList_ = false;
    // it waited long enough to say "Loading..."
    bool listLoadingShown_ = false;
    // the message selected in the list of the folder chosen once read (folder, uid)
    std::pair<int64_t, uint64_t> startMessage_{};
    // the loads of the list off the window thread: the load waited for (0 for none) and its plan, the pages asked for
    // by their offset
    uint64_t loadRequest_ = 0;
    LoadPlan loadPlan_;
    std::unordered_map<uint64_t, uint64_t> pageRequests_;
    // the tree painted the row chosen highlighted while its list waited
    bool highlightPainted_ = false;
    // what TestListOrder tells, less 10; the UI test holds a list waiting (TestHoldList)
    // the message shown was in sight when the list was asked for again (StartLoad): ShowList scrolls to keep it so,
    // and else leaves the list where the user scrolled it
    bool keptInSight_ = false;
    int testListOrder_ = 0;
    bool holdList_ = false;
    // TIMER_RELOAD is running
    bool reloadPending_ = false;
    // ChooseRow is opening the rows above the one chosen: not the user's opening, so it is not kept
    bool revealing_ = false;
    // how many times the tree was built: a drag of an account ends when its rows are built again under it
    uint64_t treeBuilds_ = 0;
    // SelectStart has run: later showings of the window keep what is selected
    bool started_ = false;
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
    // no longer used (a calendar event is a card in the message now), kept so the ids after them stay as they were
    IDC_INVITATION,
    IDC_OPEN_CALENDAR,
    // at the left of the message header: the brand's BIMI logo
    IDC_LOGO,
    // under the header of a message that could not be downloaded: a click tries again
    IDC_RETRY,
    // no control: the reading pane's "Show the message that bounced" clicked, sent to its window once the WebView2's
    // event is over
    IDC_BOUNCED_MESSAGE,
    // no control: a preview of an attachment after the message's text clicked, likewise
    IDC_OPEN_PREVIEW,
    // in the status bar: takes back the message that waits to be sent (Undo Send)
    IDC_UNDO_SEND = 225,
    // the toolbar of a message window, and its Previous and Next buttons
    IDC_MESSAGE_TOOLBAR = 230,
    IDC_PREVIOUS,
    IDC_NEXT,
    // the » after the main toolbar's buttons when some do not fit: a menu of those
    IDC_TOOLBAR_MORE,
    // the drop-down arrow at the right end of the blocked pictures' bar: Always from this sender or domain
    IDC_PICTURES_MENU,
    // the band under the toolbar with the folder's name: while the folder list is hidden, a click drops the list down
    IDC_FOLDER_BAR,
    // "Folders" over the folder list, and its button: the close box, or the drop-down's pushpin
    IDC_FOLDER_CAPTION,
    IDC_FOLDER_CAPTION_BUTTON,
    // over the list in the Columns layout, in place of the column headings: "Sorted by Date", a menu of the orders
    IDC_SORT_BUTTON,
    // on the search bar, left of Clear search: a new rule that matches the words searched for
    IDC_SEARCH_RULE,
    // under the header of a signed or encrypted message: its security bar, and the bar's Details button (also sent,
    // with no control, when a part's label is clicked)
    IDC_SECURITY_BAR,
    IDC_SECURITY_DETAILS,
    // under the header of a message with files: the attachment strip, a file of the message an item
    IDC_ATTACHMENT_STRIP,
    // the frame around it, the strip its child
    IDC_ATTACHMENT_FRAME,
    // over the list when the server did not do an action on messages: why, and its close button
    IDC_UNDONE_BAR,
    IDC_UNDONE_CLOSE,
};

// the items of the Flag submenu: IDM_FLAG_COLOR + 1 (red) to + 7 (gray), and Clear Flag
constexpr WORD IDM_FLAG_COLOR = 900;
constexpr WORD IDM_FLAG_CLEAR = 908;
// the account row's menu in the folder tree: Send and Receive of that account, its Mark All Read, its Properties, its
// place in the accounts' order
constexpr WORD IDM_ACCOUNT_SYNC = 910;
constexpr WORD IDM_ACCOUNT_MARK_ALL_READ = 911;
constexpr WORD IDM_ACCOUNT_PROPERTIES = 912;
// Move Up and Move Down of the account row's menu, and of the menu of its Inbox under All Inboxes
constexpr WORD IDM_ACCOUNT_MOVE_UP = 913;
constexpr WORD IDM_ACCOUNT_MOVE_DOWN = 914;

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
    // mailing lists to leave: the lists and the two answers
    IDC_AGENT_LISTS,
    IDC_AGENT_UNSUBSCRIBE,
    IDC_AGENT_DONT_UNSUBSCRIBE,
    // a message to send that answers a calendar invitation: the line over the text that says so
    IDC_AGENT_INVITATION,
    // Tools > AI Agents
    IDC_AGENTS_ENABLED = 630,
    IDC_AGENTS_HOSTS,
    IDC_AGENTS_CHANGE,
    IDC_AGENTS_REMOVE,
    IDC_AGENTS_LOG,
    IDC_AGENTS_UNDO,
    IDC_AGENTS_CLEAR,
    IDC_AGENTS_SETUP,
    // under the log: what the selected row of reads covers, and its words
    IDC_AGENTS_READS,
    IDC_AGENTS_READS_LABEL,
    // beside the programs: take back what the selected one did in a span
    IDC_AGENTS_UNDO_SINCE,
    // its window: the span, the question's heading and words, Take Back
    IDC_AGENT_UNDO_SPAN,
    IDC_AGENT_UNDO_TITLE,
    IDC_AGENT_UNDO_DETAIL,
    IDC_AGENT_TAKE_BACK,
};

// the controls of Tools > Options (options.cpp), which the UI test finds by them
enum OptionsControlId : WORD {
    IDC_OPTIONS_LANGUAGE = 660,
    IDC_OPTIONS_NOTIFY,
    IDC_OPTIONS_NOTE,
    IDC_OPTIONS_THREADS,
    // under the notifications: whether they name a message's sign-in code
    IDC_OPTIONS_CODES,
    // pictures in every message, its warning, the Trusted Senders window; Open .eml Files with Inbox Classic
    IDC_OPTIONS_PICTURES,
    IDC_OPTIONS_PICTURES_NOTE,
    IDC_OPTIONS_TRUSTED,
    IDC_OPTIONS_EML,
    // the Trusted Senders window: its list, Remove, and what it says with none
    IDC_TRUSTED_LIST,
    IDC_TRUSTED_REMOVE,
    IDC_TRUSTED_EMPTY,
    // Downloading: what is downloaded ahead, the limit of downloaded messages of each account, and what that means
    IDC_OPTIONS_DOWNLOAD_AHEAD,
    IDC_OPTIONS_DOWNLOAD_LIMIT,
    IDC_OPTIONS_DOWNLOAD_NOTE,
    // the main window's layout (View > Layout)
    IDC_OPTIONS_LAYOUT,
    // the senders' pictures in the message list, and what they are
    IDC_OPTIONS_LIST_PICTURES,
    IDC_OPTIONS_LIST_PICTURES_NOTE,
    // how long a message sent waits to be taken back (Undo Send), and what that is for
    IDC_OPTIONS_SEND_DELAY,
    IDC_OPTIONS_SEND_DELAY_NOTE,
    // the tabs of the pages, Apply, and Make Default Mail App (General > Default Apps)
    IDC_OPTIONS_TABS,
    IDC_OPTIONS_APPLY,
    IDC_OPTIONS_DEFAULT_APP,
    // Reading > Encryption: Search in encrypted messages, Look up keys on keys.openpgp.org, and their notes
    IDC_OPTIONS_SEARCH_ENCRYPTED,
    IDC_OPTIONS_SEARCH_ENCRYPTED_NOTE,
    IDC_OPTIONS_KEYSERVER,
    IDC_OPTIONS_KEYSERVER_NOTE,
    // Reading > Messages: pictures and PDF files after a message's text, its note, and PDF files under it
    IDC_OPTIONS_PREVIEWS,
    IDC_OPTIONS_PREVIEWS_NOTE,
    IDC_OPTIONS_PDF_PREVIEWS,
};

// the controls of the Address Book's windows (addressbook.cpp), which the UI test finds by them
enum BookControlId : WORD {
    // the Address Book: the groups, the people, the find box, the toolbar and its buttons
    IDC_BOOK_TREE = 700,
    IDC_BOOK_LIST,
    IDC_BOOK_FIND,
    IDC_BOOK_TOOLBAR,
    IDC_BOOK_NEW_CONTACT = 710,
    IDC_BOOK_NEW_GROUP,
    IDC_BOOK_PROPERTIES,
    IDC_BOOK_DELETE,
    IDC_BOOK_WRITE_TO,
    // Contact Properties
    IDC_CONTACT_FIRST = 720,
    IDC_CONTACT_LAST,
    IDC_CONTACT_DISPLAY,
    IDC_CONTACT_NICKNAME,
    IDC_CONTACT_COMPANY,
    IDC_CONTACT_ADDRESS,
    IDC_CONTACT_ADD,
    IDC_CONTACT_ADDRESSES,
    IDC_CONTACT_DEFAULT,
    IDC_CONTACT_REMOVE,
    IDC_CONTACT_PHONE_KIND,
    IDC_CONTACT_PHONE,
    IDC_CONTACT_PHONE_ADD,
    IDC_CONTACT_PHONES,
    IDC_CONTACT_PHONE_REMOVE,
    IDC_CONTACT_NOTES,
    // the card's picture at the top left, and Choose... and Remove under it
    IDC_CONTACT_PICTURE,
    IDC_CONTACT_PICTURE_CHOOSE,
    IDC_CONTACT_PICTURE_REMOVE,
    // Group Properties
    IDC_GROUP_NAME = 750,
    IDC_GROUP_MEMBERS,
    IDC_GROUP_SELECT,
    IDC_GROUP_REMOVE,
    IDC_GROUP_ADDRESS,
    IDC_GROUP_ADD,
    IDC_GROUP_COUNT,
    // Select Recipients and Select Group Members: the find box, the book, To ->, Cc -> and Bcc -> (or Add ->) and the
    // lists they fill
    IDC_PICK_FIND = 770,
    IDC_PICK_LIST,
    IDC_PICK_TO,
    IDC_PICK_CC,
    IDC_PICK_BCC,
    IDC_PICK_TO_LIST = 780,
    IDC_PICK_CC_LIST,
    IDC_PICK_BCC_LIST,
    // Contact Properties: the key of each of the card's addresses that has one (three at most), each row at
    // IDC_CONTACT_KEY + 5 * row: its words and Verify, and a newer key waiting for the user's decision, its words and
    // the two answers; with no key, the words that say so at IDC_CONTACT_KEY
    IDC_CONTACT_KEY = 785,
    IDC_CONTACT_KEY_VERIFY,
    IDC_CONTACT_KEY_PENDING,
    IDC_CONTACT_KEY_USE_NEW,
    IDC_CONTACT_KEY_KEEP,
};

// the controls of the help window (help.cpp), which the UI test finds by them
enum HelpControlId : WORD {
    // the toolbar and its buttons: Hide or Show (the left pane), Back, Forward, Home and Print
    IDC_HELP_TOOLBAR = 800,
    IDC_HELP_PANE = 810,
    IDC_HELP_BACK,
    IDC_HELP_FORWARD,
    IDC_HELP_HOME,
    IDC_HELP_PRINT,
    // the Contents and Search tabs, the contents' tree, and the search's box, button, topics found and "none found"
    IDC_HELP_TABS = 820,
    IDC_HELP_TREE,
    IDC_HELP_QUERY,
    IDC_HELP_SEARCH,
    IDC_HELP_RESULTS,
    IDC_HELP_NONE,
};

// the controls of the Message Rules window and of the rule editor (rules.cpp), which the UI test finds by them
enum RulesControlId : WORD {
    IDC_RULES_LIST = 840,
    IDC_RULES_NEW,
    IDC_RULES_EDIT,
    IDC_RULES_DELETE,
    IDC_RULES_UP,
    IDC_RULES_DOWN,
    IDC_RULES_CLOSE,
    IDC_RULE_NAME = 850,
    IDC_RULE_ACCOUNT,
    IDC_RULE_QUERY,
    IDC_RULE_HINT,
    IDC_RULE_COUNT,
    IDC_RULE_SHOW,
    IDC_RULE_MOVE,
    IDC_RULE_MOVE_TO,
    IDC_RULE_MARK_READ,
    IDC_RULE_FLAG,
    IDC_RULE_ARCHIVE,
    IDC_RULE_JUNK,
    IDC_RULE_DELETE,
    IDC_RULE_QUIET,
    IDC_RULE_APPLY_NOW,
};

// the controls of signing and encrypting in the compose window (compose.cpp) and of Recipients' Keys
// (recipientkeys.cpp), which the UI test finds by them
enum ComposeKeysControlId : WORD {
    // the line under the fields, its Details button (its child), the Keys row's label (a button) and its recipients
    IDC_COMPOSE_SECURITY = 350,
    IDC_COMPOSE_SECURITY_DETAILS,
    IDC_COMPOSE_KEYS_LABEL,
    IDC_COMPOSE_KEYS,
    // the line over them that says an AI agent wrote the draft
    IDC_COMPOSE_AGENT_NOTE,
    // Recipients' Keys: what it says at its top, the list, the selected recipient's buttons, the key that waits for a
    // decision and its two answers, why Send Without Encryption is off, and the buttons at the bottom (Send is IDOK)
    IDC_RKEYS_INTRO = 360,
    IDC_RKEYS_LIST,
    IDC_RKEYS_FIND,
    IDC_RKEYS_REMOVE,
    IDC_RKEYS_PENDING,
    IDC_RKEYS_USE_NEW,
    IDC_RKEYS_KEEP,
    IDC_RKEYS_UNENCRYPTED_NOTE,
    IDC_RKEYS_SEND_UNENCRYPTED,
};

// the controls of the key windows (keys.cpp), which the UI test finds by them
enum KeysControlId : WORD {
    // Encryption Keys: the list and its buttons
    IDC_KEYS_LIST = 870,
    IDC_KEYS_NEW,
    IDC_KEYS_IMPORT,
    IDC_KEYS_EXPORT,
    IDC_KEYS_BACKUP,
    IDC_KEYS_VERIFY,
    IDC_KEYS_PROPERTIES,
    IDC_KEYS_REMOVE,
    IDC_KEYS_CLOSE,
    // New Key: the account, and the note under it (no account, or passwords in memory only)
    IDC_KEY_ACCOUNT = 880,
    IDC_KEY_NOTE,
    // Back Up Key and Import Key: the passphrase, typed again, and why the one typed was not taken
    IDC_KEY_PASSPHRASE,
    IDC_KEY_PASSPHRASE_AGAIN,
    IDC_KEY_PROBLEM,
    // Key Properties: the values, and Verify
    IDC_KEY_NAMES,
    IDC_KEY_FINGERPRINT,
    IDC_KEY_STATUS,
    IDC_KEY_CREATED,
    IDC_KEY_EXPIRES,
    IDC_KEY_ALGORITHM,
    IDC_KEY_SOURCE,
    IDC_KEY_ADDRESSES,
    IDC_KEY_VERIFY,
    // Verify Key: the answers (or Mark as Not Verified)
    IDC_VERIFY_MATCH,
    IDC_VERIFY_DIFFER,
    IDC_VERIFY_UNMARK,
    // Account Properties > Security: the key, New Key, and Autocrypt
    IDC_ACCOUNT_KEY,
    IDC_ACCOUNT_KEY_NEW,
    IDC_ACCOUNT_AUTOCRYPT,
};

// the controls of Export and Import Settings and Accounts (setup.cpp), which the UI test finds by them
enum SetupControlId : WORD {
    // a part's check box: IDC_SETUP_PART + its place in the core's order (accounts, sign-in apps, settings, window
    // preferences, contacts, keys, rules, trusted senders)
    IDC_SETUP_PART = 940,
    // Export: the passphrase check box, its note, the fields and why what is typed is not taken
    IDC_SETUP_USE_PASSPHRASE = 950,
    IDC_SETUP_PASSPHRASE_NOTE,
    IDC_SETUP_PASSPHRASE,
    IDC_SETUP_PASSPHRASE_AGAIN,
    IDC_SETUP_PROBLEM,
    // Import: when and by which version the file was saved
    IDC_SETUP_FROM,
    // Add Mail Account: the link to the import
    IDC_SETUP_FIRST_RUN,
    // Import: an account's check box, IDC_SETUP_ACCOUNT + its place in the file's list
    IDC_SETUP_ACCOUNT = 1000,
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
// a moment after a find in a message started, how many places it found is told as it is then
constexpr UINT_PTR TIMER_FIND_SETTLED = 8;
// while a signed or encrypted message is shown: its parts' frames measured again (pictures loaded, "..." unfolded, the
// width or the text size changed)
constexpr UINT_PTR TIMER_MEASURE = 9;
// a moment after a folder changed, the tree's counts follow (once for the changes of a whole sync)
constexpr UINT_PTR TIMER_COUNTS = 10;
// a folder clicked in the tree: its list read once the highlight is painted (WM_TIMER comes after WM_PAINT)
constexpr UINT_PTR TIMER_LOAD_LIST = 11;
// a folder clicked whose list is still not read after a while: "Loading..." over the dimmed list
constexpr UINT_PTR TIMER_LIST_LOADING = 12;
// the main window's: counts down the message that waits to be sent, in the status bar (Undo Send); apart from the
// list's timers above, which the main window hands to the list
constexpr UINT_PTR TIMER_SEND_WAITING = 20;
