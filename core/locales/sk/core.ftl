# Slovenčina. Návrh, čaká na kontrolu rodeným hovoriacim (pozri core/locales/GLOSSARY.md).

## Counts and sizes

messages = { $count ->
    [one] 1 správa
    [few] { $count } správy
   *[other] { $count } správ
}
# the separator of decimals in sizes: 2,4 MB
decimal-separator = ,
# review: new
list-separator = { ", " }
size-bytes = { $count ->
    [one] 1 bajt
    [few] { $count } bajty
   *[other] { $count } bajtov
}
size-kb = { $size } KB
size-mb = { $size } MB
size-gb = { $size } GB
send-delay-off = Vypnuté
send-delay-seconds = { $count ->
    [one] 1 sekunda
    [few] { $count } sekundy
   *[other] { $count } sekúnd
}
# the status bar: "12 správ, neprečítané: 3"
list-counts = { $messages }, neprečítané: { $unread }
list-counts-selected = { $messages }, neprečítané: { $unread }, vybraté: { $selected }
# the status bar while searching: "Nájdené: 12, neprečítané: 3"
list-counts-found = Nájdené: { $found }, neprečítané: { $unread }
list-counts-found-selected = Nájdené: { $found }, neprečítané: { $unread }, vybraté: { $selected }
list-counts-none = Nenašli sa žiadne správy

## Special folders, as Outlook names them

folder-inbox = Doručená pošta
folder-sent = Odoslaná pošta
folder-deleted = Odstránená pošta
folder-drafts = Koncepty
folder-junk = Nevyžiadaná pošta
folder-archive = Archív

## The reading pane

reader-no-message = Nie je vybratá žiadna správa.
reader-downloading = Správa sa sťahuje…
reader-downloading-detail = Správa sa tu zobrazí po dokončení sťahovania.
reader-downloading-size = Správa má veľkosť { $size }. Zobrazí sa tu po stiahnutí.
reader-failed = Správu sa nepodarilo stiahnuť
reader-failed-network = Spojenie s poštovým serverom zlyhalo alebo bolo prerušené ({ $reason }).
reader-failed-sign-in = Poštový server neprijal prihlásenie ({ $reason }). V nastaveniach konta skontrolujte heslo alebo sa znova prihláste.
reader-failed-security = Pripojenie k poštovému serveru sa nepodarilo zabezpečiť ({ $reason }).
reader-failed-other = Poštový server odpovedal: { $reason }.
reader-retry-note = Skúsi sa to znova, keď sa konto opäť pripojí.
reader-unreadable = Túto správu nemožno zobraziť: { $error }
message-source-title = Zdroj správy: { $subject }
message-source-untitled = Zdroj správy

## Printing a message, and the header of a message quoted in a reply or forward

header-from = Od
header-date = Dátum
header-to = Komu
header-cc = Kópia
header-sent = Odoslané
header-subject = Predmet
header-security = Zabezpečenie
header-part = Časť { $number }
quote-original = ----- Pôvodná správa -----
fold-show-earlier = Zobraziť staršie správy

## Bounces: the card at the top of a notice that a message was not delivered

bounce-failed = Vaša správa nebola doručená
bounce-delayed = Vaša správa zatiaľ nebola doručená
bounce-delayed-note = Váš poštový server sa ju stále pokúša doručiť. Nemusíte ju posielať znova.
# the link to the message the notice is about, in Sent Items or another folder
bounce-show-message = Zobraziť nedoručenú správu
# the link of a delay's card to the message that is still on its way
bounce-show-delayed = Zobraziť oneskorenú správu
bounce-what-to-do = Čo môžete urobiť:
# what to do about a recipient the message is still on its way to: in the card of a delay, and in the card of a failure
bounce-delayed-do = Zatiaľ nič. Ak ju ani naďalej nebude možné doručiť, dostanete ďalšie oznámenie.
bounce-delayed-row-do = Zatiaľ nič. Váš poštový server sa ju stále pokúša doručiť, a ak sa to nepodarí, dostanete ďalšie oznámenie.
# folds the receiving server's own words
bounce-details = Podrobnosti
# a recipient the notice does not name
bounce-someone = Príjemca
# in Details: the server that refused the message, the status code it gave, and the server that wrote the notice
bounce-server = Server: { $server }
bounce-status = Stav: { $status }
bounce-reported-by = Oznámil: { $server }
bounce-retry-minutes = Prijímajúci server požiadal, aby sa pred ďalším pokusom počkalo { $count ->
    [one] minútu
    [few] { $count } minúty
   *[other] { $count } minút
}.
bounce-retry-hours = Prijímajúci server požiadal, aby sa pred ďalším pokusom počkalo { $count ->
    [one] hodinu
    [few] { $count } hodiny
   *[other] { $count } hodín
}.
# the names of the blocklists, "Spamhaus ZEN, Barracuda"
bounce-blocklist = Zoznam blokovaných: { $lists }
bounce-user-unknown = Adresa neexistuje
bounce-user-unknown-why = Prijímajúci server nemá schránku s touto adresou. Môže byť nesprávne napísaná alebo ju dotyčný už nepoužíva.
bounce-user-unknown-do = Skontrolujte, či je adresa správne napísaná, alebo sa dotyčného opýtajte na adresu, ktorú používa teraz.
bounce-invalid-address = Adresa nie je platná
bounce-invalid-address-why = Adresa nie je zapísaná v tvare, na ktorý možno poslať poštu.
bounce-invalid-address-do = Skontrolujte preklepy, napríklad medzeru, chýbajúce písmeno alebo chýbajúcu doménu za znakom @.
bounce-mailbox-disabled = Schránka je deaktivovaná
bounce-mailbox-disabled-why = Adresa existuje, ale jej schránka bola vypnutá alebo sa už nepoužíva.
bounce-mailbox-disabled-do = Skontaktujte sa s dotyčným inak a opýtajte sa ho na adresu, ktorú používa teraz.
bounce-mailbox-full = Schránka je plná
bounce-mailbox-full-why = V schránke príjemcu nie je miesto na novú poštu.
bounce-mailbox-full-do = Pošlite správu znova o niekoľko dní alebo dajte príjemcovi vedieť iným spôsobom. Pri veľkej prílohe môže pomôcť poslať menší súbor.
bounce-spam-blocked = Odmietnutá ako spam
bounce-spam-blocked-why = Prijímajúci server považoval správu za spam.
bounce-spam-blocked-do = Pošlite ju znova bez toho, čo vyzerá ako spam, napríklad bez množstva odkazov, skrátených odkazov alebo veľkej prílohy. Ak sa to opakuje, obráťte sa na svojho poskytovateľa pošty.
bounce-virus-detected = Odmietnutá pre vírus
bounce-virus-detected-why = Prijímajúci server oznámil vírus alebo iný škodlivý obsah v správe či jej prílohách.
bounce-virus-detected-do = Skontrolujte prílohy antivírusovým programom. Niektoré servery odmietajú všetky programy a archívy, preto takéto súbory radšej zdieľajte ako odkaz.
bounce-ip-blocklisted = Váš poštový server je na zozname blokovaných
bounce-ip-blocklisted-why = Prijímajúci server odmieta poštu zo servera, ktorý odoslal vašu správu, pretože adresa toho servera je na zozname blokovaných.
bounce-ip-blocklisted-do = Problém nie je v správe. Prepošlite toto oznámenie svojmu poskytovateľovi pošty a požiadajte ho, aby server zo zoznamu odstránil.
bounce-domain-blocklisted = Doména je na zozname blokovaných
bounce-domain-blocklisted-why = Prijímajúci server odmieta správu, pretože doména vašej adresy alebo doména v odkazoch správy je na zozname blokovaných.
bounce-domain-blocklisted-do = Ak správa obsahuje odkazy, skúste ju poslať bez nich. Inak prepošlite toto oznámenie tomu, kto spravuje poštu vašej domény.
bounce-policy-blocked = Odmietnutá podľa pravidiel prijímajúceho servera
bounce-policy-blocked-why = Pravidlá prijímajúceho servera túto správu neprepustia, napríklad pre jej veľkosť, prílohy alebo odosielateľa.
bounce-policy-blocked-do = Dôvod často nájdete v odpovedi servera v časti Podrobnosti. Opýtajte sa príjemcu, či môže takúto poštu prijať.
bounce-geo-blocked = Odmietnutá pre miesto pôvodu
bounce-geo-blocked-why = Prijímajúci server neprijíma poštu z krajiny alebo siete, v ktorej je váš poštový server.
bounce-geo-blocked-do = Skontaktujte sa s dotyčným inak alebo sa na to opýtajte svojho poskytovateľa pošty.
bounce-relay-denied = Server ju neodovzdal ďalej
bounce-relay-denied-why = Server odmietol doručiť správu ďalej, často preto, že bola odoslaná bez prihlásenia alebo cez server, ktorý tohto príjemcu neobsluhuje.
bounce-relay-denied-do = V nastaveniach konta skontrolujte server odosielanej pošty a údaje na prihlásenie k nemu.
bounce-auth-failure = Vašu adresu odosielateľa sa nepodarilo overiť
bounce-auth-failure-why = Prijímajúci server nemohol potvrdiť, že správa naozaj prišla z vašej domény (SPF, DKIM alebo DMARC).
bounce-auth-failure-do = Prepošlite toto oznámenie tomu, kto spravuje poštu vašej domény: jej nastavenia treba opraviť. Medzitým môže pomôcť odosielanie cez vlastný server vášho poskytovateľa.
bounce-rate-limited = Príliš veľa pošty naraz
bounce-rate-limited-why = Prijímajúci server zatiaľ od vášho poštového servera prijíma menej správ.
bounce-rate-limited-do = Chvíľu počkajte a pošlite ju znova. Keď píšete mnohým ľuďom, posielajte správu menej ľuďom naraz.
bounce-greylisting = Na chvíľu zadržaná
bounce-greylisting-why = Prijímajúci server žiada neznámych odosielateľov, aby to skúsili o niečo neskôr. Je to bežná ochrana proti spamu.
bounce-greylisting-do = Ak sa server ešte pokúša správu doručiť, počkajte. Ak toto oznámenie hovorí, že doručovanie sa skončilo, skúste správu odoslať neskôr.
bounce-server-error = Prijímajúci server mal problém
bounce-server-error-why = Prijímajúci server nebol dostupný alebo nemohol správu prijať pre vlastný problém.
bounce-server-error-do = Pošlite ju znova neskôr. Ak sa to stále nedarí, skontrolujte preklepy v časti adresy za znakom @.
bounce-unknown = Nedoručená
bounce-unknown-why = Oznámenie jasne neuvádza prečo.
bounce-unknown-do = Viac sa môžete dozvedieť z odpovede servera v časti Podrobnosti. Ak vám nepomôže, prepošlite toto oznámenie svojmu poskytovateľovi pošty.

