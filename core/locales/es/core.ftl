# Español. Borrador, pendiente de revisión por un hablante nativo (ver core/locales/GLOSSARY.md).

## Counts and sizes

messages = { $count ->
    [one] 1 mensaje
   *[other] { $count } mensajes
}
decimal-separator = ,
size-bytes = { $count ->
    [one] 1 byte
   *[other] { $count } bytes
}
size-kb = { $size } KB
size-mb = { $size } MB
list-counts = { $messages }, { $unread } sin leer
list-counts-selected = { $messages }, { $unread } sin leer, { $selected ->
    [one] { $selected } seleccionado
   *[other] { $selected } seleccionados
}
list-counts-found = { $found ->
    [one] { $found } encontrado
   *[other] { $found } encontrados
}, { $unread } sin leer
list-counts-found-selected = { $found ->
    [one] { $found } encontrado
   *[other] { $found } encontrados
}, { $unread } sin leer, { $selected ->
    [one] { $selected } seleccionado
   *[other] { $selected } seleccionados
}
list-counts-none = No se encontraron mensajes

## Special folders

folder-inbox = Bandeja de entrada
folder-sent = Elementos enviados
folder-deleted = Elementos eliminados
folder-drafts = Borradores
folder-junk = Correo no deseado
folder-archive = Archivo

## The reading pane

reader-no-message = No hay ningún mensaje seleccionado.
reader-downloading = Descargando el mensaje…
reader-downloading-detail = El mensaje se mostrará aquí cuando finalice la descarga.
reader-failed = No se pudo descargar el mensaje
reader-failed-network = No se pudo conectar con el servidor de correo ({ $reason }).
reader-failed-sign-in = El servidor de correo no aceptó el inicio de sesión ({ $reason }). Compruebe la contraseña o vuelva a iniciar sesión en Archivo > Cuentas.
reader-failed-security = No se pudo establecer una conexión segura con el servidor de correo ({ $reason }).
reader-failed-other = El servidor de correo respondió: { $reason }.
reader-retry-note = El mensaje no se ha descargado. Se volverá a intentar cuando se restablezca la conexión con la cuenta.
reader-unreadable = Este mensaje no se puede mostrar: { $error }
message-source-title = Formato original del mensaje: { $subject }
message-source-untitled = Formato original del mensaje

## Printing and quoting

header-from = De
header-date = Fecha
header-to = Para
header-cc = CC
header-sent = Enviado
header-subject = Asunto
quote-original = ----- Mensaje original -----
fold-show-earlier = Mostrar los mensajes anteriores

## Rebotes: la tarjeta sobre un aviso de que un mensaje no se entregó

