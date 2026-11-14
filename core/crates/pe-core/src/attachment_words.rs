//! "Did you forget the attachment?": a message that says it has a file and has none. Only what the user wrote counts
//! (the subject, and the text above the signature and the quoted message), in any of the languages of the app,
//! whatever the language of the windows is, as people write in more than one.

use pe_mime::parser::html_to_text;

use crate::Outgoing;

/// The words and phrases that say a file is attached, lowercase, matched as whole words
const WORDS: &[&str] = &[
    // English
    "attached",
    "attachment",
    "attachments",
    "attaching",
    "enclosed",
    // German
    "anbei",
    "anhang",
    "angehängt",
    "beigefügt",
    // Estonian
    "manus",
    "manuses",
    "manusena",
    "manused",
    "lisatud",
    "lisafail",
    "lisafailis",
    // Spanish
    "adjunto",
    "adjunta",
    "adjuntos",
    "adjuntas",
    "adjuntado",
    // French
    "ci-joint",
    "ci-jointe",
    "ci-joints",
    "ci-jointes",
    "pièce jointe",
    "pièces jointes",
];

/// The word that says a file is attached to a message that has none, as the question names it; None when the message
/// has a file, or says nothing of one
pub fn forgotten(outgoing: &Outgoing) -> Option<&'static str> {
    if !outgoing.attachments.is_empty() {
        return None;
    }
    let written = match &outgoing.html {
        Some(html) => html_to_text(pe_html::written_part(html)),
        None => outgoing.text.clone(),
    };
    let text = format!("{}\n{}", outgoing.subject, own_lines(&written)).to_lowercase();
    WORDS.iter().copied().find(|word| has_word(&text, word))
}

/// The lines of a plain text message above its signature ("-- ") and without the lines it quotes ("> ")
fn own_lines(text: &str) -> String {
    text.lines()
        .take_while(|line| line.trim_end() != "--")
        .filter(|line| !line.trim_start().starts_with('>'))
        .collect::<Vec<_>>()
        .join("\n")
}

/// Whether `text` has `word` as a whole word: not inside a longer one
fn has_word(text: &str, word: &str) -> bool {
    text.match_indices(word).any(|(at, _)| {
        let before = text[..at].chars().next_back();
        let after = text[at + word.len()..].chars().next();
        !before.is_some_and(char::is_alphanumeric) && !after.is_some_and(char::is_alphanumeric)
    })
}

#[cfg(test)]
mod tests {
    use super::*;

    fn written(subject: &str, html: &str) -> Outgoing {
        Outgoing {
            subject: subject.into(),
            html: Some(html.into()),
            ..Default::default()
        }
    }

    #[test]
    fn finds_the_word_in_every_language() {
        for (html, word) in [
            ("<p>Please see the attached report.</p>", "attached"),
            ("<p>Die Rechnung finden Sie im Anhang.</p>", "anhang"),
            ("<p>Saadan arve manusena.</p>", "manusena"),
            ("<p>Te envío el documento adjunto.</p>", "adjunto"),
            ("<p>Veuillez trouver ci-joint la facture.</p>", "ci-joint"),
            ("<p>Voir la pièce jointe.</p>", "pièce jointe"),
        ] {
            assert_eq!(forgotten(&written("", html)), Some(word), "{html}");
        }
        assert_eq!(
            forgotten(&written("Attachment for you", "<p>Hi</p>")),
            Some("attachment")
        );
    }

    #[test]
    fn a_message_with_a_file_or_without_the_word_is_not_asked_about() {
        let mut outgoing = written("", "<p>The report is attached.</p>");
        outgoing.attachments = vec!["/tmp/report.pdf".into()];
        assert_eq!(forgotten(&outgoing), None);
        assert_eq!(forgotten(&written("Lunch", "<p>See you at noon.</p>")), None);
        // inside a longer word
        assert_eq!(
            forgotten(&written(
                "",
                "<p>We are unattached and manuscripts are adjuntamientos.</p>"
            )),
            None
        );
    }

    #[test]
    fn the_signature_and_the_quote_do_not_count() {
        let signature = "<p>Thanks</p><div><br></div><div class=\"pe-signature\">-- <br>Attachments are scanned</div>";
        assert_eq!(forgotten(&written("", signature)), None);
        let quoted = "<p>Sure.</p><blockquote type=\"cite\"><p>The file is attached.</p></blockquote>";
        assert_eq!(forgotten(&written("", quoted)), None);
        let plain = Outgoing {
            text: "Sure.\n\n> The file is attached.\n-- \nAttachments scanned\n".into(),
            ..Default::default()
        };
        assert_eq!(forgotten(&plain), None);
        // the folded quote is apart from what was written
        let mut reply = written("Re: Plans", "<p>Thanks!</p>");
        reply.quote = Some("<blockquote><p>See the attached plan.</p></blockquote>".into());
        assert_eq!(forgotten(&reply), None);
    }
}
