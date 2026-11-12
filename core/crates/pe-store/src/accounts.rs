//! Mail accounts: who the user is and where their servers are. Passwords and tokens are not
//! here, they live in the Windows Credential Manager.

use rusqlite::{Row, params};

use crate::{Result, Store};

pub type AccountId = i64;

/// How a connection is encrypted
#[derive(Debug, Clone, Copy, PartialEq, Eq, Default)]
pub enum Security {
    #[default]
    Tls,
    StartTls,
    Plain,
}

impl Security {
    /// The stored value, as a statement parameter
    pub(crate) fn as_sql(&self) -> &'static &'static str {
        match self {
            Security::Tls => &"tls",
            Security::StartTls => &"starttls",
            Security::Plain => &"plain",
        }
    }

    pub fn as_str(self) -> &'static str {
        self.as_sql()
    }

    /// Unknown values read as TLS, never as a weaker setting
    pub(crate) fn parse(value: &str) -> Security {
        match value {
            "starttls" => Security::StartTls,
            "plain" => Security::Plain,
            _ => Security::Tls,
        }
    }
}

/// How an account signs in
#[derive(Debug, Clone, PartialEq, Eq, Default)]
pub enum Auth {
    /// A password, the account's secret
    #[default]
    Password,
    /// OAuth 2.0 with this provider (`google`, `microsoft`, or `app:<id>` for a [`crate::SignInApp`]); the
    /// account's secret is the refresh token
    OAuth2(String),
}

/// The provider name of an account that signs in with the sign-in app `id`
pub fn app_provider(id: crate::SignInAppId) -> String {
    format!("app:{id}")
}

impl Auth {
    fn to_sql(&self) -> String {
        match self {
            Auth::Password => "password".into(),
            Auth::OAuth2(provider) => format!("oauth2:{provider}"),
        }
    }

    fn parse(value: &str) -> Auth {
        match value.strip_prefix("oauth2:") {
            Some(provider) => Auth::OAuth2(provider.to_string()),
            None => Auth::Password,
        }
    }
}

#[derive(Debug, Clone, PartialEq, Eq, Default)]
pub struct AccountSettings {
    /// The name the account shows under, `Work`
    pub name: String,
    pub email: String,
    pub username: String,
    pub imap_host: String,
    pub imap_port: u16,
    pub imap_security: Security,
    pub smtp_host: String,
    pub smtp_port: u16,
    pub smtp_security: Security,
    pub auth: Auth,
}

impl AccountSettings {
    #[cfg(test)]
    pub(crate) fn example(email: &str) -> Self {
        AccountSettings {
            name: email.into(),
            email: email.into(),
            username: email.into(),
            imap_host: "imap.example.com".into(),
            imap_port: 993,
            imap_security: Security::Tls,
            smtp_host: "smtp.example.com".into(),
            smtp_port: 465,
            smtp_security: Security::Tls,
            auth: Auth::Password,
        }
    }
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct Account {
    pub id: AccountId,
    pub settings: AccountSettings,
    /// The account's own name in the folder list ("Gmail", "Work"), set apart from the settings as the signature
    /// is; empty for the name on its mail (`pe_core::account_title`)
    pub account_name: String,
}

const COLUMNS: &str = "id, name, email, username, imap_host, imap_port, imap_security, smtp_host, smtp_port, smtp_security, auth, account_name";

fn from_row(row: &Row) -> rusqlite::Result<Account> {
    Ok(Account {
        id: row.get(0)?,
        settings: AccountSettings {
            name: row.get(1)?,
            email: row.get(2)?,
            username: row.get(3)?,
            imap_host: row.get(4)?,
            imap_port: row.get(5)?,
            imap_security: Security::parse(&row.get::<_, String>(6)?),
            smtp_host: row.get(7)?,
            smtp_port: row.get(8)?,
            smtp_security: Security::parse(&row.get::<_, String>(9)?),
            auth: Auth::parse(&row.get::<_, String>(10)?),
        },
        account_name: row.get(11)?,
    })
}

/// The settings as parameters ?1 to ?10, in the column order of the INSERT and the UPDATE
// a String, not a str: the parameter is a `&dyn ToSql`, and a str is not sized
#[allow(clippy::ptr_arg)]
fn settings_params<'a>(a: &'a AccountSettings, auth: &'a String) -> [&'a dyn rusqlite::ToSql; 10] {
    [
        &a.name,
        &a.email,
        &a.username,
        &a.imap_host,
        &a.imap_port,
        a.imap_security.as_sql(),
        &a.smtp_host,
        &a.smtp_port,
        a.smtp_security.as_sql(),
        auth,
    ]
}

impl Store {
    pub fn add_account(&self, account: &AccountSettings) -> Result<AccountId> {
        self.db.execute(
            "INSERT INTO accounts (name, email, username, imap_host, imap_port, imap_security, smtp_host, smtp_port, smtp_security, auth, position) \
             VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7, ?8, ?9, ?10, (SELECT COALESCE(MAX(position), 0) + 1 FROM accounts))",
            settings_params(account, &account.auth.to_sql()).as_slice(),
        )?;
        Ok(self.db.last_insert_rowid())
    }

    pub fn update_account(&self, id: AccountId, account: &AccountSettings) -> Result<()> {
        let auth = account.auth.to_sql();
        let mut params = settings_params(account, &auth).to_vec();
        params.push(&id);
        let changed = self.db.execute(
            "UPDATE accounts SET name = ?1, email = ?2, username = ?3, imap_host = ?4, imap_port = ?5, imap_security = ?6, \
             smtp_host = ?7, smtp_port = ?8, smtp_security = ?9, auth = ?10 WHERE id = ?11",
            params.as_slice(),
        )?;
        if changed == 0 {
            return Err(rusqlite::Error::QueryReturnedNoRows);
        }
        Ok(())
    }

