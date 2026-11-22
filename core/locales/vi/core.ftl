# Bản nháp tiếng Việt, đang chờ người bản ngữ duyệt.
# Những gì phần lõi nói, giống nhau trên mọi nền tảng. Mã chương trình điền các chỗ giữ chỗ trong { $braces }; hãy giữ
# chúng ở vị trí ngôn ngữ cần. Tiếng Việt không có số nhiều theo CLDR: chỉ có *[other]; [0] và [1] chọn theo đúng số.

## Số đếm và kích cỡ

# review: new
messages = { $count } thư
# the separator of decimals in sizes: 2.4 MB
# review: new
decimal-separator = ,
# review: new
list-separator = { ", " }
# review: new
size-bytes = { $count } byte
# review: new
size-kb = { $size } KB
# review: new
size-mb = { $size } MB
# review: new
size-gb = { $size } GB
# review: new
send-delay-off = Tắt
# review: new
send-delay-seconds = { $count } giây
# the status bar: "12 messages, 3 unread"
# review: new
list-counts = { $messages }, { $unread } chưa đọc
# review: new
list-counts-selected = { $messages }, { $unread } chưa đọc, { $selected } đã chọn
# the status bar while searching: "12 found, 3 unread"
# review: new
list-counts-found = Tìm thấy { $found }, { $unread } chưa đọc
# review: new
list-counts-found-selected = Tìm thấy { $found }, { $unread } chưa đọc, { $selected } đã chọn
# review: new
list-counts-none = Không tìm thấy thư nào

## Các thư mục đặc biệt, theo tên trong Outlook Express

# review: new
folder-inbox = Hộp thư đến
# review: new
folder-sent = Mục đã gửi
# review: new
folder-deleted = Mục đã xóa
# review: new
folder-drafts = Thư nháp
# review: new
folder-junk = Email rác
# review: new
folder-archive = Lưu trữ

## Ngăn đọc

# review: new
reader-no-message = Chưa chọn thư nào.
# review: new
reader-downloading = Đang tải thư xuống…
# review: new
reader-downloading-detail = Thư sẽ hiện ở đây khi tải xuống xong.
# review: new
reader-downloading-size = Thư có kích cỡ { $size }. Thư sẽ hiện ở đây khi được tải xuống.
# review: new
reader-failed = Không thể tải thư xuống
# review: new
reader-failed-network = Không thể kết nối với máy chủ thư hoặc kết nối bị gián đoạn ({ $reason }).
# review: new
reader-failed-sign-in = Máy chủ thư không chấp nhận đăng nhập ({ $reason }). Hãy kiểm tra mật khẩu hoặc đăng nhập lại trong thiết đặt của tài khoản.
# review: new
reader-failed-security = Không thể tạo kết nối bảo mật với máy chủ thư ({ $reason }).
# review: new
reader-failed-other = Máy chủ thư trả lời: { $reason }.
# review: new
reader-retry-note = Ứng dụng sẽ thử lại khi tài khoản kết nối lại.
# review: new
reader-unreadable = Không thể hiển thị thư này: { $error }
# review: new
message-source-title = Nguồn thư: { $subject }
# review: new
message-source-untitled = Nguồn thư

## In thư, và phần đầu của thư được trích dẫn trong thư trả lời hoặc chuyển tiếp

# review: new
header-from = Từ
# review: new
header-date = Ngày
# review: new
header-to = Đến
# review: new
header-cc = Cc
# review: new
header-sent = Đã gửi
# review: new
header-subject = Chủ đề
# review: new
header-security = Bảo mật
# review: new
header-part = Phần { $number }
# review: new
quote-original = ----- Thư gốc -----
# review: new
fold-show-earlier = Hiện các thư trước đó

## Thư bị trả lại: thẻ ở đầu thông báo cho biết một thư chưa được gửi đến nơi

# review: new
bounce-failed = Thư của bạn chưa được gửi đến nơi
# review: new
bounce-delayed = Thư của bạn vẫn chưa được gửi đến nơi
# review: new
bounce-delayed-note = Máy chủ thư của bạn vẫn đang thử gửi thư. Bạn không cần gửi lại.
# the link to the message the notice is about, in Sent Items or another folder
# review: new
bounce-show-message = Hiện thư bị trả lại
# the link of a delay's card to the message that is still on its way
# review: new
bounce-show-delayed = Hiện thư bị chậm
# review: new
bounce-what-to-do = Bạn có thể làm gì:
# what to do about a recipient the message is still on its way to: in the card of a delay, and in the card of a failure
# review: new
bounce-delayed-do = Chưa cần làm gì. Nếu thư vẫn không gửi được, bạn sẽ nhận thêm một thông báo.
# review: new
bounce-delayed-row-do = Chưa cần làm gì. Máy chủ thư của bạn vẫn đang thử gửi thư, và bạn sẽ nhận thêm một thông báo nếu không gửi được.
# folds the receiving server's own words
# review: new
bounce-details = Chi tiết
# a recipient the notice does not name
# review: new
bounce-someone = Một người nhận
# in Details: the server that refused the message, the status code it gave, and the server that wrote the notice
# review: new
bounce-server = Máy chủ: { $server }
# review: new
bounce-status = Trạng thái: { $status }
# review: new
bounce-reported-by = Báo cáo bởi: { $server }
# review: new
bounce-retry-minutes = Máy chủ nhận yêu cầu chờ { $count } phút trước lần thử tiếp theo.
# review: new
bounce-retry-hours = Máy chủ nhận yêu cầu chờ { $count } giờ trước lần thử tiếp theo.
# the names of the blocklists, "Spamhaus ZEN, Barracuda"
# review: new
bounce-blocklist = Danh sách chặn: { $lists }
# review: new
bounce-user-unknown = Địa chỉ không tồn tại
# review: new
bounce-user-unknown-why = Máy chủ nhận không có hộp thư nào với địa chỉ này. Có thể địa chỉ bị gõ sai, hoặc người đó không còn dùng địa chỉ này.
# review: new
bounce-user-unknown-do = Hãy kiểm tra chính tả của địa chỉ, hoặc hỏi người đó địa chỉ họ đang dùng.
# review: new
bounce-invalid-address = Địa chỉ không hợp lệ
# review: new
bounce-invalid-address-why = Địa chỉ không được viết theo dạng có thể gửi thư đến.
# review: new
bounce-invalid-address-do = Hãy tìm lỗi gõ, chẳng hạn một dấu cách, một chữ cái bị thiếu hoặc không có gì sau dấu @.
# review: new
bounce-mailbox-disabled = Hộp thư đã đóng
# review: new
bounce-mailbox-disabled-why = Địa chỉ tồn tại nhưng hộp thư đã bị tắt hoặc không còn được sử dụng.
# review: new
bounce-mailbox-disabled-do = Hãy liên lạc với người đó bằng cách khác và hỏi địa chỉ họ đang dùng.
# review: new
bounce-mailbox-full = Hộp thư đã đầy
# review: new
bounce-mailbox-full-why = Hộp thư của người nhận không còn chỗ cho thư mới.
# review: new
bounce-mailbox-full-do = Hãy gửi lại sau vài ngày, hoặc báo cho người đó bằng cách khác.
# review: new
bounce-spam-blocked = Bị từ chối vì là thư rác
# review: new
bounce-spam-blocked-why = Máy chủ nhận cho rằng thư là thư rác.
# review: new
bounce-spam-blocked-do = Hãy gửi lại mà không có những gì trông giống thư rác, chẳng hạn nhiều liên kết, liên kết rút gọn hoặc tệp đính kèm lớn. Nếu vẫn tiếp tục xảy ra, hãy hỏi nhà cung cấp thư của bạn.
# review: new
bounce-virus-detected = Bị từ chối vì có vi-rút
# review: new
bounce-virus-detected-why = Máy chủ nhận báo có vi-rút hoặc nội dung độc hại khác trong thư hoặc tệp đính kèm.
# review: new
bounce-virus-detected-do = Hãy kiểm tra tệp đính kèm bằng phần mềm diệt vi-rút. Một số máy chủ từ chối mọi chương trình hoặc tệp nén, vì vậy hãy chia sẻ những tệp như vậy dưới dạng liên kết.
# review: new
bounce-ip-blocklisted = Máy chủ thư của bạn nằm trong danh sách chặn
# review: new
bounce-ip-blocklisted-why = Máy chủ nhận từ chối thư từ máy chủ đã gửi thư của bạn, vì địa chỉ của máy chủ đó nằm trong danh sách chặn.
# review: new
bounce-ip-blocklisted-do = Vấn đề không nằm ở thư. Hãy chuyển tiếp thông báo này cho nhà cung cấp thư của bạn và đề nghị họ đưa máy chủ ra khỏi danh sách.
# review: new
bounce-domain-blocklisted = Một tên miền nằm trong danh sách chặn
# review: new
bounce-domain-blocklisted-why = Máy chủ nhận từ chối thư vì tên miền trong địa chỉ của bạn, hoặc một tên miền trong các liên kết của thư, nằm trong danh sách chặn.
# review: new
bounce-domain-blocklisted-do = Nếu thư có liên kết, hãy thử gửi mà không có chúng. Nếu không, hãy chuyển tiếp thông báo này cho người quản lý thư của tên miền của bạn.
# review: new
bounce-policy-blocked = Bị quy định của máy chủ nhận từ chối
# review: new
bounce-policy-blocked-why = Quy định của máy chủ nhận không cho thư này đi qua, chẳng hạn vì kích cỡ, tệp đính kèm hoặc người gửi.
# review: new
bounce-policy-blocked-do = Lời của chính máy chủ trong phần Chi tiết thường cho biết lý do. Hãy hỏi người nhận xem họ có thể nhận loại thư như vậy không.
# review: new
bounce-geo-blocked = Bị từ chối vì nơi gửi
# review: new
bounce-geo-blocked-why = Máy chủ nhận không nhận thư từ quốc gia hoặc mạng nơi đặt máy chủ thư của bạn.
# review: new
bounce-geo-blocked-do = Hãy liên lạc với người đó bằng cách khác, hoặc hỏi nhà cung cấp thư của bạn.
# review: new
bounce-relay-denied = Máy chủ không chuyển tiếp thư
# review: new
bounce-relay-denied-why = Một máy chủ đã từ chối chuyển tiếp thư, thường vì thư được gửi mà không đăng nhập hoặc qua một máy chủ không phụ trách người nhận này.
# review: new
bounce-relay-denied-do = Hãy kiểm tra máy chủ thư đi và thông tin đăng nhập trong thiết đặt của tài khoản.
# review: new
bounce-auth-failure = Không thể xác minh địa chỉ người gửi của bạn
# review: new
bounce-auth-failure-why = Máy chủ nhận không thể xác nhận thư thật sự đến từ tên miền của bạn (SPF, DKIM hoặc DMARC).
# review: new
bounce-auth-failure-do = Hãy chuyển tiếp thông báo này cho người quản lý thư của tên miền của bạn: thiết đặt của tên miền cần được sửa. Trong lúc chờ, gửi qua máy chủ của chính nhà cung cấp có thể giúp ích.
# review: new
bounce-rate-limited = Quá nhiều thư cùng lúc
# review: new
bounce-rate-limited-why = Hiện tại máy chủ nhận chỉ nhận ít thư hơn từ máy chủ thư của bạn.
# review: new
bounce-rate-limited-do = Hãy chờ một lúc rồi gửi lại. Khi viết cho nhiều người, hãy gửi cho ít người hơn mỗi lần.
# review: new
bounce-greylisting = Tạm thời bị giữ lại
# review: new
bounce-greylisting-why = Máy chủ nhận yêu cầu người gửi lạ thử lại sau một lúc, một cách kiểm tra thư rác phổ biến.
# review: new
bounce-greylisting-do = Với sự chậm trễ tạm thời, máy chủ gửi thường sẽ tự thử lại. Nếu thông báo này cho biết thư đã thất bại hẳn, hãy thử gửi lại sau.
# review: new
bounce-server-error = Máy chủ nhận gặp sự cố
# review: new
bounce-server-error-why = Không thể kết nối với máy chủ nhận, hoặc máy chủ không thể nhận thư do sự cố của chính nó.
# review: new
bounce-server-error-do = Hãy gửi lại sau. Nếu vẫn thất bại, hãy kiểm tra phần địa chỉ sau dấu @ xem có lỗi gõ không.
# review: new
bounce-unknown = Chưa gửi được
# review: new
bounce-unknown-why = Thông báo không nói rõ lý do.
# review: new
bounce-unknown-do = Lời của chính máy chủ trong phần Chi tiết có thể cho biết thêm. Nếu không giúp được, hãy chuyển tiếp thông báo này cho nhà cung cấp thư của bạn.

