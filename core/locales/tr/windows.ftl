# Windows uygulamasının kendi pencerelerinin sözcükleri (app/src), win- ile başlayan kimlikler. { $braces } içindeki
# yer tutucuları uygulama doldurur; & bir menü veya düğme harfini gösterir (&& bir ve işaretidir).

## Ana pencere

# review: new
win-still-running-detail = Inbox Classic arka planda yeni postayı denetlemeye devam eder. Açmak için simgeye tıklayın. Çıkmak için simgeye sağ tıklayıp menüsünü kullanın.
# review: new
win-default-app-not-installed = Inbox Classic'in bu kopyası yüklenmediği için Windows onu posta uygulaması olarak listelemiyor. Seçebilmek için yükleyin.
# review: new
win-default-app-settings = Windows, Varsayılan uygulamalar ayarlarını açacak. MAILTO bağlantılarını açmak için Inbox Classic'i seçin.
# review: new
win-no-unread = Okunmamış ileti yok
# review: new
win-unread-messages = { $count ->
    [one] 1 okunmamış ileti
   *[other] { $count } okunmamış ileti
}
# review: new
win-print-failed = İleti yazdırılamadı.
# review: new
win-print-title-of = Yazdır - { $subject }
# review: new
win-no-bodies = İleti gövdeleri gösterilemiyor.
# review: new
win-webview-failed = WebView2 oluşturulamadı.
# review: new
win-webview-missing = WebView2 çalışma zamanı kullanılamıyor.

## Birçok pencerede kullanılan düğmeler ve sözcükler

# review: new
win-delete-button = &Sil
# review: new
win-find-label = &Bul:
# review: new
win-save-as-button = &Farklı Kaydet...
# review: new
win-too-many-files = Aynı anda çok fazla dosya: daha az dosya seçin.

## Giden Kutusu


## İleti yazma penceresi

# review: new
win-editor-failed = İleti yazılamıyor.
# review: new
win-ctrl-click-to-open = (açmak için { $ctrl }+tıklama)
# review: new
win-format-bold = Kalın ({ $ctrl }+B)
# review: new
win-format-italic = İtalik ({ $ctrl }+I)
# review: new
win-format-underline = Altı Çizili ({ $ctrl }+U)
# review: new
win-format-link = Köprü ({ $ctrl }+K)
# review: new
win-show-cc = &Bilgi
# review: new
win-show-bcc = &Gizli
# review: new
win-signature-title = İmza: { $account }

## Klasörler, ileti listesi ve okuma bölmesi

# review: new
win-search-found-all = { $count ->
    [0] Tüm klasörlerde “{ $words }” için sonuç yok
    [one] Tüm klasörlerde “{ $words }” için { $count } sonuç
   *[other] Tüm klasörlerde “{ $words }” için { $count } sonuç
}
# review: new
win-search-found-in = { $count ->
    [0] “{ $words }” için sonuç yok. Klasör: { $folder }
    [one] “{ $words }” için { $count } sonuç. Klasör: { $folder }
   *[other] “{ $words }” için { $count } sonuç. Klasör: { $folder }
}
# review: new
win-search-indexing = { $count ->
    [one] { $count } iletinin metni hâlâ dizinleniyor
   *[other] { $count } iletinin metni hâlâ dizinleniyor
}
# review: new
win-no-match-indexing = { $count ->
    [one] { $count } iletinin metni hâlâ dizinleniyor, bu nedenle yakında daha fazlası bulunabilir.
   *[other] { $count } iletinin metni hâlâ dizinleniyor, bu nedenle yakında daha fazlası bulunabilir.
}
# review: new
win-files = { $count ->
    [one] { $count } dosya
   *[other] { $count } dosya
}
# review: new
win-click-to-retry = Yeniden denemek için buraya tıklayın.
# review: new
win-save-attachments = Ekleri &Kaydet...
# review: new
win-files-not-saved = { $count } dosyadan { $failed } tanesi kaydedilemedi.
# review: new
win-new-folder-in-highlighted = Yeni klasör, seçili klasörün içinde oluşturulacak.
# review: new
win-delete-folder-ask = “{ $folder }” klasörü, iletileri ve içindeki klasörlerle birlikte silinsin mi? Sunucuda da silinir.
# review: new
win-rename = Yeniden &Adlandır...
# review: new
win-messages-not-saved = İletiler kaydedilemedi.
# review: new
win-messages-not-forwarded = İletiler iletilemedi.

