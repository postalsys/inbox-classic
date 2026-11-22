# 日本語。ネイティブ スピーカーによるレビュー待ちの下書きです。

## The app and its menus

mac-quit = Inbox Classicを終了
mac-settings = 設定…
mac-services = サービス
mac-hide = Inbox Classicを非表示
mac-hide-others = ほかを非表示
mac-show-all = すべてを表示
mac-check-updates = アップデートを確認…
mac-close-window = ウインドウを閉じる
mac-redo = やり直す
mac-cut = カット
mac-paste = ペースト
mac-menu-window = ウインドウ
mac-minimize = しまう
mac-zoom = 拡大/縮小
mac-no-updates = このバージョンのInbox Classicは自動アップデートに対応していません。最新バージョンをinboxclassic.comからダウンロードしてください。

## Settings

mac-settings-title = 設定
mac-check-updates-automatically = アップデートを自動的に確認
mac-settings-updates = アップデート

## Dialogs

mac-choose = 選択

## The main window

mac-still-running-detail = Inbox Classicはバックグラウンドで新着メールの確認を続けます。アプリを開くには、Dockのアイコンをクリックしてください。
mac-outbox-waiting = 送信トレイに{ $count }件のメッセージがあります
mac-sending = { $subject }を送信しています…
mac-checking = { $account }の新着メッセージを確認しています…
mac-account-said = { $account }：{ $message }
mac-not-bundle = このInbox Classicはアプリケーション バンドルではないため、既定のメール アプリにできません。
mac-not-made-default = Inbox Classicを既定のメール アプリにできませんでした：{ $reason }
mac-tool-search = 検索

## The folders and the message list

mac-still-indexing-more = { $count }件のメッセージの本文をまだインデックスに登録しているため、まもなく結果が増える場合があります。
mac-results-everywhere =
    { $count ->
        [0] すべてのフォルダーで「{ $words }」の結果はありません
       *[other] すべてのフォルダーで「{ $words }」の結果：{ $count }件
    }
mac-results-in =
    { $count ->
        [0] { $folder }で「{ $words }」の結果はありません
       *[other] { $folder }で「{ $words }」の結果：{ $count }件
    }
mac-still-indexing = { $count }件のメッセージの本文をインデックスに登録中
mac-folder-unread = { $folder }、未読{ $count }件
mac-import-messages = メッセージをインポート
mac-save-messages = メッセージを保存
mac-save-attachments-menu = 添付ファイルを保存…
mac-files-not-saved =
    { $count ->
       *[other] { $count }個のファイルのうち{ $failed }個を保存できませんでした。
    }
mac-no-calendar-app = 招待を開けませんでした。このMacで.icsファイルを開くカレンダー アプリが設定されていることを確認してください。
mac-file-not-saved = ファイルを保存できませんでした。
mac-unsubscribing = { $target }の配信を停止しています…
mac-loading-list = 読み込み中…

## The compose window

mac-bold = ボールド
mac-italic = イタリック
mac-underline = アンダーライン
mac-bcc = BCC
mac-command-click-to-open = ⌘クリックで開く
mac-saving-to-drafts = 下書きに保存しています…
mac-dont-save = 保存しない

## The reading pane

mac-files = { $count }個のファイル

## Accounts

mac-next = 次へ
mac-name-placeholder = 山田 花子
mac-more-sign-in-options = その他のサインイン オプション…
mac-add-sign-in-app = サインイン アプリを追加…
mac-looking-up = { $domain }の設定を検索しています…
mac-add-button = 追加…
mac-properties-button = プロパティ…
mac-signature-button = 署名…
mac-security-button = セキュリティ…
mac-sign-in-apps-button = サインイン アプリ…

## AI agents

mac-forget-program = このプログラムの保存された権限と、そのエージェントのアクティビティ履歴を削除しますか？
mac-forget-program-detail = プログラムのアクセス許可が削除されます。次回接続したときに、もう一度許可を求められます。

## Sign-in apps

mac-checking-issuer = { $issuer }を確認しています…
mac-edit-button = 編集…
mac-use-for-new-accounts = { $name }を新しいアカウントに使用
mac-built-in = { $name }（組み込み）

## Other windows

mac-new-folder-button = 新しいフォルダー…
mac-edit-link = リンクを編集…
