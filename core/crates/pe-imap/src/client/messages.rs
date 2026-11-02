//! Changing messages: flags (STORE), COPY, MOVE (with the COPY, STORE and EXPUNGE fallback),
//! EXPUNGE and APPEND, with the UIDs UIDPLUS reports.

use super::{Client, Error};
use crate::compiler::Arg;
use crate::sequence::{Messages, SequenceSet};
use crate::types::{Response, Token};

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum StoreAction {
    Add,
    Remove,
    Set,
}

/// Where copied or moved messages ended up (UIDPLUS): `[COPYUID 38505 304,319:320 3956:3958]`,
/// the UIDs in the destination in the order of the source UIDs
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct CopyUid {
    pub uid_validity: u64,
    pub source: SequenceSet,
    pub destination: SequenceSet,
}

fn copy_uid(response: &Response) -> Option<CopyUid> {
    let args = response.code_args("COPYUID")?;
    let set = |i: usize| {
        args.get(i)
            .and_then(Token::text)
            .and_then(|t| SequenceSet::parse(&t).ok())
    };
    Some(CopyUid {
        uid_validity: args.first()?.number()?,
        source: set(1)?,
        destination: set(2)?,
    })
}

impl Client {
    /// Changes flags. The new flags arrive as [`super::Event::Flags`] when the server reports
    /// them, as it does for changes by other clients.
    pub async fn store(&mut self, messages: &Messages, action: StoreAction, flags: &[&str]) -> Result<(), Error> {
        self.require_selected()?;
        let item = match action {
            StoreAction::Add => "+FLAGS",
            StoreAction::Remove => "-FLAGS",
            StoreAction::Set => "FLAGS",
        };
        let args = vec![
            Arg::Sequence(messages.set().to_string()),
            Arg::atom(item),
            Arg::List(flags.iter().map(|f| Arg::atom(*f)).collect()),
        ];
        self.simple(&messages.command("STORE"), args).await
    }

    pub async fn copy(&mut self, messages: &Messages, destination: &str) -> Result<Option<CopyUid>, Error> {
        self.require_selected()?;
        let args = vec![Arg::Sequence(messages.set().to_string()), self.encode_path(destination)];
        let completion = self.run(&messages.command("COPY"), args).await?;
        Ok(copy_uid(&completion.tagged))
    }

    /// Moves messages, with MOVE where the server has it. Otherwise they are copied, marked
    /// `\Deleted` and expunged: with UID EXPUNGE when the server has UIDPLUS, with a plain
    /// EXPUNGE otherwise, which also removes other messages marked `\Deleted`.
    pub async fn move_messages(&mut self, messages: &Messages, destination: &str) -> Result<Option<CopyUid>, Error> {
        self.require_selected()?;
        if !self.has_capability("MOVE") {
            let copied = self.copy(messages, destination).await?;
            self.store(messages, StoreAction::Add, &["\\Deleted"]).await?;
            match messages {
                Messages::Uids(set) if self.has_capability("UIDPLUS") => self.expunge(Some(set)).await?,
                _ => self.expunge(None).await?,
            }
            return Ok(copied);
        }
        let args = vec![Arg::Sequence(messages.set().to_string()), self.encode_path(destination)];
        let completion = self.run(&messages.command("MOVE"), args).await?;
        // the COPYUID of MOVE comes in an untagged OK before the expunges
        Ok(completion
            .untagged
            .iter()
            .find_map(copy_uid)
            .or_else(|| copy_uid(&completion.tagged)))
    }

    /// Removes messages marked `\Deleted`: all of them, or only those with these UIDs, which
    /// needs UIDPLUS
    pub async fn expunge(&mut self, uids: Option<&SequenceSet>) -> Result<(), Error> {
        self.require_selected()?;
        match uids {
            Some(_) if !self.has_capability("UIDPLUS") => Err(Error::Unsupported("UIDPLUS")),
            Some(set) => self.simple("UID EXPUNGE", vec![Arg::Sequence(set.to_string())]).await,
            None => self.simple("EXPUNGE", Vec::new()).await,
        }
    }

    /// Adds a message to a mailbox, returns its UIDVALIDITY and UID where the server says
    /// (UIDPLUS)
    pub async fn append(
        &mut self,
        path: &str,
        message: &[u8],
        flags: &[&str],
        internal_date: Option<i64>,
    ) -> Result<Option<(u64, u64)>, Error> {
        let mut args = vec![self.encode_path(path)];
        if !flags.is_empty() {
            args.push(Arg::List(flags.iter().map(|f| Arg::atom(*f)).collect()));
        }
        if let Some(date) = internal_date {
            args.push(Arg::string(crate::date::format_internal_date(date)));
        }
        // NUL bytes only go in a literal8, where the server supports BINARY
        if message.contains(&0) && self.has_capability("BINARY") {
            args.push(Arg::Literal8(message.to_vec()));
        } else {
            args.push(Arg::Literal(message.to_vec()));
        }
        let completion = self.run("APPEND", args).await?;
        let Some(values) = completion.tagged.code_args("APPENDUID") else {
            return Ok(None);
        };
        Ok(values
            .first()
            .and_then(Token::number)
            .zip(values.get(1).and_then(Token::number)))
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn reads_copyuid() {
        let response = crate::parse(b"A1 OK [COPYUID 38505 304,319:320 3956:3958] Done", Vec::new()).unwrap();
        assert_eq!(
            copy_uid(&response),
            Some(CopyUid {
                uid_validity: 38505,
                source: SequenceSet::parse("304,319:320").unwrap(),
                destination: SequenceSet::parse("3956:3958").unwrap(),
            })
        );
        let other = crate::parse(b"A1 OK [APPENDUID 1 2] Done", Vec::new()).unwrap();
        assert_eq!(copy_uid(&other), None);
    }
}
