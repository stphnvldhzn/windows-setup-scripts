# Variables
$usernamelist = get-localuser | select-object -expandproperty name
$defaultaccounts = "Admin|Administrator|DefaultAccount|Guest|WDAGUtilityAccount"

# Run Command on All Non-Admin/Default Accounts
foreach ($name in $usernamelist){if($name -match $defaultaccounts) {write-output "$name is a default account"} else {$sid = get-localuser -name $name | select-object -expandproperty sid; reg load "HKU\$name" "c:\users\$name\ntuser.dat"; reg add "HKU\$sid\Software\Policies\Microsoft\Windows\WindowsCopilot" /v TurnOffWindowsCopilot /t REG_DWORD /D 1 /f; reg unload "HKU\$name"}}

reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsCopilot" /v TurnOffWindowsCopilot /t REG_DWORD /d 1 /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsSearch" /v EnableDynamicContentInWSB /t REG_DWORD /d 0 /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Edge" /v HubsSidebarEnabled /t REG_DWORD /d 0 /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Edge" /v CopilotCDPPageContext /t REG_DWORD /d 0 /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Edge" /v CopilotPageContext /t REG_DWORD /d 0 /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\office\16.0\common\copilot" /v enabled /t REG_DWORD /d 0 /f