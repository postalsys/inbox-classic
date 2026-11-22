# 繁體中文（台灣）草稿，等待母語人士審閱。
# 核心在各平台上顯示的相同文字。{ $braces } 中的預留位置由程式填入，請保留，並放在中文需要的位置。中文的複數只有
# *[other] 一種形式。

## 數量與大小

# review: new
messages = { $count }封郵件
# the separator of decimals in sizes: 2.4 MB
# review: new
decimal-separator = .
# review: new
list-separator = 、
# review: new
size-bytes = { $count }位元組
# review: new
size-kb = { $size } KB
# review: new
size-mb = { $size } MB
# review: new
size-gb = { $size } GB
# review: new
send-delay-off = 關閉
# review: new
send-delay-seconds = { $count }秒
# the status bar: "12 messages, 3 unread"
# review: new
list-counts = { $messages }，{ $unread }封未讀取
# review: new
list-counts-selected = { $messages }，{ $unread }封未讀取，已選取{ $selected }封
# the status bar while searching: "12 found, 3 unread"
# review: new
list-counts-found = 找到{ $found }封，{ $unread }封未讀取
# review: new
list-counts-found-selected = 找到{ $found }封，{ $unread }封未讀取，已選取{ $selected }封
# review: new
list-counts-none = 找不到任何郵件

## 特殊資料夾，沿用 Outlook Express 的名稱

# review: new
folder-inbox = 收件匣
# review: new
folder-sent = 寄件備份
# review: new
folder-deleted = 刪除的郵件
# review: new
folder-drafts = 草稿
# review: new
folder-junk = 垃圾郵件
# review: new
folder-archive = 封存

## 讀取窗格

# review: new
reader-no-message = 未選取任何郵件。
# review: new
reader-downloading = 正在下載郵件...
# review: new
reader-downloading-detail = 下載完成後，郵件就會顯示在這裡。
# review: new
reader-downloading-size = 郵件大小為{ $size }。下載完成後就會顯示在這裡。
# review: new
reader-failed = 無法下載郵件
# review: new
reader-failed-network = 無法連線到郵件伺服器，或連線已中斷（{ $reason }）。
# review: new
reader-failed-sign-in = 郵件伺服器不接受登入（{ $reason }）。請檢查密碼，或在帳戶設定中重新登入。
# review: new
reader-failed-security = 無法建立與郵件伺服器的安全連線（{ $reason }）。
# review: new
reader-failed-other = 郵件伺服器回應：{ $reason }。
# review: new
reader-retry-note = 帳戶重新連線時會再試一次。
# review: new
reader-unreadable = 無法顯示這封郵件：{ $error }
# review: new
message-source-title = 郵件原始碼：{ $subject }
# review: new
message-source-untitled = 郵件原始碼

## 列印郵件，以及回覆或轉寄時引用郵件的標頭

# review: new
header-from = 寄件者
# review: new
header-date = 日期
# review: new
header-to = 收件者
# review: new
header-cc = 副本
# review: new
header-sent = 寄件日期
# review: new
header-subject = 主旨
# review: new
header-security = 安全性
# review: new
header-part = 第{ $number }部分
# review: new
quote-original = ----- 原始郵件 -----
# review: new
fold-show-earlier = 顯示較早的郵件

## 退信：未送達通知最上方的卡片

# review: new
bounce-failed = 您的郵件未送達
# review: new
bounce-delayed = 您的郵件尚未送達
# review: new
bounce-delayed-note = 您的郵件伺服器仍在嘗試傳遞，您不需要再傳送一次。
# the link to the message the notice is about, in Sent Items or another folder
# review: new
bounce-show-message = 顯示被退回的郵件
# the link of a delay's card to the message that is still on its way
# review: new
bounce-show-delayed = 顯示延遲的郵件
# review: new
bounce-what-to-do = 您可以這麼做：
# what to do about a recipient the message is still on its way to: in the card of a delay, and in the card of a failure
# review: new
bounce-delayed-do = 目前不需要做什麼。如果仍然無法送達，您會再收到一封通知。
# review: new
bounce-delayed-row-do = 目前不需要做什麼。您的郵件伺服器仍在嘗試傳遞，如果無法送達，您會再收到一封通知。
# folds the receiving server's own words
# review: new
bounce-details = 詳細資料
# a recipient the notice does not name
# review: new
bounce-someone = 一位收件者
# in Details: the server that refused the message, the status code it gave, and the server that wrote the notice
# review: new
bounce-server = 伺服器：{ $server }
# review: new
bounce-status = 狀態：{ $status }
# review: new
bounce-reported-by = 回報者：{ $server }
# review: new
bounce-retry-minutes = 接收端伺服器要求等待{ $count }分鐘後再重試。
# review: new
bounce-retry-hours = 接收端伺服器要求等待{ $count }小時後再重試。
# the names of the blocklists, "Spamhaus ZEN, Barracuda"
# review: new
bounce-blocklist = 封鎖清單：{ $lists }
# review: new
bounce-user-unknown = 地址不存在
# review: new
bounce-user-unknown-why = 接收端伺服器沒有這個地址的信箱。可能是地址打錯了，或對方已不再使用。
# review: new
bounce-user-unknown-do = 請檢查地址的拼字，或詢問對方目前使用的地址。
# review: new
bounce-invalid-address = 地址無效
# review: new
bounce-invalid-address-why = 這個地址的寫法無法用來寄送郵件。
# review: new
bounce-invalid-address-do = 請檢查是否有輸入錯誤，例如多了空格、少了字母，或 @ 之後沒有內容。
# review: new
bounce-mailbox-disabled = 信箱已關閉
# review: new
bounce-mailbox-disabled-why = 這個地址存在，但其信箱已停用或不再使用。
# review: new
bounce-mailbox-disabled-do = 請透過其他方式聯絡對方，並詢問對方目前使用的地址。
# review: new
bounce-mailbox-full = 信箱已滿
# review: new
bounce-mailbox-full-why = 收件者的信箱已沒有空間接收新郵件。
# review: new
bounce-mailbox-full-do = 請過幾天再傳送一次，或透過其他方式通知對方。
# review: new
bounce-spam-blocked = 被視為垃圾郵件而遭拒
# review: new
bounce-spam-blocked-why = 接收端伺服器將這封郵件視為垃圾郵件。
# review: new
bounce-spam-blocked-do = 請移除看似垃圾郵件的內容後再傳送一次，例如大量連結、縮短網址或大型附件。如果一再發生，請洽詢您的郵件服務提供者。
# review: new
bounce-virus-detected = 因含有病毒而遭拒
# review: new
bounce-virus-detected-why = 接收端伺服器回報郵件或其附件中含有病毒或其他有害內容。
# review: new
bounce-virus-detected-do = 請用防毒軟體檢查附件。有些伺服器會拒收所有程式或壓縮檔，因此請改用連結分享這類檔案。
# review: new
bounce-ip-blocklisted = 您的郵件伺服器在封鎖清單上
# review: new
bounce-ip-blocklisted-why = 接收端伺服器拒收來自寄出您郵件之伺服器的郵件，因為該伺服器的位址在封鎖清單上。
# review: new
bounce-ip-blocklisted-do = 問題不在郵件本身。請將這封通知轉寄給您的郵件服務提供者，請對方將伺服器從清單中移除。
# review: new
bounce-domain-blocklisted = 有網域在封鎖清單上
# review: new
bounce-domain-blocklisted-why = 接收端伺服器拒收這封郵件，因為您地址的網域，或郵件中連結的網域，在封鎖清單上。
# review: new
bounce-domain-blocklisted-do = 如果郵件中有連結，請試著移除連結後再傳送。否則，請將這封通知轉寄給您網域的郵件管理員。
# review: new
bounce-policy-blocked = 遭接收端伺服器的規則拒收
# review: new
bounce-policy-blocked-why = 接收端伺服器的規則不允許這封郵件通過，例如因為郵件大小、附件或寄件者。
# review: new
bounce-policy-blocked-do = 「詳細資料」中伺服器的原文通常會說明原因。請詢問收件者是否能接收這類郵件。
# review: new
bounce-geo-blocked = 因寄件來源而遭拒
# review: new
bounce-geo-blocked-why = 接收端伺服器不接收來自您郵件伺服器所在國家或網路的郵件。
# review: new
bounce-geo-blocked-do = 請透過其他方式聯絡對方，或洽詢您的郵件服務提供者。
# review: new
bounce-relay-denied = 伺服器不願轉送
# review: new
bounce-relay-denied-why = 有伺服器拒絕繼續傳遞這封郵件，通常是因為郵件未經登入就寄出，或經由不負責這位收件者的伺服器寄出。
# review: new
bounce-relay-denied-do = 請在帳戶設定中檢查外寄伺服器與登入資料。
# review: new
bounce-auth-failure = 無法驗證您的寄件者地址
# review: new
bounce-auth-failure-why = 接收端伺服器無法確認這封郵件確實來自您的網域（SPF、DKIM 或 DMARC）。
# review: new
bounce-auth-failure-do = 請將這封通知轉寄給您網域的郵件管理員：網域的設定需要修正。在此之前，透過服務提供者自己的伺服器寄送可能會有幫助。
# review: new
bounce-rate-limited = 一次寄出太多郵件
# review: new
bounce-rate-limited-why = 接收端伺服器目前減少接收來自您郵件伺服器的郵件。
# review: new
bounce-rate-limited-do = 請稍候再傳送一次。寄信給許多人時，請每次寄給較少的人。
# review: new
bounce-greylisting = 暫時延後接收
# review: new
bounce-greylisting-why = 接收端伺服器會要求不認識的寄件者稍後再試，這是常見的防垃圾郵件檢查。
# review: new
bounce-greylisting-do = 如果只是暫時延遲，寄件伺服器通常會再試一次。如果這封通知表示已確定失敗，請稍後再傳送一次郵件。
# review: new
bounce-server-error = 接收端伺服器發生問題
# review: new
bounce-server-error-why = 無法連線到接收端伺服器，或伺服器本身發生問題而無法接收郵件。
# review: new
bounce-server-error-do = 請稍後再傳送一次。如果一直失敗，請檢查地址中 @ 之後的部分是否有輸入錯誤。
# review: new
bounce-unknown = 未送達
# review: new
bounce-unknown-why = 通知中沒有清楚說明原因。
# review: new
bounce-unknown-do = 「詳細資料」中伺服器的原文可能有更多說明。如果沒有幫助，請將這封通知轉寄給您的郵件服務提供者。

