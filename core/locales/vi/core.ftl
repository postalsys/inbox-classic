# Bản nháp tiếng Việt, đang chờ người bản ngữ duyệt.
# Những gì phần lõi nói, giống nhau trên mọi nền tảng. Mã chương trình điền các chỗ giữ chỗ trong { $braces }; hãy giữ
# chúng ở vị trí ngôn ngữ cần. Tiếng Việt không có số nhiều theo CLDR: chỉ có *[other]; [0] và [1] chọn theo đúng số.

## Số đếm và kích cỡ

messages = { $count } thư
# the separator of decimals in sizes: 2.4 MB
decimal-separator = ,
list-separator = { ", " }
size-bytes = { $count } byte
size-kb = { $size } KB
size-mb = { $size } MB
size-gb = { $size } GB
send-delay-off = Tắt
send-delay-seconds = { $count } giây
# the status bar: "12 messages, 3 unread"
list-counts = { $messages }, { $unread } chưa đọc
list-counts-selected = { $messages }, { $unread } chưa đọc, { $selected } đã chọn
# the status bar while searching: "12 found, 3 unread"
list-counts-found = Tìm thấy { $found }, { $unread } chưa đọc
list-counts-found-selected = Tìm thấy { $found }, { $unread } chưa đọc, { $selected } đã chọn
list-counts-none = Không tìm thấy thư nào

## Các thư mục đặc biệt, theo tên trong Outlook Express

folder-inbox = Hộp thư đến
folder-sent = Mục đã gửi
folder-deleted = Mục đã xóa
folder-drafts = Thư nháp
folder-junk = Email rác
folder-archive = Lưu trữ

## Ngăn đọc

reader-no-message = Chưa chọn thư nào.
reader-downloading = Đang tải thư xuống…
reader-downloading-detail = Thư sẽ hiện ở đây khi tải xuống xong.
reader-downloading-size = Thư có kích cỡ { $size }. Thư sẽ hiện ở đây khi được tải xuống.
reader-failed = Không thể tải thư xuống
reader-failed-network = Không thể kết nối với máy chủ thư hoặc kết nối bị gián đoạn ({ $reason }).
reader-failed-sign-in = Máy chủ thư không chấp nhận đăng nhập ({ $reason }). Hãy kiểm tra mật khẩu hoặc đăng nhập lại trong thiết đặt của tài khoản.
reader-failed-security = Không thể tạo kết nối bảo mật với máy chủ thư ({ $reason }).
reader-failed-other = Máy chủ thư trả lời: { $reason }.
reader-retry-note = Ứng dụng sẽ thử lại khi tài khoản kết nối lại.
reader-unreadable = Không thể hiển thị thư này: { $error }
message-source-title = Nguồn thư: { $subject }
message-source-untitled = Nguồn thư

## In thư, và phần đầu của thư được trích dẫn trong thư trả lời hoặc chuyển tiếp

header-from = Từ
header-date = Ngày
header-to = Đến
header-cc = Cc
header-sent = Đã gửi
header-subject = Chủ đề
header-security = Bảo mật
header-part = Phần { $number }
quote-original = ----- Thư gốc -----
fold-show-earlier = Hiện các thư trước đó

## Thư bị trả lại: thẻ ở đầu thông báo cho biết một thư chưa được gửi đến nơi

bounce-failed = Thư của bạn không được gửi đến nơi
bounce-delayed = Thư của bạn vẫn chưa được gửi đến nơi
bounce-delayed-note = Máy chủ thư của bạn vẫn đang thử gửi thư. Bạn không cần gửi lại.
# the link to the message the notice is about, in Sent Items or another folder
bounce-show-message = Hiện thư bị trả lại
# the link of a delay's card to the message that is still on its way
bounce-show-delayed = Hiện thư bị chậm
bounce-what-to-do = Bạn có thể làm gì:
# what to do about a recipient the message is still on its way to: in the card of a delay, and in the card of a failure
bounce-delayed-do = Chưa cần làm gì. Nếu thư vẫn không gửi được, bạn sẽ nhận thêm một thông báo.
bounce-delayed-row-do = Chưa cần làm gì. Máy chủ thư của bạn vẫn đang thử gửi thư, và bạn sẽ nhận thêm một thông báo nếu không gửi được.
# folds the receiving server's own words
bounce-details = Chi tiết
# a recipient the notice does not name
bounce-someone = Một người nhận
# in Details: the server that refused the message, the status code it gave, and the server that wrote the notice
bounce-server = Máy chủ: { $server }
bounce-status = Trạng thái: { $status }
bounce-reported-by = Báo cáo bởi: { $server }
bounce-retry-minutes = Máy chủ nhận yêu cầu chờ { $count } phút trước lần thử tiếp theo.
bounce-retry-hours = Máy chủ nhận yêu cầu chờ { $count } giờ trước lần thử tiếp theo.
# the names of the blocklists, "Spamhaus ZEN, Barracuda"
bounce-blocklist = Danh sách chặn: { $lists }
bounce-user-unknown = Địa chỉ không tồn tại
bounce-user-unknown-why = Máy chủ nhận không có hộp thư nào với địa chỉ này. Có thể địa chỉ bị gõ sai, hoặc người đó không còn dùng địa chỉ này.
bounce-user-unknown-do = Hãy kiểm tra chính tả của địa chỉ, hoặc hỏi người đó địa chỉ họ đang dùng.
bounce-invalid-address = Địa chỉ không hợp lệ
bounce-invalid-address-why = Địa chỉ không được viết theo dạng có thể gửi thư đến.
bounce-invalid-address-do = Hãy tìm lỗi gõ, chẳng hạn một dấu cách, một chữ cái bị thiếu hoặc không có gì sau dấu @.
bounce-mailbox-disabled = Hộp thư đã đóng
bounce-mailbox-disabled-why = Địa chỉ tồn tại nhưng hộp thư đã bị tắt hoặc không còn được sử dụng.
bounce-mailbox-disabled-do = Hãy liên lạc với người đó bằng cách khác và hỏi địa chỉ họ đang dùng.
bounce-mailbox-full = Hộp thư đã đầy
bounce-mailbox-full-why = Hộp thư của người nhận không còn chỗ cho thư mới.
bounce-mailbox-full-do = Hãy gửi lại sau vài ngày, hoặc báo cho người đó bằng cách khác.
bounce-spam-blocked = Bị từ chối vì là thư rác
bounce-spam-blocked-why = Máy chủ nhận cho rằng thư là thư rác.
bounce-spam-blocked-do = Hãy gửi lại mà không có những gì trông giống thư rác, chẳng hạn nhiều liên kết, liên kết rút gọn hoặc tệp đính kèm lớn. Nếu vẫn tiếp tục xảy ra, hãy hỏi nhà cung cấp thư của bạn.
bounce-virus-detected = Bị từ chối vì có vi-rút
bounce-virus-detected-why = Máy chủ nhận báo có vi-rút hoặc nội dung độc hại khác trong thư hoặc tệp đính kèm.
bounce-virus-detected-do = Hãy kiểm tra tệp đính kèm bằng phần mềm diệt vi-rút. Một số máy chủ từ chối mọi chương trình hoặc tệp nén, vì vậy hãy chia sẻ những tệp như vậy dưới dạng liên kết.
bounce-ip-blocklisted = Máy chủ thư của bạn nằm trong danh sách chặn
bounce-ip-blocklisted-why = Máy chủ nhận từ chối thư từ máy chủ đã gửi thư của bạn, vì địa chỉ của máy chủ đó nằm trong danh sách chặn.
bounce-ip-blocklisted-do = Vấn đề không nằm ở thư. Hãy chuyển tiếp thông báo này cho nhà cung cấp thư của bạn và đề nghị họ đưa máy chủ ra khỏi danh sách.
bounce-domain-blocklisted = Một tên miền nằm trong danh sách chặn
bounce-domain-blocklisted-why = Máy chủ nhận từ chối thư vì tên miền trong địa chỉ của bạn, hoặc một tên miền trong các liên kết của thư, nằm trong danh sách chặn.
bounce-domain-blocklisted-do = Nếu thư có liên kết, hãy thử gửi mà không có chúng. Nếu không, hãy chuyển tiếp thông báo này cho người quản lý thư của tên miền của bạn.
bounce-policy-blocked = Bị từ chối theo quy định của máy chủ nhận
bounce-policy-blocked-why = Quy định của máy chủ nhận không cho thư này đi qua, chẳng hạn vì kích cỡ, tệp đính kèm hoặc người gửi.
bounce-policy-blocked-do = Lời của chính máy chủ trong phần Chi tiết thường cho biết lý do. Hãy hỏi người nhận xem họ có thể nhận loại thư như vậy không.
bounce-geo-blocked = Bị từ chối vì nơi gửi
bounce-geo-blocked-why = Máy chủ nhận không nhận thư từ quốc gia hoặc mạng nơi đặt máy chủ thư của bạn.
bounce-geo-blocked-do = Hãy liên lạc với người đó bằng cách khác, hoặc hỏi nhà cung cấp thư của bạn.
bounce-relay-denied = Máy chủ không chuyển tiếp thư
bounce-relay-denied-why = Một máy chủ đã từ chối chuyển tiếp thư, thường vì thư được gửi mà không đăng nhập hoặc qua một máy chủ không phụ trách người nhận này.
bounce-relay-denied-do = Hãy kiểm tra máy chủ thư đi và thông tin đăng nhập trong thiết đặt của tài khoản.
bounce-auth-failure = Không thể xác minh địa chỉ người gửi của bạn
bounce-auth-failure-why = Máy chủ nhận không thể xác nhận thư thật sự đến từ tên miền của bạn (SPF, DKIM hoặc DMARC).
bounce-auth-failure-do = Hãy chuyển tiếp thông báo này cho người quản lý thư của tên miền của bạn: thiết đặt của tên miền cần được sửa. Trong lúc chờ, gửi qua máy chủ của chính nhà cung cấp có thể giúp ích.
bounce-rate-limited = Quá nhiều thư cùng lúc
bounce-rate-limited-why = Hiện tại máy chủ nhận chỉ nhận ít thư hơn từ máy chủ thư của bạn.
bounce-rate-limited-do = Hãy chờ một lúc rồi gửi lại. Khi viết cho nhiều người, hãy gửi cho ít người hơn mỗi lần.
bounce-greylisting = Tạm thời bị giữ lại
bounce-greylisting-why = Máy chủ nhận yêu cầu người gửi lạ thử lại sau một lúc, một cách kiểm tra thư rác phổ biến.
bounce-greylisting-do = Với sự chậm trễ tạm thời, máy chủ gửi thường sẽ tự thử lại. Nếu thông báo này cho biết thư đã thất bại hẳn, hãy thử gửi lại sau.
bounce-server-error = Máy chủ nhận gặp sự cố
bounce-server-error-why = Không thể kết nối với máy chủ nhận, hoặc máy chủ không thể nhận thư do sự cố của chính nó.
bounce-server-error-do = Hãy gửi lại sau. Nếu vẫn thất bại, hãy kiểm tra phần địa chỉ sau dấu @ xem có lỗi gõ không.
bounce-unknown = Không chuyển phát được
bounce-unknown-why = Thông báo không nói rõ lý do.
bounce-unknown-do = Lời của chính máy chủ trong phần Chi tiết có thể cho biết thêm. Nếu không giúp được, hãy chuyển tiếp thông báo này cho nhà cung cấp thư của bạn.

