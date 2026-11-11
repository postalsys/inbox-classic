//! Sign-in apps: the built-in Google and Microsoft clients, and OAuth clients the user registered with any OpenID
//! Connect provider. Each can be turned off for new accounts; accounts that already sign in with one keep working.

use std::collections::HashMap;
use std::sync::{Arc, Mutex};

use pe_oauth::{Discovered, Endpoint, Provider, ProviderKind};
use pe_store::{AccountSettings, Security, SignInApp, SignInAppId, Store};

use crate::secrets::{Key, Secrets};
use crate::{Core, Error, Event, OAuthProviders, Result};

/// What a sign-in uses: a built-in client, or a sign-in app the user added
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum SignInWith {
    Builtin(ProviderKind),
    App(SignInAppId),
}

impl SignInWith {
    /// How an account that signs in with it names its provider ([`pe_store::Auth::OAuth2`])
    pub fn auth_name(self) -> String {
        match self {
            SignInWith::Builtin(kind) => kind.as_str().to_string(),
            SignInWith::App(id) => pe_store::app_provider(id),
        }
    }

    /// What an account's [`pe_store::Auth`] signs in with, None for a password
    pub fn of_auth_kind(auth: &pe_store::Auth) -> Option<SignInWith> {
        match auth {
            pe_store::Auth::OAuth2(name) => SignInWith::of_auth(name),
            pe_store::Auth::Password => None,
        }
    }

    pub fn of_auth(name: &str) -> Option<SignInWith> {
        match name.strip_prefix("app:") {
            Some(id) => id.parse().ok().map(SignInWith::App),
            None => ProviderKind::parse(name)
                .filter(|kind| *kind != ProviderKind::Oidc)
                .map(SignInWith::Builtin),
        }
    }
}

/// The accounts that sign in with `with`
fn signing_in_with(accounts: &[pe_store::Account], with: SignInWith) -> impl Iterator<Item = &pe_store::Account> {
    let auth = pe_store::Auth::OAuth2(with.auth_name());
    accounts.iter().filter(move |a| a.settings.auth == auth)
}

/// How to register a client with the provider of `issuer`, in the language in use: Google's and Microsoft's own
/// steps, or those for any OpenID Connect provider
pub fn register_hint(issuer: &str) -> String {
    pe_i18n::tr(match ProviderKind::of_issuer(issuer) {
        ProviderKind::Google => pe_i18n::Text::SignInRegisterGoogle,
        ProviderKind::Microsoft => pe_i18n::Text::SignInRegisterMicrosoft,
        ProviderKind::Oidc => pe_i18n::Text::SignInRegisterOther,
    })
}

/// The name a built-in client shows under
pub fn builtin_name(kind: ProviderKind) -> &'static str {
    match kind {
        ProviderKind::Google => "Inbox Classic for Google",
        ProviderKind::Microsoft => "Inbox Classic for Microsoft",
        ProviderKind::Oidc => "",
    }
}

/// Why a built-in client may be turned off, and what to do instead, in the language in use
pub fn builtin_off_text(kind: ProviderKind) -> String {
    match kind {
        ProviderKind::Google => pe_i18n::tr(pe_i18n::Text::SignInOffGoogle),
        _ => pe_i18n::tr(pe_i18n::Text::SignInOffOther),
    }
}

/// An issuer as the list shows it, as the built-in ones show their host: `https://` and a last `/` left out, `http://`
/// kept, as it says the sign-in is not encrypted
fn shown_issuer(issuer: &str) -> String {
    let issuer = issuer.trim_end_matches('/');
    issuer.strip_prefix("https://").unwrap_or(issuer).to_string()
}

/// A sign-in app as the manager lists it
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct SignInAppEntry {
    pub with: SignInWith,
    pub name: String,
    pub issuer: String,
    /// Offered for new accounts
    pub enabled: bool,
    /// The addresses of the accounts that sign in with it
    pub used_by: Vec<String>,
    /// What an added app was saved with; None for a built-in one
    pub app: Option<SignInApp>,
}

/// What the editor saves: everything of a sign-in app but its client secret
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct SignInAppForm {
    pub name: String,
    pub issuer: String,
    pub client_id: String,
    pub scopes: String,
    pub imap_host: String,
    pub imap_port: u16,
    pub imap_security: Security,
    pub smtp_host: String,
    pub smtp_port: u16,
    pub smtp_security: Security,
}