## Khi chọn nhiều thư

# review: new
selection-title = Đã chọn { $count } thư
# review: new
selection-unread = { $count } chưa đọc
# review: new
selection-flagged = { $count } đã gắn cờ
# review: new
delete-for-good-one = Thư này sẽ bị xóa vĩnh viễn. Xóa thư?
# review: new
delete-for-good-all = { $count } thư này sẽ bị xóa vĩnh viễn. Xóa các thư?
# review: new
delete-for-good-some = { $count } trong số { $total } thư sẽ bị xóa vĩnh viễn. Xóa các thư?
# review: new
done-read = { $count ->
   *[other] Đã đánh dấu { $messages } là đã đọc
}
# review: new
done-unread = { $count ->
   *[other] Đã đánh dấu { $messages } là chưa đọc
}
# review: new
done-flagged = { $count ->
   *[other] Đã gắn cờ { $messages }
}
# review: new
done-unflagged = Đã bỏ cờ { $messages }
# review: new
done-deleted-for-good = { $count ->
   *[other] Đã xóa vĩnh viễn { $messages }
}
# review: new
done-archived = { $count ->
   *[other] Đã lưu trữ { $messages }
}
# review: new
done-moved = { $count ->
   *[other] Đã di chuyển { $messages } đến { $folder }
}
# review: new
done-copied = { $count ->
   *[other] Đã sao chép { $messages } vào { $folder }
}
# review: new
done-moving = { $count ->
   *[other] Đang di chuyển { $messages } đến { $folder }...
}
# review: new
done-copying = { $count ->
   *[other] Đang sao chép { $messages } vào { $folder }...
}
# review: new
done-moved-back = { $count ->
   *[other] Đã chuyển { $messages } trở lại { $folder }
}
# the status bar after Watch Conversation and Ignore Conversation, and after either again on a marked one
# review: new
done-watched = { $count ->
    [1] Đang theo dõi cuộc hội thoại
   *[other] Đang theo dõi { $count } cuộc hội thoại
}
# review: new
done-unwatched = { $count ->
    [1] Đã ngừng theo dõi cuộc hội thoại
   *[other] Đã ngừng theo dõi { $count } cuộc hội thoại
}
# review: new
done-ignored = { $count ->
    [1] Đang bỏ qua cuộc hội thoại
   *[other] Đang bỏ qua { $count } cuộc hội thoại
}
# review: new
done-unignored = { $count ->
    [1] Đã ngừng bỏ qua cuộc hội thoại
   *[other] Đã ngừng bỏ qua { $count } cuộc hội thoại
}
# review: new
their-folders = thư mục ban đầu của chúng
# review: new
undo-move = Hoàn tác di chuyển
# review: new
undo-delete = Hoàn tác xóa
# review: new
undo-archive = Hoàn tác lưu trữ
# review: new
undo-junk = Hoàn tác đánh dấu là thư rác
# review: new
undo-not-junk = Hoàn tác đánh dấu là không phải thư rác
# review: new
undo-send = Hoàn tác gửi
# review: new
nothing-to-undo = Không có gì để hoàn tác.
# review: new
messages-gone = Các thư không còn ở đó nữa.
# A non-selectable IMAP folder cannot contain messages; this does not mean it is empty.
# review: new
folder-holds-no-messages = Thư mục này không thể chứa thư.
# review: new
not-archived-here = Không thể lưu trữ thư trong thư mục này.
# review: new
not-emptied-here = Chỉ có thể làm trống Mục đã xóa và Email rác.
# review: new
next-unread-question = Không còn thư chưa đọc nào trong { $folder }.

    Đi đến { $next }, thư mục tiếp theo có thư chưa đọc?
# review: new
no-unread-left = Không còn thư chưa đọc nào.
# review: new
empty-question = { $count ->
    [1] Làm trống { $folder }?

        Thư trong thư mục sẽ bị xóa vĩnh viễn. Không thể khôi phục thư.
   *[other] Làm trống { $folder }?

        { $messages } trong thư mục sẽ bị xóa vĩnh viễn. Không thể khôi phục các thư này.
}
# review: new
no-junk-folder = Tài khoản này không có thư mục Email rác để chuyển thư vào.
# review: new
no-inbox-folder = Tài khoản này không có thư mục Hộp thư đến để chuyển thư vào.
# the status bar after a flag in a colour: "Flagged 2 messages blue"
# review: new
done-flagged-color = Đã gắn cờ { $color ->
    [red] đỏ
    [orange] cam
    [yellow] vàng
    [green] xanh lá
    [blue] xanh lam
    [purple] tím
   *[gray] xám
} cho { $messages }
# the Flag menu: the colours of Apple Mail's flags
# review: new
flag-color = { $color ->
    [red] Đỏ
    [orange] Cam
    [yellow] Vàng
    [green] Xanh lá
    [blue] Xanh lam
    [purple] Tím
   *[gray] Xám
}

