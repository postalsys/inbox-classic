# Selects a folder and a message in a running Inbox Classic, for testing on the build machine:
#   powershell -File ui-select.ps1 <folder> <message>
# <folder> is the position of the folder under the first account (0 is the first folder), <message> the row in the
# message list, reached with the arrow keys as a user would.
param([Parameter(Mandatory)][int]$Folder, [Parameter(Mandatory)][int]$Message)
$ErrorActionPreference = 'Stop'
Add-Type -Namespace Native -Name Win -MemberDefinition @'
[DllImport("user32.dll", CharSet = CharSet.Unicode)] public static extern IntPtr FindWindow(string cls, string title);
[DllImport("user32.dll")] public static extern IntPtr GetDlgItem(IntPtr hwnd, int id);
[DllImport("user32.dll")] public static extern IntPtr SendMessage(IntPtr hwnd, uint message, IntPtr wParam, IntPtr lParam);
[DllImport("user32.dll")] public static extern bool PostMessage(IntPtr hwnd, uint message, IntPtr wParam, IntPtr lParam);
'@
$TVM_GETNEXTITEM = 0x110A; $TVM_SELECTITEM = 0x110B; $TVGN_ROOT = 0; $TVGN_NEXT = 1; $TVGN_CHILD = 4; $TVGN_CARET = 9
$WM_SETFOCUS = 0x0007; $WM_KEYDOWN = 0x0100; $WM_KEYUP = 0x0101; $VK_HOME = 0x24; $VK_DOWN = 0x28

$main = [Native.Win]::FindWindow('InboxClassicMain', [NullString]::Value)
if ($main -eq [IntPtr]::Zero) { throw 'Inbox Classic is not running' }
# control ids of app/src/app.h
$tree = [Native.Win]::GetDlgItem($main, 200)
$list = [Native.Win]::GetDlgItem($main, 201)

$root = [Native.Win]::SendMessage($tree, $TVM_GETNEXTITEM, [IntPtr]$TVGN_ROOT, [IntPtr]::Zero)
$item = [Native.Win]::SendMessage($tree, $TVM_GETNEXTITEM, [IntPtr]$TVGN_CHILD, $root)
for ($i = 0; $i -lt $Folder; $i++) { $item = [Native.Win]::SendMessage($tree, $TVM_GETNEXTITEM, [IntPtr]$TVGN_NEXT, $item) }
[void][Native.Win]::SendMessage($tree, $TVM_SELECTITEM, [IntPtr]$TVGN_CARET, $item)
Start-Sleep -Milliseconds 300

function Key([int]$vk) {
    [void][Native.Win]::PostMessage($list, $WM_KEYDOWN, [IntPtr]$vk, [IntPtr]::Zero)
    [void][Native.Win]::PostMessage($list, $WM_KEYUP, [IntPtr]$vk, [IntPtr]::Zero)
    Start-Sleep -Milliseconds 100
}
[void][Native.Win]::SendMessage($list, $WM_SETFOCUS, [IntPtr]::Zero, [IntPtr]::Zero)
Key $VK_HOME
for ($i = 0; $i -lt $Message; $i++) { Key $VK_DOWN }
