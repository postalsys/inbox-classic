# What the core says, the same on every platform. Placeables in { $braces } are filled in by the code; keep them, in
# the place the language puts them. Plurals choose by the number: [one] and *[other] in English, the forms your
# language has in yours.
# Português do Brasil. Rascunho, aguardando revisão por um falante nativo. As regras de plural de "pt" contam o 0 como
# [one], por isso as mensagens em que o zero é possível têm um ramo [0] próprio.

## Counts and sizes

messages = { $count ->
    [0] 0 mensagens
    [one] { $count } mensagem
   *[other] { $count } mensagens
}
# the separator of decimals in sizes: 2.4 MB
decimal-separator = ,
size-bytes = { $count ->
    [0] 0 bytes
    [one] { $count } byte
   *[other] { $count } bytes
}
size-kb = { $size } KB
size-mb = { $size } MB
size-gb = { $size } GB
send-delay-off = Desativado
send-delay-seconds = { $count ->
    [0] 0 segundos
    [one] { $count } segundo
   *[other] { $count } segundos
}
# the status bar: "12 messages, 3 unread"
list-counts = { $messages }, não lidas: { $unread }
list-counts-selected = { $messages }, não lidas: { $unread }, selecionadas: { $selected }
# the status bar while searching: "12 found, 3 unread"
list-counts-found = Encontradas: { $found }, não lidas: { $unread }
list-counts-found-selected = Encontradas: { $found }, não lidas: { $unread }, selecionadas: { $selected }
list-counts-none = Não foram encontradas mensagens

## Special folders, as Outlook Express names them

folder-inbox = Caixa de Entrada
folder-sent = Itens Enviados
folder-deleted = Itens Excluídos
folder-drafts = Rascunhos
folder-junk = Lixo Eletrônico
folder-archive = Arquivo Morto

## The reading pane

reader-no-message = Não há nenhuma mensagem selecionada.
reader-downloading = Baixando a mensagem…
reader-downloading-detail = A mensagem aparecerá aqui quando o download terminar.
reader-downloading-size = A mensagem tem { $size } e aparecerá aqui quando o download terminar.
reader-failed = Não foi possível baixar a mensagem
reader-failed-network = Não foi possível contatar o servidor de e-mail ({ $reason }).
reader-failed-sign-in = O servidor de e-mail não aceitou o login ({ $reason }). Verifique a senha ou faça login novamente em Arquivo > Contas.
reader-failed-security = Não foi possível tornar segura a conexão com o servidor de e-mail ({ $reason }).
reader-failed-other = O servidor de e-mail respondeu: { $reason }.
reader-retry-note = O download será tentado novamente quando a conta se reconectar.
reader-unreadable = Não é possível mostrar esta mensagem: { $error }
message-source-title = Código-fonte da mensagem: { $subject }
message-source-untitled = Código-fonte da mensagem

## Printing a message, and the header of a message quoted in a reply or forward

header-from = De
header-date = Data
header-to = Para
header-cc = Cc
header-sent = Enviada
header-subject = Assunto
header-security = Segurança
header-part = Parte { $number }
quote-original = ----- Mensagem original -----
fold-show-earlier = Mostrar as mensagens anteriores

## Bounces: the card at the top of a notice that a message was not delivered

