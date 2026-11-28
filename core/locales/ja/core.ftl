# 日本語。ネイティブ スピーカーによるレビュー待ちの下書きです。

## Counts and sizes

messages = { $count }件のメッセージ
decimal-separator = .
list-separator = 、
size-bytes = { $count }バイト
size-kb = { $size } KB
size-mb = { $size } MB
size-gb = { $size } GB
send-delay-off = オフ
send-delay-seconds = { $count }秒
list-counts = { $messages }、未読{ $unread }件
list-counts-selected = { $messages }、未読{ $unread }件、{ $selected }件を選択中
list-counts-found = 検索結果{ $found }件、未読{ $unread }件
list-counts-found-selected = 検索結果{ $found }件、未読{ $unread }件、{ $selected }件を選択中
list-counts-none = メッセージが見つかりません

## Special folders, as Outlook Express names them

folder-inbox = 受信トレイ
folder-sent = 送信済みアイテム
folder-deleted = 削除済みアイテム
folder-drafts = 下書き
folder-junk = 迷惑メール
folder-archive = アーカイブ

## The reading pane

reader-no-message = メッセージが選択されていません。
reader-downloading = メッセージをダウンロードしています…
reader-downloading-detail = ダウンロードが完了すると、ここにメッセージが表示されます。
reader-downloading-size = このメッセージのサイズは{ $size }です。ダウンロードが完了すると、ここに表示されます。
reader-failed = メッセージをダウンロードできませんでした
reader-failed-network = メール サーバーに接続できなかったか、接続が中断されました（{ $reason }）。
reader-failed-security = メール サーバーとの接続を保護できませんでした（{ $reason }）。
reader-failed-other = メール サーバーの応答：{ $reason }。
reader-retry-note = アカウントが再接続されたときに、もう一度試します。
reader-unreadable = このメッセージを表示できません：{ $error }
message-source-title = メッセージのソース：{ $subject }
message-source-untitled = メッセージのソース

## Printing a message, and the header of a message quoted in a reply or forward

header-from = 差出人
header-date = 日付
header-to = 宛先
header-cc = CC
header-sent = 送信日時
header-subject = 件名
header-security = セキュリティ
header-part = パート{ $number }
quote-original = ----- 元のメッセージ -----
fold-show-earlier = 以前のメッセージを表示

## Bounces: the card at the top of a notice that a message was not delivered

bounce-failed = メッセージは配信されませんでした
bounce-delayed = メッセージはまだ配信されていません
bounce-delayed-note = メール サーバーが配信を試み続けています。もう一度送信する必要はありません。
bounce-show-message = 配信されなかったメッセージを表示
bounce-show-delayed = 遅延しているメッセージを表示
bounce-what-to-do = 対処方法：
bounce-delayed-do = 今は何もする必要はありません。最終的に配信できなかった場合は、改めて通知が届きます。
bounce-delayed-row-do = 今は何もする必要はありません。メール サーバーが配信を試み続けており、配信できなかった場合は改めて通知が届きます。
bounce-details = 詳細
bounce-someone = 受信者
bounce-server = サーバー：{ $server }
bounce-status = ステータス：{ $status }
bounce-reported-by = 報告元：{ $server }
bounce-retry-minutes = 受信側のサーバーから、次の試行まで{ $count }分待つよう求められました。
bounce-retry-hours = 受信側のサーバーから、次の試行まで{ $count }時間待つよう求められました。
bounce-blocklist = ブロックリスト：{ $lists }
bounce-user-unknown = アドレスが存在しません
bounce-user-unknown-why = 受信側のサーバーに、このアドレスのメールボックスがありません。アドレスが間違っているか、相手がそのアドレスを使わなくなった可能性があります。
bounce-user-unknown-do = アドレスのつづりを確認するか、相手に現在使っているアドレスを尋ねてください。
bounce-invalid-address = アドレスが正しくありません
bounce-invalid-address-why = アドレスが、メールを送信できる形式で書かれていません。
bounce-invalid-address-do = スペースが入っている、文字が抜けている、@の後に何もないなどの入力ミスがないか確認してください。
bounce-mailbox-disabled = メールボックスが閉鎖されています
bounce-mailbox-disabled-why = アドレスは存在しますが、そのメールボックスは無効にされているか、使われなくなっています。
bounce-mailbox-disabled-do = 別の方法で相手に連絡し、現在使っているアドレスを尋ねてください。
bounce-mailbox-full = メールボックスがいっぱいです
bounce-mailbox-full-why = 受信者のメールボックスに、新しいメールを受け取る空きがありません。
bounce-mailbox-full-do = 数日後にもう一度送信するか、別の方法で相手に知らせてください。
bounce-spam-blocked = スパムとして拒否されました
bounce-spam-blocked-why = 受信側のサーバーが、このメッセージをスパムと判断しました。
bounce-spam-blocked-do = 多数のリンク、短縮URL、大きな添付ファイルなど、スパムに見える要素を除いてもう一度送信してください。何度も起こる場合は、メール プロバイダーに問い合わせてください。
bounce-virus-detected = ウイルスのため拒否されました
bounce-virus-detected-why = 受信側のサーバーから、メッセージまたは添付ファイルにウイルスなどの有害な内容が含まれていると報告されました。
bounce-virus-detected-do = ウイルス スキャナーで添付ファイルを確認してください。プログラムや圧縮ファイルをすべて拒否するサーバーもあるため、そのようなファイルはリンクで共有してください。
bounce-ip-blocklisted = お使いのメール サーバーがブロックリストに登録されています
bounce-ip-blocklisted-why = お使いのメールを送信したサーバーのアドレスがブロックリストに登録されているため、受信側のサーバーがそのサーバーからのメールを拒否しています。
bounce-ip-blocklisted-do = メッセージに問題はありません。この通知をメール プロバイダーに転送し、サーバーをリストから削除してもらうよう依頼してください。
bounce-domain-blocklisted = ドメインがブロックリストに登録されています
bounce-domain-blocklisted-why = お使いのアドレスのドメイン、またはメッセージ内のリンクのドメインがブロックリストに登録されているため、受信側のサーバーがメッセージを拒否しました。
bounce-domain-blocklisted-do = メッセージにリンクが含まれている場合は、リンクなしで送信してみてください。含まれていない場合は、ドメインのメールを管理している担当者にこの通知を転送してください。
bounce-policy-blocked = 受信側のサーバーのルールによって拒否されました
bounce-policy-blocked-why = 受信側のサーバーのルールにより、このメッセージは受け付けられません。サイズ、添付ファイル、差出人などが理由として考えられます。
bounce-policy-blocked-do = 多くの場合、［詳細］にあるサーバー自身のメッセージに理由が書かれています。このようなメールを受け取れるかどうか、受信者に確認してください。
bounce-geo-blocked = 送信元の地域のため拒否されました
bounce-geo-blocked-why = 受信側のサーバーは、お使いのメール サーバーがある国またはネットワークからのメールを受け付けていません。
bounce-geo-blocked-do = 別の方法で相手に連絡するか、メール プロバイダーに問い合わせてください。
bounce-relay-denied = サーバーが転送を拒否しました
bounce-relay-denied-why = あるサーバーがメッセージの転送を拒否しました。多くの場合、サインインせずに送信したか、この受信者を扱わないサーバーを経由して送信したことが原因です。
bounce-relay-denied-do = アカウントの設定で、送信サーバーとサインイン情報を確認してください。
bounce-auth-failure = 差出人のアドレスを確認できませんでした
bounce-auth-failure-why = 受信側のサーバーは、メッセージが本当にお使いのドメインから送信されたことを確認できませんでした（SPF、DKIM、DMARC）。
bounce-auth-failure-do = ドメインのメールを管理している担当者にこの通知を転送してください。ドメインの設定を修正する必要があります。それまでは、プロバイダー自身のサーバーから送信すると解決する場合があります。
bounce-rate-limited = 一度に送信したメールが多すぎます
bounce-rate-limited-why = 受信側のサーバーは現在、お使いのメール サーバーから受け付けるメッセージの数を制限しています。
bounce-rate-limited-do = しばらく待ってから、もう一度送信してください。多くの人に送信する場合は、一度に送る人数を減らしてください。
bounce-greylisting = 一時的に保留されました
bounce-greylisting-why = 受信側のサーバーは、不明な送信者に少し後で再送するよう求めています。これはスパム対策としてよく行われる確認です。
bounce-greylisting-do = 一時的な遅延であれば、通常は送信側のサーバーが再試行します。この通知が最終的な失敗を報告している場合は、後でもう一度メッセージを送信してみてください。
bounce-server-error = 受信側のサーバーで問題が発生しました
bounce-server-error-why = 受信側のサーバーに接続できなかったか、サーバー自身の問題でメッセージを受け取れませんでした。
bounce-server-error-do = 後でもう一度送信してください。何度も失敗する場合は、アドレスの@より後の部分に入力ミスがないか確認してください。
bounce-unknown = 配信されませんでした
bounce-unknown-why = 通知には理由がはっきり書かれていません。
bounce-unknown-do = ［詳細］にあるサーバー自身のメッセージで、さらに詳しくわかる場合があります。それでもわからない場合は、この通知をメール プロバイダーに転送してください。

