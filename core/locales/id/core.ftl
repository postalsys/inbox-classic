# Draf terjemahan bahasa Indonesia, menunggu tinjauan penutur asli.
# What the core says, the same on every platform. Placeables in { $braces } are filled in by the code; keep them, in
# the place the language puts them. Plurals choose by the number: [one] and *[other] in English, the forms your
# language has in yours.

## Counts and sizes

# review: new
messages = { $count } pesan
# the separator of decimals in sizes: 2.4 MB
# review: new
decimal-separator = ,
# what goes between the items of a list of words (Read, organize and draft; Monday, Wednesday): a comma and a space
# here, 、 in Chinese and Japanese; the quotes keep the space, which a message would otherwise lose
# review: new
list-separator = { ", " }
# review: new
size-bytes = { $count } byte
# review: new
size-kb = { $size } KB
# review: new
size-mb = { $size } MB
# review: new
size-gb = { $size } GB
# review: new
send-delay-off = Nonaktif
# review: new
send-delay-seconds = { $count } detik
# the status bar: "12 messages, 3 unread"
# review: new
list-counts = { $messages }, { $unread } belum dibaca
# review: new
list-counts-selected = { $messages }, { $unread } belum dibaca, { $selected } dipilih
# the status bar while searching: "12 found, 3 unread"
# review: new
list-counts-found = { $found } ditemukan, { $unread } belum dibaca
# review: new
list-counts-found-selected = { $found } ditemukan, { $unread } belum dibaca, { $selected } dipilih
# review: new
list-counts-none = Tidak ada pesan yang ditemukan

## Special folders, as Outlook Express names them

# review: new
folder-inbox = Kotak Masuk
# review: new
folder-sent = Item Terkirim
# review: new
folder-deleted = Item Terhapus
# review: new
folder-drafts = Draf
# review: new
folder-junk = Email Sampah
# review: new
folder-archive = Arsip

## The reading pane

# review: new
reader-no-message = Tidak ada pesan yang dipilih.
# review: new
reader-downloading = Mengunduh pesan…
# review: new
reader-downloading-detail = Pesan akan muncul di sini setelah unduhan selesai.
# review: new
reader-downloading-size = Ukuran pesan ini { $size }. Pesan akan muncul di sini setelah diunduh.
# review: new
reader-failed = Pesan tidak dapat diunduh
# review: new
reader-failed-network = Koneksi ke server email tidak dapat dibuat atau terputus ({ $reason }).
# review: new
reader-failed-sign-in = Server email tidak menerima proses masuk ({ $reason }). Periksa kata sandi atau masuk lagi di pengaturan akun.
# review: new
reader-failed-security = Koneksi ke server email tidak dapat diamankan ({ $reason }).
# review: new
reader-failed-other = Server email menjawab: { $reason }.
# review: new
reader-retry-note = Pesan akan dicoba lagi saat akun tersambung kembali.
# review: new
reader-unreadable = Pesan ini tidak dapat ditampilkan: { $error }
# review: new
message-source-title = Sumber Pesan: { $subject }
# review: new
message-source-untitled = Sumber Pesan

## Printing a message, and the header of a message quoted in a reply or forward

# review: new
header-from = Dari
# review: new
header-date = Tanggal
# review: new
header-to = Kepada
# review: new
header-cc = Cc
# review: new
header-sent = Terkirim
# review: new
header-subject = Subjek
# review: new
header-security = Keamanan
# review: new
header-part = Bagian { $number }
# review: new
quote-original = ----- Pesan Asli -----
# review: new
fold-show-earlier = Tampilkan pesan sebelumnya

## Bounces: the card at the top of a notice that a message was not delivered

# review: new
bounce-failed = Pesan Anda tidak terkirim
# review: new
bounce-delayed = Pesan Anda belum terkirim
# review: new
bounce-delayed-note = Server email Anda masih mencoba mengirimkannya. Anda tidak perlu mengirimnya lagi.
# the link to the message the notice is about, in Sent Items or another folder
# review: new
bounce-show-message = Tampilkan pesan yang terpental
# the link of a delay's card to the message that is still on its way
# review: new
bounce-show-delayed = Tampilkan pesan yang tertunda
# review: new
bounce-what-to-do = Yang dapat Anda lakukan:
# what to do about a recipient the message is still on its way to: in the card of a delay, and in the card of a failure
# review: new
bounce-delayed-do = Belum perlu apa-apa. Jika pesan tetap tidak dapat dikirim, Anda akan menerima pemberitahuan lain.
# review: new
bounce-delayed-row-do = Belum perlu apa-apa. Server email Anda masih mencoba mengirimkannya, dan Anda akan menerima pemberitahuan lain jika tidak berhasil.
# folds the receiving server's own words
# review: new
bounce-details = Detail
# a recipient the notice does not name
# review: new
bounce-someone = Seorang penerima
# in Details: the server that refused the message, the status code it gave, and the server that wrote the notice
# review: new
bounce-server = Server: { $server }
# review: new
bounce-status = Status: { $status }
# review: new
bounce-reported-by = Dilaporkan oleh: { $server }
# review: new
bounce-retry-minutes = Server penerima meminta menunggu { $count } menit sebelum percobaan berikutnya.
# review: new
bounce-retry-hours = Server penerima meminta menunggu { $count } jam sebelum percobaan berikutnya.
# the names of the blocklists, "Spamhaus ZEN, Barracuda"
# review: new
bounce-blocklist = Daftar blokir: { $lists }
# review: new
bounce-user-unknown = Alamat tidak ada
# review: new
bounce-user-unknown-why = Server penerima tidak memiliki kotak surat dengan alamat ini. Mungkin alamatnya salah ketik, atau orang tersebut sudah tidak menggunakannya.
# review: new
bounce-user-unknown-do = Periksa ejaan alamat, atau tanyakan alamat yang sekarang digunakan orang tersebut.
# review: new
bounce-invalid-address = Alamat tidak valid
# review: new
bounce-invalid-address-why = Alamat tidak ditulis dalam bentuk yang dapat dikirimi email.
# review: new
bounce-invalid-address-do = Cari kesalahan ketik, seperti spasi, huruf yang hilang, atau tidak ada apa pun setelah @.
# review: new
bounce-mailbox-disabled = Kotak surat ditutup
# review: new
bounce-mailbox-disabled-why = Alamat ini ada, tetapi kotak suratnya telah dinonaktifkan atau tidak digunakan lagi.
# review: new
bounce-mailbox-disabled-do = Hubungi orang tersebut dengan cara lain dan tanyakan alamat yang sekarang digunakannya.
# review: new
bounce-mailbox-full = Kotak surat penuh
# review: new
bounce-mailbox-full-why = Kotak surat penerima tidak memiliki ruang untuk email baru.
# review: new
bounce-mailbox-full-do = Kirim lagi dalam beberapa hari, atau beri tahu orang tersebut dengan cara lain.
# review: new
bounce-spam-blocked = Ditolak sebagai spam
# review: new
bounce-spam-blocked-why = Server penerima menganggap pesan ini sebagai spam.
# review: new
bounce-spam-blocked-do = Kirim lagi tanpa hal yang terlihat seperti spam, misalnya banyak tautan, tautan pendek, atau lampiran besar. Jika terus terjadi, tanyakan kepada penyedia email Anda.
# review: new
bounce-virus-detected = Ditolak karena virus
# review: new
bounce-virus-detected-why = Server penerima melaporkan virus atau konten berbahaya lain di dalam pesan atau lampirannya.
# review: new
bounce-virus-detected-do = Periksa lampiran dengan pemindai virus. Beberapa server menolak semua program atau arsip, jadi bagikan file seperti itu sebagai tautan.
# review: new
bounce-ip-blocklisted = Server email Anda ada di daftar blokir
# review: new
bounce-ip-blocklisted-why = Server penerima menolak email dari server yang mengirim pesan Anda, karena alamat server tersebut ada di daftar blokir.
# review: new
bounce-ip-blocklisted-do = Masalahnya bukan pada pesan. Teruskan pemberitahuan ini ke penyedia email Anda dan minta mereka mengeluarkan server tersebut dari daftar.
# review: new
bounce-domain-blocklisted = Sebuah domain ada di daftar blokir
# review: new
bounce-domain-blocklisted-why = Server penerima menolak pesan karena domain alamat Anda, atau domain dalam tautan pesan, ada di daftar blokir.
# review: new
bounce-domain-blocklisted-do = Jika pesan berisi tautan, coba kirim tanpa tautan. Jika tidak, teruskan pemberitahuan ini kepada pengelola email domain Anda.
# review: new
bounce-policy-blocked = Ditolak oleh aturan server penerima
# review: new
bounce-policy-blocked-why = Aturan server penerima tidak meloloskan pesan ini, misalnya karena ukurannya, lampirannya, atau pengirimnya.
# review: new
bounce-policy-blocked-do = Kata-kata server itu sendiri di bagian Detail sering kali menyebutkan alasannya. Tanyakan kepada penerima apakah mereka dapat menerima email seperti itu.
# review: new
bounce-geo-blocked = Ditolak karena asal pengirimannya
# review: new
bounce-geo-blocked-why = Server penerima tidak menerima email dari negara atau jaringan tempat server email Anda berada.
# review: new
bounce-geo-blocked-do = Hubungi orang tersebut dengan cara lain, atau tanyakan hal ini kepada penyedia email Anda.
# review: new
bounce-relay-denied = Server tidak mau meneruskannya
# review: new
bounce-relay-denied-why = Sebuah server menolak meneruskan pesan, sering kali karena pesan dikirim tanpa masuk atau melalui server yang tidak menangani penerima ini.
# review: new
bounce-relay-denied-do = Periksa server keluar dan detail masuk di pengaturan akun.
# review: new
bounce-auth-failure = Alamat pengirim Anda tidak dapat diverifikasi
# review: new
bounce-auth-failure-why = Server penerima tidak dapat memastikan bahwa pesan benar-benar berasal dari domain Anda (SPF, DKIM, atau DMARC).
# review: new
bounce-auth-failure-do = Teruskan pemberitahuan ini kepada pengelola email domain Anda: pengaturannya perlu diperbaiki. Sementara itu, mengirim melalui server penyedia Anda sendiri mungkin membantu.
# review: new
bounce-rate-limited = Terlalu banyak email sekaligus
# review: new
bounce-rate-limited-why = Untuk sementara, server penerima menerima lebih sedikit pesan dari server email Anda.
# review: new
bounce-rate-limited-do = Tunggu sebentar dan kirim lagi. Saat menulis kepada banyak orang, kirim ke lebih sedikit penerima sekaligus.
# review: new
bounce-greylisting = Ditahan sebentar
# review: new
bounce-greylisting-why = Server penerima meminta pengirim yang tidak dikenal untuk mencoba lagi beberapa saat kemudian, sebuah pemeriksaan umum terhadap spam.
# review: new
bounce-greylisting-do = Untuk penundaan sementara, server pengirim biasanya mencoba lagi. Jika pemberitahuan ini melaporkan kegagalan akhir, coba kirim pesan lagi nanti.
# review: new
bounce-server-error = Server penerima mengalami masalah
# review: new
bounce-server-error-why = Server penerima tidak dapat dijangkau, atau tidak dapat menerima pesan karena masalahnya sendiri.
# review: new
bounce-server-error-do = Kirim lagi nanti. Jika terus gagal, periksa bagian alamat setelah @ untuk mencari kesalahan ketik.
# review: new
bounce-unknown = Tidak terkirim
# review: new
bounce-unknown-why = Pemberitahuan tidak menyebutkan alasannya dengan jelas.
# review: new
bounce-unknown-do = Kata-kata server itu sendiri di bagian Detail mungkin memberi keterangan lebih lanjut. Jika tidak membantu, teruskan pemberitahuan ini ke penyedia email Anda.

