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
# review: new
header-security = Seguridad
# review: new
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
# review: changed
agent-level-organize = Organizar el correo: marcar como leído o no leído, añadir marcas, gestionar el correo no deseado, mover y archivar mensajes, crear carpetas, enviar mensajes a Elementos eliminados y cancelar suscripciones a listas de correo cuando usted lo apruebe
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
# review: new
agent-encrypted-original = Este mensaje está cifrado: un agente no puede responderlo ni reenviarlo, porque no puede cifrar.
# review: new
agent-encrypted = Este mensaje está cifrado. Solo el usuario puede leerlo, en Inbox Classic.
# review: new
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
# review: new
agent-log-unsubscribe-failed = No se pudo cancelar la suscripción a la lista que envió «{ $subject }»: { $reason }
# review: new
agent-log-unsubscribe-refused = Usted no canceló la suscripción a { $senders }
# review: new
agent-unsubscribe-title = { $count ->
    [one] { $program } quiere cancelar su suscripción a una lista de correo
   *[other] { $program } quiere cancelar su suscripción a { $count } listas de correo
}
# review: new
agent-unsubscribe-detail = Inbox Classic pide a cada una de las listas siguientes que deje de enviarle correo, mediante la opción de un solo clic que ofrece la lista. No se envía nada más, y los mensajes que ya tiene se quedan donde están.

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
# review: new
pgp-key-valid = Válida
# review: new
pgp-key-expires = Válida hasta el { $date }
# review: new
pgp-key-expired = Caducó el { $date }
# review: new
pgp-key-revoked = Revocada
# review: new
pgp-key-revoked-why = Revocada: { $reason }
# review: new
pgp-key-not-valid = No válida
# review: new
pgp-key-locked = No se puede usar: la clave que la protege ya no está en { $store }. Vuelva a importar su copia de seguridad.
# review: new
pgp-source-own = Creada en Inbox Classic
# review: new
pgp-source-file = Importada de un archivo
# review: new
pgp-source-paste = Pegada
# review: new
pgp-source-attachment = De un mensaje
# review: new
pgp-source-vcard = De una tarjeta de contacto
# review: new
pgp-source-wkd = Del proveedor de correo del remitente
# review: new
pgp-source-keyserver = De keys.openpgp.org
# review: new
pgp-source-autocrypt = Del encabezado Autocrypt de un mensaje
# review: new
pgp-error-no-store = Las claves privadas se guardan protegidas por { $store }, que no se puede usar: { $error }
# review: new
pgp-error-wrong-passphrase = La frase de contraseña no es correcta.
# review: new
# review: new
pgp-error-not-a-key = Esto no es una clave OpenPGP.
# review: new
pgp-error-too-large = La clave es demasiado grande.
# review: new
pgp-error-unusable = La clave usa criptografía antigua o débil y no se puede usar.
# review: new
pgp-imported-private = { $count ->
    [one] Se importó su clave privada.
   *[other] Se importaron { $count } claves privadas.
}
# review: new
pgp-imported-public = { $count ->
    [one] Se importó una clave.
   *[other] Se importaron { $count } claves.
}
# review: new
pgp-imported-pending = Ya se usa otra clave para { $addresses }: la nueva espera en el contacto hasta que la elija.
# review: new
pgp-error-needs-passphrase = La clave privada está protegida por una frase de contraseña. Escríbala para importar la clave.
# review: new
pgp-error-mismatch = La clave privada no corresponde a su clave pública. Puede haber sido alterada.
# review: new
pgp-file-name-public = Clave pública de { $who }.asc
# review: new
pgp-file-name-private = Copia de seguridad de la clave privada de { $who }.asc
# review: new
pgp-pending = Se encontró otra clave para { $address } el { $date }.

