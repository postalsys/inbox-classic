// The new account form and the password prompt. The values go to the core as typed; the core checks them when it
// connects.
#include "app.h"

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

}  // namespace

int64_t NewAccountDialog(HWND owner, PeCore* core) {
    using Kind = FormField::Kind;
    std::vector<std::wstring> security(std::begin(kSecurity), std::end(kSecurity));
    std::vector<FormField> fields = {
        {L"Display name:", L""},
        {L"E-mail address:", L""},
        {L"User name:", L""},
        {L"Password:", L"", Kind::Password},
        {L"Incoming (IMAP) server:", L""},
        {L"IMAP port:", L"993", Kind::Number},
        {L"IMAP security:", kSecurity[0], Kind::Choice, security},
        {L"Outgoing (SMTP) server:", L""},
        {L"SMTP port:", L"465", Kind::Number},
        {L"SMTP security:", kSecurity[0], Kind::Choice, security},
    };
    while (FormDialog(owner, L"Add Mail Account", L"Enter the account details your e-mail provider gave you.", fields,
                      Validate)) {
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