/// What happens to the client secret of an app being saved
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum SecretChange<'a> {
    Keep,
    Set(&'a str),
    Remove,
}

/// Discovery documents read for the editor's Check, by issuer: saving an app takes its endpoints from here
#[derive(Clone, Default)]
pub(crate) struct Discoveries(Arc<Mutex<HashMap<String, Discovered>>>);

impl Discoveries {
    fn get(&self, issuer: &str) -> Option<Discovered> {
        self.0.lock().unwrap_or_else(|p| p.into_inner()).get(issuer).cloned()
    }

    fn insert(&self, issuer: String, found: Discovered) {
        self.0.lock().unwrap_or_else(|p| p.into_inner()).insert(issuer, found);
    }
}

fn net_security(security: Security) -> pe_net::Security {
    match security {
        Security::Tls => pe_net::Security::Tls,
        Security::StartTls => pe_net::Security::StartTls,
        Security::Plain => pe_net::Security::Plain,
    }
}

/// The provider an app signs in to, with its client secret when it has one
pub(crate) fn app_provider(app: &SignInApp, secret: Option<String>) -> Provider {
    Provider {
        kind: ProviderKind::of_issuer(&app.issuer),
        imap: Endpoint {
            host: app.imap_host.clone(),
            port: app.imap_port,
            security: net_security(app.imap_security),
        },
        smtp: Endpoint {
            host: app.smtp_host.clone(),
            port: app.smtp_port,
            security: net_security(app.smtp_security),
        },
        authorize_url: app.authorize_url.clone(),
        token_url: app.token_url.clone(),
        scopes: app.scopes.split_whitespace().map(str::to_string).collect(),
        client_id: app.client_id.clone(),
        client_secret: secret.filter(|_| app.has_secret),
        response_issuer: app.response_issuer.clone(),
    }
}

impl OAuthProviders {
    /// The provider of an account that names it `name` in its [`pe_store::Auth::OAuth2`]
    pub(crate) fn resolve(&self, name: &str, store: &Store, secrets: &Secrets) -> Option<Provider> {
        match SignInWith::of_auth(name)? {
            SignInWith::Builtin(kind) => Some(self.provider(kind)),
            SignInWith::App(id) => {
                let app = store.sign_in_app(id).ok()?.app;
                // an app without a secret has nothing in the Credential Manager to look for
                let secret = app.has_secret.then(|| secrets.get(Key::App(id))).flatten();
                Some(app_provider(&app, secret))
            }
        }
    }
}

/// A host name or address as a server setting: not empty, no spaces or other characters a host has not
fn valid_host(host: &str) -> bool {
    !host.is_empty()
        && host
            .bytes()
            .all(|b| b.is_ascii_alphanumeric() || matches!(b, b'-' | b'.' | b':' | b'[' | b']'))
}

/// The form, checked, as the app to save: its endpoints from the discovery `found`
fn checked_app(form: &SignInAppForm, found: Discovered, has_secret: bool, enabled: bool) -> Result<SignInApp> {
    use pe_i18n::{Text, tr, tr_args};
    let invalid = |text: Text| Err(Error::Invalid(tr(text)));
    let text = |value: &str| value.trim().to_string();
    if form.name.trim().is_empty() {
        return invalid(Text::SignInAppNoName);
    }
    if form.client_id.trim().is_empty() || form.client_id.chars().any(char::is_control) {
        return invalid(Text::SignInAppNoClient);
    }
    let scopes = form.scopes.split_whitespace().collect::<Vec<_>>().join(" ");
    if scopes.is_empty() {
        return invalid(Text::SignInAppNoScopes);
    }
    for (what, host, port, security) in [
        ("IMAP", &form.imap_host, form.imap_port, form.imap_security),
        ("SMTP", &form.smtp_host, form.smtp_port, form.smtp_security),
    ] {
        if !valid_host(host.trim()) || port == 0 {
            return Err(Error::Invalid(tr_args(
                Text::SignInAppBadHost,
                &[("server", what.into())],
            )));
        }
        // the access token goes to these servers: never without encryption
        if security == Security::Plain {
            return Err(Error::Invalid(tr_args(
                Text::SignInAppPlain,
                &[("server", what.into())],
            )));
        }
    }
    Ok(SignInApp {
        name: text(&form.name),
        issuer: pe_oauth::issuer(&form.issuer).map_err(Error::Invalid)?,
        client_id: text(&form.client_id),
        has_secret,
        scopes,
        authorize_url: found.authorize_url,
        token_url: found.token_url,
        response_issuer: found.response_issuer,
        imap_host: text(&form.imap_host),
        imap_port: form.imap_port,
        imap_security: form.imap_security,
        smtp_host: text(&form.smtp_host),
        smtp_port: form.smtp_port,
        smtp_security: form.smtp_security,
        enabled,
    })
}

