//! The drafts an agent writes: saved in the Drafts of its account with a header that names it (decision 7 of the MCP
//! plan: the compose window says who wrote one), and replaced or discarded only by the program that saved them,
//! while they are still as it saved them.

use pe_i18n::{Text, tr_args};
use pe_store::{AccountId, FolderId, NewLogEntry};

use super::{AgentHost, DRAFTS_PER_HOUR, Written, now, remember};
use crate::{Core, Draft, Error, Result};

/// What the compose window says of a draft an AI agent wrote, None for the user's own
pub fn draft_note(draft: &Draft) -> Option<String> {
    let program = draft.agent.as_deref()?;
    Some(tr_args(Text::AgentDraftNote, &[("program", program.into())]))
}

/// Where a draft of an agent is: its account, and its copy in Drafts
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct OwnDraft {
    pub account: AccountId,
    pub folder: FolderId,
    pub uid: u64,
}

impl Core {
    /// Saves what an agent wrote in the Drafts of its account, as [`Core::agent_ask_send`] would send it, with the
    /// header that names the agent; logged. Its Message-ID, by which the agent replaces or discards it. With `key`, an
    /// idempotency key the program saved with before gives that draft, and nothing is saved. Refused when the agent
    /// saved [`DRAFTS_PER_HOUR`] (new or replaced) in the last hour.
    pub fn agent_save_draft(&self, host: &AgentHost, written: &Written, key: Option<&str>) -> Result<String> {
        // held while it is saved: a call with the same key at the same moment gets the draft this one saves
        let mut asks = self.asks();
        let keyed = key.map(|key| (host.id, key.to_string()));
        if let Some(saved) = keyed.as_ref().and_then(|keyed| asks.drafts.get(keyed)) {
            return Ok(saved.clone());
        }
        let (message_id, subject) = self.agent_draft_saved(host, written, None)?;
        self.log_agent(&[NewLogEntry {
            host: host.id,
            what: "save_draft".into(),
            account: Some(written.account),
            message_id: Some(message_id.clone()),
            summary: tr_args(Text::AgentLogDraft, &[("subject", (&subject).into())]),
            ..Default::default()
        }])?;
        if let Some(keyed) = keyed {
            remember(&mut asks.drafts, keyed, message_id.clone());
        }
        Ok(message_id)
    }

    /// Saves what an agent wrote in place of its draft `draft_id` ([`Core::agent_own_draft`] says when it may),
    /// from the draft's account; logged
    pub fn agent_replace_draft(&self, host: &AgentHost, draft_id: &str, written: &Written) -> Result<()> {
        let own = self.agent_own_draft(host, draft_id)?;
        if written.account != own.account {
            return Err(Error::Unavailable(
                "A draft stays in its account: name the account it was saved in.".into(),
            ));
        }
        self.agent_draft_unchanged(host, draft_id, &own)?;
        let (_, subject) = self.agent_draft_saved(host, written, Some(draft_id.to_string()))?;
        self.log_agent(&[NewLogEntry {
            host: host.id,
            what: "replace_draft".into(),
            account: Some(own.account),
            message_id: Some(draft_id.to_string()),
            summary: tr_args(Text::AgentLogDraftReplaced, &[("subject", (&subject).into())]),
            ..Default::default()
        }])
    }

    /// Removes an agent's draft `draft_id` from Drafts ([`Core::agent_own_draft`] says when it may); logged, after
    /// which it is no longer the agent's to change
    pub fn agent_discard_draft(&self, host: &AgentHost, draft_id: &str) -> Result<()> {
        let own = self.agent_own_draft(host, draft_id)?;
        self.agent_draft_unchanged(host, draft_id, &own)?;
        let subject = self
            .store()
            .message(own.folder, own.uid)?
            .map(|m| m.agent_subject().to_string())
            .unwrap_or_default();
        self.discard_draft(own.account, draft_id)?;
        self.log_agent(&[NewLogEntry {
            host: host.id,
            what: "discard_draft".into(),
            account: Some(own.account),
            message_id: Some(draft_id.to_string()),
            summary: tr_args(Text::AgentLogDraftDiscarded, &[("subject", (&subject).into())]),
            ..Default::default()
        }])
    }

