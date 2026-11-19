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
decimal-separator = ,
size-bytes = { $count ->
    [zero] { $count } baitu
    [one] { $count } baits
   *[other] { $count } baiti
}
size-kb = { $size } KB
size-mb = { $size } MB
size-gb = { $size } GB
send-delay-off = Izslēgts
send-delay-seconds = { $count ->
    [zero] { $count } sekunžu
    [one] { $count } sekunde
   *[other] { $count } sekundes
}
# the status bar: "12 ziņojumi, nelasīti: 3"
list-counts = { $messages }, nelasīti: { $unread }
list-counts-selected = { $messages }, nelasīti: { $unread }, atlasīti: { $selected }
# the status bar while searching: "Atrasti: 12, nelasīti: 3"
list-counts-found = Atrasti: { $found }, nelasīti: { $unread }
list-counts-found-selected = Atrasti: { $found }, nelasīti: { $unread }, atlasīti: { $selected }
list-counts-none = Neviens ziņojums nav atrasts

## Special folders, as Outlook names them

folder-inbox = Iesūtne
folder-sent = Nosūtītie vienumi
folder-deleted = Izdzēstie vienumi
folder-drafts = Melnraksti
folder-junk = Nevēlamais e-pasts
folder-archive = Arhīvs

## The reading pane

reader-no-message = Nav atlasīts neviens ziņojums.
reader-downloading = Notiek ziņojuma lejupielāde…
reader-downloading-detail = Ziņojums tiks parādīts šeit, kad lejupielāde būs pabeigta.
reader-downloading-size = Ziņojuma lielums ir { $size }. Tas tiks parādīts šeit, kad būs lejupielādēts.
reader-failed = Neizdevās lejupielādēt ziņojumu
reader-failed-network = Neizdevās sazināties ar pasta serveri ({ $reason }).
reader-failed-sign-in = Pasta serveris noraidīja pierakstīšanos ({ $reason }). Logā „Konti” pārbaudiet paroli vai pierakstieties vēlreiz.
reader-failed-security = Neizdevās izveidot drošu savienojumu ar pasta serveri ({ $reason }).
reader-failed-other = Pasta serveris atbildēja: { $reason }.
reader-retry-note = Tiks mēģināts vēlreiz, kad konts atkal izveidos savienojumu.
reader-unreadable = Šo ziņojumu nevar parādīt: { $error }
message-source-title = Ziņojuma pirmkods: { $subject }
message-source-untitled = Ziņojuma pirmkods

## Printing a message, and the header of a message quoted in a reply or forward

header-from = No
header-date = Datums
header-to = Kam
header-cc = Kopija
header-sent = Nosūtīts
header-subject = Temats
header-security = Drošība
header-part = { $number }. daļa
quote-original = ----- Sākotnējais ziņojums -----
fold-show-earlier = Rādīt iepriekšējos ziņojumus

## Bounces: the card at the top of a notice that a message was not delivered

bounce-failed = Jūsu ziņojums netika piegādāts
bounce-delayed = Jūsu ziņojums vēl nav piegādāts
bounce-delayed-note = Jūsu pasta serveris joprojām mēģina to piegādāt. Nav jāsūta vēlreiz.
# the link to the message the notice is about, in Sent Items or another folder
bounce-show-message = Rādīt ziņojumu, kas netika piegādāts
# the link of a delay's card to the message that is still on its way
bounce-show-delayed = Rādīt aizkavēto ziņojumu
bounce-what-to-do = Ko varat darīt:
# what to do about a recipient the message is still on its way to: in the card of a delay, and in the card of a failure
bounce-delayed-do = Pagaidām neko. Ja to joprojām nevarēs piegādāt, saņemsiet vēl vienu paziņojumu.
bounce-delayed-row-do = Pagaidām neko. Jūsu pasta serveris joprojām mēģina to piegādāt, un, ja tas neizdosies, saņemsiet vēl vienu paziņojumu.
# folds the receiving server's own words
bounce-details = Detaļas
# a recipient the notice does not name
bounce-someone = Kāds adresāts
# in Details: the server that refused the message, the status code it gave, and the server that wrote the notice
bounce-server = Serveris: { $server }
bounce-status = Statuss: { $status }
bounce-reported-by = Ziņoja: { $server }
bounce-retry-minutes = Saņēmēja serveris lūdza pirms nākamā mēģinājuma pagaidīt { $count ->
    [1] minūti
    [one] { $count } minūti
   *[other] { $count } minūtes
}.
bounce-retry-hours = Saņēmēja serveris lūdza pirms nākamā mēģinājuma pagaidīt { $count ->
    [1] stundu
    [one] { $count } stundu
   *[other] { $count } stundas
}.
# the names of the blocklists, "Spamhaus ZEN, Barracuda"
bounce-blocklist = Bloķēšanas saraksts: { $lists }
bounce-user-unknown = Šāda adrese nepastāv
bounce-user-unknown-why = Saņēmēja serverī nav pastkastes ar šo adresi. Iespējams, tā ir uzrakstīta kļūdaini vai cilvēks to vairs neizmanto.
bounce-user-unknown-do = Pārbaudiet, vai adrese uzrakstīta pareizi, vai pajautājiet cilvēkam, kuru adresi viņš izmanto tagad.
bounce-invalid-address = Adrese nav derīga
bounce-invalid-address-why = Adrese ir uzrakstīta nepareizā formātā, tāpēc uz to nevar nosūtīt pastu.
bounce-invalid-address-do = Pārbaudiet, vai adresē nav drukas kļūdu, piemēram, liekas atstarpes, izlaista burta vai trūkstošas daļas aiz @.
bounce-mailbox-disabled = Pastkaste ir slēgta
bounce-mailbox-disabled-why = Adrese pastāv, bet tās pastkaste ir izslēgta vai vairs netiek izmantota.
bounce-mailbox-disabled-do = Sazinieties ar cilvēku citādi un pajautājiet adresi, kuru viņš izmanto tagad.
bounce-mailbox-full = Pastkaste ir pilna
bounce-mailbox-full-why = Adresāta pastkastē nav vietas jaunam pastam.
bounce-mailbox-full-do = Mēģiniet nosūtīt vēlāk vai sazinieties ar adresātu citā veidā. Liels pielikums var pārsniegt pastkastē atlikušo vietu.
bounce-spam-blocked = Noraidīts kā mēstule
bounce-spam-blocked-why = Saņēmēja serveris uzskatīja ziņojumu par mēstuli.
bounce-spam-blocked-do = Nosūtiet to vēlreiz bez tā, kas izskatās pēc mēstules, piemēram, bez daudzām saitēm, saīsinātām saitēm vai liela pielikuma. Ja tas atkārtojas, vērsieties pie sava pasta pakalpojumu sniedzēja.
bounce-virus-detected = Noraidīts vīrusa dēļ
bounce-virus-detected-why = Saņēmēja serveris norādīja, ka ziņojumā vai tā pielikumos ir vīruss vai cits kaitīgs saturs.
bounce-virus-detected-do = Pārbaudiet pielikumus ar pretvīrusu programmu. Daži serveri atsaka jebkuru programmu vai arhīvu, tāpēc kopīgojiet šādus failus kā saiti.
bounce-ip-blocklisted = Jūsu pasta serveris ir bloķēšanas sarakstā
bounce-ip-blocklisted-why = Saņēmēja serveris atsaka pastu no servera, kas nosūtīja jūsējo, jo šī servera adrese ir bloķēšanas sarakstā.
bounce-ip-blocklisted-do = Problēma nav ziņojumā. Pārsūtiet šo paziņojumu savam pasta pakalpojumu sniedzējam un lūdziet, lai serveri izņem no saraksta.
bounce-domain-blocklisted = Domēns ir bloķēšanas sarakstā
bounce-domain-blocklisted-why = Saņēmēja serveris atsaka ziņojumu, jo jūsu adreses domēns vai kāds domēns ziņojuma saitēs ir bloķēšanas sarakstā.
bounce-domain-blocklisted-do = Ja ziņojumā ir saites, mēģiniet bez tām. Pretējā gadījumā pārsūtiet šo paziņojumu tam, kurš pārvalda jūsu domēna pastu.
bounce-policy-blocked = Noraidīts saņēmēja servera noteikumu dēļ
bounce-policy-blocked-why = Saņēmēja servera noteikumi nelaiž cauri šo ziņojumu, piemēram, tā lieluma, pielikumu vai sūtītāja dēļ.
bounce-policy-blocked-do = Servera sniegtajā informācijā sadaļā „Detaļas” bieži ir norādīts iemesls. Pajautājiet adresātam, vai viņš var saņemt šādu pastu.
bounce-geo-blocked = Noraidīts izcelsmes vietas dēļ
bounce-geo-blocked-why = Saņēmēja serveris nepieņem pastu no valsts vai tīkla, kurā atrodas jūsu pasta serveris.
bounce-geo-blocked-do = Sazinieties ar cilvēku citādi vai jautājiet par to savam pasta pakalpojumu sniedzējam.
bounce-relay-denied = Serveris to nepārsūtīja tālāk
bounce-relay-denied-why = Kāds serveris atteicās piegādāt ziņojumu tālāk, bieži tāpēc, ka tas tika nosūtīts bez pierakstīšanās vai caur serveri, kas šo adresātu neapkalpo.
bounce-relay-denied-do = Logā „Konti” pārbaudiet konta izejošā pasta servera iestatījumus un to, vai savienojumam ar serveri ir ieslēgta pierakstīšanās.
bounce-auth-failure = Jūsu sūtītāja adresi nevarēja pārbaudīt
bounce-auth-failure-why = Saņēmēja serveris nevarēja apstiprināt, ka ziņojums tiešām nāk no jūsu domēna (SPF, DKIM vai DMARC).
bounce-auth-failure-do = Pārsūtiet šo paziņojumu tam, kurš pārvalda jūsu domēna pastu: tā iestatījumi jālabo. Pa to laiku var palīdzēt sūtīšana caur jūsu pakalpojumu sniedzēja serveri.
bounce-rate-limited = Pārāk daudz pasta vienlaikus
bounce-rate-limited-why = Saņēmēja serveris pagaidām pieņem mazāk ziņojumu no jūsu pasta servera.
bounce-rate-limited-do = Pagaidiet kādu laiku un nosūtiet to vēlreiz. Rakstot daudziem cilvēkiem, sūtiet mazākam skaitam vienlaikus.
bounce-greylisting = Uz brīdi aizturēts
bounce-greylisting-why = Saņēmēja serveris lūdz nezināmiem sūtītājiem mēģināt vēlreiz nedaudz vēlāk; tā ir izplatīta pārbaude pret mēstulēm.
bounce-greylisting-do = Ja serveris turpina piegādes mēģinājumus, pagaidiet. Ja paziņojumā norādīta galīga piegādes kļūme, mēģiniet nosūtīt ziņojumu vēlāk vēlreiz.
bounce-server-error = Saņēmēja serverim radās problēma
bounce-server-error-why = Ar saņēmēja serveri nevarēja sazināties, vai tas nevarēja pieņemt ziņojumu savas problēmas dēļ.
bounce-server-error-do = Nosūtiet to vēlreiz vēlāk. Ja tas joprojām neizdodas, pārbaudiet, vai adreses daļā aiz @ nav drukas kļūdu.
bounce-unknown = Nav piegādāts
bounce-unknown-why = Paziņojumā nav skaidri pateikts, kāpēc.
bounce-unknown-do = Servera sniegtā informācija sadaļā „Detaļas” var palīdzēt noskaidrot iemeslu. Ja tā nepalīdz, pārsūtiet šo paziņojumu savam pasta pakalpojumu sniedzējam.

