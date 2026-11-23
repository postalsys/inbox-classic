# Draf terjemahan bahasa Indonesia, menunggu tinjauan penutur asli.
# What the core says, the same on every platform. Placeables in { $braces } are filled in by the code; keep them, in
# the place the language puts them. Plurals choose by the number: [one] and *[other] in English, the forms your
# language has in yours.

## Counts and sizes

messages = { $count } pesan
# the separator of decimals in sizes: 2.4 MB
decimal-separator = ,
# what goes between the items of a list of words (Read, organize and draft; Monday, Wednesday): a comma and a space
# here, 、 in Chinese and Japanese; the quotes keep the space, which a message would otherwise lose
list-separator = { ", " }
size-bytes = { $count } byte
size-kb = { $size } KB
size-mb = { $size } MB
size-gb = { $size } GB
send-delay-off = Nonaktif
send-delay-seconds = { $count } detik
# the status bar: "12 messages, 3 unread"
list-counts = { $messages }, { $unread } belum dibaca
list-counts-selected = { $messages }, { $unread } belum dibaca, { $selected } dipilih
# the status bar while searching: "12 found, 3 unread"
list-counts-found = { $found } ditemukan, { $unread } belum dibaca
list-counts-found-selected = { $found } ditemukan, { $unread } belum dibaca, { $selected } dipilih
list-counts-none = Tidak ada pesan yang ditemukan

## Special folders, as Outlook Express names them

folder-inbox = Kotak Masuk
folder-sent = Item Terkirim
folder-deleted = Item Terhapus
folder-drafts = Draf
folder-junk = Email Sampah
folder-archive = Arsip

## The reading pane

reader-no-message = Tidak ada pesan yang dipilih.
reader-downloading = Mengunduh pesan…
reader-downloading-detail = Pesan akan muncul di sini setelah unduhan selesai.
reader-downloading-size = Ukuran pesan ini { $size }. Pesan akan muncul di sini setelah diunduh.
reader-failed = Pesan tidak dapat diunduh
reader-failed-network = Koneksi ke server email tidak dapat dibuat atau terputus ({ $reason }).
reader-failed-sign-in = Server email tidak menerima proses masuk ({ $reason }). Periksa kata sandi atau masuk lagi di pengaturan akun.
reader-failed-security = Koneksi ke server email tidak dapat diamankan ({ $reason }).
reader-failed-other = Server email menjawab: { $reason }.
reader-retry-note = Pengunduhan akan dicoba lagi saat akun tersambung kembali.
reader-unreadable = Pesan ini tidak dapat ditampilkan: { $error }
message-source-title = Sumber Pesan: { $subject }
message-source-untitled = Sumber Pesan

## Printing a message, and the header of a message quoted in a reply or forward

header-from = Dari
header-date = Tanggal
header-to = Kepada
header-cc = Cc
header-sent = Terkirim
header-subject = Subjek
header-security = Keamanan
header-part = Bagian { $number }
quote-original = ----- Pesan Asli -----
fold-show-earlier = Tampilkan pesan sebelumnya

## Bounces: the card at the top of a notice that a message was not delivered

bounce-failed = Pesan Anda tidak terkirim
bounce-delayed = Pesan Anda belum terkirim
bounce-delayed-note = Server email Anda masih mencoba mengirimkannya. Anda tidak perlu mengirimnya lagi.
# the link to the message the notice is about, in Sent Items or another folder
bounce-show-message = Tampilkan pesan yang gagal terkirim
# the link of a delay's card to the message that is still on its way
bounce-show-delayed = Tampilkan pesan yang tertunda
bounce-what-to-do = Yang dapat Anda lakukan:
# what to do about a recipient the message is still on its way to: in the card of a delay, and in the card of a failure
bounce-delayed-do = Belum perlu apa-apa. Jika pesan tetap tidak dapat dikirim, Anda akan menerima pemberitahuan lain.
bounce-delayed-row-do = Belum perlu apa-apa. Server email Anda masih mencoba mengirimkannya, dan Anda akan menerima pemberitahuan lain jika tidak berhasil.
# folds the receiving server's own words
bounce-details = Detail
# a recipient the notice does not name
bounce-someone = Seorang penerima
# in Details: the server that refused the message, the status code it gave, and the server that wrote the notice
bounce-server = Server: { $server }
bounce-status = Status: { $status }
bounce-reported-by = Dilaporkan oleh: { $server }
bounce-retry-minutes = Server penerima meminta menunggu { $count } menit sebelum percobaan berikutnya.
bounce-retry-hours = Server penerima meminta menunggu { $count } jam sebelum percobaan berikutnya.
# the names of the blocklists, "Spamhaus ZEN, Barracuda"
bounce-blocklist = Daftar blokir: { $lists }
bounce-user-unknown = Alamat tidak ada
bounce-user-unknown-why = Server penerima tidak memiliki kotak surat dengan alamat ini. Mungkin alamatnya salah ketik, atau orang tersebut sudah tidak menggunakannya.
bounce-user-unknown-do = Periksa ejaan alamat, atau tanyakan alamat yang sekarang digunakan orang tersebut.
bounce-invalid-address = Alamat tidak valid
bounce-invalid-address-why = Alamat tidak ditulis dalam bentuk yang dapat dikirimi email.
bounce-invalid-address-do = Cari kesalahan ketik, seperti spasi, huruf yang hilang, atau tidak ada apa pun setelah @.
bounce-mailbox-disabled = Kotak surat ditutup
bounce-mailbox-disabled-why = Alamat ini ada, tetapi kotak suratnya telah dinonaktifkan atau tidak digunakan lagi.
bounce-mailbox-disabled-do = Hubungi orang tersebut dengan cara lain dan tanyakan alamat yang sekarang digunakannya.
bounce-mailbox-full = Kotak surat penuh
bounce-mailbox-full-why = Kotak surat penerima tidak memiliki ruang untuk email baru.
bounce-mailbox-full-do = Kirim lagi dalam beberapa hari, atau beri tahu orang tersebut dengan cara lain.
bounce-spam-blocked = Ditolak sebagai spam
bounce-spam-blocked-why = Server penerima menganggap pesan ini sebagai spam.
bounce-spam-blocked-do = Kirim lagi tanpa hal yang terlihat seperti spam, misalnya banyak tautan, tautan pendek, atau lampiran besar. Jika terus terjadi, tanyakan kepada penyedia email Anda.
bounce-virus-detected = Ditolak karena virus
bounce-virus-detected-why = Server penerima melaporkan virus atau konten berbahaya lain di dalam pesan atau lampirannya.
bounce-virus-detected-do = Periksa lampiran dengan pemindai virus. Beberapa server menolak semua program atau arsip, jadi bagikan file seperti itu sebagai tautan.
bounce-ip-blocklisted = Server email Anda ada di daftar blokir
bounce-ip-blocklisted-why = Server penerima menolak email dari server yang mengirim pesan Anda, karena alamat server tersebut ada di daftar blokir.
bounce-ip-blocklisted-do = Masalahnya bukan pada pesan. Teruskan pemberitahuan ini ke penyedia email Anda dan minta mereka mengeluarkan server tersebut dari daftar.
bounce-domain-blocklisted = Sebuah domain ada di daftar blokir
bounce-domain-blocklisted-why = Server penerima menolak pesan karena domain alamat Anda, atau domain dalam tautan pesan, ada di daftar blokir.
bounce-domain-blocklisted-do = Jika pesan berisi tautan, coba kirim tanpa tautan. Jika tidak, teruskan pemberitahuan ini kepada pengelola email domain Anda.
bounce-policy-blocked = Ditolak oleh aturan server penerima
bounce-policy-blocked-why = Aturan server penerima tidak meloloskan pesan ini, misalnya karena ukurannya, lampirannya, atau pengirimnya.
bounce-policy-blocked-do = Keterangan dari server di bagian Detail sering kali menyebutkan alasannya. Tanyakan kepada penerima apakah mereka dapat menerima email seperti itu.
bounce-geo-blocked = Ditolak karena asal pengirimannya
bounce-geo-blocked-why = Server penerima tidak menerima email dari negara atau jaringan tempat server email Anda berada.
bounce-geo-blocked-do = Hubungi orang tersebut dengan cara lain, atau tanyakan hal ini kepada penyedia email Anda.
bounce-relay-denied = Server menolak meneruskan pesan
bounce-relay-denied-why = Sebuah server menolak meneruskan pesan, sering kali karena pesan dikirim tanpa masuk atau melalui server yang tidak menangani penerima ini.
bounce-relay-denied-do = Periksa server keluar dan detail masuk di pengaturan akun.
bounce-auth-failure = Alamat pengirim Anda tidak dapat diverifikasi
bounce-auth-failure-why = Server penerima tidak dapat memastikan bahwa pesan benar-benar berasal dari domain Anda (SPF, DKIM, atau DMARC).
bounce-auth-failure-do = Teruskan pemberitahuan ini kepada pengelola email domain Anda: pengaturannya perlu diperbaiki. Sementara itu, mengirim melalui server penyedia Anda sendiri mungkin membantu.
bounce-rate-limited = Terlalu banyak email sekaligus
bounce-rate-limited-why = Untuk sementara, server penerima menerima lebih sedikit pesan dari server email Anda.
bounce-rate-limited-do = Tunggu sebentar dan kirim lagi. Saat menulis kepada banyak orang, kirim ke lebih sedikit penerima sekaligus.
bounce-greylisting = Ditahan sebentar
bounce-greylisting-why = Server penerima meminta pengirim yang tidak dikenal untuk mencoba lagi beberapa saat kemudian, sebuah pemeriksaan umum terhadap spam.
bounce-greylisting-do = Untuk penundaan sementara, server pengirim biasanya mencoba lagi. Jika pemberitahuan ini melaporkan kegagalan akhir, coba kirim pesan lagi nanti.
bounce-server-error = Server penerima mengalami masalah
bounce-server-error-why = Server penerima tidak dapat dijangkau, atau tidak dapat menerima pesan karena masalahnya sendiri.
bounce-server-error-do = Kirim lagi nanti. Jika terus gagal, periksa bagian alamat setelah @ untuk mencari kesalahan ketik.
bounce-unknown = Tidak terkirim
bounce-unknown-why = Pemberitahuan tidak menyebutkan alasannya dengan jelas.
bounce-unknown-do = Keterangan dari server di bagian Detail mungkin memberi informasi lebih lanjut. Jika tidak membantu, teruskan pemberitahuan ini ke penyedia email Anda.

