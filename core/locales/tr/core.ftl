# Çekirdeğin söyledikleri, her platformda aynı. { $braces } içindeki yer tutucuları kod doldurur; dilin istediği yerde
# kalsınlar. Çoğullar sayıya göre seçilir: İngilizcede [one] ve *[other], sizin dilinizde dilinizin biçimleri.

## Sayılar ve boyutlar

# review: new
messages = { $count ->
    [one] 1 ileti
   *[other] { $count } ileti
}
# boyutlardaki ondalık ayırıcı: 2,4 MB
# review: new
decimal-separator = ,
# review: new
size-bytes = { $count ->
    [one] 1 bayt
   *[other] { $count } bayt
}
# review: new
size-kb = { $size } KB
# review: new
size-mb = { $size } MB
# review: new
size-gb = { $size } GB
# review: new
send-delay-off = Kapalı
# review: new
send-delay-seconds = { $count ->
    [one] 1 saniye
   *[other] { $count } saniye
}
# durum çubuğu: "12 ileti, 3 okunmamış"
# review: new
list-counts = { $messages }, { $unread } okunmamış
# review: new
list-counts-selected = { $messages }, { $unread } okunmamış, { $selected } seçili
# arama sırasında durum çubuğu: "12 bulundu, 3 okunmamış"
# review: new
list-counts-found = { $found } bulundu, { $unread } okunmamış
# review: new
list-counts-found-selected = { $found } bulundu, { $unread } okunmamış, { $selected } seçili
# review: new
list-counts-none = İleti bulunamadı

## Özel klasörler, Outlook Express'in adlandırdığı gibi

# review: new
folder-inbox = Gelen Kutusu
# review: new
folder-sent = Gönderilmiş Öğeler
# review: new
folder-deleted = Silinmiş Öğeler
# review: new
folder-drafts = Taslaklar
# review: new
folder-junk = Gereksiz E-posta
# review: new
folder-archive = Arşiv

## Okuma bölmesi

# review: new
reader-no-message = Seçili ileti yok.
# review: new
reader-downloading = İleti indiriliyor…
# review: new
reader-downloading-detail = İndirme tamamlanınca ileti burada görünecek.
# review: new
reader-downloading-size = İletinin boyutu: { $size }. İndirildiğinde burada görünecek.
# review: new
reader-failed = İleti indirilemedi
# review: new
reader-failed-network = Posta sunucusuna ulaşılamadı ({ $reason }).
# review: new
reader-failed-sign-in = Posta sunucusu oturum açmayı kabul etmedi ({ $reason }). Parolayı denetleyin veya Dosya > Hesaplar'da yeniden oturum açın.
# review: new
reader-failed-security = Posta sunucusuyla güvenli bağlantı kurulamadı ({ $reason }).
# review: new
reader-failed-other = Posta sunucusunun yanıtı: { $reason }.
# review: new
reader-retry-note = Hesap yeniden bağlandığında tekrar denenecek.
# review: new
reader-unreadable = Bu ileti gösterilemiyor: { $error }
# review: new
message-source-title = İleti Kaynağı: { $subject }
# review: new
message-source-untitled = İleti Kaynağı

## Bir iletiyi yazdırma ve yanıtta ya da iletmede alıntılanan iletinin üst bilgisi

# review: new
header-from = Kimden
# review: new
header-date = Tarih
# review: new
header-to = Kime
# review: new
header-cc = Bilgi
# review: new
header-sent = Gönderildi
# review: new
header-subject = Konu
# review: new
header-security = Güvenlik
# review: new
header-part = Bölüm { $number }
# review: new
quote-original = ----- Özgün İleti -----
# review: new
fold-show-earlier = Önceki iletileri göster

## Geri dönen iletiler: bir iletinin teslim edilmediğini bildiren notun üstündeki kart

