//! The AI Agents log: what agents did, kept as data (the catalog id of its words and their values) and put into words
//! in the language in use each time it is shown, so switching languages changes every row; and what they read, one
//! row a read, shown as a summary of each program's hour that opens to the subjects (decision 6 of the MCP plan).

use pe_i18n::{Arg, Text, tr, tr_args};
use pe_store::{AgentHostId, AgentLogEntry, AgentRead, NewLogEntry, NewRead, ReadSummary};

use crate::{Core, Event, Result};

/// Between the values of an entry
const RECORD: char = '\u{1e}';
/// Between a value's name and the value
const UNIT: char = '\u{1f}';
/// The ids of the log's words: nothing else is put into words from the store
const LOG_IDS: &str = "agent-log-";

/// `args` as the store keeps them: each name, whether it is a number, and its value
pub(crate) fn encode_args(args: &[(&str, Arg)]) -> String {
    let clean = |text: &str| text.replace([RECORD, UNIT], " ");
    args.iter()
        .map(|(name, value)| match value {
            Arg::Num(n) => format!("{}{UNIT}n{n}", clean(name)),
            Arg::Str(s) => format!("{}{UNIT}s{}", clean(name), clean(s)),
        })
        .collect::<Vec<_>>()
        .join(&RECORD.to_string())
}

/// The values [`encode_args`] wrote: name, value, and whether it is a number
fn decode_args(args: &str) -> Vec<(String, String, bool)> {
    args.split(RECORD)
        .filter_map(|record| {
            let (name, value) = record.split_once(UNIT)?;
            let number = value.starts_with('n');
            Some((name.to_string(), value.get(1..)?.to_string(), number))
        })
        .collect()
}

/// An entry of program `host`'s log, doing `what` (the tool), that says `text` with `args`
pub fn log_entry(host: AgentHostId, what: &str, text: Text, args: &[(&str, Arg)]) -> NewLogEntry {
    NewLogEntry {
        host,
        what: what.into(),
        kind: Some(text.id().into()),
        args: Some(encode_args(args)),
        ..Default::default()
    }
}

/// The words of the log entry `kind` with `args`, in the language in use; None for an id that is not the log's
pub(crate) fn words(kind: &str, args: &str) -> Option<String> {
    if !kind.starts_with(LOG_IDS) {
        return None;
    }
    let text = Text::ALL.iter().copied().find(|text| text.id() == kind)?;
    let values = decode_args(args);
    let args: Vec<(&str, Arg)> = values
        .iter()
        .map(|(name, value, number)| {
            let arg = match value.parse::<i64>() {
                Ok(n) if *number => Arg::Num(n),
                _ => Arg::Str(value),
            };
            (name.as_str(), arg)
        })
        .collect();
    Some(tr_args(text, &args))
}

/// What an entry says, in the language in use (its summary when it was written before entries were data)
fn said(entry: &NewLogEntry) -> String {
    entry
        .kind
        .as_deref()
        .and_then(|kind| words(kind, entry.args.as_deref().unwrap_or_default()))
        .unwrap_or_else(|| entry.summary.clone())
}

/// An entry of the log as the AI Agents window lists it, in the language in use
pub fn log_text(entry: &AgentLogEntry) -> String {
    let said = said(&entry.entry);
    if entry.undone {
        tr_args(Text::AgentLogTakenBack, &[("entry", (&said).into())])
    } else {
        said
    }
}

/// A row of the AI Agents window's log: something an agent did, or what a program read in an hour
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct LogRow {
    /// The entry's id, for Undo; 0 for a summary of reads
    pub id: i64,
    pub host: AgentHostId,
    pub host_name: String,
    /// When it was done; a summary's last read
    pub at: i64,
    /// What it says, in the language in use
    pub text: String,
    pub can_undo: bool,
    pub undone: bool,
    /// The agent's request it came from, empty when not known
    pub call_id: String,
    /// For a summary of reads: the start of its hour, which [`Core::agent_reads_of_hour`] opens
    pub reads_hour: Option<i64>,
}

/// The parts of a summary that are not nought, in words
fn read_parts(summary: &ReadSummary) -> Vec<String> {
    [
        (summary.messages, Text::AgentReadsMessages),
        (summary.attachments, Text::AgentReadsAttachments),
        (summary.searches, Text::AgentReadsSearches),
        (summary.lists, Text::AgentReadsLists),
    ]
    .into_iter()
    .filter(|(count, _)| *count > 0)
    .map(|(count, text)| tr_args(text, &[("count", count.into())]))
    .collect()
}

/// What a program read in an hour, in a line: "Read 14 messages and searched 3 times"
pub fn read_summary_text(summary: &ReadSummary) -> String {
    let parts = read_parts(summary);
    let line = match parts.as_slice() {
        [] => return String::new(),
        [one] => one.clone(),
        [first @ .., last] => tr_args(
            Text::AgentCanList,
            &[("first", (&first.join(", ")).into()), ("last", last.into())],
        ),
    };
    super::capitalized(&line)
}