## Cửa sổ Di chuyển và Sao chép

# review: new
move-window-title-move = { $count ->
    [1] Di chuyển thư
   *[other] Di chuyển { $count } thư
}
# review: new
move-window-title-copy = { $count ->
    [1] Sao chép thư
   *[other] Sao chép { $count } thư
}
# review: new
move-window-prompt-move = { $count ->
    [1] Di chuyển thư đã chọn đến:
   *[other] Di chuyển { $count } thư đã chọn đến:
}
# review: new
move-window-prompt-copy = { $count ->
    [1] Sao chép thư đã chọn vào:
   *[other] Sao chép { $count } thư đã chọn vào:
}
# the folders used last, over the folder tree
# review: new
targets-recent = Gần đây
# the folder the messages are in, which can not be chosen
# review: new
target-current = { $folder } (hiện tại)
# a folder used last, with its account when there are several: "Archive (Work)"
# review: new
target-recent = { $folder } ({ $account })

## Di chuyển và sao chép sang tài khoản khác

# review: new
transfer-moving = Đang di chuyển { $done } trong số { $messages } đến { $folder }...
# review: new
transfer-copying = Đang sao chép { $done } trong số { $messages } vào { $folder }...
# review: new
transfer-another-account = tài khoản khác
# review: new
transfer-folder-gone = thư mục đích không còn nữa
# review: new
transfer-not-on-server = thư không còn trên máy chủ
# review: new
transfer-not-moved = { $count ->
   *[other] Không thể di chuyển { $messages } sang tài khoản khác: { $reason }
}
# review: new
transfer-not-copied = { $count ->
   *[other] Không thể sao chép { $messages } sang tài khoản khác: { $reason }
}
# review: new
transfer-none-moved = Không di chuyển được thư nào
# review: new
transfer-none-copied = Không sao chép được thư nào

## Thư dưới dạng tệp

# review: new
export-not-in-time = không thể tải thư xuống kịp thời
# review: new
export-not-saved = Không thể lưu { $failed } trong số { $messages } ({ $problems })
# review: new
export-not-attached = không thể đính kèm các thư: { $error }
# the status bar after Save As with several: "Saved 3 messages to Desktop"
# review: new
saved-to = { $count ->
   *[other] Đã lưu { $messages } vào { $folder }
}
# review: new
download-progress = Đang tải xuống { $done } trong số { $total }
# review: new
download-done = Đã tải xuống { $size }
# review: new
downloading-messages = { $count ->
   *[other] Đang tải xuống { $messages }...
}
# the status bar after files are dropped on a folder: "Put 3 messages in Archive"
# review: new
import-put = { $count ->
   *[other] Đã xếp { $messages } vào hàng đợi để nhập vào { $folder }
}
# review: new
import-not-put = Các mục sau chưa được đưa vào thư mục:

    { $problems }

## Các vấn đề mà cửa sổ hiển thị

# review: new
error-store = kho cục bộ: { $error }
# review: new
error-not-found = không tìm thấy
# review: new
error-closed = đang tắt
# review: new
error-other-account = trình duyệt đã đăng nhập vào { $email }, không phải tài khoản này
# a password or sign-in the mail server refused, with the server's words
# review: new
failure-authentication = máy chủ không chấp nhận đăng nhập ({ $reason })
# the mail server could not be reached or the connection broke, with the reason
# review: new
failure-network = kết nối với máy chủ thất bại ({ $reason })
# review: new
error-in-use = không thể gỡ khi vẫn còn tài khoản đăng nhập bằng nó: { $accounts }
# review: new
error-turned-off = ứng dụng đăng nhập này đã bị tắt cho tài khoản mới
# review: new
error-folder-name = tên thư mục phải dài từ 1 đến 200 ký tự và không được chứa ký tự điều khiển
# review: new
error-folder-separator = trên máy chủ này, tên thư mục không được chứa “{ $separator }”
# review: new
error-folder-special = không thể đổi tên hoặc xóa Hộp thư đến và các thư mục đặc biệt
# review: new
error-no-recipients = thư không có người nhận
# review: new
error-bad-address = “{ $address }” không phải là địa chỉ email
# review: new
error-not-own-address = { $address } không phải là một địa chỉ gửi của tài khoản này. Hãy thêm địa chỉ vào “Các địa chỉ khác bạn dùng để gửi” trong thuộc tính của tài khoản.
# review: new
rule-query-refused = Quy tắc không thể lọc theo thư mục hoặc ngày ({ $words }).
# review: new
rule-no-query = Hãy nhập tiêu chí tìm kiếm cho thư đến.
# review: new
rule-no-action = Hãy chọn ít nhất một hành động cho quy tắc.
# review: new
error-attachment = Không thể đọc { $path }: { $error }
# review: new
error-no-drafts = tài khoản không có thư mục Thư nháp để lưu thư
# review: new
error-draft-attachment = không thể giữ lại một tệp đính kèm của thư nháp: { $error }
# review: new
error-password-not-saved = không thể lưu mật khẩu cho lần khởi động sau: { $error }
# review: new
error-sign-in-not-saved = không thể lưu thông tin đăng nhập mới cho lần khởi động sau: { $error }
# review: new
error-import-unreadable = Không thể đọc { $path }: { $error }
# review: new
error-import-too-large = { $path } lớn hơn 50 MB
# review: new
error-import-not-mail = { $path } không phải là thư email
# review: new
error-list-answered = máy chủ danh sách gửi thư trả về trạng thái { $status }
# review: new
error-not-built = không thể tạo thư
# review: new
error-outbox-waits = { $count ->
    [1] thư vẫn còn trong Hộp thư đi; lần Gửi/Nhận tiếp theo sẽ thử gửi lại
   *[other] { $count } thư vẫn còn trong Hộp thư đi; lần Gửi/Nhận tiếp theo sẽ thử gửi lại
}
# review: new
error-draft-not-removed = không thể xóa bản nháp trước của thư khỏi Thư nháp: { $reason }
# review: new
error-sent-but = thư đã được gửi, nhưng { $problem }
# review: new
error-sent-still-in-outbox = thư vẫn còn trong Hộp thư đi: { $error }
# review: new
error-sent-no-copy = không thể lưu bản sao vào Mục đã gửi: { $reason }
# review: new
error-no-password = tài khoản này chưa có mật khẩu
# review: new
error-no-sign-in = tài khoản này chưa có thông tin đăng nhập
# review: new
error-provider-missing = ứng dụng đăng nhập không có trong bản dựng này (ID: { $provider }). Có thể nó đã bị gỡ
# review: new
error-provider-servers = máy chủ của tài khoản này không khớp với máy chủ của ứng dụng đăng nhập
# review: new
error-app-scopes = { $reason }. Máy chủ thư không nhận mã thông báo của ứng dụng đăng nhập: hãy kiểm tra xem phạm vi của ứng dụng có cấp quyền truy cập thư không
# review: new
error-in-folder = { $folder }: { $reason }

## Ứng dụng đăng nhập

# review: new
sign-in-off-google = Ứng dụng đăng nhập Google có sẵn được thiết lập cho người dùng thử nghiệm đã được phê duyệt và mặc định bị tắt cho tài khoản mới. Người dùng thử nghiệm có thể bật nó trong Ứng dụng đăng nhập (Tệp > Tài khoản). Bạn cũng có thể dùng ứng dụng đăng nhập Google của riêng mình, hoặc mật khẩu ứng dụng nếu tài khoản của bạn hỗ trợ.
# review: new
sign-in-off-other = Ứng dụng này đã bị tắt cho tài khoản mới. Bạn có thể bật nó trong Ứng dụng đăng nhập (Tệp > Tài khoản).
# review: new
sign-in-app-no-name = ứng dụng đăng nhập cần có tên
# review: new
sign-in-app-no-client = thiếu ID máy khách
# review: new
sign-in-app-no-scopes = ứng dụng đăng nhập cần các phạm vi cấp quyền truy cập thư
# review: new
sign-in-app-bad-host = địa chỉ máy chủ { $server } bị thiếu hoặc không phải là tên máy chủ hợp lệ
# review: new
sign-in-app-plain = máy chủ { $server } phải dùng SSL/TLS hoặc STARTTLS
# review: new
sign-in-app-not-checked = bên phát hành chưa được kiểm tra
# review: new
sign-in-app-issuer-changed = bên phát hành đã thay đổi: hãy nhập lại bí mật máy khách hoặc gỡ nó
# review: new
sign-in-register-google = Trong Google Cloud Console, hãy tạo một máy khách OAuth loại Desktop app, với phạm vi https://mail.google.com/ trên màn hình xin phép. Khi ứng dụng đang ở chế độ thử nghiệm, chỉ người dùng thử nghiệm của ứng dụng mới đăng nhập được.
# review: new
sign-in-register-microsoft = Trong Microsoft Entra, hãy đăng ký một ứng dụng với nền tảng Mobile and desktop applications, URI chuyển hướng http://localhost, cho phép public client flows và các quyền ủy quyền IMAP.AccessAsUser.All, SMTP.Send và offline_access. Nếu chỉ dành cho tổ chức của bạn, hãy dùng https://login.microsoftonline.com/<tenant ID>/v2.0 làm bên phát hành.
# review: new
sign-in-register-other = Hãy đăng ký một máy khách gốc (công khai) với URI chuyển hướng bên dưới; nhà cung cấp phải cho phép mọi cổng trên URI đó (RFC 8252). Thêm phạm vi mà nhà cung cấp dùng để cấp quyền truy cập thư.