## Several messages selected

selection-title = { $count ->
    [zero] Atlasīti { $count } ziņojumu
    [one] Atlasīts { $count } ziņojums
   *[other] Atlasīti { $count } ziņojumi
}
selection-unread = Nelasīti: { $count }
selection-flagged = Ar karodziņu: { $count }
delete-for-good-one = Šis ziņojums tiks neatgriezeniski izdzēsts. Vai dzēst to?
delete-for-good-all = Šie ziņojumi ({ $count }) tiks neatgriezeniski izdzēsti. Vai dzēst tos?
delete-for-good-some = { $count } no { $total } ziņojumiem tiks neatgriezeniski izdzēsti. Vai dzēst ziņojumus?
done-read = { $count ->
    [one] { $messages } atzīmēts kā lasīts
   *[other] { $messages } atzīmēti kā lasīti
}
done-unread = { $count ->
    [one] { $messages } atzīmēts kā nelasīts
   *[other] { $messages } atzīmēti kā nelasīti
}
done-flagged = { $count ->
    [one] { $messages } atzīmēts ar karodziņu
   *[other] { $messages } atzīmēti ar karodziņu
}
done-unflagged = Karodziņš noņemts: { $messages }
done-deleted-for-good = { $count ->
    [one] { $messages } neatgriezeniski izdzēsts
   *[other] { $messages } neatgriezeniski izdzēsti
}
done-archived = { $count ->
    [one] { $messages } arhivēts
   *[other] { $messages } arhivēti
}
done-moved = { $count ->
    [one] { $messages } pārvietots. Mērķis: { $folder }
   *[other] { $messages } pārvietoti. Mērķis: { $folder }
}
done-copied = { $count ->
    [one] { $messages } nokopēts. Mērķis: { $folder }
   *[other] { $messages } nokopēti. Mērķis: { $folder }
}
done-moving = { $count ->
   *[other] Notiek pārvietošana: { $messages }. Mērķis: { $folder }...
}
done-copying = { $count ->
   *[other] Notiek kopēšana: { $messages }. Mērķis: { $folder }...
}
done-moved-back = { $count ->
    [one] { $messages } pārvietots atpakaļ. Mērķis: { $folder }
   *[other] { $messages } pārvietoti atpakaļ. Mērķis: { $folder }
}
# the status bar after Watch Conversation and Ignore Conversation, and after either again on a marked one
done-watched = { $count ->
    [1] Saruna tiek vērota
    [zero] Tiek vērotas { $count } sarunu
    [one] { $count } saruna tiek vērota
   *[other] Tiek vērotas { $count } sarunas
}
done-unwatched = { $count ->
    [1] Saruna vairs netiek vērota
    [zero] { $count } sarunu vairs netiek vērotas
    [one] { $count } saruna vairs netiek vērota
   *[other] { $count } sarunas vairs netiek vērotas
}
done-ignored = { $count ->
    [1] Saruna tiek ignorēta
    [zero] Tiek ignorētas { $count } sarunu
    [one] { $count } saruna tiek ignorēta
   *[other] Tiek ignorētas { $count } sarunas
}
done-unignored = { $count ->
    [1] Saruna vairs netiek ignorēta
    [zero] { $count } sarunu vairs netiek ignorētas
    [one] { $count } saruna vairs netiek ignorēta
   *[other] { $count } sarunas vairs netiek ignorētas
}
# after "uz" (to): the dative plural, "uz to mapēm"
their-folders = attiecīgās mapes
undo-move = Atsaukt pārvietošanu
undo-delete = Atsaukt dzēšanu
undo-archive = Atsaukt arhivēšanu
undo-junk = Atsaukt atzīmēšanu kā nevēlamu
undo-not-junk = Atsaukt atzīmēšanu kā vēlamu
undo-send = Atsaukt sūtīšanu
nothing-to-undo = Nav ko atsaukt.
messages-gone = Ziņojumu tur vairs nav.
# A non-selectable IMAP folder cannot contain messages; this does not mean it is empty.
folder-holds-no-messages = Šajā mapē nevar glabāt ziņojumus.
not-archived-here = Šajā mapē esošos ziņojumus nevar arhivēt.
not-emptied-here = Iztukšot var tikai mapes Izdzēstie vienumi un Nevēlamais e-pasts.
next-unread-question = Mapē { $folder } vairs nav nelasītu ziņojumu.

    Vai pāriet uz { $next }, nākamo mapi ar nelasītiem ziņojumiem?
