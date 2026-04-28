# Variables
$usernamelist = get-localuser | select-object -expandproperty name
$defaultaccounts = "Admin|Administrator|DefaultAccount|Guest|WDAGUtilityAccount"

# Run Command on All Non-Admin/Default Accounts
foreach ($name in $usernamelist){if($name -match $defaultaccounts) {write-output "$name is a default account"} else {$sid = get-localuser -name $name | select-object -expandproperty sid; reg add "HKU\$sid\SOFTWARE\Microsoft\Windows\CurrentVersion\Notifications\Settings\Windows.SystemToast.BackupReminder" /v Enabled /t REG_DWORD /D 0 /f; reg add "HKU\$sid\SOFTWARE\Microsoft\Windows\CurrentVersion\Notifications\Settings\Microsoft.SkyDrive.Desktop" /v Enabled /t REG_DWORD /D 0 /f; reg add "HKU\$sid\SOFTWARE\Policies\Microsoft\OneDrive" /v DisablePersonalSync /t REG_DWORD /D 1 /f}}

# Disable OneDrive New Account Detection
reg add "HKLM\SOFTWARE\Policies\Microsoft\OneDrive" /v DisableNewAccountDetection /t REG_DWORD /D 1 /f