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
[DllImport("user32.dll")] public static extern bool IsIconic(IntPtr hwnd);
[DllImport("user32.dll")] public static extern bool PostMessage(IntPtr hwnd, uint message, IntPtr wParam, IntPtr lParam);
[DllImport("user32.dll")] public static extern IntPtr SendMessage(IntPtr hwnd, uint message, IntPtr wParam, IntPtr lParam);
[DllImport("user32.dll", CharSet = CharSet.Unicode)] public static extern IntPtr SendMessage(IntPtr hwnd, uint message, IntPtr wParam, string lParam);
[DllImport("user32.dll", CharSet = CharSet.Unicode)] public static extern IntPtr SendMessage(IntPtr hwnd, uint message, IntPtr wParam, System.Text.StringBuilder lParam);
[DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr hwnd, out RECT rect);
[DllImport("user32.dll")] public static extern bool SetWindowPos(IntPtr hwnd, IntPtr after, int x, int y, int cx, int cy, uint flags);
[DllImport("user32.dll")] public static extern bool IsWindowVisible(IntPtr hwnd);
[DllImport("user32.dll")] public static extern IntPtr GetDesktopWindow();
[DllImport("user32.dll")] public static extern bool IsWindowEnabled(IntPtr hwnd);
[DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr hwnd);
[DllImport("user32.dll")] public static extern bool IsWindow(IntPtr hwnd);
[DllImport("user32.dll")] public static extern IntPtr GetWindow(IntPtr hwnd, uint cmd);
[DllImport("user32.dll")] public static extern uint GetWindowThreadProcessId(IntPtr hwnd, out uint pid);
[DllImport("kernel32.dll")] public static extern IntPtr OpenProcess(uint access, bool inherit, uint pid);
[DllImport("kernel32.dll")] public static extern IntPtr VirtualAllocEx(IntPtr process, IntPtr address, IntPtr size, uint type, uint protect);
[DllImport("kernel32.dll")] public static extern bool VirtualFreeEx(IntPtr process, IntPtr address, IntPtr size, uint type);
[DllImport("kernel32.dll")] public static extern bool ReadProcessMemory(IntPtr process, IntPtr address, byte[] buffer, IntPtr size, out IntPtr read);
[DllImport("kernel32.dll")] public static extern bool CloseHandle(IntPtr handle);
public delegate bool EnumProc(IntPtr hwnd, IntPtr lParam);
[DllImport("user32.dll")] public static extern bool EnumChildWindows(IntPtr parent, EnumProc proc, IntPtr lParam);
[DllImport("user32.dll")] public static extern bool EnumWindows(EnumProc proc, IntPtr lParam);
[DllImport("user32.dll", CharSet = CharSet.Unicode)] public static extern int GetClassName(IntPtr hwnd, System.Text.StringBuilder name, int size);
[DllImport("user32.dll", CharSet = CharSet.Unicode)] public static extern int InternalGetWindowText(IntPtr hwnd, System.Text.StringBuilder text, int size);
[DllImport("user32.dll")] public static extern int GetMenuItemCount(IntPtr menu);
[DllImport("user32.dll")] public static extern IntPtr GetSubMenu(IntPtr menu, int position);
[DllImport("user32.dll")] public static extern bool GetMenuItemRect(IntPtr hwnd, IntPtr menu, uint item, out RECT rect);
[DllImport("user32.dll")] public static extern uint GetMenuState(IntPtr menu, uint id, uint flags);
[DllImport("user32.dll", CharSet = CharSet.Unicode)] public static extern int GetMenuString(IntPtr menu, uint item, System.Text.StringBuilder text, int size, uint flags);
// the labels of a menu's items, by position (separators empty)
public static string[] MenuLabels(IntPtr menu) {
    int count = GetMenuItemCount(menu);
    var labels = new string[count < 0 ? 0 : count];
    for (int i = 0; i < labels.Length; i++) {
        var text = new System.Text.StringBuilder(128);
        GetMenuString(menu, (uint)i, text, 128, 0x400);
        labels[i] = text.ToString().Replace("&", "");
    }
    return labels;
}
public struct RECT { public int Left, Top, Right, Bottom; }
[StructLayout(LayoutKind.Sequential)] public struct GUITHREADINFO { public int cbSize, flags; public IntPtr active, focus, capture, menuOwner, moveSize, caret; public RECT caretRect; }
[DllImport("user32.dll")] public static extern bool GetGUIThreadInfo(uint thread, ref GUITHREADINFO info);
// the window with the keyboard focus in the thread of `window`
public static IntPtr FocusOf(IntPtr window) {
    uint pid;
    var info = new GUITHREADINFO { cbSize = Marshal.SizeOf(typeof(GUITHREADINFO)) };
    return GetGUIThreadInfo(GetWindowThreadProcessId(window, out pid), ref info) ? info.focus : IntPtr.Zero;
}
[StructLayout(LayoutKind.Sequential)] struct MouseInput { public int dx, dy; public uint data, flags, time; public IntPtr extra; }
[StructLayout(LayoutKind.Explicit)] struct Input { [FieldOffset(0)] public uint type; [FieldOffset(8)] public MouseInput mouse; }
[DllImport("user32.dll")] static extern uint SendInput(uint count, Input[] inputs, int size);
[DllImport("user32.dll")] static extern int GetSystemMetrics(int index);
// the mouse as a user's: moved to (x, y), screen pixels, with the left button pressed (0x0002), let go (0x0004) or
// neither (0)
public static void Mouse(int x, int y, uint button) {
    var input = new Input { type = 0 };
    input.mouse.dx = x * 65535 / (GetSystemMetrics(0) - 1);
    input.mouse.dy = y * 65535 / (GetSystemMetrics(1) - 1);
    input.mouse.flags = button | 0x0001 | 0x8000;
    SendInput(1, new[] { input }, Marshal.SizeOf(typeof(Input)));
    System.Threading.Thread.Sleep(50);
}
// a click of the left mouse button at (x, y)
public static void MouseClick(int x, int y) {
    foreach (uint button in new uint[] { 0, 0x0002, 0x0004 }) { Mouse(x, y, button); }
}
// from (x, y) with the button pressed, a few steps at a time, to (toX, toY), where it stays pressed
public static void MouseDragTo(int x, int y, int toX, int toY) {
    Mouse(x, y, 0);
    Mouse(x, y, 0x0002);
    for (int i = 1; i <= 20; i++) { Mouse(x + (toX - x) * i / 20, y + (toY - y) * i / 20, 0); }
    System.Threading.Thread.Sleep(300);
}
[DllImport("user32.dll")] public static extern void keybd_event(byte key, byte scan, uint flags, IntPtr extra);
[DllImport("user32.dll")] public static extern bool ClientToScreen(IntPtr hwnd, ref POINT point);
public struct POINT { public int X, Y; }
[DllImport("kernel32.dll")] public static extern bool WriteProcessMemory(IntPtr process, IntPtr address, byte[] buffer, IntPtr size, out IntPtr written);
// a rectangle a control of another process fills in (LVM_GETITEMRECT, TVM_GETITEMRECT) from `seed` at its start, in
// screen pixels
public static RECT RemoteRect(IntPtr window, uint message, IntPtr wParam, long seed) {
    uint pid;
    GetWindowThreadProcessId(window, out pid);
    var rect = new RECT();
    IntPtr process = OpenProcess(0x0038, false, pid);
    if (process == IntPtr.Zero) { return rect; }
    IntPtr remote = VirtualAllocEx(process, IntPtr.Zero, (IntPtr)16, 0x3000, 0x04);
    if (remote != IntPtr.Zero) {
        IntPtr done;
        byte[] start = new byte[16];
        BitConverter.GetBytes(seed).CopyTo(start, 0);
        WriteProcessMemory(process, remote, start, (IntPtr)16, out done);
        if (SendMessage(window, message, wParam, remote) != IntPtr.Zero) {
            byte[] bytes = new byte[16];
            ReadProcessMemory(process, remote, bytes, (IntPtr)16, out done);
            var corner = new POINT { X = BitConverter.ToInt32(bytes, 0), Y = BitConverter.ToInt32(bytes, 4) };
            var end = new POINT { X = BitConverter.ToInt32(bytes, 8), Y = BitConverter.ToInt32(bytes, 12) };
            ClientToScreen(window, ref corner);
            ClientToScreen(window, ref end);
            rect = new RECT { Left = corner.X, Top = corner.Y, Right = end.X, Bottom = end.Y };
        }
        VirtualFreeEx(process, remote, IntPtr.Zero, 0x8000);
    }
    CloseHandle(process);
    return rect;
}
// the text of tree item `item` of a tree view of another process (TVM_GETITEMW into its memory)
public static string RemoteTreeText(IntPtr tree, IntPtr item) {
    uint pid;
    GetWindowThreadProcessId(tree, out pid);
    string text = "";
    IntPtr process = OpenProcess(0x0038, false, pid);
    if (process == IntPtr.Zero) { return text; }
    IntPtr remote = VirtualAllocEx(process, IntPtr.Zero, (IntPtr)1024, 0x3000, 0x04);
    if (remote != IntPtr.Zero) {
        IntPtr done;
        // TVITEMW on x64: mask, hItem at 8, pszText at 24, cchTextMax at 32; the text after it at 64
        byte[] tvitem = new byte[64];
        BitConverter.GetBytes((uint)0x0011).CopyTo(tvitem, 0);
        BitConverter.GetBytes(item.ToInt64()).CopyTo(tvitem, 8);
        BitConverter.GetBytes(remote.ToInt64() + 64).CopyTo(tvitem, 24);
        BitConverter.GetBytes(256).CopyTo(tvitem, 32);
        WriteProcessMemory(process, remote, tvitem, (IntPtr)64, out done);
        if (SendMessage(tree, 0x113E, IntPtr.Zero, remote) != IntPtr.Zero) {
            byte[] bytes = new byte[512];
            ReadProcessMemory(process, (IntPtr)(remote.ToInt64() + 64), bytes, (IntPtr)512, out done);
            text = System.Text.Encoding.Unicode.GetString(bytes);
            int end = text.IndexOf('\0');
            if (end >= 0) { text = text.Substring(0, end); }
        }
        VirtualFreeEx(process, remote, IntPtr.Zero, 0x8000);
    }
    CloseHandle(process);
    return text;
}
// a string handed to another window with WM_COPYDATA (the app's test hooks, with --test-hooks); what it returns
[StructLayout(LayoutKind.Sequential)] public struct COPYDATASTRUCT { public IntPtr dwData; public int cbData; public IntPtr lpData; }
[DllImport("user32.dll", EntryPoint = "SendMessageW")] static extern IntPtr SendCopyData(IntPtr hwnd, uint message, IntPtr wParam, ref COPYDATASTRUCT data);
public static long SendText(IntPtr hwnd, long kind, string text) {
    byte[] bytes = System.Text.Encoding.Unicode.GetBytes(text);
    IntPtr memory = Marshal.AllocHGlobal(Math.Max(bytes.Length, 1));
    Marshal.Copy(bytes, 0, memory, bytes.Length);
    COPYDATASTRUCT data = new COPYDATASTRUCT { dwData = (IntPtr)kind, cbData = bytes.Length, lpData = memory };
    long result = SendCopyData(hwnd, 0x004A, IntPtr.Zero, ref data).ToInt64();
    Marshal.FreeHGlobal(memory);
    return result;
}
// the text of a cell of a list view of another process (LVM_GETITEMTEXTW into its memory)
public static string RemoteListText(IntPtr list, int row, int column) {
    uint pid;
    GetWindowThreadProcessId(list, out pid);
    string text = "";
    IntPtr process = OpenProcess(0x0038, false, pid);
    if (process == IntPtr.Zero) { return text; }
    IntPtr remote = VirtualAllocEx(process, IntPtr.Zero, (IntPtr)1024, 0x3000, 0x04);
    if (remote != IntPtr.Zero) {
        IntPtr done;
        // LVITEMW on x64: iSubItem at 8, pszText at 24, cchTextMax at 32; the text after it at 128
        byte[] item = new byte[128];
        BitConverter.GetBytes(column).CopyTo(item, 8);
        BitConverter.GetBytes(remote.ToInt64() + 128).CopyTo(item, 24);
        BitConverter.GetBytes(256).CopyTo(item, 32);
        WriteProcessMemory(process, remote, item, (IntPtr)128, out done);
        int length = (int)SendMessage(list, 0x1073, (IntPtr)row, remote);
        if (length > 0) {
            byte[] bytes = new byte[length * 2];
            ReadProcessMemory(process, (IntPtr)(remote.ToInt64() + 128), bytes, (IntPtr)bytes.Length, out done);
            text = System.Text.Encoding.Unicode.GetString(bytes);
        }
        VirtualFreeEx(process, remote, IntPtr.Zero, 0x8000);
    }
    CloseHandle(process);
    return text;
}
// a text a window of another process writes into memory it is given with a message Windows does not copy between
// processes (TB_GETBUTTONTEXTW), its length the result of `message`
public static string RemoteText(IntPtr window, uint message, IntPtr wParam) {
    uint pid;
    GetWindowThreadProcessId(window, out pid);
    string text = "";
    IntPtr process = OpenProcess(0x0038, false, pid);
    if (process == IntPtr.Zero) { return text; }
    IntPtr remote = VirtualAllocEx(process, IntPtr.Zero, (IntPtr)4096, 0x3000, 0x04);
    if (remote != IntPtr.Zero) {
        int length = (int)SendMessage(window, message, wParam, remote);
        if (length > 0 && length < 2048) {
            IntPtr done;
            byte[] bytes = new byte[length * 2];
            ReadProcessMemory(process, remote, bytes, (IntPtr)bytes.Length, out done);
            text = System.Text.Encoding.Unicode.GetString(bytes);
        }
        VirtualFreeEx(process, remote, IntPtr.Zero, 0x8000);
    }
    CloseHandle(process);
    return text;
}
[DllImport("user32.dll")] public static extern IntPtr GetMenu(IntPtr hwnd);
[DllImport("user32.dll")] public static extern int GetWindowLong(IntPtr hwnd, int index);
[DllImport("user32.dll")] public static extern bool GetClientRect(IntPtr hwnd, out RECT rect);
[DllImport("user32.dll")] static extern IntPtr GetDC(IntPtr hwnd);
[DllImport("user32.dll")] static extern int ReleaseDC(IntPtr hwnd, IntPtr dc);
[DllImport("gdi32.dll")] static extern IntPtr SelectObject(IntPtr dc, IntPtr obj);
[DllImport("gdi32.dll")] static extern IntPtr GetStockObject(int index);
[DllImport("user32.dll", CharSet = CharSet.Unicode)] static extern int DrawText(IntPtr dc, string text, int count, ref RECT rect, uint format);
// whether the words of a control fit it in the dialog font the app gives its controls (DEFAULT_GUI_FONT): a static's
// wrapped to its width within its height, a button's on one line with room for its frame, and for its box when `box`
public static bool Fits(IntPtr hwnd, string text, bool button, bool box) {
    RECT client;
    GetClientRect(hwnd, out client);
    IntPtr dc = GetDC(hwnd);
    IntPtr old = SelectObject(dc, GetStockObject(17));
    int width = client.Right - client.Left - (button ? (box ? 18 : 8) : 0);
    RECT need = new RECT { Left = 0, Top = 0, Right = width, Bottom = 0 };
    // DT_CALCRECT, and DT_SINGLELINE or DT_WORDBREAK
    DrawText(dc, text, -1, ref need, 0x400u | (button ? 0x20u : 0x10u));
    SelectObject(dc, old);
    ReleaseDC(hwnd, dc);
    return need.Right <= width && (button || need.Bottom <= client.Bottom - client.Top);
}
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
$WM_KEYUP = 0x0101; $CB_SETCURSEL = 0x014E; $CB_GETCOUNT = 0x0146; $CB_GETLBTEXT = 0x0148; $EM_SETSEL = 0x00B1; $EM_REPLACESEL = 0x00C2
$TVM_GETCOUNT = 0x1105; $TVM_GETNEXTITEM = 0x110A; $TVM_SELECTITEM = 0x110B; $LVM_GETITEMCOUNT = 0x1004
$VK_RETURN = 0x0D; $VK_ESCAPE = 0x1B; $VK_SPACE = 0x20; $VK_HOME = 0x24; $VK_DOWN = 0x28; $VK_DELETE = 0x2E
# app/src/app.h
$IDM_NEW_ACCOUNT = 100; $IDM_EXIT = 101; $IDM_SYNC = 102; $IDM_MARK_READ = 103; $IDM_MARK_UNREAD = 104; $IDM_PICTURES = 105
$IDM_VIEW_SOURCE = 132; $IDM_AI_AGENTS = 133
$IDM_ABOUT = 106; $IDM_NEW_MAIL = 107; $IDM_REPLY = 108; $IDM_REPLY_ALL = 109; $IDM_FORWARD = 110; $IDM_HELP = 111
$IDM_DELETE = 112; $IDM_MOVE = 113; $IDM_FLAG = 114; $IDM_NEW_FOLDER = 115; $IDM_RENAME_FOLDER = 116; $IDM_DELETE_FOLDER = 117; $IDM_ACCOUNTS = 118; $IDM_SAVE_AS = 121; $IDM_PRINT = 122; $IDM_IMPORT = 123; $IDM_OUTBOX = 124; $IDM_PROPERTIES = 125; $IDC_SAVE = 309;
$LB_GETTEXT = 0x0189; $LB_GETCOUNT = 0x018B; $LB_SETCURSEL = 0x0186; $CB_SELECTSTRING = 0x014D
$IDC_TREE = 200; $IDC_LIST = 201; $IDC_ATTACHMENTS = 202; $IDC_PICTURES = 203
$IDC_SEND = 300; $IDC_ATTACH = 301; $IDC_FILES = 307; $IDC_FROM = 310; $IDC_SHOW_CC = 311; $IDC_SHOW_BCC = 312; $IDC_BCC = 304; $IDC_TO = 302; $IDC_CC = 303; $IDC_SUBJECT = 305; $IDC_BODY = 306; $IDF_BOLD = 330; $IDF_UNDERLINE = 332; $IDF_LINK = 341

New-Item -ItemType Directory -Force -Path $Out | Out-Null
# the app's preferences, where Options keeps the language: the one of whoever runs the test is put back at the end
$preferencesKey = 'HKCU:\Software\Postal Systems\InboxClassic'
$savedLanguage = (Get-ItemProperty -Path $preferencesKey -Name Language -ErrorAction SilentlyContinue).Language
# and Group messages by conversation, left out for the run so it is on, as it is out of the box
$savedGrouping = (Get-ItemProperty -Path $preferencesKey -Name GroupByConversation -ErrorAction SilentlyContinue).GroupByConversation
# and the folder tree's closed rows, left out so every row starts open
$savedClosedRows = (Get-ItemProperty -Path $preferencesKey -Name ClosedFolderRows -ErrorAction SilentlyContinue).ClosedFolderRows
# and the sign-in codes in notifications, left out so they are off, as out of the box
$savedCodes = (Get-ItemProperty -Path $preferencesKey -Name CodesInNotifications -ErrorAction SilentlyContinue).CodesInNotifications
# a scheduled task shows no output: everything also goes to log.txt, and result.txt is written last
Remove-Item -Force -ErrorAction SilentlyContinue (Join-Path $Out 'result.txt')
Start-Transcript -Path (Join-Path $Out 'log.txt') -Force | Out-Null
$failures = @()
# the apps started again (StartAgain), ended at the end should one hang
$started = @()
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

