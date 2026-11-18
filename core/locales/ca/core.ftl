# El que diu el nucli, igual a totes les plataformes. Els codis entre { $claus } els omple el programa; cal mantenir-los,
# al lloc on la llengua els posa. Els plurals trien segons el nombre: [one] i *[other] en català.

## Comptadors i mides

messages = { $count ->
    [one] 1 missatge
   *[other] { $count } missatges
}
# el separador decimal de les mides: 2,4 MB
decimal-separator = ,
size-bytes = { $count ->
    [one] 1 byte
   *[other] { $count } bytes
}
size-kb = { $size } kB
size-mb = { $size } MB
size-gb = { $size } GB
send-delay-off = Desactivat
send-delay-seconds = { $count ->
    [one] 1 segon
   *[other] { $count } segons
}
# la barra d’estat: "12 missatges, 3 no llegits"
list-counts = { $messages }; no llegits: { $unread }
list-counts-selected = { $messages }; no llegits: { $unread }; seleccionats: { $selected }
# la barra d’estat mentre es cerca: "12 trobats, 3 no llegits"
list-counts-found = Trobats: { $found }; no llegits: { $unread }
list-counts-found-selected = Trobats: { $found }; no llegits: { $unread }; seleccionats: { $selected }
list-counts-none = No s’ha trobat cap missatge

## Carpetes especials, com les anomena l’Outlook

folder-inbox = Safata d’entrada
folder-sent = Elements enviats
folder-deleted = Elements suprimits
folder-drafts = Esborranys
folder-junk = Correu brossa
folder-archive = Arxiu

## La subfinestra de lectura

reader-no-message = No hi ha cap missatge seleccionat.
reader-downloading = S’està baixant el missatge…
reader-downloading-detail = El missatge apareixerà aquí quan s’acabi de baixar.
reader-downloading-size = El missatge ocupa { $size }. Apareixerà aquí quan s’hagi baixat.
reader-failed = No s’ha pogut baixar el missatge
reader-failed-network = No s’ha pogut connectar amb el servidor de correu ({ $reason }).
reader-failed-sign-in = El servidor de correu no ha acceptat l’inici de sessió ({ $reason }). Comproveu la contrasenya o torneu a iniciar la sessió a Fitxer > Comptes.
reader-failed-security = No s’ha pogut establir una connexió segura amb el servidor de correu ({ $reason }).
reader-failed-other = El servidor de correu ha respost: { $reason }.
reader-retry-note = Es tornarà a provar quan el compte es torni a connectar.
reader-unreadable = Aquest missatge no es pot mostrar: { $error }
message-source-title = Codi font del missatge: { $subject }
message-source-untitled = Codi font del missatge

## Imprimir un missatge, i la capçalera d’un missatge citat en una resposta o un reenviament

header-from = De
header-date = Data
header-to = Per a
header-cc = Cc
header-sent = Enviat
header-subject = Assumpte
header-security = Seguretat
header-part = Part { $number }
quote-original = ----- Missatge original -----
fold-show-earlier = Mostra els missatges anteriors

## Retorns: la targeta al capdamunt d’un avís que un missatge no s’ha lliurat

bounce-failed = El vostre missatge no s’ha lliurat
bounce-delayed = El vostre missatge encara no s’ha lliurat
bounce-delayed-note = El vostre servidor de correu encara intenta lliurar-lo. No cal que el torneu a enviar.
# l’enllaç al missatge de què parla l’avís, a Elements enviats o a una altra carpeta
bounce-show-message = Mostra el missatge retornat
# l’enllaç de la targeta d’un retard al missatge que encara és en camí
bounce-show-delayed = Mostra el missatge endarrerit
bounce-what-to-do = Què podeu fer:
# què fer amb un destinatari al qual el missatge encara va de camí: a la targeta d’un retard i a la d’un error
bounce-delayed-do = Espereu. Si finalment no es pot lliurar el missatge, rebreu un altre avís.
bounce-delayed-row-do = Espereu. El vostre servidor de correu continua intentant lliurar el missatge. Rebreu un altre avís si no ho aconsegueix.
# plega les paraules del servidor que rep el missatge
bounce-details = Detalls
# un destinatari que l’avís no anomena
bounce-someone = Un destinatari
# a Detalls: el servidor que ha refusat el missatge, el codi d’estat que ha donat i el servidor que ha escrit l’avís
bounce-server = Servidor: { $server }
bounce-status = Estat: { $status }
bounce-reported-by = Informat per: { $server }
bounce-retry-minutes = El servidor de destinació ha demanat esperar { $count ->
    [one] un minut
   *[other] { $count } minuts
} abans del pròxim intent.
bounce-retry-hours = El servidor de destinació ha demanat esperar { $count ->
    [one] una hora
   *[other] { $count } hores
} abans del pròxim intent.
# els noms de les llistes de bloqueig, "Spamhaus ZEN, Barracuda"
bounce-blocklist = Llista de bloqueig: { $lists }
bounce-user-unknown = L’adreça no existeix
bounce-user-unknown-why = El servidor de destinació no té cap bústia amb aquesta adreça. Potser està mal escrita, o la persona ja no la fa servir.
bounce-user-unknown-do = Comproveu que l’adreça estigui ben escrita o demaneu al destinatari una adreça actual.
bounce-invalid-address = L’adreça no és vàlida
bounce-invalid-address-why = L’adreça té un format que no permet enviar-hi correu.
bounce-invalid-address-do = Comproveu si hi ha espais, lletres que falten o un domini absent després de l’@.
bounce-mailbox-disabled = La bústia està desactivada
bounce-mailbox-disabled-why = L’adreça existeix, però la seva bústia s’ha desactivat o ja no es fa servir.
bounce-mailbox-disabled-do = Poseu-vos en contacte amb la persona d’una altra manera i demaneu-li una adreça que faci servir ara.
bounce-mailbox-full = La bústia és plena
bounce-mailbox-full-why = La bústia del destinatari no té espai per a correu nou.
bounce-mailbox-full-do = Torneu-lo a enviar d’aquí a uns dies, o aviseu la persona d’una altra manera. Els fitxers adjunts grans són els primers que es refusen.
bounce-spam-blocked = Refusat com a correu brossa
bounce-spam-blocked-why = El servidor de destinació ha classificat el missatge com a correu brossa.
bounce-spam-blocked-do = Torneu-lo a enviar sense allò que sembli correu brossa, com ara molts enllaços, enllaços escurçats o un fitxer adjunt gran. Si continua passant, pregunteu al vostre proveïdor de correu.
bounce-virus-detected = Refusat per un virus
bounce-virus-detected-why = El servidor de destinació ha trobat un virus o un altre contingut perillós al missatge o als seus fitxers adjunts.
bounce-virus-detected-do = Comproveu els fitxers adjunts amb un antivirus. Alguns servidors refusen qualsevol programa o arxiu comprimit, així que compartiu aquests fitxers amb un enllaç.
bounce-ip-blocklisted = El vostre servidor de correu és en una llista de bloqueig
bounce-ip-blocklisted-why = El servidor de destinació refusa el correu del servidor que ha enviat el vostre, perquè l’adreça d’aquest servidor és en una llista de bloqueig.
bounce-ip-blocklisted-do = El problema és el bloqueig del servidor, no el contingut del missatge. Reenvieu aquest avís al vostre proveïdor de correu i demaneu-li que en sol·liciti la retirada de la llista.
bounce-domain-blocklisted = Un domini és en una llista de bloqueig
bounce-domain-blocklisted-why = El servidor de destinació refusa el missatge perquè el domini de la vostra adreça, o un domini dels enllaços del missatge, és en una llista de bloqueig.
bounce-domain-blocklisted-do = Si el missatge conté enllaços, proveu d’enviar-lo sense. Si no, reenvieu aquest avís a qui gestioni el correu del vostre domini.
bounce-policy-blocked = Refusat per les regles del servidor de destinació
bounce-policy-blocked-why = Les regles del servidor de destinació impedeixen lliurar aquest missatge, per exemple per la mida, els fitxers adjunts o el remitent.
bounce-policy-blocked-do = La resposta del servidor a Detalls pot explicar-ne el motiu. Pregunteu al destinatari si pot rebre aquest tipus de correu.
bounce-geo-blocked = Refusat per la seva procedència
bounce-geo-blocked-why = El servidor de destinació no accepta correu del país o la xarxa on és el vostre servidor de correu.
bounce-geo-blocked-do = Poseu-vos en contacte amb la persona d’una altra manera, o pregunteu-ho al vostre proveïdor de correu.
bounce-relay-denied = El servidor no ha retransmès el missatge
bounce-relay-denied-why = Un servidor s’ha negat a lliurar el missatge, sovint perquè s’ha enviat sense iniciar la sessió o a través d’un servidor que no gestiona el correu d’aquest destinatari.
bounce-relay-denied-do = A Fitxer > Comptes, comproveu la configuració del servidor de sortida i les dades d’inici de sessió.
bounce-auth-failure = No s’ha pogut verificar la vostra adreça de remitent
bounce-auth-failure-why = El servidor de destinació no ha pogut confirmar que el missatge vingués realment del vostre domini (SPF, DKIM o DMARC).
bounce-auth-failure-do = Reenvieu aquest avís a qui gestioni el correu del vostre domini: cal corregir-ne la configuració. Mentrestant, pot ajudar enviar a través del servidor del vostre proveïdor.
bounce-rate-limited = Massa correu alhora
bounce-rate-limited-why = El servidor de destinació limita temporalment el nombre de missatges que accepta del vostre servidor de correu.
bounce-rate-limited-do = Espereu una estona i torneu-lo a enviar. Quan escriviu a molta gent, envieu-lo a menys persones cada vegada.
bounce-greylisting = Lliurament ajornat temporalment
bounce-greylisting-why = El servidor de destinació demana als remitents desconeguts que ho tornin a provar una mica més tard, una comprovació habitual contra el correu brossa.
bounce-greylisting-do = Espereu. Els servidors de correu ho tornen a provar automàticament, i el missatge sol arribar abans d’una hora.
bounce-server-error = El servidor de destinació ha tingut un problema
bounce-server-error-why = No s’ha pogut connectar amb el servidor de destinació, o no ha pogut acceptar el missatge per un problema propi.
bounce-server-error-do = Torneu-lo a enviar més tard. Si continua fallant, comproveu que no hi hagi errors d’escriptura a la part de l’adreça que hi ha després de l’@.
bounce-unknown = No lliurat
bounce-unknown-why = L’avís no diu clarament per què.
bounce-unknown-do = La resposta del servidor a Detalls pot donar més informació. Si no aclareix el problema, reenvieu aquest avís al vostre proveïdor de correu.

