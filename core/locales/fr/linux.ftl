# The words of the Linux app's own windows (linux/src), ids starting with gtk-. Placeables in { $braces } are filled in
# by the app; an _ marks a button's mnemonic letter. GNOME words where GNOME has them (Preferences, Quit).

## The main window

gtk-search-mail = Rechercher dans le courrier
gtk-find-tip = Cherche des mots dans l'objet, les personnes, les noms de fichiers et le texte des messages.
gtk-clear-search = Effacer la recherche
gtk-from-account = De { $account }
gtk-the-account = le compte
gtk-column-folder = Dossier
gtk-column-account = Compte
gtk-search-looks-everywhere = La recherche porte sur l'objet, les personnes, les noms de fichiers et le texte des messages de tous les dossiers. Vérifiez l'orthographe, ou essayez avec moins de mots.
gtk-search-looks-in = La recherche porte sur l'objet, les personnes, les noms de fichiers et le texte des messages de { $place }. Vérifiez l'orthographe, ou essayez avec moins de mots.
gtk-search-still-indexing = { $count ->
    [one] Le texte de { $count } message est encore en cours d'indexation, d'autres résultats peuvent donc bientôt apparaître.
   *[other] Le texte de { $count } messages est encore en cours d'indexation, d'autres résultats peuvent donc bientôt apparaître.
}
gtk-search-no-match = Aucun message ne correspond à « { $words } ».
gtk-list-empty = Il n'y a aucun élément dans cet affichage.
gtk-list-choose-folder = Choisissez un dossier pour voir ses messages.
gtk-all-inboxes = Toutes les boîtes
gtk-all-folders = Tous les dossiers
gtk-search-results-everywhere = { $count ->
    [0] Aucun résultat
    [one] { $count } résultat
   *[other] { $count } résultats
} pour « { $words } » dans tous les dossiers
gtk-search-results-in = { $count ->
    [0] Aucun résultat
    [one] { $count } résultat
   *[other] { $count } résultats
} pour « { $words } » dans { $place }
gtk-search-indexing = { $count ->
    [one] indexation du texte de { $count } message en cours
   *[other] indexation du texte de { $count } messages en cours
}
gtk-toolbar-junk = Indésirable
gtk-toolbar-not-junk = Pas indésirable
gtk-menu-rename = Renommer...
gtk-menu-delete = Supprimer
gtk-new-folder-in-selected = Le nouveau dossier est créé dans le dossier sélectionné.
gtk-new-folder-at-top = Le nouveau dossier est créé au premier niveau du compte.
gtk-new-folder-title = Nouveau dossier
gtk-rename-folder-intro = Le nouveau nom du dossier { $folder }.
gtk-rename-folder-title = Renommer le dossier
gtk-delete-folder-question = Supprimer le dossier « { $folder } » avec ses messages et les dossiers qu'il contient ? Il est aussi supprimé sur le serveur.
gtk-not-downloaded = Le message n'est pas encore téléchargé.
gtk-mail-messages = Messages électroniques
gtk-save-message-as = Enregistrer le message sous
gtk-message-not-saved = Le message n'a pas pu être enregistré.
gtk-save-messages-in = Enregistrer les messages dans
gtk-select-message-first = Sélectionnez d'abord un message.
gtk-properties = Propriétés
gtk-properties-of = Propriétés de { $subject }
gtk-internet-headers = En-têtes Internet de ce message :
gtk-menu-open = Ouvrir
gtk-menu-flag = Indicateur
gtk-menu-view-source = Afficher la source
gtk-import-choose-folder = Choisissez d'abord le dossier où mettre les messages.
gtk-import-one-question = Mettre le message { $file } dans le dossier { $folder } ?
gtk-attachment-not-read = La pièce jointe n'a pas pu être lue.
gtk-save-attachment-as = Enregistrer la pièce jointe sous
gtk-attachment-not-saved = La pièce jointe n'a pas pu être enregistrée.
gtk-save-attachments = Enregistrer les pièces jointes
gtk-files-not-saved = { $failed } des { $total } fichiers n'ont pas pu être enregistrés.
gtk-invitation-not-read = L'invitation n'a pas pu être lue.
gtk-no-calendar-program = Aucun programme d'agenda de cet ordinateur n'ouvre les invitations (fichiers .ics).
gtk-cancel = Annuler
gtk-ok = OK
gtk-unsubscribe = Se désabonner
gtk-unsubscribe-one-click =
    Quitter cette liste de diffusion ?

    Inbox Classic demande à { $target } de ne plus vous l'envoyer. Aucune page ne s'ouvre et aucun message n'est envoyé.