## Several messages selected

selection-title = { $count }件のメッセージを選択中
selection-unread = 未読{ $count }件
selection-flagged = フラグ付き{ $count }件
delete-for-good-one = このメッセージは完全に削除されます。削除しますか？
delete-for-good-all = これらの{ $count }件のメッセージは完全に削除されます。削除しますか？
delete-for-good-some = { $total }件のメッセージのうち{ $count }件が完全に削除されます。メッセージを削除しますか？
done-read = { $count ->
   *[other] { $messages }を既読にしました
}
done-unread = { $count ->
   *[other] { $messages }を未読にしました
}
done-flagged = { $count ->
   *[other] { $messages }にフラグを設定しました
}
done-unflagged = { $messages }のフラグをクリアしました
done-deleted-for-good = { $count ->
   *[other] { $messages }を完全に削除しました
}
done-archived = { $count ->
   *[other] { $messages }をアーカイブしました
}
done-moved = { $count ->
   *[other] { $messages }を{ $folder }に移動しました
}
done-copied = { $count ->
   *[other] { $messages }を{ $folder }にコピーしました
}
done-moving = { $count ->
   *[other] { $messages }を{ $folder }に移動しています...
}
done-copying = { $count ->
   *[other] { $messages }を{ $folder }にコピーしています...
}
done-moved-back = { $count ->
   *[other] { $messages }を{ $folder }に戻しました
}
done-watched = { $count ->
    [1] スレッドをウォッチしています
   *[other] { $count }件のスレッドをウォッチしています
}
done-unwatched = { $count ->
    [1] スレッドのウォッチを停止しました
   *[other] { $count }件のスレッドのウォッチを停止しました
}
done-ignored = { $count ->
    [1] スレッドを無視しています
   *[other] { $count }件のスレッドを無視しています
}
done-unignored = { $count ->
    [1] スレッドの無視を解除しました
   *[other] { $count }件のスレッドの無視を解除しました
}
their-folders = 元のフォルダー
undo-move = 移動を元に戻す
undo-delete = 削除を元に戻す
undo-archive = アーカイブを元に戻す
undo-junk = 「迷惑メールとしてマーク」を元に戻す
undo-not-junk = 「迷惑メールではないとしてマーク」を元に戻す
undo-send = 送信を元に戻す
nothing-to-undo = 元に戻す操作はありません。
messages-gone = メッセージはもう存在しません。
folder-holds-no-messages = このフォルダーにはメッセージを保存できません。
not-archived-here = このフォルダーのメッセージはアーカイブできません。
not-emptied-here = 空にできるのは、削除済みアイテムと迷惑メールだけです。
next-unread-question = { $folder }に未読メッセージはもうありません。

    未読メッセージがある次のフォルダー「{ $next }」に移動しますか？
no-unread-left = 未読メッセージはもうありません。
empty-question = { $count ->
   *[other] { $folder }を空にしますか？

        中にある{ $messages }は完全に削除されます。元に戻すことはできません。
}
no-junk-folder = このアカウントには、メッセージの移動先となる迷惑メール フォルダーがありません。
no-inbox-folder = このアカウントには、メッセージの移動先となる受信トレイがありません。
done-flagged-color = { $messages }に{ $color ->
    [red] 赤
    [orange] オレンジ
    [yellow] 黄
    [green] 緑
    [blue] 青
    [purple] 紫
   *[gray] 灰色
}のフラグを設定しました
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

move-window-title-move = { $count ->
    [1] メッセージの移動
   *[other] { $count }件のメッセージの移動
}
move-window-title-copy = { $count ->
    [1] メッセージのコピー
   *[other] { $count }件のメッセージのコピー
}
move-window-prompt-move = { $count ->
    [1] 選択したメッセージの移動先:
   *[other] 選択した{ $count }件のメッセージの移動先:
}
move-window-prompt-copy = { $count ->
    [1] 選択したメッセージのコピー先:
   *[other] 選択した{ $count }件のメッセージのコピー先:
}
targets-recent = 最近使用したフォルダー
target-current = { $folder }（現在のフォルダー）
target-recent = { $folder }（{ $account }）

## Moving and copying to another account

transfer-moving = { $messages }のうち{ $done }件を{ $folder }に移動しています...
transfer-copying = { $messages }のうち{ $done }件を{ $folder }にコピーしています...
transfer-another-account = 別のアカウント
transfer-folder-gone = 移動先のフォルダーはもう存在しません
transfer-not-on-server = メッセージはもうサーバー上にありません
transfer-not-moved = { $count ->
   *[other] { $messages }を別のアカウントに移動できませんでした：{ $reason }
}
transfer-not-copied = { $count ->
   *[other] { $messages }を別のアカウントにコピーできませんでした：{ $reason }
}
transfer-none-moved = メッセージを移動できませんでした
transfer-none-copied = メッセージをコピーできませんでした

## Messages as files

