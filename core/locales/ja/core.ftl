# 日本語。ネイティブ スピーカーによるレビュー待ちの下書きです。

## Counts and sizes

# review: new
messages = { $count }件のメッセージ
# review: new
decimal-separator = .
# review: new
list-separator = 、
# review: new
size-bytes = { $count }バイト
# review: new
size-kb = { $size } KB
# review: new
size-mb = { $size } MB
# review: new
size-gb = { $size } GB
# review: new
send-delay-off = オフ
# review: new
send-delay-seconds = { $count }秒
# review: new
list-counts = { $messages }、未読{ $unread }件
# review: new
list-counts-selected = { $messages }、未読{ $unread }件、{ $selected }件を選択中
# review: new
list-counts-found = 検索結果{ $found }件、未読{ $unread }件
# review: new
list-counts-found-selected = 検索結果{ $found }件、未読{ $unread }件、{ $selected }件を選択中
# review: new
list-counts-none = メッセージが見つかりません

## Special folders, as Outlook Express names them

# review: new
folder-inbox = 受信トレイ
# review: new
folder-sent = 送信済みアイテム
# review: new
folder-deleted = 削除済みアイテム
# review: new
folder-drafts = 下書き
# review: new
folder-junk = 迷惑メール
# review: new
folder-archive = アーカイブ

## The reading pane

# review: new
reader-no-message = メッセージが選択されていません。
# review: new
reader-downloading = メッセージをダウンロードしています…
# review: new
reader-downloading-detail = ダウンロードが完了すると、ここにメッセージが表示されます。
# review: new
reader-downloading-size = このメッセージのサイズは{ $size }です。ダウンロードが完了すると、ここに表示されます。
# review: new
reader-failed = メッセージをダウンロードできませんでした
# review: new
reader-failed-network = メール サーバーに接続できなかったか、接続が中断されました（{ $reason }）。
# review: new
reader-failed-sign-in = メール サーバーがサインインを受け付けませんでした（{ $reason }）。パスワードを確認するか、アカウントの設定でもう一度サインインしてください。
# review: new
reader-failed-security = メール サーバーとの接続を保護できませんでした（{ $reason }）。
# review: new
reader-failed-other = メール サーバーの応答：{ $reason }。
# review: new
reader-retry-note = アカウントが再接続されたときに、もう一度試します。
# review: new
reader-unreadable = このメッセージを表示できません：{ $error }
# review: new
message-source-title = メッセージのソース：{ $subject }
# review: new
message-source-untitled = メッセージのソース

## Printing a message, and the header of a message quoted in a reply or forward

# review: new
header-from = 差出人
# review: new
header-date = 日付
# review: new
header-to = 宛先
# review: new
header-cc = CC
# review: new
header-sent = 送信日時
# review: new
header-subject = 件名
# review: new
header-security = セキュリティ
# review: new
header-part = パート{ $number }
# review: new
quote-original = ----- 元のメッセージ -----
# review: new
fold-show-earlier = 以前のメッセージを表示

## Bounces: the card at the top of a notice that a message was not delivered

# review: new
bounce-failed = メッセージは配信されませんでした
# review: new
bounce-delayed = メッセージはまだ配信されていません
# review: new
bounce-delayed-note = メール サーバーが配信を試み続けています。もう一度送信する必要はありません。
# review: new
bounce-show-message = 配信されなかったメッセージを表示
# review: new
bounce-show-delayed = 遅延しているメッセージを表示
# review: new
bounce-what-to-do = 対処方法：
# review: new
bounce-delayed-do = 今は何もする必要はありません。最終的に配信できなかった場合は、改めて通知が届きます。
# review: new
bounce-delayed-row-do = 今は何もする必要はありません。メール サーバーが配信を試み続けており、配信できなかった場合は改めて通知が届きます。
# review: new
bounce-details = 詳細
# review: new
bounce-someone = 受信者
# review: new
bounce-server = サーバー：{ $server }
# review: new
bounce-status = ステータス：{ $status }
# review: new
bounce-reported-by = 報告元：{ $server }
# review: new
bounce-retry-minutes = 受信側のサーバーから、次の試行まで{ $count }分待つよう求められました。
# review: new
bounce-retry-hours = 受信側のサーバーから、次の試行まで{ $count }時間待つよう求められました。
# review: new
bounce-blocklist = ブロックリスト：{ $lists }
# review: new
bounce-user-unknown = アドレスが存在しません
# review: new
bounce-user-unknown-why = 受信側のサーバーに、このアドレスのメールボックスがありません。アドレスが間違っているか、相手がそのアドレスを使わなくなった可能性があります。
# review: new
bounce-user-unknown-do = アドレスのつづりを確認するか、相手に現在使っているアドレスを尋ねてください。
# review: new
bounce-invalid-address = アドレスが正しくありません
# review: new
bounce-invalid-address-why = アドレスが、メールを送信できる形式で書かれていません。
# review: new
bounce-invalid-address-do = スペースが入っている、文字が抜けている、@の後に何もないなどの入力ミスがないか確認してください。
# review: new
bounce-mailbox-disabled = メールボックスが閉鎖されています
# review: new
bounce-mailbox-disabled-why = アドレスは存在しますが、そのメールボックスは無効にされているか、使われなくなっています。
# review: new
bounce-mailbox-disabled-do = 別の方法で相手に連絡し、現在使っているアドレスを尋ねてください。
# review: new
bounce-mailbox-full = メールボックスがいっぱいです
# review: new
bounce-mailbox-full-why = 受信者のメールボックスに、新しいメールを受け取る空きがありません。
# review: new
bounce-mailbox-full-do = 数日後にもう一度送信するか、別の方法で相手に知らせてください。
# review: new
bounce-spam-blocked = スパムとして拒否されました
# review: new
bounce-spam-blocked-why = 受信側のサーバーが、このメッセージをスパムと判断しました。
# review: new
bounce-spam-blocked-do = 多数のリンク、短縮URL、大きな添付ファイルなど、スパムに見える要素を除いてもう一度送信してください。何度も起こる場合は、メール プロバイダーに問い合わせてください。
# review: new
bounce-virus-detected = ウイルスのため拒否されました
# review: new
bounce-virus-detected-why = 受信側のサーバーから、メッセージまたは添付ファイルにウイルスなどの有害な内容が含まれていると報告されました。
# review: new
bounce-virus-detected-do = ウイルス スキャナーで添付ファイルを確認してください。プログラムや圧縮ファイルをすべて拒否するサーバーもあるため、そのようなファイルはリンクで共有してください。
# review: new
bounce-ip-blocklisted = お使いのメール サーバーがブロックリストに登録されています
# review: new
bounce-ip-blocklisted-why = お使いのメールを送信したサーバーのアドレスがブロックリストに登録されているため、受信側のサーバーがそのサーバーからのメールを拒否しています。
# review: new
bounce-ip-blocklisted-do = メッセージに問題はありません。この通知をメール プロバイダーに転送し、サーバーをリストから削除してもらうよう依頼してください。
# review: new
bounce-domain-blocklisted = ドメインがブロックリストに登録されています
# review: new
bounce-domain-blocklisted-why = お使いのアドレスのドメイン、またはメッセージ内のリンクのドメインがブロックリストに登録されているため、受信側のサーバーがメッセージを拒否しました。
# review: new
bounce-domain-blocklisted-do = メッセージにリンクが含まれている場合は、リンクなしで送信してみてください。含まれていない場合は、ドメインのメールを管理している担当者にこの通知を転送してください。
# review: new
bounce-policy-blocked = 受信側のサーバーのルールによって拒否されました
# review: new
bounce-policy-blocked-why = 受信側のサーバーのルールにより、このメッセージは受け付けられません。サイズ、添付ファイル、差出人などが理由として考えられます。
# review: new
bounce-policy-blocked-do = 多くの場合、［詳細］にあるサーバー自身のメッセージに理由が書かれています。このようなメールを受け取れるかどうか、受信者に確認してください。
# review: new
bounce-geo-blocked = 送信元の地域のため拒否されました
# review: new
bounce-geo-blocked-why = 受信側のサーバーは、お使いのメール サーバーがある国またはネットワークからのメールを受け付けていません。
# review: new
bounce-geo-blocked-do = 別の方法で相手に連絡するか、メール プロバイダーに問い合わせてください。
# review: new
bounce-relay-denied = サーバーが転送を拒否しました
# review: new
bounce-relay-denied-why = あるサーバーがメッセージの転送を拒否しました。多くの場合、サインインせずに送信したか、この受信者を扱わないサーバーを経由して送信したことが原因です。
# review: new
bounce-relay-denied-do = アカウントの設定で、送信サーバーとサインイン情報を確認してください。
# review: new
bounce-auth-failure = 差出人のアドレスを確認できませんでした
# review: new
bounce-auth-failure-why = 受信側のサーバーは、メッセージが本当にお使いのドメインから送信されたことを確認できませんでした（SPF、DKIM、DMARC）。
# review: new
bounce-auth-failure-do = ドメインのメールを管理している担当者にこの通知を転送してください。ドメインの設定を修正する必要があります。それまでは、プロバイダー自身のサーバーから送信すると解決する場合があります。
# review: new
bounce-rate-limited = 一度に送信したメールが多すぎます
# review: new
bounce-rate-limited-why = 受信側のサーバーは現在、お使いのメール サーバーから受け付けるメッセージの数を制限しています。
# review: new
bounce-rate-limited-do = しばらく待ってから、もう一度送信してください。多くの人に送信する場合は、一度に送る人数を減らしてください。
# review: new
bounce-greylisting = 一時的に保留されました
# review: new
bounce-greylisting-why = 受信側のサーバーは、不明な送信者に少し後で再送するよう求めています。これはスパム対策としてよく行われる確認です。
# review: new
bounce-greylisting-do = 一時的な遅延であれば、通常は送信側のサーバーが再試行します。この通知が最終的な失敗を報告している場合は、後でもう一度メッセージを送信してみてください。
# review: new
bounce-server-error = 受信側のサーバーで問題が発生しました
# review: new
bounce-server-error-why = 受信側のサーバーに接続できなかったか、サーバー自身の問題でメッセージを受け取れませんでした。
# review: new
bounce-server-error-do = 後でもう一度送信してください。何度も失敗する場合は、アドレスの@より後の部分に入力ミスがないか確認してください。
# review: new
bounce-unknown = 配信されませんでした
# review: new
bounce-unknown-why = 通知には理由がはっきり書かれていません。
# review: new
bounce-unknown-do = ［詳細］にあるサーバー自身のメッセージで、さらに詳しくわかる場合があります。それでもわからない場合は、この通知をメール プロバイダーに転送してください。

