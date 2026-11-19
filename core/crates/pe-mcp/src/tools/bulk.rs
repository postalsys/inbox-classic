//! Changes of many messages at once and taking changes back: apply_to_search (decision 5 of the MCP plan: a dry run
//! with the count, a few samples and a token bound to that moment, then one call with the token that changes exactly
//! those messages, logged as one entry with one Undo All) and undo_my_change (an agent takes back one of its own
//! changes, never another program's).

use pe_core::agents::{BULK_MAX, BulkAction, BulkPreview, TICKET_SECONDS};
use pe_store::FlagColor;
use serde_json::{Value, json};

use super::organize::COLORS;
use super::{Args, Call, Outcome, engine, row};

/// The actions apply_to_search takes
pub(super) const ACTIONS: [&str; 10] = [
    "mark_read",
    "mark_unread",
    "flag",
    "unflag",
    "flag_color",
    "move",
    "archive",
    "junk",
    "not_junk",
    "delete",
];

/// The action an apply_to_search call names, with its colour or folder
fn action(call: &Call, args: &Args) -> Result<BulkAction, String> {
    Ok(match args.string("action").as_str() {
        "mark_read" => BulkAction::Read,
        "mark_unread" => BulkAction::Unread,
        "flag" => BulkAction::Flag,
        "unflag" => BulkAction::Unflag,
        "flag_color" => {
            let color = FlagColor::from_id(&args.string("color"))
                .ok_or_else(|| format!("`color` is one of {} for flag_color.", COLORS[..7].join(", ")))?;
            BulkAction::Color(color)
        }
        "move" => BulkAction::Move(call.folder(args.int("to_folder")?)?.id),
        "archive" => BulkAction::Archive,
        "junk" => BulkAction::Junk,
        "not_junk" => BulkAction::NotJunk,
        "delete" => BulkAction::Delete,
        _ => return Err(format!("`action` is one of {}.", ACTIONS.join(", "))),
    })
}

/// What the agent is told of a dry run
fn preview_answer(call: &Call, query: &str, preview: &BulkPreview) -> Result<Value, String> {
    if preview.too_many {
        return Ok(json!({
            "dry_run": true,
            "matches": preview.count,
            "note": format!(
                "One call changes at most {BULK_MAX} messages, and this one would change more. Narrow the query \
                 (in:, before:, from:) and run the dry run again. Nothing was changed."
            ),
        }));
    }
    let places = call.places(&call.host.accounts)?;
    let mut samples = Vec::new();
    for at in &preview.samples {
        if let Ok(message) = call.message(at.folder, at.uid) {
            samples.push(row(&message, places.get(&at.folder), call.fence));
        }
    }
    let note = match &preview.ticket {
        Some(_) => format!(
            "Nothing was changed yet. Call apply_to_search again with only this token, within {} minutes, to recheck \
             these {} messages and change those still eligible, excluding later arrivals. The token works once.",
            TICKET_SECONDS / 60,
            preview.count
        ),
        None => "The action would change none of the messages the query finds. Nothing was changed.".into(),
    };
    Ok(json!({
        "dry_run": true,
        "query": query,
        "matches": preview.count,
        "unchanged": preview.unchanged,
        "samples": samples,
        "token": preview.ticket,
        "expires_in_seconds": preview.ticket.as_ref().map(|_| TICKET_SECONDS),
        "note": note,
    }))
}

pub(super) async fn apply_to_search(call: &Call<'_>, args: &Args<'_>) -> Outcome {
    let token = args.string("token");
    if !token.is_empty() {
        if args.flag("dry_run", false) {
            return Err("A dry run takes no token: give `dry_run` without `token`, or `token` alone.".into());
        }
        let done = call
            .core
            .agent_bulk_apply(&call.host, &token, Some(call.call_id))
            .await
            .map_err(engine)?;
        return Ok(json!({
            "done": true,
            "changed": done.changed,
            "left_alone": done.left,
            "change_id": done.entry,
            "note": "The user can try to undo this entry in Inbox Classic, and the agent with undo_my_change and this \
                     change_id. Messages that no longer met the action conditions were skipped. Undo can be partial.",
        }));
    }
    let query = args.string("query");
    if query.trim().is_empty() {
        return Err("`query` is empty: give a search, as search_messages takes it, and `dry_run` true.".into());
    }
    let account = args.opt_int("account");
    if let Some(account) = account {
        call.account(account)?;
    }
    let action = action(call, args)?;
    let preview = call
        .core
        .agent_bulk_preview(&call.host, &query, account, action)
        .map_err(engine)?;
    call.read("search", preview.count, &query, "")?;
    preview_answer(call, &query, &preview)
}

pub(super) fn undo_my_change(call: &Call, args: &Args) -> Outcome {
    let id = args.int("change_id")?;
    let report = call.core.agent_undo_own(call.host.id, id).map_err(|error| {
        if super::missing(&error) {
            format!("There is no change {id} of this agent's. The answers of its changes give their change_ids.")
        } else {
            engine(error)
        }
    })?;
    Ok(json!({
        "undone": true,
        "messages_taken_back": report.undone,
        "no_longer_where_left": report.gone,
        "changed_since": report.changed,
        "already_sent": report.sent,
        "note": "Undo checks the state relevant to each action and can be partial. Removing a flag can also remove a \
                 color changed later. For sending entries, already_sent counts messages no longer in the Outbox, \
                 including messages removed without sending; it does not confirm delivery.",
    }))
}

#[cfg(test)]
mod tests {
    #[test]
    fn every_action_is_named() {
        assert_eq!(super::ACTIONS.len(), 10);
        assert!(super::ACTIONS.contains(&"delete") && !super::ACTIONS.iter().any(|a| a.contains("forever")));
    }
}