export-not-in-time = メッセージを時間内にダウンロードできませんでした
export-not-saved = { $messages }のうち{ $failed }件を保存できませんでした（{ $problems }）
export-not-attached = メッセージを添付できませんでした：{ $error }
saved-to = { $count ->
   *[other] { $messages }を{ $folder }に保存しました
}
download-progress = { $total }中{ $done }をダウンロードしています
download-done = { $size }をダウンロードしました
downloading-messages = { $count ->
   *[other] { $messages }をダウンロードしています...
}
import-put = { $count ->
   *[other] { $messages }を{ $folder }へのインポート待ちに追加しました
}
import-not-put = 次のファイルはフォルダーに追加されませんでした：

    { $problems }

## Problems the windows show

error-store = ローカル ストア：{ $error }
error-not-found = 見つかりません
error-closed = 終了処理中です
error-other-account = ブラウザーでサインインしたのは{ $email }で、このアカウントではありません
failure-authentication = サーバーがサインインを受け付けませんでした（{ $reason }）
failure-network = サーバーへの接続に失敗しました（{ $reason }）
error-in-use = このアプリでサインインしているアカウントがあるため、削除できません：{ $accounts }
error-turned-off = このサインイン アプリは、新しいアカウントに対してオフになっています
error-folder-name = フォルダー名は1～200文字で指定し、制御文字を含めることはできません
error-folder-separator = このサーバーでは、フォルダー名に「{ $separator }」を使用できません
error-folder-special = 受信トレイと特別なフォルダーは、名前の変更も削除もできません
error-no-recipients = メッセージに受信者がありません
error-bad-address = 「{ $address }」はメール アドレスではありません
error-not-own-address = { $address }は、このアカウントの差出人アドレスではありません。アカウントのプロパティの「送信に使うその他のアドレス」に追加してください。
rule-query-refused = ルールでは、フォルダーや日付で絞り込むことはできません（{ $words }）。
rule-no-query = 受信メッセージの検索条件を入力してください。
rule-no-action = ルールの処理を1つ以上選択してください。
error-attachment = { $path }を読み取れませんでした：{ $error }
error-no-drafts = このアカウントには、メッセージを保存する下書きフォルダーがありません
error-draft-attachment = 下書きの添付ファイルを保持できませんでした：{ $error }
error-password-not-saved = 次回の起動用にパスワードを保存できませんでした：{ $error }
error-sign-in-not-saved = 次回の起動用に新しいサインイン情報を保存できませんでした：{ $error }
error-import-unreadable = { $path }を読み取れません：{ $error }
error-import-too-large = { $path }は50 MBを超えています
error-import-not-mail = { $path }はメール メッセージではありません
error-list-answered = メーリング リストのサーバーからステータス{ $status }が返されました
error-not-built = メッセージを作成できませんでした
error-outbox-waits = { $count }件のメッセージが送信トレイに残っています。次回の送受信で、もう一度送信を試みます
error-draft-not-removed = メッセージの以前の下書きを下書きフォルダーから削除できませんでした：{ $reason }
error-sent-but = メッセージは送信されましたが、{ $problem }
error-sent-still-in-outbox = 送信トレイに残っています：{ $error }
error-sent-no-copy = 送信済みアイテムにコピーを保存できませんでした：{ $reason }
error-no-password = このアカウントのパスワードがありません
error-no-sign-in = このアカウントのサインイン情報がありません
error-provider-missing = このビルドでは、このサインイン アプリを使用できません（ID：{ $provider }）。削除された可能性があります
error-provider-servers = このアカウントのサーバーが、サインイン アプリのサーバーと一致しません
error-app-scopes = { $reason }。メール サーバーがサインイン アプリのトークンを受け付けませんでした。アプリのスコープでメールへのアクセスが許可されているか確認してください
error-in-folder = { $folder }：{ $reason }

## Sign-in apps

sign-in-off-google = 組み込みのGoogleサインイン アプリは承認されたテスト ユーザー向けに設定されており、既定では新しいアカウントに対してオフになっています。テスト ユーザーは、サインイン アプリ（ファイル > アカウント）でオンにできます。独自のGoogleサインイン アプリや、アカウントが対応していればアプリ パスワードを使用することもできます。
sign-in-off-other = 新しいアカウントに対してオフになっています。サインイン アプリ（ファイル > アカウント）でオンにできます。
sign-in-app-no-name = サインイン アプリに名前が必要です
sign-in-app-no-client = クライアントIDがありません
sign-in-app-no-scopes = サインイン アプリに、メールへのアクセスを許可するスコープが必要です
sign-in-app-bad-host = { $server }サーバーのアドレスがないか、有効なホスト名ではありません
sign-in-app-plain = { $server }サーバーでは、SSL/TLSまたはSTARTTLSを使用する必要があります
sign-in-app-not-checked = 発行者がまだ確認されていません
sign-in-app-issuer-changed = 発行者が変更されました。クライアント シークレットをもう一度入力するか、削除してください
sign-in-register-google = Google Cloud Consoleで、種類が「デスクトップ アプリ」のOAuthクライアントを作成し、その同意画面にスコープ「https://mail.google.com/」を追加します。アプリがテスト中の間は、そのテスト ユーザーだけがサインインできます。
sign-in-register-microsoft = Microsoft Entraで、プラットフォーム「モバイル アプリケーションとデスクトップ アプリケーション」、リダイレクトURI「http://localhost」、パブリック クライアント フローの許可、委任されたアクセス許可IMAP.AccessAsUser.All、SMTP.Send、offline_accessを設定してアプリを登録します。自分の組織だけで使う場合は、発行者として「https://login.microsoftonline.com/<テナントID>/v2.0」を使用します。
sign-in-register-other = 下記のリダイレクトURIで、ネイティブ（パブリック）クライアントを登録します。プロバイダーは、このURIで任意のポートを許可する必要があります（RFC 8252）。プロバイダーがメールへのアクセスに使うスコープを追加してください。

## Calendar invitations

repeats = 繰り返し
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
repeats-on = { $repeats }（{ $days }）
repeats-times = { $repeats }、{ $count }回
day-monday = 月曜日
day-tuesday = 火曜日
day-wednesday = 水曜日
day-thursday = 木曜日
day-friday = 金曜日
day-saturday = 土曜日
day-sunday = 日曜日

## AI agents

agent-level-read = メールの読み取り：フォルダー、メッセージ一覧、スレッド、検索、メッセージとそのファイル、メッセージ ルール、メールを送ったことのある相手
agent-level-organize = メールの整理：既読と未読、フラグとその色、迷惑メール、移動、アーカイブ、フォルダーの作成と名前の変更、スレッドのウォッチと無視、削除済みアイテムへの削除、承認後のメーリング リストの配信停止
agent-level-drafts = 下書きの作成（送信はご自身で行います）
agent-level-send = メールの送信（メッセージごとに承認が必要）
agent-connect-title = { $program }がメールの使用を求めています
agent-connect-detail = AIエージェントがInbox Classicとの連携を求めています。許可する操作と、参照できるアカウントを選択してください。この設定は後で［ツール］>［AIエージェント］で変更できます。

    エージェントはほかの人が書いたメールを読むため、メッセージによってエージェントがだまされる可能性があります。エージェントが何かを送信する前に、Inbox Classicは必ず確認を求めます。
