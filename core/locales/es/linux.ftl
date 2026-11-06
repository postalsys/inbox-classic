# The words of the Linux app's own windows (linux/src), ids starting with gtk-. Placeables in { $braces } are filled in
# by the app; an _ marks a button's mnemonic letter. GNOME words where GNOME has them (Preferences, Quit).

## The main window

gtk-search-mail = Buscar en el correo
gtk-find-tip = Busca palabras en el asunto, las personas, los nombres de archivo y el texto de los mensajes.
gtk-clear-search = Borrar la búsqueda
gtk-from-account = Desde { $account }
gtk-the-account = la cuenta
gtk-column-folder = Carpeta
gtk-column-account = Cuenta
gtk-search-looks-everywhere = La búsqueda mira el asunto, las personas, los nombres de archivo y el texto de los mensajes de todas las carpetas. Revise la ortografía o pruebe con menos palabras.
gtk-search-looks-in = La búsqueda mira el asunto, las personas, los nombres de archivo y el texto de los mensajes de { $place }. Revise la ortografía o pruebe con menos palabras.
gtk-search-still-indexing = { $count ->
    [one] El texto de { $count } mensaje aún se está indexando, así que pronto puede encontrarse más.
   *[other] El texto de { $count } mensajes aún se está indexando, así que pronto puede encontrarse más.
}
gtk-search-no-match = Ningún mensaje coincide con «{ $words }».
gtk-list-empty = No hay elementos en esta vista.
gtk-list-choose-folder = Elija una carpeta para ver sus mensajes.
gtk-all-inboxes = Todas las bandejas de entrada
gtk-all-folders = Todas las carpetas
gtk-search-results-everywhere = { $count ->
    [0] Ningún resultado
    [one] { $count } resultado
   *[other] { $count } resultados
} para «{ $words }» en todas las carpetas
gtk-search-results-in = { $count ->
    [0] Ningún resultado
    [one] { $count } resultado
   *[other] { $count } resultados
} para «{ $words }» en { $place }
gtk-search-indexing = { $count ->
    [one] aún se indexa el texto de { $count } mensaje
   *[other] aún se indexa el texto de { $count } mensajes
}
gtk-toolbar-junk = No deseado
gtk-toolbar-not-junk = Deseado
gtk-menu-rename = Cambiar nombre...
gtk-menu-delete = Eliminar
gtk-new-folder-in-selected = La nueva carpeta se crea dentro de la carpeta seleccionada.
gtk-new-folder-at-top = La nueva carpeta se crea en el nivel superior de la cuenta.
gtk-new-folder-title = Nueva carpeta
gtk-rename-folder-intro = El nuevo nombre de la carpeta { $folder }.
gtk-rename-folder-title = Cambiar nombre de carpeta
gtk-delete-folder-question = ¿Eliminar la carpeta «{ $folder }» con sus mensajes y las carpetas que contiene? También se elimina en el servidor.
gtk-not-downloaded = El mensaje aún no se ha descargado.
gtk-mail-messages = Mensajes de correo
gtk-save-message-as = Guardar mensaje como
gtk-message-not-saved = No se pudo guardar el mensaje.
gtk-save-messages-in = Guardar mensajes en
gtk-select-message-first = Seleccione primero un mensaje.
gtk-properties = Propiedades
gtk-properties-of = Propiedades de { $subject }
gtk-internet-headers = Encabezados de Internet de este mensaje:
gtk-menu-open = Abrir
gtk-menu-flag = Marca
gtk-menu-view-source = Ver código fuente
gtk-import-choose-folder = Elija primero la carpeta donde poner los mensajes.
gtk-import-one-question = ¿Poner el mensaje { $file } en la carpeta { $folder }?
gtk-attachment-not-read = No se pudo leer el archivo adjunto.
gtk-save-attachment-as = Guardar archivo adjunto como
gtk-attachment-not-saved = No se pudo guardar el archivo adjunto.
gtk-save-attachments = Guardar archivos adjuntos
gtk-files-not-saved = No se pudieron guardar { $failed } de los { $total } archivos.
gtk-invitation-not-read = No se pudo leer la invitación.
gtk-no-calendar-program = Ningún programa de calendario de este equipo abre invitaciones (archivos .ics).
gtk-cancel = Cancelar
gtk-ok = Aceptar
gtk-unsubscribe = Cancelar suscripción
gtk-unsubscribe-one-click =
    ¿Salir de esta lista de correo?

    Inbox Classic pide a { $target } que deje de enviársela. No se abre ninguna página ni se envía ningún mensaje.
