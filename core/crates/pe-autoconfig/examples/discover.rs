//! Looks up the servers of an address: `cargo run -p pe-autoconfig --example discover -- user@example.com`. With
//! a password as well (`-- user@example.com password`, or in `PE_PASSWORD`), Autodiscover may use it on a server
//! that asks for it.

#[tokio::main(flavor = "current_thread")]
async fn main() {
    let mut args = std::env::args().skip(1);
    let email = args.next().unwrap_or_else(|| "someone@gmail.com".into());
    let password = args.next().or_else(|| std::env::var("PE_PASSWORD").ok());
    let found = match password {
        Some(password) => {
            let credentials = pe_autoconfig::Credentials { user: None, password };
            pe_autoconfig::discover_with_credentials(&email, &credentials).await
        }
        None => pe_autoconfig::discover(&email).await,
    };
    match found {
        Some(settings) => println!("{settings:#?}"),
        None => println!("{email} has no domain"),
    }
}
