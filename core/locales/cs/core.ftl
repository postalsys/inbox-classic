# Čeština. Koncept, čeká na kontrolu rodilým mluvčím (viz core/locales/GLOSSARY.md).

## Counts and sizes

messages = { $count ->
    [one] 1 zpráva
    [few] { $count } zprávy
   *[other] { $count } zpráv
}
decimal-separator = ,
size-bytes = { $count ->
    [one] 1 bajt
    [few] { $count } bajty
   *[other] { $count } bajtů
}
size-kb = { $size } kB
size-mb = { $size } MB
size-gb = { $size } GB
send-delay-off = Vypnuto
send-delay-seconds = { $count ->
    [one] 1 sekunda
    [few] { $count } sekundy
   *[other] { $count } sekund
}
list-counts = { $messages }, nepřečtené: { $unread }
list-counts-selected = { $messages }, nepřečtené: { $unread }, vybrané: { $selected }
list-counts-found = Nalezeno: { $found }, nepřečtené: { $unread }
list-counts-found-selected = Nalezeno: { $found }, nepřečtené: { $unread }, vybrané: { $selected }
list-counts-none = Nebyly nalezeny žádné zprávy

## Special folders

folder-inbox = Doručená pošta
folder-sent = Odeslaná pošta
folder-deleted = Odstraněná pošta
folder-drafts = Koncepty
folder-junk = Nevyžádaná pošta
folder-archive = Archiv

## The reading pane

reader-no-message = Není vybrána žádná zpráva.
reader-downloading = Stahování zprávy…
reader-downloading-detail = Zpráva se zde zobrazí po dokončení stahování.
reader-downloading-size = Zpráva má velikost { $size }. Zobrazí se zde, až bude stažena.
reader-failed = Zprávu se nepodařilo stáhnout
reader-failed-network = K poštovnímu serveru se nepodařilo připojit ({ $reason }).
reader-failed-sign-in = Poštovní server nepřijal přihlášení ({ $reason }). Zkontrolujte heslo nebo se znovu přihlaste v nabídce Soubor > Účty.
reader-failed-security = Nepodařilo se navázat zabezpečené spojení s poštovním serverem ({ $reason }).
reader-failed-other = Poštovní server odpověděl: { $reason }.
reader-retry-note = Po obnovení připojení účtu se aplikace pokusí zprávu stáhnout znovu.
reader-unreadable = Tuto zprávu nelze zobrazit: { $error }
message-source-title = Zdrojový kód zprávy: { $subject }
message-source-untitled = Zdrojový kód zprávy

## Printing and quoting

header-from = Od
header-date = Datum
header-to = Komu
header-cc = Kopie
header-sent = Odesláno
header-subject = Předmět
header-security = Zabezpečení
header-part = Část { $number }
quote-original = ----- Původní zpráva -----
fold-show-earlier = Zobrazit starší zprávy

## Bounces

