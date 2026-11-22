# ko. 원어민 검토를 기다리는 초안입니다.
# What the core says, the same on every platform. Placeables in { $braces } are filled in by the code; keep them, in
# the place the language puts them. Korean has only the plural form *[other]; where English's [one] says something
# else than the number, an exact [1] variant says it.

## 개수와 크기

# review: new
messages = 메시지 { $count }개
# the separator of decimals in sizes: 2.4 MB
# review: new
decimal-separator = .
# what goes between the items of a list of words; the quotes keep the space
# review: new
list-separator = { ", " }
# review: new
size-bytes = { $count }바이트
# review: new
size-kb = { $size }KB
# review: new
size-mb = { $size }MB
# review: new
size-gb = { $size }GB
# review: new
send-delay-off = 끄기
# review: new
send-delay-seconds = { $count }초
# the status bar: "12 messages, 3 unread"
# review: new
list-counts = { $messages }, 읽지 않음 { $unread }개
# review: new
list-counts-selected = { $messages }, 읽지 않음 { $unread }개, 선택됨 { $selected }개
# the status bar while searching: "12 found, 3 unread"
# review: new
list-counts-found = { $found }개 찾음, 읽지 않음 { $unread }개
# review: new
list-counts-found-selected = { $found }개 찾음, 읽지 않음 { $unread }개, 선택됨 { $selected }개
# review: new
list-counts-none = 찾은 메시지 없음

## 특수 폴더 (Outlook Express의 이름)

# review: new
folder-inbox = 받은 편지함
# review: new
folder-sent = 보낸 편지함
# review: new
folder-deleted = 지운 편지함
# review: new
folder-drafts = 임시 보관함
# review: new
folder-junk = 정크 메일
# review: new
folder-archive = 보관

## 읽기 창

# review: new
reader-no-message = 선택한 메시지가 없습니다.
# review: new
reader-downloading = 메시지를 다운로드하는 중…
# review: new
reader-downloading-detail = 다운로드가 완료되면 여기에 메시지가 표시됩니다.
# review: new
reader-downloading-size = 메시지 크기는 { $size }입니다. 다운로드되면 여기에 표시됩니다.
# review: new
reader-failed = 메시지를 다운로드할 수 없습니다
# review: new
reader-failed-network = 메일 서버에 연결할 수 없거나 연결이 끊어졌습니다({ $reason }).
# review: new
reader-failed-sign-in = 메일 서버가 로그인을 받아들이지 않았습니다({ $reason }). 계정 설정에서 암호를 확인하거나 다시 로그인하십시오.
# review: new
reader-failed-security = 메일 서버와 보안 연결을 설정할 수 없습니다({ $reason }).
# review: new
reader-failed-other = 메일 서버의 응답: { $reason }.
# review: new
reader-retry-note = 계정이 다시 연결되면 다시 시도합니다.
# review: new
reader-unreadable = 이 메시지를 표시할 수 없습니다: { $error }
# review: new
message-source-title = 메시지 원본: { $subject }
# review: new
message-source-untitled = 메시지 원본

## 메시지 인쇄, 회신 또는 전달에 인용된 메시지의 헤더

# review: new
header-from = 보낸 사람
# review: new
header-date = 날짜
# review: new
header-to = 받는 사람
# review: new
header-cc = 참조
# review: new
header-sent = 보낸 날짜
# review: new
header-subject = 제목
# review: new
header-security = 보안
# review: new
header-part = 부분 { $number }
# review: new
quote-original = ----- 원본 메시지 -----
# review: new
fold-show-earlier = 이전 메시지 표시

## 반송: 메시지가 배달되지 않았다는 알림 맨 위의 카드

# review: new
bounce-failed = 메시지가 배달되지 않았습니다
# review: new
bounce-delayed = 메시지가 아직 배달되지 않았습니다
# review: new
bounce-delayed-note = 메일 서버가 계속 배달을 시도하고 있습니다. 다시 보낼 필요는 없습니다.
# the link to the message the notice is about, in Sent Items or another folder
# review: new
bounce-show-message = 반송된 메시지 표시
# the link of a delay's card to the message that is still on its way
# review: new
bounce-show-delayed = 지연된 메시지 표시
# review: new
bounce-what-to-do = 할 수 있는 작업:
# what to do about a recipient the message is still on its way to: in the card of a delay, and in the card of a failure
# review: new
bounce-delayed-do = 아직은 할 일이 없습니다. 끝내 배달되지 않으면 다시 알림을 받게 됩니다.
# review: new
bounce-delayed-row-do = 아직은 할 일이 없습니다. 메일 서버가 계속 배달을 시도하고 있으며, 배달할 수 없으면 다시 알림을 받게 됩니다.
# folds the receiving server's own words
# review: new
bounce-details = 세부 정보
# a recipient the notice does not name
# review: new
bounce-someone = 받는 사람
# in Details: the server that refused the message, the status code it gave, and the server that wrote the notice
# review: new
bounce-server = 서버: { $server }
# review: new
bounce-status = 상태: { $status }
# review: new
bounce-reported-by = 보고한 서버: { $server }
# review: new
bounce-retry-minutes = 받는 서버가 다음 시도까지 { $count }분 기다리도록 요청했습니다.
# review: new
bounce-retry-hours = 받는 서버가 다음 시도까지 { $count }시간 기다리도록 요청했습니다.
# the names of the blocklists, "Spamhaus ZEN, Barracuda"
# review: new
bounce-blocklist = 차단 목록: { $lists }
# review: new
bounce-user-unknown = 주소가 존재하지 않습니다
# review: new
bounce-user-unknown-why = 받는 서버에 이 주소의 사서함이 없습니다. 주소를 잘못 입력했거나 상대방이 더 이상 이 주소를 쓰지 않을 수 있습니다.
# review: new
bounce-user-unknown-do = 주소의 철자를 확인하거나, 상대방에게 지금 사용하는 주소를 물어보십시오.
# review: new
bounce-invalid-address = 주소가 올바르지 않습니다
# review: new
bounce-invalid-address-why = 메일을 보낼 수 있는 형식으로 쓴 주소가 아닙니다.
# review: new
bounce-invalid-address-do = 공백, 빠진 글자, @ 뒤에 아무것도 없는 경우 같은 입력 실수가 있는지 확인하십시오.
# review: new
bounce-mailbox-disabled = 사서함이 닫혔습니다
# review: new
bounce-mailbox-disabled-why = 주소는 존재하지만 사서함이 꺼져 있거나 더 이상 사용되지 않습니다.
# review: new
bounce-mailbox-disabled-do = 다른 방법으로 상대방에게 연락하여 지금 사용하는 주소를 물어보십시오.
# review: new
bounce-mailbox-full = 사서함이 가득 찼습니다
# review: new
bounce-mailbox-full-why = 받는 사람의 사서함에 새 메일을 받을 공간이 없습니다.
# review: new
bounce-mailbox-full-do = 며칠 후에 다시 보내거나, 다른 방법으로 상대방에게 알리십시오.
# review: new
bounce-spam-blocked = 스팸으로 거부됨
# review: new
bounce-spam-blocked-why = 받는 서버가 메시지를 스팸으로 판단했습니다.
# review: new
bounce-spam-blocked-do = 많은 링크, 단축 링크, 큰 첨부 파일처럼 스팸으로 보이는 요소를 빼고 다시 보내십시오. 계속 이런 일이 생기면 메일 공급자에게 문의하십시오.
# review: new
bounce-virus-detected = 바이러스로 거부됨
# review: new
bounce-virus-detected-why = 받는 서버가 메시지나 첨부 파일에서 바이러스 또는 기타 유해한 콘텐츠를 발견했다고 보고했습니다.
# review: new
bounce-virus-detected-do = 바이러스 검사 프로그램으로 첨부 파일을 검사하십시오. 일부 서버는 모든 프로그램이나 압축 파일을 거부하므로, 이런 파일은 링크로 공유하십시오.
# review: new
bounce-ip-blocklisted = 메일 서버가 차단 목록에 있습니다
# review: new
bounce-ip-blocklisted-why = 메시지를 보낸 서버의 주소가 차단 목록에 있어서, 받는 서버가 그 서버에서 오는 메일을 거부합니다.
# review: new
bounce-ip-blocklisted-do = 메시지에는 문제가 없습니다. 이 알림을 메일 공급자에게 전달하고 서버를 목록에서 제거해 달라고 요청하십시오.
# review: new
bounce-domain-blocklisted = 도메인이 차단 목록에 있습니다
# review: new
bounce-domain-blocklisted-why = 주소의 도메인 또는 메시지의 링크에 있는 도메인이 차단 목록에 있어서, 받는 서버가 메시지를 거부합니다.
# review: new
bounce-domain-blocklisted-do = 메시지에 링크가 있으면 링크 없이 보내 보십시오. 그렇지 않으면 도메인의 메일을 관리하는 사람에게 이 알림을 전달하십시오.
# review: new
bounce-policy-blocked = 받는 서버의 규칙으로 거부됨
# review: new
bounce-policy-blocked-why = 크기, 첨부 파일, 보낸 사람 등의 이유로 받는 서버의 규칙이 이 메시지를 통과시키지 않습니다.
# review: new
bounce-policy-blocked-do = 세부 정보에 있는 서버의 메시지에 이유가 나와 있는 경우가 많습니다. 받는 사람에게 이런 메일을 받을 수 있는지 물어보십시오.
# review: new
bounce-geo-blocked = 보낸 위치 때문에 거부됨
# review: new
bounce-geo-blocked-why = 받는 서버가 메일 서버가 있는 국가나 네트워크에서 오는 메일을 받지 않습니다.
# review: new
bounce-geo-blocked-do = 다른 방법으로 상대방에게 연락하거나 메일 공급자에게 문의하십시오.
# review: new
bounce-relay-denied = 서버가 메시지를 전달하지 않았습니다
# review: new
bounce-relay-denied-why = 서버가 메시지를 다음 서버로 전달하기를 거부했습니다. 로그인하지 않고 보냈거나 이 받는 사람을 처리하지 않는 서버를 통해 보낸 경우가 많습니다.
# review: new
bounce-relay-denied-do = 계정 설정에서 보내는 메일 서버와 로그인 정보를 확인하십시오.
# review: new
bounce-auth-failure = 보낸 사람 주소를 확인할 수 없습니다
# review: new
bounce-auth-failure-why = 받는 서버가 메시지가 정말로 내 도메인에서 왔는지 확인할 수 없었습니다(SPF, DKIM 또는 DMARC).
# review: new
bounce-auth-failure-do = 도메인의 메일을 관리하는 사람에게 이 알림을 전달하십시오. 도메인 설정을 고쳐야 합니다. 그동안에는 공급자의 서버를 통해 보내면 도움이 될 수 있습니다.
# review: new
bounce-rate-limited = 한 번에 너무 많은 메일
# review: new
bounce-rate-limited-why = 받는 서버가 당분간 메일 서버에서 받는 메시지 수를 줄이고 있습니다.
# review: new
bounce-rate-limited-do = 잠시 기다렸다가 다시 보내십시오. 많은 사람에게 보낼 때는 한 번에 보내는 수를 줄이십시오.
# review: new
bounce-greylisting = 잠시 보류됨
# review: new
bounce-greylisting-why = 받는 서버가 알 수 없는 보낸 사람에게 잠시 후에 다시 시도하도록 요청합니다. 스팸을 막기 위한 흔한 검사입니다.
# review: new
bounce-greylisting-do = 일시적인 지연이면 보내는 서버가 보통 다시 시도합니다. 이 알림이 최종 실패를 알리는 경우 나중에 메시지를 다시 보내 보십시오.
# review: new
bounce-server-error = 받는 서버에 문제가 있습니다
# review: new
bounce-server-error-why = 받는 서버에 연결할 수 없거나, 서버 자체의 문제로 메시지를 받을 수 없었습니다.
# review: new
bounce-server-error-do = 나중에 다시 보내십시오. 계속 실패하면 주소에서 @ 뒷부분에 입력 실수가 있는지 확인하십시오.
# review: new
bounce-unknown = 배달되지 않음
# review: new
bounce-unknown-why = 알림에 이유가 분명히 나와 있지 않습니다.
# review: new
bounce-unknown-do = 세부 정보에 있는 서버의 메시지에서 더 알 수 있을 수도 있습니다. 도움이 되지 않으면 이 알림을 메일 공급자에게 전달하십시오.

