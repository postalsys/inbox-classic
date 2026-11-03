//! Sign-in apps: OAuth clients the user registered with an OpenID Connect provider, and whether each is offered for
//! new accounts, the two built-in clients included. Their secrets are not here, they live in the Credential Manager.

use rusqlite::{OptionalExtension, Row};

use crate::{Result, Security, Store};

pub type SignInAppId = i64;

#[derive(Debug, Clone, PartialEq, Eq, Default)]
pub struct SignInApp {
    /// What the user calls it, `Acme Gmail Access`
    pub name: String,
    pub issuer: String,
    pub client_id: String,
    /// Whether it has a client secret (kept in the Credential Manager)
    pub has_secret: bool,
    /// Separated by spaces, as the authorization request sends them
    pub scopes: String,
    pub authorize_url: String,
    pub token_url: String,
    /// The `iss` its redirects carry (RFC 9207), when its discovery document says it sends one
    pub response_issuer: Option<String>,
    pub imap_host: String,
    pub imap_port: u16,
    pub imap_security: Security,
    pub smtp_host: String,
    pub smtp_port: u16,
    pub smtp_security: Security,
    /// Offered for new accounts; accounts that already use it keep working either way
    pub enabled: bool,
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct StoredSignInApp {
    pub id: SignInAppId,
    pub app: SignInApp,
}

const COLUMNS: &str = "id, name, issuer, client_id, has_secret, scopes, authorize_url, token_url, response_issuer, \
                       imap_host, imap_port, imap_security, smtp_host, smtp_port, smtp_security, enabled";

fn from_row(row: &Row) -> rusqlite::Result<StoredSignInApp> {
    Ok(StoredSignInApp {
        id: row.get(0)?,
        app: SignInApp {
            name: row.get(1)?,
            issuer: row.get(2)?,
            client_id: row.get(3)?,
            has_secret: row.get(4)?,
            scopes: row.get(5)?,
            authorize_url: row.get(6)?,
            token_url: row.get(7)?,
            response_issuer: row.get(8)?,
            imap_host: row.get(9)?,
            imap_port: row.get(10)?,
            imap_security: Security::parse(&row.get::<_, String>(11)?),
            smtp_host: row.get(12)?,
            smtp_port: row.get(13)?,
            smtp_security: Security::parse(&row.get::<_, String>(14)?),
            enabled: row.get(15)?,
        },
    })
}

/// The app as parameters ?1 to ?15, in the column order of the INSERT and the UPDATE
fn params(app: &SignInApp) -> [&dyn rusqlite::ToSql; 15] {
    [
        &app.name,
        &app.issuer,
        &app.client_id,
        &app.has_secret,
        &app.scopes,
        &app.authorize_url,
        &app.token_url,
        &app.response_issuer,
        &app.imap_host,
        &app.imap_port,
        app.imap_security.as_sql(),
        &app.smtp_host,
        &app.smtp_port,
        app.smtp_security.as_sql(),
        &app.enabled,
    ]
}

/// The settings key of a built-in client's switch
fn builtin_key(provider: &str) -> String {
    format!("sign_in.{provider}")
}

impl Store {
    pub fn sign_in_apps(&self) -> Result<Vec<StoredSignInApp>> {
        let mut statement = self.db.prepare(&format!(
            "SELECT {COLUMNS} FROM sign_in_apps ORDER BY name COLLATE NOCASE, id"
        ))?;
        statement.query_map([], from_row)?.collect()
    }

    pub fn sign_in_app(&self, id: SignInAppId) -> Result<StoredSignInApp> {
        self.db.query_row(
            &format!("SELECT {COLUMNS} FROM sign_in_apps WHERE id = ?1"),
            [id],
            from_row,
        )
    }

    pub fn add_sign_in_app(&self, app: &SignInApp) -> Result<SignInAppId> {
        self.db.execute(
            "INSERT INTO sign_in_apps (name, issuer, client_id, has_secret, scopes, authorize_url, token_url, \
             response_issuer, imap_host, imap_port, imap_security, smtp_host, smtp_port, smtp_security, enabled) \
             VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7, ?8, ?9, ?10, ?11, ?12, ?13, ?14, ?15)",
            params(app).as_slice(),
        )?;
        Ok(self.db.last_insert_rowid())
    }

