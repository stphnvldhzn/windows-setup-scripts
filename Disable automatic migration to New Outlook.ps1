write-output "Getting User ID..."
$User = New-Object System.Security.Principal.NTAccount($env:UserName)
$sid = $User.Translate([System.Security.Principal.SecurityIdentifier]).value

write-output "User ID ($sid)"

reg add "HKU\$sid\Software\Microsoft\Office\16.0\Outlook\Options\General" /v DoNewOutlookAutoMigration /t REG_DWORD /D 0 /f