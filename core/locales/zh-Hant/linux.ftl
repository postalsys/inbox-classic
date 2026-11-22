# 繁體中文（台灣）草稿，等待母語人士審閱。
# Linux 應用程式自身視窗的文字（linux/src），識別碼以 gtk- 開頭。{ $braces } 中的預留位置由應用程式填入；_ 標示按鈕的
# 快速鍵字母，中文寫成「副本(_C)」。GNOME 有自己用語的地方依循 GNOME（偏好設定、離開）。

## 主視窗

# review: new
gtk-search-looks-in = 在{ $place }中搜尋的範圍包括主旨、寄件者、收件者、附件名稱與郵件內文。請檢查拼字，或減少字詞再試一次。
# review: new
gtk-search-still-indexing = 仍在為{ $count }封郵件的內文建立索引，稍後可能會出現更多結果。
# review: new
gtk-search-results-everywhere = { $count ->
    [0] 在所有資料夾中找不到「{ $words }」
   *[other] 在所有資料夾中找到{ $count }個「{ $words }」的結果
}
# review: new
gtk-search-results-in = { $count ->
    [0] 在{ $place }中找不到「{ $words }」
   *[other] 在{ $place }中找到{ $count }個「{ $words }」的結果
}
# review: new
gtk-search-indexing = 仍在為{ $count }封郵件的內文建立索引
# review: new
gtk-list-loading = 正在載入...
# review: new
gtk-menu-rename = 重新命名...
# review: new
gtk-import-one-question = 要將郵件{ $file }匯入{ $folder }嗎？
# review: new
gtk-files-not-saved = { $total }個檔案中有{ $failed }個無法儲存。
# review: new
gtk-unsubscribe-one-click =
    要退出這個郵寄清單嗎？

    Inbox Classic 會傳送取消訂閱要求到{ $target }。不會開啟網頁，也不會寄出電子郵件。
# review: new
gtk-unsubscribe-mail =
    要退出這個郵寄清單嗎？

    若要取消訂閱，請寄送電子郵件到{ $target }。Inbox Classic 會為您準備好郵件，傳送郵件即可確認。
# review: new
gtk-unsubscribe-web =
    要退出這個郵寄清單嗎？

    郵寄清單的取消訂閱網頁會在瀏覽器中開啟（{ $target }）。
# review: new
gtk-unsubscribe-failed = 無法取消訂閱：{ $problem }
# review: new
gtk-toolbar-create-mail-menu = 從指定帳戶撰寫郵件
# review: new
gtk-toolbar-send-recv-menu = 傳送及接收指定帳戶的郵件
# review: new
gtk-main-menu = 主選單
# review: new
gtk-folder-list = 資料夾清單
# review: new
gtk-quit = 離開

## 移動與複製視窗

# review: new
gtk-new-folder-at-top-of = 新資料夾會放在{ $account }的最上層。

## 郵件清單

## 說明

## 通知與系統匣

# review: new
gtk-unread-messages = { $count ->
    [0] 沒有未讀取的郵件
   *[other] { $count }封未讀取的郵件
}

## 撰寫視窗的連結選單

## 寄件匣

# review: new
gtk-outbox-empty = 沒有等候傳送的郵件。
# review: new
gtk-outbox-row = 收件者：{ $to }  ·  排入佇列：{ $queued }  ·  { $status }

## 應用程式

# review: new
gtk-still-running-detail = Inbox Classic 會繼續在背景檢查新郵件。請使用頂端列中的圖示來開啟或離開應用程式。
# review: new
gtk-sign-in-again-ask =
    登入{ $account }遭到拒絕，或工作階段已過期。

    要在瀏覽器中重新登入嗎？
# review: new
gtk-default-app-not-installed = 這份 Inbox Classic 並未安裝，因此系統不會將它列為郵件應用程式。請先安裝才能選擇它。
# review: new
gtk-default-app-now = Inbox Classic 現在是您的預設郵件應用程式：電子郵件連結會在這裡開啟新郵件。
# review: new
gtk-default-app-failed = 無法將 Inbox Classic 設為預設郵件應用程式。

## 許多視窗共用的按鈕與文字

## 讀取窗格

# review: new
gtk-reader-date = 日期：
# review: new
gtk-reader-files = 郵件附件
# review: new
gtk-files = { $count }個檔案
# review: new
gtk-save-attachments-menu = 儲存附件...

## 撰寫視窗

# review: new
gtk-format-bold = 粗體（Ctrl+B）
# review: new
gtk-format-italic = 斜體（Ctrl+I）
# review: new
gtk-format-underline = 底線（Ctrl+U）
# review: new
gtk-format-hyperlink = 超連結（Ctrl+K）
# review: new
gtk-font = 字型
# review: new
gtk-show-cc = 副本(_C)
# review: new
gtk-show-bcc = 密件副本(_B)
# review: new
gtk-save-tip = 儲存（Ctrl+S）
# review: new
gtk-link-status = { $link }    （Ctrl+按一下即可開啟）

## 帳戶

