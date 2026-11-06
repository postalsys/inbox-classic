# Français. Brouillon, en attente de relecture par un locuteur natif.

## The app and its menus

mac-store-not-opened = Le stockage des messages n'a pas pu être ouvert.
mac-store-or-certificate-not-opened = Le stockage des messages ou le fichier de certificat n'a pas pu être ouvert.
mac-quit = Quitter Inbox Classic
mac-settings = Réglages…
mac-services = Services
mac-hide = Masquer Inbox Classic
mac-hide-others = Masquer les autres
mac-show-all = Tout afficher
mac-check-updates = Rechercher des mises à jour…
mac-close-window = Fermer la fenêtre
mac-redo = Rétablir
mac-cut = Couper
mac-copy = Copier
mac-paste = Coller
mac-menu-window = Fenêtre
mac-minimize = Réduire
mac-zoom = Zoom
mac-help-title = Aide d'Inbox Classic
mac-no-updates = Cette copie d'Inbox Classic ne se met pas à jour toute seule. Téléchargez la dernière version sur inboxclassic.com.
mac-flag = Indicateur
mac-clear-flag = Effacer l'indicateur

## Settings

mac-settings-title = Réglages
mac-language-label = Langue :
mac-system-default = Langue du système ({ $language })
mac-restart-hint = Inbox Classic redémarre pour changer de langue.
mac-notify-new-mail = M'avertir à l'arrivée de nouveaux messages
mac-restart-question = Redémarrer Inbox Classic maintenant pour changer de langue ?
mac-restart-now = Redémarrer maintenant
mac-restart-later = Plus tard

## Dialogs

mac-ok = OK
mac-cancel = Annuler
mac-yes = Oui
mac-no = Non
mac-folder-name = Nom du dossier :
mac-save-attachment-as = Enregistrer la pièce jointe sous
mac-choose = Choisir
mac-messages-not-changed = Les messages n'ont pas pu être modifiés.

## The main window

mac-still-running = Inbox Classic est toujours ouvert
mac-still-running-detail = Il continue de relever les nouveaux messages. Cliquez sur son icône dans le Dock pour le rouvrir.
mac-no-subject = (sans objet)
mac-quoted = « { $subject } »
mac-outbox-waiting =
    { $count ->
        [one] { $count } message dans la Boîte d'envoi
       *[other] { $count } messages dans la Boîte d'envoi
    }
mac-outbox-waits = { $subject } attend dans la Boîte d'envoi
mac-sending = Envoi de { $subject }…
mac-checking = Relève des nouveaux messages de { $account }…
mac-done = Terminé
mac-sent-at = { $subject } envoyé à { $time }
mac-draft-saved = Message enregistré dans Brouillons.
mac-draft-not-saved = Le message n'a pas été enregistré dans Brouillons : { $reason }
mac-account-said = { $account } : { $message }
mac-new-messages =
    { $count ->
        [one] { $count } nouveau message
       *[other] { $count } nouveaux messages
    }
mac-newest-from = Le plus récent, de { $from } : { $subject }
mac-sign-in-refused = La connexion de { $account } a été refusée ou a expiré.
mac-sign-in-again = Se reconnecter dans le navigateur ?
mac-sign-in-failed = La nouvelle connexion n'a pas fonctionné : { $reason }
mac-unknown-reason = raison inconnue
mac-core-version = Noyau { $version }
mac-add-account-first = Ajoutez d'abord un compte de messagerie.
mac-add-account-first-link = Ajoutez d'abord un compte de messagerie, puis cliquez de nouveau sur le lien e-mail.
mac-select-message-first = Sélectionnez d'abord un message.
mac-not-bundle = Cette copie d'Inbox Classic n'est pas un paquet d'application, elle ne peut donc pas être l'app de messagerie par défaut.
mac-is-default = Inbox Classic est votre app de messagerie par défaut : les liens e-mail ouvrent ici un nouveau message.
mac-not-made-default = Inbox Classic n'est pas devenu l'app de messagerie par défaut : { $reason }
mac-tool-create-mail = Nouveau
mac-tool-reply = Répondre
mac-tool-reply-all = Rép. à tous
mac-tool-forward = Transférer
mac-tool-print = Imprimer
mac-tool-delete = Supprimer
mac-tool-junk = Indésirable
mac-tool-not-junk = Non indésirable
mac-tool-sync = Env./Recevoir
mac-tool-mark-read = Lu
mac-tool-mark-unread = Non lu
mac-tool-search = Rechercher
mac-search-mail = Rechercher
mac-find-tip = Cherche des mots dans l'objet, les personnes, les noms de fichiers et le texte des messages.
mac-from-account = De { $account }

