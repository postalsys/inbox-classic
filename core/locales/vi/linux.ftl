# Bản nháp tiếng Việt, đang chờ người bản ngữ duyệt.
# Chữ trong các cửa sổ riêng của ứng dụng Linux (linux/src), các id bắt đầu bằng gtk-. Ứng dụng điền các chỗ giữ chỗ
# trong { $braces }; dấu _ đánh dấu chữ cái tắt của nút. Dùng từ của GNOME khi GNOME có.

## Cửa sổ chính

# review: new
gtk-search-looks-in = Tìm kiếm trong { $place } bao gồm chủ đề, người gửi, người nhận, tên tệp đính kèm và nội dung thư. Hãy kiểm tra chính tả hoặc thử ít từ hơn.
# review: new
gtk-search-still-indexing = Văn bản của { $count } thư vẫn đang được lập chỉ mục. Có thể sớm có thêm kết quả.
# review: new
gtk-search-results-everywhere = { $count ->
    [0] Không có kết quả
   *[other] { $count } kết quả
} cho “{ $words }” trong tất cả thư mục
# review: new
gtk-search-results-in = { $count ->
    [0] Không có kết quả
   *[other] { $count } kết quả
} cho “{ $words }” trong { $place }
# review: new
gtk-search-indexing = vẫn đang lập chỉ mục văn bản của { $count } thư
# review: new
gtk-list-loading = Đang tải...
# review: new
gtk-menu-rename = Đổi tên...
# review: new
gtk-import-one-question = Nhập thư { $file } vào { $folder }?
# review: new
gtk-files-not-saved = Không thể lưu { $failed } trong số { $total } tệp.
# review: new
gtk-unsubscribe-one-click =
    Rời khỏi danh sách gửi thư này?

    Inbox Classic sẽ gửi yêu cầu hủy đăng ký đến { $target }. Sẽ không có trang web nào được mở và không có email nào được gửi.
# review: new
gtk-unsubscribe-mail =
    Rời khỏi danh sách gửi thư này?

    Để hủy đăng ký, hãy gửi một email đến { $target }. Inbox Classic sẽ soạn sẵn email này cho bạn. Gửi thư để xác nhận.
# review: new
gtk-unsubscribe-web =
    Rời khỏi danh sách gửi thư này?

    Trang hủy đăng ký của danh sách gửi thư sẽ mở trong trình duyệt của bạn ({ $target }).
# review: new
gtk-unsubscribe-failed = Không thể hủy đăng ký: { $problem }
# review: new
gtk-toolbar-create-mail-menu = Soạn thư từ một tài khoản cụ thể
# review: new
gtk-toolbar-send-recv-menu = Gửi và nhận thư cho một tài khoản cụ thể
# review: new
gtk-main-menu = Menu chính
# review: new
gtk-folder-list = Danh sách thư mục
# review: new
gtk-quit = Thoát

## Cửa sổ Di chuyển và Sao chép

# review: new
gtk-new-folder-at-top-of = Thư mục mới sẽ nằm ở cấp cao nhất của { $account }.

## Danh sách thư

## Trợ giúp

## Thông báo và khay hệ thống

# review: new
gtk-unread-messages = { $count ->
    [0] Không có thư chưa đọc
   *[other] { $count } thư chưa đọc
}

## Menu liên kết của cửa sổ soạn thư

## Hộp thư đi

# review: new
gtk-outbox-empty = Không có thư nào đang chờ gửi.
# review: new
gtk-outbox-row = Đến: { $to }  ·  Vào hàng đợi { $queued }  ·  { $status }

## Ứng dụng

# review: new
gtk-still-running-detail = Inbox Classic vẫn tiếp tục kiểm tra thư mới ở chế độ nền. Dùng biểu tượng của ứng dụng trên thanh trên cùng để mở hoặc thoát ứng dụng.
# review: new
gtk-sign-in-again-ask =
    Đăng nhập vào { $account } bị từ chối hoặc phiên đã hết hạn.

    Đăng nhập lại trong trình duyệt?