## Several messages selected

# review: new
selection-title = { $count }件のメッセージを選択中
# review: new
selection-unread = 未読{ $count }件
# review: new
selection-flagged = フラグ付き{ $count }件
# review: new
delete-for-good-one = このメッセージは完全に削除されます。削除しますか？
# review: new
delete-for-good-all = これらの{ $count }件のメッセージは完全に削除されます。削除しますか？
# review: new
delete-for-good-some = { $total }件のメッセージのうち{ $count }件が完全に削除されます。メッセージを削除しますか？
# review: new
done-read = { $count ->
   *[other] { $messages }を既読にしました
}
# review: new
done-unread = { $count ->
   *[other] { $messages }を未読にしました
}
# review: new
done-flagged = { $count ->
   *[other] { $messages }にフラグを設定しました
}
# review: new
done-unflagged = { $messages }のフラグをクリアしました
# review: new
done-deleted-for-good = { $count ->
   *[other] { $messages }を完全に削除しました
}
# review: new
done-archived = { $count ->
   *[other] { $messages }をアーカイブしました
}
# review: new
done-moved = { $count ->
   *[other] { $messages }を{ $folder }に移動しました
}
# review: new
done-copied = { $count ->
   *[other] { $messages }を{ $folder }にコピーしました
}
# review: new
done-moving = { $count ->
   *[other] { $messages }を{ $folder }に移動しています...
}
# review: new
done-copying = { $count ->
   *[other] { $messages }を{ $folder }にコピーしています...
}
# review: new
done-moved-back = { $count ->
   *[other] { $messages }を{ $folder }に戻しました
}
# review: new
done-watched = { $count ->
    [1] スレッドをウォッチしています
   *[other] { $count }件のスレッドをウォッチしています
}
# review: new
done-unwatched = { $count ->
    [1] スレッドのウォッチを停止しました
   *[other] { $count }件のスレッドのウォッチを停止しました
}
# review: new
done-ignored = { $count ->
    [1] スレッドを無視しています
   *[other] { $count }件のスレッドを無視しています
}
# review: new
done-unignored = { $count ->
    [1] スレッドの無視を解除しました
   *[other] { $count }件のスレッドの無視を解除しました
}
# review: new
their-folders = 元のフォルダー
# review: new
undo-move = 移動を元に戻す
# review: new
undo-delete = 削除を元に戻す
# review: new
undo-archive = アーカイブを元に戻す
# review: new
undo-junk = 「迷惑メールとしてマーク」を元に戻す
# review: new
undo-not-junk = 「迷惑メールではないとしてマーク」を元に戻す
# review: new
undo-send = 送信を元に戻す
# review: new
nothing-to-undo = 元に戻す操作はありません。
# review: new
messages-gone = メッセージはもう存在しません。
# review: new
folder-holds-no-messages = このフォルダーにはメッセージを保存できません。
# review: new
not-archived-here = このフォルダーのメッセージはアーカイブできません。
# review: new
not-emptied-here = 空にできるのは、削除済みアイテムと迷惑メールだけです。
# review: new
next-unread-question = { $folder }に未読メッセージはもうありません。

    未読メッセージがある次のフォルダー「{ $next }」に移動しますか？
# review: new
no-unread-left = 未読メッセージはもうありません。
# review: new
empty-question = { $count ->
   *[other] { $folder }を空にしますか？

        中にある{ $messages }は完全に削除されます。元に戻すことはできません。
}
# review: new
no-junk-folder = このアカウントには、メッセージの移動先となる迷惑メール フォルダーがありません。
# review: new
no-inbox-folder = このアカウントには、メッセージの移動先となる受信トレイがありません。
# review: new
done-flagged-color = { $messages }に{ $color ->
    [red] 赤
    [orange] オレンジ
    [yellow] 黄
    [green] 緑
    [blue] 青
    [purple] 紫
   *[gray] 灰色
}のフラグを設定しました
# review: new
flag-color = { $color ->
    [red] 赤
    [orange] オレンジ
    [yellow] 黄
    [green] 緑
    [blue] 青
    [purple] 紫
   *[gray] 灰色
}

