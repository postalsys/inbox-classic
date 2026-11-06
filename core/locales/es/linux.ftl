# The words of the Linux app's own windows (linux/src), ids starting with gtk-. Placeables in { $braces } are filled in
# by the app; an _ marks a button's mnemonic letter. GNOME words where GNOME has them (Preferences, Quit).

## The main window

gtk-search-looks-in = La búsqueda mira el asunto, las personas, los nombres de archivo y el texto de los mensajes de { $place }. Revise la ortografía o pruebe con menos palabras.
gtk-search-still-indexing = { $count ->
    [one] El texto de { $count } mensaje aún se está indexando, así que pronto puede encontrarse más.
   *[other] El texto de { $count } mensajes aún se está indexando, así que pronto puede encontrarse más.
}
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
gtk-menu-rename = Cambiar nombre...
gtk-import-one-question = ¿Poner el mensaje { $file } en la carpeta { $folder }?
gtk-files-not-saved = No se pudieron guardar { $failed } de los { $total } archivos.
gtk-unsubscribe-one-click =
    ¿Salir de esta lista de correo?

    Inbox Classic pide a { $target } que deje de enviársela. No se abre ninguna página ni se envía ningún mensaje.
gtk-unsubscribe-mail =
    ¿Salir de esta lista de correo?

    La lista pide un mensaje a { $target }. Inbox Classic lo escribe por usted; envíelo para cancelar la suscripción.
gtk-unsubscribe-web =
    ¿Salir de esta lista de correo?

    La página de la lista para ello se abre en su navegador ({ $target }).
gtk-unsubscribe-failed = No se pudo cancelar la suscripción: { $problem }
gtk-toolbar-create-mail-menu = Un mensaje desde una cuenta
gtk-toolbar-send-recv-menu = Enviar y recibir una cuenta
gtk-main-menu = Menú principal
gtk-quit = Salir

## The Move and Copy window

gtk-new-folder-at-top-of = La nueva carpeta se crea en el nivel superior de { $account }.

## The message list

## Help

## Notifications and the tray

gtk-unread-messages = { $count ->
    [0] No hay mensajes sin leer
    [one] { $count } mensaje sin leer
   *[other] { $count } mensajes sin leer
}

## The compose window's link menu

## The Outbox

gtk-outbox-empty = Nada espera para enviarse.
gtk-outbox-row = Para: { $to }  ·  En cola { $queued }  ·  { $status }

## The app

gtk-new-messages = { $count } mensajes nuevos
gtk-still-running-detail = Sigue buscando correo nuevo. Su icono en la barra superior lo vuelve a abrir o lo cierra.
gtk-sign-in-again-ask =
    El inicio de sesión de { $account } se rechazó o caducó.

    ¿Iniciar sesión de nuevo en el navegador?
gtk-default-app-not-installed = Esta copia de Inbox Classic no se instaló, por eso el sistema no la muestra como aplicación de correo. Instálela para elegirla.
gtk-default-app-now = Inbox Classic es ahora su aplicación de correo predeterminada: los vínculos de correo abren aquí un mensaje nuevo.
gtk-default-app-failed = No se pudo hacer de Inbox Classic la aplicación de correo predeterminada.

## Buttons and words used in many windows

## The reading pane

gtk-reader-date = Fecha:
gtk-reader-files = Los archivos del mensaje
gtk-pictures-blocked = Se han bloqueado algunas imágenes para impedir que el remitente identifique su equipo.
gtk-download-pictures = Descargar imágenes
gtk-save-attachments-menu = Guardar archivos adjuntos...
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
gtk-day-and-time = { $day }, { $time }

## The compose window

gtk-format-bold = Negrita (Ctrl+B)
gtk-format-italic = Cursiva (Ctrl+I)
gtk-format-underline = Subrayado (Ctrl+U)
gtk-format-hyperlink = Hipervínculo (Ctrl+K)
gtk-font = Fuente
gtk-show-cc = _CC
gtk-show-bcc = CC_O
gtk-save-tip = Guardar (Ctrl+S)
gtk-link-status = { $link }    (Ctrl+clic para abrir)

## Accounts

gtk-plain-warning =
    Sin cifrado, su contraseña y su correo viajan por la red legibles para cualquiera en el camino. Úselo solo para un servidor en su propio equipo o red.

    ¿Continuar?
gtk-display-name-title = Nombre para mostrar
gtk-turned-off-why = { $button } está desactivado en este equipo. { $reason }
gtk-turned-off-why-long =
    { $button } está desactivado en este equipo.

    { $reason }
gtk-next = Siguiente >
gtk-provider-sign-in = { $address } inicia sesión en la página de { $provider }, sin dar su contraseña a Inbox Classic. O use una contraseña de aplicación creada en la configuración de seguridad de su cuenta.
gtk-provider-sign-in-apps = { $address } puede iniciar sesión en la página de { $provider } con una de sus aplicaciones de inicio de sesión (Más opciones de inicio de sesión). O use una contraseña de aplicación creada en la configuración de seguridad de su cuenta.
gtk-accounts-add = Agregar...
gtk-accounts-properties = Propiedades...
gtk-accounts-signature = Firma...
gtk-accounts-sign-in-apps = Aplicaciones de inicio de sesión...

## Sign-in apps

gtk-app-server = Servidor { $kind }
gtk-app-port = Puerto { $kind }
gtk-app-security = Seguridad { $kind }
gtk-issuer-found =
    Página de inicio de sesión: { $page }
    Punto de conexión de tokens: { $endpoint }
gtk-client-id = ID de cliente
gtk-client-secret = Secreto de cliente
gtk-scopes = Ámbitos (scopes)
gtk-redirect-uri = URI de redirección
gtk-issuer-usable =
    El emisor se puede usar.

    { $found }
gtk-app-built-in = { $app } está integrada: solo puede cambiar si se usa para cuentas nuevas. { $reason }
gtk-built-in = { $app } (integrada)
gtk-offered-for-new = Ofrecida para cuentas nuevas
gtk-edit-button = Editar...
gtk-remove-app-ask = ¿Quitar la aplicación de inicio de sesión { $app } y su secreto de cliente guardado?
gtk-sign-in-apps-intro = Las aplicaciones de inicio de sesión permiten que las cuentas inicien sesión mediante el navegador. Una desactivada no se ofrece para cuentas nuevas; las cuentas que ya la usan siguen funcionando.

## AI agents

gtk-agent-it-may = Puede
gtk-agent-accounts = Cuentas que puede usar
gtk-never-used = Nunca usado
gtk-last-used = Usado por última vez { $date }
gtk-forget-program = ¿Olvidar este programa?
gtk-forget-program-detail = Se le vuelve a preguntar la próxima vez que se conecte, y se olvida lo que hicieron sus agentes.
gtk-no-agents-yet = Ningún agente ha pedido aún usar su correo.
gtk-nothing-yet = Nada todavía.

## Preferences

gtk-preferences = Preferencias
gtk-language = Idioma
gtk-language-subtitle = Las palabras de las ventanas y de la ayuda
gtk-new-mail-group = Correo nuevo
gtk-notify-subtitle = Una notificación cuando llegan mensajes nuevos mientras la ventana está en segundo plano
gtk-restart-to-change = Inbox Classic se reinicia para cambiar el idioma.
