# Linux uygulamasının kendi pencerelerinin sözcükleri (linux/src), gtk- ile başlayan kimlikler. { $braces } içindeki yer
# tutucuları uygulama doldurur; _ bir düğmenin kısayol harfini gösterir. GNOME'un sözcükleri varsa onlar (Tercihler, Çık).

## Ana pencere

gtk-search-looks-in = Arama, şu konumda konuları, gönderenleri, alıcıları, ek adlarını ve ileti metnini kapsar: { $place }. Yazımı denetleyin veya daha az sözcük deneyin.
gtk-search-still-indexing = { $count ->
    [one] 1 iletinin metni hâlâ dizinleniyor. Yakında daha fazla sonuç görünebilir.
   *[other] { $count } iletinin metni hâlâ dizinleniyor. Yakında daha fazla sonuç görünebilir.
}
gtk-search-results-everywhere = { $count ->
    [0] Sonuç yok
    [one] 1 sonuç
   *[other] { $count } sonuç
}: tüm klasörlerde “{ $words }”
gtk-search-results-in = { $count ->
    [0] Sonuç yok
    [one] 1 sonuç
   *[other] { $count } sonuç
}: “{ $words }”, konum: { $place }
gtk-search-indexing = { $count ->
    [one] 1 iletinin metni hâlâ dizinleniyor
   *[other] { $count } iletinin metni hâlâ dizinleniyor
}
gtk-list-loading = Yükleniyor...
gtk-menu-rename = Yeniden Adlandır...
gtk-import-one-question = { $file } iletisi içe aktarılsın mı? Hedef: { $folder }
gtk-files-not-saved = { $total } dosyadan { $failed } tanesi kaydedilemedi.
gtk-unsubscribe-one-click =
    Bu posta listesinin aboneliğinden çıkılsın mı?

    Inbox Classic, şu adrese abonelikten çıkma isteği gönderecek: { $target }. Hiçbir web sayfası açılmayacak ve e-posta gönderilmeyecek.
gtk-unsubscribe-mail =
    Bu posta listesinin aboneliğinden çıkılsın mı?

    Abonelikten çıkmak için şu adrese bir e-posta gönderin: { $target }. Inbox Classic iletiyi sizin için hazırlayacak. Onaylamak için iletiyi gönderin.
gtk-unsubscribe-web =
    Bu posta listesinin aboneliğinden çıkılsın mı?

    Posta listesinin abonelikten çıkma sayfası tarayıcınızda açılacak ({ $target }).
gtk-unsubscribe-failed = Abonelikten çıkılamadı: { $problem }
gtk-toolbar-create-mail-menu = Belirli bir hesaptan ileti yaz
gtk-toolbar-send-recv-menu = Belirli bir hesap için posta gönder ve al
gtk-main-menu = Ana Menü
gtk-folder-list = Klasör Listesi
gtk-quit = Çık

## Taşı ve Kopyala penceresi

gtk-new-folder-at-top-of = Yeni klasör şu hesabın en üst düzeyine eklenir: { $account }

## İleti listesi

## Yardım

## Bildirimler ve sistem tepsisi

gtk-unread-messages = { $count ->
    [0] Okunmamış ileti yok
    [one] 1 okunmamış ileti
   *[other] { $count } okunmamış ileti
}

## İleti yazma penceresinin bağlantı menüsü

## Giden Kutusu

gtk-outbox-empty = Gönderilmeyi bekleyen ileti yok.
gtk-outbox-row = Kime: { $to }  ·  Sıraya alındı: { $queued }  ·  { $status }

## Uygulama

gtk-still-running-detail = Inbox Classic arka planda yeni postayı denetlemeye devam eder. Uygulamayı açmak veya kapatmak için sistem tepsisindeki simgesini kullanın.
gtk-sign-in-again-ask =
    Oturum açma reddedildi veya oturumun süresi doldu. Hesap: { $account }

    Tarayıcıda yeniden oturum açılsın mı?
gtk-default-app-not-installed = Inbox Classic'in bu kopyası kurulu olmadığı için sistem uygulamayı posta programları arasında göstermiyor. Seçebilmek için önce yükleyin.
gtk-default-app-now = Inbox Classic artık varsayılan posta uygulamanız: e-posta bağlantıları burada yeni bir ileti açar.
gtk-default-app-failed = Inbox Classic varsayılan posta uygulaması yapılamadı.

## Birçok pencerede kullanılan düğmeler ve sözcükler

## Okuma bölmesi

gtk-reader-date = Tarih:
gtk-reader-files = İleti ekleri
gtk-files = { $count ->
    [one] { $count } dosya
   *[other] { $count } dosya
}
gtk-pictures-blocked = Gönderenin iletiyi ne zaman açtığınızı öğrenmesini önlemek için bazı resimler engellendi.
gtk-download-pictures = Resimleri İndir
gtk-save-attachments-menu = Ekleri Kaydet...

## İleti yazma penceresi

gtk-format-bold = Kalın (Ctrl+B)
gtk-format-italic = İtalik (Ctrl+I)
gtk-format-underline = Altı Çizili (Ctrl+U)
gtk-format-hyperlink = Köprü (Ctrl+K)
gtk-font = Yazı Tipi
gtk-show-cc = _Bilgi
gtk-show-bcc = _Gizli
gtk-save-tip = Kaydet (Ctrl+S)
gtk-link-status = { $link }    (açmak için Ctrl tuşunu basılı tutarak tıklayın)

## Hesaplar