agent-reply-to = 「{ $subject }」への返信
agent-reply-all-on = 「{ $subject }」への全員へ返信
agent-forward-of = 「{ $subject }」の転送
agent-never-written-one = { $address }にメールを送ったことはありません。
agent-never-written-many = これらのアドレスのうち{ $count }件には、メールを送ったことがありません。
agent-send-title = { $program }がこのメッセージの送信を求めています
agent-send-detail = 受信者とメッセージの内容を確認してください。確定すると、メッセージは送信トレイで{ $seconds }秒間待機します。その間は削除できます。
agent-change-title = { $program }に許可する操作
agent-change-allowed = このプログラムのAIエージェントがメールに対して行える操作を変更します。
agent-change-refused = このプログラムのアクセスを拒否しています。エージェントにもう一度メールへのアクセスを与えるには、許可してください。
agent-log-taken-back = { $entry }（取り消し済み）
agent-files = ファイル：{ $files }
agent-undo-refused = 取り消すことはできません。
agent-undo-refused-why = 取り消すことはできません：{ $reason }。
agent-undo-impossible = この操作は取り消せません
agent-undo-not-in-folder = メッセージはもうそのフォルダーにありません
agent-undo-not-arrived = メッセージが移動先のフォルダーに（まだ）ありません
agent-undo-sent = メッセージはもう送信トレイにありません
agent-original-not-downloaded = 元のメッセージがまだダウンロードされていません。先に開いてください
agent-turned-away = 拒否済み
agent-can-nothing = なし
agent-can-read = 読み取り
agent-can-organize = 整理
agent-can-drafts = 下書きの作成
agent-can-send = 承認後の送信
agent-can-list = { $first }、{ $last }
agent-accounts = { $count ->
    [0] アカウントなし
   *[other] { $count }個のアカウント
}
agent-access = { $can }（{ $accounts }）
agent-unreadable = このメッセージは読み取れません。
agent-encrypted-original = このメッセージは暗号化されています。エージェントは暗号化を行えないため、このメッセージに返信したり転送したりすることはできません。
agent-encrypted = このメッセージは暗号化されています。AIエージェントはその内容を読み取れません。ご自身で読むには、Inbox Classicで開いてください。
agent-too-many-changes = 過去30日間の変更が多すぎます。このエージェントは、Inbox Classicが1つのプログラムについてログに記録できる上限まで変更を行いました。最も古い変更から30日が経つと、さらに変更できるようになります。
agent-too-many-reads = 過去30日間の読み取りが多すぎます。このエージェントは、Inbox Classicが1つのプログラムについてログに記録できる上限まで読み取りを行いました。最も古い読み取りから30日が経つと、さらに読み取れるようになります。
list-encrypted = 暗号化されたメッセージ
agent-log-composed = 「{ $subject }」を新しいメッセージで開きました（仕上げはご自身で行います）
agent-log-refused = 「{ $subject }」を送信しませんでした
agent-log-sent = { $to }宛ての「{ $subject }」を送信トレイに追加しました
agent-log-draft = 下書き「{ $subject }」を保存しました
agent-log-draft-replaced = 下書き「{ $subject }」を置き換えました
agent-log-draft-discarded = 下書き「{ $subject }」の削除をリクエストしました
agent-draft-note = この下書きは、AIエージェントの{ $program }が作成しました。送信する前に、受信者と本文を確認してください。
agent-log-read = 「{ $subject }」を既読にしました
agent-log-unread = 「{ $subject }」を未読にしました
agent-log-flagged = 「{ $subject }」にフラグを設定しました
agent-log-unflagged = 「{ $subject }」のフラグをクリアしました
agent-log-deleted = 「{ $subject }」を削除しました
agent-log-moved = 「{ $subject }」を{ $folder }に移動しました
agent-log-junk = 「{ $subject }」を迷惑メールとしてマークしました
agent-log-not-junk = 「{ $subject }」を迷惑メールではないとしてマークしました
agent-log-archived = 「{ $subject }」をアーカイブしました
agent-log-folder = フォルダー「{ $name }」の作成をリクエストしました
agent-log-unsubscribed = メッセージ「{ $subject }」のリストの配信停止を承認しました
agent-log-unsubscribe-failed = メッセージ「{ $subject }」のリストの配信を停止できませんでした：{ $reason }
agent-log-unsubscribe-refused = { $senders }の配信停止のリクエストを承認しませんでした
agent-unsubscribe-title = { $count ->
    [1] { $program }がメーリング リストの配信停止を求めています
   *[other] { $program }が{ $count }件のメーリング リストの配信停止を求めています
}
agent-unsubscribe-detail = { $count ->
    [1] Inbox Classicは、下記のリストが提供するワンクリック方式で、配信の停止をリストに依頼します。それ以外には何も送信されず、お手元のメッセージもそのまま残ります。
   *[other] Inbox Classicは、下記の各リストが提供するワンクリック方式で、配信の停止を各リストに依頼します。それ以外には何も送信されず、お手元のメッセージもそのまま残ります。
}
agent-log-flag-color = 「{ $subject }」に{ $color ->
    [red] 赤
    [orange] オレンジ
    [yellow] 黄
    [green] 緑
    [blue] 青
    [purple] 紫
   *[gray] 灰色
}のフラグを設定しました
agent-log-renamed = フォルダー「{ $old }」の名前を「{ $name }」に変更するようリクエストしました
agent-log-watched = スレッド「{ $subject }」をウォッチしました
agent-log-ignored = スレッド「{ $subject }」を無視しました
agent-log-unmarked = スレッド「{ $subject }」のウォッチまたは無視を解除しました
agent-undo-changed = その後、メッセージが変更されました
agent-log-bulk-read = { $count }件のメッセージを既読にしました（検索：{ $query }）
agent-log-bulk-unread = { $count }件のメッセージを未読にしました（検索：{ $query }）
agent-log-bulk-flagged = { $count }件のメッセージにフラグを設定しました（検索：{ $query }）
agent-log-bulk-unflagged = { $count }件のメッセージのフラグをクリアしました（検索：{ $query }）
agent-log-bulk-color = { $count }件のメッセージに{ $color ->
    [red] 赤
    [orange] オレンジ
    [yellow] 黄
    [green] 緑
    [blue] 青
    [purple] 紫
   *[gray] 灰色
}のフラグを設定しました（検索：{ $query }）
agent-log-bulk-moved = { $count }件のメッセージを{ $folder }に移動しました（検索：{ $query }）
agent-log-bulk-archived = { $count }件のメッセージをアーカイブしました（検索：{ $query }）
agent-log-bulk-junk = { $count }件のメッセージを迷惑メールとしてマークしました（検索：{ $query }）
agent-log-bulk-not-junk = { $count }件のメッセージを迷惑メールではないとしてマークしました（検索：{ $query }）
agent-log-bulk-deleted = { $count }件のメッセージを削除しました（検索：{ $query }）
agent-undo-span = { $span ->
    [quarter] 過去15分間
    [hour] 過去1時間
    [hours] 過去4時間
    [day] 過去24時間
    [week] 過去7日間
   *[all] 過去30日間
}
agent-undo-since-question = { $count ->
    [0] この期間に、{ $program }について取り消せる変更はありません。
    [1] この期間に{ $program }について記録された変更の取り消しを試みますか？
   *[other] この期間に{ $program }について記録された{ $count }件の変更の取り消しを試みますか？
}
agent-undo-since-detail = Inbox Classicは、フォルダー、既読と未読の状態、フラグを元に戻し、送信トレイで待機中のメッセージを削除しようとします。すでに元に戻せない変更はスキップされます。その後に行われたフラグの色の変更が上書きされる場合があります。
agent-undo-done = { $count ->
    [0] 何も取り消されませんでした。
   *[other] 記録された{ $count }件の変更を、全部または一部取り消しました。
}
agent-undo-left-gone = { $count }件のメッセージは、変更によって移動された場所にありませんでした。
agent-undo-left-changed = { $count }件のメッセージは、その後ご自身またはサーバー上で変更されていたため、そのままにしました。
agent-undo-left-sent = { $count }件のメッセージは、すでに送信トレイからなくなっていました。
agent-undo-left-impossible = { $count }件の変更は取り消せません。
agent-invitation-reply = { $response ->
    [accept] このメッセージで、招待「{ $summary }」（{ $when }）を承諾します。
    [tentative] このメッセージで、招待「{ $summary }」（{ $when }）を仮承諾します。
   *[decline] このメッセージで、招待「{ $summary }」（{ $when }）を辞退します。
}メッセージは、招待に記載されている開催者に送信されます。メール サーバーがメッセージを受け付けた時点で、開催者の予定表での確認を待たずに、このコンピューター上の返答が変わります。
invitation-reply-subject = { $response ->
    [accept] 承諾: { $summary }
    [tentative] 仮承諾: { $summary }
   *[decline] 辞退: { $summary }
}
invitation-reply-text = { $response ->
    [accept] { $name }がこの招待を承諾しました。
    [tentative] { $name }がこの招待を仮承諾しました。
   *[decline] { $name }がこの招待を辞退しました。
}
agent-reads-messages = { $count }件のメッセージの読み取り
agent-reads-attachments = { $count }件の添付ファイルの要求
agent-reads-searches = { $count }回の検索
agent-reads-lists = { $count }回のメッセージ一覧の表示
agent-read-message = 「{ $subject }」を読み取りました
agent-read-conversation = スレッド「{ $subject }」を読み取りました（{ $count }件のメッセージ）
agent-read-attachment = 「{ $subject }」の添付ファイル「{ $name }」をリクエストしました
agent-read-search = 「{ $query }」を検索しました：{ $count }件のメッセージ
agent-read-people = 名前またはアドレスで連絡先を検索しました：「{ $query }」
agent-read-list = 一覧の{ $count }件の項目を表示しました（範囲：{ $folder }）
agent-read-changes = { $count }件の新着メッセージの詳細を表示しました
agent-terminal-programs-mac = { $terminal }から起動されたプログラム
agent-terminal-programs-windows = ターミナル（{ $terminal }）から起動されたプログラム
agent-terminal-programs-linux = ターミナル（{ $terminal }）から起動されたプログラム
agent-terminal-program-mac = { $terminal }から起動されたプログラム
agent-terminal-program-windows = ターミナル（{ $terminal }）から起動されたプログラム
agent-terminal-program-linux = ターミナル（{ $terminal }）から起動されたプログラム
agent-connect-title-terminal = { $programs }がメールの使用を求めています
agent-connect-terminal-detail = 同じ認識済みのターミナル プログラムから起動されたAIエージェントは、ここで許可するアクセスを共有します。個別のアクセスを与えるには、エージェントのMCP設定で、その引数に --name と任意の名前を追加してください。この名前で本人確認が行われるわけではありません。
agent-connect-claimed = このプログラムは{ $claimed }であると名乗りました。Inbox Classicが確認した起動元のプログラム：{ $program }。

