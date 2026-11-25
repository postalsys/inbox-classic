# Bản nháp tiếng Việt, đang chờ người bản ngữ duyệt.
# Chữ của các cửa sổ, giống nhau trên mọi nền tảng. Dấu & đánh dấu chữ cái của mục menu mà Alt và chữ cái đó chọn
# trên Windows và Linux (&& là dấu và); máy Mac bỏ qua nó. Đặt nó trên một chữ cái của từ, ưu tiên chữ không dấu,
# khác nhau cho mỗi mục trong cùng một menu.

## Các menu

menu-file = &Tệp
menu-edit = &Chỉnh sửa
menu-view = &Xem
menu-tools = Cô&ng cụ
menu-message = T&hư
menu-help = Trợ &giúp
menu-layout = &Bố trí
menu-sort-by = &Sắp xếp theo
menu-text-size = &Cỡ chữ
menu-folder = Thư mụ&c
menu-insert = C&hèn

## Lệnh của các menu, thanh công cụ và khay hệ thống (core/commands.toml)

cmd-new-account = Tài khoản &mới...
cmd-exit = Th&oát
cmd-sync = &Gửi và nhận tất cả
cmd-mark-read = Đánh &dấu là đã đọc
cmd-mark-unread = Đánh dấ&u là chưa đọc
cmd-pictures = &Tải xuống ảnh
cmd-about = &Giới thiệu về Inbox Classic
cmd-new-mail = Thư &mới
cmd-reply = T&rả lời người gửi
cmd-reply-all = Trả lời &tất cả
cmd-forward = Chuyển tiế&p
cmd-help = &Mục lục
cmd-delete = &Xóa thư
cmd-move = Di chu&yển đến thư mục...
cmd-flag = &Gắn cờ thư
cmd-new-folder = Thư mục &mới...
cmd-rename-folder = Đổi tê&n thư mục...
cmd-delete-folder = &Xóa thư mục
cmd-empty-folder = Làm &trống thư mục
ui-empty-button = Làm trống
cmd-accounts = &Tài khoản...
cmd-find = Tì&m thư
cmd-save-as = &Lưu dưới dạng...
cmd-print = &In...
# review: new
cmd-print-conversation = In &cuộc hội thoại...
cmd-import = &Nhập thư...
cmd-outbox = &Hộp thư đi...
cmd-properties = T&huộc tính
cmd-mark-all-read = Đánh dấu t&oàn bộ thư là đã đọc
cmd-junk = Đá&nh dấu là thư rác
cmd-not-junk = Đánh dấu là &không phải thư rác
cmd-archive = &Lưu trữ
cmd-watch-conversation = The&o dõi cuộc hội thoại
cmd-ignore-conversation = &Bỏ qua cuộc hội thoại
cmd-next-message = Thư tiế&p theo
cmd-previous-message = Thư t&rước
cmd-next-unread = Thư chư&a đọc tiếp theo
cmd-go-to-folder = Đi đến thư &mục...
cmd-find-in-message = Tìm trong thư &này...
ui-go-to-prompt = Đi đến thư mục:
ui-find-in-message-hint = Tìm trong thư này
ui-find-not-found = Không có “{ $words }” trong thư này
cmd-expand-all-threads = Mở rộn&g tất cả cuộc hội thoại
cmd-collapse-all-threads = T&hu gọn tất cả cuộc hội thoại
ui-group-by-conversation = &Nhóm thư theo cuộc hội thoại
# review: new
ui-show-whole-conversation = Hiện toàn bộ &cuộc hội thoại trong ngăn đọc
# review: new
ui-show-whole-conversation-note = Hàng của một cuộc hội thoại mở tất cả các thư của nó, kèm các thư trả lời và thư nháp của bạn cùng các thư đã lưu vào thư mục khác. Thư đã đọc được thu gọn thành một dòng: bấm vào dòng để mở hoặc thu gọn thư.
# review: new
ui-conversation-order = Thứ tự &sắp xếp cuộc hội thoại:
# review: new
ui-conversation-oldest-first = Cũ nhất trước
# review: new
ui-conversation-newest-first = Mới nhất trước
# review: new
ui-thread-count = { $new ->
    [0] ({ $count })
   *[other] ({ $count }, { $new } mới)
}
# review: new
ui-conversation-to = đến { $people }
# review: new
ui-conversation-draft = Thư nháp
# review: new
ui-conversation-alone = Đã ký hoặc mã hóa: mở riêng
# review: new
ui-conversation-downloading = Đang tải xuống…
# review: new
ui-conversation-earlier = { $count ->
    [1] Hiện 1 thư trước đó
   *[other] Hiện { $count } thư trước đó
}
# review: new
ui-conversation-elsewhere = { $count ->
    [1] Cuộc hội thoại này còn có 1 thư trong thư mục khác.
   *[other] Cuộc hội thoại này còn có { $count } thư trong các thư mục khác.
}
# review: new
ui-conversation-this-folder = Chỉ thư mục &này
# review: new
ui-conversation-whole = Toàn bộ &cuộc hội thoại
cmd-folder-list = &Danh sách thư mục
cmd-layout-automatic = &Tự động
cmd-layout-classic = &Cổ điển
cmd-layout-columns = &Dạng cột
cmd-sort-date = &Ngày
cmd-sort-from = &Từ
cmd-sort-subject = &Chủ đề
cmd-sort-size = &Kích cỡ
cmd-sort-ascending = &Sắp xếp tăng dần
cmd-sort-descending = Sắp xếp &giảm dần
cmd-text-size-largest = &Lớn nhất
cmd-text-size-larger = Lớn &hơn
cmd-text-size-medium = Trung &bình
cmd-text-size-smaller = &Nhỏ hơn
cmd-text-size-smallest = Nhỏ nhấ&t
cmd-hide-ignored = Ẩn cuộc hội thoại đã bỏ &qua
cmd-hide-read = Ẩ&n thư đã đọc
cmd-notify = Thông &báo thư mới
cmd-open = &Mở Inbox Classic
cmd-default-app = Đặt làm ứng dụng thư &mặc định...
cmd-view-source = Ng&uồn thư
cmd-ai-agents = Tác nhân &AI...
cmd-options = Tùy &chọn...
cmd-message-rules = &Quy tắc thư...
cmd-encryption-keys = &Khóa mã hóa...
cmd-create-rule-from-message = Tạo &quy tắc từ thư...
cmd-unsubscribe = &Hủy đăng ký danh sách...
cmd-select-all = Chọn tất &cả
cmd-undo = &Hoàn tác
cmd-copy = &Sao chép vào thư mục...
cmd-address-book = &Sổ địa chỉ...
cmd-add-sender-to-book = Thêm người gửi &vào Sổ địa chỉ
cmd-import-address-book = Nhập &Sổ địa chỉ...
cmd-export-address-book = &Xuất Sổ địa chỉ...
cmd-export-setup = X&uất cài đặt và tài khoản...
cmd-import-setup = Nhập cài đặt và tài &khoản...
cmd-compose-sign = &Ký điện tử
cmd-compose-encrypt = &Mã hóa
cmd-attach-my-key = Đính kèm khóa &công khai của tôi

## Menu của biểu tượng trên khay hệ thống

tray-check = &Kiểm tra thư mới
tray-no-accounts = Chưa có tài khoản nào

## Chữ mà cửa sổ của nhiều nền tảng dùng chung