# review: new
bounce-failed = İletiniz teslim edilmedi
# review: new
bounce-delayed = İletiniz henüz teslim edilmedi
# review: new
bounce-delayed-note = Posta sunucunuz iletiyi teslim etmeye hâlâ çalışıyor. Yeniden göndermeniz gerekmez.
# notun ilgili olduğu iletinin bağlantısı, Gönderilmiş Öğeler'de veya başka bir klasörde
# review: new
bounce-show-message = Geri dönen iletiyi göster
# gecikme kartında hâlâ yolda olan iletinin bağlantısı
# review: new
bounce-show-delayed = Geciken iletiyi göster
# review: new
bounce-what-to-do = Yapabilecekleriniz:
# iletinin hâlâ yolda olduğu bir alıcı için yapılacaklar: gecikme kartında ve başarısızlık kartında
# review: new
bounce-delayed-do = Şimdilik bir şey yapmanız gerekmez. Yine teslim edilemezse başka bir bildirim alırsınız.
# review: new
bounce-delayed-row-do = Şimdilik bir şey yapmanız gerekmez. Posta sunucunuz teslim etmeye hâlâ çalışıyor, edemezse başka bir bildirim alırsınız.
# alan sunucunun kendi sözlerini katlar
# review: new
bounce-details = Ayrıntılar
# bildirimin adını vermediği bir alıcı
# review: new
bounce-someone = Bir alıcı
# Ayrıntılar'da: iletiyi reddeden sunucu, verdiği durum kodu ve bildirimi yazan sunucu
# review: new
bounce-server = Sunucu: { $server }
# review: new
bounce-status = Durum: { $status }
# review: new
bounce-reported-by = Bildiren: { $server }
# review: new
bounce-retry-minutes = Alan sunucu bir sonraki denemeden önce { $count ->
    [one] bir dakika
   *[other] { $count } dakika
} beklenmesini istedi.
# review: new
bounce-retry-hours = Alan sunucu bir sonraki denemeden önce { $count ->
    [one] bir saat
   *[other] { $count } saat
} beklenmesini istedi.
# engelleme listelerinin adları, "Spamhaus ZEN, Barracuda"
# review: new
bounce-blocklist = Engelleme listesi: { $lists }
# review: new
bounce-user-unknown = Adres yok
# review: new
bounce-user-unknown-why = Alan sunucuda bu adrese ait bir posta kutusu yok. Adres yanlış yazılmış olabilir veya kişi artık bu adresi kullanmıyor olabilir.
# review: new
bounce-user-unknown-do = Adresin yazımını denetleyin veya kişiye şimdi kullandığı adresi sorun.
# review: new
bounce-invalid-address = Adres geçerli değil
# review: new
bounce-invalid-address-why = Adres, posta gönderilebilecek bir biçimde yazılmamış.
# review: new
bounce-invalid-address-do = Boşluk, eksik harf veya @ işaretinden sonra hiçbir şey olmaması gibi yazım hatalarına bakın.
# review: new
bounce-mailbox-disabled = Posta kutusu kapalı
# review: new
bounce-mailbox-disabled-why = Adres var, ancak posta kutusu kapatılmış veya artık kullanılmıyor.
# review: new
bounce-mailbox-disabled-do = Kişiye başka bir yoldan ulaşın ve şimdi kullandığı adresi sorun.
# review: new
bounce-mailbox-full = Posta kutusu dolu
# review: new
bounce-mailbox-full-why = Alıcının posta kutusunda yeni posta için yer yok.
# review: new
bounce-mailbox-full-do = Birkaç gün sonra yeniden gönderin veya kişiye başka bir yoldan haber verin. Önce büyük ekler reddedilir.
# review: new
bounce-spam-blocked = İstenmeyen posta olarak reddedildi
# review: new
bounce-spam-blocked-why = Alan sunucu iletiyi istenmeyen posta sandı.
# review: new
bounce-spam-blocked-do = Çok sayıda bağlantı, kısaltılmış bağlantılar veya büyük bir ek gibi istenmeyen postaya benzeyen şeyler olmadan yeniden gönderin. Sürerse posta sağlayıcınıza sorun.
# review: new
bounce-virus-detected = Virüs nedeniyle reddedildi
# review: new
bounce-virus-detected-why = Alan sunucu iletide veya eklerinde virüs ya da başka zararlı içerik buldu.
# review: new
bounce-virus-detected-do = Ekleri bir virüs tarayıcısıyla denetleyin. Bazı sunucular her programı veya arşivi reddeder, bu yüzden bu tür dosyaları bağlantı olarak paylaşın.
# review: new
bounce-ip-blocklisted = Posta sunucunuz bir engelleme listesinde
# review: new
bounce-ip-blocklisted-why = Alan sunucu, iletinizi gönderen sunucudan gelen postayı reddediyor, çünkü o sunucunun adresi bir engelleme listesinde.
# review: new
bounce-ip-blocklisted-do = Sorun iletide değil. Bu bildirimi posta sağlayıcınıza iletin ve sunucuyu listeden çıkartmasını isteyin.
# review: new
bounce-domain-blocklisted = Bir etki alanı engelleme listesinde
# review: new
bounce-domain-blocklisted-why = Alan sunucu iletiyi reddediyor, çünkü adresinizin etki alanı veya iletideki bağlantılardan birinin etki alanı bir engelleme listesinde.
# review: new
bounce-domain-blocklisted-do = İletide bağlantılar varsa onlarsız deneyin. Yoksa bu bildirimi etki alanınızın postasını yöneten kişiye iletin.
# review: new
bounce-policy-blocked = Alan sunucunun kuralları nedeniyle reddedildi
# review: new
bounce-policy-blocked-why = Alan sunucunun kuralları, örneğin boyutu, ekleri veya göndereni nedeniyle bu iletiyi geçirmiyor.
# review: new
bounce-policy-blocked-do = Ayrıntılar altındaki sunucunun kendi sözleri çoğu zaman nedeni söyler. Alıcıya bu tür postaları kabul edip edemeyeceğini sorun.
# review: new
bounce-geo-blocked = Geldiği yer nedeniyle reddedildi
# review: new
bounce-geo-blocked-why = Alan sunucu, posta sunucunuzun bulunduğu ülkeden veya ağdan posta almıyor.
# review: new
bounce-geo-blocked-do = Kişiye başka bir yoldan ulaşın veya posta sağlayıcınıza sorun.
# review: new
bounce-relay-denied = Sunucu iletiyi aktarmadı
# review: new
bounce-relay-denied-why = Bir sunucu iletiyi ileriye teslim etmeyi reddetti; genellikle ileti oturum açılmadan veya bu alıcıyla ilgilenmeyen bir sunucu üzerinden gönderildiği için.
# review: new
bounce-relay-denied-do = Dosya > Hesaplar'da hesabın giden posta sunucusunu ve oturum açtığını denetleyin.
# review: new
bounce-auth-failure = Gönderen adresiniz doğrulanamadı
# review: new
bounce-auth-failure-why = Alan sunucu, iletinin gerçekten etki alanınızdan geldiğini doğrulayamadı (SPF, DKIM veya DMARC).
# review: new
bounce-auth-failure-do = Bu bildirimi etki alanınızın postasını yöneten kişiye iletin: ayarlarının düzeltilmesi gerekiyor. Bu arada sağlayıcınızın kendi sunucusu üzerinden göndermek işe yarayabilir.
# review: new
bounce-rate-limited = Aynı anda çok fazla posta
# review: new
bounce-rate-limited-why = Alan sunucu şimdilik posta sunucunuzdan daha az ileti kabul ediyor.
# review: new
bounce-rate-limited-do = Bir süre bekleyip yeniden gönderin. Çok kişiye yazarken her seferinde daha az kişiye gönderin.
# review: new
bounce-greylisting = Kısa bir süre bekletildi
# review: new
bounce-greylisting-why = Alan sunucu, tanımadığı gönderenlerden biraz sonra yeniden denemelerini istiyor; bu, istenmeyen postaya karşı yaygın bir denetimdir.
# review: new
bounce-greylisting-do = Bir şey yapmanız gerekmez. Posta sunucuları kendiliğinden yeniden dener ve ileti genellikle bir saat içinde teslim edilir.
# review: new
bounce-server-error = Alan sunucuda bir sorun oluştu
# review: new
bounce-server-error-why = Alan sunucuya ulaşılamadı veya sunucu kendi sorunu nedeniyle iletiyi alamadı.
# review: new
bounce-server-error-do = Daha sonra yeniden gönderin. Başarısız olmaya devam ederse adresin @ işaretinden sonraki kısmında yazım hatası olup olmadığına bakın.
# review: new
bounce-unknown = Teslim edilmedi
# review: new
bounce-unknown-why = Bildirim nedenini açıkça söylemiyor.
# review: new
bounce-unknown-do = Ayrıntılar altındaki sunucunun kendi sözleri daha fazlasını söyleyebilir. İşe yaramazlarsa bu bildirimi posta sağlayıcınıza iletin.

## Birden çok ileti seçili

