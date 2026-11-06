# Español. Borrador, pendiente de revisión por un hablante nativo.

## The app and its menus

mac-store-not-opened = No se pudo abrir el almacén de correo.
mac-store-or-certificate-not-opened = No se pudo abrir el almacén de correo o el archivo del certificado.
mac-quit = Salir de Inbox Classic
mac-settings = Ajustes…
mac-services = Servicios
mac-hide = Ocultar Inbox Classic
mac-hide-others = Ocultar otros
mac-show-all = Mostrar todo
mac-check-updates = Buscar actualizaciones…
mac-close-window = Cerrar ventana
mac-redo = Rehacer
mac-cut = Cortar
mac-copy = Copiar
mac-paste = Pegar
mac-menu-window = Ventana
mac-minimize = Minimizar
mac-zoom = Zoom
mac-help-title = Ayuda de Inbox Classic
mac-no-updates = Esta copia de Inbox Classic no se actualiza sola. Descargue la última versión en inboxclassic.com.
mac-flag = Marca
mac-clear-flag = Quitar marca

## Settings

mac-settings-title = Ajustes
mac-language-label = Idioma:
mac-system-default = Idioma del sistema ({ $language })
mac-restart-hint = Inbox Classic se reinicia para cambiar de idioma.
mac-notify-new-mail = Avisarme cuando llegue correo nuevo
mac-restart-question = ¿Reiniciar Inbox Classic ahora para cambiar de idioma?
mac-restart-now = Reiniciar ahora
mac-restart-later = Más tarde

## Dialogs

mac-ok = Aceptar
mac-cancel = Cancelar
mac-yes = Sí
mac-no = No
mac-folder-name = Nombre de la carpeta:
mac-save-attachment-as = Guardar archivo adjunto como
mac-choose = Elegir
mac-messages-not-changed = No se pudieron cambiar los mensajes.

## The main window

mac-still-running = Inbox Classic sigue abierto
mac-still-running-detail = Sigue comprobando si hay correo nuevo. Haga clic en su icono del Dock para volver a abrirlo.
mac-no-subject = (sin asunto)
mac-quoted = «{ $subject }»
mac-outbox-waiting =
    { $count ->
        [one] { $count } mensaje en la Bandeja de salida
       *[other] { $count } mensajes en la Bandeja de salida
    }
mac-outbox-waits = { $subject } espera en la Bandeja de salida
mac-sending = Enviando { $subject }…
mac-checking = Comprobando si hay mensajes nuevos en { $account }…
mac-done = Listo
mac-sent-at = { $subject } enviado a las { $time }
mac-draft-saved = Mensaje guardado en Borradores.
mac-draft-not-saved = El mensaje no se guardó en Borradores: { $reason }
mac-account-said = { $account }: { $message }
mac-new-messages =
    { $count ->
        [one] { $count } mensaje nuevo
       *[other] { $count } mensajes nuevos
    }
mac-newest-from = El más reciente, de { $from }: { $subject }
mac-sign-in-refused = El inicio de sesión de { $account } fue rechazado o caducó.
mac-sign-in-again = ¿Iniciar sesión de nuevo en el navegador?
mac-sign-in-failed = Volver a iniciar sesión no funcionó: { $reason }
mac-unknown-reason = motivo desconocido
mac-core-version = Núcleo { $version }
mac-add-account-first = Agregue primero una cuenta de correo.
mac-add-account-first-link = Agregue primero una cuenta de correo y luego vuelva a hacer clic en el enlace de correo.
mac-select-message-first = Seleccione primero un mensaje.
mac-not-bundle = Esta copia de Inbox Classic no es un paquete de aplicación, así que no puede ser la app de correo predeterminada.
mac-is-default = Inbox Classic es su app de correo predeterminada: los enlaces de correo abren aquí un mensaje nuevo.
mac-not-made-default = Inbox Classic no se convirtió en la app de correo predeterminada: { $reason }
mac-tool-create-mail = Crear correo
mac-tool-reply = Responder
mac-tool-reply-all = Resp. a todos
mac-tool-forward = Reenviar
mac-tool-print = Imprimir
mac-tool-delete = Eliminar
mac-tool-junk = No deseado
mac-tool-not-junk = Deseado
mac-tool-sync = Enviar/Recibir
mac-tool-mark-read = Leído
mac-tool-mark-unread = No leído
mac-tool-search = Buscar
mac-search-mail = Buscar correo
mac-find-tip = Busca palabras en el asunto, las personas, los nombres de archivo y el texto de los mensajes.
mac-from-account = De { $account }