bounce-failed = Sua mensagem não foi entregue
bounce-delayed = Sua mensagem ainda não foi entregue
bounce-delayed-note = Seu servidor de e-mail ainda está tentando entregá-la. Não é preciso enviá-la novamente.
# the link to the message the notice is about, in Sent Items or another folder
bounce-show-message = Mostrar a mensagem devolvida
# the link of a delay's card to the message that is still on its way
bounce-show-delayed = Mostrar a mensagem atrasada
bounce-what-to-do = O que você pode fazer:
# what to do about a recipient the message is still on its way to: in the card of a delay, and in the card of a failure
bounce-delayed-do = Aguarde. Se a entrega não for concluída, você receberá outro aviso.
bounce-delayed-row-do = Aguarde. Seu servidor de e-mail continua tentando entregar a mensagem. Você receberá outro aviso se a entrega falhar.
# folds the receiving server's own words
bounce-details = Detalhes
# a recipient the notice does not name
bounce-someone = Um destinatário
# in Details: the server that refused the message, the status code it gave, and the server that wrote the notice
bounce-server = Servidor: { $server }
bounce-status = Status: { $status }
bounce-reported-by = Informado por: { $server }
bounce-retry-minutes = O servidor de destino pediu para esperar { $count ->
    [one] { $count } minuto
   *[other] { $count } minutos
} antes da próxima tentativa.
bounce-retry-hours = O servidor de destino pediu para esperar { $count ->
    [one] { $count } hora
   *[other] { $count } horas
} antes da próxima tentativa.
# the names of the blocklists, "Spamhaus ZEN, Barracuda"
bounce-blocklist = Lista de bloqueio: { $lists }
bounce-user-unknown = O endereço não existe
bounce-user-unknown-why = O servidor de destino não tem nenhuma caixa de correio com este endereço. Ele pode ter sido digitado errado, ou a pessoa pode não usá-lo mais.
bounce-user-unknown-do = Verifique se há erros de digitação no endereço ou peça ao destinatário o endereço que ele usa atualmente.
bounce-invalid-address = O endereço não é válido
bounce-invalid-address-why = O endereço está em um formato inválido para envio de e-mails.
bounce-invalid-address-do = Procure erros de digitação, como um espaço, uma letra faltando ou nada depois do @.
bounce-mailbox-disabled = A caixa de correio está desativada
bounce-mailbox-disabled-why = O endereço existe, mas a caixa de correio foi desativada ou não é mais usada.
bounce-mailbox-disabled-do = Entre em contato com a pessoa de outra forma e peça um endereço que ela use agora.
bounce-mailbox-full = A caixa de correio está cheia
bounce-mailbox-full-why = A caixa de correio do destinatário não tem espaço para novos e-mails.
bounce-mailbox-full-do = Envie-a novamente daqui a alguns dias, ou avise a pessoa de outra forma. Os anexos grandes são os primeiros a ser recusados.
bounce-spam-blocked = Recusada como lixo eletrônico
bounce-spam-blocked-why = O servidor de destino classificou a mensagem como lixo eletrônico.
bounce-spam-blocked-do = Tente enviar novamente sem elementos que possam ser classificados como lixo eletrônico, como muitos links, links encurtados ou anexos grandes. Se o problema persistir, entre em contato com seu provedor de e-mail.
bounce-virus-detected = Recusada por causa de um vírus
bounce-virus-detected-why = O servidor de destino encontrou um vírus ou outro conteúdo nocivo na mensagem ou nos anexos.
bounce-virus-detected-do = Verifique os anexos com um antivírus. Alguns servidores recusam qualquer programa ou arquivo compactado, por isso compartilhe esses arquivos por meio de um link.
bounce-ip-blocklisted = Seu servidor de e-mail está em uma lista de bloqueio
bounce-ip-blocklisted-why = O servidor de destino recusa e-mails do servidor que enviou o seu, porque o endereço desse servidor está em uma lista de bloqueio.
bounce-ip-blocklisted-do = O problema é o bloqueio do servidor, não o conteúdo da mensagem. Encaminhe este aviso ao seu provedor de e-mail e peça que solicite a remoção do servidor da lista.
bounce-domain-blocklisted = Um domínio está em uma lista de bloqueio
bounce-domain-blocklisted-why = O servidor de destino recusa a mensagem porque o domínio do seu endereço, ou um domínio dos links da mensagem, está em uma lista de bloqueio.
bounce-domain-blocklisted-do = Se a mensagem tiver links, tente enviá-la sem eles. Caso contrário, encaminhe este aviso para quem gerencia o e-mail do seu domínio.
bounce-policy-blocked = Recusada pelas regras do servidor de destino
bounce-policy-blocked-why = As regras do servidor de destino impedem a entrega desta mensagem, por exemplo por causa do tamanho, dos anexos ou do remetente.
bounce-policy-blocked-do = A resposta do servidor em Detalhes pode explicar o motivo. Pergunte ao destinatário se ele pode receber esse tipo de e-mail.
bounce-geo-blocked = Recusada por causa da origem
bounce-geo-blocked-why = O servidor de destino não aceita e-mails do país ou da rede onde está seu servidor de e-mail.
bounce-geo-blocked-do = Entre em contato com o destinatário por outro meio ou peça ajuda ao seu provedor de e-mail.
bounce-relay-denied = O servidor não a encaminhou
bounce-relay-denied-why = Um servidor se recusou a entregar a mensagem, muitas vezes porque ela foi enviada sem login ou por um servidor que não atende este destinatário.
bounce-relay-denied-do = Em Arquivo > Contas, verifique as configurações do servidor de envio e se a autenticação está configurada.
bounce-auth-failure = Não foi possível verificar o seu endereço de remetente
bounce-auth-failure-why = O servidor de destino não conseguiu confirmar que a mensagem veio realmente do seu domínio (SPF, DKIM ou DMARC).
bounce-auth-failure-do = Encaminhe este aviso para quem gerencia o e-mail do seu domínio: as configurações precisam ser corrigidas. Enquanto isso, enviar pelo servidor do seu provedor pode ajudar.
bounce-rate-limited = E-mails demais de uma vez
bounce-rate-limited-why = O servidor de destino está limitando temporariamente a quantidade de mensagens recebidas do seu servidor de e-mail.
bounce-rate-limited-do = Aguarde um pouco e tente enviar novamente. Se houver muitos destinatários, divida-os em grupos menores.
bounce-greylisting = Entrega adiada temporariamente
bounce-greylisting-why = O servidor de destino pede aos remetentes desconhecidos que tentem novamente um pouco mais tarde, uma verificação comum contra o spam.
bounce-greylisting-do = Aguarde. Os servidores de e-mail tentam novamente de forma automática, e a mensagem costuma ser entregue em até uma hora.
bounce-server-error = O servidor de destino teve um problema
bounce-server-error-why = Não foi possível contatar o servidor de destino, ou ele não conseguiu aceitar a mensagem por causa de um problema próprio.
bounce-server-error-do = Envie-a novamente mais tarde. Se continuar falhando, procure erros de digitação na parte do endereço depois do @.
bounce-unknown = Não entregue
bounce-unknown-why = O aviso não informa claramente o motivo.
bounce-unknown-do = A resposta do servidor em Detalhes pode fornecer mais informações. Se ela não esclarecer o problema, encaminhe este aviso ao seu provedor de e-mail.

## Several messages selected