# review: new
selection-title = { $count ->
    [one] 1 ileti seçili
   *[other] { $count } ileti seçili
}
# review: new
selection-unread = { $count } okunmamış
# review: new
selection-flagged = { $count } bayraklı
# review: new
delete-for-good-one = Bu ileti kalıcı olarak silinecek. Silinsin mi?
# review: new
delete-for-good-all = Bu { $count } ileti kalıcı olarak silinecek. Silinsinler mi?
# review: new
delete-for-good-some = { $total } iletiden { $count } tanesi kalıcı olarak silinecek. İletiler silinsin mi?
# review: new
done-read = { $count ->
   *[other] Okundu olarak işaretlendi: { $messages }
}
# review: new
done-unread = { $count ->
   *[other] Okunmadı olarak işaretlendi: { $messages }
}
# review: new
done-flagged = { $count ->
   *[other] Bayrak kondu: { $messages }
}
# review: new
done-unflagged = Bayrak kaldırıldı: { $messages }
# review: new
done-deleted-for-good = { $count ->
   *[other] Kalıcı olarak silindi: { $messages }
}
# review: new
done-archived = { $count ->
   *[other] Arşivlendi: { $messages }
}
# review: new
done-moved = { $count ->
   *[other] Taşındı: { $messages }. Hedef: { $folder }
}
# review: new
done-copied = { $count ->
   *[other] Kopyalandı: { $messages }. Hedef: { $folder }
}
# review: new
done-moving = { $count ->
   *[other] Taşınıyor: { $messages }. Hedef: { $folder }...
}
# review: new
done-copying = { $count ->
   *[other] Kopyalanıyor: { $messages }. Hedef: { $folder }...
}
# review: new
done-moved-back = { $count ->
   *[other] Geri taşındı: { $messages }. Hedef: { $folder }
}
# Konuşmayı İzle ve Konuşmayı Yoksay'dan sonra, ve işaretli bir konuşmada ikisinden biri yeniden seçildikten sonra durum çubuğu
# review: new
done-watched = { $count ->
    [one] Konuşma izleniyor
   *[other] { $count } konuşma izleniyor
}
# review: new
done-unwatched = { $count ->
    [one] Konuşma artık izlenmiyor
   *[other] { $count } konuşma artık izlenmiyor
}
# review: new
done-ignored = { $count ->
    [one] Konuşma yoksayılıyor
   *[other] { $count } konuşma yoksayılıyor
}
# review: new
done-unignored = { $count ->
    [one] Konuşma artık yoksayılmıyor
   *[other] { $count } konuşma artık yoksayılmıyor
}
# review: new
their-folders = kendi klasörleri
# review: new
undo-move = Taşımayı Geri Al
# review: new
undo-delete = Silmeyi Geri Al
# review: new
undo-archive = Arşivlemeyi Geri Al
# review: new
undo-junk = Gereksiz Olarak İşaretlemeyi Geri Al
# review: new
undo-not-junk = Gereksiz Değil Olarak İşaretlemeyi Geri Al
# review: new
undo-send = Göndermeyi Geri Al
# review: new
nothing-to-undo = Geri alınacak bir şey yok.
# review: new
messages-gone = İletiler artık orada değil.
# Seçilemeyen bir IMAP klasörü ileti içeremez; bu, klasörün boş olduğu anlamına gelmez.
# review: new
folder-holds-no-messages = Bu klasör ileti içeremez.
# review: new
not-archived-here = Bu klasördeki iletiler arşivlenemez.
# review: new
not-emptied-here = Yalnızca Silinmiş Öğeler ve Gereksiz E-posta boşaltılabilir.
# review: new
next-unread-question = { $folder } klasöründe başka okunmamış ileti yok.

    Okunmamış iletileri olan bir sonraki klasöre, { $next } klasörüne gidilsin mi?
# review: new
no-unread-left = Okunmamış ileti kalmadı.
# review: new
empty-question = { $count ->
    [one] { $folder } boşaltılsın mı?

        İçindeki ileti kalıcı olarak silinir. Geri getirilemez.
   *[other] { $folder } boşaltılsın mı?

        İçindekiler kalıcı olarak silinir ({ $messages }). Geri getirilemezler.
}
# review: new
no-junk-folder = Bu hesapta iletilerin taşınacağı bir Gereksiz E-posta klasörü yok.
# review: new
no-inbox-folder = Bu hesapta iletilerin taşınacağı bir Gelen Kutusu klasörü yok.
# renkli bir bayraktan sonra durum çubuğu: "2 iletiye mavi bayrak kondu"
# review: new
done-flagged-color = Bayrak kondu: { $messages }, { $color ->
    [red] kırmızı
    [orange] turuncu
    [yellow] sarı
    [green] yeşil
    [blue] mavi
    [purple] mor
   *[gray] gri
}
# Bayrak menüsü: Apple Mail'in bayraklarının renkleri
# review: new
flag-color = { $color ->
    [red] Kırmızı
    [orange] Turuncu
    [yellow] Sarı
    [green] Yeşil
    [blue] Mavi
    [purple] Mor
   *[gray] Gri
}

## Taşı ve Kopyala penceresi

# review: new
move-window-title-move = { $count ->
    [one] İletiyi Taşı
   *[other] { $count } İletiyi Taşı
}
# review: new
move-window-title-copy = { $count ->
    [one] İletiyi Kopyala
   *[other] { $count } İletiyi Kopyala
}
# review: new
move-window-prompt-move = { $count ->
    [one] Seçili iletinin taşınacağı yer:
   *[other] Seçili { $count } iletinin taşınacağı yer:
}
# review: new
move-window-prompt-copy = { $count ->
    [one] Seçili iletinin kopyalanacağı yer:
   *[other] Seçili { $count } iletinin kopyalanacağı yer:
}
# klasör ağacının üstünde, en son kullanılan klasörler
# review: new
targets-recent = Son Kullanılanlar
# iletilerin bulunduğu, seçilemeyen klasör
# review: new
target-current = { $folder } (geçerli)
# en son kullanılan bir klasör, birden çok hesap varsa hesabıyla: "Arşiv (İş)"
# review: new
target-recent = { $folder } ({ $account })

## Başka bir hesaba taşıma ve kopyalama

# review: new
transfer-moving = Taşınıyor: { $done } / { $messages }. Hedef: { $folder }...
# review: new
transfer-copying = Kopyalanıyor: { $done } / { $messages }. Hedef: { $folder }...
# review: new
transfer-another-account = başka bir hesap
# review: new
transfer-folder-gone = gideceği klasör artık yok
# review: new
transfer-not-on-server = ileti artık sunucuda değil
# review: new
transfer-not-moved = { $count ->
   *[other] Başka bir hesaba taşınamadı: { $messages }. Neden: { $reason }
}
# review: new
transfer-not-copied = { $count ->
   *[other] Başka bir hesaba kopyalanamadı: { $messages }. Neden: { $reason }
}
# review: new
transfer-none-moved = Hiçbir ileti taşınamadı
# review: new
transfer-none-copied = Hiçbir ileti kopyalanamadı

