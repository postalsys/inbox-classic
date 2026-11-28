# 简体中文。草稿，等待母语审阅（见 core/locales/GLOSSARY.md）。

# 核心所说的话，各平台相同。{ $braces } 中的占位符由代码填入；请保留它们，放在语言需要的位置。
# 中文只有 *[other] 一种复数形式；需要区分“1”时使用 [1]。

## 计数和大小

messages = { $count }封邮件
# the separator of decimals in sizes: 2.4 MB
decimal-separator = .
# what goes between the items of a list of words
list-separator = 、
size-bytes = { $count }字节
size-kb = { $size } KB
size-mb = { $size } MB
size-gb = { $size } GB
send-delay-off = 关
send-delay-seconds = { $count }秒
# the status bar: "12 messages, 3 unread"
list-counts = { $messages }，{ $unread }封未读
list-counts-selected = { $messages }，{ $unread }封未读，已选择{ $selected }封
# the status bar while searching: "12 found, 3 unread"
list-counts-found = 找到{ $found }封，{ $unread }封未读
list-counts-found-selected = 找到{ $found }封，{ $unread }封未读，已选择{ $selected }封
list-counts-none = 未找到邮件

## 特殊文件夹，沿用 Outlook Express 的名称

folder-inbox = 收件箱
folder-sent = 已发送邮件
folder-deleted = 已删除邮件
folder-drafts = 草稿
folder-junk = 垃圾邮件
folder-archive = 存档

## 阅读窗格

reader-no-message = 未选择邮件。
reader-downloading = 正在下载邮件…
reader-downloading-detail = 下载完成后，邮件将显示在这里。
reader-downloading-size = 此邮件大小为{ $size }。下载完成后将显示在这里。
reader-failed = 无法下载邮件
reader-failed-network = 无法连接到邮件服务器，或连接已中断（{ $reason }）。
reader-failed-security = 无法与邮件服务器建立安全连接（{ $reason }）。
reader-failed-other = 邮件服务器回复：{ $reason }。
reader-retry-note = 帐户重新连接时将再次尝试。
reader-unreadable = 无法显示此邮件：{ $error }
message-source-title = 邮件源文件：{ $subject }
message-source-untitled = 邮件源文件

## 打印邮件，以及答复或转发中引用的邮件标头

header-from = 发件人
header-date = 日期
header-to = 收件人
header-cc = 抄送
header-sent = 发送时间
header-subject = 主题
header-security = 安全
header-part = 第{ $number }部分
quote-original = ----- 原始邮件 -----
fold-show-earlier = 显示之前的邮件

## 退信：邮件未送达通知顶部的卡片

bounce-failed = 您的邮件未能送达
bounce-delayed = 您的邮件尚未送达
bounce-delayed-note = 您的邮件服务器仍在尝试投递。您无需再次发送。
# the link to the message the notice is about, in Sent Items or another folder
bounce-show-message = 显示被退回的邮件
# the link of a delay's card to the message that is still on its way
bounce-show-delayed = 显示延迟的邮件
bounce-what-to-do = 您可以这样做：
# what to do about a recipient the message is still on its way to: in the card of a delay, and in the card of a failure
bounce-delayed-do = 暂时无需任何操作。如果仍无法投递，您会收到另一封通知。
bounce-delayed-row-do = 暂时无需任何操作。您的邮件服务器仍在尝试投递，如果无法投递，您会收到另一封通知。
# folds the receiving server's own words
bounce-details = 详细信息
# a recipient the notice does not name
bounce-someone = 一位收件人
# in Details: the server that refused the message, the status code it gave, and the server that wrote the notice
bounce-server = 服务器：{ $server }
bounce-status = 状态：{ $status }
bounce-reported-by = 报告方：{ $server }
bounce-retry-minutes = 接收服务器要求在下次尝试前等待{ $count }分钟。
bounce-retry-hours = 接收服务器要求在下次尝试前等待{ $count }小时。
# the names of the blocklists, "Spamhaus ZEN, Barracuda"
bounce-blocklist = 阻止列表：{ $lists }
bounce-user-unknown = 该地址不存在
bounce-user-unknown-why = 接收服务器上没有使用此地址的邮箱。地址可能输入有误，或者对方已不再使用此地址。
bounce-user-unknown-do = 请检查地址的拼写，或向对方询问其现在使用的地址。
bounce-invalid-address = 该地址无效
bounce-invalid-address-why = 该地址的格式不正确，无法向其发送邮件。
bounce-invalid-address-do = 请检查是否有输入错误，例如多了空格、少了字母，或 @ 后面没有内容。
bounce-mailbox-disabled = 该邮箱已关闭
bounce-mailbox-disabled-why = 该地址存在，但其邮箱已被停用或不再使用。
bounce-mailbox-disabled-do = 请通过其他方式联系对方，询问其现在使用的地址。
bounce-mailbox-full = 该邮箱已满
bounce-mailbox-full-why = 收件人的邮箱没有空间接收新邮件。
bounce-mailbox-full-do = 请过几天再发送一次，或通过其他方式告知对方。
bounce-spam-blocked = 被当作垃圾邮件拒收
bounce-spam-blocked-why = 接收服务器将此邮件视为垃圾邮件。
bounce-spam-blocked-do = 请去掉看起来像垃圾邮件的内容后再发送，例如大量链接、短链接或较大的附件。如果问题持续出现，请咨询您的邮件提供商。
bounce-virus-detected = 因病毒被拒收
bounce-virus-detected-why = 接收服务器报告邮件或其附件中含有病毒或其他有害内容。
bounce-virus-detected-do = 请用病毒扫描程序检查附件。有些服务器会拒收所有程序和压缩文件，因此请改为以链接形式共享此类文件。
bounce-ip-blocklisted = 您的邮件服务器在阻止列表中
bounce-ip-blocklisted-why = 接收服务器拒收来自发送您邮件的服务器的邮件，因为该服务器的地址在阻止列表中。
bounce-ip-blocklisted-do = 问题不在邮件本身。请将此通知转发给您的邮件提供商，请他们设法将该服务器从列表中移除。
bounce-domain-blocklisted = 某个域在阻止列表中
bounce-domain-blocklisted-why = 接收服务器拒收此邮件，因为您地址的域或邮件中链接的某个域在阻止列表中。
bounce-domain-blocklisted-do = 如果邮件中有链接，请尝试去掉链接后再发送。否则，请将此通知转发给您的域的邮件管理员。
bounce-policy-blocked = 被接收服务器的规则拒收
bounce-policy-blocked-why = 接收服务器的规则不允许此邮件通过，例如由于其大小、附件或发件人。
bounce-policy-blocked-do = “详细信息”下服务器的原话通常会说明原因。请询问收件人是否能接收此类邮件。
bounce-geo-blocked = 因来源地被拒收
bounce-geo-blocked-why = 接收服务器不接收来自您邮件服务器所在国家或网络的邮件。
bounce-geo-blocked-do = 请通过其他方式联系对方，或咨询您的邮件提供商。
bounce-relay-denied = 服务器拒绝转发
bounce-relay-denied-why = 某台服务器拒绝继续投递此邮件，通常是因为发送时未登录，或经由了不处理此收件人的服务器。
bounce-relay-denied-do = 请在帐户设置中检查发送服务器和登录信息。
bounce-auth-failure = 无法验证您的发件人地址
bounce-auth-failure-why = 接收服务器无法确认此邮件确实来自您的域（SPF、DKIM 或 DMARC）。
bounce-auth-failure-do = 请将此通知转发给您的域的邮件管理员：其设置需要修正。在此期间，通过您的提供商自己的服务器发送可能会有帮助。
bounce-rate-limited = 短时间内邮件过多
bounce-rate-limited-why = 接收服务器暂时减少了从您的邮件服务器接收的邮件数量。
bounce-rate-limited-do = 请稍等一段时间后再发送。给许多人写信时，请每次少发给一些人。
bounce-greylisting = 被暂时延迟
bounce-greylisting-why = 接收服务器要求未知发件人稍后重试，这是一种常见的反垃圾邮件检查。
bounce-greylisting-do = 如果只是暂时延迟，发送服务器通常会自动重试。如果此通知报告的是最终失败，请稍后再次发送邮件。
bounce-server-error = 接收服务器出现问题
bounce-server-error-why = 无法连接到接收服务器，或者接收服务器因自身问题无法接收此邮件。
bounce-server-error-do = 请稍后再次发送。如果仍然失败，请检查地址中 @ 后面的部分是否有输入错误。
bounce-unknown = 未送达
bounce-unknown-why = 通知中没有明确说明原因。
bounce-unknown-do = “详细信息”下服务器的原话可能会提供更多信息。如果没有帮助，请将此通知转发给您的邮件提供商。

