# Français. Brouillon, en attente de relecture par un locuteur natif (voir core/locales/GLOSSARY.md).

## Counts and sizes

messages = { $count ->
    [one] { $count } message
   *[other] { $count } messages
}
decimal-separator = ,
size-bytes = { $count ->
    [one] { $count } octet
   *[other] { $count } octets
}
size-kb = { $size } Ko
size-mb = { $size } Mo
list-counts = { $messages }, { $unread ->
    [one] { $unread } non lu
   *[other] { $unread } non lus
}
list-counts-selected = { $messages }, { $unread ->
    [one] { $unread } non lu
   *[other] { $unread } non lus
}, { $selected ->
    [one] { $selected } sélectionné
   *[other] { $selected } sélectionnés
}
list-counts-found = { $found ->
    [one] { $found } trouvé
   *[other] { $found } trouvés
}, { $unread ->
    [one] { $unread } non lu
   *[other] { $unread } non lus
}
list-counts-found-selected = { $found ->
    [one] { $found } trouvé
   *[other] { $found } trouvés
}, { $unread ->
    [one] { $unread } non lu
   *[other] { $unread } non lus
}, { $selected ->
    [one] { $selected } sélectionné
   *[other] { $selected } sélectionnés
}
list-counts-none = Aucun message trouvé

## Special folders

folder-inbox = Boîte de réception
folder-sent = Éléments envoyés
folder-deleted = Éléments supprimés
folder-drafts = Brouillons
folder-junk = Courrier indésirable
folder-archive = Archives

## The reading pane

reader-no-message = Aucun message n'est sélectionné.
reader-downloading = Téléchargement du message…
reader-downloading-detail = Le message s’affichera ici une fois le téléchargement terminé.
reader-failed = Le message n'a pas pu être téléchargé
reader-failed-network = Le serveur de messagerie est inaccessible ({ $reason }).
reader-failed-sign-in = Le serveur de messagerie a refusé la connexion ({ $reason }). Vérifiez le mot de passe ou reconnectez-vous dans Fichier > Comptes.
reader-failed-security = Impossible d’établir une connexion sécurisée au serveur de messagerie ({ $reason }).
reader-failed-other = Le serveur de messagerie a répondu : { $reason }.
reader-retry-note = Message non téléchargé. Une nouvelle tentative aura lieu dès que la connexion au compte sera rétablie.
reader-unreadable = Ce message ne peut pas être affiché : { $error }
message-source-title = Code source du message : { $subject }
message-source-untitled = Code source du message

## Printing and quoting

header-from = De
header-date = Date
header-to = À
header-cc = Cc
header-sent = Envoyé
header-subject = Objet
quote-original = ----- Message d'origine -----
fold-show-earlier = Afficher les messages précédents

## Messages non remis : la carte au-dessus d'un avis de non-remise