## Several messages selected

selection-title = { $count } pesan dipilih
selection-unread = { $count } belum dibaca
selection-flagged = { $count } berbendera
delete-for-good-one = Pesan ini akan dihapus secara permanen. Hapus?
delete-for-good-all = { $count } pesan ini akan dihapus secara permanen. Hapus?
delete-for-good-some = { $count } dari { $total } pesan akan dihapus secara permanen. Hapus pesan?
done-read = { $count ->
   *[other] { $messages } ditandai sudah dibaca
}
done-unread = { $count ->
   *[other] { $messages } ditandai belum dibaca
}
done-flagged = { $count ->
   *[other] { $messages } diberi bendera
}
done-unflagged = Bendera dihapus dari { $messages }
done-deleted-for-good = { $count ->
   *[other] { $messages } dihapus secara permanen
}
done-archived = { $count ->
   *[other] { $messages } diarsipkan
}
done-moved = { $count ->
   *[other] { $messages } dipindahkan ke { $folder }
}
done-copied = { $count ->
   *[other] { $messages } disalin ke { $folder }
}
done-moving = { $count ->
   *[other] Memindahkan { $messages } ke { $folder }...
}
done-copying = { $count ->
   *[other] Menyalin { $messages } ke { $folder }...
}
done-moved-back = { $count ->
   *[other] { $messages } dipindahkan kembali ke { $folder }
}
# the status bar after Watch Conversation and Ignore Conversation, and after either again on a marked one
done-watched = { $count ->
    [1] Memantau percakapan
   *[other] Memantau { $count } percakapan
}
done-unwatched = { $count ->
    [1] Berhenti memantau percakapan
   *[other] Berhenti memantau { $count } percakapan
}
done-ignored = { $count ->
    [1] Mengabaikan percakapan
   *[other] Mengabaikan { $count } percakapan
}
done-unignored = { $count ->
    [1] Berhenti mengabaikan percakapan
   *[other] Berhenti mengabaikan { $count } percakapan
}
their-folders = folder asalnya
undo-move = Batalkan Pemindahan
undo-delete = Batalkan Penghapusan
undo-archive = Batalkan Pengarsipan
undo-junk = Batalkan Penandaan sebagai Sampah
undo-not-junk = Batalkan Penandaan sebagai Bukan Sampah
undo-send = Batalkan Pengiriman
nothing-to-undo = Tidak ada yang dapat dibatalkan.
messages-gone = Pesan sudah tidak ada lagi.
# A non-selectable IMAP folder cannot contain messages; this does not mean it is empty.
folder-holds-no-messages = Folder ini tidak dapat berisi pesan.
not-archived-here = Pesan di folder ini tidak dapat diarsipkan.
not-emptied-here = Hanya Item Terhapus dan Email Sampah yang dapat dikosongkan.
next-unread-question = Tidak ada lagi pesan yang belum dibaca di { $folder }.

    Buka { $next }, folder berikutnya yang berisi pesan belum dibaca?
no-unread-left = Tidak ada lagi pesan yang belum dibaca.
empty-question = { $count ->
    [1] Kosongkan { $folder }?

        Pesan di dalamnya akan dihapus secara permanen dan tidak dapat dikembalikan.
   *[other] Kosongkan { $folder }?

        { $messages } di dalamnya akan dihapus secara permanen dan tidak dapat dikembalikan.
}
no-junk-folder = Akun ini tidak memiliki folder Email Sampah untuk tujuan pemindahan pesan.
no-inbox-folder = Akun ini tidak memiliki folder Kotak Masuk untuk tujuan pemindahan pesan.
# the status bar after a flag in a colour: "Flagged 2 messages blue"
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

move-window-title-move = { $count ->
    [1] Pindahkan Pesan
   *[other] Pindahkan { $count } Pesan
}
move-window-title-copy = { $count ->
    [1] Salin Pesan
   *[other] Salin { $count } Pesan
}
move-window-prompt-move = { $count ->
    [1] Pindahkan pesan yang dipilih ke:
   *[other] Pindahkan { $count } pesan yang dipilih ke:
}
move-window-prompt-copy = { $count ->
    [1] Salin pesan yang dipilih ke:
   *[other] Salin { $count } pesan yang dipilih ke:
}
# the folders used last, over the folder tree
targets-recent = Terbaru
# the folder the messages are in, which can not be chosen
target-current = { $folder } (saat ini)
# a folder used last, with its account when there are several: "Archive (Work)"
target-recent = { $folder } ({ $account })