## Dosya olarak iletiler

# review: new
export-not-in-time = ileti zamanında indirilemedi
# review: new
export-not-saved = Kaydedilemedi: { $failed } / { $messages } ({ $problems })
# review: new
export-not-attached = iletiler eklenemedi: { $error }
# birden çok iletiyle Farklı Kaydet'ten sonra durum çubuğu: "Kaydedildi: 3 ileti. Hedef: Masaüstü"
# review: new
saved-to = { $count ->
   *[other] Kaydedildi: { $messages }. Hedef: { $folder }
}
# review: new
download-progress = İndiriliyor: { $done } / { $total }
# review: new
download-done = İndirildi: { $size }
# review: new
downloading-messages = { $count ->
   *[other] İndiriliyor: { $messages }...
}
# dosyalar bir klasöre bırakıldıktan sonra durum çubuğu: "Eklendi: 3 ileti. Hedef: Arşiv"
# review: new
import-put = { $count ->
   *[other] Eklendi: { $messages }. Hedef: { $folder }
}
# review: new
import-not-put = Şunlar klasöre eklenmedi:

    { $problems }

## Pencerelerin gösterdiği sorunlar

# review: new
error-store = yerel depo: { $error }
# review: new
error-not-found = bulunamadı
# review: new
error-closed = kapatılıyor
# review: new
error-other-account = tarayıcı bu hesapta değil, şu hesapta oturum açtı: { $email }
# posta sunucusunun reddettiği bir parola veya oturum açma, sunucunun sözleriyle
# review: new
failure-authentication = sunucu oturum açmayı kabul etmedi ({ $reason })
# posta sunucusuna ulaşılamadı veya bağlantı koptu, nedeniyle
# review: new
failure-network = sunucuyla bağlantı başarısız oldu ({ $reason })
# review: new
error-in-use = bu uygulamayla oturum açan hesaplar varken kaldırılamaz: { $accounts }
# review: new
error-turned-off = bu oturum açma uygulaması yeni hesaplar için kapalı
# review: new
error-folder-name = klasör adı 1 ile 200 karakter arasında olmalı ve denetim karakterleri içeremez
# review: new
error-folder-separator = bu sunucuda klasör adında “{ $separator }” olamaz
# review: new
error-folder-special = Gelen Kutusu ve özel klasörler yeniden adlandırılamaz veya silinemez
# review: new
error-no-recipients = iletinin alıcısı yok
# review: new
error-bad-address = “{ $address }” bir e-posta adresi değil
# review: new
error-not-own-address = { $address } bu hesabın gönderen adreslerinden biri değil. Hesabın özelliklerinde “Gönderdiğiniz diğer adresler” alanına ekleyin.
# review: new
rule-query-refused = Kurallar klasöre veya tarihe göre süzemez ({ $words }).
# review: new
rule-no-query = Gelen iletiler için arama ölçütleri girin.
# review: new
rule-no-action = Kural için en az bir eylem seçin.
# review: new
error-attachment = { $path } okunamadı: { $error }
# review: new
error-no-drafts = hesapta iletinin kaydedileceği bir Taslaklar klasörü yok
# review: new
error-draft-attachment = taslağın bir eki korunamadı: { $error }
# review: new
error-password-not-saved = parola bir sonraki başlatma için kaydedilemedi: { $error }
# review: new
error-sign-in-not-saved = yeni oturum açma bilgileri bir sonraki başlatma için kaydedilemedi: { $error }
# review: new
error-import-unreadable = { $path } okunamıyor: { $error }
# review: new
error-import-too-large = { $path } 50 MB'tan büyük
# review: new
error-import-not-mail = { $path } bir e-posta iletisi değil
# review: new
error-list-answered = posta listesi sunucusu şu durumu döndürdü: { $status }
# review: new
error-not-built = ileti oluşturulamadı
# review: new
error-outbox-waits = { $count ->
    [one] ileti Giden Kutusu'nda bekliyor ve bir sonraki Gönder/Al ile gönderilecek
   *[other] { $count } ileti Giden Kutusu'nda bekliyor ve bir sonraki Gönder/Al ile gönderilecek
}
# review: new
error-draft-not-removed = iletinin önceki taslağı Taslaklar'dan kaldırılamadı: { $reason }
# review: new
error-sent-but = ileti gönderildi, ancak { $problem }
# review: new
error-sent-still-in-outbox = hâlâ Giden Kutusu'nda: { $error }
# review: new
error-sent-no-copy = Gönderilmiş Öğeler'e kopya kaydedilemedi: { $reason }
# review: new
error-no-password = bu hesabın parolası yok
# review: new
error-no-sign-in = bu hesap için oturum açma bilgisi yok
# review: new
error-provider-missing = bu sürüm şu sağlayıcıda oturum açamıyor: { $provider }. Oturum açma uygulaması kaldırıldı mı?
# review: new
error-provider-servers = bu hesabın sunucuları, oturum açma uygulamasının sunucularıyla eşleşmiyor
# review: new
error-app-scopes = { $reason }. Posta sunucusu oturum açma uygulamasının belirtecini kabul etmedi: uygulamanın izinlerinin (scopes) postaya erişim verdiğini denetleyin
# review: new
error-in-folder = { $folder }: { $reason }

## Oturum açma uygulamaları

