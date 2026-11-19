# Latviešu. Melnraksts, gaida dzimtās valodas runātāja pārskatīšanu (sk. core/locales/GLOSSARY.md).
# What the core says, the same on every platform. Placeables in { $braces } are filled in by the code; keep them, in
# the place the language puts them. Plurals choose by the number: [zero], [one] and *[other] in Latvian ([one] also
# covers 21, 31 and so on).

## Counts and sizes

messages = { $count ->
    [zero] { $count } ziņojumu
    [one] { $count } ziņojums
   *[other] { $count } ziņojumi
}
# the separator of decimals in sizes: 2,4 MB
# review: new
decimal-separator = ,
# review: new
size-bytes = { $count ->
    [zero] { $count } baitu
    [one] { $count } baits
   *[other] { $count } baiti
}
# review: new
size-kb = { $size } KB
# review: new
size-mb = { $size } MB
# review: new
size-gb = { $size } GB
# review: new
send-delay-off = Izslēgts
# review: new
send-delay-seconds = { $count ->
    [zero] { $count } sekunžu
    [one] { $count } sekunde
   *[other] { $count } sekundes
}
# the status bar: "12 ziņojumi, nelasīti: 3"
# review: new
list-counts = { $messages }, nelasīti: { $unread }
# review: new
list-counts-selected = { $messages }, nelasīti: { $unread }, atlasīti: { $selected }
# the status bar while searching: "Atrasti: 12, nelasīti: 3"
# review: new
list-counts-found = Atrasti: { $found }, nelasīti: { $unread }
# review: new
list-counts-found-selected = Atrasti: { $found }, nelasīti: { $unread }, atlasīti: { $selected }
# review: new
list-counts-none = Neviens ziņojums nav atrasts

## Special folders, as Outlook names them

# review: new
folder-inbox = Iesūtne
# review: new
folder-sent = Nosūtītie vienumi
# review: new
folder-deleted = Izdzēstie vienumi
# review: new
folder-drafts = Melnraksti
# review: new
folder-junk = Nevēlamais e-pasts
# review: new
folder-archive = Arhīvs

## The reading pane

# review: new
reader-no-message = Nav atlasīts neviens ziņojums.
# review: new
reader-downloading = Notiek ziņojuma lejupielāde…
# review: new
reader-downloading-detail = Ziņojums tiks parādīts šeit, kad lejupielāde būs pabeigta.
# review: new
reader-downloading-size = Ziņojuma lielums ir { $size }. Tas tiks parādīts šeit, kad būs lejupielādēts.
# review: new
reader-failed = Ziņojumu nevarēja lejupielādēt
# review: new
reader-failed-network = Nevarēja sazināties ar pasta serveri ({ $reason }).
# review: new
reader-failed-sign-in = Pasta serveris nepieņēma pierakstīšanos ({ $reason }). Pārbaudiet paroli vai pierakstieties vēlreiz sadaļā Fails > Konti.
# review: new
reader-failed-security = Savienojumu ar pasta serveri nevarēja padarīt drošu ({ $reason }).
# review: new
reader-failed-other = Pasta serveris atbildēja: { $reason }.
# review: new
reader-retry-note = Tiks mēģināts vēlreiz, kad konts atkal izveidos savienojumu.
# review: new
reader-unreadable = Šo ziņojumu nevar parādīt: { $error }
# review: new
message-source-title = Ziņojuma pirmkods: { $subject }
# review: new
message-source-untitled = Ziņojuma pirmkods

## Printing a message, and the header of a message quoted in a reply or forward

# review: new
header-from = No
# review: new
header-date = Datums
# review: new
header-to = Kam
# review: new
header-cc = Kopija
# review: new
header-sent = Nosūtīts
# review: new
header-subject = Tēma
# review: new
header-security = Drošība
# review: new
header-part = { $number }. daļa
# review: new
quote-original = ----- Sākotnējais ziņojums -----
# review: new
fold-show-earlier = Rādīt iepriekšējos ziņojumus

## Bounces: the card at the top of a notice that a message was not delivered

# review: new
bounce-failed = Jūsu ziņojums netika piegādāts
# review: new
bounce-delayed = Jūsu ziņojums vēl nav piegādāts
# review: new
bounce-delayed-note = Jūsu pasta serveris joprojām mēģina to piegādāt. Nav jāsūta vēlreiz.
# the link to the message the notice is about, in Sent Items or another folder
# review: new
bounce-show-message = Rādīt ziņojumu, kas netika piegādāts
# the link of a delay's card to the message that is still on its way
# review: new
bounce-show-delayed = Rādīt aizkavēto ziņojumu
# review: new
bounce-what-to-do = Ko varat darīt:
# what to do about a recipient the message is still on its way to: in the card of a delay, and in the card of a failure
# review: new
bounce-delayed-do = Pagaidām neko. Ja to joprojām nevarēs piegādāt, saņemsiet vēl vienu paziņojumu.
# review: new
bounce-delayed-row-do = Pagaidām neko. Jūsu pasta serveris joprojām mēģina to piegādāt, un, ja tas neizdosies, saņemsiet vēl vienu paziņojumu.
# folds the receiving server's own words
# review: new
bounce-details = Detaļas
# a recipient the notice does not name
# review: new
bounce-someone = Kāds adresāts
# in Details: the server that refused the message, the status code it gave, and the server that wrote the notice
# review: new
bounce-server = Serveris: { $server }
# review: new
bounce-status = Statuss: { $status }
# review: new
bounce-reported-by = Ziņoja: { $server }
# review: new
bounce-retry-minutes = Saņēmēja serveris lūdza pirms nākamā mēģinājuma pagaidīt { $count ->
    [1] minūti
    [one] { $count } minūti
   *[other] { $count } minūtes
}.
# review: new
bounce-retry-hours = Saņēmēja serveris lūdza pirms nākamā mēģinājuma pagaidīt { $count ->
    [1] stundu
    [one] { $count } stundu
   *[other] { $count } stundas
}.
# the names of the blocklists, "Spamhaus ZEN, Barracuda"
# review: new
bounce-blocklist = Bloķēšanas saraksts: { $lists }
# review: new
bounce-user-unknown = Šāda adrese nepastāv
# review: new
bounce-user-unknown-why = Saņēmēja serverī nav pastkastes ar šo adresi. Iespējams, tā ir uzrakstīta kļūdaini vai cilvēks to vairs neizmanto.
# review: new
bounce-user-unknown-do = Pārbaudiet, vai adrese uzrakstīta pareizi, vai pajautājiet cilvēkam, kuru adresi viņš izmanto tagad.
# review: new
bounce-invalid-address = Adrese nav derīga
# review: new
bounce-invalid-address-why = Adrese nav uzrakstīta tādā formā, uz kuru var nosūtīt pastu.
# review: new
bounce-invalid-address-do = Meklējiet drukas kļūdas, piemēram, atstarpi, trūkstošu burtu vai tukšumu aiz @.
# review: new
bounce-mailbox-disabled = Pastkaste ir slēgta
# review: new
bounce-mailbox-disabled-why = Adrese pastāv, bet tās pastkaste ir izslēgta vai vairs netiek izmantota.
# review: new
bounce-mailbox-disabled-do = Sazinieties ar cilvēku citādi un pajautājiet adresi, kuru viņš izmanto tagad.
# review: new
bounce-mailbox-full = Pastkaste ir pilna
# review: new
bounce-mailbox-full-why = Adresāta pastkastē nav vietas jaunam pastam.
# review: new
bounce-mailbox-full-do = Nosūtiet to vēlreiz pēc dažām dienām vai paziņojiet cilvēkam citādi. Vispirms tiek atteikti lieli pielikumi.
# review: new
bounce-spam-blocked = Atteikts kā mēstule
# review: new
bounce-spam-blocked-why = Saņēmēja serveris uzskatīja ziņojumu par mēstuli.
# review: new
bounce-spam-blocked-do = Nosūtiet to vēlreiz bez tā, kas izskatās pēc mēstules, piemēram, bez daudzām saitēm, saīsinātām saitēm vai liela pielikuma. Ja tas atkārtojas, vērsieties pie sava pasta pakalpojumu sniedzēja.
# review: new
bounce-virus-detected = Atteikts vīrusa dēļ
# review: new
bounce-virus-detected-why = Saņēmēja serveris ziņojumā vai tā pielikumos atrada vīrusu vai citu kaitīgu saturu.
# review: new
bounce-virus-detected-do = Pārbaudiet pielikumus ar pretvīrusu programmu. Daži serveri atsaka jebkuru programmu vai arhīvu, tāpēc kopīgojiet šādus failus kā saiti.
# review: new
bounce-ip-blocklisted = Jūsu pasta serveris ir bloķēšanas sarakstā
# review: new
bounce-ip-blocklisted-why = Saņēmēja serveris atsaka pastu no servera, kas nosūtīja jūsējo, jo šī servera adrese ir bloķēšanas sarakstā.
# review: new
bounce-ip-blocklisted-do = Problēma nav ziņojumā. Pārsūtiet šo paziņojumu savam pasta pakalpojumu sniedzējam un lūdziet, lai serveri izņem no saraksta.
# review: new
bounce-domain-blocklisted = Domēns ir bloķēšanas sarakstā
# review: new
bounce-domain-blocklisted-why = Saņēmēja serveris atsaka ziņojumu, jo jūsu adreses domēns vai kāds domēns ziņojuma saitēs ir bloķēšanas sarakstā.
# review: new
bounce-domain-blocklisted-do = Ja ziņojumā ir saites, mēģiniet bez tām. Pretējā gadījumā pārsūtiet šo paziņojumu tam, kurš pārvalda jūsu domēna pastu.
# review: new
bounce-policy-blocked = Atteikts saskaņā ar saņēmēja servera noteikumiem
# review: new
bounce-policy-blocked-why = Saņēmēja servera noteikumi nelaiž cauri šo ziņojumu, piemēram, tā lieluma, pielikumu vai sūtītāja dēļ.
# review: new
bounce-policy-blocked-do = Servera paša vārdi sadaļā Detaļas bieži norāda iemeslu. Pajautājiet adresātam, vai viņš var pieņemt šādu pastu.
# review: new
bounce-geo-blocked = Atteikts izcelsmes vietas dēļ
# review: new
bounce-geo-blocked-why = Saņēmēja serveris nepieņem pastu no valsts vai tīkla, kurā atrodas jūsu pasta serveris.
# review: new
bounce-geo-blocked-do = Sazinieties ar cilvēku citādi vai jautājiet par to savam pasta pakalpojumu sniedzējam.
# review: new
bounce-relay-denied = Serveris to nepārsūtīja tālāk
# review: new
bounce-relay-denied-why = Kāds serveris atteicās piegādāt ziņojumu tālāk, bieži tāpēc, ka tas tika nosūtīts bez pierakstīšanās vai caur serveri, kas šo adresātu neapkalpo.
# review: new
bounce-relay-denied-do = Pārbaudiet konta izejošā pasta serveri sadaļā Fails > Konti un to, vai tas pierakstās.
# review: new
bounce-auth-failure = Jūsu sūtītāja adresi nevarēja pārbaudīt
# review: new
bounce-auth-failure-why = Saņēmēja serveris nevarēja apstiprināt, ka ziņojums tiešām nāk no jūsu domēna (SPF, DKIM vai DMARC).
# review: new
bounce-auth-failure-do = Pārsūtiet šo paziņojumu tam, kurš pārvalda jūsu domēna pastu: tā iestatījumi jālabo. Pa to laiku var palīdzēt sūtīšana caur jūsu pakalpojumu sniedzēja serveri.
# review: new
bounce-rate-limited = Pārāk daudz pasta vienlaikus
# review: new
bounce-rate-limited-why = Saņēmēja serveris pagaidām pieņem mazāk ziņojumu no jūsu pasta servera.
# review: new
bounce-rate-limited-do = Pagaidiet kādu laiku un nosūtiet to vēlreiz. Rakstot daudziem cilvēkiem, sūtiet mazākam skaitam vienlaikus.
# review: new
bounce-greylisting = Uz brīdi aizturēts
# review: new
bounce-greylisting-why = Saņēmēja serveris lūdz nezināmiem sūtītājiem mēģināt vēlreiz nedaudz vēlāk; tā ir izplatīta pārbaude pret mēstulēm.
# review: new
bounce-greylisting-do = Neko. Pasta serveri mēģina vēlreiz paši, un ziņojums parasti tiek piegādāts stundas laikā.
# review: new
bounce-server-error = Saņēmēja serverim radās problēma
# review: new
bounce-server-error-why = Ar saņēmēja serveri nevarēja sazināties, vai tas nevarēja pieņemt ziņojumu savas problēmas dēļ.
# review: new
bounce-server-error-do = Nosūtiet to vēlreiz vēlāk. Ja tas joprojām neizdodas, pārbaudiet, vai adreses daļā aiz @ nav drukas kļūdu.
# review: new
bounce-unknown = Nav piegādāts
# review: new
bounce-unknown-why = Paziņojumā nav skaidri pateikts, kāpēc.
# review: new
bounce-unknown-do = Servera paša vārdi sadaļā Detaļas var pastāstīt vairāk. Ja tie nepalīdz, pārsūtiet šo paziņojumu savam pasta pakalpojumu sniedzējam.

