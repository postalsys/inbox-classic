//! Prints what the parser makes of a message file: `cargo run -p pe-mime --example parse -- file.eml`
fn main() {
    let path = std::env::args().nth(1).expect("a message file");
    let raw = std::fs::read(path).expect("readable file");
    match pe_mime::parser::parse(&raw) {
        Ok(message) => {
            println!("subject: {:?}", message.subject);
            println!("text:\n{}", message.text.unwrap_or_default());
            println!("html:\n{}", message.html.unwrap_or_default());
            for attachment in message.attachments {
                println!(
                    "attachment: {:?} {} {} bytes",
                    attachment.filename,
                    attachment.mime_type,
                    attachment.content.len()
                );
            }
        }
        Err(error) => println!("error: {error}"),
    }
}