## The folders and the message list

mac-clear-search = Effacer la recherche
mac-all-inboxes = Toutes les boîtes
mac-the-account = le compte
mac-all-folders = Tous les dossiers
mac-column-received = Reçu
mac-column-size = Taille
mac-column-folder = Dossier
mac-column-account = Compte
mac-no-match = Aucun message ne correspond à « { $words } ».
mac-search-looks-everywhere = La recherche porte sur l'objet, les personnes, les noms de fichiers et le texte des messages de tous les dossiers. Vérifiez l'orthographe ou essayez avec moins de mots.
mac-search-looks-in = La recherche porte sur l'objet, les personnes, les noms de fichiers et le texte des messages de { $folder }. Vérifiez l'orthographe ou essayez avec moins de mots.
mac-still-indexing-more =
    { $count ->
        [one] Le texte de { $count } message est encore en cours d'indexation, d'autres résultats peuvent donc bientôt apparaître.
       *[other] Le texte de { $count } messages est encore en cours d'indexation, d'autres résultats peuvent donc bientôt apparaître.
    }
mac-no-items = Il n'y a aucun élément dans cette vue.
mac-choose-folder = Choisissez un dossier pour voir ses messages.
mac-results-everywhere =
    { $count ->
        [0] Aucun résultat pour « { $words } » dans tous les dossiers
        [one] { $count } résultat pour « { $words } » dans tous les dossiers
       *[other] { $count } résultats pour « { $words } » dans tous les dossiers
    }
mac-results-in =
    { $count ->
        [0] Aucun résultat pour « { $words } » dans { $folder }
        [one] { $count } résultat pour « { $words } » dans { $folder }
       *[other] { $count } résultats pour « { $words } » dans { $folder }
    }
mac-still-indexing =
    { $count ->
        [one] indexation du texte de { $count } message en cours
       *[other] indexation du texte de { $count } messages en cours
    }
mac-folder-unread = { $folder }, { $count } non lus
mac-message-not-shown = Le message n'a pas pu être affiché.
mac-delete = Supprimer
mac-move-button = Déplacer
mac-copy-button = Copier
mac-new-folder = Nouveau dossier
mac-new-folder-in-selected = Le nouveau dossier est créé dans le dossier sélectionné.
mac-new-folder-at-top = Le nouveau dossier est créé au premier niveau du compte.
mac-folder-not-created = Le dossier n'a pas pu être créé.
mac-rename-folder = Renommer le dossier
mac-rename-folder-intro = Le nouveau nom du dossier { $folder }.
mac-folder-not-renamed = Le dossier n'a pas pu être renommé.
mac-delete-folder-question = Supprimer le dossier « { $folder } » avec ses messages et les dossiers qu'il contient ? Il est aussi supprimé sur le serveur.
mac-folder-not-deleted = Le dossier n'a pas pu être supprimé.
mac-not-downloaded = Le message n'est pas encore téléchargé.
mac-save-message-as = Enregistrer le message sous
mac-message-not-saved = Le message n'a pas pu être enregistré.
mac-properties = Propriétés
mac-properties-of = Propriétés de { $subject }
mac-internet-headers = En-têtes Internet de ce message :
mac-close = Fermer
mac-open = Ouvrir
mac-view-source = Afficher la source
mac-import-messages = Importer des messages
mac-import-choose-folder = Choisissez d'abord le dossier où placer les messages.
mac-save-messages = Enregistrer les messages
mac-save-attachments-menu = Enregistrer les pièces jointes…
mac-save-attachments = Enregistrer les pièces jointes
mac-attachment-not-read = La pièce jointe n'a pas pu être lue.
mac-attachment-not-saved = La pièce jointe n'a pas pu être enregistrée.
mac-files-not-saved =
    { $count ->
       *[other] { $failed } des { $count } fichiers n'ont pas pu être enregistrés.
    }
mac-invitation-not-read = L'invitation n'a pas pu être lue.
mac-no-calendar-app = Aucune app de calendrier de ce Mac n'ouvre les invitations (fichiers .ics).
mac-leave-list = Quitter cette liste de diffusion ?
mac-unsubscribe = Se désabonner
mac-unsubscribe-one-click = Inbox Classic demande à { $target } de ne plus vous l'envoyer. Aucune page ne s'ouvre et aucun message n'est envoyé.
mac-unsubscribe-mail = La liste demande un message à { $target }. Inbox Classic l'écrit pour vous ; envoyez-le pour vous désabonner.
mac-unsubscribe-web = La page de la liste prévue pour cela s'ouvre dans votre navigateur ({ $target }).
mac-unsubscribing = Désabonnement de { $target }…
mac-can-not-unsubscribe = Ce message ne permet pas de vous désabonner.
mac-unsubscribed = Désabonné. La liste indique qu'elle n'enverra plus ces messages.
mac-not-unsubscribed = Désabonnement impossible : { $reason }