ui-tb-create-mail = Tạo thư
ui-tb-reply = Trả lời
ui-tb-reply-all = Trả lời tất cả
ui-tb-forward = Chuyển tiếp
ui-tb-print = In
ui-tb-delete = Xóa
ui-tb-junk = Thư rác
ui-tb-not-junk = Không phải rác
ui-tb-archive = Lưu trữ
ui-tb-previous = Trước
ui-tb-next = Tiếp
ui-previous-tip = Thư trước
ui-next-tip = Thư tiếp theo
ui-tb-sync = Gửi/Nhận
ui-tb-mark-read = Đã đọc
ui-tb-mark-unread = Chưa đọc
ui-still-running = Inbox Classic vẫn đang chạy
ui-no-subject = (không có chủ đề)
ui-quoted = “{ $subject }”
ui-newest-from = Thư mới nhất từ { $sender }: { $subject }
ui-new-messages = { $count } thư mới
ui-outbox-waiting = { $count } thư trong Hộp thư đi
ui-outbox-waits = { $subject } đang chờ trong Hộp thư đi
ui-outbox-sending = Đang gửi { $subject }...
ui-from-account = Từ { $account }
ui-sign-in-refused = Đăng nhập vào { $account } bị từ chối hoặc phiên đã hết hạn.
ui-sign-in-again-ask = Đăng nhập lại trong trình duyệt?
ui-sign-in-again-failed = Không thể đăng nhập lại: { $reason }
ui-unknown-reason = lý do không xác định
ui-checking = Đang kiểm tra thư mới trên { $account }...
ui-done = Xong
ui-sent-at = Đã gửi { $subject } lúc { $time }
ui-draft-saved = Đã lưu thư vào Thư nháp
ui-draft-not-saved = Thư chưa được lưu vào Thư nháp: { $reason }
ui-about-core = Lõi { $version }
ui-add-account-first = Hãy thêm một tài khoản thư trước.
ui-add-account-first-link = Hãy thêm một tài khoản thư trước, rồi bấm lại vào liên kết email.
ui-default-app-is = Inbox Classic là ứng dụng thư mặc định của bạn: liên kết email sẽ mở một thư mới tại đây.
ui-select-message-first = Hãy chọn một thư trước.
ui-store-not-opened = Không thể mở kho thư.
ui-store-or-cert-not-opened = Không thể mở kho thư hoặc tệp chứng chỉ.
ui-help-title = Trợ giúp Inbox Classic
ui-help-missing = Bản Inbox Classic này không có phần trợ giúp.
ui-ok = OK
ui-cancel = Hủy
ui-close = Đóng
ui-col-subject = Chủ đề
ui-col-from = Từ
ui-col-to = Đến
ui-col-received = Đã nhận
# the column of the glasses of a watched conversation (and the sign of an ignored one)
# a notification of new mail in a watched conversation, over who it is from
ui-watched-conversation = Cuộc hội thoại đang theo dõi
ui-col-sent = Đã gửi
ui-col-size = Kích cỡ
ui-col-folder = Thư mục
ui-col-account = Tài khoản
ui-col-queued = Xếp hàng lúc
ui-col-status = Trạng thái
ui-outbox-title = Hộp thư đi
ui-outbox-status-waiting = Đang chờ
ui-outbox-status-not-sent = Chưa gửi: { $reason }
# This message is still queued, during the grace period before an agent’s send.
ui-outbox-status-agent = Do tác nhân AI đưa vào hàng đợi; dự kiến gửi lúc { $time }
ui-outbox-delete-ask = Xóa thư này mà không gửi?
ui-open-link = Mở liên kết
ui-edit-link = Sửa liên kết...
ui-remove-link = Gỡ liên kết
ui-insert-attachment = Chèn tệp đính kèm
ui-insert-picture = Chèn ảnh
ui-filter-all = Tất cả tệp
ui-filter-pictures = Ảnh
ui-filter-messages = Thư email
ui-save-attachment-as = Lưu tệp đính kèm dưới dạng
ui-not-sent = Không thể gửi thư.
ui-attachment-forgotten = Bạn đã viết “{ $word }” nhưng chưa đính kèm tệp nào. Vẫn gửi thư?
ui-send-anyway = Vẫn gửi
ui-go-back = Quay lại
ui-not-saved = Không thể lưu thư.
ui-saving-draft = Đang lưu vào Thư nháp...
ui-compose-saved-at = Đã lưu vào Thư nháp lúc { $time }
ui-compose-restored = Đã khôi phục sau khi Inbox Classic đóng bất ngờ
ui-compose-not-saved = Chưa lưu vào Thư nháp: { $reason }
ui-save-changes-ask = Bạn có muốn lưu các thay đổi của thư này vào Thư nháp không?
ui-new-message-title = Thư mới
ui-link-invalid = Hãy nhập một địa chỉ web (https://...) hoặc liên kết email (mailto:...).
ui-link-address = Địa chỉ:
ui-hyperlink = Siêu liên kết
ui-hyperlink-intro = Địa chỉ mà văn bản được chọn liên kết tới.
ui-edit-hyperlink = Sửa siêu liên kết
ui-edit-hyperlink-intro = Địa chỉ đích của liên kết. Xóa địa chỉ để gỡ liên kết và giữ lại văn bản.
ui-not-a-picture = Không thể đọc tệp dưới dạng ảnh PNG, JPEG, GIF hoặc WebP có kích cỡ tối đa 10 MB.
ui-format-color = Màu phông chữ
ui-format-numbers = Danh sách đánh số
ui-format-bullets = Danh sách dấu đầu dòng
ui-format-outdent = Giảm thụt lề
ui-format-indent = Tăng thụt lề
ui-format-left = Căn trái
ui-format-center = Căn giữa
ui-format-right = Căn phải
ui-format-line = Chèn đường kẻ ngang
ui-tb-send = Gửi
ui-tb-save = Lưu
ui-tb-attach = Đính kèm
ui-tb-sign = Ký
ui-tb-encrypt = Mã hóa
ui-field-keys = Khóa:
ui-field-from = Từ:
ui-field-to = Đến:
ui-field-cc = Cc:
ui-field-bcc = Bcc:
ui-field-subject = Chủ đề:
ui-field-attach = Tệp đính kèm:
ui-signature = Chữ ký
ui-signature-hint = Được thêm vào thư mới, thư trả lời và thư chuyển tiếp từ tài khoản này.
ui-signature-not-saved = Không thể lưu chữ ký.
ui-all-inboxes = Tất cả Hộp thư đến
ui-all-sent = Tất cả Mục đã gửi
ui-all-drafts = Tất cả Thư nháp
ui-flagged-folder = Đã gắn cờ
ui-all-folders = Tất cả thư mục
ui-the-account = tài khoản
ui-folder-name = Tên thư mục:
ui-find-hint = Tìm kiếm thư
ui-find-tip = Tìm trong chủ đề, người gửi, người nhận, tên tệp đính kèm và nội dung thư.
ui-clear-search = Xóa tìm kiếm
ui-no-match = Không có thư nào khớp với “{ $words }”.
ui-no-match-all = Tìm kiếm bao gồm chủ đề, người gửi, người nhận, tên tệp đính kèm và nội dung thư trong tất cả thư mục. Hãy kiểm tra chính tả hoặc thử ít từ hơn.
ui-no-match-in = Tìm kiếm trong { $folder } bao gồm chủ đề, người gửi, người nhận, tên tệp đính kèm và nội dung thư. Hãy kiểm tra chính tả hoặc thử ít từ hơn.
ui-no-items = Không có mục nào trong dạng xem này.
ui-choose-folder = Chọn một thư mục để xem thư trong đó.
ui-unsubscribe = Hủy đăng ký
ui-open-in-calendar = Mở trong Lịch
ui-pictures-blocked = Một số ảnh đã bị chặn để hạn chế người gửi theo dõi bạn.
ui-not-shown = Không thể hiển thị thư.
ui-attachment-not-read = Không thể đọc tệp đính kèm.
ui-attachment-not-saved = Không thể lưu tệp đính kèm.
ui-not-downloaded = Thư chưa được tải xuống.
ui-leave-list = Rời khỏi danh sách gửi thư này?
ui-leave-one-click = Inbox Classic sẽ gửi yêu cầu hủy đăng ký đến { $target }. Sẽ không có trang web nào được mở và không có email nào được gửi.
ui-leave-mail = Để hủy đăng ký, hãy gửi một email đến { $target }. Inbox Classic sẽ soạn sẵn email này cho bạn. Gửi thư để xác nhận.
ui-leave-web = Trang hủy đăng ký của danh sách gửi thư sẽ mở trong trình duyệt của bạn ({ $target }).
ui-unsubscribing = Đang gửi yêu cầu hủy đăng ký đến { $target }...
ui-cannot-unsubscribe = Thư này không cung cấp tùy chọn hủy đăng ký.
ui-unsubscribed = Danh sách gửi thư đã chấp nhận yêu cầu hủy đăng ký.
ui-not-unsubscribed = Không thể hủy đăng ký: { $reason }
# the bar over a message of a mailing list. It names the list by a domain only, never by a name the sender chose
ui-list-bar = Thư này đến từ một danh sách gửi thư ({ $domain }).
ui-list-bar-plain = Thư này đến từ một danh sách gửi thư.
# $date is a day as the system writes it ("21 November 2026")
ui-list-bar-asked = Bạn đã yêu cầu rời khỏi danh sách này vào { $date }.
# a message that arrived more than two days after the request: the list did not stop
ui-list-bar-came-after = Bạn đã yêu cầu hủy đăng ký vào { $date }, nhưng thư này đến hơn hai ngày sau yêu cầu đó.
ui-list-bar-opened = Bạn đã mở trang hủy đăng ký của danh sách này vào { $date }.
ui-list-bar-failed = Yêu cầu hủy đăng ký không thành công: { $reason }
# the bar's button; it asks first
ui-unsubscribe-ask = Hủy đăng ký…
ui-unsubscribe-again = Hủy đăng ký lại…
ui-event-span = { $start } đến { $end }
ui-event-floating = { $when } (theo giờ đã ghi, không quy đổi múi giờ)
ui-invitation = Lời mời: { $title }
ui-invitation-updated = Lời mời đã cập nhật: { $title }
ui-invitation-canceled = Đã hủy: { $title }
ui-invitation-answer = Phản hồi lời mời: { $title }
ui-no-title = (không có tiêu đề)
ui-organizer = Người tổ chức: { $name }
ui-invitation-not-read = Không thể đọc lời mời.
ui-no-calendar = Không thể mở lời mời (tệp .ics). Hãy kiểm tra xem đã có ứng dụng lịch nào được liên kết với loại tệp này chưa.
ui-messages-not-changed = Không thể thay đổi các thư.
ui-new-folder-in-selected = Thư mục mới sẽ được tạo bên trong thư mục đã chọn.
ui-new-folder-at-top = Thư mục mới sẽ được tạo ở cấp cao nhất của tài khoản.
ui-folder-not-created = Không thể tạo thư mục.
ui-folder-not-renamed = Không thể đổi tên thư mục.
ui-folder-not-deleted = Không thể xóa thư mục.
ui-rename-folder-intro = Nhập tên mới cho thư mục “{ $folder }”.
ui-properties-of = Thuộc tính của { $subject }
ui-internet-headers = Tiêu đề Internet của thư này:
ui-save-messages-in = Lưu thư vào
ui-save-message-as = Lưu thư dưới dạng
ui-import-choose-folder = Trước tiên, hãy chọn thư mục để nhập thư vào.
ui-add-account-title = Thêm tài khoản thư
ui-accounts-title = Tài khoản
ui-security-none = Không có (không mã hóa)
ui-field-required = Bắt buộc phải có { $field }.
ui-email-invalid = Địa chỉ email không hợp lệ.
ui-ports-invalid = Cổng là số từ 1 đến 65535.
ui-looking-up = Đang tìm thiết đặt của { $domain }...
ui-found-none = Nhập thông tin tài khoản do nhà cung cấp email của bạn cung cấp.
ui-found-change = Hãy thay đổi các thiết đặt này nếu nhà cung cấp của bạn đã cung cấp thiết đặt khác.
ui-found-guess = Không tìm thấy thiết đặt nào cho địa chỉ này. Tên máy chủ được đề xuất chỉ là phỏng đoán. Hãy kiểm tra lại với nhà cung cấp của bạn.
ui-found-mx = Inbox Classic đã nhận ra nhà cung cấp email của bạn và điền sẵn thiết đặt máy chủ.
ui-found-srv = Các thiết đặt này được tìm thấy trong bản ghi DNS của tên miền của bạn.
ui-found-autodiscover = Các thiết đặt này được tìm thấy bằng Microsoft Autodiscover (Exchange).
ui-found-other = Các thiết đặt này được tìm thấy cho địa chỉ này.
ui-app-password-needed = Nhà cung cấp: { $provider }. Nếu tài khoản của bạn hỗ trợ mật khẩu ứng dụng, hãy tạo một mật khẩu trong thiết đặt bảo mật của tài khoản và nhập vào trường Mật khẩu ở biểu mẫu tiếp theo. Nếu không, hãy đăng nhập qua trình duyệt nếu có thể.
ui-app-password-open = Mở hướng dẫn của { $provider } trong trình duyệt?
ui-plain-warning = Khi không mã hóa, bất kỳ ai chặn bắt được lưu lượng mạng của bạn đều có thể đọc mật khẩu và thư của bạn. Chỉ tiếp tục nếu kết nối được bảo vệ theo cách khác. Bản thân mạng cục bộ không mã hóa dữ liệu.
ui-continue-ask = Tiếp tục?
ui-add-sign-in-app = Thêm ứng dụng đăng nhập...
ui-turned-off = { $name } đã bị tắt trên máy tính này.
ui-off-here = Đã tắt trên máy tính này.
ui-why = Tại sao?
ui-more-sign-in = Tùy chọn đăng nhập khác...
ui-other-account = Để thêm tài khoản email khác, hãy nhập địa chỉ email của bạn và tên mà người nhận sẽ thấy. Thiết đặt máy chủ sẽ được tìm ở bước tiếp theo.
ui-field-account-name = Tên tài khoản:
ui-field-name = Tên hiển thị:
ui-field-email = Địa chỉ email:
ui-field-user = Tên người dùng:
ui-field-password = Mật khẩu:
ui-field-imap-host = Máy chủ thư đến (IMAP):
ui-field-imap-port = Cổng IMAP:
ui-field-imap-security = Bảo mật IMAP:
ui-field-smtp-host = Máy chủ thư đi (SMTP):
ui-field-smtp-port = Cổng SMTP:
ui-field-smtp-security = Bảo mật SMTP:
ui-field-other-addresses = Các địa chỉ khác bạn dùng để gửi:
ui-sign-in-not-started = Không thể bắt đầu đăng nhập qua trình duyệt.
ui-sign-in-in-browser = Hãy đăng nhập vào { $account } trong cửa sổ trình duyệt vừa mở, rồi quay lại đây.
ui-sign-in-failed = Không thể đăng nhập: { $reason }
ui-account-not-saved = Không thể lưu tài khoản.
ui-start-intro = Gmail, Google Workspace, Outlook.com và Microsoft 365: đăng nhập trên trang của chính Google hoặc Microsoft. Bạn nhập mật khẩu ở đó, không bao giờ nhập vào Inbox Classic.
ui-start-intro-apps = Đăng nhập qua trình duyệt bằng một trong các ứng dụng đăng nhập của bạn (Tùy chọn đăng nhập khác), hoặc thêm bất kỳ tài khoản email nào bằng tên và địa chỉ của bạn ở bên dưới.
ui-use-app-password = Dùng mật khẩu ứng dụng
ui-the-provider = nhà cung cấp
ui-provider-intro = Đăng nhập vào { $email } trên trang web của { $provider }. Mật khẩu của bạn không được chia sẻ với Inbox Classic. Nếu tài khoản của bạn cho phép dùng mật khẩu ứng dụng để truy cập thư, bạn cũng có thể dùng một mật khẩu tạo trong thiết đặt bảo mật của tài khoản. Outlook.com và Microsoft 365 chỉ chấp nhận đăng nhập qua trình duyệt.
ui-provider-intro-apps = Đăng nhập vào { $email } trên trang web của { $provider } bằng một trong các ứng dụng đăng nhập của bạn (Tùy chọn đăng nhập khác). Nếu tài khoản của bạn cho phép dùng mật khẩu ứng dụng để truy cập thư, bạn cũng có thể dùng một mật khẩu tạo trong thiết đặt bảo mật của tài khoản. Outlook.com và Microsoft 365 chỉ chấp nhận đăng nhập qua trình duyệt.
ui-finish = Hoàn tất
ui-logon = Đăng nhập
ui-enter-password = Nhập mật khẩu của { $account }.
ui-signs-in-with = Ứng dụng đăng nhập: { $app }. Việc đăng nhập diễn ra trong trình duyệt, và tài khoản dùng máy chủ của ứng dụng này.
ui-keep-password = Để trống trường mật khẩu để giữ mật khẩu hiện tại.
ui-remove-account = Gỡ tài khoản
ui-remove-account-ask = Gỡ tài khoản này khỏi Inbox Classic? Dữ liệu cục bộ của tài khoản, bao gồm các thư đang chờ trong Hộp thư đi và thông tin đăng nhập đã lưu, sẽ bị xóa. Thư trên máy chủ vẫn được giữ nguyên.
ui-col-email = Địa chỉ email
ui-col-incoming = Máy chủ thư đến
ui-type-email = Nhập địa chỉ email của bạn, ví dụ ten@example.com.
ui-ai-agent = Tác nhân AI
ui-ai-agent-access = Quyền truy cập của tác nhân AI
ui-ai-agents = Tác nhân AI
ui-program-path = Chương trình: { $path }
ui-it-may = Hành động được phép:
ui-accounts-it-may-use = Tài khoản được phép:
ui-send-message-ask = Gửi thư?
ui-col-name = Tên
ui-never = Chưa bao giờ
ui-connect-agent = Kết nối tác nhân AI
ui-connect-agent-intro = Thêm nội dung này vào danh sách máy chủ MCP của tác nhân (Claude Desktop: Settings > Developer > Edit Config):
ui-col-program = Chương trình
ui-col-may = Quyền
ui-col-last-used = Dùng lần cuối
ui-col-when = Thời điểm
ui-col-what = Hành động
ui-sign-in-app = Ứng dụng đăng nhập
ui-sign-in-apps = Ứng dụng đăng nhập
ui-add-sign-in-app-title = Thêm ứng dụng đăng nhập
ui-preset-app-name = Ứng dụng đăng nhập { $provider }
ui-issuer-not-checked = không thể kiểm tra bên phát hành
ui-checking-issuer = Đang kiểm tra { $issuer }...
ui-issuer-unusable = Không thể dùng bên phát hành này: { $reason }
ui-issuer-usable = Có thể dùng bên phát hành này.
ui-sign-in-app-not-saved = Không thể lưu ứng dụng đăng nhập: { $reason }
ui-check = &Kiểm tra
ui-fill-in-for = Dùng thiết đặt cho:
ui-app-name = Tên:
ui-issuer = Bên phát hành:
ui-client-id = ID máy khách:
ui-client-secret = Bí mật máy khách:
ui-scopes = Phạm vi (scopes):
ui-imap-server = Máy chủ IMAP:
ui-smtp-server = Máy chủ SMTP:
ui-redirect-uri = URI chuyển hướng:
ui-sign-in-app-intro = Ứng dụng đăng nhập là một máy khách OAuth mà bạn đăng ký với nhà cung cấp để đăng nhập qua trình duyệt. Chọn một nhà cung cấp để điền sẵn thiết đặt, rồi thêm ID máy khách và bí mật máy khách, nếu nhà cung cấp đã cấp cho bạn.
ui-remove-secret = Đã lưu một bí mật máy khách. Nhập bí mật mới để thay thế, hoặc gỡ bí mật đã lưu
ui-register-it = Đăng ký ứng dụng với nhà cung cấp của bạn
ui-built-in-note = { $name } có sẵn trong ứng dụng. Bạn chỉ có thể thay đổi việc nó có được đề xuất cho tài khoản mới hay không.
ui-client-with-secret = ID máy khách: { $client }, có bí mật máy khách.
ui-client-public = ID máy khách: { $client }, máy khách công khai (không có bí mật).
ui-no-accounts = Không có tài khoản
ui-remove-sign-in-app = Gỡ ứng dụng đăng nhập
ui-remove-sign-in-app-ask = Gỡ ứng dụng đăng nhập { $name } và bí mật máy khách đã lưu của nó?
ui-sign-in-app-not-removed = Chưa gỡ được ứng dụng đăng nhập. { $reason }
ui-sign-in-apps-intro = Ứng dụng đăng nhập cho phép tài khoản đăng nhập qua trình duyệt. Ứng dụng không được đánh dấu chọn sẽ không được đề xuất cho tài khoản mới; các tài khoản đang dùng nó vẫn hoạt động bình thường.
ui-col-issuer = Bên phát hành
ui-col-used-by = Được dùng bởi
ui-options-system-default = Mặc định của hệ thống ({ $language })
# the settings window (core/settings.toml): its pages and the titles of its groups, Windows' Apply, and the words of
# the language the three platforms share
ui-settings-general = Chung
ui-settings-reading = Đọc thư
ui-settings-new-mail = Thư mới
ui-settings-sending = Gửi thư
ui-settings-default-apps = Ứng dụng mặc định
ui-settings-message-list = Danh sách thư
ui-settings-messages = Thư
ui-settings-encryption = Mã hóa
ui-settings-language = Ngôn ngữ
# a group's title as the label before its first control, in the Mac's panes: the colon as the language writes it
ui-settings-label = { $label }:
ui-apply = Áp &dụng
# review: new
ui-settings-sync = Đồng bộ hóa
# review: new
ui-sync-note = Giữ cho tài khoản, khóa, Sổ địa chỉ, quy tắc và cài đặt của bạn giống nhau trên mọi máy tính, thông qua một thư mục hoặc kho lưu trữ do bạn sở hữu. Mọi thứ đều được mã hóa bằng cụm mật khẩu đồng bộ của bạn trước khi rời khỏi máy tính này.
# review: new
ui-sync-place = Đồng bộ qua:
# review: new
ui-sync-status = Trạng thái:
# review: new
ui-sync-set-up = &Thiết lập đồng bộ…
# review: new
ui-sync-now = Đồng bộ &ngay
# review: new
ui-sync-computers = &Máy tính…
# review: new
ui-sync-history = &Lịch sử…
# review: new
ui-sync-turn-off = Tắt đồng &bộ…
# review: new
ui-sync-what = Nội dung cần đồng bộ
# review: new
ui-sync-what-note = Mật khẩu, thông tin đăng nhập và khóa riêng tư chỉ được truyền đi ở dạng mã hóa. Hãy bỏ chọn những gì nên ở lại trên máy tính này.
# review: new
ui-sync-accounts = Tài kh&oản
# review: new
ui-sync-passwords = Mật k&hẩu
# review: new
ui-sync-sign-ins = Đăn&g nhập bằng Google, Microsoft và ứng dụng đăng nhập
# review: new
ui-sync-sign-in-apps = Ứng dụng đăng nhậ&p
# review: new
ui-sync-app-secrets = Bí mật củ&a ứng dụng đăng nhập
# review: new
ui-sync-contacts = &Sổ địa chỉ
# review: new
ui-sync-keys = &Khóa
# review: new
ui-sync-private-keys = Khóa &riêng tư của bạn
# review: new
ui-sync-rules = &Quy tắc
# review: new
ui-sync-trusted = Người gửi t&in cậy
# review: new
ui-sync-settings = &Cài đặt
# review: new
ui-sync-preferences = Bố trí và chế độ &xem
# review: new
ui-sync-everything = Mọi thứ
# review: new
ui-sync-some-left-out = Đã bỏ qua một số mục
# review: new
ui-sync-where = Nơi lưu giữ
# review: new
ui-sync-folder = Một thư mục
# review: new
ui-sync-folder-note = Dropbox, OneDrive, iCloud Drive, Google Drive, Nextcloud hoặc Syncthing sẽ sao chép thư mục này sang các máy tính khác của bạn.
# review: new
ui-sync-bucket = Kho lưu trữ tương thích S3
# review: new
ui-sync-bucket-note = Amazon S3, Cloudflare R2, Backblaze B2, MinIO hoặc kho lưu trữ khác hoạt động giống S3.
# review: new
ui-sync-folder-label = &Thư mục:
# review: new
ui-sync-folder-none = Chưa chọn
# review: new
ui-sync-choose-folder = &Chọn…
# review: new
ui-sync-choose-folder-title = Chọn thư mục để đồng bộ qua
# review: new
ui-sync-endpoint = Điể&m cuối:
# review: new
ui-sync-region = &Vùng:
# review: new
ui-sync-bucket-name = &Bucket:
# review: new
ui-sync-prefix = Thư mục trong b&ucket:
# review: new
ui-sync-access-key = &ID khóa truy cập:
# review: new
ui-sync-secret-key = &Khóa truy cập bí mật:
# review: new
ui-sync-next = Tiế&p
# review: new
ui-sync-join-title = Tham gia đồng bộ
# review: new
ui-sync-join-note = Nơi này đang chứa dữ liệu đồng bộ của các máy tính khác của bạn. Hãy nhập cụm mật khẩu đồng bộ bạn đã chọn trên máy tính đầu tiên.
# review: new
ui-sync-start-title = Bắt đầu đồng bộ
# review: new
ui-sync-start-note = Hãy chọn một cụm mật khẩu đồng bộ. Bạn nhập nó một lần trên mỗi máy tính bạn thêm vào. Hãy cất nó ở nơi an toàn: nếu không có nó, không máy tính nào khác có thể tham gia.
# review: new
ui-sync-name = Tê&n của máy tính này:
# review: new
ui-sync-merge-note = Những gì máy tính này có và những gì bản đồng bộ có sẽ được gộp lại: một tài khoản hoặc liên hệ có ở cả hai nơi sẽ trở thành một.
# review: new
ui-sync-turn-on = Bật đồn&g bộ
# review: new
ui-sync-on = Đồng bộ đang bật.
# review: new
ui-sync-turn-off-ask = Tắt đồng bộ trên máy tính này? Mọi thứ vẫn giữ nguyên, ở đây và trên các máy tính khác của bạn. Máy tính này chỉ ngừng đồng bộ.
# review: new
ui-sync-turn-off-button = Tắt
# review: new
ui-sync-computers-title = Máy tính
# review: new
ui-sync-computers-note = Các máy tính đồng bộ qua nơi này. Hãy gỡ máy tính bạn không còn dùng: máy đó sẽ ngừng đồng bộ, và những gì nó đã đồng bộ vẫn được giữ lại.
# review: new
ui-sync-this-computer = Máy tính này
# review: new
ui-sync-seen = Đồng bộ lần cuối { $when }
# review: new
ui-sync-remove-ask = Gỡ “{ $name }” khỏi đồng bộ? Máy đó sẽ ngừng đồng bộ ở lần thử tiếp theo. Để đồng bộ lại, hãy thiết lập đồng bộ trên máy đó một lần nữa.
# review: new
ui-sync-loading = Đang đọc…
# review: new
ui-sync-history-title = Lịch sử
# review: new
ui-sync-history-note = Khi cùng một mục được thay đổi trên hai máy tính cùng lúc, thay đổi được thực hiện sau cùng được giữ lại và thay đổi kia nằm ở đây. Hãy khôi phục một thay đổi để dùng nó thay thế.
# review: new
ui-sync-history-empty = Không có thay đổi nào bị thay thế.
# review: new
ui-sync-history-row = Từ { $source }, { $when }
# review: new
ui-sync-restore = &Khôi phục
# review: new
ui-sync-restore-points = Điểm khôi phục
# review: new
ui-sync-restore-points-note = Trước khi một lần đồng bộ xóa thứ gì đó ở đây, trạng thái lúc đó sẽ được lưu lại. Hãy mở một điểm để lấy lại những phần bạn chọn.
# review: new
ui-sync-restore-points-empty = Chưa có.
# review: new
ui-sync-open-point = &Mở…
# Set Up Sync on Windows: back from its second step to the first, as a wizard's Back button
# review: new
win-sync-back = < &Quay lại
ui-language-label = &Ngôn ngữ:
ui-restart-note = Khởi động lại Inbox Classic để đổi ngôn ngữ.
ui-restart-ask = Inbox Classic sẽ hiển thị bằng { $language } sau khi khởi động lại. Khởi động lại ngay?
ui-notify-new-mail = &Thông báo cho tôi khi có thư mới
ui-new-folder-title = Thư mục mới
ui-rename-folder-title = Đổi tên thư mục
ui-delete-folder-question = Xóa thư mục “{ $folder }” cùng các thư và thư mục con trong đó? Thư mục cũng bị xóa trên máy chủ.
ui-properties = T&huộc tính
ui-account-sync = &Gửi và nhận
ui-account-properties = Thuộc tín&h...
# review: new
ui-account-properties-of = Thuộc tính tài &khoản...
ui-account-move-up = Di chuyển &lên
ui-account-move-down = &Di chuyển xuống
ui-menu-open = &Mở
ui-menu-flag = &Cờ
ui-menu-view-source = X&em nguồn
# Context menu: the same action as cmd-unsubscribe, with its own access key.
ui-menu-unsubscribe = Hủy đăng ký d&anh sách...
ui-save-attachments = Lưu tệp đính kèm
ui-attachment-open = Mở
ui-attachment-save-as = Lưu dưới dạng...
ui-attachment-save-all = Lưu tất cả...
# the strip's menu: a checked item for a picture or PDF file, drawn in the message (checked) or not
ui-attachment-show-in-message = Hiển thị trong thư
ui-attachments-strip = Tệp đính kèm
ui-attachment-note-title = Mở tệp này
ui-attachment-program-tip = Lệnh Mở bị tắt đối với loại tệp này vì tệp có thể chạy chương trình. Hãy lưu tệp rồi tự mở.
ui-clear-flag = &Bỏ cờ
ui-button-move = &Di chuyển
ui-button-copy = &Sao chép
ui-find-folder = Tìm thư mục
ui-new-folder-in = Thư mục mới sẽ nằm trong { $folder }.
ui-outbox-send-all = &Gửi tất cả ngay
ui-yes = Có
ui-no = Không
ui-try-again = Thử lại
ui-remove = &Gỡ
ui-signature-of = Chữ ký - { $account }
ui-sign-in-with = Đăng nhập bằng { $provider }
ui-sign-in-in-browser-yours = Hãy đăng nhập vào tài khoản của bạn trong cửa sổ trình duyệt vừa mở, rồi quay lại đây.
ui-browser-sign-in-server = { $server } (đăng nhập qua trình duyệt)
ui-dont-allow = Không cho phép
ui-allow = &Cho phép
ui-dont-send = Không gửi
ui-dont-unsubscribe = Không hủy đăng ký
ui-edit-first = &Sửa trước
ui-new-address = Địa chỉ mới
ui-turn-away = Từ c&hối
ui-clear-agent-log = Xóa lịch sử hoạt động của các tác nhân?
ui-clear-agent-log-detail = Thao tác này không hoàn tác các thay đổi mà tác nhân đã thực hiện.
ui-let-agents-connect = &Cho phép tác nhân AI kết nối với Inbox Classic
ui-change-button = Thay đổi…
ui-undo-button = Hoàn tác
# Tools > AI Agents: takes back everything the selected program did in a span the user picks
ui-undo-since-button = Hoàn tác từ…
ui-undo-since-span = Hoàn tác những gì chương trình này đã làm:
ui-take-back = Hoàn tác
ui-rules-title = Quy tắc thư
ui-rules-intro = Quy tắc xử lý thư mới trong Hộp thư đến khi Inbox Classic đang chạy. Các quy tắc khớp được áp dụng theo thứ tự. Khi một quy tắc dự định chuyển thư ra khỏi Hộp thư đến, các quy tắc sau sẽ không áp dụng cho thư đó nữa.
ui-rules-none = Chưa có quy tắc nào. Bấm Mới để tạo.
ui-rule-new = &Mới...
ui-rule-edit = &Sửa...
ui-rule-delete-button = &Xóa
ui-rule-title = Quy tắc thư
ui-rule-name = Tên:
ui-rule-account = Tài khoản:
ui-rule-all-accounts = Tất cả tài khoản
ui-rule-query = Tiêu chí tìm kiếm:
ui-rule-query-hint = Dùng các từ khóa tìm kiếm như from:ann@example.com, subject:hoadon hoặc list:news.example.com, giống như trong ô tìm kiếm.
ui-rule-count = Hiện có { $count } thư trong Hộp thư đến khớp với các tiêu chí này.
ui-rule-show = H&iện
ui-rule-actions = Hành động:
ui-rule-move = &Chuyển thư đến:
ui-rule-mark-read = Đánh &dấu là đã đọc
ui-rule-flag = &Gắn cờ
ui-rule-archive = &Lưu trữ
ui-rule-junk = Chuyển vào Email &rác
ui-rule-delete = &Xóa
ui-rule-quiet = &Không thông báo cho tôi
ui-rule-apply-now = Áp dụng cho cả các thư đã có trong &Hộp thư đến
ui-rule-delete-ask = Xóa quy tắc “{ $name }”?
ui-create-rule = Tạo quy tắc...
ui-rules-applied = { $count } thư đã được quy tắc của bạn xử lý
ui-col-rule-matches = Tiêu chí
ui-clear-button = &Xóa
ui-how-to-connect = Cách kết nối tác nhân…
ui-agent-programs = Các chương trình có tác nhân đã yêu cầu quyền truy cập thư của bạn
ui-what-agents-did = Hoạt động của tác nhân
ui-restart-now = &Khởi động lại ngay
ui-restart-later = Để &sau

## Sổ địa chỉ (Công cụ > Sổ địa chỉ), Thuộc tính liên hệ và nhóm, Chọn người nhận

ui-tb-new-contact = Liên hệ mới
ui-tb-new-group = Nhóm mới
ui-tb-properties = Thuộc tính
ui-tb-write-to = Viết thư
ui-menu-new-contact = &Liên hệ mới...
ui-menu-new-group = &Nhóm mới...
ui-menu-write-to = &Viết thư
ui-menu-delete = &Xóa
ui-book-find-hint = Nhập tên hoặc địa chỉ email
ui-book-all-contacts = Tất cả liên hệ
ui-col-phone = Điện thoại
ui-book-empty = Sổ địa chỉ đang trống. Bấm Liên hệ mới để thêm người, hoặc nhập tệp vCard hay CSV từ menu Tệp.
ui-book-no-match = Không có liên hệ nào khớp với “{ $words }”.
ui-book-delete-ask = { $count ->
    [1] Xóa liên hệ này khỏi Sổ địa chỉ?
   *[other] Xóa { $count } liên hệ này khỏi Sổ địa chỉ?
}
ui-group-delete-ask = Xóa nhóm “{ $name }”? Những người trong nhóm vẫn còn trong Sổ địa chỉ.
ui-book-no-address = { $name } không có địa chỉ email.
ui-new-contact-title = Liên hệ mới
ui-contact-title = Thuộc tính của { $name }
ui-contact-first = Tên:
ui-contact-last = Họ:
ui-contact-display = Tên hiển thị:
ui-contact-nickname = Biệt danh:
ui-contact-company = Công ty:
ui-contact-addresses = Địa chỉ email:
ui-contact-address-hint = Nhập địa chỉ email
ui-contact-add = &Thêm
ui-contact-set-default = Đặt &làm mặc định
ui-contact-default = { $address } (mặc định)
ui-contact-phones = Số điện thoại:
ui-phone-home = Nhà riêng
ui-phone-work = Cơ quan
ui-phone-mobile = Di động
ui-phone-other = Khác
ui-contact-notes = Ghi chú:
ui-contact-name-needed = Nhập tên hoặc địa chỉ email cho liên hệ.
ui-contact-address-invalid = “{ $address }” không phải là địa chỉ email hợp lệ.
ui-contact-not-saved = Không thể lưu liên hệ: { $reason }
ui-new-group-title = Nhóm mới
ui-group-title = Thuộc tính của { $name }
ui-group-name = Tên nhóm:
ui-group-members = Thành viên:
ui-group-select-members = &Chọn thành viên...
ui-group-new-member = Thêm một địa chỉ email không có trong Sổ địa chỉ:
ui-group-name-needed = Nhập tên cho nhóm.
ui-group-not-saved = Không thể lưu nhóm: { $reason }
ui-group-members-count = { $count } thành viên
ui-select-recipients = Chọn người nhận
ui-select-members = Chọn thành viên nhóm
ui-pick-intro = Nhập tên hoặc chọn từ danh sách:
ui-pick-recipients = Người nhận thư:
ui-pick-members = Thành viên nhóm:
ui-pick-to = Đế&n →
ui-pick-cc = &Cc →
ui-pick-bcc = &Bcc →
ui-pick-add = &Thêm →
ui-pick-tip = Chọn người nhận từ Sổ địa chỉ
ui-filter-address-books = Sổ địa chỉ (vCard, CSV)
ui-filter-vcard = Tệp vCard
ui-book-export-name = Sổ địa chỉ
ui-book-imported = Đã thêm { $added } liên hệ, bỏ qua { $skipped } liên hệ đã có trong Sổ địa chỉ.
ui-book-not-imported = Không thể nhập sổ địa chỉ: { $reason }
ui-book-exported = Đã lưu { $count } liên hệ vào { $file }.
ui-book-not-exported = Không thể lưu sổ địa chỉ: { $reason }
ui-code-copied = Đã sao chép mã
ui-codes-in-notifications = &Hiện mã đăng nhập trong thông báo thư mới
ui-tool-unread-only = Chưa đọc
ui-no-unread = Không có thư chưa đọc nào ở đây.
ui-pictures-always-sender = Luôn tải xuống ảnh từ { $sender }
ui-pictures-always-domain = Luôn tải xuống ảnh từ mọi người tại { $domain }
ui-pictures-unconfirmed = Không thể xác minh tên miền của người gửi ({ $domain }), vì vậy ảnh trong thư này không được tự động tải xuống.
ui-pictures-always-option = Tải xuống ảnh trong &mọi thư
ui-pictures-always-warning = Khi đó, người gửi có thể biết khi nào bạn đọc thư của họ.
ui-protection-details = &Chi tiết...
ui-protection-details-title = Chi tiết bảo mật
ui-download-heading = Tải xuống
ui-download-ahead = &Tải trước thư:
ui-download-ahead-recent = Thư gần đây, tối đa 1 MB mỗi thư
ui-download-ahead-all = Tất cả thư
ui-download-ahead-never = Chỉ khi mở
ui-download-limit = &Giới hạn dung lượng cho mỗi tài khoản:
ui-send-delay = Thời gian chờ trước khi &gửi:
ui-send-delay-note = Trong lúc đếm ngược, bạn có thể hủy gửi bằng Hoàn tác. Khi hết thời gian đếm ngược, bạn không thể dùng Hoàn tác để hủy gửi nữa, kể cả khi thư vẫn còn trong Hộp thư đi.
ui-dark-messages = Hiển thị thư trên nền tối khi hệ thống ở chế độ tối
# Reading settings: previews of the pictures and PDF files attached, after a message's text
ui-preview-show = Hiển thị tệp đính &kèm trong thư
ui-preview-show-note = Hiển thị ảnh và các trang đầu của tệp PDF sau phần nội dung thư. Inbox Classic tạo các bản xem trước này mà không chạy mã từ tệp và không tải tài nguyên bên ngoài của tệp.
# the second setting under it; the same words as preview-pdf-option, with an access key
ui-preview-pdfs = Hiển thị tệp &PDF trong thư
ui-sending-in = Sẽ gửi { $subject } sau { $count } giây
ui-send-undone = Chưa gửi { $subject }. Thư đã được mở lại để chỉnh sửa.
ui-send-too-late = Không thể hoàn tác việc gửi { $subject } nữa.
ui-outbox-status-undo = Dự kiến gửi lúc { $time }
ui-download-note = Giới hạn áp dụng cho nội dung thư được lưu cục bộ, không phải toàn bộ cơ sở dữ liệu. Khi vượt quá giới hạn, các bản sao cũ nhất sẽ bị xóa và có thể được tải xuống lại khi mở. Thư nháp và các thư đã mở từ khi khởi động ứng dụng vẫn được giữ lại, kể cả khi vượt quá giới hạn.
ui-attachment-downloading = Thư này chưa tải xuống xong. Hãy thử lại khi tải xuống hoàn tất.
ui-trusted-senders-button = Người gửi &tin cậy...
ui-trusted-senders-title = Người gửi tin cậy
ui-trusted-senders-note = Ảnh trong thư từ những người gửi này được tự động tải xuống khi nhà cung cấp thư của bạn xác minh được tên miền của người gửi.
ui-trusted-everyone-at = Mọi người tại { $domain }
ui-trusted-senders-empty = Chưa thêm người gửi tin cậy nào.
ui-search-encrypted = Tìm kiếm tr&ong thư đã mã hóa
ui-search-encrypted-note = Khi có sẵn các khóa riêng tư cần thiết, thư đã tải xuống hoặc đã mở có thể được giải mã và lập chỉ mục để tìm kiếm nội dung và chủ đề được bảo vệ. Chỉ mục này không được mã hóa. Tác nhân AI không thể tìm kiếm nội dung đã giải mã. Tắt tùy chọn này sẽ xóa nội dung đó khỏi chỉ mục.
ui-pgp-keyserver = Tra cứ&u khóa trên keys.openpgp.org
ui-pgp-keyserver-note = Khi tra cứu một địa chỉ, Inbox Classic hỏi tên miền của địa chỉ đó trước, rồi mới gửi địa chỉ đến keys.openpgp.org nếu cần. Khi tra cứu theo dấu vân tay hoặc ID khóa, chỉ mã định danh đó được gửi đi.
ui-eml-default = Mở tệp .&eml bằng Inbox Classic
ui-eml-default-done = Inbox Classic giờ sẽ mở tệp .eml.
ui-eml-default-failed = Không thể đặt Inbox Classic làm ứng dụng mặc định cho tệp .eml: { $reason }
ui-folders = Thư mục
ui-sorted-by = Sắp xếp theo { $field }
ui-layout-label = &Bố trí:
ui-columns-note = Cửa sổ đủ rộng cho bố trí dạng cột. Bạn có thể đổi bố trí trong Xem > Bố trí.
ui-row-unread = Chưa đọc
ui-row-flagged = Đã gắn cờ
ui-row-attachments = Có tệp đính kèm
ui-row-encrypted = Đã mã hóa
ui-row-signed = Đã ký
ui-row-messages = { $count } thư
ui-list-pictures = &Hiện ảnh của người gửi trong danh sách thư
ui-list-pictures-note = Trong bố trí dạng cột, hiển thị logo thương hiệu hoặc ảnh trong Sổ địa chỉ khi tên miền của người gửi đã được xác minh, và hiển thị chữ cái đầu khi không có ảnh. Logo đã tải xuống được lưu vào bộ nhớ đệm và dùng lại, thỉnh thoảng được làm mới.
ui-card-picture = Ảnh:
ui-card-picture-choose = C&họn...
ui-picture-not-picture = Không thể giải mã tệp dưới dạng ảnh PNG hoặc JPEG.
ui-picture-too-large = Ảnh này quá lớn. Hãy chọn ảnh có kích cỡ tối đa 10 MB, chiều rộng và chiều cao không quá 8000 điểm ảnh.

## Khóa mã hóa (Công cụ > Khóa mã hóa, Thuộc tính tài khoản > Bảo mật, khóa của một liên hệ)
ui-keys-title = Khóa mã hóa
ui-keys-intro = Khóa của bạn dùng để ký thư của bạn và mở thư được mã hóa gửi cho bạn. Khóa của các liên hệ dùng để kiểm tra chữ ký của họ và mã hóa thư gửi cho họ.
ui-keys-empty = Chưa có khóa nào. Bấm Khóa mới để tạo khóa của bạn, hoặc Nhập để thêm một khóa bạn đã có.
ui-keys-col-name = Tên
ui-keys-col-address = Địa chỉ
ui-keys-col-kind = Loại
ui-keys-col-status = Trạng thái
ui-keys-kind-own = Khóa của bạn
ui-keys-kind-contact = Liên hệ
ui-keys-status-verified = { $status }, đã xác minh
ui-keys-new = Khóa &mới...
ui-keys-import = &Nhập...
ui-keys-export = &Xuất...
ui-keys-backup = &Sao lưu...
ui-keys-verify = Xác m&inh...
ui-keys-new-title = Khóa mới
ui-keys-new-for = Tạo khóa cho:
ui-keys-new-make = &Tạo khóa
ui-keys-no-account = Hãy thêm một tài khoản thư trước: khóa được tạo cho các địa chỉ của một tài khoản.
ui-keys-memory-only = Mật khẩu chỉ được giữ trong bộ nhớ, nên khóa riêng tư được tạo hoặc nhập lúc này sẽ không dùng được sau khi đóng Inbox Classic.
ui-keys-backup-offer = Khóa mới của bạn đã sẵn sàng. Lưu bản sao lưu ngay bây giờ? Nếu máy tính này bị mất hoặc bị đặt lại, chỉ có thể lấy lại khóa từ bản sao lưu.
ui-keys-backup-now = &Lưu bản sao lưu...
ui-keys-later = Để &sau
ui-keys-backup-title = Sao lưu khóa
ui-keys-backup-intro = Bản sao lưu được bảo vệ bằng cụm mật khẩu. Hãy cất tệp và cụm mật khẩu ở hai nơi an toàn khác nhau: bạn cần cả hai để lấy lại khóa.
ui-keys-passphrase = &Cụm mật khẩu:
ui-keys-passphrase-again = &Nhập lại:
ui-keys-passphrase-differ = Hai cụm mật khẩu không giống nhau.
ui-keys-passphrase-short = Hãy dùng cụm mật khẩu dài ít nhất 8 ký tự.
ui-keys-backup-saved = Đã lưu bản sao lưu.
ui-keys-import-title = Nhập khóa
ui-keys-import-passphrase = Khóa riêng tư này được bảo vệ bằng cụm mật khẩu. Nhập cụm mật khẩu để nhập khóa:
ui-keys-file-filter = Khóa OpenPGP
ui-keys-use-for = Dùng khóa này cho { $addresses }? Bạn có thể dùng nó để ký thư gửi từ các địa chỉ này và đọc thư được mã hóa bằng khóa này.
ui-keys-use = &Dùng khóa này
ui-keys-not-now = Để s&au
ui-keys-remove-own = Gỡ khóa { $fingerprint } của bạn? Để giải mã lại thư được bảo vệ bằng khóa này, bạn sẽ cần nhập bản sao lưu khóa riêng tư của nó. Các bản đã giải mã sẽ không bị xóa.
ui-keys-remove-contact = Gỡ khóa gắn với { $name }? Bạn sẽ không thể kiểm tra chữ ký tạo bằng khóa này hay dùng nó để mã hóa thư cho đến khi thêm lại.
ui-key-properties-title = Thuộc tính khóa
ui-key-names = Tên:
ui-key-fingerprint = Dấu vân tay:
ui-key-status = Trạng thái:
ui-key-created = Ngày tạo:
ui-key-expires = Hết hạn:
ui-key-never = Không bao giờ
ui-key-algorithm = Thuật toán:
ui-key-source = Nguồn:
ui-key-addresses = Địa chỉ:
ui-key-address-verified = { $address } (đã xác minh)
ui-key-address-not-verified = { $address } (chưa xác minh)
ui-verify-title = Xác minh khóa
ui-verify-intro = Hãy nhờ { $name } đọc cho bạn dấu vân tay khóa của họ từ chính ứng dụng của họ, khi gặp trực tiếp hoặc qua cuộc gọi. Đừng so sánh với dấu vân tay được gửi qua email: ai có thể thay đổi khóa thì cũng có thể thay đổi cả dấu vân tay đó.
ui-verify-fingerprint = Dấu vân tay của khóa bạn đang có:
ui-verify-marks = { $count ->
    [0] Khóa này không có địa chỉ email. Không thể lưu xác nhận chủ sở hữu của khóa.
    [1] Trước khi bấm Trùng khớp, hãy xác nhận địa chỉ này thuộc về liên hệ: { $addresses }. Nếu không, hãy bấm Khác nhau.
   *[other] Trước khi bấm Trùng khớp, hãy xác nhận tất cả các địa chỉ này đều thuộc về liên hệ: { $addresses }. Nếu không, hãy bấm Khác nhau.
}
ui-verify-match = &Trùng khớp
ui-verify-differ = &Khác nhau
ui-verify-differs = Khóa bạn đang có không trùng với khóa của { $name }. Hãy gỡ khóa này và xin lại khóa của họ.
ui-verify-unmark = Đánh dấu là &chưa xác minh
ui-account-security = Bảo mật
ui-account-security-intro = Khi có khóa, thư của bạn có thể được ký, và người khác có thể gửi thư được mã hóa cho bạn.
ui-account-key = &Khóa cho tài khoản này:
ui-account-key-none = Không có
ui-account-key-new = Khóa &mới...
ui-account-autocrypt = &Gửi khóa công khai của tôi kèm thư (Autocrypt)
ui-contact-key = Khóa mã hóa:
ui-contact-key-none = Không có khóa
ui-contact-key-use-new = Dùng khóa &mới
ui-contact-key-keep = Giữ khóa hiệ&n tại
ui-recipient-keys-title = Khóa của người nhận
ui-recipient-col-recipient = Người nhận
ui-recipient-col-key = Khóa
ui-recipient-find-key = &Tìm khóa
ui-recipient-remove = Gỡ k&hỏi thư
ui-send-unencrypted = Gửi &không mã hóa
ui-compose-make-key = Tạo &khóa...
ui-compose-show-keys = Khóa &mã hóa...
ui-compose-encrypt-off = &Tắt mã hóa
ui-compose-keep-encrypted = &Giữ mã hóa
ui-setup-export-title = Xuất cài đặt và tài khoản
ui-setup-import-title = Nhập cài đặt và tài khoản
ui-setup-export-intro = Chọn những gì cần mang sang máy tính khác. Tệp không chứa thư nào, kể cả thư trong Hộp thư đi. Trên máy tính kia, chỉ có thể tải xuống thư được lưu trên máy chủ.
ui-setup-use-passphrase = Bả&o vệ tệp bằng cụm mật khẩu
ui-setup-passphrase-note = Cụm mật khẩu sẽ mã hóa toàn bộ tệp và cho phép tệp chứa mật khẩu, mã thông báo đăng nhập, bí mật máy khách và khóa riêng tư hiện có của các mục đã chọn. Khi không có lớp bảo vệ này, các bí mật đó sẽ bị bỏ qua và bạn sẽ cần đăng nhập lại trên máy tính kia.
ui-setup-export-button = &Xuất...
ui-setup-file-filter = Cài đặt và tài khoản Inbox Classic
ui-setup-ask-passphrase = Tệp này được bảo vệ bằng cụm mật khẩu. Nhập cụm mật khẩu để xem nội dung của tệp:
ui-setup-import-intro = Chọn những gì cần nhập. Các tài khoản đã có trên máy tính này được giữ nguyên.
ui-setup-from = Được lưu bởi Inbox Classic { $version } vào { $date }.
ui-setup-import-button = &Nhập
ui-setup-done = Xong
ui-setup-first-run = Nhập cài đặt và tài khoản từ máy tính khác...
# review: new
ui-first-run-other = Bạn đã dùng Inbox Classic trên máy tính khác? Hãy mang tài khoản và cài đặt của máy đó sang đây.
# review: new
ui-first-run-sync = Tham gia đồng bộ của máy đó…
# review: new
ui-first-run-import = Nhập từ tệp…

ui-field-verifiers = Tin cậy kết quả kiểm tra người gửi từ:
ui-attachment-import-key = Nhập khóa...
ui-book-key-known = Có khóa mã hóa
ui-book-key-verified = Có khóa mã hóa đã xác minh chủ sở hữu
ui-keys-publish = &Công bố...
ui-keys-publish-ask = Công bố khóa công khai của bạn trên keys.openpgp.org để người khác có thể tìm thấy? Các địa chỉ trong khóa: { $addresses }. Mỗi địa chỉ phải được xác nhận qua liên kết gửi đến địa chỉ đó trước khi được liệt kê.
ui-keys-publish-now = Công bố
ui-keys-paste = Nhập từ bộ nhớ &tạm
ui-keys-paste-none = Bộ nhớ tạm không chứa khóa OpenPGP.
ui-contact-find-key = Tìm khó&a
# review: new
ui-reactions-label = Cảm xúc:
# review: new
ui-reaction-open-email = Mở email cảm xúc
# review: new
ui-reaction-show-as-email = Hiển thị dưới dạng email
# review: new
ui-reaction-when = Bày tỏ lúc { $when }
