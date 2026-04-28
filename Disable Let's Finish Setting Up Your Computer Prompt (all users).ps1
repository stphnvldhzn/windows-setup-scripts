# Variables
$usernamelist = get-localuser | select-object -expandproperty name
$defaultaccounts = "Admin|Administrator|DefaultAccount|Guest|WDAGUtilityAccount"

# Run Command on All Non-Admin/Default Accounts
foreach ($name in $usernamelist){if($name -match $defaultaccounts) {write-output "$name is a default account"} else {$sid = get-localuser -name $name | select-object -expandproperty sid; reg add "HKU\$sid\Software\Microsoft\Windows\CurrentVersion\UserProfileEngagement" /v ScoobeSystemSettingEnabled /t REG_DWORD /d 1 /f}}