## Several messages selected

# review: new
selection-title = { $count ->
    [zero] Atlasīti { $count } ziņojumi
    [one] Atlasīts { $count } ziņojums
   *[other] Atlasīti { $count } ziņojumi
}
# review: new
selection-unread = Nelasīti: { $count }
# review: new
selection-flagged = Ar karodziņu: { $count }
# review: new
delete-for-good-one = Šis ziņojums tiks neatgriezeniski izdzēsts. Vai dzēst to?
# review: new
delete-for-good-all = Šie ziņojumi ({ $count }) tiks neatgriezeniski izdzēsti. Vai dzēst tos?
# review: new
delete-for-good-some = { $count } no { $total } ziņojumiem tiks neatgriezeniski izdzēsti. Vai dzēst ziņojumus?
# review: new
done-read = { $count ->
    [one] { $messages } atzīmēts kā lasīts
   *[other] { $messages } atzīmēti kā lasīti
}
# review: new
done-unread = { $count ->
    [one] { $messages } atzīmēts kā nelasīts
   *[other] { $messages } atzīmēti kā nelasīti
}
# review: new
done-flagged = { $count ->
    [one] { $messages } atzīmēts ar karodziņu
   *[other] { $messages } atzīmēti ar karodziņu
}
# review: new
done-unflagged = Karodziņš noņemts: { $messages }
# review: new
done-deleted-for-good = { $count ->
    [one] { $messages } neatgriezeniski izdzēsts
   *[other] { $messages } neatgriezeniski izdzēsti
}
# review: new
done-archived = { $count ->
    [one] { $messages } arhivēts
   *[other] { $messages } arhivēti
}
# review: new
done-moved = { $count ->
    [one] { $messages } pārvietots uz { $folder }
   *[other] { $messages } pārvietoti uz { $folder }
}
# review: new
done-copied = { $count ->
    [one] { $messages } nokopēts uz { $folder }
   *[other] { $messages } nokopēti uz { $folder }
}
# review: new
done-moving = { $count ->
   *[other] Pārvieto { $messages } uz { $folder }...
}
# review: new
done-copying = { $count ->
   *[other] Kopē { $messages } uz { $folder }...
}
# review: new
done-moved-back = { $count ->
    [one] { $messages } pārvietots atpakaļ uz { $folder }
   *[other] { $messages } pārvietoti atpakaļ uz { $folder }
}
# the status bar after Watch Conversation and Ignore Conversation, and after either again on a marked one
# review: new
done-watched = { $count ->
    [1] Saruna tiek vērota
    [one] { $count } saruna tiek vērota
   *[other] Tiek vērotas { $count } sarunas
}
# review: new
done-unwatched = { $count ->
    [1] Saruna vairs netiek vērota
    [one] { $count } saruna vairs netiek vērota
   *[other] { $count } sarunas vairs netiek vērotas
}
# review: new
done-ignored = { $count ->
    [1] Saruna tiek ignorēta
    [one] { $count } saruna tiek ignorēta
   *[other] Tiek ignorētas { $count } sarunas
}
# review: new
done-unignored = { $count ->
    [1] Saruna vairs netiek ignorēta
    [one] { $count } saruna vairs netiek ignorēta
   *[other] { $count } sarunas vairs netiek ignorētas
}
# after "uz" (to): the dative plural, "uz to mapēm"
# review: new
their-folders = to mapēm
# review: new
undo-move = Atsaukt pārvietošanu
# review: new
undo-delete = Atsaukt dzēšanu
# review: new
undo-archive = Atsaukt arhivēšanu
# review: new
undo-junk = Atsaukt atzīmēšanu kā nevēlamu
# review: new
undo-not-junk = Atsaukt atzīmēšanu kā vēlamu
# review: new
undo-send = Atsaukt sūtīšanu
# review: new
nothing-to-undo = Nav ko atsaukt.
# review: new
messages-gone = Ziņojumu tur vairs nav.
# A non-selectable IMAP folder cannot contain messages; this does not mean it is empty.
# review: new
folder-holds-no-messages = Šajā mapē nevar glabāt ziņojumus.
# review: new
not-archived-here = Šajā mapē esošos ziņojumus nevar arhivēt.
# review: new
not-emptied-here = Iztukšot var tikai mapes Izdzēstie vienumi un Nevēlamais e-pasts.
# review: new
next-unread-question = Mapē { $folder } vairs nav nelasītu ziņojumu.

    Vai pāriet uz { $next }, nākamo mapi ar nelasītiem ziņojumiem?
# review: new
no-unread-left = Nelasītu ziņojumu vairs nav.
# review: new
empty-question = { $count ->
    [1] Vai iztukšot mapi { $folder }?

        Tajā esošais ziņojums tiks neatgriezeniski izdzēsts. To nevarēs atjaunot.
    [one] Vai iztukšot mapi { $folder }?

        Tajā esošais { $messages } tiks neatgriezeniski izdzēsts. To nevarēs atjaunot.
   *[other] Vai iztukšot mapi { $folder }?

        Tajā esošie { $messages } tiks neatgriezeniski izdzēsti. Tos nevarēs atjaunot.
}
# review: new
no-junk-folder = Šim kontam nav mapes Nevēlamais e-pasts, uz kuru pārvietot ziņojumus.
# review: new
no-inbox-folder = Šim kontam nav mapes Iesūtne, uz kuru pārvietot ziņojumus.
# the status bar after a flag in a colour: "2 ziņojumi: uzlikts zils karodziņš"
# review: new
done-flagged-color = { $messages }: uzlikts { $color ->
    [red] sarkans
    [orange] oranžs
    [yellow] dzeltens
    [green] zaļš
    [blue] zils
    [purple] violets
   *[gray] pelēks
} karodziņš
# the Flag menu: the colours of Apple Mail's flags
# review: new
flag-color = { $color ->
    [red] Sarkans
    [orange] Oranžs
    [yellow] Dzeltens
    [green] Zaļš
    [blue] Zils
    [purple] Violets
   *[gray] Pelēks
}

## The Move and Copy window

