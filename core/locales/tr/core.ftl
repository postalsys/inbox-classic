# Çekirdeğin söyledikleri, her platformda aynı. { $braces } içindeki yer tutucuları kod doldurur; dilin istediği yerde
# kalsınlar. Çoğullar sayıya göre seçilir: İngilizcede [one] ve *[other], sizin dilinizde dilinizin biçimleri.

## Sayılar ve boyutlar

messages = { $count ->
    [one] 1 ileti
   *[other] { $count } ileti
}
# boyutlardaki ondalık ayırıcı: 2,4 MB
decimal-separator = ,
size-bytes = { $count ->
    [one] 1 bayt
   *[other] { $count } bayt
}
size-kb = { $size } KB
size-mb = { $size } MB
size-gb = { $size } GB
send-delay-off = Kapalı
send-delay-seconds = { $count ->
    [one] 1 saniye
   *[other] { $count } saniye
}
# durum çubuğu: "12 ileti, 3 okunmamış"
list-counts = { $messages }, { $unread } okunmamış
list-counts-selected = { $messages }, { $unread } okunmamış, { $selected } seçili
# arama sırasında durum çubuğu: "12 bulundu, 3 okunmamış"
list-counts-found = { $found } bulundu, { $unread } okunmamış
list-counts-found-selected = { $found } bulundu, { $unread } okunmamış, { $selected } seçili
list-counts-none = İleti bulunamadı

## Özel klasörler, Outlook Express'in adlandırdığı gibi

folder-inbox = Gelen Kutusu
folder-sent = Gönderilmiş Öğeler
folder-deleted = Silinmiş Öğeler
folder-drafts = Taslaklar
folder-junk = Gereksiz E-posta
folder-archive = Arşiv

## Okuma bölmesi

reader-no-message = Seçili ileti yok.
reader-downloading = İleti indiriliyor…
reader-downloading-detail = İndirme tamamlanınca ileti burada görünecek.
reader-downloading-size = İletinin boyutu: { $size }. İndirildiğinde burada görünecek.
reader-failed = İleti indirilemedi
reader-failed-network = Posta sunucusuna ulaşılamadı ({ $reason }).
reader-failed-sign-in = Posta sunucusu oturum açmayı kabul etmedi ({ $reason }). Parolayı denetleyin veya Dosya > Hesaplar'da yeniden oturum açın.
reader-failed-security = Posta sunucusuyla güvenli bağlantı kurulamadı ({ $reason }).
reader-failed-other = Posta sunucusunun yanıtı: { $reason }.
reader-retry-note = Hesap yeniden bağlandığında tekrar denenecek.
reader-unreadable = Bu ileti gösterilemiyor: { $error }
message-source-title = İleti Kaynağı: { $subject }
message-source-untitled = İleti Kaynağı

## Bir iletiyi yazdırma ve yanıtta ya da iletmede alıntılanan iletinin üst bilgisi

header-from = Kimden
header-date = Tarih
header-to = Kime
header-cc = Bilgi
header-sent = Gönderildi
header-subject = Konu
header-security = Güvenlik
header-part = Bölüm { $number }
quote-original = ----- Özgün İleti -----
fold-show-earlier = Önceki iletileri göster

## Geri dönen iletiler: bir iletinin teslim edilmediğini bildiren notun üstündeki kart