gtk-unsubscribing = Désabonnement de { $target }...
gtk-can-not-unsubscribe = Ce message ne permet pas de vous désabonner.
gtk-unsubscribe-mail =
    Quitter cette liste de diffusion ?

    La liste demande un message à { $target }. Inbox Classic l'écrit pour vous ; envoyez-le pour vous désabonner.
gtk-unsubscribe-web =
    Quitter cette liste de diffusion ?

    La page de la liste pour cela s'ouvre dans votre navigateur ({ $target }).
gtk-unsubscribed = Désabonné. La liste indique qu'elle n'enverra plus ce courrier.
gtk-unsubscribe-failed = Désabonnement impossible : { $problem }
gtk-toolbar-create-mail = Créer un message
gtk-toolbar-create-mail-menu = Un message d'un seul compte
gtk-toolbar-send-recv = Envoyer/Recevoir
gtk-toolbar-send-recv-menu = Envoyer et recevoir un seul compte
gtk-toolbar-reply = Répondre
gtk-toolbar-reply-all = Répondre à tous
gtk-toolbar-forward = Transférer
gtk-toolbar-print = Imprimer
gtk-toolbar-delete = Supprimer
gtk-toolbar-mark-read = Lu
gtk-toolbar-mark-unread = Non lu
gtk-main-menu = Menu principal
gtk-quit = Quitter
gtk-clear-flag = Effacer l'indicateur

## The Move and Copy window

gtk-button-move = Déplacer
gtk-button-copy = Copier
gtk-find-folder = Chercher un dossier
gtk-new-folder-in = Le nouveau dossier est créé dans { $folder }.
gtk-new-folder-at-top-of = Le nouveau dossier est créé au premier niveau de { $account }.

## The message list

gtk-column-from = De
gtk-column-subject = Objet
gtk-column-received = Reçu
gtk-column-size = Taille

## Help

gtk-help-title = Aide d'Inbox Classic

## Notifications and the tray

gtk-unread-messages = { $count ->
    [0] Aucun message non lu
    [one] { $count } message non lu
   *[other] { $count } messages non lus
}
gtk-done = Terminé

## The compose window's link menu

gtk-open-link = Ouvrir le lien
gtk-edit-link = Modifier le lien...
gtk-remove-link = Supprimer le lien

## The Outbox

gtk-no-subject = (sans objet)
gtk-outbox-title = Boîte d'envoi
gtk-outbox-empty = Rien n'attend d'être envoyé.
gtk-outbox-send-all = Tout envoyer maintenant
gtk-outbox-delete = Supprimer
gtk-outbox-delete-ask = Supprimer ce message sans l'envoyer ?
gtk-outbox-waiting = En attente
gtk-outbox-not-sent = Non envoyé : { $reason }
gtk-outbox-agent = Envoyé par un agent d'IA ; part à { $time }
gtk-outbox-row = À : { $to }  ·  En file { $queued }  ·  { $status }

## The app