## Several messages selected

selection-title = { $count ->
    [one] Vybratá 1 správa
    [few] Vybraté { $count } správy
   *[other] Vybratých { $count } správ
}
selection-unread = Neprečítané: { $count }
selection-flagged = S príznakom: { $count }
delete-for-good-one = Táto správa sa natrvalo odstráni. Odstrániť ju?
delete-for-good-all = Tieto správy ({ $count }) sa natrvalo odstránia. Odstrániť ich?
delete-for-good-some = Natrvalo sa odstráni { $count } z { $total } správ. Odstrániť správy?
done-read = { $count ->
    [one] { $messages } označená ako prečítaná
    [few] { $messages } označené ako prečítané
   *[other] { $messages } označených ako prečítané
}
done-unread = { $count ->
    [one] { $messages } označená ako neprečítaná
    [few] { $messages } označené ako neprečítané
   *[other] { $messages } označených ako neprečítané
}
done-flagged = { $count ->
    [one] { $messages } označená príznakom
    [few] { $messages } označené príznakom
   *[other] { $messages } označených príznakom
}
done-unflagged = Príznak zrušený: { $messages }
done-deleted-for-good = { $count ->
    [one] { $messages } natrvalo odstránená
    [few] { $messages } natrvalo odstránené
   *[other] { $messages } natrvalo odstránených
}
done-archived = { $count ->
    [one] { $messages } archivovaná
    [few] { $messages } archivované
   *[other] { $messages } archivovaných
}
done-moved = { $count ->
    [one] { $messages } presunutá do: { $folder }
    [few] { $messages } presunuté do: { $folder }
   *[other] { $messages } presunutých do: { $folder }
}
done-copied = { $count ->
    [one] { $messages } skopírovaná do: { $folder }
    [few] { $messages } skopírované do: { $folder }
   *[other] { $messages } skopírovaných do: { $folder }
}
done-moving = { $count ->
    [one] Presúva sa { $messages } do: { $folder }...
    [few] Presúvajú sa { $messages } do: { $folder }...
   *[other] Presúva sa { $messages } do: { $folder }...
}
done-copying = { $count ->
    [one] Kopíruje sa { $messages } do: { $folder }...
    [few] Kopírujú sa { $messages } do: { $folder }...
   *[other] Kopíruje sa { $messages } do: { $folder }...
}
done-moved-back = { $count ->
    [one] { $messages } vrátená do: { $folder }
    [few] { $messages } vrátené do: { $folder }
   *[other] { $messages } vrátených do: { $folder }
}
# the status bar after Watch Conversation and Ignore Conversation, and after either again on a marked one
done-watched = { $count ->
    [one] Konverzácia sa sleduje
    [few] Sledujú sa { $count } konverzácie
   *[other] Sleduje sa { $count } konverzácií
}
done-unwatched = { $count ->
    [one] Konverzácia sa už nesleduje
    [few] { $count } konverzácie sa už nesledujú
   *[other] { $count } konverzácií sa už nesleduje
}
done-ignored = { $count ->
    [one] Konverzácia sa ignoruje
    [few] Ignorujú sa { $count } konverzácie
   *[other] Ignoruje sa { $count } konverzácií
}
done-unignored = { $count ->
    [one] Konverzácia sa už neignoruje
    [few] { $count } konverzácie sa už neignorujú
   *[other] { $count } konverzácií sa už neignoruje
}
# a destination of done-moved-back and similar messages: "1 správa vrátená do: pôvodné priečinky"
their-folders = príslušné priečinky
undo-move = Vrátiť presunutie
undo-delete = Vrátiť odstránenie
undo-archive = Vrátiť archiváciu
undo-junk = Vrátiť označenie ako nevyžiadanej
undo-not-junk = Vrátiť označenie ako vyžiadanej
undo-send = Zrušiť odoslanie
nothing-to-undo = Nie je čo vrátiť.
messages-gone = Správy tu už nie sú.
# A non-selectable IMAP folder cannot contain messages; this does not mean it is empty.
folder-holds-no-messages = Tento priečinok nemôže obsahovať správy.
not-archived-here = Správy v tomto priečinku nemožno archivovať.
not-emptied-here = Vyprázdniť možno iba priečinky Odstránená pošta a Nevyžiadaná pošta.
next-unread-question = V priečinku „{ $folder }“ už nie sú žiadne neprečítané správy.

    Prejsť do ďalšieho priečinka s neprečítanými správami, „{ $next }“?
no-unread-left = Nezostali žiadne neprečítané správy.
empty-question = { $count ->
    [one] Vyprázdniť priečinok { $folder }?

        Správa v ňom sa natrvalo odstráni. Nebude ju možné obnoviť.
    [few] Vyprázdniť priečinok { $folder }?

        { $messages } v ňom sa natrvalo odstránia. Nebude ich možné obnoviť.
   *[other] Vyprázdniť priečinok { $folder }?

        { $messages } v ňom sa natrvalo odstráni. Nebude ich možné obnoviť.
}
no-junk-folder = Toto konto nemá priečinok Nevyžiadaná pošta, do ktorého by sa správy presunuli.
no-inbox-folder = Toto konto nemá priečinok Doručená pošta, do ktorého by sa správy presunuli.
# the status bar after a flag in a colour: "2 správy, príznak: modrý"
done-flagged-color = { $messages }, príznak: { $color ->
    [red] červený
    [orange] oranžový
    [yellow] žltý
    [green] zelený
    [blue] modrý
    [purple] fialový
   *[gray] sivý
}
# the Flag menu: the colours of Apple Mail's flags
flag-color = { $color ->
    [red] Červená
    [orange] Oranžová
    [yellow] Žltá
    [green] Zelená
    [blue] Modrá
    [purple] Fialová
   *[gray] Sivá
}

## The Move and Copy window

move-window-title-move = { $count ->
    [one] Presunúť správu
    [few] Presunúť { $count } správy
   *[other] Presunúť { $count } správ
}
move-window-title-copy = { $count ->
    [one] Kopírovať správu
    [few] Kopírovať { $count } správy
   *[other] Kopírovať { $count } správ
}
move-window-prompt-move = { $count ->
    [one] Presunúť vybratú správu do:
    [few] Presunúť { $count } vybraté správy do:
   *[other] Presunúť { $count } vybratých správ do:
}
move-window-prompt-copy = { $count ->
    [one] Kopírovať vybratú správu do:
    [few] Kopírovať { $count } vybraté správy do:
   *[other] Kopírovať { $count } vybratých správ do:
}
# the folders used last, over the folder tree
targets-recent = Nedávne
# the folder the messages are in, which can not be chosen
target-current = { $folder } (aktuálny)
# a folder used last, with its account when there are several: "Archív (Práca)"
target-recent = { $folder } ({ $account })

## Moving and copying to another account

transfer-moving = Presúvanie do: { $folder }. Aktuálna správa: { $done }; celkovo: { $messages }...
transfer-copying = Kopírovanie do: { $folder }. Aktuálna správa: { $done }; celkovo: { $messages }...
transfer-another-account = iné konto
transfer-folder-gone = priečinok, do ktorého mala ísť, už neexistuje
transfer-not-on-server = správa už nie je na serveri
transfer-not-moved = { $count ->
    [one] { $messages } nemohla byť presunutá do iného konta: { $reason }
    [few] { $messages } nemohli byť presunuté do iného konta: { $reason }
   *[other] { $messages } nemohlo byť presunutých do iného konta: { $reason }
}
transfer-not-copied = { $count ->
    [one] { $messages } nemohla byť skopírovaná do iného konta: { $reason }
    [few] { $messages } nemohli byť skopírované do iného konta: { $reason }
   *[other] { $messages } nemohlo byť skopírovaných do iného konta: { $reason }
}
transfer-none-moved = Nepodarilo sa presunúť žiadnu správu
transfer-none-copied = Nepodarilo sa skopírovať žiadnu správu