## Keys as the keyboards of the language name them, in the help (Windows and Linux)

key-ctrl = Ctrl
key-alt = Alt
key-shift = Shift
key-del = Del
key-enter = Enter

## Signing in and passwords

sign-in-no-refresh = プロバイダーから更新トークンが返されませんでした
sign-in-no-account = どのアカウントでサインインしたのか、プロバイダーから返されませんでした
sign-in-not-finished = サインインが完了していません
secrets-unavailable = { $store }を使用できません
secrets-unavailable-why = { $store }を使用できません：{ $error }
secrets-windows = 資格情報マネージャー
secrets-mac = キーチェーン
secrets-linux = システムのキーリング（Secret Service）
error-no-such-file = そのようなファイルはありません
cards-file-too-big = このファイルは、アドレス帳のインポートのサイズ上限を超えています。
ui-sender-added = { $name }をアドレス帳に追加しました。
ui-sender-known = { $name }はすでにアドレス帳にあります。
ui-sender-none = このメッセージの送信者には、追加できるメール アドレスがありません。
card-name-needed = 連絡先に名前もメール アドレスもありません。
cards-file-failed = { $file }：{ $reason }

## One-time codes: the card at the top of a message with a sign-in or verification code

otp-heading = { $domain }からのコード
otp-copy = コピー
otp-note = このコードは{ $domain }のページでのみ入力してください。
otp-old = このコードは開く1時間以上前に送信されたため、有効期限が切れている可能性があります。

event-attendees = 出席者{ $count }人

otp-notification = { $domain }のコード：{ $code }

## OpenPGP keys (keys.rs)
pgp-key-valid = 有効
pgp-key-expires = { $date }まで有効
pgp-key-expired = { $date }に期限切れ
pgp-key-revoked = 失効
pgp-key-revoked-why = 失効：{ $reason }
pgp-key-not-valid = 無効
pgp-key-locked = 使用できません。保護キーを{ $store }で使用できません。{ $store }が利用可能で、ロックが解除されていることを確認してください。保護キーがない場合は、秘密キーのバックアップをインポートしてください。
pgp-source-own = Inbox Classicで作成
pgp-source-file = ファイルからインポート
pgp-source-paste = 貼り付け
pgp-source-attachment = メッセージから
pgp-source-vcard = 連絡先カードから
pgp-source-wkd = 送信者のメール プロバイダーから
pgp-source-keyserver = keys.openpgp.orgから
pgp-source-autocrypt = メッセージのAutocryptヘッダーから
pgp-error-no-store = 秘密キーの保護キーは{ $store }に保存されていますが、使用できません：{ $error }
pgp-error-wrong-passphrase = パスフレーズが正しくありません。
pgp-error-not-a-key = これはOpenPGPキーではありません。
pgp-error-too-large = キーが大きすぎます。
pgp-error-unusable = このキーは使用できません。適切な署名用または暗号化用のキーがないか、サポートされていない暗号方式を使用している可能性があります。
pgp-imported-private = 秘密キーを{ $count }個インポートしました。
pgp-imported-public = キーを{ $count }個インポートしました。
pgp-imported-pending = { $addresses }にはすでに別のキーが使用されています。新しいキーは、選択されるまで連絡先で保留されます。
pgp-error-needs-passphrase = 秘密キーはパスフレーズで保護されています。キーをインポートするには、パスフレーズを入力してください。
pgp-error-mismatch = 秘密キーが、対応する公開キーと一致しません。改ざんされている可能性があります。
pgp-file-name-public = { $who }の公開キー.asc
pgp-file-name-private = { $who }の秘密キーのバックアップ.asc
pgp-pending = { $date }に、{ $address }の別のキーが見つかりました。

