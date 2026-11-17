# Čeština. Koncept, čeká na kontrolu rodilým mluvčím (viz core/locales/GLOSSARY.md).

## Counts and sizes

# review: new
messages = { $count ->
    [one] 1 zpráva
    [few] { $count } zprávy
   *[other] { $count } zpráv
}
# review: new
decimal-separator = ,
# review: new
size-bytes = { $count ->
    [one] 1 bajt
    [few] { $count } bajty
   *[other] { $count } bajtů
}
# review: new
size-kb = { $size } kB
# review: new
size-mb = { $size } MB
# review: new
size-gb = { $size } GB
# review: new
send-delay-off = Vypnuto
# review: new
send-delay-seconds = { $count ->
    [one] 1 sekunda
    [few] { $count } sekundy
   *[other] { $count } sekund
}
# review: new
list-counts = { $messages }, nepřečtené: { $unread }
# review: new
list-counts-selected = { $messages }, nepřečtené: { $unread }, vybrané: { $selected }
# review: new
list-counts-found = Nalezeno: { $found }, nepřečtené: { $unread }
# review: new
list-counts-found-selected = Nalezeno: { $found }, nepřečtené: { $unread }, vybrané: { $selected }
# review: new
list-counts-none = Nebyly nalezeny žádné zprávy

## Special folders

# review: new
folder-inbox = Doručená pošta
# review: new
folder-sent = Odeslaná pošta
# review: new
folder-deleted = Odstraněná pošta
# review: new
folder-drafts = Koncepty
# review: new
folder-junk = Nevyžádaná pošta
# review: new
folder-archive = Archiv

## The reading pane

# review: new
reader-no-message = Není vybrána žádná zpráva.
# review: new
reader-downloading = Stahování zprávy…
# review: new
reader-downloading-detail = Zpráva se zde zobrazí po dokončení stahování.
# review: new
reader-downloading-size = Zpráva má velikost { $size }. Zobrazí se zde, až bude stažena.
# review: new
reader-failed = Zprávu se nepodařilo stáhnout
# review: new
reader-failed-network = Poštovní server není dostupný ({ $reason }).
# review: new
reader-failed-sign-in = Poštovní server nepřijal přihlášení ({ $reason }). Zkontrolujte heslo nebo se znovu přihlaste v nabídce Soubor > Účty.
# review: new
reader-failed-security = Spojení s poštovním serverem nelze zabezpečit ({ $reason }).
# review: new
reader-failed-other = Poštovní server odpověděl: { $reason }.
# review: new
reader-retry-note = Stažení se zkusí znovu, až se účet opět připojí.
# review: new
reader-unreadable = Tuto zprávu nelze zobrazit: { $error }
# review: new
message-source-title = Zdrojový kód zprávy: { $subject }
# review: new
message-source-untitled = Zdrojový kód zprávy

## Printing and quoting

# review: new
header-from = Od
# review: new
header-date = Datum
# review: new
header-to = Komu
# review: new
header-cc = Kopie
# review: new
header-sent = Odesláno
# review: new
header-subject = Předmět
# review: new
header-security = Zabezpečení
# review: new
header-part = Část { $number }
# review: new
quote-original = ----- Původní zpráva -----
# review: new
fold-show-earlier = Zobrazit starší zprávy

## Bounces

