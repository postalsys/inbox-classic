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

const wchar_t* kWaitClass = L"PostalExpressWait";

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
core::Autoconfig WaitForLookup(HWND owner, PeCore* core, const std::wstring& email) {
    uint64_t request = pe_autoconfig_start(core, core::Narrow(email).c_str());
    size_t at = email.find_last_of(L'@');
    std::wstring text = L"Looking up the settings of " + email.substr(at == std::wstring::npos ? 0 : at + 1) + L"...";
    if (!WaitFor(owner, core, request, pe_autoconfig_cancel, text)) {
        return core::Autoconfig();
    }
    return core::Autoconfig(pe_autoconfig_result(core, request));
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
        MessageBoxW(owner, L"Signing in through the browser could not start.", L"PostalExpress", MB_OK | MB_ICONERROR);
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
        MessageBoxW(owner, text.c_str(), L"PostalExpress", MB_OK | MB_ICONWARNING);
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
                    first, ValidFirst)) {
        return 0;
    }
    std::wstring email = first[1].value;
    core::Autoconfig found = WaitForLookup(owner, core, email);
    const PeAutoconfigInfo* info = pe_autoconfig_info(found.get());
    std::wstring intro = L"Enter the account details your e-mail provider gave you.";
    if (info) {
        intro = info->source == PE_AUTOCONFIG_SOURCE_GUESS
                    ? L"No settings were found for this address: these are the usual names, check them with your provider."
                    : L"These settings were found for this address. Change them if your provider gave you others.";
    }

    PeOAuthProvider provider = info ? pe_oauth_provider_for(core, info->imap_host) : PE_O_AUTH_PROVIDER_NONE;
    if (provider != PE_O_AUTH_PROVIDER_NONE &&
        MessageBoxW(owner,
                    L"This provider lets you sign in through your web browser, without giving PostalExpress your "
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
    while (FormDialog(owner, L"Add Mail Account", intro, fields, Validate)) {
        bool plain = SecurityOf(fields[IMAP_SECURITY].value) == PE_SECURITY_PLAIN ||
                     SecurityOf(fields[SMTP_SECURITY].value) == PE_SECURITY_PLAIN;
        if (plain && MessageBoxW(owner,
                                 L"Without encryption your password and mail travel the network readable by anyone on "
                                 L"the way. Use this only for a server on your own computer or network.\n\nContinue?",
                                 L"Add Mail Account", MB_YESNO | MB_ICONWARNING | MB_DEFBUTTON2) != IDYES) {
            continue;
        }
        // the user name is usually the address
        std::wstring username = fields[USERNAME].value.empty() ? fields[EMAIL].value : fields[USERNAME].value;
        std::wstring name = fields[NAME].value.empty() ? fields[EMAIL].value : fields[NAME].value;
        std::string utf8[] = {core::Narrow(name), core::Narrow(fields[EMAIL].value), core::Narrow(username),
                              core::Narrow(fields[IMAP_HOST].value), core::Narrow(fields[SMTP_HOST].value)};
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
