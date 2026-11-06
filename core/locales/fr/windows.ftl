# Les mots des fenêtres de l'application Windows (app/src), identifiants commençant par win-. L'application remplit les
# éléments entre { $accolades } ; un & marque la lettre d'un élément de menu ou d'un bouton (&& est une esperluette).

## La fenêtre principale

win-tb-create-mail = Créer un message
win-tb-reply = Répondre
win-tb-reply-all = Rép. à tous
win-tb-forward = Transférer
win-tb-print = Imprimer
win-tb-delete = Supprimer
win-tb-junk = Indésirable
win-tb-not-junk = Acceptable
win-tb-sync = Envoyer/Recevoir
win-tb-mark-read = Lu
win-tb-mark-unread = Non lu
win-flag-menu = &Indicateur
win-still-running = Inbox Classic est toujours ouvert
win-still-running-detail = Il continue à relever le courrier ici. Cliquez sur l'icône pour l'ouvrir, ou cliquez dessus avec le bouton droit pour le quitter.
win-no-subject = (sans objet)
win-quoted = « { $subject } »
win-new-messages = { $count ->
    [one] { $count } nouveau message
   *[other] { $count } nouveaux messages
}
win-newest-from = Le plus récent, de { $sender } : { $subject }
win-outbox-waiting = { $count ->
    [one] { $count } message dans la Boîte d'envoi
   *[other] { $count } messages dans la Boîte d'envoi
}
win-outbox-waits = { $subject } attend dans la Boîte d'envoi
win-outbox-sending = Envoi de { $subject }...
win-from-account = De { $account }
win-sign-in-refused = La connexion de { $account } a été refusée ou a expiré.
win-sign-in-again-ask = Se connecter à nouveau dans le navigateur ?
win-sign-in-again-failed = La nouvelle connexion n'a pas fonctionné : { $reason }
win-unknown-reason = raison inconnue
win-checking = Recherche de nouveaux messages sur { $account }...
win-done = Terminé
win-sent-at = { $subject } envoyé à { $time }
win-draft-saved = Message enregistré dans Brouillons.
win-draft-not-saved = Le message n'a pas été enregistré dans Brouillons : { $reason }
win-about-core = Noyau { $version }
win-add-account-first = Ajoutez d'abord un compte de messagerie.
win-add-account-first-link = Ajoutez d'abord un compte de messagerie, puis cliquez à nouveau sur le lien de courrier.
win-default-app-is = Inbox Classic est votre programme de messagerie par défaut : les liens de courrier ouvrent ici un nouveau message.
win-default-app-not-installed = Cette copie d'Inbox Classic n'a pas été installée, Windows ne la propose donc pas comme programme de messagerie. Installez-la pour la choisir.
win-default-app-settings = Windows ouvre ses paramètres d'applications par défaut pour Inbox Classic. Choisissez-le pour MAILTO.
win-select-message-first = Sélectionnez d'abord un message.
win-store-not-opened = Le stockage du courrier n'a pas pu être ouvert.
win-store-or-cert-not-opened = Le stockage du courrier ou le fichier de certificat n'a pas pu être ouvert.
win-no-unread = Aucun message non lu
win-unread-messages = { $count ->
    [one] { $count } message non lu
   *[other] { $count } messages non lus
}
win-help-title = Aide d'Inbox Classic
win-help-missing = L'aide manque dans cette copie d'Inbox Classic.
win-print-failed = Le message n'a pas pu être imprimé.
win-print-title = Imprimer
win-print-title-of = Imprimer : { $subject }
win-no-bodies = Le contenu des messages ne peut pas être affiché.
win-webview-failed = La création du WebView2 a échoué.
win-webview-missing = Le runtime WebView2 n'est pas disponible.

## Boutons et mots de plusieurs fenêtres

win-ok = OK
win-cancel = Annuler
win-close = Fermer
win-delete-button = &Supprimer
win-find-label = &Rechercher :
win-col-subject = Objet
win-col-to = À
win-col-from = De
win-col-received = Reçu
win-col-size = Taille
win-col-folder = Dossier
win-col-account = Compte
win-col-queued = En file
win-col-status = État
win-save-as-button = Enregistrer &sous...
win-too-many-files = Trop de fichiers à la fois : choisissez-en moins.

## La Boîte d'envoi

win-outbox-title = Boîte d'envoi
win-outbox-status-waiting = En attente
win-outbox-status-not-sent = Non envoyé : { $reason }
win-outbox-status-agent = Envoyé par un agent d'IA ; part à { $time }
win-outbox-delete-ask = Supprimer ce message sans l'envoyer ?
win-outbox-send-all = &Tout envoyer maintenant

