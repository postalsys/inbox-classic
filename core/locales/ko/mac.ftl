# ko. 원어민 검토를 기다리는 초안입니다.
# The words of the Mac app's own windows (mac/Sources), ids starting with mac-; the menus and the words every platform
# shares are in app.ftl and core.ftl. Placeables in { $braces } are filled in by the app. Mac conventions: an ellipsis
# (…) after a command that asks for more; Korean follows Apple's Korean menus (윈도우, 오려두기, 실행 복귀).

## 앱과 메뉴

# review: new
mac-quit = Inbox Classic 종료
# review: new
mac-settings = 설정…
# review: new
mac-services = 서비스
# review: new
mac-hide = Inbox Classic 가리기
# review: new
mac-hide-others = 기타 가리기
# review: new
mac-show-all = 모두 보기
# review: new
mac-check-updates = 업데이트 확인…
# review: new
mac-close-window = 윈도우 닫기
# review: new
mac-redo = 실행 복귀
# review: new
mac-cut = 오려두기
# review: new
mac-paste = 붙여넣기
# review: new
mac-menu-window = 윈도우
# review: new
mac-minimize = 최소화
# review: new
mac-zoom = 확대/축소
# review: new
mac-no-updates = 이 버전의 Inbox Classic은 자동 업데이트를 지원하지 않습니다. inboxclassic.com에서 최신 버전을 다운로드하십시오.

## 설정

# review: new
mac-settings-title = 설정
# the Mac only: Sparkle's automatic check for a new version, in General
# review: new
mac-check-updates-automatically = 자동으로 업데이트 확인
# the title of that group, in the label column of the pane
# review: new
mac-settings-updates = 업데이트

## 대화상자

# review: new
mac-choose = 선택

## 기본 윈도우

# review: new
mac-still-running-detail = Inbox Classic은 백그라운드에서 계속 새 메일을 확인합니다. 앱을 열려면 Dock에서 아이콘을 클릭하십시오.
# review: new
mac-outbox-waiting =
    { $count ->
       *[other] 보낼 편지함에 메시지 { $count }개
    }
# review: new
mac-sending = { $subject } 보내는 중…
# review: new
mac-checking = { $account }에서 새 메시지 확인 중…
# review: new
mac-account-said = { $account }: { $message }
# review: new
mac-not-bundle = 이 Inbox Classic은 앱 번들이 아니므로 기본 메일 앱으로 지정할 수 없습니다.
# review: new
mac-not-made-default = Inbox Classic을 기본 메일 앱으로 지정하지 못했습니다: { $reason }
# review: new
mac-tool-search = 검색

## 폴더와 메시지 목록

# review: new
mac-still-indexing-more =
    { $count ->
       *[other] 메시지 { $count }개의 텍스트를 아직 색인하는 중이므로 곧 더 찾을 수 있습니다.
    }
# review: new
mac-results-everywhere =
    { $count ->
        [0] 모든 폴더에서 “{ $words }”에 대한 결과 없음
       *[other] 모든 폴더에서 “{ $words }”에 대한 결과 { $count }개
    }
# review: new
mac-results-in =
    { $count ->
        [0] { $folder }에서 “{ $words }”에 대한 결과 없음
       *[other] { $folder }에서 “{ $words }”에 대한 결과 { $count }개
    }
# review: new
mac-still-indexing =
    { $count ->
       *[other] 메시지 { $count }개의 텍스트를 아직 색인하는 중
    }
# review: new
mac-folder-unread = { $folder }, 읽지 않음 { $count }개
# review: new
mac-import-messages = 메시지 가져오기
# review: new
mac-save-messages = 메시지 저장
# review: new
mac-save-attachments-menu = 첨부 파일 저장…
# review: new
mac-files-not-saved =
    { $count ->
       *[other] 파일 { $count }개 중 { $failed }개를 저장할 수 없습니다.
    }
# review: new
mac-no-calendar-app = 초대를 열 수 없습니다. 이 Mac에서 .ics 파일을 열 캘린더 앱이 설정되어 있는지 확인하십시오.
# review: new
mac-file-not-saved = 파일을 저장할 수 없습니다.
# review: new
mac-unsubscribing = { $target }에서 구독 취소하는 중…
# review: new
mac-loading-list = 불러오는 중…

## 메시지 작성 윈도우

# review: new
mac-bold = 굵게
# review: new
mac-italic = 기울임꼴
# review: new
mac-underline = 밑줄
# review: new
mac-bcc = 숨은 참조
# review: new
mac-command-click-to-open = ⌘-클릭하여 열기
# review: new
mac-saving-to-drafts = 임시 보관함에 저장하는 중…
# review: new
mac-dont-save = 저장 안 함

## 읽기 패널

# review: new
mac-files =
    { $count ->
       *[other] 파일 { $count }개
    }

## 계정

# review: new
mac-next = 다음
# review: new
mac-name-placeholder = 홍길동
# review: new
mac-more-sign-in-options = 기타 로그인 옵션…
# review: new
mac-add-sign-in-app = 로그인 앱 추가…
# review: new
mac-looking-up = { $domain }의 설정을 찾는 중…
# review: new
mac-add-button = 추가…
# review: new
mac-properties-button = 속성…
# review: new
mac-signature-button = 서명…
# review: new
mac-security-button = 보안…
# review: new
mac-sign-in-apps-button = 로그인 앱…

## AI 에이전트

# review: new
mac-forget-program = 이 프로그램과 해당 에이전트의 활동 기록을 제거하시겠습니까?
# review: new
mac-forget-program-detail = 프로그램의 권한이 삭제됩니다. 다음에 연결할 때 다시 권한을 묻습니다.

## 로그인 앱

# review: new
mac-checking-issuer = { $issuer } 확인 중…
# review: new
mac-edit-button = 편집…
# review: new
mac-use-for-new-accounts = 새 계정에 { $name } 사용
# review: new
mac-built-in = { $name } (기본 제공)

## 기타 윈도우

# review: new
mac-new-folder-button = 새로운 폴더…
# review: new
mac-edit-link = 링크 편집…
