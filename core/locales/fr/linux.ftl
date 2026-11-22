# The words of the Linux app's own windows (linux/src), ids starting with gtk-. Placeables in { $braces } are filled in
# by the app; an _ marks a button's mnemonic letter. GNOME words where GNOME has them (Preferences, Quit).

## The main window

gtk-search-looks-in = La recherche dans { $place } porte sur l'objet, les expéditeurs, les destinataires, les noms des pièces jointes et le texte des messages. Vérifiez l'orthographe ou essayez avec moins de mots.
gtk-search-still-indexing = { $count ->
    [one] Le texte de { $count } message est encore en cours d'indexation, d'autres résultats peuvent donc bientôt apparaître.
   *[other] Le texte de { $count } messages est encore en cours d'indexation, d'autres résultats peuvent donc bientôt apparaître.
}
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
gtk-list-loading = Chargement...
gtk-menu-rename = Renommer...
gtk-import-one-question = Importer le message { $file } dans le dossier { $folder } ?
gtk-files-not-saved = Fichiers non enregistrés : { $failed } sur { $total }.
gtk-unsubscribe-one-click =
    Quitter cette liste de diffusion ?

    Inbox Classic envoie une demande de désabonnement à { $target }, sans ouvrir de page web ni envoyer d'e-mail.
gtk-unsubscribe-mail =
    Quitter cette liste de diffusion ?

    Pour vous désabonner, vous devez envoyer un e-mail à { $target }. Inbox Classic le prépare pour vous. Envoyez-le pour confirmer votre désabonnement.
gtk-unsubscribe-web =
    Quitter cette liste de diffusion ?

    La page de désabonnement de la liste va s'ouvrir dans votre navigateur ({ $target }).
gtk-unsubscribe-failed = Désabonnement impossible : { $problem }
gtk-toolbar-create-mail-menu = Rédiger depuis un compte au choix
gtk-toolbar-send-recv-menu = Envoyer et recevoir les messages d'un compte au choix
gtk-main-menu = Menu principal
gtk-folder-list = Liste des dossiers
gtk-quit = Quitter

## The Move and Copy window

gtk-new-folder-at-top-of = Le nouveau dossier est créé au premier niveau de { $account }.

## The message list

## Help

## Notifications and the tray

gtk-unread-messages = { $count ->
    [0] Aucun message non lu
    [one] { $count } message non lu
   *[other] { $count } messages non lus
}

## The compose window's link menu

## The Outbox

gtk-outbox-empty = Aucun message en attente d'envoi.
gtk-outbox-row = À : { $to }  ·  Mis en attente le { $queued }  ·  { $status }

## The app

gtk-still-running-detail = Inbox Classic continue de relever le courrier en arrière-plan. Utilisez son icône dans la barre supérieure pour ouvrir ou quitter l'application.
gtk-sign-in-again-ask =
    La connexion au compte { $account } a été refusée ou la session a expiré.

    Se reconnecter dans le navigateur ?
gtk-default-app-not-installed = Inbox Classic n'est pas installé et ne figure donc pas dans la liste des applications de messagerie du système. Installez-le pour le choisir comme application par défaut.
gtk-default-app-now = Inbox Classic est maintenant votre application de messagerie par défaut : les liens e-mail ouvrent un nouveau message ici.
gtk-default-app-failed = Impossible de définir Inbox Classic comme application de messagerie par défaut.

## Buttons and words used in many windows

## The reading pane

gtk-reader-date = Date :
gtk-reader-files = Pièces jointes du message
gtk-files = { $count ->
    [one] { $count } fichier
   *[other] { $count } fichiers
}
gtk-save-attachments-menu = Enregistrer les pièces jointes...

## The compose window

gtk-format-bold = Gras (Ctrl+B)
gtk-format-italic = Italique (Ctrl+I)
gtk-format-underline = Souligné (Ctrl+U)
gtk-format-hyperlink = Lien hypertexte (Ctrl+K)
gtk-font = Police
gtk-show-cc = _Cc
gtk-show-bcc = Cc_i
gtk-save-tip = Enregistrer (Ctrl+S)
gtk-link-status = { $link }    (Ctrl+clic pour ouvrir)

## Accounts

gtk-plain-warning =
    Sans chiffrement, une personne qui intercepte le trafic réseau peut lire votre mot de passe et vos messages. Ne continuez que si la connexion est protégée par un autre moyen. Un réseau local ne garantit pas cette protection.

    Continuer ?
