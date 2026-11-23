//! The bar over a message of a mailing list: what it says and its button, decided here once for the three apps. It
//! names the list by a domain only, never by a name the sender chose (List-Id's phrase, From's name), so a message can
//! not make the app's own bar speak for someone else: the domain whose signature the provider confirmed for a one-click
//! list, else List-Id's, else the sender's, and only when it reads as a host name. Once the user asked the list to let
//! them go, the bar says when; a message that came more than two days after a request (the time RFC 8058 gives a
//! sender) offers it again, since the list did not stop.

use pe_i18n::{Text, tr, tr_args};
use pe_mime::parser::{Message, ParsedAddress};
use pe_store::{AccountId, Asked, Store};

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

/// What the bar is decided from, besides the list
#[derive(Debug, Clone, Copy, Default)]
pub(crate) struct Facts<'a> {
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
    /// The list of `message`, whose provider's verdicts `trusted` names
    pub(crate) fn of(message: &Message, trusted: &crate::authres::Verifiers) -> List {
        let how = unsubscribe::of(&message.headers, trusted);
        if how.is_none() {
            return List::default();
        }
        List {
            how,
            key: list_key(message),
            domain: domain(message, trusted),
        }
    }
}

/// The bar of a message of `account` with `list`, from what `store` remembers of the list: the one way both the view
/// and the bar read again after [`crate::Event::ListsChanged`] decide it
pub(crate) fn bar_in(store: &Store, account: AccountId, list: &List, facts: Facts) -> Option<ListBar> {
    let asked = list
        .key
        .as_ref()
        .and_then(|key| store.unsubscribed(account, key).ok().flatten());
    bar(list, Facts { asked, ..facts })
}

/// The bar of a message of `list`, None when it has none
pub(crate) fn bar(list: &List, facts: Facts) -> Option<ListBar> {
    list.how.as_ref()?;
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
            text: match &list.domain {
                Some(domain) => tr_args(Text::UiListBar, &[("domain", domain.as_str().into())]),
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

/// The list a message is of, as its requests are remembered: List-Id's identifier as the store keeps it
/// (`messages.list_id`), else the sender's address
pub(crate) fn list_key(message: &Message) -> Option<String> {
    list_id(message)
        .or_else(|| sender(message).map(|address| address.to_lowercase()))
        .filter(|key| !key.is_empty())
}

/// The domain the bar names: the confirmed signer of a one-click list, else List-Id's, else the sender's; None when the
/// candidate does not read as a host name
pub(crate) fn domain(message: &Message, trusted: &crate::authres::Verifiers) -> Option<String> {
    let candidate = unsubscribe::signer(&message.headers, trusted)
        .or_else(|| list_id(message))
        .or_else(|| sender(message).and_then(|address| address.rsplit_once('@').map(|(_, host)| host.to_string())))?;
    host_name(&candidate)
}

/// The identifier of List-Id (RFC 2919), as pe-sync reads it for the store
fn list_id(message: &Message) -> Option<String> {
    pe_sync::list_id(header(&message.headers, "list-id").next()?)
}

/// The address of From, None for a From that is no single address
fn sender(message: &Message) -> Option<String> {
    match &message.from {
        Some(ParsedAddress::Mailbox(from)) if from.address.contains('@') => Some(from.address.clone()),
        _ => None,
    }
}

/// `text` as a host name the bar shows: one DNS accepts (pe-autoconfig's rule), of at least two labels and not longer
/// than the bar shows. Anything else (spaces, controls, direction marks, letters of other scripts that may look like
/// Latin ones) is not shown at all.
fn host_name(text: &str) -> Option<String> {
    pe_autoconfig::dns::host_name(text).filter(|host| host.len() <= LONGEST_DOMAIN && host.contains('.'))
}

#[cfg(test)]
mod tests {
    use super::*;

    fn headers(text: &str) -> Message {
        let source = format!("{text}\r\nSubject: x\r\n\r\nbody\r\n");
        pe_mime::parser::parse(source.as_bytes()).unwrap()
    }

    static TRUSTED: &crate::authres::Verifiers = &crate::authres::NONE;

    fn trusted() -> crate::authres::Verifiers {
        crate::authres::Verifiers::named(&["example.net"])
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
        // List-Id read as the store reads it for `messages.list_id`, so the two always agree
        assert_eq!(
            list_key(&headers("List-Id: News <News.Example.COM>")),
            pe_sync::list_id(" News <News.Example.COM>")
        );
    }

    /// Shown where it may be, nothing else known
    fn here() -> Facts<'static> {
        Facts {
            shown_here: true,
            ..Default::default()
        }
    }

    #[test]
    fn each_state_says_its_words() {
        let list = List::of(&headers(SIGNED), &trusted());
        let offered = bar(&list, here()).unwrap();
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
                &list,
                Facts {
                    asked: Some((asked, asked_at)),
                    arrived: Some(arrived),
                    ..here()
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
            &list,
            Facts {
                failed: Some("The list answered 500"),
                ..here()
            },
        )
        .unwrap();
        assert!(failed.text.contains("The list answered 500"));
        assert_eq!(failed.button, tr(Text::UiTryAgain));
    }

    #[test]
    fn no_bar_without_a_way_or_in_junk_sent_and_drafts() {
        // the list of a message without a way to leave it is nothing to remember, and has no bar
        let none = List::of(&headers("List-Id: <a.example.com>"), TRUSTED);
        assert_eq!(none, List::default());
        assert_eq!(bar(&none, here()), None);
        let list = List::of(
            &headers("List-Unsubscribe: <https://list.example.com/u/1>\r\nFrom: News <news@list.example.com>"),
            TRUSTED,
        );
        assert_eq!(
            bar(
                &list,
                Facts {
                    shown_here: false,
                    ..here()
                }
            ),
            None
        );
        // no host name to name: the bar still offers it, without one
        let nameless = List {
            domain: None,
            ..list.clone()
        };
        assert_eq!(bar(&nameless, here()).unwrap().text, tr(Text::UiListBarPlain));
        let list = List::of(&headers(SIGNED), &trusted());
        assert_eq!(list.key.as_deref(), Some("weekly.list.example.com"));
        assert_eq!(list.domain.as_deref(), Some("mail.list.example.com"));
    }
}
