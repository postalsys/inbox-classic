# ko. 원어민 검토를 기다리는 초안입니다.
# The words of the Linux app's own windows (linux/src), ids starting with gtk-. Placeables in { $braces } are filled in
# by the app; an _ marks a button's mnemonic letter, in Korean in brackets after the words: 참조(_C). GNOME words
# where GNOME has them (기본 설정, 끝내기).

## 기본 창

gtk-search-looks-in = { $place }에서 검색하는 대상은 제목, 보낸 사람, 받는 사람, 첨부 파일 이름, 메시지 텍스트입니다. 맞춤법을 확인하거나 단어 수를 줄여 보십시오.
gtk-search-still-indexing = 메시지 { $count }개의 텍스트를 아직 색인하는 중입니다. 곧 결과가 더 나타날 수 있습니다.
gtk-search-results-everywhere = 모든 폴더에서 “{ $words }”에 대한 { $count ->
    [0] 결과 없음
   *[other] 결과 { $count }개
}
gtk-search-results-in = { $place }에서 “{ $words }”에 대한 { $count ->
    [0] 결과 없음
   *[other] 결과 { $count }개
}
gtk-search-indexing = 메시지 { $count }개의 텍스트를 아직 색인하는 중
gtk-list-loading = 불러오는 중...
gtk-menu-rename = 이름 바꾸기...
gtk-import-one-question = { $file } 메시지를 { $folder } 폴더로 가져오시겠습니까?
gtk-files-not-saved = 파일 { $total }개 중 { $failed }개를 저장할 수 없습니다.
gtk-unsubscribe-one-click =
    이 메일링 리스트에서 탈퇴하시겠습니까?

    Inbox Classic이 { $target }(으)로 구독 취소 요청을 보냅니다. 웹 페이지가 열리거나 전자 메일이 전송되지는 않습니다.
gtk-unsubscribe-mail =
    이 메일링 리스트에서 탈퇴하시겠습니까?

    구독을 취소하려면 { $target }(으)로 전자 메일을 보내야 합니다. Inbox Classic이 메시지를 준비합니다. 확인하려면 메시지를 보내십시오.
gtk-unsubscribe-web =
    이 메일링 리스트에서 탈퇴하시겠습니까?

    메일링 리스트의 구독 취소 페이지가 브라우저에서 열립니다({ $target }).
gtk-unsubscribe-failed = 구독을 취소할 수 없습니다: { $problem }
gtk-toolbar-create-mail-menu = 특정 계정으로 메일 작성
gtk-toolbar-send-recv-menu = 특정 계정의 메일 보내기/받기
gtk-main-menu = 주 메뉴
gtk-folder-list = 폴더 목록
gtk-quit = 끝내기

## 이동 및 복사 창

gtk-new-folder-at-top-of = 새 폴더는 { $account }의 최상위에 만들어집니다.

## 메시지 목록

## 도움말

## 알림과 트레이

gtk-unread-messages = { $count ->
    [0] 읽지 않은 메시지 없음
   *[other] 읽지 않은 메시지 { $count }개
}

## 메시지 작성 창의 링크 메뉴

## 보낼 편지함

gtk-outbox-empty = 보내기를 기다리는 메시지가 없습니다.
gtk-outbox-row = 받는 사람: { $to }  ·  대기 시작 { $queued }  ·  { $status }

## 앱

gtk-still-running-detail = Inbox Classic은 백그라운드에서 계속 새 메일을 확인합니다. 앱을 열거나 끝내려면 상단 표시줄의 아이콘을 사용하십시오.
gtk-sign-in-again-ask =
    { $account } 로그인이 거부되었거나 세션이 만료되었습니다.

    브라우저에서 다시 로그인하시겠습니까?
gtk-default-app-not-installed = 이 Inbox Classic은 설치된 것이 아니므로 시스템의 메일 앱 목록에 나타나지 않습니다. 선택하려면 먼저 설치하십시오.
gtk-default-app-now = 이제 Inbox Classic이 기본 메일 앱입니다. 전자 메일 링크를 누르면 여기에서 새 메시지가 열립니다.
gtk-default-app-failed = Inbox Classic을 기본 메일 앱으로 지정할 수 없습니다.

## 여러 창에서 쓰는 단추와 단어

## 읽기 창

gtk-reader-date = 날짜:
gtk-reader-files = 메시지 첨부 파일
gtk-files = 파일 { $count }개
gtk-save-attachments-menu = 첨부 파일 저장...

## 메시지 작성 창

gtk-format-bold = 굵게 (Ctrl+B)
gtk-format-italic = 기울임꼴 (Ctrl+I)
gtk-format-underline = 밑줄 (Ctrl+U)
gtk-format-hyperlink = 하이퍼링크 (Ctrl+K)
gtk-font = 글꼴
gtk-show-cc = 참조(_C)
gtk-show-bcc = 숨은 참조(_B)
gtk-save-tip = 저장 (Ctrl+S)
gtk-link-status = { $link }    (Ctrl+클릭하여 열기)

## 계정

gtk-plain-warning =
    암호화하지 않으면 네트워크 트래픽을 가로채는 사람이 누구든 암호와 메시지를 읽을 수 있습니다. 연결이 다른 방법으로 보호되는 경우에만 계속하십시오. 로컬 네트워크라고 해서 암호화되는 것은 아닙니다.

    계속하시겠습니까?
