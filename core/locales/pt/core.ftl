# What the core says, the same on every platform. Placeables in { $braces } are filled in by the code; keep them, in
# the place the language puts them. Plurals choose by the number: [one] and *[other] in English, the forms your
# language has in yours.
# Português europeu. Rascunho, à espera de revisão por um falante nativo. As regras de plural de "pt" contam o 0 como
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
list-counts = { $messages }, { $unread } por ler
list-counts-selected = { $messages }, { $unread } por ler, { $selected } selecionadas
# the status bar while searching: "12 found, 3 unread"
list-counts-found = { $found ->
    [one] { $found } encontrada
   *[other] { $found } encontradas
    }, { $unread } por ler
list-counts-found-selected = { $found } encontradas, { $unread } por ler, { $selected } selecionadas
list-counts-none = Não foram encontradas mensagens

## Special folders, as Outlook Express names them

folder-inbox = Caixa de Entrada
folder-sent = Itens Enviados
folder-deleted = Itens Eliminados
folder-drafts = Rascunhos
folder-junk = Lixo Eletrónico
folder-archive = Arquivo

## The reading pane

reader-no-message = Não há nenhuma mensagem selecionada.
reader-downloading = A transferir a mensagem…
reader-downloading-detail = A mensagem aparecerá aqui quando a transferência terminar.
reader-downloading-size = A mensagem tem { $size }. Aparecerá aqui quando a transferência terminar.
reader-failed = Não foi possível transferir a mensagem
reader-failed-network = Não foi possível contactar o servidor de correio ({ $reason }).
reader-failed-sign-in = O servidor de correio não aceitou o início de sessão ({ $reason }). Verifique a palavra-passe ou inicie sessão novamente em Ficheiro > Contas.
reader-failed-security = Não foi possível tornar segura a ligação ao servidor de correio ({ $reason }).
reader-failed-other = O servidor de correio respondeu: { $reason }.
reader-retry-note = A transferência será repetida quando a conta voltar a ligar-se ao servidor.
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

bounce-failed = A sua mensagem não foi entregue
bounce-delayed = A sua mensagem ainda não foi entregue
bounce-delayed-note = O seu servidor de correio ainda está a tentar entregá-la. Não precisa de a enviar novamente.
# the link to the message the notice is about, in Sent Items or another folder
bounce-show-message = Mostrar a mensagem devolvida
# the link of a delay's card to the message that is still on its way
bounce-show-delayed = Mostrar a mensagem atrasada
bounce-what-to-do = O que pode fazer:
# what to do about a recipient the message is still on its way to: in the card of a delay, and in the card of a failure
bounce-delayed-do = Aguarde. Se continuar a não ser possível entregar a mensagem, receberá outro aviso.
bounce-delayed-row-do = Aguarde. O seu servidor de correio ainda está a tentar entregar a mensagem. Receberá outro aviso se não conseguir.
# folds the receiving server's own words
bounce-details = Detalhes
# a recipient the notice does not name
bounce-someone = Um destinatário
# in Details: the server that refused the message, the status code it gave, and the server that wrote the notice
bounce-server = Servidor: { $server }
bounce-status = Estado: { $status }
bounce-reported-by = Comunicado por: { $server }
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
bounce-user-unknown-why = O servidor de destino não tem nenhuma caixa de correio com este endereço. Pode ter sido mal escrito, ou a pessoa pode já não o usar.
bounce-user-unknown-do = Verifique se o endereço está escrito corretamente ou peça ao destinatário o endereço que utiliza atualmente.
bounce-invalid-address = O endereço não é válido
bounce-invalid-address-why = O formato do endereço não é válido para enviar correio.
bounce-invalid-address-do = Verifique se há erros, como espaços, letras em falta ou ausência do domínio depois de @.
bounce-mailbox-disabled = A caixa de correio está desativada
bounce-mailbox-disabled-why = O endereço existe, mas a caixa de correio foi desativada ou já não é usada.
bounce-mailbox-disabled-do = Contacte a pessoa de outra forma e peça-lhe um endereço que use agora.
bounce-mailbox-full = A caixa de correio está cheia
bounce-mailbox-full-why = A caixa de correio do destinatário não tem espaço para correio novo.
bounce-mailbox-full-do = Envie-a novamente daqui a alguns dias, ou avise a pessoa de outra forma. Os anexos grandes são os primeiros a ser recusados.
bounce-spam-blocked = Recusada como lixo eletrónico
bounce-spam-blocked-why = O servidor de destino classificou a mensagem como lixo eletrónico.
bounce-spam-blocked-do = Experimente enviar a mensagem com menos ligações, sem ligações encurtadas ou sem anexos grandes. Se o problema persistir, contacte o seu fornecedor de correio.
bounce-virus-detected = Recusada por deteção de vírus
bounce-virus-detected-why = O servidor de destino encontrou um vírus ou outro conteúdo nocivo na mensagem ou nos anexos.
bounce-virus-detected-do = Verifique os anexos com um antivírus. Alguns servidores recusam programas ou ficheiros comprimidos. Nesse caso, partilhe-os através de uma ligação.
bounce-ip-blocklisted = O seu servidor de correio está numa lista de bloqueio
bounce-ip-blocklisted-why = O servidor de destino recusa mensagens do seu servidor de envio porque o endereço desse servidor consta de uma lista de bloqueio.
bounce-ip-blocklisted-do = O problema está no servidor, não na mensagem. Reencaminhe este aviso para o seu fornecedor de correio e peça-lhe que solicite a remoção do servidor da lista.
bounce-domain-blocklisted = Um domínio está numa lista de bloqueio
bounce-domain-blocklisted-why = O servidor de destino recusa a mensagem porque o domínio do seu endereço, ou um domínio das ligações da mensagem, está numa lista de bloqueio.
bounce-domain-blocklisted-do = Se a mensagem tiver ligações, experimente enviá-la sem elas. Caso contrário, reencaminhe este aviso para quem gere o correio do seu domínio.
bounce-policy-blocked = Recusada pelas regras do servidor de destino
bounce-policy-blocked-why = As regras do servidor de destino impedem a entrega desta mensagem, por exemplo devido ao tamanho, aos anexos ou ao remetente.
bounce-policy-blocked-do = A resposta original do servidor, em Detalhes, costuma indicar o motivo. Pergunte ao destinatário se pode receber este tipo de mensagem.
bounce-geo-blocked = Recusada por causa da origem
bounce-geo-blocked-why = O servidor de destino não aceita correio do país ou da rede onde está o seu servidor de correio.
bounce-geo-blocked-do = Contacte a pessoa de outra forma, ou pergunte ao seu fornecedor de correio.
bounce-relay-denied = O servidor não a reencaminhou
bounce-relay-denied-why = Um servidor recusou-se a entregar a mensagem, muitas vezes porque foi enviada sem iniciar sessão ou através de um servidor que não trata deste destinatário.
bounce-relay-denied-do = Em Ficheiro > Contas, verifique o servidor de envio e confirme que a conta está configurada para se autenticar nesse servidor.
bounce-auth-failure = Não foi possível verificar o seu endereço de remetente
bounce-auth-failure-why = O servidor de destino não conseguiu confirmar que a mensagem veio realmente do seu domínio (SPF, DKIM ou DMARC).
bounce-auth-failure-do = Reencaminhe este aviso para quem gere o correio do seu domínio: as definições precisam de ser corrigidas. Entretanto, enviar através do servidor do seu fornecedor pode ajudar.
bounce-rate-limited = Demasiado correio de uma vez
bounce-rate-limited-why = Por agora, o servidor de destino aceita menos mensagens do seu servidor de correio.
bounce-rate-limited-do = Aguarde um pouco e envie-a novamente. Quando escrever a muitas pessoas, envie a menos de cada vez.
bounce-greylisting = Retida por momentos
bounce-greylisting-why = O servidor de destino pede aos remetentes desconhecidos que tentem novamente um pouco mais tarde, uma verificação comum contra o spam.
bounce-greylisting-do = Aguarde. Os servidores de correio repetem a tentativa automaticamente e a mensagem costuma ser entregue dentro de uma hora.
bounce-server-error = O servidor de destino teve um problema
bounce-server-error-why = Não foi possível contactar o servidor de destino, ou este não conseguiu aceitar a mensagem por causa de um problema próprio.
bounce-server-error-do = Envie-a novamente mais tarde. Se continuar a falhar, procure erros de escrita na parte do endereço depois do @.
bounce-unknown = Não entregue
bounce-unknown-why = O aviso não indica claramente o motivo.
bounce-unknown-do = A resposta original do servidor, em Detalhes, pode ajudar a identificar o problema. Se não for suficiente, reencaminhe este aviso para o seu fornecedor de correio.