selection-title = { $count ->
    [one] { $count } mensagem selecionada
   *[other] { $count } mensagens selecionadas
}
selection-unread = { $count ->
    [0] nenhuma não lida
    [one] { $count } não lida
   *[other] { $count } não lidas
}
selection-flagged = { $count ->
    [0] nenhuma sinalizada
    [one] { $count } sinalizada
   *[other] { $count } sinalizadas
}
delete-for-good-one = Esta mensagem será excluída permanentemente. Excluí-la?
delete-for-good-all = Estas { $count } mensagens serão excluídas permanentemente. Excluí-las?
delete-for-good-some = { $count ->
    [one] { $count } das { $total } mensagens será excluída permanentemente. Excluir as mensagens?
   *[other] { $count } das { $total } mensagens serão excluídas permanentemente. Excluir as mensagens?
}
done-read = { $count ->
    [one] { $messages } marcada como lida
   *[other] { $messages } marcadas como lidas
}
done-unread = { $count ->
    [one] { $messages } marcada como não lida
   *[other] { $messages } marcadas como não lidas
}
done-flagged = { $count ->
    [one] { $messages } sinalizada
   *[other] { $messages } sinalizadas
}
done-unflagged = Sinalizador removido de { $messages }
done-deleted-for-good = { $count ->
    [one] { $messages } excluída permanentemente
   *[other] { $messages } excluídas permanentemente
}
done-archived = { $count ->
    [one] { $messages } arquivada
   *[other] { $messages } arquivadas
}
done-moved = { $count ->
    [one] { $messages } movida para { $folder }
   *[other] { $messages } movidas para { $folder }
}
done-copied = { $count ->
    [one] { $messages } copiada para { $folder }
   *[other] { $messages } copiadas para { $folder }
}
done-moving = { $count ->
   *[other] Movendo { $messages } para { $folder }...
}
done-copying = { $count ->
   *[other] Copiando { $messages } para { $folder }...
}
done-moved-back = { $count ->
    [one] { $messages } movida de volta para { $folder }
   *[other] { $messages } movidas de volta para { $folder }
}
# the status bar after Watch Conversation and Ignore Conversation, and after either again on a marked one
done-watched = { $count ->
    [one] Acompanhando a conversa
   *[other] Acompanhando { $count } conversas
}
done-unwatched = { $count ->
    [one] Você deixou de acompanhar a conversa
   *[other] Você deixou de acompanhar { $count } conversas
}
done-ignored = { $count ->
    [one] Ignorando a conversa
   *[other] Ignorando { $count } conversas
}
done-unignored = { $count ->
    [one] Você deixou de ignorar a conversa
   *[other] Você deixou de ignorar { $count } conversas
}
their-folders = as pastas de origem
undo-move = Desfazer movimentação
undo-delete = Desfazer exclusão
undo-archive = Desfazer arquivamento
undo-junk = Desfazer marcação como lixo eletrônico
undo-not-junk = Desfazer marcação como e-mail legítimo
undo-send = Desfazer envio
nothing-to-undo = Não há nada para desfazer.
messages-gone = As mensagens não estão mais disponíveis.
# A non-selectable IMAP folder cannot contain messages; this does not mean it is empty.
folder-holds-no-messages = Esta pasta não pode conter mensagens.
not-archived-here = Não é possível arquivar as mensagens desta pasta.
not-emptied-here = Só é possível esvaziar as pastas Itens Excluídos e Lixo Eletrônico.
next-unread-question = Não há mais mensagens não lidas em { $folder }.

    Ir para { $next }, a próxima pasta com mensagens não lidas?
no-unread-left = Não há mais mensagens não lidas.
empty-question = { $count ->
    [one] Esvaziar { $folder }?

        A mensagem que contém será excluída permanentemente. Não será possível recuperá-la.
   *[other] Esvaziar { $folder }?

        As { $messages } que contém serão excluídas permanentemente. Não será possível recuperá-las.
}
no-junk-folder = Esta conta não tem uma pasta Lixo Eletrônico para onde mover as mensagens.
no-inbox-folder = Esta conta não tem uma pasta Caixa de Entrada para onde mover as mensagens.
# the status bar after a flag in a colour: "Flagged 2 messages blue"
done-flagged-color = Sinalizador { $color ->
    [red] vermelho
    [orange] laranja
    [yellow] amarelo
    [green] verde
    [blue] azul
    [purple] roxo
   *[gray] cinza
    } aplicado a { $messages }
# the Flag menu: the colours of Apple Mail's flags
flag-color = { $color ->
    [red] Vermelho
    [orange] Laranja
    [yellow] Amarelo
    [green] Verde
    [blue] Azul
    [purple] Roxo
   *[gray] Cinza
}

## The Move and Copy window

move-window-title-move = { $count ->
    [one] Mover mensagem
   *[other] Mover { $count } mensagens
}
move-window-title-copy = { $count ->
    [one] Copiar mensagem
   *[other] Copiar { $count } mensagens
}
move-window-prompt-move = { $count ->
    [one] Mover a mensagem selecionada para:
   *[other] Mover as { $count } mensagens selecionadas para:
}
move-window-prompt-copy = { $count ->
    [one] Copiar a mensagem selecionada para:
   *[other] Copiar as { $count } mensagens selecionadas para:
}
# the folders used last, over the folder tree
targets-recent = Recentes
# the folder the messages are in, which can not be chosen
target-current = { $folder } (atual)
# a folder used last, with its account when there are several: "Archive (Work)"
target-recent = { $folder } ({ $account })

## Moving and copying to another account

transfer-moving = Movendo { $done } de { $messages } para { $folder }...
transfer-copying = Copiando { $done } de { $messages } para { $folder }...
transfer-another-account = outra conta
transfer-folder-gone = a pasta de destino não existe mais
transfer-not-on-server = a mensagem não está mais no servidor
transfer-not-moved = { $count ->
    [one] Não foi possível mover { $messages } para outra conta: { $reason }
   *[other] Não foi possível mover { $messages } para outra conta: { $reason }
}
transfer-not-copied = { $count ->
    [one] Não foi possível copiar { $messages } para outra conta: { $reason }
   *[other] Não foi possível copiar { $messages } para outra conta: { $reason }
}
transfer-none-moved = Não foi possível mover nenhuma mensagem
transfer-none-copied = Não foi possível copiar nenhuma mensagem

## Messages as files

