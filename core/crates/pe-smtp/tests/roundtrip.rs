//! Messages built here and read back with pe-mime's parser (a port of postal-mime) come out as they went in:
//! names, subjects and bodies in many scripts and lengths, attachments with awkward names, inline images.

use pe_mime::Address;
use pe_mime::parser::{ParsedAddress, parse};
use pe_smtp::{Attachment, Message, build};

const TEXTS: &[&str] = &[
    "plain ASCII",
    "Tere õhtust, kuidas läheb?",
    "Привет мир",
    "日本語のテキスト",
    "emoji 😀🎉 and more",
    "quote \" and backslash \\",
    // not "=?utf-8?q?x?=": nodemailer writes ASCII that looks like an encoded word as it is, and readers decode it
    "  spaces  around  ",
];

fn mailbox(name: &str, address: &str) -> ParsedAddress {
    ParsedAddress::Mailbox(Address {
        name: name.into(),
        address: address.into(),
    })
}

fn body(seed: &str, lines: usize) -> String {
    (0..lines)
        .map(|i| format!("{seed} {i} {}\n", "pikk rida ".repeat(i % 12)))
        .collect()
}

#[test]
fn headers_and_bodies_survive() {
    for (i, subject) in TEXTS.iter().enumerate() {
        for long in [false, true] {
            let subject = if long { subject.repeat(9) } else { subject.to_string() };
            let text = body(&subject, 1 + i * 7);
            let message = Message {
                from: Address {
                    name: TEXTS[(i + 1) % TEXTS.len()].trim().into(),
                    address: "sender@example.com".into(),
                },
                to: vec![
                    mailbox(TEXTS[(i + 2) % TEXTS.len()].trim(), "to@example.com"),
                    mailbox("", "other@example.com"),
                ],
                subject: subject.clone(),
                text: Some(text.clone()),
                html: (i % 2 == 0).then(|| format!("<p>{}</p>", subject.replace('<', "&lt;"))),
                date: 1_759_744_800,
                ..Default::default()
            };
            let built = build(&message);
            let parsed = parse(&built.raw).unwrap();
            // white space at the ends of a header is not kept by any reader
            assert_eq!(parsed.subject.as_deref(), Some(subject.trim()), "subject {subject:?}");
            let Some(ParsedAddress::Mailbox(from)) = parsed.from else {
                panic!("from")
            };
            assert_eq!(from.name, message.from.name, "from name");
            assert_eq!(parsed.to, message.to, "to");
            assert_eq!(
                parsed.text.as_deref().map(|t| t.replace("\r\n", "\n")),
                Some(text.clone()),
                "text of {subject:?}"
            );
            assert_eq!(parsed.message_id.as_deref(), Some(built.message_id.as_str()));
            assert_eq!(parsed.timestamp, Some(1_759_744_800));
            for line in String::from_utf8_lossy(&built.raw).split("\r\n") {
                assert!(line.len() <= 998, "line of {} bytes", line.len());
            }
        }
    }
}

#[test]
fn attachments_survive() {
    let names = [
        "report.pdf",
        "õunad ja pirnid väga pika failinimega dokument.txt",
        "日本語のファイル名.docx",
        "quote\"and;semicolon=.bin",
        &"x".repeat(150),
    ];
    let content: Vec<u8> = (0..=255u8).cycle().take(5000).collect();
    let message = Message {
        from: Address {
            name: String::new(),
            address: "a@example.com".into(),
        },
        to: vec![mailbox("", "b@example.com")],
        subject: "files".into(),
        text: Some("see attached\n".into()),
        html: Some("<p>logo <img src=\"cid:logo@x\"></p>".into()),
        attachments: names
            .iter()
            .map(|name| Attachment {
                filename: name.to_string(),
                content_type: "application/octet-stream".into(),
                content: content.clone(),
                content_id: None,
            })
            .chain([Attachment {
                filename: "logo.png".into(),
                content_type: "image/png".into(),
                content: vec![0x89, b'P', b'N', b'G'],
                content_id: Some("logo@x".into()),
            }])
            .collect(),
        date: 0,
        ..Default::default()
    };
    let parsed = parse(&build(&message).raw).unwrap();
    assert_eq!(parsed.attachments.len(), names.len() + 1);
    for (attachment, name) in parsed.attachments.iter().filter(|a| !a.related).zip(names) {
        assert_eq!(attachment.filename.as_deref(), Some(name));
        assert_eq!(attachment.content, content);
    }
    let logo = parsed.attachments.iter().find(|a| a.related).expect("inline image");
    assert_eq!(logo.content_id.as_deref(), Some("<logo@x>"));
    assert!(parsed.html.unwrap().contains("cid:logo@x"));
}