gtk-account-name-title = 계정 이름
gtk-display-name-title = 표시 이름
gtk-turned-off-why = 이 컴퓨터에서는 “{ $button }” 옵션을 사용할 수 없습니다. { $reason }
gtk-turned-off-why-long =
    이 컴퓨터에서는 “{ $button }” 옵션을 사용할 수 없습니다.

    { $reason }
gtk-next = 다음 >
gtk-provider-sign-in = { $provider } 웹 사이트에서 { $address } 계정으로 로그인하십시오. 암호는 Inbox Classic에 전달되지 않습니다. 계정에서 메일용 앱 암호를 허용하는 경우 보안 설정에서 만든 앱 암호를 사용할 수도 있습니다. Outlook.com과 Microsoft 365는 브라우저 로그인만 사용할 수 있습니다.
gtk-provider-sign-in-apps = 로그인 앱 중 하나를 사용하여 { $provider } 웹 사이트에서 { $address } 계정으로 로그인하십시오(기타 로그인 옵션). 계정에서 메일용 앱 암호를 허용하는 경우 보안 설정에서 만든 앱 암호를 사용할 수도 있습니다. Outlook.com과 Microsoft 365는 브라우저 로그인만 사용할 수 있습니다.
gtk-accounts-add = 추가...
gtk-accounts-properties = 속성...
gtk-accounts-signature = 서명...
gtk-accounts-sign-in-apps = 로그인 앱...

## 로그인 앱

gtk-app-server = { $kind } 서버
gtk-app-port = { $kind } 포트
gtk-app-security = { $kind } 보안
gtk-issuer-found =
    로그인 페이지: { $page }
    토큰 엔드포인트: { $endpoint }
gtk-client-id = 클라이언트 ID
gtk-client-secret = 클라이언트 암호
gtk-scopes = 범위
gtk-redirect-uri = 리디렉션 URI
gtk-issuer-usable =
    발급자를 사용할 수 있습니다.

    { $found }
gtk-app-built-in = { $app }은(는) 기본 제공됩니다. 새 계정에 제공할지 여부만 변경할 수 있습니다. { $reason }
gtk-built-in = { $app } (기본 제공)
gtk-offered-for-new = 새 계정에 제공
gtk-edit-button = 편집...
gtk-remove-app-ask = 로그인 앱 { $app }과(와) 저장된 클라이언트 암호를 제거하시겠습니까?
gtk-sign-in-apps-intro = 로그인 앱을 사용하면 계정이 브라우저를 통해 로그인할 수 있습니다. 꺼져 있는 앱은 새 계정에 제공되지 않으며, 이미 사용 중인 계정은 계속 작동합니다.

## AI 에이전트

gtk-agent-it-may = 허용된 작업
gtk-agent-accounts = 허용된 계정
gtk-never-used = 사용한 적 없음
gtk-last-used = 마지막 사용 { $date }
gtk-forget-program = 이 프로그램에 저장된 권한과 활동 기록을 삭제하시겠습니까?
gtk-forget-program-detail = 프로그램 자체를 삭제하지는 않습니다. 다음에 연결할 때 다시 권한을 묻습니다.
gtk-no-agents-yet = 아직 메일 사용을 요청한 에이전트가 없습니다.
gtk-nothing-yet = 아직 없습니다.

## 기본 설정

gtk-preferences = 기본 설정
gtk-notify-subtitle = Inbox Classic의 기본 창이 백그라운드에 있을 때만

## 데스크톱 항목과 소프트웨어 스토어 페이지

# linux/data/com.inboxclassic.InboxClassic.desktop and .metainfo.xml, made by the build. The keywords are the words a
# search of the applications finds Inbox Classic by, each ended by a semicolon, in your language only: the English
# ones are added before them
gtk-desktop-generic-name = 메일 클라이언트
gtk-desktop-comment = 전자 메일 읽기 및 쓰기: 빠르고 간단한 메일 프로그램
gtk-desktop-keywords = 메일;이메일;전자 메일;편지;받은 편지함;
gtk-metainfo-summary = 빠르고 간단한 메일 프로그램
gtk-metainfo-description = Inbox Classic은 전자 메일을 읽고 씁니다. 왼쪽에 폴더, 위쪽에 메시지, 아래쪽에 선택한 메시지가 있는 클래식 레이아웃을 사용합니다. 호환되는 IMAP 및 SMTP 계정에서 작동하며, Outlook.com과 Microsoft 365에는 브라우저를 통해 로그인합니다.
gtk-metainfo-feature-sanitized = 메시지의 스크립트와 기타 활성 콘텐츠는 제거되며, 인터넷의 그림은 허용할 때만 불러옵니다
gtk-metainfo-feature-search = 익숙한 Gmail 방식의 연산자로 제목, 보낸 사람, 받는 사람, 첨부 파일 이름, 메시지 텍스트를 검색합니다
gtk-metainfo-feature-replies = 회신에 인용된 이전 메시지는 접어서 표시합니다
gtk-metainfo-feature-offline = 다운로드한 메일은 로컬 사본이 유지되는 동안 오프라인에서도 읽을 수 있으며, 로그인 자격 증명은 사용 가능한 경우 일반적으로 시스템 키링을 사용합니다
