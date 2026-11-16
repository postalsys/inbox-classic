# El que diu el nucli, igual a totes les plataformes. Els codis entre { $claus } els omple el programa; cal mantenir-los,
# al lloc on la llengua els posa. Els plurals trien segons el nombre: [one] i *[other] en català.

## Comptadors i mides

# review: new
messages = { $count ->
    [one] 1 missatge
   *[other] { $count } missatges
}
# el separador decimal de les mides: 2,4 MB
# review: new
decimal-separator = ,
# review: new
size-bytes = { $count ->
    [one] 1 byte
   *[other] { $count } bytes
}
# review: new
size-kb = { $size } kB
# review: new
size-mb = { $size } MB
# review: new
size-gb = { $size } GB
# review: new
send-delay-off = Desactivat
# review: new
send-delay-seconds = { $count ->
    [one] 1 segon
   *[other] { $count } segons
}
# la barra d’estat: "12 missatges, 3 no llegits"
# review: new
list-counts = { $messages }, { $unread } no llegits
# review: new
list-counts-selected = { $messages }, { $unread } no llegits, { $selected } seleccionats
# la barra d’estat mentre es cerca: "12 trobats, 3 no llegits"
# review: new
list-counts-found = { $found } trobats, { $unread } no llegits
# review: new
list-counts-found-selected = { $found } trobats, { $unread } no llegits, { $selected } seleccionats
# review: new
list-counts-none = No s’ha trobat cap missatge

## Carpetes especials, com les anomena l’Outlook

# review: new
folder-inbox = Safata d’entrada
# review: new
folder-sent = Elements enviats
# review: new
folder-deleted = Elements suprimits
# review: new
folder-drafts = Esborranys
# review: new
folder-junk = Correu brossa
# review: new
folder-archive = Arxiu

## La subfinestra de lectura

# review: new
reader-no-message = No hi ha cap missatge seleccionat.
# review: new
reader-downloading = S’està baixant el missatge…
# review: new
reader-downloading-detail = El missatge apareixerà aquí quan s’acabi de baixar.
# review: new
reader-downloading-size = El missatge ocupa { $size }. Apareixerà aquí quan s’hagi baixat.
# review: new
reader-failed = No s’ha pogut baixar el missatge
# review: new
reader-failed-network = No s’ha pogut connectar amb el servidor de correu ({ $reason }).
# review: new
reader-failed-sign-in = El servidor de correu no ha acceptat l’inici de sessió ({ $reason }). Comproveu la contrasenya o torneu a iniciar la sessió a Fitxer > Comptes.
# review: new
reader-failed-security = No s’ha pogut establir una connexió segura amb el servidor de correu ({ $reason }).
# review: new
reader-failed-other = El servidor de correu ha respost: { $reason }.
# review: new
reader-retry-note = Es tornarà a provar quan el compte es torni a connectar.
# review: new
reader-unreadable = Aquest missatge no es pot mostrar: { $error }
# review: new
message-source-title = Codi font del missatge: { $subject }
# review: new
message-source-untitled = Codi font del missatge

## Imprimir un missatge, i la capçalera d’un missatge citat en una resposta o un reenviament

# review: new
header-from = De
# review: new
header-date = Data
# review: new
header-to = Per a
# review: new
header-cc = Cc
# review: new
header-sent = Enviat
# review: new
header-subject = Assumpte
# review: new
header-security = Seguretat
# review: new
header-part = Part { $number }
# review: new
quote-original = ----- Missatge original -----
# review: new
fold-show-earlier = Mostra els missatges anteriors

## Retorns: la targeta al capdamunt d’un avís que un missatge no s’ha lliurat

