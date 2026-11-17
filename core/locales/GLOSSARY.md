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

## Agent unsubscribe log timing

The `agent-log-unsubscribed` entry is written when the user approves the request, before any HTTP request
is made. Translate it as user approval, not completed cancellation or a request already sent. The subject
placeholder identifies the source message, not a list name; introduce it with the localized message label.
Use the language's normal form of address. Polish uses an impersonal approval to avoid gendered user forms;
Slovenian addresses the approving user here, rather than using the masculine participle for an agent action.

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

French Cc/Cci use Alt+C/Alt+I on Windows and Linux; preserve literal English shortcuts in help and explain
the localized combinations beside them.

### German compose signing and encryption

- Keep "digital signieren" separate from the signature text appended to a message. Compose status describes
  protection applied when sending, not a completed delivery. A valid signature does not by itself verify ownership.
- Use "verwendbarer Schlüssel" when sending requires a usable key; expired or revoked keys also trigger missing-key
  guidance. "Aus der Nachricht entfernen" removes a recipient from address fields, not from the address book.
- A reason placeholder can be a complete sentence, including locked-key recovery instructions. Put it after
  "Grund:" and separate the next instruction, rather than embedding it in parentheses.

### German agent unsubscribe additions

- Use "Mailingliste abbestellen" consistently with the existing reading-pane action. An unsubscribe confirmation
  sends an "Abmeldeanfrage"; it does not guarantee that future mail will stop. Introduce sender-address lists
  with a colon. "Textsignatur" distinguishes the account footer from a digital signature; agents include it
  by default but can omit it. Keep the quota per program over the preceding 24 hours, counting approvals.

### Estonian encryption and settings transfer

- Use the polite plural in explanations and questions; short commands stay imperative ("Impordi", "Kontrolli").
- Use "krüpteerima", "avalik võti", "privaatvõti" and "võtme sõrmejälg" consistently. Key verification means
  comparing the fingerprint with the owner, not merely checking a cryptographic signature.
- Use "parool" for the password protecting a key backup or settings file, as in the existing key dialogs.
  "Sisselogimisandmed" includes saved sign-in tokens; it does not mean only a login password.
- A list of addresses must work for one or several entries. Introduce it with a colon instead of forcing a
  singular case onto the placeholder. Contact names can be placed in parentheses to avoid requiring inflection.
- Compose status describes protection applied "saatmisel". Use "digiallkiri" or "digitaalne allkirjastamine"
  when distinguishing signing from signature text. Signature checks do not by themselves confirm key ownership.
- Use "kasutatav võti" for a key that can be used, including expiry/revocation constraints. A message is
  encrypted "võtmega", not "võtmele". Recipient removal changes message address fields, not the address book.
- A key-state reason can be a full recovery instruction. Put it after "Põhjus:" and separate the next instruction;
  do not embed it in parentheses. Keep polite plural wording in explanations and confirmation questions.

Estonian agent unsubscribe additions:
- Use "meililist" and "tellimusest loobumine" with the existing "Loobu tellimusest" action. A "loobumistaotlus"
  requests removal; it does not guarantee future mail will stop. "Lugemisolek" is the read/unread state of a message.
  The account footer is "allkirjatekst", distinct from "digiallkiri". Keep polite plural explanations and concise
  imperative buttons; explain the per-program quota over the preceding 24 hours, counting approvals.

Estonian settings review (round 2):
- New-mail settings heading: "Uued kirjad". A notification is a "teatis"; "teavita" remains the action.
- Use "Kettaruumi piir konto kohta" for the downloaded-message storage limit, not a possible network quota.
- In help, a settings page is introduced by "seadetes" / "seadetest" before `data-settings`, not "kohas"
  or a bare menu reference. Apply "rakendab muudatused"; Cancel discards changes not yet applied.

### French compose signing and encryption

- Use "signature numérique" and "signer numériquement" for cryptographic signing, distinct from signature text.
  Compose status describes protection applied "à l’envoi"; signature checks alone do not confirm key ownership.
- Use "clé utilisable" when encryption requires a usable key; expired or revoked keys also trigger the warning.
  A message is encrypted with keys, not "pour la clé". Retirer du message affects recipients, not contacts.
- Put complete key-state reasons after "Motif :" with the following instruction separate. Use "pour" before
  arbitrary names/address lists to avoid required elision after "de". Date placeholders follow Dernière recherche.

### Spanish encryption and settings transfer

- Use "contraseña" for the password protecting a key backup or settings export, as in the account dialogs.
- Use "huella digital" for a key fingerprint. Verifying a key means confirming its owner by comparing the
  fingerprint; checking a message signature alone does not confirm the owner.
- "Datos de acceso" includes saved sign-in tokens as well as passwords. After an unprotected export, the user
  must sign in again, which may use a browser rather than a password prompt.
- Use "firmar digitalmente" where needed to distinguish cryptographic signing from the signature text at the
  end of a message. Compose status describes protection applied when sending, not completed delivery.
- Use "clave utilizable" in missing-key guidance: an expired or revoked key also prevents encryption.
  "Quitar del mensaje" removes a recipient from its address fields, not from the address book.
- Put a key-state reason after "Motivo:" and separate the next instruction. The reason may be a full sentence
  with recovery instructions, so it does not fit naturally inside parentheses.

Context notes:

- Check the Flag submenu's runtime colour mnemonics too: each colour takes its first unused letter, and
  Clear Flag must use another. Account/folder context menus, Settings and folder-picker buttons have their
  own combined scopes beyond the main menus. With the three settings pages and the compose menus, recipient-key dialog and questions, the extended review helper covers 53 such scopes.

- Sign-in code cards require a provider-confirmed domain signature (`otp::of`). That authenticates the
  domain associated with the code, not the safety or trustworthiness of all message content. Avoid claiming
  that every forged or malicious message is excluded.

- Outlook.com and Microsoft 365 mail require browser/modern authentication; app passwords are not an alternative.
  This is already stated by `pe-autoconfig/src/app_password.rs::MICROSOFT_WARNING`, although the English provider
  introductions and Gmail/Outlook help contradict it. Google app passwords require two-step verification and an
  eligible account. Do not imply that every provider or account supports them. The focused followup and official
  provider sources are recorded under `provider-app-password-context` in the review state. The same distinction
  applies to password-not-accepted help; its focused followup is `provider-troubleshooting-context`.

- Deleting a message is permanent both inside Deleted Items and when the account has no Trash folder.
  `Core::trash_for`/`deletes_for_good` and the selection summary enforce this; all three platforms ask first.
  The English deletion help omits the missing-folder case. Qualify the normal move and describe both cases.

