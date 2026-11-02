//! Providers that take an app password rather than the account password for IMAP and SMTP, known by the domain of
//! the address or by its mail exchange. Ported from EmailEngine (`getAppPasswords` in
//! lib/autodetect-imap-settings.js), in the same order.

/// A hint for the account form: the provider wants an app password
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct AppPassword {
    /// The provider's name, `Gmail`
    pub provider: &'static str,
    /// The provider's page on how to make one
    pub instructions: &'static str,
    /// Something to show instead of, or before, the instructions
    pub warning: Option<&'static str>,
}

/// How a provider is known: by the domain of the address, or by the end of its exchange
struct Trigger {
    domains: &'static [&'static str],
    exchange: Option<fn(&str) -> bool>,
    hint: AppPassword,
}

const MICROSOFT_WARNING: &str = "Microsoft has disabled password-based sign-ins (including app passwords) for Outlook.com, Hotmail.com, and Microsoft 365 email accounts. To continue, please use the \"Sign in with Microsoft\" button to securely connect your account.";

const TABLE: &[Trigger] = &[
    Trigger {
        domains: &["gmail.com", "googlemail.com"],
        exchange: Some(|ex| {
            ex.strip_suffix("l.google.com")
                .is_some_and(|rest| !rest.ends_with(|c: char| c.is_ascii_alphanumeric() || c == '_'))
        }),
        hint: AppPassword {
            provider: "Gmail",
            instructions: "https://support.google.com/accounts/answer/185833",
            warning: None,
        },
    },
    Trigger {
        domains: &["icloud.com", "me.com", "mac.com"],
        exchange: Some(|ex| ex.ends_with(".icloud.com")),
        hint: AppPassword {
            provider: "iCloud",
            instructions: "https://support.apple.com/en-us/HT204397",
            warning: None,
        },
    },
    Trigger {
        domains: &["aol.com"],
        exchange: None,
        hint: AppPassword {
            provider: "AOL",
            instructions: "https://help.aol.com/articles/Create-and-manage-app-password",
            warning: None,
        },
    },
    Trigger {
        domains: &["yahoo.com"],
        exchange: Some(|ex| ex.ends_with(".yahoodns.net")),
        hint: AppPassword {
            provider: "Yahoo",
            instructions: "https://help.yahoo.com/kb/SLN15241.html",
            warning: None,
        },
    },
    Trigger {
        domains: &["outlook.com", "hotmail.com", "live.com"],
        exchange: Some(|ex| ex.ends_with(".outlook.com")),
        hint: AppPassword {
            provider: "Microsoft",
            instructions: "https://support.microsoft.com/en-us/account-billing/how-to-get-and-use-app-passwords-5896ed9b-4263-e681-128a-a6f2979a7944",
            warning: Some(MICROSOFT_WARNING),
        },
    },
    Trigger {
        domains: &["t-online.de"],
        exchange: Some(|ex| ex.ends_with(".t-online.de")),
        hint: AppPassword {
            provider: "T-Online",
            instructions: "https://www.telekom.de/hilfe/apps-dienste/e-mail/programme/passwort-definition",
            warning: None,
        },
    },
];

/// The app password hint for `email`, by its domain or by `exchange`, the mail exchange of its domain
pub fn app_password(email: &str, exchange: Option<&str>) -> Option<AppPassword> {
    let domain = crate::domain_of(email).unwrap_or_else(|| {
        let raw = email.rsplit_once('@').map(|(_, d)| d).unwrap_or_default();
        raw.trim().to_lowercase()
    });
    let exchange = exchange.map(|ex| ex.trim().trim_end_matches('.').to_ascii_lowercase());
    TABLE.iter().find_map(|trigger| {
        let by_domain = trigger.domains.contains(&domain.as_str());
        let by_exchange = matches!((&exchange, trigger.exchange), (Some(ex), Some(test)) if test(ex));
        (by_domain || by_exchange).then_some(trigger.hint)
    })
}

#[cfg(test)]
mod tests {
    use super::*;

    fn provider(email: &str, exchange: Option<&str>) -> Option<&'static str> {
        app_password(email, exchange).map(|hint| hint.provider)
    }

    // EmailEngine getAppPassword
    #[test]
    fn by_domain() {
        let aol = app_password("user@aol.com", Some("whatever.example.com")).unwrap();
        assert_eq!(aol.provider, "AOL");
        assert_eq!(provider("User@AOL.COM", None), Some("AOL"));
        for (email, name) in [
            ("user@gmail.com", "Gmail"),
            ("user@googlemail.com", "Gmail"),
            ("user@icloud.com", "iCloud"),
            ("user@me.com", "iCloud"),
            ("user@mac.com", "iCloud"),
            ("user@outlook.com", "Microsoft"),
            ("user@hotmail.com", "Microsoft"),
            ("user@live.com", "Microsoft"),
            ("user@t-online.de", "T-Online"),
        ] {
            assert_eq!(provider(email, None), Some(name), "{email}");
        }
    }

    #[test]
    fn by_exchange() {
        assert_eq!(
            provider("user@customdomain.com", Some("mx01.mail.icloud.com")),
            Some("iCloud")
        );
        assert_eq!(
            provider("user@customdomain.com", Some("mta5.am0.yahoodns.net")),
            Some("Yahoo")
        );
        assert_eq!(
            provider("user@customdomain.com", Some("gmail-smtp-in.l.google.com")),
            Some("Gmail")
        );
        assert_eq!(
            provider("user@customdomain.com", Some("mx00.t-online.de")),
            Some("T-Online")
        );
        let microsoft = app_password(
            "user@customdomain.com",
            Some("customdomain.mail.protection.outlook.com"),
        )
        .unwrap();
        assert_eq!(microsoft.provider, "Microsoft");
        assert!(microsoft.warning.unwrap().contains("password-based sign-ins"));
        assert_eq!(app_password("user@example.com", Some("mx.example.com")), None);
        assert_eq!(app_password("user@example.com", None), None);
        assert_eq!(app_password("no address", None), None);
    }
}