impl Core {
    /// The sign-in apps: the built-in Microsoft and Google clients first, then the added ones by name
    pub fn sign_in_apps(&self) -> Result<Vec<SignInAppEntry>> {
        let store = self.store();
        let accounts = store.accounts()?;
        let used_by = |with: SignInWith| {
            signing_in_with(&accounts, with)
                .map(|a| a.settings.email.clone())
                .collect::<Vec<_>>()
        };
        let mut entries = Vec::new();
        for kind in [ProviderKind::Microsoft, ProviderKind::Google] {
            let with = SignInWith::Builtin(kind);
            entries.push(SignInAppEntry {
                with,
                name: builtin_name(kind).to_string(),
                issuer: pe_net::http::parse_url(&self.oauth.provider(kind).authorize_url)
                    .map(|url| url.host)
                    .unwrap_or_default(),
                enabled: store.builtin_sign_in_enabled(kind.as_str())?,
                used_by: used_by(with),
                app: None,
            });
        }
        for stored in store.sign_in_apps()? {
            let with = SignInWith::App(stored.id);
            entries.push(SignInAppEntry {
                with,
                name: stored.app.name.clone(),
                issuer: shown_issuer(&stored.app.issuer),
                enabled: stored.app.enabled,
                used_by: used_by(with),
                app: Some(stored.app),
            });
        }
        Ok(entries)
    }

    /// Whether a sign-in app is offered for new accounts
    pub fn sign_in_enabled(&self, with: SignInWith) -> Result<bool> {
        let store = self.store();
        Ok(match with {
            SignInWith::Builtin(kind) => store.builtin_sign_in_enabled(kind.as_str())?,
            SignInWith::App(id) => store.sign_in_app(id)?.app.enabled,
        })
    }

    /// Turns a sign-in app on or off for new accounts; accounts that use it keep working either way
    pub fn set_sign_in_enabled(&self, with: SignInWith, enabled: bool) -> Result<()> {
        let store = self.store();
        match with {
            SignInWith::Builtin(ProviderKind::Oidc) => Err(Error::NotFound),
            SignInWith::Builtin(kind) => Ok(store.set_builtin_sign_in_enabled(kind.as_str(), enabled)?),
            SignInWith::App(id) => Ok(store.set_sign_in_app_enabled(id, enabled)?),
        }
    }

    /// Reads the discovery document of `issuer` in the background, for the editor's Check and before saving:
    /// [`Event::SignInAppChecked`] with the request follows. Refused at once when the issuer is no address to read
    /// it from.
    pub fn sign_in_app_check(&self, issuer: &str) -> Result<u64> {
        let issuer = pe_oauth::issuer(issuer).map_err(Error::Invalid)?;
        let request = self.next_request.fetch_add(1, std::sync::atomic::Ordering::Relaxed);
        let discoveries = self.discoveries.clone();
        let work = async move {
            let found = pe_oauth::discover(&issuer).await?;
            discoveries.insert(issuer, found.clone());
            Ok(found)
        };
        self.checks
            .start(self.runtime()?, request, work, self.events.clone(), |request| {
                Event::SignInAppChecked { request }
            });
        Ok(request)
    }

    /// What a check found, taken: the endpoints, or why the issuer can not be used; None while it runs
    pub fn sign_in_app_check_result(&self, request: u64) -> Option<std::result::Result<Discovered, String>> {
        self.checks.take(request)
    }