# review: new
bounce-failed = El vostre missatge no s’ha lliurat
# review: new
bounce-delayed = El vostre missatge encara no s’ha lliurat
# review: new
bounce-delayed-note = El vostre servidor de correu encara intenta lliurar-lo. No cal que el torneu a enviar.
# l’enllaç al missatge de què parla l’avís, a Elements enviats o a una altra carpeta
# review: new
bounce-show-message = Mostra el missatge retornat
# l’enllaç de la targeta d’un retard al missatge que encara és en camí
# review: new
bounce-show-delayed = Mostra el missatge endarrerit
# review: new
bounce-what-to-do = Què podeu fer:
# què fer amb un destinatari al qual el missatge encara va de camí: a la targeta d’un retard i a la d’un error
# review: new
bounce-delayed-do = De moment, res. Si finalment no es pot lliurar, rebreu un altre avís.
# review: new
bounce-delayed-row-do = De moment, res. El vostre servidor de correu encara intenta lliurar-lo, i rebreu un altre avís si no ho aconsegueix.
# plega les paraules del servidor que rep el missatge
# review: new
bounce-details = Detalls
# un destinatari que l’avís no anomena
# review: new
bounce-someone = Un destinatari
# a Detalls: el servidor que ha refusat el missatge, el codi d’estat que ha donat i el servidor que ha escrit l’avís
# review: new
bounce-server = Servidor: { $server }
# review: new
bounce-status = Estat: { $status }
# review: new
bounce-reported-by = Informat per: { $server }
# review: new
bounce-retry-minutes = El servidor de destinació ha demanat esperar { $count ->
    [one] un minut
   *[other] { $count } minuts
} abans del pròxim intent.
# review: new
bounce-retry-hours = El servidor de destinació ha demanat esperar { $count ->
    [one] una hora
   *[other] { $count } hores
} abans del pròxim intent.
# els noms de les llistes de bloqueig, "Spamhaus ZEN, Barracuda"
# review: new
bounce-blocklist = Llista de bloqueig: { $lists }
# review: new
bounce-user-unknown = L’adreça no existeix
# review: new
bounce-user-unknown-why = El servidor de destinació no té cap bústia amb aquesta adreça. Potser està mal escrita, o la persona ja no la fa servir.
# review: new
bounce-user-unknown-do = Comproveu com està escrita l’adreça, o demaneu a la persona l’adreça que fa servir ara.
# review: new
bounce-invalid-address = L’adreça no és vàlida
# review: new
bounce-invalid-address-why = L’adreça no està escrita d’una manera a la qual es pugui enviar correu.
# review: new
bounce-invalid-address-do = Busqueu errors d’escriptura, com ara un espai, una lletra que falta o res després de l’@.
# review: new
bounce-mailbox-disabled = La bústia està tancada
# review: new
bounce-mailbox-disabled-why = L’adreça existeix, però la seva bústia s’ha desactivat o ja no es fa servir.
# review: new
bounce-mailbox-disabled-do = Poseu-vos en contacte amb la persona d’una altra manera i demaneu-li una adreça que faci servir ara.
# review: new
bounce-mailbox-full = La bústia és plena
# review: new
bounce-mailbox-full-why = La bústia del destinatari no té espai per a correu nou.
# review: new
bounce-mailbox-full-do = Torneu-lo a enviar d’aquí a uns dies, o aviseu la persona d’una altra manera. Els fitxers adjunts grans són els primers que es refusen.
# review: new
bounce-spam-blocked = Refusat com a correu brossa
# review: new
bounce-spam-blocked-why = El servidor de destinació ha pres el missatge per correu brossa.
# review: new
bounce-spam-blocked-do = Torneu-lo a enviar sense allò que sembli correu brossa, com ara molts enllaços, enllaços escurçats o un fitxer adjunt gran. Si continua passant, pregunteu al vostre proveïdor de correu.
# review: new
bounce-virus-detected = Refusat per un virus
# review: new
bounce-virus-detected-why = El servidor de destinació ha trobat un virus o un altre contingut perillós al missatge o als seus fitxers adjunts.
# review: new
bounce-virus-detected-do = Comproveu els fitxers adjunts amb un antivirus. Alguns servidors refusen qualsevol programa o arxiu comprimit, així que compartiu aquests fitxers amb un enllaç.
# review: new
bounce-ip-blocklisted = El vostre servidor de correu és en una llista de bloqueig
# review: new
bounce-ip-blocklisted-why = El servidor de destinació refusa el correu del servidor que ha enviat el vostre, perquè l’adreça d’aquest servidor és en una llista de bloqueig.
# review: new
bounce-ip-blocklisted-do = El problema no és el missatge. Reenvieu aquest avís al vostre proveïdor de correu i demaneu-li que tregui el servidor de la llista.
# review: new
bounce-domain-blocklisted = Un domini és en una llista de bloqueig
# review: new
bounce-domain-blocklisted-why = El servidor de destinació refusa el missatge perquè el domini de la vostra adreça, o un domini dels enllaços del missatge, és en una llista de bloqueig.
# review: new
bounce-domain-blocklisted-do = Si el missatge té enllaços, proveu-lo sense. Si no, reenvieu aquest avís a qui gestioni el correu del vostre domini.
# review: new
bounce-policy-blocked = Refusat per les regles del servidor de destinació
# review: new
bounce-policy-blocked-why = Les regles del servidor de destinació no deixen passar aquest missatge, per exemple per la mida, els fitxers adjunts o el remitent.
# review: new
bounce-policy-blocked-do = Les paraules del mateix servidor a Detalls sovint en donen el motiu. Pregunteu al destinatari si pot acceptar aquest tipus de correu.
# review: new
bounce-geo-blocked = Refusat per la seva procedència
# review: new
bounce-geo-blocked-why = El servidor de destinació no accepta correu del país o la xarxa on és el vostre servidor de correu.
# review: new
bounce-geo-blocked-do = Poseu-vos en contacte amb la persona d’una altra manera, o pregunteu-ho al vostre proveïdor de correu.
# review: new
bounce-relay-denied = El servidor no l’ha volgut transmetre
# review: new
bounce-relay-denied-why = Un servidor ha refusat fer arribar el missatge més enllà, sovint perquè s’ha enviat sense iniciar la sessió o a través d’un servidor que no s’encarrega d’aquest destinatari.
# review: new
bounce-relay-denied-do = Comproveu el servidor de sortida del compte a Fitxer > Comptes, i que hi inicia la sessió.
# review: new
bounce-auth-failure = No s’ha pogut verificar la vostra adreça de remitent
# review: new
bounce-auth-failure-why = El servidor de destinació no ha pogut confirmar que el missatge vingués realment del vostre domini (SPF, DKIM o DMARC).
# review: new
bounce-auth-failure-do = Reenvieu aquest avís a qui gestioni el correu del vostre domini: cal corregir-ne la configuració. Mentrestant, pot ajudar enviar a través del servidor del vostre proveïdor.
# review: new
bounce-rate-limited = Massa correu alhora
# review: new
bounce-rate-limited-why = De moment, el servidor de destinació accepta menys missatges del vostre servidor de correu.
# review: new
bounce-rate-limited-do = Espereu una estona i torneu-lo a enviar. Quan escriviu a molta gent, envieu-lo a menys persones cada vegada.
# review: new
bounce-greylisting = Retingut un moment
# review: new
bounce-greylisting-why = El servidor de destinació demana als remitents desconeguts que ho tornin a provar una mica més tard, una comprovació habitual contra el correu brossa.
# review: new
bounce-greylisting-do = Res. Els servidors de correu ho tornen a provar tot sols, i el missatge sol arribar abans d’una hora.
# review: new
bounce-server-error = El servidor de destinació ha tingut un problema
# review: new
bounce-server-error-why = No s’ha pogut connectar amb el servidor de destinació, o no ha pogut acceptar el missatge per un problema propi.
# review: new
bounce-server-error-do = Torneu-lo a enviar més tard. Si continua fallant, comproveu que no hi hagi errors d’escriptura a la part de l’adreça que hi ha després de l’@.
# review: new
bounce-unknown = No lliurat
# review: new
bounce-unknown-why = L’avís no diu clarament per què.
# review: new
bounce-unknown-do = Les paraules del mateix servidor a Detalls potser en diuen més. Si no ajuden, reenvieu aquest avís al vostre proveïdor de correu.

## Diversos missatges seleccionats