## 여러 메시지를 선택한 경우

# review: new
selection-title = 메시지 { $count }개 선택됨
# review: new
selection-unread = 읽지 않음 { $count }개
# review: new
selection-flagged = 플래그 지정됨 { $count }개
# review: new
delete-for-good-one = 이 메시지는 영구히 삭제됩니다. 삭제하시겠습니까?
# review: new
delete-for-good-all = 이 메시지 { $count }개는 영구히 삭제됩니다. 삭제하시겠습니까?
# review: new
delete-for-good-some = 메시지 { $total }개 중 { $count }개는 영구히 삭제됩니다. 메시지를 삭제하시겠습니까?
# review: new
done-read = { $count ->
   *[other] { $messages }를 읽은 상태로 표시했습니다
}
# review: new
done-unread = { $count ->
   *[other] { $messages }를 읽지 않은 상태로 표시했습니다
}
# review: new
done-flagged = { $count ->
   *[other] { $messages }에 플래그를 지정했습니다
}
# review: new
done-unflagged = { $messages }의 플래그를 지웠습니다
# review: new
done-deleted-for-good = { $count ->
   *[other] { $messages }를 영구히 삭제했습니다
}
# review: new
done-archived = { $count ->
   *[other] { $messages }를 보관했습니다
}
# review: new
done-moved = { $count ->
   *[other] { $messages }를 { $folder }(으)로 이동했습니다
}
# review: new
done-copied = { $count ->
   *[other] { $messages }를 { $folder }에 복사했습니다
}
# review: new
done-moving = { $count ->
   *[other] { $messages }를 { $folder }(으)로 이동하는 중...
}
# review: new
done-copying = { $count ->
   *[other] { $messages }를 { $folder }에 복사하는 중...
}
# review: new
done-moved-back = { $count ->
   *[other] { $messages }를 { $folder }(으)로 다시 옮겼습니다
}
# the status bar after Watch Conversation and Ignore Conversation, and after either again on a marked one
# review: new
done-watched = { $count ->
    [1] 대화를 지켜봅니다
   *[other] 대화 { $count }개를 지켜봅니다
}
# review: new
done-unwatched = { $count ->
    [1] 대화 지켜보기를 중지했습니다
   *[other] 대화 { $count }개 지켜보기를 중지했습니다
}
# review: new
done-ignored = { $count ->
    [1] 대화를 무시합니다
   *[other] 대화 { $count }개를 무시합니다
}
# review: new
done-unignored = { $count ->
    [1] 대화 무시를 중지했습니다
   *[other] 대화 { $count }개 무시를 중지했습니다
}
# review: new
their-folders = 원래 폴더
# review: new
undo-move = 이동 취소
# review: new
undo-delete = 삭제 취소
# review: new
undo-archive = 보관 취소
# review: new
undo-junk = 정크 메일로 표시 취소
# review: new
undo-not-junk = 정크 메일 아님으로 표시 취소
# review: new
undo-send = 보내기 취소
# review: new
nothing-to-undo = 취소할 작업이 없습니다.
# review: new
messages-gone = 메시지가 더 이상 없습니다.
# A non-selectable IMAP folder cannot contain messages; this does not mean it is empty.
# review: new
folder-holds-no-messages = 이 폴더에는 메시지를 넣을 수 없습니다.
# review: new
not-archived-here = 이 폴더의 메시지는 보관할 수 없습니다.
# review: new
not-emptied-here = 지운 편지함과 정크 메일만 비울 수 있습니다.
# review: new
next-unread-question = { $folder }에 읽지 않은 메시지가 더 이상 없습니다.

    읽지 않은 메시지가 있는 다음 폴더인 { $next }(으)로 이동하시겠습니까?
# review: new
no-unread-left = 읽지 않은 메시지가 더 이상 없습니다.
# review: new
empty-question = { $count ->
    [1] { $folder }을(를) 비우시겠습니까?

        안에 있는 메시지가 영구히 삭제됩니다. 되돌릴 수 없습니다.
   *[other] { $folder }을(를) 비우시겠습니까?

        안에 있는 { $messages }가 영구히 삭제됩니다. 되돌릴 수 없습니다.
}
# review: new
no-junk-folder = 이 계정에는 메시지를 옮길 정크 메일 폴더가 없습니다.
# review: new
no-inbox-folder = 이 계정에는 메시지를 옮길 받은 편지함 폴더가 없습니다.
# the status bar after a flag in a colour: "Flagged 2 messages blue"
# review: new
done-flagged-color = { $messages }에 { $color ->
    [red] 빨간색
    [orange] 주황색
    [yellow] 노란색
    [green] 초록색
    [blue] 파란색
    [purple] 보라색
   *[gray] 회색
} 플래그를 지정했습니다
# the Flag menu: the colours of Apple Mail's flags
# review: new
flag-color = { $color ->
    [red] 빨간색
    [orange] 주황색
    [yellow] 노란색
    [green] 초록색
    [blue] 파란색
    [purple] 보라색
   *[gray] 회색
}

## 이동 및 복사 창

