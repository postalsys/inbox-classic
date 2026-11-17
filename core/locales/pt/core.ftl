# What the core says, the same on every platform. Placeables in { $braces } are filled in by the code; keep them, in
# the place the language puts them. Plurals choose by the number: [one] and *[other] in English, the forms your
# language has in yours.
# Português europeu. Rascunho, à espera de revisão por um falante nativo. As regras de plural de "pt" contam o 0 como
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
folder-deleted = Itens Eliminados
# review: new
folder-drafts = Rascunhos
# review: new
folder-junk = Lixo Eletrónico
# review: new
folder-archive = Arquivo

## The reading pane

# review: new
reader-no-message = Não há nenhuma mensagem selecionada.
# review: new
reader-downloading = A transferir a mensagem…
# review: new
reader-downloading-detail = A mensagem aparece aqui quando a transferência terminar.
# review: new
reader-downloading-size = A mensagem tem { $size }. Aparece aqui quando for transferida.
# review: new
reader-failed = Não foi possível transferir a mensagem
# review: new
reader-failed-network = Não foi possível contactar o servidor de correio ({ $reason }).
# review: new
reader-failed-sign-in = O servidor de correio não aceitou o início de sessão ({ $reason }). Verifique a palavra-passe ou inicie sessão novamente em Ficheiro > Contas.
# review: new
reader-failed-security = Não foi possível tornar segura a ligação ao servidor de correio ({ $reason }).
# review: new
reader-failed-other = O servidor de correio respondeu: { $reason }.
# review: new
reader-retry-note = Será tentado novamente quando a conta voltar a ligar-se.
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
bounce-failed = A sua mensagem não foi entregue
# review: new
bounce-delayed = A sua mensagem ainda não foi entregue
# review: new
bounce-delayed-note = O seu servidor de correio ainda está a tentar entregá-la. Não precisa de a enviar novamente.
# the link to the message the notice is about, in Sent Items or another folder
# review: new
bounce-show-message = Mostrar a mensagem devolvida
# the link of a delay's card to the message that is still on its way
# review: new
bounce-show-delayed = Mostrar a mensagem atrasada
# review: new
bounce-what-to-do = O que pode fazer:
# what to do about a recipient the message is still on its way to: in the card of a delay, and in the card of a failure
# review: new
bounce-delayed-do = Nada, por agora. Se continuar a não ser possível entregá-la, receberá outro aviso.
# review: new
bounce-delayed-row-do = Nada, por agora. O seu servidor de correio ainda está a tentar entregá-la e receberá outro aviso se não conseguir.
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
bounce-status = Estado: { $status }
# review: new
bounce-reported-by = Comunicado por: { $server }
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
bounce-user-unknown-why = O servidor de destino não tem nenhuma caixa de correio com este endereço. Pode ter sido mal escrito, ou a pessoa pode já não o usar.
# review: new
bounce-user-unknown-do = Verifique como o endereço está escrito, ou peça à pessoa o endereço que usa agora.
# review: new
bounce-invalid-address = O endereço não é válido
# review: new
bounce-invalid-address-why = O endereço não está escrito de uma forma para a qual se possa enviar correio.
# review: new
bounce-invalid-address-do = Procure erros de escrita, como um espaço, uma letra em falta ou nada depois do @.
# review: new
bounce-mailbox-disabled = A caixa de correio está fechada
# review: new
bounce-mailbox-disabled-why = O endereço existe, mas a caixa de correio foi desativada ou já não é usada.
# review: new
bounce-mailbox-disabled-do = Contacte a pessoa de outra forma e peça-lhe um endereço que use agora.
# review: new
bounce-mailbox-full = A caixa de correio está cheia
# review: new
bounce-mailbox-full-why = A caixa de correio do destinatário não tem espaço para correio novo.
# review: new
bounce-mailbox-full-do = Envie-a novamente daqui a alguns dias, ou avise a pessoa de outra forma. Os anexos grandes são os primeiros a ser recusados.
# review: new
bounce-spam-blocked = Recusada como spam
# review: new
bounce-spam-blocked-why = O servidor de destino considerou a mensagem spam.
# review: new
bounce-spam-blocked-do = Envie-a novamente sem o que parece spam, como muitas ligações, ligações encurtadas ou um anexo grande. Se continuar a acontecer, pergunte ao seu fornecedor de correio.
# review: new
bounce-virus-detected = Recusada por causa de um vírus
# review: new
bounce-virus-detected-why = O servidor de destino encontrou um vírus ou outro conteúdo nocivo na mensagem ou nos anexos.
# review: new
bounce-virus-detected-do = Verifique os anexos com um antivírus. Alguns servidores recusam qualquer programa ou arquivo comprimido, por isso partilhe esses ficheiros através de uma ligação.
# review: new
bounce-ip-blocklisted = O seu servidor de correio está numa lista de bloqueio
# review: new
bounce-ip-blocklisted-why = O servidor de destino recusa correio do servidor que enviou o seu, porque o endereço desse servidor está numa lista de bloqueio.
# review: new
bounce-ip-blocklisted-do = O problema não é a mensagem. Reencaminhe este aviso para o seu fornecedor de correio e peça-lhe que retire o servidor da lista.
# review: new
bounce-domain-blocklisted = Um domínio está numa lista de bloqueio
# review: new
bounce-domain-blocklisted-why = O servidor de destino recusa a mensagem porque o domínio do seu endereço, ou um domínio das ligações da mensagem, está numa lista de bloqueio.
# review: new
bounce-domain-blocklisted-do = Se a mensagem tiver ligações, experimente enviá-la sem elas. Caso contrário, reencaminhe este aviso para quem gere o correio do seu domínio.
# review: new
bounce-policy-blocked = Recusada pelas regras do servidor de destino
# review: new
bounce-policy-blocked-why = As regras do servidor de destino não deixam passar esta mensagem, por exemplo por causa do tamanho, dos anexos ou de quem a enviou.
# review: new
bounce-policy-blocked-do = As palavras do próprio servidor em Detalhes indicam muitas vezes o motivo. Pergunte ao destinatário se pode aceitar este tipo de correio.
# review: new
bounce-geo-blocked = Recusada por causa da origem
# review: new
bounce-geo-blocked-why = O servidor de destino não aceita correio do país ou da rede onde está o seu servidor de correio.
# review: new
bounce-geo-blocked-do = Contacte a pessoa de outra forma, ou pergunte ao seu fornecedor de correio.
# review: new
bounce-relay-denied = O servidor não a reencaminhou
# review: new
bounce-relay-denied-why = Um servidor recusou-se a entregar a mensagem, muitas vezes porque foi enviada sem iniciar sessão ou através de um servidor que não trata deste destinatário.
# review: new
bounce-relay-denied-do = Verifique o servidor de envio da conta em Ficheiro > Contas, e se este inicia sessão.
# review: new
bounce-auth-failure = Não foi possível verificar o seu endereço de remetente
# review: new
bounce-auth-failure-why = O servidor de destino não conseguiu confirmar que a mensagem veio realmente do seu domínio (SPF, DKIM ou DMARC).
# review: new
bounce-auth-failure-do = Reencaminhe este aviso para quem gere o correio do seu domínio: as definições precisam de ser corrigidas. Entretanto, enviar através do servidor do seu fornecedor pode ajudar.
# review: new
bounce-rate-limited = Demasiado correio de uma vez
# review: new
bounce-rate-limited-why = Por agora, o servidor de destino aceita menos mensagens do seu servidor de correio.
# review: new
bounce-rate-limited-do = Aguarde um pouco e envie-a novamente. Quando escrever a muitas pessoas, envie a menos de cada vez.
# review: new
bounce-greylisting = Retida por momentos
# review: new
bounce-greylisting-why = O servidor de destino pede aos remetentes desconhecidos que tentem novamente um pouco mais tarde, uma verificação comum contra o spam.
# review: new
bounce-greylisting-do = Nada. Os servidores de correio tentam novamente por si e a mensagem costuma ser entregue dentro de uma hora.
# review: new
bounce-server-error = O servidor de destino teve um problema
# review: new
bounce-server-error-why = Não foi possível contactar o servidor de destino, ou este não conseguiu aceitar a mensagem por causa de um problema próprio.
# review: new
bounce-server-error-do = Envie-a novamente mais tarde. Se continuar a falhar, procure erros de escrita na parte do endereço depois do @.
# review: new
bounce-unknown = Não entregue
# review: new
bounce-unknown-why = O aviso não diz claramente porquê.
# review: new
bounce-unknown-do = As palavras do próprio servidor em Detalhes podem dizer mais. Se não ajudarem, reencaminhe este aviso para o seu fornecedor de correio.