## Several messages selected

# review: new
selection-title = { $count } pesan dipilih
# review: new
selection-unread = { $count } belum dibaca
# review: new
selection-flagged = { $count } berbendera
# review: new
delete-for-good-one = Pesan ini akan dihapus secara permanen. Hapus?
# review: new
delete-for-good-all = { $count } pesan ini akan dihapus secara permanen. Hapus?
# review: new
delete-for-good-some = { $count } dari { $total } pesan akan dihapus secara permanen. Hapus pesan?
# review: new
done-read = { $count ->
   *[other] { $messages } ditandai sudah dibaca
}
# review: new
done-unread = { $count ->
   *[other] { $messages } ditandai belum dibaca
}
# review: new
done-flagged = { $count ->
   *[other] { $messages } diberi bendera
}
# review: new
done-unflagged = Bendera dihapus dari { $messages }
# review: new
done-deleted-for-good = { $count ->
   *[other] { $messages } dihapus secara permanen
}
# review: new
done-archived = { $count ->
   *[other] { $messages } diarsipkan
}
# review: new
done-moved = { $count ->
   *[other] { $messages } dipindahkan ke { $folder }
}
# review: new
done-copied = { $count ->
   *[other] { $messages } disalin ke { $folder }
}
# review: new
done-moving = { $count ->
   *[other] Memindahkan { $messages } ke { $folder }...
}
# review: new
done-copying = { $count ->
   *[other] Menyalin { $messages } ke { $folder }...
}
# review: new
done-moved-back = { $count ->
   *[other] { $messages } dipindahkan kembali ke { $folder }
}
# the status bar after Watch Conversation and Ignore Conversation, and after either again on a marked one
# review: new
done-watched = { $count ->
    [1] Memantau percakapan
   *[other] Memantau { $count } percakapan
}
# review: new
done-unwatched = { $count ->
    [1] Berhenti memantau percakapan
   *[other] Berhenti memantau { $count } percakapan
}
# review: new
done-ignored = { $count ->
    [1] Mengabaikan percakapan
   *[other] Mengabaikan { $count } percakapan
}
# review: new
done-unignored = { $count ->
    [1] Berhenti mengabaikan percakapan
   *[other] Berhenti mengabaikan { $count } percakapan
}
# review: new
their-folders = folder asalnya
# review: new
undo-move = Batalkan Pemindahan
# review: new
undo-delete = Batalkan Penghapusan
# review: new
undo-archive = Batalkan Pengarsipan
# review: new
undo-junk = Batalkan Tandai sebagai Sampah
# review: new
undo-not-junk = Batalkan Tandai sebagai Bukan Sampah
# review: new
undo-send = Batalkan Pengiriman
# review: new
nothing-to-undo = Tidak ada yang dapat dibatalkan.
# review: new
messages-gone = Pesan sudah tidak ada lagi.
# A non-selectable IMAP folder cannot contain messages; this does not mean it is empty.
# review: new
folder-holds-no-messages = Folder ini tidak dapat berisi pesan.
# review: new
not-archived-here = Pesan di folder ini tidak dapat diarsipkan.
# review: new
not-emptied-here = Hanya Item Terhapus dan Email Sampah yang dapat dikosongkan.
# review: new
next-unread-question = Tidak ada lagi pesan yang belum dibaca di { $folder }.

    Buka { $next }, folder berikutnya yang berisi pesan belum dibaca?
# review: new
no-unread-left = Tidak ada lagi pesan yang belum dibaca.
# review: new
empty-question = { $count ->
    [1] Kosongkan { $folder }?

        Pesan di dalamnya akan dihapus secara permanen dan tidak dapat dikembalikan.
   *[other] Kosongkan { $folder }?

        { $messages } di dalamnya akan dihapus secara permanen dan tidak dapat dikembalikan.
}
# review: new
no-junk-folder = Akun ini tidak memiliki folder Email Sampah untuk tujuan pemindahan pesan.
# review: new
no-inbox-folder = Akun ini tidak memiliki folder Kotak Masuk untuk tujuan pemindahan pesan.
# the status bar after a flag in a colour: "Flagged 2 messages blue"
# review: new
done-flagged-color = { $messages } diberi bendera { $color ->
    [red] merah
    [orange] oranye
    [yellow] kuning
    [green] hijau
    [blue] biru
    [purple] ungu
   *[gray] abu-abu
}
# the Flag menu: the colours of Apple Mail's flags
# review: new
flag-color = { $color ->
    [red] Merah
    [orange] Oranye
    [yellow] Kuning
    [green] Hijau
    [blue] Biru
    [purple] Ungu
   *[gray] Abu-abu
}

## The Move and Copy window

