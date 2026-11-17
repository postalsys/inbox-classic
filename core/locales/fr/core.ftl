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
size-gb = { $size } Go
send-delay-off = Désactivé
send-delay-seconds = { $count ->
    [one] { $count } seconde
   *[other] { $count } secondes
}
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
reader-downloading-detail = Le message s'affichera ici une fois le téléchargement terminé.
reader-downloading-size = Le message fait { $size }. Il apparaîtra ici une fois téléchargé.
reader-failed = Le message n'a pas pu être téléchargé
reader-failed-network = Le serveur de messagerie est inaccessible ({ $reason }).
reader-failed-sign-in = Le serveur de messagerie a refusé la connexion ({ $reason }). Vérifiez le mot de passe ou reconnectez-vous dans Fichier > Comptes.
reader-failed-security = Impossible d'établir une connexion sécurisée au serveur de messagerie ({ $reason }).
reader-failed-other = Le serveur de messagerie a répondu : { $reason }.
reader-retry-note = Une nouvelle tentative aura lieu dès que la connexion au compte sera rétablie.
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
# review: new
header-security = Sécurité
# review: new
header-part = Partie { $number }
quote-original = ----- Message d'origine -----
fold-show-earlier = Afficher les messages précédents

## Messages non remis : la carte au-dessus d'un avis de non-remise