# review: new
move-window-title-move = { $count ->
    [1] 메시지 이동
   *[other] 메시지 { $count }개 이동
}
# review: new
move-window-title-copy = { $count ->
    [1] 메시지 복사
   *[other] 메시지 { $count }개 복사
}
# review: new
move-window-prompt-move = { $count ->
    [1] 선택한 메시지를 이동할 위치:
   *[other] 선택한 메시지 { $count }개를 이동할 위치:
}
# review: new
move-window-prompt-copy = { $count ->
    [1] 선택한 메시지를 복사할 위치:
   *[other] 선택한 메시지 { $count }개를 복사할 위치:
}
# the folders used last, over the folder tree
# review: new
targets-recent = 최근 항목
# the folder the messages are in, which can not be chosen
# review: new
target-current = { $folder } (현재)
# a folder used last, with its account when there are several: "Archive (Work)"
# review: new
target-recent = { $folder } ({ $account })

## 다른 계정으로 이동 및 복사

# review: new
transfer-moving = { $messages } 중 { $done }개를 { $folder }(으)로 이동하는 중...
# review: new
transfer-copying = { $messages } 중 { $done }개를 { $folder }에 복사하는 중...
# review: new
transfer-another-account = 다른 계정
# review: new
transfer-folder-gone = 대상 폴더가 더 이상 없습니다
# review: new
transfer-not-on-server = 메시지가 더 이상 서버에 없습니다
# review: new
transfer-not-moved = { $count ->
   *[other] { $messages }를 다른 계정으로 이동할 수 없습니다: { $reason }
}
# review: new
transfer-not-copied = { $count ->
   *[other] { $messages }를 다른 계정에 복사할 수 없습니다: { $reason }
}
# review: new
transfer-none-moved = 이동할 수 있는 메시지가 없습니다
# review: new
transfer-none-copied = 복사할 수 있는 메시지가 없습니다

## 파일로서의 메시지

# review: new
export-not-in-time = 메시지를 제시간에 다운로드할 수 없습니다
# review: new
export-not-saved = { $messages } 중 { $failed }개를 저장할 수 없습니다({ $problems })
# review: new
export-not-attached = 메시지를 첨부할 수 없습니다: { $error }
# the status bar after Save As with several: "Saved 3 messages to Desktop"
# review: new
saved-to = { $count ->
   *[other] { $messages }를 { $folder }에 저장했습니다
}
# review: new
download-progress = { $total }개 중 { $done }개 다운로드 중
# review: new
download-done = { $size } 다운로드함
# review: new
downloading-messages = { $count ->
   *[other] { $messages }를 다운로드하는 중...
}
# the status bar after files are dropped on a folder: "Put 3 messages in Archive"
# review: new
import-put = { $count ->
   *[other] { $messages }를 { $folder }(으)로 가져오도록 대기열에 추가했습니다
}
# review: new
import-not-put = 다음 항목은 폴더에 넣지 못했습니다:

    { $problems }

## 창에 표시되는 문제

# review: new
error-store = 로컬 저장소: { $error }
# review: new
error-not-found = 찾을 수 없음
# review: new
error-closed = 종료하는 중
# review: new
error-other-account = 브라우저가 이 계정이 아닌 { $email }(으)로 로그인했습니다
# a password or sign-in the mail server refused, with the server's words
# review: new
failure-authentication = 서버가 로그인을 받아들이지 않았습니다({ $reason })
# the mail server could not be reached or the connection broke, with the reason
# review: new
failure-network = 서버에 연결하지 못했습니다({ $reason })
# review: new
error-in-use = 이 앱으로 로그인하는 계정이 있는 동안에는 제거할 수 없습니다: { $accounts }
# review: new
error-turned-off = 이 로그인 앱은 새 계정에 대해 꺼져 있습니다
# review: new
error-folder-name = 폴더 이름은 1~200자여야 하며 제어 문자를 포함할 수 없습니다
# review: new
error-folder-separator = 이 서버에서는 폴더 이름에 “{ $separator }”을(를) 쓸 수 없습니다
# review: new
error-folder-special = 받은 편지함과 특수 폴더는 이름을 바꾸거나 삭제할 수 없습니다
# review: new
error-no-recipients = 메시지에 받는 사람이 없습니다
# review: new
error-bad-address = “{ $address }”은(는) 전자 메일 주소가 아닙니다
# review: new
error-not-own-address = { $address }은(는) 이 계정의 보낸 사람 주소가 아닙니다. 계정 속성의 “보낼 때 사용하는 다른 주소”에 추가하십시오.
# review: new
rule-query-refused = 규칙은 폴더나 날짜로 필터링할 수 없습니다({ $words }).
# review: new
rule-no-query = 받는 메시지에 대한 검색 조건을 입력하십시오.
# review: new
rule-no-action = 규칙의 작업을 하나 이상 선택하십시오.
# review: new
error-attachment = { $path }을(를) 읽을 수 없습니다: { $error }
# review: new
error-no-drafts = 계정에 메시지를 저장할 임시 보관함 폴더가 없습니다
# review: new
error-draft-attachment = 초안의 첨부 파일을 유지할 수 없습니다: { $error }
# review: new
error-password-not-saved = 다음 시작을 위해 암호를 저장할 수 없습니다: { $error }
# review: new
error-sign-in-not-saved = 다음 시작을 위해 새 로그인 정보를 저장할 수 없습니다: { $error }
# review: new
error-import-unreadable = { $path }을(를) 읽을 수 없습니다: { $error }
# review: new
error-import-too-large = { $path }이(가) 50MB보다 큽니다
# review: new
error-import-not-mail = { $path }은(는) 전자 메일 메시지가 아닙니다
# review: new
error-list-answered = 메일링 리스트 서버가 상태 { $status }을(를) 반환했습니다
# review: new
error-not-built = 메시지를 만들 수 없습니다
# review: new
error-outbox-waits = { $count ->
    [1] 메시지가 보낼 편지함에 남아 있습니다. 다음 보내기/받기 때 다시 보내려고 시도합니다
   *[other] 메시지 { $count }개가 보낼 편지함에 남아 있습니다. 다음 보내기/받기 때 다시 보내려고 시도합니다
}
# review: new
error-draft-not-removed = 메시지의 이전 초안을 임시 보관함에서 제거할 수 없습니다: { $reason }
# review: new
error-sent-but = 메시지를 보냈지만 문제가 있습니다: { $problem }
# review: new
error-sent-still-in-outbox = 메시지가 아직 보낼 편지함에 있습니다: { $error }
# review: new
error-sent-no-copy = 보낸 편지함에 사본을 저장할 수 없습니다: { $reason }
# review: new
error-no-password = 이 계정의 암호가 없습니다
# review: new
error-no-sign-in = 이 계정의 로그인 정보가 없습니다
# review: new
error-provider-missing = 이 빌드에서는 로그인 앱을 사용할 수 없습니다(ID: { $provider }). 제거되었을 수 있습니다
# review: new
error-provider-servers = 이 계정의 서버가 로그인 앱의 서버와 일치하지 않습니다
# review: new
error-app-scopes = { $reason }. 메일 서버가 로그인 앱의 토큰을 받아들이지 않았습니다. 앱의 범위가 메일 액세스를 허용하는지 확인하십시오
# review: new
error-in-folder = { $folder }: { $reason }

## 로그인 앱

# review: new
sign-in-off-google = 기본 제공 Google 로그인 앱은 승인된 테스트 사용자용으로 설정되어 있으며, 기본적으로 새 계정에 대해 꺼져 있습니다. 테스트 사용자는 로그인 앱(파일 > 계정)에서 켤 수 있습니다. 직접 만든 Google 로그인 앱을 사용하거나, 계정에서 지원하는 경우 앱 암호를 사용할 수도 있습니다.
# review: new
sign-in-off-other = 새 계정에 대해 꺼져 있습니다. 로그인 앱(파일 > 계정)에서 켤 수 있습니다.
# review: new
sign-in-app-no-name = 로그인 앱에 이름이 필요합니다
# review: new
sign-in-app-no-client = 클라이언트 ID가 없습니다
# review: new
sign-in-app-no-scopes = 로그인 앱에 메일 액세스를 허용하는 범위가 필요합니다
# review: new
sign-in-app-bad-host = { $server } 서버 주소가 없거나 올바른 호스트 이름이 아닙니다
# review: new
sign-in-app-plain = { $server } 서버는 SSL/TLS 또는 STARTTLS를 사용해야 합니다
# review: new
sign-in-app-not-checked = 아직 발급자를 확인하지 않았습니다
# review: new
sign-in-app-issuer-changed = 발급자가 변경되었습니다. 클라이언트 암호를 다시 입력하거나 제거하십시오
# review: new
sign-in-register-google = Google Cloud Console에서 데스크톱 앱 유형의 OAuth 클라이언트를 만들고, 동의 화면에 https://mail.google.com/ 범위를 추가하십시오. 앱이 테스트 중인 동안에는 테스트 사용자만 로그인할 수 있습니다.
# review: new
sign-in-register-microsoft = Microsoft Entra에서 모바일 및 데스크톱 애플리케이션 플랫폼으로 앱을 등록하고, 리디렉션 URI http://localhost, 공용 클라이언트 흐름 허용, 위임된 권한 IMAP.AccessAsUser.All, SMTP.Send, offline_access를 설정하십시오. 조직 전용으로 사용하려면 발급자로 https://login.microsoftonline.com/<테넌트 ID>/v2.0을 사용하십시오.
# review: new
sign-in-register-other = 아래 리디렉션 URI로 네이티브(공용) 클라이언트를 등록하십시오. 공급자는 이 URI에서 모든 포트를 허용해야 합니다(RFC 8252). 공급자가 메일 액세스를 허용하는 범위를 추가하십시오.