# review: new
move-window-title-move = { $count ->
    [1] Pindahkan Pesan
   *[other] Pindahkan { $count } Pesan
}
# review: new
move-window-title-copy = { $count ->
    [1] Salin Pesan
   *[other] Salin { $count } Pesan
}
# review: new
move-window-prompt-move = { $count ->
    [1] Pindahkan pesan yang dipilih ke:
   *[other] Pindahkan { $count } pesan yang dipilih ke:
}
# review: new
move-window-prompt-copy = { $count ->
    [1] Salin pesan yang dipilih ke:
   *[other] Salin { $count } pesan yang dipilih ke:
}
# the folders used last, over the folder tree
# review: new
targets-recent = Terbaru
# the folder the messages are in, which can not be chosen
# review: new
target-current = { $folder } (saat ini)
# a folder used last, with its account when there are several: "Archive (Work)"
# review: new
target-recent = { $folder } ({ $account })

## Moving and copying to another account

# review: new
transfer-moving = Memindahkan { $done } dari { $messages } ke { $folder }...
# review: new
transfer-copying = Menyalin { $done } dari { $messages } ke { $folder }...
# review: new
transfer-another-account = akun lain
# review: new
transfer-folder-gone = folder tujuannya sudah tidak ada
# review: new
transfer-not-on-server = pesan sudah tidak ada di server
# review: new
transfer-not-moved = { $count ->
   *[other] { $messages } tidak dapat dipindahkan ke akun lain: { $reason }
}
# review: new
transfer-not-copied = { $count ->
   *[other] { $messages } tidak dapat disalin ke akun lain: { $reason }
}
# review: new
transfer-none-moved = Tidak ada pesan yang dapat dipindahkan
# review: new
transfer-none-copied = Tidak ada pesan yang dapat disalin

## Messages as files

# review: new
export-not-in-time = pesan tidak dapat diunduh tepat waktu
# review: new
export-not-saved = { $failed } dari { $messages } tidak dapat disimpan ({ $problems })
# review: new
export-not-attached = pesan tidak dapat dilampirkan: { $error }
# the status bar after Save As with several: "Saved 3 messages to Desktop"
# review: new
saved-to = { $count ->
   *[other] { $messages } disimpan ke { $folder }
}
# review: new
download-progress = Mengunduh { $done } dari { $total }
# review: new
download-done = Diunduh: { $size }
# review: new
downloading-messages = { $count ->
   *[other] Mengunduh { $messages }...
}
# the status bar after files are dropped on a folder: "Put 3 messages in Archive"
# review: new
import-put = { $count ->
   *[other] { $messages } diantrekan untuk diimpor ke { $folder }
}
# review: new
import-not-put = Item berikut tidak dimasukkan ke folder:

    { $problems }

## Problems the windows show

# review: new
error-store = penyimpanan lokal: { $error }
# review: new
error-not-found = tidak ditemukan
# review: new
error-closed = sedang dimatikan
# review: new
error-other-account = browser masuk ke { $email }, bukan ke akun ini
# a password or sign-in the mail server refused, with the server's words
# review: new
failure-authentication = server tidak menerima proses masuk ({ $reason })
# the mail server could not be reached or the connection broke, with the reason
# review: new
failure-network = koneksi ke server gagal ({ $reason })
# review: new
error-in-use = aplikasi ini tidak dapat dihapus selama ada akun yang masuk dengannya: { $accounts }
# review: new
error-turned-off = aplikasi masuk ini dinonaktifkan untuk akun baru
# review: new
error-folder-name = nama folder harus terdiri dari 1 sampai 200 karakter dan tidak boleh berisi karakter kontrol
# review: new
error-folder-separator = nama folder tidak boleh berisi “{ $separator }” di server ini
# review: new
error-folder-special = Kotak Masuk dan folder khusus tidak dapat diganti namanya atau dihapus
# review: new
error-no-recipients = pesan tidak memiliki penerima
# review: new
error-bad-address = “{ $address }” bukan alamat email
# review: new
error-not-own-address = { $address } bukan salah satu alamat pengirim akun ini. Tambahkan alamat tersebut ke “Alamat lain yang Anda gunakan untuk mengirim” di properti akun.
# review: new
rule-query-refused = Aturan tidak dapat memfilter menurut folder atau tanggal ({ $words }).
# review: new
rule-no-query = Masukkan kriteria pencarian untuk pesan masuk.
# review: new
rule-no-action = Pilih setidaknya satu tindakan untuk aturan ini.
# review: new
error-attachment = { $path } tidak dapat dibaca: { $error }
# review: new
error-no-drafts = akun ini tidak memiliki folder Draf untuk menyimpan pesan
# review: new
error-draft-attachment = lampiran draf tidak dapat dipertahankan: { $error }
# review: new
error-password-not-saved = kata sandi tidak dapat disimpan untuk saat program dimulai berikutnya: { $error }
# review: new
error-sign-in-not-saved = detail masuk yang baru tidak dapat disimpan untuk saat program dimulai berikutnya: { $error }
# review: new
error-import-unreadable = { $path } tidak dapat dibaca: { $error }
# review: new
error-import-too-large = { $path } lebih besar dari 50 MB
# review: new
error-import-not-mail = { $path } bukan pesan email
# review: new
error-list-answered = server milis mengembalikan status { $status }
# review: new
error-not-built = pesan tidak dapat disusun
# review: new
error-outbox-waits = { $count ->
    [1] pesan tetap di Kotak Keluar; Kirim/Terima berikutnya akan mencoba mengirimnya lagi
   *[other] { $count } pesan tetap di Kotak Keluar; Kirim/Terima berikutnya akan mencoba mengirimnya lagi
}
# review: new
error-draft-not-removed = draf pesan sebelumnya tidak dapat dihapus dari Draf: { $reason }
# review: new
error-sent-but = pesan telah terkirim, tetapi { $problem }
# review: new
error-sent-still-in-outbox = pesan masih ada di Kotak Keluar: { $error }
# review: new
error-sent-no-copy = tidak ada salinan yang dapat disimpan di Item Terkirim: { $reason }
# review: new
error-no-password = tidak ada kata sandi untuk akun ini
# review: new
error-no-sign-in = tidak ada data masuk untuk akun ini
# review: new
error-provider-missing = aplikasi masuk tidak tersedia di build ini (ID: { $provider }). Aplikasi ini mungkin telah dihapus
# review: new
error-provider-servers = server akun ini tidak cocok dengan server aplikasi masuknya
# review: new
error-app-scopes = { $reason }. Server email tidak menerima token aplikasi masuk: pastikan cakupan (scopes) aplikasi memberikan akses ke email
# review: new
error-in-folder = { $folder }: { $reason }

## Sign-in apps

# review: new
sign-in-off-google = Aplikasi masuk Google bawaan disiapkan untuk pengguna uji yang disetujui dan secara default dinonaktifkan untuk akun baru. Pengguna uji dapat mengaktifkannya di Aplikasi Masuk (File > Akun). Anda juga dapat menggunakan aplikasi masuk Google Anda sendiri, atau kata sandi aplikasi jika akun Anda mendukungnya.
# review: new
sign-in-off-other = Aplikasi ini dinonaktifkan untuk akun baru. Anda dapat mengaktifkannya di Aplikasi Masuk (File > Akun).
# review: new
sign-in-app-no-name = aplikasi masuk memerlukan nama
# review: new
sign-in-app-no-client = ID klien tidak ada
# review: new
sign-in-app-no-scopes = aplikasi masuk memerlukan cakupan (scopes) yang memberikan akses ke email
# review: new
sign-in-app-bad-host = alamat server { $server } tidak ada atau bukan nama host yang valid
# review: new
sign-in-app-plain = server { $server } harus menggunakan SSL/TLS atau STARTTLS
# review: new
sign-in-app-not-checked = penerbit belum diperiksa
# review: new
sign-in-app-issuer-changed = penerbit berubah: ketik rahasia klien lagi, atau hapus rahasia tersebut
# review: new
sign-in-register-google = Di Google Cloud Console, buat klien OAuth dengan jenis Desktop app, dengan cakupan https://mail.google.com/ di layar izinnya. Selama aplikasi dalam tahap pengujian, hanya pengguna ujinya yang dapat masuk.
# review: new
sign-in-register-microsoft = Di Microsoft Entra, daftarkan aplikasi dengan platform Mobile and desktop applications, URI pengalihan http://localhost, alur klien publik diizinkan, dan izin delegasi IMAP.AccessAsUser.All, SMTP.Send, serta offline_access. Khusus untuk organisasi Anda, gunakan https://login.microsoftonline.com/<tenant ID>/v2.0 sebagai penerbit.
# review: new
sign-in-register-other = Daftarkan klien native (publik) dengan URI pengalihan di bawah ini; penyedia harus mengizinkan port apa pun pada URI tersebut (RFC 8252). Tambahkan cakupan yang digunakan penyedia untuk memberikan akses ke email.

