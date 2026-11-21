# The deep test's driver of the Windows app (docs/deep-test-plan.md, core/crates/pe-deep/src/driver.rs): starts the
# exe with the conductor's options and --test-hooks, reads one request a line from standard input, does it as the UI
# test does (a menu command, a row of the tree or the list chosen, the Find box typed into), and answers with a line
# that starts with "DEEP " and a JSON object. What the window shows comes from the exe's own look at itself
# (Mailbox::TestDeep, kTestDeep), which answers only with --test-hooks.
#   powershell -File scripts/deep-driver.ps1 <InboxClassic.exe> [the conductor's options...]
param([Parameter(Mandatory = $true)][string]$Exe, [Parameter(ValueFromRemainingArguments = $true)][string[]]$Rest)
$ErrorActionPreference = 'Stop'

Add-Type -Namespace Deep -Name Win -MemberDefinition @'
[StructLayout(LayoutKind.Sequential)]
public struct COPYDATASTRUCT { public IntPtr dwData; public int cbData; public IntPtr lpData; }
[DllImport("user32.dll", EntryPoint = "SendMessageW")]
public static extern IntPtr SendCopyData(IntPtr hwnd, uint msg, IntPtr wParam, ref COPYDATASTRUCT lParam);
[DllImport("user32.dll", EntryPoint = "SendMessageW")]
public static extern IntPtr SendMessage(IntPtr hwnd, uint msg, IntPtr wParam, IntPtr lParam);
[DllImport("user32.dll", EntryPoint = "SendMessageW", CharSet = CharSet.Unicode)]
public static extern IntPtr SendString(IntPtr hwnd, uint msg, IntPtr wParam, string lParam);
[DllImport("user32.dll", EntryPoint = "PostMessageW")]
public static extern bool PostMessage(IntPtr hwnd, uint msg, IntPtr wParam, IntPtr lParam);
[DllImport("user32.dll", CharSet = CharSet.Unicode)]
public static extern IntPtr FindWindow(string cls, string title);
[DllImport("user32.dll")]
public static extern IntPtr GetDlgItem(IntPtr dialog, int id);
[DllImport("user32.dll", CharSet = CharSet.Unicode)]
public static extern IntPtr FindWindowEx(IntPtr parent, IntPtr after, string cls, string title);
[DllImport("user32.dll")]
public static extern IntPtr GetWindow(IntPtr hwnd, uint cmd);
[DllImport("user32.dll")]
public static extern bool IsWindowVisible(IntPtr hwnd);
public delegate bool EnumProc(IntPtr hwnd, IntPtr param);
[DllImport("user32.dll")]
public static extern bool EnumWindows(EnumProc proc, IntPtr param);
[DllImport("user32.dll", CharSet = CharSet.Unicode)]
public static extern int GetClassName(IntPtr hwnd, System.Text.StringBuilder name, int size);
// a request of the exe's kTestDeep hook: what it returns
public static long Ask(IntPtr hwnd, string text) {
    byte[] bytes = System.Text.Encoding.Unicode.GetBytes(text);
    IntPtr memory = Marshal.AllocHGlobal(Math.Max(bytes.Length, 1));
    Marshal.Copy(bytes, 0, memory, bytes.Length);
    COPYDATASTRUCT data = new COPYDATASTRUCT { dwData = (IntPtr)0x44454550, cbData = bytes.Length, lpData = memory };
    long result = SendCopyData(hwnd, 0x004A, IntPtr.Zero, ref data).ToInt64();
    Marshal.FreeHGlobal(memory);
    return result;
}
// a message box the main window owns, shown: Zero when there is none
public static IntPtr OwnedDialog(IntPtr owner) {
    IntPtr found = IntPtr.Zero;
    EnumWindows((hwnd, p) => {
        var name = new System.Text.StringBuilder(64);
        GetClassName(hwnd, name, 64);
        if (name.ToString() == "#32770" && GetWindow(hwnd, 4) == owner && IsWindowVisible(hwnd)) { found = hwnd; return false; }
        return true;
    }, IntPtr.Zero);
    return found;
}
'@

$WM_COMMAND = 0x0111; $WM_SETTEXT = 0x000C; $LVM_GETITEMCOUNT = 0x1004; $LVM_GETTOPINDEX = 0x1027; $LVM_GETCOUNTPERPAGE = 0x1028
$IDC_LIST = 201
$IDM = @{ sync = 102; read = 103; unread = 104; delete = 112; flag = 114; markallread = 126; selectall = 134; undo = 135
    emptyfolder = 139; hideread = 154; date = 159; from = 160; subject = 161; size = 162; ascending = 163; descending = 164 }

