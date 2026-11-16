# Translation glossary

The words of the windows live in the Fluent files of this folder, one folder a language: `core.ftl` for what the core
says (the same on every platform), `app.ftl` for the windows (menus, commands, dialogs, and the words the windows of
more than one platform share, `ui-` ids), and `windows.ftl`, `mac.ftl` and `linux.ftl` for words only one platform
has. English (`en`) is the source; a word a language does not have yet is shown in English. The user help is
`core/crates/pe-html/help/<lang>/<topic>.html`.

**Status: the German, Estonian, French and Spanish files and help pages have had a native review; the other languages
are drafts marked for review (below). A change to the English words needs the same review in every language before a
release.**

**Adding a language.** Its catalogs (`core/locales/<code>/`, every file English has), its help
(`core/crates/pe-html/help/<code>/`, every topic), both marked for review, and its line in `pe_i18n::LANGUAGES`
(`core/crates/pe-i18n/src/lib.rs`: its tag and the language's name in itself). The tag is the language's two letters,
with a region or script where the language is written differently there (`pt-BR`, `sr-Latn`): a system's language is
matched by its language, then its region or script, then the language's own catalog (`pt` for any Portuguese but
Brazil's), then its first (`sr-Latn` for any Serbian). `node
scripts/check-language.mjs <code>` checks the catalogs and the help against English first. Everything else follows the
list: building the core writes the installer's languages, the sign-in buttons' Windows resources and the Linux desktop
entry and metainfo again (commit them), and `scripts/build-sign-in-buttons.sh` makes the language's sign-in button
pictures (commit them too); the Mac's localizations, the Help Books, the homepage's help and the UI tests read the list
themselves.

**Drafts waiting for review.** `REVIEWED` holds the commit of the last native review. A message translated after it
(new, or its English changed) has `# review: new` or `# review: changed` on the line above it, and a new or changed
passage of a help page sits between `<!--review-->` and `<!--/review-->` (the page shows it without them). `node
scripts/i18n-review.mjs` lists them (`--html out.html` as a page with the English beside each draft); `--check`, which
CI runs, fails when a new or changed message or passage has no mark. Remove a mark once its draft is reviewed, and when
none are left, put that commit in `REVIEWED`.

Rules for every language:

- Keep the `{ $placeables }` the English message has, no more and no fewer (a test checks it); put them where the
  language needs them.
- `$messages` is already a localized count, such as "1 message" or "2 messages". It is not a bare number. Where
  the language would need a different case, rephrase the sentence instead of adding an ending to the placeholder.
  `$folder` can also be the localized `their-folders` or `transfer-another-account`, so destination wording must
  work with those values as well as actual folder names.
- Plurals: use the categories of the language (`[one]`, `[few]`, `[many]`, `*[other]`, as CLDR has them); `*[other]`
  is the default.
- French `[one]` also covers zero. Use the count placeholder, not a literal `1`, unless an explicit `[0]` branch
  handles zero. Empty address-book groups and imports or exports with no contacts can display these messages.
- Counts in the same message are independent: agreement for unread, selected or failed items follows that count,
  not the total number of messages or files.
- An `&` marks the menu letter on Windows and Linux; choose a letter of your own word, different within one menu.
- No en or em dashes (a test checks it): commas, colons or separate sentences instead.
- "Re: " and "Fw: " in the subjects of replies and forwards stay English in every language (every mail program
  threads by them); the "Original Message" block of a reply follows the language.
- Keys in the help stay `<kbd>Ctrl</kbd>`, `<kbd>Shift</kbd>`, `<kbd>Alt</kbd>`, `<kbd>Del</kbd>`, `<kbd>Enter</kbd>`
  in every language: the page names them as the keyboard does (`key-*` in `core.ftl`, and the Mac's symbols there).

## Fixed terms

The terms of Outlook Express and Outlook in each language, kept the same everywhere.

| English            | Deutsch                 | Eesti                       | Français                      | Español                        |
| ------------------ | ----------------------- | --------------------------- | ----------------------------- | ------------------------------ |
| Inbox              | Posteingang             | Sisendkaust                 | Boîte de réception            | Bandeja de entrada             |
| Outbox             | Postausgang             | Väljundkaust                | Boîte d'envoi                 | Bandeja de salida              |
| Sent Items         | Gesendete Objekte       | Saadetud kirjad             | Éléments envoyés              | Elementos enviados             |
| Deleted Items      | Gelöschte Objekte       | Kustutatud kirjad           | Éléments supprimés            | Elementos eliminados           |
| Drafts             | Entwürfe                | Mustandid                   | Brouillons                    | Borradores                     |
| Junk E-mail        | Junk-E-Mail             | Rämpspost                   | Courrier indésirable          | Correo no deseado              |
| Archive            | Archiv                  | Arhiiv                      | Archives                      | Archivo                        |
| All Inboxes        | Alle Posteingänge       | Kõik sisendkaustad          | Toutes les boîtes             | Todas las bandejas de entrada  |
| message            | Nachricht               | kiri                        | message                       | mensaje                        |
| folder             | Ordner                  | kaust                       | dossier                       | carpeta                        |
| account            | Konto                   | konto                       | compte                        | cuenta                         |
| attachment         | Anlage                  | manus                       | pièce jointe                  | archivo adjunto                |
| flag               | Kennzeichnung           | lipp                        | indicateur                    | marca                          |
| Send/Recv          | Senden/Empfangen        | Saada/Võta vastu            | Envoyer/Recevoir              | Enviar y recibir               |
| Reply to Sender    | Antworten               | Vasta saatjale              | Répondre à l'expéditeur       | Responder al remitente         |
| Reply to All       | Allen antworten         | Vasta kõigile               | Répondre à tous               | Responder a todos              |
| Forward            | Weiterleiten            | Edasta                      | Transférer                    | Reenviar                       |
| Mark as Junk       | Als Junk markieren      | Märgi rämpspostiks          | Marquer comme indésirable     | Marcar como correo no deseado  |
| Mark as Not Junk   | Als kein Junk markieren | Märgi tavapostiks           | Marquer comme non indésirable | Marcar como correo deseado     |
| Move to Folder     | In Ordner verschieben   | Teisalda kausta             | Déplacer vers un dossier      | Mover a carpeta                |
| Copy to Folder     | In Ordner kopieren      | Kopeeri kausta              | Copier vers un dossier        | Copiar a carpeta               |
| Undo               | Rückgängig              | Võta tagasi                 | Annuler                       | Deshacer                       |
| Select All         | Alles auswählen         | Vali kõik                   | Sélectionner tout             | Seleccionar todo               |
| Recent             | Zuletzt verwendet       | Viimati kasutatud           | Récents                       | Recientes                      |
| Flag (menu)        | Kennzeichnung           | Lipp                        | Indicateur                    | Marca                          |
| Clear Flag         | Kennzeichnung löschen   | Eemalda lipp                | Effacer l'indicateur          | Quitar marca                   |
| Red                | Rot                     | Punane                      | Rouge                         | Rojo                           |
| Orange             | Orange                  | Oranž                       | Orange                        | Naranja                        |
| Yellow             | Gelb                    | Kollane                     | Jaune                         | Amarillo                       |
| Green              | Grün                    | Roheline                    | Vert                          | Verde                          |
| Blue               | Blau                    | Sinine                      | Bleu                          | Azul                           |
| Purple             | Lila                    | Lilla                       | Violet                        | Morado                         |
| Gray               | Grau                    | Hall                        | Gris                          | Gris                           |
| sign-in app        | Anmelde-App             | sisselogimisrakendus        | application de connexion      | aplicación de inicio de sesión |
| AI agent           | KI-Agent                | tehisintellekti agent       | agent d'IA                    | agente de IA                   |
| client ID          | Client-ID               | kliendi ID                  | ID client                     | ID de cliente                  |
| client secret      | Client-Geheimnis        | kliendi saladus             | secret client                 | secreto de cliente             |
| issuer (OAuth)     | Aussteller              | väljaandja                  | émetteur                      | emisor                         |
| scopes (OAuth)     | Berechtigungen (Scopes) | juurdepääsuõigused (scopes) | autorisations (scopes)        | permisos (scopes)              |
| Address Book       | Adressbuch              | Aadressiraamat              | Carnet d'adresses             | Libreta de direcciones         |
| contact            | Kontakt                 | kontakt                     | contact                       | contacto                       |
| group              | Gruppe                  | grupp                       | groupe                        | grupo                          |
| File > Accounts    | Datei > Konten          | Fail > Kontod               | Fichier > Comptes             | Archivo > Cuentas              |
| Tools              | Extras                  | Tööriistad                  | Outils                        | Herramientas                   |
| Ctrl / Shift / Del | Strg / Umschalt / Entf  | Ctrl / Shift / Del          | Ctrl / Maj / Suppr            | Ctrl / Mayús / Supr            |

Forms of address: German uses "Sie", French "vous", Spanish "usted", Estonian the polite plural ("teie").

### Estonian encryption and settings transfer

- Use the polite plural in explanations and questions; short commands stay imperative ("Impordi", "Kontrolli").
- Use "krüpteerima", "avalik võti", "privaatvõti" and "võtme sõrmejälg" consistently. Key verification means
  comparing the fingerprint with the owner, not merely checking a cryptographic signature.
- Use "parool" for the password protecting a key backup or settings file, as in the existing key dialogs.
  "Sisselogimisandmed" includes saved sign-in tokens; it does not mean only a login password.
- A list of addresses must work for one or several entries. Introduce it with a colon instead of forcing a
  singular case onto the placeholder. Contact names can be placed in parentheses to avoid requiring inflection.

### Spanish encryption and settings transfer

- Use "contraseña" for the password protecting a key backup or settings export, as in the account dialogs.
- Use "huella digital" for a key fingerprint. Verifying a key means confirming its owner by comparing the
  fingerprint; checking a message signature alone does not confirm the owner.
- "Datos de acceso" includes saved sign-in tokens as well as passwords. After an unprotected export, the user
  must sign in again, which may use a browser rather than a password prompt.

Context notes:

- Search covers subjects, senders, recipients, attachment names and message text. Name those fields rather than
  translating the English draft's vague "people" literally.
- An agent's message shown in the Outbox is queued for a delayed send. It has not been sent yet.
- Undo Send cancels a message during the delay before sending and reopens it for editing. It does not recall
  delivered mail. `$subject` in send-status messages is already quoted by the caller.
- Message rules process new Inbox messages in list order while the app runs. Matching rules accumulate their
  actions until one moves the message out of the Inbox. `ui-col-rule-matches` labels the search criteria, not a count.
- The sender-address error should name the actual `ui-field-other-addresses` field in account properties.
- Text size changes the display zoom for reading and composing, not the formatting recipients see. Dark mode
  concerns background colors, not encryption; messages with their own backgrounds retain their design unless
  they provide a dark version.
- Removing an agent program deletes its permissions and activity history; the next connection asks for permission
  again. Clearing the history alone does not undo the agents' changes.
- `folder-holds-no-messages` refers to a folder that cannot contain messages (IMAP `\Noselect`), not an empty folder.
- Provider sign-in prompts also receive `ui-the-provider` when the provider has no known name. The sentence must
  work with both this fallback and names such as Google or Microsoft, without requiring an inflected name.
- `ui-event-span` joins dates or date-and-time values; for a same-day event, `$end` is just a time.
- `agent-original-not-downloaded` applies to both replies and forwards.
- Keep help references to menu items and buttons in sync when changing their labels.
- `ui-pictures-*` and the trusted-sender settings concern external images inside messages. `ui-list-pictures-*`
  concerns the sender's picture beside a message: a verified brand logo, then an Address Book picture for a verified
  sender domain, otherwise initials. Do not describe these as the same kind of picture.
- `ui-download-limit` labels a storage-size selector (MB or GB) for each account. Exceeding the limit removes local
  downloaded copies; the messages remain on the server and can be downloaded again.
- `ui-picture-too-large` applies to an Address Book picture: at most 10 MB, with both width and height at most 8000
  pixels. These are upper limits, not required dimensions.
- "Contact" and "group" are a person and a group of the Address Book (Tools > Address Book), not the people Inbox
  Classic offers on its own when an address is typed.

Notes for translators:

- Colours in sentences ("Flagged 2 messages blue") take the language's own form through a selector on the colour (`done-flagged-color`), never the English name lowercased.
- Status texts that name a number of messages ("{ $messages } déplacés vers") choose by `$count` so the words agree
  with it (`[one]` and `*[other]`, more forms where the language has them); English has the one form under `*[other]`.

## Notes per language

Each new language's key terms and the rules its draft follows, for its reviewer.

### Català (ca)

Terms: Safata d’entrada; Safata de sortida; Elements enviats; Elements suprimits; Esborranys; Correu brossa; Arxiu;
Totes les safates d’entrada; missatge; carpeta; compte (m.); fitxer adjunt (short: adjunt); bandera (Marca amb bandera,
Treu la bandera); Respon al remitent; Respon a tothom; Reenvia; Envia/Rep; Marca com a correu brossa / Marca com a correu legítim;
Mou a la carpeta... / Copia a la carpeta...; Desfés; Selecciona-ho tot; Recents; Llibreta d’adreces; contacte; grup;
conversa; Fitxer > Comptes; Eines; Opcions (Windows), Configuració (Mac), Preferències (Linux); De / Per a / Cc / Cco /
Assumpte; contrasenya; servidor; baixar (download), pujar (upload); iniciar la sessió (sign in); aplicació d’inici de
sessió; agent d’IA; identificador de client; secret de client; emissor; permisos (scopes).

Encryption: clau (pública, privada), empremta digital, signat / signatura, xifrat / xifrar / desxifrar, frase de pas
(passphrase, as GnuPG and Thunderbird in Catalan), OpenPGP, certificat.

Colours (agree with the feminine "bandera"): vermella, taronja, groga, verda, blava, porpra, grisa.

Plurals: `[one]` (exactly 1) and `*[other]` (0, 2 and more). A literal 1 in `[one]` is fine.

- Menus and buttons in the imperative second person singular, as Softcatalà and Microsoft do ("Obre", "Desa",
  "Imprimeix", "Surt"); sentence case.
- Prose addresses the user with "vós" as Softcatalà and Mozilla do ("Feu clic", "Escriviu", "el vostre compte").
- No elided article or "de" before a placeable (l’, d’): a head noun goes between ("del compte { $account }", "de la
  carpeta { $folder }", "el missatge { $subject }"), or a label and colon ("Destinació: { $folder }").
- `$messages` status lines put the count after a colon or choose the participle by `$count` ("Mogut" / "Moguts");
  `their-folders` = "les seves carpetes", `transfer-another-account` = "un altre compte", both fitting "a { $folder }".
- Quotes « » (and “ ” inside them), apostrophe ’ (U+2019) everywhere; day names lowercase.
- Keys in catalog prose Ctrl / Maj / Alt / Supr / Retorn; the help’s `<kbd>` keys stay English.
- "Re: " and "Fw: " stay; the reply header is "----- Missatge original -----".
- "Inbox Classic" takes no article ("d’Inbox Classic", "a Inbox Classic").
- The Mac's own system menus (mac.ftl) use macOS's Catalan infinitives ("Sortir d’Inbox Classic", "Retallar",
  "Enganxar"); the shared commands stay imperative.
- Raw network errors that the app shows in English ("connection error: …", "TLS error: …", "the server does not offer
  STARTTLS") are quoted in English in the help.
- Other words: testimoni (OAuth token), inquilí (Entra tenant), anell de claus (Linux keyring), Configuració del
  Sistema (macOS System Settings), subfinestra de lectura (reading pane), kB / MB / GB.
- Retain "bandera" for the coloured flag, "vós" in prose and "frase de pas" for protected backups/exports.
  Use "Marca com a correu brossa" / "Marca com a correu legítim" for the commands, "Brossa" / "No és brossa" in
  the compact toolbar. The macOS system commands retain their native infinitives.
- Rules "processen" messages; "ordenen" is reserved for sorting a list. Additional sender addresses use the
  label "Altres adreces d’enviament", also named in the corresponding core error.
- Use "credencials d’inici de sessió" when passwords and OAuth tokens are both included. Unprotected exports
  require signing in again, possibly through the browser. Distinguish "signatura digital" from account signatures.
- Provider prompts use the provider name followed by a colon so named providers and the fallback work without
  changing the article or preposition. Cc/Cco controls use Alt+C / Alt+O on Windows and Linux.

### Čeština (cs)

Terms: Doručená pošta; Pošta k odeslání; Odeslaná pošta; Odstraněná pošta; Koncepty; Nevyžádaná pošta; zpráva;
složka; účet; příloha; příznak (Označit příznakem, Zrušit příznak); Odpovědět všem; Přeposlat.

Plurals: `[one]` 1, `[few]` 2 to 4, `*[other]` 0 and 5 or more; `[many]` (fractions only) is left out.

- Formal "vy" ("Zadejte", "Klikněte", "váš" lowercase); menu items and buttons in the infinitive ("Odpovědět",
  "Uložit"), only the first word capitalised, on the Mac too.
- Past participles agree by `$count` ("Přesunuta 1 zpráva", "Přesunuty 3 zprávy", "Přesunuto 5 zpráv"); `$messages`
  stays nominative ("Stahování: { $messages }").
- Folder names do not inflect: "(cíl: { $folder })", or "do složky { $folder }" only where `$folder` is always a real
  folder name; `their-folders` = "původní složky", `transfer-another-account` = "jiný účet".
- Quotes „…“; keys Ctrl / Shift / Del as on Czech keyboards.
- Rules process messages: "zpracovávat", not "třídit", because actions also include marking and notifications.
- Use "digitální podpis" for cryptographic signatures and "podpis" for text appended to a message.
  A valid signature and verified ownership of a key are separate states. "Otisk" identifies a key;
  a displayed key name can instead be an address or fingerprint, so phrase around it without inflection.
- Use "přihlašovací údaje" when passwords and browser/OAuth credentials are both meant. Transferred accounts
  without credentials need sign-in again, not necessarily a password prompt.
- Compose fields: "Kopie" and "Skrytá kopie" (Windows Alt+K / Alt+S). Address-book compose action:
  "Napsat zprávu". Native letters with diacritics are valid menu access keys; check all shared menus/dialogs.

### Dansk (da)

Terms: Indbakke; Udbakke; Sendt post; Slettet post; Kladder; Uønsket mail; meddelelse ("mail" as the mass noun);
mappe; konto (pl. konti); vedhæftet fil; flag (sætte flag på, Fjern flag); Svar alle; Videresend; Adressekartotek (as
Outlook Express).

- "du" everywhere; questions as "Vil du ...?"; menus and buttons in sentence case.
- Quotes »...«, apostrophe ’. No genitive -s on placeholders or provider names: "på webstedet for { $provider }",
  "nøglen tilhørende { $name }".
- Past-tense status lines agree with the count ("Markerede 1 meddelelse som læst" / "... som læste"); colours agree
  with the neuter "flag" ("Satte rødt/gult/grønt/blåt/gråt flag på").
- Keys Ctrl / Skift / Delete / Enter; Options, Settings and Preferences are all "Indstillinger".
- Review first: "meddelelse" versus "besked" or "e-mail", "Adressekartotek" versus "Adressebog", "adgangsfrase" for
  passphrase, "Legitimationsstyring" for the Credential Manager.

### Hrvatski (hr)

Terms: Ulazna pošta; Izlazna pošta; Poslane stavke; Izbrisane stavke; Skice; Neželjena e-pošta; poruka; mapa; račun;
privitak; zastavica (Označi zastavicom); Odgovori svima; Proslijedi.

Plurals: `[one]` 1, 21, 31...; `[few]` 2 to 4, 22 to 24...; `*[other]`. `[one]` never holds a literal 1: where English
means the single one with no number, an exact `[1]` branch comes first and `[one]` keeps `{ $count }`.

- Second person plural, lowercase ("vi", "vaš"), imperatives in -ite ("Kliknite", "Odaberite").
- `$messages` goes after a colon ("Premješteno: { $messages }") so no participle agrees with it.
- Destinations that can be `their-folders` or `transfer-another-account` read "(odredište: { $folder })"; otherwise
  the name follows "mapa" ("u mapi { $folder }", "u mapu { $folder }") and stays nominative.
- Quotes „…“; days of the week lowercase; keys Ctrl / Shift / Del.
- Folder names follow Outlook on every platform, not Apple Mail's "Smeće" and "Poslano".

### Italiano (it)

Terms: Posta in arrivo; Posta in uscita; Posta inviata; Posta eliminata; Bozze; Posta indesiderata; messaggio; cartella;
account (masculine, invariable); allegato; contrassegno (contrassegnare); Rispondi a tutti; Inoltra; Bcc: Ccn; unread:
"da leggere".

- Informal "tu" ("Fai clic", "Scegli", "Inserisci").
- Message rules "elaborano" messages; reserve "ordinare" for the display order of a message list.
- Translate blocklist as "lista di blocco". In count summaries, use singular agreement when one item is possible.
- Use "firma digitale" where needed to distinguish cryptographic signatures from account signatures.
- Keep "passphrase", "chiave privata", "chiave pubblica" and "impronta digitale" consistent; key verification
  confirms ownership and requires checking every listed address before confirming.
- Participles agreeing with `$messages` choose by `$count` ("spostato" / "spostati"); "messaggio" is masculine,
  "posta" feminine ("Segna come indesiderata").
- `their-folders` = "cartelle diverse", so "spostati in { $folder }" works without an article;
  `transfer-another-account` = "un altro account".
- Sentence case; folder names keep their capitals. Quotes “ ” and apostrophe ’.
- Keys in catalog prose Ctrl / Maiusc / Canc, help `<kbd>` stays English; the Help menu is "?" as Italian Windows
  writes it. Raw network errors ("TLS error") are quoted in English in the help.

### Latviešu (lv)

Terms: Iesūtne; Izsūtne; Nosūtītie vienumi; Izdzēstie vienumi; Melnraksti; Nevēlamais e-pasts; ziņojums; mape; konts;
pielikums; karodziņš (Atzīmēt ar karodziņu); Atbildēt visiem; Pārsūtīt; Cc / Bcc: Kopija / Diskrētā kopija.

Plurals: `[zero]` (n%10 = 0 or n%100 = 11 to 19, genitive plural "10 ziņojumu"), `[one]` (n%10 = 1 and n%100 != 11, so
also 21, 31, 101), `*[other]` ("2 ziņojumi"). `[one]` always uses `{ $count }`; an explicit `[1]` branch comes first
where the singular reads better ("Pārvietot ziņojumu").

- Polite plural "jūs" ("Noklikšķiniet", "Ievadiet"); menus and buttons in the infinitive, sentence case.
- A verb or participle next to `$messages` agrees through `$count` (`[one]` Pārvietots, `*[other]` Pārvietoti).
- After "uz" folder names stay nominative ("uz Arhīvs"), a compromise; `their-folders` = "to mapēm",
  `transfer-another-account` = "citu kontu".
- Quotes „…”; days of the week lowercase; keys unchanged.
- Access keys on ASCII letters only (no ā, č, ē and so on).

### Lietuvių (lt)

Terms: Gauti laiškai; Siunčiami laiškai; Išsiųsti laiškai; Panaikinti laiškai; Juodraščiai; Nepageidaujami laiškai;
laiškas; aplankas; paskyra; priedas; vėliavėlė (Žymėti vėliavėle); Atsakyti visiems; Persiųsti.

Plurals: `[one]` 1, 21, 31 (not 11); `[few]` 2 to 9, 22 to 29; `*[other]` 0, 10 to 20, 30 (genitive plural); `[many]`
(fractions only) is left out. `[one]` uses `{ $count }`, never a literal "1".

- Polite plural "jūs", lowercase; menu items and buttons are infinitives. Inbox Classic is feminine (programa).
- `$messages` goes after a colon ("Archyvuota: 3 laiškai"); destinations read "(paskirtis: { $folder })" rather than
  "į { $folder }".
- Account, domain and folder names never inflect: they follow a noun in the genitive ("paskyros { $account }"); special
  folders in running text are quoted (aplanke „Siunčiami laiškai“).
- `$provider` sentences use "svetainėje, kurią valdo { $provider }", so `ui-the-provider` fits too.
- Quotes „…“; `<kbd>` keys stay English.
- Review first: the "... laiškai" folder set (Lithuanian Outlook versions differ) and the "(paskirtis: ...)" pattern.

### Magyar (hu)

Terms: Beérkezett üzenetek; Postázandó üzenetek; Elküldött elemek; Törölt elemek; Piszkozatok; Levélszemét; üzenet;
mappa; fiók; melléklet; jelölő; Válasz mindenkinek; Továbbítás; Cc / Bcc: Másolat / Titkos másolat.

Plurals: `[one]` and `*[other]`; a noun after a number stays singular ("3 üzenet"), so both forms often look alike.

- Formal, impersonal ("Adja meg", "Kattintson", "Ön" avoided); buttons and menu items as nouns ("Áthelyezés").
- Placeables never take a case ending or postposition: rephrase with a colon ("Áthelyezve: { $messages }. Cél:
  { $folder }"). A name may stand as possessor ("{ $provider } webhelyén").
- `their-folders` = "eredeti mappáik", `transfer-another-account` = "másik fiók", both fitting "Cél: { $folder }".
- No "a(z)" before a placeable. In the help the article before a `data-text` word follows the Hungarian catalog value
  ("az Új levél") and must change if that word's first sound changes.
- Quotes „...”; Options, Settings and Preferences are all "Beállítások".

### Nederlands (nl)

Terms: Postvak IN; Postvak UIT; Verzonden items; Verwijderde items; Concepten; Ongewenste e-mail; bericht; map; account
(het account); bijlage; markering (markeren); Allen beantwoorden; Doorsturen.

- Informal "je"/"jouw", never "u"; imperatives in steps, infinitives for menu commands and buttons.
- Quotes ‘ ’ and “ ”, apostrophe ’; no genitive -’s on names, rephrase with "van". Compounds as Dutch spelling wants
  (AI-agent, client-ID, IMAP-server).
- Finished actions use the participle without a verb ("{ $messages } verplaatst naar ..."); ongoing ones choose
  "wordt/worden" by `$count`.
- Destinations read "naar { $folder }", which also works with `their-folders`.
- Message rules "verwerken" messages; reserve "sorteren" for the display order of a message list.
- Use "digitale handtekening" where needed to distinguish a cryptographic signature from the account signature
  added below a message. Key verification confirms ownership by comparing fingerprints.
- The account field for additional sender addresses is "Andere afzenderadressen". Refer to this exact label in
  errors and instructions.
- Keys Ctrl / Shift / Del as Dutch keyboards print them. Google's button "Inloggen met Google", Microsoft's
  "Aanmelden met Microsoft".

### Norsk bokmål (nb)

Terms: Innboks; Utboks; Sendte elementer; Slettede elementer; Utkast; Søppelpost; Arkiv; Alle innbokser; melding (f./m.,
"meldingen", pl. "meldinger"; "e-post" as the mass noun); mappe; konto (pl. kontoer); vedlegg; flagg (Merk med flagg,
Fjern flagg); Svar avsender; Svar alle; Videresend; Send/motta; Merk som søppelpost / Merk som ikke søppelpost; Flytt
til mappe; Kopier til mappe; Angre; Merk alt; Nylig brukt; Adressebok; kontakt; gruppe; Verktøy; Fil > Kontoer;
Cc / Bcc: Kopi / Blindkopi (Outlook); samtale (conversation); ulest / uleste.

Colours: Rød, Oransje, Gul, Grønn, Blå, Lilla, Grå (in sentences "rødt flagg", agreeing with the neuter "flagg").

Encryption: kryptering, kryptert, signert, signatur (of a message; the text signature is also "signatur", context keeps
them apart), nøkkel (pl. nøkler), offentlig nøkkel, privat nøkkel, fingeravtrykk, passfrase, OpenPGP.

Sign-in: logg på / pålogging, passord, påloggingsapp, KI-agent, klient-ID, klienthemmelighet, utsteder, tillatelser
(scopes), appassord ("app-passord"), Legitimasjonsbehandling (Windows Credential Manager), Nøkkelring (the Mac's
Keychain: "nøkkelringen").

Menus: Fil, Rediger, Vis, Gå, Melding, Verktøy, Vindu, Hjelp. Options (Windows) "Alternativer"; Settings (Mac) "Innstillinger";
Preferences (Linux) "Brukervalg" as GNOME's Norwegian. Mac system menus as Apple's (Avslutt, Skjul andre, Klipp ut,
Lim inn, Gjør om, Minimer).

- "du" everywhere, lowercase; imperatives in steps and on buttons ("Klikk", "Velg", "Lagre"); sentence case for menus
  and buttons.
- Quotes «...», apostrophe ’. No genitive -s on placeholders or provider names: "på nettstedet til { $provider }",
  "nøkkelen til { $name }".
- Plurals: `[one]` and `*[other]` (CLDR nb; 0 is `*[other]`).
- Past-tense status lines agree by `$count` ("Merket 1 melding som lest" / "... som lest" is invariable in Bokmål,
  "flyttet" invariable); destinations read "til { $folder }", which works with `their-folders` ("de opprinnelige
  mappene") and `transfer-another-account` ("en annen konto").
- Keys Ctrl / Skift / Del / Enter in catalog prose (Microsoft's Norwegian); help `<kbd>` stays English.
- Reply header "Opprinnelig melding"; "Re: " and "Fw: " stay English.
- Access keys: unique within every menu, folder items too (N&y mappe, Gi nytt na&vn til mappe, Slett ma&ppe, T&øm
  mappe, as File already uses N, S, g and t).
- The help quotes core error texts in Norwegian where the core translates them and in English where the app shows raw
  server or network errors (TLS error, connection error).
- Review first: "Svar avsender" versus "Svar", "Merk alt" (Windows) versus Apple's "Marker alt", "Søppelpost" pair,
  "passfrase", "Legitimasjonsbehandling".

Review notes (round 2):
- Retain direct du prose, imperative commands, Kopi/Blindkopi, KI-agent and passfrase.
- Rules behandler messages; matching is based on kriterier. Folding a conversation is "Trekk sammen",
  distinct from hiding messages. Digital signatures and confirmed key ownership are separate checks.
- "Påloggingsopplysninger" covers saved passwords and OAuth credentials; transfer without protection
  requires another password or browser sign-in. Domain authentication does not verify a person's identity.
- Actual menu/context/dialog access keys were checked in 32 scopes, including Norwegian Ø where needed.
  Recipient controls use Alt+K and Alt+B, which help must explain beside unchanged English keyboard tags.

### Polski (pl)

Terms: Skrzynka odbiorcza; Skrzynka nadawcza; Elementy wysłane; Elementy usunięte; Wersje robocze; Wiadomości-śmieci;
wiadomość; folder; konto; załącznik; flaga (Oznacz flagą, Usuń flagę); Odpowiedz wszystkim; Prześlij dalej; Cc / Bcc:
DW / UDW (Outlook).

Plurals: `[one]` 1; `[few]` 2 to 4, 22 to 24 (not 12 to 14); `[many]` 0, 5 to 21, 25 to 31; `*[other]` fractions only,
written as the `[many]` form.

- Informal singular ("Wybierz"), Ty and Twój capitalised; gendered past forms of the user ("pisałeś") avoided with
  impersonal -no, -to forms or nouns.
- `$messages` status texts use the impersonal past and a colon ("Oznaczono jako przeczytane: 2 wiadomości");
  destinations read "(cel: { $folder })".
- Folder names in running text follow "folder" ("w folderze Elementy wysłane"); the Inbox and Outbox decline as nouns
  ("ze Skrzynki odbiorczej", "w Skrzynce nadawczej").
- Counts needing a case go in parentheses or after a colon ("Te wiadomości (5) zostaną trwale usunięte").
- Quotes „…”; no Title Case. Keys stay English, `<kbd>Click</kbd>` is "Kliknięcie"; the help names Alt+D and Alt+U for
  the &DW / &UDW fields.

### Português (pt-BR, Brasil)

Made from the European Portuguese catalogs and rewritten in Brazilian usage, with Microsoft's (Outlook, Windows) and
Apple's Brazilian terms.

Terms: Caixa de Entrada; Caixa de Saída; Itens Enviados; Itens Excluídos; Rascunhos; Lixo Eletrônico; Arquivo Morto
(the Archive folder, as Outlook; "Arquivo" is the File menu); Todas as Caixas de Entrada; mensagem (f.), e-mail (m.);
lista de e-mails; pasta; conta; anexo; arquivo (file); sinalizador (Sinalizar, Limpar sinalizador); Responder,
Responder a todos, Encaminhar; Desfazer, Excluir, Salvar (Salvar como); baixar ("Baixando..."); Acompanhar conversa;
fazer login / login, the providers' own button labels ("Fazer login com o Google", "Entrar com a Microsoft");
aplicativo de login; senha, senha de app; aplicativo, aplicativo de e-mail padrão; conectar, conexão; link; navegador;
tela; mouse; contato; Catálogo de Endereços (as Outlook Express in Brazil); Nome, Sobrenome, Apelido, Nome de exibição;
provedor; Permissões (scopes) in forms, escopo in prose; locatário (tenant); barra de status; guia (tab); Exibir
código-fonte; Sobre o Inbox Classic; pressione, digite.

Menus: Arquivo, Editar, Exibir, Ferramentas, Mensagem, Ajuda. Opções (Windows), Ajustes (Mac), Preferências (Linux);
configurações for settings in general.

Encryption: criptografia, criptografar, criptografada, descriptografar; chave (privada, pública); impressão digital;
assinada, assinatura; frase secreta (passphrase, as GnuPG and Thunderbird in Brazil); confiável; Gerenciador de
Credenciais, chaveiro (the Mac), chaveiro do sistema (Linux), Acesso às Chaves.

Plurals: CLDR's `pt` (pe-i18n gives the catalog that locale), where 0 and 1 are `[one]`. Every `[one]` uses
`{ $count }`, never a literal 1, and counts where zero is plausible have an explicit `[0]` branch ("nenhuma mensagem").

- Never the forms of Portugal: ficheiro, ecrã, guardar, eliminar, transferir (download), palavra-passe, contacto,
  receção, utilizador, partilhar, browser, ligação, "a + infinitivo" for the progressive.
- "Você" with Brazilian verb forms and pronoun placement ("não o abre", "para abri-lo"), the possessive usually without
  article ("seu computador"); imperatives as Microsoft Brazil writes them ("Clique", "Digite", "Escolha").
- The progressive is the gerund ("Baixando...", "Salvando em Rascunhos...", "Conectando...").
- Brazilian spelling: recepção, detectar, aspecto, eletrônico, anônimo, registro, equipe, fato, seção.
- Sentence case for menus and buttons; folder names and the Catálogo de Endereços keep their capitals.
- `$messages` is feminine plural ("3 mensagens"): participles agree by `$count`.
- Quotes “ ”; decimal separator a comma.
- Review first: "Arquivo Morto", "Acompanhar conversa", the Junk wording (Lixo / Não é lixo), "frase secreta",
  "chaveiro", "fazer login" against "entrar", and the Google and Microsoft settings paths in the help (Verificação em
  duas etapas, Senhas de app).
- Use “Cc” and “Cco” for copy and blind copy; the Cco controls use Alt+O on Windows/Linux. Keep literal
  English keyboard tags in help and explain the localized shortcut alongside them.
- Prefer “Marcar como lixo eletrônico” / “Marcar como e-mail legítimo”; the short toolbar labels stay “Lixo” /
  “Não é lixo”. Rules “processam” messages; “ordenar” describes the display order.
- Use “assinatura digital” where text signatures could be confused with cryptographic signatures. Verify all
  addresses before confirming key ownership. A settings export without a passphrase requires signing in again,
  which may use the browser; “credenciais de login” includes tokens as well as passwords.
- The additional sender-address field is “Outros endereços de envio”; use that exact label in errors and help.
  Use “ID do cliente” / “segredo do cliente” consistently for OAuth fields.

### Português (pt, Portugal)

Terms: Caixa de Entrada; Caixa de Saída; Itens Enviados; Itens Eliminados; Rascunhos; Lixo Eletrónico; mensagem (f.);
pasta; conta; anexo; sinalizador (Sinalizar, Limpar sinalizador); Responder a todos; Reencaminhar; ficheiro;
palavra-passe.

Plurals: the catalog's plurals follow pt-PT (pe-i18n gives the bundle that locale), where only 1 is `[one]` and 0 is
`*[other]`. The explicit `[0]` branches the draft has from when it followed CLDR's Brazilian `pt` can stay.

- European spelling of the 1990 agreement (ação, eletrónico, receção), never Brazilian forms (arquivo, usuário, senha,
  você).
- Polite third person without "você" ("Clique", "o seu correio"); sentence case, but folder names and the Livro de
  Endereços keep their capitals. The app is masculine ("o Inbox Classic").
- `$messages` is feminine plural: status texts agree ("movidas") by `$count`; `done-flagged-color` and
  `done-unflagged` are phrased without agreement. Destinations read "para { $folder }".
- Quotes « »; day names lowercase.
- Use "Marcar como lixo eletrónico" / "Marcar como correio legítimo" in message commands; the short toolbar
  labels "Lixo" / "Não é lixo" remain suitable. Keep "Seguir conversa" and "Esquema" for Layout.
- Rules "processam" messages; reserve "ordenar" for their display order.
- Use "assinatura digital" for cryptographic signatures, "frase de acesso", "chave privada", "chave pública"
  and "impressão digital". Confirm every address before completing key verification.
- "Credenciais de início de sessão" includes saved browser tokens. An unprotected export requires signing in
  again, not necessarily entering a password. Use "ID do cliente" and "segredo do cliente" for OAuth fields.

### Română (ro)

Terms: Mesaje primite; Mesaje de trimis; Elemente trimise; Elemente șterse; Schițe; E-mail nedorit; mesaj; folder;
cont; atașare (as Microsoft says); semnalizare (a semnaliza); Răspuns la toți; Redirecționare; Address Book: Agendă.

Plurals: `[one]` 1; `[few]` 0, 2 to 19 and numbers ending in 01 to 19 above 100; `*[other]` 20 and up, which needs "de"
("20 de mesaje"), so `[few]` has no "de" and `*[other]` has it.

- Polite plural ("dvs.", "Faceți clic"); commands and buttons are long infinitive nouns ("Mutare în folder..."), but
  the Mac's own system menus use macOS's imperative ("Ieși din Inbox Classic", "Taie").
- Participles after `$messages` agree by `$count`: `[one]` "mutat", `*[other]` "mutate".
- Counts without a selector put the label first with a colon ("necitite: 3", "Găsite: 12").
- `done-flagged-color` and `done-unflagged` agree the colour with "semnalizarea" (f.), not with `$messages`.
- Quotes „...”, comma-below ș and ț; days of the week lowercase.

### Slovenčina (sk)

Terms: Doručená pošta; Pošta na odoslanie; Odoslaná pošta; Odstránená pošta; Koncepty; Nevyžiadaná pošta; správa;
priečinok; konto (as Microsoft Slovak); príloha; príznak (Označiť príznakom, Zrušiť príznak); Odpovedať všetkým;
Preposlať; client secret: tajný kód klienta (keeping "kľúč" for encryption).

Plurals: `[one]` 1, `[few]` 2 to 4, `*[other]` 0 and 5 or more; `[many]` (fractions only) is never used.

- Plural "vy", lowercase ("Kliknite", "vaša pošta").
- Verbs and participles agree by count ("1 správa označená", "3 správy označené", "5 správ označených").
- `$messages` stays nominative; destinations read "do: { $folder }" (`their-folders` = "pôvodné priečinky",
  `transfer-another-account` = "iné konto"). In sentences a folder follows "priečinok" ("do priečinka Koncepty").
- `ui-the-provider` = "poskytovateľa", for "cez { $provider } na jeho webovej stránke".
- Quotes „…“; help keys stay English; access keys without diacritics.

### Slovenščina (sl)

Terms: Prejeto; Odpošiljanje; Poslano; Izbrisano; Osnutki; Neželena e-pošta; sporočilo; mapa; račun; priponka;
zastavica; Odgovori vsem; Posreduj; Cc / Bcc: Kp / Skp (as Outlook); passphrase: zaščitno geslo (apart from "geslo").

Plurals: `[one]` 1, 101...; `[two]` 2, 102...; `[few]` 3, 4, 103, 104...; `*[other]`. Every count uses `{ $count }`,
never a literal 1.

- Polite plural "vi", lowercase ("Kliknite"); menu items and buttons in the imperative singular ("Odpri", "Shrani
  kot").
- `$messages` status texts use an impersonal participle and a colon ("Premaknjeno v Arhiv: 3 sporočila"); `$folder`
  after "v" works with "njihove mape" and "drug račun".
- Agent log entries use the masculine past participle (Odprl, Poslal), agreeing with "agent"; AI agent is "agent UI".
- Quotes »...«; keys Ctrl, Shift, Alt, Del, Enter.
- Review first: the `done-*` / `transfer-*` lines and the plural forms of `setup-*` and `pgp-imported-*`.

### Srpski, latinica (sr-Latn)

Terms (Outlook and Windows in Serbian Latin): Prijemno sanduče; Izlazno sanduče; Poslate stavke; Izbrisane stavke;
Radne verzije (one draft: radna verzija); Neželjena e-pošta; Arhiva; Sva prijemna sandučad; poruka; fascikla; nalog
(pl. nalozi); prilog; datoteka; zastavica (Označi zastavicom, Ukloni zastavicu); Odgovori pošiljaocu; Odgovori svima;
Prosledi; Pošalji/primi; Opozovi; Izaberi sve; Adresar; kontakt; grupa; Alatke (Tools); Datoteka > Nalozi.

More terms: server; računar; dobavljač (e-mail provider); pošiljalac / pošiljaoca; primalac / primaoca; tema (subject);
lozinka; prijava, prijaviti se; sertifikat; bezbednost; podešavanja (Settings on the Mac, Preferences on Linux, the
app's settings); Opcije (Options on Windows); meni; dugme; taster; prečica; ekran; pregledač (browser); veza (link);
obaveštenje; lista; kolona; red; podrazumevano (default); sačuvaj; izaberi.

Encryption: šifrovanje, šifrovano, šifrovati, dešifrovati; potpis, potpisano, potpisati; ključ (javni, privatni);
otisak prsta (fingerprint); pristupna fraza (passphrase, apart from lozinka); server ključeva; OpenPGP; Upravljač
akreditivima (Windows Credential Manager); privezak ključeva (keychain).

OAuth and agents: aplikacija za prijavljivanje (sign-in app); ID klijenta; tajna klijenta; izdavalac (issuer); opsezi
(scopes); AI agent.

Plurals: `[one]` 1, 21, 31... (not 11); `[few]` 2 to 4, 22 to 24... (not 12 to 14); `*[other]` 0, 5 to 20, 25 to 30...
`[one]` uses `{ $count }`; an exact `[1]` branch comes first where English means the single one with no number.

- Ekavian (vreme, mesto, pre, posle, uvek, gde) and Serbian vocabulary, never Croatian (račun, mapa, poslužitelj,
  privitak, spremiti, odabrati, izbornik, gumb, tipka, zaslon, preglednik, poveznica, postavke, tko, točno, tisuća,
  sustav).
- Second person plural, lowercase ("vi", "vaš"), imperatives in -ite ("Kliknite", "Izaberite"); menu items and buttons
  in the imperative singular as Microsoft writes them ("Sačuvaj kao...", "Odgovori svima").
- Questions with "Da li ...?"; the future fused as Serbian writes it ("otvoriće", "biće").
- `$messages` goes after a colon ("Premešteno: { $messages }") so no participle agrees with it; destinations that can
  be `their-folders` or `transfer-another-account` read "(odredište: { $folder })".
- Quotes „…“; days of the week and months lowercase; keys Ctrl / Shift / Del / Enter.
- Folder names follow Outlook on every platform (Apple Mail and Thunderbird have no Serbian Latin localization worth
  matching).
- Review first: "datoteka" (Microsoft) versus the everyday "fajl"; "Radne verzije" versus "Nacrti"; "dobavljač" for
  the mail provider; "Prijemno sanduče" (Outlook.com) versus Outlook's longer "Prijemno poštansko sanduče".

Review notes (round 2):
- Keep Serbian Ekavian and formal plural prose. Prefer "pružalac usluge e-pošte" over the supplier-like
  "dobavljač"; inflect the head noun and keep provider/name placeholders intact.
- "Označi kao neželjenu poštu" / "Označi kao poželjnu poštu" are the paired actions; toolbar labels use
  "Neželjena pošta" / "Poželjna pošta". Rules obrađuju messages. Address-book Write To is "Napiši poruku".
- The sender-address field is "Dodatne adrese za slanje:"; the core error quotes this exact label.
- Prefer "otisak ključa" for a cryptographic fingerprint, and "digitalni potpis" where the text signature
  could be confused with cryptographic verification. Verify all addresses before accepting a key.
- "Podaci za prijavu" covers passwords and OAuth credentials; importing an unprotected setup requires
  another password or browser sign-in. Cc/Bcc and Alt+C/Alt+B remain unchanged.
- All 32 actual menu/context/dialog scopes have distinct access keys, including native Serbian letters.

### Suomi (fi)

Terms: Saapuneet; Lähtevät; Lähetetyt; Poistetut; Luonnokset; Roskaposti; viesti; kansio; tili; liite; lippu (liputa,
Poista lippu); Vastaa kaikille; Välitä edelleen (toolbar: Välitä).

- Informal singular ("Valitse", "Kirjoita"); sentence case.
- Placeables never inflect: a head noun takes the case ("kansioon { $folder }", "tililtä { $account }") or a label and
  colon is used ("Siirretty: { $messages }. Kohde: { $folder }"); `their-folders` and `transfer-another-account` are
  nominative to fit "Kohde:".
- Brand names that are not placeables inflect with a colon ("Inbox Classicin").
- Participles choose by `$count` ("Merkitty luetuksi" / "Merkitty luetuiksi"); colours take the adessive inside the
  selector ("punaisella lipulla").
- Quotes ” ” (both U+201D), apostrophe ’; `ui-event-span` joins with a hyphen. Options, Settings and Preferences are
  all "Asetukset".

### Svenska (sv)

Terms: Inkorgen; Utkorgen; Skickat; Borttaget; Utkast; Skräppost; meddelande (neuter); mapp; konto; bilaga; flagga;
Svara alla; Vidarebefordra; Cc / Bcc: Kopia / Hemlig kopia (Outlook).

- "du"; sentence case.
- "Arkiv" is both the File menu and the Archive folder; context keeps them apart, as on the platforms themselves.
- Special folders are Outlook's definite forms, written as names in running text ("flyttades till Inkorgen").
- `$messages` sentences need no ending; participles ("flyttat", "flyttade") choose by `$count`.
- Quotes ” ” (both the closing form), apostrophe ’; keys Ctrl / Skift / Del / Retur.
- The reply header is "Ursprungligt meddelande"; "Create Mail" is "Skapa e-post" as in Outlook Express.

### Türkçe (tr)

Terms (Outlook / Outlook Express Turkish): Gelen Kutusu; Giden Kutusu; Gönderilmiş Öğeler; Silinmiş Öğeler; Taslaklar;
Gereksiz E-posta; Arşiv; Tüm Gelen Kutuları; ileti; klasör; hesap; ek (ekli dosya in running text where clearer);
bayrak (Bayrak Koy, Bayrağı Kaldır); Gönder/Al; Gönderene Yanıtla; Tümünü Yanıtla; İlet; Gereksiz Olarak İşaretle;
Gereksiz Değil Olarak İşaretle; Klasöre Taşı; Klasöre Kopyala; Geri Al; Tümünü Seç; Son Kullanılanlar; Adres Defteri;
kişi; grup; konuşma (conversation); Dosya, Düzen, Görünüm, Araçlar, İleti, Yardım; Dosya > Hesaplar.
Colours: Kırmızı, Turuncu, Sarı, Yeşil, Mavi, Mor, Gri.
OAuth: oturum açma uygulaması; istemci kimliği; istemci gizli dizisi (as Azure, keeping "anahtar" for encryption);
yayımcı (issuer); izinler (scopes). AI agent: yapay zeka aracısı (short: aracı).
Encryption: OpenPGP; anahtar; ortak anahtar / gizli anahtar; parmak izi; imzalı; şifreli; anahtar parolası
(passphrase), apart from "parola" (password); uygulama parolası (app password).
Settings: Windows "Seçenekler" (Options), the Mac "Ayarlar" (Settings), Linux "Tercihler" (Preferences).
Cc / Bcc: Bilgi / Gizli (as Outlook Turkish).

Plurals: `[one]` and `*[other]`; a noun after a number stays singular ("3 ileti"), so both forms usually read alike.

- Polite "siz" through the imperative in -in/-ın ("Tıklayın", "Seçin", "Girin"); "siz" itself is mostly left out.
- Menu items and buttons as Microsoft Turkish writes them: Title Case, short imperative or noun ("Yanıtla",
  "Farklı Kaydet...", "Klasöre Taşı...").
- Placeables never take a suffix (case, possessive, plural). A head noun carries the ending ("{ $folder } klasörüne"
  only where `$folder` is always a real folder name), or a label and colon is used ("Taşındı: { $messages }. Hedef:
  { $folder }"). `their-folders` = "kendi klasörleri", `transfer-another-account` = "başka bir hesap", both
  nominative to fit "Hedef:".
- Provider sentences use "{ $provider } web sitesinde" (izafet without suffix on the name), so `ui-the-provider`
  ("sağlayıcı") fits.
- Brand names that are not placeables take a suffix after an apostrophe ("Inbox Classic'i", "Gmail'de").
- Quotes “…” (as the app's English uses).
- Access keys avoid i, ı, İ and I (the dotted/dotless pair maps differently in Turkish case folding). Prefer ASCII
  letters; native ç, ğ, ö, ş and ü may be used where the actual menu scopes need more distinct letters.
  Do not lengthen otherwise natural commands just to obtain ASCII access keys.
- Keys Ctrl / Shift / Del / Enter, as Turkish keyboards print them.
- Review first: "ileti" versus "e-posta" for message, "Gereksiz E-posta" pair, "istemci gizli dizisi", "aracı" for
  agent.
- More terms: etki alanı (domain, as Microsoft; never "alan adı"); bağlantı noktası (port); okuma bölmesi; durum çubuğu;
  belirteç (token); betik (script); eşitleme (sync); istenmeyen posta (spam); Özgün İleti (reply header
  "----- Özgün İleti -----"); Windows Kimlik Bilgileri Yöneticisi, the Mac's anahtar zinciri, Linux's sistem anahtarlığı;
  Çöp Sepeti (the Mac's Trash); Linux Preferences = Tercihler, Quit = Çık.
- Suffix apostrophes are ASCII ' in catalogs and help alike ("Gelen Kutusu'nda", "Inbox Classic'ten").
- In the help a `data-text` name is followed by "komutunu seçin" (menu items), "düğmesine tıklayın" (buttons) or
  "seçeneğini" (checkboxes), so the catalog value never takes a suffix.
- Raw network errors quoted in the help ("connection error: …", "the server did not answer in time") stay English, as
  the core does not translate them.
- Round 2: the sender-address field is "Diğer gönderen adresleri:"; the validation error quotes that name.
  Rules "işler" messages. Address-book Write To is "İleti Yaz". Use "dijital imza" to distinguish
  cryptographic signatures from the signature appended to message text.
- "Oturum açma bilgileri" includes passwords and OAuth credentials. Unprotected setup files require
  another password or browser sign-in. Key verification checks every listed address before accepting it.
  "Eşleşiyor" / "Eşleşmiyor" are the matching and mismatching fingerprint buttons.
- Bilgi/Gizli keep Alt+B/Alt+G; help preserves original keyboard tags and explains these localized keys.

- The checker reads a message only up to a `}` in column 0, so selectors that English puts first stay first
  (`done-flagged-color` ends with the colour; the Linux search result counts come before a colon).

### Ελληνικά (el)

Terms: Εισερχόμενα; Εξερχόμενα; Απεσταλμένα; Διαγραμμένα; Πρόχειρα; Ανεπιθύμητη αλληλογραφία; Archive: Αρχειοθέτηση
(Outlook's name, as "Αρχείο" is the File menu); μήνυμα; φάκελος; λογαριασμός; συνημμένο; σημαία; Απάντηση σε όλους;
Προώθηση; Cc / Bcc: Κοιν. / Ιδ. κοιν.

- Polite plural ("Επιλέξτε", "Κάντε κλικ"); menu and button labels are nouns of action (Αποθήκευση), sentence case.
- Quotes «...»; the question mark is the Greek ";" (typed as ASCII `;`), the ano teleia "·" stands where English has a
  semicolon.
- Placeholders follow a noun that carries the case ("στον φάκελο «{ $folder }»"); where `$folder` may be
  `their-folders` or `transfer-another-account`, the status bar uses "σε: { $folder }" (αρχικοί φάκελοι, άλλος
  λογαριασμός).
- In the help `data-text` names are always nominative, after "στο/στα/στην", "το κουμπί", never a genitive article.
- Access keys are Greek capitals without accents; the reply header is "----- Αρχικό μήνυμα -----".

### Български (bg)

Terms: Входящи; Изходящи; Изпратени; Изтрити; Чернови; Нежелана поща; съобщение; папка; акаунт; прикачен файл; флаг
(Маркиране с флаг, Премахване на флага); Отговор до всички; Препращане.

Plurals: `[one]` and `*[other]`; masculine nouns take the count form after a number ("3 акаунта", "5 ключа"), persons
keep the normal plural.

- Polite "вие", lowercase; menus and buttons are verbal nouns in sentence case ("Преместване в папка..."). Inbox
  Classic is feminine (програмата).
- Status lines choose by `$count` so the participle agrees ("1 съобщение е преместено", "3 съобщения са преместени").
- Folder names in sentences are quoted where they would read as ordinary words ("в „Изходящи“").
- `ui-the-provider` = "доставчика", `ui-the-account` = "акаунта" (the short article, after a preposition); `$store`
  names stand without an article.
- Quotes „…“; sizes КБ, МБ, ГБ; day names lowercase; access keys Cyrillic.
- Account aliases: „Допълнителни адреси за изпращане“ in the field and its error. Rules „обработват“ messages;
  „цифров подпис“ distinguishes cryptographic signatures from the signature text appended to mail.
- „Данни за влизане“ includes passwords and browser sign-in tokens. Key verification confirms the owner
  and every listed address before „Съвпадат“; the displayed name may be a fingerprint.

### Русский (ru)

Terms: Входящие; Исходящие; Отправленные; Удаленные; Черновики; Нежелательная почта; сообщение; папка; учетная запись;
вложение; флажок (пометить флажком, Снять флажок); Ответить всем; Переслать; Cc / Bcc: Копия / Скрытая; conversation:
беседа.

Plurals: `[one]` 1, 21, 31...; `[few]` 2 to 4, 22 to 24...; `[many]` 0, 5 to 20, 25 to 30...; `*[other]` fractions.
`[one]` uses `{ $count }`; a `[1]` branch comes first where Russian says "Каждый день" or "один раз" for exactly one.

- "вы", lowercase; no "ё" (Microsoft style: Удаленные, Желтый); sentence case.
- Quotes «ёлочки»; the app's “…” placeables (`ui-quoted`) become «…».
- `$messages` takes plain agreement ("{ $messages } перемещены в { $folder }"), `[one]` singular verb, `*[other]`
  plural; `$folder` after "в" stays uninflected ("их папки", "другую учетную запись").
- Fallbacks are in the case their sentences need: `ui-the-provider` = «провайдера» (genitive), `ui-the-account` =
  «учетную запись» (accusative).
- Inbox Classic is feminine («программа»); weekday names lowercase; `<kbd>Click</kbd>` is `<kbd>Щелчок</kbd>`.

### Українська (uk)

Terms: Вхідні; Вихідні; Надіслані; Видалені; Чернетки; Небажана пошта; повідомлення; папка; обліковий запис; вкладення;
прапорець (Позначити прапорцем, Зняти прапорець); Відповісти всім; Переслати; Tools: Сервіс (as Outlook Express).

Plurals: `[one]`, `[few]`, `[many]`, `*[other]`. `[one]` covers 21, 31, 101..., so it uses `{ $count }`, with an exact
`[1]` branch first where English has no number. "повідомлення" serves one, few and other, "повідомлень" many.

- "ви", lowercase; quotes «…», apostrophe ’ (U+2019).
- `$messages` follows impersonal past participles ("Переміщено { $messages } у …", "Позначено як прочитані:
  { $messages }").
- Destinations after "у" are accusative: `their-folders` = "свої папки", `transfer-another-account` = "інший обліковий
  запис"; a folder name that is the object of a noun is quoted «{ $folder }».
- `ui-the-provider` is genitive ("вашого провайдера") and every `$provider` sentence uses a genitive slot ("на вебсайті
  { $provider }").
- Review first: "Сервіс" versus "Знаряддя" for Tools, the Junk pair, the app-password paths in `gmail-outlook.html`.