export-not-in-time = não foi possível baixar a mensagem a tempo
export-not-saved = Não foi possível salvar { $failed } de { $messages } ({ $problems })
export-not-attached = não foi possível anexar as mensagens: { $error }
# the status bar after Save As with several: "Saved 3 messages to Desktop"
saved-to = { $count ->
    [one] { $messages } salva em { $folder }
   *[other] { $messages } salvas em { $folder }
}
download-progress = Baixando { $done } de { $total }
download-done = Baixado: { $size }
downloading-messages = { $count ->
   *[other] Baixando { $messages }...
}
# the status bar after files are dropped on a folder: "Put 3 messages in Archive"
import-put = { $count ->
    [one] { $messages } importada para { $folder }
   *[other] { $messages } importadas para { $folder }
}
import-not-put = Não foi possível importar estas mensagens para a pasta:

    { $problems }

## Problems the windows show

error-store = banco de dados local: { $error }
error-not-found = não encontrado
error-closed = encerrando
error-other-account = o navegador fez login em { $email }, não nesta conta
# a password or sign-in the mail server refused, with the server's words
failure-authentication = o servidor não aceitou o login ({ $reason })
# the mail server could not be reached or the connection broke, with the reason
failure-network = a conexão com o servidor falhou ({ $reason })
error-in-use = não é possível removê-lo enquanto houver contas que fazem login com ele: { $accounts }
error-turned-off = este aplicativo de login está desativado para contas novas
error-folder-name = o nome da pasta precisa ter entre 1 e 200 caracteres e não pode conter caracteres de controle
error-folder-separator = neste servidor, o nome de uma pasta não pode conter “{ $separator }”
error-folder-special = não é possível renomear nem excluir a Caixa de Entrada e as pastas especiais
error-no-recipients = a mensagem não tem destinatários
error-bad-address = “{ $address }” não é um endereço de e-mail
error-not-own-address = { $address } não é um dos endereços de remetente desta conta. Adicione-o a “Outros endereços de envio” nas propriedades da conta.
rule-query-refused = As regras não podem filtrar por pasta nem por data ({ $words }).
rule-no-query = Digite critérios de pesquisa para as mensagens recebidas.
rule-no-action = Escolha pelo menos uma ação para a regra.
error-attachment = não foi possível ler { $path }: { $error }
error-no-drafts = a conta não tem uma pasta Rascunhos onde salvar a mensagem
error-draft-attachment = não foi possível manter um anexo do rascunho: { $error }
error-password-not-saved = não foi possível salvar a senha para a próxima vez que o aplicativo for aberto: { $error }
error-sign-in-not-saved = não foi possível salvar as novas credenciais de login para a próxima vez que o aplicativo for aberto: { $error }
error-import-unreadable = não é possível ler { $path }: { $error }
error-import-too-large = { $path } tem mais de 50 MB
error-import-not-mail = { $path } não é uma mensagem de e-mail
error-list-answered = o servidor da lista de e-mails retornou o status { $status }
error-not-built = não foi possível criar a mensagem
error-outbox-waits = { $count ->
    [one] a mensagem aguarda na Caixa de Saída e será enviada no próximo Enviar/Receber
   *[other] { $count } mensagens aguardam na Caixa de Saída e serão enviadas no próximo Enviar/Receber
}
error-draft-not-removed = não foi possível remover o rascunho anterior da mensagem de Rascunhos: { $reason }
error-sent-but = a mensagem foi enviada, mas { $problem }
error-sent-still-in-outbox = continua na Caixa de Saída: { $error }
error-sent-no-copy = não foi possível salvar uma cópia em Itens Enviados: { $reason }
error-no-password = não há uma senha salva para esta conta
error-no-sign-in = não há credenciais de login disponíveis para esta conta
error-provider-missing = esta versão não consegue fazer login em { $provider }: o aplicativo de login foi removido?
error-provider-servers = os servidores desta conta não correspondem aos servidores do seu aplicativo de login
error-app-scopes = { $reason }. O servidor de e-mail não aceitou o token do aplicativo de login: verifique se as permissões (scopes) do aplicativo dão acesso ao e-mail
error-in-folder = { $folder }: { $reason }

## Sign-in apps

sign-in-off-google = O Google ainda não verificou o Inbox Classic, por isso só permite o login com ele para usuários de teste. Use seu próprio aplicativo de login do Google ou uma senha de app, ou ative-o em Aplicativos de login (Arquivo > Contas) se você for um usuário de teste.
sign-in-off-other = Ele foi desativado em Aplicativos de login (Arquivo > Contas), onde pode ser ativado novamente.
sign-in-app-no-name = o aplicativo de login precisa de um nome
sign-in-app-no-client = o ID do cliente não foi informado
sign-in-app-no-scopes = o aplicativo de login precisa das permissões (scopes) que dão acesso ao e-mail
sign-in-app-bad-host = o endereço do servidor { $server } está faltando ou não é um nome de host válido
sign-in-app-plain = o servidor { $server } precisa usar SSL/TLS ou STARTTLS
sign-in-app-not-checked = o emissor ainda não foi verificado
sign-in-app-issuer-changed = o emissor foi alterado: digite novamente o segredo do cliente ou remova-o
sign-in-register-google = No Google Cloud Console, crie um cliente OAuth do tipo Desktop app, com o escopo https://mail.google.com/ na tela de consentimento. Enquanto o aplicativo estiver em teste, só seus usuários de teste podem fazer login.
sign-in-register-microsoft = No Microsoft Entra, registre um aplicativo com a plataforma Mobile and desktop applications e o URI de redirecionamento http://localhost. Habilite os fluxos de cliente público e as permissões delegadas IMAP.AccessAsUser.All, SMTP.Send e offline_access. Para permitir o acesso apenas à sua organização, use https://login.microsoftonline.com/<tenant ID>/v2.0 como emissor.
sign-in-register-other = Registre um cliente nativo (público) com o URI de redirecionamento abaixo; o provedor precisa permitir qualquer porta nele (RFC 8252). Adicione o escopo com o qual o provedor dá acesso ao e-mail.