## The compose window

mac-bold = Gras
mac-italic = Italique
mac-underline = Souligné
mac-numbered-list = Liste numérotée
mac-bulleted-list = Liste à puces
mac-align-left = Aligner à gauche
mac-center = Centrer
mac-align-right = Aligner à droite
mac-font-color = Couleur de police
mac-decrease-indent = Diminuer le retrait
mac-increase-indent = Augmenter le retrait
mac-hyperlink = Lien hypertexte
mac-edit-hyperlink = Modifier le lien hypertexte
mac-hyperlink-intro = L'adresse vers laquelle pointe le texte sélectionné.
mac-edit-hyperlink-intro = La destination du lien. Videz l'adresse pour supprimer le lien et garder son texte.
mac-link-address = Adresse :
mac-link-invalid = Tapez une adresse web (https://...) ou un lien e-mail (mailto:...).
mac-horizontal-line = Insérer une ligne horizontale
mac-insert-picture = Insérer une image
mac-not-a-picture = Ce fichier n'est pas une image PNG, JPEG ou GIF, ou il dépasse 10 Mo.
mac-bcc = Cci
mac-new-message = Nouveau message
mac-field-from = De :
mac-field-to = À :
mac-field-cc = Cc :
mac-field-bcc = Cci :
mac-field-subject = Objet :
mac-field-attach = Joindre :
mac-command-click-to-open = ⌘-clic pour ouvrir
mac-remove = Supprimer
mac-insert-attachment = Insérer une pièce jointe
mac-message-not-sent = Le message n'a pas pu être envoyé.
mac-saving-to-drafts = Enregistrement dans Brouillons…
mac-save-changes-question = Voulez-vous enregistrer les modifications de ce message dans Brouillons ?
mac-save = Enregistrer
mac-dont-save = Ne pas enregistrer
mac-saved-in-drafts-at = Enregistré dans Brouillons à { $time }
mac-not-saved-in-drafts = Non enregistré dans Brouillons : { $reason }
mac-send = Envoyer
mac-attach = Joindre
mac-signature = Signature
mac-signature-title = Signature - { $account }
mac-signature-hint = Ajoutée aux nouveaux messages, aux réponses et aux transferts de ce compte.
mac-signature-not-saved = La signature n'a pas pu être enregistrée.

## The reading pane

mac-open-in-calendar = Ouvrir dans Calendrier
mac-try-again = Réessayer
mac-pictures-blocked = Certaines images ont été bloquées pour empêcher l'expéditeur d'identifier votre ordinateur. Cliquez ici pour télécharger les images.
mac-files =
    { $count ->
        [one] { $count } fichier
       *[other] { $count } fichiers
    }
mac-invitation = Invitation : { $title }
mac-invitation-updated = Invitation modifiée : { $title }
mac-invitation-canceled = Annulé : { $title }
mac-invitation-answer = Réponse à une invitation : { $title }
mac-no-title = (sans titre)
mac-organizer = Organisateur : { $name }
mac-attendees =
    { $count ->
        [one] { $count } participant
       *[other] { $count } participants
    }
mac-from-to = { $start } au { $end }
mac-senders-time = { $when } (heure de l'expéditeur)

## Accounts

mac-security-none = Aucune (non chiffrée)
mac-field-required = Le champ « { $field } » est obligatoire.
mac-email-invalid = L'adresse e-mail n'est pas valide.
mac-ports-invalid = Les ports sont des nombres de 1 à 65535.
mac-plain-warning = Sans chiffrement, votre mot de passe et vos messages circulent sur le réseau, lisibles par quiconque sur le trajet. Ne l'utilisez que pour un serveur sur votre propre ordinateur ou réseau.
mac-continue-question = Continuer ?
mac-display-name = Nom affiché :
mac-email-address = Adresse e-mail :
mac-user-name = Nom d'utilisateur :
mac-password = Mot de passe :
mac-imap-server = Serveur entrant (IMAP) :
mac-imap-port = Port IMAP :
mac-imap-security = Sécurité IMAP :
mac-smtp-server = Serveur sortant (SMTP) :
mac-smtp-port = Port SMTP :
mac-smtp-security = Sécurité SMTP :
mac-sign-in-not-started = La connexion par le navigateur n'a pas pu démarrer.
mac-sign-in-waiting = Connectez-vous à { $account } dans la fenêtre du navigateur qui s'est ouverte, puis revenez ici.
mac-sign-in-waiting-any = Connectez-vous à votre compte dans la fenêtre du navigateur qui s'est ouverte, puis revenez ici.
mac-add-mail-account = Ajouter un compte de messagerie
mac-sign-in-did-not-work = La connexion n'a pas fonctionné : { $reason }
mac-sign-in-with = Se connecter avec { $provider }
mac-next = Suivant
mac-name-placeholder = Marie Dupont
mac-more-sign-in-options = Autres options de connexion…
mac-any-other-account = Tout autre compte de messagerie : votre nom tel que les autres le voient et votre adresse e-mail. Ses serveurs sont recherchés ensuite.
mac-turned-off-named = { $name } est désactivé sur cet ordinateur.
mac-turned-off = Désactivé sur cet ordinateur.
mac-why = Pourquoi ?
mac-add-sign-in-app = Ajouter une application de connexion…
mac-type-email = Tapez votre adresse e-mail, nom@example.com.
mac-found-none = Saisissez les informations de compte fournies par votre fournisseur de messagerie.
mac-found-change = Modifiez-les si votre fournisseur vous en a donné d'autres.
mac-found-guess = Aucun réglage n'a été trouvé pour cette adresse : voici les noms habituels, vérifiez-les auprès de votre fournisseur.
mac-found-mx = Votre messagerie est gérée par un fournisseur qu'Inbox Classic connaît ; voici ses serveurs.
mac-found-srv = Ces réglages ont été trouvés dans les enregistrements DNS de votre domaine.
mac-found-autodiscover = Ces réglages ont été trouvés par Microsoft Autodiscover (Exchange).
mac-found-other = Ces réglages ont été trouvés pour cette adresse.
mac-app-password-needed = { $provider } n'accepte pas votre mot de passe habituel dans les logiciels de messagerie. Créez un mot de passe d'application dans votre compte { $provider } et tapez-le dans le champ Mot de passe du formulaire suivant.
mac-open-instructions = Ouvrir les instructions de { $provider } dans votre navigateur ?
mac-account-not-saved = Le compte n'a pas pu être enregistré.
mac-start-intro = Gmail, Google Workspace, Outlook.com et Microsoft 365 : connectez-vous sur la page de Google ou de Microsoft. Votre mot de passe y est saisi, jamais dans Inbox Classic.
mac-start-intro-apps = Connectez-vous par le navigateur avec l'une de vos applications de connexion (Autres options de connexion), ou ajoutez ci-dessous n'importe quel compte de messagerie avec votre nom et votre adresse.
mac-looking-up = Recherche des réglages de { $domain }…
mac-use-app-password = Mot de passe d'application
mac-the-provider = votre fournisseur
mac-signs-in-at = { $email } se connecte sur la page de { $provider }, sans donner votre mot de passe à Inbox Classic. Ou utilisez un mot de passe d'application créé dans les réglages de sécurité de votre compte.
mac-can-sign-in-at = { $email } peut se connecter sur la page de { $provider } avec l'une de vos applications de connexion (Autres options de connexion). Ou utilisez un mot de passe d'application créé dans les réglages de sécurité de votre compte.
mac-finish = Terminer
mac-logon = Connexion
mac-enter-password = Saisissez le mot de passe de { $account }.
mac-signs-in-with = Se connecte avec : { $app }. Il se connecte par le navigateur et utilise les serveurs de sa connexion.
mac-keep-password = Laissez le mot de passe vide pour garder celui que vous avez.
mac-accounts = Comptes
mac-column-email = Adresse e-mail
mac-column-incoming = Serveur entrant
mac-add-button = Ajouter…
mac-properties-button = Propriétés…
mac-signature-button = Signature…
mac-sign-in-apps-button = Applications de connexion…
mac-browser-sign-in = { $server } (connexion par le navigateur)
mac-remove-account = Supprimer le compte
mac-remove-account-question = Supprimer ce compte d'Inbox Classic ? Ses messages restent sur le serveur ; la copie sur cet ordinateur et le mot de passe enregistré sont supprimés.

## AI agents

mac-ai-agent = Agent d'IA
mac-allow = Autoriser
mac-dont-allow = Ne pas autoriser
mac-program-path = Programme : { $path }
mac-it-may = Il peut :
mac-accounts-it-may-use = Comptes qu'il peut utiliser :
mac-new-address = Nouvelle adresse
mac-send-message-question = Envoyer le message ?
mac-edit-first = Modifier d'abord
mac-dont-send = Ne pas envoyer
mac-let-agents-connect = Autoriser les agents d'IA à se connecter à Inbox Classic
mac-change-button = Modifier…
mac-undo-button = Annuler
mac-clear = Effacer
mac-ai-agents = Agents d'IA
mac-column-program = Programme
mac-column-may = Peut
mac-column-last-used = Dernière utilisation
mac-column-when = Quand
mac-column-what = Quoi
mac-how-to-connect = Connecter un agent…
mac-agent-programs = Programmes dont les agents ont demandé à utiliser votre messagerie
mac-agent-log = Ce qu'ont fait les agents
mac-never = Jamais
mac-ai-agent-access = Accès de l'agent d'IA
mac-turn-away = Refuser
mac-forget-program = Oublier ce programme et ce qu'ont fait ses agents ?
mac-forget-program-detail = La question lui sera reposée à sa prochaine connexion.
mac-clear-log = Effacer la liste de ce qu'ont fait les agents ?
mac-clear-log-detail = Ce qu'ils ont fait reste fait.
mac-connect-agent = Connecter un agent d'IA
mac-connect-agent-intro = Ajoutez ceci aux serveurs MCP de votre agent (Claude Desktop : Settings > Developer > Edit Config) :

## Sign-in apps

mac-secret-saved = Un secret est enregistré ; tapez-en un autre pour le remplacer, ou supprimez-le
mac-add-sign-in-app-title = Ajouter une application de connexion
mac-sign-in-app = Application de connexion
mac-sign-in-apps = Applications de connexion
mac-sign-in-app-intro = Un client OAuth que vous avez enregistré auprès de votre fournisseur, pour les comptes qui se connectent par le navigateur. Remplissez-le pour un fournisseur, puis ajoutez l'ID client (et le secret, si le fournisseur en a donné un).
mac-check = Vérifier
mac-fill-in-for = Remplir pour :
mac-app-name = Nom :
mac-issuer = Émetteur :
mac-client-id = ID client :
mac-client-secret = Secret client :
mac-scopes = Portées :
mac-app-imap-server = Serveur IMAP :
mac-app-smtp-server = Serveur SMTP :
mac-register-it = Enregistrez-le auprès de votre fournisseur
mac-redirect-uri = URI de redirection :
mac-preset-app-name = Application de connexion { $provider }
mac-issuer-not-checked = l'émetteur ne peut pas être vérifié
mac-checking-issuer = Vérification de { $issuer }…
mac-issuer-usable = L'émetteur peut être utilisé.
mac-issuer-not-usable = L'émetteur ne peut pas être utilisé : { $reason }
mac-sign-in-app-not-saved = L'application de connexion n'a pas pu être enregistrée : { $reason }
mac-edit-button = Modifier…
mac-column-name = Nom
mac-column-issuer = Émetteur
mac-column-used-by = Utilisée par
mac-sign-in-apps-intro = Les applications de connexion permettent aux comptes de se connecter par le navigateur. Une application non cochée n'est pas proposée pour les nouveaux comptes ; les comptes qui l'utilisent déjà continuent de fonctionner.
mac-use-for-new-accounts = Utiliser { $name } pour les nouveaux comptes
mac-built-in = { $name } (intégrée)
mac-no-accounts = Aucun compte
mac-built-in-note = { $name } est intégrée : seul son usage pour les nouveaux comptes peut changer.
mac-client-with-secret = ID client : { $client }, avec un secret client.
mac-client-public = ID client : { $client }, un client public (sans secret).
mac-remove-sign-in-app = Supprimer l'application de connexion
mac-remove-sign-in-app-question = Supprimer l'application de connexion { $name } et son secret client enregistré ?
mac-sign-in-app-not-removed = L'application de connexion n'a pas été supprimée : { $reason }

## Other windows

mac-find-folder = Chercher un dossier
mac-new-folder-button = Nouveau dossier…
mac-new-folder-in = Le nouveau dossier est créé dans { $folder }.
mac-send-all-now = Tout envoyer maintenant
mac-outbox = Boîte d'envoi
mac-column-queued = En file depuis
mac-column-status = État
mac-not-sent = Non envoyé : { $reason }
mac-agent-goes-at = Envoyé par un agent d'IA ; part à { $time }
mac-waiting = En attente
mac-delete-unsent = Supprimer ce message sans l'envoyer ?
mac-open-link = Ouvrir le lien
mac-edit-link = Modifier le lien…
mac-remove-link = Supprimer le lien
mac-help-missing = L'aide manque dans cette copie d'Inbox Classic.