## 일정 초대

# review: new
repeats = 반복
# review: new
repeats-every = { $unit ->
    [day] { $interval ->
        [1] 매일
       *[other] { $interval }일마다
    }
    [week] { $interval ->
        [1] 매주
       *[other] { $interval }주마다
    }
    [month] { $interval ->
        [1] 매월
       *[other] { $interval }개월마다
    }
   *[year] { $interval ->
        [1] 매년
       *[other] { $interval }년마다
    }
}
# "Every week on Monday, Wednesday"
# review: new
repeats-on = { $repeats } { $days }
# "Every week, 10 times"
# review: new
repeats-times = { $repeats }, { $count }회
# review: new
day-monday = 월요일
# review: new
day-tuesday = 화요일
# review: new
day-wednesday = 수요일
# review: new
day-thursday = 목요일
# review: new
day-friday = 금요일
# review: new
day-saturday = 토요일
# review: new
day-sunday = 일요일

## AI 에이전트

# review: new
agent-level-read = 메일 읽기: 폴더, 메시지 목록, 대화, 검색, 메시지와 첨부 파일, 메시지 규칙, 메일을 주고받는 사람
# review: new
agent-level-organize = 메일 정리: 읽음 상태, 플래그와 플래그 색, 정크 메일, 이동, 보관, 폴더 만들기 및 이름 바꾸기, 대화 지켜보기 및 무시, 지운 편지함으로 삭제, 사용자가 승인한 후 메일링 리스트 탈퇴
# review: new
agent-level-drafts = 사용자가 보낼 초안 작성
# review: new
agent-level-send = 메일 보내기(메시지마다 사용자가 승인한 후에만)
# review: new
agent-connect-title = { $program }이(가) 메일을 사용하려고 합니다
# review: new
agent-connect-detail = AI 에이전트가 Inbox Classic과 함께 작업하려고 요청했습니다. 에이전트가 할 수 있는 작업과 볼 수 있는 계정을 선택하십시오. 나중에 도구 > AI 에이전트에서 변경할 수 있습니다.

    에이전트는 다른 사람이 쓴 메일을 읽으며, 메시지가 에이전트를 속이려 할 수도 있습니다. 에이전트가 무엇이든 보내기 전에 Inbox Classic이 항상 먼저 묻습니다.