bounce-failed = Votre message n'a pas été remis
bounce-delayed = Votre message n'a pas encore été remis
bounce-delayed-note = Votre serveur de messagerie essaie toujours de le remettre. Vous n'avez pas besoin de le renvoyer.
bounce-show-message = Afficher le message non remis
# the link of a delay's card to the message that is still on its way
bounce-show-delayed = Afficher le message en attente de remise
bounce-what-to-do = Ce que vous pouvez faire :
bounce-delayed-do = Vous n'avez rien à faire pour l'instant. Si le message ne peut pas être remis, vous recevrez un nouvel avis.
bounce-delayed-row-do = Vous n'avez rien à faire pour l'instant. Votre serveur de messagerie poursuit ses tentatives de remise. Vous recevrez un nouvel avis s'il n'y parvient pas.
bounce-details = Détails
bounce-someone = Un destinataire
bounce-server = Serveur : { $server }
bounce-status = État : { $status }
bounce-reported-by = Signalé par : { $server }
bounce-retry-minutes = Le serveur de réception a demandé d'attendre { $count ->
    [one] une minute
   *[other] { $count } minutes
} avant le prochain essai.
bounce-retry-hours = Le serveur de réception a demandé d'attendre { $count ->
    [one] une heure
   *[other] { $count } heures
} avant le prochain essai.
bounce-blocklist = Liste de blocage : { $lists }
bounce-user-unknown = L'adresse n'existe pas
bounce-user-unknown-why = Le serveur de réception ne possède aucune boîte aux lettres à cette adresse. L'adresse contient peut-être une faute de frappe ou n'est plus utilisée par le destinataire.
bounce-user-unknown-do = Vérifiez l'orthographe de l'adresse ou demandez au destinataire son adresse e-mail actuelle.
bounce-invalid-address = L'adresse n'est pas valide
bounce-invalid-address-why = Le format de l'adresse est incorrect. Aucun message ne peut être envoyé à cette adresse.
bounce-invalid-address-do = Vérifiez qu'il n'y a pas d'espaces superflus ni de lettres manquantes et qu'un nom de domaine figure après le signe @.
bounce-mailbox-disabled = La boîte aux lettres est désactivée
bounce-mailbox-disabled-why = L'adresse existe, mais sa boîte aux lettres a été désactivée ou n'est plus utilisée.
bounce-mailbox-disabled-do = Contactez le destinataire par un autre moyen et demandez-lui son adresse e-mail actuelle.
bounce-mailbox-full = La boîte aux lettres est pleine
bounce-mailbox-full-why = La boîte aux lettres du destinataire n'a plus de place pour de nouveaux messages.
bounce-mailbox-full-do = Renvoyez le message dans quelques jours ou prévenez le destinataire par un autre moyen. Les messages contenant des pièces jointes volumineuses sont refusés en premier.
bounce-spam-blocked = Refusé comme courrier indésirable
bounce-spam-blocked-why = Le serveur de réception a pris le message pour du courrier indésirable.
bounce-spam-blocked-do = Retirez les éléments susceptibles de faire classer le message comme indésirable, par exemple les liens trop nombreux ou raccourcis et les pièces jointes volumineuses, puis renvoyez-le. Si le problème persiste, contactez votre fournisseur de messagerie.
bounce-virus-detected = Refusé en raison d'un virus
bounce-virus-detected-why = Le serveur de réception a trouvé un virus ou un autre contenu dangereux dans le message ou ses pièces jointes.
bounce-virus-detected-do = Vérifiez les pièces jointes avec un antivirus. Certains serveurs refusent tout programme ou toute archive : partagez plutôt ces fichiers par un lien.
bounce-ip-blocklisted = Votre serveur de messagerie est sur une liste de blocage
bounce-ip-blocklisted-why = Le serveur de réception refuse les messages de votre serveur de messagerie, car son adresse IP figure sur une liste de blocage.
bounce-ip-blocklisted-do = Le message n'est pas en cause. Transférez cet avis à votre fournisseur de messagerie et demandez-lui de faire retirer le serveur de la liste.
bounce-domain-blocklisted = Un domaine est sur une liste de blocage
bounce-domain-blocklisted-why = Le serveur de réception refuse le message car le domaine de votre adresse, ou un domaine des liens du message, est sur une liste de blocage.
bounce-domain-blocklisted-do = Si le message contient des liens, essayez de l'envoyer sans ces liens. Si cela ne résout pas le problème ou si le message ne contient pas de liens, transmettez cet avis à la personne qui gère la messagerie de votre domaine.
bounce-policy-blocked = Refusé en application des règles du serveur de réception
bounce-policy-blocked-why = Les règles du serveur de réception ne laissent pas passer ce message, par exemple à cause de sa taille, de ses pièces jointes ou de son expéditeur.
bounce-policy-blocked-do = La réponse du serveur, dans la section Détails, indique souvent la raison du refus. Demandez au destinataire si sa messagerie accepte ce type de message.
bounce-geo-blocked = Refusé en raison de sa provenance
bounce-geo-blocked-why = Le serveur de réception n'accepte pas le courrier du pays ou du réseau où se trouve votre serveur de messagerie.
bounce-geo-blocked-do = Contactez le destinataire par un autre moyen ou demandez de l'aide à votre fournisseur de messagerie.
bounce-relay-denied = Le serveur a refusé de relayer le message
bounce-relay-denied-why = Un serveur a refusé de relayer le message, souvent parce qu'il a été envoyé sans authentification ou par un serveur qui ne prend pas en charge ce destinataire.
bounce-relay-denied-do = Dans Fichier > Comptes, vérifiez les paramètres du serveur sortant et assurez-vous que l'authentification auprès de ce serveur est configurée.
bounce-auth-failure = Votre adresse d'expéditeur n'a pas pu être vérifiée
bounce-auth-failure-why = Le serveur de réception n'a pas pu confirmer que le message venait bien de votre domaine (SPF, DKIM ou DMARC).
bounce-auth-failure-do = Transmettez cet avis à la personne qui gère la messagerie de votre domaine pour qu'elle en corrige les paramètres. En attendant, essayez d'envoyer le message via le serveur de votre fournisseur.
bounce-rate-limited = Trop de messages à la fois
bounce-rate-limited-why = Le serveur de réception limite temporairement le nombre de messages acceptés en provenance de votre serveur de messagerie.
bounce-rate-limited-do = Patientez un moment, puis renvoyez le message. Si vous écrivez à de nombreuses personnes, réduisez le nombre de destinataires par envoi.
bounce-greylisting = Remise temporairement différée
bounce-greylisting-why = Le serveur de réception demande aux expéditeurs inconnus de réessayer un peu plus tard. Il s'agit d'une mesure courante de protection contre le courrier indésirable.
bounce-greylisting-do = Vous n'avez rien à faire. Les serveurs de messagerie réessaient automatiquement, et le message est généralement remis dans l'heure.
bounce-server-error = Le serveur de réception a eu un problème
bounce-server-error-why = Le serveur de réception n'a pas pu être joint, ou n'a pas pu accepter le message à cause d'un problème de son côté.
bounce-server-error-do = Renvoyez le message plus tard. Si le problème persiste, vérifiez que la partie de l'adresse située après le signe @ ne contient pas de fautes de frappe.
bounce-unknown = Non remis
bounce-unknown-why = L'avis ne précise pas clairement la raison de l'échec.
bounce-unknown-do = La réponse du serveur, dans la section Détails, peut fournir des précisions. Si cela ne vous aide pas, transmettez cet avis à votre fournisseur de messagerie.

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
done-watched = { $count ->
    [one] Conversation surveillée
   *[other] { $count } conversations surveillées
}
done-unwatched = { $count ->
    [one] La conversation n'est plus surveillée
   *[other] Les { $count } conversations ne sont plus surveillées
}
done-ignored = { $count ->
    [one] Conversation ignorée
   *[other] { $count } conversations ignorées
}
done-unignored = { $count ->
    [one] La conversation n'est plus ignorée
   *[other] Les { $count } conversations ne sont plus ignorées
}
their-folders = leurs dossiers
undo-move = Annuler le déplacement
undo-delete = Annuler la suppression
undo-archive = Annuler l'archivage
undo-junk = Annuler le marquage comme indésirable
undo-not-junk = Annuler le marquage comme non indésirable
undo-send = Annuler l’envoi
nothing-to-undo = Il n'y a rien à annuler.
messages-gone = Les messages ne sont plus là.
folder-holds-no-messages = Ce dossier ne peut pas contenir de messages.
not-archived-here = Les messages de ce dossier ne peuvent pas être archivés.
not-emptied-here = Seuls les dossiers Éléments supprimés et Courrier indésirable peuvent être vidés.
next-unread-question = Il n'y a plus de messages non lus dans { $folder }.

    Ouvrir { $next }, le prochain dossier contenant des messages non lus ?
no-unread-left = Il ne reste aucun message non lu.
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
} ajouté à { $messages }
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
download-progress = Téléchargement : { $done } sur { $total }
download-done = Téléchargé : { $size }
downloading-messages = { $count ->
    [one] Téléchargement de { $messages }...
   *[other] Téléchargement de { $messages }...
}
import-put = { $count ->
    [one] { $messages } placé dans { $folder }
   *[other] { $messages } placés dans { $folder }
}
import-not-put = Les messages suivants n'ont pas pu être importés :

    { $problems }