## Reading signed and encrypted mail (protect.rs)
pgp-part-verified = { $signer }による署名、キーの所有者を確認済み
pgp-part-signed = { $signer }による署名（キーの所有者は未確認）
pgp-part-other = 送信者ではない{ $signer }による署名
pgp-part-unknown-key = 署名されていますが、キーが不明です
pgp-part-not-signed = 署名なし
pgp-part-not-checked = 署名は未確認
pgp-part-encrypted = 暗号化済み。{ $signature }
pgp-part-no-key = お持ちでないキー宛てに暗号化されています
pgp-part-changed = 暗号化された部分が整合性チェックに失敗したため、表示されません
pgp-part-unprotected = 改ざん防止なしで暗号化されているため、表示されません
pgp-part-broken = 暗号化された部分を読み取れません
pgp-why-mismatch = 署名がこのテキストと一致しません
pgp-why-weak-hash = 署名に使われている{ $hash }は、もう安全ではありません
pgp-why-key-expired = キーの有効期限（{ $date }）が切れた後に署名されています
pgp-why-key-revoked = 失効したキーで署名されています
pgp-why-not-signing-key = 署名が許可されていない可能性のあるキーで署名されています
pgp-why-from-future = 署名の日付が未来になっています
pgp-why-signature-expired = 署名の有効期限が切れています
pgp-why-key-not-valid = 無効なキーで署名されています
pgp-why-not-for-you = ほかの受信者向けに署名され、あなたに転送されたものです
pgp-why-not-key-in-use = { $address }に使用中のキーとは別のキーで署名されています
pgp-part-pictures-loaded = { $label }。画像をインターネットから読み込みました
pgp-error-no-own-key = { $address }の署名または暗号化に使うキーがありません。［ツール］>［暗号化キー］で作成するか、署名と暗号化をオフにしてください。
pgp-error-missing-keys = { $count ->
   *[other] 次の受信者に使用できる暗号化キーがありません：{ $addresses }。
}
pgp-error-encrypted-quote = このメッセージには暗号化されたメールのテキスト、画像、添付ファイルが含まれているため、暗号化しないと送信できません。暗号化をオンにするか、その内容をすべて削除してください。
pgp-error-protect = メッセージに署名または暗号化できませんでした：{ $reason }
pgp-found-keys = キーが見つかったアドレス：{ $addresses }。
pgp-found-none = { $addresses }のキーは見つかりませんでした。公開キーを送ってもらうよう依頼してください。
pgp-found-no-key = キーは見つかりませんでした。
pgp-find-unavailable = 現在キーを検索できません：{ $error }
pgp-publish-pending = keys.openpgp.orgから次のアドレスに確認のリンクが送信されました：{ $addresses }。各アドレスを確認すると、そのアドレスでキーを検索できるようになります。
pgp-publish-done = { $addresses }のキーをkeys.openpgp.orgに公開しました。
pgp-publish-failed = キーを公開できませんでした：{ $error }
pgp-keyserver-off = keys.openpgp.orgでのキーの検索は、{ $settings }でオフになっています。
pgp-compose-encrypted = { $count ->
    [1] 自分と{ $addresses }宛てに暗号化され、署名されます。
   *[other] 自分と{ $count }人の受信者宛てに暗号化され、署名されます。
}
pgp-compose-encrypt-ready = 暗号化され、署名されます。キーを持っている受信者を追加してください。
pgp-compose-missing = { $count ->
    [1] { $addresses }に使用できるキーがないため、まだメッセージを暗号化できません。
   *[other] { $count }人の受信者に使用できるキーがないため、まだメッセージを暗号化できません：{ $addresses }。
}
pgp-compose-looking = { $addresses }のキーを検索しています...
pgp-compose-signed = 送信時に署名されます。受信者は、署名された内容が変更されていないことを確認できます。キーの所有者があなたであることは、別途確認する必要があります。
pgp-compose-reply-clear = 返信元または転送元のメッセージは暗号化されていましたが、このメッセージは暗号化されません。
pgp-compose-encrypted-files = 暗号化されたメッセージのファイルが添付されているため、このメッセージは暗号化しないと送信できません。暗号化をオンにするか、それらのファイルを削除してください。
pgp-compose-sign-tip = 内容が変更されていないことを受信者が確認できるように、送信時に署名します。キーの所有者があなたであることは、別途確認する必要があります
pgp-compose-sign-tip-encrypted = 暗号化されたメッセージには常に署名されます
pgp-compose-encrypt-tip = 自分と受信者だけが読めるように、メッセージを暗号化します
pgp-compose-make-key = { $address }のキーはまだありません。今すぐ作成しますか？キーがあると、メッセージに署名して暗号化できます。
pgp-compose-key-unusable = { $address }のキーは使用できません（{ $state }）。［暗号化キー］を開いて、バックアップをインポートするか、新しいキーを作成してください。
pgp-compose-encrypt-off-quote = このメッセージには暗号化されたメールのテキスト、画像、添付ファイルが含まれています。暗号化しない場合、その内容をすべて削除するまで送信できません。それでも暗号化をオフにしますか？
pgp-compose-encrypt-off-reply = このメッセージは、暗号化されたメッセージへの返信または転送です。暗号化しないと、途中でメッセージを扱う人なら誰でも読めるようになります。暗号化をオフにしますか？
pgp-recipient-verified = キーの所有者を確認済み
pgp-recipient-found = キーの所有者は未確認
pgp-recipient-own = 自分のキー
pgp-recipient-looking = キーを検索しています...
pgp-recipient-missing = キーなし
pgp-recipient-not-found = キーなし：{ $date }に検索しましたが、見つかりませんでした
pgp-recipient-unusable = キーを使用できません：{ $state }
pgp-recipients-intro = メッセージは、各受信者のキーと自分のキー宛てに暗号化されます。
pgp-recipients-intro-missing = { $count ->
    [1] 1人の受信者に、使用できる暗号化キーがありません。キーを検索するか、その受信者をメッセージから削除してください。暗号化せずに送信できるのは、暗号化されたメールの内容をすべて削除した後だけです。
   *[other] { $count }人の受信者に、使用できる暗号化キーがありません。キーを検索するか、それらの受信者をメッセージから削除してください。暗号化せずに送信できるのは、暗号化されたメールの内容をすべて削除した後だけです。
}
pgp-details-part = パート{ $number }：{ $label }
attachment-from-part = パート{ $number }から：{ $label }
pgp-details-signed = { $when }にキー{ $key }で署名
pgp-details-unknown-key = お持ちでないキー{ $key }で署名
pgp-details-opened = 自分のキー{ $key }で復号
pgp-details-for = 暗号化先：{ $keys }
pgp-details-plain = 署名も暗号化もされていません
pgp-bar-parts = このメッセージには{ $count }個のパートがあります：{ $list }。各パートに、その保護の状態が表示されます。
pgp-bar-count-verified = 検証済み{ $count }個
pgp-bar-count-encrypted-signed = 暗号化と署名済み{ $count }個
pgp-bar-count-encrypted = 暗号化済み{ $count }個
pgp-bar-count-signed = 署名済み{ $count }個
pgp-bar-count-warning = 要確認{ $count }個
pgp-bar-count-neutral = 確認済みの署名なし{ $count }個
setup-part-settings = 設定
setup-part-preferences = ウィンドウの設定
setup-part-accounts = アカウント
setup-part-sign-in-apps = サインイン アプリ
setup-part-contacts = 連絡先とグループ
setup-part-keys = 暗号化キー
setup-part-rules = メッセージ ルール
setup-part-trusted-senders = 信頼できる送信者
setup-holds-settings = 設定{ $count }件
setup-holds-preferences = ウィンドウの設定{ $count }件
setup-holds-accounts = アカウント{ $count }個
setup-holds-sign-in-apps = サインイン アプリ{ $count }個
setup-holds-built-in = 組み込みのサインイン アプリのオンとオフ
setup-holds-contacts = 連絡先{ $count }件
setup-holds-groups = グループ{ $count }個
setup-holds-own-keys = 自分のキー{ $count }個
setup-holds-contact-keys = 連絡先のキー{ $count }個
setup-holds-rules = ルール{ $count }件
setup-holds-trusted-senders = 信頼できる送信者{ $count }件
setup-sign-in-password = パスワード
setup-account-secret-password = パスワードはファイルに含まれています。
setup-account-secret-token = 保存済みのサインイン資格情報はファイルに含まれています。
setup-account-asks-password = インポート後にパスワードの入力を求められます。
setup-account-signs-in-again = インポート後にもう一度サインインします。
setup-account-here = すでにこのコンピューターに設定されているため、スキップされます。
setup-account-no-app = このアカウントは{ $app }でサインインしますが、このアプリはこのコンピューターに設定されていません。サインイン アプリもインポートしてください。
setup-invalid-address = 「{ $address }」はメール アドレスではありません。
setup-invalid-server = { $server }の設定に、無効なサーバー名、ポート、またはセキュリティ オプションがあります。
setup-invalid-user = ユーザー名がありません。
setup-invalid-sign-in = サインインの方法または構成がサポートされていません。
setup-error-empty = ファイルが空です。
setup-error-too-large = 設定ファイルがサイズの上限を超えています。
setup-error-not-setup = このファイルはInbox Classicの設定ファイルではありません。
setup-error-damaged = 設定ファイルが破損しているため、読み取れません。
setup-error-newer = この設定は、より新しいInbox Classic（{ $version }）で保存されています。Inbox Classicを更新してから、もう一度インポートしてください。
setup-error-needs-passphrase = この設定はパスフレーズで保護されています。保存時に使用したパスフレーズを入力してください。
setup-error-wrong-passphrase = この設定の保存時に使用されたパスフレーズではありません。
setup-error-changed = 設定ファイルが整合性チェックに失敗しました。改ざんまたは破損している可能性があるため、インポートできません。
sync-wrong-passphrase = 同期パスフレーズが正しくありません。最初のコンピューターで同期を設定したときに決めたパスフレーズを入力してください。
sync-place = { $place }（「{ $name }」として）
sync-news-removed = { $count ->
   *[other] ほかのコンピューターで削除されたため、同期によってアカウント{ $accounts }が削除されました。
}
sync-news-lost = { $count ->
    [1] 別のコンピューターで同時に行われた変更が、このコンピューターでの変更に置き換えられました。その変更は同期の履歴に保存されています。
   *[other] ほかのコンピューターで同時に行われた{ $count }件の変更が、このコンピューターでの変更に置き換えられました。それらの変更は同期の履歴に保存されています。
}
sync-status-busy = 同期中…
sync-status-never = まだ同期されていません。
sync-status-last = 最終同期：{ $when }
sync-status-today = 最終同期：今日の{ $time }
sync-when-today = 今日の{ $time }
sync-status-problem = 同期できませんでした：{ $problem }
sync-removed-here = このコンピューターは、別のコンピューターで同期から削除されました。参加するには、同期をオフにしてから、もう一度設定してください。
sync-item-account = アカウント{ $name }
sync-item-contact = 連絡先{ $name }
sync-item-group = グループ{ $name }
sync-item-key = キー{ $name }
sync-item-rule = ルール{ $name }
sync-item-trusted = 信頼できる送信者{ $name }
sync-item-sign-in-app = サインイン アプリ{ $name }
sync-item-settings = 設定
sync-another-computer = 別のコンピューター
sync-no-key = このコンピューターに同期用の暗号化キーがありません。同期をオフにし、同期パスフレーズを使ってもう一度設定してください。
setup-error-read = 設定ファイルを読み取れませんでした：{ $error }
setup-error-write = 設定を保存できませんでした：{ $error }
setup-error-no-parts = 1つ以上の項目を選択してください。
setup-left-out = { $part }の{ $count }件の項目は使用できないため、除外されます。
setup-imported-settings = 設定を置き換えました。
setup-imported-preferences = ウィンドウの設定を置き換えました。
setup-added-accounts = アカウントを{ $count }個追加しました。
setup-skipped-here = { $address }はすでにこのコンピューターに設定されているため、スキップしました。
setup-skipped-no-app = { $address }をスキップしました：{ $app }でサインインしますが、このアプリはこのコンピューターに設定されていません。
setup-skipped-invalid = { $address }をスキップしました：{ $reason }
setup-asks-password = { $address }は、接続時にパスワードの入力を求めます。
setup-signs-in-again = { $address }は、接続時にもう一度サインインを求めます。
setup-added-sign-in-apps = サインイン アプリを{ $count }個追加しました。
setup-skipped-sign-in-apps = { $count }個のサインイン アプリは、すでにこのコンピューターに設定されています。
setup-added-contacts = アドレス帳に連絡先を{ $count }件追加しました。
setup-skipped-contacts = { $count }件の連絡先は、すでにアドレス帳にあります。
setup-added-groups = グループを{ $count }個追加または補完しました。
setup-added-own-keys = 自分のキーを{ $count }個追加しました。
setup-added-contact-keys = 連絡先のキーを{ $count }個追加しました。
setup-added-rules = メッセージ ルールを{ $count }件追加しました。
setup-skipped-rules = { $count }件のメッセージ ルールは、すでにこのコンピューターにあります。
setup-skipped-rules-account = { $count }件のメッセージ ルールは、このコンピューターにないアカウント用のため、スキップしました。
setup-rules-waiting = { $count }件のメッセージ ルールは、アカウントの同期中に移動先のフォルダーが見つかるのを待っています。
setup-added-trusted-senders = 信頼できる送信者を{ $count }件追加しました。
setup-nothing = 何もインポートされませんでした。
setup-account-servers = { $imap }と{ $smtp }（{ $signin }）
setup-file-name = Inbox Classicの設定とアカウント
setup-skipped-unreachable = { $name }をスキップしました：サインイン サービスに接続できなかったか、確認できませんでした。もう一度試す前に、サインイン アプリで必要なアプリを確認してください。
attachment-runs-programs = 「{ $name }」はプログラムを実行できるため、Inbox Classicでは開きません。保存してから、入手元が信頼できる場合はご自身で開いてください。
attachment-decrypted-note = この添付ファイルは暗号化されたメールのものです。別のアプリで開くため、Inbox Classicはユーザー アカウント用の一時フォルダーに、暗号化されていないコピーを保存します。起動時に、1日以上前のコピーの削除を試みます。
undone-move = { $count ->
   *[other] サーバーが{ $messages }を{ $folder }に移動しなかったため、{ $from }に戻しました：{ $reason }
}
undone-delete = { $count ->
   *[other] サーバーが{ $messages }を削除しなかったため、{ $from }に戻しました：{ $reason }
}
undone-archive = { $count ->
   *[other] サーバーが{ $messages }をアーカイブしなかったため、{ $from }に戻しました：{ $reason }
}
undone-read = { $count ->
   *[other] サーバーが{ $messages }を既読にしなかったため、未読に戻しました：{ $reason }
}
undone-unread = { $count ->
   *[other] サーバーが{ $messages }を未読にしなかったため、既読に戻しました：{ $reason }
}
undone-flags = { $count ->
   *[other] サーバーが{ $messages }のフラグを変更しなかったため、元の状態に戻しました：{ $reason }
}