## 選取多封郵件

# review: new
selection-title = 已選取{ $count }封郵件
# review: new
selection-unread = { $count }封未讀取
# review: new
selection-flagged = { $count }封已標幟
# review: new
delete-for-good-one = 這封郵件將會永久刪除。要刪除嗎？
# review: new
delete-for-good-all = 這{ $count }封郵件將會永久刪除。要刪除嗎？
# review: new
delete-for-good-some = { $total }封郵件中有{ $count }封將會永久刪除。要刪除這些郵件嗎？
# review: new
done-read = { $count ->
   *[other] 已將{ $messages }標示為已讀取
}
# review: new
done-unread = { $count ->
   *[other] 已將{ $messages }標示為未讀取
}
# review: new
done-flagged = { $count ->
   *[other] 已為{ $messages }加上標幟
}
# review: new
done-unflagged = 已清除{ $messages }的標幟
# review: new
done-deleted-for-good = { $count ->
   *[other] 已永久刪除{ $messages }
}
# review: new
done-archived = { $count ->
   *[other] 已封存{ $messages }
}
# review: new
done-moved = { $count ->
   *[other] 已將{ $messages }移至{ $folder }
}
# review: new
done-copied = { $count ->
   *[other] 已將{ $messages }複製到{ $folder }
}
# review: new
done-moving = { $count ->
   *[other] 正在將{ $messages }移至{ $folder }...
}
# review: new
done-copying = { $count ->
   *[other] 正在將{ $messages }複製到{ $folder }...
}
# review: new
done-moved-back = { $count ->
   *[other] 已將{ $messages }移回{ $folder }
}
# the status bar after Watch Conversation and Ignore Conversation, and after either again on a marked one
# review: new
done-watched = { $count ->
    [1] 正在監看交談
   *[other] 正在監看{ $count }個交談
}
# review: new
done-unwatched = { $count ->
    [1] 已停止監看交談
   *[other] 已停止監看{ $count }個交談
}
# review: new
done-ignored = { $count ->
    [1] 正在忽略交談
   *[other] 正在忽略{ $count }個交談
}
# review: new
done-unignored = { $count ->
    [1] 已停止忽略交談
   *[other] 已停止忽略{ $count }個交談
}
# review: new
their-folders = 原本的資料夾
# review: new
undo-move = 復原移動
# review: new
undo-delete = 復原刪除
# review: new
undo-archive = 復原封存
# review: new
undo-junk = 復原標示為垃圾郵件
# review: new
undo-not-junk = 復原標示為非垃圾郵件
# review: new
undo-send = 復原傳送
# review: new
nothing-to-undo = 沒有可以復原的動作。
# review: new
messages-gone = 這些郵件已不在原處。
# A non-selectable IMAP folder cannot contain messages; this does not mean it is empty.
# review: new
folder-holds-no-messages = 這個資料夾無法存放郵件。
# review: new
not-archived-here = 這個資料夾中的郵件無法封存。
# review: new
not-emptied-here = 只有「刪除的郵件」和「垃圾郵件」可以清空。
# review: new
next-unread-question = { $folder }中已沒有未讀取的郵件。

    要移至下一個有未讀取郵件的資料夾{ $next }嗎？
# review: new
no-unread-left = 已沒有未讀取的郵件。
# review: new
empty-question = { $count ->
    [1] 要清空{ $folder }嗎？

        其中的郵件將會永久刪除，無法復原。
   *[other] 要清空{ $folder }嗎？

        其中的{ $messages }將會永久刪除，無法復原。
}
# review: new
no-junk-folder = 這個帳戶沒有可以移入郵件的「垃圾郵件」資料夾。
# review: new
no-inbox-folder = 這個帳戶沒有可以移入郵件的「收件匣」資料夾。
# the status bar after a flag in a colour: "Flagged 2 messages blue"
# review: new
done-flagged-color = 已為{ $messages }加上{ $color ->
    [red] 紅色
    [orange] 橘色
    [yellow] 黃色
    [green] 綠色
    [blue] 藍色
    [purple] 紫色
   *[gray] 灰色
}標幟
# the Flag menu: the colours of Apple Mail's flags
# review: new
flag-color = { $color ->
    [red] 紅色
    [orange] 橘色
    [yellow] 黃色
    [green] 綠色
    [blue] 藍色
    [purple] 紫色
   *[gray] 灰色
}

## 移動與複製視窗