## Several messages selected

# review: new
selection-title = { $count ->
    [one] { $count } mensagem selecionada
   *[other] { $count } mensagens selecionadas
}
# review: new
selection-unread = { $count ->
    [one] { $count } não lida
   *[other] { $count } não lidas
}
# review: new
selection-flagged = { $count ->
    [one] { $count } sinalizada
   *[other] { $count } sinalizadas
}
# review: new
delete-for-good-one = Esta mensagem será eliminada permanentemente. Eliminá-la?
# review: new
delete-for-good-all = Estas { $count } mensagens serão eliminadas permanentemente. Eliminá-las?
# review: new
delete-for-good-some = { $count } das { $total } mensagens serão eliminadas permanentemente. Eliminar as mensagens?
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
    [one] { $messages } eliminada permanentemente
   *[other] { $messages } eliminadas permanentemente
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
   *[other] A mover { $messages } para { $folder }...
}
# review: new
done-copying = { $count ->
   *[other] A copiar { $messages } para { $folder }...
}
# review: new
done-moved-back = { $count ->
    [one] { $messages } devolvida a { $folder }
   *[other] { $messages } devolvidas a { $folder }
}
# the status bar after Watch Conversation and Ignore Conversation, and after either again on a marked one
# review: new
done-watched = { $count ->
    [one] A seguir a conversa
   *[other] A seguir { $count } conversas
}
# review: new
done-unwatched = { $count ->
    [one] Deixou de seguir a conversa
   *[other] Deixou de seguir { $count } conversas
}
# review: new
done-ignored = { $count ->
    [one] A ignorar a conversa
   *[other] A ignorar { $count } conversas
}
# review: new
done-unignored = { $count ->
    [one] Deixou de ignorar a conversa
   *[other] Deixou de ignorar { $count } conversas
}
# review: new
their-folders = as respetivas pastas
# review: new
undo-move = Anular mover
# review: new
undo-delete = Anular eliminar
# review: new
undo-archive = Anular arquivar
# review: new
undo-junk = Anular marcar como lixo
# review: new
undo-not-junk = Anular marcar como não lixo
# review: new
undo-send = Anular envio
# review: new
nothing-to-undo = Não há nada para anular.
# review: new
messages-gone = As mensagens já não existem.
# A non-selectable IMAP folder cannot contain messages; this does not mean it is empty.
# review: new
folder-holds-no-messages = Esta pasta não pode conter mensagens.
# review: new
not-archived-here = Não é possível arquivar as mensagens desta pasta.
# review: new
not-emptied-here = Só é possível esvaziar Itens Eliminados e Lixo Eletrónico.
# review: new
next-unread-question = Não há mais mensagens não lidas em { $folder }.

    Ir para { $next }, a próxima pasta com mensagens não lidas?