gtk-unsubscribing = Cancelando la suscripción a { $target }...
gtk-can-not-unsubscribe = Este mensaje no permite cancelar la suscripción.
gtk-unsubscribe-mail =
    ¿Salir de esta lista de correo?

    La lista pide un mensaje a { $target }. Inbox Classic lo escribe por usted; envíelo para cancelar la suscripción.
gtk-unsubscribe-web =
    ¿Salir de esta lista de correo?

    La página de la lista para ello se abre en su navegador ({ $target }).
gtk-unsubscribed = Suscripción cancelada. La lista dice que dejará de enviar este correo.
gtk-unsubscribe-failed = No se pudo cancelar la suscripción: { $problem }
gtk-toolbar-create-mail = Crear correo
gtk-toolbar-create-mail-menu = Un mensaje desde una cuenta
gtk-toolbar-send-recv = Enviar y recibir
gtk-toolbar-send-recv-menu = Enviar y recibir una cuenta
gtk-toolbar-reply = Responder
gtk-toolbar-reply-all = Responder a todos
gtk-toolbar-forward = Reenviar
gtk-toolbar-print = Imprimir
gtk-toolbar-delete = Eliminar
gtk-toolbar-mark-read = Leído
gtk-toolbar-mark-unread = No leído
gtk-main-menu = Menú principal
gtk-quit = Salir
gtk-clear-flag = Quitar marca

## The Move and Copy window

gtk-button-move = Mover
gtk-button-copy = Copiar
gtk-find-folder = Buscar una carpeta
gtk-new-folder-in = La nueva carpeta se crea dentro de { $folder }.
gtk-new-folder-at-top-of = La nueva carpeta se crea en el nivel superior de { $account }.

## The message list

gtk-column-from = De
gtk-column-subject = Asunto
gtk-column-received = Recibido
gtk-column-size = Tamaño

## Help

gtk-help-title = Ayuda de Inbox Classic

## Notifications and the tray

gtk-unread-messages = { $count ->
    [0] No hay mensajes sin leer
    [one] { $count } mensaje sin leer
   *[other] { $count } mensajes sin leer
}
gtk-done = Listo

## The compose window's link menu

gtk-open-link = Abrir vínculo
gtk-edit-link = Editar vínculo...
gtk-remove-link = Quitar vínculo

## The Outbox

gtk-no-subject = (sin asunto)
gtk-outbox-title = Bandeja de salida
gtk-outbox-empty = Nada espera para enviarse.
gtk-outbox-send-all = Enviar todo ahora
gtk-outbox-delete = Eliminar
gtk-outbox-delete-ask = ¿Eliminar este mensaje sin enviarlo?
gtk-outbox-waiting = En espera
gtk-outbox-not-sent = No enviado: { $reason }
gtk-outbox-agent = Enviado por un agente de IA; sale a las { $time }
gtk-outbox-row = Para: { $to }  ·  En cola { $queued }  ·  { $status }

## The app

