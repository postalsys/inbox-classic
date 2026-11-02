// The new account form and the password prompt. The values go to the core as typed; the core checks them when it
// connects.
#include "app.h"

#include <shellapi.h>

namespace {

const wchar_t* kSecurity[] = {L"SSL/TLS", L"STARTTLS", L"None (unencrypted)"};

enum Field { NAME, EMAIL, USERNAME, PASSWORD, IMAP_HOST, IMAP_PORT, IMAP_SECURITY, SMTP_HOST, SMTP_PORT, SMTP_SECURITY };

PeSecurity SecurityOf(const std::wstring& choice) {
    if (choice == kSecurity[1]) {
        return PE_SECURITY_START_TLS;
    }
    return choice == kSecurity[2] ? PE_SECURITY_PLAIN : PE_SECURITY_TLS;
}

bool ValidPort(const std::wstring& text) {
    if (text.empty() || text.size() > 5) {
        return false;
    }
    unsigned long port = wcstoul(text.c_str(), nullptr, 10);
    return port >= 1 && port <= 65535;
}

bool Validate(const std::vector<FormField>& fields, std::wstring& error) {
    for (Field required : {EMAIL, IMAP_HOST, SMTP_HOST}) {
        if (fields[required].value.empty()) {
            error = fields[required].label + L" is required.";
            return false;
        }
    }
    if (fields[EMAIL].value.find(L'@') == std::wstring::npos) {
        error = L"The e-mail address is not valid.";
        return false;
    }
    if (!ValidPort(fields[IMAP_PORT].value) || !ValidPort(fields[SMTP_PORT].value)) {
        error = L"Ports are numbers from 1 to 65535.";
        return false;
    }
    return true;
}

bool ValidFirst(const std::vector<FormField>& fields, std::wstring& error) {
    if (fields[1].value.find(L'@') == std::wstring::npos) {
        error = L"Type your e-mail address, name@example.com.";
        return false;
    }
    return true;
}

// the request the account form waits for: its cancel, and whether its event came
struct {
    PeCore* core = nullptr;
    uint64_t request = 0;
    void (*cancel)(const PeCore*, uint64_t) = nullptr;
    bool done = false;
} g_wait;

const wchar_t* kWaitClass = L"InboxClassicWait";

LRESULT CALLBACK WaitProc(HWND hwnd, UINT message, WPARAM wParam, LPARAM lParam) {
    if ((message == WM_COMMAND && LOWORD(wParam) == IDCANCEL) || message == WM_CLOSE) {
        g_wait.cancel(g_wait.core, g_wait.request);
        g_wait.done = true;
        g_wait.request = 0;
        return 0;
    }
    if (message == WM_CTLCOLORSTATIC) {
        return ButtonFaceColor(reinterpret_cast<HDC>(wParam));
    }
    return DefWindowProcW(hwnd, message, wParam, lParam);
}

// waits with a small window that can cancel it for the event of `request`; false when it was cancelled
bool WaitFor(HWND owner, PeCore* core, uint64_t request, void (*cancel)(const PeCore*, uint64_t), const std::wstring& text) {
    g_wait = {core, request, cancel, false};
    if (!request) {
        return false;
    }
    static bool registered = false;
    if (!registered) {
        WNDCLASSEXW windowClass = {sizeof(windowClass)};
        windowClass.lpfnWndProc = WaitProc;
        windowClass.hInstance = GetModuleHandleW(nullptr);
        windowClass.hCursor = LoadCursorW(nullptr, IDC_APPSTARTING);
        windowClass.hbrBackground = reinterpret_cast<HBRUSH>(COLOR_BTNFACE + 1);
        windowClass.lpszClassName = kWaitClass;
        RegisterClassExW(&windowClass);
        registered = true;
    }
    HWND root = GetAncestor(owner, GA_ROOT);
    RECT ownerRect;
    GetWindowRect(root, &ownerRect);
    int width = Scale(360);
    int height = Scale(130);
    HWND wait = CreateWindowExW(WS_EX_DLGMODALFRAME, kWaitClass, L"Add Mail Account", WS_POPUP | WS_CAPTION | WS_SYSMENU,
                                (ownerRect.left + ownerRect.right - width) / 2, (ownerRect.top + ownerRect.bottom - height) / 2,
                                width, height, root, nullptr, GetModuleHandleW(nullptr), nullptr);
    CreateChild(wait, L"STATIC", text.c_str(), SS_LEFT | SS_NOPREFIX, 0, {Scale(12), Scale(12), width - Scale(24), Scale(52)});
    CreateChild(wait, L"BUTTON", L"Cancel", WS_TABSTOP, IDCANCEL,
                {width - Scale(100), Scale(58), width - Scale(16), Scale(83)});
    bool wasEnabled = IsWindowEnabled(root);
    EnableWindow(root, FALSE);
    ShowWindow(wait, SW_SHOW);
    MSG msg = {};
    // the main window passes the event of this request on to RequestDone
    while (!g_wait.done && GetMessageW(&msg, nullptr, 0, 0) > 0) {
        if (!IsDialogMessageW(wait, &msg)) {
            TranslateMessage(&msg);
            DispatchMessageW(&msg);
        }
    }
    if (msg.message == WM_QUIT) {
        PostQuitMessage(static_cast<int>(msg.wParam));
    }
    EnableWindow(root, wasEnabled);
    DestroyWindow(wait);
    bool finished = g_wait.request != 0;
    g_wait.request = 0;
    return finished;
}

// looks the servers of `email` up; the result, or NULL
core::Autoconfig WaitForLookup(HWND owner, PeCore* core, const std::wstring& email, const std::wstring& password) {
    // the password only answers a Microsoft Autodiscover server that asks for it (hosted Exchange), over https
    std::string secret = core::Narrow(password);
    uint64_t request = pe_autoconfig_start(core, core::Narrow(email).c_str(), secret.c_str());
    SecureZeroMemory(secret.data(), secret.size());
    size_t at = email.find_last_of(L'@');
    std::wstring text = L"Looking up the settings of " + email.substr(at == std::wstring::npos ? 0 : at + 1) + L"...";
    if (!WaitFor(owner, core, request, pe_autoconfig_cancel, text)) {
        return core::Autoconfig();
    }
    return core::Autoconfig(pe_autoconfig_result(core, request));
}

// the first line of the server settings form: where the settings came from
std::wstring FoundIntro(const PeAutoconfigInfo* info) {
    if (!info) {
        return L"Enter the account details your e-mail provider gave you.";
    }
    const wchar_t* change = L" Change them if your provider gave you others.";
    switch (info->source) {
    case PE_AUTOCONFIG_SOURCE_GUESS:
        return L"No settings were found for this address: these are the usual names, check them with your provider.";
    case PE_AUTOCONFIG_SOURCE_MX:
        return std::wstring(L"Your mail is handled by a provider Inbox Classic knows; these are its servers.") + change;
    case PE_AUTOCONFIG_SOURCE_SRV:
        return std::wstring(L"These settings were found in the DNS records of your domain.") + change;
    case PE_AUTOCONFIG_SOURCE_AUTODISCOVER:
        return std::wstring(L"These settings were found by Microsoft Autodiscover (Exchange).") + change;
    default:
        return std::wstring(L"These settings were found for this address.") + change;
    }
}

// a provider that does not take the account's password from mail programs: says so, and opens the page that tells
// how to make an app password when the user wants it
void ExplainAppPassword(HWND owner, const PeAutoconfigInfo* info) {
    if (!info || !info->app_password_provider) {
        return;
    }
    std::wstring provider = Text(info->app_password_provider);
    std::wstring text = info->app_password_warning
                            ? Text(info->app_password_warning)
                            : provider + L" does not take your normal password in mail programs. Create an app password in your " +
                                  provider + L" account and type it in the Password field of the next form.";
    std::wstring page = info->app_password_instructions ? Text(info->app_password_instructions) : L"";
    bool linkable = page.rfind(L"https://", 0) == 0;
    if (linkable) {
        text += L"\n\nOpen " + provider + L"'s instructions in your browser?";
    }
    int answer = MessageBoxW(owner, text.c_str(), L"Add Mail Account", (linkable ? MB_YESNO : MB_OK) | MB_ICONINFORMATION);
    if (linkable && answer == IDYES) {
        ShellExecuteW(owner, L"open", page.c_str(), nullptr, nullptr, SW_SHOWNORMAL);
    }
}

// the warning before a connection without encryption: true to go on
bool AcceptPlain(HWND owner, const std::vector<FormField>& fields, const wchar_t* title) {
    bool plain = SecurityOf(fields[IMAP_SECURITY].value) == PE_SECURITY_PLAIN || SecurityOf(fields[SMTP_SECURITY].value) == PE_SECURITY_PLAIN;
    return !plain || MessageBoxW(owner,
                                 L"Without encryption your password and mail travel the network readable by anyone on "
                                 L"the way. Use this only for a server on your own computer or network.\n\nContinue?",
                                 title, MB_YESNO | MB_ICONWARNING | MB_DEFBUTTON2) == IDYES;
}

// the settings of the server form; `utf8` keeps the strings they point to
PeAccountSettings SettingsOf(const std::vector<FormField>& fields, std::string (&utf8)[5]) {
    // the user name is usually the address
    std::wstring username = fields[USERNAME].value.empty() ? fields[EMAIL].value : fields[USERNAME].value;
    std::wstring name = fields[NAME].value.empty() ? fields[EMAIL].value : fields[NAME].value;
    utf8[0] = core::Narrow(name);
    utf8[1] = core::Narrow(fields[EMAIL].value);
    utf8[2] = core::Narrow(username);
    utf8[3] = core::Narrow(fields[IMAP_HOST].value);
    utf8[4] = core::Narrow(fields[SMTP_HOST].value);
    PeAccountSettings settings = {};
    settings.name = utf8[0].c_str();
    settings.email = utf8[1].c_str();
    settings.username = utf8[2].c_str();
    settings.imap_host = utf8[3].c_str();
    settings.imap_port = static_cast<uint16_t>(wcstoul(fields[IMAP_PORT].value.c_str(), nullptr, 10));
    settings.imap_security = SecurityOf(fields[IMAP_SECURITY].value);
    settings.smtp_host = utf8[4].c_str();
    settings.smtp_port = static_cast<uint16_t>(wcstoul(fields[SMTP_PORT].value.c_str(), nullptr, 10));
    settings.smtp_security = SecurityOf(fields[SMTP_SECURITY].value);
    return settings;
}

std::wstring SecurityName(PeSecurity security) {
    return kSecurity[security == PE_SECURITY_START_TLS ? 1 : security == PE_SECURITY_PLAIN ? 2 : 0];
}

}  // namespace