## Several messages selected

selection-title = { $count ->
    [one] { $count } mensagem selecionada
   *[other] { $count } mensagens selecionadas
}
selection-unread = { $count ->
    [one] { $count } não lida
   *[other] { $count } não lidas
}
selection-flagged = { $count ->
    [one] { $count } sinalizada
   *[other] { $count } sinalizadas
}
delete-for-good-one = Esta mensagem será eliminada permanentemente. Eliminá-la?
delete-for-good-all = Estas { $count } mensagens serão eliminadas permanentemente. Eliminá-las?
delete-for-good-some = { $count ->
    [one] Das { $total } mensagens, { $count } será eliminada permanentemente. Eliminar as mensagens?
   *[other] Das { $total } mensagens, { $count } serão eliminadas permanentemente. Eliminar as mensagens?
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
    [one] { $messages } eliminada permanentemente
   *[other] { $messages } eliminadas permanentemente
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
   *[other] A mover { $messages } para { $folder }...
}
done-copying = { $count ->
   *[other] A copiar { $messages } para { $folder }...
}
done-moved-back = { $count ->
    [one] { $messages } movida de volta para { $folder }
   *[other] { $messages } movidas de volta para { $folder }
}
# the status bar after Watch Conversation and Ignore Conversation, and after either again on a marked one
done-watched = { $count ->
    [one] A seguir a conversa
   *[other] A seguir { $count } conversas
}
done-unwatched = { $count ->
    [one] Deixou de seguir a conversa
   *[other] Deixou de seguir { $count } conversas
}
done-ignored = { $count ->
    [one] A ignorar a conversa
   *[other] A ignorar { $count } conversas
}
done-unignored = { $count ->
    [one] Deixou de ignorar a conversa
   *[other] Deixou de ignorar { $count } conversas
}
their-folders = as respetivas pastas
undo-move = Anular movimento
undo-delete = Anular eliminação
undo-archive = Anular arquivamento
undo-junk = Anular marcação como lixo eletrónico
undo-not-junk = Anular marcação como correio legítimo
undo-send = Anular envio
nothing-to-undo = Não há nada para anular.
messages-gone = As mensagens já não estão disponíveis.
# A non-selectable IMAP folder cannot contain messages; this does not mean it is empty.
folder-holds-no-messages = Esta pasta não pode conter mensagens.
not-archived-here = Não é possível arquivar as mensagens desta pasta.
not-emptied-here = Só é possível esvaziar Itens Eliminados e Lixo Eletrónico.
next-unread-question = Não há mais mensagens não lidas em { $folder }.

    Ir para { $next }, a próxima pasta com mensagens não lidas?
