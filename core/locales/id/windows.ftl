# Draf terjemahan bahasa Indonesia, menunggu tinjauan penutur asli.
# The words of the Windows app's own windows (app/src), ids starting with win-. Placeables in { $braces } are filled in
# by the app; an & marks a menu or button letter (&& is an ampersand).

## The main window

win-still-running-detail = Inbox Classic tetap memeriksa email baru di latar belakang. Klik ikonnya untuk membukanya. Untuk keluar, klik kanan ikon tersebut dan gunakan menunya.
win-default-app-not-installed = Salinan Inbox Classic ini tidak diinstal, jadi Windows tidak mencantumkannya sebagai aplikasi email. Instal terlebih dahulu agar dapat memilihnya.
win-default-app-settings = Windows akan membuka pengaturan Aplikasi default. Pilih Inbox Classic untuk membuka tautan MAILTO.
win-no-unread = Tidak ada pesan yang belum dibaca
win-unread-messages = { $count } pesan belum dibaca
win-print-failed = Pesan tidak dapat dicetak.
win-print-title-of = Cetak - { $subject }
win-no-bodies = Isi pesan tidak dapat ditampilkan.
win-webview-failed = WebView2 gagal dibuat.
win-webview-missing = Runtime WebView2 tidak tersedia.
win-list-loading = Memuat...

## Buttons and words used in many windows

win-delete-button = &Hapus
win-find-label = &Cari:
win-save-as-button = Simpan Seba&gai...
win-too-many-files = Terlalu banyak file sekaligus: pilih lebih sedikit.

## The Outbox


## The compose window

win-editor-failed = Pesan tidak dapat ditulis.
win-ctrl-click-to-open = ({ $ctrl }+klik untuk membuka)
win-format-bold = Tebal ({ $ctrl }+B)
win-format-italic = Miring ({ $ctrl }+I)
win-format-underline = Garis Bawah ({ $ctrl }+U)
win-format-link = Hyperlink ({ $ctrl }+K)
win-show-cc = &Cc
win-show-bcc = &Bcc
win-signature-title = Tanda Tangan: { $account }

## The folders, the message list and the reading pane

win-search-found-all = { $count ->
    [0] Tidak ada hasil untuk “{ $words }” di semua folder
   *[other] { $count } hasil untuk “{ $words }” di semua folder
}
win-search-found-in = { $count ->
    [0] Tidak ada hasil untuk “{ $words }” di { $folder }
   *[other] { $count } hasil untuk “{ $words }” di { $folder }
}
win-search-indexing = teks { $count } pesan masih diindeks
win-no-match-indexing = Teks { $count } pesan masih diindeks, jadi hasil lain mungkin segera ditemukan.
win-files = { $count } file
win-save-attachments = &Simpan Lampiran...
win-files-not-saved = { $failed } dari { $count } file tidak dapat disimpan.
win-new-folder-in-highlighted = Folder baru akan dibuat di dalam folder yang dipilih.
win-delete-folder-ask = Hapus folder “{ $folder }” beserta pesan dan folder di dalamnya? Folder ini juga dihapus di server.
win-rename = &Ganti Nama...
win-messages-not-saved = Pesan tidak dapat disimpan.
win-messages-not-forwarded = Pesan tidak dapat diteruskan.

## Accounts

win-sign-in-google = Masuk dengan Google
win-sign-in-microsoft = Masuk dengan Microsoft
win-next = &Berikutnya >
win-your-account = akun Anda
win-browser-sign-in = (masuk lewat browser)
win-add = &Tambah...
win-properties-button = &Properti...
win-signature-button = Tanda Ta&ngan...
win-sign-in-apps-button = &Aplikasi Masuk...

## AI agents

win-dont-allow = &Jangan Izinkan
win-col-address = Alamat
win-never-written-to = Belum pernah dikirimi pesan
win-book-find-label = Ketik nama atau alamat email:
win-send = &Kirim
win-dont-send = &Jangan Kirim
win-unsubscribe = &Berhenti Berlangganan
win-dont-unsubscribe = &Tetap Berlangganan
win-forget-program-ask = Hapus izin tersimpan program ini dan riwayat aktivitas agennya? Program ini tidak akan dicopot. Anda akan dimintai izin lagi saat program ini terhubung berikutnya.
win-clear-log-ask = Hapus riwayat aktivitas agen? Ini tidak membatalkan perubahan yang dibuat oleh agen.
win-agent-programs = &Program yang agennya telah meminta akses ke email Anda:
win-change = &Ubah...
# Tools > AI Agents: takes back everything the selected program did in a span the user picks
win-undo-since = Batalkan &Sejak...
win-take-back = &Tarik Kembali
win-what-agents-did = &Aktivitas agen:
# under the log of Tools > AI Agents: what the selected row of reads covers (the start and end of its hour), or how to see it
win-agent-reads = Yang dibaca dari { $from } sampai { $to }:
win-agent-reads-hint = Pilih baris pada riwayat pembacaan di atas untuk melihat apa yang dibaca.

## Sign-in apps

win-built-in = (bawaan)
win-edit = &Edit...

## Options

win-folders-hide = Sembunyikan daftar folder
win-folders-pin = Tetap tampilkan daftar folder di samping pesan
win-folders-show = Tampilkan folder

## The installer

# the installer's own words (installer/inbox-classic.nsi), made into installer/languages.nsh by the build;
# { $version } and { $installed } are version numbers, 0.18.0
win-installer-start = Jalankan Inbox Classic
win-installer-welcome-new = Ini akan menginstal Inbox Classic { $version }, sebuah program email.

    Tidak perlu hak administrator, program ini hanya diinstal untuk akun pengguna Windows Anda.
win-installer-welcome-same =
    Inbox Classic { $version } sudah terinstal. Ini akan menginstalnya lagi.

    Akun dan email Anda tetap disimpan.
win-installer-welcome-update =
    Ini akan memperbarui Inbox Classic { $installed } ke { $version }.

    Jika sedang berjalan, program akan ditutup terlebih dahulu. Akun dan email Anda tetap disimpan.
win-installer-older-ask = Inbox Classic { $installed } sudah terinstal, yang lebih baru daripada { $version }. Tetap instal versi yang lebih lama?
win-installer-still-running = Inbox Classic masih berjalan. Tutup program ini, lalu coba lagi.
win-installer-remove-mail-ask = Hapus juga data lokal Inbox Classic, termasuk akun, email yang diunduh, pesan dalam antrean, pengaturan, kontak, aturan, dan kunci enkripsi? Email di server dan entri di penyimpanan kredensial sistem tetap ada.