no-unread-left = Nelasītu ziņojumu vairs nav.
empty-question = { $count ->
    [1] Vai iztukšot mapi { $folder }?

        Tajā esošais ziņojums tiks neatgriezeniski izdzēsts. To nevarēs atjaunot.
    [one] Vai iztukšot mapi { $folder }?

        Tajā esošais { $messages } tiks neatgriezeniski izdzēsts. To nevarēs atjaunot.
   *[other] Vai iztukšot mapi { $folder }?

        Tajā esošie { $messages } tiks neatgriezeniski izdzēsti. Tos nevarēs atjaunot.
}
no-junk-folder = Šim kontam nav mapes Nevēlamais e-pasts, uz kuru pārvietot ziņojumus.
no-inbox-folder = Šim kontam nav mapes Iesūtne, uz kuru pārvietot ziņojumus.
# the status bar after a flag in a colour: "2 ziņojumi: uzlikts zils karodziņš"
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

move-window-title-move = { $count ->
    [1] Pārvietot ziņojumu
    [one] Pārvietot { $count } ziņojumu
   *[other] Pārvietot { $count } ziņojumus
}
move-window-title-copy = { $count ->
    [1] Kopēt ziņojumu
    [one] Kopēt { $count } ziņojumu
   *[other] Kopēt { $count } ziņojumus
}
move-window-prompt-move = { $count ->
    [1] Pārvietot atlasīto ziņojumu uz:
    [one] Pārvietot { $count } atlasīto ziņojumu uz:
   *[other] Pārvietot { $count } atlasītos ziņojumus uz:
}
move-window-prompt-copy = { $count ->
    [1] Kopēt atlasīto ziņojumu uz:
    [one] Kopēt { $count } atlasīto ziņojumu uz:
   *[other] Kopēt { $count } atlasītos ziņojumus uz:
}
# the folders used last, over the folder tree
targets-recent = Nesen izmantotās
# the folder the messages are in, which can not be chosen
target-current = { $folder } (pašreizējā)
# a folder used last, with its account when there are several: "Arhīvs (Darbs)"
target-recent = { $folder } ({ $account })

## Moving and copying to another account

transfer-moving = Pārvieto ziņojumu Nr. { $done } (kopā: { $messages }). Mērķis: { $folder }...
transfer-copying = Kopē ziņojumu Nr. { $done } (kopā: { $messages }). Mērķis: { $folder }...
# after "uz" (to): the accusative, "uz citu kontu"
transfer-another-account = cits konts
transfer-folder-gone = mērķa mapes vairs nav
transfer-not-on-server = ziņojuma serverī vairs nav
transfer-not-moved = { $count ->
    [one] Neizdevās pārvietot uz citu kontu ({ $messages }): { $reason }
   *[other] Neizdevās pārvietot uz citu kontu ({ $messages }): { $reason }
}
transfer-not-copied = { $count ->
    [one] Neizdevās nokopēt uz citu kontu ({ $messages }): { $reason }
   *[other] Neizdevās nokopēt uz citu kontu ({ $messages }): { $reason }
}
transfer-none-moved = Nevienu ziņojumu nevarēja pārvietot
transfer-none-copied = Nevienu ziņojumu nevarēja nokopēt

## Messages as files

export-not-in-time = ziņojumu neizdevās lejupielādēt atvēlētajā laikā
export-not-saved = Neizdevās saglabāt: { $failed } (kopā: { $messages }; iemesli: { $problems })
export-not-attached = ziņojumus nevarēja pievienot: { $error }
# the status bar after Save As with several: "3 ziņojumi saglabāti mapē Darbvirsma"
saved-to = { $count ->
    [one] { $messages } saglabāts mapē „{ $folder }”
   *[other] { $messages } saglabāti mapē „{ $folder }”
}
download-progress = Lejupielādē { $done } no { $total }
download-done = Lejupielādēts: { $size }
downloading-messages = { $count ->
   *[other] Notiek lejupielāde: { $messages }...
}
# the status bar after files are dropped on a folder: "3 ziņojumi ievietoti mapē Arhīvs"
import-put = { $count ->
        [one] { $messages } pievienots importēšanas rindai mapē „{ $folder }”
       *[other] { $messages } pievienoti importēšanas rindai mapē „{ $folder }”
    }
import-not-put = Mapē neizdevās ievietot šos ziņojumus:

    { $problems }

## Problems the windows show

error-store = lokālā pasta datubāze: { $error }
error-not-found = nav atrasts
error-closed = notiek izslēgšana
error-other-account = pārlūkprogrammā tika veikta pierakstīšanās kontā „{ $email }”, nevis šajā kontā
# a password or sign-in the mail server refused, with the server's words
failure-authentication = serveris nepieņēma pierakstīšanos ({ $reason })
# the mail server could not be reached or the connection broke, with the reason
failure-network = savienojums ar serveri neizdevās ({ $reason })
error-in-use = pierakstīšanās lietotni nevar noņemt, kamēr to izmanto šie konti: { $accounts }
error-turned-off = šī pierakstīšanās lietotne jauniem kontiem ir izslēgta
error-folder-name = mapes nosaukumam jābūt no 1 līdz 200 rakstzīmēm garam, un tajā nedrīkst būt vadības rakstzīmes
error-folder-separator = šajā serverī mapes nosaukumā nedrīkst būt „{ $separator }”
error-folder-special = Iesūtni un īpašās mapes nevar pārdēvēt vai izdzēst
error-no-recipients = ziņojumam nav adresātu
error-bad-address = „{ $address }” nav e-pasta adrese
error-not-own-address = Adrese „{ $address }” nav šī konta sūtītāja adrešu sarakstā. Pievienojiet to konta rekvizītu laukā „Citas adreses, no kurām sūtāt”.
rule-query-refused = Kārtulas nevar filtrēt pēc mapes vai datuma ({ $words }).
rule-no-query = Ievadiet ienākošo ziņojumu meklēšanas kritērijus.
rule-no-action = Izvēlieties kārtulai vismaz vienu darbību.
error-attachment = neizdevās nolasīt failu „{ $path }”: { $error }
error-no-drafts = kontam nav mapes „Melnraksti”, kurā saglabāt ziņojumu
error-draft-attachment = melnraksta pielikumu nevarēja saglabāt: { $error }
error-password-not-saved = paroli nevarēja saglabāt nākamajai palaišanai: { $error }
error-sign-in-not-saved = jaunos pierakstīšanās datus nevarēja saglabāt nākamajai palaišanai: { $error }
error-import-unreadable = nevar nolasīt failu „{ $path }”: { $error }
error-import-too-large = fails „{ $path }” ir lielāks par 50 MB
error-import-not-mail = fails „{ $path }” nav e-pasta ziņojums
error-list-answered = adresātu saraksta serveris atgrieza statusu { $status }
error-not-built = ziņojumu nevarēja izveidot
error-outbox-waits = { $count ->
    [1] ziņojums gaida mapē „Izsūtne”; nākamajā sūtīšanas/saņemšanas reizē programma mēģinās to nosūtīt
    [zero] { $count } ziņojumu gaida mapē „Izsūtne”; nākamajā sūtīšanas/saņemšanas reizē programma mēģinās tos nosūtīt
    [one] { $count } ziņojums gaida mapē „Izsūtne”; nākamajā sūtīšanas/saņemšanas reizē programma mēģinās to nosūtīt
   *[other] { $count } ziņojumi gaida mapē „Izsūtne”; nākamajā sūtīšanas/saņemšanas reizē programma mēģinās tos nosūtīt
}
error-draft-not-removed = neizdevās noņemt iepriekšējo ziņojuma melnrakstu no mapes „Melnraksti”: { $reason }
error-sent-but = ziņojums tika nosūtīts, bet { $problem }
error-sent-still-in-outbox = tas joprojām ir mapē „Izsūtne”: { $error }
error-sent-no-copy = neizdevās saglabāt kopiju mapē „Nosūtītie vienumi”: { $reason }
error-no-password = šim kontam nav paroles
error-no-sign-in = šim kontam nav pierakstīšanās datu
error-provider-missing = šī versija nevar pierakstīties pakalpojumā { $provider }: vai tā pierakstīšanās lietotne ir noņemta?
error-provider-servers = šī konta serveri neatbilst tā pierakstīšanās lietotnes serveriem
error-app-scopes = { $reason }. Pasta serveris nepieņēma pierakstīšanās lietotnes marķieri: pārbaudiet, vai lietotnes atļaujas (scopes) dod piekļuvi pastam
error-in-folder = { $folder }: { $reason }