## Problems the windows show

error-store = stockage local : { $error }
error-not-found = introuvable
error-closed = fermeture en cours
error-other-account = le navigateur s'est connecté à { $email }, pas à ce compte
# a password or sign-in the mail server refused, with the server's words
failure-authentication = le serveur a refusé la connexion ({ $reason })
# the mail server could not be reached or the connection broke, with the reason
failure-network = la connexion au serveur a échoué ({ $reason })
error-in-use = impossible de la supprimer tant que des comptes l'utilisent pour se connecter : { $accounts }
error-turned-off = cette application de connexion est désactivée pour les nouveaux comptes
error-folder-name = le nom du dossier doit comporter de 1 à 200 caractères, sans caractères de contrôle
error-folder-separator = un nom de dossier ne peut pas contenir « { $separator } » sur ce serveur
error-folder-special = la Boîte de réception et les dossiers spéciaux ne peuvent pas être renommés ni supprimés
error-no-recipients = le message n'a aucun destinataire
error-bad-address = « { $address } » n'est pas une adresse de messagerie
error-not-own-address = { $address } ne fait pas partie des adresses d’envoi de ce compte. Ajoutez-la au champ « Autres adresses d’envoi » dans les propriétés du compte.
rule-query-refused = Les règles n’acceptent pas les filtres de dossier ou de date ({ $words }).
rule-no-query = Saisissez les critères de recherche pour les messages entrants.
rule-no-action = Choisissez au moins une action pour la règle.
error-attachment = { $path } n'a pas pu être lu : { $error }
error-no-drafts = le compte n'a pas de dossier Brouillons où enregistrer le message
error-draft-attachment = une pièce jointe du brouillon n'a pas pu être conservée : { $error }
error-password-not-saved = le mot de passe n'a pas pu être enregistré pour le prochain démarrage : { $error }
error-sign-in-not-saved = les nouvelles informations de connexion n'ont pas pu être enregistrées pour le prochain démarrage : { $error }
error-import-unreadable = { $path } ne peut pas être lu : { $error }
error-import-too-large = { $path } dépasse 50 Mo
error-import-not-mail = { $path } n'est pas un message électronique
error-list-answered = le serveur de la liste a répondu avec le code { $status }
error-not-built = le message n'a pas pu être créé
error-outbox-waits = { $count ->
    [one] le message est en attente dans la Boîte d'envoi et sera envoyé lors de la prochaine opération d'envoi et de réception
   *[other] { $count } messages sont en attente dans la Boîte d'envoi et seront envoyés lors de la prochaine opération d'envoi et de réception
}
error-draft-not-removed = le brouillon précédent du message n'a pas pu être retiré des Brouillons : { $reason }
error-sent-but = le message a été envoyé, mais { $problem }
error-sent-still-in-outbox = il est toujours dans la Boîte d'envoi : { $error }
error-sent-no-copy = aucune copie n'a pu être enregistrée dans Éléments envoyés : { $reason }
error-no-password = aucun mot de passe pour ce compte
error-no-sign-in = aucune information de connexion enregistrée pour ce compte
error-provider-missing = cette version ne peut pas se connecter à { $provider } : son application de connexion a-t-elle été supprimée ?
error-provider-servers = les serveurs de ce compte ne correspondent pas à ceux de l'application de connexion
error-app-scopes = { $reason }. Le serveur de messagerie a refusé le jeton de l'application de connexion. Vérifiez que ses autorisations (scopes) permettent l'accès à la messagerie
error-in-folder = { $folder } : { $reason }

## Sign-in apps

sign-in-off-google = Google n'a pas encore validé Inbox Classic. Seuls les utilisateurs de test peuvent donc se connecter avec l'application intégrée. Utilisez votre propre application de connexion Google ou un mot de passe d'application. Si vous êtes un utilisateur de test, vous pouvez activer l'application intégrée dans Applications de connexion (Fichier > Comptes).
sign-in-off-other = Elle a été désactivée dans Applications de connexion (Fichier > Comptes), où vous pouvez la réactiver.
sign-in-app-no-name = l'application de connexion a besoin d'un nom
sign-in-app-no-client = l'ID client est manquant
sign-in-app-no-scopes = l'application de connexion doit disposer des autorisations (scopes) d'accès à la messagerie
sign-in-app-bad-host = l'adresse du serveur { $server } est manquante ou n'est pas un nom d'hôte valide
sign-in-app-plain = le serveur { $server } doit utiliser SSL/TLS ou STARTTLS
sign-in-app-not-checked = l'émetteur n'a pas encore été vérifié
sign-in-app-issuer-changed = l'émetteur a changé : saisissez à nouveau le secret client, ou supprimez-le
sign-in-register-google = Dans Google Cloud Console, créez un client OAuth de type Application de bureau, avec l'autorisation (scope) https://mail.google.com/ sur son écran de consentement. Tant que l'application est en test, seuls ses utilisateurs test peuvent se connecter.
sign-in-register-microsoft = Dans Microsoft Entra, inscrivez une application avec la plateforme Applications mobiles et de bureau, l'adresse de redirection http://localhost, les flux de clients publics autorisés et les autorisations déléguées IMAP.AccessAsUser.All, SMTP.Send et offline_access. Pour votre organisation uniquement, utilisez https://login.microsoftonline.com/<ID du locataire>/v2.0 comme émetteur.
sign-in-register-other = Inscrivez un client natif (public) avec l'adresse de redirection ci-dessous ; le fournisseur doit y autoriser n'importe quel port (RFC 8252). Ajoutez l'autorisation (scope) prévue par le fournisseur pour accéder à la messagerie.

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

