//! Waiting for changes: IDLE (RFC 2177), or NOOP every `Timeouts::poll` where the server has no IDLE.
//! Changes arrive as [`super::Event`]s while it waits.

use std::future::Future;

use super::{Client, Error};

impl Client {
    /// Waits for changes until `stop` completes or the IDLE period (`Timeouts::idle`) ends.
    /// Returns Ok(true) when `stop` completed, Ok(false) when the period ended and the caller
    /// should call it again.
    pub async fn idle(&mut self, stop: impl Future<Output = ()>) -> Result<bool, Error> {
        if self.selected.is_none() {
            return Err(Error::NoMailboxSelected);
        }
        let period = tokio::time::sleep(self.config.timeouts.idle);
        tokio::pin!(stop, period);
        if !self.has_capability("IDLE") {
            loop {
                tokio::select! {
                    _ = &mut stop => return Ok(true),
                    _ = &mut period => return Ok(false),
                    _ = tokio::time::sleep(self.config.timeouts.poll) => self.noop().await?,
                }
            }
        }

        let tag = self.next_tag();
        self.log(super::Direction::Client, &format!("{tag} IDLE"));
        self.write(format!("{tag} IDLE\r\n").as_bytes()).await?;
        let mut done_sent = false;
        let mut stopped = false;
        loop {
            tokio::select! {
                // the server's answer first, so a completion is never missed
                biased;
                response = self.read_response(Some(&tag), if done_sent { Some(self.config.timeouts.response) } else { None }) => {
                    let response = response?;
                    if response.tag == tag {
                        self.update_from_code(&response);
                        return self.complete("IDLE", response, Vec::new()).map(|_| stopped);
                    }
                    if response.is_untagged() {
                        self.handle_untagged(&response);
                    }
                    // the "+ idling" continuation needs no answer
                }
                _ = &mut stop, if !done_sent => {
                    stopped = true;
                    done_sent = true;
                    self.done().await?;
                }
                _ = &mut period, if !done_sent => {
                    done_sent = true;
                    self.done().await?;
                }
            }
        }
    }

    async fn done(&mut self) -> Result<(), Error> {
        self.log(super::Direction::Client, "DONE");
        self.write(b"DONE\r\n").await
    }
}