# review: new
bounce-failed = Votre message n'a pas été remis
# review: new
bounce-delayed = Votre message n'a pas encore été remis
# review: new
bounce-delayed-note = Votre serveur de messagerie essaie toujours de le remettre. Vous n'avez pas besoin de le renvoyer.
# review: new
bounce-show-message = Afficher le message non remis
# review: new
bounce-what-to-do = Ce que vous pouvez faire :
# review: new
bounce-delayed-do = Rien pour l'instant. S'il ne peut toujours pas être remis, vous recevrez un autre avis.
# review: new
bounce-delayed-row-do = Rien pour l'instant. Votre serveur de messagerie essaie toujours de le remettre, et vous recevrez un autre avis s'il n'y parvient pas.
# review: new
bounce-details = Détails
# review: new
bounce-someone = Un destinataire
# review: new
bounce-server = Serveur : { $server }
# review: new
bounce-status = État : { $status }
# review: new
bounce-reported-by = Signalé par : { $server }
# review: new
bounce-retry-minutes = Le serveur de réception a demandé d'attendre { $count ->
    [one] une minute
   *[other] { $count } minutes
} avant le prochain essai.
# review: new
bounce-retry-hours = Le serveur de réception a demandé d'attendre { $count ->
    [one] une heure
   *[other] { $count } heures
} avant le prochain essai.
# review: new
bounce-blocklist = Liste de blocage : { $lists }
# review: new
bounce-user-unknown = L'adresse n'existe pas
# review: new
bounce-user-unknown-why = Le serveur de réception n'a aucune boîte aux lettres à cette adresse. Elle est peut-être mal écrite, ou la personne n'y est plus.
# review: new
bounce-user-unknown-do = Vérifiez l'orthographe de l'adresse, ou demandez à la personne l'adresse qu'elle utilise maintenant.
# review: new
bounce-invalid-address = L'adresse n'est pas valide
# review: new
bounce-invalid-address-why = L'adresse n'est pas écrite sous une forme à laquelle on peut envoyer du courrier.
# review: new
bounce-invalid-address-do = Cherchez les fautes de frappe, comme une espace, une lettre manquante ou rien après le @.
# review: new
bounce-mailbox-disabled = La boîte aux lettres est fermée
# review: new
bounce-mailbox-disabled-why = L'adresse existe, mais sa boîte aux lettres a été désactivée ou n'est plus utilisée.
# review: new
bounce-mailbox-disabled-do = Joignez la personne autrement et demandez-lui une adresse qu'elle utilise maintenant.
# review: new
bounce-mailbox-full = La boîte aux lettres est pleine
# review: new
bounce-mailbox-full-why = La boîte aux lettres du destinataire n'a plus de place pour le nouveau courrier.
# review: new
bounce-mailbox-full-do = Renvoyez-le dans quelques jours, ou prévenez la personne autrement. Les grosses pièces jointes sont refusées en premier.
# review: new
bounce-spam-blocked = Refusé comme courrier indésirable
# review: new
bounce-spam-blocked-why = Le serveur de réception a pris le message pour du courrier indésirable.
# review: new
bounce-spam-blocked-do = Renvoyez-le sans ce qui ressemble à du courrier indésirable, comme de nombreux liens, des liens raccourcis ou une grosse pièce jointe. Si cela se reproduit, contactez votre fournisseur de messagerie.
# review: new
bounce-virus-detected = Refusé pour un virus
# review: new
bounce-virus-detected-why = Le serveur de réception a trouvé un virus ou un autre contenu dangereux dans le message ou ses pièces jointes.
# review: new
bounce-virus-detected-do = Vérifiez les pièces jointes avec un antivirus. Certains serveurs refusent tout programme ou toute archive : partagez plutôt ces fichiers par un lien.
# review: new
bounce-ip-blocklisted = Votre serveur de messagerie est sur une liste de blocage
# review: new
bounce-ip-blocklisted-why = Le serveur de réception refuse le courrier du serveur qui a envoyé le vôtre, car l'adresse de ce serveur est sur une liste de blocage.
# review: new
bounce-ip-blocklisted-do = Le message n'est pas en cause. Transférez cet avis à votre fournisseur de messagerie et demandez-lui de faire retirer le serveur de la liste.
# review: new
bounce-domain-blocklisted = Un domaine est sur une liste de blocage
# review: new
bounce-domain-blocklisted-why = Le serveur de réception refuse le message car le domaine de votre adresse, ou un domaine des liens du message, est sur une liste de blocage.
# review: new
bounce-domain-blocklisted-do = Si le message contient des liens, essayez sans eux. Sinon, transférez cet avis à la personne qui gère le courrier de votre domaine.
# review: new
bounce-policy-blocked = Refusé par les règles du serveur de réception
# review: new
bounce-policy-blocked-why = Les règles du serveur de réception ne laissent pas passer ce message, par exemple à cause de sa taille, de ses pièces jointes ou de son expéditeur.
# review: new
bounce-policy-blocked-do = Les propres mots du serveur sous Détails donnent souvent la raison. Demandez au destinataire s'il peut accepter ce type de courrier.
# review: new
bounce-geo-blocked = Refusé pour sa provenance
# review: new
bounce-geo-blocked-why = Le serveur de réception n'accepte pas le courrier du pays ou du réseau où se trouve votre serveur de messagerie.
# review: new
bounce-geo-blocked-do = Joignez la personne autrement, ou contactez votre fournisseur de messagerie.
# review: new
bounce-relay-denied = Le serveur ne l'a pas transmis
# review: new
bounce-relay-denied-why = Un serveur a refusé de transmettre le message, souvent parce qu'il a été envoyé sans connexion ou par un serveur qui ne dessert pas ce destinataire.
# review: new
bounce-relay-denied-do = Vérifiez le serveur sortant du compte dans Fichier > Comptes, et qu'il se connecte.
# review: new
bounce-auth-failure = Votre adresse d'expéditeur n'a pas pu être vérifiée
# review: new
bounce-auth-failure-why = Le serveur de réception n'a pas pu confirmer que le message venait bien de votre domaine (SPF, DKIM ou DMARC).
# review: new
bounce-auth-failure-do = Transférez cet avis à la personne qui gère le courrier de votre domaine : ses réglages doivent être corrigés. En attendant, envoyer par le serveur de votre fournisseur peut aider.
# review: new
bounce-rate-limited = Trop de courrier à la fois
# review: new
bounce-rate-limited-why = Le serveur de réception accepte pour l'instant moins de messages de votre serveur de messagerie.
# review: new
bounce-rate-limited-do = Attendez un moment et renvoyez-le. Si vous écrivez à de nombreuses personnes, envoyez à moins de personnes à la fois.
# review: new
bounce-greylisting = Retenu un instant
# review: new
bounce-greylisting-why = Le serveur de réception demande aux expéditeurs inconnus de réessayer un peu plus tard, une vérification courante contre le courrier indésirable.
# review: new
bounce-greylisting-do = Rien. Les serveurs de messagerie réessaient d'eux-mêmes, et le message est généralement remis dans l'heure.
# review: new
bounce-server-error = Le serveur de réception a eu un problème
# review: new
bounce-server-error-why = Le serveur de réception n'a pas pu être joint, ou n'a pas pu accepter le message à cause d'un problème de son côté.
# review: new
bounce-server-error-do = Renvoyez-le plus tard. Si l'échec persiste, cherchez des fautes de frappe dans la partie de l'adresse après le @.
# review: new
bounce-unknown = Non remis
# review: new
bounce-unknown-why = L'avis ne dit pas clairement pourquoi.
# review: new
bounce-unknown-do = Les propres mots du serveur sous Détails peuvent en dire plus. S'ils n'aident pas, transférez cet avis à votre fournisseur de messagerie.

