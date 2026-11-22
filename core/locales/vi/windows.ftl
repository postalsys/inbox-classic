# Bản nháp tiếng Việt, đang chờ người bản ngữ duyệt.
# Chữ trong các cửa sổ riêng của ứng dụng Windows (app/src), các id bắt đầu bằng win-. Ứng dụng điền các chỗ giữ chỗ
# trong { $braces }; dấu & đánh dấu chữ cái của menu hoặc nút (&& là dấu và).

## Cửa sổ chính

# review: new
win-still-running-detail = Inbox Classic vẫn tiếp tục kiểm tra thư mới ở chế độ nền. Bấm vào biểu tượng để mở ứng dụng. Để thoát, bấm chuột phải vào biểu tượng và dùng menu của nó.
# review: new
win-default-app-not-installed = Bản Inbox Classic này chưa được cài đặt, nên Windows không liệt kê nó là ứng dụng thư. Hãy cài đặt để có thể chọn nó.
# review: new
win-default-app-settings = Windows sẽ mở thiết đặt Ứng dụng mặc định. Hãy chọn Inbox Classic để mở liên kết MAILTO.
# review: new
win-no-unread = Không có thư chưa đọc
# review: new
win-unread-messages = { $count } thư chưa đọc
# review: new
win-print-failed = Không thể in thư.
# review: new
win-print-title-of = In - { $subject }
# review: new
win-no-bodies = Không thể hiển thị nội dung thư.
# review: new
win-webview-failed = Không thể tạo WebView2.
# review: new
win-webview-missing = Không có thời gian chạy WebView2.
# review: new
win-list-loading = Đang tải...

## Các nút và chữ dùng trong nhiều cửa sổ

# review: new
win-delete-button = &Xóa
# review: new
win-find-label = &Tìm:
# review: new
win-save-as-button = Lưu dưới dạn&g...
# review: new
win-too-many-files = Quá nhiều tệp cùng lúc: hãy chọn ít tệp hơn.

## Hộp thư đi


## Cửa sổ soạn thư

# review: new
win-editor-failed = Không thể soạn thư.
# review: new
win-ctrl-click-to-open = ({ $ctrl }+bấm để mở)
# review: new
win-format-bold = Đậm ({ $ctrl }+B)
# review: new
win-format-italic = Nghiêng ({ $ctrl }+I)
# review: new
win-format-underline = Gạch dưới ({ $ctrl }+U)
# review: new
win-format-link = Siêu liên kết ({ $ctrl }+K)
# review: new
win-show-cc = &Cc
# review: new
win-show-bcc = &Bcc
# review: new
win-signature-title = Chữ ký: { $account }

## Thư mục, danh sách thư và ngăn đọc

# review: new
win-search-found-all = { $count ->
    [0] Không có kết quả cho “{ $words }” trong tất cả thư mục
   *[other] { $count } kết quả cho “{ $words }” trong tất cả thư mục
}
# review: new
win-search-found-in = { $count ->
    [0] Không có kết quả cho “{ $words }” trong { $folder }
   *[other] { $count } kết quả cho “{ $words }” trong { $folder }
}
# review: new
win-search-indexing = vẫn đang lập chỉ mục văn bản của { $count } thư
# review: new
win-no-match-indexing = Văn bản của { $count } thư vẫn đang được lập chỉ mục, nên có thể sớm tìm thấy thêm.
# review: new
win-files = { $count } tệp
# review: new
win-save-attachments = &Lưu tệp đính kèm...
# review: new
win-files-not-saved = Không thể lưu { $failed } trong số { $count } tệp.
# review: new
win-new-folder-in-highlighted = Thư mục mới sẽ được tạo bên trong thư mục đã chọn.
# review: new
win-delete-folder-ask = Xóa thư mục “{ $folder }” cùng các thư và thư mục con trong đó? Thư mục cũng bị xóa trên máy chủ.
# review: new
win-rename = Đổi &tên...
# review: new
win-messages-not-saved = Không thể lưu các thư.
# review: new
win-messages-not-forwarded = Không thể chuyển tiếp các thư.

## Tài khoản