- Settings now have General, Reading and Downloading pages from `core/settings.toml`. Group headings have
  no access key or colon; `ui-settings-label` supplies the Mac label punctuation. Check each page's access
  keys together with OK, Cancel and Apply, and use `data-settings` for help navigation.
- In Windows Options, OK/Apply save pending settings and trusted-sender removals; Cancel discards changes
  since the last apply. Opening Windows Default apps is immediate and external: Cancel does not undo a
  default-app selection there, despite the new English Settings help claiming it does. Apply can prompt
  for a language restart. Mac/Linux settings take effect immediately, with a restart for a new UI language.

- The `undone-*` failure bar embeds the already-localized `messages` count phrase. Source and destination
  placeholders here are actual folder names. Moves, deletion and archiving restore local rows after failure;
  a refused flag/read-state change reverses that requested change. Separate a standalone single-message noun
  or pronoun from numeric agreement: CLDR `[one]` can include 21 or 101, so use exact `[1]` where required.

- Watched-conversation alerts obey notification settings and are suppressed while the main window is in
  front. Watching also enables alerts for messages in user folders, not every special folder. Do not promise
  that watched messages are always announced. Ignored conversations do not produce new-mail alerts.

- Search covers subjects, senders, recipients, attachment names and message text. Name those fields rather than
  translating the English draft's vague "people" literally.
- Encrypted search uses available private keys and downloaded sources; it does not guarantee that every message
  can be decrypted. The setting defaults on. Decrypted text is kept unencrypted in the local index; disabling it
  removes that indexed content and previews and restores the outer subject. Do not imply secure erasure.
- The list's lock/seal identifies encrypted/signed mail, not signature validity or verified ownership. A decrypted
  preview and protected subject depend on the index setting. New encrypted-mail notifications always use
  `list-encrypted`; unlike the English help's "until then", they do not switch to the decrypted subject.
- Agents cannot read encrypted message contents or attachments or search decrypted text. They can still receive
  outer envelope metadata; do not claim that encrypted messages are completely invisible to them.
- Address-based key lookup asks the address's domain first, then keys.openpgp.org when enabled and needed.
  An explicit fingerprint/key-ID lookup sends that identifier instead of an address. The keyserver switch leaves
  domain lookup available. Avoid the English note's implication that every lookup sends an email address.
- The new connections paragraph must also cover explicit key searches, not only lookup while encrypting.
  Private keys are encrypted in the mail database with a separate key kept alongside sign-in credentials;
  the database file alone cannot decrypt them. Avoid a literal key "lying beside" passwords.
- Autocrypt sends a public key when the sending address has one assigned and sharing is enabled. Inbox Classic
  may learn a usable sender key when a message is opened. Receiving a key does not verify ownership, and a
  different key for an address already in use waits for the user's choice. Describe public-key sharing directly,
  not as keys that "travel" or an app that "learns" a contact. Keep the Autocrypt control and Security-tab labels.
- An agent's message shown in the Outbox is queued for a delayed send. It has not been sent yet.
- Approval in the agent send dialog queues a message with a 30-second minimum delay (`agents::SEND_DELAY`).
  It is separate from the user's normal send-delay setting; quitting only accelerates the user's undoable sends,
  not the agent queue. Agent Undo cancels a queued message and cannot recall a delivered one.
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
- Help control labels (`help.rs::words`) lose access-key markers, ellipses and trailing colons. Add sentence
  punctuation outside `data-text` tags and check each rendered platform branch for duplicate prepositions.
- `ui-pictures-*` and the trusted-sender settings concern external images inside messages. `ui-list-pictures-*`
  concerns the sender's picture beside a message: a verified brand logo, then an Address Book picture for a verified
  sender domain, otherwise initials. Do not describe these as the same kind of picture.
- External images in encrypted message parts always require explicit permission when the message is opened,
  even with automatic image loading or a trusted sender (`view.rs`: encrypted parts use the clicked flag).
  Mention this exception when Settings/help says images are automatically loaded in all messages.
- Downloaded brand logos are stored and reused across app restarts, not once per run. Describe cached reuse
  across messages, not a promise of exactly one download per brand. When a download occurs, the logo server
  can see the request time and IP address. The English logo help still contains the older timing claims.
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
- Compose explanations and tooltips keep polite vós; short command labels keep their imperative singular.
  Protection is applied "en enviar-lo". Use "clau utilitzable" for missing/unusable-key guidance, and introduce
  complete key-state reasons with "Motiu:" before a separate instruction. Recipient removal affects fields, not contacts.
- The compose menu uses Alt+N for "Insereix" to avoid Eines (Alt+I). "Cerca la clau" uses Alt+E to avoid
  "Conserva l’actual" (Alt+C) in the combined recipient-key dialog.
- Provider prompts use the provider name followed by a colon so named providers and the fallback work without
  changing the article or preposition. Cc/Cco controls use Alt+C / Alt+O on Windows and Linux.

- Agent actions use "cancel·lar subscripcions" and "llistes de correu", matching the existing reader command.
  A cancellation is a request, not a guarantee. "Text de la signatura" is the optional account footer, distinct from "signatura digital".
- Keep "descartar l’esborrany" for abandoning an agent-created draft and explain its permanent removal. Saving,
  including autosave, ends agent access; opening alone does not. Prose keeps vós, while buttons use singular imperatives.

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
- Desktop notifications are "oznámení"; use "upozornit" as the verb in the new-mail command and checkbox.
- Compose wording describes protection „při odeslání“ and uses „použitelný klíč“ for usable keys. Keep infinitive
  controls/tooltips and formal plural prose. Signature integrity and verified key ownership remain distinct.
- Recipient counts use one/few/other; nominative „2 příjemci“, „5 příjemců“, but „pro 2 příjemce“ in missing-key
  guidance. Names/addresses stay uninflected after a colon or a head noun such as „adresu“.
- Complete key-state reasons follow „Důvod:“, dates „Poslední hledání:“. „Najít klíč“ uses Alt+K to avoid
  „Použít nový klíč“ (Alt+N) in the recipient-key dialog. Unencrypted sending requires removal of inherited
  text/images/attachments. Use „Oranžová“ consistently with the reading-security help.

- Agent consent uses "odhlásit odběr zpráv" and "rozesílací seznam" for mailing lists, including newsletters.
  Controls retain "Odhlásit odběr" / "Neodhlašovat" (Windows O/N). A request does not guarantee that mail stops.
- Counted subscription titles use "váš odběr", "vaše 2 odběry" and "vašich 5 odběrů". Failure logs label the
  subject as "Zpráva:" and refusal logs use "Odesílatelé:" before the address list; placeholders stay uninflected.