bounce-failed = İletiniz teslim edilmedi
bounce-delayed = İletiniz henüz teslim edilmedi
bounce-delayed-note = Posta sunucunuz iletiyi teslim etmeye hâlâ çalışıyor. Yeniden göndermeniz gerekmez.
# notun ilgili olduğu iletinin bağlantısı, Gönderilmiş Öğeler'de veya başka bir klasörde
bounce-show-message = Geri dönen iletiyi göster
# gecikme kartında hâlâ yolda olan iletinin bağlantısı
bounce-show-delayed = Geciken iletiyi göster
bounce-what-to-do = Yapabilecekleriniz:
# iletinin hâlâ yolda olduğu bir alıcı için yapılacaklar: gecikme kartında ve başarısızlık kartında
bounce-delayed-do = Şimdilik bir şey yapmanız gerekmez. Yine teslim edilemezse başka bir bildirim alırsınız.
bounce-delayed-row-do = Şimdilik bir şey yapmanız gerekmez. Posta sunucunuz teslim etmeyi deniyor. Başarılı olamazsa başka bir bildirim alırsınız.
# alan sunucunun kendi sözlerini katlar
bounce-details = Ayrıntılar
# bildirimin adını vermediği bir alıcı
bounce-someone = Bir alıcı
# Ayrıntılar'da: iletiyi reddeden sunucu, verdiği durum kodu ve bildirimi yazan sunucu
bounce-server = Sunucu: { $server }
bounce-status = Durum: { $status }
bounce-reported-by = Bildiren: { $server }
bounce-retry-minutes = Alıcı sunucu bir sonraki denemeden önce { $count ->
    [one] bir dakika
   *[other] { $count } dakika
} beklenmesini istedi.
bounce-retry-hours = Alıcı sunucu bir sonraki denemeden önce { $count ->
    [one] bir saat
   *[other] { $count } saat
} beklenmesini istedi.
# engelleme listelerinin adları, "Spamhaus ZEN, Barracuda"
bounce-blocklist = Engelleme listesi: { $lists }
bounce-user-unknown = Adres yok
bounce-user-unknown-why = Alıcı sunucuda bu adrese ait bir posta kutusu yok. Adres yanlış yazılmış olabilir veya kişi artık bu adresi kullanmıyor olabilir.
bounce-user-unknown-do = Adresin yazımını denetleyin veya kişiye şimdi kullandığı adresi sorun.
bounce-invalid-address = Adres geçerli değil
bounce-invalid-address-why = Adres, posta gönderilebilecek bir biçimde yazılmamış.
bounce-invalid-address-do = Adresin yazımını denetleyin. Fazladan boşluk, eksik harf veya @ işaretinden sonra eksik etki alanı olup olmadığına bakın.
bounce-mailbox-disabled = Posta kutusu kapalı
bounce-mailbox-disabled-why = Adres var, ancak posta kutusu kapatılmış veya artık kullanılmıyor.
bounce-mailbox-disabled-do = Kişiye başka bir yoldan ulaşın ve şimdi kullandığı adresi sorun.
bounce-mailbox-full = Posta kutusu dolu
bounce-mailbox-full-why = Alıcının posta kutusunda yeni posta için yer yok.
bounce-mailbox-full-do = Birkaç gün sonra yeniden gönderin veya alıcıya başka bir yoldan ulaşın. Posta kutusunda az yer kaldığında büyük ekler içeren iletiler önce reddedilebilir.
bounce-spam-blocked = İstenmeyen posta olarak reddedildi
bounce-spam-blocked-why = Alıcı sunucu iletiyi istenmeyen posta olarak değerlendirdi.
bounce-spam-blocked-do = Çok sayıda bağlantı, kısaltılmış URL veya büyük ek gibi istenmeyen posta şüphesi uyandırabilecek içerikleri çıkarıp yeniden deneyin. Sorun sürerse e-posta sağlayıcınıza başvurun.
bounce-virus-detected = Virüs nedeniyle reddedildi
bounce-virus-detected-why = Alıcı sunucu iletide veya eklerinde virüs ya da başka zararlı içerik buldu.
bounce-virus-detected-do = Ekleri bir antivirüs programıyla tarayın. Bazı sunucular tüm çalıştırılabilir dosyaları veya arşivleri engeller. Gerekirse bu dosyaları bir bağlantı üzerinden paylaşın.
bounce-ip-blocklisted = Posta sunucunuz bir engelleme listesinde
bounce-ip-blocklisted-why = Alıcı sunucu, gönderim yapan sunucunun IP adresi bir engelleme listesinde olduğu için iletiyi reddediyor.
bounce-ip-blocklisted-do = Sorun iletinizin içeriğinde değil. Bu bildirimi e-posta sağlayıcınıza iletip sunucunun engelleme listesinden çıkarılmasını isteyin.
bounce-domain-blocklisted = Bir etki alanı engelleme listesinde
bounce-domain-blocklisted-why = Alıcı sunucu iletiyi reddediyor, çünkü adresinizin etki alanı veya iletideki bağlantılardan birinin etki alanı bir engelleme listesinde.
bounce-domain-blocklisted-do = İletide bağlantılar varsa onlarsız deneyin. Yoksa bu bildirimi etki alanınızın postasını yöneten kişiye iletin.
bounce-policy-blocked = Alıcı sunucunun kuralları nedeniyle reddedildi
bounce-policy-blocked-why = Alıcı sunucunun kuralları iletinin kabul edilmesini engelliyor. Bunun nedeni ileti boyutu, ekler veya gönderen olabilir.
bounce-policy-blocked-do = Ayrıntılar bölümündeki sunucu yanıtı genellikle nedeni açıklar. Alıcıya bu tür iletileri kabul edip edemediğini sorun.
bounce-geo-blocked = Geldiği yer nedeniyle reddedildi
bounce-geo-blocked-why = Alıcı sunucu, posta sunucunuzun bulunduğu ülkeden veya ağdan posta almıyor.
bounce-geo-blocked-do = Kişiye başka bir yoldan ulaşın veya posta sağlayıcınıza sorun.
bounce-relay-denied = Sunucu iletiyi aktarmadı
bounce-relay-denied-why = Sunucu iletiyi başka bir sunucuya aktarmayı reddetti. Bunun nedeni genellikle oturum açılmadan gönderim yapılması veya alıcıya posta iletmeye yetkili olmayan bir sunucunun kullanılmasıdır.
bounce-relay-denied-do = Dosya > Hesaplar bölümünde giden posta sunucusunu ve oturum açma ayarlarını denetleyin.
bounce-auth-failure = Gönderen adresiniz doğrulanamadı
bounce-auth-failure-why = Alıcı sunucu, iletinin gerçekten etki alanınızdan geldiğini doğrulayamadı (SPF, DKIM veya DMARC).
bounce-auth-failure-do = Bu bildirimi etki alanınızın postasını yöneten kişiye iletin: ayarlarının düzeltilmesi gerekiyor. Bu arada sağlayıcınızın kendi sunucusu üzerinden göndermek işe yarayabilir.
bounce-rate-limited = Aynı anda çok fazla posta
bounce-rate-limited-why = Alıcı sunucu şimdilik posta sunucunuzdan daha az ileti kabul ediyor.
bounce-rate-limited-do = Bir süre bekleyip yeniden gönderin. Çok kişiye yazarken her seferinde daha az kişiye gönderin.
bounce-greylisting = Kısa bir süre bekletildi
bounce-greylisting-why = Alıcı sunucu, tanımadığı gönderenlerden biraz sonra yeniden denemelerini istiyor; bu, istenmeyen postaya karşı yaygın bir denetimdir.
bounce-greylisting-do = Bir şey yapmanız gerekmez. Posta sunucuları kendiliğinden yeniden dener ve ileti genellikle bir saat içinde teslim edilir.
bounce-server-error = Alıcı sunucuda bir sorun oluştu
bounce-server-error-why = Alıcı sunucuya ulaşılamadı veya sunucu kendi sorunu nedeniyle iletiyi alamadı.
bounce-server-error-do = Daha sonra yeniden gönderin. Başarısız olmaya devam ederse adresin @ işaretinden sonraki kısmında yazım hatası olup olmadığına bakın.
bounce-unknown = Teslim edilmedi
bounce-unknown-why = Bildirimde teslim edilememe nedeni açıkça belirtilmemiş.
bounce-unknown-do = Ayrıntılar bölümündeki sunucu yanıtında daha fazla bilgi olabilir. Nedeni anlayamazsanız bildirimi e-posta sağlayıcınıza iletin.

## Birden çok ileti seçili

selection-title = { $count ->
    [one] 1 ileti seçili
   *[other] { $count } ileti seçili
}
selection-unread = { $count } okunmamış
selection-flagged = { $count } bayraklı
delete-for-good-one = Bu ileti kalıcı olarak silinecek. Silinsin mi?
delete-for-good-all = Seçili { $count } ileti kalıcı olarak silinsin mi?
delete-for-good-some = Toplam { $total } iletiden { $count } tanesi kalıcı olarak silinecek. Devam edilsin mi?
done-read = { $count ->
   *[other] Okundu olarak işaretlendi: { $messages }
}
done-unread = { $count ->
   *[other] Okunmadı olarak işaretlendi: { $messages }
}
done-flagged = { $count ->
   *[other] Bayrak kondu: { $messages }
}
done-unflagged = Bayrak kaldırıldı: { $messages }
done-deleted-for-good = { $count ->
   *[other] Kalıcı olarak silindi: { $messages }
}
done-archived = { $count ->
   *[other] Arşivlendi: { $messages }
}
done-moved = { $count ->
   *[other] Taşındı: { $messages }. Hedef: { $folder }
}
done-copied = { $count ->
   *[other] Kopyalandı: { $messages }. Hedef: { $folder }
}
done-moving = { $count ->
   *[other] Taşınıyor: { $messages }. Hedef: { $folder }...
}
done-copying = { $count ->
   *[other] Kopyalanıyor: { $messages }. Hedef: { $folder }...
}
done-moved-back = { $count ->
   *[other] Geri taşındı: { $messages }. Hedef: { $folder }
}
# Konuşmayı İzle ve Konuşmayı Yoksay'dan sonra, ve işaretli bir konuşmada ikisinden biri yeniden seçildikten sonra durum çubuğu
done-watched = { $count ->
    [one] Konuşma izleniyor
   *[other] { $count } konuşma izleniyor
}
done-unwatched = { $count ->
    [one] Konuşma artık izlenmiyor
   *[other] { $count } konuşma artık izlenmiyor
}
done-ignored = { $count ->
    [one] Konuşma yoksayılıyor
   *[other] { $count } konuşma yoksayılıyor
}
done-unignored = { $count ->
    [one] Konuşma artık yoksayılmıyor
   *[other] { $count } konuşma artık yoksayılmıyor
}
their-folders = kendi klasörleri
undo-move = Taşımayı Geri Al
undo-delete = Silmeyi Geri Al
undo-archive = Arşivlemeyi Geri Al
undo-junk = Gereksiz Olarak İşaretlemeyi Geri Al
undo-not-junk = Gereksiz Değil Olarak İşaretlemeyi Geri Al
undo-send = Gönderimi Geri Al
nothing-to-undo = Geri alınacak bir şey yok.
messages-gone = İletiler artık bu konumda bulunmuyor.
# Seçilemeyen bir IMAP klasörü ileti içeremez; bu, klasörün boş olduğu anlamına gelmez.
folder-holds-no-messages = Bu klasör ileti içeremez.
not-archived-here = Bu klasördeki iletiler arşivlenemez.
not-emptied-here = Yalnızca Silinmiş Öğeler ve Gereksiz E-posta boşaltılabilir.
next-unread-question = { $folder } klasöründe başka okunmamış ileti yok.

    Okunmamış iletileri olan bir sonraki klasöre, { $next } klasörüne gidilsin mi?
