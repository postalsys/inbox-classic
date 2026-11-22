# 简体中文。草稿，等待母语审阅（见 core/locales/GLOSSARY.md）。

# Mac 应用自身窗口的文字（mac/Sources），ID 以 mac- 开头；菜单以及各平台共用的文字在 app.ftl 和 core.ftl 中。
# { $braces } 中的占位符由应用填入。Mac 惯例：需要进一步输入的命令后加省略号（…），使用弯引号。

## 应用及其菜单

# review: new
mac-quit = 退出 Inbox Classic
# review: new
mac-settings = 设置…
# review: new
mac-services = 服务
# review: new
mac-hide = 隐藏 Inbox Classic
# review: new
mac-hide-others = 隐藏其他
# review: new
mac-show-all = 全部显示
# review: new
mac-check-updates = 检查更新…
# review: new
mac-close-window = 关闭窗口
# review: new
mac-redo = 重做
# review: new
mac-cut = 剪切
# review: new
mac-paste = 粘贴
# review: new
mac-menu-window = 窗口
# review: new
mac-minimize = 最小化
# review: new
mac-zoom = 缩放
# review: new
mac-no-updates = 此版本的 Inbox Classic 不支持自动更新。请从 inboxclassic.com 下载最新版本。

## 设置

# review: new
mac-settings-title = 设置
# the Mac only: Sparkle's automatic check for a new version, in General
# review: new
mac-check-updates-automatically = 自动检查更新
# the title of that group, in the label column of the pane
# review: new
mac-settings-updates = 更新

## 对话框

# review: new
mac-choose = 选取

## 主窗口

# review: new
mac-still-running-detail = Inbox Classic 会在后台继续检查新邮件。点按程序坞中的图标即可打开应用。
# review: new
mac-outbox-waiting = 发件箱中有{ $count }封邮件
# review: new
mac-sending = 正在发送{ $subject }…
# review: new
mac-checking = 正在检查{ $account }上的新邮件…
# review: new
mac-account-said = { $account }：{ $message }
# review: new
mac-not-bundle = 此 Inbox Classic 副本不是应用包，因此不能设为默认邮件应用。
# review: new
mac-not-made-default = 未能将 Inbox Classic 设为默认邮件应用：{ $reason }
# review: new
mac-tool-search = 搜索

## 文件夹和邮件列表

# review: new
mac-still-indexing-more = 仍在为{ $count }封邮件的文本编制索引，稍后可能会找到更多结果。
# review: new
mac-results-everywhere =
    { $count ->
        [0] 在所有文件夹中没有找到“{ $words }”的结果
       *[other] 在所有文件夹中找到{ $count }个“{ $words }”的结果
    }
# review: new
mac-results-in =
    { $count ->
        [0] 在{ $folder }中没有找到“{ $words }”的结果
       *[other] 在{ $folder }中找到{ $count }个“{ $words }”的结果
    }
# review: new
mac-still-indexing = 仍在为{ $count }封邮件的文本编制索引
# review: new
mac-folder-unread = { $folder }，{ $count }封未读
# review: new
mac-import-messages = 导入邮件
# review: new
mac-save-messages = 保存邮件
# review: new
mac-save-attachments-menu = 保存附件…
# review: new
mac-files-not-saved = { $count }个文件中有{ $failed }个无法保存。
# review: new
mac-no-calendar-app = 无法打开邀请。请检查这台 Mac 上是否已设置用日历应用打开 .ics 文件。
# review: new
mac-file-not-saved = 无法保存文件。
# review: new
mac-unsubscribing = 正在退订{ $target }…
# review: new
mac-loading-list = 正在载入…

## 撰写窗口

# review: new
mac-bold = 粗体
# review: new
mac-italic = 斜体
# review: new
mac-underline = 下划线
# review: new
mac-bcc = 密件抄送
# review: new
mac-command-click-to-open = 按住 Command 键点按以打开
# review: new
mac-saving-to-drafts = 正在保存到“草稿”…
# review: new
mac-dont-save = 不保存

## 阅读窗格

# review: new
mac-files = { $count }个文件

## 帐户

# review: new
mac-next = 继续
# review: new
mac-name-placeholder = 张三
# review: new
mac-more-sign-in-options = 更多登录选项…
# review: new
mac-add-sign-in-app = 添加登录应用…
# review: new
mac-looking-up = 正在查找{ $domain }的设置…
# review: new
mac-add-button = 添加…
# review: new
mac-properties-button = 属性…
# review: new
mac-signature-button = 签名…
# review: new
mac-security-button = 安全…
# review: new
mac-sign-in-apps-button = 登录应用…

## AI 代理

# review: new
mac-forget-program = 要移除此程序及其代理的活动历史记录吗？
# review: new
mac-forget-program-detail = 此程序的权限将被删除。下次连接时，将再次请求您的许可。

## 登录应用

# review: new
mac-checking-issuer = 正在检查{ $issuer }…
# review: new
mac-edit-button = 编辑…
# review: new
mac-use-for-new-accounts = 将{ $name }用于新帐户
# review: new
mac-built-in = { $name }（内置）

## 其他窗口

# review: new
mac-new-folder-button = 新建文件夹…
# review: new
mac-edit-link = 编辑链接…