- Keep "zahodit koncept" for discarding an agent-owned draft and explain permanent removal in help. Saving,
  including autosave, ends agent access; opening alone does not. "Textový podpis" distinguishes the account footer.

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
- Keep "meddelelse" for a message, "mail" for mail generally, and "Adressekartotek" for the address book.
  "Adgangsfrase" is a passphrase; "Legitimationsstyring" is the Windows Credential Manager.
- Rules "behandler" messages; "sorterer" is reserved for ordering a list. Criteria are "opfyldt".
- The appended message footer is "signatur"; cryptography uses "digital signatur" and "signere digitalt".
  Key ownership is "bekræftet"; use "fingeraftrykkene stemmer overens" for the comparison.
- "Loginoplysninger" includes passwords and browser sign-in tokens. Transfer without a passphrase requires
  signing in again, which may mean entering a password or using the browser.
- Use "Tilslut" for connecting an agent and "Rediger" for changing its permissions. Cc / Bcc retain Alt+C / Alt+B.
- A key label can be a name, address or fingerprint. Use "nøglen { $name }" where the owner is not known.
- Logos are cached and reused across messages; avoid implying a fresh download on every app launch.
- Compose status describes protection »når du sender den«.
  Keep direct du wording, meddelelse and digital signatur; signatures do not by themselves confirm key ownership.
- Use »brugbar nøgle« for keys that must be usable, »Årsag:« before complete key-state explanations and
  »Seneste søgning:« before dates. Unencrypted sending requires removing inherited text, images and attachments.
- Help task titles use the imperative, »Signer og krypter en meddelelse«. Status colors match the reading-security
  help (Orange); per-recipient icons differ across platforms. Recipient removal affects message fields, not contacts.

- Agent controls retain "Afmeld" / "Afmeld ikke" (Windows A/I). Use "afmeldingsanmodning" for a request,
  not a completed cancellation. Logs identify the subject with "Meddelelse:" and sender addresses with "Afsendere:".
- Keep "kassere en kladde" and explain permanent removal of agent-owned drafts. Saving, including autosave,
  ends agent access; opening alone does not. "Signaturtekst" is the optional account footer, distinct from "digital signatur".

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

Review notes (round 2):
- Commands use the imperative singular; instructions keep the formal plural. Write To is "Napiši poruku".
- Pair "Označi kao neželjenu poštu" / "Označi kao poželjnu poštu"; the folder remains "Neželjena e-pošta".
- Rules "obrađuju" messages; "sortiranje" describes the displayed order. Mailing list is "lista e-pošte".
- Use "baza pošte" for the local mail store, "otisak ključa" for a cryptographic fingerprint, and "digitalni
  potpis" to distinguish cryptographic signing from an account's signature text. Key verification confirms
  ownership; check every listed address before accepting it. A key label may be a name, address or fingerprint.
- "Podaci za prijavu" includes passwords and OAuth credentials. An unprotected transfer requires another
  password or browser sign-in. Inflect a head noun before dynamic names, or use a colon/parentheses.
- Cached brand logos are saved and reused; verified sender domains do not prove a person's identity.
- All 46 actual menu/dialog scopes have unique access keys, including the three settings pages. Croatian letters
  are used where needed. Cc/Bcc use Kopija / Skrivena kopija with Alt+K / Alt+S, matching Windows and GTK controls.
- Core review: status counters use separate labels for progress and totals, so `$messages` stays nominative.
  `$done` in cross-account transfers is the item being attempted, not a completed-success count.
  Mixed permanent-delete prompts keep `$count` and `$total` independent; move/copy instructions use formal plural.
- Calendar intervals greater than one use "Razmak između ponavljanja:" with a counted nominative phrase, including
  21/31 and the year form "godina". Weekday names appear in parentheses, without requiring an inflected placeholder.
- Agent logs distinguish a message added to "red za slanje" from a message actually sent. Permissions describe access
  through Inbox Classic. The full organize permission explains deletion as moving to Izbrisane stavke.
- "Vlasništvo ključa potvrđeno" identifies verified key ownership separately from a valid "digitalni potpis".
  "Dešifrirano vašim ključem" describes decryption. A locked private key requires importing its own backup again;
  the missing system protection key is not that backup. Publication requires confirming every listed address.
- Use "datoteka s postavkama" and "Postavke i računi programa Inbox Classic", not "postava", for setup transfers.
  `setup-skipped-unreachable` can name either an account or a sign-in app; use a neutral "Preskočeno:" and refer to
  re-adding the corresponding sign-in app. Unencrypted temporary attachment copies older than a day are removed
  when the app starts, not automatically exactly one day after opening.
- Linux Preferences is "Postavke"; keep the native Mac menu labels "Zatvori Inbox Classic" and "Zumiraj".
  Indexing labels count remaining messages; failed-file summaries keep failed and total counts independent.
- Removing an agent program removes its entry and saved access/history, not the installed program. The installer's
  account is a "korisnički račun u sustavu Windows". Uninstalling local mail leaves server mail intact.
- Store descriptions say that quoted text is hidden, not summarized, and that downloaded mail is available offline.
  Browser sign-in provider names and the generic fallback remain uninflected in parentheses.
- Help uses "objedinjeni prikaz" for combined folders and explains hidden quoted text separately from a collapsed
  conversation ("sažeti razgovor"). Search indexing does not require the user to open or mark a message read.
  Use "mogućnost" before long setting labels and quote them when needed to keep the rendered sentence grammatical.
- Rules use "kriteriji" and "lista e-pošte"; folder expansion is "proširiti/sažeti", not opening/closing.
  Replies hide quoted text ("skrivena"), rather than summarizing it. Account signatures are added below the text.
- Attachment reminders currently recognize EN/DE/ET/ES/FR only, not Croatian. Undo Send is available only during
  the send delay (default ten seconds); quitting the app attempts immediate sending. Failed sends are retried,
  not guaranteed to succeed. Permanent deletion also applies when an account has no deleted-mail folder.
- Settings help uses "Postavka" or "Mogućnost" before quoted control labels; send delay is "koliko dugo poruka
  čeka", not the ambiguous "koliko poruka čeka". Use explicit punctuation after stripped download labels.
  Windows Cancel keeps prior Apply results and external default-app choices; Mac/Linux apply immediately except
  language. Encrypted parts still require permission for external images, even for trusted senders. One-time
  codes use "uvećanim znakovima" for large type, not "velikim slovima" (uppercase).
- Account/privacy help keeps "podaci za prijavu" broad enough for browser credentials, including removal and
  setup transfer. Sign-in apps need mail-server support as well as OpenID Connect. Use "lista e-pošte" and
  "otkazivanje pretplate"; acceptance of a direct unsubscribe request is not a guarantee of no future mail.
  Links to web pages open in the browser, mail links use the default mail app, and allowed attachments open
  externally after a temporary copy is saved. A replacement contact key waits for selection in its properties.
