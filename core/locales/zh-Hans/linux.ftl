# 简体中文。草稿，等待母语审阅（见 core/locales/GLOSSARY.md）。

# Linux 应用自身窗口的文字（linux/src），ID 以 gtk- 开头。{ $braces } 中的占位符由应用填入；_ 标记按钮的助记键
# 字母，中文写在文字后的括号中，例如“抄送(_C)”。GNOME 有对应说法时使用 GNOME 的说法（首选项、退出）。

## 主窗口

gtk-search-looks-in = 在{ $place }中搜索的范围包括主题、发件人、收件人、附件名称和邮件正文。请检查拼写或减少搜索词。
gtk-search-still-indexing = 仍在为{ $count }封邮件的文本编制索引。稍后可能会出现更多结果。
gtk-search-results-everywhere = 在所有文件夹中{ $count ->
    [0] 没有找到
   *[other] 找到{ $count }个
}“{ $words }”的结果
gtk-search-results-in = 在{ $place }中{ $count ->
    [0] 没有找到
   *[other] 找到{ $count }个
}“{ $words }”的结果
gtk-search-indexing = 仍在为{ $count }封邮件的文本编制索引
gtk-list-loading = 正在加载...
gtk-menu-rename = 重命名...
gtk-import-one-question = 要将邮件{ $file }导入到{ $folder }吗？
gtk-files-not-saved = { $total }个文件中有{ $failed }个无法保存。
gtk-unsubscribe-one-click =
    要退订此邮件列表吗？

    Inbox Classic 将向{ $target }发送退订请求。不会打开网页，也不会发送电子邮件。
gtk-unsubscribe-mail =
    要退订此邮件列表吗？

    要退订，请向{ $target }发送一封电子邮件。Inbox Classic 会为您准备好这封邮件，发送即可确认。
gtk-unsubscribe-web =
    要退订此邮件列表吗？

    邮件列表的退订页面将在浏览器中打开（{ $target }）。
gtk-unsubscribe-failed = 无法退订：{ $problem }
gtk-toolbar-create-mail-menu = 从指定帐户撰写邮件
gtk-toolbar-send-recv-menu = 发送和接收指定帐户的邮件
gtk-main-menu = 主菜单
gtk-folder-list = 文件夹列表
gtk-quit = 退出

## “移动”和“复制”窗口

gtk-new-folder-at-top-of = 新文件夹将位于{ $account }的顶层。

## 邮件列表

## 帮助

## 通知和托盘

gtk-unread-messages = { $count ->
    [0] 没有未读邮件
   *[other] { $count }封未读邮件
}

## 撰写窗口的链接菜单

## 发件箱

gtk-outbox-empty = 没有等待发送的邮件。
gtk-outbox-row = 收件人：{ $to }  ·  排队时间：{ $queued }  ·  { $status }

## 应用

gtk-still-running-detail = Inbox Classic 会在后台继续检查新邮件。使用顶栏中的图标可打开或退出应用。
gtk-sign-in-again-ask =
    { $account }的登录被拒绝，或会话已过期。

    要在浏览器中重新登录吗？
gtk-default-app-not-installed = 此 Inbox Classic 副本未经安装，因此系统不会将其列为邮件应用。请先安装，然后再选择它。
gtk-default-app-now = Inbox Classic 现在是您的默认邮件应用：电子邮件链接会在这里打开新邮件。
gtk-default-app-failed = 无法将 Inbox Classic 设为默认邮件应用。

## 多个窗口使用的按钮和文字

## 阅读窗格

gtk-reader-date = 日期：
gtk-reader-files = 邮件附件
gtk-files = { $count }个文件
gtk-save-attachments-menu = 保存附件...

## 撰写窗口

gtk-format-bold = 粗体（Ctrl+B）
gtk-format-italic = 斜体（Ctrl+I）
gtk-format-underline = 下划线（Ctrl+U）
gtk-format-hyperlink = 超链接（Ctrl+K）
gtk-font = 字体
gtk-show-cc = 抄送(_C)
gtk-show-bcc = 密件抄送(_B)
gtk-save-tip = 保存（Ctrl+S）
gtk-link-status = { $link }    （Ctrl+单击可打开）

## 帐户

