# Windows uygulamasının kendi pencerelerinin sözcükleri (app/src), win- ile başlayan kimlikler. { $braces } içindeki
# yer tutucuları uygulama doldurur; & bir menü veya düğme harfini gösterir (&& bir ve işaretidir).

## Ana pencere

win-still-running-detail = Inbox Classic arka planda yeni postayı denetlemeye devam eder. Açmak için simgeye tıklayın. Çıkmak için simgeye sağ tıklayıp menüsünü kullanın.
win-default-app-not-installed = Inbox Classic'in bu kopyası kurulu olmadığı için Windows uygulamayı posta programları arasında göstermiyor. Seçebilmek için önce yükleyin.
win-default-app-settings = Windows, Varsayılan uygulamalar ayarlarını açacak. MAILTO bağlantılarını açmak için Inbox Classic'i seçin.
win-no-unread = Okunmamış ileti yok
win-unread-messages = { $count ->
    [one] 1 okunmamış ileti
   *[other] { $count } okunmamış ileti
}
win-print-failed = İleti yazdırılamadı.
win-print-title-of = Yazdır - { $subject }
win-no-bodies = İleti içerikleri gösterilemiyor.
win-webview-failed = WebView2 başlatılamadı.
win-webview-missing = WebView2 çalışma zamanı kullanılamıyor.
# review: new
win-list-loading = Yükleniyor...

## Birçok pencerede kullanılan düğmeler ve sözcükler

win-delete-button = &Sil
win-find-label = &Bul:
win-save-as-button = &Farklı Kaydet...
win-too-many-files = Çok fazla dosya seçildi. Daha az dosya seçip yeniden deneyin.

## Giden Kutusu


## İleti yazma penceresi

win-editor-failed = İleti düzenleyicisi açılamadı.
win-ctrl-click-to-open = (açmak için { $ctrl } tuşunu basılı tutarak tıklayın)
win-format-bold = Kalın ({ $ctrl }+B)
win-format-italic = İtalik ({ $ctrl }+I)
win-format-underline = Altı Çizili ({ $ctrl }+U)
win-format-link = Köprü ({ $ctrl }+K)
win-show-cc = &Bilgi
win-show-bcc = &Gizli
win-signature-title = İmza: { $account }

## Klasörler, ileti listesi ve okuma bölmesi

win-search-found-all = { $count ->
    [0] Tüm klasörlerde “{ $words }” için sonuç yok
    [one] Tüm klasörlerde “{ $words }” için { $count } sonuç
   *[other] Tüm klasörlerde “{ $words }” için { $count } sonuç
}
win-search-found-in = { $count ->
    [0] “{ $words }” için sonuç yok. Klasör: { $folder }
    [one] “{ $words }” için { $count } sonuç. Klasör: { $folder }
   *[other] “{ $words }” için { $count } sonuç. Klasör: { $folder }
}
win-search-indexing = { $count ->
    [one] { $count } iletinin metni hâlâ dizinleniyor
   *[other] { $count } iletinin metni hâlâ dizinleniyor
}
win-no-match-indexing = { $count ->
    [one] { $count } iletinin metni hâlâ dizinleniyor. Dizinleme tamamlandığında daha fazla sonuç bulunabilir.
   *[other] { $count } iletinin metni hâlâ dizinleniyor. Dizinleme tamamlandığında daha fazla sonuç bulunabilir.
}
win-files = { $count ->
    [one] { $count } dosya
   *[other] { $count } dosya
}
win-click-to-retry = Yeniden denemek için buraya tıklayın.
win-save-attachments = Ekleri &Kaydet...
win-files-not-saved = { $count } dosyadan { $failed } tanesi kaydedilemedi.
win-new-folder-in-highlighted = Yeni klasör, seçili klasörün içinde oluşturulacak.
win-delete-folder-ask = “{ $folder }” klasörü, iletileri ve içindeki klasörlerle birlikte silinsin mi? Sunucuda da silinir.
win-rename = Yeniden &Adlandır...
win-messages-not-saved = İletiler kaydedilemedi.
win-messages-not-forwarded = İletiler iletilemedi.

## Hesaplar

win-sign-in-google = Google ile oturum açın
win-sign-in-microsoft = Microsoft ile oturum açın
win-next = İ&leri >
win-your-account = hesabınız
win-browser-sign-in = (tarayıcıda oturum açma)
win-add = &Ekle...
win-properties-button = Ö&zellikler...
win-signature-button = İ&mza...
win-sign-in-apps-button = &Oturum Açma Uygulamaları...

## Yapay zeka aracıları

win-dont-allow = İzin &Verme
win-col-address = Adres
win-never-written-to = Hiç yazılmadı
win-book-find-label = Bir ad veya e-posta adresi yazın:
win-send = &Gönder
win-dont-send = Gö&nderme
win-forget-program-ask = Bu program, izinleri ve aracılarının etkinlik geçmişi kaldırılsın mı? Bir sonraki bağlantısında yeniden izin istenecek.
win-clear-log-ask = Aracıların etkinlik geçmişi temizlensin mi? Bu, aracıların yaptığı değişiklikleri geri almaz.
win-agent-programs = Postanıza erişim isteyen aracıların &programları:
win-change = &Değiştir...
win-what-agents-did = Aracı &etkinliği:
win-how-to-connect = Aracı Nasıl Bağlanır

## Oturum açma uygulamaları

win-built-in = (yerleşik)
win-edit = &Düzenle...

## Seçenekler

win-options-language-label = Inbox Classic'in &dili:
win-options-restart-note = Dili değiştirmek için Inbox Classic'i yeniden başlatın.
win-options-notify = Yeni posta geldiğinde &bildir
win-restart-ask = Yeniden başlattığınızda Inbox Classic şu dili kullanacak: { $language }. Şimdi yeniden başlatılsın mı?
win-folders-hide = Klasör listesini gizle
win-folders-pin = Klasör listesini iletilerin yanında tut
win-folders-show = Klasörleri göster

## Yükleyici

# yükleyicinin kendi sözcükleri (installer/inbox-classic.nsi), derleme bunları installer/languages.nsh dosyasına dönüştürür;
# { $version } ve { $installed } sürüm numaralarıdır, 0.18.0
win-installer-start = Inbox Classic'i Başlat
win-installer-welcome-new =
    Inbox Classic e-posta uygulamasının { $version } sürümü yüklenecek.

    Yönetici izni gerekmez. Uygulama yalnızca mevcut Windows kullanıcı hesabınız için yüklenir.
win-installer-welcome-same =
    Inbox Classic { $version } zaten yüklü. Aynı sürüm yeniden yüklenecek.

    Hesaplarınız ve postanız korunur.
win-installer-welcome-update =
    Inbox Classic, { $installed } sürümünden { $version } sürümüne güncellenecek.

    Uygulama çalışıyorsa önce kapatılır. Hesaplarınız ve postanız korunur.
win-installer-older-ask = Inbox Classic { $installed } yüklü ve bu sürüm { $version } sürümünden daha yeni. Eski sürüm yine de yüklensin mi?
win-installer-still-running = Inbox Classic hâlâ çalışıyor. Kapatıp yeniden deneyin.
win-installer-remove-mail-ask = Inbox Classic'in bu bilgisayarda sakladığı hesap bilgileri ve ileti kopyaları da silinsin mi? Sunuculardaki postanız korunur.