- Encryption help uses "otisak ključa", never "otisak prsta"; a valid digital signature and confirmed key ownership
  are distinct. Check all addresses before confirming ownership. Contact photos confirm a domain, not a person.
  Calendar help uses "pozivnica za događaj" and "vremenska zona"; floating event times remain as written.
  Agent permissions describe access through Inbox Classic, and removing an agent entry does not uninstall it.
- Troubleshooting quotes the current localized errors and leaves raw low-level English errors recognizable.
  A requirement for TLS does not confirm the password is valid. Use provider-supported ports/security modes;
  describe retries as attempts, not delivery promises. Damaged mail may be unreadable by this app, not all apps.
  Browser sign-in is required for Outlook.com; Gmail app passwords depend on account eligibility and two-step
  verification. Two-step verification alone does not mean an app password is needed.
- Search syntax stays literal. The search index folds č/ć/š/ž, but đ and d remain distinct. Do not promise that
  a minus negates every operator: date, age and size filters currently ignore it. `after:` includes the given day.
- The sign-in-page file contains a URL. Account removal clears saved sign-in credentials, including browser tokens.
  Address suggestions use "Unos odabrane adrese", not "Preuzimanje osobe"; removing an automatic suggestion leaves
  saved Address Book contacts and groups intact. Combined views are "prošireni" / "sažeti", not open/closed folders.

- Agent unsubscribe additions use "lista e-pošte" and "zahtjev za otkazivanje pretplate" consistently.
  The title keeps the count in all one/few/other branches, including 21. Failure/refusal logs label the
  actual subject as "Poruka:" and sender addresses as "Pošiljatelji:". Buttons retain O/N on Windows.
- Use "odbaciti skicu" for discarding an agent-owned draft, with permanent removal explained in help.
  Saving, including autosave, ends the agent's access; opening alone does not. The account footer is
  "tekst potpisa", separate from a digital signature. Permission descriptions name all allowed actions.

### Italiano (it)

Terms: Posta in arrivo; Posta in uscita; Posta inviata; Posta eliminata; Bozze; Posta indesiderata; messaggio; cartella;
account (masculine, invariable); allegato; contrassegno (contrassegnare); Rispondi a tutti; Inoltra; Bcc: Ccn; unread:
"da leggere".

- Informal "tu" ("Fai clic", "Scegli", "Inserisci").
- Message rules "elaborano" messages; reserve "ordinare" for the display order of a message list.
- Translate blocklist as "lista di blocco". In count summaries, use singular agreement when one item is possible.
- Use "firma digitale" where needed to distinguish cryptographic signatures from account signatures.
- Compose status describes protection applied "all’invio", not a completed delivery. Use "chiave utilizzabile"
  when sending needs a usable key, including expiry/revocation constraints. Encrypt "con" keys, not "per la chiave".
- Put complete key-state reasons after "Motivo:" with the next instruction separate, rather than in parentheses.
  Removing a recipient changes the message address fields, not the address book.
- Keep "passphrase", "chiave privata", "chiave pubblica" and "impronta digitale" consistent; key verification
  confirms ownership and requires checking every listed address before confirming.
- Participles agreeing with `$messages` choose by `$count` ("spostato" / "spostati"); "messaggio" is masculine,
  "posta" feminine ("Segna come indesiderata").
- `their-folders` = "cartelle diverse", so "spostati in { $folder }" works without an article;
  `transfer-another-account` = "un altro account".
- Sentence case; folder names keep their capitals. Quotes “ ” and apostrophe ’.
- Keys in catalog prose Ctrl / Maiusc / Canc, help `<kbd>` stays English; the Help menu is "?" as Italian Windows
  writes it. Raw network errors ("TLS error") are quoted in English in the help.

- For agent actions, use "annullare l’iscrizione" and "mailing list" with the existing reader command. An unsubscribe
  is a request, not a guarantee. "Testo della firma" is the optional account footer, distinct from "firma digitale".
- Draft removal uses "eliminare". Agents can permanently remove only their own unchanged drafts. Saving, including
  autosave, ends their access; opening a draft alone does not.

### Latviešu (lv)

Terms: Iesūtne; Izsūtne; Nosūtītie vienumi; Izdzēstie vienumi; Melnraksti; Nevēlamais e-pasts; ziņojums; mape; konts;
pielikums; karodziņš (Atzīmēt ar karodziņu); Atbildēt visiem; Pārsūtīt; Cc / Bcc: Kopija / Diskrētā kopija.

Plurals: `[zero]` (n%10 = 0 or n%100 = 11 to 19, genitive plural "10 ziņojumu"), `[one]` (n%10 = 1 and n%100 != 11, so
also 21, 31, 101), `*[other]` ("2 ziņojumi"). `[one]` always uses `{ $count }`; an explicit `[1]` branch comes first
where the singular reads better ("Pārvietot ziņojumu").

- Polite plural "jūs" ("Noklikšķiniet", "Ievadiet"); menus and buttons in the infinitive, sentence case.
- A verb or participle next to `$messages` agrees through `$count` (`[one]` Pārvietots, `*[other]` Pārvietoti).
- For actual folder names, inflect a head noun and quote the name ("uz mapi „{ $folder }”",
  "mapē „{ $from }”"). Where a destination can instead be `their-folders` ("to mapēm") or
  `transfer-another-account` ("citu kontu"), phrase the sentence to accommodate that fallback too.
- Quotes „…”; days of the week lowercase; keys unchanged.
- Access keys on ASCII letters only (no ā, č, ē and so on).

- Agent permissions use verbs for the available actions. Keep "adresātu saraksts" and "atteikties no abonēšanas"
  consistent with the reader command. The Windows unsubscribe buttons retain distinct ASCII A/N keys.
- Agent logs use third-person past-tense verbs for agent actions and polite plural for user decisions. Send logs
  describe queuing; an absent Outbox entry does not prove delivery. Subjects and actual folder names follow
  an inflected head noun and remain unchanged inside quotes. Use "darbība atsaukta" in the log wrapper.
- Agent-owned draft removal is permanent. Saving in the editor, including autosave, ends the agent's access;
  opening alone does not. "Paraksta teksts" is the optional account footer, distinct from "digitālais paraksts".
- The email warning says that message content is data, not instructions to follow. The unsubscribe quota counts
  user-approved list requests per program over the preceding 24 hours, including failed attempts.

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