## Moving and copying to another account

transfer-moving = Memindahkan { $done } dari { $messages } ke { $folder }...
transfer-copying = Menyalin { $done } dari { $messages } ke { $folder }...
transfer-another-account = akun lain
transfer-folder-gone = folder tujuannya sudah tidak ada
transfer-not-on-server = pesan sudah tidak ada di server
transfer-not-moved = { $count ->
   *[other] { $messages } tidak dapat dipindahkan ke akun lain: { $reason }
}
transfer-not-copied = { $count ->
   *[other] { $messages } tidak dapat disalin ke akun lain: { $reason }
}
transfer-none-moved = Tidak ada pesan yang dapat dipindahkan
transfer-none-copied = Tidak ada pesan yang dapat disalin

## Messages as files

export-not-in-time = pesan tidak dapat diunduh tepat waktu
export-not-saved = { $failed } dari { $messages } tidak dapat disimpan ({ $problems })
export-not-attached = pesan tidak dapat dilampirkan: { $error }
# the status bar after Save As with several: "Saved 3 messages to Desktop"
saved-to = { $count ->
   *[other] { $messages } disimpan ke { $folder }
}
download-progress = Mengunduh { $done } dari { $total }
download-done = Diunduh: { $size }
downloading-messages = { $count ->
   *[other] Mengunduh { $messages }...
}
# the status bar after files are dropped on a folder: "Put 3 messages in Archive"
import-put = { $count ->
   *[other] { $messages } diantrekan untuk diimpor ke { $folder }
}
import-not-put = Item berikut tidak dimasukkan ke folder:

    { $problems }

## Problems the windows show

error-store = penyimpanan lokal: { $error }
error-not-found = tidak ditemukan
error-closed = sedang dimatikan
error-other-account = browser masuk ke { $email }, bukan ke akun ini
# a password or sign-in the mail server refused, with the server's words
failure-authentication = server tidak menerima proses masuk ({ $reason })
# the mail server could not be reached or the connection broke, with the reason
failure-network = koneksi ke server gagal ({ $reason })
error-in-use = aplikasi ini tidak dapat dihapus selama ada akun yang masuk dengannya: { $accounts }
error-turned-off = aplikasi masuk ini dinonaktifkan untuk akun baru
error-folder-name = nama folder harus terdiri dari 1 sampai 200 karakter dan tidak boleh berisi karakter kontrol
error-folder-separator = nama folder tidak boleh berisi “{ $separator }” di server ini
error-folder-special = Kotak Masuk dan folder khusus tidak dapat diganti namanya atau dihapus
error-no-recipients = pesan tidak memiliki penerima
error-bad-address = “{ $address }” bukan alamat email
error-not-own-address = { $address } bukan salah satu alamat pengirim akun ini. Tambahkan alamat tersebut ke “Alamat lain yang Anda gunakan untuk mengirim” di properti akun.
rule-query-refused = Aturan tidak dapat memfilter menurut folder atau tanggal ({ $words }).
rule-no-query = Masukkan kriteria pencarian untuk pesan masuk.
rule-no-action = Pilih setidaknya satu tindakan untuk aturan ini.
error-attachment = { $path } tidak dapat dibaca: { $error }
error-no-drafts = akun ini tidak memiliki folder Draf untuk menyimpan pesan
error-draft-attachment = lampiran draf tidak dapat dipertahankan: { $error }
error-password-not-saved = kata sandi tidak dapat disimpan untuk saat program dimulai berikutnya: { $error }
error-sign-in-not-saved = detail masuk yang baru tidak dapat disimpan untuk saat program dimulai berikutnya: { $error }
error-import-unreadable = { $path } tidak dapat dibaca: { $error }
error-import-too-large = { $path } lebih besar dari 50 MB
error-import-not-mail = { $path } bukan pesan email
error-list-answered = server milis mengembalikan status { $status }
error-not-built = pesan tidak dapat disusun
error-outbox-waits = { $count ->
    [1] pesan tetap di Kotak Keluar; Kirim/Terima berikutnya akan mencoba mengirimnya lagi
   *[other] { $count } pesan tetap di Kotak Keluar; Kirim/Terima berikutnya akan mencoba mengirimnya lagi
}
error-draft-not-removed = draf pesan sebelumnya tidak dapat dihapus dari Draf: { $reason }
error-sent-but = pesan telah terkirim, tetapi { $problem }
error-sent-still-in-outbox = pesan masih ada di Kotak Keluar: { $error }
error-sent-no-copy = tidak ada salinan yang dapat disimpan di Item Terkirim: { $reason }
error-no-password = tidak ada kata sandi untuk akun ini
error-no-sign-in = tidak ada data masuk untuk akun ini
error-provider-missing = aplikasi masuk tidak tersedia di build ini (ID: { $provider }). Aplikasi ini mungkin telah dihapus
error-provider-servers = server akun ini tidak cocok dengan server aplikasi masuknya
error-app-scopes = { $reason }. Server email tidak menerima token aplikasi masuk: pastikan cakupan (scopes) aplikasi memberikan akses ke email
error-in-folder = { $folder }: { $reason }

## Sign-in apps

sign-in-off-google = Aplikasi masuk Google bawaan disiapkan untuk pengguna uji yang disetujui dan secara default dinonaktifkan untuk akun baru. Pengguna uji dapat mengaktifkannya di Aplikasi Masuk (File > Akun). Anda juga dapat menggunakan aplikasi masuk Google Anda sendiri, atau kata sandi aplikasi jika akun Anda mendukungnya.
sign-in-off-other = Aplikasi ini dinonaktifkan untuk akun baru. Anda dapat mengaktifkannya di Aplikasi Masuk (File > Akun).
sign-in-app-no-name = aplikasi masuk memerlukan nama
sign-in-app-no-client = ID klien tidak ada
sign-in-app-no-scopes = aplikasi masuk memerlukan cakupan (scopes) yang memberikan akses ke email
sign-in-app-bad-host = alamat server { $server } tidak ada atau bukan nama host yang valid
sign-in-app-plain = server { $server } harus menggunakan SSL/TLS atau STARTTLS
sign-in-app-not-checked = penerbit belum diperiksa
sign-in-app-issuer-changed = penerbit berubah: ketik rahasia klien lagi, atau hapus rahasia tersebut
sign-in-register-google = Di Google Cloud Console, buat klien OAuth dengan jenis Desktop app, dengan cakupan https://mail.google.com/ di layar izinnya. Selama aplikasi dalam tahap pengujian, hanya pengguna ujinya yang dapat masuk.
sign-in-register-microsoft = Di Microsoft Entra, daftarkan aplikasi dengan platform Mobile and desktop applications, URI pengalihan http://localhost, alur klien publik diizinkan, dan izin delegasi IMAP.AccessAsUser.All, SMTP.Send, serta offline_access. Khusus untuk organisasi Anda, gunakan https://login.microsoftonline.com/<tenant ID>/v2.0 sebagai penerbit.
sign-in-register-other = Daftarkan klien native (publik) dengan URI pengalihan di bawah ini; penyedia harus mengizinkan port apa pun pada URI tersebut (RFC 8252). Tambahkan cakupan yang digunakan penyedia untuk memberikan akses ke email.

## Calendar invitations

