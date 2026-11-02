//! Changing messages: flags (STORE), COPY, MOVE (with the COPY, STORE and EXPUNGE fallback),
//! EXPUNGE and APPEND, with the UIDs UIDPLUS reports.

use super::{Client, Error};
use crate::compiler::Arg;
use crate::types::{Response, Token};

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum StoreAction {
    Add,
    Remove,
    Set,
}

/// Where copied or moved messages ended up (UIDPLUS): `[COPYUID 38505 304,319:320 3956:3958]`
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct CopyUid {
    pub uid_validity: u64,
    pub source: String,
    pub destination: String,
}

fn copy_uid(response: &Response) -> Option<CopyUid> {
    let (code, args) = response.code()?;
    if code != "COPYUID" {
        return None;
    }
    Some(CopyUid {
        uid_validity: args.first()?.number()?,
        source: args.get(1)?.text()?,
        destination: args.get(2)?.text()?,
    })
}

impl Client {
    fn require_selected(&self) -> Result<(), Error> {
        self.selected.as_ref().map(|_| ()).ok_or(Error::NoMailboxSelected)
    }

    /// Changes flags. The new flags arrive as [`super::Event::Flags`] when the server reports
    /// them, as it does for changes by other clients.
    pub async fn store(&mut self, set: &str, uid: bool, action: StoreAction, flags: &[&str]) -> Result<(), Error> {
        self.require_selected()?;
        let item = match action {
            StoreAction::Add => "+FLAGS",
            StoreAction::Remove => "-FLAGS",
            StoreAction::Set => "FLAGS",
        };
        let args = vec![
            Arg::Sequence(set.to_string()),
            Arg::atom(item),
            Arg::List(flags.iter().map(|f| Arg::atom(*f)).collect()),
        ];
        let command = if uid { "UID STORE" } else { "STORE" };
        self.run(command, args).await.map(|_| ())
    }

    pub async fn copy(&mut self, set: &str, uid: bool, destination: &str) -> Result<Option<CopyUid>, Error> {
        self.require_selected()?;
        let args = vec![Arg::Sequence(set.to_string()), self.encode_path(destination)];
        let completion = self.run(if uid { "UID COPY" } else { "COPY" }, args).await?;
        Ok(copy_uid(&completion.tagged))
    }

    /// Moves messages, with MOVE where the server has it and COPY, `\Deleted` and EXPUNGE
    /// otherwise
    pub async fn move_messages(&mut self, set: &str, uid: bool, destination: &str) -> Result<Option<CopyUid>, Error> {
        self.require_selected()?;
        if !self.has_capability("MOVE") {
            let copied = self.copy(set, uid, destination).await?;
            self.store(set, uid, StoreAction::Add, &["\\Deleted"]).await?;
            self.expunge(uid.then_some(set)).await?;
            return Ok(copied);
        }
        let args = vec![Arg::Sequence(set.to_string()), self.encode_path(destination)];
        let completion = self.run(if uid { "UID MOVE" } else { "MOVE" }, args).await?;
        // the COPYUID of MOVE comes in an untagged OK before the expunges
        Ok(completion
            .untagged
            .iter()
            .find_map(copy_uid)
            .or_else(|| copy_uid(&completion.tagged)))
    }

    /// Removes messages marked `\Deleted`: only those with these UIDs when the server has UIDPLUS
    pub async fn expunge(&mut self, uids: Option<&str>) -> Result<(), Error> {
        self.require_selected()?;
        match uids {
            Some(set) if self.has_capability("UIDPLUS") => {
                self.run("UID EXPUNGE", vec![Arg::Sequence(set.to_string())]).await?;
            }
            _ => {
                self.run("EXPUNGE", Vec::new()).await?;
            }
        }
        Ok(())
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
            args.push(Arg::string(pe_mime::date::format_internal_date(date)));
        }
        // NUL bytes only go in a literal8, where the server supports BINARY
        if message.contains(&0) && self.has_capability("BINARY") {
            args.push(Arg::Literal8(message.to_vec()));
        } else {
            args.push(Arg::Literal(message.to_vec()));
        }
        let completion = self.run("APPEND", args).await?;
        let Some((code, values)) = completion.tagged.code() else {
            return Ok(None);
        };
        if code != "APPENDUID" {
            return Ok(None);
        }
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
                source: "304,319:320".into(),
                destination: "3956:3958".into(),
            })
        );
        let other = crate::parse(b"A1 OK [APPENDUID 1 2] Done", Vec::new()).unwrap();
        assert_eq!(copy_uid(&other), None);
    }
}