## Sign-in apps

sign-in-off-google = Iebūvētā Google pierakstīšanās lietotne šeit ir izslēgta. Ja lietotne ir testēšanas režīmā, ar to var pierakstīties tikai tās testa lietotāji. Varat izmantot savu Google pierakstīšanās lietotni vai lietotnes paroli, ja konts to atļauj. Iebūvēto lietotni var ieslēgt logā „Pierakstīšanās lietotnes”, ko atver no loga „Konti”.
sign-in-off-other = Šī lietotne tika izslēgta logā „Pierakstīšanās lietotnes”, kur to var atkal ieslēgt. Šo logu var atvērt no loga „Konti”.
sign-in-app-no-name = pierakstīšanās lietotnei jānorāda nosaukums
sign-in-app-no-client = trūkst klienta ID
sign-in-app-no-scopes = pierakstīšanās lietotnei jānorāda atļaujas (scopes), kas nodrošina piekļuvi pastam
sign-in-app-bad-host = { $server } servera adrese trūkst vai nav derīgs resursdatora nosaukums
sign-in-app-plain = { $server } serverim jāizmanto SSL/TLS vai STARTTLS
sign-in-app-not-checked = izdevēja dati vēl nav pārbaudīti
sign-in-app-issuer-changed = izdevējs ir mainīts: ievadiet klienta noslēpumu vēlreiz vai noņemiet to
sign-in-register-google = Google Cloud Console izveidojiet OAuth klientu ar tipu Desktop app un piekrišanas ekrānā norādiet atļauju (scope) https://mail.google.com/. Kamēr lietotne ir testēšanas režīmā, pierakstīties var tikai tās testa lietotāji.
sign-in-register-microsoft = Microsoft Entra reģistrējiet lietotni ar platformu Mobile and desktop applications, novirzīšanas URI http://localhost, atļautām publiskā klienta plūsmām un deleģētajām atļaujām IMAP.AccessAsUser.All, SMTP.Send un offline_access. Tikai savai organizācijai kā izdevēju izmantojiet https://login.microsoftonline.com/<tenant ID>/v2.0.
sign-in-register-other = Reģistrējiet vietējo (publisko) klientu ar tālāk norādīto novirzīšanas URI; pakalpojumu sniedzējam tajā jāatļauj jebkurš ports (RFC 8252). Pievienojiet atļauju (scope), ar kuru pakalpojumu sniedzējs dod piekļuvi pastam.

## Calendar invitations

repeats = Atkārtojas
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
repeats-on = { $repeats }: { $days }
# "Katru nedēļu, 10 reizes"
repeats-times = { $count ->
    [1] { $repeats }, vienu reizi
    [one] { $repeats }, { $count } reizi
   *[other] { $repeats }, { $count } reizes
}
day-monday = pirmdiena
day-tuesday = otrdiena
day-wednesday = trešdiena
day-thursday = ceturtdiena
day-friday = piektdiena
day-saturday = sestdiena
day-sunday = svētdiena

## AI agents