no-unread-left = Okunmamış ileti kalmadı.
empty-question = { $count ->
    [one] { $folder } boşaltılsın mı?

        İçindeki ileti kalıcı olarak silinir. Geri getirilemez.
   *[other] { $folder } boşaltılsın mı?

        İçindekiler kalıcı olarak silinir ({ $messages }). Geri getirilemezler.
}
no-junk-folder = Bu hesapta iletilerin taşınacağı bir Gereksiz E-posta klasörü yok.
no-inbox-folder = Bu hesapta iletilerin taşınacağı bir Gelen Kutusu klasörü yok.
# renkli bir bayraktan sonra durum çubuğu: "2 iletiye mavi bayrak kondu"
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

move-window-title-move = { $count ->
    [one] İletiyi Taşı
   *[other] { $count } İletiyi Taşı
}
move-window-title-copy = { $count ->
    [one] İletiyi Kopyala
   *[other] { $count } İletiyi Kopyala
}
move-window-prompt-move = { $count ->
    [one] Seçili iletinin taşınacağı yer:
   *[other] Seçili { $count } iletinin taşınacağı yer:
}
move-window-prompt-copy = { $count ->
    [one] Seçili iletinin kopyalanacağı yer:
   *[other] Seçili { $count } iletinin kopyalanacağı yer:
}
# klasör ağacının üstünde, en son kullanılan klasörler
targets-recent = Son Kullanılanlar
# iletilerin bulunduğu, seçilemeyen klasör
target-current = { $folder } (bulunduğu klasör)
# en son kullanılan bir klasör, birden çok hesap varsa hesabıyla: "Arşiv (İş)"
target-recent = { $folder } ({ $account })

## Başka bir hesaba taşıma ve kopyalama

transfer-moving = Taşınıyor: { $done } / { $messages }. Hedef: { $folder }...
transfer-copying = Kopyalanıyor: { $done } / { $messages }. Hedef: { $folder }...
transfer-another-account = başka bir hesap
transfer-folder-gone = hedef klasör artık yok
transfer-not-on-server = ileti artık sunucuda değil
transfer-not-moved = { $count ->
   *[other] Başka bir hesaba taşınamadı: { $messages }. Neden: { $reason }
}
transfer-not-copied = { $count ->
   *[other] Başka bir hesaba kopyalanamadı: { $messages }. Neden: { $reason }
}
transfer-none-moved = Hiçbir ileti taşınamadı
transfer-none-copied = Hiçbir ileti kopyalanamadı

## Dosya olarak iletiler

export-not-in-time = ileti zamanında indirilemedi
export-not-saved = Kaydedilemeyen ileti sayısı: { $failed }. Toplam: { $messages }. Neden: { $problems }
export-not-attached = iletiler eklenemedi: { $error }
# birden çok iletiyle Farklı Kaydet'ten sonra durum çubuğu: "Kaydedildi: 3 ileti. Hedef: Masaüstü"
saved-to = { $count ->
   *[other] Kaydedildi: { $messages }. Hedef: { $folder }
}
download-progress = İndiriliyor: { $done } / { $total }
download-done = İndirildi: { $size }
downloading-messages = { $count ->
   *[other] İndiriliyor: { $messages }...
}
# dosyalar bir klasöre bırakıldıktan sonra durum çubuğu: "Eklendi: 3 ileti. Hedef: Arşiv"
import-put = { $count ->
   *[other] Eklendi: { $messages }. Hedef: { $folder }
}
import-not-put = Şu iletiler klasöre eklenemedi:

    { $problems }

## Pencerelerin gösterdiği sorunlar

error-store = yerel depo: { $error }
error-not-found = bulunamadı
error-closed = kapatılıyor
error-other-account = tarayıcıda farklı bir hesapla oturum açıldı: { $email }
# posta sunucusunun reddettiği bir parola veya oturum açma, sunucunun sözleriyle
failure-authentication = sunucu oturum açmayı kabul etmedi ({ $reason })
# posta sunucusuna ulaşılamadı veya bağlantı koptu, nedeniyle
failure-network = sunucuyla bağlantı başarısız oldu ({ $reason })
error-in-use = bu uygulamayla oturum açan hesaplar varken kaldırılamaz: { $accounts }
error-turned-off = bu oturum açma uygulaması yeni hesaplar için devre dışı
error-folder-name = klasör adı 1 ile 200 karakter uzunluğunda olmalı ve denetim karakteri içermemelidir
error-folder-separator = bu sunucuda klasör adları “{ $separator }” karakterini içeremez
error-folder-special = Gelen Kutusu ve özel klasörler yeniden adlandırılamaz veya silinemez
error-no-recipients = iletinin alıcısı yok
error-bad-address = “{ $address }” bir e-posta adresi değil
error-not-own-address = { $address } bu hesabın gönderen adreslerinden biri değil. Hesap özelliklerindeki “Diğer gönderen adresleri” alanına ekleyin.
rule-query-refused = Kurallar klasöre veya tarihe göre süzemez ({ $words }).
rule-no-query = Gelen iletiler için arama ölçütleri girin.
rule-no-action = Kural için en az bir eylem seçin.
error-attachment = { $path } okunamadı: { $error }
error-no-drafts = hesapta iletinin kaydedileceği bir Taslaklar klasörü yok
error-draft-attachment = taslağın bir eki korunamadı: { $error }
error-password-not-saved = parola sonraki oturumlarda kullanılmak üzere kaydedilemedi: { $error }
error-sign-in-not-saved = yeni oturum açma bilgileri sonraki oturumlarda kullanılmak üzere kaydedilemedi: { $error }
error-import-unreadable = { $path } okunamıyor: { $error }
error-import-too-large = { $path } 50 MB'tan büyük
error-import-not-mail = { $path } bir e-posta iletisi değil
error-list-answered = posta listesi sunucusu şu durumu döndürdü: { $status }
error-not-built = ileti oluşturulamadı
error-outbox-waits = { $count ->
    [one] ileti Giden Kutusu'nda bekliyor ve bir sonraki Gönder/Al ile gönderilecek
   *[other] { $count } ileti Giden Kutusu'nda bekliyor ve bir sonraki Gönder/Al ile gönderilecek
}
error-draft-not-removed = iletinin önceki taslağı Taslaklar'dan kaldırılamadı: { $reason }
error-sent-but = ileti gönderildi, ancak { $problem }
error-sent-still-in-outbox = hâlâ Giden Kutusu'nda: { $error }
error-sent-no-copy = Gönderilmiş Öğeler'e kopya kaydedilemedi: { $reason }
error-no-password = bu hesap için kayıtlı parola yok
error-no-sign-in = bu hesap için oturum açma bilgisi yok
error-provider-missing = bu sürümde şu sağlayıcı için oturum açma uygulaması bulunamadı: { $provider }. Uygulama kaldırılmış olabilir.
error-provider-servers = bu hesabın sunucuları, oturum açma uygulamasının sunucularıyla eşleşmiyor
error-app-scopes = { $reason }. Posta sunucusu oturum açma uygulamasının belirtecini kabul etmedi: uygulamanın izinlerinin (scopes) postaya erişim verdiğini denetleyin
error-in-folder = { $folder }: { $reason }