## Previews of attachments: the pictures and PDF files shown in a message

preview-pdf-option = PDFファイルをメッセージ内に表示する
preview-pdf-off = PDFファイルはメッセージ内に表示されません。
preview-pdf-off-crashed = メッセージ内のファイルの表示中にInbox Classicが終了したため、PDFファイルはメッセージ内に表示されなくなりました。画像は引き続き表示されます。PDFファイルをもう一度表示するには、{ $settings }で「{ $option }」をオンにしてください。
preview-pdf-details = { $count }ページ、{ $size }
preview-page-alt = { $name }、{ $page }/{ $count }ページ
preview-more-pages = { $count ->
    [1] 開くとページを表示できます
   *[other] 開くと全{ $count }ページを表示できます
}
preview-more-files = ほかに{ $count }個のファイルが上の一覧にあります
preview-tile-downloading = ダウンロードしています…
preview-tile-preparing = 準備しています…
preview-tile-format = { $format }画像はまだ表示できません
preview-tile-password = パスワードで保護されています。開いてパスワードを入力してください
preview-tile-too-large = 大きすぎて表示できません
preview-tile-unreadable = 表示できません
preview-tile-timed-out = プレビューの準備に時間がかかりすぎました
preview-tile-crashed = プレビューを利用できません。以前の試行が中断されました
preview-tile-off = Inbox Classicを再起動するまで表示されません
preview-not-printed = { $name }（{ $details }）は印刷されません。印刷するには開いてください。

