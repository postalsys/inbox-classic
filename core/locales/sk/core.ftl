# Slovenčina. Návrh, čaká na kontrolu rodeným hovoriacim (pozri core/locales/GLOSSARY.md).

## Counts and sizes

messages = { $count ->
    [one] 1 správa
    [few] { $count } správy
   *[other] { $count } správ
}
# the separator of decimals in sizes: 2,4 MB
# review: new
decimal-separator = ,
# review: new
size-bytes = { $count ->
    [one] 1 bajt
    [few] { $count } bajty
   *[other] { $count } bajtov
}
# review: new
size-kb = { $size } KB
# review: new
size-mb = { $size } MB
# review: new
size-gb = { $size } GB
# review: new
send-delay-off = Vypnuté
# review: new
send-delay-seconds = { $count ->
    [one] 1 sekunda
    [few] { $count } sekundy
   *[other] { $count } sekúnd
}
# the status bar: "12 správ, neprečítané: 3"
# review: new
list-counts = { $messages }, neprečítané: { $unread }
# review: new
list-counts-selected = { $messages }, neprečítané: { $unread }, vybraté: { $selected }
# the status bar while searching: "Nájdené: 12, neprečítané: 3"
# review: new
list-counts-found = Nájdené: { $found }, neprečítané: { $unread }
# review: new
list-counts-found-selected = Nájdené: { $found }, neprečítané: { $unread }, vybraté: { $selected }
# review: new
list-counts-none = Nenašli sa žiadne správy

## Special folders, as Outlook names them

# review: new
folder-inbox = Doručená pošta
# review: new
folder-sent = Odoslaná pošta
# review: new
folder-deleted = Odstránená pošta
# review: new
folder-drafts = Koncepty
# review: new
folder-junk = Nevyžiadaná pošta
# review: new
folder-archive = Archív

## The reading pane

# review: new
reader-no-message = Nie je vybratá žiadna správa.
# review: new
reader-downloading = Správa sa sťahuje…
# review: new
reader-downloading-detail = Správa sa tu zobrazí po dokončení sťahovania.
# review: new
reader-downloading-size = Správa má veľkosť { $size }. Zobrazí sa tu po stiahnutí.
# review: new
reader-failed = Správu sa nepodarilo stiahnuť
# review: new
reader-failed-network = Poštový server nie je dostupný ({ $reason }).
# review: new
reader-failed-sign-in = Poštový server neprijal prihlásenie ({ $reason }). Skontrolujte heslo alebo sa znova prihláste v ponuke Súbor > Kontá.
# review: new
reader-failed-security = Pripojenie k poštovému serveru sa nepodarilo zabezpečiť ({ $reason }).
# review: new
reader-failed-other = Poštový server odpovedal: { $reason }.
# review: new
reader-retry-note = Skúsi sa to znova, keď sa konto opäť pripojí.
# review: new
reader-unreadable = Túto správu nemožno zobraziť: { $error }
# review: new
message-source-title = Zdroj správy: { $subject }
# review: new
message-source-untitled = Zdroj správy

## Printing a message, and the header of a message quoted in a reply or forward

# review: new
header-from = Od
# review: new
header-date = Dátum
# review: new
header-to = Komu
# review: new
header-cc = Kópia
# review: new
header-sent = Odoslané
# review: new
header-subject = Predmet
# review: new
header-security = Zabezpečenie
# review: new
header-part = Časť { $number }
# review: new
quote-original = ----- Pôvodná správa -----
# review: new
fold-show-earlier = Zobraziť staršie správy

## Bounces: the card at the top of a notice that a message was not delivered

# review: new
bounce-failed = Vaša správa nebola doručená
# review: new
bounce-delayed = Vaša správa zatiaľ nebola doručená
# review: new
bounce-delayed-note = Váš poštový server sa ju stále pokúša doručiť. Nemusíte ju posielať znova.
# the link to the message the notice is about, in Sent Items or another folder
# review: new
bounce-show-message = Zobraziť nedoručenú správu
# the link of a delay's card to the message that is still on its way
# review: new
bounce-show-delayed = Zobraziť oneskorenú správu
# review: new
bounce-what-to-do = Čo môžete urobiť:
# what to do about a recipient the message is still on its way to: in the card of a delay, and in the card of a failure
# review: new
bounce-delayed-do = Zatiaľ nič. Ak ju ani naďalej nebude možné doručiť, dostanete ďalšie oznámenie.
# review: new
bounce-delayed-row-do = Zatiaľ nič. Váš poštový server sa ju stále pokúša doručiť, a ak sa to nepodarí, dostanete ďalšie oznámenie.
# folds the receiving server's own words
# review: new
bounce-details = Podrobnosti
# a recipient the notice does not name
# review: new
bounce-someone = Príjemca
# in Details: the server that refused the message, the status code it gave, and the server that wrote the notice
# review: new
bounce-server = Server: { $server }
# review: new
bounce-status = Stav: { $status }
# review: new
bounce-reported-by = Oznámil: { $server }
# review: new
bounce-retry-minutes = Prijímajúci server požiadal, aby sa pred ďalším pokusom počkalo { $count ->
    [one] minútu
    [few] { $count } minúty
   *[other] { $count } minút
}.
# review: new
bounce-retry-hours = Prijímajúci server požiadal, aby sa pred ďalším pokusom počkalo { $count ->
    [one] hodinu
    [few] { $count } hodiny
   *[other] { $count } hodín
}.
# the names of the blocklists, "Spamhaus ZEN, Barracuda"
# review: new
bounce-blocklist = Zoznam blokovaných: { $lists }
# review: new
bounce-user-unknown = Adresa neexistuje
# review: new
bounce-user-unknown-why = Prijímajúci server nemá schránku s touto adresou. Môže byť nesprávne napísaná alebo ju dotyčný už nepoužíva.
# review: new
bounce-user-unknown-do = Skontrolujte, či je adresa správne napísaná, alebo sa dotyčného opýtajte na adresu, ktorú používa teraz.
# review: new
bounce-invalid-address = Adresa nie je platná
# review: new
bounce-invalid-address-why = Adresa nie je zapísaná v tvare, na ktorý možno poslať poštu.
# review: new
bounce-invalid-address-do = Hľadajte preklepy, napríklad medzeru, chýbajúce písmeno alebo nič za znakom @.
# review: new
bounce-mailbox-disabled = Schránka je zrušená
# review: new
bounce-mailbox-disabled-why = Adresa existuje, ale jej schránka bola vypnutá alebo sa už nepoužíva.
# review: new
bounce-mailbox-disabled-do = Skontaktujte sa s dotyčným inak a opýtajte sa ho na adresu, ktorú používa teraz.
# review: new
bounce-mailbox-full = Schránka je plná
# review: new
bounce-mailbox-full-why = V schránke príjemcu nie je miesto na novú poštu.
# review: new
bounce-mailbox-full-do = Pošlite správu znova o niekoľko dní alebo dajte dotyčnému vedieť inak. Veľké prílohy sa odmietajú ako prvé.
# review: new
bounce-spam-blocked = Odmietnutá ako spam
# review: new
bounce-spam-blocked-why = Prijímajúci server považoval správu za spam.
# review: new
bounce-spam-blocked-do = Pošlite ju znova bez toho, čo vyzerá ako spam, napríklad bez množstva odkazov, skrátených odkazov alebo veľkej prílohy. Ak sa to opakuje, obráťte sa na svojho poskytovateľa pošty.
# review: new
bounce-virus-detected = Odmietnutá pre vírus
# review: new
bounce-virus-detected-why = Prijímajúci server našiel v správe alebo v jej prílohách vírus alebo iný škodlivý obsah.
# review: new
bounce-virus-detected-do = Skontrolujte prílohy antivírusovým programom. Niektoré servery odmietajú všetky programy a archívy, preto takéto súbory radšej zdieľajte ako odkaz.
# review: new
bounce-ip-blocklisted = Váš poštový server je na zozname blokovaných
# review: new
bounce-ip-blocklisted-why = Prijímajúci server odmieta poštu zo servera, ktorý odoslal vašu správu, pretože adresa toho servera je na zozname blokovaných.
# review: new
bounce-ip-blocklisted-do = Problém nie je v správe. Prepošlite toto oznámenie svojmu poskytovateľovi pošty a požiadajte ho, aby server zo zoznamu odstránil.
# review: new
bounce-domain-blocklisted = Doména je na zozname blokovaných
# review: new
bounce-domain-blocklisted-why = Prijímajúci server odmieta správu, pretože doména vašej adresy alebo doména v odkazoch správy je na zozname blokovaných.
# review: new
bounce-domain-blocklisted-do = Ak správa obsahuje odkazy, skúste ju poslať bez nich. Inak prepošlite toto oznámenie tomu, kto spravuje poštu vašej domény.
# review: new
bounce-policy-blocked = Odmietnutá podľa pravidiel prijímajúceho servera
# review: new
bounce-policy-blocked-why = Pravidlá prijímajúceho servera túto správu neprepustia, napríklad pre jej veľkosť, prílohy alebo odosielateľa.
# review: new
bounce-policy-blocked-do = Dôvod často uvádzajú vlastné slová servera v časti Podrobnosti. Opýtajte sa príjemcu, či môže takúto poštu prijať.
# review: new
bounce-geo-blocked = Odmietnutá pre miesto pôvodu
# review: new
bounce-geo-blocked-why = Prijímajúci server neprijíma poštu z krajiny alebo siete, v ktorej je váš poštový server.
# review: new
bounce-geo-blocked-do = Skontaktujte sa s dotyčným inak alebo sa na to opýtajte svojho poskytovateľa pošty.
# review: new
bounce-relay-denied = Server ju neodovzdal ďalej
# review: new
bounce-relay-denied-why = Server odmietol doručiť správu ďalej, často preto, že bola odoslaná bez prihlásenia alebo cez server, ktorý tohto príjemcu neobsluhuje.
# review: new
bounce-relay-denied-do = Skontrolujte server odosielanej pošty konta v ponuke Súbor > Kontá a to, či sa naň prihlasuje.
# review: new
bounce-auth-failure = Vašu adresu odosielateľa sa nepodarilo overiť
# review: new
bounce-auth-failure-why = Prijímajúci server nemohol potvrdiť, že správa naozaj prišla z vašej domény (SPF, DKIM alebo DMARC).
# review: new
bounce-auth-failure-do = Prepošlite toto oznámenie tomu, kto spravuje poštu vašej domény: jej nastavenia treba opraviť. Medzitým môže pomôcť odosielanie cez vlastný server vášho poskytovateľa.
# review: new
bounce-rate-limited = Príliš veľa pošty naraz
# review: new
bounce-rate-limited-why = Prijímajúci server zatiaľ od vášho poštového servera prijíma menej správ.
# review: new
bounce-rate-limited-do = Chvíľu počkajte a pošlite ju znova. Keď píšete mnohým ľuďom, posielajte správu menej ľuďom naraz.
# review: new
bounce-greylisting = Na chvíľu zadržaná
# review: new
bounce-greylisting-why = Prijímajúci server žiada neznámych odosielateľov, aby to skúsili o niečo neskôr. Je to bežná ochrana proti spamu.
# review: new
bounce-greylisting-do = Nič. Poštové servery to skúšajú znova samy a správa sa zvyčajne doručí do hodiny.
# review: new
bounce-server-error = Prijímajúci server mal problém
# review: new
bounce-server-error-why = Prijímajúci server nebol dostupný alebo nemohol správu prijať pre vlastný problém.
# review: new
bounce-server-error-do = Pošlite ju znova neskôr. Ak sa to stále nedarí, skontrolujte preklepy v časti adresy za znakom @.
# review: new
bounce-unknown = Nedoručená
# review: new
bounce-unknown-why = Oznámenie jasne neuvádza prečo.
# review: new
bounce-unknown-do = Viac môžu povedať vlastné slová servera v časti Podrobnosti. Ak nepomôžu, prepošlite toto oznámenie svojmu poskytovateľovi pošty.

