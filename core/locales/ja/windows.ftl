# 日本語。ネイティブ スピーカーによるレビュー待ちの下書きです。

## The main window

win-still-running-detail = Inbox Classicはバックグラウンドで新着メールの確認を続けます。開くにはアイコンをクリックしてください。終了するには、アイコンを右クリックしてメニューを使用してください。
win-default-app-not-installed = このInbox Classicはインストールされていないため、Windowsのメール アプリの一覧に表示されません。選択するには、インストールしてください。
win-default-app-settings = Windowsの［既定のアプリ］の設定が開きます。MAILTOリンクを開くアプリとしてInbox Classicを選択してください。
win-no-unread = 未読メッセージはありません
win-unread-messages = { $count }件の未読メッセージ
win-print-failed = メッセージを印刷できませんでした。
win-print-title-of = 印刷 - { $subject }
win-no-bodies = メッセージの本文を表示できません。
win-webview-failed = WebView2を作成できませんでした。
win-webview-missing = WebView2ランタイムを利用できません。
win-list-loading = 読み込んでいます...

## Buttons and words used in many windows

win-delete-button = 削除(&D)
win-find-label = 検索(&F):
win-save-as-button = 名前を付けて保存(&E)...
win-too-many-files = 一度に指定したファイルが多すぎます。ファイルの数を減らしてください。

## The compose window

win-editor-failed = メッセージを作成できません。
win-ctrl-click-to-open = （{ $ctrl }キーを押しながらクリックすると開きます）
win-format-bold = 太字（{ $ctrl }+B）
win-format-italic = 斜体（{ $ctrl }+I）
win-format-underline = 下線（{ $ctrl }+U）
win-format-link = ハイパーリンク（{ $ctrl }+K）
win-show-cc = CC(&C)
win-show-bcc = BCC(&B)
win-signature-title = 署名：{ $account }

## The folders, the message list and the reading pane

win-search-found-all = { $count ->
    [0] すべてのフォルダーで「{ $words }」の結果はありません
   *[other] すべてのフォルダーで「{ $words }」の結果：{ $count }件
}
win-search-found-in = { $count ->
    [0] { $folder }で「{ $words }」の結果はありません
   *[other] { $folder }で「{ $words }」の結果：{ $count }件
}
win-search-indexing = { $count }件のメッセージの本文をインデックスに登録中
win-no-match-indexing = { $count }件のメッセージの本文をまだインデックスに登録しているため、まもなく結果が増える場合があります。
win-files = { $count }個のファイル
win-save-attachments = 添付ファイルの保存(&S)...
win-files-not-saved = { $count }個のファイルのうち{ $failed }個を保存できませんでした。
win-new-folder-in-highlighted = 新しいフォルダーは、選択したフォルダーの中に作成されます。
win-delete-folder-ask = フォルダー「{ $folder }」を、その中のメッセージとフォルダーと一緒に削除しますか？サーバー上でも削除されます。
win-rename = 名前の変更(&R)...
win-messages-not-saved = メッセージを保存できませんでした。
win-messages-not-forwarded = メッセージを転送できませんでした。

## Accounts

win-sign-in-google = Googleでサインイン
win-sign-in-microsoft = Microsoftでサインイン
win-next = 次へ(&N) >
win-your-account = アカウント
win-browser-sign-in = （ブラウザーでのサインイン）
win-add = 追加(&A)...
win-properties-button = プロパティ(&P)...
win-signature-button = 署名(&G)...
win-sign-in-apps-button = サインイン アプリ(&S)...

## AI agents

win-dont-allow = 許可しない(&D)
win-col-address = アドレス
win-never-written-to = 送信したことのない宛先
win-book-find-label = 名前またはメール アドレスを入力:
win-send = 送信(&S)
win-dont-send = 送信しない(&D)
win-unsubscribe = 配信停止(&U)
win-dont-unsubscribe = 配信停止しない(&D)
win-forget-program-ask = このプログラムの保存されたアクセス許可と、そのエージェントのアクティビティ履歴を削除しますか？プログラムはアンインストールされません。次回接続したときに、もう一度許可を求められます。
win-clear-log-ask = エージェントのアクティビティ履歴を消去しますか？エージェントが行った変更は元に戻りません。
win-agent-programs = エージェントがメールへのアクセスを要求したプログラム(&P):
win-change = 変更(&C)...
win-undo-since = 期間を指定して元に戻す(&S)...
win-take-back = 取り消す(&T)
win-what-agents-did = エージェントのアクティビティ(&A):
win-agent-reads = { $from }～{ $to }に読み取られた内容：
win-agent-reads-hint = 読み取られた内容を表示するには、上の読み取りの行を選択してください。

## Sign-in apps

win-built-in = （組み込み）
win-edit = 編集(&E)...

## Options

win-folders-hide = フォルダー一覧を非表示にする
win-folders-pin = フォルダー一覧をメッセージの横に固定する
win-folders-show = フォルダーを表示

## The installer

win-installer-start = Inbox Classicを起動
win-installer-welcome-new =
    メール プログラムInbox Classic { $version }をインストールします。

    管理者権限は不要です。現在のWindowsユーザーにのみインストールされます。
win-installer-welcome-same =
    Inbox Classic { $version }はすでにインストールされています。もう一度インストールします。

    アカウントとメールはそのまま保持されます。
win-installer-welcome-update =
    Inbox Classic { $installed }を{ $version }に更新します。

    実行中の場合は、先に終了します。アカウントとメールはそのまま保持されます。
win-installer-older-ask = { $version }より新しいInbox Classic { $installed }がインストールされています。それでも古いバージョンをインストールしますか？
win-installer-still-running = Inbox Classicは実行中です。終了してから、もう一度お試しください。
win-installer-remove-mail-ask = アカウント、ダウンロードしたメール、送信待ちのメッセージ、設定、連絡先、ルール、暗号化キーを含む、Inbox Classicのローカル データも削除しますか？サーバー上のメールと、システムの資格情報ストアのエントリは残ります。