repeats = Berulang
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
repeats-on = { $repeats } pada hari { $days }
# "Every week, 10 times"
repeats-times = { $count ->
    [1] { $repeats }, sekali
   *[other] { $repeats }, { $count } kali
}
day-monday = Senin
day-tuesday = Selasa
day-wednesday = Rabu
day-thursday = Kamis
day-friday = Jumat
day-saturday = Sabtu
day-sunday = Minggu

## AI agents

agent-level-read = Membaca email: folder, daftar pesan, percakapan, pencarian, pesan beserta filenya, aturan pesan Anda, dan orang-orang yang Anda kirimi pesan
agent-level-organize = Mengatur email: status baca, bendera dan warnanya, sampah, pemindahan, pengarsipan, pembuatan dan penggantian nama folder, pemantauan dan pengabaian percakapan, penghapusan ke Item Terhapus, dan keluar dari milis setelah Anda setuju
agent-level-drafts = Menulis draf untuk Anda kirim
agent-level-send = Mengirim email, setiap pesan hanya setelah Anda setuju
agent-connect-title = { $program } ingin menggunakan email Anda
agent-connect-detail = Sebuah agen AI meminta untuk bekerja dengan Inbox Classic. Pilih apa yang boleh dilakukannya dan akun mana yang boleh dilihatnya; Anda dapat mengubahnya nanti di Alat > Agen AI.

    Agen membaca email yang ditulis orang lain, dan sebuah pesan dapat mencoba menipunya. Inbox Classic selalu bertanya kepada Anda sebelum agen mengirim apa pun.
