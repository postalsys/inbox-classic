# What the core says, the same on every platform. Placeables in { $braces } are filled in by the code; keep them, in
# the place the language puts them. Plurals choose by the number: [one] and *[other] in English, the forms your
# language has in yours.
# Português do Brasil. Rascunho, aguardando revisão por um falante nativo. As regras de plural de "pt" contam o 0 como
# [one], por isso as mensagens em que o zero é possível têm um ramo [0] próprio.

## Counts and sizes

# review: new
messages = { $count ->
    [0] 0 mensagens
    [one] { $count } mensagem
   *[other] { $count } mensagens
}
# the separator of decimals in sizes: 2.4 MB
# review: new
decimal-separator = ,
# review: new
size-bytes = { $count ->
    [0] 0 bytes
    [one] { $count } byte
   *[other] { $count } bytes
}
# review: new
size-kb = { $size } KB
# review: new
size-mb = { $size } MB
# review: new
size-gb = { $size } GB
# review: new
send-delay-off = Desativado
# review: new
send-delay-seconds = { $count ->
    [0] 0 segundos
    [one] { $count } segundo
   *[other] { $count } segundos
}
# the status bar: "12 messages, 3 unread"
# review: new
list-counts = { $messages }, { $unread } não lidas
# review: new
list-counts-selected = { $messages }, { $unread } não lidas, { $selected } selecionadas
# the status bar while searching: "12 found, 3 unread"
# review: new
list-counts-found = { $found } encontradas, { $unread } não lidas
# review: new
list-counts-found-selected = { $found } encontradas, { $unread } não lidas, { $selected } selecionadas
# review: new
list-counts-none = Não foram encontradas mensagens

## Special folders, as Outlook Express names them

# review: new
folder-inbox = Caixa de Entrada
# review: new
folder-sent = Itens Enviados
# review: new
folder-deleted = Itens Excluídos
# review: new
folder-drafts = Rascunhos
# review: new
folder-junk = Lixo Eletrônico
# review: new
folder-archive = Arquivo Morto

## The reading pane

# review: new
reader-no-message = Não há nenhuma mensagem selecionada.
# review: new
reader-downloading = Baixando a mensagem…
# review: new
reader-downloading-detail = A mensagem aparece aqui quando o download terminar.
# review: new
reader-downloading-size = A mensagem tem { $size }. Aparece aqui quando for baixada.
# review: new
reader-failed = Não foi possível baixar a mensagem
# review: new
reader-failed-network = Não foi possível contatar o servidor de e-mail ({ $reason }).
# review: new
reader-failed-sign-in = O servidor de e-mail não aceitou o login ({ $reason }). Verifique a senha ou faça login novamente em Arquivo > Contas.
# review: new
reader-failed-security = Não foi possível tornar segura a conexão com o servidor de e-mail ({ $reason }).
# review: new
reader-failed-other = O servidor de e-mail respondeu: { $reason }.
# review: new
reader-retry-note = Uma nova tentativa será feita quando a conta se conectar novamente.
# review: new
reader-unreadable = Não é possível mostrar esta mensagem: { $error }
# review: new
message-source-title = Código-fonte da mensagem: { $subject }
# review: new
message-source-untitled = Código-fonte da mensagem

## Printing a message, and the header of a message quoted in a reply or forward

# review: new
header-from = De
# review: new
header-date = Data
# review: new
header-to = Para
# review: new
header-cc = Cc
# review: new
header-sent = Enviada
# review: new
header-subject = Assunto
# review: new
header-security = Segurança
# review: new
header-part = Parte { $number }
# review: new
quote-original = ----- Mensagem original -----
# review: new
fold-show-earlier = Mostrar as mensagens anteriores

## Bounces: the card at the top of a notice that a message was not delivered