# review: new
sign-in-off-google = Google, Inbox Classic'i henüz doğrulamadı, bu yüzden yalnızca test kullanıcılarının onunla oturum açmasına izin veriyor. Kendi Google oturum açma uygulamanızı veya bir uygulama parolası kullanın ya da test kullanıcısıysanız Oturum Açma Uygulamaları'nda (Dosya > Hesaplar) açın.
# review: new
sign-in-off-other = Oturum Açma Uygulamaları'nda (Dosya > Hesaplar) kapatıldı; orada yeniden açılabilir.
# review: new
sign-in-app-no-name = oturum açma uygulamasının bir adı olmalı
# review: new
sign-in-app-no-client = istemci kimliği eksik
# review: new
sign-in-app-no-scopes = oturum açma uygulaması postaya erişim veren izinleri (scopes) gerektirir
# review: new
sign-in-app-bad-host = { $server } sunucu adresi eksik veya geçerli bir ana bilgisayar adı değil
# review: new
sign-in-app-plain = { $server } sunucusu SSL/TLS veya STARTTLS kullanmalı
# review: new
sign-in-app-not-checked = yayımcı henüz denetlenmedi
# review: new
sign-in-app-issuer-changed = yayımcı değişti: istemci gizli dizisini yeniden yazın veya kaldırın
# review: new
sign-in-register-google = Google Cloud Console'da, onay ekranında https://mail.google.com/ izni olan, Masaüstü uygulaması türünde bir OAuth istemcisi oluşturun. Uygulama test aşamasındayken yalnızca test kullanıcıları oturum açabilir.
# review: new
sign-in-register-microsoft = Microsoft Entra'da Mobil ve masaüstü uygulamaları platformuyla, http://localhost yeniden yönlendirme URI'siyle, genel istemci akışlarına izin vererek ve IMAP.AccessAsUser.All, SMTP.Send ve offline_access temsilci izinleriyle bir uygulama kaydedin. Yalnızca kuruluşunuz için yayımcı olarak https://login.microsoftonline.com/<kiracı kimliği>/v2.0 kullanın.
# review: new
sign-in-register-other = Aşağıdaki yeniden yönlendirme URI'siyle yerel (genel) bir istemci kaydedin; sağlayıcı bu URI'de herhangi bir bağlantı noktasına izin vermeli (RFC 8252). Sağlayıcının postaya erişim verdiği izni (scope) ekleyin.

## Takvim davetleri

# review: new
repeats = Yineleme
# review: new
repeats-every = { $unit ->
    [day] { $interval ->
        [one] Her gün
       *[other] { $interval } günde bir
    }
    [week] { $interval ->
        [one] Her hafta
       *[other] { $interval } haftada bir
    }
    [month] { $interval ->
        [one] Her ay
       *[other] { $interval } ayda bir
    }
   *[year] { $interval ->
        [one] Her yıl
       *[other] { $interval } yılda bir
    }
}
# "Her hafta, günler: Pazartesi, Çarşamba"
# review: new
repeats-on = { $repeats }, günler: { $days }
# "Her hafta, 10 kez"
# review: new
repeats-times = { $count ->
    [one] { $repeats }, bir kez
   *[other] { $repeats }, { $count } kez
}
# review: new
day-monday = Pazartesi
# review: new
day-tuesday = Salı
# review: new
day-wednesday = Çarşamba
# review: new
day-thursday = Perşembe
# review: new
day-friday = Cuma
# review: new
day-saturday = Cumartesi
# review: new
day-sunday = Pazar

## Yapay zeka aracıları

# review: new
agent-level-read = Postayı okuma: klasörler, ileti listesi, arama ve iletiler
# review: new
agent-level-organize = Postayı düzenleme: okundu durumu, bayraklar, gereksiz posta, taşıma, Silinmiş Öğeler'e silme
# review: new
agent-level-drafts = Göndermeniz için taslak yazma
# review: new
agent-level-send = Posta gönderme, her iletiyi ancak siz onayladıktan sonra
# review: new
agent-connect-title = { $program } postanızı kullanmak istiyor
# review: new
agent-connect-detail = Bir yapay zeka aracısı Inbox Classic ile çalışmak istedi. Neler yapabileceğini ve hangi hesapları görebileceğini seçin; bunu daha sonra Araçlar > Yapay Zeka Aracıları'nda değiştirebilirsiniz.

    Aracılar başkalarının yazdığı postaları okur ve bir ileti onları kandırmaya çalışabilir. Inbox Classic, bir aracı herhangi bir şey göndermeden önce her zaman size sorar.
# review: new
agent-reply-to = Yanıt: “{ $subject }”
# review: new
agent-reply-all-on = Tümüne yanıt: “{ $subject }”
# review: new
agent-forward-of = İletme: “{ $subject }”
# review: new
agent-never-written-one = Bu adrese hiç yazmadınız: { $address }
# review: new
agent-never-written-many = Bu adreslerden { $count } tanesine hiç yazmadınız.
# review: new
agent-send-title = { $program } bu iletiyi göndermek istiyor
# review: new
agent-send-detail = Alıcıları ve iletinin içeriğini denetleyin. Onayladığınızda ileti Giden Kutusu'nda { $seconds } saniye bekler; bu sürede onu hâlâ silebilirsiniz.
# review: new
agent-change-title = { $program } neler yapabilir
# review: new
agent-change-allowed = Bu programın yapay zeka aracılarının postanızla neler yapabileceğini değiştirin.
# review: new
agent-change-refused = Bu programın erişimini reddettiniz. Aracılarının postanıza yeniden erişebilmesi için izin verin.
# review: new
agent-log-taken-back = { $entry } (geri alındı)
# review: new
agent-files = Dosyalar: { $files }
# review: new
agent-undo-refused = Geri alınamaz.
# review: new
agent-undo-refused-why = Geri alınamaz: { $reason }.
# review: new
agent-undo-impossible = bu geri alınamaz
# review: new
agent-undo-not-in-folder = ileti artık o klasörde değil
# review: new
agent-undo-not-arrived = ileti gittiği klasörde (henüz) yok
# review: new
agent-undo-sent = ileti zaten gönderildi
# review: new
agent-original-not-downloaded = özgün ileti henüz indirilmedi. Önce onu açın
# review: new
agent-turned-away = Geri çevrildi
# review: new
agent-can-nothing = Hiçbir şey
# review: new
agent-can-read = okuma
# review: new
agent-can-organize = düzenleme
# review: new
agent-can-drafts = taslak yazma
# review: new
agent-can-send = onayınızla gönderme
# "Okuma, düzenleme ve taslak yazma"
# review: new
agent-can-list = { $first } ve { $last }
# review: new
agent-accounts = { $count ->
    [0] hesap yok
    [one] 1 hesap
   *[other] { $count } hesap
}
# "Okuma ve düzenleme; 1 hesap"
# review: new
agent-access = { $can }; { $accounts }
# review: new
agent-unreadable = Bu ileti okunamıyor.
# review: new
agent-encrypted-original = Bu ileti şifreli: aracı şifreleme yapamadığı için ona yanıt veremez veya onu iletemez.
# review: new
agent-log-composed = “{ $subject }” bitirmeniz için yeni bir iletide açıldı
# review: new
agent-log-refused = “{ $subject }” iletisini göndermediniz
# review: new
agent-log-sent = “{ $subject }” gönderildi. Alıcı: { $to }
# review: new
agent-log-draft = Taslak kaydedildi: “{ $subject }”
# review: new
agent-log-read = Okundu olarak işaretlendi: “{ $subject }”
# review: new
agent-log-unread = Okunmadı olarak işaretlendi: “{ $subject }”
# review: new
agent-log-flagged = Bayrak kondu: “{ $subject }”
# review: new
agent-log-unflagged = Bayrak kaldırıldı: “{ $subject }”
# review: new
agent-log-deleted = Silindi: “{ $subject }”
# review: new
agent-log-moved = Taşındı: “{ $subject }”. Hedef: { $folder }
# review: new
agent-log-junk = Gereksiz olarak işaretlendi: “{ $subject }”
# review: new
agent-log-not-junk = Gereksiz değil olarak işaretlendi: “{ $subject }”
# review: new
agent-log-archived = Arşivlendi: “{ $subject }”
# review: new
agent-log-folder = Klasör oluşturuldu: “{ $name }”
# review: new
agent-log-unsubscribed = “{ $subject }” iletisinin listesinden abonelik iptal edildi