## Khi chọn nhiều thư

selection-title = Đã chọn { $count } thư
selection-unread = { $count } chưa đọc
selection-flagged = { $count } đã gắn cờ
delete-for-good-one = Thư này sẽ bị xóa vĩnh viễn. Xóa thư?
delete-for-good-all = { $count } thư này sẽ bị xóa vĩnh viễn. Xóa các thư?
delete-for-good-some = { $count } trong số { $total } thư sẽ bị xóa vĩnh viễn. Xóa các thư?
done-read = { $count ->
   *[other] Đã đánh dấu { $messages } là đã đọc
}
done-unread = { $count ->
   *[other] Đã đánh dấu { $messages } là chưa đọc
}
done-flagged = { $count ->
   *[other] Đã gắn cờ { $messages }
}
done-unflagged = Đã bỏ cờ { $messages }
done-deleted-for-good = { $count ->
   *[other] Đã xóa vĩnh viễn { $messages }
}
done-archived = { $count ->
   *[other] Đã lưu trữ { $messages }
}
done-moved = { $count ->
   *[other] Đã di chuyển { $messages } đến { $folder }
}
done-copied = { $count ->
   *[other] Đã sao chép { $messages } vào { $folder }
}
done-moving = { $count ->
   *[other] Đang di chuyển { $messages } đến { $folder }...
}
done-copying = { $count ->
   *[other] Đang sao chép { $messages } vào { $folder }...
}
done-moved-back = { $count ->
   *[other] Đã chuyển { $messages } trở lại { $folder }
}
# the status bar after Watch Conversation and Ignore Conversation, and after either again on a marked one
done-watched = { $count ->
    [1] Đang theo dõi cuộc hội thoại
   *[other] Đang theo dõi { $count } cuộc hội thoại
}
done-unwatched = { $count ->
    [1] Đã ngừng theo dõi cuộc hội thoại
   *[other] Đã ngừng theo dõi { $count } cuộc hội thoại
}
done-ignored = { $count ->
    [1] Đang bỏ qua cuộc hội thoại
   *[other] Đang bỏ qua { $count } cuộc hội thoại
}
done-unignored = { $count ->
    [1] Đã ngừng bỏ qua cuộc hội thoại
   *[other] Đã ngừng bỏ qua { $count } cuộc hội thoại
}
their-folders = thư mục ban đầu của chúng
undo-move = Hoàn tác di chuyển
undo-delete = Hoàn tác xóa
undo-archive = Hoàn tác lưu trữ
undo-junk = Hoàn tác đánh dấu là thư rác
undo-not-junk = Hoàn tác đánh dấu là không phải thư rác
undo-send = Hoàn tác gửi
nothing-to-undo = Không có gì để hoàn tác.
messages-gone = Các thư không còn ở đó nữa.
# A non-selectable IMAP folder cannot contain messages; this does not mean it is empty.
folder-holds-no-messages = Thư mục này không thể chứa thư.
not-archived-here = Không thể lưu trữ thư trong thư mục này.
not-emptied-here = Chỉ có thể làm trống Mục đã xóa và Email rác.
next-unread-question = Không còn thư chưa đọc nào trong { $folder }.

    Đi đến { $next }, thư mục tiếp theo có thư chưa đọc?
no-unread-left = Không còn thư chưa đọc nào.
empty-question = { $count ->
    [1] Làm trống { $folder }?

        Thư trong thư mục sẽ bị xóa vĩnh viễn. Không thể khôi phục thư.
   *[other] Làm trống { $folder }?

        { $messages } trong thư mục sẽ bị xóa vĩnh viễn. Không thể khôi phục các thư này.
}
no-junk-folder = Tài khoản này không có thư mục Email rác để chuyển thư vào.
no-inbox-folder = Tài khoản này không có thư mục Hộp thư đến để chuyển thư vào.
# the status bar after a flag in a colour: "Flagged 2 messages blue"
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