no-unread-left = Não há mais mensagens não lidas.
empty-question = { $count ->
    [one] Esvaziar { $folder }?

        A mensagem que contém será eliminada permanentemente. Não será possível recuperá-la.
   *[other] Esvaziar { $folder }?

        As { $messages } que contém serão eliminadas permanentemente. Não será possível recuperá-las.
}
no-junk-folder = Esta conta não tem uma pasta Lixo Eletrónico para onde mover as mensagens.
no-inbox-folder = Esta conta não tem uma pasta Caixa de Entrada para onde mover as mensagens.
# the status bar after a flag in a colour: "Flagged 2 messages blue"
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

transfer-moving = A mover { $done } de { $messages } para { $folder }...
transfer-copying = A copiar { $done } de { $messages } para { $folder }...
transfer-another-account = outra conta
transfer-folder-gone = a pasta de destino já não existe
transfer-not-on-server = a mensagem já não está no servidor
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

export-not-in-time = não foi possível transferir a mensagem a tempo
export-not-saved = Não foi possível guardar { $failed } de { $messages } ({ $problems })
export-not-attached = não foi possível anexar as mensagens: { $error }
# the status bar after Save As with several: "Saved 3 messages to Desktop"
saved-to = { $count ->
    [one] { $messages } guardada em { $folder }
   *[other] { $messages } guardadas em { $folder }
}
download-progress = A transferir { $done } de { $total }
download-done = Transferência concluída: { $size }
downloading-messages = { $count ->
   *[other] A transferir { $messages }...
}
# the status bar after files are dropped on a folder: "Put 3 messages in Archive"
import-put = { $count ->
    [one] { $messages } importada para { $folder }
   *[other] { $messages } importadas para { $folder }
}
import-not-put = Não foi possível importar as seguintes mensagens para a pasta:

    { $problems }

## Problems the windows show

error-store = base de dados local: { $error }
error-not-found = não encontrado
error-closed = a encerrar
error-other-account = o browser iniciou sessão em { $email }, não nesta conta
# a password or sign-in the mail server refused, with the server's words
failure-authentication = o servidor não aceitou o início de sessão ({ $reason })
# the mail server could not be reached or the connection broke, with the reason
failure-network = a ligação ao servidor falhou ({ $reason })
error-in-use = não é possível removê-la enquanto houver contas que iniciam sessão com ela: { $accounts }
error-turned-off = esta aplicação de início de sessão está desativada para contas novas
error-folder-name = o nome da pasta tem de ter entre 1 e 200 carateres e não pode conter carateres de controlo
error-folder-separator = neste servidor, o nome de uma pasta não pode conter «{ $separator }»
error-folder-special = não é possível mudar o nome nem eliminar a Caixa de Entrada e as pastas especiais
error-no-recipients = a mensagem não tem destinatários
error-bad-address = «{ $address }» não é um endereço de e-mail
error-not-own-address = { $address } não é um dos endereços de remetente desta conta. Adicione-o a «Outros endereços a partir dos quais envia» nas propriedades da conta.
rule-query-refused = As regras não podem filtrar por pasta nem por data ({ $words }).
rule-no-query = Introduza critérios de pesquisa para as mensagens recebidas.
rule-no-action = Escolha pelo menos uma ação para a regra.
error-attachment = não foi possível ler { $path }: { $error }
error-no-drafts = a conta não tem uma pasta Rascunhos onde guardar a mensagem
error-draft-attachment = não foi possível guardar um anexo do rascunho: { $error }
error-password-not-saved = não foi possível guardar a palavra-passe para a próxima sessão: { $error }
error-sign-in-not-saved = não foi possível guardar as novas credenciais de início de sessão para a próxima sessão: { $error }
error-import-unreadable = não é possível ler { $path }: { $error }
error-import-too-large = { $path } tem mais de 50 MB
error-import-not-mail = { $path } não é uma mensagem de e-mail
error-list-answered = o servidor da lista de correio devolveu o estado { $status }
error-not-built = não foi possível criar a mensagem
error-outbox-waits = { $count ->
    [one] a mensagem aguarda na Caixa de Saída e será enviada no próximo Enviar/Receber
   *[other] { $count } mensagens aguardam na Caixa de Saída e serão enviadas no próximo Enviar/Receber
}
error-draft-not-removed = não foi possível remover o rascunho anterior da mensagem de Rascunhos: { $reason }
error-sent-but = a mensagem foi enviada, mas { $problem }
error-sent-still-in-outbox = continua na Caixa de Saída: { $error }
error-sent-no-copy = não foi possível guardar uma cópia em Itens Enviados: { $reason }
error-no-password = não existe uma palavra-passe guardada para esta conta
error-no-sign-in = não existem credenciais de início de sessão para esta conta
error-provider-missing = esta versão não consegue iniciar sessão em { $provider }: a aplicação de início de sessão foi removida?
error-provider-servers = os servidores desta conta não correspondem aos servidores da sua aplicação de início de sessão
error-app-scopes = { $reason }. O servidor de correio não aceitou o token da aplicação de início de sessão: verifique se as permissões (scopes) da aplicação dão acesso ao correio
error-in-folder = { $folder }: { $reason }

## Sign-in apps