# review: new
move-window-title-move = { $count ->
    [1] 移動郵件
   *[other] 移動{ $count }封郵件
}
# review: new
move-window-title-copy = { $count ->
    [1] 複製郵件
   *[other] 複製{ $count }封郵件
}
# review: new
move-window-prompt-move = { $count ->
    [1] 將選取的郵件移至：
   *[other] 將選取的{ $count }封郵件移至：
}
# review: new
move-window-prompt-copy = { $count ->
    [1] 將選取的郵件複製到：
   *[other] 將選取的{ $count }封郵件複製到：
}
# the folders used last, over the folder tree
# review: new
targets-recent = 最近使用
# the folder the messages are in, which can not be chosen
# review: new
target-current = { $folder }（目前）
# a folder used last, with its account when there are several: "Archive (Work)"
# review: new
target-recent = { $folder }（{ $account }）

## 移動及複製到其他帳戶

# review: new
transfer-moving = 正在將{ $messages }移至{ $folder }，已完成{ $done }封...
# review: new
transfer-copying = 正在將{ $messages }複製到{ $folder }，已完成{ $done }封...
# review: new
transfer-another-account = 其他帳戶
# review: new
transfer-folder-gone = 目的地資料夾已不存在
# review: new
transfer-not-on-server = 郵件已不在伺服器上
# review: new
transfer-not-moved = { $count ->
   *[other] 無法將{ $messages }移至其他帳戶：{ $reason }
}
# review: new
transfer-not-copied = { $count ->
   *[other] 無法將{ $messages }複製到其他帳戶：{ $reason }
}
# review: new
transfer-none-moved = 沒有任何郵件可以移動
# review: new
transfer-none-copied = 沒有任何郵件可以複製

## 郵件檔案

# review: new
export-not-in-time = 無法及時下載郵件
# review: new
export-not-saved = { $messages }中有{ $failed }封無法儲存（{ $problems }）
# review: new
export-not-attached = 無法附加郵件：{ $error }
# the status bar after Save As with several: "Saved 3 messages to Desktop"
# review: new
saved-to = { $count ->
   *[other] 已將{ $messages }儲存到{ $folder }
}
# review: new
download-progress = 正在下載，已完成{ $done }，共{ $total }
# review: new
download-done = 已下載{ $size }
# review: new
downloading-messages = { $count ->
   *[other] 正在下載{ $messages }...
}
# the status bar after files are dropped on a folder: "Put 3 messages in Archive"
# review: new
import-put = { $count ->
   *[other] 已將{ $messages }排入佇列，準備匯入{ $folder }
}
# review: new
import-not-put = 下列項目未放入資料夾：

    { $problems }

## 視窗顯示的問題

# review: new
error-store = 本機存放區：{ $error }
# review: new
error-not-found = 找不到
# review: new
error-closed = 正在關閉
# review: new
error-other-account = 瀏覽器登入的是{ $email }，而不是這個帳戶
# a password or sign-in the mail server refused, with the server's words
# review: new
failure-authentication = 伺服器不接受登入（{ $reason }）
# the mail server could not be reached or the connection broke, with the reason
# review: new
failure-network = 無法連線到伺服器（{ $reason }）
# review: new
error-in-use = 有帳戶使用它登入時無法移除：{ $accounts }
# review: new
error-turned-off = 這個登入應用程式已對新帳戶關閉
# review: new
error-folder-name = 資料夾名稱長度必須為 1 到 200 個字元，且不能包含控制字元
# review: new
error-folder-separator = 在這部伺服器上，資料夾名稱不能包含「{ $separator }」
# review: new
error-folder-special = 收件匣與特殊資料夾無法重新命名或刪除
# review: new
error-no-recipients = 郵件沒有收件者
# review: new
error-bad-address = 「{ $address }」不是電子郵件地址
# review: new
error-not-own-address = { $address }不是這個帳戶的寄件者地址之一。請在帳戶內容的「您用來寄信的其他地址」中新增它。
# review: new
rule-query-refused = 規則無法依資料夾或日期篩選（{ $words }）。
# review: new
rule-no-query = 請輸入內送郵件的搜尋準則。
# review: new
rule-no-action = 請為規則選擇至少一個動作。
# review: new
error-attachment = 無法讀取{ $path }：{ $error }
# review: new
error-no-drafts = 帳戶沒有可以儲存郵件的「草稿」資料夾
# review: new
error-draft-attachment = 無法保留草稿的附件：{ $error }
# review: new
error-password-not-saved = 無法儲存密碼供下次啟動使用：{ $error }
# review: new
error-sign-in-not-saved = 無法儲存新的登入資料供下次啟動使用：{ $error }
# review: new
error-import-unreadable = 無法讀取{ $path }：{ $error }
# review: new
error-import-too-large = { $path }超過 50 MB
# review: new
error-import-not-mail = { $path }不是電子郵件
# review: new
error-list-answered = 郵寄清單伺服器傳回狀態{ $status }
# review: new
error-not-built = 無法建立郵件
# review: new
error-outbox-waits = { $count ->
    [1] 郵件仍留在寄件匣中，下次傳送/接收時會再試著傳送
   *[other] { $count }封郵件仍留在寄件匣中，下次傳送/接收時會再試著傳送
}
# review: new
error-draft-not-removed = 無法從草稿中移除這封郵件的先前草稿：{ $reason }
# review: new
error-sent-but = 郵件已傳送，但{ $problem }
# review: new
error-sent-still-in-outbox = 它仍在寄件匣中：{ $error }
# review: new
error-sent-no-copy = 無法在寄件備份中儲存副本：{ $reason }
# review: new
error-no-password = 這個帳戶沒有密碼
# review: new
error-no-sign-in = 這個帳戶沒有登入資料
# review: new
error-provider-missing = 這個版本無法使用此登入應用程式（識別碼：{ $provider }），它可能已被移除
# review: new
error-provider-servers = 這個帳戶的伺服器與其登入應用程式的伺服器不符
# review: new
error-app-scopes = { $reason }。郵件伺服器不接受登入應用程式的權杖：請檢查應用程式的權限範圍是否包含郵件存取權
# review: new
error-in-folder = { $folder }：{ $reason }

## 登入應用程式

# review: new
sign-in-off-google = 內建的 Google 登入應用程式是為核准的測試使用者設定的，預設對新帳戶關閉。測試使用者可以在「登入應用程式」（檔案 > 帳戶）中開啟它。您也可以使用自己的 Google 登入應用程式，或在帳戶支援時使用應用程式密碼。
# review: new
sign-in-off-other = 它已對新帳戶關閉。您可以在「登入應用程式」（檔案 > 帳戶）中開啟它。
# review: new
sign-in-app-no-name = 登入應用程式需要名稱
# review: new
sign-in-app-no-client = 缺少用戶端識別碼
# review: new
sign-in-app-no-scopes = 登入應用程式需要提供郵件存取權的權限範圍
# review: new
sign-in-app-bad-host = { $server }伺服器位址遺漏，或不是有效的主機名稱
# review: new
sign-in-app-plain = { $server }伺服器必須使用 SSL/TLS 或 STARTTLS
# review: new
sign-in-app-not-checked = 尚未檢查簽發者
# review: new
sign-in-app-issuer-changed = 簽發者已變更：請重新輸入用戶端密碼，或將其移除
# review: new
sign-in-register-google = 在 Google Cloud Console 中建立類型為「電腦版應用程式」的 OAuth 用戶端，並在其同意畫面加入權限範圍 https://mail.google.com/。應用程式處於測試階段時，只有其測試使用者可以登入。
# review: new
sign-in-register-microsoft = 在 Microsoft Entra 中註冊應用程式：平台選擇「行動和桌面應用程式」，重新導向 URI 設為 http://localhost 並允許公用用戶端流程，委派的權限為 IMAP.AccessAsUser.All、SMTP.Send 與 offline_access。若只供您的組織使用，請以 https://login.microsoftonline.com/<tenant ID>/v2.0 作為簽發者。
# review: new
sign-in-register-other = 使用下方的重新導向 URI 註冊原生（公用）用戶端；服務提供者必須允許其使用任何連接埠（RFC 8252）。並加入服務提供者用來授予郵件存取權的權限範圍。