## Diversos missatges seleccionats

selection-title = { $count ->
    [one] 1 missatge seleccionat
   *[other] { $count } missatges seleccionats
}
selection-unread = No llegits: { $count }
selection-flagged = { $count } amb bandera
delete-for-good-one = Aquest missatge se suprimirà definitivament. Voleu suprimir-lo?
delete-for-good-all = Aquests { $count } missatges se suprimiran definitivament. Voleu suprimir-los?
delete-for-good-some = { $count ->
    [one] Se suprimirà definitivament 1 dels { $total } missatges. Voleu suprimir els missatges seleccionats?
   *[other] Se suprimiran definitivament { $count } dels { $total } missatges. Voleu suprimir els missatges seleccionats?
}
done-read = { $count ->
    [one] Marcat com a llegit: { $messages }
   *[other] Marcats com a llegits: { $messages }
}
done-unread = { $count ->
    [one] Marcat com a no llegit: { $messages }
   *[other] Marcats com a no llegits: { $messages }
}
done-flagged = { $count ->
    [one] Marcat amb bandera: { $messages }
   *[other] Marcats amb bandera: { $messages }
}
done-unflagged = S’ha tret la bandera: { $messages }
done-deleted-for-good = { $count ->
    [one] Suprimit definitivament: { $messages }
   *[other] Suprimits definitivament: { $messages }
}
done-archived = { $count ->
    [one] Arxivat: { $messages }
   *[other] Arxivats: { $messages }
}
done-moved = { $count ->
    [one] { $messages } mogut a { $folder }
   *[other] { $messages } moguts a { $folder }
}
done-copied = { $count ->
    [one] { $messages } copiat a { $folder }
   *[other] { $messages } copiats a { $folder }
}
done-moving = { $count ->
    [one] S’està movent { $messages } a { $folder }...
   *[other] S’estan movent { $messages } a { $folder }...
}
done-copying = { $count ->
    [one] S’està copiant { $messages } a { $folder }...
   *[other] S’estan copiant { $messages } a { $folder }...
}
done-moved-back = { $count ->
    [one] { $messages } retornat a { $folder }
   *[other] { $messages } retornats a { $folder }
}
# la barra d’estat després de Segueix la conversa i Ignora la conversa, i després de tornar-les a triar en una de marcada
done-watched = { $count ->
    [one] Se segueix la conversa
   *[other] Se segueixen { $count } converses
}
done-unwatched = { $count ->
    [one] S’ha deixat de seguir la conversa
   *[other] S’han deixat de seguir { $count } converses
}
done-ignored = { $count ->
    [one] S’ignora la conversa
   *[other] S’ignoren { $count } converses
}
done-unignored = { $count ->
    [one] S’ha deixat d’ignorar la conversa
   *[other] S’han deixat d’ignorar { $count } converses
}
their-folders = les seves carpetes
undo-move = Desfés el trasllat
undo-delete = Desfés la supressió
undo-archive = Desfés l’arxivament
undo-junk = Desfés la marca de correu brossa
undo-not-junk = Desfés la marca de correu legítim
undo-send = Desfés l’enviament
nothing-to-undo = No hi ha res per desfer.
messages-gone = Els missatges ja no hi són.
# Una carpeta IMAP no seleccionable no pot contenir missatges; no vol dir que sigui buida.
folder-holds-no-messages = Aquesta carpeta no pot contenir missatges.
not-archived-here = Els missatges d’aquesta carpeta no es poden arxivar.
not-emptied-here = Només es poden buidar Elements suprimits i Correu brossa.
next-unread-question = No hi ha més missatges no llegits a la carpeta { $folder }.

    Voleu anar a la carpeta { $next }, la següent amb missatges no llegits?
