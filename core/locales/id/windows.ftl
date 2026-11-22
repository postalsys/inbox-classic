# Draf terjemahan bahasa Indonesia, menunggu tinjauan penutur asli.
# The words of the Windows app's own windows (app/src), ids starting with win-. Placeables in { $braces } are filled in
# by the app; an & marks a menu or button letter (&& is an ampersand).

## The main window

# review: new
win-still-running-detail = Inbox Classic tetap memeriksa email baru di latar belakang. Klik ikonnya untuk membukanya. Untuk keluar, klik kanan ikon tersebut dan gunakan menunya.
# review: new
win-default-app-not-installed = Salinan Inbox Classic ini tidak diinstal, jadi Windows tidak mencantumkannya sebagai aplikasi email. Instal terlebih dahulu agar dapat memilihnya.
# review: new
win-default-app-settings = Windows akan membuka pengaturan Aplikasi default. Pilih Inbox Classic untuk membuka tautan MAILTO.
# review: new
win-no-unread = Tidak ada pesan yang belum dibaca
# review: new
win-unread-messages = { $count } pesan belum dibaca
# review: new
win-print-failed = Pesan tidak dapat dicetak.
# review: new
win-print-title-of = Cetak - { $subject }
# review: new
win-no-bodies = Isi pesan tidak dapat ditampilkan.
# review: new
win-webview-failed = WebView2 gagal dibuat.
# review: new
win-webview-missing = Runtime WebView2 tidak tersedia.
# review: new
win-list-loading = Memuat...

## Buttons and words used in many windows

# review: new
win-delete-button = &Hapus
# review: new
win-find-label = &Cari:
# review: new
win-save-as-button = Simpan Seba&gai...
# review: new
win-too-many-files = Terlalu banyak file sekaligus: pilih lebih sedikit.

## The Outbox


## The compose window

# review: new
win-editor-failed = Pesan tidak dapat ditulis.
# review: new
win-ctrl-click-to-open = ({ $ctrl }+klik untuk membuka)
# review: new
win-format-bold = Tebal ({ $ctrl }+B)
# review: new
win-format-italic = Miring ({ $ctrl }+I)
# review: new
win-format-underline = Garis Bawah ({ $ctrl }+U)
# review: new
win-format-link = Hyperlink ({ $ctrl }+K)
# review: new
win-show-cc = &Cc
# review: new
win-show-bcc = &Bcc
# review: new
win-signature-title = Tanda Tangan: { $account }

## The folders, the message list and the reading pane

# review: new
win-search-found-all = { $count ->
    [0] Tidak ada hasil untuk “{ $words }” di semua folder
   *[other] { $count } hasil untuk “{ $words }” di semua folder
}
# review: new
win-search-found-in = { $count ->
    [0] Tidak ada hasil untuk “{ $words }” di { $folder }
   *[other] { $count } hasil untuk “{ $words }” di { $folder }
}
# review: new
win-search-indexing = teks { $count } pesan masih diindeks
# review: new
win-no-match-indexing = Teks { $count } pesan masih diindeks, jadi hasil lain mungkin segera ditemukan.
# review: new
win-files = { $count } file
# review: new
win-save-attachments = &Simpan Lampiran...
# review: new
win-files-not-saved = { $failed } dari { $count } file tidak dapat disimpan.
# review: new
win-new-folder-in-highlighted = Folder baru akan dibuat di dalam folder yang dipilih.
# review: new
win-delete-folder-ask = Hapus folder “{ $folder }” beserta pesan dan folder di dalamnya? Folder ini juga dihapus di server.
# review: new
win-rename = &Ganti Nama...
# review: new
win-messages-not-saved = Pesan tidak dapat disimpan.
# review: new
win-messages-not-forwarded = Pesan tidak dapat diteruskan.

## Accounts

# review: new
win-sign-in-google = Masuk dengan Google
# review: new
win-sign-in-microsoft = Masuk dengan Microsoft
# review: new
win-next = &Berikutnya >
# review: new
win-your-account = akun Anda
# review: new
win-browser-sign-in = (masuk lewat browser)
# review: new
win-add = &Tambah...
# review: new
win-properties-button = &Properti...
# review: new
win-signature-button = Tanda Ta&ngan...
# review: new
win-sign-in-apps-button = &Aplikasi Masuk...

## AI agents

# review: new
win-dont-allow = &Jangan Izinkan
# review: new
win-col-address = Alamat
# review: new
win-never-written-to = Belum pernah dikirimi pesan
# review: new
win-book-find-label = Ketik nama atau alamat email:
# review: new
win-send = &Kirim
# review: new
win-dont-send = &Jangan Kirim
# review: new
win-unsubscribe = &Berhenti Berlangganan
# review: new
win-dont-unsubscribe = &Tetap Berlangganan
# review: new
win-forget-program-ask = Hapus izin tersimpan program ini dan riwayat aktivitas agennya? Program ini tidak akan dicopot. Anda akan dimintai izin lagi saat program ini terhubung berikutnya.
# review: new
win-clear-log-ask = Hapus riwayat aktivitas agen? Ini tidak membatalkan perubahan yang dibuat oleh agen.
# review: new
win-agent-programs = &Program yang agennya telah meminta akses ke email Anda:
# review: new
win-change = &Ubah...
# Tools > AI Agents: takes back everything the selected program did in a span the user picks
# review: new
win-undo-since = Batalkan &Sejak...
# review: new
win-take-back = &Tarik Kembali
# review: new
win-what-agents-did = &Aktivitas agen:
# under the log of Tools > AI Agents: what the selected row of reads covers (the start and end of its hour), or how to see it
# review: new
win-agent-reads = Yang dibaca dari { $from } sampai { $to }:
# review: new
win-agent-reads-hint = Pilih baris bacaan di atas untuk melihat apa yang dibaca.

## Sign-in apps

# review: new
win-built-in = (bawaan)
# review: new
win-edit = &Edit...

## Options

# review: new
win-folders-hide = Sembunyikan daftar folder
# review: new
win-folders-pin = Tetap tampilkan daftar folder di samping pesan
# review: new
win-folders-show = Tampilkan folder

## The installer

# the installer's own words (installer/inbox-classic.nsi), made into installer/languages.nsh by the build;
# { $version } and { $installed } are version numbers, 0.18.0
# review: new
win-installer-start = Jalankan Inbox Classic
# review: new
win-installer-welcome-new =
    Ini akan menginstal Inbox Classic { $version }, sebuah program email.

    Tidak perlu hak administrator, program ini hanya diinstal untuk akun Anda.
# review: new
win-installer-welcome-same =
    Inbox Classic { $version } sudah terinstal. Ini akan menginstalnya lagi.

    Akun dan email Anda tetap disimpan.
# review: new
win-installer-welcome-update =
    Ini akan memperbarui Inbox Classic { $installed } ke { $version }.

    Jika sedang berjalan, program akan ditutup terlebih dahulu. Akun dan email Anda tetap disimpan.
# review: new
win-installer-older-ask = Inbox Classic { $installed } sudah terinstal, yang lebih baru daripada { $version }. Tetap instal versi yang lebih lama?
# review: new
win-installer-still-running = Inbox Classic masih berjalan. Tutup program ini, lalu coba lagi.
# review: new
win-installer-remove-mail-ask = Hapus juga data lokal Inbox Classic, termasuk akun, email yang diunduh, pesan dalam antrean, pengaturan, kontak, aturan, dan kunci enkripsi? Email di server dan entri di penyimpanan kredensial sistem tetap ada.
