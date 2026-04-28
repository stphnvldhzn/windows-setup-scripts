$usernamelist = Get-LocalUser | Select-Object -ExpandProperty Name
$defaultaccounts = "Admin|Administrator|DefaultAccount|Guest|WDAGUtilityAccount"
foreach ($name in $usernamelist) {
    if ($name -match $defaultaccounts) {
        Write-Output "$name is a default account, skipping"
    } else {
        $sid = Get-LocalUser -Name $name | Select-Object -ExpandProperty SID
        reg add "HKU\$sid\console" /v ForceV2 /t REG_DWORD /D 0 /f
    }
}