# the screen at ($left, $top) into $bitmap; the desktop of a remote session may refuse a copy for a moment (its
# display redrawn, the client resized)
function CopyScreen($bitmap, [int]$left, [int]$top) {
    for ($try = 1; ; $try++) {
        try {
            [System.Drawing.Graphics]::FromImage($bitmap).CopyFromScreen($left, $top, 0, 0, $bitmap.Size)
            return
        } catch {
            if ($try -ge 10) { throw }
            Start-Sleep -Seconds 2
        }
    }
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
    CopyScreen $bitmap $rect.Left $rect.Top
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
# the rows of a list view, and the rows and the text of a row of a list box (LB_GETTEXT, which Windows copies between
# processes)
function ListCount([IntPtr]$list) { [int][Native.Win]::SendMessage($list, $LVM_GETITEMCOUNT, [IntPtr]::Zero, [IntPtr]::Zero) }
function ListBoxCount([IntPtr]$box) { [int][Native.Win]::SendMessage($box, $LB_GETCOUNT, [IntPtr]::Zero, [IntPtr]::Zero) }
function ListBoxText([IntPtr]$box, [int]$row) {
    $text = New-Object System.Text.StringBuilder 1024
    [void][Native.Win]::SendMessage($box, $LB_GETTEXT, [IntPtr]$row, $text)
    $text.ToString()
}
# the words of a window's static texts (a message box, a form's intro)
function Statics([IntPtr]$window) { ([Native.Win]::FindDescendants($window, 'Static') | ForEach-Object { WindowText $_ }) -join ' ' }
# the text of a part of a status bar: SB_GETTEXT writes it to memory of the app's own process, read back from there
function StatusPart([IntPtr]$bar, [int]$index) {
    $appPid = [uint32]0
    [void][Native.Win]::GetWindowThreadProcessId($bar, [ref]$appPid)
    # PROCESS_VM_OPERATION | PROCESS_VM_READ | PROCESS_VM_WRITE
    $process = [Native.Win]::OpenProcess(0x0038, $false, $appPid)
    if ($process -eq [IntPtr]::Zero) { return '' }
    $size = 4096
    # MEM_COMMIT | MEM_RESERVE, PAGE_READWRITE
    $remote = [Native.Win]::VirtualAllocEx($process, [IntPtr]::Zero, [IntPtr]$size, 0x3000, 0x04)
    $text = ''
    if ($remote -ne [IntPtr]::Zero) {
        # SB_GETTEXTLENGTHW first, so the text fits
        $length = [int]([Native.Win]::SendMessage($bar, 0x040C, [IntPtr]$index, [IntPtr]::Zero).ToInt64() -band 0xFFFF)
        if ($length -gt 0 -and ($length + 1) * 2 -le $size) {
            [void][Native.Win]::SendMessage($bar, 0x040D, [IntPtr]$index, $remote)
            $bytes = New-Object byte[] ($length * 2)
            $read = [IntPtr]::Zero
            if ([Native.Win]::ReadProcessMemory($process, $remote, $bytes, [IntPtr]$bytes.Length, [ref]$read)) {
                $text = [System.Text.Encoding]::Unicode.GetString($bytes)
            }
        }
        # MEM_RELEASE
        [void][Native.Win]::VirtualFreeEx($process, $remote, [IntPtr]::Zero, 0x8000)
    }
    [void][Native.Win]::CloseHandle($process)
    return $text
}
# whether window $a is in front of window $b
function InFront([IntPtr]$a, [IntPtr]$b) {
    for ($w = [Native.Win]::GetWindow($a, 2); $w -ne [IntPtr]::Zero; $w = [Native.Win]::GetWindow($w, 2)) {
        if ($w -eq $b) { return $true }
    }
    return $false
}
# presses a button as its click ends up: BN_CLICKED to its window, which works whether or not that window is active
# (BM_CLICK can be lost when it is not, as on the CI runner). A disabled button can not be pressed, as with the mouse:
# a check fails instead
function Click([IntPtr]$window, [int]$id) {
    $button = [Native.Win]::GetDlgItem($window, $id)
    if ($button -ne [IntPtr]::Zero -and -not [Native.Win]::IsWindowEnabled($button)) {
        Check $false "button $id is enabled to be pressed"
        return
    }
    [void][Native.Win]::PostMessage($window, $WM_COMMAND, [IntPtr]($id -band 0xFFFF), $button)
}
# what is open when a window does not come: the app's visible windows, and a picture of $shown
function ShowAppWindows([IntPtr]$shown, [string]$shot) {
    [Native.Win]::EnumWindows({
        param($w, $l)
        $owner = [uint32]0
        [void][Native.Win]::GetWindowThreadProcessId($w, [ref]$owner)
        if ($owner -eq $app.Id -and [Native.Win]::IsWindowVisible($w)) {
            $cls = New-Object System.Text.StringBuilder 64
            [void][Native.Win]::GetClassName($w, $cls, 64)
            $title = New-Object System.Text.StringBuilder 256
            [void][Native.Win]::InternalGetWindowText($w, $title, 256)
            Write-Host "   window of the app: $cls '$title'"
        }
        $true
    }, [IntPtr]::Zero) | Out-Null
    Shot $shown $shot
}
# a menu or toolbar command, posted as the menu would
function Command([IntPtr]$window, [int]$id) {
    [void][Native.Win]::PostMessage($window, $WM_COMMAND, [IntPtr]$id, [IntPtr]::Zero)
}
function Key([IntPtr]$window, [int]$vk) {
    [void][Native.Win]::PostMessage($window, $WM_KEYDOWN, [IntPtr]$vk, [IntPtr]::Zero)
    [void][Native.Win]::PostMessage($window, $WM_KEYUP, [IntPtr]$vk, [IntPtr]::Zero)
}
# an account's Properties form, titled "<account> Properties", or 0
function PropertiesForm() {
    $w = [IntPtr]::Zero
    while (($w = [Native.Win]::FindWindowEx([IntPtr]::Zero, $w, 'InboxClassicForm', [NullString]::Value)) -ne [IntPtr]::Zero) {
        if ((WindowText $w) -match 'Properties$') { return $w }
    }
    return [IntPtr]::Zero
}
# a top-level window of a class (and title), once it is there
function WaitWindow([string]$class, [string]$title = $null, [int]$Seconds = 20) {
    $t = if ($title) { $title } else { [NullString]::Value }
    WaitFor { $w = [Native.Win]::FindWindow($class, $t); if ($w -ne [IntPtr]::Zero) { $w } } $Seconds
}
# a window of the app's own once it shows: its controls are made and filled before it does, so they can be read
function WaitShown([string]$class, [int]$Seconds = 20) {
    WaitFor { $w = [Native.Win]::FindWindow($class, [NullString]::Value); if ($w -ne [IntPtr]::Zero -and [Native.Win]::IsWindowVisible($w)) { $w } } $Seconds
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
    # the first file dialog of a session can take long to open while the shell starts (CI runners)
    $dialog = WaitWindow '#32770' $title 40
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
# the Windows folder picker (Save Messages In) answered with `path`: typed into its Folder box, then Select Folder
function AnswerFolderDialog([string]$title, [string]$path) {
    $dialog = WaitWindow '#32770' $title 40
    if (-not $dialog) {
        Shot ([Native.Win]::GetDesktopWindow()) 'debug-folder-dialog-missing'
        return $false
    }
    # the Folder box: the one edit field it shows (the address bar's is hidden until clicked)
    $name = WaitFor { [Native.Win]::FindDescendants($dialog, 'Edit') | Where-Object { [Native.Win]::IsWindowVisible($_) } | Select-Object -First 1 } 10
    $answered = $false
    if ($name) {
        [void][Native.Win]::SendMessage($name, $EM_SETSEL, [IntPtr]0, [IntPtr](-1))
        foreach ($c in $path.ToCharArray()) { [void][Native.Win]::PostMessage($name, 0x0102, [IntPtr][int]$c, [IntPtr]::Zero) }
        if (WaitFor { (WindowText $name) -eq $path } 10) {
            Click $dialog 1
            # a typed folder is opened first, its name then in the box: Select Folder once more chooses it
            $leaf = Split-Path -Leaf $path
            if (-not (WaitFor { -not [Native.Win]::IsWindow($dialog) } 3) -and (WaitFor { (WindowText $name) -eq $leaf } 5)) {
                Click $dialog 1
            }
            $answered = [bool](WaitFor { -not [Native.Win]::IsWindow($dialog) } 10)
        }
    }
    if (-not $answered -and [Native.Win]::IsWindow($dialog)) {
        $edits = @([Native.Win]::FindDescendants($dialog, 'Edit') | ForEach-Object { "$([Native.Win]::IsWindowVisible($_)):'$(WindowText $_)'" }) -join ', '
        Write-Host "   (the folder dialog: edit fields $edits)"
        Shot $dialog 'debug-folder-dialog'
        # not left open over the steps after this one
        [void][Native.Win]::PostMessage($dialog, $WM_CLOSE, [IntPtr]::Zero, [IntPtr]::Zero)
        [void](WaitFor { -not [Native.Win]::IsWindow($dialog) } 5)
    }
    return $answered
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
# with its OAuth 2.0 / OpenID Connect provider, and a user with an address for name to sign in as there
# and a second server with a mailbox of its own for the second account (ImapKit's users share one mailbox)
$harness.StandardInput.WriteLine('{"oauth":{},"users":{"testuser":{"password":"testpass"},"alice@example.com":{"password":"pw","displayName":"Alice Example"}},"second":{"users":{"testuser2":{"password":"testpass2"}}}}')
$ports = $harness.StandardOutput.ReadLine() | ConvertFrom-Json
$rest = "http://127.0.0.1:$($ports.rest)/v1/mailboxes"
$rest2 = "http://127.0.0.1:$($ports.second.rest)/v1/mailboxes"
function Messages([string]$mailbox, [string]$server = $rest) {
    # through the pipeline, which unrolls the array: Windows PowerShell hands an empty one on as one object
    @(Invoke-RestMethod "$server/$([uri]::EscapeDataString($mailbox))/messages?raw=true" | ForEach-Object { $_ })
}
# the REST API gives the source base64 encoded
function RawText($message) {
    try { [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($message.raw)) }
    catch { "UNDECODED(" + ([string]$message.raw).Substring(0, [Math]::Min(80, ([string]$message.raw).Length)) + ")" }
}
function Find([string]$mailbox, [string]$pattern) { (Messages $mailbox) | Where-Object { (RawText $_) -match $pattern } | Select-Object -First 1 }
function Seen([string]$pattern) { (Find 'INBOX' $pattern).flags -contains '\Seen' }
function AddMessage([string]$raw, [string[]]$flags = @(), [string]$mailbox = 'INBOX', [string]$server = $rest) {
    $body = @{ raw = $raw; flags = $flags } | ConvertTo-Json
    [void](Invoke-RestMethod -Method Post -ContentType 'application/json' -Body $body "$server/$mailbox/messages")
}

# a picture sent inside the message: the newsletter's banner
$picture = New-Object System.Drawing.Bitmap 560, 110
$graphics = [System.Drawing.Graphics]::FromImage($picture)
$graphics.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::AntiAliasGridFit
$graphics.Clear([System.Drawing.Color]::FromArgb(31, 77, 58))
$graphics.DrawString('Trail Notes', (New-Object System.Drawing.Font 'Georgia', 30, ([System.Drawing.FontStyle]::Bold), ([System.Drawing.GraphicsUnit]::Pixel)), [System.Drawing.Brushes]::White, 24, 22)
$graphics.DrawString('Walks, maps and weekend ideas  |  October', (New-Object System.Drawing.Font 'Georgia', 15, ([System.Drawing.FontStyle]::Regular), ([System.Drawing.GraphicsUnit]::Pixel)), (New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(214, 232, 220))), 26, 66)
$stream = New-Object System.IO.MemoryStream
$picture.Save($stream, [System.Drawing.Imaging.ImageFormat]::Png)
$png = [Convert]::ToBase64String($stream.ToArray(), 'InsertLineBreaks')
$pdf = "%PDF-1.4`n% a small attachment from scripts/ui-e2e.ps1`n"
$pdf64 = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes($pdf))

# in the list newest first: the newsletter, Ann's message, the minutes
$minutes = 'Minutes of the planning meeting'
AddMessage ("From: Bob Harris <bob@example.com>`r`nTo: testuser@inboxclassic.test, Dave <dave@example.com>`r`n" +
    "Cc: Carol <carol@example.com>`r`nSubject: $minutes`r`nMessage-ID: <minutes@example.com>`r`n" +
    "Date: Wed, 1 Oct 2025 09:00:00 +0000`r`n`r`nWe agreed on the dates.`r`n") @('\Seen')
# a reply with the message it answers quoted below, as Gmail sends it: the oldest, the last row
AddMessage ("From: Carol <carol@example.com>`r`nTo: testuser@inboxclassic.test`r`nSubject: Re: Lunch on Friday`r`n" +
    "Message-ID: <lunch2@example.com>`r`nIn-Reply-To: <lunch1@example.com>`r`nDate: Mon, 29 Sep 2025 12:00:00 +0000`r`n" +
    "Content-Type: text/html; charset=utf-8`r`n`r`n" +
    '<div dir="ltr">Friday is fine, see you at noon.</div><br><div class="gmail_quote"><div dir="ltr" class="gmail_attr">' +
    'On Mon, Sep 29, 2025 at 9:00 AM Alex Morgan &lt;testuser@inboxclassic.test&gt; wrote:<br></div>' +
    '<blockquote class="gmail_quote" style="margin:0px 0px 0px 0.8ex;border-left:1px solid rgb(204,204,204);padding-left:1ex">' +
    'Lunch on Friday? The usual place.</blockquote></div>' + "`r`n") @('\Seen')
$subject = 'Photos from Saturday'
AddMessage ("From: Ann Example <ann@example.com>`r`nTo: testuser@inboxclassic.test`r`nSubject: $subject`r`n" +
    "Message-ID: <ui-e2e@example.com>`r`nDate: Mon, 6 Oct 2025 10:00:00 +0000`r`n`r`nHi Alex,`r`n" +
    "the photos from Saturday are in the shared album. The one from the lake came out best.`r`n`r`nAnn`r`n")
$newsletter = 'October newsletter'
$html = '<div style="font-family:Georgia,serif;max-width:560px;color:#222">' +
    '<p><img src="cid:banner@example.com" width="560" height="110" alt="Trail Notes"></p>' +
    '<h2 style="color:#1f4d3a;margin:18px 0 6px">Five autumn walks worth the drive</h2>' +
    '<p>The larches are turning gold and the summer crowds have gone home. This month we picked five routes for short ' +
    'October days, each under four hours, with a warm cafe at the end.</p>' +
    '<p><a href="https://example.com/news">Read the full guide</a> <script>alert("never runs")</script></p>' +
    '<p style="color:#666;font-size:14px">Photo of the month, sent in by a reader:</p>' +
    '<p><img src="https://nodemailer.com/img/nm_logo_200x136.png" width="200" height="136" alt="Photo of the month"></p></div>'
AddMessage ("From: Trail Notes <news@example.com>`r`nTo: testuser@inboxclassic.test`r`nSubject: $newsletter`r`n" +
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
    # ImapKit's certificate is self-signed: the app trusts it, and only it, for this run. A browser sign-in writes its
    # page to a file, where the test opens it as the browser would
    $signInPage = Join-Path $Out 'sign-in-page.txt'
    Remove-Item -Force -ErrorAction SilentlyContinue $signInPage
    $arguments = @('--store', "`"$store`"", '--memory-passwords', '--pin-certificate', "`"$($ports.cert)`"",
        '--sign-in-page-file', "`"$signInPage`"", '--test-hooks')
    Remove-ItemProperty -Path $preferencesKey -Name GroupByConversation -ErrorAction SilentlyContinue
    Remove-ItemProperty -Path $preferencesKey -Name ClosedFolderRows -ErrorAction SilentlyContinue
    Remove-ItemProperty -Path $preferencesKey -Name CodesInNotifications -ErrorAction SilentlyContinue
    $app = Start-Process -FilePath $Exe -ArgumentList $arguments -PassThru

    # the first page of Add Mail Account, with the address fields when $fields, else the page that offers a
    # provider's sign-in for an address found there
    function StartPage([bool]$fields, [int]$seconds = 10) {
        WaitFor {
            $f = [Native.Win]::FindWindow('InboxClassicAccountStart', 'Add Mail Account')
            if ($f -ne [IntPtr]::Zero -and (([Native.Win]::GetDlgItem($f, 101) -ne [IntPtr]::Zero) -eq $fields)) { $f }
        } $seconds
    }

    # both steps of the form: the name and address, then the servers with the password; on the second server. The
    # second step's fields are 100 + their place (Field in accounts.cpp): Account name, Your name, E-mail address,
    # User name, Password, the incoming server, port and security, the outgoing server, port and security
    function AddAccount([string]$name, [string]$user, [string]$password, [bool]$shots, [bool]$onSecond = $false) {
        $on = if ($onSecond) { $ports.second } else { $ports }
        $first = StartPage $true
        Check ($null -ne $first) "the account form opens ($name)"
        if ($shots) {
            $google = [Native.Win]::GetDlgItem($first, 120); $microsoft = [Native.Win]::GetDlgItem($first, 121)
            Check ((WindowText $google) -eq 'Sign in with Google' -and (WindowText $microsoft) -eq 'Sign in with Microsoft') 'it starts with the Google and Microsoft sign-in buttons'
            Check ([Native.Win]::GetDlgItem($first, 102) -eq [IntPtr]::Zero) 'and asks no password before the servers are known'
        }
        SetText $first 100 $name
        SetText $first 101 "$user@inboxclassic.test"
        if ($shots) { Shot $first 'account-1-form' }
        Click $first 1
        if ($shots) {
            $wait = WaitWindow 'InboxClassicWait' $null 5
            if ($wait) { Shot $wait 'account-2-lookup' }
        }
        # the lookup finds nothing for this domain: the second form comes with the usual names to correct
        $second = WaitFor {
            $f = [Native.Win]::FindWindow('InboxClassicForm', 'Add Mail Account')
            if ($f -ne [IntPtr]::Zero -and [Native.Win]::GetDlgItem($f, 110) -ne [IntPtr]::Zero) { $f }
        } 40
        Check ($null -ne $second) 'the server settings form follows the lookup'
        if (-not $second) { Shot $first "account-failed-$user"; throw 'no server settings form' }
        Check ((GetText $second 105) -eq 'imap.inboxclassic.test') 'the lookup guessed the IMAP server'
        Check ((GetText $second 101) -eq $name) 'the server form keeps the name typed first'
        Check ((GetText $second 100) -eq 'inboxclassic.test') "the Account name starts as the address's domain ($(GetText $second 100))"
        # the first account keeps the name offered; the second is named as the test calls it ("Work"), so the folder
        # tree and the Account column say that
        if ($onSecond) { SetText $second 100 $name }
        SetText $second 103 $user
        SetText $second 104 $password
        SetText $second 105 '127.0.0.1'
        SetText $second 106 "$($on.imap)"
        [void][Native.Win]::SendMessage([Native.Win]::GetDlgItem($second, 107), $CB_SETCURSEL, [IntPtr]2, [IntPtr]::Zero)
        SetText $second 108 '127.0.0.1'
        SetText $second 109 "$($on.smtp)"
        # ImapKit's SMTP server takes a password only after STARTTLS
        [void][Native.Win]::SendMessage([Native.Win]::GetDlgItem($second, 110), $CB_SETCURSEL, [IntPtr]1, [IntPtr]::Zero)
        if ($shots) { Shot $second 'account-3-servers' }
        Click $second 1
        $warning = WaitWindow '#32770' 'Add Mail Account'
        Check ($null -ne $warning) 'a connection without encryption is warned about'
        if ($shots -and $warning) { Shot $warning 'account-4-warning' }
        Click $warning 6
    }
    AddAccount 'Alex Morgan' 'testuser' 'testpass' $true

    # ---- reading ----

    Step 'syncing'
    $main = [Native.Win]::FindWindow('InboxClassicMain', [NullString]::Value)
    $tree = [Native.Win]::GetDlgItem($main, $IDC_TREE)
    $list = [Native.Win]::GetDlgItem($main, $IDC_LIST)
    # the message list's columns (Column in mailbox.cpp)
    $COL_FROM = 2; $COL_SUBJECT = 3; $COL_RECEIVED = 4; $COL_FOLDER = 5
    # the columns of a folder's list: attachment, flag, From, Subject, Received; a search adds Folder
    $FOLDER_COLUMNS = 5
    $folders = WaitFor { $n = [int][Native.Win]::SendMessage($tree, $TVM_GETCOUNT, [IntPtr]::Zero, [IntPtr]::Zero); if ($n -ge 7) { $n } }
    Check ($null -ne $folders) "the folders of the account are in the tree ($folders)"
    # the first account's item: the first at the top of the tree, or the one after All Inboxes (above the accounts
    # while there are two), whose first row is named as the account after it (or which has none, before the accounts'
    # Inboxes are known)
    function FirstAccountItem {
        $item = [Native.Win]::SendMessage($tree, $TVM_GETNEXTITEM, [IntPtr]0, [IntPtr]::Zero)
        $next = [Native.Win]::SendMessage($tree, $TVM_GETNEXTITEM, [IntPtr]1, $item)
        $child = [Native.Win]::SendMessage($tree, $TVM_GETNEXTITEM, [IntPtr]4, $item)
        $bare = { param($i) ([Native.Win]::RemoteTreeText($tree, $i)) -replace ' \(\d+\)$', '' }
        if ($next -ne [IntPtr]::Zero -and ($child -eq [IntPtr]::Zero -or (& $bare $child) -eq (& $bare $next))) {
            $item = $next
        }
        $item
    }
    # the folders under the account: Inbox, Sent Items, Drafts, Archive, Junk E-mail, Deleted Items
    function SelectFolder([int]$index) {
        $item = [Native.Win]::SendMessage($tree, $TVM_GETNEXTITEM, [IntPtr]4, (FirstAccountItem))
        for ($i = 0; $i -lt $index; $i++) { $item = [Native.Win]::SendMessage($tree, $TVM_GETNEXTITEM, [IntPtr]1, $item) }
        [void][Native.Win]::SendMessage($tree, $TVM_SELECTITEM, [IntPtr]9, $item)
    }
    function Rows { ListCount $list }
    # the rows of the list with this subject
    function SubjectRows([string]$s) { @(0..([Math]::Max(0, (Rows) - 1)) | Where-Object { [Native.Win]::RemoteListText($list, $_, $COL_SUBJECT) -eq $s }) }
    # a tree's row by its account and folder, their unread counts and "(current)" left out; Zero when it is not there
    function TreeRow([IntPtr]$t, [string]$account, [string]$folder) {
        $name = { param($item) ([Native.Win]::RemoteTreeText($t, $item)) -replace ' \((\d+|current)\)$', '' }
        $item = [Native.Win]::SendMessage($t, $TVM_GETNEXTITEM, [IntPtr]0, [IntPtr]::Zero)
        while ($item -ne [IntPtr]::Zero) {
            if ((& $name $item) -eq $account) {
                $child = [Native.Win]::SendMessage($t, $TVM_GETNEXTITEM, [IntPtr]4, $item)
                while ($child -ne [IntPtr]::Zero) {
                    if ((& $name $child) -eq $folder) { return $child }
                    $child = [Native.Win]::SendMessage($t, $TVM_GETNEXTITEM, [IntPtr]1, $child)
                }
            }
            $item = [Native.Win]::SendMessage($t, $TVM_GETNEXTITEM, [IntPtr]1, $item)
        }
        [IntPtr]::Zero
    }
    # the texts of the rows a tree shows, top to bottom
    function TreeTexts([IntPtr]$t) {
        $texts = @()
        $item = [Native.Win]::SendMessage($t, $TVM_GETNEXTITEM, [IntPtr]0, [IntPtr]::Zero)
        while ($item -ne [IntPtr]::Zero) {
            $texts += [Native.Win]::RemoteTreeText($t, $item)
            $item = [Native.Win]::SendMessage($t, $TVM_GETNEXTITEM, [IntPtr]6, $item)
        }
        $texts
    }
    # the Move and Copy window, once it is open
    function WaitPicker([string]$title) {
        WaitFor {
            $f = [Native.Win]::FindWindow('InboxClassicFolderPicker', $title)
            # once its tree has the folders
            if ($f -ne [IntPtr]::Zero) {
                $t = [Native.Win]::GetDlgItem($f, 102)
                if ($t -ne [IntPtr]::Zero -and [int][Native.Win]::SendMessage($t, $TVM_GETCOUNT, [IntPtr]::Zero, [IntPtr]::Zero) -gt 0) { $f }
            }
        }
    }
    # a folder of the Move and Copy window chosen, as a click on it would
    function PickIn([IntPtr]$picker, [string]$account, [string]$folder) {
        $pickerTree = [Native.Win]::GetDlgItem($picker, 102)
        $row = TreeRow $pickerTree $account $folder
        if ($row -ne [IntPtr]::Zero) { [void][Native.Win]::SendMessage($pickerTree, $TVM_SELECTITEM, [IntPtr]9, $row) }
        $row -ne [IntPtr]::Zero
    }
    # a row of the list, reached with the keys as a user would
    function SelectRow([int]$row) {
        # a click into the first row gives the list the keyboard, as it does for a user
        $point = [IntPtr]((28 -shl 16) -bor 60)
        [void][Native.Win]::PostMessage($list, 0x0201, [IntPtr]1, $point)
        [void][Native.Win]::PostMessage($list, 0x0202, [IntPtr]::Zero, $point)
        Start-Sleep -Milliseconds 300
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
        Check ($headers -match 'Subject: October newsletter' -and $headers -notmatch 'larches are turning') 'the headers, without the body'
        Shot $properties 'read-7-properties'
        Click $properties 1
        Check ([bool](WaitFor { -not [Native.Win]::IsWindow($properties) } 10)) 'OK closes it'
    }

    Step 'the message list menu and the message source'
    # the menu key in the list, as Shift+F10 opens it: the menu at the selected message
    $WM_CONTEXTMENU = 0x007B
    [void][Native.Win]::PostMessage($main, $WM_CONTEXTMENU, $list, [IntPtr](-1))
    $menu = WaitWindow '#32768' $null 10
    Check ($null -ne $menu) 'the message list has a right-click menu'
    if ($menu) {
        $hmenu = [Native.Win]::SendMessage($menu, 0x01E1, [IntPtr]::Zero, [IntPtr]::Zero)
        $labels = [Native.Win]::MenuLabels($hmenu)
        Check (($labels -contains 'Reply to Sender') -and ($labels -contains 'Mark as Unread') -and ($labels -contains 'Move to Folder...') -and
            ($labels -contains 'View Source') -and ($labels -contains 'Properties...')) "with the message's actions ($($labels -join ', '))"
        Check ($labels -notcontains 'Mark as Read') 'a read message offers Mark as Unread, not Mark as Read'
        Shot $main 'read-14-menu' $menu
        $sourceAt = [array]::IndexOf($labels, 'View Source')
        for ($i = 0; $i -le $sourceAt; $i++) { if ($labels[$i]) { Key $menu $VK_DOWN } }
        Key $menu $VK_RETURN
    }
    $source = WaitShown 'InboxClassicSource' 5
    if (-not $source) {
        # where the menu does not take posted keys: the command, as the menu would send it
        $menu = [Native.Win]::FindWindow('#32768', [NullString]::Value)
        if ($menu -ne [IntPtr]::Zero) { Key $menu $VK_ESCAPE }
        Command $main $IDM_VIEW_SOURCE
        $source = WaitShown 'InboxClassicSource' 10
    }
    Check ($null -ne $source) 'View Source opens the whole message'
    if ($source) {
        $box = [Native.Win]::FindDescendants($source, 'Edit') | Select-Object -First 1
        $raw = if ($box) { WindowText $box } else { '' }
        Check ($raw -match 'Subject: October newsletter' -and $raw -match 'Content-Type: multipart' -and $raw -match 'larches are turning') 'with its header and every part, as the server has it'
        $sourceTitle = WindowText $source
        Check ($sourceTitle -eq 'Message Source: October newsletter') "the window names the message ($sourceTitle)"
        Shot $source 'read-15-source'
        $sourceEml = Join-Path (Resolve-Path $Out) 'source-saved.eml'
        Remove-Item -Force -ErrorAction SilentlyContinue $sourceEml
        Click $source $IDM_SAVE_AS
        Check (AnswerFileDialog 'Save Message As' $sourceEml $null '*October newsletter*') 'Save As in it asks where, with the subject as the name'
        Check ([bool](WaitFor { (Test-Path $sourceEml) -and (Get-Content -Raw $sourceEml) -match 'larches are turning' } 10)) 'and saves the message as it came'
        Check ([Native.Win]::IsWindow($source)) 'and the source stays open'
        Click $source 1
        Check ([bool](WaitFor { -not [Native.Win]::IsWindow($source) } 10)) 'Close closes it'
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
    Check (TypeInEditor $compose 'Thanks, Ann. The lake one is my favourite too.') 'the editor takes typing'
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
        Check ($text -match 'my favourite too') 'the reply has what was typed'
        Check ($text -match 'Content-Type: text/html' -and $text -match 'Content-Type: text/plain') 'it is HTML with a text part'
        Check ($text -match '<b>Thanks, Ann') 'what was typed in bold is bold'
        Check ($text -match 'Original Message' -and $text -match 'shared album') 'the folded quote is sent along'
        # once in the HTML part and once in the text part: unfolded into the text, it is not added a second time
        Check ((([regex]::Matches($text, 'shared album')).Count) -eq 2) 'the quote is sent once'
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
    Check ($from -eq 'Alex Morgan <testuser@inboxclassic.test>') "From names the account it goes from ($from)"
    SetText $compose $IDC_TO 'dave at example.com'
    SetText $compose $IDC_SUBJECT 'Trail map for Sunday'
    Check ((WindowText $compose) -eq 'Trail map for Sunday') "a new message's window is named by the subject typed ($(WindowText $compose))"
    Check (TypeInEditor $compose 'Hi Dave, here is the trail map for Sunday. See you at nine!') 'the editor of a new message takes typing'
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
    Set-Content (Join-Path $files 'trail-map.txt') 'the attachment that goes'
    Set-Content (Join-Path $files 'packing-list.txt') 'attached by mistake'
    $attached = [Native.Win]::GetDlgItem($compose, $IDC_FILES)
    $count = { ListBoxCount $attached }
    foreach ($file in 'trail-map.txt', 'packing-list.txt') {
        $before = & $count
        # once more if the dialog did not take the file, after closing what is left of it
        for ($try = 0; $try -lt 2 -and (& $count) -le $before; $try++) {
            $left = [Native.Win]::FindWindow('#32770', 'Insert Attachment')
            if ($left -ne [IntPtr]::Zero) { Click $left 2; [void](WaitFor { -not [Native.Win]::IsWindow($left) } 10) }
            Command $compose $IDC_ATTACH
            if (-not (AnswerFileDialog 'Insert Attachment' (Join-Path $files $file) $null)) { Write-Host "   the file dialog did not take $file (try $($try + 1))" }
            [void](WaitFor { (& $count) -gt $before } 10)
        }
    }
    Check ([bool](WaitFor { (& $count) -eq 2 } 10)) 'Attach adds the files to the Attach row'
    Shot $compose 'write-5-new'
    [void][Native.Win]::SendMessage($attached, $LB_SETCURSEL, [IntPtr]1, [IntPtr]::Zero)
    Key $attached $VK_DELETE
    Check ([bool](WaitFor { (& $count) -eq 1 } 10)) 'Delete in the Attach row takes one off'
    Command $compose $IDC_SEND
    $new = WaitFor { Find 'INBOX' 'Subject: Trail map for Sunday' } 30
    Check ($null -ne $new) 'the new message was sent'
    Check ($new -and (RawText $new) -match 'here is the trail map for Sunday') 'with what was typed'
    Check ($new -and (RawText $new) -match 'trail-map\.txt' -and (RawText $new) -notmatch 'packing-list') 'with only the file left attached'
    Check ($new -and (RawText $new) -match 'Content-Type: text/plain' -and (RawText $new) -notmatch 'Content-Type: text/html') 'nothing formatted: it went as plain text'

    Step 'pictures dropped into the text'
    # a real drag and drop, as from Explorer: a small window of this test starts an OLE drag of the files while the
    # mouse, moved by SendInput, carries them onto the editor and lets go there
    Add-Type -ReferencedAssemblies System.Windows.Forms, System.Drawing -TypeDefinition @'
using System;
using System.Collections.Specialized;
using System.Drawing;
using System.Runtime.InteropServices;
using System.Threading;
using System.Windows.Forms;
public static class Dragger {
    [StructLayout(LayoutKind.Sequential)] struct MouseInput { public int dx, dy; public uint data, flags, time; public IntPtr extra; }
    [StructLayout(LayoutKind.Explicit)] struct Input { [FieldOffset(0)] public uint type; [FieldOffset(8)] public MouseInput mouse; }
    [DllImport("user32.dll")] static extern uint SendInput(uint count, Input[] inputs, int size);
    const uint MOVE = 0x0001, DOWN = 0x0002, UP = 0x0004, ABSOLUTE = 0x8000;
    static void Mouse(int x, int y, uint flags) {
        Rectangle screen = Screen.PrimaryScreen.Bounds;
        var input = new Input { type = 0 };
        input.mouse.dx = x * 65535 / (screen.Width - 1);
        input.mouse.dy = y * 65535 / (screen.Height - 1);
        input.mouse.flags = flags | MOVE | ABSOLUTE;
        SendInput(1, new[] { input }, Marshal.SizeOf(typeof(Input)));
    }
    // drags `files` from (fromX, fromY) to (toX, toY), screen pixels; false when the drag ended without a drop
    public static bool Drag(string[] files, int fromX, int fromY, int toX, int toY) {
        var list = new StringCollection();
        list.AddRange(files);
        var data = new DataObject();
        data.SetFileDropList(list);
        var effect = DragDropEffects.None;
        var form = new Form {
            FormBorderStyle = FormBorderStyle.None, StartPosition = FormStartPosition.Manual, ShowInTaskbar = false,
            TopMost = true, BackColor = Color.Orange, Location = new Point(fromX - 20, fromY - 20), Size = new Size(40, 40)
        };
        form.MouseDown += (s, e) => { effect = form.DoDragDrop(data, DragDropEffects.Copy); form.Close(); };
        form.Shown += (s, e) => new Thread(() => {
            Thread.Sleep(400);
            Mouse(fromX, fromY, 0);
            Thread.Sleep(100);
            Mouse(fromX, fromY, DOWN);
            Thread.Sleep(300);
            for (int i = 1; i <= 25; i++) {
                Mouse(fromX + (toX - fromX) * i / 25, fromY + (toY - fromY) * i / 25, 0);
                Thread.Sleep(40);
            }
            Thread.Sleep(500);
            Mouse(toX, toY, UP);
        }) { IsBackground = true }.Start();
        Application.Run(form);
        return effect != DragDropEffects.None;
    }
}
'@
    Command $main $IDM_NEW_MAIL
    $compose = WaitCompose
    SetText $compose $IDC_TO 'Dave <dave@example.com>'
    SetText $compose $IDC_SUBJECT 'Pictures dropped in the UI test'
    Check (TypeInEditor $compose 'A picture: ') 'the editor takes typing'
    $pictureFile = Join-Path $files 'dropped.png'
    $picture.Save($pictureFile, [System.Drawing.Imaging.ImageFormat]::Png)
    $noteFile = Join-Path $files 'dropped-note.txt'
    Set-Content $noteFile 'not a picture, attached'
    [void][Native.Win]::SetForegroundWindow($compose)
    $editorRect = New-Object Native.Win+RECT
    [void][Native.Win]::GetWindowRect([Native.Win]::GetDlgItem($compose, $IDC_BODY), [ref]$editorRect)
    $toX = [int](($editorRect.Left + $editorRect.Right) / 2); $toY = [int](($editorRect.Top + $editorRect.Bottom) / 2)
    $dropped = [Dragger]::Drag(@($pictureFile, $noteFile), 40, 40, $toX, $toY)
    Check $dropped 'the text takes files dropped on it'
    $attached = [Native.Win]::GetDlgItem($compose, $IDC_FILES)
    Check ([bool](WaitFor { (ListBoxCount $attached) -eq 1 } 10)) 'a file that is no picture is attached'
    Start-Sleep -Seconds 1
    Shot $compose 'write-13-dropped-picture'
    Command $compose $IDC_SEND
    $sentPicture = WaitFor { Find 'INBOX' 'Subject: Pictures dropped in the UI test' } 30
    Check ($null -ne $sentPicture) 'the message with the dropped picture was sent'
    $raw = if ($sentPicture) { RawText $sentPicture } else { '' }
    Check ($raw -match '(?s)multipart/related.*Content-Type: image/png.*Content-ID: <picture1\.' -and $raw -match 'src=(3D)?"cid:picture1\.') 'the picture went inline, as a cid: part, like Insert Picture puts one'
    Check ($raw -notmatch 'data:image') 'with no data: URI left in the HTML'
    Check ($raw -match 'dropped-note\.txt' -and $raw -notmatch 'filename="?dropped\.png') 'the other file went as an attachment, the picture not'

    Step 'links in a message being written'
    # the mouse away from where the last step left it, so no link is under it
    [Native.Win]::Mouse(5, 5, 0)
    Command $main $IDM_NEW_MAIL
    $compose = WaitCompose
    SetText $compose $IDC_TO 'Dave <dave@example.com>'
    SetText $compose $IDC_SUBJECT 'Links in the UI test'
    $input = ClickEditor $compose
    $composeStatus = [Native.Win]::FindWindowEx($compose, [IntPtr]::Zero, 'msctls_statusbar32', [NullString]::Value)
    # a link with nothing selected: the address itself is the link's text
    Command $compose $IDF_LINK
    $dialog = WaitWindow 'InboxClassicForm' 'Hyperlink' 10
    # found as soon as it is made: its field is read once it is filled in
    Check ($dialog -and (WaitFor { (GetText $dialog 100) -eq 'https://' } 5)) 'the Link button asks for an address'
    if ($dialog) {
        SetText $dialog 100 'https://example.com/first'
        Click $dialog 1
        [void](WaitFor { -not [Native.Win]::IsWindow($dialog) } 10)
    }
    # the cursor into the link: the status bar says where it goes
    Start-Sleep -Milliseconds 500
    Key $input 0x25
    Key $input 0x25
    Check ($null -ne (WaitFor { $t = WindowText $composeStatus; if ($t -like 'https://example.com/first*Ctrl+click to open*') { $t } } 10)) 'with the cursor in a link, the status bar shows its address'
    # a link is underlined by its own style, not by Underline: the button stays up
    Check (-not (Pressed $compose $IDF_UNDERLINE)) 'with the cursor in a link, Underline is not pressed'
    Shot $compose 'write-14-link-status'
    # the Link button on a link: its address to change
    Command $compose $IDF_LINK
    $dialog = WaitWindow 'InboxClassicForm' 'Edit Hyperlink' 10
    Check ($dialog -and (WaitFor { (GetText $dialog 100) -eq 'https://example.com/first' } 5)) 'the Link button on a link shows its address to change'
    if ($dialog) {
        Shot $dialog 'write-15-edit-link'
        SetText $dialog 100 'https://example.com/second'
        Click $dialog 1
        [void](WaitFor { -not [Native.Win]::IsWindow($dialog) } 10)
    }
    Check ($null -ne (WaitFor { $t = WindowText $composeStatus; if ($t -like 'https://example.com/second*') { $t } } 10)) 'and changes it'
    # its menu, the app's own: Open Link, Edit Link and Remove Link first, then the editing commands
    $point = [IntPtr]((12 -shl 16) -bor 20)
    [void][Native.Win]::PostMessage($input, 0x0204, [IntPtr]2, $point)
    [void][Native.Win]::PostMessage($input, 0x0205, [IntPtr]::Zero, $point)
    $linkMenu = WaitWindow '#32768' $null 10
    Check ($null -ne $linkMenu) 'a link in the editor has a right-click menu of the app'
    if ($linkMenu) {
        $labels = @([Native.Win]::MenuLabels([Native.Win]::SendMessage($linkMenu, 0x01E1, [IntPtr]::Zero, [IntPtr]::Zero)))
        Check (($labels[0] -eq 'Open Link') -and ($labels -contains 'Edit Link...') -and ($labels -contains 'Remove Link') -and
            ($labels -contains 'Copy') -and ($labels -contains 'Paste') -and ($labels -contains 'Select All') -and
            ($labels -notcontains 'Emoji')) "with Open Link, Edit Link and Remove Link, then Cut, Copy, Paste ($($labels -join ', '))"
        Shot $compose 'write-16-link-menu' $linkMenu
        Key $linkMenu $VK_ESCAPE
        [void](WaitFor { -not [Native.Win]::IsWindow($linkMenu) } 5)
    }
    Start-Sleep -Milliseconds 500
    # emptied, the address takes the link off and leaves its text; the mouse off the text, so the status bar says
    # nothing of a link under it
    $composeRect = New-Object Native.Win+RECT
    [void][Native.Win]::GetWindowRect($compose, [ref]$composeRect)
    [Native.Win]::Mouse($composeRect.Left + 40, $composeRect.Bottom - 8, 0)
    Command $compose $IDF_LINK
    $dialog = WaitWindow 'InboxClassicForm' 'Edit Hyperlink' 10
    Check ($dialog -and (WaitFor { (GetText $dialog 100) -eq 'https://example.com/second' } 5)) 'the dialog shows the changed address'
    if ($dialog) {
        SetText $dialog 100 ''
        Click $dialog 1
        [void](WaitFor { -not [Native.Win]::IsWindow($dialog) } 10)
    }
    Check ([bool](WaitFor { (WindowText $composeStatus) -notlike '*example.com*' } 10)) "an empty address removes the link ($(WindowText $composeStatus))"
    Shot $compose 'write-16b-unlinked'
    Command $compose $IDC_SEND
    $linked = WaitFor { Find 'INBOX' 'Subject: Links in the UI test' } 30
    $raw = if ($linked) { RawText $linked } else { '' }
    Check ($raw -match 'https://example\.com/first' -and $raw -notmatch 'href' -and $raw -notmatch 'example\.com/second') 'the link text went, without the link'

    # a server out of reach, as when offline: its port (106 the incoming, 109 the outgoing) changed in Accounts >
    # Properties, and back
    function SetPort([int]$field, [string]$port) {
        Command $main $IDM_ACCOUNTS
        $list = WaitWindow 'InboxClassicAccounts' 'Accounts'
        if (-not $list) {
            ShowAppWindows $main 'accounts-missing'
            throw 'Tools > Accounts did not open'
        }
        Click $list 402
        $form = WaitFor {
            $f = PropertiesForm
            if ($f -ne [IntPtr]::Zero -and [Native.Win]::GetDlgItem($f, 110) -ne [IntPtr]::Zero) { $f }
        }
        if (-not $form) {
            ShowAppWindows $list 'properties-missing'
            throw 'Properties did not open'
        }
        SetText $form $field $port
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
    function SetSmtpPort([string]$port) { SetPort 109 $port }

    Step 'a message that is not downloaded yet'
    $IDC_RETRY = 214
    $waiting = 'Subject: Waiting on the server'
    # in Archive, so the rows of the Inbox the later steps count stay as they are; dated a moment ahead, so it is the
    # first row there
    AddMessage ("From: Hal Example <hal@example.com>`r`nTo: testuser@inboxclassic.test`r`n$waiting`r`n" +
        "Message-ID: <waiting@example.com>`r`nDate: $([DateTime]::UtcNow.AddMinutes(5).ToString('r'))`r`n`r`nHere at last.`r`n") @() 'Archive'
    Command $main $IDM_SYNC
    [void](WaitFor { Find 'Archive' $waiting })
    SelectFolder 3
    Start-Sleep -Seconds 2
    # a server that takes the connection and says nothing: the download waits
    $silent = New-Object System.Net.Sockets.TcpListener([System.Net.IPAddress]::Loopback, 0)
    $silent.Start()
    SetPort 106 "$($silent.LocalEndpoint.Port)"
    SelectRow 0
    $header = Statics $main
    Check ($header -like '*Waiting on the server*' -and $header -like '*Hal Example*') 'the header shows the message''s sender and subject at once'
    Check (-not (Visible $main $IDC_RETRY)) 'while it is being downloaded there is no Try Again'
    Shot $main 'read-13-downloading'
    # the server gone: why, and Try Again
    $silent.Stop()
    Check ([bool](WaitFor { Visible $main $IDC_RETRY } 30)) 'a message that can not be downloaded says why, with Try Again'
    Shot $main 'read-12-not-downloaded'
    # the server back: the account syncs, and the message is tried again by itself
    SetPort 106 "$($ports.imap)"
    Check ([bool](WaitFor { -not (Visible $main $IDC_RETRY) -and (Find 'Archive' $waiting).flags -contains '\Seen' } 40)) "once the account is back the message shows by itself (Try Again $(Visible $main $IDC_RETRY), flags $((Find 'Archive' $waiting).flags -join ' '))"
    SelectFolder 0

    Step 'the Outbox: a send that can not go'
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
        $waiting = (ListCount ([Native.Win]::GetDlgItem($outbox, 450)))
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
    # a window of its own, not owned by the main window: the main window can come in front of it
    Check ([Native.Win]::GetWindow($compose, 4) -eq [IntPtr]::Zero) 'the message window is a window of its own'
    # neither pinned on top (the screenshots pin the window they take)
    foreach ($w in $main, $compose) { [void][Native.Win]::SetWindowPos($w, [IntPtr](-2), 0, 0, 0, 0, 0x13) }
    [void][Native.Win]::SetForegroundWindow($main)
    Check ([bool](WaitFor { InFront $main $compose } 5)) 'the main window comes in front of a message being written'
    Shot $main 'write-0-main-in-front' $compose
    [void][Native.Win]::SetForegroundWindow($compose)
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
        $composeStatus = [Native.Win]::FindWindowEx($compose, [IntPtr]::Zero, 'msctls_statusbar32', [NullString]::Value)
        Check ($null -ne (WaitFor { $t = WindowText $composeStatus; if ($t -like 'Saved in Drafts at *') { $t } } 30)) 'the message window says when the draft is saved'
        Shot $compose 'write-10-draft-saved'
        Command $compose $IDC_SEND
        $finished = WaitFor { Find 'INBOX' 'Subject: Draft from the UI test' } 30
        Check ($null -ne $finished) 'the finished draft is sent'
        Check ($finished -and (RawText $finished) -match 'Half written' -and (RawText $finished) -match 'Now finished') 'with all that was written'
        Check ([bool](WaitFor { @(Messages 'Drafts').Count -eq 0 } 30)) 'and its draft is gone'
        $mainStatus = [Native.Win]::FindWindowEx($main, [IntPtr]::Zero, 'msctls_statusbar32', [NullString]::Value)
        $outgoing = WaitFor { $t = StatusPart $mainStatus 1; if ($t -like "Sent *Draft from the UI test* at *") { $t } } 30
        Check ($null -ne $outgoing) "the main window says what was sent ($(StatusPart $mainStatus 1))"
        Shot $main 'write-11-sent'
    }
    SelectFolder 0

    # ---- getting new mail ----

    Step 'Send/Recv'
    AddMessage ("From: Ann Example <ann@example.com>`r`nTo: testuser@inboxclassic.test`r`nSubject: One more thing`r`n" +
        "Message-ID: <later@example.com>`r`nDate: $([DateTime]::UtcNow.ToString('r'))`r`n`r`nArrived later.`r`n")
    Command $main $IDM_SYNC
    Check ($null -ne (WaitFor { if ((Rows) -ge 7) { Rows } } 30)) 'the new mail is in the list'
    Shot $main 'main-2-new-mail'
    SelectFolder 1
    Check ($null -ne (WaitFor { if ((Rows) -ge 2) { Rows } })) 'Sent Items has what was sent'
    SelectRow 0
    $firstTo = [Native.Win]::RemoteListText($list, 0, $COL_FROM)
    Check ($firstTo -eq 'Fay') "Sent Items names whom each message went to, in a To column ($firstTo)"
    Shot $main 'main-3-sent-items'
    SelectFolder 0

    # ---- finding ----

    Step 'finding'
    SelectFolder 0
    $all = WaitFor { if ((Rows) -ge 7) { Rows } }
    $IDC_FIND_FIELD = 205; $IDC_FIND_CLEAR = 207
    $field = [Native.Win]::GetDlgItem($main, $IDC_FIND_FIELD)
    $find = [Native.Win]::GetDlgItem($field, 204)
    Check ($find -ne [IntPtr]::Zero) 'there is a Find box, in a search field'
    # a click anywhere in the field, not only on the line of text, starts typing in it: at its left end (the
    # magnifier), its right end and its top edge
    [void][Native.Win]::SetForegroundWindow($main)
    $box = New-Object Native.Win+RECT
    [void][Native.Win]::GetWindowRect($field, [ref]$box)
    $listBox = New-Object Native.Win+RECT
    [void][Native.Win]::GetWindowRect($list, [ref]$listBox)
    $middle = [int](($box.Top + $box.Bottom) / 2)
    foreach ($point in @(@(($box.Left + 6), $middle, 'its left end'), @(($box.Right - 6), $middle, 'its right end'), @([int](($box.Left + $box.Right) / 2), ($box.Top + 4), 'its top edge'))) {
        # somewhere else first: below the rows of the list
        [Native.Win]::MouseClick($listBox.Left + 60, $listBox.Bottom - 10)
        [void](WaitFor { [Native.Win]::FocusOf($main) -eq $list } 3)
        [Native.Win]::MouseClick($point[0], $point[1])
        Check ([bool](WaitFor { [Native.Win]::FocusOf($main) -eq $find } 3)) "a click at $($point[2]) of the search field gives the Find box the focus"
    }
    $listHeader = [Native.Win]::SendMessage($list, 0x101F, [IntPtr]::Zero, [IntPtr]::Zero)
    $columns = { [int][Native.Win]::SendMessage($listHeader, 0x1200, [IntPtr]::Zero, [IntPtr]::Zero) }
    Check ((& $columns) -eq $FOLDER_COLUMNS) 'a folder has no Folder column'
    # the folder bar: the static whose text starts with a space
    $folderBar = { ([Native.Win]::FindDescendants($main, 'Static') | ForEach-Object { WindowText $_ } | Where-Object { $_.StartsWith(' ') } | Select-Object -First 1) }
    [void][Native.Win]::SendMessage($find, $WM_SETTEXT, [IntPtr]::Zero, 'lunch')
    Check ([bool](WaitFor { (Rows) -eq 1 })) 'typing in it narrows the list to what has it (the subject)'
    Check ([bool](WaitFor { (& $columns) -eq ($FOLDER_COLUMNS + 1) } 5)) 'it searches every folder: the list has a Folder column'
    # the search bar over the list says what was found for what, the folder bar where
    $IDC_SEARCH_BAR = 208; $IDC_SEARCH_CLEAR = 209
    $searchBar = { WindowText ([Native.Win]::GetDlgItem($main, $IDC_SEARCH_BAR)) }
    Check ([bool](WaitFor { (Visible $main $IDC_SEARCH_BAR) -and (& $searchBar) -match '^1 result for .lunch. in all folders' } 5)) "the search bar says what was found for what ($(& $searchBar))"
    Check ([bool](WaitFor { (& $folderBar) -eq ' All Folders' } 5)) "the folder bar says where ($(& $folderBar))"
    Check ((WindowText $main) -match '^All Folders') 'and so does the title'
    Shot $main 'find-1-results'
    [void][Native.Win]::SendMessage($find, $WM_SETTEXT, [IntPtr]::Zero, 'ann@example.com')
    Check ([bool](WaitFor { (Rows) -ge 2 })) 'the sender address is found too'
    [void][Native.Win]::SendMessage($find, $WM_SETTEXT, [IntPtr]::Zero, 'nothing has this')
    Check ([bool](WaitFor { (Rows) -eq 0 })) 'and nothing when nothing has it'
    # the list then says so in its middle, and what to try
    Check ([bool](WaitFor { (& $searchBar) -match '^No results for .nothing has this.' } 5)) "the search bar says there are no results ($(& $searchBar))"
    Shot $main 'find-3-no-results'
    [void][Native.Win]::SendMessage($find, $WM_SETTEXT, [IntPtr]::Zero, '')
    Check ([bool](WaitFor { (Rows) -eq $all -and (& $columns) -eq $FOLDER_COLUMNS })) 'clearing it shows the folder again, without the Folder column'
    Check (-not (Visible $main $IDC_SEARCH_BAR)) 'and without the search bar'
    # the clear button is there only while there is something to clear, and clears it
    Check (-not (Visible $field $IDC_FIND_CLEAR)) 'an empty Find box has no clear button'
    [void][Native.Win]::SendMessage($find, $WM_SETTEXT, [IntPtr]::Zero, 'lunch')
    Check ([bool](WaitFor { (Rows) -eq 1 -and (Visible $field $IDC_FIND_CLEAR) })) 'with text in it, it has'
    Click $field $IDC_FIND_CLEAR
    Check ([bool](WaitFor { (Rows) -eq $all -and (WindowText $find) -eq '' -and -not (Visible $field $IDC_FIND_CLEAR) })) 'which empties it and shows the folder'
    # the text of messages is found too, once the search has read it (in the background after a sync; only the text
    # parts are fetched)
    Command $main $IDM_SYNC
    [void][Native.Win]::SendMessage($find, $WM_SETTEXT, [IntPtr]::Zero, 'agreed dates')
    Check ([bool](WaitFor { (Rows) -eq 1 } 40)) 'words of the text are found'
    [void][Native.Win]::SendMessage($find, $WM_SETTEXT, [IntPtr]::Zero, 'from:carol')
    Check ([bool](WaitFor { (Rows) -eq 1 })) 'Gmail operators work: from:'
    # what is in other folders is found as well; in: narrows it to one
    # from the folder (the whole of it), so what is counted is what this search found
    [void][Native.Win]::SendMessage($find, $WM_SETTEXT, [IntPtr]::Zero, '')
    [void](WaitFor { (Rows) -eq $all })
    # the messages found, as the search bar counts them: grouped by conversation a reply in Sent Items shares a row
    # with the message it answers, so the rows do not tell
    $foundCount = { if ((& $searchBar) -match '^(\d+) results? for') { [int]$Matches[1] } else { 0 } }
    [void][Native.Win]::SendMessage($find, $WM_SETTEXT, [IntPtr]::Zero, 'photos in:inbox')
    $inInbox = WaitFor { if ((Rows) -ge 1 -and (& $searchBar) -match ' in Inbox' -and (& $foundCount) -ge 1) { & $foundCount } }
    Check ([bool](WaitFor { (& $folderBar) -eq ' Inbox' -and (& $searchBar) -match ' in Inbox$' } 5)) "in:inbox: the folder bar and the search bar say the Inbox ($(& $folderBar), $(& $searchBar))"
    [void][Native.Win]::SendMessage($find, $WM_SETTEXT, [IntPtr]::Zero, 'photos')
    $everywhere = WaitFor { if ((& $searchBar) -match ' in all folders' -and (& $foundCount) -gt $inInbox) { & $foundCount } }
    Check ([bool]$inInbox -and [bool]$everywhere) "the messages of other folders are found too ($everywhere), in:inbox narrows them to the Inbox ($inInbox)"
    Shot $main 'find-2-every-folder'
    [void][Native.Win]::SendMessage($find, $WM_SETTEXT, [IntPtr]::Zero, 'is:unread')
    Check ([bool](WaitFor { (Rows) -ge 1 -and (Rows) -lt $all })) 'is:unread lists the unread messages'
    # a result from another folder opens where it is
    [void][Native.Win]::SendMessage($find, $WM_SETTEXT, [IntPtr]::Zero, 'photos')
    [void](WaitFor { (Rows) -ge 1 -and (& $foundCount) -eq $everywhere })
    SelectRow 0
    Check ([bool](WaitFor { (WindowText ([Native.Win]::FindDescendants($main, 'Static') | Where-Object { (WindowText $_) -match 'From:' } | Select-Object -First 1)) -match 'Subject:' } 10)) 'a result is shown in the reading pane'
    # Clear search on the search bar ends it
    Click $main $IDC_SEARCH_CLEAR
    Check ([bool](WaitFor { (Rows) -eq $all -and (WindowText $find) -eq '' -and -not (Visible $main $IDC_SEARCH_BAR) })) 'Clear search on the search bar ends the search'
    # and so does Esc, back in the folder
    [void][Native.Win]::SendMessage($find, $WM_SETTEXT, [IntPtr]::Zero, 'photos')
    [void](WaitFor { (Rows) -ge 1 -and (& $foundCount) -eq $everywhere })
    Key $find $VK_ESCAPE
    Check ([bool](WaitFor { (Rows) -eq $all -and (& $columns) -eq $FOLDER_COLUMNS })) 'Esc ends the search: the folder again, without the Folder column'

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
    $move = WaitPicker 'Move Message'
    Check ($null -ne $move) 'Move to Folder asks where'
    if ($move) {
        Check (PickIn $move 'inboxclassic.test' 'Archive') 'Archive can be chosen'
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

    Step 'unsubscribing'
    # the list's server: a socket of the test, answered by hand
    $listServer = New-Object System.Net.Sockets.TcpListener ([System.Net.IPAddress]::Loopback, 0)
    $listServer.Start()
    $listPort = $listServer.LocalEndpoint.Port
    $accepted = $listServer.AcceptTcpClientAsync()
    $listRaw = "Authentication-Results: mx.inboxclassic.test; dkim=pass header.d=list.example.com`r`n" +
        "DKIM-Signature: v=1; d=list.example.com; s=s1; h=from:subject:list-unsubscribe:list-unsubscribe-post; bh=x; b=y`r`n" +
        "From: Weekly List <news@list.example.com>`r`nTo: testuser@inboxclassic.test`r`nSubject: Weekly list news`r`n" +
        "Date: $([DateTime]::UtcNow.ToString('r'))`r`nMessage-ID: <weekly-list@list.example.com>`r`n" +
        "List-Unsubscribe: <mailto:leave@list.example.com>, <http://127.0.0.1:$listPort/u/42>`r`n" +
        "List-Unsubscribe-Post: List-Unsubscribe=One-Click`r`n`r`nThis week on the list.`r`n"
    AddMessage $listRaw
    Command $main $IDM_SYNC
    SelectFolder 0
    $findBox = [Native.Win]::GetDlgItem([Native.Win]::GetDlgItem($main, 205), 204)
    [void](WaitFor { $null -ne (Find 'INBOX' 'Subject: Weekly list news') } 20)
    [void][Native.Win]::SendMessage($findBox, $WM_SETTEXT, [IntPtr]::Zero, 'subject:"Weekly list news"')
    [void](WaitFor { (Rows) -eq 1 } 20)
    SelectRow 0
    $IDC_UNSUBSCRIBE = 210
    Check ([bool](WaitFor { Visible $main $IDC_UNSUBSCRIBE } 15)) 'a message of a mailing list has Unsubscribe in its header'
    Shot $main 'read-8-unsubscribe'
    [void][Native.Win]::PostMessage($main, $WM_COMMAND, [IntPtr]$IDC_UNSUBSCRIBE, [Native.Win]::GetDlgItem($main, $IDC_UNSUBSCRIBE))
    $sure = WaitWindow '#32770' 'Unsubscribe' 10
    Check ($null -ne $sure -and (Statics $sure) -match '127\.0\.0\.1') "it asks first, naming where it goes ($(if ($sure) { Statics $sure }))"
    if ($sure) {
        Shot $sure 'read-9-unsubscribe-ask'
        Click $sure 6
    }
    # the POST of RFC 8058, answered 200
    $sent = ''
    if ($accepted.Wait(15000)) {
        $client = $accepted.Result
        $stream = $client.GetStream()
        $stream.ReadTimeout = 5000
        $buffer = New-Object byte[] 4096
        while ($sent -notmatch 'One-Click') {
            $read = $stream.Read($buffer, 0, $buffer.Length)
            if ($read -le 0) { break }
            $sent += [Text.Encoding]::ASCII.GetString($buffer, 0, $read)
        }
        $answer = [Text.Encoding]::ASCII.GetBytes("HTTP/1.0 200 OK`r`nContent-Length: 2`r`n`r`nok")
        $stream.Write($answer, 0, $answer.Length)
        $client.Close()
    }
    $listServer.Stop()
    Check ($sent -match '^POST /u/42 ' -and $sent -match 'List-Unsubscribe=One-Click') "Yes posts List-Unsubscribe=One-Click to the list ($(($sent -split "`r`n")[0]))"
    $mainStatus = [Native.Win]::FindWindowEx($main, [IntPtr]::Zero, 'msctls_statusbar32', [NullString]::Value)
    Check ([bool](WaitFor { (StatusPart $mainStatus 0) -match 'Unsubscribe request accepted' } 10)) "and the status bar says it is done ($(StatusPart $mainStatus 0))"
    [void][Native.Win]::SendMessage($findBox, $WM_SETTEXT, [IntPtr]::Zero, '')

    Step 'a calendar invitation'
    # a point of the reading pane in a colour of the card, in screen pixels: the middle of the pixels of that colour
    # in the band where it is first found, from the top; $null when there is none
    $pane = [Native.Win]::FindDescendants($main, 'Chrome_RenderWidgetHostHWND') | Select-Object -First 1
    $cardPoint = {
        param([int]$r, [int]$g, [int]$b)
        [void][Native.Win]::SetWindowPos($main, [IntPtr](-1), 0, 0, 0, 0, 0x13)
        [void][Native.Win]::SetForegroundWindow($main)
        Start-Sleep -Milliseconds 500
        $box = New-Object Native.Win+RECT
        [void][Native.Win]::GetWindowRect($pane, [ref]$box)
        [void][Native.Win]::SetWindowPos($main, [IntPtr](-2), 0, 0, 0, 0, 0x13)
        $w = [Math]::Min(560, $box.Right - $box.Left); $h = [Math]::Min(320, $box.Bottom - $box.Top)
        if ($w -le 0 -or $h -le 0) { return $null }
        $picture = New-Object System.Drawing.Bitmap $w, $h
        CopyScreen $picture $box.Left $box.Top
        $first = -1; $xs = @(); $ys = @()
        for ($y = 0; $y -lt $h; $y++) {
            if ($first -ge 0 -and $y -gt $first + 14) { break }
            for ($x = 0; $x -lt $w; $x++) {
                $p = $picture.GetPixel($x, $y)
                if ([Math]::Abs($p.R - $r) -lt 28 -and [Math]::Abs($p.G - $g) -lt 28 -and [Math]::Abs($p.B - $b) -lt 28) {
                    if ($first -lt 0) { $first = $y }
                    $xs += $x; $ys += $y
                }
            }
        }
        if ($first -lt 0) { return $null }
        $xs = @($xs | Sort-Object); $ys = @($ys | Sort-Object)
        @(($box.Left + $xs[[int]($xs.Count / 2)]), ($box.Top + $ys[[int]($ys.Count / 2)]))
    }
    # words of the message shown found by Find in This Message
    $foundInMessage = {
        param([string]$words)
        Command $main $IDM_FIND_IN_MESSAGE
        $form = WaitWindow 'InboxClassicForm' 'Find in This Message' 10
        if (-not $form) { return $false }
        SetText $form 100 $words
        Click $form 1
        Start-Sleep -Milliseconds 1500
        (StatusPart $mainStatus 0) -notmatch 'not in this message'
    }

    $invite = "From: Ann Example <ann@example.com>`r`nTo: testuser@inboxclassic.test`r`nSubject: Invitation: Quarterly planning`r`n" +
        "Date: $([DateTime]::UtcNow.ToString('r'))`r`nMessage-ID: <planning-invite@example.com>`r`n" +
        "Content-Type: multipart/mixed; boundary=inv`r`n`r`n--inv`r`nContent-Type: text/plain`r`n`r`nLet us plan the quarter.`r`n" +
        "--inv`r`nContent-Type: text/calendar; method=REQUEST; charset=utf-8`r`n`r`n" +
        "BEGIN:VCALENDAR`r`nMETHOD:REQUEST`r`nBEGIN:VEVENT`r`nUID:planning@example.com`r`nSUMMARY:Quarterly planning`r`n" +
        "DTSTART:20261201T100000Z`r`nDTEND:20261201T113000Z`r`nLOCATION:Room 2`r`nORGANIZER;CN=Ann Example:mailto:ann@example.com`r`n" +
        "ATTENDEE;CN=Test:mailto:testuser@inboxclassic.test`r`nRRULE:FREQ=WEEKLY;BYDAY=TU;COUNT=4`r`nEND:VEVENT`r`nEND:VCALENDAR`r`n--inv--`r`n"
    AddMessage $invite
    Command $main $IDM_SYNC
    [void](WaitFor { $null -ne (Find 'INBOX' 'Subject: Invitation: Quarterly planning') } 20)
    [void][Native.Win]::SendMessage($findBox, $WM_SETTEXT, [IntPtr]::Zero, 'subject:"Quarterly planning"')
    [void](WaitFor { (Rows) -eq 1 } 20)
    SelectRow 0
    # the event is a card in the message, in the blue of the app's information
    Check ([bool](WaitFor { $null -ne (& $cardPoint 15 95 179) } 15)) 'a message with an invitation shows the event in a card above the text'
    Shot $main 'read-10-invitation'
    [void][Native.Win]::SendMessage($findBox, $WM_SETTEXT, [IntPtr]::Zero, '')

    Step 'a brand logo (BIMI)'
    $logoSvg = '<svg xmlns="http://www.w3.org/2000/svg" version="1.2" baseProfile="tiny-ps" viewBox="0 0 100 100"><title>Brand</title>' +
        '<rect width="100" height="100" rx="22" fill="#0a5bd3"/><circle cx="50" cy="50" r="26" fill="#ffffff"/><circle cx="50" cy="50" r="13" fill="#0a5bd3"/></svg>'
    $indicator = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($logoSvg))
    $branded = "Authentication-Results: mx.inboxclassic.test; dmarc=pass header.from=brand.example; bimi=pass header.d=brand.example`r`n" +
        "BIMI-Indicator: $indicator`r`nFrom: Brand <hello@brand.example>`r`nTo: testuser@inboxclassic.test`r`nSubject: News from the brand`r`n" +
        "Date: $([DateTime]::UtcNow.ToString('r'))`r`nMessage-ID: <brand-news@brand.example>`r`n`r`nOur news.`r`n"
    AddMessage $branded
    Command $main $IDM_SYNC
    [void](WaitFor { $null -ne (Find 'INBOX' 'Subject: News from the brand') } 20)
    [void][Native.Win]::SendMessage($findBox, $WM_SETTEXT, [IntPtr]::Zero, 'subject:"News from the brand"')
    [void](WaitFor { (Rows) -eq 1 } 20)
    $IDC_LOGO = 213
    # selected again while the search's last reload may still take the selection away
    Check ([bool](WaitFor { if ([int][Native.Win]::SendMessage($list, 0x100C, [IntPtr](-1), [IntPtr]2) -ne 0) { SelectRow 0 }; Visible $main $IDC_LOGO } 15)) 'a sender whose logo the server passed has it beside the header'
    Shot $main 'read-11-logo'
    [void][Native.Win]::SendMessage($findBox, $WM_SETTEXT, [IntPtr]::Zero, '')

    Step 'a collapsed account'
    # the account's own item, the first of the tree, and the Inbox under it
    $accountItem = [Native.Win]::SendMessage($tree, $TVM_GETNEXTITEM, [IntPtr]0, [IntPtr]::Zero)
    $inboxItem = [Native.Win]::SendMessage($tree, $TVM_GETNEXTITEM, [IntPtr]4, $accountItem)
    $TVM_GETITEMSTATE = 0x1127; $TVIS_BOLD = 0x10; $VK_LEFT = 0x25; $VK_RIGHT = 0x27
    $bold = { param($item) ([int][Native.Win]::SendMessage($tree, $TVM_GETITEMSTATE, $item, [IntPtr]$TVIS_BOLD) -band $TVIS_BOLD) -ne 0 }
    $inboxText = [Native.Win]::RemoteTreeText($tree, $inboxItem)
    Check ($inboxText -match '\((\d+)\)$') "the Inbox has unread messages ($inboxText)"
    $inboxUnread = if ($inboxText -match '\((\d+)\)$') { [int]$Matches[1] } else { 0 }
    # collapsed with the keyboard, as a user would, so the tree tells the window (TVM_EXPAND would not)
    [void][Native.Win]::SendMessage($tree, $TVM_SELECTITEM, [IntPtr]9, $accountItem)
    [void][Native.Win]::SetForegroundWindow($main)
    [void][Native.Win]::SendMessage($tree, $WM_KEYDOWN, [IntPtr]$VK_LEFT, [IntPtr]::Zero)
    [void][Native.Win]::SendMessage($tree, $WM_KEYUP, [IntPtr]$VK_LEFT, [IntPtr]::Zero)
    $collapsed = WaitFor { $t = [Native.Win]::RemoteTreeText($tree, $accountItem); if ($t -match '\((\d+)\)$' -and [int]$Matches[1] -ge $inboxUnread) { $t } } 5
    Check ([bool]$collapsed) "collapsed, the account shows the unread messages of its folders ($([Native.Win]::RemoteTreeText($tree, $accountItem)))"
    Check (& $bold $accountItem) 'and is bold'
    Shot $main 'folders-5-collapsed'
    [void][Native.Win]::SendMessage($tree, $WM_KEYDOWN, [IntPtr]$VK_RIGHT, [IntPtr]::Zero)
    [void][Native.Win]::SendMessage($tree, $WM_KEYUP, [IntPtr]$VK_RIGHT, [IntPtr]::Zero)
    $expanded = WaitFor { $t = [Native.Win]::RemoteTreeText($tree, $accountItem); if ($t -notmatch '\(\d+\)$') { $t } } 5
    Check ([bool]$expanded -and -not (& $bold $accountItem) -and ([Native.Win]::RemoteTreeText($tree, $inboxItem)) -match '\(\d+\)$') 'expanded, the count is back on the Inbox alone'

    Step 'an AI agent'
    $IDC_AGENT_LEVEL = 600; $IDC_AGENT_PATH = 611; $IDC_AGENT_RECIPIENTS = 612; $IDC_AGENT_WARNING = 614; $IDC_AGENT_SEND = 615
    $IDC_AGENTS_HOSTS = 631; $IDC_AGENTS_LOG = 634; $IDC_AGENTS_UNDO = 635; $BM_GETCHECK = 0x00F0; $BM_SETCHECK = 0x00F1
    # two new messages for the agent to read, whatever the steps before left unread
    $inboxBefore = @(Messages 'INBOX').Count
    foreach ($new in @(@('Maria Lopez <maria@example.org>', 'Quarterly report draft', 'Here is the draft of the quarterly report. Comments by Thursday?'),
                       @('Sam Lee <sam@example.org>', 'Team lunch on Friday', 'Who is in for lunch on Friday at noon?'))) {
        AddMessage ("From: $($new[0])`r`nTo: testuser@inboxclassic.test`r`nSubject: $($new[1])`r`nDate: $([DateTime]::UtcNow.ToString('r'))`r`n" +
            "Message-ID: <$([guid]::NewGuid())@example.org>`r`n`r`n$($new[2])`r`n")
    }
    SelectFolder 0
    Command $main $IDM_SYNC
    # the messages the status bar counts: the rows are fewer where replies share a conversation's row
    [void](WaitFor { (StatusPart $mainStatus 2) -match '^(\d+) message' -and [int]$Matches[1] -ge $inboxBefore + 2 } 20)
    $unreadBefore = @(Messages 'INBOX' | Where-Object { $_.flags -notcontains '\Seen' }).Count
    Start-Sleep -Seconds 1
    Shot $main 'agents-1-before'
    # the agent: Node.js under a name of its own, as an agent host would be, starting the relay (--mcp)
    $agentOut = Join-Path $Out 'agent.jsonl'
    $agentExe = Join-Path $Out 'My AI agent.exe'
    Copy-Item -Force (Get-Command node).Source $agentExe
    $env:APP = (Resolve-Path $Exe).Path; $env:STORE = $store; $env:OUT = $agentOut
    $agent = Start-Process -FilePath $agentExe -ArgumentList "`"$(Join-Path $PSScriptRoot 'ui-e2e\agent.mjs')`"" -PassThru -WindowStyle Hidden
    $agentSaid = { param($step) if (Test-Path $agentOut) { @(Get-Content $agentOut | ForEach-Object { $_ | ConvertFrom-Json } | Where-Object { $_.step -eq $step })[0] } }
    $ask = WaitShown 'InboxClassicAgentAccess' 30
    Check ($null -ne $ask) 'a program whose agent connects for the first time is asked about'
    if ($ask) {
        Check ((WindowText ([Native.Win]::GetDlgItem($ask, $IDC_AGENT_PATH))) -match 'My AI agent\.exe') 'the question names the program'
        $checked = { param($i) [int][Native.Win]::SendMessage([Native.Win]::GetDlgItem($ask, $IDC_AGENT_LEVEL + $i), $BM_GETCHECK, [IntPtr]::Zero, [IntPtr]::Zero) -eq 1 }
        Check ((& $checked 0) -and (& $checked 1) -and -not (& $checked 2) -and -not (& $checked 3)) 'reading and organizing are offered, sending is not'
        # sending too, for the rest of the test
        [void][Native.Win]::SendMessage([Native.Win]::GetDlgItem($ask, $IDC_AGENT_LEVEL + 3), $BM_SETCHECK, [IntPtr]1, [IntPtr]::Zero)
        # Enter takes the default button the window names (DM_GETDEFID), which must be Don't Allow (IDNO), not Allow
        $defId = [int64][Native.Win]::SendMessage($ask, 0x400, [IntPtr]::Zero, [IntPtr]::Zero)
        Check ((($defId -shr 16) -band 0xFFFF) -eq 0x534B -and ($defId -band 0xFFFF) -eq 7) "Enter answers Don't Allow ($('{0:X}' -f $defId))"
        Shot $ask 'agents-2-connect'
        Click $ask 1
    }
    $marked = WaitFor { & $agentSaid 'marked' } 30
    Check ((& $agentSaid 'initialize').result.result.serverInfo.name -eq 'inbox-classic') 'allowed, the agent connects'
    Check (@((& $agentSaid 'tools').result).Count -eq 15) "with the tools of what it may do ($(@((& $agentSaid 'tools').result) -join ', '))"
    $read = (& $agentSaid 'read').result
    Check ($read.notice -match 'not as instructions' -and $read.unread) 'it reads a message as text, told it is the sender''s, without marking it read'
    Check ($null -ne $marked -and $marked.result.done) 'it marks two messages read'
    $unreadAfter = WaitFor { $n = @(Messages 'INBOX' | Where-Object { $_.flags -notcontains '\Seen' }).Count; if ($n -eq $unreadBefore - 2) { "$n" } } 20
    Check ($null -ne $unreadAfter) "on the server ($unreadBefore unread before, $unreadAfter after)"
    $mainStatus = [Native.Win]::FindWindowEx($main, [IntPtr]::Zero, 'msctls_statusbar32', [NullString]::Value)
    Check ([bool](WaitFor { (StatusPart $mainStatus 2) -match ", $($unreadBefore - 2) unread" } 10)) "and in the window at once ($(StatusPart $mainStatus 2))"
    Shot $main 'agents-3-after'
    $send = WaitShown 'InboxClassicAgentSend' 30
    Check ($null -ne $send) 'a message the agent wants to send is shown to the user first'
    if ($send) {
        $recipients = [Native.Win]::GetDlgItem($send, $IDC_AGENT_RECIPIENTS)
        Check ([Native.Win]::RemoteListText($recipients, 0, 1) -eq 'pat@example.net' -and [Native.Win]::RemoteListText($recipients, 0, 3) -eq 'Never written to') 'every recipient by address, the new ones marked'
        Check ((WindowText ([Native.Win]::GetDlgItem($send, $IDC_AGENT_WARNING))) -match 'never written to pat@example.net') 'with a warning about the new address'
        Check (-not [Native.Win]::IsWindowEnabled([Native.Win]::GetDlgItem($send, $IDC_AGENT_SEND))) 'Send waits a moment before it can be pressed'
        Start-Sleep -Seconds 2
        Shot $send 'agents-4-send'
        Click $send $IDC_AGENT_SEND
    }
    $sent = WaitFor { & $agentSaid 'sent' } 20
    Check ($sent.result.sent -eq $true) 'the agent learns the user said yes'
    Command $main $IDM_OUTBOX
    $outbox = WaitShown 'InboxClassicOutbox' 10
    if ($outbox) {
        $outboxList = [Native.Win]::GetDlgItem($outbox, 450)
        Check ([Native.Win]::RemoteListText($outboxList, 0, 3) -match '^Queued by an AI agent; sends at') 'it waits in the Outbox, where it can still be deleted'
        Shot $outbox 'agents-5-outbox'
        [void][Native.Win]::PostMessage($outbox, $WM_CLOSE, [IntPtr]::Zero, [IntPtr]::Zero)
        [void](WaitFor { -not [Native.Win]::IsWindow($outbox) } 10)
    }
    Command $main $IDM_AI_AGENTS
    $agents = WaitShown 'InboxClassicAgents' 10
    Check ($null -ne $agents) 'Tools > AI Agents opens'
    if ($agents) {
        $hosts = [Native.Win]::GetDlgItem($agents, $IDC_AGENTS_HOSTS)
        $log = [Native.Win]::GetDlgItem($agents, $IDC_AGENTS_LOG)
        Check ([Native.Win]::RemoteListText($hosts, 0, 0) -eq 'My AI agent' -and [Native.Win]::RemoteListText($hosts, 0, 1) -match '^Read, organize and send with your yes') "it lists the program and what it may do ($([Native.Win]::RemoteListText($hosts, 0, 1)))"
        $newest = { [Native.Win]::RemoteListText($log, 0, 2) }
        [void](WaitFor { (& $newest) -match '^Sent' } 10)
        Check ((& $newest) -match "^Sent $([char]0x201C)Lunch on Friday\?$([char]0x201D) to pat@example.net" -and [Native.Win]::RemoteListText($log, 1, 2) -match '^Marked read') "and what its agent did, newest first ($(& $newest); $([Native.Win]::RemoteListText($log, 1, 2)))"
        Shot $agents 'agents-6-window'
        # the newest, the message sent, is selected: Undo takes it out of the Outbox before it goes
        Click $agents $IDC_AGENTS_UNDO
        Check ([bool](WaitFor { (& $newest) -match 'taken back' } 10)) "Undo takes the message back ($(& $newest))"
        [void][Native.Win]::PostMessage($agents, $WM_CLOSE, [IntPtr]::Zero, [IntPtr]::Zero)
        [void](WaitFor { -not [Native.Win]::IsWindow($agents) } 10)
    }
    Command $main $IDM_OUTBOX
    $outbox = WaitShown 'InboxClassicOutbox' 10
    if ($outbox) {
        Check ((ListCount ([Native.Win]::GetDlgItem($outbox, 450))) -eq 0) 'and the Outbox is empty'
        [void][Native.Win]::PostMessage($outbox, $WM_CLOSE, [IntPtr]::Zero, [IntPtr]::Zero)
        [void](WaitFor { -not [Native.Win]::IsWindow($outbox) } 10)
    }
    if ($agent -and -not $agent.HasExited) { $agent | Stop-Process -Force -ErrorAction SilentlyContinue }

    Step 'marking all read'
    $IDM_MARK_ALL_READ = 126
    SelectFolder 0
    [void](WaitFor { if ((Rows) -ge 5) { Rows } })
    $mainStatus = [Native.Win]::FindWindowEx($main, [IntPtr]::Zero, 'msctls_statusbar32', [NullString]::Value)
    $unreadOnServer = { @(Messages 'INBOX' | Where-Object { $_.flags -notcontains '\Seen' }).Count }
    Check ((& $unreadOnServer) -ge 1) "the Inbox has unread messages ($(& $unreadOnServer))"
    Command $main $IDM_MARK_ALL_READ
    Check ([bool](WaitFor { (StatusPart $mainStatus 2) -match ', 0 unread' } 10)) "Edit > Mark All Read: none unread in the folder ($(StatusPart $mainStatus 2))"
    Check ([bool](WaitFor { (& $unreadOnServer) -eq 0 } 20)) 'and none on the server'
    Shot $main 'organize-5-all-read'

    Step 'dragging a message onto a folder'
    # a message of its own, the newest, so it is the first row
    # Drag me the newest, Copy me a minute older: the first two rows, over what the test sent this minute
    foreach ($pair in @(@('Drag me', 3), @('Copy me', 2))) {
        $date = [DateTime]::UtcNow.AddMinutes($pair[1]).ToString('r')
        AddMessage "From: Dana <dana@example.com>`r`nTo: testuser@inboxclassic.test`r`nSubject: $($pair[0])`r`nDate: $date`r`nMessage-ID: <$($pair[0] -replace ' ', '-')@example.com>`r`n`r`nDragged in the UI test.`r`n"
    }
    Command $main $IDM_SYNC
    SelectFolder 0
    $inInbox = WaitFor { if ((Rows) -ge 2 -and [Native.Win]::RemoteListText($list, 0, $COL_SUBJECT) -eq 'Drag me' -and [Native.Win]::RemoteListText($list, 1, $COL_SUBJECT) -eq 'Copy me') { Rows } } 30
    # the first row and Archive (the fourth folder) on the screen
    $archiveItem = [Native.Win]::SendMessage($tree, $TVM_GETNEXTITEM, [IntPtr]4, [Native.Win]::SendMessage($tree, $TVM_GETNEXTITEM, [IntPtr]0, [IntPtr]::Zero))
    for ($i = 0; $i -lt 3; $i++) { $archiveItem = [Native.Win]::SendMessage($tree, $TVM_GETNEXTITEM, [IntPtr]1, $archiveItem) }
    function Middle($rect) { @([int](($rect.Left + $rect.Right) / 2), [int](($rect.Top + $rect.Bottom) / 2)) }
    [void][Native.Win]::SetForegroundWindow($main)
    function DragFirstRow([bool]$copy, [string]$shot) {
        $row = Middle ([Native.Win]::RemoteRect($list, 0x100E, [IntPtr]0, 0))
        $row[0] = ([Native.Win]::RemoteRect($list, 0x100E, [IntPtr]0, 0)).Left + 120
        $folder = Middle ([Native.Win]::RemoteRect($tree, 0x1104, [IntPtr]1, $archiveItem.ToInt64()))
        if ($copy) { [Native.Win]::keybd_event(0x11, 0, 0, [IntPtr]::Zero) }
        [Native.Win]::MouseDragTo($row[0], $row[1], $folder[0], $folder[1])
        if ($shot) { Shot $main $shot }
        [Native.Win]::Mouse($folder[0], $folder[1], 0x0004)
        if ($copy) { [Native.Win]::keybd_event(0x11, 0, 2, [IntPtr]::Zero) }
    }
    $first = 'Drag me'
    DragFirstRow $false 'organize-6-drag'
    Check ($null -ne (WaitFor { Find 'Archive' "Subject: $first" } 20)) "a message dragged onto Archive is moved there ($first)"
    Check ([bool](WaitFor { -not (Find 'INBOX' "Subject: $first") } 10)) 'and out of the Inbox'
    # by its subject: mail arriving meanwhile changes the number of rows
    $listed = { param($subject) (SubjectRows $subject).Count -gt 0 }
    Check ([bool](WaitFor { -not (& $listed $first) } 10)) "and out of the list ($(Rows) rows, $inInbox before)"
    $second = 'Copy me'
    DragFirstRow $true ''
    Check ($null -ne (WaitFor { Find 'Archive' "Subject: $second" } 20)) "with Ctrl it is copied there ($second)"
    Check ($null -ne (Find 'INBOX' "Subject: $second")) 'and stays in the Inbox'
    # onto the folder it is in: nothing happens
    $inboxItem = [Native.Win]::SendMessage($tree, $TVM_GETNEXTITEM, [IntPtr]4, [Native.Win]::SendMessage($tree, $TVM_GETNEXTITEM, [IntPtr]0, [IntPtr]::Zero))
    $row = [Native.Win]::RemoteRect($list, 0x100E, [IntPtr]0, 0)
    $inbox = Middle ([Native.Win]::RemoteRect($tree, 0x1104, [IntPtr]1, $inboxItem.ToInt64()))
    $before = Rows
    [Native.Win]::MouseDragTo($row.Left + 120, [int](($row.Top + $row.Bottom) / 2), $inbox[0], $inbox[1])
    [Native.Win]::Mouse($inbox[0], $inbox[1], 0x0004)
    Start-Sleep -Seconds 2
    Check ((Rows) -eq $before -and $null -ne (Find 'INBOX' "Subject: $second")) 'dropped on its own folder, it stays'

    Step 'several messages'
    $IDM_SELECT_ALL = 134; $IDM_UNDO = 135; $TB_ISBUTTONENABLED = 0x0409
    $buttons = [Native.Win]::FindDescendants($main, 'ToolbarWindow32') | Where-Object { [int][Native.Win]::SendMessage($_, 0x0419, [IntPtr]$IDM_SYNC, [IntPtr]::Zero) -ge 0 } | Select-Object -First 1
    $enabled = { param($id) [int][Native.Win]::SendMessage($buttons, $TB_ISBUTTONENABLED, [IntPtr]$id, [IntPtr]::Zero) -ne 0 }
    SelectFolder 0
    $before = WaitFor { if ((Rows) -ge 3) { Rows } }
    SelectRow 0
    # Ctrl+click on the next two rows adds them
    [void][Native.Win]::SetForegroundWindow($main)
    [Native.Win]::keybd_event(0x11, 0, 0, [IntPtr]::Zero)
    foreach ($i in 1, 2) {
        $box = [Native.Win]::RemoteRect($list, 0x100E, [IntPtr]$i, 0)
        [Native.Win]::MouseClick($box.Left + 120, [int](($box.Top + $box.Bottom) / 2))
    }
    [Native.Win]::keybd_event(0x11, 0, 2, [IntPtr]::Zero)
    $subjects = @(0, 1, 2 | ForEach-Object { [Native.Win]::RemoteListText($list, $_, $COL_SUBJECT) })
    $onServer = { param($mailbox) @($subjects | Where-Object { $s = $_; Find $mailbox "Subject: $([regex]::Escape($s))" }).Count }
    # Archive may have one of them already (the copy the drag made)
    $inArchive = & $onServer 'Archive'
    Check ([bool](WaitFor { (StatusPart $mainStatus 2) -match ', 3 selected$' } 10)) "Ctrl+click adds two more messages: three are selected ($(StatusPart $mainStatus 2))"
    Command $main $IDM_MARK_UNREAD
    $allUnread = { @($subjects | Where-Object { (Find 'INBOX' "Subject: $([regex]::Escape($_))").flags -notcontains '\Seen' }).Count -eq 3 }
    Check ([bool](WaitFor $allUnread 20)) 'Mark as Unread marks the three unread on the server'
    Check ((StatusPart $mainStatus 0) -eq 'Marked 3 messages as unread') "the status bar says what was done ($(StatusPart $mainStatus 0))"
    Check ((StatusPart $mainStatus 2) -match ', 3 selected$') 'the status bar says 3 selected'
    Check (-not (& $enabled $IDM_REPLY) -and (& $enabled $IDM_MARK_READ)) 'Reply is off for several, Mark as Read is on'
    Shot $main 'select-1-several'
    Command $main $IDM_MARK_READ
    $allRead = { @($subjects | Where-Object { (Find 'INBOX' "Subject: $([regex]::Escape($_))").flags -contains '\Seen' }).Count -eq 3 }
    Check ([bool](WaitFor $allRead 20)) 'Mark as Read marks the three read on the server'
    Command $main $IDM_MOVE
    $move = WaitPicker 'Move 3 Messages'
    Check ($null -ne $move) 'Move to Folder asks where'
    if ($move) {
        [void](PickIn $move 'inboxclassic.test' 'Archive')
        Click $move 1
    }
    Check ([bool](WaitFor { -not (& $onServer 'INBOX') -and (& $onServer 'Archive') -eq 3 } 20)) 'Move to Folder moves the three to Archive'
    Check ([bool](WaitFor { (Rows) -eq $before - 3 } 10)) 'and out of the list'
    Check ((StatusPart $mainStatus 0) -eq 'Moved 3 messages to Archive') "the status bar says they were moved to Archive ($(StatusPart $mainStatus 0))"
    Command $main $IDM_UNDO
    Check ([bool](WaitFor { (StatusPart $mainStatus 0) -eq 'Moved 3 messages back to Inbox' } 10)) "Edit > Undo Move brings them back to the Inbox ($(StatusPart $mainStatus 0))"
    Check ([bool](WaitFor { (& $onServer 'INBOX') -eq 3 -and (& $onServer 'Archive') -eq $inArchive } 20)) "and on the server ($(& $onServer 'INBOX') in the Inbox, $(& $onServer 'Archive') in Archive)"
    [void](WaitFor { (Rows) -eq $before } 20)
    # the rows selected (LVM_GETNEXTITEM, LVNI_SELECTED), and whether the first of them is in view
    $selectedRows = {
        $found = @(); $i = -1
        while (($i = [int][Native.Win]::SendMessage($list, 0x100C, [IntPtr]$i, [IntPtr]2)) -ge 0) { $found += $i }
        $found
    }
    $restored = {
        $rows = @(& $selectedRows)
        $names = @($rows | ForEach-Object { [Native.Win]::RemoteListText($list, $_, $COL_SUBJECT) } | Sort-Object)
        $top = [int][Native.Win]::SendMessage($list, 0x1027, [IntPtr]::Zero, [IntPtr]::Zero)
        $page = [int][Native.Win]::SendMessage($list, 0x1028, [IntPtr]::Zero, [IntPtr]::Zero)
        $rows.Count -eq 3 -and (($names -join '|') -eq (($subjects | Sort-Object) -join '|')) -and $rows[0] -ge $top -and $rows[0] -lt $top + $page
    }
    Check ([bool](WaitFor $restored 20)) "and selects them, in view ($((& $selectedRows) -join ', '))"
    Shot $main 'select-2-undo'
    [void][Native.Win]::PostMessage($list, 0x0201, [IntPtr]1, [IntPtr]((28 -shl 16) -bor 60))
    [void][Native.Win]::PostMessage($list, 0x0202, [IntPtr]::Zero, [IntPtr]((28 -shl 16) -bor 60))
    Start-Sleep -Milliseconds 300
    Command $main $IDM_SELECT_ALL
    Check ([bool](WaitFor { (StatusPart $mainStatus 2) -match ", $(Rows) selected$" } 10)) "Select All selects every message of the list ($(StatusPart $mainStatus 2))"
    SelectRow 0
    Check ([bool](WaitFor { (StatusPart $mainStatus 2) -notmatch 'selected' -and (& $enabled $IDM_REPLY) } 10)) 'one message selected again is shown in the reading pane'

    Step 'messages as files'
    $kDragOut = 0x44524F55; $kDropFiles = 0x44524F50
    # one not downloaded yet: it arrives now and is never opened
    $notOpened = 'Not opened yet'
    $added = Invoke-RestMethod -Method Post -ContentType 'application/json' "$rest/INBOX/messages" -Body (@{
        raw = "From: Ferry Office <ferry@example.com>`r`nTo: testuser@inboxclassic.test`r`nSubject: $notOpened`r`nDate: $([DateTime]::UtcNow.ToString('r'))`r`nMessage-ID: <not-opened@example.com>`r`n`r`nThe ferry times for the weekend.`r`n"
        flags = @() } | ConvertTo-Json)
    Command $main $IDM_SYNC
    SelectFolder 0
    [void](WaitFor { (Rows) -ge 3 -and [Native.Win]::RemoteListText($list, 0, $COL_SUBJECT) -eq $notOpened } 30)
    # the newest three, the one not downloaded among them
    SelectRow 0
    [void][Native.Win]::SetForegroundWindow($main)
    [Native.Win]::keybd_event(0x11, 0, 0, [IntPtr]::Zero)
    foreach ($i in 1, 2) {
        $box = [Native.Win]::RemoteRect($list, 0x100E, [IntPtr]$i, 0)
        [Native.Win]::MouseClick($box.Left + 120, [int](($box.Top + $box.Bottom) / 2))
    }
    [Native.Win]::keybd_event(0x11, 0, 2, [IntPtr]::Zero)
    [void](WaitFor { (StatusPart $mainStatus 2) -match ', 3 selected$' } 10)
    $three = @(0, 1, 2 | ForEach-Object { [Native.Win]::RemoteListText($list, $_, $COL_SUBJECT) })
    # the file a subject becomes: what Windows does not allow in a name taken out
    $fileOf = { param($subject) (($subject -replace '[/\\]', '-') -replace '[<>:"|?*]', '') + '.eml' }
    $sameBytes = { param($dir)
        @($three | Where-Object {
            $path = Join-Path $dir (& $fileOf $_)
            $server = Find 'INBOX' "Subject: $([regex]::Escape($_))"
            # (an antivirus on the test machine may add its own header to what it fetches over IMAP: not compared)
            $plain = { param($text) (($text -replace "`r`n", "`n") -split "`n" | Where-Object { $_ -notmatch '^X-EsetId:' }) -join "`n" }
            (Test-Path -LiteralPath $path) -and $server -and (& $plain ([IO.File]::ReadAllText($path))) -eq (& $plain (RawText $server))
        }).Count -eq 3
    }
    # dropped into a folder as Explorer drops it: the one not downloaded makes them files fetched at the drop
    $out1 = Join-Path (Resolve-Path $Out) 'dragged-out'
    Remove-Item -Recurse -Force -ErrorAction SilentlyContinue $out1
    [void](New-Item -ItemType Directory -Force $out1)
    $written = [Native.Win]::SendText($main, $kDragOut, $out1)
    Check ($written -eq 3 -and @($three | Where-Object { Test-Path -LiteralPath (Join-Path $out1 (& $fileOf $_)) }).Count -eq 3) "three messages dragged out become three .eml files where they are dropped, named after their subjects ($written)"
    Check (& $sameBytes $out1) 'with what each message is, byte for byte'
    Check ($three -contains $notOpened) 'one not downloaded yet is downloaded for it'
    Shot $main 'files-4-drag-out'
    # all downloaded now: written at once, as files that keep the mark of a download from the internet
    $out2 = Join-Path (Resolve-Path $Out) 'dragged-out-again'
    Remove-Item -Recurse -Force -ErrorAction SilentlyContinue $out2
    [void](New-Item -ItemType Directory -Force $out2)
    $written = [Native.Win]::SendText($main, $kDragOut, $out2)
    $zone = Get-Content -LiteralPath (Join-Path $out2 (& $fileOf $three[0])) -Stream Zone.Identifier -ErrorAction SilentlyContinue
    Check ($written -eq 3 -and (& $sameBytes $out2) -and (($zone -join "`n") -match 'ZoneId=3')) "downloaded, they are files marked as from the internet ($written)"
    # Save As with three: a folder, never over a file there
    $saveDir = Join-Path (Resolve-Path $Out) 'saved-three'
    Remove-Item -Recurse -Force -ErrorAction SilentlyContinue $saveDir
    [void](New-Item -ItemType Directory -Force $saveDir)
    $theirs = Join-Path $saveDir (& $fileOf $three[1])
    Set-Content -LiteralPath $theirs -Value 'mine' -NoNewline
    Command $main $IDM_SAVE_AS
    Check (AnswerFolderDialog 'Save Messages In' $saveDir) 'Save As with three selected asks for a folder'
    $savedAll = WaitFor { (@(Get-ChildItem -LiteralPath $saveDir -Filter '*.eml').Count -eq 4) } 30
    Check ([bool]$savedAll -and (Get-Content -Raw -LiteralPath $theirs) -eq 'mine') "and saves the three there, never over a file that is there ($(@(Get-ChildItem -LiteralPath $saveDir).Count) files)"
    Check ([bool](WaitFor { (StatusPart $mainStatus 0) -eq 'Saved 3 messages to saved-three' } 10)) "the status bar says where ($(StatusPart $mainStatus 0))"
    # Forward with three: one new message with them attached
    Command $main $IDM_FORWARD
    $compose = WaitCompose
    Check ($null -ne $compose) 'Forward with three selected writes one new message'
    if ($compose) {
        $attached = [Native.Win]::GetDlgItem($compose, $IDC_FILES)
        $files = WaitFor { if ((ListBoxCount $attached) -eq 3) { 3 } } 10
        Check ($files -eq 3) 'with the three attached as .eml files'
        Check ((GetText $compose $IDC_SUBJECT) -eq "Fw: $($three[0])") "its subject is the first one's, with Fw: ($(GetText $compose $IDC_SUBJECT))"
        # the mouse out of the way: no tooltip of the format bar in the picture
        [Native.Win]::Mouse(2, 2, 0)
        Start-Sleep -Milliseconds 300
        Shot $compose 'files-5-forward'
        CloseCompose $compose
    }
    # .eml files dropped onto Archive are put in it; a file that is not a message is turned away
    $dropDir = Join-Path (Resolve-Path $Out) 'to-drop'
    Remove-Item -Recurse -Force -ErrorAction SilentlyContinue $dropDir
    [void](New-Item -ItemType Directory -Force $dropDir)
    $dropped = @('Dropped one', 'Dropped two', 'Dropped three') | ForEach-Object {
        $path = Join-Path $dropDir "$_.eml"
        $raw = "From: Files <files@example.com>`r`nTo: testuser@inboxclassic.test`r`nSubject: $_`r`nDate: $([DateTime]::UtcNow.ToString('r'))`r`nMessage-ID: <$($_ -replace ' ', '-')@example.com>`r`n`r`nDropped from a folder.`r`n"
        [IO.File]::WriteAllText($path, $raw)
        $path
    }
    $text = Join-Path $dropDir 'notes.txt'
    Set-Content -LiteralPath $text -Value 'not a message'
    $archive = TreeRow $tree 'inboxclassic.test' 'Archive'
    $effect = [Native.Win]::SendText($main, $kDropFiles, "$($archive.ToInt64())|$($dropped -join '|')")
    $inArchive = { @('Dropped one', 'Dropped two', 'Dropped three' | Where-Object { Find 'Archive' "Subject: $_" }).Count }
    Check ($effect -eq 1 -and [bool](WaitFor { (& $inArchive) -eq 3 } 20)) ".eml files dropped onto Archive in the folder tree are put in it, on the server ($effect, $(& $inArchive))"
    $effect = [Native.Win]::SendText($main, $kDropFiles, "$($archive.ToInt64())|$text")
    Check ($effect -eq 0) "a file that is not a message is turned away ($effect)"
    [void][Native.Win]::SendMessage($tree, $TVM_SELECTITEM, [IntPtr]9, $archive)
    [void](WaitFor { @(0..([Math]::Max(0, (Rows) - 1)) | Where-Object { [Native.Win]::RemoteListText($list, $_, $COL_SUBJECT) -like 'Dropped*' }).Count -eq 3 } 20)
    # one of them shown
    $droppedRow = @(SubjectRows 'Dropped one')[0]
    if ($null -ne $droppedRow) { SelectRow $droppedRow }
    [void](WaitFor { (StatusPart $mainStatus 2) -notmatch 'selected' } 5)
    Shot $main 'files-6-drop-in'
    # the message added for this step goes, so the Inbox is as the steps after expect it
    [void](Invoke-RestMethod -Method Delete "$rest/INBOX/messages/$($added.uid)")
    Command $main $IDM_SYNC
    SelectFolder 0
    [void](WaitFor { [Native.Win]::RemoteListText($list, 0, $COL_SUBJECT) -ne $notOpened } 20)

    Step 'flag colours'
    $IDM_FLAG_COLOR = 900; $IDM_FLAG_CLEAR = 908; $MF_CHECKED = 0x8
    # a message Apple Mail flagged purple: \Flagged with $MailFlagBit0 and $MailFlagBit2
    $apple = 'Flagged in Apple Mail'
    AddMessage ("From: Mira Lind <mira@example.com>`r`nTo: testuser@inboxclassic.test`r`nSubject: $apple`r`nMessage-ID: <apple-flag@example.com>`r`n" +
        "Date: $([DateTime]::UtcNow.ToString('r'))`r`n`r`nFlagged purple in Apple Mail.`r`n") @('\Flagged', '$MailFlagBit0', '$MailFlagBit2')
    Command $main $IDM_SYNC
    SelectFolder 0
    $rowOf = { param($subject) @(SubjectRows $subject)[0] }
    [void](WaitFor { $null -ne (& $rowOf $apple) } 20)
    # a picture of a part of the list's row $row as the screen shows it, the main window in front: the part $rect gives
    # for the row (asked while the window is in front); $null when it is empty
    function CellPicture($row, [scriptblock]$rect) {
        [void][Native.Win]::SetWindowPos($main, [IntPtr](-1), 0, 0, 0, 0, 0x13)
        [void][Native.Win]::SetForegroundWindow($main)
        Start-Sleep -Milliseconds 300
        $cell = & $rect $row
        [void][Native.Win]::SetWindowPos($main, [IntPtr](-2), 0, 0, 0, 0, 0x13)
        if ($cell.Right -le $cell.Left -or $cell.Bottom -le $cell.Top) { return $null }
        $picture = New-Object System.Drawing.Bitmap ($cell.Right - $cell.Left), ($cell.Bottom - $cell.Top)
        CopyScreen $picture $cell.Left $cell.Top
        $picture
    }
    # every pixel of the part $rect gives of the row $row (CellPicture) handed to $visit; false when the part is empty.
    # $visit keeps what it finds in a hashtable of its caller's
    function ScanCell($row, [scriptblock]$rect, [scriptblock]$visit) {
        $picture = CellPicture $row $rect
        if (-not $picture) { return $false }
        for ($x = 0; $x -lt $picture.Width; $x++) {
            for ($y = 0; $y -lt $picture.Height; $y++) { $null = & $visit $picture.GetPixel($x, $y) }
        }
        $true
    }
    # LVM_GETSUBITEMRECT of the flag column (1), its bounds
    $flagCell = { param($row) [Native.Win]::RemoteRect($list, 0x1038, [IntPtr]$row, ([long]1 -shl 32)) }
    # the colour of a row's flag: the most coloured pixel of its flag cell, as the screen shows it
    $flagColor = {
        param($row)
        $found = @{ best = $null; most = -1 }
        $null = ScanCell $row $flagCell {
            param($p)
            $spread = [Math]::Max($p.R, [Math]::Max($p.G, $p.B)) - [Math]::Min($p.R, [Math]::Min($p.G, $p.B))
            if ($spread -gt $found.most) { $found.most = $spread; $found.best = $p }
        }
        $found.best
    }
    $near = { param($c, $r, $g, $b) $c -and [Math]::Abs($c.R - $r) -lt 40 -and [Math]::Abs($c.G - $g) -lt 40 -and [Math]::Abs($c.B - $b) -lt 40 }
    # another row selected, so the flag is drawn on the list's white
    SelectRow ([int](& $rowOf $apple) + 1)
    $purple = & $flagColor (& $rowOf $apple)
    Check (& $near $purple 136 23 152) "a message flagged purple by another program (Apple Mail) shows a purple flag ($purple)"

    # three rows without a flag for the colours
    $plain = @(0..([Math]::Min(8, (Rows) - 1)) | ForEach-Object { [Native.Win]::RemoteListText($list, $_, $COL_SUBJECT) } |
        Where-Object { $_ -and $_ -ne $apple -and ((Find 'INBOX' "Subject: $([regex]::Escape($_))").flags -notcontains '\Flagged') } | Select-Object -First 3)
    $flagsOf = { param($subject) @((Find 'INBOX' "Subject: $([regex]::Escape($subject))").flags) }

    # the menu: the seven colours and Clear Flag
    SelectRow (& $rowOf $plain[0])
    $WM_CONTEXTMENU = 0x007B
    [void][Native.Win]::PostMessage($main, $WM_CONTEXTMENU, $list, [IntPtr](-1))
    $menu = WaitWindow '#32768' $null 10
    if ($menu) {
        $hmenu = [Native.Win]::SendMessage($menu, 0x01E1, [IntPtr]::Zero, [IntPtr]::Zero)
        $labels = [Native.Win]::MenuLabels($hmenu)
        $at = [array]::IndexOf($labels, 'Flag')
        $colours = if ($at -ge 0) { [Native.Win]::MenuLabels([Native.Win]::GetSubMenu($hmenu, $at)) } else { @() }
        Check (($colours -join ',') -eq 'Red,Orange,Yellow,Green,Blue,Purple,Gray,,Clear Flag') "the message menu's Flag has the seven colours of Apple Mail and Clear Flag ($($colours -join ', '))"
        Key $menu $VK_ESCAPE
        [void](WaitFor { [Native.Win]::FindWindow('#32768', [NullString]::Value) -eq [IntPtr]::Zero } 5)
    } else {
        Check $false 'the message list has a right-click menu'
    }

    # orange: \Flagged and $MailFlagBit0
    Command $main ($IDM_FLAG_COLOR + 2)
    Check ([bool](WaitFor { $f = & $flagsOf $plain[0]; ($f -contains '\Flagged') -and ($f -contains '$MailFlagBit0') -and ($f -notcontains '$MailFlagBit1') -and ($f -notcontains '$MailFlagBit2') } 20)) "Orange flags the message orange: \Flagged and `$MailFlagBit0 on the server ($((& $flagsOf $plain[0]) -join ' '))"
    Check ((StatusPart $mainStatus 0) -eq 'Flagged 1 message orange') "the status bar says so ($(StatusPart $mainStatus 0))"
    SelectRow (& $rowOf $apple)
    $orange = & $flagColor (& $rowOf $plain[0])
    Check (& $near $orange 247 99 12) "the flag column shows it in orange ($orange)"

    # blue on two selected
    SelectRow (& $rowOf $plain[1])
    [void][Native.Win]::SetForegroundWindow($main)
    [Native.Win]::keybd_event(0x11, 0, 0, [IntPtr]::Zero)
    $box = [Native.Win]::RemoteRect($list, 0x100E, [IntPtr](& $rowOf $plain[2]), 0)
    [Native.Win]::MouseClick($box.Left + 120, [int](($box.Top + $box.Bottom) / 2))
    [Native.Win]::keybd_event(0x11, 0, 2, [IntPtr]::Zero)
    [void](WaitFor { (StatusPart $mainStatus 2) -match ', 2 selected$' } 10)
    Command $main ($IDM_FLAG_COLOR + 5)
    $blue = { param($s) $f = & $flagsOf $s; ($f -contains '\Flagged') -and ($f -contains '$MailFlagBit2') -and ($f -notcontains '$MailFlagBit0') -and ($f -notcontains '$MailFlagBit1') }
    Check ([bool](WaitFor { (& $blue $plain[1]) -and (& $blue $plain[2]) } 20)) 'Blue on two selected messages flags both blue: $MailFlagBit2'
    # on the selected rows' highlight the flag is drawn white, as the Mac shows it: a blue one would not be seen
    $selectedFlag = {
        param($row)
        # the lightest pixel of the cell
        $found = @{ best = $null; most = -1 }
        $null = ScanCell $row $flagCell {
            param($p)
            $light = [Math]::Min($p.R, [Math]::Min($p.G, $p.B))
            if ($light -gt $found.most) { $found.most = $light; $found.best = $p }
        }
        $found.best
    }
    $white = & $selectedFlag (& $rowOf $plain[1])
    Check ($white -and $white.R -gt 200 -and $white.G -gt 200 -and $white.B -gt 200) "a selected row's flag is drawn white on its highlight ($white)"
    # the menu checks Blue: its Flag submenu opened as the keys open it
    [void][Native.Win]::PostMessage($main, $WM_CONTEXTMENU, $list, [IntPtr](-1))
    $menu = WaitWindow '#32768' $null 10
    $sub = [IntPtr]::Zero
    if ($menu) {
        $hmenu = [Native.Win]::SendMessage($menu, 0x01E1, [IntPtr]::Zero, [IntPtr]::Zero)
        $labels = [Native.Win]::MenuLabels($hmenu)
        # with two selected, what acts on one message alone is greyed (MF_GRAYED | MF_DISABLED)
        $greyed = { param($id) ([Native.Win]::GetMenuState($hmenu, $id, 0) -band 0x3) -ne 0 }
        Check ((& $greyed $IDM_REPLY) -and (& $greyed $IDM_VIEW_SOURCE) -and (& $greyed $IDM_PROPERTIES) -and -not (& $greyed $IDM_FORWARD)) 'with two selected the menu greys Reply to Sender, View Source and Properties, not Forward'
        $at = [array]::IndexOf($labels, 'Flag')
        # Flag clicked where the menu shows it opens its submenu
        $item = New-Object Native.Win+RECT
        if ([Native.Win]::GetMenuItemRect([IntPtr]::Zero, $hmenu, [uint32]$at, [ref]$item)) {
            [Native.Win]::MouseClick([int](($item.Left + $item.Right) / 2), [int](($item.Top + $item.Bottom) / 2))
        }
        # the submenu: another menu window, besides the one opened first
        $otherMenu = {
            $next = [IntPtr]::Zero
            while (($next = [Native.Win]::FindWindowEx([IntPtr]::Zero, $next, '#32768', [NullString]::Value)) -ne [IntPtr]::Zero) {
                if ($next -ne $menu -and [Native.Win]::IsWindowVisible($next)) { return $next }
            }
        }
        $sub = WaitFor $otherMenu 5
        $flagMenu = [Native.Win]::GetSubMenu($hmenu, $at)
        Check ((([Native.Win]::GetMenuState($flagMenu, $IDM_FLAG_COLOR + 5, 0) -band $MF_CHECKED) -ne 0) -and
            (([Native.Win]::GetMenuState($flagMenu, $IDM_FLAG_COLOR + 2, 0) -band $MF_CHECKED) -eq 0)) 'the Flag menu checks Blue, the colour both have'
        if ($sub) { Shot $main 'flags-1-colors' $sub } else { Shot $main 'flags-1-colors' $menu }
        Key $menu $VK_ESCAPE
        Key $menu $VK_ESCAPE
        [void](WaitFor { [Native.Win]::FindWindow('#32768', [NullString]::Value) -eq [IntPtr]::Zero } 5)
    }

    # Clear Flag takes the flag and its colour away
    SelectRow (& $rowOf $plain[0])
    [void][Native.Win]::SetForegroundWindow($main)
    [Native.Win]::keybd_event(0x11, 0, 0, [IntPtr]::Zero)
    foreach ($s in $plain[1], $plain[2], $apple) {
        $box = [Native.Win]::RemoteRect($list, 0x100E, [IntPtr](& $rowOf $s), 0)
        [Native.Win]::MouseClick($box.Left + 120, [int](($box.Top + $box.Bottom) / 2))
    }
    [Native.Win]::keybd_event(0x11, 0, 2, [IntPtr]::Zero)
    [void](WaitFor { (StatusPart $mainStatus 2) -match ', 4 selected$' } 10)
    Command $main $IDM_FLAG_CLEAR
    $cleared = { param($s) $f = & $flagsOf $s; ($f -notcontains '\Flagged') -and ($f -notcontains '$MailFlagBit0') -and ($f -notcontains '$MailFlagBit1') -and ($f -notcontains '$MailFlagBit2') }
    Check ([bool](WaitFor { @($plain + $apple | Where-Object { & $cleared $_ }).Count -eq 4 } 20)) 'Clear Flag takes the flag and its colour away on the server'
    # the message added for this step goes, so the Inbox is as the steps after expect it
    $added = Find 'INBOX' "Subject: $apple"
    if ($added) { [void](Invoke-RestMethod -Method Delete "$rest/INBOX/messages/$($added.uid)") }
    Command $main $IDM_SYNC
    SelectFolder 0
    [void](WaitFor { $null -eq (& $rowOf $apple) } 20)

    Step 'junk and not junk'
    $IDM_JUNK = 127; $IDM_NOT_JUNK = 128; $TB_COMMANDTOINDEX = 0x0419
    # the main toolbar: the one with Send/Recv
    $toolbar = [Native.Win]::FindDescendants($main, 'ToolbarWindow32') | Where-Object { [int][Native.Win]::SendMessage($_, $TB_COMMANDTOINDEX, [IntPtr]$IDM_SYNC, [IntPtr]::Zero) -ge 0 } | Select-Object -First 1
    $hasButton = { param($id) [int][Native.Win]::SendMessage($toolbar, $TB_COMMANDTOINDEX, [IntPtr]$id, [IntPtr]::Zero) -ge 0 }
    SelectFolder 0
    [void](WaitFor { if ((Rows) -ge 3) { Rows } })
    Check ((& $hasButton $IDM_JUNK) -and -not (& $hasButton $IDM_NOT_JUNK)) 'the toolbar has Junk in the Inbox'
    # the first row: the message copied by the drag
    SelectRow 0
    Command $main $IDM_JUNK
    $junked = WaitFor { Find 'Junk' 'Subject: Copy me' } 20
    Check ($null -ne $junked) 'Junk moves the message to Junk E-mail'
    Check ($junked -and $junked.flags -contains '$Junk') "with the `$Junk keyword ($($junked.flags -join ' '))"
    Check ($null -eq (Find 'INBOX' 'Subject: Copy me')) 'and out of the Inbox'
    SelectFolder 4
    [void](WaitFor { if ((Rows) -ge 1) { Rows } } 20)
    Check ([bool](WaitFor { (& $hasButton $IDM_NOT_JUNK) -and -not (& $hasButton $IDM_JUNK) } 5)) 'in Junk E-mail the toolbar has Not Junk in its place'
    # the toolbar redrawn with the new button leaves the search field on it alone: its sunken edge and white inside
    # still there, not the toolbar's face
    [void][Native.Win]::SetWindowPos($main, [IntPtr](-1), 0, 0, 0, 0, 0x13)
    [void][Native.Win]::SetForegroundWindow($main)
    Start-Sleep -Milliseconds 700
    $fieldBox = New-Object Native.Win+RECT
    [void][Native.Win]::GetWindowRect([Native.Win]::GetDlgItem($main, 205), [ref]$fieldBox)
    $fieldPicture = New-Object System.Drawing.Bitmap ($fieldBox.Right - $fieldBox.Left), ($fieldBox.Bottom - $fieldBox.Top)
    CopyScreen $fieldPicture $fieldBox.Left $fieldBox.Top
    [void][Native.Win]::SetWindowPos($main, [IntPtr](-2), 0, 0, 0, 0, 0x13)
    $edgePixel = $fieldPicture.GetPixel(0, [int]($fieldPicture.Height / 2))
    $insidePixel = $fieldPicture.GetPixel([int]($fieldPicture.Width / 2), 3)
    Check ($edgePixel.R -lt 200 -and $insidePixel.R -eq 255 -and $insidePixel.G -eq 255 -and $insidePixel.B -eq 255) "the search field is still drawn over the toolbar (edge $edgePixel, inside $insidePixel)"
    SelectRow 0
    Shot $main 'organize-7-junk'
    Command $main $IDM_NOT_JUNK
    $back = WaitFor { Find 'INBOX' 'Subject: Copy me' } 20
    Check ($null -ne $back) 'Not Junk moves it back to the Inbox'
    Check ($back -and $back.flags -contains '$NotJunk' -and $back.flags -notcontains '$Junk') "with `$NotJunk in place of `$Junk ($($back.flags -join ' '))"
    SelectFolder 0

    # ---- archive ----

    Step 'archive'
    $IDM_ARCHIVE = 138; $IDM_UNDO = 135; $TB_ISBUTTONENABLED = 0x0409
    $mainStatus = [Native.Win]::FindWindowEx($main, [IntPtr]::Zero, 'msctls_statusbar32', [NullString]::Value)
    [void](WaitFor { if ((Rows) -ge 3) { Rows } })
    # as text: row 0 would read as nothing found
    $copyRow = WaitFor { $r = @(SubjectRows 'Copy me'); if ($r.Count) { "$($r[0])" } } 20
    SelectRow ([int]$copyRow)
    $archiveOn = WaitFor { [int][Native.Win]::SendMessage($toolbar, $TB_ISBUTTONENABLED, [IntPtr]$IDM_ARCHIVE, [IntPtr]::Zero) -ne 0 } 5
    Check ([bool]$archiveOn) 'Archive is on for a message of the Inbox'
    Command $main $IDM_ARCHIVE
    $archived = WaitFor { Find 'Archive' 'Subject: Copy me' } 20
    Check ($null -ne $archived) 'Archive moves the message to Archive on the server'
    Check ($null -eq (Find 'INBOX' 'Subject: Copy me')) 'and out of the Inbox'
    $said = WaitFor { $t = StatusPart $mainStatus 0; if ($t -like 'Archived 1 message*') { $t } } 10
    Check ($null -ne $said) "the status bar says it was archived ($(StatusPart $mainStatus 0))"
    Shot $main 'organize-8-archive'
    Command $main $IDM_UNDO
    Check ($null -ne (WaitFor { Find 'INBOX' 'Subject: Copy me' } 20)) 'Undo puts it back in the Inbox'

    # ---- empty folder ----

    Step 'empty folder'
    $IDM_EMPTY_FOLDER = 139; $IDM_SYNC = 102
    AddMessage "From: Spammer <spam@example.net>`r`nTo: testuser@inboxclassic.test`r`nSubject: Win a prize`r`n`r`nClick.`r`n" @() 'Junk'
    SelectFolder 4
    Command $main $IDM_SYNC
    [void](WaitFor { if ((Rows) -ge 1) { Rows } } 20)
    Command $main $IDM_EMPTY_FOLDER
    $sure = WaitWindow '#32770' 'Inbox Classic' 10
    Check ($null -ne $sure) 'Empty Folder asks first, saying how many go'
    if ($sure) {
        Shot $sure 'organize-9-empty'
        Click $sure 6
    }
    Check ($null -ne (WaitFor { if (@(Messages 'Junk').Count -eq 0) { $true } } 20)) 'Junk E-mail is empty on the server'
    Check ([bool](WaitFor { (Rows) -eq 0 } 10)) 'and in the list'
    SelectFolder 0

    # ---- a message in a window of its own ----

    Step 'message window'
    $IDC_PREVIOUS = 231; $IDC_NEXT = 232
    [void](WaitFor { if ((Rows) -ge 2) { Rows } } 20)
    $firstSubject = [Native.Win]::RemoteListText($list, 0, $COL_SUBJECT)
    $secondSubject = [Native.Win]::RemoteListText($list, 1, $COL_SUBJECT)
    $firstPattern = "Subject: $([regex]::Escape($firstSubject))"
    SelectRow 0
    # unread again, so that the window is what marks it read
    [void](WaitFor { Seen $firstPattern } 10)
    Command $main $IDM_MARK_UNREAD
    Check ([bool](WaitFor { -not (Seen $firstPattern) } 20)) "the first message is unread before it is opened ($firstSubject)"
    [void][Native.Win]::SetForegroundWindow($main)
    Key $list $VK_RETURN
    $messageWindow = WaitShown 'InboxClassicMessage' 10
    Check ($null -ne $messageWindow) 'Enter opens the message in a window of its own'
    if ($messageWindow) {
        Check ([Native.Win]::GetWindow($messageWindow, 4) -eq [IntPtr]::Zero) 'a window of its own, not owned by the main window'
        $windowTitle = WindowText $messageWindow
        Check ($windowTitle -eq "$firstSubject - Inbox Classic") "titled with its subject ($windowTitle)"
        Check ([bool](WaitFor { Seen $firstPattern } 20)) 'opening it marked it read on the server'
        Command $messageWindow $IDC_NEXT
        Check ([bool](WaitFor { (WindowText $messageWindow) -eq "$secondSubject - Inbox Classic" } 10)) "Next shows the message after it, the title follows ($(WindowText $messageWindow))"
        Command $messageWindow $IDC_PREVIOUS
        Check ([bool](WaitFor { (WindowText $messageWindow) -eq "$firstSubject - Inbox Classic" } 10)) "Previous goes back ($(WindowText $messageWindow))"
        Start-Sleep -Milliseconds 1000
        Shot $messageWindow 'read-16-window'
        Command $messageWindow $IDM_REPLY
        $compose = WaitCompose
        Check ($null -ne $compose) 'Reply in the window opens a compose window'
        if ($compose) {
            $replySubject = GetText $compose $IDC_SUBJECT
            Check ($replySubject -eq "Re: $firstSubject" -or ($firstSubject -like 'Re:*' -and $replySubject -eq $firstSubject)) "a reply to that message ($replySubject)"
            CloseCompose $compose
        }
        Key $messageWindow $VK_ESCAPE
        Check ([bool](WaitFor { -not [Native.Win]::IsWindow($messageWindow) } 10)) 'Esc closes the window'
        Check ((WindowText $main) -eq 'Inbox - Inbox Classic') "the main window is as it was ($(WindowText $main))"
    }

    # ---- reading with the keyboard ----

    Step 'keyboard reading'
    $IDM_NEXT_MESSAGE = 140; $IDM_PREVIOUS_MESSAGE = 141; $IDM_NEXT_UNREAD = 142; $IDM_GO_TO_FOLDER = 143; $IDM_FIND_IN_MESSAGE = 144
    $IDM_MARK_ALL_READ = 126; $LVM_GETNEXTITEM = 0x100C
    $mainStatus = [Native.Win]::FindWindowEx($main, [IntPtr]::Zero, 'msctls_statusbar32', [NullString]::Value)
    function SelectedRow { [int][Native.Win]::SendMessage($list, $LVM_GETNEXTITEM, [IntPtr](-1), [IntPtr]2) }
    SelectFolder 0
    [void](WaitFor { if ((Rows) -ge 3) { Rows } } 20)
    SelectRow 0
    Command $main $IDM_NEXT_MESSAGE
    Check ([bool](WaitFor { (SelectedRow) -eq 1 } 5)) "Next Message selects the message below ($(SelectedRow))"
    Command $main $IDM_PREVIOUS_MESSAGE
    Check ([bool](WaitFor { (SelectedRow) -eq 0 } 5)) "Previous Message selects the one above ($(SelectedRow))"
    # one unread message in the Inbox, the third, and one in Archive to go on to
    Command $main $IDM_MARK_ALL_READ
    AddMessage "From: Ann Example <ann@example.com>`r`nTo: testuser@inboxclassic.test`r`nSubject: Unread in Archive`r`n`r`nStill unread.`r`n" @() 'Archive'
    Command $main $IDM_SYNC
    $thirdSubject = [Native.Win]::RemoteListText($list, 2, $COL_SUBJECT)
    $thirdPattern = "Subject: $([regex]::Escape($thirdSubject))"
    [void](WaitFor { Seen $thirdPattern } 20)
    SelectRow 2
    [void](WaitFor { Seen $thirdPattern } 10)
    Command $main $IDM_MARK_UNREAD
    [void](WaitFor { -not (Seen $thirdPattern) } 20)
    SelectRow 0
    Command $main $IDM_NEXT_UNREAD
    Check ([bool](WaitFor { (SelectedRow) -eq 2 } 5)) "Next Unread Message selects the next unread message ($(SelectedRow))"
    [void](WaitFor { Seen $thirdPattern } 20)
    Command $main $IDM_NEXT_UNREAD
    $goOn = WaitWindow '#32770' 'Inbox Classic' 10
    $asked = if ($goOn) { Statics $goOn } else { '' }
    Check ($asked -match 'Archive') "with none left it asks to go on to the next folder with unread mail ($asked)"
    if ($goOn) {
        Click $goOn 6
        Check ([bool](WaitFor { (WindowText $main) -eq 'Archive - Inbox Classic' -and (SelectedRow) -ge 0 } 10)) "and Yes goes there, to its unread message ($(WindowText $main))"
    }
    Command $main $IDM_GO_TO_FOLDER
    $goTo = WaitPicker 'Go to Folder'
    Check ($null -ne $goTo) 'Go to Folder opens'
    if ($goTo) {
        $pickerTree = [Native.Win]::GetDlgItem($goTo, 102)
        $texts = @(TreeTexts $pickerTree)
        Check (($texts -contains 'inboxclassic.test') -and ($texts -contains 'Sent Items')) "it shows the folders of every account ($($texts -join ', '))"
        Check (-not (Visible $goTo 103)) 'without New Folder'
        SetText $goTo 101 'sent'
        $narrowed = @(TreeTexts $pickerTree)
        Check (($narrowed -contains 'Sent Items') -and -not ($narrowed -contains 'Drafts')) "typing narrows them ($($narrowed -join ', '))"
        Shot $goTo 'read-18-go-to'
        Check (PickIn $goTo 'inboxclassic.test' 'Sent Items') 'Sent Items can be chosen'
        Click $goTo 1
        Check ([bool](WaitFor { (WindowText $main) -eq 'Sent Items - Inbox Classic' } 10)) "choosing Sent Items shows Sent Items ($(WindowText $main))"
    }
    SelectFolder 0
    [void](WaitFor { if ((Rows) -ge 3) { Rows } } 20)
    $newsRow = WaitFor { $r = @(SubjectRows $newsletter); if ($r.Count) { "$($r[0])" } } 10
    if ($newsRow) { SelectRow ([int]$newsRow) }
    Command $main $IDM_FIND_IN_MESSAGE
    $findForm = WaitWindow 'InboxClassicForm' 'Find in This Message' 10
    Check ($null -ne $findForm) 'Find in This Message asks for the words'
    if ($findForm) {
        SetText $findForm 100 'larches'
        Click $findForm 1
        Start-Sleep -Milliseconds 1500
        $said = StatusPart $mainStatus 0
        Check ($said -notmatch 'not in this message') "it finds a word of the message shown ($said)"
        Shot $main 'read-17-find'
    }
    Command $main $IDM_FIND_IN_MESSAGE
    $findForm = WaitWindow 'InboxClassicForm' 'Find in This Message' 10
    if ($findForm) {
        SetText $findForm 100 'zeppelins'
        Click $findForm 1
        $said = WaitFor { $t = StatusPart $mainStatus 0; if ($t -match 'zeppelins.*not in this message') { $t } } 10
        Check ($null -ne $said) "and says when it is not there ($(StatusPart $mainStatus 0))"
    } else {
        Check $false 'Find in This Message asks again'
    }

    # ---- conversations ----

    Step 'conversations'
    $IDM_EXPAND_ALL_THREADS = 145; $IDM_COLLAPSE_ALL_THREADS = 146; $IDM_OPTIONS = 137; $IDC_OPTIONS_THREADS = 663
    # Tools > Options with Group messages by conversation turned on or off, and OK; whether the box was there
    function SetGrouping([bool]$on, [string]$shot = $null) {
        Command $main $IDM_OPTIONS
        $o = WaitShown 'InboxClassicOptions' 10
        if (-not $o) { return $false }
        $box = [Native.Win]::GetDlgItem($o, $IDC_OPTIONS_THREADS)
        [void][Native.Win]::SendMessage($box, $BM_SETCHECK, [IntPtr]([int]$on), [IntPtr]::Zero)
        if ($shot) { Shot $o $shot }
        Click $o 1
        [void](WaitFor { -not [Native.Win]::IsWindow($o) } 10)
        $box -ne [IntPtr]::Zero
    }
    # Tools > Options: the notifications can name a message's sign-in code, off until chosen, kept for the next start
    $IDC_OPTIONS_CODES = 664
    Command $main $IDM_OPTIONS
    $o = WaitShown 'InboxClassicOptions' 10
    if ($o) {
        $codes = [Native.Win]::GetDlgItem($o, $IDC_OPTIONS_CODES)
        Check ($codes -ne [IntPtr]::Zero -and [int][Native.Win]::SendMessage($codes, $BM_GETCHECK, [IntPtr]::Zero, [IntPtr]::Zero) -eq 0) 'Options can show sign-in codes in new mail notifications, off at first'
        [void][Native.Win]::SendMessage($codes, $BM_SETCHECK, [IntPtr]1, [IntPtr]::Zero)
        Click $o 1
        [void](WaitFor { -not [Native.Win]::IsWindow($o) } 10)
        Check ((Get-ItemProperty -Path $preferencesKey -Name CodesInNotifications -ErrorAction SilentlyContinue).CodesInNotifications -eq 1) 'turned on, that is kept for the next start'
    } else {
        Check $false 'Tools > Options opens'
    }
    $topic = 'Trip to the coast'
    $coast = @('coast1@example.com', 'coast2@example.com', 'coast3@example.com')
    $coastSeen = { @($coast | Where-Object { Seen "Message-ID: <$([regex]::Escape($_))>" }).Count }
    SelectFolder 0
    [void](WaitFor { if ((Rows) -ge 3) { Rows } } 20)
    # three messages of one conversation, each answering the one before
    $date = [DateTime]::UtcNow
    AddMessage ("From: Ann Example <ann@example.com>`r`nTo: testuser@inboxclassic.test`r`nSubject: $topic`r`n" +
        "Message-ID: <$($coast[0])>`r`nDate: $($date.AddMinutes(1).ToString('r'))`r`n`r`nShall we go to the coast on Sunday?`r`n")
    AddMessage ("From: Bob Harris <bob@example.com>`r`nTo: testuser@inboxclassic.test`r`nSubject: Re: $topic`r`n" +
        "Message-ID: <$($coast[1])>`r`nIn-Reply-To: <$($coast[0])>`r`nReferences: <$($coast[0])>`r`n" +
        "Date: $($date.AddMinutes(2).ToString('r'))`r`n`r`nI am in.`r`n")
    AddMessage ("From: Carol <carol@example.com>`r`nTo: testuser@inboxclassic.test`r`nSubject: Re: $topic`r`n" +
        "Message-ID: <$($coast[2])>`r`nIn-Reply-To: <$($coast[1])>`r`nReferences: <$($coast[0])> <$($coast[1])>`r`n" +
        "Date: $($date.AddMinutes(3).ToString('r'))`r`n`r`nMe too, I will bring the sandwiches.`r`n")
    Command $main $IDM_SYNC
    # grouped, as it is out of the box: the three are one row, on the first message
    $grouped = WaitFor { if ((SubjectRows $topic).Count -eq 1 -and (SubjectRows "Re: $topic").Count -eq 0 -and
        (StatusPart $mainStatus 2) -match '^(\d+) message' -and [int]$Matches[1] -eq @(Messages 'INBOX').Count) { Rows } } 30
    # every message of the Inbox, a row each when nothing is grouped
    $flat = @(Messages 'INBOX').Count
    $head = @(SubjectRows $topic)
    Check ($null -ne $grouped -and $head.Count -eq 1 -and $grouped -lt $flat) "the Inbox lists the conversation once, on its first message ($(Rows) rows of $flat messages)"
    if ($head.Count -eq 1) {
        $at = [int]$head[0]
        SelectRow $at
        Check ((SelectedRow) -eq $at) "its row can be selected ($(SelectedRow))"
        Shot $main 'threads-1-collapsed'
        Key $list $VK_RIGHT
        Check ([bool](WaitFor { (Rows) -eq $grouped + 2 } 10)) "Right expands it ($(Rows) rows)"
        $under = @(($at + 1), ($at + 2) | ForEach-Object { [Native.Win]::RemoteListText($list, $_, $COL_SUBJECT) })
        Check (($under | Where-Object { $_ -eq "Re: $topic" }).Count -eq 2) "its replies are under it ($($under -join ', '))"
        Shot $main 'threads-2-expanded'
        Key $list $VK_LEFT
        Check ([bool](WaitFor { (Rows) -eq $grouped } 10)) "Left collapses it again ($(Rows) rows)"
        Check ((SelectedRow) -eq $at) "its row stays selected ($(SelectedRow))"
        Command $main $IDM_EXPAND_ALL_THREADS
        Check ([bool](WaitFor { (Rows) -eq $flat } 10)) "Expand All Conversations shows every message ($(Rows) of $flat)"
        Command $main $IDM_COLLAPSE_ALL_THREADS
        Check ([bool](WaitFor { (Rows) -eq $grouped } 10)) "Collapse All Conversations hides the replies again ($(Rows))"
        # the replies are still unread; the first message is read once it was shown
        Check ((& $coastSeen) -lt 3) "not all of the conversation is read yet ($(& $coastSeen))"
        $at = [int](@(SubjectRows $topic)[0])
        SelectRow $at
        Command $main $IDM_MARK_READ
        Check ([bool](WaitFor { (& $coastSeen) -eq 3 } 20)) "Mark Read on the collapsed row marks all three read on the server ($(& $coastSeen))"
    }
    Check (SetGrouping $false) 'Group messages by conversation can be turned off'
    Check ([bool](WaitFor { (Rows) -eq $flat -and (SubjectRows "Re: $topic").Count -eq 2 } 10)) "with it off the three messages are three rows ($(Rows))"
    Check ((Get-ItemProperty -Path $preferencesKey -Name GroupByConversation -ErrorAction SilentlyContinue).GroupByConversation -eq 0) 'and that is kept for the next start'
    Shot $main 'threads-3-options-off'
    Check (SetGrouping $true) 'and on again'
    Check ([bool](WaitFor { (Rows) -eq $grouped -and (SubjectRows $topic).Count -eq 1 -and (SubjectRows "Re: $topic").Count -eq 0 } 10)) "turned on again, the conversation is one row again ($(Rows))"
    # ---- watch and ignore conversation ----

    Step 'watch and ignore conversation'
    $IDM_WATCH_CONVERSATION = 151; $IDM_IGNORE_CONVERSATION = 152; $IDM_HIDE_IGNORED = 153
    $kTestNotification = 0x4E4F5445; $VK_K = 0x4B
    $WM_INITMENUPOPUP = 0x0117; $WM_SYSCOMMAND = 0x0112; $SC_MINIMIZE = 0xF020; $WM_TRAY = 0x8000 + 60; $NIN_SELECT = 0x0400
    $bar = [Native.Win]::GetMenu($main)
    # whether an item of a menu of the bar (View is the third, Message the fifth) is checked, as the menu opens
    function MenuChecked([int]$position, [int]$id) {
        $sub = [Native.Win]::GetSubMenu($bar, $position)
        [void][Native.Win]::SendMessage($main, $WM_INITMENUPOPUP, $sub, [IntPtr]$position)
        ([Native.Win]::GetMenuState($sub, $id, 0) -band 0x8) -ne 0
    }
    # whether the last new mail notification since the last ask had this heading ('' for none)
    function Notified([string]$heading) { [Native.Win]::SendText($main, $kTestNotification, $heading) -eq 1 }
    # the window minimized, so new mail is announced, and back
    function Minimize { [void][Native.Win]::PostMessage($main, $WM_SYSCOMMAND, [IntPtr]$SC_MINIMIZE, [IntPtr]::Zero); Start-Sleep -Seconds 1 }
    function Restore {
        [void][Native.Win]::PostMessage($main, $WM_TRAY, [IntPtr]::Zero, [IntPtr]$NIN_SELECT)
        [void](WaitFor { -not [Native.Win]::IsIconic($main) } 10)
        SelectFolder 0
        Start-Sleep -Seconds 1
    }
    # whether an item of the selected row's right-click menu is checked: the list has no Watch column, the menu says it
    function ContextChecked([int]$id) {
        # WM_CONTEXTMENU from the keyboard: the menu at the selected row
        [void][Native.Win]::PostMessage($main, 0x007B, $list, [IntPtr](-1))
        $menu = WaitWindow '#32768' $null 10
        $checked = $false
        if ($menu) {
            $hmenu = [Native.Win]::SendMessage($menu, 0x01E1, [IntPtr]::Zero, [IntPtr]::Zero)
            $checked = ([Native.Win]::GetMenuState($hmenu, $id, 0) -band 0x8) -ne 0
            Key $menu $VK_ESCAPE
            [void](WaitFor { [Native.Win]::FindWindow('#32768', [NullString]::Value) -eq [IntPtr]::Zero } 5)
        }
        [void][Native.Win]::SetForegroundWindow($main)
        $checked
    }
    # the message list's columns, Watch and Size gone, Subject the widest
    $width = { param($column) [int][Native.Win]::SendMessage($list, 0x101D, [IntPtr]$column, [IntPtr]::Zero) }
    Check ((& $width $COL_SUBJECT) -gt (& $width $COL_FROM) -and (& $width $COL_SUBJECT) -gt (& $width $COL_RECEIVED)) "the list has no Watch or Size column, and Subject takes the room ($(& $width $COL_SUBJECT) wide)"
    # the darkest pixel of a row's From cell: black for its words, grey for an ignored conversation's
    $fromCell = { param($row) [Native.Win]::RemoteRect($list, 0x1038, [IntPtr]$row, ([long]$COL_FROM -shl 32)) }
    $darkest = {
        param($row)
        $found = @{ least = 255 }
        $null = ScanCell $row $fromCell { param($p) $found.least = [Math]::Min($found.least, [Math]::Max($p.R, [Math]::Max($p.G, $p.B))) }
        $found.least
    }
    $coastRow = { @(SubjectRows $topic)[0] }
    SelectRow (& $coastRow)
    Command $main $IDM_WATCH_CONVERSATION
    Check ([bool](WaitFor { (StatusPart $mainStatus 0) -match 'Watching' } 10)) "Watch Conversation says so ($(StatusPart $mainStatus 0))"
    Check ([bool](WaitFor { ContextChecked $IDM_WATCH_CONVERSATION } 10)) 'the right-click menu checks Watch Conversation'
    Check (MenuChecked 4 $IDM_WATCH_CONVERSATION) 'and Watch Conversation is checked in the Message menu'
    Check (-not (MenuChecked 4 $IDM_IGNORE_CONVERSATION)) 'Ignore Conversation is not'
    Shot $main 'threads-4-watch'
    # a reply to it while the window is minimized: announced as a watched conversation
    [void](Notified '')
    $toolbarHeight = { $r = New-Object Native.Win+RECT; [void][Native.Win]::GetWindowRect($toolbar, [ref]$r); $r.Bottom - $r.Top }
    $tallBefore = & $toolbarHeight
    Minimize
    $coast += 'coast4@example.com'
    AddMessage ("From: Dan <dan@example.com>`r`nTo: testuser@inboxclassic.test`r`nSubject: Re: $topic`r`n" +
        "Message-ID: <$($coast[3])>`r`nIn-Reply-To: <$($coast[2])>`r`nReferences: <$($coast[0])> <$($coast[2])>`r`n" +
        "Date: $($date.AddMinutes(4).ToString('r'))`r`n`r`nCount me in as well.`r`n")
    Command $main $IDM_SYNC
    Check ([bool](WaitFor { Notified 'Watched conversation' } 30)) 'a new reply to it is announced as a watched conversation'
    Restore
    Check ([bool](WaitFor { (& $toolbarHeight) -eq $tallBefore } 5)) "minimized and restored, the toolbar keeps its labels ($(& $toolbarHeight), was $tallBefore)"
    SelectRow (& $coastRow)
    Command $main $IDM_WATCH_CONVERSATION
    Check ([bool](WaitFor { (StatusPart $mainStatus 0) -match 'Stopped watching' } 10)) "Watch Conversation again stops watching it ($(StatusPart $mainStatus 0))"
    Check ([bool](WaitFor { -not (ContextChecked $IDM_WATCH_CONVERSATION) } 10)) 'and the right-click menu no longer checks it'
    Check (-not (MenuChecked 4 $IDM_WATCH_CONVERSATION)) 'and the menu item is no longer checked'

    # another conversation, ignored with K
    $party = 'Garden party'
    $garden = @('garden1@example.com', 'garden2@example.com', 'garden3@example.com')
    $gardenSeen = { @($garden | Where-Object { Seen "Message-ID: <$([regex]::Escape($_))>" }).Count }
    AddMessage ("From: Erin <erin@example.com>`r`nTo: testuser@inboxclassic.test`r`nSubject: $party`r`n" +
        "Message-ID: <$($garden[0])>`r`nDate: $($date.AddMinutes(5).ToString('r'))`r`n`r`nA garden party on Saturday, who is coming?`r`n")
    AddMessage ("From: Frank <frank@example.com>`r`nTo: testuser@inboxclassic.test`r`nSubject: Re: $party`r`n" +
        "Message-ID: <$($garden[1])>`r`nIn-Reply-To: <$($garden[0])>`r`nReferences: <$($garden[0])>`r`n" +
        "Date: $($date.AddMinutes(6).ToString('r'))`r`n`r`nI will bring a cake.`r`n")
    Command $main $IDM_SYNC
    $partyRow = { @(SubjectRows $party)[0] }
    Check ([bool](WaitFor { $null -ne (& $partyRow) } 30)) 'a second conversation is in the Inbox'
    SelectRow (& $partyRow)
    Key $list $VK_K
    Check ([bool](WaitFor { (StatusPart $mainStatus 0) -match 'Ignoring' } 10)) "K ignores the conversation ($(StatusPart $mainStatus 0))"
    Check ([bool](WaitFor { (& $gardenSeen) -eq 2 } 20)) "and marks its messages read on the server ($(& $gardenSeen))"
    Check ([bool](WaitFor { ContextChecked $IDM_IGNORE_CONVERSATION } 10)) 'the right-click menu checks Ignore Conversation'
    Check (MenuChecked 4 $IDM_IGNORE_CONVERSATION) 'and Ignore Conversation is checked in the Message menu'
    # another row selected, so the ignored one is drawn on the list's white
    SelectRow (& $coastRow)
    $grey = & $darkest (& $partyRow)
    Check ($grey -gt 60) "its row is grey (darkest $grey, $(& $darkest (& $coastRow)) for another)"
    Shot $main 'threads-5-ignore'
    # a reply to it while the window is minimized: read on the server, not announced
    [void](Notified '')
    Minimize
    AddMessage ("From: Gail <gail@example.com>`r`nTo: testuser@inboxclassic.test`r`nSubject: Re: $party`r`n" +
        "Message-ID: <$($garden[2])>`r`nIn-Reply-To: <$($garden[1])>`r`nReferences: <$($garden[0])> <$($garden[1])>`r`n" +
        "Date: $($date.AddMinutes(7).ToString('r'))`r`n`r`nCan I bring my dog?`r`n")
    Command $main $IDM_SYNC
    Check ([bool](WaitFor { (& $gardenSeen) -eq 3 } 30)) "a new reply to it arrives read on the server ($(& $gardenSeen))"
    Start-Sleep -Seconds 2
    Check (Notified '') 'without a notification'
    Restore
    # View > Hide Ignored Conversations leaves it out, kept for the next start
    Command $main $IDM_HIDE_IGNORED
    Check ([bool](WaitFor { (SubjectRows $party).Count -eq 0 -and (SubjectRows $topic).Count -eq 1 } 10)) 'Hide Ignored Conversations leaves the ignored conversation out of the list'
    Check (MenuChecked 2 $IDM_HIDE_IGNORED) 'and is checked in the View menu'
    Check ((Get-ItemProperty -Path $preferencesKey -Name HideIgnoredConversations -ErrorAction SilentlyContinue).HideIgnoredConversations -eq 1) 'and that is kept for the next start'
    Command $main $IDM_HIDE_IGNORED
    Check ([bool](WaitFor { (SubjectRows $party).Count -eq 1 } 10)) 'turned off again, it is back'
    Check (-not (MenuChecked 2 $IDM_HIDE_IGNORED)) 'and the menu item is no longer checked'
    $coast += $garden

    # the Inbox as the steps after expect it, without the conversations
    foreach ($id in $coast) {
        $m = Find 'INBOX' "Message-ID: <$([regex]::Escape($id))>"
        if ($m) { [void](Invoke-RestMethod -Method Delete "$rest/INBOX/messages/$($m.uid)") }
    }
    Command $main $IDM_SYNC
    [void](WaitFor { (SubjectRows $topic).Count -eq 0 } 20)

    # ---- a message that bounced ----

    Step 'a message that bounced'
    # a message in Sent Items, a report that it could not be delivered to one of its recipients and a notice that it
    # is delayed for the other, in the forms of pe-bounce's fixtures (Postfix's report, a delay notice)
    $bounced = 'Plans for the weekend'
    $failedSubject = 'Undelivered Mail Returned to Sender'
    $delayedSubject = 'Delayed Mail (still being retried)'
    $serverWords = 'The email account that you tried to reach does not exist'
    $now = [DateTime]::UtcNow
    $original = @(
        'From: Alex Morgan <testuser@inboxclassic.test>', 'To: Sam Nobody <sam.nobody@example.org>, Kim <kim@example.net>',
        "Subject: $bounced", 'Message-ID: <bounce-original@inboxclassic.test>', "Date: $($now.AddMinutes(-10).ToString('r'))")
    AddMessage (($original -join "`r`n") + "`r`n`r`nShall we go to the lake on Saturday?`r`n") @('\Seen') 'Sent'
    AddMessage ((@(
        'From: MAILER-DAEMON@mail.inboxclassic.test (Mail Delivery System)', 'To: testuser@inboxclassic.test',
        "Subject: $failedSubject", 'Message-ID: <bounce-failed@mail.inboxclassic.test>', "Date: $($now.ToString('r'))",
        'Auto-Submitted: auto-replied', 'MIME-Version: 1.0',
        'Content-Type: multipart/report; report-type=delivery-status; boundary="failed"', '',
        'This is a MIME-encapsulated message.', '', '--failed', 'Content-Description: Notification',
        'Content-Type: text/plain; charset=us-ascii', '', 'This is the mail system at host mail.inboxclassic.test.', '',
        "I'm sorry to have to inform you that your message could not", "be delivered to one or more recipients. It's attached below.", '',
        '                   The mail system', '', '--failed', 'Content-Description: Delivery report',
        'Content-Type: message/delivery-status', '', 'Reporting-MTA: dns; mail.inboxclassic.test', '',
        'Final-Recipient: rfc822; sam.nobody@example.org', 'Original-Recipient: rfc822;sam.nobody@example.org', 'Action: failed',
        'Status: 5.1.1', 'Remote-MTA: dns; mx.example.org', "Diagnostic-Code: smtp; 550 5.1.1 $serverWords. Please try double-checking the recipient's email address for typos", '',
        '--failed', 'Content-Description: Undelivered Message Headers', 'Content-Type: text/rfc822-headers', '') + $original +
        @('', '--failed--', '')) -join "`r`n")
    AddMessage ((@(
        'From: Mail Delivery System <MAILER-DAEMON@mail.inboxclassic.test>', 'To: testuser@inboxclassic.test',
        "Subject: $delayedSubject", 'Message-ID: <bounce-delayed@mail.inboxclassic.test>', "Date: $($now.AddMinutes(-1).ToString('r'))",
        'MIME-Version: 1.0', 'Content-Type: multipart/report; report-type=delivery-status; boundary="delayed"', '',
        '--delayed', 'Content-Type: text/plain', '', 'This is a warning message only. Delivery is still being retried.', '',
        '--delayed', 'Content-Type: message/delivery-status', '', 'Reporting-MTA: dns; mail.inboxclassic.test', '',
        'Final-Recipient: rfc822; kim@example.net', 'Action: delayed', 'Status: 4.4.1',
        "Will-Retry-Until: $($now.AddDays(5).ToString('r'))", 'Diagnostic-Code: smtp; 421 4.4.1 Connection timed out', '',
        '--delayed', 'Content-Type: text/rfc822-headers', '') + $original + @('', '--delayed--', '')) -join "`r`n")
    Command $main $IDM_SYNC
    # the message that bounced in the store, so the card can link to it
    SelectFolder 1
    Check ([bool](WaitFor { $null -ne (& $rowOf $bounced) } 20)) 'the message is in Sent Items'
    SelectFolder 0
    Check ([bool](WaitFor { ($null -ne (& $rowOf $failedSubject)) -and ($null -ne (& $rowOf $delayedSubject)) } 20)) 'the report and the delay notice are in the Inbox'

    # the dark pixels of a row's attachment column (0), as the screen shows them: where its icon is
    $markCell = {
        param($row)
        $bounds = [Native.Win]::RemoteRect($list, 0x100E, [IntPtr]$row, 0)
        # LVM_GETCOLUMNWIDTH
        $width = [int][Native.Win]::SendMessage($list, 0x101D, [IntPtr]0, [IntPtr]::Zero)
        [pscustomobject]@{ Left = $bounds.Left; Top = $bounds.Top; Right = $bounds.Left + $width; Bottom = $bounds.Bottom }
    }
    $markOf = {
        param($row)
        $picture = CellPicture $row $markCell
        if (-not $picture) { return '' }
        $dark = @()
        for ($x = 0; $x -lt $picture.Width; $x++) {
            for ($y = 0; $y -lt $picture.Height; $y++) {
                $p = $picture.GetPixel($x, $y)
                if ($p.R -lt 120 -and $p.G -lt 120 -and $p.B -lt 120) { $dark += "$x,$y" }
            }
        }
        $dark -join ' '
    }
    # another row selected, so the marks are drawn on the list's white
    $failedRow = & $rowOf $failedSubject
    $delayedRow = & $rowOf $delayedSubject
    $clipRow = & $rowOf $newsletter
    $otherRow = @(0..((Rows) - 1) | Where-Object { $_ -ne $failedRow -and $_ -ne $delayedRow -and $_ -ne $clipRow })[0]
    SelectRow $otherRow
    $failedMark = & $markOf $failedRow
    $clipMark = if ($null -ne $clipRow) { & $markOf $clipRow } else { '' }
    Check ($failedMark -ne '' -and $failedMark -ne $clipMark) 'the report has the undelivered mark in the attachment column, not a paper clip'
    Check ((& $markOf $delayedRow) -eq $failedMark) 'and so has the delay notice'

    SelectRow $failedRow
    Check ([bool](WaitFor { $null -ne (& $cardPoint 196 43 28) } 15)) 'opening the report shows the red card of a message not delivered'
    # Show the message that bounced: the card's button, followed as a click on it would be
    Check ([bool](WaitFor { & $foundInMessage 'Show the message that bounced' } 5)) 'the card has Show the message that bounced'
    Check ([Native.Win]::SendText($main, 0x4C494E4B, 'inboxclassic:bounced-message') -eq 1) 'which is a link of the card'
    Check ([bool](WaitFor { (WindowText $main) -eq 'Sent Items - Inbox Classic' -and (SelectedRow) -ge 0 -and [Native.Win]::RemoteListText($list, (SelectedRow), $COL_SUBJECT) -eq $bounced } 10)) "and it selects the message in Sent Items ($(WindowText $main))"
    SelectFolder 0
    [void](WaitFor { $null -ne (& $rowOf $failedSubject) } 20)
    SelectRow (& $rowOf $failedSubject)
    [void](WaitFor { $null -ne (& $cardPoint 196 43 28) } 15)
    Check ([bool](WaitFor { & $foundInMessage 'Your message was not delivered' } 5)) 'the card says the message was not delivered'
    Check ([bool](WaitFor { & $foundInMessage 'sam.nobody@example.org' } 5)) 'it names the recipient'
    Check ([bool](WaitFor { & $foundInMessage 'The address does not exist' } 5)) 'why'
    Check ([bool](WaitFor { & $foundInMessage 'Check the spelling of the address' } 5)) 'and what to do'
    # Details, folded, opened by the find
    Check ([bool](WaitFor { & $foundInMessage $serverWords } 5)) "its Details show the server's own words"
    Shot $main 'bounce-1-failed'

    SelectRow (& $rowOf $delayedSubject)
    Check ([bool](WaitFor { $null -ne (& $cardPoint 154 91 0) } 15)) 'a delay notice shows the amber card'
    Check ([bool](WaitFor { & $foundInMessage 'Your message has not been delivered yet' } 5)) 'it says the message is not delivered yet'
    Check ([bool](WaitFor { & $foundInMessage 'still trying to deliver it' } 5)) 'and that it is still being tried'
    Shot $main 'bounce-2-delayed'

    [void][Native.Win]::SendMessage($find, $WM_SETTEXT, [IntPtr]::Zero, 'is:bounce')
    $both = WaitFor {
        $found = @(0..([Math]::Max(0, (Rows) - 1)) | ForEach-Object { [Native.Win]::RemoteListText($list, $_, $COL_SUBJECT) })
        if ((Rows) -eq 2 -and $found -contains $failedSubject -and $found -contains $delayedSubject) { $true }
    } 15
    Check ([bool]$both) "is:bounce finds the two notices and nothing else ($(Rows))"
    Shot $main 'bounce-3-list'
    Click $main $IDC_SEARCH_CLEAR
    [void](WaitFor { -not (Visible $main $IDC_SEARCH_BAR) } 10)
    # the messages of this step go, so the folders are as the steps after expect them
    foreach ($added in @((Find 'INBOX' "Subject: $([regex]::Escape($failedSubject))"), (Find 'INBOX' "Subject: $([regex]::Escape($delayedSubject))"))) {
        if ($added) { [void](Invoke-RestMethod -Method Delete "$rest/INBOX/messages/$($added.uid)") }
    }
    $sentCopy = Find 'Sent' "Subject: $bounced"
    if ($sentCopy) { [void](Invoke-RestMethod -Method Delete "$rest/Sent/messages/$($sentCopy.uid)") }
    Command $main $IDM_SYNC
    SelectFolder 0
    [void](WaitFor { $null -eq (& $rowOf $failedSubject) -and $null -eq (& $rowOf $delayedSubject) } 20)

    # ---- a one-time code ----

    Step 'a one-time code'
    # a code in the text of a message the provider says example.com signed, one in an OTP-Token header, one unsigned
    $kTestLink = 0x4C494E4B
    $codeMessage = {
        param([bool]$verdict, [string]$extra, [string]$subject, [string]$id, [string]$body)
        $head = if ($verdict) { "Authentication-Results: mx.inboxclassic.test; dkim=pass header.d=example.com`r`n" } else { '' }
        $head + $extra + "From: Example Accounts <no-reply@accounts.example.com>`r`nTo: testuser@inboxclassic.test`r`n" +
            "Subject: $subject`r`nDate: $($now.AddHours(-3).ToString('r'))`r`nMessage-ID: <$id@example.com>`r`n" +
            "MIME-Version: 1.0`r`nContent-Type: text/plain; charset=utf-8`r`n`r`n$body`r`n"
    }
    $codeText = { param($digits) "Hello,`r`n`r`nYour verification code is $digits.`r`n`r`nIt expires in 10 minutes. If you did not ask for it, ignore this email." }
    $codeSubjects = @('Your sign-in code', 'Sign in to Example', 'Your code, unsigned')
    AddMessage (& $codeMessage $true '' $codeSubjects[0] 'code-body' (& $codeText '482913')) @('\Seen')
    AddMessage (& $codeMessage $true "OTP-Token: `"917355`"; origin=`"https://login.example.com`"`r`n" $codeSubjects[1] 'code-header' 'Use the code at the top of this message to sign in.') @('\Seen')
    AddMessage (& $codeMessage $false '' $codeSubjects[2] 'code-unsigned' (& $codeText '771204')) @('\Seen')
    Command $main $IDM_SYNC
    SelectFolder 0
    $codesIn = WaitFor { if (@($codeSubjects | Where-Object { $null -ne (& $rowOf $_) }).Count -eq 3) { $true } } 30
    Check ([bool]$codesIn) 'three messages with codes are in the Inbox'
    # Copy on the card, as a click on it: the link followed, the code on the clipboard
    $copied = {
        param($subject)
        Set-Clipboard -Value 'nothing'
        SelectRow (& $rowOf $subject)
        [void](WaitFor { (WindowText $main) -match 'Inbox' } 5)
        Start-Sleep -Seconds 2
        [void][Native.Win]::SendText($main, $kTestLink, 'inboxclassic:copy-code')
        Start-Sleep -Milliseconds 500
        (Get-Clipboard -Raw)
    }
    $first = & $copied $codeSubjects[0]
    Check ($first -eq '482913') "Copy on the card of a signed message puts its code on the clipboard ($first)"
    Check ((StatusPart $mainStatus 0) -eq 'Copied the code') "and the status bar says so ($(StatusPart $mainStatus 0))"
    Shot $main 'otp-1-card'
    $second = & $copied $codeSubjects[1]
    Check ($second -eq '917355') "an OTP-Token header gives the code ($second)"
    $third = & $copied $codeSubjects[2]
    Check ($third -eq 'nothing') "an unsigned message has no card, so nothing is copied ($third)"
    foreach ($subject in $codeSubjects) {
        $added = Find 'INBOX' "Subject: $([regex]::Escape($subject))"
        if ($added) { [void](Invoke-RestMethod -Method Delete "$rest/INBOX/messages/$($added.uid)") }
    }
    Command $main $IDM_SYNC
    [void](WaitFor { @($codeSubjects | Where-Object { $null -ne (& $rowOf $_) }).Count -eq 0 } 20)

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

    Step 'an e-mail link'
    # Windows starts the default mail program with the link: the app already open for the store takes it over
    $link = 'mailto:gina@example.com?subject=From%20a%20link&body=Hello%20Gina%2C'
    $second = Start-Process -FilePath $Exe -ArgumentList ($arguments + @("`"$link`"")) -PassThru
    Check ($second.WaitForExit(15000)) 'a second start with a mailto: link hands it over and ends'
    $linked = WaitFor {
        $c = [Native.Win]::FindWindow('InboxClassicCompose', [NullString]::Value)
        if ($c -ne [IntPtr]::Zero -and (GetText $c $IDC_SUBJECT) -eq 'From a link') { $c }
    } 15
    Check ($null -ne $linked) 'the running app opens a new message from it'
    if ($linked) {
        Check ((GetText $linked $IDC_TO) -eq 'gina@example.com') "to the link's address ($(GetText $linked $IDC_TO))"
        Shot $linked 'write-18-mailto'
        [void][Native.Win]::PostMessage($linked, $WM_CLOSE, [IntPtr]::Zero, [IntPtr]::Zero)
        $ask = WaitWindow '#32770' 'Inbox Classic' 5
        if ($ask) { Click $ask 7 }
        [void](WaitFor { -not [Native.Win]::IsWindow($linked) } 10)
    }

    Step 'completing an address'
    Command $main $IDM_NEW_MAIL
    $compose = WaitCompose
    if ($compose) {
        $to = [Native.Win]::GetDlgItem($compose, $IDC_TO)
        foreach ($c in 'ann'.ToCharArray()) { [void][Native.Win]::PostMessage($to, 0x0102, [IntPtr][int]$c, [IntPtr]::Zero) }
        # the list under the field: a list box of the app's own, shown
        $appPid = [uint32]0
        [void][Native.Win]::GetWindowThreadProcessId($compose, [ref]$appPid)
        $completion = WaitFor {
            $w = [IntPtr]::Zero
            do {
                $w = [Native.Win]::FindWindowEx([IntPtr]::Zero, $w, 'ListBox', [NullString]::Value)
                $owner = [uint32]0
                if ($w -ne [IntPtr]::Zero) { [void][Native.Win]::GetWindowThreadProcessId($w, [ref]$owner) }
            } while ($w -ne [IntPtr]::Zero -and -not ($owner -eq $appPid -and [Native.Win]::IsWindowVisible($w)))
            if ($w -ne [IntPtr]::Zero) { $w }
        } 10
        Check ($null -ne $completion) 'typing in To lists the people it may be'
        Check ($completion -and (ListBoxCount $completion) -ge 1) 'with someone heard from'
        if ($completion) { Shot $compose 'write-17-complete' $completion }
        Key $to $VK_RETURN
        Check ([bool](WaitFor { (GetText $compose $IDC_TO) -eq 'Ann Example <ann@example.com>, ' } 5)) "Enter takes the first, with a comma for the next ($(GetText $compose $IDC_TO))"
        Check ($completion -and -not [Native.Win]::IsWindowVisible($completion)) 'and closes the list'
        [void][Native.Win]::PostMessage($compose, $WM_CLOSE, [IntPtr]::Zero, [IntPtr]::Zero)
        $ask = WaitWindow '#32770' 'Inbox Classic' 5
        if ($ask) { Click $ask 7 }
        [void](WaitFor { -not [Native.Win]::IsWindow($compose) } 10)
    }

    Step 'a signature'
    $IDC_ACCOUNT_SIGNATURE = 406
    Command $main $IDM_ACCOUNTS
    $accounts = WaitWindow 'InboxClassicAccounts' 'Accounts'
    Check ($null -ne $accounts) 'File > Accounts opens the accounts'
    if ($accounts) {
        # the first account is selected when the list opens
        Click $accounts $IDC_ACCOUNT_SIGNATURE
        $signature = WaitWindow 'InboxClassicSignature' $null 20
        Check ($null -ne $signature) 'Signature opens the signature editor of the account'
        if ($signature) {
            Check ((WindowText $signature) -match '^Signature: ') "titled with the account ($(WindowText $signature))"
            Check (TypeInEditor $signature 'Ann, signed by the UI test') 'the signature editor takes typing'
            Shot $signature 'signature-1-editor'
            Click $signature 1
            Check ([bool](WaitFor { -not [Native.Win]::IsWindow($signature) } 10)) 'OK saves it and closes the editor'
        }
        Click $accounts 404
        [void](WaitFor { -not [Native.Win]::IsWindow($accounts) } 10)
    }
    # a new message starts with it, under the line to write on
    Command $main $IDM_NEW_MAIL
    $compose = WaitCompose
    if ($compose) {
        SetText $compose $IDC_TO 'Fay <fay@example.com>'
        SetText $compose $IDC_SUBJECT 'Signed in the UI test'
        Check (TypeInEditor $compose 'Hello Fay.') 'a new message takes typing above the signature'
        Shot $compose 'signature-2-new'
        Command $compose $IDC_SEND
    }
    $signed = WaitFor { Find 'INBOX' 'Subject: Signed in the UI test' } 30
    $raw = if ($signed) { RawText $signed } else { '' }
    Check ($raw -match 'Ann, signed by the UI test') 'the message went with the signature'
    Check ($raw.IndexOf('Hello Fay') -ge 0 -and $raw.IndexOf('Hello Fay') -lt $raw.IndexOf('-- ') -and $raw.IndexOf('-- ') -lt $raw.IndexOf('Ann, signed by the UI test')) 'after what was written and the "-- " line'
    # a reply has it above the quote
    Command $main $IDM_SYNC
    SelectFolder 0
    [void](WaitFor { if ((Rows) -ge 1) { Rows } } 20)
    [void](WaitFor { $null -ne (Find 'INBOX' 'Subject: Signed in the UI test') } 10)
    # found with the search, as other messages of the test are newer
    $findBox = [Native.Win]::GetDlgItem([Native.Win]::GetDlgItem($main, 205), 204)
    [void][Native.Win]::SendMessage($findBox, $WM_SETTEXT, [IntPtr]::Zero, 'subject:"Signed in the UI test"')
    [void](WaitFor { (Rows) -eq 1 } 20)
    SelectRow 0
    Command $main $IDM_REPLY
    $compose = WaitCompose
    if ($compose) {
        Check (TypeInEditor $compose 'Thanks.') 'a reply takes typing'
        Command $compose $IDC_SEND
    }
    $reply = WaitFor { Find 'INBOX' 'Subject: Re: Signed in the UI test' } 30
    $raw = if ($reply) { RawText $reply } else { '' }
    [void][Native.Win]::SendMessage($findBox, $WM_SETTEXT, [IntPtr]::Zero, '')
    if ($compose -and [Native.Win]::IsWindow($compose)) {
        Shot $compose 'signature-3-reply-left'
        CloseCompose $compose
        $left = WaitWindow '#32770' $null 5
        if ($left) { Click $left 7 }
    }
    # in the text part, with its lines as they are (the HTML part may wrap them)
    $plain = ($raw -replace "=`r`n", '')
    $at = $plain.IndexOf('Ann, signed by the UI test'); $quoteAt = $plain.IndexOf('Original Message')
    Check ($at -ge 0 -and $quoteAt -ge 0 -and $at -lt $quoteAt) "a reply has the signature above the quote ($at, $quoteAt)"
    if (-not ($at -ge 0 -and $at -lt $quoteAt)) { Set-Content (Join-Path $out 'signature-reply.eml') $raw }

    Step 'the Address Book'
    # core/commands.toml and app/src/app.h, compose.cpp
    $IDM_ADDRESS_BOOK = 147; $IDM_ADD_SENDER_TO_BOOK = 148; $IDM_IMPORT_ADDRESS_BOOK = 149; $IDM_EXPORT_ADDRESS_BOOK = 150
    $IDC_BOOK_TREE = 700; $IDC_BOOK_LIST = 701; $IDC_BOOK_FIND = 702; $IDC_BOOK_TOOLBAR = 703
    $IDC_BOOK_NEW_CONTACT = 710; $IDC_BOOK_NEW_GROUP = 711; $IDC_BOOK_PROPERTIES = 712; $IDC_BOOK_DELETE = 713; $IDC_BOOK_WRITE_TO = 714
    $IDC_CONTACT_FIRST = 720; $IDC_CONTACT_LAST = 721; $IDC_CONTACT_ADDRESS = 725; $IDC_CONTACT_ADD = 726; $IDC_CONTACT_ADDRESSES = 727
    $IDC_GROUP_NAME = 750; $IDC_GROUP_MEMBERS = 751; $IDC_GROUP_SELECT = 752; $IDC_GROUP_ADDRESS = 754; $IDC_GROUP_ADD = 755
    $IDC_PICK_LIST = 771; $IDC_PICK_TO = 772; $IDC_PICK_TO_LIST = 780; $IDC_PICK_TO_BUTTON = 313
    $TVM_SELECTITEM_CARET = [IntPtr]9
    $mainStatus = [Native.Win]::FindWindowEx($main, [IntPtr]::Zero, 'msctls_statusbar32', [NullString]::Value)
    # the Name column of a list of the book, top to bottom
    function Names([IntPtr]$l) {
        $n = ListCount $l
        if ($n -eq 0) { return @() }
        @(0..($n - 1) | ForEach-Object { [Native.Win]::RemoteListText($l, $_, 0) })
    }
    Command $main $IDM_ADDRESS_BOOK
    $book = WaitShown 'InboxClassicAddressBook' 10
    Check ($null -ne $book) 'Tools > Address Book opens the Address Book'
    if ($book) {
        $bookList = [Native.Win]::GetDlgItem($book, $IDC_BOOK_LIST)
        $bookTree = [Native.Win]::GetDlgItem($book, $IDC_BOOK_TREE)
        $bookBar = [Native.Win]::GetDlgItem($book, $IDC_BOOK_TOOLBAR)
        # TB_GETBUTTONTEXTW of each button
        $buttons = @($IDC_BOOK_NEW_CONTACT, $IDC_BOOK_NEW_GROUP, $IDC_BOOK_PROPERTIES, $IDC_BOOK_DELETE, $IDC_BOOK_WRITE_TO) |
            ForEach-Object { [Native.Win]::RemoteText($bookBar, 0x044B, [IntPtr]$_) }
        Check (($buttons -join ', ') -eq 'New Contact, New Group, Properties, Delete, Write To') "with New Contact, New Group, Properties, Delete and Write To ($($buttons -join ', '))"
        Check ((ListCount $bookList) -eq 0) 'it starts empty'
        Check ((TreeTexts $bookTree) -contains 'All Contacts') "the groups start with All Contacts ($((TreeTexts $bookTree) -join ', '))"

        # a person with two addresses, the first the default
        Click $book $IDC_BOOK_NEW_CONTACT
        $contact = WaitShown 'InboxClassicContact' 10
        Check ($null -ne $contact) 'New Contact opens Contact Properties'
        if ($contact) {
            SetText $contact $IDC_CONTACT_FIRST 'Mary'
            SetText $contact $IDC_CONTACT_LAST 'Smith'
            # Click only posts the press: each address is in the list before the next is typed, or the first Add
            # would read the second address
            $addresses = [Native.Win]::GetDlgItem($contact, $IDC_CONTACT_ADDRESSES)
            SetText $contact $IDC_CONTACT_ADDRESS 'mary@example.com'
            Click $contact $IDC_CONTACT_ADD
            [void](WaitFor { (ListBoxCount $addresses) -eq 1 } 5)
            SetText $contact $IDC_CONTACT_ADDRESS 'mary.smith@work.example'
            Click $contact $IDC_CONTACT_ADD
            Check ([bool](WaitFor { (ListBoxCount $addresses) -eq 2 } 5)) 'it takes two addresses'
            Check ((ListBoxText $addresses 0) -eq 'mary@example.com (default)' -and (ListBoxText $addresses 1) -eq 'mary.smith@work.example') "the first the default ($(ListBoxText $addresses 0); $(ListBoxText $addresses 1))"
            Shot $contact 'contacts-2-person'
            Click $contact 1
            Check ([bool](WaitFor { -not [Native.Win]::IsWindow($contact) } 10)) 'OK saves the contact'
        }
        Check ([bool](WaitFor { (ListCount $bookList) -eq 1 -and [Native.Win]::RemoteListText($bookList, 0, 0) -eq 'Mary Smith' -and [Native.Win]::RemoteListText($bookList, 0, 1) -eq 'mary@example.com' } 10)) "the book lists her: Mary Smith, mary@example.com ($(Names $bookList))"
        Shot $book 'contacts-1-book'
        SetText $book $IDC_BOOK_FIND 'smi'
        Check ([bool](WaitFor { (ListCount $bookList) -eq 1 } 5)) 'the find box finds her by "smi"'
        SetText $book $IDC_BOOK_FIND 'zed'
        Check ([bool](WaitFor { (ListCount $bookList) -eq 0 } 5)) 'and lists no one for "zed"'
        SetText $book $IDC_BOOK_FIND ''
        [void](WaitFor { (ListCount $bookList) -eq 1 } 5)

        # a group of her and an address typed
        Click $book $IDC_BOOK_NEW_GROUP
        $group = WaitShown 'InboxClassicGroup' 10
        Check ($null -ne $group) 'New Group opens Group Properties'
        if ($group) {
            SetText $group $IDC_GROUP_NAME 'Team'
            Click $group $IDC_GROUP_SELECT
            $members = WaitShown 'InboxClassicPick' 10
            Check ($null -ne $members) 'Select Members opens the book'
            if ($members) {
                $pickList = [Native.Win]::GetDlgItem($members, $IDC_PICK_LIST)
                [void](WaitFor { (ListCount $pickList) -ge 1 } 5)
                Key $pickList $VK_HOME
                Start-Sleep -Milliseconds 300
                Click $members $IDC_PICK_TO
                [void](WaitFor { (ListBoxCount ([Native.Win]::GetDlgItem($members, $IDC_PICK_TO_LIST))) -eq 1 } 5)
                Click $members 1
                [void](WaitFor { -not [Native.Win]::IsWindow($members) } 10)
            }
            SetText $group $IDC_GROUP_ADDRESS 'dave@example.com'
            Click $group $IDC_GROUP_ADD
            $memberList = [Native.Win]::GetDlgItem($group, $IDC_GROUP_MEMBERS)
            Check ([bool](WaitFor { (ListBoxCount $memberList) -eq 2 } 5)) "with Mary Smith from Select Members and dave@example.com typed ($(ListBoxText $memberList 0); $(ListBoxText $memberList 1))"
            Shot $group 'contacts-3-group'
            Click $group 1
            Check ([bool](WaitFor { -not [Native.Win]::IsWindow($group) } 10)) 'OK saves the group'
        }
        Check ([bool](WaitFor { (TreeTexts $bookTree) -contains 'Team' } 5)) "it is listed on the left ($((TreeTexts $bookTree) -join ', '))"
        Check ([bool](WaitFor { (ListCount $bookList) -eq 2 } 5)) "with its two members ($(Names $bookList))"
        # back to everyone
        [void][Native.Win]::SendMessage($bookTree, $TVM_SELECTITEM, $TVM_SELECTITEM_CARET, [Native.Win]::SendMessage($bookTree, $TVM_GETNEXTITEM, [IntPtr]0, [IntPtr]::Zero))
        [void](WaitFor { (ListCount $bookList) -eq 1 } 5)
    }

    # the To button of a message: Select Recipients
    Command $main $IDM_NEW_MAIL
    $compose = WaitCompose
    if ($compose) {
        Click $compose $IDC_PICK_TO_BUTTON
        $pick = WaitShown 'InboxClassicPick' 10
        Check ($null -ne $pick) 'in a new message, To opens Select Recipients'
        if ($pick) {
            $pickList = [Native.Win]::GetDlgItem($pick, $IDC_PICK_LIST)
            [void](WaitFor { (ListCount $pickList) -ge 2 } 5)
            Check ((((Names $pickList) -join ', ')) -eq 'Team, Mary Smith') "it lists the group and the contact ($((Names $pickList) -join ', '))"
            Key $pickList $VK_HOME
            Start-Sleep -Milliseconds 300
            Click $pick $IDC_PICK_TO
            Key $pickList $VK_DOWN
            Start-Sleep -Milliseconds 300
            Click $pick $IDC_PICK_TO
            $toList = [Native.Win]::GetDlgItem($pick, $IDC_PICK_TO_LIST)
            Check ([bool](WaitFor { (ListBoxCount $toList) -eq 2 } 5)) "To -> puts the group and the contact in the message's recipients ($(ListBoxText $toList 0); $(ListBoxText $toList 1))"
            Shot $pick 'contacts-4-pick'
            Click $pick 1
            [void](WaitFor { -not [Native.Win]::IsWindow($pick) } 10)
        }
        Check ([bool](WaitFor { (GetText $compose $IDC_TO) -eq 'Mary Smith <mary@example.com>, dave@example.com' } 5)) "OK puts them in To, each address once ($(GetText $compose $IDC_TO))"
        # a group completes by its name, to its members
        Click $compose $IDC_SHOW_CC
        $cc = [Native.Win]::GetDlgItem($compose, $IDC_CC)
        foreach ($c in 'tea'.ToCharArray()) { [void][Native.Win]::PostMessage($cc, 0x0102, [IntPtr][int]$c, [IntPtr]::Zero) }
        $appPid = [uint32]0
        [void][Native.Win]::GetWindowThreadProcessId($compose, [ref]$appPid)
        $completion = WaitFor {
            $w = [IntPtr]::Zero
            do {
                $w = [Native.Win]::FindWindowEx([IntPtr]::Zero, $w, 'ListBox', [NullString]::Value)
                $owner = [uint32]0
                if ($w -ne [IntPtr]::Zero) { [void][Native.Win]::GetWindowThreadProcessId($w, [ref]$owner) }
            } while ($w -ne [IntPtr]::Zero -and -not ($owner -eq $appPid -and [Native.Win]::IsWindowVisible($w)))
            if ($w -ne [IntPtr]::Zero) { $w }
        } 10
        Check ($completion -and (ListBoxText $completion 0) -eq 'Team') "typing ""tea"" in Cc offers the group by its name ($(if ($completion) { ListBoxText $completion 0 }))"
        Key $cc $VK_RETURN
        Check ([bool](WaitFor { (GetText $compose $IDC_CC) -eq 'Mary Smith <mary@example.com>, dave@example.com, ' } 5)) "taking it puts its members in Cc ($(GetText $compose $IDC_CC))"
        [void][Native.Win]::PostMessage($compose, $WM_CLOSE, [IntPtr]::Zero, [IntPtr]::Zero)
        $ask = WaitWindow '#32770' 'Inbox Classic' 5
        if ($ask) { Click $ask 7 }
        Check ([bool](WaitFor { -not [Native.Win]::IsWindow($compose) } 10)) 'the message is closed without saving'
    }

    # the sender of a message into the book, once
    AddMessage ("From: Sender <sender@example.com>`r`nTo: testuser@inboxclassic.test`r`nSubject: Add me to the Address Book`r`n" +
        "Message-ID: <book-sender@example.com>`r`nDate: Thu, 9 Oct 2025 08:00:00 +0000`r`nMIME-Version: 1.0`r`n" +
        "Content-Type: text/html; charset=utf-8`r`n`r`n<p>Please keep my address.</p>`r`n")
    Command $main $IDM_SYNC
    SelectFolder 0
    $findBox = [Native.Win]::GetDlgItem([Native.Win]::GetDlgItem($main, 205), 204)
    [void](WaitFor {
        [void][Native.Win]::SendMessage($findBox, $WM_SETTEXT, [IntPtr]::Zero, 'subject:"Add me to the Address Book"')
        Start-Sleep -Milliseconds 800
        (Rows) -eq 1
    } 30)
    SelectRow 0
    $WM_CONTEXTMENU = 0x007B
    [void][Native.Win]::PostMessage($main, $WM_CONTEXTMENU, $list, [IntPtr](-1))
    $menu = WaitWindow '#32768' $null 10
    if ($menu) {
        $labels = [Native.Win]::MenuLabels([Native.Win]::SendMessage($menu, 0x01E1, [IntPtr]::Zero, [IntPtr]::Zero))
        Check ($labels -contains 'Add Sender to Address Book') "the message list's right-click menu has Add Sender to Address Book ($($labels -join ', '))"
        Key $menu $VK_ESCAPE
        [void](WaitFor { [Native.Win]::FindWindow('#32768', [NullString]::Value) -eq [IntPtr]::Zero } 5)
    }
    Command $main $IDM_ADD_SENDER_TO_BOOK
    Check ([bool](WaitFor { (StatusPart $mainStatus 0) -eq 'Sender was added to the Address Book.' } 10)) "Add Sender to Address Book adds Sender ($(StatusPart $mainStatus 0))"
    Command $main $IDM_ADD_SENDER_TO_BOOK
    Check ([bool](WaitFor { (StatusPart $mainStatus 0) -eq 'Sender is already in the Address Book.' } 10)) "and again says the sender is in it already ($(StatusPart $mainStatus 0))"
    [void][Native.Win]::SendMessage($findBox, $WM_SETTEXT, [IntPtr]::Zero, '')
    if ($book) {
        Check ([bool](WaitFor { (ListCount $bookList) -eq 2 } 5)) "without a second card ($((Names $bookList) -join ', '))"
        Check (@(Names $bookList | Where-Object { $_ -eq 'Sender' }).Count -eq 1) 'Sender is listed once'
    }

    # a vCard file of two contacts, one in the book already
    $vcf = Join-Path (Resolve-Path $Out) 'contacts-import.vcf'
    $cards = "BEGIN:VCARD`r`nVERSION:3.0`r`nFN:Mary Smith`r`nN:Smith;Mary;;;`r`nEMAIL:mary@example.com`r`nEND:VCARD`r`n" +
        "BEGIN:VCARD`r`nVERSION:3.0`r`nFN:John Doe`r`nN:Doe;John;;;`r`nEMAIL:john@example.org`r`nTEL;TYPE=CELL:+1 555 0100`r`nEND:VCARD`r`n"
    [IO.File]::WriteAllText($vcf, $cards, (New-Object Text.UTF8Encoding $false))
    Command $main $IDM_IMPORT_ADDRESS_BOOK
    Check (AnswerFileDialog 'Import Address Book' $vcf $null) 'File > Import Address Book asks for a file'
    Check ([bool](WaitFor { (StatusPart $mainStatus 0) -eq 'Added 1 contact, skipped 1 already in the Address Book.' } 10)) "it added 1 and skipped 1 ($(StatusPart $mainStatus 0))"
    if ($book) {
        Check ([bool](WaitFor { ((Names $bookList) -join ', ') -eq 'John Doe, Mary Smith, Sender' } 5)) "the book lists John Doe beside Mary Smith and Sender ($((Names $bookList) -join ', '))"
        Shot $book 'contacts-5-import'
    }
    $exported = Join-Path (Resolve-Path $Out) 'contacts-export.vcf'
    Remove-Item -Force -ErrorAction SilentlyContinue $exported
    Command $main $IDM_EXPORT_ADDRESS_BOOK
    Check (AnswerFileDialog 'Export Address Book' $exported $null 'Address Book*') 'File > Export Address Book asks where, as "Address Book"'
    Check ([bool](WaitFor { (StatusPart $mainStatus 0) -match '^3 contacts saved to ' } 10)) "it says how many it saved ($(StatusPart $mainStatus 0))"
    $vcards = if (Test-Path $exported) { Get-Content -Raw $exported } else { '' }
    Check ($vcards -match 'FN:Mary Smith' -and $vcards -match 'FN:John Doe' -and $vcards -match 'FN:Sender' -and $vcards -match 'mary.smith@work.example') 'the vCard file has Mary Smith (both addresses), John Doe and Sender'

    # Delete asks first
    if ($book) {
        Key $bookList $VK_HOME
        Start-Sleep -Milliseconds 300
        Key $bookList $VK_DELETE
        $ask = WaitWindow '#32770' 'Inbox Classic' 10
        Check ($ask -and (Statics $ask) -match 'Delete this contact from the Address Book\?') "Delete asks first ($(if ($ask) { Statics $ask }))"
        if ($ask) { Click $ask 6 }
        Check ([bool](WaitFor { ((Names $bookList) -join ', ') -eq 'Mary Smith, Sender' } 10)) "then removes the selected contact ($((Names $bookList) -join ', '))"
        [void][Native.Win]::PostMessage($book, $WM_CLOSE, [IntPtr]::Zero, [IntPtr]::Zero)
        Check ([bool](WaitFor { -not [Native.Win]::IsWindow($book) } 10)) 'the Address Book closes'
    }

    Step 'a Gmail address'
    Command $main $IDM_NEW_ACCOUNT
    $first = StartPage $true
    SetText $first 100 'Gmail Test'
    SetText $first 101 'inboxclassic.test@gmail.com'
    Click $first 1
    # the built-in Google client is off out of the box and no sign-in app is added yet: no browser sign-in to offer,
    # the app password way follows at once (Sign in with Google is offered further down, once it is turned on)
    $hint = WaitWindow '#32770' 'Add Mail Account' 40
    Check ($null -ne $hint) 'without it, Gmail wants an app password, and that is said'
    Check ([Native.Win]::FindWindow('InboxClassicAccountStart', 'Add Mail Account') -eq [IntPtr]::Zero) 'with Google turned off, a Gmail address goes to the app password way'
    if ($hint) {
        Shot $hint 'account-5-app-password'
        # No: not now to the instructions
        Click $hint 7
    }
    $servers = WaitFor {
        $f = [Native.Win]::FindWindow('InboxClassicForm', 'Add Mail Account')
        if ($f -ne [IntPtr]::Zero -and [Native.Win]::GetDlgItem($f, 110) -ne [IntPtr]::Zero) { $f }
    } 20
    Check ($servers -and (GetText $servers 105) -eq 'imap.gmail.com' -and (GetText $servers 108) -eq 'smtp.gmail.com') 'its servers were found'
    Check ($servers -and (GetText $servers 100) -eq 'Gmail') "the Account name starts as the provider's ($(if ($servers) { GetText $servers 100 }))"
    if ($servers) {
        Shot $servers 'account-6-gmail'
        Click $servers 2
        [void](WaitFor { -not [Native.Win]::IsWindow($servers) })
    }

    # ---- a wrong password ----

    Step 'a wrong password'
    # the second account's mail, on a server of its own, unread, dated a little ahead so it is the newest in the list
    # (over what the steps before added), around the first account's message of the next step
    foreach ($mail in @(
            @('Priya Shah <priya@work.example>', 'Contract renewal for next year', 'The renewal is ready to sign. Could you look it over before Friday?', 10),
            @('Tom Becker <tom@work.example>', 'Offsite agenda', 'Here is the agenda for the offsite. Add anything you want to talk about.', 8))) {
        $date = [DateTime]::UtcNow.AddMinutes($mail[3]).ToString('r')
        AddMessage "From: $($mail[0])`r`nTo: testuser2@inboxclassic.test`r`nSubject: $($mail[1])`r`nDate: $date`r`nMessage-ID: <$($mail[1] -replace ' ', '-')@work.example>`r`n`r`n$($mail[2])`r`n" @() 'INBOX' $rest2
    }
    Command $main $IDM_NEW_ACCOUNT
    AddAccount 'Work' 'testuser2' 'not-the-password' $false $true
    $logon = WaitWindow 'InboxClassicForm' 'Logon' 30
    Check ($null -ne $logon) 'a refused password is asked for again'
    if ($logon) {
        $status = [Native.Win]::FindWindowEx($main, [IntPtr]::Zero, 'msctls_statusbar32', [NullString]::Value)
        $status = WindowText $status
        Check ($status -match 'authentication') "the status bar says why ($status)"
        Shot $main 'trouble-1-password'
        # the right password, and the account syncs
        SetText $logon 100 'testpass2'
        Click $logon 1
        $synced = WaitFor {
            $work = [Native.Win]::SendMessage($tree, $TVM_GETNEXTITEM, [IntPtr]1, (FirstAccountItem))
            if ($work -ne [IntPtr]::Zero -and [Native.Win]::SendMessage($tree, $TVM_GETNEXTITEM, [IntPtr]4, $work) -ne [IntPtr]::Zero) { $work }
        } 30
        Check ($null -ne $synced) 'with the right password typed, the account syncs'
    }

    # ---- All Inboxes ----

    Step 'All Inboxes'
    # a new message for the first account too, so both have unread mail
    $date = [DateTime]::UtcNow.AddMinutes(9).ToString('r')
    AddMessage "From: Maria Lopez <maria@example.org>`r`nTo: testuser@inboxclassic.test`r`nSubject: Photos from the trip`r`nDate: $date`r`nMessage-ID: <trip-photos@example.org>`r`n`r`nThe photos from the trip are in the shared album.`r`n"
    Command $main $IDM_SYNC
    $top = [Native.Win]::SendMessage($tree, $TVM_GETNEXTITEM, [IntPtr]0, [IntPtr]::Zero)
    Check (([Native.Win]::RemoteTreeText($tree, $top)) -match '^All Inboxes') "All Inboxes is at the top of the tree, above the accounts ($([Native.Win]::RemoteTreeText($tree, $top)))"
    [void][Native.Win]::SendMessage($tree, $TVM_SELECTITEM, [IntPtr]9, $top)
    $expected = (Messages 'INBOX').Count + (Messages 'INBOX' $rest2).Count
    # grouped by conversation the rows are fewer (replies share a row): the messages the list has are counted
    $mainStatus = [Native.Win]::FindWindowEx($main, [IntPtr]::Zero, 'msctls_statusbar32', [NullString]::Value)
    Check ([bool](WaitFor { (Rows) -ge 1 -and (StatusPart $mainStatus 2) -match "^$expected message" } 20)) "it lists the mail of both accounts' Inboxes ($(Rows) rows, $(StatusPart $mainStatus 2) of $expected)"
    $places = @(0..([Math]::Min(4, (Rows)) - 1) | ForEach-Object { [Native.Win]::RemoteListText($list, $_, $COL_FOLDER) })
    Check (($places -contains 'Work') -and ($places -contains 'inboxclassic.test')) "newest first, the two accounts' messages among each other, the Account column naming each ($($places -join ', '))"
    Check ((StatusPart $mainStatus 2) -match "^$expected message") "the status bar counts both Inboxes ($(StatusPart $mainStatus 2))"
    SelectRow 0
    Shot $main 'all-inboxes-1-list'
    # its right-click menu, as a right-click on its row opens it: Mark All Read alone, no folder commands
    # topmost for the click, as SetForegroundWindow alone is refused to a background process on a shared desktop
    [void][Native.Win]::SetWindowPos($main, [IntPtr](-1), 0, 0, 0, 0, 0x13)
    [void][Native.Win]::SetForegroundWindow($main)
    Start-Sleep -Milliseconds 300
    $at = Middle ([Native.Win]::RemoteRect($tree, 0x1104, [IntPtr]1, $top.ToInt64()))
    foreach ($button in @(0, 0x0008, 0x0010)) { [Native.Win]::Mouse($at[0], $at[1], $button) }
    $menu = WaitWindow '#32768' $null 10
    [void][Native.Win]::SetWindowPos($main, [IntPtr](-2), 0, 0, 0, 0, 0x13)
    Check ($null -ne $menu) 'All Inboxes has a right-click menu'
    if ($menu) {
        $labels = @([Native.Win]::MenuLabels([Native.Win]::SendMessage($menu, 0x01E1, [IntPtr]::Zero, [IntPtr]::Zero)))
        Check ($labels.Count -eq 1 -and $labels[0] -eq 'Mark All Read') "with Mark All Read alone ($($labels -join ', '))"
        Shot $main 'all-inboxes-2-menu' $menu
        Key $menu $VK_ESCAPE
        [void](WaitFor { [Native.Win]::FindWindow('#32768', [NullString]::Value) -eq [IntPtr]::Zero } 5)
    }
    SelectRow ([array]::IndexOf($places, 'Work'))
    Command $main $IDM_REPLY
    $compose = WaitCompose
    Check ($null -ne $compose) 'Reply opens a compose window'
    if ($compose) {
        $from = GetText $compose $IDC_FROM
        Check ($from -eq 'Work <testuser2@inboxclassic.test>') "a reply goes from the account of the message ($from)"
        CloseCompose $compose
    }
    Command $main $IDM_MARK_ALL_READ
    $unreadOn = { param($server) @(Messages 'INBOX' $server | Where-Object { $_.flags -notcontains '\Seen' }).Count }
    Check ([bool](WaitFor { (& $unreadOn $rest) -eq 0 -and (& $unreadOn $rest2) -eq 0 } 20)) "Mark All Read marks both Inboxes read on the servers ($(& $unreadOn $rest) and $(& $unreadOn $rest2) unread)"

    Step 'moving between accounts'
    $IDM_COPY = 136
    $across = 'Across the accounts'; $copied = 'Copied across'; $dragged = 'Dragged across'
    foreach ($pair in @(@($across, 12), @($copied, 11), @($dragged, 10))) {
        $date = [DateTime]::UtcNow.AddMinutes($pair[1]).ToString('r')
        AddMessage "From: Sam Lee <sam@example.org>`r`nTo: testuser@inboxclassic.test`r`nSubject: $($pair[0])`r`nDate: $date`r`nMessage-ID: <$($pair[0] -replace ' ', '-')@example.org>`r`n`r`nMoved between the accounts in the UI test.`r`n" @('\Flagged')
    }
    Command $main $IDM_SYNC
    SelectFolder 0
    [void](WaitFor { if ((Rows) -ge 3 -and [Native.Win]::RemoteListText($list, 0, $COL_SUBJECT) -eq $across) { Rows } } 30)
    SelectRow 0
    Command $main $IDM_MOVE
    $move = WaitPicker 'Move Message'
    Check ($null -ne $move) 'Move to Folder opens'
    if ($move) {
        $pickerTree = [Native.Win]::GetDlgItem($move, 102)
        $texts = @(TreeTexts $pickerTree)
        Check (($texts -contains 'inboxclassic.test') -and ($texts -contains 'Work') -and [Native.Win]::GetDlgItem($move, 101) -ne [IntPtr]::Zero) "Move to Folder shows the folders of both accounts in a tree, with a filter box ($($texts -join ', '))"
        $current = TreeRow $pickerTree 'inboxclassic.test' 'Inbox'
        [void][Native.Win]::SendMessage($pickerTree, $TVM_SELECTITEM, [IntPtr]9, $current)
        $ok = [Native.Win]::GetDlgItem($move, 1)
        Check (([Native.Win]::RemoteTreeText($pickerTree, $current)) -eq 'Inbox (current)' -and -not [Native.Win]::IsWindowEnabled($ok)) 'the folder the message is in is shown but can not be chosen'
        Check ((WindowText $ok) -eq '&Move') "the button says Move ($(WindowText $ok))"
        SetText $move 101 'arch'
        $narrowed = @(TreeTexts $pickerTree)
        $others = @($narrowed | Where-Object { $_ -notmatch 'Archive' -and $_ -notin @('Recent', 'inboxclassic.test', 'Work') })
        Check ($narrowed.Count -ge 2 -and $others.Count -eq 0) "typing in the filter narrows the tree to the folders that match ($($narrowed -join ', '))"
        SetText $move 101 ''
        Check (PickIn $move 'Work' 'Archive') "the second account's Archive can be chosen"
        Shot $move 'move-1-dialog'
        $listed = Rows
        Click $move 1
        Check ([bool](WaitFor { (Rows) -eq $listed - 1 } 10)) 'a message of the first account moved to the second account''s Archive leaves the list at once'
        Check ((StatusPart $mainStatus 0) -match '^Mov(ing|ed) 1 ') "the status bar says how far the move is ($(StatusPart $mainStatus 0))"
        Check ([bool](WaitFor { (StatusPart $mainStatus 0) -eq 'Moved 1 message to Archive' } 30)) "and what was done once it is there ($(StatusPart $mainStatus 0))"
    }
    $there = WaitFor { (Messages 'Archive' $rest2) | Where-Object { (RawText $_) -match "Subject: $across" } | Select-Object -First 1 } 30
    Check ($null -ne $there -and $there.flags -contains '\Flagged') "it is in the second account's Archive on its server, with its flags ($($there.flags -join ' '))"
    Check ([bool](WaitFor { -not (Find 'INBOX' "Subject: $across") } 20)) "and gone from the first account's server"
    # the second account's Archive in the main tree, with the message in it
    $workArchive = TreeRow $tree 'Work' 'Archive'
    [void][Native.Win]::SendMessage($tree, $TVM_SELECTITEM, [IntPtr]9, $workArchive)
    [void](WaitFor { if ((Rows) -ge 1 -and [Native.Win]::RemoteListText($list, 0, $COL_SUBJECT) -eq $across) { Rows } } 20)
    SelectRow 0
    Shot $main 'move-2-accounts'
    SelectFolder 0
    Command $main $IDM_UNDO
    Check ([bool](WaitFor { $null -ne (Find 'INBOX' "Subject: $across") } 30)) 'Edit > Undo Move brings it back to the first account'
    Check ([bool](WaitFor { -not ((Messages 'Archive' $rest2) | Where-Object { (RawText $_) -match "Subject: $across" }) } 20)) 'and out of the second account''s Archive'
    # Copy to Folder: the second account's Archive is under Recent now
    [void](WaitFor { if ((Rows) -ge 3 -and [Native.Win]::RemoteListText($list, 1, $COL_SUBJECT) -eq $copied) { Rows } } 30)
    SelectRow 1
    Command $main $IDM_COPY
    $copy = WaitPicker 'Copy Message'
    Check ($null -ne $copy) 'Copy to Folder opens'
    if ($copy) {
        $copyTree = [Native.Win]::GetDlgItem($copy, 102)
        $recent = TreeRow $copyTree 'Recent' 'Archive (Work)'
        Check ($recent -ne [IntPtr]::Zero) "the next Move to Folder offers Archive of the second account under Recent ($((TreeTexts $copyTree) -join ', '))"
        Check ((WindowText ([Native.Win]::GetDlgItem($copy, 1))) -eq '&Copy') 'the button says Copy'
        [void](PickIn $copy 'Work' 'Archive')
        Click $copy 1
    }
    Check ($null -ne (WaitFor { (Messages 'Archive' $rest2) | Where-Object { (RawText $_) -match "Subject: $copied" } | Select-Object -First 1 } 30)) "Copy to Folder copies a message to the second account's Archive"
    Check ($null -ne (Find 'INBOX' "Subject: $copied")) 'and keeps it in the Inbox'
    # dragged onto the second account's Archive in the folder tree
    SelectFolder 0
    [void](WaitFor { if ((Rows) -ge 3 -and [Native.Win]::RemoteListText($list, 2, $COL_SUBJECT) -eq $dragged) { Rows } } 30)
    SelectRow 2
    [void][Native.Win]::SetForegroundWindow($main)
    $workArchive = TreeRow $tree 'Work' 'Archive'
    [void][Native.Win]::SendMessage($tree, 0x1114, [IntPtr]0, $workArchive)
    $row = [Native.Win]::RemoteRect($list, 0x100E, [IntPtr]2, 0)
    $target = Middle ([Native.Win]::RemoteRect($tree, 0x1104, [IntPtr]1, $workArchive.ToInt64()))
    [Native.Win]::MouseDragTo($row.Left + 120, [int](($row.Top + $row.Bottom) / 2), $target[0], $target[1])
    [Native.Win]::Mouse($target[0], $target[1], 0x0004)
    Check ($null -ne (WaitFor { (Messages 'Archive' $rest2) | Where-Object { (RawText $_) -match "Subject: $dragged" } | Select-Object -First 1 } 30)) 'a message dragged onto a folder of the second account is moved there'
    Check ([bool](WaitFor { -not (Find 'INBOX' "Subject: $dragged") } 20)) 'and out of the first account'

    # ---- All Inboxes by account ----

    Step 'All Inboxes by account'
    # the account row's menu (app.h)
    $IDM_ACCOUNT_SYNC = 910; $IDM_ACCOUNT_MARK_ALL_READ = 911; $IDM_ACCOUNT_PROPERTIES = 912
    # unread mail in both accounts' Inboxes again, and in the first account's Archive for its Mark All Read
    $date = [DateTime]::UtcNow.AddMinutes(14).ToString('r')
    AddMessage "From: Priya Shah <priya@work.example>`r`nTo: testuser2@inboxclassic.test`r`nSubject: Budget for the next quarter`r`nDate: $date`r`nMessage-ID: <budget-next-quarter@work.example>`r`n`r`nThe budget is ready for a look.`r`n" @() 'INBOX' $rest2
    AddMessage "From: Maria Lopez <maria@example.org>`r`nTo: testuser@inboxclassic.test`r`nSubject: Dinner on Friday`r`nDate: $date`r`nMessage-ID: <dinner-friday@example.org>`r`n`r`nAre you free on Friday?`r`n"
    AddMessage "From: Maria Lopez <maria@example.org>`r`nTo: testuser@inboxclassic.test`r`nSubject: Kept for later`r`nDate: $date`r`nMessage-ID: <kept-for-later@example.org>`r`n`r`nUnread in the Archive.`r`n" @() 'Archive'
    Command $main $IDM_SYNC
    $top = [Native.Win]::SendMessage($tree, $TVM_GETNEXTITEM, [IntPtr]0, [IntPtr]::Zero)
    # the rows under All Inboxes, top to bottom (the tree's first row read again: a change of the accounts builds it anew)
    function AllInboxesRows {
        $rows = @()
        $first = [Native.Win]::SendMessage($tree, $TVM_GETNEXTITEM, [IntPtr]0, [IntPtr]::Zero)
        $item = [Native.Win]::SendMessage($tree, $TVM_GETNEXTITEM, [IntPtr]4, $first)
        while ($item -ne [IntPtr]::Zero) {
            $rows += $item
            $item = [Native.Win]::SendMessage($tree, $TVM_GETNEXTITEM, [IntPtr]1, $item)
        }
        $rows
    }
    # an account's own row at the top level, by its name
    function AccountRow([string]$name) {
        $item = [Native.Win]::SendMessage($tree, $TVM_GETNEXTITEM, [IntPtr]0, [IntPtr]::Zero)
        while ($item -ne [IntPtr]::Zero) {
            if ((([Native.Win]::RemoteTreeText($tree, $item)) -replace ' \(\d+\)$', '') -eq $name) { return $item }
            $item = [Native.Win]::SendMessage($tree, $TVM_GETNEXTITEM, [IntPtr]1, $item)
        }
        [IntPtr]::Zero
    }
    # a row's name with the unread count the server has for that Inbox
    $counted = { param($name, $server) $n = & $unreadOn $server; if ($n -gt 0) { "$name ($n)" } else { $name } }
    $rowTexts = { @(AllInboxesRows | ForEach-Object { [Native.Win]::RemoteTreeText($tree, $_) }) }
    $named = [bool](WaitFor {
            $texts = & $rowTexts
            $texts.Count -eq 2 -and $texts[0] -eq (& $counted 'inboxclassic.test' $rest) -and $texts[1] -eq (& $counted 'Work' $rest2) -and (& $unreadOn $rest2) -gt 0
        } 30)
    Check $named "All Inboxes has a row for each account, in their order, named as the account with its Inbox's unread count ($((& $rowTexts) -join ', '))"
    Check (([Native.Win]::RemoteTreeText($tree, $top)) -eq 'All Inboxes') "open, All Inboxes shows no count of its own ($([Native.Win]::RemoteTreeText($tree, $top)))"
    $workInbox = @(AllInboxesRows)[1]
    [void][Native.Win]::SendMessage($tree, $TVM_SELECTITEM, [IntPtr]9, $workInbox)
    $workCount = (Messages 'INBOX' $rest2).Count
    $alone = [bool](WaitFor { (StatusPart $mainStatus 2) -match "^$workCount message" -and @(SubjectRows 'Budget for the next quarter').Count -eq 1 } 20)
    Check ($alone -and @(SubjectRows 'Dinner on Friday').Count -eq 0) "the second account's row lists its Inbox alone, not the first account's message ($(StatusPart $mainStatus 2) of $workCount)"
    Check ((& $folderBar) -eq ' Inbox - Work' -and (WindowText $main) -eq 'Inbox - Work - Inbox Classic') "the folder bar and the title name the Inbox and the account ($(& $folderBar); $(WindowText $main))"
    # no message selected, so the second account's mail stays unread for Mark All Read below
    Shot $main 'all-inboxes-3-accounts'
    [void][Native.Win]::SendMessage($tree, $TVM_SELECTITEM, [IntPtr]9, $top)
    $both = (Messages 'INBOX').Count + (Messages 'INBOX' $rest2).Count
    Check ([bool](WaitFor { (StatusPart $mainStatus 2) -match "^$both message" } 20)) "All Inboxes again lists both accounts' Inboxes ($(StatusPart $mainStatus 2) of $both)"
    # the second account's Properties, from its row: the Account name first, filled with its name
    [void][Native.Win]::SendMessage($tree, $TVM_SELECTITEM, [IntPtr]9, (AccountRow 'Work'))
    Command $main $IDM_ACCOUNT_PROPERTIES
    $properties = WaitFor {
        $f = PropertiesForm
        if ($f -ne [IntPtr]::Zero -and [Native.Win]::GetDlgItem($f, 110) -ne [IntPtr]::Zero) { $f }
    } 10
    Check ($properties -and (GetText $properties 100) -eq 'Work' -and (GetText $properties 102) -eq 'testuser2@inboxclassic.test') "the account's Properties opens from its row, the Account name filled with its name ($(if ($properties) { GetText $properties 100 }))"
    if ($properties) {
        SetText $properties 100 'Second'
        Click $properties 1
        [void](WaitFor { -not [Native.Win]::IsWindow($properties) } 10)
    }
    $renamed = [bool](WaitFor { (AccountRow 'Second') -ne [IntPtr]::Zero -and @(& $rowTexts)[-1] -match '^Second( \(\d+\))?$' } 20)
    Check $renamed "set to Second, the account's heading and its row under All Inboxes say Second ($((& $rowTexts) -join ', '))"
    # the first account's right-click menu, as a right-click on its row opens it
    $alex = AccountRow 'inboxclassic.test'
    [void][Native.Win]::SetWindowPos($main, [IntPtr](-1), 0, 0, 0, 0, 0x13)
    [void][Native.Win]::SetForegroundWindow($main)
    Start-Sleep -Milliseconds 300
    $at = Middle ([Native.Win]::RemoteRect($tree, 0x1104, [IntPtr]1, $alex.ToInt64()))
    foreach ($button in @(0, 0x0008, 0x0010)) { [Native.Win]::Mouse($at[0], $at[1], $button) }
    $menu = WaitWindow '#32768' $null 10
    [void][Native.Win]::SetWindowPos($main, [IntPtr](-2), 0, 0, 0, 0, 0x13)
    Check ($null -ne $menu) 'an account has a right-click menu'
    if ($menu) {
        $hmenu = [Native.Win]::SendMessage($menu, 0x01E1, [IntPtr]::Zero, [IntPtr]::Zero)
        $labels = @([Native.Win]::MenuLabels($hmenu))
        Check (($labels -join '|') -eq 'Send and Receive|Mark All Read||New Folder...||Properties...') "with Send and Receive, Mark All Read, New Folder and Properties ($($labels -join ', '))"
        Check ((([Native.Win]::GetMenuState($hmenu, $IDM_ACCOUNT_MARK_ALL_READ, 0) -band 0x3) -eq 0)) 'Mark All Read is on while the account has unread mail'
        Shot $main 'account-menu' $menu
        Key $menu $VK_ESCAPE
        [void](WaitFor { [Native.Win]::FindWindow('#32768', [NullString]::Value) -eq [IntPtr]::Zero } 5)
    }
    # the menu is for the row it was opened on, which stays selected: its commands
    Check ((& $folderBar) -eq ' inboxclassic.test') "the right-click selected the account ($(& $folderBar))"
    $archiveUnread = { @(Messages 'Archive' | Where-Object { $_.flags -notcontains '\Seen' }).Count }
    $secondUnread = & $unreadOn $rest2
    Command $main $IDM_ACCOUNT_MARK_ALL_READ
    Check ([bool](WaitFor { (& $unreadOn $rest) -eq 0 -and (& $archiveUnread) -eq 0 } 20)) "its Mark All Read marks every folder of the first account read on the server ($(& $unreadOn $rest) in the Inbox, $(& $archiveUnread) in Archive)"
    Check ((& $unreadOn $rest2) -eq $secondUnread -and $secondUnread -gt 0) "the second account's mail stays unread ($(& $unreadOn $rest2))"
    Command $main $IDM_ACCOUNT_PROPERTIES
    $properties = WaitFor {
        $f = PropertiesForm
        if ($f -ne [IntPtr]::Zero -and [Native.Win]::GetDlgItem($f, 110) -ne [IntPtr]::Zero) { $f }
    } 10
    Check ($properties -and (GetText $properties 102) -eq 'testuser@inboxclassic.test') "its Properties opens that account's Properties ($(if ($properties) { GetText $properties 102 }))"
    if ($properties) {
        Click $properties 2
        [void](WaitFor { -not [Native.Win]::IsWindow($properties) } 10)
    }
    Command $main $IDM_ACCOUNT_SYNC

    # ---- accounts ----

    Step 'accounts'
    Command $main $IDM_ACCOUNTS
    $accounts = WaitWindow 'InboxClassicAccounts' 'Accounts'
    Check ($null -ne $accounts) 'File > Accounts lists the accounts'
    if ($accounts) {
        $accountList = [Native.Win]::GetDlgItem($accounts, 400)
        Check ((ListCount $accountList) -eq 2) 'both accounts are listed'
        Shot $accounts 'accounts-1-list'
        # Properties of the first: a new display name
        # the first account is selected when the list opens, and stays so after a change
        Click $accounts 402
        $properties = WaitFor {
            $f = PropertiesForm
            if ($f -ne [IntPtr]::Zero -and [Native.Win]::GetDlgItem($f, 110) -ne [IntPtr]::Zero) { $f }
        }
        Check ($null -ne $properties) 'Properties shows the settings'
        if ($properties) {
            Check ((GetText $properties 106) -eq "$($ports.imap)") 'with the IMAP port as it was saved'
            SetText $properties 101 'Alex Morgan Renamed'
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
            $f = PropertiesForm
            if ($f -ne [IntPtr]::Zero -and [Native.Win]::GetDlgItem($f, 110) -ne [IntPtr]::Zero) { $f }
        }
        Check ($again -and (GetText $again 101) -eq 'Alex Morgan Renamed') 'the new name is saved'
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
        Check ([bool](WaitFor { (ListCount $accountList) -eq 1 })) 'and removes it'
        Click $accounts 404
        [void](WaitFor { -not [Native.Win]::IsWindow($accounts) })
        $after = WaitFor { $n = [int][Native.Win]::SendMessage($tree, $TVM_GETCOUNT, [IntPtr]::Zero, [IntPtr]::Zero); if ($n -lt $before) { $n } }
        Check ($null -ne $after) "the account leaves the tree ($before items before)"
        $top = [Native.Win]::SendMessage($tree, $TVM_GETNEXTITEM, [IntPtr]0, [IntPtr]::Zero)
        Check (([Native.Win]::RemoteTreeText($tree, $top)) -notmatch '^All Inboxes') 'All Inboxes goes with the second account'
        Shot $main 'accounts-3-after'
    }

    # ---- sign-in apps: an OAuth client of the user's, against ImapKit's OpenID Connect provider ----

    Step 'sign-in apps'
    $LVM_GETITEMSTATE = 0x102C
    # whether the check box of a row is checked: its state image, 1 unchecked, 2 checked
    function Checked([IntPtr]$list, [int]$row) {
        (([int][Native.Win]::SendMessage($list, $LVM_GETITEMSTATE, [IntPtr]$row, [IntPtr]0xF000)) -shr 12) -eq 2
    }
    # a row selected with the keys, from the first
    function KeyToRow([IntPtr]$list, [int]$row) {
        Key $list $VK_HOME
        for ($i = 0; $i -lt $row; $i++) { Key $list $VK_DOWN }
        # once the list has it selected (LVM_GETNEXTITEM, LVNI_SELECTED): the buttons act on the selected row
        [void](WaitFor { [int][Native.Win]::SendMessage($list, 0x100C, [IntPtr](-1), [IntPtr]2) -eq $row } 5)
        Start-Sleep -Milliseconds 200
    }
    function OpenSignInApps {
        Command $main $IDM_ACCOUNTS
        $accounts = WaitWindow 'InboxClassicAccounts' 'Accounts'
        if (-not $accounts) { return $null }
        Click $accounts 405
        $apps = WaitWindow 'InboxClassicSignInApps' 'Sign-in Apps'
        return @($accounts, $apps)
    }
    function CloseSignInApps($windows) {
        Click $windows[1] 705
        [void](WaitFor { -not [Native.Win]::IsWindow($windows[1]) })
        Click $windows[0] 404
        [void](WaitFor { -not [Native.Win]::IsWindow($windows[0]) })
    }

    $windows = OpenSignInApps
    Check ($null -ne $windows -and $windows[1]) 'File > Accounts > Sign-in Apps opens the sign-in apps'
    if ($windows -and $windows[1]) {
        $apps = $windows[1]
        $appList = [Native.Win]::GetDlgItem($apps, 700)
        Check ((ListCount $appList) -eq 2) 'the built-in Microsoft and Google clients are listed'
        Check ((Checked $appList 0) -and -not (Checked $appList 1)) 'Microsoft is on and Google off out of the box'
        Check (-not [Native.Win]::IsWindowEnabled([Native.Win]::GetDlgItem($apps, 702)) -and -not [Native.Win]::IsWindowEnabled([Native.Win]::GetDlgItem($apps, 703))) 'a built-in client can not be edited or removed'
        Check ((WindowText ([Native.Win]::GetDlgItem($apps, 704))) -match 'built in') 'a built-in client says what it is'
        Shot $apps 'signin-1-apps'

        Click $apps 701
        $editor = WaitWindow 'InboxClassicSignInApp' 'Add Sign-in App'
        Check ($null -ne $editor) 'Add opens the sign-in app editor'
        if ($editor) {
            # a preset fills in everything but the client
            Click $editor 600
            Check ([bool](WaitFor { (GetText $editor 611) -eq 'https://accounts.google.com' } 5)) 'Fill in for Google fills in its issuer'
            Check ((GetText $editor 617) -eq 'imap.gmail.com' -and (GetText $editor 624) -eq 'http://127.0.0.1') 'its servers, and the redirect URI to register'
            Shot $editor 'signin-2-google-preset'
            SetText $editor 610 'ImapKit'
            SetText $editor 611 $ports.oauth
            Check ([bool](WaitFor { (GetText $editor 624) -eq 'http://localhost' } 5)) 'the redirect URI follows the issuer'
            SetText $editor 613 'imapkit-approve'
            SetText $editor 616 'openid email profile offline_access mail'
            SetText $editor 617 '127.0.0.1'
            SetText $editor 618 "$($ports.imaps)"
            [void][Native.Win]::SendMessage([Native.Win]::GetDlgItem($editor, 619), $CB_SETCURSEL, [IntPtr]0, [IntPtr]::Zero)
            SetText $editor 620 '127.0.0.1'
            SetText $editor 621 "$($ports.smtp)"
            [void][Native.Win]::SendMessage([Native.Win]::GetDlgItem($editor, 622), $CB_SETCURSEL, [IntPtr]1, [IntPtr]::Zero)
            Click $editor 612
            $found = WaitWindow '#32770' 'Sign-in App' 20
            Check ($found -and (Statics $found) -match 'can be used') "Check reads the issuer's discovery document"
            if ($found) {
                Shot $found 'signin-3-check'
                Click $found 2
                [void](WaitFor { -not [Native.Win]::IsWindow($found) })
            }
            Shot $editor 'signin-4-editor'
            Click $editor 1
            Check ([bool](WaitFor { -not [Native.Win]::IsWindow($editor) } 20)) 'OK saves the sign-in app'
        }
        Check ([bool](WaitFor { (ListCount $appList) -eq 3 } 5) -and (Checked $appList 2)) 'it is listed, turned on'
        Shot $apps 'signin-5-apps-added'
        CloseSignInApps $windows
    }

    # the first page: Google's button faded with the reason, More sign-in options with the app
    Command $main $IDM_NEW_ACCOUNT
    $first = StartPage $true
    if ($first) {
        $google = [Native.Win]::GetDlgItem($first, 120)
        Check ($google -ne [IntPtr]::Zero -and -not [Native.Win]::IsWindowEnabled($google)) 'Sign in with Google is shown turned off'
        Check ([Native.Win]::IsWindowEnabled([Native.Win]::GetDlgItem($first, 121))) 'Sign in with Microsoft works'
        Check ((Statics $first) -match 'Turned off on this computer') 'the reason is under it, without hovering'
        Shot $first 'signin-6-first-page'
        Click $first 123
        $why = WaitWindow '#32770' 'Add Mail Account' 10
        Check ($why -and (Statics $why) -match 'test users') 'Why? says why it is off'
        if ($why) {
            Shot $why 'signin-7-why'
            Click $why 2
            [void](WaitFor { -not [Native.Win]::IsWindow($why) })
        }
        # the address typed goes to the provider as the account to sign in to
        SetText $first 101 'alice@example.com'
        Click $first 122
        $menu = WaitWindow '#32768' $null 10
        Check ($null -ne $menu) 'More sign-in options opens a menu'
        if ($menu) {
            $hmenu = [Native.Win]::SendMessage($menu, 0x01E1, [IntPtr]::Zero, [IntPtr]::Zero)
            Check ([Native.Win]::GetMenuItemCount($hmenu) -eq 3) 'with the sign-in app, a separator and Add a sign-in app'
            Shot $first 'signin-8-more' $menu
            Key $menu $VK_DOWN
            Key $menu $VK_RETURN
        }
        # the app writes the page instead of opening the browser; opened here, ImapKit approves and redirects back
        $page = WaitFor { if (Test-Path $signInPage) { Get-Content -Raw $signInPage } } 20
        Check ($page -and $page.StartsWith("$($ports.oauth)/authorize?") -and $page -match 'login_hint=alice%40example.com') "signing in opens the sign-in app's page for the address typed"
        if ($page) {
            $waiting = WaitWindow 'InboxClassicWait' $null 5
            if ($waiting) { Shot $waiting 'signin-9-waiting' }
            $beforeTree = [int][Native.Win]::SendMessage($tree, $TVM_GETCOUNT, [IntPtr]::Zero, [IntPtr]::Zero)
            $answer = Invoke-WebRequest -UseBasicParsing $page.Trim()
            Check ($answer.Content -match 'You are signed in') 'the provider sends the browser back to the app, which says it is signed in'
            Remove-Item -Force $signInPage
            $grown = WaitFor { $n = [int][Native.Win]::SendMessage($tree, $TVM_GETCOUNT, [IntPtr]::Zero, [IntPtr]::Zero); if ($n -ge $beforeTree + 6) { $n } } 40
            Check ($null -ne $grown) 'the account signed in to is added, and its folders sync with the token'
            Shot $main 'signin-10-added'
        }
    }

    $windows = OpenSignInApps
    if ($windows -and $windows[1]) {
        $apps = $windows[1]
        $appList = [Native.Win]::GetDlgItem($apps, 700)
        # removing it is refused while the account uses it
        KeyToRow $appList 2
        [void](WaitFor { [Native.Win]::IsWindowEnabled([Native.Win]::GetDlgItem($apps, 703)) } 5)
        Click $apps 703
        $sure = WaitWindow '#32770' 'Remove Sign-in App' 10
        if ($sure) { Click $sure 6 }
        $refused = WaitFor {
            $box = [Native.Win]::FindWindow('#32770', 'Remove Sign-in App')
            if ($box -ne [IntPtr]::Zero -and $box -ne $sure -and (Statics $box) -match 'alice@example.com') { $box }
        } 10
        Check ($null -ne $refused) 'a sign-in app an account uses is not removed, naming the account'
        if ($refused) {
            Shot $refused 'signin-11-in-use'
            Click $refused 2
            [void](WaitFor { -not [Native.Win]::IsWindow($refused) })
        }
        # the app off, Google on: Space on a row turns it on or off (each waited for, the rows are filled again after)
        Key $appList $VK_SPACE
        $off = WaitFor { -not (Checked $appList 2) } 5
        Start-Sleep -Milliseconds 500
        KeyToRow $appList 1
        Key $appList $VK_SPACE
        Check ([bool]$off -and [bool](WaitFor { Checked $appList 1 } 5) -and -not (Checked $appList 2)) 'Google turned on, the sign-in app off'
        Shot $apps 'signin-12-toggled'
        CloseSignInApps $windows
    }

    # Properties of the account names its sign-in app
    Command $main $IDM_ACCOUNTS
    $accounts = WaitWindow 'InboxClassicAccounts' 'Accounts'
    if ($accounts) {
        # the Properties of the account signed in to: each row's tried, wherever it is in the list
        # once the window has its list, and the list its rows (the window is there a moment before them)
        $count = WaitFor {
            $accountList = [Native.Win]::GetDlgItem($accounts, 400)
            $n = ListCount $accountList
            if ($n -ge 2) { $n }
        } 10
        $accountList = [Native.Win]::GetDlgItem($accounts, 400)
        $count = [int]$count
        $said = @()
        $found = $null
        for ($row = 0; $row -lt $count -and -not $found; $row++) {
            KeyToRow $accountList $row
            Click $accounts 402
            $properties = WaitFor { $f = PropertiesForm; if ($f -ne [IntPtr]::Zero) { $f } }
            if (-not $properties) { continue }
            if (WaitFor { (Statics $properties) -match 'Sign-in app: ImapKit' } 3) {
                $found = $properties
                Shot $properties 'signin-13-properties'
            } else {
                $said += Statics $properties
            }
            Click $properties 2
            [void](WaitFor { -not [Native.Win]::IsWindow($properties) })
        }
        Check ($null -ne $found) "Properties of the account signed in to says what it signs in with ($count accounts; $($said -join ' | '))"
        Click $accounts 404
        [void](WaitFor { -not [Native.Win]::IsWindow($accounts) })
    }

    # Google turned on: its button works, and a Gmail address is offered it; the app turned off is not in the menu
    Command $main $IDM_NEW_ACCOUNT
    $first = StartPage $true
    if ($first) {
        Check ([Native.Win]::IsWindowEnabled([Native.Win]::GetDlgItem($first, 120)) -and [Native.Win]::GetDlgItem($first, 123) -eq [IntPtr]::Zero) 'Sign in with Google works once turned on'
        Click $first 122
        $menu = WaitWindow '#32768' $null 10
        if ($menu) {
            $hmenu = [Native.Win]::SendMessage($menu, 0x01E1, [IntPtr]::Zero, [IntPtr]::Zero)
            Check ([Native.Win]::GetMenuItemCount($hmenu) -eq 1) 'a sign-in app turned off is left out of More sign-in options'
            Key $menu $VK_ESCAPE
            [void](WaitFor { -not [Native.Win]::IsWindow($menu) } 5)
        }
        SetText $first 100 'Gmail Test'
        SetText $first 101 'inboxclassic.test@gmail.com'
        Click $first 1
        $browser = StartPage $false 40
        Check ($browser -and [Native.Win]::GetDlgItem($browser, 120) -ne [IntPtr]::Zero -and [Native.Win]::GetDlgItem($browser, 121) -eq [IntPtr]::Zero) 'a Gmail address is offered Sign in with Google'
        if ($browser) {
            Shot $browser 'account-5b-browser-sign-in'
            Click $browser 2
            [void](WaitFor { -not [Native.Win]::IsWindow($browser) } 10)
        }
    }

    # ---- Options and the language ----

    Step 'Options and the language'
    $IDM_OPTIONS = 137; $IDC_OPTIONS_LANGUAGE = 660; $IDC_OPTIONS_NOTIFY = 661
    Command $main $IDM_OPTIONS
    $options = WaitShown 'InboxClassicOptions'
    Check ($null -ne $options) 'Tools > Options opens'
    if ($options) {
        $combo = [Native.Win]::GetDlgItem($options, $IDC_OPTIONS_LANGUAGE)
        $count = [int][Native.Win]::SendMessage($combo, $CB_GETCOUNT, [IntPtr]::Zero, [IntPtr]::Zero)
        # CB_GETLBTEXT is one of the messages Windows copies between processes: a buffer of this one
        $items = @(for ($i = 0; $i -lt $count; $i++) {
            $item = New-Object System.Text.StringBuilder 256
            [void][Native.Win]::SendMessage($combo, $CB_GETLBTEXT, [IntPtr]$i, $item)
            $item.ToString()
        })
        Check ($items.Count -eq 6 -and $items[0] -like 'System default (*)') "Language starts with System default and the language it is now ($($items[0]))"
        # the names in themselves; the script stays ASCII for Windows PowerShell, which reads it as ANSI
        $names = "English,Deutsch,Eesti,Espa$([char]0xF1)ol,Fran$([char]0xE7)ais"
        Check ((($items | Select-Object -Skip 1) -join ',') -eq $names) "and lists the five languages by their own names ($($items -join ', '))"
        Check ([Native.Win]::GetDlgItem($options, $IDC_OPTIONS_NOTIFY) -ne [IntPtr]::Zero) 'Notify of New Mail is there too'
        $deutsch = [array]::IndexOf($items, 'Deutsch')
        [void][Native.Win]::SendMessage($combo, $CB_SETCURSEL, [IntPtr]$deutsch, [IntPtr]::Zero)
        Shot $options 'options-1-language'
        Click $options 1
        $restart = WaitShown 'InboxClassicRestart' 10
        Check ($null -ne $restart) 'a language chosen asks to restart'
        if ($restart) {
            Check ((GetText $restart 1) -eq '&Restart Now' -and (GetText $restart 2) -eq '&Later') 'with Restart Now and Later'
            Click $restart 2
        }
        Start-Sleep -Milliseconds 500
        Check ((Get-ItemProperty -Path $preferencesKey -Name Language -ErrorAction SilentlyContinue).Language -eq 'de') 'the language is kept for the next start'
        Check ([Native.Win]::IsWindow($main) -and -not $app.HasExited) 'Later keeps the app running'
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

    Step 'the tray'
    Add-Type -Namespace Native -Name Tray -MemberDefinition @'
[StructLayout(LayoutKind.Sequential)] public struct NOTIFYICONIDENTIFIER { public int cbSize; public IntPtr hWnd; public uint uID; public Guid guidItem; }
public struct IconRect { public int Left, Top, Right, Bottom; }
[DllImport("shell32.dll")] public static extern int Shell_NotifyIconGetRect(ref NOTIFYICONIDENTIFIER identifier, out IconRect rect);
public static bool HasIcon(IntPtr window) {
    var id = new NOTIFYICONIDENTIFIER { cbSize = Marshal.SizeOf(typeof(NOTIFYICONIDENTIFIER)), hWnd = window, uID = 1 };
    IconRect rect;
    return Shell_NotifyIconGetRect(ref id, out rect) == 0;
}
'@
    Check ([Native.Tray]::HasIcon($main)) 'the app has its icon in the notification area'
    SelectFolder 0
    $beforeRows = WaitFor { if ((Rows) -ge 1) { Rows } }
    # the close button hides it there, where it goes on checking mail
    [void][Native.Win]::PostMessage($main, $WM_CLOSE, [IntPtr]::Zero, [IntPtr]::Zero)
    Check ([bool](WaitFor { -not [Native.Win]::IsWindowVisible($main) } 10)) 'closing the window hides it in the tray'
    Check (-not $app.HasExited) 'and the app keeps running'
    # new mail while it is hidden: it comes in at once (IDLE), with a notification
    AddMessage "From: Nora Example <nora@example.com>`r`nTo: testuser@inboxclassic.test`r`nSubject: Fresh while hidden`r`nDate: $([DateTime]::UtcNow.AddMinutes(5).ToString('r'))`r`nMessage-ID: <fresh-hidden@example.com>`r`n`r`nJust in.`r`n"
    Start-Sleep -Seconds 6
    $desktop = [Native.Win]::GetDesktopWindow()
    Shot $desktop 'tray-1-notification'
    # a click on the icon brings it back, with the new message in the Inbox
    $WM_TRAY = 0x8000 + 60; $NIN_SELECT = 0x0400
    [void][Native.Win]::PostMessage($main, $WM_TRAY, [IntPtr]::Zero, [IntPtr]$NIN_SELECT)
    Check ([bool](WaitFor { [Native.Win]::IsWindowVisible($main) } 10)) 'a click on the icon shows the window again'
    Check ([bool](WaitFor { (Rows) -gt $beforeRows } 10)) "with the new message in the list, which came without a sync ($beforeRows, $(Rows))"
    # the taskbar button counts what is unread in the Inbox
    Start-Sleep -Seconds 1
    Shot $desktop 'tray-2-taskbar'

    Step 'closing'
    # a message being written is asked about first: Cancel keeps the app and the message, No lets both go
    Command $main $IDM_NEW_MAIL
    $compose = WaitCompose
    SetText $compose $IDC_SUBJECT 'Still writing'
    [void](TypeInEditor $compose 'Not done yet.')
    # File > Exit ends the app (the close button only hides it)
    Command $main $IDM_EXIT
    $ask = WaitWindow '#32770' 'Inbox Classic' 10
    Check ($null -ne $ask) 'closing the app asks about a message with changes'
    if ($ask) {
        Shot $ask 'write-12-close-app'
        Click $ask 2
        Start-Sleep -Seconds 1
        Check ([Native.Win]::IsWindow($main) -and [Native.Win]::IsWindow($compose)) 'Cancel keeps the app and the message open'
        Command $main $IDM_EXIT
        $ask = WaitWindow '#32770' 'Inbox Classic' 10
        if ($ask) { Click $ask 7 }
    }
    Check ($app.WaitForExit(15000)) 'No closes the message without saving, and the app'

    # ---- the other languages ----

    # the language of a catalog, as the app shows it: id to words (core/locales/<language>/*.ftl), one line each
    function Catalog([string]$language) {
        $words = @{}
        foreach ($file in Get-ChildItem (Join-Path $PSScriptRoot "..\core\locales\$language") -Filter '*.ftl') {
            foreach ($line in Get-Content -Encoding UTF8 $file.FullName) {
                if ($line -match '^([a-z][a-z0-9-]*) = (.+)$') { $words[$Matches[1]] = $Matches[2].Replace('&', '') }
            }
        }
        $words
    }
    # the app started again with this store; the main window once it shows its folders
    function StartAgain([string[]]$more) {
        # one that did not close (its failure is reported) would take the new start over
        if (-not $script:app.HasExited) { $script:app.Kill(); [void]$script:app.WaitForExit(5000) }
        $script:started += $script:app
        $script:app = Start-Process -FilePath $Exe -ArgumentList ($arguments + $more) -PassThru
        $window = WaitFor {
            # the window of the new process, not of one still closing
            $w = [Native.Win]::FindWindow('InboxClassicMain', [NullString]::Value)
            $owner = [uint32]0
            if ($w -ne [IntPtr]::Zero) { [void][Native.Win]::GetWindowThreadProcessId($w, [ref]$owner) }
            if ($w -ne [IntPtr]::Zero -and $owner -eq $script:app.Id -and [Native.Win]::IsWindowVisible($w)) { $w }
        } 30
        if ($window) {
            $t = [Native.Win]::GetDlgItem($window, $IDC_TREE)
            [void](WaitFor { if (@(TreeTexts $t).Count -gt 2) { $true } } 30)
            Start-Sleep -Seconds 2
        }
        $window
    }
    function Quit([IntPtr]$window, [string]$what) {
        Command $window $IDM_EXIT
        Check ($script:app.WaitForExit(15000)) "File > Exit ends the app ($what)"
    }
    # the toolbar of the main window and the words of its buttons
    function ToolbarText([IntPtr]$window, [int]$id) {
        foreach ($bar in [Native.Win]::FindDescendants($window, 'ToolbarWindow32')) {
            $text = [Native.Win]::RemoteText($bar, 0x044B, [IntPtr]$id)
            if ($text) { return $text }
        }
        ''
    }
    # every static and button of $window: its words not left in English (a word of the pseudo-language starts with
    # "["), and, unless $wordsOnly, not cut off
    function CheckPseudo([IntPtr]$window, [string]$what, [bool]$wordsOnly = $false) {
        $english = @(); $cut = @()
        foreach ($class in 'Static', 'Button') {
            foreach ($control in [Native.Win]::FindDescendants($window, $class)) {
                if (-not [Native.Win]::IsWindowVisible($control)) { continue }
                $text = WindowText $control
                if ([string]::IsNullOrWhiteSpace($text)) { continue }
                if (-not $text.TrimStart().StartsWith('[')) { $english += $text }
                $style = [Native.Win]::GetWindowLong($control, -16)
                $kind = $style -band 0x1F
                # owner drawn (a picture, a link) and group boxes draw their words their own way
                $drawn = ($class -eq 'Button' -and (($kind -band 0xF) -in @(7, 11))) -or ($class -eq 'Static' -and $kind -eq 13)
                if ($wordsOnly -or $drawn) { continue }
                $isButton = $class -eq 'Button'
                $hasBox = ($kind -band 0xF) -in @(2, 3, 5, 6)
                if (-not [Native.Win]::Fits($control, $text, $isButton, $hasBox)) { $cut += $text }
            }
        }
        Check ($english.Count -eq 0) "${what}: no word left in English ($($english -join ' | '))"
        if (-not $wordsOnly) { Check ($cut.Count -eq 0) "${what}: nothing cut off ($($cut -join ' | '))" }
    }

    Step 'in German'
    # the language chosen in Options above, read at start
    $de = Catalog 'de'
    $main = StartAgain @()
    Check ($null -ne $main) 'the app starts again in the language chosen'
    if ($main) {
        $menus = [Native.Win]::MenuLabels([Native.Win]::GetMenu($main))
        $wanted = @('menu-file', 'menu-edit', 'menu-view', 'menu-tools', 'menu-message', 'menu-help' | ForEach-Object { $de[$_] })
        Check (($menus -join ',') -eq ($wanted -join ',')) "the menus are German ($($menus -join ', '))"
        $tools = [Native.Win]::MenuLabels([Native.Win]::GetSubMenu([Native.Win]::GetMenu($main), 3))
        Check ($tools[-1] -eq $de['cmd-options']) "Tools ends with $($de['cmd-options'])"
        Check ((ToolbarText $main $IDM_NEW_MAIL) -eq $de['ui-tb-create-mail']) "the toolbar is German ($(ToolbarText $main $IDM_NEW_MAIL))"
        $folders = @(TreeTexts ([Native.Win]::GetDlgItem($main, $IDC_TREE)))
        Check (@($folders | Where-Object { $_ -like "$($de['folder-inbox'])*" }).Count -gt 0) "the folders are German ($($folders -join ', '))"
        $status = [Native.Win]::FindDescendants($main, 'msctls_statusbar32') | Select-Object -First 1
        Write-Host "   status bar: $(StatusPart $status 0) | $(StatusPart $status 1)"
        Shot $main 'lang-1-german'
        # the sign-in buttons say it in German, and the form is as wide as they are
        Command $main $IDM_NEW_ACCOUNT
        $form = WaitShown 'InboxClassicAccountStart' 10
        Check ($null -ne $form) 'Add Mail Account opens in German'
        if ($form) {
            Start-Sleep -Milliseconds 500
            Shot $form 'lang-1b-german-form'
            Click $form 2
        }
        Start-Sleep -Milliseconds 500
        Quit $main 'German'
    }
    Remove-ItemProperty -Path $preferencesKey -Name Language -ErrorAction SilentlyContinue

    Step 'in the pseudo-language'
    $main = StartAgain @('--language', 'qps')
    Check ($null -ne $main) 'the app starts in the pseudo-language'
    if ($main) {
        $menus = [Native.Win]::MenuLabels([Native.Win]::GetMenu($main))
        $bar = [Native.Win]::GetMenu($main)
        $items = @()
        for ($i = 0; $i -lt $menus.Count; $i++) { $items += [Native.Win]::MenuLabels([Native.Win]::GetSubMenu($bar, $i)) }
        $english = @(($menus + $items) | Where-Object { $_ -and -not $_.StartsWith('[') })
        Check ($english.Count -eq 0) "no menu item is left in English ($($english -join ' | '))"
        $buttons = @($IDM_NEW_MAIL, $IDM_REPLY, $IDM_REPLY_ALL, $IDM_FORWARD, $IDM_PRINT, $IDM_DELETE, $IDM_SYNC | ForEach-Object { ToolbarText $main $_ })
        Check (@($buttons | Where-Object { -not $_.StartsWith('[') }).Count -eq 0) "no toolbar button is left in English ($($buttons -join ' | '))"
        # the longer words take room from the Find box down to its least width, and a button that would still run
        # under it is hidden (its command is in the menus)
        $findLeft = 0; $box = New-Object Native.Win+RECT
        [void][Native.Win]::GetWindowRect([Native.Win]::GetDlgItem($main, 205), [ref]$box); $findLeft = $box.Left
        $under = @()
        foreach ($bar in [Native.Win]::FindDescendants($main, 'ToolbarWindow32')) {
            foreach ($id in $IDM_NEW_MAIL, $IDM_REPLY, $IDM_REPLY_ALL, $IDM_FORWARD, $IDM_PRINT, $IDM_DELETE, 127, $IDM_SYNC, $IDM_MARK_READ, $IDM_MARK_UNREAD) {
                $r = [Native.Win]::RemoteRect($bar, 0x0433, [IntPtr]$id, 0)
                if ($r.Right -gt $r.Left -and $r.Right -gt $findLeft -and $r.Left -lt $box.Right -and $r.Top -lt $box.Bottom -and $r.Bottom -gt $box.Top) { $under += $id }
            }
        }
        Check ($under.Count -eq 0) "no toolbar button runs under the Find box ($($under -join ', '))"
        # the buttons hidden for want of room are in the menu of the chevron after the others
        $IDC_TOOLBAR_MORE = 233
        $chevron = [Native.Win]::GetDlgItem($main, $IDC_TOOLBAR_MORE)
        Check ($chevron -ne [IntPtr]::Zero -and [Native.Win]::IsWindowVisible($chevron)) 'the chevron is shown after the buttons that fit'
        if ($chevron -ne [IntPtr]::Zero -and [Native.Win]::IsWindowVisible($chevron)) {
            Click $main $IDC_TOOLBAR_MORE
            $more = WaitWindow '#32768' $null 10
            $hidden = if ($more) { @([Native.Win]::MenuLabels([Native.Win]::SendMessage($more, 0x01E1, [IntPtr]::Zero, [IntPtr]::Zero)) | Where-Object { $_ }) } else { @() }
            Check ($hidden.Count -gt 0 -and @($hidden | Where-Object { -not $_.StartsWith('[') }).Count -eq 0) "its menu has the hidden buttons ($($hidden -join ' | '))"
            if ($more) {
                Shot $main 'lang-2b-pseudo-more' $more
                Key $more $VK_ESCAPE
                [void](WaitFor { -not [Native.Win]::IsWindow($more) } 5)
            }
        }
        $folders = @(TreeTexts ([Native.Win]::GetDlgItem($main, $IDC_TREE)))
        Check (@($folders | Where-Object { $_.StartsWith('[') }).Count -ge 3) "the special folders and All Inboxes are pseudo ($($folders -join ', '))"
        CheckPseudo $main 'the main window' $true
        Shot $main 'lang-2-pseudo-main'

        Command $main $IDM_NEW_MAIL
        $compose = WaitCompose
        if ($compose) {
            CheckPseudo $compose 'the compose window'
            [void][Native.Win]::PostMessage($compose, $WM_CLOSE, [IntPtr]::Zero, [IntPtr]::Zero)
            [void](WaitFor { if (-not [Native.Win]::IsWindow($compose)) { $true } } 10)
        }

        Command $main $IDM_OPTIONS
        $options = WaitShown 'InboxClassicOptions'
        if ($options) {
            CheckPseudo $options 'Options'
            Shot $options 'lang-4-pseudo-options'
            Click $options 2
        }

        Command $main $IDM_NEW_ACCOUNT
        $form = WaitShown 'InboxClassicAccountStart' 10
        Check ($null -ne $form) 'Add Mail Account opens'
        if ($form) {
            CheckPseudo $form 'the account form'
            Shot $form 'lang-3-pseudo-form'
            Click $form 2
        }
        Start-Sleep -Milliseconds 500
        Quit $main 'pseudo-language'
    }
} catch {
    Check $false "unexpected error: $_ at line $($_.InvocationInfo.ScriptLineNumber)"
} finally {
    # this run's app, and any earlier one of it that did not close (a dialog left open by a failed step)
    foreach ($process in @($app) + $started) {
        if ($process -and -not $process.HasExited) { $process.Kill() }
    }
    if ($null -eq $savedLanguage) {
        Remove-ItemProperty -Path $preferencesKey -Name Language -ErrorAction SilentlyContinue
    } else {
        Set-ItemProperty -Path $preferencesKey -Name Language -Value $savedLanguage
    }
    if ($null -eq $savedGrouping) {
        Remove-ItemProperty -Path $preferencesKey -Name GroupByConversation -ErrorAction SilentlyContinue
    } else {
        Set-ItemProperty -Path $preferencesKey -Name GroupByConversation -Value $savedGrouping -Type DWord
    }
    if ($null -eq $savedClosedRows) {
        Remove-ItemProperty -Path $preferencesKey -Name ClosedFolderRows -ErrorAction SilentlyContinue
    } else {
        Set-ItemProperty -Path $preferencesKey -Name ClosedFolderRows -Value $savedClosedRows
    }
    if ($null -eq $savedCodes) {
        Remove-ItemProperty -Path $preferencesKey -Name CodesInNotifications -ErrorAction SilentlyContinue
    } else {
        Set-ItemProperty -Path $preferencesKey -Name CodesInNotifications -Value $savedCodes -Type DWord
    }
    $harness.StandardInput.Close()
    if (-not $harness.WaitForExit(5000)) { $harness.Kill() }
}

$result = if ($failures.Count) { "FAILED: $($failures -join '; ')" } else { 'passed' }
Write-Host $result
Stop-Transcript | Out-Null
Set-Content -Path (Join-Path $Out 'result.txt') -Value $result
if ($failures.Count) { exit 1 }
