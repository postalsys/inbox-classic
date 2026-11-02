//! Looks up the servers of an address: `cargo run -p pe-autoconfig --example discover -- user@example.com`

#[tokio::main(flavor = "current_thread")]
async fn main() {
    let email = std::env::args().nth(1).unwrap_or_else(|| "someone@gmail.com".into());
    match pe_autoconfig::discover(&email).await {
        Some(settings) => println!("{settings:#?}"),
        None => println!("{email} has no domain"),
    }
}
