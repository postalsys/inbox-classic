# Español. Borrador, pendiente de revisión por un hablante nativo.

## The menus

menu-file = &Archivo
menu-edit = &Edición
menu-view = &Ver
menu-tools = &Herramientas
menu-message = &Mensaje
menu-help = Ay&uda
menu-layout = &Diseño
menu-sort-by = Ordenar &por
menu-text-size = Tamaño del te&xto
menu-folder = Carpe&ta
# review: new
menu-insert = &Insertar

## The commands

cmd-new-account = &Nueva cuenta...
cmd-exit = &Salir
cmd-sync = &Enviar y recibir todo
cmd-mark-read = Marcar como &leído
cmd-mark-unread = Marcar como &no leído
cmd-pictures = Descargar &imágenes
cmd-about = &Acerca de Inbox Classic
cmd-new-mail = &Nuevo mensaje
cmd-reply = &Responder al remitente
cmd-reply-all = Responder a &todos
cmd-forward = Reen&viar
cmd-help = &Contenido
cmd-delete = &Eliminar mensaje
cmd-move = &Mover a carpeta...
cmd-flag = Añadir una &marca al mensaje
cmd-new-folder = Nueva car&peta...
cmd-rename-folder = Renom&brar carpeta...
cmd-delete-folder = &Eliminar carpeta
cmd-empty-folder = &Vaciar carpeta
ui-empty-button = Vaciar
cmd-accounts = &Cuentas...
cmd-find = &Buscar mensaje
cmd-save-as = &Guardar como...
cmd-print = Im&primir...
cmd-import = &Importar mensajes...
cmd-outbox = Bandeja de &salida...
cmd-properties = P&ropiedades
cmd-mark-all-read = Marcar todos como leíd&os
cmd-junk = Marcar como correo no &deseado
cmd-not-junk = Marcar como correo de&seado
cmd-archive = A&rchivar
cmd-watch-conversation = Se&guir la conversación
cmd-ignore-conversation = &Ignorar la conversación
cmd-next-message = Mensaje &siguiente
cmd-previous-message = Mensaje &anterior
cmd-next-unread = Siguiente mensaje &no leído
cmd-go-to-folder = &Ir a la carpeta...
cmd-find-in-message = Buscar en es&te mensaje...
ui-go-to-prompt = Ir a la carpeta:
ui-find-in-message-hint = Buscar en este mensaje
ui-find-not-found = No se encontró «{ $words }» en este mensaje
cmd-expand-all-threads = &Expandir todas las conversaciones
cmd-collapse-all-threads = &Contraer todas las conversaciones
ui-group-by-conversation = &Agrupar los mensajes por conversación
cmd-folder-list = Lis&ta de carpetas
cmd-layout-automatic = &Automático
cmd-layout-classic = &Clásico
cmd-layout-columns = C&olumnas
cmd-sort-date = &Fecha
cmd-sort-from = &De
cmd-sort-subject = &Asunto
cmd-sort-size = &Tamaño
cmd-sort-ascending = Orden as&cendente
cmd-sort-descending = Orden desce&ndente
cmd-text-size-largest = Muy gra&nde
cmd-text-size-larger = &Grande
cmd-text-size-medium = &Mediano
cmd-text-size-smaller = &Pequeño
cmd-text-size-smallest = Mu&y pequeño
cmd-hide-ignored = &Ocultar las conversaciones ignoradas
cmd-hide-read = Ocultar los mensajes &leídos
cmd-notify = &Avisar de correo nuevo
cmd-open = &Abrir Inbox Classic
cmd-default-app = Usar como programa de correo &predeterminado...
cmd-view-source = &Formato original del mensaje
cmd-ai-agents = Agentes de &IA...
cmd-options = &Opciones...
cmd-message-rules = &Reglas de mensajes...
# review: new
cmd-encryption-keys = Claves de &cifrado...
cmd-create-rule-from-message = Crear regla a partir del mensa&je...
cmd-select-all = Seleccionar &todo
cmd-undo = &Deshacer
cmd-copy = &Copiar a carpeta...
cmd-address-book = &Libreta de direcciones...
cmd-add-sender-to-book = Añadir remitente a la li&breta de direcciones
cmd-import-address-book = Importar &libreta de direcciones...
cmd-export-address-book = &Exportar libreta de direcciones...
# review: new
cmd-export-setup = Exportar configuración y c&uentas...
# review: new
cmd-import-setup = Importar con&figuración y cuentas...
# review: new
cmd-compose-sign = &Firmar digitalmente
# review: new
cmd-compose-encrypt = &Cifrar
# review: new
cmd-attach-my-key = Adjuntar mi clave &pública

## The tray icon's menu

tray-check = &Comprobar si hay correo nuevo
tray-no-accounts = Todavía no hay cuentas

## Words the windows of more than one platform share