## Messages as files

export-not-in-time = správu sa nepodarilo stiahnuť včas
export-not-saved = Nepodarilo sa uložiť: { $failed }; celkovo: { $messages } ({ $problems })
export-not-attached = správy sa nepodarilo priložiť: { $error }
# the status bar after Save As with several: "3 správy uložené do: Pracovná plocha"
saved-to = { $count ->
    [one] { $messages } uložená do: { $folder }
    [few] { $messages } uložené do: { $folder }
   *[other] { $messages } uložených do: { $folder }
}
download-progress = Sťahuje sa { $done } z { $total }
download-done = Stiahnuté: { $size }
downloading-messages = { $count ->
    [one] Sťahuje sa { $messages }...
    [few] Sťahujú sa { $messages }...
   *[other] Sťahuje sa { $messages }...
}
# the status bar after files are dropped on a folder: "3 správy vložené do: Archív"
import-put = { $count ->
    [one] { $messages } zaradená na import do: { $folder }
    [few] { $messages } zaradené na import do: { $folder }
   *[other] { $messages } zaradených na import do: { $folder }
}
import-not-put = Tieto súbory sa do priečinka nevložili:

    { $problems }

## Problems the windows show

error-store = lokálne úložisko: { $error }
error-not-found = nenašlo sa
error-closed = ukončuje sa
error-other-account = prehliadač sa prihlásil do konta { $email }, nie do tohto konta
# a password or sign-in the mail server refused, with the server's words
failure-authentication = server neprijal prihlásenie ({ $reason })
# the mail server could not be reached or the connection broke, with the reason
failure-network = pripojenie k serveru zlyhalo ({ $reason })
error-in-use = nemožno ju odstrániť, kým sa cez ňu prihlasujú kontá: { $accounts }
error-turned-off = táto prihlasovacia aplikácia je pre nové kontá vypnutá
error-folder-name = názov priečinka musí mať 1 až 200 znakov a nesmie obsahovať riadiace znaky
error-folder-separator = názov priečinka na tomto serveri nesmie obsahovať „{ $separator }“
error-folder-special = priečinok Doručená pošta a špeciálne priečinky nemožno premenovať ani odstrániť
error-no-recipients = správa nemá príjemcov
error-bad-address = „{ $address }“ nie je e-mailová adresa
error-not-own-address = { $address } nie je jednou z adries odosielateľa tohto konta. Pridajte ju do poľa „Ďalšie adresy, z ktorých posielate“ vo vlastnostiach konta.
rule-query-refused = Pravidlá nemôžu filtrovať podľa priečinka ani dátumu ({ $words }).
rule-no-query = Zadajte kritériá vyhľadávania pre prichádzajúce správy.
rule-no-action = Vyberte pre pravidlo aspoň jednu akciu.
error-attachment = { $path } sa nepodarilo prečítať: { $error }
error-no-drafts = konto nemá priečinok Koncepty, do ktorého by sa správa uložila
error-draft-attachment = prílohu konceptu sa nepodarilo zachovať: { $error }
error-password-not-saved = heslo sa nepodarilo uložiť na ďalšie spustenie: { $error }
error-sign-in-not-saved = nové prihlasovacie údaje sa nepodarilo uložiť na ďalšie spustenie: { $error }
error-import-unreadable = { $path } nemožno prečítať: { $error }
error-import-too-large = { $path } je väčší ako 50 MB
error-import-not-mail = { $path } nie je e-mailová správa
error-list-answered = server zoznamu adresátov vrátil stav { $status }
error-not-built = správu sa nepodarilo zostaviť
error-outbox-waits = { $count ->
    [one] správa čaká v priečinku Pošta na odoslanie a program ju znova skúsi odoslať pri ďalšom príkaze Odoslať/prijať
    [few] { $count } správy čakajú v priečinku Pošta na odoslanie a program ich znova skúsi odoslať pri ďalšom príkaze Odoslať/prijať
   *[other] { $count } správ čaká v priečinku Pošta na odoslanie a program ich znova skúsi odoslať pri ďalšom príkaze Odoslať/prijať
}
error-draft-not-removed = predchádzajúci koncept správy sa nepodarilo odstrániť z priečinka Koncepty: { $reason }
error-sent-but = správa bola odoslaná, ale { $problem }
error-sent-still-in-outbox = stále je v priečinku Pošta na odoslanie: { $error }
error-sent-no-copy = do priečinka Odoslaná pošta sa nepodarilo uložiť kópiu: { $reason }
error-no-password = pre toto konto nie je k dispozícii heslo
error-no-sign-in = pre toto konto nie sú k dispozícii prihlasovacie údaje
error-provider-missing = táto zostava sa nemôže prihlásiť do služby { $provider }: nebola odstránená jej prihlasovacia aplikácia?
error-provider-servers = servery tohto konta sa nezhodujú so servermi jeho prihlasovacej aplikácie
error-app-scopes = { $reason }. Poštový server neprijal token prihlasovacej aplikácie. Skontrolujte, či jej rozsahy oprávnení umožňujú prístup k pošte
error-in-folder = { $folder }: { $reason }

## Sign-in apps

sign-in-off-google = Vstavaná prihlasovacia aplikácia Google je vypnutá. Ak ste jej testovací používateľ, môžete ju zapnúť v okne Prihlasovacie aplikácie v nastaveniach kont. Môžete tiež použiť vlastnú prihlasovaciu aplikáciu Google alebo heslo aplikácie, ak ho vaše konto podporuje.
sign-in-off-other = Táto aplikácia je vypnutá. Znova ju môžete zapnúť v okne Prihlasovacie aplikácie v nastaveniach kont.
sign-in-app-no-name = prihlasovacia aplikácia potrebuje názov
sign-in-app-no-client = chýba ID klienta
sign-in-app-no-scopes = prihlasovacia aplikácia potrebuje rozsahy oprávnení umožňujúce prístup k pošte
sign-in-app-bad-host = server { $server } nemá platný názov hostiteľa alebo port
sign-in-app-plain = server { $server } musí používať SSL/TLS alebo STARTTLS
sign-in-app-not-checked = nastavenia vydavateľa ešte neboli skontrolované
sign-in-app-issuer-changed = vydavateľ sa zmenil: zadajte tajný kód klienta znova alebo ho odstráňte
sign-in-register-google = V konzole Google Cloud Console vytvorte klienta OAuth typu Desktop app s oprávnením https://mail.google.com/ na obrazovke súhlasu. Kým je aplikácia v testovaní, prihlásiť sa môžu iba jej testovací používatelia.
sign-in-register-microsoft = V Microsoft Entra zaregistrujte aplikáciu s platformou Mobile and desktop applications, URI presmerovania http://localhost, povolenými tokmi verejného klienta a delegovanými povoleniami IMAP.AccessAsUser.All, SMTP.Send a offline_access. Ak je len pre vašu organizáciu, použite ako vydavateľa https://login.microsoftonline.com/<ID nájomníka>/v2.0.
sign-in-register-other = Zaregistrujte natívneho (verejného) klienta s URI presmerovania uvedeným nižšie. Poskytovateľ musí pre toto URI povoliť ľubovoľný port (RFC 8252). Pridajte rozsah oprávnení, ktorým poskytovateľ umožňuje prístup k pošte.

## Calendar invitations

repeats = Opakuje sa
repeats-every = { $unit ->
    [day] { $interval ->
        [one] Každý deň
        [few] Každé { $interval } dni
       *[other] Každých { $interval } dní
    }
    [week] { $interval ->
        [one] Každý týždeň
        [few] Každé { $interval } týždne
       *[other] Každých { $interval } týždňov
    }
    [month] { $interval ->
        [one] Každý mesiac
        [few] Každé { $interval } mesiace
       *[other] Každých { $interval } mesiacov
    }
   *[year] { $interval ->
        [one] Každý rok
        [few] Každé { $interval } roky
       *[other] Každých { $interval } rokov
    }
}
# "Každý týždeň (pondelok, streda)"
repeats-on = { $repeats } ({ $days })
# "Každý týždeň, 10-krát"
repeats-times = { $repeats }; počet opakovaní: { $count }
day-monday = pondelok
day-tuesday = utorok
day-wednesday = streda
day-thursday = štvrtok
day-friday = piatok
day-saturday = sobota
day-sunday = nedeľa

## AI agents