# review: new
bounce-failed = Sua mensagem não foi entregue
# review: new
bounce-delayed = Sua mensagem ainda não foi entregue
# review: new
bounce-delayed-note = Seu servidor de e-mail ainda está tentando entregá-la. Não é preciso enviá-la novamente.
# the link to the message the notice is about, in Sent Items or another folder
# review: new
bounce-show-message = Mostrar a mensagem devolvida
# the link of a delay's card to the message that is still on its way
# review: new
bounce-show-delayed = Mostrar a mensagem atrasada
# review: new
bounce-what-to-do = O que você pode fazer:
# what to do about a recipient the message is still on its way to: in the card of a delay, and in the card of a failure
# review: new
bounce-delayed-do = Nada, por enquanto. Se ainda assim não for possível entregá-la, você receberá outro aviso.
# review: new
bounce-delayed-row-do = Nada, por enquanto. Seu servidor de e-mail ainda está tentando entregá-la, e você receberá outro aviso se ele não conseguir.
# folds the receiving server's own words
# review: new
bounce-details = Detalhes
# a recipient the notice does not name
# review: new
bounce-someone = Um destinatário
# in Details: the server that refused the message, the status code it gave, and the server that wrote the notice
# review: new
bounce-server = Servidor: { $server }
# review: new
bounce-status = Status: { $status }
# review: new
bounce-reported-by = Informado por: { $server }
# review: new
bounce-retry-minutes = O servidor de destino pediu para esperar { $count ->
    [one] { $count } minuto
   *[other] { $count } minutos
} antes da próxima tentativa.
# review: new
bounce-retry-hours = O servidor de destino pediu para esperar { $count ->
    [one] { $count } hora
   *[other] { $count } horas
} antes da próxima tentativa.
# the names of the blocklists, "Spamhaus ZEN, Barracuda"
# review: new
bounce-blocklist = Lista de bloqueio: { $lists }
# review: new
bounce-user-unknown = O endereço não existe
# review: new
bounce-user-unknown-why = O servidor de destino não tem nenhuma caixa de correio com este endereço. Ele pode ter sido digitado errado, ou a pessoa pode não usá-lo mais.
# review: new
bounce-user-unknown-do = Verifique como o endereço está escrito, ou peça à pessoa o endereço que ela usa agora.
# review: new
bounce-invalid-address = O endereço não é válido
# review: new
bounce-invalid-address-why = O endereço não está escrito de uma forma para a qual seja possível enviar e-mails.
# review: new
bounce-invalid-address-do = Procure erros de digitação, como um espaço, uma letra faltando ou nada depois do @.
# review: new
bounce-mailbox-disabled = A caixa de correio está fechada
# review: new
bounce-mailbox-disabled-why = O endereço existe, mas a caixa de correio foi desativada ou não é mais usada.
# review: new
bounce-mailbox-disabled-do = Entre em contato com a pessoa de outra forma e peça um endereço que ela use agora.
# review: new
bounce-mailbox-full = A caixa de correio está cheia
# review: new
bounce-mailbox-full-why = A caixa de correio do destinatário não tem espaço para novos e-mails.
# review: new
bounce-mailbox-full-do = Envie-a novamente daqui a alguns dias, ou avise a pessoa de outra forma. Os anexos grandes são os primeiros a ser recusados.
# review: new
bounce-spam-blocked = Recusada como spam
# review: new
bounce-spam-blocked-why = O servidor de destino considerou a mensagem spam.
# review: new
bounce-spam-blocked-do = Envie-a novamente sem o que parece spam, como muitos links, links encurtados ou um anexo grande. Se continuar acontecendo, pergunte ao seu provedor de e-mail.
# review: new
bounce-virus-detected = Recusada por causa de um vírus
# review: new
bounce-virus-detected-why = O servidor de destino encontrou um vírus ou outro conteúdo nocivo na mensagem ou nos anexos.
# review: new
bounce-virus-detected-do = Verifique os anexos com um antivírus. Alguns servidores recusam qualquer programa ou arquivo compactado, por isso compartilhe esses arquivos por meio de um link.
# review: new
bounce-ip-blocklisted = Seu servidor de e-mail está em uma lista de bloqueio
# review: new
bounce-ip-blocklisted-why = O servidor de destino recusa e-mails do servidor que enviou o seu, porque o endereço desse servidor está em uma lista de bloqueio.
# review: new
bounce-ip-blocklisted-do = O problema não é a mensagem. Encaminhe este aviso para seu provedor de e-mail e peça que ele retire o servidor da lista.
# review: new
bounce-domain-blocklisted = Um domínio está em uma lista de bloqueio
# review: new
bounce-domain-blocklisted-why = O servidor de destino recusa a mensagem porque o domínio do seu endereço, ou um domínio dos links da mensagem, está em uma lista de bloqueio.
# review: new
bounce-domain-blocklisted-do = Se a mensagem tiver links, tente enviá-la sem eles. Caso contrário, encaminhe este aviso para quem gerencia o e-mail do seu domínio.
# review: new
bounce-policy-blocked = Recusada pelas regras do servidor de destino
# review: new
bounce-policy-blocked-why = As regras do servidor de destino não deixam passar esta mensagem, por exemplo por causa do tamanho, dos anexos ou de quem a enviou.
# review: new
bounce-policy-blocked-do = As palavras do próprio servidor em Detalhes muitas vezes indicam o motivo. Pergunte ao destinatário se ele pode aceitar este tipo de e-mail.
# review: new
bounce-geo-blocked = Recusada por causa da origem
# review: new
bounce-geo-blocked-why = O servidor de destino não aceita e-mails do país ou da rede onde está seu servidor de e-mail.
# review: new
bounce-geo-blocked-do = Entre em contato com a pessoa de outra forma, ou pergunte ao seu provedor de e-mail.
# review: new
bounce-relay-denied = O servidor não a encaminhou
# review: new
bounce-relay-denied-why = Um servidor se recusou a entregar a mensagem, muitas vezes porque ela foi enviada sem login ou por um servidor que não atende este destinatário.
# review: new
bounce-relay-denied-do = Verifique o servidor de envio da conta em Arquivo > Contas, e se ele faz login.
# review: new
bounce-auth-failure = Não foi possível verificar o seu endereço de remetente
# review: new
bounce-auth-failure-why = O servidor de destino não conseguiu confirmar que a mensagem veio realmente do seu domínio (SPF, DKIM ou DMARC).
# review: new
bounce-auth-failure-do = Encaminhe este aviso para quem gerencia o e-mail do seu domínio: as configurações precisam ser corrigidas. Enquanto isso, enviar pelo servidor do seu provedor pode ajudar.
# review: new
bounce-rate-limited = E-mails demais de uma vez
# review: new
bounce-rate-limited-why = Por enquanto, o servidor de destino aceita menos mensagens do seu servidor de e-mail.
# review: new
bounce-rate-limited-do = Aguarde um pouco e envie-a novamente. Quando escrever para muitas pessoas, envie para menos de cada vez.
# review: new
bounce-greylisting = Retida por um momento
# review: new
bounce-greylisting-why = O servidor de destino pede aos remetentes desconhecidos que tentem novamente um pouco mais tarde, uma verificação comum contra o spam.
# review: new
bounce-greylisting-do = Nada. Os servidores de e-mail tentam novamente sozinhos, e a mensagem costuma ser entregue em até uma hora.
# review: new
bounce-server-error = O servidor de destino teve um problema
# review: new
bounce-server-error-why = Não foi possível contatar o servidor de destino, ou ele não conseguiu aceitar a mensagem por causa de um problema próprio.
# review: new
bounce-server-error-do = Envie-a novamente mais tarde. Se continuar falhando, procure erros de digitação na parte do endereço depois do @.
# review: new
bounce-unknown = Não entregue
# review: new
bounce-unknown-why = O aviso não diz claramente porquê.
# review: new
bounce-unknown-do = As palavras do próprio servidor em Detalhes podem dizer mais. Se não ajudarem, encaminhe este aviso para seu provedor de e-mail.

## Several messages selected