- Agent additions retain "adresatų sąrašas" and use "prašymas atsisakyti prenumeratos". Logs label the
  message subject with "Laiškas:" and sender addresses with "Siuntėjai:". Keep the numeric count in all
  title branches, including 21. Windows unsubscribe buttons retain distinct A/N keys.
- Use "atmesti juodraštį" and explain that agent-owned drafts are permanently removed. Saving in the editor,
  including autosave, ends the agent's ability to edit/discard; opening alone does not. The optional account
  footer is "parašo tekstas", separate from cryptographic signing. Quoted controls follow an inflected head noun.
- Full agent help distinguishes approval, queuing and sending, and removal of saved program access from uninstalling.
  Email content is data, not instructions to follow. Normal deletion moves mail to the deleted-mail folder;
  an absent destination does not permit permanent deletion. Only the agent’s own drafts not yet saved by the user
  can be discarded permanently.

- Remaining agent core: send logs use "įtrauktas į siuntimo eilę" at queuing time. The Undo error says the
  message is no longer in "Siunčiami laiškai"; manual removal can also cause this, so it does not prove delivery.
  Reply/forward headings put an inflected "laiškas" before the untouched quoted subject. The number of new
  recipient addresses follows "skaičius:". Access summaries capitalize the first permission at runtime.
  Agent encrypted-message errors describe inaccessible content, without promising the user can decrypt it.

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
- The local mail store is "levéladatbázis", not the archival "levéltár". Rules "feldolgozzák" messages;
  "rendezés" is the list's sort order. Keep these terms in the remaining core and help review.
- Use "bejelentkezési adatok" for credentials, including browser sign-in, and "jelszó" only for passwords.
  An unprotected settings transfer requires signing in again, which may happen in the browser.
- Keep "titkos kulcs", "nyilvános kulcs", "ujjlenyomat" and "jelmondat" consistent. Message-signature text is
  "aláírás"; explain cryptographic signing as "digitális aláírás". A key's name may be an address or fingerprint,
  and verifying ownership requires checking every listed address as well as the fingerprint.
- Encrypted search uses available keys and stores decrypted content unencrypted in the local "keresési index".
  Disabling it removes that content from the index; agent searches cannot use it. Key lookup sends either an
  address or a key identifier. Preserve these distinctions in the remaining core/help review.
- Provider guidance must condition app-password use on account support. Outlook.com and Microsoft 365 use
  browser sign-in. List pictures refer to the column layout and verified domains, with cached logos reused.
- When Undo Send is too late, say "A küldés már nem vonható vissza". The expired delay does not prove delivery:
  `outbox::take_back` refuses once `not_before <= now`, even before the worker finishes sending.
- Core messages keep singular predicates after counts, including skipped entries and queued messages.
  Export failures label the failed and total counts separately; `$messages` remains an uninflected counted phrase.
  Bounce retry intervals describe the server's requested wait, not an instruction to resend delayed mail.
- Agent permissions use "Levelek kezelése", not the list-order term "rendezés". Send logs say "Küldési sorba
  helyezve" at queuing time. A failed agent undo says the message is no longer in Postázandó üzenetek; manual
  deletion can also cause this result, so it does not prove sending succeeded.
- Security details use "Visszafejtve" for decryption, and "digitális aláíró" for the signer. Verified key ownership
  is distinct from a valid signature. A locked private key requires reimporting its own backup, not the missing
  protection key. Publication requires confirmation of every listed address.
- Use "beállításfájl" for an exported setup file; it can contain accounts, contacts and keys as well as settings.
  An unreachable sign-in app message can name either that app or an account; tell the user to re-add the needed
  sign-in app. Temporary unencrypted attachment copies older than a day are removed at app startup.

- Agent additions keep formal, impersonal instructions without explicit "Ön". Use "leiratkozási kérelem",
  "levelezőlista" and "piszkozat elvetése". Logs introduce subjects with "Üzenet:" and addresses with "Feladók:".
  The retained Windows unsubscribe pair uses L/N. Titles and controls leave all placeables uninflected.
- Full agent help distinguishes approval from queuing/sending, limits approval to 30 list requests per program
  over the preceding 24 hours, and treats account "aláírásszöveg" as optional. Only own untouched drafts can
  be permanently discarded; saving in the editor, including autosave, ends that access. Opening alone does not.
- Email content is data, not instructions for the agent to follow. Do not claim that mail contains no instructions.
  Articles beside inserted labels follow their actual first sound: az Engedélyezés/Új cím/Eltávolítás/Eszközök,
  a Tiltás/Leiratkozás/Nincs leiratkozás/Módosítás/Visszavonás/Küldés/Szerkesztés.

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
- Compose status describes protection "bij het verzenden"; it does not report completed delivery. Use
  "bruikbare sleutel" when encryption requires a usable key, including expiry/revocation constraints.
- Encrypt "met" keys rather than "voor de sleutel". "Uit bericht verwijderen" changes recipients, not contacts.
  Place complete key-state reasons after "Reden:" and separate the next instruction instead of using parentheses.
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
- Compose status describes protection "når du sender den"; encrypted drafts are not signed. Use "brukbar nøkkel"
  when an available key must also be usable. Digital signatures do not by themselves confirm key ownership.
- Introduce complete key-state explanations with "Årsak:" and dates with "Siste søk:". Recipient removal affects
  message fields, not contacts. Sending without encryption requires removing inherited text, images and attachments.

- Agent unsubscribe buttons use "Meld meg av" / "Ikke meld meg av"; help and logs use "avmeldingsforespørsel"
  where a request, rather than a completed cancellation, is meant. "Signaturtekst" is the optional account footer.
- Keep "forkaste utkast" for abandoning an agent-created draft and explain that removal is permanent. Saving,
  including autosave, ends agent access; opening alone does not. Warn that email content must not be treated as
  instructions to the agent, not that messages cannot contain instructions.

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

- Agent status messages use impersonal forms, avoiding gendered user forms. Send logs describe adding a message
  to the sending queue; absence from the Outbox does not prove delivery. Subject placeholders follow "wiadomość".
- Retain "lista mailingowa" and "wypisz się". Logs label the source message subject and sender addresses separately.
  Windows unsubscribe controls keep distinct W/N keys. Ordinary read/organize summaries use consistent noun phrases.
- Draft removal uses "usunięto wersję roboczą". Only an agent's own drafts not yet saved by the user in the editor
  can be permanently removed. Saving including autosave ends access; opening alone does not. Account signature text
  ("tekst podpisu") is distinct from a digital signature ("podpis cyfrowy").
- "Oznaczenie śmieci" refers to the junk flag. Removing it does not delete the message. The email warning tells
  agents to treat message content as data, not as commands to execute.

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
- Compose status describes protection “no envio”, not completed delivery. Use “chave utilizável” when sending
  requires a usable key; expired/revoked keys also trigger missing-key guidance. Encrypt with keys, not “para a chave”.