void RequestDone(uint64_t request) {
    if (request && request == g_wait.request) {
        g_wait.done = true;
    }
}

uint64_t SignInWithBrowser(HWND owner, PeCore* core, PeOAuthProvider provider, const std::wstring& email) {
    char* page = nullptr;
    uint64_t request = pe_sign_in_begin(core, provider, core::Narrow(email).c_str(), &page);
    core::String url(page);
    // the core makes the page; only an https page is opened
    std::wstring address = url ? Text(url.get()) : L"";
    if (!request || address.rfind(L"https://", 0) != 0) {
        MessageBoxW(owner, L"Signing in through the browser could not start.", L"Inbox Classic", MB_OK | MB_ICONERROR);
        return 0;
    }
    ShellExecuteW(owner, L"open", address.c_str(), nullptr, nullptr, SW_SHOWNORMAL);
    if (!WaitFor(owner, core, request, pe_sign_in_cancel,
                 L"Sign in to " + email + L" in the browser window that opened, then come back here.")) {
        return 0;
    }
    char* why = nullptr;
    if (!pe_sign_in_result(core, request, &why)) {
        core::String reason(why);
        std::wstring text = L"Signing in did not work: " + (reason ? Text(reason.get()) : L"unknown reason");
        MessageBoxW(owner, text.c_str(), L"Inbox Classic", MB_OK | MB_ICONWARNING);
        return 0;
    }
    return request;
}