# review: new
bounce-failed = Vaše zpráva nebyla doručena
# review: new
bounce-delayed = Vaše zpráva zatím nebyla doručena
# review: new
bounce-delayed-note = Váš poštovní server se ji stále pokouší doručit. Není třeba ji posílat znovu.
# review: new
bounce-show-message = Zobrazit nedoručenou zprávu
# review: new
bounce-show-delayed = Zobrazit zpožděnou zprávu
# review: new
bounce-what-to-do = Co můžete udělat:
# review: new
bounce-delayed-do = Zatím nic. Pokud ji ani tak nepůjde doručit, dostanete další oznámení.
# review: new
bounce-delayed-row-do = Zatím nic. Váš poštovní server se ji stále pokouší doručit, a pokud se to nepodaří, dostanete další oznámení.
# review: new
bounce-details = Podrobnosti
# review: new
bounce-someone = Příjemce
# review: new
bounce-server = Server: { $server }
# review: new
bounce-status = Stav: { $status }
# review: new
bounce-reported-by = Ohlásil: { $server }
# review: new
bounce-retry-minutes = Přijímající server požádal o počkání { $count ->
    [one] 1 minutu
    [few] { $count } minuty
   *[other] { $count } minut
} před dalším pokusem.
# review: new
bounce-retry-hours = Přijímající server požádal o počkání { $count ->
    [one] 1 hodinu
    [few] { $count } hodiny
   *[other] { $count } hodin
} před dalším pokusem.
# review: new
bounce-blocklist = Seznam blokovaných: { $lists }
# review: new
bounce-user-unknown = Adresa neexistuje
# review: new
bounce-user-unknown-why = Přijímající server nemá schránku s touto adresou. Adresa může obsahovat překlep, nebo ji daná osoba už nepoužívá.
# review: new
bounce-user-unknown-do = Zkontrolujte, zda je adresa napsána správně, nebo se dané osoby zeptejte na adresu, kterou používá teď.
# review: new
bounce-invalid-address = Adresa není platná
# review: new
bounce-invalid-address-why = Adresa není zapsána ve tvaru, na který lze poslat poštu.
# review: new
bounce-invalid-address-do = Hledejte překlepy, například mezeru, chybějící písmeno nebo nic za znakem @.
# review: new
bounce-mailbox-disabled = Schránka je zrušena
# review: new
bounce-mailbox-disabled-why = Adresa existuje, ale její schránka byla vypnuta nebo se už nepoužívá.
# review: new
bounce-mailbox-disabled-do = Spojte se s danou osobou jinak a zeptejte se na adresu, kterou používá teď.
# review: new
bounce-mailbox-full = Schránka je plná
# review: new
bounce-mailbox-full-why = Ve schránce příjemce není místo pro novou poštu.
# review: new
bounce-mailbox-full-do = Pošlete zprávu znovu za několik dní, nebo dejte osobě vědět jinak. Jako první se odmítají velké přílohy.
# review: new
bounce-spam-blocked = Odmítnuto jako spam
# review: new
bounce-spam-blocked-why = Přijímající server považoval zprávu za spam.
# review: new
bounce-spam-blocked-do = Pošlete ji znovu bez toho, co vypadá jako spam, například bez mnoha odkazů, zkrácených odkazů nebo velké přílohy. Pokud se to opakuje, obraťte se na svého poskytovatele pošty.
# review: new
bounce-virus-detected = Odmítnuto kvůli viru
# review: new
bounce-virus-detected-why = Přijímající server našel ve zprávě nebo v jejích přílohách virus nebo jiný škodlivý obsah.
# review: new
bounce-virus-detected-do = Zkontrolujte přílohy antivirovým programem. Některé servery odmítají všechny programy a archivy, takové soubory proto sdílejte jako odkaz.
# review: new
bounce-ip-blocklisted = Váš poštovní server je na seznamu blokovaných
# review: new
bounce-ip-blocklisted-why = Přijímající server odmítá poštu ze serveru, který odeslal vaši zprávu, protože adresa tohoto serveru je na seznamu blokovaných.
# review: new
bounce-ip-blocklisted-do = Problém není ve zprávě. Přepošlete toto oznámení svému poskytovateli pošty a požádejte ho, aby server ze seznamu nechal odstranit.
# review: new
bounce-domain-blocklisted = Doména je na seznamu blokovaných
# review: new
bounce-domain-blocklisted-why = Přijímající server zprávu odmítá, protože doména vaší adresy nebo doména v odkazech zprávy je na seznamu blokovaných.
# review: new
bounce-domain-blocklisted-do = Pokud zpráva obsahuje odkazy, zkuste ji poslat bez nich. Jinak přepošlete toto oznámení tomu, kdo spravuje poštu vaší domény.
# review: new
bounce-policy-blocked = Odmítnuto pravidly přijímajícího serveru
# review: new
bounce-policy-blocked-why = Pravidla přijímajícího serveru tuto zprávu nepropustí, například kvůli její velikosti, přílohám nebo odesílateli.
# review: new
bounce-policy-blocked-do = Důvod často uvádí vlastní slova serveru v části Podrobnosti. Zeptejte se příjemce, zda může takovou poštu přijímat.
# review: new
bounce-geo-blocked = Odmítnuto kvůli místu původu
# review: new
bounce-geo-blocked-why = Přijímající server nepřijímá poštu ze země nebo sítě, ve které je váš poštovní server.
# review: new
bounce-geo-blocked-do = Spojte se s danou osobou jinak, nebo se obraťte na svého poskytovatele pošty.
# review: new
bounce-relay-denied = Server zprávu nepředal dál
# review: new
bounce-relay-denied-why = Server odmítl zprávu doručit dál, často proto, že byla odeslána bez přihlášení nebo přes server, který tohoto příjemce neobsluhuje.
# review: new
bounce-relay-denied-do = V nabídce Soubor > Účty zkontrolujte server odchozí pošty účtu a to, zda se přihlašuje.
# review: new
bounce-auth-failure = Adresu odesílatele nelze ověřit
# review: new
bounce-auth-failure-why = Přijímající server nemohl potvrdit, že zpráva opravdu přišla z vaší domény (SPF, DKIM nebo DMARC).
# review: new
bounce-auth-failure-do = Přepošlete toto oznámení tomu, kdo spravuje poštu vaší domény: její nastavení je třeba opravit. Mezitím může pomoci odesílání přes vlastní server vašeho poskytovatele.
# review: new
bounce-rate-limited = Příliš mnoho pošty najednou
# review: new
bounce-rate-limited-why = Přijímající server teď od vašeho poštovního serveru přijímá méně zpráv.
# review: new
bounce-rate-limited-do = Chvíli počkejte a pošlete zprávu znovu. Když píšete mnoha lidem, posílejte ji menšímu počtu najednou.
# review: new
bounce-greylisting = Na chvíli pozdrženo
# review: new
bounce-greylisting-why = Přijímající server žádá neznámé odesílatele, aby to zkusili o něco později. Je to běžná ochrana proti spamu.
# review: new
bounce-greylisting-do = Nic. Poštovní servery to zkusí znovu samy a zpráva se obvykle doručí do hodiny.
# review: new
bounce-server-error = Přijímající server měl problém
# review: new
bounce-server-error-why = Přijímající server nebyl dostupný, nebo zprávu nemohl přijmout kvůli vlastnímu problému.
# review: new
bounce-server-error-do = Pošlete zprávu znovu později. Pokud se to stále nedaří, zkontrolujte, zda část adresy za znakem @ neobsahuje překlep.
# review: new
bounce-unknown = Nedoručeno
# review: new
bounce-unknown-why = Oznámení jasně neuvádí proč.
# review: new
bounce-unknown-do = Více mohou říct vlastní slova serveru v části Podrobnosti. Pokud nepomohou, přepošlete toto oznámení svému poskytovateli pošty.

## Several messages selected

# review: new
selection-title = { $count ->
    [one] Vybrána 1 zpráva
    [few] Vybrány { $count } zprávy
   *[other] Vybráno { $count } zpráv
}
# review: new
selection-unread = { $count ->
    [one] { $count } nepřečtená
    [few] { $count } nepřečtené
   *[other] { $count } nepřečtených
}
# review: new
selection-flagged = { $count } s příznakem
# review: new
delete-for-good-one = Tato zpráva bude trvale odstraněna. Odstranit ji?
# review: new
delete-for-good-all = Tyto zprávy ({ $count }) budou trvale odstraněny. Odstranit je?
# review: new
delete-for-good-some = Některé zprávy budou trvale odstraněny ({ $count } z { $total }). Odstranit zprávy?
# review: new
done-read = { $count ->
    [one] { $messages } označena jako přečtená
    [few] { $messages } označeny jako přečtené
   *[other] { $messages } označeno jako přečtené
}
# review: new
done-unread = { $count ->
    [one] { $messages } označena jako nepřečtená
    [few] { $messages } označeny jako nepřečtené
   *[other] { $messages } označeno jako nepřečtené
}
# review: new
done-flagged = { $count ->
    [one] { $messages } označena příznakem
    [few] { $messages } označeny příznakem
   *[other] { $messages } označeno příznakem
}
# review: new
done-unflagged = Příznak zrušen: { $messages }
# review: new
done-deleted-for-good = { $count ->
    [one] { $messages } trvale odstraněna
    [few] { $messages } trvale odstraněny
   *[other] { $messages } trvale odstraněno
}
# review: new
done-archived = { $count ->
    [one] { $messages } archivována
    [few] { $messages } archivovány
   *[other] { $messages } archivováno
}
# review: new
done-moved = { $count ->
    [one] { $messages } přesunuta (cíl: { $folder })
    [few] { $messages } přesunuty (cíl: { $folder })
   *[other] { $messages } přesunuto (cíl: { $folder })
}
# review: new
done-copied = { $count ->
    [one] { $messages } zkopírována (cíl: { $folder })
    [few] { $messages } zkopírovány (cíl: { $folder })
   *[other] { $messages } zkopírováno (cíl: { $folder })
}
# review: new
done-moving = { $count ->
   *[other] Přesouvání: { $messages } (cíl: { $folder })...
}
# review: new
done-copying = { $count ->
   *[other] Kopírování: { $messages } (cíl: { $folder })...
}
# review: new
done-moved-back = { $count ->
    [one] { $messages } vrácena zpět (cíl: { $folder })
    [few] { $messages } vráceny zpět (cíl: { $folder })
   *[other] { $messages } vráceno zpět (cíl: { $folder })
}
# review: new
done-watched = { $count ->
    [one] Konverzace je sledována
    [few] Sledují se { $count } konverzace
   *[other] Sleduje se { $count } konverzací
}
# review: new
done-unwatched = { $count ->
    [one] Sledování konverzace ukončeno
    [few] Sledování { $count } konverzací ukončeno
   *[other] Sledování { $count } konverzací ukončeno
}
# review: new
done-ignored = { $count ->
    [one] Konverzace je ignorována
    [few] Ignorují se { $count } konverzace
   *[other] Ignoruje se { $count } konverzací
}
# review: new
done-unignored = { $count ->
    [one] Ignorování konverzace ukončeno
    [few] Ignorování { $count } konverzací ukončeno
   *[other] Ignorování { $count } konverzací ukončeno
}
# review: new
their-folders = původní složky
# review: new
undo-move = Zpět: přesunutí
# review: new
undo-delete = Zpět: odstranění
# review: new
undo-archive = Zpět: archivace
# review: new
undo-junk = Zpět: označení jako nevyžádané
# review: new
undo-not-junk = Zpět: označení jako vyžádané
# review: new
undo-send = Zpět: odeslání
# review: new
nothing-to-undo = Není co vrátit zpět.
# review: new
messages-gone = Zprávy už neexistují.
# review: new
folder-holds-no-messages = Tato složka nemůže obsahovat zprávy.
# review: new
not-archived-here = Zprávy v této složce nelze archivovat.
# review: new
not-emptied-here = Vyprázdnit lze jen složky Odstraněná pošta a Nevyžádaná pošta.
# review: new
next-unread-question = Ve složce { $folder } už nejsou žádné nepřečtené zprávy.

    Přejít do složky { $next }, další složky s nepřečtenými zprávami?