## 选择了多封邮件

selection-title = 已选择{ $count }封邮件
selection-unread = { $count }封未读
selection-flagged = { $count }封带标志
delete-for-good-one = 此邮件将被永久删除。要删除吗？
delete-for-good-all = 这{ $count }封邮件将被永久删除。要删除吗？
delete-for-good-some = { $total }封邮件中有{ $count }封将被永久删除。要删除这些邮件吗？
done-read = { $count ->
   *[other] 已将{ $messages }标记为已读
}
done-unread = { $count ->
   *[other] 已将{ $messages }标记为未读
}
done-flagged = { $count ->
   *[other] 已为{ $messages }设置标志
}
done-unflagged = 已清除{ $messages }的标志
done-deleted-for-good = { $count ->
   *[other] 已永久删除{ $messages }
}
done-archived = { $count ->
   *[other] 已存档{ $messages }
}
done-moved = { $count ->
   *[other] 已将{ $messages }移动到{ $folder }
}
done-copied = { $count ->
   *[other] 已将{ $messages }复制到{ $folder }
}
done-moving = { $count ->
   *[other] 正在将{ $messages }移动到{ $folder }...
}
done-copying = { $count ->
   *[other] 正在将{ $messages }复制到{ $folder }...
}
done-moved-back = { $count ->
   *[other] 已将{ $messages }移回{ $folder }
}
# the status bar after Watch Conversation and Ignore Conversation, and after either again on a marked one
done-watched = { $count ->
    [1] 正在监视该对话
   *[other] 正在监视{ $count }个对话
}
done-unwatched = { $count ->
    [1] 已停止监视该对话
   *[other] 已停止监视{ $count }个对话
}
done-ignored = { $count ->
    [1] 正在忽略该对话
   *[other] 正在忽略{ $count }个对话
}
done-unignored = { $count ->
    [1] 已停止忽略该对话
   *[other] 已停止忽略{ $count }个对话
}
their-folders = 各自原来的文件夹
undo-move = 撤消移动
undo-delete = 撤消删除
undo-archive = 撤消存档
undo-junk = 撤消标记为垃圾邮件
undo-not-junk = 撤消标记为非垃圾邮件
undo-send = 撤消发送
nothing-to-undo = 没有可撤消的操作。
messages-gone = 这些邮件已不存在。
# A non-selectable IMAP folder cannot contain messages; this does not mean it is empty.
folder-holds-no-messages = 此文件夹不能包含邮件。
not-archived-here = 此文件夹中的邮件无法存档。
not-emptied-here = 只能清空“已删除邮件”和“垃圾邮件”。
next-unread-question = { $folder }中没有更多未读邮件。

    要转到下一个有未读邮件的文件夹{ $next }吗？
no-unread-left = 没有剩余的未读邮件。
empty-question = { $count ->
    [1] 要清空{ $folder }吗？

        其中的邮件将被永久删除，无法恢复。
   *[other] 要清空{ $folder }吗？

        其中的{ $messages }将被永久删除，无法恢复。
}
no-junk-folder = 此帐户没有可将邮件移入的“垃圾邮件”文件夹。
no-inbox-folder = 此帐户没有可将邮件移入的“收件箱”文件夹。
# the status bar after a flag in a colour: "Flagged 2 messages blue"
done-flagged-color = 已为{ $messages }设置{ $color ->
    [red] 红色
    [orange] 橙色
    [yellow] 黄色
    [green] 绿色
    [blue] 蓝色
    [purple] 紫色
   *[gray] 灰色
}标志
# the Flag menu: the colours of Apple Mail's flags
flag-color = { $color ->
    [red] 红色
    [orange] 橙色
    [yellow] 黄色
    [green] 绿色
    [blue] 蓝色
    [purple] 紫色
   *[gray] 灰色
}

## “移动”和“复制”窗口

move-window-title-move = { $count ->
    [1] 移动邮件
   *[other] 移动{ $count }封邮件
}
move-window-title-copy = { $count ->
    [1] 复制邮件
   *[other] 复制{ $count }封邮件
}
move-window-prompt-move = { $count ->
    [1] 将所选邮件移动到：
   *[other] 将所选的{ $count }封邮件移动到：
}
move-window-prompt-copy = { $count ->
    [1] 将所选邮件复制到：
   *[other] 将所选的{ $count }封邮件复制到：
}
# the folders used last, over the folder tree
targets-recent = 最近使用
# the folder the messages are in, which can not be chosen
target-current = { $folder }（当前）
# a folder used last, with its account when there are several: "Archive (Work)"
target-recent = { $folder }（{ $account }）

## 移动和复制到另一个帐户

transfer-moving = 正在将{ $messages }移动到{ $folder }，已完成{ $done }封...
transfer-copying = 正在将{ $messages }复制到{ $folder }，已完成{ $done }封...
transfer-another-account = 另一个帐户
transfer-folder-gone = 目标文件夹已不存在
transfer-not-on-server = 邮件已不在服务器上
transfer-not-moved = { $count ->
   *[other] 无法将{ $messages }移动到另一个帐户：{ $reason }
}
transfer-not-copied = { $count ->
   *[other] 无法将{ $messages }复制到另一个帐户：{ $reason }
}
transfer-none-moved = 未能移动任何邮件
transfer-none-copied = 未能复制任何邮件

## 邮件文件