gtk-store-not-opened = Le stockage du courrier n'a pas pu être ouvert.
gtk-store-or-cert-not-opened = Le stockage du courrier ou le fichier de certificat n'a pas pu être ouvert.
gtk-checking = Vérification des nouveaux messages sur { $account }...
gtk-sent-at = { $subject } envoyé à { $time }
gtk-draft-saved = Message enregistré dans Brouillons.
gtk-draft-not-saved = Le message n'a pas été enregistré dans Brouillons : { $reason }
gtk-newest-from = Le plus récent, de { $sender } : { $subject }
gtk-new-messages = { $count } nouveaux messages
gtk-outbox-waits = { $subject } attend dans la Boîte d'envoi
gtk-outbox-sending = Envoi de { $subject }...
gtk-outbox-count = { $count ->
    [one] { $count } message dans la Boîte d'envoi
   *[other] { $count } messages dans la Boîte d'envoi
}
gtk-still-running = Inbox Classic est toujours ouvert
gtk-still-running-detail = Il continue de relever le courrier. Son icône dans la barre supérieure le rouvre, ou le quitte.
gtk-add-account-first = Ajoutez d'abord un compte de messagerie.
gtk-add-account-first-link = Ajoutez d'abord un compte de messagerie, puis cliquez de nouveau sur le lien e-mail.
gtk-quoted = « { $subject } »
gtk-sign-in-again-ask =
    La connexion de { $account } a été refusée ou a expiré.

    Se reconnecter dans le navigateur ?
gtk-sign-in-again-failed = La reconnexion n'a pas fonctionné : { $reason }
gtk-default-app-not-installed = Cette copie d'Inbox Classic n'a pas été installée, le système ne la propose donc pas comme application de messagerie. Installez-la pour la choisir.
gtk-default-app-is = Inbox Classic est votre application de messagerie par défaut : les liens e-mail ouvrent un nouveau message ici.
gtk-default-app-now = Inbox Classic est maintenant votre application de messagerie par défaut : les liens e-mail ouvrent un nouveau message ici.
gtk-default-app-failed = Inbox Classic n'a pas pu devenir l'application de messagerie par défaut.
gtk-about-core = Noyau { $version }

## Buttons and words used in many windows

gtk-yes = Oui
gtk-no = Non
gtk-folder-name = Nom du dossier :
gtk-all-files = Tous les fichiers

## The reading pane

