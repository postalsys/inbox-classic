# The words of the Linux app's own windows (linux/src), ids starting with gtk-. Placeables in { $braces } are filled in
# by the app; an _ marks a button's mnemonic letter. GNOME words where GNOME has them (Preferences, Quit).

## The main window

# review: new
gtk-search-looks-in = A pesquisa em { $place } abrange assuntos, remetentes, destinatários, nomes de anexos e texto das mensagens. Verifique a ortografia ou experimente menos palavras.
# review: new
gtk-search-still-indexing = { $count ->
    [one] O texto de { $count } mensagem ainda está a ser indexado. Poderão aparecer mais resultados em breve.
   *[other] O texto de { $count } mensagens ainda está a ser indexado. Poderão aparecer mais resultados em breve.
}
# review: new
gtk-search-results-everywhere = { $count ->
    [0] Nenhum resultado
    [one] { $count } resultado
   *[other] { $count } resultados
} para «{ $words }» em todas as pastas
# review: new
gtk-search-results-in = { $count ->
    [0] Nenhum resultado
    [one] { $count } resultado
   *[other] { $count } resultados
} para «{ $words }» em { $place }
# review: new
gtk-search-indexing = { $count ->
    [one] ainda a indexar o texto de { $count } mensagem
   *[other] ainda a indexar o texto de { $count } mensagens
}
# review: new
gtk-list-loading = A carregar...
# review: new
gtk-menu-rename = Mudar o nome...
# review: new
gtk-import-one-question = Importar a mensagem { $file } para { $folder }?
# review: new
gtk-files-not-saved = Não foi possível guardar { $failed } dos { $total } ficheiros.
# review: new
gtk-unsubscribe-one-click =
    Sair desta lista de correio?

    O Inbox Classic vai enviar um pedido de cancelamento da subscrição para { $target }. Não será aberta nenhuma página web nem enviado nenhum e-mail.
# review: new
gtk-unsubscribe-mail =
    Sair desta lista de correio?

    Para cancelar a subscrição, envie um e-mail para { $target }. O Inbox Classic prepara-o por si. Envie a mensagem para confirmar.
# review: new
gtk-unsubscribe-web =
    Sair desta lista de correio?

    A página de cancelamento da subscrição da lista de correio vai abrir no seu browser ({ $target }).
# review: new
gtk-unsubscribe-failed = Não foi possível cancelar a subscrição: { $problem }
# review: new
gtk-toolbar-create-mail-menu = Escrever a partir de uma conta específica
# review: new
gtk-toolbar-send-recv-menu = Enviar e receber correio de uma conta específica
# review: new
gtk-main-menu = Menu principal
# review: new
gtk-folder-list = Lista de pastas
# review: new
gtk-quit = Sair

## The Move and Copy window

# review: new
gtk-new-folder-at-top-of = A nova pasta fica no nível superior de { $account }.

## The message list

## Help

## Notifications and the tray

# review: new
gtk-unread-messages = { $count ->
    [0] Não há mensagens não lidas
    [one] { $count } mensagem não lida
   *[other] { $count } mensagens não lidas
}

## The compose window's link menu

## The Outbox

# review: new
gtk-outbox-empty = Não há mensagens à espera de ser enviadas.
# review: new
gtk-outbox-row = Para: { $to }  ·  Em fila { $queued }  ·  { $status }

## The app

# review: new
gtk-still-running-detail = O Inbox Classic continua a verificar se há correio novo em segundo plano. Use o respetivo ícone na barra superior para abrir ou sair da aplicação.
# review: new
gtk-sign-in-again-ask =
    O início de sessão em { $account } foi rejeitado ou a sessão expirou.

    Iniciar sessão novamente no browser?
# review: new
gtk-default-app-not-installed = Esta cópia do Inbox Classic não foi instalada, por isso o sistema não a apresenta como aplicação de correio. Instale-a para a poder escolher.
# review: new
gtk-default-app-now = O Inbox Classic é agora a sua aplicação de correio predefinida: as ligações de e-mail abrem aqui uma nova mensagem.
# review: new
gtk-default-app-failed = Não foi possível tornar o Inbox Classic a aplicação de correio predefinida.

## Buttons and words used in many windows

## The reading pane

# review: new
gtk-reader-date = Data:
# review: new
gtk-reader-files = Anexos da mensagem
# review: new
gtk-files = { $count ->
    [one] { $count } ficheiro
   *[other] { $count } ficheiros
}
# review: new
gtk-pictures-blocked = Algumas imagens foram bloqueadas para ajudar a impedir que o remetente identifique o seu computador.
# review: new
gtk-download-pictures = Transferir imagens
# review: new
gtk-save-attachments-menu = Guardar anexos...

## The compose window

# review: new
gtk-format-bold = Negrito (Ctrl+B)
# review: new
gtk-format-italic = Itálico (Ctrl+I)
# review: new
gtk-format-underline = Sublinhado (Ctrl+U)
# review: new
gtk-format-hyperlink = Hiperligação (Ctrl+K)
# review: new
gtk-font = Tipo de letra
# review: new
gtk-show-cc = _Cc
# review: new
gtk-show-bcc = _Bcc
# review: new
gtk-save-tip = Guardar (Ctrl+S)
# review: new
gtk-link-status = { $link }    (Ctrl+clique para abrir)

## Accounts