# review: new
agent-reply-to = “{ $subject }”에 대한 회신
# review: new
agent-reply-all-on = “{ $subject }”에 대한 전체 회신
# review: new
agent-forward-of = “{ $subject }” 전달
# review: new
agent-never-written-one = { $address }에 메일을 보낸 적이 없습니다.
# review: new
agent-never-written-many = 이 주소 중 { $count }개에는 메일을 보낸 적이 없습니다.
# review: new
agent-send-title = { $program }이(가) 이 메시지를 보내려고 합니다
# review: new
agent-send-detail = 받는 사람과 메시지 내용을 확인하십시오. 확인하면 메시지는 보낼 편지함에서 { $seconds }초 동안 대기하며, 그동안 삭제할 수 있습니다.
# review: new
agent-change-title = { $program }이(가) 할 수 있는 작업
# review: new
agent-change-allowed = 이 프로그램의 AI 에이전트가 메일로 할 수 있는 작업을 변경합니다.
# review: new
agent-change-refused = 이 프로그램의 액세스를 거부했습니다. 에이전트가 다시 메일에 액세스하도록 하려면 허용하십시오.
# review: new
agent-log-taken-back = { $entry } (되돌림)
# review: new
agent-files = 파일: { $files }
# review: new
agent-undo-refused = 되돌릴 수 없습니다.
# review: new
agent-undo-refused-why = 되돌릴 수 없습니다: { $reason }.
# review: new
agent-undo-impossible = 이 작업은 되돌릴 수 없습니다
# review: new
agent-undo-not-in-folder = 메시지가 더 이상 그 폴더에 없습니다
# review: new
agent-undo-not-arrived = 메시지가 (아직) 이동한 폴더에 없습니다
# review: new
agent-undo-sent = 메시지가 더 이상 보낼 편지함에 없습니다
# review: new
agent-original-not-downloaded = 원본 메시지를 아직 다운로드하지 않았습니다. 먼저 메시지를 여십시오
# review: new
agent-turned-away = 거부됨
# review: new
agent-can-nothing = 없음
# review: new
agent-can-read = 읽기
# review: new
agent-can-organize = 정리
# review: new
agent-can-drafts = 초안 작성
# review: new
agent-can-send = 승인 후 보내기
# "Read, organize and write drafts"
# review: new
agent-can-list = { $first } 및 { $last }
# review: new
agent-accounts = { $count ->
    [0] 계정 없음
   *[other] 계정 { $count }개
}
# "Read and organize; 1 account"
# review: new
agent-access = { $can }; { $accounts }
# review: new
agent-unreadable = 이 메시지를 읽을 수 없습니다.
# review: new
agent-encrypted-original = 이 메시지는 암호화되어 있습니다. 에이전트는 암호화할 수 없으므로 이 메시지에 회신하거나 전달할 수 없습니다.
# review: new
agent-encrypted = 이 메시지는 암호화되어 있습니다. AI 에이전트는 내용을 읽을 수 없습니다. 직접 읽으려면 Inbox Classic에서 여십시오.
# review: new
agent-too-many-changes = 지난 30일 동안 변경이 너무 많습니다. 이 에이전트는 Inbox Classic이 한 프로그램에 대해 기록에 보관하는 만큼 변경했습니다. 가장 오래된 변경이 30일이 지나면 더 변경할 수 있습니다.
# review: new
agent-too-many-reads = 지난 30일 동안 읽기가 너무 많습니다. 이 에이전트는 Inbox Classic이 한 프로그램에 대해 기록에 보관하는 만큼 읽었습니다. 가장 오래된 읽기가 30일이 지나면 더 읽을 수 있습니다.
# review: new
list-encrypted = 암호화된 메시지
# review: new
agent-log-composed = 사용자가 마무리할 수 있도록 “{ $subject }” 메시지를 새 메시지 창에 열었습니다
# review: new
agent-log-refused = “{ $subject }” 메시지를 보내지 않았습니다
# review: new
agent-log-sent = { $to }에게 보낼 “{ $subject }” 메시지를 보낼 편지함에 넣었습니다
# review: new
agent-log-draft = “{ $subject }” 초안을 저장했습니다
# review: new
agent-log-draft-replaced = “{ $subject }” 초안을 바꿨습니다
# review: new
agent-log-draft-discarded = “{ $subject }” 초안의 삭제를 요청했습니다
# review: new
agent-draft-note = AI 에이전트인 { $program }이(가) 이 초안을 작성했습니다. 보내기 전에 받는 사람과 텍스트를 확인하십시오.
# review: new
agent-log-read = “{ $subject }” 메시지를 읽은 상태로 표시했습니다
# review: new
agent-log-unread = “{ $subject }” 메시지를 읽지 않은 상태로 표시했습니다
# review: new
agent-log-flagged = “{ $subject }” 메시지에 플래그를 지정했습니다
# review: new
agent-log-unflagged = “{ $subject }” 메시지의 플래그를 지웠습니다
# review: new
agent-log-deleted = “{ $subject }” 메시지를 삭제했습니다
# review: new
agent-log-moved = “{ $subject }” 메시지를 { $folder }(으)로 이동했습니다
# review: new
agent-log-junk = “{ $subject }” 메시지를 정크 메일로 표시했습니다
# review: new
agent-log-not-junk = “{ $subject }” 메시지를 정크 메일 아님으로 표시했습니다
# review: new
agent-log-archived = “{ $subject }” 메시지를 보관했습니다
# review: new
agent-log-folder = “{ $name }” 폴더 만들기를 요청했습니다
# written at the user's yes, before the list is asked; a list that fails replaces it with agent-log-unsubscribe-failed
# review: new
agent-log-unsubscribed = 메시지 “{ $subject }”의 메일링 리스트 구독 취소를 승인했습니다
# review: new
agent-log-unsubscribe-failed = 메시지 “{ $subject }”의 메일링 리스트에서 구독을 취소할 수 없습니다: { $reason }
# "You did not unsubscribe from news@shop.example, deals@example.com": the lists' addresses, never their names
# review: new
agent-log-unsubscribe-refused = 다음 보낸 사람의 구독 취소 요청을 승인하지 않았습니다: { $senders }
# review: new
agent-unsubscribe-title = { $count ->
    [1] { $program }이(가) 메일링 리스트 구독을 취소하려고 합니다
   *[other] { $program }이(가) 메일링 리스트 { $count }개의 구독을 취소하려고 합니다
}
# review: new
agent-unsubscribe-detail = { $count ->
    [1] Inbox Classic이 아래 리스트가 제공하는 원클릭 방식으로 메일 발송 중지를 요청합니다. 그 밖에는 아무것도 보내지 않으며, 가지고 있는 메시지는 그대로 남습니다.
   *[other] Inbox Classic이 아래 각 리스트가 제공하는 원클릭 방식으로 메일 발송 중지를 요청합니다. 그 밖에는 아무것도 보내지 않으며, 가지고 있는 메시지는 그대로 남습니다.
}
# review: new
agent-log-flag-color = “{ $subject }” 메시지에 { $color ->
    [red] 빨간색
    [orange] 주황색
    [yellow] 노란색
    [green] 초록색
    [blue] 파란색
    [purple] 보라색
   *[gray] 회색
} 플래그를 지정했습니다
# review: new
agent-log-renamed = “{ $old }” 폴더의 이름을 “{ $name }”(으)로 바꾸도록 요청했습니다
# review: new
agent-log-watched = “{ $subject }” 대화를 지켜보기 시작했습니다
# review: new
agent-log-ignored = “{ $subject }” 대화를 무시하기 시작했습니다
# review: new
agent-log-unmarked = “{ $subject }” 대화 지켜보기 또는 무시를 중지했습니다
# the reason one change can not be taken back (agent-undo-refused-why)
# review: new
agent-undo-changed = 그 이후 메시지가 변경되었습니다
# one change of many messages an agent made with a search (apply_to_search), a row of the log; { $query } is the search
# review: new
agent-log-bulk-read = 메시지 { $count }개를 읽은 상태로 표시했습니다(검색: { $query })
# review: new
agent-log-bulk-unread = 메시지 { $count }개를 읽지 않은 상태로 표시했습니다(검색: { $query })
# review: new
agent-log-bulk-flagged = 메시지 { $count }개에 플래그를 지정했습니다(검색: { $query })
# review: new
agent-log-bulk-unflagged = 메시지 { $count }개의 플래그를 지웠습니다(검색: { $query })
# review: new
agent-log-bulk-color = 메시지 { $count }개에 { $color ->
    [red] 빨간색
    [orange] 주황색
    [yellow] 노란색
    [green] 초록색
    [blue] 파란색
    [purple] 보라색
   *[gray] 회색
} 플래그를 지정했습니다(검색: { $query })
# review: new
agent-log-bulk-moved = 메시지 { $count }개를 { $folder }(으)로 이동했습니다(검색: { $query })
# review: new
agent-log-bulk-archived = 메시지 { $count }개를 보관했습니다(검색: { $query })
# review: new
agent-log-bulk-junk = 메시지 { $count }개를 정크 메일로 표시했습니다(검색: { $query })
# review: new
agent-log-bulk-not-junk = 메시지 { $count }개를 정크 메일 아님으로 표시했습니다(검색: { $query })
# review: new
agent-log-bulk-deleted = 메시지 { $count }개를 삭제했습니다(검색: { $query })
# Undo Everything Since in the AI Agents window: how far back it reaches
# review: new
agent-undo-span = { $span ->
    [quarter] 지난 15분
    [hour] 지난 1시간
    [hours] 지난 4시간
    [day] 지난 24시간
    [week] 지난 7일
   *[all] 지난 30일
}
# the question before it takes back what a program did in the span chosen
# review: new
agent-undo-since-question = { $count ->
    [0] { $program }에는 이 기간에 되돌릴 수 있는 변경 내용이 없습니다.
    [1] 이 기간에 { $program }에 대해 기록된 변경 내용을 되돌려 보시겠습니까?
   *[other] 이 기간에 { $program }에 대해 기록된 변경 내용 { $count }개를 되돌려 보시겠습니까?
}
# review: new
agent-undo-since-detail = Inbox Classic은 폴더, 읽음 상태, 플래그를 복원하고 아직 보낼 편지함에서 대기 중인 메시지를 삭제하려고 시도합니다. 더 이상 되돌릴 수 없는 변경 내용은 건너뜁니다. 나중에 바뀐 일부 플래그 색은 덮어쓸 수 있습니다.
# what taking back did, then a line for each kind of message it left as it is
# review: new
agent-undo-done = { $count ->
    [0] 되돌린 것이 없습니다.
   *[other] 기록된 변경 내용 { $count }개를 전부 또는 일부 되돌렸습니다.
}
# review: new
agent-undo-left-gone = 메시지 { $count }개가 더 이상 변경으로 옮겨진 위치에 없었습니다.
# review: new
agent-undo-left-changed = 메시지 { $count }개는 그 이후 사용자나 서버에서 변경되었으므로 그대로 두었습니다.
# review: new
agent-undo-left-sent = 메시지 { $count }개는 이미 보낼 편지함을 떠났습니다.
# review: new
agent-undo-left-impossible = 변경 내용 { $count }개는 되돌릴 수 없습니다.
# the Send question of an agent's answer to a calendar invitation: what it answers, and when the event is
# review: new
agent-invitation-reply = { $response ->
    [accept] 이 메시지는 초대 “{ $summary }”({ $when })을(를) 수락합니다.
    [tentative] 이 메시지는 초대 “{ $summary }”({ $when })을(를) 미정으로 수락합니다.
   *[decline] 이 메시지는 초대 “{ $summary }”({ $when })을(를) 거절합니다.
} 메시지는 초대에 지정된 주최자에게 전송됩니다. 메일 서버가 메시지를 받아들이면 주최자의 캘린더에서 확인하지 않고도 로컬 응답이 바뀝니다.
# the subject of an answer to an invitation, as calendar programs write it
# review: new
invitation-reply-subject = { $response ->
    [accept] 수락: { $summary }
    [tentative] 미정: { $summary }
   *[decline] 거절: { $summary }
}
# the text of an answer to an invitation; { $name } is the user's name, or address
# review: new
invitation-reply-text = { $response ->
    [accept] { $name }님이 이 초대를 수락했습니다.
    [tentative] { $name }님이 이 초대를 미정으로 수락했습니다.
   *[decline] { $name }님이 이 초대를 거절했습니다.
}
# what a program read in an hour, a row of the log: "Read 14 messages and searched 3 times" (joined by agent-can-list)
# review: new
agent-reads-messages = 메시지 { $count }개 읽기
# review: new
agent-reads-attachments = 첨부 파일 { $count }개 요청
# review: new
agent-reads-searches = 검색 { $count }회
# review: new
agent-reads-lists = 메시지 목록 조회 { $count }회
# each read under that row
# review: new
agent-read-message = “{ $subject }” 메시지를 읽었습니다
# review: new
agent-read-conversation = “{ $subject }” 대화를 읽었습니다(메시지 { $count }개)
# review: new
agent-read-attachment = “{ $subject }” 메시지에서 첨부 파일 “{ $name }”을(를) 요청했습니다
# review: new
agent-read-search = “{ $query }” 검색: 메시지 { $count }개
# review: new
agent-read-people = 이름 또는 주소의 앞부분으로 사람을 찾았습니다: “{ $query }”
# review: new
agent-read-list = 목록 항목 { $count }개를 조회했습니다(범위: { $folder })
# review: new
agent-read-changes = 새 메시지 { $count }개의 세부 정보를 조회했습니다
# the programs started from a terminal app, which share one access: in the list of programs and the question when one connects
# review: new
agent-terminal-programs-mac = { $terminal }에서 시작한 프로그램
# review: new
agent-terminal-programs-windows = 터미널({ $terminal })에서 시작한 프로그램
# review: new
agent-terminal-programs-linux = 터미널({ $terminal })에서 시작한 프로그램
# one of them, as the questions to send or unsubscribe name it: "A program started from Terminal wants to send this message"
# review: new
agent-terminal-program-mac = { $terminal }에서 시작한 프로그램
# review: new
agent-terminal-program-windows = 터미널({ $terminal })에서 시작한 프로그램
# review: new
agent-terminal-program-linux = 터미널({ $terminal })에서 시작한 프로그램
# review: new
agent-connect-title-terminal = { $programs }이 메일을 사용하려고 합니다
# review: new
agent-connect-terminal-detail = 같은 인식된 터미널 프로그램에서 시작한 AI 에이전트는 여기에서 허용한 액세스를 함께 사용합니다. 에이전트에 별도의 액세스를 주려면 에이전트의 MCP 설정에서 인수에 --name과 원하는 이름을 추가하십시오. 이 이름으로 신원이 확인되지는 않습니다.
# above the question when a program said it was another one than the system found: "It said it was Claude. Inbox Classic checked which program started it: python3."
# review: new
agent-connect-claimed = 이 프로그램은 자신을 { $claimed }(이)라고 밝혔습니다. Inbox Classic이 확인한 실제 시작 프로그램: { $program }.