## Lời mời lịch

# review: new
repeats = Lặp lại
# review: new
repeats-every = { $unit ->
    [day] { $interval ->
        [1] Hằng ngày
       *[other] Mỗi { $interval } ngày
    }
    [week] { $interval ->
        [1] Hằng tuần
       *[other] Mỗi { $interval } tuần
    }
    [month] { $interval ->
        [1] Hằng tháng
       *[other] Mỗi { $interval } tháng
    }
   *[year] { $interval ->
        [1] Hằng năm
       *[other] Mỗi { $interval } năm
    }
}
# "Every week on Monday, Wednesday"
# review: new
repeats-on = { $repeats } vào { $days }
# "Every week, 10 times"
# review: new
repeats-times = { $count ->
    [1] { $repeats }, một lần
   *[other] { $repeats }, { $count } lần
}
# review: new
day-monday = Thứ Hai
# review: new
day-tuesday = Thứ Ba
# review: new
day-wednesday = Thứ Tư
# review: new
day-thursday = Thứ Năm
# review: new
day-friday = Thứ Sáu
# review: new
day-saturday = Thứ Bảy
# review: new
day-sunday = Chủ Nhật

## Tác nhân AI

# review: new
agent-level-read = Đọc thư: thư mục, danh sách thư, cuộc hội thoại, tìm kiếm, thư và tệp của thư, quy tắc thư của bạn và những người bạn viết thư cho
# review: new
agent-level-organize = Sắp xếp thư: trạng thái đã đọc, cờ và màu cờ, thư rác, di chuyển, lưu trữ, tạo và đổi tên thư mục, theo dõi và bỏ qua cuộc hội thoại, xóa vào Mục đã xóa, và rời danh sách gửi thư sau khi bạn đồng ý
# review: new
agent-level-drafts = Viết thư nháp để bạn gửi
# review: new
agent-level-send = Gửi thư, mỗi thư chỉ sau khi bạn đồng ý
# review: new
agent-connect-title = { $program } muốn dùng thư của bạn
# review: new
agent-connect-detail = Một tác nhân AI đã yêu cầu làm việc với Inbox Classic. Hãy chọn những gì nó được làm và những tài khoản nó được xem; bạn có thể thay đổi sau trong Công cụ > Tác nhân AI.

    Tác nhân đọc thư do người khác viết, và một thư có thể tìm cách lừa chúng. Inbox Classic luôn hỏi bạn trước khi tác nhân gửi bất cứ thứ gì.