# review: new
no-unread-left = Nezbývají žádné nepřečtené zprávy.
# review: new
empty-question = { $count ->
    [one] Vyprázdnit složku { $folder }?

        Zpráva v ní bude trvale odstraněna. Nelze ji obnovit.
    [few] Vyprázdnit složku { $folder }?

        { $messages } v ní budou trvale odstraněny. Nelze je obnovit.
   *[other] Vyprázdnit složku { $folder }?

        { $messages } v ní bude trvale odstraněno. Nelze je obnovit.
}
# review: new
no-junk-folder = Tento účet nemá složku Nevyžádaná pošta, do které by bylo možné zprávy přesunout.
# review: new
no-inbox-folder = Tento účet nemá složku Doručená pošta, do které by bylo možné zprávy přesunout.
# review: new
done-flagged-color = Příznakem označeno: { $messages }, barva { $color ->
    [red] červená
    [orange] oranžová
    [yellow] žlutá
    [green] zelená
    [blue] modrá
    [purple] fialová
   *[gray] šedá
}
# review: new
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

# review: new
move-window-title-move = { $count ->
    [one] Přesunout zprávu
    [few] Přesunout { $count } zprávy
   *[other] Přesunout { $count } zpráv
}
# review: new
move-window-title-copy = { $count ->
    [one] Kopírovat zprávu
    [few] Kopírovat { $count } zprávy
   *[other] Kopírovat { $count } zpráv
}
# review: new
move-window-prompt-move = { $count ->
    [one] Přesunout vybranou zprávu do:
    [few] Přesunout { $count } vybrané zprávy do:
   *[other] Přesunout { $count } vybraných zpráv do:
}
# review: new
move-window-prompt-copy = { $count ->
    [one] Kopírovat vybranou zprávu do:
    [few] Kopírovat { $count } vybrané zprávy do:
   *[other] Kopírovat { $count } vybraných zpráv do:
}
# review: new
targets-recent = Naposledy použité
# review: new
target-current = { $folder } (aktuální)
# review: new
target-recent = { $folder } ({ $account })

## Moving and copying to another account

# review: new
transfer-moving = Přesouvání (cíl: { $folder }): { $done } / { $messages }...
# review: new
transfer-copying = Kopírování (cíl: { $folder }): { $done } / { $messages }...
# review: new
transfer-another-account = jiný účet
# review: new
transfer-folder-gone = cílová složka už neexistuje
# review: new
transfer-not-on-server = zpráva už na serveru není
# review: new
transfer-not-moved = { $count ->
   *[other] Na jiný účet nelze přesunout: { $messages } ({ $reason })
}
# review: new
transfer-not-copied = { $count ->
   *[other] Na jiný účet nelze zkopírovat: { $messages } ({ $reason })
}
# review: new
transfer-none-moved = Žádnou zprávu se nepodařilo přesunout
# review: new
transfer-none-copied = Žádnou zprávu se nepodařilo zkopírovat

## Messages as files

# review: new
export-not-in-time = zprávu se nepodařilo včas stáhnout
# review: new
export-not-saved = Nelze uložit { $failed } / { $messages } ({ $problems })
# review: new
export-not-attached = zprávy nelze připojit: { $error }
# review: new
saved-to = { $count ->
    [one] { $messages } uložena do složky { $folder }
    [few] { $messages } uloženy do složky { $folder }
   *[other] { $messages } uloženo do složky { $folder }
}
# review: new
download-progress = Stahování: { $done } / { $total }
# review: new
download-done = Staženo { $size }
# review: new
downloading-messages = { $count ->
   *[other] Stahování: { $messages }...
}
# review: new
import-put = { $count ->
    [one] { $messages } vložena do složky { $folder }
    [few] { $messages } vloženy do složky { $folder }
   *[other] { $messages } vloženo do složky { $folder }
}
# review: new
import-not-put = Tyto soubory nebyly vloženy do složky:

    { $problems }

## Problems the windows show