## Dilin klavyelerinde adlandırıldığı biçimiyle tuşlar, yardımda (Windows ve Linux)

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

## Oturum açma ve parolalar

# review: new
sign-in-no-refresh = sağlayıcı yenileme belirteci vermedi
# review: new
sign-in-no-account = sağlayıcı hangi hesabın oturum açtığını söylemedi
# review: new
sign-in-not-finished = oturum açma tamamlanmadı
# review: new
secrets-unavailable = Kullanılamıyor: { $store }
# review: new
secrets-unavailable-why = Kullanılamıyor: { $store } ({ $error })
# review: new
secrets-windows = Kimlik Bilgileri Yöneticisi
# review: new
secrets-mac = anahtar zinciri
# review: new
secrets-linux = sistem anahtarlığı (Secret Service)
# review: new
error-no-such-file = böyle bir dosya yok
# review: new
cards-file-too-big = Bu dosya bir adres defteri olamayacak kadar büyük.
# review: new
ui-sender-added = { $name } Adres Defteri'ne eklendi.
# review: new
ui-sender-known = { $name } zaten Adres Defteri'nde.
# review: new
ui-sender-none = Bu iletinin gönderenine ait eklenecek bir e-posta adresi yok.
# review: new
card-name-needed = Kişinin adı ve e-posta adresi yok.
# Adres Defterini İçe Aktar'ın okunamayan bir dosyası: "kisiler.vcf: böyle bir dosya yok"
# review: new
cards-file-failed = { $file }: { $reason }

## Tek kullanımlık kodlar: oturum açma veya doğrulama kodu olan bir iletinin üstündeki kart

# kodun ait olduğu, iletiyi imzalayan etki alanı
# review: new
otp-heading = { $domain } kodu
# review: new
otp-copy = Kopyala
# review: new
otp-note = Bu kodu yalnızca şu etki alanının bir sayfasına girin: { $domain }
# review: new
otp-old = Bu kod, siz açmadan bir saatten uzun süre önce gönderildi ve büyük olasılıkla süresi doldu.

# bir etkinliğin kartında kaç kişinin davet edildiği
# review: new
event-attendees =
    { $count ->
        [one] { $count } katılımcı
       *[other] { $count } katılımcı
    }

# kod içeren yeni bir iletinin bildiriminin ilk satırı, iletiyi imzalayan etki alanı için
# review: new
otp-notification = { $domain } için kodunuz: { $code }

## OpenPGP anahtarları (keys.rs)
# review: new
pgp-key-valid = Geçerli
# review: new
pgp-key-expires = Geçerlilik sonu: { $date }
# review: new
pgp-key-expired = Süresi doldu: { $date }
# review: new
pgp-key-revoked = İptal edildi
# review: new
pgp-key-revoked-why = İptal edildi: { $reason }
# review: new
pgp-key-not-valid = Geçerli değil
# review: new
pgp-key-locked = Kullanılamaz: onu koruyan anahtar artık şurada değil: { $store }. Yedeğini yeniden içe aktarın.
# review: new
pgp-source-own = Inbox Classic'te oluşturuldu
# review: new
pgp-source-file = Bir dosyadan içe aktarıldı
# review: new
pgp-source-paste = Yapıştırıldı
# review: new
pgp-source-attachment = Bir iletiden
# review: new
pgp-source-vcard = Bir kişi kartından
# review: new
pgp-source-wkd = Gönderenin posta sağlayıcısından
# review: new
pgp-source-keyserver = keys.openpgp.org'dan
# review: new
pgp-source-autocrypt = Bir iletinin Autocrypt üst bilgisinden
# review: new
pgp-error-no-store = Gizli anahtarlar şunun korumasında tutulur, ancak kullanılamıyor: { $store } ({ $error })
# review: new
pgp-error-wrong-passphrase = Anahtar parolası doğru değil.
# review: new
pgp-error-not-a-key = Bu bir OpenPGP anahtarı değil.
# review: new
pgp-error-too-large = Anahtar çok büyük.
# review: new
pgp-error-unusable = Anahtar eski veya zayıf şifreleme kullanıyor ve kullanılamaz.
# review: new
pgp-imported-private = { $count ->
    [one] Gizli anahtarınız içe aktarıldı.
   *[other] { $count } gizli anahtar içe aktarıldı.
}
# review: new
pgp-imported-public = { $count ->
    [one] Bir anahtar içe aktarıldı.
   *[other] { $count } anahtar içe aktarıldı.
}
# review: new
pgp-imported-pending = Şu adresler için zaten başka bir anahtar kullanılıyor: { $addresses }. Yeni anahtar, siz seçene kadar kişide bekler.
# review: new
pgp-error-needs-passphrase = Gizli anahtar bir anahtar parolasıyla korunuyor. Anahtarı içe aktarmak için parolayı yazın.
# review: new
pgp-error-mismatch = Gizli anahtar, ortak anahtarına ait değil. Değiştirilmiş olabilir.
# review: new
pgp-file-name-public = { $who } ortak anahtar.asc
# review: new
pgp-file-name-private = { $who } gizli anahtar yedeği.asc
# review: new
pgp-pending = { $date } tarihinde şu adres için farklı bir anahtar bulundu: { $address }