# review: new
selection-title = { $count ->
    [one] 1 missatge seleccionat
   *[other] { $count } missatges seleccionats
}
# review: new
selection-unread = { $count } no llegits
# review: new
selection-flagged = { $count } amb bandera
# review: new
delete-for-good-one = Aquest missatge se suprimirà definitivament. Voleu suprimir-lo?
# review: new
delete-for-good-all = Aquests { $count } missatges se suprimiran definitivament. Voleu suprimir-los?
# review: new
delete-for-good-some = { $count } dels { $total } missatges se suprimiran definitivament. Voleu suprimir els missatges?
# review: new
done-read = { $count ->
    [one] Marcat com a llegit: { $messages }
   *[other] Marcats com a llegits: { $messages }
}
# review: new
done-unread = { $count ->
    [one] Marcat com a no llegit: { $messages }
   *[other] Marcats com a no llegits: { $messages }
}
# review: new
done-flagged = { $count ->
    [one] Marcat amb bandera: { $messages }
   *[other] Marcats amb bandera: { $messages }
}
# review: new
done-unflagged = S’ha tret la bandera: { $messages }
# review: new
done-deleted-for-good = { $count ->
    [one] Suprimit definitivament: { $messages }
   *[other] Suprimits definitivament: { $messages }
}
# review: new
done-archived = { $count ->
    [one] Arxivat: { $messages }
   *[other] Arxivats: { $messages }
}
# review: new
done-moved = { $count ->
    [one] { $messages } mogut a { $folder }
   *[other] { $messages } moguts a { $folder }
}
# review: new
done-copied = { $count ->
    [one] { $messages } copiat a { $folder }
   *[other] { $messages } copiats a { $folder }
}
# review: new
done-moving = { $count ->
    [one] S’està movent { $messages } a { $folder }...
   *[other] S’estan movent { $messages } a { $folder }...
}
# review: new
done-copying = { $count ->
    [one] S’està copiant { $messages } a { $folder }...
   *[other] S’estan copiant { $messages } a { $folder }...
}
# review: new
done-moved-back = { $count ->
    [one] { $messages } retornat a { $folder }
   *[other] { $messages } retornats a { $folder }
}
# la barra d’estat després de Segueix la conversa i Ignora la conversa, i després de tornar-les a triar en una de marcada
# review: new
done-watched = { $count ->
    [one] Se segueix la conversa
   *[other] Se segueixen { $count } converses
}
# review: new
done-unwatched = { $count ->
    [one] S’ha deixat de seguir la conversa
   *[other] S’han deixat de seguir { $count } converses
}
# review: new
done-ignored = { $count ->
    [one] S’ignora la conversa
   *[other] S’ignoren { $count } converses
}
# review: new
done-unignored = { $count ->
    [one] S’ha deixat d’ignorar la conversa
   *[other] S’han deixat d’ignorar { $count } converses
}
# review: new
their-folders = les seves carpetes
# review: new
undo-move = Desfés el moviment
# review: new
undo-delete = Desfés la supressió
# review: new
undo-archive = Desfés l’arxivament
# review: new
undo-junk = Desfés Marca com a brossa
# review: new
undo-not-junk = Desfés Marca com a no brossa
# review: new
undo-send = Desfés l’enviament
# review: new
nothing-to-undo = No hi ha res per desfer.
# review: new
messages-gone = Els missatges ja no hi són.
# Una carpeta IMAP no seleccionable no pot contenir missatges; no vol dir que sigui buida.
# review: new
folder-holds-no-messages = Aquesta carpeta no pot contenir missatges.
# review: new
not-archived-here = Els missatges d’aquesta carpeta no es poden arxivar.
# review: new
not-emptied-here = Només es poden buidar Elements suprimits i Correu brossa.
# review: new
next-unread-question = No hi ha més missatges no llegits a { $folder }.

    Voleu anar a { $next }, la carpeta següent amb missatges no llegits?
# review: new
no-unread-left = No queda cap missatge no llegit.
# review: new
empty-question = { $count ->
    [one] Voleu buidar { $folder }?

        El missatge que conté se suprimirà definitivament. No es podrà recuperar.
   *[other] Voleu buidar { $folder }?

        Els { $messages } que conté se suprimiran definitivament. No es podran recuperar.
}
# review: new
no-junk-folder = Aquest compte no té cap carpeta Correu brossa on moure els missatges.
# review: new
no-inbox-folder = Aquest compte no té cap carpeta Safata d’entrada on moure els missatges.
# la barra d’estat després d’una bandera de color: "2 missatges amb bandera blava"
# review: new
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
# review: new
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

# review: new
move-window-title-move = { $count ->
    [one] Mou el missatge
   *[other] Mou { $count } missatges
}
# review: new
move-window-title-copy = { $count ->
    [one] Copia el missatge
   *[other] Copia { $count } missatges
}
# review: new
move-window-prompt-move = { $count ->
    [one] Mou el missatge seleccionat a:
   *[other] Mou els { $count } missatges seleccionats a:
}
# review: new
move-window-prompt-copy = { $count ->
    [one] Copia el missatge seleccionat a:
   *[other] Copia els { $count } missatges seleccionats a:
}
# les carpetes usades darrerament, damunt de l’arbre de carpetes
# review: new
targets-recent = Recents
# la carpeta on són els missatges, que no es pot triar
# review: new
target-current = { $folder } (actual)
# una carpeta usada darrerament, amb el seu compte quan n’hi ha diversos: "Arxiu (Feina)"
# review: new
target-recent = { $folder } ({ $account })

## Moure i copiar a un altre compte

# review: new
transfer-moving = S’estan movent { $done } de { $messages } a { $folder }...
# review: new
transfer-copying = S’estan copiant { $done } de { $messages } a { $folder }...
# review: new
transfer-another-account = un altre compte
# review: new
transfer-folder-gone = la carpeta de destinació ja no hi és
# review: new
transfer-not-on-server = el missatge ja no és al servidor
# review: new
transfer-not-moved = { $count ->
    [one] No s’ha pogut moure a un altre compte: { $messages } ({ $reason })
   *[other] No s’han pogut moure a un altre compte: { $messages } ({ $reason })
}
# review: new
transfer-not-copied = { $count ->
    [one] No s’ha pogut copiar a un altre compte: { $messages } ({ $reason })
   *[other] No s’han pogut copiar a un altre compte: { $messages } ({ $reason })
}
# review: new
transfer-none-moved = No s’ha pogut moure cap missatge
# review: new
transfer-none-copied = No s’ha pogut copiar cap missatge