# review: new
move-window-title-move = { $count ->
    [1] Pārvietot ziņojumu
    [one] Pārvietot { $count } ziņojumu
   *[other] Pārvietot { $count } ziņojumus
}
# review: new
move-window-title-copy = { $count ->
    [1] Kopēt ziņojumu
    [one] Kopēt { $count } ziņojumu
   *[other] Kopēt { $count } ziņojumus
}
# review: new
move-window-prompt-move = { $count ->
    [1] Pārvietot atlasīto ziņojumu uz:
    [one] Pārvietot { $count } atlasīto ziņojumu uz:
   *[other] Pārvietot { $count } atlasītos ziņojumus uz:
}
# review: new
move-window-prompt-copy = { $count ->
    [1] Kopēt atlasīto ziņojumu uz:
    [one] Kopēt { $count } atlasīto ziņojumu uz:
   *[other] Kopēt { $count } atlasītos ziņojumus uz:
}
# the folders used last, over the folder tree
# review: new
targets-recent = Nesen izmantotās
# the folder the messages are in, which can not be chosen
# review: new
target-current = { $folder } (pašreizējā)
# a folder used last, with its account when there are several: "Arhīvs (Darbs)"
# review: new
target-recent = { $folder } ({ $account })

## Moving and copying to another account

# review: new
transfer-moving = Pārvieto { $done } no { $messages } uz { $folder }...
# review: new
transfer-copying = Kopē { $done } no { $messages } uz { $folder }...
# after "uz" (to): the accusative, "uz citu kontu"
# review: new
transfer-another-account = citu kontu
# review: new
transfer-folder-gone = mapes, uz kuru tas tika sūtīts, vairs nav
# review: new
transfer-not-on-server = ziņojuma serverī vairs nav
# review: new
transfer-not-moved = { $count ->
    [one] { $messages } nevarēja pārvietot uz citu kontu: { $reason }
   *[other] { $messages } nevarēja pārvietot uz citu kontu: { $reason }
}
# review: new
transfer-not-copied = { $count ->
    [one] { $messages } nevarēja nokopēt uz citu kontu: { $reason }
   *[other] { $messages } nevarēja nokopēt uz citu kontu: { $reason }
}
# review: new
transfer-none-moved = Nevienu ziņojumu nevarēja pārvietot
# review: new
transfer-none-copied = Nevienu ziņojumu nevarēja nokopēt

## Messages as files

# review: new
export-not-in-time = ziņojumu nevarēja lejupielādēt laikā
# review: new
export-not-saved = { $failed } no { $messages } nevarēja saglabāt ({ $problems })
# review: new
export-not-attached = ziņojumus nevarēja pievienot: { $error }
# the status bar after Save As with several: "3 ziņojumi saglabāti mapē Darbvirsma"
# review: new
saved-to = { $count ->
    [one] { $messages } saglabāts mapē { $folder }
   *[other] { $messages } saglabāti mapē { $folder }
}
# review: new
download-progress = Lejupielādē { $done } no { $total }
# review: new
download-done = Lejupielādēts: { $size }
# review: new
downloading-messages = { $count ->
   *[other] Lejupielādē { $messages }...
}
# the status bar after files are dropped on a folder: "3 ziņojumi ievietoti mapē Arhīvs"
# review: new
import-put = { $count ->
    [one] { $messages } ievietots mapē { $folder }
   *[other] { $messages } ievietoti mapē { $folder }
}
# review: new
import-not-put = Šie netika ievietoti mapē:

    { $problems }

## Problems the windows show

# review: new
error-store = lokālā krātuve: { $error }
# review: new
error-not-found = nav atrasts
# review: new
error-closed = notiek izslēgšana
# review: new
error-other-account = pārlūkprogramma pierakstījās kontā { $email }, nevis šajā kontā
# a password or sign-in the mail server refused, with the server's words
# review: new
failure-authentication = serveris nepieņēma pierakstīšanos ({ $reason })
# the mail server could not be reached or the connection broke, with the reason
# review: new
failure-network = savienojums ar serveri neizdevās ({ $reason })
# review: new
error-in-use = to nevar noņemt, kamēr ar to pierakstās konti: { $accounts }
# review: new
error-turned-off = šī pierakstīšanās lietotne jauniem kontiem ir izslēgta
# review: new
error-folder-name = mapes nosaukumam jābūt no 1 līdz 200 rakstzīmēm garam, un tajā nedrīkst būt vadības rakstzīmes
# review: new
error-folder-separator = šajā serverī mapes nosaukumā nedrīkst būt „{ $separator }”
# review: new
error-folder-special = Iesūtni un īpašās mapes nevar pārdēvēt vai izdzēst
# review: new
error-no-recipients = ziņojumam nav adresātu
# review: new
error-bad-address = „{ $address }” nav e-pasta adrese
# review: new
error-not-own-address = { $address } nav neviena no šī konta sūtītāja adresēm. Pievienojiet to laukā „Citas adreses, no kurām sūtāt” konta rekvizītos.
# review: new
rule-query-refused = Kārtulas nevar filtrēt pēc mapes vai datuma ({ $words }).
# review: new
rule-no-query = Ievadiet ienākošo ziņojumu meklēšanas kritērijus.
# review: new
rule-no-action = Izvēlieties kārtulai vismaz vienu darbību.
# review: new
error-attachment = { $path } nevarēja nolasīt: { $error }
# review: new
error-no-drafts = kontam nav mapes Melnraksti, kurā saglabāt ziņojumu
# review: new
error-draft-attachment = melnraksta pielikumu nevarēja saglabāt: { $error }
# review: new
error-password-not-saved = paroli nevarēja saglabāt nākamajai palaišanai: { $error }
# review: new
error-sign-in-not-saved = jaunos pierakstīšanās datus nevarēja saglabāt nākamajai palaišanai: { $error }
# review: new
error-import-unreadable = { $path } nevar nolasīt: { $error }
# review: new
error-import-too-large = { $path } ir lielāks par 50 MB
# review: new
error-import-not-mail = { $path } nav e-pasta ziņojums
# review: new
error-list-answered = adresātu saraksta serveris atgrieza statusu { $status }
# review: new
error-not-built = ziņojumu nevarēja izveidot
# review: new
error-outbox-waits = { $count ->
    [1] ziņojums gaida mapē Izsūtne un tiks nosūtīts ar nākamo sūtīšanu/saņemšanu
    [one] { $count } ziņojums gaida mapē Izsūtne un tiks nosūtīts ar nākamo sūtīšanu/saņemšanu
   *[other] { $count } ziņojumi gaida mapē Izsūtne un tiks nosūtīti ar nākamo sūtīšanu/saņemšanu
}
# review: new
error-draft-not-removed = iepriekšējo ziņojuma melnrakstu nevarēja noņemt no mapes Melnraksti: { $reason }
# review: new
error-sent-but = ziņojums tika nosūtīts, bet { $problem }
# review: new
error-sent-still-in-outbox = tas joprojām ir mapē Izsūtne: { $error }
# review: new
error-sent-no-copy = kopiju nevarēja saglabāt mapē Nosūtītie vienumi: { $reason }
# review: new
error-no-password = šim kontam nav paroles
# review: new
error-no-sign-in = šim kontam nav pierakstīšanās datu
# review: new
error-provider-missing = šī versija nevar pierakstīties pakalpojumā { $provider }: vai tā pierakstīšanās lietotne ir noņemta?
# review: new
error-provider-servers = šī konta serveri neatbilst tā pierakstīšanās lietotnes serveriem
# review: new
error-app-scopes = { $reason }. Pasta serveris nepieņēma pierakstīšanās lietotnes marķieri: pārbaudiet, vai lietotnes atļaujas (scopes) dod piekļuvi pastam
# review: new
error-in-folder = { $folder }: { $reason }

## Sign-in apps

# review: new
sign-in-off-google = Google vēl nav pārbaudījis Inbox Classic, tāpēc ļauj ar to pierakstīties tikai testa lietotājiem. Izmantojiet savu Google pierakstīšanās lietotni vai lietotnes paroli, vai arī ieslēdziet to sadaļā Pierakstīšanās lietotnes (Fails > Konti), ja esat testa lietotājs.
# review: new
sign-in-off-other = Tā tika izslēgta sadaļā Pierakstīšanās lietotnes (Fails > Konti), kur to var atkal ieslēgt.
# review: new
sign-in-app-no-name = pierakstīšanās lietotnei vajag nosaukumu
# review: new
sign-in-app-no-client = trūkst klienta ID
# review: new
sign-in-app-no-scopes = pierakstīšanās lietotnei vajag atļaujas (scopes), kas dod piekļuvi pastam
# review: new
sign-in-app-bad-host = { $server } servera adrese trūkst vai nav derīgs resursdatora nosaukums
# review: new
sign-in-app-plain = { $server } serverim jāizmanto SSL/TLS vai STARTTLS
# review: new
sign-in-app-not-checked = izdevējs vēl nav pārbaudīts
# review: new
sign-in-app-issuer-changed = izdevējs ir mainījies: ierakstiet klienta noslēpumu vēlreiz vai noņemiet to
# review: new
sign-in-register-google = Google Cloud Console izveidojiet OAuth klientu ar tipu Desktop app un piekrišanas ekrānā norādiet atļauju (scope) https://mail.google.com/. Kamēr lietotne ir testēšanas režīmā, pierakstīties var tikai tās testa lietotāji.
# review: new
sign-in-register-microsoft = Microsoft Entra reģistrējiet lietotni ar platformu Mobile and desktop applications, novirzīšanas URI http://localhost, atļautām publiskā klienta plūsmām un deleģētajām atļaujām IMAP.AccessAsUser.All, SMTP.Send un offline_access. Tikai savai organizācijai kā izdevēju izmantojiet https://login.microsoftonline.com/<tenant ID>/v2.0.
# review: new
sign-in-register-other = Reģistrējiet vietējo (publisko) klientu ar tālāk norādīto novirzīšanas URI; pakalpojumu sniedzējam tajā jāatļauj jebkurš ports (RFC 8252). Pievienojiet atļauju (scope), ar kuru pakalpojumu sniedzējs dod piekļuvi pastam.

## Calendar invitations

