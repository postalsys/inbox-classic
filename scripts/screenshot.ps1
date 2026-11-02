# Saves a screenshot as PNG: of the app window (made topmost for a moment, so other windows do not cover it and the
# WebView2 content is on screen), or of the whole desktop with -Desktop. At full resolution also on scaled displays
param([string]$Path, [switch]$Desktop)
$Title = 'PostalExpress'
Add-Type -AssemblyName System.Windows.Forms, System.Drawing
Add-Type -Namespace Native -Name User32 -MemberDefinition @'
[DllImport("user32.dll")] public static extern bool SetProcessDPIAware();
[DllImport("user32.dll", CharSet = CharSet.Unicode)] public static extern IntPtr FindWindow(string cls, string title);
[DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr hwnd, out RECT rect);
[DllImport("user32.dll")] public static extern bool SetWindowPos(IntPtr hwnd, IntPtr after, int x, int y, int cx, int cy, uint flags);
public struct RECT { public int Left, Top, Right, Bottom; }
'@
[Native.User32]::SetProcessDPIAware() | Out-Null
if (-not $Desktop) {
    $hwnd = [Native.User32]::FindWindow([NullString]::Value, $Title)
    if ($hwnd -eq [IntPtr]::Zero) { Write-Error "no window titled $Title"; exit 1 }
    # HWND_TOPMOST without moving, sizing or activating, then back to HWND_NOTOPMOST
    [Native.User32]::SetWindowPos($hwnd, [IntPtr](-1), 0, 0, 0, 0, 0x13) | Out-Null
    Start-Sleep -Milliseconds 400
    $rect = New-Object Native.User32+RECT
    [Native.User32]::GetWindowRect($hwnd, [ref]$rect) | Out-Null
    $bitmap = New-Object System.Drawing.Bitmap ($rect.Right - $rect.Left), ($rect.Bottom - $rect.Top)
    $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
    $graphics.CopyFromScreen($rect.Left, $rect.Top, 0, 0, $bitmap.Size)
    [Native.User32]::SetWindowPos($hwnd, [IntPtr](-2), 0, 0, 0, 0, 0x13) | Out-Null
} else {
    $bounds = [System.Windows.Forms.SystemInformation]::VirtualScreen
    $bitmap = New-Object System.Drawing.Bitmap $bounds.Width, $bounds.Height
    $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
    $graphics.CopyFromScreen($bounds.Location, [System.Drawing.Point]::Empty, $bounds.Size)
}
$bitmap.Save($Path, [System.Drawing.Imaging.ImageFormat]::Png)
