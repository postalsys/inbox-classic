# ko. 원어민 검토를 기다리는 초안입니다.
# The words of the Windows app's own windows (app/src), ids starting with win-. Placeables in { $braces } are filled in
# by the app; an & marks a menu or button letter (&& is an ampersand). Korean: the letter in brackets after the words,
# 삭제(&D).

## 기본 창

# review: new
win-still-running-detail = Inbox Classic은 백그라운드에서 계속 새 메일을 확인합니다. 열려면 아이콘을 클릭하십시오. 끝내려면 아이콘을 마우스 오른쪽 단추로 클릭하고 메뉴를 사용하십시오.
# review: new
win-default-app-not-installed = 이 Inbox Classic은 설치된 것이 아니므로 Windows의 메일 앱 목록에 나타나지 않습니다. 선택하려면 먼저 설치하십시오.
# review: new
win-default-app-settings = Windows의 기본 앱 설정이 열립니다. MAILTO 링크를 열 앱으로 Inbox Classic을 선택하십시오.
# review: new
win-no-unread = 읽지 않은 메시지 없음
# review: new
win-unread-messages = 읽지 않은 메시지 { $count }개
# review: new
win-print-failed = 메시지를 인쇄할 수 없습니다.
# review: new
win-print-title-of = 인쇄 - { $subject }
# review: new
win-no-bodies = 메시지 본문을 표시할 수 없습니다.
# review: new
win-webview-failed = WebView2를 만들지 못했습니다.
# review: new
win-webview-missing = WebView2 런타임을 사용할 수 없습니다.
# review: new
win-list-loading = 불러오는 중...

## 여러 창에서 쓰는 단추와 단어

# review: new
win-delete-button = 삭제(&D)
# review: new
win-find-label = 찾기(&F):
# review: new
win-save-as-button = 다른 이름으로 저장(&E)...
# review: new
win-too-many-files = 한 번에 파일이 너무 많습니다. 더 적게 선택하십시오.

## 보낼 편지함


## 메시지 작성 창

# review: new
win-editor-failed = 메시지를 작성할 수 없습니다.
# review: new
win-ctrl-click-to-open = ({ $ctrl }+클릭하여 열기)
# review: new
win-format-bold = 굵게 ({ $ctrl }+B)
# review: new
win-format-italic = 기울임꼴 ({ $ctrl }+I)
# review: new
win-format-underline = 밑줄 ({ $ctrl }+U)
# review: new
win-format-link = 하이퍼링크 ({ $ctrl }+K)
# review: new
win-show-cc = 참조(&C)
# review: new
win-show-bcc = 숨은 참조(&B)
# review: new
win-signature-title = 서명: { $account }

## 폴더, 메시지 목록, 읽기 창

# review: new
win-search-found-all = { $count ->
    [0] 모든 폴더에서 “{ $words }”에 대한 결과 없음
   *[other] 모든 폴더에서 “{ $words }”에 대한 결과 { $count }개
}
# review: new
win-search-found-in = { $count ->
    [0] { $folder }에서 “{ $words }”에 대한 결과 없음
   *[other] { $folder }에서 “{ $words }”에 대한 결과 { $count }개
}
# review: new
win-search-indexing = 메시지 { $count }개의 텍스트를 아직 색인하는 중
# review: new
win-no-match-indexing = 메시지 { $count }개의 텍스트를 아직 색인하는 중이므로 곧 더 찾을 수 있습니다.
# review: new
win-files = 파일 { $count }개
# review: new
win-save-attachments = 첨부 파일 저장(&S)...
# review: new
win-files-not-saved = 파일 { $count }개 중 { $failed }개를 저장할 수 없습니다.
# review: new
win-new-folder-in-highlighted = 새 폴더는 선택한 폴더 안에 만들어집니다.
# review: new
win-delete-folder-ask = “{ $folder }” 폴더를 그 안의 메시지 및 폴더와 함께 삭제하시겠습니까? 서버에서도 삭제됩니다.
# review: new
win-rename = 이름 바꾸기(&R)...
# review: new
win-messages-not-saved = 메시지를 저장할 수 없습니다.
# review: new
win-messages-not-forwarded = 메시지를 전달할 수 없습니다.

