# Bản nháp tiếng Việt, đang chờ người bản ngữ duyệt.
# Chữ trong các cửa sổ riêng của ứng dụng Mac (mac/Sources), các id bắt đầu bằng mac-; menu và chữ dùng chung cho mọi
# nền tảng nằm trong app.ftl và core.ftl. Ứng dụng điền các chỗ giữ chỗ trong { $braces }. Quy ước của Mac: dấu ba
# chấm (…) sau lệnh cần hỏi thêm, dấu ngoặc kép cong; tiếng Việt của Apple viết hoa chữ đầu câu.

## Ứng dụng và các menu

mac-quit = Thoát Inbox Classic
mac-settings = Cài đặt…
mac-services = Dịch vụ
mac-hide = Ẩn Inbox Classic
mac-hide-others = Ẩn các mục khác
mac-show-all = Hiện tất cả
mac-check-updates = Kiểm tra cập nhật…
mac-close-window = Đóng cửa sổ
mac-redo = Làm lại
mac-cut = Cắt
mac-paste = Dán
mac-menu-window = Cửa sổ
mac-minimize = Thu nhỏ
mac-zoom = Thu/Phóng
mac-no-updates = Phiên bản Inbox Classic này không hỗ trợ cập nhật tự động. Hãy tải phiên bản mới nhất từ inboxclassic.com.

## Cài đặt

mac-settings-title = Cài đặt
# the Mac only: Sparkle's automatic check for a new version, in General
mac-check-updates-automatically = Tự động kiểm tra cập nhật
# the title of that group, in the label column of the pane
mac-settings-updates = Cập nhật

## Hộp thoại

mac-choose = Chọn

## Cửa sổ chính

mac-still-running-detail = Inbox Classic vẫn tiếp tục kiểm tra thư mới ở chế độ nền. Bấm vào biểu tượng của ứng dụng trong Dock để mở.
mac-outbox-waiting = { $count } thư trong Hộp thư đi
mac-sending = Đang gửi { $subject }…
mac-checking = Đang kiểm tra thư mới trên { $account }…
mac-account-said = { $account }: { $message }
mac-not-bundle = Bản Inbox Classic này không phải là gói ứng dụng, nên không thể làm ứng dụng thư mặc định.
mac-not-made-default = Chưa đặt được Inbox Classic làm ứng dụng thư mặc định: { $reason }
mac-tool-search = Tìm kiếm

## Thư mục và danh sách thư

mac-still-indexing-more = Văn bản của { $count } thư vẫn đang được lập chỉ mục, nên có thể sớm tìm thấy thêm.
mac-results-everywhere =
    { $count ->
        [0] Không có kết quả cho “{ $words }” trong tất cả thư mục
       *[other] { $count } kết quả cho “{ $words }” trong tất cả thư mục
    }
mac-results-in =
    { $count ->
        [0] Không có kết quả cho “{ $words }” trong { $folder }
       *[other] { $count } kết quả cho “{ $words }” trong { $folder }
    }
mac-still-indexing = vẫn đang lập chỉ mục văn bản của { $count } thư
mac-folder-unread = { $folder }, { $count } chưa đọc
mac-import-messages = Nhập thư
mac-save-messages = Lưu thư
mac-save-attachments-menu = Lưu tệp đính kèm…
mac-files-not-saved = Không thể lưu { $failed } trong số { $count } tệp.
mac-no-calendar-app = Không thể mở lời mời. Hãy kiểm tra xem đã có ứng dụng lịch nào được thiết lập để mở tệp .ics trên máy Mac này chưa.
mac-file-not-saved = Không thể lưu tệp.
mac-unsubscribing = Đang hủy đăng ký khỏi { $target }…
mac-loading-list = Đang tải…

## Cửa sổ soạn thư

mac-bold = Đậm
mac-italic = Nghiêng
mac-underline = Gạch dưới
mac-bcc = Bcc
mac-command-click-to-open = ⌘-bấm để mở
mac-saving-to-drafts = Đang lưu vào Thư nháp…
mac-dont-save = Không lưu

## Ngăn đọc

mac-files = { $count } tệp

## Tài khoản

mac-next = Tiếp
mac-name-placeholder = Nguyễn Văn An
mac-more-sign-in-options = Tùy chọn đăng nhập khác…
mac-add-sign-in-app = Thêm ứng dụng đăng nhập…
mac-looking-up = Đang tìm thiết đặt của { $domain }…
mac-add-button = Thêm…
mac-properties-button = Thuộc tính…
mac-signature-button = Chữ ký…
mac-security-button = Bảo mật…
mac-sign-in-apps-button = Ứng dụng đăng nhập…

## Tác nhân AI

mac-forget-program = Xóa các quyền đã lưu của chương trình này và lịch sử hoạt động của các tác nhân của nó?
mac-forget-program-detail = Các quyền của chương trình sẽ bị xóa. Bạn sẽ được yêu cầu cấp quyền lại vào lần tới chương trình kết nối.

## Ứng dụng đăng nhập

mac-checking-issuer = Đang kiểm tra { $issuer }…
mac-edit-button = Sửa…
mac-use-for-new-accounts = Dùng { $name } cho tài khoản mới
mac-built-in = { $name } (có sẵn)

## Các cửa sổ khác

mac-new-folder-button = Thư mục mới…
mac-edit-link = Sửa liên kết…