## Several messages selected

# review: new
selection-title = { $count ->
    [one] Vybratá 1 správa
    [few] Vybraté { $count } správy
   *[other] Vybratých { $count } správ
}
# review: new
selection-unread = Neprečítané: { $count }
# review: new
selection-flagged = S príznakom: { $count }
# review: new
delete-for-good-one = Táto správa sa natrvalo odstráni. Odstrániť ju?
# review: new
delete-for-good-all = Tieto správy ({ $count }) sa natrvalo odstránia. Odstrániť ich?
# review: new
delete-for-good-some = Natrvalo sa odstráni { $count } z { $total } správ. Odstrániť správy?
# review: new
done-read = { $count ->
    [one] { $messages } označená ako prečítaná
    [few] { $messages } označené ako prečítané
   *[other] { $messages } označených ako prečítané
}
# review: new
done-unread = { $count ->
    [one] { $messages } označená ako neprečítaná
    [few] { $messages } označené ako neprečítané
   *[other] { $messages } označených ako neprečítané
}
# review: new
done-flagged = { $count ->
    [one] { $messages } označená príznakom
    [few] { $messages } označené príznakom
   *[other] { $messages } označených príznakom
}
# review: new
done-unflagged = Príznak zrušený: { $messages }
# review: new
done-deleted-for-good = { $count ->
    [one] { $messages } natrvalo odstránená
    [few] { $messages } natrvalo odstránené
   *[other] { $messages } natrvalo odstránených
}
# review: new
done-archived = { $count ->
    [one] { $messages } archivovaná
    [few] { $messages } archivované
   *[other] { $messages } archivovaných
}
# review: new
done-moved = { $count ->
    [one] { $messages } presunutá do: { $folder }
    [few] { $messages } presunuté do: { $folder }
   *[other] { $messages } presunutých do: { $folder }
}
# review: new
done-copied = { $count ->
    [one] { $messages } skopírovaná do: { $folder }
    [few] { $messages } skopírované do: { $folder }
   *[other] { $messages } skopírovaných do: { $folder }
}
# review: new
done-moving = { $count ->
    [one] Presúva sa { $messages } do: { $folder }...
    [few] Presúvajú sa { $messages } do: { $folder }...
   *[other] Presúva sa { $messages } do: { $folder }...
}
# review: new
done-copying = { $count ->
    [one] Kopíruje sa { $messages } do: { $folder }...
    [few] Kopírujú sa { $messages } do: { $folder }...
   *[other] Kopíruje sa { $messages } do: { $folder }...
}
# review: new
done-moved-back = { $count ->
    [one] { $messages } vrátená do: { $folder }
    [few] { $messages } vrátené do: { $folder }
   *[other] { $messages } vrátených do: { $folder }
}
# the status bar after Watch Conversation and Ignore Conversation, and after either again on a marked one
# review: new
done-watched = { $count ->
    [one] Konverzácia sa sleduje
    [few] Sledujú sa { $count } konverzácie
   *[other] Sleduje sa { $count } konverzácií
}
# review: new
done-unwatched = { $count ->
    [one] Konverzácia sa už nesleduje
    [few] { $count } konverzácie sa už nesledujú
   *[other] { $count } konverzácií sa už nesleduje
}
# review: new
done-ignored = { $count ->
    [one] Konverzácia sa ignoruje
    [few] Ignorujú sa { $count } konverzácie
   *[other] Ignoruje sa { $count } konverzácií
}
# review: new
done-unignored = { $count ->
    [one] Konverzácia sa už neignoruje
    [few] { $count } konverzácie sa už neignorujú
   *[other] { $count } konverzácií sa už neignoruje
}
# a destination of done-moved-back and similar messages: "1 správa vrátená do: pôvodné priečinky"
# review: new
their-folders = pôvodné priečinky
# review: new
undo-move = Vrátiť presunutie
# review: new
undo-delete = Vrátiť odstránenie
# review: new
undo-archive = Vrátiť archiváciu
# review: new
undo-junk = Vrátiť označenie ako nevyžiadanej
# review: new
undo-not-junk = Vrátiť označenie ako vyžiadanej
# review: new
undo-send = Zrušiť odoslanie
# review: new
nothing-to-undo = Nie je čo vrátiť.
# review: new
messages-gone = Správy tu už nie sú.
# A non-selectable IMAP folder cannot contain messages; this does not mean it is empty.
# review: new
folder-holds-no-messages = Tento priečinok nemôže obsahovať správy.
# review: new
not-archived-here = Správy v tomto priečinku nemožno archivovať.
# review: new
not-emptied-here = Vyprázdniť možno iba priečinky Odstránená pošta a Nevyžiadaná pošta.
# review: new
next-unread-question = V priečinku { $folder } už nie sú žiadne neprečítané správy.

    Prejsť do priečinka { $next }, ďalšieho priečinka s neprečítanými správami?
