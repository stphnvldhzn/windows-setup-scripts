write-output "Getting User ID..."
$User = New-Object System.Security.Principal.NTAccount($env:UserName)
$sid = $User.Translate([System.Security.Principal.SecurityIdentifier]).value
get-localuser -sid $sid

write-output "User ID ($sid)"

reg add "HKU\$sid\Software\Policies\Microsoft\Windows\WindowsCopilot" /v TurnOffWindowsCopilot /t REG_DWORD /D 1 /f