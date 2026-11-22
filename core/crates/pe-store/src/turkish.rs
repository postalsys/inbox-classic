//! Turkish's two i's in what the store matches and orders: dotted İ/i and dotless I/ı are one letter to a search, the
//! message list's order and the address completion, whichever the user types, as a Turkish user expects of a program
//! that does not know it is in Turkish (the store lowercases with no locale); and every capital beside its small
//! letter in the list's order, in any alphabet.

use crate::test_support::{found, id_of, message_to, store_of, words};
use crate::{Card, IndexText, MessageInfo, Scope, Search, Sort, SortField, Store};

fn store() -> (Store, i64, i64) {
    store_of("ben@example.com.tr")
}

fn message(uid: u64, subject: &str, from: (&str, &str)) -> MessageInfo {
    message_to(uid, subject, from, "Ben <ben@example.com.tr>")
}

/// Turkish mail: the words in each of their cases
fn turkish_mail(store: &Store, inbox: i64) {
    store
        .add_messages(
            inbox,
            &[
                message(1, "İstanbul toplantısı", ("İlker Yıldız", "ilker@example.com.tr")),
                message(2, "IŞIK faturası", ("Işıl Çelik", "isil@example.com.tr")),
                message(3, "ışık ve gölge", ("ŞULE IRMAK", "sule@example.com.tr")),
                message(4, "Ankara gezisi", ("Ayşe Kaya", "ayse@example.com.tr")),
                message(5, "istanbul notları", ("Zeynep Öz", "zeynep@example.com.tr")),
                message(6, "Zeytin hasadı", ("Ümit Işık", "umit@example.com.tr")),
            ],
        )
        .unwrap();
}

#[test]
fn search_takes_dotted_and_dotless_i_alike() {
    let (store, inbox, _) = store();
    turkish_mail(&store, inbox);
    // the text of a message read, its body as the index takes it
    let id = id_of(&store, inbox, 4);
    store
        .set_indexed(
            id,
            &IndexText {
                body: "Yarın KIZILAY meydanında buluşalım, sonra Ilgaz dağına çıkarız.".into(),
                ..Default::default()
            },
        )
        .unwrap();
    let found = |text: &str| found(&store, &words(Some(inbox), text));
    // İstanbul as it is typed: lower case, upper case, with the dotless capital of a keyboard without Turkish keys
    for typed in ["istanbul", "İstanbul", "İSTANBUL", "ISTANBUL", "ist"] {
        assert_eq!(found(typed), [1, 5], "{typed}");
    }
    // ışık in its cases, and without the Turkish letters
    for typed in ["ışık", "IŞIK", "Işık", "isik", "ışı"] {
        assert_eq!(found(typed), [2, 3, 6], "{typed}");
    }
    // the from:, subject: and the other terms of a column
    for typed in ["from:ilker", "from:İLKER", "from:yildiz", "from:YILDIZ", "from:yıldız"] {
        assert_eq!(found(typed), [1], "{typed}");
    }
    for typed in [
        "from:ışıl",
        "from:IŞIL",
        "from:isil",
        "from:ırmak",
        "from:IRMAK",
        "from:irmak",
    ] {
        assert!(!found(typed).is_empty(), "{typed}");
    }
    assert_eq!(found("from:ışıl"), [2]);
    assert_eq!(found("from:ırmak"), [3]);
    for typed in ["subject:ışık", "subject:IŞIK", "subject:\"ışık ve\""] {
        assert_eq!(
            found(typed),
            if typed.contains(" ve") { vec![3] } else { vec![2, 3] },
            "{typed}"
        );
    }
    assert_eq!(found("to:ben"), [1, 2, 3, 4, 5, 6]);
    // the text of the message: KIZILAY and Ilgaz in capitals, typed in lower case
    for typed in ["kızılay", "kizilay", "KIZILAY", "ılgaz", "ilgaz"] {
        assert_eq!(found(typed), [4], "{typed}");
    }
    // the other Turkish letters by their case, as for every language
    assert_eq!(found("şule"), [3]);
    assert_eq!(found("ÇELİK"), [2]);
    assert_eq!(found("ümit"), [6]);
}

#[test]
fn the_list_orders_dotted_and_dotless_i_together() {
    let (store, inbox, _) = store();
    turkish_mail(&store, inbox);
    let order = |field: SortField| -> Vec<u64> {
        let search = Search {
            scope: Scope::Folder(inbox),
            ..Default::default()
        };
        store
            .search(&search, Sort { field, ascending: true }, 0, 100)
            .unwrap()
            .iter()
            .map(|m| m.info.uid)
            .collect()
    };
    // Ankara, then the i's of either kind together (ışık and IŞIK side by side, İstanbul and istanbul), then Zeytin:
    // İstanbul is not after Z as its bytes would have it
    let subjects = order(SortField::Subject);
    assert_eq!(subjects.first(), Some(&4), "{subjects:?}");
    assert_eq!(subjects.last(), Some(&6), "{subjects:?}");
    let place = |uid: u64| subjects.iter().position(|u| *u == uid).unwrap();
    assert_eq!(place(1).abs_diff(place(5)), 1, "İstanbul beside istanbul: {subjects:?}");
    assert_eq!(place(2).abs_diff(place(3)), 1, "IŞIK beside ışık: {subjects:?}");
    // by sender: Ayşe, then İlker and Işıl among the I's
    let senders = order(SortField::From);
    assert_eq!(senders.first(), Some(&4), "{senders:?}");
    let place = |uid: u64| senders.iter().position(|u| *u == uid).unwrap();
    assert!(place(1) < 3 && place(2) < 3, "İlker and Işıl after Ayşe: {senders:?}");
    // the same orders by conversation
    let threads = |field: SortField| -> Vec<u64> {
        let search = Search {
            scope: Scope::Folder(inbox),
            threads: Some(Vec::new()),
            ..Default::default()
        };
        store
            .search(&search, Sort { field, ascending: true }, 0, 100)
            .unwrap()
            .iter()
            .map(|m| m.info.uid)
            .collect()
    };
    assert_eq!(threads(SortField::Subject), subjects);
    assert_eq!(threads(SortField::From), senders);
}

