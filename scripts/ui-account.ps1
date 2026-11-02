# Fills the Add Mail Account form of a running PostalExpress and clicks OK, for testing on the build machine:
#   powershell -File ui-account.ps1 <email> <password> <imap host> <imap port> <smtp host> <smtp port> <smtp security>
# Security is the index of the choice: 0 SSL/TLS, 1 STARTTLS, 2 None. The IMAP security is SSL/TLS.
param(
    [Parameter(Mandatory)][string]$Email,
    [Parameter(Mandatory)][string]$Password,
    [Parameter(Mandatory)][string]$ImapHost,
    [Parameter(Mandatory)][string]$ImapPort,
    [Parameter(Mandatory)][string]$SmtpHost,
    [Parameter(Mandatory)][string]$SmtpPort,
    [Parameter(Mandatory)][int]$SmtpSecurity
)
$ErrorActionPreference = 'Stop'
Add-Type -Namespace Native -Name Win -MemberDefinition @'
[DllImport("user32.dll", CharSet = CharSet.Unicode)] public static extern IntPtr FindWindow(string cls, string title);
[DllImport("user32.dll")] public static extern IntPtr GetDlgItem(IntPtr hwnd, int id);
[DllImport("user32.dll", CharSet = CharSet.Unicode)] public static extern IntPtr SendMessage(IntPtr hwnd, uint message, IntPtr wParam, string lParam);
[DllImport("user32.dll")] public static extern IntPtr SendMessage(IntPtr hwnd, uint message, IntPtr wParam, IntPtr lParam);
'@
$WM_SETTEXT = 0x000C; $BM_CLICK = 0x00F5; $CB_SETCURSEL = 0x014E

$form = [IntPtr]::Zero
for ($i = 0; $i -lt 50 -and $form -eq [IntPtr]::Zero; $i++) {
    Start-Sleep -Milliseconds 200
    $form = [Native.Win]::FindWindow('PostalExpressForm', 'Add Mail Account')
}
if ($form -eq [IntPtr]::Zero) { throw 'no Add Mail Account form' }

# the inputs have ids 100 and up in the order of the form (app/src/accounts.cpp)
$values = @{ 100 = 'Test'; 101 = $Email; 102 = $Email; 103 = $Password; 104 = $ImapHost; 105 = $ImapPort; 107 = $SmtpHost; 108 = $SmtpPort }
foreach ($id in $values.Keys) {
    [void][Native.Win]::SendMessage([Native.Win]::GetDlgItem($form, $id), $WM_SETTEXT, [IntPtr]::Zero, [string]$values[$id])
}
[void][Native.Win]::SendMessage([Native.Win]::GetDlgItem($form, 106), $CB_SETCURSEL, [IntPtr]0, [IntPtr]::Zero)
[void][Native.Win]::SendMessage([Native.Win]::GetDlgItem($form, 109), $CB_SETCURSEL, [IntPtr]$SmtpSecurity, [IntPtr]::Zero)
# IDOK
[void][Native.Win]::SendMessage([Native.Win]::GetDlgItem($form, 1), $BM_CLICK, [IntPtr]::Zero, [IntPtr]::Zero)