agent-level-read = Čítať poštu: priečinky, zoznamy správ, konverzácie, výsledky vyhľadávania, správy a ich prílohy, pravidlá správ a kontakty, ktorým píšete
agent-level-organize = Spravovať poštu: meniť stav prečítania, príznaky a ich farby, označovať nevyžiadanú poštu, presúvať a archivovať správy, vytvárať a premenúvať priečinky, sledovať a ignorovať konverzácie, odstraňovať správy do priečinka Odstránená pošta a s vaším súhlasom odhlasovať odber zoznamov adresátov
agent-level-drafts = Písať koncepty, ktoré odošlete vy
agent-level-send = Odosielať poštu, každú správu až po vašom súhlase
agent-connect-title = { $program } chce pracovať s vašou poštou
agent-connect-detail = AI agent chce pracovať s vašou poštou prostredníctvom aplikácie Inbox Classic. Vyberte povolené činnosti a kontá, ku ktorým bude mať prístup. Neskôr to môžete zmeniť v ponuke Nástroje > AI agenti.

    Správy od iných ľudí môžu obsahovať pokyny, ktorých cieľom je oklamať agenta. Inbox Classic si pred každým odoslaním správy agentom vyžiada váš súhlas.
agent-reply-to = Odpoveď na správu „{ $subject }“
agent-reply-all-on = Odpoveď všetkým na správu „{ $subject }“
agent-forward-of = Preposlanie správy „{ $subject }“
agent-never-written-one = Na adresu { $address } ste ešte nikdy nepísali.
agent-never-written-many = Na { $count } z týchto adries ste ešte nikdy nepísali.
agent-send-title = { $program } chce odoslať túto správu
agent-send-detail = Skontrolujte príjemcov a obsah správy. Po potvrdení zostane správa v priečinku Pošta na odoslanie najmenej { $seconds } sekúnd. Pred odoslaním ju ešte môžete odstrániť.
agent-change-title = Čo smie robiť { $program }
agent-change-allowed = Vyberte, čo smú AI agenti tohto programu robiť s vašou poštou.
agent-change-refused = Tomuto programu ste odmietli prístup. Ak ho povolíte, jeho agenti budú môcť opäť pracovať s vašou poštou.
agent-log-taken-back = { $entry } (vrátené)
agent-files = Súbory: { $files }
agent-undo-refused = Túto akciu nemožno vrátiť späť.
agent-undo-refused-why = Túto akciu nemožno vrátiť späť: { $reason }.
agent-undo-impossible = túto akciu nemožno vrátiť späť
agent-undo-not-in-folder = správa už nie je v tom priečinku
agent-undo-not-arrived = správa zatiaľ nie je v cieľovom priečinku
agent-undo-sent = správa už nie je v priečinku Pošta na odoslanie
agent-original-not-downloaded = pôvodná správa ešte nebola stiahnutá. Najprv ju otvorte
agent-turned-away = Prístup odmietnutý
agent-can-nothing = Nič
agent-can-read = čítať
agent-can-organize = spravovať
agent-can-drafts = písať koncepty
agent-can-send = odosielať s vaším súhlasom
# "čítať, usporadúvať a písať koncepty"
agent-can-list = { $first } a { $last }
agent-accounts = { $count ->
    [0] žiadne kontá
    [one] 1 konto
    [few] { $count } kontá
   *[other] { $count } kont
}
# "čítať a usporadúvať; 1 konto"
agent-access = { $can }; { $accounts }
agent-unreadable = Túto správu nemožno prečítať.
agent-encrypted-original = Táto správa je šifrovaná: agent na ňu nemôže odpovedať ani ju preposlať, pretože nevie šifrovať.
agent-encrypted = Táto správa je šifrovaná a agent nemá prístup k jej obsahu. Otvoriť ju môžete v aplikácii Inbox Classic.
agent-too-many-changes = Príliš veľa zmien za posledných 30 dní: tento agent vyčerpal kapacitu denníka zmien pre jeden program. Ďalšie zmeny bude môcť robiť, keď najstaršie záznamy dosiahnu vek 30 dní.
agent-too-many-reads = Príliš veľa prístupov k údajom za posledných 30 dní: tento agent vyčerpal kapacitu denníka prístupov pre jeden program. Ďalšie údaje bude môcť čítať, keď najstaršie záznamy dosiahnu vek 30 dní.
list-encrypted = Šifrovaná správa
agent-log-composed = Otvorená nová správa na úpravu. Predmet: „{ $subject }“
agent-log-refused = Nepovolili ste odoslanie správy „{ $subject }“
agent-log-sent = Správa „{ $subject }“ zaradená do frontu na odoslanie. Príjemcovia: { $to }
agent-log-draft = Uložený koncept „{ $subject }“
agent-log-draft-replaced = Nahradený koncept „{ $subject }“
agent-log-draft-discarded = Zadané trvalé odstránenie konceptu „{ $subject }“
agent-draft-note = Tento koncept vytvoril AI agent { $program }. Pred odoslaním skontrolujte príjemcov a text.
agent-log-read = Správa „{ $subject }“ označená ako prečítaná
agent-log-unread = Správa „{ $subject }“ označená ako neprečítaná
agent-log-flagged = Správa „{ $subject }“ označená príznakom
agent-log-unflagged = Zo správy „{ $subject }“ bol odstránený príznak
agent-log-deleted = Správa „{ $subject }“ odstránená
agent-log-moved = Správa „{ $subject }“ presunutá do priečinka „{ $folder }“
agent-log-junk = Správa „{ $subject }“ označená ako nevyžiadaná
agent-log-not-junk = Označenie správy „{ $subject }“ ako nevyžiadanej bolo zrušené
agent-log-archived = Správa „{ $subject }“ archivovaná
agent-log-folder = Zadané vytvorenie priečinka „{ $name }“
agent-log-unsubscribed = Schválili ste žiadosť o odhlásenie odberu. Správa: „{ $subject }“
agent-log-unsubscribe-failed = Žiadosť o odhlásenie odberu zlyhala. Správa: „{ $subject }“. Dôvod: { $reason }
agent-log-unsubscribe-refused = Odhlásenie odberu ste nepovolili. Odosielatelia: { $senders }
agent-unsubscribe-title = { $count ->
    [one] { $program } vás chce odhlásiť zo zoznamu adresátov
    [few] { $program } vás chce odhlásiť z { $count } zoznamov adresátov
   *[other] { $program } vás chce odhlásiť z { $count } zoznamov adresátov
}
agent-unsubscribe-detail = { $count ->
    [1] Inbox Classic odošle nižšie uvedenému zoznamu adresátov žiadosť o odhlásenie odberu. Použije na to odhlásenie jedným kliknutím, ktoré tento zoznam ponúka. Žiadny e-mail sa neodošle a prijaté správy sa nezmenia.
   *[other] Inbox Classic odošle každému z nižšie uvedených zoznamov adresátov žiadosť o odhlásenie odberu. Použije na to odhlásenie jedným kliknutím, ktoré daný zoznam ponúka. Žiadny e-mail sa neodošle a prijaté správy sa nezmenia.
}
agent-log-flag-color = Správa „{ $subject }“ označená { $color ->
    [red] červeným príznakom
    [orange] oranžovým príznakom
    [yellow] žltým príznakom
    [green] zeleným príznakom
    [blue] modrým príznakom
    [purple] fialovým príznakom
   *[gray] sivým príznakom
}
agent-log-renamed = Zadané premenovanie priečinka „{ $old }“ na „{ $name }“
agent-log-watched = Zapnuté sledovanie konverzácie „{ $subject }“
agent-log-ignored = Zapnuté ignorovanie konverzácie „{ $subject }“
agent-log-unmarked = Zrušené sledovanie alebo ignorovanie konverzácie „{ $subject }“
# the reason one change can not be taken back (agent-undo-refused-why)
agent-undo-changed = správa bola odvtedy zmenená
# one change of many messages an agent made with a search (apply_to_search), a row of the log; { $query } is the search
agent-log-bulk-read = { $count ->
    [one] 1 správa označená ako prečítaná (vyhľadávanie: { $query })
    [few] { $count } správy označené ako prečítané (vyhľadávanie: { $query })
   *[other] { $count } správ označených ako prečítané (vyhľadávanie: { $query })
}
agent-log-bulk-unread = { $count ->
    [one] 1 správa označená ako neprečítaná (vyhľadávanie: { $query })
    [few] { $count } správy označené ako neprečítané (vyhľadávanie: { $query })
   *[other] { $count } správ označených ako neprečítané (vyhľadávanie: { $query })
}
agent-log-bulk-flagged = { $count ->
    [one] 1 správa označená príznakom (vyhľadávanie: { $query })
    [few] { $count } správy označené príznakom (vyhľadávanie: { $query })
   *[other] { $count } správ označených príznakom (vyhľadávanie: { $query })
}
agent-log-bulk-unflagged = { $count ->
    [one] Z 1 správy bol odstránený príznak (vyhľadávanie: { $query })
    [few] Z { $count } správ bol odstránený príznak (vyhľadávanie: { $query })
   *[other] Z { $count } správ bol odstránený príznak (vyhľadávanie: { $query })
}
agent-log-bulk-color = { $count ->
    [one] 1 správa označená
    [few] { $count } správy označené
   *[other] { $count } správ označených
} { $color ->
    [red] červeným príznakom
    [orange] oranžovým príznakom
    [yellow] žltým príznakom
    [green] zeleným príznakom
    [blue] modrým príznakom
    [purple] fialovým príznakom
   *[gray] sivým príznakom
} (vyhľadávanie: { $query })
agent-log-bulk-moved = { $count ->
    [one] 1 správa presunutá do priečinka „{ $folder }“ (vyhľadávanie: { $query })
    [few] { $count } správy presunuté do priečinka „{ $folder }“ (vyhľadávanie: { $query })
   *[other] { $count } správ presunutých do priečinka „{ $folder }“ (vyhľadávanie: { $query })
}
agent-log-bulk-archived = { $count ->
    [one] 1 správa archivovaná (vyhľadávanie: { $query })
    [few] { $count } správy archivované (vyhľadávanie: { $query })
   *[other] { $count } správ archivovaných (vyhľadávanie: { $query })
}
agent-log-bulk-junk = { $count ->
    [one] 1 správa označená ako nevyžiadaná (vyhľadávanie: { $query })
    [few] { $count } správy označené ako nevyžiadané (vyhľadávanie: { $query })
   *[other] { $count } správ označených ako nevyžiadané (vyhľadávanie: { $query })
}
agent-log-bulk-not-junk = { $count ->
    [one] Pri 1 správe zrušené označenie ako nevyžiadanej (vyhľadávanie: { $query })
    [few] Pri { $count } správach zrušené označenie ako nevyžiadaných (vyhľadávanie: { $query })
   *[other] Pri { $count } správach zrušené označenie ako nevyžiadaných (vyhľadávanie: { $query })
}
agent-log-bulk-deleted = { $count ->
    [one] 1 správa odstránená (vyhľadávanie: { $query })
    [few] { $count } správy odstránené (vyhľadávanie: { $query })
   *[other] { $count } správ odstránených (vyhľadávanie: { $query })
}
# Undo Everything Since in the AI Agents window: how far back it reaches
agent-undo-span = { $span ->
    [quarter] Za posledných 15 minút
    [hour] Za poslednú hodinu
    [hours] Za posledné 4 hodiny
    [day] Za posledných 24 hodín
    [week] Za posledných 7 dní
   *[all] Za posledných 30 dní
}
# the question before it takes back what a program did in the span chosen
agent-undo-since-question = { $count ->
    [0] Program { $program } za tento čas neurobil žiadne zmeny, ktoré by sa dali vrátiť.
    [one] Vrátiť zmenu, ktorú program { $program } urobil za tento čas?
    [few] Vrátiť { $count } zmeny, ktoré program { $program } urobil za tento čas?
   *[other] Vrátiť { $count } zmien, ktoré program { $program } urobil za tento čas?
}
agent-undo-since-detail = Podľa druhu pôvodnej akcie sa obnoví priečinok správy, stav prečítania alebo príznak, prípadne sa odstráni správa, ktorá ešte čaká v priečinku Pošta na odoslanie. Zmena sa preskočí, ak sa stav potrebný na jej vrátenie už nezhoduje s očakávaným stavom. Ostatné neskoršie úpravy nemusia vráteniu zmeny zabrániť.
# what taking back did, then a line for each kind of message it left as it is
agent-undo-done = { $count ->
    [0] Nič sa nevrátilo.
    [one] Vrátená 1 zmena, úplne alebo čiastočne.
    [few] Vrátené { $count } zmeny, úplne alebo čiastočne.
   *[other] Vrátených { $count } zmien, úplne alebo čiastočne.
}
agent-undo-left-gone = { $count ->
    [one] 1 správa už nebola tam, kam ju zmena umiestnila.
    [few] { $count } správy už neboli tam, kam ich zmena umiestnila.
   *[other] { $count } správ už nebolo tam, kam ich zmena umiestnila.
}
agent-undo-left-changed = { $count ->
    [one] 1 správa bola odvtedy zmenená, vami alebo na serveri, a zostala bez zmeny.
    [few] { $count } správy boli odvtedy zmenené, vami alebo na serveri, a zostali bez zmeny.
   *[other] { $count } správ bolo odvtedy zmenených, vami alebo na serveri, a zostalo bez zmeny.
}
agent-undo-left-sent = { $count ->
    [one] 1 správa už opustila priečinok Pošta na odoslanie.
    [few] { $count } správy už opustili priečinok Pošta na odoslanie.
   *[other] { $count } správ už opustilo priečinok Pošta na odoslanie.
}
agent-undo-left-impossible = { $count ->
    [one] 1 zmenu nemožno vrátiť.
    [few] { $count } zmeny nemožno vrátiť.
   *[other] { $count } zmien nemožno vrátiť.
}
# the Send question of an agent's answer to a calendar invitation: what it answers, and when the event is
agent-invitation-reply = { $response ->
    [accept] Táto správa prijíma pozvánku „{ $summary }“ ({ $when }).
    [tentative] Táto správa predbežne prijíma pozvánku „{ $summary }“ ({ $when }).
   *[decline] Táto správa odmieta pozvánku „{ $summary }“ ({ $when }).
} Správa je určená kalendáru organizátora. Vaša odpoveď sa v Inbox Classic zmení až po odoslaní správy; neznamená to, že ju kalendár organizátora už spracoval.
# the subject of an answer to an invitation, as calendar programs write it
invitation-reply-subject = { $response ->
    [accept] Prijaté: { $summary }
    [tentative] Predbežne: { $summary }
   *[decline] Odmietnuté: { $summary }
}
# the text of an answer to an invitation; { $name } is the user's name, or address
invitation-reply-text = { $response ->
    [accept] { $name } prijíma túto pozvánku.
    [tentative] { $name } predbežne prijíma túto pozvánku.
   *[decline] { $name } odmieta túto pozvánku.
}
# what a program read in an hour, a row of the log: "Read 14 messages and searched 3 times" (joined by agent-can-list)
agent-reads-messages = { $count ->
    [one] prečítaná 1 správa
    [few] prečítané { $count } správy
   *[other] prečítaných { $count } správ
}
agent-reads-attachments = { $count ->
    [one] vyžiadaná 1 príloha
    [few] vyžiadané { $count } prílohy
   *[other] vyžiadaných { $count } príloh
}
agent-reads-searches = { $count ->
    [one] 1 vyhľadávanie
    [few] { $count } vyhľadávania
   *[other] { $count } vyhľadávaní
}
agent-reads-lists = { $count ->
    [one] 1 zobrazenie zoznamu správ
    [few] { $count } zobrazenia zoznamov správ
   *[other] { $count } zobrazení zoznamov správ
}
# each read under that row
agent-read-message = Prečítaná správa „{ $subject }“
agent-read-conversation = { $count ->
    [one] Prečítaná konverzácia „{ $subject }“ (1 správa)
    [few] Prečítaná konverzácia „{ $subject }“ ({ $count } správy)
   *[other] Prečítaná konverzácia „{ $subject }“ ({ $count } správ)
}
agent-read-attachment = Vyžiadané údaje prílohy „{ $name }“ zo správy „{ $subject }“
agent-read-search = { $count ->
    [one] Vyhľadávanie „{ $query }“: 1 správa
    [few] Vyhľadávanie „{ $query }“: { $count } správy
   *[other] Vyhľadávanie „{ $query }“: { $count } správ
}
agent-read-people = Vyhľadané kontakty s menom alebo adresou začínajúcou na „{ $query }“
agent-read-list = { $count ->
    [one] Zobrazený 1 riadok zoznamu (rozsah: { $folder })
    [few] Zobrazené { $count } riadky zoznamu (rozsah: { $folder })
   *[other] Zobrazených { $count } riadkov zoznamu (rozsah: { $folder })
}
agent-read-changes = { $count ->
        [one] Zobrazené údaje o 1 novej správe
        [few] Zobrazené údaje o { $count } nových správach
       *[other] Zobrazené údaje o { $count } nových správach
    }
