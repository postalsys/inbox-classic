# Las palabras de las ventanas de la aplicación de Windows (app/src), identificadores que empiezan por win-. La
# aplicación rellena lo que va entre { $llaves }; un & marca la letra de un elemento de menú o de un botón (&& es un &).

## La ventana principal

win-still-running-detail = Inbox Classic sigue buscando correo nuevo en segundo plano. Haga clic en su icono para abrirlo. Para salir, abra el menú del icono con el botón derecho.
win-default-app-not-installed = Inbox Classic no está instalado, por lo que Windows no lo muestra entre las aplicaciones de correo. Instálelo para elegirlo como aplicación predeterminada.
win-default-app-settings = Windows abrirá la configuración de aplicaciones predeterminadas. Seleccione Inbox Classic para abrir los enlaces MAILTO.
win-no-unread = No hay mensajes sin leer
win-unread-messages = { $count ->
    [one] { $count } mensaje sin leer
   *[other] { $count } mensajes sin leer
}
win-print-failed = No se pudo imprimir el mensaje.
win-print-title-of = Imprimir: { $subject }
win-no-bodies = No se puede mostrar el contenido de los mensajes.
win-webview-failed = No se pudo crear el WebView2.
win-webview-missing = El entorno de ejecución de WebView2 no está disponible.

## Botones y palabras de varias ventanas

win-delete-button = &Eliminar
win-find-label = &Buscar:
win-save-as-button = Guardar &como...
win-too-many-files = Demasiados archivos a la vez: elija menos.

## La Bandeja de salida


## La ventana de redacción

win-editor-failed = No se pueden escribir mensajes.
win-ctrl-click-to-open = ({ $ctrl }+clic para abrir)
win-format-bold = Negrita ({ $ctrl }+B)
win-format-italic = Cursiva ({ $ctrl }+I)
win-format-underline = Subrayado ({ $ctrl }+U)
win-format-link = Enlace ({ $ctrl }+K)
win-show-cc = &CC
win-show-bcc = CC&O
win-signature-title = Firma: { $account }

## Las carpetas, la lista de mensajes y el panel de lectura

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
win-no-match-indexing = { $count ->
    [one] Se está indexando el texto de { $count } mensaje. Pueden aparecer más resultados.
   *[other] Se está indexando el texto de { $count } mensajes. Pueden aparecer más resultados.
}
win-files = { $count ->
    [one] { $count } archivo
   *[other] { $count } archivos
}
win-click-to-retry = Haga clic aquí para volver a intentarlo.
win-save-attachments = &Guardar archivos adjuntos...
win-files-not-saved = Archivos sin guardar: { $failed } de { $count }.
win-new-folder-in-highlighted = La nueva carpeta se creará dentro de la carpeta seleccionada.
win-delete-folder-ask = ¿Eliminar la carpeta «{ $folder }», todos sus mensajes y sus subcarpetas? También se eliminarán del servidor.
win-rename = Re&nombrar...
win-messages-not-saved = No se pudieron guardar los mensajes.
win-messages-not-forwarded = No se pudieron reenviar los mensajes.

## Cuentas

win-sign-in-google = Iniciar sesión con Google
win-sign-in-microsoft = Iniciar sesión con Microsoft
win-next = &Siguiente >
win-your-account = su cuenta
win-browser-sign-in = (inicio de sesión en el navegador)
win-add = &Agregar...
win-properties-button = &Propiedades...
win-signature-button = &Firma...
win-sign-in-apps-button = Aplicaciones de &inicio de sesión...

## Agentes de IA

win-dont-allow = &No permitir
win-col-address = Dirección
win-never-written-to = Nunca le ha escrito
win-send = &Enviar
win-dont-send = &No enviar
win-forget-program-ask = ¿Quitar este programa, sus permisos y el historial de sus agentes? Se le volverá a pedir autorización la próxima vez que el programa se conecte.
win-clear-log-ask = ¿Borrar el historial de los agentes? Esto no deshará los cambios realizados.
win-agent-programs = P&rogramas cuyos agentes pidieron usar su correo:
win-change = &Cambiar...
win-what-agents-did = &Historial de los agentes:
win-how-to-connect = Cómo conectar un agente

## Aplicaciones de inicio de sesión

win-built-in = (integrada)
win-edit = &Editar...

## Opciones

win-options-language-label = &Mostrar Inbox Classic en:
win-options-restart-note = Reinicie Inbox Classic para aplicar el nuevo idioma.
win-options-notify = &Avisarme cuando llegue correo nuevo
win-restart-ask = Inbox Classic se mostrará en el idioma elegido ({ $language }) después de reiniciarse. ¿Reiniciar ahora?