## The Move and Copy window

# review: new
move-window-title-move = { $count ->
    [1] メッセージの移動
   *[other] { $count }件のメッセージの移動
}
# review: new
move-window-title-copy = { $count ->
    [1] メッセージのコピー
   *[other] { $count }件のメッセージのコピー
}
# review: new
move-window-prompt-move = { $count ->
    [1] 選択したメッセージの移動先:
   *[other] 選択した{ $count }件のメッセージの移動先:
}
# review: new
move-window-prompt-copy = { $count ->
    [1] 選択したメッセージのコピー先:
   *[other] 選択した{ $count }件のメッセージのコピー先:
}
# review: new
targets-recent = 最近使用したフォルダー
# review: new
target-current = { $folder }（現在のフォルダー）
# review: new
target-recent = { $folder }（{ $account }）

## Moving and copying to another account

# review: new
transfer-moving = { $messages }のうち{ $done }件を{ $folder }に移動しています...
# review: new
transfer-copying = { $messages }のうち{ $done }件を{ $folder }にコピーしています...
# review: new
transfer-another-account = 別のアカウント
# review: new
transfer-folder-gone = 移動先のフォルダーはもう存在しません
# review: new
transfer-not-on-server = メッセージはもうサーバー上にありません
# review: new
transfer-not-moved = { $count ->
   *[other] { $messages }を別のアカウントに移動できませんでした：{ $reason }
}
# review: new
transfer-not-copied = { $count ->
   *[other] { $messages }を別のアカウントにコピーできませんでした：{ $reason }
}
# review: new
transfer-none-moved = メッセージを移動できませんでした
# review: new
transfer-none-copied = メッセージをコピーできませんでした

## Messages as files

# review: new
export-not-in-time = メッセージを時間内にダウンロードできませんでした
# review: new
export-not-saved = { $messages }のうち{ $failed }件を保存できませんでした（{ $problems }）
# review: new
export-not-attached = メッセージを添付できませんでした：{ $error }
# review: new
saved-to = { $count ->
   *[other] { $messages }を{ $folder }に保存しました
}
# review: new
download-progress = { $total }中{ $done }をダウンロードしています
# review: new
download-done = { $size }をダウンロードしました
# review: new
downloading-messages = { $count ->
   *[other] { $messages }をダウンロードしています...
}
# review: new
import-put = { $count ->
   *[other] { $messages }を{ $folder }へのインポート待ちに追加しました
}
# review: new
import-not-put = 次のファイルはフォルダーに追加されませんでした：

    { $problems }

## Problems the windows show

# review: new
error-store = ローカル ストア：{ $error }
# review: new
error-not-found = 見つかりません
# review: new
error-closed = 終了処理中です
# review: new
error-other-account = ブラウザーでサインインしたのは{ $email }で、このアカウントではありません
# review: new
failure-authentication = サーバーがサインインを受け付けませんでした（{ $reason }）
# review: new
failure-network = サーバーへの接続に失敗しました（{ $reason }）
# review: new
error-in-use = このアプリでサインインしているアカウントがあるため、削除できません：{ $accounts }
# review: new
error-turned-off = このサインイン アプリは、新しいアカウントに対してオフになっています
# review: new
error-folder-name = フォルダー名は1～200文字で指定し、制御文字を含めることはできません
# review: new
error-folder-separator = このサーバーでは、フォルダー名に「{ $separator }」を使用できません
# review: new
error-folder-special = 受信トレイと特別なフォルダーは、名前の変更も削除もできません
# review: new
error-no-recipients = メッセージに受信者がありません
# review: new
error-bad-address = 「{ $address }」はメール アドレスではありません
# review: new
error-not-own-address = { $address }は、このアカウントの差出人アドレスではありません。アカウントのプロパティの「送信に使うその他のアドレス」に追加してください。
# review: new
rule-query-refused = ルールでは、フォルダーや日付で絞り込むことはできません（{ $words }）。
# review: new
rule-no-query = 受信メッセージの検索条件を入力してください。
# review: new
rule-no-action = ルールの処理を1つ以上選択してください。
# review: new
error-attachment = { $path }を読み取れませんでした：{ $error }
# review: new
error-no-drafts = このアカウントには、メッセージを保存する下書きフォルダーがありません
# review: new
error-draft-attachment = 下書きの添付ファイルを保持できませんでした：{ $error }
# review: new
error-password-not-saved = 次回の起動用にパスワードを保存できませんでした：{ $error }
# review: new
error-sign-in-not-saved = 次回の起動用に新しいサインイン情報を保存できませんでした：{ $error }
# review: new
error-import-unreadable = { $path }を読み取れません：{ $error }
# review: new
error-import-too-large = { $path }は50 MBを超えています
# review: new
error-import-not-mail = { $path }はメール メッセージではありません
# review: new
error-list-answered = メーリング リストのサーバーからステータス{ $status }が返されました
# review: new
error-not-built = メッセージを作成できませんでした
# review: new
error-outbox-waits = { $count }件のメッセージが送信トレイに残っています。次回の送受信で、もう一度送信を試みます
# review: new
error-draft-not-removed = メッセージの以前の下書きを下書きフォルダーから削除できませんでした：{ $reason }
# review: new
error-sent-but = メッセージは送信されましたが、{ $problem }
# review: new
error-sent-still-in-outbox = 送信トレイに残っています：{ $error }
# review: new
error-sent-no-copy = 送信済みアイテムにコピーを保存できませんでした：{ $reason }
# review: new
error-no-password = このアカウントのパスワードがありません
# review: new
error-no-sign-in = このアカウントのサインイン情報がありません
# review: new
error-provider-missing = このビルドでは、このサインイン アプリを使用できません（ID：{ $provider }）。削除された可能性があります
# review: new
error-provider-servers = このアカウントのサーバーが、サインイン アプリのサーバーと一致しません
# review: new
error-app-scopes = { $reason }。メール サーバーがサインイン アプリのトークンを受け付けませんでした。アプリのスコープでメールへのアクセスが許可されているか確認してください
# review: new
error-in-folder = { $folder }：{ $reason }

## Sign-in apps

# review: new
sign-in-off-google = 組み込みのGoogleサインイン アプリは承認されたテスト ユーザー向けに設定されており、既定では新しいアカウントに対してオフになっています。テスト ユーザーは、サインイン アプリ（ファイル > アカウント）でオンにできます。独自のGoogleサインイン アプリや、アカウントが対応していればアプリ パスワードを使用することもできます。
# review: new
sign-in-off-other = 新しいアカウントに対してオフになっています。サインイン アプリ（ファイル > アカウント）でオンにできます。
# review: new
sign-in-app-no-name = サインイン アプリに名前が必要です
# review: new
sign-in-app-no-client = クライアントIDがありません
# review: new
sign-in-app-no-scopes = サインイン アプリに、メールへのアクセスを許可するスコープが必要です
# review: new
sign-in-app-bad-host = { $server }サーバーのアドレスがないか、有効なホスト名ではありません
# review: new
sign-in-app-plain = { $server }サーバーでは、SSL/TLSまたはSTARTTLSを使用する必要があります
# review: new
sign-in-app-not-checked = 発行者がまだ確認されていません
# review: new
sign-in-app-issuer-changed = 発行者が変更されました。クライアント シークレットをもう一度入力するか、削除してください
# review: new
sign-in-register-google = Google Cloud Consoleで、種類が「デスクトップ アプリ」のOAuthクライアントを作成し、その同意画面にスコープ「https://mail.google.com/」を追加します。アプリがテスト中の間は、そのテスト ユーザーだけがサインインできます。
# review: new
sign-in-register-microsoft = Microsoft Entraで、プラットフォーム「モバイル アプリケーションとデスクトップ アプリケーション」、リダイレクトURI「http://localhost」、パブリック クライアント フローの許可、委任されたアクセス許可IMAP.AccessAsUser.All、SMTP.Send、offline_accessを設定してアプリを登録します。自分の組織だけで使う場合は、発行者として「https://login.microsoftonline.com/<テナントID>/v2.0」を使用します。
# review: new
sign-in-register-other = 下記のリダイレクトURIで、ネイティブ（パブリック）クライアントを登録します。プロバイダーは、このURIで任意のポートを許可する必要があります（RFC 8252）。プロバイダーがメールへのアクセスに使うスコープを追加してください。

