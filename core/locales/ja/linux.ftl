# 日本語。ネイティブ スピーカーによるレビュー待ちの下書きです。

## The main window

# review: new
gtk-search-looks-in = { $place }で、件名、差出人、受信者、添付ファイル名、本文を検索しました。つづりを確認するか、語句を減らしてみてください。
# review: new
gtk-search-still-indexing = { $count }件のメッセージの本文を、まだインデックスに登録しています。まもなく結果が増える場合があります。
# review: new
gtk-search-results-everywhere = すべてのフォルダーで「{ $words }」を検索：{ $count ->
    [0] 結果なし
   *[other] { $count }件
}
# review: new
gtk-search-results-in = { $place }で「{ $words }」を検索：{ $count ->
    [0] 結果なし
   *[other] { $count }件
}
# review: new
gtk-search-indexing = { $count }件のメッセージの本文をインデックスに登録中
# review: new
gtk-list-loading = 読み込んでいます...
# review: new
gtk-menu-rename = 名前の変更...
# review: new
gtk-import-one-question = メッセージ{ $file }を{ $folder }にインポートしますか？
# review: new
gtk-files-not-saved = { $total }個のファイルのうち{ $failed }個を保存できませんでした。
# review: new
gtk-unsubscribe-one-click =
    このメーリング リストの配信を停止しますか？

    Inbox Classicから{ $target }に配信停止のリクエストを送信します。Webページは開かず、メールも送信されません。
# review: new
gtk-unsubscribe-mail =
    このメーリング リストの配信を停止しますか？

    配信を停止するには、{ $target }にメールを送信します。メールはInbox Classicが用意します。メッセージを送信して確定してください。
# review: new
gtk-unsubscribe-web =
    このメーリング リストの配信を停止しますか？

    メーリング リストの配信停止ページがブラウザーで開きます（{ $target }）。
# review: new
gtk-unsubscribe-failed = 配信を停止できませんでした：{ $problem }
# review: new
gtk-toolbar-create-mail-menu = 特定のアカウントからメールを作成
# review: new
gtk-toolbar-send-recv-menu = 特定のアカウントのメールを送受信
# review: new
gtk-main-menu = メイン メニュー
# review: new
gtk-folder-list = フォルダー一覧
# review: new
gtk-quit = 終了

## The Move and Copy window

# review: new
gtk-new-folder-at-top-of = 新しいフォルダーは{ $account }の最上位に作成されます。

## Notifications and the tray

# review: new
gtk-unread-messages = { $count ->
    [0] 未読メッセージはありません
   *[other] { $count }件の未読メッセージ
}

## The Outbox

# review: new
gtk-outbox-empty = 送信待ちのメッセージはありません。
# review: new
gtk-outbox-row = 宛先：{ $to }  ·  追加日時：{ $queued }  ·  { $status }

## The app

# review: new
gtk-still-running-detail = Inbox Classicはバックグラウンドで新着メールの確認を続けます。アプリを開いたり終了したりするには、トップ バーのアイコンを使用してください。
# review: new
gtk-sign-in-again-ask =
    { $account }へのサインインが拒否されたか、セッションの有効期限が切れました。

    ブラウザーでもう一度サインインしますか？
# review: new
gtk-default-app-not-installed = このInbox Classicはインストールされていないため、システムのメール アプリの一覧に表示されません。選択するには、インストールしてください。
# review: new
gtk-default-app-now = Inbox Classicが既定のメール アプリになりました。メールのリンクをクリックすると、ここで新しいメッセージが開きます。
# review: new
gtk-default-app-failed = Inbox Classicを既定のメール アプリにできませんでした。

## The reading pane

# review: new
gtk-reader-date = 日付:
# review: new
gtk-reader-files = メッセージの添付ファイル
# review: new
gtk-files = { $count }個のファイル
# review: new
gtk-save-attachments-menu = 添付ファイルの保存...

## The compose window

# review: new
gtk-format-bold = 太字（Ctrl+B）
# review: new
gtk-format-italic = 斜体（Ctrl+I）
# review: new
gtk-format-underline = 下線（Ctrl+U）
# review: new
gtk-format-hyperlink = ハイパーリンク（Ctrl+K）
# review: new
gtk-font = フォント
# review: new
gtk-show-cc = CC(_C)
# review: new
gtk-show-bcc = BCC(_B)
# review: new
gtk-save-tip = 保存（Ctrl+S）
# review: new
gtk-link-status = { $link }    （Ctrlキーを押しながらクリックすると開きます）

## Accounts

# review: new
gtk-plain-warning =
    暗号化しないと、ネットワーク通信を傍受した人がパスワードとメッセージを読み取れます。この接続は、ご自身のコンピューターまたはローカル ネットワーク上のサーバーでのみ使用してください。

    続行しますか？
