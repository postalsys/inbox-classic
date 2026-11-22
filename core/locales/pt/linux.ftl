# The words of the Linux app's own windows (linux/src), ids starting with gtk-. Placeables in { $braces } are filled in
# by the app; an _ marks a button's mnemonic letter. GNOME words where GNOME has them (Preferences, Quit).

## The main window

gtk-search-looks-in = A pesquisa em { $place } abrange assuntos, remetentes, destinatários, nomes de anexos e texto das mensagens. Verifique a ortografia ou experimente menos palavras.
gtk-search-still-indexing = { $count ->
    [one] O texto de { $count } mensagem ainda está a ser indexado. Poderão aparecer mais resultados em breve.
   *[other] O texto de { $count } mensagens ainda está a ser indexado. Poderão aparecer mais resultados em breve.
}
gtk-search-results-everywhere = { $count ->
    [0] Nenhum resultado
    [one] { $count } resultado
   *[other] { $count } resultados
} para «{ $words }» em todas as pastas
gtk-search-results-in = { $count ->
    [0] Nenhum resultado
    [one] { $count } resultado
   *[other] { $count } resultados
} para «{ $words }» em { $place }
gtk-search-indexing = { $count ->
    [one] ainda a indexar o texto de { $count } mensagem
   *[other] ainda a indexar o texto de { $count } mensagens
}
gtk-list-loading = A carregar...
gtk-menu-rename = Mudar o nome...
gtk-import-one-question = Importar a mensagem { $file } para { $folder }?
gtk-files-not-saved = Ficheiros não guardados: { $failed } de { $total }.
gtk-unsubscribe-one-click =
    Sair desta lista de correio?

    O Inbox Classic vai enviar um pedido de cancelamento da subscrição para { $target }. Não será aberta nenhuma página web nem enviado nenhum e-mail.
gtk-unsubscribe-mail =
    Sair desta lista de correio?

    Para cancelar a subscrição, envie um e-mail para { $target }. O Inbox Classic prepara-o por si. Envie a mensagem para confirmar.
gtk-unsubscribe-web =
    Sair desta lista de correio?

    A página de cancelamento da subscrição da lista de correio vai abrir no seu browser ({ $target }).
gtk-unsubscribe-failed = Não foi possível cancelar a subscrição: { $problem }
gtk-toolbar-create-mail-menu = Escrever a partir de uma conta específica
gtk-toolbar-send-recv-menu = Enviar e receber correio de uma conta específica
gtk-main-menu = Menu principal
gtk-folder-list = Lista de pastas
gtk-quit = Sair

## The Move and Copy window

gtk-new-folder-at-top-of = A nova pasta será criada no nível principal da conta { $account }.

## The message list

## Help

## Notifications and the tray

gtk-unread-messages = { $count ->
    [0] Não há mensagens não lidas
    [one] { $count } mensagem não lida
   *[other] { $count } mensagens não lidas
}

## The compose window's link menu

## The Outbox

gtk-outbox-empty = Não há mensagens à espera de ser enviadas.
gtk-outbox-row = Para: { $to }  ·  Em espera desde: { $queued }  ·  { $status }

## The app

gtk-still-running-detail = O Inbox Classic continua a verificar se há correio novo em segundo plano. Use o respetivo ícone na barra superior para abrir ou sair da aplicação.
gtk-sign-in-again-ask =
    O início de sessão em { $account } foi rejeitado ou a sessão expirou.

    Iniciar sessão novamente no browser?
gtk-default-app-not-installed = Esta cópia do Inbox Classic não foi instalada, por isso o sistema não a apresenta como aplicação de correio. Instale-a para a poder escolher.
gtk-default-app-now = O Inbox Classic é agora a sua aplicação de correio predefinida: as ligações de e-mail abrem aqui uma nova mensagem.
gtk-default-app-failed = Não foi possível definir o Inbox Classic como aplicação de correio predefinida.

## Buttons and words used in many windows

## The reading pane

gtk-reader-date = Data:
gtk-reader-files = Anexos da mensagem
gtk-files = { $count ->
    [one] { $count } ficheiro
   *[other] { $count } ficheiros
}
gtk-save-attachments-menu = Guardar anexos...

## The compose window

gtk-format-bold = Negrito (Ctrl+B)
gtk-format-italic = Itálico (Ctrl+I)
gtk-format-underline = Sublinhado (Ctrl+U)
gtk-format-hyperlink = Hiperligação (Ctrl+K)
gtk-font = Tipo de letra
gtk-show-cc = _Cc
gtk-show-bcc = _Bcc
gtk-save-tip = Guardar (Ctrl+S)
gtk-link-status = { $link }    (Ctrl+clique para abrir)

## Accounts

