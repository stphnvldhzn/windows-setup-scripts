# Variables
$usernamelist = get-localuser | select-object -expandproperty name
$defaultaccounts = "Admin|Administrator|DefaultAccount|Guest|WDAGUtilityAccount"

# Run Command on All Non-Admin/Default Accounts
foreach ($name in $usernamelist){if($name -match $defaultaccounts) {write-output "$name is a default account"} else {$sid = get-localuser -name $name | select-object -expandproperty sid; reg add "HKU\$sid\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32" /f /ve}}