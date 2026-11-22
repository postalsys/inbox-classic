# Draf terjemahan bahasa Indonesia, menunggu tinjauan penutur asli.
# The words of the Linux app's own windows (linux/src), ids starting with gtk-. Placeables in { $braces } are filled in
# by the app; an _ marks a button's mnemonic letter. GNOME words where GNOME has them (Preferences, Quit).

## The main window

gtk-search-looks-in = Pencarian di { $place } mencakup subjek, pengirim, penerima, nama lampiran, dan teks pesan. Periksa ejaan atau coba lebih sedikit kata.
gtk-search-still-indexing = Teks { $count } pesan masih diindeks. Hasil lain mungkin segera muncul.
gtk-search-results-everywhere = { $count ->
    [0] Tidak ada hasil
   *[other] { $count } hasil
} untuk “{ $words }” di semua folder
gtk-search-results-in = { $count ->
    [0] Tidak ada hasil
   *[other] { $count } hasil
} untuk “{ $words }” di { $place }
gtk-search-indexing = teks { $count } pesan masih diindeks
gtk-list-loading = Memuat...
gtk-menu-rename = Ganti Nama...
gtk-import-one-question = Impor pesan { $file } ke { $folder }?
gtk-files-not-saved = { $failed } dari { $total } file tidak dapat disimpan.
gtk-unsubscribe-one-click =
    Keluar dari milis ini?

    Inbox Classic akan mengirim permintaan berhenti berlangganan ke { $target }. Tidak ada halaman web yang dibuka dan tidak ada email yang dikirim.
gtk-unsubscribe-mail =
    Keluar dari milis ini?

    Untuk berhenti berlangganan, kirim email ke { $target }. Inbox Classic akan menyiapkannya untuk Anda. Kirim pesan tersebut untuk mengonfirmasi.
gtk-unsubscribe-web =
    Keluar dari milis ini?

    Halaman berhenti berlangganan milis akan dibuka di browser Anda ({ $target }).
gtk-unsubscribe-failed = Tidak dapat berhenti berlangganan: { $problem }
gtk-toolbar-create-mail-menu = Tulis dari akun tertentu
gtk-toolbar-send-recv-menu = Kirim dan terima email untuk akun tertentu
gtk-main-menu = Menu Utama
gtk-folder-list = Daftar Folder
gtk-quit = Keluar

## The Move and Copy window

gtk-new-folder-at-top-of = Folder baru ditempatkan di tingkat teratas { $account }.

## The message list

## Help

## Notifications and the tray

gtk-unread-messages = { $count ->
    [0] Tidak ada pesan yang belum dibaca
   *[other] { $count } pesan belum dibaca
}

## The compose window's link menu

## The Outbox

gtk-outbox-empty = Tidak ada pesan yang menunggu untuk dikirim.
gtk-outbox-row = Kepada: { $to }  ·  Diantrekan { $queued }  ·  { $status }

## The app

gtk-still-running-detail = Inbox Classic tetap memeriksa email baru di latar belakang. Gunakan ikonnya di bilah atas untuk membuka atau keluar dari aplikasi.
gtk-sign-in-again-ask =
    Proses masuk ke { $account } ditolak atau sesinya telah berakhir.

    Masuk lagi di browser?
gtk-default-app-not-installed = Salinan Inbox Classic ini tidak diinstal, jadi sistem tidak mencantumkannya sebagai aplikasi email. Instal terlebih dahulu agar dapat memilihnya.
gtk-default-app-now = Inbox Classic kini menjadi aplikasi email default Anda: tautan email membuka pesan baru di sini.
gtk-default-app-failed = Inbox Classic tidak dapat dijadikan aplikasi email default.

## Buttons and words used in many windows

## The reading pane

gtk-reader-date = Tanggal:
gtk-reader-files = Lampiran pesan
gtk-files = { $count } file
gtk-save-attachments-menu = Simpan Lampiran...

## The compose window

gtk-format-bold = Tebal (Ctrl+B)
gtk-format-italic = Miring (Ctrl+I)
gtk-format-underline = Garis Bawah (Ctrl+U)
gtk-format-hyperlink = Hyperlink (Ctrl+K)
gtk-font = Font
gtk-show-cc = _Cc
gtk-show-bcc = _Bcc
gtk-save-tip = Simpan (Ctrl+S)
gtk-link-status = { $link }    (Ctrl+klik untuk membuka)

## Accounts

gtk-plain-warning =
    Tanpa enkripsi, siapa pun yang menyadap lalu lintas jaringan Anda dapat membaca kata sandi dan pesan Anda. Lanjutkan hanya jika koneksi dilindungi dengan cara lain. Jaringan lokal saja tidak memberikan enkripsi.

    Lanjutkan?