## Calendar invitations

repeats = Repete
repeats-every = { $unit ->
    [day] { $interval ->
        [one] Todos os dias
       *[other] A cada { $interval } dias
    }
    [week] { $interval ->
        [one] Todas as semanas
       *[other] A cada { $interval } semanas
    }
    [month] { $interval ->
        [one] Todos os meses
       *[other] A cada { $interval } meses
    }
   *[year] { $interval ->
        [one] Todos os anos
       *[other] A cada { $interval } anos
    }
}
# "Every week on Monday, Wednesday"
repeats-on = { $repeats }: { $days }
# "Every week, 10 times"
repeats-times = { $count ->
    [one] { $repeats }, uma vez
   *[other] { $repeats }, { $count } vezes
}
day-monday = segunda-feira
day-tuesday = terça-feira
day-wednesday = quarta-feira
day-thursday = quinta-feira
day-friday = sexta-feira
day-saturday = sábado
day-sunday = domingo

## AI agents

agent-level-read = Ler os e-mails: pastas, lista de mensagens, pesquisa e mensagens
agent-level-organize = Organizar e-mails: alterar o status de leitura e os sinalizadores, marcar como lixo eletrônico, mover mensagens e enviá-las para Itens Excluídos
agent-level-drafts = Escrever rascunhos para você enviar
agent-level-send = Enviar e-mails, com sua confirmação para cada mensagem
agent-connect-title = { $program } quer acessar seus e-mails
agent-connect-detail = Um agente de IA pediu para trabalhar com o Inbox Classic. Escolha o que ele pode fazer e quais contas pode ver; você pode alterar isso mais tarde em Ferramentas > Agentes de IA.

    Os agentes leem e-mails escritos por outras pessoas, e uma mensagem pode tentar enganá-los. O Inbox Classic sempre pergunta a você antes de um agente enviar qualquer coisa.
agent-reply-to = Resposta a “{ $subject }”
agent-reply-all-on = Resposta a todos em “{ $subject }”
agent-forward-of = Encaminhamento de “{ $subject }”
agent-never-written-one = Você nunca escreveu para { $address }.
agent-never-written-many = Você nunca escreveu para { $count } destes endereços.
agent-send-title = { $program } quer enviar esta mensagem
agent-send-detail = Verifique os destinatários e o conteúdo da mensagem. Depois que você confirmar, a mensagem aguarda { $seconds } segundos na Caixa de Saída, onde você ainda pode excluí-la.
agent-change-title = O que { $program } pode fazer
agent-change-allowed = Altere o que os agentes de IA deste programa podem fazer com seu e-mail.
agent-change-refused = Você recusou o acesso deste programa. Altere a permissão para que seus agentes possam acessar seus e-mails.
agent-log-taken-back = { $entry } (desfeito)
agent-files = Arquivos: { $files }
agent-undo-refused = Não é possível desfazer.
agent-undo-refused-why = Não é possível desfazer: { $reason }.
agent-undo-impossible = isso não pode ser desfeito
agent-undo-not-in-folder = a mensagem não está mais nessa pasta
agent-undo-not-arrived = a mensagem ainda não chegou à pasta de destino
agent-undo-sent = a mensagem já foi enviada
agent-original-not-downloaded = a mensagem original ainda não foi baixada. Abra-a primeiro
agent-turned-away = Recusado
agent-can-nothing = Nada
agent-can-read = ler
agent-can-organize = organizar
agent-can-drafts = escrever rascunhos
agent-can-send = enviar com sua confirmação
# "Read, organize and write drafts"
agent-can-list = { $first } e { $last }
agent-accounts = { $count ->
    [0] nenhuma conta
    [one] { $count } conta
   *[other] { $count } contas
}
# "Read and organize; 1 account"
agent-access = { $can }; { $accounts }
agent-unreadable = Não é possível ler esta mensagem.
agent-encrypted-original = Esta mensagem está criptografada: um agente não pode respondê-la nem encaminhá-la, porque não consegue criptografar.
agent-log-composed = Abriu “{ $subject }” na janela de escrita para você concluir
agent-log-refused = Você não enviou “{ $subject }”
agent-log-sent = Colocou “{ $subject }” na fila de envio para { $to }
agent-log-draft = Salvou o rascunho “{ $subject }”
agent-log-read = Marcou como lida “{ $subject }”
agent-log-unread = Marcou como não lida “{ $subject }”
agent-log-flagged = Sinalizou “{ $subject }”
agent-log-unflagged = Removeu o sinalizador de “{ $subject }”
agent-log-deleted = Excluiu “{ $subject }”
agent-log-moved = Moveu “{ $subject }” para { $folder }
agent-log-junk = Marcou “{ $subject }” como lixo eletrônico
agent-log-not-junk = Marcou “{ $subject }” como e-mail legítimo
agent-log-archived = Arquivou “{ $subject }”
agent-log-folder = Criou a pasta “{ $name }”
agent-log-unsubscribed = Cancelou a inscrição na lista de “{ $subject }”

## Keys as the keyboards of the language name them, in the help (Windows and Linux)

key-ctrl = Ctrl
key-alt = Alt
key-shift = Shift
key-del = Del
key-enter = Enter

## Signing in and passwords

