# Les mots des fenêtres de l'application Windows (app/src), identifiants commençant par win-. L'application remplit les
# éléments entre { $accolades } ; un & marque la lettre d'un élément de menu ou d'un bouton (&& est une esperluette).

## La fenêtre principale

win-flag-menu = &Indicateur
win-still-running-detail = Il continue à relever le courrier ici. Cliquez sur l'icône pour l'ouvrir, ou cliquez dessus avec le bouton droit pour le quitter.
win-new-messages = { $count ->
    [one] { $count } nouveau message
   *[other] { $count } nouveaux messages
}
win-default-app-not-installed = Cette copie d'Inbox Classic n'a pas été installée, Windows ne la propose donc pas comme programme de messagerie. Installez-la pour la choisir.
win-default-app-settings = Windows ouvre ses paramètres d'applications par défaut pour Inbox Classic. Choisissez-le pour MAILTO.
win-no-unread = Aucun message non lu
win-unread-messages = { $count ->
    [one] { $count } message non lu
   *[other] { $count } messages non lus
}
win-print-failed = Le message n'a pas pu être imprimé.
win-print-title-of = Imprimer : { $subject }
win-no-bodies = Le contenu des messages ne peut pas être affiché.
win-webview-failed = La création du WebView2 a échoué.
win-webview-missing = Le runtime WebView2 n'est pas disponible.

## Boutons et mots de plusieurs fenêtres

win-delete-button = &Supprimer
win-find-label = &Rechercher :
win-col-to = À
win-save-as-button = Enregistrer &sous...
win-too-many-files = Trop de fichiers à la fois : choisissez-en moins.

## La Boîte d'envoi

win-outbox-send-all = &Tout envoyer maintenant

## La fenêtre de rédaction

win-editor-failed = Les messages ne peuvent pas être rédigés.
win-ctrl-click-to-open = ({ $ctrl }+clic pour ouvrir)
win-remove-file = &Supprimer
win-format-bold = Gras ({ $ctrl }+B)
win-format-italic = Italique ({ $ctrl }+I)
win-format-underline = Souligné ({ $ctrl }+U)
win-format-link = Lien hypertexte ({ $ctrl }+K)
win-show-cc = &Cc
win-show-bcc = C&ci
win-signature-title = Signature : { $account }

## Les dossiers, la liste des messages et le volet de lecture

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
win-no-match-indexing = { $count ->
    [one] Le texte de { $count } message est encore en cours d'indexation, d'autres résultats peuvent donc apparaître bientôt.
   *[other] Le texte de { $count } messages est encore en cours d'indexation, d'autres résultats peuvent donc apparaître bientôt.
}
win-files = { $count ->
    [one] { $count } fichier
   *[other] { $count } fichiers
}
win-click-to-retry = Cliquez ici pour réessayer.
win-save-attachments = &Enregistrer les pièces jointes...
win-files-not-saved = { $failed } des { $count } fichiers n'ont pas pu être enregistrés.
win-attendees = { $count ->
    [one] { $count } participant
   *[other] { $count } participants
}
win-copy-button = &Copier
win-move-button = &Déplacer
win-new-folder-in-highlighted = Le nouveau dossier est créé dans le dossier mis en évidence.
win-delete-folder-ask = Supprimer le dossier « { $folder } » avec ses messages et les dossiers qu'il contient ? Il est aussi supprimé sur le serveur.
win-clear-flag = &Effacer l'indicateur
win-rename = &Renommer...
win-open = &Ouvrir
win-view-source = Afficher la &source
win-properties = &Propriétés
win-messages-not-saved = Les messages n'ont pas pu être enregistrés.
win-messages-not-forwarded = Les messages n'ont pas pu être transférés.

## Comptes

win-sign-in-google = Se connecter avec Google
win-sign-in-microsoft = Se connecter avec Microsoft
win-next = &Suivant >
win-your-account = votre compte
win-browser-sign-in = (connexion par le navigateur)
win-add = &Ajouter...
win-properties-button = &Propriétés...
win-signature-button = Si&gnature...
win-sign-in-apps-button = Applications de &connexion...

## Agents d'IA

win-allow = &Autoriser
win-dont-allow = &Ne pas autoriser
win-turn-away = &Refuser
win-col-address = Adresse
win-never-written-to = Jamais écrit
win-send = &Envoyer
win-edit-first = &Modifier d'abord
win-dont-send = &Ne pas envoyer
win-forget-program-ask = Oublier ce programme et ce que ses agents ont fait ? La question sera reposée à sa prochaine connexion.
win-clear-log-ask = Effacer la liste de ce que les agents ont fait ? Ce qu'ils ont fait reste fait.
win-let-agents-connect = &Laisser les agents d'IA se connecter à Inbox Classic
win-agent-programs = &Programmes dont les agents ont demandé à utiliser votre courrier :
win-change = &Modifier...
win-what-agents-did = Ce que les agents ont &fait :
win-clear = &Effacer
win-how-to-connect = Comment connecter un agent

## Applications de connexion

win-check-button = &Vérifier
win-copy = &Copier
win-built-in = (intégrée)
win-edit = &Modifier...

## Options

win-options-language-label = &Afficher Inbox Classic en :
win-options-restart-note = Inbox Classic redémarre pour afficher une autre langue.
win-options-notify = &Me prévenir de l'arrivée de nouveaux messages
win-restart-ask = Inbox Classic s'affichera dans la langue choisie ({ $language }) après un redémarrage. Redémarrer maintenant ?
win-restart-now = &Redémarrer maintenant
win-restart-later = &Plus tard