## Oturum açma uygulamaları

sign-in-off-google = Google, Inbox Classic'i henüz doğrulamadığı için yalnızca test kullanıcıları bu uygulamayla oturum açabilir. Kendi Google oturum açma uygulamanızı veya hesabınız destekliyorsa bir uygulama parolası kullanın. Test kullanıcısıysanız Dosya > Hesaplar > Oturum Açma Uygulamaları bölümünden bu seçeneği etkinleştirebilirsiniz.
sign-in-off-other = Dosya > Hesaplar > Oturum Açma Uygulamaları bölümünde devre dışı bırakıldı. Aynı yerden yeniden etkinleştirebilirsiniz.
sign-in-app-no-name = oturum açma uygulamasının bir adı olmalı
sign-in-app-no-client = istemci kimliği eksik
sign-in-app-no-scopes = oturum açma uygulaması postaya erişim veren izinleri (scopes) gerektirir
sign-in-app-bad-host = { $server } sunucu adresi eksik veya geçerli bir ana bilgisayar adı değil
sign-in-app-plain = { $server } sunucusu SSL/TLS veya STARTTLS kullanmalı
sign-in-app-not-checked = yayımcı henüz denetlenmedi
sign-in-app-issuer-changed = yayımcı değişti: istemci gizli dizisini yeniden yazın veya kaldırın
sign-in-register-google = Google Cloud Console'da, onay ekranında https://mail.google.com/ izni olan, Masaüstü uygulaması türünde bir OAuth istemcisi oluşturun. Uygulama test aşamasındayken yalnızca test kullanıcıları oturum açabilir.
sign-in-register-microsoft = Microsoft Entra'da Mobil ve masaüstü uygulamaları platformunu seçerek bir uygulama kaydedin. Yeniden yönlendirme URI'si olarak http://localhost girin, genel istemci akışlarına izin verin ve IMAP.AccessAsUser.All, SMTP.Send ile offline_access temsilci izinlerini ekleyin. Uygulama yalnızca kuruluşunuz içinse yayımcı olarak https://login.microsoftonline.com/<kiracı kimliği>/v2.0 kullanın.
sign-in-register-other = Aşağıdaki yeniden yönlendirme URI'sini kullanarak yerel bir genel istemci kaydedin. Sağlayıcı bu URI'de herhangi bir bağlantı noktasının kullanılmasına izin vermelidir (RFC 8252). Postaya erişim sağlayan izni (scope) ekleyin.

## Takvim davetleri

repeats = Yineleme
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
repeats-on = { $repeats }, günler: { $days }
# "Her hafta, 10 kez"
repeats-times = { $count ->
    [one] { $repeats }, bir kez
   *[other] { $repeats }, { $count } kez
}
day-monday = Pazartesi
day-tuesday = Salı
day-wednesday = Çarşamba
day-thursday = Perşembe
day-friday = Cuma
day-saturday = Cumartesi
day-sunday = Pazar

## Yapay zeka aracıları

agent-level-read = Postayı okuma: klasörleri, ileti listelerini ve içeriklerini görüntüleme, arama yapma
agent-level-organize = Postayı düzenleme: okundu durumunu ve bayrakları değiştirme, gereksiz postayı yönetme, iletileri taşıma ve arşivleme, klasör oluşturma, iletileri Silinmiş Öğeler'e taşıyarak silme ve onayınızla posta listelerinden çıkma
agent-level-drafts = Göndermeniz için taslak yazma
agent-level-send = Posta gönderme, her iletiyi ancak siz onayladıktan sonra
agent-connect-title = { $program } postanıza erişmek istiyor
agent-connect-detail = Bir yapay zeka aracısı Inbox Classic'e erişmek istiyor. Yapabileceklerini ve erişebileceği hesapları seçin. Bu izinleri daha sonra Araçlar > Yapay Zeka Aracıları bölümünden değiştirebilirsiniz.

    Aracılar başkalarının yazdığı iletileri okur. Bu iletiler, aracıyı istenmeyen işlemler yapmaya yönlendirebilir. Inbox Classic üzerinden gönderilecek her ileti için onayınız istenir.
