# The app end to end, driven the way a user drives it, against ImapKit (core/e2e): adds an account through the
# account form, waits for the sync, opens a message (and checks on the server that it was marked read), answers it
# from the compose window (and checks that the answer arrived over SMTP and was kept in Sent), and opens the help.
# Screenshots of each step go to -Out.
#
#   powershell -ExecutionPolicy Bypass -File scripts\ui-e2e.ps1 [-Exe build\PostalExpress.exe] [-Out build\ui-e2e]
#
# Needs a desktop (a logged in session, or a CI runner), Node.js and `npm ci` in core\e2e. The app runs with a
# store of its own and --memory-passwords, so nothing of the user's is touched. The control and command ids are those
# of app/src/app.h, accounts.cpp and compose.cpp.
param(
    [string]$Exe = (Join-Path $PSScriptRoot '..\build\PostalExpress.exe'),
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
public struct RECT { public int Left, Top, Right, Bottom; }
'@
[void][Native.Win]::SetProcessDPIAware()

$WM_SETTEXT = 0x000C; $WM_GETTEXT = 0x000D; $WM_CLOSE = 0x0010; $WM_COMMAND = 0x0111; $WM_KEYDOWN = 0x0100
$WM_KEYUP = 0x0101; $BM_CLICK = 0x00F5; $CB_SETCURSEL = 0x014E; $EM_SETSEL = 0x00B1; $EM_REPLACESEL = 0x00C2
$TVM_GETCOUNT = 0x1105; $TVM_GETNEXTITEM = 0x110A; $TVM_SELECTITEM = 0x110B; $LVM_GETITEMCOUNT = 0x1004
$IDM_REPLY = 108; $IDM_HELP = 111; $IDC_TREE = 200; $IDC_LIST = 201; $IDC_SEND = 300; $IDC_TO = 302; $IDC_BODY = 306

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

function Shot([IntPtr]$hwnd, [string]$name) {
    [void][Native.Win]::SetWindowPos($hwnd, [IntPtr](-1), 0, 0, 0, 0, 0x13)
    Start-Sleep -Milliseconds 500
    $rect = New-Object Native.Win+RECT
    [void][Native.Win]::GetWindowRect($hwnd, [ref]$rect)
    $bitmap = New-Object System.Drawing.Bitmap ($rect.Right - $rect.Left), ($rect.Bottom - $rect.Top)
    [System.Drawing.Graphics]::FromImage($bitmap).CopyFromScreen($rect.Left, $rect.Top, 0, 0, $bitmap.Size)
    [void][Native.Win]::SetWindowPos($hwnd, [IntPtr](-2), 0, 0, 0, 0, 0x13)
    $bitmap.Save((Join-Path $Out "$name.png"), [System.Drawing.Imaging.ImageFormat]::Png)
}

function SetText([IntPtr]$window, [int]$id, [string]$text) {
    [void][Native.Win]::SendMessage([Native.Win]::GetDlgItem($window, $id), $WM_SETTEXT, [IntPtr]::Zero, $text)
}
function GetText([IntPtr]$window, [int]$id) {
    $buffer = New-Object System.Text.StringBuilder 4096
    [void][Native.Win]::SendMessage([Native.Win]::GetDlgItem($window, $id), $WM_GETTEXT, [IntPtr]4096, $buffer)
    return $buffer.ToString()
}
function Click([IntPtr]$window, [int]$id) {
    [void][Native.Win]::PostMessage([Native.Win]::GetDlgItem($window, $id), $BM_CLICK, [IntPtr]::Zero, [IntPtr]::Zero)
}

# ---- ImapKit ----

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
    @(Invoke-RestMethod "$rest/$([uri]::EscapeDataString($mailbox))/messages?raw=true")
}
# the REST API gives the source base64 encoded
function RawText($message) { [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($message.raw)) }
$subject = 'Hello from the UI test'
$raw = "From: Ann Example <ann@example.com>`r`nTo: testuser@postalexpress.test`r`nSubject: $subject`r`nMessage-ID: <ui-e2e@example.com>`r`nDate: Mon, 6 Oct 2025 10:00:00 +0000`r`n`r`nHi,`r`nthis message was put here by scripts/ui-e2e.ps1.`r`n"
$body = @{ raw = $raw; flags = @() } | ConvertTo-Json
[void](Invoke-RestMethod -Method Post -ContentType 'application/json' -Body $body "$rest/INBOX/messages")