no-unread-left = No queda cap missatge no llegit.
empty-question = { $count ->
    [one] Voleu buidar la carpeta { $folder }?

        El missatge que conté se suprimirà definitivament. No es podrà recuperar.
   *[other] Voleu buidar la carpeta { $folder }?

        Els { $messages } que conté se suprimiran definitivament. No es podran recuperar.
}
no-junk-folder = Aquest compte no té cap carpeta de correu brossa on moure els missatges.
no-inbox-folder = Aquest compte no té cap safata d’entrada on moure els missatges.
# la barra d’estat després d’una bandera de color: "2 missatges amb bandera blava"
done-flagged-color = { $messages } amb bandera { $color ->
    [red] vermella
    [orange] taronja
    [yellow] groga
    [green] verda
    [blue] blava
    [purple] porpra
   *[gray] grisa
}
# el menú Bandera: els colors de les banderes de l’Apple Mail
flag-color = { $color ->
    [red] Vermella
    [orange] Taronja
    [yellow] Groga
    [green] Verda
    [blue] Blava
    [purple] Porpra
   *[gray] Grisa
}

## La finestra Mou i Copia

move-window-title-move = { $count ->
    [one] Mou el missatge
   *[other] Mou { $count } missatges
}
move-window-title-copy = { $count ->
    [one] Copia el missatge
   *[other] Copia { $count } missatges
}
move-window-prompt-move = { $count ->
    [one] Mou el missatge seleccionat a:
   *[other] Mou els { $count } missatges seleccionats a:
}
move-window-prompt-copy = { $count ->
    [one] Copia el missatge seleccionat a:
   *[other] Copia els { $count } missatges seleccionats a:
}
# les carpetes usades darrerament, damunt de l’arbre de carpetes
targets-recent = Recents
# la carpeta on són els missatges, que no es pot triar
target-current = { $folder } (actual)
# una carpeta usada darrerament, amb el seu compte quan n’hi ha diversos: "Arxiu (Feina)"
target-recent = { $folder } ({ $account })

## Moure i copiar a un altre compte

transfer-moving = S’està movent el correu: { $done } de { $messages } a { $folder }...
transfer-copying = S’està copiant el correu: { $done } de { $messages } a { $folder }...
transfer-another-account = un altre compte
transfer-folder-gone = la carpeta de destinació ja no hi és
transfer-not-on-server = el missatge ja no és al servidor
transfer-not-moved = { $count ->
    [one] No s’ha pogut moure a un altre compte: { $messages } ({ $reason })
   *[other] No s’han pogut moure a un altre compte: { $messages } ({ $reason })
}
transfer-not-copied = { $count ->
    [one] No s’ha pogut copiar a un altre compte: { $messages } ({ $reason })
   *[other] No s’han pogut copiar a un altre compte: { $messages } ({ $reason })
}
transfer-none-moved = No s’ha pogut moure cap missatge
transfer-none-copied = No s’ha pogut copiar cap missatge

## Missatges com a fitxers

export-not-in-time = el missatge no s’ha pogut baixar a temps
export-not-saved = Missatges no desats: { $failed } de { $messages } ({ $problems })
export-not-attached = no s’han pogut adjuntar els missatges: { $error }
# la barra d’estat després de Desa com a amb diversos: "Desats a Escriptori: 3 missatges"
saved-to = { $count ->
    [one] Desat a { $folder }: { $messages }
   *[other] Desats a { $folder }: { $messages }
}
download-progress = S’està baixant { $done } de { $total }
download-done = Baixada completada: { $size }
downloading-messages = { $count ->
    [one] S’està baixant { $messages }...
   *[other] S’estan baixant { $messages }...
}
# la barra d’estat després de deixar anar fitxers en una carpeta: "Posats a Arxiu: 3 missatges"
import-put = { $count ->
    [one] Importat a { $folder }: { $messages }
   *[other] Importats a { $folder }: { $messages }
}
import-not-put = No s’han pogut importar aquests missatges a la carpeta:

    { $problems }

## Problemes que mostren les finestres

error-store = base de dades de correu: { $error }
error-not-found = no s’ha trobat
error-closed = s’està tancant
error-other-account = el navegador ha iniciat la sessió amb { $email }, no amb aquest compte
# una contrasenya o un inici de sessió que el servidor de correu ha refusat, amb les paraules del servidor
failure-authentication = el servidor no ha acceptat l’inici de sessió ({ $reason })
# no s’ha pogut connectar amb el servidor de correu o la connexió s’ha tallat, amb el motiu
failure-network = la connexió amb el servidor ha fallat ({ $reason })
error-in-use = no es pot suprimir mentre hi hagi comptes que l’utilitzin per iniciar la sessió: { $accounts }
error-turned-off = aquesta aplicació d’inici de sessió està desactivada per als comptes nous
error-folder-name = el nom de la carpeta ha de tenir entre 1 i 200 caràcters i no pot contenir caràcters de control
error-folder-separator = en aquest servidor, un nom de carpeta no pot contenir «{ $separator }»
error-folder-special = la Safata d’entrada i les carpetes especials no es poden canviar de nom ni suprimir
error-no-recipients = el missatge no té destinataris
error-bad-address = «{ $address }» no és una adreça electrònica
error-not-own-address = { $address } no és cap de les adreces d’enviament d’aquest compte. Afegiu-la al camp «Altres adreces d’enviament» de les propietats del compte.
rule-query-refused = Les regles no poden filtrar per carpeta ni per data ({ $words }).
rule-no-query = Introduïu els criteris de cerca per als missatges entrants.
rule-no-action = Trieu almenys una acció per a la regla.
error-attachment = No s’ha pogut llegir { $path }: { $error }
error-no-drafts = el compte no té cap carpeta Esborranys on desar el missatge
error-draft-attachment = no s’ha pogut conservar un fitxer adjunt de l’esborrany: { $error }
error-password-not-saved = no s’ha pogut desar la contrasenya per a la propera vegada que s’obri l’aplicació: { $error }
error-sign-in-not-saved = no s’han pogut desar les noves credencials d’inici de sessió per a la propera vegada que s’obri l’aplicació: { $error }
error-import-unreadable = No es pot llegir { $path }: { $error }
error-import-too-large = { $path } ocupa més de 50 MB
error-import-not-mail = { $path } no és un missatge de correu electrònic
error-list-answered = el servidor de la llista de correu ha retornat l’estat { $status }
error-not-built = no s’ha pogut preparar el missatge
error-outbox-waits = { $count ->
    [one] el missatge espera a la Safata de sortida i s’enviarà amb el proper Envia/Rep
   *[other] { $count } missatges esperen a la Safata de sortida i s’enviaran amb el proper Envia/Rep
}
error-draft-not-removed = no s’ha pogut eliminar la versió anterior del missatge de la carpeta Esborranys: { $reason }
error-sent-but = el missatge s’ha enviat, però { $problem }
error-sent-still-in-outbox = encara és a la Safata de sortida: { $error }
error-sent-no-copy = no s’ha pogut desar cap còpia a Elements enviats: { $reason }
error-no-password = no hi ha cap contrasenya desada per a aquest compte
error-no-sign-in = no hi ha credencials d’inici de sessió disponibles per a aquest compte
error-provider-missing = aquesta versió no pot iniciar la sessió a { $provider }: potser se n’ha suprimit l’aplicació d’inici de sessió?
error-provider-servers = els servidors d’aquest compte no coincideixen amb els de la seva aplicació d’inici de sessió
error-app-scopes = { $reason }. El servidor de correu no ha acceptat el testimoni de l’aplicació d’inici de sessió: comproveu que els permisos (scopes) de l’aplicació donin accés al correu
error-in-folder = { $folder }: { $reason }

