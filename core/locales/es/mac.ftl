# Español. Borrador, pendiente de revisión por un hablante nativo.

## The app and its menus

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
mac-paste = Pegar
mac-menu-window = Ventana
mac-minimize = Minimizar
mac-zoom = Zoom
mac-no-updates = Esta copia de Inbox Classic no se actualiza sola. Descargue la última versión en inboxclassic.com.

## Settings

mac-settings-title = Ajustes
mac-language-label = Idioma:
mac-restart-hint = Inbox Classic se reinicia para cambiar de idioma.
mac-notify-new-mail = Avisarme cuando llegue correo nuevo
mac-restart-question = ¿Reiniciar Inbox Classic ahora para cambiar de idioma?

## Dialogs

mac-choose = Elegir

## The main window

mac-still-running-detail = Sigue comprobando si hay correo nuevo. Haga clic en su icono del Dock para volver a abrirlo.
mac-outbox-waiting =
    { $count ->
        [one] { $count } mensaje en la Bandeja de salida
       *[other] { $count } mensajes en la Bandeja de salida
    }
mac-sending = Enviando { $subject }…
mac-checking = Comprobando si hay mensajes nuevos en { $account }…
mac-account-said = { $account }: { $message }
mac-new-messages =
    { $count ->
        [one] { $count } mensaje nuevo
       *[other] { $count } mensajes nuevos
    }
mac-newest-from = El más reciente, de { $from }: { $subject }
mac-not-bundle = Esta copia de Inbox Classic no es un paquete de aplicación, así que no puede ser la app de correo predeterminada.
mac-not-made-default = Inbox Classic no se convirtió en la app de correo predeterminada: { $reason }
mac-tool-search = Buscar

## The folders and the message list

mac-still-indexing-more =
    { $count ->
        [one] El texto de { $count } mensaje aún se está indexando, así que pronto puede encontrarse más.
       *[other] El texto de { $count } mensajes aún se está indexando, así que pronto puede encontrarse más.
    }
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
mac-import-messages = Importar mensajes
mac-save-messages = Guardar mensajes
mac-save-attachments-menu = Guardar archivos adjuntos…
mac-files-not-saved =
    { $count ->
       *[other] No se pudieron guardar { $failed } de los { $count } archivos.
    }
mac-no-calendar-app = Ninguna app de calendario de este Mac abre invitaciones (archivos .ics).
mac-unsubscribing = Cancelando la suscripción a { $target }…

## The compose window

mac-bold = Negrita
mac-italic = Cursiva
mac-underline = Subrayado
mac-bcc = CCO
mac-command-click-to-open = ⌘-clic para abrir
mac-saving-to-drafts = Guardando en Borradores…
mac-dont-save = No guardar

## The reading pane

mac-files =
    { $count ->
        [one] { $count } archivo
       *[other] { $count } archivos
    }
mac-attendees =
    { $count ->
        [one] { $count } asistente
       *[other] { $count } asistentes
    }

## Accounts

mac-next = Siguiente
mac-name-placeholder = Ana García
mac-more-sign-in-options = Más opciones de inicio de sesión…
mac-add-sign-in-app = Agregar una aplicación de inicio de sesión…
mac-looking-up = Buscando los ajustes de { $domain }…
mac-add-button = Agregar…
mac-properties-button = Propiedades…
mac-signature-button = Firma…
mac-sign-in-apps-button = Aplicaciones de inicio de sesión…

## AI agents

mac-forget-program = ¿Olvidar este programa y lo que hicieron sus agentes?
mac-forget-program-detail = Se le volverá a preguntar la próxima vez que se conecte.

## Sign-in apps

mac-checking-issuer = Comprobando { $issuer }…
mac-edit-button = Editar…
mac-use-for-new-accounts = Usar { $name } para cuentas nuevas
mac-built-in = { $name } (integrada)

## Other windows

mac-new-folder-button = Nueva carpeta…
mac-edit-link = Editar enlace…
