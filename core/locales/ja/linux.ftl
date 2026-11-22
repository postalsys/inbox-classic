# 日本語。ネイティブ スピーカーによるレビュー待ちの下書きです。

## The main window

gtk-search-looks-in = { $place }で、件名、差出人、受信者、添付ファイル名、本文を検索しました。つづりを確認するか、語句を減らしてみてください。
gtk-search-still-indexing = { $count }件のメッセージの本文を、まだインデックスに登録しています。まもなく結果が増える場合があります。
gtk-search-results-everywhere = すべてのフォルダーで「{ $words }」を検索：{ $count ->
    [0] 結果なし
   *[other] { $count }件
}
gtk-search-results-in = { $place }で「{ $words }」を検索：{ $count ->
    [0] 結果なし
   *[other] { $count }件
}
gtk-search-indexing = { $count }件のメッセージの本文をインデックスに登録中
gtk-list-loading = 読み込んでいます...
gtk-menu-rename = 名前の変更...
gtk-import-one-question = メッセージ{ $file }を{ $folder }にインポートしますか？
gtk-files-not-saved = { $total }個のファイルのうち{ $failed }個を保存できませんでした。
gtk-unsubscribe-one-click =
    このメーリング リストの配信を停止しますか？

    Inbox Classicから{ $target }に配信停止のリクエストを送信します。Webページは開かず、メールも送信されません。
gtk-unsubscribe-mail =
    このメーリング リストの配信を停止しますか？

    配信を停止するには、{ $target }にメールを送信します。メールはInbox Classicが用意します。メッセージを送信して確定してください。
gtk-unsubscribe-web =
    このメーリング リストの配信を停止しますか？

    メーリング リストの配信停止ページがブラウザーで開きます（{ $target }）。
gtk-unsubscribe-failed = 配信を停止できませんでした：{ $problem }
gtk-toolbar-create-mail-menu = 特定のアカウントからメールを作成
gtk-toolbar-send-recv-menu = 特定のアカウントのメールを送受信
gtk-main-menu = メイン メニュー
gtk-folder-list = フォルダー一覧
gtk-quit = 終了

## The Move and Copy window

gtk-new-folder-at-top-of = 新しいフォルダーは{ $account }の最上位に作成されます。

## Notifications and the tray

gtk-unread-messages = { $count ->
    [0] 未読メッセージはありません
   *[other] { $count }件の未読メッセージ
}

## The Outbox

gtk-outbox-empty = 送信待ちのメッセージはありません。
gtk-outbox-row = 宛先：{ $to }  ·  追加日時：{ $queued }  ·  { $status }

## The app

gtk-still-running-detail = Inbox Classicはバックグラウンドで新着メールの確認を続けます。アプリを開いたり終了したりするには、トップ バーのアイコンを使用してください。
gtk-sign-in-again-ask =
    { $account }へのサインインが拒否されたか、セッションの有効期限が切れました。

    ブラウザーでもう一度サインインしますか？
gtk-default-app-not-installed = このInbox Classicはインストールされていないため、システムのメール アプリの一覧に表示されません。選択するには、インストールしてください。
gtk-default-app-now = Inbox Classicが既定のメール アプリになりました。メールのリンクをクリックすると、ここで新しいメッセージが開きます。
gtk-default-app-failed = Inbox Classicを既定のメール アプリにできませんでした。

## The reading pane

gtk-reader-date = 日付:
gtk-reader-files = メッセージの添付ファイル
gtk-files = { $count }個のファイル
gtk-save-attachments-menu = 添付ファイルの保存...

## The compose window

gtk-format-bold = 太字（Ctrl+B）
gtk-format-italic = 斜体（Ctrl+I）
gtk-format-underline = 下線（Ctrl+U）
gtk-format-hyperlink = ハイパーリンク（Ctrl+K）
gtk-font = フォント
gtk-show-cc = CC(_C)
gtk-show-bcc = BCC(_B)
gtk-save-tip = 保存（Ctrl+S）
gtk-link-status = { $link }    （Ctrlキーを押しながらクリックすると開きます）

## Accounts

gtk-plain-warning =
    暗号化しないと、ネットワーク通信を傍受した人がパスワードとメッセージを読み取れます。接続が別の方法で保護されている場合にのみ続行してください。ローカル ネットワークというだけでは暗号化されません。

    続行しますか？