# review: new
selection-title = { $count ->
    [one] { $count } mensagem selecionada
   *[other] { $count } mensagens selecionadas
}
# review: new
selection-unread = { $count ->
    [0] nenhuma não lida
    [one] { $count } não lida
   *[other] { $count } não lidas
}
# review: new
selection-flagged = { $count ->
    [0] nenhuma sinalizada
    [one] { $count } sinalizada
   *[other] { $count } sinalizadas
}
# review: new
delete-for-good-one = Esta mensagem será excluída permanentemente. Excluí-la?
# review: new
delete-for-good-all = Estas { $count } mensagens serão excluídas permanentemente. Excluí-las?
# review: new
delete-for-good-some = { $count } das { $total } mensagens serão excluídas permanentemente. Excluir as mensagens?
# review: new
done-read = { $count ->
    [one] { $messages } marcada como lida
   *[other] { $messages } marcadas como lidas
}
# review: new
done-unread = { $count ->
    [one] { $messages } marcada como não lida
   *[other] { $messages } marcadas como não lidas
}
# review: new
done-flagged = { $count ->
    [one] { $messages } sinalizada
   *[other] { $messages } sinalizadas
}
# review: new
done-unflagged = Sinalizador removido de { $messages }
# review: new
done-deleted-for-good = { $count ->
    [one] { $messages } excluída permanentemente
   *[other] { $messages } excluídas permanentemente
}
# review: new
done-archived = { $count ->
    [one] { $messages } arquivada
   *[other] { $messages } arquivadas
}
# review: new
done-moved = { $count ->
    [one] { $messages } movida para { $folder }
   *[other] { $messages } movidas para { $folder }
}
# review: new
done-copied = { $count ->
    [one] { $messages } copiada para { $folder }
   *[other] { $messages } copiadas para { $folder }
}
# review: new
done-moving = { $count ->
   *[other] Movendo { $messages } para { $folder }...
}
# review: new
done-copying = { $count ->
   *[other] Copiando { $messages } para { $folder }...
}
# review: new
done-moved-back = { $count ->
    [one] { $messages } devolvida a { $folder }
   *[other] { $messages } devolvidas a { $folder }
}
# the status bar after Watch Conversation and Ignore Conversation, and after either again on a marked one
# review: new
done-watched = { $count ->
    [one] Acompanhando a conversa
   *[other] Acompanhando { $count } conversas
}
# review: new
done-unwatched = { $count ->
    [one] Você deixou de acompanhar a conversa
   *[other] Você deixou de acompanhar { $count } conversas
}
# review: new
done-ignored = { $count ->
    [one] Ignorando a conversa
   *[other] Ignorando { $count } conversas
}
# review: new
done-unignored = { $count ->
    [one] Você deixou de ignorar a conversa
   *[other] Você deixou de ignorar { $count } conversas
}
# review: new
their-folders = as pastas de origem
# review: new
undo-move = Desfazer mover
# review: new
undo-delete = Desfazer excluir
# review: new
undo-archive = Desfazer arquivar
# review: new
undo-junk = Desfazer marcar como lixo
# review: new
undo-not-junk = Desfazer marcar como não lixo
# review: new
undo-send = Desfazer envio
# review: new
nothing-to-undo = Não há nada para desfazer.
# review: new
messages-gone = As mensagens não existem mais.
# A non-selectable IMAP folder cannot contain messages; this does not mean it is empty.
# review: new
folder-holds-no-messages = Esta pasta não pode conter mensagens.
# review: new
not-archived-here = Não é possível arquivar as mensagens desta pasta.
# review: new
not-emptied-here = Só é possível esvaziar Itens Excluídos e Lixo Eletrônico.
# review: new
next-unread-question = Não há mais mensagens não lidas em { $folder }.

    Ir para { $next }, a próxima pasta com mensagens não lidas?
# review: new
no-unread-left = Não há mais mensagens não lidas.
# review: new
empty-question = { $count ->
    [one] Esvaziar { $folder }?

        A mensagem que contém será excluída permanentemente. Não será possível recuperá-la.
   *[other] Esvaziar { $folder }?

        As { $messages } que contém serão excluídas permanentemente. Não será possível recuperá-las.
}
# review: new
no-junk-folder = Esta conta não tem uma pasta Lixo Eletrônico para onde mover as mensagens.
# review: new
no-inbox-folder = Esta conta não tem uma pasta Caixa de Entrada para onde mover as mensagens.
# the status bar after a flag in a colour: "Flagged 2 messages blue"
# review: new
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
# review: new
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

# review: new
move-window-title-move = { $count ->
    [one] Mover mensagem
   *[other] Mover { $count } mensagens
}
# review: new
move-window-title-copy = { $count ->
    [one] Copiar mensagem
   *[other] Copiar { $count } mensagens
}
# review: new
move-window-prompt-move = { $count ->
    [one] Mover a mensagem selecionada para:
   *[other] Mover as { $count } mensagens selecionadas para:
}
# review: new
move-window-prompt-copy = { $count ->
    [one] Copiar a mensagem selecionada para:
   *[other] Copiar as { $count } mensagens selecionadas para:
}
# the folders used last, over the folder tree
# review: new
targets-recent = Recentes
# the folder the messages are in, which can not be chosen
# review: new
target-current = { $folder } (atual)
# a folder used last, with its account when there are several: "Archive (Work)"
# review: new
target-recent = { $folder } ({ $account })

## Moving and copying to another account

# review: new
transfer-moving = Movendo { $done } de { $messages } para { $folder }...
# review: new
transfer-copying = Copiando { $done } de { $messages } para { $folder }...
# review: new
transfer-another-account = outra conta
# review: new
transfer-folder-gone = a pasta de destino não existe mais
# review: new
transfer-not-on-server = a mensagem não está mais no servidor
# review: new
transfer-not-moved = { $count ->
    [one] Não foi possível mover { $messages } para outra conta: { $reason }
   *[other] Não foi possível mover { $messages } para outra conta: { $reason }
}
# review: new
transfer-not-copied = { $count ->
    [one] Não foi possível copiar { $messages } para outra conta: { $reason }
   *[other] Não foi possível copiar { $messages } para outra conta: { $reason }
}
# review: new
transfer-none-moved = Não foi possível mover nenhuma mensagem
# review: new
transfer-none-copied = Não foi possível copiar nenhuma mensagem

## Messages as files

# review: new
export-not-in-time = não foi possível baixar a mensagem a tempo
# review: new
export-not-saved = Não foi possível salvar { $failed } de { $messages } ({ $problems })
# review: new
export-not-attached = não foi possível anexar as mensagens: { $error }
# the status bar after Save As with several: "Saved 3 messages to Desktop"
# review: new
saved-to = { $count ->
    [one] { $messages } salva em { $folder }
   *[other] { $messages } salvas em { $folder }
}
# review: new
download-progress = Baixando { $done } de { $total }
# review: new
download-done = Baixado: { $size }
# review: new
downloading-messages = { $count ->
   *[other] Baixando { $messages }...
}
# the status bar after files are dropped on a folder: "Put 3 messages in Archive"
# review: new
import-put = { $count ->
    [one] { $messages } colocada em { $folder }
   *[other] { $messages } colocadas em { $folder }
}
# review: new
import-not-put = Estes não foram colocados na pasta:

    { $problems }

## Problems the windows show

