//! Looking things up: the overview of the accounts, the message rules (read and tried, never changed: decision 1 of
//! the MCP plan), and people by the start of their name or address.

use pe_core::agents::everywhere;
use pe_store::{Scope, Search, Sort};
use serde_json::{Value, json};

use super::{Args, Call, Outcome, engine, row};

/// The most samples test_rule gives
const RULE_SAMPLES: u64 = 10;
/// The most people find_contacts gives
const MAX_PEOPLE: usize = 20;

pub(super) fn get_overview(call: &Call) -> Outcome {
    let accounts = call.core.agent_overview(&call.host).map_err(engine)?;
    let sum = |field: fn(&pe_core::agents::AccountOverview) -> u64| accounts.iter().map(field).sum::<u64>();
    let listed: Vec<Value> = accounts
        .iter()
        .map(|a| {
            json!({
                "account": a.account,
                "name": a.name,
                "email": a.email,
                "inbox": { "messages": a.counts.inbox, "unread": a.counts.inbox_unread },
                "flagged": a.counts.flagged,
                "drafts": a.counts.drafts,
                "outbox": a.outbox,
            })
        })
        .collect();
    Ok(json!({
        "accounts": listed,
        "all_inboxes": {
            "messages": sum(|a| a.counts.inbox),
            "unread": sum(|a| a.counts.inbox_unread),
        },
        "flagged": sum(|a| a.counts.flagged),
        "drafts": sum(|a| a.counts.drafts),
        "outbox": sum(|a| a.outbox),
    }))
}

pub(super) fn list_rules(call: &Call) -> Outcome {
    let rules: Vec<Value> = call
        .core
        .rules()
        .map_err(engine)?
        .into_iter()
        // a rule of every account's Inbox, or of one this agent may use
        .filter(|rule| rule.account.is_none_or(|account| call.host.accounts.contains(&account)))
        .map(|rule| {
            let move_to = rule
                .move_to
                .and_then(|folder| call.folder(folder).ok())
                .map(|folder| json!({ "folder": folder.id, "name": pe_core::folder_name(&folder.info) }));
            json!({
                "rule": rule.id,
                "name": rule.name,
                "enabled": rule.enabled,
                "account": rule.account,
                "query": rule.query,
                "mark_read": rule.mark_read,
                "flag": rule.flag,
                "archive": rule.archive,
                "junk": rule.junk,
                "delete": rule.remove,
                "not_announced": rule.quiet,
                "move_to": move_to,
            })
        })
        .collect();
    Ok(json!({
        "rules": rules,
        "note": "Rules run in this order on the new mail of an Inbox. Agents can read and test them (test_rule); only the user can change them."
    }))
}

pub(super) fn test_rule(call: &Call, args: &Args) -> Outcome {
    let query = args.string("query");
    if query.trim().is_empty() {
        return Err("`query` is empty.".into());
    }
    if let Some(problem) = call.core.rule_query_problem(&query) {
        return Ok(json!({ "query": query, "problem": problem, "matches": 0 }));
    }
    let scope = match args.opt_int("account") {
        Some(account) => {
            call.account(account)?;
            let inbox = call
                .core
                .folders(account)
                .map_err(engine)?
                .into_iter()
                .find(|f| f.info.path.eq_ignore_ascii_case("INBOX"))
                .ok_or("The account has no Inbox.")?;
            Scope::Folder(inbox.id)
        }
        None => Scope::AllInboxes,
    };
    let search = Search {
        scope,
        text: query.clone(),
        // as every search of an agent's: never by what only decrypting gives
        no_decrypted: true,
        ..everywhere(&call.host)
    };
    let (matches, _) = call.core.count_search(&search).map_err(engine)?;
    call.read("search", matches, &query, "")?;
    let samples = call
        .core
        .search(&search, Sort::default(), 0, RULE_SAMPLES)
        .map_err(engine)?;
    let places = call.places(&call.host.accounts)?;
    Ok(json!({
        "query": query,
        "matches": matches,
        "samples": samples.iter().map(|m| row(m, places.get(&m.folder_id), call.fence)).collect::<Vec<_>>(),
        "note": "Nothing was changed: this is what a rule with this query would find in the Inbox now."
    }))
}

pub(super) fn find_contacts(call: &Call, args: &Args) -> Outcome {
    let query = args.string("query");
    if query.trim().is_empty() {
        return Err("`query` is empty: give the start of a name or an address.".into());
    }
    let limit = args.size("limit", 10)?.clamp(1, MAX_PEOPLE);
    let (people, every) = call.core.agent_people(&call.host, &query, limit).map_err(engine)?;
    call.read("people", people.len() as u64, &query, "")?;
    let listed: Vec<Value> = people
        .iter()
        .map(|p| {
            json!({
                "name": call.fence.wrap(&p.name),
                "address": super::mail::address(&p.address),
                "in_address_book": p.in_book,
                "messages_sent": p.sent,
                "messages_received": p.received,
            })
        })
        .collect();
    let mut result = json!({ "people": listed });
    if !every {
        result["note"] = json!(
            "Only the address book: this agent may not use every account, and the people of mail are not kept by account."
        );
    }
    Ok(result)
}
