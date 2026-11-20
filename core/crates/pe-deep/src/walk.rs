//! The walk: steps drawn at random from what a user and a server do, with the checks after each. Stretches of "fast
//! fingers" send several acts before anything comes back, then wait and check. The seed decides every choice, so a
//! run can be played again up to the step that failed (`--until`); what the target does in between can still differ
//! in its timing, which is why the checks wait for quiet and the report keeps both sides' answers.

use pe_testkit::Rng;

use crate::model::{Act, List, Seen, SortBy};
use crate::run::{Run, Stop};
use crate::world::{Kind, rfc2822};

/// A maker of new mail for the server to deliver: the `n`th message, the same for a seed
pub fn new_mail_maker(seed: u64) -> impl Fn(u64) -> String {
    move |n| {
        let date = crate::world::NOW + 3600 + n as i64 * 61;
        format!(
            "From: Walk Sender <walk@example.com>\r\nTo: You <you@deep.inboxclassic.test>\r\nSubject: Arrived during the walk {seed}-{n}\r\nDate: {}\r\nMessage-ID: <walk-{seed}-{n}@deep.inboxclassic.test>\r\nContent-Type: text/plain; charset=utf-8\r\n\r\nNew mail in the walk.\r\n",
            rfc2822(date)
        )
    }
}

/// What the walk can do, with how often
#[derive(Debug, Clone, Copy)]
#[allow(clippy::enum_variant_names)]
enum Move {
    Open,
    Scroll,
    Ends,
    Click,
    Range,
    Mark,
    Delete,
    Move,
    Sort,
    Search,
    Group,
    UnreadOnly,
    Undo,
    Sync,
    Deliver,
    OtherFlags,
    OtherExpunge,
    FastFingers,
    Fault,
}

const TABLE: &[(Move, u64)] = &[
    (Move::Open, 14),
    (Move::Scroll, 12),
    (Move::Ends, 5),
    (Move::Click, 16),
    (Move::Range, 3),
    (Move::Mark, 6),
    (Move::Delete, 4),
    (Move::Move, 3),
    (Move::Sort, 3),
    (Move::Search, 4),
    (Move::Group, 2),
    (Move::UnreadOnly, 2),
    (Move::Undo, 2),
    (Move::Sync, 3),
    (Move::Deliver, 5),
    (Move::OtherFlags, 3),
    (Move::OtherExpunge, 2),
    (Move::FastFingers, 4),
    (Move::Fault, 2),
];

fn draw(rng: &mut Rng) -> Move {
    let total: u64 = TABLE.iter().map(|(_, w)| w).sum();
    let mut at = rng.below(total);
    for (m, w) in TABLE {
        if at < *w {
            return *m;
        }
        at -= w;
    }
    Move::Click
}

/// The folders the servers have now, by account: the world's, less those the journeys renamed or deleted
pub struct Folders(Vec<(String, Vec<String>)>);

impl Folders {
    pub fn read(servers: &crate::servers::Servers) -> Folders {
        Folders(
            servers
                .accounts
                .iter()
                .map(|a| (a.name.clone(), a.counted().into_iter().map(|c| c.path).collect()))
                .collect(),
        )
    }
}

/// A list of the tree, the big ones more often
fn some_list(rng: &mut Rng, folders: &Folders) -> List {
    let accounts = &folders.0;
    match rng.below(10) {
        0 => List::AllInboxes,
        1 => List::Flagged,
        2 => List::AllSent,
        3..=5 => List::folder(&accounts[0].0, "INBOX"),
        _ => {
            let (account, paths) = rng.pick(accounts);
            List::folder(account, rng.pick(paths))
        }
    }
}

/// A folder of `account` to move messages to: not the one they are in
fn some_folder(rng: &mut Rng, folders: &Folders, account: &str, not: &str) -> Option<List> {
    let (_, paths) = folders.0.iter().find(|(a, _)| a == account)?;
    let candidates: Vec<&String> = paths.iter().filter(|p| *p != not).collect();
    (!candidates.is_empty()).then(|| List::folder(account, rng.pick(&candidates)))
}

/// One act drawn for the window as it is
fn user_act(rng: &mut Rng, m: Move, seen: &Seen, folders: &Folders) -> Option<Act> {
    let rows = seen.rows;
    let any_row = |rng: &mut Rng| rng.below(rows.max(1));
    Some(match m {
        Move::Open => Act::Open(some_list(rng, folders)),
        Move::Scroll if rows > 0 => Act::Scroll(any_row(rng)),
        Move::Ends => match rng.below(3) {
            0 => Act::Home,
            1 => Act::End,
            _ => Act::PageDown(1 + rng.below(20) as u32),
        },
        Move::Click if rows > 0 => {
            // mostly a row in sight, as a hand does; now and then one far away (type to find, Next Unread)
            let row = match seen.sight.as_slice() {
                [] => any_row(rng),
                sight if rng.chance(80) => rng.pick(sight).row,
                _ => any_row(rng),
            };
            Act::Click(row)
        }
        Move::Range if rows > 1 => Act::ShiftClick(any_row(rng)),
        Move::Mark if !seen.selected.is_empty() => match rng.below(3) {
            0 => Act::Flag,
            1 => Act::Read,
            _ => Act::Unread,
        },
        // a delete or a move of a few: what a user does with what they selected, not the whole of a big list
        Move::Delete if (1..=50).contains(&seen.selected.len()) => Act::Delete,
        Move::Move if (1..=50).contains(&seen.selected.len()) => {
            let Some(List::Folder { account, path }) = &seen.list else {
                return None;
            };
            Act::MoveTo(some_folder(rng, folders, account, path)?)
        }
        Move::Sort => Act::Sort(*rng.pick(&SortBy::ALL), rng.chance(30)),
        Move::Search => {
            if seen.search.is_empty() {
                Act::Search((*rng.pick(&["budget", "review", "notes", "Re:", "from:maria", "has:attachment"])).into())
            } else {
                Act::Search(String::new())
            }
        }
        Move::Group => Act::Group(!seen.grouped),
        Move::UnreadOnly => Act::UnreadOnly(!seen.unread_only),
        Move::Undo => Act::Undo,
        Move::Sync => Act::Sync,
        _ => return None,
    })
}

