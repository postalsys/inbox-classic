# 繁體中文（台灣）草稿，等待母語人士審閱。
# 各平台共用的視窗文字。& 標示 Windows 與 Linux 上按 Alt 加該字母即可選取的功能表項目字母（&& 為 & 符號本身）；
# Mac 不使用。中文寫成「檔案(&F)」，字母放在文字之後的括號中，同一功能表內盡量各用不同字母。

## 功能表

# review: new
menu-file = 檔案(&F)
# review: new
menu-edit = 編輯(&E)
# review: new
menu-view = 檢視(&V)
# review: new
menu-tools = 工具(&T)
# review: new
menu-message = 郵件(&M)
# review: new
menu-help = 說明(&H)
# review: new
menu-layout = 版面配置(&L)
# review: new
menu-sort-by = 排序方式(&B)
# review: new
menu-text-size = 文字大小(&T)
# review: new
menu-folder = 資料夾(&O)
# review: new
menu-insert = 插入(&I)

## 功能表、工具列與系統匣的命令 (core/commands.toml)

# review: new
cmd-new-account = 新增帳戶(&N)...
# review: new
cmd-exit = 結束(&X)
# review: new
cmd-sync = 全部傳送及接收(&V)
# review: new
cmd-mark-read = 標示為已讀取(&M)
# review: new
cmd-mark-unread = 標示為未讀取(&N)
# review: new
cmd-pictures = 下載圖片(&P)
# review: new
cmd-about = 關於 Inbox Classic(&A)
# review: new
cmd-new-mail = 新郵件(&N)
# review: new
cmd-reply = 回覆寄件者(&R)
# review: new
cmd-reply-all = 全部回覆(&Y)
# review: new
cmd-forward = 轉寄(&F)
# review: new
cmd-help = 目錄(&C)
# review: new
cmd-delete = 刪除郵件(&D)
# review: new
cmd-move = 移至資料夾(&V)...
# review: new
cmd-flag = 標幟郵件(&L)
# review: new
cmd-new-folder = 新增資料夾(&N)...
# review: new
cmd-rename-folder = 重新命名資料夾(&R)...
# review: new
cmd-delete-folder = 刪除資料夾(&D)
# review: new
cmd-empty-folder = 清空資料夾(&E)
# review: new
ui-empty-button = 清空
# review: new
cmd-accounts = 帳戶(&A)...
# review: new
cmd-find = 尋找郵件(&F)
# review: new
cmd-save-as = 另存新檔(&S)...
# review: new
cmd-print = 列印(&P)...
# review: new
cmd-import = 匯入郵件(&I)...
# review: new
cmd-outbox = 寄件匣(&O)...
# review: new
cmd-properties = 內容(&R)
# review: new
cmd-mark-all-read = 全部標示為已讀取(&A)
# review: new
cmd-junk = 標示為垃圾郵件(&J)
# review: new
cmd-not-junk = 標示為非垃圾郵件(&O)
# review: new
cmd-archive = 封存(&A)
# review: new
cmd-watch-conversation = 監看交談(&W)
# review: new
cmd-ignore-conversation = 忽略交談(&I)
# review: new
cmd-next-message = 下一封郵件(&N)
# review: new
cmd-previous-message = 上一封郵件(&V)
# review: new
cmd-next-unread = 下一封未讀取郵件(&U)
# review: new
cmd-go-to-folder = 前往資料夾(&G)...
# review: new
cmd-find-in-message = 在這封郵件中尋找(&T)...
# review: new
ui-go-to-prompt = 前往資料夾：
# review: new
ui-find-in-message-hint = 在這封郵件中尋找
# review: new
ui-find-not-found = 這封郵件中沒有「{ $words }」
# review: new
cmd-expand-all-threads = 展開所有交談(&E)
# review: new
cmd-collapse-all-threads = 摺疊所有交談(&O)
# review: new
ui-group-by-conversation = 依交談將郵件分組(&G)
# review: new
cmd-folder-list = 資料夾清單(&F)
# review: new
cmd-layout-automatic = 自動(&A)
# review: new
cmd-layout-classic = 傳統(&C)
# review: new
cmd-layout-columns = 欄式(&O)
# review: new
cmd-sort-date = 日期(&D)
# review: new
cmd-sort-from = 寄件者(&F)
# review: new
cmd-sort-subject = 主旨(&S)
# review: new
cmd-sort-size = 大小(&Z)
# review: new
cmd-sort-ascending = 遞增排序(&A)
# review: new
cmd-sort-descending = 遞減排序(&N)
# review: new
cmd-text-size-largest = 最大(&L)
# review: new
cmd-text-size-larger = 較大(&R)
# review: new
cmd-text-size-medium = 中(&M)
# review: new
cmd-text-size-smaller = 較小(&S)
# review: new
cmd-text-size-smallest = 最小(&T)
# review: new
cmd-hide-ignored = 隱藏忽略的交談(&H)
# review: new
cmd-hide-read = 隱藏已讀取的郵件(&R)
# review: new
cmd-notify = 新郵件通知(&N)
# review: new
cmd-open = 開啟 Inbox Classic(&O)
# review: new
cmd-default-app = 設為預設郵件應用程式(&D)...
# review: new
cmd-view-source = 郵件原始碼(&S)
# review: new
cmd-ai-agents = AI 代理程式(&A)...
# review: new
cmd-options = 選項(&P)...
# review: new
cmd-message-rules = 郵件規則(&R)...
# review: new
cmd-encryption-keys = 加密金鑰(&Y)...
# review: new
cmd-create-rule-from-message = 從郵件建立規則(&T)...
# review: new
cmd-unsubscribe = 取消訂閱郵寄清單(&U)...
# review: new
cmd-select-all = 全選(&L)
# review: new
cmd-undo = 復原(&U)
# review: new
cmd-copy = 複製到資料夾(&C)...
# review: new
cmd-address-book = 通訊錄(&B)...
# review: new
cmd-add-sender-to-book = 將寄件者新增到通訊錄(&K)
# review: new
cmd-import-address-book = 匯入通訊錄(&B)...
# review: new
cmd-export-address-book = 匯出通訊錄(&E)...
# review: new
cmd-export-setup = 匯出設定與帳戶(&G)...
# review: new
cmd-import-setup = 匯入設定與帳戶(&T)...
# review: new
cmd-compose-sign = 數位簽署(&S)
# review: new
cmd-compose-encrypt = 加密(&E)
# review: new
cmd-attach-my-key = 附加我的公開金鑰(&P)

## 系統匣圖示的功能表

# review: new
tray-check = 檢查新郵件(&C)
# review: new
tray-no-accounts = 尚無帳戶