# review: new
gtk-plain-warning =
    不加密的話，任何攔截您網路流量的人都能讀取您的密碼與郵件。請只在伺服器位於您自己的電腦或區域網路上時使用這個連線。

    要繼續嗎？
# review: new
gtk-account-name-title = 帳戶名稱
# review: new
gtk-display-name-title = 顯示名稱
# review: new
gtk-turned-off-why = 「{ $button }」選項已在這部電腦上停用。{ $reason }
# review: new
gtk-turned-off-why-long =
    「{ $button }」選項已在這部電腦上停用。

    { $reason }
# review: new
gtk-next = 下一步 >
# review: new
gtk-provider-sign-in = 請在{ $provider }的網站上登入{ $address }。您的密碼不會提供給 Inbox Classic。如果您的帳戶允許在郵件中使用應用程式密碼，也可以使用在其安全性設定中建立的應用程式密碼。Outlook.com 與 Microsoft 365 只接受瀏覽器登入。
# review: new
gtk-provider-sign-in-apps = 請使用您的登入應用程式（更多登入選項），在{ $provider }的網站上登入{ $address }。如果您的帳戶允許在郵件中使用應用程式密碼，也可以使用在其安全性設定中建立的應用程式密碼。Outlook.com 與 Microsoft 365 只接受瀏覽器登入。
# review: new
gtk-accounts-add = 新增...
# review: new
gtk-accounts-properties = 內容...
# review: new
gtk-accounts-signature = 簽名...
# review: new
gtk-accounts-sign-in-apps = 登入應用程式...

## 登入應用程式

# review: new
gtk-app-server = { $kind }伺服器
# review: new
gtk-app-port = { $kind }連接埠
# review: new
gtk-app-security = { $kind }安全性
# review: new
gtk-issuer-found =
    登入頁面：{ $page }
    權杖端點：{ $endpoint }
# review: new
gtk-client-id = 用戶端識別碼
# review: new
gtk-client-secret = 用戶端密碼
# review: new
gtk-scopes = 權限範圍（scopes）
# review: new
gtk-redirect-uri = 重新導向 URI
# review: new
gtk-issuer-usable =
    可以使用此簽發者。

    { $found }
# review: new
gtk-app-built-in = { $app }是內建的。您只能變更是否在新帳戶中提供它。{ $reason }
# review: new
gtk-built-in = { $app }（內建）
# review: new
gtk-offered-for-new = 在新帳戶中提供
# review: new
gtk-edit-button = 編輯...
# review: new
gtk-remove-app-ask = 要移除登入應用程式{ $app }及其儲存的用戶端密碼嗎？
# review: new
gtk-sign-in-apps-intro = 登入應用程式讓帳戶可以透過瀏覽器登入。已關閉的應用程式不會在新帳戶中提供；已在使用它的帳戶可繼續運作。

## AI 代理程式

# review: new
gtk-agent-it-may = 允許的動作
# review: new
gtk-agent-accounts = 允許的帳戶
# review: new
gtk-never-used = 從未使用
# review: new
gtk-last-used = 上次使用：{ $date }
# review: new
gtk-forget-program = 要移除這個程式嗎？
# review: new
gtk-forget-program-detail = 程式的權限及其代理程式的活動記錄將會刪除。下次它連接時，會再次要求您授予權限。
# review: new
gtk-no-agents-yet = 還沒有代理程式要求使用您的郵件。
# review: new
gtk-nothing-yet = 尚無記錄。

## 偏好設定

# review: new
gtk-preferences = 偏好設定
# review: new
gtk-notify-subtitle = 僅在 Inbox Classic 於背景執行時

## 桌面項目與軟體商店的頁面

# linux/data/com.inboxclassic.InboxClassic.desktop and .metainfo.xml, made by the build. The keywords are the words a
# search of the applications finds Inbox Classic by, each ended by a semicolon, in your language only: the English
# ones are added before them
# review: new
gtk-desktop-generic-name = 郵件用戶端
# review: new
gtk-desktop-comment = 閱讀及撰寫電子郵件：快速、簡單的郵件程式
# review: new
gtk-desktop-keywords = 郵件;電子郵件;信件;收件匣;信箱;
# review: new
gtk-metainfo-summary = 快速、簡單的郵件程式
# review: new
gtk-metainfo-description = Inbox Classic 可以閱讀及撰寫電子郵件。其傳統的版面配置將資料夾放在左側，郵件清單在上方，選取的郵件在下方。它可搭配相容的 IMAP 與 SMTP 帳戶使用，並可透過瀏覽器登入 Outlook.com 與 Microsoft 365。
# review: new
gtk-metainfo-feature-sanitized = 會移除郵件中的指令碼及其他主動式內容；網際網路上的圖片只在您允許時才會載入
# review: new
gtk-metainfo-feature-search = 使用熟悉的 Gmail 式運算子，搜尋主旨、寄件者、收件者、附件名稱與郵件內文
# review: new
gtk-metainfo-feature-replies = 回覆會摺疊其引用的較早郵件
# review: new
gtk-metainfo-feature-offline = 只要保留本機副本，已下載的郵件在離線時仍可閱讀；登入認證通常會在可用時使用系統金鑰圈