## Missatges com a fitxers

# review: new
export-not-in-time = el missatge no s’ha pogut baixar a temps
# review: new
export-not-saved = No s’han pogut desar { $failed } de { $messages } ({ $problems })
# review: new
export-not-attached = no s’han pogut adjuntar els missatges: { $error }
# la barra d’estat després de Desa com a amb diversos: "Desats a Escriptori: 3 missatges"
# review: new
saved-to = { $count ->
    [one] Desat a { $folder }: { $messages }
   *[other] Desats a { $folder }: { $messages }
}
# review: new
download-progress = S’està baixant { $done } de { $total }
# review: new
download-done = S’han baixat { $size }
# review: new
downloading-messages = { $count ->
    [one] S’està baixant { $messages }...
   *[other] S’estan baixant { $messages }...
}
# la barra d’estat després de deixar anar fitxers en una carpeta: "Posats a Arxiu: 3 missatges"
# review: new
import-put = { $count ->
    [one] Posat a { $folder }: { $messages }
   *[other] Posats a { $folder }: { $messages }
}
# review: new
import-not-put = Aquests no s’han posat a la carpeta:

    { $problems }

## Problemes que mostren les finestres

# review: new
error-store = emmagatzematge local: { $error }
# review: new
error-not-found = no s’ha trobat
# review: new
error-closed = s’està tancant
# review: new
error-other-account = el navegador ha iniciat la sessió amb { $email }, no amb aquest compte
# una contrasenya o un inici de sessió que el servidor de correu ha refusat, amb les paraules del servidor
# review: new
failure-authentication = el servidor no ha acceptat l’inici de sessió ({ $reason })
# no s’ha pogut connectar amb el servidor de correu o la connexió s’ha tallat, amb el motiu
# review: new
failure-network = la connexió amb el servidor ha fallat ({ $reason })
# review: new
error-in-use = no es pot suprimir mentre hi hagi comptes que l’utilitzin per iniciar la sessió: { $accounts }
# review: new
error-turned-off = aquesta aplicació d’inici de sessió està desactivada per als comptes nous
# review: new
error-folder-name = el nom de la carpeta ha de tenir entre 1 i 200 caràcters i no pot contenir caràcters de control
# review: new
error-folder-separator = en aquest servidor, un nom de carpeta no pot contenir «{ $separator }»
# review: new
error-folder-special = la Safata d’entrada i les carpetes especials no es poden canviar de nom ni suprimir
# review: new
error-no-recipients = el missatge no té destinataris
# review: new
error-bad-address = «{ $address }» no és una adreça electrònica
# review: new
error-not-own-address = { $address } no és cap de les adreces de remitent d’aquest compte. Afegiu-la a «Altres adreces des de les quals envieu» a les propietats del compte.
# review: new
rule-query-refused = Les regles no poden filtrar per carpeta ni per data ({ $words }).
# review: new
rule-no-query = Introduïu els criteris de cerca per als missatges entrants.
# review: new
rule-no-action = Trieu almenys una acció per a la regla.
# review: new
error-attachment = No s’ha pogut llegir { $path }: { $error }
# review: new
error-no-drafts = el compte no té cap carpeta Esborranys on desar el missatge
# review: new
error-draft-attachment = no s’ha pogut conservar un fitxer adjunt de l’esborrany: { $error }
# review: new
error-password-not-saved = no s’ha pogut desar la contrasenya per a la propera vegada: { $error }
# review: new
error-sign-in-not-saved = no s’han pogut desar les noves dades d’inici de sessió per a la propera vegada: { $error }
# review: new
error-import-unreadable = No es pot llegir { $path }: { $error }
# review: new
error-import-too-large = { $path } ocupa més de 50 MB
# review: new
error-import-not-mail = { $path } no és un missatge de correu electrònic
# review: new
error-list-answered = el servidor de la llista de correu ha retornat l’estat { $status }
# review: new
error-not-built = no s’ha pogut construir el missatge
# review: new
error-outbox-waits = { $count ->
    [one] el missatge espera a la Safata de sortida i s’enviarà amb el proper Envia/Rep
   *[other] { $count } missatges esperen a la Safata de sortida i s’enviaran amb el proper Envia/Rep
}
# review: new
error-draft-not-removed = no s’ha pogut treure l’esborrany anterior del missatge d’Esborranys: { $reason }
# review: new
error-sent-but = el missatge s’ha enviat, però { $problem }
# review: new
error-sent-still-in-outbox = encara és a la Safata de sortida: { $error }
# review: new
error-sent-no-copy = no s’ha pogut desar cap còpia a Elements enviats: { $reason }
# review: new
error-no-password = aquest compte no té contrasenya
# review: new
error-no-sign-in = aquest compte no té inici de sessió
# review: new
error-provider-missing = aquesta versió no pot iniciar la sessió a { $provider }: potser se n’ha suprimit l’aplicació d’inici de sessió?
# review: new
error-provider-servers = els servidors d’aquest compte no coincideixen amb els de la seva aplicació d’inici de sessió
# review: new
error-app-scopes = { $reason }. El servidor de correu no ha acceptat el testimoni de l’aplicació d’inici de sessió: comproveu que els permisos (scopes) de l’aplicació donin accés al correu
# review: new
error-in-folder = { $folder }: { $reason }

## Aplicacions d’inici de sessió

