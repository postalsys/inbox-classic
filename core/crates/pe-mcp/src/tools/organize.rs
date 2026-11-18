//! Organizing beyond moving messages: flag colours, Watch and Ignore Conversation, and folders made and renamed. Each
//! goes through the engine's own methods and is written in the agent log, with Undo where the log can take it back.

use std::time::{Duration, Instant};

use pe_core::agents::Undo;
use pe_i18n::{Arg, Text};
use pe_store::{FlagColor, MessageRef, ThreadMark};
use serde_json::json;

use super::{Args, Call, Outcome, engine};

/// The colours set_flag_color takes, and none
pub(super) const COLORS: [&str; 8] = ["red", "orange", "yellow", "green", "blue", "purple", "gray", "none"];

/// How long create_folder waits for the server to make the folder
const FOLDER_WAIT: Duration = Duration::from_secs(15);

pub(super) fn set_flag_color(call: &Call, args: &Args) -> Outcome {
    let folder = call.folder(args.int("folder")?)?;
    let uids = args.uids()?;
    let name = args.string("color");
    let color = match name.as_str() {
        "none" => None,
        _ => Some(
            FlagColor::ALL
                .into_iter()
                .find(|c| c.id() == name)
                .ok_or_else(|| format!("`color` is one of {}.", COLORS.join(", ")))?,
        ),
    };
    let before = call.messages(folder.id, &uids)?;
    call.core.set_flag_color_many(folder.id, &uids, color).map_err(engine)?;
    // only what changed is written: a colour set again is no change to take back, and must not crowd the log
    let entries: Vec<_> = before
        .iter()
        .filter_map(|message| {
            let was = message
                .info
                .flagged()
                .then(|| message.info.flag_color().unwrap_or(FlagColor::Red));
            (was != color).then_some((message, was))
        })
        .map(|(message, was)| {
            let undo = Undo::Color {
                folder: folder.id,
                uid: message.info.uid,
                was,
                set: Some(color),
            };
            match color {
                Some(color) => call.message_entry(
                    &folder,
                    message,
                    Text::AgentLogFlagColor,
                    &[("color", color.id().into())],
                    Some(undo),
                ),
                None => call.message_entry(&folder, message, Text::AgentLogUnflagged, &[], Some(undo)),
            }
        })
        .collect();
    let ids = call.log(&entries)?;
    Ok(json!({ "done": true, "messages": uids.len(), "change_ids": ids }))
}

pub(super) fn set_conversation_mark(call: &Call, args: &Args) -> Outcome {
    let thread = args.int("thread")?;
    let (mark, text) = match args.string("mark").as_str() {
        "watch" => (ThreadMark::Watch, Text::AgentLogWatched),
        "ignore" => (ThreadMark::Ignore, Text::AgentLogIgnored),
        "none" => (ThreadMark::None, Text::AgentLogUnmarked),
        _ => return Err("`mark` is watch, ignore or none.".into()),
    };
    let messages = call.core.agent_conversation(&call.host, thread).map_err(engine)?;
    let Some(first) = messages.first() else {
        return Err(format!(
            "There is no conversation {thread} in the accounts this agent may use. Message rows name theirs as `thread`."
        ));
    };
    let refs: Vec<MessageRef> = messages
        .iter()
        .map(|m| MessageRef {
            folder: m.folder_id,
            uid: m.info.uid,
        })
        .collect();
    call.core.set_conversation_mark(&refs, mark).map_err(engine)?;
    let folder = call.folder(first.folder_id)?;
    call.log(&[call.message_entry(&folder, first, text, &[], None)])?;
    Ok(json!({ "done": true, "thread": thread, "messages": messages.len() }))
}

pub(super) fn rename_folder(call: &Call, args: &Args) -> Outcome {
    let folder = call.folder(args.int("folder")?)?;
    if pe_core::is_fixed_folder(&folder.info) {
        return Err(
            "The Inbox and the special folders (Sent Items, Drafts, Deleted Items, Junk E-mail, Archive and the like) are not renamed."
                .into(),
        );
    }
    let name = args.string("name");
    let old = pe_core::folder_name(&folder.info);
    call.core.rename_folder(folder.id, &name).map_err(engine)?;
    let args: [(&str, Arg); 2] = [("old", (&old).into()), ("name", (&name).into())];
    call.log(&[call.entry(folder.account_id, Text::AgentLogRenamed, &args)])?;
    Ok(
        json!({ "done": true, "note": "The folder shows under its new name in list_folders once the server renamed it." }),
    )
}

pub(super) async fn create_folder(call: &Call<'_>, args: &Args<'_>) -> Outcome {
    let account = args.int("account")?;
    call.account(account)?;
    let parent = match args.opt_int("parent") {
        Some(parent) => Some(call.folder(parent)?.id),
        None => None,
    };
    let name = args.string("name");
    let before: Vec<i64> = call
        .core
        .folders(account)
        .map_err(engine)?
        .iter()
        .map(|f| f.id)
        .collect();
    call.core.create_folder(account, parent, &name).map_err(engine)?;
    call.log(&[call.entry(account, Text::AgentLogFolder, &[("name", (&name).into())])])?;
    let deadline = Instant::now() + FOLDER_WAIT;
    while Instant::now() < deadline {
        tokio::time::sleep(Duration::from_millis(250)).await;
        let made = call
            .core
            .folders(account)
            .map_err(engine)?
            .into_iter()
            .find(|f| !before.contains(&f.id) && f.info.name == name.trim());
        if let Some(made) = made {
            return Ok(json!({ "done": true, "folder": made.id, "path": made.info.path }));
        }
    }
    Ok(json!({ "done": true, "note": "The server has not made the folder yet: it shows in list_folders once it has." }))
}

#[cfg(test)]
mod tests {
    #[test]
    fn every_colour_is_offered() {
        for color in pe_store::FlagColor::ALL {
            assert!(super::COLORS.contains(&color.id()), "{color:?}");
        }
    }
}