# review: new
bounce-failed = Su mensaje no se entregó
# review: new
bounce-delayed = Su mensaje aún no se ha entregado
# review: new
bounce-delayed-note = Su servidor de correo sigue intentando entregarlo. No necesita enviarlo de nuevo.
# review: new
bounce-show-message = Mostrar el mensaje que no se entregó
# review: new
bounce-what-to-do = Qué puede hacer:
# review: new
bounce-delayed-do = Nada por ahora. Si sigue sin poder entregarse, recibirá otro aviso.
# review: new
bounce-delayed-row-do = Nada por ahora. Su servidor de correo sigue intentando entregarlo, y recibirá otro aviso si no lo consigue.
# review: new
bounce-details = Detalles
# review: new
bounce-someone = Un destinatario
# review: new
bounce-server = Servidor: { $server }
# review: new
bounce-status = Estado: { $status }
# review: new
bounce-reported-by = Informado por: { $server }
# review: new
bounce-retry-minutes = El servidor receptor pidió esperar { $count ->
    [one] un minuto
   *[other] { $count } minutos
} antes del siguiente intento.
# review: new
bounce-retry-hours = El servidor receptor pidió esperar { $count ->
    [one] una hora
   *[other] { $count } horas
} antes del siguiente intento.
# review: new
bounce-blocklist = Lista de bloqueo: { $lists }
# review: new
bounce-user-unknown = La dirección no existe
# review: new
bounce-user-unknown-why = El servidor receptor no tiene ningún buzón con esta dirección. Puede estar mal escrita, o la persona ya no la usa.
# review: new
bounce-user-unknown-do = Revise cómo está escrita la dirección, o pida a la persona la dirección que usa ahora.
# review: new
bounce-invalid-address = La dirección no es válida
# review: new
bounce-invalid-address-why = La dirección no está escrita de una forma a la que se pueda enviar correo.
# review: new
bounce-invalid-address-do = Busque errores de escritura, como un espacio, una letra que falta o nada después de la @.
# review: new
bounce-mailbox-disabled = El buzón está cerrado
# review: new
bounce-mailbox-disabled-why = La dirección existe, pero su buzón se ha desactivado o ya no se usa.
# review: new
bounce-mailbox-disabled-do = Contacte con la persona de otra forma y pídale una dirección que use ahora.
# review: new
bounce-mailbox-full = El buzón está lleno
# review: new
bounce-mailbox-full-why = El buzón del destinatario no tiene espacio para correo nuevo.
# review: new
bounce-mailbox-full-do = Envíelo de nuevo dentro de unos días, o avise a la persona de otra forma. Los archivos adjuntos grandes son los primeros en rechazarse.
# review: new
bounce-spam-blocked = Rechazado como correo no deseado
# review: new
bounce-spam-blocked-why = El servidor receptor tomó el mensaje por correo no deseado.
# review: new
bounce-spam-blocked-do = Envíelo de nuevo sin lo que parece correo no deseado, como muchos vínculos, vínculos acortados o un archivo adjunto grande. Si vuelve a ocurrir, consulte a su proveedor de correo.
# review: new
bounce-virus-detected = Rechazado por un virus
# review: new
bounce-virus-detected-why = El servidor receptor encontró un virus u otro contenido dañino en el mensaje o en sus archivos adjuntos.
# review: new
bounce-virus-detected-do = Revise los archivos adjuntos con un antivirus. Algunos servidores rechazan cualquier programa o archivo comprimido, así que comparta esos archivos con un vínculo.
# review: new
bounce-ip-blocklisted = Su servidor de correo está en una lista de bloqueo
# review: new
bounce-ip-blocklisted-why = El servidor receptor rechaza el correo del servidor que envió el suyo, porque la dirección de ese servidor está en una lista de bloqueo.
# review: new
bounce-ip-blocklisted-do = El problema no es el mensaje. Reenvíe este aviso a su proveedor de correo y pídale que saque el servidor de la lista.
# review: new
bounce-domain-blocklisted = Un dominio está en una lista de bloqueo
# review: new
bounce-domain-blocklisted-why = El servidor receptor rechaza el mensaje porque el dominio de su dirección, o un dominio de los vínculos del mensaje, está en una lista de bloqueo.
# review: new
bounce-domain-blocklisted-do = Si el mensaje tiene vínculos, pruebe sin ellos. Si no, reenvíe este aviso a quien gestione el correo de su dominio.
# review: new
bounce-policy-blocked = Rechazado por las reglas del servidor receptor
# review: new
bounce-policy-blocked-why = Las reglas del servidor receptor no dejan pasar este mensaje, por ejemplo por su tamaño, sus archivos adjuntos o quién lo envió.
# review: new
bounce-policy-blocked-do = Las propias palabras del servidor en Detalles suelen dar el motivo. Pregunte al destinatario si puede aceptar ese correo.
# review: new
bounce-geo-blocked = Rechazado por su procedencia
# review: new
bounce-geo-blocked-why = El servidor receptor no acepta correo del país o la red donde está su servidor de correo.
# review: new
bounce-geo-blocked-do = Contacte con la persona de otra forma, o consulte a su proveedor de correo.
# review: new
bounce-relay-denied = El servidor no lo reenvió
# review: new
bounce-relay-denied-why = Un servidor se negó a entregar el mensaje, a menudo porque se envió sin iniciar sesión o por un servidor que no atiende a este destinatario.
# review: new
bounce-relay-denied-do = Revise el servidor de salida de la cuenta en Archivo > Cuentas, y que inicie sesión.
# review: new
bounce-auth-failure = No se pudo verificar su dirección de remitente
# review: new
bounce-auth-failure-why = El servidor receptor no pudo confirmar que el mensaje viniera realmente de su dominio (SPF, DKIM o DMARC).
# review: new
bounce-auth-failure-do = Reenvíe este aviso a quien gestione el correo de su dominio: hay que corregir su configuración. Mientras tanto, enviar por el servidor de su proveedor puede ayudar.
# review: new
bounce-rate-limited = Demasiado correo a la vez
# review: new
bounce-rate-limited-why = El servidor receptor acepta por ahora menos mensajes de su servidor de correo.
# review: new
bounce-rate-limited-do = Espere un rato y envíelo de nuevo. Si escribe a muchas personas, envíelo a menos a la vez.
# review: new
bounce-greylisting = Retenido un momento
# review: new
bounce-greylisting-why = El servidor receptor pide a los remitentes desconocidos que lo intenten un poco más tarde, una comprobación habitual contra el correo no deseado.
# review: new
bounce-greylisting-do = Nada. Los servidores de correo lo intentan de nuevo por sí solos, y el mensaje suele entregarse en menos de una hora.
# review: new
bounce-server-error = El servidor receptor tuvo un problema
# review: new
bounce-server-error-why = No se pudo contactar con el servidor receptor, o no pudo aceptar el mensaje por un problema propio.
# review: new
bounce-server-error-do = Envíelo de nuevo más tarde. Si sigue fallando, busque errores de escritura en la parte de la dirección después de la @.
# review: new
bounce-unknown = No entregado
# review: new
bounce-unknown-why = El aviso no dice con claridad por qué.
# review: new
bounce-unknown-do = Las propias palabras del servidor en Detalles pueden decir más. Si no ayudan, reenvíe este aviso a su proveedor de correo.