# review: new
no-unread-left = Nezostali žiadne neprečítané správy.
# review: new
empty-question = { $count ->
    [one] Vyprázdniť priečinok { $folder }?

        Správa v ňom sa natrvalo odstráni. Nebude ju možné obnoviť.
    [few] Vyprázdniť priečinok { $folder }?

        { $messages } v ňom sa natrvalo odstránia. Nebude ich možné obnoviť.
   *[other] Vyprázdniť priečinok { $folder }?

        { $messages } v ňom sa natrvalo odstráni. Nebude ich možné obnoviť.
}
# review: new
no-junk-folder = Toto konto nemá priečinok Nevyžiadaná pošta, do ktorého by sa správy presunuli.
# review: new
no-inbox-folder = Toto konto nemá priečinok Doručená pošta, do ktorého by sa správy presunuli.
# the status bar after a flag in a colour: "2 správy, príznak: modrý"
# review: new
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
# review: new
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

# review: new
move-window-title-move = { $count ->
    [one] Presunúť správu
    [few] Presunúť { $count } správy
   *[other] Presunúť { $count } správ
}
# review: new
move-window-title-copy = { $count ->
    [one] Kopírovať správu
    [few] Kopírovať { $count } správy
   *[other] Kopírovať { $count } správ
}
# review: new
move-window-prompt-move = { $count ->
    [one] Presunúť vybratú správu do:
    [few] Presunúť { $count } vybraté správy do:
   *[other] Presunúť { $count } vybratých správ do:
}
# review: new
move-window-prompt-copy = { $count ->
    [one] Kopírovať vybratú správu do:
    [few] Kopírovať { $count } vybraté správy do:
   *[other] Kopírovať { $count } vybratých správ do:
}
# the folders used last, over the folder tree
# review: new
targets-recent = Nedávne
# the folder the messages are in, which can not be chosen
# review: new
target-current = { $folder } (aktuálny)
# a folder used last, with its account when there are several: "Archív (Práca)"
# review: new
target-recent = { $folder } ({ $account })

## Moving and copying to another account

# review: new
transfer-moving = Presúvanie { $done } / { $messages } do: { $folder }...
# review: new
transfer-copying = Kopírovanie { $done } / { $messages } do: { $folder }...
# review: new
transfer-another-account = iné konto
# review: new
transfer-folder-gone = priečinok, do ktorého mala ísť, už neexistuje
# review: new
transfer-not-on-server = správa už nie je na serveri
# review: new
transfer-not-moved = { $count ->
    [one] { $messages } nemohla byť presunutá do iného konta: { $reason }
    [few] { $messages } nemohli byť presunuté do iného konta: { $reason }
   *[other] { $messages } nemohlo byť presunutých do iného konta: { $reason }
}
# review: new
transfer-not-copied = { $count ->
    [one] { $messages } nemohla byť skopírovaná do iného konta: { $reason }
    [few] { $messages } nemohli byť skopírované do iného konta: { $reason }
   *[other] { $messages } nemohlo byť skopírovaných do iného konta: { $reason }
}
# review: new
transfer-none-moved = Nepodarilo sa presunúť žiadnu správu
# review: new
transfer-none-copied = Nepodarilo sa skopírovať žiadnu správu

## Messages as files

# review: new
export-not-in-time = správu sa nepodarilo stiahnuť včas
# review: new
export-not-saved = Neuložené: { $failed }, celkom { $messages } ({ $problems })
# review: new
export-not-attached = správy sa nepodarilo priložiť: { $error }
# the status bar after Save As with several: "3 správy uložené do: Pracovná plocha"
# review: new
saved-to = { $count ->
    [one] { $messages } uložená do: { $folder }
    [few] { $messages } uložené do: { $folder }
   *[other] { $messages } uložených do: { $folder }
}
# review: new
download-progress = Sťahuje sa { $done } z { $total }
# review: new
download-done = Stiahnuté: { $size }
# review: new
downloading-messages = { $count ->
    [one] Sťahuje sa { $messages }...
    [few] Sťahujú sa { $messages }...
   *[other] Sťahuje sa { $messages }...
}
# the status bar after files are dropped on a folder: "3 správy vložené do: Archív"
# review: new
import-put = { $count ->
    [one] { $messages } vložená do: { $folder }
    [few] { $messages } vložené do: { $folder }
   *[other] { $messages } vložených do: { $folder }
}
# review: new
import-not-put = Tieto súbory sa do priečinka nevložili:

    { $problems }

## Problems the windows show

# review: new
error-store = lokálne úložisko: { $error }
# review: new
error-not-found = nenašlo sa
# review: new
error-closed = ukončuje sa
# review: new
error-other-account = prehliadač sa prihlásil do konta { $email }, nie do tohto konta
# a password or sign-in the mail server refused, with the server's words
# review: new
failure-authentication = server neprijal prihlásenie ({ $reason })
# the mail server could not be reached or the connection broke, with the reason
# review: new
failure-network = pripojenie k serveru zlyhalo ({ $reason })
# review: new
error-in-use = nemožno ju odstrániť, kým sa cez ňu prihlasujú kontá: { $accounts }
# review: new
error-turned-off = táto prihlasovacia aplikácia je pre nové kontá vypnutá
# review: new
error-folder-name = názov priečinka musí mať 1 až 200 znakov a nesmie obsahovať riadiace znaky
# review: new
error-folder-separator = názov priečinka na tomto serveri nesmie obsahovať „{ $separator }“
# review: new
error-folder-special = priečinok Doručená pošta a špeciálne priečinky nemožno premenovať ani odstrániť
# review: new
error-no-recipients = správa nemá príjemcov
# review: new
error-bad-address = „{ $address }“ nie je e-mailová adresa
# review: new
error-not-own-address = { $address } nie je jednou z adries odosielateľa tohto konta. Pridajte ju do poľa „Ďalšie adresy, z ktorých posielate“ vo vlastnostiach konta.
# review: new
rule-query-refused = Pravidlá nemôžu filtrovať podľa priečinka ani dátumu ({ $words }).
# review: new
rule-no-query = Zadajte kritériá vyhľadávania pre prichádzajúce správy.
# review: new
rule-no-action = Vyberte pre pravidlo aspoň jednu akciu.
# review: new
error-attachment = { $path } sa nepodarilo prečítať: { $error }
# review: new
error-no-drafts = konto nemá priečinok Koncepty, do ktorého by sa správa uložila
# review: new
error-draft-attachment = prílohu konceptu sa nepodarilo zachovať: { $error }
# review: new
error-password-not-saved = heslo sa nepodarilo uložiť na ďalšie spustenie: { $error }
# review: new
error-sign-in-not-saved = nové prihlasovacie údaje sa nepodarilo uložiť na ďalšie spustenie: { $error }
# review: new
error-import-unreadable = { $path } nemožno prečítať: { $error }
# review: new
error-import-too-large = { $path } je väčší ako 50 MB
# review: new
error-import-not-mail = { $path } nie je e-mailová správa
# review: new
error-list-answered = server zoznamu adresátov vrátil stav { $status }
# review: new
error-not-built = správu sa nepodarilo zostaviť
# review: new
error-outbox-waits = { $count ->
    [one] správa čaká v priečinku Pošta na odoslanie a odošle sa pri ďalšom príkaze Odoslať/prijať
    [few] { $count } správy čakajú v priečinku Pošta na odoslanie a odošlú sa pri ďalšom príkaze Odoslať/prijať
   *[other] { $count } správ čaká v priečinku Pošta na odoslanie a odošle sa pri ďalšom príkaze Odoslať/prijať
}
# review: new
error-draft-not-removed = predchádzajúci koncept správy sa nepodarilo odstrániť z priečinka Koncepty: { $reason }
# review: new
error-sent-but = správa bola odoslaná, ale { $problem }
# review: new
error-sent-still-in-outbox = stále je v priečinku Pošta na odoslanie: { $error }
# review: new
error-sent-no-copy = do priečinka Odoslaná pošta sa nepodarilo uložiť kópiu: { $reason }
# review: new
error-no-password = toto konto nemá heslo
# review: new
error-no-sign-in = toto konto nemá prihlásenie
# review: new
error-provider-missing = táto zostava sa nemôže prihlásiť do služby { $provider }: nebola odstránená jej prihlasovacia aplikácia?
# review: new
error-provider-servers = servery tohto konta sa nezhodujú so servermi jeho prihlasovacej aplikácie
# review: new
error-app-scopes = { $reason }. Poštový server neprijal token prihlasovacej aplikácie: skontrolujte, či oprávnenia (scopes) aplikácie dávajú prístup k pošte
# review: new
error-in-folder = { $folder }: { $reason }