## 언어의 키보드에 표시된 키 이름 (도움말, Windows 및 Linux)

# review: new
key-ctrl = Ctrl
# review: new
key-alt = Alt
# review: new
key-shift = Shift
# review: new
key-del = Del
# review: new
key-enter = Enter

## 로그인과 암호

# review: new
sign-in-no-refresh = 공급자가 새로 고침 토큰을 주지 않았습니다
# review: new
sign-in-no-account = 공급자가 어떤 계정으로 로그인했는지 알려 주지 않았습니다
# review: new
sign-in-not-finished = 로그인이 끝나지 않았습니다
# review: new
secrets-unavailable = { $store }을(를) 사용할 수 없습니다
# review: new
secrets-unavailable-why = { $store }을(를) 사용할 수 없습니다: { $error }
# review: new
secrets-windows = 자격 증명 관리자
# review: new
secrets-mac = 키체인
# review: new
secrets-linux = 시스템 키링(Secret Service)
# review: new
error-no-such-file = 해당 파일이 없습니다
# review: new
cards-file-too-big = 이 파일은 주소록 가져오기 크기 한도를 초과합니다.
# review: new
ui-sender-added = { $name }을(를) 주소록에 추가했습니다.
# review: new
ui-sender-known = { $name }은(는) 이미 주소록에 있습니다.
# review: new
ui-sender-none = 이 메시지의 보낸 사람에게는 추가할 전자 메일 주소가 없습니다.
# review: new
card-name-needed = 연락처에 이름과 전자 메일 주소가 없습니다.
# a file of Import Address Book that could not be read: "contacts.vcf: there is no such file"
# review: new
cards-file-failed = { $file }: { $reason }

## 일회용 코드: 로그인 또는 인증 코드가 있는 메시지 맨 위의 카드

# the domain the code is for, which signed the message
# review: new
otp-heading = { $domain }의 코드
# review: new
otp-copy = 복사
# review: new
otp-note = { $domain }의 페이지에서만 입력하십시오.
# review: new
otp-old = 이 코드는 열기 한 시간 이상 전에 전송되었으므로 만료되었을 가능성이 높습니다.

# how many are invited, in the card of an event
# review: new
event-attendees =
    { $count ->
       *[other] 참석자 { $count }명
    }

# the first line of a new message's notification when it has a code, for a domain that signed it
# review: new
otp-notification = { $domain } 코드: { $code }

## OpenPGP 키 (keys.rs)
# review: new
pgp-key-valid = 유효함
# review: new
pgp-key-expires = { $date }까지 유효
# review: new
pgp-key-expired = { $date }에 만료됨
# review: new
pgp-key-revoked = 해지됨
# review: new
pgp-key-revoked-why = 해지됨: { $reason }
# review: new
pgp-key-not-valid = 유효하지 않음
# review: new
pgp-key-locked = 사용할 수 없음: { $store }에서 보호 키를 사용할 수 없습니다. 저장소를 사용할 수 있고 잠금 해제되어 있는지 확인하십시오. 보호 키가 없으면 개인 키 백업을 가져오십시오.
# review: new
pgp-source-own = Inbox Classic에서 만듦
# review: new
pgp-source-file = 파일에서 가져옴
# review: new
pgp-source-paste = 붙여 넣음
# review: new
pgp-source-attachment = 메시지에서
# review: new
pgp-source-vcard = 연락처 카드에서
# review: new
pgp-source-wkd = 보낸 사람의 메일 공급자에서
# review: new
pgp-source-keyserver = keys.openpgp.org에서
# review: new
pgp-source-autocrypt = 메시지의 Autocrypt 헤더에서
# review: new
pgp-error-no-store = 개인 키의 보호 키는 { $store }에 보관되어 있는데, 이를 사용할 수 없습니다: { $error }
# review: new
pgp-error-wrong-passphrase = 암호 문구가 올바르지 않습니다.
# review: new
pgp-error-not-a-key = OpenPGP 키가 아닙니다.
# review: new
pgp-error-too-large = 키가 너무 큽니다.
# review: new
pgp-error-unusable = 키를 사용할 수 없습니다. 적합한 서명 키나 암호화 키가 없거나, 지원되지 않는 암호화 방식을 사용할 수 있습니다.
# review: new
pgp-imported-private = { $count ->
    [1] 개인 키를 가져왔습니다.
   *[other] 개인 키 { $count }개를 가져왔습니다.
}
# review: new
pgp-imported-public = { $count ->
    [1] 키 1개를 가져왔습니다.
   *[other] 키 { $count }개를 가져왔습니다.
}
# review: new
pgp-imported-pending = { $addresses }에 이미 다른 키를 사용하고 있습니다. 새 키는 선택할 때까지 연락처에서 대기합니다.
# review: new
pgp-error-needs-passphrase = 개인 키가 암호 문구로 보호되어 있습니다. 키를 가져오려면 암호 문구를 입력하십시오.
# review: new
pgp-error-mismatch = 개인 키가 해당 공개 키와 맞지 않습니다. 변조되었을 수 있습니다.
# review: new
pgp-file-name-public = { $who } 공개 키.asc
# review: new
pgp-file-name-private = { $who } 개인 키 백업.asc
# review: new
pgp-pending = { $date }에 { $address }의 다른 키를 찾았습니다.

