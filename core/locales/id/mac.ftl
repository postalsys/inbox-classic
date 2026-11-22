# Draf terjemahan bahasa Indonesia, menunggu tinjauan penutur asli.
# The words of the Mac app's own windows (mac/Sources), ids starting with mac-; the menus and the words every platform
# shares are in app.ftl and core.ftl. Placeables in { $braces } are filled in by the app. Mac conventions: an ellipsis
# (…) after a command that asks for more, Title Case in menus and on buttons, curly quotes and apostrophes.

## The app and its menus

# review: new
mac-quit = Keluar dari Inbox Classic
# review: new
mac-settings = Pengaturan…
# review: new
mac-services = Layanan
# review: new
mac-hide = Sembunyikan Inbox Classic
# review: new
mac-hide-others = Sembunyikan Lainnya
# review: new
mac-show-all = Tampilkan Semua
# review: new
mac-check-updates = Periksa Pembaruan…
# review: new
mac-close-window = Tutup Jendela
# review: new
mac-redo = Ulangi
# review: new
mac-cut = Potong
# review: new
mac-paste = Tempel
# review: new
mac-menu-window = Jendela
# review: new
mac-minimize = Minimalkan
# review: new
mac-zoom = Perbesar
# review: new
mac-no-updates = Versi Inbox Classic ini tidak mendukung pembaruan otomatis. Unduh versi terbaru dari inboxclassic.com.

## Settings

# review: new
mac-settings-title = Pengaturan
# the Mac only: Sparkle's automatic check for a new version, in General
# review: new
mac-check-updates-automatically = Periksa pembaruan secara otomatis
# the title of that group, in the label column of the pane
# review: new
mac-settings-updates = Pembaruan

## Dialogs

# review: new
mac-choose = Pilih

## The main window

# review: new
mac-still-running-detail = Inbox Classic tetap memeriksa email baru di latar belakang. Klik ikonnya di Dock untuk membuka aplikasi.
# review: new
mac-outbox-waiting = { $count } pesan di Kotak Keluar
# review: new
mac-sending = Mengirim { $subject }…
# review: new
mac-checking = Memeriksa pesan baru di { $account }…
# review: new
mac-account-said = { $account }: { $message }
# review: new
mac-not-bundle = Salinan Inbox Classic ini bukan bundel aplikasi, jadi tidak dapat menjadi aplikasi email default.
# review: new
mac-not-made-default = Inbox Classic tidak dijadikan aplikasi email default: { $reason }
# review: new
mac-tool-search = Cari

## The folders and the message list

# review: new
mac-still-indexing-more = Teks { $count } pesan masih diindeks, jadi hasil lain mungkin segera ditemukan.
# review: new
mac-results-everywhere =
    { $count ->
        [0] Tidak ada hasil untuk “{ $words }” di semua folder
       *[other] { $count } hasil untuk “{ $words }” di semua folder
    }
# review: new
mac-results-in =
    { $count ->
        [0] Tidak ada hasil untuk “{ $words }” di { $folder }
       *[other] { $count } hasil untuk “{ $words }” di { $folder }
    }
# review: new
mac-still-indexing = teks { $count } pesan masih diindeks
# review: new
mac-folder-unread = { $folder }, { $count } belum dibaca
# review: new
mac-import-messages = Impor Pesan
# review: new
mac-save-messages = Simpan Pesan
# review: new
mac-save-attachments-menu = Simpan Lampiran…
# review: new
mac-files-not-saved = { $failed } dari { $count } file tidak dapat disimpan.
# review: new
mac-no-calendar-app = Undangan tidak dapat dibuka. Pastikan ada aplikasi kalender yang diatur untuk membuka file .ics di Mac ini.
# review: new
mac-file-not-saved = File tidak dapat disimpan.
# review: new
mac-unsubscribing = Mengirim permintaan berhenti berlangganan ke { $target }…
# review: new
mac-loading-list = Memuat…

## The compose window

# review: new
mac-bold = Tebal
# review: new
mac-italic = Miring
# review: new
mac-underline = Garis Bawah
# review: new
mac-bcc = Bcc
# review: new
mac-command-click-to-open = ⌘-klik untuk membuka
# review: new
mac-saving-to-drafts = Menyimpan ke Draf…
# review: new
mac-dont-save = Jangan Simpan

## The reading pane

# review: new
mac-files = { $count } file

## Accounts

# review: new
mac-next = Berikutnya
# review: new
mac-name-placeholder = Budi Santoso
# review: new
mac-more-sign-in-options = Opsi masuk lainnya…
# review: new
mac-add-sign-in-app = Tambahkan aplikasi masuk…
# review: new
mac-looking-up = Mencari pengaturan { $domain }…
# review: new
mac-add-button = Tambah…
# review: new
mac-properties-button = Properti…
# review: new
mac-signature-button = Tanda Tangan…
# review: new
mac-security-button = Keamanan…
# review: new
mac-sign-in-apps-button = Aplikasi Masuk…

## AI agents

# review: new
mac-forget-program = Hapus program ini dan riwayat aktivitas agennya?
# review: new
mac-forget-program-detail = Izin program ini akan dihapus. Anda akan dimintai izin lagi saat program ini terhubung berikutnya.

## Sign-in apps

# review: new
mac-checking-issuer = Memeriksa { $issuer }…
# review: new
mac-edit-button = Edit…
# review: new
mac-use-for-new-accounts = Gunakan { $name } untuk akun baru
# review: new
mac-built-in = { $name } (bawaan)

## Other windows

# review: new
mac-new-folder-button = Folder Baru…
# review: new
mac-edit-link = Edit Tautan…