# review: new
repeats = Atkārtojas
# review: new
repeats-every = { $unit ->
    [day] { $interval ->
        [1] Katru dienu
        [one] Ik pēc { $interval } dienas
       *[other] Ik pēc { $interval } dienām
    }
    [week] { $interval ->
        [1] Katru nedēļu
        [one] Ik pēc { $interval } nedēļas
       *[other] Ik pēc { $interval } nedēļām
    }
    [month] { $interval ->
        [1] Katru mēnesi
        [one] Ik pēc { $interval } mēneša
       *[other] Ik pēc { $interval } mēnešiem
    }
   *[year] { $interval ->
        [1] Katru gadu
        [one] Ik pēc { $interval } gada
       *[other] Ik pēc { $interval } gadiem
    }
}
# "Katru nedēļu: pirmdiena, trešdiena"
# review: new
repeats-on = { $repeats }: { $days }
# "Katru nedēļu, 10 reizes"
# review: new
repeats-times = { $count ->
    [1] { $repeats }, vienu reizi
    [one] { $repeats }, { $count } reizi
   *[other] { $repeats }, { $count } reizes
}
# review: new
day-monday = pirmdiena
# review: new
day-tuesday = otrdiena
# review: new
day-wednesday = trešdiena
# review: new
day-thursday = ceturtdiena
# review: new
day-friday = piektdiena
# review: new
day-saturday = sestdiena
# review: new
day-sunday = svētdiena

## AI agents

agent-level-read = Lasīt pastu: skatīt mapes, ziņojumus un sarunas, meklēt ziņojumus un kontaktus, kā arī skatīt ziņojumu kārtulas
# review: changed
agent-level-organize = Kārtot pastu: atzīmēt ziņojumus kā lasītus vai nelasītus, mainīt karodziņus, to krāsas un nevēlamā pasta atzīmes, pārvietot un arhivēt ziņojumus, veidot un pārdēvēt mapes, sekot sarunām un ignorēt tās, dzēst ziņojumus, pārvietojot tos uz mapi „Izdzēstie vienumi”, un ar jūsu piekrišanu atteikties no adresātu sarakstu abonēšanas
agent-level-drafts = Rakstīt melnrakstus, kurus varat nosūtīt
agent-level-send = Sūtīt pastu, katru ziņojumu tikai pēc jūsu piekrišanas
agent-connect-title = { $program } vēlas izmantot jūsu pastu
agent-connect-detail = MI aģents lūdz piekļuvi jūsu pastam lietotnē Inbox Classic. Izvēlieties, ko tas drīkst darīt un kuriem kontiem piekļūt. Šīs atļaujas vēlāk varat mainīt sadaļā „Rīki > MI aģenti”.

    Aģenti lasa citu cilvēku rakstītus ziņojumus, kuros var būt mēģinājumi tos apmānīt. Pirms katra ziņojuma nosūtīšanas ar Inbox Classic aģentam jāsaņem jūsu piekrišana.