## Several messages selected

selection-title = { $count ->
    [one] 1 mensaje seleccionado
   *[other] { $count } mensajes seleccionados
}
selection-unread = { $count } sin leer
selection-flagged = { $count } con marca
delete-for-good-one = Este mensaje se eliminará definitivamente. ¿Eliminarlo?
delete-for-good-all = Estos { $count } mensajes se eliminarán definitivamente. ¿Eliminarlos?
delete-for-good-some = { $count } de los { $total } mensajes se eliminarán definitivamente. ¿Eliminar los mensajes?
done-read = { $count ->
    [one] { $messages } marcado como leído
   *[other] { $messages } marcados como leídos
}
done-unread = { $count ->
    [one] { $messages } marcado como no leído
   *[other] { $messages } marcados como no leídos
}
done-flagged = { $count ->
   *[other] Se añadió una marca a { $messages }
}
done-unflagged = Se quitó la marca de { $messages }
done-deleted-for-good = { $count ->
    [one] { $messages } eliminado definitivamente
   *[other] { $messages } eliminados definitivamente
}
# review: new
done-archived = { $count ->
    [one] { $messages } archivado
   *[other] { $messages } archivados
}
done-moved = { $count ->
    [one] { $messages } movido a { $folder }
   *[other] { $messages } movidos a { $folder }
}
done-copied = { $count ->
    [one] { $messages } copiado a { $folder }
   *[other] { $messages } copiados a { $folder }
}
done-moving = { $count ->
    [one] Moviendo { $messages } a { $folder }...
   *[other] Moviendo { $messages } a { $folder }...
}
done-copying = { $count ->
    [one] Copiando { $messages } a { $folder }...
   *[other] Copiando { $messages } a { $folder }...
}
done-moved-back = { $count ->
    [one] { $messages } devuelto a { $folder }
   *[other] { $messages } devueltos a { $folder }
}
# review: new
done-watched = { $count ->
    [one] Siguiendo la conversación
   *[other] Siguiendo { $count } conversaciones
}
# review: new
done-unwatched = { $count ->
    [one] Ya no se sigue la conversación
   *[other] Ya no se siguen { $count } conversaciones
}
# review: new
done-ignored = { $count ->
    [one] Ignorando la conversación
   *[other] Ignorando { $count } conversaciones
}
# review: new
done-unignored = { $count ->
    [one] Ya no se ignora la conversación
   *[other] Ya no se ignoran { $count } conversaciones
}
their-folders = sus carpetas
undo-move = Deshacer Mover
undo-delete = Deshacer Eliminar
# review: new
undo-archive = Deshacer Archivar
undo-junk = Deshacer Marcar como correo no deseado
undo-not-junk = Deshacer Marcar como correo deseado
nothing-to-undo = No hay nada que deshacer.
messages-gone = Los mensajes ya no están.
folder-holds-no-messages = Esta carpeta no puede contener mensajes.
# review: new
not-archived-here = Los mensajes de esta carpeta no se pueden archivar.
# review: new
not-emptied-here = Solo se pueden vaciar Elementos eliminados y Correo no deseado.
# review: new
next-unread-question = No quedan mensajes sin leer en { $folder }.

    ¿Ir a { $next }, la siguiente carpeta con mensajes sin leer?