## İmzalı ve şifreli postayı okuma (protect.rs)
# review: new
pgp-part-verified = İmzalayan: { $signer }, anahtar doğrulandı
# review: new
pgp-part-signed = İmzalayan: { $signer } (anahtar doğrulanmadı)
# review: new
pgp-part-other = İmzalayan: { $signer }, gönderen değil
# review: new
pgp-part-unknown-key = İmzalı, ancak anahtar bilinmiyor
# review: new
pgp-part-not-signed = İmzalı değil
# review: new
pgp-part-not-checked = İmza denetlenmedi
# review: new
pgp-part-encrypted = Şifreli. { $signature }
# review: new
pgp-part-no-key = Sizde olmayan bir anahtara şifrelenmiş
# review: new
pgp-part-changed = Şifreli bölüm yolda değiştirildi ve gösterilmiyor
# review: new
pgp-part-unprotected = Değişikliklere karşı koruma olmadan şifrelenmiş, gösterilmiyor
# review: new
pgp-part-broken = Şifreli bölüm okunamıyor
# review: new
pgp-why-mismatch = İmza bu metinle eşleşmiyor
# review: new
pgp-why-weak-hash = İmza artık güvenli olmayan bir yöntem kullanıyor: { $hash }
# review: new
pgp-why-key-expired = Anahtarın süresi dolduktan sonra imzalanmış (süre sonu: { $date })
# review: new
pgp-why-key-revoked = İptal edilmiş bir anahtarla imzalanmış
# review: new
pgp-why-not-signing-key = İmzalama yetkisi olmayan bir anahtarla imzalanmış
# review: new
pgp-why-from-future = İmzanın tarihi gelecekte
# review: new
pgp-why-signature-expired = İmzanın süresi doldu
# review: new
pgp-why-key-not-valid = Geçerli olmayan bir anahtarla imzalanmış
# review: new
pgp-why-not-for-you = Başka alıcılar için imzalanmış ve size iletilmiş
# review: new
pgp-part-pictures-loaded = { $label }. Resimler internetten yüklendi
# review: new
pgp-error-no-own-key = İmzalamak veya şifrelemek için şu adrese ait bir anahtarınız yok: { $address }. Araçlar > Şifreleme Anahtarları'nda bir anahtar oluşturun veya İmzala ve Şifrele'yi kapatın.
# review: new
pgp-error-missing-keys = { $count ->
    [one] Şifrelemek için bu alıcının anahtarı yok: { $addresses }.
   *[other] Şifrelemek için bu alıcıların anahtarı yok: { $addresses }.
}
# review: new
pgp-error-encrypted-quote = Bu ileti şifreli bir iletiyi alıntılıyor veya iletiyor, bu yüzden yalnızca şifreli gönderilebilir. Şifrele'yi açın veya alıntılanan metni kaldırın.
# review: new
pgp-error-protect = İleti imzalanamadı veya şifrelenemedi: { $reason }
# review: new
pgp-found-keys = Anahtar bulundu: { $addresses }.
# review: new
pgp-found-none = Şu adresler için anahtar bulunamadı: { $addresses }. Size ortak anahtarlarını göndermelerini isteyin.
# review: new
pgp-found-no-key = Anahtar bulunamadı.
# review: new
pgp-find-unavailable = Anahtarlar şu anda aranamadı: { $error }
# review: new
pgp-publish-pending = keys.openpgp.org şu adreslere bir onay bağlantısı gönderdi: { $addresses }. Bağlantıya tıkladığınızda anahtarınız orada yayımlanır.
# review: new
pgp-publish-done = Anahtarınız keys.openpgp.org'da şu adresler için yayımlandı: { $addresses }.
# review: new
pgp-publish-failed = Anahtar yayımlanamadı: { $error }
# review: new
pgp-keyserver-off = keys.openpgp.org'da anahtar arama Seçenekler'de kapalı.
# review: new
pgp-details-part = Bölüm { $number }: { $label }
# review: new
pgp-details-signed = İmzalandı: { $when }, anahtar: { $key }
# review: new
pgp-details-unknown-key = Sizde olmayan bir anahtarla imzalandı: { $key }
# review: new
pgp-details-opened = Anahtarınıza şifrelendi: { $key }
# review: new
pgp-details-for = Şifrelendiği anahtarlar: { $keys }
# review: new
pgp-details-plain = İmzalı değil ve şifreli değil
# review: new
pgp-bar-parts = Bu iletinin { $count } bölümü var: { $list }. Her bölüm nasıl korunduğunu gösterir.
# review: new
pgp-bar-count-verified = { $count } doğrulanmış
# review: new
pgp-bar-count-good = { $count ->
    [one] 1 imzalı veya şifreli
   *[other] { $count } imzalı veya şifreli
}
# review: new
pgp-bar-count-warning = { $count ->
    [one] 1 bölüm dikkat gerektiriyor
   *[other] { $count } bölüm dikkat gerektiriyor
}
# review: new
pgp-bar-count-neutral = Doğrulanmış imzası olmayan: { $count }
# kurulum dosyası: başka bir bilgisayara taşınan ayarlar, hesaplar, kişiler ve anahtarlar
# review: new
setup-part-settings = Ayarlar
# review: new
setup-part-preferences = Pencere tercihleri
# review: new
setup-part-accounts = Hesaplar
# review: new
setup-part-sign-in-apps = Oturum açma uygulamaları
# review: new
setup-part-contacts = Kişiler ve gruplar
# review: new
setup-part-keys = Şifreleme anahtarları
# review: new
setup-part-rules = İleti kuralları
# review: new
setup-part-trusted-senders = Güvenilen gönderenler
# review: new
setup-holds-settings = { $count ->
    [one] 1 ayar
   *[other] { $count } ayar
}
# review: new
setup-holds-preferences = { $count ->
    [one] 1 tercih
   *[other] { $count } tercih
}
# review: new
setup-holds-accounts = { $count ->
    [one] 1 hesap
   *[other] { $count } hesap
}
# review: new
setup-holds-sign-in-apps = { $count ->
    [one] 1 oturum açma uygulaması
   *[other] { $count } oturum açma uygulaması
}
# review: new
setup-holds-built-in = Hangi yerleşik oturum açma uygulamalarının açık olduğu
# review: new
setup-holds-contacts = { $count ->
    [one] 1 kişi
   *[other] { $count } kişi
}
# review: new
setup-holds-groups = { $count ->
    [one] 1 grup
   *[other] { $count } grup
}
# review: new
setup-holds-own-keys = { $count ->
    [one] Size ait 1 anahtar
   *[other] Size ait { $count } anahtar
}
# review: new
setup-holds-contact-keys = { $count ->
    [one] Bir kişiye ait 1 anahtar
   *[other] Kişilere ait { $count } anahtar
}
# review: new
setup-holds-rules = { $count ->
    [one] 1 kural
   *[other] { $count } kural
}
# review: new
setup-holds-trusted-senders = { $count ->
    [one] 1 güvenilen gönderen
   *[other] { $count } güvenilen gönderen
}
# review: new
setup-sign-in-password = Parola
# review: new
setup-account-secret-password = Parolası dosyada.
# review: new
setup-account-secret-token = Oturum açma bilgisi dosyada.
# review: new
setup-account-asks-password = İçe aktarmadan sonra parolasını sorar.
# review: new
setup-account-signs-in-again = İçe aktarmadan sonra yeniden oturum açarsınız.
# review: new
setup-account-here = Burada zaten kurulu, bu yüzden atlanır.
# review: new
setup-account-no-app = Burada kurulu olmayan bir uygulamayla oturum açıyor: { $app }. Oturum açma uygulamalarını da içe aktarın.
# review: new
setup-invalid-address = “{ $address }” bir e-posta adresi değil.
# review: new
setup-invalid-server = { $server } sunucusunun kullanılabilir bir adı veya bağlantı noktası yok.
# review: new
setup-invalid-user = Kullanıcı adı yok.
# review: new
setup-invalid-sign-in = Inbox Classic'in bilmediği bir yolla oturum açıyor.
# review: new
setup-error-empty = Dosya boş.
# review: new
setup-error-too-large = Dosya bir Inbox Classic kurulumu olamayacak kadar büyük.
# review: new
setup-error-not-setup = Bu dosya bir Inbox Classic kurulumu değil.
# review: new
setup-error-damaged = Kurulum dosyası hasarlı ve okunamıyor.
# review: new
setup-error-newer = Bu kurulum daha yeni bir Inbox Classic sürümüyle kaydedildi ({ $version }). Inbox Classic'i güncelleyin ve yeniden içe aktarın.
# review: new
setup-error-needs-passphrase = Bu kurulum bir anahtar parolasıyla korunuyor. Kaydedilirken kullanılan parolayı yazın.
# review: new
setup-error-wrong-passphrase = Bu kurulum o parolayla kaydedilmedi.
# review: new
setup-error-changed = Kurulum dosyası kaydedildikten sonra değiştirilmiş veya hasar görmüş, bu yüzden içe aktarılamaz.
# review: new
setup-error-read = Kurulum dosyası okunamadı: { $error }
# review: new
setup-error-write = Kurulum kaydedilemedi: { $error }
# review: new
setup-error-no-parts = En az bir bölüm seçin.
# review: new
setup-left-out = { $count ->
    [one] { $part } bölümünün 1 girdisi kullanılamıyor ve dışarıda bırakıldı.
   *[other] { $part } bölümünün { $count } girdisi kullanılamıyor ve dışarıda bırakıldı.
}
# review: new
setup-imported-settings = Ayarlar değiştirildi.
# review: new
setup-imported-preferences = Pencere tercihleri değiştirildi.
# review: new
setup-added-accounts = { $count ->
    [one] 1 hesap eklendi.
   *[other] { $count } hesap eklendi.
}
# review: new
setup-skipped-here = Burada zaten kurulu olduğu için atlandı: { $address }
# review: new
setup-skipped-no-app = Atlandı: { $address }. Burada kurulu olmayan bir uygulamayla oturum açıyor: { $app }
# review: new
setup-skipped-invalid = Atlandı: { $address }. Neden: { $reason }
# review: new
setup-asks-password = Bağlandığında parolasını soracak: { $address }
# review: new
setup-signs-in-again = Bağlandığında yeniden oturum açmanızı isteyecek: { $address }
# review: new
setup-added-sign-in-apps = { $count ->
    [one] 1 oturum açma uygulaması eklendi.
   *[other] { $count } oturum açma uygulaması eklendi.
}
# review: new
setup-skipped-sign-in-apps = { $count ->
    [one] 1 oturum açma uygulaması burada zaten kurulu.
   *[other] { $count } oturum açma uygulaması burada zaten kurulu.
}
# review: new
setup-added-contacts = { $count ->
    [one] Adres defterine 1 kişi eklendi.
   *[other] Adres defterine { $count } kişi eklendi.
}
# review: new
setup-skipped-contacts = { $count ->
    [one] 1 kişi zaten adres defterinde.
   *[other] { $count } kişi zaten adres defterinde.
}
# review: new
setup-added-groups = { $count ->
    [one] 1 grup eklendi veya tamamlandı.
   *[other] { $count } grup eklendi veya tamamlandı.
}
# review: new
setup-added-own-keys = { $count ->
    [one] Size ait 1 anahtar eklendi.
   *[other] Size ait { $count } anahtar eklendi.
}
# review: new
setup-added-contact-keys = { $count ->
    [one] Bir kişiye ait 1 anahtar eklendi.
   *[other] Kişilere ait { $count } anahtar eklendi.
}
# review: new
setup-added-rules = { $count ->
    [one] 1 ileti kuralı eklendi.
   *[other] { $count } ileti kuralı eklendi.
}
# review: new
setup-skipped-rules = { $count ->
    [one] 1 ileti kuralı burada zaten var.
   *[other] { $count } ileti kuralı burada zaten var.
}
# review: new
setup-skipped-rules-account = { $count ->
    [one] 1 ileti kuralı burada olmayan bir hesaba ait, bu yüzden atlandı.
   *[other] { $count } ileti kuralı burada olmayan hesaplara ait, bu yüzden atlandı.
}
# review: new
setup-rules-waiting = { $count ->
    [one] 1 ileti kuralı iletileri, hesabı eşitlendiğinde görünecek bir klasöre taşıyor.
   *[other] { $count } ileti kuralı iletileri, hesapları eşitlendiğinde görünecek klasörlere taşıyor.
}
# review: new
setup-added-trusted-senders = { $count ->
    [one] 1 güvenilen gönderen eklendi.
   *[other] { $count } güvenilen gönderen eklendi.
}
# review: new
setup-nothing = Hiçbir şey içe aktarılmadı.
# review: new
setup-account-servers = { $imap } ve { $smtp } ({ $signin })
# review: new
setup-file-name = Inbox Classic ayarları ve hesapları
# review: new
setup-skipped-unreachable = Atlandı: { $name }. Oturum açma hizmetine ulaşılamadı. Oturum Açma Uygulamaları'nda yeniden ekleyin.
# review: new
attachment-runs-programs = “{ $name }” program çalıştırabilir, bu yüzden Inbox Classic onu açmaz. Kaydedin, kaynağına güveniyorsanız kendiniz açın.
# review: new
attachment-decrypted-note = Bu ek şifreli bir iletiden geliyor. Inbox Classic onu açmak için şifresi çözülmüş olarak bu bilgisayarda, size ait ve bir gün sonra boşalttığı bir klasörde saklar.