move-window-title-move = { $count ->
    [1] Di chuyển thư
   *[other] Di chuyển { $count } thư
}
move-window-title-copy = { $count ->
    [1] Sao chép thư
   *[other] Sao chép { $count } thư
}
move-window-prompt-move = { $count ->
    [1] Di chuyển thư đã chọn đến:
   *[other] Di chuyển { $count } thư đã chọn đến:
}
move-window-prompt-copy = { $count ->
    [1] Sao chép thư đã chọn vào:
   *[other] Sao chép { $count } thư đã chọn vào:
}
# the folders used last, over the folder tree
targets-recent = Gần đây
# the folder the messages are in, which can not be chosen
target-current = { $folder } (hiện tại)
# a folder used last, with its account when there are several: "Archive (Work)"
target-recent = { $folder } ({ $account })

## Di chuyển và sao chép sang tài khoản khác

transfer-moving = Đang di chuyển { $done } trong số { $messages } đến { $folder }...
transfer-copying = Đang sao chép { $done } trong số { $messages } vào { $folder }...
transfer-another-account = tài khoản khác
transfer-folder-gone = thư mục đích không còn nữa
transfer-not-on-server = thư không còn trên máy chủ
transfer-not-moved = { $count ->
   *[other] Không thể di chuyển { $messages } sang tài khoản khác: { $reason }
}
transfer-not-copied = { $count ->
   *[other] Không thể sao chép { $messages } sang tài khoản khác: { $reason }
}
transfer-none-moved = Không di chuyển được thư nào
transfer-none-copied = Không sao chép được thư nào

## Thư dưới dạng tệp

export-not-in-time = không thể tải thư xuống kịp thời
export-not-saved = Không thể lưu { $failed } trong số { $messages } ({ $problems })
export-not-attached = không thể đính kèm các thư: { $error }
# the status bar after Save As with several: "Saved 3 messages to Desktop"
saved-to = { $count ->
   *[other] Đã lưu { $messages } vào { $folder }
}
download-progress = Đang tải xuống { $done } trong số { $total }
download-done = Đã tải xuống { $size }
downloading-messages = { $count ->
   *[other] Đang tải xuống { $messages }...
}
# the status bar after files are dropped on a folder: "Put 3 messages in Archive"
import-put = { $count ->
   *[other] Đã xếp { $messages } vào hàng đợi để nhập vào { $folder }
}
import-not-put = Các mục sau chưa được đưa vào thư mục:

    { $problems }

## Các vấn đề mà cửa sổ hiển thị

error-store = kho cục bộ: { $error }
error-not-found = không tìm thấy
error-closed = đang tắt
error-other-account = trình duyệt đã đăng nhập vào { $email }, không phải tài khoản này
# a password or sign-in the mail server refused, with the server's words
failure-authentication = máy chủ không chấp nhận đăng nhập ({ $reason })
# the mail server could not be reached or the connection broke, with the reason
failure-network = kết nối với máy chủ thất bại ({ $reason })
error-in-use = không thể gỡ khi vẫn còn tài khoản đăng nhập bằng nó: { $accounts }
error-turned-off = ứng dụng đăng nhập này đã bị tắt cho tài khoản mới
error-folder-name = tên thư mục phải dài từ 1 đến 200 ký tự và không được chứa ký tự điều khiển
error-folder-separator = trên máy chủ này, tên thư mục không được chứa “{ $separator }”
error-folder-special = không thể đổi tên hoặc xóa Hộp thư đến và các thư mục đặc biệt
error-no-recipients = thư không có người nhận
error-bad-address = “{ $address }” không phải là địa chỉ email
error-not-own-address = { $address } không phải là một địa chỉ gửi của tài khoản này. Hãy thêm địa chỉ vào “Các địa chỉ khác bạn dùng để gửi” trong thuộc tính của tài khoản.
rule-query-refused = Quy tắc không thể lọc theo thư mục hoặc ngày ({ $words }).
rule-no-query = Hãy nhập tiêu chí tìm kiếm cho thư đến.
rule-no-action = Hãy chọn ít nhất một hành động cho quy tắc.
error-attachment = Không thể đọc { $path }: { $error }
error-no-drafts = tài khoản không có thư mục Thư nháp để lưu thư
error-draft-attachment = không thể giữ lại một tệp đính kèm của thư nháp: { $error }
error-password-not-saved = không thể lưu mật khẩu cho lần khởi động sau: { $error }
error-sign-in-not-saved = không thể lưu thông tin đăng nhập mới cho lần khởi động sau: { $error }
error-import-unreadable = Không thể đọc { $path }: { $error }
error-import-too-large = { $path } lớn hơn 50 MB
error-import-not-mail = { $path } không phải là thư email
error-list-answered = máy chủ danh sách gửi thư trả về trạng thái { $status }
error-not-built = không thể tạo thư
error-outbox-waits = { $count ->
    [1] thư vẫn còn trong Hộp thư đi; lần Gửi/Nhận tiếp theo sẽ thử gửi lại
   *[other] { $count } thư vẫn còn trong Hộp thư đi; lần Gửi/Nhận tiếp theo sẽ thử gửi lại
}
error-draft-not-removed = không thể xóa bản nháp trước của thư khỏi Thư nháp: { $reason }
error-sent-but = thư đã được gửi, nhưng { $problem }
error-sent-still-in-outbox = thư vẫn còn trong Hộp thư đi: { $error }
error-sent-no-copy = không thể lưu bản sao vào Mục đã gửi: { $reason }
error-no-password = tài khoản này chưa có mật khẩu
error-no-sign-in = tài khoản này chưa có thông tin đăng nhập
error-provider-missing = ứng dụng đăng nhập không có trong bản dựng này (ID: { $provider }). Có thể nó đã bị gỡ
error-provider-servers = máy chủ của tài khoản này không khớp với máy chủ của ứng dụng đăng nhập
error-app-scopes = { $reason }. Máy chủ thư không nhận mã thông báo của ứng dụng đăng nhập: hãy kiểm tra xem phạm vi của ứng dụng có cấp quyền truy cập thư không
error-in-folder = { $folder }: { $reason }

## Ứng dụng đăng nhập

sign-in-off-google = Ứng dụng đăng nhập Google có sẵn được thiết lập cho người dùng thử nghiệm đã được phê duyệt và mặc định bị tắt cho tài khoản mới. Người dùng thử nghiệm có thể bật nó trong Ứng dụng đăng nhập (Tệp > Tài khoản). Bạn cũng có thể dùng ứng dụng đăng nhập Google của riêng mình, hoặc mật khẩu ứng dụng nếu tài khoản của bạn hỗ trợ.
sign-in-off-other = Ứng dụng này đã bị tắt cho tài khoản mới. Bạn có thể bật nó trong Ứng dụng đăng nhập (Tệp > Tài khoản).
sign-in-app-no-name = ứng dụng đăng nhập cần có tên
sign-in-app-no-client = thiếu ID máy khách
sign-in-app-no-scopes = ứng dụng đăng nhập cần các phạm vi cấp quyền truy cập thư
sign-in-app-bad-host = địa chỉ máy chủ { $server } bị thiếu hoặc không phải là tên máy chủ hợp lệ
sign-in-app-plain = máy chủ { $server } phải dùng SSL/TLS hoặc STARTTLS
sign-in-app-not-checked = bên phát hành chưa được kiểm tra
sign-in-app-issuer-changed = bên phát hành đã thay đổi: hãy nhập lại bí mật máy khách hoặc gỡ nó
sign-in-register-google = Trong Google Cloud Console, hãy tạo một máy khách OAuth loại Desktop app, với phạm vi https://mail.google.com/ trên màn hình xin phép. Khi ứng dụng đang ở chế độ thử nghiệm, chỉ người dùng thử nghiệm của ứng dụng mới đăng nhập được.
sign-in-register-microsoft = Trong Microsoft Entra, hãy đăng ký một ứng dụng với nền tảng Mobile and desktop applications, URI chuyển hướng http://localhost, cho phép public client flows và các quyền ủy quyền IMAP.AccessAsUser.All, SMTP.Send và offline_access. Nếu chỉ dành cho tổ chức của bạn, hãy dùng https://login.microsoftonline.com/<tenant ID>/v2.0 làm bên phát hành.
sign-in-register-other = Hãy đăng ký một máy khách gốc (công khai) với URI chuyển hướng bên dưới; nhà cung cấp phải cho phép mọi cổng trên URI đó (RFC 8252). Thêm phạm vi mà nhà cung cấp dùng để cấp quyền truy cập thư.

