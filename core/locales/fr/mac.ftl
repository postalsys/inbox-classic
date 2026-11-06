# Français. Brouillon, en attente de relecture par un locuteur natif.

## The app and its menus

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
mac-paste = Coller
mac-menu-window = Fenêtre
mac-minimize = Réduire
mac-zoom = Zoom
mac-no-updates = Cette copie d'Inbox Classic ne se met pas à jour toute seule. Téléchargez la dernière version sur inboxclassic.com.

## Settings

mac-settings-title = Réglages
mac-language-label = Langue :
mac-restart-hint = Inbox Classic redémarre pour changer de langue.
mac-notify-new-mail = M'avertir à l'arrivée de nouveaux messages
mac-restart-question = Redémarrer Inbox Classic maintenant pour changer de langue ?

## Dialogs

mac-choose = Choisir

## The main window

mac-still-running-detail = Il continue de relever les nouveaux messages. Cliquez sur son icône dans le Dock pour le rouvrir.
mac-outbox-waiting =
    { $count ->
        [one] { $count } message dans la Boîte d'envoi
       *[other] { $count } messages dans la Boîte d'envoi
    }
mac-sending = Envoi de { $subject }…
mac-checking = Relève des nouveaux messages de { $account }…
mac-account-said = { $account } : { $message }
mac-new-messages =
    { $count ->
        [one] { $count } nouveau message
       *[other] { $count } nouveaux messages
    }
mac-newest-from = Le plus récent, de { $from } : { $subject }
mac-not-bundle = Cette copie d'Inbox Classic n'est pas un paquet d'application, elle ne peut donc pas être l'app de messagerie par défaut.
mac-not-made-default = Inbox Classic n'est pas devenu l'app de messagerie par défaut : { $reason }
mac-tool-search = Rechercher

## The folders and the message list

mac-still-indexing-more =
    { $count ->
        [one] Le texte de { $count } message est encore en cours d'indexation, d'autres résultats peuvent donc bientôt apparaître.
       *[other] Le texte de { $count } messages est encore en cours d'indexation, d'autres résultats peuvent donc bientôt apparaître.
    }
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
mac-import-messages = Importer des messages
mac-save-messages = Enregistrer les messages
mac-save-attachments-menu = Enregistrer les pièces jointes…
mac-files-not-saved =
    { $count ->
       *[other] { $failed } des { $count } fichiers n'ont pas pu être enregistrés.
    }
mac-no-calendar-app = Aucune app de calendrier de ce Mac n'ouvre les invitations (fichiers .ics).
mac-unsubscribing = Désabonnement de { $target }…

## The compose window

mac-bold = Gras
mac-italic = Italique
mac-underline = Souligné
mac-bcc = Cci
mac-command-click-to-open = ⌘-clic pour ouvrir
mac-saving-to-drafts = Enregistrement dans Brouillons…
mac-dont-save = Ne pas enregistrer

## The reading pane

mac-files =
    { $count ->
        [one] { $count } fichier
       *[other] { $count } fichiers
    }
mac-attendees =
    { $count ->
        [one] { $count } participant
       *[other] { $count } participants
    }

## Accounts

mac-next = Suivant
mac-name-placeholder = Marie Dupont
mac-more-sign-in-options = Autres options de connexion…
mac-add-sign-in-app = Ajouter une application de connexion…
mac-looking-up = Recherche des réglages de { $domain }…
mac-add-button = Ajouter…
mac-properties-button = Propriétés…
mac-signature-button = Signature…
mac-sign-in-apps-button = Applications de connexion…

## AI agents

mac-forget-program = Oublier ce programme et ce qu'ont fait ses agents ?
mac-forget-program-detail = La question lui sera reposée à sa prochaine connexion.

## Sign-in apps

mac-checking-issuer = Vérification de { $issuer }…
mac-edit-button = Modifier…
mac-use-for-new-accounts = Utiliser { $name } pour les nouveaux comptes
mac-built-in = { $name } (intégrée)

## Other windows

mac-new-folder-button = Nouveau dossier…
mac-edit-link = Modifier le lien…