agent-reply-to = Balasan untuk “{ $subject }”
agent-reply-all-on = Balasan ke semua untuk “{ $subject }”
agent-forward-of = Penerusan “{ $subject }”
agent-never-written-one = Anda belum pernah mengirim pesan ke { $address }.
agent-never-written-many = Anda belum pernah mengirim pesan ke { $count } dari alamat ini.
agent-send-title = { $program } ingin mengirim pesan ini
agent-send-detail = Periksa penerima dan isi pesan. Setelah Anda mengonfirmasi, pesan menunggu { $seconds } detik di Kotak Keluar, tempat Anda masih dapat menghapusnya.
agent-change-title = Yang boleh dilakukan { $program }
agent-change-allowed = Ubah apa yang boleh dilakukan agen AI program ini terhadap email Anda.
agent-change-refused = Anda menolak akses program ini. Izinkan program ini agar agennya dapat mengakses email Anda lagi.
agent-log-taken-back = { $entry } (ditarik kembali)
agent-files = File: { $files }
agent-undo-refused = Ini tidak dapat ditarik kembali.
agent-undo-refused-why = Ini tidak dapat ditarik kembali: { $reason }.
agent-undo-impossible = ini tidak dapat ditarik kembali
agent-undo-not-in-folder = pesan sudah tidak ada di folder tersebut
agent-undo-not-arrived = pesan (belum) ada di folder tujuannya
agent-undo-sent = pesan sudah tidak ada di Kotak Keluar
agent-original-not-downloaded = pesan aslinya belum diunduh. Buka pesan tersebut terlebih dahulu
agent-turned-away = Ditolak
agent-can-nothing = Tidak ada
agent-can-read = membaca
agent-can-organize = mengatur
agent-can-drafts = menulis draf
agent-can-send = mengirim dengan persetujuan Anda
# "Read, organize and write drafts"
agent-can-list = { $first } dan { $last }
agent-accounts = { $count ->
    [0] tidak ada akun
   *[other] { $count } akun
}
# "Read and organize; 1 account"
agent-access = { $can }; { $accounts }
agent-unreadable = Pesan ini tidak dapat dibaca.
agent-encrypted-original = Pesan ini terenkripsi: agen tidak dapat membalas atau meneruskannya, karena agen tidak dapat mengenkripsi.
agent-encrypted = Pesan ini terenkripsi. Agen AI tidak dapat membaca isinya. Buka di Inbox Classic untuk membacanya sendiri.
agent-too-many-changes = Terlalu banyak perubahan dalam 30 hari terakhir: agen ini telah membuat perubahan sebanyak yang dapat disimpan Inbox Classic di lognya untuk satu program. Agen dapat membuat perubahan lagi setelah yang terlama berusia 30 hari.
agent-too-many-reads = Terlalu banyak pembacaan dalam 30 hari terakhir: agen ini telah membaca sebanyak yang dapat disimpan Inbox Classic di lognya untuk satu program. Agen dapat membaca lagi setelah pembacaan terlama berusia 30 hari.
list-encrypted = Pesan terenkripsi
agent-log-composed = Membuka “{ $subject }” di pesan baru untuk Anda selesaikan
agent-log-refused = Anda tidak mengirim “{ $subject }”
agent-log-sent = Memasukkan “{ $subject }” ke Kotak Keluar untuk { $to }
agent-log-draft = Menyimpan draf “{ $subject }”
agent-log-draft-replaced = Mengganti draf “{ $subject }”
agent-log-draft-discarded = Meminta penghapusan draf “{ $subject }”
agent-draft-note = { $program }, sebuah agen AI, menulis draf ini. Periksa penerima dan teksnya sebelum Anda mengirimnya.
agent-log-read = Menandai “{ $subject }” sebagai sudah dibaca
agent-log-unread = Menandai “{ $subject }” sebagai belum dibaca
agent-log-flagged = Memberi bendera pada “{ $subject }”
agent-log-unflagged = Menghapus bendera dari “{ $subject }”
agent-log-deleted = Menghapus “{ $subject }”
agent-log-moved = Memindahkan “{ $subject }” ke { $folder }
agent-log-junk = Menandai “{ $subject }” sebagai sampah
agent-log-not-junk = Menandai “{ $subject }” sebagai bukan sampah
agent-log-archived = Mengarsipkan “{ $subject }”
agent-log-folder = Meminta pembuatan folder “{ $name }”
# written at the user's yes, before the list is asked; a list that fails replaces it with agent-log-unsubscribe-failed
agent-log-unsubscribed = Anda setuju untuk berhenti berlangganan milis dari pesan “{ $subject }”
agent-log-unsubscribe-failed = Tidak dapat berhenti berlangganan milis dari pesan “{ $subject }”: { $reason }
# "You did not unsubscribe from news@shop.example, deals@example.com": the lists' addresses, never their names
agent-log-unsubscribe-refused = Anda tidak menyetujui permintaan berhenti berlangganan untuk: { $senders }
agent-unsubscribe-title = { $count ->
    [1] { $program } ingin menghentikan langganan Anda pada sebuah milis
   *[other] { $program } ingin menghentikan langganan Anda pada { $count } milis
}
agent-unsubscribe-detail = { $count ->
    [1] Inbox Classic meminta milis di bawah ini berhenti mengirimi Anda pesan, dengan cara sekali klik yang disediakannya. Tidak ada hal lain yang dikirim, dan pesan yang sudah Anda miliki tetap di tempatnya.
   *[other] Inbox Classic meminta setiap milis di bawah ini berhenti mengirimi Anda pesan, dengan cara sekali klik yang disediakan milis tersebut. Tidak ada hal lain yang dikirim, dan pesan yang sudah Anda miliki tetap di tempatnya.
}
agent-log-flag-color = Memberi bendera { $color ->
    [red] merah
    [orange] oranye
    [yellow] kuning
    [green] hijau
    [blue] biru
    [purple] ungu
   *[gray] abu-abu
} pada “{ $subject }”
agent-log-renamed = Meminta penggantian nama folder “{ $old }” menjadi “{ $name }”
agent-log-watched = Memantau percakapan “{ $subject }”
agent-log-ignored = Mengabaikan percakapan “{ $subject }”
agent-log-unmarked = Berhenti memantau atau mengabaikan percakapan “{ $subject }”
# the reason one change can not be taken back (agent-undo-refused-why)
agent-undo-changed = pesan telah diubah sejak itu
# one change of many messages an agent made with a search (apply_to_search), a row of the log; { $query } is the search
agent-log-bulk-read = Menandai { $count } pesan sebagai sudah dibaca (pencarian: { $query })
agent-log-bulk-unread = Menandai { $count } pesan sebagai belum dibaca (pencarian: { $query })
agent-log-bulk-flagged = Memberi bendera pada { $count } pesan (pencarian: { $query })
agent-log-bulk-unflagged = Menghapus bendera dari { $count } pesan (pencarian: { $query })
agent-log-bulk-color = Memberi bendera { $color ->
    [red] merah
    [orange] oranye
    [yellow] kuning
    [green] hijau
    [blue] biru
    [purple] ungu
   *[gray] abu-abu
} pada { $count } pesan (pencarian: { $query })
agent-log-bulk-moved = Memindahkan { $count } pesan ke { $folder } (pencarian: { $query })
agent-log-bulk-archived = Mengarsipkan { $count } pesan (pencarian: { $query })
agent-log-bulk-junk = Menandai { $count } pesan sebagai sampah (pencarian: { $query })
agent-log-bulk-not-junk = Menandai { $count } pesan sebagai bukan sampah (pencarian: { $query })
agent-log-bulk-deleted = Menghapus { $count } pesan (pencarian: { $query })
# Undo Everything Since in the AI Agents window: how far back it reaches
agent-undo-span = { $span ->
    [quarter] Dalam 15 menit terakhir
    [hour] Dalam 1 jam terakhir
    [hours] Dalam 4 jam terakhir
    [day] Dalam 24 jam terakhir
    [week] Dalam 7 hari terakhir
   *[all] Dalam 30 hari terakhir
}
# the question before it takes back what a program did in the span chosen
agent-undo-since-question = { $count ->
    [0] { $program } tidak memiliki perubahan dalam periode ini yang dapat ditarik kembali.
    [1] Coba tarik kembali perubahan yang tercatat untuk { $program } dalam periode ini?
   *[other] Coba tarik kembali { $count } perubahan yang tercatat untuk { $program } dalam periode ini?
}
agent-undo-since-detail = Inbox Classic mencoba memulihkan folder, status baca, dan bendera, serta menghapus pesan yang masih menunggu di Kotak Keluar. Perubahan yang tidak dapat dibatalkan lagi dilewati. Beberapa perubahan warna bendera yang lebih baru dapat tertimpa.
# what taking back did, then a line for each kind of message it left as it is
agent-undo-done = { $count ->
    [0] Tidak ada yang ditarik kembali.
   *[other] { $count } perubahan tercatat ditarik kembali, seluruhnya atau sebagian.
}
agent-undo-left-gone = { $count } pesan sudah tidak berada di tempat yang ditentukan oleh perubahan.
agent-undo-left-changed = { $count } pesan telah berubah sejak itu, oleh Anda atau di server, dan dibiarkan apa adanya.
agent-undo-left-sent = { $count } pesan sudah keluar dari Kotak Keluar.
agent-undo-left-impossible = { $count } perubahan tidak dapat ditarik kembali.
# the Send question of an agent's answer to a calendar invitation: what it answers, and when the event is
agent-invitation-reply = { $response ->
    [accept] Pesan ini menerima undangan “{ $summary }” ({ $when }).
    [tentative] Pesan ini menerima undangan “{ $summary }” secara tentatif ({ $when }).
   *[decline] Pesan ini menolak undangan “{ $summary }” ({ $when }).
} Pesan dikirim ke penyelenggara yang disebutkan dalam undangan. Tanggapan lokal Anda berubah setelah server email menerima pesan, tanpa konfirmasi dari kalender penyelenggara.
# the subject of an answer to an invitation, as calendar programs write it
invitation-reply-subject = { $response ->
    [accept] Diterima: { $summary }
    [tentative] Tentatif: { $summary }
   *[decline] Ditolak: { $summary }
}
# the text of an answer to an invitation; { $name } is the user's name, or address
invitation-reply-text = { $response ->
    [accept] { $name } telah menerima undangan ini.
    [tentative] { $name } telah menerima undangan ini secara tentatif.
   *[decline] { $name } telah menolak undangan ini.
}
# what a program read in an hour, a row of the log: "Read 14 messages and searched 3 times" (joined by agent-can-list)
agent-reads-messages = membaca { $count } pesan
agent-reads-attachments = meminta { $count } lampiran
agent-reads-searches = { $count ->
    [1] mencari sekali
   *[other] mencari { $count } kali
}
agent-reads-lists = { $count ->
    [1] melihat daftar pesan sekali
   *[other] melihat daftar pesan { $count } kali
}
# each read under that row
agent-read-message = Membaca “{ $subject }”
agent-read-conversation = Membaca percakapan “{ $subject }” ({ $count } pesan)
agent-read-attachment = Meminta lampiran “{ $name }” dari “{ $subject }”
agent-read-search = Mencari “{ $query }”: { $count } pesan
agent-read-people = Mencari orang berdasarkan nama atau alamatnya: “{ $query }”
agent-read-list = Melihat { $count } entri daftar (lingkup: { $folder })
agent-read-changes = Melihat detail { $count } pesan baru
# the programs started from a terminal app, which share one access: in the list of programs and the question when one connects
agent-terminal-programs-mac = Program yang dijalankan dari { $terminal }
agent-terminal-programs-windows = Program yang dijalankan dari terminal ({ $terminal })
agent-terminal-programs-linux = Program yang dijalankan dari terminal ({ $terminal })
# one of them, as the questions to send or unsubscribe name it: "A program started from Terminal wants to send this message"
agent-terminal-program-mac = Sebuah program yang dijalankan dari { $terminal }
agent-terminal-program-windows = Sebuah program yang dijalankan dari terminal ({ $terminal })
agent-terminal-program-linux = Sebuah program yang dijalankan dari terminal ({ $terminal })
agent-connect-title-terminal = { $programs } ingin menggunakan email Anda
agent-connect-terminal-detail = Agen AI yang dijalankan dari program terminal yang sama dan dikenali berbagi akses yang Anda izinkan di sini. Untuk memberi satu agen akses tersendiri, tambahkan --name dan nama pilihan Anda ke argumennya di pengaturan MCP agen tersebut. Nama itu tidak memverifikasi identitasnya.
# above the question when a program said it was another one than the system found: "It said it was Claude. Inbox Classic checked which program started it: python3."
agent-connect-claimed = Program ini mengaku sebagai { $claimed }. Inbox Classic memeriksa program mana yang menjalankannya: { $program }.

## Keys as the keyboards of the language name them, in the help (Windows and Linux)

key-ctrl = Ctrl
key-alt = Alt
key-shift = Shift
key-del = Del
key-enter = Enter

## Signing in and passwords