#[test]
fn the_list_orders_every_capital_with_its_small_letter() {
    let (store, inbox, _) = store();
    // pairs that differ only in the case of their first letter, beyond ASCII: Turkish Ç, Ş, Ö, French É, Cyrillic М
    let pairs = [
        ("Çiçek siparişi", "çay saati"),
        ("Şubat raporu", "şirket gezisi"),
        ("Ödeme planı", "öğle yemeği"),
        ("École d'été", "élection du bureau"),
        ("Москва", "мир"),
    ];
    let mut messages = vec![
        message(1, "Ankara", ("Ayşe", "a@example.com.tr")),
        message(2, "Zeytin", ("Zeki", "z@example.com.tr")),
    ];
    for (index, (upper, lower)) in pairs.iter().enumerate() {
        let uid = 10 + index as u64 * 2;
        messages.push(message(uid, upper, (upper, "u@example.com.tr")));
        messages.push(message(uid + 1, lower, (lower, "l@example.com.tr")));
    }
    store.add_messages(inbox, &messages).unwrap();
    for field in [SortField::Subject, SortField::From] {
        for threads in [None, Some(Vec::new())] {
            let search = Search {
                scope: Scope::Folder(inbox),
                threads: threads.clone(),
                ..Default::default()
            };
            let order: Vec<u64> = store
                .search(&search, Sort { field, ascending: true }, 0, 100)
                .unwrap()
                .iter()
                .map(|m| m.info.uid)
                .collect();
            let place = |uid: u64| order.iter().position(|u| *u == uid).unwrap();
            for index in 0..pairs.len() as u64 {
                let uid = 10 + index * 2;
                assert_eq!(
                    place(uid).abs_diff(place(uid + 1)),
                    1,
                    "{field:?} {:?}: a capital beside its small letter: {order:?}",
                    threads.is_some()
                );
            }
        }
    }
}

#[test]
fn completion_takes_dotted_and_dotless_i_alike() {
    let (store, inbox, sent) = store();
    turkish_mail(&store, inbox);
    let mut written = message(1, "", ("Ben", "ben@example.com.tr"));
    written.correspondents = vec![("İbrahim Işıklı".into(), "ibrahim@example.com.tr".into())];
    store.add_messages(sent, &[written]).unwrap();
    store
        .save_card(&Card {
            name: "IRMAK İnci".into(),
            addresses: vec!["irmak@example.com.tr".into()],
            ..Default::default()
        })
        .unwrap();
    store
        .save_card(&Card {
            name: "Çağlar Ilıcak".into(),
            addresses: vec!["caglar@example.com.tr".into()],
            ..Default::default()
        })
        .unwrap();
    let contacts = |typed: &str| -> Vec<String> {
        let mut found: Vec<String> = store
            .contacts_matching(typed, 10)
            .unwrap()
            .into_iter()
            .map(|c| c.address)
            .collect();
        found.sort();
        found
    };
    // a name's start or a word's in it, by either i and either case
    for typed in ["ilker", "İlker", "ILKER", "il"] {
        assert_eq!(contacts(typed), ["ilker@example.com.tr"], "{typed}");
    }
    for typed in ["yıldız", "yildiz", "YILDIZ"] {
        assert_eq!(contacts(typed), ["ilker@example.com.tr"], "{typed}");
    }
    // (by its case: the other letters as they are, ş not s, as in every language)
    for typed in ["ışıl", "IŞIL", "Işıl", "işil"] {
        assert_eq!(contacts(typed), ["isil@example.com.tr"], "{typed}");
    }
    for typed in ["ırmak", "irmak", "Irmak"] {
        assert_eq!(contacts(typed), ["sule@example.com.tr"], "{typed}");
    }
    // the other Turkish capitals by their small letters
    assert_eq!(contacts("şule"), ["sule@example.com.tr"]);
    assert_eq!(contacts("çelik"), ["isil@example.com.tr"]);
    assert_eq!(contacts("ümit"), ["umit@example.com.tr"]);
    for typed in ["ibrahim", "İBRAHİM", "ışıklı", "IŞIKLI", "işikli"] {
        assert_eq!(contacts(typed), ["ibrahim@example.com.tr"], "{typed}");
    }
    // the address book's cards
    let book = |typed: &str| -> Vec<String> {
        store
            .book_matching(typed, 10)
            .unwrap()
            .0
            .into_iter()
            .map(|(_, address)| address)
            .collect()
    };
    for typed in ["ırmak", "irmak", "inci", "İnci", "ınci"] {
        assert_eq!(book(typed), ["irmak@example.com.tr"], "{typed}");
    }
    for typed in ["çağlar", "ÇAĞLAR", "ılıcak", "ilicak", "ILICAK"] {
        assert_eq!(book(typed), ["caglar@example.com.tr"], "{typed}");
    }
}