## Aplicacions d’inici de sessió

sign-in-off-google = Google encara no ha verificat Inbox Classic, així que només hi deixa iniciar la sessió als usuaris de prova. Feu servir la vostra pròpia aplicació d’inici de sessió de Google o una contrasenya d’aplicació, o activeu-la a Aplicacions d’inici de sessió (Fitxer > Comptes) si sou un usuari de prova.
sign-in-off-other = Es va desactivar a Aplicacions d’inici de sessió (Fitxer > Comptes). Podeu tornar-la a activar allà.
sign-in-app-no-name = l’aplicació d’inici de sessió necessita un nom
sign-in-app-no-client = falta l’identificador de client
sign-in-app-no-scopes = l’aplicació d’inici de sessió necessita els permisos (scopes) que donen accés al correu
sign-in-app-bad-host = falta l’adreça del servidor { $server } o no és un nom d’amfitrió vàlid
sign-in-app-plain = el servidor { $server } ha d’utilitzar SSL/TLS o STARTTLS
sign-in-app-not-checked = encara no s’ha comprovat l’emissor
sign-in-app-issuer-changed = l’emissor ha canviat: torneu a escriure el secret de client, o suprimiu-lo
sign-in-register-google = A Google Cloud Console, creeu un client OAuth del tipus «Aplicació d’escriptori», amb el permís (scope) https://mail.google.com/ a la pantalla de consentiment. Mentre l’aplicació estigui en proves, només hi podran iniciar la sessió els usuaris de prova.
sign-in-register-microsoft = A Microsoft Entra, registreu una aplicació amb la plataforma «Aplicacions mòbils i d’escriptori» i l’URI de redirecció http://localhost. Activeu els fluxos de client públic i els permisos delegats IMAP.AccessAsUser.All, SMTP.Send i offline_access. Per limitar l’accés a la vostra organització, feu servir https://login.microsoftonline.com/<tenant ID>/v2.0 com a emissor.
sign-in-register-other = Registreu un client natiu (públic) amb l’URI de redirecció indicat a continuació. El proveïdor hi ha de permetre qualsevol port (RFC 8252). Afegiu-hi el permís (scope) que dona accés al correu.

## Invitacions de calendari

repeats = Es repeteix
repeats-every = { $unit ->
    [day] { $interval ->
        [one] Cada dia
       *[other] Cada { $interval } dies
    }
    [week] { $interval ->
        [one] Cada setmana
       *[other] Cada { $interval } setmanes
    }
    [month] { $interval ->
        [one] Cada mes
       *[other] Cada { $interval } mesos
    }
   *[year] { $interval ->
        [one] Cada any
       *[other] Cada { $interval } anys
    }
}
# "Cada setmana els dies dilluns, dimecres"
repeats-on = { $repeats } els dies { $days }
# "Cada setmana, 10 vegades"
repeats-times = { $count ->
    [one] { $repeats }, una vegada
   *[other] { $repeats }, { $count } vegades
}
day-monday = dilluns
day-tuesday = dimarts
day-wednesday = dimecres
day-thursday = dijous
day-friday = divendres
day-saturday = dissabte
day-sunday = diumenge

## Agents d’IA

# review: changed
agent-level-read = Llegir el correu: accedir a carpetes, llistes de missatges, cerques i contingut dels missatges
# review: changed
agent-level-organize = Organitzar el correu: canviar l’estat de lectura, les banderes i els seus colors, gestionar el correu brossa, moure i arxivar missatges, crear i canviar el nom de carpetes, seguir i ignorar converses, suprimir missatges (movent-los a Elements suprimits) i cancel·lar subscripcions a llistes de correu amb la vostra autorització
agent-level-drafts = Escriure esborranys perquè els envieu vós
agent-level-send = Enviar correu, amb la vostra aprovació per a cada missatge
agent-connect-title = { $program } vol fer servir el vostre correu
agent-connect-detail = Un agent d’IA ha demanat treballar amb Inbox Classic. Trieu què pot fer i quins comptes pot veure; ho podreu canviar més endavant a Eines > Agents d’IA.

    Els agents llegeixen correu que han escrit altres persones, i un missatge pot intentar enganyar-los. Inbox Classic sempre us ho demana abans que un agent enviï res.