export-not-in-time = 未能及时下载邮件
export-not-saved = { $messages }中有{ $failed }封无法保存（{ $problems }）
export-not-attached = 无法附加邮件：{ $error }
# the status bar after Save As with several: "Saved 3 messages to Desktop"
saved-to = { $count ->
   *[other] 已将{ $messages }保存到{ $folder }
}
download-progress = 正在下载{ $done }，共{ $total }
download-done = 已下载{ $size }
downloading-messages = { $count ->
   *[other] 正在下载{ $messages }...
}
# the status bar after files are dropped on a folder: "Put 3 messages in Archive"
import-put = { $count ->
   *[other] 已将{ $messages }加入队列，准备导入到{ $folder }
}
import-not-put = 以下各项未放入文件夹：

    { $problems }

## 窗口显示的问题

error-store = 本地存储：{ $error }
error-not-found = 未找到
error-closed = 正在关闭
error-other-account = 浏览器登录的是{ $email }，而不是此帐户
# a password or sign-in the mail server refused, with the server's words
failure-authentication = 服务器未接受登录（{ $reason }）
# the mail server could not be reached or the connection broke, with the reason
failure-network = 与服务器的连接失败（{ $reason }）
error-in-use = 仍有帐户使用它登录，因此无法删除：{ $accounts }
error-turned-off = 此登录应用已对新帐户关闭
error-folder-name = 文件夹名称的长度必须为 1 到 200 个字符，且不能包含控制字符
error-folder-separator = 在此服务器上，文件夹名称中不能包含“{ $separator }”
error-folder-special = 收件箱和特殊文件夹不能重命名或删除
error-no-recipients = 邮件没有收件人
error-bad-address = “{ $address }”不是电子邮件地址
error-not-own-address = { $address }不是此帐户的发件人地址之一。请在帐户属性中将其添加到“您用于发送邮件的其他地址”。
rule-query-refused = 规则不能按文件夹或日期筛选（{ $words }）。
rule-no-query = 请输入用于筛选传入邮件的搜索条件。
rule-no-action = 请为规则至少选择一项操作。
error-attachment = 无法读取{ $path }：{ $error }
error-no-drafts = 此帐户没有可保存邮件的“草稿”文件夹
error-draft-attachment = 无法保留草稿的某个附件：{ $error }
error-password-not-saved = 无法保存密码供下次启动时使用：{ $error }
error-sign-in-not-saved = 无法保存新的登录信息供下次启动时使用：{ $error }
error-import-unreadable = 无法读取{ $path }：{ $error }
error-import-too-large = { $path }大于 50 MB
error-import-not-mail = { $path }不是电子邮件
error-list-answered = 邮件列表服务器返回了状态{ $status }
error-not-built = 无法生成邮件
error-outbox-waits = { $count ->
    [1] 邮件仍在发件箱中；下次发送/接收时将再次尝试发送
   *[other] { $count }封邮件仍在发件箱中；下次发送/接收时将再次尝试发送
}
error-draft-not-removed = 无法从“草稿”中删除此邮件的早期草稿：{ $reason }
error-sent-but = 邮件已发送，但{ $problem }
error-sent-still-in-outbox = 它仍在发件箱中：{ $error }
error-sent-no-copy = 无法在“已发送邮件”中保存副本：{ $reason }
error-no-password = 此帐户没有密码
error-no-sign-in = 此帐户没有登录信息
error-provider-missing = 此版本中没有该登录应用（ID：{ $provider }）。它可能已被删除
error-provider-servers = 此帐户的服务器与其登录应用的服务器不匹配
error-app-scopes = { $reason }。邮件服务器未接受登录应用的令牌：请检查该应用的范围是否授予了邮件访问权限
error-in-folder = { $folder }：{ $reason }

## 登录应用

sign-in-off-google = 内置的 Google 登录应用是为经过批准的测试用户设置的，默认对新帐户关闭。测试用户可以在“登录应用”（文件 > 帐户）中将其打开。您也可以使用自己的 Google 登录应用，或使用应用密码（如果您的帐户支持）。
sign-in-off-other = 它已对新帐户关闭。您可以在“登录应用”（文件 > 帐户）中将其打开。
sign-in-app-no-name = 登录应用需要名称
sign-in-app-no-client = 缺少客户端 ID
sign-in-app-no-scopes = 登录应用需要授予邮件访问权限的范围
sign-in-app-bad-host = { $server }服务器地址缺失，或不是有效的主机名
sign-in-app-plain = { $server }服务器必须使用 SSL/TLS 或 STARTTLS
sign-in-app-not-checked = 尚未检查颁发者
sign-in-app-issuer-changed = 颁发者已更改：请重新键入客户端密码，或将其删除
sign-in-register-google = 在 Google Cloud Console 中，创建类型为“桌面应用”的 OAuth 客户端，并在其同意屏幕上添加 https://mail.google.com/ 范围。应用处于测试阶段时，只有其测试用户可以登录。
sign-in-register-microsoft = 在 Microsoft Entra 中注册一个应用：平台为“移动和桌面应用程序”，重定向 URI 为 http://localhost ，允许公共客户端流，并添加委托的权限 IMAP.AccessAsUser.All、SMTP.Send 和 offline_access。如果仅用于您的组织，请使用 https://login.microsoftonline.com/<租户 ID>/v2.0 作为颁发者。
sign-in-register-other = 注册一个本机（公共）客户端，并使用下方的重定向 URI；提供商必须允许该 URI 使用任意端口（RFC 8252）。添加提供商用于授予邮件访问权限的范围。

## 日历邀请

repeats = 重复
repeats-every = { $unit ->
    [day] { $interval ->
        [1] 每天
       *[other] 每{ $interval }天
    }
    [week] { $interval ->
        [1] 每周
       *[other] 每{ $interval }周
    }
    [month] { $interval ->
        [1] 每月
       *[other] 每{ $interval }个月
    }
   *[year] { $interval ->
        [1] 每年
       *[other] 每{ $interval }年
    }
}
# "Every week on Monday, Wednesday"
repeats-on = { $repeats }的{ $days }
# "Every week, 10 times"
repeats-times = { $count ->
    [1] { $repeats }，仅一次
   *[other] { $repeats }，共{ $count }次
}
day-monday = 星期一
day-tuesday = 星期二
day-wednesday = 星期三
day-thursday = 星期四
day-friday = 星期五
day-saturday = 星期六
day-sunday = 星期日

## AI 代理

agent-level-read = 读取邮件：文件夹、文件夹中的邮件列表、对话、搜索、邮件及其文件、您的邮件规则，以及您写信联系过的人
agent-level-organize = 整理邮件：已读状态、标志及其颜色、垃圾邮件、移动、存档、创建和重命名文件夹、监视和忽略对话、删除到“已删除邮件”，以及在您同意后退订邮件列表
agent-level-drafts = 撰写草稿，由您发送
agent-level-send = 发送邮件，每封邮件都需经您同意
agent-connect-title = { $program }想要使用您的邮件
agent-connect-detail = 有 AI 代理请求与 Inbox Classic 协作。请选择它可以执行的操作以及可以查看的帐户；您以后可以在“工具 > AI 代理”下更改这些设置。

    代理会阅读他人写的邮件，而邮件可能试图欺骗代理。代理发送任何内容之前，Inbox Classic 始终会先征求您的同意。
