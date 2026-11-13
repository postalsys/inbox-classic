# Les mots des fenêtres de l'application Windows (app/src), identifiants commençant par win-. L'application remplit les
# éléments entre { $accolades } ; un & marque la lettre d'un élément de menu ou d'un bouton (&& est une esperluette).

## La fenêtre principale

# review: changed
win-still-running-detail = Inbox Classic continue de relever le courrier en arrière-plan. Cliquez sur son icône pour l'ouvrir. Pour quitter l'application, ouvrez le menu de l'icône avec le bouton droit.
# review: changed
win-default-app-not-installed = Inbox Classic n'est pas installé et ne figure donc pas dans la liste des applications de messagerie de Windows. Installez-le pour le choisir comme application par défaut.
win-default-app-settings = Windows ouvre les paramètres des applications par défaut. Choisissez Inbox Classic pour ouvrir les liens MAILTO.
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
win-save-as-button = Enregistrer &sous...
win-too-many-files = Trop de fichiers à la fois : choisissez-en moins.

## La Boîte d'envoi


## La fenêtre de rédaction

win-editor-failed = Les messages ne peuvent pas être rédigés.
win-ctrl-click-to-open = ({ $ctrl }+clic pour ouvrir)
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
win-files-not-saved = Fichiers non enregistrés : { $failed } sur { $count }.
win-new-folder-in-highlighted = Le nouveau dossier sera créé dans le dossier sélectionné.
# review: changed
win-delete-folder-ask = Supprimer le dossier « { $folder } », tous ses messages et ses sous-dossiers ? Ils seront également supprimés du serveur.
win-rename = &Renommer...
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

# review: changed
win-dont-allow = &Ne pas autoriser
win-col-address = Adresse
win-never-written-to = Jamais écrit
# review: new
win-book-find-label = Tapez un nom ou une adresse e-mail :
win-send = &Envoyer
# review: changed
win-dont-send = &Ne pas envoyer
# review: changed
win-forget-program-ask = Supprimer ce programme, ses autorisations et l'historique de ses agents ? Une autorisation vous sera de nouveau demandée à la prochaine connexion.
# review: changed
win-clear-log-ask = Effacer l'historique des agents ? Les modifications effectuées ne seront pas annulées.
win-agent-programs = &Programmes dont les agents ont demandé à utiliser votre courrier :
win-change = &Modifier...
win-what-agents-did = &Historique des agents :
win-how-to-connect = Comment connecter un agent

## Applications de connexion

win-built-in = (intégrée)
win-edit = &Modifier...

## Options

win-options-language-label = &Afficher Inbox Classic en :
win-options-restart-note = Redémarrez Inbox Classic pour appliquer la nouvelle langue.
win-options-notify = &Me prévenir de l'arrivée de nouveaux messages
win-restart-ask = Inbox Classic s'affichera dans la langue choisie ({ $language }) après un redémarrage. Redémarrer maintenant ?
# review: new
win-folders-hide = Masquer la liste des dossiers
# review: new
win-folders-pin = Épingler la liste des dossiers à côté des messages
# review: new
win-folders-show = Afficher les dossiers
