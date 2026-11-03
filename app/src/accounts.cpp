// The new account form and the password prompt. The values go to the core as typed; the core checks them when it
// connects.
#include "app.h"

#include <shellapi.h>

#include <algorithm>
#include <span>

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

}  // namespace

bool WaitForRequest(HWND owner, PeCore* core, uint64_t request, void (*cancel)(const PeCore*, uint64_t),
                    const std::wstring& text, const wchar_t* title) {
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
    HWND wait = CreateWindowExW(WS_EX_DLGMODALFRAME, kWaitClass, title, WS_POPUP | WS_CAPTION | WS_SYSMENU,
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

namespace {

// looks the servers of `email` up; the result, or NULL
core::Autoconfig WaitForLookup(HWND owner, PeCore* core, const std::wstring& email) {
    uint64_t request = pe_autoconfig_start(core, core::Narrow(email).c_str(), nullptr);
    size_t at = email.find_last_of(L'@');
    std::wstring text = L"Looking up the settings of " + email.substr(at == std::wstring::npos ? 0 : at + 1) + L"...";
    if (!WaitForRequest(owner, core, request, pe_autoconfig_cancel, text, L"Add Mail Account")) {
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

namespace {

// ---- the first page: the providers' sign-in buttons, or the name and address of any other account ----

enum class Start { Cancel, Next, SignIn };

// the ids of the first page: the name and address as the server form has them, the sign-in buttons, the "Why?" under
// each, and More sign-in options
enum StartId : int {
    IDC_START_NAME = 100,
    IDC_START_EMAIL = 101,
    IDC_SIGN_IN_GOOGLE = 120,
    IDC_SIGN_IN_MICROSOFT = 121,
    IDC_SIGN_IN_MORE = 122,
    IDC_WHY_GOOGLE = 123,
    IDC_WHY_MICROSOFT = 124,
};

// a provider's sign-in button: its id, its picture (the provider's own), what a screen reader says for it, and the
// "Why?" under it when it is off
struct SignInButton {
    PeOAuthProvider provider;
    int id;
    int picture;
    const wchar_t* label;
    const wchar_t* company;
    int why;
};
const SignInButton kSignIns[] = {
    {PE_O_AUTH_PROVIDER_GOOGLE, IDC_SIGN_IN_GOOGLE, IDR_GOOGLE_SIGN_IN, L"Sign in with Google", L"Google", IDC_WHY_GOOGLE},
    {PE_O_AUTH_PROVIDER_MICROSOFT, IDC_SIGN_IN_MICROSOFT, IDR_MICROSOFT_SIGN_IN, L"Sign in with Microsoft", L"Microsoft",
     IDC_WHY_MICROSOFT},
};

// the button of the command `id` (its own or its "Why?"), or of `provider`
const SignInButton* SignInOf(int id, PeOAuthProvider provider = PE_O_AUTH_PROVIDER_NONE) {
    for (const SignInButton& button : kSignIns) {
        if (button.id == id || button.why == id || button.provider == provider) {
            return &button;
        }
    }
    return nullptr;
}

// the sign-in apps as the core has them now: which built-in clients are on, and the added apps
struct SignInApps {
    core::SignInAppList list;

    explicit SignInApps(PeCore* core) : list(pe_sign_in_apps(core)) {}

    const PeSignInApp* Builtin(PeOAuthProvider provider) const {
        for (size_t i = 0; i < pe_sign_in_app_list_count(list.get()); i++) {
            const PeSignInApp* app = pe_sign_in_app_list_get(list.get(), i);
            if (app->provider == provider) {
                return app;
            }
        }
        return nullptr;
    }

    bool On(PeOAuthProvider provider) const {
        const PeSignInApp* app = Builtin(provider);
        return app && app->enabled;
    }

    // the added apps that are on, for new accounts
    std::vector<const PeSignInApp*> AddedOn() const {
        std::vector<const PeSignInApp*> on;
        for (size_t i = 0; i < pe_sign_in_app_list_count(list.get()); i++) {
            const PeSignInApp* app = pe_sign_in_app_list_get(list.get(), i);
            if (app->provider == PE_O_AUTH_PROVIDER_APP && app->enabled) {
                on.push_back(app);
            }
        }
        return on;
    }
};

const wchar_t* kStartClass = L"InboxClassicAccountStart";

struct StartState {
    PeCore* core = nullptr;
    const SignInApps* apps = nullptr;
    // the inputs of the page with fields, and where what is typed in them goes
    HWND nameInput = nullptr;
    HWND emailInput = nullptr;
    std::wstring* name = nullptr;
    std::wstring* email = nullptr;
    HWND more = nullptr;
    Start choice = Start::Cancel;
    SignInChoice with;
    bool done = false;
};

// a provider's sign-in button: its own picture (kept on the button), unchanged, with the focus rectangle inside it and
// pushed in by a pixel; when its client is turned off, the same picture faded into the window color
void DrawSignInButton(const DRAWITEMSTRUCT& item) {
    FillRect(item.hDC, &item.rcItem, GetSysColorBrush(COLOR_BTNFACE));
    if (auto picture = reinterpret_cast<HBITMAP>(GetWindowLongPtrW(item.hwndItem, GWLP_USERDATA))) {
        HDC memory = CreateCompatibleDC(item.hDC);
        HGDIOBJ old = SelectObject(memory, picture);
        int pushed = (item.itemState & ODS_SELECTED) ? 1 : 0;
        int width = item.rcItem.right - item.rcItem.left, height = item.rcItem.bottom - item.rcItem.top;
        if (item.itemState & ODS_DISABLED) {
            BLENDFUNCTION faded = {AC_SRC_OVER, 0, 102, 0};
            AlphaBlend(item.hDC, item.rcItem.left, item.rcItem.top, width, height, memory, 0, 0, width, height, faded);
        } else {
            BitBlt(item.hDC, item.rcItem.left + pushed, item.rcItem.top + pushed, width, height, memory, 0, 0, SRCCOPY);
        }
        SelectObject(memory, old);
        DeleteDC(memory);
    }
    if ((item.itemState & ODS_FOCUS) && !(item.itemState & ODS_NOFOCUSRECT)) {
        RECT focus = item.rcItem;
        InflateRect(&focus, -Scale(3), -Scale(3));
        DrawFocusRect(item.hDC, &focus);
    }
}

// More sign-in options: a menu of the added sign-in apps that are on, and Add a sign-in app; true with the app to sign
// in with chosen
bool ChooseMore(HWND hwnd, StartState& state) {
    constexpr int kAdd = 1000;
    std::vector<const PeSignInApp*> apps = state.apps->AddedOn();
    HMENU menu = CreatePopupMenu();
    for (size_t i = 0; i < apps.size(); i++) {
        AppendMenuW(menu, MF_STRING, i + 1, MenuText(Text(apps[i]->name)).c_str());
    }
    if (!apps.empty()) {
        AppendMenuW(menu, MF_SEPARATOR, 0, nullptr);
    }
    AppendMenuW(menu, MF_STRING, kAdd, L"Add a sign-in app...");
    RECT link;
    GetWindowRect(state.more, &link);
    // a popup menu of a window that is not in front would not close when clicking elsewhere
    SetForegroundWindow(hwnd);
    int chosen = TrackPopupMenu(menu, TPM_RETURNCMD | TPM_LEFTALIGN | TPM_TOPALIGN, link.left, link.bottom, 0, hwnd, nullptr);
    DestroyMenu(menu);
    int64_t app = 0;
    if (chosen == kAdd) {
        app = SignInAppEditor(hwnd, state.core, nullptr);
    } else if (chosen > 0 && static_cast<size_t>(chosen) <= apps.size()) {
        app = apps[chosen - 1]->id;
    }
    if (!app) {
        return false;
    }
    state.choice = Start::SignIn;
    state.with = {PE_O_AUTH_PROVIDER_APP, app};
    return true;
}

// what the command `id` chooses, false when the page stays (an address to type first, a reason shown)
bool Choose(HWND hwnd, StartState& state, int id) {
    const SignInButton* signIn = SignInOf(id);
    if (signIn && id == signIn->why) {
        const PeSignInApp* app = state.apps->Builtin(signIn->provider);
        std::wstring text = std::wstring(signIn->label) + L" is turned off on this computer.\n\n" + (app ? Text(app->off_reason) : L"");
        MessageBoxW(hwnd, text.c_str(), L"Add Mail Account", MB_OK | MB_ICONINFORMATION);
        return false;
    }
    if (signIn) {
        state.choice = Start::SignIn;
        state.with = {signIn->provider, 0};
    } else if (id == IDC_SIGN_IN_MORE) {
        if (!ChooseMore(hwnd, state)) {
            return false;
        }
    } else if (id == IDOK) {
        // the page of another account wants an address to look up
        if (state.emailInput && GetWindowString(state.emailInput).find(L'@') == std::wstring::npos) {
            MessageBoxW(hwnd, L"Type your e-mail address, name@example.com.", L"Inbox Classic", MB_OK | MB_ICONWARNING);
            SetFocus(state.emailInput);
            return false;
        }
        state.choice = Start::Next;
    } else if (id != IDCANCEL) {
        return false;
    }
    if (state.nameInput) {
        *state.name = GetWindowString(state.nameInput);
        *state.email = GetWindowString(state.emailInput);
    }
    return true;
}

LRESULT CALLBACK StartProc(HWND hwnd, UINT message, WPARAM wParam, LPARAM lParam) {
    auto* state = reinterpret_cast<StartState*>(GetWindowLongPtrW(hwnd, GWLP_USERDATA));
    if (!state) {
        return DefWindowProcW(hwnd, message, wParam, lParam);
    }
    switch (message) {
    case WM_COMMAND:
        state->done = Choose(hwnd, *state, LOWORD(wParam));
        return 0;
    case WM_DRAWITEM: {
        auto* item = reinterpret_cast<const DRAWITEMSTRUCT*>(lParam);
        if (GetPropW(item->hwndItem, L"InboxClassicLink")) {
            DrawLinkButton(*item);
        } else {
            DrawSignInButton(*item);
        }
        return TRUE;
    }
    case WM_SETCURSOR:
        if (SetLinkCursor(hwnd, wParam)) {
            return TRUE;
        }
        break;
    case WM_CLOSE:
        state->choice = Start::Cancel;
        state->done = true;
        return 0;
    case WM_CTLCOLORSTATIC:
        return ButtonFaceColor(reinterpret_cast<HDC>(wParam));
    }
    return DefWindowProcW(hwnd, message, wParam, lParam);
}

// what a page of Add Mail Account offers: the intro, a sign-in button for each of `providers` (faded and turned off
// when its client is off; left out when all are off), More sign-in options when `more`, then when `fields` the name
// and address of any other account and `nextLabel` to go on with that
struct StartOffer {
    std::wstring intro;
    std::vector<PeOAuthProvider> providers;
    bool more = false;
    bool fields = false;
    const wchar_t* nextLabel = L"Next >";
};

// a tooltip over the area of the turned-off button `button`: a turned-off control gets no mouse messages, so the tool
// belongs to the window under it
void AddReasonTip(HWND dialog, HWND& tooltip, HWND button, const std::wstring& reason) {
    if (!tooltip) {
        tooltip = CreateWindowExW(WS_EX_TOPMOST, TOOLTIPS_CLASSW, nullptr, WS_POPUP | TTS_ALWAYSTIP | TTS_NOPREFIX, CW_USEDEFAULT,
                                  CW_USEDEFAULT, CW_USEDEFAULT, CW_USEDEFAULT, dialog, nullptr, GetModuleHandleW(nullptr), nullptr);
        SendMessageW(tooltip, TTM_SETMAXTIPWIDTH, 0, Scale(320));
    }
    TOOLINFOW tool = {sizeof(tool)};
    tool.uFlags = TTF_SUBCLASS;
    tool.hwnd = dialog;
    tool.uId = static_cast<UINT_PTR>(GetDlgCtrlID(button));
    GetWindowRect(button, &tool.rect);
    MapWindowPoints(nullptr, dialog, reinterpret_cast<POINT*>(&tool.rect), 2);
    tool.lpszText = const_cast<wchar_t*>(reason.c_str());
    SendMessageW(tooltip, TTM_ADDTOOLW, 0, reinterpret_cast<LPARAM>(&tool));
}

Start StartPage(HWND owner, PeCore* core, const SignInApps& apps, const StartOffer& offer, std::wstring& name,
                std::wstring& email, SignInChoice& chosen) {
    RegisterDialogClass(kStartClass, StartProc);
    // the buttons, side by side; none when every one of them is off
    std::vector<const SignInButton*> shown;
    bool anyOn = false, anyOff = false;
    for (const SignInButton& button : kSignIns) {
        if (std::find(offer.providers.begin(), offer.providers.end(), button.provider) != offer.providers.end()) {
            shown.push_back(&button);
            (apps.On(button.provider) ? anyOn : anyOff) = true;
        }
    }
    if (!anyOn) {
        shown.clear();
        anyOff = false;
    }
    int pad = Scale(10), width = Scale(440), rowHeight = Scale(22), labelWidth = Scale(110);
    int introHeight = Scale(30), buttonHeight = Scale(40), gap = Scale(12), reasonHeight = Scale(18), linkHeight = Scale(20);
    int buttonsHeight = shown.empty() ? 0 : buttonHeight + (anyOff ? reasonHeight : 0) + Scale(8);
    int moreHeight = offer.more ? linkHeight + Scale(6) : 0;
    int otherHeight = offer.fields ? Scale(12) + Scale(30) + 2 * (rowHeight + Scale(6)) : 0;
    int height = pad + introHeight + Scale(8) + buttonsHeight + moreHeight + Scale(6) + otherHeight + Scale(25) + pad;
    HWND dialog = CreateModalWindow(owner, kStartClass, L"Add Mail Account", width, height);
    StartState state{core, &apps};

    int top = pad;
    CreateChild(dialog, L"STATIC", offer.intro.c_str(), SS_LEFT | SS_NOPREFIX, 0, {pad, top, width - pad, top + introHeight});
    top += introHeight + Scale(8);
    // centered, each as wide as its picture is at this height
    std::vector<HBITMAP> pictures;
    std::vector<int> widths;
    int total = -gap;
    for (const SignInButton* button : shown) {
        int buttonWidth = Scale(200);
        pictures.push_back(LoadPicture(button->picture, buttonHeight, GetSysColor(COLOR_BTNFACE), buttonWidth));
        widths.push_back(buttonWidth);
        total += buttonWidth + gap;
    }
    HWND firstButton = nullptr, tooltip = nullptr;
    std::vector<std::wstring> reasons(shown.size());
    int left = (width - total) / 2;
    for (size_t i = 0; i < shown.size(); i++) {
        const SignInButton* button = shown[i];
        bool on = apps.On(button->provider);
        // the text is what a screen reader says; the picture shows the same words. A turned-off one is skipped by Tab
        HWND control = CreateChild(dialog, L"BUTTON", button->label, (on ? WS_TABSTOP : WS_DISABLED) | BS_OWNERDRAW, button->id,
                                   {left, top, left + widths[i], top + buttonHeight});
        SetWindowLongPtrW(control, GWLP_USERDATA, reinterpret_cast<LONG_PTR>(pictures[i]));
        if (on) {
            firstButton = firstButton ? firstButton : control;
        } else {
            // why, without hovering: a line under it with Why?, the same words as its tooltip and for a screen reader
            const PeSignInApp* app = apps.Builtin(button->provider);
            reasons[i] = std::wstring(button->label) + L" is turned off on this computer. " + (app ? Text(app->off_reason) : L"");
            SetAccessibleDescription(control, reasons[i]);
            AddReasonTip(dialog, tooltip, control, reasons[i]);
            int lineTop = top + buttonHeight + Scale(2);
            CreateChild(dialog, L"STATIC", L"Turned off on this computer.", SS_LEFT | SS_NOPREFIX, 0,
                        {left, lineTop, left + widths[i] - Scale(40), lineTop + reasonHeight});
            CreateLinkButton(dialog, L"Why?", button->why, {left + widths[i] - Scale(38), lineTop - Scale(1), left + widths[i], lineTop + reasonHeight});
        }
        left += widths[i] + gap;
    }
    top += buttonsHeight;
    if (offer.more) {
        state.more = CreateLinkButton(dialog, L"More sign-in options...", IDC_SIGN_IN_MORE, {pad, top, pad + Scale(160), top + linkHeight});
        top += moreHeight;
    }
    top += Scale(6);
    if (offer.fields) {
        CreateChild(dialog, L"STATIC", L"", SS_ETCHEDHORZ, 0, {pad, top, width - pad, top + 2});
        top += Scale(12);
        CreateChild(dialog, L"STATIC",
                    L"Any other e-mail account: your name as others see it and your e-mail address. Its servers are "
                    L"looked up next.",
                    SS_LEFT | SS_NOPREFIX, 0, {pad, top, width - pad, top + Scale(30)});
        top += Scale(30);
        CreateChild(dialog, L"STATIC", L"Display name:", SS_LEFT, 0, {pad, top + Scale(3), pad + labelWidth, top + rowHeight});
        state.nameInput = CreateChild(dialog, L"EDIT", name.c_str(), WS_TABSTOP | ES_AUTOHSCROLL, IDC_START_NAME,
                                      {pad + labelWidth, top, width - pad, top + rowHeight}, WS_EX_CLIENTEDGE);
        top += rowHeight + Scale(6);
        CreateChild(dialog, L"STATIC", L"E-mail address:", SS_LEFT, 0, {pad, top + Scale(3), pad + labelWidth, top + rowHeight});
        state.emailInput = CreateChild(dialog, L"EDIT", email.c_str(), WS_TABSTOP | ES_AUTOHSCROLL, IDC_START_EMAIL,
                                       {pad + labelWidth, top, width - pad, top + rowHeight}, WS_EX_CLIENTEDGE);
        state.name = &name;
        state.email = &email;
    }
    int buttonWidth = Scale(110), buttonTop = height - pad - Scale(25);
    // the default where it goes on with what was typed; beside a provider's button, the other way only
    CreateChild(dialog, L"BUTTON", offer.nextLabel, WS_TABSTOP | (offer.fields ? BS_DEFPUSHBUTTON : BS_PUSHBUTTON), IDOK,
                {width - pad - buttonWidth - Scale(86), buttonTop, width - pad - Scale(86), buttonTop + Scale(25)});
    CreateChild(dialog, L"BUTTON", L"Cancel", WS_TABSTOP, IDCANCEL, {width - pad - Scale(80), buttonTop, width - pad, buttonTop + Scale(25)});

    SetWindowLongPtrW(dialog, GWLP_USERDATA, reinterpret_cast<LONG_PTR>(&state));
    // typing comes first on the page with the fields; the provider's button on the page that offers it
    RunModal(dialog, state.nameInput ? state.nameInput : firstButton ? firstButton : state.more, state.done);
    for (HBITMAP picture : pictures) {
        if (picture) {
            DeleteObject(picture);
        }
    }
    chosen = state.with;
    return state.choice;
}

// the page the browser sign-in starts on: written to the file of --sign-in-page-file in a test run
std::wstring g_signInPageFile;

}  // namespace

void SetSignInPageFile(const std::wstring& path) {
    g_signInPageFile = path;
}

uint64_t SignInWithBrowser(HWND owner, PeCore* core, SignInChoice with, const std::wstring& email) {
    char* page = nullptr;
    uint64_t request = pe_sign_in_begin(core, with.provider, with.app, core::Narrow(email).c_str(), &page);
    core::String url(page);
    // the core makes the page, and gives only an https page or one of a provider on this computer (a test server)
    std::wstring address = url ? Text(url.get()) : L"";
    if (!request || address.empty()) {
        MessageBoxW(owner, L"Signing in through the browser could not start.", L"Inbox Classic", MB_OK | MB_ICONERROR);
        return 0;
    }
    if (g_signInPageFile.empty()) {
        ShellExecuteW(owner, L"open", address.c_str(), nullptr, nullptr, SW_SHOWNORMAL);
    } else {
        WriteFileBytes(g_signInPageFile, reinterpret_cast<const uint8_t*>(url.get()), strlen(url.get()));
    }
    std::wstring account = email.empty() ? L"your account" : email;
    if (!WaitForRequest(owner, core, request, pe_sign_in_cancel,
                        L"Sign in to " + account + L" in the browser window that opened, then come back here.", L"Add Mail Account")) {
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

namespace {

// signs in with `with` in the browser (`email`, when typed, as the account to suggest there) and adds the account
// signed in to, named `name` or, without one, as at the provider
int64_t AddSignedIn(HWND owner, PeCore* core, SignInChoice with, const std::wstring& name, const std::wstring& email) {
    uint64_t request = SignInWithBrowser(owner, core, with, email);
    if (!request) {
        return 0;
    }
    int64_t account = pe_account_add_signed_in(core, request, core::Narrow(name).c_str());
    if (account <= 0) {
        MessageBoxW(owner, L"The account could not be saved.", L"Add Mail Account", MB_OK | MB_ICONERROR);
    }
    return account;
}

}  // namespace

int64_t NewAccountDialog(HWND owner, PeCore* core) {
    std::wstring name, email;
    SignInChoice chosen;
    SignInApps apps(core);
    StartOffer first;
    first.providers = {PE_O_AUTH_PROVIDER_GOOGLE, PE_O_AUTH_PROVIDER_MICROSOFT};
    first.more = true;
    first.fields = true;
    first.intro = apps.On(PE_O_AUTH_PROVIDER_GOOGLE) || apps.On(PE_O_AUTH_PROVIDER_MICROSOFT)
                      ? L"Gmail, Google Workspace, Outlook.com and Microsoft 365: sign in on Google's or Microsoft's own page. "
                        L"Your password is typed there, never into Inbox Classic."
                      : L"Sign in through the browser with one of your sign-in apps (More sign-in options), or add any "
                        L"e-mail account with your name and address below.";
    Start start = StartPage(owner, core, apps, first, name, email, chosen);
    if (start == Start::Cancel) {
        return 0;
    }
    if (start == Start::SignIn) {
        return AddSignedIn(owner, core, chosen, name, email);
    }
    core::Autoconfig found = WaitForLookup(owner, core, email);
    const PeAutoconfigInfo* info = pe_autoconfig_info(found.get());
    std::wstring intro = FoundIntro(info);

    // an address at Google or Microsoft: a browser sign-in first (the built-in client when it is on, the added sign-in
    // apps that are), an app password the other way
    PeOAuthProvider provider = info ? pe_oauth_provider_for(core, info->imap_host) : PE_O_AUTH_PROVIDER_NONE;
    StartOffer offer;
    offer.more = !apps.AddedOn().empty();
    offer.nextLabel = L"Use App Password";
    if (provider != PE_O_AUTH_PROVIDER_NONE && (apps.On(provider) || offer.more)) {
        const SignInButton* signIn = SignInOf(0, provider);
        std::wstring company = signIn ? signIn->company : L"the provider";
        if (apps.On(provider)) {
            offer.providers = {provider};
            offer.intro = email + L" signs in on " + company +
                          L"'s own page, without giving Inbox Classic your password. Or use an app password made in your "
                          L"account's security settings.";
        } else {
            offer.intro = email + L" can sign in on " + company +
                          L"'s own page with one of your sign-in apps (More sign-in options). Or use an app password made "
                          L"in your account's security settings.";
        }
        Start choice = StartPage(owner, core, apps, offer, name, email, chosen);
        if (choice == Start::Cancel) {
            return 0;
        }
        if (choice == Start::SignIn) {
            return AddSignedIn(owner, core, chosen, name, email);
        }
    }

    ExplainAppPassword(owner, info);
    using Kind = FormField::Kind;
    std::vector<std::wstring> security(std::begin(kSecurity), std::end(kSecurity));
    std::vector<FormField> fields = {
        {L"Display name:", name},
        {L"E-mail address:", email},
        {L"User name:", info ? Text(info->username) : L""},
        {L"Password:", L"", Kind::Password},
        {L"Incoming (IMAP) server:", info ? Text(info->imap_host) : L""},
        {L"IMAP port:", info ? std::to_wstring(info->imap_port) : L"993", Kind::Number},
        {L"IMAP security:", info ? SecurityName(info->imap_security) : kSecurity[0], Kind::Choice, security},
        {L"Outgoing (SMTP) server:", info ? Text(info->smtp_host) : L""},
        {L"SMTP port:", info ? std::to_wstring(info->smtp_port) : L"465", Kind::Number},
        {L"SMTP security:", info ? SecurityName(info->smtp_security) : kSecurity[0], Kind::Choice, security},
    };
    // the name and address were typed already: the password is next
    while (FormDialog(owner, L"Add Mail Account", intro, fields, Validate, L"Finish", PASSWORD)) {
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

enum AccountsId : WORD {
    IDC_ACCOUNT_LIST = 400,
    IDC_ACCOUNT_ADD,
    IDC_ACCOUNT_PROPERTIES,
    IDC_ACCOUNT_REMOVE,
    IDC_ACCOUNT_CLOSE,
    IDC_ACCOUNT_SIGN_IN_APPS,
};

struct AccountsState {
    PeCore* core;
    HWND list = nullptr;
    std::vector<int64_t> ids;
    // what each signs in with through the browser, by position; empty for a password
    std::vector<std::wstring> signsInWith;
    bool done = false;
    bool changed = false;
};

enum AccountColumn { COL_NAME, COL_EMAIL, COL_SERVER };

// a row per account: its name, address and incoming server (or the provider's sign-in); `select` stays selected
void FillAccounts(AccountsState* state, int select = 0) {
    ListView_DeleteAllItems(state->list);
    state->ids.clear();
    state->signsInWith.clear();
    core::AccountList accounts(pe_accounts(state->core));
    for (size_t i = 0; i < pe_account_list_count(accounts.get()); i++) {
        const PeAccount* account = pe_account_list_get(accounts.get(), i);
        int row = AddRow(state->list, static_cast<int>(i), Text(account->name));
        bool oauth = account->oauth != PE_O_AUTH_PROVIDER_NONE;
        SetCell(state->list, row, COL_EMAIL, Text(account->email));
        SetCell(state->list, row, COL_SERVER, Text(account->imap_host) + (oauth ? L" (browser sign-in)" : L""));
        state->ids.push_back(account->id);
        state->signsInWith.push_back(oauth ? Text(account->signs_in_with) : L"");
    }
    SelectRow(state->list, select);
}


// the settings of an account, changed: the server form for a password account, the name for one that signs in
// through the browser with `signsInWith` (its servers are the sign-in's); a password typed in replaces the kept one
bool AccountProperties(HWND owner, PeCore* core, int64_t account, const std::wstring& signsInWith) {
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
    if (!signsInWith.empty()) {
        // a browser sign-in account: the name only, the rest is the provider's
        std::vector<FormField> name = {fields[NAME]};
        std::wstring intro = L"Signs in with: " + signsInWith + L". It signs in through the browser and uses the servers of its sign-in.";
        if (!FormDialog(owner, L"Properties", intro, name)) {
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
        if (chosen && AccountProperties(hwnd, state->core, account, state->signsInWith[index])) {
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
    case IDC_ACCOUNT_SIGN_IN_APPS:
        SignInAppsDialog(hwnd, state->core);
        FillAccounts(state, index);
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
    Button buttons[] = {{IDC_ACCOUNT_ADD, L"&Add..."},
                        {IDC_ACCOUNT_PROPERTIES, L"&Properties..."},
                        {IDC_ACCOUNT_REMOVE, L"&Remove"},
                        {IDC_ACCOUNT_SIGN_IN_APPS, L"Sign-in A&pps..."}};
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
