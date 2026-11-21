# The words of the windows, the same on every platform. An & marks the letter of a menu item that Alt and the letter
# choose on Windows and Linux (&& is an ampersand); the Mac leaves it out. Put it on a letter of your word, a different
# one for each item of a menu where you can.
# Português do Brasil. Rascunho, aguardando revisão por um falante nativo.

## The menus

menu-file = &Arquivo
menu-edit = &Editar
menu-view = E&xibir
menu-tools = Ferramen&tas
menu-message = &Mensagem
menu-help = Aj&uda
menu-layout = &Layout
menu-sort-by = &Ordenar por
menu-text-size = &Tamanho do texto
menu-folder = &Pasta
menu-insert = &Inserir

## The commands of the menus, the toolbar and the tray (core/commands.toml)

cmd-new-account = &Nova conta...
cmd-exit = S&air
cmd-sync = Enviar e &receber tudo
cmd-mark-read = Marcar como &lida
cmd-mark-unread = Marcar como &não lida
cmd-pictures = Baixar &imagens
cmd-about = &Sobre o Inbox Classic
cmd-new-mail = &Nova mensagem
cmd-reply = &Responder ao remetente
cmd-reply-all = Responder a &todos
cmd-forward = &Encaminhar
cmd-help = &Conteúdo
cmd-delete = &Excluir mensagem
cmd-move = &Mover para pasta...
cmd-flag = &Sinalizar mensagem
cmd-new-folder = &Nova pasta...
cmd-rename-folder = &Renomear pasta...
cmd-delete-folder = &Excluir pasta
cmd-empty-folder = Esva&ziar pasta
ui-empty-button = Esvaziar
cmd-accounts = &Contas...
cmd-find = L&ocalizar mensagem
cmd-save-as = &Salvar como...
cmd-print = &Imprimir...
cmd-import = I&mportar mensagens...
cmd-outbox = Caixa de &Saída...
cmd-properties = P&ropriedades
cmd-mark-all-read = Marcar &todas como lidas
cmd-junk = M&arcar como lixo eletrônico
cmd-not-junk = Marcar como e-mail legítim&o
cmd-archive = Ar&quivar
cmd-watch-conversation = Acompan&har conversa
cmd-ignore-conversation = Ignorar con&versa
cmd-next-message = Próxi&ma mensagem
cmd-previous-message = Mensagem &anterior
cmd-next-unread = Próxima mensagem &não lida
cmd-go-to-folder = I&r para pasta...
cmd-find-in-message = Localizar ne&sta mensagem...
ui-go-to-prompt = Ir para a pasta:
ui-find-in-message-hint = Localizar nesta mensagem
ui-find-not-found = “{ $words }” não está nesta mensagem
cmd-expand-all-threads = E&xpandir todas as conversas
cmd-collapse-all-threads = Re&colher todas as conversas
ui-group-by-conversation = A&grupar mensagens por conversa
cmd-folder-list = Lista de &pastas
cmd-layout-automatic = &Automático
cmd-layout-classic = &Clássico
cmd-layout-columns = C&olunas
cmd-sort-date = &Data
cmd-sort-from = &Remetente
cmd-sort-subject = &Assunto
cmd-sort-size = &Tamanho
cmd-sort-ascending = Ordem &crescente
cmd-sort-descending = Ordem d&ecrescente
cmd-text-size-largest = &Muito grande
cmd-text-size-larger = &Grande
cmd-text-size-medium = Mé&dio
cmd-text-size-smaller = &Pequeno
cmd-text-size-smallest = Muito peq&ueno
cmd-hide-ignored = Oc&ultar conversas ignoradas
cmd-hide-read = Ocultar mensagens li&das
cmd-notify = &Notificar a chegada de e-mails
cmd-open = A&brir o Inbox Classic
cmd-default-app = Definir como aplicativo de e-mail &padrão...
cmd-view-source = Código-&fonte da mensagem
cmd-ai-agents = &Agentes de IA...
cmd-options = &Opções...
cmd-message-rules = Regras de &mensagens...
cmd-encryption-keys = C&haves de criptografia...
cmd-create-rule-from-message = Criar re&gra a partir da mensagem...
# review: new
cmd-unsubscribe = Cancelar inscrição na &lista...
cmd-select-all = Selecionar t&udo
cmd-undo = &Desfazer
cmd-copy = &Copiar para pasta...
cmd-address-book = &Catálogo de Endereços...
cmd-add-sender-to-book = A&dicionar remetente ao Catálogo de Endereços
cmd-import-address-book = Importar Catálogo de En&dereços...
cmd-export-address-book = &Exportar Catálogo de Endereços...
cmd-export-setup = Exportar con&figurações e contas...
cmd-import-setup = Importar confi&gurações e contas...
cmd-compose-sign = &Assinar digitalmente
cmd-compose-encrypt = &Criptografar
cmd-attach-my-key = Anexar minha chave &pública

## The tray icon's menu

tray-check = &Verificar se há e-mails novos
tray-no-accounts = Ainda não há contas

## Words the windows of more than one platform share

