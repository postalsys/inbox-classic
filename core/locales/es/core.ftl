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
size-gb = { $size } GB
send-delay-off = Desactivado
send-delay-seconds = { $count ->
    [one] 1 segundo
   *[other] { $count } segundos
}
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
reader-downloading-size = El mensaje ocupa { $size }. Aparecerá aquí cuando se haya descargado.
reader-failed = No se pudo descargar el mensaje
reader-failed-network = No se pudo conectar con el servidor de correo ({ $reason }).
reader-failed-sign-in = El servidor de correo no aceptó el inicio de sesión ({ $reason }). Compruebe la contraseña o vuelva a iniciar sesión en Archivo > Cuentas.
reader-failed-security = No se pudo establecer una conexión segura con el servidor de correo ({ $reason }).
reader-failed-other = El servidor de correo respondió: { $reason }.
reader-retry-note = Se volverá a intentar cuando se restablezca la conexión con la cuenta.
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
header-security = Seguridad
header-part = Parte { $number }
quote-original = ----- Mensaje original -----
fold-show-earlier = Mostrar los mensajes anteriores

## Rebotes: la tarjeta sobre un aviso de que un mensaje no se entregó

bounce-failed = Su mensaje no se entregó
bounce-delayed = Su mensaje aún no se ha entregado
bounce-delayed-note = Su servidor de correo sigue intentando entregarlo. No necesita enviarlo de nuevo.
bounce-show-message = Mostrar el mensaje que no se entregó
# the link of a delay's card to the message that is still on its way
bounce-show-delayed = Mostrar el mensaje pendiente de entrega
bounce-what-to-do = Qué puede hacer:
bounce-delayed-do = No necesita hacer nada por ahora. Si el mensaje no se puede entregar, recibirá otro aviso.
bounce-delayed-row-do = No necesita hacer nada por ahora. Su servidor de correo sigue intentando entregar el mensaje. Recibirá otro aviso si no lo consigue.
bounce-details = Detalles
bounce-someone = Un destinatario
bounce-server = Servidor: { $server }
bounce-status = Estado: { $status }
bounce-reported-by = Aviso enviado por: { $server }
bounce-retry-minutes = El servidor receptor pidió esperar { $count ->
    [one] un minuto
   *[other] { $count } minutos
} antes del siguiente intento.
bounce-retry-hours = El servidor receptor pidió esperar { $count ->
    [one] una hora
   *[other] { $count } horas
} antes del siguiente intento.
bounce-blocklist = Lista de bloqueo: { $lists }
bounce-user-unknown = La dirección no existe
bounce-user-unknown-why = El servidor receptor no tiene ningún buzón con esta dirección. Puede estar mal escrita, o la persona ya no la usa.
bounce-user-unknown-do = Compruebe que la dirección esté bien escrita o pida al destinatario su dirección de correo actual.
bounce-invalid-address = La dirección no es válida
bounce-invalid-address-why = El formato de la dirección es incorrecto, por lo que no se puede enviar correo a ella.
bounce-invalid-address-do = Compruebe que no haya espacios de más ni letras que falten, y que aparezca el nombre de dominio después del signo @.
bounce-mailbox-disabled = El buzón está desactivado
bounce-mailbox-disabled-why = La dirección existe, pero su buzón se ha desactivado o ya no se usa.
bounce-mailbox-disabled-do = Contacte con el destinatario por otro medio y pídale su dirección de correo actual.
bounce-mailbox-full = El buzón está lleno
bounce-mailbox-full-why = El buzón del destinatario no tiene espacio para correo nuevo.
bounce-mailbox-full-do = Vuelva a enviar el mensaje dentro de unos días o avise al destinatario por otro medio. Los mensajes con archivos adjuntos grandes son los primeros en rechazarse.
bounce-spam-blocked = Rechazado como correo no deseado
bounce-spam-blocked-why = El servidor receptor clasificó el mensaje como correo no deseado.
bounce-spam-blocked-do = Quite los elementos que puedan hacer que el mensaje se clasifique como correo no deseado, como un exceso de enlaces, enlaces acortados o archivos adjuntos grandes, y vuelva a enviarlo. Si el problema persiste, contacte con su proveedor de correo.
bounce-virus-detected = Rechazado por un virus
bounce-virus-detected-why = El servidor receptor encontró un virus u otro contenido dañino en el mensaje o en sus archivos adjuntos.
bounce-virus-detected-do = Analice los archivos adjuntos con un antivirus. Algunos servidores rechazan todos los programas y archivos comprimidos. En ese caso, comparta los archivos mediante un enlace.
bounce-ip-blocklisted = Su servidor de correo está en una lista de bloqueo
bounce-ip-blocklisted-why = El servidor receptor rechaza los mensajes de su servidor de correo porque su dirección IP figura en una lista de bloqueo.
bounce-ip-blocklisted-do = El problema no está en el mensaje. Reenvíe este aviso a su proveedor de correo y pídale que solicite la retirada del servidor de la lista.
bounce-domain-blocklisted = Un dominio está en una lista de bloqueo
bounce-domain-blocklisted-why = El servidor receptor rechaza el mensaje porque el dominio de su dirección de correo, o alguno de los dominios de los enlaces del mensaje, figura en una lista de bloqueo.
bounce-domain-blocklisted-do = Si el mensaje contiene enlaces, intente enviarlo sin ellos. Si el problema persiste o el mensaje no contiene enlaces, reenvíe este aviso a quien gestione el correo de su dominio.
bounce-policy-blocked = Rechazado por las reglas del servidor receptor
bounce-policy-blocked-why = Las reglas del servidor receptor no dejan pasar este mensaje, por ejemplo por su tamaño, sus archivos adjuntos o quién lo envió.
bounce-policy-blocked-do = La respuesta del servidor, en la sección Detalles, suele indicar el motivo. Pregunte al destinatario si su servicio de correo admite ese tipo de mensajes.
bounce-geo-blocked = Rechazado por su procedencia
bounce-geo-blocked-why = El servidor receptor no acepta correo del país o la red donde está su servidor de correo.
bounce-geo-blocked-do = Contacte con el destinatario por otro medio o consulte a su proveedor de correo.
bounce-relay-denied = El servidor rechazó la retransmisión del mensaje
bounce-relay-denied-why = Un servidor se negó a entregar el mensaje, a menudo porque se envió sin iniciar sesión o por un servidor que no atiende a este destinatario.
bounce-relay-denied-do = En Archivo > Cuentas, revise la configuración del servidor saliente y compruebe que el inicio de sesión en ese servidor esté configurado.
bounce-auth-failure = No se pudo verificar su dirección de remitente
bounce-auth-failure-why = El servidor receptor no pudo confirmar que el mensaje viniera realmente de su dominio (SPF, DKIM o DMARC).
bounce-auth-failure-do = Reenvíe este aviso a quien gestione el correo de su dominio para que corrija la configuración. Mientras tanto, puede intentar enviar el mensaje a través del servidor de su proveedor.
bounce-rate-limited = Demasiados mensajes a la vez
bounce-rate-limited-why = El servidor receptor está limitando temporalmente la cantidad de mensajes que acepta de su servidor de correo.
bounce-rate-limited-do = Espere un rato y vuelva a enviar el mensaje. Si escribe a muchas personas, reduzca el número de destinatarios por envío.
bounce-greylisting = Entrega aplazada temporalmente
bounce-greylisting-why = El servidor receptor pide a los remitentes desconocidos que lo intenten un poco más tarde. Es una medida habitual de protección contra el correo no deseado.
bounce-greylisting-do = No necesita hacer nada. Los servidores de correo vuelven a intentarlo automáticamente y el mensaje suele entregarse en menos de una hora.
bounce-server-error = El servidor receptor tuvo un problema
bounce-server-error-why = No se pudo contactar con el servidor receptor, o no pudo aceptar el mensaje por un problema propio.
bounce-server-error-do = Vuelva a enviar el mensaje más tarde. Si el problema persiste, compruebe que no haya errores en la parte de la dirección situada después del signo @.
bounce-unknown = No entregado
bounce-unknown-why = El aviso no indica claramente por qué no se pudo entregar el mensaje.
bounce-unknown-do = La respuesta del servidor, en la sección Detalles, puede ofrecer más información. Si no le resulta útil, reenvíe este aviso a su proveedor de correo.

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
done-watched = { $count ->
    [one] Siguiendo la conversación
   *[other] Siguiendo { $count } conversaciones
}
done-unwatched = { $count ->
    [one] Ya no se sigue la conversación
   *[other] Ya no se siguen { $count } conversaciones
}
done-ignored = { $count ->
    [one] Ignorando la conversación
   *[other] Ignorando { $count } conversaciones
}
done-unignored = { $count ->
    [one] Ya no se ignora la conversación
   *[other] Ya no se ignoran { $count } conversaciones
}
their-folders = sus carpetas
undo-move = Deshacer Mover
undo-delete = Deshacer Eliminar
undo-archive = Deshacer Archivar
undo-junk = Deshacer Marcar como correo no deseado
undo-not-junk = Deshacer Marcar como correo deseado
undo-send = Deshacer envío
nothing-to-undo = No hay nada que deshacer.
messages-gone = Los mensajes ya no están.
folder-holds-no-messages = Esta carpeta no puede contener mensajes.
not-archived-here = Los mensajes de esta carpeta no se pueden archivar.
not-emptied-here = Solo se pueden vaciar las carpetas Elementos eliminados y Correo no deseado.
next-unread-question = No quedan mensajes sin leer en { $folder }.

    ¿Ir a { $next }, la siguiente carpeta con mensajes sin leer?