## The folders and the message list

mac-clear-search = Borrar búsqueda
mac-all-inboxes = Todas las bandejas de entrada
mac-the-account = la cuenta
mac-all-folders = Todas las carpetas
mac-column-received = Recibido
mac-column-size = Tamaño
mac-column-folder = Carpeta
mac-column-account = Cuenta
mac-no-match = Ningún mensaje coincide con «{ $words }».
mac-search-looks-everywhere = La búsqueda mira el asunto, las personas, los nombres de archivo y el texto de los mensajes de todas las carpetas. Revise la ortografía o pruebe con menos palabras.
mac-search-looks-in = La búsqueda mira el asunto, las personas, los nombres de archivo y el texto de los mensajes de { $folder }. Revise la ortografía o pruebe con menos palabras.
mac-still-indexing-more =
    { $count ->
        [one] El texto de { $count } mensaje aún se está indexando, así que pronto puede encontrarse más.
       *[other] El texto de { $count } mensajes aún se está indexando, así que pronto puede encontrarse más.
    }
mac-no-items = No hay elementos en esta vista.
mac-choose-folder = Elija una carpeta para ver sus mensajes.
mac-results-everywhere =
    { $count ->
        [0] No hay resultados para «{ $words }» en todas las carpetas
        [one] { $count } resultado para «{ $words }» en todas las carpetas
       *[other] { $count } resultados para «{ $words }» en todas las carpetas
    }
mac-results-in =
    { $count ->
        [0] No hay resultados para «{ $words }» en { $folder }
        [one] { $count } resultado para «{ $words }» en { $folder }
       *[other] { $count } resultados para «{ $words }» en { $folder }
    }
mac-still-indexing =
    { $count ->
        [one] aún se indexa el texto de { $count } mensaje
       *[other] aún se indexa el texto de { $count } mensajes
    }
mac-folder-unread = { $folder }, { $count } sin leer
mac-message-not-shown = No se pudo mostrar el mensaje.
mac-delete = Eliminar
mac-move-button = Mover
mac-copy-button = Copiar
mac-new-folder = Nueva carpeta
mac-new-folder-in-selected = La nueva carpeta se crea dentro de la carpeta seleccionada.
mac-new-folder-at-top = La nueva carpeta se crea en el nivel superior de la cuenta.
mac-folder-not-created = No se pudo crear la carpeta.
mac-rename-folder = Cambiar nombre de carpeta
mac-rename-folder-intro = El nuevo nombre de la carpeta { $folder }.
mac-folder-not-renamed = No se pudo cambiar el nombre de la carpeta.
mac-delete-folder-question = ¿Eliminar la carpeta «{ $folder }» con sus mensajes y las carpetas que contiene? También se elimina en el servidor.
mac-folder-not-deleted = No se pudo eliminar la carpeta.
mac-not-downloaded = El mensaje aún no se ha descargado.
mac-save-message-as = Guardar mensaje como
mac-message-not-saved = No se pudo guardar el mensaje.
mac-properties = Propiedades
mac-properties-of = Propiedades de { $subject }
mac-internet-headers = Encabezados de Internet de este mensaje:
mac-close = Cerrar
mac-open = Abrir
mac-view-source = Ver código fuente
mac-import-messages = Importar mensajes
mac-import-choose-folder = Elija primero la carpeta en la que poner los mensajes.
mac-save-messages = Guardar mensajes
mac-save-attachments-menu = Guardar archivos adjuntos…
mac-save-attachments = Guardar archivos adjuntos
mac-attachment-not-read = No se pudo leer el archivo adjunto.
mac-attachment-not-saved = No se pudo guardar el archivo adjunto.
mac-files-not-saved =
    { $count ->
       *[other] No se pudieron guardar { $failed } de los { $count } archivos.
    }
mac-invitation-not-read = No se pudo leer la invitación.
mac-no-calendar-app = Ninguna app de calendario de este Mac abre invitaciones (archivos .ics).
mac-leave-list = ¿Salir de esta lista de correo?
mac-unsubscribe = Cancelar suscripción
mac-unsubscribe-one-click = Inbox Classic pide a { $target } que deje de enviársela. No se abre ninguna página ni se envía ningún mensaje.
mac-unsubscribe-mail = La lista quiere un mensaje a { $target }. Inbox Classic lo escribe por usted; envíelo para cancelar la suscripción.
mac-unsubscribe-web = La página de la lista para ello se abre en su navegador ({ $target }).
mac-unsubscribing = Cancelando la suscripción a { $target }…
mac-can-not-unsubscribe = Este mensaje no permite cancelar la suscripción.
mac-unsubscribed = Suscripción cancelada. La lista dice que dejará de enviar este correo.
mac-not-unsubscribed = No se pudo cancelar la suscripción: { $reason }