# review: new
no-unread-left = No quedan mensajes sin leer.
# review: new
empty-question = { $count ->
    [one] ¿Vaciar { $folder }?

        El mensaje que contiene se eliminará definitivamente. No se podrá recuperar.
   *[other] ¿Vaciar { $folder }?

        Los { $messages } que contiene se eliminarán definitivamente. No se podrán recuperar.
}
no-junk-folder = Esta cuenta no tiene una carpeta de correo no deseado a la que mover los mensajes.
no-inbox-folder = Esta cuenta no tiene una bandeja de entrada a la que mover los mensajes.
done-flagged-color = Marca { $color ->
    [red] roja
    [orange] naranja
    [yellow] amarilla
    [green] verde
    [blue] azul
    [purple] morada
   *[gray] gris
} puesta en { $messages }
flag-color = { $color ->
    [red] Rojo
    [orange] Naranja
    [yellow] Amarillo
    [green] Verde
    [blue] Azul
    [purple] Morado
   *[gray] Gris
}

## La ventana Mover y Copiar

move-window-title-move = { $count ->
    [one] Mover mensaje
   *[other] Mover { $count } mensajes
}
move-window-title-copy = { $count ->
    [one] Copiar mensaje
   *[other] Copiar { $count } mensajes
}
move-window-prompt-move = { $count ->
    [one] Mover el mensaje seleccionado a:
   *[other] Mover los { $count } mensajes seleccionados a:
}
move-window-prompt-copy = { $count ->
    [one] Copiar el mensaje seleccionado a:
   *[other] Copiar los { $count } mensajes seleccionados a:
}
targets-recent = Recientes
target-current = { $folder } (actual)
target-recent = { $folder } ({ $account })

## Moving and copying to another account

transfer-moving = Moviendo { $done } de { $messages } a { $folder }...
transfer-copying = Copiando { $done } de { $messages } a { $folder }...
transfer-another-account = otra cuenta
transfer-folder-gone = la carpeta de destino ya no existe
transfer-not-on-server = el mensaje ya no está en el servidor
transfer-not-moved = { $count ->
    [one] No se pudo mover { $messages } a otra cuenta: { $reason }
   *[other] No se pudieron mover { $messages } a otra cuenta: { $reason }
}
transfer-not-copied = { $count ->
    [one] No se pudo copiar { $messages } a otra cuenta: { $reason }
   *[other] No se pudieron copiar { $messages } a otra cuenta: { $reason }
}
transfer-none-moved = No se pudo mover ningún mensaje
transfer-none-copied = No se pudo copiar ningún mensaje

