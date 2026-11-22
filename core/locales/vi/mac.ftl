# Bản nháp tiếng Việt, đang chờ người bản ngữ duyệt.
# Chữ trong các cửa sổ riêng của ứng dụng Mac (mac/Sources), các id bắt đầu bằng mac-; menu và chữ dùng chung cho mọi
# nền tảng nằm trong app.ftl và core.ftl. Ứng dụng điền các chỗ giữ chỗ trong { $braces }. Quy ước của Mac: dấu ba
# chấm (…) sau lệnh cần hỏi thêm, dấu ngoặc kép cong; tiếng Việt của Apple viết hoa chữ đầu câu.

## Ứng dụng và các menu

# review: new
mac-quit = Thoát Inbox Classic
# review: new
mac-settings = Cài đặt…
# review: new
mac-services = Dịch vụ
# review: new
mac-hide = Ẩn Inbox Classic
# review: new
mac-hide-others = Ẩn các mục khác
# review: new
mac-show-all = Hiện tất cả
# review: new
mac-check-updates = Kiểm tra cập nhật…
# review: new
mac-close-window = Đóng cửa sổ
# review: new
mac-redo = Làm lại
# review: new
mac-cut = Cắt
# review: new
mac-paste = Dán
# review: new
mac-menu-window = Cửa sổ
# review: new
mac-minimize = Thu nhỏ
# review: new
mac-zoom = Thu/Phóng
# review: new
mac-no-updates = Phiên bản Inbox Classic này không hỗ trợ cập nhật tự động. Hãy tải phiên bản mới nhất từ inboxclassic.com.

## Cài đặt

# review: new
mac-settings-title = Cài đặt
# the Mac only: Sparkle's automatic check for a new version, in General
# review: new
mac-check-updates-automatically = Tự động kiểm tra cập nhật
# the title of that group, in the label column of the pane
# review: new
mac-settings-updates = Cập nhật

## Hộp thoại

# review: new
mac-choose = Chọn

## Cửa sổ chính

# review: new
mac-still-running-detail = Inbox Classic vẫn tiếp tục kiểm tra thư mới ở chế độ nền. Bấm vào biểu tượng của ứng dụng trong Dock để mở.
# review: new
mac-outbox-waiting = { $count } thư trong Hộp thư đi
# review: new
mac-sending = Đang gửi { $subject }…
# review: new
mac-checking = Đang kiểm tra thư mới trên { $account }…
# review: new
mac-account-said = { $account }: { $message }
# review: new
mac-not-bundle = Bản Inbox Classic này không phải là gói ứng dụng, nên không thể làm ứng dụng thư mặc định.
# review: new
mac-not-made-default = Chưa đặt được Inbox Classic làm ứng dụng thư mặc định: { $reason }
# review: new
mac-tool-search = Tìm kiếm

## Thư mục và danh sách thư

# review: new
mac-still-indexing-more = Văn bản của { $count } thư vẫn đang được lập chỉ mục, nên có thể sớm tìm thấy thêm.
# review: new
mac-results-everywhere =
    { $count ->
        [0] Không có kết quả cho “{ $words }” trong tất cả thư mục
       *[other] { $count } kết quả cho “{ $words }” trong tất cả thư mục
    }
# review: new
mac-results-in =
    { $count ->
        [0] Không có kết quả cho “{ $words }” trong { $folder }
       *[other] { $count } kết quả cho “{ $words }” trong { $folder }
    }
# review: new
mac-still-indexing = vẫn đang lập chỉ mục văn bản của { $count } thư
# review: new
mac-folder-unread = { $folder }, { $count } chưa đọc
# review: new
mac-import-messages = Nhập thư
# review: new
mac-save-messages = Lưu thư
# review: new
mac-save-attachments-menu = Lưu tệp đính kèm…
# review: new
mac-files-not-saved = Không thể lưu { $failed } trong số { $count } tệp.
# review: new
mac-no-calendar-app = Không thể mở lời mời. Hãy kiểm tra xem đã có ứng dụng lịch nào được thiết lập để mở tệp .ics trên máy Mac này chưa.
# review: new
mac-file-not-saved = Không thể lưu tệp.
# review: new
mac-unsubscribing = Đang hủy đăng ký khỏi { $target }…
# review: new
mac-loading-list = Đang tải…

## Cửa sổ soạn thư

# review: new
mac-bold = Đậm
# review: new
mac-italic = Nghiêng
# review: new
mac-underline = Gạch dưới
# review: new
mac-bcc = Bcc
# review: new
mac-command-click-to-open = ⌘-bấm để mở
# review: new
mac-saving-to-drafts = Đang lưu vào Thư nháp…
# review: new
mac-dont-save = Không lưu

## Ngăn đọc

# review: new
mac-files = { $count } tệp

## Tài khoản

# review: new
mac-next = Tiếp
# review: new
mac-name-placeholder = Nguyễn Văn An
# review: new
mac-more-sign-in-options = Tùy chọn đăng nhập khác…
# review: new
mac-add-sign-in-app = Thêm ứng dụng đăng nhập…
# review: new
mac-looking-up = Đang tìm thiết đặt của { $domain }…
# review: new
mac-add-button = Thêm…
# review: new
mac-properties-button = Thuộc tính…
# review: new
mac-signature-button = Chữ ký…
# review: new
mac-security-button = Bảo mật…
# review: new
mac-sign-in-apps-button = Ứng dụng đăng nhập…

## Tác nhân AI

# review: new
mac-forget-program = Xóa chương trình này và lịch sử hoạt động của các tác nhân của nó?
# review: new
mac-forget-program-detail = Các quyền của chương trình sẽ bị xóa. Bạn sẽ được hỏi lại quyền vào lần tới chương trình kết nối.

## Ứng dụng đăng nhập

# review: new
mac-checking-issuer = Đang kiểm tra { $issuer }…
# review: new
mac-edit-button = Sửa…
# review: new
mac-use-for-new-accounts = Dùng { $name } cho tài khoản mới
# review: new
mac-built-in = { $name } (có sẵn)

## Các cửa sổ khác

# review: new
mac-new-folder-button = Thư mục mới…
# review: new
mac-edit-link = Sửa liên kết…