gtk-store-not-opened = No se pudo abrir el almacén de correo.
gtk-store-or-cert-not-opened = No se pudo abrir el almacén de correo o el archivo de certificado.
gtk-checking = Buscando mensajes nuevos en { $account }...
gtk-sent-at = { $subject } enviado a las { $time }
gtk-draft-saved = Mensaje guardado en Borradores.
gtk-draft-not-saved = El mensaje no se guardó en Borradores: { $reason }
gtk-newest-from = El más reciente, de { $sender }: { $subject }
gtk-new-messages = { $count } mensajes nuevos
gtk-outbox-waits = { $subject } espera en la Bandeja de salida
gtk-outbox-sending = Enviando { $subject }...
gtk-outbox-count = { $count ->
    [one] { $count } mensaje en la Bandeja de salida
   *[other] { $count } mensajes en la Bandeja de salida
}
gtk-still-running = Inbox Classic sigue abierto
gtk-still-running-detail = Sigue buscando correo nuevo. Su icono en la barra superior lo vuelve a abrir o lo cierra.
gtk-add-account-first = Agregue primero una cuenta de correo.
gtk-add-account-first-link = Agregue primero una cuenta de correo y luego vuelva a hacer clic en el vínculo de correo.
gtk-quoted = «{ $subject }»
gtk-sign-in-again-ask =
    El inicio de sesión de { $account } se rechazó o caducó.

    ¿Iniciar sesión de nuevo en el navegador?
gtk-sign-in-again-failed = Volver a iniciar sesión no funcionó: { $reason }
gtk-default-app-not-installed = Esta copia de Inbox Classic no se instaló, por eso el sistema no la muestra como aplicación de correo. Instálela para elegirla.
gtk-default-app-is = Inbox Classic es su aplicación de correo predeterminada: los vínculos de correo abren aquí un mensaje nuevo.
gtk-default-app-now = Inbox Classic es ahora su aplicación de correo predeterminada: los vínculos de correo abren aquí un mensaje nuevo.
gtk-default-app-failed = No se pudo hacer de Inbox Classic la aplicación de correo predeterminada.
gtk-about-core = Núcleo { $version }

## Buttons and words used in many windows

gtk-yes = Sí
gtk-no = No
gtk-folder-name = Nombre de la carpeta:
gtk-all-files = Todos los archivos

## The reading pane

gtk-reader-from = De:
gtk-reader-to = Para:
gtk-reader-date = Fecha:
gtk-reader-files = Los archivos del mensaje
gtk-open-in-calendar = Abrir en el calendario
gtk-pictures-blocked = Se han bloqueado algunas imágenes para impedir que el remitente identifique su equipo.
gtk-download-pictures = Descargar imágenes
gtk-try-again = Reintentar
gtk-message-not-shown = No se pudo mostrar el mensaje.
gtk-save-attachments-menu = Guardar archivos adjuntos...
gtk-no-title = (sin título)
gtk-invitation = { $kind ->
    [update] Invitación actualizada: { $summary }
    [cancel] Cancelado: { $summary }
    [reply] Respuesta a una invitación: { $summary }
   *[request] Invitación: { $summary }
}
gtk-organizer = Organizador: { $organizer }
gtk-attendees = { $count ->
    [one] { $count } asistente
   *[other] { $count } asistentes
}
gtk-from-to = { $start } a { $end }
gtk-day-and-time = { $day }, { $time }
gtk-senders-time = { $when } (hora del remitente)

## The compose window