agent-reply-to = 答复“{ $subject }”
agent-reply-all-on = 全部答复“{ $subject }”
agent-forward-of = 转发“{ $subject }”
agent-never-written-one = 您从未给{ $address }写过信。
agent-never-written-many = 这些地址中有{ $count }个您从未写信联系过。
agent-send-title = { $program }想要发送此邮件
agent-send-detail = 请检查收件人和邮件内容。确认后，邮件将在发件箱中等待{ $seconds }秒，在此期间您仍可以将其删除。
agent-change-title = { $program }可以执行的操作
agent-change-allowed = 更改此程序的 AI 代理可以对您的邮件执行的操作。
agent-change-refused = 您已拒绝此程序的访问。允许后，其代理将可以再次访问您的邮件。
agent-log-taken-back = { $entry }（已撤回）
agent-files = 文件：{ $files }
agent-undo-refused = 无法撤回。
agent-undo-refused-why = 无法撤回：{ $reason }。
agent-undo-impossible = 此操作无法撤回
agent-undo-not-in-folder = 邮件已不在该文件夹中
agent-undo-not-arrived = 邮件（尚）不在其移入的文件夹中
agent-undo-sent = 邮件已不在发件箱中
agent-original-not-downloaded = 原始邮件尚未下载。请先打开它
agent-turned-away = 已拒绝
agent-can-nothing = 无
agent-can-read = 读取
agent-can-organize = 整理
agent-can-drafts = 撰写草稿
agent-can-send = 经您同意后发送
# "Read, organize and write drafts"
agent-can-list = { $first }和{ $last }
agent-accounts = { $count ->
    [0] 无帐户
   *[other] { $count }个帐户
}
# "Read and organize; 1 account"
agent-access = { $can }；{ $accounts }
agent-unreadable = 无法读取此邮件。
agent-encrypted-original = 此邮件已加密：代理无法答复或转发它，因为代理无法加密。
agent-encrypted = 此邮件已加密。AI 代理无法读取其内容。请在 Inbox Classic 中打开它，自行阅读。
agent-too-many-changes = 过去 30 天内更改过多：此代理所做的更改已达到 Inbox Classic 在日志中为单个程序保留的上限。待最早的更改超过 30 天后，它才能进行更多更改。
agent-too-many-reads = 过去 30 天内读取过多：此代理的读取量已达到 Inbox Classic 在日志中为单个程序保留的上限。待最早的读取记录超过 30 天后，它才能读取更多内容。
list-encrypted = 加密邮件
agent-log-composed = 已在新邮件中打开“{ $subject }”，供您完成
agent-log-refused = 您未发送“{ $subject }”
agent-log-sent = 已将发给{ $to }的“{ $subject }”放入发件箱
agent-log-draft = 已保存草稿“{ $subject }”
agent-log-draft-replaced = 已替换草稿“{ $subject }”
agent-log-draft-discarded = 已请求删除草稿“{ $subject }”
agent-draft-note = 此草稿由 AI 代理{ $program }撰写。发送前请检查收件人和正文。
agent-log-read = 已将“{ $subject }”标记为已读
agent-log-unread = 已将“{ $subject }”标记为未读
agent-log-flagged = 已为“{ $subject }”设置标志
agent-log-unflagged = 已清除“{ $subject }”的标志
agent-log-deleted = 已删除“{ $subject }”
agent-log-moved = 已将“{ $subject }”移动到{ $folder }
agent-log-junk = 已将“{ $subject }”标记为垃圾邮件
agent-log-not-junk = 已将“{ $subject }”标记为非垃圾邮件
agent-log-archived = 已存档“{ $subject }”
agent-log-folder = 已请求创建文件夹“{ $name }”
# written at the user's yes, before the list is asked; a list that fails replaces it with agent-log-unsubscribe-failed
agent-log-unsubscribed = 您已同意退订邮件“{ $subject }”所属的邮件列表
agent-log-unsubscribe-failed = 无法退订邮件“{ $subject }”所属的邮件列表：{ $reason }
# "You did not unsubscribe from news@shop.example, deals@example.com": the lists' addresses, never their names
agent-log-unsubscribe-refused = 您未批准以下发件人的退订请求：{ $senders }
agent-unsubscribe-title = { $count ->
    [1] { $program }想要为您退订一个邮件列表
   *[other] { $program }想要为您退订{ $count }个邮件列表
}
agent-unsubscribe-detail = { $count ->
    [1] Inbox Classic 将以下面的列表所提供的一键方式，请求该列表停止向您发送邮件。不会发送其他任何内容，您已有的邮件也将保持原样。
   *[other] Inbox Classic 将以下面每个列表所提供的一键方式，请求各列表停止向您发送邮件。不会发送其他任何内容，您已有的邮件也将保持原样。
}
agent-log-flag-color = 已为“{ $subject }”设置{ $color ->
    [red] 红色
    [orange] 橙色
    [yellow] 黄色
    [green] 绿色
    [blue] 蓝色
    [purple] 紫色
   *[gray] 灰色
}标志
agent-log-renamed = 已请求将文件夹“{ $old }”重命名为“{ $name }”
agent-log-watched = 已监视对话“{ $subject }”
agent-log-ignored = 已忽略对话“{ $subject }”
agent-log-unmarked = 已停止监视或忽略对话“{ $subject }”
# the reason one change can not be taken back (agent-undo-refused-why)
agent-undo-changed = 此后邮件已被更改
# one change of many messages an agent made with a search (apply_to_search), a row of the log; { $query } is the search
agent-log-bulk-read = 已将{ $count }封邮件标记为已读（搜索：{ $query }）
agent-log-bulk-unread = 已将{ $count }封邮件标记为未读（搜索：{ $query }）
agent-log-bulk-flagged = 已为{ $count }封邮件设置标志（搜索：{ $query }）
agent-log-bulk-unflagged = 已清除{ $count }封邮件的标志（搜索：{ $query }）
agent-log-bulk-color = 已为{ $count }封邮件设置{ $color ->
    [red] 红色
    [orange] 橙色
    [yellow] 黄色
    [green] 绿色
    [blue] 蓝色
    [purple] 紫色
   *[gray] 灰色
}标志（搜索：{ $query }）
agent-log-bulk-moved = 已将{ $count }封邮件移动到{ $folder }（搜索：{ $query }）
agent-log-bulk-archived = 已存档{ $count }封邮件（搜索：{ $query }）
agent-log-bulk-junk = 已将{ $count }封邮件标记为垃圾邮件（搜索：{ $query }）
agent-log-bulk-not-junk = 已将{ $count }封邮件标记为非垃圾邮件（搜索：{ $query }）
agent-log-bulk-deleted = 已删除{ $count }封邮件（搜索：{ $query }）
# Undo Everything Since in the AI Agents window: how far back it reaches
agent-undo-span = { $span ->
    [quarter] 过去 15 分钟内
    [hour] 过去 1 小时内
    [hours] 过去 4 小时内
    [day] 过去 24 小时内
    [week] 过去 7 天内
   *[all] 过去 30 天内
}
# the question before it takes back what a program did in the span chosen
agent-undo-since-question = { $count ->
    [0] { $program }在此时间段内没有可以撤回的更改。
    [1] 要尝试撤回此时间段内为{ $program }记录的那项更改吗？
   *[other] 要尝试撤回此时间段内为{ $program }记录的{ $count }项更改吗？
}
agent-undo-since-detail = Inbox Classic 会尝试恢复文件夹、已读状态和标志，并删除仍在发件箱中等待的邮件。已无法撤消的更改将被跳过。之后的某些标志颜色更改可能会被覆盖。
# what taking back did, then a line for each kind of message it left as it is
agent-undo-done = { $count ->
    [0] 未撤回任何内容。
   *[other] 已全部或部分撤回{ $count }项记录的更改。
}
agent-undo-left-gone = { $count }封邮件已不在更改后所在的位置。
agent-undo-left-changed = { $count }封邮件此后已被您或服务器更改，因此保持原样。
agent-undo-left-sent = { $count }封邮件已不在发件箱中。
agent-undo-left-impossible = { $count }项更改无法撤回。
# the Send question of an agent's answer to a calendar invitation: what it answers, and when the event is
agent-invitation-reply = { $response ->
    [accept] 此邮件将接受邀请“{ $summary }”（{ $when }）。
    [tentative] 此邮件将暂定接受邀请“{ $summary }”（{ $when }）。
   *[decline] 此邮件将拒绝邀请“{ $summary }”（{ $when }）。
}邮件将发送给邀请中指定的组织者。邮件服务器接受此邮件后，您本地的答复状态即会更改，不会等待组织者日历的确认。
# the subject of an answer to an invitation, as calendar programs write it
invitation-reply-subject = { $response ->
    [accept] 已接受：{ $summary }
    [tentative] 暂定：{ $summary }
   *[decline] 已拒绝：{ $summary }
}
# the text of an answer to an invitation; { $name } is the user's name, or address
invitation-reply-text = { $response ->
    [accept] { $name }已接受此邀请。
    [tentative] { $name }已暂定接受此邀请。
   *[decline] { $name }已拒绝此邀请。
}
# what a program read in an hour, a row of the log: "Read 14 messages and searched 3 times" (joined by agent-can-list)
agent-reads-messages = 读取了{ $count }封邮件
agent-reads-attachments = 请求了{ $count }个附件
agent-reads-searches = { $count ->
    [1] 搜索了一次
   *[other] 搜索了{ $count }次
}
agent-reads-lists = { $count ->
    [1] 查看了一次文件夹的邮件列表
   *[other] 查看了{ $count }次文件夹的邮件列表
}
# each read under that row
agent-read-message = 已读取“{ $subject }”
agent-read-conversation = 已读取对话“{ $subject }”（{ $count }封邮件）
agent-read-attachment = 已请求“{ $subject }”中的附件“{ $name }”
agent-read-search = 已搜索“{ $query }”：{ $count }封邮件
agent-read-people = 已按姓名或地址查找人员：“{ $query }”
agent-read-list = 已查看{ $count }个列表条目（范围：{ $folder }）
agent-read-changes = 已查看{ $count }封新邮件的详细信息
# the programs started from a terminal app, which share one access: in the list of programs and the question when one connects
agent-terminal-programs-mac = 从{ $terminal }启动的程序
agent-terminal-programs-windows = 从终端（{ $terminal }）启动的程序
agent-terminal-programs-linux = 从终端（{ $terminal }）启动的程序
# one of them, as the questions to send or unsubscribe name it: "A program started from Terminal wants to send this message"
agent-terminal-program-mac = 从{ $terminal }启动的某个程序
agent-terminal-program-windows = 从终端（{ $terminal }）启动的某个程序
agent-terminal-program-linux = 从终端（{ $terminal }）启动的某个程序
agent-connect-title-terminal = { $programs }想要使用您的邮件
agent-connect-terminal-detail = 从同一个已识别的终端程序启动的 AI 代理共享您在此处授予的访问权限。若要为某个代理单独授予访问权限，请在该代理的 MCP 设置中，向其参数添加 --name 以及您选择的名称。该名称并不能验证其身份。
# above the question when a program said it was another one than the system found: "It said it was Claude. Inbox Classic checked which program started it: python3."
agent-connect-claimed = 它声称自己是{ $claimed }。Inbox Classic 检查了启动它的程序：{ $program }。