## Calendar invitations

# review: new
repeats = Berulang
# review: new
repeats-every = { $unit ->
    [day] { $interval ->
        [1] Setiap hari
       *[other] Setiap { $interval } hari
    }
    [week] { $interval ->
        [1] Setiap minggu
       *[other] Setiap { $interval } minggu
    }
    [month] { $interval ->
        [1] Setiap bulan
       *[other] Setiap { $interval } bulan
    }
   *[year] { $interval ->
        [1] Setiap tahun
       *[other] Setiap { $interval } tahun
    }
}
# "Every week on Monday, Wednesday"
# review: new
repeats-on = { $repeats } pada hari { $days }
# "Every week, 10 times"
# review: new
repeats-times = { $count ->
    [1] { $repeats }, sekali
   *[other] { $repeats }, { $count } kali
}
# review: new
day-monday = Senin
# review: new
day-tuesday = Selasa
# review: new
day-wednesday = Rabu
# review: new
day-thursday = Kamis
# review: new
day-friday = Jumat
# review: new
day-saturday = Sabtu
# review: new
day-sunday = Minggu

## AI agents

# review: new
agent-level-read = Membaca email: folder, daftar pesan, percakapan, pencarian, pesan beserta filenya, aturan pesan Anda, dan orang-orang yang Anda kirimi pesan
# review: new
agent-level-organize = Mengatur email: status baca, bendera dan warnanya, sampah, pemindahan, pengarsipan, pembuatan dan penggantian nama folder, pemantauan dan pengabaian percakapan, penghapusan ke Item Terhapus, dan keluar dari milis setelah Anda setuju
# review: new
agent-level-drafts = Menulis draf untuk Anda kirim
# review: new
agent-level-send = Mengirim email, setiap pesan hanya setelah Anda setuju
# review: new
agent-connect-title = { $program } ingin menggunakan email Anda
# review: new
agent-connect-detail = Sebuah agen AI meminta untuk bekerja dengan Inbox Classic. Pilih apa yang boleh dilakukannya dan akun mana yang boleh dilihatnya; Anda dapat mengubahnya nanti di Alat > Agen AI.

    Agen membaca email yang ditulis orang lain, dan sebuah pesan dapat mencoba menipunya. Inbox Classic selalu bertanya kepada Anda sebelum agen mengirim apa pun.