## 계정

# review: new
win-sign-in-google = Google 계정으로 로그인
# review: new
win-sign-in-microsoft = Microsoft 계정으로 로그인
# review: new
win-next = 다음(&N) >
# review: new
win-your-account = 내 계정
# review: new
win-browser-sign-in = (브라우저 로그인)
# review: new
win-add = 추가(&A)...
# review: new
win-properties-button = 속성(&P)...
# review: new
win-signature-button = 서명(&G)...
# review: new
win-sign-in-apps-button = 로그인 앱(&S)...

## AI 에이전트

# review: new
win-dont-allow = 허용 안 함(&D)
# review: new
win-col-address = 주소
# review: new
win-never-written-to = 보낸 적 없음
# review: new
win-book-find-label = 이름 또는 전자 메일 주소 입력:
# review: new
win-send = 보내기(&S)
# review: new
win-dont-send = 보내지 않음(&D)
# review: new
win-unsubscribe = 구독 취소(&U)
# review: new
win-dont-unsubscribe = 구독 취소 안 함(&D)
# review: new
win-forget-program-ask = 이 프로그램에 대해 저장된 권한과 해당 에이전트의 활동 기록을 제거하시겠습니까? 프로그램이 제거되지는 않습니다. 다음에 연결할 때 다시 권한을 묻습니다.
# review: new
win-clear-log-ask = 에이전트의 활동 기록을 지우시겠습니까? 에이전트가 한 변경 내용은 취소되지 않습니다.
# review: new
win-agent-programs = 에이전트가 메일 액세스를 요청한 프로그램(&P):
# review: new
win-change = 변경(&C)...
# Tools > AI Agents: takes back everything the selected program did in a span the user picks
# review: new
win-undo-since = 기간 지정 실행 취소(&S)...
# review: new
win-take-back = 되돌리기(&T)
# review: new
win-what-agents-did = 에이전트 활동(&A):
# under the log of Tools > AI Agents: what the selected row of reads covers (the start and end of its hour), or how to see it
# review: new
win-agent-reads = { $from }부터 { $to }까지 읽은 내용:
# review: new
win-agent-reads-hint = 읽은 내용을 보려면 위에서 읽기 행을 선택하십시오.

## 로그인 앱

# review: new
win-built-in = (기본 제공)
# review: new
win-edit = 편집(&E)...

## 옵션

# review: new
win-folders-hide = 폴더 목록 숨기기
# review: new
win-folders-pin = 폴더 목록을 메시지 옆에 고정
# review: new
win-folders-show = 폴더 표시

## 설치 프로그램

# the installer's own words (installer/inbox-classic.nsi), made into installer/languages.nsh by the build;
# { $version } and { $installed } are version numbers, 0.18.0
# review: new
win-installer-start = Inbox Classic 시작
# review: new
win-installer-welcome-new =
    전자 메일 프로그램인 Inbox Classic { $version }을(를) 설치합니다.

    관리자 권한은 필요하지 않으며, 현재 사용자 계정에만 설치됩니다.
# review: new
win-installer-welcome-same =
    Inbox Classic { $version }이(가) 이미 설치되어 있습니다. 다시 설치합니다.

    계정과 메일은 그대로 유지됩니다.
# review: new
win-installer-welcome-update =
    Inbox Classic { $installed }을(를) { $version }(으)로 업데이트합니다.

    실행 중이면 먼저 닫습니다. 계정과 메일은 그대로 유지됩니다.
# review: new
win-installer-older-ask = { $version }보다 최신 버전인 Inbox Classic { $installed }이(가) 설치되어 있습니다. 이전 버전을 그래도 설치하시겠습니까?
# review: new
win-installer-still-running = Inbox Classic이 아직 실행 중입니다. 닫은 후 다시 시도하십시오.
# review: new
win-installer-remove-mail-ask = 계정, 다운로드한 메일, 대기 중인 메시지, 설정, 연락처, 규칙, 암호화 키를 포함한 Inbox Classic의 로컬 데이터도 제거하시겠습니까? 서버의 메일과 시스템 자격 증명 저장소의 항목은 남아 있습니다.