    pub fn update_sign_in_app(&self, id: SignInAppId, app: &SignInApp) -> Result<()> {
        let mut values = params(app).to_vec();
        values.push(&id);
        let changed = self.db.execute(
            "UPDATE sign_in_apps SET name = ?1, issuer = ?2, client_id = ?3, has_secret = ?4, scopes = ?5, \
             authorize_url = ?6, token_url = ?7, response_issuer = ?8, imap_host = ?9, imap_port = ?10, \
             imap_security = ?11, smtp_host = ?12, smtp_port = ?13, smtp_security = ?14, enabled = ?15 WHERE id = ?16",
            values.as_slice(),
        )?;
        if changed == 0 {
            return Err(rusqlite::Error::QueryReturnedNoRows);
        }
        Ok(())
    }

    pub fn remove_sign_in_app(&self, id: SignInAppId) -> Result<()> {
        self.db.execute("DELETE FROM sign_in_apps WHERE id = ?1", [id])?;
        Ok(())
    }

    pub fn set_sign_in_app_enabled(&self, id: SignInAppId, enabled: bool) -> Result<()> {
        let changed = self
            .db
            .execute("UPDATE sign_in_apps SET enabled = ?1 WHERE id = ?2", (enabled, id))?;
        if changed == 0 {
            return Err(rusqlite::Error::QueryReturnedNoRows);
        }
        Ok(())
    }

    /// Whether the built-in client of `provider` (`google`, `microsoft`) is offered for new accounts
    pub fn builtin_sign_in_enabled(&self, provider: &str) -> Result<bool> {
        let value: Option<String> = self
            .db
            .query_row(
                "SELECT value FROM settings WHERE key = ?1",
                [builtin_key(provider)],
                |row| row.get(0),
            )
            .optional()?;
        Ok(value.as_deref() == Some("1"))
    }

    pub fn set_builtin_sign_in_enabled(&self, provider: &str, enabled: bool) -> Result<()> {
        self.db.execute(
            "INSERT INTO settings (key, value) VALUES (?1, ?2) ON CONFLICT (key) DO UPDATE SET value = excluded.value",
            (builtin_key(provider), if enabled { "1" } else { "0" }),
        )?;
        Ok(())
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    fn example() -> SignInApp {
        SignInApp {
            name: "Acme".into(),
            issuer: "https://login.example.com".into(),
            client_id: "client".into(),
            has_secret: false,
            scopes: "openid email mail".into(),
            authorize_url: "https://login.example.com/authorize".into(),
            token_url: "https://login.example.com/token".into(),
            response_issuer: None,
            imap_host: "imap.example.com".into(),
            imap_port: 993,
            imap_security: Security::Tls,
            smtp_host: "smtp.example.com".into(),
            smtp_port: 587,
            smtp_security: Security::StartTls,
            enabled: true,
        }
    }

    #[test]
    fn sign_in_apps_round_trip() {
        let store = Store::open_in_memory().unwrap();
        let mut app = example();
        let id = store.add_sign_in_app(&app).unwrap();
        assert_eq!(store.sign_in_app(id).unwrap().app, app);
        app.name = "Acme Mail".into();
        app.has_secret = true;
        app.response_issuer = Some("https://login.example.com".into());
        store.update_sign_in_app(id, &app).unwrap();
        assert_eq!(store.sign_in_apps().unwrap(), vec![StoredSignInApp { id, app }]);
        store.set_sign_in_app_enabled(id, false).unwrap();
        assert!(!store.sign_in_app(id).unwrap().app.enabled);
        assert!(store.update_sign_in_app(id + 1, &example()).is_err());
        assert!(store.set_sign_in_app_enabled(id + 1, true).is_err());
        store.remove_sign_in_app(id).unwrap();
        assert!(store.sign_in_app(id).is_err());
        // an id is never given out again, so nothing of a removed app can come back with a new one
        assert!(store.add_sign_in_app(&example()).unwrap() > id);
    }

    #[test]
    fn built_in_clients_start_with_microsoft_on_and_google_off() {
        let store = Store::open_in_memory().unwrap();
        assert!(store.builtin_sign_in_enabled("microsoft").unwrap());
        assert!(!store.builtin_sign_in_enabled("google").unwrap());
        store.set_builtin_sign_in_enabled("google", true).unwrap();
        store.set_builtin_sign_in_enabled("microsoft", false).unwrap();
        assert!(store.builtin_sign_in_enabled("google").unwrap());
        assert!(!store.builtin_sign_in_enabled("microsoft").unwrap());
        assert!(!store.builtin_sign_in_enabled("unknown").unwrap());
    }
}
