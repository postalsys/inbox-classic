# Bản nháp tiếng Việt, đang chờ người bản ngữ duyệt.
# Chữ trong các cửa sổ riêng của ứng dụng Windows (app/src), các id bắt đầu bằng win-. Ứng dụng điền các chỗ giữ chỗ
# trong { $braces }; dấu & đánh dấu chữ cái của menu hoặc nút (&& là dấu và).

## Cửa sổ chính

win-still-running-detail = Inbox Classic vẫn tiếp tục kiểm tra thư mới ở chế độ nền. Bấm vào biểu tượng để mở ứng dụng. Để thoát, bấm chuột phải vào biểu tượng và dùng menu của nó.
win-default-app-not-installed = Bản Inbox Classic này chưa được cài đặt, nên Windows không liệt kê nó là ứng dụng thư. Hãy cài đặt để có thể chọn nó.
win-default-app-settings = Windows sẽ mở thiết đặt Ứng dụng mặc định. Hãy chọn Inbox Classic để mở liên kết MAILTO.
win-no-unread = Không có thư chưa đọc
win-unread-messages = { $count } thư chưa đọc
win-print-failed = Không thể in thư.
win-print-title-of = In - { $subject }
win-no-bodies = Không thể hiển thị nội dung thư.
win-webview-failed = Không thể tạo WebView2.
win-webview-missing = Môi trường chạy WebView2 không khả dụng.
win-list-loading = Đang tải...

## Các nút và chữ dùng trong nhiều cửa sổ

win-delete-button = &Xóa
win-find-label = &Tìm:
win-save-as-button = Lưu dưới dạn&g...
win-too-many-files = Quá nhiều tệp cùng lúc: hãy chọn ít tệp hơn.

## Hộp thư đi


## Cửa sổ soạn thư

win-editor-failed = Không thể soạn thư.
win-ctrl-click-to-open = ({ $ctrl }+bấm để mở)
win-format-bold = Đậm ({ $ctrl }+B)
win-format-italic = Nghiêng ({ $ctrl }+I)
win-format-underline = Gạch dưới ({ $ctrl }+U)
win-format-link = Siêu liên kết ({ $ctrl }+K)
win-show-cc = &Cc
win-show-bcc = &Bcc
win-signature-title = Chữ ký: { $account }

## Thư mục, danh sách thư và ngăn đọc

win-search-found-all = { $count ->
    [0] Không có kết quả cho “{ $words }” trong tất cả thư mục
   *[other] { $count } kết quả cho “{ $words }” trong tất cả thư mục
}
win-search-found-in = { $count ->
    [0] Không có kết quả cho “{ $words }” trong { $folder }
   *[other] { $count } kết quả cho “{ $words }” trong { $folder }
}
win-search-indexing = vẫn đang lập chỉ mục văn bản của { $count } thư
win-no-match-indexing = Văn bản của { $count } thư vẫn đang được lập chỉ mục, nên có thể sớm tìm thấy thêm.
win-files = { $count } tệp
win-save-attachments = &Lưu tệp đính kèm...
win-files-not-saved = Không thể lưu { $failed } trong số { $count } tệp.
win-new-folder-in-highlighted = Thư mục mới sẽ được tạo bên trong thư mục đã chọn.
win-delete-folder-ask = Xóa thư mục “{ $folder }” cùng các thư và thư mục con trong đó? Thư mục cũng bị xóa trên máy chủ.
win-rename = Đổ&i tên...
win-messages-not-saved = Không thể lưu các thư.
win-messages-not-forwarded = Không thể chuyển tiếp các thư.

## Tài khoản

win-sign-in-google = Đăng nhập bằng Google
win-sign-in-microsoft = Đăng nhập bằng Microsoft
win-next = &Tiếp >
win-your-account = tài khoản của bạn
win-browser-sign-in = (đăng nhập qua trình duyệt)
win-add = &Thêm...
win-properties-button = Thuộc tín&h...
win-signature-button = Chữ &ký...
win-sign-in-apps-button = Ứng dụng đăng &nhập...

## Tác nhân AI

win-dont-allow = &Không cho phép
win-col-address = Địa chỉ
win-never-written-to = Chưa từng viết thư tới
win-book-find-label = Nhập tên hoặc địa chỉ email:
win-send = &Gửi
win-dont-send = &Không gửi
win-unsubscribe = &Hủy đăng ký
win-dont-unsubscribe = &Không hủy đăng ký
win-forget-program-ask = Xóa các quyền đã lưu của chương trình này và lịch sử hoạt động của các tác nhân của nó? Chương trình sẽ không bị gỡ cài đặt. Bạn sẽ được yêu cầu cấp quyền lại vào lần tới chương trình kết nối.
win-clear-log-ask = Xóa lịch sử hoạt động của các tác nhân? Thao tác này không hoàn tác các thay đổi mà tác nhân đã thực hiện.
win-agent-programs = Các chương trình có tác nhân đã yêu cầu &quyền truy cập thư của bạn:
win-change = &Thay đổi...
# Tools > AI Agents: takes back everything the selected program did in a span the user picks
win-undo-since = H&oàn tác từ...
win-take-back = &Hoàn tác
win-what-agents-did = Hoạt động của tác &nhân:
# under the log of Tools > AI Agents: what the selected row of reads covers (the start and end of its hour), or how to see it
win-agent-reads = Những gì đã được đọc từ { $from } đến { $to }:
win-agent-reads-hint = Chọn một dòng hoạt động đọc ở trên để xem những gì đã được đọc.

## Ứng dụng đăng nhập

win-built-in = (có sẵn)
win-edit = &Sửa...

## Tùy chọn

win-folders-hide = Ẩn danh sách thư mục
win-folders-pin = Giữ danh sách thư mục bên cạnh thư
win-folders-show = Hiện thư mục

## Trình cài đặt

# the installer's own words (installer/inbox-classic.nsi), made into installer/languages.nsh by the build;
# { $version } and { $installed } are version numbers, 0.18.0
win-installer-start = Khởi động Inbox Classic
win-installer-welcome-new = Trình cài đặt sẽ cài Inbox Classic { $version }, một chương trình email.

    Không cần quyền quản trị viên, ứng dụng chỉ được cài cho người dùng Windows hiện tại.
win-installer-welcome-same =
    Inbox Classic { $version } đã được cài đặt. Trình cài đặt sẽ cài lại ứng dụng.

    Tài khoản và thư của bạn được giữ nguyên.
win-installer-welcome-update =
    Trình cài đặt sẽ cập nhật Inbox Classic { $installed } lên { $version }.

    Nếu ứng dụng đang chạy, nó sẽ được đóng trước. Tài khoản và thư của bạn được giữ nguyên.
win-installer-older-ask = Inbox Classic { $installed } đã được cài đặt, mới hơn { $version }. Vẫn cài phiên bản cũ hơn?
win-installer-still-running = Inbox Classic vẫn đang chạy. Hãy đóng ứng dụng rồi thử lại.
win-installer-remove-mail-ask = Xóa cả dữ liệu cục bộ của Inbox Classic, bao gồm tài khoản, thư đã tải xuống, thư trong hàng đợi, cài đặt, liên hệ, quy tắc và khóa mã hóa? Thư trên máy chủ và các mục trong kho thông tin xác thực của hệ thống vẫn được giữ lại.
