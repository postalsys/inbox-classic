# 繁體中文（台灣）草稿，等待母語人士審閱。
# Linux 應用程式自身視窗的文字（linux/src），識別碼以 gtk- 開頭。{ $braces } 中的預留位置由應用程式填入；_ 標示按鈕的
# 快速鍵字母，中文寫成「副本(_C)」。GNOME 有自己用語的地方依循 GNOME（偏好設定、離開）。

## 主視窗

gtk-search-looks-in = 在{ $place }中搜尋的範圍包括主旨、寄件者、收件者、附件名稱與郵件內文。請檢查拼字，或減少字詞再試一次。
gtk-search-still-indexing = 仍在為{ $count }封郵件的內文建立索引，稍後可能會出現更多結果。
gtk-search-results-everywhere = { $count ->
    [0] 在所有資料夾中找不到「{ $words }」
   *[other] 在所有資料夾中找到{ $count }個「{ $words }」的結果
}
gtk-search-results-in = { $count ->
    [0] 在{ $place }中找不到「{ $words }」
   *[other] 在{ $place }中找到{ $count }個「{ $words }」的結果
}
gtk-search-indexing = 仍在為{ $count }封郵件的內文建立索引
gtk-list-loading = 正在載入...
gtk-menu-rename = 重新命名...
gtk-import-one-question = 要將郵件{ $file }匯入{ $folder }嗎？
gtk-files-not-saved = { $total }個檔案中有{ $failed }個無法儲存。
gtk-unsubscribe-one-click =
    要退出這個郵寄清單嗎？

    Inbox Classic 會傳送取消訂閱要求到{ $target }。不會開啟網頁，也不會寄出電子郵件。
gtk-unsubscribe-mail =
    要退出這個郵寄清單嗎？

    若要取消訂閱，請寄送電子郵件到{ $target }。Inbox Classic 會為您準備好郵件，傳送郵件即可確認。
gtk-unsubscribe-web =
    要退出這個郵寄清單嗎？

    郵寄清單的取消訂閱網頁會在瀏覽器中開啟（{ $target }）。
gtk-unsubscribe-failed = 無法取消訂閱：{ $problem }
gtk-toolbar-create-mail-menu = 從指定帳戶撰寫郵件
gtk-toolbar-send-recv-menu = 傳送及接收指定帳戶的郵件
gtk-main-menu = 主選單
gtk-folder-list = 資料夾清單
gtk-quit = 離開

## 移動與複製視窗

gtk-new-folder-at-top-of = 新資料夾會放在{ $account }的最上層。

## 郵件清單

## 說明

## 通知與系統匣

gtk-unread-messages = { $count ->
    [0] 沒有未讀取的郵件
   *[other] { $count }封未讀取的郵件
}

## 撰寫視窗的連結選單

## 寄件匣

gtk-outbox-empty = 沒有等候傳送的郵件。
gtk-outbox-row = 收件者：{ $to }  ·  排入佇列：{ $queued }  ·  { $status }

## 應用程式

gtk-still-running-detail = Inbox Classic 會繼續在背景檢查新郵件。請使用頂端列中的圖示來開啟或離開應用程式。
gtk-sign-in-again-ask =
    登入{ $account }遭到拒絕，或工作階段已過期。

    要在瀏覽器中重新登入嗎？
gtk-default-app-not-installed = 這份 Inbox Classic 並未安裝，因此系統不會將它列為郵件應用程式。請先安裝才能選擇它。
gtk-default-app-now = Inbox Classic 現在是您的預設郵件應用程式：電子郵件連結會在這裡開啟新郵件。
gtk-default-app-failed = 無法將 Inbox Classic 設為預設郵件應用程式。

## 許多視窗共用的按鈕與文字

## 讀取窗格

gtk-reader-date = 日期：
gtk-reader-files = 郵件附件
gtk-files = { $count }個檔案
gtk-save-attachments-menu = 儲存附件...

## 撰寫視窗

gtk-format-bold = 粗體（Ctrl+B）
gtk-format-italic = 斜體（Ctrl+I）
gtk-format-underline = 底線（Ctrl+U）
gtk-format-hyperlink = 超連結（Ctrl+K）
gtk-font = 字型
gtk-show-cc = 副本(_C)
gtk-show-bcc = 密件副本(_B)
gtk-save-tip = 儲存（Ctrl+S）
gtk-link-status = { $link }    （Ctrl+按一下即可開啟）

## 帳戶

gtk-plain-warning = 不加密的話，任何攔截您網路流量的人都能讀取您的密碼與郵件。只有在連線已透過其他方式保護時才繼續。單靠區域網路並不能提供加密。

    要繼續嗎？