## Lời mời lịch

repeats = Lặp lại
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
repeats-on = { $repeats } vào { $days }
# "Every week, 10 times"
repeats-times = { $count ->
    [1] { $repeats }, một lần
   *[other] { $repeats }, { $count } lần
}
day-monday = Thứ Hai
day-tuesday = Thứ Ba
day-wednesday = Thứ Tư
day-thursday = Thứ Năm
day-friday = Thứ Sáu
day-saturday = Thứ Bảy
day-sunday = Chủ Nhật

## Tác nhân AI

agent-level-read = Đọc thư: thư mục, danh sách thư, cuộc hội thoại, tìm kiếm, thư và tệp của thư, quy tắc thư của bạn và những người bạn viết thư cho
agent-level-organize = Sắp xếp thư: trạng thái đã đọc, cờ và màu cờ, thư rác, di chuyển, lưu trữ, tạo và đổi tên thư mục, theo dõi và bỏ qua cuộc hội thoại, xóa vào Mục đã xóa, và rời danh sách gửi thư sau khi bạn đồng ý
agent-level-drafts = Viết thư nháp để bạn gửi
agent-level-send = Gửi thư, mỗi thư chỉ sau khi bạn đồng ý
agent-connect-title = { $program } muốn dùng thư của bạn
agent-connect-detail = Một tác nhân AI đã yêu cầu làm việc với Inbox Classic. Hãy chọn những gì nó được làm và những tài khoản nó được xem; bạn có thể thay đổi sau trong Công cụ > Tác nhân AI.

    Tác nhân đọc thư do người khác viết, và một thư có thể tìm cách lừa chúng. Inbox Classic luôn hỏi bạn trước khi tác nhân gửi bất cứ thứ gì.