## Calendar invitations

# review: new
repeats = 繰り返し
# review: new
repeats-every = { $unit ->
    [day] { $interval ->
        [1] 毎日
       *[other] { $interval }日ごと
    }
    [week] { $interval ->
        [1] 毎週
       *[other] { $interval }週間ごと
    }
    [month] { $interval ->
        [1] 毎月
       *[other] { $interval }か月ごと
    }
   *[year] { $interval ->
        [1] 毎年
       *[other] { $interval }年ごと
    }
}
# review: new
repeats-on = { $repeats }（{ $days }）
# review: new
repeats-times = { $repeats }、{ $count }回
# review: new
day-monday = 月曜日
# review: new
day-tuesday = 火曜日
# review: new
day-wednesday = 水曜日
# review: new
day-thursday = 木曜日
# review: new
day-friday = 金曜日
# review: new
day-saturday = 土曜日
# review: new
day-sunday = 日曜日

## AI agents

# review: new
agent-level-read = メールの読み取り：フォルダー、メッセージ一覧、スレッド、検索、メッセージとそのファイル、メッセージ ルール、メールを送ったことのある相手
# review: new
agent-level-organize = メールの整理：既読と未読、フラグとその色、迷惑メール、移動、アーカイブ、フォルダーの作成と名前の変更、スレッドのウォッチと無視、削除済みアイテムへの削除、承認後のメーリング リストの配信停止
# review: new
agent-level-drafts = 下書きの作成（送信はご自身で行います）
# review: new
agent-level-send = メールの送信（メッセージごとに承認が必要）
# review: new
agent-connect-title = { $program }がメールの使用を求めています
# review: new
agent-connect-detail = AIエージェントがInbox Classicとの連携を求めています。許可する操作と、参照できるアカウントを選択してください。この設定は後で［ツール］>［AIエージェント］で変更できます。

    エージェントはほかの人が書いたメールを読むため、メッセージによってエージェントがだまされる可能性があります。エージェントが何かを送信する前に、Inbox Classicは必ず確認を求めます。
