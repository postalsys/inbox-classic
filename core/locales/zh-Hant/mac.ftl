# 繁體中文（台灣）草稿，等待母語人士審閱。
# Mac 應用程式自身視窗的文字（mac/Sources），識別碼以 mac- 開頭；功能表與各平台共用的文字在 app.ftl 與 core.ftl 中。
# { $braces } 中的預留位置由應用程式填入。用語依循 Apple 的繁體中文（台灣）慣例。

## 應用程式與其功能表

# review: new
mac-quit = 結束 Inbox Classic
# review: new
mac-settings = 設定...
# review: new
mac-services = 服務
# review: new
mac-hide = 隱藏 Inbox Classic
# review: new
mac-hide-others = 隱藏其他
# review: new
mac-show-all = 顯示全部
# review: new
mac-check-updates = 檢查更新項目...
# review: new
mac-close-window = 關閉視窗
# review: new
mac-redo = 重做
# review: new
mac-cut = 剪下
# review: new
mac-paste = 貼上
# review: new
mac-menu-window = 視窗
# review: new
mac-minimize = 縮到最小
# review: new
mac-zoom = 縮放
# review: new
mac-no-updates = 這個版本的 Inbox Classic 不支援自動更新。請從 inboxclassic.com 下載最新版本。

## 設定

# review: new
mac-settings-title = 設定
# the Mac only: Sparkle's automatic check for a new version, in General
# review: new
mac-check-updates-automatically = 自動檢查更新項目
# the title of that group, in the label column of the pane
# review: new
mac-settings-updates = 更新

## 對話框

# review: new
mac-choose = 選擇

## 主視窗

# review: new
mac-still-running-detail = Inbox Classic 會繼續在背景檢查新郵件。按一下 Dock 中的圖示即可開啟 App。
# review: new
mac-outbox-waiting = 寄件匣中有{ $count }封郵件
# review: new
mac-sending = 正在傳送{ $subject }...
# review: new
mac-checking = 正在檢查{ $account }的新郵件...
# review: new
mac-account-said = { $account }：{ $message }
# review: new
mac-not-bundle = 這份 Inbox Classic 不是 App 套件，因此無法設為預設郵件 App。
# review: new
mac-not-made-default = 未將 Inbox Classic 設為預設郵件 App：{ $reason }
# review: new
mac-tool-search = 搜尋

## 資料夾與郵件清單

# review: new
mac-still-indexing-more = 仍在為{ $count }封郵件的內文建立索引，稍後可能會找到更多結果。
# review: new
mac-results-everywhere =
    { $count ->
        [0] 在所有資料夾中找不到「{ $words }」
       *[other] 在所有資料夾中找到{ $count }個「{ $words }」的結果
    }
# review: new
mac-results-in =
    { $count ->
        [0] 在{ $folder }中找不到「{ $words }」
       *[other] 在{ $folder }中找到{ $count }個「{ $words }」的結果
    }
# review: new
mac-still-indexing = 仍在為{ $count }封郵件的內文建立索引
# review: new
mac-folder-unread = { $folder }，{ $count }封未讀取
# review: new
mac-import-messages = 匯入郵件
# review: new
mac-save-messages = 儲存郵件
# review: new
mac-save-attachments-menu = 儲存附件...
# review: new
mac-files-not-saved = { $count }個檔案中有{ $failed }個無法儲存。
# review: new
mac-no-calendar-app = 無法開啟邀請。請確認這部 Mac 上已設定用來開啟 .ics 檔案的行事曆 App。
# review: new
mac-file-not-saved = 無法儲存檔案。
# review: new
mac-unsubscribing = 正在取消訂閱{ $target }...
# review: new
mac-loading-list = 正在載入...

## 撰寫視窗

# review: new
mac-bold = 粗體
# review: new
mac-italic = 斜體
# review: new
mac-underline = 底線
# review: new
mac-bcc = 密件副本
# review: new
mac-command-click-to-open = 按住 ⌘ 並按一下即可開啟
# review: new
mac-saving-to-drafts = 正在儲存到草稿...
# review: new
mac-dont-save = 不要儲存

## 讀取窗格

# review: new
mac-files = { $count }個檔案

## 帳戶

# review: new
mac-next = 下一步
# review: new
mac-name-placeholder = 王小明
# review: new
mac-more-sign-in-options = 更多登入選項...
# review: new
mac-add-sign-in-app = 新增登入應用程式...
# review: new
mac-looking-up = 正在查詢{ $domain }的設定...
# review: new
mac-add-button = 新增...
# review: new
mac-properties-button = 內容...
# review: new
mac-signature-button = 簽名...
# review: new
mac-security-button = 安全性...
# review: new
mac-sign-in-apps-button = 登入應用程式...

## AI 代理程式

# review: new
mac-forget-program = 要移除這個程式及其代理程式的活動記錄嗎？
# review: new
mac-forget-program-detail = 程式的權限將會刪除。下次它連接時，會再次要求您授予權限。

## 登入應用程式

# review: new
mac-checking-issuer = 正在檢查{ $issuer }...
# review: new
mac-edit-button = 編輯...
# review: new
mac-use-for-new-accounts = 在新帳戶中使用{ $name }
# review: new
mac-built-in = { $name }（內建）

## 其他視窗

# review: new
mac-new-folder-button = 新增資料夾...
# review: new
mac-edit-link = 編輯連結...
