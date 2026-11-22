# 简体中文。草稿，等待母语审阅（见 core/locales/GLOSSARY.md）。

# Mac 应用自身窗口的文字（mac/Sources），ID 以 mac- 开头；菜单以及各平台共用的文字在 app.ftl 和 core.ftl 中。
# { $braces } 中的占位符由应用填入。Mac 惯例：需要进一步输入的命令后加省略号（…），使用弯引号。

## 应用及其菜单

mac-quit = 退出 Inbox Classic
mac-settings = 设置…
mac-services = 服务
mac-hide = 隐藏 Inbox Classic
mac-hide-others = 隐藏其他
mac-show-all = 全部显示
mac-check-updates = 检查更新…
mac-close-window = 关闭窗口
mac-redo = 重做
mac-cut = 剪切
mac-paste = 粘贴
mac-menu-window = 窗口
mac-minimize = 最小化
mac-zoom = 缩放
mac-no-updates = 此版本的 Inbox Classic 不支持自动更新。请从 inboxclassic.com 下载最新版本。

## 设置

mac-settings-title = 设置
# the Mac only: Sparkle's automatic check for a new version, in General
mac-check-updates-automatically = 自动检查更新
# the title of that group, in the label column of the pane
mac-settings-updates = 更新

## 对话框

mac-choose = 选取

## 主窗口

mac-still-running-detail = Inbox Classic 会在后台继续检查新邮件。点按程序坞中的图标即可打开应用。
mac-outbox-waiting = 发件箱中有{ $count }封邮件
mac-sending = 正在发送{ $subject }…
mac-checking = 正在检查{ $account }上的新邮件…
mac-account-said = { $account }：{ $message }
mac-not-bundle = 此 Inbox Classic 副本不是应用包，因此不能设为默认邮件应用。
mac-not-made-default = 未能将 Inbox Classic 设为默认邮件应用：{ $reason }
mac-tool-search = 搜索

## 文件夹和邮件列表

mac-still-indexing-more = 仍在为{ $count }封邮件的文本编制索引，稍后可能会找到更多结果。
mac-results-everywhere =
    { $count ->
        [0] 在所有文件夹中没有找到“{ $words }”的结果
       *[other] 在所有文件夹中找到{ $count }个“{ $words }”的结果
    }
mac-results-in =
    { $count ->
        [0] 在{ $folder }中没有找到“{ $words }”的结果
       *[other] 在{ $folder }中找到{ $count }个“{ $words }”的结果
    }
mac-still-indexing = 仍在为{ $count }封邮件的文本编制索引
mac-folder-unread = { $folder }，{ $count }封未读
mac-import-messages = 导入邮件
mac-save-messages = 保存邮件
mac-save-attachments-menu = 保存附件…
mac-files-not-saved = { $count }个文件中有{ $failed }个无法保存。
mac-no-calendar-app = 无法打开邀请。请检查这台 Mac 上是否已设置用日历应用打开 .ics 文件。
mac-file-not-saved = 无法保存文件。
mac-unsubscribing = 正在退订{ $target }…
mac-loading-list = 正在载入…

## 撰写窗口

mac-bold = 粗体
mac-italic = 斜体
mac-underline = 下划线
mac-bcc = 密件抄送
mac-command-click-to-open = 按住 Command 键点按以打开
mac-saving-to-drafts = 正在保存到“草稿”…
mac-dont-save = 不保存

## 阅读窗格

mac-files = { $count }个文件

## 帐户

mac-next = 继续
mac-name-placeholder = 张三
mac-more-sign-in-options = 更多登录选项…
mac-add-sign-in-app = 添加登录应用…
mac-looking-up = 正在查找{ $domain }的设置…
mac-add-button = 添加…
mac-properties-button = 属性…
mac-signature-button = 签名…
mac-security-button = 安全…
mac-sign-in-apps-button = 登录应用…

## AI 代理

mac-forget-program = 要删除此程序已保存的权限及其代理的活动历史记录吗？
mac-forget-program-detail = 此程序的权限将被删除。下次连接时，将再次请求您的许可。

## 登录应用

mac-checking-issuer = 正在检查{ $issuer }…
mac-edit-button = 编辑…
mac-use-for-new-accounts = 将{ $name }用于新帐户
mac-built-in = { $name }（内置）

## 其他窗口

mac-new-folder-button = 新建文件夹…
mac-edit-link = 编辑链接…