# review: new
agent-reply-to = Balasan untuk “{ $subject }”
# review: new
agent-reply-all-on = Balasan ke semua untuk “{ $subject }”
# review: new
agent-forward-of = Penerusan “{ $subject }”
# review: new
agent-never-written-one = Anda belum pernah mengirim pesan ke { $address }.
# review: new
agent-never-written-many = Anda belum pernah mengirim pesan ke { $count } dari alamat ini.
# review: new
agent-send-title = { $program } ingin mengirim pesan ini
# review: new
agent-send-detail = Periksa penerima dan isi pesan. Setelah Anda mengonfirmasi, pesan menunggu { $seconds } detik di Kotak Keluar, tempat Anda masih dapat menghapusnya.
# review: new
agent-change-title = Yang boleh dilakukan { $program }
# review: new
agent-change-allowed = Ubah apa yang boleh dilakukan agen AI program ini terhadap email Anda.
# review: new
agent-change-refused = Anda menolak akses program ini. Izinkan untuk memberi agennya akses ke email Anda lagi.
# review: new
agent-log-taken-back = { $entry } (ditarik kembali)
# review: new
agent-files = File: { $files }
# review: new
agent-undo-refused = Ini tidak dapat ditarik kembali.
# review: new
agent-undo-refused-why = Ini tidak dapat ditarik kembali: { $reason }.
# review: new
agent-undo-impossible = ini tidak dapat ditarik kembali
# review: new
agent-undo-not-in-folder = pesan sudah tidak ada di folder tersebut
# review: new
agent-undo-not-arrived = pesan (belum) ada di folder tujuannya
# review: new
agent-undo-sent = pesan sudah tidak ada di Kotak Keluar
# review: new
agent-original-not-downloaded = pesan aslinya belum diunduh. Buka pesan tersebut terlebih dahulu
# review: new
agent-turned-away = Ditolak
# review: new
agent-can-nothing = Tidak ada
# review: new
agent-can-read = membaca
# review: new
agent-can-organize = mengatur
# review: new
agent-can-drafts = menulis draf
# review: new
agent-can-send = mengirim dengan persetujuan Anda
# "Read, organize and write drafts"
# review: new
agent-can-list = { $first } dan { $last }
# review: new
agent-accounts = { $count ->
    [0] tidak ada akun
   *[other] { $count } akun
}
# "Read and organize; 1 account"
# review: new
agent-access = { $can }; { $accounts }
# review: new
agent-unreadable = Pesan ini tidak dapat dibaca.
# review: new
agent-encrypted-original = Pesan ini terenkripsi: agen tidak dapat membalas atau meneruskannya, karena agen tidak dapat mengenkripsi.
# review: new
agent-encrypted = Pesan ini terenkripsi. Agen AI tidak dapat membaca isinya. Buka di Inbox Classic untuk membacanya sendiri.
# review: new
agent-too-many-changes = Terlalu banyak perubahan dalam 30 hari terakhir: agen ini telah membuat perubahan sebanyak yang dapat disimpan Inbox Classic di lognya untuk satu program. Agen dapat membuat perubahan lagi setelah yang terlama berusia 30 hari.
# review: new
agent-too-many-reads = Terlalu banyak pembacaan dalam 30 hari terakhir: agen ini telah membaca sebanyak yang dapat disimpan Inbox Classic di lognya untuk satu program. Agen dapat membaca lagi setelah pembacaan terlama berusia 30 hari.
# review: new
list-encrypted = Pesan terenkripsi
# review: new
agent-log-composed = Membuka “{ $subject }” di pesan baru untuk Anda selesaikan
# review: new
agent-log-refused = Anda tidak mengirim “{ $subject }”
# review: new
agent-log-sent = Memasukkan “{ $subject }” ke Kotak Keluar untuk { $to }
# review: new
agent-log-draft = Menyimpan draf “{ $subject }”
# review: new
agent-log-draft-replaced = Mengganti draf “{ $subject }”
# review: new
agent-log-draft-discarded = Meminta penghapusan draf “{ $subject }”
# review: new
agent-draft-note = { $program }, sebuah agen AI, menulis draf ini. Periksa penerima dan teksnya sebelum Anda mengirimnya.
# review: new
agent-log-read = Menandai sudah dibaca “{ $subject }”
# review: new
agent-log-unread = Menandai belum dibaca “{ $subject }”
# review: new
agent-log-flagged = Memberi bendera “{ $subject }”
# review: new
agent-log-unflagged = Menghapus bendera dari “{ $subject }”
# review: new
agent-log-deleted = Menghapus “{ $subject }”
# review: new
agent-log-moved = Memindahkan “{ $subject }” ke { $folder }
# review: new
agent-log-junk = Menandai “{ $subject }” sebagai sampah
# review: new
agent-log-not-junk = Menandai “{ $subject }” sebagai bukan sampah
# review: new
agent-log-archived = Mengarsipkan “{ $subject }”
# review: new
agent-log-folder = Meminta pembuatan folder “{ $name }”
# written at the user's yes, before the list is asked; a list that fails replaces it with agent-log-unsubscribe-failed
# review: new
agent-log-unsubscribed = Anda menyetujui berhenti berlangganan milis dari pesan “{ $subject }”
# review: new
agent-log-unsubscribe-failed = Tidak dapat berhenti berlangganan milis dari pesan “{ $subject }”: { $reason }
# "You did not unsubscribe from news@shop.example, deals@example.com": the lists' addresses, never their names
# review: new
agent-log-unsubscribe-refused = Anda tidak menyetujui permintaan berhenti berlangganan untuk: { $senders }
# review: new
agent-unsubscribe-title = { $count ->
    [1] { $program } ingin menghentikan langganan Anda pada sebuah milis
   *[other] { $program } ingin menghentikan langganan Anda pada { $count } milis
}
# review: new
agent-unsubscribe-detail = { $count ->
    [1] Inbox Classic meminta milis di bawah ini berhenti mengirimi Anda pesan, dengan cara sekali klik yang disediakannya. Tidak ada hal lain yang dikirim, dan pesan yang sudah Anda miliki tetap di tempatnya.
   *[other] Inbox Classic meminta setiap milis di bawah ini berhenti mengirimi Anda pesan, dengan cara sekali klik yang disediakan milis tersebut. Tidak ada hal lain yang dikirim, dan pesan yang sudah Anda miliki tetap di tempatnya.
}
# review: new
agent-log-flag-color = Memberi bendera “{ $subject }” { $color ->
    [red] merah
    [orange] oranye
    [yellow] kuning
    [green] hijau
    [blue] biru
    [purple] ungu
   *[gray] abu-abu
}
# review: new
agent-log-renamed = Meminta penggantian nama folder “{ $old }” menjadi “{ $name }”
# review: new
agent-log-watched = Memantau percakapan “{ $subject }”
# review: new
agent-log-ignored = Mengabaikan percakapan “{ $subject }”
# review: new
agent-log-unmarked = Berhenti memantau atau mengabaikan percakapan “{ $subject }”
# the reason one change can not be taken back (agent-undo-refused-why)
# review: new
agent-undo-changed = pesan telah diubah sejak itu
# one change of many messages an agent made with a search (apply_to_search), a row of the log; { $query } is the search
# review: new
agent-log-bulk-read = Menandai { $count } pesan sudah dibaca (pencarian: { $query })
# review: new
agent-log-bulk-unread = Menandai { $count } pesan belum dibaca (pencarian: { $query })
# review: new
agent-log-bulk-flagged = Memberi bendera pada { $count } pesan (pencarian: { $query })
# review: new
agent-log-bulk-unflagged = Menghapus bendera dari { $count } pesan (pencarian: { $query })
# review: new
agent-log-bulk-color = Memberi bendera pada { $count } pesan { $color ->
    [red] merah
    [orange] oranye
    [yellow] kuning
    [green] hijau
    [blue] biru
    [purple] ungu
   *[gray] abu-abu
} (pencarian: { $query })
# review: new
agent-log-bulk-moved = Memindahkan { $count } pesan ke { $folder } (pencarian: { $query })
# review: new
agent-log-bulk-archived = Mengarsipkan { $count } pesan (pencarian: { $query })
# review: new
agent-log-bulk-junk = Menandai { $count } pesan sebagai sampah (pencarian: { $query })
# review: new
agent-log-bulk-not-junk = Menandai { $count } pesan sebagai bukan sampah (pencarian: { $query })
# review: new
agent-log-bulk-deleted = Menghapus { $count } pesan (pencarian: { $query })
# Undo Everything Since in the AI Agents window: how far back it reaches
# review: new
agent-undo-span = { $span ->
    [quarter] Dalam 15 menit terakhir
    [hour] Dalam 1 jam terakhir
    [hours] Dalam 4 jam terakhir
    [day] Dalam 24 jam terakhir
    [week] Dalam 7 hari terakhir
   *[all] Dalam 30 hari terakhir
}
# the question before it takes back what a program did in the span chosen
# review: new
agent-undo-since-question = { $count ->
    [0] { $program } tidak memiliki perubahan dalam periode ini yang dapat ditarik kembali.
    [1] Coba tarik kembali perubahan yang tercatat untuk { $program } dalam periode ini?
   *[other] Coba tarik kembali { $count } perubahan yang tercatat untuk { $program } dalam periode ini?
}
# review: new
agent-undo-since-detail = Inbox Classic mencoba memulihkan folder, status baca, dan bendera, serta menghapus pesan yang masih menunggu di Kotak Keluar. Perubahan yang tidak dapat dibatalkan lagi dilewati. Beberapa perubahan warna bendera yang lebih baru dapat tertimpa.
# what taking back did, then a line for each kind of message it left as it is
# review: new
agent-undo-done = { $count ->
    [0] Tidak ada yang ditarik kembali.
   *[other] { $count } perubahan tercatat ditarik kembali, seluruhnya atau sebagian.
}
# review: new
agent-undo-left-gone = { $count } pesan sudah tidak berada di tempat yang ditentukan oleh perubahan.
# review: new
agent-undo-left-changed = { $count } pesan telah berubah sejak itu, oleh Anda atau di server, dan dibiarkan apa adanya.
# review: new
agent-undo-left-sent = { $count } pesan sudah keluar dari Kotak Keluar.
# review: new
agent-undo-left-impossible = { $count } perubahan tidak dapat ditarik kembali.
# the Send question of an agent's answer to a calendar invitation: what it answers, and when the event is
# review: new
agent-invitation-reply = { $response ->
    [accept] Pesan ini menerima undangan “{ $summary }” ({ $when }).
    [tentative] Pesan ini menerima undangan “{ $summary }” secara tentatif ({ $when }).
   *[decline] Pesan ini menolak undangan “{ $summary }” ({ $when }).
} Pesan dikirim ke penyelenggara yang disebutkan dalam undangan. Tanggapan lokal Anda berubah setelah server email menerima pesan, tanpa konfirmasi dari kalender penyelenggara.
# the subject of an answer to an invitation, as calendar programs write it
# review: new
invitation-reply-subject = { $response ->
    [accept] Diterima: { $summary }
    [tentative] Tentatif: { $summary }
   *[decline] Ditolak: { $summary }
}
# the text of an answer to an invitation; { $name } is the user's name, or address
# review: new
invitation-reply-text = { $response ->
    [accept] { $name } telah menerima undangan ini.
    [tentative] { $name } telah menerima undangan ini secara tentatif.
   *[decline] { $name } telah menolak undangan ini.
}
# what a program read in an hour, a row of the log: "Read 14 messages and searched 3 times" (joined by agent-can-list)
# review: new
agent-reads-messages = membaca { $count } pesan
# review: new
agent-reads-attachments = meminta { $count } lampiran
# review: new
agent-reads-searches = { $count ->
    [1] mencari sekali
   *[other] mencari { $count } kali
}
# review: new
agent-reads-lists = { $count ->
    [1] melihat daftar pesan sekali
   *[other] melihat daftar pesan { $count } kali
}
# each read under that row
# review: new
agent-read-message = Membaca “{ $subject }”
# review: new
agent-read-conversation = Membaca percakapan “{ $subject }” ({ $count } pesan)
# review: new
agent-read-attachment = Meminta lampiran “{ $name }” dari “{ $subject }”
# review: new
agent-read-search = Mencari “{ $query }”: { $count } pesan
# review: new
agent-read-people = Mencari orang berdasarkan awal nama atau alamatnya: “{ $query }”
# review: new
agent-read-list = Melihat { $count } entri daftar (lingkup: { $folder })
# review: new
agent-read-changes = Melihat detail { $count } pesan baru
# the programs started from a terminal app, which share one access: in the list of programs and the question when one connects
# review: new
agent-terminal-programs-mac = Program yang dijalankan dari { $terminal }
# review: new
agent-terminal-programs-windows = Program yang dijalankan dari terminal ({ $terminal })
# review: new
agent-terminal-programs-linux = Program yang dijalankan dari terminal ({ $terminal })
# one of them, as the questions to send or unsubscribe name it: "A program started from Terminal wants to send this message"
# review: new
agent-terminal-program-mac = Sebuah program yang dijalankan dari { $terminal }
# review: new
agent-terminal-program-windows = Sebuah program yang dijalankan dari terminal ({ $terminal })
# review: new
agent-terminal-program-linux = Sebuah program yang dijalankan dari terminal ({ $terminal })
# review: new
agent-connect-title-terminal = { $programs } ingin menggunakan email Anda
# review: new
agent-connect-terminal-detail = Agen AI yang dijalankan dari program terminal yang sama dan dikenali berbagi akses yang Anda izinkan di sini. Untuk memberi satu agen akses tersendiri, tambahkan --name dan nama pilihan Anda ke argumennya di pengaturan MCP agen tersebut. Nama itu tidak memverifikasi identitasnya.
# above the question when a program said it was another one than the system found: "It said it was Claude. Inbox Classic checked which program started it: python3."
# review: new
agent-connect-claimed = Program ini mengaku sebagai { $claimed }. Inbox Classic memeriksa program mana yang menjalankannya: { $program }.