# review: new
error-store = místní úložiště: { $error }
# review: new
error-not-found = nenalezeno
# review: new
error-closed = probíhá ukončení
# review: new
error-other-account = prohlížeč se přihlásil k účtu { $email }, ne k tomuto účtu
# review: new
failure-authentication = server nepřijal přihlášení ({ $reason })
# review: new
failure-network = spojení se serverem selhalo ({ $reason })
# review: new
error-in-use = nelze ji odebrat, dokud se s ní přihlašují účty: { $accounts }
# review: new
error-turned-off = tato přihlašovací aplikace je pro nové účty vypnutá
# review: new
error-folder-name = název složky musí mít 1 až 200 znaků a nesmí obsahovat řídicí znaky
# review: new
error-folder-separator = název složky nesmí na tomto serveru obsahovat znak „{ $separator }“
# review: new
error-folder-special = Doručenou poštu a zvláštní složky nelze přejmenovat ani odstranit
# review: new
error-no-recipients = zpráva nemá žádné příjemce
# review: new
error-bad-address = „{ $address }“ není e-mailová adresa
# review: new
error-not-own-address = { $address } není jednou z adres odesílatele tohoto účtu. Přidejte ji do pole „Další adresy, ze kterých odesíláte“ ve vlastnostech účtu.
# review: new
rule-query-refused = Pravidla nemohou filtrovat podle složky ani data ({ $words }).
# review: new
rule-no-query = Zadejte kritéria hledání pro příchozí zprávy.
# review: new
rule-no-action = Zvolte pro pravidlo alespoň jednu akci.
# review: new
error-attachment = soubor { $path } nelze přečíst: { $error }
# review: new
error-no-drafts = účet nemá složku Koncepty, do které by bylo možné zprávu uložit
# review: new
error-draft-attachment = přílohu konceptu nelze zachovat: { $error }
# review: new
error-password-not-saved = heslo nelze uložit pro příští spuštění: { $error }
# review: new
error-sign-in-not-saved = nové přihlašovací údaje nelze uložit pro příští spuštění: { $error }
# review: new
error-import-unreadable = soubor { $path } nelze přečíst: { $error }
# review: new
error-import-too-large = soubor { $path } je větší než 50 MB
# review: new
error-import-not-mail = soubor { $path } není e-mailová zpráva
# review: new
error-list-answered = server poštovní konference vrátil stav { $status }
# review: new
error-not-built = zprávu nelze sestavit
# review: new
error-outbox-waits = { $count ->
    [one] zpráva čeká ve složce Pošta k odeslání a odešle se při příštím odeslání a přijetí
    [few] { $count } zprávy čekají ve složce Pošta k odeslání a odešlou se při příštím odeslání a přijetí
   *[other] { $count } zpráv čeká ve složce Pošta k odeslání a odešle se při příštím odeslání a přijetí
}
# review: new
error-draft-not-removed = předchozí koncept zprávy nelze odebrat ze složky Koncepty: { $reason }
# review: new
error-sent-but = zpráva byla odeslána, ale { $problem }
# review: new
error-sent-still-in-outbox = je stále ve složce Pošta k odeslání: { $error }
# review: new
error-sent-no-copy = do složky Odeslaná pošta nelze uložit kopii: { $reason }
# review: new
error-no-password = pro tento účet není uloženo heslo
# review: new
error-no-sign-in = pro tento účet není uloženo přihlášení
# review: new
error-provider-missing = tato verze se nemůže přihlásit k { $provider }: byla odebrána její přihlašovací aplikace?
# review: new
error-provider-servers = servery tohoto účtu neodpovídají serverům jeho přihlašovací aplikace
# review: new
error-app-scopes = { $reason }. Poštovní server nepřijal token přihlašovací aplikace: zkontrolujte, zda oprávnění (scopes) aplikace dávají přístup k poště
# review: new
error-in-folder = { $folder }: { $reason }

## Sign-in apps

# review: new
sign-in-off-google = Google zatím aplikaci Inbox Classic neověřil, takže se přes ni mohou přihlásit jen testovací uživatelé. Použijte vlastní přihlašovací aplikaci Google nebo heslo aplikace, nebo ji zapněte v okně Přihlašovací aplikace (Soubor > Účty), pokud jste testovací uživatel.
# review: new
sign-in-off-other = Byla vypnuta v okně Přihlašovací aplikace (Soubor > Účty), kde ji lze znovu zapnout.
# review: new
sign-in-app-no-name = přihlašovací aplikace musí mít název
# review: new
sign-in-app-no-client = chybí ID klienta
# review: new
sign-in-app-no-scopes = přihlašovací aplikace potřebuje oprávnění (scopes), která dávají přístup k poště
# review: new
sign-in-app-bad-host = adresa serveru { $server } chybí nebo není platný název hostitele
# review: new
sign-in-app-plain = server { $server } musí používat SSL/TLS nebo STARTTLS
# review: new
sign-in-app-not-checked = vydavatel ještě nebyl ověřen
# review: new
sign-in-app-issuer-changed = vydavatel se změnil: zadejte znovu tajný kód klienta, nebo ho odeberte
# review: new
sign-in-register-google = V Google Cloud Console vytvořte klienta OAuth typu Desktop app s oprávněním https://mail.google.com/ na jeho obrazovce souhlasu. Dokud je aplikace ve fázi testování, mohou se přihlásit jen její testovací uživatelé.
# review: new
sign-in-register-microsoft = V Microsoft Entra zaregistrujte aplikaci s platformou Mobile and desktop applications, URI přesměrování http://localhost, povolenými toky veřejného klienta a delegovanými oprávněními IMAP.AccessAsUser.All, SMTP.Send a offline_access. Jen pro vaši organizaci použijte jako vydavatele https://login.microsoftonline.com/<ID tenanta>/v2.0.
# review: new
sign-in-register-other = Zaregistrujte nativního (veřejného) klienta s níže uvedeným URI přesměrování; poskytovatel na něm musí povolit libovolný port (RFC 8252). Přidejte oprávnění, kterým poskytovatel dává přístup k poště.

## Calendar invitations

# review: new
repeats = Opakování
# review: new
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
# review: new
repeats-on = { $repeats }, dny: { $days }
# review: new
repeats-times = { $count ->
    [one] { $repeats }, jednou
    [few] { $repeats }, { $count }krát
   *[other] { $repeats }, { $count }krát
}
# review: new
day-monday = pondělí
# review: new
day-tuesday = úterý
# review: new
day-wednesday = středa
# review: new
day-thursday = čtvrtek
# review: new
day-friday = pátek
# review: new
day-saturday = sobota
# review: new
day-sunday = neděle

## AI agents

# review: new
agent-level-read = Číst poštu: složky, seznam zpráv, hledání a zprávy
# review: new
agent-level-organize = Třídit poštu: stav přečtení, příznaky, nevyžádaná pošta, přesouvání, odstraňování do složky Odstraněná pošta
# review: new
agent-level-drafts = Psát koncepty, které odešlete vy
# review: new
agent-level-send = Odesílat poštu, každou zprávu až po vašem souhlasu
# review: new
agent-connect-title = { $program } chce používat vaši poštu
# review: new
agent-connect-detail = Agent AI požádal o práci s aplikací Inbox Classic. Zvolte, co smí dělat a které účty smí vidět; později to můžete změnit v nabídce Nástroje > Agenti AI.

    Agenti čtou poštu, kterou napsali jiní lidé, a zpráva se je může pokusit oklamat. Inbox Classic se vás vždy zeptá, než agent cokoli odešle.