int64_t NewAccountDialog(HWND owner, PeCore* core) {
    using Kind = FormField::Kind;
    std::vector<FormField> first = {
        {L"Display name:", L""},
        {L"E-mail address:", L""},
        {L"Password:", L"", Kind::Password},
    };
    if (!FormDialog(owner, L"Add Mail Account",
                    L"Your name as others see it, your e-mail address and its password. The servers are looked up next.",
                    first, ValidFirst, L"Next >")) {
        return 0;
    }
    std::wstring email = first[1].value;
    core::Autoconfig found = WaitForLookup(owner, core, email, first[2].value);
    const PeAutoconfigInfo* info = pe_autoconfig_info(found.get());
    std::wstring intro = FoundIntro(info);

    PeOAuthProvider provider = info ? pe_oauth_provider_for(core, info->imap_host) : PE_O_AUTH_PROVIDER_NONE;
    if (provider != PE_O_AUTH_PROVIDER_NONE &&
        MessageBoxW(owner,
                    L"This provider lets you sign in through your web browser, without giving Inbox Classic your "
                    L"password.\n\nSign in with the browser?",
                    L"Add Mail Account", MB_YESNO | MB_ICONQUESTION) == IDYES) {
        uint64_t request = SignInWithBrowser(owner, core, provider, email);
        if (!request) {
            return 0;
        }
        std::string utf8[] = {core::Narrow(first[0].value.empty() ? email : first[0].value), core::Narrow(email)};
        PeAccountSettings settings = {};
        settings.name = utf8[0].c_str();
        settings.email = utf8[1].c_str();
        settings.username = info->username;
        settings.imap_host = info->imap_host;
        settings.imap_port = info->imap_port;
        settings.imap_security = info->imap_security;
        settings.smtp_host = info->smtp_host;
        settings.smtp_port = info->smtp_port;
        settings.smtp_security = info->smtp_security;
        SecureZeroMemory(first[2].value.data(), first[2].value.size() * sizeof(wchar_t));
        return pe_account_add_oauth(core, &settings, request);
    }

    ExplainAppPassword(owner, info);
    std::vector<std::wstring> security(std::begin(kSecurity), std::end(kSecurity));
    std::vector<FormField> fields = {
        {L"Display name:", first[0].value},
        {L"E-mail address:", email},
        {L"User name:", info ? Text(info->username) : L""},
        {L"Password:", first[2].value, Kind::Password},
        {L"Incoming (IMAP) server:", info ? Text(info->imap_host) : L""},
        {L"IMAP port:", info ? std::to_wstring(info->imap_port) : L"993", Kind::Number},
        {L"IMAP security:", info ? SecurityName(info->imap_security) : kSecurity[0], Kind::Choice, security},
        {L"Outgoing (SMTP) server:", info ? Text(info->smtp_host) : L""},
        {L"SMTP port:", info ? std::to_wstring(info->smtp_port) : L"465", Kind::Number},
        {L"SMTP security:", info ? SecurityName(info->smtp_security) : kSecurity[0], Kind::Choice, security},
    };
    SecureZeroMemory(first[2].value.data(), first[2].value.size() * sizeof(wchar_t));
    while (FormDialog(owner, L"Add Mail Account", intro, fields, Validate, L"Finish")) {
        if (!AcceptPlain(owner, fields, L"Add Mail Account")) {
            continue;
        }
        std::string utf8[5];
        PeAccountSettings settings = SettingsOf(fields, utf8);
        std::string password = core::Narrow(fields[PASSWORD].value);
        int64_t account = pe_account_add(core, &settings, password.c_str());
        SecureZeroMemory(password.data(), password.size());
        if (account > 0) {
            SecureZeroMemory(fields[PASSWORD].value.data(), fields[PASSWORD].value.size() * sizeof(wchar_t));
            return account;
        }
        MessageBoxW(owner, L"The account could not be saved.", L"Add Mail Account", MB_OK | MB_ICONERROR);
    }
    SecureZeroMemory(fields[PASSWORD].value.data(), fields[PASSWORD].value.size() * sizeof(wchar_t));
    return 0;
}