agent-reply-to = Trả lời “{ $subject }”
agent-reply-all-on = Trả lời tất cả về “{ $subject }”
agent-forward-of = Chuyển tiếp “{ $subject }”
agent-never-written-one = Bạn chưa từng viết thư cho { $address }.
agent-never-written-many = Bạn chưa từng viết thư cho { $count } địa chỉ trong số này.
agent-send-title = { $program } muốn gửi thư này
agent-send-detail = Hãy kiểm tra người nhận và nội dung thư. Sau khi bạn xác nhận, thư sẽ chờ { $seconds } giây trong Hộp thư đi, nơi bạn vẫn có thể xóa thư.
agent-change-title = Những gì { $program } được phép làm
agent-change-allowed = Thay đổi những gì tác nhân AI của chương trình này được phép làm với thư của bạn.
agent-change-refused = Bạn đã từ chối quyền truy cập của chương trình này. Hãy cho phép để các tác nhân của nó truy cập lại thư của bạn.
agent-log-taken-back = { $entry } (đã hoàn tác)
agent-files = Tệp: { $files }
agent-undo-refused = Không thể hoàn tác.
agent-undo-refused-why = Không thể hoàn tác: { $reason }.
agent-undo-impossible = thay đổi này không thể hoàn tác
agent-undo-not-in-folder = thư không còn trong thư mục đó
agent-undo-not-arrived = thư không (hoặc chưa) có trong thư mục đích
agent-undo-sent = thư không còn trong Hộp thư đi
agent-original-not-downloaded = thư gốc chưa được tải xuống. Hãy mở thư đó trước
agent-turned-away = Đã từ chối
agent-can-nothing = Không gì cả
agent-can-read = đọc
agent-can-organize = sắp xếp
agent-can-drafts = viết thư nháp
agent-can-send = gửi khi bạn đồng ý
# "Read, organize and write drafts"
agent-can-list = { $first } và { $last }
agent-accounts = { $count ->
    [0] không có tài khoản nào
   *[other] { $count } tài khoản
}
# "Read and organize; 1 account"
agent-access = { $can }; { $accounts }
agent-unreadable = Không thể đọc thư này.
agent-encrypted-original = Thư này đã được mã hóa: tác nhân không thể trả lời hay chuyển tiếp thư, vì nó không thể mã hóa.
agent-encrypted = Thư này đã được mã hóa. Tác nhân AI không thể đọc nội dung thư. Hãy mở thư trong Inbox Classic để tự đọc.
agent-too-many-changes = Quá nhiều thay đổi trong 30 ngày qua: tác nhân này đã thực hiện số thay đổi tối đa mà Inbox Classic lưu trong nhật ký cho một chương trình. Nó có thể thực hiện thêm khi các thay đổi cũ nhất đã quá 30 ngày.
agent-too-many-reads = Quá nhiều lượt đọc trong 30 ngày qua: tác nhân này đã đọc lượng tối đa mà Inbox Classic lưu trong nhật ký cho một chương trình. Nó có thể đọc thêm khi các lượt đọc cũ nhất đã quá 30 ngày.
list-encrypted = Thư đã mã hóa
agent-log-composed = Đã mở “{ $subject }” trong một thư mới để bạn hoàn tất
agent-log-refused = Bạn đã không gửi “{ $subject }”
agent-log-sent = Đã đưa “{ $subject }” vào Hộp thư đi để gửi cho { $to }
agent-log-draft = Đã lưu thư nháp “{ $subject }”
agent-log-draft-replaced = Đã thay thế thư nháp “{ $subject }”
agent-log-draft-discarded = Đã yêu cầu xóa thư nháp “{ $subject }”
agent-draft-note = { $program }, một tác nhân AI, đã viết thư nháp này. Hãy kiểm tra người nhận và nội dung trước khi gửi.
agent-log-read = Đã đánh dấu “{ $subject }” là đã đọc
agent-log-unread = Đã đánh dấu “{ $subject }” là chưa đọc
agent-log-flagged = Đã gắn cờ “{ $subject }”
agent-log-unflagged = Đã bỏ cờ “{ $subject }”
agent-log-deleted = Đã xóa “{ $subject }”
agent-log-moved = Đã di chuyển “{ $subject }” đến { $folder }
agent-log-junk = Đã đánh dấu “{ $subject }” là thư rác
agent-log-not-junk = Đã đánh dấu “{ $subject }” là không phải thư rác
agent-log-archived = Đã lưu trữ “{ $subject }”
agent-log-folder = Đã yêu cầu tạo thư mục “{ $name }”
# written at the user's yes, before the list is asked; a list that fails replaces it with agent-log-unsubscribe-failed
agent-log-unsubscribed = Bạn đã đồng ý hủy đăng ký danh sách của thư “{ $subject }”
agent-log-unsubscribe-failed = Không thể hủy đăng ký danh sách của thư “{ $subject }”: { $reason }
# "You did not unsubscribe from news@shop.example, deals@example.com": the lists' addresses, never their names
agent-log-unsubscribe-refused = Bạn đã không chấp thuận yêu cầu hủy đăng ký cho: { $senders }
agent-unsubscribe-title = { $count ->
    [1] { $program } muốn hủy đăng ký cho bạn khỏi một danh sách gửi thư
   *[other] { $program } muốn hủy đăng ký cho bạn khỏi { $count } danh sách gửi thư
}
agent-unsubscribe-detail = { $count ->
    [1] Inbox Classic đề nghị danh sách bên dưới ngừng gửi thư cho bạn, theo cách một lần bấm mà danh sách cung cấp. Không có gì khác được gửi đi, và các thư bạn đang có vẫn được giữ nguyên.
   *[other] Inbox Classic đề nghị từng danh sách bên dưới ngừng gửi thư cho bạn, theo cách một lần bấm mà danh sách đó cung cấp. Không có gì khác được gửi đi, và các thư bạn đang có vẫn được giữ nguyên.
}
agent-log-flag-color = Đã gắn cờ { $color ->
    [red] đỏ
    [orange] cam
    [yellow] vàng
    [green] xanh lá
    [blue] xanh lam
    [purple] tím
   *[gray] xám
} cho “{ $subject }”
agent-log-renamed = Đã yêu cầu đổi tên thư mục “{ $old }” thành “{ $name }”
agent-log-watched = Đã theo dõi cuộc hội thoại “{ $subject }”
agent-log-ignored = Đã bỏ qua cuộc hội thoại “{ $subject }”
agent-log-unmarked = Đã ngừng theo dõi hoặc bỏ qua cuộc hội thoại “{ $subject }”
# the reason one change can not be taken back (agent-undo-refused-why)
agent-undo-changed = thư đã bị thay đổi kể từ đó
# one change of many messages an agent made with a search (apply_to_search), a row of the log; { $query } is the search
agent-log-bulk-read = Đã đánh dấu { $count } thư là đã đọc (tìm kiếm: { $query })
agent-log-bulk-unread = Đã đánh dấu { $count } thư là chưa đọc (tìm kiếm: { $query })
agent-log-bulk-flagged = Đã gắn cờ { $count } thư (tìm kiếm: { $query })
agent-log-bulk-unflagged = Đã bỏ cờ { $count } thư (tìm kiếm: { $query })
agent-log-bulk-color = Đã gắn cờ { $color ->
    [red] đỏ
    [orange] cam
    [yellow] vàng
    [green] xanh lá
    [blue] xanh lam
    [purple] tím
   *[gray] xám
} cho { $count } thư (tìm kiếm: { $query })
agent-log-bulk-moved = Đã di chuyển { $count } thư đến { $folder } (tìm kiếm: { $query })
agent-log-bulk-archived = Đã lưu trữ { $count } thư (tìm kiếm: { $query })
agent-log-bulk-junk = Đã đánh dấu { $count } thư là thư rác (tìm kiếm: { $query })
agent-log-bulk-not-junk = Đã đánh dấu { $count } thư là không phải thư rác (tìm kiếm: { $query })
agent-log-bulk-deleted = Đã xóa { $count } thư (tìm kiếm: { $query })
# Undo Everything Since in the AI Agents window: how far back it reaches
agent-undo-span = { $span ->
    [quarter] Trong 15 phút qua
    [hour] Trong 1 giờ qua
    [hours] Trong 4 giờ qua
    [day] Trong 24 giờ qua
    [week] Trong 7 ngày qua
   *[all] Trong 30 ngày qua
}
# the question before it takes back what a program did in the span chosen
agent-undo-since-question = { $count ->
    [0] { $program } không có thay đổi nào trong khoảng thời gian này có thể hoàn tác.
    [1] Thử hoàn tác thay đổi đã ghi nhận của { $program } trong khoảng thời gian này?
   *[other] Thử hoàn tác { $count } thay đổi đã ghi nhận của { $program } trong khoảng thời gian này?
}
agent-undo-since-detail = Inbox Classic sẽ cố khôi phục thư mục, trạng thái đã đọc và cờ, đồng thời xóa các thư vẫn đang chờ trong Hộp thư đi. Những thay đổi không còn hoàn tác được sẽ bị bỏ qua. Một số thay đổi màu cờ về sau có thể bị ghi đè.
# what taking back did, then a line for each kind of message it left as it is
agent-undo-done = { $count ->
    [0] Không có gì được hoàn tác.
   *[other] Đã hoàn tác toàn bộ hoặc một phần { $count } thay đổi đã ghi nhận.
}
agent-undo-left-gone = { $count } thư không còn ở nơi mà thay đổi đã đặt chúng.
agent-undo-left-changed = { $count } thư đã bị thay đổi kể từ đó, bởi bạn hoặc trên máy chủ, nên được giữ nguyên.
agent-undo-left-sent = { $count } thư đã rời khỏi Hộp thư đi.
agent-undo-left-impossible = { $count } thay đổi không thể hoàn tác.
# the Send question of an agent's answer to a calendar invitation: what it answers, and when the event is
agent-invitation-reply = { $response ->
    [accept] Thư này chấp nhận lời mời “{ $summary }” ({ $when }).
    [tentative] Thư này tạm chấp nhận lời mời “{ $summary }” ({ $when }).
   *[decline] Thư này từ chối lời mời “{ $summary }” ({ $when }).
} Thư được gửi đến người tổ chức có tên trong lời mời. Phản hồi của bạn trên máy này sẽ thay đổi khi máy chủ thư chấp nhận thư. Điều này không xác nhận rằng lịch của người tổ chức đã nhận được phản hồi.
# the subject of an answer to an invitation, as calendar programs write it
invitation-reply-subject = { $response ->
    [accept] Đã chấp nhận: { $summary }
    [tentative] Tạm chấp nhận: { $summary }
   *[decline] Đã từ chối: { $summary }
}
# the text of an answer to an invitation; { $name } is the user's name, or address
invitation-reply-text = { $response ->
    [accept] { $name } đã chấp nhận lời mời này.
    [tentative] { $name } đã tạm chấp nhận lời mời này.
   *[decline] { $name } đã từ chối lời mời này.
}
# what a program read in an hour, a row of the log: "Read 14 messages and searched 3 times" (joined by agent-can-list)
agent-reads-messages = đã đọc { $count } thư
agent-reads-attachments = đã yêu cầu { $count } tệp đính kèm
agent-reads-searches = { $count ->
    [1] đã tìm kiếm một lần
   *[other] đã tìm kiếm { $count } lần
}
agent-reads-lists = { $count ->
    [1] đã xem danh sách thư một lần
   *[other] đã xem danh sách thư { $count } lần
}
# each read under that row
agent-read-message = Đã đọc “{ $subject }”
agent-read-conversation = Đã đọc cuộc hội thoại “{ $subject }” ({ $count } thư)
agent-read-attachment = Đã yêu cầu tệp đính kèm “{ $name }” của “{ $subject }”
agent-read-search = Đã tìm kiếm “{ $query }”: { $count } thư
agent-read-people = Đã tra cứu người theo tên hoặc địa chỉ: “{ $query }”
agent-read-list = Đã xem { $count } mục trong danh sách (phạm vi: { $folder })
agent-read-changes = Đã xem chi tiết của { $count } thư mới
# the programs started from a terminal app, which share one access: in the list of programs and the question when one connects
agent-terminal-programs-mac = Các chương trình được khởi chạy từ { $terminal }
agent-terminal-programs-windows = Các chương trình được khởi chạy từ cửa sổ dòng lệnh ({ $terminal })
agent-terminal-programs-linux = Các chương trình được khởi chạy từ cửa sổ dòng lệnh ({ $terminal })
# one of them, as the questions to send or unsubscribe name it: "A program started from Terminal wants to send this message"
agent-terminal-program-mac = Một chương trình được khởi chạy từ { $terminal }
agent-terminal-program-windows = Một chương trình được khởi chạy từ cửa sổ dòng lệnh ({ $terminal })
agent-terminal-program-linux = Một chương trình được khởi chạy từ cửa sổ dòng lệnh ({ $terminal })
agent-connect-title-terminal = { $programs } muốn dùng thư của bạn
agent-connect-terminal-detail = Các tác nhân AI được khởi chạy từ cùng một chương trình dòng lệnh đã nhận diện sẽ dùng chung quyền truy cập bạn cho phép ở đây. Để cấp quyền riêng cho một tác nhân, hãy thêm --name và một tên tùy ý vào đối số của nó trong thiết đặt MCP của tác nhân. Tên đó không xác minh danh tính của tác nhân.
# above the question when a program said it was another one than the system found: "It said it was Claude. Inbox Classic checked which program started it: python3."
agent-connect-claimed = Nó tự nhận là { $claimed }. Inbox Classic đã kiểm tra chương trình nào khởi chạy nó: { $program }.

