# Linux uygulamasının kendi pencerelerinin sözcükleri (linux/src), gtk- ile başlayan kimlikler. { $braces } içindeki yer
# tutucuları uygulama doldurur; _ bir düğmenin kısayol harfini gösterir. GNOME'un sözcükleri varsa onlar (Tercihler, Çık).

## Ana pencere

# review: new
gtk-search-looks-in = Arama, şu konumda konuları, gönderenleri, alıcıları, ek adlarını ve ileti metnini kapsar: { $place }. Yazımı denetleyin veya daha az sözcük deneyin.
# review: new
gtk-search-still-indexing = { $count ->
    [one] 1 iletinin metni hâlâ dizinleniyor. Yakında daha fazla sonuç görünebilir.
   *[other] { $count } iletinin metni hâlâ dizinleniyor. Yakında daha fazla sonuç görünebilir.
}
# review: new
gtk-search-results-everywhere = { $count ->
    [0] Sonuç yok
    [one] 1 sonuç
   *[other] { $count } sonuç
}: tüm klasörlerde “{ $words }”
# review: new
gtk-search-results-in = { $count ->
    [0] Sonuç yok
    [one] 1 sonuç
   *[other] { $count } sonuç
}: “{ $words }”, konum: { $place }
# review: new
gtk-search-indexing = { $count ->
    [one] 1 iletinin metni hâlâ dizinleniyor
   *[other] { $count } iletinin metni hâlâ dizinleniyor
}
# review: new
gtk-list-loading = Yükleniyor...
# review: new
gtk-menu-rename = Yeniden Adlandır...
# review: new
gtk-import-one-question = { $file } iletisi içe aktarılsın mı? Hedef: { $folder }
# review: new
gtk-files-not-saved = { $total } dosyadan { $failed } tanesi kaydedilemedi.
# review: new
gtk-unsubscribe-one-click =
    Bu posta listesinden ayrılınsın mı?

    Inbox Classic, şu adrese abonelikten çıkma isteği gönderecek: { $target }. Hiçbir web sayfası açılmayacak ve e-posta gönderilmeyecek.
# review: new
gtk-unsubscribe-mail =
    Bu posta listesinden ayrılınsın mı?

    Abonelikten çıkmak için şu adrese bir e-posta gönderin: { $target }. Inbox Classic iletiyi sizin için hazırlayacak. Onaylamak için iletiyi gönderin.
# review: new
gtk-unsubscribe-web =
    Bu posta listesinden ayrılınsın mı?

    Posta listesinin abonelikten çıkma sayfası tarayıcınızda açılacak ({ $target }).
# review: new
gtk-unsubscribe-failed = Abonelikten çıkılamadı: { $problem }
# review: new
gtk-toolbar-create-mail-menu = Belirli bir hesaptan ileti yaz
# review: new
gtk-toolbar-send-recv-menu = Belirli bir hesap için posta gönder ve al
# review: new
gtk-main-menu = Ana Menü
# review: new
gtk-folder-list = Klasör Listesi
# review: new
gtk-quit = Çık

## Taşı ve Kopyala penceresi

# review: new
gtk-new-folder-at-top-of = Yeni klasör şu hesabın en üst düzeyine eklenir: { $account }

## İleti listesi

## Yardım

## Bildirimler ve sistem tepsisi

# review: new
gtk-unread-messages = { $count ->
    [0] Okunmamış ileti yok
    [one] 1 okunmamış ileti
   *[other] { $count } okunmamış ileti
}

## İleti yazma penceresinin bağlantı menüsü

## Giden Kutusu

# review: new
gtk-outbox-empty = Gönderilmeyi bekleyen ileti yok.
# review: new
gtk-outbox-row = Kime: { $to }  ·  Sıraya alındı: { $queued }  ·  { $status }

## Uygulama