sign-in-no-refresh = penyedia tidak memberikan token penyegaran
sign-in-no-account = penyedia tidak menyebutkan akun mana yang masuk
sign-in-not-finished = proses masuk belum selesai
secrets-unavailable = { $store } tidak tersedia
secrets-unavailable-why = { $store } tidak tersedia: { $error }
secrets-windows = Manajer Kredensial
secrets-mac = rantai kunci
secrets-linux = keyring sistem (Secret Service)
error-no-such-file = file tidak ada
cards-file-too-big = File ini melebihi batas ukuran untuk mengimpor buku alamat.
ui-sender-added = { $name } ditambahkan ke Buku Alamat.
ui-sender-known = { $name } sudah ada di Buku Alamat.
ui-sender-none = Pengirim pesan ini tidak memiliki alamat email untuk ditambahkan.
card-name-needed = Kontak ini tidak memiliki nama dan alamat email.
# a file of Import Address Book that could not be read: "contacts.vcf: there is no such file"
cards-file-failed = { $file }: { $reason }

## One-time codes: the card at the top of a message with a sign-in or verification code

# the domain the code is for, which signed the message
otp-heading = Kode dari { $domain }
otp-copy = Salin
otp-note = Masukkan kode ini hanya di halaman { $domain }.
otp-old = Kode ini dikirim lebih dari satu jam sebelum Anda membukanya, dan kemungkinan sudah kedaluwarsa.

# how many are invited, in the card of an event
event-attendees = { $count } peserta

# the first line of a new message's notification when it has a code, for a domain that signed it
otp-notification = { $code } adalah kode Anda untuk { $domain }

## OpenPGP keys (keys.rs)
pgp-key-valid = Valid
pgp-key-expires = Valid hingga { $date }
pgp-key-expired = Kedaluwarsa pada { $date }
pgp-key-revoked = Dicabut
pgp-key-revoked-why = Dicabut: { $reason }
pgp-key-not-valid = Tidak valid
pgp-key-locked = Tidak dapat digunakan: kunci pelindungnya tidak tersedia di { $store }. Pastikan penyimpanan tersebut tersedia dan tidak terkunci. Jika kunci pelindung hilang, impor cadangan kunci privat.
pgp-source-own = Dibuat di Inbox Classic
pgp-source-file = Diimpor dari file
pgp-source-paste = Ditempel
pgp-source-attachment = Dari pesan
pgp-source-vcard = Dari kartu kontak
pgp-source-wkd = Dari penyedia email pengirim
pgp-source-keyserver = Dari keys.openpgp.org
pgp-source-autocrypt = Dari header Autocrypt pesan
pgp-error-no-store = Kunci pelindung untuk kunci privat Anda disimpan di { $store }, yang tidak dapat digunakan: { $error }
pgp-error-wrong-passphrase = Frasa sandi salah.
pgp-error-not-a-key = Ini bukan kunci OpenPGP.
pgp-error-too-large = Kunci terlalu besar.
pgp-error-unusable = Kunci tidak dapat digunakan. Kunci ini mungkin tidak memiliki kunci penandatanganan atau enkripsi yang sesuai, atau menggunakan kriptografi yang tidak didukung.
pgp-imported-private = { $count ->
    [1] Kunci privat Anda telah diimpor.
   *[other] { $count } kunci privat telah diimpor.
}
pgp-imported-public = { $count ->
    [1] Satu kunci telah diimpor.
   *[other] { $count } kunci telah diimpor.
}
pgp-imported-pending = Kunci lain sudah digunakan untuk { $addresses }: kunci baru menunggu di kontak sampai Anda memilihnya.
pgp-error-needs-passphrase = Kunci privat dilindungi dengan frasa sandi. Ketik frasa sandi untuk mengimpor kunci.
pgp-error-mismatch = Kunci privat ini bukan pasangan kunci publiknya. Kunci mungkin telah diubah.
pgp-file-name-public = Kunci publik { $who }.asc
pgp-file-name-private = Cadangan kunci privat { $who }.asc
pgp-pending = Kunci yang berbeda untuk { $address } ditemukan pada { $date }.