agent-level-read = Lasīt pastu: skatīt mapes, ziņojumus, sarunas un atbalstītos pielikumus, meklēt ziņojumus un kontaktus, kā arī skatīt ziņojumu kārtulas
agent-level-organize = Kārtot pastu: atzīmēt ziņojumus kā lasītus vai nelasītus, mainīt karodziņus, to krāsas un nevēlamā pasta atzīmes, pārvietot un arhivēt ziņojumus, veidot un pārdēvēt mapes, vērot sarunas un ignorēt tās, dzēst ziņojumus, pārvietojot tos uz mapi „Izdzēstie vienumi”, un ar jūsu piekrišanu atteikties no adresātu sarakstu abonēšanas
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
agent-too-many-changes = Šis aģents ir sasniedzis izmaiņu skaita ierobežojumu 30 dienās. Inbox Classic vienas programmas žurnālā nevar glabāt vairāk ierakstu. Aģents atkal varēs veikt izmaiņas, kad vecākie ieraksti sasniegs 30 dienu vecumu.
agent-too-many-reads = Šis aģents ir sasniedzis lasīšanas reižu ierobežojumu 30 dienās. Inbox Classic vienas programmas žurnālā nevar glabāt vairāk ierakstu. Aģents atkal varēs lasīt, kad vecākie lasīšanas ieraksti sasniegs 30 dienu vecumu.
list-encrypted = Šifrēts ziņojums
agent-log-composed = Atvēra jaunu ziņojumu „{ $subject }”, kuru varat pabeigt rakstīt
agent-log-refused = Noraidījāt pieprasījumu nosūtīt ziņojumu „{ $subject }”
agent-log-sent = Ievietoja ziņojumu „{ $subject }” nosūtīšanas rindā. Adresāti: { $to }
agent-log-draft = Saglabāja melnrakstu „{ $subject }”
agent-log-draft-replaced = Aizstāja melnrakstu „{ $subject }”
agent-log-draft-discarded = Pieprasīja dzēst melnrakstu „{ $subject }”
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
agent-log-folder = Pieprasīja izveidot mapi „{ $name }”
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
agent-log-flag-color = Atzīmēja „{ $subject }” ar { $color ->
    [red] sarkanu
    [orange] oranžu
    [yellow] dzeltenu
    [green] zaļu
    [blue] zilu
    [purple] violetu
   *[gray] pelēku
} karodziņu
agent-log-renamed = Pieprasīja pārdēvēt mapi „{ $old }” par „{ $name }”
agent-log-watched = Sāka vērot sarunu „{ $subject }”
agent-log-ignored = Sāka ignorēt sarunu „{ $subject }”
agent-log-unmarked = Pārtrauca vērot vai ignorēt sarunu „{ $subject }”
# the reason one change can not be taken back (agent-undo-refused-why)
agent-undo-changed = ziņojums kopš tā laika ir mainīts
# one change of many messages an agent made with a search (apply_to_search), a row of the log; { $query } is the search
agent-log-bulk-read = { $count ->
    [zero] Atzīmēja kā lasītus { $count } ziņojumus (meklējums: { $query })
    [one] Atzīmēja kā lasītu { $count } ziņojumu (meklējums: { $query })
   *[other] Atzīmēja kā lasītus { $count } ziņojumus (meklējums: { $query })
}
agent-log-bulk-unread = { $count ->
    [zero] Atzīmēja kā nelasītus { $count } ziņojumus (meklējums: { $query })
    [one] Atzīmēja kā nelasītu { $count } ziņojumu (meklējums: { $query })
   *[other] Atzīmēja kā nelasītus { $count } ziņojumus (meklējums: { $query })
}
agent-log-bulk-flagged = { $count ->
    [zero] Atzīmēja ar karodziņu { $count } ziņojumus (meklējums: { $query })
    [one] Atzīmēja ar karodziņu { $count } ziņojumu (meklējums: { $query })
   *[other] Atzīmēja ar karodziņu { $count } ziņojumus (meklējums: { $query })
}
agent-log-bulk-unflagged = { $count ->
    [zero] Noņēma karodziņu { $count } ziņojumiem (meklējums: { $query })
    [one] Noņēma karodziņu { $count } ziņojumam (meklējums: { $query })
   *[other] Noņēma karodziņu { $count } ziņojumiem (meklējums: { $query })
}
agent-log-bulk-color = { $count ->
    [zero] Atzīmēja { $count } ziņojumus
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
agent-log-bulk-moved = { $count ->
    [zero] Pārvietoja { $count } ziņojumus uz mapi „{ $folder }” (meklējums: { $query })
    [one] Pārvietoja { $count } ziņojumu uz mapi „{ $folder }” (meklējums: { $query })
   *[other] Pārvietoja { $count } ziņojumus uz mapi „{ $folder }” (meklējums: { $query })
}
agent-log-bulk-archived = { $count ->
    [zero] Arhivēja { $count } ziņojumus (meklējums: { $query })
    [one] Arhivēja { $count } ziņojumu (meklējums: { $query })
   *[other] Arhivēja { $count } ziņojumus (meklējums: { $query })
}
agent-log-bulk-junk = { $count ->
    [zero] Atzīmēja { $count } ziņojumus kā nevēlamus (meklējums: { $query })
    [one] Atzīmēja { $count } ziņojumu kā nevēlamu (meklējums: { $query })
   *[other] Atzīmēja { $count } ziņojumus kā nevēlamus (meklējums: { $query })
}
agent-log-bulk-not-junk = { $count ->
    [zero] Atzīmēja { $count } ziņojumus kā vēlamus (meklējums: { $query })
    [one] Atzīmēja { $count } ziņojumu kā vēlamu (meklējums: { $query })
   *[other] Atzīmēja { $count } ziņojumus kā vēlamus (meklējums: { $query })
}
agent-log-bulk-deleted = { $count ->
    [zero] Izdzēsa { $count } ziņojumus (meklējums: { $query })
    [one] Izdzēsa { $count } ziņojumu (meklējums: { $query })
   *[other] Izdzēsa { $count } ziņojumus (meklējums: { $query })
}
# Undo Everything Since in the AI Agents window: how far back it reaches
agent-undo-span = { $span ->
    [quarter] Pēdējās 15 minūtēs
    [hour] Pēdējā stundā
    [hours] Pēdējās 4 stundās
    [day] Pēdējās 24 stundās
    [week] Pēdējās 7 dienās
   *[all] Pēdējās 30 dienās
}
# the question before it takes back what a program did in the span chosen
agent-undo-since-question = { $count ->
    [0] Programma „{ $program }” šajā laikā nav veikusi izmaiņas, kuras var atsaukt.
    [zero] Vai atsaukt { $count } izmaiņas, ko { $program } veica šajā laikā?
    [one] Vai atsaukt { $count } izmaiņu, ko { $program } veica šajā laikā?
   *[other] Vai atsaukt { $count } izmaiņas, ko { $program } veica šajā laikā?
}
agent-undo-since-detail = Ziņojumi tiek pārvietoti atpakaļ uz iepriekšējām mapēm, tiek atjaunotas iepriekšējās lasīšanas atzīmes un karodziņi, bet ziņojumi, kas vēl gaida izsūtnē, tiek izdzēsti. Izmaiņas, kuras pēc pašreizējā ziņojuma stāvokļa vairs nevar atsaukt, tiek izlaistas. Ne visi vēlākie labojumi ir pasargāti; piemēram, noņemot karodziņu, var pazust arī tā jaunā krāsa.
# what taking back did, then a line for each kind of message it left as it is
agent-undo-done = { $count ->
    [0] Nekas netika atsaukts.
    [zero] Vismaz daļēji atsauktas { $count } darbību.
    [one] Vismaz daļēji atsaukta { $count } darbība.
   *[other] Vismaz daļēji atsauktas { $count } darbības.
}
agent-undo-left-gone = { $count ->
    [zero] { $count } ziņojumu vairs nebija tur, kur izmaiņa tos ievietoja.
    [one] { $count } ziņojums vairs nebija tur, kur izmaiņa to ievietoja.
   *[other] { $count } ziņojumi vairs nebija tur, kur izmaiņa tos ievietoja.
}
agent-undo-left-changed = { $count ->
    [zero] { $count } ziņojumus kopš tā laika mainījāt jūs vai serveris, tāpēc tie atstāti, kā ir.
    [one] { $count } ziņojumu kopš tā laika mainījāt jūs vai serveris, tāpēc tas atstāts, kā ir.
   *[other] { $count } ziņojumus kopš tā laika mainījāt jūs vai serveris, tāpēc tie atstāti, kā ir.
}
agent-undo-left-sent = { $count ->
    [zero] { $count } ziņojumu vairs nebija mapē „Izsūtne”.
    [one] { $count } ziņojums vairs nebija mapē „Izsūtne”.
   *[other] { $count } ziņojumi vairs nebija mapē „Izsūtne”.
}
agent-undo-left-impossible = { $count ->
    [zero] { $count } izmaiņas nevar atsaukt.
    [one] { $count } izmaiņu nevar atsaukt.
   *[other] { $count } izmaiņas nevar atsaukt.
}
# the Send question of an agent's answer to a calendar invitation: what it answers, and when the event is
agent-invitation-reply = { $response ->
    [accept] Šis ziņojums pieņem uzaicinājumu „{ $summary }” ({ $when }).
    [tentative] Šis ziņojums provizoriski pieņem uzaicinājumu „{ $summary }” ({ $when }).
   *[decline] Šis ziņojums noraida uzaicinājumu „{ $summary }” ({ $when }).
} Atbilde tiks nosūtīta organizatoram. Tās statuss Inbox Classic mainīsies pēc veiksmīgas nosūtīšanas pasta serverim.
# the subject of an answer to an invitation, as calendar programs write it
invitation-reply-subject = { $response ->
    [accept] Pieņemts: { $summary }
    [tentative] Provizoriski: { $summary }
   *[decline] Noraidīts: { $summary }
}
# the text of an answer to an invitation; { $name } is the user's name, or address
invitation-reply-text = { $response ->
    [accept] { $name } pieņēma šo uzaicinājumu.
    [tentative] { $name } provizoriski pieņēma šo uzaicinājumu.
   *[decline] { $name } noraidīja šo uzaicinājumu.
}
# what a program read in an hour, a row of the log: "Read 14 messages and searched 3 times" (joined by agent-can-list)
agent-reads-messages = { $count ->
    [zero] izlasīja { $count } ziņojumus
    [one] izlasīja { $count } ziņojumu
   *[other] izlasīja { $count } ziņojumus
}
agent-reads-attachments = { $count ->
    [one] pieprasīja pielikumus { $count } reizi
   *[other] pieprasīja pielikumus { $count } reizes
}
agent-reads-searches = { $count ->
    [1] meklēja vienu reizi
    [zero] meklēja { $count } reizes
    [one] meklēja { $count } reizi
   *[other] meklēja { $count } reizes
}
agent-reads-lists = { $count ->
    [1] skatīja ziņojumu sarakstu vienu reizi
    [zero] skatīja ziņojumu sarakstus { $count } reizes
    [one] skatīja ziņojumu sarakstus { $count } reizi
   *[other] skatīja ziņojumu sarakstus { $count } reizes
}
# each read under that row
agent-read-message = Izlasīja ziņojumu „{ $subject }”
agent-read-conversation = { $count ->
    [zero] Izlasīja sarunu „{ $subject }” ({ $count } ziņojumu)
    [one] Izlasīja sarunu „{ $subject }” ({ $count } ziņojums)
   *[other] Izlasīja sarunu „{ $subject }” ({ $count } ziņojumi)
}
agent-read-attachment = Pieprasīja pielikumu „{ $name }” no ziņojuma „{ $subject }”
agent-read-search = { $count ->
    [zero] Meklēja „{ $query }”: { $count } ziņojumu
    [one] Meklēja „{ $query }”: { $count } ziņojums
   *[other] Meklēja „{ $query }”: { $count } ziņojumi
}
agent-read-people = Meklēja kontaktpersonas, kuru vārds vai adrese sākas ar „{ $query }”
agent-read-list = { $count ->
    [zero] Skatīja { $count } saraksta ierakstus. Saraksts: { $folder }
    [one] Skatīja { $count } saraksta ierakstu. Saraksts: { $folder }
   *[other] Skatīja { $count } saraksta ierakstus. Saraksts: { $folder }
}
agent-read-changes = { $count ->
    [zero] Skatīja { $count } jaunu ziņojumu kopsavilkumus
    [one] Skatīja { $count } jauna ziņojuma kopsavilkumu
   *[other] Skatīja { $count } jaunu ziņojumu kopsavilkumus
}
# the programs started from a terminal app, which share one access: in the list of programs and the question when one connects
agent-terminal-programs-mac = No lietotnes { $terminal } palaistās programmas
agent-terminal-programs-windows = No termināļa ({ $terminal }) palaistās programmas
agent-terminal-programs-linux = No termināļa ({ $terminal }) palaistās programmas
# one of them, as the questions to send or unsubscribe name it: "A program started from Terminal wants to send this message"
agent-terminal-program-mac = No lietotnes { $terminal } palaista programma
agent-terminal-program-windows = No termināļa ({ $terminal }) palaista programma
agent-terminal-program-linux = No termināļa ({ $terminal }) palaista programma
agent-connect-title-terminal = { $programs } vēlas izmantot jūsu pastu
agent-connect-terminal-detail = No tās pašas atpazītās termināļa programmas palaistie aģenti kopīgi izmanto šeit atļauto piekļuvi. Lai aģentu pārvaldītu atsevišķi, tā MCP iestatījumos pievienojiet argumentiem --name un paša izvēlētu nosaukumu. Nosaukums neapliecina programmas identitāti.
agent-connect-claimed = Programma norādīja, ka tā ir { $claimed }. Inbox Classic pārbaudīja, kura programma to palaida: { $program }.

## Keys as the keyboards of the language name them, in the help (Windows and Linux)

key-ctrl = Ctrl
key-alt = Alt
key-shift = Shift
key-del = Del
key-enter = Enter

## Signing in and passwords

sign-in-no-refresh = pakalpojumu sniedzējs nedeva atsvaidzināšanas marķieri
sign-in-no-account = pakalpojumu sniedzējs nepateica, kurš konts pierakstījās
sign-in-not-finished = pierakstīšanās nav pabeigta
secrets-unavailable = { $store } nav pieejams
secrets-unavailable-why = { $store } nav pieejams: { $error }
secrets-windows = Akreditācijas datu pārvaldnieks
secrets-mac = Atslēgu piekariņš
secrets-linux = sistēmas atslēgu saišķis (Secret Service)
error-no-such-file = šāda faila nav
cards-file-too-big = Faila izmērs pārsniedz adrešu grāmatas importēšanas ierobežojumu.
ui-sender-added = Adrešu grāmatai pievienota kontaktpersona „{ $name }”.
ui-sender-known = Kontaktpersona „{ $name }” jau ir adrešu grāmatā.
ui-sender-none = Šī ziņojuma sūtītājam nav e-pasta adreses, ko pievienot.
card-name-needed = Kontaktpersonai nav ne vārda, ne e-pasta adreses.
# a file of Import Address Book that could not be read: "contacts.vcf: šāda faila nav"
cards-file-failed = { $file }: { $reason }

## One-time codes: the card at the top of a message with a sign-in or verification code

# the domain the code is for, which signed the message
otp-heading = Kods no { $domain }
otp-copy = Kopēt
otp-note = Ievadiet to tikai domēna { $domain } lapā.
otp-old = Pēc ziņojuma datuma šis kods ir vairāk nekā stundu sens. Iespējams, tas vairs nav derīgs.

# how many are invited, in the card of an event
event-attendees =
    { $count ->
        [zero] { $count } dalībnieku
        [one] { $count } dalībnieks
       *[other] { $count } dalībnieki
    }

# the first line of a new message's notification when it has a code, for a domain that signed it
otp-notification = { $code } ir jūsu kods domēnam { $domain }

## OpenPGP keys (keys.rs)
pgp-key-valid = Derīga
pgp-key-expires = Derīga līdz { $date }
pgp-key-expired = Derīguma termiņš beidzās { $date }
pgp-key-revoked = Atsaukta
pgp-key-revoked-why = Atsaukta: { $reason }
pgp-key-not-valid = Nav derīga
pgp-key-locked = Privāto atslēgu pašlaik nevar atvērt. Pārbaudiet, vai pieejama sistēmas krātuve „{ $store }”. Ja tajā glabātā aizsardzības atslēga ir zudusi, importējiet privātās atslēgas dublējumu.
pgp-source-own = Izveidota programmā Inbox Classic
pgp-source-file = Importēta no faila
pgp-source-paste = Ielīmēta
pgp-source-attachment = No ziņojuma
pgp-source-vcard = No kontaktpersonas kartītes
pgp-source-wkd = No sūtītāja pasta pakalpojumu sniedzēja
pgp-source-keyserver = No keys.openpgp.org
pgp-source-autocrypt = No ziņojuma Autocrypt galvenes
pgp-error-no-store = Privātās atslēgas aizsargā { $store }, ko nevar izmantot: { $error }
pgp-error-wrong-passphrase = Paroles frāze nav pareiza.
pgp-error-not-a-key = Šī nav OpenPGP atslēga.
pgp-error-too-large = Atslēga ir pārāk liela.
pgp-error-unusable = Atslēgu nevar izmantot šai darbībai. Iespējams, trūkst piemērotas parakstīšanas vai šifrēšanas atslēgas vai izmantotais kriptogrāfijas algoritms nav atbalstīts.
pgp-imported-private = { $count ->
    [1] Jūsu privātā atslēga tika importēta.
    [zero] Tika importētas { $count } privāto atslēgu.
    [one] Tika importēta { $count } privātā atslēga.
   *[other] Tika importētas { $count } privātās atslēgas.
}
pgp-imported-public = { $count ->
    [zero] Tika importētas { $count } atslēgu.
    [one] Tika importēta { $count } atslēga.
   *[other] Tika importētas { $count } atslēgas.
}
pgp-imported-pending = Šīm adresēm jau tiek izmantota cita atslēga: { $addresses }. Jaunā atslēga būs pieejama attiecīgajās kontaktpersonās, līdz izvēlēsieties to izmantot.
pgp-error-needs-passphrase = Privāto atslēgu aizsargā paroles frāze. Ierakstiet to, lai importētu atslēgu.
pgp-error-mismatch = Privātā atslēga neatbilst publiskajai atslēgai. Iespējams, tā ir mainīta.
pgp-file-name-public = Publiskā atslēga - { $who }.asc
pgp-file-name-private = Privātās atslēgas dublējums - { $who }.asc
pgp-pending = Adresei { $address } { $date } tika atrasta cita atslēga.

## Reading signed and encrypted mail (protect.rs)
pgp-part-verified = Parakstītājs: { $signer }; atslēgas piederība apstiprināta
pgp-part-signed = Parakstītājs: { $signer } (atslēgas piederība nav apstiprināta)
pgp-part-other = Parakstītājs: { $signer }; parakstu nevar sasaistīt ar ziņojuma sūtītāju
pgp-part-unknown-key = Parakstīts, bet atslēga nav zināma
pgp-part-not-signed = Nav parakstīts
pgp-part-not-checked = Paraksts nav pārbaudīts
pgp-part-encrypted = Šifrēts. { $signature }
pgp-part-no-key = Šifrēts ar atslēgu, kuras jums nav
pgp-part-changed = Šifrētās daļas integritāti nevar apstiprināt, tāpēc tā netiek rādīta
pgp-part-unprotected = Šifrēts bez aizsardzības pret izmaiņām, netiek rādīts
pgp-part-broken = Šifrēto daļu nevar nolasīt
pgp-why-mismatch = Paraksts neatbilst šim tekstam
pgp-why-weak-hash = Parakstam izmantots novecojis jaucējalgoritms { $hash }, kas vairs nav drošs
pgp-why-key-expired = Parakstīts pēc tam, kad atslēgas derīgums beidzās { $date }
pgp-why-key-revoked = Parakstīts ar atsauktu atslēgu
pgp-why-not-signing-key = Parakstīts ar atslēgu, kas nav paredzēta parakstīšanai
pgp-why-from-future = Paraksts ir datēts nākotnē
pgp-why-signature-expired = Paraksta derīgums ir beidzies
pgp-why-key-not-valid = Parakstīts ar atslēgu, kas nav derīga
pgp-why-not-for-you = Parakstīts citiem adresātiem un pārsūtīts jums
pgp-why-not-key-in-use = Parakstīts ar citu atslēgu, nevis to, kas tiek lietota adresei { $address }
pgp-part-pictures-loaded = { $label }. Attēli tika ielādēti no interneta
pgp-error-no-own-key = Adresei „{ $address }” nav jūsu atslēgas, ko izmantot parakstīšanai vai šifrēšanai. Izveidojiet to logā „Šifrēšanas atslēgas” vai izslēdziet parakstīšanu un šifrēšanu.
pgp-error-missing-keys = { $count ->
    [1] Adresātam { $addresses } nav izmantojamas atslēgas, ar ko šifrēt.
   *[other] Šiem adresātiem nav izmantojamas atslēgas, ar ko šifrēt: { $addresses }.
}
pgp-error-encrypted-quote = Šajā ziņojumā ir citēts vai pārsūtīts šifrēts ziņojums, tāpēc to var nosūtīt tikai šifrētu. Ieslēdziet šifrēšanu vai noņemiet visu no sākotnējā ziņojuma pārņemto tekstu, attēlus un pielikumus.
pgp-error-protect = Ziņojumu nevarēja parakstīt vai šifrēt: { $reason }
pgp-found-keys = Atslēgas atrastas šīm adresēm: { $addresses }.
pgp-found-none = Atslēga netika atrasta: { $addresses }. Palūdziet, lai jums nosūta savu publisko atslēgu.
pgp-found-no-key = Neviena atslēga netika atrasta.
pgp-find-unavailable = Atslēgas pašlaik nevarēja meklēt: { $error }
pgp-publish-pending = keys.openpgp.org nosūtīja apstiprinājuma saiti uz šīm adresēm: { $addresses }. Apstipriniet katru adresi, lai pēc tās varētu atrast jūsu atslēgu.
pgp-publish-done = Jūsu atslēga vietnē keys.openpgp.org ir pieejama šīm adresēm: { $addresses }.
pgp-publish-failed = Atslēgu nevarēja publicēt: { $error }
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

    Vispirms pārbaudiet norādīto iemeslu un piekļuvi sistēmas atslēgu krātuvei. Ja vajadzīgs, logā „Šifrēšanas atslēgas” importējiet atslēgas dublējumu vai izveidojiet jaunu atslēgu.
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
    [1] Vienam adresātam nav izmantojamas šifrēšanas atslēgas. Atrodiet viņa atslēgu, noņemiet adresātu no ziņojuma vai nosūtiet ziņojumu bez šifrēšanas, ja tajā nav teksta, attēlu vai pielikumu no šifrētiem ziņojumiem.
    [one] { $count } adresātam nav izmantojamas šifrēšanas atslēgas. Atrodiet šo adresātu atslēgas, noņemiet adresātus no ziņojuma vai nosūtiet ziņojumu bez šifrēšanas, ja tajā nav teksta, attēlu vai pielikumu no šifrētiem ziņojumiem.
   *[other] { $count } adresātiem nav izmantojamu šifrēšanas atslēgu. Atrodiet šo adresātu atslēgas, noņemiet adresātus no ziņojuma vai nosūtiet ziņojumu bez šifrēšanas, ja tajā nav teksta, attēlu vai pielikumu no šifrētiem ziņojumiem.
}
pgp-details-part = { $number }. daļa: { $label }
attachment-from-part = No { $number }. daļas: { $label }
pgp-details-signed = Parakstīts { $when } ar atslēgu { $key }
pgp-details-unknown-key = Parakstīts ar atslēgu { $key }, kuras jums nav
pgp-details-opened = Atšifrēts ar jūsu atslēgu { $key }
pgp-details-for = Šifrēts saņēmēju atslēgām: { $keys }
pgp-details-plain = Nav parakstīts un nav šifrēts
pgp-bar-parts = Šim ziņojumam ir vairākas daļas ({ $count }): { $list }. Katrā daļā norādīts, kā tā ir aizsargāta.
pgp-bar-count-verified = Ar apstiprinātu atslēgas piederību: { $count }
pgp-bar-count-encrypted-signed = { $count ->
    [zero] { $count } šifrētu un parakstītu
    [one] { $count } šifrēta un parakstīta
   *[other] { $count } šifrētas un parakstītas
}
pgp-bar-count-encrypted = { $count ->
    [zero] { $count } šifrētu
    [one] { $count } šifrēta
   *[other] { $count } šifrētas
}
pgp-bar-count-signed = { $count ->
    [zero] { $count } parakstītu
    [one] { $count } parakstīta
   *[other] { $count } parakstītas
}
pgp-bar-count-warning = { $count ->
    [one] { $count } prasa uzmanību
   *[other] { $count } prasa uzmanību
}
pgp-bar-count-neutral = Bez apstiprināta paraksta: { $count }
# the setup file: settings, accounts, contacts and keys carried to another computer
setup-part-settings = Iestatījumi
setup-part-preferences = Logu preferences
setup-part-accounts = Konti
setup-part-sign-in-apps = Pierakstīšanās lietotnes
setup-part-contacts = Kontaktpersonas un grupas
setup-part-keys = Šifrēšanas atslēgas
setup-part-rules = Ziņojumu kārtulas
setup-part-trusted-senders = Uzticamie sūtītāji
setup-holds-settings = { $count ->
    [zero] { $count } iestatījumu
    [one] { $count } iestatījums
   *[other] { $count } iestatījumi
}
setup-holds-preferences = { $count ->
    [zero] { $count } preferenču
    [one] { $count } preference
   *[other] { $count } preferences
}
setup-holds-accounts = { $count ->
    [zero] { $count } kontu
    [one] { $count } konts
   *[other] { $count } konti
}
setup-holds-sign-in-apps = { $count ->
    [zero] { $count } pierakstīšanās lietotņu
    [one] { $count } pierakstīšanās lietotne
   *[other] { $count } pierakstīšanās lietotnes
}
setup-holds-built-in = Kuras iebūvētās pierakstīšanās lietotnes ir ieslēgtas
setup-holds-contacts = { $count ->
    [zero] { $count } kontaktpersonu
    [one] { $count } kontaktpersona
   *[other] { $count } kontaktpersonas
}
setup-holds-groups = { $count ->
    [zero] { $count } grupu
    [one] { $count } grupa
   *[other] { $count } grupas
}
setup-holds-own-keys = { $count ->
    [zero] { $count } jūsu atslēgu
    [one] { $count } jūsu atslēga
   *[other] { $count } jūsu atslēgas
}
setup-holds-contact-keys = { $count ->
    [zero] { $count } kontaktpersonu atslēgu
    [one] { $count } kontaktpersonas atslēga
   *[other] { $count } kontaktpersonu atslēgas
}
setup-holds-rules = { $count ->
    [zero] { $count } kārtulu
    [one] { $count } kārtula
   *[other] { $count } kārtulas
}
setup-holds-trusted-senders = { $count ->
    [zero] { $count } uzticamu sūtītāju
    [one] { $count } uzticams sūtītājs
   *[other] { $count } uzticami sūtītāji
}
setup-sign-in-password = Parole
setup-account-secret-password = Tā parole ir failā.
setup-account-secret-token = Tā pierakstīšanās dati ir failā.
setup-account-asks-password = Pēc importēšanas tas prasīs paroli.
setup-account-signs-in-again = Pēc importēšanas tajā jāpierakstās vēlreiz.
setup-account-here = Tas šeit jau ir iestatīts, tāpēc tiek izlaists.
setup-account-no-app = Konts izmanto pierakstīšanās lietotni „{ $app }”, kas šeit nav iestatīta. Importējiet arī pierakstīšanās lietotnes.
setup-invalid-address = „{ $address }” nav e-pasta adrese.
setup-invalid-server = Servera { $server } iestatījumos nav derīga nosaukuma, porta vai savienojuma drošības veida.
setup-invalid-user = Tam nav lietotājvārda.
setup-invalid-sign-in = Pierakstīšanās pakalpojuma izdevēja adrese nav derīga.
setup-error-empty = Fails ir tukšs.
setup-error-too-large = Fails pārsniedz Inbox Classic iestatījumu importa lieluma ierobežojumu.
setup-error-not-setup = Šis fails nav Inbox Classic iestatījumu fails.
setup-error-damaged = Iestatījumu fails ir bojāts, un to nevar nolasīt.
setup-error-newer = Šos iestatījumus saglabāja jaunāka Inbox Classic versija ({ $version }). Atjauniniet Inbox Classic un pēc tam importējiet tos vēlreiz.
setup-error-needs-passphrase = Šos iestatījumus aizsargā paroles frāze. Ierakstiet paroles frāzi, ar kuru tie tika saglabāti.
setup-error-wrong-passphrase = Tā nav paroles frāze, ar kuru šie iestatījumi tika saglabāti.
setup-error-changed = Neizdevās apstiprināt iestatījumu faila integritāti. Fails var būt mainīts vai bojāts, tāpēc to nevar importēt.
setup-error-read = Iestatījumu failu nevarēja nolasīt: { $error }
setup-error-write = Iestatījumus nevarēja saglabāt: { $error }
setup-error-no-parts = Izvēlieties vismaz vienu daļu.
setup-left-out = { $count ->
    [one] Daļā „{ $part }” nevar izmantot { $count } ierakstu, tāpēc tas tiek izlaists.
   *[other] Daļā „{ $part }” nevar izmantot { $count } ierakstus, tāpēc tie tiek izlaisti.
}
setup-imported-settings = Iestatījumi tika aizstāti.
setup-imported-preferences = Logu preferences tika aizstātas.
setup-added-accounts = { $count ->
    [zero] Pievienoti { $count } kontu.
    [one] Pievienots { $count } konts.
   *[other] Pievienoti { $count } konti.
}
setup-skipped-here = Konts „{ $address }” šeit jau ir iestatīts, tāpēc tas tika izlaists.
setup-skipped-no-app = Konts „{ $address }” tika izlaists: tam vajadzīgā pierakstīšanās lietotne „{ $app }” šeit nav iestatīta.
setup-skipped-invalid = Konts „{ $address }” tika izlaists: { $reason }
setup-asks-password = Izveidojot savienojumu ar kontu „{ $address }”, būs jāievada parole.
setup-signs-in-again = Izveidojot savienojumu ar kontu „{ $address }”, būs jāpierakstās vēlreiz.
setup-added-sign-in-apps = { $count ->
    [zero] Pievienotas { $count } pierakstīšanās lietotņu.
    [one] Pievienota { $count } pierakstīšanās lietotne.
   *[other] Pievienotas { $count } pierakstīšanās lietotnes.
}
setup-skipped-sign-in-apps = { $count ->
    [zero] { $count } pierakstīšanās lietotņu šeit jau ir iestatītas.
    [one] { $count } pierakstīšanās lietotne šeit jau ir iestatīta.
   *[other] { $count } pierakstīšanās lietotnes šeit jau ir iestatītas.
}
setup-added-contacts = { $count ->
    [zero] Adrešu grāmatai pievienotas { $count } kontaktpersonu.
    [one] Adrešu grāmatai pievienota { $count } kontaktpersona.
   *[other] Adrešu grāmatai pievienotas { $count } kontaktpersonas.
}
setup-skipped-contacts = { $count ->
    [zero] { $count } kontaktpersonu jau ir adrešu grāmatā.
    [one] { $count } kontaktpersona jau ir adrešu grāmatā.
   *[other] { $count } kontaktpersonas jau ir adrešu grāmatā.
}
setup-added-groups = { $count ->
    [zero] Pievienotas vai papildinātas { $count } grupu.
    [one] Pievienota vai papildināta { $count } grupa.
   *[other] Pievienotas vai papildinātas { $count } grupas.
}
setup-added-own-keys = { $count ->
    [zero] Pievienotas { $count } jūsu atslēgu.
    [one] Pievienota { $count } jūsu atslēga.
   *[other] Pievienotas { $count } jūsu atslēgas.
}
setup-added-contact-keys = { $count ->
    [zero] Pievienotas { $count } kontaktpersonu atslēgu.
    [one] Pievienota { $count } kontaktpersonas atslēga.
   *[other] Pievienotas { $count } kontaktpersonu atslēgas.
}
setup-added-rules = { $count ->
    [zero] Pievienotas { $count } ziņojumu kārtulu.
    [one] Pievienota { $count } ziņojumu kārtula.
   *[other] Pievienotas { $count } ziņojumu kārtulas.
}
setup-skipped-rules = { $count ->
    [zero] { $count } ziņojumu kārtulu šeit jau ir.
    [one] { $count } ziņojumu kārtula šeit jau ir.
   *[other] { $count } ziņojumu kārtulas šeit jau ir.
}
setup-skipped-rules-account = { $count ->
    [zero] { $count } ziņojumu kārtulu ir paredzētas kontiem, kuru šeit nav, tāpēc tās tika izlaistas.
    [one] { $count } ziņojumu kārtula ir paredzēta kontam, kura šeit nav, tāpēc tā tika izlaista.
   *[other] { $count } ziņojumu kārtulas ir paredzētas kontiem, kuru šeit nav, tāpēc tās tika izlaistas.
}
setup-rules-waiting = { $count ->
    [zero] { $count } ziņojumu kārtulu gaida mērķa mapju atrašanu pēc kontu sinhronizācijas.
    [one] { $count } ziņojumu kārtula gaida mērķa mapes atrašanu pēc konta sinhronizācijas.
   *[other] { $count } ziņojumu kārtulas gaida mērķa mapju atrašanu pēc kontu sinhronizācijas.
}
setup-added-trusted-senders = { $count ->
    [zero] Pievienoti { $count } uzticamu sūtītāju.
    [one] Pievienots { $count } uzticams sūtītājs.
   *[other] Pievienoti { $count } uzticami sūtītāji.
}
setup-nothing = Nekas netika importēts.
setup-account-servers = { $imap } un { $smtp } ({ $signin })
setup-file-name = Inbox Classic iestatījumi un konti
setup-skipped-unreachable = Neizdevās importēt ierakstu „{ $name }”: nevarēja pārbaudīt tā pierakstīšanās pakalpojuma konfigurāciju. Vajadzīgo pierakstīšanās lietotni pievienojiet vēlreiz logā „Pierakstīšanās lietotnes”.
attachment-runs-programs = Fails „{ $name }” var palaist programmas, tāpēc Inbox Classic to neatver. Saglabājiet to un pēc tam atveriet paši, ja uzticaties tā izcelsmei.
attachment-decrypted-note = Šis pielikums ir no šifrēta ziņojuma. Lai to atvērtu, Inbox Classic saglabā nešifrētu kopiju jūsu lietotāja konta pagaidu mapē. Palaižot programmu, tā mēģina dzēst kopijas, kas vecākas par vienu dienu.
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