# review: new
gtk-still-running-detail = Inbox Classic arka planda yeni postayı denetlemeye devam eder. Uygulamayı açmak veya kapatmak için üst çubuktaki simgesini kullanın.
# review: new
gtk-sign-in-again-ask =
    Oturum açma reddedildi veya oturumun süresi doldu. Hesap: { $account }

    Tarayıcıda yeniden oturum açılsın mı?
# review: new
gtk-default-app-not-installed = Inbox Classic'in bu kopyası yüklenmediği için sistem onu posta uygulaması olarak listelemiyor. Seçebilmek için yükleyin.
# review: new
gtk-default-app-now = Inbox Classic artık varsayılan posta uygulamanız: e-posta bağlantıları burada yeni bir ileti açar.
# review: new
gtk-default-app-failed = Inbox Classic varsayılan posta uygulaması yapılamadı.

## Birçok pencerede kullanılan düğmeler ve sözcükler

## Okuma bölmesi

# review: new
gtk-reader-date = Tarih:
# review: new
gtk-reader-files = İleti ekleri
# review: new
gtk-files = { $count ->
    [one] { $count } dosya
   *[other] { $count } dosya
}
# review: new
gtk-pictures-blocked = Gönderenin bilgisayarınızı tanımasını önlemeye yardımcı olmak için bazı resimler engellendi.
# review: new
gtk-download-pictures = Resimleri İndir
# review: new
gtk-save-attachments-menu = Ekleri Kaydet...

## İleti yazma penceresi

# review: new
gtk-format-bold = Kalın (Ctrl+B)
# review: new
gtk-format-italic = İtalik (Ctrl+I)
# review: new
gtk-format-underline = Altı Çizili (Ctrl+U)
# review: new
gtk-format-hyperlink = Köprü (Ctrl+K)
# review: new
gtk-font = Yazı Tipi
# review: new
gtk-show-cc = _Bilgi
# review: new
gtk-show-bcc = _Gizli
# review: new
gtk-save-tip = Kaydet (Ctrl+S)
# review: new
gtk-link-status = { $link }    (açmak için Ctrl+tıklama)

## Hesaplar

# review: new
gtk-plain-warning =
    Şifreleme olmadan, ağ trafiğinizi ele geçiren herkes parolanızı ve iletilerinizi okuyabilir. Bu bağlantıyı yalnızca kendi bilgisayarınızdaki veya yerel ağınızdaki bir sunucuyla kullanın.

    Devam edilsin mi?
# review: new
gtk-account-name-title = Hesap adı
# review: new
gtk-display-name-title = Görünen ad
# review: new
gtk-turned-off-why = “{ $button }” seçeneği bu bilgisayarda devre dışı. { $reason }
# review: new
gtk-turned-off-why-long =
    “{ $button }” seçeneği bu bilgisayarda devre dışı.

    { $reason }
# review: new
gtk-next = İleri >
# review: new
gtk-provider-sign-in = { $provider } web sitesinde oturum açın. Hesap: { $address }. Parolanız Inbox Classic ile paylaşılmaz. Hesabınızın güvenlik ayarlarında oluşturulan bir uygulama parolasını da kullanabilirsiniz.
# review: new
gtk-provider-sign-in-apps = Oturum açma uygulamalarınızdan biriyle (Diğer oturum açma seçenekleri) { $provider } web sitesinde oturum açın. Hesap: { $address }. Hesabınızın güvenlik ayarlarında oluşturulan bir uygulama parolasını da kullanabilirsiniz.
# review: new
gtk-accounts-add = Ekle...
# review: new
gtk-accounts-properties = Özellikler...
# review: new
gtk-accounts-signature = İmza...
# review: new
gtk-accounts-sign-in-apps = Oturum Açma Uygulamaları...

## Oturum açma uygulamaları

# review: new
gtk-app-server = { $kind } sunucusu
# review: new
gtk-app-port = { $kind } bağlantı noktası
# review: new
gtk-app-security = { $kind } güvenliği
# review: new
gtk-issuer-found =
    Oturum açma sayfası: { $page }
    Belirteç uç noktası: { $endpoint }
