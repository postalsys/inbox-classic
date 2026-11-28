# The words of the windows, the same on every platform. An & marks the letter of a menu item that Alt and the letter
# choose on Windows and Linux (&& is an ampersand); the Mac leaves it out. Put it on a letter of your word, a different
# one for each item of a menu where you can.

## The menus

menu-file = &Fișier
menu-edit = &Editare
menu-view = &Vizualizare
menu-tools = &Instrumente
menu-message = &Mesaj
menu-help = &Ajutor
menu-layout = As&pect
menu-sort-by = Sor&tare după
menu-text-size = &Dimensiune text
menu-folder = Fo&lder
menu-insert = I&nserare

## The commands of the menus, the toolbar and the tray (core/commands.toml)

cmd-new-account = Cont &nou...
cmd-exit = &Ieșire
cmd-sync = &Trimitere și primire în toate conturile
cmd-mark-read = Marcare ca &citit
cmd-mark-unread = Marcare ca &necitit
cmd-pictures = Descărcare &imagini
cmd-about = &Despre Inbox Classic
cmd-new-mail = Mesaj &nou
cmd-reply = Răspuns e&xpeditorului
cmd-reply-all = Răspuns la &toți
cmd-forward = Re&direcționare
cmd-help = &Cuprins
cmd-delete = Ștergere &mesaj
cmd-move = Mutare în &folder...
cmd-flag = &Semnalizare mesaj
cmd-new-folder = &Folder nou...
cmd-rename-folder = &Redenumire folder...
cmd-delete-folder = Ștergere f&older
cmd-empty-folder = &Golire folder
ui-empty-button = Golire
cmd-accounts = &Conturi...
cmd-find = Căutare me&saj
cmd-save-as = &Salvare ca...
cmd-print = Im&primare...
cmd-print-conversation = Imprimare con&versație...
cmd-import = Import &mesaje...
cmd-outbox = Mesaje de t&rimis...
cmd-properties = Propri&etăți
cmd-mark-all-read = Marcare toate ca c&itite
cmd-junk = &Marcare ca nedorit
cmd-not-junk = Anu&lare marcare ca nedorit
cmd-archive = &Arhivare
cmd-watch-conversation = &Urmărire conversație
cmd-ignore-conversation = &Ignorare conversație
cmd-next-message = Mesajul &următor
cmd-previous-message = Mesajul &anterior
cmd-next-unread = Următorul mesaj &necitit
cmd-go-to-folder = &Salt la folder...
cmd-find-in-message = Căutare în acest m&esaj...
ui-go-to-prompt = Salt la folderul:
ui-find-in-message-hint = Căutare în acest mesaj
ui-find-not-found = „{ $words }” nu apare în acest mesaj
cmd-expand-all-threads = &Extindere toate conversațiile
cmd-collapse-all-threads = &Restrângere toate conversațiile
cmd-next-in-conversation = Mesaju&l următor din conversație
cmd-previous-in-conversation = Mesajul anterior din con&versație
cmd-open-all-messages = Desc&hidere toate mesajele
cmd-fold-all-messages = Restrângere t&oate mesajele
ui-group-by-conversation = Grupare mesa&je după conversație
ui-show-whole-conversation = Afișare conversație întrea&gă în panoul de citire
ui-show-whole-conversation-note = Deschideți împreună mesajele conversației, inclusiv răspunsurile dvs., schițele și mesajele din alte foldere. Mesajele citite sunt de obicei restrânse la un rând. Folosiți săgeata fiecărui mesaj pentru a-l deschide sau a-l restrânge.
ui-conversation-order = &Ordine în conversație:
ui-conversation-oldest-first = Cele mai vechi primele
ui-conversation-newest-first = Cele mai noi primele
ui-thread-count = { $new ->
    [0] ({ $count })
    [one] ({ $count }, { $new } nou)
   *[other] ({ $count }, { $new } noi)
}
ui-conversation-to = către { $people }
ui-conversation-draft = Schiță
ui-conversation-downloading = Se descarcă…
ui-conversation-you = Eu
ui-conversation-messages = { $count ->
    [one] 1 mesaj
    [few] { $count } mesaje
   *[other] { $count } de mesaje
}
ui-conversation-unread = { $count ->
    [one] 1 necitit
    [few] { $count } necitite
   *[other] { $count } de necitite
}
ui-conversation-found-in = Găsit în { $folder }
ui-conversation-hidden = { $count ->
    [one] Încă 1 mesaj
    [few] Încă { $count } mesaje
   *[other] Încă { $count } de mesaje
}
ui-conversation-open-message = Deschidere mesaj
ui-conversation-fold-message = Restrângere mesaj
ui-conversation-more = Mai multe
ui-conversation-edit = Editare
ui-conversation-elsewhere = { $count ->
    [one] Această conversație are și un mesaj în alt folder.
    [few] Această conversație are și { $count } mesaje în alte foldere.
   *[other] Această conversație are și { $count } de mesaje în alte foldere.
}
ui-conversation-this-folder = &Doar acest folder
ui-conversation-whole = &Toată conversația
cmd-folder-list = Listă de &foldere
cmd-layout-automatic = &Automat
cmd-layout-classic = &Clasic
cmd-layout-columns = C&oloane
cmd-sort-date = &Dată
cmd-sort-from = &Expeditor
cmd-sort-subject = &Subiect
cmd-sort-size = &Mărime
cmd-sort-ascending = Sortare &ascendentă
cmd-sort-descending = Sortare desce&ndentă
cmd-text-size-largest = Cea mai m&are
cmd-text-size-larger = Mai ma&re
cmd-text-size-medium = &Medie
cmd-text-size-smaller = Mai m&ică
cmd-text-size-smallest = Cea mai mi&că
cmd-hide-ignored = Ascundere conversații i&gnorate
cmd-hide-read = Ascundere mesaje &citite
cmd-notify = Notificare la &mesaje noi
cmd-open = &Deschidere Inbox Classic
cmd-default-app = &Setare ca aplicație de e-mail implicită...
cmd-view-source = Sursa &mesajului
cmd-ai-agents = Agenț&i IA...
cmd-options = &Opțiuni...
cmd-message-rules = Reguli pentru m&esaje...
cmd-encryption-keys = &Chei de criptare...
cmd-create-rule-from-message = Creare regulă din mesa&j...
cmd-unsubscribe = D&ezabonare de la listă...
cmd-select-all = Selectare &totală
cmd-undo = An&ulare
cmd-copy = C&opiere în folder...
cmd-address-book = &Agendă...
cmd-add-sender-to-book = Adău&gare expeditor în agendă
cmd-import-address-book = Import agen&dă...
cmd-export-address-book = E&xport agendă...
cmd-export-setup = Export setări și con&turi...
cmd-import-setup = Import setări și cont&uri...
cmd-compose-sign = &Semnare digitală
cmd-compose-encrypt = &Criptare
cmd-attach-my-key = Atașare cheie &publică proprie

## The tray icon's menu

tray-check = &Verificare mesaje noi
tray-no-accounts = Niciun cont încă

## Words the windows of more than one platform share