- Put complete key-state reasons after “Motivo:” and separate the next instruction. Keep Brazilian você,
  criptografar, arquivo and backup; “Remover da mensagem” removes recipients, not address-book contacts.
- The additional sender-address field is “Outros endereços de envio”; use that exact label in errors and help.
  Use “ID do cliente” / “segredo do cliente” consistently for OAuth fields.

- Agent actions use "cancelar inscrições" and "listas de e-mails", matching the existing reader command. A request
  does not guarantee cancellation. "Texto da assinatura" is the optional account footer, distinct from "assinatura digital".
- Keep "descartar o rascunho" for abandoning an agent-created draft; explain that this permanently deletes it.
  Saving, including autosave, ends agent access; opening alone does not. Keep Brazilian "salvar", "contatos" and "você".

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
- Compose status describes protection "no envio", not completed delivery. Use "chave utilizável" when sending
  needs a usable key, including expiry/revocation constraints. Encrypt with keys, not "para a chave".
- Put complete key-state reasons after "Motivo:" and separate the next instruction. Recipient removal affects
  the message address fields, not the Livro de Endereços. Keep polite third-person wording without "você".
- "Credenciais de início de sessão" includes saved browser tokens. An unprotected export requires signing in
  again, not necessarily entering a password. Use "ID do cliente" and "segredo do cliente" for OAuth fields.

- Agent actions use "cancelar subscrições" and "listas de correio", matching the existing reader command. A request
  does not guarantee cancellation. "Texto da assinatura" is the optional account footer, distinct from "assinatura digital".
- Use "eliminar" for draft removal. Agents can permanently remove only their own unchanged drafts. Saving, including
  autosave, ends their access; opening a draft alone does not. Retain European Portuguese "guardar" and "contactos".

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

- Agent permissions use noun labels and "agent IA"; consent keeps polite plural forms and the D/N unsubscribe
  access keys. "Creare de schițe" distinguishes the permission from sending; each send needs approval.
- Agent logs use third-person past forms for agent actions and polite plural for the user's decisions. Subject
  placeholders follow "mesajul" or "Subiect:"; access summaries keep their independent account plurals.
- A send log describes the "coada de trimitere", before delivery. An unavailable Undo reports that the message
  is absent from "Mesaje de trimis", without claiming that it was delivered. The seconds value is always 30
  at this caller, so the confirmation uses "30 de secunde".
- "Cerere de dezabonare" names the request, not successful list removal. The quota counts approved requests
  per program over the preceding 24 hours, including failures. Mail content is data, not instructions to follow.
- Only the agent's own drafts not yet saved in the editor can be permanently deleted. Saving, including
  autosave, or sending ends agent access; merely opening does not. "Textul semnăturii contului" is optional
  message footer text, distinct from a digital signature. Removing program access does not uninstall it.

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

Slovak agent permissions and activity:

- Use "spravovať poštu" for managing mail, beyond sorting it. Permission summaries keep infinitives;
  activity logs use a clear head noun ("Správa", "Koncept") so participles agree and subjects need no inflection.
- Keep "konto", "priečinok", "koncept", "príjemca" and "odhlásiť odber". Refusal is "Neodhlásiť odber";
  Windows O/N access keys remain distinct. A dynamic folder name follows "do priečinka" in quotes.
- A queued agent message is not yet delivered. An unavailable Undo reports that it is no longer in
  "Pošta na odoslanie". The fixed 30-second caller uses "sekúnd"; all existing count branches remain.
- Unsubscribe approval is separate from success. The quota counts approved lists per program in the
  preceding 24 hours, including failures. "Textový podpis konta" is optional footer text, not a digital signature.
- The agent can permanently remove only its own drafts not saved by the user. Saving, including autosave,
  or sending ends its permission to edit/delete; merely opening does not. Other read permissions are separate.
- Mail may contain hostile instructions: explain that agents must not follow them. Disabling agent access
  uses the already reviewed neutral "vypnite možnosť" wording for the switch/checkbox on each platform.

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

Slovenian agent permissions and activity:

- Permission summaries use nouns ("branje", "urejanje", "pisanje osnutkov"). Keep masculine past agent logs,
  and insert "sporočilo" before a subject so its text never needs inflection. Folder names follow "v mapo" in quotes.
- "Razveljaviti" reverses an action; "preklicati pošiljanje" cancels queued sending. A send log records the queue,
  and unavailable Undo reports absence from "Odpošiljanje", without claiming delivery. The fixed 30-second value
  uses "sekund". All existing one/two/few/other account and unsubscribe branches and numeric placeholders remain.
- The unsubscribe count stays in parentheses after the list phrase, avoiding s/z choices before arbitrary
  numbers. The exact-one branch remains separate. Use imperative "Odjavi" on the shared action and Windows
  confirmation; "Ne odjavi" refuses. Windows O/N keys remain distinct. The shared action is also a reader link/title.
- Unsubscribe approval differs from success; the quota is per program over the preceding 24 hours, including
  failed approved requests. "Besedilni podpis računa" is optional footer text, not a cryptographic signature.
- Agents can permanently delete only their own drafts not saved by the user. Save/autosave or sending ends
  permission to edit/delete; opening alone does not. Independent read permission is separate. Removing access
  does not uninstall the program. Preserve the reviewed neutral shutdown instruction for switches/checkboxes.
- Email may contain hostile instructions; tell readers that agents must not follow them, rather than saying
  that email contains no instructions. Use polite plural address and the language's ordinary control labels.
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
- Compose explanations keep formal plural and feminine agreement with "poruka"; protection is applied "pri slanju".
  Use "upotrebljiv ključ" when keys must be usable, and distinguish digital-signature checks from key ownership.
- Compose recipient counts use exact `[1]`, then numeric `[one]` (21), `[few]` (2, 22), and `*[other]` (5, 11).
  Keep count placeholders in every category branch. Complete reasons follow "Razlog:", dates "Poslednja pretraga:".
- Unencrypted sending requires removing inherited text, images and attachments. Removing recipients affects the
  message fields, not contacts. Keep the existing "Žutonarandžasta" color term shared with reading-security help.

- Agent controls retain "Otkaži pretplatu" / "Nemoj otkazati pretplatu" (Windows O/N). Prose uses
  "otkazivanje pretplata" and "liste za slanje pošte"; a request does not guarantee that mail stops.
- Keep the numeric placeholder in the Serbian [one] title (21 lists); exact [1] handles one subscription.
  Refusal logs introduce sender addresses with "Pošiljaoci:", without attaching case endings to placeholders.