## Several messages selected

selection-title = { $count ->
    [one] { $count } message sélectionné
   *[other] { $count } messages sélectionnés
}
selection-unread = { $count ->
    [one] { $count } non lu
   *[other] { $count } non lus
}
selection-flagged = { $count } avec indicateur
delete-for-good-one = Ce message sera supprimé définitivement. Le supprimer ?
delete-for-good-all = Ces { $count } messages seront supprimés définitivement. Les supprimer ?
delete-for-good-some = { $count } des { $total } messages seront supprimés définitivement. Supprimer les messages ?
done-read = { $count ->
    [one] { $messages } marqué comme lu
   *[other] { $messages } marqués comme lus
}
done-unread = { $count ->
    [one] { $messages } marqué comme non lu
   *[other] { $messages } marqués comme non lus
}
done-flagged = { $count ->
    [one] Indicateur ajouté à { $messages }
   *[other] Indicateur ajouté à { $messages }
}
done-unflagged = Indicateur retiré de { $messages }
done-deleted-for-good = { $count ->
    [one] { $messages } supprimé définitivement
   *[other] { $messages } supprimés définitivement
}
# review: new
done-archived = { $count ->
    [one] { $messages } archivé
   *[other] { $messages } archivés
}
done-moved = { $count ->
    [one] { $messages } déplacé vers { $folder }
   *[other] { $messages } déplacés vers { $folder }
}
done-copied = { $count ->
    [one] { $messages } copié vers { $folder }
   *[other] { $messages } copiés vers { $folder }
}
done-moving = { $count ->
    [one] Déplacement de { $messages } vers { $folder }...
   *[other] Déplacement de { $messages } vers { $folder }...
}
done-copying = { $count ->
    [one] Copie de { $messages } vers { $folder }...
   *[other] Copie de { $messages } vers { $folder }...
}
done-moved-back = { $count ->
    [one] { $messages } replacé dans { $folder }
   *[other] { $messages } replacés dans { $folder }
}
their-folders = leurs dossiers
undo-move = Annuler le déplacement
undo-delete = Annuler la suppression
# review: new
undo-archive = Annuler l'archivage
undo-junk = Annuler le marquage comme indésirable
undo-not-junk = Annuler le marquage comme non indésirable
nothing-to-undo = Il n'y a rien à annuler.
messages-gone = Les messages ne sont plus là.
folder-holds-no-messages = Ce dossier ne peut pas contenir de messages.
# review: new
not-archived-here = Les messages de ce dossier ne peuvent pas être archivés.
# review: new
not-emptied-here = Seuls Éléments supprimés et Courrier indésirable peuvent être vidés.
# review: new
empty-question = { $count ->
    [one] Vider { $folder } ?

        Le message qu'il contient sera supprimé définitivement. Il ne pourra pas être récupéré.
   *[other] Vider { $folder } ?

        Les { $messages } qu'il contient seront supprimés définitivement. Ils ne pourront pas être récupérés.
}
no-junk-folder = Ce compte n'a pas de dossier Courrier indésirable où déplacer les messages.
no-inbox-folder = Ce compte n'a pas de Boîte de réception où déplacer les messages.
done-flagged-color = Indicateur { $color ->
    [red] rouge
    [orange] orange
    [yellow] jaune
    [green] vert
    [blue] bleu
    [purple] violet
   *[gray] gris
} mis sur { $messages }
flag-color = { $color ->
    [red] Rouge
    [orange] Orange
    [yellow] Jaune
    [green] Vert
    [blue] Bleu
    [purple] Violet
   *[gray] Gris
}