# review: new
sign-in-off-google = Google encara no ha verificat Inbox Classic, així que només hi deixa iniciar la sessió als usuaris de prova. Feu servir la vostra pròpia aplicació d’inici de sessió de Google o una contrasenya d’aplicació, o activeu-la a Aplicacions d’inici de sessió (Fitxer > Comptes) si sou un usuari de prova.
# review: new
sign-in-off-other = Es va desactivar a Aplicacions d’inici de sessió (Fitxer > Comptes), on es pot tornar a activar.
# review: new
sign-in-app-no-name = l’aplicació d’inici de sessió necessita un nom
# review: new
sign-in-app-no-client = falta l’identificador de client
# review: new
sign-in-app-no-scopes = l’aplicació d’inici de sessió necessita els permisos (scopes) que donen accés al correu
# review: new
sign-in-app-bad-host = falta l’adreça del servidor { $server } o no és un nom d’amfitrió vàlid
# review: new
sign-in-app-plain = el servidor { $server } ha d’utilitzar SSL/TLS o STARTTLS
# review: new
sign-in-app-not-checked = encara no s’ha comprovat l’emissor
# review: new
sign-in-app-issuer-changed = l’emissor ha canviat: torneu a escriure el secret de client, o suprimiu-lo
# review: new
sign-in-register-google = A la Google Cloud Console, creeu un client OAuth del tipus «Aplicació d’escriptori», amb l’abast https://mail.google.com/ a la pantalla de consentiment. Mentre l’aplicació és en proves, només hi poden iniciar la sessió els seus usuaris de prova.
# review: new
sign-in-register-microsoft = A Microsoft Entra, registreu una aplicació amb la plataforma «Aplicacions mòbils i d’escriptori», l’URI de redirecció http://localhost i els fluxos de client públic permesos, i els permisos delegats IMAP.AccessAsUser.All, SMTP.Send i offline_access. Només per a la vostra organització, feu servir https://login.microsoftonline.com/<tenant ID>/v2.0 com a emissor.
# review: new
sign-in-register-other = Registreu un client natiu (públic) amb l’URI de redirecció de sota; el proveïdor hi ha de permetre qualsevol port (RFC 8252). Afegiu-hi l’abast amb què el proveïdor dona accés al correu.

## Invitacions de calendari

# review: new
repeats = Es repeteix
# review: new
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
# review: new
repeats-on = { $repeats } els dies { $days }
# "Cada setmana, 10 vegades"
# review: new
repeats-times = { $count ->
    [one] { $repeats }, una vegada
   *[other] { $repeats }, { $count } vegades
}
# review: new
day-monday = dilluns
# review: new
day-tuesday = dimarts
# review: new
day-wednesday = dimecres
# review: new
day-thursday = dijous
# review: new
day-friday = divendres
# review: new
day-saturday = dissabte
# review: new
day-sunday = diumenge

## Agents d’IA

# review: new
agent-level-read = Llegir el correu: carpetes, llista de missatges, cerca i missatges
# review: new
agent-level-organize = Organitzar el correu: estat de lectura, banderes, correu brossa, moure, suprimir a Elements suprimits
# review: new
agent-level-drafts = Escriure esborranys perquè els envieu vós
# review: new
agent-level-send = Enviar correu, cada missatge només després que digueu que sí
# review: new
agent-connect-title = { $program } vol fer servir el vostre correu
# review: new
agent-connect-detail = Un agent d’IA ha demanat treballar amb Inbox Classic. Trieu què pot fer i quins comptes pot veure; ho podreu canviar més endavant a Eines > Agents d’IA.

    Els agents llegeixen correu que han escrit altres persones, i un missatge pot intentar enganyar-los. Inbox Classic sempre us ho demana abans que un agent enviï res.
# review: new
agent-reply-to = Resposta a «{ $subject }»
# review: new
agent-reply-all-on = Resposta a tots a «{ $subject }»
# review: new
agent-forward-of = Reenviament de «{ $subject }»
# review: new
agent-never-written-one = No heu escrit mai a { $address }.
# review: new
agent-never-written-many = No heu escrit mai a { $count } d’aquestes adreces.
# review: new
agent-send-title = { $program } vol enviar aquest missatge
# review: new
agent-send-detail = Comproveu els destinataris i el contingut del missatge. Quan ho confirmeu, el missatge esperarà { $seconds } segons a la Safata de sortida, on encara el podreu suprimir.
# review: new
agent-change-title = Què pot fer { $program }
# review: new
agent-change-allowed = Canvieu què poden fer amb el vostre correu els agents d’IA d’aquest programa.
# review: new
agent-change-refused = Heu denegat l’accés a aquest programa. Permeteu-lo per tornar a donar als seus agents accés al vostre correu.
# review: new
agent-log-taken-back = { $entry } (desfet)
# review: new
agent-files = Fitxers: { $files }
# review: new
agent-undo-refused = No es pot desfer.
# review: new
agent-undo-refused-why = No es pot desfer: { $reason }.
# review: new
agent-undo-impossible = això no es pot desfer
# review: new
agent-undo-not-in-folder = el missatge ja no és en aquella carpeta
# review: new
agent-undo-not-arrived = el missatge no és (encara) a la carpeta on ha anat
# review: new
agent-undo-sent = el missatge ja s’ha enviat
# review: new
agent-original-not-downloaded = el missatge original encara no s’ha baixat. Obriu-lo primer
# review: new
agent-turned-away = Rebutjat
# review: new
agent-can-nothing = Res
# review: new
agent-can-read = llegir
# review: new
agent-can-organize = organitzar
# review: new
agent-can-drafts = escriure esborranys
# review: new
agent-can-send = enviar amb el vostre sí
# "Llegir, organitzar i escriure esborranys"
# review: new
agent-can-list = { $first } i { $last }
# review: new
agent-accounts = { $count ->
    [0] cap compte
    [one] 1 compte
   *[other] { $count } comptes
}
# "Llegir i organitzar; 1 compte"
# review: new
agent-access = { $can }; { $accounts }
# review: new
agent-unreadable = Aquest missatge no es pot llegir.
# review: new
agent-encrypted-original = Aquest missatge està xifrat: un agent no hi pot respondre ni reenviar-lo, perquè no pot xifrar.
# review: new
agent-log-composed = Ha obert «{ $subject }» en un missatge nou perquè l’acabeu
# review: new
agent-log-refused = No heu enviat «{ $subject }»
# review: new
agent-log-sent = Ha enviat «{ $subject }» a { $to }
# review: new
agent-log-draft = Ha desat l’esborrany «{ $subject }»
# review: new
agent-log-read = Ha marcat com a llegit «{ $subject }»
# review: new
agent-log-unread = Ha marcat com a no llegit «{ $subject }»
# review: new
agent-log-flagged = Ha posat la bandera a «{ $subject }»
# review: new
agent-log-unflagged = Ha tret la bandera de «{ $subject }»
# review: new
agent-log-deleted = Ha suprimit «{ $subject }»
# review: new
agent-log-moved = Ha mogut «{ $subject }» a { $folder }
# review: new
agent-log-junk = Ha marcat «{ $subject }» com a brossa
# review: new
agent-log-not-junk = Ha marcat «{ $subject }» com a no brossa
# review: new
agent-log-archived = Ha arxivat «{ $subject }»
# review: new
agent-log-folder = Ha creat la carpeta «{ $name }»
# review: new
agent-log-unsubscribed = S’ha donat de baixa de la llista de «{ $subject }»