bounce-failed = Vaše zpráva nebyla doručena
bounce-delayed = Vaše zpráva zatím nebyla doručena
bounce-delayed-note = Váš poštovní server se ji stále pokouší doručit. Není třeba ji posílat znovu.
bounce-show-message = Zobrazit nedoručenou zprávu
bounce-show-delayed = Zobrazit zpožděnou zprávu
bounce-what-to-do = Co můžete udělat:
bounce-delayed-do = Zatím nemusíte nic dělat. Pokud se zprávu nepodaří doručit, dostanete další oznámení.
bounce-delayed-row-do = Zatím nemusíte nic dělat. Váš poštovní server se zprávu stále pokouší doručit. Pokud se to nepodaří, dostanete další oznámení.
bounce-details = Podrobnosti
bounce-someone = Příjemce
bounce-server = Server: { $server }
bounce-status = Stav: { $status }
bounce-reported-by = Ohlásil: { $server }
bounce-retry-minutes = Server příjemce požádal, aby se další pokus uskutečnil za { $count ->
    [one] 1 minutu
    [few] { $count } minuty
   *[other] { $count } minut
}.
bounce-retry-hours = Server příjemce požádal, aby se další pokus uskutečnil za { $count ->
    [one] 1 hodinu
    [few] { $count } hodiny
   *[other] { $count } hodin
}.
bounce-blocklist = Seznamy blokovaných adres: { $lists }
bounce-user-unknown = Adresa neexistuje
bounce-user-unknown-why = Server příjemce nemá schránku s touto adresou. Adresa může obsahovat překlep, nebo ji daná osoba už nepoužívá.
bounce-user-unknown-do = Zkontrolujte, zda je adresa napsána správně, nebo se dané osoby zeptejte na adresu, kterou používá teď.
bounce-invalid-address = Adresa není platná
bounce-invalid-address-why = Adresa nemá správný formát pro odesílání pošty.
bounce-invalid-address-do = Zkontrolujte, zda v adrese není překlep, mezera nebo chybějící část, například za znakem @.
bounce-mailbox-disabled = Schránka není aktivní
bounce-mailbox-disabled-why = Adresa existuje, ale její schránka byla vypnuta nebo se už nepoužívá.
bounce-mailbox-disabled-do = Spojte se s danou osobou jinak a zeptejte se na adresu, kterou používá teď.
bounce-mailbox-full = Schránka je plná
bounce-mailbox-full-why = Ve schránce příjemce není místo pro novou poštu.
bounce-mailbox-full-do = Pošlete zprávu znovu za několik dní nebo příjemce upozorněte jiným způsobem. Velké přílohy mohou být odmítnuty jako první.
bounce-spam-blocked = Odmítnuto jako spam
bounce-spam-blocked-why = Server příjemce považoval zprávu za spam.
bounce-spam-blocked-do = Zkuste zprávu odeslat bez velkého množství odkazů, zkrácených odkazů nebo velkých příloh, které mohou působit jako spam. Pokud se odmítnutí opakuje, obraťte se na svého poskytovatele pošty.
bounce-virus-detected = Odmítnuto kvůli viru
bounce-virus-detected-why = Server příjemce našel ve zprávě nebo v jejích přílohách virus nebo jiný škodlivý obsah.
bounce-virus-detected-do = Zkontrolujte přílohy antivirovým programem. Některé servery odmítají všechny programy a archivy, takové soubory proto sdílejte jako odkaz.
bounce-ip-blocklisted = Váš poštovní server je na seznamu blokovaných
bounce-ip-blocklisted-why = Server příjemce odmítá poštu ze serveru, který odeslal vaši zprávu, protože adresa tohoto serveru je na seznamu blokovaných.
bounce-ip-blocklisted-do = Problém není ve zprávě. Přepošlete toto oznámení svému poskytovateli pošty a požádejte ho, aby server ze seznamu nechal odstranit.
bounce-domain-blocklisted = Doména je na seznamu blokovaných
bounce-domain-blocklisted-why = Server příjemce zprávu odmítá, protože doména vaší adresy nebo doména v odkazech zprávy je na seznamu blokovaných.
bounce-domain-blocklisted-do = Pokud zpráva obsahuje odkazy, zkuste ji poslat bez nich. Jinak přepošlete toto oznámení tomu, kdo spravuje poštu vaší domény.
bounce-policy-blocked = Odmítnuto podle pravidel serveru příjemce
bounce-policy-blocked-why = Pravidla serveru příjemce tuto zprávu nepropustí, například kvůli její velikosti, přílohám nebo odesílateli.
bounce-policy-blocked-do = Důvod bývá uveden v odpovědi serveru v části Podrobnosti. Zeptejte se příjemce, zda může takovou zprávu přijmout.
bounce-geo-blocked = Odmítnuto kvůli místu původu
bounce-geo-blocked-why = Server příjemce nepřijímá poštu ze země nebo sítě, ve které je váš poštovní server.
bounce-geo-blocked-do = Spojte se s danou osobou jinak, nebo se obraťte na svého poskytovatele pošty.
bounce-relay-denied = Server zprávu nepředal dál
bounce-relay-denied-why = Server odmítl zprávu doručit dál, často proto, že byla odeslána bez přihlášení nebo přes server, který tohoto příjemce neobsluhuje.
bounce-relay-denied-do = V nabídce Soubor > Účty zkontrolujte nastavení serveru odchozí pošty a přihlašování k němu.
bounce-auth-failure = Adresu odesílatele nelze ověřit
bounce-auth-failure-why = Server příjemce nemohl potvrdit, že zpráva opravdu přišla z vaší domény (SPF, DKIM nebo DMARC).
bounce-auth-failure-do = Přepošlete toto oznámení tomu, kdo spravuje poštu vaší domény: její nastavení je třeba opravit. Mezitím může pomoci odesílání přes vlastní server vašeho poskytovatele.
bounce-rate-limited = Příliš mnoho pošty najednou
bounce-rate-limited-why = Server příjemce dočasně omezuje počet zpráv přijímaných z vašeho poštovního serveru.
bounce-rate-limited-do = Chvíli počkejte a pošlete zprávu znovu. Pokud píšete mnoha lidem, rozdělte je do menších skupin příjemců.
bounce-greylisting = Na chvíli pozdrženo
bounce-greylisting-why = Server příjemce žádá neznámé odesílatele, aby to zkusili o něco později. Je to běžná ochrana proti spamu.
bounce-greylisting-do = Nic. Poštovní servery to zkusí znovu samy a zpráva se obvykle doručí do hodiny.
bounce-server-error = Server příjemce měl problém
bounce-server-error-why = Server příjemce nebyl dostupný, nebo zprávu nemohl přijmout kvůli vlastnímu problému.
bounce-server-error-do = Pošlete zprávu znovu později. Pokud se to stále nedaří, zkontrolujte, zda část adresy za znakem @ neobsahuje překlep.
bounce-unknown = Nedoručeno
bounce-unknown-why = Z oznámení není jasné, proč nebyla zpráva doručena.
bounce-unknown-do = Další informace mohou být v odpovědi serveru v části Podrobnosti. Pokud nepomohou, přepošlete oznámení svému poskytovateli pošty.

## Several messages selected

selection-title = { $count ->
    [one] Vybrána 1 zpráva
    [few] Vybrány { $count } zprávy
   *[other] Vybráno { $count } zpráv
}
selection-unread = { $count ->
    [one] { $count } nepřečtená
    [few] { $count } nepřečtené
   *[other] { $count } nepřečtených
}
selection-flagged = { $count } s příznakem
delete-for-good-one = Tato zpráva bude trvale odstraněna. Odstranit ji?
delete-for-good-all = Tyto zprávy ({ $count }) budou trvale odstraněny. Odstranit je?
delete-for-good-some = Z celkového počtu zpráv ({ $total }) se trvale odstraní: { $count }. Odstranit zprávy?
done-read = { $count ->
    [one] { $messages } označena jako přečtená
    [few] { $messages } označeny jako přečtené
   *[other] { $messages } označeno jako přečtené
}
done-unread = { $count ->
    [one] { $messages } označena jako nepřečtená
    [few] { $messages } označeny jako nepřečtené
   *[other] { $messages } označeno jako nepřečtené
}
done-flagged = { $count ->
    [one] { $messages } označena příznakem
    [few] { $messages } označeny příznakem
   *[other] { $messages } označeno příznakem
}
done-unflagged = Příznak zrušen: { $messages }
done-deleted-for-good = { $count ->
    [one] { $messages } trvale odstraněna
    [few] { $messages } trvale odstraněny
   *[other] { $messages } trvale odstraněno
}
done-archived = { $count ->
    [one] { $messages } archivována
    [few] { $messages } archivovány
   *[other] { $messages } archivováno
}
done-moved = { $count ->
    [one] { $messages } přesunuta (cíl: { $folder })
    [few] { $messages } přesunuty (cíl: { $folder })
   *[other] { $messages } přesunuto (cíl: { $folder })
}
done-copied = { $count ->
    [one] { $messages } zkopírována (cíl: { $folder })
    [few] { $messages } zkopírovány (cíl: { $folder })
   *[other] { $messages } zkopírováno (cíl: { $folder })
}
done-moving = { $count ->
   *[other] Přesouvání: { $messages } (cíl: { $folder })...
}
done-copying = { $count ->
   *[other] Kopírování: { $messages } (cíl: { $folder })...
}
done-moved-back = { $count ->
    [one] { $messages } vrácena zpět (cíl: { $folder })
    [few] { $messages } vráceny zpět (cíl: { $folder })
   *[other] { $messages } vráceno zpět (cíl: { $folder })
}
done-watched = { $count ->
    [one] Konverzace je sledována
    [few] Sledují se { $count } konverzace
   *[other] Sleduje se { $count } konverzací
}
done-unwatched = { $count ->
    [one] Sledování konverzace ukončeno
    [few] Sledování { $count } konverzací ukončeno
   *[other] Sledování { $count } konverzací ukončeno
}
done-ignored = { $count ->
    [one] Konverzace je ignorována
    [few] Ignorují se { $count } konverzace
   *[other] Ignoruje se { $count } konverzací
}
done-unignored = { $count ->
    [one] Ignorování konverzace ukončeno
    [few] Ignorování { $count } konverzací ukončeno
   *[other] Ignorování { $count } konverzací ukončeno
}
their-folders = původní složky
undo-move = Zpět: přesunutí
undo-delete = Zpět: odstranění
undo-archive = Zpět: archivace
undo-junk = Zpět: označení jako nevyžádané
undo-not-junk = Zpět: označení jako vyžádané
undo-send = Zpět: odeslání
nothing-to-undo = Není co vrátit zpět.
messages-gone = Zprávy už zde nejsou.
folder-holds-no-messages = Tato složka nemůže obsahovat zprávy.
not-archived-here = Zprávy v této složce nelze archivovat.
not-emptied-here = Vyprázdnit lze jen složky Odstraněná pošta a Nevyžádaná pošta.
next-unread-question = Ve složce { $folder } už nejsou žádné nepřečtené zprávy.

    Přejít do další složky s nepřečtenými zprávami: { $next }?