## 多個平台的視窗共用的文字

# review: new
ui-tb-create-mail = 建立郵件
# review: new
ui-tb-reply = 回覆
# review: new
ui-tb-reply-all = 全部回覆
# review: new
ui-tb-forward = 轉寄
# review: new
ui-tb-print = 列印
# review: new
ui-tb-delete = 刪除
# review: new
ui-tb-junk = 垃圾郵件
# review: new
ui-tb-not-junk = 非垃圾郵件
# review: new
ui-tb-archive = 封存
# review: new
ui-tb-previous = 上一封
# review: new
ui-tb-next = 下一封
# review: new
ui-previous-tip = 上一封郵件
# review: new
ui-next-tip = 下一封郵件
# review: new
ui-tb-sync = 傳送/接收
# review: new
ui-tb-mark-read = 標示為已讀取
# review: new
ui-tb-mark-unread = 標示為未讀取
# review: new
ui-still-running = Inbox Classic 仍在執行中
# review: new
ui-no-subject = （無主旨）
# review: new
ui-quoted = 「{ $subject }」
# review: new
ui-newest-from = 最新郵件來自{ $sender }：{ $subject }
# review: new
ui-new-messages = { $count }封新郵件
# review: new
ui-outbox-waiting = 寄件匣中有{ $count }封郵件
# review: new
ui-outbox-waits = { $subject }正在寄件匣中等候
# review: new
ui-outbox-sending = 正在傳送{ $subject }...
# review: new
ui-from-account = 來自{ $account }
# review: new
ui-sign-in-refused = 登入{ $account }遭到拒絕，或工作階段已過期。
# review: new
ui-sign-in-again-ask = 要在瀏覽器中重新登入嗎？
# review: new
ui-sign-in-again-failed = 無法重新登入：{ $reason }
# review: new
ui-unknown-reason = 原因不明
# review: new
ui-checking = 正在檢查{ $account }的新郵件...
# review: new
ui-done = 完成
# review: new
ui-sent-at = 已於{ $time }傳送{ $subject }
# review: new
ui-draft-saved = 郵件已儲存到草稿
# review: new
ui-draft-not-saved = 郵件未儲存到草稿：{ $reason }
# review: new
ui-about-core = 核心版本{ $version }
# review: new
ui-add-account-first = 請先新增郵件帳戶。
# review: new
ui-add-account-first-link = 請先新增郵件帳戶，然後再按一次電子郵件連結。
# review: new
ui-default-app-is = Inbox Classic 是您的預設郵件應用程式：電子郵件連結會在這裡開啟新郵件。
# review: new
ui-select-message-first = 請先選取郵件。
# review: new
ui-store-not-opened = 無法開啟郵件存放區。
# review: new
ui-store-or-cert-not-opened = 無法開啟郵件存放區或憑證檔案。
# review: new
ui-help-title = Inbox Classic 說明
# review: new
ui-help-missing = 這份 Inbox Classic 缺少說明。
# review: new
ui-ok = 確定
# review: new
ui-cancel = 取消
# review: new
ui-close = 關閉
# review: new
ui-col-subject = 主旨
# review: new
ui-col-from = 寄件者
# review: new
ui-col-to = 收件者
# review: new
ui-col-received = 收件日期
# the column of the glasses of a watched conversation (and the sign of an ignored one)
# a notification of new mail in a watched conversation, over who it is from
# review: new
ui-watched-conversation = 監看的交談
# review: new
ui-col-sent = 寄件日期
# review: new
ui-col-size = 大小
# review: new
ui-col-folder = 資料夾
# review: new
ui-col-account = 帳戶
# review: new
ui-col-queued = 排入佇列
# review: new
ui-col-status = 狀態
# review: new
ui-outbox-title = 寄件匣
# review: new
ui-outbox-status-waiting = 等候中
# review: new
ui-outbox-status-not-sent = 未傳送：{ $reason }
# This message is still queued, during the grace period before an agent’s send.
# review: new
ui-outbox-status-agent = 由 AI 代理程式排入佇列，預定於{ $time }傳送
# review: new
ui-outbox-delete-ask = 要刪除這封郵件而不傳送嗎？
# review: new
ui-open-link = 開啟連結
# review: new
ui-edit-link = 編輯連結...
# review: new
ui-remove-link = 移除連結
# review: new
ui-insert-attachment = 插入附件
# review: new
ui-insert-picture = 插入圖片
# review: new
ui-filter-all = 所有檔案
# review: new
ui-filter-pictures = 圖片
# review: new
ui-filter-messages = 郵件
# review: new
ui-save-attachment-as = 另存附件
# review: new
ui-not-sent = 無法傳送郵件。
# review: new
ui-attachment-forgotten = 您寫了「{ $word }」，但沒有附加任何檔案。仍要傳送郵件嗎？
# review: new
ui-send-anyway = 仍要傳送
# review: new
ui-go-back = 返回
# review: new
ui-not-saved = 無法儲存郵件。
# review: new
ui-saving-draft = 正在儲存到草稿...
# review: new
ui-compose-saved-at = 已於{ $time }儲存到草稿
# review: new
ui-compose-restored = Inbox Classic 意外關閉後已還原
# review: new
ui-compose-not-saved = 未儲存到草稿：{ $reason }
# review: new
ui-save-changes-ask = 要將這封郵件的變更儲存到草稿嗎？
# review: new
ui-new-message-title = 新郵件
# review: new
ui-link-invalid = 請輸入網址（https://...）或電子郵件連結（mailto:...）。
# review: new
ui-link-address = 網址：
# review: new
ui-hyperlink = 超連結
# review: new
ui-hyperlink-intro = 選取的文字所連結的網址。
# review: new
ui-edit-hyperlink = 編輯超連結
# review: new
ui-edit-hyperlink-intro = 連結的目的地網址。清除網址即可移除連結並保留文字。
# review: new
ui-not-a-picture = 無法將檔案讀取為 10 MB 以內的 PNG、JPEG、GIF 或 WebP 圖片。
# review: new
ui-format-color = 字型色彩
# review: new
ui-format-numbers = 編號清單
# review: new
ui-format-bullets = 項目符號清單
# review: new
ui-format-outdent = 減少縮排
# review: new
ui-format-indent = 增加縮排
# review: new
ui-format-left = 靠左對齊
# review: new
ui-format-center = 置中
# review: new
ui-format-right = 靠右對齊
# review: new
ui-format-line = 插入水平線
# review: new
ui-tb-send = 傳送
# review: new
ui-tb-save = 儲存
# review: new
ui-tb-attach = 附加
# review: new
ui-tb-sign = 簽署
# review: new
ui-tb-encrypt = 加密
# review: new
ui-field-keys = 金鑰：
# review: new
ui-field-from = 寄件者：
# review: new
ui-field-to = 收件者：
# review: new
ui-field-cc = 副本：
# review: new
ui-field-bcc = 密件副本：
# review: new
ui-field-subject = 主旨：
# review: new
ui-field-attach = 附件：
# review: new
ui-signature = 簽名
# review: new
ui-signature-hint = 加在這個帳戶的新郵件、回覆與轉寄郵件中。
# review: new
ui-signature-not-saved = 無法儲存簽名。
# review: new
ui-all-inboxes = 所有收件匣
# review: new
ui-all-sent = 所有寄件備份
# review: new
ui-all-drafts = 所有草稿
# review: new
ui-flagged-folder = 已標幟
# review: new
ui-all-folders = 所有資料夾
# review: new
ui-the-account = 此帳戶
# review: new
ui-folder-name = 資料夾名稱：
# review: new
ui-find-hint = 搜尋郵件
# review: new
ui-find-tip = 搜尋郵件主旨、寄件者、收件者、附件名稱與郵件內文。
# review: new
ui-clear-search = 清除搜尋
# review: new
ui-no-match = 沒有符合「{ $words }」的郵件。
# review: new
ui-no-match-all = 搜尋範圍包括所有資料夾中的主旨、寄件者、收件者、附件名稱與郵件內文。請檢查拼字，或減少字詞再試一次。
# review: new
ui-no-match-in = 在{ $folder }中搜尋的範圍包括主旨、寄件者、收件者、附件名稱與郵件內文。請檢查拼字，或減少字詞再試一次。
# review: new
ui-no-items = 這個檢視中沒有任何項目。
# review: new
ui-choose-folder = 選擇資料夾以查看其中的郵件。
# review: new
ui-unsubscribe = 取消訂閱
# review: new
ui-open-in-calendar = 在行事曆中開啟
# review: new
ui-pictures-blocked = 已封鎖部分圖片，以減少寄件者的追蹤。
# review: new
ui-not-shown = 無法顯示郵件。
# review: new
ui-attachment-not-read = 無法讀取附件。
# review: new
ui-attachment-not-saved = 無法儲存附件。
# review: new
ui-not-downloaded = 郵件尚未下載。
# review: new
ui-leave-list = 要退出這個郵寄清單嗎？
# review: new
ui-leave-one-click = Inbox Classic 會傳送取消訂閱要求到{ $target }。不會開啟網頁，也不會寄出電子郵件。
# review: new
ui-leave-mail = 若要取消訂閱，請寄送電子郵件到{ $target }。Inbox Classic 會為您準備好郵件，傳送郵件即可確認。
# review: new
ui-leave-web = 郵寄清單的取消訂閱網頁會在瀏覽器中開啟（{ $target }）。
# review: new
ui-unsubscribing = 正在傳送取消訂閱要求到{ $target }...
# review: new
ui-cannot-unsubscribe = 這封郵件沒有提供取消訂閱的方式。
# review: new
ui-unsubscribed = 郵寄清單已接受取消訂閱要求。
# review: new
ui-not-unsubscribed = 無法取消訂閱：{ $reason }
# the bar over a message of a mailing list. It names the list by a domain only, never by a name the sender chose
# review: new
ui-list-bar = 這封郵件來自郵寄清單（{ $domain }）。
# review: new
ui-list-bar-plain = 這封郵件來自郵寄清單。
# $date is a day as the system writes it ("21 November 2026")
# review: new
ui-list-bar-asked = 您已於{ $date }要求退出這個清單。
# a message that arrived more than two days after the request: the list did not stop
# review: new
ui-list-bar-came-after = 您已於{ $date }要求退出這個清單，但這封郵件是在那之後寄達的。
# review: new
ui-list-bar-opened = 您已於{ $date }開啟清單的網頁以退出清單。
# review: new
ui-list-bar-failed = 清單未接受要求：{ $reason }
# the bar's button; it asks first
# review: new
ui-unsubscribe-ask = 取消訂閱...
# review: new
ui-unsubscribe-again = 再次取消訂閱...
# review: new
ui-event-span = { $start }至{ $end }
# review: new
ui-event-floating = { $when }（依原文時間，未轉換時區）
# review: new
ui-invitation = 邀請：{ $title }
# review: new
ui-invitation-updated = 已更新的邀請：{ $title }
# review: new
ui-invitation-canceled = 已取消：{ $title }
# review: new
ui-invitation-answer = 邀請回覆：{ $title }
# review: new
ui-no-title = （無標題）
# review: new
ui-organizer = 召集人：{ $name }
# review: new
ui-invitation-not-read = 無法讀取邀請。
# review: new
ui-no-calendar = 無法開啟邀請（.ics 檔案）。請確認已有行事曆應用程式與此檔案類型建立關聯。
# review: new
ui-messages-not-changed = 無法變更郵件。
# review: new
ui-new-folder-in-selected = 新資料夾會建立在選取的資料夾中。
# review: new
ui-new-folder-at-top = 新資料夾會建立在帳戶的最上層。
# review: new
ui-folder-not-created = 無法建立資料夾。
# review: new
ui-folder-not-renamed = 無法重新命名資料夾。
# review: new
ui-folder-not-deleted = 無法刪除資料夾。
# review: new
ui-rename-folder-intro = 請輸入資料夾「{ $folder }」的新名稱。
# review: new
ui-properties-of = { $subject }內容
# review: new
ui-internet-headers = 這封郵件的網際網路標頭：
# review: new
ui-save-messages-in = 將郵件儲存在
# review: new
ui-save-message-as = 另存郵件
# review: new
ui-import-choose-folder = 請先選擇要匯入郵件的資料夾。
# review: new
ui-add-account-title = 新增郵件帳戶
# review: new
ui-accounts-title = 帳戶
# review: new
ui-security-none = 無（不加密）
# review: new
ui-field-required = { $field }為必填。
# review: new
ui-email-invalid = 電子郵件地址無效。
# review: new
ui-ports-invalid = 連接埠是 1 到 65535 之間的數字。
# review: new
ui-looking-up = 正在查詢{ $domain }的設定...
# review: new
ui-found-none = 請輸入電子郵件服務提供者給您的帳戶資料。
# review: new
ui-found-change = 如果服務提供者給您的設定不同，請變更這些設定。
# review: new
ui-found-guess = 找不到這個地址的設定。建議的伺服器名稱是推測出來的，請向服務提供者確認。
# review: new
ui-found-mx = Inbox Classic 已辨識出您的電子郵件服務提供者，並填入其伺服器設定。
# review: new
ui-found-srv = 這些設定是從您網域的 DNS 記錄中找到的。
# review: new
ui-found-autodiscover = 這些設定是透過 Microsoft 自動探索（Exchange）找到的。
# review: new
ui-found-other = 已找到這個地址的設定。
# review: new
ui-app-password-needed = 服務提供者：{ $provider }。如果您的帳戶支援應用程式密碼，請在其安全性設定中建立一組，並輸入到下一個表單的「密碼」欄位。否則，請在可用時改用瀏覽器登入。
# review: new
ui-app-password-open = 要在瀏覽器中開啟{ $provider }的說明嗎？
# review: new
ui-plain-warning = 不加密的話，任何攔截您網路流量的人都能讀取您的密碼與郵件。只有在連線已透過其他方式保護時才繼續。單靠區域網路並不能提供加密。
# review: new
ui-continue-ask = 要繼續嗎？
# review: new
ui-add-sign-in-app = 新增登入應用程式...
# review: new
ui-turned-off = { $name }已在這部電腦上關閉。
# review: new
ui-off-here = 已在這部電腦上關閉。
# review: new
ui-why = 為什麼？
# review: new
ui-more-sign-in = 更多登入選項...
# review: new
ui-other-account = 若要新增其他電子郵件帳戶，請輸入您的電子郵件地址，以及收件者會看到的名稱。接著會查詢伺服器設定。
# review: new
ui-field-account-name = 帳戶名稱：
# review: new
ui-field-name = 顯示名稱：
# review: new
ui-field-email = 電子郵件地址：
# review: new
ui-field-user = 使用者名稱：
# review: new
ui-field-password = 密碼：
# review: new
ui-field-imap-host = 內送（IMAP）伺服器：
# review: new
ui-field-imap-port = IMAP 連接埠：
# review: new
ui-field-imap-security = IMAP 安全性：
# review: new
ui-field-smtp-host = 外寄（SMTP）伺服器：
# review: new
ui-field-smtp-port = SMTP 連接埠：
# review: new
ui-field-smtp-security = SMTP 安全性：
# review: new
ui-field-other-addresses = 您用來寄信的其他地址：
# review: new
ui-sign-in-not-started = 無法啟動瀏覽器登入。
# review: new
ui-sign-in-in-browser = 請在已開啟的瀏覽器視窗中登入{ $account }，然後回到這裡。
# review: new
ui-sign-in-failed = 無法登入：{ $reason }
# review: new
ui-account-not-saved = 無法儲存帳戶。
# review: new
ui-start-intro = Gmail、Google Workspace、Outlook.com 與 Microsoft 365：請在 Google 或 Microsoft 自己的網頁上登入。密碼是在那裡輸入，絕不會輸入到 Inbox Classic 中。
# review: new
ui-start-intro-apps = 使用您的登入應用程式透過瀏覽器登入（更多登入選項），或在下方輸入您的名稱與地址，新增任何電子郵件帳戶。
# review: new
ui-use-app-password = 使用應用程式密碼
# review: new
ui-the-provider = 服務提供者
# review: new
ui-provider-intro = 請在{ $provider }的網站上登入{ $email }。您的密碼不會提供給 Inbox Classic。如果您的帳戶允許在郵件中使用應用程式密碼，也可以使用在其安全性設定中建立的應用程式密碼。Outlook.com 與 Microsoft 365 只接受瀏覽器登入。
# review: new
ui-provider-intro-apps = 請使用您的登入應用程式（更多登入選項），在{ $provider }的網站上登入{ $email }。如果您的帳戶允許在郵件中使用應用程式密碼，也可以使用在其安全性設定中建立的應用程式密碼。Outlook.com 與 Microsoft 365 只接受瀏覽器登入。
# review: new
ui-finish = 完成
# review: new
ui-logon = 登入
# review: new
ui-enter-password = 請輸入{ $account }的密碼。
# review: new
ui-signs-in-with = 登入應用程式：{ $app }。登入會在瀏覽器中進行，帳戶會使用這個應用程式的伺服器。
# review: new
ui-keep-password = 若要保留目前的密碼，請將密碼欄位留白。
# review: new
ui-remove-account = 移除帳戶
# review: new
ui-remove-account-ask = 要從 Inbox Classic 移除這個帳戶嗎？其本機資料，包括在寄件匣中等候的郵件與儲存的登入認證，都會被移除。伺服器上的郵件會保留在伺服器上。
# review: new
ui-col-email = 電子郵件地址
# review: new
ui-col-incoming = 內送伺服器
# review: new
ui-type-email = 請輸入您的電子郵件地址，例如 name@example.com。
# review: new
ui-ai-agent = AI 代理程式
# review: new
ui-ai-agent-access = AI 代理程式存取權
# review: new
ui-ai-agents = AI 代理程式
# review: new
ui-program-path = 程式：{ $path }
# review: new
ui-it-may = 允許的動作：
# review: new
ui-accounts-it-may-use = 允許的帳戶：
# review: new
ui-send-message-ask = 要傳送郵件嗎？
# review: new
ui-col-name = 名稱
# review: new
ui-never = 從未
# review: new
ui-connect-agent = 連接 AI 代理程式
# review: new
ui-connect-agent-intro = 將下列內容加入代理程式的 MCP 伺服器（Claude Desktop：Settings > Developer > Edit Config）：
# review: new
ui-col-program = 程式
# review: new
ui-col-may = 權限
# review: new
ui-col-last-used = 上次使用
# review: new
ui-col-when = 時間
# review: new
ui-col-what = 動作
# review: new
ui-sign-in-app = 登入應用程式
# review: new
ui-sign-in-apps = 登入應用程式
# review: new
ui-add-sign-in-app-title = 新增登入應用程式
# review: new
ui-preset-app-name = { $provider }登入應用程式
# review: new
ui-issuer-not-checked = 無法檢查簽發者
# review: new
ui-checking-issuer = 正在檢查{ $issuer }...
# review: new
ui-issuer-unusable = 無法使用此簽發者：{ $reason }
# review: new
ui-issuer-usable = 可以使用此簽發者。
# review: new
ui-sign-in-app-not-saved = 無法儲存登入應用程式：{ $reason }
# review: new
ui-check = 檢查(&H)
# review: new
ui-fill-in-for = 使用以下服務提供者的設定：
# review: new
ui-app-name = 名稱：
# review: new
ui-issuer = 簽發者：
# review: new
ui-client-id = 用戶端識別碼：
# review: new
ui-client-secret = 用戶端密碼：
# review: new
ui-scopes = 權限範圍（scopes）：
# review: new
ui-imap-server = IMAP 伺服器：
# review: new
ui-smtp-server = SMTP 伺服器：
# review: new
ui-redirect-uri = 重新導向 URI：
# review: new
ui-sign-in-app-intro = 登入應用程式是您向服務提供者註冊的 OAuth 用戶端，用於透過瀏覽器登入。選擇服務提供者以填入其設定，然後加入用戶端識別碼，以及服務提供者提供的用戶端密碼（如果有的話）。
# review: new
ui-remove-secret = 已儲存用戶端密碼。輸入新的密碼即可取代，或移除已儲存的密碼
# review: new
ui-register-it = 向服務提供者註冊應用程式
# review: new
ui-built-in-note = { $name }是內建的。您只能變更是否在新帳戶中提供它。
# review: new
ui-client-with-secret = 用戶端識別碼：{ $client }，有用戶端密碼。
# review: new
ui-client-public = 用戶端識別碼：{ $client }，公用用戶端（沒有密碼）。
# review: new
ui-no-accounts = 沒有帳戶
# review: new
ui-remove-sign-in-app = 移除登入應用程式
# review: new
ui-remove-sign-in-app-ask = 要移除登入應用程式{ $name }及其儲存的用戶端密碼嗎？
# review: new
ui-sign-in-app-not-removed = 未移除登入應用程式。{ $reason }
# review: new
ui-sign-in-apps-intro = 登入應用程式讓帳戶可以透過瀏覽器登入。未勾選的應用程式不會在新帳戶中提供；已在使用它的帳戶可繼續運作。
# review: new
ui-col-issuer = 簽發者
# review: new
ui-col-used-by = 使用的帳戶
# review: new
ui-options-system-default = 系統預設（{ $language }）
# the settings window (core/settings.toml): its pages and the titles of its groups, Windows' Apply, and the words of
# the language the three platforms share
# review: new
ui-settings-general = 一般
# review: new
ui-settings-reading = 閱讀
# review: new
ui-settings-new-mail = 新郵件
# review: new
ui-settings-sending = 傳送
# review: new
ui-settings-default-apps = 預設應用程式
# review: new
ui-settings-message-list = 郵件清單
# review: new
ui-settings-messages = 郵件
# review: new
ui-settings-encryption = 加密
# review: new
ui-settings-language = 語言
# a group's title as the label before its first control, in the Mac's panes: the colon as the language writes it
# review: new
ui-settings-label = { $label }：
# review: new
ui-apply = 套用(&A)
# review: new
ui-language-label = 語言(&L)：
# review: new
ui-restart-note = 重新啟動 Inbox Classic 即可變更語言。
# review: new
ui-restart-ask = Inbox Classic 重新啟動後會以{ $language }顯示。要立即重新啟動嗎？
# review: new
ui-notify-new-mail = 有新郵件時通知我(&N)
# review: new
ui-new-folder-title = 新增資料夾
# review: new
ui-rename-folder-title = 重新命名資料夾
# review: new
ui-delete-folder-question = 要刪除資料夾「{ $folder }」及其中的郵件與資料夾嗎？伺服器上的資料夾也會一併刪除。
# review: new
ui-properties = 內容(&S)
# review: new
ui-account-sync = 傳送及接收(&V)
# review: new
ui-account-properties = 內容(&R)...
# review: new
ui-account-move-up = 上移(&U)
# review: new
ui-account-move-down = 下移(&W)
# review: new
ui-menu-open = 開啟(&O)
# review: new
ui-menu-flag = 標幟(&G)
# review: new
ui-menu-view-source = 檢視原始碼(&U)
# review: new
ui-save-attachments = 儲存附件
# review: new
ui-attachment-open = 開啟
# review: new
ui-attachment-save-as = 另存新檔...
# review: new
ui-attachment-save-all = 全部儲存...
# the strip's menu: a checked item for a picture or PDF file, drawn in the message (checked) or not
# review: new
ui-attachment-show-in-message = 在郵件中顯示
# review: new
ui-attachments-strip = 附件
# review: new
ui-attachment-note-title = 開啟這個檔案
# review: new
ui-attachment-program-tip = 這類檔案停用「開啟」：它可能會執行程式。請先儲存，再自行開啟。
# review: new
ui-clear-flag = 清除標幟(&C)
# review: new
ui-button-move = 移動(&M)
# review: new
ui-button-copy = 複製(&C)
# review: new
ui-find-folder = 尋找資料夾
# review: new
ui-new-folder-in = 新資料夾會放在{ $folder }中。
# review: new
ui-outbox-send-all = 立即全部傳送(&S)
# review: new
ui-yes = 是
# review: new
ui-no = 否
# review: new
ui-try-again = 再試一次
# review: new
ui-remove = 移除(&R)
# review: new
ui-signature-of = 簽名 - { $account }
# review: new
ui-sign-in-with = 使用{ $provider }登入
# review: new
ui-sign-in-in-browser-yours = 請在已開啟的瀏覽器視窗中登入您的帳戶，然後回到這裡。
# review: new
ui-browser-sign-in-server = { $server }（瀏覽器登入）
# review: new
ui-dont-allow = 不允許
# review: new
ui-allow = 允許(&A)
# review: new
ui-dont-send = 不要傳送
# review: new
ui-dont-unsubscribe = 不要取消訂閱
# review: new
ui-edit-first = 先編輯(&E)
# review: new
ui-new-address = 新地址
# review: new
ui-turn-away = 拒絕存取(&T)
# review: new
ui-clear-agent-log = 要清除代理程式的活動記錄嗎？
# review: new
ui-clear-agent-log-detail = 這不會復原代理程式所做的變更。
# review: new
ui-let-agents-connect = 允許 AI 代理程式連接 Inbox Classic(&L)
# review: new
ui-change-button = 變更...
# review: new
ui-undo-button = 復原
# Tools > AI Agents: takes back everything the selected program did in a span the user picks
# review: new
ui-undo-since-button = 復原自...
# review: new
ui-undo-since-span = 收回這個程式所做的動作：
# review: new
ui-take-back = 收回
# review: new
ui-rules-title = 郵件規則
# review: new
ui-rules-intro = Inbox Classic 執行時，規則會處理收件匣中的新郵件。符合的規則會依序執行。一旦某條規則預定將郵件移出收件匣，就不會再對它套用其他規則。
# review: new
ui-rules-none = 尚無規則。按一下「新增」即可建立。
# review: new
ui-rule-new = 新增(&N)...
# review: new
ui-rule-edit = 編輯(&E)...
# review: new
ui-rule-delete-button = 刪除(&L)
# review: new
ui-rule-title = 郵件規則
# review: new
ui-rule-name = 名稱：
# review: new
ui-rule-account = 帳戶：
# review: new
ui-rule-all-accounts = 所有帳戶
# review: new
ui-rule-query = 搜尋準則：
# review: new
ui-rule-query-hint = 使用與搜尋方塊相同的搜尋字詞，例如 from:ann@example.com、subject:invoice 或 list:news.example.com。
# review: new
ui-rule-count = 目前有{ $count }封收件匣郵件符合這些準則。
# review: new
ui-rule-show = 顯示(&S)
# review: new
ui-rule-actions = 動作：
# review: new
ui-rule-move = 移至(&M)：
# review: new
ui-rule-mark-read = 標示為已讀取(&R)
# review: new
ui-rule-flag = 加上標幟(&F)
# review: new
ui-rule-archive = 封存(&A)
# review: new
ui-rule-junk = 移至垃圾郵件(&J)
# review: new
ui-rule-delete = 刪除(&D)
# review: new
ui-rule-quiet = 不要通知我(&N)
# review: new
ui-rule-apply-now = 同時套用到收件匣中現有的郵件(&I)
# review: new
ui-rule-delete-ask = 要刪除規則「{ $name }」嗎？
# review: new
ui-create-rule = 建立規則...
# review: new
ui-rules-applied = 規則已處理{ $count }封郵件
# review: new
ui-col-rule-matches = 準則
# review: new
ui-clear-button = 清除(&E)
# review: new
ui-how-to-connect = 如何連接代理程式...
# review: new
ui-agent-programs = 其代理程式曾要求存取您郵件的程式
# review: new
ui-what-agents-did = 代理程式活動
# review: new
ui-restart-now = 立即重新啟動(&R)
# review: new
ui-restart-later = 稍後(&L)