# review: new
agent-reply-to = Trả lời “{ $subject }”
# review: new
agent-reply-all-on = Trả lời tất cả về “{ $subject }”
# review: new
agent-forward-of = Chuyển tiếp “{ $subject }”
# review: new
agent-never-written-one = Bạn chưa từng viết thư cho { $address }.
# review: new
agent-never-written-many = Bạn chưa từng viết thư cho { $count } địa chỉ trong số này.
# review: new
agent-send-title = { $program } muốn gửi thư này
# review: new
agent-send-detail = Hãy kiểm tra người nhận và nội dung thư. Sau khi bạn xác nhận, thư sẽ chờ { $seconds } giây trong Hộp thư đi, nơi bạn vẫn có thể xóa thư.
# review: new
agent-change-title = Những gì { $program } được phép làm
# review: new
agent-change-allowed = Thay đổi những gì tác nhân AI của chương trình này được phép làm với thư của bạn.
# review: new
agent-change-refused = Bạn đã từ chối quyền truy cập của chương trình này. Hãy cho phép để các tác nhân của nó truy cập lại thư của bạn.
# review: new
agent-log-taken-back = { $entry } (đã hoàn tác)
# review: new
agent-files = Tệp: { $files }
# review: new
agent-undo-refused = Không thể hoàn tác.
# review: new
agent-undo-refused-why = Không thể hoàn tác: { $reason }.
# review: new
agent-undo-impossible = thay đổi này không thể hoàn tác
# review: new
agent-undo-not-in-folder = thư không còn trong thư mục đó
# review: new
agent-undo-not-arrived = thư không (hoặc chưa) có trong thư mục đích
# review: new
agent-undo-sent = thư không còn trong Hộp thư đi
# review: new
agent-original-not-downloaded = thư gốc chưa được tải xuống. Hãy mở thư đó trước
# review: new
agent-turned-away = Đã từ chối
# review: new
agent-can-nothing = Không gì cả
# review: new
agent-can-read = đọc
# review: new
agent-can-organize = sắp xếp
# review: new
agent-can-drafts = viết thư nháp
# review: new
agent-can-send = gửi khi bạn đồng ý
# "Read, organize and write drafts"
# review: new
agent-can-list = { $first } và { $last }
# review: new
agent-accounts = { $count ->
    [0] không có tài khoản nào
   *[other] { $count } tài khoản
}
# "Read and organize; 1 account"
# review: new
agent-access = { $can }; { $accounts }
# review: new
agent-unreadable = Không thể đọc thư này.
# review: new
agent-encrypted-original = Thư này đã được mã hóa: tác nhân không thể trả lời hay chuyển tiếp thư, vì nó không thể mã hóa.
# review: new
agent-encrypted = Thư này đã được mã hóa. Tác nhân AI không thể đọc nội dung thư. Hãy mở thư trong Inbox Classic để tự đọc.
# review: new
agent-too-many-changes = Quá nhiều thay đổi trong 30 ngày qua: tác nhân này đã thực hiện số thay đổi tối đa mà Inbox Classic lưu trong nhật ký cho một chương trình. Nó có thể thực hiện thêm khi các thay đổi cũ nhất đã quá 30 ngày.
# review: new
agent-too-many-reads = Quá nhiều lượt đọc trong 30 ngày qua: tác nhân này đã đọc lượng tối đa mà Inbox Classic lưu trong nhật ký cho một chương trình. Nó có thể đọc thêm khi các lượt đọc cũ nhất đã quá 30 ngày.
# review: new
list-encrypted = Thư đã mã hóa
# review: new
agent-log-composed = Đã mở “{ $subject }” trong một thư mới để bạn hoàn tất
# review: new
agent-log-refused = Bạn đã không gửi “{ $subject }”
# review: new
agent-log-sent = Đã đưa “{ $subject }” vào Hộp thư đi để gửi cho { $to }
# review: new
agent-log-draft = Đã lưu thư nháp “{ $subject }”
# review: new
agent-log-draft-replaced = Đã thay thế thư nháp “{ $subject }”
# review: new
agent-log-draft-discarded = Đã yêu cầu xóa thư nháp “{ $subject }”
# review: new
agent-draft-note = { $program }, một tác nhân AI, đã viết thư nháp này. Hãy kiểm tra người nhận và nội dung trước khi gửi.
# review: new
agent-log-read = Đã đánh dấu đã đọc “{ $subject }”
# review: new
agent-log-unread = Đã đánh dấu chưa đọc “{ $subject }”
# review: new
agent-log-flagged = Đã gắn cờ “{ $subject }”
# review: new
agent-log-unflagged = Đã bỏ cờ “{ $subject }”
# review: new
agent-log-deleted = Đã xóa “{ $subject }”
# review: new
agent-log-moved = Đã di chuyển “{ $subject }” đến { $folder }
# review: new
agent-log-junk = Đã đánh dấu “{ $subject }” là thư rác
# review: new
agent-log-not-junk = Đã đánh dấu “{ $subject }” là không phải thư rác
# review: new
agent-log-archived = Đã lưu trữ “{ $subject }”
# review: new
agent-log-folder = Đã yêu cầu tạo thư mục “{ $name }”
# written at the user's yes, before the list is asked; a list that fails replaces it with agent-log-unsubscribe-failed
# review: new
agent-log-unsubscribed = Bạn đã đồng ý hủy đăng ký danh sách của thư “{ $subject }”
# review: new
agent-log-unsubscribe-failed = Không thể hủy đăng ký danh sách của thư “{ $subject }”: { $reason }
# "You did not unsubscribe from news@shop.example, deals@example.com": the lists' addresses, never their names
# review: new
agent-log-unsubscribe-refused = Bạn đã không chấp thuận yêu cầu hủy đăng ký cho: { $senders }
# review: new
agent-unsubscribe-title = { $count ->
    [1] { $program } muốn hủy đăng ký cho bạn khỏi một danh sách gửi thư
   *[other] { $program } muốn hủy đăng ký cho bạn khỏi { $count } danh sách gửi thư
}
# review: new
agent-unsubscribe-detail = { $count ->
    [1] Inbox Classic đề nghị danh sách bên dưới ngừng gửi thư cho bạn, theo cách một lần bấm mà danh sách cung cấp. Không có gì khác được gửi đi, và các thư bạn đang có vẫn được giữ nguyên.
   *[other] Inbox Classic đề nghị từng danh sách bên dưới ngừng gửi thư cho bạn, theo cách một lần bấm mà danh sách đó cung cấp. Không có gì khác được gửi đi, và các thư bạn đang có vẫn được giữ nguyên.
}
# review: new
agent-log-flag-color = Đã gắn cờ { $color ->
    [red] đỏ
    [orange] cam
    [yellow] vàng
    [green] xanh lá
    [blue] xanh lam
    [purple] tím
   *[gray] xám
} cho “{ $subject }”
# review: new
agent-log-renamed = Đã yêu cầu đổi tên thư mục “{ $old }” thành “{ $name }”
# review: new
agent-log-watched = Đã theo dõi cuộc hội thoại “{ $subject }”
# review: new
agent-log-ignored = Đã bỏ qua cuộc hội thoại “{ $subject }”
# review: new
agent-log-unmarked = Đã ngừng theo dõi hoặc bỏ qua cuộc hội thoại “{ $subject }”
# the reason one change can not be taken back (agent-undo-refused-why)
# review: new
agent-undo-changed = thư đã bị thay đổi kể từ đó
# one change of many messages an agent made with a search (apply_to_search), a row of the log; { $query } is the search
# review: new
agent-log-bulk-read = Đã đánh dấu { $count } thư là đã đọc (tìm kiếm: { $query })
# review: new
agent-log-bulk-unread = Đã đánh dấu { $count } thư là chưa đọc (tìm kiếm: { $query })
# review: new
agent-log-bulk-flagged = Đã gắn cờ { $count } thư (tìm kiếm: { $query })
# review: new
agent-log-bulk-unflagged = Đã bỏ cờ { $count } thư (tìm kiếm: { $query })
# review: new
agent-log-bulk-color = Đã gắn cờ { $color ->
    [red] đỏ
    [orange] cam
    [yellow] vàng
    [green] xanh lá
    [blue] xanh lam
    [purple] tím
   *[gray] xám
} cho { $count } thư (tìm kiếm: { $query })
# review: new
agent-log-bulk-moved = Đã di chuyển { $count } thư đến { $folder } (tìm kiếm: { $query })
# review: new
agent-log-bulk-archived = Đã lưu trữ { $count } thư (tìm kiếm: { $query })
# review: new
agent-log-bulk-junk = Đã đánh dấu { $count } thư là thư rác (tìm kiếm: { $query })
# review: new
agent-log-bulk-not-junk = Đã đánh dấu { $count } thư là không phải thư rác (tìm kiếm: { $query })
# review: new
agent-log-bulk-deleted = Đã xóa { $count } thư (tìm kiếm: { $query })
# Undo Everything Since in the AI Agents window: how far back it reaches
# review: new
agent-undo-span = { $span ->
    [quarter] Trong 15 phút qua
    [hour] Trong 1 giờ qua
    [hours] Trong 4 giờ qua
    [day] Trong 24 giờ qua
    [week] Trong 7 ngày qua
   *[all] Trong 30 ngày qua
}
# the question before it takes back what a program did in the span chosen
# review: new
agent-undo-since-question = { $count ->
    [0] { $program } không có thay đổi nào trong khoảng thời gian này có thể hoàn tác.
    [1] Thử hoàn tác thay đổi đã ghi nhận của { $program } trong khoảng thời gian này?
   *[other] Thử hoàn tác { $count } thay đổi đã ghi nhận của { $program } trong khoảng thời gian này?
}
# review: new
agent-undo-since-detail = Inbox Classic sẽ cố khôi phục thư mục, trạng thái đã đọc và cờ, đồng thời xóa các thư vẫn đang chờ trong Hộp thư đi. Những thay đổi không còn hoàn tác được sẽ bị bỏ qua. Một số thay đổi màu cờ về sau có thể bị ghi đè.
# what taking back did, then a line for each kind of message it left as it is
# review: new
agent-undo-done = { $count ->
    [0] Không có gì được hoàn tác.
   *[other] Đã hoàn tác toàn bộ hoặc một phần { $count } thay đổi đã ghi nhận.
}
# review: new
agent-undo-left-gone = { $count } thư không còn ở nơi mà thay đổi đã đặt chúng.
# review: new
agent-undo-left-changed = { $count } thư đã bị thay đổi kể từ đó, bởi bạn hoặc trên máy chủ, nên được giữ nguyên.
# review: new
agent-undo-left-sent = { $count } thư đã rời khỏi Hộp thư đi.
# review: new
agent-undo-left-impossible = { $count } thay đổi không thể hoàn tác.
# the Send question of an agent's answer to a calendar invitation: what it answers, and when the event is
# review: new
agent-invitation-reply = { $response ->
    [accept] Thư này chấp nhận lời mời “{ $summary }” ({ $when }).
    [tentative] Thư này tạm chấp nhận lời mời “{ $summary }” ({ $when }).
   *[decline] Thư này từ chối lời mời “{ $summary }” ({ $when }).
} Thư được gửi đến người tổ chức có tên trong lời mời. Phản hồi của bạn trên máy này sẽ thay đổi khi máy chủ thư chấp nhận thư, mà không cần xác nhận từ lịch của người tổ chức.
# the subject of an answer to an invitation, as calendar programs write it
# review: new
invitation-reply-subject = { $response ->
    [accept] Đã chấp nhận: { $summary }
    [tentative] Tạm chấp nhận: { $summary }
   *[decline] Đã từ chối: { $summary }
}
# the text of an answer to an invitation; { $name } is the user's name, or address
# review: new
invitation-reply-text = { $response ->
    [accept] { $name } đã chấp nhận lời mời này.
    [tentative] { $name } đã tạm chấp nhận lời mời này.
   *[decline] { $name } đã từ chối lời mời này.
}
# what a program read in an hour, a row of the log: "Read 14 messages and searched 3 times" (joined by agent-can-list)
# review: new
agent-reads-messages = đã đọc { $count } thư
# review: new
agent-reads-attachments = đã yêu cầu { $count } tệp đính kèm
# review: new
agent-reads-searches = { $count ->
    [1] đã tìm kiếm một lần
   *[other] đã tìm kiếm { $count } lần
}
# review: new
agent-reads-lists = { $count ->
    [1] đã xem danh sách thư một lần
   *[other] đã xem danh sách thư { $count } lần
}
# each read under that row
# review: new
agent-read-message = Đã đọc “{ $subject }”
# review: new
agent-read-conversation = Đã đọc cuộc hội thoại “{ $subject }” ({ $count } thư)
# review: new
agent-read-attachment = Đã yêu cầu tệp đính kèm “{ $name }” của “{ $subject }”
# review: new
agent-read-search = Đã tìm kiếm “{ $query }”: { $count } thư
# review: new
agent-read-people = Đã tra cứu người theo phần đầu tên hoặc địa chỉ: “{ $query }”
# review: new
agent-read-list = Đã xem { $count } mục trong danh sách (phạm vi: { $folder })
# review: new
agent-read-changes = Đã xem chi tiết của { $count } thư mới
# the programs started from a terminal app, which share one access: in the list of programs and the question when one connects
# review: new
agent-terminal-programs-mac = Các chương trình được khởi chạy từ { $terminal }
# review: new
agent-terminal-programs-windows = Các chương trình được khởi chạy từ cửa sổ dòng lệnh ({ $terminal })
# review: new
agent-terminal-programs-linux = Các chương trình được khởi chạy từ cửa sổ dòng lệnh ({ $terminal })
# one of them, as the questions to send or unsubscribe name it: "A program started from Terminal wants to send this message"
# review: new
agent-terminal-program-mac = Một chương trình được khởi chạy từ { $terminal }
# review: new
agent-terminal-program-windows = Một chương trình được khởi chạy từ cửa sổ dòng lệnh ({ $terminal })
# review: new
agent-terminal-program-linux = Một chương trình được khởi chạy từ cửa sổ dòng lệnh ({ $terminal })
# review: new
agent-connect-title-terminal = { $programs } muốn dùng thư của bạn
# review: new
agent-connect-terminal-detail = Các tác nhân AI được khởi chạy từ cùng một chương trình dòng lệnh đã nhận diện sẽ dùng chung quyền truy cập bạn cho phép ở đây. Để cấp quyền riêng cho một tác nhân, hãy thêm --name và một tên tùy ý vào đối số của nó trong thiết đặt MCP của tác nhân. Tên đó không xác minh danh tính của tác nhân.
# above the question when a program said it was another one than the system found: "It said it was Claude. Inbox Classic checked which program started it: python3."
# review: new
agent-connect-claimed = Nó tự nhận là { $claimed }. Inbox Classic đã kiểm tra chương trình nào khởi chạy nó: { $program }.