$arguments = @($Rest) + '--test-hooks' + '--adds-accounts'
[Console]::Error.WriteLine("deep-driver: $Exe $($arguments -join ' ')")
$process = Start-Process -FilePath $Exe -ArgumentList $arguments -PassThru
$main = [IntPtr]::Zero
foreach ($i in 1..300) {
    $main = [Deep.Win]::FindWindow('InboxClassicMain', [NullString]::Value)
    if ($main -ne [IntPtr]::Zero) { break }
    Start-Sleep -Milliseconds 100
}
[Console]::Error.WriteLine("deep-driver: the main window $main answers ping with $([Deep.Win]::Ask($main, 'ping'))")
$list = [Deep.Win]::GetDlgItem($main, $IDC_LIST)
$findBox = [Deep.Win]::GetDlgItem([Deep.Win]::GetDlgItem($main, 205), 204)
$search = ''
$accounts = @()

# the compose windows open
function ComposeWindows {
    $found = @()
    $w = [IntPtr]::Zero
    while (($w = [Deep.Win]::FindWindowEx([IntPtr]::Zero, $w, 'InboxClassicCompose', [NullString]::Value)) -ne [IntPtr]::Zero) { $found += $w }
    $found
}
function Reply([string]$json) { [Console]::Out.WriteLine("DEEP $json"); [Console]::Out.Flush() }
function Ask([string]$text) { [Deep.Win]::Ask($main, $text) }
function Command([int]$id) { [void][Deep.Win]::PostMessage($main, $WM_COMMAND, [IntPtr]$id, [IntPtr]::Zero) }
# a note the command showed (nothing to undo) closed, as a user who goes on does
function DismissNote {
    Start-Sleep -Milliseconds 300
    $box = [Deep.Win]::OwnedDialog($main)
    if ($box -ne [IntPtr]::Zero) {
        [void][Deep.Win]::PostMessage($box, $WM_COMMAND, [IntPtr]2, [IntPtr]::Zero)
        Start-Sleep -Milliseconds 200
        if ([Deep.Win]::OwnedDialog($main) -ne [IntPtr]::Zero) { [void][Deep.Win]::PostMessage($box, $WM_COMMAND, [IntPtr]1, [IntPtr]::Zero) }
    }
}
function Rows { [int][Deep.Win]::SendMessage($list, $LVM_GETITEMCOUNT, [IntPtr]::Zero, [IntPtr]::Zero) }
# a question the command asked, answered yes (IDYES, else IDOK)
function AnswerYes {
    foreach ($i in 1..30) {
        $box = [Deep.Win]::OwnedDialog($main)
        if ($box -ne [IntPtr]::Zero) {
            [void][Deep.Win]::PostMessage($box, $WM_COMMAND, [IntPtr]6, [IntPtr]::Zero)
            Start-Sleep -Milliseconds 300
            if ([Deep.Win]::OwnedDialog($main) -ne [IntPtr]::Zero) { [void][Deep.Win]::PostMessage($box, $WM_COMMAND, [IntPtr]1, [IntPtr]::Zero) }
            return
        }
        Start-Sleep -Milliseconds 100
    }
}
# nothing under way: the core quiet and the list read, then Send/Recv as a barrier, then quiet again
function Settle([int]$seconds) {
    foreach ($round in 1..2) {
        $until = (Get-Date).AddSeconds($seconds)
        while ((Ask 'quiet') -ne 11) {
            if ((Get-Date) -gt $until) { throw "still busy after $seconds s" }
            Start-Sleep -Milliseconds 100
        }
        if ($round -eq 1) { [void](Ask 'barrier') }
    }
}
function Observe {
    $file = [System.IO.Path]::GetTempFileName()
    if ((Ask "observe`t$file") -ne 11) { throw 'the window could not say what it shows' }
    $json = [System.IO.File]::ReadAllText($file, [System.Text.Encoding]::UTF8)
    Remove-Item $file
    $json.Substring(0, $json.Length - 1) + ',"search":' + (ConvertTo-Json $search -Compress) + '}'
}
function ListWords($list) {
    if ($list -is [string]) { return "open`t$list" }
    "open`tfolder`t$($list.account)`t$($list.path)"
}