agent-reply-to = Yanıt: “{ $subject }”
agent-reply-all-on = Tümüne yanıt: “{ $subject }”
agent-forward-of = İletme: “{ $subject }”
agent-never-written-one = Bu adrese hiç yazmadınız: { $address }
agent-never-written-many = Bu adreslerden { $count } tanesine hiç yazmadınız.
agent-send-title = { $program } bu iletiyi göndermek istiyor
agent-send-detail = Alıcıları ve iletinin içeriğini denetleyin. Onayladığınızda ileti Giden Kutusu'nda { $seconds } saniye bekler; bu sürede onu hâlâ silebilirsiniz.
agent-change-title = { $program } için izinler
agent-change-allowed = Bu programın yapay zeka aracılarının postanızla neler yapabileceğini değiştirin.
agent-change-refused = Bu programın erişimini reddettiniz. Aracılarının postanıza yeniden erişebilmesi için izin verin.
agent-log-taken-back = { $entry } (geri alındı)
agent-files = Dosyalar: { $files }
agent-undo-refused = Geri alınamaz.
agent-undo-refused-why = Geri alınamaz: { $reason }.
agent-undo-impossible = bu geri alınamaz
agent-undo-not-in-folder = ileti artık o klasörde değil
agent-undo-not-arrived = ileti henüz hedef klasörde görünmüyor
agent-undo-sent = ileti artık Giden Kutusu’nda değil
agent-original-not-downloaded = özgün ileti henüz indirilmedi. Önce onu açın
agent-turned-away = Geri çevrildi
agent-can-nothing = Hiçbir şey
agent-can-read = okuma
agent-can-organize = düzenleme
agent-can-drafts = taslak yazma
agent-can-send = onayınızla gönderme
# "Okuma, düzenleme ve taslak yazma"
agent-can-list = { $first } ve { $last }
agent-accounts = { $count ->
    [0] hesap yok
    [one] 1 hesap
   *[other] { $count } hesap
}
# "Okuma ve düzenleme; 1 hesap"
agent-access = { $can }; { $accounts }
agent-unreadable = Bu ileti okunamıyor.
agent-encrypted-original = Bu ileti şifreli: aracı şifreleme yapamadığı için ona yanıt veremez veya onu iletemez.
agent-encrypted = Bu ileti şifreli. Yapay zeka aracıları içeriğini okuyamaz. Kullanıcının iletiyi Inbox Classic'te açması gerekir.
list-encrypted = Şifreli ileti
agent-log-composed = Tamamlamanız için yeni bir ileti açıldı: “{ $subject }”
agent-log-refused = Gönderimi reddedildi: “{ $subject }”
agent-log-sent = Gönderilmek üzere sıraya alındı: “{ $subject }”. Alıcı: { $to }
agent-log-draft = Taslak kaydedildi: “{ $subject }”
agent-log-draft-replaced = Taslak değiştirildi: “{ $subject }”
agent-log-draft-discarded = Taslak silindi: “{ $subject }”
agent-draft-note = Bu taslağı bir yapay zeka aracısı olan { $program } yazdı. Göndermeden önce alıcıları ve metni kontrol edin.
agent-log-read = Okundu olarak işaretlendi: “{ $subject }”
agent-log-unread = Okunmadı olarak işaretlendi: “{ $subject }”
agent-log-flagged = Bayrak kondu: “{ $subject }”
agent-log-unflagged = Bayrak kaldırıldı: “{ $subject }”
agent-log-deleted = Silinmiş Öğeler'e taşındı: “{ $subject }”
agent-log-moved = Taşındı: “{ $subject }”. Hedef: { $folder }
agent-log-junk = Gereksiz olarak işaretlendi: “{ $subject }”
agent-log-not-junk = Gereksiz değil olarak işaretlendi: “{ $subject }”
agent-log-archived = Arşivlendi: “{ $subject }”
agent-log-folder = Klasör oluşturuldu: “{ $name }”
agent-log-unsubscribed = Abonelikten çıkma isteğini onayladınız. İleti: “{ $subject }”
agent-log-unsubscribe-failed = “{ $subject }” konulu iletinin geldiği listeden çıkılamadı: { $reason }
agent-log-unsubscribe-refused = Abonelikten çıkmayı onaylamadınız. Gönderenler: { $senders }
agent-unsubscribe-title = { $count ->
    [one] { $program } bir posta listesindeki aboneliğinizi iptal etmek istiyor
   *[other] { $program } { $count } posta listesindeki aboneliğinizi iptal etmek istiyor
}
agent-unsubscribe-detail = { $count ->
    [1] Inbox Classic, aşağıdaki listeye abonelikten çıkma isteği gönderir. Bunun için listenin sunduğu tek tıklamayla abonelikten çıkma seçeneğini kullanır. Başka bir şey gönderilmez. Mevcut iletiler değiştirilmez veya taşınmaz.
   *[other] Inbox Classic, aşağıdaki listelerin her birine abonelikten çıkma isteği gönderir. Bunun için her listenin sunduğu tek tıklamayla abonelikten çıkma seçeneğini kullanır. Başka bir şey gönderilmez. Mevcut iletiler değiştirilmez veya taşınmaz.
}

## Dilin klavyelerinde adlandırıldığı biçimiyle tuşlar, yardımda (Windows ve Linux)

key-ctrl = Ctrl
key-alt = Alt
key-shift = Shift
key-del = Del
key-enter = Enter

## Oturum açma ve parolalar

sign-in-no-refresh = sağlayıcı yenileme belirteci döndürmedi
sign-in-no-account = sağlayıcı oturum açılan hesabı bildirmedi
sign-in-not-finished = oturum açma tamamlanmadı
secrets-unavailable = Kullanılamıyor: { $store }
secrets-unavailable-why = Kullanılamıyor: { $store } ({ $error })
secrets-windows = Kimlik Bilgileri Yöneticisi
secrets-mac = anahtar zinciri
secrets-linux = sistem anahtarlığı (Secret Service)
error-no-such-file = böyle bir dosya yok
cards-file-too-big = Dosya boyutu, adres defteri içe aktarma sınırını aşıyor.
ui-sender-added = { $name } Adres Defteri'ne eklendi.
ui-sender-known = { $name } zaten Adres Defteri'nde.
ui-sender-none = Bu iletinin gönderenine ait eklenecek bir e-posta adresi yok.
card-name-needed = Kişinin adı ve e-posta adresi yok.
# Adres Defterini İçe Aktar'ın okunamayan bir dosyası: "kisiler.vcf: böyle bir dosya yok"
cards-file-failed = { $file }: { $reason }

## Tek kullanımlık kodlar: oturum açma veya doğrulama kodu olan bir iletinin üstündeki kart

# kodun ait olduğu, iletiyi imzalayan etki alanı
otp-heading = { $domain } kodu
otp-copy = Kopyala
otp-note = Bu kodu yalnızca şu etki alanının bir sayfasına girin: { $domain }
otp-old = Bu kod, iletiyi açmanızdan bir saatten daha uzun süre önce gönderildi. Büyük olasılıkla süresi dolmuştur.

# bir etkinliğin kartında kaç kişinin davet edildiği
event-attendees =
    { $count ->
        [one] { $count } katılımcı
       *[other] { $count } katılımcı
    }

# kod içeren yeni bir iletinin bildiriminin ilk satırı, iletiyi imzalayan etki alanı için
otp-notification = { $domain } için kodunuz: { $code }

## OpenPGP anahtarları (keys.rs)
pgp-key-valid = Geçerli
pgp-key-expires = Geçerlilik sonu: { $date }
pgp-key-expired = Süresi doldu: { $date }
pgp-key-revoked = İptal edildi
pgp-key-revoked-why = İptal edildi: { $reason }
pgp-key-not-valid = Geçerli değil
pgp-key-locked = Gizli anahtarı koruyan anahtar bulunamadığı için kullanılamıyor. Depo: { $store }. Gizli anahtarınızın yedeğini yeniden içe aktarın.
pgp-source-own = Inbox Classic'te oluşturuldu
pgp-source-file = Bir dosyadan içe aktarıldı
pgp-source-paste = Yapıştırıldı
pgp-source-attachment = Bir iletiden
pgp-source-vcard = Bir kişi kartından
pgp-source-wkd = E-posta adresinin etki alanından (WKD)
pgp-source-keyserver = keys.openpgp.org'dan
pgp-source-autocrypt = Bir iletinin Autocrypt üst bilgisinden
pgp-error-no-store = Gizli anahtarları korumak için kullanılan depoya erişilemiyor: { $store } ({ $error })
pgp-error-wrong-passphrase = Anahtar parolası doğru değil.
pgp-error-not-a-key = Bu bir OpenPGP anahtarı değil.
pgp-error-too-large = Anahtar çok büyük.
pgp-error-unusable = Anahtar eski veya zayıf şifreleme kullanıyor ve kullanılamaz.
pgp-imported-private = { $count ->
    [one] Gizli anahtarınız içe aktarıldı.
   *[other] { $count } gizli anahtar içe aktarıldı.
}
pgp-imported-public = { $count ->
    [one] Bir anahtar içe aktarıldı.
   *[other] { $count } anahtar içe aktarıldı.
}
pgp-imported-pending = Şu adresler için zaten başka bir anahtar kullanılıyor: { $addresses }. Yeni anahtar, kişi özelliklerinden siz seçene kadar kullanılmaz.
pgp-error-needs-passphrase = Gizli anahtar bir anahtar parolasıyla korunuyor. Anahtarı içe aktarmak için parolayı yazın.
pgp-error-mismatch = Gizli anahtar ile ortak anahtar eşleşmiyor. Anahtar verileri değiştirilmiş olabilir.
pgp-file-name-public = { $who } ortak anahtar.asc
pgp-file-name-private = { $who } gizli anahtar yedeği.asc
pgp-pending = { $date } tarihinde şu adres için farklı bir anahtar bulundu: { $address }