## Les tecles com les anomenen els teclats de la llengua, a l’ajuda (Windows i Linux)

# review: new
key-ctrl = Ctrl
# review: new
key-alt = Alt
# review: new
key-shift = Maj
# review: new
key-del = Supr
# review: new
key-enter = Retorn

## Iniciar la sessió i contrasenyes

# review: new
sign-in-no-refresh = el proveïdor no ha donat cap testimoni d’actualització
# review: new
sign-in-no-account = el proveïdor no ha dit quin compte ha iniciat la sessió
# review: new
sign-in-not-finished = l’inici de sessió no ha acabat
# review: new
secrets-unavailable = { $store } no està disponible
# review: new
secrets-unavailable-why = { $store } no està disponible: { $error }
# review: new
secrets-windows = l’Administrador de credencials
# review: new
secrets-mac = el clauer
# review: new
secrets-linux = l’anell de claus del sistema (Secret Service)
# review: new
error-no-such-file = no existeix aquest fitxer
# review: new
cards-file-too-big = Aquest fitxer és massa gran per ser una llibreta d’adreces.
# review: new
ui-sender-added = S’ha afegit { $name } a la Llibreta d’adreces.
# review: new
ui-sender-known = { $name } ja és a la Llibreta d’adreces.
# review: new
ui-sender-none = El remitent d’aquest missatge no té cap adreça electrònica per afegir.
# review: new
card-name-needed = El contacte no té nom ni adreça electrònica.
# un fitxer d’Importa la llibreta d’adreces que no s’ha pogut llegir: "contactes.vcf: no existeix aquest fitxer"
# review: new
cards-file-failed = { $file }: { $reason }

## Codis d’un sol ús: la targeta al capdamunt d’un missatge amb un codi d’inici de sessió o de verificació

# el domini per al qual és el codi, que ha signat el missatge
# review: new
otp-heading = Codi per a { $domain }
# review: new
otp-copy = Copia
# review: new
otp-note = Introduïu-lo només en una pàgina del domini { $domain }.
# review: new
otp-old = Aquest codi es va enviar més d’una hora abans que l’obríssiu, i probablement ha caducat.

# quantes persones estan convidades, a la targeta d’un esdeveniment
# review: new
event-attendees =
    { $count ->
        [one] { $count } assistent
       *[other] { $count } assistents
    }

# la primera línia de la notificació d’un missatge nou quan té un codi, per a un domini que l’ha signat
# review: new
otp-notification = { $code } és el vostre codi per a { $domain }

## Claus OpenPGP (keys.rs)
# review: new
pgp-key-valid = Vàlida
# review: new
pgp-key-expires = Vàlida fins al { $date }
# review: new
pgp-key-expired = Va caducar el { $date }
# review: new
pgp-key-revoked = Revocada
# review: new
pgp-key-revoked-why = Revocada: { $reason }
# review: new
pgp-key-not-valid = No vàlida
# review: new
pgp-key-locked = No es pot fer servir: la clau que la protegeix ja no és a { $store }. Torneu a importar-ne la còpia de seguretat.
# review: new
pgp-source-own = Creada a Inbox Classic
# review: new
pgp-source-file = Importada d’un fitxer
# review: new
pgp-source-paste = Enganxada
# review: new
pgp-source-attachment = D’un missatge
# review: new
pgp-source-vcard = D’una targeta de contacte
# review: new
pgp-source-wkd = Del proveïdor de correu del remitent
# review: new
pgp-source-keyserver = De keys.openpgp.org
# review: new
pgp-source-autocrypt = De la capçalera Autocrypt d’un missatge
# review: new
pgp-error-no-store = Les claus privades estan protegides per { $store }, que no es pot fer servir: { $error }
# review: new
pgp-error-wrong-passphrase = La frase de pas no és correcta.
# review: new
pgp-error-not-a-key = Això no és una clau OpenPGP.
# review: new
pgp-error-too-large = La clau és massa gran.
# review: new
pgp-error-unusable = La clau fa servir una criptografia antiga o feble i no es pot utilitzar.
# review: new
pgp-imported-private = { $count ->
    [one] S’ha importat la vostra clau privada.
   *[other] S’han importat { $count } claus privades.
}
# review: new
pgp-imported-public = { $count ->
    [one] S’ha importat una clau.
   *[other] S’han importat { $count } claus.
}
# review: new
pgp-imported-pending = Ja s’utilitza una altra clau per a { $addresses }: la nova espera al contacte fins que la trieu.
# review: new
pgp-error-needs-passphrase = La clau privada està protegida amb una frase de pas. Escriviu-la per importar la clau.
# review: new
pgp-error-mismatch = La clau privada no correspon a la seva clau pública. Pot ser que s’hagi alterat.
# review: new
pgp-file-name-public = Clau pública, { $who }.asc
# review: new
pgp-file-name-private = Còpia de seguretat de la clau privada, { $who }.asc
# review: new
pgp-pending = El { $date } es va trobar una clau diferent per a { $address }.