## Messages as files

export-not-in-time = el mensaje no se pudo descargar a tiempo
export-not-saved = { $failed ->
    [one] No se pudo guardar { $failed } de { $messages } ({ $problems })
   *[other] No se pudieron guardar { $failed } de { $messages } ({ $problems })
}
export-not-attached = no se pudieron adjuntar los mensajes: { $error }
saved-to = { $count ->
    [one] { $messages } guardado en { $folder }
   *[other] { $messages } guardados en { $folder }
}
downloading-messages = { $count ->
    [one] Descargando { $messages }...
   *[other] Descargando { $messages }...
}
import-put = { $count ->
    [one] { $messages } colocado en { $folder }
   *[other] { $messages } colocados en { $folder }
}
import-not-put = No se pudieron importar los siguientes mensajes:

    { $problems }

## Problems the windows show

error-store = almacén local: { $error }
error-not-found = no encontrado
error-closed = cerrándose
error-other-account = el navegador inició sesión en { $email }, no en esta cuenta
error-in-use = no se puede quitar mientras haya cuentas que inician sesión con ella: { $accounts }
error-turned-off = esta aplicación de inicio de sesión está desactivada para cuentas nuevas
error-folder-name = el nombre de la carpeta debe tener entre 1 y 200 caracteres, sin caracteres de control
error-folder-separator = un nombre de carpeta no puede contener "{ $separator }" en este servidor
error-folder-special = la Bandeja de entrada y las carpetas especiales no se pueden renombrar ni eliminar
error-no-recipients = el mensaje no tiene destinatarios
error-bad-address = "{ $address }" no es una dirección de correo electrónico
error-attachment = no se pudo leer { $path }: { $error }
error-no-drafts = la cuenta no tiene una carpeta Borradores donde guardar el mensaje
error-draft-attachment = no se pudo conservar un archivo adjunto del borrador: { $error }
error-password-not-saved = no se pudo guardar la contraseña para el próximo inicio: { $error }
error-sign-in-not-saved = no se pudieron guardar los nuevos datos de inicio de sesión para la próxima vez que abra la aplicación: { $error }
error-import-unreadable = no se puede leer { $path }: { $error }
error-import-too-large = { $path } ocupa más de 50 MB
error-import-not-mail = { $path } no es un mensaje de correo electrónico
error-list-answered = el servidor de la lista respondió con el código { $status }
error-not-built = no se pudo crear el mensaje
error-outbox-waits = { $count ->
    [one] el mensaje espera en la Bandeja de salida y se enviará con el próximo Enviar y recibir
   *[other] { $count } mensajes esperan en la Bandeja de salida y se enviarán con el próximo Enviar y recibir
}
error-draft-not-removed = no se pudo quitar de Borradores el borrador anterior del mensaje: { $reason }
error-sent-but = el mensaje se envió, pero { $problem }
error-sent-still-in-outbox = sigue en la Bandeja de salida: { $error }
error-sent-no-copy = no se pudo guardar una copia en Elementos enviados: { $reason }
error-no-password = no hay contraseña para esta cuenta
error-no-sign-in = no hay datos de inicio de sesión guardados para esta cuenta
error-provider-missing = esta versión no puede iniciar sesión en { $provider }: ¿se quitó su aplicación de inicio de sesión?
error-provider-servers = los servidores de esta cuenta no coinciden con los de la aplicación de inicio de sesión
error-app-scopes = { $reason }. El servidor de correo rechazó el token de la aplicación de inicio de sesión. Compruebe que sus permisos (scopes) permiten acceder al correo
error-in-folder = { $folder }: { $reason }

## Sign-in apps

