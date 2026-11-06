//! What the core says in another language. A binary of its own: the language is the whole process's, and the other
//! tests expect English.

use pe_core::i18n;

#[test]
fn the_core_speaks_the_language_set() {
    // English to begin with, as the other tests have it
    assert_eq!(
        pe_core::list_counts(12, 3, 2, false),
        "12 messages, 3 unread, 2 selected"
    );
    assert_eq!(pe_core::list_counts(1, 0, 1, false), "1 message, 0 unread");
    assert_eq!(pe_core::format_size(2_621_440), "2.5 MB");

    assert_eq!(i18n::set_language("de-DE"), "de");
    assert_eq!(
        pe_core::list_counts(12, 3, 2, false),
        "12 Nachrichten, 3 ungelesen, 2 ausgewählt"
    );
    assert_eq!(pe_core::list_counts(1, 0, 0, false), "1 Nachricht, 0 ungelesen");
    assert_eq!(pe_core::format_size(2_621_440), "2,5 MB");
    assert_eq!(pe_core::format_size(1), "1 Byte");
    let page = pe_core::reader_page(pe_core::ReaderState::NoMessage);
    assert!(page.contains("Es ist keine Nachricht ausgewählt."), "{page}");
    // the quote header of a reply follows the language; Re: and Fw: do not (the core's compose keeps them)
    let quote = pe_html::quote_html(&[("Von", "Ann".to_string())], "<p>Hi</p>", &[], true);
    assert!(quote.contains("----- Ursprüngliche Nachricht -----"), "{quote}");
    let (title, detail) = pe_core::agents::connect_text(&pe_core::agents::HostInfo {
        path: "/x".into(),
        name: "Claude".into(),
    });
    assert_eq!(title, "Claude möchte Ihre E-Mail verwenden");
    assert!(detail.contains("ändern.\n\nAgenten lesen"), "{detail}");

    // what came with several messages, moves and files
    assert_eq!(pe_core::list_counts(4, 1, 0, true), "4 gefunden, 1 ungelesen");
    assert_eq!(pe_core::list_counts(0, 0, 0, true), "Keine Nachrichten gefunden");
    let summary = pe_core::Summary {
        count: 3,
        unread: 2,
        ..Default::default()
    };
    assert_eq!(summary.title(), "3 Nachrichten ausgewählt");
    assert_eq!(summary.move_title(false), "3 Nachrichten verschieben");
    assert_eq!(
        summary.move_prompt(true),
        "Die 3 ausgewählten Nachrichten kopieren nach:"
    );
    assert_eq!(
        pe_core::saved_text(3, std::path::Path::new("/tmp/Desktop")),
        "3 Nachrichten in Desktop gespeichert"
    );
    assert_eq!(pe_core::color_name(pe_core::FlagColor::Purple), "Lila");
    // a flag sentence takes the colour's form of the language, not the English name lowercased
    let flagged = i18n::tr_args(
        i18n::Text::DoneFlaggedColor,
        &[("messages", "2 Nachrichten".into()), ("color", "blue".into())],
    );
    assert_eq!(flagged, "2 Nachrichten blau gekennzeichnet");

    assert_eq!(i18n::set_language("et"), "et");
    assert_eq!(pe_core::color_name(pe_core::FlagColor::Purple), "Lilla");
    assert_eq!(summary.move_title(true), "Kopeeri 3 kirja");
    assert_eq!(pe_core::list_counts(5, 1, 0, false), "5 kirja, 1 lugemata");
    assert_eq!(pe_core::format_size(3000), "3 KB");

    assert_eq!(i18n::set_language("fr"), "fr");
    assert_eq!(pe_core::format_size(2_621_440), "2,5 Mo");
    // French counts 0 as one
    assert_eq!(pe_core::messages(0), "0 message");
    assert_eq!(pe_core::color_name(pe_core::FlagColor::Gray), "Gris");

    // the help in the language, its keys as its keyboards name them; English for a language without one
    i18n::set_language("de");
    let help = pe_html::help_page(pe_html::Platform::Windows);
    assert!(help.contains("<kbd>Strg</kbd>"), "keys named for a German keyboard");
    assert!(!help.contains("<kbd>Ctrl</kbd>"));
    let mac = pe_html::help_page(pe_html::Platform::Mac);
    assert!(mac.contains("<kbd>\u{2318}</kbd>") && !mac.contains("Strg"));
    assert!(pe_html::help_page_in(pe_html::Platform::Linux, "pt").contains("<h2>Contents</h2>"));

    // back to English, which the pseudo-language is made from
    i18n::set_language("qps");
    assert!(pe_core::messages(3).starts_with("[3 "));
    i18n::set_language("en");
    assert_eq!(pe_core::messages(3), "3 messages");
    assert_eq!(pe_core::color_name(pe_core::FlagColor::Purple), "Purple");
    assert_eq!(pe_core::list_counts(2, 0, 2, true), "2 found, 0 unread, 2 selected");
}