## Keys as the keyboards of the language name them, in the help (Windows and Linux)

# review: new
key-ctrl = Ctrl
# review: new
key-alt = Alt
# review: new
key-shift = Shift
# review: new
key-del = Del
# review: new
key-enter = Enter

## Signing in and passwords

# review: new
sign-in-no-refresh = penyedia tidak memberikan token penyegaran
# review: new
sign-in-no-account = penyedia tidak menyebutkan akun mana yang masuk
# review: new
sign-in-not-finished = proses masuk belum selesai
# review: new
secrets-unavailable = { $store } tidak tersedia
# review: new
secrets-unavailable-why = { $store } tidak tersedia: { $error }
# review: new
secrets-windows = Manajer Kredensial
# review: new
secrets-mac = rantai kunci
# review: new
secrets-linux = keyring sistem (Secret Service)
# review: new
error-no-such-file = file tidak ada
# review: new
cards-file-too-big = File ini melebihi batas ukuran untuk mengimpor buku alamat.
# review: new
ui-sender-added = { $name } ditambahkan ke Buku Alamat.
# review: new
ui-sender-known = { $name } sudah ada di Buku Alamat.
# review: new
ui-sender-none = Pengirim pesan ini tidak memiliki alamat email untuk ditambahkan.
# review: new
card-name-needed = Kontak ini tidak memiliki nama dan alamat email.
# a file of Import Address Book that could not be read: "contacts.vcf: there is no such file"
# review: new
cards-file-failed = { $file }: { $reason }

## One-time codes: the card at the top of a message with a sign-in or verification code

# the domain the code is for, which signed the message
# review: new
otp-heading = Kode dari { $domain }
# review: new
otp-copy = Salin
# review: new
otp-note = Masukkan kode ini hanya di halaman { $domain }.
# review: new
otp-old = Kode ini dikirim lebih dari satu jam sebelum Anda membukanya, dan kemungkinan sudah kedaluwarsa.

# how many are invited, in the card of an event
# review: new
event-attendees = { $count } peserta

# the first line of a new message's notification when it has a code, for a domain that signed it
# review: new
otp-notification = { $code } adalah kode Anda untuk { $domain }

## OpenPGP keys (keys.rs)
# review: new
pgp-key-valid = Valid
# review: new
pgp-key-expires = Valid hingga { $date }
# review: new
pgp-key-expired = Kedaluwarsa pada { $date }
# review: new
pgp-key-revoked = Dicabut
# review: new
pgp-key-revoked-why = Dicabut: { $reason }
# review: new
pgp-key-not-valid = Tidak valid
# review: new
pgp-key-locked = Tidak dapat digunakan: kunci pelindungnya tidak tersedia di { $store }. Pastikan penyimpanan tersebut tersedia dan tidak terkunci. Jika kunci pelindung hilang, impor cadangan kunci privat.
# review: new
pgp-source-own = Dibuat di Inbox Classic
# review: new
pgp-source-file = Diimpor dari file
# review: new
pgp-source-paste = Ditempel
# review: new
pgp-source-attachment = Dari pesan
# review: new
pgp-source-vcard = Dari kartu kontak
# review: new
pgp-source-wkd = Dari penyedia email pengirim
# review: new
pgp-source-keyserver = Dari keys.openpgp.org
# review: new
pgp-source-autocrypt = Dari header Autocrypt pesan
# review: new
pgp-error-no-store = Kunci pelindung untuk kunci privat Anda disimpan di { $store }, yang tidak dapat digunakan: { $error }
# review: new
pgp-error-wrong-passphrase = Frasa sandi salah.
# review: new
pgp-error-not-a-key = Ini bukan kunci OpenPGP.
# review: new
pgp-error-too-large = Kunci terlalu besar.
# review: new
pgp-error-unusable = Kunci tidak dapat digunakan. Kunci ini mungkin tidak memiliki kunci penandatanganan atau enkripsi yang sesuai, atau menggunakan kriptografi yang tidak didukung.
# review: new
pgp-imported-private = { $count ->
    [1] Kunci privat Anda telah diimpor.
   *[other] { $count } kunci privat telah diimpor.
}
# review: new
pgp-imported-public = { $count ->
    [1] Satu kunci telah diimpor.
   *[other] { $count } kunci telah diimpor.
}
# review: new
pgp-imported-pending = Kunci lain sudah digunakan untuk { $addresses }: kunci baru menunggu di kontak sampai Anda memilihnya.
# review: new
pgp-error-needs-passphrase = Kunci privat dilindungi dengan frasa sandi. Ketik frasa sandi untuk mengimpor kunci.
# review: new
pgp-error-mismatch = Kunci privat ini bukan pasangan kunci publiknya. Kunci mungkin telah diubah.
# review: new
pgp-file-name-public = Kunci publik { $who }.asc
# review: new
pgp-file-name-private = Cadangan kunci privat { $who }.asc
# review: new
pgp-pending = Kunci yang berbeda untuk { $address } ditemukan pada { $date }.