agent-reply-to = Resposta a «{ $subject }»
agent-reply-all-on = Resposta a tothom: «{ $subject }»
agent-forward-of = Reenviament de «{ $subject }»
agent-never-written-one = No heu escrit mai a { $address }.
agent-never-written-many = No heu escrit mai a { $count } d’aquestes adreces.
agent-send-title = { $program } vol enviar aquest missatge
agent-send-detail = Comproveu els destinataris i el contingut del missatge. Quan ho confirmeu, el missatge esperarà { $seconds } segons a la Safata de sortida, on encara el podreu suprimir.
agent-change-title = Què pot fer { $program }
agent-change-allowed = Canvieu què poden fer amb el vostre correu els agents d’IA d’aquest programa.
agent-change-refused = Heu denegat l’accés a aquest programa. Permeteu-lo per tornar a donar als seus agents accés al vostre correu.
agent-log-taken-back = { $entry } (desfet)
agent-files = Fitxers: { $files }
agent-undo-refused = No es pot desfer.
agent-undo-refused-why = No es pot desfer: { $reason }.
agent-undo-impossible = això no es pot desfer
agent-undo-not-in-folder = el missatge ja no és en aquella carpeta
agent-undo-not-arrived = el missatge encara no ha arribat a la carpeta de destinació
agent-undo-sent = el missatge ja no és a la Safata de sortida
agent-original-not-downloaded = el missatge original encara no s’ha baixat. Obriu-lo primer
agent-turned-away = Rebutjat
agent-can-nothing = Res
agent-can-read = llegir
agent-can-organize = organitzar
agent-can-drafts = escriure esborranys
agent-can-send = enviar amb la vostra aprovació
# "Llegir, organitzar i escriure esborranys"
agent-can-list = { $first } i { $last }
agent-accounts = { $count ->
    [0] cap compte
    [one] 1 compte
   *[other] { $count } comptes
}
# "Llegir i organitzar; 1 compte"
agent-access = { $can }; { $accounts }
agent-unreadable = Aquest missatge no es pot llegir.
agent-encrypted-original = El missatge original està xifrat. Un agent no hi pot respondre ni reenviar-lo perquè no pot xifrar el missatge de sortida.
agent-encrypted = Aquest missatge està xifrat. Els agents d’IA no poden llegir-ne el contingut. L’usuari ha d’obrir-lo a Inbox Classic.
# review: new
agent-too-many-changes = Massa canvis en els últims 30 dies: aquest agent n’ha fet tants com Inbox Classic en desa al registre per a un programa. En podrà fer més quan els més antics tinguin 30 dies.
# review: new
agent-too-many-reads = Massa lectures en els últims 30 dies: aquest agent ha llegit tant com Inbox Classic en desa al registre per a un programa. Podrà llegir més quan les lectures més antigues tinguin 30 dies.
list-encrypted = Missatge xifrat
agent-log-composed = Ha obert «{ $subject }» en una finestra de composició perquè l’editeu
agent-log-refused = Heu rebutjat l’enviament de «{ $subject }»
agent-log-sent = Ha posat «{ $subject }» a la cua per enviar-lo a { $to }
agent-log-draft = Ha desat l’esborrany «{ $subject }»
agent-log-draft-replaced = Ha substituït l’esborrany «{ $subject }»
agent-log-draft-discarded = Ha descartat l’esborrany «{ $subject }»
agent-draft-note = { $program }, un agent d’IA, ha escrit aquest esborrany. Comproveu els destinataris i el text abans d’enviar-lo.
agent-log-read = Ha marcat com a llegit «{ $subject }»
agent-log-unread = Ha marcat com a no llegit «{ $subject }»
agent-log-flagged = Ha marcat «{ $subject }» amb bandera
agent-log-unflagged = Ha tret la bandera de «{ $subject }»
agent-log-deleted = Ha suprimit «{ $subject }»
agent-log-moved = Ha mogut «{ $subject }» a { $folder }
agent-log-junk = Ha marcat «{ $subject }» com a correu brossa
agent-log-not-junk = Ha marcat «{ $subject }» com a correu legítim
agent-log-archived = Ha arxivat «{ $subject }»
agent-log-folder = Ha creat la carpeta «{ $name }»
agent-log-unsubscribed = Heu autoritzat la sol·licitud de cancel·lació de la subscripció. Missatge: «{ $subject }»
agent-log-unsubscribe-failed = No s’ha pogut cancel·lar la subscripció a la llista de correu associada al missatge «{ $subject }»: { $reason }
agent-log-unsubscribe-refused = No heu autoritzat la cancel·lació de subscripcions. Remitents: { $senders }
agent-unsubscribe-title = { $count ->
    [one] { $program } vol cancel·lar la vostra subscripció a una llista de correu
   *[other] { $program } vol cancel·lar la vostra subscripció a { $count } llistes de correu
}
agent-unsubscribe-detail = { $count ->
    [1] Inbox Classic demana a la llista de correu següent que deixi d’enviar-vos missatges, fent servir l’opció de cancel·lació amb un sol clic. No s’envia res més. Els missatges que ja teniu no es modifiquen ni es mouen.
   *[other] Inbox Classic demana a cadascuna de les llistes de correu següents que deixi d’enviar-vos missatges, fent servir l’opció de cancel·lació amb un sol clic. No s’envia res més. Els missatges que ja teniu no es modifiquen ni es mouen.
}
# review: new
agent-log-flag-color = Ha marcat «{ $subject }» amb bandera { $color ->
    [red] vermella
    [orange] taronja
    [yellow] groga
    [green] verda
    [blue] blava
    [purple] porpra
   *[gray] grisa
}
# review: new
agent-log-renamed = Ha canviat el nom de la carpeta «{ $old }» a «{ $name }»
# review: new
agent-log-watched = Ha començat a seguir la conversa «{ $subject }»
# review: new
agent-log-ignored = Ha començat a ignorar la conversa «{ $subject }»
# review: new
agent-log-unmarked = Ha deixat de seguir o ignorar la conversa «{ $subject }»
# what a program read in an hour, a row of the log: "Read 14 messages and searched 3 times" (joined by agent-can-list)
# review: new
agent-reads-messages = { $count ->
    [one] ha llegit 1 missatge
   *[other] ha llegit { $count } missatges
}
# review: new
agent-reads-attachments = { $count ->
    [one] ha obert 1 fitxer adjunt
   *[other] ha obert { $count } fitxers adjunts
}
# review: new
agent-reads-searches = { $count ->
    [one] ha cercat una vegada
   *[other] ha cercat { $count } vegades
}
# review: new
agent-reads-lists = { $count ->
    [one] ha consultat una llista de missatges una vegada
   *[other] ha consultat llistes de missatges { $count } vegades
}
# each read under that row
# review: new
agent-read-message = Ha llegit «{ $subject }»
# review: new
agent-read-conversation = { $count ->
    [one] Ha llegit la conversa «{ $subject }» (1 missatge)
   *[other] Ha llegit la conversa «{ $subject }» ({ $count } missatges)
}
# review: new
agent-read-attachment = Ha obert «{ $name }» de «{ $subject }»
# review: new
agent-read-search = { $count ->
    [one] Ha cercat «{ $query }»: 1 missatge
   *[other] Ha cercat «{ $query }»: { $count } missatges
}
# review: new
agent-read-people = Ha cercat persones que comencen per «{ $query }»
# review: new
agent-read-list = { $count ->
    [one] Ha consultat 1 missatge a { $folder }
   *[other] Ha consultat { $count } missatges a { $folder }
}
# review: new
agent-read-changes = { $count ->
    [one] Ha consultat 1 missatge nou
   *[other] Ha consultat { $count } missatges nous
}
# the programs started from a terminal app, which share one access: in the list of programs and the question when one connects
# review: new
agent-terminal-programs-mac = Programes iniciats des de { $terminal }
# review: new
agent-terminal-programs-windows = Programes iniciats des d’un terminal ({ $terminal })
# review: new
agent-terminal-programs-linux = Programes iniciats des d’un terminal ({ $terminal })
# one of them, as the questions to send or unsubscribe name it: "A program started from Terminal wants to send this message"
# review: new
agent-terminal-program-mac = Un programa iniciat des de { $terminal }
# review: new
agent-terminal-program-windows = Un programa iniciat des d’un terminal ({ $terminal })
# review: new
agent-terminal-program-linux = Un programa iniciat des d’un terminal ({ $terminal })
# review: new
agent-connect-title-terminal = { $programs } volen fer servir el vostre correu
# review: new
agent-connect-terminal-detail = Tots els agents d’IA que inicieu des d’aquest terminal comparteixen l’accés que permeteu aquí. Per donar a un agent el seu propi accés, afegiu --name i un nom que trieu als seus arguments a la configuració MCP de l’agent.

## Les tecles com les anomenen els teclats de la llengua, a l’ajuda (Windows i Linux)

key-ctrl = Ctrl
key-alt = Alt
key-shift = Maj
key-del = Supr
key-enter = Retorn

## Iniciar la sessió i contrasenyes

sign-in-no-refresh = el proveïdor no ha proporcionat cap testimoni d’actualització
sign-in-no-account = el proveïdor no ha indicat quin compte ha iniciat la sessió
sign-in-not-finished = l’inici de sessió encara no s’ha completat
secrets-unavailable = { $store } no està disponible
secrets-unavailable-why = { $store } no està disponible: { $error }
secrets-windows = l’Administrador de credencials
secrets-mac = el clauer
secrets-linux = l’anell de claus del sistema (Secret Service)
error-no-such-file = no existeix aquest fitxer
cards-file-too-big = Aquest fitxer és massa gran per ser una llibreta d’adreces.
ui-sender-added = S’ha afegit { $name } a la Llibreta d’adreces.
ui-sender-known = { $name } ja és a la Llibreta d’adreces.
ui-sender-none = El remitent d’aquest missatge no té cap adreça electrònica per afegir.
card-name-needed = El contacte no té nom ni adreça electrònica.
# un fitxer d’Importa la llibreta d’adreces que no s’ha pogut llegir: "contactes.vcf: no existeix aquest fitxer"
cards-file-failed = { $file }: { $reason }

## Codis d’un sol ús: la targeta al capdamunt d’un missatge amb un codi d’inici de sessió o de verificació