## Reading signed and encrypted mail (protect.rs)
pgp-part-verified = Ditandatangani oleh { $signer }, pemilik kunci terverifikasi
pgp-part-signed = Ditandatangani oleh { $signer } (pemilik kunci belum diverifikasi)
pgp-part-other = Ditandatangani oleh { $signer }, yang bukan pengirim
pgp-part-unknown-key = Ditandatangani, tetapi kuncinya tidak dikenal
pgp-part-not-signed = Tidak ditandatangani
pgp-part-not-checked = Tanda tangan tidak diperiksa
pgp-part-encrypted = Terenkripsi. { $signature }
pgp-part-no-key = Dienkripsi untuk kunci yang tidak Anda miliki
pgp-part-changed = Bagian terenkripsi gagal dalam pemeriksaan integritas dan tidak ditampilkan
pgp-part-unprotected = Dienkripsi tanpa perlindungan terhadap perubahan, tidak ditampilkan
pgp-part-broken = Bagian terenkripsi tidak dapat dibaca
pgp-why-mismatch = Tanda tangan tidak cocok dengan teks ini
pgp-why-weak-hash = Tanda tangan menggunakan { $hash }, yang sudah tidak aman
pgp-why-key-expired = Ditandatangani setelah kunci kedaluwarsa pada { $date }
pgp-why-key-revoked = Ditandatangani dengan kunci yang telah dicabut
pgp-why-not-signing-key = Ditandatangani dengan kunci yang tidak boleh menandatangani
pgp-why-from-future = Tanda tangan bertanggal di masa depan
pgp-why-signature-expired = Tanda tangan telah kedaluwarsa
pgp-why-key-not-valid = Ditandatangani dengan kunci yang tidak valid
pgp-why-not-for-you = Ditandatangani untuk penerima lain, lalu diteruskan kepada Anda
pgp-why-not-key-in-use = Ditandatangani dengan kunci selain kunci yang digunakan untuk { $address }
pgp-part-pictures-loaded = { $label }. Gambar dimuat dari internet
pgp-error-no-own-key = Anda tidak memiliki kunci untuk { $address } untuk menandatangani atau mengenkripsi. Buat kunci di Alat > Kunci Enkripsi, atau nonaktifkan Tanda Tangani dan Enkripsi.
pgp-error-missing-keys = { $count ->
   *[other] Tidak ada kunci enkripsi yang dapat digunakan untuk penerima berikut: { $addresses }.
}
pgp-error-encrypted-quote = Pesan ini berisi teks, gambar, atau lampiran dari email terenkripsi dan hanya dapat dikirim dalam keadaan terenkripsi. Aktifkan Enkripsi, atau hapus semua konten tersebut.
pgp-error-protect = Pesan tidak dapat ditandatangani atau dienkripsi: { $reason }
pgp-found-keys = Kunci ditemukan untuk: { $addresses }.
pgp-found-none = Tidak ditemukan kunci untuk { $addresses }. Minta mereka mengirimkan kunci publiknya kepada Anda.
pgp-found-no-key = Tidak ditemukan kunci.
pgp-find-unavailable = Kunci tidak dapat dicari sekarang: { $error }
pgp-publish-pending = keys.openpgp.org mengirim tautan konfirmasi ke alamat berikut: { $addresses }. Konfirmasikan setiap alamat agar kunci Anda dapat ditemukan menggunakan alamat tersebut.
pgp-publish-done = Kunci Anda telah dipublikasikan di keys.openpgp.org untuk { $addresses }.
pgp-publish-failed = Kunci tidak dapat dipublikasikan: { $error }
pgp-keyserver-off = Pencarian kunci di keys.openpgp.org dinonaktifkan di { $settings }.
# the compose window with Sign and Encrypt: the line under the fields, each recipient's key, the questions
pgp-compose-encrypted = { $count ->
    [1] Akan dienkripsi dan ditandatangani untuk Anda dan { $addresses }.
   *[other] Akan dienkripsi dan ditandatangani untuk Anda dan { $count } penerimanya.
}
pgp-compose-encrypt-ready = Pesan akan dienkripsi dan ditandatangani. Tambahkan penerima yang kuncinya Anda miliki.
pgp-compose-missing = { $count ->
    [1] Tidak ada kunci yang dapat digunakan untuk { $addresses }, jadi pesan belum dapat dienkripsi.
   *[other] { $count } penerima tidak memiliki kunci yang dapat digunakan, jadi pesan belum dapat dienkripsi: { $addresses }.
}
pgp-compose-looking = Mencari kunci untuk { $addresses }...
pgp-compose-signed = Akan ditandatangani saat dikirim: penerima dapat memeriksa bahwa konten yang ditandatangani tidak berubah. Mereka juga harus memverifikasi siapa pemilik kunci Anda.
pgp-compose-reply-clear = Tidak dienkripsi, meskipun pesan yang dibalas atau diteruskan terenkripsi.
pgp-compose-encrypted-files = File dari pesan terenkripsi dilampirkan, jadi pesan ini hanya dapat dikirim dalam keadaan terenkripsi. Aktifkan Enkripsi, atau hapus file tersebut.
pgp-compose-sign-tip = Tanda tangani pesan agar penerima dapat memeriksa bahwa isinya tidak berubah. Mereka juga harus memverifikasi siapa pemilik kunci Anda
pgp-compose-sign-tip-encrypted = Pesan terenkripsi selalu ditandatangani
pgp-compose-encrypt-tip = Enkripsi pesan, agar hanya Anda dan penerimanya yang dapat membacanya
pgp-compose-make-key = Anda belum memiliki kunci untuk { $address }. Buat sekarang? Dengan kunci, pesan Anda dapat ditandatangani dan dienkripsi.
pgp-compose-key-unusable = Kunci Anda untuk { $address } tidak dapat digunakan. Alasan: { $state }. Buka Kunci Enkripsi untuk mengimpor cadangannya atau membuat kunci baru.
pgp-compose-encrypt-off-quote = Pesan ini berisi teks, gambar, atau lampiran dari email terenkripsi. Tanpa enkripsi, pesan tidak dapat dikirim sampai Anda menghapus semua konten tersebut. Tetap nonaktifkan enkripsi?
pgp-compose-encrypt-off-reply = Pesan ini membalas atau meneruskan pesan terenkripsi. Tanpa enkripsi, siapa pun yang menangani pesan Anda dalam perjalanan dapat membacanya. Nonaktifkan enkripsi?
pgp-recipient-verified = Pemilik kunci terverifikasi
pgp-recipient-found = Pemilik kunci belum diverifikasi
pgp-recipient-own = Kunci Anda sendiri
pgp-recipient-looking = Mencari kunci...
pgp-recipient-missing = Tidak ada kunci
pgp-recipient-not-found = Tidak ada kunci: tidak ditemukan pada { $date }
pgp-recipient-unusable = Kunci tidak dapat digunakan: { $state }
pgp-recipients-intro = Pesan dienkripsi dengan kunci setiap penerima, dan dengan kunci Anda.
pgp-recipients-intro-missing = { $count ->
    [1] Satu penerima tidak memiliki kunci enkripsi yang dapat digunakan. Cari kuncinya atau hapus penerima tersebut. Pengiriman tanpa enkripsi baru tersedia setelah semua konten dari email terenkripsi dihapus.
   *[other] { $count } penerima tidak memiliki kunci enkripsi yang dapat digunakan. Cari kunci mereka atau hapus penerima tersebut. Pengiriman tanpa enkripsi baru tersedia setelah semua konten dari email terenkripsi dihapus.
}
pgp-details-part = Bagian { $number }: { $label }
attachment-from-part = Dari bagian { $number }: { $label }
pgp-details-signed = Ditandatangani { $when } dengan kunci { $key }
pgp-details-unknown-key = Ditandatangani dengan kunci { $key }, yang tidak Anda miliki
pgp-details-opened = Didekripsi dengan kunci Anda { $key }
pgp-details-for = Dienkripsi dengan kunci { $keys }
pgp-details-plain = Tidak ditandatangani dan tidak dienkripsi
pgp-bar-parts = Pesan ini memiliki { $count } bagian: { $list }. Setiap bagian menyebutkan cara perlindungannya.
pgp-bar-count-verified = { $count } terverifikasi
pgp-bar-count-encrypted-signed = { $count } terenkripsi dan ditandatangani
pgp-bar-count-encrypted = { $count } terenkripsi
pgp-bar-count-signed = { $count } ditandatangani
pgp-bar-count-warning = { $count } perlu diperhatikan
pgp-bar-count-neutral = { $count } tanpa tanda tangan yang terkonfirmasi
# the setup file: settings, accounts, contacts and keys carried to another computer
setup-part-settings = Pengaturan
setup-part-preferences = Preferensi jendela
setup-part-accounts = Akun
setup-part-sign-in-apps = Aplikasi masuk
setup-part-contacts = Kontak dan grup
setup-part-keys = Kunci enkripsi
setup-part-rules = Aturan pesan
setup-part-trusted-senders = Pengirim tepercaya
setup-holds-settings = { $count } pengaturan
setup-holds-preferences = { $count } preferensi
setup-holds-accounts = { $count } akun
setup-holds-sign-in-apps = { $count } aplikasi masuk
setup-holds-built-in = Aplikasi masuk bawaan mana yang diaktifkan
setup-holds-contacts = { $count } kontak
setup-holds-groups = { $count } grup
setup-holds-own-keys = { $count } kunci milik Anda
setup-holds-contact-keys = { $count } kunci kontak
setup-holds-rules = { $count } aturan
setup-holds-trusted-senders = { $count } pengirim tepercaya
setup-sign-in-password = Kata sandi
setup-account-secret-password = Kata sandinya ada di dalam file.
setup-account-secret-token = Kredensial masuk yang tersimpan ada di dalam file.
setup-account-asks-password = Akun ini meminta kata sandinya setelah diimpor.
setup-account-signs-in-again = Anda perlu masuk lagi ke akun ini setelah diimpor.
setup-account-here = Akun ini sudah disiapkan di sini, jadi dilewati.
setup-account-no-app = Akun ini masuk dengan { $app }, yang tidak disiapkan di sini. Impor juga aplikasi masuknya.
setup-invalid-address = “{ $address }” bukan alamat email.
setup-invalid-server = Pengaturan { $server } memiliki nama server, port, atau opsi keamanan yang tidak valid.
setup-invalid-user = Akun ini tidak memiliki nama pengguna.
setup-invalid-sign-in = Metode atau konfigurasi masuknya tidak didukung.
setup-error-empty = File kosong.
setup-error-too-large = File pengaturan melebihi batas ukuran.
setup-error-not-setup = File ini bukan file pengaturan Inbox Classic.
setup-error-damaged = File pengaturan rusak dan tidak dapat dibaca.
setup-error-newer = Pengaturan ini disimpan oleh Inbox Classic yang lebih baru ({ $version }). Perbarui Inbox Classic, lalu impor lagi.
setup-error-needs-passphrase = Pengaturan ini dilindungi dengan frasa sandi. Ketik frasa sandi yang digunakan saat menyimpannya.
setup-error-wrong-passphrase = Itu bukan frasa sandi yang digunakan saat menyimpan pengaturan ini.
setup-error-changed = File pengaturan gagal dalam pemeriksaan integritas. File mungkin telah diubah atau rusak dan tidak dapat diimpor.
setup-error-read = File pengaturan tidak dapat dibaca: { $error }
setup-error-write = Pengaturan tidak dapat disimpan: { $error }
setup-error-no-parts = Pilih setidaknya satu bagian.
setup-left-out = { $count } entri dari { $part } tidak dapat digunakan dan tidak disertakan.
setup-imported-settings = Pengaturan telah diganti.
setup-imported-preferences = Preferensi jendela telah diganti.
setup-added-accounts = { $count } akun ditambahkan.
setup-skipped-here = { $address } sudah disiapkan di sini, jadi dilewati.
setup-skipped-no-app = { $address } dilewati: akun ini masuk dengan { $app }, yang tidak disiapkan di sini.
setup-skipped-invalid = { $address } dilewati: { $reason }
setup-asks-password = { $address } meminta kata sandinya saat terhubung.
setup-signs-in-again = { $address } meminta Anda masuk lagi saat terhubung.
setup-added-sign-in-apps = { $count } aplikasi masuk ditambahkan.
setup-skipped-sign-in-apps = { $count } aplikasi masuk sudah disiapkan di sini.
setup-added-contacts = { $count } kontak ditambahkan ke buku alamat.
setup-skipped-contacts = { $count } kontak sudah ada di buku alamat.
setup-added-groups = { $count } grup ditambahkan atau dilengkapi.
setup-added-own-keys = { $count } kunci milik Anda ditambahkan.
setup-added-contact-keys = { $count } kunci kontak ditambahkan.
setup-added-rules = { $count } aturan pesan ditambahkan.
setup-skipped-rules = { $count } aturan pesan sudah ada di sini.
setup-skipped-rules-account = { $count } aturan pesan memerlukan akun yang tidak ada di sini, jadi dilewati.
setup-rules-waiting = { $count } aturan pesan menunggu folder tujuannya ditemukan selama sinkronisasi akun.
setup-added-trusted-senders = { $count } pengirim tepercaya ditambahkan.
setup-nothing = Tidak ada yang diimpor.
setup-account-servers = { $imap } dan { $smtp } ({ $signin })
setup-file-name = Pengaturan dan akun Inbox Classic
setup-skipped-unreachable = { $name } dilewati: layanan masuknya tidak dapat dijangkau atau diperiksa. Periksa aplikasi yang diperlukan di Aplikasi Masuk sebelum mencoba lagi.
attachment-runs-programs = “{ $name }” dapat menjalankan program, jadi Inbox Classic tidak membukanya. Simpan file ini, lalu buka sendiri jika Anda memercayai asalnya.
attachment-decrypted-note = Lampiran ini berasal dari email terenkripsi. Untuk membukanya di aplikasi lain, Inbox Classic menyimpan salinan yang tidak terenkripsi di folder sementara untuk akun pengguna Anda. Saat dimulai, aplikasi mencoba menghapus salinan yang berusia lebih dari satu hari.
# a bar over the list when the server did not do what the user asked of messages, so they are as they were again
undone-move = { $count ->
   *[other] Server tidak memindahkan { $messages } ke { $folder }, jadi pesan kembali ke { $from }: { $reason }
}
undone-delete = { $count ->
   *[other] Server tidak menghapus { $messages }, jadi pesan kembali ke { $from }: { $reason }
}
undone-archive = { $count ->
   *[other] Server tidak mengarsipkan { $messages }, jadi pesan kembali ke { $from }: { $reason }
}
undone-read = { $count ->
   *[other] Server tidak menandai { $messages } sebagai sudah dibaca, jadi pesan kembali belum dibaca: { $reason }
}
undone-unread = { $count ->
   *[other] Server tidak menandai { $messages } sebagai belum dibaca, jadi pesan kembali sudah dibaca: { $reason }
}
undone-flags = { $count ->
   *[other] Server tidak mengubah bendera { $messages }, jadi pesan kembali seperti semula: { $reason }
}