## La fenêtre Déplacer et Copier

move-window-title-move = { $count ->
    [one] Déplacer le message
   *[other] Déplacer { $count } messages
}
move-window-title-copy = { $count ->
    [one] Copier le message
   *[other] Copier { $count } messages
}
move-window-prompt-move = { $count ->
    [one] Déplacer le message sélectionné vers :
   *[other] Déplacer les { $count } messages sélectionnés vers :
}
move-window-prompt-copy = { $count ->
    [one] Copier le message sélectionné vers :
   *[other] Copier les { $count } messages sélectionnés vers :
}
targets-recent = Récents
target-current = { $folder } (actuel)
target-recent = { $folder } ({ $account })

## Moving and copying to another account

transfer-moving = Déplacement vers { $folder } : { $done } sur { $messages }...
transfer-copying = Copie vers { $folder } : { $done } sur { $messages }...
transfer-another-account = un autre compte
transfer-folder-gone = le dossier de destination n'existe plus
transfer-not-on-server = le message n'est plus sur le serveur
transfer-not-moved = { $count ->
    [one] { $messages } n'a pas pu être déplacé vers un autre compte : { $reason }
   *[other] { $messages } n'ont pas pu être déplacés vers un autre compte : { $reason }
}
transfer-not-copied = { $count ->
    [one] { $messages } n'a pas pu être copié vers un autre compte : { $reason }
   *[other] { $messages } n'ont pas pu être copiés vers un autre compte : { $reason }
}
transfer-none-moved = Aucun message n'a pu être déplacé
transfer-none-copied = Aucun message n'a pu être copié

