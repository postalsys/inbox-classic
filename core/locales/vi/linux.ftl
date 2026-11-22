# Bản nháp tiếng Việt, đang chờ người bản ngữ duyệt.
# Chữ trong các cửa sổ riêng của ứng dụng Linux (linux/src), các id bắt đầu bằng gtk-. Ứng dụng điền các chỗ giữ chỗ
# trong { $braces }; dấu _ đánh dấu chữ cái tắt của nút. Dùng từ của GNOME khi GNOME có.

## Cửa sổ chính

gtk-search-looks-in = Tìm kiếm trong { $place } bao gồm chủ đề, người gửi, người nhận, tên tệp đính kèm và nội dung thư. Hãy kiểm tra chính tả hoặc thử ít từ hơn.
gtk-search-still-indexing = Văn bản của { $count } thư vẫn đang được lập chỉ mục. Có thể sớm có thêm kết quả.
gtk-search-results-everywhere = { $count ->
    [0] Không có kết quả
   *[other] { $count } kết quả
} cho “{ $words }” trong tất cả thư mục
gtk-search-results-in = { $count ->
    [0] Không có kết quả
   *[other] { $count } kết quả
} cho “{ $words }” trong { $place }
gtk-search-indexing = vẫn đang lập chỉ mục văn bản của { $count } thư
gtk-list-loading = Đang tải...
gtk-menu-rename = Đổi tên...
gtk-import-one-question = Nhập thư { $file } vào { $folder }?
gtk-files-not-saved = Không thể lưu { $failed } trong số { $total } tệp.
gtk-unsubscribe-one-click =
    Rời khỏi danh sách gửi thư này?

    Inbox Classic sẽ gửi yêu cầu hủy đăng ký đến { $target }. Sẽ không có trang web nào được mở và không có email nào được gửi.
gtk-unsubscribe-mail =
    Rời khỏi danh sách gửi thư này?

    Để hủy đăng ký, hãy gửi một email đến { $target }. Inbox Classic sẽ soạn sẵn email này cho bạn. Gửi thư để xác nhận.
gtk-unsubscribe-web =
    Rời khỏi danh sách gửi thư này?

    Trang hủy đăng ký của danh sách gửi thư sẽ mở trong trình duyệt của bạn ({ $target }).
gtk-unsubscribe-failed = Không thể hủy đăng ký: { $problem }
gtk-toolbar-create-mail-menu = Soạn thư từ một tài khoản cụ thể
gtk-toolbar-send-recv-menu = Gửi và nhận thư cho một tài khoản cụ thể
gtk-main-menu = Menu chính
gtk-folder-list = Danh sách thư mục
gtk-quit = Thoát

## Cửa sổ Di chuyển và Sao chép

gtk-new-folder-at-top-of = Thư mục mới sẽ nằm ở cấp cao nhất của { $account }.

## Danh sách thư

## Trợ giúp

## Thông báo và khay hệ thống

gtk-unread-messages = { $count ->
    [0] Không có thư chưa đọc
   *[other] { $count } thư chưa đọc
}

## Menu liên kết của cửa sổ soạn thư

## Hộp thư đi

gtk-outbox-empty = Không có thư nào đang chờ gửi.
gtk-outbox-row = Đến: { $to }  ·  Vào hàng đợi { $queued }  ·  { $status }

## Ứng dụng

gtk-still-running-detail = Inbox Classic vẫn tiếp tục kiểm tra thư mới ở chế độ nền. Dùng biểu tượng của ứng dụng trên thanh trên cùng để mở hoặc thoát ứng dụng.
gtk-sign-in-again-ask =
    Đăng nhập vào { $account } bị từ chối hoặc phiên đã hết hạn.

    Đăng nhập lại trong trình duyệt?
gtk-default-app-not-installed = Bản Inbox Classic này chưa được cài đặt, nên hệ thống không liệt kê nó là ứng dụng thư. Hãy cài đặt để có thể chọn nó.
gtk-default-app-now = Inbox Classic giờ là ứng dụng thư mặc định của bạn: liên kết email sẽ mở một thư mới tại đây.
gtk-default-app-failed = Không thể đặt Inbox Classic làm ứng dụng thư mặc định.

## Các nút và chữ dùng trong nhiều cửa sổ

## Ngăn đọc

gtk-reader-date = Ngày:
gtk-reader-files = Tệp đính kèm của thư
gtk-files = { $count } tệp
gtk-save-attachments-menu = Lưu tệp đính kèm...

## Cửa sổ soạn thư

gtk-format-bold = Đậm (Ctrl+B)
gtk-format-italic = Nghiêng (Ctrl+I)
gtk-format-underline = Gạch dưới (Ctrl+U)
gtk-format-hyperlink = Siêu liên kết (Ctrl+K)
gtk-font = Phông chữ
gtk-show-cc = _Cc
gtk-show-bcc = _Bcc
gtk-save-tip = Lưu (Ctrl+S)
gtk-link-status = { $link }    (Ctrl+bấm để mở)

## Tài khoản

gtk-plain-warning = Khi không mã hóa, bất kỳ ai chặn bắt được lưu lượng mạng của bạn đều có thể đọc mật khẩu và thư của bạn. Chỉ tiếp tục nếu kết nối được bảo vệ theo cách khác. Bản thân mạng cục bộ không mã hóa dữ liệu.

    Tiếp tục?