sign-in-off-google = A Google ainda não verificou o Inbox Classic, por isso só deixa iniciar sessão com ele aos utilizadores de teste. Use a sua própria aplicação de início de sessão da Google ou uma palavra-passe de aplicação, ou ative-a em Aplicações de início de sessão (Ficheiro > Contas) se for um utilizador de teste.
sign-in-off-other = Foi desativada em Aplicações de início de sessão (Ficheiro > Contas), onde pode ser ativada novamente.
sign-in-app-no-name = a aplicação de início de sessão precisa de um nome
sign-in-app-no-client = falta o ID do cliente
sign-in-app-no-scopes = a aplicação de início de sessão precisa das permissões (scopes) que dão acesso ao correio
sign-in-app-bad-host = o endereço do servidor { $server } está em falta ou não é um nome de anfitrião válido
sign-in-app-plain = o servidor { $server } tem de usar SSL/TLS ou STARTTLS
sign-in-app-not-checked = o emissor ainda não foi verificado
sign-in-app-issuer-changed = o emissor foi alterado: introduza novamente o segredo do cliente ou remova-o
sign-in-register-google = Na Google Cloud Console, crie um cliente OAuth do tipo Desktop app. No ecrã de consentimento, adicione a permissão (scope) https://mail.google.com/. Enquanto a aplicação estiver em teste, só os utilizadores de teste podem iniciar sessão.
sign-in-register-microsoft = No Microsoft Entra, registe uma aplicação com a plataforma Mobile and desktop applications, o URI de redirecionamento http://localhost e os fluxos de cliente público permitidos, e as permissões delegadas IMAP.AccessAsUser.All, SMTP.Send e offline_access. Só para a sua organização, use https://login.microsoftonline.com/<tenant ID>/v2.0 como emissor.
sign-in-register-other = Registe um cliente nativo (público) com o URI de redirecionamento indicado abaixo. O fornecedor tem de permitir qualquer porta nesse endereço (RFC 8252). Adicione a permissão (scope) que o fornecedor exige para aceder ao correio.

## Calendar invitations

repeats = Repete-se
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

agent-level-read = Ler o correio: pastas, lista de mensagens, pesquisa e mensagens
agent-level-organize = Organizar o correio: alterar o estado de leitura e os sinalizadores, gerir o lixo eletrónico, mover e arquivar mensagens, criar pastas, eliminar mensagens (movendo-as para Itens Eliminados) e cancelar subscrições de listas de correio com a sua autorização
agent-level-drafts = Escrever rascunhos para que os possa enviar
agent-level-send = Enviar correio, com a sua confirmação para cada mensagem
agent-connect-title = { $program } quer usar o seu correio
agent-connect-detail = Um agente de IA pediu acesso ao Inbox Classic. Escolha as ações permitidas e as contas a que pode aceder. Pode alterar estas permissões em Ferramentas > Agentes de IA.

    Os agentes leem mensagens escritas por outras pessoas, que podem conter instruções enganosas. O Inbox Classic pede sempre a sua confirmação antes de um agente enviar correio.
agent-reply-to = Resposta a «{ $subject }»
agent-reply-all-on = Resposta a todos em «{ $subject }»
agent-forward-of = Reencaminhamento de «{ $subject }»
agent-never-written-one = Nunca escreveu para { $address }.
agent-never-written-many = Nunca escreveu para { $count } destes endereços.
agent-send-title = { $program } quer enviar esta mensagem
agent-send-detail = Verifique os destinatários e o conteúdo da mensagem. Depois de confirmar, a mensagem aguarda { $seconds } segundos na Caixa de Saída, onde ainda a pode eliminar.
agent-change-title = O que { $program } pode fazer
agent-change-allowed = Altere o que os agentes de IA deste programa podem fazer com o seu correio.
agent-change-refused = O acesso deste programa foi recusado. Autorize-o para permitir que os respetivos agentes acedam ao seu correio.
agent-log-taken-back = { $entry } (anulado)
agent-files = Ficheiros: { $files }
agent-undo-refused = Não é possível anular.
agent-undo-refused-why = Não é possível anular: { $reason }.
agent-undo-impossible = isto não pode ser anulado
agent-undo-not-in-folder = a mensagem já não está nessa pasta
agent-undo-not-arrived = a mensagem ainda não chegou à pasta de destino
agent-undo-sent = a mensagem já não está na Caixa de Saída
agent-original-not-downloaded = a mensagem original ainda não foi transferida. Abra-a primeiro
agent-turned-away = Recusado
agent-can-nothing = Nada
agent-can-read = ler
agent-can-organize = organizar
agent-can-drafts = escrever rascunhos
agent-can-send = enviar com a sua confirmação
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
agent-encrypted-original = Esta mensagem está encriptada: um agente não pode responder-lhe nem reencaminhá-la, porque não consegue encriptar.
agent-encrypted = Esta mensagem está encriptada. Os agentes de IA não podem ler o seu conteúdo. O utilizador tem de a abrir no Inbox Classic.
list-encrypted = Mensagem encriptada
agent-log-composed = Abriu «{ $subject }» numa janela de composição para que possa terminar a mensagem
agent-log-refused = Não enviou «{ $subject }»
agent-log-sent = Colocou «{ $subject }» em espera para envio a { $to }
agent-log-draft = Guardou o rascunho «{ $subject }»
agent-log-draft-replaced = Substituiu o rascunho «{ $subject }»
agent-log-draft-discarded = Eliminou o rascunho «{ $subject }»
agent-draft-note = { $program }, um agente de IA, escreveu este rascunho. Verifique os destinatários e o texto antes de o enviar.
agent-log-read = Marcou como lida «{ $subject }»
agent-log-unread = Marcou como não lida «{ $subject }»
agent-log-flagged = Sinalizou «{ $subject }»
agent-log-unflagged = Removeu o sinalizador de «{ $subject }»
agent-log-deleted = Eliminou «{ $subject }»
agent-log-moved = Moveu «{ $subject }» para { $folder }
agent-log-junk = Marcou «{ $subject }» como lixo eletrónico
agent-log-not-junk = Marcou «{ $subject }» como correio legítimo
agent-log-archived = Arquivou «{ $subject }»
agent-log-folder = Criou a pasta «{ $name }»
agent-log-unsubscribed = Autorizou o pedido de cancelamento da subscrição. Mensagem: «{ $subject }»
agent-log-unsubscribe-failed = Não foi possível cancelar a subscrição da lista de correio associada à mensagem «{ $subject }»: { $reason }
agent-log-unsubscribe-refused = Não autorizou o cancelamento de subscrições. Remetentes: { $senders }
agent-unsubscribe-title = { $count ->
    [one] { $program } quer cancelar a sua subscrição de uma lista de correio
   *[other] { $program } quer cancelar a sua subscrição de { $count } listas de correio
}
agent-unsubscribe-detail = { $count ->
    [1] O Inbox Classic pede à lista de correio abaixo que deixe de lhe enviar mensagens, usando a opção de cancelamento com um clique. Não é enviado mais nada. As mensagens existentes não são alteradas nem movidas.
   *[other] O Inbox Classic pede a cada lista de correio abaixo que deixe de lhe enviar mensagens, usando a opção de cancelamento com um clique. Não é enviado mais nada. As mensagens existentes não são alteradas nem movidas.
}

