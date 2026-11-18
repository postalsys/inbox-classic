//! The lists of messages: a folder or a scope of several accounts, by message or by conversation; a conversation
//! read whole; and what came since a cursor. Every list is of the accounts the program may use, counted in the store.

use std::collections::HashMap;
use std::time::Instant;

use pe_core::agents::everywhere;
use pe_store::{FolderId, Scope, Search, Show, Sort};
use serde_json::{Value, json};

use super::{
    Args, Call, DOWNLOAD_WAIT, Outcome, PROGRESS_EVERY, Place, UNTRUSTED, engine, part, read_fields, row, scope,
};

/// The most messages of a conversation get_conversation gives: the newest
const CONVERSATION_MESSAGES: usize = 30;
/// About the most characters of text a conversation's answer carries, all its messages together
const CONVERSATION_TEXT: usize = 60_000;
/// The most people a conversation's row names
const PARTICIPANTS: usize = 10;

/// What list_messages and list_changes list: a folder of an account this agent may use, or a scope of every account
/// it may use; and the folders' places, for the rows
fn listed(call: &Call, args: &Args) -> Result<(Scope, HashMap<FolderId, Place>), String> {
    match (args.opt_int("folder"), args.0.get("scope").and_then(Value::as_str)) {
        (Some(folder), None) => {
            let folder = call.folder(folder)?;
            Ok((
                Scope::Folder(folder.id),
                HashMap::from([(folder.id, Place::of(&folder))]),
            ))
        }
        (None, Some(name)) => Ok((scope(name)?, call.places(&call.host.accounts)?)),
        (None, None) => Ok((Scope::Everywhere, call.places(&call.host.accounts)?)),
        (Some(_), Some(_)) => Err("Give `folder` or `scope`, not both.".into()),
    }
}

pub(super) fn list_messages(call: &Call, args: &Args) -> Outcome {
    if args.opt_int("folder").is_none() && !args.0.contains_key("scope") {
        return Err("Give `folder` (list_folders) or `scope` (all_inboxes, all_sent, all_drafts or flagged).".into());
    }
    let (scope, places) = listed(call, args)?;
    let (offset, limit) = args.page();
    let grouped = args.flag("group_by_conversation", false);
    let search = Search {
        scope,
        show: if args.flag("unread_only", false) {
            Show::Unread
        } else {
            Show::All
        },
        threads: grouped.then(Vec::new),
        // only what this agent may see, counted in the store
        ..everywhere(&call.host)
    };
    let rows = call
        .core
        .search(&search, Sort::default(), offset, limit)
        .map_err(engine)?;
    let (messages, unread) = call.core.count_search(&search).map_err(engine)?;
    let (total, key, listed) = if grouped {
        let total = call.core.count_rows(&search).map_err(engine)?;
        (
            total,
            "conversations",
            conversation_rows(call, &search, &rows, &places)?,
        )
    } else {
        let listed = rows
            .iter()
            .map(|m| row(m, places.get(&m.folder_id), call.fence))
            .collect();
        (messages, "messages", listed)
    };
    let named = match scope {
        Scope::Folder(folder) => places.get(&folder).map(|p| p.name.clone()),
        _ => args.0.get("scope").and_then(Value::as_str).map(str::to_string),
    };
    call.read("list", rows.len() as u64, &named.unwrap_or_default(), "")?;
    let mut result = json!({
        "total": total,
        "unread": unread,
        "offset": offset,
        "has_more": offset + (rows.len() as u64) < total,
    });
    if let Scope::Folder(folder) = scope {
        result["folder"] = json!(folder);
        result["name"] = json!(places.get(&folder).map(|p| p.name.as_str()));
    }
    result[key] = json!(listed);
    if grouped {
        result["messages"] = json!(messages);
    }
    Ok(result)
}

/// The rows of a list grouped by conversation: each its first message's row, with how many messages the
/// conversation has in the list, how many are unread, who wrote, and its latest date (the store gives the collapsed
/// row the newest message's)
fn conversation_rows(
    call: &Call,
    search: &Search,
    rows: &[pe_store::Message],
    places: &HashMap<FolderId, Place>,
) -> Result<Vec<Value>, String> {
    let threads: Vec<i64> = rows.iter().filter_map(|m| m.thread.map(|t| t.thread)).collect();
    let senders = call
        .core
        .thread_senders(search, &threads, PARTICIPANTS)
        .map_err(engine)?;
    Ok(rows
        .iter()
        .map(|message| {
            let mut fields = row(message, places.get(&message.folder_id), call.fence);
            let place = message.thread.unwrap_or_default();
            let people: Vec<String> = senders
                .get(&place.thread)
                .map(|people| {
                    people
                        .iter()
                        .map(|(name, address)| pe_core::address_label(name, address))
                        .collect()
                })
                .unwrap_or_default();
            fields["count"] = json!(place.count.max(1));
            fields["unread_count"] = json!(place.unread);
            fields["participants"] = call.fence.wrap_all(&people);
            fields["latest_date"] = fields["date"].take();
            fields
        })
        .collect())
}