# review: new
gtk-default-app-not-installed = Bản Inbox Classic này chưa được cài đặt, nên hệ thống không liệt kê nó là ứng dụng thư. Hãy cài đặt để có thể chọn nó.
# review: new
gtk-default-app-now = Inbox Classic giờ là ứng dụng thư mặc định của bạn: liên kết email sẽ mở một thư mới tại đây.
# review: new
gtk-default-app-failed = Không thể đặt Inbox Classic làm ứng dụng thư mặc định.

## Các nút và chữ dùng trong nhiều cửa sổ

## Ngăn đọc

# review: new
gtk-reader-date = Ngày:
# review: new
gtk-reader-files = Tệp đính kèm của thư
# review: new
gtk-files = { $count } tệp
# review: new
gtk-save-attachments-menu = Lưu tệp đính kèm...

## Cửa sổ soạn thư

# review: new
gtk-format-bold = Đậm (Ctrl+B)
# review: new
gtk-format-italic = Nghiêng (Ctrl+I)
# review: new
gtk-format-underline = Gạch dưới (Ctrl+U)
# review: new
gtk-format-hyperlink = Siêu liên kết (Ctrl+K)
# review: new
gtk-font = Phông chữ
# review: new
gtk-show-cc = _Cc
# review: new
gtk-show-bcc = _Bcc
# review: new
gtk-save-tip = Lưu (Ctrl+S)
# review: new
gtk-link-status = { $link }    (Ctrl+bấm để mở)

## Tài khoản

# review: new
gtk-plain-warning =
    Khi không mã hóa, bất kỳ ai chặn bắt được lưu lượng mạng của bạn đều có thể đọc mật khẩu và thư của bạn. Chỉ dùng kết nối này với máy chủ trên chính máy tính của bạn hoặc trong mạng cục bộ.

    Tiếp tục?
# review: new
gtk-account-name-title = Tên tài khoản
# review: new
gtk-display-name-title = Tên hiển thị
# review: new
gtk-turned-off-why = Tùy chọn “{ $button }” đã bị tắt trên máy tính này. { $reason }
# review: new
gtk-turned-off-why-long =
    Tùy chọn “{ $button }” đã bị tắt trên máy tính này.

    { $reason }
# review: new
gtk-next = Tiếp >
# review: new
gtk-provider-sign-in = Đăng nhập vào { $address } trên trang web của { $provider }. Mật khẩu của bạn không được chia sẻ với Inbox Classic. Nếu tài khoản của bạn cho phép dùng mật khẩu ứng dụng cho thư, bạn cũng có thể dùng một mật khẩu tạo trong thiết đặt bảo mật của tài khoản. Outlook.com và Microsoft 365 chỉ chấp nhận đăng nhập qua trình duyệt.
# review: new
gtk-provider-sign-in-apps = Đăng nhập vào { $address } trên trang web của { $provider } bằng một trong các ứng dụng đăng nhập của bạn (Tùy chọn đăng nhập khác). Nếu tài khoản của bạn cho phép dùng mật khẩu ứng dụng cho thư, bạn cũng có thể dùng một mật khẩu tạo trong thiết đặt bảo mật của tài khoản. Outlook.com và Microsoft 365 chỉ chấp nhận đăng nhập qua trình duyệt.
# review: new
gtk-accounts-add = Thêm...
# review: new
gtk-accounts-properties = Thuộc tính...
# review: new
gtk-accounts-signature = Chữ ký...
# review: new
gtk-accounts-sign-in-apps = Ứng dụng đăng nhập...

## Ứng dụng đăng nhập

# review: new
gtk-app-server = Máy chủ { $kind }
# review: new
gtk-app-port = Cổng { $kind }
# review: new
gtk-app-security = Bảo mật { $kind }
# review: new
gtk-issuer-found =
    Trang đăng nhập: { $page }
    Điểm cuối mã thông báo: { $endpoint }