## Keys as the keyboards of the language name them, in the help (Windows and Linux)

key-ctrl = Ctrl
key-alt = Alt
key-shift = Shift
key-del = Del
key-enter = Enter

## Signing in and passwords

sign-in-no-refresh = o fornecedor não forneceu um token de atualização
sign-in-no-account = o fornecedor não indicou que conta iniciou sessão
sign-in-not-finished = o início de sessão não terminou
secrets-unavailable = { $store } não está disponível
secrets-unavailable-why = { $store } não está disponível: { $error }
secrets-windows = o Gestor de Credenciais
secrets-mac = o porta-chaves
secrets-linux = o porta-chaves do sistema (Secret Service)
error-no-such-file = o ficheiro não existe
cards-file-too-big = Este ficheiro é demasiado grande para ser importado como livro de endereços.
ui-sender-added = O contacto { $name } foi adicionado ao Livro de Endereços.
ui-sender-known = { $name } já está no Livro de Endereços.
ui-sender-none = O remetente desta mensagem não tem um endereço de e-mail para adicionar.
card-name-needed = O contacto não tem nome nem endereço de e-mail.
# a file of Import Address Book that could not be read: "contacts.vcf: there is no such file"
cards-file-failed = { $file }: { $reason }

## One-time codes: the card at the top of a message with a sign-in or verification code

# the domain the code is for, which signed the message
otp-heading = Código de { $domain }
otp-copy = Copiar
otp-note = Introduza-o apenas numa página de { $domain }.
otp-old = Este código foi enviado mais de uma hora antes de o abrir e provavelmente já expirou.

# how many are invited, in the card of an event
event-attendees =
    { $count ->
        [0] 0 participantes
        [one] { $count } participante
       *[other] { $count } participantes
    }

# the first line of a new message's notification when it has a code, for a domain that signed it
otp-notification = { $code } é o seu código para { $domain }

## OpenPGP keys (keys.rs)
pgp-key-valid = Válida
pgp-key-expires = Válida até { $date }
pgp-key-expired = Expirou a { $date }
pgp-key-revoked = Revogada
pgp-key-revoked-why = Revogada: { $reason }
pgp-key-not-valid = Não válida
pgp-key-locked = Não é possível usar esta chave: { $store } já não contém a chave que a protegia. Importe novamente a cópia de segurança da sua chave privada.
pgp-source-own = Criada no Inbox Classic
pgp-source-file = Importada de um ficheiro
pgp-source-paste = Colada
pgp-source-attachment = De uma mensagem
pgp-source-vcard = De um cartão de contacto
pgp-source-wkd = Do fornecedor de correio do remetente
pgp-source-keyserver = De keys.openpgp.org
pgp-source-autocrypt = Do cabeçalho Autocrypt de uma mensagem
pgp-error-no-store = Não é possível usar { $store }, que protege as chaves privadas: { $error }
pgp-error-wrong-passphrase = A frase de acesso não está correta.
pgp-error-not-a-key = Isto não é uma chave OpenPGP.
pgp-error-too-large = A chave é demasiado grande.
pgp-error-unusable = A chave utiliza métodos criptográficos obsoletos ou inseguros e não pode ser utilizada.
pgp-imported-private = { $count ->
    [one] A sua chave privada foi importada.
   *[other] Foram importadas { $count } chaves privadas.
}
pgp-imported-public = { $count ->
    [0] Não foi importada nenhuma chave.
    [one] Foi importada uma chave.
   *[other] Foram importadas { $count } chaves.
}
pgp-imported-pending = Já existe outra chave em uso para estes endereços: { $addresses }. A nova chave só será utilizada quando a selecionar nas propriedades do contacto.
pgp-error-needs-passphrase = A chave privada está protegida por uma frase de acesso. Escreva-a para importar a chave.
pgp-error-mismatch = A chave privada não corresponde à chave pública. Pode ter sido alterada.
pgp-file-name-public = Chave pública de { $who }.asc
pgp-file-name-private = Cópia de segurança da chave privada de { $who }.asc
pgp-pending = Foi encontrada uma chave diferente para { $address } a { $date }.