no-unread-left = No quedan mensajes sin leer.
empty-question = { $count ->
    [one] ¿Vaciar { $folder }?

        El mensaje que contiene se eliminará definitivamente. No se podrá recuperar.
   *[other] ¿Vaciar { $folder }?

        Los { $messages } que contiene se eliminarán definitivamente. No se podrán recuperar.
}
no-junk-folder = Esta cuenta no tiene una carpeta de correo no deseado a la que mover los mensajes.
no-inbox-folder = Esta cuenta no tiene una bandeja de entrada a la que mover los mensajes.
done-flagged-color = Se añadió una marca { $color ->
    [red] roja
    [orange] naranja
    [yellow] amarilla
    [green] verde
    [blue] azul
    [purple] morada
   *[gray] gris
} a { $messages }
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
download-progress = Descargando { $done } de { $total }
download-done = Descargado: { $size }
downloading-messages = { $count ->
    [one] Descargando { $messages }...
   *[other] Descargando { $messages }...
}
import-put = { $count ->
    [one] { $messages } importado a { $folder }
   *[other] { $messages } importados a { $folder }
}
import-not-put = No se pudieron importar los siguientes mensajes:

    { $problems }

## Problems the windows show

error-store = almacén local: { $error }
error-not-found = no encontrado
error-closed = cerrándose
error-other-account = el navegador inició sesión en { $email }, no en esta cuenta
# a password or sign-in the mail server refused, with the server's words
failure-authentication = el servidor no aceptó el inicio de sesión ({ $reason })
# the mail server could not be reached or the connection broke, with the reason
failure-network = la conexión con el servidor falló ({ $reason })
error-in-use = no se puede quitar mientras haya cuentas que inician sesión con ella: { $accounts }
error-turned-off = esta aplicación de inicio de sesión está desactivada para cuentas nuevas
error-folder-name = el nombre de la carpeta debe tener entre 1 y 200 caracteres, sin caracteres de control
error-folder-separator = un nombre de carpeta no puede contener «{ $separator }» en este servidor
error-folder-special = la Bandeja de entrada y las carpetas especiales no se pueden renombrar ni eliminar
error-no-recipients = el mensaje no tiene destinatarios
error-bad-address = «{ $address }» no es una dirección de correo electrónico
error-not-own-address = { $address } no es una de las direcciones de envío de esta cuenta. Añádala al campo «Otras direcciones de envío» en las propiedades de la cuenta.
rule-query-refused = Las reglas no admiten filtros de carpeta ni de fecha ({ $words }).
rule-no-query = Introduzca los criterios de búsqueda para los mensajes entrantes.
rule-no-action = Elija al menos una acción para la regla.
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
    [one] el mensaje está en la Bandeja de salida y se enviará la próxima vez que se envíe y reciba correo
   *[other] { $count } mensajes están en la Bandeja de salida y se enviarán la próxima vez que se envíe y reciba correo
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

