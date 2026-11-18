# The MCP update: what AI agents can do with Inbox Classic

From the review of 2026-11-17. The MCP server (`core/crates/pe-mcp`) still offers the 16 tools it had before most of this year's features. This plan brings agents up to the app, fixes the quality issues of the tools, and closes the security gaps the review found. It is part of the active goal and is built after the OpenPGP pull requests (7, 10, 11).

The encrypted mail wall (an agent could read decrypted attachments of encrypted mail through `get_attachment`) is fixed by OpenPGP PR 10 (#132), which merges first. Every new tool goes through one wall function in pe-core (`agent_view(message) -> Envelope | Readable`) so no tool can bypass it.

## Decisions (2026-11-17)

1. **Rules**: agents read and test rules only (`list_rules`, `test_rule` as a dry run with the match count and samples). They never create, edit or delete one.
2. **Sign-in codes**: visible as today. Agents keep seeing codes in message text; no redaction. (The review's warning stands: a hijacked agent with a browser could use one; the user chose to keep them visible.)
3. **Unsubscribe**: one question per batch. An agent's unsubscribe call raises one question in the app listing the senders; refused from Junk; a daily cap; the real outcome returned. The consent text names it.
4. **PDF, Office and image attachments**: handed to the agent as the file, an MCP embedded resource (or an image), up to about 10 MB. No new document parser in the app.
5. **Bulk changes**: `apply_to_search` with a dry run (count, samples, a token bound to the moment), then one call that runs through the off-thread actions with one Undo All. No hourly question.
6. **Read logging**: an hourly summary per program ("Read 14 messages, searched 3 times"), expandable to the subjects, no bodies, kept 30 days. The log is capped, and clearing it no longer resets the send limit.
7. **Agent drafts** are marked: opening one in the compose window says it was written by the agent, with a reminder to check recipients and text.
8. **Calendar**: agents read invitations now; accept and decline come in phase 3, only through the Send question.
9. **Programs started from a terminal** share one grant today. The connect dialog says "programs started from Terminal", and an optional `--name` in the agent's configuration gives each its own grant (informative, like the rest of the identity).

## Phase 1: quick wins

- Merge #132; one numbering of attachments for `get_message` and `get_attachment` (wrong today on bounces and signed mail), with tests.
- Compact JSON with `structuredContent`; empty fields left out; `max_chars` and `text_offset` on `get_message`.
- Rows carry `account`, `folder_name`, `message_id`, `thread`, `snippet` (outer, behind the wall), `flag_color`, `answered`.
- The search description generated from pe-store's own list of operators; `total` and `has_more`.
- Consistent names (`mark_messages_read` and so on, old names kept one release as aliases); `reply_to` input renamed `original`; `title`, `idempotentHint`, `destructiveHint` annotations.
- Errors as sentences, never debug output; not-found names which id.
- The Organize consent text and the help name archive, new folders and unsubscribe (every language, marked for review).
- Unsubscribe per decision 3.
- One pending send question per program; drafts 30 an hour; the user's signature on agent drafts and sends.
- Undo for junk; `listChanged: true` with a notification when a program's levels change; protocol 2025-11-25.

## Phase 2: what agent users expect

- Requests served side by side, cancellation, progress; `send_message` answers `waiting` with an id after about 20 s, `get_send_status`, `idempotency_key`.
- `get_conversation`, `group_by_conversation`.
- Scopes (All Inboxes, All Sent, All Drafts, Flagged) with the allowed accounts filtered in SQL.
- `list_changes(since)` with a cursor; `get_overview()` from the kept counts.
- Drafts: `draft_id`, `replace_draft`, `discard_draft` (its own only), Markdown made into sanitized HTML in Rust; agent drafts marked (decision 7).
- `get_message` adds the bounce explained, the invitation, `sender_verified` and the cleartext signature state.
- Attachments per decision 4; `find_contacts` by prefix, 20 at most.
- Flag colours, `rename_folder` (not special folders), `create_folder` returning the id, watch and ignore a conversation.
- The read log per decision 6, `call_id` on log entries, retention.
- `list_rules` and `test_rule` per decision 1.
- Untrusted mail text in per-answer delimiters; links shown by domain unless `include_links`.
- The terminal identity per decision 9.

## Phase 3

- `apply_to_search` per decision 5.
- "Undo everything this program did since..." in the AI Agents window; `undo_my_change` for agents.
- Calendar accept and decline through the Send question (decision 8).
- The real calling process checked on Windows and Linux instead of trusting the relay's hello.
- MCP resources and subscriptions (`inboxclassic://inbox`) and prompts ("Triage my inbox", "Summarize unread").

## How each PR is done

As every feature: the core and its tests, the C API, the three apps where a window changes (the AI Agents window, the send and unsubscribe questions, the compose window's agent draft note), the scenario steps and UI tests, the help in every language (drafts marked for review), /simplify and /security-review, CI green, merged. The pe-mcp e2e test grows with each tool, and the wall test covers every tool that returns mail data.
