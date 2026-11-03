# The app end to end, driven the way a user drives it, against ImapKit (core/e2e). Every feature is used once and
# its effect checked, on the server through ImapKit's REST API where there is one: adding an account (and a wrong
# password), reading plain and HTML mail, marking read and unread, inline and remote pictures, saving an attachment,
# replying, replying to all, forwarding, writing a new message (and a mistyped address), Send/Recv, Sent Items,
# About and the help. A screenshot of each step goes to -Out (scripts/feature-map.mjs builds a page from them).
#
#   powershell -ExecutionPolicy Bypass -File scripts\ui-e2e.ps1 [-Exe build\InboxClassic.exe] [-Out build\ui-e2e]
#
# Needs a desktop (a logged in session, or a CI runner), Node.js and `npm ci` in core\e2e. The app runs with a
# store of its own and --memory-passwords, so nothing of the user's is touched. The control and command ids are those
# of app/src/app.h, accounts.cpp and compose.cpp.
param(
    [string]$Exe = (Join-Path $PSScriptRoot '..\build\InboxClassic.exe'),
    [string]$Out = (Join-Path $PSScriptRoot '..\build\ui-e2e')
)
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Windows.Forms, System.Drawing
Add-Type -Namespace Native -Name Win -MemberDefinition @'
[DllImport("user32.dll")] public static extern bool SetProcessDPIAware();
[DllImport("user32.dll", CharSet = CharSet.Unicode)] public static extern IntPtr FindWindow(string cls, string title);
[DllImport("user32.dll", CharSet = CharSet.Unicode)] public static extern IntPtr FindWindowEx(IntPtr parent, IntPtr after, string cls, string title);
[DllImport("user32.dll")] public static extern IntPtr GetDlgItem(IntPtr hwnd, int id);
[DllImport("user32.dll")] public static extern bool PostMessage(IntPtr hwnd, uint message, IntPtr wParam, IntPtr lParam);
[DllImport("user32.dll")] public static extern IntPtr SendMessage(IntPtr hwnd, uint message, IntPtr wParam, IntPtr lParam);
[DllImport("user32.dll", CharSet = CharSet.Unicode)] public static extern IntPtr SendMessage(IntPtr hwnd, uint message, IntPtr wParam, string lParam);
[DllImport("user32.dll", CharSet = CharSet.Unicode)] public static extern IntPtr SendMessage(IntPtr hwnd, uint message, IntPtr wParam, System.Text.StringBuilder lParam);
[DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr hwnd, out RECT rect);
[DllImport("user32.dll")] public static extern bool SetWindowPos(IntPtr hwnd, IntPtr after, int x, int y, int cx, int cy, uint flags);
[DllImport("user32.dll")] public static extern bool IsWindowVisible(IntPtr hwnd);
[DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr hwnd);
[DllImport("user32.dll")] public static extern bool IsWindow(IntPtr hwnd);
public delegate bool EnumProc(IntPtr hwnd, IntPtr lParam);
[DllImport("user32.dll")] public static extern bool EnumChildWindows(IntPtr parent, EnumProc proc, IntPtr lParam);
[DllImport("user32.dll", CharSet = CharSet.Unicode)] public static extern int GetClassName(IntPtr hwnd, System.Text.StringBuilder name, int size);
[DllImport("user32.dll", CharSet = CharSet.Unicode)] public static extern int InternalGetWindowText(IntPtr hwnd, System.Text.StringBuilder text, int size);
public struct RECT { public int Left, Top, Right, Bottom; }
// the windows of class `cls` anywhere under `parent`
public static System.Collections.Generic.List<IntPtr> FindDescendants(IntPtr parent, string cls) {
    var found = new System.Collections.Generic.List<IntPtr>();
    EnumChildWindows(parent, (hwnd, _) => {
        var name = new System.Text.StringBuilder(64);
        GetClassName(hwnd, name, 64);
        if (name.ToString() == cls) { found.Add(hwnd); }
        return true;
    }, IntPtr.Zero);
    return found;
}
'@
[void][Native.Win]::SetProcessDPIAware()

$WM_SETTEXT = 0x000C; $WM_GETTEXT = 0x000D; $WM_CLOSE = 0x0010; $WM_COMMAND = 0x0111; $WM_KEYDOWN = 0x0100
$WM_KEYUP = 0x0101; $BM_CLICK = 0x00F5; $CB_SETCURSEL = 0x014E; $EM_SETSEL = 0x00B1; $EM_REPLACESEL = 0x00C2
$TVM_GETCOUNT = 0x1105; $TVM_GETNEXTITEM = 0x110A; $TVM_SELECTITEM = 0x110B; $LVM_GETITEMCOUNT = 0x1004
$VK_RETURN = 0x0D; $VK_HOME = 0x24; $VK_DOWN = 0x28; $VK_DELETE = 0x2E
# app/src/app.h
$IDM_NEW_ACCOUNT = 100; $IDM_SYNC = 102; $IDM_MARK_READ = 103; $IDM_MARK_UNREAD = 104; $IDM_PICTURES = 105
$IDM_ABOUT = 106; $IDM_NEW_MAIL = 107; $IDM_REPLY = 108; $IDM_REPLY_ALL = 109; $IDM_FORWARD = 110; $IDM_HELP = 111
$IDM_DELETE = 112; $IDM_MOVE = 113; $IDM_FLAG = 114; $IDM_NEW_FOLDER = 115; $IDM_RENAME_FOLDER = 116; $IDM_DELETE_FOLDER = 117; $IDM_ACCOUNTS = 118; $IDM_SAVE_AS = 121; $IDM_PRINT = 122; $IDM_IMPORT = 123; $IDM_OUTBOX = 124; $IDM_PROPERTIES = 125; $IDC_SAVE = 309;
$LB_GETTEXT = 0x0189; $LB_GETCOUNT = 0x018B; $LB_SETCURSEL = 0x0186; $CB_SELECTSTRING = 0x014D
$IDC_TREE = 200; $IDC_LIST = 201; $IDC_ATTACHMENTS = 202; $IDC_PICTURES = 203
$IDC_SEND = 300; $IDC_ATTACH = 301; $IDC_FILES = 307; $IDC_FROM = 310; $IDC_SHOW_CC = 311; $IDC_SHOW_BCC = 312; $IDC_BCC = 304; $IDC_TO = 302; $IDC_CC = 303; $IDC_SUBJECT = 305; $IDC_BODY = 306; $IDF_BOLD = 330

New-Item -ItemType Directory -Force -Path $Out | Out-Null
# a scheduled task shows no output: everything also goes to log.txt, and result.txt is written last
Remove-Item -Force -ErrorAction SilentlyContinue (Join-Path $Out 'result.txt')
Start-Transcript -Path (Join-Path $Out 'log.txt') -Force | Out-Null
$failures = @()
function Step([string]$text) { Write-Host "== $text" }
function Check([bool]$ok, [string]$what) {
    if ($ok) { Write-Host "   ok: $what" } else { Write-Host "   FAILED: $what"; $script:failures += $what }
}

# waits up to $Seconds for $Condition to give something truthy, returns it (or $null)
function WaitFor([scriptblock]$Condition, [int]$Seconds = 20) {
    $deadline = (Get-Date).AddSeconds($Seconds)
    while ((Get-Date) -lt $deadline) {
        $value = & $Condition
        if ($value) { return $value }
        Start-Sleep -Milliseconds 250
    }
    return $null
}