## İmzalı ve şifreli postayı okuma (protect.rs)
pgp-part-verified = İmzalayan: { $signer }, anahtar doğrulandı
pgp-part-signed = İmzalayan: { $signer } (anahtar doğrulanmadı)
pgp-part-other = İmzalayan: { $signer }, gönderen değil
pgp-part-unknown-key = İmzalı, ancak anahtar bilinmiyor
pgp-part-not-signed = İmzalı değil
pgp-part-not-checked = İmza denetlenmedi
pgp-part-encrypted = Şifreli. { $signature }
pgp-part-no-key = Şifreyi çözmek için gereken gizli anahtar sizde yok
pgp-part-changed = Şifreli bölümün bütünlüğü doğrulanamadığı için içerik gösterilmiyor
pgp-part-unprotected = Şifreli bölüm değişikliklere karşı korunmadığı için içerik gösterilmiyor
pgp-part-broken = Şifreli bölüm okunamıyor
pgp-why-mismatch = İmza bu metinle eşleşmiyor
pgp-why-weak-hash = İmza artık güvenli olmayan bir yöntem kullanıyor: { $hash }
pgp-why-key-expired = Anahtarın süresi dolduktan sonra imzalanmış (süre sonu: { $date })
pgp-why-key-revoked = İptal edilmiş bir anahtarla imzalanmış
pgp-why-not-signing-key = İmzalama özelliği olmayan bir anahtarla imzalanmış
pgp-why-from-future = İmzanın tarihi gelecekte
pgp-why-signature-expired = İmzanın süresi doldu
pgp-why-key-not-valid = Geçerli olmayan bir anahtarla imzalanmış
pgp-why-not-for-you = Başka alıcılar için imzalanmış ve size iletilmiş
pgp-why-not-key-in-use = { $address } için kullanılan anahtardan farklı bir anahtarla imzalanmış
pgp-part-pictures-loaded = { $label }. Resimler internetten yüklendi
pgp-error-no-own-key = İmzalamak veya şifrelemek için şu adrese ait bir anahtarınız yok: { $address }. Araçlar > Şifreleme Anahtarları'nda bir anahtar oluşturun veya İmzala ve Şifrele'yi kapatın.
pgp-error-missing-keys = { $count ->
    [one] Şifrelemek için bu alıcının anahtarı yok: { $addresses }.
   *[other] Şifrelemek için bu alıcıların anahtarı yok: { $addresses }.
}
pgp-error-encrypted-quote = Bu ileti şifreli bir iletiyi alıntılıyor veya iletiyor, bu yüzden yalnızca şifreli gönderilebilir. Şifrele'yi açın veya alıntılanan metni kaldırın.
pgp-error-protect = İleti imzalanamadı veya şifrelenemedi: { $reason }
pgp-found-keys = Şu adresler için anahtar bulundu: { $addresses }.
pgp-found-none = Şu adresler için anahtar bulunamadı: { $addresses }. Bu adreslerin sahiplerinden ortak anahtarlarını göndermelerini isteyin.
pgp-found-no-key = Anahtar bulunamadı.
pgp-find-unavailable = Anahtar araması yapılamadı: { $error }
pgp-publish-pending = keys.openpgp.org şu adreslere onay bağlantıları gönderdi: { $addresses }. Anahtarınızın her adres için bulunabilmesi, o adrese gelen bağlantıyı onaylamanıza bağlıdır.
pgp-publish-done = Anahtarınız keys.openpgp.org'da şu adresler için yayımlandı: { $addresses }.
pgp-publish-failed = Anahtar yayımlanamadı: { $error }
pgp-keyserver-off = keys.openpgp.org'da anahtar arama, { $settings } bölümünde kapalı.
# the compose window with Sign and Encrypt: the line under the fields, each recipient's key, the questions
pgp-compose-encrypted = { $count ->
    [one] İleti gönderilirken şifrelenip imzalanacak. İçeriği yalnızca siz ve şu alıcı okuyabilirsiniz: { $addresses }.
   *[other] İleti gönderilirken şifrelenip imzalanacak. İçeriği yalnızca siz ve { $count } alıcı okuyabilirsiniz.
}
pgp-compose-encrypt-ready = İleti gönderilirken şifrelenip imzalanacak. Kullanılabilir anahtarı bulunan alıcıları ekleyin.
pgp-compose-missing = { $count ->
    [one] Bu alıcı için kullanılabilir anahtar yok: { $addresses }. İleti henüz şifrelenemez.
   *[other] { $count } alıcı için kullanılabilir anahtar yok: { $addresses }. İleti henüz şifrelenemez.
}
pgp-compose-looking = Anahtarlar aranıyor: { $addresses }...
pgp-compose-signed = İleti gönderilirken dijital olarak imzalanacak. Alıcılar imzayı ve içeriğin değiştirilip değiştirilmediğini kontrol edebilir.
pgp-compose-reply-clear = Özgün ileti şifreli olmasına rağmen şifreleme kapalı.
pgp-compose-encrypted-files = Bu ileti, şifreli bir iletiden alınan ekleri içeriyor ve yalnızca şifreli gönderilebilir. “Şifrele” seçeneğini açın veya bu ekleri kaldırın.
pgp-compose-sign-tip = Alıcıların imzayı ve içeriğin değiştirilip değiştirilmediğini kontrol edebilmesi için iletiyi gönderirken dijital olarak imzalayın
pgp-compose-sign-tip-encrypted = Şifreli iletiler gönderilirken her zaman imzalanır
pgp-compose-encrypt-tip = İletiyi gönderirken içeriği yalnızca sizin ve alıcıların okuyabileceği şekilde şifreleyin
pgp-compose-make-key = Henüz { $address } adresi için bir anahtar ayarlamadınız. Şimdi bir anahtar oluşturmak ister misiniz? Bu anahtarla iletilerinizi imzalayabilir ve şifreleyebilirsiniz.
pgp-compose-key-unusable = { $address } adresi için anahtarınız kullanılamıyor. Neden: { $state }
    Bu anahtarın yedeğini içe aktarmak veya yeni bir anahtar oluşturmak için “Şifreleme Anahtarları” penceresini açın.