- Agent drafts use "radna verzija" and "odbaciti". Saving, including autosave, ends agent access; opening alone
  does not. "Tekst potpisa" is the optional account footer, distinct from a digital signature.

### Suomi (fi)

Terms: Saapuneet; Lähtevät; Lähetetyt; Poistetut; Luonnokset; Roskaposti; viesti; kansio; tili; liite; lippu (liputa,
Poista lippu); Vastaa kaikille; Välitä edelleen (toolbar: Välitä).

- Informal singular ("Valitse", "Kirjoita"); sentence case.
- Help terms: "työkalurivi", "lukuruutu", "tilarivi", "kansioluettelo". A collapsed conversation is
  "supistettu keskustelu"; its messages are hidden, not closed or ended.
- Placeables never inflect: a head noun takes the case ("kansioon { $folder }", "tililtä { $account }") or a label and
  colon is used ("Siirretty: { $messages }. Kohde: { $folder }"); `their-folders` and `transfer-another-account` are
  nominative to fit "Kohde:".
- Brand names that are not placeables inflect normally, without a colon ("Inbox Classicin", "Inbox Classicista").
- Participles choose by `$count` ("Merkitty luetuksi" / "Merkitty luetuiksi"); colours take the adessive inside the
  selector ("punaisella lipulla").
- Quotes ” ” (both U+201D), apostrophe ’; `ui-event-span` joins with a hyphen. Options, Settings and Preferences are
  all "Asetukset".
- Round 2: rules "käsittelevät" messages; "lajitella" means changing list order. Address-book Write To is
  "Kirjoita viesti". The local mail store is "postitietokanta".
- "Digitaalinen allekirjoitus" is cryptographic; "allekirjoitus" alone can mean the text appended to messages.
  "Avaimen haltija vahvistettu" identifies verified ownership, independently of signature validity. A key's
  displayed name may be an address or fingerprint. Check all listed addresses before selecting "Täsmäävät".
- "Kirjautumistiedot" includes passwords and OAuth credentials. An unprotected transfer requires another
  password or browser sign-in. "Salalause" protects an encrypted backup.
- Cc/Bcc are "Kopio" / "Piilokopio", with Alt+K/Alt+P in the compose window. The recipient picker has its own
  shortcut scope. Native ä/ö may be used when needed to keep menu shortcuts distinct.
  Open Draft and Not Junk never coexist: their folder roles are mutually exclusive.
  Additional platform checks cover Settings, accounts, folder/account context menus and the folder picker.
  "Siirrä alas" uses Alt+L and the copy dialog uses Alt+O to keep these scopes distinct.
- Sender images rely on authenticated domains, not verified people or message contents. Downloaded logos are
  cached and reused across messages; do not claim that each logo is only ever downloaded once.
- Use "tuotemerkin logo" consistently in help. OAuth "asiakassalaisuus" is the client secret;
  "käyttöoikeustunnus" is an access token. Keep both distinct from the client ID ("asiakastunnus").
- Agent send logs describe queuing ("Lisäsi ... lähetysjonoon"), while the sent status confirms actual sending.
  Permission descriptions apply to access through Inbox Classic. The current Windows access dialog measures
  and wraps permission checkboxes; use complete wording and "Poistetut-kansioon" for deletion by moving.
- "Salaus purettu avaimella" describes decryption, not encryption. A locked key requires restoring the private
  key backup; publication requires confirmation of every address. Unencrypted temporary attachment copies
  older than a day are removed at app startup, not automatically exactly one day after opening.
- Decryption "purkaa viestin salauksen", not "purkaa viestin". Use "hakuindeksi" for the local search index;
  disabling encrypted search removes the decrypted content from that index, not the messages themselves.

- Agent controls retain "Peruuta tilaus" / "Älä peruuta tilausta" (Windows P/L). Use "peruutuspyyntö" for
  the request, not completed cancellation. Logs label the subject as "Viesti:" and addresses as "Lähettäjät:".
- Keep "hylätä luonnos" and explain permanent removal of agent-owned drafts. Saving, including autosave,
  ends agent access; opening alone does not. "Allekirjoitusteksti" distinguishes the optional account footer.

### Svenska (sv)

Terms: Inkorgen; Utkorgen; Skickat; Borttaget; Utkast; Skräppost; meddelande (neuter); mapp; konto; bilaga; flagga;
Svara alla; Vidarebefordra; Cc / Bcc: Kopia / Hemlig kopia (Outlook).

- "du"; sentence case.
- "Arkiv" is both the File menu and the Archive folder; context keeps them apart, as on the platforms themselves.
- Special folders are Outlook's definite forms, written as names in running text ("flyttades till Inkorgen").
- `$messages` sentences need no ending; participles ("flyttat", "flyttade") choose by `$count`.
- Quotes ” ” (both the closing form), apostrophe ’; keys Ctrl / Skift / Del / Retur.
- The reply header is "Ursprungligt meddelande"; "Create Mail" is "Skapa e-post" as in Outlook Express.

Swedish agent permissions and activity:

- Use "hantera e-post" for organization beyond sorting; short permission summaries use "hantera". The read/unread
  flag is a "lästmarkering", not "läsläge" (a reading mode). Permission lists keep infinitives and logs use past tense.
- Logs distinguish putting a message in the send queue from delivery. An unavailable Undo says the message is
  absent from "Utkorgen". Introduce folder placeholders with "mappen" and quotes; no endings attach to names.
- Keep "Avsluta prenumeration" / "Avsluta inte" and the distinct Windows A/I keys. "Avanmälan" names the action;
  a request or approval does not prove the list stopped sending. The quota counts approvals per program over
  the preceding 24 hours, one per list, including failed attempts.
- "Textsignatur" is the optional account footer, distinct from a digital signature. Keep "du", sentence case,
  Swedish ” ” quotes, all existing plural branches and their numeric placeholders. The delay caller supplies 30.
- Permanent deletion is allowed only for the agent's own drafts not saved by the user. Save/autosave or sending
  ends permission to change/delete; opening alone does not. Read permission is separate. Removing program access
  does not uninstall it. Preserve the reviewed neutral connection-switch instruction.
- Explain that agents must not follow instructions in email; do not claim that email contains no instructions.

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
- Compose explanations describe protection "gönderilirken" and use "kullanılabilir anahtar" for usable keys.
  Names/addresses keep their original form; use "adresi" or a colon rather than suffixes on placeholders.
- Complete key-state reasons follow "Neden:", dates "Son arama:". Commands in prose take a head noun such as
  "seçeneği" or "penceresi". Digital signatures do not by themselves confirm who owns the key.
