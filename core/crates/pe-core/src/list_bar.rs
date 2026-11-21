//! The bar over a message of a mailing list: what it says and its button, decided here once for the three apps. It
//! names the list by a domain only, never by a name the sender chose (List-Id's phrase, From's name), so a message can
//! not make the app's own bar speak for someone else: the domain whose signature the provider confirmed for a one-click
//! list, else List-Id's, else the sender's, and only when it reads as a host name. Once the user asked the list to let
//! them go, the bar says when; a message that came more than two days after a request (the time RFC 8058 gives a
//! sender) offers it again, since the list did not stop.

use pe_i18n::{Text, tr, tr_args};
use pe_mime::parser::Header;
use pe_store::Asked;

use crate::authres::headers as header;
use crate::unsubscribe::{self, Unsubscribe};

/// How long a list may take to stop after a request before its messages show that it did not
pub const GRACE_SECONDS: i64 = 2 * 24 * 60 * 60;

/// The longest domain the bar shows
const LONGEST_DOMAIN: usize = 80;

/// What the bar over a message says, and its button
#[derive(Debug, Clone, PartialEq, Eq, Default)]
pub struct ListBar {
    pub text: String,
    /// Empty when the bar has no button (the list was asked and the message came before it could stop)
    pub button: String,
}

/// What the bar is decided from
#[derive(Debug, Clone, Copy, Default)]
pub(crate) struct Facts<'a> {
    pub how: Option<&'a Unsubscribe>,
    /// The folder may show it: not Junk E-mail (leaving confirms the address to a spammer), Sent Items or Drafts
    pub shown_here: bool,
    /// When and how its list was asked, for a message of an account
    pub asked: Option<(Asked, i64)>,
    /// When the message arrived
    pub arrived: Option<i64>,
    /// Why the last one-click request of its list failed, this session
    pub failed: Option<&'a str>,
}

/// The list of a message as its view keeps it: how to leave it, the list it is ([`list_key`]) and the domain the bar
/// names ([`domain`])
#[derive(Debug, Clone, PartialEq, Eq, Default)]
pub struct List {
    pub how: Option<Unsubscribe>,
    pub key: Option<String>,
    pub domain: Option<String>,
}

impl List {
    /// The list of a message with `headers`, whose provider's verdicts `trusted` names
    pub(crate) fn of(headers: &[Header], trusted: &[String]) -> List {
        let how = unsubscribe::of(headers, trusted);
        if how.is_none() {
            return List::default();
        }
        List {
            how,
            key: list_key(headers),
            domain: domain(headers, trusted),
        }
    }
}

/// The bar of a message whose list names `domain`, None when it has none
pub(crate) fn bar(domain: Option<&str>, facts: Facts) -> Option<ListBar> {
    facts.how?;
    if !facts.shown_here {
        return None;
    }
    let ask = tr(Text::UiUnsubscribeAsk);
    if let Some(reason) = facts.failed {
        return Some(ListBar {
            text: tr_args(Text::UiListBarFailed, &[("reason", reason.into())]),
            button: tr(Text::UiTryAgain),
        });
    }
    let on = |at: i64| crate::calendar::local_date(at);
    Some(match facts.asked {
        None => ListBar {
            text: match domain {
                Some(domain) => tr_args(Text::UiListBar, &[("domain", domain.into())]),
                None => tr(Text::UiListBarPlain),
            },
            button: ask,
        },
        Some((Asked::Web, at)) => ListBar {
            text: tr_args(Text::UiListBarOpened, &[("date", on(at).as_str().into())]),
            button: ask,
        },
        Some((_, at)) if facts.arrived.is_some_and(|arrived| arrived > at + GRACE_SECONDS) => ListBar {
            text: tr_args(Text::UiListBarCameAfter, &[("date", on(at).as_str().into())]),
            button: tr(Text::UiUnsubscribeAgain),
        },
        Some((_, at)) => ListBar {
            text: tr_args(Text::UiListBarAsked, &[("date", on(at).as_str().into())]),
            button: String::new(),
        },
    })
}

/// The list a message is of, as its requests are remembered: List-Id's identifier, else the sender's address
pub(crate) fn list_key(headers: &[Header]) -> Option<String> {
    list_id(headers)
        .or_else(|| sender(headers))
        .map(|key| key.to_ascii_lowercase())
        .filter(|key| !key.is_empty())
}