no-unread-left = Nezbývají žádné nepřečtené zprávy.
empty-question = { $count ->
    [one] Vyprázdnit složku { $folder }?

        Zpráva v ní bude trvale odstraněna. Nelze ji obnovit.
    [few] Vyprázdnit složku { $folder }?

        { $messages } v ní budou trvale odstraněny. Nelze je obnovit.
   *[other] Vyprázdnit složku { $folder }?

        { $messages } v ní bude trvale odstraněno. Nelze je obnovit.
}
no-junk-folder = Tento účet nemá složku Nevyžádaná pošta, do které by bylo možné zprávy přesunout.
no-inbox-folder = Tento účet nemá složku Doručená pošta, do které by bylo možné zprávy přesunout.
done-flagged-color = Označeno příznakem: { $messages }. Barva: { $color ->
    [red] červená
    [orange] oranžová
    [yellow] žlutá
    [green] zelená
    [blue] modrá
    [purple] fialová
   *[gray] šedá
}
flag-color = { $color ->
    [red] Červená
    [orange] Oranžová
    [yellow] Žlutá
    [green] Zelená
    [blue] Modrá
    [purple] Fialová
   *[gray] Šedá
}

## The Move and Copy window

move-window-title-move = { $count ->
    [one] Přesunout zprávu
    [few] Přesunout { $count } zprávy
   *[other] Přesunout { $count } zpráv
}
move-window-title-copy = { $count ->
    [one] Kopírovat zprávu
    [few] Kopírovat { $count } zprávy
   *[other] Kopírovat { $count } zpráv
}
move-window-prompt-move = { $count ->
    [one] Přesunout vybranou zprávu do:
    [few] Přesunout { $count } vybrané zprávy do:
   *[other] Přesunout { $count } vybraných zpráv do:
}
move-window-prompt-copy = { $count ->
    [one] Kopírovat vybranou zprávu do:
    [few] Kopírovat { $count } vybrané zprávy do:
   *[other] Kopírovat { $count } vybraných zpráv do:
}
targets-recent = Naposledy použité
target-current = { $folder } (aktuální)
target-recent = { $folder } ({ $account })

## Moving and copying to another account

transfer-moving = Přesouvání (cíl: { $folder }): { $done } / { $messages }...
transfer-copying = Kopírování (cíl: { $folder }): { $done } / { $messages }...
transfer-another-account = jiný účet
transfer-folder-gone = cílová složka už neexistuje
transfer-not-on-server = zpráva už na serveru není
transfer-not-moved = { $count ->
   *[other] Na jiný účet nelze přesunout: { $messages } ({ $reason })
}
transfer-not-copied = { $count ->
   *[other] Na jiný účet nelze zkopírovat: { $messages } ({ $reason })
}
transfer-none-moved = Žádnou zprávu se nepodařilo přesunout
transfer-none-copied = Žádnou zprávu se nepodařilo zkopírovat

## Messages as files

export-not-in-time = zprávu se nepodařilo včas stáhnout
export-not-saved = Celkem: { $messages }. Nepodařilo se uložit: { $failed } ({ $problems })
export-not-attached = zprávy nelze připojit: { $error }
saved-to = { $count ->
    [one] { $messages } uložena do složky { $folder }
    [few] { $messages } uloženy do složky { $folder }
   *[other] { $messages } uloženo do složky { $folder }
}
download-progress = Stahování: { $done } / { $total }
download-done = Staženo { $size }
downloading-messages = { $count ->
   *[other] Stahování: { $messages }...
}
import-put = { $count ->
    [one] { $messages } vložena do složky { $folder }
    [few] { $messages } vloženy do složky { $folder }
   *[other] { $messages } vloženo do složky { $folder }
}
import-not-put = Tyto soubory nebyly vloženy do složky:

    { $problems }

## Problems the windows show