# el domini per al qual és el codi, que ha signat el missatge
otp-heading = Codi per a { $domain }
otp-copy = Copia
otp-note = Introduïu-lo només en una pàgina del domini { $domain }.
otp-old = Aquest codi es va enviar fa més d’una hora i pot haver caducat.

# quantes persones estan convidades, a la targeta d’un esdeveniment
event-attendees =
    { $count ->
        [one] { $count } assistent
       *[other] { $count } assistents
    }

# la primera línia de la notificació d’un missatge nou quan té un codi, per a un domini que l’ha signat
otp-notification = { $code } és el vostre codi per a { $domain }

## Claus OpenPGP (keys.rs)
pgp-key-valid = Vàlida
pgp-key-expires = Vàlida fins al { $date }
pgp-key-expired = Va caducar el { $date }
pgp-key-revoked = Revocada
pgp-key-revoked-why = Revocada: { $reason }
pgp-key-not-valid = No vàlida
pgp-key-locked = No es pot fer servir aquesta clau privada: la clau mestra que la protegeix ja no és a l’emmagatzematge segur ({ $store }). Restaureu la clau privada important-ne una còpia de seguretat.
pgp-source-own = Creada a Inbox Classic
pgp-source-file = Importada d’un fitxer
pgp-source-paste = Enganxada
pgp-source-attachment = D’un missatge
pgp-source-vcard = D’una targeta de contacte
pgp-source-wkd = Del proveïdor de correu del remitent
pgp-source-keyserver = De keys.openpgp.org
pgp-source-autocrypt = De la capçalera Autocrypt d’un missatge
pgp-error-no-store = No es pot accedir a l’emmagatzematge segur ({ $store }) per protegir les claus privades: { $error }
pgp-error-wrong-passphrase = La frase de pas no és correcta.
pgp-error-not-a-key = Això no és una clau OpenPGP.
pgp-error-too-large = La clau és massa gran.
pgp-error-unusable = La clau fa servir una criptografia antiga o feble i no es pot utilitzar.
pgp-imported-private = { $count ->
    [one] S’ha importat la vostra clau privada.
   *[other] S’han importat { $count } claus privades.
}
pgp-imported-public = { $count ->
    [one] S’ha importat una clau.
   *[other] S’han importat { $count } claus.
}
pgp-imported-pending = Ja es fa servir una altra clau per a aquestes adreces: { $addresses }. La clau nova queda pendent fins que la trieu a les propietats del contacte.
pgp-error-needs-passphrase = La clau privada està protegida amb una frase de pas. Escriviu-la per importar la clau.
pgp-error-mismatch = La clau privada no correspon a la seva clau pública. Pot ser que s’hagi alterat.
pgp-file-name-public = Clau pública, { $who }.asc
pgp-file-name-private = Còpia de seguretat de la clau privada, { $who }.asc
pgp-pending = El { $date } es va trobar una clau diferent per a { $address }.

## Llegir correu signat i xifrat (protect.rs)
pgp-part-verified = Signat per { $signer }, clau verificada
pgp-part-signed = Signat per { $signer } (clau no verificada)
pgp-part-other = Signat per { $signer }, que no és el remitent
pgp-part-unknown-key = Signatura no comprovada: la clau és desconeguda
pgp-part-not-signed = No signat
pgp-part-not-checked = Signatura no comprovada
pgp-part-encrypted = Xifrat. { $signature }
pgp-part-no-key = Xifrat: no teniu cap clau privada que permeti desxifrar-lo
pgp-part-changed = La part xifrada s’ha modificat després de xifrar-la i no es mostra
pgp-part-unprotected = Xifrat sense protecció contra modificacions, no es mostra
pgp-part-broken = La part xifrada no es pot llegir
pgp-why-mismatch = La signatura no correspon a aquest text
pgp-why-weak-hash = La signatura fa servir { $hash }, que ja no és segur
pgp-why-key-expired = Signat després que la clau caduqués el { $date }
pgp-why-key-revoked = Signat amb una clau revocada
pgp-why-not-signing-key = Signat amb una clau que no està habilitada per signar
pgp-why-from-future = La signatura té una data futura
pgp-why-signature-expired = La signatura ha caducat
pgp-why-key-not-valid = Signat amb una clau que no és vàlida
pgp-why-not-for-you = Signat per a altres destinataris, i reenviat a vós
pgp-why-not-key-in-use = Signat amb una clau diferent de la que s’utilitza per a l’adreça { $address }
pgp-part-pictures-loaded = { $label }. S’han carregat imatges d’internet
pgp-error-no-own-key = No teniu cap clau per a { $address } amb què signar o xifrar. Creeu-ne una a Eines > Claus de xifratge, o desactiveu Signa i Xifra.
pgp-error-missing-keys = { $count ->
    [one] Falta la clau pública d’aquest destinatari per xifrar el missatge: { $addresses }.
   *[other] Falten les claus públiques d’aquests destinataris per xifrar el missatge: { $addresses }.
}
pgp-error-encrypted-quote = Aquest missatge cita o reenvia contingut xifrat i, per tant, només es pot enviar xifrat. Activeu Xifra o suprimiu el contingut citat.
pgp-error-protect = No s’ha pogut signar ni xifrar el missatge: { $reason }
pgp-found-keys = Adreces per a les quals s’han trobat claus: { $addresses }.
pgp-found-none = No s’ha trobat cap clau per a: { $addresses }. Demaneu la clau pública als contactes corresponents.
pgp-found-no-key = No s’ha trobat cap clau.
pgp-find-unavailable = Ara no es poden cercar claus: { $error }
pgp-publish-pending = keys.openpgp.org ha enviat un enllaç de confirmació a cada adreça: { $addresses }. Confirmeu cada adreça per fer-hi accessible la vostra clau.
pgp-publish-done = La vostra clau està publicada a keys.openpgp.org. Adreces: { $addresses }.
pgp-publish-failed = No s’ha pogut publicar la clau: { $error }
pgp-keyserver-off = La cerca de claus a keys.openpgp.org està desactivada a { $settings }.
# the compose window with Sign and Encrypt: the line under the fields, each recipient's key, the questions
pgp-compose-encrypted = { $count ->
    [one] El missatge es xifrarà i se signarà en enviar-lo. Només vós i { $addresses } en podreu llegir el contingut.
   *[other] El missatge es xifrarà i se signarà en enviar-lo. Només vós i els { $count } destinataris en podreu llegir el contingut.
}
pgp-compose-encrypt-ready = El missatge es xifrarà i se signarà en enviar-lo. Afegiu destinataris de qui tingueu una clau utilitzable.
pgp-compose-missing = { $count ->
    [one] No hi ha cap clau utilitzable per a aquest destinatari: { $addresses }. Encara no es pot xifrar el missatge.
   *[other] No hi ha claus utilitzables per a { $count } destinataris: { $addresses }. Encara no es pot xifrar el missatge.
}
pgp-compose-looking = S’estan cercant claus: { $addresses }...
pgp-compose-signed = El missatge se signarà digitalment en enviar-lo. Els destinataris podran comprovar la signatura i la integritat del contingut.
pgp-compose-reply-clear = Sense xifrar, tot i que el missatge original estava xifrat.
pgp-compose-encrypted-files = Aquest missatge conté fitxers adjunts provinents d’un missatge xifrat i només es pot enviar xifrat. Activeu «Xifra» o traieu aquests fitxers adjunts.
pgp-compose-sign-tip = Signeu el missatge digitalment en enviar-lo perquè els destinataris puguin comprovar la signatura i la integritat del contingut
pgp-compose-sign-tip-encrypted = Els missatges xifrats sempre se signen en enviar-los
pgp-compose-encrypt-tip = Xifreu el contingut del missatge en enviar-lo perquè només vós i els destinataris el pugueu llegir
pgp-compose-make-key = Encara no hi ha cap clau pròpia configurada per a l’adreça { $address }. Voleu crear-ne una ara? Us permetrà signar i xifrar missatges.
pgp-compose-key-unusable = La vostra clau per a l’adreça { $address } no es pot fer servir. Motiu: { $state }
    Obriu «Claus de xifratge» per importar una còpia de seguretat d’aquesta clau o crear-ne una de nova.