## 帮助中按键盘上的名称称呼的按键（Windows 和 Linux）

key-ctrl = Ctrl
key-alt = Alt
key-shift = Shift
key-del = Del
key-enter = Enter

## 登录和密码

sign-in-no-refresh = 提供商未提供刷新令牌
sign-in-no-account = 提供商未说明登录的是哪个帐户
sign-in-not-finished = 登录尚未完成
secrets-unavailable = { $store }不可用
secrets-unavailable-why = { $store }不可用：{ $error }
secrets-windows = 凭据管理器
secrets-mac = 钥匙串
secrets-linux = 系统密钥环（Secret Service）
error-no-such-file = 文件不存在
cards-file-too-big = 此文件超出了导入通讯簿的大小上限。
ui-sender-added = 已将{ $name }添加到通讯簿。
ui-sender-known = { $name }已在通讯簿中。
ui-sender-none = 此邮件的发件人没有可添加的电子邮件地址。
card-name-needed = 该联系人没有姓名，也没有电子邮件地址。
# a file of Import Address Book that could not be read: "contacts.vcf: there is no such file"
cards-file-failed = { $file }：{ $reason }

## 一次性验证码：带有登录或验证码的邮件顶部的卡片

# the domain the code is for, which signed the message
otp-heading = 来自{ $domain }的验证码
otp-copy = 复制
otp-note = 请仅在{ $domain }的页面上输入此验证码。
otp-old = 此验证码在您打开前一个多小时就已发送，可能已过期。

# how many are invited, in the card of an event
event-attendees = { $count }位参与者

# the first line of a new message's notification when it has a code, for a domain that signed it
otp-notification = { $code }是您在{ $domain }的验证码