## 通訊錄（工具 > 通訊錄）、連絡人與群組內容、選取收件者

# review: new
ui-tb-new-contact = 新增連絡人
# review: new
ui-tb-new-group = 新增群組
# review: new
ui-tb-properties = 內容
# review: new
ui-tb-write-to = 寫信給
# review: new
ui-menu-new-contact = 新增連絡人(&C)...
# review: new
ui-menu-new-group = 新增群組(&G)...
# review: new
ui-menu-write-to = 寫信給(&W)
# review: new
ui-menu-delete = 刪除(&D)
# review: new
ui-book-find-hint = 輸入名稱或電子郵件地址
# review: new
ui-book-all-contacts = 所有連絡人
# review: new
ui-col-phone = 電話
# review: new
ui-book-empty = 通訊錄是空的。按一下「新增連絡人」以新增連絡人，或從「檔案」功能表匯入 vCard 或 CSV 檔案。
# review: new
ui-book-no-match = 沒有符合「{ $words }」的連絡人。
# review: new
ui-book-delete-ask = { $count ->
    [1] 要從通訊錄刪除這位連絡人嗎？
   *[other] 要從通訊錄刪除這{ $count }位連絡人嗎？
}
# review: new
ui-group-delete-ask = 要刪除群組「{ $name }」嗎？群組中的成員仍會保留在通訊錄中。
# review: new
ui-book-no-address = { $name }沒有電子郵件地址。
# review: new
ui-new-contact-title = 新增連絡人
# review: new
ui-contact-title = { $name }內容
# review: new
ui-contact-first = 名字：
# review: new
ui-contact-last = 姓氏：
# review: new
ui-contact-display = 顯示名稱：
# review: new
ui-contact-nickname = 暱稱：
# review: new
ui-contact-company = 公司：
# review: new
ui-contact-addresses = 電子郵件地址：
# review: new
ui-contact-address-hint = 輸入電子郵件地址
# review: new
ui-contact-add = 新增(&A)
# review: new
ui-contact-set-default = 設為預設值(&U)
# review: new
ui-contact-default = { $address }（預設）
# review: new
ui-contact-phones = 電話號碼：
# review: new
ui-phone-home = 住家
# review: new
ui-phone-work = 公司
# review: new
ui-phone-mobile = 行動電話
# review: new
ui-phone-other = 其他
# review: new
ui-contact-notes = 附註：
# review: new
ui-contact-name-needed = 請輸入連絡人的名稱或電子郵件地址。
# review: new
ui-contact-address-invalid = 「{ $address }」不是有效的電子郵件地址。
# review: new
ui-contact-not-saved = 無法儲存連絡人：{ $reason }
# review: new
ui-new-group-title = 新增群組
# review: new
ui-group-title = { $name }內容
# review: new
ui-group-name = 群組名稱：
# review: new
ui-group-members = 成員：
# review: new
ui-group-select-members = 選取成員(&S)...
# review: new
ui-group-new-member = 新增不在通訊錄中的電子郵件地址：
# review: new
ui-group-name-needed = 請輸入群組名稱。
# review: new
ui-group-not-saved = 無法儲存群組：{ $reason }
# review: new
ui-group-members-count = { $count }位成員
# review: new
ui-select-recipients = 選取收件者
# review: new
ui-select-members = 選取群組成員
# review: new
ui-pick-intro = 輸入名稱或從清單中選取：
# review: new
ui-pick-recipients = 郵件收件者：
# review: new
ui-pick-members = 群組成員：
# review: new
ui-pick-to = 收件者(&T) →
# review: new
ui-pick-cc = 副本(&C) →
# review: new
ui-pick-bcc = 密件副本(&B) →
# review: new
ui-pick-add = 新增(&A) →
# review: new
ui-pick-tip = 從通訊錄選擇收件者
# review: new
ui-filter-address-books = 通訊錄（vCard、CSV）
# review: new
ui-filter-vcard = vCard 檔案
# review: new
ui-book-export-name = 通訊錄
# review: new
ui-book-imported = 已新增{ $added }位連絡人，略過{ $skipped }位已在通訊錄中的連絡人。
# review: new
ui-book-not-imported = 無法匯入通訊錄：{ $reason }
# review: new
ui-book-exported = 已將{ $count }位連絡人儲存到{ $file }。
# review: new
ui-book-not-exported = 無法儲存通訊錄：{ $reason }
# review: new
ui-code-copied = 已複製代碼
# review: new
ui-codes-in-notifications = 在新郵件通知中顯示登入代碼(&C)
# review: new
ui-tool-unread-only = 未讀取
# review: new
ui-no-unread = 這裡沒有未讀取的郵件。
# review: new
ui-pictures-always-sender = 一律下載{ $sender }寄來的圖片
# review: new
ui-pictures-always-domain = 一律下載{ $domain }所有人寄來的圖片
# review: new
ui-pictures-unconfirmed = 無法驗證寄件者的網域（{ $domain }），因此不會自動下載這封郵件中的圖片。
# review: new
ui-pictures-always-option = 下載所有郵件中的圖片(&M)
# review: new
ui-pictures-always-warning = 如此一來，寄件者就能知道您何時閱讀他們的郵件。
# review: new
ui-protection-details = 詳細資料(&D)...
# review: new
ui-protection-details-title = 安全性詳細資料
# review: new
ui-download-heading = 下載
# review: new
ui-download-ahead = 預先下載郵件(&D)：
# review: new
ui-download-ahead-recent = 最近的郵件，每封最多 1 MB
# review: new
ui-download-ahead-all = 所有郵件
# review: new
ui-download-ahead-never = 僅在開啟時
# review: new
ui-download-limit = 每個帳戶的儲存空間上限(&S)：
# review: new
ui-send-delay = 傳送前延遲(&S)：
# review: new
ui-send-delay-note = 倒數期間，您可以使用「復原」取消傳送。倒數結束後就無法再取消，即使郵件仍在寄件匣中也一樣。
# review: new
ui-dark-messages = 系統處於深色模式時，以深色背景顯示郵件
# Reading settings: previews of the pictures and PDF files attached, after a message's text
# review: new
ui-preview-show = 在郵件中顯示附件(&S)
# review: new
ui-preview-show-note = 在郵件內文之後顯示圖片與 PDF 檔案的前幾頁。Inbox Classic 建立這些預覽時，不會執行檔案中的程式碼，也不會載入其外部資源。
# the second setting under it; the same words as preview-pdf-option, with an access key
# review: new
ui-preview-pdfs = 在郵件中顯示 PDF 檔案(&F)
# review: new
ui-sending-in = { $count }秒後傳送{ $subject }
# review: new
ui-send-undone = 未傳送{ $subject }。郵件已重新開啟供您編輯。
# review: new
ui-send-too-late = 傳送{ $subject }已無法復原。
# review: new
ui-outbox-status-undo = 預定於{ $time }傳送
# review: new
ui-download-note = 此上限適用於本機儲存的郵件內容，而非整個資料庫。超過上限時，會移除最舊的副本，開啟時可再次下載。草稿以及應用程式啟動後開啟過的郵件，即使超過上限也會保留。
# review: new
ui-attachment-downloading = 這封郵件尚未下載完成。請在下載完成後再試一次。
# review: new
ui-trusted-senders-button = 信任的寄件者(&T)...
# review: new
ui-trusted-senders-title = 信任的寄件者
# review: new
ui-trusted-senders-note = 當您的郵件服務提供者驗證寄件者的網域後，會自動下載這些寄件者郵件中的圖片。
# review: new
ui-trusted-everyone-at = { $domain }的所有人
# review: new
ui-trusted-senders-empty = 尚未新增信任的寄件者。
# review: new
ui-search-encrypted = 搜尋加密的郵件(&E)
# review: new
ui-search-encrypted-note = 有所需的私密金鑰時，已下載或開啟的郵件可以解密並建立索引，以供文字搜尋與顯示受保護的主旨。此索引未加密。AI 代理程式無法搜尋解密後的內容。關閉此選項會從索引中移除這些內容。
# review: new
ui-pgp-keyserver = 在 keys.openpgp.org 上查詢金鑰(&U)
# review: new
ui-pgp-keyserver-note = 查詢地址時，Inbox Classic 會先詢問該地址的網域，必要時再將地址傳送到 keys.openpgp.org。依指紋或金鑰識別碼查詢時，則改為傳送該識別碼。
# review: new
ui-eml-default = 使用 Inbox Classic 開啟 .eml 檔案(&E)
# review: new
ui-eml-default-done = Inbox Classic 現在會開啟 .eml 檔案。
# review: new
ui-eml-default-failed = 無法將 Inbox Classic 設為 .eml 檔案的預設應用程式：{ $reason }
# review: new
ui-folders = 資料夾
# review: new
ui-sorted-by = 依{ $field }排序
# review: new
ui-layout-label = 版面配置(&L)：
# review: new
ui-columns-note = 視窗寬度足以使用欄式版面配置。您可以在「檢視 > 版面配置」下變更版面配置。
# review: new
ui-row-unread = 未讀取
# review: new
ui-row-flagged = 已標幟
# review: new
ui-row-attachments = 有附件
# review: new
ui-row-encrypted = 已加密
# review: new
ui-row-signed = 已簽署
# review: new
ui-row-messages = { $count }封郵件
# review: new
ui-list-pictures = 在郵件清單中顯示寄件者的圖片(&P)
# review: new
ui-list-pictures-note = 在欄式版面配置中，寄件者的網域經過驗證時，會顯示品牌標誌或通訊錄中的圖片；沒有圖片時則顯示姓名縮寫。下載的標誌會快取並重複使用，偶爾會重新整理。
# review: new
ui-card-picture = 圖片：
# review: new
ui-card-picture-choose = 選擇(&H)...
# review: new
ui-picture-not-picture = 無法將檔案解碼為 PNG 或 JPEG 圖片。
# review: new
ui-picture-too-large = 這張圖片太大。請選擇 10 MB 以內、寬度與高度都不超過 8000 像素的圖片。