# review: new
agent-reply-to = Odpověď na „{ $subject }“
# review: new
agent-reply-all-on = Odpověď všem na „{ $subject }“
# review: new
agent-forward-of = Přeposlání „{ $subject }“
# review: new
agent-never-written-one = Na adresu { $address } jste nikdy nepsali.
# review: new
agent-never-written-many = Na některé z těchto adres jste nikdy nepsali (počet: { $count }).
# review: new
agent-send-title = { $program } chce odeslat tuto zprávu
# review: new
agent-send-detail = Zkontrolujte příjemce a obsah zprávy. Po potvrzení zpráva počká { $seconds } s ve složce Pošta k odeslání, kde ji ještě můžete odstranit.
# review: new
agent-change-title = Co smí { $program } dělat
# review: new
agent-change-allowed = Změňte, co smí agenti AI tohoto programu dělat s vaší poštou.
# review: new
agent-change-refused = Tomuto programu jste odepřeli přístup. Povolte ho, aby jeho agenti opět měli přístup k vaší poště.
# review: new
agent-log-taken-back = { $entry } (vráceno zpět)
# review: new
agent-files = Soubory: { $files }
# review: new
agent-undo-refused = Nelze vrátit zpět.
# review: new
agent-undo-refused-why = Nelze vrátit zpět: { $reason }.
# review: new
agent-undo-impossible = toto nelze vrátit zpět
# review: new
agent-undo-not-in-folder = zpráva už v této složce není
# review: new
agent-undo-not-arrived = zpráva (zatím) není ve složce, kam byla přesunuta
# review: new
agent-undo-sent = zpráva už byla odeslána
# review: new
agent-original-not-downloaded = původní zpráva ještě nebyla stažena. Nejdřív ji otevřete
# review: new
agent-turned-away = Odmítnuto
# review: new
agent-can-nothing = Nic
# review: new
agent-can-read = číst
# review: new
agent-can-organize = třídit
# review: new
agent-can-drafts = psát koncepty
# review: new
agent-can-send = odesílat s vaším souhlasem
# review: new
agent-can-list = { $first } a { $last }
# review: new
agent-accounts = { $count ->
    [0] žádné účty
    [one] 1 účet
    [few] { $count } účty
   *[other] { $count } účtů
}
# review: new
agent-access = { $can }; { $accounts }
# review: new
agent-unreadable = Tuto zprávu nelze přečíst.
# review: new
agent-encrypted-original = Tato zpráva je šifrovaná: agent na ni nemůže odpovědět ani ji přeposlat, protože neumí šifrovat.
# review: new
agent-encrypted = Tato zpráva je šifrovaná. Přečíst ji může jen uživatel, v aplikaci Inbox Classic.
# review: new
list-encrypted = Šifrovaná zpráva
# review: new
agent-log-composed = „{ $subject }“ otevřeno v nové zprávě, kterou dokončíte vy
# review: new
agent-log-refused = „{ $subject }“ jste neodeslali
# review: new
agent-log-sent = „{ $subject }“ odesláno příjemci { $to }
# review: new
agent-log-draft = Uložen koncept „{ $subject }“
# review: new
agent-log-read = Označeno jako přečtené: „{ $subject }“
# review: new
agent-log-unread = Označeno jako nepřečtené: „{ $subject }“
# review: new
agent-log-flagged = Označeno příznakem: „{ $subject }“
# review: new
agent-log-unflagged = Zrušen příznak: „{ $subject }“
# review: new
agent-log-deleted = Odstraněno: „{ $subject }“
# review: new
agent-log-moved = „{ $subject }“ přesunuto (cíl: { $folder })
# review: new
agent-log-junk = Označeno jako nevyžádané: „{ $subject }“
# review: new
agent-log-not-junk = Označeno jako vyžádané: „{ $subject }“
# review: new
agent-log-archived = Archivováno: „{ $subject }“
# review: new
agent-log-folder = Vytvořena složka „{ $name }“
# review: new
agent-log-unsubscribed = Odhlášeno z konference zprávy „{ $subject }“

## Keys

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
sign-in-no-refresh = poskytovatel neposkytl obnovovací token
# review: new
sign-in-no-account = poskytovatel neuvedl, který účet se přihlásil
# review: new
sign-in-not-finished = přihlašování nebylo dokončeno
# review: new
secrets-unavailable = { $store } není k dispozici
# review: new
secrets-unavailable-why = { $store } není k dispozici: { $error }
# review: new
secrets-windows = Správce pověření
# review: new
secrets-mac = Klíčenka
# review: new
secrets-linux = Systémová klíčenka (Secret Service)
# review: new
error-no-such-file = takový soubor neexistuje
# review: new
cards-file-too-big = Tento soubor je příliš velký na to, aby to byl adresář.
# review: new
ui-sender-added = Kontakt { $name } byl přidán do Adresáře.
# review: new
ui-sender-known = Kontakt { $name } už je v Adresáři.
# review: new
ui-sender-none = Odesílatel této zprávy nemá e-mailovou adresu, kterou by bylo možné přidat.
# review: new
card-name-needed = Kontakt nemá jméno ani e-mailovou adresu.
# review: new
cards-file-failed = { $file }: { $reason }

## One-time codes

# review: new
otp-heading = Kód od { $domain }
# review: new
otp-copy = Kopírovat
# review: new
otp-note = Zadejte ho jen na stránce domény { $domain }.
# review: new
otp-old = Tento kód byl odeslán více než hodinu předtím, než jste ho otevřeli, a pravděpodobně už vypršel.

# review: new
event-attendees =
    { $count ->
        [one] { $count } účastník
        [few] { $count } účastníci
       *[other] { $count } účastníků
    }

# review: new
otp-notification = { $code } je váš kód pro { $domain }

## OpenPGP keys (keys.rs)
# review: new
pgp-key-valid = Platný
# review: new
pgp-key-expires = Platný do { $date }
# review: new
pgp-key-expired = Platnost vypršela { $date }
# review: new
pgp-key-revoked = Odvolaný
# review: new
pgp-key-revoked-why = Odvolaný: { $reason }
# review: new
pgp-key-not-valid = Neplatný
# review: new
pgp-key-locked = Nelze použít: klíč, který ho chrání, už není v úložišti { $store }. Znovu importujte jeho zálohu.
# review: new
pgp-source-own = Vytvořen v aplikaci Inbox Classic
# review: new
pgp-source-file = Importován ze souboru
# review: new
pgp-source-paste = Vložen
# review: new
pgp-source-attachment = Ze zprávy
# review: new
pgp-source-vcard = Z vizitky kontaktu
# review: new
pgp-source-wkd = Od poskytovatele pošty odesílatele
# review: new
pgp-source-keyserver = Z keys.openpgp.org
# review: new
pgp-source-autocrypt = Z hlavičky Autocrypt zprávy
# review: new
pgp-error-no-store = Soukromé klíče chrání úložiště { $store }, které nelze použít: { $error }
# review: new
pgp-error-wrong-passphrase = Heslová fráze není správná.
# review: new
pgp-error-not-a-key = Toto není klíč OpenPGP.
# review: new
pgp-error-too-large = Klíč je příliš velký.
# review: new
pgp-error-unusable = Klíč používá starou nebo slabou kryptografii a nelze ho použít.
# review: new
pgp-imported-private = { $count ->
    [one] Váš soukromý klíč byl importován.
    [few] Byly importovány { $count } soukromé klíče.
   *[other] Bylo importováno { $count } soukromých klíčů.
}
# review: new
pgp-imported-public = { $count ->
    [one] Byl importován jeden klíč.
    [few] Byly importovány { $count } klíče.
   *[other] Bylo importováno { $count } klíčů.
}
# review: new
pgp-imported-pending = Pro { $addresses } se už používá jiný klíč: nový čeká v kontaktu, dokud ho nevyberete.
# review: new
pgp-error-needs-passphrase = Soukromý klíč je chráněn heslovou frází. Zadejte ji, abyste klíč mohli importovat.
# review: new
pgp-error-mismatch = Soukromý klíč nepatří ke svému veřejnému klíči. Mohl být pozměněn.
# review: new
pgp-file-name-public = { $who } veřejný klíč.asc
# review: new
pgp-file-name-private = { $who } záloha soukromého klíče.asc
# review: new
pgp-pending = Pro { $address } byl { $date } nalezen jiný klíč.