## Reading signed and encrypted mail (protect.rs)
# review: new
pgp-part-verified = Ditandatangani oleh { $signer }, kunci terverifikasi
# review: new
pgp-part-signed = Ditandatangani oleh { $signer } (kunci belum diverifikasi)
# review: new
pgp-part-other = Ditandatangani oleh { $signer }, yang bukan pengirim
# review: new
pgp-part-unknown-key = Ditandatangani, tetapi kuncinya tidak dikenal
# review: new
pgp-part-not-signed = Tidak ditandatangani
# review: new
pgp-part-not-checked = Tanda tangan tidak diperiksa
# review: new
pgp-part-encrypted = Terenkripsi. { $signature }
# review: new
pgp-part-no-key = Dienkripsi untuk kunci yang tidak Anda miliki
# review: new
pgp-part-changed = Bagian terenkripsi gagal dalam pemeriksaan integritas dan tidak ditampilkan
# review: new
pgp-part-unprotected = Dienkripsi tanpa perlindungan terhadap perubahan, tidak ditampilkan
# review: new
pgp-part-broken = Bagian terenkripsi tidak dapat dibaca
# review: new
pgp-why-mismatch = Tanda tangan tidak cocok dengan teks ini
# review: new
pgp-why-weak-hash = Tanda tangan menggunakan { $hash }, yang sudah tidak aman
# review: new
pgp-why-key-expired = Ditandatangani setelah kunci kedaluwarsa pada { $date }
# review: new
pgp-why-key-revoked = Ditandatangani dengan kunci yang telah dicabut
# review: new
pgp-why-not-signing-key = Ditandatangani dengan kunci yang tidak boleh menandatangani
# review: new
pgp-why-from-future = Tanda tangan bertanggal di masa depan
# review: new
pgp-why-signature-expired = Tanda tangan telah kedaluwarsa
# review: new
pgp-why-key-not-valid = Ditandatangani dengan kunci yang tidak valid
# review: new
pgp-why-not-for-you = Ditandatangani untuk penerima lain, lalu diteruskan kepada Anda
# review: new
pgp-why-not-key-in-use = Ditandatangani dengan kunci selain kunci yang digunakan untuk { $address }
# review: new
pgp-part-pictures-loaded = { $label }. Gambar dimuat dari internet
# review: new
pgp-error-no-own-key = Anda tidak memiliki kunci untuk { $address } untuk menandatangani atau mengenkripsi. Buat kunci di Alat > Kunci Enkripsi, atau nonaktifkan Tanda Tangani dan Enkripsi.
# review: new
pgp-error-missing-keys = { $count ->
   *[other] Tidak ada kunci enkripsi yang dapat digunakan untuk penerima berikut: { $addresses }.
}
# review: new
pgp-error-encrypted-quote = Pesan ini berisi teks, gambar, atau lampiran dari email terenkripsi dan hanya dapat dikirim dalam keadaan terenkripsi. Aktifkan Enkripsi, atau hapus semua konten tersebut.
# review: new
pgp-error-protect = Pesan tidak dapat ditandatangani atau dienkripsi: { $reason }
# review: new
pgp-found-keys = Kunci ditemukan untuk: { $addresses }.
# review: new
pgp-found-none = Tidak ditemukan kunci untuk { $addresses }. Minta mereka mengirimkan kunci publiknya kepada Anda.
# review: new
pgp-found-no-key = Tidak ditemukan kunci.
# review: new
pgp-find-unavailable = Kunci tidak dapat dicari sekarang: { $error }
# review: new
pgp-publish-pending = keys.openpgp.org mengirim tautan konfirmasi ke alamat berikut: { $addresses }. Konfirmasikan setiap alamat agar kunci Anda dapat ditemukan menggunakan alamat tersebut.
# review: new
pgp-publish-done = Kunci Anda telah dipublikasikan di keys.openpgp.org untuk { $addresses }.
# review: new
pgp-publish-failed = Kunci tidak dapat dipublikasikan: { $error }
# review: new
pgp-keyserver-off = Pencarian kunci di keys.openpgp.org dinonaktifkan di { $settings }.
# the compose window with Sign and Encrypt: the line under the fields, each recipient's key, the questions
# review: new
pgp-compose-encrypted = { $count ->
    [1] Akan dienkripsi dan ditandatangani untuk Anda dan { $addresses }.
   *[other] Akan dienkripsi dan ditandatangani untuk Anda dan { $count } penerimanya.
}
# review: new
pgp-compose-encrypt-ready = Pesan akan dienkripsi dan ditandatangani. Tambahkan penerima yang kuncinya Anda miliki.
# review: new
pgp-compose-missing = { $count ->
    [1] Tidak ada kunci yang dapat digunakan untuk { $addresses }, jadi pesan belum dapat dienkripsi.
   *[other] { $count } penerima tidak memiliki kunci yang dapat digunakan, jadi pesan belum dapat dienkripsi: { $addresses }.
}
# review: new
pgp-compose-looking = Mencari kunci untuk { $addresses }...
# review: new
pgp-compose-signed = Akan ditandatangani saat dikirim: penerima dapat memeriksa bahwa konten yang ditandatangani tidak berubah. Mereka juga harus memverifikasi siapa pemilik kunci Anda.
# review: new
pgp-compose-reply-clear = Tidak dienkripsi, meskipun pesan yang dibalas atau diteruskan terenkripsi.
# review: new
pgp-compose-encrypted-files = File dari pesan terenkripsi dilampirkan, jadi pesan ini hanya dapat dikirim dalam keadaan terenkripsi. Aktifkan Enkripsi, atau hapus file tersebut.
# review: new
pgp-compose-sign-tip = Tanda tangani pesan agar penerima dapat memeriksa isinya. Mereka juga harus memverifikasi siapa pemilik kunci Anda
# review: new
pgp-compose-sign-tip-encrypted = Pesan terenkripsi selalu ditandatangani
# review: new
pgp-compose-encrypt-tip = Enkripsi pesan, agar hanya Anda dan penerimanya yang dapat membacanya
# review: new
pgp-compose-make-key = Anda belum memiliki kunci untuk { $address }. Buat sekarang? Dengan kunci, pesan Anda dapat ditandatangani dan dienkripsi.
# review: new
pgp-compose-key-unusable = Kunci Anda untuk { $address } tidak dapat digunakan. Alasan: { $state }. Buka Kunci Enkripsi untuk mengimpor cadangannya atau membuat kunci baru.
# review: new
pgp-compose-encrypt-off-quote = Pesan ini berisi teks, gambar, atau lampiran dari email terenkripsi. Tanpa enkripsi, pesan tidak dapat dikirim sampai Anda menghapus semua konten tersebut. Tetap nonaktifkan enkripsi?
# review: new
pgp-compose-encrypt-off-reply = Pesan ini membalas atau meneruskan pesan terenkripsi. Tanpa enkripsi, siapa pun yang menangani pesan Anda dalam perjalanan dapat membacanya. Nonaktifkan enkripsi?
# review: new
pgp-recipient-verified = Kunci terverifikasi
# review: new
pgp-recipient-found = Kunci belum diverifikasi
# review: new
pgp-recipient-own = Kunci Anda sendiri
# review: new
pgp-recipient-looking = Mencari kunci...
# review: new
pgp-recipient-missing = Tidak ada kunci
# review: new
pgp-recipient-not-found = Tidak ada kunci: tidak ditemukan pada { $date }
# review: new
pgp-recipient-unusable = Kunci tidak dapat digunakan: { $state }
# review: new
pgp-recipients-intro = Pesan dienkripsi dengan kunci setiap penerima, dan dengan kunci Anda.
# review: new
pgp-recipients-intro-missing = { $count ->
    [1] Satu penerima tidak memiliki kunci enkripsi yang dapat digunakan. Cari kuncinya atau hapus penerima tersebut. Pengiriman tanpa enkripsi baru tersedia setelah semua konten dari email terenkripsi dihapus.
   *[other] { $count } penerima tidak memiliki kunci enkripsi yang dapat digunakan. Cari kunci mereka atau hapus penerima tersebut. Pengiriman tanpa enkripsi baru tersedia setelah semua konten dari email terenkripsi dihapus.
}
# review: new
pgp-details-part = Bagian { $number }: { $label }
# review: new
attachment-from-part = Dari bagian { $number }: { $label }
# review: new
pgp-details-signed = Ditandatangani { $when } dengan kunci { $key }
# review: new
pgp-details-unknown-key = Ditandatangani dengan kunci { $key }, yang tidak Anda miliki
# review: new
pgp-details-opened = Didekripsi dengan kunci Anda { $key }
# review: new
pgp-details-for = Dienkripsi dengan kunci { $keys }
# review: new
pgp-details-plain = Tidak ditandatangani dan tidak dienkripsi
# review: new
pgp-bar-parts = Pesan ini memiliki { $count } bagian: { $list }. Setiap bagian menyebutkan cara perlindungannya.
# review: new
pgp-bar-count-verified = { $count } terverifikasi
# review: new
pgp-bar-count-encrypted-signed = { $count } terenkripsi dan ditandatangani
# review: new
pgp-bar-count-encrypted = { $count } terenkripsi
# review: new
pgp-bar-count-signed = { $count } ditandatangani
# review: new
pgp-bar-count-warning = { $count } perlu diperhatikan
# review: new
pgp-bar-count-neutral = { $count } tanpa tanda tangan yang terkonfirmasi
# the setup file: settings, accounts, contacts and keys carried to another computer
# review: new
setup-part-settings = Pengaturan
# review: new
setup-part-preferences = Preferensi jendela
# review: new
setup-part-accounts = Akun
# review: new
setup-part-sign-in-apps = Aplikasi masuk
# review: new
setup-part-contacts = Kontak dan grup
# review: new
setup-part-keys = Kunci enkripsi
# review: new
setup-part-rules = Aturan pesan
# review: new
setup-part-trusted-senders = Pengirim tepercaya
# review: new
setup-holds-settings = { $count } pengaturan
# review: new
setup-holds-preferences = { $count } preferensi
# review: new
setup-holds-accounts = { $count } akun
# review: new
setup-holds-sign-in-apps = { $count } aplikasi masuk
# review: new
setup-holds-built-in = Aplikasi masuk bawaan mana yang diaktifkan
# review: new
setup-holds-contacts = { $count } kontak
# review: new
setup-holds-groups = { $count } grup
# review: new
setup-holds-own-keys = { $count } kunci milik Anda
# review: new
setup-holds-contact-keys = { $count } kunci kontak
# review: new
setup-holds-rules = { $count } aturan
# review: new
setup-holds-trusted-senders = { $count } pengirim tepercaya
# review: new
setup-sign-in-password = Kata sandi
# review: new
setup-account-secret-password = Kata sandinya ada di dalam file.
# review: new
setup-account-secret-token = Kredensial masuk yang tersimpan ada di dalam file.
# review: new
setup-account-asks-password = Akun ini meminta kata sandinya setelah diimpor.
# review: new
setup-account-signs-in-again = Anda perlu masuk lagi ke akun ini setelah diimpor.
# review: new
setup-account-here = Akun ini sudah disiapkan di sini, jadi dilewati.
# review: new
setup-account-no-app = Akun ini masuk dengan { $app }, yang tidak disiapkan di sini. Impor juga aplikasi masuknya.
# review: new
setup-invalid-address = “{ $address }” bukan alamat email.
# review: new
setup-invalid-server = Pengaturan { $server } memiliki nama server, port, atau opsi keamanan yang tidak valid.
# review: new
setup-invalid-user = Akun ini tidak memiliki nama pengguna.
# review: new
setup-invalid-sign-in = Metode atau konfigurasi masuknya tidak didukung.
# review: new
setup-error-empty = File kosong.
# review: new
setup-error-too-large = File pengaturan melebihi batas ukuran.
# review: new
setup-error-not-setup = File ini bukan file pengaturan Inbox Classic.
# review: new
setup-error-damaged = File pengaturan rusak dan tidak dapat dibaca.
# review: new
setup-error-newer = Pengaturan ini disimpan oleh Inbox Classic yang lebih baru ({ $version }). Perbarui Inbox Classic, lalu impor lagi.
# review: new
setup-error-needs-passphrase = Pengaturan ini dilindungi dengan frasa sandi. Ketik frasa sandi yang digunakan saat menyimpannya.
# review: new
setup-error-wrong-passphrase = Itu bukan frasa sandi yang digunakan saat menyimpan pengaturan ini.
# review: new
setup-error-changed = File pengaturan gagal dalam pemeriksaan integritas. File mungkin telah diubah atau rusak dan tidak dapat diimpor.
# review: new
setup-error-read = File pengaturan tidak dapat dibaca: { $error }
# review: new
setup-error-write = Pengaturan tidak dapat disimpan: { $error }
# review: new
setup-error-no-parts = Pilih setidaknya satu bagian.
# review: new
setup-left-out = { $count } entri dari { $part } tidak dapat digunakan dan tidak disertakan.
# review: new
setup-imported-settings = Pengaturan telah diganti.
# review: new
setup-imported-preferences = Preferensi jendela telah diganti.
# review: new
setup-added-accounts = { $count } akun ditambahkan.
# review: new
setup-skipped-here = { $address } sudah disiapkan di sini, jadi dilewati.
# review: new
setup-skipped-no-app = { $address } dilewati: akun ini masuk dengan { $app }, yang tidak disiapkan di sini.
# review: new
setup-skipped-invalid = { $address } dilewati: { $reason }
# review: new
setup-asks-password = { $address } meminta kata sandinya saat terhubung.
# review: new
setup-signs-in-again = { $address } meminta Anda masuk lagi saat terhubung.
# review: new
setup-added-sign-in-apps = { $count } aplikasi masuk ditambahkan.
# review: new
setup-skipped-sign-in-apps = { $count } aplikasi masuk sudah disiapkan di sini.
# review: new
setup-added-contacts = { $count } kontak ditambahkan ke buku alamat.
# review: new
setup-skipped-contacts = { $count } kontak sudah ada di buku alamat.
# review: new
setup-added-groups = { $count } grup ditambahkan atau dilengkapi.
# review: new
setup-added-own-keys = { $count } kunci milik Anda ditambahkan.
# review: new
setup-added-contact-keys = { $count } kunci kontak ditambahkan.
# review: new
setup-added-rules = { $count } aturan pesan ditambahkan.
# review: new
setup-skipped-rules = { $count } aturan pesan sudah ada di sini.
# review: new
setup-skipped-rules-account = { $count } aturan pesan ditujukan untuk akun yang tidak ada di sini, jadi dilewati.
# review: new
setup-rules-waiting = { $count } aturan pesan menunggu folder tujuannya ditemukan selama sinkronisasi akun.
# review: new
setup-added-trusted-senders = { $count } pengirim tepercaya ditambahkan.
# review: new
setup-nothing = Tidak ada yang diimpor.
# review: new
setup-account-servers = { $imap } dan { $smtp } ({ $signin })
# review: new
setup-file-name = Pengaturan dan akun Inbox Classic
# review: new
setup-skipped-unreachable = { $name } dilewati: layanan masuknya tidak dapat dijangkau atau diperiksa. Periksa aplikasi yang diperlukan di Aplikasi Masuk sebelum mencoba lagi.
# review: new
attachment-runs-programs = “{ $name }” dapat menjalankan program, jadi Inbox Classic tidak membukanya. Simpan file ini, lalu buka sendiri jika Anda memercayai asalnya.
# review: new
attachment-decrypted-note = Lampiran ini berasal dari email terenkripsi. Untuk membukanya di aplikasi lain, Inbox Classic menyimpan salinan yang tidak terenkripsi di folder sementara untuk akun pengguna Anda. Saat dimulai, aplikasi mencoba menghapus salinan yang berusia lebih dari satu hari.
# a bar over the list when the server did not do what the user asked of messages, so they are as they were again
# review: new
undone-move = { $count ->
   *[other] Server tidak memindahkan { $messages } ke { $folder }, jadi pesan kembali ke { $from }: { $reason }
}
# review: new
undone-delete = { $count ->
   *[other] Server tidak menghapus { $messages }, jadi pesan kembali ke { $from }: { $reason }
}
# review: new
undone-archive = { $count ->
   *[other] Server tidak mengarsipkan { $messages }, jadi pesan kembali ke { $from }: { $reason }
}
# review: new
undone-read = { $count ->
   *[other] Server tidak menandai { $messages } sebagai sudah dibaca, jadi pesan kembali belum dibaca: { $reason }
}
# review: new
undone-unread = { $count ->
   *[other] Server tidak menandai { $messages } sebagai belum dibaca, jadi pesan kembali sudah dibaca: { $reason }
}
# review: new
undone-flags = { $count ->
   *[other] Server tidak mengubah bendera { $messages }, jadi pesan kembali seperti semula: { $reason }
}