# a picture of a window; with $Also (a popup menu, say) of the area that holds both
function Shot([IntPtr]$hwnd, [string]$name, [IntPtr]$Also = [IntPtr]::Zero) {
    # in front and painted: a window that just opened may not have drawn itself yet
    if ($Also -eq [IntPtr]::Zero) {
        [void][Native.Win]::SetWindowPos($hwnd, [IntPtr](-1), 0, 0, 0, 0, 0x13)
        [void][Native.Win]::SetForegroundWindow($hwnd)
    }
    Start-Sleep -Milliseconds 700
    $rect = New-Object Native.Win+RECT
    [void][Native.Win]::GetWindowRect($hwnd, [ref]$rect)
    if ($Also -ne [IntPtr]::Zero) {
        $other = New-Object Native.Win+RECT
        [void][Native.Win]::GetWindowRect($Also, [ref]$other)
        $rect.Left = [Math]::Min($rect.Left, $other.Left); $rect.Top = [Math]::Min($rect.Top, $other.Top)
        $rect.Right = [Math]::Max($rect.Right, $other.Right); $rect.Bottom = [Math]::Max($rect.Bottom, $other.Bottom)
    }
    # a window that closed in the meantime has no picture
    if ($rect.Right -le $rect.Left -or $rect.Bottom -le $rect.Top) { return }
    $bitmap = New-Object System.Drawing.Bitmap ($rect.Right - $rect.Left), ($rect.Bottom - $rect.Top)
    [System.Drawing.Graphics]::FromImage($bitmap).CopyFromScreen($rect.Left, $rect.Top, 0, 0, $bitmap.Size)
    if ($Also -eq [IntPtr]::Zero) { [void][Native.Win]::SetWindowPos($hwnd, [IntPtr](-2), 0, 0, 0, 0, 0x13) }
    $bitmap.Save((Join-Path $Out "$name.png"), [System.Drawing.Imaging.ImageFormat]::Png)
}

function SetText([IntPtr]$window, [int]$id, [string]$text) {
    [void][Native.Win]::SendMessage([Native.Win]::GetDlgItem($window, $id), $WM_SETTEXT, [IntPtr]::Zero, $text)
}
function WindowText([IntPtr]$window) {
    $buffer = New-Object System.Text.StringBuilder 4096
    [void][Native.Win]::SendMessage($window, $WM_GETTEXT, [IntPtr]4096, $buffer)
    return $buffer.ToString()
}
function GetText([IntPtr]$window, [int]$id) { WindowText ([Native.Win]::GetDlgItem($window, $id)) }
function Click([IntPtr]$window, [int]$id) {
    [void][Native.Win]::PostMessage([Native.Win]::GetDlgItem($window, $id), $BM_CLICK, [IntPtr]::Zero, [IntPtr]::Zero)
}
# a menu or toolbar command, posted as the menu would
function Command([IntPtr]$window, [int]$id) {
    [void][Native.Win]::PostMessage($window, $WM_COMMAND, [IntPtr]$id, [IntPtr]::Zero)
}
function Key([IntPtr]$window, [int]$vk) {
    [void][Native.Win]::PostMessage($window, $WM_KEYDOWN, [IntPtr]$vk, [IntPtr]::Zero)
    [void][Native.Win]::PostMessage($window, $WM_KEYUP, [IntPtr]$vk, [IntPtr]::Zero)
}
# a top-level window of a class (and title), once it is there
function WaitWindow([string]$class, [string]$title = $null, [int]$Seconds = 20) {
    $t = if ($title) { $title } else { [NullString]::Value }
    WaitFor { $w = [Native.Win]::FindWindow($class, $t); if ($w -ne [IntPtr]::Zero) { $w } } $Seconds
}
# the window of the WebView2 of a compose window's editor that takes input, clicked into as a user would when the
# cursor is in another field
function ClickEditor([IntPtr]$compose) {
    $input = WaitFor { [Native.Win]::FindDescendants($compose, 'Chrome_RenderWidgetHostHWND') | Select-Object -First 1 }
    if (-not $input) { return $null }
    Start-Sleep -Milliseconds 500
    $point = [IntPtr]((12 -shl 16) -bor 12)
    [void][Native.Win]::PostMessage($input, 0x0201, [IntPtr]1, $point)
    [void][Native.Win]::PostMessage($input, 0x0202, [IntPtr]::Zero, $point)
    Start-Sleep -Milliseconds 300
    return $input
}
# types into the HTML editor of a compose window
function TypeInEditor([IntPtr]$compose, [string]$text) {
    $input = ClickEditor $compose
    if (-not $input) { return $false }
    foreach ($c in $text.ToCharArray()) {
        [void][Native.Win]::PostMessage($input, 0x0102, [IntPtr][int]$c, [IntPtr]::Zero)
    }
    Start-Sleep -Milliseconds 500
    return $true
}
# a file dialog answered: the path typed into its name box (characters, as the dialog keeps its own copy), then Open or Save
function AnswerFileDialog([string]$title, [string]$path, [string]$shot, [string]$suggested = $null) {
    $dialog = WaitWindow '#32770' $title 15
    if (-not $dialog) { return $false }
    # the name box: the one with the suggested name in a Save dialog, the one in the name combo box (1148) otherwise
    $name = WaitFor {
        if ($suggested) {
            [Native.Win]::FindDescendants($dialog, 'Edit') | Where-Object { (WindowText $_) -like $suggested } | Select-Object -First 1
        } else {
            $combo = [Native.Win]::GetDlgItem($dialog, 1148)
            if ($combo -ne [IntPtr]::Zero) { [Native.Win]::FindDescendants($combo, 'Edit') | Select-Object -First 1 }
        }
    } 10
    if (-not $name) { return $false }
    if ($shot) { Shot $dialog $shot }
    [void][Native.Win]::SendMessage($name, $EM_SETSEL, [IntPtr]0, [IntPtr](-1))
    foreach ($c in $path.ToCharArray()) { [void][Native.Win]::PostMessage($name, 0x0102, [IntPtr][int]$c, [IntPtr]::Zero) }
    # the dialog's own Open or Save button (id 1) once the box has all of the path: Enter could go to the list of
    # suggestions that opens while a path is typed
    if (-not (WaitFor { (WindowText $name) -eq $path } 10)) { return $false }
    Click $dialog 1
    return [bool](WaitFor { -not [Native.Win]::IsWindow($dialog) } 10)
}
# whether a button of the format bar is pressed
function Pressed([IntPtr]$compose, [int]$id) {
    $bar = [Native.Win]::GetDlgItem($compose, 322)
    [int][Native.Win]::SendMessage($bar, 0x040A, [IntPtr]$id, [IntPtr]::Zero) -ne 0
}
function Visible([IntPtr]$window, [int]$id) { [Native.Win]::IsWindowVisible([Native.Win]::GetDlgItem($window, $id)) }

# ---- ImapKit, with mail to read ----

Step 'starting ImapKit'
$e2e = Join-Path $PSScriptRoot '..\core\e2e'
$start = New-Object System.Diagnostics.ProcessStartInfo 'node', 'harness.mjs'
$start.WorkingDirectory = (Resolve-Path $e2e)
$start.UseShellExecute = $false
$start.RedirectStandardInput = $true
$start.RedirectStandardOutput = $true
$harness = [System.Diagnostics.Process]::Start($start)
$harness.StandardInput.WriteLine('{}')
$ports = $harness.StandardOutput.ReadLine() | ConvertFrom-Json
$rest = "http://127.0.0.1:$($ports.rest)/v1/mailboxes"
function Messages([string]$mailbox) {
    # through the pipeline, which unrolls the array: Windows PowerShell hands an empty one on as one object
    @(Invoke-RestMethod "$rest/$([uri]::EscapeDataString($mailbox))/messages?raw=true" | ForEach-Object { $_ })
}
# the REST API gives the source base64 encoded
function RawText($message) {
    try { [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($message.raw)) }
    catch { "UNDECODED(" + ([string]$message.raw).Substring(0, [Math]::Min(80, ([string]$message.raw).Length)) + ")" }
}
function Find([string]$mailbox, [string]$pattern) { (Messages $mailbox) | Where-Object { (RawText $_) -match $pattern } | Select-Object -First 1 }
function Seen([string]$pattern) { (Find 'INBOX' $pattern).flags -contains '\Seen' }
function AddMessage([string]$raw, [string[]]$flags = @()) {
    $body = @{ raw = $raw; flags = $flags } | ConvertTo-Json
    [void](Invoke-RestMethod -Method Post -ContentType 'application/json' -Body $body "$rest/INBOX/messages")
}

# a picture sent inside the message
$picture = New-Object System.Drawing.Bitmap 220, 60
$graphics = [System.Drawing.Graphics]::FromImage($picture)
$graphics.Clear([System.Drawing.Color]::FromArgb(0, 51, 102))
$graphics.DrawString('Inline picture', (New-Object System.Drawing.Font 'Tahoma', 16), [System.Drawing.Brushes]::White, 12, 16)
$stream = New-Object System.IO.MemoryStream
$picture.Save($stream, [System.Drawing.Imaging.ImageFormat]::Png)
$png = [Convert]::ToBase64String($stream.ToArray(), 'InsertLineBreaks')
$pdf = "%PDF-1.4`n% a small attachment from scripts/ui-e2e.ps1`n"
$pdf64 = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes($pdf))