# review: new
gtk-client-id = ID máy khách
# review: new
gtk-client-secret = Bí mật máy khách
# review: new
gtk-scopes = Phạm vi (scopes)
# review: new
gtk-redirect-uri = URI chuyển hướng
# review: new
gtk-issuer-usable =
    Có thể dùng bên phát hành này.

    { $found }
# review: new
gtk-app-built-in = { $app } có sẵn trong ứng dụng. Bạn chỉ có thể thay đổi việc nó có được đề xuất cho tài khoản mới hay không. { $reason }
# review: new
gtk-built-in = { $app } (có sẵn)
# review: new
gtk-offered-for-new = Đề xuất cho tài khoản mới
# review: new
gtk-edit-button = Sửa...
# review: new
gtk-remove-app-ask = Gỡ ứng dụng đăng nhập { $app } và bí mật máy khách đã lưu của nó?
# review: new
gtk-sign-in-apps-intro = Ứng dụng đăng nhập cho phép tài khoản đăng nhập qua trình duyệt. Ứng dụng bị tắt sẽ không được đề xuất cho tài khoản mới; các tài khoản đang dùng nó vẫn hoạt động bình thường.

## Tác nhân AI

# review: new
gtk-agent-it-may = Hành động được phép
# review: new
gtk-agent-accounts = Tài khoản được phép
# review: new
gtk-never-used = Chưa từng dùng
# review: new
gtk-last-used = Dùng lần cuối { $date }
# review: new
gtk-forget-program = Xóa chương trình này?
# review: new
gtk-forget-program-detail = Các quyền của chương trình và lịch sử hoạt động của các tác nhân của nó sẽ bị xóa. Bạn sẽ được hỏi lại quyền vào lần tới chương trình kết nối.
# review: new
gtk-no-agents-yet = Chưa có tác nhân nào yêu cầu dùng thư của bạn.
# review: new
gtk-nothing-yet = Chưa có gì.

## Cài đặt

# review: new
gtk-preferences = Cài đặt
# review: new
gtk-notify-subtitle = Chỉ khi Inbox Classic đang chạy ở chế độ nền

## Mục trên màn hình nền và trang của các kho phần mềm

# linux/data/com.inboxclassic.InboxClassic.desktop and .metainfo.xml, made by the build. The keywords are the words a
# search of the applications finds Inbox Classic by, each ended by a semicolon, in your language only: the English
# ones are added before them
# review: new
gtk-desktop-generic-name = Ứng dụng thư
# review: new
gtk-desktop-comment = Đọc và viết email: một chương trình thư nhanh, đơn giản
# review: new
gtk-desktop-keywords = thư;thư điện tử;hộp thư;hộp thư đến;ứng dụng thư;
# review: new
gtk-metainfo-summary = Một chương trình thư nhanh, đơn giản
# review: new
gtk-metainfo-description = Inbox Classic đọc và viết email. Bố cục cổ điển của ứng dụng có thư mục ở bên trái, danh sách thư ở phía trên và thư đang chọn ở bên dưới. Ứng dụng hoạt động với các tài khoản IMAP và SMTP tương thích, và đăng nhập vào Outlook.com và Microsoft 365 qua trình duyệt.
# review: new
gtk-metainfo-feature-sanitized = Tập lệnh và nội dung động khác trong thư bị loại bỏ; ảnh từ internet chỉ được tải khi bạn cho phép
# review: new
gtk-metainfo-feature-search = Tìm trong chủ đề, người gửi, người nhận, tên tệp đính kèm và nội dung thư bằng các toán tử quen thuộc kiểu Gmail
# review: new
gtk-metainfo-feature-replies = Thư trả lời tự thu gọn các thư trước đó mà chúng trích dẫn
# review: new
gtk-metainfo-feature-offline = Thư đã tải xuống vẫn đọc được khi ngoại tuyến trong thời gian bản sao cục bộ còn được giữ; thông tin đăng nhập thường được lưu trong vòng khóa của hệ thống khi có thể
