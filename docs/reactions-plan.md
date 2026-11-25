# Emoji reactions

Gmail and Outlook let people react to a message with an emoji and send the reaction back as an email. Inbox Classic shows the reaction on the message it is for and keeps the email out of the lists. The user's decisions of 2026-11-25 are below; later work keeps them.

## Decisions

- The reaction email is hidden in the app, marked read and kept where it is on the server; other mail programs still see it.
- A reaction shows on the reacted message: a badge after the subject of its row (up to three emoji, most used first, then how many when more than one; a collapsed conversation's row carries its messages'), a Reactions line in the reading pane's header (one chip a person, their emoji together), the conversation stack's lines, and a notification in place of the new mail one.
- Strict recognition: only a reply to one message the app has, from that message's sender or one of its recipients, whose domain the provider says signed it (as for sign-in codes). Anything else stays an ordinary email, and so does a reaction whose message is not here.
- No sending of reactions. Gmail's taken-back reactions are not followed (Gmail sends nothing).
- A chip's menu: Open Reaction Email (the email in a message window) and Show as Email (listed again for good).
- AI agents read a message's reactions; the hidden emails stay out of their lists.
- Mail downloaded before the update is looked at in the background.

## How it works

- `pe-core/src/reactions.rs` recognises the three shapes: Gmail's `text/vnd.google.email-reaction+json` part (`{"emoji", "version": 1}`), RFC 9078's `Content-Disposition: reaction` part, and Outlook's banner (its reaction picture from `outlook-1.cdn.office.net/assets/reaction/<name>.png` first in the HTML, `[name]` opening the text; the names `like`, `heart`, `celebrate`, `laugh`, `surprised`, `sad`).
- `pe-core/src/worker/reactions.rs`: new mail is looked at before the rules and the notification (small replies to a message here: their source fetched as for a sign-in code); a reaction is marked read on the server, taken out, and announced. The background pass looks at stored replies whose first words start with an emoji or Outlook's marker, once each.
- `pe-store/src/reactions.rs`: a reaction email leaves `messages` (every list, count and conversation stays as the triggers keep them) and is kept in `hidden_messages` with its source; `reactions` holds the reactions by the reacted Message-ID. The folder sync counts hidden UIDs as known (not fetched again, let go when gone from the server); Show as Email fetches the UIDs back (`pe_sync::fetch_uids`).

## The windows

- **The list**: `PeMessage::reactions` (Linux: `pe_core::reactions::badge(&message.reactions)`) after the subject, in the list's secondary colour, never a column of its own.
- **The reading pane**: under the header fields, a "Reactions:" row (`ui-reactions-label`, in the label column like From and To) with one chip a person (`pe_reactions`), shown only when there are reactions; reloaded when the message's folder changes. A chip's context menu (right-click, the context key, Shift+F10): Open Reaction Email (`pe_reactions_email_file`, opened as a message file is), Show as Email (`pe_reactions_show_as_email`), and a dimmed line with when (`ui-reaction-when`). Keyboard: the chips are reachable with Tab; Windows draws them as a static line of text whose menu opens on it.
- **The conversation stack**: drawn by the core (`pe-html` conversation lines).
- **Notifications**: the core's `NewMail` carries the words; a click opens the reacted message (its folder and UID).