gtk-account-name-title = Nama akun
gtk-display-name-title = Nama tampilan
gtk-turned-off-why = Opsi “{ $button }” dinonaktifkan di komputer ini. { $reason }
gtk-turned-off-why-long =
    Opsi “{ $button }” dinonaktifkan di komputer ini.

    { $reason }
gtk-next = Berikutnya >
gtk-provider-sign-in = Masuk ke { $address } di situs web { $provider }. Kata sandi Anda tidak dibagikan dengan Inbox Classic. Jika akun Anda mengizinkan kata sandi aplikasi untuk email, Anda juga dapat menggunakan kata sandi yang dibuat di pengaturan keamanannya. Outlook.com dan Microsoft 365 hanya menerima proses masuk lewat browser.
gtk-provider-sign-in-apps = Masuk ke { $address } di situs web { $provider } menggunakan salah satu aplikasi masuk Anda (Opsi masuk lainnya). Jika akun Anda mengizinkan kata sandi aplikasi untuk email, Anda juga dapat menggunakan kata sandi yang dibuat di pengaturan keamanannya. Outlook.com dan Microsoft 365 hanya menerima proses masuk lewat browser.
gtk-accounts-add = Tambah...
gtk-accounts-properties = Properti...
gtk-accounts-signature = Tanda Tangan...
gtk-accounts-sign-in-apps = Aplikasi Masuk...

## Sign-in apps

gtk-app-server = Server { $kind }
gtk-app-port = Port { $kind }
gtk-app-security = Keamanan { $kind }
gtk-issuer-found =
    Halaman masuk: { $page }
    Titik akhir token: { $endpoint }
gtk-client-id = ID klien
gtk-client-secret = Rahasia klien
gtk-scopes = Cakupan (scopes)
gtk-redirect-uri = URI pengalihan
gtk-issuer-usable =
    Penerbit dapat digunakan.

    { $found }
gtk-app-built-in = { $app } adalah aplikasi bawaan. Anda hanya dapat mengubah apakah aplikasi ini ditawarkan untuk akun baru. { $reason }
gtk-built-in = { $app } (bawaan)
gtk-offered-for-new = Ditawarkan untuk akun baru
gtk-edit-button = Edit...
gtk-remove-app-ask = Hapus aplikasi masuk { $app } beserta rahasia klien yang tersimpan?
gtk-sign-in-apps-intro = Aplikasi masuk memungkinkan akun masuk lewat browser. Aplikasi yang dinonaktifkan tidak ditawarkan untuk akun baru; akun yang sudah menggunakannya tetap berfungsi.

## AI agents

gtk-agent-it-may = Tindakan yang diizinkan
gtk-agent-accounts = Akun yang diizinkan
gtk-never-used = Belum pernah digunakan
gtk-last-used = Terakhir digunakan { $date }
gtk-forget-program = Hapus izin tersimpan program ini?
gtk-forget-program-detail = Izin program ini dan riwayat aktivitas agennya akan dihapus. Anda akan dimintai izin lagi saat program ini terhubung berikutnya.
gtk-no-agents-yet = Belum ada agen yang meminta akses ke email Anda.
gtk-nothing-yet = Belum ada.

## Preferences

gtk-preferences = Pengaturan
gtk-notify-subtitle = Hanya saat jendela utama tidak berada di depan

## The desktop entry and the page of the software stores

# linux/data/com.inboxclassic.InboxClassic.desktop and .metainfo.xml, made by the build. The keywords are the words a
# search of the applications finds Inbox Classic by, each ended by a semicolon, in your language only: the English
# ones are added before them
gtk-desktop-generic-name = Klien Email
gtk-desktop-comment = Baca dan tulis email: program email yang cepat dan sederhana
gtk-desktop-keywords = surel;pesan;kotak masuk;surat;
gtk-metainfo-summary = Program email yang cepat dan sederhana
gtk-metainfo-description = Inbox Classic membaca dan menulis email. Tata letak klasiknya menampilkan folder di kiri, pesan di atas, dan pesan yang dipilih di bawahnya. Program ini bekerja dengan akun IMAP dan SMTP yang kompatibel, dan masuk ke Outlook.com serta Microsoft 365 lewat browser.
gtk-metainfo-feature-sanitized = Skrip pesan dan konten aktif lainnya dihapus; gambar dari internet hanya dimuat jika Anda mengizinkannya
gtk-metainfo-feature-search = Cari subjek, pengirim, penerima, nama lampiran, dan teks pesan dengan operator gaya Gmail yang sudah dikenal
gtk-metainfo-feature-replies = Balasan menciutkan kutipan pesan sebelumnya
gtk-metainfo-feature-offline = Email yang diunduh tetap dapat dibaca secara offline selama salinan lokalnya disimpan; kredensial masuk biasanya disimpan di keyring sistem jika tersedia