/// One read, in a line: "Read “Lunch”", "Searched for “invoice”: 4 messages"
pub fn read_text(read: &NewRead) -> String {
    let shown = if read.subject.trim().is_empty() {
        tr(Text::UiNoSubject)
    } else {
        read.subject.clone()
    };
    let (subject, count) = (Arg::from(&shown), Arg::from(read.count));
    let query = Arg::from(&read.subject);
    match read.what.as_str() {
        "conversation" => tr_args(Text::AgentReadConversation, &[("subject", subject), ("count", count)]),
        "attachment" => tr_args(
            Text::AgentReadAttachment,
            &[("name", (&read.detail).into()), ("subject", subject)],
        ),
        "search" => tr_args(Text::AgentReadSearch, &[("query", query), ("count", count)]),
        "people" => tr_args(Text::AgentReadPeople, &[("query", query)]),
        "list" => tr_args(Text::AgentReadList, &[("folder", query), ("count", count)]),
        "changes" => tr_args(Text::AgentReadChanges, &[("count", count)]),
        _ => tr_args(Text::AgentReadMessage, &[("subject", subject)]),
    }
}

impl LogRow {
    fn of_entry(entry: &AgentLogEntry) -> LogRow {
        LogRow {
            id: entry.id,
            host: entry.entry.host,
            host_name: entry.host_name.clone(),
            at: entry.at,
            text: log_text(entry),
            can_undo: entry.entry.undo.is_some() && !entry.undone,
            undone: entry.undone,
            call_id: entry.entry.call_id.clone().unwrap_or_default(),
            reads_hour: None,
        }
    }

    fn of_reads(summary: &ReadSummary) -> LogRow {
        LogRow {
            id: 0,
            host: summary.host,
            host_name: summary.host_name.clone(),
            at: summary.last,
            text: read_summary_text(summary),
            can_undo: false,
            undone: false,
            call_id: String::new(),
            reads_hour: Some(summary.hour),
        }
    }
}

impl Core {
    /// Writes what agents read; the windows hear of it once
    pub fn log_agent_reads(&self, reads: &[NewRead]) -> Result<()> {
        if reads.is_empty() {
            return Ok(());
        }
        self.store().log_reads(reads, super::now())?;
        self.post(Event::AgentLogChanged)
    }

    /// The newest `limit` rows of the AI Agents window's log, newest first: what agents did, and a summary of what
    /// each program read in each hour, in the language in use
    pub fn agent_log_rows(&self, limit: u64) -> Result<Vec<LogRow>> {
        let (entries, summaries, hosts) = {
            let store = self.store();
            (
                store.agent_log(limit)?,
                store.read_summaries(limit)?,
                store.agent_hosts()?,
            )
        };
        let mut rows: Vec<LogRow> = entries.iter().map(LogRow::of_entry).collect();
        rows.extend(summaries.iter().map(LogRow::of_reads));
        // each program as the list of programs names it
        for row in &mut rows {
            if let Some(host) = hosts.iter().find(|h| h.id == row.host) {
                row.host_name = super::host_label(&host.name, &host.path);
            }
        }
        rows.sort_by(|a, b| b.at.cmp(&a.at).then(b.id.cmp(&a.id)));
        rows.truncate(usize::try_from(limit).unwrap_or(usize::MAX));
        Ok(rows)
    }

    /// What program `host` read in the hour that starts at `hour` (a row's [`LogRow::reads_hour`]), each read with
    /// when and in a line: subjects, queries and folders, never what the messages say
    pub fn agent_reads_of_hour(&self, host: AgentHostId, hour: i64) -> Result<Vec<(i64, String)>> {
        let reads: Vec<AgentRead> = self.store().reads_of_hour(host, hour)?;
        Ok(reads.iter().map(|r| (r.at, read_text(&r.read))).collect())
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn entries_are_worded_when_shown() {
        let entry = log_entry(
            1,
            "move_messages",
            Text::AgentLogMoved,
            &[("subject", "Plans \u{1e}x".into()), ("folder", "Archive".into())],
        );
        assert_eq!(entry.kind.as_deref(), Some("agent-log-moved"));
        assert_eq!(said(&entry), "Moved \u{201c}Plans  x\u{201d} to Archive");
        // numbers stay numbers, for the plurals
        let args = encode_args(&[("count", 3.into()), ("name", "12".into())]);
        assert_eq!(
            decode_args(&args),
            [("count".into(), "3".into(), true), ("name".into(), "12".into(), false)]
        );
        // only the log's own words; an older entry says what it said
        assert_eq!(words("menu-file", ""), None);
        let old = NewLogEntry {
            summary: "Moved \u{201c}A\u{201d}".into(),
            ..Default::default()
        };
        assert_eq!(said(&old), "Moved \u{201c}A\u{201d}");
    }

    #[test]
    fn reads_are_summed_in_words() {
        let summary = ReadSummary {
            messages: 14,
            searches: 3,
            ..Default::default()
        };
        assert_eq!(read_summary_text(&summary), "Read 14 messages and searched 3 times");
        let one = ReadSummary {
            attachments: 1,
            lists: 2,
            messages: 1,
            ..Default::default()
        };
        assert_eq!(
            read_summary_text(&one),
            "Read 1 message, opened 1 attachment and looked at message lists 2 times"
        );
        let read = |what: &str, count: u64, subject: &str| NewRead {
            what: what.into(),
            count,
            subject: subject.into(),
            detail: "plan.pdf".into(),
            ..Default::default()
        };
        assert_eq!(read_text(&read("message", 1, "Lunch")), "Read \u{201c}Lunch\u{201d}");
        assert_eq!(read_text(&read("message", 1, " ")), "Read \u{201c}(no subject)\u{201d}");
        assert_eq!(
            read_text(&read("search", 4, "invoice")),
            "Searched for \u{201c}invoice\u{201d}: 4 messages"
        );
        assert_eq!(
            read_text(&read("attachment", 1, "Plans")),
            "Opened \u{201c}plan.pdf\u{201d} of \u{201c}Plans\u{201d}"
        );
    }
}