## 서명 및 암호화된 메일 읽기 (protect.rs)
# review: new
pgp-part-verified = { $signer }이(가) 서명함, 키 확인됨
# review: new
pgp-part-signed = { $signer }이(가) 서명함(키 확인 안 됨)
# review: new
pgp-part-other = 보낸 사람이 아닌 { $signer }이(가) 서명함
# review: new
pgp-part-unknown-key = 서명되었지만 키를 알 수 없음
# review: new
pgp-part-not-signed = 서명되지 않음
# review: new
pgp-part-not-checked = 서명을 확인하지 않음
# review: new
pgp-part-encrypted = 암호화됨. { $signature }
# review: new
pgp-part-no-key = 가지고 있지 않은 키로 암호화됨
# review: new
pgp-part-changed = 암호화된 부분이 무결성 검사를 통과하지 못해 표시하지 않습니다
# review: new
pgp-part-unprotected = 변경 방지 보호 없이 암호화되어 표시하지 않습니다
# review: new
pgp-part-broken = 암호화된 부분을 읽을 수 없습니다
# review: new
pgp-why-mismatch = 서명이 이 텍스트와 일치하지 않습니다
# review: new
pgp-why-weak-hash = 서명에 더 이상 안전하지 않은 { $hash }을(를) 사용합니다
# review: new
pgp-why-key-expired = { $date }에 키가 만료된 후에 서명되었습니다
# review: new
pgp-why-key-revoked = 해지된 키로 서명되었습니다
# review: new
pgp-why-not-signing-key = 서명에 쓸 수 없는 키로 서명되었습니다
# review: new
pgp-why-from-future = 서명 날짜가 미래로 되어 있습니다
# review: new
pgp-why-signature-expired = 서명이 만료되었습니다
# review: new
pgp-why-key-not-valid = 유효하지 않은 키로 서명되었습니다
# review: new
pgp-why-not-for-you = 다른 받는 사람을 위해 서명된 후 나에게 전달되었습니다
# review: new
pgp-why-not-key-in-use = { $address }에 사용 중인 키가 아닌 다른 키로 서명되었습니다
# review: new
pgp-part-pictures-loaded = { $label }. 인터넷에서 그림을 불러왔습니다
# review: new
pgp-error-no-own-key = { $address }(으)로 서명하거나 암호화할 키가 없습니다. 도구 > 암호화 키에서 키를 만들거나, 서명과 암호화를 끄십시오.
# review: new
pgp-error-missing-keys = { $count ->
    [1] 이 받는 사람에게 사용할 수 있는 암호화 키가 없습니다: { $addresses }.
   *[other] 이 받는 사람들에게 사용할 수 있는 암호화 키가 없습니다: { $addresses }.
}
# review: new
pgp-error-encrypted-quote = 이 메시지에는 암호화된 메일의 텍스트, 그림 또는 첨부 파일이 들어 있어 암호화해야만 보낼 수 있습니다. 암호화를 켜거나 해당 내용을 모두 제거하십시오.
# review: new
pgp-error-protect = 메시지에 서명하거나 메시지를 암호화할 수 없습니다: { $reason }
# review: new
pgp-found-keys = 키를 찾은 주소: { $addresses }.
# review: new
pgp-found-none = { $addresses }의 키를 찾지 못했습니다. 상대방에게 공개 키를 보내 달라고 요청하십시오.
# review: new
pgp-found-no-key = 키를 찾지 못했습니다.
# review: new
pgp-find-unavailable = 지금은 키를 찾을 수 없습니다: { $error }
# review: new
pgp-publish-pending = keys.openpgp.org에서 다음 주소로 확인 링크를 보냈습니다: { $addresses }. 각 주소를 확인해야 해당 주소로 내 키를 찾을 수 있습니다.
# review: new
pgp-publish-done = keys.openpgp.org에 { $addresses }의 키가 게시되었습니다.
# review: new
pgp-publish-failed = 키를 게시할 수 없습니다: { $error }
# review: new
pgp-keyserver-off = { $settings }에서 keys.openpgp.org 키 찾기가 꺼져 있습니다.
# the compose window with Sign and Encrypt: the line under the fields, each recipient's key, the questions
# review: new
pgp-compose-encrypted = { $count ->
    [1] 나와 { $addresses }을(를) 위해 암호화되고 서명됩니다.
   *[other] 나와 받는 사람 { $count }명을 위해 암호화되고 서명됩니다.
}
# review: new
pgp-compose-encrypt-ready = 암호화되고 서명됩니다. 키가 있는 받는 사람을 추가하십시오.
# review: new
pgp-compose-missing = { $count ->
    [1] { $addresses }에 사용할 수 있는 키가 없어 아직 메시지를 암호화할 수 없습니다.
   *[other] 받는 사람 { $count }명에게 사용할 수 있는 키가 없어 아직 메시지를 암호화할 수 없습니다: { $addresses }.
}
# review: new
pgp-compose-looking = { $addresses }의 키를 찾는 중...
# review: new
pgp-compose-signed = 서명됩니다. 받는 사람은 서명된 내용이 바뀌지 않았는지 확인할 수 있습니다. 내 키의 소유자도 따로 확인해야 합니다.
# review: new
pgp-compose-reply-clear = 회신하거나 전달하는 메시지는 암호화되어 있었지만, 이 메시지는 암호화되지 않습니다.
# review: new
pgp-compose-encrypted-files = 암호화된 메시지의 파일이 첨부되어 있어 이 메시지는 암호화해야만 보낼 수 있습니다. 암호화를 켜거나 해당 파일을 제거하십시오.
# review: new
pgp-compose-sign-tip = 받는 사람이 내용을 확인할 수 있도록 메시지에 서명합니다. 내 키의 소유자도 따로 확인해야 합니다
# review: new
pgp-compose-sign-tip-encrypted = 암호화된 메시지는 항상 서명됩니다
# review: new
pgp-compose-encrypt-tip = 나와 받는 사람만 읽을 수 있도록 메시지를 암호화합니다
# review: new
pgp-compose-make-key = 아직 { $address }의 키가 없습니다. 지금 만드시겠습니까? 키가 있으면 메시지에 서명하고 메시지를 암호화할 수 있습니다.
# review: new
pgp-compose-key-unusable = { $address }의 키를 사용할 수 없습니다({ $state }). 암호화 키를 열어 백업을 가져오거나 새 키를 만드십시오.
# review: new
pgp-compose-encrypt-off-quote = 이 메시지에는 암호화된 메일의 텍스트, 그림 또는 첨부 파일이 들어 있습니다. 암호화하지 않으면 해당 내용을 모두 제거할 때까지 보낼 수 없습니다. 그래도 암호화를 끄시겠습니까?
# review: new
pgp-compose-encrypt-off-reply = 이 메시지는 암호화된 메시지에 대한 회신이거나 전달입니다. 암호화하지 않으면 전송 중에 메시지를 다루는 누구든 읽을 수 있습니다. 암호화를 끄시겠습니까?
# review: new
pgp-recipient-verified = 키 확인됨
# review: new
pgp-recipient-found = 키 확인 안 됨
# review: new
pgp-recipient-own = 내 키
# review: new
pgp-recipient-looking = 키를 찾는 중...
# review: new
pgp-recipient-missing = 키 없음
# review: new
pgp-recipient-not-found = 키 없음: { $date }에 찾지 못함
# review: new
pgp-recipient-unusable = 키를 사용할 수 없음: { $state }
# review: new
pgp-recipients-intro = 메시지는 각 받는 사람의 키와 내 키로 암호화됩니다.
# review: new
pgp-recipients-intro-missing = { $count ->
    [1] 받는 사람 한 명에게 사용할 수 있는 암호화 키가 없습니다. 키를 찾거나 받는 사람을 제거하십시오. 암호화된 메일의 내용을 모두 제거한 후에만 암호화하지 않고 보낼 수 있습니다.
   *[other] 받는 사람 { $count }명에게 사용할 수 있는 암호화 키가 없습니다. 키를 찾거나 해당 받는 사람을 제거하십시오. 암호화된 메일의 내용을 모두 제거한 후에만 암호화하지 않고 보낼 수 있습니다.
}
# review: new
pgp-details-part = 부분 { $number }: { $label }
# review: new
attachment-from-part = 부분 { $number }에서: { $label }
# review: new
pgp-details-signed = { $when }에 키 { $key }(으)로 서명됨
# review: new
pgp-details-unknown-key = 가지고 있지 않은 키 { $key }(으)로 서명됨
# review: new
pgp-details-opened = 내 키 { $key }(으)로 해독됨
# review: new
pgp-details-for = 암호화 대상 키: { $keys }
# review: new
pgp-details-plain = 서명 및 암호화되지 않음
# review: new
pgp-bar-parts = 이 메시지는 { $count }개 부분으로 되어 있습니다: { $list }. 각 부분에 보호 방식이 표시됩니다.
# review: new
pgp-bar-count-verified = 확인됨 { $count }개
# review: new
pgp-bar-count-encrypted-signed = 암호화 및 서명됨 { $count }개
# review: new
pgp-bar-count-encrypted = 암호화됨 { $count }개
# review: new
pgp-bar-count-signed = 서명됨 { $count }개
# review: new
pgp-bar-count-warning = 주의 필요 { $count }개
# review: new
pgp-bar-count-neutral = 확인된 서명 없음 { $count }개
# the setup file: settings, accounts, contacts and keys carried to another computer
# review: new
setup-part-settings = 설정
# review: new
setup-part-preferences = 창 기본 설정
# review: new
setup-part-accounts = 계정
# review: new
setup-part-sign-in-apps = 로그인 앱
# review: new
setup-part-contacts = 연락처 및 그룹
# review: new
setup-part-keys = 암호화 키
# review: new
setup-part-rules = 메시지 규칙
# review: new
setup-part-trusted-senders = 신뢰할 수 있는 보낸 사람
# review: new
setup-holds-settings = 설정 { $count }개
# review: new
setup-holds-preferences = 기본 설정 { $count }개
# review: new
setup-holds-accounts = 계정 { $count }개
# review: new
setup-holds-sign-in-apps = 로그인 앱 { $count }개
# review: new
setup-holds-built-in = 켜져 있는 기본 제공 로그인 앱
# review: new
setup-holds-contacts = 연락처 { $count }개
# review: new
setup-holds-groups = 그룹 { $count }개
# review: new
setup-holds-own-keys = 내 키 { $count }개
# review: new
setup-holds-contact-keys = 연락처의 키 { $count }개
# review: new
setup-holds-rules = 규칙 { $count }개
# review: new
setup-holds-trusted-senders = 신뢰할 수 있는 보낸 사람 { $count }명
# review: new
setup-sign-in-password = 암호
# review: new
setup-account-secret-password = 암호가 파일에 들어 있습니다.
# review: new
setup-account-secret-token = 저장된 로그인 자격 증명이 파일에 들어 있습니다.
# review: new
setup-account-asks-password = 가져온 후에 암호를 묻습니다.
# review: new
setup-account-signs-in-again = 가져온 후에 다시 로그인해야 합니다.
# review: new
setup-account-here = 이미 여기에 설정되어 있으므로 건너뜁니다.
# review: new
setup-account-no-app = 여기에 설정되지 않은 { $app }(으)로 로그인합니다. 로그인 앱도 가져오십시오.
# review: new
setup-invalid-address = "{ $address }"은(는) 전자 메일 주소가 아닙니다.
# review: new
setup-invalid-server = { $server } 설정의 서버 이름, 포트 또는 보안 옵션이 올바르지 않습니다.
# review: new
setup-invalid-user = 사용자 이름이 없습니다.
# review: new
setup-invalid-sign-in = 로그인 방법 또는 구성이 지원되지 않습니다.
# review: new
setup-error-empty = 파일이 비어 있습니다.
# review: new
setup-error-too-large = 설정 파일이 크기 한도를 초과합니다.
# review: new
setup-error-not-setup = 이 파일은 Inbox Classic 설정 파일이 아닙니다.
# review: new
setup-error-damaged = 설정 파일이 손상되어 읽을 수 없습니다.
# review: new
setup-error-newer = 이 설정은 최신 버전의 Inbox Classic({ $version })에서 저장되었습니다. Inbox Classic을 업데이트한 다음 다시 가져오십시오.
# review: new
setup-error-needs-passphrase = 이 설정은 암호 문구로 보호되어 있습니다. 저장할 때 사용한 암호 문구를 입력하십시오.
# review: new
setup-error-wrong-passphrase = 이 설정을 저장할 때 사용한 암호 문구가 아닙니다.
# review: new
setup-error-changed = 설정 파일이 무결성 검사를 통과하지 못했습니다. 변조되었거나 손상되었을 수 있으므로 가져올 수 없습니다.
# review: new
setup-error-read = 설정 파일을 읽을 수 없습니다: { $error }
# review: new
setup-error-write = 설정을 저장할 수 없습니다: { $error }
# review: new
setup-error-no-parts = 항목을 하나 이상 선택하십시오.
# review: new
setup-left-out = { $part }의 항목 { $count }개를 사용할 수 없어 제외했습니다.
# review: new
setup-imported-settings = 설정을 바꿨습니다.
# review: new
setup-imported-preferences = 창 기본 설정을 바꿨습니다.
# review: new
setup-added-accounts = 계정 { $count }개를 추가했습니다.
# review: new
setup-skipped-here = { $address }은(는) 이미 여기에 설정되어 있으므로 건너뛰었습니다.
# review: new
setup-skipped-no-app = { $address }을(를) 건너뛰었습니다. 여기에 설정되지 않은 { $app }(으)로 로그인합니다.
# review: new
setup-skipped-invalid = { $address }을(를) 건너뛰었습니다: { $reason }
# review: new
setup-asks-password = { $address }은(는) 연결할 때 암호를 묻습니다.
# review: new
setup-signs-in-again = { $address }은(는) 연결할 때 다시 로그인하도록 요청합니다.
# review: new
setup-added-sign-in-apps = 로그인 앱 { $count }개를 추가했습니다.
# review: new
setup-skipped-sign-in-apps = 로그인 앱 { $count }개는 이미 여기에 설정되어 있습니다.
# review: new
setup-added-contacts = 주소록에 연락처 { $count }개를 추가했습니다.
# review: new
setup-skipped-contacts = 연락처 { $count }개는 이미 주소록에 있습니다.
# review: new
setup-added-groups = 그룹 { $count }개를 추가하거나 보완했습니다.
# review: new
setup-added-own-keys = 내 키 { $count }개를 추가했습니다.
# review: new
setup-added-contact-keys = 연락처의 키 { $count }개를 추가했습니다.
# review: new
setup-added-rules = 메시지 규칙 { $count }개를 추가했습니다.
# review: new
setup-skipped-rules = 메시지 규칙 { $count }개는 이미 여기에 있습니다.
# review: new
setup-skipped-rules-account = 메시지 규칙 { $count }개는 여기에 없는 계정용이므로 건너뛰었습니다.
# review: new
setup-rules-waiting = 메시지 규칙 { $count }개는 계정 동기화 중에 대상 폴더를 찾을 때까지 대기합니다.
# review: new
setup-added-trusted-senders = 신뢰할 수 있는 보낸 사람 { $count }명을 추가했습니다.
# review: new
setup-nothing = 가져온 항목이 없습니다.
# review: new
setup-account-servers = { $imap } 및 { $smtp } ({ $signin })
# review: new
setup-file-name = Inbox Classic 설정 및 계정
# review: new
setup-skipped-unreachable = { $name }을(를) 건너뛰었습니다. 로그인 서비스에 연결하거나 확인할 수 없습니다. 다시 시도하기 전에 로그인 앱에서 필요한 앱을 확인하십시오.
# review: new
attachment-runs-programs = “{ $name }”은(는) 프로그램을 실행할 수 있으므로 Inbox Classic에서 열지 않습니다. 저장한 다음, 출처를 신뢰할 수 있으면 직접 여십시오.
# review: new
attachment-decrypted-note = 이 첨부 파일은 암호화된 메일에서 온 것입니다. 다른 앱에서 열기 위해 Inbox Classic은 사용자 계정의 임시 폴더에 암호화되지 않은 사본을 저장합니다. 시작할 때 하루가 지난 사본을 제거하려고 시도합니다.
# a bar over the list when the server did not do what the user asked of messages, so they are as they were again
# review: new
undone-move = { $count ->
   *[other] 서버가 { $messages }를 { $folder }(으)로 이동하지 않았으므로 다시 { $from }에 있습니다: { $reason }
}
# review: new
undone-delete = { $count ->
   *[other] 서버가 { $messages }를 삭제하지 않았으므로 다시 { $from }에 있습니다: { $reason }
}
# review: new
undone-archive = { $count ->
   *[other] 서버가 { $messages }를 보관하지 않았으므로 다시 { $from }에 있습니다: { $reason }
}
# review: new
undone-read = { $count ->
   *[other] 서버가 { $messages }를 읽은 상태로 표시하지 않았으므로 다시 읽지 않은 상태가 되었습니다: { $reason }
}
# review: new
undone-unread = { $count ->
   *[other] 서버가 { $messages }를 읽지 않은 상태로 표시하지 않았으므로 다시 읽은 상태가 되었습니다: { $reason }
}
# review: new
undone-flags = { $count ->
   *[other] 서버가 { $messages }의 플래그를 변경하지 않았으므로 원래 상태로 돌아갔습니다: { $reason }
}