## 行事曆邀請

# review: new
repeats = 重複
# review: new
repeats-every = { $unit ->
    [day] { $interval ->
        [1] 每天
       *[other] 每{ $interval }天
    }
    [week] { $interval ->
        [1] 每週
       *[other] 每{ $interval }週
    }
    [month] { $interval ->
        [1] 每月
       *[other] 每{ $interval }個月
    }
   *[year] { $interval ->
        [1] 每年
       *[other] 每{ $interval }年
    }
}
# "Every week on Monday, Wednesday"
# review: new
repeats-on = { $repeats }的{ $days }
# "Every week, 10 times"
# review: new
repeats-times = { $repeats }，共{ $count }次
# review: new
day-monday = 星期一
# review: new
day-tuesday = 星期二
# review: new
day-wednesday = 星期三
# review: new
day-thursday = 星期四
# review: new
day-friday = 星期五
# review: new
day-saturday = 星期六
# review: new
day-sunday = 星期日

## AI 代理程式

# review: new
agent-level-read = 讀取郵件：資料夾、郵件清單、交談、搜尋、郵件及其檔案、您的郵件規則，以及您寫信往來的人
# review: new
agent-level-organize = 整理郵件：已讀取狀態、標幟及其色彩、垃圾郵件、移動、封存、建立及重新命名資料夾、監看及忽略交談、刪除到「刪除的郵件」，以及經您同意後退出郵寄清單
# review: new
agent-level-drafts = 撰寫草稿供您傳送
# review: new
agent-level-send = 傳送郵件，每封郵件都須經您同意
# review: new
agent-connect-title = { $program }想要使用您的郵件
# review: new
agent-connect-detail = 有 AI 代理程式要求與 Inbox Classic 搭配使用。請選擇它可以做什麼，以及可以查看哪些帳戶；之後可以在「工具 > AI 代理程式」中變更。

    代理程式會讀取其他人寫的郵件，而郵件可能會試圖欺騙它們。代理程式要傳送任何內容之前，Inbox Classic 一律會先詢問您。
