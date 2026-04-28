reg add "HKEY_LOCAL_MACHINE\Software\Policies\Google\Chrome" /v BrowserSignin /t REG_DWORD /D 0 /f

# Disable Login in HKey_Current_User
# Variables
$usernamelist = get-localuser | select-object -expandproperty name
$defaultaccounts = "Admin|Administrator|DefaultAccount|Guest|WDAGUtilityAccount"

# Run Command on All Non-Admin/Default Accounts
foreach ($name in $usernamelist){if($name -match $defaultaccounts) {write-output "$name is a default account"} else {$sid = get-localuser -name $name | select-object -expandproperty sid; reg add "HKU\$sid\Software\Policies\Google\Chrome" /v BrowserSignin /t REG_DWORD /D 0 /f}}