## OpenPGP 密钥（keys.rs）
pgp-key-valid = 有效
pgp-key-expires = 有效期至{ $date }
pgp-key-expired = 已于{ $date }过期
pgp-key-revoked = 已吊销
pgp-key-revoked-why = 已吊销：{ $reason }
pgp-key-not-valid = 无效
pgp-key-locked = 无法使用：无法从{ $store }获取其保护密钥。请检查该存储是否可用且已解锁。如果保护密钥丢失，请导入私钥备份。
pgp-source-own = 在 Inbox Classic 中创建
pgp-source-file = 从文件导入
pgp-source-paste = 粘贴
pgp-source-attachment = 来自邮件
pgp-source-vcard = 来自联系人名片
pgp-source-wkd = 来自发件人的邮件提供商
pgp-source-keyserver = 来自 keys.openpgp.org
pgp-source-autocrypt = 来自邮件的 Autocrypt 标头
pgp-error-no-store = 您私钥的保护密钥保存在{ $store }中，但该存储无法使用：{ $error }
pgp-error-wrong-passphrase = 密码短语不正确。
pgp-error-not-a-key = 这不是 OpenPGP 密钥。
pgp-error-too-large = 密钥太大。
pgp-error-unusable = 此密钥无法使用。它可能缺少合适的签名或加密密钥，或者使用了不受支持的加密算法。
pgp-imported-private = { $count ->
    [1] 已导入您的私钥。
   *[other] 已导入{ $count }个私钥。
}
pgp-imported-public = 已导入{ $count }个密钥。
pgp-imported-pending = { $addresses }已在使用另一个密钥：新密钥将保存在联系人中，直到您选择使用它。
pgp-error-needs-passphrase = 此私钥受密码短语保护。请键入密码短语以导入密钥。
pgp-error-mismatch = 此私钥与其公钥不匹配。它可能已被篡改。
pgp-file-name-public = { $who }的公钥.asc
pgp-file-name-private = { $who }的私钥备份.asc
pgp-pending = 已于{ $date }找到{ $address }的另一个密钥。