bool PasswordDialog(HWND owner, const std::wstring& account, std::wstring& password) {
    std::vector<FormField> fields = {{L"Password:", L"", FormField::Kind::Password}};
    std::wstring intro = L"Enter the password of " + account + L".";
    if (!FormDialog(owner, L"Logon", intro, fields)) {
        return false;
    }
    password = fields[0].value;
    SecureZeroMemory(fields[0].value.data(), fields[0].value.size() * sizeof(wchar_t));
    return true;
}

// ---- the accounts window ----

namespace {

const wchar_t* kAccountsClass = L"InboxClassicAccounts";

enum AccountsId : WORD { IDC_ACCOUNT_LIST = 400, IDC_ACCOUNT_ADD, IDC_ACCOUNT_PROPERTIES, IDC_ACCOUNT_REMOVE, IDC_ACCOUNT_CLOSE };

struct AccountsState {
    PeCore* core;
    HWND list = nullptr;
    std::vector<int64_t> ids;
    // signs in through the browser, by position
    std::vector<bool> oauth;
    bool done = false;
    bool changed = false;
};

enum AccountColumn { COL_NAME, COL_EMAIL, COL_SERVER };

// a row per account: its name, address and incoming server (or the provider's sign-in); `select` stays selected
void FillAccounts(AccountsState* state, int select = 0) {
    ListView_DeleteAllItems(state->list);
    state->ids.clear();
    state->oauth.clear();
    core::AccountList accounts(pe_accounts(state->core));
    for (size_t i = 0; i < pe_account_list_count(accounts.get()); i++) {
        const PeAccount* account = pe_account_list_get(accounts.get(), i);
        int row = AddRow(state->list, static_cast<int>(i), Text(account->name));
        bool oauth = account->oauth != PE_O_AUTH_PROVIDER_NONE;
        SetCell(state->list, row, COL_EMAIL, Text(account->email));
        SetCell(state->list, row, COL_SERVER, Text(account->imap_host) + (oauth ? L" (browser sign-in)" : L""));
        state->ids.push_back(account->id);
        state->oauth.push_back(oauth);
    }
    SelectRow(state->list, select);
}


// the settings of an account, changed: the server form for a password account, the name for one that signs in
// through the browser (its servers are the provider's); a password typed in replaces the kept one
bool AccountProperties(HWND owner, PeCore* core, int64_t account, bool oauth) {
    core::AccountSettings view(pe_account_settings(core, account));
    const PeAccountSettings* stored = pe_account_settings_info(view.get());
    if (!stored) {
        return false;
    }
    std::vector<std::wstring> security(std::begin(kSecurity), std::end(kSecurity));
    using Kind = FormField::Kind;
    std::vector<FormField> fields = {
        {L"Display name:", Text(stored->name)},
        {L"E-mail address:", Text(stored->email)},
        {L"User name:", Text(stored->username)},
        {L"Password:", L"", Kind::Password},
        {L"Incoming (IMAP) server:", Text(stored->imap_host)},
        {L"IMAP port:", std::to_wstring(stored->imap_port), Kind::Number},
        {L"IMAP security:", SecurityName(stored->imap_security), Kind::Choice, security},
        {L"Outgoing (SMTP) server:", Text(stored->smtp_host)},
        {L"SMTP port:", std::to_wstring(stored->smtp_port), Kind::Number},
        {L"SMTP security:", SecurityName(stored->smtp_security), Kind::Choice, security},
    };
    if (oauth) {
        // a browser sign-in account: the name only, the rest is the provider's
        std::vector<FormField> name = {fields[NAME]};
        if (!FormDialog(owner, L"Properties", L"This account signs in through the browser; its servers are the provider's.", name)) {
            return false;
        }
        fields[NAME] = name[0];
        std::string utf8[5];
        PeAccountSettings settings = SettingsOf(fields, utf8);
        return pe_account_update(core, account, &settings);
    }
    std::wstring intro = L"Leave the password empty to keep the one you have.";
    std::wstring imapHost = Text(stored->imap_host);
    std::wstring smtpHost = Text(stored->smtp_host);
    PeSecurity imapSecurity = stored->imap_security;
    PeSecurity smtpSecurity = stored->smtp_security;
    bool saved = false;
    while (FormDialog(owner, L"Properties", intro, fields, Validate)) {
        // warned for a side without encryption, unless it was so already to the same server: not each time such an
        // account is saved, but when the password would go readable somewhere new
        auto newlyPlain = [&](Field security, Field host, PeSecurity was, const std::wstring& wasHost) {
            return SecurityOf(fields[security].value) == PE_SECURITY_PLAIN && (was != PE_SECURITY_PLAIN || fields[host].value != wasHost);
        };
        bool warn = newlyPlain(IMAP_SECURITY, IMAP_HOST, imapSecurity, imapHost) || newlyPlain(SMTP_SECURITY, SMTP_HOST, smtpSecurity, smtpHost);
        if (warn && !AcceptPlain(owner, fields, L"Properties")) {
            continue;
        }
        std::string utf8[5];
        PeAccountSettings settings = SettingsOf(fields, utf8);
        if (!pe_account_update(core, account, &settings)) {
            MessageBoxW(owner, L"The account could not be saved.", L"Properties", MB_OK | MB_ICONERROR);
            continue;
        }
        if (!fields[PASSWORD].value.empty()) {
            std::string password = core::Narrow(fields[PASSWORD].value);
            pe_account_set_password(core, account, password.c_str());
            SecureZeroMemory(password.data(), password.size());
        }
        saved = true;
        break;
    }
    SecureZeroMemory(fields[PASSWORD].value.data(), fields[PASSWORD].value.size() * sizeof(wchar_t));
    return saved;
}

void OnAccountsCommand(HWND hwnd, AccountsState* state, WORD id) {
    int index = ListView_GetNextItem(state->list, -1, LVNI_SELECTED);
    bool chosen = index >= 0 && static_cast<size_t>(index) < state->ids.size();
    int64_t account = chosen ? state->ids[index] : 0;
    if (id == IDC_ACCOUNT_PROPERTIES) {
        if (chosen && AccountProperties(hwnd, state->core, account, state->oauth[index])) {
            state->changed = true;
            FillAccounts(state, index);
        }
        return;
    }
    switch (id) {
    case IDC_ACCOUNT_ADD:
        if (NewAccountDialog(hwnd, state->core) > 0) {
            state->changed = true;
            FillAccounts(state);
        }
        return;
    case IDC_ACCOUNT_REMOVE:
        if (account && MessageBoxW(hwnd,
                                   L"Remove this account from Inbox Classic? Its mail stays on the server; the copy on this "
                                   L"computer and the saved password are removed.",
                                   L"Remove Account", MB_YESNO | MB_ICONWARNING | MB_DEFBUTTON2) == IDYES) {
            pe_account_remove(state->core, account);
            state->changed = true;
            FillAccounts(state, index);
        }
        return;
    case IDC_ACCOUNT_CLOSE:
    case IDCANCEL:
        state->done = true;
        return;
    }
}

LRESULT CALLBACK AccountsProc(HWND hwnd, UINT message, WPARAM wParam, LPARAM lParam) {
    auto* state = reinterpret_cast<AccountsState*>(GetWindowLongPtrW(hwnd, GWLP_USERDATA));
    switch (message) {
    case WM_COMMAND:
        if (state) {
            // Enter in the list is IDOK of the window: Properties of the selected account
            WORD id = LOWORD(wParam) == IDOK && GetFocus() == state->list ? IDC_ACCOUNT_PROPERTIES : LOWORD(wParam);
            OnAccountsCommand(hwnd, state, id);
        }
        return 0;
    case WM_NOTIFY: {
        auto* header = reinterpret_cast<NMHDR*>(lParam);
        if (state && header->hwndFrom == state->list) {
            // a double-click opens Properties, Delete removes
            if (header->code == LVN_ITEMACTIVATE) {
                OnAccountsCommand(hwnd, state, IDC_ACCOUNT_PROPERTIES);
            } else if (header->code == LVN_KEYDOWN && reinterpret_cast<NMLVKEYDOWN*>(lParam)->wVKey == VK_DELETE) {
                OnAccountsCommand(hwnd, state, IDC_ACCOUNT_REMOVE);
            }
        }
        return 0;
    }
    case WM_CLOSE:
        if (state) {
            state->done = true;
        }
        return 0;
    case WM_CTLCOLORSTATIC:
        return ButtonFaceColor(reinterpret_cast<HDC>(wParam));
    }
    return DefWindowProcW(hwnd, message, wParam, lParam);
}

}  // namespace