gtk-plain-warning =
    Sem encriptação, quem intercetar o tráfego pode ler a sua palavra-passe e as mensagens. Uma rede local, por si só, não protege a ligação. Continue apenas se a ligação estiver protegida de outra forma.

    Continuar?
gtk-account-name-title = Nome da conta
gtk-display-name-title = Nome a apresentar
gtk-turned-off-why = A opção «{ $button }» está desativada neste computador. { $reason }
gtk-turned-off-why-long =
    A opção «{ $button }» está desativada neste computador.

    { $reason }
gtk-next = Seguinte >
gtk-provider-sign-in = { $provider }: inicie sessão em { $address } no site do fornecedor. A sua palavra-passe não é partilhada com o Inbox Classic. Se a sua conta permitir palavras-passe de aplicação para o correio, pode criar uma nas definições de segurança. Para o Outlook.com e o Microsoft 365, tem de iniciar sessão através do browser.
gtk-provider-sign-in-apps = { $provider }: inicie sessão em { $address } no site do fornecedor com uma das suas aplicações de início de sessão (Mais opções de início de sessão). Se a sua conta permitir palavras-passe de aplicação para o correio, pode criar uma nas definições de segurança. Para o Outlook.com e o Microsoft 365, tem de iniciar sessão através do browser.
gtk-accounts-add = Adicionar...
gtk-accounts-properties = Propriedades...
gtk-accounts-signature = Assinatura...
gtk-accounts-sign-in-apps = Aplicações de início de sessão...

## Sign-in apps

gtk-app-server = Servidor { $kind }
gtk-app-port = Porta { $kind }
gtk-app-security = Segurança { $kind }
gtk-issuer-found =
    Página de início de sessão: { $page }
    Endpoint do token: { $endpoint }
gtk-client-id = ID do cliente
gtk-client-secret = Segredo do cliente
gtk-scopes = Permissões (scopes)
gtk-redirect-uri = URI de redirecionamento
gtk-issuer-usable =
    O emissor pode ser usado.

    { $found }
gtk-app-built-in = A aplicação { $app } está integrada no Inbox Classic. Só pode escolher se é apresentada como opção para novas contas. { $reason }
gtk-built-in = { $app } (integrada)
gtk-offered-for-new = Disponível para novas contas
gtk-edit-button = Editar...
gtk-remove-app-ask = Remover a aplicação de início de sessão { $app } e o segredo do cliente guardado?
gtk-sign-in-apps-intro = As aplicações de início de sessão permitem aceder às contas através do browser. Uma aplicação desativada deixa de ser apresentada como opção para novas contas. As contas que já a utilizam continuam a funcionar.

## AI agents

gtk-agent-it-may = Ações permitidas
gtk-agent-accounts = Contas permitidas
gtk-never-used = Nunca usado
gtk-last-used = Última utilização: { $date }
gtk-forget-program = Remover as permissões guardadas deste programa?
gtk-forget-program-detail = As permissões do programa e o histórico de atividade dos seus agentes serão eliminados. Será pedida novamente autorização da próxima vez que se ligar.
gtk-no-agents-yet = Ainda nenhum agente pediu para usar o seu correio.
gtk-nothing-yet = Ainda nada.

## Preferences

gtk-preferences = Preferências
gtk-notify-subtitle = Apenas quando a janela principal não está em primeiro plano

## The desktop entry and the page of the software stores

# linux/data/com.inboxclassic.InboxClassic.desktop and .metainfo.xml, made by the build. The keywords are the words a
# search of the applications finds Inbox Classic by, each ended by a semicolon, in your language only: the English
# ones are added before them
gtk-desktop-generic-name = Cliente de correio
gtk-desktop-comment = Ler e escrever e-mail: um programa de correio rápido e simples
gtk-desktop-keywords = correio;correio eletrónico;mensagens;caixa de entrada;
gtk-metainfo-summary = Um programa de correio rápido e simples
gtk-metainfo-description = O Inbox Classic permite ler e escrever correio eletrónico numa interface familiar e configurável. Por predefinição, mostra as pastas à esquerda, as mensagens em cima e a mensagem selecionada por baixo. Funciona com contas IMAP e SMTP e permite iniciar sessão no Outlook.com e no Microsoft 365 através do browser.
gtk-metainfo-feature-sanitized = As mensagens são apresentadas sem scripts; as imagens da internet só são carregadas com a sua autorização
gtk-metainfo-feature-search = Pesquisa no assunto, nos remetentes, nos destinatários, nos nomes dos anexos e no texto das mensagens, com suporte para os operadores do Gmail
gtk-metainfo-feature-replies = O texto das mensagens anteriores citado nas respostas fica recolhido e pode ser expandido quando necessário
gtk-metainfo-feature-offline = O correio em cache pode ser lido sem ligação à internet; por predefinição, as credenciais são guardadas no porta-chaves, quando disponível