## Tên phím theo bàn phím của ngôn ngữ, trong phần trợ giúp (Windows và Linux)

key-ctrl = Ctrl
key-alt = Alt
key-shift = Shift
key-del = Del
key-enter = Enter

## Đăng nhập và mật khẩu

sign-in-no-refresh = nhà cung cấp không cấp mã thông báo làm mới
sign-in-no-account = nhà cung cấp không cho biết tài khoản nào đã đăng nhập
sign-in-not-finished = quá trình đăng nhập chưa hoàn tất
secrets-unavailable = { $store } không khả dụng
secrets-unavailable-why = { $store } không khả dụng: { $error }
secrets-windows = Trình quản lý Thông tin xác thực
secrets-mac = chuỗi khóa
secrets-linux = vòng khóa của hệ thống (Secret Service)
error-no-such-file = không có tệp như vậy
cards-file-too-big = Tệp này vượt quá giới hạn kích cỡ để nhập sổ địa chỉ.
ui-sender-added = Đã thêm { $name } vào Sổ địa chỉ.
ui-sender-known = { $name } đã có trong Sổ địa chỉ.
ui-sender-none = Người gửi thư này không có địa chỉ email để thêm.
card-name-needed = Liên hệ không có tên và không có địa chỉ email.
# a file of Import Address Book that could not be read: "contacts.vcf: there is no such file"
cards-file-failed = { $file }: { $reason }

## Mã dùng một lần: thẻ ở đầu thư có mã đăng nhập hoặc mã xác minh

# the domain the code is for, which signed the message
otp-heading = Mã từ { $domain }
otp-copy = Sao chép
otp-note = Chỉ nhập mã trên một trang của { $domain }.
otp-old = Mã này được gửi hơn một giờ trước khi bạn mở thư, và có lẽ đã hết hạn.

# how many are invited, in the card of an event
event-attendees = { $count } người tham dự

# the first line of a new message's notification when it has a code, for a domain that signed it
otp-notification = { $code } là mã của bạn cho { $domain }

## Khóa OpenPGP (keys.rs)
pgp-key-valid = Hợp lệ
pgp-key-expires = Hợp lệ đến { $date }
pgp-key-expired = Đã hết hạn vào { $date }
pgp-key-revoked = Đã thu hồi
pgp-key-revoked-why = Đã thu hồi: { $reason }
pgp-key-not-valid = Không hợp lệ
pgp-key-locked = Không thể dùng: khóa bảo vệ của nó không khả dụng trong { $store }. Hãy kiểm tra xem kho đó có khả dụng và đã được mở khóa chưa. Nếu khóa bảo vệ bị mất, hãy nhập bản sao lưu khóa riêng tư.
pgp-source-own = Tạo trong Inbox Classic
pgp-source-file = Nhập từ tệp
pgp-source-paste = Đã dán
pgp-source-attachment = Từ một thư
pgp-source-vcard = Từ một thẻ liên hệ
pgp-source-wkd = Từ nhà cung cấp thư của người gửi
pgp-source-keyserver = Từ keys.openpgp.org
pgp-source-autocrypt = Từ tiêu đề Autocrypt của một thư
pgp-error-no-store = Khóa bảo vệ các khóa riêng tư của bạn được giữ trong { $store }, nhưng kho này hiện không khả dụng: { $error }
pgp-error-wrong-passphrase = Cụm mật khẩu không đúng.
pgp-error-not-a-key = Đây không phải là khóa OpenPGP.
pgp-error-too-large = Khóa quá lớn.
pgp-error-unusable = Không thể dùng khóa này. Có thể nó thiếu khóa ký hoặc khóa mã hóa phù hợp, hoặc dùng thuật toán mật mã không được hỗ trợ.
pgp-imported-private = { $count ->
    [1] Đã nhập khóa riêng tư của bạn.
   *[other] Đã nhập { $count } khóa riêng tư.
}
pgp-imported-public = { $count ->
    [1] Đã nhập một khóa.
   *[other] Đã nhập { $count } khóa.
}
pgp-imported-pending = Một khóa khác đang được dùng cho { $addresses }: khóa mới sẽ chờ trong liên hệ cho đến khi bạn chọn nó.
pgp-error-needs-passphrase = Khóa riêng tư được bảo vệ bằng cụm mật khẩu. Hãy nhập cụm mật khẩu để nhập khóa.
pgp-error-mismatch = Khóa riêng tư không tương ứng với khóa công khai. Có thể khóa đã bị sửa đổi.
pgp-file-name-public = Khóa công khai { $who }.asc
pgp-file-name-private = Bản sao lưu khóa riêng tư { $who }.asc
pgp-pending = Đã tìm thấy một khóa khác cho { $address } vào { $date }.

## Đọc thư đã ký và đã mã hóa (protect.rs)
pgp-part-verified = Được ký bởi { $signer }, khóa đã xác minh
pgp-part-signed = Được ký bởi { $signer } (khóa chưa xác minh)
pgp-part-other = Được ký bởi { $signer }, không phải người gửi
pgp-part-unknown-key = Đã ký, nhưng không rõ khóa
pgp-part-not-signed = Không có chữ ký
pgp-part-not-checked = Chưa kiểm tra chữ ký
pgp-part-encrypted = Đã mã hóa. { $signature }
pgp-part-no-key = Được mã hóa bằng một khóa bạn không có
pgp-part-changed = Phần được mã hóa không qua được kiểm tra tính toàn vẹn và không được hiển thị
pgp-part-unprotected = Được mã hóa mà không có bảo vệ chống sửa đổi, không được hiển thị
pgp-part-broken = Không thể đọc phần được mã hóa
pgp-why-mismatch = Chữ ký không khớp với văn bản này
pgp-why-weak-hash = Chữ ký dùng { $hash }, thuật toán không còn an toàn
pgp-why-key-expired = Được ký sau khi khóa hết hạn vào { $date }
pgp-why-key-revoked = Được ký bằng một khóa đã bị thu hồi
pgp-why-not-signing-key = Được ký bằng một khóa không được phép ký
pgp-why-from-future = Chữ ký mang ngày trong tương lai
pgp-why-signature-expired = Chữ ký đã hết hạn
pgp-why-key-not-valid = Được ký bằng một khóa không hợp lệ
pgp-why-not-for-you = Được ký cho người nhận khác, rồi được chuyển cho bạn
pgp-why-not-key-in-use = Được ký bằng một khóa khác với khóa đang dùng cho { $address }
pgp-part-pictures-loaded = { $label }. Ảnh đã được tải từ internet
pgp-error-no-own-key = Bạn không có khóa cho { $address } để ký hoặc mã hóa. Hãy tạo một khóa trong Công cụ > Khóa mã hóa, hoặc tắt Ký và Mã hóa.
pgp-error-missing-keys = { $count ->
    [1] Không có khóa mã hóa dùng được cho người nhận này: { $addresses }.
   *[other] Không có khóa mã hóa dùng được cho những người nhận này: { $addresses }.
}
pgp-error-encrypted-quote = Thư này chứa văn bản, ảnh hoặc tệp đính kèm từ thư đã mã hóa nên chỉ có thể gửi ở dạng mã hóa. Hãy bật Mã hóa, hoặc gỡ toàn bộ nội dung đó.
pgp-error-protect = Không thể ký hoặc mã hóa thư: { $reason }
pgp-found-keys = Đã tìm thấy khóa cho: { $addresses }.
pgp-found-none = Không tìm thấy khóa nào cho { $addresses }. Hãy đề nghị họ gửi khóa công khai cho bạn.
pgp-found-no-key = Không tìm thấy khóa nào.
pgp-find-unavailable = Hiện không thể tra cứu khóa: { $error }
pgp-publish-pending = keys.openpgp.org đã gửi liên kết xác nhận đến các địa chỉ này: { $addresses }. Hãy xác nhận từng địa chỉ để người khác có thể tìm khóa của bạn bằng địa chỉ đó.
pgp-publish-done = Khóa của bạn đã được công bố trên keys.openpgp.org cho { $addresses }.
pgp-publish-failed = Không thể công bố khóa: { $error }
pgp-keyserver-off = Việc tra cứu khóa trên keys.openpgp.org đã bị tắt trong { $settings }.
# the compose window with Sign and Encrypt: the line under the fields, each recipient's key, the questions
pgp-compose-encrypted = { $count ->
    [1] Sẽ được mã hóa và ký cho bạn và { $addresses }.
   *[other] Sẽ được mã hóa và ký cho bạn và { $count } người nhận của thư.
}
pgp-compose-encrypt-ready = Thư sẽ được mã hóa và ký. Hãy thêm người nhận mà bạn có khóa của họ.
pgp-compose-missing = { $count ->
    [1] Không có khóa dùng được cho { $addresses }, nên chưa thể mã hóa thư.
   *[other] { $count } người nhận không có khóa dùng được, nên chưa thể mã hóa thư: { $addresses }.
}
pgp-compose-looking = Đang tìm khóa của { $addresses }...
pgp-compose-signed = Sẽ được ký: người nhận có thể kiểm tra nội dung đã ký không bị thay đổi. Họ cũng phải xác minh ai là chủ sở hữu khóa của bạn.
pgp-compose-reply-clear = Không được mã hóa, dù thư mà nó trả lời hoặc chuyển tiếp đã được mã hóa.
pgp-compose-encrypted-files = Tệp của một thư đã mã hóa đang được đính kèm, nên thư này chỉ có thể gửi ở dạng mã hóa. Hãy bật Mã hóa, hoặc gỡ các tệp đó.
pgp-compose-sign-tip = Ký thư để người nhận có thể kiểm tra xem nội dung có bị thay đổi hay không. Họ cũng phải xác minh ai là chủ sở hữu khóa của bạn
pgp-compose-sign-tip-encrypted = Thư đã mã hóa luôn được ký
pgp-compose-encrypt-tip = Mã hóa thư, để chỉ bạn và người nhận mới đọc được
pgp-compose-make-key = Bạn chưa có khóa cho { $address }. Tạo khóa ngay? Với khóa này, thư của bạn có thể được ký và mã hóa.
pgp-compose-key-unusable = Không thể dùng khóa của bạn cho { $address }. Lý do: { $state }

    Hãy mở Khóa mã hóa để nhập bản sao lưu của khóa hoặc tạo khóa mới.