pgp-compose-encrypt-off-quote = Bu iletide hâlâ şifreli bir iletiden alınan metin, resim veya ekler var. Şifrelemeden göndermek için bu içeriği kaldırın. Yine de şifrelemeyi kapatmak istiyor musunuz?
pgp-compose-encrypt-off-reply = Özgün ileti şifreliydi. Yanıtınızı veya ilettiğiniz kopyayı şifrelemeden gönderirseniz e-posta sunucuları içeriği okuyabilir. Şifrelemeyi kapatmak istiyor musunuz?
pgp-recipient-verified = Anahtar doğrulandı
pgp-recipient-found = Anahtar doğrulanmadı
pgp-recipient-own = Kendi anahtarınız
pgp-recipient-looking = Anahtar aranıyor...
pgp-recipient-missing = Anahtar yok
pgp-recipient-not-found = Anahtar bulunamadı. Son arama: { $date }
pgp-recipient-unusable = Anahtar kullanılamıyor: { $state }
pgp-recipients-intro = İleti, alıcıların anahtarları ve sizin anahtarınız kullanılarak şifrelenecek.
pgp-recipients-intro-missing = { $count ->
    [one] Bir alıcı için kullanılabilir anahtar yok. Anahtarı bulun veya alıcıyı iletiden kaldırın. İletide şifreli iletilerden alınan metin, resim veya ek varsa şifrelemeden gönderemezsiniz.
   *[other] { $count } alıcı için kullanılabilir anahtar yok. Anahtarlarını bulun veya bu alıcıları iletiden kaldırın. İletide şifreli iletilerden alınan metin, resim veya ek varsa şifrelemeden gönderemezsiniz.
}
pgp-details-part = Bölüm { $number }: { $label }
pgp-details-signed = İmzalandı: { $when }, anahtar: { $key }
pgp-details-unknown-key = Sizde olmayan bir anahtarla imzalandı: { $key }
pgp-details-opened = Şifreyi çözmek için kullanılan anahtarınız: { $key }
pgp-details-for = Şifrelendiği anahtarlar: { $keys }
pgp-details-plain = İmzalı değil ve şifreli değil
pgp-bar-parts = Bu iletinin { $count } bölümü var: { $list }. Her bölüm nasıl korunduğunu gösterir.
pgp-bar-count-verified = Doğrulanmış: { $count }
pgp-bar-count-good = { $count ->
    [one] 1 imzalı veya şifreli
   *[other] { $count } imzalı veya şifreli
}
pgp-bar-count-warning = { $count ->
    [one] 1 bölüm dikkat gerektiriyor
   *[other] { $count } bölüm dikkat gerektiriyor
}
pgp-bar-count-neutral = Denetlenmemiş: { $count }
# kurulum dosyası: başka bir bilgisayara taşınan ayarlar, hesaplar, kişiler ve anahtarlar
setup-part-settings = Ayarlar
setup-part-preferences = Pencere tercihleri
setup-part-accounts = Hesaplar
setup-part-sign-in-apps = Oturum açma uygulamaları
setup-part-contacts = Kişiler ve gruplar
setup-part-keys = Şifreleme anahtarları
setup-part-rules = İleti kuralları
setup-part-trusted-senders = Güvenilen gönderenler
setup-holds-settings = { $count ->
    [one] 1 ayar
   *[other] { $count } ayar
}
setup-holds-preferences = { $count ->
    [one] 1 tercih
   *[other] { $count } tercih
}
setup-holds-accounts = { $count ->
    [one] 1 hesap
   *[other] { $count } hesap
}
setup-holds-sign-in-apps = { $count ->
    [one] 1 oturum açma uygulaması
   *[other] { $count } oturum açma uygulaması
}
setup-holds-built-in = Etkin olan yerleşik oturum açma uygulamaları
setup-holds-contacts = { $count ->
    [one] 1 kişi
   *[other] { $count } kişi
}
setup-holds-groups = { $count ->
    [one] 1 grup
   *[other] { $count } grup
}
setup-holds-own-keys = { $count ->
    [one] Size ait 1 anahtar
   *[other] Size ait { $count } anahtar
}
setup-holds-contact-keys = { $count ->
    [one] Bir kişiye ait 1 anahtar
   *[other] Kişilere ait { $count } anahtar
}
setup-holds-rules = { $count ->
    [one] 1 kural
   *[other] { $count } kural
}
setup-holds-trusted-senders = { $count ->
    [one] 1 güvenilen gönderen
   *[other] { $count } güvenilen gönderen
}
setup-sign-in-password = Parola
setup-account-secret-password = Parolası dosyada.
setup-account-secret-token = Oturum açma bilgisi dosyada.
setup-account-asks-password = İçe aktardıktan sonra hesap parolası istenir.
setup-account-signs-in-again = İçe aktardıktan sonra yeniden oturum açmanız gerekir.
setup-account-here = Bu bilgisayarda zaten var; değişiklik yapılmadan atlanır.
setup-account-no-app = Bu bilgisayarda bulunmayan bir oturum açma uygulaması kullanıyor: { $app }. Oturum açma uygulamalarını da içe aktarın.
setup-invalid-address = “{ $address }” bir e-posta adresi değil.
setup-invalid-server = { $server } sunucusunun kullanılabilir bir adı veya bağlantı noktası yok.
setup-invalid-user = Kullanıcı adı yok.
setup-invalid-sign-in = Bu sürümün desteklemediği bir oturum açma yöntemi kullanılıyor.
setup-error-empty = Dosya boş.
setup-error-too-large = Dosya boyutu, ayar ve hesap içe aktarma sınırını aşıyor.
setup-error-not-setup = Bu dosya, Inbox Classic ayar ve hesap dosyası değil.
setup-error-damaged = Ayar ve hesap dosyası hasarlı olduğu için okunamıyor.
setup-error-newer = Bu dosya daha yeni bir Inbox Classic sürümüyle kaydedilmiş ({ $version }). Inbox Classic'i güncelleyip yeniden içe aktarın.
setup-error-needs-passphrase = Bu dosya bir anahtar parolasıyla korunuyor. Dosya kaydedilirken kullanılan parolayı girin.
setup-error-wrong-passphrase = Girilen anahtar parolası bu dosyanın parolasıyla eşleşmiyor.
setup-error-changed = Ayar ve hesap dosyası kaydedildikten sonra değiştirilmiş veya hasar görmüş. İçe aktarılamıyor.
setup-error-read = Ayar ve hesap dosyası okunamadı: { $error }
setup-error-write = Ayar ve hesap dosyası kaydedilemedi: { $error }
setup-error-no-parts = En az bir bölüm seçin.
setup-left-out = { $count ->
    [one] { $part } bölümünün 1 girdisi kullanılamıyor ve dışarıda bırakıldı.
   *[other] { $part } bölümünün { $count } girdisi kullanılamıyor ve dışarıda bırakıldı.
}
setup-imported-settings = Ayarlar değiştirildi.
setup-imported-preferences = Pencere tercihleri değiştirildi.
setup-added-accounts = { $count ->
    [one] 1 hesap eklendi.
   *[other] { $count } hesap eklendi.
}
setup-skipped-here = Burada zaten kurulu olduğu için atlandı: { $address }
setup-skipped-no-app = Atlandı: { $address }. Burada kurulu olmayan bir uygulamayla oturum açıyor: { $app }
setup-skipped-invalid = Atlandı: { $address }. Neden: { $reason }
setup-asks-password = Bağlandığında parolasını soracak: { $address }
setup-signs-in-again = Bağlandığında yeniden oturum açmanızı isteyecek: { $address }
setup-added-sign-in-apps = { $count ->
    [one] 1 oturum açma uygulaması eklendi.
   *[other] { $count } oturum açma uygulaması eklendi.
}
setup-skipped-sign-in-apps = { $count ->
    [one] 1 oturum açma uygulaması burada zaten kurulu.
   *[other] { $count } oturum açma uygulaması burada zaten kurulu.
}
setup-added-contacts = { $count ->
    [one] Adres defterine 1 kişi eklendi.
   *[other] Adres defterine { $count } kişi eklendi.
}
setup-skipped-contacts = { $count ->
    [one] 1 kişi zaten adres defterinde.
   *[other] { $count } kişi zaten adres defterinde.
}
setup-added-groups = { $count ->
    [one] 1 grup eklendi veya yeni üyelerle güncellendi.
   *[other] { $count } grup eklendi veya yeni üyelerle güncellendi.
}
setup-added-own-keys = { $count ->
    [one] Size ait 1 anahtar eklendi.
   *[other] Size ait { $count } anahtar eklendi.
}
setup-added-contact-keys = { $count ->
    [one] Bir kişiye ait 1 anahtar eklendi.
   *[other] Kişilere ait { $count } anahtar eklendi.
}
setup-added-rules = { $count ->
    [one] 1 ileti kuralı eklendi.
   *[other] { $count } ileti kuralı eklendi.
}
setup-skipped-rules = { $count ->
    [one] 1 ileti kuralı burada zaten var.
   *[other] { $count } ileti kuralı burada zaten var.
}
setup-skipped-rules-account = { $count ->
    [one] 1 ileti kuralı burada olmayan bir hesaba ait, bu yüzden atlandı.
   *[other] { $count } ileti kuralı burada olmayan hesaplara ait, bu yüzden atlandı.
}
setup-rules-waiting = { $count ->
    [one] 1 kuralın hedef klasörü henüz bulunamadı. Hesap eşitlendiğinde klasör kuralla eşleştirilecek.
   *[other] { $count } kuralın hedef klasörleri henüz bulunamadı. Hesaplar eşitlendiğinde klasörler kurallarla eşleştirilecek.
}
setup-added-trusted-senders = { $count ->
    [one] 1 güvenilen gönderen eklendi.
   *[other] { $count } güvenilen gönderen eklendi.
}
setup-nothing = Hiçbir şey içe aktarılmadı.
setup-account-servers = { $imap } ve { $smtp } ({ $signin })
setup-file-name = Inbox Classic ayarları ve hesapları
setup-skipped-unreachable = Atlandı: { $name }. Oturum açma hizmetine ulaşılamadı. Oturum Açma Uygulamaları'nda yeniden ekleyin.
attachment-runs-programs = “{ $name }” kod çalıştırabilen bir dosya türünde olduğu için Inbox Classic tarafından doğrudan açılmaz. Kaynağına güveniyorsanız dosyayı kaydedip kendiniz açabilirsiniz.
attachment-decrypted-note = Bu ek, şifreli bir iletiden geliyor. Açabilmeniz için bu bilgisayarda, kullanıcı hesabınıza ait bir klasöre şifresi çözülmüş geçici bir kopyası kaydedilir. Dosyayı açan programı kapatmanız kopyayı silmez. 24 saatten eski kopyalar Inbox Classic'in bir sonraki açılışında temizlenir.
# a bar over the list when the server did not do what the user asked of messages, so they are as they were again
undone-move = { $count ->
    [one] Sunucuda { $messages } { $folder } klasörüne taşınamadı; ileti yeniden { $from } klasöründe: { $reason }
   *[other] Sunucuda { $messages } { $folder } klasörüne taşınamadı; iletiler yeniden { $from } klasöründe: { $reason }
}
undone-delete = { $count ->
    [one] Sunucuda { $messages } silinemedi; ileti yeniden { $from } klasöründe: { $reason }
   *[other] Sunucuda { $messages } silinemedi; iletiler yeniden { $from } klasöründe: { $reason }
}
undone-archive = { $count ->
    [one] Sunucuda { $messages } arşivlenemedi; ileti yeniden { $from } klasöründe: { $reason }
   *[other] Sunucuda { $messages } arşivlenemedi; iletiler yeniden { $from } klasöründe: { $reason }
}
undone-read = { $count ->
    [one] Sunucuda { $messages } okundu olarak işaretlenemedi; ileti yeniden okunmamış durumda: { $reason }
   *[other] Sunucuda { $messages } okundu olarak işaretlenemedi; iletiler yeniden okunmamış durumda: { $reason }
}
undone-unread = { $count ->
    [one] Sunucuda { $messages } okunmadı olarak işaretlenemedi; ileti yeniden okunmuş durumda: { $reason }
   *[other] Sunucuda { $messages } okunmadı olarak işaretlenemedi; iletiler yeniden okunmuş durumda: { $reason }
}
undone-flags = { $count ->
    [one] Sunucuda bayrak değişikliği uygulanamadı ({ $messages }); değişiklik geri alındı: { $reason }
   *[other] Sunucuda bayrak değişikliği uygulanamadı ({ $messages }); değişiklik geri alındı: { $reason }
}

