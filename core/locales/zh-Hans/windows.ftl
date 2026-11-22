# 简体中文。草稿，等待母语审阅（见 core/locales/GLOSSARY.md）。

# Windows 应用自身窗口的文字（app/src），ID 以 win- 开头。{ $braces } 中的占位符由应用填入；& 标记菜单或按钮的
# 访问键字母（&& 表示 & 符号）。

## 主窗口

win-still-running-detail = Inbox Classic 会在后台继续检查新邮件。单击图标可打开它。要退出，请右键单击图标并使用其菜单。
win-default-app-not-installed = 此 Inbox Classic 副本未经安装，因此 Windows 不会将其列为邮件应用。请先安装，然后再选择它。
win-default-app-settings = Windows 将打开“默认应用”设置。请选择 Inbox Classic 来打开 MAILTO 链接。
win-no-unread = 没有未读邮件
win-unread-messages = { $count }封未读邮件
win-print-failed = 无法打印邮件。
win-print-title-of = 打印 - { $subject }
win-no-bodies = 无法显示邮件正文。
win-webview-failed = 创建 WebView2 失败。
win-webview-missing = WebView2 运行时不可用。
win-list-loading = 正在加载...

## 多个窗口使用的按钮和文字

win-delete-button = 删除(&D)
win-find-label = 查找(&F)：
win-save-as-button = 另存为(&E)...
win-too-many-files = 一次选择的文件过多：请减少文件数量。

## 发件箱


## 撰写窗口

win-editor-failed = 无法撰写邮件。
win-ctrl-click-to-open = （{ $ctrl }+单击可打开）
win-format-bold = 加粗（{ $ctrl }+B）
win-format-italic = 倾斜（{ $ctrl }+I）
win-format-underline = 下划线（{ $ctrl }+U）
win-format-link = 超链接（{ $ctrl }+K）
win-show-cc = 抄送(&C)
win-show-bcc = 密件抄送(&B)
win-signature-title = 签名：{ $account }

## 文件夹、邮件列表和阅读窗格

win-search-found-all = { $count ->
    [0] 在所有文件夹中没有找到“{ $words }”的结果
   *[other] 在所有文件夹中找到{ $count }个“{ $words }”的结果
}
win-search-found-in = { $count ->
    [0] 在{ $folder }中没有找到“{ $words }”的结果
   *[other] 在{ $folder }中找到{ $count }个“{ $words }”的结果
}
win-search-indexing = 仍在为{ $count }封邮件的文本编制索引
win-no-match-indexing = 仍在为{ $count }封邮件的文本编制索引，稍后可能会找到更多结果。
win-files = { $count }个文件
win-save-attachments = 保存附件(&S)...
win-files-not-saved = { $count }个文件中有{ $failed }个无法保存。
win-new-folder-in-highlighted = 新文件夹将创建在所选文件夹中。
win-delete-folder-ask = 要删除文件夹“{ $folder }”及其中的邮件和文件夹吗？服务器上的文件夹也会被删除。
win-rename = 重命名(&R)...
win-messages-not-saved = 无法保存邮件。
win-messages-not-forwarded = 无法转发邮件。

## 帐户

win-sign-in-google = 使用 Google 账号登录
win-sign-in-microsoft = 使用 Microsoft 登录
win-next = 下一步(&N) >
win-your-account = 您的帐户
win-browser-sign-in = （浏览器登录）
win-add = 添加(&A)...
win-properties-button = 属性(&P)...
win-signature-button = 签名(&G)...
win-sign-in-apps-button = 登录应用(&S)...

## AI 代理

win-dont-allow = 不允许(&D)
win-col-address = 地址
win-never-written-to = 从未写信联系
win-book-find-label = 键入姓名或电子邮件地址：
win-send = 发送(&S)
win-dont-send = 不发送(&D)
win-unsubscribe = 退订(&U)
win-dont-unsubscribe = 不退订(&D)
win-forget-program-ask = 要删除此程序已保存的权限及其代理的活动历史记录吗？该程序不会被卸载。下次连接时，将再次请求您的许可。
win-clear-log-ask = 要清除代理的活动历史记录吗？这不会撤消代理所做的更改。
win-agent-programs = 其代理已请求访问您邮件的程序(&P)：
win-change = 更改(&C)...
# Tools > AI Agents: takes back everything the selected program did in a span the user picks
win-undo-since = 按时间段撤消(&S)...
win-take-back = 撤回(&T)
win-what-agents-did = 代理活动(&A)：
# under the log of Tools > AI Agents: what the selected row of reads covers (the start and end of its hour), or how to see it
win-agent-reads = { $from }至{ $to }读取的内容：
win-agent-reads-hint = 在上方选择一行读取记录，即可查看读取了哪些内容。

## 登录应用

win-built-in = （内置）
win-edit = 编辑(&E)...

## 选项

win-folders-hide = 隐藏文件夹列表
win-folders-pin = 将文件夹列表固定在邮件旁边
win-folders-show = 显示文件夹

## 安装程序

# the installer's own words (installer/inbox-classic.nsi), made into installer/languages.nsh by the build;
# { $version } and { $installed } are version numbers, 0.18.0
win-installer-start = 启动 Inbox Classic
win-installer-welcome-new =
    此向导将安装电子邮件程序 Inbox Classic { $version }。

    无需管理员权限，仅为当前 Windows 用户安装。
win-installer-welcome-same =
    已安装 Inbox Classic { $version }。此向导将重新安装它。

    您的帐户和邮件将保留。
win-installer-welcome-update =
    此向导将把 Inbox Classic { $installed }更新到{ $version }。

    如果它正在运行，将先将其关闭。您的帐户和邮件将保留。
win-installer-older-ask = 已安装的 Inbox Classic { $installed }比{ $version }更新。仍要安装旧版本吗？
win-installer-still-running = Inbox Classic 仍在运行。请将其关闭后重试。
win-installer-remove-mail-ask = 是否同时删除 Inbox Classic 的本地数据，包括帐户、已下载的邮件、排队的邮件、设置、联系人、规则和加密密钥？服务器上的邮件和系统凭据存储中的条目将保留。