## Llegir correu signat i xifrat (protect.rs)
# review: new
pgp-part-verified = Signat per { $signer }, clau verificada
# review: new
pgp-part-signed = Signat per { $signer } (clau no verificada)
# review: new
pgp-part-other = Signat per { $signer }, que no és el remitent
# review: new
pgp-part-unknown-key = Signat, però la clau és desconeguda
# review: new
pgp-part-not-signed = No signat
# review: new
pgp-part-not-checked = Signatura no comprovada
# review: new
pgp-part-encrypted = Xifrat. { $signature }
# review: new
pgp-part-no-key = Xifrat amb una clau que no teniu
# review: new
pgp-part-changed = La part xifrada s’ha modificat pel camí i no es mostra
# review: new
pgp-part-unprotected = Xifrat sense protecció contra modificacions, no es mostra
# review: new
pgp-part-broken = La part xifrada no es pot llegir
# review: new
pgp-why-mismatch = La signatura no correspon a aquest text
# review: new
pgp-why-weak-hash = La signatura fa servir { $hash }, que ja no és segur
# review: new
pgp-why-key-expired = Signat després que la clau caduqués el { $date }
# review: new
pgp-why-key-revoked = Signat amb una clau revocada
# review: new
pgp-why-not-signing-key = Signat amb una clau que no pot signar
# review: new
pgp-why-from-future = La signatura té una data futura
# review: new
pgp-why-signature-expired = La signatura ha caducat
# review: new
pgp-why-key-not-valid = Signat amb una clau que no és vàlida
# review: new
pgp-why-not-for-you = Signat per a altres destinataris, i reenviat a vós
# review: new
pgp-part-pictures-loaded = { $label }. S’han carregat imatges d’internet
# review: new
pgp-error-no-own-key = No teniu cap clau per a { $address } amb què signar o xifrar. Creeu-ne una a Eines > Claus de xifratge, o desactiveu Signa i Xifra.
# review: new
pgp-error-missing-keys = { $count ->
    [one] { $addresses } no té cap clau amb què xifrar.
   *[other] Aquests destinataris no tenen cap clau amb què xifrar: { $addresses }.
}
# review: new
pgp-error-encrypted-quote = Aquest missatge cita o reenvia un missatge xifrat, així que només es pot enviar xifrat. Activeu Xifra, o suprimiu el text citat.
# review: new
pgp-error-protect = No s’ha pogut signar ni xifrar el missatge: { $reason }
# review: new
pgp-found-keys = S’ha trobat la clau de: { $addresses }.
# review: new
pgp-found-none = No s’ha trobat cap clau per a { $addresses }. Demaneu-los que us enviïn la seva clau pública.
# review: new
pgp-found-no-key = No s’ha trobat cap clau.
# review: new
pgp-find-unavailable = Ara no es poden cercar claus: { $error }
# review: new
pgp-publish-pending = keys.openpgp.org ha enviat un enllaç de confirmació a { $addresses }. La vostra clau s’hi publicarà quan hi feu clic.
# review: new
pgp-publish-done = La vostra clau està publicada a keys.openpgp.org per a { $addresses }.
# review: new
pgp-publish-failed = No s’ha pogut publicar la clau: { $error }
# review: new
pgp-keyserver-off = La cerca de claus a keys.openpgp.org està desactivada a Opcions.
# review: new
pgp-details-part = Part { $number }: { $label }
# review: new
pgp-details-signed = Signat { $when } amb la clau { $key }
# review: new
pgp-details-unknown-key = Signat amb la clau { $key }, que no teniu
# review: new
pgp-details-opened = Xifrat amb la vostra clau { $key }
# review: new
pgp-details-for = Xifrat per a { $keys }
# review: new
pgp-details-plain = Ni signat ni xifrat
# review: new
pgp-bar-parts = Aquest missatge té { $count } parts: { $list }. Cada part indica com està protegida.
# review: new
pgp-bar-count-verified = { $count } verificades
# review: new
pgp-bar-count-good = { $count ->
    [one] 1 signada o xifrada
   *[other] { $count } signades o xifrades
}
# review: new
pgp-bar-count-warning = { $count ->
    [one] 1 requereix atenció
   *[other] { $count } requereixen atenció
}
# review: new
pgp-bar-count-neutral = { $count } sense signatura confirmada
# el fitxer de configuració: opcions, comptes, contactes i claus que es porten a un altre ordinador
# review: new
setup-part-settings = Opcions
# review: new
setup-part-preferences = Preferències de les finestres
# review: new
setup-part-accounts = Comptes
# review: new
setup-part-sign-in-apps = Aplicacions d’inici de sessió
# review: new
setup-part-contacts = Contactes i grups
# review: new
setup-part-keys = Claus de xifratge
# review: new
setup-part-rules = Regles de missatges
# review: new
setup-part-trusted-senders = Remitents de confiança
# review: new
setup-holds-settings = { $count ->
    [one] 1 opció
   *[other] { $count } opcions
}
# review: new
setup-holds-preferences = { $count ->
    [one] 1 preferència
   *[other] { $count } preferències
}
# review: new
setup-holds-accounts = { $count ->
    [one] 1 compte
   *[other] { $count } comptes
}
# review: new
setup-holds-sign-in-apps = { $count ->
    [one] 1 aplicació d’inici de sessió
   *[other] { $count } aplicacions d’inici de sessió
}
# review: new
setup-holds-built-in = Quines aplicacions d’inici de sessió integrades estan activades
# review: new
setup-holds-contacts = { $count ->
    [one] 1 contacte
   *[other] { $count } contactes
}
# review: new
setup-holds-groups = { $count ->
    [one] 1 grup
   *[other] { $count } grups
}
# review: new
setup-holds-own-keys = { $count ->
    [one] 1 clau pròpia
   *[other] { $count } claus pròpies
}
# review: new
setup-holds-contact-keys = { $count ->
    [one] 1 clau d’un contacte
   *[other] { $count } claus de contactes
}
# review: new
setup-holds-rules = { $count ->
    [one] 1 regla
   *[other] { $count } regles
}
# review: new
setup-holds-trusted-senders = { $count ->
    [one] 1 remitent de confiança
   *[other] { $count } remitents de confiança
}
# review: new
setup-sign-in-password = Contrasenya
# review: new
setup-account-secret-password = La seva contrasenya és al fitxer.
# review: new
setup-account-secret-token = El seu inici de sessió és al fitxer.
# review: new
setup-account-asks-password = Demanarà la contrasenya després de la importació.
# review: new
setup-account-signs-in-again = Hi haureu de tornar a iniciar la sessió després de la importació.
# review: new
setup-account-here = Ja està configurat aquí, així que s’omet.
# review: new
setup-account-no-app = Inicia la sessió amb { $app }, que no està configurada aquí. Importeu també les aplicacions d’inici de sessió.
# review: new
setup-invalid-address = «{ $address }» no és una adreça electrònica.
# review: new
setup-invalid-server = El servidor { $server } no té cap nom o port utilitzable.
# review: new
setup-invalid-user = No té nom d’usuari.
# review: new
setup-invalid-sign-in = Inicia la sessió d’una manera que Inbox Classic no coneix.
# review: new
setup-error-empty = El fitxer és buit.
# review: new
setup-error-too-large = El fitxer és massa gran per ser una configuració d’Inbox Classic.
# review: new
setup-error-not-setup = Aquest fitxer no és una configuració d’Inbox Classic.
# review: new
setup-error-damaged = El fitxer de configuració està malmès i no es pot llegir.
# review: new
setup-error-newer = Aquesta configuració l’ha desada una versió més nova d’Inbox Classic ({ $version }). Actualitzeu Inbox Classic i torneu-la a importar.
# review: new
setup-error-needs-passphrase = Aquesta configuració està protegida amb una frase de pas. Escriviu la frase de pas amb què es va desar.
# review: new
setup-error-wrong-passphrase = Aquesta no és la frase de pas amb què es va desar aquesta configuració.
# review: new
setup-error-changed = El fitxer de configuració s’ha modificat o malmès després de desar-lo, així que no es pot importar.
# review: new
setup-error-read = No s’ha pogut llegir el fitxer de configuració: { $error }
# review: new
setup-error-write = No s’ha pogut desar la configuració: { $error }
# review: new
setup-error-no-parts = Trieu almenys una part.
# review: new
setup-left-out = { $count ->
    [one] 1 entrada de la part { $part } no es pot fer servir i s’omet.
   *[other] { $count } entrades de la part { $part } no es poden fer servir i s’ometen.
}
# review: new
setup-imported-settings = S’han substituït les opcions.
# review: new
setup-imported-preferences = S’han substituït les preferències de les finestres.
# review: new
setup-added-accounts = { $count ->
    [one] S’ha afegit 1 compte.
   *[other] S’han afegit { $count } comptes.
}
# review: new
setup-skipped-here = { $address } ja està configurat aquí, així que s’ha omès.
# review: new
setup-skipped-no-app = S’ha omès { $address }: inicia la sessió amb { $app }, que no està configurada aquí.
# review: new
setup-skipped-invalid = S’ha omès { $address }: { $reason }
# review: new
setup-asks-password = { $address } demanarà la contrasenya quan es connecti.
# review: new
setup-signs-in-again = { $address } us demanarà que torneu a iniciar la sessió quan es connecti.
# review: new
setup-added-sign-in-apps = { $count ->
    [one] S’ha afegit 1 aplicació d’inici de sessió.
   *[other] S’han afegit { $count } aplicacions d’inici de sessió.
}
# review: new
setup-skipped-sign-in-apps = { $count ->
    [one] 1 aplicació d’inici de sessió ja està configurada aquí.
   *[other] { $count } aplicacions d’inici de sessió ja estan configurades aquí.
}
# review: new
setup-added-contacts = { $count ->
    [one] S’ha afegit 1 contacte a la llibreta d’adreces.
   *[other] S’han afegit { $count } contactes a la llibreta d’adreces.
}
# review: new
setup-skipped-contacts = { $count ->
    [one] 1 contacte ja és a la llibreta d’adreces.
   *[other] { $count } contactes ja són a la llibreta d’adreces.
}
# review: new
setup-added-groups = { $count ->
    [one] S’ha afegit o completat 1 grup.
   *[other] S’han afegit o completat { $count } grups.
}
# review: new
setup-added-own-keys = { $count ->
    [one] S’ha afegit 1 clau pròpia.
   *[other] S’han afegit { $count } claus pròpies.
}
# review: new
setup-added-contact-keys = { $count ->
    [one] S’ha afegit 1 clau d’un contacte.
   *[other] S’han afegit { $count } claus de contactes.
}
# review: new
setup-added-rules = { $count ->
    [one] S’ha afegit 1 regla de missatges.
   *[other] S’han afegit { $count } regles de missatges.
}
# review: new
setup-skipped-rules = { $count ->
    [one] 1 regla de missatges ja hi és.
   *[other] { $count } regles de missatges ja hi són.
}
# review: new
setup-skipped-rules-account = { $count ->
    [one] 1 regla de missatges és per a un compte que no és aquí, així que s’ha omès.
   *[other] { $count } regles de missatges són per a comptes que no són aquí, així que s’han omès.
}
# review: new
setup-rules-waiting = { $count ->
    [one] 1 regla de missatges mou missatges a una carpeta que apareixerà quan se sincronitzi el seu compte.
   *[other] { $count } regles de missatges mouen missatges a carpetes que apareixeran quan se sincronitzin els seus comptes.
}
# review: new
setup-added-trusted-senders = { $count ->
    [one] S’ha afegit 1 remitent de confiança.
   *[other] S’han afegit { $count } remitents de confiança.
}
# review: new
setup-nothing = No s’ha importat res.
# review: new
setup-account-servers = { $imap } i { $smtp } ({ $signin })
# review: new
setup-file-name = Opcions i comptes d’Inbox Classic
# review: new
setup-skipped-unreachable = S’ha omès { $name }: no s’ha pogut connectar amb el seu servei d’inici de sessió. Torneu-lo a afegir a Aplicacions d’inici de sessió.
# review: new
attachment-runs-programs = «{ $name }» pot executar programes, així que Inbox Classic no l’obre. Deseu-lo i obriu-lo vós mateix si confieu en la seva procedència.
# review: new
attachment-decrypted-note = Aquest fitxer adjunt prové d’un missatge xifrat. Per obrir-lo, Inbox Classic el desa desxifrat en aquest ordinador, en una carpeta vostra que Inbox Classic buida al cap d’un dia.