# review: new
no-unread-left = Não há mais mensagens não lidas.
# review: new
empty-question = { $count ->
    [one] Esvaziar { $folder }?

        A mensagem que contém será eliminada permanentemente. Não será possível recuperá-la.
   *[other] Esvaziar { $folder }?

        As { $messages } que contém serão eliminadas permanentemente. Não será possível recuperá-las.
}
# review: new
no-junk-folder = Esta conta não tem uma pasta Lixo Eletrónico para onde mover as mensagens.
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
   *[gray] cinzento
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
   *[gray] Cinzento
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
transfer-moving = A mover { $done } de { $messages } para { $folder }...
# review: new
transfer-copying = A copiar { $done } de { $messages } para { $folder }...
# review: new
transfer-another-account = outra conta
# review: new
transfer-folder-gone = a pasta de destino já não existe
# review: new
transfer-not-on-server = a mensagem já não está no servidor
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
export-not-in-time = não foi possível transferir a mensagem a tempo
# review: new
export-not-saved = Não foi possível guardar { $failed } de { $messages } ({ $problems })
# review: new
export-not-attached = não foi possível anexar as mensagens: { $error }
# the status bar after Save As with several: "Saved 3 messages to Desktop"
# review: new
saved-to = { $count ->
    [one] { $messages } guardada em { $folder }
   *[other] { $messages } guardadas em { $folder }
}
# review: new
download-progress = A transferir { $done } de { $total }
# review: new
download-done = Transferido: { $size }
# review: new
downloading-messages = { $count ->
   *[other] A transferir { $messages }...
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
error-closed = a encerrar
# review: new
error-other-account = o browser iniciou sessão em { $email }, não nesta conta
# a password or sign-in the mail server refused, with the server's words
# review: new
failure-authentication = o servidor não aceitou o início de sessão ({ $reason })
# the mail server could not be reached or the connection broke, with the reason
# review: new
failure-network = a ligação ao servidor falhou ({ $reason })
# review: new
error-in-use = não é possível removê-la enquanto houver contas que iniciam sessão com ela: { $accounts }
# review: new
error-turned-off = esta aplicação de início de sessão está desativada para contas novas
# review: new
error-folder-name = o nome da pasta tem de ter entre 1 e 200 carateres e não pode conter carateres de controlo
# review: new
error-folder-separator = neste servidor, o nome de uma pasta não pode conter «{ $separator }»
# review: new
error-folder-special = não é possível mudar o nome nem eliminar a Caixa de Entrada e as pastas especiais
# review: new
error-no-recipients = a mensagem não tem destinatários
# review: new
error-bad-address = «{ $address }» não é um endereço de e-mail
# review: new
error-not-own-address = { $address } não é um dos endereços de remetente desta conta. Adicione-o a «Outros endereços a partir dos quais envia» nas propriedades da conta.
# review: new
rule-query-refused = As regras não podem filtrar por pasta nem por data ({ $words }).
# review: new
rule-no-query = Introduza critérios de pesquisa para as mensagens recebidas.
# review: new
rule-no-action = Escolha pelo menos uma ação para a regra.
# review: new
error-attachment = não foi possível ler { $path }: { $error }
# review: new
error-no-drafts = a conta não tem uma pasta Rascunhos onde guardar a mensagem
# review: new
error-draft-attachment = não foi possível manter um anexo do rascunho: { $error }
# review: new
error-password-not-saved = não foi possível guardar a palavra-passe para o próximo arranque: { $error }
# review: new
error-sign-in-not-saved = não foi possível guardar os novos dados de início de sessão para o próximo arranque: { $error }
# review: new
error-import-unreadable = não é possível ler { $path }: { $error }
# review: new
error-import-too-large = { $path } tem mais de 50 MB
# review: new
error-import-not-mail = { $path } não é uma mensagem de e-mail
# review: new
error-list-answered = o servidor da lista de correio devolveu o estado { $status }
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
error-sent-no-copy = não foi possível guardar uma cópia em Enviados: { $reason }
# review: new
error-no-password = esta conta não tem palavra-passe
# review: new
error-no-sign-in = esta conta não tem início de sessão
# review: new
error-provider-missing = esta versão não consegue iniciar sessão em { $provider }: a aplicação de início de sessão foi removida?
# review: new
error-provider-servers = os servidores desta conta não correspondem aos servidores da sua aplicação de início de sessão
# review: new
error-app-scopes = { $reason }. O servidor de correio não aceitou o token da aplicação de início de sessão: verifique se as permissões (scopes) da aplicação dão acesso ao correio
# review: new
error-in-folder = { $folder }: { $reason }

## Sign-in apps

# review: new
sign-in-off-google = A Google ainda não verificou o Inbox Classic, por isso só deixa iniciar sessão com ele aos utilizadores de teste. Use a sua própria aplicação de início de sessão da Google ou uma palavra-passe de aplicação, ou ative-a em Aplicações de início de sessão (Ficheiro > Contas) se for um utilizador de teste.
# review: new
sign-in-off-other = Foi desativada em Aplicações de início de sessão (Ficheiro > Contas), onde pode ser ativada novamente.
# review: new
sign-in-app-no-name = a aplicação de início de sessão precisa de um nome
# review: new
sign-in-app-no-client = falta o ID de cliente
# review: new
sign-in-app-no-scopes = a aplicação de início de sessão precisa das permissões (scopes) que dão acesso ao correio
# review: new
sign-in-app-bad-host = o endereço do servidor { $server } está em falta ou não é um nome de anfitrião válido
# review: new
sign-in-app-plain = o servidor { $server } tem de usar SSL/TLS ou STARTTLS
# review: new
sign-in-app-not-checked = o emissor ainda não foi verificado
# review: new
sign-in-app-issuer-changed = o emissor mudou: escreva novamente o segredo de cliente, ou remova-o
# review: new
sign-in-register-google = Na Google Cloud Console, crie um cliente OAuth do tipo Desktop app, com o âmbito https://mail.google.com/ no ecrã de consentimento. Enquanto a aplicação estiver em teste, só os seus utilizadores de teste podem iniciar sessão.
# review: new
sign-in-register-microsoft = No Microsoft Entra, registe uma aplicação com a plataforma Mobile and desktop applications, o URI de redirecionamento http://localhost e os fluxos de cliente público permitidos, e as permissões delegadas IMAP.AccessAsUser.All, SMTP.Send e offline_access. Só para a sua organização, use https://login.microsoftonline.com/<tenant ID>/v2.0 como emissor.
# review: new
sign-in-register-other = Registe um cliente nativo (público) com o URI de redirecionamento abaixo; o fornecedor tem de permitir qualquer porta nele (RFC 8252). Adicione o âmbito com que o fornecedor dá acesso ao correio.

## Calendar invitations

# review: new
repeats = Repete-se
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
agent-level-read = Ler o correio: pastas, lista de mensagens, pesquisa e mensagens
# review: new
agent-level-organize = Organizar o correio: estado de leitura, sinalizadores, lixo, mover, eliminar para Itens Eliminados
# review: new
agent-level-drafts = Escrever rascunhos para enviar
# review: new
agent-level-send = Enviar correio, cada mensagem só depois de dizer que sim
# review: new
agent-connect-title = { $program } quer usar o seu correio
# review: new
agent-connect-detail = Um agente de IA pediu para trabalhar com o Inbox Classic. Escolha o que pode fazer e que contas pode ver; pode alterar isto mais tarde em Ferramentas > Agentes de IA.

    Os agentes leem correio escrito por outras pessoas, e uma mensagem pode tentar enganá-los. O Inbox Classic pergunta-lhe sempre antes de um agente enviar alguma coisa.
# review: new
agent-reply-to = Resposta a «{ $subject }»
# review: new
agent-reply-all-on = Resposta a todos em «{ $subject }»
# review: new
agent-forward-of = Reencaminhamento de «{ $subject }»
# review: new
agent-never-written-one = Nunca escreveu para { $address }.
# review: new
agent-never-written-many = Nunca escreveu para { $count } destes endereços.
# review: new
agent-send-title = { $program } quer enviar esta mensagem
# review: new
agent-send-detail = Verifique os destinatários e o conteúdo da mensagem. Depois de confirmar, a mensagem aguarda { $seconds } segundos na Caixa de Saída, onde ainda a pode eliminar.
# review: new
agent-change-title = O que { $program } pode fazer
# review: new
agent-change-allowed = Altere o que os agentes de IA deste programa podem fazer com o seu correio.
# review: new
agent-change-refused = Recusou o acesso a este programa. Permita-o para dar novamente aos seus agentes acesso ao seu correio.
# review: new
agent-log-taken-back = { $entry } (anulado)
# review: new
agent-files = Ficheiros: { $files }
# review: new
agent-undo-refused = Não é possível anular.
# review: new
agent-undo-refused-why = Não é possível anular: { $reason }.
# review: new
agent-undo-impossible = isto não pode ser anulado
# review: new
agent-undo-not-in-folder = a mensagem já não está nessa pasta
# review: new
agent-undo-not-arrived = a mensagem (ainda) não está na pasta para onde foi
# review: new
agent-undo-sent = a mensagem já foi enviada
# review: new
agent-original-not-downloaded = a mensagem original ainda não foi transferida. Abra-a primeiro
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
agent-can-send = enviar com o seu sim
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
agent-encrypted-original = Esta mensagem está encriptada: um agente não pode responder-lhe nem reencaminhá-la, porque não consegue encriptar.
# review: new
agent-encrypted = Esta mensagem está encriptada. Só o utilizador a pode ler, no Inbox Classic.
# review: new
list-encrypted = Mensagem encriptada
# review: new
agent-log-composed = Abriu «{ $subject }» numa nova mensagem para a terminar
# review: new
agent-log-refused = Não enviou «{ $subject }»
# review: new
agent-log-sent = Enviou «{ $subject }» para { $to }
# review: new
agent-log-draft = Guardou o rascunho «{ $subject }»
# review: new
agent-log-read = Marcou como lida «{ $subject }»
# review: new
agent-log-unread = Marcou como não lida «{ $subject }»
# review: new
agent-log-flagged = Sinalizou «{ $subject }»
# review: new
agent-log-unflagged = Removeu o sinalizador de «{ $subject }»
# review: new
agent-log-deleted = Eliminou «{ $subject }»
# review: new
agent-log-moved = Moveu «{ $subject }» para { $folder }
# review: new
agent-log-junk = Marcou «{ $subject }» como lixo
# review: new
agent-log-not-junk = Marcou «{ $subject }» como não lixo
# review: new
agent-log-archived = Arquivou «{ $subject }»
# review: new
agent-log-folder = Criou a pasta «{ $name }»
# review: new
agent-log-unsubscribed = Cancelou a subscrição da lista de «{ $subject }»

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
sign-in-no-refresh = o fornecedor não deu um token de atualização
# review: new
sign-in-no-account = o fornecedor não indicou que conta iniciou sessão
# review: new
sign-in-not-finished = o início de sessão não terminou
# review: new
secrets-unavailable = { $store } não está disponível
# review: new
secrets-unavailable-why = { $store } não está disponível: { $error }
# review: new
secrets-windows = o Gestor de Credenciais
# review: new
secrets-mac = o porta-chaves
# review: new
secrets-linux = o porta-chaves do sistema (Secret Service)
# review: new
error-no-such-file = o ficheiro não existe
# review: new
cards-file-too-big = Este ficheiro é demasiado grande para ser um livro de endereços.
# review: new
ui-sender-added = { $name } foi adicionado ao Livro de Endereços.
# review: new
ui-sender-known = { $name } já está no Livro de Endereços.
# review: new
ui-sender-none = O remetente desta mensagem não tem um endereço de e-mail para adicionar.
# review: new
card-name-needed = O contacto não tem nome nem endereço de e-mail.
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
otp-note = Introduza-o apenas numa página de { $domain }.
# review: new
otp-old = Este código foi enviado mais de uma hora antes de o abrir e provavelmente já expirou.

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
otp-notification = { $code } é o seu código para { $domain }

## OpenPGP keys (keys.rs)
# review: new
pgp-key-valid = Válida
# review: new
pgp-key-expires = Válida até { $date }
# review: new
pgp-key-expired = Expirou a { $date }
# review: new
pgp-key-revoked = Revogada
# review: new
pgp-key-revoked-why = Revogada: { $reason }
# review: new
pgp-key-not-valid = Não válida
# review: new
pgp-key-locked = Não pode ser usada: { $store } já não tem a chave que a protege. Importe novamente a cópia de segurança.
# review: new
pgp-source-own = Criada no Inbox Classic
# review: new
pgp-source-file = Importada de um ficheiro
# review: new
pgp-source-paste = Colada
# review: new
pgp-source-attachment = De uma mensagem
# review: new
pgp-source-vcard = De um cartão de contacto
# review: new
pgp-source-wkd = Do fornecedor de correio do remetente
# review: new
pgp-source-keyserver = De keys.openpgp.org
# review: new
pgp-source-autocrypt = Do cabeçalho Autocrypt de uma mensagem
# review: new
pgp-error-no-store = Não é possível usar { $store }, que protege as chaves privadas: { $error }
# review: new
pgp-error-wrong-passphrase = A frase de acesso não está correta.
# review: new
pgp-error-not-a-key = Isto não é uma chave OpenPGP.
# review: new
pgp-error-too-large = A chave é demasiado grande.
# review: new
pgp-error-unusable = A chave usa criptografia antiga ou fraca e não pode ser usada.
# review: new
pgp-imported-private = { $count ->
    [one] A sua chave privada foi importada.
   *[other] Foram importadas { $count } chaves privadas.
}
# review: new
pgp-imported-public = { $count ->
    [0] Não foi importada nenhuma chave.
    [one] Foi importada uma chave.
   *[other] Foram importadas { $count } chaves.
}
# review: new
pgp-imported-pending = Já é usada outra chave para { $addresses }: a nova aguarda no contacto até a escolher.
# review: new
pgp-error-needs-passphrase = A chave privada está protegida por uma frase de acesso. Escreva-a para importar a chave.
# review: new
pgp-error-mismatch = A chave privada não pertence à respetiva chave pública. Pode ter sido alterada.
# review: new
pgp-file-name-public = Chave pública de { $who }.asc
# review: new
pgp-file-name-private = Cópia de segurança da chave privada de { $who }.asc
# review: new
pgp-pending = Foi encontrada uma chave diferente para { $address } a { $date }.

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
pgp-part-encrypted = Encriptada. { $signature }
# review: new
pgp-part-no-key = Encriptada para uma chave que não tem
# review: new
pgp-part-changed = A parte encriptada foi alterada pelo caminho e não é mostrada
# review: new
pgp-part-unprotected = Encriptada sem proteção contra alterações, não é mostrada
# review: new
pgp-part-broken = Não é possível ler a parte encriptada
# review: new
pgp-why-mismatch = A assinatura não corresponde a este texto
# review: new
pgp-why-weak-hash = A assinatura usa { $hash }, que já não é seguro
# review: new
pgp-why-key-expired = Assinada depois de a chave ter expirado a { $date }
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
pgp-why-not-for-you = Assinada para outros destinatários e reencaminhada para si
# review: new
pgp-part-pictures-loaded = { $label }. Foram carregadas imagens da Internet
# review: new
pgp-error-no-own-key = Não tem nenhuma chave para { $address } com que assinar ou encriptar. Crie uma em Ferramentas > Chaves de encriptação, ou desative Assinar e Encriptar.
# review: new
pgp-error-missing-keys = { $count ->
    [one] { $addresses } não tem nenhuma chave para a qual encriptar.
   *[other] Estes destinatários não têm nenhuma chave para a qual encriptar: { $addresses }.
}
# review: new
pgp-error-encrypted-quote = Esta mensagem cita ou reencaminha uma mensagem encriptada, por isso só pode ser enviada encriptada. Ative Encriptar, ou remova o texto citado.
# review: new
pgp-error-protect = Não foi possível assinar ou encriptar a mensagem: { $reason }
# review: new
pgp-found-keys = Foi encontrada a chave de { $addresses }.
# review: new
pgp-found-none = Não foi encontrada nenhuma chave para { $addresses }. Peça-lhes que lhe enviem a respetiva chave pública.
# review: new
pgp-found-no-key = Não foi encontrada nenhuma chave.
# review: new
pgp-find-unavailable = Não foi possível procurar chaves agora: { $error }
# review: new
pgp-publish-pending = keys.openpgp.org enviou uma ligação de confirmação para { $addresses }. A sua chave fica publicada lá depois de clicar nela.
# review: new
pgp-publish-done = A sua chave está publicada em keys.openpgp.org para { $addresses }.
# review: new
pgp-publish-failed = Não foi possível publicar a chave: { $error }
# review: changed
pgp-keyserver-off = A procura de chaves em keys.openpgp.org está desativada em { $settings }.
# review: new
pgp-keyserver-off = A procura de chaves em keys.openpgp.org está desativada em Opções.
# the compose window with Sign and Encrypt: the line under the fields, each recipient's key, the questions
# review: new
pgp-compose-encrypted = { $count ->
    [one] Encriptada e assinada: só pode ser lida por si e por { $addresses }.
   *[other] Encriptada e assinada: só pode ser lida por si e pelos { $count } destinatários.
}
# review: new
pgp-compose-encrypt-ready = Vai ser encriptada e assinada. Adicione destinatários cujas chaves tenha.
# review: new
pgp-compose-missing = { $count ->
    [one] { $addresses } não tem nenhuma chave, por isso a mensagem ainda não pode ser encriptada.
   *[other] { $count } destinatários não têm nenhuma chave, por isso a mensagem ainda não pode ser encriptada: { $addresses }.
}
# review: new
pgp-compose-looking = A procurar as chaves de { $addresses }...
# review: new
pgp-compose-signed = Assinada: os destinatários podem verificar que vem de si e que não foi alterada.
# review: new
pgp-compose-reply-clear = Não encriptada, embora a mensagem a que responde ou que reencaminha estivesse encriptada.
# review: new
pgp-compose-encrypted-files = Estão anexados ficheiros de uma mensagem encriptada, por isso esta mensagem só pode ser enviada encriptada. Ative Encriptar, ou remova esses ficheiros.
# review: new
pgp-compose-sign-tip = Assinar a mensagem com a sua chave, para que os destinatários possam verificar que vem de si e que não foi alterada
# review: new
pgp-compose-sign-tip-encrypted = Uma mensagem encriptada é sempre assinada
# review: new
pgp-compose-encrypt-tip = Encriptar a mensagem, para que só possa ser lida por si e pelos destinatários
# review: new
pgp-compose-make-key = Ainda não tem nenhuma chave para { $address }. Criar uma agora? Com ela, as suas mensagens podem ser assinadas e encriptadas.
# review: new
pgp-compose-key-unusable = A sua chave para { $address } não pode ser usada ({ $state }). Abra Chaves de encriptação para importar a cópia de segurança ou criar uma chave nova.
# review: new
pgp-compose-encrypt-off-quote = Esta mensagem cita ou reencaminha uma mensagem encriptada. Sem encriptação, só pode ser enviada depois de remover o que cita. Desativar a encriptação mesmo assim?
# review: new
pgp-compose-encrypt-off-reply = Esta mensagem responde a uma mensagem encriptada ou reencaminha-a. Sem encriptação, qualquer pessoa que trate a sua mensagem pelo caminho pode lê-la. Desativar a encriptação?
# review: new
pgp-recipient-verified = Chave verificada
# review: new
pgp-recipient-found = Chave não verificada
# review: new
pgp-recipient-own = A sua própria chave
# review: new
pgp-recipient-looking = A procurar uma chave...
# review: new
pgp-recipient-missing = Sem chave
# review: new
pgp-recipient-not-found = Sem chave: não foi encontrada nenhuma a { $date }
# review: new
pgp-recipient-unusable = A chave não pode ser usada: { $state }
# review: new
pgp-recipients-intro = A mensagem é encriptada para a chave de cada destinatário e para a sua.
# review: new
pgp-recipients-intro-missing = { $count ->
    [one] Um destinatário não tem nenhuma chave para a qual encriptar. Procure a chave dele, remova-o desta mensagem ou envie-a sem encriptação.
   *[other] { $count } destinatários não têm nenhuma chave para a qual encriptar. Procure as chaves deles, remova-os desta mensagem ou envie-a sem encriptação.
}
# review: new
pgp-details-part = Parte { $number }: { $label }
# review: new
pgp-details-signed = Assinada { $when } com a chave { $key }
# review: new
pgp-details-unknown-key = Assinada com a chave { $key }, que não tem
# review: new
pgp-details-opened = Encriptada para a sua chave { $key }
# review: new
pgp-details-for = Encriptada para { $keys }
# review: new
pgp-details-plain = Não assinada e não encriptada
# review: new
pgp-bar-parts = Esta mensagem tem { $count } partes: { $list }. Cada parte indica como está protegida.
# review: new
pgp-bar-count-verified = { $count ->
    [one] { $count } verificada
   *[other] { $count } verificadas
}
# review: new
pgp-bar-count-good = { $count ->
    [one] { $count } assinada ou encriptada
   *[other] { $count } assinadas ou encriptadas
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
setup-part-settings = Definições
# review: new
setup-part-preferences = Preferências das janelas
# review: new
setup-part-accounts = Contas
# review: new
setup-part-sign-in-apps = Aplicações de início de sessão
# review: new
setup-part-contacts = Contactos e grupos
# review: new
setup-part-keys = Chaves de encriptação
# review: new
setup-part-rules = Regras de mensagens
# review: new
setup-part-trusted-senders = Remetentes fidedignos
# review: new
setup-holds-settings = { $count ->
    [0] 0 definições
    [one] { $count } definição
   *[other] { $count } definições
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
    [0] 0 aplicações de início de sessão
    [one] { $count } aplicação de início de sessão
   *[other] { $count } aplicações de início de sessão
}
# review: new
setup-holds-built-in = Que aplicações de início de sessão integradas estão ativadas
# review: new
setup-holds-contacts = { $count ->
    [0] 0 contactos
    [one] { $count } contacto
   *[other] { $count } contactos
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
    [0] 0 chaves de contactos
    [one] { $count } chave de um contacto
   *[other] { $count } chaves de contactos
}
# review: new
setup-holds-rules = { $count ->
    [0] 0 regras
    [one] { $count } regra
   *[other] { $count } regras
}
# review: new
setup-holds-trusted-senders = { $count ->
    [0] 0 remetentes fidedignos
    [one] { $count } remetente fidedigno
   *[other] { $count } remetentes fidedignos
}
# review: new
setup-sign-in-password = Palavra-passe
# review: new
setup-account-secret-password = A palavra-passe está no ficheiro.
# review: new
setup-account-secret-token = O início de sessão está no ficheiro.
# review: new
setup-account-asks-password = Pede a palavra-passe depois da importação.
# review: new
setup-account-signs-in-again = Inicia sessão novamente depois da importação.
# review: new
setup-account-here = Já está configurada aqui, por isso é ignorada.
# review: new
setup-account-no-app = Inicia sessão com { $app }, que não está configurada aqui. Importe também as aplicações de início de sessão.
# review: new
setup-invalid-address = «{ $address }» não é um endereço de e-mail.
# review: new
setup-invalid-server = O servidor { $server } não tem um nome ou uma porta utilizáveis.
# review: new
setup-invalid-user = Não tem nome de utilizador.
# review: new
setup-invalid-sign-in = Inicia sessão de uma forma que o Inbox Classic não conhece.
# review: new
setup-error-empty = O ficheiro está vazio.
# review: new
setup-error-too-large = O ficheiro é demasiado grande para ser uma configuração do Inbox Classic.
# review: new
setup-error-not-setup = Este ficheiro não é uma configuração do Inbox Classic.
# review: new
setup-error-damaged = O ficheiro de configuração está danificado e não pode ser lido.
# review: new
setup-error-newer = Esta configuração foi guardada por uma versão mais recente do Inbox Classic ({ $version }). Atualize o Inbox Classic e importe-a novamente.
# review: new
setup-error-needs-passphrase = Esta configuração está protegida por uma frase de acesso. Escreva a frase de acesso com que foi guardada.
# review: new
setup-error-wrong-passphrase = Essa não é a frase de acesso com que esta configuração foi guardada.
# review: new
setup-error-changed = O ficheiro de configuração foi alterado ou danificado depois de ser guardado, por isso não pode ser importado.
# review: new
setup-error-read = Não foi possível ler o ficheiro de configuração: { $error }
# review: new
setup-error-write = Não foi possível guardar a configuração: { $error }
# review: new
setup-error-no-parts = Escolha pelo menos uma parte.
# review: new
setup-left-out = { $count ->
    [one] { $count } entrada de { $part } não pode ser usada e fica de fora.
   *[other] { $count } entradas de { $part } não podem ser usadas e ficam de fora.
}
# review: new
setup-imported-settings = As definições foram substituídas.
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
setup-skipped-no-app = { $address } foi ignorada: inicia sessão com { $app }, que não está configurada aqui.
# review: new
setup-skipped-invalid = { $address } foi ignorada: { $reason }
# review: new
setup-asks-password = { $address } pede a palavra-passe quando se ligar.
# review: new
setup-signs-in-again = { $address } pede-lhe para iniciar sessão novamente quando se ligar.
# review: new
setup-added-sign-in-apps = { $count ->
    [one] Foi adicionada { $count } aplicação de início de sessão.
   *[other] Foram adicionadas { $count } aplicações de início de sessão.
}
# review: new
setup-skipped-sign-in-apps = { $count ->
    [one] { $count } aplicação de início de sessão já está configurada aqui.
   *[other] { $count } aplicações de início de sessão já estão configuradas aqui.
}
# review: new
setup-added-contacts = { $count ->
    [one] Foi adicionado { $count } contacto ao livro de endereços.
   *[other] Foram adicionados { $count } contactos ao livro de endereços.
}
# review: new
setup-skipped-contacts = { $count ->
    [one] { $count } contacto já está no livro de endereços.
   *[other] { $count } contactos já estão no livro de endereços.
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
    [one] Foi adicionada { $count } chave de um contacto.
   *[other] Foram adicionadas { $count } chaves de contactos.
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
    [one] { $count } regra de mensagens move mensagens para uma pasta que aparece quando a respetiva conta sincronizar.
   *[other] { $count } regras de mensagens movem mensagens para pastas que aparecem quando as respetivas contas sincronizarem.
}
# review: new
setup-added-trusted-senders = { $count ->
    [one] Foi adicionado { $count } remetente fidedigno.
   *[other] Foram adicionados { $count } remetentes fidedignos.
}
# review: new
setup-nothing = Não foi importado nada.
# review: new
setup-account-servers = { $imap } e { $smtp } ({ $signin })
# review: new
setup-file-name = Definições e contas do Inbox Classic
# review: new
setup-skipped-unreachable = { $name } foi ignorada: não foi possível contactar o respetivo serviço de início de sessão. Adicione-a novamente em Aplicações de início de sessão.
# review: new
attachment-runs-programs = «{ $name }» pode executar programas, por isso o Inbox Classic não o abre. Guarde-o e, se confiar na sua origem, abra-o por sua conta.
# review: new
attachment-decrypted-note = Este anexo provém de uma mensagem encriptada. Para o abrir, o Inbox Classic guarda-o desencriptado neste computador, numa pasta sua que o Inbox Classic esvazia ao fim de um dia.
# a bar over the list when the server did not do what the user asked of messages, so they are as they were again
# review: new
undone-move = { $count ->
    [one] O servidor não moveu { $messages } para { $folder }, por isso está de novo em { $from }: { $reason }
   *[other] O servidor não moveu { $messages } para { $folder }, por isso estão de novo em { $from }: { $reason }
}
# review: new
undone-delete = { $count ->
    [one] O servidor não eliminou { $messages }, por isso está de novo em { $from }: { $reason }
   *[other] O servidor não eliminou { $messages }, por isso estão de novo em { $from }: { $reason }
}
# review: new
undone-archive = { $count ->
    [one] O servidor não arquivou { $messages }, por isso está de novo em { $from }: { $reason }
   *[other] O servidor não arquivou { $messages }, por isso estão de novo em { $from }: { $reason }
}
# review: new
undone-read = { $count ->
    [one] O servidor não marcou { $messages } como lida, por isso está de novo por ler: { $reason }
   *[other] O servidor não marcou { $messages } como lidas, por isso estão de novo por ler: { $reason }
}
# review: new
undone-unread = { $count ->
    [one] O servidor não marcou { $messages } como não lida, por isso está de novo lida: { $reason }
   *[other] O servidor não marcou { $messages } como não lidas, por isso estão de novo lidas: { $reason }
}
# review: new
undone-flags = { $count ->
    [one] O servidor não alterou os sinalizadores de { $messages }, por isso está como estava: { $reason }
   *[other] O servidor não alterou os sinalizadores de { $messages }, por isso estão como estavam: { $reason }
}