ui-tb-create-mail = Mesaj nou
ui-tb-reply = Răspuns
ui-tb-reply-all = Răspuns la toți
ui-tb-forward = Redirecționare
ui-tb-print = Imprimare
ui-tb-delete = Ștergere
ui-tb-junk = Nedorit
ui-tb-not-junk = Nu este nedorit
ui-tb-archive = Arhivare
ui-tb-previous = Anterior
ui-tb-next = Următor
ui-previous-tip = Mesajul anterior
ui-next-tip = Mesajul următor
ui-tb-sync = Trimitere/primire
ui-tb-mark-read = Marcare citit
ui-tb-mark-unread = Marcare necitit
ui-still-running = Inbox Classic rulează în continuare
ui-no-subject = (fără subiect)
ui-quoted = „{ $subject }”
ui-newest-from = Cel mai recent mesaj de la { $sender }: { $subject }
ui-new-messages = { $count ->
    [one] { $count } mesaj nou
    [few] { $count } mesaje noi
   *[other] { $count } de mesaje noi
}
ui-outbox-waiting = { $count ->
    [one] 1 mesaj în folderul „Mesaje de trimis”
    [few] { $count } mesaje în folderul „Mesaje de trimis”
   *[other] { $count } de mesaje în folderul „Mesaje de trimis”
}
ui-outbox-waits = Mesajul { $subject } așteaptă în folderul „Mesaje de trimis”
ui-outbox-sending = Se trimite mesajul { $subject }...
ui-from-account = Din contul „{ $account }”
ui-sign-in-refused = Conectarea la contul „{ $account }” a fost refuzată sau sesiunea a expirat.
ui-sign-in-again-ask = Doriți să vă conectați din nou în browser?
ui-sign-in-again-failed = Nu s-a putut face reconectarea: { $reason }
ui-unknown-reason = motiv necunoscut
ui-checking = Se caută mesaje noi în contul „{ $account }”...
ui-done = Gata
ui-sent-at = Mesajul { $subject } a fost trimis la { $time }
ui-draft-saved = Mesaj salvat în folderul „Schițe”
ui-draft-not-saved = Mesajul nu a fost salvat în folderul „Schițe”: { $reason }
ui-about-core = Nucleu { $version }
ui-add-account-first = Adăugați mai întâi un cont de e-mail.
ui-add-account-first-link = Adăugați mai întâi un cont de e-mail, apoi faceți din nou clic pe linkul de e-mail.
ui-default-app-is = Inbox Classic este aplicația dvs. de e-mail implicită: linkurile de e-mail deschid aici un mesaj nou.
ui-select-message-first = Selectați mai întâi un mesaj.
ui-store-not-opened = Nu s-a putut deschide baza de date a mesajelor.
ui-store-or-cert-not-opened = Nu s-a putut deschide baza de date a mesajelor sau fișierul certificatului.
ui-help-title = Ajutor Inbox Classic
ui-help-missing = Această copie a aplicației Inbox Classic nu include fișierele de ajutor.
ui-ok = OK
ui-cancel = Anulare
ui-close = Închidere
ui-col-subject = Subiect
ui-col-from = Expeditor
ui-col-to = Destinatari
ui-col-received = Primit
# the column of the glasses of a watched conversation (and the sign of an ignored one)
# a notification of new mail in a watched conversation, over who it is from
ui-watched-conversation = Conversație urmărită
ui-col-sent = Trimis
ui-col-size = Mărime
ui-col-folder = Folder
ui-col-account = Cont
ui-col-queued = În așteptare din
ui-col-status = Stare
ui-outbox-title = Mesaje de trimis
ui-outbox-status-waiting = În așteptare
ui-outbox-status-not-sent = Netrimis: { $reason }
# This message is still queued, during the grace period before an agent’s send.
ui-outbox-status-agent = Adăugat de un agent IA; trimitere cel mai devreme la { $time }
ui-outbox-delete-ask = Ștergeți acest mesaj fără să îl trimiteți?
ui-open-link = Deschidere link
ui-edit-link = Editare link...
ui-remove-link = Eliminare link
ui-insert-attachment = Inserare atașare
ui-insert-picture = Inserare imagine
ui-filter-all = Toate fișierele
ui-filter-pictures = Imagini
ui-filter-messages = Mesaje de e-mail
ui-save-attachment-as = Salvare atașare ca
ui-not-sent = Mesajul nu a putut fi trimis.
ui-attachment-forgotten = Ați scris „{ $word }”, dar nu este atașat niciun fișier. Trimiteți totuși mesajul?
ui-send-anyway = Trimitere oricum
ui-go-back = Înapoi
ui-not-saved = Mesajul nu a putut fi salvat.
ui-saving-draft = Se salvează în folderul „Schițe”...
ui-compose-saved-at = Salvat în folderul „Schițe” la { $time }
ui-compose-restored = Mesaj recuperat după ce Inbox Classic s-a închis neașteptat
ui-compose-not-saved = Nesalvat în folderul „Schițe”: { $reason }
ui-save-changes-ask = Salvați modificările acestui mesaj în folderul „Schițe”?
ui-new-message-title = Mesaj nou
ui-link-invalid = Introduceți o adresă web (https://...) sau un link de e-mail (mailto:...).
ui-link-address = Adresă:
ui-hyperlink = Hyperlink
ui-hyperlink-intro = Adresa către care duce textul selectat.
ui-edit-hyperlink = Editare hyperlink
ui-edit-hyperlink-intro = Adresa de destinație a linkului. Ștergeți adresa pentru a elimina linkul și a păstra textul.
ui-not-a-picture = Imaginea nu a putut fi inserată. Alegeți un fișier PNG, JPEG, GIF sau WebP de cel mult 10 MB.
ui-format-color = Culoare font
ui-format-numbers = Listă numerotată
ui-format-bullets = Listă cu marcatori
ui-format-outdent = Micșorare indentare
ui-format-indent = Mărire indentare
ui-format-left = Aliniere la stânga
ui-format-center = Centrare
ui-format-right = Aliniere la dreapta
ui-format-line = Inserare linie orizontală
ui-tb-send = Trimitere
ui-tb-save = Salvare
ui-tb-attach = Atașare
ui-tb-sign = Semnare
ui-tb-encrypt = Criptare
ui-field-keys = Chei:
ui-field-from = De la:
ui-field-to = Către:
ui-field-cc = Cc:
ui-field-bcc = Bcc:
ui-field-subject = Subiect:
ui-field-attach = Atașări:
ui-signature = Textul semnăturii
ui-signature-hint = Se adaugă mesajelor noi, răspunsurilor și mesajelor redirecționate pe care le trimiteți din acest cont.
ui-signature-not-saved = Textul semnăturii nu a putut fi salvat.
ui-all-inboxes = Toate mesajele primite
ui-all-sent = Toate mesajele trimise
ui-all-drafts = Toate schițele
ui-flagged-folder = Semnalizate
ui-all-folders = Toate folderele
ui-the-account = contul
ui-folder-name = Nume folder:
ui-find-hint = Căutare mesaje
ui-find-tip = Caută în subiectele și textul mesajelor, în numele și adresele expeditorilor și destinatarilor, precum și în numele atașărilor.
ui-clear-search = Ștergere căutare
ui-no-match = Niciun mesaj nu se potrivește cu „{ $words }”.
ui-no-match-all = În toate folderele, se caută în subiectele și textul mesajelor, în numele și adresele expeditorilor și destinatarilor, precum și în numele atașărilor. Verificați ortografia sau încercați mai puține cuvinte.
ui-no-match-in = În „{ $folder }”, se caută în subiectele și textul mesajelor, în numele și adresele expeditorilor și destinatarilor, precum și în numele atașărilor. Verificați ortografia sau încercați mai puține cuvinte.
ui-no-items = Nu există mesaje în această vizualizare.
ui-choose-folder = Alegeți un folder pentru a-i vedea mesajele.
ui-unsubscribe = Dezabonare
ui-open-in-calendar = Deschidere în Calendar
ui-pictures-blocked = Unele imagini au fost blocate pentru a limita urmărirea deschiderii mesajului de către expeditor.
ui-not-shown = Mesajul nu a putut fi afișat.
ui-attachment-not-read = Atașarea nu a putut fi citită.
ui-attachment-not-saved = Atașarea nu a putut fi salvată.
ui-not-downloaded = Mesajul nu este descărcat încă.
ui-leave-list = Vă dezabonați de la această listă de corespondență?
ui-leave-one-click = Inbox Classic va trimite o cerere de dezabonare către { $target }. Nu se va deschide nicio pagină web și nu se va trimite niciun e-mail.
ui-leave-mail = Pentru dezabonare, trimiteți un e-mail la { $target }. Inbox Classic îl pregătește pentru dvs. Trimiteți mesajul pentru a confirma.
ui-leave-web = Pagina de dezabonare a listei de corespondență se va deschide în browser ({ $target }).
ui-unsubscribing = Se face dezabonarea de la { $target }...
ui-cannot-unsubscribe = Acest mesaj nu oferă o opțiune de dezabonare.
ui-unsubscribed = Cererea de dezabonare a fost acceptată.
ui-not-unsubscribed = Dezabonarea nu a reușit: { $reason }
ui-list-bar = Acest mesaj este de la o listă de corespondență ({ $domain }).
ui-list-bar-plain = Acest mesaj este de la o listă de corespondență.
ui-list-bar-asked = Ați solicitat dezabonarea de la această listă la { $date }.
ui-list-bar-came-after = Ați solicitat dezabonarea la { $date }, dar acest mesaj a sosit cu mai mult de două zile mai târziu.
ui-list-bar-opened = Ați deschis pagina de dezabonare a acestei liste la { $date }.
ui-list-bar-failed = Cererea de dezabonare a eșuat: { $reason }
ui-unsubscribe-ask = Dezabonare…
ui-unsubscribe-again = Dezabonare din nou…
ui-event-span = De la { $start } până la { $end }
ui-event-floating = { $when } (fus orar nespecificat sau necunoscut)
ui-invitation = Invitație: { $title }
ui-invitation-updated = Invitație actualizată: { $title }
ui-invitation-canceled = Eveniment anulat: { $title }
ui-invitation-answer = Răspuns la o invitație: { $title }
ui-no-title = (fără titlu)
ui-organizer = Organizator: { $name }
ui-invitation-not-read = Invitația nu a putut fi citită.
ui-no-calendar = Invitația nu a putut fi deschisă într-o aplicație de calendar. Verificați aplicația asociată fișierelor .ics.
ui-messages-not-changed = Mesajele nu au putut fi modificate.
ui-new-folder-in-selected = Folderul nou va fi creat în folderul selectat.
ui-new-folder-at-top = Folderul nou va fi creat la nivelul principal al contului.
ui-folder-not-created = Folderul nu a putut fi creat.
ui-folder-not-renamed = Folderul nu a putut fi redenumit.
ui-folder-not-deleted = Folderul nu a putut fi șters.
ui-rename-folder-intro = Introduceți un nume nou pentru folderul „{ $folder }”.
ui-properties-of = Proprietăți: { $subject }
ui-internet-headers = Anteturile de internet ale acestui mesaj:
ui-save-messages-in = Folder pentru salvarea mesajelor
ui-save-message-as = Salvare mesaj ca
ui-import-choose-folder = Alegeți mai întâi folderul în care să fie importate mesajele.
ui-add-account-title = Adăugare cont de e-mail
ui-accounts-title = Conturi
ui-security-none = Fără criptare
ui-field-required = Completați câmpul „{ $field }”.
ui-email-invalid = Adresa de e-mail nu este validă.
ui-ports-invalid = Porturile sunt numere de la 1 la 65535.
ui-looking-up = Se caută setările pentru { $domain }...
ui-found-none = Introduceți datele contului primite de la furnizorul de e-mail.
ui-found-change = Modificați aceste setări dacă furnizorul v-a indicat altele.
ui-found-guess = Nu s-au găsit setări pentru această adresă. Numele de server sugerate nu au fost confirmate. Verificați-le cu furnizorul de e-mail.
ui-found-mx = Inbox Classic a identificat furnizorul dvs. de e-mail și a completat setările serverelor acestuia.
ui-found-srv = Aceste setări au fost găsite în înregistrările DNS ale domeniului dvs.
ui-found-autodiscover = Aceste setări au fost găsite prin Microsoft Autodiscover (Exchange).
ui-found-other = Aceste setări au fost găsite pentru această adresă.
ui-app-password-needed = { $provider } nu acceptă parola obișnuită în programele de e-mail. Dacă acest cont permite parole de aplicație, creați una în contul { $provider } și introduceți-o în câmpul Parolă din formularul următor. Pentru Outlook.com și Microsoft 365, folosiți conectarea prin browser.
ui-app-password-open = Deschideți în browser instrucțiunile oferite de { $provider }?
ui-plain-warning = Fără criptare, oricine interceptează traficul de rețea vă poate citi parola și mesajele. O rețea locală nu protejează singură conexiunea. Continuați numai dacă conexiunea este protejată în alt mod.
ui-continue-ask = Continuați?
ui-add-sign-in-app = Adăugare aplicație de conectare...
ui-turned-off = Opțiunea „{ $name }” este dezactivată pe acest computer.
ui-off-here = Dezactivată pe acest computer.
ui-why = De ce?
ui-more-sign-in = Mai multe opțiuni de conectare...
ui-other-account = Pentru a adăuga alt cont de e-mail, introduceți adresa de e-mail și numele pe care doriți să îl vadă destinatarii. Aplicația va căuta apoi setările serverelor.
ui-field-account-name = Nume cont:
ui-field-name = Nume afișat:
ui-field-email = Adresă de e-mail:
ui-field-user = Nume utilizator:
ui-field-password = Parolă:
ui-field-imap-host = Server de intrare (IMAP):
ui-field-imap-port = Port IMAP:
ui-field-imap-security = Securitate IMAP:
ui-field-smtp-host = Server de ieșire (SMTP):
ui-field-smtp-port = Port SMTP:
ui-field-smtp-security = Securitate SMTP:
ui-field-other-addresses = Alte adrese de la care trimiteți:
ui-sign-in-not-started = Nu s-a putut iniția conectarea prin browser.
ui-sign-in-in-browser = Conectați-vă la contul „{ $account }” în fereastra de browser care s-a deschis, apoi reveniți aici.
ui-sign-in-failed = Conectarea nu a reușit: { $reason }
ui-account-not-saved = Contul nu a putut fi salvat.
ui-start-intro = Gmail, Google Workspace, Outlook.com și Microsoft 365: conectați-vă pe pagina Google sau Microsoft. Parola o introduceți acolo, niciodată în Inbox Classic.
ui-start-intro-apps = Conectați-vă prin browser folosind una dintre aplicațiile dvs. de conectare, disponibile în „Mai multe opțiuni de conectare”, sau adăugați un cont de e-mail introducând mai jos numele și adresa dvs.
ui-use-app-password = Folosire parolă de aplicație
ui-the-provider = furnizorul
ui-provider-intro = Conectați-vă la contul „{ $email }” pe site-ul furnizorului ({ $provider }). Inbox Classic nu primește parola dvs. Dacă acest cont permite folosirea parolelor de aplicație pentru e-mail, puteți folosi o astfel de parolă creată în setările de securitate ale contului. Outlook.com și Microsoft 365 permit numai conectarea prin browser.
ui-provider-intro-apps = Conectați-vă la contul „{ $email }” pe site-ul furnizorului ({ $provider }), folosind una dintre aplicațiile dvs. de conectare din „Mai multe opțiuni de conectare”. Dacă acest cont permite folosirea parolelor de aplicație pentru e-mail, puteți folosi o astfel de parolă creată în setările de securitate ale contului. Outlook.com și Microsoft 365 permit numai conectarea prin browser.
ui-finish = Terminare
ui-logon = Conectare
ui-enter-password = Introduceți parola contului „{ $account }”.
ui-signs-in-with = Aplicație de conectare: { $app }. Conectarea se face în browser, iar contul folosește serverele acestei aplicații.
ui-keep-password = Lăsați câmpul de parolă gol pentru a păstra parola actuală.
ui-remove-account = Eliminare cont
ui-remove-account-ask = Eliminați acest cont din Inbox Classic? Mesajele aflate pe server rămân acolo. Datele locale ale contului, inclusiv mesajele care așteaptă trimiterea, și datele de autentificare salvate vor fi eliminate.
ui-col-email = Adresă de e-mail
ui-col-incoming = Server de intrare
ui-type-email = Introduceți adresa de e-mail, nume@example.com.
ui-ai-agent = Agent IA
ui-ai-agent-access = Acces agent IA
ui-ai-agents = Agenți IA
ui-program-path = Program: { $path }
ui-it-may = Acțiuni permise:
ui-accounts-it-may-use = Conturi permise:
ui-send-message-ask = Trimiteți mesajul?
ui-col-name = Nume
ui-never = Niciodată
ui-connect-agent = Conectare agent IA
ui-connect-agent-intro = Adăugați această configurație la lista serverelor MCP ale agentului dvs. (în Claude Desktop: Settings > Developer > Edit Config):
ui-col-program = Program
ui-col-may = Permisiuni
ui-col-last-used = Ultima utilizare
ui-col-when = Când
ui-col-what = Acțiune
ui-sign-in-app = Aplicație de conectare
ui-sign-in-apps = Aplicații de conectare
ui-add-sign-in-app-title = Adăugare aplicație de conectare
ui-preset-app-name = Aplicație de conectare { $provider }
ui-issuer-not-checked = emitentul nu poate fi verificat
ui-checking-issuer = Se verifică { $issuer }...
ui-issuer-unusable = Emitentul nu poate fi folosit: { $reason }
ui-issuer-usable = Emitentul poate fi folosit.
ui-sign-in-app-not-saved = Aplicația de conectare nu a putut fi salvată: { $reason }
ui-check = &Verificare
ui-fill-in-for = Setări pentru:
ui-app-name = Nume:
ui-issuer = Emitent:
ui-client-id = ID client:
ui-client-secret = Secret client:
ui-scopes = Permisiuni (scopes):
ui-imap-server = Server IMAP:
ui-smtp-server = Server SMTP:
ui-redirect-uri = URI de redirecționare:
ui-sign-in-app-intro = O aplicație de conectare este un client OAuth pe care îl înregistrați la furnizor pentru a vă conecta prin browser. Alegeți un furnizor pentru a-i completa setările, apoi adăugați ID-ul client și secretul client, dacă furnizorul v-a dat unul.
ui-remove-secret = Este salvat un secret client. Introduceți altul pentru a-l înlocui sau eliminați secretul salvat
ui-register-it = Înregistrați aplicația la furnizor
ui-built-in-note = Aplicația „{ $name }” este integrată în Inbox Classic. Puteți schimba doar dacă apare printre opțiunile de conectare pentru conturi noi.
ui-client-with-secret = ID client: { $client }, cu un secret client.
ui-client-public = ID client: { $client }, client public (fără secret).
ui-no-accounts = Niciun cont
ui-remove-sign-in-app = Eliminare aplicație de conectare
ui-remove-sign-in-app-ask = Eliminați aplicația de conectare „{ $name }” și secretul client salvat pentru aceasta?
ui-sign-in-app-not-removed = Aplicația de conectare nu a fost eliminată. { $reason }
ui-sign-in-apps-intro = Aplicațiile de conectare vă permit să vă conectați la conturi prin browser. Dacă o aplicație nu este bifată, nu apare printre opțiunile de conectare pentru conturi noi. Conturile care o folosesc deja continuă să funcționeze.
ui-col-issuer = Emitent
ui-col-used-by = Folosită de
ui-options-system-default = Limba sistemului ({ $language })
ui-settings-general = General
ui-settings-reading = Citire
ui-settings-new-mail = Mesaje noi
ui-settings-sending = Trimitere
ui-settings-default-apps = Aplicații implicite
ui-settings-message-list = Lista de mesaje
ui-settings-messages = Mesaje
ui-settings-encryption = Criptare
ui-settings-language = Limbă
ui-settings-label = { $label }:
ui-apply = &Aplicare
ui-settings-sync = Sincronizare
ui-sync-note = Păstrați conturile, cheile, agenda, regulile și setările la fel pe fiecare computer, printr-un folder sau un spațiu de stocare care vă aparține. Totul este criptat cu fraza-parolă de sincronizare înainte să părăsească acest computer.
ui-sync-place = Sincronizat prin:
ui-sync-status = Stare:
ui-sync-set-up = Configurare &sincronizare…
ui-sync-now = Sincronizare a&cum
ui-sync-computers = Co&mputere…
ui-sync-history = &Istoric…
ui-sync-turn-off = &Dezactivare sincronizare…
ui-sync-what = Ce se sincronizează
ui-sync-what-note = Parolele, conectările și cheile private circulă numai criptate. Excludeți ce trebuie să rămână pe acest computer.
ui-sync-accounts = C&onturi
ui-sync-passwords = &Parole
ui-sync-sign-ins = Co&nectări cu Google, Microsoft și aplicații de conectare
ui-sync-sign-in-apps = Ap&licații de conectare
ui-sync-app-secrets = S&ecretele aplicațiilor de conectare
ui-sync-contacts = A&gendă
ui-sync-keys = C&hei
ui-sync-private-keys = Cheile dvs. p&rivate
ui-sync-rules = Reg&uli
ui-sync-trusted = E&xpeditori de încredere
ui-sync-settings = Se&tări
ui-sync-preferences = Aspect și &vizualizare
ui-sync-everything = Totul
ui-sync-some-left-out = Unele elemente sunt excluse
ui-sync-where = Unde se păstrează
ui-sync-folder = Un folder
ui-sync-folder-note = Dropbox, OneDrive, iCloud Drive, Google Drive, Nextcloud sau Syncthing îl copiază pe celelalte computere ale dvs.
ui-sync-bucket = Stocare compatibilă S3
ui-sync-bucket-note = Amazon S3, Cloudflare R2, Backblaze B2, MinIO sau alt spațiu de stocare care funcționează ca S3.
ui-sync-folder-label = &Folder:
ui-sync-folder-none = Niciunul ales încă
ui-sync-choose-folder = Ale&gere…
ui-sync-choose-folder-title = Alegerea folderului de sincronizare
ui-sync-endpoint = &Endpoint:
ui-sync-region = &Regiune:
ui-sync-bucket-name = &Bucket:
ui-sync-prefix = &Folder în bucket:
ui-sync-access-key = ID cheie de &acces:
ui-sync-secret-key = Cheie de acces &secretă:
ui-sync-next = Urmă&torul
ui-sync-join-title = Alăturare la sincronizare
ui-sync-join-note = Această locație conține deja date sincronizate. Introduceți fraza-parolă de sincronizare aleasă pe primul computer.
ui-sync-start-title = Pornirea sincronizării
ui-sync-start-note = Alegeți o frază-parolă de sincronizare. O introduceți o singură dată pe fiecare computer pe care îl adăugați. Păstrați-o într-un loc sigur: fără ea, niciun alt computer nu se poate alătura.
ui-sync-name = Nu&mele acestui computer:
ui-sync-merge-note = Datele acestui computer sunt îmbinate cu datele sincronizate. Conturile și contactele care corespund sunt reunite în câte o singură înregistrare.
ui-sync-turn-on = Activare sin&cronizare
ui-sync-on = Sincronizarea este activată.
ui-sync-turn-off-ask = Dezactivați sincronizarea pe acest computer? Totul rămâne cum este, aici și pe celelalte computere ale dvs. Doar acest computer nu se mai sincronizează.
ui-sync-turn-off-button = Dezactivare
ui-sync-computers-title = Computere
ui-sync-computers-note = Aceste computere se sincronizează prin aceeași locație. Eliminați un computer pe care nu îl mai folosiți pentru a-i opri sincronizarea. Datele sale sincronizate sunt păstrate.
ui-sync-this-computer = Acest computer
ui-sync-seen = Ultima sincronizare: { $when }
ui-sync-remove-ask = Eliminați „{ $name }” din sincronizare? Se oprește data viitoare când încearcă să se sincronizeze. Pentru a-l sincroniza din nou, configurați încă o dată sincronizarea pe el.
ui-sync-loading = Se citește…
ui-sync-history-title = Istoric
ui-sync-history-note = Când modificările de pe computere diferite intră în conflict, sincronizarea păstrează o versiune. Valorile înlocuite apar aici; restaurați o valoare pentru a o folosi din nou. Parolele, datele de conectare și cheile private nu sunt păstrate aici.
ui-sync-history-empty = Nicio modificare nu a fost înlocuită.
ui-sync-history-row = Sursa: { $source }, { $when }
ui-sync-restore = &Restaurare
ui-sync-restore-points = Puncte de restaurare
ui-sync-restore-points-note = Punctele de restaurare salvează configurația înainte ca sincronizarea să elimine elemente de pe acest computer. Deschideți un punct pentru a alege ce restaurați.
ui-sync-restore-points-empty = Niciunul încă.
ui-sync-open-point = &Deschidere…
# Set Up Sync on Windows: back from its second step to the first, as a wizard's Back button
win-sync-back = < Înapo&i
ui-language-label = &Limbă:
ui-restart-note = Reporniți Inbox Classic pentru a schimba limba.
ui-restart-ask = După repornire, limba aplicației Inbox Classic va fi „{ $language }”. Reporniți acum?
ui-notify-new-mail = &Notificare la sosirea e-mailurilor noi
ui-new-folder-title = Folder nou
ui-rename-folder-title = Redenumire folder
ui-delete-folder-question = Ștergeți folderul „{ $folder }”, inclusiv mesajele și subfolderele sale? Acestea vor fi șterse și de pe server.
ui-properties = P&roprietăți
ui-account-sync = Trimitere și pri&mire
ui-account-properties = P&roprietăți...
ui-account-properties-of = &Proprietățile contului...
ui-account-move-up = Mutare în &sus
ui-account-move-down = Mutare în &jos
ui-menu-open = Desc&hidere
ui-menu-flag = Semnali&zare
ui-menu-view-source = &Vizualizare sursă
# Context menu: the same action as cmd-unsubscribe, with its own access key.
ui-menu-unsubscribe = Deza&bonare de la listă...
ui-save-attachments = Salvare atașări
ui-attachment-open = Deschidere
ui-attachment-save-as = Salvare ca...
ui-attachment-save-all = Salvare toate...
ui-attachment-show-in-message = Afișare în mesaj
ui-attachments-strip = Atașări
ui-attachment-note-title = Deschiderea acestui fișier
ui-attachment-program-tip = Opțiunea „Deschidere” este dezactivată pentru acest tip de fișier, deoarece poate rula programe. Îl puteți salva și deschide manual.
ui-clear-flag = &Eliminare semnalizare
ui-button-move = &Mutare
ui-button-copy = C&opiere
ui-find-folder = Căutare folder
ui-new-folder-in = Folderul nou va fi creat în „{ $folder }”.
ui-outbox-send-all = &Trimitere toate acum
ui-yes = Da
ui-no = Nu
ui-try-again = Reîncercare
ui-remove = E&liminare
ui-signature-of = Textul semnăturii: { $account }
ui-sign-in-with = Conectare cu { $provider }
ui-sign-in-in-browser-yours = Conectați-vă la cont în fereastra de browser care s-a deschis, apoi reveniți aici.
ui-browser-sign-in-server = { $server } (conectare prin browser)
ui-dont-allow = Nu permiteți
ui-allow = &Permitere
ui-dont-send = Nu trimiteți
ui-dont-unsubscribe = Nu vă dezabonați
ui-edit-first = &Editați mai întâi
ui-new-address = Adresă nouă
ui-turn-away = &Refuzare
ui-clear-agent-log = Ștergeți istoricul activității agenților?
ui-clear-agent-log-detail = Modificările făcute de agenți nu vor fi anulate.
ui-let-agents-connect = Permiteți agenților IA &să se conecteze la Inbox Classic
ui-change-button = Modificare…
ui-undo-button = Anulare acțiune
# Tools > AI Agents: takes back everything the selected program did in a span the user picks
ui-undo-since-button = Anulare pe interval…
ui-undo-since-span = Anulați modificările făcute de acest program:
ui-take-back = Anulare modificări
ui-rules-title = Reguli pentru mesaje
ui-rules-intro = Regulile organizează mesajele noi din folderul „Mesaje primite” cât timp Inbox Classic rulează. Regulile ale căror criterii sunt îndeplinite se aplică în ordine. După ce o regulă mută un mesaj în alt folder, nu i se mai aplică alte reguli.
ui-rules-none = Nicio regulă încă. Faceți clic pe Nouă pentru a crea una.
ui-rule-new = &Nouă...
ui-rule-edit = &Editare...
ui-rule-delete-button = Șter&gere
ui-rule-title = Regulă pentru mesaje
ui-rule-name = Nume:
ui-rule-account = Cont:
ui-rule-all-accounts = Toate conturile
ui-rule-query = Criterii de căutare:
ui-rule-query-hint = Folosiți termeni de căutare precum from:ana@example.com, subject:factură sau list:news.example.com, la fel ca în caseta de căutare.
ui-rule-count = { $count ->
    [one] 1 mesaj din folderul „Mesaje primite” corespunde acum acestor criterii.
    [few] { $count } mesaje din folderul „Mesaje primite” corespund acum acestor criterii.
   *[other] { $count } de mesaje din folderul „Mesaje primite” corespund acum acestor criterii.
}
ui-rule-show = &Afișare
ui-rule-actions = Acțiuni:
ui-rule-move = &Mutare în:
ui-rule-mark-read = Marcare ca &citit
ui-rule-flag = &Semnalizare
ui-rule-archive = Ar&hivare
ui-rule-junk = Mutare î&n „E-mail nedorit”
ui-rule-delete = Șt&ergere
ui-rule-quiet = &Fără notificare
ui-rule-apply-now = A&plicare și pentru mesajele aflate deja în folderul „Mesaje primite”
ui-rule-delete-ask = Ștergeți regula „{ $name }”?
ui-create-rule = Creare regulă...
ui-rules-applied = { $count ->
    [one] 1 mesaj procesat conform regulilor dvs.
    [few] { $count } mesaje procesate conform regulilor dvs.
   *[other] { $count } de mesaje procesate conform regulilor dvs.
}
ui-col-rule-matches = Criterii
ui-clear-button = Ș&tergere
ui-how-to-connect = Cum se conectează un agent…
ui-agent-programs = Programe ai căror agenți au cerut acces la mesajele dvs.
ui-what-agents-did = Activitatea agenților
ui-restart-now = &Repornire acum
ui-restart-later = Mai &târziu

## The Address Book (Tools > Address Book), Contact and Group Properties, Select Recipients

ui-tb-new-contact = Contact nou
ui-tb-new-group = Grup nou
ui-tb-properties = Proprietăți
ui-tb-write-to = Scrieți
ui-menu-new-contact = &Contact nou...
ui-menu-new-group = &Grup nou...
ui-menu-write-to = &Scrieți
ui-menu-delete = Șt&ergere
ui-book-find-hint = Introduceți un nume sau o adresă de e-mail
ui-book-all-contacts = Toate contactele
ui-col-phone = Telefon
ui-book-empty = Agenda este goală. Faceți clic pe Contact nou pentru a adăuga pe cineva sau importați un fișier vCard sau CSV din meniul Fișier.
ui-book-no-match = Niciun contact nu se potrivește cu „{ $words }”.
ui-book-delete-ask = { $count ->
    [one] Ștergeți acest contact din Agendă?
    [few] Ștergeți aceste { $count } contacte din Agendă?
   *[other] Ștergeți aceste { $count } de contacte din Agendă?
}
ui-group-delete-ask = Ștergeți grupul „{ $name }”? Persoanele din el rămân în Agendă.
ui-book-no-address = { $name } nu are adresă de e-mail.
ui-new-contact-title = Contact nou
ui-contact-title = Proprietăți: { $name }
ui-contact-first = Prenume:
ui-contact-last = Nume de familie:
ui-contact-display = Nume afișat:
ui-contact-nickname = Poreclă:
ui-contact-company = Companie:
ui-contact-addresses = Adrese de e-mail:
ui-contact-address-hint = Introduceți o adresă de e-mail
ui-contact-add = A&dăugare
ui-contact-set-default = Setare ca &implicită
ui-contact-default = { $address } (implicită)
ui-contact-phones = Numere de telefon:
ui-phone-home = Acasă
ui-phone-work = Serviciu
ui-phone-mobile = Mobil
ui-phone-other = Altul
ui-contact-notes = Note:
ui-contact-name-needed = Introduceți un nume sau o adresă de e-mail pentru contact.
ui-contact-address-invalid = „{ $address }” nu este o adresă de e-mail validă.
ui-contact-not-saved = Contactul nu a putut fi salvat: { $reason }
ui-new-group-title = Grup nou
ui-group-title = Proprietăți: { $name }
ui-group-name = Nume grup:
ui-group-members = Membri:
ui-group-select-members = &Selectare membri...
ui-group-new-member = Adăugați o adresă de e-mail care nu este în Agendă:
ui-group-name-needed = Introduceți un nume pentru grup.
ui-group-not-saved = Grupul nu a putut fi salvat: { $reason }
ui-group-members-count = { $count ->
    [one] 1 membru
    [few] { $count } membri
   *[other] { $count } de membri
}
ui-select-recipients = Selectare destinatari
ui-select-members = Selectare membri grup
ui-pick-intro = Introduceți un nume sau selectați-l din listă:
ui-pick-recipients = Destinatarii mesajului:
ui-pick-members = Membrii grupului:
ui-pick-to = Că&tre →
ui-pick-cc = C&c →
ui-pick-bcc = &Bcc →
ui-pick-add = &Adăugare →
ui-pick-tip = Alegeți destinatari din Agendă
ui-filter-address-books = Agende (vCard, CSV)
ui-filter-vcard = Fișiere vCard
ui-book-export-name = Agendă
ui-book-imported = { $added ->
    [one] S-a adăugat 1 contact.
    [few] S-au adăugat { $added } contacte.
   *[other] S-au adăugat { $added } de contacte.
} { $skipped ->
    [one] S-a omis 1 contact care era deja în Agendă.
    [few] S-au omis { $skipped } contacte care erau deja în Agendă.
   *[other] S-au omis { $skipped } de contacte care erau deja în Agendă.
}
ui-book-not-imported = Agenda nu a putut fi importată: { $reason }
ui-book-exported = { $count ->
    [one] 1 contact salvat în { $file }.
    [few] { $count } contacte salvate în { $file }.
   *[other] { $count } de contacte salvate în { $file }.
}
ui-book-not-exported = Agenda nu a putut fi salvată: { $reason }
ui-code-copied = Codul a fost copiat
ui-codes-in-notifications = Afișare &coduri de conectare în notificările pentru mesaje noi
ui-tool-unread-only = Necitite
ui-no-unread = Nu există mesaje necitite aici.
ui-pictures-always-sender = Descărcați întotdeauna imaginile de la { $sender }
ui-pictures-always-domain = Descărcați întotdeauna imaginile de la toți expeditorii din domeniul „{ $domain }”
ui-pictures-unconfirmed = Domeniul expeditorului ({ $domain }) nu a putut fi verificat, așa că imaginile din acest mesaj nu se descarcă automat.
ui-pictures-always-option = &Descărcare imagini în toate mesajele
ui-pictures-always-warning = Expeditorii pot vedea atunci când le citiți mesajele.
ui-protection-details = &Detalii...
ui-protection-details-title = Detalii de securitate
ui-download-heading = Descărcare
ui-download-ahead = &Descărcare mesaje în avans:
ui-download-ahead-recent = Mesajele recente, de până la 1 MB fiecare
ui-download-ahead-all = Toate mesajele
ui-download-ahead-never = Doar la deschidere
ui-download-limit = &Limită de stocare pe cont:
ui-send-delay = Întârziere înainte &de trimitere:
ui-send-delay-note = În timpul numărătorii inverse, puteți anula trimiterea cu Anulare. Această posibilitate încetează la sfârșitul numărătorii, chiar dacă mesajul încă așteaptă să fie trimis.
ui-dark-messages = Afișare mesaje pe fundal întunecat când sistemul este în modul întunecat
ui-preview-show = Afișare a&tașări în mesaje
ui-preview-show-note = Afișează imaginile și primele pagini ale fișierelor PDF după textul mesajului. Inbox Classic generează aceste previzualizări fără a rula cod din fișiere.
ui-preview-pdfs = A&fișare fișiere PDF în mesaje
ui-sending-in = Mesajul { $subject } se trimite în { $count ->
    [one] 1 secundă
    [few] { $count } secunde
   *[other] { $count } de secunde
}
ui-send-undone = Mesajul { $subject } nu a fost trimis. A fost redeschis pentru editare.
ui-send-too-late = Trimiterea mesajului { $subject } nu mai poate fi anulată.
ui-outbox-status-undo = Trimitere cel mai devreme la { $time }
ui-download-note = Mesajele descărcate în avans se deschid imediat. Când se depășește limita de stocare, se elimină cele mai vechi copii locale eligibile. Schițele și mesajele deschise de la pornirea aplicației sunt păstrate, astfel că limita poate fi depășită. Mesajele de pe server pot fi descărcate din nou.
ui-attachment-downloading = Descărcarea acestui mesaj nu s-a terminat. Încercați din nou după ce se termină descărcarea.
ui-trusted-senders-button = &Expeditori de încredere...
ui-trusted-senders-title = Expeditori de încredere
ui-trusted-senders-note = Imaginile din mesajele acestor expeditori se pot descărca automat când furnizorul dvs. de e-mail confirmă domeniul de origine. În părțile criptate trebuie să permiteți descărcarea de fiecare dată.
ui-trusted-everyone-at = Toți expeditorii din domeniul „{ $domain }”
ui-trusted-senders-empty = Nu a fost adăugat încă niciun expeditor de încredere.
ui-search-encrypted = Căutare în mesajele &criptate
ui-search-encrypted-note = Mesajele descărcate pot fi decriptate pe acest computer dacă sunt disponibile cheile necesare. Textul și subiectele originale sunt păstrate într-un index local necriptat, pentru căutare și afișare în listă. Agenții IA nu caută în textul decriptat. Dezactivarea opțiunii elimină aceste date din index.
ui-pgp-keyserver = Căutare chei &pe keys.openpgp.org
ui-pgp-keyserver-note = Când căutați cheia unei adrese, este interogat mai întâi domeniul ei, apoi keys.openpgp.org dacă este necesar. Se transmite adresa căutată. La căutarea după amprentă sau ID, se transmite acel identificator. Conținutul mesajelor nu este trimis.
ui-eml-default = Deschidere &fișiere .eml cu Inbox Classic
ui-eml-default-done = Inbox Classic deschide acum fișierele .eml.
ui-eml-default-failed = Inbox Classic nu a putut fi setat ca aplicație implicită pentru fișierele .eml: { $reason }
ui-folders = Foldere
ui-sorted-by = Sortare după: { $field }
ui-layout-label = A&spect:
ui-columns-note = Fereastra este destul de lată pentru aspectul pe coloane. Puteți schimba aspectul din Vizualizare > Aspect.
ui-row-unread = Necitit
ui-row-flagged = Semnalizat
ui-row-attachments = Are atașări
ui-row-encrypted = Criptat
ui-row-signed = Semnat
ui-row-messages = { $count ->
    [one] { $count } mesaj
    [few] { $count } mesaje
   *[other] { $count } de mesaje
}
ui-list-pictures = Af&ișare imagini ale expeditorilor în lista de mesaje
ui-list-pictures-note = În aspectul pe coloane, afișează sigle sau imagini din Agendă pentru expeditorii al căror domeniu a fost verificat. Dacă nu există o imagine, afișează inițialele. Siglele descărcate sunt păstrate local și reutilizate între mesaje și după repornirea aplicației; uneori este necesară reîmprospătarea lor.
ui-card-picture = Imagine:
ui-card-picture-choose = &Alegere...
ui-picture-not-picture = Fișierul nu este o imagine PNG sau JPEG validă.
ui-picture-too-large = Această imagine este prea mare. Alegeți una de cel mult 10 MB, cu lățimea și înălțimea de cel mult 8000 de pixeli.

## Encryption keys (Tools > Encryption Keys, Account Properties > Security, a contact's key)
ui-keys-title = Chei de criptare
ui-keys-intro = Cu cheile dvs. puteți semna mesajele pe care le trimiteți și citi mesajele criptate pentru dvs. Cheile contactelor permit verificarea semnăturilor acestora și criptarea mesajelor pe care li le trimiteți.
ui-keys-empty = Nu există încă nicio cheie. Faceți clic pe „Cheie nouă” pentru a crea o cheie proprie sau pe „Import” pentru a adăuga o cheie pe care o aveți deja.
ui-keys-col-name = Nume
ui-keys-col-address = Adresă
ui-keys-col-kind = Tip
ui-keys-col-status = Stare
ui-keys-kind-own = Cheia dvs.
ui-keys-kind-contact = Contact
ui-keys-status-verified = { $status }; proprietarul cheii a fost confirmat
ui-keys-new = Cheie &nouă...
ui-keys-import = &Import...
ui-keys-export = &Export...
ui-keys-backup = &Copie de rezervă...
ui-keys-verify = &Verificare...
ui-keys-new-title = Cheie nouă
ui-keys-new-for = Creați o cheie pentru:
ui-keys-new-make = &Creare cheie
ui-keys-no-account = Adăugați mai întâi un cont de e-mail: o cheie se creează pentru adresele unui cont.
ui-keys-memory-only = Parolele sunt păstrate doar în memorie, așa că o cheie privată creată sau importată acum nu poate fi folosită după închiderea Inbox Classic.
ui-keys-backup-offer = Cheia nouă este gata. Salvați acum o copie de rezervă? Dacă acest computer se pierde sau este resetat, cheia poate fi recuperată doar dintr-o copie de rezervă.
ui-keys-backup-now = &Salvare copie de rezervă...
ui-keys-later = Mai &târziu
ui-keys-backup-title = Copie de rezervă a cheii
ui-keys-backup-intro = Copia de rezervă este protejată de o frază-parolă. Păstrați fișierul și fraza-parolă în locuri sigure diferite: aveți nevoie de amândouă pentru a recupera cheia.
ui-keys-passphrase = &Frază-parolă:
ui-keys-passphrase-again = &Reintroduceți-o:
ui-keys-passphrase-differ = Frazele-parolă nu coincid.
ui-keys-passphrase-short = Folosiți o frază-parolă de cel puțin 8 caractere.
ui-keys-backup-saved = Copia de rezervă a fost salvată.
ui-keys-import-title = Import cheie
ui-keys-import-passphrase = Această cheie privată este protejată de o frază-parolă. Introduceți-o pentru a importa cheia:
ui-keys-file-filter = Chei OpenPGP
ui-keys-use-for = Asociați această cheie cu { $addresses }? O veți putea folosi pentru a semna mesaje de la adresele asociate și pentru a decripta aici mesajele criptate cu cheia publică respectivă.
ui-keys-use = &Folosire
ui-keys-not-now = &Nu acum
ui-keys-remove-own = Eliminați cheia dvs. { $fingerprint }? Pentru a decripta din nou mesaje cu această cheie, va trebui să importați copia ei de rezervă. Conținutul deja decriptat nu este șters.
ui-keys-remove-contact = Eliminați cheia „{ $name }”? Nu veți mai putea verifica semnături sau cripta mesaje folosind această cheie până când o adăugați din nou.
ui-key-properties-title = Proprietăți cheie
ui-key-names = Nume:
ui-key-fingerprint = Amprentă:
ui-key-status = Stare:
ui-key-created = Creată:
ui-key-expires = Expiră:
ui-key-never = Niciodată
ui-key-algorithm = Algoritm:
ui-key-source = Sursă:
ui-key-addresses = Adrese:
ui-key-address-verified = { $address } (proprietarul cheii a fost confirmat)
ui-key-address-not-verified = { $address } (proprietarul cheii nu a fost confirmat)
ui-verify-title = Verificare cheie
ui-verify-intro = Luați legătura cu proprietarul cheii „{ $name }”, direct sau la telefon, și cereți-i să vă citească amprenta cheii din propria aplicație. Nu o comparați cu o amprentă primită prin e-mail: cine poate înlocui cheia poate înlocui și amprenta trimisă astfel.
ui-verify-fingerprint = Amprenta cheii pe care o aveți:
ui-verify-marks = { $count ->
    [0] Această cheie nu conține nicio adresă de e-mail. Confirmarea proprietarului nu poate fi salvată.
    [one] Dacă amprentele coincid, confirmați că această cheie aparține persoanei care folosește adresa { $addresses }. Dacă adresa nu îi aparține, alegeți „Diferă”.
   *[other] Dacă amprentele coincid, confirmați că această cheie aparține persoanei care folosește adresele { $addresses }. Dacă una dintre adrese nu îi aparține, alegeți „Diferă”.
}
ui-verify-match = &Se potrivesc
ui-verify-differ = &Diferă
ui-verify-differs = Amprentele nu coincid pentru cheia „{ $name }”. Eliminați cheia salvată și cereți din nou cheia proprietarului.
ui-verify-unmark = Anulare &confirmare proprietar
ui-account-security = Securitate
ui-account-security-intro = Cu o cheie, puteți semna mesajele pe care le trimiteți și primi mesaje criptate.
ui-account-key = &Cheie pentru acest cont:
ui-account-key-none = Niciuna
ui-account-key-new = Cheie &nouă...
ui-account-autocrypt = &Trimitere cheie publică proprie împreună cu mesajele (Autocrypt)
ui-contact-key = Cheie de criptare:
ui-contact-key-none = Nicio cheie
ui-contact-key-use-new = Folosire cheie &nouă
ui-contact-key-keep = &Păstrare cheie actuală
ui-recipient-keys-title = Cheile destinatarilor
ui-recipient-col-recipient = Destinatar
ui-recipient-col-key = Cheie
ui-recipient-find-key = &Găsire cheie
ui-recipient-remove = &Eliminare din mesaj
ui-send-unencrypted = Trimitere &fără criptare
ui-compose-make-key = &Creare cheie...
ui-compose-show-keys = Chei de c&riptare...
ui-compose-encrypt-off = &Dezactivare criptare
ui-compose-keep-encrypted = &Păstrare criptare
ui-setup-export-title = Export setări și conturi
ui-setup-import-title = Import setări și conturi
ui-setup-export-intro = Alegeți ce să transferați pe alt computer. Fișierul nu conține mesaje. Pe celălalt computer se pot descărca din nou doar mesajele păstrate pe server.
ui-setup-use-passphrase = &Protejare fișier cu o frază-parolă
ui-setup-passphrase-note = Cu o frază-parolă, fișierul este criptat și poate include parolele, datele de autentificare și cheile private accesibile din categoriile selectate. Fără ea, va trebui să vă conectați din nou la conturi pe celălalt computer.
ui-setup-export-button = &Export...
ui-setup-file-filter = Setări și conturi Inbox Classic
ui-setup-ask-passphrase = Acest fișier este protejat de o frază-parolă. Introduceți-o pentru a vedea ce conține fișierul:
ui-setup-import-intro = Alegeți ce să importați. Conturile care există deja pe acest computer rămân neschimbate.
ui-setup-from = Salvat de Inbox Classic { $version } pe { $date }.
ui-setup-import-button = &Import
ui-setup-done = Gata
ui-setup-first-run = Import setări și conturi de pe alt computer...
ui-first-run-other = Folosiți deja Inbox Classic pe alt computer? Aduceți aici conturile și setările de pe acesta.
ui-first-run-sync = Alăturare la sincronizare…
ui-first-run-import = Import dintr-un fișier…

ui-field-verifiers = Surse de încredere pentru verificarea expeditorului:
ui-attachment-import-key = Import cheie...
ui-book-key-known = Are o cheie de criptare
ui-book-key-verified = Are o cheie de criptare cu proprietarul confirmat
ui-keys-publish = P&ublicare...
ui-keys-publish-ask = Publicați cheia publică pe keys.openpgp.org pentru ca alții să o poată găsi? Adresele din cheie: { $addresses }. Fiecare adresă trebuie confirmată printr-un link trimis la acea adresă înainte de a fi inclusă în catalog.
ui-keys-publish-now = Publicare
ui-keys-paste = Import din clip&board
ui-keys-paste-none = Clipboardul nu conține nicio cheie OpenPGP.
ui-contact-find-key = &Găsire cheie
ui-reactions-label = Reacții:
ui-reaction-open-email = Deschidere e-mail cu reacția
ui-reaction-show-as-email = Afișare ca e-mail
ui-reaction-when = Reacție: { $when }

cmd-sign-in-again = A&utentificare din nou...