## Tên phím theo bàn phím của ngôn ngữ, trong phần trợ giúp (Windows và Linux)

# review: new
key-ctrl = Ctrl
# review: new
key-alt = Alt
# review: new
key-shift = Shift
# review: new
key-del = Del
# review: new
key-enter = Enter

## Đăng nhập và mật khẩu

# review: new
sign-in-no-refresh = nhà cung cấp không cấp mã thông báo làm mới
# review: new
sign-in-no-account = nhà cung cấp không cho biết tài khoản nào đã đăng nhập
# review: new
sign-in-not-finished = quá trình đăng nhập chưa hoàn tất
# review: new
secrets-unavailable = { $store } không khả dụng
# review: new
secrets-unavailable-why = { $store } không khả dụng: { $error }
# review: new
secrets-windows = Trình quản lý Thông tin xác thực
# review: new
secrets-mac = chuỗi khóa
# review: new
secrets-linux = vòng khóa của hệ thống (Secret Service)
# review: new
error-no-such-file = không có tệp như vậy
# review: new
cards-file-too-big = Tệp này vượt quá giới hạn kích cỡ để nhập sổ địa chỉ.
# review: new
ui-sender-added = Đã thêm { $name } vào Sổ địa chỉ.
# review: new
ui-sender-known = { $name } đã có trong Sổ địa chỉ.
# review: new
ui-sender-none = Người gửi thư này không có địa chỉ email để thêm.
# review: new
card-name-needed = Liên hệ không có tên và không có địa chỉ email.
# a file of Import Address Book that could not be read: "contacts.vcf: there is no such file"
# review: new
cards-file-failed = { $file }: { $reason }

## Mã dùng một lần: thẻ ở đầu thư có mã đăng nhập hoặc mã xác minh

# the domain the code is for, which signed the message
# review: new
otp-heading = Mã từ { $domain }
# review: new
otp-copy = Sao chép
# review: new
otp-note = Chỉ nhập mã trên một trang của { $domain }.
# review: new
otp-old = Mã này được gửi hơn một giờ trước khi bạn mở thư, và có lẽ đã hết hạn.

# how many are invited, in the card of an event
# review: new
event-attendees = { $count } người tham dự

# the first line of a new message's notification when it has a code, for a domain that signed it
# review: new
otp-notification = { $code } là mã của bạn cho { $domain }

## Khóa OpenPGP (keys.rs)
# review: new
pgp-key-valid = Hợp lệ
# review: new
pgp-key-expires = Hợp lệ đến { $date }
# review: new
pgp-key-expired = Đã hết hạn vào { $date }
# review: new
pgp-key-revoked = Đã thu hồi
# review: new
pgp-key-revoked-why = Đã thu hồi: { $reason }
# review: new
pgp-key-not-valid = Không hợp lệ
# review: new
pgp-key-locked = Không thể dùng: khóa bảo vệ của nó không khả dụng trong { $store }. Hãy kiểm tra xem kho đó có khả dụng và đã được mở khóa chưa. Nếu khóa bảo vệ bị mất, hãy nhập bản sao lưu khóa riêng tư.
# review: new
pgp-source-own = Tạo trong Inbox Classic
# review: new
pgp-source-file = Nhập từ tệp
# review: new
pgp-source-paste = Đã dán
# review: new
pgp-source-attachment = Từ một thư
# review: new
pgp-source-vcard = Từ một thẻ liên hệ
# review: new
pgp-source-wkd = Từ nhà cung cấp thư của người gửi
# review: new
pgp-source-keyserver = Từ keys.openpgp.org
# review: new
pgp-source-autocrypt = Từ tiêu đề Autocrypt của một thư
# review: new
pgp-error-no-store = Khóa bảo vệ các khóa riêng tư của bạn được giữ trong { $store }, nhưng không thể dùng: { $error }
# review: new
pgp-error-wrong-passphrase = Cụm mật khẩu không đúng.
# review: new
pgp-error-not-a-key = Đây không phải là khóa OpenPGP.
# review: new
pgp-error-too-large = Khóa quá lớn.
# review: new
pgp-error-unusable = Không thể dùng khóa này. Có thể nó thiếu khóa ký hoặc khóa mã hóa phù hợp, hoặc dùng thuật toán mật mã không được hỗ trợ.
# review: new
pgp-imported-private = { $count ->
    [1] Đã nhập khóa riêng tư của bạn.
   *[other] Đã nhập { $count } khóa riêng tư.
}
# review: new
pgp-imported-public = { $count ->
    [1] Đã nhập một khóa.
   *[other] Đã nhập { $count } khóa.
}
# review: new
pgp-imported-pending = Một khóa khác đang được dùng cho { $addresses }: khóa mới sẽ chờ trong liên hệ cho đến khi bạn chọn nó.
# review: new
pgp-error-needs-passphrase = Khóa riêng tư được bảo vệ bằng cụm mật khẩu. Hãy nhập cụm mật khẩu để nhập khóa.
# review: new
pgp-error-mismatch = Khóa riêng tư không thuộc về khóa công khai của nó. Có thể nó đã bị sửa đổi.
# review: new
pgp-file-name-public = Khóa công khai { $who }.asc
# review: new
pgp-file-name-private = Bản sao lưu khóa riêng tư { $who }.asc
# review: new
pgp-pending = Đã tìm thấy một khóa khác cho { $address } vào { $date }.

