# Las palabras de las ventanas de la aplicación de Windows (app/src), identificadores que empiezan por win-. La
# aplicación rellena lo que va entre { $llaves }; un & marca la letra de un elemento de menú o de un botón (&& es un &).

## La ventana principal

win-tb-create-mail = Crear correo
win-tb-reply = Responder
win-tb-reply-all = Resp. a todos
win-tb-forward = Reenviar
win-tb-print = Imprimir
win-tb-delete = Eliminar
win-tb-junk = No deseado
win-tb-not-junk = Deseado
win-tb-sync = Enviar y recibir
win-tb-mark-read = Leído
win-tb-mark-unread = No leído
win-flag-menu = &Marca
win-still-running = Inbox Classic sigue abierto
win-still-running-detail = Sigue buscando correo nuevo aquí. Haga clic en el icono para abrirlo, o haga clic con el botón derecho para salir.
win-no-subject = (sin asunto)
win-quoted = «{ $subject }»
win-new-messages = { $count ->
    [one] { $count } mensaje nuevo
   *[other] { $count } mensajes nuevos
}
win-newest-from = El más reciente, de { $sender }: { $subject }
win-outbox-waiting = { $count ->
    [one] { $count } mensaje en la Bandeja de salida
   *[other] { $count } mensajes en la Bandeja de salida
}
win-outbox-waits = { $subject } espera en la Bandeja de salida
win-outbox-sending = Enviando { $subject }...
win-from-account = De { $account }
win-sign-in-refused = El inicio de sesión de { $account } se rechazó o caducó.
win-sign-in-again-ask = ¿Iniciar sesión de nuevo en el navegador?
win-sign-in-again-failed = El nuevo inicio de sesión no funcionó: { $reason }
win-unknown-reason = motivo desconocido
win-checking = Buscando mensajes nuevos en { $account }...
win-done = Listo
win-sent-at = { $subject } enviado a las { $time }
win-draft-saved = Mensaje guardado en Borradores.
win-draft-not-saved = El mensaje no se guardó en Borradores: { $reason }
win-about-core = Núcleo { $version }
win-add-account-first = Agregue primero una cuenta de correo.
win-add-account-first-link = Agregue primero una cuenta de correo y luego vuelva a hacer clic en el vínculo de correo.
win-default-app-is = Inbox Classic es su programa de correo predeterminado: los vínculos de correo abren aquí un mensaje nuevo.
win-default-app-not-installed = Esta copia de Inbox Classic no se instaló, por eso Windows no la muestra como programa de correo. Instálela para elegirla.
win-default-app-settings = Windows abre su configuración de aplicaciones predeterminadas para Inbox Classic. Elíjalo allí para MAILTO.
win-select-message-first = Seleccione primero un mensaje.
win-store-not-opened = No se pudo abrir el almacén de correo.
win-store-or-cert-not-opened = No se pudo abrir el almacén de correo o el archivo del certificado.
win-no-unread = No hay mensajes sin leer
win-unread-messages = { $count ->
    [one] { $count } mensaje sin leer
   *[other] { $count } mensajes sin leer
}
win-help-title = Ayuda de Inbox Classic
win-help-missing = La ayuda falta en esta copia de Inbox Classic.
win-print-failed = No se pudo imprimir el mensaje.
win-print-title = Imprimir
win-print-title-of = Imprimir: { $subject }
win-no-bodies = No se puede mostrar el contenido de los mensajes.
win-webview-failed = No se pudo crear el WebView2.
win-webview-missing = El entorno de ejecución de WebView2 no está disponible.

## Botones y palabras de varias ventanas

win-ok = Aceptar
win-cancel = Cancelar
win-close = Cerrar
win-delete-button = &Eliminar
win-find-label = &Buscar:
win-col-subject = Asunto
win-col-to = Para
win-col-from = De
win-col-received = Recibido
win-col-size = Tamaño
win-col-folder = Carpeta
win-col-account = Cuenta
win-col-queued = En cola
win-col-status = Estado
win-save-as-button = Guardar &como...
win-too-many-files = Demasiados archivos a la vez: elija menos.

## La Bandeja de salida

win-outbox-title = Bandeja de salida
win-outbox-status-waiting = En espera
win-outbox-status-not-sent = No enviado: { $reason }
win-outbox-status-agent = Enviado por un agente de IA; sale a las { $time }
win-outbox-delete-ask = ¿Eliminar este mensaje sin enviarlo?
win-outbox-send-all = &Enviar todo ahora