ui-tb-create-mail = Redactar
ui-tb-reply = Responder
ui-tb-reply-all = Responder a todos
ui-tb-forward = Reenviar
ui-tb-print = Imprimir
ui-tb-delete = Eliminar
ui-tb-junk = No deseado
ui-tb-not-junk = Deseado
ui-tb-archive = Archivar
ui-tb-previous = Anterior
ui-tb-next = Siguiente
ui-previous-tip = Mensaje anterior
ui-next-tip = Mensaje siguiente
ui-tb-sync = Enviar y recibir
ui-tb-mark-read = Marcar como leído
ui-tb-mark-unread = Marcar como no leído
ui-still-running = Inbox Classic sigue abierto
ui-no-subject = (sin asunto)
ui-quoted = «{ $subject }»
ui-newest-from = Último mensaje de { $sender }: { $subject }
ui-new-messages = { $count ->
    [one] { $count } mensaje nuevo
   *[other] { $count } mensajes nuevos
}
ui-outbox-waiting = { $count ->
    [one] { $count } mensaje en la Bandeja de salida
   *[other] { $count } mensajes en la Bandeja de salida
}
ui-outbox-waits = { $subject } espera en la Bandeja de salida
ui-outbox-sending = Enviando { $subject }...
ui-from-account = De { $account }
ui-sign-in-refused = Se rechazó el inicio de sesión en { $account } o la sesión ha caducado.
ui-sign-in-again-ask = ¿Iniciar sesión de nuevo en el navegador?
ui-sign-in-again-failed = No se pudo volver a iniciar sesión: { $reason }
ui-unknown-reason = motivo desconocido
ui-checking = Buscando mensajes nuevos en { $account }...
ui-done = Listo
ui-sent-at = { $subject } enviado a las { $time }
ui-draft-saved = Mensaje guardado en Borradores
ui-draft-not-saved = El mensaje no se guardó en Borradores: { $reason }
ui-about-core = Núcleo { $version }
ui-add-account-first = Agregue primero una cuenta de correo.
ui-add-account-first-link = Agregue primero una cuenta de correo y luego vuelva a hacer clic en el enlace de correo.
ui-default-app-is = Inbox Classic es su programa de correo predeterminado: los enlaces de correo abren aquí un mensaje nuevo.
ui-select-message-first = Seleccione primero un mensaje.
ui-store-not-opened = No se pudo abrir el almacén de correo.
ui-store-or-cert-not-opened = No se pudo abrir el almacén de correo o el archivo del certificado.
ui-help-title = Ayuda de Inbox Classic
ui-help-missing = La ayuda no está disponible en esta versión de Inbox Classic.
ui-ok = Aceptar
ui-cancel = Cancelar
ui-close = Cerrar
ui-col-subject = Asunto
ui-col-from = De
ui-col-to = Para
ui-col-received = Recibido
ui-watched-conversation = Conversación seguida
ui-col-sent = Enviado
ui-col-size = Tamaño
ui-col-folder = Carpeta
ui-col-account = Cuenta
ui-col-queued = En cola desde
ui-col-status = Estado
ui-outbox-title = Bandeja de salida
ui-outbox-status-waiting = En espera
ui-outbox-status-not-sent = No enviado: { $reason }
ui-outbox-status-agent = Un agente de IA ha puesto el mensaje en cola; se enviará a las { $time }
ui-outbox-delete-ask = ¿Eliminar este mensaje sin enviarlo?
ui-open-link = Abrir enlace
ui-edit-link = Editar enlace...
ui-remove-link = Quitar enlace
ui-insert-attachment = Insertar archivo adjunto
ui-insert-picture = Insertar imagen
ui-filter-all = Todos los archivos
ui-filter-pictures = Imágenes
ui-filter-messages = Mensajes de correo
ui-save-attachment-as = Guardar archivo adjunto como
ui-not-sent = No se pudo enviar el mensaje.
ui-attachment-forgotten = Escribió «{ $word }», pero no hay ningún archivo adjunto. ¿Desea enviar el mensaje de todos modos?
ui-send-anyway = Enviar de todos modos
ui-go-back = Volver
ui-not-saved = No se pudo guardar el mensaje.
ui-saving-draft = Guardando en Borradores...
ui-compose-saved-at = Guardado en Borradores a las { $time }
ui-compose-restored = Recuperado después de que Inbox Classic se cerrara inesperadamente
ui-compose-not-saved = No se guardó en Borradores: { $reason }
ui-save-changes-ask = ¿Desea guardar los cambios de este mensaje en Borradores?
ui-new-message-title = Mensaje nuevo
ui-link-invalid = Escriba una dirección web (https://...) o un enlace de correo (mailto:...).
ui-link-address = Dirección:
ui-hyperlink = Enlace
ui-hyperlink-intro = La dirección a la que lleva el texto seleccionado.
ui-edit-hyperlink = Editar enlace
ui-edit-hyperlink-intro = Dirección de destino del enlace. Borre la dirección para quitar el enlace y conservar el texto.
ui-not-a-picture = Este archivo no es una imagen PNG, JPEG o GIF, o tiene más de 10 MB.
ui-format-color = Color de fuente
ui-format-numbers = Lista numerada
ui-format-bullets = Lista con viñetas
ui-format-outdent = Reducir sangría
ui-format-indent = Aumentar sangría
ui-format-left = Alinear a la izquierda
ui-format-center = Centrar
ui-format-right = Alinear a la derecha
ui-format-line = Insertar línea horizontal
ui-tb-send = Enviar
ui-tb-save = Guardar
ui-tb-attach = Adjuntar
# review: new
ui-tb-sign = Firmar
# review: new
ui-tb-encrypt = Cifrar
# review: new
ui-field-keys = Claves:
ui-field-from = De:
ui-field-to = Para:
ui-field-cc = CC:
ui-field-bcc = CCO:
ui-field-subject = Asunto:
ui-field-attach = Adjuntos:
ui-signature = Firma
ui-signature-hint = Se agrega a los mensajes nuevos, respuestas y reenvíos de esta cuenta.
ui-signature-not-saved = No se pudo guardar la firma.
ui-all-inboxes = Todas las bandejas de entrada
# review: new
ui-all-sent = Todos los enviados
# review: new
ui-all-drafts = Todos los borradores
ui-flagged-folder = Marcados
ui-all-folders = Todas las carpetas
ui-the-account = la cuenta
ui-folder-name = Nombre de la carpeta:
ui-find-hint = Buscar en el correo
ui-find-tip = Busca en el asunto, los remitentes, los destinatarios, los nombres de los archivos adjuntos y el texto de los mensajes.
ui-clear-search = Borrar búsqueda
ui-no-match = Ningún mensaje coincide con «{ $words }».
ui-no-match-all = La búsqueda incluye el asunto, los remitentes, los destinatarios, los nombres de los archivos adjuntos y el texto de los mensajes de todas las carpetas. Revise la ortografía o pruebe con menos palabras.
ui-no-match-in = La búsqueda en { $folder } incluye el asunto, los remitentes, los destinatarios, los nombres de los archivos adjuntos y el texto de los mensajes. Revise la ortografía o pruebe con menos palabras.
ui-no-items = No hay elementos en esta vista.
ui-choose-folder = Elija una carpeta para ver sus mensajes.
ui-unsubscribe = Cancelar suscripción
ui-open-in-calendar = Abrir en el calendario
ui-pictures-blocked = Se bloquearon algunas imágenes para evitar que el remitente identifique su equipo. Haga clic aquí para descargar las imágenes.
ui-not-shown = No se pudo mostrar el mensaje.
ui-attachment-not-read = No se pudo leer el archivo adjunto.
ui-attachment-not-saved = No se pudo guardar el archivo adjunto.
ui-not-downloaded = El mensaje aún no se ha descargado.
ui-leave-list = ¿Salir de esta lista de correo?
ui-leave-one-click = Inbox Classic enviará una solicitud de baja a { $target }. No se abrirá ninguna página web ni se enviará ningún correo electrónico.
ui-leave-mail = Para cancelar la suscripción, debe enviar un mensaje a { $target }. Inbox Classic lo prepara por usted. Envíelo para confirmar la baja.
ui-leave-web = Se abrirá la página de baja de la lista en su navegador ({ $target }).
ui-unsubscribing = Cancelando la suscripción a { $target }...
ui-cannot-unsubscribe = Este mensaje no permite cancelar la suscripción.
ui-unsubscribed = Baja confirmada. La lista indica que dejará de enviarle estos mensajes.
ui-not-unsubscribed = No se pudo cancelar la suscripción: { $reason }
ui-event-span = { $start } a { $end }
ui-event-floating = { $when } (hora del remitente)
ui-invitation = Invitación: { $title }
ui-invitation-updated = Invitación actualizada: { $title }
ui-invitation-canceled = Cancelado: { $title }
ui-invitation-answer = Respuesta a una invitación: { $title }
ui-no-title = (sin título)
ui-organizer = Organizador: { $name }
ui-invitation-not-read = No se pudo leer la invitación.
ui-no-calendar = No hay ninguna aplicación de calendario disponible en este equipo para abrir invitaciones (archivos .ics).
ui-messages-not-changed = No se pudieron cambiar los mensajes.
ui-new-folder-in-selected = La nueva carpeta se crea dentro de la carpeta seleccionada.
ui-new-folder-at-top = La nueva carpeta se crea en el nivel superior de la cuenta.
ui-folder-not-created = No se pudo crear la carpeta.
ui-folder-not-renamed = No se pudo cambiar el nombre de la carpeta.
ui-folder-not-deleted = No se pudo eliminar la carpeta.
ui-rename-folder-intro = Escriba el nuevo nombre de la carpeta «{ $folder }».
ui-properties-of = Propiedades de { $subject }
ui-internet-headers = Encabezados de Internet de este mensaje:
ui-save-messages-in = Guardar mensajes en
ui-save-message-as = Guardar mensaje como
ui-import-choose-folder = Elija primero la carpeta en la que desea importar los mensajes.
ui-add-account-title = Agregar cuenta de correo
ui-accounts-title = Cuentas
ui-security-none = Ninguna (sin cifrar)
ui-field-required = { $field } es obligatorio.
ui-email-invalid = La dirección de correo no es válida.
ui-ports-invalid = Los puertos son números del 1 al 65535.
ui-looking-up = Buscando la configuración de { $domain }...
ui-found-none = Introduzca los datos de la cuenta facilitados por su proveedor de correo.
ui-found-change = Modifique estos datos si su proveedor le ha indicado otros.
ui-found-guess = No se encontró la configuración de esta dirección. Los nombres de servidor propuestos son estimaciones. Confírmelos con su proveedor.
ui-found-mx = Inbox Classic ha identificado su proveedor de correo y ha completado los datos de sus servidores.
ui-found-srv = Esta configuración se encontró en los registros DNS de su dominio.
ui-found-autodiscover = Esta configuración se encontró mediante Microsoft Autodiscover (Exchange).
ui-found-other = Esta configuración se encontró para esta dirección.
ui-app-password-needed = { $provider } no acepta su contraseña normal en los programas de correo. Cree una contraseña de aplicación en su cuenta de { $provider } y escríbala en el campo Contraseña del siguiente formulario.
ui-app-password-open = ¿Abrir las instrucciones de { $provider } en su navegador?
ui-plain-warning = Sin cifrado, cualquier persona que intercepte el tráfico de red podrá leer su contraseña y sus mensajes. Utilice esta conexión solo con un servidor en su propio equipo o en su red local.
ui-continue-ask = ¿Continuar?
ui-add-sign-in-app = Agregar una aplicación de inicio de sesión...
ui-turned-off = { $name } está desactivado en este equipo.
ui-off-here = Desactivado en este equipo.
ui-why = ¿Por qué?
ui-more-sign-in = Más opciones de inicio de sesión...
ui-other-account = Para agregar otra cuenta de correo, introduzca su dirección y el nombre que verán los destinatarios. En el siguiente paso se buscará la configuración de los servidores.
ui-field-account-name = Nombre de la cuenta:
ui-field-name = Nombre para mostrar:
ui-field-email = Dirección de correo:
ui-field-user = Nombre de usuario:
ui-field-password = Contraseña:
ui-field-imap-host = Servidor entrante (IMAP):
ui-field-imap-port = Puerto IMAP:
ui-field-imap-security = Seguridad IMAP:
ui-field-smtp-host = Servidor saliente (SMTP):
ui-field-smtp-port = Puerto SMTP:
ui-field-smtp-security = Seguridad SMTP:
ui-field-other-addresses = Otras direcciones de envío:
ui-sign-in-not-started = No se pudo iniciar la sesión en el navegador.
ui-sign-in-in-browser = Inicie sesión en { $account } en la ventana del navegador que se abrió y luego vuelva aquí.
ui-sign-in-failed = No se pudo iniciar sesión: { $reason }
ui-account-not-saved = No se pudo guardar la cuenta.
ui-start-intro = Gmail, Google Workspace, Outlook.com y Microsoft 365: inicie sesión en el sitio web de Google o de Microsoft. Introduzca allí su contraseña, sin compartirla con Inbox Classic.
ui-start-intro-apps = Inicie sesión en el navegador con una de sus aplicaciones de inicio de sesión (Más opciones de inicio de sesión), o agregue abajo cualquier cuenta de correo con su nombre y su dirección.
ui-use-app-password = Usar contraseña de aplicación
ui-the-provider = su proveedor
ui-provider-intro = Inicie sesión en la cuenta { $email } desde el sitio web de { $provider }. Su contraseña no se compartirá con Inbox Classic. También puede usar una contraseña de aplicación creada en la configuración de seguridad de su cuenta.
ui-provider-intro-apps = Inicie sesión en la cuenta { $email } desde el sitio web de { $provider } con una de sus aplicaciones de inicio de sesión («Más opciones de inicio de sesión»). También puede usar una contraseña de aplicación creada en la configuración de seguridad de su cuenta.
ui-finish = Finalizar
ui-logon = Iniciar sesión
ui-enter-password = Escriba la contraseña de { $account }.
ui-signs-in-with = Aplicación de inicio de sesión: { $app }. La sesión se inicia en el navegador y la cuenta utiliza los servidores de esa aplicación.
ui-keep-password = Deje vacío el campo de contraseña para conservar la contraseña actual.
ui-remove-account = Quitar cuenta
ui-remove-account-ask = ¿Quitar esta cuenta de Inbox Classic? Los mensajes permanecerán en el servidor. Se eliminarán las copias de este equipo y la contraseña guardada.
ui-col-email = Dirección de correo electrónico
ui-col-incoming = Servidor de entrada
ui-type-email = Escriba su dirección de correo, por ejemplo nombre@example.com.
ui-ai-agent = Agente de IA
ui-ai-agent-access = Acceso de agentes de IA
ui-ai-agents = Agentes de IA
ui-program-path = Programa: { $path }
ui-it-may = Acciones permitidas:
ui-accounts-it-may-use = Cuentas autorizadas:
ui-send-message-ask = ¿Enviar el mensaje?
ui-col-name = Nombre
ui-never = Nunca
ui-connect-agent = Conectar un agente de IA
ui-connect-agent-intro = Agregue esto a los servidores MCP de su agente (Claude Desktop: Settings > Developer > Edit Config):
ui-col-program = Programa
ui-col-may = Permisos
ui-col-last-used = Último uso
ui-col-when = Fecha
ui-col-what = Acción
ui-sign-in-app = Aplicación de inicio de sesión
ui-sign-in-apps = Aplicaciones de inicio de sesión
ui-add-sign-in-app-title = Agregar aplicación de inicio de sesión
ui-preset-app-name = Aplicación de inicio de sesión de { $provider }
ui-issuer-not-checked = no se puede comprobar el emisor
ui-checking-issuer = Comprobando { $issuer }...
ui-issuer-unusable = El emisor no se puede usar: { $reason }
ui-issuer-usable = Se puede usar el emisor.
ui-sign-in-app-not-saved = No se pudo guardar la aplicación de inicio de sesión: { $reason }
ui-check = Co&mprobar
ui-fill-in-for = Completar datos para:
ui-app-name = Nombre:
ui-issuer = Emisor:
ui-client-id = ID de cliente:
ui-client-secret = Secreto de cliente:
ui-scopes = Permisos (scopes):
ui-imap-server = Servidor IMAP:
ui-smtp-server = Servidor SMTP:
ui-redirect-uri = URI de redirección:
ui-sign-in-app-intro = Una aplicación de inicio de sesión es un cliente OAuth registrado con su proveedor para iniciar sesión en el navegador. Seleccione un proveedor para completar sus datos y añada el ID de cliente y el secreto de cliente, si el proveedor le ha facilitado uno.
ui-remove-secret = Hay un secreto de cliente guardado. Introduzca uno nuevo para sustituirlo o quite el actual
ui-register-it = Registrar la aplicación con su proveedor
ui-built-in-note = { $name } es una aplicación integrada. Solo puede elegir si se ofrece para cuentas nuevas.
ui-client-with-secret = ID de cliente: { $client }, con un secreto de cliente.
ui-client-public = ID de cliente: { $client }, un cliente público (sin secreto).
ui-no-accounts = Ninguna cuenta
ui-remove-sign-in-app = Quitar aplicación de inicio de sesión
ui-remove-sign-in-app-ask = ¿Quitar la aplicación de inicio de sesión { $name } y su secreto de cliente guardado?
ui-sign-in-app-not-removed = No se quitó la aplicación de inicio de sesión. { $reason }
ui-sign-in-apps-intro = Las aplicaciones de inicio de sesión permiten que las cuentas inicien sesión en el navegador. Una que no esté marcada no se ofrece a las cuentas nuevas; las cuentas que ya la usan siguen funcionando.
ui-col-issuer = Emisor
ui-col-used-by = Usada por
ui-options-system-default = Idioma del sistema ({ $language })
# review: new
ui-settings-general = General
# review: new
ui-settings-reading = Lectura
# review: changed
ui-settings-new-mail = Correo nuevo
# review: new
ui-settings-sending = Envío
# review: new
ui-settings-default-apps = Aplicaciones predeterminadas
# review: new
ui-settings-message-list = Lista de mensajes
# review: new
ui-settings-messages = Mensajes
# review: new
ui-settings-encryption = Cifrado
# review: new
ui-settings-language = Idioma
# review: new
ui-settings-label = { $label }:
# review: new
ui-apply = Apli&car
# review: changed
ui-language-label = &Idioma:
ui-restart-note = Reinicie Inbox Classic para aplicar el nuevo idioma.
ui-restart-ask = Inbox Classic se mostrará en el idioma elegido ({ $language }) después de reiniciarse. ¿Reiniciar ahora?
ui-notify-new-mail = &Avisarme cuando llegue correo nuevo
ui-new-folder-title = Nueva carpeta
ui-rename-folder-title = Renombrar carpeta
ui-delete-folder-question = ¿Eliminar la carpeta «{ $folder }», todos sus mensajes y sus subcarpetas? También se eliminarán del servidor.
ui-properties = &Propiedades
ui-account-sync = &Enviar y recibir
ui-account-properties = P&ropiedades...
ui-account-move-up = Mover &arriba
ui-account-move-down = Mover a&bajo
ui-menu-open = &Abrir
ui-menu-flag = Marc&a
ui-menu-view-source = Ver &código fuente
ui-save-attachments = Guardar archivos adjuntos
# review: new
ui-attachment-open = Abrir
# review: new
ui-attachment-save-as = Guardar como...
# review: new
ui-attachment-save-all = Guardar todos...
# review: new
ui-attachments-strip = Archivos adjuntos
# review: new
ui-attachment-note-title = Abrir este archivo
# review: new
ui-attachment-program-tip = Abrir no está disponible para este tipo de archivo: puede ejecutar programas. Guárdelo para abrirlo usted mismo.
ui-clear-flag = &Quitar marca
ui-button-move = &Mover
ui-button-copy = &Copiar
ui-find-folder = Buscar una carpeta
ui-new-folder-in = La nueva carpeta se crea dentro de { $folder }.
ui-outbox-send-all = &Enviar todo ahora
ui-yes = Sí
ui-no = No
ui-try-again = Reintentar
ui-remove = &Quitar
ui-signature-of = Firma - { $account }
ui-sign-in-with = Iniciar sesión con { $provider }
ui-sign-in-in-browser-yours = Inicie sesión en su cuenta en la ventana del navegador que se abrió y luego vuelva aquí.
ui-browser-sign-in-server = { $server } (inicio de sesión en el navegador)
ui-dont-allow = No permitir
ui-allow = &Permitir
ui-dont-send = No enviar
ui-edit-first = &Modificar antes
ui-new-address = Dirección nueva
ui-turn-away = &Rechazar
ui-clear-agent-log = ¿Borrar el historial de los agentes?
ui-clear-agent-log-detail = Esto no deshará los cambios realizados por los agentes.
ui-let-agents-connect = &Permitir que los agentes de IA se conecten a Inbox Classic
ui-change-button = Cambiar…
ui-undo-button = Deshacer
ui-rules-title = Reglas de mensajes
ui-rules-intro = Las reglas organizan los mensajes nuevos que llegan a sus bandejas de entrada mientras Inbox Classic está abierto. Las reglas cuyos criterios se cumplen se aplican por orden. Cuando una mueve un mensaje fuera de la Bandeja de entrada, no se le aplican más reglas.
ui-rules-none = Aún no hay reglas. Haga clic en Nueva para crear una.
ui-rule-new = &Nueva...
ui-rule-edit = &Editar...
ui-rule-delete-button = Eli&minar
ui-rule-title = Regla de mensaje
ui-rule-name = Nombre:
ui-rule-account = Cuenta:
ui-rule-all-accounts = Todas las cuentas
ui-rule-query = Criterios de búsqueda:
ui-rule-query-hint = Use los mismos términos que en el cuadro de búsqueda, por ejemplo from:ana@example.com, subject:factura o list:news.example.com.
ui-rule-count = { $count ->
    [one] Actualmente, 1 mensaje de la Bandeja de entrada cumple estos criterios.
   *[other] Actualmente, { $count } mensajes de la Bandeja de entrada cumplen estos criterios.
}
ui-rule-show = M&ostrar
ui-rule-actions = Acciones:
ui-rule-move = &Moverlo a:
ui-rule-mark-read = Marcarlo como &leído
ui-rule-flag = Ma&rcarlo
ui-rule-archive = &Archivarlo
ui-rule-junk = Moverlo a &Correo no deseado
ui-rule-delete = &Eliminarlo
ui-rule-quiet = &No avisarme
ui-rule-apply-now = Aplicarla también a los mensajes que ya están en la &Bandeja de entrada
ui-rule-delete-ask = ¿Eliminar la regla «{ $name }»?
ui-create-rule = Crear regla...
ui-rules-applied = { $count ->
    [one] Sus reglas ordenaron 1 mensaje
   *[other] Sus reglas ordenaron { $count } mensajes
}
ui-col-rule-matches = Criterios
ui-clear-button = &Borrar
ui-how-to-connect = Cómo conectar un agente…
ui-agent-programs = Programas cuyos agentes pidieron usar su correo
ui-what-agents-did = Historial de los agentes
ui-restart-now = &Reiniciar ahora
ui-restart-later = Más &tarde

## The Address Book (Tools > Address Book), Contact and Group Properties, Select Recipients

ui-tb-new-contact = Nuevo contacto
ui-tb-new-group = Nuevo grupo
ui-tb-properties = Propiedades
ui-tb-write-to = Escribir a
ui-menu-new-contact = Nuevo &contacto...
ui-menu-new-group = Nuevo &grupo...
ui-menu-write-to = &Escribir a
ui-menu-delete = E&liminar
ui-book-find-hint = Escriba un nombre o una dirección de correo
ui-book-all-contacts = Todos los contactos
ui-col-phone = Teléfono
ui-book-empty = La libreta de direcciones está vacía. Haga clic en «Nuevo contacto» para añadir un contacto o importe un archivo vCard o CSV desde el menú Archivo.
ui-book-no-match = Ningún contacto coincide con «{ $words }».
ui-book-delete-ask = { $count ->
    [one] ¿Eliminar este contacto de la libreta de direcciones?
   *[other] ¿Eliminar estos { $count } contactos de la libreta de direcciones?
}
ui-group-delete-ask = ¿Eliminar el grupo «{ $name }»? Sus miembros permanecen en la libreta de direcciones.
ui-book-no-address = { $name } no tiene dirección de correo electrónico.
ui-new-contact-title = Nuevo contacto
ui-contact-title = Propiedades de { $name }
ui-contact-first = Nombre:
ui-contact-last = Apellidos:
ui-contact-display = Nombre para mostrar:
ui-contact-nickname = Alias:
ui-contact-company = Empresa:
ui-contact-addresses = Direcciones de correo electrónico:
ui-contact-address-hint = Escriba una dirección de correo electrónico
ui-contact-add = &Añadir
ui-contact-set-default = Establecer como &predeterminada
ui-contact-default = { $address } (predeterminada)
ui-contact-phones = Números de teléfono:
ui-phone-home = Casa
ui-phone-work = Trabajo
ui-phone-mobile = Móvil
ui-phone-other = Otro
ui-contact-notes = Notas:
ui-contact-name-needed = Escriba un nombre o una dirección de correo electrónico para el contacto.
ui-contact-address-invalid = «{ $address }» no es una dirección de correo electrónico válida.
ui-contact-not-saved = No se pudo guardar el contacto: { $reason }
ui-new-group-title = Nuevo grupo
ui-group-title = Propiedades de { $name }
ui-group-name = Nombre del grupo:
ui-group-members = Miembros:
ui-group-select-members = &Seleccionar miembros...
ui-group-new-member = Añada una dirección de correo electrónico que no esté en la libreta de direcciones:
ui-group-name-needed = Escriba un nombre para el grupo.
ui-group-not-saved = No se pudo guardar el grupo: { $reason }
ui-group-members-count = { $count ->
    [one] 1 miembro
   *[other] { $count } miembros
}
ui-select-recipients = Seleccionar destinatarios
ui-select-members = Seleccionar miembros del grupo
ui-pick-intro = Escriba un nombre o selecciónelo en la lista:
ui-pick-recipients = Destinatarios del mensaje:
ui-pick-members = Miembros del grupo:
ui-pick-to = &Para →
ui-pick-cc = &CC →
ui-pick-bcc = CC&O →
ui-pick-add = &Añadir →
ui-pick-tip = Elegir destinatarios de la libreta de direcciones
ui-filter-address-books = Libretas de direcciones (vCard, CSV)
ui-filter-vcard = Archivos vCard
ui-book-export-name = Libreta de direcciones
ui-book-imported = { $added ->
    [one] Se añadió 1 contacto.
   *[other] Se añadieron { $added } contactos.
} { $skipped ->
    [0] No se encontraron contactos duplicados.
    [one] Se omitió 1 contacto que ya estaba en la libreta de direcciones.
   *[other] Se omitieron { $skipped } contactos que ya estaban en la libreta de direcciones.
}
ui-book-not-imported = No se pudo importar la libreta de direcciones: { $reason }
ui-book-exported = { $count ->
    [one] 1 contacto guardado en { $file }.
   *[other] { $count } contactos guardados en { $file }.
}
ui-book-not-exported = No se pudo guardar la libreta de direcciones: { $reason }
ui-code-copied = Código copiado
# review: changed
ui-codes-in-notifications = &Mostrar los códigos de inicio de sesión en los avisos de correo nuevo
ui-tool-unread-only = No leídos
ui-no-unread = Aquí no hay mensajes sin leer.
ui-pictures-always-sender = Descargar siempre las imágenes de { $sender }
ui-pictures-always-domain = Descargar siempre las imágenes de los remitentes del dominio { $domain }
ui-pictures-unconfirmed = No se pudo verificar el dominio del remitente ({ $domain }). Por eso, las imágenes de este mensaje no se descargan automáticamente.
# review: changed
ui-pictures-always-option = Descargar &las imágenes de todos los mensajes
ui-pictures-always-warning = Los remitentes podrán saber cuándo lee sus mensajes.
# review: new
ui-protection-details = &Detalles...
# review: new
ui-protection-details-title = Detalles de seguridad
ui-download-heading = Descarga
# review: changed
ui-download-ahead = &Descargar mensajes con antelación:
ui-download-ahead-recent = Mensajes recientes de hasta 1 MB
ui-download-ahead-all = Todos los mensajes
ui-download-ahead-never = Solo al abrirlos
# review: changed
ui-download-limit = &Espacio máximo por cuenta:
# review: changed
ui-send-delay = &Retraso antes de enviar:
ui-send-delay-note = Mientras un mensaje esté pendiente de envío, puede cancelar el envío con Deshacer.
ui-dark-messages = Mostrar los mensajes sobre fondo oscuro cuando el sistema esté en modo oscuro
ui-sending-in = Se enviará { $subject } en { $count ->
    [one] 1 segundo
   *[other] { $count } segundos
}
ui-send-undone = { $subject } no se envió. El mensaje se ha vuelto a abrir para editarlo.
ui-send-too-late = { $subject } ya se envió.
ui-outbox-status-undo = Se envía a las { $time }
ui-download-note = Los mensajes descargados con antelación se abren al instante. Cuando se supera el límite de almacenamiento, se eliminan las copias locales más antiguas y se vuelven a descargar al abrir los mensajes.
ui-attachment-downloading = La descarga de este mensaje aún no ha terminado. Vuelva a intentarlo cuando finalice.
# review: changed
ui-trusted-senders-button = &Remitentes de confianza...
ui-trusted-senders-title = Remitentes de confianza
ui-trusted-senders-note = Las imágenes de los mensajes de estos remitentes se descargan automáticamente cuando su proveedor de correo verifica el dominio del remitente.
ui-trusted-everyone-at = Todos los remitentes del dominio { $domain }
ui-trusted-senders-empty = Aún no hay remitentes de confianza.
# review: new
ui-search-encrypted = &Buscar en mensajes cifrados
# review: new
ui-search-encrypted-note = Los mensajes cifrados se descifran en este equipo una vez descargados o abiertos, para que se puedan encontrar sus palabras y la lista muestre su propio asunto. El índice no está cifrado y los agentes de IA nunca buscan en él. Desactívelo para quitarlos del índice.
# review: new
ui-pgp-keyserver = Buscar claves &en keys.openpgp.org
# review: new
ui-pgp-keyserver-note = Cuando cifra un mensaje o busca una clave, la dirección buscada se envía a keys.openpgp.org. Antes se consulta al propio dominio de la dirección.
# review: changed
ui-eml-default = Abrir &los archivos .eml con Inbox Classic
ui-eml-default-done = Inbox Classic abre ahora los archivos .eml.
ui-eml-default-failed = No se pudo establecer Inbox Classic como aplicación predeterminada para los archivos .eml: { $reason }
ui-folders = Carpetas
ui-sorted-by = Orden: { $field }
# review: changed
ui-layout-label = &Diseño:
ui-columns-note = La ventana es lo bastante ancha para el diseño en columnas. Puede cambiar el diseño en Ver > Diseño.
ui-row-unread = No leído
ui-row-flagged = Marcado
ui-row-attachments = Con archivos adjuntos
# review: new
ui-row-encrypted = Cifrado
# review: new
ui-row-signed = Firmado
ui-row-messages = { $count ->
    [one] { $count } mensaje
   *[other] { $count } mensajes
}
# review: changed
ui-list-pictures = &Mostrar las imágenes de los remitentes en la lista de mensajes
# review: changed
ui-list-pictures-note = En el diseño en columnas, muestra logotipos de marca o fotos de la libreta de direcciones para los remitentes verificados, e iniciales si no hay imagen disponible. Los logotipos se descargan una vez por marca, no por cada mensaje.
ui-card-picture = Imagen:
ui-card-picture-choose = &Elegir...
ui-picture-not-picture = Este archivo no es una imagen PNG ni JPEG.
ui-picture-too-large = Esta imagen es demasiado grande. Elija una de un máximo de 10 MB, con un ancho y un alto de hasta 8000 píxeles.

## Encryption keys (Tools > Encryption Keys, Account Properties > Security, a contact's key)
# review: new
ui-keys-title = Claves de cifrado
# review: new
ui-keys-intro = Sus claves firman sus mensajes y abren el correo cifrado para usted. Las claves de sus contactos comprueban sus firmas y cifran el correo para ellos.
# review: new
ui-keys-empty = Aún no hay claves. Haga clic en Nueva clave para crear la suya, o en Importar para añadir una que ya tenga.
# review: new
ui-keys-col-name = Nombre
# review: new
ui-keys-col-address = Dirección
# review: new
ui-keys-col-kind = Tipo
# review: new
ui-keys-col-status = Estado
# review: new
ui-keys-kind-own = Su clave
# review: new
ui-keys-kind-contact = Contacto
# review: new
ui-keys-status-verified = { $status }, verificada
# review: new
ui-keys-new = &Nueva clave...
# review: new
ui-keys-import = &Importar...
# review: new
ui-keys-export = &Exportar...
# review: new
ui-keys-backup = Copia de &seguridad...
# review: new
ui-keys-verify = &Verificar...
# review: new
ui-keys-new-title = Nueva clave
# review: new
ui-keys-new-for = Crear una clave para:
# review: new
ui-keys-new-make = &Crear clave
# review: new
ui-keys-no-account = Añada primero una cuenta de correo: la clave se crea para las direcciones de una cuenta.
# review: new
ui-keys-memory-only = Las contraseñas se guardan solo en memoria, así que una clave privada creada o importada ahora no se podrá usar después de cerrar Inbox Classic.
# review: new
ui-keys-backup-offer = Su nueva clave está lista. ¿Guardar ahora una copia de seguridad? Si este equipo se pierde o se restablece, la clave solo se puede recuperar de una copia.
# review: new
ui-keys-backup-now = &Guardar una copia...
# review: new
ui-keys-later = &Más tarde
# review: new
ui-keys-backup-title = Copia de seguridad de la clave
# review: new
ui-keys-backup-intro = La copia está protegida por una frase de contraseña. Guarde el archivo y la frase en lugares seguros distintos: necesita ambos para recuperar la clave.
# review: new
ui-keys-passphrase = &Frase de contraseña:
# review: new
ui-keys-passphrase-again = &Repítala:
# review: new
ui-keys-passphrase-differ = Las frases de contraseña no coinciden.
# review: new
ui-keys-passphrase-short = Use una frase de contraseña de al menos 8 caracteres.
# review: new
ui-keys-backup-saved = Se guardó la copia de seguridad.
# review: new
ui-keys-import-title = Importar clave
# review: new
ui-keys-import-passphrase = Esta clave privada está protegida por una frase de contraseña. Escríbala para importar la clave:
# review: new
ui-keys-file-filter = Claves OpenPGP
# review: new
ui-keys-use-for = ¿Usar esta clave para { $addresses }? Sus mensajes desde allí se firmarán con ella, y el correo cifrado para ella se podrá leer aquí.
# review: new
ui-keys-use = &Usarla
# review: new
ui-keys-not-now = &Ahora no
# review: new
ui-keys-remove-own = ¿Quitar su clave { $fingerprint }? El correo cifrado para ella ya no se podrá leer aquí, salvo que vuelva a importar su copia de seguridad.
# review: new
ui-keys-remove-contact = ¿Quitar la clave de { $name }? No se podrán comprobar sus firmas ni cifrar correo para esa persona hasta que vuelva a añadir su clave.
# review: new
ui-key-properties-title = Propiedades de la clave
# review: new
ui-key-names = Nombres:
# review: new
ui-key-fingerprint = Huella:
# review: new
ui-key-status = Estado:
# review: new
ui-key-created = Creada:
# review: new
ui-key-expires = Caduca:
# review: new
ui-key-never = Nunca
# review: new
ui-key-algorithm = Algoritmo:
# review: new
ui-key-source = Origen:
# review: new
ui-key-addresses = Direcciones:
# review: new
ui-key-address-verified = { $address } (verificada)
# review: new
ui-key-address-not-verified = { $address } (sin verificar)
# review: new
ui-verify-title = Verificar clave
# review: new
ui-verify-intro = Pida a { $name } que le lea la huella de su clave desde su propia aplicación, en persona o por teléfono. No la compare con una enviada por correo: quien pudiera cambiar la clave también podría cambiar eso.
# review: new
ui-verify-fingerprint = La huella de la clave que tiene:
# review: new
ui-verify-marks = { $count ->
    [one] Si coinciden, la clave se marca como suya para { $addresses }. Si esa dirección no es suya, haga clic en «No coinciden».
   *[other] Si coinciden, la clave se marca como suya para { $addresses }. Si alguna de estas direcciones no es suya, haga clic en «No coinciden».
}
# review: new
ui-verify-match = &Coinciden
# review: new
ui-verify-differ = &No coinciden
# review: new
ui-verify-differs = La clave que tiene no es la de { $name }. Quítela y pídale su clave de nuevo.
# review: new
ui-verify-unmark = Marcar como &no verificada
# review: new
ui-account-security = Seguridad
# review: new
ui-account-security-intro = Con una clave, sus mensajes se pueden firmar y otras personas le pueden enviar correo cifrado.
# review: new
ui-account-key = &Clave de esta cuenta:
# review: new
ui-account-key-none = Ninguna
# review: new
ui-account-key-new = &Nueva clave...
# review: new
ui-account-autocrypt = &Enviar mi clave pública con mis mensajes (Autocrypt)
# review: new
ui-contact-key = Clave de cifrado:
# review: new
ui-contact-key-none = Sin clave
# review: new
ui-contact-key-use-new = &Usar la nueva clave
# review: new
ui-contact-key-keep = &Mantener la actual
# review: new
ui-recipient-keys-title = Claves de los destinatarios
# review: new
ui-recipient-col-recipient = Destinatario
# review: new
ui-recipient-col-key = Clave
# review: new
ui-recipient-find-key = &Buscar clave
# review: new
ui-recipient-remove = &Quitar del mensaje
# review: new
ui-send-unencrypted = Enviar &sin cifrar
# review: new
ui-compose-make-key = C&rear una clave...
# review: new
ui-compose-show-keys = Claves de &cifrado...
# review: new
ui-compose-encrypt-off = &Desactivar el cifrado
# review: new
ui-compose-keep-encrypted = &Mantenerlo cifrado
# review: new
ui-setup-export-title = Exportar configuración y cuentas
# review: new
ui-setup-import-title = Importar configuración y cuentas
# review: new
ui-setup-export-intro = Elija qué llevar a otro equipo. El archivo no contiene mensajes: se descargan de nuevo allí.
# review: new
ui-setup-use-passphrase = &Proteger el archivo con una frase de contraseña
# review: new
ui-setup-passphrase-note = Con una frase de contraseña, el archivo se cifra y contiene también sus contraseñas, inicios de sesión y claves privadas. Sin ella, cada cuenta pide su contraseña en el otro equipo.
# review: new
ui-setup-export-button = &Exportar...
# review: new
ui-setup-file-filter = Configuración y cuentas de Inbox Classic
# review: new
ui-setup-ask-passphrase = Este archivo está protegido por una frase de contraseña. Escríbala para ver lo que contiene:
# review: new
ui-setup-import-intro = Elija qué importar. Las cuentas que ya están en este equipo se dejan como están.
# review: new
ui-setup-from = Guardado por Inbox Classic { $version } el { $date }.
# review: new
ui-setup-import-button = &Importar
# review: new
ui-setup-done = Listo
# review: new
ui-setup-first-run = Importar configuración y cuentas de otro equipo...