error-store = místní úložiště: { $error }
error-not-found = nenalezeno
error-closed = probíhá ukončení
error-other-account = prohlížeč se přihlásil k účtu { $email }, ne k tomuto účtu
failure-authentication = server nepřijal přihlášení ({ $reason })
failure-network = spojení se serverem selhalo ({ $reason })
error-in-use = nelze ji odebrat, dokud se s ní přihlašují účty: { $accounts }
error-turned-off = tato přihlašovací aplikace je pro nové účty vypnutá
error-folder-name = název složky musí mít 1 až 200 znaků a nesmí obsahovat řídicí znaky
error-folder-separator = název složky nesmí na tomto serveru obsahovat znak „{ $separator }“
error-folder-special = Doručenou poštu a systémové složky nelze přejmenovat ani odstranit
error-no-recipients = zpráva nemá žádné příjemce
error-bad-address = „{ $address }“ není e-mailová adresa
error-not-own-address = { $address } není jednou z adres odesílatele tohoto účtu. Přidejte ji do pole „Další adresy, ze kterých odesíláte“ ve vlastnostech účtu.
rule-query-refused = Pravidla nemohou filtrovat podle složky ani data ({ $words }).
rule-no-query = Zadejte kritéria hledání pro příchozí zprávy.
rule-no-action = Zvolte pro pravidlo alespoň jednu akci.
error-attachment = soubor { $path } nelze přečíst: { $error }
error-no-drafts = účet nemá složku Koncepty, do které by bylo možné zprávu uložit
error-draft-attachment = přílohu konceptu nelze zachovat: { $error }
error-password-not-saved = heslo nelze uložit pro příští spuštění: { $error }
error-sign-in-not-saved = nové přihlašovací údaje nelze uložit pro příští spuštění: { $error }
error-import-unreadable = soubor { $path } nelze přečíst: { $error }
error-import-too-large = soubor { $path } je větší než 50 MB
error-import-not-mail = soubor { $path } není e-mailová zpráva
error-list-answered = server poštovní konference vrátil stav { $status }
error-not-built = zprávu nelze sestavit
error-outbox-waits = { $count ->
    [one] zpráva čeká ve složce Pošta k odeslání a odešle se při příštím odeslání a přijetí
    [few] { $count } zprávy čekají ve složce Pošta k odeslání a odešlou se při příštím odeslání a přijetí
   *[other] { $count } zpráv čeká ve složce Pošta k odeslání a odešle se při příštím odeslání a přijetí
}
error-draft-not-removed = předchozí koncept zprávy nelze odebrat ze složky Koncepty: { $reason }
error-sent-but = zpráva byla odeslána, ale { $problem }
error-sent-still-in-outbox = je stále ve složce Pošta k odeslání: { $error }
error-sent-no-copy = do složky Odeslaná pošta nelze uložit kopii: { $reason }
error-no-password = pro tento účet není uloženo heslo
error-no-sign-in = pro tento účet nejsou uloženy přihlašovací údaje
error-provider-missing = v této verzi se nelze přihlásit ke službě { $provider }. Nebyla odebrána její přihlašovací aplikace?
error-provider-servers = servery tohoto účtu neodpovídají serverům jeho přihlašovací aplikace
error-app-scopes = { $reason }. Poštovní server nepřijal token přihlašovací aplikace: zkontrolujte, zda oprávnění (scopes) aplikace dávají přístup k poště
error-in-folder = { $folder }: { $reason }

## Sign-in apps

sign-in-off-google = Google zatím aplikaci Inbox Classic neověřil, takže se přes ni mohou přihlásit jen testovací uživatelé. Použijte vlastní přihlašovací aplikaci Google nebo heslo aplikace, nebo ji zapněte v okně Přihlašovací aplikace (Soubor > Účty), pokud jste testovací uživatel.
sign-in-off-other = Byla vypnuta v okně Přihlašovací aplikace (Soubor > Účty), kde ji lze znovu zapnout.
sign-in-app-no-name = přihlašovací aplikace musí mít název
sign-in-app-no-client = chybí ID klienta
sign-in-app-no-scopes = přihlašovací aplikace potřebuje oprávnění (scopes), která dávají přístup k poště
sign-in-app-bad-host = adresa serveru { $server } chybí nebo není platným názvem hostitele
sign-in-app-plain = server { $server } musí používat SSL/TLS nebo STARTTLS
sign-in-app-not-checked = vydavatel ještě nebyl ověřen
sign-in-app-issuer-changed = vydavatel se změnil: zadejte znovu tajný kód klienta, nebo ho odeberte
sign-in-register-google = V Google Cloud Console vytvořte klienta OAuth typu Desktop app s oprávněním https://mail.google.com/ na jeho obrazovce souhlasu. Dokud je aplikace ve fázi testování, mohou se přihlásit jen její testovací uživatelé.
sign-in-register-microsoft = V Microsoft Entra zaregistrujte aplikaci s platformou Mobile and desktop applications, URI přesměrování http://localhost, povolenými toky veřejného klienta a delegovanými oprávněními IMAP.AccessAsUser.All, SMTP.Send a offline_access. Jen pro vaši organizaci použijte jako vydavatele https://login.microsoftonline.com/<ID tenanta>/v2.0.
sign-in-register-other = Zaregistrujte nativního (veřejného) klienta s níže uvedeným URI přesměrování; poskytovatel na něm musí povolit libovolný port (RFC 8252). Přidejte oprávnění, kterým poskytovatel dává přístup k poště.

## Calendar invitations

repeats = Opakování
repeats-every = { $unit ->
    [day] { $interval ->
        [one] Každý den
        [few] Každé { $interval } dny
       *[other] Každých { $interval } dní
    }
    [week] { $interval ->
        [one] Každý týden
        [few] Každé { $interval } týdny
       *[other] Každých { $interval } týdnů
    }
    [month] { $interval ->
        [one] Každý měsíc
        [few] Každé { $interval } měsíce
       *[other] Každých { $interval } měsíců
    }
   *[year] { $interval ->
        [one] Každý rok
        [few] Každé { $interval } roky
       *[other] Každých { $interval } let
    }
}
repeats-on = { $repeats }, dny: { $days }
repeats-times = { $count ->
    [one] { $repeats }, jednou
    [few] { $repeats }, celkem { $count } opakování
   *[other] { $repeats }, celkem { $count } opakování
}
day-monday = pondělí
day-tuesday = úterý
day-wednesday = středa
day-thursday = čtvrtek
day-friday = pátek
day-saturday = sobota
day-sunday = neděle