# review: new
agent-reply-to = 「{ $subject }」への返信
# review: new
agent-reply-all-on = 「{ $subject }」への全員へ返信
# review: new
agent-forward-of = 「{ $subject }」の転送
# review: new
agent-never-written-one = { $address }にメールを送ったことはありません。
# review: new
agent-never-written-many = これらのアドレスのうち{ $count }件には、メールを送ったことがありません。
# review: new
agent-send-title = { $program }がこのメッセージの送信を求めています
# review: new
agent-send-detail = 受信者とメッセージの内容を確認してください。確定すると、メッセージは送信トレイで{ $seconds }秒間待機します。その間は削除できます。
# review: new
agent-change-title = { $program }に許可する操作
# review: new
agent-change-allowed = このプログラムのAIエージェントがメールに対して行える操作を変更します。
# review: new
agent-change-refused = このプログラムのアクセスを拒否しています。エージェントにもう一度メールへのアクセスを与えるには、許可してください。
# review: new
agent-log-taken-back = { $entry }（取り消し済み）
# review: new
agent-files = ファイル：{ $files }
# review: new
agent-undo-refused = 取り消すことはできません。
# review: new
agent-undo-refused-why = 取り消すことはできません：{ $reason }。
# review: new
agent-undo-impossible = この操作は取り消せません
# review: new
agent-undo-not-in-folder = メッセージはもうそのフォルダーにありません
# review: new
agent-undo-not-arrived = メッセージが移動先のフォルダーに（まだ）ありません
# review: new
agent-undo-sent = メッセージはもう送信トレイにありません
# review: new
agent-original-not-downloaded = 元のメッセージがまだダウンロードされていません。先に開いてください
# review: new
agent-turned-away = 拒否済み
# review: new
agent-can-nothing = なし
# review: new
agent-can-read = 読み取り
# review: new
agent-can-organize = 整理
# review: new
agent-can-drafts = 下書きの作成
# review: new
agent-can-send = 承認後の送信
# review: new
agent-can-list = { $first }、{ $last }
# review: new
agent-accounts = { $count ->
    [0] アカウントなし
   *[other] { $count }個のアカウント
}
# review: new
agent-access = { $can }（{ $accounts }）
# review: new
agent-unreadable = このメッセージは読み取れません。
# review: new
agent-encrypted-original = このメッセージは暗号化されています。エージェントは暗号化を行えないため、このメッセージに返信したり転送したりすることはできません。
# review: new
agent-encrypted = このメッセージは暗号化されています。AIエージェントはその内容を読み取れません。ご自身で読むには、Inbox Classicで開いてください。
# review: new
agent-too-many-changes = 過去30日間の変更が多すぎます。このエージェントは、Inbox Classicが1つのプログラムについてログに記録できる上限まで変更を行いました。最も古い変更から30日が経つと、さらに変更できるようになります。
# review: new
agent-too-many-reads = 過去30日間の読み取りが多すぎます。このエージェントは、Inbox Classicが1つのプログラムについてログに記録できる上限まで読み取りを行いました。最も古い読み取りから30日が経つと、さらに読み取れるようになります。
# review: new
list-encrypted = 暗号化されたメッセージ
# review: new
agent-log-composed = 「{ $subject }」を新しいメッセージで開きました（仕上げはご自身で行います）
# review: new
agent-log-refused = 「{ $subject }」を送信しませんでした
# review: new
agent-log-sent = { $to }宛ての「{ $subject }」を送信トレイに追加しました
# review: new
agent-log-draft = 下書き「{ $subject }」を保存しました
# review: new
agent-log-draft-replaced = 下書き「{ $subject }」を置き換えました
# review: new
agent-log-draft-discarded = 下書き「{ $subject }」の削除をリクエストしました
# review: new
agent-draft-note = この下書きは、AIエージェントの{ $program }が作成しました。送信する前に、受信者と本文を確認してください。
# review: new
agent-log-read = 「{ $subject }」を既読にしました
# review: new
agent-log-unread = 「{ $subject }」を未読にしました
# review: new
agent-log-flagged = 「{ $subject }」にフラグを設定しました
# review: new
agent-log-unflagged = 「{ $subject }」のフラグをクリアしました
# review: new
agent-log-deleted = 「{ $subject }」を削除しました
# review: new
agent-log-moved = 「{ $subject }」を{ $folder }に移動しました
# review: new
agent-log-junk = 「{ $subject }」を迷惑メールとしてマークしました
# review: new
agent-log-not-junk = 「{ $subject }」を迷惑メールではないとしてマークしました
# review: new
agent-log-archived = 「{ $subject }」をアーカイブしました
# review: new
agent-log-folder = フォルダー「{ $name }」の作成をリクエストしました
# review: new
agent-log-unsubscribed = メッセージ「{ $subject }」のリストの配信停止を承認しました
# review: new
agent-log-unsubscribe-failed = メッセージ「{ $subject }」のリストの配信を停止できませんでした：{ $reason }
# review: new
agent-log-unsubscribe-refused = { $senders }の配信停止のリクエストを承認しませんでした
# review: new
agent-unsubscribe-title = { $count ->
    [1] { $program }がメーリング リストの配信停止を求めています
   *[other] { $program }が{ $count }件のメーリング リストの配信停止を求めています
}
# review: new
agent-unsubscribe-detail = { $count ->
    [1] Inbox Classicは、下記のリストが提供するワンクリック方式で、配信の停止をリストに依頼します。それ以外には何も送信されず、お手元のメッセージもそのまま残ります。
   *[other] Inbox Classicは、下記の各リストが提供するワンクリック方式で、配信の停止を各リストに依頼します。それ以外には何も送信されず、お手元のメッセージもそのまま残ります。
}
# review: new
agent-log-flag-color = 「{ $subject }」に{ $color ->
    [red] 赤
    [orange] オレンジ
    [yellow] 黄
    [green] 緑
    [blue] 青
    [purple] 紫
   *[gray] 灰色
}のフラグを設定しました
# review: new
agent-log-renamed = フォルダー「{ $old }」の名前を「{ $name }」に変更するようリクエストしました
# review: new
agent-log-watched = スレッド「{ $subject }」をウォッチしました
# review: new
agent-log-ignored = スレッド「{ $subject }」を無視しました
# review: new
agent-log-unmarked = スレッド「{ $subject }」のウォッチまたは無視を解除しました
# review: new
agent-undo-changed = その後、メッセージが変更されました
# review: new
agent-log-bulk-read = { $count }件のメッセージを既読にしました（検索：{ $query }）
# review: new
agent-log-bulk-unread = { $count }件のメッセージを未読にしました（検索：{ $query }）
# review: new
agent-log-bulk-flagged = { $count }件のメッセージにフラグを設定しました（検索：{ $query }）
# review: new
agent-log-bulk-unflagged = { $count }件のメッセージのフラグをクリアしました（検索：{ $query }）
# review: new
agent-log-bulk-color = { $count }件のメッセージに{ $color ->
    [red] 赤
    [orange] オレンジ
    [yellow] 黄
    [green] 緑
    [blue] 青
    [purple] 紫
   *[gray] 灰色
}のフラグを設定しました（検索：{ $query }）
# review: new
agent-log-bulk-moved = { $count }件のメッセージを{ $folder }に移動しました（検索：{ $query }）
# review: new
agent-log-bulk-archived = { $count }件のメッセージをアーカイブしました（検索：{ $query }）
# review: new
agent-log-bulk-junk = { $count }件のメッセージを迷惑メールとしてマークしました（検索：{ $query }）
# review: new
agent-log-bulk-not-junk = { $count }件のメッセージを迷惑メールではないとしてマークしました（検索：{ $query }）
# review: new
agent-log-bulk-deleted = { $count }件のメッセージを削除しました（検索：{ $query }）
# review: new
agent-undo-span = { $span ->
    [quarter] 過去15分間
    [hour] 過去1時間
    [hours] 過去4時間
    [day] 過去24時間
    [week] 過去7日間
   *[all] 過去30日間
}
# review: new
agent-undo-since-question = { $count ->
    [0] この期間に、{ $program }について取り消せる変更はありません。
    [1] この期間に{ $program }について記録された変更の取り消しを試みますか？
   *[other] この期間に{ $program }について記録された{ $count }件の変更の取り消しを試みますか？
}
# review: new
agent-undo-since-detail = Inbox Classicは、フォルダー、既読と未読の状態、フラグを元に戻し、送信トレイで待機中のメッセージを削除しようとします。すでに元に戻せない変更はスキップされます。その後に行われたフラグの色の変更が上書きされる場合があります。
# review: new
agent-undo-done = { $count ->
    [0] 何も取り消されませんでした。
   *[other] 記録された{ $count }件の変更を、全部または一部取り消しました。
}
# review: new
agent-undo-left-gone = { $count }件のメッセージは、変更によって移動された場所にありませんでした。
# review: new
agent-undo-left-changed = { $count }件のメッセージは、その後ご自身またはサーバー上で変更されていたため、そのままにしました。
# review: new
agent-undo-left-sent = { $count }件のメッセージは、すでに送信トレイから送信されていました。
# review: new
agent-undo-left-impossible = { $count }件の変更は取り消せません。
# review: new
agent-invitation-reply = { $response ->
    [accept] このメッセージで、招待「{ $summary }」（{ $when }）を承諾します。
    [tentative] このメッセージで、招待「{ $summary }」（{ $when }）を仮承諾します。
   *[decline] このメッセージで、招待「{ $summary }」（{ $when }）を辞退します。
}メッセージは、招待に記載されている開催者に送信されます。メール サーバーがメッセージを受け付けた時点で、開催者の予定表での確認を待たずに、このコンピューター上の返答が変わります。
# review: new
invitation-reply-subject = { $response ->
    [accept] 承諾: { $summary }
    [tentative] 仮承諾: { $summary }
   *[decline] 辞退: { $summary }
}
# review: new
invitation-reply-text = { $response ->
    [accept] { $name }がこの招待を承諾しました。
    [tentative] { $name }がこの招待を仮承諾しました。
   *[decline] { $name }がこの招待を辞退しました。
}
# review: new
agent-reads-messages = { $count }件のメッセージの読み取り
# review: new
agent-reads-attachments = { $count }件の添付ファイルの要求
# review: new
agent-reads-searches = { $count }回の検索
# review: new
agent-reads-lists = { $count }回のメッセージ一覧の表示
# review: new
agent-read-message = 「{ $subject }」を読み取りました
# review: new
agent-read-conversation = スレッド「{ $subject }」を読み取りました（{ $count }件のメッセージ）
# review: new
agent-read-attachment = 「{ $subject }」の添付ファイル「{ $name }」をリクエストしました
# review: new
agent-read-search = 「{ $query }」を検索しました：{ $count }件のメッセージ
# review: new
agent-read-people = 名前またはアドレスの先頭で連絡先を検索しました：「{ $query }」
# review: new
agent-read-list = 一覧の{ $count }件の項目を表示しました（範囲：{ $folder }）
# review: new
agent-read-changes = { $count }件の新着メッセージの詳細を表示しました
# review: new
agent-terminal-programs-mac = { $terminal }から起動されたプログラム
# review: new
agent-terminal-programs-windows = ターミナル（{ $terminal }）から起動されたプログラム
# review: new
agent-terminal-programs-linux = ターミナル（{ $terminal }）から起動されたプログラム
# review: new
agent-terminal-program-mac = { $terminal }から起動されたプログラム
# review: new
agent-terminal-program-windows = ターミナル（{ $terminal }）から起動されたプログラム
# review: new
agent-terminal-program-linux = ターミナル（{ $terminal }）から起動されたプログラム
# review: new
agent-connect-title-terminal = { $programs }がメールの使用を求めています
# review: new
agent-connect-terminal-detail = 同じ認識済みのターミナル プログラムから起動されたAIエージェントは、ここで許可するアクセスを共有します。個別のアクセスを与えるには、エージェントのMCP設定で、その引数に --name と任意の名前を追加してください。この名前で本人確認が行われるわけではありません。
# review: new
agent-connect-claimed = このプログラムは{ $claimed }であると名乗りました。Inbox Classicが確認した起動元のプログラム：{ $program }。