## Messages as files

export-not-in-time = le message n'a pas pu être téléchargé à temps
export-not-saved = { $failed ->
    [one] { $failed } sur { $messages } n'a pas pu être enregistré ({ $problems })
   *[other] { $failed } sur { $messages } n'ont pas pu être enregistrés ({ $problems })
}
export-not-attached = les messages n'ont pas pu être joints : { $error }
saved-to = { $count ->
    [one] { $messages } enregistré dans { $folder }
   *[other] { $messages } enregistrés dans { $folder }
}
downloading-messages = { $count ->
    [one] Téléchargement de { $messages }...
   *[other] Téléchargement de { $messages }...
}
import-put = { $count ->
    [one] { $messages } placé dans { $folder }
   *[other] { $messages } placés dans { $folder }
}
import-not-put = Les messages suivants n’ont pas pu être importés :

    { $problems }

## Problems the windows show

error-store = stockage local : { $error }
error-not-found = introuvable
error-closed = fermeture en cours
error-other-account = le navigateur s'est connecté à { $email }, pas à ce compte
error-in-use = impossible de la supprimer tant que des comptes l'utilisent pour se connecter : { $accounts }
error-turned-off = cette application de connexion est désactivée pour les nouveaux comptes
error-folder-name = le nom du dossier doit comporter de 1 à 200 caractères, sans caractères de contrôle
error-folder-separator = un nom de dossier ne peut pas contenir « { $separator } » sur ce serveur
error-folder-special = la Boîte de réception et les dossiers spéciaux ne peuvent pas être renommés ni supprimés
error-no-recipients = le message n'a aucun destinataire
error-bad-address = « { $address } » n'est pas une adresse de messagerie
error-attachment = { $path } n'a pas pu être lu : { $error }
error-no-drafts = le compte n'a pas de dossier Brouillons où enregistrer le message
error-draft-attachment = une pièce jointe du brouillon n'a pas pu être conservée : { $error }
error-password-not-saved = le mot de passe n'a pas pu être enregistré pour le prochain démarrage : { $error }
error-sign-in-not-saved = les nouvelles informations de connexion n’ont pas pu être enregistrées pour le prochain démarrage : { $error }
error-import-unreadable = { $path } ne peut pas être lu : { $error }
error-import-too-large = { $path } dépasse 50 Mo
error-import-not-mail = { $path } n'est pas un message électronique
error-list-answered = le serveur de la liste a répondu avec le code { $status }
error-not-built = le message n'a pas pu être créé
error-outbox-waits = { $count ->
    [one] le message attend dans la Boîte d'envoi et partira au prochain Envoyer/Recevoir
   *[other] { $count } messages attendent dans la Boîte d'envoi et partiront au prochain Envoyer/Recevoir
}
error-draft-not-removed = le brouillon précédent du message n'a pas pu être retiré des Brouillons : { $reason }
error-sent-but = le message a été envoyé, mais { $problem }
error-sent-still-in-outbox = il est toujours dans la Boîte d'envoi : { $error }
error-sent-no-copy = aucune copie n'a pu être enregistrée dans Éléments envoyés : { $reason }
error-no-password = aucun mot de passe pour ce compte
error-no-sign-in = aucune information de connexion enregistrée pour ce compte
error-provider-missing = cette version ne peut pas se connecter à { $provider } : son application de connexion a-t-elle été supprimée ?
error-provider-servers = les serveurs de ce compte ne correspondent pas à ceux de l’application de connexion
error-app-scopes = { $reason }. Le serveur de messagerie a refusé le jeton de l’application de connexion. Vérifiez que ses autorisations (scopes) permettent l’accès à la messagerie
error-in-folder = { $folder } : { $reason }

