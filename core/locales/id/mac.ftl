# Draf terjemahan bahasa Indonesia, menunggu tinjauan penutur asli.
# The words of the Mac app's own windows (mac/Sources), ids starting with mac-; the menus and the words every platform
# shares are in app.ftl and core.ftl. Placeables in { $braces } are filled in by the app. Mac conventions: an ellipsis
# (…) after a command that asks for more, Title Case in menus and on buttons, curly quotes and apostrophes.

## The app and its menus

mac-quit = Keluar dari Inbox Classic
mac-settings = Pengaturan…
mac-services = Layanan
mac-hide = Sembunyikan Inbox Classic
mac-hide-others = Sembunyikan Lainnya
mac-show-all = Tampilkan Semua
mac-check-updates = Periksa Pembaruan…
mac-close-window = Tutup Jendela
mac-redo = Ulangi
mac-cut = Potong
mac-paste = Tempel
mac-menu-window = Jendela
mac-minimize = Minimalkan
mac-zoom = Perbesar
mac-no-updates = Versi Inbox Classic ini tidak mendukung pembaruan otomatis. Unduh versi terbaru dari inboxclassic.com.

## Settings

mac-settings-title = Pengaturan
# the Mac only: Sparkle's automatic check for a new version, in General
mac-check-updates-automatically = Periksa pembaruan secara otomatis
# the title of that group, in the label column of the pane
mac-settings-updates = Pembaruan

## Dialogs

mac-choose = Pilih

## The main window

mac-still-running-detail = Inbox Classic tetap memeriksa email baru di latar belakang. Klik ikonnya di Dock untuk membuka aplikasi.
mac-outbox-waiting = { $count } pesan di Kotak Keluar
mac-sending = Mengirim { $subject }…
mac-checking = Memeriksa pesan baru di { $account }…
mac-account-said = { $account }: { $message }
mac-not-bundle = Salinan Inbox Classic ini bukan bundel aplikasi, jadi tidak dapat menjadi aplikasi email default.
mac-not-made-default = Inbox Classic tidak dijadikan aplikasi email default: { $reason }
mac-tool-search = Cari

## The folders and the message list

mac-still-indexing-more = Teks { $count } pesan masih diindeks, jadi hasil lain mungkin segera ditemukan.
mac-results-everywhere =
    { $count ->
        [0] Tidak ada hasil untuk “{ $words }” di semua folder
       *[other] { $count } hasil untuk “{ $words }” di semua folder
    }
mac-results-in =
    { $count ->
        [0] Tidak ada hasil untuk “{ $words }” di { $folder }
       *[other] { $count } hasil untuk “{ $words }” di { $folder }
    }
mac-still-indexing = teks { $count } pesan masih diindeks
mac-folder-unread = { $folder }, { $count } belum dibaca
mac-import-messages = Impor Pesan
mac-save-messages = Simpan Pesan
mac-save-attachments-menu = Simpan Lampiran…
mac-files-not-saved = { $failed } dari { $count } file tidak dapat disimpan.
mac-no-calendar-app = Undangan tidak dapat dibuka. Pastikan ada aplikasi kalender yang diatur untuk membuka file .ics di Mac ini.
mac-file-not-saved = File tidak dapat disimpan.
mac-unsubscribing = Mengirim permintaan berhenti berlangganan ke { $target }…
mac-loading-list = Memuat…

## The compose window

mac-bold = Tebal
mac-italic = Miring
mac-underline = Garis Bawah
mac-bcc = Bcc
mac-command-click-to-open = ⌘-klik untuk membuka
mac-saving-to-drafts = Menyimpan ke Draf…
mac-dont-save = Jangan Simpan

## The reading pane

mac-files = { $count } file

## Accounts

mac-next = Berikutnya
mac-name-placeholder = Budi Santoso
mac-more-sign-in-options = Opsi masuk lainnya…
mac-add-sign-in-app = Tambahkan aplikasi masuk…
mac-looking-up = Mencari pengaturan { $domain }…
mac-add-button = Tambah…
mac-properties-button = Properti…
mac-signature-button = Tanda Tangan…
mac-security-button = Keamanan…
mac-sign-in-apps-button = Aplikasi Masuk…

## AI agents

mac-forget-program = Hapus izin tersimpan program ini dan riwayat aktivitas agennya?
mac-forget-program-detail = Izin program ini akan dihapus. Anda akan dimintai izin lagi saat program ini terhubung berikutnya.

## Sign-in apps

mac-checking-issuer = Memeriksa { $issuer }…
mac-edit-button = Edit…
mac-use-for-new-accounts = Gunakan { $name } untuk akun baru
mac-built-in = { $name } (bawaan)

## Other windows

mac-new-folder-button = Folder Baru…
mac-edit-link = Edit Tautan…
