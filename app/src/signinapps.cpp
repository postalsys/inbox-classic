// Sign-in apps: the Sign-in Apps window (File > Accounts) with the built-in Google and Microsoft clients and the OAuth
// clients the user added, each turned on or off for new accounts, and the editor of an added one. What is typed goes
// to the core as it is; the core checks the issuer (OpenID Connect discovery) and the rest before saving.
#include "app.h"

namespace {

const wchar_t* kSecurityNames[] = {L"SSL/TLS", L"STARTTLS"};

PeSecurity SecurityAt(int index) {
    return index == 1 ? PE_SECURITY_START_TLS : PE_SECURITY_TLS;
}

int SecurityIndex(PeSecurity security) {
    return security == PE_SECURITY_START_TLS ? 1 : 0;
}

// ---- the editor ----

enum EditorId : int {
    IDC_APP_PRESET = 600,
    IDC_APP_NAME = 610,
    IDC_APP_ISSUER,
    IDC_APP_CHECK,
    IDC_APP_CLIENT_ID,
    IDC_APP_SECRET,
    IDC_APP_REMOVE_SECRET,
    IDC_APP_SCOPES,
    IDC_APP_IMAP_HOST,
    IDC_APP_IMAP_PORT,
    IDC_APP_IMAP_SECURITY,
    IDC_APP_SMTP_HOST,
    IDC_APP_SMTP_PORT,
    IDC_APP_SMTP_SECURITY,
    IDC_APP_REGISTER,
    IDC_APP_REDIRECT,
    IDC_APP_COPY,
};

const wchar_t* kEditorClass = L"InboxClassicSignInApp";

struct EditorState {
    PeCore* core = nullptr;
    // the app changed, 0 for a new one; and whether it has a secret saved
    int64_t id = 0;
    bool hadSecret = false;
    core::SignInPresetList presets;
    int64_t saved = 0;
    bool done = false;
};

HWND Item(HWND dialog, int id) {
    return GetDlgItem(dialog, id);
}

std::wstring ItemText(HWND dialog, int id) {
    return GetWindowString(Item(dialog, id));
}

void SetItemText(HWND dialog, int id, const std::wstring& text) {
    SetWindowTextW(Item(dialog, id), text.c_str());
}

// the redirect URI and how to register a client, for the issuer typed
void ShowRegistration(HWND dialog) {
    std::string issuer = core::Narrow(ItemText(dialog, IDC_APP_ISSUER));
    core::String redirect(pe_sign_in_redirect_uri(issuer.c_str()));
    core::String hint(pe_sign_in_register_hint(issuer.c_str()));
    SetItemText(dialog, IDC_APP_REDIRECT, redirect ? Text(redirect.get()) : L"");
    SetItemText(dialog, IDC_APP_REGISTER, hint ? Text(hint.get()) : L"");
}

// a preset fills in everything but the client; the name only when there is none yet
void FillPreset(HWND dialog, const PeSignInPreset& preset) {
    if (ItemText(dialog, IDC_APP_NAME).empty()) {
        SetItemText(dialog, IDC_APP_NAME, Text(preset.name) + L" sign-in app");
    }
    SetItemText(dialog, IDC_APP_ISSUER, Text(preset.issuer));
    SetItemText(dialog, IDC_APP_SCOPES, Text(preset.scopes));
    SetItemText(dialog, IDC_APP_IMAP_HOST, Text(preset.imap_host));
    SetItemText(dialog, IDC_APP_IMAP_PORT, std::to_wstring(preset.imap_port));
    SendMessageW(Item(dialog, IDC_APP_IMAP_SECURITY), CB_SETCURSEL, SecurityIndex(preset.imap_security), 0);
    SetItemText(dialog, IDC_APP_SMTP_HOST, Text(preset.smtp_host));
    SetItemText(dialog, IDC_APP_SMTP_PORT, std::to_wstring(preset.smtp_port));
    SendMessageW(Item(dialog, IDC_APP_SMTP_SECURITY), CB_SETCURSEL, SecurityIndex(preset.smtp_security), 0);
    ShowRegistration(dialog);
    SetFocus(Item(dialog, IDC_APP_CLIENT_ID));
}

uint16_t PortOf(HWND dialog, int id) {
    std::wstring text = ItemText(dialog, id);
    unsigned long port = text.size() <= 5 ? wcstoul(text.c_str(), nullptr, 10) : 0;
    return static_cast<uint16_t>(port <= 65535 ? port : 0);
}

// checks the issuer typed (its discovery document), waiting with a window that can cancel it: true when it can be
// used, with what was found or why not in `said`
bool CheckIssuer(HWND dialog, PeCore* core, std::wstring& said) {
    std::wstring issuer = ItemText(dialog, IDC_APP_ISSUER);
    char* error = nullptr;
    uint64_t request = pe_sign_in_app_check(core, core::Narrow(issuer).c_str(), &error);
    core::String reason(error);
    if (!request) {
        said = reason ? Text(reason.get()) : L"the issuer can not be checked";
        return false;
    }
    if (!WaitForRequest(dialog, core, request, pe_sign_in_app_check_cancel, L"Checking " + issuer + L"...", L"Sign-in App")) {
        said.clear();
        return false;
    }
    char* text = nullptr;
    bool usable = pe_sign_in_app_check_result(core, request, &text);
    core::String found(text);
    said = found ? Text(found.get()) : L"";
    return usable;
}

// OK: the issuer checked, then the app saved; false when the editor stays open (with the reason shown)
bool SaveApp(HWND dialog, EditorState& state) {
    uint16_t imapPort = PortOf(dialog, IDC_APP_IMAP_PORT), smtpPort = PortOf(dialog, IDC_APP_SMTP_PORT);
    if (!imapPort || !smtpPort) {
        MessageBoxW(dialog, L"Ports are numbers from 1 to 65535.", L"Sign-in App", MB_OK | MB_ICONWARNING);
        return false;
    }
    std::wstring said;
    if (!CheckIssuer(dialog, state.core, said)) {
        if (!said.empty()) {
            MessageBoxW(dialog, (L"The issuer can not be used: " + said).c_str(), L"Sign-in App", MB_OK | MB_ICONWARNING);
            SetFocus(Item(dialog, IDC_APP_ISSUER));
        }
        return false;
    }
    std::string text[7] = {
        core::Narrow(ItemText(dialog, IDC_APP_NAME)),      core::Narrow(ItemText(dialog, IDC_APP_ISSUER)),
        core::Narrow(ItemText(dialog, IDC_APP_CLIENT_ID)), core::Narrow(ItemText(dialog, IDC_APP_SCOPES)),
        core::Narrow(ItemText(dialog, IDC_APP_IMAP_HOST)), core::Narrow(ItemText(dialog, IDC_APP_SMTP_HOST)),
        core::Narrow(ItemText(dialog, IDC_APP_SECRET)),
    };
    PeSignInAppForm form = {};
    form.name = text[0].c_str();
    form.issuer = text[1].c_str();
    form.client_id = text[2].c_str();
    form.scopes = text[3].c_str();
    form.imap_host = text[4].c_str();
    form.imap_port = imapPort;
    form.imap_security = SecurityAt(static_cast<int>(SendMessageW(Item(dialog, IDC_APP_IMAP_SECURITY), CB_GETCURSEL, 0, 0)));
    form.smtp_host = text[5].c_str();
    form.smtp_port = smtpPort;
    form.smtp_security = SecurityAt(static_cast<int>(SendMessageW(Item(dialog, IDC_APP_SMTP_SECURITY), CB_GETCURSEL, 0, 0)));
    bool remove = state.hadSecret && SendMessageW(Item(dialog, IDC_APP_REMOVE_SECRET), BM_GETCHECK, 0, 0) == BST_CHECKED;
    PeSecretChange change = !text[6].empty() ? PE_SECRET_CHANGE_SET : remove ? PE_SECRET_CHANGE_REMOVE : PE_SECRET_CHANGE_KEEP;
    char* error = nullptr;
    int64_t saved = pe_sign_in_app_save(state.core, state.id, &form, change, text[6].c_str(), &error);
    SecureZeroMemory(text[6].data(), text[6].size());
    core::String reason(error);
    if (!saved) {
        std::wstring message = L"The sign-in app could not be saved: " + (reason ? Text(reason.get()) : L"unknown reason");
        MessageBoxW(dialog, message.c_str(), L"Sign-in App", MB_OK | MB_ICONWARNING);
        return false;
    }
    state.saved = saved;
    return true;
}

void OnEditorCommand(HWND dialog, EditorState& state, int id, int code) {
    size_t presets = pe_sign_in_preset_list_count(state.presets.get());
    if (id >= IDC_APP_PRESET && static_cast<size_t>(id - IDC_APP_PRESET) < presets) {
        FillPreset(dialog, *pe_sign_in_preset_list_get(state.presets.get(), id - IDC_APP_PRESET));
        return;
    }
    switch (id) {
    case IDC_APP_ISSUER:
        if (code == EN_CHANGE) {
            ShowRegistration(dialog);
        }
        return;
    case IDC_APP_CHECK: {
        std::wstring said;
        bool usable = CheckIssuer(dialog, state.core, said);
        if (!said.empty()) {
            std::wstring text = usable ? L"The issuer can be used.\n\n" + said : L"The issuer can not be used: " + said;
            MessageBoxW(dialog, text.c_str(), L"Check", MB_OK | (usable ? MB_ICONINFORMATION : MB_ICONWARNING));
        }
        return;
    }
    case IDC_APP_COPY: {
        HWND redirect = Item(dialog, IDC_APP_REDIRECT);
        SendMessageW(redirect, EM_SETSEL, 0, -1);
        SendMessageW(redirect, WM_COPY, 0, 0);
        return;
    }
    case IDOK:
        state.done = SaveApp(dialog, state);
        return;
    case IDCANCEL:
        state.done = true;
        return;
    }
}

LRESULT CALLBACK EditorProc(HWND hwnd, UINT message, WPARAM wParam, LPARAM lParam) {
    auto* state = reinterpret_cast<EditorState*>(GetWindowLongPtrW(hwnd, GWLP_USERDATA));
    switch (message) {
    case WM_COMMAND:
        if (state) {
            OnEditorCommand(hwnd, *state, LOWORD(wParam), HIWORD(wParam));
        }
        return 0;
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

// a row of the editor: its label, then the control at `left` to `right`
HWND EditorRow(HWND dialog, const wchar_t* label, int top, int pad, int labelWidth, const wchar_t* className, const std::wstring& text,
               DWORD style, int id, int right, DWORD exStyle = WS_EX_CLIENTEDGE) {
    int height = Scale(22);
    if (label) {
        CreateChild(dialog, L"STATIC", label, SS_LEFT, 0, {pad, top + Scale(3), pad + labelWidth, top + height});
    }
    return CreateChild(dialog, className, text.c_str(), WS_TABSTOP | style, id, {pad + labelWidth, top, right, top + height}, exStyle);
}

HWND SecurityChoice(HWND dialog, int id, const RECT& bounds, PeSecurity chosen) {
    HWND combo = CreateChild(dialog, L"COMBOBOX", nullptr, WS_TABSTOP | WS_VSCROLL | CBS_DROPDOWNLIST, id,
                             {bounds.left, bounds.top, bounds.right, bounds.top + Scale(120)});
    for (const wchar_t* name : kSecurityNames) {
        SendMessageW(combo, CB_ADDSTRING, 0, reinterpret_cast<LPARAM>(name));
    }
    SendMessageW(combo, CB_SETCURSEL, SecurityIndex(chosen), 0);
    return combo;
}

// the servers row: host, port and encryption
void ServerRow(HWND dialog, const wchar_t* label, int top, int pad, int labelWidth, int width, int ids, const std::wstring& host,
               uint16_t port, PeSecurity security) {
    int portLeft = width - pad - Scale(190);
    EditorRow(dialog, label, top, pad, labelWidth, L"EDIT", host, ES_AUTOHSCROLL, ids, portLeft - Scale(6));
    CreateChild(dialog, L"EDIT", port ? std::to_wstring(port).c_str() : L"", WS_TABSTOP | ES_NUMBER, ids + 1,
                {portLeft, top, portLeft + Scale(50), top + Scale(22)}, WS_EX_CLIENTEDGE);
    SecurityChoice(dialog, ids + 2, {portLeft + Scale(56), top, width - pad, top}, security);
}

}  // namespace

int64_t SignInAppEditor(HWND owner, PeCore* core, const PeSignInApp* app) {
    RegisterDialogClass(kEditorClass, EditorProc);
    EditorState state{core};
    state.presets.reset(pe_sign_in_presets());
    state.id = app ? app->id : 0;
    state.hadSecret = app && app->has_secret;
    int pad = Scale(10), width = Scale(500), labelWidth = Scale(110), row = Scale(28);
    int rows = 7 + (state.hadSecret ? 1 : 0);
    // the intro, the presets and the rows, the registration box, the redirect URI, the buttons
    int height = pad + Scale(36) + row + rows * row + Scale(6 + 8 + 20 + 48) + Scale(22) + Scale(16) + Scale(25) + pad;
    HWND dialog = CreateModalWindow(owner, kEditorClass, app ? L"Sign-in App" : L"Add Sign-in App", width, height);
    SetWindowLongPtrW(dialog, GWLP_USERDATA, 0);

    int top = pad;
    CreateChild(dialog, L"STATIC",
                L"An OAuth client you registered with your provider, for accounts that sign in through the browser. "
                L"Fill it in for a provider, then add the client ID (and secret, if the provider gave one).",
                SS_LEFT | SS_NOPREFIX, 0, {pad, top, width - pad, top + Scale(32)});
    top += Scale(36);
    CreateChild(dialog, L"STATIC", L"Fill in for:", SS_LEFT, 0, {pad, top + Scale(4), pad + labelWidth, top + Scale(22)});
    int left = pad + labelWidth;
    for (size_t i = 0; i < pe_sign_in_preset_list_count(state.presets.get()); i++) {
        const PeSignInPreset* preset = pe_sign_in_preset_list_get(state.presets.get(), i);
        CreateChild(dialog, L"BUTTON", Text(preset->name).c_str(), WS_TABSTOP, IDC_APP_PRESET + static_cast<int>(i),
                    {left, top, left + Scale(90), top + Scale(24)});
        left += Scale(96);
    }
    top += row;
    int right = width - pad;
    HWND name = EditorRow(dialog, L"Name:", top, pad, labelWidth, L"EDIT", app ? Text(app->name) : L"", ES_AUTOHSCROLL, IDC_APP_NAME, right);
    top += row;
    EditorRow(dialog, L"Issuer:", top, pad, labelWidth, L"EDIT", app ? Text(app->issuer) : L"", ES_AUTOHSCROLL, IDC_APP_ISSUER,
              right - Scale(86));
    CreateChild(dialog, L"BUTTON", L"C&heck", WS_TABSTOP, IDC_APP_CHECK, {right - Scale(80), top - Scale(1), right, top + Scale(23)});
    top += row;
    EditorRow(dialog, L"Client ID:", top, pad, labelWidth, L"EDIT", app ? Text(app->client_id) : L"", ES_AUTOHSCROLL,
              IDC_APP_CLIENT_ID, right);
    top += row;
    // never shown again once saved: it is in the Credential Manager
    EditorRow(dialog, L"Client secret:", top, pad, labelWidth, L"EDIT", L"", ES_AUTOHSCROLL | ES_PASSWORD, IDC_APP_SECRET, right);
    top += row;
    if (state.hadSecret) {
        CreateChild(dialog, L"BUTTON", L"A secret is saved; type another to replace it, or remove it", WS_TABSTOP | BS_AUTOCHECKBOX,
                    IDC_APP_REMOVE_SECRET, {pad + labelWidth, top, right, top + Scale(22)});
        top += row;
    }
    EditorRow(dialog, L"Scopes:", top, pad, labelWidth, L"EDIT", app ? Text(app->scopes) : L"", ES_AUTOHSCROLL, IDC_APP_SCOPES, right);
    top += row;
    ServerRow(dialog, L"IMAP server:", top, pad, labelWidth, width, IDC_APP_IMAP_HOST, app ? Text(app->imap_host) : L"",
              app ? app->imap_port : 993, app ? app->imap_security : PE_SECURITY_TLS);
    top += row;
    ServerRow(dialog, L"SMTP server:", top, pad, labelWidth, width, IDC_APP_SMTP_HOST, app ? Text(app->smtp_host) : L"",
              app ? app->smtp_port : 465, app ? app->smtp_security : PE_SECURITY_TLS);
    top += row + Scale(6);
    CreateChild(dialog, L"STATIC", L"", SS_ETCHEDHORZ, 0, {pad, top, right, top + 2});
    top += Scale(8);
    CreateChild(dialog, L"STATIC", L"Register it with your provider", SS_LEFT | SS_NOPREFIX, 0, {pad, top, right, top + Scale(18)});
    top += Scale(20);
    CreateChild(dialog, L"STATIC", L"", SS_LEFT | SS_NOPREFIX, IDC_APP_REGISTER, {pad, top, right, top + Scale(46)});
    top += Scale(48);
    EditorRow(dialog, L"Redirect URI:", top, pad, labelWidth, L"EDIT", L"", ES_AUTOHSCROLL | ES_READONLY, IDC_APP_REDIRECT, right - Scale(86));
    CreateChild(dialog, L"BUTTON", L"&Copy", WS_TABSTOP, IDC_APP_COPY, {right - Scale(80), top - Scale(1), right, top + Scale(23)});

    int buttonTop = height - pad - Scale(25);
    CreateChild(dialog, L"BUTTON", L"OK", WS_TABSTOP | BS_DEFPUSHBUTTON, IDOK,
                {right - Scale(166), buttonTop, right - Scale(86), buttonTop + Scale(25)});
    CreateChild(dialog, L"BUTTON", L"Cancel", WS_TABSTOP, IDCANCEL, {right - Scale(80), buttonTop, right, buttonTop + Scale(25)});
    ShowRegistration(dialog);
    SetWindowLongPtrW(dialog, GWLP_USERDATA, reinterpret_cast<LONG_PTR>(&state));
    RunModal(dialog, app ? name : Item(dialog, IDC_APP_PRESET), state.done);
    return state.saved;
}

// ---- the Sign-in Apps window ----

namespace {

const wchar_t* kAppsClass = L"InboxClassicSignInApps";

enum AppsId : WORD { IDC_APPS_LIST = 700, IDC_APPS_ADD, IDC_APPS_EDIT, IDC_APPS_REMOVE, IDC_APPS_NOTE, IDC_APPS_CLOSE };

enum AppsColumn { APPS_NAME, APPS_ISSUER, APPS_USED_BY };

// the rows filled again once the list's notification of a check box is over (wParam: the row to select)
constexpr UINT WM_REFILL = WM_APP + 10;

struct AppsState {
    PeCore* core;
    HWND list = nullptr;
    core::SignInAppList apps;
    // while the rows are filled, their check boxes changing is not the user turning an app on or off
    bool filling = false;
    bool done = false;
};

const PeSignInApp* AppAt(const AppsState& state, int row) {
    return row >= 0 ? pe_sign_in_app_list_get(state.apps.get(), static_cast<size_t>(row)) : nullptr;
}

const PeSignInApp* Selected(const AppsState& state) {
    return AppAt(state, ListView_GetNextItem(state.list, -1, LVNI_SELECTED));
}

// what the selected app is: why a built-in one may be off, an added one's client; Edit and Remove for added ones only
void ShowSelected(HWND hwnd, const AppsState& state) {
    const PeSignInApp* app = Selected(state);
    bool added = app && app->provider == PE_O_AUTH_PROVIDER_APP;
    EnableWindow(GetDlgItem(hwnd, IDC_APPS_EDIT), added);
    EnableWindow(GetDlgItem(hwnd, IDC_APPS_REMOVE), added);
    std::wstring note;
    if (app && !added) {
        note = Text(app->name) + L" is built in: only whether it is used for new accounts can change. ";
        note += app->enabled ? L"" : Text(app->off_reason);
    } else if (added) {
        note = L"Client ID: " + Text(app->client_id) + (app->has_secret ? L", with a client secret." : L", a public client (no secret).");
    }
    SetWindowTextW(GetDlgItem(hwnd, IDC_APPS_NOTE), note.c_str());
}

// a row per app, the built-in ones first, checked when it is on; `select` stays selected
void FillApps(HWND hwnd, AppsState& state, int select = 0) {
    state.filling = true;
    ListView_DeleteAllItems(state.list);
    state.apps.reset(pe_sign_in_apps(state.core));
    for (size_t i = 0; i < pe_sign_in_app_list_count(state.apps.get()); i++) {
        const PeSignInApp* app = pe_sign_in_app_list_get(state.apps.get(), i);
        bool builtin = app->provider != PE_O_AUTH_PROVIDER_APP;
        int row = AddRow(state.list, static_cast<int>(i), Text(app->name) + (builtin ? L" (built-in)" : L""));
        SetCell(state.list, row, APPS_ISSUER, Text(app->issuer));
        std::wstring usedBy = Text(app->used_by);
        SetCell(state.list, row, APPS_USED_BY, usedBy.empty() ? L"No accounts" : usedBy);
        ListView_SetCheckState(state.list, row, app->enabled);
    }
    SelectRow(state.list, select);
    state.filling = false;
    ShowSelected(hwnd, state);
}

// a check box changed: the app turned on or off for new accounts
void OnChecked(HWND hwnd, AppsState& state, int row) {
    const PeSignInApp* app = AppAt(state, row);
    bool on = ListView_GetCheckState(state.list, row);
    if (!app || app->enabled == on) {
        return;
    }
    pe_sign_in_app_set_enabled(state.core, app->provider, app->id, on);
    PostMessageW(hwnd, WM_REFILL, static_cast<WPARAM>(row), 0);
}

void OnAppsCommand(HWND hwnd, AppsState& state, WORD id) {
    int index = ListView_GetNextItem(state.list, -1, LVNI_SELECTED);
    const PeSignInApp* app = Selected(state);
    bool added = app && app->provider == PE_O_AUTH_PROVIDER_APP;
    switch (id) {
    case IDC_APPS_ADD:
        if (SignInAppEditor(hwnd, state.core, nullptr)) {
            FillApps(hwnd, state, static_cast<int>(pe_sign_in_app_list_count(state.apps.get())));
        }
        return;
    case IDC_APPS_EDIT:
        if (added && SignInAppEditor(hwnd, state.core, app)) {
            FillApps(hwnd, state, index);
        }
        return;
    case IDC_APPS_REMOVE: {
        if (!added) {
            return;
        }
        std::wstring question = L"Remove the sign-in app " + Text(app->name) + L" and its saved client secret?";
        if (MessageBoxW(hwnd, question.c_str(), L"Remove Sign-in App", MB_YESNO | MB_ICONWARNING | MB_DEFBUTTON2) != IDYES) {
            return;
        }
        char* error = nullptr;
        if (!pe_sign_in_app_remove(state.core, app->id, &error)) {
            core::String reason(error);
            std::wstring text = L"The sign-in app was not removed: " + (reason ? Text(reason.get()) : L"unknown reason");
            MessageBoxW(hwnd, text.c_str(), L"Remove Sign-in App", MB_OK | MB_ICONWARNING);
            return;
        }
        FillApps(hwnd, state, index);
        return;
    }
    case IDC_APPS_CLOSE:
    case IDCANCEL:
        state.done = true;
        return;
    }
}

LRESULT CALLBACK AppsProc(HWND hwnd, UINT message, WPARAM wParam, LPARAM lParam) {
    auto* state = reinterpret_cast<AppsState*>(GetWindowLongPtrW(hwnd, GWLP_USERDATA));
    switch (message) {
    case WM_COMMAND:
        if (state) {
            // Enter in the list is IDOK of the window: Edit of the selected app
            WORD id = LOWORD(wParam) == IDOK && GetFocus() == state->list ? IDC_APPS_EDIT : LOWORD(wParam);
            OnAppsCommand(hwnd, *state, id);
        }
        return 0;
    case WM_NOTIFY: {
        auto* header = reinterpret_cast<NMHDR*>(lParam);
        if (!state || header->hwndFrom != state->list || state->filling) {
            return 0;
        }
        if (header->code == LVN_ITEMCHANGED) {
            auto* change = reinterpret_cast<NMLISTVIEW*>(lParam);
            if ((change->uChanged & LVIF_STATE) && ((change->uNewState ^ change->uOldState) & LVIS_STATEIMAGEMASK)) {
                OnChecked(hwnd, *state, change->iItem);
            } else if ((change->uChanged & LVIF_STATE) && ((change->uNewState ^ change->uOldState) & LVIS_SELECTED)) {
                ShowSelected(hwnd, *state);
            }
        } else if (header->code == LVN_ITEMACTIVATE) {
            OnAppsCommand(hwnd, *state, IDC_APPS_EDIT);
        } else if (header->code == LVN_KEYDOWN && reinterpret_cast<NMLVKEYDOWN*>(lParam)->wVKey == VK_DELETE) {
            OnAppsCommand(hwnd, *state, IDC_APPS_REMOVE);
        }
        return 0;
    }
    case WM_REFILL:
        if (state) {
            FillApps(hwnd, *state, static_cast<int>(wParam));
        }
        return 0;
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

void SignInAppsDialog(HWND owner, PeCore* core) {
    RegisterDialogClass(kAppsClass, AppsProc);
    int pad = Scale(10), width = Scale(640), height = Scale(300);
    HWND dialog = CreateModalWindow(owner, kAppsClass, L"Sign-in Apps", width, height);
    AppsState state{core};
    int buttonWidth = Scale(100), listRight = width - pad - buttonWidth - pad;
    int top = pad;
    CreateChild(dialog, L"STATIC",
                L"Sign-in apps let accounts sign in through the browser. One that is not checked is not offered for new "
                L"accounts; the accounts that already use it keep working.",
                SS_LEFT | SS_NOPREFIX, 0, {pad, top, width - pad, top + Scale(30)});
    top += Scale(36);
    int noteTop = height - pad - Scale(25) - Scale(8) - Scale(32);
    state.list = CreateReportList(dialog, IDC_APPS_LIST, {pad, top, listRight, noteTop - Scale(8)});
    ListView_SetExtendedListViewStyleEx(state.list, LVS_EX_CHECKBOXES, LVS_EX_CHECKBOXES);
    AddColumn(state.list, APPS_NAME, L"Name", 200);
    AddColumn(state.list, APPS_ISSUER, L"Issuer", 160);
    AddColumn(state.list, APPS_USED_BY, L"Used by", 100);
    ListView_SetColumnWidth(state.list, APPS_USED_BY, LVSCW_AUTOSIZE_USEHEADER);
    struct Button {
        WORD id;
        const wchar_t* text;
    };
    Button buttons[] = {{IDC_APPS_ADD, L"&Add..."}, {IDC_APPS_EDIT, L"&Edit..."}, {IDC_APPS_REMOVE, L"&Remove"}};
    int buttonTop = top;
    for (const Button& button : buttons) {
        CreateChild(dialog, L"BUTTON", button.text, WS_TABSTOP, button.id,
                    {width - pad - buttonWidth, buttonTop, width - pad, buttonTop + Scale(25)});
        buttonTop += Scale(31);
    }
    CreateChild(dialog, L"STATIC", L"", SS_LEFT | SS_NOPREFIX, IDC_APPS_NOTE, {pad, noteTop, width - pad, noteTop + Scale(32)});
    CreateChild(dialog, L"BUTTON", L"Close", WS_TABSTOP | BS_DEFPUSHBUTTON, IDC_APPS_CLOSE,
                {width - pad - buttonWidth, height - pad - Scale(25), width - pad, height - pad});
    SetWindowLongPtrW(dialog, GWLP_USERDATA, reinterpret_cast<LONG_PTR>(&state));
    FillApps(dialog, state);
    RunModal(dialog, state.list, state.done);
}
