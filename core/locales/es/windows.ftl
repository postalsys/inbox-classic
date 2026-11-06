# Las palabras de las ventanas de la aplicación de Windows (app/src), identificadores que empiezan por win-. La
# aplicación rellena lo que va entre { $llaves }; un & marca la letra de un elemento de menú o de un botón (&& es un &).

## La ventana principal

win-flag-menu = &Marca
win-still-running-detail = Sigue buscando correo nuevo aquí. Haga clic en el icono para abrirlo, o haga clic con el botón derecho para salir.
win-new-messages = { $count ->
    [one] { $count } mensaje nuevo
   *[other] { $count } mensajes nuevos
}
win-default-app-not-installed = Esta copia de Inbox Classic no se instaló, por eso Windows no la muestra como programa de correo. Instálela para elegirla.
win-default-app-settings = Windows abre su configuración de aplicaciones predeterminadas para Inbox Classic. Elíjalo allí para MAILTO.
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
win-col-to = Para
win-save-as-button = Guardar &como...
win-too-many-files = Demasiados archivos a la vez: elija menos.

## La Bandeja de salida

win-outbox-send-all = &Enviar todo ahora

## La ventana de redacción

win-editor-failed = No se pueden escribir mensajes.
win-ctrl-click-to-open = ({ $ctrl }+clic para abrir)
win-remove-file = &Quitar
win-format-bold = Negrita ({ $ctrl }+B)
win-format-italic = Cursiva ({ $ctrl }+I)
win-format-underline = Subrayado ({ $ctrl }+U)
win-format-link = Hipervínculo ({ $ctrl }+K)
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
    [one] El texto de { $count } mensaje aún se está indexando, así que pronto puede encontrarse más.
   *[other] El texto de { $count } mensajes aún se está indexando, así que pronto puede encontrarse más.
}
win-files = { $count ->
    [one] { $count } archivo
   *[other] { $count } archivos
}
win-click-to-retry = Haga clic aquí para volver a intentarlo.
win-save-attachments = &Guardar archivos adjuntos...
win-files-not-saved = No se pudieron guardar { $failed } de los { $count } archivos.
win-attendees = { $count ->
    [one] { $count } asistente
   *[other] { $count } asistentes
}
win-copy-button = &Copiar
win-move-button = &Mover
win-new-folder-in-highlighted = La carpeta nueva va dentro de la carpeta resaltada.
win-delete-folder-ask = ¿Eliminar la carpeta «{ $folder }» con sus mensajes y las carpetas que contiene? También se elimina en el servidor.
win-clear-flag = &Quitar marca
win-rename = Cambiar &nombre...
win-open = &Abrir
win-view-source = Ver &código fuente
win-properties = &Propiedades
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

win-allow = &Permitir
win-dont-allow = &No permitir
win-turn-away = &Rechazar
win-col-address = Dirección
win-never-written-to = Nunca escrito
win-send = &Enviar
win-edit-first = &Modificar antes
win-dont-send = &No enviar
win-forget-program-ask = ¿Olvidar este programa y lo que hicieron sus agentes? Se volverá a preguntar la próxima vez que se conecte.
win-clear-log-ask = ¿Borrar la lista de lo que hicieron los agentes? Lo que hicieron queda hecho.
win-let-agents-connect = &Permitir que los agentes de IA se conecten a Inbox Classic
win-agent-programs = P&rogramas cuyos agentes pidieron usar su correo:
win-change = &Cambiar...
win-what-agents-did = &Lo que hicieron los agentes:
win-clear = &Borrar
win-how-to-connect = Cómo conectar un agente

## Aplicaciones de inicio de sesión

win-check-button = Co&mprobar
win-copy = &Copiar
win-built-in = (integrada)
win-edit = &Modificar...

## Opciones

win-options-language-label = &Mostrar Inbox Classic en:
win-options-restart-note = Inbox Classic se reinicia para mostrar otro idioma.
win-options-notify = &Avisarme cuando llegue correo nuevo
win-restart-ask = Inbox Classic se mostrará en el idioma elegido ({ $language }) después de reiniciarse. ¿Reiniciar ahora?
win-restart-now = &Reiniciar ahora
win-restart-later = Más &tarde
