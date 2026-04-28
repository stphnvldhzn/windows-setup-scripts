reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\GameDVR" /v AllowGameDVR /t REG_DWORD /d 0 /f

reg add HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\GameDVR /f /t REG_DWORD /v "AppCaptureEnabled" /d 0
reg add HKEY_CURRENT_USER\System\GameConfigStore /f /t REG_DWORD /v "GameDVR_Enabled" /d 0


# Disable for current SID
write-output "Getting User ID..."
$User = New-Object System.Security.Principal.NTAccount($env:UserName)
$sid = $User.Translate([System.Security.Principal.SecurityIdentifier]).value

write-output "User ID ($sid)"

reg add "HKU\$sid\Software\Microsoft\Windows\CurrentVersion\PushNotifications" /v ToastEnabled /t REG_DWORD /D 0 /f


# Disable for all local users
# Variables
$usernamelist = get-localuser | select-object -expandproperty name
$defaultaccounts = "Admin|Administrator|DefaultAccount|Guest|WDAGUtilityAccount"

# Run Command on All Non-Admin/Default Accounts
foreach ($name in $usernamelist){if($name -match $defaultaccounts) {write-output "$name is a default account"} else {$sid2 = get-localuser -name $name | select-object -expandproperty sid; reg add "HKU\$sid2\Software\Microsoft\Windows\CurrentVersion\PushNotifications" /v ToastEnabled /t REG_DWORD /D 0 /f}}