gtk-plain-warning =
    Şifreleme olmadan, ağ trafiğinizi ele geçiren herkes parolanızı ve iletilerinizi okuyabilir. Bu bağlantıyı yalnızca kendi bilgisayarınızdaki veya yerel ağınızdaki bir sunucuyla kullanın.

    Devam edilsin mi?
gtk-account-name-title = Hesap adı
gtk-display-name-title = Görünen ad
gtk-turned-off-why = “{ $button }” seçeneği bu bilgisayarda devre dışı. { $reason }
gtk-turned-off-why-long =
    “{ $button }” seçeneği bu bilgisayarda devre dışı.

    { $reason }
gtk-next = İleri >
gtk-provider-sign-in = Tarayıcıda oturum açın. Sağlayıcı: { $provider }. Hesap: { $address }. Parolanız Inbox Classic ile paylaşılmaz. Hesabınız destekliyorsa güvenlik ayarlarından oluşturduğunuz bir uygulama parolasını da kullanabilirsiniz.
gtk-provider-sign-in-apps = Diğer oturum açma seçenekleri bölümünden bir uygulama seçerek tarayıcıda oturum açın. Sağlayıcı: { $provider }. Hesap: { $address }. Hesabınız destekliyorsa güvenlik ayarlarından oluşturduğunuz bir uygulama parolasını da kullanabilirsiniz.
gtk-accounts-add = Ekle...
gtk-accounts-properties = Özellikler...
gtk-accounts-signature = İmza...
gtk-accounts-sign-in-apps = Oturum Açma Uygulamaları...

## Oturum açma uygulamaları

gtk-app-server = { $kind } sunucusu
gtk-app-port = { $kind } bağlantı noktası
gtk-app-security = { $kind } güvenliği
gtk-issuer-found =
    Oturum açma sayfası: { $page }
    Belirteç uç noktası: { $endpoint }
gtk-client-id = İstemci kimliği
gtk-client-secret = İstemci gizli dizisi
gtk-scopes = İzinler (scopes)
gtk-redirect-uri = Yeniden yönlendirme URI'si
gtk-issuer-usable =
    Yayımcı kullanılabilir.

    { $found }
gtk-app-built-in = { $app } yerleşiktir. Yalnızca yeni hesaplar için sunulup sunulmayacağını değiştirebilirsiniz. { $reason }
gtk-built-in = { $app } (yerleşik)
gtk-offered-for-new = Yeni hesaplar için sunulur
gtk-edit-button = Düzenle...
gtk-remove-app-ask = { $app } oturum açma uygulaması ve kayıtlı istemci gizli dizisi kaldırılsın mı?
gtk-sign-in-apps-intro = Oturum açma uygulamaları, hesapların tarayıcı üzerinden oturum açmasını sağlar. Devre dışı bir uygulama yeni hesaplar için sunulmaz; uygulamayı zaten kullanan hesaplar çalışmaya devam eder.

## Yapay zeka aracıları

gtk-agent-it-may = İzin verilen eylemler
gtk-agent-accounts = İzin verilen hesaplar
gtk-never-used = Hiç kullanılmadı
gtk-last-used = Son kullanım: { $date }
gtk-forget-program = Bu programın kayıtlı izinleri ve etkinlik geçmişi silinsin mi?
gtk-forget-program-detail = Programın izinleri ve aracılarının etkinlik geçmişi silinecek. Bir sonraki bağlantısında yeniden izin istenecek.
gtk-no-agents-yet = Henüz hiçbir aracı postanıza erişim istemedi.
gtk-nothing-yet = Henüz etkinlik yok.

## Tercihler

gtk-preferences = Tercihler
gtk-notify-subtitle = Yalnızca Inbox Classic arka plandayken

## Masaüstü girdisi ve yazılım mağazalarının sayfası

# linux/data/com.inboxclassic.InboxClassic.desktop ve .metainfo.xml, derleme tarafından oluşturulur. Anahtar sözcükler,
# uygulama aramasının Inbox Classic'i bulduğu sözcüklerdir, her biri noktalı virgülle biter, yalnızca sizin dilinizde:
# İngilizce olanlar önlerine eklenir
gtk-desktop-generic-name = Posta İstemcisi
gtk-desktop-comment = E-posta okuyun ve yazın: hızlı, basit bir posta programı
gtk-desktop-keywords = posta;eposta;e-posta;ileti;gelen kutusu;mektup;
gtk-metainfo-summary = Hızlı, basit bir posta programı
gtk-metainfo-description = Inbox Classic, alışılmış e-posta düzenini sunar: solda klasörler, üstte ileti listesi, altta okuma bölmesi. IMAP ve SMTP hesaplarıyla çalışır; Outlook.com ve Microsoft 365 hesaplarında tarayıcı üzerinden oturum açmayı destekler.
gtk-metainfo-feature-sanitized = İletiler, betikler ve güvenli olmayan içerikler temizlenerek gösterilir. İnternetteki resimler yalnızca izin verdiğinizde yüklenir
gtk-metainfo-feature-search = Konularda, gönderenlerde, alıcılarda, ek adlarında ve ileti metninde arama yapın; Gmail tarzı arama ifadeleriyle sonuçları daraltın
gtk-metainfo-feature-replies = Yanıtlardaki önceki iletiler, gerektiğinde açılabilecek şekilde gizlenir
gtk-metainfo-feature-offline = Önceden indirilen iletileri çevrimdışı okuyun. Parolalarınız sistemin güvenli kimlik bilgileri deposunda saklanır