# in the list newest first: the newsletter, Ann's message, the minutes
$minutes = 'Minutes of the planning meeting'
AddMessage ("From: Bob Builder <bob@example.com>`r`nTo: testuser@postalexpress.test, Dave <dave@example.com>`r`n" +
    "Cc: Carol <carol@example.com>`r`nSubject: $minutes`r`nMessage-ID: <minutes@example.com>`r`n" +
    "Date: Wed, 1 Oct 2025 09:00:00 +0000`r`n`r`nWe agreed on the dates.`r`n") @('\Seen')
# a reply with the message it answers quoted below, as Gmail sends it: the oldest, the last row
AddMessage ("From: Carol <carol@example.com>`r`nTo: testuser@postalexpress.test`r`nSubject: Re: Lunch on Friday`r`n" +
    "Message-ID: <lunch2@example.com>`r`nIn-Reply-To: <lunch1@example.com>`r`nDate: Mon, 29 Sep 2025 12:00:00 +0000`r`n" +
    "Content-Type: text/html; charset=utf-8`r`n`r`n" +
    '<div dir="ltr">Friday is fine, see you at noon.</div><br><div class="gmail_quote"><div dir="ltr" class="gmail_attr">' +
    'On Mon, Sep 29, 2025 at 9:00 AM UI Test &lt;testuser@postalexpress.test&gt; wrote:<br></div>' +
    '<blockquote class="gmail_quote" style="margin:0px 0px 0px 0.8ex;border-left:1px solid rgb(204,204,204);padding-left:1ex">' +
    'Lunch on Friday? The usual place.</blockquote></div>' + "`r`n") @('\Seen')
$subject = 'Hello from the UI test'
AddMessage ("From: Ann Example <ann@example.com>`r`nTo: testuser@postalexpress.test`r`nSubject: $subject`r`n" +
    "Message-ID: <ui-e2e@example.com>`r`nDate: Mon, 6 Oct 2025 10:00:00 +0000`r`n`r`nHi,`r`n" +
    "this message was put here by scripts/ui-e2e.ps1.`r`n")
$newsletter = 'October newsletter'
$html = '<div style="font-family:Georgia,serif;max-width:560px"><h2 style="color:#036">October newsletter</h2>' +
    '<p>This message is <b>HTML</b>, with a picture sent inside it:</p><p><img src="cid:banner@example.com" alt="banner"></p>' +
    '<p>and one kept on the internet, shown only after <i>Download pictures</i>:</p>' +
    '<p><img src="https://nodemailer.com/img/nm_logo_200x136.png" width="200" height="136" alt="remote picture"></p>' +
    '<p>A <a href="https://example.com/news">link</a> opens in the browser. <script>alert("never runs")</script></p></div>'
AddMessage ("From: The Newsletter <news@example.com>`r`nTo: testuser@postalexpress.test`r`nSubject: $newsletter`r`n" +
    "Message-ID: <news@example.com>`r`nDate: Wed, 8 Oct 2025 08:00:00 +0000`r`nMIME-Version: 1.0`r`n" +
    "Content-Type: multipart/mixed; boundary=`"mixed`"`r`n`r`n--mixed`r`n" +
    "Content-Type: multipart/related; boundary=`"related`"`r`n`r`n--related`r`n" +
    "Content-Type: text/html; charset=utf-8`r`n`r`n$html`r`n--related`r`n" +
    "Content-Type: image/png`r`nContent-ID: <banner@example.com>`r`nContent-Transfer-Encoding: base64`r`n`r`n$png`r`n" +
    "--related--`r`n--mixed`r`nContent-Type: application/pdf; name=`"report.pdf`"`r`n" +
    "Content-Disposition: attachment; filename=`"report.pdf`"`r`nContent-Transfer-Encoding: base64`r`n`r`n$pdf64`r`n" +
    "--mixed--`r`n") @('\Flagged')