function Act($request) {
    $rows = Rows
    $last = [Math]::Max($rows - 1, 0)
    switch ($request.act) {
        'open' { if ((Ask (ListWords $request.list)) -ne 11) { throw "not in the folder list" } }
        'scroll' { [void](Ask "scroll`t$([Math]::Min([int]$request.row, $last))") }
        'home' { [void](Ask "scroll`t0") }
        'end' { [void](Ask "scroll`t$last") }
        'pagedown' {
            $top = [int][Deep.Win]::SendMessage($list, $LVM_GETTOPINDEX, [IntPtr]::Zero, [IntPtr]::Zero)
            $page = [int][Deep.Win]::SendMessage($list, $LVM_GETCOUNTPERPAGE, [IntPtr]::Zero, [IntPtr]::Zero)
            [void](Ask "scroll`t$([Math]::Min($top + $page * [int]$request.times, $last))")
        }
        'click' {
            if ([int]$request.row -ge $rows) { throw "no row $($request.row) in a list of $rows" }
            [void](Ask "select`t$($request.row)`t$($request.row)")
        }
        'shiftclick' {
            $from = [int][Deep.Win]::SendMessage($list, 0x100C, [IntPtr](-1), [IntPtr]2)
            [void](Ask "select`t$([Math]::Max($from, 0))`t$([Math]::Min([int]$request.row, $last))")
        }
        'selectall' { Command $IDM.selectall; DismissNote }
        'delete' { Command $IDM.delete; AnswerYes }
        'move' { if ((Ask "move`t$($request.list.account)`t$($request.list.path)") -ne 11) { throw 'the messages could not be moved there' } }
        'flag' { Command $IDM.flag }
        'read' { Command $IDM.read }
        'unread' { Command $IDM.unread }
        'sort' { Command $IDM[$request.by]; Command ($(if ($request.ascending) { $IDM.ascending } else { $IDM.descending })) }
        'search' { $script:search = [string]$request.text; [void][Deep.Win]::SendString($findBox, $WM_SETTEXT, [IntPtr]::Zero, $script:search) }
        'group' { [void](Ask "group`t$(if ($request.on) { 1 } else { 0 })") }
        'unreadonly' {
            $seen = Observe | ConvertFrom-Json
            if ([bool]$seen.unreadOnly -ne [bool]$request.on) { Command $IDM.hideread }
        }
        'undo' { Command $IDM.undo; DismissNote }
        'sync' { Command $IDM.sync }
        'markallread' { Command $IDM.markallread; AnswerYes }
        'emptyfolder' { Command $IDM.emptyfolder; AnswerYes }
        'send' {
            $before = @(ComposeWindows)
            Command 107
            $c = $null
            foreach ($i in 1..100) {
                $c = @(ComposeWindows | Where-Object { $before -notcontains $_ }) | Select-Object -First 1
                if ($c -and [Deep.Win]::GetDlgItem($c, 306) -ne [IntPtr]::Zero) { break }
                Start-Sleep -Milliseconds 100
            }
            if (-not $c) { throw 'New Mail opened no window' }
            Start-Sleep -Milliseconds 500
            [void][Deep.Win]::SendString([Deep.Win]::GetDlgItem($c, 302), $WM_SETTEXT, [IntPtr]::Zero, [string]$request.to)
            [void][Deep.Win]::SendString([Deep.Win]::GetDlgItem($c, 305), $WM_SETTEXT, [IntPtr]::Zero, [string]$request.subject)
            [void][Deep.Win]::PostMessage($c, $WM_COMMAND, [IntPtr]300, [IntPtr]::Zero)
        }
        'restart' { throw 'unsupported' }
        default { throw "not an act: $($request.act)" }
    }
    Start-Sleep -Milliseconds 50
}

while ($null -ne ($line = [Console]::In.ReadLine())) {
    try {
        $request = $line | ConvertFrom-Json
        if ($request.quit) { Reply '{"ok":true}'; break }
        if ($request.start) {
            [void](Ask "group`t0")
            foreach ($a in $request.start.accounts) {
                $id = Ask "account`t$($a.name)`t$($a.email)`t$($a.username)`t$($a.password)`t$($a.imap)`t$($a.smtp)"
                if ($id -le 10) { throw "the account $($a.name) could not be added (the window answered $id)" }
            }
            Settle 1800
            Reply '{"ok":true}'
        } elseif ($null -ne $request.settle) {
            Settle ([int]$request.settle)
            Reply '{"ok":true}'
        } elseif ($request.observe) {
            Reply ('{"ok":true,"seen":' + (Observe) + '}')
        } elseif ($request.health) {
            $p = Get-Process -Id $process.Id
            Reply ('{"ok":true,"memory_kib":' + [int64]($p.WorkingSet64 / 1024) + ',"open_files":' + $p.HandleCount + '}')
        } elseif ($request.screenshot) {
            Reply '{"ok":true}'
        } else {
            Act $request
            Reply '{"ok":true}'
        }
    } catch {
        Reply ('{"ok":false,"error":' + (ConvertTo-Json ([string]$_.Exception.Message) -Compress) + '}')
    }
}
if (-not $process.HasExited) { Stop-Process -Id $process.Id -Force }