## Reading signed and encrypted mail (protect.rs)
# review: new
pgp-part-verified = Podpis: { $signer }, klíč ověřen
# review: new
pgp-part-signed = Podpis: { $signer } (klíč neověřen)
# review: new
pgp-part-other = Podpis: { $signer }, nejde o odesílatele
# review: new
pgp-part-unknown-key = Podepsáno, ale klíč není známý
# review: new
pgp-part-not-signed = Nepodepsáno
# review: new
pgp-part-not-checked = Podpis nebyl ověřen
# review: new
pgp-part-encrypted = Šifrováno. { $signature }
# review: new
pgp-part-no-key = Šifrováno pro klíč, který nemáte
# review: new
pgp-part-changed = Šifrovaná část byla cestou změněna a nezobrazuje se
# review: new
pgp-part-unprotected = Šifrováno bez ochrany proti změnám, nezobrazuje se
# review: new
pgp-part-broken = Šifrovanou část nelze přečíst
# review: new
pgp-why-mismatch = Podpis neodpovídá tomuto textu
# review: new
pgp-why-weak-hash = Podpis používá { $hash }, který už není bezpečný
# review: new
pgp-why-key-expired = Podepsáno po vypršení platnosti klíče { $date }
# review: new
pgp-why-key-revoked = Podepsáno klíčem, který byl odvolán
# review: new
pgp-why-not-signing-key = Podepsáno klíčem, který nesmí podepisovat
# review: new
pgp-why-from-future = Podpis je datován do budoucnosti
# review: new
pgp-why-signature-expired = Platnost podpisu vypršela
# review: new
pgp-why-key-not-valid = Podepsáno klíčem, který není platný
# review: new
pgp-why-not-for-you = Podepsáno pro jiné příjemce a předáno vám
# review: new
pgp-why-not-key-in-use = Podepsáno jiným klíčem, než jaký se používá pro { $address }
# review: new
pgp-part-pictures-loaded = { $label }. Obrázky byly načteny z internetu
# review: new
pgp-error-no-own-key = Pro { $address } nemáte klíč, kterým byste mohli podepisovat nebo šifrovat. Vytvořte si ho v nabídce Nástroje > Šifrovací klíče, nebo vypněte Podepsat a Šifrovat.
# review: new
pgp-error-missing-keys = { $count ->
    [one] { $addresses } nemá klíč, pro který by bylo možné šifrovat.
   *[other] Tito příjemci nemají klíč, pro který by bylo možné šifrovat: { $addresses }.
}
# review: new
pgp-error-encrypted-quote = Tato zpráva cituje nebo přeposílá šifrovanou zprávu, a lze ji proto odeslat jen šifrovaně. Zapněte Šifrovat, nebo odeberte citovaný text.
# review: new
pgp-error-protect = Zprávu nelze podepsat ani zašifrovat: { $reason }
# review: new
pgp-found-keys = Nalezen klíč pro { $addresses }.
# review: new
pgp-found-none = Pro { $addresses } nebyl nalezen žádný klíč. Požádejte o zaslání veřejného klíče.
# review: new
pgp-found-no-key = Nebyl nalezen žádný klíč.
# review: new
pgp-find-unavailable = Klíče teď nelze vyhledat: { $error }
# review: new
pgp-publish-pending = keys.openpgp.org poslal na { $addresses } odkaz k potvrzení. Po kliknutí na něj tam bude váš klíč zveřejněn.
# review: new
pgp-publish-done = Váš klíč je zveřejněn na keys.openpgp.org pro { $addresses }.
# review: new
pgp-publish-failed = Klíč nelze zveřejnit: { $error }
# review: changed
pgp-keyserver-off = Vyhledávání klíčů na keys.openpgp.org je vypnuté v { $settings }.
# the compose window with Sign and Encrypt: the line under the fields, each recipient's key, the questions
# review: new
pgp-compose-encrypted = { $count ->
    [one] Šifrováno a podepsáno: přečíst ji můžete jen vy a { $addresses }.
   *[other] Šifrováno a podepsáno: přečíst ji můžete jen vy a její příjemci ({ $count }).
}
# review: new
pgp-compose-encrypt-ready = Bude zašifrována a podepsána. Přidejte příjemce, jejichž klíče máte.
# review: new
pgp-compose-missing = { $count ->
    [one] { $addresses } nemá klíč, a zprávu proto zatím nelze zašifrovat.
   *[other] Příjemci bez klíče ({ $count }): { $addresses }. Zprávu proto zatím nelze zašifrovat.
}
# review: new
pgp-compose-looking = Hledají se klíče pro { $addresses }...
# review: new
pgp-compose-signed = Podepsáno: příjemci si mohou ověřit, že je od vás a nebyla změněna.
# review: new
pgp-compose-reply-clear = Nešifrováno, přestože zpráva, na kterou odpovídá nebo kterou přeposílá, šifrovaná byla.
# review: new
pgp-compose-encrypted-files = Jsou připojeny soubory šifrované zprávy, a tuto zprávu lze proto odeslat jen šifrovaně. Zapněte Šifrovat, nebo tyto soubory odeberte.
# review: new
pgp-compose-sign-tip = Podepsat zprávu vaším klíčem, aby si příjemci mohli ověřit, že je od vás a nebyla změněna
# review: new
pgp-compose-sign-tip-encrypted = Šifrovaná zpráva je vždy podepsaná
# review: new
pgp-compose-encrypt-tip = Zašifrovat zprávu, aby ji mohli přečíst jen vy a její příjemci
# review: new
pgp-compose-make-key = Pro { $address } zatím nemáte klíč. Vytvořit ho nyní? S ním lze vaše zprávy podepisovat a šifrovat.
# review: new
pgp-compose-key-unusable = Váš klíč pro { $address } nelze použít ({ $state }). Otevřete Šifrovací klíče a importujte jeho zálohu, nebo vytvořte nový klíč.
# review: new
pgp-compose-encrypt-off-quote = Tato zpráva cituje nebo přeposílá šifrovanou zprávu. Bez šifrování ji nelze odeslat, dokud citovaný obsah neodeberete. Přesto vypnout šifrování?
# review: new
pgp-compose-encrypt-off-reply = Tato zpráva odpovídá na šifrovanou zprávu nebo ji přeposílá. Bez šifrování si vaši zprávu může přečíst kdokoli, kdo s ní cestou pracuje. Vypnout šifrování?
# review: new
pgp-recipient-verified = Klíč ověřen
# review: new
pgp-recipient-found = Klíč neověřen
# review: new
pgp-recipient-own = Váš klíč
# review: new
pgp-recipient-looking = Hledá se klíč...
# review: new
pgp-recipient-missing = Žádný klíč
# review: new
pgp-recipient-not-found = Žádný klíč: { $date } nebyl žádný nalezen
# review: new
pgp-recipient-unusable = Klíč nelze použít: { $state }
# review: new
pgp-recipients-intro = Zpráva se šifruje pro klíč každého příjemce a pro váš.
# review: new
pgp-recipients-intro-missing = { $count ->
    [one] Jeden příjemce nemá klíč, pro který by bylo možné šifrovat. Najděte jeho klíč, odeberte ho z této zprávy, nebo ji odešlete bez šifrování.
    [few] { $count } příjemci nemají klíč, pro který by bylo možné šifrovat. Najděte jejich klíče, odeberte je z této zprávy, nebo ji odešlete bez šifrování.
   *[other] { $count } příjemců nemá klíč, pro který by bylo možné šifrovat. Najděte jejich klíče, odeberte je z této zprávy, nebo ji odešlete bez šifrování.
}
# review: new
pgp-details-part = Část { $number }: { $label }
# review: new
pgp-details-signed = Podepsáno { $when } klíčem { $key }
# review: new
pgp-details-unknown-key = Podepsáno klíčem { $key }, který nemáte
# review: new
pgp-details-opened = Šifrováno pro váš klíč { $key }
# review: new
pgp-details-for = Šifrováno pro { $keys }
# review: new
pgp-details-plain = Nepodepsáno a nešifrováno
# review: new
pgp-bar-parts = Tato zpráva má více částí ({ $count }): { $list }. U každé části je uvedeno, jak je chráněna.
# review: new
pgp-bar-count-verified = ověřené: { $count }
# review: new
pgp-bar-count-good = { $count ->
    [one] 1 podepsaná nebo šifrovaná
    [few] { $count } podepsané nebo šifrované
   *[other] { $count } podepsaných nebo šifrovaných
}
# review: new
pgp-bar-count-warning = { $count ->
    [one] 1 vyžaduje pozornost
    [few] { $count } vyžadují pozornost
   *[other] { $count } vyžaduje pozornost
}
# review: new
pgp-bar-count-neutral = bez potvrzeného podpisu: { $count }
# review: new
setup-part-settings = Nastavení
# review: new
setup-part-preferences = Předvolby oken
# review: new
setup-part-accounts = Účty
# review: new
setup-part-sign-in-apps = Přihlašovací aplikace
# review: new
setup-part-contacts = Kontakty a skupiny
# review: new
setup-part-keys = Šifrovací klíče
# review: new
setup-part-rules = Pravidla zpráv
# review: new
setup-part-trusted-senders = Důvěryhodní odesílatelé
# review: new
setup-holds-settings = { $count ->
    [one] 1 nastavení
   *[other] { $count } nastavení
}
# review: new
setup-holds-preferences = { $count ->
    [one] 1 předvolba
    [few] { $count } předvolby
   *[other] { $count } předvoleb
}
# review: new
setup-holds-accounts = { $count ->
    [one] 1 účet
    [few] { $count } účty
   *[other] { $count } účtů
}
# review: new
setup-holds-sign-in-apps = { $count ->
    [one] 1 přihlašovací aplikace
    [few] { $count } přihlašovací aplikace
   *[other] { $count } přihlašovacích aplikací
}
# review: new
setup-holds-built-in = Které vestavěné přihlašovací aplikace jsou zapnuté
# review: new
setup-holds-contacts = { $count ->
    [one] 1 kontakt
    [few] { $count } kontakty
   *[other] { $count } kontaktů
}
# review: new
setup-holds-groups = { $count ->
    [one] 1 skupina
    [few] { $count } skupiny
   *[other] { $count } skupin
}
# review: new
setup-holds-own-keys = { $count ->
    [one] 1 vlastní klíč
    [few] { $count } vlastní klíče
   *[other] { $count } vlastních klíčů
}
# review: new
setup-holds-contact-keys = { $count ->
    [one] 1 klíč kontaktu
    [few] { $count } klíče kontaktů
   *[other] { $count } klíčů kontaktů
}
# review: new
setup-holds-rules = { $count ->
    [one] 1 pravidlo
    [few] { $count } pravidla
   *[other] { $count } pravidel
}
# review: new
setup-holds-trusted-senders = { $count ->
    [one] 1 důvěryhodný odesílatel
    [few] { $count } důvěryhodní odesílatelé
   *[other] { $count } důvěryhodných odesílatelů
}
# review: new
setup-sign-in-password = Heslo
# review: new
setup-account-secret-password = Jeho heslo je v souboru.
# review: new
setup-account-secret-token = Jeho přihlášení je v souboru.
# review: new
setup-account-asks-password = Po importu se zeptá na heslo.
# review: new
setup-account-signs-in-again = Po importu se k němu znovu přihlásíte.
# review: new
setup-account-here = Tady už je nastaven, proto se přeskočí.
# review: new
setup-account-no-app = Přihlašuje se přes { $app }, která tady není nastavená. Importujte také přihlašovací aplikace.
# review: new
setup-invalid-address = „{ $address }“ není e-mailová adresa.
# review: new
setup-invalid-server = Server { $server } nemá použitelný název nebo port.
# review: new
setup-invalid-user = Nemá uživatelské jméno.
# review: new
setup-invalid-sign-in = Přihlašuje se způsobem, který Inbox Classic nezná.
# review: new
setup-error-empty = Soubor je prázdný.
# review: new
setup-error-too-large = Soubor je příliš velký na to, aby to bylo nastavení Inbox Classic.
# review: new
setup-error-not-setup = Tento soubor není nastavení Inbox Classic.
# review: new
setup-error-damaged = Soubor s nastavením je poškozený a nelze ho přečíst.
# review: new
setup-error-newer = Toto nastavení uložila novější verze Inbox Classic ({ $version }). Aktualizujte Inbox Classic a pak ho importujte znovu.
# review: new
setup-error-needs-passphrase = Toto nastavení je chráněno heslovou frází. Zadejte heslovou frázi, se kterou bylo uloženo.
# review: new
setup-error-wrong-passphrase = To není heslová fráze, se kterou bylo toto nastavení uloženo.
# review: new
setup-error-changed = Soubor s nastavením byl po uložení změněn nebo poškozen, a proto ho nelze importovat.
# review: new
setup-error-read = Soubor s nastavením nelze přečíst: { $error }
# review: new
setup-error-write = Nastavení nelze uložit: { $error }
# review: new
setup-error-no-parts = Zvolte alespoň jednu část.
# review: new
setup-left-out = { $count ->
    [one] 1 položku části { $part } nelze použít, proto je vynechána.
    [few] { $count } položky části { $part } nelze použít, proto jsou vynechány.
   *[other] { $count } položek části { $part } nelze použít, proto jsou vynechány.
}
# review: new
setup-imported-settings = Nastavení byla nahrazena.
# review: new
setup-imported-preferences = Předvolby oken byly nahrazeny.
# review: new
setup-added-accounts = { $count ->
    [one] Přidán 1 účet.
    [few] Přidány { $count } účty.
   *[other] Přidáno { $count } účtů.
}
# review: new
setup-skipped-here = { $address } už je tady nastaven, proto byl přeskočen.
# review: new
setup-skipped-no-app = { $address } byl přeskočen: přihlašuje se přes { $app }, která tady není nastavená.
# review: new
setup-skipped-invalid = { $address } byl přeskočen: { $reason }
# review: new
setup-asks-password = { $address } se při připojení zeptá na heslo.
# review: new
setup-signs-in-again = { $address } vás při připojení požádá o nové přihlášení.
# review: new
setup-added-sign-in-apps = { $count ->
    [one] Přidána 1 přihlašovací aplikace.
    [few] Přidány { $count } přihlašovací aplikace.
   *[other] Přidáno { $count } přihlašovacích aplikací.
}
# review: new
setup-skipped-sign-in-apps = { $count ->
    [one] 1 přihlašovací aplikace už je tady nastavená.
    [few] { $count } přihlašovací aplikace už jsou tady nastavené.
   *[other] { $count } přihlašovacích aplikací už je tady nastaveno.
}
# review: new
setup-added-contacts = { $count ->
    [one] Do adresáře byl přidán 1 kontakt.
    [few] Do adresáře byly přidány { $count } kontakty.
   *[other] Do adresáře bylo přidáno { $count } kontaktů.
}
# review: new
setup-skipped-contacts = { $count ->
    [one] 1 kontakt už v adresáři je.
    [few] { $count } kontakty už v adresáři jsou.
   *[other] { $count } kontaktů už v adresáři je.
}
# review: new
setup-added-groups = { $count ->
    [one] Přidána nebo doplněna 1 skupina.
    [few] Přidány nebo doplněny { $count } skupiny.
   *[other] Přidáno nebo doplněno { $count } skupin.
}
# review: new
setup-added-own-keys = { $count ->
    [one] Přidán 1 vlastní klíč.
    [few] Přidány { $count } vlastní klíče.
   *[other] Přidáno { $count } vlastních klíčů.
}
# review: new
setup-added-contact-keys = { $count ->
    [one] Přidán 1 klíč kontaktu.
    [few] Přidány { $count } klíče kontaktů.
   *[other] Přidáno { $count } klíčů kontaktů.
}
# review: new
setup-added-rules = { $count ->
    [one] Přidáno 1 pravidlo zpráv.
    [few] Přidána { $count } pravidla zpráv.
   *[other] Přidáno { $count } pravidel zpráv.
}
# review: new
setup-skipped-rules = { $count ->
    [one] 1 pravidlo zpráv už tady je.
    [few] { $count } pravidla zpráv už tady jsou.
   *[other] { $count } pravidel zpráv už tady je.
}
# review: new
setup-skipped-rules-account = { $count ->
    [one] 1 pravidlo zpráv patří k účtu, který tady není, proto bylo přeskočeno.
    [few] { $count } pravidla zpráv patří k účtům, které tady nejsou, proto byla přeskočena.
   *[other] { $count } pravidel zpráv patří k účtům, které tady nejsou, proto bylo přeskočeno.
}
# review: new
setup-rules-waiting = { $count ->
    [one] 1 pravidlo zpráv přesouvá zprávy do složky, která se objeví po synchronizaci jejího účtu.
    [few] { $count } pravidla zpráv přesouvají zprávy do složek, které se objeví po synchronizaci jejich účtů.
   *[other] { $count } pravidel zpráv přesouvá zprávy do složek, které se objeví po synchronizaci jejich účtů.
}
# review: new
setup-added-trusted-senders = { $count ->
    [one] Přidán 1 důvěryhodný odesílatel.
    [few] Přidáni { $count } důvěryhodní odesílatelé.
   *[other] Přidáno { $count } důvěryhodných odesílatelů.
}
# review: new
setup-nothing = Nic nebylo importováno.
# review: new
setup-account-servers = { $imap } a { $smtp } ({ $signin })
# review: new
setup-file-name = Inbox Classic nastavení a účty
# review: new
setup-skipped-unreachable = { $name } byl přeskočen: jeho přihlašovací služba není dostupná. Přidejte ho znovu v okně Přihlašovací aplikace.
# review: new
attachment-runs-programs = Soubor „{ $name }“ může spouštět programy, proto ho Inbox Classic neotevře. Uložte ho a otevřete ho sami, pokud důvěřujete jeho původu.
# review: new
attachment-decrypted-note = Tato příloha pochází ze šifrované zprávy. Aby ji Inbox Classic mohl otevřít, uloží ji dešifrovanou do tohoto počítače, do vaší složky, kterou Inbox Classic po jednom dni vyprázdní.
# a bar over the list when the server did not do what the user asked of messages, so they are as they were again
# review: new
undone-move = { $count ->
    [one] Server nepřesunul zprávu do složky { $folder }, takže { $messages } je zpět ve složce { $from }: { $reason }
    [few] Server nepřesunul zprávy do složky { $folder }, takže { $messages } jsou zpět ve složce { $from }: { $reason }
   *[other] Server nepřesunul zprávy do složky { $folder }, takže { $messages } je zpět ve složce { $from }: { $reason }
}
# review: new
undone-delete = { $count ->
    [one] Server neodstranil zprávu, takže { $messages } je zpět ve složce { $from }: { $reason }
    [few] Server neodstranil zprávy, takže { $messages } jsou zpět ve složce { $from }: { $reason }
   *[other] Server neodstranil zprávy, takže { $messages } je zpět ve složce { $from }: { $reason }
}
# review: new
undone-archive = { $count ->
    [one] Server nearchivoval zprávu, takže { $messages } je zpět ve složce { $from }: { $reason }
    [few] Server nearchivoval zprávy, takže { $messages } jsou zpět ve složce { $from }: { $reason }
   *[other] Server nearchivoval zprávy, takže { $messages } je zpět ve složce { $from }: { $reason }
}
# review: new
undone-read = { $count ->
    [one] Server neoznačil zprávu jako přečtenou, takže { $messages } je opět nepřečtená: { $reason }
    [few] Server neoznačil zprávy jako přečtené, takže { $messages } jsou opět nepřečtené: { $reason }
   *[other] Server neoznačil zprávy jako přečtené, takže { $messages } je opět nepřečteno: { $reason }
}
# review: new
undone-unread = { $count ->
    [one] Server neoznačil zprávu jako nepřečtenou, takže { $messages } je opět přečtená: { $reason }
    [few] Server neoznačil zprávy jako nepřečtené, takže { $messages } jsou opět přečtené: { $reason }
   *[other] Server neoznačil zprávy jako nepřečtené, takže { $messages } je opět přečteno: { $reason }
}
# review: new
undone-flags = { $count ->
    [one] Server nezměnil příznaky zprávy, takže { $messages } zůstává beze změny: { $reason }
    [few] Server nezměnil příznaky zpráv, takže { $messages } zůstávají beze změny: { $reason }
   *[other] Server nezměnil příznaky zpráv, takže { $messages } zůstává beze změny: { $reason }
}