/// The domain the bar names: the confirmed signer of a one-click list, else List-Id's, else the sender's; None when the
/// candidate does not read as a host name
pub(crate) fn domain(headers: &[Header], trusted: &[String]) -> Option<String> {
    let candidate = unsubscribe::signer(headers, trusted)
        .or_else(|| list_id(headers))
        .or_else(|| sender(headers).and_then(|address| address.rsplit_once('@').map(|(_, host)| host.to_string())))?;
    host_name(&candidate)
}

/// The identifier of List-Id (RFC 2919): what is in angle brackets, else the whole value
fn list_id(headers: &[Header]) -> Option<String> {
    let value = header(headers, "list-id").next()?;
    let id = match value.rsplit_once('<') {
        Some((_, rest)) => rest.split_once('>').map_or(rest, |(id, _)| id),
        None => value,
    };
    Some(id.trim().to_string()).filter(|id| !id.is_empty())
}

/// The address of From
fn sender(headers: &[Header]) -> Option<String> {
    let from = header(headers, "from").next()?;
    let address = match from.rsplit_once('<') {
        Some((_, rest)) => rest.split_once('>').map_or(rest, |(address, _)| address),
        None => from,
    };
    Some(address.trim().to_string()).filter(|address| address.contains('@'))
}

/// `text` lowercased when it is a host name: ASCII letters, digits and hyphens in labels between dots, at least two
/// labels, none empty or starting or ending with a hyphen, not longer than the bar shows. Anything else (spaces,
/// controls, direction marks, letters of other scripts that may look like Latin ones) is not shown at all.
fn host_name(text: &str) -> Option<String> {
    let host = text.trim().trim_end_matches('.').to_ascii_lowercase();
    let labels: Vec<&str> = host.split('.').collect();
    let fine = host.len() <= LONGEST_DOMAIN
        && labels.len() >= 2
        && labels.iter().all(|label| {
            !label.is_empty()
                && !label.starts_with('-')
                && !label.ends_with('-')
                && label.bytes().all(|b| b.is_ascii_alphanumeric() || b == b'-')
        });
    fine.then_some(host)
}

#[cfg(test)]
mod tests {
    use super::*;

    fn headers(text: &str) -> Vec<Header> {
        let source = format!("{text}\r\nSubject: x\r\n\r\nbody\r\n");
        pe_mime::parser::parse(source.as_bytes()).unwrap().headers
    }

    const TRUSTED: &[String] = &[];

    fn trusted() -> Vec<String> {
        vec!["example.net".to_string()]
    }

    const SIGNED: &str = "Authentication-Results: mx.example.net; dkim=pass header.d=mail.list.example.com\r\n\
        DKIM-Signature: v=1; d=mail.list.example.com; s=s1; h=from:list-unsubscribe:list-unsubscribe-post; bh=x; b=y\r\n\
        From: Weekly <news@sender.example.org>\r\n\
        List-Id: Your Bank Security <weekly.list.example.com>\r\n\
        List-Unsubscribe: <https://list.example.com/u/1>\r\n\
        List-Unsubscribe-Post: List-Unsubscribe=One-Click";

    #[test]
    fn the_domain_is_the_signer_then_list_id_then_the_sender() {
        assert_eq!(
            domain(&headers(SIGNED), &trusted()).as_deref(),
            Some("mail.list.example.com")
        );
        // unsigned: List-Id's identifier, never its phrase
        assert_eq!(
            domain(&headers(SIGNED), TRUSTED).as_deref(),
            Some("weekly.list.example.com")
        );
        let no_list_id = SIGNED.replace("List-Id: Your Bank Security <weekly.list.example.com>\r\n", "");
        assert_eq!(
            domain(&headers(&no_list_id), TRUSTED).as_deref(),
            Some("sender.example.org")
        );
        assert_eq!(
            domain(&headers("List-Id: <News.Example.COM.>"), TRUSTED).as_deref(),
            Some("news.example.com")
        );
        assert_eq!(
            domain(&headers("List-Id: bare.example.com"), TRUSTED).as_deref(),
            Some("bare.example.com")
        );
    }