$app = $null
try {
    # ---- adding the account ----

    Step 'starting Inbox Classic with a store of its own'
    $store = Join-Path $Out 'store.db'
    Remove-Item -Force -ErrorAction SilentlyContinue "$store*", (Join-Path $Out '*.png'), (Join-Path $Out 'report*.pdf')
    # ImapKit's certificate is self-signed: the app trusts it, and only it, for this run
    $arguments = @('--store', "`"$store`"", '--memory-passwords', '--pin-certificate', "`"$($ports.cert)`"")
    $app = Start-Process -FilePath $Exe -ArgumentList $arguments -PassThru

    # the first page of Add Mail Account, with the address fields when $fields, else the page that offers a
    # provider's sign-in for an address found there
    function StartPage([bool]$fields, [int]$seconds = 10) {
        WaitFor {
            $f = [Native.Win]::FindWindow('InboxClassicAccountStart', 'Add Mail Account')
            if ($f -ne [IntPtr]::Zero -and (([Native.Win]::GetDlgItem($f, 101) -ne [IntPtr]::Zero) -eq $fields)) { $f }
        } $seconds
    }

    # both steps of the form: the name and address, then the servers with the password
    function AddAccount([string]$name, [string]$user, [string]$password, [bool]$shots) {
        $first = StartPage $true
        Check ($null -ne $first) "the account form opens ($name)"
        if ($shots) {
            $google = [Native.Win]::GetDlgItem($first, 120); $microsoft = [Native.Win]::GetDlgItem($first, 121)
            Check ((WindowText $google) -eq 'Sign in with Google' -and (WindowText $microsoft) -eq 'Sign in with Microsoft') 'it starts with the Google and Microsoft sign-in buttons'
            Check ([Native.Win]::GetDlgItem($first, 102) -eq [IntPtr]::Zero) 'and asks no password before the servers are known'
        }
        SetText $first 100 $name
        SetText $first 101 "$user@postalexpress.test"
        if ($shots) { Shot $first 'account-1-form' }
        Click $first 1
        if ($shots) {
            $wait = WaitWindow 'InboxClassicWait' $null 5
            if ($wait) { Shot $wait 'account-2-lookup' }
        }
        # the lookup finds nothing for this domain: the second form comes with the usual names to correct
        $second = WaitFor {
            $f = [Native.Win]::FindWindow('InboxClassicForm', 'Add Mail Account')
            if ($f -ne [IntPtr]::Zero -and [Native.Win]::GetDlgItem($f, 109) -ne [IntPtr]::Zero) { $f }
        } 40
        Check ($null -ne $second) 'the server settings form follows the lookup'
        if (-not $second) { Shot $first "account-failed-$user"; throw 'no server settings form' }
        Check ((GetText $second 104) -eq 'imap.postalexpress.test') 'the lookup guessed the IMAP server'
        Check ((GetText $second 100) -eq $name) 'the server form keeps the name typed first'
        SetText $second 102 $user
        SetText $second 103 $password
        SetText $second 104 '127.0.0.1'
        SetText $second 105 "$($ports.imap)"
        [void][Native.Win]::SendMessage([Native.Win]::GetDlgItem($second, 106), $CB_SETCURSEL, [IntPtr]2, [IntPtr]::Zero)
        SetText $second 107 '127.0.0.1'
        SetText $second 108 "$($ports.smtp)"
        # ImapKit's SMTP server takes a password only after STARTTLS
        [void][Native.Win]::SendMessage([Native.Win]::GetDlgItem($second, 109), $CB_SETCURSEL, [IntPtr]1, [IntPtr]::Zero)
        if ($shots) { Shot $second 'account-3-servers' }
        Click $second 1
        $warning = WaitWindow '#32770' 'Add Mail Account'
        Check ($null -ne $warning) 'a connection without encryption is warned about'
        if ($shots -and $warning) { Shot $warning 'account-4-warning' }
        Click $warning 6
    }
    AddAccount 'UI Test' 'testuser' 'testpass' $true

    # ---- reading ----

    Step 'syncing'
    $main = [Native.Win]::FindWindow('InboxClassicMain', [NullString]::Value)
    $tree = [Native.Win]::GetDlgItem($main, $IDC_TREE)
    $list = [Native.Win]::GetDlgItem($main, $IDC_LIST)
    $folders = WaitFor { $n = [int][Native.Win]::SendMessage($tree, $TVM_GETCOUNT, [IntPtr]::Zero, [IntPtr]::Zero); if ($n -ge 7) { $n } }
    Check ($null -ne $folders) "the folders of the account are in the tree ($folders)"
    # the folders under the account: Inbox, Sent Items, Drafts, Archive, Junk E-mail, Deleted Items
    function SelectFolder([int]$index) {
        $item = [Native.Win]::SendMessage($tree, $TVM_GETNEXTITEM, [IntPtr]4, [Native.Win]::SendMessage($tree, $TVM_GETNEXTITEM, [IntPtr]0, [IntPtr]::Zero))
        for ($i = 0; $i -lt $index; $i++) { $item = [Native.Win]::SendMessage($tree, $TVM_GETNEXTITEM, [IntPtr]1, $item) }
        [void][Native.Win]::SendMessage($tree, $TVM_SELECTITEM, [IntPtr]9, $item)
    }
    function Rows { [int][Native.Win]::SendMessage($list, $LVM_GETITEMCOUNT, [IntPtr]::Zero, [IntPtr]::Zero) }
    # a row of the list, reached with the keys as a user would
    function SelectRow([int]$row) {
        [void][Native.Win]::SendMessage($list, 0x0007, [IntPtr]::Zero, [IntPtr]::Zero)
        Key $list $VK_HOME
        for ($i = 0; $i -lt $row; $i++) { Key $list $VK_DOWN }
        Start-Sleep -Milliseconds 1500
    }
    SelectFolder 0
    $rows = WaitFor { if ((Rows) -ge 4) { Rows } }
    Check ($rows -eq 4) 'the messages are in the list'
    Shot $main 'main-1-inbox'

    Step 'reading an HTML message'
    SelectRow 0
    Check ([bool](WaitFor { Seen $newsletter })) 'showing the message marked it read on the server'
    Check (Visible $main $IDC_ATTACHMENTS) 'the paper clip of the attachments is there'
    Check (Visible $main $IDC_PICTURES) 'the information bar says pictures are blocked'
    $title = WindowText $main
    Check ($title -eq 'Inbox - Inbox Classic') "the title names the folder, as the folder bar does ($title)"
    Shot $main 'read-1-html'

    Step 'message properties'
    Command $main $IDM_PROPERTIES
    $properties = WaitWindow 'InboxClassicText' $null 10
    Check ($null -ne $properties) 'File > Properties opens the headers of the message'
    if ($properties) {
        $box = [Native.Win]::FindDescendants($properties, 'Edit') | Select-Object -First 1
        $headers = if ($box) { WindowText $box } else { '' }
        Check ($headers -match 'Subject: October newsletter' -and $headers -notmatch 'This message is') 'the headers, without the body'
        Shot $properties 'read-7-properties'
        Click $properties 1
        Check ([bool](WaitFor { -not [Native.Win]::IsWindow($properties) } 10)) 'OK closes it'
    }

    Step 'pictures from the internet'
    # a click on the information bar, as the mouse would
    $bar = [Native.Win]::GetDlgItem($main, $IDC_PICTURES)
    $point = [IntPtr]((8 -shl 16) -bor 40)
    [void][Native.Win]::PostMessage($bar, 0x0201, [IntPtr]1, $point)
    [void][Native.Win]::PostMessage($bar, 0x0202, [IntPtr]::Zero, $point)
    Check ([bool](WaitFor { -not (Visible $main $IDC_PICTURES) } 10)) 'clicking the bar shows the pictures, and the bar goes away'
    Start-Sleep -Seconds 3
    Shot $main 'read-2-pictures'

    Step 'saving the attachment'
    # the paper clip's menu, as its drop-down opens it
    Command $main $IDC_ATTACHMENTS
    $menu = WaitWindow '#32768' $null 10
    Check ($null -ne $menu) 'the paper clip offers the files to save'
    if ($menu) {
        Shot $main 'read-3-attachments' $menu
        # the keys once the menu takes them: on a slow machine it appears before it does
        $save = $null
        for ($try = 0; $try -lt 3 -and -not $save; $try++) {
            Start-Sleep -Milliseconds 500
            $menu = [Native.Win]::FindWindow('#32768', [NullString]::Value)
            if ($menu -ne [IntPtr]::Zero) {
                if ($try -eq 0) {
                    Key $menu $VK_DOWN
                    Key $menu $VK_RETURN
                } else {
                    # where the menu does not take posted keys (a CI runner): real keystrokes, the app in front
                    [void][Native.Win]::SetForegroundWindow($main)
                    [System.Windows.Forms.SendKeys]::SendWait('{DOWN}{ENTER}')
                }
            }
            $save = WaitWindow '#32770' 'Save Attachment As' 5
        }
        Check ($null -ne $save) 'choosing one asks where to save it'
        if ($save) {
            # the file name box: the edit field that holds the suggested name (Explorer may hide the extension)
            $name = WaitFor { [Native.Win]::FindDescendants($save, 'Edit') | Where-Object { (WindowText $_) -like 'report*' } | Select-Object -First 1 } 10
            Check ($null -ne $name) "the suggested name is the file's"
            Shot $save 'read-4-save'
            $target = Join-Path (Resolve-Path $Out) 'report-saved.pdf'
            if ($name) {
                # typed, as the dialog keeps its own copy of the name and does not see WM_SETTEXT
                [void][Native.Win]::SendMessage($name, $EM_SETSEL, [IntPtr]0, [IntPtr](-1))
                foreach ($c in $target.ToCharArray()) {
                    [void][Native.Win]::PostMessage($name, 0x0102, [IntPtr][int]$c, [IntPtr]::Zero)
                }
                Start-Sleep -Milliseconds 800
                Key $name $VK_RETURN
            }
            $saved = WaitFor { if (Test-Path $target) { Get-Content -Raw $target } } 10
            if (-not $saved) {
                Shot $save 'read-4-save-failed'
                [void][Native.Win]::PostMessage($save, $WM_CLOSE, [IntPtr]::Zero, [IntPtr]::Zero)
            }
            Check ($saved -eq $pdf) 'the attachment is saved as it was sent'
            # marked as from the internet, so SmartScreen and Protected View look at it when it is opened
            $zone = Get-Content -Path $target -Stream Zone.Identifier -ErrorAction SilentlyContinue
            Check (($zone -join "`n") -match 'ZoneId=3') 'and marked as from the internet'
        }
    }

    Step 'marking unread and read'
    Command $main $IDM_MARK_UNREAD
    Check ([bool](WaitFor { -not (Seen $newsletter) })) 'Mark Unread clears \Seen on the server'
    Shot $main 'read-5-unread'
    Command $main $IDM_MARK_READ
    Check ([bool](WaitFor { Seen $newsletter })) 'Mark Read sets it again'

    Step 'a reply with the earlier message folded'
    SelectRow 3
    Start-Sleep -Seconds 1
    Shot $main 'read-6-folded'

    # ---- writing ----

    # a compose window, once its fields are there (the window exists a moment before them)
    function WaitCompose {
        WaitFor {
            $c = [Native.Win]::FindWindow('InboxClassicCompose', [NullString]::Value)
            if ($c -ne [IntPtr]::Zero -and [Native.Win]::GetDlgItem($c, $IDC_BODY) -ne [IntPtr]::Zero) { $c }
        }
    }
    function CloseCompose([IntPtr]$compose) {
        [void][Native.Win]::PostMessage($compose, $WM_CLOSE, [IntPtr]::Zero, [IntPtr]::Zero)
        [void](WaitFor { -not [Native.Win]::IsWindow($compose) })
    }

    Step 'forwarding'
    SelectRow 0
    Command $main $IDM_FORWARD
    $compose = WaitCompose
    Check ($null -ne $compose) 'Forward opens a compose window'
    Check ((GetText $compose $IDC_SUBJECT) -eq "Fw: $newsletter") 'the subject is marked Fw:'
    Check ((GetText $compose $IDC_TO) -eq '') 'the recipients are left to the user'
    Shot $compose 'write-1-forward'
    CloseCompose $compose

    Step 'replying to all'
    SelectRow 2
    Command $main $IDM_REPLY_ALL
    $compose = WaitCompose
    Check ($null -ne $compose) 'Reply All opens a compose window'
    $to = GetText $compose $IDC_TO
    Check ($to -like '*bob@example.com*' -and $to -like '*dave@example.com*') "it goes to the sender and the others ($to)"
    Check ($to -notlike '*testuser@*') 'but not to the account itself'
    Check ((GetText $compose $IDC_CC) -like '*carol@example.com*') 'with the Cc kept'
    Check (Visible $compose $IDC_CC) 'the Cc row is open, as it has someone in it'
    Shot $compose 'write-2-reply-all'
    CloseCompose $compose

    Step 'replying'
    SelectRow 1
    Command $main $IDM_REPLY
    $compose = WaitCompose
    Check ($null -ne $compose) 'Reply opens a compose window'
    Check ((GetText $compose $IDC_TO) -like '*ann@example.com*') 'the reply goes to the sender'
    # the quote is folded behind "...", the cursor is at the top: Bold, then the answer
    [void](ClickEditor $compose)
    Command $compose $IDF_BOLD
    Check ([bool](WaitFor { Pressed $compose $IDF_BOLD } 10)) 'B shows bold is on'
    Check (TypeInEditor $compose 'Thanks, Ann. Answered by the UI test.') 'the editor takes typing'
    Shot $compose 'write-3-reply'
    # Select All unfolds the quote and selects it along with the text
    [void][Native.Win]::SetForegroundWindow($compose)
    [void](ClickEditor $compose)
    [System.Windows.Forms.SendKeys]::SendWait('^a')
    Start-Sleep -Milliseconds 800
    Shot $compose 'write-3b-select-all'
    # the cursor back to the end, so nothing selected is typed over
    [System.Windows.Forms.SendKeys]::SendWait('^{END}')
    Command $compose $IDC_SEND
    # ImapKit's SMTP server delivers to its INBOX
    $answer = WaitFor { Find 'INBOX' "Subject: Re: $subject" } 30
    Check ($null -ne $answer) 'the reply arrived over SMTP'
    if ($answer) {
        $text = RawText $answer
        Check ($text -match 'In-Reply-To: <ui-e2e@example.com>') 'the reply refers to the message it answers'
        Check ($text -match 'Answered by the UI test') 'the reply has what was typed'
        Check ($text -match 'Content-Type: text/html' -and $text -match 'Content-Type: text/plain') 'it is HTML with a text part'
        Check ($text -match '<b>Thanks, Ann') 'what was typed in bold is bold'
        Check ($text -match 'Original Message' -and $text -match 'this message was put here') 'the folded quote is sent along'
        # once in the HTML part and once in the text part: unfolded into the text, it is not added a second time
        Check ((([regex]::Matches($text, 'this message was put here')).Count) -eq 2) 'the quote is sent once'
    }
    Check ($null -ne (WaitFor { Find 'Sent' "Subject: Re: $subject" })) 'a copy of the reply is in Sent'

    Step 'a new message'
    Command $main $IDM_NEW_MAIL
    $compose = WaitCompose
    Check ($null -ne $compose) 'Create Mail opens an empty compose window'
    # only the rows that are needed: Cc, Bcc and Attach wait until there is something to put in them
    Check (-not (Visible $compose $IDC_CC) -and -not (Visible $compose $IDC_BCC) -and -not (Visible $compose $IDC_FILES)) 'a new message shows no empty Cc, Bcc or Attach row'
    Check ((Visible $compose $IDC_SHOW_CC) -and (Visible $compose $IDC_SHOW_BCC)) 'the Cc and Bcc buttons are at the end of the To row'
    Shot $compose 'write-0-new-empty'
    Command $compose $IDC_SHOW_CC
    Check ([bool](WaitFor { (Visible $compose $IDC_CC) -and -not (Visible $compose $IDC_SHOW_CC) } 10)) 'Cc opens its row, and its button goes'
    $from = GetText $compose $IDC_FROM
    Check ($from -eq 'UI Test <testuser@postalexpress.test>') "From names the account it goes from ($from)"
    SetText $compose $IDC_TO 'dave at example.com'
    SetText $compose $IDC_SUBJECT 'A new message from the UI test'
    Check (TypeInEditor $compose 'Hello Dave, written from scratch.') 'the editor of a new message takes typing'
    Command $compose $IDC_SEND
    $problem = WaitWindow '#32770' 'Inbox Classic' 10
    Check ($null -ne $problem) 'a mistyped address is pointed out before sending'
    if ($problem) {
        Shot $problem 'write-4-bad-address'
        [void][Native.Win]::PostMessage($problem, $WM_CLOSE, [IntPtr]::Zero, [IntPtr]::Zero)
    }
    Check ([bool](WaitFor { [Native.Win]::IsWindow($compose) -and [Native.Win]::FindWindow('#32770', 'Inbox Classic') -eq [IntPtr]::Zero })) 'and the message stays open to fix it'
    SetText $compose $IDC_TO 'Dave <dave@example.com>'
    # two files attached, one taken off again with Delete
    $files = Join-Path $env:TEMP 'pe-ui-attach'
    New-Item -ItemType Directory -Force $files | Out-Null
    Set-Content (Join-Path $files 'keep-me.txt') 'the attachment that goes'
    Set-Content (Join-Path $files 'wrong-file.txt') 'attached by mistake'
    $attached = [Native.Win]::GetDlgItem($compose, $IDC_FILES)
    $count = { [int][Native.Win]::SendMessage($attached, $LB_GETCOUNT, [IntPtr]::Zero, [IntPtr]::Zero) }
    foreach ($file in 'keep-me.txt', 'wrong-file.txt') {
        $before = & $count
        Command $compose $IDC_ATTACH
        [void](AnswerFileDialog 'Insert Attachment' (Join-Path $files $file) $null)
        [void](WaitFor { (& $count) -gt $before } 10)
    }
    Check ([bool](WaitFor { (& $count) -eq 2 } 10)) 'Attach adds the files to the Attach row'
    Shot $compose 'write-5-new'
    [void][Native.Win]::SendMessage($attached, $LB_SETCURSEL, [IntPtr]1, [IntPtr]::Zero)
    Key $attached $VK_DELETE
    Check ([bool](WaitFor { (& $count) -eq 1 } 10)) 'Delete in the Attach row takes one off'
    Command $compose $IDC_SEND
    $new = WaitFor { Find 'INBOX' 'Subject: A new message from the UI test' } 30
    Check ($null -ne $new) 'the new message was sent'
    Check ($new -and (RawText $new) -match 'Hello Dave, written from scratch') 'with what was typed'
    Check ($new -and (RawText $new) -match 'keep-me\.txt' -and (RawText $new) -notmatch 'wrong-file') 'with only the file left attached'
    Check ($new -and (RawText $new) -match 'Content-Type: text/plain' -and (RawText $new) -notmatch 'Content-Type: text/html') 'nothing formatted: it went as plain text'

    Step 'the Outbox: a send that can not go'
    # the outgoing server out of reach, as when offline: its port changed in Accounts > Properties to one nothing
    # listens on, and back
    function SetSmtpPort([string]$port) {
        Command $main $IDM_ACCOUNTS
        $list = WaitWindow 'InboxClassicAccounts' 'Accounts'
        Click $list 402
        $form = WaitFor {
            $f = [Native.Win]::FindWindow('InboxClassicForm', 'Properties')
            if ($f -ne [IntPtr]::Zero -and [Native.Win]::GetDlgItem($f, 109) -ne [IntPtr]::Zero) { $f }
        }
        SetText $form 108 $port
        Click $form 1
        # a question about a connection without encryption: Yes
        [void](WaitFor {
            $box = [Native.Win]::FindWindow('#32770', 'Properties')
            if ($box -ne [IntPtr]::Zero) { Click $box 6 }
            -not [Native.Win]::IsWindow($form)
        } 10)
        Click $list 404
        [void](WaitFor { -not [Native.Win]::IsWindow($list) })
    }
    SetSmtpPort '1'
    Command $main $IDM_NEW_MAIL
    $compose = WaitCompose
    Check ([Native.Win]::GetDlgItem($compose, 308) -eq [IntPtr]::Zero) 'there is no Send Later: Send sends'
    SetText $compose $IDC_TO 'Erin <erin@example.com>'
    SetText $compose $IDC_SUBJECT 'Waited in the Outbox in the UI test'
    [void](TypeInEditor $compose 'This waited in the Outbox.')
    Command $compose $IDC_SEND
    Check ([bool](WaitFor { -not [Native.Win]::IsWindow($compose) })) 'Send closes the message'
    $status = [Native.Win]::FindWindowEx($main, [IntPtr]::Zero, 'msctls_statusbar32', [NullString]::Value)
    Check ($null -ne (WaitFor { $t = WindowText $status; if ($t -match 'Outbox') { $t } } 40)) 'a send that can not go says it waits in the Outbox'
    Check ($null -eq (Find 'INBOX' 'Subject: Waited in the Outbox in the UI test')) 'and it was not sent'
    Command $main $IDM_OUTBOX
    $outbox = WaitWindow 'InboxClassicOutbox' 'Outbox'
    Check ($null -ne $outbox) 'Tools > Outbox lists what waits'
    if ($outbox) {
        $waiting = [int][Native.Win]::SendMessage([Native.Win]::GetDlgItem($outbox, 450), $LVM_GETITEMCOUNT, [IntPtr]::Zero, [IntPtr]::Zero)
        Check ($waiting -eq 1) 'the message is in it'
        Shot $outbox 'write-7-outbox'
        [void][Native.Win]::PostMessage($outbox, $WM_CLOSE, [IntPtr]::Zero, [IntPtr]::Zero)
        [void](WaitFor { -not [Native.Win]::IsWindow($outbox) })
    }
    # the server back: the settings change syncs the account, and a sync sends the Outbox first
    SetSmtpPort "$($ports.smtp)"
    Check ($null -ne (WaitFor { Find 'INBOX' 'Subject: Waited in the Outbox in the UI test' } 30)) 'once the server is back it goes by itself'

    Step 'Drafts'
    Command $main $IDM_NEW_MAIL
    $compose = WaitCompose
    SetText $compose $IDC_TO 'Fay <fay@example.com>'
    SetText $compose $IDC_SUBJECT 'Draft from the UI test'
    [void](TypeInEditor $compose 'Half written.')
    # closing what was written asks whether to keep it; Yes saves it in Drafts
    [void][Native.Win]::PostMessage($compose, $WM_CLOSE, [IntPtr]::Zero, [IntPtr]::Zero)
    $ask = WaitWindow '#32770' 'Inbox Classic' 10
    Check ($null -ne $ask) 'closing a written message asks to save it'
    if ($ask) {
        Shot $ask 'write-8-save-draft'
        Click $ask 6
    }
    Check ([bool](WaitFor { -not [Native.Win]::IsWindow($compose) })) 'Yes saves it and closes the window'
    $draft = WaitFor { Find 'Drafts' 'Subject: Draft from the UI test' } 30
    Check ($null -ne $draft) 'the draft is in Drafts on the server'
    Check ($draft -and $draft.flags -contains '\Draft') 'marked as a draft'
    # Drafts is the third folder; Enter on the draft opens it to go on writing
    SelectFolder 2
    Check ($null -ne (WaitFor { if ((Rows) -ge 1) { Rows } })) 'Drafts lists it'
    SelectRow 0
    Key $list $VK_RETURN
    $compose = WaitCompose
    Check ($null -ne $compose) 'opening the draft opens a compose window'
    if ($compose) {
        Check ((GetText $compose $IDC_SUBJECT) -eq 'Draft from the UI test') 'with its subject'
        Check ((GetText $compose $IDC_TO) -like '*fay@example.com*') 'and its recipient'
        [void][Native.Win]::SetForegroundWindow($compose)
        [System.Windows.Forms.SendKeys]::SendWait('^{END}')
        [void](TypeInEditor $compose 'Now finished. ')
        Shot $compose 'write-9-draft-reopened'
        # saved again: one draft, the new one
        Command $compose $IDC_SAVE
        Check ($null -ne (WaitFor { $d = @(Messages 'Drafts'); if ($d.Count -eq 1 -and (RawText $d[0]) -match 'Now finished') { $d } } 30)) 'Save replaces the draft'
        Command $compose $IDC_SEND
        $finished = WaitFor { Find 'INBOX' 'Subject: Draft from the UI test' } 30
        Check ($null -ne $finished) 'the finished draft is sent'
        Check ($finished -and (RawText $finished) -match 'Half written' -and (RawText $finished) -match 'Now finished') 'with all that was written'
        Check ([bool](WaitFor { @(Messages 'Drafts').Count -eq 0 } 30)) 'and its draft is gone'
    }
    SelectFolder 0

    # ---- getting new mail ----

    Step 'Send/Recv'
    AddMessage ("From: Ann Example <ann@example.com>`r`nTo: testuser@postalexpress.test`r`nSubject: One more thing`r`n" +
        "Message-ID: <later@example.com>`r`nDate: $([DateTime]::UtcNow.ToString('r'))`r`n`r`nArrived later.`r`n")
    Command $main $IDM_SYNC
    Check ($null -ne (WaitFor { if ((Rows) -ge 7) { Rows } } 30)) 'the new mail is in the list'
    Shot $main 'main-2-new-mail'
    SelectFolder 1
    Check ($null -ne (WaitFor { if ((Rows) -ge 2) { Rows } })) 'Sent Items has what was sent'
    SelectRow 0
    Shot $main 'main-3-sent-items'
    SelectFolder 0

    # ---- finding ----

    Step 'finding'
    SelectFolder 0
    $all = WaitFor { if ((Rows) -ge 7) { Rows } }
    $find = [Native.Win]::GetDlgItem($main, 204)
    Check ($find -ne [IntPtr]::Zero) 'there is a Find box'
    [void][Native.Win]::SendMessage($find, $WM_SETTEXT, [IntPtr]::Zero, 'lunch')
    Check ([bool](WaitFor { (Rows) -eq 1 })) 'typing in it narrows the list to what has it (the subject)'
    $status = WindowText ([Native.Win]::FindWindowEx($main, [IntPtr]::Zero, 'msctls_statusbar32', [NullString]::Value))
    Shot $main 'find-1-results'
    [void][Native.Win]::SendMessage($find, $WM_SETTEXT, [IntPtr]::Zero, 'ann@example.com')
    Check ([bool](WaitFor { (Rows) -ge 2 })) 'the sender address is found too'
    [void][Native.Win]::SendMessage($find, $WM_SETTEXT, [IntPtr]::Zero, 'nothing has this')
    Check ([bool](WaitFor { (Rows) -eq 0 })) 'and nothing when nothing has it'
    [void][Native.Win]::SendMessage($find, $WM_SETTEXT, [IntPtr]::Zero, '')
    Check ([bool](WaitFor { (Rows) -eq $all })) 'clearing it shows the whole folder again'

    # ---- files ----

    Step 'saving and importing a message as a file'
    SelectFolder 0
    [void](WaitFor { if ((Rows) -ge 7) { Rows } })
    # Carol's reply, the last row (the oldest)
    SelectRow ((Rows) - 1)
    $eml = Join-Path (Resolve-Path $Out) 'saved-message.eml'
    Remove-Item -Force -ErrorAction SilentlyContinue $eml
    Command $main $IDM_SAVE_AS
    Check (AnswerFileDialog 'Save Message As' $eml 'files-1-save-as' 'Re*Lunch on Friday*') 'Save As asks where, with the subject as the name'
    Check ([bool](WaitFor { (Test-Path $eml) -and (Get-Content -Raw $eml) -match 'Subject: Re: Lunch on Friday' } 10)) 'and saves the message as it came'
    SelectFolder 3
    Command $main $IDM_IMPORT
    Check (AnswerFileDialog 'Import Messages' $eml 'files-2-import') 'Import Messages asks for files'
    Check ($null -ne (WaitFor { Find 'Archive' 'Subject: Re: Lunch on Friday' } 20)) 'and puts the message in the folder, on the server'
    SelectFolder 0

    # ---- flag, delete, move ----

    Step 'flagging, deleting and moving'
    SelectFolder 0
    [void](WaitFor { if ((Rows) -ge 7) { Rows } })
    # the newest message, "One more thing"
    SelectRow 0
    Check (-not (Visible $main $IDC_PICTURES)) 'a plain text message does not offer Download pictures'
    Command $main $IDM_FLAG
    Check ([bool](WaitFor { (Find 'INBOX' 'Subject: One more thing').flags -contains '\Flagged' })) 'Flag Message flags it on the server'
    Shot $main 'organize-1-flagged'
    $listed = Rows
    Command $main $IDM_DELETE
    Check ($null -ne (WaitFor { Find 'Trash' 'Subject: One more thing' } 20)) 'Delete puts it in Deleted Items'
    Check ($null -eq (Find 'INBOX' 'Subject: One more thing')) 'and takes it out of the Inbox'
    Check ([bool](WaitFor { (Rows) -eq $listed - 1 })) 'the list has one less'
    # the next one is selected: move it to Archive through the dialog
    Command $main $IDM_MOVE
    $move = WaitFor {
        $f = [Native.Win]::FindWindow('InboxClassicForm', 'Move')
        if ($f -ne [IntPtr]::Zero -and [Native.Win]::GetDlgItem($f, 100) -ne [IntPtr]::Zero) { $f }
    }
    Check ($null -ne $move) 'Move to Folder asks where'
    if ($move) {
        [void][Native.Win]::SendMessage([Native.Win]::GetDlgItem($move, 100), $CB_SELECTSTRING, [IntPtr](-1), 'Archive')
        Shot $move 'organize-2-move'
        Click $move 1
        # the one selected after the delete: the newest, the message sent later
        Check ($null -ne (WaitFor { Find 'Archive' 'Subject: Draft from the UI test' } 20)) 'the selected message is in Archive'
        Check ([bool](WaitFor { (Rows) -eq $listed - 2 })) 'and out of the list'
    }
    Shot $main 'organize-3-after'
    # from Deleted Items it is gone for good, after asking
    SelectFolder 5
    [void](WaitFor { if ((Rows) -ge 1) { Rows } })
    SelectRow 0
    Command $main $IDM_DELETE
    $sure = WaitWindow '#32770' 'Inbox Classic' 10
    Check ($null -ne $sure) 'deleting for good asks first'
    if ($sure) {
        Shot $sure 'organize-4-for-good'
        Click $sure 6
    }
    Check ([bool](WaitFor { -not (Find 'Trash' 'Subject: One more thing') } 20)) 'and then it is gone from the server'
    SelectFolder 0

    # ---- folders ----

    Step 'folders'
    function Mailboxes { @(Invoke-RestMethod $rest) | ForEach-Object { $_.path } }
    # a folder of the form that asks for a name: its name typed and OK clicked
    function AnswerName([string]$title, [string]$name, [string]$shot) {
        $form = WaitFor {
            $f = [Native.Win]::FindWindow('InboxClassicForm', $title)
            if ($f -ne [IntPtr]::Zero -and [Native.Win]::GetDlgItem($f, 100) -ne [IntPtr]::Zero) { $f }
        }
        Check ($null -ne $form) "$title asks for a name"
        if ($form) {
            SetText $form 100 $name
            if ($shot) { Shot $form $shot }
            Click $form 1
        }
    }
    SelectFolder 3
    Command $main $IDM_NEW_FOLDER
    AnswerName 'New Folder' 'Projects' 'folders-1-new'
    Check ([bool](WaitFor { (Mailboxes) -contains 'Archive/Projects' } 20)) 'New Folder makes Archive/Projects on the server'
    # the first folder in Archive, found again each time: the tree is built anew when the folders change
    function ArchiveChild {
        $item = [Native.Win]::SendMessage($tree, $TVM_GETNEXTITEM, [IntPtr]4, [Native.Win]::SendMessage($tree, $TVM_GETNEXTITEM, [IntPtr]0, [IntPtr]::Zero))
        for ($i = 0; $i -lt 3; $i++) { $item = [Native.Win]::SendMessage($tree, $TVM_GETNEXTITEM, [IntPtr]1, $item) }
        $child = [Native.Win]::SendMessage($tree, $TVM_GETNEXTITEM, [IntPtr]4, $item)
        if ($child -ne [IntPtr]::Zero) { $child }
    }
    $projects = WaitFor { ArchiveChild }
    Check ($null -ne $projects) 'and it is in the tree'
    if ($projects) {
        [void][Native.Win]::SendMessage($tree, $TVM_SELECTITEM, [IntPtr]9, $projects)
        Shot $main 'folders-2-tree'
        Command $main $IDM_RENAME_FOLDER
        AnswerName 'Rename Folder' 'Plans' $null
        Check ([bool](WaitFor { (Mailboxes) -contains 'Archive/Plans' -and (Mailboxes) -notcontains 'Archive/Projects' } 20)) 'Rename renames it on the server'
        Start-Sleep -Milliseconds 500
        $plans = WaitFor { ArchiveChild }
        [void][Native.Win]::SendMessage($tree, $TVM_SELECTITEM, [IntPtr]9, $plans)
        Command $main $IDM_DELETE_FOLDER
        $sure = WaitWindow '#32770' 'Inbox Classic' 10
        Check ($null -ne $sure) 'deleting a folder asks first'
        if ($sure) {
            Shot $sure 'folders-3-delete'
            Click $sure 6
        }
        Check ([bool](WaitFor { (Mailboxes) -notcontains 'Archive/Plans' } 20)) 'and Yes deletes it on the server'
    }
    # the Inbox is not renamed
    SelectFolder 0
    Command $main $IDM_RENAME_FOLDER
    AnswerName 'Rename Folder' 'Mail' $null
    $refused = WaitWindow '#32770' 'Inbox Classic' 10
    Check ($null -ne $refused) 'renaming the Inbox is refused with the reason'
    if ($refused) {
        Shot $refused 'folders-4-inbox'
        [void][Native.Win]::PostMessage($refused, $WM_CLOSE, [IntPtr]::Zero, [IntPtr]::Zero)
        [void](WaitFor { [Native.Win]::FindWindow('#32770', 'Inbox Classic') -eq [IntPtr]::Zero })
    }

    Step 'closing a message that was written'
    Command $main $IDM_NEW_MAIL
    $compose = WaitCompose
    [void](TypeInEditor $compose 'Never mind.')
    [void][Native.Win]::PostMessage($compose, $WM_CLOSE, [IntPtr]::Zero, [IntPtr]::Zero)
    $ask = WaitWindow '#32770' 'Inbox Classic' 10
    Check ($null -ne $ask) 'closing asks before throwing the text away'
    if ($ask) {
        Shot $ask 'write-6-close'
        # No: closed without saving
        Click $ask 7
    }
    Check ([bool](WaitFor { -not [Native.Win]::IsWindow($compose) })) 'No closes it'
    Start-Sleep -Seconds 1
    Check ($null -eq (Find 'Drafts' 'Never mind')) 'without saving it'

    # ---- a provider found by its MX, one that wants an app password ----

    Step 'a Gmail address'
    Command $main $IDM_NEW_ACCOUNT
    $first = StartPage $true
    SetText $first 100 'Gmail Test'
    SetText $first 101 'postalexpress.test@gmail.com'
    Click $first 1
    # Gmail signs in through the browser (the Google client is built in): its button is offered first; the test can
    # not sign in to Google, so Use App Password here, and the password way follows
    $browser = StartPage $false 40
    Check ($browser -and [Native.Win]::GetDlgItem($browser, 120) -ne [IntPtr]::Zero -and [Native.Win]::GetDlgItem($browser, 121) -eq [IntPtr]::Zero) 'a Gmail address is offered Sign in with Google'
    if ($browser) {
        Shot $browser 'account-5b-browser-sign-in'
        Click $browser 1
        [void](WaitFor { -not [Native.Win]::IsWindow($browser) } 10)
    }
    $hint = WaitWindow '#32770' 'Add Mail Account' 40
    Check ($null -ne $hint) 'without it, Gmail wants an app password, and that is said'
    if ($hint) {
        Shot $hint 'account-5-app-password'
        # No: not now to the instructions
        Click $hint 7
    }
    $servers = WaitFor {
        $f = [Native.Win]::FindWindow('InboxClassicForm', 'Add Mail Account')
        if ($f -ne [IntPtr]::Zero -and [Native.Win]::GetDlgItem($f, 109) -ne [IntPtr]::Zero) { $f }
    } 20
    Check ($servers -and (GetText $servers 104) -eq 'imap.gmail.com' -and (GetText $servers 107) -eq 'smtp.gmail.com') 'its servers were found'
    if ($servers) {
        Shot $servers 'account-6-gmail'
        Click $servers 2
        [void](WaitFor { -not [Native.Win]::IsWindow($servers) })
    }

    # ---- a wrong password ----

    Step 'a wrong password'
    Command $main $IDM_NEW_ACCOUNT
    AddAccount 'Wrong Password' 'testuser2' 'not-the-password' $false
    $logon = WaitWindow 'InboxClassicForm' 'Logon' 30
    Check ($null -ne $logon) 'a refused password is asked for again'
    if ($logon) {
        $status = [Native.Win]::FindWindowEx($main, [IntPtr]::Zero, 'msctls_statusbar32', [NullString]::Value)
        $status = WindowText $status
        Check ($status -match 'authentication') "the status bar says why ($status)"
        Shot $main 'trouble-1-password'
        Click $logon 2
    }

    # ---- accounts ----

    Step 'accounts'
    Command $main $IDM_ACCOUNTS
    $accounts = WaitWindow 'InboxClassicAccounts' 'Accounts'
    Check ($null -ne $accounts) 'File > Accounts lists the accounts'
    if ($accounts) {
        $accountList = [Native.Win]::GetDlgItem($accounts, 400)
        Check ([int][Native.Win]::SendMessage($accountList, $LVM_GETITEMCOUNT, [IntPtr]::Zero, [IntPtr]::Zero) -eq 2) 'both accounts are listed'
        Shot $accounts 'accounts-1-list'
        # Properties of the first: a new display name
        # the first account is selected when the list opens, and stays so after a change
        Click $accounts 402
        $properties = WaitFor {
            $f = [Native.Win]::FindWindow('InboxClassicForm', 'Properties')
            if ($f -ne [IntPtr]::Zero -and [Native.Win]::GetDlgItem($f, 109) -ne [IntPtr]::Zero) { $f }
        }
        Check ($null -ne $properties) 'Properties shows the settings'
        if ($properties) {
            Check ((GetText $properties 105) -eq "$($ports.imap)") 'with the IMAP port as it was saved'
            SetText $properties 100 'UI Test Renamed'
            Shot $properties 'accounts-2-properties'
            Click $properties 1
            Check ([bool](WaitFor { -not [Native.Win]::IsWindow($properties) } 10)) 'OK closes Properties'
            $box = [Native.Win]::FindWindow('#32770', [NullString]::Value)
            if ($box -ne [IntPtr]::Zero) {
                Write-Host "   a message box is open: $(WindowText $box)"
                Shot $box 'accounts-unexpected'
            }
        }
        # read back in Properties (the text of a list entry does not cross processes)
        Click $accounts 402
        $again = WaitFor {
            $f = [Native.Win]::FindWindow('InboxClassicForm', 'Properties')
            if ($f -ne [IntPtr]::Zero -and [Native.Win]::GetDlgItem($f, 109) -ne [IntPtr]::Zero) { $f }
        }
        Check ($again -and (GetText $again 100) -eq 'UI Test Renamed') 'the new name is saved'
        if ($again) {
            Click $again 2
            [void](WaitFor { -not [Native.Win]::IsWindow($again) })
        }
        # Remove the second, the one with the wrong password
        $before = [int][Native.Win]::SendMessage($tree, $TVM_GETCOUNT, [IntPtr]::Zero, [IntPtr]::Zero)
        Key $accountList $VK_DOWN
        Start-Sleep -Milliseconds 300
        # the Delete key in the list does what Remove does
        Key $accountList $VK_DELETE
        $sure = WaitWindow '#32770' 'Remove Account' 10
        Check ($null -ne $sure) 'Remove (or Delete) asks first'
        if ($sure) { Click $sure 6 }
        Check ([bool](WaitFor { [int][Native.Win]::SendMessage($accountList, $LVM_GETITEMCOUNT, [IntPtr]::Zero, [IntPtr]::Zero) -eq 1 })) 'and removes it'
        Click $accounts 404
        [void](WaitFor { -not [Native.Win]::IsWindow($accounts) })
        $after = WaitFor { $n = [int][Native.Win]::SendMessage($tree, $TVM_GETCOUNT, [IntPtr]::Zero, [IntPtr]::Zero); if ($n -lt $before) { $n } }
        Check ($null -ne $after) "the account leaves the tree ($before items before)"
        Shot $main 'accounts-3-after'
    }

    # ---- about and help ----

    Step 'about'
    Command $main $IDM_ABOUT
    $about = WaitWindow '#32770' 'About Inbox Classic'
    Check ($null -ne $about) 'About shows the version'
    if ($about) {
        Shot $about 'help-1-about'
        [void][Native.Win]::PostMessage($about, $WM_CLOSE, [IntPtr]::Zero, [IntPtr]::Zero)
        [void](WaitFor { [Native.Win]::FindWindow('#32770', 'About Inbox Classic') -eq [IntPtr]::Zero })
    }

    Step 'help'
    Command $main $IDM_HELP
    $help = WaitWindow 'InboxClassicHelp'
    Check ($null -ne $help) 'F1 opens the help'
    if ($help) {
        Start-Sleep -Seconds 3
        Shot $help 'help-2-contents'
        [void][Native.Win]::PostMessage($help, $WM_CLOSE, [IntPtr]::Zero, [IntPtr]::Zero)
    }

    Step 'printing'
    SelectFolder 0
    [void](WaitFor { if ((Rows) -ge 1) { Rows } })
    SelectRow 1
    Command $main $IDM_PRINT
    # a window of its own over the app with the print preview in it, rather than a preview inside the reading pane
    $print = WaitWindow 'InboxClassicPrint' $null 20
    Check ($null -ne $print) 'Print opens the print preview in a window over the app'
    if (-not $print) {
        # what is there instead: the visible top-level windows with a title
        $w = [IntPtr]::Zero
        while (($w = [Native.Win]::FindWindowEx([IntPtr]::Zero, $w, [NullString]::Value, [NullString]::Value)) -ne [IntPtr]::Zero) {
            # not WM_GETTEXT: a hung window (a print dialog left behind) would block the test for good
            $text = New-Object System.Text.StringBuilder 256
            [void][Native.Win]::InternalGetWindowText($w, $text, 256)
            $title = $text.ToString()
            if ($title -and [Native.Win]::IsWindowVisible($w)) {
                $class = New-Object System.Text.StringBuilder 256
                [void][Native.Win]::GetClassName($w, $class, 256)
                Write-Host "   window: '$title' ($class)"
            }
        }
        Shot $main 'files-3-print-missing'
    }
    if ($print) {
        $printRect = New-Object Native.Win+RECT
        $mainRect = New-Object Native.Win+RECT
        [void][Native.Win]::GetWindowRect($print, [ref]$printRect)
        [void][Native.Win]::GetWindowRect($main, [ref]$mainRect)
        Check (($printRect.Right - $printRect.Left) -ge ($mainRect.Right - $mainRect.Left)) 'as wide as the app'
        # the preview takes a moment to lay the message out
        Start-Sleep -Seconds 5
        Shot $print 'files-3-print'
        [void][Native.Win]::PostMessage($print, $WM_CLOSE, [IntPtr]::Zero, [IntPtr]::Zero)
        Check ([bool](WaitFor { -not [Native.Win]::IsWindow($print) } 10)) 'and closing it prints nothing'
    }

    Step 'closing'
    [void][Native.Win]::PostMessage($main, $WM_CLOSE, [IntPtr]::Zero, [IntPtr]::Zero)
    Check ($app.WaitForExit(15000)) 'the app closes'
} catch {
    Check $false "unexpected error: $_ at line $($_.InvocationInfo.ScriptLineNumber)"
} finally {
    if ($app -and -not $app.HasExited) { $app.Kill() }
    $harness.StandardInput.Close()
    if (-not $harness.WaitForExit(5000)) { $harness.Kill() }
}

$result = if ($failures.Count) { "FAILED: $($failures -join '; ')" } else { 'passed' }
Write-Host $result
Stop-Transcript | Out-Null
Set-Content -Path (Join-Path $Out 'result.txt') -Value $result
if ($failures.Count) { exit 1 }