# the programs started from a terminal app, which share one access: in the list of programs and the question when one connects
agent-terminal-programs-mac = Programy spustené z aplikácie { $terminal }
agent-terminal-programs-windows = Programy spustené z terminálu ({ $terminal })
agent-terminal-programs-linux = Programy spustené z terminálu ({ $terminal })
# one of them, as the questions to send or unsubscribe name it: "A program started from Terminal wants to send this message"
agent-terminal-program-mac = Program spustený z aplikácie { $terminal }
agent-terminal-program-windows = Program spustený z terminálu ({ $terminal })
agent-terminal-program-linux = Program spustený z terminálu ({ $terminal })
agent-connect-title-terminal = { $programs } chcú pracovať s vašou poštou
agent-connect-terminal-detail = AI agenti rozpoznaní podľa rovnakej cesty k tomuto terminálu zdieľajú povolený prístup. Ak chcete niektorému z nich prideliť samostatné oprávnenia, pridajte v jeho nastaveniach MCP argument --name a ľubovoľný názov. Tento názov slúži na rozlíšenie oprávnení, nie na overenie totožnosti programu.
agent-connect-claimed = Program sa predstavil ako { $claimed }. Aplikácia Inbox Classic overila, ktorý program ho spustil: { $program }.

## Keys as the keyboards of the language name them, in the help (Windows and Linux)

key-ctrl = Ctrl
key-alt = Alt
key-shift = Shift
key-del = Del
key-enter = Enter

## Signing in and passwords