    #[test]
    fn only_a_host_name_is_shown() {
        for bad in [
            "List-Id: <Your Bank>",
            "List-Id: <localhost>",
            "List-Id: <-bad.example.com>",
            "List-Id: <a..example.com>",
            "List-Id: <exa\u{0430}mple.com>",
            "List-Id: <example.com\u{202e}moc>",
            "List-Id: <bank.example.com evil>",
        ] {
            assert_eq!(domain(&headers(bad), TRUSTED), None, "{bad}");
        }
        let long = format!("List-Id: <{}.example.com>", "a".repeat(LONGEST_DOMAIN));
        assert_eq!(domain(&headers(&long), TRUSTED), None);
    }

    #[test]
    fn the_list_is_its_id_else_its_sender() {
        assert_eq!(list_key(&headers(SIGNED)).as_deref(), Some("weekly.list.example.com"));
        assert_eq!(
            list_key(&headers("From: \"Shop\" <Deals@Shop.example>")).as_deref(),
            Some("deals@shop.example")
        );
        assert_eq!(list_key(&headers("X-Other: 1")), None);
    }

    fn facts(how: &Unsubscribe) -> Facts<'_> {
        Facts {
            how: Some(how),
            shown_here: true,
            ..Default::default()
        }
    }

    #[test]
    fn each_state_says_its_words() {
        let how = Unsubscribe::OneClick {
            url: "https://list.example.com/u/1".into(),
        };
        let domain = domain(&headers(SIGNED), &trusted());
        let domain = domain.as_deref();
        let offered = bar(domain, facts(&how)).unwrap();
        assert_eq!(
            offered.text,
            tr_args(Text::UiListBar, &[("domain", "mail.list.example.com".into())])
        );
        assert!(!offered.text.contains("Bank"), "no sender-chosen words");
        assert_eq!(offered.button, tr(Text::UiUnsubscribeAsk));

        let day = 86_400;
        let asked_at = 100 * day;
        let asked = |arrived: i64, asked: Asked| {
            bar(
                domain,
                Facts {
                    asked: Some((asked, asked_at)),
                    arrived: Some(arrived),
                    ..facts(&how)
                },
            )
            .unwrap()
        };
        // came before the request, or within the grace: when it was asked, nothing to press
        for arrived in [asked_at - day, asked_at + day, asked_at + GRACE_SECONDS] {
            let shown = asked(arrived, Asked::OneClick);
            assert!(shown.button.is_empty(), "{arrived}");
            assert_eq!(
                shown.text,
                tr_args(
                    Text::UiListBarAsked,
                    &[("date", crate::calendar::local_date(asked_at).as_str().into())]
                )
            );
        }
        // after it: the list did not stop
        let after = asked(asked_at + GRACE_SECONDS + 1, Asked::Mail);
        assert_eq!(after.button, tr(Text::UiUnsubscribeAgain));
        // a page opened may not have finished: the button stays
        let opened = asked(asked_at + day, Asked::Web);
        assert_eq!(opened.button, tr(Text::UiUnsubscribeAsk));
        assert!(opened.text.contains(&crate::calendar::local_date(asked_at)));
        // a request that failed says why and is tried again
        let failed = bar(
            domain,
            Facts {
                failed: Some("The list answered 500"),
                ..facts(&how)
            },
        )
        .unwrap();
        assert!(failed.text.contains("The list answered 500"));
        assert_eq!(failed.button, tr(Text::UiTryAgain));
    }

    #[test]
    fn no_bar_without_a_way_or_in_junk_sent_and_drafts() {
        let how = Unsubscribe::Web {
            url: "https://list.example.com/u/1".into(),
        };
        assert_eq!(bar(Some("list.example.com"), Facts::default()), None);
        assert_eq!(
            bar(
                Some("list.example.com"),
                Facts {
                    shown_here: false,
                    ..facts(&how)
                }
            ),
            None
        );
        // no host name to name: the bar still offers it, without one
        assert_eq!(bar(None, facts(&how)).unwrap().text, tr(Text::UiListBarPlain));
        // the list of a message without a way to leave it is nothing to remember
        assert_eq!(List::of(&headers("List-Id: <a.example.com>"), TRUSTED), List::default());
        let list = List::of(&headers(SIGNED), &trusted());
        assert_eq!(list.key.as_deref(), Some("weekly.list.example.com"));
        assert_eq!(list.domain.as_deref(), Some("mail.list.example.com"));
    }
}
