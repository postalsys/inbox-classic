//! Waiting for changes: IDLE (RFC 2177), or NOOP every `Timeouts::poll` where the server has no IDLE.
//! Changes arrive as [`super::Event`]s while it waits.

use std::future::Future;

use super::{Client, Direction, Error, keep};

impl Client {
    /// Waits for changes until `stop` completes or the IDLE period (`Timeouts::idle`) ends.
    /// Returns Ok(true) when `stop` completed, Ok(false) when the period ended and the caller
    /// should call it again.
    pub async fn idle(&mut self, stop: impl Future<Output = ()>) -> Result<bool, Error> {
        self.require_selected()?;
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

        let (tag, _) = self.send("IDLE", Vec::new()).await?;
        // None while idling, then whether `stop` (rather than the period) ended it
        let mut ended: Option<bool> = None;
        let mut collected = Vec::new();
        loop {
            let timeout = ended.map(|_| self.config.timeouts.response);
            tokio::select! {
                // the server's answer first, so a completion is never missed
                biased;
                response = self.read_response(Some(&tag), timeout) => {
                    let response = response?;
                    if response.tag == tag {
                        return self.complete("IDLE", response, Vec::new()).map(|_| ended == Some(true));
                    }
                    if response.is_untagged() {
                        self.on_untagged(response, &mut keep, &mut collected)?;
                        // nothing waits for these, they were applied and reported
                        collected.clear();
                    }
                    // the "+ idling" continuation needs no answer
                }
                _ = &mut stop, if ended.is_none() => {
                    ended = Some(true);
                    self.done().await?;
                }
                _ = &mut period, if ended.is_none() => {
                    ended = Some(false);
                    self.done().await?;
                }
            }
        }
    }

    async fn done(&mut self) -> Result<(), Error> {
        self.log(Direction::Client, || "DONE".into());
        self.write(b"DONE\r\n").await
    }
}