sign-in-no-refresh = poskytovateľ nevydal obnovovací token
sign-in-no-account = poskytovateľ neuviedol, ktoré konto sa prihlásilo
sign-in-not-finished = prihlásenie sa nedokončilo
secrets-unavailable = { $store } nie je k dispozícii
secrets-unavailable-why = { $store } nie je k dispozícii: { $error }
secrets-windows = Správca poverení
secrets-mac = Kľúčenka
secrets-linux = Systémová kľúčenka (Secret Service)
error-no-such-file = taký súbor neexistuje
cards-file-too-big = Súbor je príliš veľký na import do adresára.
ui-sender-added = Kontakt { $name } bol pridaný do adresára.
ui-sender-known = Kontakt { $name } už je v adresári.
ui-sender-none = Odosielateľ tejto správy nemá e-mailovú adresu, ktorú by bolo možné pridať.
card-name-needed = Kontakt nemá meno ani e-mailovú adresu.
# a file of Import Address Book that could not be read: "kontakty.vcf: taký súbor neexistuje"
cards-file-failed = { $file }: { $reason }

## One-time codes: the card at the top of a message with a sign-in or verification code

# the domain the code is for, which signed the message
otp-heading = Kód z domény { $domain }
otp-copy = Kopírovať
otp-note = Zadajte ho iba na stránke domény { $domain }.
otp-old = Podľa dátumu správy bol tento kód odoslaný viac ako hodinu pred jej otvorením. Jeho platnosť už pravdepodobne skončila.

# how many are invited, in the card of an event
event-attendees =
    { $count ->
        [one] { $count } účastník
        [few] { $count } účastníci
       *[other] { $count } účastníkov
    }

# the first line of a new message's notification when it has a code, for a domain that signed it
otp-notification = { $code } je váš kód pre { $domain }

## OpenPGP keys (keys.rs)
pgp-key-valid = Platný
pgp-key-expires = Platnosť do: { $date }
pgp-key-expired = Platnosť skončila: { $date }
pgp-key-revoked = Odvolaný
pgp-key-revoked-why = Odvolaný: { $reason }
pgp-key-not-valid = Neplatný
pgp-key-locked = Kľúč sa nedá použiť, pretože nie je dostupný ochranný kľúč z úložiska { $store }. Skontrolujte, či je úložisko odomknuté a prístupné. Ak ochranný kľúč chýba, znova importujte zálohu súkromného kľúča.
pgp-source-own = Vytvorený v aplikácii Inbox Classic
pgp-source-file = Importovaný zo súboru
pgp-source-paste = Vložený
pgp-source-attachment = Zo správy
pgp-source-vcard = Z vizitky kontaktu
pgp-source-wkd = Od poskytovateľa pošty odosielateľa
pgp-source-keyserver = Z keys.openpgp.org
pgp-source-autocrypt = Z hlavičky Autocrypt správy
pgp-error-no-store = Súkromné kľúče chráni úložisko { $store }, ktoré nemožno použiť: { $error }
pgp-error-wrong-passphrase = Prístupová fráza nie je správna.
pgp-error-not-a-key = Toto nie je kľúč OpenPGP.
pgp-error-too-large = Kľúč je príliš veľký.
pgp-error-unusable = Kľúč sa nedá použiť na túto operáciu. Môže chýbať vhodný podpisový alebo šifrovací kľúč alebo použitá kryptografia nie je podporovaná.
pgp-imported-private = { $count ->
    [one] Váš súkromný kľúč bol importovaný.
    [few] Boli importované { $count } súkromné kľúče.
   *[other] Bolo importovaných { $count } súkromných kľúčov.
}
pgp-imported-public = { $count ->
    [one] Bol importovaný jeden kľúč.
    [few] Boli importované { $count } kľúče.
   *[other] Bolo importovaných { $count } kľúčov.
}
pgp-imported-pending = Pre tieto adresy sa už používa iný kľúč: { $addresses }. Nové kľúče čakajú pri kontaktoch, kým ich nevyberiete.
pgp-error-needs-passphrase = Súkromný kľúč je chránený prístupovou frázou. Zadajte ju, aby sa kľúč importoval.
pgp-error-mismatch = Súkromný kľúč nepatrí k svojmu verejnému kľúču. Mohol byť zmenený.
pgp-file-name-public = Verejný kľúč { $who }.asc
pgp-file-name-private = Záloha súkromného kľúča { $who }.asc
pgp-pending = Našiel sa iný kľúč pre adresu { $address }. Dátum nájdenia: { $date }.

## Reading signed and encrypted mail (protect.rs)
pgp-part-verified = Digitálny podpis: { $signer }; vlastník kľúča je overený
pgp-part-signed = Digitálny podpis: { $signer } (vlastník kľúča nie je overený)
pgp-part-other = Digitálny podpis: { $signer } (iná osoba než odosielateľ)
pgp-part-unknown-key = Digitálne podpísané, ale kľúč nie je známy
pgp-part-not-signed = Bez digitálneho podpisu
pgp-part-not-checked = Digitálny podpis nebol skontrolovaný
pgp-part-encrypted = Šifrované. { $signature }
pgp-part-no-key = Šifrované pre kľúč, ktorý nemáte
pgp-part-changed = Nepodarilo sa potvrdiť celistvosť šifrovanej časti, preto sa nezobrazuje
pgp-part-unprotected = Šifrované bez ochrany proti zmenám, nezobrazuje sa
pgp-part-broken = Šifrovanú časť nemožno prečítať
pgp-why-mismatch = Digitálny podpis nezodpovedá tomuto textu
pgp-why-weak-hash = Digitálny podpis používa hashovaciu funkciu { $hash }, ktorá už nie je bezpečná
pgp-why-key-expired = Digitálne podpísané po skončení platnosti kľúča. Platnosť skončila: { $date }
pgp-why-key-revoked = Podpísané kľúčom, ktorý bol odvolaný
pgp-why-not-signing-key = Podpísané kľúčom, ktorý nesmie podpisovať
pgp-why-from-future = Podpis má dátum v budúcnosti
pgp-why-signature-expired = Platnosť podpisu skončila
pgp-why-key-not-valid = Podpísané kľúčom, ktorý nie je platný
pgp-why-not-for-you = Podpísané pre iných príjemcov a preposlané vám
pgp-why-not-key-in-use = Podpísané iným kľúčom, než aký sa používa pre { $address }
pgp-part-pictures-loaded = { $label }. Obrázky boli načítané z internetu
pgp-error-no-own-key = Pre adresu { $address } nemáte použiteľný kľúč na digitálne podpisovanie alebo šifrovanie. Vytvorte ho v okne Šifrovacie kľúče alebo vypnite možnosti Podpísať a Šifrovať.
pgp-error-missing-keys = { $count ->
    [one] Pre adresu { $addresses } nie je k dispozícii použiteľný kľúč na šifrovanie.
   *[other] Pre týchto príjemcov nie je k dispozícii použiteľný kľúč na šifrovanie: { $addresses }.
}
pgp-error-encrypted-quote = Táto správa obsahuje text, obrázky alebo prílohy zo šifrovanej správy, preto ju možno odoslať iba šifrovanú. Zapnite Šifrovať alebo odstráňte všetok prevzatý šifrovaný obsah.
pgp-error-protect = Správu sa nepodarilo digitálne podpísať alebo zašifrovať: { $reason }
pgp-found-keys = Našli sa kľúče pre adresy: { $addresses }.
pgp-found-none = Pre tieto adresy sa nenašiel žiadny kľúč: { $addresses }. Požiadajte príjemcov, aby vám poslali svoje verejné kľúče.
pgp-found-no-key = Nenašiel sa žiadny kľúč.
pgp-find-unavailable = Kľúče teraz nemožno vyhľadať: { $error }
pgp-publish-pending = Služba keys.openpgp.org poslala potvrdzovací odkaz na tieto adresy: { $addresses }. Potvrďte každú adresu, aby sa podľa nej dal váš kľúč vyhľadať.
pgp-publish-done = Váš kľúč je zverejnený na keys.openpgp.org pre adresy: { $addresses }.
pgp-publish-failed = Kľúč sa nepodarilo zverejniť: { $error }
pgp-keyserver-off = Vyhľadávanie kľúčov na keys.openpgp.org je vypnuté. Príslušné nastavenia: { $settings }.
# the compose window with Sign and Encrypt: the line under the fields, each recipient's key, the questions
pgp-compose-encrypted = { $count ->
    [one] Správa bude pri odoslaní zašifrovaná a digitálne podpísaná. Jej obsah si budete môcť prečítať iba vy a { $addresses }.
   *[other] Správa bude pri odoslaní zašifrovaná a digitálne podpísaná. Obsah bude dostupný iba vám a príjemcom ({ $count }).
}
pgp-compose-encrypt-ready = Správa bude pri odoslaní zašifrovaná a digitálne podpísaná. Pridajte príjemcov, ktorých kľúče máte.
pgp-compose-missing = { $count ->
    [one] Príjemca bez použiteľného kľúča: { $addresses }. Správu zatiaľ nemožno zašifrovať.
   *[other] Príjemcovia bez použiteľných kľúčov ({ $count }): { $addresses }. Správu zatiaľ nemožno zašifrovať.
}
pgp-compose-looking = Hľadajú sa kľúče príjemcov: { $addresses }...
pgp-compose-signed = Správa bude pri odoslaní digitálne podpísaná. Príjemcovia si budú môcť overiť, či sa jej obsah po podpísaní nezmenil.
pgp-compose-reply-clear = Správa sa odošle bez šifrovania, hoci pôvodná správa bola zašifrovaná.
pgp-compose-encrypted-files = Správa obsahuje prílohy zo zašifrovanej správy, preto ju možno odoslať iba zašifrovanú. Zapnite možnosť „Šifrovať“ alebo tieto prílohy odstráňte.
pgp-compose-sign-tip = Digitálne podpísať správu vlastným kľúčom, aby si príjemcovia mohli overiť, či sa jej obsah po podpísaní nezmenil
pgp-compose-sign-tip-encrypted = Správa odoslaná v zašifrovanej podobe je vždy aj digitálne podpísaná
pgp-compose-encrypt-tip = Zašifrovať obsah správy, aby bol dostupný iba vám a jej príjemcom
pgp-compose-make-key = Pre adresu { $address } zatiaľ nemáte vlastný kľúč. Vytvoriť ho teraz? Umožní vám digitálne podpisovať a šifrovať správy.
pgp-compose-key-unusable =
    Váš kľúč pre adresu { $address } nemožno použiť.

    Dôvod: { $state }

    Skontrolujte prístup k systémovému úložisku prihlasovacích údajov. Ak ochranný kľúč chýba alebo je vlastný kľúč neplatný, otvorte okno „Šifrovacie kľúče“ a importujte jeho zálohu alebo vytvorte nový kľúč.