gtk-format-bold = Negrita (Ctrl+B)
gtk-format-italic = Cursiva (Ctrl+I)
gtk-format-underline = Subrayado (Ctrl+U)
gtk-format-font-color = Color de fuente
gtk-format-numbered-list = Lista numerada
gtk-format-bulleted-list = Lista con viñetas
gtk-format-decrease-indent = Reducir sangría
gtk-format-increase-indent = Aumentar sangría
gtk-format-align-left = Alinear a la izquierda
gtk-format-center = Centrar
gtk-format-align-right = Alinear a la derecha
gtk-format-hyperlink = Hipervínculo (Ctrl+K)
gtk-format-insert-horizontal-line = Insertar línea horizontal
gtk-format-insert-picture = Insertar imagen
gtk-font = Fuente
gtk-font-size = Tamaño
gtk-link-invalid = Escriba una dirección web (https://...) o un vínculo de correo (mailto:...).
gtk-edit-hyperlink = Editar hipervínculo
gtk-edit-hyperlink-intro = Adónde lleva el vínculo. Vacíe la dirección para quitar el vínculo y conservar su texto.
gtk-hyperlink = Hipervínculo
gtk-hyperlink-intro = La dirección a la que lleva el texto seleccionado.
gtk-link-address = Dirección:
gtk-pictures = Imágenes
gtk-insert-picture = Insertar imagen
gtk-not-a-picture = Este archivo no es una imagen PNG, JPEG o GIF, o es mayor de 10 MB.
gtk-show-cc = _CC
gtk-show-bcc = CC_O
gtk-compose-from = De:
gtk-compose-to = Para:
gtk-compose-cc = CC:
gtk-compose-bcc = CCO:
gtk-compose-subject = Asunto:
gtk-compose-attach = Adjuntar:
gtk-send = Enviar
gtk-save-tip = Guardar (Ctrl+S)
gtk-attach-tip = Adjuntar
gtk-new-message = Mensaje nuevo
gtk-remove = Quitar
gtk-link-status = { $link }    (Ctrl+clic para abrir)
gtk-insert-attachment = Insertar archivo adjunto
gtk-saving-draft = Guardando en Borradores...
gtk-save-changes = ¿Desea guardar los cambios de este mensaje en Borradores?
gtk-not-saved-in-drafts = No se guardó en Borradores: { $reason }
gtk-saved-in-drafts-at = Guardado en Borradores a las { $time }
gtk-signature-hint = Se agrega a los mensajes nuevos, las respuestas y los reenvíos de esta cuenta.
gtk-signature-of = Firma - { $account }
gtk-signature = Firma
gtk-signature-not-saved = No se pudo guardar la firma.

## Accounts

gtk-add-mail-account = Agregar cuenta de correo
gtk-account-not-saved = No se pudo guardar la cuenta.
gtk-security-none = Ninguna (sin cifrar)
gtk-field-required = { $field } es obligatorio.
gtk-address-not-valid = La dirección de correo no es válida.
gtk-ports-are-numbers = Los puertos son números del 1 al 65535.
gtk-display-name = Nombre para mostrar:
gtk-email-address = Dirección de correo:
gtk-user-name = Nombre de usuario:
gtk-password = Contraseña:
gtk-imap-server = Servidor entrante (IMAP):
gtk-imap-port = Puerto IMAP:
gtk-imap-security = Seguridad IMAP:
gtk-smtp-server = Servidor saliente (SMTP):
gtk-smtp-port = Puerto SMTP:
gtk-smtp-security = Seguridad SMTP:
gtk-plain-warning =
    Sin cifrado, su contraseña y su correo viajan por la red legibles para cualquiera en el camino. Úselo solo para un servidor en su propio equipo o red.

    ¿Continuar?
gtk-sign-in-with = Iniciar sesión con { $provider }
gtk-the-provider = su proveedor
gtk-more-sign-in = Más opciones de inicio de sesión...
gtk-display-name-title = Nombre para mostrar
gtk-email-address-title = Dirección de correo
gtk-other-account-intro = Cualquier otra cuenta de correo: su nombre tal como lo ven los demás y su dirección de correo. Sus servidores se buscan a continuación.
gtk-type-address = Escriba su dirección de correo, nombre@example.com.
gtk-turned-off-why = { $button } está desactivado en este equipo. { $reason }
gtk-turned-off-why-long =
    { $button } está desactivado en este equipo.

    { $reason }
gtk-turned-off = Desactivado en este equipo.
gtk-why = ¿Por qué?
gtk-add-sign-in-app = Agregar una aplicación de inicio de sesión...
gtk-browser-sign-in-not-started = No se pudo iniciar sesión mediante el navegador.
gtk-sign-in-in-browser = Inicie sesión en { $account } en la ventana del navegador que se abrió y luego vuelva aquí.
gtk-sign-in-in-browser-yours = Inicie sesión en su cuenta en la ventana del navegador que se abrió y luego vuelva aquí.
gtk-signing-in-failed = El inicio de sesión no funcionó: { $reason }
gtk-looking-up = Buscando la configuración de { $domain }...
gtk-found-none = Escriba los datos de la cuenta que le dio su proveedor de correo.
gtk-found-guess = No se encontró configuración para esta dirección: estos son los nombres habituales, compruébelos con su proveedor.
gtk-found-mx = Su correo lo gestiona un proveedor que Inbox Classic conoce; estos son sus servidores.
gtk-found-srv = Esta configuración se encontró en los registros DNS de su dominio.
gtk-found-autodiscover = Esta configuración la encontró Microsoft Autodiscover (Exchange).
gtk-found-other = Esta configuración se encontró para esta dirección.
gtk-found-change = Cámbiela si su proveedor le dio otra.
gtk-app-password-needed = { $provider } no acepta su contraseña normal en los programas de correo. Cree una contraseña de aplicación en su cuenta de { $provider } y escríbala en el campo Contraseña del siguiente formulario.
gtk-open-instructions = ¿Abrir las instrucciones de { $provider } en su navegador?
gtk-start-intro = Gmail, Google Workspace, Outlook.com y Microsoft 365: inicie sesión en la página de Google o de Microsoft. Su contraseña se escribe allí, nunca en Inbox Classic.
gtk-start-intro-apps = Inicie sesión mediante el navegador con una de sus aplicaciones de inicio de sesión (Más opciones de inicio de sesión), o agregue cualquier cuenta de correo con su nombre y dirección abajo.
gtk-next = Siguiente >
gtk-provider-sign-in = { $address } inicia sesión en la página de { $provider }, sin dar su contraseña a Inbox Classic. O use una contraseña de aplicación creada en la configuración de seguridad de su cuenta.
gtk-provider-sign-in-apps = { $address } puede iniciar sesión en la página de { $provider } con una de sus aplicaciones de inicio de sesión (Más opciones de inicio de sesión). O use una contraseña de aplicación creada en la configuración de seguridad de su cuenta.
gtk-use-app-password = Usar contraseña de aplicación
gtk-finish = Finalizar
gtk-enter-password = Escriba la contraseña de { $account }.
gtk-logon = Inicio de sesión
gtk-signs-in-with = Inicia sesión con: { $app }. Inicia sesión mediante el navegador y usa los servidores de su inicio de sesión.
gtk-keep-password = Deje la contraseña vacía para conservar la que tiene.
gtk-browser-sign-in-server = { $server } (inicio de sesión en el navegador)
gtk-accounts-add = Agregar...
gtk-accounts-properties = Propiedades...
gtk-accounts-signature = Firma...
gtk-accounts-sign-in-apps = Aplicaciones de inicio de sesión...
gtk-accounts-title = Cuentas
gtk-remove-account = Quitar cuenta
gtk-remove-account-ask = ¿Quitar esta cuenta de Inbox Classic? Su correo permanece en el servidor; se quitan la copia de este equipo y la contraseña guardada.

## Sign-in apps

gtk-sign-in-app = Aplicación de inicio de sesión
gtk-remove-sign-in-app = Quitar aplicación de inicio de sesión
gtk-check = Comprobar
gtk-app-server = Servidor { $kind }
gtk-app-port = Puerto { $kind }
gtk-app-security = Seguridad { $kind }
gtk-preset-name = Aplicación de inicio de sesión de { $provider }
gtk-checking-issuer = Comprobando { $issuer }...
gtk-issuer-found =
    Página de inicio de sesión: { $page }
    Punto de conexión de tokens: { $endpoint }
gtk-app-editor-intro = Un cliente OAuth que registró con su proveedor, para las cuentas que inician sesión mediante el navegador. Rellénelo para un proveedor y luego agregue el ID de cliente (y el secreto, si el proveedor le dio uno).
gtk-fill-in-for = Rellenar para:
gtk-app-name = Nombre
gtk-issuer = Emisor
gtk-client-id = ID de cliente
gtk-client-secret = Secreto de cliente
gtk-secret-saved = Hay un secreto guardado; escriba otro para sustituirlo, o quítelo
gtk-scopes = Ámbitos (scopes)
gtk-register-it = Regístrelo con su proveedor
gtk-redirect-uri = URI de redirección
gtk-copy-button = Copiar
gtk-add-sign-in-app-title = Agregar aplicación de inicio de sesión
gtk-issuer-usable =
    El emisor se puede usar.

    { $found }
gtk-issuer-not-usable = El emisor no se puede usar: { $reason }
gtk-app-not-saved = No se pudo guardar la aplicación de inicio de sesión: { $reason }
gtk-app-built-in = { $app } es integrada: solo puede cambiar si se usa para cuentas nuevas. { $reason }
gtk-client-with-secret = ID de cliente: { $client }, con un secreto de cliente.
gtk-client-public = ID de cliente: { $client }, un cliente público (sin secreto).
gtk-no-accounts = Ninguna cuenta
gtk-built-in = { $app } (integrada)
gtk-offered-for-new = Ofrecida para cuentas nuevas
gtk-edit-button = Editar...
gtk-sign-in-apps-title = Aplicaciones de inicio de sesión
gtk-remove-app-ask = ¿Quitar la aplicación de inicio de sesión { $app } y su secreto de cliente guardado?
gtk-app-not-removed = No se quitó la aplicación de inicio de sesión: { $reason }
gtk-sign-in-apps-intro = Las aplicaciones de inicio de sesión permiten que las cuentas inicien sesión mediante el navegador. Una desactivada no se ofrece para cuentas nuevas; las cuentas que ya la usan siguen funcionando.

## AI agents

gtk-agent-program = Programa: { $path }
gtk-agent-it-may = Puede
gtk-agent-accounts = Cuentas que puede usar
gtk-dont-allow = No permitir
gtk-allow = Permitir
gtk-dont-send = No enviar
gtk-edit-first = Editar primero
gtk-new-address = Dirección nueva
gtk-never-used = Nunca usado
gtk-last-used = Usado por última vez { $date }
gtk-turn-away = Rechazar
gtk-forget-program = ¿Olvidar este programa?
gtk-forget-program-detail = Se le vuelve a preguntar la próxima vez que se conecte, y se olvida lo que hicieron sus agentes.
gtk-ai-agents = Agentes de IA
gtk-clear-agent-log = ¿Borrar la lista de lo que hicieron los agentes?
gtk-clear-agent-log-detail = Lo que hicieron sigue hecho.
gtk-let-agents-connect = Permitir que los agentes de IA se conecten a Inbox Classic
gtk-no-agents-yet = Ningún agente ha pedido aún usar su correo.
gtk-nothing-yet = Nada todavía.
gtk-change-button = Cambiar…
gtk-undo-button = Deshacer
gtk-clear-button = Borrar
gtk-how-to-connect = Cómo conectar un agente…
gtk-agent-programs = Programas cuyos agentes pidieron usar su correo
gtk-what-agents-did = Lo que hicieron los agentes
gtk-connect-agent = Conectar un agente de IA
gtk-connect-agent-intro = Agregue esto a los servidores MCP de su agente (Claude Desktop: Settings > Developer > Edit Config):

## Preferences

gtk-preferences = Preferencias
gtk-language = Idioma
gtk-language-subtitle = Las palabras de las ventanas y de la ayuda
gtk-system-default = Predeterminado del sistema ({ $language })
gtk-new-mail-group = Correo nuevo
gtk-notify-subtitle = Una notificación cuando llegan mensajes nuevos mientras la ventana está en segundo plano
gtk-restart-to-change = Inbox Classic se reinicia para cambiar el idioma.
gtk-restart-now = Reiniciar ahora
gtk-restart-later = Más tarde