agent-level-read = Lire le courrier : consulter les dossiers et les messages, et effectuer des recherches
# review: changed
agent-level-organize = Gérer le courrier : marquer comme lu ou non lu, ajouter des indicateurs, gérer les indésirables, déplacer, archiver et supprimer des messages, créer des dossiers, et se désabonner de listes de diffusion après votre accord. Les messages supprimés vont dans Éléments supprimés.
agent-level-drafts = Rédiger des brouillons que vous enverrez vous-même
agent-level-send = Envoyer du courrier, chaque message seulement après votre accord
agent-connect-title = { $program } souhaite utiliser votre messagerie
agent-connect-detail = Un agent d'IA souhaite accéder à Inbox Classic. Choisissez les actions autorisées et les comptes auxquels il peut accéder. Vous pourrez modifier ces autorisations dans Outils > Agents d'IA.

    Les agents lisent des messages écrits par d'autres personnes. Ces messages peuvent contenir des instructions destinées à tromper les agents. Inbox Classic vous demande toujours votre accord avant qu'un agent envoie un message.
agent-reply-to = Réponse à « { $subject } »
agent-reply-all-on = Réponse à tous sur « { $subject } »
agent-forward-of = Transfert de « { $subject } »
agent-never-written-one = Vous n'avez jamais écrit à { $address }.
agent-never-written-many = Vous n'avez jamais écrit à { $count } de ces adresses.
agent-send-title = { $program } souhaite envoyer ce message
agent-send-detail = Vérifiez les destinataires et le contenu du message. Après votre confirmation, il reste { $seconds } secondes dans la Boîte d'envoi, où vous pouvez encore le supprimer.
agent-change-title = Ce que { $program } peut faire
agent-change-allowed = Modifiez ce que les agents d'IA de ce programme peuvent faire avec votre courrier.
agent-change-refused = Vous avez refusé l'accès à ce programme. Autorisez-le pour que ses agents puissent à nouveau accéder à votre courrier.
agent-log-taken-back = { $entry } (annulé)
agent-files = Fichiers : { $files }
agent-undo-refused = Impossible d'annuler.
agent-undo-refused-why = Impossible d'annuler : { $reason }.
agent-undo-impossible = cela ne peut pas être annulé
agent-undo-not-in-folder = le message n'est plus dans ce dossier
agent-undo-not-arrived = le message n'est pas (encore) dans son dossier de destination
agent-undo-sent = le message a déjà été envoyé
agent-original-not-downloaded = le message d'origine n'est pas encore téléchargé. Ouvrez-le d'abord
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
# review: new
agent-encrypted-original = Ce message est chiffré : un agent ne peut ni y répondre ni le transférer, car il ne peut pas chiffrer.
# review: new
agent-encrypted = Ce message est chiffré. Seul l’utilisateur peut le lire, dans Inbox Classic.
# review: new
list-encrypted = Message chiffré
agent-log-composed = « { $subject } » ouvert dans un nouveau message à compléter
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
agent-log-archived = « { $subject } » archivé
agent-log-folder = Dossier « { $name } » créé
agent-log-unsubscribed = Désabonnement de la liste ayant envoyé « { $subject } »
# review: new
agent-log-unsubscribe-failed = Impossible de se désabonner de la liste ayant envoyé « { $subject } » : { $reason }
# review: new
agent-log-unsubscribe-refused = Vous avez refusé le désabonnement de { $senders }
# review: new
agent-unsubscribe-title = { $count ->
    [one] { $program } souhaite vous désabonner d'une liste de diffusion
   *[other] { $program } souhaite vous désabonner de { $count } listes de diffusion
}
# review: new
agent-unsubscribe-detail = { $count ->
    [1] Inbox Classic demande à la liste ci-dessous de ne plus vous écrire, par le désabonnement en un clic qu'elle propose. Rien d'autre n'est envoyé, et les messages que vous avez restent où ils sont.
   *[other] Inbox Classic demande à chaque liste ci-dessous de ne plus vous écrire, par le désabonnement en un clic qu'elle propose. Rien d'autre n'est envoyé, et les messages que vous avez restent où ils sont.
}

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
cards-file-too-big = Ce fichier est trop volumineux pour être importé comme carnet d'adresses.
ui-sender-added = { $name } a été ajouté au carnet d'adresses.
ui-sender-known = { $name } est déjà dans le carnet d'adresses.
ui-sender-none = L'expéditeur de ce message n'a pas d'adresse e-mail à ajouter.
card-name-needed = Le contact n'a ni nom ni adresse e-mail.
# a file of Import Address Book that could not be read: "contacts.vcf: there is no such file"
cards-file-failed = { $file } : { $reason }