ui-tb-create-mail = Nova mensagem
ui-tb-reply = Responder
ui-tb-reply-all = Responder a todos
ui-tb-forward = Encaminhar
ui-tb-print = Imprimir
ui-tb-delete = Excluir
ui-tb-junk = Lixo
ui-tb-not-junk = Não é lixo
ui-tb-archive = Arquivar
ui-tb-previous = Anterior
ui-tb-next = Próxima
ui-previous-tip = Mensagem anterior
ui-next-tip = Próxima mensagem
ui-tb-sync = Enviar/Receber
ui-tb-mark-read = Marcar como lida
ui-tb-mark-unread = Marcar como não lida
ui-still-running = O Inbox Classic continua em execução
ui-no-subject = (sem assunto)
ui-quoted = “{ $subject }”
ui-newest-from = Mensagem mais recente de { $sender }: { $subject }
ui-new-messages = { $count ->
    [one] { $count } mensagem nova
   *[other] { $count } mensagens novas
}
ui-outbox-waiting = { $count ->
    [one] { $count } mensagem na Caixa de Saída
   *[other] { $count } mensagens na Caixa de Saída
}
ui-outbox-waits = { $subject } aguarda na Caixa de Saída
ui-outbox-sending = Enviando { $subject }...
ui-from-account = De { $account }
ui-sign-in-refused = O login em { $account } foi rejeitado ou a sessão expirou.
ui-sign-in-again-ask = Fazer login novamente no navegador?
ui-sign-in-again-failed = Não foi possível fazer login novamente: { $reason }
ui-unknown-reason = motivo desconhecido
ui-checking = Verificando se há mensagens novas em { $account }...
ui-done = Concluído
ui-sent-at = { $subject } enviada às { $time }
ui-draft-saved = Mensagem salva em Rascunhos
ui-draft-not-saved = A mensagem não foi salva em Rascunhos: { $reason }
ui-about-core = Núcleo { $version }
ui-add-account-first = Adicione uma conta de e-mail primeiro.
ui-add-account-first-link = Adicione uma conta de e-mail primeiro e depois clique novamente no link de e-mail.
ui-default-app-is = O Inbox Classic é seu aplicativo de e-mail padrão: os links de e-mail abrem uma nova mensagem aqui.
ui-select-message-first = Selecione uma mensagem primeiro.
ui-store-not-opened = Não foi possível abrir o banco de dados de e-mails.
ui-store-or-cert-not-opened = Não foi possível abrir o banco de dados de e-mails ou o arquivo de certificado.
ui-help-title = Ajuda do Inbox Classic
ui-help-missing = A ajuda não está incluída nesta cópia do Inbox Classic.
ui-ok = OK
ui-cancel = Cancelar
ui-close = Fechar
ui-col-subject = Assunto
ui-col-from = De
ui-col-to = Para
ui-col-received = Recebida
# the column of the glasses of a watched conversation (and the sign of an ignored one)
# a notification of new mail in a watched conversation, over who it is from
ui-watched-conversation = Conversa acompanhada
ui-col-sent = Enviada
ui-col-size = Tamanho
ui-col-folder = Pasta
ui-col-account = Conta
ui-col-queued = Na fila desde
ui-col-status = Status
ui-outbox-title = Caixa de Saída
ui-outbox-status-waiting = Aguardando
ui-outbox-status-not-sent = Não enviada: { $reason }
# This message is still queued, during the grace period before an agent’s send.
ui-outbox-status-agent = Na fila por solicitação de um agente de IA; envio previsto para as { $time }
ui-outbox-delete-ask = Excluir esta mensagem sem enviá-la?
ui-open-link = Abrir link
ui-edit-link = Editar link...
ui-remove-link = Remover link
ui-insert-attachment = Inserir anexo
ui-insert-picture = Inserir imagem
ui-filter-all = Todos os arquivos
ui-filter-pictures = Imagens
ui-filter-messages = Mensagens de e-mail
ui-save-attachment-as = Salvar anexo como
ui-not-sent = Não foi possível enviar a mensagem.
ui-attachment-forgotten = Você escreveu “{ $word }”, mas não há nenhum arquivo anexado. Enviar a mensagem mesmo assim?
ui-send-anyway = Enviar mesmo assim
ui-go-back = Voltar
ui-not-saved = Não foi possível salvar a mensagem.
ui-saving-draft = Salvando em Rascunhos...
ui-compose-saved-at = Salva em Rascunhos às { $time }
ui-compose-restored = Recuperada depois que o Inbox Classic fechou inesperadamente
ui-compose-not-saved = Não salva em Rascunhos: { $reason }
ui-save-changes-ask = Deseja salvar as alterações desta mensagem em Rascunhos?
ui-new-message-title = Nova mensagem
ui-link-invalid = Digite um endereço da Web (https://...) ou um link de e-mail (mailto:...).
ui-link-address = Endereço:
ui-hyperlink = Hiperlink
ui-hyperlink-intro = O endereço para onde o texto selecionado aponta.
ui-edit-hyperlink = Editar hiperlink
ui-edit-hyperlink-intro = O endereço de destino do link. Apague o endereço para remover o link e manter o texto.
ui-not-a-picture = Não foi possível ler a imagem. Escolha um arquivo PNG, JPEG, GIF ou WebP de até 10 MB.
ui-format-color = Cor da fonte
ui-format-numbers = Lista numerada
ui-format-bullets = Lista com marcadores
ui-format-outdent = Diminuir recuo
ui-format-indent = Aumentar recuo
ui-format-left = Alinhar à esquerda
ui-format-center = Centralizar
ui-format-right = Alinhar à direita
ui-format-line = Inserir linha horizontal
ui-tb-send = Enviar
ui-tb-save = Salvar
ui-tb-attach = Anexar
ui-tb-sign = Assinar
ui-tb-encrypt = Criptografar
ui-field-keys = Chaves:
ui-field-from = De:
ui-field-to = Para:
ui-field-cc = Cc:
ui-field-bcc = Cco:
ui-field-subject = Assunto:
ui-field-attach = Anexos:
ui-signature = Assinatura
ui-signature-hint = Adicionada às mensagens novas, respostas e encaminhamentos desta conta.
ui-signature-not-saved = Não foi possível salvar a assinatura.
ui-all-inboxes = Todas as Caixas de Entrada
ui-all-sent = Todas as mensagens enviadas
ui-all-drafts = Todos os Rascunhos
ui-flagged-folder = Sinalizadas
ui-all-folders = Todas as pastas
ui-the-account = a conta
ui-folder-name = Nome da pasta:
ui-find-hint = Pesquisar e-mails
ui-find-tip = Pesquisa assuntos, remetentes, destinatários, nomes de anexos e texto das mensagens.
ui-clear-search = Limpar pesquisa
ui-no-match = Nenhuma mensagem corresponde a “{ $words }”.
ui-no-match-all = A pesquisa abrange assuntos, remetentes, destinatários, nomes de anexos e texto das mensagens em todas as pastas. Verifique a ortografia ou tente menos palavras.
ui-no-match-in = A pesquisa em { $folder } abrange assuntos, remetentes, destinatários, nomes de anexos e texto das mensagens. Verifique a ortografia ou tente menos palavras.
ui-no-items = Não há itens nesta exibição.
ui-choose-folder = Escolha uma pasta para ver suas mensagens.
ui-unsubscribe = Cancelar inscrição
ui-open-in-calendar = Abrir no Calendário
ui-pictures-blocked = Algumas imagens foram bloqueadas para ajudar a impedir que o remetente identifique o seu computador. Clique aqui para baixar as imagens.
ui-not-shown = Não foi possível mostrar a mensagem.
ui-attachment-not-read = Não foi possível ler o anexo.
ui-attachment-not-saved = Não foi possível salvar o anexo.
ui-not-downloaded = A mensagem ainda não foi baixada.
ui-leave-list = Sair desta lista de e-mails?
ui-leave-one-click = O Inbox Classic vai enviar um pedido de cancelamento da inscrição para { $target }. Nenhuma página da Web será aberta e nenhum e-mail será enviado.
ui-leave-mail = Para cancelar a inscrição, envie um e-mail para { $target }. O Inbox Classic o prepara para você. Envie a mensagem para confirmar.
ui-leave-web = A página de cancelamento da inscrição da lista de e-mails vai abrir no seu navegador ({ $target }).
ui-unsubscribing = Cancelando a inscrição em { $target }...
ui-cannot-unsubscribe = Esta mensagem não oferece uma opção para cancelar a inscrição.
ui-unsubscribed = Pedido de cancelamento da inscrição aceito.
ui-not-unsubscribed = Não foi possível cancelar a inscrição: { $reason }
# review: new
ui-list-bar = Esta mensagem é de uma lista de e-mails ({ $domain }).
# review: new
ui-list-bar-plain = Esta mensagem é de uma lista de e-mails.
# review: new
ui-list-bar-asked = Você pediu para sair desta lista em { $date }.
# review: new
ui-list-bar-came-after = Você pediu para sair desta lista em { $date }, mas esta mensagem chegou depois.
# review: new
ui-list-bar-opened = Você abriu a página da lista para sair dela em { $date }.
# review: new
ui-list-bar-failed = A lista não aceitou a solicitação: { $reason }
# review: new
ui-unsubscribe-ask = Cancelar inscrição…
# review: new
ui-unsubscribe-again = Cancelar inscrição novamente…
ui-event-span = { $start } a { $end }
ui-event-floating = { $when } (sem conversão de fuso horário)
ui-invitation = Convite: { $title }
ui-invitation-updated = Convite atualizado: { $title }
ui-invitation-canceled = Cancelado: { $title }
ui-invitation-answer = Resposta a um convite: { $title }
ui-no-title = (sem título)
ui-organizer = Organizador: { $name }
ui-invitation-not-read = Não foi possível ler o convite.
ui-no-calendar = Não foi possível abrir o convite. Verifique se há um aplicativo de calendário configurado para abrir arquivos .ics neste computador.
ui-messages-not-changed = Não foi possível alterar as mensagens.
ui-new-folder-in-selected = A nova pasta será criada dentro da pasta selecionada.
ui-new-folder-at-top = A nova pasta será criada no nível principal da conta.
ui-folder-not-created = Não foi possível criar a pasta.
ui-folder-not-renamed = Não foi possível renomear a pasta.
ui-folder-not-deleted = Não foi possível excluir a pasta.
ui-rename-folder-intro = Digite um novo nome para a pasta “{ $folder }”.
ui-properties-of = Propriedades de { $subject }
ui-internet-headers = Cabeçalhos da Internet desta mensagem:
ui-save-messages-in = Salvar mensagens em
ui-save-message-as = Salvar mensagem como
ui-import-choose-folder = Escolha primeiro a pasta para a qual importar as mensagens.
ui-add-account-title = Adicionar conta de e-mail
ui-accounts-title = Contas
ui-security-none = Nenhuma (não criptografada)
ui-field-required = Preencha o campo { $field }.
ui-email-invalid = O endereço de e-mail não é válido.
ui-ports-invalid = As portas são números de 1 a 65535.
ui-looking-up = Procurando as configurações de { $domain }...
ui-found-none = Digite os dados da conta fornecidos pelo seu provedor de e-mail.
ui-found-change = Altere estas configurações se seu provedor tiver fornecido outras.
ui-found-guess = Não foram encontradas configurações para este endereço. Os nomes dos servidores são apenas sugestões. Confirme-os com seu provedor.
ui-found-mx = O Inbox Classic reconheceu seu provedor de e-mail e preencheu as configurações dos servidores.
ui-found-srv = Estas configurações foram encontradas nos registros DNS do seu domínio.
ui-found-autodiscover = Estas configurações foram encontradas pela Detecção Automática da Microsoft (Exchange).
ui-found-other = Estas configurações foram encontradas para este endereço.
ui-app-password-needed = Provedor: { $provider }. Se sua conta aceitar senhas de app, crie uma nas configurações de segurança e digite-a no campo Senha do próximo formulário. Caso contrário, entre pelo navegador, se essa opção estiver disponível.
ui-app-password-open = Abrir as instruções de { $provider } no navegador?
ui-plain-warning = Sem criptografia, qualquer pessoa que intercepte seu tráfego de rede pode ler sua senha e suas mensagens. Continue apenas se a conexão estiver protegida de outra forma; uma rede local, por si só, não fornece criptografia.
ui-continue-ask = Continuar?
ui-add-sign-in-app = Adicionar um aplicativo de login...
ui-turned-off = A opção “{ $name }” está desativada neste computador.
ui-off-here = Desativado neste computador.
ui-why = Por quê?
ui-more-sign-in = Mais opções de login...
ui-other-account = Para adicionar outra conta de e-mail, digite seu endereço e o nome que os destinatários verão. O Inbox Classic buscará as configurações do servidor na próxima etapa.
ui-field-account-name = Nome da conta:
ui-field-name = Nome de exibição:
ui-field-email = Endereço de e-mail:
ui-field-user = Nome de usuário:
ui-field-password = Senha:
ui-field-imap-host = Servidor de recepção (IMAP):
ui-field-imap-port = Porta IMAP:
ui-field-imap-security = Segurança IMAP:
ui-field-smtp-host = Servidor de envio (SMTP):
ui-field-smtp-port = Porta SMTP:
ui-field-smtp-security = Segurança SMTP:
ui-field-other-addresses = Outros endereços de envio:
ui-sign-in-not-started = Não foi possível iniciar o login pelo navegador.
ui-sign-in-in-browser = Faça login em { $account } na janela do navegador que se abriu e depois volte aqui.
ui-sign-in-failed = Não foi possível fazer login: { $reason }
ui-account-not-saved = Não foi possível salvar a conta.
ui-start-intro = Gmail, Google Workspace, Outlook.com e Microsoft 365: faça login na própria página do Google ou da Microsoft. Sua senha é digitada lá, nunca no Inbox Classic.
ui-start-intro-apps = Faça login pelo navegador com um dos seus aplicativos de login (Mais opções de login), ou adicione qualquer conta de e-mail com seu nome e endereço abaixo.
ui-use-app-password = Usar senha de app
ui-the-provider = Seu provedor de e-mail
ui-provider-intro = { $provider }: faça login em { $email } no site do provedor. Sua senha não é compartilhada com o Inbox Classic. Se sua conta permitir o uso de senhas de app para e-mail, você pode criar uma nas configurações de segurança. Para Outlook.com e Microsoft 365, é necessário fazer login pelo navegador.
ui-provider-intro-apps = { $provider }: faça login em { $email } no site do provedor usando um dos seus aplicativos de login (Mais opções de login). Se sua conta permitir o uso de senhas de app para e-mail, você pode criar uma nas configurações de segurança. Para Outlook.com e Microsoft 365, é necessário fazer login pelo navegador.
ui-finish = Concluir
ui-logon = Login
ui-enter-password = Digite a senha de { $account }.
ui-signs-in-with = Aplicativo de login: { $app }. O login é feito no navegador e a conta usa os servidores deste aplicativo.
ui-keep-password = Deixe o campo da senha vazio para manter a senha atual.
ui-remove-account = Remover conta
ui-remove-account-ask = Remover esta conta do Inbox Classic? Os dados locais, incluindo mensagens não enviadas e credenciais de acesso salvas, serão removidos. Os e-mails no servidor permanecerão lá.
ui-col-email = Endereço de e-mail
ui-col-incoming = Servidor de recepção
ui-type-email = Digite seu endereço de e-mail, nome@example.com.
ui-ai-agent = Agente de IA
ui-ai-agent-access = Acesso de agentes de IA
ui-ai-agents = Agentes de IA
ui-program-path = Programa: { $path }
ui-it-may = Ações permitidas:
ui-accounts-it-may-use = Contas permitidas:
ui-send-message-ask = Enviar a mensagem?
ui-col-name = Nome
ui-never = Nunca
ui-connect-agent = Conectar um agente de IA
ui-connect-agent-intro = Adicione esta configuração à lista de servidores MCP do seu agente (Claude Desktop: Settings > Developer > Edit Config):
ui-col-program = Programa
ui-col-may = Permissões
ui-col-last-used = Último uso
ui-col-when = Quando
ui-col-what = Ação
ui-sign-in-app = Aplicativo de login
ui-sign-in-apps = Aplicativos de login
ui-add-sign-in-app-title = Adicionar aplicativo de login
ui-preset-app-name = Aplicativo de login { $provider }
ui-issuer-not-checked = não é possível verificar o emissor
ui-checking-issuer = Verificando { $issuer }...
ui-issuer-unusable = Não é possível usar o emissor: { $reason }
ui-issuer-usable = O emissor pode ser usado.
ui-sign-in-app-not-saved = Não foi possível salvar o aplicativo de login: { $reason }
ui-check = &Verificar
ui-fill-in-for = Usar configurações para:
ui-app-name = Nome:
ui-issuer = Emissor:
ui-client-id = ID do cliente:
ui-client-secret = Segredo do cliente:
ui-scopes = Permissões (scopes):
ui-imap-server = Servidor IMAP:
ui-smtp-server = Servidor SMTP:
ui-redirect-uri = URI de redirecionamento:
ui-sign-in-app-intro = Um aplicativo de login é um cliente OAuth que você registra no provedor para fazer login pelo navegador. Escolha um provedor para preencher as configurações e informe o ID do cliente e, se houver, o segredo do cliente.
ui-remove-secret = Há um segredo do cliente salvo. Digite um novo para substituí-lo ou remova o segredo salvo
ui-register-it = Registre o aplicativo no seu provedor
ui-built-in-note = O aplicativo { $name } é integrado ao Inbox Classic. Você só pode escolher se ele aparece nas opções de login ao adicionar contas.
ui-client-with-secret = ID do cliente: { $client }, com segredo do cliente.
ui-client-public = ID do cliente: { $client }, cliente público (sem segredo).
ui-no-accounts = Nenhuma conta
ui-remove-sign-in-app = Remover aplicativo de login
ui-remove-sign-in-app-ask = Remover o aplicativo de login { $name } e o segredo do cliente salvo?
ui-sign-in-app-not-removed = O aplicativo de login não foi removido. { $reason }
ui-sign-in-apps-intro = Os aplicativos de login permitem que as contas façam login pelo navegador. Um aplicativo desmarcado não é oferecido para contas novas; as contas que já o usam continuam funcionando.
ui-col-issuer = Emissor
ui-col-used-by = Usado por
ui-options-system-default = Padrão do sistema ({ $language })
ui-settings-general = Geral
ui-settings-reading = Leitura
ui-settings-new-mail = E-mails novos
ui-settings-sending = Envio
ui-settings-default-apps = Aplicativos padrão
ui-settings-message-list = Lista de mensagens
ui-settings-messages = Mensagens
ui-settings-encryption = Criptografia
ui-settings-language = Idioma
ui-settings-label = { $label }:
ui-apply = &Aplicar
ui-language-label = &Idioma:
ui-restart-note = Reinicie o Inbox Classic para mudar o idioma.
ui-restart-ask = Depois de reiniciar, o Inbox Classic usará o idioma { $language }. Reiniciar agora?
ui-notify-new-mail = &Notificar quando chegarem e-mails novos
ui-new-folder-title = Nova pasta
ui-rename-folder-title = Renomear pasta
ui-delete-folder-question = Excluir a pasta “{ $folder }” com as mensagens e as pastas que ela contém? Ela também será excluída no servidor.
ui-properties = &Propriedades
ui-account-sync = Enviar e &receber
ui-account-properties = &Propriedades...
ui-account-move-up = Mover para &cima
ui-account-move-down = Mover para &baixo
ui-menu-open = A&brir
ui-menu-flag = Sinali&zar
ui-menu-view-source = Exibir código-&fonte
ui-save-attachments = Salvar anexos
ui-attachment-open = Abrir
ui-attachment-save-as = Salvar como...
ui-attachment-save-all = Salvar todos...
ui-attachment-show-in-message = Mostrar na mensagem
ui-attachments-strip = Anexos
ui-attachment-note-title = Abrindo este arquivo
ui-attachment-program-tip = Abrir está desativado para este tipo de arquivo: ele pode executar programas. Salve-o para abri-lo você mesmo.
ui-clear-flag = L&impar sinalizador
ui-button-move = &Mover
ui-button-copy = &Copiar
ui-find-folder = Localizar uma pasta
ui-new-folder-in = A nova pasta será criada em { $folder }.
ui-outbox-send-all = &Enviar tudo agora
ui-yes = Sim
ui-no = Não
ui-try-again = Tentar novamente
ui-remove = &Remover
ui-signature-of = Assinatura - { $account }
ui-sign-in-with = Fazer login com { $provider }
ui-sign-in-in-browser-yours = Faça login na sua conta na janela do navegador que se abriu e depois volte aqui.
ui-browser-sign-in-server = { $server } (login no navegador)
ui-dont-allow = Não permitir
ui-allow = &Permitir
ui-dont-send = Não enviar
ui-dont-unsubscribe = Não cancelar inscrição
ui-edit-first = Editar &primeiro
ui-new-address = Endereço novo
ui-turn-away = &Recusar
ui-clear-agent-log = Limpar o histórico de atividade dos agentes?
ui-clear-agent-log-detail = Isso não desfaz as alterações feitas pelos agentes.
ui-let-agents-connect = &Permitir que os agentes de IA se conectem ao Inbox Classic
ui-change-button = Alterar…
ui-undo-button = Desfazer
# Tools > AI Agents: takes back everything the selected program did in a span the user picks
ui-undo-since-button = Desfazer desde…
ui-undo-since-span = Desfazer o que este programa fez:
ui-take-back = Desfazer
ui-rules-title = Regras de mensagens
ui-rules-intro = As regras organizam as mensagens novas da Caixa de Entrada enquanto o Inbox Classic está em execução. As regras correspondentes são executadas em ordem. Quando uma regra move uma mensagem para fora da Caixa de Entrada, as regras seguintes não se aplicam mais a ela.
ui-rules-none = Ainda não há regras. Clique em Nova para criar uma.
ui-rule-new = &Nova...
ui-rule-edit = &Editar...
ui-rule-delete-button = E&xcluir
ui-rule-title = Regra de mensagens
ui-rule-name = Nome:
ui-rule-account = Conta:
ui-rule-all-accounts = Todas as contas
ui-rule-query = Critérios de pesquisa:
ui-rule-query-hint = Use operadores como from:ana@example.com, subject:fatura ou list:news.example.com, assim como na caixa de pesquisa.
ui-rule-count = { $count ->
    [0] Nenhuma mensagem da Caixa de Entrada corresponde atualmente a estes critérios.
    [one] { $count } mensagem da Caixa de Entrada corresponde atualmente a estes critérios.
   *[other] { $count } mensagens da Caixa de Entrada correspondem atualmente a estes critérios.
}
ui-rule-show = M&ostrar
ui-rule-actions = Ações:
ui-rule-move = &Mover para:
ui-rule-mark-read = Marcar como &lida
ui-rule-flag = &Sinalizar
ui-rule-archive = &Arquivar
ui-rule-junk = Mover para Lixo Ele&trônico
ui-rule-delete = &Excluir
ui-rule-quiet = &Não me notificar
ui-rule-apply-now = Aplicá-la também às mensagens que já estão na &Caixa de Entrada
ui-rule-delete-ask = Excluir a regra “{ $name }”?
ui-create-rule = Criar regra...
ui-rules-applied = { $count ->
    [one] { $count } mensagem processada pelas regras
   *[other] { $count } mensagens processadas pelas regras
}
ui-col-rule-matches = Critérios
ui-clear-button = &Limpar
ui-how-to-connect = Como conectar um agente…
ui-agent-programs = Programas cujos agentes pediram acesso ao seu e-mail
ui-what-agents-did = Atividade dos agentes
ui-restart-now = &Reiniciar agora
ui-restart-later = &Mais tarde

## The Address Book (Tools > Address Book), Contact and Group Properties, Select Recipients

ui-tb-new-contact = Novo contato
ui-tb-new-group = Novo grupo
ui-tb-properties = Propriedades
ui-tb-write-to = Escrever para
ui-menu-new-contact = Novo &contato...
ui-menu-new-group = Novo &grupo...
ui-menu-write-to = &Escrever para
ui-menu-delete = E&xcluir
ui-book-find-hint = Digite um nome ou endereço de e-mail
ui-book-all-contacts = Todos os contatos
ui-col-phone = Telefone
ui-book-empty = O Catálogo de Endereços está vazio. Clique em Novo contato para adicionar alguém, ou importe um arquivo vCard ou CSV pelo menu Arquivo.
ui-book-no-match = Nenhum contato corresponde a “{ $words }”.
ui-book-delete-ask = { $count ->
    [one] Excluir este contato do Catálogo de Endereços?
   *[other] Excluir estes { $count } contatos do Catálogo de Endereços?
}
ui-group-delete-ask = Excluir o grupo “{ $name }”? Os contatos do grupo continuarão no Catálogo de Endereços.
ui-book-no-address = { $name } não tem endereço de e-mail.
ui-new-contact-title = Novo contato
ui-contact-title = Propriedades de { $name }
ui-contact-first = Nome:
ui-contact-last = Sobrenome:
ui-contact-display = Nome de exibição:
ui-contact-nickname = Apelido:
ui-contact-company = Empresa:
ui-contact-addresses = Endereços de e-mail:
ui-contact-address-hint = Digite um endereço de e-mail
ui-contact-add = &Adicionar
ui-contact-set-default = Definir como &padrão
ui-contact-default = { $address } (padrão)
ui-contact-phones = Números de telefone:
ui-phone-home = Residencial
ui-phone-work = Trabalho
ui-phone-mobile = Celular
ui-phone-other = Outro
ui-contact-notes = Notas:
ui-contact-name-needed = Digite um nome ou um endereço de e-mail para o contato.
ui-contact-address-invalid = “{ $address }” não é um endereço de e-mail válido.
ui-contact-not-saved = Não foi possível salvar o contato: { $reason }
ui-new-group-title = Novo grupo
ui-group-title = Propriedades de { $name }
ui-group-name = Nome do grupo:
ui-group-members = Membros:
ui-group-select-members = &Selecionar membros...
ui-group-new-member = Adicione um endereço de e-mail que não está no Catálogo de Endereços:
ui-group-name-needed = Digite um nome para o grupo.
ui-group-not-saved = Não foi possível salvar o grupo: { $reason }
ui-group-members-count = { $count ->
    [0] 0 membros
    [one] { $count } membro
   *[other] { $count } membros
}
ui-select-recipients = Selecionar destinatários
ui-select-members = Selecionar membros do grupo
ui-pick-intro = Digite um nome ou selecione-o na lista:
ui-pick-recipients = Destinatários da mensagem:
ui-pick-members = Membros do grupo:
ui-pick-to = &Para →
ui-pick-cc = &Cc →
ui-pick-bcc = Cc&o →
ui-pick-add = &Adicionar →
ui-pick-tip = Escolher destinatários do Catálogo de Endereços
ui-filter-address-books = Catálogos de endereços (vCard, CSV)
ui-filter-vcard = Arquivos vCard
ui-book-export-name = Catálogo de Endereços
ui-book-imported = { $added ->
    [0] Nenhum contato foi adicionado
    [one] { $added } contato foi adicionado
   *[other] { $added } contatos foram adicionados
}, { $skipped ->
    [0] nenhum foi ignorado.
    [one] { $skipped } ignorado por já estar no Catálogo de Endereços.
   *[other] { $skipped } ignorados por já estarem no Catálogo de Endereços.
}
ui-book-not-imported = Não foi possível importar o catálogo de endereços: { $reason }
ui-book-exported = { $count ->
    [0] Nenhum contato foi salvo em { $file }.
    [one] { $count } contato salvo em { $file }.
   *[other] { $count } contatos salvos em { $file }.
}
ui-book-not-exported = Não foi possível salvar o catálogo de endereços: { $reason }
ui-code-copied = Código copiado
ui-codes-in-notifications = &Mostrar códigos de login nas notificações de e-mails novos
ui-tool-unread-only = Não lidas
ui-no-unread = Não há mensagens não lidas aqui.
ui-pictures-always-sender = Sempre baixar imagens de { $sender }
ui-pictures-always-domain = Sempre baixar imagens de remetentes do domínio { $domain }
ui-pictures-unconfirmed = Não foi possível verificar o domínio do remetente ({ $domain }), por isso as imagens desta mensagem não são baixadas automaticamente.
ui-pictures-always-option = &Baixar imagens em todas as mensagens
ui-pictures-always-warning = Os remetentes poderão saber quando você lê as mensagens deles.
ui-protection-details = &Detalhes...
ui-protection-details-title = Detalhes de segurança
ui-download-heading = Download
ui-download-ahead = &Baixar mensagens antecipadamente:
ui-download-ahead-recent = Mensagens recentes até 1 MB cada
ui-download-ahead-all = Todas as mensagens
ui-download-ahead-never = Só quando são abertas
ui-download-limit = &Limite de armazenamento por conta:
ui-send-delay = Tempo &de espera antes do envio:
ui-send-delay-note = Durante o tempo de espera configurado, você pode cancelar o envio com Desfazer.
ui-dark-messages = Mostrar as mensagens em um fundo escuro quando o sistema está no modo escuro
ui-preview-show = Mostrar os a&nexos nas mensagens
ui-preview-show-note = Mostra imagens e as primeiras páginas de arquivos PDF depois do texto da mensagem. O Inbox Classic cria essas visualizações localmente, sem executar scripts ou carregar conteúdo externo dos arquivos.
ui-preview-pdfs = Mostrar arquivos PD&F nas mensagens
ui-sending-in = { $subject } será enviada em { $count ->
    [one] { $count } segundo
   *[other] { $count } segundos
}
ui-send-undone = { $subject } não foi enviada. A mensagem foi reaberta para edição.
ui-send-too-late = Não é mais possível desfazer o envio: { $subject }.
ui-outbox-status-undo = Envio previsto para as { $time }
ui-download-note = As mensagens já baixadas abrem sem esperar pelo servidor. Ao exceder o limite, o aplicativo remove as cópias locais mais antigas que podem ser descartadas; elas serão baixadas novamente quando você as abrir. Rascunhos e mensagens abertas nesta execução ficam fora desse limite.
ui-attachment-downloading = O download desta mensagem ainda não terminou. Tente novamente quando o download estiver concluído.
ui-trusted-senders-button = &Remetentes confiáveis...
ui-trusted-senders-title = Remetentes confiáveis
ui-trusted-senders-note = As imagens das mensagens destes remetentes são baixadas automaticamente quando seu provedor de e-mail verifica o domínio do remetente.
ui-trusted-everyone-at = Remetentes do domínio { $domain }
ui-trusted-senders-empty = Nenhum remetente confiável foi adicionado ainda.
ui-search-encrypted = Pesquisar em mensagens &criptografadas
ui-search-encrypted-note = Se a chave privada necessária estiver disponível, o Inbox Classic pode descriptografar neste computador as mensagens baixadas ou abertas. Você pode então pesquisar no texto e ver na lista uma prévia e o assunto protegido, se houver. O conteúdo descriptografado fica armazenado sem criptografia no índice de pesquisa local. Os agentes de IA não podem pesquisar nesse conteúdo. Ao desativar esta opção, esse conteúdo é removido do índice.
ui-pgp-keyserver = &Procurar chaves em keys.openpgp.org
ui-pgp-keyserver-note = Quando você procura uma chave pelo endereço de e-mail, o domínio desse endereço é consultado primeiro. Se necessário, o endereço é enviado para keys.openpgp.org. Se você procura pela impressão digital ou pelo ID da chave, esse identificador é enviado no lugar do endereço.
ui-eml-default = Abrir arquivos .&eml com o Inbox Classic
ui-eml-default-done = O Inbox Classic agora abre os arquivos .eml.
ui-eml-default-failed = Não foi possível definir o Inbox Classic como aplicativo padrão para arquivos .eml: { $reason }
ui-folders = Pastas
ui-sorted-by = Ordenado por { $field }
ui-layout-label = &Layout:
ui-columns-note = A janela é larga o suficiente para o layout em colunas. Você pode alterar o layout em Exibir > Layout.
ui-row-unread = Não lida
ui-row-flagged = Sinalizada
ui-row-attachments = Tem anexos
ui-row-encrypted = Criptografada
ui-row-signed = Assinada
ui-row-messages = { $count ->
    [0] 0 mensagens
    [one] { $count } mensagem
   *[other] { $count } mensagens
}
ui-list-pictures = &Mostrar as imagens dos remetentes na lista de mensagens
ui-list-pictures-note = No layout em colunas, mostra logotipos de marcas ou imagens do Catálogo de Endereços quando o domínio do remetente é verificado, e as iniciais quando não há imagem. Os logotipos baixados são salvos e reutilizados em várias mensagens.
ui-card-picture = Imagem:
ui-card-picture-choose = &Escolher...
ui-picture-not-picture = Não foi possível ler este arquivo como uma imagem PNG ou JPEG.
ui-picture-too-large = Esta imagem é grande demais. Escolha uma que não tenha mais de 10 MB, com largura e altura de no máximo 8000 pixels.

## Encryption keys (Tools > Encryption Keys, Account Properties > Security, a contact's key)
ui-keys-title = Chaves de criptografia
ui-keys-intro = Suas chaves permitem assinar digitalmente suas mensagens e ler e-mails criptografados para você. As chaves públicas dos contatos permitem verificar as assinaturas digitais deles e criptografar as mensagens que você envia a eles.
ui-keys-empty = Ainda não há chaves. Clique em Nova chave para criar a sua, ou em Importar para adicionar uma chave que você já tem.
ui-keys-col-name = Nome
ui-keys-col-address = Endereço
ui-keys-col-kind = Tipo
ui-keys-col-status = Status
ui-keys-kind-own = Sua chave
ui-keys-kind-contact = Contato
ui-keys-status-verified = { $status }, verificada
ui-keys-new = &Nova chave...
ui-keys-import = &Importar...
ui-keys-export = &Exportar...
ui-keys-backup = &Backup...
ui-keys-verify = &Verificar...
ui-keys-new-title = Nova chave
ui-keys-new-for = Criar uma chave para:
ui-keys-new-make = &Criar chave
ui-keys-no-account = Adicione uma conta de e-mail primeiro: uma chave é criada para os endereços de uma conta.
ui-keys-memory-only = As senhas são mantidas apenas na memória. Por isso, uma chave privada criada ou importada agora ficará indisponível depois que o Inbox Classic for fechado.
ui-keys-backup-offer = Sua nova chave está pronta. Deseja salvar um backup agora? Se você perder este computador ou ele for restaurado, precisará do backup para recuperar a chave.
ui-keys-backup-now = &Salvar um backup...
ui-keys-later = &Mais tarde
ui-keys-backup-title = Backup da chave
ui-keys-backup-intro = O backup será protegido por uma frase secreta. Mantenha o arquivo e a frase secreta em locais seguros separados: você precisará de ambos para recuperar a chave.
ui-keys-passphrase = &Frase secreta:
ui-keys-passphrase-again = &Digite-a novamente:
ui-keys-passphrase-differ = As frases secretas não são iguais.
ui-keys-passphrase-short = Use uma frase secreta com pelo menos 8 caracteres.
ui-keys-backup-saved = O backup foi salvo.
ui-keys-import-title = Importar chave
ui-keys-import-passphrase = Esta chave privada está protegida por uma frase secreta. Digite-a para importar a chave:
ui-keys-file-filter = Chaves OpenPGP
ui-keys-use-for = Usar esta chave para { $addresses }? Você poderá assinar digitalmente mensagens desses endereços e ler aqui os e-mails criptografados com a chave pública correspondente.
ui-keys-use = &Usar
ui-keys-not-now = &Agora não
ui-keys-remove-own = Remover sua chave { $fingerprint }? Sem ela, você não poderá descriptografar e-mails que dependam dessa chave, a menos que importe o backup novamente. Isso não apaga conteúdo já descriptografado do índice de pesquisa local.
ui-keys-remove-contact = Remover a chave de { $name }? Até importá-la novamente, não será possível verificar as assinaturas digitais feitas com ela nem usá-la para criptografar mensagens para esse contato.
ui-key-properties-title = Propriedades da chave
ui-key-names = Nomes:
ui-key-fingerprint = Impressão digital:
ui-key-status = Status:
ui-key-created = Criada:
ui-key-expires = Expira:
ui-key-never = Nunca
ui-key-algorithm = Algoritmo:
ui-key-source = Origem:
ui-key-addresses = Endereços:
ui-key-address-verified = { $address } (verificado)
ui-key-address-not-verified = { $address } (não verificado)
ui-verify-title = Verificar chave
ui-verify-intro = Peça a { $name }, pessoalmente ou por telefone, que leia a impressão digital da chave no próprio aplicativo. Não a compare com uma recebida por e-mail: quem alterasse a chave também poderia alterar a impressão digital.
ui-verify-fingerprint = A impressão digital da chave que você tem:
ui-verify-marks = { $count ->
    [0] Esta chave não tem endereços de e-mail que possam ser associados ao contato. Não é possível salvar a confirmação de titularidade.
    [one] Antes de confirmar, verifique se { $addresses } pertence ao contato. Clique em Coincidem somente se o endereço e todos os grupos da impressão digital estiverem corretos. Caso contrário, clique em São diferentes.
   *[other] Antes de confirmar, verifique se todos estes endereços pertencem ao contato: { $addresses }. Clique em Coincidem somente se todos os endereços e grupos da impressão digital estiverem corretos. Caso contrário, clique em São diferentes.
}
ui-verify-match = &Coincidem
ui-verify-differ = &São diferentes
ui-verify-differs = A chave que você tem é diferente da chave de { $name }. Remova-a e peça ao contato que envie a chave novamente.
ui-verify-unmark = Marcar como &não verificada
ui-account-security = Segurança
ui-account-security-intro = Com uma chave, você pode assinar digitalmente suas mensagens e receber e-mails criptografados.
ui-account-key = &Chave para esta conta:
ui-account-key-none = Nenhuma
ui-account-key-new = &Nova chave...
ui-account-autocrypt = &Enviar minha chave pública com minhas mensagens (Autocrypt)
ui-contact-key = Chave de criptografia:
ui-contact-key-none = Sem chave
ui-contact-key-use-new = Usar a &nova chave
ui-contact-key-keep = &Manter a atual
ui-recipient-keys-title = Chaves dos destinatários
ui-recipient-col-recipient = Destinatário
ui-recipient-col-key = Chave
ui-recipient-find-key = &Procurar chave
ui-recipient-remove = &Remover da mensagem
ui-send-unencrypted = Enviar &sem criptografia
ui-compose-make-key = &Criar uma chave...
ui-compose-show-keys = C&haves de criptografia...
ui-compose-encrypt-off = &Desativar a criptografia
ui-compose-keep-encrypted = &Manter criptografada
ui-setup-export-title = Exportar configurações e contas
ui-setup-import-title = Importar configurações e contas
ui-setup-export-intro = Escolha o que transferir para outro computador. O arquivo não inclui mensagens, nem mesmo as da Caixa de Saída. No outro computador, só será possível baixar as mensagens que estiverem no servidor.
ui-setup-use-passphrase = &Proteger o arquivo com uma frase secreta
ui-setup-passphrase-note = Com uma frase secreta, o arquivo é criptografado e pode incluir as credenciais de login e as chaves privadas selecionadas que estiverem acessíveis. Sem ela, você precisará fazer login nas contas novamente no outro computador.
ui-setup-export-button = &Exportar...
ui-setup-file-filter = Configurações e contas do Inbox Classic
ui-setup-ask-passphrase = Este arquivo está protegido por uma frase secreta. Digite-a para ver o que o arquivo contém:
ui-setup-import-intro = Escolha o que importar. As contas já configuradas neste computador não serão alteradas.
ui-setup-from = Salvo pelo Inbox Classic { $version } em { $date }.
ui-setup-import-button = &Importar
ui-setup-done = Concluído
ui-setup-first-run = Importar configurações e contas de outro computador...