## Reading signed and encrypted mail (protect.rs)
pgp-part-verified = Assinada por { $signer }, chave verificada
pgp-part-signed = Assinada por { $signer } (chave não verificada)
pgp-part-other = Assinada por { $signer }, que não é o remetente
pgp-part-unknown-key = Assinada, mas a chave não é conhecida
pgp-part-not-signed = Não assinada
pgp-part-not-checked = Assinatura não verificada
pgp-part-encrypted = Encriptada. { $signature }
pgp-part-no-key = Encriptada; falta a chave privada necessária para a ler
pgp-part-changed = A parte encriptada foi alterada durante a transmissão e não é apresentada
pgp-part-unprotected = Encriptada sem proteção contra alterações, não é mostrada
pgp-part-broken = Não é possível ler a parte encriptada
pgp-why-mismatch = A assinatura não corresponde a este texto
pgp-why-weak-hash = A assinatura usa { $hash }, que já não é seguro
pgp-why-key-expired = Assinada depois de a chave ter expirado a { $date }
pgp-why-key-revoked = Assinada com uma chave que foi revogada
pgp-why-not-signing-key = Assinada com uma chave que não permite criar assinaturas
pgp-why-from-future = A assinatura tem uma data no futuro
pgp-why-signature-expired = A assinatura expirou
pgp-why-key-not-valid = Assinada com uma chave que não é válida
pgp-why-not-for-you = Assinada para outros destinatários e reencaminhada para si
pgp-why-not-key-in-use = Assinada com uma chave diferente da usada para { $address }
pgp-part-pictures-loaded = { $label }. Foram carregadas imagens da Internet
pgp-error-no-own-key = Não tem nenhuma chave para { $address } com que assinar ou encriptar. Crie uma em Ferramentas > Chaves de encriptação, ou desative Assinar e Encriptar.
pgp-error-missing-keys = { $count ->
    [one] Não existe uma chave para encriptar mensagens para este destinatário: { $addresses }.
   *[other] Não existem chaves para encriptar mensagens para estes destinatários: { $addresses }.
}
pgp-error-encrypted-quote = Esta mensagem cita ou reencaminha uma mensagem encriptada, por isso só pode ser enviada encriptada. Ative Encriptar, ou remova o texto citado.
pgp-error-protect = Não foi possível assinar ou encriptar a mensagem: { $reason }
pgp-found-keys = Foram encontradas chaves para: { $addresses }.
pgp-found-none = Não foi encontrada nenhuma chave para estes endereços: { $addresses }. Peça aos respetivos titulares que enviem as suas chaves públicas.
pgp-found-no-key = Não foi encontrada nenhuma chave.
pgp-find-unavailable = Não foi possível procurar chaves agora: { $error }
pgp-publish-pending = O serviço keys.openpgp.org enviou uma ligação de confirmação para cada um destes endereços: { $addresses }. Confirme cada endereço para que a sua chave possa ser encontrada através dele.
pgp-publish-done = A sua chave está publicada em keys.openpgp.org para { $addresses }.
pgp-publish-failed = Não foi possível publicar a chave: { $error }
pgp-keyserver-off = A procura de chaves em keys.openpgp.org está desativada em { $settings }.
# the compose window with Sign and Encrypt: the line under the fields, each recipient's key, the questions
pgp-compose-encrypted = { $count ->
    [one] A mensagem será encriptada e assinada no envio. O conteúdo só poderá ser lido por si e por { $addresses }.
   *[other] A mensagem será encriptada e assinada no envio. O conteúdo só poderá ser lido por si e pelos { $count } destinatários.
}
pgp-compose-encrypt-ready = A mensagem será encriptada e assinada no envio. Adicione destinatários para os quais tenha uma chave utilizável.
pgp-compose-missing = { $count ->
    [one] Não há uma chave utilizável para este destinatário: { $addresses }. Ainda não é possível encriptar a mensagem.
   *[other] Não há chaves utilizáveis para { $count } destinatários: { $addresses }. Ainda não é possível encriptar a mensagem.
}
pgp-compose-looking = A procurar as chaves de { $addresses }...
pgp-compose-signed = A mensagem será assinada digitalmente no envio. Os destinatários poderão verificar a assinatura e a integridade do conteúdo.
pgp-compose-reply-clear = Não encriptada, embora a mensagem original estivesse encriptada.
pgp-compose-encrypted-files = Esta mensagem contém anexos provenientes de uma mensagem encriptada e só pode ser enviada encriptada. Ative «Encriptar» ou remova esses anexos.
pgp-compose-sign-tip = Assinar digitalmente a mensagem no envio para que os destinatários possam verificar a assinatura e a integridade do conteúdo
pgp-compose-sign-tip-encrypted = As mensagens encriptadas são sempre assinadas no envio
pgp-compose-encrypt-tip = Encriptar o conteúdo da mensagem no envio para que só possa ser lido por si e pelos destinatários
pgp-compose-make-key = Ainda não está configurada uma chave própria para { $address }. Pretende criar uma agora? Poderá usá-la para assinar e encriptar mensagens.
pgp-compose-key-unusable = A sua chave para { $address } não pode ser utilizada. Motivo: { $state }
    Abra «Chaves de encriptação» para importar uma cópia de segurança dessa chave ou criar uma nova.