sign-in-no-refresh = o provedor não forneceu um token de atualização
sign-in-no-account = o provedor não indicou qual conta fez login
sign-in-not-finished = o login ainda não foi concluído
secrets-unavailable = { $store } não está disponível
secrets-unavailable-why = { $store } não está disponível: { $error }
secrets-windows = o Gerenciador de Credenciais
secrets-mac = o chaveiro
secrets-linux = o chaveiro do sistema (Secret Service)
error-no-such-file = o arquivo não existe
cards-file-too-big = Este arquivo é grande demais para ser um catálogo de endereços.
ui-sender-added = O contato { $name } foi adicionado ao Catálogo de Endereços.
ui-sender-known = { $name } já está no Catálogo de Endereços.
ui-sender-none = O remetente desta mensagem não tem um endereço de e-mail para adicionar.
card-name-needed = O contato não tem nome nem endereço de e-mail.
# a file of Import Address Book that could not be read: "contacts.vcf: there is no such file"
cards-file-failed = { $file }: { $reason }

## One-time codes: the card at the top of a message with a sign-in or verification code

# the domain the code is for, which signed the message
otp-heading = Código de { $domain }
otp-copy = Copiar
otp-note = Digite-o apenas em uma página de { $domain }.
otp-old = Este código foi enviado mais de uma hora antes de você abri-lo e provavelmente já expirou.

# how many are invited, in the card of an event
event-attendees =
    { $count ->
        [0] 0 participantes
        [one] { $count } participante
       *[other] { $count } participantes
    }

# the first line of a new message's notification when it has a code, for a domain that signed it
otp-notification = { $code } é seu código para { $domain }

## OpenPGP keys (keys.rs)
pgp-key-valid = Válida
pgp-key-expires = Válida até { $date }
pgp-key-expired = Expirou em { $date }
pgp-key-revoked = Revogada
pgp-key-revoked-why = Revogada: { $reason }
pgp-key-not-valid = Não válida
pgp-key-locked = Não é possível usar esta chave privada: { $store } não contém mais a chave que a protege. Importe novamente o backup desta chave privada.
pgp-source-own = Criada no Inbox Classic
pgp-source-file = Importada de um arquivo
pgp-source-paste = Colada
pgp-source-attachment = De uma mensagem
pgp-source-vcard = De um cartão de contato
pgp-source-wkd = Do provedor de e-mail do remetente
pgp-source-keyserver = De keys.openpgp.org
pgp-source-autocrypt = Do cabeçalho Autocrypt de uma mensagem
pgp-error-no-store = Não é possível usar { $store }, que protege as chaves privadas: { $error }
pgp-error-wrong-passphrase = A frase secreta não está correta.
pgp-error-not-a-key = Isso não é uma chave OpenPGP.
pgp-error-too-large = A chave é grande demais.
pgp-error-unusable = A chave usa criptografia antiga ou fraca e não pode ser usada.
pgp-imported-private = { $count ->
    [0] Nenhuma chave privada foi importada.
    [one] Sua chave privada foi importada.
   *[other] { $count } chaves privadas foram importadas.
}
pgp-imported-public = { $count ->
    [0] Nenhuma chave foi importada.
    [one] Uma chave foi importada.
   *[other] { $count } chaves foram importadas.
}
pgp-imported-pending = Já existe outra chave em uso para { $addresses }. A nova chave só será usada quando você a selecionar nas propriedades do contato.
pgp-error-needs-passphrase = A chave privada está protegida por uma frase secreta. Digite-a para importar a chave.
pgp-error-mismatch = A chave privada não corresponde à chave pública associada. Ela pode ter sido alterada.
pgp-file-name-public = Chave pública de { $who }.asc
pgp-file-name-private = Backup da chave privada de { $who }.asc
pgp-pending = Uma chave diferente para { $address } foi encontrada em { $date }.