- "Şifrelemeden Gönder" uses Alt+N to avoid "Geçerli Olanı Koru" (Alt+G) in the recipient-key dialog.
  Unencrypted sending requires removing inherited text, images and attachments. Keep "Kehribar" consistent with
  the existing reading-security help; individual recipient symbols vary by platform.

- The checker reads a message only up to a `}` in column 0, so selectors that English puts first stay first
  (`done-flagged-color` ends with the colour; the Linux search result counts come before a colon).

- Agent controls retain "Abonelikten Çık" / "Abonelikten Çıkma" (Windows A/M, avoiding dotted/dotless i).
  Use "abonelikten çıkma isteği" for the request; it does not guarantee that mail stops. Refusal logs use
  "Gönderenler:" before address placeholders, without suffixes.
- Agent-owned draft discard is "taslağı silme", with permanent deletion explained in help. Saving, including
  autosave, ends agent access; opening alone does not. "İmza metni" is the optional account footer, not a digital signature.

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
- Rules επεξεργάζονται messages; use πληρούν τα κριτήρια for matches and reserve ταξινόμηση for list order.
- Distinguish ψηφιακή υπογραφή from the signature text appended to messages. Key ownership is a separate
  check (επαληθευμένος κάτοχος). Verify every address before selecting Ταιριάζουν. A key's displayed name
  may be an address or fingerprint, so put it in parentheses without treating it as a person's name.
- Στοιχεία σύνδεσης includes passwords and browser/OAuth tokens. Importing an unprotected settings file
  requires signing in again, possibly in a browser. Keep φράση πρόσβασης for protected exports and backups.
- Account/provider names and nominative fallbacks can lead a sentence followed by a colon. The Address Book
  action Σύνταξη μηνύματος opens the compose window. Cc/Bcc remain Κοιν. / Ιδ. κοιν., with Alt+Κ / Alt+Ι
  in Windows/Linux; explain these beside the unchanged literal English keyboard tags in help.
- Menu access letters may appear lowercase in a label; their uppercase form must be an unaccented Greek
  letter. Check shared menu/dialog scopes, including the two separate flag entries in the Message menu.
- The unaccented-letter rule applies to explicit catalog mnemonics. The Windows Flag submenu generates its
  own mnemonics in `app/src/mailbox.cpp::FlagMenu`: its first-unused-letter algorithm can select ί in
  "Κίτρινο" after Κ was used for "Κόκκινο". Preserve the correct colour spelling; this needs an app-side
  review, not a translation workaround. Collision checks alone do not validate that generated shortcut.

- Agent consent uses "Κατάργηση εγγραφής" / "Διατήρηση εγγραφής", with distinct unaccented Greek Κ/Δ access keys.
  The latter keeps the subscription and sends no request. "Αίτημα κατάργησης εγγραφής" is not a completed cancellation.
- Logs label the subject as "Μήνυμα:" and addresses as "Αποστολείς:"; agent names follow "Ο πράκτορας ΤΝ" unchanged.
- Keep "απόρριψη πρόχειρου" and explain permanent removal of agent-owned drafts. Saving, including autosave,
  ends agent access; opening alone does not. "Κείμενο της υπογραφής" distinguishes the optional account footer.

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
- Compose controls and tooltips keep verbal nouns; explanations use polite plural and „при изпращане“.
  Use „използваем ключ“ when keys must be usable. Digital signatures do not themselves establish ownership.
- Complete reasons follow „Причина:“, dates „Последно търсене:“. Recipients are people, so counts keep
  „получатели“, not the count form used for objects. Names/addresses remain unchanged.
- „Намиране на ключ“ uses Cyrillic Alt+К to avoid „Използване на новия ключ“ (Alt+Н) in the recipient dialog.
  Unencrypted sending requires removing inherited text/images/attachments. Keep „Кехлибарен“ consistent with
  the reading-security help and quote the folder title „Изпратени“ in prose.

- Agent consent controls use "Отписване" / "Без отписване", with distinct Cyrillic О/Б access keys.
  "Заявка за отписване" describes a request, not a guarantee. Refusal logs use "Податели:" before addresses.
- Retain "чернова" / "премахване" for agent-owned drafts and explain permanent removal in help. Saving,
  including autosave, ends agent access; opening alone does not. "Текстът на подписа" is the optional account footer.
  Quote folder names in prose, including the rendered "Изтрити" and "Нежелана поща" controls.

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

- Agent permissions use "управление почтой" for organization beyond sorting, consistently in catalogs and all
  three agent help topics. Use "ИИ-агент", "черновик", "запрос на отписку" and the existing Cyrillic О/Н keys.
- Agent logs keep impersonal past forms and describe the send queue before delivery. An unavailable Undo says
  that the message is absent from "Исходящие", without claiming delivery. A folder name follows "в папку" in
  quotes so custom names need no inflection. The seconds caller supplies only 30, so "30 секунд" is grammatical.
- Keep all Russian account and unsubscribe plural branches, including the numeric placeholder in `[one]` for
  21 and higher. Account counts are independent of the permission list. Subject placeholders follow "сообщение"
  or "Тема:" where the surrounding grammar needs a head noun.
- The unsubscribe quota counts approved requests per program over the preceding 24 hours, including failures.
  Mail content must be treated as data, not instructions to follow. The optional "текстовая подпись" is the
  account footer, distinct from a digital signature.
- Only the agent's own drafts not yet saved by the user can be permanently removed. Saving, including autosave,
  or sending ends access; merely opening does not. Removing a program's access does not uninstall the program.
  Use "отключите" for the connection control, since Linux has a switch and the other platforms use checkboxes.

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

Ukrainian agent permissions and activity:

- Keep polite lowercase "ви", infinitive permission labels and impersonal past-tense activity logs. "Сервіс" remains
  the actual Tools menu label in this batch. Subject/folder placeholders keep guillemets and no added endings.
- "Упорядковувати пошту" covers organization. A read/unread flag is "стан прочитання". The send log records
  "додано до черги надсилання", and an unavailable Undo reports absence from "Вихідні", not proven delivery.
- Keep "Скасувати підписку" / "Не скасовувати підписку" and distinct Windows С/Н access keys. Refusing a request,
  approving one and its HTTP outcome are separate. The quota counts approved lists per program over the last 24 hours.
- Agent-owned drafts may be removed "назавжди". User save, autosave or sending ends the agent's edit/remove rights;
  merely opening a draft does not. This does not revoke an independent permission to read mail.
- "Текстовий підпис" is the optional message footer, separate from a cryptographic signature. Instructions inside
  mail must not be followed by the agent; do not claim that email cannot contain instructions.
- Preserve one/few/many/other with numeric placeholders, plus exact-zero account and exact-one unsubscribe branches.