otp-heading = Code de { $domain }
otp-copy = Copier
otp-note = Saisissez-le uniquement sur une page de { $domain }.
otp-old = Ce code a été envoyé plus d'une heure avant l'ouverture de ce message et a probablement expiré.

event-attendees =
    { $count ->
        [one] { $count } participant
       *[other] { $count } participants
    }

otp-notification = { $code } est votre code pour { $domain }

## OpenPGP keys (keys.rs)
# review: new
pgp-key-valid = Valide
# review: new
pgp-key-expires = Valide jusqu'au { $date }
# review: new
pgp-key-expired = Expirée le { $date }
# review: new
pgp-key-revoked = Révoquée
# review: new
pgp-key-revoked-why = Révoquée : { $reason }
# review: new
pgp-key-not-valid = Non valide
# review: new
pgp-key-locked = Inutilisable : la clé qui la protège n'est plus dans { $store }. Importez à nouveau sa sauvegarde.
# review: new
pgp-source-own = Créée dans Inbox Classic
# review: new
pgp-source-file = Importée depuis un fichier
# review: new
pgp-source-paste = Collée
# review: new
pgp-source-attachment = Depuis un message
# review: new
pgp-source-vcard = Depuis une carte de contact
# review: new
pgp-source-wkd = Depuis le fournisseur de messagerie de l'expéditeur
# review: new
pgp-source-keyserver = Depuis keys.openpgp.org
# review: new
pgp-source-autocrypt = Depuis l'en-tête Autocrypt d'un message
# review: new
pgp-error-no-store = Les clés privées sont protégées par { $store }, qui ne peut pas être utilisé : { $error }
# review: new
pgp-error-wrong-passphrase = La phrase secrète n'est pas correcte.
# review: new
# review: new
pgp-error-not-a-key = Ceci n'est pas une clé OpenPGP.
# review: new
pgp-error-too-large = La clé est trop grande.
# review: new
pgp-error-unusable = La clé utilise une cryptographie ancienne ou faible et ne peut pas être utilisée.
# review: new
pgp-imported-private = { $count ->
    [one] Votre clé privée a été importée.
   *[other] { $count } clés privées ont été importées.
}
# review: new
pgp-imported-public = { $count ->
    [one] Une clé a été importée.
   *[other] { $count } clés ont été importées.
}
# review: new
pgp-imported-pending = Une autre clé est déjà utilisée pour { $addresses } : la nouvelle attend dans le contact jusqu'à ce que vous la choisissiez.
# review: new
pgp-error-needs-passphrase = La clé privée est protégée par une phrase secrète. Saisissez-la pour importer la clé.
# review: new
pgp-error-mismatch = La clé privée ne correspond pas à sa clé publique. Elle a peut-être été modifiée.
# review: new
pgp-file-name-public = Clé publique de { $who }.asc
# review: new
pgp-file-name-private = Sauvegarde de la clé privée de { $who }.asc
# review: new
pgp-pending = Une autre clé pour { $address } a été trouvée le { $date }.