pgp-compose-encrypt-off-quote = Thư này chứa văn bản, ảnh hoặc tệp đính kèm từ thư đã mã hóa. Khi không mã hóa, thư không thể được gửi cho đến khi bạn gỡ toàn bộ nội dung đó. Vẫn tắt mã hóa?
pgp-compose-encrypt-off-reply = Thư này trả lời hoặc chuyển tiếp một thư đã mã hóa. Khi không mã hóa, bất kỳ ai xử lý thư của bạn trên đường đi đều có thể đọc được. Tắt mã hóa?
pgp-recipient-verified = Khóa đã xác minh
pgp-recipient-found = Khóa chưa xác minh
pgp-recipient-own = Khóa của chính bạn
pgp-recipient-looking = Đang tìm khóa...
pgp-recipient-missing = Không có khóa
pgp-recipient-not-found = Không có khóa: không tìm thấy khóa nào vào { $date }
pgp-recipient-unusable = Không thể dùng khóa: { $state }
pgp-recipients-intro = Thư được mã hóa bằng khóa của từng người nhận và bằng khóa của bạn.
pgp-recipients-intro-missing = { $count ->
    [1] Một người nhận không có khóa mã hóa dùng được. Hãy tìm khóa hoặc gỡ người nhận đó. Chỉ có thể gửi không mã hóa sau khi đã gỡ mọi nội dung từ thư đã mã hóa.
   *[other] { $count } người nhận không có khóa mã hóa dùng được. Hãy tìm khóa của họ hoặc gỡ những người nhận đó. Chỉ có thể gửi không mã hóa sau khi đã gỡ mọi nội dung từ thư đã mã hóa.
}
pgp-details-part = Phần { $number }: { $label }
attachment-from-part = Từ phần { $number }: { $label }
pgp-details-signed = Được ký { $when } bằng khóa { $key }
pgp-details-unknown-key = Được ký bằng khóa { $key }, khóa mà bạn không có
pgp-details-opened = Đã giải mã bằng khóa { $key } của bạn
pgp-details-for = Được mã hóa bằng khóa: { $keys }
pgp-details-plain = Không được ký và không được mã hóa
pgp-bar-parts = Thư này có { $count } phần: { $list }. Mỗi phần cho biết cách nó được bảo vệ.
pgp-bar-count-verified = { $count } đã xác minh
pgp-bar-count-encrypted-signed = { $count } đã mã hóa và ký
pgp-bar-count-encrypted = { $count } đã mã hóa
pgp-bar-count-signed = { $count } đã ký
pgp-bar-count-warning = { $count } cần chú ý
pgp-bar-count-neutral = { $count } không có chữ ký được xác nhận
# the setup file: settings, accounts, contacts and keys carried to another computer
setup-part-settings = Cài đặt
setup-part-preferences = Tùy chọn cửa sổ
setup-part-accounts = Tài khoản
setup-part-sign-in-apps = Ứng dụng đăng nhập
setup-part-contacts = Liên hệ và nhóm
setup-part-keys = Khóa mã hóa
setup-part-rules = Quy tắc thư
setup-part-trusted-senders = Người gửi tin cậy
setup-holds-settings = { $count } cài đặt
setup-holds-preferences = { $count } tùy chọn
setup-holds-accounts = { $count } tài khoản
setup-holds-sign-in-apps = { $count } ứng dụng đăng nhập
setup-holds-built-in = Những ứng dụng đăng nhập có sẵn nào được bật
setup-holds-contacts = { $count } liên hệ
setup-holds-groups = { $count } nhóm
setup-holds-own-keys = { $count } khóa của bạn
setup-holds-contact-keys = { $count } khóa của liên hệ
setup-holds-rules = { $count } quy tắc
setup-holds-trusted-senders = { $count } người gửi tin cậy
setup-sign-in-password = Mật khẩu
setup-account-secret-password = Mật khẩu của tài khoản có trong tệp.
setup-account-secret-token = Thông tin đăng nhập đã lưu của tài khoản có trong tệp.
setup-account-asks-password = Tài khoản sẽ hỏi mật khẩu sau khi nhập.
setup-account-signs-in-again = Bạn sẽ đăng nhập lại vào tài khoản sau khi nhập.
setup-account-here = Tài khoản đã được thiết lập ở đây, nên sẽ bị bỏ qua.
setup-account-no-app = Tài khoản đăng nhập bằng { $app }, ứng dụng chưa được thiết lập ở đây. Hãy nhập cả các ứng dụng đăng nhập.
setup-invalid-address = “{ $address }” không phải là địa chỉ email.
setup-invalid-server = Thiết đặt { $server } có tên máy chủ, cổng hoặc tùy chọn bảo mật không hợp lệ.
setup-invalid-user = Tài khoản không có tên người dùng.
setup-invalid-sign-in = Phương thức hoặc cấu hình đăng nhập của tài khoản không được hỗ trợ.
setup-error-empty = Tệp trống.
setup-error-too-large = Tệp thiết lập vượt quá giới hạn kích cỡ.
setup-error-not-setup = Tệp này không phải là tệp thiết lập của Inbox Classic.
setup-error-damaged = Tệp thiết lập bị hỏng và không thể đọc.
setup-error-newer = Tệp thiết lập này được lưu bởi một phiên bản Inbox Classic mới hơn ({ $version }). Hãy cập nhật Inbox Classic, rồi nhập lại.
setup-error-needs-passphrase = Tệp thiết lập này được bảo vệ bằng cụm mật khẩu. Hãy nhập cụm mật khẩu đã dùng khi lưu.
setup-error-wrong-passphrase = Đó không phải là cụm mật khẩu đã dùng khi lưu tệp thiết lập này.
setup-error-changed = Tệp thiết lập không qua được kiểm tra tính toàn vẹn. Có thể tệp đã bị sửa đổi hoặc bị hỏng nên không thể nhập.
setup-error-read = Không thể đọc tệp thiết lập: { $error }
setup-error-write = Không thể lưu tệp thiết lập: { $error }
setup-error-no-parts = Hãy chọn ít nhất một phần.
setup-left-out = { $count } mục của { $part } không dùng được và bị bỏ qua.
setup-imported-settings = Đã thay thế cài đặt.
setup-imported-preferences = Đã thay thế tùy chọn cửa sổ.
setup-added-accounts = Đã thêm { $count } tài khoản.
setup-skipped-here = { $address } đã được thiết lập ở đây, nên đã bị bỏ qua.
setup-skipped-no-app = Đã bỏ qua { $address }: tài khoản đăng nhập bằng { $app }, ứng dụng chưa được thiết lập ở đây.
setup-skipped-invalid = Đã bỏ qua { $address }: { $reason }
setup-asks-password = { $address } sẽ hỏi mật khẩu khi kết nối.
setup-signs-in-again = { $address } sẽ yêu cầu bạn đăng nhập lại khi kết nối.
setup-added-sign-in-apps = Đã thêm { $count } ứng dụng đăng nhập.
setup-skipped-sign-in-apps = { $count } ứng dụng đăng nhập đã được thiết lập ở đây.
setup-added-contacts = Đã thêm { $count } liên hệ vào sổ địa chỉ.
setup-skipped-contacts = { $count } liên hệ đã có trong sổ địa chỉ.
setup-added-groups = Đã thêm hoặc bổ sung { $count } nhóm.
setup-added-own-keys = Đã thêm { $count } khóa của bạn.
setup-added-contact-keys = Đã thêm { $count } khóa của liên hệ.
setup-added-rules = Đã thêm { $count } quy tắc thư.
setup-skipped-rules = { $count } quy tắc thư đã có ở đây.
setup-skipped-rules-account = { $count } quy tắc thư dành cho tài khoản không có ở đây, nên đã bị bỏ qua.
setup-rules-waiting = { $count } quy tắc thư đang chờ tìm thấy thư mục đích trong lúc đồng bộ tài khoản.
setup-added-trusted-senders = Đã thêm { $count } người gửi tin cậy.
setup-nothing = Không có gì được nhập.
setup-account-servers = { $imap } và { $smtp } ({ $signin })
setup-file-name = Cài đặt và tài khoản Inbox Classic
setup-skipped-unreachable = Đã bỏ qua { $name }: không thể kết nối hoặc kiểm tra dịch vụ đăng nhập của nó. Hãy kiểm tra ứng dụng cần thiết trong Ứng dụng đăng nhập trước khi thử lại.
attachment-runs-programs = “{ $name }” có thể chạy chương trình, nên Inbox Classic không mở tệp này. Hãy lưu tệp, rồi tự mở nếu bạn tin tưởng nguồn gốc của nó.
attachment-decrypted-note = Tệp đính kèm này đến từ thư đã mã hóa. Để mở tệp trong ứng dụng khác, Inbox Classic lưu một bản sao không mã hóa vào một thư mục tạm của tài khoản người dùng của bạn. Khi khởi động, ứng dụng sẽ cố xóa các bản sao cũ hơn một ngày.
# a bar over the list when the server did not do what the user asked of messages, so they are as they were again
undone-move = { $count ->
   *[other] Máy chủ không di chuyển { $messages } đến { $folder }, nên thư đã trở lại { $from }: { $reason }
}
undone-delete = { $count ->
   *[other] Máy chủ không xóa { $messages }, nên thư đã trở lại { $from }: { $reason }
}
undone-archive = { $count ->
   *[other] Máy chủ không lưu trữ { $messages }, nên thư đã trở lại { $from }: { $reason }
}
undone-read = { $count ->
   *[other] Máy chủ không đánh dấu { $messages } là đã đọc, nên thư lại là chưa đọc: { $reason }
}
undone-unread = { $count ->
   *[other] Máy chủ không đánh dấu { $messages } là chưa đọc, nên thư lại là đã đọc: { $reason }
}
undone-flags = { $count ->
   *[other] Máy chủ không thay đổi cờ của { $messages }, nên thư vẫn như cũ: { $reason }
}

