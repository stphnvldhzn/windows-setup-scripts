write-output "Getting User ID..."
$User = New-Object System.Security.Principal.NTAccount($env:UserName)
$sid = $User.Translate([System.Security.Principal.SecurityIdentifier]).value

write-output "User ID ($sid)"

reg add "HKU\$sid\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32" /f /ve