pgp-compose-encrypt-off-quote = Esta mensagem ainda contém texto, imagens ou anexos provenientes de uma mensagem encriptada. Remova-os antes de a enviar sem encriptação. Pretende desativar a encriptação mesmo assim?
pgp-compose-encrypt-off-reply = A mensagem original estava encriptada. Se enviar a resposta ou a mensagem reencaminhada sem encriptação, os servidores de correio poderão ler o conteúdo. Pretende desativar a encriptação?
pgp-recipient-verified = Chave verificada
pgp-recipient-found = Chave não verificada
pgp-recipient-own = A sua própria chave
pgp-recipient-looking = A procurar uma chave...
pgp-recipient-missing = Sem chave
pgp-recipient-not-found = Não foi encontrada nenhuma chave. Última pesquisa: { $date }
pgp-recipient-unusable = A chave não pode ser usada: { $state }
pgp-recipients-intro = O Inbox Classic utilizará as chaves dos destinatários e a sua para encriptar a mensagem.
pgp-recipients-intro-missing = { $count ->
    [one] Falta uma chave utilizável para um destinatário. Procure a chave ou remova o destinatário da mensagem. Só pode enviar a mensagem sem encriptação se esta já não contiver texto, imagens ou anexos de mensagens encriptadas.
   *[other] Faltam chaves utilizáveis para { $count } destinatários. Procure as respetivas chaves ou remova esses destinatários da mensagem. Só pode enviar a mensagem sem encriptação se esta já não contiver texto, imagens ou anexos de mensagens encriptadas.
}
pgp-details-part = Parte { $number }: { $label }
pgp-details-signed = Data da assinatura: { $when }. Chave: { $key }
pgp-details-unknown-key = Assinada com a chave { $key }, que não tem
pgp-details-opened = Desencriptada com a sua chave { $key }
pgp-details-for = Encriptada com as chaves: { $keys }
pgp-details-plain = Não assinada e não encriptada
pgp-bar-parts = Esta mensagem tem { $count } partes: { $list }. Cada parte indica como está protegida.
pgp-bar-count-verified = { $count ->
    [one] { $count } verificada
   *[other] { $count } verificadas
}
pgp-bar-count-good = { $count ->
    [one] { $count } assinada ou encriptada
   *[other] { $count } assinadas ou encriptadas
}
pgp-bar-count-warning = { $count ->
    [one] { $count } requer atenção
   *[other] { $count } requerem atenção
}
pgp-bar-count-neutral = { $count } sem assinatura confirmada
# the setup file: settings, accounts, contacts and keys carried to another computer
setup-part-settings = Definições
setup-part-preferences = Preferências das janelas
setup-part-accounts = Contas
setup-part-sign-in-apps = Aplicações de início de sessão
setup-part-contacts = Contactos e grupos
setup-part-keys = Chaves de encriptação
setup-part-rules = Regras de mensagens
setup-part-trusted-senders = Remetentes fidedignos
setup-holds-settings = { $count ->
    [0] 0 definições
    [one] { $count } definição
   *[other] { $count } definições
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
    [0] 0 aplicações de início de sessão
    [one] { $count } aplicação de início de sessão
   *[other] { $count } aplicações de início de sessão
}
setup-holds-built-in = Estado de ativação das aplicações de início de sessão integradas
setup-holds-contacts = { $count ->
    [0] 0 contactos
    [one] { $count } contacto
   *[other] { $count } contactos
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
    [0] 0 chaves de contactos
    [one] { $count } chave de um contacto
   *[other] { $count } chaves de contactos
}
setup-holds-rules = { $count ->
    [0] 0 regras
    [one] { $count } regra
   *[other] { $count } regras
}
setup-holds-trusted-senders = { $count ->
    [0] 0 remetentes fidedignos
    [one] { $count } remetente fidedigno
   *[other] { $count } remetentes fidedignos
}
setup-sign-in-password = Palavra-passe
setup-account-secret-password = A palavra-passe está no ficheiro.
setup-account-secret-token = As credenciais de início de sessão estão incluídas no ficheiro.
setup-account-asks-password = Será necessário introduzir a palavra-passe após a importação.
setup-account-signs-in-again = Será necessário iniciar sessão novamente após a importação.
setup-account-here = Já está configurada aqui, por isso é ignorada.
setup-account-no-app = Esta conta usa a aplicação { $app }, que não está configurada neste computador. Importe também as aplicações de início de sessão.
setup-invalid-address = «{ $address }» não é um endereço de e-mail.
setup-invalid-server = O nome ou a porta do servidor { $server } não são válidos.
setup-invalid-user = Não tem nome de utilizador.
setup-invalid-sign-in = O método de início de sessão não é suportado pelo Inbox Classic.
setup-error-empty = O ficheiro está vazio.
setup-error-too-large = O ficheiro é demasiado grande para ser uma configuração do Inbox Classic.
setup-error-not-setup = Este ficheiro não é uma configuração do Inbox Classic.
setup-error-damaged = O ficheiro de configuração está danificado e não pode ser lido.
setup-error-newer = Esta configuração foi guardada por uma versão mais recente do Inbox Classic ({ $version }). Atualize o Inbox Classic e importe-a novamente.
setup-error-needs-passphrase = Esta configuração está protegida por uma frase de acesso. Escreva a frase de acesso com que foi guardada.
setup-error-wrong-passphrase = Essa não é a frase de acesso com que esta configuração foi guardada.
setup-error-changed = O ficheiro de configuração foi alterado ou danificado depois de ser guardado, por isso não pode ser importado.
setup-error-read = Não foi possível ler o ficheiro de configuração: { $error }
setup-error-write = Não foi possível guardar a configuração: { $error }
setup-error-no-parts = Selecione pelo menos um tipo de dados.
setup-left-out = { $count ->
    [one] Foi excluída { $count } entrada inválida de «{ $part }».
   *[other] Foram excluídas { $count } entradas inválidas de «{ $part }».
}
setup-imported-settings = As definições foram substituídas.
setup-imported-preferences = As preferências das janelas foram substituídas.
setup-added-accounts = { $count ->
    [one] Foi adicionada { $count } conta.
   *[other] Foram adicionadas { $count } contas.
}
setup-skipped-here = A conta { $address } já está configurada neste computador e não foi importada.
setup-skipped-no-app = A conta { $address } não foi importada porque utiliza a aplicação { $app }, que não está configurada neste computador.
setup-skipped-invalid = A conta { $address } não foi importada: { $reason }
setup-asks-password = A conta { $address } pedirá a palavra-passe quando se ligar ao servidor.
setup-signs-in-again = Será necessário iniciar sessão novamente na conta { $address } quando esta se ligar ao servidor.
setup-added-sign-in-apps = { $count ->
    [one] Foi adicionada { $count } aplicação de início de sessão.
   *[other] Foram adicionadas { $count } aplicações de início de sessão.
}
setup-skipped-sign-in-apps = { $count ->
    [one] { $count } aplicação de início de sessão já está configurada aqui.
   *[other] { $count } aplicações de início de sessão já estão configuradas aqui.
}
setup-added-contacts = { $count ->
    [one] Foi adicionado { $count } contacto ao Livro de Endereços.
   *[other] Foram adicionados { $count } contactos ao Livro de Endereços.
}
setup-skipped-contacts = { $count ->
    [one] { $count } contacto já está no Livro de Endereços.
   *[other] { $count } contactos já estão no Livro de Endereços.
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
    [one] Foi adicionada { $count } chave de um contacto.
   *[other] Foram adicionadas { $count } chaves de contactos.
}
setup-added-rules = { $count ->
    [one] Foi adicionada { $count } regra de mensagens.
   *[other] Foram adicionadas { $count } regras de mensagens.
}
setup-skipped-rules = { $count ->
    [one] { $count } regra de mensagens já existe neste computador.
   *[other] { $count } regras de mensagens já existem neste computador.
}
setup-skipped-rules-account = { $count ->
    [one] { $count } regra de mensagens é para uma conta que não está aqui, por isso foi ignorada.
   *[other] { $count } regras de mensagens são para contas que não estão aqui, por isso foram ignoradas.
}
setup-rules-waiting = { $count ->
    [one] { $count } regra de mensagens move mensagens para uma pasta que aparece quando a respetiva conta sincronizar.
   *[other] { $count } regras de mensagens movem mensagens para pastas que aparecem quando as respetivas contas sincronizarem.
}
setup-added-trusted-senders = { $count ->
    [one] Foi adicionado { $count } remetente fidedigno.
   *[other] Foram adicionados { $count } remetentes fidedignos.
}
setup-nothing = Não foi importado nada.
setup-account-servers = { $imap } e { $smtp } ({ $signin })
setup-file-name = Definições e contas do Inbox Classic
setup-skipped-unreachable = A aplicação { $name } não foi importada porque não foi possível contactar o respetivo serviço de início de sessão. Adicione-a novamente em Aplicações de início de sessão.
attachment-runs-programs = «{ $name }» pode executar código, por isso o Inbox Classic não o abre diretamente. Guarde o ficheiro e abra-o manualmente apenas se confiar na sua origem.
attachment-decrypted-note = Este anexo provém de uma mensagem encriptada. Para o abrir, o Inbox Classic guarda uma cópia sem encriptação numa pasta temporária do seu utilizador. As cópias com mais de 24 horas são removidas quando a aplicação é iniciada.
# a bar over the list when the server did not do what the user asked of messages, so they are as they were again
undone-move = { $count ->
    [one] O servidor não moveu { $messages } para { $folder }, por isso está de novo em { $from }: { $reason }
   *[other] O servidor não moveu { $messages } para { $folder }, por isso estão de novo em { $from }: { $reason }
}
undone-delete = { $count ->
    [one] O servidor não eliminou { $messages }, por isso está de novo em { $from }: { $reason }
   *[other] O servidor não eliminou { $messages }, por isso estão de novo em { $from }: { $reason }
}
undone-archive = { $count ->
    [one] O servidor não arquivou { $messages }, por isso está de novo em { $from }: { $reason }
   *[other] O servidor não arquivou { $messages }, por isso estão de novo em { $from }: { $reason }
}
undone-read = { $count ->
    [one] O servidor não marcou { $messages } como lida, por isso está de novo por ler: { $reason }
   *[other] O servidor não marcou { $messages } como lidas, por isso estão de novo por ler: { $reason }
}
undone-unread = { $count ->
    [one] O servidor não marcou { $messages } como não lida, por isso volta a aparecer como lida: { $reason }
   *[other] O servidor não marcou { $messages } como não lidas, por isso voltam a aparecer como lidas: { $reason }
}
undone-flags = { $count ->
    [one] O servidor não alterou os sinalizadores de { $messages }, por isso a alteração foi anulada: { $reason }
   *[other] O servidor não alterou os sinalizadores de { $messages }, por isso a alteração foi anulada: { $reason }
}

