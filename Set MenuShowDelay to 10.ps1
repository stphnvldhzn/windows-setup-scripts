$usernamelist = Get-LocalUser | Select-Object -ExpandProperty Name
$defaultaccounts = "Admin|Administrator|DefaultAccount|Guest|WDAGUtilityAccount"
foreach ($name in $usernamelist) {
    if ($name -match $defaultaccounts) {
        Write-Output "$name is a default account, skipping"
    } else {
        $sid = Get-LocalUser -Name $name | Select-Object -ExpandProperty SID
        reg add "HKU\$sid\Control Panel\Desktop" /v MenuShowDelay /t REG_SZ /D 10 /f
    }
}