gtk-reader-from = De :
gtk-reader-to = À :
gtk-reader-date = Date :
gtk-reader-files = Les fichiers du message
gtk-open-in-calendar = Ouvrir dans l'agenda
gtk-pictures-blocked = Certaines images ont été bloquées pour empêcher l'expéditeur d'identifier votre ordinateur.
gtk-download-pictures = Télécharger les images
gtk-try-again = Réessayer
gtk-message-not-shown = Le message n'a pas pu être affiché.
gtk-save-attachments-menu = Enregistrer les pièces jointes...
gtk-no-title = (sans titre)
gtk-invitation = { $kind ->
    [update] Invitation modifiée : { $summary }
    [cancel] Annulé : { $summary }
    [reply] Réponse à une invitation : { $summary }
   *[request] Invitation : { $summary }
}
gtk-organizer = Organisateur : { $organizer }
gtk-attendees = { $count ->
    [one] { $count } participant
   *[other] { $count } participants
}
gtk-from-to = { $start } à { $end }
gtk-day-and-time = { $day }, { $time }
gtk-senders-time = { $when } (heure de l'expéditeur)

## The compose window

gtk-format-bold = Gras (Ctrl+B)
gtk-format-italic = Italique (Ctrl+I)
gtk-format-underline = Souligné (Ctrl+U)
gtk-format-font-color = Couleur de police
gtk-format-numbered-list = Liste numérotée
gtk-format-bulleted-list = Liste à puces
gtk-format-decrease-indent = Diminuer le retrait
gtk-format-increase-indent = Augmenter le retrait
gtk-format-align-left = Aligner à gauche
gtk-format-center = Centrer
gtk-format-align-right = Aligner à droite
gtk-format-hyperlink = Lien hypertexte (Ctrl+K)
gtk-format-insert-horizontal-line = Insérer une ligne horizontale
gtk-format-insert-picture = Insérer une image
gtk-font = Police
gtk-font-size = Taille
gtk-link-invalid = Tapez une adresse web (https://...) ou un lien e-mail (mailto:...).
gtk-edit-hyperlink = Modifier le lien hypertexte
gtk-edit-hyperlink-intro = Où mène le lien. Videz l'adresse pour supprimer le lien et garder son texte.
gtk-hyperlink = Lien hypertexte
gtk-hyperlink-intro = L'adresse vers laquelle pointe le texte sélectionné.
gtk-link-address = Adresse :
gtk-pictures = Images
gtk-insert-picture = Insérer une image
gtk-not-a-picture = Ce fichier n'est pas une image PNG, JPEG ou GIF, ou il dépasse 10 Mo.
gtk-show-cc = _Cc
gtk-show-bcc = C_ci
gtk-compose-from = De :
gtk-compose-to = À :
gtk-compose-cc = Cc :
gtk-compose-bcc = Cci :
gtk-compose-subject = Objet :
gtk-compose-attach = Joindre :
gtk-send = Envoyer
gtk-save-tip = Enregistrer (Ctrl+S)
gtk-attach-tip = Joindre
gtk-new-message = Nouveau message
gtk-remove = Supprimer
gtk-link-status = { $link }    (Ctrl+clic pour ouvrir)
gtk-insert-attachment = Insérer une pièce jointe
gtk-saving-draft = Enregistrement dans Brouillons...
gtk-save-changes = Voulez-vous enregistrer les modifications de ce message dans Brouillons ?
gtk-not-saved-in-drafts = Non enregistré dans Brouillons : { $reason }
gtk-saved-in-drafts-at = Enregistré dans Brouillons à { $time }
gtk-signature-hint = Ajoutée aux nouveaux messages, aux réponses et aux transferts de ce compte.
gtk-signature-of = Signature - { $account }
gtk-signature = Signature
gtk-signature-not-saved = La signature n'a pas pu être enregistrée.

## Accounts

gtk-add-mail-account = Ajouter un compte de messagerie
gtk-account-not-saved = Le compte n'a pas pu être enregistré.
gtk-security-none = Aucune (non chiffrée)
gtk-field-required = { $field } est obligatoire.
gtk-address-not-valid = L'adresse e-mail n'est pas valide.
gtk-ports-are-numbers = Les ports sont des nombres de 1 à 65535.
gtk-display-name = Nom affiché :
gtk-email-address = Adresse e-mail :
gtk-user-name = Nom d'utilisateur :
gtk-password = Mot de passe :
gtk-imap-server = Serveur entrant (IMAP) :
gtk-imap-port = Port IMAP :
gtk-imap-security = Sécurité IMAP :
gtk-smtp-server = Serveur sortant (SMTP) :
gtk-smtp-port = Port SMTP :
gtk-smtp-security = Sécurité SMTP :
gtk-plain-warning =
    Sans chiffrement, votre mot de passe et votre courrier traversent le réseau lisibles par quiconque se trouve sur le chemin. Ne l'utilisez que pour un serveur sur votre propre ordinateur ou réseau.

    Continuer ?
gtk-sign-in-with = Se connecter avec { $provider }
gtk-the-provider = votre fournisseur
gtk-more-sign-in = Autres options de connexion...
gtk-display-name-title = Nom affiché
gtk-email-address-title = Adresse e-mail
gtk-other-account-intro = Tout autre compte de messagerie : votre nom tel que les autres le voient et votre adresse e-mail. Ses serveurs sont recherchés ensuite.
gtk-type-address = Tapez votre adresse e-mail, nom@example.com.
gtk-turned-off-why = { $button } est désactivé sur cet ordinateur. { $reason }
gtk-turned-off-why-long =
    { $button } est désactivé sur cet ordinateur.

    { $reason }
gtk-turned-off = Désactivé sur cet ordinateur.
gtk-why = Pourquoi ?
gtk-add-sign-in-app = Ajouter une application de connexion...
gtk-browser-sign-in-not-started = La connexion par le navigateur n'a pas pu démarrer.
gtk-sign-in-in-browser = Connectez-vous à { $account } dans la fenêtre du navigateur qui s'est ouverte, puis revenez ici.
gtk-sign-in-in-browser-yours = Connectez-vous à votre compte dans la fenêtre du navigateur qui s'est ouverte, puis revenez ici.
gtk-signing-in-failed = La connexion n'a pas fonctionné : { $reason }
gtk-looking-up = Recherche des paramètres de { $domain }...
gtk-found-none = Saisissez les informations de compte que votre fournisseur de messagerie vous a données.
gtk-found-guess = Aucun paramètre n'a été trouvé pour cette adresse : voici les noms habituels, vérifiez-les auprès de votre fournisseur.
gtk-found-mx = Votre courrier est géré par un fournisseur qu'Inbox Classic connaît ; voici ses serveurs.
gtk-found-srv = Ces paramètres ont été trouvés dans les enregistrements DNS de votre domaine.
gtk-found-autodiscover = Ces paramètres ont été trouvés par Microsoft Autodiscover (Exchange).
gtk-found-other = Ces paramètres ont été trouvés pour cette adresse.
gtk-found-change = Modifiez-les si votre fournisseur vous en a donné d'autres.
gtk-app-password-needed = { $provider } n'accepte pas votre mot de passe habituel dans les programmes de messagerie. Créez un mot de passe d'application dans votre compte { $provider } et tapez-le dans le champ Mot de passe du formulaire suivant.
gtk-open-instructions = Ouvrir les instructions de { $provider } dans votre navigateur ?
gtk-start-intro = Gmail, Google Workspace, Outlook.com et Microsoft 365 : connectez-vous sur la page de Google ou de Microsoft. Votre mot de passe y est saisi, jamais dans Inbox Classic.
gtk-start-intro-apps = Connectez-vous par le navigateur avec l'une de vos applications de connexion (Autres options de connexion), ou ajoutez n'importe quel compte de messagerie avec votre nom et votre adresse ci-dessous.
gtk-next = Suivant >
gtk-provider-sign-in = { $address } se connecte sur la page de { $provider }, sans donner votre mot de passe à Inbox Classic. Ou utilisez un mot de passe d'application créé dans les paramètres de sécurité de votre compte.
gtk-provider-sign-in-apps = { $address } peut se connecter sur la page de { $provider } avec l'une de vos applications de connexion (Autres options de connexion). Ou utilisez un mot de passe d'application créé dans les paramètres de sécurité de votre compte.
gtk-use-app-password = Utiliser un mot de passe d'application
gtk-finish = Terminer
gtk-enter-password = Saisissez le mot de passe de { $account }.
gtk-logon = Connexion
gtk-signs-in-with = Se connecte avec : { $app }. Il se connecte par le navigateur et utilise les serveurs de sa connexion.
gtk-keep-password = Laissez le mot de passe vide pour garder celui que vous avez.
gtk-browser-sign-in-server = { $server } (connexion par le navigateur)
gtk-accounts-add = Ajouter...
gtk-accounts-properties = Propriétés...
gtk-accounts-signature = Signature...
gtk-accounts-sign-in-apps = Applications de connexion...
gtk-accounts-title = Comptes
gtk-remove-account = Supprimer le compte
gtk-remove-account-ask = Supprimer ce compte d'Inbox Classic ? Son courrier reste sur le serveur ; la copie sur cet ordinateur et le mot de passe enregistré sont supprimés.

## Sign-in apps

gtk-sign-in-app = Application de connexion
gtk-remove-sign-in-app = Supprimer l'application de connexion
gtk-check = Vérifier
gtk-app-server = Serveur { $kind }
gtk-app-port = Port { $kind }
gtk-app-security = Sécurité { $kind }
gtk-preset-name = Application de connexion { $provider }
gtk-checking-issuer = Vérification de { $issuer }...
gtk-issuer-found =
    Page de connexion : { $page }
    Point de terminaison du jeton : { $endpoint }
gtk-app-editor-intro = Un client OAuth que vous avez enregistré auprès de votre fournisseur, pour les comptes qui se connectent par le navigateur. Remplissez-le pour un fournisseur, puis ajoutez l'ID client (et le secret, si le fournisseur en a donné un).
gtk-fill-in-for = Remplir pour :
gtk-app-name = Nom
gtk-issuer = Émetteur
gtk-client-id = ID client
gtk-client-secret = Secret client
gtk-secret-saved = Un secret est enregistré ; tapez-en un autre pour le remplacer, ou supprimez-le
gtk-scopes = Portées (scopes)
gtk-register-it = Enregistrez-le auprès de votre fournisseur
gtk-redirect-uri = URI de redirection
gtk-copy-button = Copier
gtk-add-sign-in-app-title = Ajouter une application de connexion
gtk-issuer-usable =
    L'émetteur peut être utilisé.

    { $found }
gtk-issuer-not-usable = L'émetteur ne peut pas être utilisé : { $reason }
gtk-app-not-saved = L'application de connexion n'a pas pu être enregistrée : { $reason }
gtk-app-built-in = { $app } est intégrée : seul son usage pour les nouveaux comptes peut changer. { $reason }
gtk-client-with-secret = ID client : { $client }, avec un secret client.
gtk-client-public = ID client : { $client }, un client public (sans secret).
gtk-no-accounts = Aucun compte
gtk-built-in = { $app } (intégrée)
gtk-offered-for-new = Proposée pour les nouveaux comptes
gtk-edit-button = Modifier...
gtk-sign-in-apps-title = Applications de connexion
gtk-remove-app-ask = Supprimer l'application de connexion { $app } et son secret client enregistré ?
gtk-app-not-removed = L'application de connexion n'a pas été supprimée : { $reason }
gtk-sign-in-apps-intro = Les applications de connexion permettent aux comptes de se connecter par le navigateur. Une application désactivée n'est pas proposée pour les nouveaux comptes ; les comptes qui l'utilisent déjà continuent de fonctionner.

## AI agents

gtk-agent-program = Programme : { $path }
gtk-agent-it-may = Il peut
gtk-agent-accounts = Comptes qu'il peut utiliser
gtk-dont-allow = Ne pas autoriser
gtk-allow = Autoriser
gtk-dont-send = Ne pas envoyer
gtk-edit-first = Modifier d'abord
gtk-new-address = Nouvelle adresse
gtk-never-used = Jamais utilisé
gtk-last-used = Dernière utilisation { $date }
gtk-turn-away = Refuser
gtk-forget-program = Oublier ce programme ?
gtk-forget-program-detail = La question lui est reposée à sa prochaine connexion, et ce que ses agents ont fait est oublié.
gtk-ai-agents = Agents d'IA
gtk-clear-agent-log = Effacer la liste de ce que les agents ont fait ?
gtk-clear-agent-log-detail = Ce qu'ils ont fait reste fait.
gtk-let-agents-connect = Permettre aux agents d'IA de se connecter à Inbox Classic
gtk-no-agents-yet = Aucun agent n'a encore demandé à utiliser votre courrier.
gtk-nothing-yet = Rien pour l'instant.
gtk-change-button = Modifier…
gtk-undo-button = Annuler
gtk-clear-button = Effacer
gtk-how-to-connect = Comment connecter un agent…
gtk-agent-programs = Programmes dont les agents ont demandé à utiliser votre courrier
gtk-what-agents-did = Ce que les agents ont fait
gtk-connect-agent = Connecter un agent d'IA
gtk-connect-agent-intro = Ajoutez ceci aux serveurs MCP de votre agent (Claude Desktop : Settings > Developer > Edit Config) :

## Preferences

gtk-preferences = Préférences
gtk-language = Langue
gtk-language-subtitle = Les mots des fenêtres et de l'aide
gtk-system-default = Par défaut du système ({ $language })
gtk-new-mail-group = Nouveau courrier
gtk-notify-subtitle = Une notification quand de nouveaux messages arrivent alors que la fenêtre est en arrière-plan
gtk-restart-to-change = Inbox Classic redémarre pour changer de langue.
gtk-restart-now = Redémarrer maintenant
gtk-restart-later = Plus tard