agent-level-read = Leer el correo: consultar carpetas y mensajes, y realizar búsquedas
agent-level-organize = Organizar el correo: marcar como leído o no leído, añadir marcas, gestionar el correo no deseado, mover mensajes y enviarlos a Elementos eliminados
agent-level-drafts = Escribir borradores para que usted los envíe
agent-level-send = Enviar correo, cada mensaje solo después de que usted lo apruebe
agent-connect-title = { $program } solicita acceso a su correo
agent-connect-detail = Un agente de IA solicita acceso a Inbox Classic. Elija qué puede hacer y a qué cuentas puede acceder. Podrá cambiar estos permisos en Herramientas > Agentes de IA.

    Los agentes leen mensajes escritos por otras personas. Estos mensajes pueden contener instrucciones destinadas a engañarlos. Inbox Classic siempre le pide confirmación antes de que un agente envíe un mensaje.
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
agent-undo-sent = el mensaje ya no está en la Bandeja de salida
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
agent-encrypted-original = Los agentes no pueden responder a este mensaje cifrado ni reenviarlo, ya que no pueden cifrar mensajes.
agent-encrypted = Este mensaje está cifrado. Los agentes de IA no pueden leer su contenido. El usuario debe abrirlo en Inbox Classic.
list-encrypted = Mensaje cifrado
agent-log-composed = Se abrió «{ $subject }» en la ventana de redacción para que termine de escribirlo
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
agent-log-archived = Se archivó «{ $subject }»
agent-log-folder = Se creó la carpeta «{ $name }»
agent-log-unsubscribed = Suscripción cancelada a la lista que envió «{ $subject }»