## Previews of attachments: the pictures and PDF files shown in a message

# the reading option that turns PDF previews on and off (the apps show it)
preview-pdf-option = Tampilkan file PDF di pesan
# the tile of a PDF file while PDF previews are off
preview-pdf-off = File PDF tidak ditampilkan di pesan.
# the note where previews are, after the app ended while it was drawing a file of a message: { $option } is the option's name
preview-pdf-off-crashed = Inbox Classic tertutup saat menampilkan file di sebuah pesan, jadi file PDF tidak lagi ditampilkan di pesan. Gambar tetap ditampilkan. Untuk menampilkan file PDF lagi, aktifkan { $option } di { $settings }.
# under the pages of a PDF file shown in a message: its page count and size ("3 pages, 84 KB")
preview-pdf-details = { $count } halaman, { $size }
# what a screen reader says of a page of a PDF file shown in a message
preview-page-alt = { $name }, halaman { $page } dari { $count }
# the link under the pages of a PDF file shown in a message, when it has more pages than are shown
preview-more-pages = { $count ->
    [1] Buka untuk melihat halamannya
   *[other] Buka untuk melihat semua { $count } halaman
}
# after the files shown in a message, when it has more pictures and PDF files than are shown; the list is the
# strip of files over the message
preview-more-files = { $count } file lainnya ada di daftar di atas
# the tile of a picture or PDF file of a message still downloading (the ellipsis as in reader-downloading)
preview-tile-downloading = Mengunduh…
# the tile of a picture or PDF file whose size was not read in time when the message was shown: its preview
# comes in its place in a moment (the ellipsis as in reader-downloading)
preview-tile-preparing = Menyiapkan…
# the tile of a picture in a format not shown yet: { $format } is its name (HEIC, AVIF, JPEG XL)
preview-tile-format = Gambar { $format } belum dapat ditampilkan
# the tile of a PDF file that wants a password to open
preview-tile-password = Dilindungi kata sandi: buka file untuk memasukkan kata sandi
# the tile of a picture or PDF file over the size or pixel limit
preview-tile-too-large = Terlalu besar untuk ditampilkan
# the tile of a file that is broken, or not what its name says
preview-tile-unreadable = Tidak dapat ditampilkan
# the tile of a file that took too long to draw
preview-tile-timed-out = Pratinjau terlalu lama disiapkan
# the tile of a file that closed the app once while it was drawn: never drawn again
preview-tile-crashed = Pratinjau tidak tersedia: upaya sebelumnya terhenti
# the tile of a file while previews are paused after a file took too long, until the app starts again
preview-tile-off = Tidak ditampilkan sampai Inbox Classic dimulai lagi
# in a printout, for a file shown in the message that is not printed (a PDF file, a tile): { $details } is its size,
# or a PDF file's pages and size
preview-not-printed = { $name } ({ $details }) tidak dicetak. Buka file untuk mencetaknya.

pgp-error-attached-private = Lampiran ini berisi kunci privat. Hanya kunci publik yang dapat diimpor langsung dari email. Untuk memulihkan kunci privat Anda sendiri, simpan lampiran lalu impor file tersebut di Kunci Enkripsi.
pgp-part-find-key = Cari Kunci