## Keys as the keyboards of the language name them, in the help (Windows and Linux)

# review: new
key-ctrl = Ctrl
# review: new
key-alt = Alt
# review: new
key-shift = Shift
# review: new
key-del = Del
# review: new
key-enter = Enter

## Signing in and passwords

# review: new
sign-in-no-refresh = プロバイダーから更新トークンが返されませんでした
# review: new
sign-in-no-account = どのアカウントでサインインしたのか、プロバイダーから返されませんでした
# review: new
sign-in-not-finished = サインインが完了していません
# review: new
secrets-unavailable = { $store }を使用できません
# review: new
secrets-unavailable-why = { $store }を使用できません：{ $error }
# review: new
secrets-windows = 資格情報マネージャー
# review: new
secrets-mac = キーチェーン
# review: new
secrets-linux = システムのキーリング（Secret Service）
# review: new
error-no-such-file = そのようなファイルはありません
# review: new
cards-file-too-big = このファイルは、アドレス帳のインポートのサイズ上限を超えています。
# review: new
ui-sender-added = { $name }をアドレス帳に追加しました。
# review: new
ui-sender-known = { $name }はすでにアドレス帳にあります。
# review: new
ui-sender-none = このメッセージの送信者には、追加できるメール アドレスがありません。
# review: new
card-name-needed = 連絡先に名前もメール アドレスもありません。
# review: new
cards-file-failed = { $file }：{ $reason }

## One-time codes: the card at the top of a message with a sign-in or verification code

# review: new
otp-heading = { $domain }からのコード
# review: new
otp-copy = コピー
# review: new
otp-note = このコードは{ $domain }のページでのみ入力してください。
# review: new
otp-old = このコードは開く1時間以上前に送信されたため、有効期限が切れている可能性があります。

# review: new
event-attendees = 出席者{ $count }人

# review: new
otp-notification = { $domain }のコード：{ $code }

## OpenPGP keys (keys.rs)
# review: new
pgp-key-valid = 有効
# review: new
pgp-key-expires = { $date }まで有効
# review: new
pgp-key-expired = { $date }に期限切れ
# review: new
pgp-key-revoked = 失効
# review: new
pgp-key-revoked-why = 失効：{ $reason }
# review: new
pgp-key-not-valid = 無効
# review: new
pgp-key-locked = 使用できません。保護キーを{ $store }で使用できません。{ $store }が利用可能で、ロックが解除されていることを確認してください。保護キーがない場合は、秘密キーのバックアップをインポートしてください。
# review: new
pgp-source-own = Inbox Classicで作成
# review: new
pgp-source-file = ファイルからインポート
# review: new
pgp-source-paste = 貼り付け
# review: new
pgp-source-attachment = メッセージから
# review: new
pgp-source-vcard = 連絡先カードから
# review: new
pgp-source-wkd = 送信者のメール プロバイダーから
# review: new
pgp-source-keyserver = keys.openpgp.orgから
# review: new
pgp-source-autocrypt = メッセージのAutocryptヘッダーから
# review: new
pgp-error-no-store = 秘密キーの保護キーは{ $store }に保存されていますが、使用できません：{ $error }
# review: new
pgp-error-wrong-passphrase = パスフレーズが正しくありません。
# review: new
pgp-error-not-a-key = これはOpenPGPキーではありません。
# review: new
pgp-error-too-large = キーが大きすぎます。
# review: new
pgp-error-unusable = このキーは使用できません。適切な署名用または暗号化用のキーがないか、サポートされていない暗号方式を使用している可能性があります。
# review: new
pgp-imported-private = 秘密キーを{ $count }個インポートしました。
# review: new
pgp-imported-public = キーを{ $count }個インポートしました。
# review: new
pgp-imported-pending = { $addresses }にはすでに別のキーが使用されています。新しいキーは、選択されるまで連絡先で保留されます。
# review: new
pgp-error-needs-passphrase = 秘密キーはパスフレーズで保護されています。キーをインポートするには、パスフレーズを入力してください。
# review: new
pgp-error-mismatch = 秘密キーが、対応する公開キーと一致しません。改ざんされている可能性があります。
# review: new
pgp-file-name-public = { $who }の公開キー.asc
# review: new
pgp-file-name-private = { $who }の秘密キーのバックアップ.asc
# review: new
pgp-pending = { $date }に、{ $address }の別のキーが見つかりました。