    pub fn sign_in_app_check_cancel(&self, request: u64) {
        self.checks.cancel(request);
    }

    /// Saves a sign-in app, new (`id` None, turned on) or changed, once its issuer was checked
    /// ([`Core::sign_in_app_check`]). The accounts that sign in with a changed one move to its servers.
    pub fn save_sign_in_app(
        &self,
        id: Option<SignInAppId>,
        form: &SignInAppForm,
        secret: SecretChange,
    ) -> Result<SignInAppId> {
        let issuer = pe_oauth::issuer(&form.issuer).map_err(Error::Invalid)?;
        let found = self
            .discoveries
            .get(&issuer)
            .ok_or_else(|| Error::Invalid(pe_i18n::tr(pe_i18n::Text::SignInAppNotChecked)))?;
        let before = id.map(|id| self.store().sign_in_app(id)).transpose()?.map(|s| s.app);
        let has_secret = match secret {
            SecretChange::Set(value) => !value.is_empty(),
            SecretChange::Remove => false,
            SecretChange::Keep => before.as_ref().is_some_and(|app| app.has_secret),
        };
        // a secret saved for one issuer is not sent to another one's token endpoint
        if secret == SecretChange::Keep
            && before
                .as_ref()
                .is_some_and(|app| app.has_secret && app.issuer != issuer)
        {
            return Err(Error::Invalid(pe_i18n::tr(pe_i18n::Text::SignInAppIssuerChanged)));
        }
        let enabled = before.as_ref().is_none_or(|app| app.enabled);
        let app = checked_app(form, found, has_secret, enabled)?;
        let id = match id {
            Some(id) => {
                self.store().update_sign_in_app(id, &app)?;
                id
            }
            None => self.store().add_sign_in_app(&app)?,
        };
        match secret {
            SecretChange::Set(value) if !value.is_empty() => {
                self.secrets.set(Key::App(id), value).map_err(Error::Unavailable)?
            }
            SecretChange::Set(_) | SecretChange::Remove => self.secrets.remove(Key::App(id)),
            SecretChange::Keep => {}
        }
        if before.is_some() {
            self.move_accounts_to(id, &app)?;
        }
        Ok(id)
    }

    /// The accounts of app `id` at its servers, their workers started again with them
    fn move_accounts_to(&self, id: SignInAppId, app: &SignInApp) -> Result<()> {
        let with = SignInWith::App(id);
        let auth = pe_store::Auth::OAuth2(with.auth_name());
        let provider = app_provider(app, None);
        let store = self.store();
        for account in signing_in_with(&store.accounts()?, with) {
            store.update_account(account.id, &with_provider(&account.settings, &provider, &auth))?;
            self.stop_worker(account.id);
        }
        Ok(())
    }

    /// Removes a sign-in app and its secret; refused while accounts sign in with it
    pub fn remove_sign_in_app(&self, id: SignInAppId) -> Result<()> {
        let accounts = self.store().accounts()?;
        let used_by: Vec<String> = signing_in_with(&accounts, SignInWith::App(id))
            .map(|a| a.settings.email.clone())
            .collect();
        if !used_by.is_empty() {
            return Err(Error::InUse(used_by));
        }
        self.store().remove_sign_in_app(id)?;
        self.secrets.remove(Key::App(id));
        Ok(())
    }

    /// The name of what an account that names its provider `auth` signs in with: a built-in client's, or a sign-in
    /// app's; None for a password, or an app that is not there
    pub fn sign_in_name(&self, auth: &pe_store::Auth) -> Option<String> {
        match SignInWith::of_auth_kind(auth)? {
            SignInWith::Builtin(kind) => Some(builtin_name(kind).to_string()),
            SignInWith::App(id) => self.store().sign_in_app(id).ok().map(|s| s.app.name),
        }
    }

    /// The provider a sign-in with `with` goes to
    pub(crate) fn sign_in_provider(&self, with: SignInWith) -> Result<Provider> {
        self.oauth
            .resolve(&with.auth_name(), &self.store(), &self.secrets)
            .ok_or(Error::NotFound)
    }
}