# review: new
agent-reply-to = 回覆「{ $subject }」
# review: new
agent-reply-all-on = 全部回覆「{ $subject }」
# review: new
agent-forward-of = 轉寄「{ $subject }」
# review: new
agent-never-written-one = 您從未寫信給{ $address }。
# review: new
agent-never-written-many = 這些地址中，有{ $count }個您從未寫信過。
# review: new
agent-send-title = { $program }想要傳送這封郵件
# review: new
agent-send-detail = 請檢查收件者與郵件內容。確認後，郵件會在寄件匣中等候{ $seconds }秒，在此期間您仍可刪除它。
# review: new
agent-change-title = { $program }可以做什麼
# review: new
agent-change-allowed = 變更這個程式的 AI 代理程式可以對您的郵件做什麼。
# review: new
agent-change-refused = 您已拒絕這個程式的存取。允許它，即可讓其代理程式再次存取您的郵件。
# review: new
agent-log-taken-back = { $entry }（已收回）
# review: new
agent-files = 檔案：{ $files }
# review: new
agent-undo-refused = 無法收回。
# review: new
agent-undo-refused-why = 無法收回：{ $reason }。
# review: new
agent-undo-impossible = 這個動作無法收回
# review: new
agent-undo-not-in-folder = 郵件已不在該資料夾中
# review: new
agent-undo-not-arrived = 郵件（還）不在它被移往的資料夾中
# review: new
agent-undo-sent = 郵件已不在寄件匣中
# review: new
agent-original-not-downloaded = 原始郵件尚未下載，請先開啟它
# review: new
agent-turned-away = 已拒絕
# review: new
agent-can-nothing = 無
# review: new
agent-can-read = 讀取
# review: new
agent-can-organize = 整理
# review: new
agent-can-drafts = 撰寫草稿
# review: new
agent-can-send = 經您同意後傳送
# "Read, organize and write drafts"
# review: new
agent-can-list = { $first }和{ $last }
# review: new
agent-accounts = { $count ->
    [0] 沒有帳戶
   *[other] { $count }個帳戶
}
# "Read and organize; 1 account"
# review: new
agent-access = { $can }；{ $accounts }
# review: new
agent-unreadable = 無法讀取這封郵件。
# review: new
agent-encrypted-original = 這封郵件已加密：代理程式無法加密，因此無法回覆或轉寄它。
# review: new
agent-encrypted = 這封郵件已加密。AI 代理程式無法讀取其內容。請在 Inbox Classic 中開啟，自行閱讀。
# review: new
agent-too-many-changes = 過去 30 天的變更太多：這個代理程式所做的變更，已達 Inbox Classic 為單一程式保留的記錄上限。最舊的記錄滿 30 天後，它才能再做更多變更。
# review: new
agent-too-many-reads = 過去 30 天的讀取太多：這個代理程式讀取的量，已達 Inbox Classic 為單一程式保留的記錄上限。最舊的讀取記錄滿 30 天後，它才能再讀取更多內容。
# review: new
list-encrypted = 加密的郵件
# review: new
agent-log-composed = 已在新郵件中開啟「{ $subject }」，供您完成
# review: new
agent-log-refused = 您未傳送「{ $subject }」
# review: new
agent-log-sent = 已將寄給{ $to }的「{ $subject }」放入寄件匣
# review: new
agent-log-draft = 已儲存草稿「{ $subject }」
# review: new
agent-log-draft-replaced = 已取代草稿「{ $subject }」
# review: new
agent-log-draft-discarded = 已要求刪除草稿「{ $subject }」
# review: new
agent-draft-note = 這份草稿是由 AI 代理程式{ $program }撰寫的。傳送前請檢查收件者與內文。
# review: new
agent-log-read = 已將「{ $subject }」標示為已讀取
# review: new
agent-log-unread = 已將「{ $subject }」標示為未讀取
# review: new
agent-log-flagged = 已為「{ $subject }」加上標幟
# review: new
agent-log-unflagged = 已清除「{ $subject }」的標幟
# review: new
agent-log-deleted = 已刪除「{ $subject }」
# review: new
agent-log-moved = 已將「{ $subject }」移至{ $folder }
# review: new
agent-log-junk = 已將「{ $subject }」標示為垃圾郵件
# review: new
agent-log-not-junk = 已將「{ $subject }」標示為非垃圾郵件
# review: new
agent-log-archived = 已封存「{ $subject }」
# review: new
agent-log-folder = 已要求建立資料夾「{ $name }」
# written at the user's yes, before the list is asked; a list that fails replaces it with agent-log-unsubscribe-failed
# review: new
agent-log-unsubscribed = 您已同意取消訂閱郵件「{ $subject }」所屬的清單
# review: new
agent-log-unsubscribe-failed = 無法取消訂閱郵件「{ $subject }」所屬的清單：{ $reason }
# "You did not unsubscribe from news@shop.example, deals@example.com": the lists' addresses, never their names
# review: new
agent-log-unsubscribe-refused = 您未核准以下地址的取消訂閱要求：{ $senders }
# review: new
agent-unsubscribe-title = { $count ->
    [1] { $program }想要為您取消訂閱一個郵寄清單
   *[other] { $program }想要為您取消訂閱{ $count }個郵寄清單
}
# review: new
agent-unsubscribe-detail = { $count ->
    [1] Inbox Classic 會透過下方清單提供的一鍵取消訂閱方式，要求清單停止寄信給您。不會傳送其他任何內容，您已收到的郵件也會保留在原處。
   *[other] Inbox Classic 會透過下方每個清單提供的一鍵取消訂閱方式，要求清單停止寄信給您。不會傳送其他任何內容，您已收到的郵件也會保留在原處。
}
# review: new
agent-log-flag-color = 已為「{ $subject }」加上{ $color ->
    [red] 紅色
    [orange] 橘色
    [yellow] 黃色
    [green] 綠色
    [blue] 藍色
    [purple] 紫色
   *[gray] 灰色
}標幟
# review: new
agent-log-renamed = 已要求將資料夾「{ $old }」重新命名為「{ $name }」
# review: new
agent-log-watched = 已監看交談「{ $subject }」
# review: new
agent-log-ignored = 已忽略交談「{ $subject }」
# review: new
agent-log-unmarked = 已停止監看或忽略交談「{ $subject }」
# the reason one change can not be taken back (agent-undo-refused-why)
# review: new
agent-undo-changed = 郵件在那之後已有變更
# one change of many messages an agent made with a search (apply_to_search), a row of the log; { $query } is the search
# review: new
agent-log-bulk-read = 已將{ $count }封郵件標示為已讀取（搜尋：{ $query }）
# review: new
agent-log-bulk-unread = 已將{ $count }封郵件標示為未讀取（搜尋：{ $query }）
# review: new
agent-log-bulk-flagged = 已為{ $count }封郵件加上標幟（搜尋：{ $query }）
# review: new
agent-log-bulk-unflagged = 已清除{ $count }封郵件的標幟（搜尋：{ $query }）
# review: new
agent-log-bulk-color = 已為{ $count }封郵件加上{ $color ->
    [red] 紅色
    [orange] 橘色
    [yellow] 黃色
    [green] 綠色
    [blue] 藍色
    [purple] 紫色
   *[gray] 灰色
}標幟（搜尋：{ $query }）
# review: new
agent-log-bulk-moved = 已將{ $count }封郵件移至{ $folder }（搜尋：{ $query }）
# review: new
agent-log-bulk-archived = 已封存{ $count }封郵件（搜尋：{ $query }）
# review: new
agent-log-bulk-junk = 已將{ $count }封郵件標示為垃圾郵件（搜尋：{ $query }）
# review: new
agent-log-bulk-not-junk = 已將{ $count }封郵件標示為非垃圾郵件（搜尋：{ $query }）
# review: new
agent-log-bulk-deleted = 已刪除{ $count }封郵件（搜尋：{ $query }）
# Undo Everything Since in the AI Agents window: how far back it reaches
# review: new
agent-undo-span = { $span ->
    [quarter] 過去 15 分鐘內
    [hour] 過去 1 小時內
    [hours] 過去 4 小時內
    [day] 過去 24 小時內
    [week] 過去 7 天內
   *[all] 過去 30 天內
}
# the question before it takes back what a program did in the span chosen
# review: new
agent-undo-since-question = { $count ->
    [0] { $program }在這段期間內沒有可以收回的變更。
    [1] 要試著收回這段期間內為{ $program }記錄的變更嗎？
   *[other] 要試著收回這段期間內為{ $program }記錄的{ $count }項變更嗎？
}
# review: new
agent-undo-since-detail = Inbox Classic 會試著還原資料夾、已讀取狀態與標幟，並刪除仍在寄件匣中等候的郵件。已無法復原的變更會略過。之後的某些標幟色彩變更可能會被覆寫。
# what taking back did, then a line for each kind of message it left as it is
# review: new
agent-undo-done = { $count ->
    [0] 沒有收回任何變更。
   *[other] 已全部或部分收回{ $count }項記錄的變更。
}
# review: new
agent-undo-left-gone = { $count }封郵件已不在變更後所在的位置。
# review: new
agent-undo-left-changed = { $count }封郵件在那之後已由您或在伺服器上變更，因此維持原狀。
# review: new
agent-undo-left-sent = { $count }封郵件已離開寄件匣。
# review: new
agent-undo-left-impossible = { $count }項變更無法收回。
# the Send question of an agent's answer to a calendar invitation: what it answers, and when the event is
# review: new
agent-invitation-reply = { $response ->
    [accept] 這封郵件會接受邀請「{ $summary }」（{ $when }）。
    [tentative] 這封郵件會暫時接受邀請「{ $summary }」（{ $when }）。
   *[decline] 這封郵件會拒絕邀請「{ $summary }」（{ $when }）。
}郵件會寄給邀請中列出的召集人。郵件伺服器接受郵件後，您本機的回覆就會變更，不需等待召集人行事曆的確認。
# the subject of an answer to an invitation, as calendar programs write it
# review: new
invitation-reply-subject = { $response ->
    [accept] 已接受：{ $summary }
    [tentative] 暫定：{ $summary }
   *[decline] 已拒絕：{ $summary }
}
# the text of an answer to an invitation; { $name } is the user's name, or address
# review: new
invitation-reply-text = { $response ->
    [accept] { $name }已接受這項邀請。
    [tentative] { $name }已暫時接受這項邀請。
   *[decline] { $name }已拒絕這項邀請。
}
# what a program read in an hour, a row of the log: "Read 14 messages and searched 3 times" (joined by agent-can-list)
# review: new
agent-reads-messages = 讀取了{ $count }封郵件
# review: new
agent-reads-attachments = 要求了{ $count }個附件
# review: new
agent-reads-searches = 搜尋了{ $count }次
# review: new
agent-reads-lists = 查看了郵件清單{ $count }次
# each read under that row
# review: new
agent-read-message = 已讀取「{ $subject }」
# review: new
agent-read-conversation = 已讀取交談「{ $subject }」（{ $count }封郵件）
# review: new
agent-read-attachment = 已要求「{ $subject }」中的附件「{ $name }」
# review: new
agent-read-search = 已搜尋「{ $query }」：{ $count }封郵件
# review: new
agent-read-people = 已依名稱或地址的開頭查詢人員：「{ $query }」
# review: new
agent-read-list = 已查看{ $count }個清單項目（範圍：{ $folder }）
# review: new
agent-read-changes = 已查看{ $count }封新郵件的詳細資料
# the programs started from a terminal app, which share one access: in the list of programs and the question when one connects
# review: new
agent-terminal-programs-mac = 從{ $terminal }啟動的程式
# review: new
agent-terminal-programs-windows = 從終端機（{ $terminal }）啟動的程式
# review: new
agent-terminal-programs-linux = 從終端機（{ $terminal }）啟動的程式
# one of them, as the questions to send or unsubscribe name it: "A program started from Terminal wants to send this message"
# review: new
agent-terminal-program-mac = 從{ $terminal }啟動的程式
# review: new
agent-terminal-program-windows = 從終端機（{ $terminal }）啟動的程式
# review: new
agent-terminal-program-linux = 從終端機（{ $terminal }）啟動的程式
# review: new
agent-connect-title-terminal = { $programs }想要使用您的郵件
# review: new
agent-connect-terminal-detail = 從同一個可辨識的終端機程式啟動的 AI 代理程式，會共用您在此允許的存取權。若要給予某個代理程式獨立的存取權，請在該代理程式的 MCP 設定中，於其引數加入 --name 及您自訂的名稱。該名稱並不能驗證其身分。
# above the question when a program said it was another one than the system found: "It said it was Claude. Inbox Classic checked which program started it: python3."
# review: new
agent-connect-claimed = 它自稱是{ $claimed }。Inbox Classic 檢查了啟動它的程式：{ $program }。