gtk-account-name-title = アカウント名
gtk-display-name-title = 表示名
gtk-turned-off-why = 「{ $button }」オプションは、このコンピューターで無効になっています。{ $reason }
gtk-turned-off-why-long =
    「{ $button }」オプションは、このコンピューターで無効になっています。

    { $reason }
gtk-next = 次へ >
gtk-provider-sign-in = { $provider }のWebサイトで{ $address }にサインインします。パスワードがInbox Classicに渡されることはありません。アカウントでメール用のアプリ パスワードを使える場合は、アカウントのセキュリティ設定で作成したアプリ パスワードも使用できます。Outlook.comとMicrosoft 365では、ブラウザーでのサインインのみを使用できます。
gtk-provider-sign-in-apps = サインイン アプリ（その他のサインイン オプション）のいずれかを使って、{ $provider }のWebサイトで{ $address }にサインインします。アカウントでメール用のアプリ パスワードを使える場合は、アカウントのセキュリティ設定で作成したアプリ パスワードも使用できます。Outlook.comとMicrosoft 365では、ブラウザーでのサインインのみを使用できます。
gtk-accounts-add = 追加...
gtk-accounts-properties = プロパティ...
gtk-accounts-signature = 署名...
gtk-accounts-sign-in-apps = サインイン アプリ...

## Sign-in apps

gtk-app-server = { $kind }サーバー
gtk-app-port = { $kind }ポート
gtk-app-security = { $kind }のセキュリティ
gtk-issuer-found =
    サインイン ページ：{ $page }
    トークン エンドポイント：{ $endpoint }
gtk-client-id = クライアントID
gtk-client-secret = クライアント シークレット
gtk-scopes = スコープ
gtk-redirect-uri = リダイレクトURI
gtk-issuer-usable =
    この発行者は使用できます。

    { $found }
gtk-app-built-in = { $app }は組み込みのアプリです。変更できるのは、新しいアカウントで使用できるようにするかどうかだけです。{ $reason }
gtk-built-in = { $app }（組み込み）
gtk-offered-for-new = 新しいアカウントで使用可能
gtk-edit-button = 編集...
gtk-remove-app-ask = サインイン アプリ{ $app }と、保存されているクライアント シークレットを削除しますか？
gtk-sign-in-apps-intro = サインイン アプリを使うと、アカウントはブラウザーでサインインできます。オフになっているアプリは新しいアカウントでは使用できませんが、すでに使用しているアカウントは引き続き動作します。

## AI agents

gtk-agent-it-may = 許可する操作
gtk-agent-accounts = 許可するアカウント
gtk-never-used = 未使用
gtk-last-used = 最終使用：{ $date }
gtk-forget-program = このプログラムの登録を削除しますか？
gtk-forget-program-detail = プログラムのアクセス許可と、そのエージェントのアクティビティ履歴が削除されます。次回接続したときに、もう一度許可を求められます。
gtk-no-agents-yet = メールの使用を求めたエージェントはまだありません。
gtk-nothing-yet = まだ何もありません。

## Preferences

gtk-preferences = 設定
gtk-notify-subtitle = Inbox Classicのメイン ウインドウが最前面にないときのみ

## The desktop entry and the page of the software stores

gtk-desktop-generic-name = メール クライアント
gtk-desktop-comment = メールの読み書き：高速でシンプルなメール プログラム
gtk-desktop-keywords = メール;電子メール;受信トレイ;メーラー;
gtk-metainfo-summary = 高速でシンプルなメール プログラム
gtk-metainfo-description = Inbox Classicはメールを読み書きするアプリです。クラシックなレイアウトで、左にフォルダー、上にメッセージ一覧、下に選択したメッセージが表示されます。互換性のあるIMAPとSMTPのアカウントで動作し、Outlook.comとMicrosoft 365にはブラウザーでサインインします。
gtk-metainfo-feature-sanitized = メッセージ内のスクリプトなどのアクティブ コンテンツは削除され、インターネット上の画像は許可したときだけ読み込まれます
gtk-metainfo-feature-search = 件名、差出人、受信者、添付ファイル名、本文を、おなじみのGmail形式の演算子で検索できます
gtk-metainfo-feature-replies = 返信に引用された以前のメッセージは折りたたまれます
gtk-metainfo-feature-offline = ダウンロードしたメールは、ローカルのコピーが保持されている間はオフラインでも読めます。サインイン資格情報は、利用できる場合は通常システムのキーリングに保存されます
