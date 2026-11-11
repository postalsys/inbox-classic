# The words of the Linux app's own windows (linux/src), ids starting with gtk-. Placeables in { $braces } are filled in
# by the app; an _ marks a button's mnemonic letter. GNOME words where GNOME has them (Preferences, Quit).

## The main window

gtk-search-looks-in = La búsqueda en { $place } incluye el asunto, los remitentes, los destinatarios, los nombres de los archivos adjuntos y el texto de los mensajes. Revise la ortografía o pruebe con menos palabras.
gtk-search-still-indexing = { $count ->
    [one] Se está indexando el texto de { $count } mensaje. Pueden aparecer más resultados.
   *[other] Se está indexando el texto de { $count } mensajes. Pueden aparecer más resultados.
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
gtk-menu-rename = Renombrar...
gtk-import-one-question = ¿Importar el mensaje { $file } a la carpeta { $folder }?
gtk-files-not-saved = Archivos sin guardar: { $failed } de { $total }.
gtk-unsubscribe-one-click =
    ¿Salir de esta lista de correo?

    Inbox Classic enviará una solicitud de baja a { $target }. No se abrirá ninguna página web ni se enviará ningún correo electrónico.
gtk-unsubscribe-mail =
    ¿Salir de esta lista de correo?

    Para cancelar la suscripción, debe enviar un mensaje a { $target }. Inbox Classic lo prepara por usted. Envíelo para confirmar la baja.
gtk-unsubscribe-web =
    ¿Salir de esta lista de correo?

    Se abrirá la página de baja de la lista en su navegador ({ $target }).
gtk-unsubscribe-failed = No se pudo cancelar la suscripción: { $problem }
gtk-toolbar-create-mail-menu = Redactar desde una cuenta específica
gtk-toolbar-send-recv-menu = Enviar y recibir mensajes de una cuenta específica
gtk-main-menu = Menú principal
# review: new
gtk-folder-list = Lista de carpetas
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

gtk-outbox-empty = No hay mensajes pendientes de envío.
gtk-outbox-row = Para: { $to }  ·  En cola desde { $queued }  ·  { $status }

## The app

gtk-still-running-detail = Inbox Classic sigue buscando correo nuevo en segundo plano. Utilice su icono en la barra superior para abrir la aplicación o salir de ella.
gtk-sign-in-again-ask =
    Se rechazó el inicio de sesión en { $account } o la sesión ha caducado.

    ¿Iniciar sesión de nuevo en el navegador?
gtk-default-app-not-installed = Inbox Classic no está instalado, por lo que no aparece entre las aplicaciones de correo del sistema. Instálelo para elegirlo como aplicación predeterminada.
gtk-default-app-now = Inbox Classic es ahora su aplicación de correo predeterminada: los enlaces de correo abren aquí un mensaje nuevo.
gtk-default-app-failed = No se pudo establecer Inbox Classic como aplicación de correo predeterminada.

## Buttons and words used in many windows

## The reading pane

gtk-reader-date = Fecha:
gtk-reader-files = Archivos adjuntos del mensaje
gtk-pictures-blocked = Se han bloqueado algunas imágenes para impedir que el remitente identifique su equipo.
gtk-download-pictures = Descargar imágenes
gtk-save-attachments-menu = Guardar archivos adjuntos...

## The compose window

gtk-format-bold = Negrita (Ctrl+B)
gtk-format-italic = Cursiva (Ctrl+I)
gtk-format-underline = Subrayado (Ctrl+U)
gtk-format-hyperlink = Enlace (Ctrl+K)
gtk-font = Tipo de letra
gtk-show-cc = _CC
gtk-show-bcc = CC_O
gtk-save-tip = Guardar (Ctrl+S)
gtk-link-status = { $link }    (Ctrl+clic para abrir)

## Accounts

gtk-plain-warning =
    Sin cifrado, cualquier persona que intercepte el tráfico de red podrá leer su contraseña y sus mensajes. Utilice esta conexión solo con un servidor en su propio equipo o en su red local.

    ¿Continuar?
# review: new
gtk-account-name-title = Nombre de la cuenta
gtk-display-name-title = Nombre para mostrar
gtk-turned-off-why = La opción «{ $button }» está desactivada en este equipo. { $reason }
gtk-turned-off-why-long =
    La opción «{ $button }» está desactivada en este equipo.

    { $reason }
gtk-next = Siguiente >
gtk-provider-sign-in = Inicie sesión en la cuenta { $address } desde el sitio web de { $provider }. Su contraseña no se compartirá con Inbox Classic. También puede usar una contraseña de aplicación creada en la configuración de seguridad de su cuenta.
gtk-provider-sign-in-apps = Inicie sesión en la cuenta { $address } desde el sitio web de { $provider } con una de sus aplicaciones de inicio de sesión («Más opciones de inicio de sesión»). También puede usar una contraseña de aplicación creada en la configuración de seguridad de su cuenta.
gtk-accounts-add = Agregar...
gtk-accounts-properties = Propiedades...
gtk-accounts-signature = Firma...
# review: changed
gtk-accounts-sign-in-apps = Apps de inicio de sesión...

## Sign-in apps

gtk-app-server = Servidor { $kind }
gtk-app-port = Puerto { $kind }
gtk-app-security = Seguridad { $kind }
gtk-issuer-found =
    Página de inicio de sesión: { $page }
    Punto de conexión de tokens: { $endpoint }
gtk-client-id = ID de cliente
gtk-client-secret = Secreto de cliente
gtk-scopes = Permisos (scopes)
gtk-redirect-uri = URI de redirección
gtk-issuer-usable =
    El emisor se puede usar.

    { $found }
gtk-app-built-in = { $app } es una aplicación integrada. Solo puede elegir si se ofrece para cuentas nuevas. { $reason }
gtk-built-in = { $app } (integrada)
gtk-offered-for-new = Ofrecida para cuentas nuevas
gtk-edit-button = Editar...
gtk-remove-app-ask = ¿Quitar la aplicación de inicio de sesión { $app } y su secreto de cliente guardado?
gtk-sign-in-apps-intro = Las aplicaciones de inicio de sesión permiten que las cuentas inicien sesión mediante el navegador. Una desactivada no se ofrece para cuentas nuevas; las cuentas que ya la usan siguen funcionando.

## AI agents

gtk-agent-it-may = Acciones permitidas
gtk-agent-accounts = Cuentas autorizadas
gtk-never-used = Nunca usado
gtk-last-used = Último uso: { $date }
gtk-forget-program = ¿Quitar este programa?
gtk-forget-program-detail = Se borrarán los permisos del programa y el historial de sus agentes. Se le volverá a pedir autorización la próxima vez que el programa se conecte.
gtk-no-agents-yet = Ningún agente ha pedido aún usar su correo.
gtk-nothing-yet = Nada todavía.

## Preferences

gtk-preferences = Preferencias
gtk-language = Idioma
gtk-language-subtitle = Idioma de la interfaz y de la ayuda
gtk-new-mail-group = Correo nuevo
# the row of Preferences that turns the new mail notification on, in sentence case as GNOME writes it
# review: new
gtk-notify-new-mail = Avisar de correo nuevo
gtk-notify-subtitle = Recibir una notificación cuando lleguen mensajes nuevos y la ventana esté en segundo plano
gtk-restart-to-change = Inbox Classic se reinicia para cambiar el idioma.