## Previews of attachments: the pictures and PDF files shown in a message

# review: new
preview-pdf-option = Mostrar ficheiros PDF nas mensagens
# review: new
preview-pdf-off = Os ficheiros PDF não são mostrados nas mensagens.
# review: new
preview-pdf-off-crashed = Um ficheiro PDF fechou o Inbox Classic enquanto era mostrado, pelo que os ficheiros PDF deixaram de ser mostrados nas mensagens. As imagens continuam a ser. Para voltar a mostrar ficheiros PDF, ative { $option } em { $settings }.
# review: new
preview-pdf-details = { $count ->
    [one] 1 página, { $size }
   *[other] { $count } páginas, { $size }
}
# review: new
preview-page-alt = { $name }, página { $page } de { $count }
# review: new
preview-more-pages = { $count ->
    [one] Abra o ficheiro para ver a página
   *[other] Abra o ficheiro para ver as { $count } páginas
}
# review: new
preview-more-files = { $count ->
    [one] Mais 1 ficheiro está na lista acima
   *[other] Mais { $count } ficheiros estão na lista acima
}
# review: new
preview-tile-downloading = A transferir…
# review: new
preview-tile-format = As imagens { $format } ainda não são mostradas
# review: new
preview-tile-password = Protegido por palavra-passe
# review: new
preview-tile-too-large = Demasiado grande para mostrar
# review: new
preview-tile-unreadable = Não é possível mostrar
# review: new
preview-tile-timed-out = Demorou demasiado a mostrar
# review: new
preview-tile-crashed = Não mostrado: fechou o Inbox Classic uma vez
# review: new
preview-tile-off = Não mostrado até o Inbox Classic ser iniciado novamente
# review: new
preview-not-printed = { $name } ({ $details }) não é impresso. Abra-o para o imprimir.