## 加密金鑰（工具 > 加密金鑰、帳戶內容 > 安全性、連絡人的金鑰）
# review: new
ui-keys-title = 加密金鑰
# review: new
ui-keys-intro = 您的金鑰可以簽署您的郵件，並開啟加密給您的郵件。連絡人的金鑰可以檢查他們的簽章，並為寄給他們的郵件加密。
# review: new
ui-keys-empty = 尚無金鑰。按一下「新增金鑰」以建立您的金鑰，或按一下「匯入」新增您已有的金鑰。
# review: new
ui-keys-col-name = 名稱
# review: new
ui-keys-col-address = 地址
# review: new
ui-keys-col-kind = 類型
# review: new
ui-keys-col-status = 狀態
# review: new
ui-keys-kind-own = 您的金鑰
# review: new
ui-keys-kind-contact = 連絡人
# review: new
ui-keys-status-verified = { $status }，已驗證
# review: new
ui-keys-new = 新增金鑰(&N)...
# review: new
ui-keys-import = 匯入(&I)...
# review: new
ui-keys-export = 匯出(&E)...
# review: new
ui-keys-backup = 備份(&B)...
# review: new
ui-keys-verify = 驗證(&V)...
# review: new
ui-keys-new-title = 新增金鑰
# review: new
ui-keys-new-for = 建立金鑰給：
# review: new
ui-keys-new-make = 建立金鑰(&M)
# review: new
ui-keys-no-account = 請先新增郵件帳戶：金鑰是為帳戶的地址建立的。
# review: new
ui-keys-memory-only = 密碼只保存在記憶體中，因此現在建立或匯入的私密金鑰在 Inbox Classic 關閉後就無法使用。
# review: new
ui-keys-backup-offer = 您的新金鑰已準備就緒。要立即儲存備份嗎？如果這部電腦遺失或重設，只能從備份還原金鑰。
# review: new
ui-keys-backup-now = 儲存備份(&S)...
# review: new
ui-keys-later = 稍後(&L)
# review: new
ui-keys-backup-title = 備份金鑰
# review: new
ui-keys-backup-intro = 備份受到密語保護。請將檔案與密語分別存放在不同的安全地方：兩者都要有，才能還原金鑰。
# review: new
ui-keys-passphrase = 密語(&P)：
# review: new
ui-keys-passphrase-again = 再輸入一次(&T)：
# review: new
ui-keys-passphrase-differ = 兩次輸入的密語不相同。
# review: new
ui-keys-passphrase-short = 請使用至少 8 個字元的密語。
# review: new
ui-keys-backup-saved = 備份已儲存。
# review: new
ui-keys-import-title = 匯入金鑰
# review: new
ui-keys-import-passphrase = 這個私密金鑰受到密語保護。請輸入密語以匯入金鑰：
# review: new
ui-keys-file-filter = OpenPGP 金鑰
# review: new
ui-keys-use-for = 要將這個金鑰用於{ $addresses }嗎？您可以用它簽署從這些地址寄出的郵件，並閱讀加密給它的郵件。
# review: new
ui-keys-use = 使用(&U)
# review: new
ui-keys-not-now = 現在不要(&N)
# review: new
ui-keys-remove-own = 要移除您的金鑰{ $fingerprint }嗎？若要再次解密受此金鑰保護的郵件，您需要匯入其私密金鑰備份。已解密的副本不會被移除。
# review: new
ui-keys-remove-contact = 要移除與{ $name }相關聯的金鑰嗎？在您再次新增此金鑰之前，將無法檢查以它建立的簽章，也無法用它為郵件加密。
# review: new
ui-key-properties-title = 金鑰內容
# review: new
ui-key-names = 名稱：
# review: new
ui-key-fingerprint = 指紋：
# review: new
ui-key-status = 狀態：
# review: new
ui-key-created = 建立日期：
# review: new
ui-key-expires = 到期日：
# review: new
ui-key-never = 永不
# review: new
ui-key-algorithm = 演算法：
# review: new
ui-key-source = 來源：
# review: new
ui-key-addresses = 地址：
# review: new
ui-key-address-verified = { $address }（已驗證）
# review: new
ui-key-address-not-verified = { $address }（未驗證）
# review: new
ui-verify-title = 驗證金鑰
# review: new
ui-verify-intro = 請{ $name }當面或透過通話，從他們自己的應用程式念出其金鑰的指紋給您聽。不要與透過電子郵件傳來的指紋比對：能更改金鑰的人，也能更改那封郵件。
# review: new
ui-verify-fingerprint = 您所擁有金鑰的指紋：
# review: new
ui-verify-marks = { $count ->
    [0] 這個金鑰沒有電子郵件地址，無法儲存其擁有者的確認結果。
    [1] 按一下「相符」之前，請確認這個地址屬於這位連絡人：{ $addresses }。否則，請按一下「不相符」。
   *[other] 按一下「相符」之前，請確認下列地址都屬於這位連絡人：{ $addresses }。否則，請按一下「不相符」。
}
# review: new
ui-verify-match = 相符(&M)
# review: new
ui-verify-differ = 不相符(&D)
# review: new
ui-verify-differs = 您擁有的金鑰與{ $name }的金鑰不同。請移除它，並再次向對方索取金鑰。
# review: new
ui-verify-unmark = 標示為未驗證(&N)
# review: new
ui-account-security = 安全性
# review: new
ui-account-security-intro = 有了金鑰，您的郵件就可以簽署，其他人也可以寄加密郵件給您。
# review: new
ui-account-key = 此帳戶的金鑰(&K)：
# review: new
ui-account-key-none = 無
# review: new
ui-account-key-new = 新增金鑰(&N)...
# review: new
ui-account-autocrypt = 隨郵件傳送我的公開金鑰（Autocrypt）(&S)
# review: new
ui-contact-key = 加密金鑰：
# review: new
ui-contact-key-none = 沒有金鑰
# review: new
ui-contact-key-use-new = 使用新的金鑰(&N)
# review: new
ui-contact-key-keep = 保留目前的金鑰(&K)
# review: new
ui-recipient-keys-title = 收件者的金鑰
# review: new
ui-recipient-col-recipient = 收件者
# review: new
ui-recipient-col-key = 金鑰
# review: new
ui-recipient-find-key = 尋找金鑰(&F)
# review: new
ui-recipient-remove = 從郵件中移除(&R)
# review: new
ui-send-unencrypted = 不加密傳送(&W)
# review: new
ui-compose-make-key = 建立金鑰(&M)...
# review: new
ui-compose-show-keys = 加密金鑰(&E)...
# review: new
ui-compose-encrypt-off = 關閉加密(&T)
# review: new
ui-compose-keep-encrypted = 保持加密(&K)
# review: new
ui-setup-export-title = 匯出設定與帳戶
# review: new
ui-setup-import-title = 匯入設定與帳戶
# review: new
ui-setup-export-intro = 選擇要帶到另一部電腦的項目。檔案中不含任何郵件，包括寄件匣中的郵件。只有保留在伺服器上的郵件可以在另一部電腦上下載。
# review: new
ui-setup-use-passphrase = 以密語保護檔案(&O)
# review: new
ui-setup-passphrase-note = 密語會加密整個檔案，並讓檔案可以包含所選項目中可用的密碼、登入權杖、用戶端密碼與私密金鑰。沒有這項保護，這些機密資料會被略過，您需要在另一部電腦上重新登入。
# review: new
ui-setup-export-button = 匯出(&E)...
# review: new
ui-setup-file-filter = Inbox Classic 設定與帳戶
# review: new
ui-setup-ask-passphrase = 這個檔案受到密語保護。請輸入密語以查看檔案內容：
# review: new
ui-setup-import-intro = 選擇要匯入的項目。這部電腦上已有的帳戶會維持原狀。
# review: new
ui-setup-from = 由 Inbox Classic { $version }於{ $date }儲存。
# review: new
ui-setup-import-button = 匯入(&I)
# review: new
ui-setup-done = 完成
# review: new
ui-setup-first-run = 從另一部電腦匯入設定與帳戶...