/// The walk of `steps` steps; the run's own `until` stops it early
pub fn walk(run: &mut Run<'_>, seed: u64, steps: u64) -> Result<(), Stop> {
    run.part = "walk".into();
    let mut rng = Rng::new(seed ^ 0x005e_ed0f_d33b);
    let accounts = run.world.accounts.clone();
    let folders = Folders::read(run.servers);
    let deliver = new_mail_maker(seed);
    let mut delivered = 0;
    let start = run.step_number();
    let mut seen = run.settled()?;
    while run.step_number() - start < steps {
        let m = draw(&mut rng);
        match m {
            Move::Deliver => {
                let account = rng.pick(&accounts);
                let count = 1 + rng.below(if account.kind == Kind::Work { 60 } else { 6 });
                let first = delivered;
                delivered += count;
                let name = account.name.clone();
                run.server(format!("delivers {count} to {name}/INBOX"), |s| {
                    if let Some(a) = s.account(&name) {
                        for n in first..first + count {
                            a.deliver("INBOX", &deliver(n), &[]);
                        }
                    }
                })?;
            }
            Move::OtherFlags | Move::OtherExpunge => {
                // another client changes some of the rows in sight, in the folders they are in (a search's rows are
                // of every folder)
                let expunge = matches!(m, Move::OtherExpunge);
                let mut picked: Vec<(String, String, u64)> = seen
                    .sight
                    .iter()
                    .filter_map(|r| r.message.as_ref())
                    .filter(|_| rng.chance(30))
                    .map(|msg| (msg.account.clone(), msg.path.clone(), msg.uid))
                    .collect();
                picked.truncate(if expunge { 3 } else { 10 });
                if picked.is_empty() {
                    continue;
                }
                let flag = *rng.pick(&["\\Seen", "\\Flagged"]);
                let add = rng.chance(50);
                run.server(
                    format!(
                        "another client {} {picked:?}",
                        if expunge { "expunges" } else { "flags" }
                    ),
                    |s| {
                        for (account, path, uid) in &picked {
                            if let Some(a) = s.account(account) {
                                if expunge {
                                    a.expunge(path, &[*uid]);
                                } else {
                                    a.flags(path, &[*uid], &[flag], if add { "add" } else { "remove" });
                                }
                            }
                        }
                    },
                )?;
            }
            Move::Fault => {
                // the ill server of Broken: a dropped connection, a slow command or a refused one, now and then
                let rule = match rng.below(3) {
                    0 => {
                        serde_json::json!({ "on": "command", "match": "FETCH|STORE|MOVE|SELECT", "close": true, "times": 1 })
                    }
                    1 => serde_json::json!({ "on": "command", "match": "FETCH", "delay": 3000, "times": 1 }),
                    _ => serde_json::json!({ "on": "greeting", "send": "* BYE Busy\r\n", "close": true, "times": 1 }),
                };
                let broken = accounts.iter().find(|a| a.kind == Kind::Broken).map(|a| a.name.clone());
                let Some(broken) = broken else { continue };
                run.server(format!("Broken's server: {rule}"), |s| {
                    if let Some(a) = s.account(&broken) {
                        a.fault(rule.clone());
                    }
                })?;
                run.act(Act::Open(List::folder(&broken, "INBOX")))?;
                run.act(Act::Sync)?;
                // once the fault is spent the next sync is a clean one, for the checks
                run.target.settle().map_err(Stop::Broken)?;
                run.act(Act::Sync)?;
            }
            Move::FastFingers => {
                // several acts before anything comes back
                for _ in 0..3 + rng.below(4) {
                    let quick = *rng.pick(&[Move::Open, Move::Scroll, Move::Click, Move::Ends, Move::Sort]);
                    if let Some(act) = user_act(&mut rng, quick, &seen, &folders) {
                        run.act(act)?;
                        seen = run.check(false)?;
                    }
                }
            }
            _ => {
                let Some(act) = user_act(&mut rng, m, &seen, &folders) else {
                    continue;
                };
                run.act(act)?;
            }
        }
        // what the server did reaches the window with the next sync (IDLE tells of the folder shown only)
        if matches!(m, Move::Deliver | Move::OtherFlags | Move::OtherExpunge) {
            run.act(Act::Sync)?;
        }
        // a check now and then before quiet (what holds while things are under way), always after
        if rng.chance(20) {
            run.check(false)?;
        }
        seen = run.settled()?;
    }
    if run.shape.sort != SortBy::Date {
        run.act(Act::Sort(SortBy::Date, false))?;
        run.settled()?;
    }
    Ok(())
}