pgp-error-attached-private = この添付ファイルには秘密キーが含まれています。メールから直接インポートできるのは公開キーだけです。自分の秘密キーを復元するには、添付ファイルを保存し、［暗号化キー］でそのファイルをインポートしてください。
pgp-part-find-key = キーを検索
reaction-notification-title = { $name }が{ $emoji }でリアクションしました
reaction-notification-text = { $count ->
    [1] 対象: { $subject }
   *[other] 対象: { $subject }（新しいリアクションは合計{ $count }件）
}

reader-failed-signed-out = メール サーバーがこのアカウントのサインインを受け付けませんでした。メッセージ一覧の上のバーに対処方法が表示されます。

account-state-tooltip-refused = サインインしていません：サインインが拒否されました

account-state-tooltip-admin = サインインしていません：先に管理者がInbox Classicを承認する必要があります

account-state-tooltip-imap-off = サインインしていません：このメールボックスではIMAPが無効になっています

account-state-tooltip-other-address = サインインしていません：ブラウザーでは別のアドレスでサインインしました

account-state-tooltip-cannot-connect = メール サーバーに接続できません

account-state-mail-server = メール サーバー

account-state-bar-refused-browser = { $account }にサインインしていません：{ $provider }がサインインを受け付けませんでした。このアカウントのメールは最新の状態ではない可能性があります。

account-state-bar-refused-password = { $account }にサインインしていません：メール サーバーがパスワードを受け付けませんでした。このアカウントのメールは最新の状態ではない可能性があります。

account-state-bar-admin = { $account }にサインインしていません：サインインするには、先に{ $domain }の管理者がInbox Classicを承認する必要があります。このアカウントのメールは最新の状態ではない可能性があります。

account-state-bar-imap-off = { $account }にサインインしていません：{ $provider }によると、このメールボックスではIMAPが無効になっています。メールボックスの設定で有効にしてから、もう一度送受信してください。

account-state-bar-other-address = { $account }にサインインしていません：ブラウザーでは{ $expected }ではなく{ $email }でサインインしました。もう一度試して{ $expected }を選択してください。

account-state-bar-cannot-connect = { $account }のメール サーバーに接続できません。このアカウントのメールは最新の状態ではない可能性があります。

account-state-button-sign-in = 再サインイン

account-state-button-password = パスワードの入力

account-state-button-admin-link = 管理者に送るリンクをコピー

account-state-button-help = ヘルプ

account-state-button-try-again = 再試行

account-state-admin-link-copied = リンクをコピーしました。組織の管理者に送ってください。

account-state-app-password-hint = プロバイダーがメール プログラム用のアプリ パスワードを求めている場合は、通常のパスワードの代わりにここに入力してください。

account-status-sign-in = { $account }へのサインインが必要です

account-status-cannot-connect = { $account }で接続できません

account-status-failed = { $account }：{ $reason }

account-status-sign-in-many = { $count }個のアカウントでサインインが必要です

account-status-cannot-connect-many = { $count }個のアカウントで接続できません

account-notify-title-sign-in = { $account }にサインインしていません

account-notify-text-refused-browser = { $provider }がサインインを受け付けませんでした。新しいメールを受信するには、もう一度サインインしてください。

account-notify-text-refused-password = メール サーバーがパスワードを受け付けませんでした。新しいメールを受信するには、もう一度入力してください。

account-notify-text-admin = 先に{ $domain }の管理者がInbox Classicを承認する必要があります。

account-notify-text-imap-off = { $provider }によると、このメールボックスではIMAPが無効になっています。

account-notify-text-other-address = ブラウザーでは{ $email }でサインインしました。もう一度試して{ $expected }を選択してください。

account-notify-title-cannot-connect = { $account }で接続できません

account-notify-text-cannot-connect = Inbox Classicはメール サーバーに接続できません。引き続き接続を試みます。

account-state-compose-sign-in = このアカウントにサインインしていないため、メッセージは送信トレイで待機します。

account-state-compose-cannot-connect = このアカウントに接続の問題があります。送信に失敗した場合、メッセージは送信トレイに残ります。

account-state-outbox-sign-in = 待機中：{ $account }にサインインしていません

account-state-outbox-cannot-connect = 待機中：{ $account }で接続できません