## Reading signed and encrypted mail (protect.rs)
pgp-part-verified = Assinada por { $signer }, chave verificada
pgp-part-signed = Assinada por { $signer } (chave não verificada)
pgp-part-other = Assinada por { $signer }, que não é o remetente
pgp-part-unknown-key = Assinada, mas a chave necessária para verificar a assinatura não está disponível
pgp-part-not-signed = Não assinada
pgp-part-not-checked = Assinatura não verificada
pgp-part-encrypted = Criptografada. { $signature }
pgp-part-no-key = Criptografada para uma chave que você não tem
pgp-part-changed = A parte criptografada foi alterada pelo caminho e não é mostrada
pgp-part-unprotected = Criptografada sem proteção contra alterações, não é mostrada
pgp-part-broken = Não é possível ler a parte criptografada
pgp-why-mismatch = A assinatura não corresponde a este texto
pgp-why-weak-hash = A assinatura usa { $hash }, que não é mais seguro
pgp-why-key-expired = Assinada depois que a chave expirou em { $date }
pgp-why-key-revoked = Assinada com uma chave que foi revogada
pgp-why-not-signing-key = Assinada com uma chave que não pode criar assinaturas digitais
pgp-why-from-future = A assinatura tem uma data no futuro
pgp-why-signature-expired = A assinatura expirou
pgp-why-key-not-valid = Assinada com uma chave que não é válida
pgp-why-not-for-you = Assinada para outros destinatários e encaminhada para você
pgp-part-pictures-loaded = { $label }. Imagens da internet foram carregadas
pgp-error-no-own-key = Você não tem nenhuma chave para { $address } com a qual assinar ou criptografar. Crie uma em Ferramentas > Chaves de criptografia, ou desative Assinar e Criptografar.
pgp-error-missing-keys = { $count ->
    [one] Não há uma chave pública disponível para criptografar mensagens destinadas a { $addresses }.
   *[other] Não há chaves públicas disponíveis para criptografar mensagens destinadas a estes endereços: { $addresses }.
}
pgp-error-encrypted-quote = Esta mensagem cita ou encaminha uma mensagem criptografada, por isso só pode ser enviada criptografada. Ative Criptografar, ou remova o texto citado.
pgp-error-protect = Não foi possível assinar ou criptografar a mensagem: { $reason }
pgp-found-keys = Chaves encontradas para: { $addresses }.
pgp-found-none = Nenhuma chave foi encontrada para { $addresses }. Solicite a chave pública de cada destinatário.
pgp-found-no-key = Nenhuma chave foi encontrada.
pgp-find-unavailable = Não foi possível procurar chaves agora: { $error }
pgp-publish-pending = O serviço keys.openpgp.org enviou links de confirmação para estes endereços: { $addresses }. Confirme cada endereço para que sua chave possa ser encontrada por ele.
pgp-publish-done = Sua chave está publicada em keys.openpgp.org para { $addresses }.
pgp-publish-failed = Não foi possível publicar a chave: { $error }
pgp-keyserver-off = A procura de chaves em keys.openpgp.org está desativada em Opções.
pgp-details-part = Parte { $number }: { $label }
pgp-details-signed = Data da assinatura: { $when }. Chave: { $key }
pgp-details-unknown-key = Assinada com a chave { $key }, que você não tem
pgp-details-opened = Descriptografada com sua chave { $key }
pgp-details-for = Criptografada para { $keys }
pgp-details-plain = Não assinada e não criptografada
pgp-bar-parts = Esta mensagem tem { $count } partes: { $list }. Cada parte indica como está protegida.
pgp-bar-count-verified = { $count ->
    [one] { $count } verificada
   *[other] { $count } verificadas
}
pgp-bar-count-good = { $count ->
    [one] { $count } assinada ou criptografada
   *[other] { $count } assinadas ou criptografadas
}
pgp-bar-count-warning = { $count ->
    [one] { $count } requer atenção
   *[other] { $count } requerem atenção
}
pgp-bar-count-neutral = { $count } sem assinatura confirmada
# the setup file: settings, accounts, contacts and keys carried to another computer
setup-part-settings = Configurações
setup-part-preferences = Preferências das janelas
setup-part-accounts = Contas
setup-part-sign-in-apps = Aplicativos de login
setup-part-contacts = Contatos e grupos
setup-part-keys = Chaves de criptografia
setup-part-rules = Regras de mensagens
setup-part-trusted-senders = Remetentes confiáveis
setup-holds-settings = { $count ->
    [0] 0 configurações
    [one] { $count } configuração
   *[other] { $count } configurações
}
setup-holds-preferences = { $count ->
    [0] 0 preferências
    [one] { $count } preferência
   *[other] { $count } preferências
}
setup-holds-accounts = { $count ->
    [0] 0 contas
    [one] { $count } conta
   *[other] { $count } contas
}
setup-holds-sign-in-apps = { $count ->
    [0] 0 aplicativos de login
    [one] { $count } aplicativo de login
   *[other] { $count } aplicativos de login
}
setup-holds-built-in = Quais aplicativos de login integrados estão ativados
setup-holds-contacts = { $count ->
    [0] 0 contatos
    [one] { $count } contato
   *[other] { $count } contatos
}
setup-holds-groups = { $count ->
    [0] 0 grupos
    [one] { $count } grupo
   *[other] { $count } grupos
}
setup-holds-own-keys = { $count ->
    [0] 0 chaves pessoais
    [one] { $count } chave pessoal
   *[other] { $count } chaves pessoais
}
setup-holds-contact-keys = { $count ->
    [0] 0 chaves de contatos
    [one] { $count } chave de um contato
   *[other] { $count } chaves de contatos
}
setup-holds-rules = { $count ->
    [0] 0 regras
    [one] { $count } regra
   *[other] { $count } regras
}
setup-holds-trusted-senders = { $count ->
    [0] 0 remetentes confiáveis
    [one] { $count } remetente confiável
   *[other] { $count } remetentes confiáveis
}
setup-sign-in-password = Senha
setup-account-secret-password = A senha está no arquivo.
setup-account-secret-token = As credenciais de login estão incluídas no arquivo.
setup-account-asks-password = Você precisará informar a senha após a importação.
setup-account-signs-in-again = Você precisará fazer login novamente após a importação.
setup-account-here = A conta já está configurada neste computador e não será importada novamente.
setup-account-no-app = Faz login com { $app }, que não está configurado aqui. Importe também os aplicativos de login.
setup-invalid-address = “{ $address }” não é um endereço de e-mail.
setup-invalid-server = Confira o nome e a porta do servidor { $server }: há dados ausentes ou inválidos.
setup-invalid-user = O nome de usuário não foi informado.
setup-invalid-sign-in = A conta usa um método de login que o Inbox Classic não reconhece.
setup-error-empty = O arquivo está vazio.
setup-error-too-large = O arquivo é grande demais para ser um arquivo de configurações do Inbox Classic.
setup-error-not-setup = Este não é um arquivo de configurações do Inbox Classic.
setup-error-damaged = O arquivo de configurações está danificado e não pode ser lido.
setup-error-newer = Este arquivo foi salvo por uma versão mais recente do Inbox Classic ({ $version }). Atualize o Inbox Classic e tente importá-lo novamente.
setup-error-needs-passphrase = Este arquivo está protegido por uma frase secreta. Digite a frase usada ao salvá-lo.
setup-error-wrong-passphrase = Esta não é a frase secreta usada para proteger o arquivo.
setup-error-changed = O arquivo de configurações foi alterado ou danificado depois de ser salvo e não pode ser importado.
setup-error-read = Não foi possível ler o arquivo de configurações: { $error }
setup-error-write = Não foi possível salvar o arquivo de configurações: { $error }
setup-error-no-parts = Selecione pelo menos um item.
setup-left-out = { $count ->
    [one] { $count } item de { $part } não pode ser usado e será ignorado.
   *[other] { $count } itens de { $part } não podem ser usados e serão ignorados.
}
setup-imported-settings = As configurações foram substituídas.
setup-imported-preferences = As preferências das janelas foram substituídas.
setup-added-accounts = { $count ->
    [one] Foi adicionada { $count } conta.
   *[other] Foram adicionadas { $count } contas.
}
setup-skipped-here = A conta { $address } já está configurada neste computador e não foi importada novamente.
setup-skipped-no-app = A conta { $address } não foi importada: ela usa { $app } para fazer login, mas esse aplicativo não está configurado neste computador.
setup-skipped-invalid = A conta { $address } não foi importada: { $reason }
setup-asks-password = A senha da conta { $address } será solicitada ao conectar.
setup-signs-in-again = Será necessário fazer login novamente na conta { $address } ao conectar.
setup-added-sign-in-apps = { $count ->
    [one] { $count } aplicativo de login foi adicionado.
   *[other] { $count } aplicativos de login foram adicionados.
}
setup-skipped-sign-in-apps = { $count ->
    [one] { $count } aplicativo de login já está configurado aqui.
   *[other] { $count } aplicativos de login já estão configurados aqui.
}
setup-added-contacts = { $count ->
    [one] { $count } contato foi adicionado ao Catálogo de Endereços.
   *[other] { $count } contatos foram adicionados ao Catálogo de Endereços.
}
setup-skipped-contacts = { $count ->
    [one] { $count } contato já está no Catálogo de Endereços.
   *[other] { $count } contatos já estão no Catálogo de Endereços.
}
setup-added-groups = { $count ->
    [one] Foi adicionado ou atualizado { $count } grupo.
   *[other] Foram adicionados ou atualizados { $count } grupos.
}
setup-added-own-keys = { $count ->
    [one] Foi adicionada { $count } chave pessoal.
   *[other] Foram adicionadas { $count } chaves pessoais.
}
setup-added-contact-keys = { $count ->
    [one] Foi adicionada { $count } chave de um contato.
   *[other] Foram adicionadas { $count } chaves de contatos.
}
setup-added-rules = { $count ->
    [one] Foi adicionada { $count } regra de mensagens.
   *[other] Foram adicionadas { $count } regras de mensagens.
}
setup-skipped-rules = { $count ->
    [one] { $count } regra de mensagens já está configurada neste computador.
   *[other] { $count } regras de mensagens já estão configuradas neste computador.
}
setup-skipped-rules-account = { $count ->
    [one] { $count } regra de mensagens foi ignorada porque sua conta não está configurada neste computador.
   *[other] { $count } regras de mensagens foram ignoradas porque suas contas não estão configuradas neste computador.
}
setup-rules-waiting = { $count ->
    [one] A pasta de destino de { $count } regra de mensagens será identificada após a sincronização da conta.
   *[other] As pastas de destino de { $count } regras de mensagens serão identificadas após a sincronização das contas.
}
setup-added-trusted-senders = { $count ->
    [one] Foi adicionado { $count } remetente confiável.
   *[other] Foram adicionados { $count } remetentes confiáveis.
}
setup-nothing = Nada foi importado.
setup-account-servers = { $imap } e { $smtp } ({ $signin })
setup-file-name = Configurações e contas do Inbox Classic
setup-skipped-unreachable = O aplicativo { $name } não foi importado: não foi possível acessar seu serviço de login. Adicione-o novamente em Aplicativos de login.
attachment-runs-programs = “{ $name }” pode executar programas, por isso o Inbox Classic não o abre. Salve-o e depois abra-o você mesmo, se confiar na origem dele.
attachment-decrypted-note = Este anexo faz parte de uma mensagem criptografada. Para abri-lo, o Inbox Classic salva uma cópia sem criptografia em uma pasta temporária da sua conta de usuário. As cópias com mais de um dia são removidas quando o aplicativo é iniciado.
# a bar over the list when the server did not do what the user asked of messages, so they are as they were again
# review: new
undone-move = { $count ->
    [one] O servidor não moveu { $messages } para { $folder }, por isso ela voltou para { $from }: { $reason }
   *[other] O servidor não moveu { $messages } para { $folder }, por isso elas voltaram para { $from }: { $reason }
}
# review: new
undone-delete = { $count ->
    [one] O servidor não excluiu { $messages }, por isso ela voltou para { $from }: { $reason }
   *[other] O servidor não excluiu { $messages }, por isso elas voltaram para { $from }: { $reason }
}
# review: new
undone-archive = { $count ->
    [one] O servidor não arquivou { $messages }, por isso ela voltou para { $from }: { $reason }
   *[other] O servidor não arquivou { $messages }, por isso elas voltaram para { $from }: { $reason }
}
# review: new
undone-read = { $count ->
    [one] O servidor não marcou { $messages } como lida, por isso ela está não lida novamente: { $reason }
   *[other] O servidor não marcou { $messages } como lidas, por isso elas estão não lidas novamente: { $reason }
}
# review: new
undone-unread = { $count ->
    [one] O servidor não marcou { $messages } como não lida, por isso ela está lida novamente: { $reason }
   *[other] O servidor não marcou { $messages } como não lidas, por isso elas estão lidas novamente: { $reason }
}
# review: new
undone-flags = { $count ->
    [one] O servidor não alterou os sinalizadores de { $messages }, por isso ela está como estava: { $reason }
   *[other] O servidor não alterou os sinalizadores de { $messages }, por isso elas estão como estavam: { $reason }
}