    /// The draft `draft_id` of the program `host`: one it saved (its log says so) and has not discarded, in the
    /// Drafts of its account. Refused otherwise, in words for the agent. Its source may still be to download
    /// ([`Core::open_message`]) before it is replaced or discarded.
    pub fn agent_own_draft(&self, host: &AgentHost, draft_id: &str) -> Result<OwnDraft> {
        let store = self.store();
        let account = store
            .agent_draft(host.id, draft_id)?
            .filter(|account| host.accounts.contains(account))
            .ok_or_else(|| {
                Error::Unavailable(format!(
                    "There is no draft {draft_id} of this agent: it changes only drafts it saved itself, and not \
                     those it discarded."
                ))
            })?;
        let folder = crate::compose::drafts_folder(&store, account)?.ok_or(Error::NotFound)?;
        let uid = store.uid_of_message_id(folder.id, draft_id)?.ok_or_else(|| {
            Error::Unavailable(
                "The draft is not in Drafts: the user may have sent or deleted it, or it is still being saved. Try \
                 again in a moment."
                    .into(),
            )
        })?;
        Ok(OwnDraft {
            account,
            folder: folder.id,
            uid,
        })
    }

    /// Refused when the user took over the agent's draft: it is open in a compose window that saved it, or the
    /// user saved their own version (without the header naming the agent). Its source must be here.
    fn agent_draft_unchanged(&self, host: &AgentHost, draft_id: &str, own: &OwnDraft) -> Result<()> {
        let store = self.store();
        let theirs = || {
            Error::Unavailable(
                "The user has changed this draft since the agent saved it, so it is theirs now. Save a new draft \
                 instead."
                    .into(),
            )
        };
        if store.recoveries()?.iter().any(|r| r.message_id == draft_id) {
            return Err(theirs());
        }
        let source = store
            .source(own.folder, own.uid)?
            .ok_or_else(|| Error::Unavailable("The draft is not downloaded yet. Try again in a moment.".into()))?;
        let (draft, _) = crate::compose::reopen(&source);
        if draft.agent.is_none_or(|agent| agent != host.name) {
            return Err(theirs());
        }
        Ok(())
    }

    /// What an agent wrote saved in Drafts (in place of `message_id`'s copy when given), with the header that names
    /// it; its Message-ID and subject. Refused past [`DRAFTS_PER_HOUR`].
    fn agent_draft_saved(
        &self,
        host: &AgentHost,
        written: &Written,
        message_id: Option<String>,
    ) -> Result<(String, String)> {
        let since = now() - 3600;
        let saved = {
            let store = self.store();
            store.agent_log_count(host.id, "save_draft", since)?
                + store.agent_log_count(host.id, "replace_draft", since)?
        };
        if saved >= DRAFTS_PER_HOUR {
            return Err(Error::Unavailable(format!(
                "An agent may save {DRAFTS_PER_HOUR} drafts an hour, and this one has. Try again later."
            )));
        }
        let mut outgoing = self.agent_outgoing(written)?.outgoing;
        outgoing.message_id = message_id;
        outgoing.agent = Some(host.name.clone());
        let subject = outgoing.subject.clone();
        let message_id = self.save_draft(written.account, outgoing)?;
        // no window writes it: nothing to open again after a crash
        self.store().drop_recovery(&message_id)?;
        Ok((message_id, subject))
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn an_agent_draft_says_who_wrote_it() {
        let raw = b"From: me@example.com\r\nSubject: Plan\r\nMessage-ID: <d1@example.com>\r\n\r\nHi\r\n".to_vec();
        let marked = crate::compose::with_agent_header(raw.clone(), "Claude \u{e9}\r\nX-Evil: 1");
        let (draft, _) = crate::compose::reopen(&marked);
        // one header, its name without the line break that would start another
        assert_eq!(draft.agent.as_deref(), Some("Claude \u{e9}X-Evil: 1"));
        assert!(!String::from_utf8_lossy(&marked).contains("\nX-Evil"));
        let note = draft_note(&draft).unwrap();
        assert!(note.contains("Claude"), "{note}");
        // the user's own: no note
        let (own, _) = crate::compose::reopen(&raw);
        assert_eq!((own.agent, draft_note(&Draft::default())), (None, None));
    }
}
