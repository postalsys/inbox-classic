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
list-counts-selected = { $messages }, { $unread } sin leer, { $selected } seleccionados
list-counts-found = { $found } encontrados, { $unread } sin leer
list-counts-found-selected = { $found } encontrados, { $unread } sin leer, { $selected } seleccionados
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
reader-downloading-detail = Se mostrará aquí en cuanto llegue.
reader-failed = No se pudo descargar el mensaje
reader-failed-network = No se pudo conectar con el servidor de correo ({ $reason }).
reader-failed-sign-in = El servidor de correo no aceptó el inicio de sesión ({ $reason }). Compruebe la contraseña o vuelva a iniciar sesión en Archivo > Cuentas.
reader-failed-security = No se pudo proteger la conexión con el servidor de correo ({ $reason }).
reader-failed-other = El servidor de correo respondió: { $reason }.
reader-retry-note = No descargado. Se volverá a intentar cuando la cuenta vuelva a estar en línea.
reader-unreadable = Este mensaje no se puede mostrar: { $error }
message-source-title = Código fuente del mensaje: { $subject }
message-source-untitled = Código fuente del mensaje

## Printing and quoting

header-from = De
header-date = Fecha
header-to = Para
header-cc = CC
header-sent = Enviado
header-subject = Asunto
quote-original = ----- Mensaje original -----
fold-show-earlier = Mostrar los mensajes anteriores

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
    [one] { $messages } marcado con marca
   *[other] { $messages } marcados con marca
}
done-unflagged = Se quitó la marca de { $messages }
done-deleted-for-good = { $count ->
    [one] { $messages } eliminado definitivamente
   *[other] { $messages } eliminados definitivamente
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
their-folders = sus carpetas
undo-move = Deshacer Mover
undo-delete = Deshacer Eliminar
undo-junk = Deshacer Marcar como correo no deseado
undo-not-junk = Deshacer Marcar como correo deseado
nothing-to-undo = No hay nada que deshacer.
messages-gone = Los mensajes ya no están.
folder-holds-no-messages = Esa carpeta no contiene mensajes.
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
import-not-put = Estos no se colocaron en la carpeta:

    { $problems }

## Problems the windows show

error-store = almacén local: { $error }
error-not-found = no encontrado
error-closed = cerrándose
error-other-account = el navegador inició sesión en { $email }, no en esta cuenta
error-in-use = no se puede quitar mientras haya cuentas que inician sesión con ella: { $accounts }
error-turned-off = esta aplicación de inicio de sesión está desactivada para cuentas nuevas
error-folder-name = un nombre de carpeta de 1 a 200 caracteres, sin caracteres de control
error-folder-separator = un nombre de carpeta no puede contener "{ $separator }" en este servidor
error-folder-special = la Bandeja de entrada y las carpetas especiales no se pueden renombrar ni eliminar
error-no-recipients = el mensaje no tiene destinatarios
error-bad-address = "{ $address }" no es una dirección de correo electrónico
error-attachment = no se pudo leer { $path }: { $error }
error-no-drafts = la cuenta no tiene una carpeta Borradores donde guardar el mensaje
error-draft-attachment = no se pudo conservar un archivo adjunto del borrador: { $error }
error-password-not-saved = no se pudo guardar la contraseña para el próximo inicio: { $error }
error-sign-in-not-saved = no se pudo guardar el nuevo inicio de sesión para el próximo inicio: { $error }
error-import-unreadable = no se puede leer { $path }: { $error }
error-import-too-large = { $path } ocupa más de 50 MB
error-import-not-mail = { $path } no es un mensaje de correo electrónico
error-list-answered = la lista respondió { $status }
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
error-no-sign-in = no hay inicio de sesión para esta cuenta
error-provider-missing = esta versión no puede iniciar sesión en { $provider }: ¿se quitó su aplicación de inicio de sesión?
error-provider-servers = los servidores de esta cuenta no son aquellos en los que inicia sesión
error-app-scopes = { $reason }. El servidor de correo no aceptó el token de la aplicación de inicio de sesión: compruebe que los ámbitos (scopes) de la aplicación dan acceso al correo
error-in-folder = { $folder }: { $reason }

## Sign-in apps

sign-in-off-google = Google aún no ha verificado Inbox Classic, así que solo permite iniciar sesión con ella a usuarios de prueba. Use su propia aplicación de inicio de sesión de Google o una contraseña de aplicación, o actívela en Aplicaciones de inicio de sesión (Archivo > Cuentas) si es usuario de prueba.
sign-in-off-other = Se desactivó en Aplicaciones de inicio de sesión (Archivo > Cuentas), donde se puede volver a activar.
sign-in-app-no-name = la aplicación de inicio de sesión necesita un nombre
sign-in-app-no-client = falta el ID de cliente
sign-in-app-no-scopes = la aplicación de inicio de sesión necesita los ámbitos (scopes) que dan acceso al correo
sign-in-app-bad-host = falta el servidor { $server } o no es un nombre de host
sign-in-app-plain = el servidor { $server } debe usar SSL/TLS o STARTTLS
sign-in-app-not-checked = el emisor aún no se ha comprobado
sign-in-app-issuer-changed = el emisor cambió: vuelva a escribir el secreto de cliente o quítelo
sign-in-register-google = En Google Cloud Console, cree un cliente OAuth de tipo Aplicación de escritorio, con el ámbito https://mail.google.com/ en su pantalla de consentimiento. Mientras la aplicación esté en pruebas, solo sus usuarios de prueba pueden iniciar sesión.
sign-in-register-microsoft = En Microsoft Entra, registre una aplicación con la plataforma Aplicaciones móviles y de escritorio, el URI de redirección http://localhost, los flujos de cliente público permitidos y los permisos delegados IMAP.AccessAsUser.All, SMTP.Send y offline_access. Solo para su organización, use https://login.microsoftonline.com/<ID de inquilino>/v2.0 como emisor.
sign-in-register-other = Registre un cliente nativo (público) con el URI de redirección de abajo; el proveedor debe permitir cualquier puerto en él (RFC 8252). Agregue el ámbito con el que el proveedor da acceso al correo.

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
repeats-on = { $repeats } el { $days }
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
agent-level-organize = Organizar el correo: leído o no leído, marcas, correo no deseado, mover, eliminar a Elementos eliminados
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
agent-send-detail = Compruebe a quién va y qué dice. Si lo envía, espera { $seconds } segundos en la Bandeja de salida, donde aún puede eliminarlo.
agent-change-title = Qué puede hacer { $program }
agent-change-allowed = Cambie lo que los agentes de IA de este programa pueden hacer con su correo.
agent-change-refused = Rechazó este programa. Permítalo para que sus agentes puedan volver a usar su correo.
agent-log-taken-back = { $entry } (deshecho)
agent-files = Archivos: { $files }
agent-undo-refused = No se puede deshacer.
agent-undo-refused-why = No se puede deshacer: { $reason }.
agent-undo-impossible = esto no se puede deshacer
agent-undo-not-in-folder = el mensaje ya no está en esa carpeta
agent-undo-not-arrived = el mensaje no está (todavía) en la carpeta de destino
agent-undo-sent = el mensaje ya se envió
agent-original-not-downloaded = el mensaje respondido aún no está descargado: léalo primero
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
agent-log-flagged = «{ $subject }» marcado con marca
agent-log-unflagged = Se quitó la marca de «{ $subject }»
agent-log-deleted = Se eliminó «{ $subject }»
agent-log-moved = «{ $subject }» movido a { $folder }
agent-log-junk = «{ $subject }» marcado como correo no deseado
agent-log-not-junk = «{ $subject }» marcado como correo deseado
agent-log-folder = Se creó la carpeta «{ $name }»
agent-log-unsubscribed = Baja de la lista de «{ $subject }»

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