# review: new
gtk-client-id = İstemci kimliği
# review: new
gtk-client-secret = İstemci gizli dizisi
# review: new
gtk-scopes = İzinler (scopes)
# review: new
gtk-redirect-uri = Yeniden yönlendirme URI'si
# review: new
gtk-issuer-usable =
    Yayımcı kullanılabilir.

    { $found }
# review: new
gtk-app-built-in = { $app } yerleşiktir. Yalnızca yeni hesaplar için sunulup sunulmayacağını değiştirebilirsiniz. { $reason }
# review: new
gtk-built-in = { $app } (yerleşik)
# review: new
gtk-offered-for-new = Yeni hesaplar için sunulur
# review: new
gtk-edit-button = Düzenle...
# review: new
gtk-remove-app-ask = { $app } oturum açma uygulaması ve kayıtlı istemci gizli dizisi kaldırılsın mı?
# review: new
gtk-sign-in-apps-intro = Oturum açma uygulamaları, hesapların tarayıcı üzerinden oturum açmasını sağlar. Kapalı olan bir uygulama yeni hesaplar için sunulmaz; onu zaten kullanan hesaplar çalışmaya devam eder.

## Yapay zeka aracıları

# review: new
gtk-agent-it-may = İzin verilen eylemler
# review: new
gtk-agent-accounts = İzin verilen hesaplar
# review: new
gtk-never-used = Hiç kullanılmadı
# review: new
gtk-last-used = Son kullanım: { $date }
# review: new
gtk-forget-program = Bu program kaldırılsın mı?
# review: new
gtk-forget-program-detail = Programın izinleri ve aracılarının etkinlik geçmişi silinecek. Bir sonraki bağlantısında yeniden izin istenecek.
# review: new
gtk-no-agents-yet = Henüz hiçbir aracı postanızı kullanmak istemedi.
# review: new
gtk-nothing-yet = Henüz bir şey yok.

## Tercihler

# review: new
gtk-preferences = Tercihler
# review: changed
gtk-notify-subtitle = Yalnızca Inbox Classic arka plandayken

## Masaüstü girdisi ve yazılım mağazalarının sayfası

# linux/data/com.inboxclassic.InboxClassic.desktop ve .metainfo.xml, derleme tarafından oluşturulur. Anahtar sözcükler,
# uygulama aramasının Inbox Classic'i bulduğu sözcüklerdir, her biri noktalı virgülle biter, yalnızca sizin dilinizde:
# İngilizce olanlar önlerine eklenir
# review: new
gtk-desktop-generic-name = Posta İstemcisi
# review: new
gtk-desktop-comment = E-posta okuyun ve yazın: hızlı, basit bir posta programı
# review: new
gtk-desktop-keywords = posta;eposta;e-posta;ileti;gelen kutusu;mektup;
# review: new
gtk-metainfo-summary = Hızlı, basit bir posta programı
# review: new
gtk-metainfo-description = Inbox Classic, eski posta programlarındaki gibi solda klasörler, üstte iletiler ve altta ileti ile e-posta okur ve yazar. Her IMAP ve SMTP hesabıyla çalışır, Outlook.com ve Microsoft 365'te tarayıcı üzerinden oturum açar.
# review: new
gtk-metainfo-feature-sanitized = Her ileti betikler olmadan temizlenmiş olarak, internetten gelen resimler yalnızca siz izin verdiğinizde gösterilir
# review: new
gtk-metainfo-feature-search = Konuda, kişilerde, dosya adlarında ve metinde sözcük bulan, Gmail'in işleçlerini kullanan bir arama
# review: new
gtk-metainfo-feature-replies = Yanıtlar, alıntıladıkları önceki iletileri katlar
# review: new
gtk-metainfo-feature-offline = Posta çevrimdışıyken de okunabilir; parolalar anahtarlığınızda saklanır