## Đọc thư đã ký và đã mã hóa (protect.rs)
# review: new
pgp-part-verified = Được ký bởi { $signer }, khóa đã xác minh
# review: new
pgp-part-signed = Được ký bởi { $signer } (khóa chưa xác minh)
# review: new
pgp-part-other = Được ký bởi { $signer }, không phải người gửi
# review: new
pgp-part-unknown-key = Đã ký, nhưng không rõ khóa
# review: new
pgp-part-not-signed = Chưa ký
# review: new
pgp-part-not-checked = Chưa kiểm tra chữ ký
# review: new
pgp-part-encrypted = Đã mã hóa. { $signature }
# review: new
pgp-part-no-key = Được mã hóa bằng một khóa bạn không có
# review: new
pgp-part-changed = Phần được mã hóa không qua được kiểm tra tính toàn vẹn và không được hiển thị
# review: new
pgp-part-unprotected = Được mã hóa mà không có bảo vệ chống sửa đổi, không được hiển thị
# review: new
pgp-part-broken = Không thể đọc phần được mã hóa
# review: new
pgp-why-mismatch = Chữ ký không khớp với văn bản này
# review: new
pgp-why-weak-hash = Chữ ký dùng { $hash }, thuật toán không còn an toàn
# review: new
pgp-why-key-expired = Được ký sau khi khóa hết hạn vào { $date }
# review: new
pgp-why-key-revoked = Được ký bằng một khóa đã bị thu hồi
# review: new
pgp-why-not-signing-key = Được ký bằng một khóa không được phép ký
# review: new
pgp-why-from-future = Chữ ký mang ngày trong tương lai
# review: new
pgp-why-signature-expired = Chữ ký đã hết hạn
# review: new
pgp-why-key-not-valid = Được ký bằng một khóa không hợp lệ
# review: new
pgp-why-not-for-you = Được ký cho người nhận khác, rồi được chuyển cho bạn
# review: new
pgp-why-not-key-in-use = Được ký bằng một khóa khác với khóa đang dùng cho { $address }
# review: new
pgp-part-pictures-loaded = { $label }. Ảnh đã được tải từ internet
# review: new
pgp-error-no-own-key = Bạn không có khóa cho { $address } để ký hoặc mã hóa. Hãy tạo một khóa trong Công cụ > Khóa mã hóa, hoặc tắt Ký và Mã hóa.
# review: new
pgp-error-missing-keys = { $count ->
    [1] Không có khóa mã hóa dùng được cho người nhận này: { $addresses }.
   *[other] Không có khóa mã hóa dùng được cho những người nhận này: { $addresses }.
}
# review: new
pgp-error-encrypted-quote = Thư này chứa văn bản, ảnh hoặc tệp đính kèm từ thư đã mã hóa nên chỉ có thể gửi ở dạng mã hóa. Hãy bật Mã hóa, hoặc gỡ toàn bộ nội dung đó.
# review: new
pgp-error-protect = Không thể ký hoặc mã hóa thư: { $reason }
# review: new
pgp-found-keys = Đã tìm thấy khóa cho: { $addresses }.
# review: new
pgp-found-none = Không tìm thấy khóa nào cho { $addresses }. Hãy đề nghị họ gửi khóa công khai cho bạn.
# review: new
pgp-found-no-key = Không tìm thấy khóa nào.
# review: new
pgp-find-unavailable = Hiện không thể tra cứu khóa: { $error }
# review: new
pgp-publish-pending = keys.openpgp.org đã gửi liên kết xác nhận đến các địa chỉ này: { $addresses }. Hãy xác nhận từng địa chỉ để người khác có thể tìm khóa của bạn bằng địa chỉ đó.
# review: new
pgp-publish-done = Khóa của bạn đã được công bố trên keys.openpgp.org cho { $addresses }.
# review: new
pgp-publish-failed = Không thể công bố khóa: { $error }
# review: new
pgp-keyserver-off = Việc tra cứu khóa trên keys.openpgp.org đã bị tắt trong { $settings }.
# the compose window with Sign and Encrypt: the line under the fields, each recipient's key, the questions
# review: new
pgp-compose-encrypted = { $count ->
    [1] Sẽ được mã hóa và ký cho bạn và { $addresses }.
   *[other] Sẽ được mã hóa và ký cho bạn và { $count } người nhận của thư.
}
# review: new
pgp-compose-encrypt-ready = Thư sẽ được mã hóa và ký. Hãy thêm người nhận mà bạn có khóa của họ.
# review: new
pgp-compose-missing = { $count ->
    [1] Không có khóa dùng được cho { $addresses }, nên chưa thể mã hóa thư.
   *[other] { $count } người nhận không có khóa dùng được, nên chưa thể mã hóa thư: { $addresses }.
}
# review: new
pgp-compose-looking = Đang tìm khóa của { $addresses }...
# review: new
pgp-compose-signed = Sẽ được ký: người nhận có thể kiểm tra nội dung đã ký không bị thay đổi. Họ cũng phải xác minh ai là chủ sở hữu khóa của bạn.
# review: new
pgp-compose-reply-clear = Không được mã hóa, dù thư mà nó trả lời hoặc chuyển tiếp đã được mã hóa.
# review: new
pgp-compose-encrypted-files = Tệp của một thư đã mã hóa đang được đính kèm, nên thư này chỉ có thể gửi ở dạng mã hóa. Hãy bật Mã hóa, hoặc gỡ các tệp đó.
# review: new
pgp-compose-sign-tip = Ký thư để người nhận có thể kiểm tra nội dung. Họ cũng phải xác minh ai là chủ sở hữu khóa của bạn
# review: new
pgp-compose-sign-tip-encrypted = Thư đã mã hóa luôn được ký
# review: new
pgp-compose-encrypt-tip = Mã hóa thư, để chỉ bạn và người nhận mới đọc được
# review: new
pgp-compose-make-key = Bạn chưa có khóa cho { $address }. Tạo khóa ngay? Với khóa này, thư của bạn có thể được ký và mã hóa.
# review: new
pgp-compose-key-unusable = Không thể dùng khóa của bạn cho { $address } ({ $state }). Hãy mở Khóa mã hóa để nhập bản sao lưu của khóa hoặc tạo khóa mới.
# review: new
pgp-compose-encrypt-off-quote = Thư này chứa văn bản, ảnh hoặc tệp đính kèm từ thư đã mã hóa. Khi không mã hóa, thư không thể được gửi cho đến khi bạn gỡ toàn bộ nội dung đó. Vẫn tắt mã hóa?
# review: new
pgp-compose-encrypt-off-reply = Thư này trả lời hoặc chuyển tiếp một thư đã mã hóa. Khi không mã hóa, bất kỳ ai xử lý thư của bạn trên đường đi đều có thể đọc được. Tắt mã hóa?
# review: new
pgp-recipient-verified = Khóa đã xác minh
# review: new
pgp-recipient-found = Khóa chưa xác minh
# review: new
pgp-recipient-own = Khóa của chính bạn
# review: new
pgp-recipient-looking = Đang tìm khóa...
# review: new
pgp-recipient-missing = Không có khóa
# review: new
pgp-recipient-not-found = Không có khóa: không tìm thấy khóa nào vào { $date }
# review: new
pgp-recipient-unusable = Không thể dùng khóa: { $state }
# review: new
pgp-recipients-intro = Thư được mã hóa bằng khóa của từng người nhận và bằng khóa của bạn.
# review: new
pgp-recipients-intro-missing = { $count ->
    [1] Một người nhận không có khóa mã hóa dùng được. Hãy tìm khóa hoặc gỡ người nhận đó. Chỉ có thể gửi không mã hóa sau khi đã gỡ mọi nội dung từ thư đã mã hóa.
   *[other] { $count } người nhận không có khóa mã hóa dùng được. Hãy tìm khóa của họ hoặc gỡ những người nhận đó. Chỉ có thể gửi không mã hóa sau khi đã gỡ mọi nội dung từ thư đã mã hóa.
}
# review: new
pgp-details-part = Phần { $number }: { $label }
# review: new
attachment-from-part = Từ phần { $number }: { $label }
# review: new
pgp-details-signed = Được ký { $when } bằng khóa { $key }
# review: new
pgp-details-unknown-key = Được ký bằng khóa { $key }, khóa mà bạn không có
# review: new
pgp-details-opened = Đã giải mã bằng khóa { $key } của bạn
# review: new
pgp-details-for = Được mã hóa cho { $keys }
# review: new
pgp-details-plain = Không được ký và không được mã hóa
# review: new
pgp-bar-parts = Thư này có { $count } phần: { $list }. Mỗi phần cho biết cách nó được bảo vệ.
# review: new
pgp-bar-count-verified = { $count } đã xác minh
# review: new
pgp-bar-count-encrypted-signed = { $count } đã mã hóa và ký
# review: new
pgp-bar-count-encrypted = { $count } đã mã hóa
# review: new
pgp-bar-count-signed = { $count } đã ký
# review: new
pgp-bar-count-warning = { $count } cần chú ý
# review: new
pgp-bar-count-neutral = { $count } không có chữ ký được xác nhận
# the setup file: settings, accounts, contacts and keys carried to another computer
# review: new
setup-part-settings = Cài đặt
# review: new
setup-part-preferences = Tùy chọn cửa sổ
# review: new
setup-part-accounts = Tài khoản
# review: new
setup-part-sign-in-apps = Ứng dụng đăng nhập
# review: new
setup-part-contacts = Liên hệ và nhóm
# review: new
setup-part-keys = Khóa mã hóa
# review: new
setup-part-rules = Quy tắc thư
# review: new
setup-part-trusted-senders = Người gửi tin cậy
# review: new
setup-holds-settings = { $count } cài đặt
# review: new
setup-holds-preferences = { $count } tùy chọn
# review: new
setup-holds-accounts = { $count } tài khoản
# review: new
setup-holds-sign-in-apps = { $count } ứng dụng đăng nhập
# review: new
setup-holds-built-in = Những ứng dụng đăng nhập có sẵn nào được bật
# review: new
setup-holds-contacts = { $count } liên hệ
# review: new
setup-holds-groups = { $count } nhóm
# review: new
setup-holds-own-keys = { $count } khóa của bạn
# review: new
setup-holds-contact-keys = { $count } khóa của liên hệ
# review: new
setup-holds-rules = { $count } quy tắc
# review: new
setup-holds-trusted-senders = { $count } người gửi tin cậy
# review: new
setup-sign-in-password = Mật khẩu
# review: new
setup-account-secret-password = Mật khẩu của tài khoản có trong tệp.
# review: new
setup-account-secret-token = Thông tin đăng nhập đã lưu của tài khoản có trong tệp.
# review: new
setup-account-asks-password = Tài khoản sẽ hỏi mật khẩu sau khi nhập.
# review: new
setup-account-signs-in-again = Bạn sẽ đăng nhập lại vào tài khoản sau khi nhập.
# review: new
setup-account-here = Tài khoản đã được thiết lập ở đây, nên sẽ bị bỏ qua.
# review: new
setup-account-no-app = Tài khoản đăng nhập bằng { $app }, ứng dụng chưa được thiết lập ở đây. Hãy nhập cả các ứng dụng đăng nhập.
# review: new
setup-invalid-address = “{ $address }” không phải là địa chỉ email.
# review: new
setup-invalid-server = Thiết đặt { $server } có tên máy chủ, cổng hoặc tùy chọn bảo mật không hợp lệ.
# review: new
setup-invalid-user = Tài khoản không có tên người dùng.
# review: new
setup-invalid-sign-in = Phương thức hoặc cấu hình đăng nhập của tài khoản không được hỗ trợ.
# review: new
setup-error-empty = Tệp trống.
# review: new
setup-error-too-large = Tệp thiết lập vượt quá giới hạn kích cỡ.
# review: new
setup-error-not-setup = Tệp này không phải là tệp thiết lập của Inbox Classic.
# review: new
setup-error-damaged = Tệp thiết lập bị hỏng và không thể đọc.
# review: new
setup-error-newer = Tệp thiết lập này được lưu bởi một phiên bản Inbox Classic mới hơn ({ $version }). Hãy cập nhật Inbox Classic, rồi nhập lại.
# review: new
setup-error-needs-passphrase = Tệp thiết lập này được bảo vệ bằng cụm mật khẩu. Hãy nhập cụm mật khẩu đã dùng khi lưu.
# review: new
setup-error-wrong-passphrase = Đó không phải là cụm mật khẩu đã dùng khi lưu tệp thiết lập này.
# review: new
setup-error-changed = Tệp thiết lập không qua được kiểm tra tính toàn vẹn. Có thể tệp đã bị sửa đổi hoặc bị hỏng nên không thể nhập.
# review: new
setup-error-read = Không thể đọc tệp thiết lập: { $error }
# review: new
setup-error-write = Không thể lưu tệp thiết lập: { $error }
# review: new
setup-error-no-parts = Hãy chọn ít nhất một phần.
# review: new
setup-left-out = { $count } mục của { $part } không dùng được và bị bỏ qua.
# review: new
setup-imported-settings = Đã thay thế cài đặt.
# review: new
setup-imported-preferences = Đã thay thế tùy chọn cửa sổ.
# review: new
setup-added-accounts = Đã thêm { $count } tài khoản.
# review: new
setup-skipped-here = { $address } đã được thiết lập ở đây, nên đã bị bỏ qua.
# review: new
setup-skipped-no-app = Đã bỏ qua { $address }: tài khoản đăng nhập bằng { $app }, ứng dụng chưa được thiết lập ở đây.
# review: new
setup-skipped-invalid = Đã bỏ qua { $address }: { $reason }
# review: new
setup-asks-password = { $address } sẽ hỏi mật khẩu khi kết nối.
# review: new
setup-signs-in-again = { $address } sẽ yêu cầu bạn đăng nhập lại khi kết nối.
# review: new
setup-added-sign-in-apps = Đã thêm { $count } ứng dụng đăng nhập.
# review: new
setup-skipped-sign-in-apps = { $count } ứng dụng đăng nhập đã được thiết lập ở đây.
# review: new
setup-added-contacts = Đã thêm { $count } liên hệ vào sổ địa chỉ.
# review: new
setup-skipped-contacts = { $count } liên hệ đã có trong sổ địa chỉ.
# review: new
setup-added-groups = Đã thêm hoặc bổ sung { $count } nhóm.
# review: new
setup-added-own-keys = Đã thêm { $count } khóa của bạn.
# review: new
setup-added-contact-keys = Đã thêm { $count } khóa của liên hệ.
# review: new
setup-added-rules = Đã thêm { $count } quy tắc thư.
# review: new
setup-skipped-rules = { $count } quy tắc thư đã có ở đây.
# review: new
setup-skipped-rules-account = { $count } quy tắc thư dành cho tài khoản không có ở đây, nên đã bị bỏ qua.
# review: new
setup-rules-waiting = { $count } quy tắc thư đang chờ tìm thấy thư mục đích trong lúc đồng bộ tài khoản.
# review: new
setup-added-trusted-senders = Đã thêm { $count } người gửi tin cậy.
# review: new
setup-nothing = Không có gì được nhập.
# review: new
setup-account-servers = { $imap } và { $smtp } ({ $signin })
# review: new
setup-file-name = Cài đặt và tài khoản Inbox Classic
# review: new
setup-skipped-unreachable = Đã bỏ qua { $name }: không thể kết nối hoặc kiểm tra dịch vụ đăng nhập của nó. Hãy kiểm tra ứng dụng cần thiết trong Ứng dụng đăng nhập trước khi thử lại.
# review: new
attachment-runs-programs = “{ $name }” có thể chạy chương trình, nên Inbox Classic không mở tệp này. Hãy lưu tệp, rồi tự mở nếu bạn tin tưởng nguồn gốc của nó.
# review: new
attachment-decrypted-note = Tệp đính kèm này đến từ thư đã mã hóa. Để mở tệp trong ứng dụng khác, Inbox Classic lưu một bản sao không mã hóa vào một thư mục tạm của tài khoản người dùng của bạn. Khi khởi động, ứng dụng sẽ cố xóa các bản sao cũ hơn một ngày.
# a bar over the list when the server did not do what the user asked of messages, so they are as they were again
# review: new
undone-move = { $count ->
   *[other] Máy chủ không di chuyển { $messages } đến { $folder }, nên thư đã trở lại { $from }: { $reason }
}
# review: new
undone-delete = { $count ->
   *[other] Máy chủ không xóa { $messages }, nên thư đã trở lại { $from }: { $reason }
}
# review: new
undone-archive = { $count ->
   *[other] Máy chủ không lưu trữ { $messages }, nên thư đã trở lại { $from }: { $reason }
}
# review: new
undone-read = { $count ->
   *[other] Máy chủ không đánh dấu { $messages } là đã đọc, nên thư lại là chưa đọc: { $reason }
}
# review: new
undone-unread = { $count ->
   *[other] Máy chủ không đánh dấu { $messages } là chưa đọc, nên thư lại là đã đọc: { $reason }
}
# review: new
undone-flags = { $count ->
   *[other] Máy chủ không thay đổi cờ của { $messages }, nên thư vẫn như cũ: { $reason }
}