pgp-compose-encrypt-off-quote = Aquest missatge encara conté text, imatges o fitxers adjunts provinents d’un missatge xifrat. Traieu-los abans d’enviar-lo sense xifrar. Voleu desactivar el xifratge igualment?
pgp-compose-encrypt-off-reply = El missatge original estava xifrat. Si envieu la resposta o el missatge reenviat sense xifrar, els servidors de correu en podran llegir el contingut. Voleu desactivar el xifratge?
pgp-recipient-verified = Clau verificada
pgp-recipient-found = Clau no verificada
pgp-recipient-own = La vostra clau
pgp-recipient-looking = S’està cercant una clau...
pgp-recipient-missing = Cap clau
pgp-recipient-not-found = No s’ha trobat cap clau. Darrera cerca: { $date }
pgp-recipient-unusable = La clau no es pot fer servir: { $state }
pgp-recipients-intro = Inbox Classic farà servir les claus dels destinataris i la vostra per xifrar el missatge.
pgp-recipients-intro-missing = { $count ->
    [one] Falta una clau utilitzable per a un destinatari. Cerqueu la clau o traieu el destinatari del missatge. Només podeu enviar-lo sense xifrar si ja no conté text, imatges ni fitxers adjunts de missatges xifrats.
   *[other] Falten claus utilitzables per a { $count } destinataris. Cerqueu les claus o traieu aquests destinataris del missatge. Només podeu enviar-lo sense xifrar si ja no conté text, imatges ni fitxers adjunts de missatges xifrats.
}
pgp-details-part = Part { $number }: { $label }
pgp-details-signed = Data de la signatura: { $when }. Clau: { $key }
pgp-details-unknown-key = Signat amb la clau { $key }, que no teniu
pgp-details-opened = Desxifrat amb la vostra clau { $key }
pgp-details-for = Xifrat per a { $keys }
pgp-details-plain = Ni signat ni xifrat
pgp-bar-parts = Aquest missatge té { $count } parts: { $list }. Cada part indica com està protegida.
pgp-bar-count-verified = { $count ->
    [one] 1 verificada
   *[other] { $count } verificades
}
pgp-bar-count-good = { $count ->
    [one] 1 signada o xifrada
   *[other] { $count } signades o xifrades
}
pgp-bar-count-warning = { $count ->
    [one] 1 requereix atenció
   *[other] { $count } requereixen atenció
}
pgp-bar-count-neutral = { $count } sense signatura confirmada
# el fitxer de configuració: opcions, comptes, contactes i claus que es porten a un altre ordinador
setup-part-settings = Opcions
setup-part-preferences = Preferències de les finestres
setup-part-accounts = Comptes
setup-part-sign-in-apps = Aplicacions d’inici de sessió
setup-part-contacts = Contactes i grups
setup-part-keys = Claus de xifratge
setup-part-rules = Regles de missatge
setup-part-trusted-senders = Remitents de confiança
setup-holds-settings = { $count ->
    [one] 1 opció
   *[other] { $count } opcions
}
setup-holds-preferences = { $count ->
    [one] 1 preferència
   *[other] { $count } preferències
}
setup-holds-accounts = { $count ->
    [one] 1 compte
   *[other] { $count } comptes
}
setup-holds-sign-in-apps = { $count ->
    [one] 1 aplicació d’inici de sessió
   *[other] { $count } aplicacions d’inici de sessió
}
setup-holds-built-in = Quines aplicacions d’inici de sessió integrades estan activades
setup-holds-contacts = { $count ->
    [one] 1 contacte
   *[other] { $count } contactes
}
setup-holds-groups = { $count ->
    [one] 1 grup
   *[other] { $count } grups
}
setup-holds-own-keys = { $count ->
    [one] 1 clau pròpia
   *[other] { $count } claus pròpies
}
setup-holds-contact-keys = { $count ->
    [one] 1 clau d’un contacte
   *[other] { $count } claus de contactes
}
setup-holds-rules = { $count ->
    [one] 1 regla
   *[other] { $count } regles
}
setup-holds-trusted-senders = { $count ->
    [one] 1 remitent de confiança
   *[other] { $count } remitents de confiança
}
setup-sign-in-password = Contrasenya
setup-account-secret-password = La contrasenya està inclosa al fitxer.
setup-account-secret-token = Les credencials d’inici de sessió estan incloses al fitxer.
setup-account-asks-password = Haureu d’introduir la contrasenya després de la importació.
setup-account-signs-in-again = Hi haureu de tornar a iniciar la sessió després de la importació.
setup-account-here = Aquest compte ja està configurat aquí i no s’importarà.
setup-account-no-app = El compte fa servir l’aplicació { $app } per iniciar la sessió, però no està configurada en aquest ordinador. Importeu també les aplicacions d’inici de sessió.
setup-invalid-address = «{ $address }» no és una adreça electrònica.
setup-invalid-server = Comproveu el nom i el port del servidor { $server }: falten dades o no són vàlides.
setup-invalid-user = Falta el nom d’usuari.
setup-invalid-sign-in = El compte fa servir un mètode d’inici de sessió que Inbox Classic no reconeix.
setup-error-empty = El fitxer és buit.
setup-error-too-large = El fitxer és massa gran per ser un fitxer de configuració d’Inbox Classic.
setup-error-not-setup = Aquest no és un fitxer de configuració d’Inbox Classic.
setup-error-damaged = El fitxer de configuració està malmès i no es pot llegir.
setup-error-newer = Aquest fitxer de configuració s’ha desat amb una versió més nova d’Inbox Classic ({ $version }). Actualitzeu Inbox Classic i torneu-lo a importar.
setup-error-needs-passphrase = Aquest fitxer de configuració està protegit amb una frase de pas. Escriviu la frase de pas amb què es va desar.
setup-error-wrong-passphrase = La frase de pas no és la que es va fer servir per protegir aquest fitxer de configuració.
setup-error-changed = El fitxer de configuració s’ha modificat o malmès després de desar-lo, així que no es pot importar.
setup-error-read = No s’ha pogut llegir el fitxer de configuració: { $error }
setup-error-write = No s’ha pogut desar el fitxer de configuració: { $error }
setup-error-no-parts = Trieu almenys una secció.
setup-left-out = { $count ->
    [one] 1 entrada de la secció { $part } no es pot importar i s’ometrà.
   *[other] { $count } entrades de la secció { $part } no es poden importar i s’ometran.
}
setup-imported-settings = S’han substituït les opcions.
setup-imported-preferences = S’han substituït les preferències de les finestres.
setup-added-accounts = { $count ->
    [one] S’ha afegit 1 compte.
   *[other] S’han afegit { $count } comptes.
}
setup-skipped-here = El compte { $address } ja està configurat en aquest ordinador i no s’ha importat.
setup-skipped-no-app = No s’ha importat el compte { $address }: l’aplicació { $app } que fa servir per iniciar la sessió no està configurada en aquest ordinador.
setup-skipped-invalid = No s’ha importat el compte { $address }: { $reason }
setup-asks-password = Haureu d’introduir la contrasenya del compte { $address } quan es connecti.
setup-signs-in-again = Haureu de tornar a iniciar la sessió al compte { $address } quan es connecti.
setup-added-sign-in-apps = { $count ->
    [one] S’ha afegit 1 aplicació d’inici de sessió.
   *[other] S’han afegit { $count } aplicacions d’inici de sessió.
}
setup-skipped-sign-in-apps = { $count ->
    [one] 1 aplicació d’inici de sessió ja està configurada aquí.
   *[other] { $count } aplicacions d’inici de sessió ja estan configurades aquí.
}
setup-added-contacts = { $count ->
    [one] S’ha afegit 1 contacte a la Llibreta d’adreces.
   *[other] S’han afegit { $count } contactes a la Llibreta d’adreces.
}
setup-skipped-contacts = { $count ->
    [one] 1 contacte ja és a la Llibreta d’adreces.
   *[other] { $count } contactes ja són a la Llibreta d’adreces.
}
setup-added-groups = { $count ->
    [one] S’ha afegit o actualitzat 1 grup.
   *[other] S’han afegit o actualitzat { $count } grups.
}
setup-added-own-keys = { $count ->
    [one] S’ha afegit 1 clau pròpia.
   *[other] S’han afegit { $count } claus pròpies.
}
setup-added-contact-keys = { $count ->
    [one] S’ha afegit 1 clau d’un contacte.
   *[other] S’han afegit { $count } claus de contactes.
}
setup-added-rules = { $count ->
    [one] S’ha afegit 1 regla de missatge.
   *[other] S’han afegit { $count } regles de missatge.
}
setup-skipped-rules = { $count ->
    [one] 1 regla de missatge ja està configurada aquí.
   *[other] { $count } regles de missatge ja estan configurades aquí.
}
setup-skipped-rules-account = { $count ->
    [one] S’ha omès 1 regla de missatge perquè el seu compte no està configurat aquí.
   *[other] S’han omès { $count } regles de missatge perquè els seus comptes no estan configurats aquí.
}
setup-rules-waiting = { $count ->
    [one] La carpeta de destinació d’una regla de missatge s’identificarà després de sincronitzar el compte.
   *[other] Les carpetes de destinació de { $count } regles de missatge s’identificaran després de sincronitzar els comptes.
}
setup-added-trusted-senders = { $count ->
    [one] S’ha afegit 1 remitent de confiança.
   *[other] S’han afegit { $count } remitents de confiança.
}
setup-nothing = No s’ha importat res.
setup-account-servers = { $imap } i { $smtp } ({ $signin })
setup-file-name = Configuració i comptes d’Inbox Classic
setup-skipped-unreachable = No s’ha importat l’aplicació { $name }: no s’ha pogut connectar amb el seu servei d’inici de sessió. Torneu-la a afegir a Aplicacions d’inici de sessió.
attachment-runs-programs = «{ $name }» pot executar programes. Inbox Classic no permet obrir-lo directament, però podeu desar-lo i obrir-lo manualment si confieu en l’origen.
attachment-decrypted-note = Aquest fitxer adjunt prové d’un missatge xifrat. Per obrir-lo, Inbox Classic en desa una còpia sense xifrar en una carpeta temporal del vostre compte d’usuari. La còpia hi pot continuar després de tancar el programa que l’ha obert. En iniciar-se, Inbox Classic elimina d’aquesta carpeta les còpies de més d’un dia.
# a bar over the list when the server did not do what the user asked of messages, so they are as they were again
undone-move = { $count ->
    [one] El servidor no ha mogut { $messages } a { $folder }, així que torna a ser a { $from }: { $reason }
   *[other] El servidor no ha mogut { $messages } a { $folder }, així que tornen a ser a { $from }: { $reason }
}
undone-delete = { $count ->
    [one] El servidor no ha suprimit { $messages }, així que torna a ser a { $from }: { $reason }
   *[other] El servidor no ha suprimit { $messages }, així que tornen a ser a { $from }: { $reason }
}
undone-archive = { $count ->
    [one] El servidor no ha arxivat { $messages }, així que torna a ser a { $from }: { $reason }
   *[other] El servidor no ha arxivat { $messages }, així que tornen a ser a { $from }: { $reason }
}
undone-read = { $count ->
    [one] El servidor no ha marcat { $messages } com a llegit, així que torna a estar sense llegir: { $reason }
   *[other] El servidor no ha marcat { $messages } com a llegits, així que tornen a estar sense llegir: { $reason }
}
undone-unread = { $count ->
    [one] El servidor no ha marcat { $messages } com a no llegit, així que torna a figurar com a llegit: { $reason }
   *[other] El servidor no ha marcat { $messages } com a no llegits, així que tornen a figurar com a llegits: { $reason }
}
undone-flags = { $count ->
    [one] El servidor no ha canviat les banderes de { $messages }, per això s’ha desfet el canvi: { $reason }
   *[other] El servidor no ha canviat les banderes de { $messages }, per això s’ha desfet el canvi: { $reason }
}

