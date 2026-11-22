# 繁體中文（台灣）草稿，等待母語人士審閱。
# Windows 應用程式自身視窗的文字（app/src），識別碼以 win- 開頭。{ $braces } 中的預留位置由應用程式填入；& 標示功能表
# 或按鈕的字母（&& 為 & 符號本身），中文寫成「刪除(&D)」。

## 主視窗

win-still-running-detail = Inbox Classic 會繼續在背景檢查新郵件。按一下圖示即可開啟。若要結束，請以滑鼠右鍵按一下圖示，然後使用其功能表。
win-default-app-not-installed = 這份 Inbox Classic 並未安裝，因此 Windows 不會將它列為郵件應用程式。請先安裝才能選擇它。
win-default-app-settings = Windows 會開啟其「預設應用程式」設定。請選擇 Inbox Classic 來開啟 MAILTO 連結。
win-no-unread = 沒有未讀取的郵件
win-unread-messages = { $count }封未讀取的郵件
win-print-failed = 無法列印郵件。
win-print-title-of = 列印 - { $subject }
win-no-bodies = 無法顯示郵件內文。
win-webview-failed = 無法建立 WebView2。
win-webview-missing = 無法使用 WebView2 執行階段。
win-list-loading = 正在載入...

## 許多視窗共用的按鈕與文字

win-delete-button = 刪除(&D)
win-find-label = 尋找(&F)：
win-save-as-button = 另存新檔(&E)...
win-too-many-files = 一次選取的檔案太多，請少選一些。

## 寄件匣


## 撰寫視窗

win-editor-failed = 無法撰寫郵件。
win-ctrl-click-to-open = （{ $ctrl }+按一下即可開啟）
win-format-bold = 粗體（{ $ctrl }+B）
win-format-italic = 斜體（{ $ctrl }+I）
win-format-underline = 底線（{ $ctrl }+U）
win-format-link = 超連結（{ $ctrl }+K）
win-show-cc = 副本(&C)
win-show-bcc = 密件副本(&B)
win-signature-title = 簽名：{ $account }

## 資料夾、郵件清單與讀取窗格

win-search-found-all = { $count ->
    [0] 在所有資料夾中找不到「{ $words }」
   *[other] 在所有資料夾中找到{ $count }個「{ $words }」的結果
}
win-search-found-in = { $count ->
    [0] 在{ $folder }中找不到「{ $words }」
   *[other] 在{ $folder }中找到{ $count }個「{ $words }」的結果
}
win-search-indexing = 仍在為{ $count }封郵件的內文建立索引
win-no-match-indexing = 仍在為{ $count }封郵件的內文建立索引，稍後可能會找到更多結果。
win-files = { $count }個檔案
win-save-attachments = 儲存附件(&S)...
win-files-not-saved = { $count }個檔案中有{ $failed }個無法儲存。
win-new-folder-in-highlighted = 新資料夾會建立在選取的資料夾中。
win-delete-folder-ask = 要刪除資料夾「{ $folder }」及其中的郵件與資料夾嗎？伺服器上的資料夾也會一併刪除。
win-rename = 重新命名(&R)...
win-messages-not-saved = 無法儲存郵件。
win-messages-not-forwarded = 無法轉寄郵件。

## 帳戶

win-sign-in-google = 使用 Google 帳戶登入
win-sign-in-microsoft = 使用 Microsoft 帳戶登入
win-next = 下一步(&N) >
win-your-account = 您的帳戶
win-browser-sign-in = （瀏覽器登入）
win-add = 新增(&A)...
win-properties-button = 內容(&P)...
win-signature-button = 簽名(&G)...
win-sign-in-apps-button = 登入應用程式(&S)...

## AI 代理程式

win-dont-allow = 不允許(&D)
win-col-address = 地址
win-never-written-to = 從未寫信給此地址
win-book-find-label = 輸入名稱或電子郵件地址：
win-send = 傳送(&S)
win-dont-send = 不要傳送(&D)
win-unsubscribe = 取消訂閱(&U)
win-dont-unsubscribe = 不要取消訂閱(&D)
win-forget-program-ask = 要移除這個程式已儲存的權限，以及其代理程式的活動記錄嗎？這不會解除安裝程式。下次它連接時，會再次要求您授予權限。
win-clear-log-ask = 要清除代理程式的活動記錄嗎？這不會復原代理程式所做的變更。
win-agent-programs = 其代理程式曾要求存取您郵件的程式(&P)：
win-change = 變更(&C)...
# Tools > AI Agents: takes back everything the selected program did in a span the user picks
win-undo-since = 復原自(&S)...
win-take-back = 收回(&T)
win-what-agents-did = 代理程式活動(&A)：
# under the log of Tools > AI Agents: what the selected row of reads covers (the start and end of its hour), or how to see it
win-agent-reads = 從{ $from }到{ $to }讀取的內容：
win-agent-reads-hint = 選取上方的讀取記錄列，即可查看讀取了哪些內容。

## 登入應用程式

win-built-in = （內建）
win-edit = 編輯(&E)...

## 選項

win-folders-hide = 隱藏資料夾清單
win-folders-pin = 將資料夾清單固定在郵件旁邊
win-folders-show = 顯示資料夾

## 安裝程式

# the installer's own words (installer/inbox-classic.nsi), made into installer/languages.nsh by the build;
# { $version } and { $installed } are version numbers, 0.18.0
win-installer-start = 啟動 Inbox Classic
win-installer-welcome-new = 這會安裝電子郵件程式 Inbox Classic { $version }。

    不需要系統管理員權限，只會為目前的 Windows 使用者安裝。
win-installer-welcome-same =
    已安裝 Inbox Classic { $version }。這會重新安裝一次。

    您的帳戶與郵件都會保留。
win-installer-welcome-update =
    這會將 Inbox Classic { $installed }更新為{ $version }。

    如果它正在執行，會先將其關閉。您的帳戶與郵件都會保留。
win-installer-older-ask = 已安裝的 Inbox Classic { $installed }比{ $version }新。仍要安裝舊版嗎？
win-installer-still-running = Inbox Classic 仍在執行中。請將它關閉後再試一次。
win-installer-remove-mail-ask = 要一併移除 Inbox Classic 的本機資料嗎？包括帳戶、已下載的郵件、排入佇列的郵件、設定、連絡人、規則與加密金鑰。伺服器上的郵件，以及系統認證存放區中的項目會保留。
