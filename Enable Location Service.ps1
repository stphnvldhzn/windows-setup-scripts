# Enable Location Service Computer-Wide
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\LocationAndSensors" /v "DisableWindowsLocationProvider" /t REG_DWORD /d "0" /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\LocationAndSensors" /v "DisableLocationScripting" /t REG_DWORD /d "0" /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\LocationAndSensors" /v "DisableLocation" /d "0" /t REG_DWORD /f
reg add "HKLM\SOFTWARE\WOW6432Node\Policies\Microsoft\Windows\LocationAndSensors" /v "DisableLocation" /d "0" /t REG_DWORD /f
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\location" /v "Value" /d "Allow" /t REG_SZ /f
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\location\NonPackaged" /v "Value" /d "Allow" /t REG_SZ /f


#Enable Location Server Per-User
# Variables
$usernamelist = get-localuser | select-object -expandproperty name
$defaultaccounts = "Admin|Administrator|DefaultAccount|Guest|WDAGUtilityAccount"

# Run Command on All Non-Admin/Default Accounts - For Apps
foreach ($name in $usernamelist){if($name -match $defaultaccounts) {write-output "$name is a default account"} else {$sid = get-localuser -name $name | select-object -expandproperty sid; reg add "HKU\$sid\Software\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\location" /v Value /t REG_SZ /d Allow /f}}

# Run Command on All Non-Admin/Default Accounts - For Desktop Apps
foreach ($name in $usernamelist){if($name -match $defaultaccounts) {write-output "$name is a default account"} else {$sid = get-localuser -name $name | select-object -expandproperty sid; reg add "HKU\$sid\Software\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\location\NonPackaged" /v Value /t REG_SZ /d Allow /f}}