## The compose window

mac-bold = Negrita
mac-italic = Cursiva
mac-underline = Subrayado
mac-numbered-list = Lista numerada
mac-bulleted-list = Lista con viñetas
mac-align-left = Alinear a la izquierda
mac-center = Centrar
mac-align-right = Alinear a la derecha
mac-font-color = Color de fuente
mac-decrease-indent = Reducir sangría
mac-increase-indent = Aumentar sangría
mac-hyperlink = Hipervínculo
mac-edit-hyperlink = Editar hipervínculo
mac-hyperlink-intro = La dirección a la que enlaza el texto seleccionado.
mac-edit-hyperlink-intro = Adónde lleva el enlace. Vacíe la dirección para quitar el enlace y conservar su texto.
mac-link-address = Dirección:
mac-link-invalid = Escriba una dirección web (https://...) o un enlace de correo (mailto:...).
mac-horizontal-line = Insertar línea horizontal
mac-insert-picture = Insertar imagen
mac-not-a-picture = Este archivo no es una imagen PNG, JPEG o GIF, o supera los 10 MB.
mac-bcc = CCO
mac-new-message = Mensaje nuevo
mac-field-from = De:
mac-field-to = Para:
mac-field-cc = CC:
mac-field-bcc = CCO:
mac-field-subject = Asunto:
mac-field-attach = Adjuntar:
mac-command-click-to-open = ⌘-clic para abrir
mac-remove = Quitar
mac-insert-attachment = Insertar archivo adjunto
mac-message-not-sent = No se pudo enviar el mensaje.
mac-saving-to-drafts = Guardando en Borradores…
mac-save-changes-question = ¿Desea guardar los cambios de este mensaje en Borradores?
mac-save = Guardar
mac-dont-save = No guardar
mac-saved-in-drafts-at = Guardado en Borradores a las { $time }
mac-not-saved-in-drafts = No se guardó en Borradores: { $reason }
mac-send = Enviar
mac-attach = Adjuntar
mac-signature = Firma
mac-signature-title = Firma - { $account }
mac-signature-hint = Se añade a los mensajes nuevos, las respuestas y los reenvíos de esta cuenta.
mac-signature-not-saved = No se pudo guardar la firma.

## The reading pane

mac-open-in-calendar = Abrir en Calendario
mac-try-again = Reintentar
mac-pictures-blocked = Se bloquearon algunas imágenes para impedir que el remitente identifique su ordenador. Haga clic aquí para descargar las imágenes.
mac-files =
    { $count ->
        [one] { $count } archivo
       *[other] { $count } archivos
    }
mac-invitation = Invitación: { $title }
mac-invitation-updated = Invitación actualizada: { $title }
mac-invitation-canceled = Cancelado: { $title }
mac-invitation-answer = Respuesta a una invitación: { $title }
mac-no-title = (sin título)
mac-organizer = Organizador: { $name }
mac-attendees =
    { $count ->
        [one] { $count } asistente
       *[other] { $count } asistentes
    }
mac-from-to = { $start } a { $end }
mac-senders-time = { $when } (hora del remitente)

## Accounts

mac-security-none = Ninguna (sin cifrar)
mac-field-required = { $field } es obligatorio.
mac-email-invalid = La dirección de correo no es válida.
mac-ports-invalid = Los puertos son números del 1 al 65535.
mac-plain-warning = Sin cifrado, su contraseña y su correo viajan por la red legibles para cualquiera en el camino. Úselo solo para un servidor en su propio ordenador o red.
mac-continue-question = ¿Continuar?
mac-display-name = Nombre para mostrar:
mac-email-address = Dirección de correo:
mac-user-name = Nombre de usuario:
mac-password = Contraseña:
mac-imap-server = Servidor entrante (IMAP):
mac-imap-port = Puerto IMAP:
mac-imap-security = Seguridad IMAP:
mac-smtp-server = Servidor saliente (SMTP):
mac-smtp-port = Puerto SMTP:
mac-smtp-security = Seguridad SMTP:
mac-sign-in-not-started = No se pudo iniciar la sesión a través del navegador.
mac-sign-in-waiting = Inicie sesión en { $account } en la ventana del navegador que se abrió y luego vuelva aquí.
mac-sign-in-waiting-any = Inicie sesión en su cuenta en la ventana del navegador que se abrió y luego vuelva aquí.
mac-add-mail-account = Agregar cuenta de correo
mac-sign-in-did-not-work = El inicio de sesión no funcionó: { $reason }
mac-sign-in-with = Iniciar sesión con { $provider }
mac-next = Siguiente
mac-name-placeholder = Ana García
mac-more-sign-in-options = Más opciones de inicio de sesión…
mac-any-other-account = Cualquier otra cuenta de correo: su nombre tal como lo ven los demás y su dirección de correo. Sus servidores se buscan a continuación.
mac-turned-off-named = { $name } está desactivado en este ordenador.
mac-turned-off = Desactivado en este ordenador.
mac-why = ¿Por qué?
mac-add-sign-in-app = Agregar una aplicación de inicio de sesión…
mac-type-email = Escriba su dirección de correo, nombre@example.com.
mac-found-none = Introduzca los datos de la cuenta que le dio su proveedor de correo.
mac-found-change = Cámbielos si su proveedor le dio otros.
mac-found-guess = No se encontraron ajustes para esta dirección: estos son los nombres habituales, compruébelos con su proveedor.
mac-found-mx = Su correo lo gestiona un proveedor que Inbox Classic conoce; estos son sus servidores.
mac-found-srv = Estos ajustes se encontraron en los registros DNS de su dominio.
mac-found-autodiscover = Estos ajustes los encontró Microsoft Autodiscover (Exchange).
mac-found-other = Estos ajustes se encontraron para esta dirección.
mac-app-password-needed = { $provider } no acepta su contraseña normal en los programas de correo. Cree una contraseña de aplicación en su cuenta de { $provider } y escríbala en el campo Contraseña del siguiente formulario.
mac-open-instructions = ¿Abrir las instrucciones de { $provider } en su navegador?
mac-account-not-saved = No se pudo guardar la cuenta.
mac-start-intro = Gmail, Google Workspace, Outlook.com y Microsoft 365: inicie sesión en la página de Google o de Microsoft. Su contraseña se escribe allí, nunca en Inbox Classic.
mac-start-intro-apps = Inicie sesión a través del navegador con una de sus aplicaciones de inicio de sesión (Más opciones de inicio de sesión) o agregue abajo cualquier cuenta de correo con su nombre y dirección.
mac-looking-up = Buscando los ajustes de { $domain }…
mac-use-app-password = Usar contraseña de aplicación
mac-the-provider = su proveedor
mac-signs-in-at = { $email } inicia sesión en la página de { $provider }, sin dar su contraseña a Inbox Classic. O use una contraseña de aplicación creada en los ajustes de seguridad de su cuenta.
mac-can-sign-in-at = { $email } puede iniciar sesión en la página de { $provider } con una de sus aplicaciones de inicio de sesión (Más opciones de inicio de sesión). O use una contraseña de aplicación creada en los ajustes de seguridad de su cuenta.
mac-finish = Finalizar
mac-logon = Iniciar sesión
mac-enter-password = Introduzca la contraseña de { $account }.
mac-signs-in-with = Inicia sesión con: { $app }. Inicia sesión a través del navegador y usa los servidores de su inicio de sesión.
mac-keep-password = Deje la contraseña vacía para conservar la que tiene.
mac-accounts = Cuentas
mac-column-email = Dirección de correo
mac-column-incoming = Servidor entrante
mac-add-button = Agregar…
mac-properties-button = Propiedades…
mac-signature-button = Firma…
mac-sign-in-apps-button = Aplicaciones de inicio de sesión…
mac-browser-sign-in = { $server } (inicio de sesión en el navegador)
mac-remove-account = Quitar cuenta
mac-remove-account-question = ¿Quitar esta cuenta de Inbox Classic? Su correo sigue en el servidor; se quitan la copia de este ordenador y la contraseña guardada.

## AI agents

mac-ai-agent = Agente de IA
mac-allow = Permitir
mac-dont-allow = No permitir
mac-program-path = Programa: { $path }
mac-it-may = Puede:
mac-accounts-it-may-use = Cuentas que puede usar:
mac-new-address = Dirección nueva
mac-send-message-question = ¿Enviar el mensaje?
mac-edit-first = Editar antes
mac-dont-send = No enviar
mac-let-agents-connect = Permitir que los agentes de IA se conecten a Inbox Classic
mac-change-button = Cambiar…
mac-undo-button = Deshacer
mac-clear = Borrar
mac-ai-agents = Agentes de IA
mac-column-program = Programa
mac-column-may = Puede
mac-column-last-used = Último uso
mac-column-when = Cuándo
mac-column-what = Qué
mac-how-to-connect = Cómo conectar un agente…
mac-agent-programs = Programas cuyos agentes pidieron usar su correo
mac-agent-log = Lo que hicieron los agentes
mac-never = Nunca
mac-ai-agent-access = Acceso del agente de IA
mac-turn-away = Rechazar
mac-forget-program = ¿Olvidar este programa y lo que hicieron sus agentes?
mac-forget-program-detail = Se le volverá a preguntar la próxima vez que se conecte.
mac-clear-log = ¿Borrar la lista de lo que hicieron los agentes?
mac-clear-log-detail = Lo que hicieron sigue hecho.
mac-connect-agent = Conectar un agente de IA
mac-connect-agent-intro = Agregue esto a los servidores MCP de su agente (Claude Desktop: Settings > Developer > Edit Config):

## Sign-in apps

mac-secret-saved = Hay un secreto guardado; escriba otro para sustituirlo, o quítelo
mac-add-sign-in-app-title = Agregar aplicación de inicio de sesión
mac-sign-in-app = Aplicación de inicio de sesión
mac-sign-in-apps = Aplicaciones de inicio de sesión
mac-sign-in-app-intro = Un cliente OAuth que registró con su proveedor, para las cuentas que inician sesión a través del navegador. Rellénelo para un proveedor y luego agregue el ID de cliente (y el secreto, si el proveedor le dio uno).
mac-check = Comprobar
mac-fill-in-for = Rellenar para:
mac-app-name = Nombre:
mac-issuer = Emisor:
mac-client-id = ID de cliente:
mac-client-secret = Secreto de cliente:
mac-scopes = Ámbitos:
mac-app-imap-server = Servidor IMAP:
mac-app-smtp-server = Servidor SMTP:
mac-register-it = Regístrela con su proveedor
mac-redirect-uri = URI de redirección:
mac-preset-app-name = Aplicación de inicio de sesión de { $provider }
mac-issuer-not-checked = no se puede comprobar el emisor
mac-checking-issuer = Comprobando { $issuer }…
mac-issuer-usable = El emisor se puede usar.
mac-issuer-not-usable = El emisor no se puede usar: { $reason }
mac-sign-in-app-not-saved = No se pudo guardar la aplicación de inicio de sesión: { $reason }
mac-edit-button = Editar…
mac-column-name = Nombre
mac-column-issuer = Emisor
mac-column-used-by = Usada por
mac-sign-in-apps-intro = Las aplicaciones de inicio de sesión permiten a las cuentas iniciar sesión a través del navegador. Una que no está marcada no se ofrece para cuentas nuevas; las cuentas que ya la usan siguen funcionando.
mac-use-for-new-accounts = Usar { $name } para cuentas nuevas
mac-built-in = { $name } (integrada)
mac-no-accounts = Ninguna cuenta
mac-built-in-note = { $name } está integrada: solo puede cambiarse si se usa para cuentas nuevas.
mac-client-with-secret = ID de cliente: { $client }, con un secreto de cliente.
mac-client-public = ID de cliente: { $client }, un cliente público (sin secreto).
mac-remove-sign-in-app = Quitar aplicación de inicio de sesión
mac-remove-sign-in-app-question = ¿Quitar la aplicación de inicio de sesión { $name } y su secreto de cliente guardado?
mac-sign-in-app-not-removed = No se quitó la aplicación de inicio de sesión: { $reason }

## Other windows

mac-find-folder = Buscar una carpeta
mac-new-folder-button = Nueva carpeta…
mac-new-folder-in = La nueva carpeta se crea dentro de { $folder }.
mac-send-all-now = Enviar todo ahora
mac-outbox = Bandeja de salida
mac-column-queued = En cola desde
mac-column-status = Estado
mac-not-sent = No enviado: { $reason }
mac-agent-goes-at = Enviado por un agente de IA; sale a las { $time }
mac-waiting = En espera
mac-delete-unsent = ¿Eliminar este mensaje sin enviarlo?
mac-open-link = Abrir enlace
mac-edit-link = Editar enlace…
mac-remove-link = Quitar enlace
mac-help-missing = Falta la ayuda en esta copia de Inbox Classic.
