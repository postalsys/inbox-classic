# Mac uygulamasının kendi pencerelerinin sözcükleri (mac/Sources), mac- ile başlayan kimlikler; menüler ve her platformun
# paylaştığı sözcükler app.ftl ve core.ftl dosyalarındadır. { $braces } içindeki yer tutucuları uygulama doldurur. Mac
# kuralları: daha fazlasını soran bir komuttan sonra üç nokta (…), menülerde ve düğmelerde Başlık Biçimi, kıvrık tırnaklar
# ve kesme işaretleri.

## Uygulama ve menüleri

# review: new
mac-quit = Inbox Classic'ten Çık
# review: new
mac-settings = Ayarlar…
# review: new
mac-services = Servisler
# review: new
mac-hide = Inbox Classic'i Gizle
# review: new
mac-hide-others = Diğerlerini Gizle
# review: new
mac-show-all = Tümünü Göster
# review: new
mac-check-updates = Güncellemeleri Denetle…
# review: new
mac-close-window = Pencereyi Kapat
# review: new
mac-redo = Yinele
# review: new
mac-cut = Kes
# review: new
mac-paste = Yapıştır
# review: new
mac-menu-window = Pencere
# review: new
mac-minimize = Simge Durumuna Küçült
# review: new
mac-zoom = Büyüt/Küçült
# review: new
mac-no-updates = Inbox Classic'in bu sürümü otomatik güncellemeleri desteklemiyor. En son sürümü inboxclassic.com adresinden indirin.

## Ayarlar

# review: new
mac-settings-title = Ayarlar
# review: new
mac-language-label = Dil:
# review: new
mac-restart-hint = Dili değiştirmek için Inbox Classic'i yeniden başlatın.
# review: new
mac-notify-new-mail = Yeni posta geldiğinde bildir
# review: new
mac-restart-question = Dili değiştirmek için Inbox Classic şimdi yeniden başlatılsın mı?

## Sorular

# review: new
mac-choose = Seç

## Ana pencere

# review: new
mac-still-running-detail = Inbox Classic arka planda yeni postayı denetlemeye devam eder. Uygulamayı açmak için Dock'taki simgesine tıklayın.
# review: new
mac-outbox-waiting =
    { $count ->
        [one] Giden Kutusu'nda { $count } ileti
       *[other] Giden Kutusu'nda { $count } ileti
    }
# review: new
mac-sending = Gönderiliyor: { $subject }…
# review: new
mac-checking = Yeni iletiler denetleniyor: { $account }…
# review: new
mac-account-said = { $account }: { $message }
# review: new
mac-not-bundle = Inbox Classic'in bu kopyası bir uygulama paketi değil, bu nedenle varsayılan posta uygulaması olamaz.
# review: new
mac-not-made-default = Inbox Classic varsayılan posta uygulaması yapılmadı: { $reason }
# review: new
mac-tool-search = Ara

## Klasörler ve ileti listesi

# review: new
mac-still-indexing-more =
    { $count ->
        [one] { $count } iletinin metni hâlâ dizinleniyor, bu nedenle yakında daha fazlası bulunabilir.
       *[other] { $count } iletinin metni hâlâ dizinleniyor, bu nedenle yakında daha fazlası bulunabilir.
    }
# review: new
mac-results-everywhere =
    { $count ->
        [0] Tüm klasörlerde “{ $words }” için sonuç yok
        [one] Tüm klasörlerde “{ $words }” için { $count } sonuç
       *[other] Tüm klasörlerde “{ $words }” için { $count } sonuç
    }
# review: new
mac-results-in =
    { $count ->
        [0] “{ $words }” için sonuç yok. Klasör: { $folder }
        [one] “{ $words }” için { $count } sonuç. Klasör: { $folder }
       *[other] “{ $words }” için { $count } sonuç. Klasör: { $folder }
    }
# review: new
mac-still-indexing =
    { $count ->
        [one] { $count } iletinin metni hâlâ dizinleniyor
       *[other] { $count } iletinin metni hâlâ dizinleniyor
    }
# review: new
mac-folder-unread = { $folder }, { $count } okunmamış
# review: new
mac-import-messages = İletileri İçe Aktar
# review: new
mac-save-messages = İletileri Kaydet
# review: new
mac-save-attachments-menu = Ekleri Kaydet…
# review: new
mac-files-not-saved =
    { $count ->
       *[other] { $count } dosyadan { $failed } tanesi kaydedilemedi.
    }
# review: new
mac-no-calendar-app = Bu Mac'te davetleri (.ics dosyaları) açacak bir takvim uygulaması yok.
# review: new
mac-file-not-saved = Dosya kaydedilemedi.
# review: new
mac-unsubscribing = Abonelikten çıkılıyor: { $target }…
# review: new
mac-loading-list = Yükleniyor…

## İleti yazma penceresi

# review: new
mac-bold = Kalın
# review: new
mac-italic = İtalik
# review: new
mac-underline = Altı Çizili
# review: new
mac-bcc = Gizli
# review: new
mac-command-click-to-open = Açmak için ⌘-tıklama
# review: new
mac-saving-to-drafts = Taslaklar'a kaydediliyor…
# review: new
mac-dont-save = Kaydetme

## Okuma bölmesi

# review: new
mac-files =
    { $count ->
        [one] { $count } dosya
       *[other] { $count } dosya
    }

## Hesaplar

# review: new
mac-next = İleri
# review: new
mac-name-placeholder = Ayşe Yılmaz
# review: new
mac-more-sign-in-options = Diğer oturum açma seçenekleri…
# review: new
mac-add-sign-in-app = Oturum açma uygulaması ekle…
# review: new
mac-looking-up = Ayarlar aranıyor: { $domain }…
# review: new
mac-add-button = Ekle…
# review: new
mac-properties-button = Özellikler…
# review: new
mac-signature-button = İmza…
# review: new
mac-security-button = Güvenlik…
# review: new
mac-sign-in-apps-button = Oturum Açma Uygulamaları…

## Yapay zeka aracıları

# review: new
mac-forget-program = Bu program ve aracılarının etkinlik geçmişi kaldırılsın mı?
# review: new
mac-forget-program-detail = Programın izinleri silinecek. Bir sonraki bağlantısında yeniden izin istenecek.

## Oturum açma uygulamaları

# review: new
mac-checking-issuer = Denetleniyor: { $issuer }…
# review: new
mac-edit-button = Düzenle…
# review: new
mac-use-for-new-accounts = { $name } yeni hesaplar için kullanılsın
# review: new
mac-built-in = { $name } (yerleşik)

## Diğer pencereler

# review: new
mac-new-folder-button = Yeni Klasör…
# review: new
mac-edit-link = Bağlantıyı Düzenle…