gtk-plain-warning =
    如果不加密，任何截获您网络流量的人都能读取您的密码和邮件。仅当连接已通过其他方式受到保护时才继续。仅靠局域网并不能提供加密。

    要继续吗？
gtk-account-name-title = 帐户名称
gtk-display-name-title = 显示名称
gtk-turned-off-why = “{ $button }”选项已在此计算机上停用。{ $reason }
gtk-turned-off-why-long =
    “{ $button }”选项已在此计算机上停用。

    { $reason }
gtk-next = 下一步 >
gtk-provider-sign-in = 在{ $provider }的网站上登录{ $address }。您的密码不会与 Inbox Classic 共享。如果您的帐户允许将应用密码用于邮件，也可以使用在其安全设置中创建的应用密码。Outlook.com 和 Microsoft 365 仅支持浏览器登录。
gtk-provider-sign-in-apps = 使用您的某个登录应用（更多登录选项）在{ $provider }的网站上登录{ $address }。如果您的帐户允许将应用密码用于邮件，也可以使用在其安全设置中创建的应用密码。Outlook.com 和 Microsoft 365 仅支持浏览器登录。
gtk-accounts-add = 添加...
gtk-accounts-properties = 属性...
gtk-accounts-signature = 签名...
gtk-accounts-sign-in-apps = 登录应用...

## 登录应用

gtk-app-server = { $kind }服务器
gtk-app-port = { $kind }端口
gtk-app-security = { $kind }安全性
gtk-issuer-found =
    登录页面：{ $page }
    令牌端点：{ $endpoint }
gtk-client-id = 客户端 ID
gtk-client-secret = 客户端密码
gtk-scopes = 范围
gtk-redirect-uri = 重定向 URI
gtk-issuer-usable =
    可以使用此颁发者。

    { $found }
gtk-app-built-in = { $app }是内置的。您只能更改是否为新帐户提供它。{ $reason }
gtk-built-in = { $app }（内置）
gtk-offered-for-new = 提供给新帐户
gtk-edit-button = 编辑...
gtk-remove-app-ask = 要删除登录应用{ $app }及其已保存的客户端密码吗？
gtk-sign-in-apps-intro = 登录应用让帐户可以通过浏览器登录。已关闭的登录应用不会提供给新帐户；已在使用它的帐户可继续正常工作。

## AI 代理

gtk-agent-it-may = 允许的操作
gtk-agent-accounts = 允许的帐户
gtk-never-used = 从未使用
gtk-last-used = 上次使用：{ $date }
gtk-forget-program = 要删除此程序已保存的权限吗？
gtk-forget-program-detail = 此程序的权限及其代理的活动历史记录将被删除。下次连接时，将再次请求您的许可。
gtk-no-agents-yet = 尚无代理请求使用您的邮件。
gtk-nothing-yet = 暂无内容。

## 首选项

gtk-preferences = 首选项
gtk-notify-subtitle = 仅在 Inbox Classic 的主窗口不在最前面时

## 桌面项和软件商店页面

# linux/data/com.inboxclassic.InboxClassic.desktop and .metainfo.xml, made by the build. The keywords are the words a
# search of the applications finds Inbox Classic by, each ended by a semicolon, in your language only: the English
# ones are added before them
gtk-desktop-generic-name = 邮件客户端
gtk-desktop-comment = 阅读和撰写电子邮件：快速、简洁的邮件程序
gtk-desktop-keywords = 邮件;电子邮件;邮箱;收件箱;发邮件;
gtk-metainfo-summary = 快速、简洁的邮件程序
gtk-metainfo-description = Inbox Classic 用于阅读和撰写电子邮件。它采用经典布局：左侧是文件夹，上方是邮件，下方是所选邮件。它适用于兼容的 IMAP 和 SMTP 帐户，并可通过浏览器登录 Outlook.com 和 Microsoft 365。
gtk-metainfo-feature-sanitized = 邮件中的脚本和其他活动内容会被删除；来自 Internet 的图片只有在您允许后才会加载
gtk-metainfo-feature-search = 使用熟悉的 Gmail 风格运算符搜索主题、发件人、收件人、附件名称和邮件正文
gtk-metainfo-feature-replies = 答复会折叠其引用的早期邮件
gtk-metainfo-feature-offline = 已下载的邮件在本地副本保留期间可离线阅读；登录凭据通常会使用系统密钥环（如果可用）
