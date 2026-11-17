# Français. Brouillon, en attente de relecture par un locuteur natif.

## The menus

menu-file = &Fichier
menu-edit = &Édition
menu-view = &Affichage
menu-tools = &Outils
menu-message = &Message
menu-help = &?
menu-layout = Dispositio&n
menu-sort-by = T&rier par
menu-text-size = Taille du te&xte
menu-folder = &Dossier

## The commands

cmd-new-account = &Nouveau compte...
cmd-exit = &Quitter
cmd-sync = &Envoyer et recevoir tout
cmd-mark-read = Marquer comme &lu
cmd-mark-unread = Marquer comme &non lu
cmd-pictures = &Télécharger les images
cmd-about = À &propos d'Inbox Classic
cmd-new-mail = &Nouveau message
cmd-reply = &Répondre à l'expéditeur
cmd-reply-all = Répondre à &tous
cmd-forward = Trans&férer
cmd-help = &Sommaire
cmd-delete = &Supprimer le message
cmd-move = &Déplacer vers un dossier...
cmd-flag = Ajouter un &indicateur au message
cmd-new-folder = Nouveau &dossier...
cmd-rename-folder = &Renommer le dossier...
cmd-delete-folder = Supprimer le d&ossier
cmd-empty-folder = &Vider le dossier
ui-empty-button = Vider
cmd-accounts = &Comptes...
cmd-find = &Rechercher un message
cmd-save-as = Enregistrer &sous...
cmd-print = &Imprimer...
cmd-import = I&mporter des messages...
cmd-outbox = Boîte d'en&voi...
cmd-properties = &Propriétés
cmd-mark-all-read = Marquer tous les messages comme l&us
cmd-junk = Marquer comme in&désirable
cmd-not-junk = Marquer comme non indé&sirable
cmd-archive = A&rchiver
cmd-watch-conversation = Sur&veiller la conversation
cmd-ignore-conversation = I&gnorer la conversation
cmd-next-message = Message &suivant
cmd-previous-message = Message &précédent
cmd-next-unread = Message non &lu suivant
cmd-go-to-folder = &Aller au dossier...
cmd-find-in-message = Rechercher dans &ce message...
ui-go-to-prompt = Aller au dossier :
ui-find-in-message-hint = Rechercher dans ce message
ui-find-not-found = Aucune occurrence de « { $words } » dans ce message
cmd-expand-all-threads = &Développer toutes les conversations
cmd-collapse-all-threads = Ré&duire toutes les conversations
ui-group-by-conversation = &Regrouper les messages par conversation
cmd-folder-list = Liste des d&ossiers
cmd-layout-automatic = &Automatique
cmd-layout-classic = &Classique
cmd-layout-columns = C&olonnes
cmd-sort-date = &Date
cmd-sort-from = D&e
cmd-sort-subject = &Objet
cmd-sort-size = &Taille
cmd-sort-ascending = Tri &croissant
cmd-sort-descending = Tri déc&roissant
cmd-text-size-largest = Très gra&nde
cmd-text-size-larger = &Grande
cmd-text-size-medium = &Moyenne
cmd-text-size-smaller = &Petite
cmd-text-size-smallest = &Très petite
cmd-hide-ignored = &Masquer les conversations ignorées
cmd-hide-read = Masquer les messages &lus
cmd-notify = &Signaler les nouveaux messages
cmd-open = &Ouvrir Inbox Classic
cmd-default-app = Définir comme programme de &messagerie par défaut...
cmd-view-source = Code &source du message
cmd-ai-agents = &Agents d'IA...
cmd-options = &Options...
cmd-message-rules = &Règles de message...
# review: new
cmd-encryption-keys = Clés de c&hiffrement...
cmd-create-rule-from-message = Créer une règl&e à partir du message...
cmd-select-all = Sélectionner &tout
cmd-undo = &Annuler
cmd-copy = &Copier vers un dossier...
cmd-address-book = &Carnet d'adresses...
cmd-add-sender-to-book = Ajouter l'e&xpéditeur au carnet d'adresses
cmd-import-address-book = Importer le carnet d'&adresses...
cmd-export-address-book = &Exporter le carnet d'adresses...
# review: new
cmd-export-setup = Exporter les param&ètres et comptes...
# review: new
cmd-import-setup = Importer les &paramètres et comptes...

## The tray icon's menu

tray-check = &Vérifier les nouveaux messages
tray-no-accounts = Aucun compte pour l'instant

## Words the windows of more than one platform share