# review: new
gtk-plain-warning =
    Sem encriptação, qualquer pessoa que intercete o seu tráfego de rede pode ler a sua palavra-passe e as suas mensagens. Use esta ligação apenas com um servidor no seu próprio computador ou na sua rede local.

    Continuar?
# review: new
gtk-account-name-title = Nome da conta
# review: new
gtk-display-name-title = Nome a apresentar
# review: new
gtk-turned-off-why = A opção «{ $button }» está desativada neste computador. { $reason }
# review: new
gtk-turned-off-why-long =
    A opção «{ $button }» está desativada neste computador.

    { $reason }
# review: new
gtk-next = Seguinte >
# review: new
gtk-provider-sign-in = Inicie sessão em { $address } no site do fornecedor ({ $provider }). A sua palavra-passe não é partilhada com o Inbox Classic. Também pode usar uma palavra-passe de aplicação criada nas definições de segurança da sua conta.
# review: new
gtk-provider-sign-in-apps = Inicie sessão em { $address } no site do fornecedor ({ $provider }) com uma das suas aplicações de início de sessão (Mais opções de início de sessão). Também pode usar uma palavra-passe de aplicação criada nas definições de segurança da sua conta.
# review: new
gtk-accounts-add = Adicionar...
# review: new
gtk-accounts-properties = Propriedades...
# review: new
gtk-accounts-signature = Assinatura...
# review: new
gtk-accounts-sign-in-apps = Aplicações de início de sessão...

## Sign-in apps

# review: new
gtk-app-server = Servidor { $kind }
# review: new
gtk-app-port = Porta { $kind }
# review: new
gtk-app-security = Segurança { $kind }
# review: new
gtk-issuer-found =
    Página de início de sessão: { $page }
    Endpoint do token: { $endpoint }
# review: new
gtk-client-id = ID de cliente
# review: new
gtk-client-secret = Segredo de cliente
# review: new
gtk-scopes = Permissões (scopes)
# review: new
gtk-redirect-uri = URI de redirecionamento
# review: new
gtk-issuer-usable =
    O emissor pode ser usado.

    { $found }
# review: new
gtk-app-built-in = { $app } está integrada. Só pode alterar se é oferecida para contas novas. { $reason }
# review: new
gtk-built-in = { $app } (integrada)
# review: new
gtk-offered-for-new = Oferecida para contas novas
# review: new
gtk-edit-button = Editar...
# review: new
gtk-remove-app-ask = Remover a aplicação de início de sessão { $app } e o respetivo segredo de cliente guardado?
# review: new
gtk-sign-in-apps-intro = As aplicações de início de sessão permitem que as contas iniciem sessão através do browser. Uma que esteja desativada não é oferecida para contas novas; as contas que já a usam continuam a funcionar.

## AI agents

# review: new
gtk-agent-it-may = Ações permitidas
# review: new
gtk-agent-accounts = Contas permitidas
# review: new
gtk-never-used = Nunca usado
# review: new
gtk-last-used = Última utilização: { $date }
# review: new
gtk-forget-program = Remover este programa?
# review: new
gtk-forget-program-detail = As permissões do programa e o histórico de atividade dos seus agentes serão eliminados. Será pedida novamente autorização da próxima vez que se ligar.
# review: new
gtk-no-agents-yet = Ainda nenhum agente pediu para usar o seu correio.
# review: new
gtk-nothing-yet = Ainda nada.

## Preferences

# review: new
gtk-preferences = Preferências
# review: new
gtk-language = Idioma
# review: new
gtk-language-subtitle = Idioma da aplicação e da ajuda
# review: new
gtk-new-mail-group = Correio novo
# the row of Preferences that turns the new mail notification on, in sentence case as GNOME writes it
# review: new
gtk-notify-new-mail = Notificar correio novo
# review: new
gtk-notify-subtitle = Uma notificação quando chegam mensagens novas com a janela em segundo plano
# review: new
gtk-restart-to-change = O Inbox Classic reinicia para mudar o idioma.

## The desktop entry and the page of the software stores

# linux/data/com.inboxclassic.InboxClassic.desktop and .metainfo.xml, made by the build. The keywords are the words a
# search of the applications finds Inbox Classic by, each ended by a semicolon, in your language only: the English
# ones are added before them
# review: new
gtk-desktop-generic-name = Cliente de correio
# review: new
gtk-desktop-comment = Ler e escrever e-mail: um programa de correio rápido e simples
# review: new
gtk-desktop-keywords = correio;correio eletrónico;mensagens;caixa de entrada;
# review: new
gtk-metainfo-summary = Um programa de correio rápido e simples
# review: new
gtk-metainfo-description = O Inbox Classic lê e escreve e-mail com as pastas à esquerda, as mensagens em cima e a mensagem por baixo, como os programas de correio de antigamente. Funciona com qualquer conta IMAP e SMTP e inicia sessão no Outlook.com e no Microsoft 365 através do browser.
# review: new
gtk-metainfo-feature-sanitized = Cada mensagem é mostrada limpa, sem scripts, e as imagens da Internet só quando as permitir
# review: new
gtk-metainfo-feature-search = Uma pesquisa que encontra palavras no assunto, nas pessoas, nos nomes dos ficheiros e no texto, com os operadores do Gmail
# review: new
gtk-metainfo-feature-replies = As respostas recolhem as mensagens anteriores que citam
# review: new
gtk-metainfo-feature-offline = O correio continua legível sem ligação; as palavras-passe ficam guardadas no seu porta-chaves