sign-in-off-google = Google aún no ha verificado Inbox Classic, así que solo permite iniciar sesión con ella a usuarios de prueba. Use su propia aplicación de inicio de sesión de Google o una contraseña de aplicación, o actívela en Aplicaciones de inicio de sesión (Archivo > Cuentas) si es usuario de prueba.
sign-in-off-other = Se desactivó en Aplicaciones de inicio de sesión (Archivo > Cuentas), donde se puede volver a activar.
sign-in-app-no-name = la aplicación de inicio de sesión necesita un nombre
sign-in-app-no-client = falta el ID de cliente
sign-in-app-no-scopes = la aplicación de inicio de sesión necesita permisos (scopes) de acceso al correo
sign-in-app-bad-host = falta la dirección del servidor { $server } o no es un nombre de host válido
sign-in-app-plain = el servidor { $server } debe usar SSL/TLS o STARTTLS
sign-in-app-not-checked = el emisor aún no se ha comprobado
sign-in-app-issuer-changed = el emisor cambió: vuelva a escribir el secreto de cliente o quítelo
sign-in-register-google = En Google Cloud Console, cree un cliente OAuth de tipo Aplicación de escritorio, con el permiso (scope) https://mail.google.com/ en su pantalla de consentimiento. Mientras la aplicación esté en pruebas, solo sus usuarios de prueba pueden iniciar sesión.
sign-in-register-microsoft = En Microsoft Entra, registre una aplicación con la plataforma Aplicaciones móviles y de escritorio, el URI de redirección http://localhost, los flujos de cliente público permitidos y los permisos delegados IMAP.AccessAsUser.All, SMTP.Send y offline_access. Solo para su organización, use https://login.microsoftonline.com/<ID de inquilino>/v2.0 como emisor.
sign-in-register-other = Registre un cliente nativo (público) con el URI de redirección de abajo; el proveedor debe permitir cualquier puerto en él (RFC 8252). Añada el permiso (scope) que indique su proveedor para acceder al correo.

## Calendar invitations

repeats = Se repite
repeats-every = { $unit ->
    [day] { $interval ->
        [one] Cada día
       *[other] Cada { $interval } días
    }
    [week] { $interval ->
        [one] Cada semana
       *[other] Cada { $interval } semanas
    }
    [month] { $interval ->
        [one] Cada mes
       *[other] Cada { $interval } meses
    }
   *[year] { $interval ->
        [one] Cada año
       *[other] Cada { $interval } años
    }
}
repeats-on = { $repeats }: { $days }
repeats-times = { $count ->
    [one] { $repeats }, una vez
   *[other] { $repeats }, { $count } veces
}
day-monday = lunes
day-tuesday = martes
day-wednesday = miércoles
day-thursday = jueves
day-friday = viernes
day-saturday = sábado
day-sunday = domingo

## AI agents

agent-level-read = Leer el correo: carpetas, lista de mensajes, búsqueda y mensajes
agent-level-organize = Organizar el correo: marcar como leído o no leído, añadir marcas, gestionar el correo no deseado, mover mensajes y enviarlos a Elementos eliminados
agent-level-drafts = Escribir borradores para que usted los envíe
agent-level-send = Enviar correo, cada mensaje solo después de que usted lo apruebe
agent-connect-title = { $program } quiere usar su correo
agent-connect-detail = Un agente de IA pidió trabajar con Inbox Classic. Elija qué puede hacer y qué cuentas puede ver; puede cambiarlo más tarde en Herramientas > Agentes de IA.

    Los agentes leen correo escrito por otras personas, y un mensaje puede intentar engañarlos. Inbox Classic siempre le pregunta antes de que un agente envíe algo.