agent-reply-to = Atbilde uz ziņojumu „{ $subject }”
agent-reply-all-on = Atbilde visiem uz ziņojumu „{ $subject }”
agent-forward-of = Ziņojuma „{ $subject }” pārsūtīšana
agent-never-written-one = Uz adresi { $address } vēl neesat rakstījuši.
agent-never-written-many = Uz { $count } no šīm adresēm vēl neesat rakstījuši.
agent-send-title = { $program } vēlas nosūtīt šo ziņojumu
agent-send-detail = Pārbaudiet adresātus un ziņojuma saturu. Pēc jūsu apstiprinājuma ziņojums vismaz { $seconds } s gaidīs mapē „Izsūtne”. Šajā laikā varat to izdzēst, lai atceltu nosūtīšanu.
agent-change-title = Ko { $program } drīkst darīt
agent-change-allowed = Mainiet, ko šīs programmas MI aģenti drīkst darīt ar jūsu pastu.
agent-change-refused = Šai programmai piekļuve ir liegta. Varat to atļaut, lai programmas aģenti varētu izmantot jūsu pastu.
agent-log-taken-back = { $entry } (darbība atsaukta)
agent-files = Faili: { $files }
agent-undo-refused = Šo darbību nevar atsaukt.
agent-undo-refused-why = Šo darbību nevar atsaukt: { $reason }.
agent-undo-impossible = to nevar atsaukt
agent-undo-not-in-folder = ziņojuma šajā mapē vairs nav
agent-undo-not-arrived = ziņojums vēl nav atrasts galamērķa mapē
agent-undo-sent = ziņojuma mapē „Izsūtne” vairs nav
agent-original-not-downloaded = sākotnējais ziņojums vēl nav lejupielādēts. Vispirms atveriet to
agent-turned-away = Piekļuve liegta
agent-can-nothing = Neko
agent-can-read = lasīt
agent-can-organize = kārtot
agent-can-drafts = rakstīt melnrakstus
agent-can-send = sūtīt ar jūsu piekrišanu
# "Lasīt, kārtot un rakstīt melnrakstus"
agent-can-list = { $first } un { $last }
agent-accounts = { $count ->
    [0] neviens konts
    [zero] { $count } kontu
    [one] { $count } konts
   *[other] { $count } konti
}
# "Lasīt un kārtot; 1 konts"
agent-access = { $can }; { $accounts }
agent-unreadable = Šo ziņojumu nevar nolasīt.
agent-encrypted-original = Šis ziņojums ir šifrēts: aģents nevar uz to atbildēt vai to pārsūtīt, jo nevar šifrēt.
agent-encrypted = Šis ziņojums ir šifrēts. Aģents nevar izlasīt tā saturu. Ziņojums jāatver lietotājam lietotnē Inbox Classic.
# review: new
agent-too-many-changes = Pārāk daudz izmaiņu pēdējās 30 dienās: šis aģents ir veicis tik daudz, cik Inbox Classic vienai programmai glabā žurnālā. Vairāk varēs veikt, kad vecākās būs 30 dienas vecas.
# review: new
agent-too-many-reads = Pārāk daudz lasīts pēdējās 30 dienās: šis aģents ir lasījis tik daudz, cik Inbox Classic vienai programmai glabā žurnālā. Vairāk varēs lasīt, kad vecākās lasīšanas reizes būs 30 dienas vecas.
# review: new
list-encrypted = Šifrēts ziņojums
agent-log-composed = Atvēra jaunu ziņojumu „{ $subject }”, kuru varat pabeigt rakstīt
agent-log-refused = Noraidījāt pieprasījumu nosūtīt ziņojumu „{ $subject }”
agent-log-sent = Ievietoja ziņojumu „{ $subject }” nosūtīšanas rindā. Adresāti: { $to }
agent-log-draft = Saglabāja melnrakstu „{ $subject }”
agent-log-draft-replaced = Aizstāja melnrakstu „{ $subject }”
agent-log-draft-discarded = Atmeta melnrakstu „{ $subject }”
agent-draft-note = Šo melnrakstu uzrakstīja MI aģents { $program }. Pirms nosūtāt, pārbaudiet adresātus un tekstu.
agent-log-read = Atzīmēja kā lasītu „{ $subject }”
agent-log-unread = Atzīmēja kā nelasītu „{ $subject }”
agent-log-flagged = Atzīmēja ar karodziņu „{ $subject }”
agent-log-unflagged = Noņēma karodziņu ziņojumam „{ $subject }”
agent-log-deleted = Izdzēsa „{ $subject }”
agent-log-moved = Pārvietoja ziņojumu „{ $subject }” uz mapi „{ $folder }”
agent-log-junk = Atzīmēja „{ $subject }” kā nevēlamu
agent-log-not-junk = Atzīmēja „{ $subject }” kā vēlamu
agent-log-archived = Arhivēja „{ $subject }”
agent-log-folder = Izveidoja mapi „{ $name }”
agent-log-unsubscribed = Apstiprinājāt pieprasījumu atteikties no abonēšanas. Ziņojums: „{ $subject }”
agent-log-unsubscribe-failed = Neizdevās atteikties no abonēšanas. Ziņojums: „{ $subject }”. Iemesls: { $reason }
agent-log-unsubscribe-refused = Noraidījāt pieprasījumu atteikties no abonēšanas. Sūtītāji: { $senders }
agent-unsubscribe-title = { $count ->
    [zero] { $program } vēlas jūsu vārdā atteikties no { $count } adresātu sarakstiem
    [one] { $program } vēlas jūsu vārdā atteikties no { $count } adresātu saraksta
   *[other] { $program } vēlas jūsu vārdā atteikties no { $count } adresātu sarakstiem
}
agent-unsubscribe-detail = { $count ->
    [1] Pēc jūsu apstiprinājuma Inbox Classic lūgs tālāk norādītajam sarakstam pārtraukt jums sūtīt ziņojumus, izmantojot tā piedāvāto atteikšanos ar vienu klikšķi. Netiek sūtīti e-pasta ziņojumi, un jūsu esošie ziņojumi paliek nemainīti savās vietās.
   *[other] Pēc jūsu apstiprinājuma Inbox Classic lūgs katram tālāk norādītajam sarakstam pārtraukt jums sūtīt ziņojumus, izmantojot saraksta piedāvāto atteikšanos ar vienu klikšķi. Netiek sūtīti e-pasta ziņojumi, un jūsu esošie ziņojumi paliek nemainīti savās vietās.
}
# review: new
agent-log-flag-color = Atzīmēja „{ $subject }” ar { $color ->
    [red] sarkanu
    [orange] oranžu
    [yellow] dzeltenu
    [green] zaļu
    [blue] zilu
    [purple] violetu
   *[gray] pelēku
} karodziņu
# review: new
agent-log-renamed = Pārdēvēja mapi „{ $old }” par „{ $name }”
# review: new
agent-log-watched = Sāka vērot sarunu „{ $subject }”
# review: new
agent-log-ignored = Sāka ignorēt sarunu „{ $subject }”
# review: new
agent-log-unmarked = Pārtrauca vērot vai ignorēt sarunu „{ $subject }”
# the reason one change can not be taken back (agent-undo-refused-why)
# review: new
agent-undo-changed = ziņojums kopš tā laika ir mainīts
# one change of many messages an agent made with a search (apply_to_search), a row of the log; { $query } is the search
# review: new
agent-log-bulk-read = { $count ->
    [zero] Atzīmēja kā lasītus { $count } ziņojumu (meklējums: { $query })
    [one] Atzīmēja kā lasītu { $count } ziņojumu (meklējums: { $query })
   *[other] Atzīmēja kā lasītus { $count } ziņojumus (meklējums: { $query })
}
# review: new
agent-log-bulk-unread = { $count ->
    [zero] Atzīmēja kā nelasītus { $count } ziņojumu (meklējums: { $query })
    [one] Atzīmēja kā nelasītu { $count } ziņojumu (meklējums: { $query })
   *[other] Atzīmēja kā nelasītus { $count } ziņojumus (meklējums: { $query })
}
# review: new
agent-log-bulk-flagged = { $count ->
    [zero] Atzīmēja ar karodziņu { $count } ziņojumu (meklējums: { $query })
    [one] Atzīmēja ar karodziņu { $count } ziņojumu (meklējums: { $query })
   *[other] Atzīmēja ar karodziņu { $count } ziņojumus (meklējums: { $query })
}
# review: new
agent-log-bulk-unflagged = { $count ->
    [zero] Noņēma karodziņu { $count } ziņojumiem (meklējums: { $query })
    [one] Noņēma karodziņu { $count } ziņojumam (meklējums: { $query })
   *[other] Noņēma karodziņu { $count } ziņojumiem (meklējums: { $query })
}
# review: new
agent-log-bulk-color = { $count ->
    [zero] Atzīmēja { $count } ziņojumu
    [one] Atzīmēja { $count } ziņojumu
   *[other] Atzīmēja { $count } ziņojumus
} ar { $color ->
    [red] sarkanu
    [orange] oranžu
    [yellow] dzeltenu
    [green] zaļu
    [blue] zilu
    [purple] violetu
   *[gray] pelēku
} karodziņu (meklējums: { $query })
# review: new
agent-log-bulk-moved = { $count ->
    [zero] Pārvietoja { $count } ziņojumu uz mapi „{ $folder }” (meklējums: { $query })
    [one] Pārvietoja { $count } ziņojumu uz mapi „{ $folder }” (meklējums: { $query })
   *[other] Pārvietoja { $count } ziņojumus uz mapi „{ $folder }” (meklējums: { $query })
}
# review: new
agent-log-bulk-archived = { $count ->
    [zero] Arhivēja { $count } ziņojumu (meklējums: { $query })
    [one] Arhivēja { $count } ziņojumu (meklējums: { $query })
   *[other] Arhivēja { $count } ziņojumus (meklējums: { $query })
}
# review: new
agent-log-bulk-junk = { $count ->
    [zero] Atzīmēja { $count } ziņojumu kā nevēlamus (meklējums: { $query })
    [one] Atzīmēja { $count } ziņojumu kā nevēlamu (meklējums: { $query })
   *[other] Atzīmēja { $count } ziņojumus kā nevēlamus (meklējums: { $query })
}
# review: new
agent-log-bulk-not-junk = { $count ->
    [zero] Atzīmēja { $count } ziņojumu kā vēlamus (meklējums: { $query })
    [one] Atzīmēja { $count } ziņojumu kā vēlamu (meklējums: { $query })
   *[other] Atzīmēja { $count } ziņojumus kā vēlamus (meklējums: { $query })
}
# review: new
agent-log-bulk-deleted = { $count ->
    [zero] Izdzēsa { $count } ziņojumu (meklējums: { $query })
    [one] Izdzēsa { $count } ziņojumu (meklējums: { $query })
   *[other] Izdzēsa { $count } ziņojumus (meklējums: { $query })
}
# Undo Everything Since in the AI Agents window: how far back it reaches
# review: new
agent-undo-span = { $span ->
    [quarter] Pēdējās 15 minūtēs
    [hour] Pēdējā stundā
    [hours] Pēdējās 4 stundās
    [day] Pēdējās 24 stundās
    [week] Pēdējās 7 dienās
   *[all] Pēdējās 30 dienās
}
# the question before it takes back what a program did in the span chosen
# review: new
agent-undo-since-question = { $count ->
    [0] { $program } šajā laikā nav veikusi izmaiņas, kuras var atsaukt.
    [zero] Vai atsaukt { $count } izmaiņas, ko { $program } veica šajā laikā?
    [one] Vai atsaukt { $count } izmaiņu, ko { $program } veica šajā laikā?
   *[other] Vai atsaukt { $count } izmaiņas, ko { $program } veica šajā laikā?
}
# review: new
agent-undo-since-detail = Ziņojumi atgriežas mapēs, no kurām tie tika pārvietoti, lasīšanas stāvokļi un karodziņi kļūst tādi, kādi tie bija, un ziņojumi, kas vēl gaida mapē „Izsūtne”, tiek izdzēsti. To, ko kopš tā laika mainījāt jūs vai serveris, atstāj, kā ir.
# what taking back did, then a line for each kind of message it left as it is
# review: new
agent-undo-done = { $count ->
    [0] Nekas netika atsaukts.
    [zero] Atsauktas { $count } izmaiņas.
    [one] Atsaukta { $count } izmaiņa.
   *[other] Atsauktas { $count } izmaiņas.
}
# review: new
agent-undo-left-gone = { $count ->
    [zero] { $count } ziņojumi vairs nebija tur, kur izmaiņa tos ievietoja.
    [one] { $count } ziņojums vairs nebija tur, kur izmaiņa to ievietoja.
   *[other] { $count } ziņojumi vairs nebija tur, kur izmaiņa tos ievietoja.
}
# review: new
agent-undo-left-changed = { $count ->
    [zero] { $count } ziņojumus kopš tā laika mainījāt jūs vai serveris, tāpēc tie atstāti, kā ir.
    [one] { $count } ziņojumu kopš tā laika mainījāt jūs vai serveris, tāpēc tas atstāts, kā ir.
   *[other] { $count } ziņojumus kopš tā laika mainījāt jūs vai serveris, tāpēc tie atstāti, kā ir.
}
# review: new
agent-undo-left-sent = { $count ->
    [zero] { $count } ziņojumi jau bija izgājuši no mapes „Izsūtne”.
    [one] { $count } ziņojums jau bija izgājis no mapes „Izsūtne”.
   *[other] { $count } ziņojumi jau bija izgājuši no mapes „Izsūtne”.
}
# review: new
agent-undo-left-impossible = { $count ->
    [zero] { $count } izmaiņas nevar atsaukt.
    [one] { $count } izmaiņu nevar atsaukt.
   *[other] { $count } izmaiņas nevar atsaukt.
}
# the Send question of an agent's answer to a calendar invitation: what it answers, and when the event is
# review: new
agent-invitation-reply = { $response ->
    [accept] Šis ziņojums pieņem uzaicinājumu „{ $summary }” ({ $when }).
    [tentative] Šis ziņojums provizoriski pieņem uzaicinājumu „{ $summary }” ({ $when }).
   *[decline] Šis ziņojums noraida uzaicinājumu „{ $summary }” ({ $when }).
} Organizatora kalendārs atbildi reģistrē. Jūsu atbilde uz uzaicinājumu mainās tikai tad, kad ziņojums ir nosūtīts.
# the subject of an answer to an invitation, as calendar programs write it
# review: new
invitation-reply-subject = { $response ->
    [accept] Pieņemts: { $summary }
    [tentative] Provizoriski: { $summary }
   *[decline] Noraidīts: { $summary }
}
# the text of an answer to an invitation; { $name } is the user's name, or address
# review: new
invitation-reply-text = { $response ->
    [accept] { $name } pieņēma šo uzaicinājumu.
    [tentative] { $name } provizoriski pieņēma šo uzaicinājumu.
   *[decline] { $name } noraidīja šo uzaicinājumu.
}
# what a program read in an hour, a row of the log: "Read 14 messages and searched 3 times" (joined by agent-can-list)
# review: new
agent-reads-messages = { $count ->
    [zero] izlasīja { $count } ziņojumu
    [one] izlasīja { $count } ziņojumu
   *[other] izlasīja { $count } ziņojumus
}
# review: new
agent-reads-attachments = { $count ->
    [zero] atvēra { $count } pielikumu
    [one] atvēra { $count } pielikumu
   *[other] atvēra { $count } pielikumus
}
# review: new
agent-reads-searches = { $count ->
    [1] meklēja vienu reizi
    [zero] meklēja { $count } reižu
    [one] meklēja { $count } reizi
   *[other] meklēja { $count } reizes
}
# review: new
agent-reads-lists = { $count ->
    [1] skatīja ziņojumu sarakstu vienu reizi
    [zero] skatīja ziņojumu sarakstus { $count } reižu
    [one] skatīja ziņojumu sarakstus { $count } reizi
   *[other] skatīja ziņojumu sarakstus { $count } reizes
}
# each read under that row
# review: new
agent-read-message = Izlasīja ziņojumu „{ $subject }”
# review: new
agent-read-conversation = { $count ->
    [zero] Izlasīja sarunu „{ $subject }” ({ $count } ziņojumu)
    [one] Izlasīja sarunu „{ $subject }” ({ $count } ziņojums)
   *[other] Izlasīja sarunu „{ $subject }” ({ $count } ziņojumi)
}
# review: new
agent-read-attachment = Atvēra pielikumu „{ $name }” ziņojumā „{ $subject }”
# review: new
agent-read-search = { $count ->
    [zero] Meklēja „{ $query }”: { $count } ziņojumu
    [one] Meklēja „{ $query }”: { $count } ziņojums
   *[other] Meklēja „{ $query }”: { $count } ziņojumi
}
# review: new
agent-read-people = Meklēja kontaktus, kuru vārds vai adrese sākas ar „{ $query }”
# review: new
agent-read-list = { $count ->
    [zero] Skatīja { $count } ziņojumu mapē „{ $folder }”
    [one] Skatīja { $count } ziņojumu mapē „{ $folder }”
   *[other] Skatīja { $count } ziņojumus mapē „{ $folder }”
}
# review: new
agent-read-changes = { $count ->
    [zero] Skatīja { $count } jaunu ziņojumu
    [one] Skatīja { $count } jaunu ziņojumu
   *[other] Skatīja { $count } jaunus ziņojumus
}
# the programs started from a terminal app, which share one access: in the list of programs and the question when one connects
# review: new
agent-terminal-programs-mac = No lietotnes { $terminal } palaistās programmas
# review: new
agent-terminal-programs-windows = No termināļa ({ $terminal }) palaistās programmas
# review: new
agent-terminal-programs-linux = No termināļa ({ $terminal }) palaistās programmas
# one of them, as the questions to send or unsubscribe name it: "A program started from Terminal wants to send this message"
# review: new
agent-terminal-program-mac = No lietotnes { $terminal } palaista programma
# review: new
agent-terminal-program-windows = No termināļa ({ $terminal }) palaista programma
# review: new
agent-terminal-program-linux = No termināļa ({ $terminal }) palaista programma
# review: new
agent-connect-title-terminal = { $programs } vēlas izmantot jūsu pastu
# review: new
agent-connect-terminal-detail = Visi MI aģenti, ko palaižat no šī termināļa, kopīgi izmanto šeit atļauto piekļuvi. Lai aģentam piešķirtu atsevišķu piekļuvi, aģenta MCP iestatījumos pievienojiet tā argumentiem --name un paša izvēlētu nosaukumu.
# review: new
agent-connect-claimed = Programma norādīja, ka tā ir { $claimed }. Inbox Classic pārbaudīja, kura programma to palaida: { $program }.

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
sign-in-no-refresh = pakalpojumu sniedzējs nedeva atsvaidzināšanas marķieri
# review: new
sign-in-no-account = pakalpojumu sniedzējs nepateica, kurš konts pierakstījās
# review: new
sign-in-not-finished = pierakstīšanās nav pabeigta
# review: new
secrets-unavailable = { $store } nav pieejams
# review: new
secrets-unavailable-why = { $store } nav pieejams: { $error }
# review: new
secrets-windows = Akreditācijas datu pārvaldnieks
# review: new
secrets-mac = Atslēgu piekariņš
# review: new
secrets-linux = sistēmas atslēgu saišķis (Secret Service)
# review: new
error-no-such-file = šāda faila nav
# review: new
cards-file-too-big = Šis fails ir pārāk liels, lai būtu adrešu grāmata.
# review: new
ui-sender-added = { $name } tika pievienots adrešu grāmatai.
# review: new
ui-sender-known = { $name } jau ir adrešu grāmatā.
# review: new
ui-sender-none = Šī ziņojuma sūtītājam nav e-pasta adreses, ko pievienot.
# review: new
card-name-needed = Kontaktpersonai nav ne vārda, ne e-pasta adreses.
# a file of Import Address Book that could not be read: "contacts.vcf: šāda faila nav"
# review: new
cards-file-failed = { $file }: { $reason }