## Hesaplar

# review: new
win-sign-in-google = Google ile oturum açın
# review: new
win-sign-in-microsoft = Microsoft ile oturum açın
# review: new
win-next = &İleri >
# review: new
win-your-account = hesabınız
# review: new
win-browser-sign-in = (tarayıcıda oturum açma)
# review: new
win-add = &Ekle...
# review: new
win-properties-button = Ö&zellikler...
# review: new
win-signature-button = İ&mza...
# review: new
win-sign-in-apps-button = &Oturum Açma Uygulamaları...

## Yapay zeka aracıları

# review: new
win-dont-allow = İzin &Verme
# review: new
win-col-address = Adres
# review: new
win-never-written-to = Hiç yazılmadı
# review: new
win-book-find-label = Bir ad veya e-posta adresi yazın:
# review: new
win-send = &Gönder
# review: new
win-dont-send = Gö&nderme
# review: new
win-forget-program-ask = Bu program, izinleri ve aracılarının etkinlik geçmişi kaldırılsın mı? Bir sonraki bağlantısında yeniden izin istenecek.
# review: new
win-clear-log-ask = Aracıların etkinlik geçmişi temizlensin mi? Bu, aracıların yaptığı değişiklikleri geri almaz.
win-agent-programs = Postanıza erişim isteyen aracıların &programları:
# review: new
win-change = &Değiştir...
# review: new
win-what-agents-did = Aracı &etkinliği:
# review: new
win-how-to-connect = Aracı nasıl bağlanır

## Oturum açma uygulamaları

# review: new
win-built-in = (yerleşik)
# review: new
win-edit = &Düzenle...

## Seçenekler

# review: new
win-options-language-label = Inbox Classic'in &dili:
# review: new
win-options-restart-note = Dili değiştirmek için Inbox Classic'i yeniden başlatın.
# review: new
win-options-notify = Yeni posta geldiğinde &bildir
# review: new
win-restart-ask = Inbox Classic yeniden başladığında dil şu olacak: { $language }. Şimdi yeniden başlatılsın mı?
# review: new
win-folders-hide = Klasör listesini gizle
# review: new
win-folders-pin = Klasör listesini iletilerin yanında tut
# review: new
win-folders-show = Klasörleri göster

## Yükleyici

# yükleyicinin kendi sözcükleri (installer/inbox-classic.nsi), derleme bunları installer/languages.nsh dosyasına dönüştürür;
# { $version } ve { $installed } sürüm numaralarıdır, 0.18.0
# review: new
win-installer-start = Inbox Classic'i Başlat
# review: new
win-installer-welcome-new =
    Bu işlem bir e-posta programı olan Inbox Classic { $version } sürümünü yükleyecek.

    Yönetici hakları gerekmez, yalnızca sizin hesabınız için yüklenir.
# review: new
win-installer-welcome-same =
    Inbox Classic { $version } zaten yüklü. Bu işlem onu yeniden yükleyecek.

    Hesaplarınız ve postanız korunur.
# review: new
win-installer-welcome-update =
    Bu işlem Inbox Classic { $installed } sürümünü { $version } sürümüne güncelleyecek.

    Çalışıyorsa önce kapatılır. Hesaplarınız ve postanız korunur.
# review: new
win-installer-older-ask = Inbox Classic { $installed } yüklü ve bu sürüm { $version } sürümünden daha yeni. Eski sürüm yine de yüklensin mi?
# review: new
win-installer-still-running = Inbox Classic hâlâ çalışıyor. Kapatıp yeniden deneyin.
# review: new
win-installer-remove-mail-ask = Inbox Classic'in bu bilgisayarda tuttuğu hesaplar ve posta da kaldırılsın mı? Sunuculardaki posta kalır.