pgp-compose-encrypt-off-quote = Správa obsahuje text, obrázky alebo prílohy zo zašifrovanej správy. Bez šifrovania ju možno odoslať až po odstránení tohto obsahu. Napriek tomu vypnúť šifrovanie?
pgp-compose-encrypt-off-reply = Odpovedáte na zašifrovanú správu alebo ju preposielate. Bez šifrovania môžu obsah vašej správy čítať aj servery, cez ktoré prechádza. Vypnúť šifrovanie?
pgp-recipient-verified = Vlastník kľúča je overený
pgp-recipient-found = Vlastník kľúča nie je overený
pgp-recipient-own = Váš kľúč
pgp-recipient-looking = Hľadá sa kľúč...
pgp-recipient-missing = Žiadny kľúč
pgp-recipient-not-found = Kľúč sa nenašiel. Posledné vyhľadávanie: { $date }
pgp-recipient-unusable = Kľúč nemožno použiť: { $state }
pgp-recipients-intro = Správa sa šifruje kľúčom každého príjemcu aj vaším kľúčom.
pgp-recipients-intro-missing = { $count ->
    [one] Jeden príjemca nemá použiteľný kľúč na šifrovanie. Nájdite jeho kľúč, odstráňte príjemcu zo správy alebo správu odošlite bez šifrovania, ak neobsahuje text, obrázky ani prílohy zo šifrovaných správ.
    [few] { $count } príjemcovia nemajú použiteľné kľúče na šifrovanie. Nájdite ich kľúče, odstráňte týchto príjemcov zo správy alebo správu odošlite bez šifrovania, ak neobsahuje text, obrázky ani prílohy zo šifrovaných správ.
   *[other] { $count } príjemcov nemá použiteľné kľúče na šifrovanie. Nájdite ich kľúče, odstráňte týchto príjemcov zo správy alebo správu odošlite bez šifrovania, ak neobsahuje text, obrázky ani prílohy zo šifrovaných správ.
}
pgp-details-part = Časť { $number }: { $label }
attachment-from-part = Z časti { $number }: { $label }
pgp-details-signed = Digitálny podpis vytvorený: { $when }; kľúč: { $key }
pgp-details-unknown-key = Podpísané kľúčom { $key }, ktorý nemáte
pgp-details-opened = Dešifrované vaším kľúčom { $key }
pgp-details-for = Šifrované pre { $keys }
pgp-details-plain = Nepodpísané a nešifrované
pgp-bar-parts = Táto správa má viac častí ({ $count }): { $list }. Každá časť uvádza, ako je chránená.
pgp-bar-count-verified = s overeným vlastníkom kľúča: { $count }
pgp-bar-count-encrypted-signed = { $count ->
    [one] 1 šifrovaná a podpísaná
    [few] { $count } šifrované a podpísané
   *[other] { $count } šifrovaných a podpísaných
}
pgp-bar-count-encrypted = { $count ->
    [one] 1 šifrovaná
    [few] { $count } šifrované
   *[other] { $count } šifrovaných
}
pgp-bar-count-signed = { $count ->
    [one] 1 podpísaná
    [few] { $count } podpísané
   *[other] { $count } podpísaných
}
pgp-bar-count-warning = { $count ->
    [one] 1 vyžaduje pozornosť
    [few] { $count } vyžadujú pozornosť
   *[other] { $count } vyžaduje pozornosť
}
pgp-bar-count-neutral = bez potvrdeného podpisu: { $count }
# the setup file: settings, accounts, contacts and keys carried to another computer
setup-part-settings = Nastavenia
setup-part-preferences = Predvoľby okien
setup-part-accounts = Kontá
setup-part-sign-in-apps = Prihlasovacie aplikácie
setup-part-contacts = Kontakty a skupiny
setup-part-keys = Šifrovacie kľúče
setup-part-rules = Pravidlá správ
setup-part-trusted-senders = Dôveryhodní odosielatelia
setup-holds-settings = { $count ->
    [one] 1 nastavenie
    [few] { $count } nastavenia
   *[other] { $count } nastavení
}
setup-holds-preferences = { $count ->
    [one] 1 predvoľba
    [few] { $count } predvoľby
   *[other] { $count } predvolieb
}
setup-holds-accounts = { $count ->
    [one] 1 konto
    [few] { $count } kontá
   *[other] { $count } kont
}
setup-holds-sign-in-apps = { $count ->
    [one] 1 prihlasovacia aplikácia
    [few] { $count } prihlasovacie aplikácie
   *[other] { $count } prihlasovacích aplikácií
}
setup-holds-built-in = Ktoré vstavané prihlasovacie aplikácie sú zapnuté
setup-holds-contacts = { $count ->
    [one] 1 kontakt
    [few] { $count } kontakty
   *[other] { $count } kontaktov
}
setup-holds-groups = { $count ->
    [one] 1 skupina
    [few] { $count } skupiny
   *[other] { $count } skupín
}
setup-holds-own-keys = { $count ->
    [one] 1 vlastný kľúč
    [few] { $count } vlastné kľúče
   *[other] { $count } vlastných kľúčov
}
setup-holds-contact-keys = { $count ->
    [one] 1 kľúč kontaktu
    [few] { $count } kľúče kontaktov
   *[other] { $count } kľúčov kontaktov
}
setup-holds-rules = { $count ->
    [one] 1 pravidlo
    [few] { $count } pravidlá
   *[other] { $count } pravidiel
}
setup-holds-trusted-senders = { $count ->
    [one] 1 dôveryhodný odosielateľ
    [few] { $count } dôveryhodní odosielatelia
   *[other] { $count } dôveryhodných odosielateľov
}
setup-sign-in-password = Heslo
setup-account-secret-password = Jeho heslo je v súbore.
setup-account-secret-token = Jeho prihlasovacie údaje sú v súbore.
setup-account-asks-password = Po importe si vyžiada heslo.
setup-account-signs-in-again = Po importe sa doň znova prihlásite.
setup-account-here = Tu už je nastavené, preto sa preskočí.
setup-account-no-app = Prihlasuje sa cez aplikáciu „{ $app }“, ktorá tu nie je nastavená. Importujte aj prihlasovacie aplikácie.
setup-invalid-address = „{ $address }“ nie je e-mailová adresa.
setup-invalid-server = Server { $server } nemá platný názov hostiteľa, port alebo nastavenie zabezpečenia.
setup-invalid-user = Nemá meno používateľa.
setup-invalid-sign-in = Nastavenia prihlásenia tohto konta nie sú platné.
setup-error-empty = Súbor je prázdny.
setup-error-too-large = Súbor nastavení prekračuje povolenú veľkosť.
setup-error-not-setup = Tento súbor nie je súborom nastavení Inbox Classic.
setup-error-damaged = Súbor nastavení je poškodený a nemožno ho prečítať.
setup-error-newer = Tieto nastavenia uložila novšia verzia Inbox Classic ({ $version }). Aktualizujte Inbox Classic a potom ich importujte znova.
setup-error-needs-passphrase = Tieto nastavenia sú chránené prístupovou frázou. Zadajte frázu, s ktorou boli uložené.
setup-error-wrong-passphrase = To nie je prístupová fráza, s ktorou boli tieto nastavenia uložené.
setup-error-changed = Nepodarilo sa potvrdiť celistvosť súboru nastavení, preto ho nemožno importovať.
setup-error-read = Súbor nastavení sa nepodarilo prečítať: { $error }
setup-error-write = Nastavenia sa nepodarilo uložiť: { $error }
setup-error-no-parts = Vyberte aspoň jednu časť.
setup-left-out = { $count ->
    [one] 1 položku z časti { $part } nemožno použiť, a preto sa vynecháva.
    [few] { $count } položky z časti { $part } nemožno použiť, a preto sa vynechávajú.
   *[other] { $count } položiek z časti { $part } nemožno použiť, a preto sa vynecháva.
}
setup-imported-settings = Nastavenia boli nahradené.
setup-imported-preferences = Predvoľby okien boli nahradené.
setup-added-accounts = { $count ->
    [one] Pridané 1 konto.
    [few] Pridané { $count } kontá.
   *[other] Pridaných { $count } kont.
}
setup-skipped-here = Konto { $address } tu už je nastavené, preto sa preskočilo.
setup-skipped-no-app = Konto { $address } sa preskočilo: prihlasuje sa cez aplikáciu „{ $app }“, ktorá tu nie je nastavená.
setup-skipped-invalid = Konto { $address } sa preskočilo: { $reason }
setup-asks-password = Konto { $address } si pri pripojení vyžiada heslo.
setup-signs-in-again = Konto { $address } vás pri pripojení požiada o nové prihlásenie.
setup-added-sign-in-apps = { $count ->
    [one] Pridaná 1 prihlasovacia aplikácia.
    [few] Pridané { $count } prihlasovacie aplikácie.
   *[other] Pridaných { $count } prihlasovacích aplikácií.
}
setup-skipped-sign-in-apps = { $count ->
    [one] 1 prihlasovacia aplikácia tu už je nastavená.
    [few] { $count } prihlasovacie aplikácie tu už sú nastavené.
   *[other] { $count } prihlasovacích aplikácií tu už je nastavených.
}
setup-added-contacts = { $count ->
    [one] Do adresára bol pridaný 1 kontakt.
    [few] Do adresára boli pridané { $count } kontakty.
   *[other] Do adresára bolo pridaných { $count } kontaktov.
}
setup-skipped-contacts = { $count ->
    [one] 1 kontakt už je v adresári.
    [few] { $count } kontakty už sú v adresári.
   *[other] { $count } kontaktov už je v adresári.
}
setup-added-groups = { $count ->
    [one] Pridaná alebo doplnená 1 skupina.
    [few] Pridané alebo doplnené { $count } skupiny.
   *[other] Pridaných alebo doplnených { $count } skupín.
}
setup-added-own-keys = { $count ->
    [one] Pridaný 1 vlastný kľúč.
    [few] Pridané { $count } vlastné kľúče.
   *[other] Pridaných { $count } vlastných kľúčov.
}
setup-added-contact-keys = { $count ->
    [one] Pridaný 1 kľúč kontaktu.
    [few] Pridané { $count } kľúče kontaktov.
   *[other] Pridaných { $count } kľúčov kontaktov.
}
setup-added-rules = { $count ->
    [one] Pridané 1 pravidlo správ.
    [few] Pridané { $count } pravidlá správ.
   *[other] Pridaných { $count } pravidiel správ.
}
setup-skipped-rules = { $count ->
    [one] 1 pravidlo správ tu už je.
    [few] { $count } pravidlá správ tu už sú.
   *[other] { $count } pravidiel správ tu už je.
}
setup-skipped-rules-account = { $count ->
    [one] 1 pravidlo správ je pre konto, ktoré tu nie je, preto sa preskočilo.
    [few] { $count } pravidlá správ sú pre kontá, ktoré tu nie sú, preto sa preskočili.
   *[other] { $count } pravidiel správ je pre kontá, ktoré tu nie sú, preto sa preskočilo.
}
setup-rules-waiting = { $count ->
    [one] 1 pravidlo čaká na priradenie cieľového priečinka po synchronizácii konta.
    [few] { $count } pravidlá čakajú na priradenie cieľových priečinkov po synchronizácii kont.
   *[other] { $count } pravidiel čaká na priradenie cieľových priečinkov po synchronizácii kont.
}
setup-added-trusted-senders = { $count ->
    [one] Pridaný 1 dôveryhodný odosielateľ.
    [few] Pridaní { $count } dôveryhodní odosielatelia.
   *[other] Pridaných { $count } dôveryhodných odosielateľov.
}
setup-nothing = Nič sa neimportovalo.
setup-account-servers = { $imap } a { $smtp } ({ $signin })
setup-file-name = Nastavenia a kontá Inbox Classic
setup-skipped-unreachable = Položka „{ $name }“ sa preskočila, pretože prihlasovaciu službu nebolo možné overiť. Skontrolujte potrebnú aplikáciu v okne Prihlasovacie aplikácie a skúste import znova.
attachment-runs-programs = Súbor „{ $name }“ môže spúšťať programy, preto ho Inbox Classic neotvorí. Uložte ho a potom ho otvorte sami, ak dôverujete jeho zdroju.
attachment-decrypted-note = Táto príloha pochádza zo šifrovanej správy. Pri otvorení Inbox Classic uloží nešifrovanú kópiu do dočasného priečinka vášho používateľského konta. Pri spustení sa aplikácia pokúsi odstrániť kópie staršie ako jeden deň.
# a bar over the list when the server did not do what the user asked of messages, so they are as they were again
undone-move = { $count ->
    [one] Server nepresunul správu do priečinka { $folder }, takže { $messages } je opäť v priečinku { $from }: { $reason }
    [few] Server nepresunul správy do priečinka { $folder }, takže { $messages } sú opäť v priečinku { $from }: { $reason }
   *[other] Server nepresunul správy do priečinka { $folder }, takže { $messages } je opäť v priečinku { $from }: { $reason }
}
undone-delete = { $count ->
    [one] Server neodstránil správu, takže { $messages } je opäť v priečinku { $from }: { $reason }
    [few] Server neodstránil správy, takže { $messages } sú opäť v priečinku { $from }: { $reason }
   *[other] Server neodstránil správy, takže { $messages } je opäť v priečinku { $from }: { $reason }
}
undone-archive = { $count ->
    [one] Server nearchivoval správu, takže { $messages } je opäť v priečinku { $from }: { $reason }
    [few] Server nearchivoval správy, takže { $messages } sú opäť v priečinku { $from }: { $reason }
   *[other] Server nearchivoval správy, takže { $messages } je opäť v priečinku { $from }: { $reason }
}
undone-read = { $count ->
    [one] Server neoznačil správu ako prečítanú, takže { $messages } je opäť neprečítaná: { $reason }
    [few] Server neoznačil správy ako prečítané, takže { $messages } sú opäť neprečítané: { $reason }
   *[other] Server neoznačil správy ako prečítané, takže { $messages } je opäť neprečítaných: { $reason }
}
undone-unread = { $count ->
    [one] Server neoznačil správu ako neprečítanú, takže { $messages } je opäť prečítaná: { $reason }
    [few] Server neoznačil správy ako neprečítané, takže { $messages } sú opäť prečítané: { $reason }
   *[other] Server neoznačil správy ako neprečítané, takže { $messages } je opäť prečítaných: { $reason }
}
undone-flags = { $count ->
    [one] Server nezmenil príznaky správy, preto bola zmena vrátená späť ({ $messages }): { $reason }
    [few] Server nezmenil príznaky správ, preto bola zmena vrátená späť ({ $messages }): { $reason }
   *[other] Server nezmenil príznaky správ, preto bola zmena vrátená späť ({ $messages }): { $reason }
}