## AI agents

agent-level-read = Číst poštu: prohlížet složky a zprávy a vyhledávat v nich
agent-level-organize = Uspořádat poštu: měnit stav přečtení a příznaky, označovat nevyžádanou poštu, přesouvat zprávy a odstraňovat je do složky Odstraněná pošta
agent-level-drafts = Psát koncepty, které odešlete vy
agent-level-send = Odesílat poštu, každou zprávu až po vašem souhlasu
agent-connect-title = { $program } chce používat vaši poštu
agent-connect-detail = Agent AI požádal o přístup k aplikaci Inbox Classic. Zvolte, co smí dělat a ke kterým účtům má mít přístup. Později to můžete změnit v nabídce Nástroje > Agenti AI.

    Agenti čtou zprávy od jiných lidí. Ty mohou obsahovat pokyny, které se je snaží oklamat. Před odesláním jakékoli zprávy agentem si Inbox Classic vždy vyžádá váš souhlas.
agent-reply-to = Odpověď na „{ $subject }“
agent-reply-all-on = Odpověď všem na „{ $subject }“
agent-forward-of = Přeposlání „{ $subject }“
agent-never-written-one = Na adresu { $address } jste nikdy nepsali.
agent-never-written-many = Na některé z těchto adres jste nikdy nepsali (počet: { $count }).
agent-send-title = { $program } chce odeslat tuto zprávu
agent-send-detail = Zkontrolujte příjemce a obsah zprávy. Po potvrzení zpráva počká { $seconds } s ve složce Pošta k odeslání, kde ji ještě můžete odstranit.
agent-change-title = Co smí { $program } dělat
agent-change-allowed = Změňte, co smí agenti AI tohoto programu dělat s vaší poštou.
agent-change-refused = Tomuto programu jste odepřeli přístup. Povolte ho, aby jeho agenti opět měli přístup k vaší poště.
agent-log-taken-back = { $entry } (vráceno zpět)
agent-files = Soubory: { $files }
agent-undo-refused = Nelze vrátit zpět.
agent-undo-refused-why = Nelze vrátit zpět: { $reason }.
agent-undo-impossible = toto nelze vrátit zpět
agent-undo-not-in-folder = zpráva už v této složce není
agent-undo-not-arrived = zpráva (zatím) není ve složce, kam byla přesunuta
agent-undo-sent = zpráva už není ve složce Pošta k odeslání
agent-original-not-downloaded = původní zpráva ještě nebyla stažena. Nejdřív ji otevřete
agent-turned-away = Odmítnuto
agent-can-nothing = Nic
agent-can-read = číst
agent-can-organize = uspořádat
agent-can-drafts = psát koncepty
agent-can-send = odesílat s vaším souhlasem
agent-can-list = { $first } a { $last }
agent-accounts = { $count ->
    [0] žádné účty
    [one] 1 účet
    [few] { $count } účty
   *[other] { $count } účtů
}
agent-access = { $can }; { $accounts }
agent-unreadable = Tuto zprávu nelze přečíst.
agent-encrypted-original = Tato zpráva je šifrovaná: agent na ni nemůže odpovědět ani ji přeposlat, protože neumí šifrovat.
agent-encrypted = Tato zpráva je šifrovaná. Agenti AI nemohou číst její obsah. Uživatel ji musí otevřít v aplikaci Inbox Classic.
list-encrypted = Šifrovaná zpráva
agent-log-composed = Otevřena nová zpráva „{ $subject }“, abyste ji mohli dokončit
agent-log-refused = Odeslání zprávy „{ $subject }“ nebylo schváleno
agent-log-sent = Zpráva „{ $subject }“ zařazena k odeslání. Příjemci: { $to }
agent-log-draft = Uložen koncept „{ $subject }“
agent-log-read = Označeno jako přečtené: „{ $subject }“
agent-log-unread = Označeno jako nepřečtené: „{ $subject }“
agent-log-flagged = Označeno příznakem: „{ $subject }“
agent-log-unflagged = Zrušen příznak: „{ $subject }“
agent-log-deleted = Odstraněno: „{ $subject }“
agent-log-moved = „{ $subject }“ přesunuto (cíl: { $folder })
agent-log-junk = Označeno jako nevyžádané: „{ $subject }“
agent-log-not-junk = Označeno jako vyžádané: „{ $subject }“
agent-log-archived = Archivováno: „{ $subject }“
agent-log-folder = Vytvořena složka „{ $name }“
agent-log-unsubscribed = Odhlášen odběr ze seznamu, z něhož přišla zpráva „{ $subject }“

## Keys

key-ctrl = Ctrl
key-alt = Alt
key-shift = Shift
key-del = Del
key-enter = Enter

## Signing in and passwords

sign-in-no-refresh = poskytovatel neposkytl obnovovací token
sign-in-no-account = poskytovatel neuvedl, který účet se přihlásil
sign-in-not-finished = přihlašování nebylo dokončeno
secrets-unavailable = { $store } není k dispozici
secrets-unavailable-why = { $store } není k dispozici: { $error }
secrets-windows = Správce pověření
secrets-mac = Klíčenka
secrets-linux = Systémová klíčenka (Secret Service)
error-no-such-file = takový soubor neexistuje
cards-file-too-big = Tento soubor je pro import adresáře příliš velký.
ui-sender-added = Kontakt { $name } byl přidán do Adresáře.
ui-sender-known = Kontakt { $name } už je v Adresáři.
ui-sender-none = Odesílatel této zprávy nemá e-mailovou adresu, kterou by bylo možné přidat.
card-name-needed = Kontakt nemá jméno ani e-mailovou adresu.
cards-file-failed = { $file }: { $reason }

## One-time codes

otp-heading = Kód od { $domain }
otp-copy = Kopírovat
otp-note = Zadejte ho jen na stránce domény { $domain }.
otp-old = Kód byl odeslán více než hodinu před otevřením zprávy a jeho platnost už pravděpodobně vypršela.

event-attendees =
    { $count ->
        [one] { $count } účastník
        [few] { $count } účastníci
       *[other] { $count } účastníků
    }