## Previews of attachments: the pictures and PDF files shown in a message

# the reading option that turns PDF previews on and off (the apps show it)
# review: new
preview-pdf-option = Tampilkan file PDF di pesan
# the tile of a PDF file while PDF previews are off
# review: new
preview-pdf-off = File PDF tidak ditampilkan di pesan.
# the note where previews are, after the app ended while it was drawing a file of a message: { $option } is the option's name
# review: new
preview-pdf-off-crashed = Inbox Classic tertutup saat menampilkan file di sebuah pesan, jadi file PDF tidak lagi ditampilkan di pesan. Gambar tetap ditampilkan. Untuk menampilkan file PDF lagi, aktifkan { $option } di { $settings }.
# under the pages of a PDF file shown in a message: its page count and size ("3 pages, 84 KB")
# review: new
preview-pdf-details = { $count } halaman, { $size }
# what a screen reader says of a page of a PDF file shown in a message
# review: new
preview-page-alt = { $name }, halaman { $page } dari { $count }
# the link under the pages of a PDF file shown in a message, when it has more pages than are shown
# review: new
preview-more-pages = { $count ->
    [1] Buka untuk melihat halamannya
   *[other] Buka untuk melihat semua { $count } halaman
}
# after the files shown in a message, when it has more pictures and PDF files than are shown; the list is the
# strip of files over the message
# review: new
preview-more-files = { $count } file lainnya ada di daftar di atas
# the tile of a picture or PDF file of a message still downloading (the ellipsis as in reader-downloading)
# review: new
preview-tile-downloading = Mengunduh…
# the tile of a picture or PDF file whose size was not read in time when the message was shown: its preview
# comes in its place in a moment (the ellipsis as in reader-downloading)
# review: new
preview-tile-preparing = Menyiapkan…
# the tile of a picture in a format not shown yet: { $format } is its name (HEIC, AVIF, JPEG XL)
# review: new
preview-tile-format = Gambar { $format } belum dapat ditampilkan
# the tile of a PDF file that wants a password to open
# review: new
preview-tile-password = Dilindungi kata sandi: buka file untuk memasukkan kata sandi
# the tile of a picture or PDF file over the size or pixel limit
# review: new
preview-tile-too-large = Terlalu besar untuk ditampilkan
# the tile of a file that is broken, or not what its name says
# review: new
preview-tile-unreadable = Tidak dapat ditampilkan
# the tile of a file that took too long to draw
# review: new
preview-tile-timed-out = Pratinjau terlalu lama disiapkan
# the tile of a file that closed the app once while it was drawn: never drawn again
# review: new
preview-tile-crashed = Pratinjau tidak tersedia: upaya sebelumnya terhenti
# the tile of a file while previews are paused after a file took too long, until the app starts again
# review: new
preview-tile-off = Tidak ditampilkan sampai Inbox Classic dimulai lagi
# in a printout, for a file shown in the message that is not printed (a PDF file, a tile): { $details } is its size,
# or a PDF file's pages and size
# review: new
preview-not-printed = { $name } ({ $details }) tidak dicetak. Buka file untuk mencetaknya.