## 阅读已签名和已加密的邮件（protect.rs）
pgp-part-verified = 由{ $signer }签名，已验证密钥所有者
pgp-part-signed = 由{ $signer }签名（未验证密钥所有者）
pgp-part-other = 由{ $signer }签名，此人不是发件人
pgp-part-unknown-key = 已签名，但密钥未知
pgp-part-not-signed = 未签名
pgp-part-not-checked = 未检查签名
pgp-part-encrypted = 已加密。{ $signature }
pgp-part-no-key = 已使用您没有的密钥加密
pgp-part-changed = 加密部分未通过完整性检查，因此不显示
pgp-part-unprotected = 加密时未提供防篡改保护，因此不显示
pgp-part-broken = 无法读取加密部分
pgp-why-mismatch = 签名与此文本不匹配
pgp-why-weak-hash = 签名使用的{ $hash }已不再安全
pgp-why-key-expired = 签名时间晚于密钥的过期时间（{ $date }）
pgp-why-key-revoked = 使用已吊销的密钥签名
pgp-why-not-signing-key = 使用不允许签名的密钥签名
pgp-why-from-future = 签名的日期在未来
pgp-why-signature-expired = 签名已过期
pgp-why-key-not-valid = 使用无效的密钥签名
pgp-why-not-for-you = 签名针对的是其他收件人，随后被转给了您
pgp-why-not-key-in-use = 签名所用的密钥不是{ $address }当前使用的密钥
pgp-part-pictures-loaded = { $label }。已从 Internet 加载图片
pgp-error-no-own-key = 您没有可用于签名或加密的{ $address }密钥。请在“工具 > 加密密钥”中创建一个，或关闭“签名”和“加密”。
pgp-error-missing-keys = { $count ->
    [1] 此收件人没有可用的加密密钥：{ $addresses }。
   *[other] 这些收件人没有可用的加密密钥：{ $addresses }。
}
pgp-error-encrypted-quote = 此邮件包含来自加密邮件的文本、图片或附件，只能加密发送。请打开“加密”，或删除所有这些内容。
pgp-error-protect = 无法为邮件签名或加密：{ $reason }
pgp-found-keys = 已找到以下地址的密钥：{ $addresses }。
pgp-found-none = 未找到{ $addresses }的密钥。请让对方将其公钥发送给您。
pgp-found-no-key = 未找到密钥。
pgp-find-unavailable = 现在无法查找密钥：{ $error }
pgp-publish-pending = keys.openpgp.org 已向以下地址发送确认链接：{ $addresses }。请确认每个地址，以便其他人可以通过该地址找到您的密钥。
pgp-publish-done = 您的密钥已在 keys.openpgp.org 上针对{ $addresses }发布。
pgp-publish-failed = 无法发布密钥：{ $error }
pgp-keyserver-off = 已在{ $settings }中关闭在 keys.openpgp.org 上查找密钥。
# the compose window with Sign and Encrypt: the line under the fields, each recipient's key, the questions
pgp-compose-encrypted = { $count ->
    [1] 发送时将为您和{ $addresses }加密并签名。
   *[other] 发送时将为您和{ $count }位收件人加密并签名。
}
pgp-compose-encrypt-ready = 发送时将加密并签名。请添加您拥有其密钥的收件人。
pgp-compose-missing = { $count ->
    [1] { $addresses }没有可用的密钥，因此暂时无法加密邮件。
   *[other] { $count }位收件人没有可用的密钥，因此暂时无法加密邮件：{ $addresses }。
}
pgp-compose-looking = 正在查找{ $addresses }的密钥...
pgp-compose-signed = 发送时将签名，收件人可以检查签名后的内容是否被更改。还需另行确认密钥确实属于您。
pgp-compose-reply-clear = 未加密，但所答复或转发的邮件是加密的。
pgp-compose-encrypted-files = 已附加加密邮件中的文件，因此此邮件只能加密发送。请打开“加密”，或删除这些文件。
pgp-compose-sign-tip = 发送时签名，让收件人可以检查内容是否被更改。还需另行确认密钥确实属于您
pgp-compose-sign-tip-encrypted = 加密邮件始终会签名
pgp-compose-encrypt-tip = 加密邮件，使只有您和收件人可以阅读
pgp-compose-make-key = 您还没有{ $address }的密钥。要立即创建一个吗？有了密钥，您的邮件就可以签名和加密。
pgp-compose-key-unusable = 您的{ $address }密钥无法使用（{ $state }）。请打开“加密密钥”导入其备份，或创建新密钥。
pgp-compose-encrypt-off-quote = 此邮件包含来自加密邮件的文本、图片或附件。如果不加密，必须删除所有这些内容后才能发送。仍要关闭加密吗？
pgp-compose-encrypt-off-reply = 此邮件答复或转发的是一封加密邮件。如果不加密，传输途中经手您邮件的任何人都能读取它。要关闭加密吗？
pgp-recipient-verified = 已验证密钥所有者
pgp-recipient-found = 未验证密钥所有者
pgp-recipient-own = 您自己的密钥
pgp-recipient-looking = 正在查找密钥...
pgp-recipient-missing = 无密钥
pgp-recipient-not-found = 无密钥：{ $date }查找时未找到
pgp-recipient-unusable = 密钥无法使用：{ $state }
pgp-recipients-intro = 邮件将使用每位收件人的密钥以及您的密钥加密。
pgp-recipients-intro-missing = { $count ->
    [1] 有一位收件人没有可用的加密密钥。请查找密钥或删除该收件人。只有删除所有来自加密邮件的内容后，才能不加密发送。
   *[other] 有{ $count }位收件人没有可用的加密密钥。请查找他们的密钥或删除这些收件人。只有删除所有来自加密邮件的内容后，才能不加密发送。
}
pgp-details-part = 第{ $number }部分：{ $label }
attachment-from-part = 来自第{ $number }部分：{ $label }
pgp-details-signed = 于{ $when }使用密钥{ $key }签名
pgp-details-unknown-key = 使用密钥{ $key }签名，但您没有此密钥
pgp-details-opened = 已使用您的密钥{ $key }解密
pgp-details-for = 已使用以下密钥加密：{ $keys }
pgp-details-plain = 未签名，也未加密
pgp-bar-parts = 此邮件有{ $count }个部分：{ $list }。每个部分都会说明其保护方式。
pgp-bar-count-verified = { $count }个已验证
pgp-bar-count-encrypted-signed = { $count }个已加密并签名
pgp-bar-count-encrypted = { $count }个已加密
pgp-bar-count-signed = { $count }个已签名
pgp-bar-count-warning = { $count }个需要注意
pgp-bar-count-neutral = { $count }个没有经过确认的签名
# the setup file: settings, accounts, contacts and keys carried to another computer
setup-part-settings = 设置
setup-part-preferences = 窗口偏好设置
setup-part-accounts = 帐户
setup-part-sign-in-apps = 登录应用
setup-part-contacts = 联系人和组
setup-part-keys = 加密密钥
setup-part-rules = 邮件规则
setup-part-trusted-senders = 受信任的发件人
setup-holds-settings = { $count }项设置
setup-holds-preferences = { $count }项偏好设置
setup-holds-accounts = { $count }个帐户
setup-holds-sign-in-apps = { $count }个登录应用
setup-holds-built-in = 已打开哪些内置登录应用
setup-holds-contacts = { $count }个联系人
setup-holds-groups = { $count }个组
setup-holds-own-keys = { $count }个您自己的密钥
setup-holds-contact-keys = { $count }个联系人的密钥
setup-holds-rules = { $count }条规则
setup-holds-trusted-senders = { $count }个受信任的发件人
setup-sign-in-password = 密码
setup-account-secret-password = 文件中包含其密码。
setup-account-secret-token = 文件中包含其已保存的登录凭据。
setup-account-asks-password = 导入后会要求输入其密码。
setup-account-signs-in-again = 导入后您需要重新登录此帐户。
setup-account-here = 此帐户已在这里设置，因此将跳过。
setup-account-no-app = 它使用{ $app }登录，但这里未设置该应用。请同时导入登录应用。
setup-invalid-address = “{ $address }”不是电子邮件地址。
setup-invalid-server = { $server }设置中的服务器名称、端口或安全选项无效。
setup-invalid-user = 没有用户名。
setup-invalid-sign-in = 不支持其登录方式或配置。
setup-error-empty = 文件为空。
setup-error-too-large = 设置文件超出了大小上限。
setup-error-not-setup = 此文件不是 Inbox Classic 设置文件。
setup-error-damaged = 设置文件已损坏，无法读取。
setup-error-newer = 此设置文件由较新版本的 Inbox Classic（{ $version }）保存。请更新 Inbox Classic，然后重新导入。
setup-error-needs-passphrase = 此设置文件受密码短语保护。请键入保存时使用的密码短语。
setup-error-wrong-passphrase = 这不是保存此设置文件时使用的密码短语。
setup-error-changed = 设置文件未通过完整性检查。它可能已被篡改或损坏，无法导入。
sync-wrong-passphrase = 同步密码短语不正确。请键入您在第一台计算机上设置同步时选择的密码短语。
sync-place = { $place }，名称为“{ $name }”
sync-news-removed = { $count ->
   *[other] 由于帐户{ $accounts }已在另一台计算机上删除，同步已将其删除。
}
sync-news-lost = { $count ->
    [1] 另一台计算机上同时进行的一项更改已被这里的更改替换。同步历史记录保存了它。
   *[other] 其他计算机上同时进行的{ $count }项更改已被这里的更改替换。同步历史记录保存了它们。
}
sync-status-busy = 正在同步…
sync-status-never = 尚未同步。
sync-status-last = 上次同步时间：{ $when }。
sync-status-today = 上次同步时间：今天{ $time }。
sync-when-today = 今天{ $time }
sync-status-problem = 无法同步：{ $problem }
sync-removed-here = 这台计算机已在另一台计算机上被移出同步。请关闭同步，然后重新设置以加入。
sync-item-account = 帐户{ $name }
sync-item-contact = 联系人{ $name }
sync-item-group = 组{ $name }
sync-item-key = 密钥{ $name }
sync-item-rule = 规则{ $name }
sync-item-trusted = 受信任的发件人{ $name }
sync-item-sign-in-app = 登录应用{ $name }
sync-item-settings = 设置
sync-another-computer = 另一台计算机
sync-no-key = 这台计算机上缺少用于同步的加密密钥。请关闭同步，然后使用同步密码短语重新设置。
setup-error-read = 无法读取设置文件：{ $error }
setup-error-write = 无法保存设置：{ $error }
setup-error-no-parts = 请至少选择一项。
setup-left-out = { $part }中有{ $count }个条目无法使用，已被省略。
setup-imported-settings = 设置已被替换。
setup-imported-preferences = 窗口偏好设置已被替换。
setup-added-accounts = 已添加{ $count }个帐户。
setup-skipped-here = { $address }已在这里设置，因此已跳过。
setup-skipped-no-app = 已跳过{ $address }：它使用{ $app }登录，但这里未设置该应用。
setup-skipped-invalid = 已跳过{ $address }：{ $reason }
setup-asks-password = { $address }连接时会要求输入其密码。
setup-signs-in-again = { $address }连接时会要求您重新登录。
setup-added-sign-in-apps = 已添加{ $count }个登录应用。
setup-skipped-sign-in-apps = { $count }个登录应用已在这里设置。
setup-added-contacts = 已向通讯簿添加{ $count }个联系人。
setup-skipped-contacts = { $count }个联系人已在通讯簿中。
setup-added-groups = 已添加或补全{ $count }个组。
setup-added-own-keys = 已添加{ $count }个您自己的密钥。
setup-added-contact-keys = 已添加{ $count }个联系人的密钥。
setup-added-rules = 已添加{ $count }条邮件规则。
setup-skipped-rules = { $count }条邮件规则已存在。
setup-skipped-rules-account = { $count }条邮件规则所属的帐户不在这里，因此已跳过。
setup-rules-waiting = { $count }条邮件规则正在等待帐户同步期间找到其目标文件夹。
setup-added-trusted-senders = 已添加{ $count }个受信任的发件人。
setup-nothing = 未导入任何内容。
setup-account-servers = { $imap }和{ $smtp }（{ $signin }）
setup-file-name = Inbox Classic 设置和帐户
setup-skipped-unreachable = 已跳过{ $name }：无法连接或检查其登录服务。请先在“登录应用”中检查所需的应用，然后重试。
attachment-runs-programs = “{ $name }”可以运行程序，因此 Inbox Classic 不会打开它。请先保存，如果您信任其来源，再自行打开。
attachment-decrypted-note = 此附件来自加密邮件。为了在其他应用中打开它，Inbox Classic 会在您用户帐户的临时文件夹中保存一份未加密的副本。启动时，它会尝试删除超过一天的副本。
# a bar over the list when the server did not do what the user asked of messages, so they are as they were again
undone-move = { $count ->
   *[other] 服务器未将{ $messages }移动到{ $folder }，因此邮件已回到{ $from }：{ $reason }
}
undone-delete = { $count ->
   *[other] 服务器未删除{ $messages }，因此邮件已回到{ $from }：{ $reason }
}
undone-archive = { $count ->
   *[other] 服务器未存档{ $messages }，因此邮件已回到{ $from }：{ $reason }
}
undone-read = { $count ->
   *[other] 服务器未将{ $messages }标记为已读，因此邮件又变为未读：{ $reason }
}
undone-unread = { $count ->
   *[other] 服务器未将{ $messages }标记为未读，因此邮件又变为已读：{ $reason }
}
undone-flags = { $count ->
   *[other] 服务器未更改{ $messages }的标志，因此邮件保持原样：{ $reason }
}

