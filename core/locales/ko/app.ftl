# ko. 원어민 검토를 기다리는 초안입니다.
# The words of the windows, the same on every platform. An & marks the letter of a menu item that Alt and the letter
# choose on Windows and Linux (&& is an ampersand); the Mac leaves it out. Korean writes the letter in brackets after
# the words, before a trailing ... or colon (파일(&F), 새 계정(&N)...), the same letter as English's.

## 메뉴

menu-file = 파일(&F)
menu-edit = 편집(&E)
menu-view = 보기(&V)
menu-tools = 도구(&T)
menu-message = 메시지(&M)
menu-help = 도움말(&H)
menu-layout = 레이아웃(&L)
menu-sort-by = 정렬 기준(&B)
menu-text-size = 텍스트 크기(&T)
menu-folder = 폴더(&O)
menu-insert = 삽입(&I)

## 메뉴, 도구 모음, 알림 영역의 명령 (core/commands.toml)

cmd-new-account = 새 계정(&N)...
cmd-exit = 끝내기(&X)
cmd-sync = 모두 보내기/받기(&V)
cmd-mark-read = 읽은 상태로 표시(&M)
cmd-mark-unread = 읽지 않은 상태로 표시(&N)
cmd-pictures = 그림 다운로드(&P)
cmd-about = Inbox Classic 정보(&A)
cmd-new-mail = 새 메시지(&N)
cmd-reply = 보낸 사람에게 회신(&R)
cmd-reply-all = 전체 회신(&Y)
cmd-forward = 전달(&F)
cmd-help = 목차(&C)
cmd-delete = 메시지 삭제(&D)
cmd-move = 폴더로 이동(&V)...
cmd-flag = 메시지에 플래그 지정(&L)
cmd-new-folder = 새 폴더(&N)...
cmd-rename-folder = 폴더 이름 바꾸기(&R)...
cmd-delete-folder = 폴더 삭제(&D)
cmd-empty-folder = 폴더 비우기(&E)
ui-empty-button = 비우기
cmd-accounts = 계정(&A)...
cmd-find = 메시지 찾기(&F)
cmd-save-as = 다른 이름으로 저장(&S)...
cmd-print = 인쇄(&P)...
# review: new
cmd-print-conversation = 대화 인쇄(&V)...
cmd-import = 메시지 가져오기(&I)...
cmd-outbox = 보낼 편지함(&O)...
cmd-properties = 속성(&R)
cmd-mark-all-read = 모두 읽은 상태로 표시(&A)
cmd-junk = 정크 메일로 표시(&J)
cmd-not-junk = 정크 메일 아님으로 표시(&O)
cmd-archive = 보관(&A)
cmd-watch-conversation = 대화 지켜보기(&W)
cmd-ignore-conversation = 대화 무시(&I)
cmd-next-message = 다음 메시지(&N)
cmd-previous-message = 이전 메시지(&V)
cmd-next-unread = 읽지 않은 다음 메시지(&U)
cmd-go-to-folder = 폴더로 가기(&G)...
cmd-find-in-message = 이 메시지에서 찾기(&T)...
ui-go-to-prompt = 열 폴더:
ui-find-in-message-hint = 이 메시지에서 찾기
ui-find-not-found = 이 메시지에 “{ $words }”이(가) 없습니다
cmd-expand-all-threads = 모든 대화 펼치기(&E)
cmd-collapse-all-threads = 모든 대화 접기(&O)
ui-group-by-conversation = 대화별로 메시지 그룹화(&G)
# review: new
ui-show-whole-conversation = 읽기 창에 전체 대화 표시(&W)
# review: new
ui-show-whole-conversation-note = 대화의 행을 선택하면 회신, 임시 보관 메시지, 다른 폴더로 옮긴 메시지를 포함하여 그 대화의 모든 메시지가 열립니다. 읽은 메시지는 한 줄로 접힙니다. 줄을 클릭하면 열거나 접을 수 있습니다.
# review: new
ui-conversation-order = 대화 순서(&O):
# review: new
ui-conversation-oldest-first = 오래된 메시지부터
# review: new
ui-conversation-newest-first = 최신 메시지부터
# review: new
ui-thread-count = { $new ->
    [0] ({ $count })
   *[other] ({ $count }, 새 메시지 { $new }개)
}
# review: new
ui-conversation-to = 받는 사람: { $people }
# review: new
ui-conversation-draft = 임시 보관
# review: new
ui-conversation-alone = 서명 또는 암호화됨: 따로 열립니다
# review: new
ui-conversation-downloading = 다운로드 중…
# review: new
ui-conversation-earlier = { $count ->
    [1] 이전 메시지 1개 표시
   *[other] 이전 메시지 { $count }개 표시
}
# review: new
ui-conversation-elsewhere = { $count ->
    [1] 이 대화에는 다른 폴더에도 메시지가 1개 있습니다.
   *[other] 이 대화에는 다른 폴더에도 메시지가 { $count }개 있습니다.
}
# review: new
ui-conversation-this-folder = 이 폴더만(&T)
# review: new
ui-conversation-whole = 전체 대화(&W)
cmd-folder-list = 폴더 목록(&F)
cmd-layout-automatic = 자동(&A)
cmd-layout-classic = 클래식(&C)
cmd-layout-columns = 열(&O)
cmd-sort-date = 날짜(&D)
cmd-sort-from = 보낸 사람(&F)
cmd-sort-subject = 제목(&S)
cmd-sort-size = 크기(&Z)
cmd-sort-ascending = 오름차순 정렬(&A)
cmd-sort-descending = 내림차순 정렬(&N)
cmd-text-size-largest = 가장 크게(&L)
cmd-text-size-larger = 크게(&R)
cmd-text-size-medium = 보통(&M)
cmd-text-size-smaller = 작게(&S)
cmd-text-size-smallest = 가장 작게(&T)
cmd-hide-ignored = 무시한 대화 숨기기(&H)
cmd-hide-read = 읽은 메시지 숨기기(&R)
cmd-notify = 새 메일 알림(&N)
cmd-open = Inbox Classic 열기(&O)
cmd-default-app = 기본 메일 앱으로 지정(&D)...
cmd-view-source = 메시지 원본(&S)
cmd-ai-agents = AI 에이전트(&A)...
cmd-options = 옵션(&P)...
cmd-message-rules = 메시지 규칙(&R)...
cmd-encryption-keys = 암호화 키(&Y)...
cmd-create-rule-from-message = 메시지로 규칙 만들기(&T)...
cmd-unsubscribe = 메일링 리스트 구독 취소(&U)...
cmd-select-all = 모두 선택(&L)
cmd-undo = 실행 취소(&U)
cmd-copy = 폴더로 복사(&C)...
cmd-address-book = 주소록(&B)...
cmd-add-sender-to-book = 주소록에 보낸 사람 추가(&K)
cmd-import-address-book = 주소록 가져오기(&B)...
cmd-export-address-book = 주소록 내보내기(&E)...
cmd-export-setup = 설정 및 계정 내보내기(&G)...
cmd-import-setup = 설정 및 계정 가져오기(&T)...
cmd-compose-sign = 디지털 서명(&S)
cmd-compose-encrypt = 암호화(&E)
cmd-attach-my-key = 내 공개 키 첨부(&P)

## 알림 영역 아이콘의 메뉴

tray-check = 새 메일 확인(&C)
tray-no-accounts = 아직 계정 없음

## 여러 플랫폼의 창이 함께 쓰는 단어

