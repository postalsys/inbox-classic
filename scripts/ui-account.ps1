# Fills both steps of the Add Mail Account form of a running Inbox Classic, for testing on the build machine:
#   powershell -File ui-account.ps1 <email> <password> <imap host> <imap port> <smtp host> <smtp port> <smtp security>
# Security is the index of the choice: 0 SSL/TLS, 1 STARTTLS, 2 None. The IMAP security is SSL/TLS. The user name
# is the address. scripts/ui-e2e.ps1 goes through the same form with checks.
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
[DllImport("user32.dll")] public static extern bool PostMessage(IntPtr hwnd, uint message, IntPtr wParam, IntPtr lParam);
'@
$WM_SETTEXT = 0x000C; $WM_COMMAND = 0x0111; $CB_SETCURSEL = 0x014E

# the first page (name and address), or the server settings form when $Second (it has the SMTP security choice, id 109)
function WaitForForm([bool]$Second) {
    for ($i = 0; $i -lt 200; $i++) {
        $form = [Native.Win]::FindWindow($(if ($Second) { 'InboxClassicForm' } else { 'InboxClassicAccountStart' }), 'Add Mail Account')
        if ($form -ne [IntPtr]::Zero -and (-not $Second -or [Native.Win]::GetDlgItem($form, 109) -ne [IntPtr]::Zero)) { return $form }
        Start-Sleep -Milliseconds 200
    }
    throw 'no Add Mail Account form'
}
function Fill([IntPtr]$form, [hashtable]$values) {
    foreach ($id in $values.Keys) {
        [void][Native.Win]::SendMessage([Native.Win]::GetDlgItem($form, $id), $WM_SETTEXT, [IntPtr]::Zero, [string]$values[$id])
    }
}
# posted: the click starts the next step's modal loop, a sent one would wait for it
function ClickOk([IntPtr]$window, [int]$id = 1) {
    # BN_CLICKED to the window, as a click ends up: BM_CLICK can be lost when the window is not the active one
    [void][Native.Win]::PostMessage($window, $WM_COMMAND, [IntPtr]($id -band 0xFFFF), [Native.Win]::GetDlgItem($window, $id))
}

# the inputs have ids 100 and up in the order of the form (app/src/accounts.cpp). First the name and address; the
# lookup of the servers follows
$form = WaitForForm $false
Fill $form @{ 100 = 'Test'; 101 = $Email }
ClickOk $form
# then the server settings it found, corrected
$form = WaitForForm $true
Fill $form @{ 102 = $Email; 103 = $Password; 104 = $ImapHost; 105 = $ImapPort; 107 = $SmtpHost; 108 = $SmtpPort }
[void][Native.Win]::SendMessage([Native.Win]::GetDlgItem($form, 106), $CB_SETCURSEL, [IntPtr]0, [IntPtr]::Zero)
[void][Native.Win]::SendMessage([Native.Win]::GetDlgItem($form, 109), $CB_SETCURSEL, [IntPtr]$SmtpSecurity, [IntPtr]::Zero)
ClickOk $form
if ($SmtpSecurity -eq 2) {
    # the warning about a connection without encryption: Yes
    for ($i = 0; $i -lt 50; $i++) {
        $warning = [Native.Win]::FindWindow('#32770', 'Add Mail Account')
        if ($warning -ne [IntPtr]::Zero) { ClickOk $warning 6; break }
        Start-Sleep -Milliseconds 200
    }
}