preview-pdf-option = Rādīt PDF failus ziņojumos
preview-pdf-off = PDF faili ziņojumos netiek rādīti.
preview-pdf-off-crashed = Iepriekšējais faila priekšskatījums tika pārtraukts vai iestrēga. Piesardzības dēļ PDF faili ziņojumos vairs netiek rādīti, bet attēli joprojām tiek rādīti. Lai atkal rādītu PDF failus, sadaļā „{ $settings }” ieslēdziet opciju „{ $option }”.
preview-pdf-details = { $count ->
    [zero] { $count } lappušu, { $size }
    [one] { $count } lappuse, { $size }
   *[other] { $count } lappuses, { $size }
}
preview-page-alt = { $name }, { $page }. lappuse no { $count }
preview-more-pages = { $count ->
    [1] Atveriet failu, lai skatītu lappusi
    [zero] Atveriet failu, lai skatītu visas lappuses (kopā: { $count })
    [one] Atveriet failu, lai skatītu visas lappuses (kopā: { $count })
   *[other] Atveriet failu, lai skatītu visas lappuses (kopā: { $count })
}
preview-more-files = { $count ->
    [zero] Vēl { $count } failu ir sarakstā augstāk
    [one] Vēl { $count } fails ir sarakstā augstāk
   *[other] Vēl { $count } faili ir sarakstā augstāk
}
preview-tile-downloading = Notiek lejupielāde…
preview-tile-preparing = Notiek sagatavošana…
preview-tile-format = { $format } attēli vēl netiek rādīti
preview-tile-password = Aizsargāts ar paroli: atveriet, lai to ievadītu
preview-tile-too-large = Pārsniedz priekšskatījuma ierobežojumu
preview-tile-unreadable = Nevar parādīt
preview-tile-timed-out = Priekšskatījuma sagatavošana aizņēma pārāk ilgu laiku
preview-tile-crashed = Iepriekšējais priekšskatījums tika pārtraukts vai iestrēga
preview-tile-off = Netiek rādīts, līdz Inbox Classic tiks palaists no jauna
preview-not-printed = Fails „{ $name }” ({ $details }) netiek drukāts. Atveriet to, lai izdrukātu.