    /// Sets the account's own name for the folder list; empty for the name on its mail
    pub fn set_account_name(&self, id: AccountId, name: &str) -> Result<()> {
        let changed = self.db.execute(
            "UPDATE accounts SET account_name = ?2 WHERE id = ?1",
            params![id, name.trim()],
        )?;
        if changed == 0 {
            return Err(rusqlite::Error::QueryReturnedNoRows);
        }
        Ok(())
    }

    /// The signature of an account, as the core sanitized it; empty for none
    pub fn signature(&self, id: AccountId) -> Result<String> {
        self.db
            .query_row("SELECT signature FROM accounts WHERE id = ?1", [id], |row| row.get(0))
    }

    pub fn set_signature(&self, id: AccountId, html: &str) -> Result<()> {
        let changed = self
            .db
            .execute("UPDATE accounts SET signature = ?2 WHERE id = ?1", params![id, html])?;
        if changed == 0 {
            return Err(rusqlite::Error::QueryReturnedNoRows);
        }
        Ok(())
    }

    /// Puts the account `id` at `index` in the accounts' order (0 first; past the end, last), the others keeping
    /// theirs around it
    pub fn move_account(&mut self, id: AccountId, index: usize) -> Result<()> {
        self.transaction(|store| {
            let mut order: Vec<AccountId> = store
                .db
                .prepare("SELECT id FROM accounts ORDER BY position, id")?
                .query_map([], |row| row.get(0))?
                .collect::<Result<_>>()?;
            let at = order
                .iter()
                .position(|&account| account == id)
                .ok_or(rusqlite::Error::QueryReturnedNoRows)?;
            order.remove(at);
            order.insert(index.min(order.len()), id);
            for (position, account) in order.iter().enumerate() {
                store.db.execute(
                    "UPDATE accounts SET position = ?2 WHERE id = ?1",
                    params![account, position + 1],
                )?;
            }
            Ok(())
        })
    }

    pub fn remove_account(&self, id: AccountId) -> Result<()> {
        self.db.execute("DELETE FROM accounts WHERE id = ?1", [id])?;
        Ok(())
    }

    pub fn accounts(&self) -> Result<Vec<Account>> {
        let mut statement = self
            .db
            .prepare(&format!("SELECT {COLUMNS} FROM accounts ORDER BY position, id"))?;
        statement.query_map([], from_row)?.collect()
    }

    pub fn account(&self, id: AccountId) -> Result<Account> {
        self.db
            .query_row(&format!("SELECT {COLUMNS} FROM accounts WHERE id = ?1"), [id], from_row)
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn accounts_keep_the_order_they_are_moved_to() {
        let mut store = Store::open_in_memory().unwrap();
        let ids: Vec<AccountId> = ["a", "b", "c"]
            .iter()
            .map(|name| {
                store
                    .add_account(&AccountSettings::example(&format!("{name}@example.com")))
                    .unwrap()
            })
            .collect();
        let order = |store: &Store| store.accounts().unwrap().iter().map(|a| a.id).collect::<Vec<_>>();
        assert_eq!(order(&store), ids);
        store.move_account(ids[2], 0).unwrap();
        assert_eq!(order(&store), vec![ids[2], ids[0], ids[1]]);
        store.move_account(ids[2], 99).unwrap();
        assert_eq!(order(&store), ids);
        // a new account comes last
        let d = store.add_account(&AccountSettings::example("d@example.com")).unwrap();
        store.move_account(ids[0], 1).unwrap();
        assert_eq!(order(&store), vec![ids[1], ids[0], ids[2], d]);
        assert!(store.move_account(999, 0).is_err());
    }

    #[test]
    fn accounts_round_trip() {
        let store = Store::open_in_memory().unwrap();
        let mut settings = AccountSettings::example("a@example.com");
        settings.imap_security = Security::StartTls;
        let id = store.add_account(&settings).unwrap();
        assert_eq!(store.account(id).unwrap().settings, settings);

        settings.name = "Work".into();
        settings.smtp_security = Security::Plain;
        settings.auth = Auth::OAuth2("google".into());
        store.update_account(id, &settings).unwrap();
        assert_eq!(
            store.accounts().unwrap(),
            vec![Account {
                id,
                settings: settings.clone(),
                account_name: String::new(),
            }]
        );
        // an account name of its own, trimmed, kept when the settings change
        store.set_account_name(id, " Gmail ").unwrap();
        store.update_account(id, &settings).unwrap();
        assert_eq!(store.account(id).unwrap().account_name, "Gmail");
        assert!(store.set_account_name(id + 1, "x").is_err());
        assert!(store.update_account(id + 1, &AccountSettings::example("x@y")).is_err());

        // a signature of its own, none to begin with, kept when the settings change
        assert_eq!(store.signature(id).unwrap(), "");
        store.set_signature(id, "<p>Ann</p>").unwrap();
        store.update_account(id, &settings).unwrap();
        assert_eq!(store.signature(id).unwrap(), "<p>Ann</p>");
        assert!(store.set_signature(id + 1, "x").is_err());

        store.remove_account(id).unwrap();
        assert!(store.account(id).is_err());
    }

    #[test]
    fn auth_round_trips() {
        for auth in [Auth::Password, Auth::OAuth2("microsoft".into())] {
            assert_eq!(Auth::parse(&auth.to_sql()), auth);
        }
        assert_eq!(Auth::parse("anything else"), Auth::Password);
    }

    #[test]
    fn unknown_security_is_tls() {
        assert_eq!(Security::parse("bogus"), Security::Tls);
        for security in [Security::Tls, Security::StartTls, Security::Plain] {
            assert_eq!(Security::parse(security.as_str()), security);
        }
    }
}
