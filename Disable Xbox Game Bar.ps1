# Machine-wide policy
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\GameDVR" /v AllowGameDVR /t REG_DWORD /d 0 /f

# Per-user GameDVR keys for every non-default local account
$usernamelist = Get-LocalUser | Select-Object -ExpandProperty Name
$defaultaccounts = "Admin|Administrator|DefaultAccount|Guest|WDAGUtilityAccount"
foreach ($name in $usernamelist) {
    if ($name -match $defaultaccounts) {
        Write-Output "$name is a default account, skipping"
    } else {
        $sid = Get-LocalUser -Name $name | Select-Object -ExpandProperty SID
        reg add "HKU\$sid\Software\Microsoft\Windows\CurrentVersion\GameDVR" /v AppCaptureEnabled /t REG_DWORD /D 0 /f
        reg add "HKU\$sid\System\GameConfigStore" /v GameDVR_Enabled /t REG_DWORD /D 0 /f
    }
}