# review: new
error-store = armazenamento local: { $error }
# review: new
error-not-found = não encontrado
# review: new
error-closed = encerrando
# review: new
error-other-account = o navegador fez login em { $email }, não nesta conta
# a password or sign-in the mail server refused, with the server's words
# review: new
failure-authentication = o servidor não aceitou o login ({ $reason })
# the mail server could not be reached or the connection broke, with the reason
# review: new
failure-network = a conexão com o servidor falhou ({ $reason })
# review: new
error-in-use = não é possível removê-lo enquanto houver contas que fazem login com ele: { $accounts }
# review: new
error-turned-off = este aplicativo de login está desativado para contas novas
# review: new
error-folder-name = o nome da pasta precisa ter entre 1 e 200 caracteres e não pode conter caracteres de controle
# review: new
error-folder-separator = neste servidor, o nome de uma pasta não pode conter “{ $separator }”
# review: new
error-folder-special = não é possível renomear nem excluir a Caixa de Entrada e as pastas especiais
# review: new
error-no-recipients = a mensagem não tem destinatários
# review: new
error-bad-address = “{ $address }” não é um endereço de e-mail
# review: new
error-not-own-address = { $address } não é um dos endereços de remetente desta conta. Adicione-o a “Outros endereços dos quais você envia” nas propriedades da conta.
# review: new
rule-query-refused = As regras não podem filtrar por pasta nem por data ({ $words }).
# review: new
rule-no-query = Digite critérios de pesquisa para as mensagens recebidas.
# review: new
rule-no-action = Escolha pelo menos uma ação para a regra.
# review: new
error-attachment = não foi possível ler { $path }: { $error }
# review: new
error-no-drafts = a conta não tem uma pasta Rascunhos onde salvar a mensagem
# review: new
error-draft-attachment = não foi possível manter um anexo do rascunho: { $error }
# review: new
error-password-not-saved = não foi possível salvar a senha para a próxima inicialização: { $error }
# review: new
error-sign-in-not-saved = não foi possível salvar os novos dados de login para a próxima inicialização: { $error }
# review: new
error-import-unreadable = não é possível ler { $path }: { $error }
# review: new
error-import-too-large = { $path } tem mais de 50 MB
# review: new
error-import-not-mail = { $path } não é uma mensagem de e-mail
# review: new
error-list-answered = o servidor da lista de e-mails retornou o status { $status }
# review: new
error-not-built = não foi possível criar a mensagem
# review: new
error-outbox-waits = { $count ->
    [one] a mensagem aguarda na Caixa de Saída e será enviada no próximo Enviar/Receber
   *[other] { $count } mensagens aguardam na Caixa de Saída e serão enviadas no próximo Enviar/Receber
}
# review: new
error-draft-not-removed = não foi possível remover o rascunho anterior da mensagem de Rascunhos: { $reason }
# review: new
error-sent-but = a mensagem foi enviada, mas { $problem }
# review: new
error-sent-still-in-outbox = continua na Caixa de Saída: { $error }
# review: new
error-sent-no-copy = não foi possível salvar uma cópia em Enviados: { $reason }
# review: new
error-no-password = esta conta não tem senha
# review: new
error-no-sign-in = esta conta não tem login
# review: new
error-provider-missing = esta versão não consegue fazer login em { $provider }: o aplicativo de login foi removido?
# review: new
error-provider-servers = os servidores desta conta não correspondem aos servidores do seu aplicativo de login
# review: new
error-app-scopes = { $reason }. O servidor de e-mail não aceitou o token do aplicativo de login: verifique se as permissões (scopes) do aplicativo dão acesso ao e-mail
# review: new
error-in-folder = { $folder }: { $reason }

## Sign-in apps

# review: new
sign-in-off-google = O Google ainda não verificou o Inbox Classic, por isso só permite o login com ele para usuários de teste. Use seu próprio aplicativo de login do Google ou uma senha de app, ou ative-o em Aplicativos de login (Arquivo > Contas) se você for um usuário de teste.
# review: new
sign-in-off-other = Ele foi desativado em Aplicativos de login (Arquivo > Contas), onde pode ser ativado novamente.
# review: new
sign-in-app-no-name = o aplicativo de login precisa de um nome
# review: new
sign-in-app-no-client = falta o ID de cliente
# review: new
sign-in-app-no-scopes = o aplicativo de login precisa das permissões (scopes) que dão acesso ao e-mail
# review: new
sign-in-app-bad-host = o endereço do servidor { $server } está faltando ou não é um nome de host válido
# review: new
sign-in-app-plain = o servidor { $server } precisa usar SSL/TLS ou STARTTLS
# review: new
sign-in-app-not-checked = o emissor ainda não foi verificado
# review: new
sign-in-app-issuer-changed = o emissor mudou: digite novamente o segredo de cliente, ou remova-o
# review: new
sign-in-register-google = No Google Cloud Console, crie um cliente OAuth do tipo Desktop app, com o escopo https://mail.google.com/ na tela de consentimento. Enquanto o aplicativo estiver em teste, só seus usuários de teste podem fazer login.
# review: new
sign-in-register-microsoft = No Microsoft Entra, registre um aplicativo com a plataforma Mobile and desktop applications, o URI de redirecionamento http://localhost e os fluxos de cliente público permitidos, e as permissões delegadas IMAP.AccessAsUser.All, SMTP.Send e offline_access. Apenas para a sua organização, use https://login.microsoftonline.com/<tenant ID>/v2.0 como emissor.
# review: new
sign-in-register-other = Registre um cliente nativo (público) com o URI de redirecionamento abaixo; o provedor precisa permitir qualquer porta nele (RFC 8252). Adicione o escopo com o qual o provedor dá acesso ao e-mail.

## Calendar invitations

# review: new
repeats = Repete
# review: new
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
# review: new
repeats-on = { $repeats }: { $days }
# "Every week, 10 times"
# review: new
repeats-times = { $count ->
    [one] { $repeats }, uma vez
   *[other] { $repeats }, { $count } vezes
}
# review: new
day-monday = segunda-feira
# review: new
day-tuesday = terça-feira
# review: new
day-wednesday = quarta-feira
# review: new
day-thursday = quinta-feira
# review: new
day-friday = sexta-feira
# review: new
day-saturday = sábado
# review: new
day-sunday = domingo

## AI agents

# review: new
agent-level-read = Ler os e-mails: pastas, lista de mensagens, pesquisa e mensagens
# review: changed
agent-level-organize = Organizar os e-mails: status de leitura, sinalizadores, lixo, mover, arquivar, novas pastas, excluir para Itens Excluídos e sair de listas de e-mails depois que você disser sim
# review: new
agent-level-drafts = Escrever rascunhos para enviar
# review: new
agent-level-send = Enviar e-mails, cada mensagem só depois de você dizer sim
# review: new
agent-connect-title = { $program } quer usar seu e-mail
# review: new
agent-connect-detail = Um agente de IA pediu para trabalhar com o Inbox Classic. Escolha o que ele pode fazer e quais contas pode ver; você pode alterar isso mais tarde em Ferramentas > Agentes de IA.

    Os agentes leem e-mails escritos por outras pessoas, e uma mensagem pode tentar enganá-los. O Inbox Classic sempre pergunta a você antes de um agente enviar qualquer coisa.