## Previews of attachments: the pictures and PDF files shown in a message

preview-pdf-option = Zobrazovať súbory PDF v správach
preview-pdf-off = Súbory PDF sa v správach nezobrazujú.
preview-pdf-off-crashed = Inbox Classic sa ukončil počas vytvárania náhľadu súboru v správe. Preto sú náhľady PDF vypnuté; obrázky sa zobrazujú ďalej. Náhľady PDF znova povolíte možnosťou „{ $option }“. Príslušné nastavenia: { $settings }.
preview-pdf-details = { $count ->
    [one] 1 strana, { $size }
    [few] { $count } strany, { $size }
   *[other] { $count } strán, { $size }
}
preview-page-alt = { $name }, strana { $page } z { $count }
preview-more-pages = { $count ->
    [one] Otvorte súbor a uvidíte stranu
    [few] Otvorte súbor a uvidíte všetky { $count } strany
   *[other] Otvorte súbor a uvidíte všetkých { $count } strán
}
preview-more-files = { $count ->
    [one] Ďalší 1 súbor je v zozname vyššie
    [few] Ďalšie { $count } súbory sú v zozname vyššie
   *[other] Ďalších { $count } súborov je v zozname vyššie
}
preview-tile-downloading = Sťahuje sa…
preview-tile-preparing = Pripravuje sa…
preview-tile-format = Obrázky { $format } sa zatiaľ nezobrazujú
preview-tile-password = Súbor je chránený heslom. Otvorte ho a zadajte heslo
preview-tile-too-large = Náhľad prekračuje limit veľkosti alebo spracovania
preview-tile-unreadable = Nedá sa zobraziť
preview-tile-timed-out = Príprava náhľadu trvala príliš dlho
preview-tile-crashed = Náhľad sa nezobrazuje: predchádzajúce vytváranie náhľadu sa prerušilo
preview-tile-off = Nezobrazené do ďalšieho spustenia Inbox Classic
preview-not-printed = Súbor { $name } ({ $details }) sa nevytlačí. Ak ho chcete vytlačiť, otvorte ho.