# review: new
gtk-account-name-title = アカウント名
# review: new
gtk-display-name-title = 表示名
# review: new
gtk-turned-off-why = 「{ $button }」オプションは、このコンピューターで無効になっています。{ $reason }
# review: new
gtk-turned-off-why-long =
    「{ $button }」オプションは、このコンピューターで無効になっています。

    { $reason }
# review: new
gtk-next = 次へ >
# review: new
gtk-provider-sign-in = { $provider }のWebサイトで{ $address }にサインインします。パスワードがInbox Classicに渡されることはありません。アカウントでメール用のアプリ パスワードを使える場合は、アカウントのセキュリティ設定で作成したアプリ パスワードも使用できます。Outlook.comとMicrosoft 365では、ブラウザーでのサインインのみを使用できます。
# review: new
gtk-provider-sign-in-apps = サインイン アプリ（その他のサインイン オプション）のいずれかを使って、{ $provider }のWebサイトで{ $address }にサインインします。アカウントでメール用のアプリ パスワードを使える場合は、アカウントのセキュリティ設定で作成したアプリ パスワードも使用できます。Outlook.comとMicrosoft 365では、ブラウザーでのサインインのみを使用できます。
# review: new
gtk-accounts-add = 追加...
# review: new
gtk-accounts-properties = プロパティ...
# review: new
gtk-accounts-signature = 署名...
# review: new
gtk-accounts-sign-in-apps = サインイン アプリ...

## Sign-in apps

# review: new
gtk-app-server = { $kind }サーバー
# review: new
gtk-app-port = { $kind }ポート
# review: new
gtk-app-security = { $kind }のセキュリティ
# review: new
gtk-issuer-found =
    サインイン ページ：{ $page }
    トークン エンドポイント：{ $endpoint }
# review: new
gtk-client-id = クライアントID
# review: new
gtk-client-secret = クライアント シークレット
# review: new
gtk-scopes = スコープ
# review: new
gtk-redirect-uri = リダイレクトURI
# review: new
gtk-issuer-usable =
    この発行者は使用できます。

    { $found }
# review: new
gtk-app-built-in = { $app }は組み込みのアプリです。変更できるのは、新しいアカウントで使用できるようにするかどうかだけです。{ $reason }
# review: new
gtk-built-in = { $app }（組み込み）
# review: new
gtk-offered-for-new = 新しいアカウントで使用可能
# review: new
gtk-edit-button = 編集...
# review: new
gtk-remove-app-ask = サインイン アプリ{ $app }と、保存されているクライアント シークレットを削除しますか？
# review: new
gtk-sign-in-apps-intro = サインイン アプリを使うと、アカウントはブラウザーでサインインできます。オフになっているアプリは新しいアカウントでは使用できませんが、すでに使用しているアカウントは引き続き動作します。

## AI agents

# review: new
gtk-agent-it-may = 許可する操作
# review: new
gtk-agent-accounts = 許可するアカウント
# review: new
gtk-never-used = 未使用
# review: new
gtk-last-used = 最終使用：{ $date }
# review: new
gtk-forget-program = このプログラムを削除しますか？
# review: new
gtk-forget-program-detail = プログラムのアクセス許可と、そのエージェントのアクティビティ履歴が削除されます。次回接続したときに、もう一度許可を求められます。
# review: new
gtk-no-agents-yet = メールの使用を求めたエージェントはまだありません。
# review: new
gtk-nothing-yet = まだ何もありません。

## Preferences

# review: new
gtk-preferences = 設定
# review: new
gtk-notify-subtitle = Inbox Classicがバックグラウンドにあるときのみ

## The desktop entry and the page of the software stores

# review: new
gtk-desktop-generic-name = メール クライアント
# review: new
gtk-desktop-comment = メールの読み書き：高速でシンプルなメール プログラム
# review: new
gtk-desktop-keywords = メール;電子メール;受信トレイ;メーラー;
# review: new
gtk-metainfo-summary = 高速でシンプルなメール プログラム
# review: new
gtk-metainfo-description = Inbox Classicはメールを読み書きするアプリです。クラシックなレイアウトで、左にフォルダー、上にメッセージ一覧、下に選択したメッセージが表示されます。互換性のあるIMAPとSMTPのアカウントで動作し、Outlook.comとMicrosoft 365にはブラウザーでサインインします。
# review: new
gtk-metainfo-feature-sanitized = メッセージ内のスクリプトなどのアクティブ コンテンツは削除され、インターネット上の画像は許可したときだけ読み込まれます
# review: new
gtk-metainfo-feature-search = 件名、差出人、受信者、添付ファイル名、本文を、おなじみのGmail形式の演算子で検索できます
# review: new
gtk-metainfo-feature-replies = 返信に引用された以前のメッセージは折りたたまれます
# review: new
gtk-metainfo-feature-offline = ダウンロードしたメールは、ローカルのコピーが保持されている間はオフラインでも読めます。サインイン資格情報は、利用できる場合は通常システムのキーリングに保存されます