/// Asks for the sources of `messages` not downloaded yet, all at once: those it asked for
fn ask_downloads(call: &Call, messages: &[pe_store::Message]) -> Result<Vec<(FolderId, u64)>, String> {
    let missing: Vec<(FolderId, u64)> = messages
        .iter()
        .filter(|m| !m.cached)
        .map(|m| (m.folder_id, m.info.uid))
        .collect();
    for &(folder, uid) in &missing {
        call.core.open_message(folder, uid).map_err(engine)?;
    }
    Ok(missing)
}

pub(super) async fn get_conversation(call: &Call<'_>, args: &Args<'_>) -> Outcome {
    let thread = args.int("thread")?;
    let mut messages = call.core.agent_conversation(&call.host, thread).map_err(engine)?;
    if messages.is_empty() {
        return Err(format!(
            "There is no conversation {thread} in the accounts this agent may use. Message rows name theirs as `thread`."
        ));
    }
    let left_out = messages.len().saturating_sub(CONVERSATION_MESSAGES);
    messages.drain(..left_out);
    // the ones not downloaded yet, asked for at once and waited for together
    let mut missing = ask_downloads(call, &messages)?;
    let deadline = Instant::now() + DOWNLOAD_WAIT;
    let mut told = Instant::now();
    while !missing.is_empty() && Instant::now() < deadline {
        tokio::time::sleep(std::time::Duration::from_millis(250)).await;
        missing.retain(|&(folder, uid)| !call.message(folder, uid).is_ok_and(|m| m.cached));
        if told.elapsed() >= PROGRESS_EVERY {
            told = Instant::now();
            call.progress
                .report(&format!("Downloading {} messages of the conversation", missing.len()));
        }
    }
    let places = call.places(&call.host.accounts)?;
    let first = messages
        .first()
        .map(|m| m.agent_subject().to_string())
        .unwrap_or_default();
    // the newest first while the text lasts, so the oldest are the ones left without
    let mut budget = CONVERSATION_TEXT;
    let mut read: Vec<Value> = Vec::with_capacity(messages.len());
    for mut summary in messages.into_iter().rev() {
        summary.info.subject = summary.agent_subject().to_string();
        let place = places.get(&summary.folder_id);
        let Some(message) = call
            .core
            .agent_message(summary.folder_id, summary.info.uid)
            .map_err(engine)?
        else {
            let mut fields = super::row_fields(&summary, place, call.fence);
            fields.insert("text_not_downloaded".into(), json!(true));
            read.push(Value::Object(fields));
            continue;
        };
        let mut fields = read_fields(&summary, place, &message, call.fence);
        let written = call.fence.links(&message.written);
        let (text, more) = part(&written, 0, budget);
        budget -= text.chars().count();
        if more.is_some() {
            fields.insert("text_cut".into(), json!(true));
        }
        fields.insert("text".into(), call.fence.wrap(&text));
        if !message.earlier.is_empty() {
            fields.insert("earlier_messages_left_out".into(), json!(true));
        }
        read.push(Value::Object(fields));
    }
    read.reverse();
    call.read("conversation", read.len() as u64, &first, "")?;
    Ok(json!({
        "thread": thread,
        "notice": UNTRUSTED,
        "left_out": left_out,
        "messages": read,
    }))
}

pub(super) fn list_changes(call: &Call, args: &Args) -> Outcome {
    let (scope, places) = listed(call, args)?;
    // the bound first: whatever is stored while this reads comes in the next answer
    let newest = call.core.newest_message().map_err(engine)?;
    let Some(since) = args.opt_int("since") else {
        return Ok(json!({
            "next_cursor": newest,
            "note": "Nothing is listed without `since`: call again with this next_cursor to get what comes after now."
        }));
    };
    let (_, limit) = args.page();
    let search = Search {
        scope,
        up_to: Some(newest),
        ..everywhere(&call.host)
    };
    let mut rows = call.core.stored_since(&search, since, limit + 1).map_err(engine)?;
    let has_more = rows.len() as u64 > limit;
    rows.truncate(limit as usize);
    if !rows.is_empty() {
        call.read("changes", rows.len() as u64, "", "")?;
    }
    let next = match rows.last() {
        Some(last) if has_more => last.id,
        _ => newest.max(since),
    };
    Ok(json!({
        "next_cursor": next,
        "has_more": has_more,
        "messages": rows.iter().map(|m| row(m, places.get(&m.folder_id), call.fence)).collect::<Vec<_>>(),
    }))
}
