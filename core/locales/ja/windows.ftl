# 日本語。ネイティブ スピーカーによるレビュー待ちの下書きです。

## The main window

# review: new
win-still-running-detail = Inbox Classicはバックグラウンドで新着メールの確認を続けます。開くにはアイコンをクリックしてください。終了するには、アイコンを右クリックしてメニューを使用してください。
# review: new
win-default-app-not-installed = このInbox Classicはインストールされていないため、Windowsのメール アプリの一覧に表示されません。選択するには、インストールしてください。
# review: new
win-default-app-settings = Windowsの［既定のアプリ］の設定が開きます。MAILTOリンクを開くアプリとしてInbox Classicを選択してください。
# review: new
win-no-unread = 未読メッセージはありません
# review: new
win-unread-messages = { $count }件の未読メッセージ
# review: new
win-print-failed = メッセージを印刷できませんでした。
# review: new
win-print-title-of = 印刷 - { $subject }
# review: new
win-no-bodies = メッセージの本文を表示できません。
# review: new
win-webview-failed = WebView2を作成できませんでした。
# review: new
win-webview-missing = WebView2ランタイムを利用できません。
# review: new
win-list-loading = 読み込んでいます...

## Buttons and words used in many windows

# review: new
win-delete-button = 削除(&D)
# review: new
win-find-label = 検索(&F):
# review: new
win-save-as-button = 名前を付けて保存(&E)...
# review: new
win-too-many-files = 一度に指定したファイルが多すぎます。ファイルの数を減らしてください。

## The compose window

# review: new
win-editor-failed = メッセージを作成できません。
# review: new
win-ctrl-click-to-open = （{ $ctrl }キーを押しながらクリックすると開きます）
# review: new
win-format-bold = 太字（{ $ctrl }+B）
# review: new
win-format-italic = 斜体（{ $ctrl }+I）
# review: new
win-format-underline = 下線（{ $ctrl }+U）
# review: new
win-format-link = ハイパーリンク（{ $ctrl }+K）
# review: new
win-show-cc = CC(&C)
# review: new
win-show-bcc = BCC(&B)
# review: new
win-signature-title = 署名：{ $account }

## The folders, the message list and the reading pane

# review: new
win-search-found-all = { $count ->
    [0] すべてのフォルダーで「{ $words }」の結果はありません
   *[other] すべてのフォルダーで「{ $words }」の結果：{ $count }件
}
# review: new
win-search-found-in = { $count ->
    [0] { $folder }で「{ $words }」の結果はありません
   *[other] { $folder }で「{ $words }」の結果：{ $count }件
}
# review: new
win-search-indexing = { $count }件のメッセージの本文をインデックスに登録中
# review: new
win-no-match-indexing = { $count }件のメッセージの本文をまだインデックスに登録しているため、まもなく結果が増える場合があります。
# review: new
win-files = { $count }個のファイル
# review: new
win-save-attachments = 添付ファイルの保存(&S)...
# review: new
win-files-not-saved = { $count }個のファイルのうち{ $failed }個を保存できませんでした。
# review: new
win-new-folder-in-highlighted = 新しいフォルダーは、選択したフォルダーの中に作成されます。
# review: new
win-delete-folder-ask = フォルダー「{ $folder }」を、その中のメッセージとフォルダーと一緒に削除しますか？サーバー上でも削除されます。
# review: new
win-rename = 名前の変更(&R)...
# review: new
win-messages-not-saved = メッセージを保存できませんでした。
# review: new
win-messages-not-forwarded = メッセージを転送できませんでした。

## Accounts

# review: new
win-sign-in-google = Googleでサインイン
# review: new
win-sign-in-microsoft = Microsoftでサインイン
# review: new
win-next = 次へ(&N) >
# review: new
win-your-account = アカウント
# review: new
win-browser-sign-in = （ブラウザーでのサインイン）
# review: new
win-add = 追加(&A)...
# review: new
win-properties-button = プロパティ(&P)...
# review: new
win-signature-button = 署名(&G)...
# review: new
win-sign-in-apps-button = サインイン アプリ(&S)...

## AI agents

# review: new
win-dont-allow = 許可しない(&D)
# review: new
win-col-address = アドレス
# review: new
win-never-written-to = 送信したことのない宛先
# review: new
win-book-find-label = 名前またはメール アドレスを入力:
# review: new
win-send = 送信(&S)
# review: new
win-dont-send = 送信しない(&D)
# review: new
win-unsubscribe = 配信停止(&U)
# review: new
win-dont-unsubscribe = 配信停止しない(&D)
# review: new
win-forget-program-ask = このプログラムの保存されたアクセス許可と、そのエージェントのアクティビティ履歴を削除しますか？プログラムはアンインストールされません。次回接続したときに、もう一度許可を求められます。
# review: new
win-clear-log-ask = エージェントのアクティビティ履歴を消去しますか？エージェントが行った変更は元に戻りません。
# review: new
win-agent-programs = エージェントがメールへのアクセスを要求したプログラム(&P):
# review: new
win-change = 変更(&C)...
# review: new
win-undo-since = 期間を指定して元に戻す(&S)...
# review: new
win-take-back = 取り消す(&T)
# review: new
win-what-agents-did = エージェントのアクティビティ(&A):
# review: new
win-agent-reads = { $from }～{ $to }に読み取られた内容：
# review: new
win-agent-reads-hint = 読み取られた内容を表示するには、上の読み取りの行を選択してください。

## Sign-in apps

# review: new
win-built-in = （組み込み）
# review: new
win-edit = 編集(&E)...

## Options

# review: new
win-folders-hide = フォルダー一覧を非表示にする
# review: new
win-folders-pin = フォルダー一覧をメッセージの横に固定する
# review: new
win-folders-show = フォルダーを表示

## The installer

# review: new
win-installer-start = Inbox Classicを起動
# review: new
win-installer-welcome-new =
    メール プログラムInbox Classic { $version }をインストールします。

    管理者権限は不要です。お使いのアカウントにのみインストールされます。
# review: new
win-installer-welcome-same =
    Inbox Classic { $version }はすでにインストールされています。もう一度インストールします。

    アカウントとメールはそのまま保持されます。
# review: new
win-installer-welcome-update =
    Inbox Classic { $installed }を{ $version }に更新します。

    実行中の場合は、先に終了します。アカウントとメールはそのまま保持されます。
# review: new
win-installer-older-ask = { $version }より新しいInbox Classic { $installed }がインストールされています。それでも古いバージョンをインストールしますか？
# review: new
win-installer-still-running = Inbox Classicは実行中です。終了してから、もう一度お試しください。
# review: new
win-installer-remove-mail-ask = アカウント、ダウンロードしたメール、送信待ちのメッセージ、設定、連絡先、ルール、暗号化キーを含む、Inbox Classicのローカル データも削除しますか？サーバー上のメールと、システムの資格情報ストアのエントリは残ります。