## Keys

key-ctrl = Ctrl
key-alt = Alt
key-shift = Mayús
key-del = Supr
key-enter = Intro

## Signing in and passwords

sign-in-no-refresh = el proveedor no proporcionó un token de actualización
sign-in-no-account = el proveedor no indicó qué cuenta inició sesión
sign-in-not-finished = el inicio de sesión no ha terminado
secrets-unavailable = { $store } no está disponible
secrets-unavailable-why = { $store } no está disponible: { $error }
secrets-windows = el Administrador de credenciales
secrets-mac = el llavero
secrets-linux = el llavero del sistema (Secret Service)
error-no-such-file = ese archivo no existe
cards-file-too-big = Este archivo es demasiado grande para importarlo como libreta de direcciones.
ui-sender-added = { $name } se ha añadido a la libreta de direcciones.
ui-sender-known = { $name } ya está en la libreta de direcciones.
ui-sender-none = El remitente de este mensaje no tiene una dirección de correo electrónico que añadir.
card-name-needed = El contacto no tiene nombre ni dirección de correo electrónico.
# a file of Import Address Book that could not be read: "contacts.vcf: there is no such file"
cards-file-failed = { $file }: { $reason }

otp-heading = Código de { $domain }
otp-copy = Copiar
otp-note = Introdúzcalo solo en una página de { $domain }.
otp-old = Este código se envió más de una hora antes de que abriera el mensaje y probablemente haya caducado.

event-attendees =
    { $count ->
        [one] { $count } asistente
       *[other] { $count } asistentes
    }

otp-notification = { $code } es su código para { $domain }

## OpenPGP keys (keys.rs)
pgp-key-valid = Válida
pgp-key-expires = Válida hasta el { $date }
pgp-key-expired = Caducó el { $date }
pgp-key-revoked = Revocada
pgp-key-revoked-why = Revocada: { $reason }
pgp-key-not-valid = No válida
pgp-key-locked = Falta la clave necesaria para desbloquearla en el almacén de contraseñas ({ $store }). Vuelva a importar la copia de seguridad de su clave privada.
pgp-source-own = Creada en Inbox Classic
pgp-source-file = Importada de un archivo
pgp-source-paste = Pegada
pgp-source-attachment = De un mensaje
pgp-source-vcard = De una tarjeta de contacto
pgp-source-wkd = Del proveedor de correo del remitente
pgp-source-keyserver = De keys.openpgp.org
pgp-source-autocrypt = Del encabezado Autocrypt de un mensaje
pgp-error-no-store = El almacén de contraseñas necesario para proteger las claves privadas no está disponible ({ $store }): { $error }
pgp-error-wrong-passphrase = La contraseña no es correcta.
pgp-error-not-a-key = Esto no es una clave OpenPGP.
pgp-error-too-large = La clave es demasiado grande.
pgp-error-unusable = Esta clave utiliza métodos criptográficos obsoletos o inseguros y no se puede usar.
pgp-imported-private = { $count ->
    [one] Se importó su clave privada.
   *[other] Se importaron { $count } claves privadas.
}
pgp-imported-public = { $count ->
    [one] Se importó una clave.
   *[other] Se importaron { $count } claves.
}
pgp-imported-pending = Ya hay otra clave asociada a estas direcciones: { $addresses }. Puede elegir la nueva clave en las propiedades del contacto.
pgp-error-needs-passphrase = La clave privada está protegida con una contraseña. Introdúzcala para importar la clave.
pgp-error-mismatch = La clave privada y la pública no corresponden al mismo par. Es posible que la clave se haya modificado.
pgp-file-name-public = Clave pública de { $who }.asc
pgp-file-name-private = Copia de seguridad de la clave privada de { $who }.asc
pgp-pending = Se encontró otra clave para { $address } el { $date }.