## Previews of attachments: the pictures and PDF files shown in a message

# review: new
preview-pdf-option = İletilerde PDF dosyalarını göster
# review: new
preview-pdf-off = PDF dosyaları iletilerde gösterilmiyor.
# review: new
preview-pdf-off-crashed = Bir PDF dosyası gösterilirken Inbox Classic'i kapattı, bu yüzden PDF dosyaları artık iletilerde gösterilmiyor. Resimler hâlâ gösteriliyor. PDF dosyalarını yeniden göstermek için { $settings } altında { $option } seçeneğini açın.
# review: new
preview-pdf-details = { $count ->
    [one] { $count } sayfa, { $size }
   *[other] { $count } sayfa, { $size }
}
# review: new
preview-page-alt = { $name }, sayfa { $page }/{ $count }
# review: new
preview-more-pages = { $count ->
    [one] Sayfayı görmek için dosyayı açın
   *[other] { $count } sayfanın tümünü görmek için dosyayı açın
}
# review: new
preview-more-files = { $count ->
    [one] 1 dosya daha yukarıdaki listede
   *[other] { $count } dosya daha yukarıdaki listede
}
# review: new
preview-tile-downloading = İndiriliyor…
# review: new
preview-tile-format = { $format } resimleri henüz gösterilmiyor
# review: new
preview-tile-password = Parolayla korunuyor: parolayı girmek için açın
# review: new
preview-tile-too-large = Gösterilemeyecek kadar büyük
# review: new
preview-tile-unreadable = Gösterilemiyor
# review: new
preview-tile-timed-out = Gösterilmesi çok uzun sürdü
# review: new
preview-tile-crashed = Gösterilmiyor: Inbox Classic'i bir kez kapattı
# review: new
preview-tile-off = Inbox Classic yeniden başlayana kadar gösterilmiyor
# review: new
preview-not-printed = { $name } ({ $details }) yazdırılmaz. Yazdırmak için açın.
