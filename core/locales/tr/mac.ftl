# Mac uygulamasının kendi pencerelerinin sözcükleri (mac/Sources), mac- ile başlayan kimlikler; menüler ve her platformun
# paylaştığı sözcükler app.ftl ve core.ftl dosyalarındadır. { $braces } içindeki yer tutucuları uygulama doldurur. Mac
# kuralları: daha fazlasını soran bir komuttan sonra üç nokta (…), menülerde ve düğmelerde Başlık Biçimi, kıvrık tırnaklar
# ve kesme işaretleri.

## Uygulama ve menüleri

mac-quit = Inbox Classic'ten Çık
mac-settings = Ayarlar…
mac-services = Servisler
mac-hide = Inbox Classic'i Gizle
mac-hide-others = Diğerlerini Gizle
mac-show-all = Tümünü Göster
mac-check-updates = Güncellemeleri Denetle…
mac-close-window = Pencereyi Kapat
mac-redo = Yinele
mac-cut = Kes
mac-paste = Yapıştır
mac-menu-window = Pencere
mac-minimize = Simge Durumuna Küçült
mac-zoom = Büyüt/Küçült
mac-no-updates = Inbox Classic'in bu sürümü otomatik güncellemeleri desteklemiyor. En son sürümü inboxclassic.com adresinden indirin.

## Ayarlar

mac-settings-title = Ayarlar
mac-language-label = Dil:
mac-restart-hint = Dili değiştirmek için Inbox Classic'i yeniden başlatın.
mac-notify-new-mail = Yeni posta geldiğinde bildir
mac-restart-question = Dili değiştirmek için Inbox Classic şimdi yeniden başlatılsın mı?

## Sorular

mac-choose = Seç

## Ana pencere

mac-still-running-detail = Inbox Classic arka planda yeni postayı denetlemeye devam eder. Uygulamayı açmak için Dock'taki simgesine tıklayın.
mac-outbox-waiting =
    { $count ->
        [one] Giden Kutusu'nda { $count } ileti
       *[other] Giden Kutusu'nda { $count } ileti
    }
mac-sending = Gönderiliyor: { $subject }…
mac-checking = Yeni iletiler denetleniyor: { $account }…
mac-account-said = { $account }: { $message }
mac-not-bundle = Inbox Classic'in bu kopyası bir uygulama paketi değil, bu nedenle varsayılan posta uygulaması olamaz.
mac-not-made-default = Inbox Classic varsayılan posta uygulaması yapılamadı: { $reason }
mac-tool-search = Ara

## Klasörler ve ileti listesi

mac-still-indexing-more =
    { $count ->
        [one] { $count } iletinin metni hâlâ dizinleniyor. Dizinleme tamamlandığında daha fazla sonuç bulunabilir.
       *[other] { $count } iletinin metni hâlâ dizinleniyor. Dizinleme tamamlandığında daha fazla sonuç bulunabilir.
    }
mac-results-everywhere =
    { $count ->
        [0] Tüm klasörlerde “{ $words }” için sonuç yok
        [one] Tüm klasörlerde “{ $words }” için { $count } sonuç
       *[other] Tüm klasörlerde “{ $words }” için { $count } sonuç
    }
mac-results-in =
    { $count ->
        [0] “{ $words }” için sonuç yok. Klasör: { $folder }
        [one] “{ $words }” için { $count } sonuç. Klasör: { $folder }
       *[other] “{ $words }” için { $count } sonuç. Klasör: { $folder }
    }
mac-still-indexing =
    { $count ->
        [one] { $count } iletinin metni hâlâ dizinleniyor
       *[other] { $count } iletinin metni hâlâ dizinleniyor
    }
mac-folder-unread = { $folder }, { $count } okunmamış
mac-import-messages = İletileri İçe Aktar
mac-save-messages = İletileri Kaydet
mac-save-attachments-menu = Ekleri Kaydet…
mac-files-not-saved =
    { $count ->
       *[other] { $count } dosyadan { $failed } tanesi kaydedilemedi.
    }
mac-no-calendar-app = Bu Mac'te davetleri (.ics dosyaları) açacak bir takvim uygulaması yok.
mac-file-not-saved = Dosya kaydedilemedi.
mac-unsubscribing = Abonelikten çıkılıyor: { $target }…
mac-loading-list = Yükleniyor…

## İleti yazma penceresi

mac-bold = Kalın
mac-italic = İtalik
mac-underline = Altı Çizili
mac-bcc = Gizli
mac-command-click-to-open = Açmak için ⌘ tuşunu basılı tutarak tıklayın
mac-saving-to-drafts = Taslaklar'a kaydediliyor…
mac-dont-save = Kaydetme

## Okuma bölmesi

mac-files =
    { $count ->
        [one] { $count } dosya
       *[other] { $count } dosya
    }

## Hesaplar

mac-next = İleri
mac-name-placeholder = Ayşe Yılmaz
mac-more-sign-in-options = Diğer oturum açma seçenekleri…
mac-add-sign-in-app = Oturum açma uygulaması ekle…
mac-looking-up = Ayarlar aranıyor: { $domain }…
mac-add-button = Ekle…
mac-properties-button = Özellikler…
mac-signature-button = İmza…
mac-security-button = Güvenlik…
mac-sign-in-apps-button = Oturum Açma Uygulamaları…

## Yapay zeka aracıları

mac-forget-program = Bu programın kayıtlı izinleri ve aracı etkinlik geçmişi silinsin mi?
mac-forget-program-detail = Programın izinleri silinecek. Bir sonraki bağlantısında yeniden izin istenecek.

## Oturum açma uygulamaları

mac-checking-issuer = Denetleniyor: { $issuer }…
mac-edit-button = Düzenle…
mac-use-for-new-accounts = { $name } yeni hesaplar için kullanılsın
mac-built-in = { $name } (yerleşik)

## Diğer pencereler

mac-new-folder-button = Yeni Klasör…
mac-edit-link = Bağlantıyı Düzenle…