## Reading signed and encrypted mail (protect.rs)
pgp-part-verified = Firmado por { $signer }, clave verificada
pgp-part-signed = Firmado por { $signer } (clave sin verificar)
pgp-part-other = Firmado por { $signer }, que no es el remitente
pgp-part-unknown-key = Firmado, pero no se conoce la clave
pgp-part-not-signed = Sin firmar
pgp-part-not-checked = Firma no comprobada
pgp-part-encrypted = Cifrado. { $signature }
pgp-part-no-key = No dispone de la clave privada necesaria para descifrar el contenido
pgp-part-changed = El contenido cifrado se modificó durante la transmisión y no se muestra
pgp-part-unprotected = El contenido cifrado no está protegido contra modificaciones y no se muestra
pgp-part-broken = La parte cifrada no se puede leer
pgp-why-mismatch = La firma no coincide con el contenido
pgp-why-weak-hash = La firma utiliza el algoritmo hash { $hash }, que ya no se considera seguro
pgp-why-key-expired = Firmado después de que la clave caducara el { $date }
pgp-why-key-revoked = Firmado con una clave revocada
pgp-why-not-signing-key = La clave utilizada no está habilitada para firmar
pgp-why-from-future = La firma tiene una fecha futura
pgp-why-signature-expired = La firma ha caducado
pgp-why-key-not-valid = Firmado con una clave no válida
pgp-why-not-for-you = Firmado para otros destinatarios y reenviado a usted
pgp-why-not-key-in-use = Firmado con una clave distinta de la que se usa para { $address }
pgp-part-pictures-loaded = { $label }. Se cargaron imágenes de internet
pgp-error-no-own-key = No hay ninguna clave configurada para firmar o cifrar con la dirección { $address }. Cree una en Herramientas > Claves de cifrado o desactive las opciones Firmar y Cifrar.
pgp-error-missing-keys = { $count ->
    [one] Falta la clave necesaria para enviar un mensaje cifrado a { $addresses }.
   *[other] Faltan las claves necesarias para enviar mensajes cifrados a estos destinatarios: { $addresses }.
}
pgp-error-encrypted-quote = Este mensaje incluye contenido de un mensaje cifrado. Active la opción Cifrar o quite el contenido citado antes de enviarlo.
pgp-error-protect = No se pudo firmar ni cifrar el mensaje: { $reason }
pgp-found-keys = Claves encontradas para: { $addresses }.
pgp-found-none = No se encontró ninguna clave para estas direcciones: { $addresses }. Pida a los destinatarios que le envíen sus claves públicas.
pgp-found-no-key = No se encontró ninguna clave.
pgp-find-unavailable = La búsqueda de claves no está disponible en este momento: { $error }
pgp-publish-pending = keys.openpgp.org ha enviado un enlace de confirmación a las siguientes direcciones: { $addresses }. Confirme cada dirección para que su clave pueda encontrarse a través de ella.
pgp-publish-done = Su clave está publicada en keys.openpgp.org para { $addresses }.
pgp-publish-failed = No se pudo publicar la clave: { $error }
pgp-keyserver-off = La búsqueda de claves en keys.openpgp.org está desactivada en { $settings }.
# the compose window with Sign and Encrypt: the line under the fields, each recipient's key, the questions
# review: new
pgp-compose-encrypted = { $count ->
    [one] Cifrado y firmado: solo usted y { $addresses } pueden leerlo.
   *[other] Cifrado y firmado: solo usted y sus { $count } destinatarios pueden leerlo.
}
# review: new
pgp-compose-encrypt-ready = Se cifrará y firmará. Agregue destinatarios cuyas claves tenga.
# review: new
pgp-compose-missing = { $count ->
    [one] { $addresses } no tiene ninguna clave, así que el mensaje aún no se puede cifrar.
   *[other] { $count } destinatarios no tienen ninguna clave, así que el mensaje aún no se puede cifrar: { $addresses }.
}
# review: new
pgp-compose-looking = Buscando las claves de { $addresses }...
# review: new
pgp-compose-signed = Firmado: los destinatarios pueden comprobar que procede de usted y que nadie lo cambió.
# review: new
pgp-compose-reply-clear = Sin cifrar, aunque el mensaje al que responde o que reenvía estaba cifrado.
# review: new
pgp-compose-encrypted-files = Lleva adjuntos archivos de un mensaje cifrado, así que este mensaje solo se puede enviar cifrado. Active Cifrar, o quite esos archivos.
# review: new
pgp-compose-sign-tip = Firmar el mensaje con su clave, para que los destinatarios puedan comprobar que procede de usted y que nadie lo cambió
# review: new
pgp-compose-sign-tip-encrypted = Un mensaje cifrado siempre se firma
# review: new
pgp-compose-encrypt-tip = Cifrar el mensaje, para que solo usted y sus destinatarios puedan leerlo
# review: new
pgp-compose-make-key = Aún no tiene ninguna clave para { $address }. ¿Crear una ahora? Con ella, sus mensajes se pueden firmar y cifrar.
# review: new
pgp-compose-key-unusable = Su clave para { $address } no se puede usar ({ $state }). Abra Claves de cifrado para importar su copia de seguridad o crear una clave nueva.
# review: new
pgp-compose-encrypt-off-quote = Este mensaje cita o reenvía un mensaje cifrado. Sin cifrado, no se podrá enviar hasta que quite lo que cita. ¿Desactivar el cifrado de todos modos?
# review: new
pgp-compose-encrypt-off-reply = Este mensaje responde a un mensaje cifrado o lo reenvía. Sin cifrado, cualquiera que maneje su mensaje por el camino podrá leerlo. ¿Desactivar el cifrado?
# review: new
pgp-recipient-verified = Clave verificada
# review: new
pgp-recipient-found = Clave sin verificar
# review: new
pgp-recipient-own = Su propia clave
# review: new
pgp-recipient-looking = Buscando una clave...
# review: new
pgp-recipient-missing = Sin clave
# review: new
pgp-recipient-not-found = Sin clave: no se encontró ninguna el { $date }
# review: new
pgp-recipient-unusable = La clave no se puede usar: { $state }
# review: new
pgp-recipients-intro = El mensaje se cifra para la clave de cada destinatario, y para la suya.
# review: new
pgp-recipients-intro-missing = { $count ->
    [one] Un destinatario no tiene ninguna clave para cifrar. Busque su clave, quítelo de este mensaje o envíelo sin cifrar.
   *[other] { $count } destinatarios no tienen ninguna clave para cifrar. Busque sus claves, quítelos de este mensaje o envíelo sin cifrar.
}
pgp-details-part = Parte { $number }: { $label }
pgp-details-signed = Firmado el { $when } con la clave { $key }
pgp-details-unknown-key = Firmado con la clave { $key }, que no está disponible en este equipo
pgp-details-opened = Descifrado con su clave { $key }
pgp-details-for = Cifrado con las siguientes claves: { $keys }
pgp-details-plain = Ni firmado ni cifrado
pgp-bar-parts = Este mensaje consta de { $count } partes: { $list }. El estado de protección se indica sobre cada parte.
pgp-bar-count-verified = { $count ->
    [one] 1 verificada
   *[other] { $count } verificadas
}
pgp-bar-count-good = { $count ->
    [one] 1 firmada o cifrada
   *[other] { $count } firmadas o cifradas
}
pgp-bar-count-warning = { $count ->
    [one] 1 con advertencias
   *[other] { $count } con advertencias
}
pgp-bar-count-neutral = { $count } sin firma confirmada
# the setup file: settings, accounts, contacts and keys carried to another computer
setup-part-settings = Configuración
setup-part-preferences = Preferencias de las ventanas
setup-part-accounts = Cuentas
setup-part-sign-in-apps = Aplicaciones de inicio de sesión
setup-part-contacts = Contactos y grupos
setup-part-keys = Claves de cifrado
setup-part-rules = Reglas de mensajes
setup-part-trusted-senders = Remitentes de confianza
setup-holds-settings = { $count ->
    [one] 1 ajuste
   *[other] { $count } ajustes
}
setup-holds-preferences = { $count ->
    [one] 1 preferencia
   *[other] { $count } preferencias
}
setup-holds-accounts = { $count ->
    [one] 1 cuenta
   *[other] { $count } cuentas
}
setup-holds-sign-in-apps = { $count ->
    [one] 1 aplicación de inicio de sesión
   *[other] { $count } aplicaciones de inicio de sesión
}
setup-holds-built-in = Estado de activación de las aplicaciones de inicio de sesión integradas
setup-holds-contacts = { $count ->
    [one] 1 contacto
   *[other] { $count } contactos
}
setup-holds-groups = { $count ->
    [one] 1 grupo
   *[other] { $count } grupos
}
setup-holds-own-keys = { $count ->
    [one] 1 clave propia
   *[other] { $count } claves propias
}
setup-holds-contact-keys = { $count ->
    [one] 1 clave de un contacto
   *[other] { $count } claves de contactos
}
setup-holds-rules = { $count ->
    [one] 1 regla
   *[other] { $count } reglas
}
setup-holds-trusted-senders = { $count ->
    [one] 1 remitente de confianza
   *[other] { $count } remitentes de confianza
}
setup-sign-in-password = Contraseña
setup-account-secret-password = El archivo incluye la contraseña guardada.
setup-account-secret-token = El archivo incluye los datos de acceso guardados.
setup-account-asks-password = Tras la importación, tendrá que introducir la contraseña.
setup-account-signs-in-again = Tras la importación, tendrá que volver a iniciar sesión en esta cuenta.
setup-account-here = Esta cuenta ya está configurada en este equipo y no se volverá a importar.
setup-account-no-app = Esta cuenta utiliza la aplicación de inicio de sesión { $app }, que aún no está configurada en este equipo. Importe también las aplicaciones de inicio de sesión.
setup-invalid-address = «{ $address }» no es una dirección de correo electrónico.
setup-invalid-server = El nombre o el puerto del servidor { $server } no es válido.
setup-invalid-user = La cuenta no tiene un nombre de usuario.
setup-invalid-sign-in = El método de inicio de sesión de esta cuenta no es compatible con Inbox Classic.
setup-error-empty = El archivo está vacío.
setup-error-too-large = El archivo es demasiado grande para importar su configuración y sus cuentas.
setup-error-not-setup = Este archivo no contiene una exportación de configuración y cuentas de Inbox Classic.
setup-error-damaged = El archivo de configuración está dañado y no se puede leer.
setup-error-newer = El archivo se exportó con una versión más reciente de Inbox Classic ({ $version }). Actualice Inbox Classic y vuelva a intentar la importación.
setup-error-needs-passphrase = El archivo está protegido con una contraseña. Introduzca la contraseña que usó al exportarlo.
setup-error-wrong-passphrase = No se puede abrir el archivo con esta contraseña.
setup-error-changed = El archivo de configuración se modificó o dañó después de guardarlo, así que no se puede importar.
setup-error-read = No se pudo leer el archivo de configuración: { $error }
setup-error-write = No se pudo guardar el archivo de configuración: { $error }
setup-error-no-parts = Elija al menos una categoría de datos.
setup-left-out = { $count ->
    [one] Se omitirá 1 elemento de «{ $part }» porque no se puede usar.
   *[other] Se omitirán { $count } elementos de «{ $part }» porque no se pueden usar.
}
setup-imported-settings = Se reemplazó la configuración.
setup-imported-preferences = Se reemplazaron las preferencias de las ventanas.
setup-added-accounts = { $count ->
    [one] Se añadió 1 cuenta.
   *[other] Se añadieron { $count } cuentas.
}
setup-skipped-here = La cuenta { $address } ya está configurada en este equipo y no se ha vuelto a importar.
setup-skipped-no-app = No se importó { $address } porque falta la aplicación de inicio de sesión { $app }.
setup-skipped-invalid = Se omitió { $address }: { $reason }
setup-asks-password = Al conectarse a la cuenta { $address }, tendrá que introducir la contraseña.
setup-signs-in-again = Al conectarse a la cuenta { $address }, tendrá que volver a iniciar sesión.
setup-added-sign-in-apps = { $count ->
    [one] Se añadió 1 aplicación de inicio de sesión.
   *[other] Se añadieron { $count } aplicaciones de inicio de sesión.
}
setup-skipped-sign-in-apps = { $count ->
    [one] 1 aplicación de inicio de sesión ya está configurada aquí.
   *[other] { $count } aplicaciones de inicio de sesión ya están configuradas aquí.
}
setup-added-contacts = { $count ->
    [one] Se añadió 1 contacto a la libreta de direcciones.
   *[other] Se añadieron { $count } contactos a la libreta de direcciones.
}
setup-skipped-contacts = { $count ->
    [one] 1 contacto ya está en la libreta de direcciones.
   *[other] { $count } contactos ya están en la libreta de direcciones.
}
setup-added-groups = { $count ->
    [one] Se añadió o actualizó 1 grupo.
   *[other] Se añadieron o actualizaron { $count } grupos.
}
setup-added-own-keys = { $count ->
    [one] Se añadió 1 clave propia.
   *[other] Se añadieron { $count } claves propias.
}
setup-added-contact-keys = { $count ->
    [one] Se añadió 1 clave de un contacto.
   *[other] Se añadieron { $count } claves de contactos.
}
setup-added-rules = { $count ->
    [one] Se añadió 1 regla de mensajes.
   *[other] Se añadieron { $count } reglas de mensajes.
}
setup-skipped-rules = { $count ->
    [one] 1 regla de mensajes ya existe en este equipo.
   *[other] { $count } reglas de mensajes ya existen en este equipo.
}
setup-skipped-rules-account = { $count ->
    [one] Se omitió 1 regla de mensajes porque su cuenta no está configurada en este equipo.
   *[other] Se omitieron { $count } reglas de mensajes porque sus cuentas no están configuradas en este equipo.
}
setup-rules-waiting = { $count ->
    [one] La carpeta de destino de 1 regla de mensajes estará disponible cuando se sincronice la cuenta.
   *[other] Las carpetas de destino de { $count } reglas de mensajes estarán disponibles cuando se sincronicen sus cuentas.
}
setup-added-trusted-senders = { $count ->
    [one] Se añadió 1 remitente de confianza.
   *[other] Se añadieron { $count } remitentes de confianza.
}
setup-nothing = No se importó nada.
setup-account-servers = { $imap } y { $smtp } ({ $signin })
setup-file-name = Configuración y cuentas de Inbox Classic
setup-skipped-unreachable = Se omitió { $name } porque no se pudo contactar con el servicio de inicio de sesión. Vuelva a añadir esta aplicación en «Aplicaciones de inicio de sesión».
attachment-runs-programs = El archivo «{ $name }» puede ejecutar programas, por lo que Inbox Classic no lo abre. Si confía en su origen, puede guardarlo y abrirlo por su cuenta.
attachment-decrypted-note = Este archivo adjunto procede de un mensaje cifrado. Para abrirlo, Inbox Classic guarda una copia sin cifrar en una carpeta temporal de su cuenta de usuario. Al iniciar la aplicación, se eliminan las copias que tienen más de un día.
undone-move = { $count ->
    [one] El servidor no movió { $messages } a { $folder }, así que vuelve a estar en { $from }: { $reason }
   *[other] El servidor no movió { $messages } a { $folder }, así que vuelven a estar en { $from }: { $reason }
}
undone-delete = { $count ->
    [one] El servidor no eliminó { $messages }, así que vuelve a estar en { $from }: { $reason }
   *[other] El servidor no eliminó { $messages }, así que vuelven a estar en { $from }: { $reason }
}
undone-archive = { $count ->
    [one] El servidor no archivó { $messages }, así que vuelve a estar en { $from }: { $reason }
   *[other] El servidor no archivó { $messages }, así que vuelven a estar en { $from }: { $reason }
}
undone-read = { $count ->
    [one] El servidor no marcó { $messages } como leído, así que vuelve a figurar como no leído: { $reason }
   *[other] El servidor no marcó { $messages } como leídos, así que vuelven a figurar como no leídos: { $reason }
}
undone-unread = { $count ->
    [one] El servidor no marcó { $messages } como no leído, así que vuelve a figurar como leído: { $reason }
   *[other] El servidor no marcó { $messages } como no leídos, así que vuelven a figurar como leídos: { $reason }
}
undone-flags = { $count ->
    [one] El servidor no cambió las marcas de { $messages }, así que está como antes: { $reason }
   *[other] El servidor no cambió las marcas de { $messages }, así que están como antes: { $reason }
}