gtk-account-name-title = Nom du compte
gtk-display-name-title = Nom affiché
gtk-turned-off-why = L'option « { $button } » est désactivée sur cet ordinateur. { $reason }
gtk-turned-off-why-long =
    L'option « { $button } » est désactivée sur cet ordinateur.

    { $reason }
gtk-next = Suivant >
gtk-provider-sign-in = Connectez-vous au compte { $address } sur le site de { $provider }. Votre mot de passe ne sera pas transmis à Inbox Classic. Si votre compte autorise les mots de passe d'application, vous pouvez en créer un dans ses paramètres de sécurité. Outlook.com et Microsoft 365 exigent une connexion via le navigateur.
gtk-provider-sign-in-apps = Connectez-vous au compte { $address } sur le site de { $provider } avec l'une de vos applications de connexion (« Autres options de connexion »). Si votre compte autorise les mots de passe d'application, vous pouvez en créer un dans ses paramètres de sécurité. Outlook.com et Microsoft 365 exigent une connexion via le navigateur.
gtk-accounts-add = Ajouter...
gtk-accounts-properties = Propriétés...
gtk-accounts-signature = Signature...
gtk-accounts-sign-in-apps = Applications de connexion...

## Sign-in apps

gtk-app-server = Serveur { $kind }
gtk-app-port = Port { $kind }
gtk-app-security = Sécurité { $kind }
gtk-issuer-found =
    Page de connexion : { $page }
    Point de terminaison du jeton : { $endpoint }
gtk-client-id = ID client
gtk-client-secret = Secret client
gtk-scopes = Autorisations (scopes)
gtk-redirect-uri = Adresse de redirection
gtk-issuer-usable =
    L'émetteur peut être utilisé.

    { $found }
gtk-app-built-in = { $app } est une application intégrée. Vous pouvez uniquement choisir de la proposer ou non aux nouveaux comptes. { $reason }
gtk-built-in = { $app } (intégrée)
gtk-offered-for-new = Proposée pour les nouveaux comptes
gtk-edit-button = Modifier...
gtk-remove-app-ask = Supprimer l'application de connexion { $app } et son secret client enregistré ?
gtk-sign-in-apps-intro = Les applications de connexion permettent aux comptes de se connecter par le navigateur. Une application désactivée n'est pas proposée pour les nouveaux comptes ; les comptes qui l'utilisent déjà continuent de fonctionner.

## AI agents

gtk-agent-it-may = Actions autorisées
gtk-agent-accounts = Comptes accessibles
gtk-never-used = Jamais utilisé
gtk-last-used = Dernière utilisation { $date }
gtk-forget-program = Supprimer les autorisations enregistrées de ce programme ?
gtk-forget-program-detail = Les autorisations du programme et l'historique de ses agents seront effacés. Une autorisation vous sera de nouveau demandée à la prochaine connexion.
gtk-no-agents-yet = Aucun agent n'a encore demandé à utiliser votre courrier.
gtk-nothing-yet = Rien pour l'instant.

## Preferences

gtk-preferences = Préférences
gtk-notify-subtitle = Uniquement si la fenêtre principale n’est pas au premier plan

## The desktop entry and the page of the software stores

gtk-desktop-generic-name = Client de messagerie
gtk-desktop-comment = Lire et écrire des e-mails : un programme de messagerie rapide et simple
gtk-desktop-keywords = courriel;courrier;message;
gtk-metainfo-summary = Un programme de messagerie rapide et simple
gtk-metainfo-description = Inbox Classic retrouve la disposition classique des logiciels de messagerie : dossiers à gauche, liste des messages en haut et volet de lecture en dessous. Il prend en charge les comptes IMAP et SMTP et permet de se connecter à Outlook.com et Microsoft 365 dans le navigateur.
gtk-metainfo-feature-sanitized = Les messages sont affichés sans scripts ; les images provenant d’Internet ne sont chargées qu’avec votre accord
gtk-metainfo-feature-search = Recherchez dans l’objet, les expéditeurs, les destinataires, les noms des pièces jointes et le texte avec des opérateurs de recherche inspirés de Gmail
gtk-metainfo-feature-replies = Les messages cités dans les réponses sont repliés
gtk-metainfo-feature-offline = Le courrier reste lisible hors connexion tant que sa copie locale est conservée ; les identifiants sont normalement enregistrés dans le trousseau du système, s’il est disponible