## 說明中依該語言鍵盤標示的按鍵名稱（Windows 與 Linux）

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

## 登入與密碼

# review: new
sign-in-no-refresh = 服務提供者未提供重新整理權杖
# review: new
sign-in-no-account = 服務提供者未說明登入的是哪個帳戶
# review: new
sign-in-not-finished = 登入尚未完成
# review: new
secrets-unavailable = 無法使用{ $store }
# review: new
secrets-unavailable-why = 無法使用{ $store }：{ $error }
# review: new
secrets-windows = 認證管理員
# review: new
secrets-mac = 鑰匙圈
# review: new
secrets-linux = 系統金鑰圈（Secret Service）
# review: new
error-no-such-file = 沒有這個檔案
# review: new
cards-file-too-big = 這個檔案超過匯入通訊錄的大小上限。
# review: new
ui-sender-added = 已將{ $name }新增到通訊錄。
# review: new
ui-sender-known = { $name }已在通訊錄中。
# review: new
ui-sender-none = 這封郵件的寄件者沒有可以新增的電子郵件地址。
# review: new
card-name-needed = 這位連絡人沒有名稱，也沒有電子郵件地址。
# a file of Import Address Book that could not be read: "contacts.vcf: there is no such file"
# review: new
cards-file-failed = { $file }：{ $reason }

## 一次性代碼：含有登入或驗證代碼的郵件最上方的卡片

# the domain the code is for, which signed the message
# review: new
otp-heading = 來自{ $domain }的代碼
# review: new
otp-copy = 複製
# review: new
otp-note = 請只在{ $domain }的網頁上輸入此代碼。
# review: new
otp-old = 這個代碼是在您開啟郵件的一小時多以前寄出的，可能已經過期。

# how many are invited, in the card of an event
# review: new
event-attendees = { $count }位與會者

# the first line of a new message's notification when it has a code, for a domain that signed it
# review: new
otp-notification = { $code }是您在{ $domain }的代碼

## OpenPGP 金鑰 (keys.rs)
# review: new
pgp-key-valid = 有效
# review: new
pgp-key-expires = 有效期限至{ $date }
# review: new
pgp-key-expired = 已於{ $date }過期
# review: new
pgp-key-revoked = 已撤銷
# review: new
pgp-key-revoked-why = 已撤銷：{ $reason }
# review: new
pgp-key-not-valid = 無效
# review: new
pgp-key-locked = 無法使用：在{ $store }中找不到其保護金鑰。請確認存放區可以使用且已解除鎖定。如果遺失保護金鑰，請匯入私密金鑰備份。
# review: new
pgp-source-own = 在 Inbox Classic 中建立
# review: new
pgp-source-file = 從檔案匯入
# review: new
pgp-source-paste = 貼上
# review: new
pgp-source-attachment = 來自郵件
# review: new
pgp-source-vcard = 來自連絡人名片
# review: new
pgp-source-wkd = 來自寄件者的郵件服務提供者
# review: new
pgp-source-keyserver = 來自 keys.openpgp.org
# review: new
pgp-source-autocrypt = 來自郵件的 Autocrypt 標頭
# review: new
pgp-error-no-store = 您私密金鑰的保護金鑰存放在{ $store }中，但目前無法使用：{ $error }
# review: new
pgp-error-wrong-passphrase = 密語不正確。
# review: new
pgp-error-not-a-key = 這不是 OpenPGP 金鑰。
# review: new
pgp-error-too-large = 金鑰太大。
# review: new
pgp-error-unusable = 無法使用這個金鑰。它可能缺少合適的簽署或加密金鑰，或使用了不支援的密碼編譯方式。
# review: new
pgp-imported-private = { $count ->
    [1] 已匯入您的私密金鑰。
   *[other] 已匯入{ $count }個私密金鑰。
}
# review: new
pgp-imported-public = { $count ->
    [1] 已匯入一個金鑰。
   *[other] 已匯入{ $count }個金鑰。
}
# review: new
pgp-imported-pending = { $addresses }已在使用另一個金鑰：新的金鑰會先保留在連絡人中，直到您選擇使用它。
# review: new
pgp-error-needs-passphrase = 私密金鑰受到密語保護。請輸入密語以匯入金鑰。
# review: new
pgp-error-mismatch = 私密金鑰與其公開金鑰不相符，可能已遭竄改。
# review: new
pgp-file-name-public = { $who }公開金鑰.asc
# review: new
pgp-file-name-private = { $who }私密金鑰備份.asc
# review: new
pgp-pending = 已於{ $date }找到{ $address }的另一個金鑰。