# review: new
win-sign-in-google = Đăng nhập bằng Google
# review: new
win-sign-in-microsoft = Đăng nhập bằng Microsoft
# review: new
win-next = &Tiếp >
# review: new
win-your-account = tài khoản của bạn
# review: new
win-browser-sign-in = (đăng nhập qua trình duyệt)
# review: new
win-add = &Thêm...
# review: new
win-properties-button = Thuộc tín&h...
# review: new
win-signature-button = Chữ &ký...
# review: new
win-sign-in-apps-button = Ứng dụng đăng &nhập...

## Tác nhân AI

# review: new
win-dont-allow = &Không cho phép
# review: new
win-col-address = Địa chỉ
# review: new
win-never-written-to = Chưa từng viết thư
# review: new
win-book-find-label = Nhập tên hoặc địa chỉ email:
# review: new
win-send = &Gửi
# review: new
win-dont-send = &Không gửi
# review: new
win-unsubscribe = &Hủy đăng ký
# review: new
win-dont-unsubscribe = &Không hủy đăng ký
# review: new
win-forget-program-ask = Xóa các quyền đã lưu của chương trình này và lịch sử hoạt động của các tác nhân của nó? Chương trình sẽ không bị gỡ cài đặt. Bạn sẽ được hỏi lại quyền vào lần tới chương trình kết nối.
# review: new
win-clear-log-ask = Xóa lịch sử hoạt động của các tác nhân? Thao tác này không hoàn tác các thay đổi mà tác nhân đã thực hiện.
# review: new
win-agent-programs = &Các chương trình có tác nhân đã yêu cầu quyền truy cập thư của bạn:
# review: new
win-change = &Thay đổi...
# Tools > AI Agents: takes back everything the selected program did in a span the user picks
# review: new
win-undo-since = Hoàn tác &từ...
# review: new
win-take-back = &Hoàn tác
# review: new
win-what-agents-did = Hoạt động của tác &nhân:
# under the log of Tools > AI Agents: what the selected row of reads covers (the start and end of its hour), or how to see it
# review: new
win-agent-reads = Những gì đã được đọc từ { $from } đến { $to }:
# review: new
win-agent-reads-hint = Chọn một hàng lượt đọc ở trên để xem những gì đã được đọc.

## Ứng dụng đăng nhập

# review: new
win-built-in = (có sẵn)
# review: new
win-edit = &Sửa...

## Tùy chọn

# review: new
win-folders-hide = Ẩn danh sách thư mục
# review: new
win-folders-pin = Giữ danh sách thư mục bên cạnh thư
# review: new
win-folders-show = Hiện thư mục

## Trình cài đặt

# the installer's own words (installer/inbox-classic.nsi), made into installer/languages.nsh by the build;
# { $version } and { $installed } are version numbers, 0.18.0
# review: new
win-installer-start = Khởi động Inbox Classic
# review: new
win-installer-welcome-new =
    Trình cài đặt sẽ cài Inbox Classic { $version }, một chương trình email.

    Không cần quyền quản trị viên, ứng dụng chỉ được cài cho tài khoản của bạn.
# review: new
win-installer-welcome-same =
    Inbox Classic { $version } đã được cài đặt. Trình cài đặt sẽ cài lại ứng dụng.

    Tài khoản và thư của bạn được giữ nguyên.
# review: new
win-installer-welcome-update =
    Trình cài đặt sẽ cập nhật Inbox Classic { $installed } lên { $version }.

    Nếu ứng dụng đang chạy, nó sẽ được đóng trước. Tài khoản và thư của bạn được giữ nguyên.
# review: new
win-installer-older-ask = Inbox Classic { $installed } đã được cài đặt, mới hơn { $version }. Vẫn cài phiên bản cũ hơn?
# review: new
win-installer-still-running = Inbox Classic vẫn đang chạy. Hãy đóng ứng dụng rồi thử lại.
# review: new
win-installer-remove-mail-ask = Xóa cả dữ liệu cục bộ của Inbox Classic, bao gồm tài khoản, thư đã tải xuống, thư trong hàng đợi, cài đặt, liên hệ, quy tắc và khóa mã hóa? Thư trên máy chủ và các mục trong kho thông tin xác thực của hệ thống vẫn được giữ lại.
