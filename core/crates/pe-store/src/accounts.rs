//! Mail accounts: who the user is and where their servers are. Passwords and tokens are not
//! here, they live in the Windows Credential Manager.

use rusqlite::Row;

use crate::{Result, Store};

pub type AccountId = i64;

/// How a connection is encrypted
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum Security {
    Tls,
    StartTls,
    Plain,
}

impl Security {
    /// The stored value, as a statement parameter
    fn as_sql(&self) -> &'static &'static str {
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
    fn parse(value: &str) -> Security {
        match value {
            "starttls" => Security::StartTls,
            "plain" => Security::Plain,
            _ => Security::Tls,
        }
    }
}

#[derive(Debug, Clone, PartialEq, Eq)]
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
        }
    }
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct Account {
    pub id: AccountId,
    pub settings: AccountSettings,
}

const COLUMNS: &str =
    "id, name, email, username, imap_host, imap_port, imap_security, smtp_host, smtp_port, smtp_security";

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
        },
    })
}

/// The settings as parameters ?1 to ?9, in the column order of the INSERT and the UPDATE
fn settings_params(a: &AccountSettings) -> [&dyn rusqlite::ToSql; 9] {
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
    ]
}

impl Store {
    pub fn add_account(&self, account: &AccountSettings) -> Result<AccountId> {
        self.db.execute(
            "INSERT INTO accounts (name, email, username, imap_host, imap_port, imap_security, smtp_host, smtp_port, smtp_security) \
             VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7, ?8, ?9)",
            settings_params(account).as_slice(),
        )?;
        Ok(self.db.last_insert_rowid())
    }

    pub fn update_account(&self, id: AccountId, account: &AccountSettings) -> Result<()> {
        let mut params = settings_params(account).to_vec();
        params.push(&id);
        let changed = self.db.execute(
            "UPDATE accounts SET name = ?1, email = ?2, username = ?3, imap_host = ?4, imap_port = ?5, imap_security = ?6, \
             smtp_host = ?7, smtp_port = ?8, smtp_security = ?9 WHERE id = ?10",
            params.as_slice(),
        )?;
        if changed == 0 {
            return Err(rusqlite::Error::QueryReturnedNoRows);
        }
        Ok(())
    }

    pub fn remove_account(&self, id: AccountId) -> Result<()> {
        self.db.execute("DELETE FROM accounts WHERE id = ?1", [id])?;
        Ok(())
    }

    pub fn accounts(&self) -> Result<Vec<Account>> {
        let mut statement = self
            .db
            .prepare(&format!("SELECT {COLUMNS} FROM accounts ORDER BY id"))?;
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
    fn accounts_round_trip() {
        let store = Store::open_in_memory().unwrap();
        let mut settings = AccountSettings::example("a@example.com");
        settings.imap_security = Security::StartTls;
        let id = store.add_account(&settings).unwrap();
        assert_eq!(store.account(id).unwrap().settings, settings);

        settings.name = "Work".into();
        settings.smtp_security = Security::Plain;
        store.update_account(id, &settings).unwrap();
        assert_eq!(store.accounts().unwrap(), vec![Account { id, settings }]);
        assert!(store.update_account(id + 1, &AccountSettings::example("x@y")).is_err());

        store.remove_account(id).unwrap();
        assert!(store.account(id).is_err());
    }

    #[test]
    fn unknown_security_is_tls() {
        assert_eq!(Security::parse("bogus"), Security::Tls);
        for security in [Security::Tls, Security::StartTls, Security::Plain] {
            assert_eq!(Security::parse(security.as_str()), security);
        }
    }
}