## 첨부 파일 미리 보기: 메시지에 표시되는 그림과 PDF 파일

# the reading option that turns PDF previews on and off (the apps show it)
# review: new
preview-pdf-option = 메시지에 PDF 파일 표시
# the tile of a PDF file while PDF previews are off
# review: new
preview-pdf-off = 메시지에 PDF 파일을 표시하지 않습니다.
# the note where previews are, after the app ended while it was drawing a file of a message: { $option } is the option's name
# review: new
preview-pdf-off-crashed = 메시지의 파일을 표시하는 동안 Inbox Classic이 닫혀서 이제 메시지에 PDF 파일을 표시하지 않습니다. 그림은 계속 표시됩니다. PDF 파일을 다시 표시하려면 { $settings }에서 { $option } 옵션을 켜십시오.
# under the pages of a PDF file shown in a message: its page count and size ("3 pages, 84 KB")
# review: new
preview-pdf-details = { $count }페이지, { $size }
# what a screen reader says of a page of a PDF file shown in a message
# review: new
preview-page-alt = { $name }, { $count }페이지 중 { $page }페이지
# the link under the pages of a PDF file shown in a message, when it has more pages than are shown
# review: new
preview-more-pages = { $count ->
    [1] 열어서 페이지 보기
   *[other] 열어서 { $count }페이지 모두 보기
}
# after the files shown in a message, when it has more pictures and PDF files than are shown; the list is the
# strip of files over the message
# review: new
preview-more-files = 위 목록에 파일이 { $count }개 더 있습니다
# the tile of a picture or PDF file of a message still downloading (the ellipsis as in reader-downloading)
# review: new
preview-tile-downloading = 다운로드하는 중…
# the tile of a picture or PDF file whose size was not read in time when the message was shown: its preview
# comes in its place in a moment (the ellipsis as in reader-downloading)
# review: new
preview-tile-preparing = 준비하는 중…
# the tile of a picture in a format not shown yet: { $format } is its name (HEIC, AVIF, JPEG XL)
# review: new
preview-tile-format = { $format } 그림은 아직 표시할 수 없습니다
# the tile of a PDF file that wants a password to open
# review: new
preview-tile-password = 암호로 보호됨: 열어서 암호를 입력하십시오
# the tile of a picture or PDF file over the size or pixel limit
# review: new
preview-tile-too-large = 너무 커서 표시할 수 없음
# the tile of a file that is broken, or not what its name says
# review: new
preview-tile-unreadable = 표시할 수 없음
# the tile of a file that took too long to draw
# review: new
preview-tile-timed-out = 미리 보기를 준비하는 데 너무 오래 걸렸습니다
# the tile of a file that closed the app once while it was drawn: never drawn again
# review: new
preview-tile-crashed = 미리 보기를 사용할 수 없음: 이전 시도가 중단되었습니다
# the tile of a file while previews are paused after a file took too long, until the app starts again
# review: new
preview-tile-off = Inbox Classic을 다시 시작할 때까지 표시하지 않음
# in a printout, for a file shown in the message that is not printed (a PDF file, a tile): { $details } is its size,
# or a PDF file's pages and size
# review: new
preview-not-printed = { $name }({ $details })은(는) 인쇄되지 않습니다. 인쇄하려면 파일을 여십시오.