## One-time codes: the card at the top of a message with a sign-in or verification code

# the domain the code is for, which signed the message
# review: new
otp-heading = Kods no { $domain }
# review: new
otp-copy = Kopēt
# review: new
otp-note = Ievadiet to tikai domēna { $domain } lapā.
# review: new
otp-old = Šis kods tika nosūtīts vairāk nekā stundu pirms tā atvēršanas, un tā derīgums, visticamāk, ir beidzies.

# how many are invited, in the card of an event
# review: new
event-attendees =
    { $count ->
        [zero] { $count } dalībnieku
        [one] { $count } dalībnieks
       *[other] { $count } dalībnieki
    }

# the first line of a new message's notification when it has a code, for a domain that signed it
# review: new
otp-notification = { $code } ir jūsu kods domēnam { $domain }

## OpenPGP keys (keys.rs)
# review: new
pgp-key-valid = Derīga
# review: new
pgp-key-expires = Derīga līdz { $date }
# review: new
pgp-key-expired = Derīguma termiņš beidzās { $date }
# review: new
pgp-key-revoked = Atsaukta
# review: new
pgp-key-revoked-why = Atsaukta: { $reason }
# review: new
pgp-key-not-valid = Nav derīga
# review: new
pgp-key-locked = Nevar izmantot: atslēga, kas to aizsargā, vairs nav šeit: { $store }. Importējiet tās dublējumu vēlreiz.
# review: new
pgp-source-own = Izveidota programmā Inbox Classic
# review: new
pgp-source-file = Importēta no faila
# review: new
pgp-source-paste = Ielīmēta
# review: new
pgp-source-attachment = No ziņojuma
# review: new
pgp-source-vcard = No kontaktpersonas kartītes
# review: new
pgp-source-wkd = No sūtītāja pasta pakalpojumu sniedzēja
# review: new
pgp-source-keyserver = No keys.openpgp.org
# review: new
pgp-source-autocrypt = No ziņojuma Autocrypt galvenes
# review: new
pgp-error-no-store = Privātās atslēgas aizsargā { $store }, ko nevar izmantot: { $error }
# review: new
pgp-error-wrong-passphrase = Paroles frāze nav pareiza.
# review: new
pgp-error-not-a-key = Šī nav OpenPGP atslēga.
# review: new
pgp-error-too-large = Atslēga ir pārāk liela.
# review: new
pgp-error-unusable = Atslēga izmanto vecu vai vāju kriptogrāfiju, un to nevar izmantot.
# review: new
pgp-imported-private = { $count ->
    [1] Jūsu privātā atslēga tika importēta.
    [one] Tika importēta { $count } privātā atslēga.
   *[other] Tika importētas { $count } privātās atslēgas.
}
# review: new
pgp-imported-public = { $count ->
    [one] Tika importēta { $count } atslēga.
   *[other] Tika importētas { $count } atslēgas.
}
# review: new
pgp-imported-pending = Adresei { $addresses } jau tiek izmantota cita atslēga: jaunā gaida kontaktpersonā, līdz to izvēlēsieties.
# review: new
pgp-error-needs-passphrase = Privāto atslēgu aizsargā paroles frāze. Ierakstiet to, lai importētu atslēgu.
# review: new
pgp-error-mismatch = Privātā atslēga nepieder savai publiskajai atslēgai. Iespējams, tā ir mainīta.
# review: new
pgp-file-name-public = { $who } publiskā atslēga.asc
# review: new
pgp-file-name-private = { $who } privātās atslēgas dublējums.asc
# review: new
pgp-pending = Adresei { $address } { $date } tika atrasta cita atslēga.

## Reading signed and encrypted mail (protect.rs)
# review: new
pgp-part-verified = Parakstījis { $signer }, atslēga pārbaudīta
# review: new
pgp-part-signed = Parakstījis { $signer } (atslēga nav pārbaudīta)
# review: new
pgp-part-other = Parakstījis { $signer }, kas nav sūtītājs
# review: new
pgp-part-unknown-key = Parakstīts, bet atslēga nav zināma
# review: new
pgp-part-not-signed = Nav parakstīts
# review: new
pgp-part-not-checked = Paraksts nav pārbaudīts
# review: new
pgp-part-encrypted = Šifrēts. { $signature }
# review: new
pgp-part-no-key = Šifrēts ar atslēgu, kuras jums nav
# review: new
pgp-part-changed = Šifrētā daļa ceļā tika mainīta un netiek rādīta
# review: new
pgp-part-unprotected = Šifrēts bez aizsardzības pret izmaiņām, netiek rādīts
# review: new
pgp-part-broken = Šifrēto daļu nevar nolasīt
# review: new
pgp-why-mismatch = Paraksts neatbilst šim tekstam
# review: new
pgp-why-weak-hash = Paraksts izmanto { $hash }, kas vairs nav drošs
# review: new
pgp-why-key-expired = Parakstīts pēc tam, kad atslēgas derīgums beidzās { $date }
# review: new
pgp-why-key-revoked = Parakstīts ar atsauktu atslēgu
# review: new
pgp-why-not-signing-key = Parakstīts ar atslēgu, kas nedrīkst parakstīt
# review: new
pgp-why-from-future = Paraksts ir datēts nākotnē
# review: new
pgp-why-signature-expired = Paraksta derīgums ir beidzies
# review: new
pgp-why-key-not-valid = Parakstīts ar atslēgu, kas nav derīga
# review: new
pgp-why-not-for-you = Parakstīts citiem adresātiem un pārsūtīts jums
pgp-why-not-key-in-use = Parakstīts ar citu atslēgu, nevis to, kas tiek lietota adresei { $address }
# review: new
pgp-part-pictures-loaded = { $label }. Attēli tika ielādēti no interneta
# review: new
pgp-error-no-own-key = Jums nav atslēgas adresei { $address }, ar ko parakstīt vai šifrēt. Izveidojiet to sadaļā Rīki > Šifrēšanas atslēgas vai izslēdziet parakstīšanu un šifrēšanu.
# review: new
pgp-error-missing-keys = { $count ->
    [1] Adresātam { $addresses } nav atslēgas, ar ko šifrēt.
   *[other] Šiem adresātiem nav atslēgas, ar ko šifrēt: { $addresses }.
}
# review: new
pgp-error-encrypted-quote = Šis ziņojums citē vai pārsūta šifrētu ziņojumu, tāpēc to var nosūtīt tikai šifrētu. Ieslēdziet šifrēšanu vai noņemiet citēto tekstu.
# review: new
pgp-error-protect = Ziņojumu nevarēja parakstīt vai šifrēt: { $reason }
# review: new
pgp-found-keys = Atrasta atslēga: { $addresses }.
# review: new
pgp-found-none = Atslēga netika atrasta: { $addresses }. Palūdziet, lai jums nosūta savu publisko atslēgu.
# review: new
pgp-found-no-key = Neviena atslēga netika atrasta.
# review: new
pgp-find-unavailable = Atslēgas pašlaik nevarēja meklēt: { $error }
# review: new
pgp-publish-pending = keys.openpgp.org nosūtīja apstiprinājuma saiti uz { $addresses }. Jūsu atslēga tur tiks publicēta, kad noklikšķināsiet uz tās.
# review: new
pgp-publish-done = Jūsu atslēga ir publicēta vietnē keys.openpgp.org adresei { $addresses }.
# review: new
pgp-publish-failed = Atslēgu nevarēja publicēt: { $error }
# review: changed
pgp-keyserver-off = Atslēgu meklēšana vietnē keys.openpgp.org ir izslēgta sadaļā { $settings }.
# the compose window with Sign and Encrypt: the line under the fields, each recipient's key, the questions
pgp-compose-encrypted = { $count ->
    [1] Ziņojums tiks nosūtīts šifrēts un digitāli parakstīts. Tā saturu varēsiet izlasīt tikai jūs un adresāts: { $addresses }.
    [zero] Ziņojums tiks nosūtīts šifrēts un digitāli parakstīts. Tā saturu varēsiet izlasīt tikai jūs un { $count } adresātu.
    [one] Ziņojums tiks nosūtīts šifrēts un digitāli parakstīts. Tā saturu varēsiet izlasīt tikai jūs un { $count } adresāts.
   *[other] Ziņojums tiks nosūtīts šifrēts un digitāli parakstīts. Tā saturu varēsiet izlasīt tikai jūs un { $count } adresāti.
}
pgp-compose-encrypt-ready = Tas tiks šifrēts un parakstīts. Pievienojiet adresātus, kuru atslēgas jums ir.
pgp-compose-missing = { $count ->
    [1] Šim adresātam nav izmantojamas atslēgas: { $addresses }. Ziņojumu vēl nevar šifrēt.
    [one] { $count } adresātam nav izmantojamas atslēgas: { $addresses }. Ziņojumu vēl nevar šifrēt.
   *[other] { $count } adresātiem nav izmantojamu atslēgu: { $addresses }. Ziņojumu vēl nevar šifrēt.
}
pgp-compose-looking = Meklē atslēgas: { $addresses }...
pgp-compose-signed = Ziņojums tiks digitāli parakstīts pirms nosūtīšanas. Adresāti varēs pārbaudīt, vai tā saturs pēc parakstīšanas nav mainīts.
pgp-compose-reply-clear = Ziņojums tiks nosūtīts nešifrēts, lai gan sākotnējais ziņojums bija šifrēts.
pgp-compose-encrypted-files = Ziņojumā ir pielikumi no šifrēta ziņojuma, tāpēc to var nosūtīt tikai šifrētu. Ieslēdziet opciju „Šifrēt” vai noņemiet šos pielikumus.
pgp-compose-sign-tip = Digitāli parakstīt ziņojumu ar savu atslēgu, lai adresāti varētu pārbaudīt, vai tā saturs nav mainīts
pgp-compose-sign-tip-encrypted = Ziņojums, kas tiek nosūtīts šifrēts, vienmēr tiek arī digitāli parakstīts
pgp-compose-encrypt-tip = Šifrēt ziņojuma saturu, lai to varētu izlasīt tikai jūs un adresāti
pgp-compose-make-key = Jums vēl nav atslēgas adresei { $address }. Vai izveidot to tagad? Ar šo atslēgu varēsiet digitāli parakstīt un šifrēt ziņojumus.
pgp-compose-key-unusable =
    Nevar izmantot jūsu atslēgu adresei { $address }.

    Iemesls: { $state }

    Atveriet logu „Šifrēšanas atslēgas” un importējiet šīs atslēgas dublējumu vai izveidojiet jaunu atslēgu.