## La fenêtre de rédaction

win-editor-failed = Les messages ne peuvent pas être rédigés.
win-open-link = Ouvrir le lien
win-edit-link = Modifier le lien...
win-remove-link = Supprimer le lien
win-ctrl-click-to-open = ({ $ctrl }+clic pour ouvrir)
win-insert-attachment = Insérer une pièce jointe
win-insert-picture = Insérer une image
win-filter-all = Tous les fichiers
win-filter-pictures = Images
win-filter-messages = Messages électroniques
win-save-attachment-as = Enregistrer la pièce jointe sous
win-remove-file = &Supprimer
win-not-sent = Le message n'a pas pu être envoyé.
win-not-saved = Le message n'a pas pu être enregistré.
win-saving-draft = Enregistrement dans Brouillons...
win-compose-saved-at = Enregistré dans Brouillons à { $time }
win-compose-not-saved = Non enregistré dans Brouillons : { $reason }
win-save-changes-ask = Voulez-vous enregistrer les modifications de ce message dans Brouillons ?
win-new-message-title = Nouveau message
win-link-invalid = Tapez une adresse web (https://...) ou un lien de courrier (mailto:...).
win-link-address = Adresse :
win-hyperlink = Lien hypertexte
win-hyperlink-intro = L'adresse vers laquelle pointe le texte sélectionné.
win-edit-hyperlink = Modifier le lien hypertexte
win-edit-hyperlink-intro = Où mène le lien. Videz l'adresse pour supprimer le lien et garder son texte.
win-not-a-picture = Ce fichier n'est pas une image PNG, JPEG ou GIF, ou il dépasse 10 Mo.
win-format-bold = Gras ({ $ctrl }+B)
win-format-italic = Italique ({ $ctrl }+I)
win-format-underline = Souligné ({ $ctrl }+U)
win-format-color = Couleur de police
win-format-numbers = Liste numérotée
win-format-bullets = Liste à puces
win-format-outdent = Diminuer le retrait
win-format-indent = Augmenter le retrait
win-format-left = Aligner à gauche
win-format-center = Centrer
win-format-right = Aligner à droite
win-format-link = Lien hypertexte ({ $ctrl }+K)
win-format-line = Insérer une ligne horizontale
win-tb-send = Envoyer
win-tb-save = Enregistrer
win-tb-attach = Joindre
win-field-from = De :
win-field-to = À :
win-field-cc = Cc :
win-field-bcc = Cci :
win-field-subject = Objet :
win-field-attach = Joint :
win-show-cc = &Cc
win-show-bcc = C&ci
win-signature = Signature
win-signature-title = Signature : { $account }
win-signature-hint = Ajoutée aux nouveaux messages, réponses et transferts de ce compte.
win-signature-not-saved = La signature n'a pas pu être enregistrée.

## Les dossiers, la liste des messages et le volet de lecture

win-all-inboxes = Toutes les boîtes
win-all-folders = Tous les dossiers
win-the-account = le compte
win-folder-name = Nom du dossier :
win-find-hint = Rechercher dans le courrier
win-find-tip = Trouve des mots dans l'objet, les personnes, les noms de fichiers et le texte des messages.
win-clear-search = Effacer la recherche
win-search-found-all = { $count ->
    [0] Aucun résultat pour « { $words } » dans tous les dossiers
    [one] { $count } résultat pour « { $words } » dans tous les dossiers
   *[other] { $count } résultats pour « { $words } » dans tous les dossiers
}
win-search-found-in = { $count ->
    [0] Aucun résultat pour « { $words } » dans { $folder }
    [one] { $count } résultat pour « { $words } » dans { $folder }
   *[other] { $count } résultats pour « { $words } » dans { $folder }
}
win-search-indexing = { $count ->
    [one] indexation du texte de { $count } message en cours
   *[other] indexation du texte de { $count } messages en cours
}
win-no-match = Aucun message ne correspond à « { $words } ».
win-no-match-all = La recherche porte sur l'objet, les personnes, les noms de fichiers et le texte des messages de tous les dossiers. Vérifiez l'orthographe, ou essayez avec moins de mots.
win-no-match-in = La recherche porte sur l'objet, les personnes, les noms de fichiers et le texte des messages de { $folder }. Vérifiez l'orthographe, ou essayez avec moins de mots.
win-no-match-indexing = { $count ->
    [one] Le texte de { $count } message est encore en cours d'indexation, d'autres résultats peuvent donc apparaître bientôt.
   *[other] Le texte de { $count } messages est encore en cours d'indexation, d'autres résultats peuvent donc apparaître bientôt.
}
win-no-items = Il n'y a aucun élément dans cet affichage.
win-choose-folder = Choisissez un dossier pour voir ses messages.
win-unsubscribe = Se désabonner
win-open-in-calendar = Ouvrir dans le calendrier
win-files = { $count ->
    [one] { $count } fichier
   *[other] { $count } fichiers
}
win-pictures-blocked = Certaines images ont été bloquées pour empêcher l'expéditeur d'identifier votre ordinateur. Cliquez ici pour télécharger les images.
win-click-to-retry = Cliquez ici pour réessayer.
win-not-shown = Le message n'a pas pu être affiché.
win-save-attachments = &Enregistrer les pièces jointes...
win-attachment-not-read = La pièce jointe n'a pas pu être lue.
win-attachment-not-saved = La pièce jointe n'a pas pu être enregistrée.
win-not-downloaded = Le message n'est pas encore téléchargé.
win-files-not-saved = { $failed } des { $count } fichiers n'ont pas pu être enregistrés.
win-leave-list = Quitter cette liste de diffusion ?
win-leave-one-click = Inbox Classic demande à { $target } de ne plus vous l'envoyer. Aucune page ne s'ouvre et aucun message n'est envoyé.
win-leave-mail = La liste demande un message à { $target }. Inbox Classic le rédige pour vous ; envoyez-le pour vous désabonner.
win-leave-web = La page de la liste prévue pour cela s'ouvre dans votre navigateur ({ $target }).
win-unsubscribing = Désabonnement de { $target }...
win-cannot-unsubscribe = Ce message ne permet pas de vous désabonner.
win-unsubscribed = Désabonné. La liste indique qu'elle cessera d'envoyer ce courrier.
win-not-unsubscribed = Le désabonnement a échoué : { $reason }
win-event-span = { $start } au { $end }
win-event-floating = { $when } (heure de l'expéditeur)
win-invitation = Invitation : { $title }
win-invitation-updated = Invitation mise à jour : { $title }
win-invitation-canceled = Annulé : { $title }
win-invitation-answer = Réponse à une invitation : { $title }
win-no-title = (sans titre)
win-organizer = Organisateur : { $name }
win-attendees = { $count ->
    [one] { $count } participant
   *[other] { $count } participants
}
win-invitation-not-read = L'invitation n'a pas pu être lue.
win-no-calendar = Aucun programme de calendrier de cet ordinateur n'ouvre les invitations (fichiers .ics).
win-messages-not-changed = Les messages n'ont pas pu être modifiés.
win-copy-button = &Copier
win-move-button = &Déplacer
win-new-folder-in-highlighted = Le nouveau dossier est créé dans le dossier mis en évidence.
win-new-folder-in-selected = Le nouveau dossier est créé dans le dossier sélectionné.
win-new-folder-at-top = Le nouveau dossier est créé au premier niveau du compte.
win-folder-not-created = Le dossier n'a pas pu être créé.
win-folder-not-renamed = Le dossier n'a pas pu être renommé.
win-folder-not-deleted = Le dossier n'a pas pu être supprimé.
win-rename-folder-intro = Le nouveau nom du dossier { $folder }.
win-delete-folder-ask = Supprimer le dossier « { $folder } » avec ses messages et les dossiers qu'il contient ? Il est aussi supprimé sur le serveur.
win-clear-flag = &Effacer l'indicateur
win-rename = &Renommer...
win-open = &Ouvrir
win-view-source = Afficher la &source
win-properties = &Propriétés
win-properties-of = Propriétés de { $subject }
win-internet-headers = En-têtes Internet de ce message :
win-save-messages-in = Enregistrer les messages dans
win-save-message-as = Enregistrer le message sous
win-messages-not-saved = Les messages n'ont pas pu être enregistrés.
win-messages-not-forwarded = Les messages n'ont pas pu être transférés.
win-import-choose-folder = Choisissez d'abord le dossier où placer les messages.

## Comptes

win-add-account-title = Ajouter un compte de messagerie
win-accounts-title = Comptes
win-security-none = Aucune (non chiffré)
win-field-required = { $field } est obligatoire.
win-email-invalid = L'adresse électronique n'est pas valide.
win-ports-invalid = Les ports sont des nombres de 1 à 65535.
win-looking-up = Recherche des paramètres de { $domain }...
win-found-none = Saisissez les informations de compte que votre fournisseur de messagerie vous a données.
win-found-change = Modifiez-les si votre fournisseur vous en a donné d'autres.
win-found-guess = Aucun paramètre n'a été trouvé pour cette adresse : voici les noms habituels, vérifiez-les auprès de votre fournisseur.
win-found-mx = Votre courrier est géré par un fournisseur qu'Inbox Classic connaît ; voici ses serveurs.
win-found-srv = Ces paramètres ont été trouvés dans les enregistrements DNS de votre domaine.
win-found-autodiscover = Ces paramètres ont été trouvés par la découverte automatique de Microsoft (Exchange).
win-found-other = Ces paramètres ont été trouvés pour cette adresse.
win-app-password-needed = { $provider } n'accepte pas votre mot de passe habituel dans les programmes de messagerie. Créez un mot de passe d'application dans votre compte { $provider } et tapez-le dans le champ Mot de passe du formulaire suivant.
win-app-password-open = Ouvrir les instructions de { $provider } dans votre navigateur ?
win-plain-warning = Sans chiffrement, votre mot de passe et votre courrier traversent le réseau lisibles par quiconque sur le chemin. N'utilisez ceci que pour un serveur sur votre propre ordinateur ou réseau.
win-continue-ask = Continuer ?
win-sign-in-google = Se connecter avec Google
win-sign-in-microsoft = Se connecter avec Microsoft
win-add-sign-in-app = Ajouter une application de connexion...
win-turned-off = { $name } est désactivé sur cet ordinateur.
win-off-here = Désactivé sur cet ordinateur.
win-why = Pourquoi ?
win-more-sign-in = Autres options de connexion...
win-next = &Suivant >
win-other-account = Tout autre compte de messagerie : votre nom tel que les autres le voient et votre adresse électronique. Ses serveurs sont recherchés ensuite.
win-field-name = Nom complet :
win-field-email = Adresse électronique :
win-field-user = Nom d'utilisateur :
win-field-password = Mot de passe :
win-field-imap-host = Serveur entrant (IMAP) :
win-field-imap-port = Port IMAP :
win-field-imap-security = Sécurité IMAP :
win-field-smtp-host = Serveur sortant (SMTP) :
win-field-smtp-port = Port SMTP :
win-field-smtp-security = Sécurité SMTP :
win-sign-in-not-started = La connexion par le navigateur n'a pas pu commencer.
win-your-account = votre compte
win-sign-in-in-browser = Connectez-vous à { $account } dans la fenêtre du navigateur qui s'est ouverte, puis revenez ici.
win-sign-in-failed = La connexion n'a pas fonctionné : { $reason }
win-account-not-saved = Le compte n'a pas pu être enregistré.
win-start-intro = Gmail, Google Workspace, Outlook.com et Microsoft 365 : connectez-vous sur la page de Google ou de Microsoft. Votre mot de passe se tape là-bas, jamais dans Inbox Classic.
win-start-intro-apps = Connectez-vous par le navigateur avec l'une de vos applications de connexion (Autres options de connexion), ou ajoutez ci-dessous n'importe quel compte de messagerie avec votre nom et votre adresse.
win-use-app-password = Mot de passe d'application
win-the-provider = votre fournisseur
win-provider-intro = { $email } se connecte sur la page de { $provider }, sans donner votre mot de passe à Inbox Classic. Ou utilisez un mot de passe d'application créé dans les paramètres de sécurité de votre compte.
win-provider-intro-apps = { $email } peut se connecter sur la page de { $provider } avec l'une de vos applications de connexion (Autres options de connexion). Ou utilisez un mot de passe d'application créé dans les paramètres de sécurité de votre compte.
win-finish = Terminer
win-logon = Connexion
win-enter-password = Saisissez le mot de passe de { $account }.
win-browser-sign-in = (connexion par le navigateur)
win-signs-in-with = Se connecte avec : { $app }. Il se connecte par le navigateur et utilise les serveurs de sa connexion.
win-keep-password = Laissez le mot de passe vide pour garder celui que vous avez.
win-remove-account = Supprimer le compte
win-remove-account-ask = Supprimer ce compte d'Inbox Classic ? Son courrier reste sur le serveur ; la copie sur cet ordinateur et le mot de passe enregistré sont supprimés.
win-col-email = Adresse électronique
win-col-incoming = Serveur entrant
win-add = &Ajouter...
win-properties-button = &Propriétés...
win-signature-button = Si&gnature...
win-sign-in-apps-button = Applications de &connexion...
win-type-email = Tapez votre adresse électronique, nom@example.com.

## Agents d'IA

win-ai-agent = Agent d'IA
win-ai-agent-access = Accès d'un agent d'IA
win-ai-agents = Agents d'IA
win-program-path = Programme : { $path }
win-it-may = Il peut :
win-accounts-it-may-use = Comptes qu'il peut utiliser :
win-allow = &Autoriser
win-dont-allow = &Ne pas autoriser
win-turn-away = &Refuser
win-send-message-ask = Envoyer le message ?
win-col-address = Adresse
win-col-name = Nom
win-never-written-to = Jamais écrit
win-send = &Envoyer
win-edit-first = &Modifier d'abord
win-dont-send = &Ne pas envoyer
win-never = Jamais
win-forget-program-ask = Oublier ce programme et ce que ses agents ont fait ? La question sera reposée à sa prochaine connexion.
win-clear-log-ask = Effacer la liste de ce que les agents ont fait ? Ce qu'ils ont fait reste fait.
win-connect-agent = Connecter un agent d'IA
win-connect-agent-intro = Ajoutez ceci aux serveurs MCP de votre agent (Claude Desktop : Settings > Developer > Edit Config) :
win-let-agents-connect = &Laisser les agents d'IA se connecter à Inbox Classic
win-agent-programs = &Programmes dont les agents ont demandé à utiliser votre courrier :
win-col-program = Programme
win-col-may = Peut
win-col-last-used = Dernière utilisation
win-change = &Modifier...
win-what-agents-did = Ce que les agents ont &fait :
win-col-when = Quand
win-col-what = Quoi
win-clear = &Effacer
win-how-to-connect = Comment connecter un agent

## Applications de connexion

win-sign-in-app = Application de connexion
win-sign-in-apps = Applications de connexion
win-add-sign-in-app-title = Ajouter une application de connexion
win-preset-app-name = Application de connexion { $provider }
win-issuer-not-checked = l'émetteur ne peut pas être vérifié
win-checking-issuer = Vérification de { $issuer }...
win-issuer-unusable = L'émetteur ne peut pas être utilisé : { $reason }
win-issuer-usable = L'émetteur peut être utilisé.
win-sign-in-app-not-saved = L'application de connexion n'a pas pu être enregistrée : { $reason }
win-check = Vérifier
win-check-button = &Vérifier
win-copy = &Copier
win-fill-in-for = Remplir pour :
win-app-name = Nom :
win-issuer = Émetteur :
win-client-id = ID client :
win-client-secret = Secret client :
win-scopes = Portées :
win-imap-server = Serveur IMAP :
win-smtp-server = Serveur SMTP :
win-redirect-uri = URI de redirection :
win-sign-in-app-intro = Un client OAuth que vous avez enregistré auprès de votre fournisseur, pour les comptes qui se connectent par le navigateur. Remplissez-le pour un fournisseur, puis ajoutez l'ID client (et le secret, si le fournisseur en a donné un).
win-remove-secret = Un secret est enregistré ; tapez-en un autre pour le remplacer, ou supprimez-le
win-register-it = Enregistrez-le auprès de votre fournisseur
win-built-in-note = { $name } est intégré : seul son usage pour les nouveaux comptes peut changer.
win-client-with-secret = ID client : { $client }, avec un secret client.
win-client-public = ID client : { $client }, un client public (sans secret).
win-built-in = (intégré)
win-no-accounts = Aucun compte
win-remove-sign-in-app = Supprimer l'application de connexion
win-remove-sign-in-app-ask = Supprimer l'application de connexion { $name } et son secret client enregistré ?
win-sign-in-app-not-removed = L'application de connexion n'a pas été supprimée : { $reason }
win-sign-in-apps-intro = Les applications de connexion permettent aux comptes de se connecter par le navigateur. Une application non cochée n'est pas proposée aux nouveaux comptes ; les comptes qui l'utilisent déjà continuent de fonctionner.
win-col-issuer = Émetteur
win-col-used-by = Utilisée par
win-edit = &Modifier...

## Options

win-options-language-group = Langue
win-options-language-label = &Afficher Inbox Classic en :
win-options-system-default = Langue du système ({ $language })
win-options-restart-note = Inbox Classic redémarre pour afficher une autre langue.
win-options-notify-group = Notifications
win-options-notify = &Me prévenir de l'arrivée de nouveaux messages
win-restart-ask = Inbox Classic s'affichera dans la langue choisie ({ $language }) après un redémarrage. Redémarrer maintenant ?
win-restart-now = &Redémarrer maintenant
win-restart-later = &Plus tard