## Reading signed and encrypted mail (protect.rs)
# review: new
pgp-part-verified = { $signer }による署名、キーは検証済み
# review: new
pgp-part-signed = { $signer }による署名（キーは未検証）
# review: new
pgp-part-other = 送信者ではない{ $signer }による署名
# review: new
pgp-part-unknown-key = 署名されていますが、キーが不明です
# review: new
pgp-part-not-signed = 署名なし
# review: new
pgp-part-not-checked = 署名は未確認
# review: new
pgp-part-encrypted = 暗号化済み。{ $signature }
# review: new
pgp-part-no-key = お持ちでないキー宛てに暗号化されています
# review: new
pgp-part-changed = 暗号化された部分が整合性チェックに失敗したため、表示されません
# review: new
pgp-part-unprotected = 改ざん防止なしで暗号化されているため、表示されません
# review: new
pgp-part-broken = 暗号化された部分を読み取れません
# review: new
pgp-why-mismatch = 署名がこのテキストと一致しません
# review: new
pgp-why-weak-hash = 署名に使われている{ $hash }は、もう安全ではありません
# review: new
pgp-why-key-expired = キーの有効期限（{ $date }）が切れた後に署名されています
# review: new
pgp-why-key-revoked = 失効したキーで署名されています
# review: new
pgp-why-not-signing-key = 署名が許可されていない可能性のあるキーで署名されています
# review: new
pgp-why-from-future = 署名の日付が未来になっています
# review: new
pgp-why-signature-expired = 署名の有効期限が切れています
# review: new
pgp-why-key-not-valid = 無効なキーで署名されています
# review: new
pgp-why-not-for-you = ほかの受信者向けに署名され、あなたに転送されたものです
# review: new
pgp-why-not-key-in-use = { $address }に使用中のキーとは別のキーで署名されています
# review: new
pgp-part-pictures-loaded = { $label }。画像をインターネットから読み込みました
# review: new
pgp-error-no-own-key = { $address }の署名または暗号化に使うキーがありません。［ツール］>［暗号化キー］で作成するか、署名と暗号化をオフにしてください。
# review: new
pgp-error-missing-keys = { $count ->
   *[other] 次の受信者に使用できる暗号化キーがありません：{ $addresses }。
}
# review: new
pgp-error-encrypted-quote = このメッセージには暗号化されたメールのテキスト、画像、添付ファイルが含まれているため、暗号化しないと送信できません。暗号化をオンにするか、その内容をすべて削除してください。
# review: new
pgp-error-protect = メッセージに署名または暗号化できませんでした：{ $reason }
# review: new
pgp-found-keys = キーが見つかったアドレス：{ $addresses }。
# review: new
pgp-found-none = { $addresses }のキーは見つかりませんでした。公開キーを送ってもらうよう依頼してください。
# review: new
pgp-found-no-key = キーは見つかりませんでした。
# review: new
pgp-find-unavailable = 現在キーを検索できません：{ $error }
# review: new
pgp-publish-pending = keys.openpgp.orgから次のアドレスに確認のリンクが送信されました：{ $addresses }。各アドレスを確認すると、そのアドレスでキーを検索できるようになります。
# review: new
pgp-publish-done = { $addresses }のキーをkeys.openpgp.orgに公開しました。
# review: new
pgp-publish-failed = キーを公開できませんでした：{ $error }
# review: new
pgp-keyserver-off = keys.openpgp.orgでのキーの検索は、{ $settings }でオフになっています。
# review: new
pgp-compose-encrypted = { $count ->
    [1] 自分と{ $addresses }宛てに暗号化され、署名されます。
   *[other] 自分と{ $count }人の受信者宛てに暗号化され、署名されます。
}
# review: new
pgp-compose-encrypt-ready = 暗号化され、署名されます。キーを持っている受信者を追加してください。
# review: new
pgp-compose-missing = { $count ->
    [1] { $addresses }に使用できるキーがないため、まだメッセージを暗号化できません。
   *[other] { $count }人の受信者に使用できるキーがないため、まだメッセージを暗号化できません：{ $addresses }。
}
# review: new
pgp-compose-looking = { $addresses }のキーを検索しています...
# review: new
pgp-compose-signed = 署名されます。受信者は、署名された内容が変更されていないことを確認できます。あなたのキーの所有者についても、受信者が検証する必要があります。
# review: new
pgp-compose-reply-clear = 返信元または転送元のメッセージは暗号化されていましたが、このメッセージは暗号化されません。
# review: new
pgp-compose-encrypted-files = 暗号化されたメッセージのファイルが添付されているため、このメッセージは暗号化しないと送信できません。暗号化をオンにするか、それらのファイルを削除してください。
# review: new
pgp-compose-sign-tip = 受信者が内容を確認できるように、メッセージに署名します。あなたのキーの所有者についても、受信者が検証する必要があります
# review: new
pgp-compose-sign-tip-encrypted = 暗号化されたメッセージには常に署名されます
# review: new
pgp-compose-encrypt-tip = 自分と受信者だけが読めるように、メッセージを暗号化します
# review: new
pgp-compose-make-key = { $address }のキーはまだありません。今すぐ作成しますか？キーがあると、メッセージに署名して暗号化できます。
# review: new
pgp-compose-key-unusable = { $address }のキーは使用できません（{ $state }）。［暗号化キー］を開いて、バックアップをインポートするか、新しいキーを作成してください。
# review: new
pgp-compose-encrypt-off-quote = このメッセージには暗号化されたメールのテキスト、画像、添付ファイルが含まれています。暗号化しない場合、その内容をすべて削除するまで送信できません。それでも暗号化をオフにしますか？
# review: new
pgp-compose-encrypt-off-reply = このメッセージは、暗号化されたメッセージへの返信または転送です。暗号化しないと、途中でメッセージを扱う人なら誰でも読めるようになります。暗号化をオフにしますか？
# review: new
pgp-recipient-verified = キーは検証済み
# review: new
pgp-recipient-found = キーは未検証
# review: new
pgp-recipient-own = 自分のキー
# review: new
pgp-recipient-looking = キーを検索しています...
# review: new
pgp-recipient-missing = キーなし
# review: new
pgp-recipient-not-found = キーなし：{ $date }に検索しましたが、見つかりませんでした
# review: new
pgp-recipient-unusable = キーを使用できません：{ $state }
# review: new
pgp-recipients-intro = メッセージは、各受信者のキーと自分のキー宛てに暗号化されます。
# review: new
pgp-recipients-intro-missing = { $count ->
    [1] 1人の受信者に、使用できる暗号化キーがありません。キーを検索するか、その受信者をメッセージから削除してください。暗号化せずに送信できるのは、暗号化されたメールの内容をすべて削除した後だけです。
   *[other] { $count }人の受信者に、使用できる暗号化キーがありません。キーを検索するか、それらの受信者をメッセージから削除してください。暗号化せずに送信できるのは、暗号化されたメールの内容をすべて削除した後だけです。
}
# review: new
pgp-details-part = パート{ $number }：{ $label }
# review: new
attachment-from-part = パート{ $number }から：{ $label }
# review: new
pgp-details-signed = { $when }にキー{ $key }で署名
# review: new
pgp-details-unknown-key = お持ちでないキー{ $key }で署名
# review: new
pgp-details-opened = 自分のキー{ $key }で復号
# review: new
pgp-details-for = 暗号化先：{ $keys }
# review: new
pgp-details-plain = 署名も暗号化もされていません
# review: new
pgp-bar-parts = このメッセージには{ $count }個のパートがあります：{ $list }。各パートに、その保護の状態が表示されます。
# review: new
pgp-bar-count-verified = 検証済み{ $count }個
# review: new
pgp-bar-count-encrypted-signed = 暗号化と署名済み{ $count }個
# review: new
pgp-bar-count-encrypted = 暗号化済み{ $count }個
# review: new
pgp-bar-count-signed = 署名済み{ $count }個
# review: new
pgp-bar-count-warning = 要確認{ $count }個
# review: new
pgp-bar-count-neutral = 確認済みの署名なし{ $count }個
# review: new
setup-part-settings = 設定
# review: new
setup-part-preferences = ウィンドウの設定
# review: new
setup-part-accounts = アカウント
# review: new
setup-part-sign-in-apps = サインイン アプリ
# review: new
setup-part-contacts = 連絡先とグループ
# review: new
setup-part-keys = 暗号化キー
# review: new
setup-part-rules = メッセージ ルール
# review: new
setup-part-trusted-senders = 信頼できる送信者
# review: new
setup-holds-settings = 設定{ $count }件
# review: new
setup-holds-preferences = ウィンドウの設定{ $count }件
# review: new
setup-holds-accounts = アカウント{ $count }個
# review: new
setup-holds-sign-in-apps = サインイン アプリ{ $count }個
# review: new
setup-holds-built-in = 組み込みのサインイン アプリのオンとオフ
# review: new
setup-holds-contacts = 連絡先{ $count }件
# review: new
setup-holds-groups = グループ{ $count }個
# review: new
setup-holds-own-keys = 自分のキー{ $count }個
# review: new
setup-holds-contact-keys = 連絡先のキー{ $count }個
# review: new
setup-holds-rules = ルール{ $count }件
# review: new
setup-holds-trusted-senders = 信頼できる送信者{ $count }件
# review: new
setup-sign-in-password = パスワード
# review: new
setup-account-secret-password = パスワードはファイルに含まれています。
# review: new
setup-account-secret-token = 保存済みのサインイン資格情報はファイルに含まれています。
# review: new
setup-account-asks-password = インポート後にパスワードの入力を求められます。
# review: new
setup-account-signs-in-again = インポート後にもう一度サインインします。
# review: new
setup-account-here = すでにこのコンピューターに設定されているため、スキップされます。
# review: new
setup-account-no-app = このアカウントは{ $app }でサインインしますが、このアプリはこのコンピューターに設定されていません。サインイン アプリもインポートしてください。
# review: new
setup-invalid-address = 「{ $address }」はメール アドレスではありません。
# review: new
setup-invalid-server = { $server }の設定に、無効なサーバー名、ポート、またはセキュリティ オプションがあります。
# review: new
setup-invalid-user = ユーザー名がありません。
# review: new
setup-invalid-sign-in = サインインの方法または構成がサポートされていません。
# review: new
setup-error-empty = ファイルが空です。
# review: new
setup-error-too-large = 設定ファイルがサイズの上限を超えています。
# review: new
setup-error-not-setup = このファイルはInbox Classicの設定ファイルではありません。
# review: new
setup-error-damaged = 設定ファイルが破損しているため、読み取れません。
# review: new
setup-error-newer = この設定は、より新しいInbox Classic（{ $version }）で保存されています。Inbox Classicを更新してから、もう一度インポートしてください。
# review: new
setup-error-needs-passphrase = この設定はパスフレーズで保護されています。保存時に使用したパスフレーズを入力してください。
# review: new
setup-error-wrong-passphrase = この設定の保存時に使用されたパスフレーズではありません。
# review: new
setup-error-changed = 設定ファイルが整合性チェックに失敗しました。改ざんまたは破損している可能性があるため、インポートできません。
# review: new
setup-error-read = 設定ファイルを読み取れませんでした：{ $error }
# review: new
setup-error-write = 設定を保存できませんでした：{ $error }
# review: new
setup-error-no-parts = 1つ以上の項目を選択してください。
# review: new
setup-left-out = { $part }の{ $count }件の項目は使用できないため、除外されます。
# review: new
setup-imported-settings = 設定を置き換えました。
# review: new
setup-imported-preferences = ウィンドウの設定を置き換えました。
# review: new
setup-added-accounts = アカウントを{ $count }個追加しました。
# review: new
setup-skipped-here = { $address }はすでにこのコンピューターに設定されているため、スキップしました。
# review: new
setup-skipped-no-app = { $address }をスキップしました：{ $app }でサインインしますが、このアプリはこのコンピューターに設定されていません。
# review: new
setup-skipped-invalid = { $address }をスキップしました：{ $reason }
# review: new
setup-asks-password = { $address }は、接続時にパスワードの入力を求めます。
# review: new
setup-signs-in-again = { $address }は、接続時にもう一度サインインを求めます。
# review: new
setup-added-sign-in-apps = サインイン アプリを{ $count }個追加しました。
# review: new
setup-skipped-sign-in-apps = { $count }個のサインイン アプリは、すでにこのコンピューターに設定されています。
# review: new
setup-added-contacts = アドレス帳に連絡先を{ $count }件追加しました。
# review: new
setup-skipped-contacts = { $count }件の連絡先は、すでにアドレス帳にあります。
# review: new
setup-added-groups = グループを{ $count }個追加または補完しました。
# review: new
setup-added-own-keys = 自分のキーを{ $count }個追加しました。
# review: new
setup-added-contact-keys = 連絡先のキーを{ $count }個追加しました。
# review: new
setup-added-rules = メッセージ ルールを{ $count }件追加しました。
# review: new
setup-skipped-rules = { $count }件のメッセージ ルールは、すでにこのコンピューターにあります。
# review: new
setup-skipped-rules-account = { $count }件のメッセージ ルールは、このコンピューターにないアカウント用のため、スキップしました。
# review: new
setup-rules-waiting = { $count }件のメッセージ ルールは、アカウントの同期中に移動先のフォルダーが見つかるのを待っています。
# review: new
setup-added-trusted-senders = 信頼できる送信者を{ $count }件追加しました。
# review: new
setup-nothing = 何もインポートされませんでした。
# review: new
setup-account-servers = { $imap }と{ $smtp }（{ $signin }）
# review: new
setup-file-name = Inbox Classicの設定とアカウント
# review: new
setup-skipped-unreachable = { $name }をスキップしました：サインイン サービスに接続できなかったか、確認できませんでした。もう一度試す前に、サインイン アプリで必要なアプリを確認してください。
# review: new
attachment-runs-programs = 「{ $name }」はプログラムを実行できるため、Inbox Classicでは開きません。保存してから、入手元が信頼できる場合はご自身で開いてください。
# review: new
attachment-decrypted-note = この添付ファイルは暗号化されたメールのものです。別のアプリで開くため、Inbox Classicはユーザー アカウント用の一時フォルダーに、暗号化されていないコピーを保存します。起動時に、1日以上前のコピーの削除を試みます。
# review: new
undone-move = { $count ->
   *[other] サーバーが{ $messages }を{ $folder }に移動しなかったため、{ $from }に戻しました：{ $reason }
}
# review: new
undone-delete = { $count ->
   *[other] サーバーが{ $messages }を削除しなかったため、{ $from }に戻しました：{ $reason }
}
# review: new
undone-archive = { $count ->
   *[other] サーバーが{ $messages }をアーカイブしなかったため、{ $from }に戻しました：{ $reason }
}
# review: new
undone-read = { $count ->
   *[other] サーバーが{ $messages }を既読にしなかったため、未読に戻しました：{ $reason }
}
# review: new
undone-unread = { $count ->
   *[other] サーバーが{ $messages }を未読にしなかったため、既読に戻しました：{ $reason }
}
# review: new
undone-flags = { $count ->
   *[other] サーバーが{ $messages }のフラグを変更しなかったため、元の状態に戻しました：{ $reason }
}