## Xem trước tệp đính kèm: ảnh và tệp PDF được hiển thị trong thư

# the reading option that turns PDF previews on and off (the apps show it)
# review: new
preview-pdf-option = Hiển thị tệp PDF trong thư
# the tile of a PDF file while PDF previews are off
# review: new
preview-pdf-off = Tệp PDF không được hiển thị trong thư.
# the note where previews are, after the app ended while it was drawing a file of a message: { $option } is the option's name
# review: new
preview-pdf-off-crashed = Inbox Classic đã đóng khi đang hiển thị một tệp trong thư, nên tệp PDF không còn được hiển thị trong thư. Ảnh vẫn được hiển thị. Để hiển thị lại tệp PDF, hãy bật { $option } trong { $settings }.
# under the pages of a PDF file shown in a message: its page count and size ("3 pages, 84 KB")
# review: new
preview-pdf-details = { $count } trang, { $size }
# what a screen reader says of a page of a PDF file shown in a message
# review: new
preview-page-alt = { $name }, trang { $page } trên { $count }
# the link under the pages of a PDF file shown in a message, when it has more pages than are shown
# review: new
preview-more-pages = { $count ->
    [1] Mở để xem trang này
   *[other] Mở để xem cả { $count } trang
}
# after the files shown in a message, when it has more pictures and PDF files than are shown; the list is the
# strip of files over the message
# review: new
preview-more-files = Còn { $count } tệp khác trong danh sách phía trên
# the tile of a picture or PDF file of a message still downloading (the ellipsis as in reader-downloading)
# review: new
preview-tile-downloading = Đang tải xuống…
# the tile of a picture or PDF file whose size was not read in time when the message was shown: its preview
# comes in its place in a moment (the ellipsis as in reader-downloading)
# review: new
preview-tile-preparing = Đang chuẩn bị…
# the tile of a picture in a format not shown yet: { $format } is its name (HEIC, AVIF, JPEG XL)
# review: new
preview-tile-format = Chưa hỗ trợ hiển thị ảnh { $format }
# the tile of a PDF file that wants a password to open
# review: new
preview-tile-password = Được bảo vệ bằng mật khẩu: hãy mở tệp để nhập mật khẩu
# the tile of a picture or PDF file over the size or pixel limit
# review: new
preview-tile-too-large = Quá lớn để hiển thị
# the tile of a file that is broken, or not what its name says
# review: new
preview-tile-unreadable = Không thể hiển thị
# the tile of a file that took too long to draw
# review: new
preview-tile-timed-out = Việc chuẩn bị bản xem trước mất quá nhiều thời gian
# the tile of a file that closed the app once while it was drawn: never drawn again
# review: new
preview-tile-crashed = Không có bản xem trước: lần thử trước đã bị gián đoạn
# the tile of a file while previews are paused after a file took too long, until the app starts again
# review: new
preview-tile-off = Không hiển thị cho đến khi Inbox Classic khởi động lại
# in a printout, for a file shown in the message that is not printed (a PDF file, a tile): { $details } is its size,
# or a PDF file's pages and size
# review: new
preview-not-printed = { $name } ({ $details }) không được in. Hãy mở tệp để in.