bool AccountsDialog(HWND owner, PeCore* core) {
    static bool registered = false;
    if (!registered) {
        WNDCLASSEXW windowClass = {sizeof(windowClass)};
        windowClass.lpfnWndProc = AccountsProc;
        windowClass.hInstance = GetModuleHandleW(nullptr);
        windowClass.hCursor = LoadCursorW(nullptr, IDC_ARROW);
        windowClass.hbrBackground = reinterpret_cast<HBRUSH>(COLOR_BTNFACE + 1);
        windowClass.lpszClassName = kAccountsClass;
        RegisterClassExW(&windowClass);
        registered = true;
    }
    int pad = Scale(10);
    int width = Scale(600);
    int height = Scale(240);
    HWND dialog = CreateModalWindow(owner, kAccountsClass, L"Accounts", width, height);
    AccountsState state{core};
    SetWindowLongPtrW(dialog, GWLP_USERDATA, reinterpret_cast<LONG_PTR>(&state));
    int buttonWidth = Scale(100);
    int listRight = width - pad - buttonWidth - pad;
    state.list = CreateReportList(dialog, IDC_ACCOUNT_LIST, {pad, pad, listRight, height - pad});
    AddColumn(state.list, COL_NAME, L"Account", 120);
    AddColumn(state.list, COL_EMAIL, L"E-mail address", 170);
    AddColumn(state.list, COL_SERVER, L"Incoming server", 100);
    ListView_SetColumnWidth(state.list, COL_SERVER, LVSCW_AUTOSIZE_USEHEADER);
    struct Button {
        WORD id;
        const wchar_t* text;
    };
    Button buttons[] = {{IDC_ACCOUNT_ADD, L"&Add..."}, {IDC_ACCOUNT_PROPERTIES, L"&Properties..."}, {IDC_ACCOUNT_REMOVE, L"&Remove"}};
    int top = pad;
    for (const Button& button : buttons) {
        CreateChild(dialog, L"BUTTON", button.text, WS_TABSTOP, button.id, {width - pad - buttonWidth, top, width - pad, top + Scale(25)});
        top += Scale(31);
    }
    CreateChild(dialog, L"BUTTON", L"Close", WS_TABSTOP | BS_DEFPUSHBUTTON, IDC_ACCOUNT_CLOSE,
                {width - pad - buttonWidth, height - pad - Scale(25), width - pad, height - pad});
    FillAccounts(&state);

    RunModal(dialog, state.list, state.done);
    return state.changed;
}