## Previews of attachments: the pictures and PDF files shown in a message

# review: new
preview-pdf-option = PDFファイルをメッセージ内に表示する
# review: new
preview-pdf-off = PDFファイルはメッセージ内に表示されません。
# review: new
preview-pdf-off-crashed = メッセージ内のファイルの表示中にInbox Classicが終了したため、PDFファイルはメッセージ内に表示されなくなりました。画像は引き続き表示されます。PDFファイルをもう一度表示するには、{ $settings }で「{ $option }」をオンにしてください。
# review: new
preview-pdf-details = { $count }ページ、{ $size }
# review: new
preview-page-alt = { $name }、{ $page }/{ $count }ページ
# review: new
preview-more-pages = { $count ->
    [1] 開くとページを表示できます
   *[other] 開くと全{ $count }ページを表示できます
}
# review: new
preview-more-files = ほかに{ $count }個のファイルが上の一覧にあります
# review: new
preview-tile-downloading = ダウンロードしています…
# review: new
preview-tile-preparing = 準備しています…
# review: new
preview-tile-format = { $format }画像はまだ表示できません
# review: new
preview-tile-password = パスワードで保護されています。開いてパスワードを入力してください
# review: new
preview-tile-too-large = 大きすぎて表示できません
# review: new
preview-tile-unreadable = 表示できません
# review: new
preview-tile-timed-out = プレビューの準備に時間がかかりすぎました
# review: new
preview-tile-crashed = プレビューを利用できません。以前の試行が中断されました
# review: new
preview-tile-off = Inbox Classicを再起動するまで表示されません
# review: new
preview-not-printed = { $name }（{ $details }）は印刷されません。印刷するには開いてください。