## Xem trước tệp đính kèm: ảnh và tệp PDF được hiển thị trong thư

# the reading option that turns PDF previews on and off (the apps show it)
preview-pdf-option = Hiển thị tệp PDF trong thư
# the tile of a PDF file while PDF previews are off
preview-pdf-off = Tệp PDF không được hiển thị trong thư.
# the note where previews are, after the app ended while it was drawing a file of a message: { $option } is the option's name
preview-pdf-off-crashed = Inbox Classic đã đóng khi đang hiển thị một tệp trong thư, nên tệp PDF không còn được hiển thị trong thư. Ảnh vẫn được hiển thị. Để hiển thị lại tệp PDF, hãy bật { $option } trong { $settings }.
# under the pages of a PDF file shown in a message: its page count and size ("3 pages, 84 KB")
preview-pdf-details = { $count } trang, { $size }
# what a screen reader says of a page of a PDF file shown in a message
preview-page-alt = { $name }, trang { $page } trên { $count }
# the link under the pages of a PDF file shown in a message, when it has more pages than are shown
preview-more-pages = { $count ->
    [1] Mở để xem trang này
   *[other] Mở để xem cả { $count } trang
}
# after the files shown in a message, when it has more pictures and PDF files than are shown; the list is the
# strip of files over the message
preview-more-files = Còn { $count } tệp khác trong danh sách phía trên
# the tile of a picture or PDF file of a message still downloading (the ellipsis as in reader-downloading)
preview-tile-downloading = Đang tải xuống…
# the tile of a picture or PDF file whose size was not read in time when the message was shown: its preview
# comes in its place in a moment (the ellipsis as in reader-downloading)
preview-tile-preparing = Đang chuẩn bị…
# the tile of a picture in a format not shown yet: { $format } is its name (HEIC, AVIF, JPEG XL)
preview-tile-format = Chưa hỗ trợ hiển thị ảnh { $format }
# the tile of a PDF file that wants a password to open
preview-tile-password = Được bảo vệ bằng mật khẩu: hãy mở tệp để nhập mật khẩu
# the tile of a picture or PDF file over the size or pixel limit
preview-tile-too-large = Quá lớn để hiển thị
# the tile of a file that is broken, or not what its name says
preview-tile-unreadable = Không thể hiển thị
# the tile of a file that took too long to draw
preview-tile-timed-out = Việc chuẩn bị bản xem trước mất quá nhiều thời gian
# the tile of a file that closed the app once while it was drawn: never drawn again
preview-tile-crashed = Không có bản xem trước: lần thử trước đã bị gián đoạn
# the tile of a file while previews are paused after a file took too long, until the app starts again
preview-tile-off = Không hiển thị cho đến khi Inbox Classic khởi động lại
# in a printout, for a file shown in the message that is not printed (a PDF file, a tile): { $details } is its size,
# or a PDF file's pages and size
preview-not-printed = { $name } ({ $details }) không được in. Hãy mở tệp để in.

pgp-error-attached-private = Tệp đính kèm này chứa khóa riêng tư. Chỉ có thể nhập khóa công khai trực tiếp từ thư. Để khôi phục khóa riêng tư của chính bạn, hãy lưu tệp đính kèm rồi nhập tệp đó trong Khóa mã hóa.
pgp-part-find-key = Tìm khóa