$app = $null
try {
    # ---- the app, its account form ----

    Step 'starting PostalExpress with a store of its own'
    $store = Join-Path $Out 'store.db'
    Remove-Item -Force -ErrorAction SilentlyContinue "$store*"
    # ImapKit's certificate is self-signed: the app trusts it, and only it, for this run
    $arguments = @('--store', "`"$store`"", '--memory-passwords', '--pin-certificate', "`"$($ports.cert)`"")
    $app = Start-Process -FilePath $Exe -ArgumentList $arguments -PassThru
    $first = WaitFor { $f = [Native.Win]::FindWindow('PostalExpressForm', 'Add Mail Account'); if ($f -ne [IntPtr]::Zero) { $f } }
    Check ($null -ne $first) 'the account form opens on the first start'
    SetText $first 100 'UI Test'
    SetText $first 101 'testuser@postalexpress.test'
    SetText $first 102 'testpass'
    Shot $first '1-account-form'
    Click $first 1

    # the lookup finds nothing for this domain: the second form comes with the usual names to correct
    $second = WaitFor {
        $f = [Native.Win]::FindWindow('PostalExpressForm', 'Add Mail Account')
        if ($f -ne [IntPtr]::Zero -and [Native.Win]::GetDlgItem($f, 109) -ne [IntPtr]::Zero) { $f }
    } 40
    Check ($null -ne $second) 'the server settings form follows the lookup'
    Check ((GetText $second 104) -eq 'imap.postalexpress.test') 'the lookup guessed the IMAP server'
    SetText $second 102 'testuser'
    SetText $second 104 '127.0.0.1'
    SetText $second 105 "$($ports.imap)"
    [void][Native.Win]::SendMessage([Native.Win]::GetDlgItem($second, 106), $CB_SETCURSEL, [IntPtr]2, [IntPtr]::Zero)
    SetText $second 107 '127.0.0.1'
    SetText $second 108 "$($ports.smtp)"
    # ImapKit's SMTP server takes a password only after STARTTLS
    [void][Native.Win]::SendMessage([Native.Win]::GetDlgItem($second, 109), $CB_SETCURSEL, [IntPtr]1, [IntPtr]::Zero)
    Shot $second '2-server-settings'
    Click $second 1
    # the warning about a connection without encryption: Yes
    $warning = WaitFor { $w = [Native.Win]::FindWindow('#32770', 'Add Mail Account'); if ($w -ne [IntPtr]::Zero) { $w } }
    Check ($null -ne $warning) 'a connection without encryption is warned about'
    Click $warning 6

    # ---- reading ----

    Step 'syncing and reading'
    $main = [Native.Win]::FindWindow('PostalExpressMain', [NullString]::Value)
    $tree = [Native.Win]::GetDlgItem($main, $IDC_TREE)
    $list = [Native.Win]::GetDlgItem($main, $IDC_LIST)
    $folders = WaitFor { $n = [int][Native.Win]::SendMessage($tree, $TVM_GETCOUNT, [IntPtr]::Zero, [IntPtr]::Zero); if ($n -ge 3) { $n } }
    Check ($null -ne $folders) "the folders of the account are in the tree ($folders)"
    $root = [Native.Win]::SendMessage($tree, $TVM_GETNEXTITEM, [IntPtr]0, [IntPtr]::Zero)
    $inbox = [Native.Win]::SendMessage($tree, $TVM_GETNEXTITEM, [IntPtr]4, $root)
    [void][Native.Win]::SendMessage($tree, $TVM_SELECTITEM, [IntPtr]9, $inbox)
    $rows = WaitFor { $n = [int][Native.Win]::SendMessage($list, $LVM_GETITEMCOUNT, [IntPtr]::Zero, [IntPtr]::Zero); if ($n -ge 1) { $n } }
    Check ($rows -eq 1) 'the message is in the list'
    [void][Native.Win]::SendMessage($list, 0x0007, [IntPtr]::Zero, [IntPtr]::Zero)
    [void][Native.Win]::PostMessage($list, $WM_KEYDOWN, [IntPtr]0x24, [IntPtr]::Zero)
    [void][Native.Win]::PostMessage($list, $WM_KEYUP, [IntPtr]0x24, [IntPtr]::Zero)
    $seen = WaitFor { (Messages 'INBOX')[0].flags -contains '\Seen' } 20
    Check ([bool]$seen) 'showing the message marked it read on the server'
    Shot $main '3-reading'

    # ---- answering ----

    Step 'replying'
    [void][Native.Win]::PostMessage($main, $WM_COMMAND, [IntPtr]$IDM_REPLY, [IntPtr]::Zero)
    $compose = WaitFor { $c = [Native.Win]::FindWindow('PostalExpressCompose', [NullString]::Value); if ($c -ne [IntPtr]::Zero) { $c } }
    Check ($null -ne $compose) 'Reply opens a compose window'
    Check ((GetText $compose $IDC_TO) -like '*ann@example.com*') 'the reply goes to the sender'
    $bodyField = [Native.Win]::GetDlgItem($compose, $IDC_BODY)
    [void][Native.Win]::SendMessage($bodyField, $EM_SETSEL, [IntPtr]0, [IntPtr]0)
    [void][Native.Win]::SendMessage($bodyField, $EM_REPLACESEL, [IntPtr]1, 'Thanks, Ann. Answered by the UI test.')
    Shot $compose '4-reply'
    [void][Native.Win]::PostMessage($compose, $WM_COMMAND, [IntPtr]$IDC_SEND, [IntPtr]::Zero)
    # ImapKit's SMTP server delivers to its INBOX
    $answer = WaitFor { (Messages 'INBOX') | Where-Object { (RawText $_) -match "Subject: Re: $subject" } } 30
    Check ($null -ne $answer) 'the reply arrived over SMTP'
    if ($answer) {
        $text = RawText $answer
        Check ($text -match 'In-Reply-To: <ui-e2e@example.com>') 'the reply refers to the message it answers'
        Check ($text -match 'Answered by the UI test') 'the reply has what was typed'
    }
    $sent = WaitFor { $m = @(Messages 'Sent'); if ($m.Count -ge 1) { $m } } 20
    Check ($null -ne $sent) 'a copy of the reply is in Sent'
    Shot $main '5-after-sending'

    # ---- help ----

    Step 'help'
    [void][Native.Win]::PostMessage($main, $WM_COMMAND, [IntPtr]$IDM_HELP, [IntPtr]::Zero)
    $help = WaitFor { $h = [Native.Win]::FindWindow('PostalExpressHelp', [NullString]::Value); if ($h -ne [IntPtr]::Zero) { $h } }
    Check ($null -ne $help) 'F1 opens the help'
    if ($help) {
        Start-Sleep -Seconds 3
        Shot $help '6-help'
        [void][Native.Win]::PostMessage($help, $WM_CLOSE, [IntPtr]::Zero, [IntPtr]::Zero)
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