ui-tb-create-mail = 새 메일
ui-tb-reply = 회신
ui-tb-reply-all = 전체 회신
ui-tb-forward = 전달
ui-tb-print = 인쇄
ui-tb-delete = 삭제
ui-tb-junk = 정크 메일
ui-tb-not-junk = 정크 메일 아님
ui-tb-archive = 보관
ui-tb-previous = 이전
ui-tb-next = 다음
ui-previous-tip = 이전 메시지
ui-next-tip = 다음 메시지
ui-tb-sync = 보내기/받기
ui-tb-mark-read = 읽음 표시
ui-tb-mark-unread = 읽지 않음 표시
ui-still-running = Inbox Classic이 아직 실행 중입니다
ui-no-subject = (제목 없음)
ui-quoted = “{ $subject }”
ui-newest-from = { $sender }의 최근 메시지: { $subject }
ui-new-messages = 새 메시지 { $count }개
ui-outbox-waiting = 보낼 편지함에 메시지 { $count }개
ui-outbox-waits = “{ $subject }” 메시지가 보낼 편지함에서 대기 중입니다
ui-outbox-sending = { $subject } 보내는 중...
ui-from-account = 보낸 계정: { $account }
ui-sign-in-refused = { $account } 로그인이 거부되었거나 세션이 만료되었습니다.
ui-sign-in-again-ask = 브라우저에서 다시 로그인하시겠습니까?
ui-sign-in-again-failed = 다시 로그인할 수 없습니다: { $reason }
ui-unknown-reason = 알 수 없는 이유
ui-checking = { $account }에서 새 메시지 확인 중...
ui-done = 완료
ui-sent-at = { $time }에 “{ $subject }” 메시지를 보냈습니다
ui-draft-saved = 메시지를 임시 보관함에 저장했습니다
ui-draft-not-saved = 메시지를 임시 보관함에 저장하지 못했습니다: { $reason }
ui-about-core = 코어 { $version }
ui-add-account-first = 먼저 메일 계정을 추가하십시오.
ui-add-account-first-link = 먼저 메일 계정을 추가한 다음 전자 메일 링크를 다시 클릭하십시오.
ui-default-app-is = Inbox Classic이 기본 메일 앱입니다. 전자 메일 링크를 누르면 여기에서 새 메시지가 열립니다.
ui-select-message-first = 먼저 메시지를 선택하십시오.
ui-store-not-opened = 메일 저장소를 열 수 없습니다.
ui-store-or-cert-not-opened = 메일 저장소 또는 인증서 파일을 열 수 없습니다.
ui-help-title = Inbox Classic 도움말
ui-help-missing = 이 Inbox Classic에는 도움말이 없습니다.
ui-ok = 확인
ui-cancel = 취소
ui-close = 닫기
ui-col-subject = 제목
ui-col-from = 보낸 사람
ui-col-to = 받는 사람
ui-col-received = 받은 날짜
# the column of the glasses of a watched conversation (and the sign of an ignored one)
# a notification of new mail in a watched conversation, over who it is from
ui-watched-conversation = 지켜보는 대화
ui-col-sent = 보낸 날짜
ui-col-size = 크기
ui-col-folder = 폴더
ui-col-account = 계정
ui-col-queued = 대기 시작
ui-col-status = 상태
ui-outbox-title = 보낼 편지함
ui-outbox-status-waiting = 대기 중
ui-outbox-status-not-sent = 보내지 못함: { $reason }
# This message is still queued, during the grace period before an agent’s send.
ui-outbox-status-agent = AI 에이전트가 대기열에 추가함, { $time }에 보낼 예정
ui-outbox-delete-ask = 이 메시지를 보내지 않고 삭제하시겠습니까?
ui-open-link = 링크 열기
ui-edit-link = 링크 편집...
ui-remove-link = 링크 제거
ui-insert-attachment = 첨부 파일 삽입
ui-insert-picture = 그림 삽입
ui-filter-all = 모든 파일
ui-filter-pictures = 그림
ui-filter-messages = 메일 메시지
ui-save-attachment-as = 첨부 파일을 다른 이름으로 저장
ui-not-sent = 메시지를 보낼 수 없습니다.
ui-attachment-forgotten = “{ $word }”(이)라고 썼지만 첨부된 파일이 없습니다. 그래도 메시지를 보내시겠습니까?
ui-send-anyway = 그래도 보내기
ui-go-back = 돌아가기
ui-not-saved = 메시지를 저장할 수 없습니다.
ui-saving-draft = 임시 보관함에 저장하는 중...
ui-compose-saved-at = { $time }에 임시 보관함에 저장함
ui-compose-restored = Inbox Classic이 예기치 않게 닫힌 후 복원됨
ui-compose-not-saved = 임시 보관함에 저장되지 않음: { $reason }
ui-save-changes-ask = 이 메시지의 변경 내용을 임시 보관함에 저장하시겠습니까?
ui-new-message-title = 새 메시지
ui-link-invalid = 웹 주소(https://...) 또는 전자 메일 링크(mailto:...)를 입력하십시오.
ui-link-address = 주소:
ui-hyperlink = 하이퍼링크
ui-hyperlink-intro = 선택한 텍스트가 연결될 주소입니다.
ui-edit-hyperlink = 하이퍼링크 편집
ui-edit-hyperlink-intro = 링크의 대상 주소입니다. 텍스트는 그대로 두고 링크만 제거하려면 주소를 지우십시오.
ui-not-a-picture = 파일을 10MB 이하의 PNG, JPEG, GIF 또는 WebP 그림으로 읽을 수 없습니다.
ui-format-color = 글꼴 색
ui-format-numbers = 번호 매기기 목록
ui-format-bullets = 글머리 기호 목록
ui-format-outdent = 내어쓰기
ui-format-indent = 들여쓰기
ui-format-left = 왼쪽 맞춤
ui-format-center = 가운데 맞춤
ui-format-right = 오른쪽 맞춤
ui-format-line = 가로줄 삽입
ui-tb-send = 보내기
ui-tb-save = 저장
ui-tb-attach = 첨부
ui-tb-sign = 서명
ui-tb-encrypt = 암호화
ui-field-keys = 키:
ui-field-from = 보낸 사람:
ui-field-to = 받는 사람:
ui-field-cc = 참조:
ui-field-bcc = 숨은 참조:
ui-field-subject = 제목:
ui-field-attach = 첨부 파일:
ui-signature = 서명
ui-signature-hint = 이 계정에서 보내는 새 메시지, 회신, 전달 메시지에 추가됩니다.
ui-signature-not-saved = 서명을 저장할 수 없습니다.
ui-all-inboxes = 모든 받은 편지함
ui-all-sent = 모든 보낸 편지함
ui-all-drafts = 모든 임시 보관함
ui-flagged-folder = 플래그 지정됨
ui-all-folders = 모든 폴더
ui-the-account = 계정
ui-folder-name = 폴더 이름:
ui-find-hint = 메일 검색
ui-find-tip = 메시지 제목, 보낸 사람, 받는 사람, 첨부 파일 이름, 메시지 텍스트를 검색합니다.
ui-clear-search = 검색 지우기
ui-no-match = “{ $words }”과(와) 일치하는 메시지가 없습니다.
ui-no-match-all = 모든 폴더에서 검색하는 대상은 제목, 보낸 사람, 받는 사람, 첨부 파일 이름, 메시지 텍스트입니다. 맞춤법을 확인하거나 단어 수를 줄여 보십시오.
ui-no-match-in = { $folder }에서 검색하는 대상은 제목, 보낸 사람, 받는 사람, 첨부 파일 이름, 메시지 텍스트입니다. 맞춤법을 확인하거나 단어 수를 줄여 보십시오.
ui-no-items = 이 보기에 항목이 없습니다.
ui-choose-folder = 메시지를 보려면 폴더를 선택하십시오.
ui-unsubscribe = 구독 취소
ui-open-in-calendar = 캘린더에서 열기
ui-pictures-blocked = 보낸 사람의 추적을 줄이기 위해 일부 그림이 차단되었습니다.
ui-not-shown = 메시지를 표시할 수 없습니다.
ui-attachment-not-read = 첨부 파일을 읽을 수 없습니다.
ui-attachment-not-saved = 첨부 파일을 저장할 수 없습니다.
ui-not-downloaded = 메시지를 아직 다운로드하지 않았습니다.
ui-leave-list = 이 메일링 리스트에서 탈퇴하시겠습니까?
ui-leave-one-click = Inbox Classic이 { $target }(으)로 구독 취소 요청을 보냅니다. 웹 페이지가 열리거나 전자 메일이 전송되지는 않습니다.
ui-leave-mail = 구독을 취소하려면 { $target }(으)로 전자 메일을 보내야 합니다. Inbox Classic이 메시지를 준비합니다. 확인하려면 메시지를 보내십시오.
ui-leave-web = 메일링 리스트의 구독 취소 페이지가 브라우저에서 열립니다({ $target }).
ui-unsubscribing = { $target }(으)로 구독 취소 요청을 보내는 중...
ui-cannot-unsubscribe = 이 메시지에는 구독 취소 방법이 없습니다.
ui-unsubscribed = 메일링 리스트가 구독 취소 요청을 수락했습니다.
ui-not-unsubscribed = 구독을 취소할 수 없습니다: { $reason }
# the bar over a message of a mailing list. It names the list by a domain only, never by a name the sender chose
ui-list-bar = 메일링 리스트({ $domain })에서 온 메시지입니다.
ui-list-bar-plain = 메일링 리스트에서 온 메시지입니다.
# $date is a day as the system writes it ("21 November 2026")
ui-list-bar-asked = { $date }에 이 메일링 리스트의 구독 취소를 요청했습니다.
# a message that arrived more than two days after the request: the list did not stop
ui-list-bar-came-after = { $date }에 구독 취소를 요청했지만, 이 메시지는 요청한 지 이틀이 넘어서 도착했습니다.
ui-list-bar-opened = { $date }에 이 메일링 리스트의 구독 취소 페이지를 열었습니다.
ui-list-bar-failed = 구독 취소 요청에 실패했습니다: { $reason }
# the bar's button; it asks first
ui-unsubscribe-ask = 구독 취소…
ui-unsubscribe-again = 다시 구독 취소…
ui-event-span = { $start } ~ { $end }
ui-event-floating = { $when } (표준 시간대 변환 없이 지정된 그대로)
ui-invitation = 초대: { $title }
ui-invitation-updated = 업데이트된 초대: { $title }
ui-invitation-canceled = 취소됨: { $title }
ui-invitation-answer = 초대에 대한 응답: { $title }
ui-no-title = (제목 없음)
ui-organizer = 주최자: { $name }
ui-invitation-not-read = 초대를 읽을 수 없습니다.
ui-no-calendar = 초대(.ics 파일)를 열 수 없습니다. 이 파일 형식에 캘린더 앱이 연결되어 있는지 확인하십시오.
ui-messages-not-changed = 메시지를 변경할 수 없습니다.
ui-new-folder-in-selected = 새 폴더는 선택한 폴더 안에 만들어집니다.
ui-new-folder-at-top = 새 폴더는 계정의 최상위에 만들어집니다.
ui-folder-not-created = 폴더를 만들 수 없습니다.
ui-folder-not-renamed = 폴더 이름을 바꿀 수 없습니다.
ui-folder-not-deleted = 폴더를 삭제할 수 없습니다.
ui-rename-folder-intro = “{ $folder }” 폴더의 새 이름을 입력하십시오.
ui-properties-of = { $subject } 속성
ui-internet-headers = 이 메시지의 인터넷 헤더:
ui-save-messages-in = 메시지 저장 위치
ui-save-message-as = 메시지를 다른 이름으로 저장
ui-import-choose-folder = 먼저 메시지를 가져와 저장할 폴더를 선택하십시오.
ui-add-account-title = 메일 계정 추가
ui-accounts-title = 계정
ui-security-none = 없음(암호화 안 함)
ui-field-required = { $field }은(는) 필수 항목입니다.
ui-email-invalid = 전자 메일 주소가 올바르지 않습니다.
ui-ports-invalid = 포트는 1부터 65535까지의 숫자입니다.
ui-looking-up = { $domain }의 설정을 찾는 중...
ui-found-none = 전자 메일 공급자가 알려 준 계정 정보를 입력하십시오.
ui-found-change = 공급자가 다른 설정을 알려 준 경우 이 설정을 변경하십시오.
ui-found-guess = 이 주소에 대한 설정을 찾지 못했습니다. 제안된 서버 이름은 추측한 것입니다. 공급자에게 확인하십시오.
ui-found-mx = Inbox Classic이 전자 메일 공급자를 인식하고 서버 설정을 입력했습니다.
ui-found-srv = 도메인의 DNS 레코드에서 찾은 설정입니다.
ui-found-autodiscover = Microsoft 자동 검색(Exchange)으로 찾은 설정입니다.
ui-found-other = 이 주소에 대해 찾은 설정입니다.
ui-app-password-needed = 공급자: { $provider }. 계정에서 앱 암호를 지원하는 경우 보안 설정에서 앱 암호를 만들어 다음 양식의 암호 필드에 입력하십시오. 그렇지 않으면 가능한 경우 브라우저 로그인을 사용하십시오.
ui-app-password-open = 브라우저에서 { $provider } 안내를 여시겠습니까?
ui-plain-warning = 암호화하지 않으면 네트워크 트래픽을 가로채는 사람이 누구든 암호와 메시지를 읽을 수 있습니다. 연결이 다른 방법으로 보호되는 경우에만 계속하십시오. 로컬 네트워크라고 해서 암호화되는 것은 아닙니다.
ui-continue-ask = 계속하시겠습니까?
ui-add-sign-in-app = 로그인 앱 추가...
ui-turned-off = 이 컴퓨터에서는 { $name }이(가) 꺼져 있습니다.
ui-off-here = 이 컴퓨터에서는 꺼져 있습니다.
ui-why = 이유
ui-more-sign-in = 기타 로그인 옵션...
ui-other-account = 다른 전자 메일 계정을 추가하려면 전자 메일 주소와 받는 사람에게 표시할 이름을 입력하십시오. 그다음에 서버 설정을 찾습니다.
ui-field-account-name = 계정 이름:
ui-field-name = 표시 이름:
ui-field-email = 전자 메일 주소:
ui-field-user = 사용자 이름:
ui-field-password = 암호:
ui-field-imap-host = 받는 메일(IMAP) 서버:
ui-field-imap-port = IMAP 포트:
ui-field-imap-security = IMAP 보안:
ui-field-smtp-host = 보내는 메일(SMTP) 서버:
ui-field-smtp-port = SMTP 포트:
ui-field-smtp-security = SMTP 보안:
ui-field-other-addresses = 보낼 때 사용하는 다른 주소:
ui-sign-in-not-started = 브라우저를 통한 로그인을 시작할 수 없습니다.
ui-sign-in-in-browser = 열린 브라우저 창에서 { $account }에 로그인한 다음 여기로 돌아오십시오.
ui-sign-in-failed = 로그인할 수 없습니다: { $reason }
ui-account-not-saved = 계정을 저장할 수 없습니다.
ui-start-intro = Gmail, Google Workspace, Outlook.com, Microsoft 365: Google 또는 Microsoft의 페이지에서 직접 로그인합니다. 암호는 그곳에 입력하며 Inbox Classic에는 입력하지 않습니다.
ui-start-intro-apps = 로그인 앱 중 하나로 브라우저를 통해 로그인하거나(기타 로그인 옵션), 아래에 이름과 주소를 입력하여 전자 메일 계정을 추가하십시오.
ui-use-app-password = 앱 암호 사용
ui-the-provider = 공급자
ui-provider-intro = { $provider } 웹 사이트에서 { $email } 계정으로 로그인하십시오. 암호는 Inbox Classic에 전달되지 않습니다. 계정에서 메일용 앱 암호를 허용하는 경우 보안 설정에서 만든 앱 암호를 사용할 수도 있습니다. Outlook.com과 Microsoft 365는 브라우저 로그인만 사용할 수 있습니다.
ui-provider-intro-apps = 로그인 앱 중 하나를 사용하여 { $provider } 웹 사이트에서 { $email } 계정으로 로그인하십시오(기타 로그인 옵션). 계정에서 메일용 앱 암호를 허용하는 경우 보안 설정에서 만든 앱 암호를 사용할 수도 있습니다. Outlook.com과 Microsoft 365는 브라우저 로그인만 사용할 수 있습니다.
ui-finish = 마침
ui-logon = 로그온
ui-enter-password = { $account }의 암호를 입력하십시오.
ui-signs-in-with = 로그인 앱: { $app }. 로그인은 브라우저에서 이루어지며, 계정은 이 앱의 서버를 사용합니다.
ui-keep-password = 현재 암호를 유지하려면 암호 필드를 비워 두십시오.
ui-remove-account = 계정 제거
ui-remove-account-ask = Inbox Classic에서 이 계정을 제거하시겠습니까? 보낼 편지함에서 대기 중인 메시지와 저장된 로그인 자격 증명을 포함한 로컬 데이터가 제거됩니다. 서버의 메일은 그대로 남아 있습니다.
ui-col-email = 전자 메일 주소
ui-col-incoming = 받는 메일 서버
ui-type-email = 전자 메일 주소를 입력하십시오(예: name@example.com).
ui-ai-agent = AI 에이전트
ui-ai-agent-access = AI 에이전트 액세스
ui-ai-agents = AI 에이전트
ui-program-path = 프로그램: { $path }
ui-it-may = 허용된 작업:
ui-accounts-it-may-use = 허용된 계정:
ui-send-message-ask = 메시지를 보내시겠습니까?
ui-col-name = 이름
ui-never = 안 함
ui-connect-agent = AI 에이전트 연결
ui-connect-agent-intro = 에이전트의 MCP 서버에 다음을 추가하십시오(Claude Desktop: Settings > Developer > Edit Config):
ui-col-program = 프로그램
ui-col-may = 권한
ui-col-last-used = 마지막 사용
ui-col-when = 시간
ui-col-what = 작업
ui-sign-in-app = 로그인 앱
ui-sign-in-apps = 로그인 앱
ui-add-sign-in-app-title = 로그인 앱 추가
ui-preset-app-name = { $provider } 로그인 앱
ui-issuer-not-checked = 발급자를 확인할 수 없습니다
ui-checking-issuer = { $issuer } 확인 중...
ui-issuer-unusable = 발급자를 사용할 수 없습니다: { $reason }
ui-issuer-usable = 발급자를 사용할 수 있습니다.
ui-sign-in-app-not-saved = 로그인 앱을 저장할 수 없습니다: { $reason }
ui-check = 확인(&H)
ui-fill-in-for = 설정 가져올 공급자:
ui-app-name = 이름:
ui-issuer = 발급자:
ui-client-id = 클라이언트 ID:
ui-client-secret = 클라이언트 암호:
ui-scopes = 범위:
ui-imap-server = IMAP 서버:
ui-smtp-server = SMTP 서버:
ui-redirect-uri = 리디렉션 URI:
ui-sign-in-app-intro = 로그인 앱은 브라우저를 통해 로그인하기 위해 공급자에 등록하는 OAuth 클라이언트입니다. 공급자를 선택하여 설정을 입력한 다음, 클라이언트 ID와 공급자가 제공한 경우 클라이언트 암호를 추가하십시오.
ui-remove-secret = 저장된 클라이언트 암호 제거(교체하려면 새 암호 입력)
ui-register-it = 공급자에 앱 등록
ui-built-in-note = { $name }은(는) 기본 제공됩니다. 새 계정에 제공할지 여부만 변경할 수 있습니다.
ui-client-with-secret = 클라이언트 ID: { $client }, 클라이언트 암호 있음.
ui-client-public = 클라이언트 ID: { $client }, 공용 클라이언트(암호 없음).
ui-no-accounts = 계정 없음
ui-remove-sign-in-app = 로그인 앱 제거
ui-remove-sign-in-app-ask = 로그인 앱 { $name }과(와) 저장된 클라이언트 암호를 제거하시겠습니까?
ui-sign-in-app-not-removed = 로그인 앱을 제거하지 않았습니다. { $reason }
ui-sign-in-apps-intro = 로그인 앱을 사용하면 계정이 브라우저를 통해 로그인할 수 있습니다. 선택하지 않은 앱은 새 계정에 제공되지 않으며, 이미 사용 중인 계정은 계속 작동합니다.
ui-col-issuer = 발급자
ui-col-used-by = 사용하는 계정
ui-options-system-default = 시스템 기본값({ $language })
# the settings window (core/settings.toml): its pages and the titles of its groups, Windows' Apply, and the words of
# the language the three platforms share
ui-settings-general = 일반
ui-settings-reading = 읽기
ui-settings-new-mail = 새 메일
ui-settings-sending = 보내기
ui-settings-default-apps = 기본 앱
ui-settings-message-list = 메시지 목록
ui-settings-messages = 메시지
ui-settings-encryption = 암호화
ui-settings-language = 언어
# a group's title as the label before its first control, in the Mac's panes: the colon as the language writes it
ui-settings-label = { $label }:
ui-apply = 적용(&A)
# review: new
ui-settings-sync = 동기화
# review: new
ui-sync-note = 직접 관리하는 폴더나 스토리지를 통해 모든 컴퓨터에서 계정, 키, 주소록, 규칙, 설정을 똑같이 유지합니다. 모든 데이터는 이 컴퓨터를 떠나기 전에 동기화 암호 문구로 암호화됩니다.
# review: new
ui-sync-place = 동기화 위치:
# review: new
ui-sync-status = 상태:
# review: new
ui-sync-set-up = 동기화 설정(&S)…
# review: new
ui-sync-now = 지금 동기화(&N)
# review: new
ui-sync-computers = 컴퓨터(&M)…
# review: new
ui-sync-history = 기록(&H)…
# review: new
ui-sync-turn-off = 동기화 끄기(&T)…
# review: new
ui-sync-what = 동기화할 항목
# review: new
ui-sync-what-note = 암호, 로그인 정보, 개인 키는 암호화된 상태로만 전송됩니다. 이 컴퓨터에만 두어야 하는 항목은 선택 취소하십시오.
# review: new
ui-sync-accounts = 계정(&O)
# review: new
ui-sync-passwords = 암호(&W)
# review: new
ui-sync-sign-ins = Google, Microsoft 및 로그인 앱으로 로그인한 정보(&I)
# review: new
ui-sync-sign-in-apps = 로그인 앱(&P)
# review: new
ui-sync-app-secrets = 로그인 앱의 클라이언트 암호(&C)
# review: new
ui-sync-contacts = 주소록(&D)
# review: new
ui-sync-keys = 키(&K)
# review: new
ui-sync-private-keys = 내 개인 키(&R)
# review: new
ui-sync-rules = 규칙(&U)
# review: new
ui-sync-trusted = 신뢰할 수 있는 보낸 사람(&E)
# review: new
ui-sync-settings = 설정(&G)
# review: new
ui-sync-preferences = 레이아웃 및 보기(&V)
# review: new
ui-sync-everything = 모든 항목
# review: new
ui-sync-some-left-out = 일부 항목 제외
# review: new
ui-sync-where = 보관 위치
# review: new
ui-sync-folder = 폴더
# review: new
ui-sync-folder-note = Dropbox, OneDrive, iCloud Drive, Google Drive, Nextcloud 또는 Syncthing이 다른 컴퓨터로 복사합니다.
# review: new
ui-sync-bucket = S3 호환 스토리지
# review: new
ui-sync-bucket-note = Amazon S3, Cloudflare R2, Backblaze B2, MinIO 등 S3처럼 작동하는 스토리지입니다.
# review: new
ui-sync-folder-label = 폴더(&F):
# review: new
ui-sync-folder-none = 아직 선택하지 않음
# review: new
ui-sync-choose-folder = 선택(&C)…
# review: new
ui-sync-choose-folder-title = 동기화에 사용할 폴더 선택
# review: new
ui-sync-endpoint = 엔드포인트(&E):
# review: new
ui-sync-region = 리전(&R):
# review: new
ui-sync-bucket-name = 버킷(&B):
# review: new
ui-sync-prefix = 버킷 내 폴더(&U):
# review: new
ui-sync-access-key = 액세스 키 ID(&A):
# review: new
ui-sync-secret-key = 비밀 액세스 키(&S):
# review: new
ui-sync-next = 다음(&N)
# review: new
ui-sync-join-title = 동기화 참여
# review: new
ui-sync-join-note = 이 위치에는 다른 컴퓨터의 동기화 데이터가 있습니다. 첫 번째 컴퓨터에서 정한 동기화 암호 문구를 입력하십시오.
# review: new
ui-sync-start-title = 동기화 시작
# review: new
ui-sync-start-note = 동기화 암호 문구를 정하십시오. 추가하는 컴퓨터마다 한 번씩 입력합니다. 안전한 곳에 보관하십시오. 암호 문구가 없으면 다른 컴퓨터가 참여할 수 없습니다.
# review: new
ui-sync-name = 이 컴퓨터의 이름(&N):
# review: new
ui-sync-merge-note = 이 컴퓨터에 있는 항목과 동기화에 있는 항목이 합쳐집니다. 양쪽에 모두 있는 계정이나 연락처는 하나가 됩니다.
# review: new
ui-sync-turn-on = 동기화 켜기(&T)
# review: new
ui-sync-on = 동기화가 켜져 있습니다.
# review: new
ui-sync-turn-off-ask = 이 컴퓨터에서 동기화를 끄시겠습니까? 이 컴퓨터와 다른 컴퓨터의 모든 항목은 그대로 유지됩니다. 이 컴퓨터만 동기화를 중지합니다.
# review: new
ui-sync-turn-off-button = 끄기
# review: new
ui-sync-computers-title = 컴퓨터
# review: new
ui-sync-computers-note = 이 위치를 통해 동기화하는 컴퓨터입니다. 더 이상 사용하지 않는 컴퓨터는 제거하십시오. 제거한 컴퓨터는 동기화를 중지하며, 이미 동기화된 항목은 그대로 남습니다.
# review: new
ui-sync-this-computer = 이 컴퓨터
# review: new
ui-sync-seen = 마지막 동기화: { $when }
# review: new
ui-sync-remove-ask = “{ $name }” 컴퓨터를 동기화에서 제거하시겠습니까? 다음에 동기화를 시도할 때 동기화가 중지됩니다. 다시 동기화하려면 그 컴퓨터에서 동기화를 다시 설정하십시오.
# review: new
ui-sync-loading = 읽는 중…
# review: new
ui-sync-history-title = 기록
# review: new
ui-sync-history-note = 같은 항목이 두 컴퓨터에서 동시에 변경되면 마지막으로 이루어진 변경 내용이 유지되고 다른 변경 내용은 여기에 보관됩니다. 다른 변경 내용을 대신 사용하려면 복원하십시오.
# review: new
ui-sync-history-empty = 대체된 변경 내용이 없습니다.
# review: new
ui-sync-history-row = { $source }에서, { $when }
# review: new
ui-sync-restore = 복원(&R)
# review: new
ui-sync-restore-points = 복원 지점
# review: new
ui-sync-restore-points-note = 동기화로 이 컴퓨터에서 항목이 제거되기 전에 그때의 상태가 저장됩니다. 복원 지점을 열어 원하는 항목을 되돌릴 수 있습니다.
# review: new
ui-sync-restore-points-empty = 아직 없습니다.
# review: new
ui-sync-open-point = 열기(&O)…
# Set Up Sync on Windows: back from its second step to the first, as a wizard's Back button
# review: new
win-sync-back = < 뒤로(&B)
ui-language-label = 언어(&L):
ui-restart-note = 언어를 바꾸려면 Inbox Classic을 다시 시작하십시오.
ui-restart-ask = Inbox Classic을 다시 시작하면 { $language }(으)로 표시됩니다. 지금 다시 시작하시겠습니까?
ui-notify-new-mail = 새 메일이 도착하면 알림(&N)
ui-new-folder-title = 새 폴더
ui-rename-folder-title = 폴더 이름 바꾸기
ui-delete-folder-question = “{ $folder }” 폴더를 그 안의 메시지 및 폴더와 함께 삭제하시겠습니까? 서버에서도 삭제됩니다.
ui-properties = 속성(&S)
ui-account-sync = 보내기/받기(&V)
ui-account-properties = 속성(&R)...
# review: new
ui-account-properties-of = 계정 속성(&C)...
ui-account-move-up = 위로 이동(&U)
ui-account-move-down = 아래로 이동(&W)
ui-menu-open = 열기(&O)
ui-menu-flag = 플래그(&G)
ui-menu-view-source = 원본 보기(&U)
# Context menu: the same action as cmd-unsubscribe, with its own access key.
ui-menu-unsubscribe = 메일링 리스트 구독 취소(&B)...
ui-save-attachments = 첨부 파일 저장
ui-attachment-open = 열기
ui-attachment-save-as = 다른 이름으로 저장...
ui-attachment-save-all = 모두 저장...
# the strip's menu: a checked item for a picture or PDF file, drawn in the message (checked) or not
ui-attachment-show-in-message = 메시지에 표시
ui-attachments-strip = 첨부 파일
ui-attachment-note-title = 이 파일 열기
ui-attachment-program-tip = 이 종류의 파일은 프로그램을 실행할 수 있으므로 열기 기능을 사용할 수 없습니다. 저장한 후 직접 여십시오.
ui-clear-flag = 플래그 지우기(&C)
ui-button-move = 이동(&M)
ui-button-copy = 복사(&C)
ui-find-folder = 폴더 찾기
ui-new-folder-in = 새 폴더는 { $folder } 안에 만들어집니다.
ui-outbox-send-all = 지금 모두 보내기(&S)
ui-yes = 예
ui-no = 아니요
ui-try-again = 다시 시도
ui-remove = 제거(&R)
ui-signature-of = 서명 - { $account }
ui-sign-in-with = { $provider } 계정으로 로그인
ui-sign-in-in-browser-yours = 열린 브라우저 창에서 계정에 로그인한 다음 여기로 돌아오십시오.
ui-browser-sign-in-server = { $server } (브라우저 로그인)
ui-dont-allow = 허용 안 함
ui-allow = 허용(&A)
ui-dont-send = 보내지 않음
ui-dont-unsubscribe = 구독 취소 안 함
ui-edit-first = 먼저 편집(&E)
ui-new-address = 새 주소
ui-turn-away = 거부(&T)
ui-clear-agent-log = 에이전트의 활동 기록을 지우시겠습니까?
ui-clear-agent-log-detail = 에이전트가 한 변경 내용은 취소되지 않습니다.
ui-let-agents-connect = AI 에이전트가 Inbox Classic에 연결하도록 허용(&L)
ui-change-button = 변경…
ui-undo-button = 실행 취소
# Tools > AI Agents: takes back everything the selected program did in a span the user picks
ui-undo-since-button = 기간 지정 실행 취소…
ui-undo-since-span = 이 프로그램이 한 작업을 되돌릴 기간:
ui-take-back = 되돌리기
ui-rules-title = 메시지 규칙
ui-rules-intro = 규칙은 Inbox Classic이 실행 중일 때 받은 편지함의 새 메시지를 처리합니다. 일치하는 규칙은 순서대로 실행됩니다. 어떤 규칙이 메시지를 받은 편지함 밖으로 옮기기로 하면 그 메시지에는 더 이상 규칙이 적용되지 않습니다.
ui-rules-none = 아직 규칙이 없습니다. 만들려면 새로 만들기를 클릭하십시오.
ui-rule-new = 새로 만들기(&N)...
ui-rule-edit = 편집(&E)...
ui-rule-delete-button = 삭제(&L)
ui-rule-title = 메시지 규칙
ui-rule-name = 이름:
ui-rule-account = 계정:
ui-rule-all-accounts = 모든 계정
ui-rule-query = 검색 조건:
ui-rule-query-hint = 검색 상자에서처럼 from:ann@example.com, subject:invoice, list:news.example.com 같은 검색어를 사용하십시오.
ui-rule-count = 현재 받은 편지함 메시지 { $count }개가 이 조건과 일치합니다.
ui-rule-show = 표시(&S)
ui-rule-actions = 작업:
ui-rule-move = 다음 폴더로 이동(&M):
ui-rule-mark-read = 읽은 상태로 표시(&R)
ui-rule-flag = 플래그 지정(&F)
ui-rule-archive = 보관(&A)
ui-rule-junk = 정크 메일로 이동(&J)
ui-rule-delete = 삭제(&D)
ui-rule-quiet = 알리지 않음(&N)
ui-rule-apply-now = 받은 편지함에 이미 있는 메시지에도 적용(&I)
ui-rule-delete-ask = “{ $name }” 규칙을 삭제하시겠습니까?
ui-create-rule = 규칙 만들기...
ui-rules-applied = 규칙으로 처리된 메시지 { $count }개
ui-col-rule-matches = 조건
ui-clear-button = 지우기(&E)
ui-how-to-connect = 에이전트 연결 방법…
ui-agent-programs = 에이전트가 메일 액세스를 요청한 프로그램
ui-what-agents-did = 에이전트 활동
ui-restart-now = 지금 다시 시작(&R)
ui-restart-later = 나중에(&L)

## 주소록 (도구 > 주소록), 연락처 및 그룹 속성, 받는 사람 선택

ui-tb-new-contact = 새 연락처
ui-tb-new-group = 새 그룹
ui-tb-properties = 속성
ui-tb-write-to = 메일 쓰기
ui-menu-new-contact = 새 연락처(&C)...
ui-menu-new-group = 새 그룹(&G)...
ui-menu-write-to = 메일 쓰기(&W)
ui-menu-delete = 삭제(&D)
ui-book-find-hint = 이름 또는 전자 메일 주소 입력
ui-book-all-contacts = 모든 연락처
ui-col-phone = 전화
ui-book-empty = 주소록이 비어 있습니다. 사람을 추가하려면 새 연락처를 클릭하거나, 파일 메뉴에서 vCard 또는 CSV 파일을 가져오십시오.
ui-book-no-match = “{ $words }”과(와) 일치하는 연락처가 없습니다.
ui-book-delete-ask = { $count ->
    [1] 주소록에서 이 연락처를 삭제하시겠습니까?
   *[other] 주소록에서 이 연락처 { $count }개를 삭제하시겠습니까?
}
ui-group-delete-ask = “{ $name }” 그룹을 삭제하시겠습니까? 그룹에 속한 사람은 주소록에 그대로 남아 있습니다.
ui-book-no-address = “{ $name }” 연락처에 전자 메일 주소가 없습니다.
ui-new-contact-title = 새 연락처
ui-contact-title = { $name } 속성
ui-contact-first = 이름:
ui-contact-last = 성:
ui-contact-display = 표시 이름:
ui-contact-nickname = 별명:
ui-contact-company = 회사:
ui-contact-addresses = 전자 메일 주소:
ui-contact-address-hint = 전자 메일 주소 입력
ui-contact-add = 추가(&A)
ui-contact-set-default = 기본값으로 설정(&U)
ui-contact-default = { $address } (기본값)
ui-contact-phones = 전화번호:
ui-phone-home = 집
ui-phone-work = 회사
ui-phone-mobile = 휴대폰
ui-phone-other = 기타
ui-contact-notes = 메모:
ui-contact-name-needed = 연락처의 이름 또는 전자 메일 주소를 입력하십시오.
ui-contact-address-invalid = “{ $address }”은(는) 올바른 전자 메일 주소가 아닙니다.
ui-contact-not-saved = 연락처를 저장할 수 없습니다: { $reason }
ui-new-group-title = 새 그룹
ui-group-title = { $name } 속성
ui-group-name = 그룹 이름:
ui-group-members = 구성원:
ui-group-select-members = 구성원 선택(&S)...
ui-group-new-member = 주소록에 없는 전자 메일 주소 추가:
ui-group-name-needed = 그룹 이름을 입력하십시오.
ui-group-not-saved = 그룹을 저장할 수 없습니다: { $reason }
ui-group-members-count = 구성원 { $count }명
ui-select-recipients = 받는 사람 선택
ui-select-members = 그룹 구성원 선택
ui-pick-intro = 이름을 입력하거나 목록에서 선택하십시오:
ui-pick-recipients = 메시지 받는 사람:
ui-pick-members = 그룹 구성원:
ui-pick-to = 받는 사람(&T) →
ui-pick-cc = 참조(&C) →
ui-pick-bcc = 숨은 참조(&B) →
ui-pick-add = 추가(&A) →
ui-pick-tip = 주소록에서 받는 사람 선택
ui-filter-address-books = 주소록(vCard, CSV)
ui-filter-vcard = vCard 파일
ui-book-export-name = 주소록
ui-book-imported = 연락처 { $added }개를 추가했고, 이미 주소록에 있는 { $skipped }개를 건너뛰었습니다.
ui-book-not-imported = 주소록을 가져올 수 없습니다: { $reason }
ui-book-exported = 연락처 { $count }개를 { $file }에 저장했습니다.
ui-book-not-exported = 주소록을 저장할 수 없습니다: { $reason }
ui-code-copied = 코드를 복사했습니다
ui-codes-in-notifications = 새 메일 알림에 로그인 코드 표시(&C)
ui-tool-unread-only = 읽지 않음
ui-no-unread = 여기에는 읽지 않은 메시지가 없습니다.
ui-pictures-always-sender = { $sender }의 그림을 항상 다운로드
ui-pictures-always-domain = { $domain }의 모든 사람이 보낸 그림을 항상 다운로드
ui-pictures-unconfirmed = 보낸 사람의 도메인({ $domain })을 확인할 수 없으므로 이 메시지의 그림을 자동으로 다운로드하지 않습니다.
ui-pictures-always-option = 모든 메시지의 그림 다운로드(&M)
ui-pictures-always-warning = 이 경우 보낸 사람이 사용자가 메시지를 읽은 시간을 알 수 있습니다.
ui-protection-details = 자세히(&D)...
ui-protection-details-title = 보안 세부 정보
ui-download-heading = 다운로드
ui-download-ahead = 미리 메시지 다운로드(&D):
ui-download-ahead-recent = 최근 메시지(각각 1MB 이하)
ui-download-ahead-all = 모든 메시지
ui-download-ahead-never = 열 때만
ui-download-limit = 계정당 저장 공간 한도(&S):
ui-send-delay = 보내기 전 지연 시간(&S):
ui-send-delay-note = 카운트다운 중에는 실행 취소로 보내기를 취소할 수 있습니다. 카운트다운이 끝나면 메시지가 아직 보낼 편지함에 있더라도 이 기능을 사용할 수 없습니다.
ui-dark-messages = 시스템이 다크 모드일 때 메시지를 어두운 배경에 표시
# Reading settings: previews of the pictures and PDF files attached, after a message's text
ui-preview-show = 메시지에 첨부 파일 표시(&S)
ui-preview-show-note = 메시지 텍스트 뒤에 그림과 PDF 파일의 처음 몇 페이지를 표시합니다. Inbox Classic은 파일의 코드를 실행하거나 외부 리소스를 불러오지 않고 이 미리 보기를 만듭니다.
# the second setting under it; the same words as preview-pdf-option, with an access key
ui-preview-pdfs = 메시지에 PDF 파일 표시(&F)
ui-sending-in = { $count }초 후에 “{ $subject }” 메시지를 보냅니다
ui-send-undone = “{ $subject }” 메시지를 보내지 않았습니다. 편집할 수 있도록 다시 열었습니다.
ui-send-too-late = “{ $subject }” 메시지의 보내기는 더 이상 취소할 수 없습니다.
ui-outbox-status-undo = { $time }에 보낼 예정
ui-download-note = 한도는 데이터베이스 전체가 아니라 로컬에 저장된 메시지 내용에 적용됩니다. 한도를 넘으면 가장 오래된 사본이 제거되며, 열 때 다시 다운로드할 수 있습니다. 임시 보관함의 메시지와 앱 시작 후 연 메시지는 한도를 넘더라도 유지됩니다.
ui-attachment-downloading = 이 메시지의 다운로드가 끝나지 않았습니다. 다운로드가 완료되면 다시 시도하십시오.
ui-trusted-senders-button = 신뢰할 수 있는 보낸 사람(&T)...
ui-trusted-senders-title = 신뢰할 수 있는 보낸 사람
ui-trusted-senders-note = 메일 공급자가 보낸 사람의 도메인을 확인하면 이 보낸 사람들이 보낸 메시지의 그림이 자동으로 다운로드됩니다.
ui-trusted-everyone-at = { $domain }의 모든 사람
ui-trusted-senders-empty = 아직 추가한 신뢰할 수 있는 보낸 사람이 없습니다.
ui-search-encrypted = 암호화된 메시지에서 검색(&E)
ui-search-encrypted-note = 필요한 개인 키가 있으면 다운로드했거나 연 메시지를 해독하여 텍스트 검색과 보호된 제목을 위해 색인할 수 있습니다. 이 색인은 암호화되지 않습니다. AI 에이전트는 해독된 내용을 검색할 수 없습니다. 이 기능을 끄면 해당 내용이 색인에서 제거됩니다.
ui-pgp-keyserver = keys.openpgp.org에서 키 찾기(&U)
ui-pgp-keyserver-note = 주소로 키를 찾을 때 Inbox Classic은 먼저 주소의 도메인에 묻고, 필요하면 keys.openpgp.org에 주소를 보냅니다. 지문이나 키 ID로 찾을 때는 주소 대신 그 식별자를 보냅니다.
ui-eml-default = Inbox Classic으로 .eml 파일 열기(&E)
ui-eml-default-done = 이제 Inbox Classic이 .eml 파일을 엽니다.
ui-eml-default-failed = Inbox Classic을 .eml 파일의 기본 앱으로 지정할 수 없습니다: { $reason }
ui-folders = 폴더
ui-sorted-by = 정렬 기준: { $field }
ui-layout-label = 레이아웃(&L):
ui-columns-note = 창이 열 레이아웃을 사용할 만큼 넓습니다. 보기 > 레이아웃에서 레이아웃을 바꿀 수 있습니다.
ui-row-unread = 읽지 않음
ui-row-flagged = 플래그 지정됨
ui-row-attachments = 첨부 파일 있음
ui-row-encrypted = 암호화됨
ui-row-signed = 서명됨
ui-row-messages = 메시지 { $count }개
ui-list-pictures = 메시지 목록에 보낸 사람 그림 표시(&P)
ui-list-pictures-note = 열 레이아웃에서 보낸 사람의 도메인이 확인되면 브랜드 로고나 주소록 그림을 표시하고, 그림이 없으면 이니셜을 표시합니다. 다운로드한 로고는 캐시에 저장되어 다시 사용되며, 가끔 새로 고쳐집니다.
ui-card-picture = 그림:
ui-card-picture-choose = 선택(&H)...
ui-picture-not-picture = 파일을 PNG 또는 JPEG 그림으로 디코딩할 수 없습니다.
ui-picture-too-large = 그림이 너무 큽니다. 10MB 이하이고 너비와 높이가 각각 8000픽셀 이하인 그림을 선택하십시오.

## 암호화 키 (도구 > 암호화 키, 계정 속성 > 보안, 연락처의 키)
ui-keys-title = 암호화 키
ui-keys-intro = 내 키는 내 메시지에 디지털 서명을 하거나 나에게 보내는 암호화된 메일을 여는 데 사용합니다. 연락처의 키는 그 사람의 디지털 서명을 확인하거나 그 사람에게 보내는 메일을 암호화하는 데 사용합니다.
ui-keys-empty = 아직 키가 없습니다. 키를 만들려면 새 키를 클릭하고, 이미 가지고 있는 키를 추가하려면 가져오기를 클릭하십시오.
ui-keys-col-name = 이름
ui-keys-col-address = 주소
ui-keys-col-kind = 종류
ui-keys-col-status = 상태
ui-keys-kind-own = 내 키
ui-keys-kind-contact = 연락처
ui-keys-status-verified = { $status }, 소유자 확인됨
ui-keys-new = 새 키(&N)...
ui-keys-import = 가져오기(&I)...
ui-keys-export = 내보내기(&E)...
ui-keys-backup = 백업(&B)...
ui-keys-verify = 소유자 확인(&V)...
ui-keys-new-title = 새 키
ui-keys-new-for = 키를 만들 주소:
ui-keys-new-make = 키 만들기(&M)
ui-keys-no-account = 먼저 메일 계정을 추가하십시오. 키는 계정의 주소에 대해 만들어집니다.
ui-keys-memory-only = 암호를 메모리에만 보관하므로, 지금 만들거나 가져온 개인 키는 Inbox Classic을 닫은 후에는 사용할 수 없습니다.
ui-keys-backup-offer = 새 키가 준비되었습니다. 지금 백업을 저장하시겠습니까? 이 컴퓨터를 잃어버리거나 초기화하면 백업에서만 키를 되살릴 수 있습니다.
ui-keys-backup-now = 백업 저장(&S)...
ui-keys-later = 나중에(&L)
ui-keys-backup-title = 키 백업
ui-keys-backup-intro = 백업은 암호 문구로 보호됩니다. 파일과 암호 문구를 서로 다른 안전한 곳에 보관하십시오. 키를 되살리려면 둘 다 필요합니다.
ui-keys-passphrase = 암호 문구(&P):
ui-keys-passphrase-again = 다시 입력(&T):
ui-keys-passphrase-differ = 암호 문구가 서로 다릅니다.
ui-keys-passphrase-short = 8자 이상의 암호 문구를 사용하십시오.
ui-keys-backup-saved = 백업을 저장했습니다.
ui-keys-import-title = 키 가져오기
ui-keys-import-passphrase = 이 개인 키는 암호 문구로 보호되어 있습니다. 키를 가져오려면 암호 문구를 입력하십시오:
ui-keys-file-filter = OpenPGP 키
ui-keys-use-for = { $addresses } 주소에 이 키를 사용하시겠습니까? 이 주소에서 보내는 메시지에 서명하고 이 키로 암호화된 메일을 읽는 데 사용할 수 있습니다.
ui-keys-use = 사용(&U)
ui-keys-not-now = 나중에(&N)
ui-keys-remove-own = 내 키 { $fingerprint }을(를) 제거하시겠습니까? 이 키로 보호된 메일을 다시 해독하려면 개인 키 백업을 가져와야 합니다. 이미 해독된 사본은 제거되지 않습니다.
ui-keys-remove-contact = { $name }에 연결된 키를 제거하시겠습니까? 다시 추가할 때까지 이 키로 만든 서명을 확인하거나 이 키로 메일을 암호화할 수 없습니다.
ui-key-properties-title = 키 속성
ui-key-names = 이름:
ui-key-fingerprint = 지문:
ui-key-status = 상태:
ui-key-created = 만든 날짜:
ui-key-expires = 만료 날짜:
ui-key-never = 없음
ui-key-algorithm = 알고리즘:
ui-key-source = 출처:
ui-key-addresses = 주소:
ui-key-address-verified = { $address } (소유자 확인됨)
ui-key-address-not-verified = { $address } (소유자 확인 안 됨)
ui-verify-title = 키 소유자 확인
ui-verify-intro = 확인 대상: { $name }

    키 소유자를 직접 만나거나 통화하면서, 상대방의 앱에 표시된 키 지문을 읽어 달라고 하십시오. 전자 메일로 받은 지문과 비교하지 마십시오. 키를 바꿀 수 있는 사람이라면 그 지문도 바꿀 수 있습니다.
ui-verify-fingerprint = 가지고 있는 키의 지문:
ui-verify-marks = { $count ->
    [0] 이 키에는 전자 메일 주소가 없습니다. 소유자 확인을 저장할 수 없습니다.
    [1] 일치함을 클릭하기 전에 이 주소가 해당 연락처의 주소인지 확인하십시오: { $addresses }. 그렇지 않으면 다름을 클릭하십시오.
   *[other] 일치함을 클릭하기 전에 이 주소가 모두 해당 연락처의 주소인지 확인하십시오: { $addresses }. 그렇지 않으면 다름을 클릭하십시오.
}
ui-verify-match = 일치함(&M)
ui-verify-differ = 다름(&D)
ui-verify-differs = 확인 대상: { $name }

    가지고 있는 키가 상대방이 확인해 준 키와 다릅니다. 이 키를 제거하고 상대방에게 키를 다시 요청하십시오.
ui-verify-unmark = 소유자 확인 취소(&N)
ui-account-security = 보안
ui-account-security-intro = 키가 있으면 메시지에 서명할 수 있고, 다른 사람이 나에게 암호화된 메일을 보낼 수 있습니다.
ui-account-key = 이 계정의 키(&K):
ui-account-key-none = 없음
ui-account-key-new = 새 키(&N)...
ui-account-autocrypt = Autocrypt로 메시지와 함께 내 공개 키 보내기(&S)
ui-contact-key = 암호화 키:
ui-contact-key-none = 키 없음
ui-contact-key-use-new = 새 키 사용(&N)
ui-contact-key-keep = 현재 키 유지(&K)
ui-recipient-keys-title = 받는 사람의 키
ui-recipient-col-recipient = 받는 사람
ui-recipient-col-key = 키
ui-recipient-find-key = 키 찾기(&F)
ui-recipient-remove = 메시지에서 제거(&R)
ui-send-unencrypted = 암호화하지 않고 보내기(&W)
ui-compose-make-key = 키 만들기(&M)...
ui-compose-show-keys = 암호화 키(&E)...
ui-compose-encrypt-off = 암호화 끄기(&T)
ui-compose-keep-encrypted = 암호화 유지(&K)
ui-setup-export-title = 설정 및 계정 내보내기
ui-setup-import-title = 설정 및 계정 가져오기
ui-setup-export-intro = 다른 컴퓨터로 가져갈 항목을 선택하십시오. 파일에는 보낼 편지함의 메시지를 포함해 어떤 메시지도 들어 있지 않습니다. 다른 컴퓨터에서는 서버에 보관된 메일만 다운로드할 수 있습니다.
ui-setup-use-passphrase = 암호 문구로 파일 보호(&O)
ui-setup-passphrase-note = 암호 문구는 파일 전체를 암호화하며, 선택한 항목에 있는 암호, 로그인 토큰, 클라이언트 암호, 개인 키도 파일에 포함할 수 있게 합니다. 이 보호를 사용하지 않으면 이러한 비밀 정보는 빠지며, 다른 컴퓨터에서 다시 로그인해야 합니다.
ui-setup-export-button = 내보내기(&E)...
ui-setup-file-filter = Inbox Classic 설정 및 계정
ui-setup-ask-passphrase = 이 파일은 암호 문구로 보호되어 있습니다. 파일 내용을 보려면 암호 문구를 입력하십시오:
ui-setup-import-intro = 가져올 항목을 선택하십시오. 이 컴퓨터에 이미 있는 계정은 그대로 둡니다.
ui-setup-from = Inbox Classic { $version }에서 { $date }에 저장함.
ui-setup-import-button = 가져오기(&I)
ui-setup-done = 완료
ui-setup-first-run = 다른 컴퓨터에서 설정 및 계정 가져오기...
# review: new
ui-first-run-other = 다른 컴퓨터에서 이미 Inbox Classic을 사용하고 계십니까? 그 컴퓨터의 계정과 설정을 여기로 가져오십시오.
# review: new
ui-first-run-sync = 그 컴퓨터의 동기화에 참여…
# review: new
ui-first-run-import = 파일에서 가져오기…

ui-field-verifiers = 보낸 사람 확인 결과를 신뢰할 서버:
ui-attachment-import-key = 키 가져오기...
ui-book-key-known = 암호화 키 있음
ui-book-key-verified = 소유자가 확인된 암호화 키 있음
ui-keys-publish = 게시(&U)...
ui-keys-publish-ask = 다른 사람이 찾을 수 있도록 공개 키를 keys.openpgp.org에 게시하시겠습니까? 키에 포함된 주소: { $addresses }. 각 주소는 해당 주소로 전송된 링크를 통해 확인해야 목록에 표시됩니다.
ui-keys-publish-now = 게시
ui-keys-paste = 클립보드에서 가져오기(&L)
ui-keys-paste-none = 클립보드에 OpenPGP 키가 없습니다.
ui-contact-find-key = 키 찾기(&F)