gtk-account-name-title = Tên tài khoản
gtk-display-name-title = Tên hiển thị
gtk-turned-off-why = Tùy chọn “{ $button }” đã bị tắt trên máy tính này. { $reason }
gtk-turned-off-why-long =
    Tùy chọn “{ $button }” đã bị tắt trên máy tính này.

    { $reason }
gtk-next = Tiếp >
gtk-provider-sign-in = Đăng nhập vào { $address } trên trang web của { $provider }. Mật khẩu của bạn không được chia sẻ với Inbox Classic. Nếu tài khoản của bạn cho phép dùng mật khẩu ứng dụng để truy cập thư, bạn cũng có thể dùng một mật khẩu tạo trong thiết đặt bảo mật của tài khoản. Outlook.com và Microsoft 365 chỉ chấp nhận đăng nhập qua trình duyệt.
gtk-provider-sign-in-apps = Đăng nhập vào { $address } trên trang web của { $provider } bằng một trong các ứng dụng đăng nhập của bạn (Tùy chọn đăng nhập khác). Nếu tài khoản của bạn cho phép dùng mật khẩu ứng dụng để truy cập thư, bạn cũng có thể dùng một mật khẩu tạo trong thiết đặt bảo mật của tài khoản. Outlook.com và Microsoft 365 chỉ chấp nhận đăng nhập qua trình duyệt.
gtk-accounts-add = Thêm...
gtk-accounts-properties = Thuộc tính...
gtk-accounts-signature = Chữ ký...
gtk-accounts-sign-in-apps = Ứng dụng đăng nhập...

## Ứng dụng đăng nhập

gtk-app-server = Máy chủ { $kind }
gtk-app-port = Cổng { $kind }
gtk-app-security = Bảo mật { $kind }
gtk-issuer-found =
    Trang đăng nhập: { $page }
    Điểm cuối mã thông báo: { $endpoint }
gtk-client-id = ID máy khách
gtk-client-secret = Bí mật máy khách
gtk-scopes = Phạm vi (scopes)
gtk-redirect-uri = URI chuyển hướng
gtk-issuer-usable =
    Có thể dùng bên phát hành này.

    { $found }
gtk-app-built-in = { $app } có sẵn trong ứng dụng. Bạn chỉ có thể thay đổi việc nó có được đề xuất cho tài khoản mới hay không. { $reason }
gtk-built-in = { $app } (có sẵn)
gtk-offered-for-new = Đề xuất cho tài khoản mới
gtk-edit-button = Sửa...
gtk-remove-app-ask = Gỡ ứng dụng đăng nhập { $app } và bí mật máy khách đã lưu của nó?
gtk-sign-in-apps-intro = Ứng dụng đăng nhập cho phép tài khoản đăng nhập qua trình duyệt. Ứng dụng bị tắt sẽ không được đề xuất cho tài khoản mới; các tài khoản đang dùng nó vẫn hoạt động bình thường.

## Tác nhân AI

gtk-agent-it-may = Hành động được phép
gtk-agent-accounts = Tài khoản được phép
gtk-never-used = Chưa từng dùng
gtk-last-used = Dùng lần cuối { $date }
gtk-forget-program = Xóa các quyền đã lưu của chương trình này?
gtk-forget-program-detail = Các quyền của chương trình và lịch sử hoạt động của các tác nhân của nó sẽ bị xóa. Bạn sẽ được yêu cầu cấp quyền lại vào lần tới chương trình kết nối.
gtk-no-agents-yet = Chưa có tác nhân nào yêu cầu dùng thư của bạn.
gtk-nothing-yet = Chưa có gì.

## Cài đặt

gtk-preferences = Cài đặt
gtk-notify-subtitle = Chỉ khi cửa sổ chính không ở phía trước

## Mục trên màn hình nền và trang của các kho phần mềm

# linux/data/com.inboxclassic.InboxClassic.desktop and .metainfo.xml, made by the build. The keywords are the words a
# search of the applications finds Inbox Classic by, each ended by a semicolon, in your language only: the English
# ones are added before them
gtk-desktop-generic-name = Ứng dụng thư
gtk-desktop-comment = Đọc và viết email: một chương trình thư nhanh, đơn giản
gtk-desktop-keywords = thư;thư điện tử;hộp thư;hộp thư đến;ứng dụng thư;
gtk-metainfo-summary = Một chương trình thư nhanh, đơn giản
gtk-metainfo-description = Inbox Classic đọc và viết email. Bố cục cổ điển của ứng dụng có thư mục ở bên trái, danh sách thư ở phía trên và thư đang chọn ở bên dưới. Ứng dụng hoạt động với các tài khoản IMAP và SMTP tương thích, và đăng nhập vào Outlook.com và Microsoft 365 qua trình duyệt.
gtk-metainfo-feature-sanitized = Tập lệnh và nội dung động khác trong thư bị loại bỏ; ảnh từ internet chỉ được tải khi bạn cho phép
gtk-metainfo-feature-search = Tìm trong chủ đề, người gửi, người nhận, tên tệp đính kèm và nội dung thư bằng các toán tử quen thuộc kiểu Gmail
gtk-metainfo-feature-replies = Thư trả lời tự thu gọn các thư trước đó mà chúng trích dẫn
gtk-metainfo-feature-offline = Thư đã tải xuống vẫn đọc được khi ngoại tuyến trong thời gian bản sao cục bộ còn được giữ; thông tin đăng nhập thường được lưu trong vòng khóa của hệ thống khi có thể