## Previews of attachments: the pictures and PDF files shown in a message

# review: new
preview-pdf-option = Mostra els fitxers PDF als missatges
# review: new
preview-pdf-off = Els fitxers PDF no es mostren als missatges.
# review: new
preview-pdf-off-crashed = Un fitxer PDF ha tancat Inbox Classic mentre es mostrava, per això els fitxers PDF ja no es mostren als missatges. Les imatges sí. Per tornar a mostrar els fitxers PDF, activeu { $option } a { $settings }.
# review: new
preview-pdf-details = { $count ->
    [one] 1 pàgina, { $size }
   *[other] { $count } pàgines, { $size }
}
# review: new
preview-page-alt = { $name }, pàgina { $page } de { $count }
# review: new
preview-more-pages = { $count ->
    [one] Obriu-lo per veure la pàgina
   *[other] Obriu-lo per veure les { $count } pàgines
}
# review: new
preview-more-files = { $count ->
    [one] 1 fitxer més és a la llista de dalt
   *[other] { $count } fitxers més són a la llista de dalt
}
# review: new
preview-tile-downloading = S’està baixant…
# review: new
preview-tile-format = Les imatges { $format } encara no es mostren
# review: new
preview-tile-password = Protegit amb contrasenya: obre'l per introduir-la
# review: new
preview-tile-too-large = Massa gran per mostrar-lo
# review: new
preview-tile-unreadable = No es pot mostrar
# review: new
preview-tile-timed-out = Ha trigat massa a mostrar-se
# review: new
preview-tile-crashed = No es mostra: va tancar l’Inbox Classic una vegada
# review: new
preview-tile-off = No es mostra fins que l’Inbox Classic es torni a iniciar
# review: new
preview-not-printed = { $name } ({ $details }) no s’imprimeix. Obriu-lo per imprimir-lo.