## Reading signed and encrypted mail (protect.rs)
# review: new
pgp-part-verified = Firmado por { $signer }, clave verificada
# review: new
pgp-part-signed = Firmado por { $signer } (clave sin verificar)
# review: new
pgp-part-other = Firmado por { $signer }, que no es el remitente
# review: new
pgp-part-unknown-key = Firmado, pero no se conoce la clave
# review: new
pgp-part-not-signed = Sin firmar
# review: new
pgp-part-not-checked = Firma no comprobada
# review: new
pgp-part-encrypted = Cifrado. { $signature }
# review: new
pgp-part-no-key = Cifrado para una clave que no tiene
# review: new
pgp-part-changed = La parte cifrada se modificó por el camino y no se muestra
# review: new
pgp-part-unprotected = Cifrado sin protección contra cambios, no se muestra
# review: new
pgp-part-broken = La parte cifrada no se puede leer
# review: new
pgp-why-mismatch = La firma no corresponde a este texto
# review: new
pgp-why-weak-hash = La firma usa { $hash }, que ya no es seguro
# review: new
pgp-why-key-expired = Firmado después de que la clave caducara el { $date }
# review: new
pgp-why-key-revoked = Firmado con una clave revocada
# review: new
pgp-why-not-signing-key = Firmado con una clave que no puede firmar
# review: new
pgp-why-from-future = La firma tiene una fecha futura
# review: new
pgp-why-signature-expired = La firma ha caducado
# review: new
pgp-why-key-not-valid = Firmado con una clave no válida
# review: new
pgp-why-not-for-you = Firmado para otros destinatarios y reenviado a usted
# review: new
pgp-why-not-key-in-use = Firmado con una clave distinta de la que se usa para { $address }
# review: new
pgp-part-pictures-loaded = { $label }. Se cargaron imágenes de internet
# review: new
pgp-error-no-own-key = No tiene ninguna clave para { $address } con la que firmar o cifrar. Cree una en Herramientas > Claves de cifrado, o desactive Firmar y Cifrar.
# review: new
pgp-error-missing-keys = { $count ->
    [one] { $addresses } no tiene ninguna clave para cifrar.
   *[other] Estos destinatarios no tienen ninguna clave para cifrar: { $addresses }.
}
# review: new
pgp-error-encrypted-quote = Este mensaje cita o reenvía un mensaje cifrado, así que solo se puede enviar cifrado. Active Cifrar, o quite el texto citado.
# review: new
pgp-error-protect = No se pudo firmar ni cifrar el mensaje: { $reason }
# review: new
pgp-found-keys = Se encontró la clave de { $addresses }.
# review: new
pgp-found-none = No se encontró ninguna clave para { $addresses }. Pídale que le envíe su clave pública.
# review: new
pgp-found-no-key = No se encontró ninguna clave.
# review: new
pgp-find-unavailable = Ahora no se pueden buscar claves: { $error }
# review: new
pgp-publish-pending = keys.openpgp.org envió un enlace de confirmación a { $addresses }. Su clave se publica allí en cuanto haga clic en él.
# review: new
pgp-publish-done = Su clave está publicada en keys.openpgp.org para { $addresses }.
# review: new
pgp-publish-failed = No se pudo publicar la clave: { $error }
# review: changed
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
# review: new
pgp-details-part = Parte { $number }: { $label }
# review: new
pgp-details-signed = Firmado { $when } con la clave { $key }
# review: new
pgp-details-unknown-key = Firmado con la clave { $key }, que usted no tiene
# review: new
pgp-details-opened = Cifrado para su clave { $key }
# review: new
pgp-details-for = Cifrado para { $keys }
# review: new
pgp-details-plain = Ni firmado ni cifrado
# review: new
pgp-bar-parts = Este mensaje tiene { $count } partes: { $list }. Cada parte indica cómo está protegida.
# review: new
pgp-bar-count-verified = { $count ->
    [one] 1 verificada
   *[other] { $count } verificadas
}
# review: new
pgp-bar-count-good = { $count ->
    [one] 1 firmada o cifrada
   *[other] { $count } firmadas o cifradas
}
# review: new
pgp-bar-count-warning = { $count ->
    [one] 1 requiere atención
   *[other] { $count } requieren atención
}
# review: new
pgp-bar-count-neutral = { $count } sin firma confirmada
# the setup file: settings, accounts, contacts and keys carried to another computer
# review: new
setup-part-settings = Configuración
# review: new
setup-part-preferences = Preferencias de las ventanas
# review: new
setup-part-accounts = Cuentas
# review: new
setup-part-sign-in-apps = Aplicaciones de inicio de sesión
# review: new
setup-part-contacts = Contactos y grupos
# review: new
setup-part-keys = Claves de cifrado
# review: new
setup-part-rules = Reglas de mensajes
# review: new
setup-part-trusted-senders = Remitentes de confianza
# review: new
setup-holds-settings = { $count ->
    [one] 1 ajuste
   *[other] { $count } ajustes
}
# review: new
setup-holds-preferences = { $count ->
    [one] 1 preferencia
   *[other] { $count } preferencias
}
# review: new
setup-holds-accounts = { $count ->
    [one] 1 cuenta
   *[other] { $count } cuentas
}
# review: new
setup-holds-sign-in-apps = { $count ->
    [one] 1 aplicación de inicio de sesión
   *[other] { $count } aplicaciones de inicio de sesión
}
# review: new
setup-holds-built-in = Qué aplicaciones de inicio de sesión integradas están activadas
# review: new
setup-holds-contacts = { $count ->
    [one] 1 contacto
   *[other] { $count } contactos
}
# review: new
setup-holds-groups = { $count ->
    [one] 1 grupo
   *[other] { $count } grupos
}
# review: new
setup-holds-own-keys = { $count ->
    [one] 1 clave propia
   *[other] { $count } claves propias
}
# review: new
setup-holds-contact-keys = { $count ->
    [one] 1 clave de un contacto
   *[other] { $count } claves de contactos
}
# review: new
setup-holds-rules = { $count ->
    [one] 1 regla
   *[other] { $count } reglas
}
# review: new
setup-holds-trusted-senders = { $count ->
    [one] 1 remitente de confianza
   *[other] { $count } remitentes de confianza
}
# review: new
setup-sign-in-password = Contraseña
# review: new
setup-account-secret-password = Su contraseña está en el archivo.
# review: new
setup-account-secret-token = Su inicio de sesión está en el archivo.
# review: new
setup-account-asks-password = Pedirá su contraseña después de la importación.
# review: new
setup-account-signs-in-again = Volverá a iniciar sesión en ella después de la importación.
# review: new
setup-account-here = Ya está configurada aquí, así que se omite.
# review: new
setup-account-no-app = Inicia sesión con { $app }, que no está configurada aquí. Importe también las aplicaciones de inicio de sesión.
# review: new
setup-invalid-address = «{ $address }» no es una dirección de correo electrónico.
# review: new
setup-invalid-server = El servidor { $server } no tiene un nombre o un puerto que se pueda usar.
# review: new
setup-invalid-user = No tiene nombre de usuario.
# review: new
setup-invalid-sign-in = Inicia sesión de una forma que Inbox Classic no conoce.
# review: new
setup-error-empty = El archivo está vacío.
# review: new
setup-error-too-large = El archivo es demasiado grande para ser una configuración de Inbox Classic.
# review: new
setup-error-not-setup = Este archivo no es una configuración de Inbox Classic.
# review: new
setup-error-damaged = El archivo de configuración está dañado y no se puede leer.
# review: new
setup-error-newer = Esta configuración la guardó una versión más reciente de Inbox Classic ({ $version }). Actualice Inbox Classic y vuelva a importarla.
# review: new
setup-error-needs-passphrase = Esta configuración está protegida por una frase de contraseña. Escriba la frase de contraseña con la que se guardó.
# review: new
setup-error-wrong-passphrase = Esa no es la frase de contraseña con la que se guardó esta configuración.
# review: new
setup-error-changed = El archivo de configuración se modificó o dañó después de guardarlo, así que no se puede importar.
# review: new
setup-error-read = No se pudo leer el archivo de configuración: { $error }
# review: new
setup-error-write = No se pudo guardar la configuración: { $error }
# review: new
setup-error-no-parts = Elija al menos una parte.
# review: new
setup-left-out = { $count ->
    [one] 1 elemento de «{ $part }» no se puede usar y se omite.
   *[other] { $count } elementos de «{ $part }» no se pueden usar y se omiten.
}
# review: new
setup-imported-settings = Se reemplazó la configuración.
# review: new
setup-imported-preferences = Se reemplazaron las preferencias de las ventanas.
# review: new
setup-added-accounts = { $count ->
    [one] Se agregó 1 cuenta.
   *[other] Se agregaron { $count } cuentas.
}
# review: new
setup-skipped-here = { $address } ya está configurada aquí, así que se omitió.
# review: new
setup-skipped-no-app = Se omitió { $address }: inicia sesión con { $app }, que no está configurada aquí.
# review: new
setup-skipped-invalid = Se omitió { $address }: { $reason }
# review: new
setup-asks-password = { $address } pedirá su contraseña al conectarse.
# review: new
setup-signs-in-again = { $address } le pedirá que vuelva a iniciar sesión al conectarse.
# review: new
setup-added-sign-in-apps = { $count ->
    [one] Se agregó 1 aplicación de inicio de sesión.
   *[other] Se agregaron { $count } aplicaciones de inicio de sesión.
}
# review: new
setup-skipped-sign-in-apps = { $count ->
    [one] 1 aplicación de inicio de sesión ya está configurada aquí.
   *[other] { $count } aplicaciones de inicio de sesión ya están configuradas aquí.
}
# review: new
setup-added-contacts = { $count ->
    [one] Se agregó 1 contacto a la libreta de direcciones.
   *[other] Se agregaron { $count } contactos a la libreta de direcciones.
}
# review: new
setup-skipped-contacts = { $count ->
    [one] 1 contacto ya está en la libreta de direcciones.
   *[other] { $count } contactos ya están en la libreta de direcciones.
}
# review: new
setup-added-groups = { $count ->
    [one] Se agregó o completó 1 grupo.
   *[other] Se agregaron o completaron { $count } grupos.
}
# review: new
setup-added-own-keys = { $count ->
    [one] Se agregó 1 clave propia.
   *[other] Se agregaron { $count } claves propias.
}
# review: new
setup-added-contact-keys = { $count ->
    [one] Se agregó 1 clave de un contacto.
   *[other] Se agregaron { $count } claves de contactos.
}
# review: new
setup-added-rules = { $count ->
    [one] Se agregó 1 regla de mensajes.
   *[other] Se agregaron { $count } reglas de mensajes.
}
# review: new
setup-skipped-rules = { $count ->
    [one] 1 regla de mensajes ya está aquí.
   *[other] { $count } reglas de mensajes ya están aquí.
}
# review: new
setup-skipped-rules-account = { $count ->
    [one] 1 regla de mensajes es de una cuenta que no está aquí, así que se omitió.
   *[other] { $count } reglas de mensajes son de cuentas que no están aquí, así que se omitieron.
}
# review: new
setup-rules-waiting = { $count ->
    [one] 1 regla de mensajes mueve mensajes a una carpeta que aparecerá cuando su cuenta se sincronice.
   *[other] { $count } reglas de mensajes mueven mensajes a carpetas que aparecerán cuando sus cuentas se sincronicen.
}
# review: new
setup-added-trusted-senders = { $count ->
    [one] Se agregó 1 remitente de confianza.
   *[other] Se agregaron { $count } remitentes de confianza.
}
# review: new
setup-nothing = No se importó nada.
# review: new
setup-account-servers = { $imap } y { $smtp } ({ $signin })
# review: new
setup-file-name = Configuración y cuentas de Inbox Classic
# review: new
setup-skipped-unreachable = Se omitió { $name }: no se pudo contactar con su servicio de inicio de sesión. Vuelva a agregarla en Aplicaciones de inicio de sesión.
# review: new
attachment-runs-programs = «{ $name }» puede ejecutar programas, así que Inbox Classic no lo abre. Guárdelo y ábralo usted mismo si confía en su origen.
# review: new
attachment-decrypted-note = Este adjunto viene de un mensaje cifrado. Para abrirlo, Inbox Classic lo guarda descifrado en este equipo, en una carpeta suya que Inbox Classic vacía al cabo de un día.
# review: new
undone-move = { $count ->
    [one] El servidor no movió { $messages } a { $folder }, así que vuelve a estar en { $from }: { $reason }
   *[other] El servidor no movió { $messages } a { $folder }, así que vuelven a estar en { $from }: { $reason }
}
# review: new
undone-delete = { $count ->
    [one] El servidor no eliminó { $messages }, así que vuelve a estar en { $from }: { $reason }
   *[other] El servidor no eliminó { $messages }, así que vuelven a estar en { $from }: { $reason }
}
# review: new
undone-archive = { $count ->
    [one] El servidor no archivó { $messages }, así que vuelve a estar en { $from }: { $reason }
   *[other] El servidor no archivó { $messages }, así que vuelven a estar en { $from }: { $reason }
}
# review: new
undone-read = { $count ->
    [one] El servidor no marcó { $messages } como leído, así que vuelve a estar sin leer: { $reason }
   *[other] El servidor no marcó { $messages } como leídos, así que vuelven a estar sin leer: { $reason }
}
# review: new
undone-unread = { $count ->
    [one] El servidor no marcó { $messages } como no leído, así que vuelve a estar leído: { $reason }
   *[other] El servidor no marcó { $messages } como no leídos, así que vuelven a estar leídos: { $reason }
}
# review: new
undone-flags = { $count ->
    [one] El servidor no cambió las marcas de { $messages }, así que está como antes: { $reason }
   *[other] El servidor no cambió las marcas de { $messages }, así que están como antes: { $reason }
}
