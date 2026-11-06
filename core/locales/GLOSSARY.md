# Translation glossary

The words of the windows live in the Fluent files of this folder, one folder a language: `core.ftl` for what the core
says (the same on every platform), `app.ftl` for the windows (menus, commands, dialogs, and the words the windows of
more than one platform share, `ui-` ids), and `windows.ftl`, `mac.ftl` and `linux.ftl` for words only one platform
has. English (`en`) is the source;
a word a language does not have yet is shown in English. The user help is `core/crates/pe-html/src/help.<lang>.html`.

**Status: the German, Estonian, French and Spanish files and help pages are drafts, written without a native
speaker. They need a native review before a release lists the language.**

Rules for every language:

- Keep the `{ $placeables }` the English message has, no more and no fewer (a test checks it); put them where the
  language needs them.
- Plurals: use the categories of the language (`[one]`, `[few]`, `[many]`, `*[other]`, as CLDR has them); `*[other]`
  is the default.
- An `&` marks the menu letter on Windows and Linux; choose a letter of your own word, different within one menu.
- No en or em dashes (a test checks it): commas, colons or separate sentences instead.
- "Re: " and "Fw: " in the subjects of replies and forwards stay English in every language (every mail program
  threads by them); the "Original Message" block of a reply follows the language.
- Keys in the help stay `<kbd>Ctrl</kbd>`, `<kbd>Shift</kbd>`, `<kbd>Alt</kbd>`, `<kbd>Del</kbd>`, `<kbd>Enter</kbd>`
  in every language: the page names them as the keyboard does (`key-*` in `core.ftl`, and the Mac's symbols there).

## Fixed terms

The terms of Outlook Express and Outlook in each language, kept the same everywhere.

| English            | Deutsch                | Eesti                 | Français                  | Español                        |
| ------------------ | ---------------------- | --------------------- | ------------------------- | ------------------------------ |
| Inbox              | Posteingang            | Sisendkaust           | Boîte de réception        | Bandeja de entrada             |
| Outbox             | Postausgang            | Väljundkaust          | Boîte d'envoi             | Bandeja de salida              |
| Sent Items         | Gesendete Objekte      | Saadetud kirjad       | Éléments envoyés          | Elementos enviados             |
| Deleted Items      | Gelöschte Objekte      | Kustutatud kirjad     | Éléments supprimés        | Elementos eliminados           |
| Drafts             | Entwürfe               | Mustandid             | Brouillons                | Borradores                     |
| Junk E-mail        | Junk-E-Mail            | Rämpspost             | Courrier indésirable      | Correo no deseado              |
| Archive            | Archiv                 | Arhiiv                | Archives                  | Archivo                        |
| All Inboxes        | Alle Posteingänge      | Kõik sisendkaustad    | Toutes les boîtes         | Todas las bandejas de entrada  |
| message            | Nachricht              | kiri                  | message                   | mensaje                        |
| folder             | Ordner                 | kaust                 | dossier                   | carpeta                        |
| account            | Konto                  | konto                 | compte                    | cuenta                         |
| attachment         | Anlage                 | manus                 | pièce jointe              | archivo adjunto                |
| flag               | Kennzeichnung          | lipp                  | indicateur                | marca                          |
| Send/Recv          | Senden/Empfangen       | Saada/Võta vastu      | Envoyer/Recevoir          | Enviar y recibir               |
| Reply to Sender    | Antworten              | Vasta saatjale        | Répondre à l'expéditeur   | Responder al remitente         |
| Reply to All       | Allen antworten        | Vasta kõigile         | Répondre à tous           | Responder a todos              |
| Forward            | Weiterleiten           | Edasta                | Transférer                | Reenviar                       |
| Mark as Junk       | Als Junk markieren     | Märgi rämpspostiks    | Marquer comme indésirable | Marcar como correo no deseado  |
| Move to Folder     | In Ordner verschieben  | Teisalda kausta       | Déplacer vers un dossier  | Mover a carpeta                |
| Copy to Folder     | In Ordner kopieren     | Kopeeri kausta        | Copier vers un dossier    | Copiar a carpeta               |
| Undo               | Rückgängig             | Võta tagasi           | Annuler                   | Deshacer                       |
| Select All         | Alles auswählen        | Vali kõik             | Sélectionner tout         | Seleccionar todo               |
| Recent             | Zuletzt verwendet      | Viimati kasutatud     | Récents                   | Recientes                      |
| Flag (menu)        | Kennzeichnung          | Lipp                  | Indicateur                | Marca                          |
| Clear Flag         | Kennzeichnung löschen  | Eemalda lipp          | Effacer l'indicateur      | Quitar marca                   |
| Red                | Rot                    | Punane                | Rouge                     | Rojo                           |
| Orange             | Orange                 | Oranž                 | Orange                    | Naranja                        |
| Yellow             | Gelb                   | Kollane               | Jaune                     | Amarillo                       |
| Green              | Grün                   | Roheline              | Vert                      | Verde                          |
| Blue               | Blau                   | Sinine                | Bleu                      | Azul                           |
| Purple             | Lila                   | Lilla                 | Violet                    | Morado                         |
| Gray               | Grau                   | Hall                  | Gris                      | Gris                           |
| sign-in app        | Anmelde-App            | sisselogimisrakendus  | application de connexion  | aplicación de inicio de sesión |
| AI agent           | KI-Agent               | tehisintellekti agent | agent d'IA                | agente de IA                   |
| client ID          | Client-ID              | kliendi ID            | ID client                 | ID de cliente                  |
| client secret      | Client-Geheimnis       | kliendi saladus       | secret client             | secreto de cliente             |
| issuer (OAuth)     | Aussteller             | väljaandja            | émetteur                  | emisor                         |
| sign-in app        | Anmelde-App            | sisselogimisrakendus  | application de connexion  | aplicación de inicio de sesión |
| File > Accounts    | Datei > Konten         | Fail > Kontod         | Fichier > Comptes         | Archivo > Cuentas              |
| Tools              | Extras                 | Tööriistad            | Outils                    | Herramientas                   |
| Ctrl / Shift / Del | Strg / Umschalt / Entf | Ctrl / Shift / Del    | Ctrl / Maj / Suppr        | Ctrl / Mayús / Supr            |

Forms of address: German uses "Sie", French "vous", Spanish "usted", Estonian the polite plural ("teie").

Notes for the native review:

- Colours in sentences ("Flagged 2 messages blue") take the language's own form through a selector on the colour (`done-flagged-color`), never the English name lowercased.
- Status texts that name a number of messages ("{ $messages } déplacés vers") choose by `$count` so the words agree
  with it (`[one]` and `*[other]`, more forms where the language has them); English has the one form under `*[other]`.