pgp-compose-encrypt-off-quote = Ziņojumā ir teksts, attēli vai pielikumi no šifrēta ziņojuma. Ziņojumu var nosūtīt nešifrētu tikai pēc šī satura noņemšanas. Vai tomēr izslēgt šifrēšanu?
pgp-compose-encrypt-off-reply = Jūs atbildat uz šifrētu ziņojumu vai to pārsūtāt. Bez šifrēšanas tā saturu varēs izlasīt arī serveri, caur kuriem ziņojums tiek sūtīts. Vai izslēgt šifrēšanu?
pgp-recipient-verified = Atslēgas piederība apstiprināta
pgp-recipient-found = Atslēgas piederība nav apstiprināta
pgp-recipient-own = Jūsu atslēga
pgp-recipient-looking = Meklē atslēgu...
pgp-recipient-missing = Nav atslēgas
pgp-recipient-not-found = Atslēga nav atrasta. Pēdējā meklēšana: { $date }
pgp-recipient-unusable = Atslēgu nevar izmantot: { $state }
pgp-recipients-intro = Ziņojums tiek šifrēts ar katra adresāta atslēgu un ar jūsējo.
pgp-recipients-intro-missing = { $count ->
    [1] Vienam adresātam nav izmantojamas šifrēšanas atslēgas. Atrodiet viņa atslēgu, noņemiet adresātu no ziņojuma vai nosūtiet ziņojumu bez šifrēšanas.
    [one] { $count } adresātam nav izmantojamas šifrēšanas atslēgas. Atrodiet šo adresātu atslēgas, noņemiet adresātus no ziņojuma vai nosūtiet ziņojumu bez šifrēšanas.
   *[other] { $count } adresātiem nav izmantojamu šifrēšanas atslēgu. Atrodiet šo adresātu atslēgas, noņemiet adresātus no ziņojuma vai nosūtiet ziņojumu bez šifrēšanas.
}
# review: new
pgp-details-part = { $number }. daļa: { $label }
# review: new
attachment-from-part = No { $number }. daļas: { $label }
# review: new
pgp-details-signed = Parakstīts { $when } ar atslēgu { $key }
# review: new
pgp-details-unknown-key = Parakstīts ar atslēgu { $key }, kuras jums nav
# review: new
pgp-details-opened = Šifrēts ar jūsu atslēgu { $key }
# review: new
pgp-details-for = Šifrēts ar { $keys }
# review: new
pgp-details-plain = Nav parakstīts un nav šifrēts
# review: new
pgp-bar-parts = Šim ziņojumam ir vairākas daļas ({ $count }): { $list }. Katrā daļā norādīts, kā tā ir aizsargāta.
# review: new
pgp-bar-count-verified = Pārbaudītas: { $count }
# review: new
pgp-bar-count-encrypted-signed = { $count ->
    [one] { $count } šifrēta un parakstīta
   *[other] { $count } šifrētas un parakstītas
}
# review: new
pgp-bar-count-encrypted = { $count ->
    [one] { $count } šifrēta
   *[other] { $count } šifrētas
}
# review: new
pgp-bar-count-signed = { $count ->
    [one] { $count } parakstīta
   *[other] { $count } parakstītas
}
# review: new
pgp-bar-count-warning = { $count ->
    [one] { $count } prasa uzmanību
   *[other] { $count } prasa uzmanību
}
# review: new
pgp-bar-count-neutral = Bez apstiprināta paraksta: { $count }
# the setup file: settings, accounts, contacts and keys carried to another computer
# review: new
setup-part-settings = Iestatījumi
# review: new
setup-part-preferences = Logu preferences
# review: new
setup-part-accounts = Konti
# review: new
setup-part-sign-in-apps = Pierakstīšanās lietotnes
# review: new
setup-part-contacts = Kontaktpersonas un grupas
# review: new
setup-part-keys = Šifrēšanas atslēgas
# review: new
setup-part-rules = Ziņojumu kārtulas
# review: new
setup-part-trusted-senders = Uzticamie sūtītāji
# review: new
setup-holds-settings = { $count ->
    [zero] { $count } iestatījumu
    [one] { $count } iestatījums
   *[other] { $count } iestatījumi
}
# review: new
setup-holds-preferences = { $count ->
    [zero] { $count } preferenču
    [one] { $count } preference
   *[other] { $count } preferences
}
# review: new
setup-holds-accounts = { $count ->
    [zero] { $count } kontu
    [one] { $count } konts
   *[other] { $count } konti
}
# review: new
setup-holds-sign-in-apps = { $count ->
    [zero] { $count } pierakstīšanās lietotņu
    [one] { $count } pierakstīšanās lietotne
   *[other] { $count } pierakstīšanās lietotnes
}
# review: new
setup-holds-built-in = Kuras iebūvētās pierakstīšanās lietotnes ir ieslēgtas
# review: new
setup-holds-contacts = { $count ->
    [zero] { $count } kontaktpersonu
    [one] { $count } kontaktpersona
   *[other] { $count } kontaktpersonas
}
# review: new
setup-holds-groups = { $count ->
    [zero] { $count } grupu
    [one] { $count } grupa
   *[other] { $count } grupas
}
# review: new
setup-holds-own-keys = { $count ->
    [zero] { $count } jūsu atslēgu
    [one] { $count } jūsu atslēga
   *[other] { $count } jūsu atslēgas
}
# review: new
setup-holds-contact-keys = { $count ->
    [zero] { $count } kontaktpersonu atslēgu
    [one] { $count } kontaktpersonas atslēga
   *[other] { $count } kontaktpersonu atslēgas
}
# review: new
setup-holds-rules = { $count ->
    [zero] { $count } kārtulu
    [one] { $count } kārtula
   *[other] { $count } kārtulas
}
# review: new
setup-holds-trusted-senders = { $count ->
    [zero] { $count } uzticamu sūtītāju
    [one] { $count } uzticams sūtītājs
   *[other] { $count } uzticami sūtītāji
}
# review: new
setup-sign-in-password = Parole
# review: new
setup-account-secret-password = Tā parole ir failā.
# review: new
setup-account-secret-token = Tā pierakstīšanās dati ir failā.
# review: new
setup-account-asks-password = Pēc importēšanas tas prasīs paroli.
# review: new
setup-account-signs-in-again = Pēc importēšanas tajā jāpierakstās vēlreiz.
# review: new
setup-account-here = Tas šeit jau ir iestatīts, tāpēc tiek izlaists.
# review: new
setup-account-no-app = Tas pierakstās ar { $app }, kas šeit nav iestatīta. Importējiet arī pierakstīšanās lietotnes.
# review: new
setup-invalid-address = „{ $address }” nav e-pasta adrese.
# review: new
setup-invalid-server = { $server } serverim nav izmantojama nosaukuma vai porta.
# review: new
setup-invalid-user = Tam nav lietotājvārda.
# review: new
setup-invalid-sign-in = Tas pierakstās veidā, ko Inbox Classic nepazīst.
# review: new
setup-error-empty = Fails ir tukšs.
# review: new
setup-error-too-large = Fails ir pārāk liels, lai būtu Inbox Classic iestatījumu fails.
# review: new
setup-error-not-setup = Šis fails nav Inbox Classic iestatījumu fails.
# review: new
setup-error-damaged = Iestatījumu fails ir bojāts, un to nevar nolasīt.
# review: new
setup-error-newer = Šos iestatījumus saglabāja jaunāka Inbox Classic versija ({ $version }). Atjauniniet Inbox Classic un pēc tam importējiet tos vēlreiz.
# review: new
setup-error-needs-passphrase = Šos iestatījumus aizsargā paroles frāze. Ierakstiet paroles frāzi, ar kuru tie tika saglabāti.
# review: new
setup-error-wrong-passphrase = Tā nav paroles frāze, ar kuru šie iestatījumi tika saglabāti.
# review: new
setup-error-changed = Iestatījumu fails pēc saglabāšanas tika mainīts vai bojāts, tāpēc to nevar importēt.
# review: new
setup-error-read = Iestatījumu failu nevarēja nolasīt: { $error }
# review: new
setup-error-write = Iestatījumus nevarēja saglabāt: { $error }
# review: new
setup-error-no-parts = Izvēlieties vismaz vienu daļu.
# review: new
setup-left-out = { $count ->
    [one] { $count } daļas „{ $part }” ierakstu nevar izmantot, un tas tiek izlaists.
   *[other] { $count } daļas „{ $part }” ierakstus nevar izmantot, un tie tiek izlaisti.
}
# review: new
setup-imported-settings = Iestatījumi tika aizstāti.
# review: new
setup-imported-preferences = Logu preferences tika aizstātas.
# review: new
setup-added-accounts = { $count ->
    [one] Pievienots { $count } konts.
   *[other] Pievienoti { $count } konti.
}
# review: new
setup-skipped-here = { $address } šeit jau ir iestatīts, tāpēc tika izlaists.
# review: new
setup-skipped-no-app = { $address } tika izlaists: tas pierakstās ar { $app }, kas šeit nav iestatīta.
# review: new
setup-skipped-invalid = { $address } tika izlaists: { $reason }
# review: new
setup-asks-password = { $address } prasīs paroli, kad izveidos savienojumu.
# review: new
setup-signs-in-again = { $address } lūgs jūs pierakstīties vēlreiz, kad izveidos savienojumu.
# review: new
setup-added-sign-in-apps = { $count ->
    [one] Pievienota { $count } pierakstīšanās lietotne.
   *[other] Pievienotas { $count } pierakstīšanās lietotnes.
}
# review: new
setup-skipped-sign-in-apps = { $count ->
    [one] { $count } pierakstīšanās lietotne šeit jau ir iestatīta.
   *[other] { $count } pierakstīšanās lietotnes šeit jau ir iestatītas.
}
# review: new
setup-added-contacts = { $count ->
    [one] Adrešu grāmatai pievienota { $count } kontaktpersona.
   *[other] Adrešu grāmatai pievienotas { $count } kontaktpersonas.
}
# review: new
setup-skipped-contacts = { $count ->
    [one] { $count } kontaktpersona jau ir adrešu grāmatā.
   *[other] { $count } kontaktpersonas jau ir adrešu grāmatā.
}
# review: new
setup-added-groups = { $count ->
    [one] Pievienota vai papildināta { $count } grupa.
   *[other] Pievienotas vai papildinātas { $count } grupas.
}
# review: new
setup-added-own-keys = { $count ->
    [one] Pievienota { $count } jūsu atslēga.
   *[other] Pievienotas { $count } jūsu atslēgas.
}
# review: new
setup-added-contact-keys = { $count ->
    [one] Pievienota { $count } kontaktpersonas atslēga.
   *[other] Pievienotas { $count } kontaktpersonu atslēgas.
}
# review: new
setup-added-rules = { $count ->
    [one] Pievienota { $count } ziņojumu kārtula.
   *[other] Pievienotas { $count } ziņojumu kārtulas.
}
# review: new
setup-skipped-rules = { $count ->
    [one] { $count } ziņojumu kārtula šeit jau ir.
   *[other] { $count } ziņojumu kārtulas šeit jau ir.
}
# review: new
setup-skipped-rules-account = { $count ->
    [one] { $count } ziņojumu kārtula ir paredzēta kontam, kura šeit nav, tāpēc tā tika izlaista.
   *[other] { $count } ziņojumu kārtulas ir paredzētas kontiem, kuru šeit nav, tāpēc tās tika izlaistas.
}
# review: new
setup-rules-waiting = { $count ->
    [one] { $count } ziņojumu kārtula pārvieto ziņojumus uz mapi, kas parādīsies, kad tās konts tiks sinhronizēts.
   *[other] { $count } ziņojumu kārtulas pārvieto ziņojumus uz mapēm, kas parādīsies, kad to konti tiks sinhronizēti.
}
# review: new
setup-added-trusted-senders = { $count ->
    [one] Pievienots { $count } uzticams sūtītājs.
   *[other] Pievienoti { $count } uzticami sūtītāji.
}
# review: new
setup-nothing = Nekas netika importēts.
# review: new
setup-account-servers = { $imap } un { $smtp } ({ $signin })
# review: new
setup-file-name = Inbox Classic iestatījumi un konti
# review: new
setup-skipped-unreachable = { $name } tika izlaista: ar tās pierakstīšanās pakalpojumu nevarēja sazināties. Pievienojiet to vēlreiz sadaļā Pierakstīšanās lietotnes.
# review: new
attachment-runs-programs = Fails „{ $name }” var palaist programmas, tāpēc Inbox Classic to neatver. Saglabājiet to un pēc tam atveriet paši, ja uzticaties tā izcelsmei.
# review: new
attachment-decrypted-note = Šis pielikums ir no šifrēta ziņojuma. Lai to atvērtu, Inbox Classic glabā to atšifrētu šajā datorā, jūsu mapē, ko Inbox Classic iztukšo pēc vienas dienas.
# a bar over the list when the server did not do what the user asked of messages, so they are as they were again
undone-move = { $count ->
   *[other] Pārvietošana uz mapi „{ $folder }” serverī neizdevās, tāpēc { $messages } atkal ir mapē „{ $from }”: { $reason }
}
undone-delete = { $count ->
   *[other] Dzēšana serverī neizdevās, tāpēc { $messages } atkal ir mapē „{ $from }”: { $reason }
}
undone-archive = { $count ->
   *[other] Arhivēšana serverī neizdevās, tāpēc { $messages } atkal ir mapē „{ $from }”: { $reason }
}
undone-read = { $count ->
    [1] Serveris neatzīmēja ziņojumu kā lasītu ({ $messages }), tāpēc tas atkal ir nelasīts: { $reason }
   *[other] Serveris neatzīmēja ziņojumus kā lasītus ({ $messages }), tāpēc tie atkal ir nelasīti: { $reason }
}
undone-unread = { $count ->
    [1] Serveris neatzīmēja ziņojumu kā nelasītu ({ $messages }), tāpēc tas atkal ir lasīts: { $reason }
   *[other] Serveris neatzīmēja ziņojumus kā nelasītus ({ $messages }), tāpēc tie atkal ir lasīti: { $reason }
}
undone-flags = { $count ->
   *[other] Serveris nemainīja karodziņus ({ $messages }), tāpēc izmaiņa ir atcelta: { $reason }
}