ui-tb-create-mail = Écrire
ui-tb-reply = Répondre
ui-tb-reply-all = Répondre à tous
ui-tb-forward = Transférer
ui-tb-print = Imprimer
ui-tb-delete = Supprimer
ui-tb-junk = Indésirable
ui-tb-not-junk = Non indésirable
ui-tb-archive = Archiver
ui-tb-previous = Précédent
ui-tb-next = Suivant
ui-previous-tip = Message précédent
ui-next-tip = Message suivant
ui-tb-sync = Envoyer/Recevoir
ui-tb-mark-read = Marquer comme lu
ui-tb-mark-unread = Marquer comme non lu
ui-still-running = Inbox Classic fonctionne en arrière-plan
ui-no-subject = (sans objet)
ui-quoted = « { $subject } »
ui-newest-from = Dernier message de { $sender } : { $subject }
ui-new-messages = { $count ->
    [one] { $count } nouveau message
   *[other] { $count } nouveaux messages
}
ui-outbox-waiting = { $count ->
    [one] { $count } message dans la Boîte d'envoi
   *[other] { $count } messages dans la Boîte d'envoi
}
ui-outbox-waits = { $subject } attend dans la Boîte d'envoi
ui-outbox-sending = Envoi de { $subject }...
ui-from-account = De { $account }
ui-sign-in-refused = La connexion au compte { $account } a été refusée ou la session a expiré.
ui-sign-in-again-ask = Se connecter à nouveau dans le navigateur ?
ui-sign-in-again-failed = La reconnexion a échoué : { $reason }
ui-unknown-reason = raison inconnue
ui-checking = Recherche de nouveaux messages sur { $account }...
ui-done = Terminé
ui-sent-at = { $subject } envoyé à { $time }
ui-draft-saved = Message enregistré dans le dossier Brouillons
ui-draft-not-saved = Le message n'a pas été enregistré dans le dossier Brouillons : { $reason }
ui-about-core = Noyau { $version }
ui-add-account-first = Ajoutez d'abord un compte de messagerie.
ui-add-account-first-link = Ajoutez d'abord un compte de messagerie, puis cliquez de nouveau sur le lien e-mail.
ui-default-app-is = Inbox Classic est votre programme de messagerie par défaut : les liens de courrier ouvrent ici un nouveau message.
ui-select-message-first = Sélectionnez d'abord un message.
ui-store-not-opened = Le stockage du courrier n'a pas pu être ouvert.
ui-store-or-cert-not-opened = Le stockage du courrier ou le fichier de certificat n'a pas pu être ouvert.
ui-help-title = Aide d'Inbox Classic
ui-help-missing = L'aide n'est pas disponible dans cette version d'Inbox Classic.
ui-ok = OK
ui-cancel = Annuler
ui-close = Fermer
ui-col-subject = Objet
ui-col-from = De
ui-col-to = À
ui-col-received = Reçu
ui-watched-conversation = Conversation surveillée
ui-col-sent = Envoyé
ui-col-size = Taille
ui-col-folder = Dossier
ui-col-account = Compte
ui-col-queued = Mis en attente le
ui-col-status = État
ui-outbox-title = Boîte d'envoi
ui-outbox-status-waiting = En attente
ui-outbox-status-not-sent = Non envoyé : { $reason }
ui-outbox-status-agent = Mis en attente par un agent d'IA ; envoi à { $time }
ui-outbox-delete-ask = Supprimer ce message sans l'envoyer ?
ui-open-link = Ouvrir le lien
ui-edit-link = Modifier le lien...
ui-remove-link = Supprimer le lien
ui-insert-attachment = Insérer une pièce jointe
ui-insert-picture = Insérer une image
ui-filter-all = Tous les fichiers
ui-filter-pictures = Images
ui-filter-messages = Messages électroniques
ui-save-attachment-as = Enregistrer la pièce jointe sous
ui-not-sent = Le message n'a pas pu être envoyé.
ui-attachment-forgotten = Vous avez écrit « { $word } », mais aucun fichier n’est joint. Envoyer le message quand même ?
ui-send-anyway = Envoyer quand même
ui-go-back = Revenir
ui-not-saved = Le message n'a pas pu être enregistré.
ui-saving-draft = Enregistrement dans le dossier Brouillons...
ui-compose-saved-at = Enregistré dans le dossier Brouillons à { $time }
ui-compose-restored = Restauré après la fermeture inattendue d’Inbox Classic
ui-compose-not-saved = Non enregistré dans le dossier Brouillons : { $reason }
ui-save-changes-ask = Voulez-vous enregistrer les modifications de ce message dans le dossier Brouillons ?
ui-new-message-title = Nouveau message
ui-link-invalid = Tapez une adresse web (https://...) ou un lien e-mail (mailto:...).
ui-link-address = Adresse :
ui-hyperlink = Lien hypertexte
ui-hyperlink-intro = L'adresse vers laquelle pointe le texte sélectionné.
ui-edit-hyperlink = Modifier le lien hypertexte
ui-edit-hyperlink-intro = Adresse de destination du lien. Effacez l'adresse pour supprimer le lien tout en conservant le texte.
ui-not-a-picture = Ce fichier n'est pas une image PNG, JPEG ou GIF, ou il dépasse 10 Mo.
ui-format-color = Couleur de police
ui-format-numbers = Liste numérotée
ui-format-bullets = Liste à puces
ui-format-outdent = Diminuer le retrait
ui-format-indent = Augmenter le retrait
ui-format-left = Aligner à gauche
ui-format-center = Centrer
ui-format-right = Aligner à droite
ui-format-line = Insérer une ligne horizontale
ui-tb-send = Envoyer
ui-tb-save = Enregistrer
ui-tb-attach = Joindre
ui-field-from = De :
ui-field-to = À :
ui-field-cc = Cc :
ui-field-bcc = Cci :
ui-field-subject = Objet :
ui-field-attach = Pièces jointes :
ui-signature = Signature
ui-signature-hint = Ajoutée aux nouveaux messages, aux réponses et aux transferts de ce compte.
ui-signature-not-saved = La signature n'a pas pu être enregistrée.
ui-all-inboxes = Toutes les boîtes
# review: new
ui-all-sent = Tous les envoyés
# review: new
ui-all-drafts = Tous les brouillons
ui-flagged-folder = Avec indicateur
ui-all-folders = Tous les dossiers
ui-the-account = le compte
ui-folder-name = Nom du dossier :
ui-find-hint = Rechercher dans le courrier
ui-find-tip = Recherche dans l'objet, les expéditeurs, les destinataires, les noms des pièces jointes et le texte des messages.
ui-clear-search = Effacer la recherche
ui-no-match = Aucun message ne correspond à « { $words } ».
ui-no-match-all = La recherche porte sur l'objet, les expéditeurs, les destinataires, les noms des pièces jointes et le texte des messages de tous les dossiers. Vérifiez l'orthographe ou essayez avec moins de mots.
ui-no-match-in = La recherche dans { $folder } porte sur l'objet, les expéditeurs, les destinataires, les noms des pièces jointes et le texte des messages. Vérifiez l'orthographe ou essayez avec moins de mots.
ui-no-items = Il n'y a aucun élément dans cet affichage.
ui-choose-folder = Choisissez un dossier pour voir ses messages.
ui-unsubscribe = Se désabonner
ui-open-in-calendar = Ouvrir dans le calendrier
ui-pictures-blocked = Certaines images ont été bloquées pour empêcher l'expéditeur d'identifier votre ordinateur. Cliquez ici pour télécharger les images.
ui-not-shown = Le message n'a pas pu être affiché.
ui-attachment-not-read = La pièce jointe n'a pas pu être lue.
ui-attachment-not-saved = La pièce jointe n'a pas pu être enregistrée.
ui-not-downloaded = Le message n'est pas encore téléchargé.
ui-leave-list = Quitter cette liste de diffusion ?
ui-leave-one-click = Inbox Classic envoie une demande de désabonnement à { $target }, sans ouvrir de page web ni envoyer d'e-mail.
ui-leave-mail = Pour vous désabonner, vous devez envoyer un e-mail à { $target }. Inbox Classic le prépare pour vous. Envoyez-le pour confirmer votre désabonnement.
ui-leave-web = La page de désabonnement de la liste va s'ouvrir dans votre navigateur ({ $target }).
ui-unsubscribing = Désabonnement de { $target }...
ui-cannot-unsubscribe = Ce message ne permet pas de vous désabonner.
ui-unsubscribed = Désabonnement confirmé. La liste indique que vous ne recevrez plus ces messages.
ui-not-unsubscribed = Le désabonnement a échoué : { $reason }
ui-event-span = { $start } à { $end }
ui-event-floating = { $when } (heure de l'expéditeur)
ui-invitation = Invitation : { $title }
ui-invitation-updated = Invitation mise à jour : { $title }
ui-invitation-canceled = Annulé : { $title }
ui-invitation-answer = Réponse à une invitation : { $title }
ui-no-title = (sans titre)
ui-organizer = Organisateur : { $name }
ui-invitation-not-read = L'invitation n'a pas pu être lue.
ui-no-calendar = Aucune application de calendrier n'est disponible sur cet ordinateur pour ouvrir les invitations (fichiers .ics).
ui-messages-not-changed = Les messages n'ont pas pu être modifiés.
ui-new-folder-in-selected = Le nouveau dossier est créé dans le dossier sélectionné.
ui-new-folder-at-top = Le nouveau dossier est créé au premier niveau du compte.
ui-folder-not-created = Le dossier n'a pas pu être créé.
ui-folder-not-renamed = Le dossier n'a pas pu être renommé.
ui-folder-not-deleted = Le dossier n'a pas pu être supprimé.
ui-rename-folder-intro = Saisissez le nouveau nom du dossier « { $folder } ».
ui-properties-of = Propriétés de { $subject }
ui-internet-headers = En-têtes Internet de ce message :
ui-save-messages-in = Enregistrer les messages dans
ui-save-message-as = Enregistrer le message sous
ui-import-choose-folder = Choisissez d'abord le dossier dans lequel importer les messages.
ui-add-account-title = Ajouter un compte de messagerie
ui-accounts-title = Comptes
ui-security-none = Aucune (non chiffrée)
ui-field-required = { $field } est obligatoire.
ui-email-invalid = L'adresse e-mail n'est pas valide.
ui-ports-invalid = Les ports sont des nombres de 1 à 65535.
ui-looking-up = Recherche des paramètres de { $domain }...
ui-found-none = Saisissez les paramètres de compte fournis par votre service de messagerie.
ui-found-change = Modifiez ces paramètres si votre fournisseur vous en a indiqué d'autres.
ui-found-guess = Aucun paramètre n'a été trouvé pour cette adresse. Les noms de serveurs proposés sont des suppositions. Vérifiez-les auprès de votre fournisseur.
ui-found-mx = Inbox Classic a identifié votre fournisseur de messagerie et renseigné les serveurs correspondants.
ui-found-srv = Ces paramètres ont été trouvés dans les enregistrements DNS de votre domaine.
ui-found-autodiscover = Ces paramètres ont été trouvés à l'aide de Microsoft Autodiscover (Exchange).
ui-found-other = Ces paramètres ont été trouvés pour cette adresse.
ui-app-password-needed = { $provider } n'accepte pas votre mot de passe habituel dans les programmes de messagerie. Créez un mot de passe d'application dans votre compte { $provider } et tapez-le dans le champ Mot de passe du formulaire suivant.
ui-app-password-open = Ouvrir les instructions de { $provider } dans votre navigateur ?
ui-plain-warning = Sans chiffrement, toute personne qui intercepte le trafic réseau peut lire votre mot de passe et vos messages. Utilisez cette connexion uniquement avec un serveur sur votre ordinateur ou votre réseau local.
ui-continue-ask = Continuer ?
ui-add-sign-in-app = Ajouter une application de connexion...
ui-turned-off = La connexion avec { $name } est désactivée sur cet ordinateur.
ui-off-here = Désactivé sur cet ordinateur.
ui-why = Pourquoi ?
ui-more-sign-in = Autres options de connexion...
ui-other-account = Pour ajouter un autre compte de messagerie, saisissez votre adresse e-mail et le nom à afficher pour vos destinataires. Les paramètres des serveurs seront recherchés à l'étape suivante.
ui-field-account-name = Nom du compte :
ui-field-name = Nom affiché :
ui-field-email = Adresse e-mail :
ui-field-user = Nom d'utilisateur :
ui-field-password = Mot de passe :
ui-field-imap-host = Serveur entrant (IMAP) :
ui-field-imap-port = Port IMAP :
ui-field-imap-security = Sécurité IMAP :
ui-field-smtp-host = Serveur sortant (SMTP) :
ui-field-smtp-port = Port SMTP :
ui-field-smtp-security = Sécurité SMTP :
ui-field-other-addresses = Autres adresses d’envoi :
ui-sign-in-not-started = La connexion par le navigateur n'a pas pu démarrer.
ui-sign-in-in-browser = Connectez-vous à { $account } dans la fenêtre du navigateur qui s'est ouverte, puis revenez ici.
ui-sign-in-failed = La connexion a échoué : { $reason }
ui-account-not-saved = Le compte n'a pas pu être enregistré.
ui-start-intro = Gmail, Google Workspace, Outlook.com et Microsoft 365 : connectez-vous sur le site de Google ou de Microsoft. Vous y saisissez votre mot de passe, sans le communiquer à Inbox Classic.
ui-start-intro-apps = Connectez-vous par le navigateur avec l'une de vos applications de connexion (Autres options de connexion), ou ajoutez ci-dessous n'importe quel compte de messagerie avec votre nom et votre adresse.
ui-use-app-password = Utiliser un mot de passe d'application
ui-the-provider = votre fournisseur
ui-provider-intro = Connectez-vous au compte { $email } sur le site de { $provider }. Votre mot de passe ne sera pas transmis à Inbox Classic. Vous pouvez aussi utiliser un mot de passe d'application créé dans les paramètres de sécurité de votre compte.
ui-provider-intro-apps = Connectez-vous au compte { $email } sur le site de { $provider } avec l'une de vos applications de connexion (« Autres options de connexion »). Vous pouvez aussi utiliser un mot de passe d'application créé dans les paramètres de sécurité de votre compte.
ui-finish = Terminer
ui-logon = Connexion
ui-enter-password = Saisissez le mot de passe de { $account }.
ui-signs-in-with = Application de connexion : { $app }. La connexion s'effectue dans le navigateur et le compte utilise les serveurs de cette application.
ui-keep-password = Laissez le champ du mot de passe vide pour conserver le mot de passe actuel.
ui-remove-account = Supprimer le compte
ui-remove-account-ask = Supprimer ce compte d'Inbox Classic ? Son courrier reste sur le serveur ; la copie sur cet ordinateur et le mot de passe enregistré sont supprimés.
ui-col-email = Adresse e-mail
ui-col-incoming = Serveur entrant
ui-type-email = Saisissez votre adresse e-mail, par exemple nom@example.com.
ui-ai-agent = Agent d'IA
ui-ai-agent-access = Accès d'un agent d'IA
ui-ai-agents = Agents d'IA
ui-program-path = Programme : { $path }
ui-it-may = Actions autorisées :
ui-accounts-it-may-use = Comptes accessibles :
ui-send-message-ask = Envoyer le message ?
ui-col-name = Nom
ui-never = Jamais
ui-connect-agent = Connecter un agent d'IA
ui-connect-agent-intro = Ajoutez ceci aux serveurs MCP de votre agent (Claude Desktop : Settings > Developer > Edit Config) :
ui-col-program = Programme
ui-col-may = Autorisations
ui-col-last-used = Dernière utilisation
ui-col-when = Date
ui-col-what = Action
ui-sign-in-app = Application de connexion
ui-sign-in-apps = Applications de connexion
ui-add-sign-in-app-title = Ajouter une application de connexion
ui-preset-app-name = Application de connexion { $provider }
ui-issuer-not-checked = l'émetteur ne peut pas être vérifié
ui-checking-issuer = Vérification de { $issuer }...
ui-issuer-unusable = L'émetteur ne peut pas être utilisé : { $reason }
ui-issuer-usable = L'émetteur peut être utilisé.
ui-sign-in-app-not-saved = L'application de connexion n'a pas pu être enregistrée : { $reason }
ui-check = &Vérifier
ui-fill-in-for = Préremplir pour :
ui-app-name = Nom :
ui-issuer = Émetteur :
ui-client-id = ID client :
ui-client-secret = Secret client :
ui-scopes = Autorisations (scopes) :
ui-imap-server = Serveur IMAP :
ui-smtp-server = Serveur SMTP :
ui-redirect-uri = Adresse de redirection :
ui-sign-in-app-intro = Une application de connexion est un client OAuth enregistré auprès de votre fournisseur pour vous connecter dans le navigateur. Choisissez un fournisseur pour préremplir les paramètres, puis ajoutez l'ID client et le secret client, si votre fournisseur en a attribué un.
ui-remove-secret = Un secret client est enregistré. Saisissez-en un nouveau pour le remplacer ou supprimez celui qui est enregistré
ui-register-it = Enregistrer l'application auprès du fournisseur
ui-built-in-note = { $name } est une application intégrée. Vous pouvez uniquement choisir de la proposer ou non aux nouveaux comptes.
ui-client-with-secret = ID client : { $client }, avec un secret client.
ui-client-public = ID client : { $client }, un client public (sans secret).
ui-no-accounts = Aucun compte
ui-remove-sign-in-app = Supprimer l'application de connexion
ui-remove-sign-in-app-ask = Supprimer l'application de connexion { $name } et son secret client enregistré ?
ui-sign-in-app-not-removed = L'application de connexion n'a pas été supprimée. { $reason }
ui-sign-in-apps-intro = Les applications de connexion permettent aux comptes de se connecter par le navigateur. Une application non cochée n'est pas proposée aux nouveaux comptes ; les comptes qui l'utilisent déjà continuent de fonctionner.
ui-col-issuer = Émetteur
ui-col-used-by = Utilisée par
ui-options-system-default = Langue du système ({ $language })
# review: new
ui-settings-general = Général
# review: new
ui-settings-reading = Lecture
# review: changed
ui-settings-new-mail = Nouveau courrier
# review: new
ui-settings-sending = Envoi
# review: new
ui-settings-default-apps = Applications par défaut
# review: new
ui-settings-message-list = Liste des messages
# review: new
ui-settings-messages = Messages
# review: new
ui-settings-label = { $label } :
# review: new
ui-apply = &Appliquer
# review: changed
ui-language-label = &Langue :
ui-restart-note = Redémarrez Inbox Classic pour appliquer la nouvelle langue.
ui-restart-ask = Inbox Classic s'affichera dans la langue choisie ({ $language }) après un redémarrage. Redémarrer maintenant ?
# review: changed
ui-notify-new-mail = Me &prévenir de l'arrivée de nouveaux messages
ui-new-folder-title = Nouveau dossier
ui-rename-folder-title = Renommer le dossier
ui-delete-folder-question = Supprimer le dossier « { $folder } », tous ses messages et ses sous-dossiers ? Ils seront également supprimés du serveur.
ui-properties = &Propriétés
ui-account-sync = &Envoyer et recevoir
ui-account-properties = &Propriétés...
ui-account-move-up = &Monter
ui-account-move-down = &Descendre
ui-menu-open = &Ouvrir
ui-menu-flag = Indi&cateur
ui-menu-view-source = Afficher la &source
ui-save-attachments = Enregistrer les pièces jointes
# review: new
ui-attachment-open = Ouvrir
# review: new
ui-attachment-save-as = Enregistrer sous...
# review: new
ui-attachment-save-all = Tout enregistrer...
# review: new
ui-attachments-strip = Pièces jointes
# review: new
ui-attachment-note-title = Ouverture de ce fichier
# review: new
ui-attachment-program-tip = Ouvrir n’est pas possible pour ce type de fichier : il peut lancer des programmes. Enregistrez-le pour l’ouvrir vous-même.
ui-clear-flag = &Effacer l'indicateur
ui-button-move = &Déplacer
ui-button-copy = &Copier
ui-find-folder = Chercher un dossier
ui-new-folder-in = Le nouveau dossier est créé dans { $folder }.
ui-outbox-send-all = &Tout envoyer maintenant
ui-yes = Oui
ui-no = Non
ui-try-again = Réessayer
ui-remove = &Supprimer
ui-signature-of = Signature - { $account }
ui-sign-in-with = Se connecter avec { $provider }
ui-sign-in-in-browser-yours = Connectez-vous à votre compte dans la fenêtre du navigateur qui s'est ouverte, puis revenez ici.
ui-browser-sign-in-server = { $server } (connexion par le navigateur)
ui-dont-allow = Ne pas autoriser
ui-allow = &Autoriser
ui-dont-send = Ne pas envoyer
ui-edit-first = &Modifier d'abord
ui-new-address = Nouvelle adresse
ui-turn-away = &Refuser
ui-clear-agent-log = Effacer l'historique des agents ?
ui-clear-agent-log-detail = Les modifications effectuées par les agents ne seront pas annulées.
ui-let-agents-connect = &Laisser les agents d'IA se connecter à Inbox Classic
ui-change-button = Modifier…
ui-undo-button = Annuler
ui-rules-title = Règles de message
ui-rules-intro = Les règles trient les nouveaux messages reçus tant qu’Inbox Classic est ouvert. Les règles dont les critères sont remplis s’appliquent dans l’ordre. Dès qu’une règle déplace un message hors de la boîte de réception, les suivantes ne s’appliquent plus à ce message.
ui-rules-none = Aucune règle pour l’instant. Cliquez sur Nouvelle pour en créer une.
ui-rule-new = &Nouvelle...
ui-rule-edit = M&odifier...
ui-rule-delete-button = &Supprimer
ui-rule-title = Règle de message
ui-rule-name = Nom :
ui-rule-account = Compte :
ui-rule-all-accounts = Tous les comptes
ui-rule-query = Critères de recherche :
ui-rule-query-hint = Utilisez les mêmes termes que dans la zone de recherche, par exemple from:anne@example.com, subject:facture ou list:news.example.com.
ui-rule-count = { $count ->
    [one] { $count } message de la boîte de réception correspond actuellement à ces critères.
   *[other] { $count } messages de la boîte de réception correspondent actuellement à ces critères.
}
ui-rule-show = A&fficher
ui-rule-actions = Actions :
ui-rule-move = Le &déplacer vers :
ui-rule-mark-read = Le marquer comme &lu
ui-rule-flag = Lui ajouter un &indicateur
ui-rule-archive = L’&archiver
ui-rule-junk = Le déplacer dans le &Courrier indésirable
ui-rule-delete = Le &supprimer
ui-rule-quiet = Ne &pas me prévenir
ui-rule-apply-now = L’appliquer aussi aux messages déjà dans la &boîte de réception
ui-rule-delete-ask = Supprimer la règle « { $name } » ?
ui-create-rule = Créer une règle...
ui-rules-applied = { $count ->
    [one] { $count } message trié selon vos règles
   *[other] { $count } messages triés selon vos règles
}
ui-col-rule-matches = Critères
ui-clear-button = &Effacer
ui-how-to-connect = Comment connecter un agent…
ui-agent-programs = Programmes dont les agents ont demandé à utiliser votre courrier
ui-what-agents-did = Historique des agents
ui-restart-now = &Redémarrer maintenant
ui-restart-later = &Plus tard

## The Address Book (Tools > Address Book), Contact and Group Properties, Select Recipients

ui-tb-new-contact = Nouveau contact
ui-tb-new-group = Nouveau groupe
ui-tb-properties = Propriétés
ui-tb-write-to = Écrire à
ui-menu-new-contact = Nouveau &contact...
ui-menu-new-group = Nouveau &groupe...
ui-menu-write-to = É&crire à
ui-menu-delete = &Supprimer
ui-book-find-hint = Tapez un nom ou une adresse e-mail
ui-book-all-contacts = Tous les contacts
ui-col-phone = Téléphone
ui-book-empty = Le carnet d'adresses est vide. Cliquez sur « Nouveau contact » pour ajouter un contact ou importez un fichier vCard ou CSV depuis le menu Fichier.
ui-book-no-match = Aucun contact ne correspond à « { $words } ».
ui-book-delete-ask = { $count ->
    [one] Supprimer ce contact du carnet d'adresses ?
   *[other] Supprimer ces { $count } contacts du carnet d'adresses ?
}
ui-group-delete-ask = Supprimer le groupe « { $name } » ? Ses contacts resteront dans le carnet d'adresses.
ui-book-no-address = { $name } n'a pas d'adresse e-mail.
ui-new-contact-title = Nouveau contact
ui-contact-title = Propriétés de { $name }
ui-contact-first = Prénom :
ui-contact-last = Nom :
ui-contact-display = Nom affiché :
ui-contact-nickname = Surnom :
ui-contact-company = Société :
ui-contact-addresses = Adresses e-mail :
ui-contact-address-hint = Tapez une adresse e-mail
ui-contact-add = &Ajouter
ui-contact-set-default = Définir par &défaut
ui-contact-default = { $address } (par défaut)
ui-contact-phones = Numéros de téléphone :
ui-phone-home = Domicile
ui-phone-work = Travail
ui-phone-mobile = Mobile
ui-phone-other = Autre
ui-contact-notes = Notes :
ui-contact-name-needed = Tapez un nom ou une adresse e-mail pour le contact.
ui-contact-address-invalid = « { $address } » n'est pas une adresse e-mail valide.
ui-contact-not-saved = Le contact n'a pas pu être enregistré : { $reason }
ui-new-group-title = Nouveau groupe
ui-group-title = Propriétés de { $name }
ui-group-name = Nom du groupe :
ui-group-members = Membres :
ui-group-select-members = &Sélectionner les membres...
ui-group-new-member = Ajouter une adresse e-mail qui n'est pas dans le carnet d'adresses :
ui-group-name-needed = Tapez un nom pour le groupe.
ui-group-not-saved = Le groupe n'a pas pu être enregistré : { $reason }
ui-group-members-count = { $count ->
    [one] { $count } membre
   *[other] { $count } membres
}
ui-select-recipients = Sélectionner les destinataires
ui-select-members = Sélectionner les membres du groupe
ui-pick-intro = Tapez un nom ou sélectionnez-le dans la liste :
ui-pick-recipients = Destinataires du message :
ui-pick-members = Membres du groupe :
ui-pick-to = &À →
ui-pick-cc = &Cc →
ui-pick-bcc = Cc&i →
ui-pick-add = &Ajouter →
ui-pick-tip = Choisir les destinataires dans le carnet d'adresses
ui-filter-address-books = Carnets d'adresses (vCard, CSV)
ui-filter-vcard = Fichiers vCard
ui-book-export-name = Carnet d'adresses
ui-book-imported = { $added ->
    [one] { $added } contact ajouté.
   *[other] { $added } contacts ajoutés.
} { $skipped ->
    [0] Aucun doublon trouvé.
    [one] 1 contact ignoré, car il figure déjà dans le carnet d'adresses.
   *[other] { $skipped } contacts ignorés, car ils figurent déjà dans le carnet d'adresses.
}
ui-book-not-imported = Le carnet d'adresses n'a pas pu être importé : { $reason }
ui-book-exported = { $count ->
    [one] { $count } contact enregistré dans { $file }.
   *[other] { $count } contacts enregistrés dans { $file }.
}
ui-book-not-exported = Le carnet d'adresses n'a pas pu être enregistré : { $reason }
ui-code-copied = Code copié
# review: changed
ui-codes-in-notifications = Afficher les &codes de connexion dans les notifications de nouveau courrier
ui-tool-unread-only = Non lus
ui-no-unread = Il n'y a aucun message non lu ici.
ui-pictures-always-sender = Toujours télécharger les images de { $sender }
ui-pictures-always-domain = Toujours télécharger les images des expéditeurs du domaine { $domain }
ui-pictures-unconfirmed = Le domaine de l'expéditeur ({ $domain }) n'a pas pu être vérifié. Les images de ce message ne sont donc pas téléchargées automatiquement.
# review: changed
ui-pictures-always-option = &Télécharger les images de tous les messages
ui-pictures-always-warning = Les expéditeurs peuvent alors savoir quand vous lisez leurs messages.
# review: new
ui-protection-details = &Détails...
# review: new
ui-protection-details-title = Détails de sécurité
ui-download-heading = Téléchargement
# review: changed
ui-download-ahead = &Télécharger les messages à l’avance :
ui-download-ahead-recent = Messages récents de 1 Mo maximum
ui-download-ahead-all = Tous les messages
ui-download-ahead-never = Seulement à l’ouverture
# review: changed
ui-download-limit = &Espace maximal par compte :
# review: changed
ui-send-delay = &Délai avant l’envoi :
ui-send-delay-note = Tant qu’un message est en attente d’envoi, vous pouvez annuler son envoi avec le bouton Annuler.
ui-dark-messages = Afficher les messages sur fond sombre lorsque le système est en mode sombre
ui-sending-in = Envoi de { $subject } dans { $count ->
    [one] { $count } seconde
   *[other] { $count } secondes
}
ui-send-undone = { $subject } n’a pas été envoyé. Le message est à nouveau ouvert pour être modifié.
ui-send-too-late = { $subject } a déjà été envoyé.
ui-outbox-status-undo = Envoi à { $time }
ui-download-note = Les messages téléchargés à l'avance s'ouvrent immédiatement. Lorsque la limite de stockage est dépassée, les copies locales les plus anciennes sont supprimées, puis téléchargées à nouveau à l'ouverture des messages.
ui-attachment-downloading = Le téléchargement de ce message est encore en cours. Réessayez une fois le téléchargement terminé.
# review: changed
ui-trusted-senders-button = &Expéditeurs de confiance...
ui-trusted-senders-title = Expéditeurs de confiance
ui-trusted-senders-note = Les images des messages de ces expéditeurs sont téléchargées automatiquement lorsque votre fournisseur de messagerie vérifie le domaine de l'expéditeur.
ui-trusted-everyone-at = Tous les expéditeurs du domaine { $domain }
ui-trusted-senders-empty = Aucun expéditeur de confiance n'a encore été ajouté.
# review: changed
ui-eml-default = &Ouvrir les fichiers .eml avec Inbox Classic
ui-eml-default-done = Inbox Classic ouvre maintenant les fichiers .eml.
ui-eml-default-failed = Impossible de définir Inbox Classic comme application par défaut pour les fichiers .eml : { $reason }
ui-folders = Dossiers
ui-sorted-by = Tri : { $field }
# review: changed
ui-layout-label = &Disposition :
ui-columns-note = La fenêtre est assez large pour la disposition en colonnes. Vous pouvez modifier la disposition dans Affichage > Disposition.
ui-row-unread = Non lu
ui-row-flagged = Avec indicateur
ui-row-attachments = Avec pièces jointes
ui-row-messages = { $count ->
    [one] { $count } message
   *[other] { $count } messages
}
# review: changed
ui-list-pictures = Afficher &les images des expéditeurs dans la liste des messages
# review: changed
ui-list-pictures-note = Dans la disposition en colonnes, affiche les logos de marque ou les photos du carnet d'adresses pour les expéditeurs vérifiés, et les initiales si aucune image n'est disponible. Les logos sont téléchargés une seule fois par marque, et non à chaque message.
ui-card-picture = Image :
ui-card-picture-choose = &Choisir...
ui-picture-not-picture = Ce fichier n'est pas une image PNG ou JPEG.
ui-picture-too-large = Cette image est trop grande. Choisissez une image de 10 Mo maximum, dont la largeur et la hauteur ne dépassent pas 8000 pixels.

## Encryption keys (Tools > Encryption Keys, Account Properties > Security, a contact's key)
# review: new
ui-keys-title = Clés de chiffrement
# review: new
ui-keys-intro = Vos clés signent vos messages et ouvrent le courrier chiffré pour vous. Les clés de vos contacts vérifient leurs signatures et chiffrent le courrier qui leur est destiné.
# review: new
ui-keys-empty = Aucune clé pour l'instant. Cliquez sur Nouvelle clé pour créer la vôtre, ou sur Importer pour ajouter une clé que vous avez déjà.
# review: new
ui-keys-col-name = Nom
# review: new
ui-keys-col-address = Adresse
# review: new
ui-keys-col-kind = Type
# review: new
ui-keys-col-status = État
# review: new
ui-keys-kind-own = Votre clé
# review: new
ui-keys-kind-contact = Contact
# review: new
ui-keys-status-verified = { $status }, vérifiée
# review: new
ui-keys-new = &Nouvelle clé...
# review: new
ui-keys-import = &Importer...
# review: new
ui-keys-export = &Exporter...
# review: new
ui-keys-backup = &Sauvegarder...
# review: new
ui-keys-verify = &Vérifier...
# review: new
ui-keys-new-title = Nouvelle clé
# review: new
ui-keys-new-for = Créer une clé pour :
# review: new
ui-keys-new-make = &Créer la clé
# review: new
ui-keys-no-account = Ajoutez d'abord un compte de messagerie : une clé est créée pour les adresses d'un compte.
# review: new
ui-keys-memory-only = Les mots de passe sont gardés en mémoire seulement : une clé privée créée ou importée maintenant ne pourra plus servir après la fermeture d'Inbox Classic.
# review: new
ui-keys-backup-offer = Votre nouvelle clé est prête. Enregistrer une sauvegarde maintenant ? Si cet ordinateur est perdu ou réinitialisé, la clé ne pourra revenir que d'une sauvegarde.
# review: new
ui-keys-backup-now = &Enregistrer une sauvegarde...
# review: new
ui-keys-later = &Plus tard
# review: new
ui-keys-backup-title = Sauvegarder la clé
# review: new
ui-keys-backup-intro = La sauvegarde est protégée par une phrase secrète. Gardez le fichier et la phrase dans des endroits sûrs différents : il faut les deux pour récupérer la clé.
# review: new
ui-keys-passphrase = &Phrase secrète :
# review: new
ui-keys-passphrase-again = &Saisissez-la à nouveau :
# review: new
ui-keys-passphrase-differ = Les phrases secrètes ne sont pas identiques.
# review: new
ui-keys-passphrase-short = Utilisez une phrase secrète d'au moins 8 caractères.
# review: new
ui-keys-backup-saved = La sauvegarde a été enregistrée.
# review: new
ui-keys-import-title = Importer une clé
# review: new
ui-keys-import-passphrase = Cette clé privée est protégée par une phrase secrète. Saisissez-la pour importer la clé :
# review: new
ui-keys-file-filter = Clés OpenPGP
# review: new
ui-keys-use-for = Utiliser cette clé pour { $addresses } ? Vos messages envoyés de là seront signés avec elle, et le courrier chiffré pour elle pourra être lu ici.
# review: new
ui-keys-use = &Utiliser
# review: new
ui-keys-not-now = &Pas maintenant
# review: new
ui-keys-remove-own = Supprimer votre clé { $fingerprint } ? Le courrier chiffré pour elle ne pourra plus être lu ici, sauf si vous importez à nouveau sa sauvegarde.
# review: new
ui-keys-remove-contact = Supprimer la clé de { $name } ? Ses signatures ne pourront pas être vérifiées ni le courrier lui être chiffré tant que vous n'aurez pas ajouté sa clé à nouveau.
# review: new
ui-key-properties-title = Propriétés de la clé
# review: new
ui-key-names = Noms :
# review: new
ui-key-fingerprint = Empreinte :
# review: new
ui-key-status = État :
# review: new
ui-key-created = Créée le :
# review: new
ui-key-expires = Expire le :
# review: new
ui-key-never = Jamais
# review: new
ui-key-algorithm = Algorithme :
# review: new
ui-key-source = Origine :
# review: new
ui-key-addresses = Adresses :
# review: new
ui-key-address-verified = { $address } (vérifiée)
# review: new
ui-key-address-not-verified = { $address } (non vérifiée)
# review: new
ui-verify-title = Vérifier la clé
# review: new
ui-verify-intro = Demandez à { $name } de vous lire l'empreinte de sa clé depuis sa propre application, en personne ou au téléphone. Ne la comparez pas avec une empreinte reçue par courriel : qui pourrait changer la clé pourrait aussi changer celle-ci.
# review: new
ui-verify-fingerprint = L'empreinte de la clé que vous avez :
# review: new
ui-verify-marks = { $count ->
    [one] S’ils correspondent, la clé est marquée comme la leur pour { $addresses }. Si cette adresse n’est pas la leur, cliquez sur « Elles diffèrent ».
   *[other] S’ils correspondent, la clé est marquée comme la leur pour { $addresses }. Si l’une de ces adresses n’est pas la leur, cliquez sur « Elles diffèrent ».
}
# review: new
ui-verify-match = Elles &correspondent
# review: new
ui-verify-differ = Elles &diffèrent
# review: new
ui-verify-differs = La clé que vous avez n'est pas celle de { $name }. Supprimez-la et redemandez sa clé.
# review: new
ui-verify-unmark = Marquer comme &non vérifiée
# review: new
ui-account-security = Sécurité
# review: new
ui-account-security-intro = Avec une clé, vos messages peuvent être signés et d'autres personnes peuvent vous envoyer du courrier chiffré.
# review: new
ui-account-key = &Clé de ce compte :
# review: new
ui-account-key-none = Aucune
# review: new
ui-account-key-new = &Nouvelle clé...
# review: new
ui-account-autocrypt = &Envoyer ma clé publique avec mes messages (Autocrypt)
# review: new
ui-contact-key = Clé de chiffrement :
# review: new
ui-contact-key-none = Aucune clé
# review: new
ui-contact-key-use-new = &Utiliser la nouvelle clé
# review: new
ui-contact-key-keep = &Garder l'actuelle
# review: new
ui-setup-export-title = Exporter les paramètres et comptes
# review: new
ui-setup-import-title = Importer les paramètres et comptes
# review: new
ui-setup-export-intro = Choisissez ce que vous emportez sur un autre ordinateur. Le fichier ne contient aucun message : ils seront téléchargés à nouveau là-bas.
# review: new
ui-setup-use-passphrase = &Protéger le fichier par une phrase secrète
# review: new
ui-setup-passphrase-note = Avec une phrase secrète, le fichier est chiffré et contient aussi vos mots de passe, connexions et clés privées. Sans elle, chaque compte demande son mot de passe sur l’autre ordinateur.
# review: new
ui-setup-export-button = &Exporter...
# review: new
ui-setup-file-filter = Paramètres et comptes Inbox Classic
# review: new
ui-setup-ask-passphrase = Ce fichier est protégé par une phrase secrète. Saisissez-la pour voir ce qu’il contient :
# review: new
ui-setup-import-intro = Choisissez ce qu’il faut importer. Les comptes déjà présents sur cet ordinateur restent tels quels.
# review: new
ui-setup-from = Enregistré par Inbox Classic { $version } le { $date }.
# review: new
ui-setup-import-button = &Importer
# review: new
ui-setup-done = Terminé
# review: new
ui-setup-first-run = Importer les paramètres et comptes d’un autre ordinateur...