gtk-account-name-title = 帳戶名稱
gtk-display-name-title = 顯示名稱
gtk-turned-off-why = 「{ $button }」選項已在這部電腦上停用。{ $reason }
gtk-turned-off-why-long =
    「{ $button }」選項已在這部電腦上停用。

    { $reason }
gtk-next = 下一步 >
gtk-provider-sign-in = 請在{ $provider }的網站上登入{ $address }。您的密碼不會提供給 Inbox Classic。如果您的帳戶允許以應用程式密碼存取郵件，也可以使用在其安全性設定中建立的應用程式密碼。Outlook.com 與 Microsoft 365 只接受瀏覽器登入。
gtk-provider-sign-in-apps = 請使用您的登入應用程式（更多登入選項），在{ $provider }的網站上登入{ $address }。如果您的帳戶允許以應用程式密碼存取郵件，也可以使用在其安全性設定中建立的應用程式密碼。Outlook.com 與 Microsoft 365 只接受瀏覽器登入。
gtk-accounts-add = 新增...
gtk-accounts-properties = 內容...
gtk-accounts-signature = 簽名...
gtk-accounts-sign-in-apps = 登入應用程式...

## 登入應用程式

gtk-app-server = { $kind }伺服器
gtk-app-port = { $kind }連接埠
gtk-app-security = { $kind }安全性
gtk-issuer-found =
    登入頁面：{ $page }
    權杖端點：{ $endpoint }
gtk-client-id = 用戶端識別碼
gtk-client-secret = 用戶端密碼
gtk-scopes = 權限範圍（scopes）
gtk-redirect-uri = 重新導向 URI
gtk-issuer-usable =
    可以使用此簽發者。

    { $found }
gtk-app-built-in = { $app }是內建的。您只能變更是否在新帳戶中提供它。{ $reason }
gtk-built-in = { $app }（內建）
gtk-offered-for-new = 在新帳戶中提供
gtk-edit-button = 編輯...
gtk-remove-app-ask = 要移除登入應用程式{ $app }及其儲存的用戶端密碼嗎？
gtk-sign-in-apps-intro = 登入應用程式讓帳戶可以透過瀏覽器登入。已關閉的應用程式不會在新帳戶中提供；已在使用它的帳戶可繼續運作。

## AI 代理程式

gtk-agent-it-may = 允許的動作
gtk-agent-accounts = 允許的帳戶
gtk-never-used = 從未使用
gtk-last-used = 上次使用：{ $date }
gtk-forget-program = 要移除這個程式已儲存的權限嗎？
gtk-forget-program-detail = 程式的權限及其代理程式的活動記錄將會刪除，但不會解除安裝程式。下次它連接時，會再次要求您授予權限。
gtk-no-agents-yet = 還沒有代理程式要求使用您的郵件。
gtk-nothing-yet = 尚無記錄。

## 偏好設定

gtk-preferences = 偏好設定
gtk-notify-subtitle = 僅在 Inbox Classic 主視窗未位於前景時

## 桌面項目與軟體商店的頁面

# linux/data/com.inboxclassic.InboxClassic.desktop and .metainfo.xml, made by the build. The keywords are the words a
# search of the applications finds Inbox Classic by, each ended by a semicolon, in your language only: the English
# ones are added before them
gtk-desktop-generic-name = 郵件用戶端
gtk-desktop-comment = 閱讀及撰寫電子郵件：快速、簡單的郵件程式
gtk-desktop-keywords = 郵件;電子郵件;信件;收件匣;信箱;
gtk-metainfo-summary = 快速、簡單的郵件程式
gtk-metainfo-description = Inbox Classic 可以閱讀及撰寫電子郵件。其傳統的版面配置將資料夾放在左側，郵件清單在上方，選取的郵件在下方。它可搭配相容的 IMAP 與 SMTP 帳戶使用，並可透過瀏覽器登入 Outlook.com 與 Microsoft 365。
gtk-metainfo-feature-sanitized = 會移除郵件中的指令碼及其他主動式內容；網際網路上的圖片只在您允許時才會載入
gtk-metainfo-feature-search = 使用熟悉的 Gmail 式運算子，搜尋主旨、寄件者、收件者、附件名稱與郵件內文
gtk-metainfo-feature-replies = 回覆會摺疊其引用的較早郵件
gtk-metainfo-feature-offline = 只要保留本機副本，已下載的郵件在離線時仍可閱讀；登入認證通常會在可用時使用系統金鑰圈
