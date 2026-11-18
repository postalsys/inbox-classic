//! Writing: drafts an agent saves, replaces and discards (its own only), and messages it asks the user to send, with
//! the answer told later when the user takes their time.

use std::time::Instant;

use pe_core::agents::{AgentAnswer, Asked, SendStatus};
use serde_json::{Value, json};

use super::{Args, Call, Outcome, PROGRESS_EVERY, SEND_WAIT, downloaded, engine, idempotency_key, written};

pub(super) fn save_draft(call: &Call, args: &Args) -> Outcome {
    let written = written(call, args, args.int("account")?)?;
    let key = idempotency_key(args)?;
    let draft_id = call
        .core
        .agent_save_draft(&call.host, &written, key.as_deref())
        .map_err(engine)?;
    Ok(json!({
        "draft_id": draft_id,
        "note": "The draft is in the account's Drafts folder for the user to read and send. replace_draft and discard_draft take its draft_id."
    }))
}

/// The draft an agent names, its own, its source here to check that the user did not change it
async fn own_draft(call: &Call<'_>, args: &Args<'_>) -> Result<(String, pe_core::agents::OwnDraft), String> {
    let draft_id = args.string("draft_id");
    if draft_id.trim().is_empty() {
        return Err("`draft_id` is missing: save_draft gave it.".into());
    }
    let own = call.core.agent_own_draft(&call.host, &draft_id).map_err(engine)?;
    downloaded(call, own.folder, own.uid).await?;
    Ok((draft_id, own))
}

pub(super) async fn replace_draft(call: &Call<'_>, args: &Args<'_>) -> Outcome {
    let (draft_id, own) = own_draft(call, args).await?;
    let account = args.opt_int("account").unwrap_or(own.account);
    let written = written(call, args, account)?;
    call.core
        .agent_replace_draft(&call.host, &draft_id, &written)
        .map_err(engine)?;
    Ok(json!({ "draft_id": draft_id, "note": "The draft was saved in place of the one before." }))
}

pub(super) async fn discard_draft(call: &Call<'_>, args: &Args<'_>) -> Outcome {
    let (draft_id, _) = own_draft(call, args).await?;
    call.core.agent_discard_draft(&call.host, &draft_id).map_err(engine)?;
    Ok(json!({ "discarded": true, "note": "The draft goes from Drafts." }))
}

/// What the agent is told of the user's answer to question `ask_id`, or that it still waits
fn told(ask_id: u64, status: &SendStatus) -> Value {
    let (status, sent, note) = match status {
        SendStatus::Waiting => (
            "waiting",
            false,
            "The user has not answered yet. The question stays open in Inbox Classic; get_send_status with this ask_id tells what becomes of it.",
        ),
        SendStatus::Answered(AgentAnswer::Send) => (
            "sent",
            true,
            "The user said yes. The message waits in the Outbox for a moment, then goes.",
        ),
        SendStatus::Answered(AgentAnswer::Compose) => (
            "opened",
            false,
            "The user opened the message to change it. It is sent only if they send it themselves.",
        ),
        SendStatus::Answered(_) => ("not_sent", false, "The user said no: the message was not sent."),
        SendStatus::Unknown => (
            "unknown",
            false,
            "Inbox Classic no longer knows this question: it closed, or it was answered long ago.",
        ),
    };
    json!({ "status": status, "sent": sent, "ask_id": ask_id, "note": note })
}

pub(super) async fn send_message(call: &Call<'_>, args: &Args<'_>) -> Outcome {
    let written = written(call, args, args.int("account")?)?;
    let key = idempotency_key(args)?;
    let asked = call
        .core
        .agent_ask_send(&call.host, &written, key.as_deref())
        .map_err(engine)?;
    let (ask_id, mut answer) = match asked {
        // asked before with this key: what became of that question
        Asked::Before(ask_id) => return Ok(told(ask_id, &call.core.agent_send_status(call.host.id, ask_id))),
        Asked::New { ask_id, answer } => (ask_id, answer),
    };
    let deadline = Instant::now() + SEND_WAIT;
    loop {
        let left = deadline.saturating_duration_since(Instant::now());
        if left.is_zero() {
            return Ok(told(ask_id, &SendStatus::Waiting));
        }
        match tokio::time::timeout(left.min(PROGRESS_EVERY), &mut answer).await {
            Ok(Ok(answer)) => return Ok(told(ask_id, &SendStatus::Answered(answer))),
            Ok(Err(_)) => return Err("Inbox Classic closed before the user answered.".into()),
            Err(_) => call.progress.report("Waiting for the user to answer in Inbox Classic"),
        }
    }
}

pub(super) fn get_send_status(call: &Call, args: &Args) -> Outcome {
    let ask_id = u64::try_from(args.int("ask_id")?).map_err(|_| "`ask_id` is not an ask_id.")?;
    match call.core.agent_send_status(call.host.id, ask_id) {
        SendStatus::Unknown => Err(format!(
            "There is no message {ask_id} this agent asked to send, or it was answered too long ago to be known."
        )),
        status => Ok(told(ask_id, &status)),
    }
}