## Reading signed and encrypted mail (protect.rs)
# review: new
pgp-part-verified = Signé par { $signer }, clé vérifiée
# review: new
pgp-part-signed = Signé par { $signer } (clé non vérifiée)
# review: new
pgp-part-other = Signé par { $signer }, qui n'est pas l'expéditeur
# review: new
pgp-part-unknown-key = Signé, mais la clé n'est pas connue
# review: new
pgp-part-not-signed = Non signé
# review: new
pgp-part-not-checked = Signature non vérifiée
# review: new
pgp-part-encrypted = Chiffré. { $signature }
# review: new
pgp-part-no-key = Chiffré pour une clé que vous n'avez pas
# review: new
pgp-part-changed = La partie chiffrée a été modifiée en route et n'est pas affichée
# review: new
pgp-part-unprotected = Chiffré sans protection contre les modifications, non affiché
# review: new
pgp-part-broken = La partie chiffrée ne peut pas être lue
# review: new
pgp-why-mismatch = La signature ne correspond pas à ce texte
# review: new
pgp-why-weak-hash = La signature utilise { $hash }, qui n'est plus sûr
# review: new
pgp-why-key-expired = Signé après l'expiration de la clé le { $date }
# review: new
pgp-why-key-revoked = Signé avec une clé révoquée
# review: new
pgp-why-not-signing-key = Signé avec une clé qui ne peut pas signer
# review: new
pgp-why-from-future = La signature est datée dans le futur
# review: new
pgp-why-signature-expired = La signature a expiré
# review: new
pgp-why-key-not-valid = Signé avec une clé non valide
# review: new
pgp-why-not-for-you = Signé pour d'autres destinataires et transmis à vous
# review: new
pgp-why-not-key-in-use = Signé avec une autre clé que celle utilisée pour { $address }
# review: new
pgp-part-pictures-loaded = { $label }. Des images ont été chargées depuis Internet
# review: new
pgp-error-no-own-key = Vous n'avez pas de clé pour { $address } pour signer ou chiffrer. Créez-en une dans Outils > Clés de chiffrement, ou désactivez Signer et Chiffrer.
# review: new
pgp-error-missing-keys = { $count ->
    [one] { $addresses } n'a pas de clé pour chiffrer.
   *[other] Ces destinataires n'ont pas de clé pour chiffrer : { $addresses }.
}
# review: new
pgp-error-encrypted-quote = Ce message cite ou transfère un message chiffré : il ne peut être envoyé que chiffré. Activez Chiffrer, ou supprimez le texte cité.
# review: new
pgp-error-protect = Le message n’a pas pu être signé ou chiffré : { $reason }
# review: new
pgp-found-keys = La clé de { $addresses } a été trouvée.
# review: new
pgp-found-none = Aucune clé n'a été trouvée pour { $addresses }. Demandez-lui de vous envoyer sa clé publique.
# review: new
pgp-found-no-key = Aucune clé n'a été trouvée.
# review: new
pgp-find-unavailable = Les clés ne peuvent pas être recherchées pour l'instant : { $error }
# review: new
pgp-publish-pending = keys.openpgp.org a envoyé un lien de confirmation à { $addresses }. Votre clé y est publiée dès que vous cliquez dessus.
# review: new
pgp-publish-done = Votre clé est publiée sur keys.openpgp.org pour { $addresses }.
# review: new
pgp-publish-failed = La clé n'a pas pu être publiée : { $error }
# review: changed
pgp-keyserver-off = La recherche de clés sur keys.openpgp.org est désactivée dans { $settings }.
# the compose window with Sign and Encrypt: the line under the fields, each recipient's key, the questions
# review: new
pgp-compose-encrypted = { $count ->
    [one] Chiffré et signé : seuls vous et { $addresses } pouvez le lire.
   *[other] Chiffré et signé : seuls vous et ses { $count } destinataires pouvez le lire.
}
# review: new
pgp-compose-encrypt-ready = Le message sera chiffré et signé. Ajoutez des destinataires dont vous avez la clé.
# review: new
pgp-compose-missing = { $count ->
    [one] { $addresses } n’a pas de clé, le message ne peut donc pas encore être chiffré.
   *[other] { $count } destinataires n’ont pas de clé, le message ne peut donc pas encore être chiffré : { $addresses }.
}
# review: new
pgp-compose-looking = Recherche des clés de { $addresses }...
# review: new
pgp-compose-signed = Signé : les destinataires peuvent vérifier qu’il vient de vous et qu’il n’a pas été modifié.
# review: new
pgp-compose-reply-clear = Non chiffré, alors que le message auquel il répond ou qu’il transfère l’était.
# review: new
pgp-compose-encrypted-files = Des fichiers d’un message chiffré sont joints : ce message ne peut donc être envoyé que chiffré. Activez Chiffrer, ou supprimez ces fichiers.
# review: new
pgp-compose-sign-tip = Signer le message avec votre clé, pour que les destinataires puissent vérifier qu’il vient de vous et qu’il n’a pas été modifié
# review: new
pgp-compose-sign-tip-encrypted = Un message chiffré est toujours signé
# review: new
pgp-compose-encrypt-tip = Chiffrer le message, pour que seuls vous et ses destinataires puissiez le lire
# review: new
pgp-compose-make-key = Vous n’avez pas encore de clé pour { $address }. En créer une maintenant ? Avec elle, vos messages peuvent être signés et chiffrés.
# review: new
pgp-compose-key-unusable = Votre clé pour { $address } ne peut pas être utilisée ({ $state }). Ouvrez Clés de chiffrement pour importer sa sauvegarde ou créer une nouvelle clé.
# review: new
pgp-compose-encrypt-off-quote = Ce message cite ou transfère un message chiffré. Sans chiffrement, il ne pourra pas être envoyé tant que vous n’aurez pas supprimé ce qu’il cite. Désactiver quand même le chiffrement ?
# review: new
pgp-compose-encrypt-off-reply = Ce message répond à un message chiffré ou le transfère. Sans chiffrement, toute personne qui traite votre message en chemin peut le lire. Désactiver le chiffrement ?
# review: new
pgp-recipient-verified = Clé vérifiée
# review: new
pgp-recipient-found = Clé non vérifiée
# review: new
pgp-recipient-own = Votre propre clé
# review: new
pgp-recipient-looking = Recherche d’une clé...
# review: new
pgp-recipient-missing = Aucune clé
# review: new
pgp-recipient-not-found = Aucune clé : aucune n’a été trouvée le { $date }
# review: new
pgp-recipient-unusable = Clé inutilisable : { $state }
# review: new
pgp-recipients-intro = Le message est chiffré pour la clé de chaque destinataire, et pour la vôtre.
# review: new
pgp-recipients-intro-missing = { $count ->
    [one] { $count } destinataire n’a pas de clé pour chiffrer. Trouvez sa clé, retirez-le de ce message, ou envoyez celui-ci sans chiffrement.
   *[other] { $count } destinataires n’ont pas de clé pour chiffrer. Trouvez leurs clés, retirez-les de ce message, ou envoyez celui-ci sans chiffrement.
}
# review: new
pgp-details-part = Partie { $number } : { $label }
# review: new
pgp-details-signed = Signé { $when } avec la clé { $key }
# review: new
pgp-details-unknown-key = Signé avec la clé { $key }, que vous n’avez pas
# review: new
pgp-details-opened = Chiffré pour votre clé { $key }
# review: new
pgp-details-for = Chiffré pour { $keys }
# review: new
pgp-details-plain = Ni signé ni chiffré
# review: new
pgp-bar-parts = Ce message a { $count } parties : { $list }. Chaque partie indique comment elle est protégée.
# review: new
pgp-bar-count-verified = { $count ->
    [one] 1 vérifiée
   *[other] { $count } vérifiées
}
# review: new
pgp-bar-count-good = { $count ->
    [one] 1 signée ou chiffrée
   *[other] { $count } signées ou chiffrées
}
# review: new
pgp-bar-count-warning = { $count ->
    [one] 1 demande votre attention
   *[other] { $count } demandent votre attention
}
# review: new
pgp-bar-count-neutral = { $count } sans signature confirmée
# the setup file: settings, accounts, contacts and keys carried to another computer
# review: new
setup-part-settings = Paramètres
# review: new
setup-part-preferences = Préférences des fenêtres
# review: new
setup-part-accounts = Comptes
# review: new
setup-part-sign-in-apps = Applications de connexion
# review: new
setup-part-contacts = Contacts et groupes
# review: new
setup-part-keys = Clés de chiffrement
# review: new
setup-part-rules = Règles de message
# review: new
setup-part-trusted-senders = Expéditeurs de confiance
# review: new
setup-holds-settings = { $count ->
    [one] { $count } paramètre
   *[other] { $count } paramètres
}
# review: new
setup-holds-preferences = { $count ->
    [one] { $count } préférence
   *[other] { $count } préférences
}
# review: new
setup-holds-accounts = { $count ->
    [one] { $count } compte
   *[other] { $count } comptes
}
# review: new
setup-holds-sign-in-apps = { $count ->
    [one] { $count } application de connexion
   *[other] { $count } applications de connexion
}
# review: new
setup-holds-built-in = Les applications de connexion intégrées activées
# review: new
setup-holds-contacts = { $count ->
    [one] { $count } contact
   *[other] { $count } contacts
}
# review: new
setup-holds-groups = { $count ->
    [one] { $count } groupe
   *[other] { $count } groupes
}
# review: new
setup-holds-own-keys = { $count ->
    [one] { $count } clé personnelle
   *[other] { $count } clés personnelles
}
# review: new
setup-holds-contact-keys = { $count ->
    [one] { $count } clé de contact
   *[other] { $count } clés de contacts
}
# review: new
setup-holds-rules = { $count ->
    [one] { $count } règle
   *[other] { $count } règles
}
# review: new
setup-holds-trusted-senders = { $count ->
    [one] { $count } expéditeur de confiance
   *[other] { $count } expéditeurs de confiance
}
# review: new
setup-sign-in-password = Mot de passe
# review: new
setup-account-secret-password = Son mot de passe est dans le fichier.
# review: new
setup-account-secret-token = Sa connexion est dans le fichier.
# review: new
setup-account-asks-password = Il demandera son mot de passe après l'importation.
# review: new
setup-account-signs-in-again = Vous vous y reconnecterez après l'importation.
# review: new
setup-account-here = Il est déjà configuré ici, il sera donc ignoré.
# review: new
setup-account-no-app = Il se connecte avec { $app }, qui n'est pas configurée ici. Importez aussi les applications de connexion.
# review: new
setup-invalid-address = « { $address } » n'est pas une adresse e-mail.
# review: new
setup-invalid-server = Le serveur { $server } n'a pas de nom ou de port utilisable.
# review: new
setup-invalid-user = Il n'a pas de nom d'utilisateur.
# review: new
setup-invalid-sign-in = Il se connecte d'une manière qu'Inbox Classic ne connaît pas.
# review: new
setup-error-empty = Le fichier est vide.
# review: new
setup-error-too-large = Le fichier est trop volumineux pour être une configuration d'Inbox Classic.
# review: new
setup-error-not-setup = Ce fichier n'est pas une configuration d'Inbox Classic.
# review: new
setup-error-damaged = Le fichier de configuration est endommagé et ne peut pas être lu.
# review: new
setup-error-newer = Cette configuration a été enregistrée par une version plus récente d'Inbox Classic ({ $version }). Mettez Inbox Classic à jour, puis importez-la de nouveau.
# review: new
setup-error-needs-passphrase = Cette configuration est protégée par une phrase secrète. Tapez la phrase secrète avec laquelle elle a été enregistrée.
# review: new
setup-error-wrong-passphrase = Ce n'est pas la phrase secrète avec laquelle cette configuration a été enregistrée.
# review: new
setup-error-changed = Le fichier de configuration a été modifié ou endommagé après son enregistrement, il ne peut donc pas être importé.
# review: new
setup-error-read = Le fichier de configuration n'a pas pu être lu : { $error }
# review: new
setup-error-write = La configuration n'a pas pu être enregistrée : { $error }
# review: new
setup-error-no-parts = Choisissez au moins une partie.
# review: new
setup-left-out = { $count ->
    [one] { $count } élément de « { $part } » n'est pas utilisable et est laissé de côté.
   *[other] { $count } éléments de « { $part } » ne sont pas utilisables et sont laissés de côté.
}
# review: new
setup-imported-settings = Les paramètres ont été remplacés.
# review: new
setup-imported-preferences = Les préférences des fenêtres ont été remplacées.
# review: new
setup-added-accounts = { $count ->
    [one] { $count } compte ajouté.
   *[other] { $count } comptes ajoutés.
}
# review: new
setup-skipped-here = { $address } est déjà configuré ici, il a donc été ignoré.
# review: new
setup-skipped-no-app = { $address } a été ignoré : il se connecte avec { $app }, qui n'est pas configurée ici.
# review: new
setup-skipped-invalid = { $address } a été ignoré : { $reason }
# review: new
setup-asks-password = { $address } demandera son mot de passe à la connexion.
# review: new
setup-signs-in-again = { $address } vous demandera de vous reconnecter à la connexion.
# review: new
setup-added-sign-in-apps = { $count ->
    [one] { $count } application de connexion ajoutée.
   *[other] { $count } applications de connexion ajoutées.
}
# review: new
setup-skipped-sign-in-apps = { $count ->
    [one] { $count } application de connexion est déjà configurée ici.
   *[other] { $count } applications de connexion sont déjà configurées ici.
}
# review: new
setup-added-contacts = { $count ->
    [one] { $count } contact ajouté au carnet d'adresses.
   *[other] { $count } contacts ajoutés au carnet d'adresses.
}
# review: new
setup-skipped-contacts = { $count ->
    [one] { $count } contact est déjà dans le carnet d'adresses.
   *[other] { $count } contacts sont déjà dans le carnet d'adresses.
}
# review: new
setup-added-groups = { $count ->
    [one] { $count } groupe ajouté ou complété.
   *[other] { $count } groupes ajoutés ou complétés.
}
# review: new
setup-added-own-keys = { $count ->
    [one] { $count } clé personnelle ajoutée.
   *[other] { $count } clés personnelles ajoutées.
}
# review: new
setup-added-contact-keys = { $count ->
    [one] { $count } clé de contact ajoutée.
   *[other] { $count } clés de contacts ajoutées.
}
# review: new
setup-added-rules = { $count ->
    [one] { $count } règle de message ajoutée.
   *[other] { $count } règles de message ajoutées.
}
# review: new
setup-skipped-rules = { $count ->
    [one] { $count } règle de message existe déjà ici.
   *[other] { $count } règles de message existent déjà ici.
}
# review: new
setup-skipped-rules-account = { $count ->
    [one] { $count } règle de message concerne un compte absent d'ici, elle a donc été ignorée.
   *[other] { $count } règles de message concernent des comptes absents d'ici, elles ont donc été ignorées.
}
# review: new
setup-rules-waiting = { $count ->
    [one] { $count } règle de message déplace des messages vers un dossier qui apparaîtra une fois son compte synchronisé.
   *[other] { $count } règles de message déplacent des messages vers des dossiers qui apparaîtront une fois leurs comptes synchronisés.
}
# review: new
setup-added-trusted-senders = { $count ->
    [one] { $count } expéditeur de confiance ajouté.
   *[other] { $count } expéditeurs de confiance ajoutés.
}
# review: new
setup-nothing = Rien n'a été importé.
# review: new
setup-account-servers = { $imap } et { $smtp } ({ $signin })
# review: new
setup-file-name = Paramètres et comptes Inbox Classic
# review: new
setup-skipped-unreachable = { $name } a été ignoré : son service de connexion n'a pas pu être joint. Ajoutez-le de nouveau dans Applications de connexion.
# review: new
attachment-runs-programs = « { $name } » peut lancer des programmes, Inbox Classic ne l’ouvre donc pas. Enregistrez-le, puis ouvrez-le vous-même si vous faites confiance à sa provenance.
# review: new
attachment-decrypted-note = Cette pièce jointe vient d’un message chiffré. Pour l’ouvrir, Inbox Classic l’enregistre déchiffrée sur cet ordinateur, dans un dossier à vous qu’Inbox Classic vide au bout d’un jour.
# review: new
undone-move = { $count ->
    [one] Le serveur n’a pas déplacé { $messages } vers { $folder }, il est donc de retour dans { $from } : { $reason }
   *[other] Le serveur n’a pas déplacé { $messages } vers { $folder }, ils sont donc de retour dans { $from } : { $reason }
}
# review: new
undone-delete = { $count ->
    [one] Le serveur n’a pas supprimé { $messages }, il est donc de retour dans { $from } : { $reason }
   *[other] Le serveur n’a pas supprimé { $messages }, ils sont donc de retour dans { $from } : { $reason }
}
# review: new
undone-archive = { $count ->
    [one] Le serveur n’a pas archivé { $messages }, il est donc de retour dans { $from } : { $reason }
   *[other] Le serveur n’a pas archivé { $messages }, ils sont donc de retour dans { $from } : { $reason }
}
# review: new
undone-read = { $count ->
    [one] Le serveur n’a pas marqué { $messages } comme lu, il est donc de nouveau non lu : { $reason }
   *[other] Le serveur n’a pas marqué { $messages } comme lus, ils sont donc de nouveau non lus : { $reason }
}
# review: new
undone-unread = { $count ->
    [one] Le serveur n’a pas marqué { $messages } comme non lu, il est donc de nouveau lu : { $reason }
   *[other] Le serveur n’a pas marqué { $messages } comme non lus, ils sont donc de nouveau lus : { $reason }
}
# review: new
undone-flags = { $count ->
    [one] Le serveur n’a pas modifié les indicateurs de { $messages }, il est donc comme avant : { $reason }
   *[other] Le serveur n’a pas modifié les indicateurs de { $messages }, ils sont donc comme avant : { $reason }
}