otp-notification = { $code } je váš kód pro { $domain }

## OpenPGP keys (keys.rs)
pgp-key-valid = Platný
pgp-key-expires = Platný do { $date }
pgp-key-expired = Platnost vypršela { $date }
pgp-key-revoked = Odvolaný
pgp-key-revoked-why = Odvolaný: { $reason }
pgp-key-not-valid = Neplatný
pgp-key-locked = Tento soukromý klíč nelze použít, protože v úložišti { $store } chybí klíč, který jej chrání. Obnovte soukromý klíč importem jeho zálohy.
pgp-source-own = Vytvořen v aplikaci Inbox Classic
pgp-source-file = Importován ze souboru
pgp-source-paste = Vložen
pgp-source-attachment = Ze zprávy
pgp-source-vcard = Z vizitky kontaktu
pgp-source-wkd = Od poskytovatele pošty odesílatele
pgp-source-keyserver = Z keys.openpgp.org
pgp-source-autocrypt = Z hlavičky Autocrypt zprávy
pgp-error-no-store = Soukromé klíče chrání úložiště { $store }, které nelze použít: { $error }
pgp-error-wrong-passphrase = Heslová fráze není správná.
pgp-error-not-a-key = Toto není klíč OpenPGP.
pgp-error-too-large = Klíč je příliš velký.
pgp-error-unusable = Klíč používá zastaralé nebo slabé šifrovací postupy a nelze jej použít.
pgp-imported-private = { $count ->
    [one] Váš soukromý klíč byl importován.
    [few] Byly importovány { $count } soukromé klíče.
   *[other] Bylo importováno { $count } soukromých klíčů.
}
pgp-imported-public = { $count ->
    [one] Byl importován jeden klíč.
    [few] Byly importovány { $count } klíče.
   *[other] Bylo importováno { $count } klíčů.
}
pgp-imported-pending = Pro uvedené adresy už používáte jiný klíč: { $addresses }. Nový klíč je uložen u kontaktu a začne se používat, až jej vyberete.
pgp-error-needs-passphrase = Soukromý klíč je chráněn heslovou frází. Zadejte ji, abyste klíč mohli importovat.
pgp-error-mismatch = Soukromý klíč neodpovídá příslušnému veřejnému klíči. Mohl být pozměněn.
pgp-file-name-public = { $who } - veřejný klíč.asc
pgp-file-name-private = { $who } - záloha soukromého klíče.asc
pgp-pending = Pro { $address } byl { $date } nalezen jiný klíč.

