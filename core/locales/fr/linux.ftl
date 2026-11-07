# The words of the Linux app's own windows (linux/src), ids starting with gtk-. Placeables in { $braces } are filled in
# by the app; an _ marks a button's mnemonic letter. GNOME words where GNOME has them (Preferences, Quit).

## The main window

gtk-search-looks-in = La recherche dans { $place } porte sur l’objet, les expéditeurs, les destinataires, les noms des pièces jointes et le texte des messages. Vérifiez l’orthographe ou essayez avec moins de mots.
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
gtk-menu-rename = Renommer...
gtk-import-one-question = Importer le message { $file } dans le dossier { $folder } ?
gtk-files-not-saved = Fichiers non enregistrés : { $failed } sur { $total }.
gtk-unsubscribe-one-click =
    Quitter cette liste de diffusion ?

    Inbox Classic envoie une demande de désabonnement à { $target }, sans ouvrir de page web ni envoyer d’e-mail.
gtk-unsubscribe-mail =
    Quitter cette liste de diffusion ?

    Pour vous désabonner, vous devez envoyer un e-mail à { $target }. Inbox Classic le prépare pour vous. Envoyez-le pour confirmer votre désabonnement.
gtk-unsubscribe-web =
    Quitter cette liste de diffusion ?

    La page de désabonnement de la liste va s’ouvrir dans votre navigateur ({ $target }).
gtk-unsubscribe-failed = Désabonnement impossible : { $problem }
gtk-toolbar-create-mail-menu = Rédiger depuis un compte au choix
gtk-toolbar-send-recv-menu = Envoyer et recevoir les messages d’un compte au choix
gtk-main-menu = Menu principal
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

gtk-outbox-empty = Aucun message en attente d’envoi.
gtk-outbox-row = À : { $to }  ·  Mis en attente le { $queued }  ·  { $status }

## The app

gtk-still-running-detail = Inbox Classic continue de relever le courrier en arrière-plan. Utilisez son icône dans la barre supérieure pour ouvrir ou quitter l’application.
gtk-sign-in-again-ask =
    La connexion au compte { $account } a été refusée ou la session a expiré.

    Se reconnecter dans le navigateur ?
gtk-default-app-not-installed = Inbox Classic n’est pas installé et ne figure donc pas dans la liste des applications de messagerie du système. Installez-le pour le choisir comme application par défaut.
gtk-default-app-now = Inbox Classic est maintenant votre application de messagerie par défaut : les liens e-mail ouvrent un nouveau message ici.
gtk-default-app-failed = Impossible de définir Inbox Classic comme application de messagerie par défaut.

## Buttons and words used in many windows

## The reading pane

gtk-reader-date = Date :
gtk-reader-files = Pièces jointes du message
gtk-pictures-blocked = Certaines images ont été bloquées pour empêcher l'expéditeur d'identifier votre ordinateur.
gtk-download-pictures = Télécharger les images
gtk-save-attachments-menu = Enregistrer les pièces jointes...
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
gtk-day-and-time = { $day }, { $time }

## The compose window

gtk-format-bold = Gras (Ctrl+B)
gtk-format-italic = Italique (Ctrl+I)
gtk-format-underline = Souligné (Ctrl+U)
gtk-format-hyperlink = Lien hypertexte (Ctrl+K)
gtk-font = Police
gtk-show-cc = _Cc
gtk-show-bcc = C_ci
gtk-save-tip = Enregistrer (Ctrl+S)
gtk-link-status = { $link }    (Ctrl+clic pour ouvrir)

## Accounts

gtk-plain-warning =
    Sans chiffrement, toute personne qui intercepte le trafic réseau peut lire votre mot de passe et vos messages. Utilisez cette connexion uniquement avec un serveur sur votre ordinateur ou votre réseau local.

    Continuer ?
gtk-display-name-title = Nom affiché
gtk-turned-off-why = L’option « { $button } » est désactivée sur cet ordinateur. { $reason }
gtk-turned-off-why-long =
    L’option « { $button } » est désactivée sur cet ordinateur.

    { $reason }
gtk-next = Suivant >
gtk-provider-sign-in = Connectez-vous au compte { $address } sur le site de { $provider }. Votre mot de passe ne sera pas transmis à Inbox Classic. Vous pouvez aussi utiliser un mot de passe d'application créé dans les paramètres de sécurité de votre compte.
gtk-provider-sign-in-apps = Connectez-vous au compte { $address } sur le site de { $provider } avec l'une de vos applications de connexion (« Autres options de connexion »). Vous pouvez aussi utiliser un mot de passe d'application créé dans les paramètres de sécurité de votre compte.
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
gtk-forget-program = Supprimer ce programme ?
gtk-forget-program-detail = Les autorisations du programme et l’historique de ses agents seront effacés. Une autorisation vous sera de nouveau demandée à la prochaine connexion.
gtk-no-agents-yet = Aucun agent n'a encore demandé à utiliser votre courrier.
gtk-nothing-yet = Rien pour l'instant.

## Preferences

gtk-preferences = Préférences
gtk-language = Langue
gtk-language-subtitle = Langue de l’interface et de l’aide
gtk-new-mail-group = Nouveau courrier
gtk-notify-subtitle = Recevoir une notification à l’arrivée de nouveaux messages lorsque la fenêtre est en arrière-plan
gtk-restart-to-change = Inbox Classic redémarre pour changer de langue.