## La ventana de redacción

win-editor-failed = No se pueden escribir mensajes.
win-open-link = Abrir vínculo
win-edit-link = Modificar vínculo...
win-remove-link = Quitar vínculo
win-ctrl-click-to-open = ({ $ctrl }+clic para abrir)
win-insert-attachment = Insertar archivo adjunto
win-insert-picture = Insertar imagen
win-filter-all = Todos los archivos
win-filter-pictures = Imágenes
win-filter-messages = Mensajes de correo
win-save-attachment-as = Guardar archivo adjunto como
win-remove-file = &Quitar
win-not-sent = No se pudo enviar el mensaje.
win-not-saved = No se pudo guardar el mensaje.
win-saving-draft = Guardando en Borradores...
win-compose-saved-at = Guardado en Borradores a las { $time }
win-compose-not-saved = No guardado en Borradores: { $reason }
win-save-changes-ask = ¿Desea guardar los cambios de este mensaje en Borradores?
win-new-message-title = Mensaje nuevo
win-link-invalid = Escriba una dirección web (https://...) o un vínculo de correo (mailto:...).
win-link-address = Dirección:
win-hyperlink = Hipervínculo
win-hyperlink-intro = La dirección a la que lleva el texto seleccionado.
win-edit-hyperlink = Modificar hipervínculo
win-edit-hyperlink-intro = Adónde lleva el vínculo. Vacíe la dirección para quitar el vínculo y conservar su texto.
win-not-a-picture = Este archivo no es una imagen PNG, JPEG o GIF, o tiene más de 10 MB.
win-format-bold = Negrita ({ $ctrl }+B)
win-format-italic = Cursiva ({ $ctrl }+I)
win-format-underline = Subrayado ({ $ctrl }+U)
win-format-color = Color de fuente
win-format-numbers = Lista numerada
win-format-bullets = Lista con viñetas
win-format-outdent = Reducir sangría
win-format-indent = Aumentar sangría
win-format-left = Alinear a la izquierda
win-format-center = Centrar
win-format-right = Alinear a la derecha
win-format-link = Hipervínculo ({ $ctrl }+K)
win-format-line = Insertar línea horizontal
win-tb-send = Enviar
win-tb-save = Guardar
win-tb-attach = Adjuntar
win-field-from = De:
win-field-to = Para:
win-field-cc = CC:
win-field-bcc = CCO:
win-field-subject = Asunto:
win-field-attach = Adjunto:
win-show-cc = &CC
win-show-bcc = CC&O
win-signature = Firma
win-signature-title = Firma: { $account }
win-signature-hint = Se agrega a los mensajes nuevos, respuestas y reenvíos de esta cuenta.
win-signature-not-saved = No se pudo guardar la firma.

## Las carpetas, la lista de mensajes y el panel de lectura

win-all-inboxes = Todas las bandejas de entrada
win-all-folders = Todas las carpetas
win-the-account = la cuenta
win-folder-name = Nombre de la carpeta:
win-find-hint = Buscar en el correo
win-find-tip = Busca palabras en el asunto, las personas, los nombres de archivo y el texto de los mensajes.
win-clear-search = Borrar búsqueda
win-search-found-all = { $count ->
    [0] No hay resultados para «{ $words }» en todas las carpetas
    [one] { $count } resultado para «{ $words }» en todas las carpetas
   *[other] { $count } resultados para «{ $words }» en todas las carpetas
}
win-search-found-in = { $count ->
    [0] No hay resultados para «{ $words }» en { $folder }
    [one] { $count } resultado para «{ $words }» en { $folder }
   *[other] { $count } resultados para «{ $words }» en { $folder }
}
win-search-indexing = { $count ->
    [one] aún se indexa el texto de { $count } mensaje
   *[other] aún se indexa el texto de { $count } mensajes
}
win-no-match = Ningún mensaje coincide con «{ $words }».
win-no-match-all = La búsqueda mira el asunto, las personas, los nombres de archivo y el texto de los mensajes de todas las carpetas. Revise la ortografía o pruebe con menos palabras.
win-no-match-in = La búsqueda mira el asunto, las personas, los nombres de archivo y el texto de los mensajes de { $folder }. Revise la ortografía o pruebe con menos palabras.
win-no-match-indexing = { $count ->
    [one] El texto de { $count } mensaje aún se está indexando, así que pronto puede encontrarse más.
   *[other] El texto de { $count } mensajes aún se está indexando, así que pronto puede encontrarse más.
}
win-no-items = No hay elementos en esta vista.
win-choose-folder = Elija una carpeta para ver sus mensajes.
win-unsubscribe = Cancelar suscripción
win-open-in-calendar = Abrir en el calendario
win-files = { $count ->
    [one] { $count } archivo
   *[other] { $count } archivos
}
win-pictures-blocked = Se bloquearon algunas imágenes para evitar que el remitente identifique su equipo. Haga clic aquí para descargar las imágenes.
win-click-to-retry = Haga clic aquí para volver a intentarlo.
win-not-shown = No se pudo mostrar el mensaje.
win-save-attachments = &Guardar archivos adjuntos...
win-attachment-not-read = No se pudo leer el archivo adjunto.
win-attachment-not-saved = No se pudo guardar el archivo adjunto.
win-not-downloaded = El mensaje aún no se ha descargado.
win-files-not-saved = No se pudieron guardar { $failed } de los { $count } archivos.
win-leave-list = ¿Salir de esta lista de correo?
win-leave-one-click = Inbox Classic pide a { $target } que deje de enviárselo. No se abre ninguna página ni se envía ningún mensaje.
win-leave-mail = La lista pide un mensaje a { $target }. Inbox Classic lo escribe por usted; envíelo para cancelar la suscripción.
win-leave-web = La página de la lista para ello se abre en su navegador ({ $target }).
win-unsubscribing = Cancelando la suscripción a { $target }...
win-cannot-unsubscribe = Este mensaje no permite cancelar la suscripción.
win-unsubscribed = Suscripción cancelada. La lista dice que dejará de enviar este correo.
win-not-unsubscribed = No se pudo cancelar la suscripción: { $reason }
win-event-span = { $start } a { $end }
win-event-floating = { $when } (hora del remitente)
win-invitation = Invitación: { $title }
win-invitation-updated = Invitación actualizada: { $title }
win-invitation-canceled = Cancelado: { $title }
win-invitation-answer = Respuesta a una invitación: { $title }
win-no-title = (sin título)
win-organizer = Organizador: { $name }
win-attendees = { $count ->
    [one] { $count } asistente
   *[other] { $count } asistentes
}
win-invitation-not-read = No se pudo leer la invitación.
win-no-calendar = Ningún programa de calendario de este equipo abre invitaciones (archivos .ics).
win-messages-not-changed = No se pudieron cambiar los mensajes.
win-copy-button = &Copiar
win-move-button = &Mover
win-new-folder-in-highlighted = La carpeta nueva va dentro de la carpeta resaltada.
win-new-folder-in-selected = La carpeta nueva va dentro de la carpeta seleccionada.
win-new-folder-at-top = La carpeta nueva va en el nivel superior de la cuenta.
win-folder-not-created = No se pudo crear la carpeta.
win-folder-not-renamed = No se pudo cambiar el nombre de la carpeta.
win-folder-not-deleted = No se pudo eliminar la carpeta.
win-rename-folder-intro = El nuevo nombre de la carpeta { $folder }.
win-delete-folder-ask = ¿Eliminar la carpeta «{ $folder }» con sus mensajes y las carpetas que contiene? También se elimina en el servidor.
win-clear-flag = &Quitar marca
win-rename = Cambiar &nombre...
win-open = &Abrir
win-view-source = Ver &código fuente
win-properties = &Propiedades
win-properties-of = Propiedades de { $subject }
win-internet-headers = Encabezados de Internet de este mensaje:
win-save-messages-in = Guardar mensajes en
win-save-message-as = Guardar mensaje como
win-messages-not-saved = No se pudieron guardar los mensajes.
win-messages-not-forwarded = No se pudieron reenviar los mensajes.
win-import-choose-folder = Elija primero la carpeta donde poner los mensajes.

## Cuentas

win-add-account-title = Agregar cuenta de correo
win-accounts-title = Cuentas
win-security-none = Ninguna (sin cifrar)
win-field-required = { $field } es obligatorio.
win-email-invalid = La dirección de correo no es válida.
win-ports-invalid = Los puertos son números del 1 al 65535.
win-looking-up = Buscando la configuración de { $domain }...
win-found-none = Escriba los datos de la cuenta que le dio su proveedor de correo.
win-found-change = Cámbielos si su proveedor le dio otros.
win-found-guess = No se encontró configuración para esta dirección: estos son los nombres habituales, compruébelos con su proveedor.
win-found-mx = Su correo lo gestiona un proveedor que Inbox Classic conoce; estos son sus servidores.
win-found-srv = Esta configuración se encontró en los registros DNS de su dominio.
win-found-autodiscover = Esta configuración se encontró mediante la detección automática de Microsoft (Exchange).
win-found-other = Esta configuración se encontró para esta dirección.
win-app-password-needed = { $provider } no acepta su contraseña normal en programas de correo. Cree una contraseña de aplicación en su cuenta de { $provider } y escríbala en el campo Contraseña del siguiente formulario.
win-app-password-open = ¿Abrir las instrucciones de { $provider } en el navegador?
win-plain-warning = Sin cifrado, su contraseña y su correo viajan por la red legibles para cualquiera en el camino. Úselo solo para un servidor en su propio equipo o red.
win-continue-ask = ¿Continuar?
win-sign-in-google = Iniciar sesión con Google
win-sign-in-microsoft = Iniciar sesión con Microsoft
win-add-sign-in-app = Agregar una aplicación de inicio de sesión...
win-turned-off = { $name } está desactivado en este equipo.
win-off-here = Desactivado en este equipo.
win-why = ¿Por qué?
win-more-sign-in = Más opciones de inicio de sesión...
win-next = &Siguiente >
win-other-account = Cualquier otra cuenta de correo: su nombre tal como lo ven los demás y su dirección de correo. Sus servidores se buscan a continuación.
win-field-name = Nombre para mostrar:
win-field-email = Dirección de correo:
win-field-user = Nombre de usuario:
win-field-password = Contraseña:
win-field-imap-host = Servidor de entrada (IMAP):
win-field-imap-port = Puerto IMAP:
win-field-imap-security = Seguridad IMAP:
win-field-smtp-host = Servidor de salida (SMTP):
win-field-smtp-port = Puerto SMTP:
win-field-smtp-security = Seguridad SMTP:
win-sign-in-not-started = No se pudo iniciar la sesión en el navegador.
win-your-account = su cuenta
win-sign-in-in-browser = Inicie sesión en { $account } en la ventana del navegador que se abrió y luego vuelva aquí.
win-sign-in-failed = El inicio de sesión no funcionó: { $reason }
win-account-not-saved = No se pudo guardar la cuenta.
win-start-intro = Gmail, Google Workspace, Outlook.com y Microsoft 365: inicie sesión en la página de Google o de Microsoft. Su contraseña se escribe allí, nunca en Inbox Classic.
win-start-intro-apps = Inicie sesión en el navegador con una de sus aplicaciones de inicio de sesión (Más opciones de inicio de sesión), o agregue abajo cualquier cuenta de correo con su nombre y su dirección.
win-use-app-password = Usar contraseña de aplicación
win-the-provider = su proveedor
win-provider-intro = { $email } inicia sesión en la página de { $provider }, sin dar su contraseña a Inbox Classic. O use una contraseña de aplicación creada en la configuración de seguridad de su cuenta.
win-provider-intro-apps = { $email } puede iniciar sesión en la página de { $provider } con una de sus aplicaciones de inicio de sesión (Más opciones de inicio de sesión). O use una contraseña de aplicación creada en la configuración de seguridad de su cuenta.
win-finish = Finalizar
win-logon = Iniciar sesión
win-enter-password = Escriba la contraseña de { $account }.
win-browser-sign-in = (inicio de sesión en el navegador)
win-signs-in-with = Inicia sesión con: { $app }. Inicia sesión en el navegador y usa los servidores de su inicio de sesión.
win-keep-password = Deje la contraseña vacía para conservar la que tiene.
win-remove-account = Quitar cuenta
win-remove-account-ask = ¿Quitar esta cuenta de Inbox Classic? Su correo se queda en el servidor; se quitan la copia de este equipo y la contraseña guardada.
win-col-email = Dirección de correo
win-col-incoming = Servidor de entrada
win-add = &Agregar...
win-properties-button = &Propiedades...
win-signature-button = &Firma...
win-sign-in-apps-button = Aplicaciones de &inicio de sesión...
win-type-email = Escriba su dirección de correo, nombre@example.com.

## Agentes de IA

win-ai-agent = Agente de IA
win-ai-agent-access = Acceso de agentes de IA
win-ai-agents = Agentes de IA
win-program-path = Programa: { $path }
win-it-may = Puede:
win-accounts-it-may-use = Cuentas que puede usar:
win-allow = &Permitir
win-dont-allow = &No permitir
win-turn-away = &Rechazar
win-send-message-ask = ¿Enviar el mensaje?
win-col-address = Dirección
win-col-name = Nombre
win-never-written-to = Nunca escrito
win-send = &Enviar
win-edit-first = &Modificar antes
win-dont-send = &No enviar
win-never = Nunca
win-forget-program-ask = ¿Olvidar este programa y lo que hicieron sus agentes? Se volverá a preguntar la próxima vez que se conecte.
win-clear-log-ask = ¿Borrar la lista de lo que hicieron los agentes? Lo que hicieron queda hecho.
win-connect-agent = Conectar un agente de IA
win-connect-agent-intro = Agregue esto a los servidores MCP de su agente (Claude Desktop: Settings > Developer > Edit Config):
win-let-agents-connect = &Permitir que los agentes de IA se conecten a Inbox Classic
win-agent-programs = P&rogramas cuyos agentes pidieron usar su correo:
win-col-program = Programa
win-col-may = Puede
win-col-last-used = Último uso
win-change = &Cambiar...
win-what-agents-did = &Lo que hicieron los agentes:
win-col-when = Cuándo
win-col-what = Qué
win-clear = &Borrar
win-how-to-connect = Cómo conectar un agente

## Aplicaciones de inicio de sesión

win-sign-in-app = Aplicación de inicio de sesión
win-sign-in-apps = Aplicaciones de inicio de sesión
win-add-sign-in-app-title = Agregar aplicación de inicio de sesión
win-preset-app-name = Aplicación de inicio de sesión de { $provider }
win-issuer-not-checked = no se puede comprobar el emisor
win-checking-issuer = Comprobando { $issuer }...
win-issuer-unusable = No se puede usar el emisor: { $reason }
win-issuer-usable = Se puede usar el emisor.
win-sign-in-app-not-saved = No se pudo guardar la aplicación de inicio de sesión: { $reason }
win-check = Comprobar
win-check-button = Co&mprobar
win-copy = &Copiar
win-fill-in-for = Rellenar para:
win-app-name = Nombre:
win-issuer = Emisor:
win-client-id = Id. de cliente:
win-client-secret = Secreto de cliente:
win-scopes = Ámbitos:
win-imap-server = Servidor IMAP:
win-smtp-server = Servidor SMTP:
win-redirect-uri = URI de redirección:
win-sign-in-app-intro = Un cliente OAuth que registró con su proveedor, para las cuentas que inician sesión en el navegador. Rellénelo para un proveedor y luego agregue el Id. de cliente (y el secreto, si el proveedor le dio uno).
win-remove-secret = Hay un secreto guardado; escriba otro para reemplazarlo, o quítelo
win-register-it = Regístrelo con su proveedor
win-built-in-note = { $name } está integrado: solo puede cambiar si se usa para cuentas nuevas.
win-client-with-secret = Id. de cliente: { $client }, con un secreto de cliente.
win-client-public = Id. de cliente: { $client }, un cliente público (sin secreto).
win-built-in = (integrado)
win-no-accounts = Ninguna cuenta
win-remove-sign-in-app = Quitar aplicación de inicio de sesión
win-remove-sign-in-app-ask = ¿Quitar la aplicación de inicio de sesión { $name } y su secreto de cliente guardado?
win-sign-in-app-not-removed = No se quitó la aplicación de inicio de sesión: { $reason }
win-sign-in-apps-intro = Las aplicaciones de inicio de sesión permiten que las cuentas inicien sesión en el navegador. Una que no esté marcada no se ofrece a las cuentas nuevas; las cuentas que ya la usan siguen funcionando.
win-col-issuer = Emisor
win-col-used-by = Usada por
win-edit = &Modificar...

## Opciones

win-options-language-label = &Mostrar Inbox Classic en:
win-options-system-default = Idioma del sistema ({ $language })
win-options-restart-note = Inbox Classic se reinicia para mostrar otro idioma.
win-options-notify = &Avisarme cuando llegue correo nuevo
win-restart-ask = Inbox Classic se mostrará en el idioma elegido ({ $language }) después de reiniciarse. ¿Reiniciar ahora?
win-restart-now = &Reiniciar ahora
win-restart-later = Más &tarde