## Sign-in apps

# review: new
sign-in-off-google = Google zatiaľ Inbox Classic neoveril, preto cez neho povoľuje prihlásenie iba testovacím používateľom. Použite vlastnú prihlasovaciu aplikáciu Google alebo heslo aplikácie, prípadne ju zapnite v okne Prihlasovacie aplikácie (Súbor > Kontá), ak ste testovací používateľ.
# review: new
sign-in-off-other = Bola vypnutá v okne Prihlasovacie aplikácie (Súbor > Kontá), kde ju možno znova zapnúť.
# review: new
sign-in-app-no-name = prihlasovacia aplikácia potrebuje názov
# review: new
sign-in-app-no-client = chýba ID klienta
# review: new
sign-in-app-no-scopes = prihlasovacia aplikácia potrebuje oprávnenia, ktoré dávajú prístup k pošte
# review: new
sign-in-app-bad-host = adresa servera { $server } chýba alebo nie je platným názvom hostiteľa
# review: new
sign-in-app-plain = server { $server } musí používať SSL/TLS alebo STARTTLS
# review: new
sign-in-app-not-checked = vydavateľ ešte nebol overený
# review: new
sign-in-app-issuer-changed = vydavateľ sa zmenil: zadajte tajný kód klienta znova alebo ho odstráňte
# review: new
sign-in-register-google = V konzole Google Cloud Console vytvorte klienta OAuth typu Desktop app s oprávnením https://mail.google.com/ na obrazovke súhlasu. Kým je aplikácia v testovaní, prihlásiť sa môžu iba jej testovací používatelia.
# review: new
sign-in-register-microsoft = V Microsoft Entra zaregistrujte aplikáciu s platformou Mobile and desktop applications, URI presmerovania http://localhost, povolenými tokmi verejného klienta a delegovanými povoleniami IMAP.AccessAsUser.All, SMTP.Send a offline_access. Ak je len pre vašu organizáciu, použite ako vydavateľa https://login.microsoftonline.com/<ID nájomníka>/v2.0.
# review: new
sign-in-register-other = Zaregistrujte natívneho (verejného) klienta s URI presmerovania uvedeným nižšie; poskytovateľ musí v ňom povoliť ľubovoľný port (RFC 8252). Pridajte oprávnenie, ktorým poskytovateľ dáva prístup k pošte.

## Calendar invitations

# review: new
repeats = Opakuje sa
# review: new
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
# review: new
repeats-on = { $repeats } ({ $days })
# "Každý týždeň, 10-krát"
# review: new
repeats-times = { $count ->
    [one] { $repeats }, raz
   *[other] { $repeats }, { $count }-krát
}
# review: new
day-monday = pondelok
# review: new
day-tuesday = utorok
# review: new
day-wednesday = streda
# review: new
day-thursday = štvrtok
# review: new
day-friday = piatok
# review: new
day-saturday = sobota
# review: new
day-sunday = nedeľa

## AI agents