## Sign-in apps

sign-in-off-google = Google n'a pas encore validé Inbox Classic. Seuls les utilisateurs de test peuvent donc se connecter avec l’application intégrée. Utilisez votre propre application de connexion Google ou un mot de passe d'application. Si vous êtes un utilisateur de test, vous pouvez activer l’application intégrée dans Applications de connexion (Fichier > Comptes).
sign-in-off-other = Elle a été désactivée dans Applications de connexion (Fichier > Comptes), où vous pouvez la réactiver.
sign-in-app-no-name = l'application de connexion a besoin d'un nom
sign-in-app-no-client = l'ID client est manquant
sign-in-app-no-scopes = l’application de connexion doit disposer des autorisations (scopes) d’accès à la messagerie
sign-in-app-bad-host = l’adresse du serveur { $server } est manquante ou n’est pas un nom d’hôte valide
sign-in-app-plain = le serveur { $server } doit utiliser SSL/TLS ou STARTTLS
sign-in-app-not-checked = l'émetteur n'a pas encore été vérifié
sign-in-app-issuer-changed = l'émetteur a changé : saisissez à nouveau le secret client, ou supprimez-le
sign-in-register-google = Dans Google Cloud Console, créez un client OAuth de type Application de bureau, avec l’autorisation (scope) https://mail.google.com/ sur son écran de consentement. Tant que l'application est en test, seuls ses utilisateurs test peuvent se connecter.
sign-in-register-microsoft = Dans Microsoft Entra, inscrivez une application avec la plateforme Applications mobiles et de bureau, l'adresse de redirection http://localhost, les flux de clients publics autorisés et les autorisations déléguées IMAP.AccessAsUser.All, SMTP.Send et offline_access. Pour votre organisation uniquement, utilisez https://login.microsoftonline.com/<ID du locataire>/v2.0 comme émetteur.
sign-in-register-other = Inscrivez un client natif (public) avec l'adresse de redirection ci-dessous ; le fournisseur doit y autoriser n'importe quel port (RFC 8252). Ajoutez l’autorisation (scope) prévue par le fournisseur pour accéder à la messagerie.

## Calendar invitations

repeats = Se répète
repeats-every = { $unit ->
    [day] { $interval ->
        [one] Tous les jours
       *[other] Tous les { $interval } jours
    }
    [week] { $interval ->
        [one] Toutes les semaines
       *[other] Toutes les { $interval } semaines
    }
    [month] { $interval ->
        [one] Tous les mois
       *[other] Tous les { $interval } mois
    }
   *[year] { $interval ->
        [one] Tous les ans
       *[other] Tous les { $interval } ans
    }
}
repeats-on = { $repeats } : { $days }
repeats-times = { $count ->
    [one] { $repeats }, une fois
   *[other] { $repeats }, { $count } fois
}
day-monday = lundi
day-tuesday = mardi
day-wednesday = mercredi
day-thursday = jeudi
day-friday = vendredi
day-saturday = samedi
day-sunday = dimanche

## AI agents

agent-level-read = Lire le courrier : dossiers, liste des messages, recherche et messages
agent-level-organize = Gérer le courrier : marquer comme lu ou non lu, ajouter des indicateurs, gérer les indésirables, déplacer et supprimer des messages. Les messages supprimés vont dans Éléments supprimés.
agent-level-drafts = Rédiger des brouillons que vous enverrez vous-même
agent-level-send = Envoyer du courrier, chaque message seulement après votre accord
agent-connect-title = { $program } souhaite utiliser votre messagerie
agent-connect-detail = Un agent d'IA demande à travailler avec Inbox Classic. Choisissez ce qu'il peut faire et quels comptes il peut voir ; vous pourrez le modifier plus tard dans Outils > Agents d'IA.

    Les agents lisent du courrier écrit par d'autres personnes, et un message peut tenter de les tromper. Inbox Classic vous demande toujours votre accord avant qu'un agent envoie quoi que ce soit.