## 讀取已簽署及加密的郵件 (protect.rs)
# review: new
pgp-part-verified = 由{ $signer }簽署，金鑰已驗證
# review: new
pgp-part-signed = 由{ $signer }簽署（金鑰未驗證）
# review: new
pgp-part-other = 由{ $signer }簽署，但簽署者不是寄件者
# review: new
pgp-part-unknown-key = 已簽署，但金鑰不明
# review: new
pgp-part-not-signed = 未簽署
# review: new
pgp-part-not-checked = 未檢查簽章
# review: new
pgp-part-encrypted = 已加密。{ $signature }
# review: new
pgp-part-no-key = 已使用您沒有的金鑰加密
# review: new
pgp-part-changed = 加密的部分未通過完整性檢查，因此不顯示
# review: new
pgp-part-unprotected = 加密時未防範竄改，因此不顯示
# review: new
pgp-part-broken = 無法讀取加密的部分
# review: new
pgp-why-mismatch = 簽章與這段文字不符
# review: new
pgp-why-weak-hash = 簽章使用的{ $hash }已不再安全
# review: new
pgp-why-key-expired = 在金鑰於{ $date }過期之後簽署
# review: new
pgp-why-key-revoked = 以已撤銷的金鑰簽署
# review: new
pgp-why-not-signing-key = 以不允許簽署的金鑰簽署
# review: new
pgp-why-from-future = 簽章的日期在未來
# review: new
pgp-why-signature-expired = 簽章已過期
# review: new
pgp-why-key-not-valid = 以無效的金鑰簽署
# review: new
pgp-why-not-for-you = 簽署給其他收件者，再轉給您
# review: new
pgp-why-not-key-in-use = 以不同於{ $address }目前使用的金鑰簽署
# review: new
pgp-part-pictures-loaded = { $label }。已從網際網路載入圖片
# review: new
pgp-error-no-own-key = 您沒有{ $address }的金鑰可用來簽署或加密。請在「工具 > 加密金鑰」中建立一個，或關閉「簽署」與「加密」。
# review: new
pgp-error-missing-keys = { $count ->
    [1] 這位收件者沒有可用的加密金鑰：{ $addresses }。
   *[other] 這些收件者沒有可用的加密金鑰：{ $addresses }。
}
# review: new
pgp-error-encrypted-quote = 這封郵件包含來自加密郵件的文字、圖片或附件，只能以加密方式傳送。請開啟「加密」，或移除所有這類內容。
# review: new
pgp-error-protect = 無法簽署或加密郵件：{ $reason }
# review: new
pgp-found-keys = 已找到下列地址的金鑰：{ $addresses }。
# review: new
pgp-found-none = 找不到{ $addresses }的金鑰。請要求對方將公開金鑰寄給您。
# review: new
pgp-found-no-key = 找不到金鑰。
# review: new
pgp-find-unavailable = 目前無法查詢金鑰：{ $error }
# review: new
pgp-publish-pending = keys.openpgp.org 已將確認連結寄到下列地址：{ $addresses }。請確認每個地址，其他人才能透過該地址找到您的金鑰。
# review: new
pgp-publish-done = 您的金鑰已在 keys.openpgp.org 上針對{ $addresses }發佈。
# review: new
pgp-publish-failed = 無法發佈金鑰：{ $error }
# review: new
pgp-keyserver-off = 已在{ $settings }中關閉在 keys.openpgp.org 上查詢金鑰。
# the compose window with Sign and Encrypt: the line under the fields, each recipient's key, the questions
# review: new
pgp-compose-encrypted = { $count ->
    [1] 傳送時會為您與{ $addresses }加密並簽署。
   *[other] 傳送時會為您與{ $count }位收件者加密並簽署。
}
# review: new
pgp-compose-encrypt-ready = 傳送時會加密並簽署。請新增您擁有其金鑰的收件者。
# review: new
pgp-compose-missing = { $count ->
    [1] { $addresses }沒有可用的金鑰，因此郵件還無法加密。
   *[other] 有{ $count }位收件者沒有可用的金鑰，因此郵件還無法加密：{ $addresses }。
}
# review: new
pgp-compose-looking = 正在尋找{ $addresses }的金鑰...
# review: new
pgp-compose-signed = 傳送時會簽署：收件者可以檢查已簽署的內容是否未經變更。他們還必須驗證您金鑰的擁有者。
# review: new
pgp-compose-reply-clear = 未加密，但所回覆或轉寄的郵件是加密的。
# review: new
pgp-compose-encrypted-files = 已附加加密郵件中的檔案，因此這封郵件只能以加密方式傳送。請開啟「加密」，或移除這些檔案。
# review: new
pgp-compose-sign-tip = 簽署郵件，讓收件者可以檢查其內容。他們還必須驗證您金鑰的擁有者
# review: new
pgp-compose-sign-tip-encrypted = 加密的郵件一律會簽署
# review: new
pgp-compose-encrypt-tip = 加密郵件，只有您與收件者能夠閱讀
# review: new
pgp-compose-make-key = 您還沒有{ $address }的金鑰。要立即建立嗎？有了金鑰，您的郵件就可以簽署及加密。
# review: new
pgp-compose-key-unusable = 無法使用您{ $address }的金鑰（{ $state }）。請開啟「加密金鑰」匯入其備份，或建立新的金鑰。
# review: new
pgp-compose-encrypt-off-quote = 這封郵件包含來自加密郵件的文字、圖片或附件。不加密的話，必須移除所有這類內容才能傳送。仍要關閉加密嗎？
# review: new
pgp-compose-encrypt-off-reply = 這封郵件回覆或轉寄了一封加密郵件。不加密的話，傳遞途中經手您郵件的任何人都能讀取它。要關閉加密嗎？
# review: new
pgp-recipient-verified = 金鑰已驗證
# review: new
pgp-recipient-found = 金鑰未驗證
# review: new
pgp-recipient-own = 您自己的金鑰
# review: new
pgp-recipient-looking = 正在尋找金鑰...
# review: new
pgp-recipient-missing = 沒有金鑰
# review: new
pgp-recipient-not-found = 沒有金鑰：{ $date }時找不到
# review: new
pgp-recipient-unusable = 無法使用金鑰：{ $state }
# review: new
pgp-recipients-intro = 郵件會使用每位收件者的金鑰以及您的金鑰加密。
# review: new
pgp-recipients-intro-missing = { $count ->
    [1] 有一位收件者沒有可用的加密金鑰。請尋找金鑰或移除該收件者。必須先移除所有來自加密郵件的內容，才能不加密傳送。
   *[other] 有{ $count }位收件者沒有可用的加密金鑰。請尋找他們的金鑰或移除這些收件者。必須先移除所有來自加密郵件的內容，才能不加密傳送。
}
# review: new
pgp-details-part = 第{ $number }部分：{ $label }
# review: new
attachment-from-part = 來自第{ $number }部分：{ $label }
# review: new
pgp-details-signed = 於{ $when }以金鑰{ $key }簽署
# review: new
pgp-details-unknown-key = 以您沒有的金鑰{ $key }簽署
# review: new
pgp-details-opened = 已使用您的金鑰{ $key }解密
# review: new
pgp-details-for = 已加密給{ $keys }
# review: new
pgp-details-plain = 未簽署也未加密
# review: new
pgp-bar-parts = 這封郵件有{ $count }個部分：{ $list }。每個部分都會標示其保護方式。
# review: new
pgp-bar-count-verified = { $count }個已驗證
# review: new
pgp-bar-count-encrypted-signed = { $count }個已加密並簽署
# review: new
pgp-bar-count-encrypted = { $count }個已加密
# review: new
pgp-bar-count-signed = { $count }個已簽署
# review: new
pgp-bar-count-warning = { $count }個需要注意
# review: new
pgp-bar-count-neutral = { $count }個沒有經確認的簽章
# the setup file: settings, accounts, contacts and keys carried to another computer
# review: new
setup-part-settings = 設定
# review: new
setup-part-preferences = 視窗偏好設定
# review: new
setup-part-accounts = 帳戶
# review: new
setup-part-sign-in-apps = 登入應用程式
# review: new
setup-part-contacts = 連絡人與群組
# review: new
setup-part-keys = 加密金鑰
# review: new
setup-part-rules = 郵件規則
# review: new
setup-part-trusted-senders = 信任的寄件者
# review: new
setup-holds-settings = { $count }項設定
# review: new
setup-holds-preferences = { $count }項偏好設定
# review: new
setup-holds-accounts = { $count }個帳戶
# review: new
setup-holds-sign-in-apps = { $count }個登入應用程式
# review: new
setup-holds-built-in = 開啟了哪些內建登入應用程式
# review: new
setup-holds-contacts = { $count }位連絡人
# review: new
setup-holds-groups = { $count }個群組
# review: new
setup-holds-own-keys = { $count }個您自己的金鑰
# review: new
setup-holds-contact-keys = { $count }個連絡人的金鑰
# review: new
setup-holds-rules = { $count }條規則
# review: new
setup-holds-trusted-senders = { $count }位信任的寄件者
# review: new
setup-sign-in-password = 密碼
# review: new
setup-account-secret-password = 其密碼包含在檔案中。
# review: new
setup-account-secret-token = 其儲存的登入認證包含在檔案中。
# review: new
setup-account-asks-password = 匯入後會要求輸入其密碼。
# review: new
setup-account-signs-in-again = 匯入後您需要重新登入。
# review: new
setup-account-here = 這裡已設定此帳戶，因此會略過。
# review: new
setup-account-no-app = 它使用{ $app }登入，但這裡尚未設定該應用程式。請一併匯入登入應用程式。
# review: new
setup-invalid-address = 「{ $address }」不是電子郵件地址。
# review: new
setup-invalid-server = { $server }設定中的伺服器名稱、連接埠或安全性選項無效。
# review: new
setup-invalid-user = 沒有使用者名稱。
# review: new
setup-invalid-sign-in = 不支援其登入方式或設定。
# review: new
setup-error-empty = 檔案是空的。
# review: new
setup-error-too-large = 設定檔超過大小上限。
# review: new
setup-error-not-setup = 這個檔案不是 Inbox Classic 設定檔。
# review: new
setup-error-damaged = 設定檔已損毀，無法讀取。
# review: new
setup-error-newer = 此設定檔是由較新版的 Inbox Classic（{ $version }）儲存的。請更新 Inbox Classic 後再匯入一次。
# review: new
setup-error-needs-passphrase = 此設定檔受到密語保護。請輸入儲存時使用的密語。
# review: new
setup-error-wrong-passphrase = 這不是儲存此設定檔時使用的密語。
# review: new
setup-error-changed = 設定檔未通過完整性檢查。它可能已遭竄改或損毀，無法匯入。
# review: new
setup-error-read = 無法讀取設定檔：{ $error }
# review: new
setup-error-write = 無法儲存設定：{ $error }
# review: new
setup-error-no-parts = 請至少選擇一個項目。
# review: new
setup-left-out = { $part }中有{ $count }個項目無法使用，已略過。
# review: new
setup-imported-settings = 已取代設定。
# review: new
setup-imported-preferences = 已取代視窗偏好設定。
# review: new
setup-added-accounts = 已新增{ $count }個帳戶。
# review: new
setup-skipped-here = 這裡已設定{ $address }，因此已略過。
# review: new
setup-skipped-no-app = 已略過{ $address }：它使用{ $app }登入，但這裡尚未設定該應用程式。
# review: new
setup-skipped-invalid = 已略過{ $address }：{ $reason }
# review: new
setup-asks-password = { $address }連線時會要求輸入其密碼。
# review: new
setup-signs-in-again = { $address }連線時會要求您重新登入。
# review: new
setup-added-sign-in-apps = 已新增{ $count }個登入應用程式。
# review: new
setup-skipped-sign-in-apps = 這裡已設定{ $count }個登入應用程式。
# review: new
setup-added-contacts = 已將{ $count }位連絡人新增到通訊錄。
# review: new
setup-skipped-contacts = 通訊錄中已有{ $count }位連絡人。
# review: new
setup-added-groups = 已新增或補齊{ $count }個群組。
# review: new
setup-added-own-keys = 已新增{ $count }個您自己的金鑰。
# review: new
setup-added-contact-keys = 已新增{ $count }個連絡人的金鑰。
# review: new
setup-added-rules = 已新增{ $count }條郵件規則。
# review: new
setup-skipped-rules = 這裡已有{ $count }條郵件規則。
# review: new
setup-skipped-rules-account = { $count }條郵件規則所屬的帳戶不在這裡，因此已略過。
# review: new
setup-rules-waiting = { $count }條郵件規則正在等候帳戶同步時找到其目的地資料夾。
# review: new
setup-added-trusted-senders = 已新增{ $count }位信任的寄件者。
# review: new
setup-nothing = 沒有匯入任何項目。
# review: new
setup-account-servers = { $imap }與{ $smtp }（{ $signin }）
# review: new
setup-file-name = Inbox Classic 設定與帳戶
# review: new
setup-skipped-unreachable = 已略過{ $name }：無法連線到其登入服務或無法檢查。請先在「登入應用程式」中檢查所需的應用程式，再試一次。
# review: new
attachment-runs-programs = 「{ $name }」可能會執行程式，因此 Inbox Classic 不會開啟它。如果您信任其來源，請先儲存再自行開啟。
# review: new
attachment-decrypted-note = 這個附件來自加密郵件。為了在其他應用程式中開啟，Inbox Classic 會在您使用者帳戶的暫存資料夾中儲存一份未加密的副本。啟動時，它會試著移除存放超過一天的副本。
# a bar over the list when the server did not do what the user asked of messages, so they are as they were again
# review: new
undone-move = { $count ->
   *[other] 伺服器未將{ $messages }移至{ $folder }，因此已回到{ $from }：{ $reason }
}
# review: new
undone-delete = { $count ->
   *[other] 伺服器未刪除{ $messages }，因此已回到{ $from }：{ $reason }
}
# review: new
undone-archive = { $count ->
   *[other] 伺服器未封存{ $messages }，因此已回到{ $from }：{ $reason }
}
# review: new
undone-read = { $count ->
   *[other] 伺服器未將{ $messages }標示為已讀取，因此已恢復為未讀取：{ $reason }
}
# review: new
undone-unread = { $count ->
   *[other] 伺服器未將{ $messages }標示為未讀取，因此已恢復為已讀取：{ $reason }
}
# review: new
undone-flags = { $count ->
   *[other] 伺服器未變更{ $messages }的標幟，因此維持原狀：{ $reason }
}