# review: changed
agent-level-read = Čítať poštu: zobrazovať priečinky, zoznam správ a obsah správ, vyhľadávať
# review: changed
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
# review: new
agent-too-many-changes = Príliš veľa zmien za posledných 30 dní: tento agent ich urobil toľko, koľko Inbox Classic pre jeden program uchováva v denníku. Ďalšie bude môcť urobiť, keď budú najstaršie staré 30 dní.
# review: new
agent-too-many-reads = Príliš veľa čítania za posledných 30 dní: tento agent prečítal toľko, koľko Inbox Classic pre jeden program uchováva v denníku. Ďalej bude môcť čítať, keď budú najstaršie čítania staré 30 dní.
# review: new
list-encrypted = Šifrovaná správa
agent-log-composed = Otvorená nová správa na úpravu. Predmet: „{ $subject }“
agent-log-refused = Nepovolili ste odoslanie správy „{ $subject }“
agent-log-sent = Správa „{ $subject }“ zaradená do frontu na odoslanie. Príjemcovia: { $to }
agent-log-draft = Uložený koncept „{ $subject }“
agent-log-draft-replaced = Nahradený koncept „{ $subject }“
agent-log-draft-discarded = Natrvalo odstránený koncept „{ $subject }“
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
agent-log-folder = Vytvorený priečinok „{ $name }“
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
# review: new
agent-log-flag-color = Správa „{ $subject }“ označená { $color ->
    [red] červeným príznakom
    [orange] oranžovým príznakom
    [yellow] žltým príznakom
    [green] zeleným príznakom
    [blue] modrým príznakom
    [purple] fialovým príznakom
   *[gray] sivým príznakom
}
# review: new
agent-log-renamed = Priečinok „{ $old }“ premenovaný na „{ $name }“
# review: new
agent-log-watched = Zapnuté sledovanie konverzácie „{ $subject }“
# review: new
agent-log-ignored = Zapnuté ignorovanie konverzácie „{ $subject }“
# review: new
agent-log-unmarked = Zrušené sledovanie alebo ignorovanie konverzácie „{ $subject }“
# the reason one change can not be taken back (agent-undo-refused-why)
# review: new
agent-undo-changed = správa bola odvtedy zmenená
# one change of many messages an agent made with a search (apply_to_search), a row of the log; { $query } is the search
# review: new
agent-log-bulk-read = { $count ->
    [one] 1 správa označená ako prečítaná (vyhľadávanie: { $query })
    [few] { $count } správy označené ako prečítané (vyhľadávanie: { $query })
   *[other] { $count } správ označených ako prečítané (vyhľadávanie: { $query })
}
# review: new
agent-log-bulk-unread = { $count ->
    [one] 1 správa označená ako neprečítaná (vyhľadávanie: { $query })
    [few] { $count } správy označené ako neprečítané (vyhľadávanie: { $query })
   *[other] { $count } správ označených ako neprečítané (vyhľadávanie: { $query })
}
# review: new
agent-log-bulk-flagged = { $count ->
    [one] 1 správa označená príznakom (vyhľadávanie: { $query })
    [few] { $count } správy označené príznakom (vyhľadávanie: { $query })
   *[other] { $count } správ označených príznakom (vyhľadávanie: { $query })
}
# review: new
agent-log-bulk-unflagged = { $count ->
    [one] Z 1 správy bol odstránený príznak (vyhľadávanie: { $query })
    [few] Z { $count } správ bol odstránený príznak (vyhľadávanie: { $query })
   *[other] Z { $count } správ bol odstránený príznak (vyhľadávanie: { $query })
}
# review: new
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
# review: new
agent-log-bulk-moved = { $count ->
    [one] 1 správa presunutá do priečinka „{ $folder }“ (vyhľadávanie: { $query })
    [few] { $count } správy presunuté do priečinka „{ $folder }“ (vyhľadávanie: { $query })
   *[other] { $count } správ presunutých do priečinka „{ $folder }“ (vyhľadávanie: { $query })
}
# review: new
agent-log-bulk-archived = { $count ->
    [one] 1 správa archivovaná (vyhľadávanie: { $query })
    [few] { $count } správy archivované (vyhľadávanie: { $query })
   *[other] { $count } správ archivovaných (vyhľadávanie: { $query })
}
# review: new
agent-log-bulk-junk = { $count ->
    [one] 1 správa označená ako nevyžiadaná (vyhľadávanie: { $query })
    [few] { $count } správy označené ako nevyžiadané (vyhľadávanie: { $query })
   *[other] { $count } správ označených ako nevyžiadané (vyhľadávanie: { $query })
}
# review: new
agent-log-bulk-not-junk = { $count ->
    [one] Pri 1 správe zrušené označenie ako nevyžiadanej (vyhľadávanie: { $query })
    [few] Pri { $count } správach zrušené označenie ako nevyžiadaných (vyhľadávanie: { $query })
   *[other] Pri { $count } správach zrušené označenie ako nevyžiadaných (vyhľadávanie: { $query })
}
# review: new
agent-log-bulk-deleted = { $count ->
    [one] 1 správa odstránená (vyhľadávanie: { $query })
    [few] { $count } správy odstránené (vyhľadávanie: { $query })
   *[other] { $count } správ odstránených (vyhľadávanie: { $query })
}
# Undo Everything Since in the AI Agents window: how far back it reaches
# review: new
agent-undo-span = { $span ->
    [quarter] Za posledných 15 minút
    [hour] Za poslednú hodinu
    [hours] Za posledné 4 hodiny
    [day] Za posledných 24 hodín
    [week] Za posledných 7 dní
   *[all] Za posledných 30 dní
}
# the question before it takes back what a program did in the span chosen
# review: new
agent-undo-since-question = { $count ->
    [0] Program { $program } za tento čas neurobil žiadne zmeny, ktoré by sa dali vrátiť.
    [one] Vrátiť zmenu, ktorú program { $program } urobil za tento čas?
    [few] Vrátiť { $count } zmeny, ktoré program { $program } urobil za tento čas?
   *[other] Vrátiť { $count } zmien, ktoré program { $program } urobil za tento čas?
}
# review: new
agent-undo-since-detail = Správy sa vrátia do priečinkov, z ktorých prišli, stav prečítania a príznaky budú také ako predtým a správy, ktoré ešte čakajú v priečinku Pošta na odoslanie, sa odstránia. Čo ste odvtedy zmenili vy alebo server, zostane bez zmeny.
# what taking back did, then a line for each kind of message it left as it is
# review: new
agent-undo-done = { $count ->
    [0] Nič sa nevrátilo.
    [one] Vrátená 1 zmena.
    [few] Vrátené { $count } zmeny.
   *[other] Vrátených { $count } zmien.
}
# review: new
agent-undo-left-gone = { $count ->
    [one] 1 správa už nebola tam, kam ju zmena umiestnila.
    [few] { $count } správy už neboli tam, kam ich zmena umiestnila.
   *[other] { $count } správ už nebolo tam, kam ich zmena umiestnila.
}
# review: new
agent-undo-left-changed = { $count ->
    [one] 1 správa bola odvtedy zmenená, vami alebo na serveri, a zostala bez zmeny.
    [few] { $count } správy boli odvtedy zmenené, vami alebo na serveri, a zostali bez zmeny.
   *[other] { $count } správ bolo odvtedy zmenených, vami alebo na serveri, a zostalo bez zmeny.
}
# review: new
agent-undo-left-sent = { $count ->
    [one] 1 správa už opustila priečinok Pošta na odoslanie.
    [few] { $count } správy už opustili priečinok Pošta na odoslanie.
   *[other] { $count } správ už opustilo priečinok Pošta na odoslanie.
}
# review: new
agent-undo-left-impossible = { $count ->
    [one] 1 zmenu nemožno vrátiť.
    [few] { $count } zmeny nemožno vrátiť.
   *[other] { $count } zmien nemožno vrátiť.
}
# the Send question of an agent's answer to a calendar invitation: what it answers, and when the event is
# review: new
agent-invitation-reply = { $response ->
    [accept] Táto správa prijíma pozvánku „{ $summary }“ ({ $when }).
    [tentative] Táto správa predbežne prijíma pozvánku „{ $summary }“ ({ $when }).
   *[decline] Táto správa odmieta pozvánku „{ $summary }“ ({ $when }).
} Kalendár organizátora odpoveď zaznamená. Vaša odpoveď na pozvánku sa zmení až po odoslaní správy.
# the subject of an answer to an invitation, as calendar programs write it
# review: new
invitation-reply-subject = { $response ->
    [accept] Prijaté: { $summary }
    [tentative] Predbežne: { $summary }
   *[decline] Odmietnuté: { $summary }
}
# the text of an answer to an invitation; { $name } is the user's name, or address
# review: new
invitation-reply-text = { $response ->
    [accept] { $name } prijíma túto pozvánku.
    [tentative] { $name } predbežne prijíma túto pozvánku.
   *[decline] { $name } odmieta túto pozvánku.
}
# what a program read in an hour, a row of the log: "Read 14 messages and searched 3 times" (joined by agent-can-list)
# review: new
agent-reads-messages = { $count ->
    [one] prečítaná 1 správa
    [few] prečítané { $count } správy
   *[other] prečítaných { $count } správ
}
# review: new
agent-reads-attachments = { $count ->
    [one] otvorená 1 príloha
    [few] otvorené { $count } prílohy
   *[other] otvorených { $count } príloh
}
# review: new
agent-reads-searches = { $count ->
    [one] 1 vyhľadávanie
    [few] { $count } vyhľadávania
   *[other] { $count } vyhľadávaní
}
# review: new
agent-reads-lists = { $count ->
    [one] 1 zobrazenie zoznamu správ
    [few] { $count } zobrazenia zoznamov správ
   *[other] { $count } zobrazení zoznamov správ
}
# each read under that row
# review: new
agent-read-message = Prečítaná správa „{ $subject }“
# review: new
agent-read-conversation = { $count ->
    [one] Prečítaná konverzácia „{ $subject }“ (1 správa)
    [few] Prečítaná konverzácia „{ $subject }“ ({ $count } správy)
   *[other] Prečítaná konverzácia „{ $subject }“ ({ $count } správ)
}
# review: new
agent-read-attachment = Otvorená príloha „{ $name }“ zo správy „{ $subject }“
# review: new
agent-read-search = { $count ->
    [one] Vyhľadávanie „{ $query }“: 1 správa
    [few] Vyhľadávanie „{ $query }“: { $count } správy
   *[other] Vyhľadávanie „{ $query }“: { $count } správ
}
# review: new
agent-read-people = Vyhľadané kontakty začínajúce na „{ $query }“
# review: new
agent-read-list = { $count ->
    [one] Zobrazená 1 správa v priečinku { $folder }
    [few] Zobrazené { $count } správy v priečinku { $folder }
   *[other] Zobrazených { $count } správ v priečinku { $folder }
}
# review: new
agent-read-changes = { $count ->
    [one] Zobrazená 1 nová správa
    [few] Zobrazené { $count } nové správy
   *[other] Zobrazených { $count } nových správ
}
# the programs started from a terminal app, which share one access: in the list of programs and the question when one connects
# review: new
agent-terminal-programs-mac = Programy spustené z aplikácie { $terminal }
# review: new
agent-terminal-programs-windows = Programy spustené z terminálu ({ $terminal })
# review: new
agent-terminal-programs-linux = Programy spustené z terminálu ({ $terminal })
# one of them, as the questions to send or unsubscribe name it: "A program started from Terminal wants to send this message"
# review: new
agent-terminal-program-mac = Program spustený z aplikácie { $terminal }
# review: new
agent-terminal-program-windows = Program spustený z terminálu ({ $terminal })
# review: new
agent-terminal-program-linux = Program spustený z terminálu ({ $terminal })
# review: new
agent-connect-title-terminal = { $programs } chcú pracovať s vašou poštou
# review: new
agent-connect-terminal-detail = Všetci AI agenti, ktorých spustíte z tohto terminálu, zdieľajú prístup, ktorý tu povolíte. Ak chcete niektorému z nich dať vlastný prístup, pridajte v nastaveniach MCP agenta do jeho argumentov --name a ľubovoľný názov.