agent-reply-to = Réponse à « { $subject } »
agent-reply-all-on = Réponse à tous sur « { $subject } »
agent-forward-of = Transfert de « { $subject } »
agent-never-written-one = Vous n'avez jamais écrit à { $address }.
agent-never-written-many = Vous n'avez jamais écrit à { $count } de ces adresses.
agent-send-title = { $program } souhaite envoyer ce message
agent-send-detail = Vérifiez les destinataires et le contenu du message. Après votre confirmation, il reste { $seconds } secondes dans la Boîte d’envoi, où vous pouvez encore le supprimer.
agent-change-title = Ce que { $program } peut faire
agent-change-allowed = Modifiez ce que les agents d'IA de ce programme peuvent faire avec votre courrier.
agent-change-refused = Vous avez refusé l’accès à ce programme. Autorisez-le pour que ses agents puissent à nouveau accéder à votre courrier.
agent-log-taken-back = { $entry } (annulé)
agent-files = Fichiers : { $files }
agent-undo-refused = Impossible d'annuler.
agent-undo-refused-why = Impossible d'annuler : { $reason }.
agent-undo-impossible = cela ne peut pas être annulé
agent-undo-not-in-folder = le message n'est plus dans ce dossier
agent-undo-not-arrived = le message n'est pas (encore) dans son dossier de destination
agent-undo-sent = le message a déjà été envoyé
agent-original-not-downloaded = le message d’origine n’est pas encore téléchargé. Ouvrez-le d’abord
agent-turned-away = Refusé
agent-can-nothing = Rien
agent-can-read = lire
agent-can-organize = organiser
agent-can-drafts = écrire des brouillons
agent-can-send = envoyer avec votre accord
agent-can-list = { $first } et { $last }
agent-accounts = { $count ->
    [0] aucun compte
    [one] 1 compte
   *[other] { $count } comptes
}
agent-access = { $can } ; { $accounts }
agent-unreadable = Ce message ne peut pas être lu.
agent-log-composed = « { $subject } » ouvert dans un nouveau message que vous terminerez
agent-log-refused = Vous n'avez pas envoyé « { $subject } »
agent-log-sent = « { $subject } » envoyé à { $to }
agent-log-draft = Brouillon « { $subject } » enregistré
agent-log-read = « { $subject } » marqué comme lu
agent-log-unread = « { $subject } » marqué comme non lu
agent-log-flagged = Indicateur ajouté à « { $subject } »
agent-log-unflagged = Indicateur retiré de « { $subject } »
agent-log-deleted = « { $subject } » supprimé
agent-log-moved = « { $subject } » déplacé vers { $folder }
agent-log-junk = « { $subject } » marqué comme indésirable
agent-log-not-junk = « { $subject } » marqué comme non indésirable
# review: new
agent-log-archived = « { $subject } » archivé
agent-log-folder = Dossier « { $name } » créé
agent-log-unsubscribed = Désabonnement de la liste ayant envoyé « { $subject } »

## Keys

key-ctrl = Ctrl
key-alt = Alt
key-shift = Maj
key-del = Suppr
key-enter = Entrée

## Signing in and passwords

sign-in-no-refresh = le fournisseur n'a pas donné de jeton d'actualisation
sign-in-no-account = le fournisseur n'a pas indiqué quel compte s'est connecté
sign-in-not-finished = la connexion n'est pas terminée
secrets-unavailable = { $store } n'est pas disponible
secrets-unavailable-why = { $store } n'est pas disponible : { $error }
secrets-windows = le Gestionnaire d'identification
secrets-mac = le trousseau
secrets-linux = le trousseau du système (Secret Service)
error-no-such-file = ce fichier n'existe pas