# review: new
agent-reply-to = Resposta a “{ $subject }”
# review: new
agent-reply-all-on = Resposta a todos em “{ $subject }”
# review: new
agent-forward-of = Encaminhamento de “{ $subject }”
# review: new
agent-never-written-one = Você nunca escreveu para { $address }.
# review: new
agent-never-written-many = Você nunca escreveu para { $count } destes endereços.
# review: new
agent-send-title = { $program } quer enviar esta mensagem
# review: new
agent-send-detail = Verifique os destinatários e o conteúdo da mensagem. Depois que você confirmar, a mensagem aguarda { $seconds } segundos na Caixa de Saída, onde você ainda pode excluí-la.
# review: new
agent-change-title = O que { $program } pode fazer
# review: new
agent-change-allowed = Altere o que os agentes de IA deste programa podem fazer com seu e-mail.
# review: new
agent-change-refused = Você negou o acesso a este programa. Permita-o para dar novamente aos agentes dele acesso ao seu e-mail.
# review: new
agent-log-taken-back = { $entry } (desfeito)
# review: new
agent-files = Arquivos: { $files }
# review: new
agent-undo-refused = Não é possível desfazer.
# review: new
agent-undo-refused-why = Não é possível desfazer: { $reason }.
# review: new
agent-undo-impossible = isso não pode ser desfeito
# review: new
agent-undo-not-in-folder = a mensagem não está mais nessa pasta
# review: new
agent-undo-not-arrived = a mensagem (ainda) não está na pasta para onde foi
# review: new
agent-undo-sent = a mensagem já foi enviada
# review: new
agent-original-not-downloaded = a mensagem original ainda não foi baixada. Abra-a primeiro
# review: new
agent-turned-away = Recusado
# review: new
agent-can-nothing = Nada
# review: new
agent-can-read = ler
# review: new
agent-can-organize = organizar
# review: new
agent-can-drafts = escrever rascunhos
# review: new
agent-can-send = enviar com seu sim
# "Read, organize and write drafts"
# review: new
agent-can-list = { $first } e { $last }
# review: new
agent-accounts = { $count ->
    [0] nenhuma conta
    [one] { $count } conta
   *[other] { $count } contas
}
# "Read and organize; 1 account"
# review: new
agent-access = { $can }; { $accounts }
# review: new
agent-unreadable = Não é possível ler esta mensagem.
# review: new
agent-encrypted-original = Esta mensagem está criptografada: um agente não pode respondê-la nem encaminhá-la, porque não consegue criptografar.
# review: new
agent-encrypted = Esta mensagem está criptografada. Somente o usuário pode lê-la, no Inbox Classic.
# review: new
list-encrypted = Mensagem criptografada
# review: new
agent-log-composed = Abriu “{ $subject }” em uma nova mensagem para você terminar
# review: new
agent-log-refused = Você não enviou “{ $subject }”
# review: new
agent-log-sent = Enviou “{ $subject }” para { $to }
# review: new
agent-log-draft = Salvou o rascunho “{ $subject }”
# review: new
agent-log-read = Marcou como lida “{ $subject }”
# review: new
agent-log-unread = Marcou como não lida “{ $subject }”
# review: new
agent-log-flagged = Sinalizou “{ $subject }”
# review: new
agent-log-unflagged = Removeu o sinalizador de “{ $subject }”
# review: new
agent-log-deleted = Excluiu “{ $subject }”
# review: new
agent-log-moved = Moveu “{ $subject }” para { $folder }
# review: new
agent-log-junk = Marcou “{ $subject }” como lixo
# review: new
agent-log-not-junk = Marcou “{ $subject }” como não lixo
# review: new
agent-log-archived = Arquivou “{ $subject }”
# review: new
agent-log-folder = Criou a pasta “{ $name }”
# review: new
agent-log-unsubscribed = Cancelou a inscrição na lista de “{ $subject }”
# review: new
agent-log-unsubscribe-failed = Não foi possível cancelar a inscrição na lista de “{ $subject }”: { $reason }
# review: new
agent-log-unsubscribe-refused = Você não cancelou sua inscrição em { $senders }
# review: new
agent-unsubscribe-title = { $count ->
    [one] { $program } quer cancelar sua inscrição em uma lista de e-mails
   *[other] { $program } quer cancelar sua inscrição em { $count } listas de e-mails
}
# review: new
agent-unsubscribe-detail = { $count ->
    [1] O Inbox Classic pede à lista abaixo que pare de enviar mensagens para você, pelo cancelamento com um clique que ela oferece. Nada mais é enviado, e as mensagens que você tem ficam onde estão.
   *[other] O Inbox Classic pede a cada lista abaixo que pare de enviar mensagens para você, pelo cancelamento com um clique que a lista oferece. Nada mais é enviado, e as mensagens que você tem ficam onde estão.
}

## Keys as the keyboards of the language name them, in the help (Windows and Linux)

# review: new
key-ctrl = Ctrl
# review: new
key-alt = Alt
# review: new
key-shift = Shift
# review: new
key-del = Del
# review: new
key-enter = Enter

## Signing in and passwords

# review: new
sign-in-no-refresh = o provedor não forneceu um token de atualização
# review: new
sign-in-no-account = o provedor não indicou qual conta fez login
# review: new
sign-in-not-finished = o login não terminou
# review: new
secrets-unavailable = { $store } não está disponível
# review: new
secrets-unavailable-why = { $store } não está disponível: { $error }
# review: new
secrets-windows = o Gerenciador de Credenciais
# review: new
secrets-mac = o chaveiro
# review: new
secrets-linux = o chaveiro do sistema (Secret Service)
# review: new
error-no-such-file = o arquivo não existe
# review: new
cards-file-too-big = Este arquivo é grande demais para ser um catálogo de endereços.
# review: new
ui-sender-added = { $name } foi adicionado ao Catálogo de Endereços.
# review: new
ui-sender-known = { $name } já está no Catálogo de Endereços.
# review: new
ui-sender-none = O remetente desta mensagem não tem um endereço de e-mail para adicionar.
# review: new
card-name-needed = O contato não tem nome nem endereço de e-mail.
# a file of Import Address Book that could not be read: "contacts.vcf: there is no such file"
# review: new
cards-file-failed = { $file }: { $reason }