## Keys as the keyboards of the language name them, in the help (Windows and Linux)

# review: new
key-ctrl = Ctrl
# review: new
key-alt = Alt
# review: new
key-shift = Shift
# review: new
key-del = Del
# review: new
key-enter = Enter

## Signing in and passwords

# review: new
sign-in-no-refresh = poskytovateľ nevydal obnovovací token
# review: new
sign-in-no-account = poskytovateľ neuviedol, ktoré konto sa prihlásilo
# review: new
sign-in-not-finished = prihlásenie sa nedokončilo
# review: new
secrets-unavailable = { $store } nie je k dispozícii
# review: new
secrets-unavailable-why = { $store } nie je k dispozícii: { $error }
# review: new
secrets-windows = Správca poverení
# review: new
secrets-mac = Kľúčenka
# review: new
secrets-linux = Systémová kľúčenka (Secret Service)
# review: new
error-no-such-file = taký súbor neexistuje
# review: new
cards-file-too-big = Tento súbor je príliš veľký na to, aby bol adresárom.
# review: new
ui-sender-added = Kontakt { $name } bol pridaný do adresára.
# review: new
ui-sender-known = Kontakt { $name } už je v adresári.
# review: new
ui-sender-none = Odosielateľ tejto správy nemá e-mailovú adresu, ktorú by bolo možné pridať.
# review: new
card-name-needed = Kontakt nemá meno ani e-mailovú adresu.
# a file of Import Address Book that could not be read: "kontakty.vcf: taký súbor neexistuje"
# review: new
cards-file-failed = { $file }: { $reason }

## One-time codes: the card at the top of a message with a sign-in or verification code

# the domain the code is for, which signed the message
# review: new
otp-heading = Kód od { $domain }
# review: new
otp-copy = Kopírovať
# review: new
otp-note = Zadajte ho iba na stránke domény { $domain }.
# review: new
otp-old = Tento kód bol odoslaný viac ako hodinu predtým, než ste ho otvorili, a pravdepodobne už vypršal.

# how many are invited, in the card of an event
# review: new
event-attendees =
    { $count ->
        [one] { $count } účastník
        [few] { $count } účastníci
       *[other] { $count } účastníkov
    }

# the first line of a new message's notification when it has a code, for a domain that signed it
# review: new
otp-notification = { $code } je váš kód pre { $domain }

## OpenPGP keys (keys.rs)
# review: new
pgp-key-valid = Platný
# review: new
pgp-key-expires = Platný do { $date }
# review: new
pgp-key-expired = Platnosť skončila { $date }
# review: new
pgp-key-revoked = Odvolaný
# review: new
pgp-key-revoked-why = Odvolaný: { $reason }
# review: new
pgp-key-not-valid = Neplatný
# review: new
pgp-key-locked = Nedá sa použiť: kľúč, ktorý ho chráni, už nie je v úložisku { $store }. Znova importujte jeho zálohu.
# review: new
pgp-source-own = Vytvorený v Inbox Classic
# review: new
pgp-source-file = Importovaný zo súboru
# review: new
pgp-source-paste = Vložený
# review: new
pgp-source-attachment = Zo správy
# review: new
pgp-source-vcard = Z vizitky kontaktu
# review: new
pgp-source-wkd = Od poskytovateľa pošty odosielateľa
# review: new
pgp-source-keyserver = Z keys.openpgp.org
# review: new
pgp-source-autocrypt = Z hlavičky Autocrypt správy
# review: new
pgp-error-no-store = Súkromné kľúče chráni úložisko { $store }, ktoré nemožno použiť: { $error }
# review: new
pgp-error-wrong-passphrase = Prístupová fráza nie je správna.
# review: new
pgp-error-not-a-key = Toto nie je kľúč OpenPGP.
# review: new
pgp-error-too-large = Kľúč je príliš veľký.
# review: new
pgp-error-unusable = Kľúč používa starú alebo slabú kryptografiu a nemožno ho použiť.
# review: new
pgp-imported-private = { $count ->
    [one] Váš súkromný kľúč bol importovaný.
    [few] Boli importované { $count } súkromné kľúče.
   *[other] Bolo importovaných { $count } súkromných kľúčov.
}
# review: new
pgp-imported-public = { $count ->
    [one] Bol importovaný jeden kľúč.
    [few] Boli importované { $count } kľúče.
   *[other] Bolo importovaných { $count } kľúčov.
}
# review: new
pgp-imported-pending = Pre { $addresses } sa už používa iný kľúč: nový čaká v kontakte, kým ho nevyberiete.
# review: new
pgp-error-needs-passphrase = Súkromný kľúč je chránený prístupovou frázou. Zadajte ju, aby sa kľúč importoval.
# review: new
pgp-error-mismatch = Súkromný kľúč nepatrí k svojmu verejnému kľúču. Mohol byť zmenený.
# review: new
pgp-file-name-public = Verejný kľúč { $who }.asc
# review: new
pgp-file-name-private = Záloha súkromného kľúča { $who }.asc
# review: new
pgp-pending = Pre { $address } sa { $date } našiel iný kľúč.