## 附件预览：邮件中显示的图片和 PDF 文件

# the reading option that turns PDF previews on and off (the apps show it)
preview-pdf-option = 在邮件中显示 PDF 文件
# the tile of a PDF file while PDF previews are off
preview-pdf-off = 邮件中不显示 PDF 文件。
# the note where previews are, after the app ended while it was drawing a file of a message: { $option } is the option's name
preview-pdf-off-crashed = Inbox Classic 在显示邮件中的某个文件时关闭，因此邮件中将不再显示 PDF 文件。图片仍会显示。若要再次显示 PDF 文件，请在{ $settings }中打开“{ $option }”。
# under the pages of a PDF file shown in a message: its page count and size ("3 pages, 84 KB")
preview-pdf-details = { $count }页，{ $size }
# what a screen reader says of a page of a PDF file shown in a message
preview-page-alt = { $name }，第{ $page }页，共{ $count }页
# the link under the pages of a PDF file shown in a message, when it has more pages than are shown
preview-more-pages = { $count ->
    [1] 打开以查看该页
   *[other] 打开以查看全部{ $count }页
}
# after the files shown in a message, when it has more pictures and PDF files than are shown; the list is the
# strip of files over the message
preview-more-files = 上方列表中还有{ $count }个文件
# the tile of a picture or PDF file of a message still downloading (the ellipsis as in reader-downloading)
preview-tile-downloading = 正在下载…
# the tile of a picture or PDF file whose size was not read in time when the message was shown: its preview
# comes in its place in a moment (the ellipsis as in reader-downloading)
preview-tile-preparing = 正在准备…
# the tile of a picture in a format not shown yet: { $format } is its name (HEIC, AVIF, JPEG XL)
preview-tile-format = 尚不支持显示{ $format }图片
# the tile of a PDF file that wants a password to open
preview-tile-password = 受密码保护：请打开它以输入密码
# the tile of a picture or PDF file over the size or pixel limit
preview-tile-too-large = 太大，无法显示
# the tile of a file that is broken, or not what its name says
preview-tile-unreadable = 无法显示
# the tile of a file that took too long to draw
preview-tile-timed-out = 准备预览的时间过长
# the tile of a file that closed the app once while it was drawn: never drawn again
preview-tile-crashed = 预览不可用：之前的尝试被中断
# the tile of a file while previews are paused after a file took too long, until the app starts again
preview-tile-off = 在 Inbox Classic 重新启动之前不显示
# in a printout, for a file shown in the message that is not printed (a PDF file, a tile): { $details } is its size,
# or a PDF file's pages and size
preview-not-printed = { $name }（{ $details }）未打印。请打开它进行打印。

pgp-error-attached-private = 此附件包含私钥。只能从邮件直接导入公钥。要恢复您自己的私钥，请保存附件，然后在“加密密钥”中导入该文件。
pgp-part-find-key = 查找密钥
reaction-notification-title = { $name }回应了{ $emoji }
reaction-notification-text = { $count ->
    [1] 邮件：{ $subject }
   *[other] 邮件：{ $subject }，共有{ $count }个新回应
}

reader-failed-signed-out = 邮件服务器未接受此帐户的登录。邮件列表上方的提示栏会说明如何处理。

account-state-tooltip-refused = 未登录：登录未被接受

account-state-tooltip-admin = 未登录：管理员必须先批准 Inbox Classic

account-state-tooltip-imap-off = 未登录：此邮箱已关闭 IMAP

account-state-tooltip-other-address = 未登录：浏览器登录了另一个地址

account-state-tooltip-cannot-connect = 无法连接到邮件服务器

account-state-mail-server = 邮件服务器

account-state-bar-refused-browser = 帐户{ $account }未登录：{ $provider }未接受登录。此帐户的邮件可能不是最新状态。

account-state-bar-refused-password = 帐户{ $account }未登录：邮件服务器未接受密码。此帐户的邮件可能不是最新状态。

account-state-bar-admin = 帐户{ $account }未登录：域{ $domain }的管理员必须先批准 Inbox Classic，才能登录。此帐户的邮件可能不是最新状态。

account-state-bar-imap-off = 帐户{ $account }未登录：{ $provider }表示此邮箱已关闭 IMAP。请在邮箱设置中将其打开，然后重新发送和接收邮件。

account-state-bar-other-address = 帐户{ $account }未登录：浏览器登录的是{ $email }，而不是{ $expected }。请重试并选择{ $expected }。

account-state-bar-cannot-connect = 帐户{ $account }无法连接到其邮件服务器。此帐户的邮件可能不是最新状态。

account-state-button-sign-in = 重新登录

account-state-button-password = 输入密码

account-state-button-admin-link = 复制给管理员的链接

account-state-button-help = 帮助

account-state-button-try-again = 重试

account-state-admin-link-copied = 链接已复制。请将其发送给您组织的管理员。

account-state-app-password-hint = 如果您的提供商要求邮件程序使用应用密码，请在此输入应用密码，而不是平时的密码。

account-status-sign-in = 帐户{ $account }需要登录

account-status-cannot-connect = 帐户{ $account }无法连接

account-status-failed = { $account }：{ $reason }

account-status-sign-in-many = { $count }个帐户需要登录

account-status-cannot-connect-many = { $count }个帐户无法连接

account-notify-title-sign-in = 帐户{ $account }未登录

account-notify-text-refused-browser = { $provider }未接受登录。请重新登录以接收新邮件。

account-notify-text-refused-password = 邮件服务器未接受密码。请重新输入以接收新邮件。

account-notify-text-admin = 域{ $domain }的管理员必须先批准 Inbox Classic。

account-notify-text-imap-off = { $provider }表示此邮箱已关闭 IMAP。

account-notify-text-other-address = 浏览器登录的是{ $email }。请重试并选择{ $expected }。

account-notify-title-cannot-connect = 帐户{ $account }无法连接

account-notify-text-cannot-connect = Inbox Classic 无法连接到邮件服务器，将继续尝试。

account-state-compose-sign-in = 此帐户未登录，邮件将在发件箱中等待。

account-state-compose-cannot-connect = 此帐户存在连接问题。如果发送失败，邮件会留在发件箱中。

account-state-outbox-sign-in = 等待中：帐户{ $account }未登录

account-state-outbox-cannot-connect = 等待中：帐户{ $account }无法连接