agent-reply-to = Respuesta a «{ $subject }»
agent-reply-all-on = Respuesta a todos sobre «{ $subject }»
agent-forward-of = Reenvío de «{ $subject }»
agent-never-written-one = Nunca ha escrito a { $address }.
agent-never-written-many = Nunca ha escrito a { $count } de estas direcciones.
agent-send-title = { $program } quiere enviar este mensaje
agent-send-detail = Revise los destinatarios y el contenido del mensaje. Tras confirmar el envío, permanecerá { $seconds } segundos en la Bandeja de salida, donde aún podrá eliminarlo.
agent-change-title = Qué puede hacer { $program }
agent-change-allowed = Cambie lo que los agentes de IA de este programa pueden hacer con su correo.
agent-change-refused = Ha denegado el acceso a este programa. Autorícelo para que sus agentes puedan volver a acceder a su correo.
agent-log-taken-back = { $entry } (deshecho)
agent-files = Archivos: { $files }
agent-undo-refused = No se puede deshacer.
agent-undo-refused-why = No se puede deshacer: { $reason }.
agent-undo-impossible = esto no se puede deshacer
agent-undo-not-in-folder = el mensaje ya no está en esa carpeta
agent-undo-not-arrived = el mensaje no está (todavía) en la carpeta de destino
agent-undo-sent = el mensaje ya se envió
agent-original-not-downloaded = el mensaje original aún no se ha descargado. Ábralo primero
agent-turned-away = Rechazado
agent-can-nothing = Nada
agent-can-read = leer
agent-can-organize = organizar
agent-can-drafts = escribir borradores
agent-can-send = enviar con su aprobación
agent-can-list = { $first } y { $last }
agent-accounts = { $count ->
    [0] ninguna cuenta
    [one] 1 cuenta
   *[other] { $count } cuentas
}
agent-access = { $can }; { $accounts }
agent-unreadable = Este mensaje no se puede leer.
agent-log-composed = Se abrió «{ $subject }» en un mensaje nuevo para que lo termine
agent-log-refused = No envió «{ $subject }»
agent-log-sent = Se envió «{ $subject }» a { $to }
agent-log-draft = Se guardó el borrador «{ $subject }»
agent-log-read = «{ $subject }» marcado como leído
agent-log-unread = «{ $subject }» marcado como no leído
agent-log-flagged = Se añadió una marca a «{ $subject }»
agent-log-unflagged = Se quitó la marca de «{ $subject }»
agent-log-deleted = Se eliminó «{ $subject }»
agent-log-moved = «{ $subject }» movido a { $folder }
agent-log-junk = «{ $subject }» marcado como correo no deseado
agent-log-not-junk = «{ $subject }» marcado como correo deseado
# review: new
agent-log-archived = Se archivó «{ $subject }»
agent-log-folder = Se creó la carpeta «{ $name }»
agent-log-unsubscribed = Suscripción cancelada a la lista que envió «{ $subject }»

## Keys

key-ctrl = Ctrl
key-alt = Alt
key-shift = Mayús
key-del = Supr
key-enter = Entrar

## Signing in and passwords

sign-in-no-refresh = el proveedor no dio un token de actualización
sign-in-no-account = el proveedor no indicó qué cuenta inició sesión
sign-in-not-finished = el inicio de sesión no ha terminado
secrets-unavailable = { $store } no está disponible
secrets-unavailable-why = { $store } no está disponible: { $error }
secrets-windows = el Administrador de credenciales
secrets-mac = el llavero
secrets-linux = el llavero del sistema (Secret Service)
error-no-such-file = ese archivo no existe
# review: new
cards-file-too-big = Este archivo es demasiado grande para ser una libreta de direcciones.
# review: new
ui-sender-added = { $name } se ha añadido a la libreta de direcciones.
# review: new
ui-sender-known = { $name } ya está en la libreta de direcciones.
# review: new
ui-sender-none = El remitente de este mensaje no tiene una dirección de correo electrónico que añadir.
# review: new
card-name-needed = El contacto no tiene nombre ni dirección de correo electrónico.
# a file of Import Address Book that could not be read: "contacts.vcf: there is no such file"
# review: new
cards-file-failed = { $file }: { $reason }