## One-time codes: the card at the top of a message with a sign-in or verification code

# the domain the code is for, which signed the message
# review: new
otp-heading = Código de { $domain }
# review: new
otp-copy = Copiar
# review: new
otp-note = Digite-o apenas em uma página de { $domain }.
# review: new
otp-old = Este código foi enviado mais de uma hora antes de você abri-lo e provavelmente já expirou.

# how many are invited, in the card of an event
# review: new
event-attendees =
    { $count ->
        [0] 0 participantes
        [one] { $count } participante
       *[other] { $count } participantes
    }

# the first line of a new message's notification when it has a code, for a domain that signed it
# review: new
otp-notification = { $code } é seu código para { $domain }

## OpenPGP keys (keys.rs)
# review: new
pgp-key-valid = Válida
# review: new
pgp-key-expires = Válida até { $date }
# review: new
pgp-key-expired = Expirou em { $date }
# review: new
pgp-key-revoked = Revogada
# review: new
pgp-key-revoked-why = Revogada: { $reason }
# review: new
pgp-key-not-valid = Não válida
# review: new
pgp-key-locked = Não pode ser usada: { $store } não tem mais a chave que a protege. Importe o backup novamente.
# review: new
pgp-source-own = Criada no Inbox Classic
# review: new
pgp-source-file = Importada de um arquivo
# review: new
pgp-source-paste = Colada
# review: new
pgp-source-attachment = De uma mensagem
# review: new
pgp-source-vcard = De um cartão de contato
# review: new
pgp-source-wkd = Do provedor de e-mail do remetente
# review: new
pgp-source-keyserver = De keys.openpgp.org
# review: new
pgp-source-autocrypt = Do cabeçalho Autocrypt de uma mensagem
# review: new
pgp-error-no-store = Não é possível usar { $store }, que protege as chaves privadas: { $error }
# review: new
pgp-error-wrong-passphrase = A frase secreta não está correta.
# review: new
pgp-error-not-a-key = Isso não é uma chave OpenPGP.
# review: new
pgp-error-too-large = A chave é grande demais.
# review: new
pgp-error-unusable = A chave usa criptografia antiga ou fraca e não pode ser usada.
# review: new
pgp-imported-private = { $count ->
    [0] Nenhuma chave privada foi importada.
    [one] Sua chave privada foi importada.
   *[other] { $count } chaves privadas foram importadas.
}
# review: new
pgp-imported-public = { $count ->
    [0] Nenhuma chave foi importada.
    [one] Uma chave foi importada.
   *[other] { $count } chaves foram importadas.
}
# review: new
pgp-imported-pending = Outra chave já é usada para { $addresses }: a nova aguarda no contato até você escolhê-la.
# review: new
pgp-error-needs-passphrase = A chave privada está protegida por uma frase secreta. Digite-a para importar a chave.
# review: new
pgp-error-mismatch = A chave privada não pertence à chave pública dela. Ela pode ter sido alterada.
# review: new
pgp-file-name-public = Chave pública de { $who }.asc
# review: new
pgp-file-name-private = Backup da chave privada de { $who }.asc
# review: new
pgp-pending = Uma chave diferente para { $address } foi encontrada em { $date }.