## Reading signed and encrypted mail (protect.rs)
pgp-part-verified = Digitální podpis: { $signer }, vlastnictví klíče ověřeno
pgp-part-signed = Digitální podpis: { $signer } (vlastnictví klíče neověřeno)
pgp-part-other = Digitální podpis: { $signer }, podpis není od odesílatele
pgp-part-unknown-key = Digitálně podepsáno, ale podpisový klíč není známý
pgp-part-not-signed = Bez digitálního podpisu
pgp-part-not-checked = Digitální podpis nebyl zkontrolován
pgp-part-encrypted = Šifrováno. { $signature }
pgp-part-no-key = Šifrováno pro klíč, který nemáte
pgp-part-changed = Šifrovaná část byla cestou změněna a nezobrazuje se
pgp-part-unprotected = Šifrováno bez ochrany proti změnám, nezobrazuje se
pgp-part-broken = Šifrovanou část nelze přečíst
pgp-why-mismatch = Digitální podpis neodpovídá tomuto textu
pgp-why-weak-hash = Digitální podpis používá algoritmus { $hash }, který už není bezpečný
pgp-why-key-expired = Podepsáno až po vypršení platnosti klíče (datum vypršení: { $date })
pgp-why-key-revoked = Podepsáno klíčem, který byl odvolán
pgp-why-not-signing-key = Podepsáno klíčem, který není určen k podepisování
pgp-why-from-future = Digitální podpis má datum v budoucnosti
pgp-why-signature-expired = Platnost digitálního podpisu vypršela
pgp-why-key-not-valid = Podepsáno klíčem, který není platný
pgp-why-not-for-you = Podepsáno pro jiné příjemce a předáno vám
pgp-part-pictures-loaded = { $label }. Obrázky byly načteny z internetu
pgp-error-no-own-key = Pro { $address } nemáte klíč, kterým byste mohli podepisovat nebo šifrovat. Vytvořte si ho v nabídce Nástroje > Šifrovací klíče, nebo vypněte Podepsat a Šifrovat.
pgp-error-missing-keys = { $count ->
    [one] Chybí klíč pro šifrování zpráv příjemci: { $addresses }.
   *[other] Chybějí klíče pro šifrování zpráv těmto příjemcům: { $addresses }.
}
pgp-error-encrypted-quote = Tato zpráva cituje nebo přeposílá šifrovanou zprávu, a lze ji proto odeslat jen šifrovaně. Zapněte Šifrovat, nebo odeberte citovaný text.
pgp-error-protect = Zprávu nelze podepsat ani zašifrovat: { $reason }
pgp-found-keys = Klíče nalezeny pro adresy: { $addresses }.
pgp-found-none = Pro { $addresses } nebyl nalezen žádný klíč. Požádejte o zaslání veřejného klíče.
pgp-found-no-key = Nebyl nalezen žádný klíč.
pgp-find-unavailable = Klíče teď nelze vyhledat: { $error }
pgp-publish-pending = Služba keys.openpgp.org poslala potvrzovací odkaz na tyto adresy: { $addresses }. Potvrďte každou adresu, aby podle ní bylo možné váš klíč vyhledat.
pgp-publish-done = Váš klíč je zveřejněn na keys.openpgp.org pro { $addresses }.
pgp-publish-failed = Klíč nelze zveřejnit: { $error }
pgp-keyserver-off = Vyhledávání klíčů na serveru keys.openpgp.org je vypnuté v nastavení { $settings }.
pgp-details-part = Část { $number }: { $label }
pgp-details-signed = Digitálně podepsáno: { $when }. Klíč: { $key }
pgp-details-unknown-key = Podepsáno klíčem { $key }, který nemáte
pgp-details-opened = Dešifrováno vaším klíčem { $key }
pgp-details-for = Šifrováno pro klíče: { $keys }
pgp-details-plain = Bez digitálního podpisu a šifrování
pgp-bar-parts = Tato zpráva má více částí ({ $count }): { $list }. U každé části je uvedeno, jak je chráněna.
pgp-bar-count-verified = ověřené: { $count }
pgp-bar-count-good = { $count ->
    [one] 1 podepsaná nebo šifrovaná
    [few] { $count } podepsané nebo šifrované
   *[other] { $count } podepsaných nebo šifrovaných
}
pgp-bar-count-warning = { $count ->
    [one] 1 vyžaduje pozornost
    [few] { $count } vyžadují pozornost
   *[other] { $count } vyžaduje pozornost
}
pgp-bar-count-neutral = bez potvrzeného digitálního podpisu: { $count }
setup-part-settings = Nastavení
setup-part-preferences = Předvolby oken
setup-part-accounts = Účty
setup-part-sign-in-apps = Přihlašovací aplikace
setup-part-contacts = Kontakty a skupiny
setup-part-keys = Šifrovací klíče
setup-part-rules = Pravidla zpráv
setup-part-trusted-senders = Důvěryhodní odesílatelé
setup-holds-settings = { $count ->
    [one] 1 nastavení
   *[other] { $count } nastavení
}
setup-holds-preferences = { $count ->
    [one] 1 předvolba
    [few] { $count } předvolby
   *[other] { $count } předvoleb
}
setup-holds-accounts = { $count ->
    [one] 1 účet
    [few] { $count } účty
   *[other] { $count } účtů
}
setup-holds-sign-in-apps = { $count ->
    [one] 1 přihlašovací aplikace
    [few] { $count } přihlašovací aplikace
   *[other] { $count } přihlašovacích aplikací
}
setup-holds-built-in = Které vestavěné přihlašovací aplikace jsou zapnuté
setup-holds-contacts = { $count ->
    [one] 1 kontakt
    [few] { $count } kontakty
   *[other] { $count } kontaktů
}
setup-holds-groups = { $count ->
    [one] 1 skupina
    [few] { $count } skupiny
   *[other] { $count } skupin
}
setup-holds-own-keys = { $count ->
    [one] 1 vlastní klíč
    [few] { $count } vlastní klíče
   *[other] { $count } vlastních klíčů
}
setup-holds-contact-keys = { $count ->
    [one] 1 klíč kontaktu
    [few] { $count } klíče kontaktů
   *[other] { $count } klíčů kontaktů
}
setup-holds-rules = { $count ->
    [one] 1 pravidlo
    [few] { $count } pravidla
   *[other] { $count } pravidel
}
setup-holds-trusted-senders = { $count ->
    [one] 1 důvěryhodný odesílatel
    [few] { $count } důvěryhodní odesílatelé
   *[other] { $count } důvěryhodných odesílatelů
}
setup-sign-in-password = Heslo
setup-account-secret-password = Soubor obsahuje heslo k tomuto účtu.
setup-account-secret-token = Soubor obsahuje přihlašovací údaje k tomuto účtu.
setup-account-asks-password = Po importu budete muset zadat heslo k tomuto účtu.
setup-account-signs-in-again = Po importu se k němu znovu přihlásíte.
setup-account-here = Tady už je nastaven, proto se přeskočí.
setup-account-no-app = Účet používá přihlašovací aplikaci { $app }, která zde není nastavená. Importujte také přihlašovací aplikace.
setup-invalid-address = „{ $address }“ není e-mailová adresa.
setup-invalid-server = Server { $server } nemá použitelný název nebo port.
setup-invalid-user = Nemá uživatelské jméno.
setup-invalid-sign-in = Přihlašuje se způsobem, který Inbox Classic nezná.
setup-error-empty = Soubor je prázdný.
setup-error-too-large = Soubor je pro import nastavení aplikace Inbox Classic příliš velký.
setup-error-not-setup = Tento soubor neobsahuje nastavení aplikace Inbox Classic.
setup-error-damaged = Soubor s nastavením je poškozený a nelze ho přečíst.
setup-error-newer = Toto nastavení uložila novější verze aplikace Inbox Classic ({ $version }). Aktualizujte aplikaci a pak nastavení importujte znovu.
setup-error-needs-passphrase = Toto nastavení je chráněno heslovou frází. Zadejte heslovou frázi, se kterou bylo uloženo.
setup-error-wrong-passphrase = To není heslová fráze, se kterou bylo toto nastavení uloženo.
setup-error-changed = Soubor s nastavením byl po uložení změněn nebo poškozen, a proto ho nelze importovat.
setup-error-read = Soubor s nastavením nelze přečíst: { $error }
setup-error-write = Nastavení nelze uložit: { $error }
setup-error-no-parts = Zvolte alespoň jednu část.
setup-left-out = { $count ->
    [one] V části „{ $part }“ byla vynechána 1 nepoužitelná položka.
    [few] V části „{ $part }“ byly vynechány { $count } nepoužitelné položky.
   *[other] V části „{ $part }“ bylo vynecháno { $count } nepoužitelných položek.
}
setup-imported-settings = Nastavení bylo nahrazeno.
setup-imported-preferences = Předvolby oken byly nahrazeny.
setup-added-accounts = { $count ->
    [one] Přidán 1 účet.
    [few] Přidány { $count } účty.
   *[other] Přidáno { $count } účtů.
}
setup-skipped-here = Účet { $address } už je zde nastaven, proto byl přeskočen.
setup-skipped-no-app = Účet { $address } byl přeskočen, protože jeho přihlašovací aplikace { $app } zde není nastavená.
setup-skipped-invalid = Účet { $address } byl přeskočen: { $reason }
setup-asks-password = Při připojení k účtu { $address } budete muset zadat heslo.
setup-signs-in-again = Při připojení k účtu { $address } se budete muset znovu přihlásit.
setup-added-sign-in-apps = { $count ->
    [one] Přidána 1 přihlašovací aplikace.
    [few] Přidány { $count } přihlašovací aplikace.
   *[other] Přidáno { $count } přihlašovacích aplikací.
}
setup-skipped-sign-in-apps = { $count ->
    [one] 1 přihlašovací aplikace už je tady nastavená.
    [few] { $count } přihlašovací aplikace už jsou tady nastavené.
   *[other] { $count } přihlašovacích aplikací už je tady nastaveno.
}
setup-added-contacts = { $count ->
    [one] Do adresáře byl přidán 1 kontakt.
    [few] Do adresáře byly přidány { $count } kontakty.
   *[other] Do adresáře bylo přidáno { $count } kontaktů.
}
setup-skipped-contacts = { $count ->
    [one] 1 kontakt už v adresáři je.
    [few] { $count } kontakty už v adresáři jsou.
   *[other] { $count } kontaktů už v adresáři je.
}
setup-added-groups = { $count ->
    [one] Přidána nebo doplněna 1 skupina.
    [few] Přidány nebo doplněny { $count } skupiny.
   *[other] Přidáno nebo doplněno { $count } skupin.
}
setup-added-own-keys = { $count ->
    [one] Přidán 1 vlastní klíč.
    [few] Přidány { $count } vlastní klíče.
   *[other] Přidáno { $count } vlastních klíčů.
}
setup-added-contact-keys = { $count ->
    [one] Přidán 1 klíč kontaktu.
    [few] Přidány { $count } klíče kontaktů.
   *[other] Přidáno { $count } klíčů kontaktů.
}
setup-added-rules = { $count ->
    [one] Přidáno 1 pravidlo zpráv.
    [few] Přidána { $count } pravidla zpráv.
   *[other] Přidáno { $count } pravidel zpráv.
}
setup-skipped-rules = { $count ->
    [one] 1 pravidlo zpráv už tady je.
    [few] { $count } pravidla zpráv už tady jsou.
   *[other] { $count } pravidel zpráv už tady je.
}
setup-skipped-rules-account = { $count ->
    [one] 1 pravidlo zpráv patří k účtu, který tady není, proto bylo přeskočeno.
    [few] { $count } pravidla zpráv patří k účtům, které tady nejsou, proto byla přeskočena.
   *[other] { $count } pravidel zpráv patří k účtům, které tady nejsou, proto bylo přeskočeno.
}
setup-rules-waiting = { $count ->
    [one] 1 pravidlo zpráv přesouvá zprávy do složky, která se objeví po synchronizaci jejího účtu.
    [few] { $count } pravidla zpráv přesouvají zprávy do složek, které se objeví po synchronizaci jejich účtů.
   *[other] { $count } pravidel zpráv přesouvá zprávy do složek, které se objeví po synchronizaci jejich účtů.
}
setup-added-trusted-senders = { $count ->
    [one] Přidán 1 důvěryhodný odesílatel.
    [few] Přidáni { $count } důvěryhodní odesílatelé.
   *[other] Přidáno { $count } důvěryhodných odesílatelů.
}
setup-nothing = Nic nebylo importováno.
setup-account-servers = { $imap } a { $smtp } ({ $signin })
setup-file-name = Nastavení a účty Inbox Classic
setup-skipped-unreachable = Přihlašovací aplikace { $name } byla přeskočena, protože její služba nebyla dostupná. Přidejte ji znovu v okně Přihlašovací aplikace.
attachment-runs-programs = Soubor „{ $name }“ může spouštět programy, proto ho Inbox Classic neotevře. Uložte ho a otevřete ho sami, pokud důvěřujete jeho původu.
attachment-decrypted-note = Tato příloha pochází ze šifrované zprávy. Při otevření uloží Inbox Classic nešifrovanou kopii do dočasné složky vašeho uživatelského účtu. Při spuštění aplikace se odstraní kopie starší než jeden den.
# a bar over the list when the server did not do what the user asked of messages, so they are as they were again
undone-move = { $count ->
    [one] Server nepřesunul zprávu do složky { $folder }, takže { $messages } je zpět ve složce { $from }: { $reason }
    [few] Server nepřesunul zprávy do složky { $folder }, takže { $messages } jsou zpět ve složce { $from }: { $reason }
   *[other] Server nepřesunul zprávy do složky { $folder }, takže { $messages } je zpět ve složce { $from }: { $reason }
}
undone-delete = { $count ->
    [one] Server neodstranil zprávu, takže { $messages } je zpět ve složce { $from }: { $reason }
    [few] Server neodstranil zprávy, takže { $messages } jsou zpět ve složce { $from }: { $reason }
   *[other] Server neodstranil zprávy, takže { $messages } je zpět ve složce { $from }: { $reason }
}
undone-archive = { $count ->
    [one] Server nearchivoval zprávu, takže { $messages } je zpět ve složce { $from }: { $reason }
    [few] Server nearchivoval zprávy, takže { $messages } jsou zpět ve složce { $from }: { $reason }
   *[other] Server nearchivoval zprávy, takže { $messages } je zpět ve složce { $from }: { $reason }
}
undone-read = { $count ->
    [one] Server neoznačil zprávu jako přečtenou, takže { $messages } je opět nepřečtená: { $reason }
    [few] Server neoznačil zprávy jako přečtené, takže { $messages } jsou opět nepřečtené: { $reason }
   *[other] Server neoznačil zprávy jako přečtené, takže { $messages } je opět nepřečtených: { $reason }
}
undone-unread = { $count ->
    [one] Server neoznačil zprávu jako nepřečtenou, takže { $messages } je opět přečtená: { $reason }
    [few] Server neoznačil zprávy jako nepřečtené, takže { $messages } jsou opět přečtené: { $reason }
   *[other] Server neoznačil zprávy jako nepřečtené, takže { $messages } je opět přečtených: { $reason }
}
undone-flags = { $count ->
    [one] Server nezměnil příznaky zprávy, proto byla změna vrácena zpět ({ $messages }): { $reason }
    [few] Server nezměnil příznaky zpráv, proto byla změna vrácena zpět ({ $messages }): { $reason }
   *[other] Server nezměnil příznaky zpráv, proto byla změna vrácena zpět ({ $messages }): { $reason }
}