## Reading signed and encrypted mail (protect.rs)
# review: new
pgp-part-verified = Podpísal(a) { $signer }, kľúč overený
# review: new
pgp-part-signed = Podpísal(a) { $signer } (kľúč neoverený)
# review: new
pgp-part-other = Podpísal(a) { $signer }, nie odosielateľ
# review: new
pgp-part-unknown-key = Podpísané, ale kľúč nie je známy
# review: new
pgp-part-not-signed = Nepodpísané
# review: new
pgp-part-not-checked = Podpis nebol overený
# review: new
pgp-part-encrypted = Šifrované. { $signature }
# review: new
pgp-part-no-key = Šifrované pre kľúč, ktorý nemáte
# review: new
pgp-part-changed = Šifrovaná časť bola cestou zmenená a nezobrazuje sa
# review: new
pgp-part-unprotected = Šifrované bez ochrany proti zmenám, nezobrazuje sa
# review: new
pgp-part-broken = Šifrovanú časť nemožno prečítať
# review: new
pgp-why-mismatch = Podpis nezodpovedá tomuto textu
# review: new
pgp-why-weak-hash = Podpis používa { $hash }, ktorý už nie je bezpečný
# review: new
pgp-why-key-expired = Podpísané po skončení platnosti kľúča { $date }
# review: new
pgp-why-key-revoked = Podpísané kľúčom, ktorý bol odvolaný
# review: new
pgp-why-not-signing-key = Podpísané kľúčom, ktorý nesmie podpisovať
# review: new
pgp-why-from-future = Podpis má dátum v budúcnosti
# review: new
pgp-why-signature-expired = Platnosť podpisu skončila
# review: new
pgp-why-key-not-valid = Podpísané kľúčom, ktorý nie je platný
# review: new
pgp-why-not-for-you = Podpísané pre iných príjemcov a preposlané vám
pgp-why-not-key-in-use = Podpísané iným kľúčom, než aký sa používa pre { $address }
# review: new
pgp-part-pictures-loaded = { $label }. Obrázky boli načítané z internetu
# review: new
pgp-error-no-own-key = Nemáte kľúč pre { $address }, ktorým by ste podpisovali alebo šifrovali. Vytvorte ho v ponuke Nástroje > Šifrovacie kľúče alebo vypnite Podpísať a Šifrovať.
# review: new
pgp-error-missing-keys = { $count ->
    [one] { $addresses } nemá kľúč na šifrovanie.
   *[other] Títo príjemcovia nemajú kľúč na šifrovanie: { $addresses }.
}
# review: new
pgp-error-encrypted-quote = Táto správa cituje alebo preposiela šifrovanú správu, preto ju možno odoslať iba šifrovanú. Zapnite Šifrovať alebo odstráňte citovaný text.
# review: new
pgp-error-protect = Správu sa nepodarilo podpísať ani zašifrovať: { $reason }
# review: new
pgp-found-keys = Našiel sa kľúč pre { $addresses }.
# review: new
pgp-found-none = Pre { $addresses } sa nenašiel žiadny kľúč. Požiadajte o zaslanie verejného kľúča.
# review: new
pgp-found-no-key = Nenašiel sa žiadny kľúč.
# review: new
pgp-find-unavailable = Kľúče teraz nemožno vyhľadať: { $error }
# review: new
pgp-publish-pending = keys.openpgp.org poslal odkaz na potvrdenie na { $addresses }. Váš kľúč tam bude zverejnený, keď naň kliknete.
# review: new
pgp-publish-done = Váš kľúč je zverejnený na keys.openpgp.org pre { $addresses }.
# review: new
pgp-publish-failed = Kľúč sa nepodarilo zverejniť: { $error }
# review: changed
pgp-keyserver-off = Vyhľadávanie kľúčov na keys.openpgp.org je vypnuté v { $settings }.
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

    Otvorte okno „Šifrovacie kľúče“ a importujte zálohu tohto kľúča alebo vytvorte nový kľúč.
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
    [one] Jeden príjemca nemá použiteľný kľúč na šifrovanie. Nájdite jeho kľúč, odstráňte príjemcu zo správy alebo správu odošlite bez šifrovania.
    [few] { $count } príjemcovia nemajú použiteľné kľúče na šifrovanie. Nájdite ich kľúče, odstráňte týchto príjemcov zo správy alebo správu odošlite bez šifrovania.
   *[other] { $count } príjemcov nemá použiteľné kľúče na šifrovanie. Nájdite ich kľúče, odstráňte týchto príjemcov zo správy alebo správu odošlite bez šifrovania.
}
# review: new
pgp-details-part = Časť { $number }: { $label }
# review: new
attachment-from-part = Z časti { $number }: { $label }
# review: new
pgp-details-signed = Podpísané { $when } kľúčom { $key }
# review: new
pgp-details-unknown-key = Podpísané kľúčom { $key }, ktorý nemáte
# review: new
pgp-details-opened = Šifrované pre váš kľúč { $key }
# review: new
pgp-details-for = Šifrované pre { $keys }
# review: new
pgp-details-plain = Nepodpísané a nešifrované
# review: new
pgp-bar-parts = Táto správa má viac častí ({ $count }): { $list }. Každá časť uvádza, ako je chránená.
# review: new
pgp-bar-count-verified = overené: { $count }
# review: new
pgp-bar-count-encrypted-signed = { $count ->
    [one] 1 šifrovaná a podpísaná
    [few] { $count } šifrované a podpísané
   *[other] { $count } šifrovaných a podpísaných
}
# review: new
pgp-bar-count-encrypted = { $count ->
    [one] 1 šifrovaná
    [few] { $count } šifrované
   *[other] { $count } šifrovaných
}
# review: new
pgp-bar-count-signed = { $count ->
    [one] 1 podpísaná
    [few] { $count } podpísané
   *[other] { $count } podpísaných
}
# review: new
pgp-bar-count-warning = { $count ->
    [one] 1 vyžaduje pozornosť
    [few] { $count } vyžadujú pozornosť
   *[other] { $count } vyžaduje pozornosť
}
# review: new
pgp-bar-count-neutral = bez potvrdeného podpisu: { $count }
# the setup file: settings, accounts, contacts and keys carried to another computer
# review: new
setup-part-settings = Nastavenia
# review: new
setup-part-preferences = Predvoľby okien
# review: new
setup-part-accounts = Kontá
# review: new
setup-part-sign-in-apps = Prihlasovacie aplikácie
# review: new
setup-part-contacts = Kontakty a skupiny
# review: new
setup-part-keys = Šifrovacie kľúče
# review: new
setup-part-rules = Pravidlá správ
# review: new
setup-part-trusted-senders = Dôveryhodní odosielatelia
# review: new
setup-holds-settings = { $count ->
    [one] 1 nastavenie
    [few] { $count } nastavenia
   *[other] { $count } nastavení
}
# review: new
setup-holds-preferences = { $count ->
    [one] 1 predvoľba
    [few] { $count } predvoľby
   *[other] { $count } predvolieb
}
# review: new
setup-holds-accounts = { $count ->
    [one] 1 konto
    [few] { $count } kontá
   *[other] { $count } kont
}
# review: new
setup-holds-sign-in-apps = { $count ->
    [one] 1 prihlasovacia aplikácia
    [few] { $count } prihlasovacie aplikácie
   *[other] { $count } prihlasovacích aplikácií
}
# review: new
setup-holds-built-in = Ktoré vstavané prihlasovacie aplikácie sú zapnuté
# review: new
setup-holds-contacts = { $count ->
    [one] 1 kontakt
    [few] { $count } kontakty
   *[other] { $count } kontaktov
}
# review: new
setup-holds-groups = { $count ->
    [one] 1 skupina
    [few] { $count } skupiny
   *[other] { $count } skupín
}
# review: new
setup-holds-own-keys = { $count ->
    [one] 1 vlastný kľúč
    [few] { $count } vlastné kľúče
   *[other] { $count } vlastných kľúčov
}
# review: new
setup-holds-contact-keys = { $count ->
    [one] 1 kľúč kontaktu
    [few] { $count } kľúče kontaktov
   *[other] { $count } kľúčov kontaktov
}
# review: new
setup-holds-rules = { $count ->
    [one] 1 pravidlo
    [few] { $count } pravidlá
   *[other] { $count } pravidiel
}
# review: new
setup-holds-trusted-senders = { $count ->
    [one] 1 dôveryhodný odosielateľ
    [few] { $count } dôveryhodní odosielatelia
   *[other] { $count } dôveryhodných odosielateľov
}
# review: new
setup-sign-in-password = Heslo
# review: new
setup-account-secret-password = Jeho heslo je v súbore.
# review: new
setup-account-secret-token = Jeho prihlásenie je v súbore.
# review: new
setup-account-asks-password = Po importe si vyžiada heslo.
# review: new
setup-account-signs-in-again = Po importe sa doň znova prihlásite.
# review: new
setup-account-here = Tu už je nastavené, preto sa preskočí.
# review: new
setup-account-no-app = Prihlasuje sa cez { $app }, ktorá tu nie je nastavená. Importujte aj prihlasovacie aplikácie.
# review: new
setup-invalid-address = „{ $address }“ nie je e-mailová adresa.
# review: new
setup-invalid-server = Server { $server } nemá použiteľný názov alebo port.
# review: new
setup-invalid-user = Nemá meno používateľa.
# review: new
setup-invalid-sign-in = Prihlasuje sa spôsobom, ktorý Inbox Classic nepozná.
# review: new
setup-error-empty = Súbor je prázdny.
# review: new
setup-error-too-large = Súbor je príliš veľký na to, aby bol súborom nastavení Inbox Classic.
# review: new
setup-error-not-setup = Tento súbor nie je súborom nastavení Inbox Classic.
# review: new
setup-error-damaged = Súbor nastavení je poškodený a nemožno ho prečítať.
# review: new
setup-error-newer = Tieto nastavenia uložila novšia verzia Inbox Classic ({ $version }). Aktualizujte Inbox Classic a potom ich importujte znova.
# review: new
setup-error-needs-passphrase = Tieto nastavenia sú chránené prístupovou frázou. Zadajte frázu, s ktorou boli uložené.
# review: new
setup-error-wrong-passphrase = To nie je prístupová fráza, s ktorou boli tieto nastavenia uložené.
# review: new
setup-error-changed = Súbor nastavení bol po uložení zmenený alebo poškodený, preto ho nemožno importovať.
# review: new
setup-error-read = Súbor nastavení sa nepodarilo prečítať: { $error }
# review: new
setup-error-write = Nastavenia sa nepodarilo uložiť: { $error }
# review: new
setup-error-no-parts = Vyberte aspoň jednu časť.
# review: new
setup-left-out = { $count ->
    [one] 1 položku z časti { $part } nemožno použiť, a preto sa vynecháva.
    [few] { $count } položky z časti { $part } nemožno použiť, a preto sa vynechávajú.
   *[other] { $count } položiek z časti { $part } nemožno použiť, a preto sa vynecháva.
}
# review: new
setup-imported-settings = Nastavenia boli nahradené.
# review: new
setup-imported-preferences = Predvoľby okien boli nahradené.
# review: new
setup-added-accounts = { $count ->
    [one] Pridané 1 konto.
    [few] Pridané { $count } kontá.
   *[other] Pridaných { $count } kont.
}
# review: new
setup-skipped-here = { $address } tu už je nastavené, preto sa preskočilo.
# review: new
setup-skipped-no-app = { $address } sa preskočilo: prihlasuje sa cez { $app }, ktorá tu nie je nastavená.
# review: new
setup-skipped-invalid = { $address } sa preskočilo: { $reason }
# review: new
setup-asks-password = { $address } si pri pripojení vyžiada heslo.
# review: new
setup-signs-in-again = { $address } vás pri pripojení požiada o nové prihlásenie.
# review: new
setup-added-sign-in-apps = { $count ->
    [one] Pridaná 1 prihlasovacia aplikácia.
    [few] Pridané { $count } prihlasovacie aplikácie.
   *[other] Pridaných { $count } prihlasovacích aplikácií.
}
# review: new
setup-skipped-sign-in-apps = { $count ->
    [one] 1 prihlasovacia aplikácia tu už je nastavená.
    [few] { $count } prihlasovacie aplikácie tu už sú nastavené.
   *[other] { $count } prihlasovacích aplikácií tu už je nastavených.
}
# review: new
setup-added-contacts = { $count ->
    [one] Do adresára bol pridaný 1 kontakt.
    [few] Do adresára boli pridané { $count } kontakty.
   *[other] Do adresára bolo pridaných { $count } kontaktov.
}
# review: new
setup-skipped-contacts = { $count ->
    [one] 1 kontakt už je v adresári.
    [few] { $count } kontakty už sú v adresári.
   *[other] { $count } kontaktov už je v adresári.
}
# review: new
setup-added-groups = { $count ->
    [one] Pridaná alebo doplnená 1 skupina.
    [few] Pridané alebo doplnené { $count } skupiny.
   *[other] Pridaných alebo doplnených { $count } skupín.
}
# review: new
setup-added-own-keys = { $count ->
    [one] Pridaný 1 vlastný kľúč.
    [few] Pridané { $count } vlastné kľúče.
   *[other] Pridaných { $count } vlastných kľúčov.
}
# review: new
setup-added-contact-keys = { $count ->
    [one] Pridaný 1 kľúč kontaktu.
    [few] Pridané { $count } kľúče kontaktov.
   *[other] Pridaných { $count } kľúčov kontaktov.
}
# review: new
setup-added-rules = { $count ->
    [one] Pridané 1 pravidlo správ.
    [few] Pridané { $count } pravidlá správ.
   *[other] Pridaných { $count } pravidiel správ.
}
# review: new
setup-skipped-rules = { $count ->
    [one] 1 pravidlo správ tu už je.
    [few] { $count } pravidlá správ tu už sú.
   *[other] { $count } pravidiel správ tu už je.
}
# review: new
setup-skipped-rules-account = { $count ->
    [one] 1 pravidlo správ je pre konto, ktoré tu nie je, preto sa preskočilo.
    [few] { $count } pravidlá správ sú pre kontá, ktoré tu nie sú, preto sa preskočili.
   *[other] { $count } pravidiel správ je pre kontá, ktoré tu nie sú, preto sa preskočili.
}
# review: new
setup-rules-waiting = { $count ->
    [one] 1 pravidlo správ presúva správy do priečinka, ktorý sa zobrazí po synchronizácii jeho konta.
    [few] { $count } pravidlá správ presúvajú správy do priečinkov, ktoré sa zobrazia po synchronizácii ich kont.
   *[other] { $count } pravidiel správ presúva správy do priečinkov, ktoré sa zobrazia po synchronizácii ich kont.
}
# review: new
setup-added-trusted-senders = { $count ->
    [one] Pridaný 1 dôveryhodný odosielateľ.
    [few] Pridaní { $count } dôveryhodní odosielatelia.
   *[other] Pridaných { $count } dôveryhodných odosielateľov.
}
# review: new
setup-nothing = Nič sa neimportovalo.
# review: new
setup-account-servers = { $imap } a { $smtp } ({ $signin })
# review: new
setup-file-name = Nastavenia a kontá Inbox Classic
# review: new
setup-skipped-unreachable = { $name } sa preskočila: jej prihlasovacia služba nebola dostupná. Pridajte ju znova v okne Prihlasovacie aplikácie.
# review: new
attachment-runs-programs = Súbor „{ $name }“ môže spúšťať programy, preto ho Inbox Classic neotvorí. Uložte ho a potom ho otvorte sami, ak dôverujete jeho zdroju.
# review: new
attachment-decrypted-note = Táto príloha pochádza zo šifrovanej správy. Aby ju mohol otvoriť, Inbox Classic ju uloží dešifrovanú v tomto počítači, do vášho priečinka, ktorý Inbox Classic po jednom dni vyprázdni.
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