## Reading signed and encrypted mail (protect.rs)
# review: new
pgp-part-verified = Assinada por { $signer }, chave verificada
# review: new
pgp-part-signed = Assinada por { $signer } (chave não verificada)
# review: new
pgp-part-other = Assinada por { $signer }, que não é o remetente
# review: new
pgp-part-unknown-key = Assinada, mas a chave não é conhecida
# review: new
pgp-part-not-signed = Não assinada
# review: new
pgp-part-not-checked = Assinatura não verificada
# review: new
pgp-part-encrypted = Criptografada. { $signature }
# review: new
pgp-part-no-key = Criptografada para uma chave que você não tem
# review: new
pgp-part-changed = A parte criptografada foi alterada pelo caminho e não é mostrada
# review: new
pgp-part-unprotected = Criptografada sem proteção contra alterações, não é mostrada
# review: new
pgp-part-broken = Não é possível ler a parte criptografada
# review: new
pgp-why-mismatch = A assinatura não corresponde a este texto
# review: new
pgp-why-weak-hash = A assinatura usa { $hash }, que não é mais seguro
# review: new
pgp-why-key-expired = Assinada depois que a chave expirou em { $date }
# review: new
pgp-why-key-revoked = Assinada com uma chave que foi revogada
# review: new
pgp-why-not-signing-key = Assinada com uma chave que não pode assinar
# review: new
pgp-why-from-future = A assinatura tem uma data no futuro
# review: new
pgp-why-signature-expired = A assinatura expirou
# review: new
pgp-why-key-not-valid = Assinada com uma chave que não é válida
# review: new
pgp-why-not-for-you = Assinada para outros destinatários e encaminhada para você
# review: new
pgp-why-not-key-in-use = Assinada com uma chave diferente da usada para { $address }
# review: new
pgp-part-pictures-loaded = { $label }. Imagens da internet foram carregadas
# review: new
pgp-error-no-own-key = Você não tem nenhuma chave para { $address } com a qual assinar ou criptografar. Crie uma em Ferramentas > Chaves de criptografia, ou desative Assinar e Criptografar.
# review: new
pgp-error-missing-keys = { $count ->
    [one] { $addresses } não tem nenhuma chave para a qual criptografar.
   *[other] Estes destinatários não têm nenhuma chave para a qual criptografar: { $addresses }.
}
# review: new
pgp-error-encrypted-quote = Esta mensagem cita ou encaminha uma mensagem criptografada, por isso só pode ser enviada criptografada. Ative Criptografar, ou remova o texto citado.
# review: new
pgp-error-protect = Não foi possível assinar ou criptografar a mensagem: { $reason }
# review: new
pgp-found-keys = A chave de { $addresses } foi encontrada.
# review: new
pgp-found-none = Nenhuma chave foi encontrada para { $addresses }. Peça que enviem a chave pública deles para você.
# review: new
pgp-found-no-key = Nenhuma chave foi encontrada.
# review: new
pgp-find-unavailable = Não foi possível procurar chaves agora: { $error }
# review: new
pgp-publish-pending = keys.openpgp.org enviou um link de confirmação para { $addresses }. Sua chave fica publicada lá depois que você clicar nele.
# review: new
pgp-publish-done = Sua chave está publicada em keys.openpgp.org para { $addresses }.
# review: new
pgp-publish-failed = Não foi possível publicar a chave: { $error }
# review: changed
pgp-keyserver-off = A procura de chaves em keys.openpgp.org está desativada em { $settings }.
# the compose window with Sign and Encrypt: the line under the fields, each recipient's key, the questions
# review: new
pgp-compose-encrypted = { $count ->
    [one] Criptografada e assinada: só você e { $addresses } podem lê-la.
   *[other] Criptografada e assinada: só você e os { $count } destinatários podem lê-la.
}
# review: new
pgp-compose-encrypt-ready = Ela será criptografada e assinada. Adicione destinatários cujas chaves você tem.
# review: new
pgp-compose-missing = { $count ->
    [one] { $addresses } não tem nenhuma chave, por isso a mensagem ainda não pode ser criptografada.
   *[other] { $count } destinatários não têm nenhuma chave, por isso a mensagem ainda não pode ser criptografada: { $addresses }.
}
# review: new
pgp-compose-looking = Procurando as chaves de { $addresses }...
# review: new
pgp-compose-signed = Assinada: os destinatários podem verificar que ela vem de você e não foi alterada.
# review: new
pgp-compose-reply-clear = Não criptografada, embora a mensagem respondida ou encaminhada estivesse criptografada.
# review: new
pgp-compose-encrypted-files = Há arquivos de uma mensagem criptografada anexados, por isso esta mensagem só pode ser enviada criptografada. Ative Criptografar, ou remova esses arquivos.
# review: new
pgp-compose-sign-tip = Assinar a mensagem com sua chave, para que os destinatários possam verificar que ela vem de você e não foi alterada
# review: new
pgp-compose-sign-tip-encrypted = Uma mensagem criptografada é sempre assinada
# review: new
pgp-compose-encrypt-tip = Criptografar a mensagem, para que só você e os destinatários possam lê-la
# review: new
pgp-compose-make-key = Você ainda não tem nenhuma chave para { $address }. Criar uma agora? Com ela, suas mensagens podem ser assinadas e criptografadas.
# review: new
pgp-compose-key-unusable = Sua chave para { $address } não pode ser usada ({ $state }). Abra Chaves de criptografia para importar o backup dela ou criar uma nova chave.
# review: new
pgp-compose-encrypt-off-quote = Esta mensagem cita ou encaminha uma mensagem criptografada. Sem criptografia, ela só poderá ser enviada depois que você remover o que ela cita. Desativar a criptografia mesmo assim?
# review: new
pgp-compose-encrypt-off-reply = Esta mensagem responde a uma mensagem criptografada ou a encaminha. Sem criptografia, qualquer pessoa que manipule sua mensagem no caminho pode lê-la. Desativar a criptografia?
# review: new
pgp-recipient-verified = Chave verificada
# review: new
pgp-recipient-found = Chave não verificada
# review: new
pgp-recipient-own = Sua própria chave
# review: new
pgp-recipient-looking = Procurando uma chave...
# review: new
pgp-recipient-missing = Sem chave
# review: new
pgp-recipient-not-found = Sem chave: nenhuma foi encontrada em { $date }
# review: new
pgp-recipient-unusable = A chave não pode ser usada: { $state }
# review: new
pgp-recipients-intro = A mensagem é criptografada para a chave de cada destinatário e para a sua.
# review: new
pgp-recipients-intro-missing = { $count ->
    [one] { $count } destinatário não tem nenhuma chave para a qual criptografar. Procure a chave dele, remova-o desta mensagem ou envie-a sem criptografia.
   *[other] { $count } destinatários não têm nenhuma chave para a qual criptografar. Procure as chaves deles, remova-os desta mensagem ou envie-a sem criptografia.
}
# review: new
pgp-details-part = Parte { $number }: { $label }
# review: new
pgp-details-signed = Assinada { $when } com a chave { $key }
# review: new
pgp-details-unknown-key = Assinada com a chave { $key }, que você não tem
# review: new
pgp-details-opened = Criptografada para sua chave { $key }
# review: new
pgp-details-for = Criptografada para { $keys }
# review: new
pgp-details-plain = Não assinada e não criptografada
# review: new
pgp-bar-parts = Esta mensagem tem { $count } partes: { $list }. Cada parte indica como está protegida.
# review: new
pgp-bar-count-verified = { $count ->
    [one] { $count } verificada
   *[other] { $count } verificadas
}
# review: new
pgp-bar-count-good = { $count ->
    [one] { $count } assinada ou criptografada
   *[other] { $count } assinadas ou criptografadas
}
# review: new
pgp-bar-count-warning = { $count ->
    [one] { $count } requer atenção
   *[other] { $count } requerem atenção
}
# review: new
pgp-bar-count-neutral = { $count } sem assinatura confirmada
# the setup file: settings, accounts, contacts and keys carried to another computer
# review: new
setup-part-settings = Configurações
# review: new
setup-part-preferences = Preferências das janelas
# review: new
setup-part-accounts = Contas
# review: new
setup-part-sign-in-apps = Aplicativos de login
# review: new
setup-part-contacts = Contatos e grupos
# review: new
setup-part-keys = Chaves de criptografia
# review: new
setup-part-rules = Regras de mensagens
# review: new
setup-part-trusted-senders = Remetentes confiáveis
# review: new
setup-holds-settings = { $count ->
    [0] 0 configurações
    [one] { $count } configuração
   *[other] { $count } configurações
}
# review: new
setup-holds-preferences = { $count ->
    [0] 0 preferências
    [one] { $count } preferência
   *[other] { $count } preferências
}
# review: new
setup-holds-accounts = { $count ->
    [0] 0 contas
    [one] { $count } conta
   *[other] { $count } contas
}
# review: new
setup-holds-sign-in-apps = { $count ->
    [0] 0 aplicativos de login
    [one] { $count } aplicativo de login
   *[other] { $count } aplicativos de login
}
# review: new
setup-holds-built-in = Quais aplicativos de login integrados estão ativados
# review: new
setup-holds-contacts = { $count ->
    [0] 0 contatos
    [one] { $count } contato
   *[other] { $count } contatos
}
# review: new
setup-holds-groups = { $count ->
    [0] 0 grupos
    [one] { $count } grupo
   *[other] { $count } grupos
}
# review: new
setup-holds-own-keys = { $count ->
    [0] 0 chaves suas
    [one] { $count } chave sua
   *[other] { $count } chaves suas
}
# review: new
setup-holds-contact-keys = { $count ->
    [0] 0 chaves de contatos
    [one] { $count } chave de um contato
   *[other] { $count } chaves de contatos
}
# review: new
setup-holds-rules = { $count ->
    [0] 0 regras
    [one] { $count } regra
   *[other] { $count } regras
}
# review: new
setup-holds-trusted-senders = { $count ->
    [0] 0 remetentes confiáveis
    [one] { $count } remetente confiável
   *[other] { $count } remetentes confiáveis
}
# review: new
setup-sign-in-password = Senha
# review: new
setup-account-secret-password = A senha está no arquivo.
# review: new
setup-account-secret-token = O login está no arquivo.
# review: new
setup-account-asks-password = Pede a senha depois da importação.
# review: new
setup-account-signs-in-again = Faz login novamente depois da importação.
# review: new
setup-account-here = Já está configurada aqui, por isso é ignorada.
# review: new
setup-account-no-app = Faz login com { $app }, que não está configurado aqui. Importe também os aplicativos de login.
# review: new
setup-invalid-address = “{ $address }” não é um endereço de e-mail.
# review: new
setup-invalid-server = O servidor { $server } não tem um nome ou uma porta utilizáveis.
# review: new
setup-invalid-user = Não tem nome de usuário.
# review: new
setup-invalid-sign-in = Faz login de uma forma que o Inbox Classic não conhece.
# review: new
setup-error-empty = O arquivo está vazio.
# review: new
setup-error-too-large = O arquivo é grande demais para ser uma configuração do Inbox Classic.
# review: new
setup-error-not-setup = Este arquivo não é uma configuração do Inbox Classic.
# review: new
setup-error-damaged = O arquivo de configuração está danificado e não pode ser lido.
# review: new
setup-error-newer = Esta configuração foi salva por uma versão mais recente do Inbox Classic ({ $version }). Atualize o Inbox Classic e importe-a novamente.
# review: new
setup-error-needs-passphrase = Esta configuração está protegida por uma frase secreta. Digite a frase secreta com a qual ela foi salva.
# review: new
setup-error-wrong-passphrase = Essa não é a frase secreta com a qual esta configuração foi salva.
# review: new
setup-error-changed = O arquivo de configuração foi alterado ou danificado depois de ser salvo, por isso não pode ser importado.
# review: new
setup-error-read = Não foi possível ler o arquivo de configuração: { $error }
# review: new
setup-error-write = Não foi possível salvar a configuração: { $error }
# review: new
setup-error-no-parts = Escolha pelo menos uma parte.
# review: new
setup-left-out = { $count ->
    [one] { $count } entrada de { $part } não pode ser usada e fica de fora.
   *[other] { $count } entradas de { $part } não podem ser usadas e ficam de fora.
}
# review: new
setup-imported-settings = As configurações foram substituídas.
# review: new
setup-imported-preferences = As preferências das janelas foram substituídas.
# review: new
setup-added-accounts = { $count ->
    [one] Foi adicionada { $count } conta.
   *[other] Foram adicionadas { $count } contas.
}
# review: new
setup-skipped-here = { $address } já está configurada aqui, por isso foi ignorada.
# review: new
setup-skipped-no-app = { $address } foi ignorada: faz login com { $app }, que não está configurado aqui.
# review: new
setup-skipped-invalid = { $address } foi ignorada: { $reason }
# review: new
setup-asks-password = { $address } pede a senha quando se conectar.
# review: new
setup-signs-in-again = { $address } pede que você faça login novamente quando se conectar.
# review: new
setup-added-sign-in-apps = { $count ->
    [one] { $count } aplicativo de login foi adicionado.
   *[other] { $count } aplicativos de login foram adicionados.
}
# review: new
setup-skipped-sign-in-apps = { $count ->
    [one] { $count } aplicativo de login já está configurado aqui.
   *[other] { $count } aplicativos de login já estão configurados aqui.
}
# review: new
setup-added-contacts = { $count ->
    [one] { $count } contato foi adicionado ao Catálogo de Endereços.
   *[other] { $count } contatos foram adicionados ao Catálogo de Endereços.
}
# review: new
setup-skipped-contacts = { $count ->
    [one] { $count } contato já está no Catálogo de Endereços.
   *[other] { $count } contatos já estão no Catálogo de Endereços.
}
# review: new
setup-added-groups = { $count ->
    [one] Foi adicionado ou completado { $count } grupo.
   *[other] Foram adicionados ou completados { $count } grupos.
}
# review: new
setup-added-own-keys = { $count ->
    [one] Foi adicionada { $count } chave sua.
   *[other] Foram adicionadas { $count } chaves suas.
}
# review: new
setup-added-contact-keys = { $count ->
    [one] Foi adicionada { $count } chave de um contato.
   *[other] Foram adicionadas { $count } chaves de contatos.
}
# review: new
setup-added-rules = { $count ->
    [one] Foi adicionada { $count } regra de mensagens.
   *[other] Foram adicionadas { $count } regras de mensagens.
}
# review: new
setup-skipped-rules = { $count ->
    [one] { $count } regra de mensagens já está aqui.
   *[other] { $count } regras de mensagens já estão aqui.
}
# review: new
setup-skipped-rules-account = { $count ->
    [one] { $count } regra de mensagens é para uma conta que não está aqui, por isso foi ignorada.
   *[other] { $count } regras de mensagens são para contas que não estão aqui, por isso foram ignoradas.
}
# review: new
setup-rules-waiting = { $count ->
    [one] { $count } regra de mensagens move mensagens para uma pasta que aparece quando a conta dela sincronizar.
   *[other] { $count } regras de mensagens movem mensagens para pastas que aparecem quando as contas delas sincronizarem.
}
# review: new
setup-added-trusted-senders = { $count ->
    [one] Foi adicionado { $count } remetente confiável.
   *[other] Foram adicionados { $count } remetentes confiáveis.
}
# review: new
setup-nothing = Nada foi importado.
# review: new
setup-account-servers = { $imap } e { $smtp } ({ $signin })
# review: new
setup-file-name = Configurações e contas do Inbox Classic
# review: new
setup-skipped-unreachable = { $name } foi ignorado: não foi possível contatar o serviço de login dele. Adicione-o novamente em Aplicativos de login.
# review: new
attachment-runs-programs = “{ $name }” pode executar programas, por isso o Inbox Classic não o abre. Salve-o e depois abra-o você mesmo, se confiar na origem dele.
# review: new
attachment-decrypted-note = Este anexo vem de uma mensagem criptografada. Para abri-lo, o Inbox Classic o armazena descriptografado neste computador, em uma pasta sua que o Inbox Classic esvazia após um dia.
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
