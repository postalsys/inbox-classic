# Draf terjemahan bahasa Indonesia, menunggu tinjauan penutur asli.
# The words of the Linux app's own windows (linux/src), ids starting with gtk-. Placeables in { $braces } are filled in
# by the app; an _ marks a button's mnemonic letter. GNOME words where GNOME has them (Preferences, Quit).

## The main window

# review: new
gtk-search-looks-in = Pencarian di { $place } mencakup subjek, pengirim, penerima, nama lampiran, dan teks pesan. Periksa ejaan atau coba lebih sedikit kata.
# review: new
gtk-search-still-indexing = Teks { $count } pesan masih diindeks. Hasil lain mungkin segera muncul.
# review: new
gtk-search-results-everywhere = { $count ->
    [0] Tidak ada hasil
   *[other] { $count } hasil
} untuk “{ $words }” di semua folder
# review: new
gtk-search-results-in = { $count ->
    [0] Tidak ada hasil
   *[other] { $count } hasil
} untuk “{ $words }” di { $place }
# review: new
gtk-search-indexing = teks { $count } pesan masih diindeks
# review: new
gtk-list-loading = Memuat...
# review: new
gtk-menu-rename = Ganti Nama...
# review: new
gtk-import-one-question = Impor pesan { $file } ke { $folder }?
# review: new
gtk-files-not-saved = { $failed } dari { $total } file tidak dapat disimpan.
# review: new
gtk-unsubscribe-one-click =
    Keluar dari milis ini?

    Inbox Classic akan mengirim permintaan berhenti berlangganan ke { $target }. Tidak ada halaman web yang dibuka dan tidak ada email yang dikirim.
# review: new
gtk-unsubscribe-mail =
    Keluar dari milis ini?

    Untuk berhenti berlangganan, kirim email ke { $target }. Inbox Classic akan menyiapkannya untuk Anda. Kirim pesan tersebut untuk mengonfirmasi.
# review: new
gtk-unsubscribe-web =
    Keluar dari milis ini?

    Halaman berhenti berlangganan milis akan dibuka di browser Anda ({ $target }).
# review: new
gtk-unsubscribe-failed = Tidak dapat berhenti berlangganan: { $problem }
# review: new
gtk-toolbar-create-mail-menu = Tulis dari akun tertentu
# review: new
gtk-toolbar-send-recv-menu = Kirim dan terima email untuk akun tertentu
# review: new
gtk-main-menu = Menu Utama
# review: new
gtk-folder-list = Daftar Folder
# review: new
gtk-quit = Keluar

## The Move and Copy window

# review: new
gtk-new-folder-at-top-of = Folder baru ditempatkan di tingkat teratas { $account }.

## The message list

## Help

## Notifications and the tray

# review: new
gtk-unread-messages = { $count ->
    [0] Tidak ada pesan yang belum dibaca
   *[other] { $count } pesan belum dibaca
}

## The compose window's link menu

## The Outbox

# review: new
gtk-outbox-empty = Tidak ada pesan yang menunggu untuk dikirim.
# review: new
gtk-outbox-row = Kepada: { $to }  ·  Diantrekan { $queued }  ·  { $status }

## The app

# review: new
gtk-still-running-detail = Inbox Classic tetap memeriksa email baru di latar belakang. Gunakan ikonnya di bilah atas untuk membuka atau keluar dari aplikasi.
# review: new
gtk-sign-in-again-ask =
    Proses masuk ke { $account } ditolak atau sesinya telah berakhir.

    Masuk lagi di browser?
# review: new
gtk-default-app-not-installed = Salinan Inbox Classic ini tidak diinstal, jadi sistem tidak mencantumkannya sebagai aplikasi email. Instal terlebih dahulu agar dapat memilihnya.
# review: new
gtk-default-app-now = Inbox Classic kini menjadi aplikasi email default Anda: tautan email membuka pesan baru di sini.
# review: new
gtk-default-app-failed = Inbox Classic tidak dapat dijadikan aplikasi email default.

## Buttons and words used in many windows

## The reading pane

# review: new
gtk-reader-date = Tanggal:
# review: new
gtk-reader-files = Lampiran pesan
# review: new
gtk-files = { $count } file
# review: new
gtk-save-attachments-menu = Simpan Lampiran...

## The compose window

# review: new
gtk-format-bold = Tebal (Ctrl+B)
# review: new
gtk-format-italic = Miring (Ctrl+I)
# review: new
gtk-format-underline = Garis Bawah (Ctrl+U)
# review: new
gtk-format-hyperlink = Hyperlink (Ctrl+K)
# review: new
gtk-font = Font
# review: new
gtk-show-cc = _Cc
# review: new
gtk-show-bcc = _Bcc
# review: new
gtk-save-tip = Simpan (Ctrl+S)
# review: new
gtk-link-status = { $link }    (Ctrl+klik untuk membuka)

## Accounts

# review: new
gtk-plain-warning =
    Tanpa enkripsi, siapa pun yang menyadap lalu lintas jaringan Anda dapat membaca kata sandi dan pesan Anda. Gunakan koneksi ini hanya dengan server di komputer Anda sendiri atau di jaringan lokal Anda.

    Lanjutkan?