# review: new
preview-pdf-option = Zobrazovať súbory PDF v správach
# review: new
preview-pdf-off = Súbory PDF sa v správach nezobrazujú.
# review: new
preview-pdf-off-crashed = Súbor PDF ukončil Inbox Classic počas zobrazenia, preto sa súbory PDF v správach už nezobrazujú. Obrázky áno. Ak chcete súbory PDF znova zobrazovať, zapnite { $option } v { $settings }.
# review: new
preview-pdf-details = { $count ->
    [one] 1 strana, { $size }
    [few] { $count } strany, { $size }
    [many] { $count } strany, { $size }
   *[other] { $count } strán, { $size }
}
# review: new
preview-page-alt = { $name }, strana { $page } z { $count }
# review: new
preview-more-pages = { $count ->
    [one] Otvorte súbor a uvidíte stranu
    [few] Otvorte súbor a uvidíte všetky { $count } strany
    [many] Otvorte súbor a uvidíte všetkých { $count } strany
   *[other] Otvorte súbor a uvidíte všetkých { $count } strán
}
# review: new
preview-more-files = { $count ->
    [one] Ďalší 1 súbor je v zozname vyššie
    [few] Ďalšie { $count } súbory sú v zozname vyššie
    [many] Ďalšieho { $count } súboru je v zozname vyššie
   *[other] Ďalších { $count } súborov je v zozname vyššie
}
# review: new
preview-tile-downloading = Sťahuje sa…
# review: new
preview-tile-preparing = Pripravuje sa…
# review: new
preview-tile-format = Obrázky { $format } sa zatiaľ nezobrazujú
# review: new
preview-tile-password = Chránené heslom: otvorte ho a zadajte heslo
# review: new
preview-tile-too-large = Príliš veľké na zobrazenie
# review: new
preview-tile-unreadable = Nedá sa zobraziť
# review: new
preview-tile-timed-out = Zobrazenie trvalo príliš dlho
# review: new
preview-tile-crashed = Nezobrazené: tento súbor raz ukončil Inbox Classic
# review: new
preview-tile-off = Nezobrazené do ďalšieho spustenia Inbox Classic
# review: new
preview-not-printed = { $name } ({ $details }) sa netlačí. Ak ho chcete vytlačiť, otvorte ho.