## 附件預覽：郵件中顯示的圖片與 PDF 檔案

# the reading option that turns PDF previews on and off (the apps show it)
# review: new
preview-pdf-option = 在郵件中顯示 PDF 檔案
# the tile of a PDF file while PDF previews are off
# review: new
preview-pdf-off = 郵件中不顯示 PDF 檔案。
# the note where previews are, after the app ended while it was drawing a file of a message: { $option } is the option's name
# review: new
preview-pdf-off-crashed = Inbox Classic 在顯示郵件中的檔案時關閉，因此郵件中不再顯示 PDF 檔案，但仍會顯示圖片。若要再次顯示 PDF 檔案，請在{ $settings }中開啟「{ $option }」。
# under the pages of a PDF file shown in a message: its page count and size ("3 pages, 84 KB")
# review: new
preview-pdf-details = { $count }頁，{ $size }
# what a screen reader says of a page of a PDF file shown in a message
# review: new
preview-page-alt = { $name }，第{ $page }頁，共{ $count }頁
# the link under the pages of a PDF file shown in a message, when it has more pages than are shown
# review: new
preview-more-pages = { $count ->
    [1] 開啟以查看該頁
   *[other] 開啟以查看全部{ $count }頁
}
# after the files shown in a message, when it has more pictures and PDF files than are shown; the list is the
# strip of files over the message
# review: new
preview-more-files = 上方清單中還有{ $count }個檔案
# the tile of a picture or PDF file of a message still downloading (the ellipsis as in reader-downloading)
# review: new
preview-tile-downloading = 正在下載...
# the tile of a picture or PDF file whose size was not read in time when the message was shown: its preview
# comes in its place in a moment (the ellipsis as in reader-downloading)
# review: new
preview-tile-preparing = 正在準備...
# the tile of a picture in a format not shown yet: { $format } is its name (HEIC, AVIF, JPEG XL)
# review: new
preview-tile-format = 尚不支援顯示{ $format }圖片
# the tile of a PDF file that wants a password to open
# review: new
preview-tile-password = 受密碼保護：請開啟檔案以輸入密碼
# the tile of a picture or PDF file over the size or pixel limit
# review: new
preview-tile-too-large = 太大，無法顯示
# the tile of a file that is broken, or not what its name says
# review: new
preview-tile-unreadable = 無法顯示
# the tile of a file that took too long to draw
# review: new
preview-tile-timed-out = 準備預覽花費的時間太長
# the tile of a file that closed the app once while it was drawn: never drawn again
# review: new
preview-tile-crashed = 無法預覽：先前的嘗試被中斷
# the tile of a file while previews are paused after a file took too long, until the app starts again
# review: new
preview-tile-off = 重新啟動 Inbox Classic 前不會顯示
# in a printout, for a file shown in the message that is not printed (a PDF file, a tile): { $details } is its size,
# or a PDF file's pages and size
# review: new
preview-not-printed = 未列印{ $name }（{ $details }）。請開啟檔案以列印。
