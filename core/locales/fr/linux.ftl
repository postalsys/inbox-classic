# The words of the Linux app's own windows (linux/src), ids starting with gtk-. Placeables in { $braces } are filled in
# by the app; an _ marks a button's mnemonic letter. GNOME words where GNOME has them (Preferences, Quit).

## The main window

gtk-search-looks-in = La recherche porte sur l'objet, les personnes, les noms de fichiers et le texte des messages de { $place }. Vérifiez l'orthographe, ou essayez avec moins de mots.
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
gtk-import-one-question = Mettre le message { $file } dans le dossier { $folder } ?
gtk-files-not-saved = { $failed } des { $total } fichiers n'ont pas pu être enregistrés.
gtk-unsubscribe-one-click =
    Quitter cette liste de diffusion ?

    Inbox Classic demande à { $target } de ne plus vous l'envoyer. Aucune page ne s'ouvre et aucun message n'est envoyé.
gtk-unsubscribe-mail =
    Quitter cette liste de diffusion ?

    La liste demande un message à { $target }. Inbox Classic l'écrit pour vous ; envoyez-le pour vous désabonner.
gtk-unsubscribe-web =
    Quitter cette liste de diffusion ?

    La page de la liste pour cela s'ouvre dans votre navigateur ({ $target }).
gtk-unsubscribe-failed = Désabonnement impossible : { $problem }
gtk-toolbar-create-mail-menu = Un message d'un seul compte
gtk-toolbar-send-recv-menu = Envoyer et recevoir un seul compte
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

gtk-outbox-empty = Rien n'attend d'être envoyé.
gtk-outbox-row = À : { $to }  ·  En file { $queued }  ·  { $status }

## The app

gtk-new-messages = { $count } nouveaux messages
gtk-still-running-detail = Il continue de relever le courrier. Son icône dans la barre supérieure le rouvre, ou le quitte.
gtk-sign-in-again-ask =
    La connexion de { $account } a été refusée ou a expiré.

    Se reconnecter dans le navigateur ?
gtk-default-app-not-installed = Cette copie d'Inbox Classic n'a pas été installée, le système ne la propose donc pas comme application de messagerie. Installez-la pour la choisir.
gtk-default-app-now = Inbox Classic est maintenant votre application de messagerie par défaut : les liens e-mail ouvrent un nouveau message ici.
gtk-default-app-failed = Inbox Classic n'a pas pu devenir l'application de messagerie par défaut.

## Buttons and words used in many windows

## The reading pane

gtk-reader-date = Date :
gtk-reader-files = Les fichiers du message
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
    Sans chiffrement, votre mot de passe et votre courrier traversent le réseau lisibles par quiconque se trouve sur le chemin. Ne l'utilisez que pour un serveur sur votre propre ordinateur ou réseau.

    Continuer ?
gtk-display-name-title = Nom affiché
gtk-turned-off-why = { $button } est désactivé sur cet ordinateur. { $reason }
gtk-turned-off-why-long =
    { $button } est désactivé sur cet ordinateur.

    { $reason }
gtk-next = Suivant >
gtk-provider-sign-in = { $address } se connecte sur la page de { $provider }, sans donner votre mot de passe à Inbox Classic. Ou utilisez un mot de passe d'application créé dans les paramètres de sécurité de votre compte.
gtk-provider-sign-in-apps = { $address } peut se connecter sur la page de { $provider } avec l'une de vos applications de connexion (Autres options de connexion). Ou utilisez un mot de passe d'application créé dans les paramètres de sécurité de votre compte.
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
gtk-scopes = Portées (scopes)
gtk-redirect-uri = URI de redirection
gtk-issuer-usable =
    L'émetteur peut être utilisé.

    { $found }
gtk-app-built-in = { $app } est intégrée : seul son usage pour les nouveaux comptes peut changer. { $reason }
gtk-built-in = { $app } (intégrée)
gtk-offered-for-new = Proposée pour les nouveaux comptes
gtk-edit-button = Modifier...
gtk-remove-app-ask = Supprimer l'application de connexion { $app } et son secret client enregistré ?
gtk-sign-in-apps-intro = Les applications de connexion permettent aux comptes de se connecter par le navigateur. Une application désactivée n'est pas proposée pour les nouveaux comptes ; les comptes qui l'utilisent déjà continuent de fonctionner.

## AI agents

gtk-agent-it-may = Il peut
gtk-agent-accounts = Comptes qu'il peut utiliser
gtk-never-used = Jamais utilisé
gtk-last-used = Dernière utilisation { $date }
gtk-forget-program = Oublier ce programme ?
gtk-forget-program-detail = La question lui est reposée à sa prochaine connexion, et ce que ses agents ont fait est oublié.
gtk-no-agents-yet = Aucun agent n'a encore demandé à utiliser votre courrier.
gtk-nothing-yet = Rien pour l'instant.

## Preferences

gtk-preferences = Préférences
gtk-language = Langue
gtk-language-subtitle = Les mots des fenêtres et de l'aide
gtk-new-mail-group = Nouveau courrier
gtk-notify-subtitle = Une notification quand de nouveaux messages arrivent alors que la fenêtre est en arrière-plan
gtk-restart-to-change = Inbox Classic redémarre pour changer de langue.