# review: new
gtk-account-name-title = Nama akun
# review: new
gtk-display-name-title = Nama tampilan
# review: new
gtk-turned-off-why = Opsi “{ $button }” dinonaktifkan di komputer ini. { $reason }
# review: new
gtk-turned-off-why-long =
    Opsi “{ $button }” dinonaktifkan di komputer ini.

    { $reason }
# review: new
gtk-next = Berikutnya >
# review: new
gtk-provider-sign-in = Masuk ke { $address } di situs web { $provider }. Kata sandi Anda tidak dibagikan dengan Inbox Classic. Jika akun Anda mengizinkan kata sandi aplikasi untuk email, Anda juga dapat menggunakan kata sandi yang dibuat di pengaturan keamanannya. Outlook.com dan Microsoft 365 hanya menerima proses masuk lewat browser.
# review: new
gtk-provider-sign-in-apps = Masuk ke { $address } di situs web { $provider } menggunakan salah satu aplikasi masuk Anda (Opsi masuk lainnya). Jika akun Anda mengizinkan kata sandi aplikasi untuk email, Anda juga dapat menggunakan kata sandi yang dibuat di pengaturan keamanannya. Outlook.com dan Microsoft 365 hanya menerima proses masuk lewat browser.
# review: new
gtk-accounts-add = Tambah...
# review: new
gtk-accounts-properties = Properti...
# review: new
gtk-accounts-signature = Tanda Tangan...
# review: new
gtk-accounts-sign-in-apps = Aplikasi Masuk...

## Sign-in apps

# review: new
gtk-app-server = Server { $kind }
# review: new
gtk-app-port = Port { $kind }
# review: new
gtk-app-security = Keamanan { $kind }
# review: new
gtk-issuer-found =
    Halaman masuk: { $page }
    Titik akhir token: { $endpoint }
# review: new
gtk-client-id = ID klien
# review: new
gtk-client-secret = Rahasia klien
# review: new
gtk-scopes = Cakupan (scopes)
# review: new
gtk-redirect-uri = URI pengalihan
# review: new
gtk-issuer-usable =
    Penerbit dapat digunakan.

    { $found }
# review: new
gtk-app-built-in = { $app } adalah aplikasi bawaan. Anda hanya dapat mengubah apakah aplikasi ini ditawarkan untuk akun baru. { $reason }
# review: new
gtk-built-in = { $app } (bawaan)
# review: new
gtk-offered-for-new = Ditawarkan untuk akun baru
# review: new
gtk-edit-button = Edit...
# review: new
gtk-remove-app-ask = Hapus aplikasi masuk { $app } beserta rahasia klien yang tersimpan?
# review: new
gtk-sign-in-apps-intro = Aplikasi masuk memungkinkan akun masuk lewat browser. Aplikasi yang dinonaktifkan tidak ditawarkan untuk akun baru; akun yang sudah menggunakannya tetap berfungsi.

## AI agents

# review: new
gtk-agent-it-may = Tindakan yang diizinkan
# review: new
gtk-agent-accounts = Akun yang diizinkan
# review: new
gtk-never-used = Belum pernah digunakan
# review: new
gtk-last-used = Terakhir digunakan { $date }
# review: new
gtk-forget-program = Hapus program ini?
# review: new
gtk-forget-program-detail = Izin program ini dan riwayat aktivitas agennya akan dihapus. Anda akan dimintai izin lagi saat program ini terhubung berikutnya.
# review: new
gtk-no-agents-yet = Belum ada agen yang meminta akses ke email Anda.
# review: new
gtk-nothing-yet = Belum ada.

## Preferences

# review: new
gtk-preferences = Pengaturan
# review: new
gtk-notify-subtitle = Hanya saat Inbox Classic berjalan di latar belakang

## The desktop entry and the page of the software stores

# linux/data/com.inboxclassic.InboxClassic.desktop and .metainfo.xml, made by the build. The keywords are the words a
# search of the applications finds Inbox Classic by, each ended by a semicolon, in your language only: the English
# ones are added before them
# review: new
gtk-desktop-generic-name = Klien Email
# review: new
gtk-desktop-comment = Baca dan tulis email: program email yang cepat dan sederhana
# review: new
gtk-desktop-keywords = surel;pesan;kotak masuk;surat;
# review: new
gtk-metainfo-summary = Program email yang cepat dan sederhana
# review: new
gtk-metainfo-description = Inbox Classic membaca dan menulis email. Tata letak klasiknya menampilkan folder di kiri, pesan di atas, dan pesan yang dipilih di bawahnya. Program ini bekerja dengan akun IMAP dan SMTP yang kompatibel, dan masuk ke Outlook.com serta Microsoft 365 lewat browser.
# review: new
gtk-metainfo-feature-sanitized = Skrip pesan dan konten aktif lainnya dihapus; gambar dari internet hanya dimuat jika Anda mengizinkannya
# review: new
gtk-metainfo-feature-search = Cari subjek, pengirim, penerima, nama lampiran, dan teks pesan dengan operator gaya Gmail yang sudah dikenal
# review: new
gtk-metainfo-feature-replies = Balasan melipat pesan sebelumnya yang dikutipnya
# review: new
gtk-metainfo-feature-offline = Email yang diunduh tetap dapat dibaca secara offline selama salinan lokalnya disimpan; kredensial masuk biasanya disimpan di keyring sistem jika tersedia