## Previews of attachments: the pictures and PDF files shown in a message

# review: new
preview-pdf-option = Rādīt PDF failus vēstulēs
# review: new
preview-pdf-off = PDF faili vēstulēs netiek rādīti.
# review: new
preview-pdf-off-crashed = PDF fails aizvēra Inbox Classic, kamēr tas tika rādīts, tāpēc PDF faili vēstulēs vairs netiek rādīti. Attēli joprojām tiek rādīti. Lai atkal rādītu PDF failus, sadaļā { $settings } ieslēdziet { $option }.
# review: new
preview-pdf-details = { $count ->
    [zero] { $count } lappušu, { $size }
    [one] { $count } lappuse, { $size }
   *[other] { $count } lappuses, { $size }
}
# review: new
preview-page-alt = { $name }, { $page }. lappuse no { $count }
# review: new
preview-more-pages = { $count ->
    [zero] Atveriet failu, lai redzētu visas { $count } lappuses
    [one] Atveriet failu, lai redzētu visu { $count } lappusi
   *[other] Atveriet failu, lai redzētu visas { $count } lappuses
}
# review: new
preview-more-files = { $count ->
    [zero] Vēl { $count } failu ir sarakstā augstāk
    [one] Vēl { $count } fails ir sarakstā augstāk
   *[other] Vēl { $count } faili ir sarakstā augstāk
}
# review: new
preview-tile-downloading = Notiek lejupielāde…
# review: new
preview-tile-preparing = Notiek sagatavošana…
# review: new
preview-tile-format = { $format } attēli vēl netiek rādīti
# review: new
preview-tile-password = Aizsargāts ar paroli: atveriet, lai to ievadītu
# review: new
preview-tile-too-large = Pārāk liels, lai parādītu
# review: new
preview-tile-unreadable = Nevar parādīt
# review: new
preview-tile-timed-out = Parādīšana aizņēma pārāk ilgu laiku
# review: new
preview-tile-crashed = Netiek rādīts: šis fails reiz aizvēra Inbox Classic
# review: new
preview-tile-off = Netiek rādīts, līdz Inbox Classic tiks palaists no jauna
# review: new
preview-not-printed = { $name } ({ $details }) netiek drukāts. Atveriet to, lai izdrukātu.
