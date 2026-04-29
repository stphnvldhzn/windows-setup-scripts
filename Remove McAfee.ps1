<#
.SYNOPSIS
    Removes McAfee consumer products (LiveSafe, Safe Connect, WebAdvisor, WPS).

.DESCRIPTION
    Detects whether McAfee is installed, then runs the McAfee Consumer Product
    Removal (Mccleanup) tool — both the legacy and current builds — followed by
    a sweep of any remaining registry uninstall entries, Safe Connect, leftover
    Start Menu / registry items, and WebAdvisor.

    Adapted from Andrew Taylor's Win11Debloat / RemoveBloat script
    (https://andrewstaylor.com) — McAfee components only.

.OUTPUTS
    C:\ProgramData\Debloat\Debloat.log
#>

##Elevate if needed
If (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]'Administrator')) {
    Write-Output "You didn't run this script as an Administrator. This script will self elevate to run as an Administrator and continue."
    Start-Sleep 1
    Start-Process powershell.exe -ArgumentList ("-NoProfile -ExecutionPolicy Bypass -File `"{0}`"" -f $PSCommandPath) -Verb RunAs
    Exit
}

$startUtc = [datetime]::UtcNow
$ErrorActionPreference = 'SilentlyContinue'
$OrginalProgressPreference = $ProgressPreference
$ProgressPreference = 'SilentlyContinue'

$DebloatFolder = "C:\ProgramData\Debloat"
If (!(Test-Path $DebloatFolder)) {
    New-Item -Path $DebloatFolder -ItemType Directory | Out-Null
}
Start-Transcript -Path "C:\ProgramData\Debloat\Debloat.log"


############################################################################################################
#                                  Detect McAfee Installation                                              #
############################################################################################################

Write-Output "Detecting McAfee"
$mcafeeinstalled = $false
foreach ($path in @(
    "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall",
    "HKLM:\Software\WOW6432NODE\Microsoft\Windows\CurrentVersion\Uninstall"
)) {
    foreach ($obj in (Get-ChildItem $path)) {
        if ($obj.GetValue('DisplayName') -like "*McAfee*") {
            $mcafeeinstalled = $true
        }
    }
}

if (-not $mcafeeinstalled) {
    Write-Output "McAfee not detected. Nothing to do."
    Stop-Transcript
    return
}

Write-Output "McAfee detected"


############################################################################################################
#                            Build All Uninstall Strings (for sweep below)                                 #
############################################################################################################

$allstring = @()
$paths = @(
    "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall",
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall"
)
if ([System.Security.Principal.WindowsIdentity]::GetCurrent().Name -ne "NT AUTHORITY\SYSTEM") {
    $paths += @(
        "HKCU:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall",
        "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall"
    )
}

foreach ($path in $paths) {
    if (-not (Test-Path $path)) { continue }
    $apps = Get-ChildItem -Path $path | Get-ItemProperty | Select-Object -Property DisplayName, UninstallString
    foreach ($app in $apps) {
        $string1 = $app.uninstallstring
        if ($string1 -match "^\s*(C:\\Windows\\System32\\)?msiexec(\.exe)?\s+\S*") {
            $string2 = ($string1 + " /quiet /norestart") -replace "/I", "/X "
        } else {
            $string2 = $string1
        }
        $allstring += New-Object -TypeName PSObject -Property @{
            Name   = $app.DisplayName
            String = $string2
        }
    }
}


############################################################################################################
#                                       Run Mccleanup (Legacy)                                             #
############################################################################################################

Write-Output "Downloading McAfee Removal Tool (legacy)"
$URL = 'https://github.com/andrew-s-taylor/public/raw/main/De-Bloat/mcafeeclean.zip'
$destination = 'C:\ProgramData\Debloat\mcafee.zip'
Invoke-WebRequest -Uri $URL -OutFile $destination -Method Get
Expand-Archive $destination -DestinationPath "C:\ProgramData\Debloat" -Force

Write-Output "Running legacy Mccleanup"
Start-Process "C:\ProgramData\Debloat\Mccleanup.exe" -ArgumentList "-p StopServices,MFSY,PEF,MXD,CSP,Sustainability,MOCP,MFP,APPSTATS,Auth,EMproxy,FWdiver,HW,MAS,MAT,MBK,MCPR,McProxy,McSvcHost,VUL,MHN,MNA,MOBK,MPFP,MPFPCU,MPS,SHRED,MPSCU,MQC,MQCCU,MSAD,MSHR,MSK,MSKCU,MWL,NMC,RedirSvc,VS,REMEDIATION,MSC,YAP,TRUEKEY,LAM,PCB,Symlink,SafeConnect,MGS,WMIRemover,RESIDUEFWDRIVER,Redir,MSHR,WPS,MSSPlus -v -s"


############################################################################################################
#                                       Run Mccleanup (Current)                                            #
############################################################################################################

Write-Output "Downloading McAfee Removal Tool (current)"
$URL = 'https://github.com/andrew-s-taylor/public/raw/main/De-Bloat/mccleanup.zip'
$destination = 'C:\ProgramData\Debloat\mcafeenew.zip'
Invoke-WebRequest -Uri $URL -OutFile $destination -Method Get
New-Item -Path "C:\ProgramData\Debloat\mcnew" -ItemType Directory -Force | Out-Null
Expand-Archive $destination -DestinationPath "C:\ProgramData\Debloat\mcnew" -Force

Write-Output "Running current Mccleanup"
Start-Process "C:\ProgramData\Debloat\mcnew\Mccleanup.exe" -ArgumentList "-p StopServices,MFSY,PEF,MXD,CSP,Sustainability,MOCP,MFP,APPSTATS,Auth,EMproxy,FWdiver,HW,MAS,MAT,MBK,MCPR,McProxy,McSvcHost,VUL,MHN,MNA,MOBK,MPFP,MPFPCU,MPS,SHRED,MPSCU,MQC,MQCCU,MSAD,MSHR,MSK,MSKCU,MWL,NMC,RedirSvc,VS,REMEDIATION,MSC,YAP,TRUEKEY,LAM,PCB,Symlink,SafeConnect,MGS,WMIRemover,RESIDUE -v -s"


############################################################################################################
#                       Sweep Remaining McAfee Registry Uninstall Entries                                  #
############################################################################################################

# Skip WebAdvisor — handled separately below
$InstalledPrograms = $allstring | Where-Object { ($_.Name -like "*McAfee*") -and ($_.Name -notlike "*WebAdvisor*") }
foreach ($p in $InstalledPrograms) {
    Write-Output "Attempting to uninstall: [$($p.Name)]..."
    $uninstallcommand = $p.String
    try {
        if ($uninstallcommand -match "^msiexec*") {
            $uninstallcommand = ($uninstallcommand -replace "msiexec.exe", "") + " /quiet /norestart"
            $uninstallcommand = $uninstallcommand -replace "/I", "/X "
            Start-Process 'msiexec.exe' -ArgumentList $uninstallcommand -NoNewWindow -Wait
        } else {
            Start-Process $uninstallcommand
        }
        Write-Output "Successfully uninstalled: [$($p.Name)]"
    } catch {
        Write-Warning "Failed to uninstall: [$($p.Name)]"
    }
}


############################################################################################################
#                                       McAfee Safe Connect                                                #
############################################################################################################

Get-ChildItem -Path HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall, HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall |
    Get-ItemProperty | Where-Object { $_.DisplayName -match "McAfee Safe Connect" } |
    ForEach-Object { if ($_.UninstallString) { cmd.exe /c $_.UninstallString /quiet /norestart } }


############################################################################################################
#                                  Leftover Start Menu / Registry                                          #
############################################################################################################

if (Test-Path "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\McAfee") {
    Remove-Item -Path "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\McAfee" -Recurse -Force
}
if (Test-Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\McAfee.WPS") {
    Remove-Item -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\McAfee.WPS" -Recurse -Force
}
Get-AppxProvisionedPackage -Online | Where-Object DisplayName -eq "McAfeeWPSSparsePackage" | Remove-AppxProvisionedPackage -Online -AllUsers


############################################################################################################
#                                            WebAdvisor                                                    #
############################################################################################################

if (Test-Path "${env:ProgramFiles(x86)}\McAfee\SiteAdvisor\Uninstall.exe") {
    Start-Process -FilePath "${env:ProgramFiles(x86)}\McAfee\SiteAdvisor\Uninstall.exe" -ArgumentList "/s" -WorkingDirectory "${env:ProgramFiles(x86)}\McAfee\SiteAdvisor" -Wait -NoNewWindow
}
Start-Sleep -Seconds 5
if (Test-Path "${env:ProgramFiles(x86)}\McAfee") {
    Remove-Item -Path "${env:ProgramFiles(x86)}\McAfee" -Recurse -Force
}


############################################################################################################
#                                                Done                                                      #
############################################################################################################

$stopUtc = [datetime]::UtcNow
$runTime = $stopUtc - $startUtc
if ($runTime.TotalHours -ge 1) {
    $runTimeFormatted = 'Duration: {0:hh} hr {0:mm} min {0:ss} sec' -f $runTime
} else {
    $runTimeFormatted = 'Duration: {0:mm} min {0:ss} sec' -f $runTime
}
Write-Output "Completed"
Write-Output "Total Script $($runTimeFormatted)"

$ProgressPreference = $OrginalProgressPreference
Stop-Transcript