/// The settings of an account at `provider`'s servers that signs in as `auth` says
pub(crate) fn with_provider(settings: &AccountSettings, provider: &Provider, auth: &pe_store::Auth) -> AccountSettings {
    AccountSettings {
        imap_host: provider.imap.host.clone(),
        imap_port: provider.imap.port,
        imap_security: crate::store_security(provider.imap.security),
        smtp_host: provider.smtp.host.clone(),
        smtp_port: provider.smtp.port,
        smtp_security: crate::store_security(provider.smtp.security),
        auth: auth.clone(),
        ..settings.clone()
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    fn form() -> SignInAppForm {
        SignInAppForm {
            name: " Acme ".into(),
            issuer: "https://login.example.com/".into(),
            client_id: "client".into(),
            scopes: " openid  mail ".into(),
            imap_host: "imap.example.com".into(),
            imap_port: 993,
            imap_security: Security::Tls,
            smtp_host: "smtp.example.com".into(),
            smtp_port: 587,
            smtp_security: Security::StartTls,
        }
    }

    fn found() -> Discovered {
        Discovered {
            authorize_url: "https://login.example.com/authorize".into(),
            token_url: "https://login.example.com/token".into(),
            response_issuer: None,
        }
    }

    #[test]
    fn forms_are_checked() {
        let app = checked_app(&form(), found(), false, true).unwrap();
        assert_eq!(
            (app.name.as_str(), app.issuer.as_str(), app.scopes.as_str()),
            ("Acme", "https://login.example.com", "openid mail")
        );
        type Change = fn(&mut SignInAppForm);
        let refused: [(Change, &str); 6] = [
            (|f| f.name = " ".into(), "name"),
            (|f| f.client_id = String::new(), "client ID"),
            (|f| f.scopes = "  ".into(), "scopes"),
            (|f| f.imap_host = "imap example".into(), "IMAP server"),
            (|f| f.smtp_port = 0, "SMTP server"),
            (|f| f.smtp_security = Security::Plain, "STARTTLS"),
        ];
        for (change, reason) in refused {
            let mut form = form();
            change(&mut form);
            let error = checked_app(&form, found(), false, true).unwrap_err().to_string();
            assert!(error.contains(reason), "{error}");
        }
    }

    #[test]
    fn sign_in_with_names() {
        for with in [
            SignInWith::Builtin(ProviderKind::Google),
            SignInWith::Builtin(ProviderKind::Microsoft),
            SignInWith::App(7),
        ] {
            assert_eq!(SignInWith::of_auth(&with.auth_name()), Some(with));
        }
        assert_eq!(SignInWith::of_auth("oidc"), None);
        assert_eq!(SignInWith::of_auth("app:x"), None);
    }

    #[test]
    fn app_providers() {
        let mut app = checked_app(&form(), found(), true, true).unwrap();
        let provider = app_provider(&app, Some("s".into()));
        assert_eq!(provider.kind, ProviderKind::Oidc);
        assert_eq!(provider.scopes, ["openid", "mail"]);
        assert_eq!(provider.client_secret.as_deref(), Some("s"));
        assert_eq!(provider.smtp.security, pe_net::Security::StartTls);
        // a secret left behind is not sent for an app that has none
        app.has_secret = false;
        assert_eq!(app_provider(&app, Some("s".into())).client_secret, None);
        app.issuer = "https://accounts.google.com".into();
        assert_eq!(app_provider(&app, None).kind, ProviderKind::Google);
    }

    #[test]
    fn issuers_listed_as_hosts() {
        assert_eq!(shown_issuer("https://login.example.com/"), "login.example.com");
        assert_eq!(
            shown_issuer("https://idp.example.com/realms/mail"),
            "idp.example.com/realms/mail"
        );
        assert_eq!(shown_issuer("http://127.0.0.1:60837"), "http://127.0.0.1:60837");
    }

    #[test]
    fn register_hint_by_issuer() {
        use pe_i18n::{Text, tr};
        assert_eq!(
            register_hint("https://login.microsoftonline.com/contoso/v2.0"),
            tr(Text::SignInRegisterMicrosoft)
        );
        assert_eq!(
            register_hint("https://accounts.google.com"),
            tr(Text::SignInRegisterGoogle)
        );
        assert_eq!(register_hint("https://sso.example.edu"), tr(Text::SignInRegisterOther));
    }
}
