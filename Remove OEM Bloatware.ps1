<#
.SYNOPSIS
    Removes OEM bloatware (HP, Dell, Lenovo, Samsung, Acer, Asus) and McAfee
    from a fresh Windows build.

.DESCRIPTION
    Detects the system manufacturer and removes the matching pre-installed
    bloatware. Also runs the McAfee Consumer Product Removal Tool, since
    McAfee trial software is preinstalled by most OEMs.

    Adapted from Andrew Taylor's Win11Debloat / RemoveBloat script
    (https://andrewstaylor.com) — OEM components only.

.PARAMETER customwhitelist
    Comma-separated list of app names to keep, even if they appear in an
    OEM bloat list.

.OUTPUTS
    C:\ProgramData\Debloat\Debloat.log
#>

param (
    [string[]]$customwhitelist
)

##Elevate if needed
If (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]'Administrator')) {
    Write-Output "You didn't run this script as an Administrator. This script will self elevate to run as an Administrator and continue."
    Start-Sleep 1
    Start-Process powershell.exe -ArgumentList ("-NoProfile -ExecutionPolicy Bypass -File `"{0}`" -customwhitelist {1}" -f $PSCommandPath, ($customwhitelist -join ',')) -Verb RunAs
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
#                                            Whitelist                                                     #
############################################################################################################

$WhitelistedApps = @(
    'WavesAudio.MaxxAudioProforDell2019',
    'Dell Optimizer Core',
    'Dell SupportAssist Remediation',
    'Dell SupportAssist OS Recovery Plugin for Dell Update',
    'Dell Pair',
    'Dell Display Manager 2.0',
    'Dell Display Manager 2.1',
    'Dell Display Manager 2.2',
    'Dell Peripheral Manager'
)

if ($customwhitelist) {
    foreach ($whitelistapp in ($customwhitelist -split ",")) {
        $WhitelistedApps += $whitelistapp
    }
}
$appstoignore = $WhitelistedApps | Sort-Object -Unique


############################################################################################################
#                                          Helper Functions                                                #
############################################################################################################

function parseExeUninstall {
    param ([string]$exeString)
    $pattern = ' +(?=(?:[^\"]*\"[^\"]*\")*[^\"]*$)'
    return $exeString -split $pattern
}

function UninstallAppFull {
    param ([string]$appName)

    $installedApps = Get-ItemProperty HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*,
        HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* |
        Where-Object { $null -ne $_.DisplayName } |
        Select-Object DisplayName, UninstallString

    if ([System.Security.Principal.WindowsIdentity]::GetCurrent().Name -ne 'NT AUTHORITY\SYSTEM') {
        $userInstalledApps = Get-ItemProperty HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* |
            Where-Object { $null -ne $_.DisplayName } |
            Select-Object DisplayName, UninstallString
    }

    $allInstalledApps = @($installedApps) + @($userInstalledApps) | Where-Object { $_.DisplayName -eq "$appName" }

    foreach ($app in $allInstalledApps) {
        $uninstallString = $app.UninstallString
        $displayName = $app.DisplayName

        Write-Output "Calling Uninstaller for: $displayName"
        if ($uninstallString -match "^\s*(C:\\Windows\\System32\\)?msiexec(\.exe)?\s+\S*") {
            Write-Output "MSI Uninstall detected"
            $uninstallString -match '(?<content>{.*})' | Out-Null
            $GUID = $matches['content']
            $uninstallArgs = @('/X', $GUID, '/quiet', '/norestart', '/qn')
            $uninstaller = "msiexec.exe"
            try {
                Start-Process $uninstaller -ArgumentList $uninstallArgs
                Write-Output "Successfully called MSI Uninstaller for: $displayName"
            }
            catch {
                Write-Output "Failed to call MSI Uninstaller for: $displayName"
                Write-Output "Error: $($_.Exception.Message)"
            }
        }
        else {
            Write-Output "EXE Uninstall detected"
            $parsedString = parseExeUninstall -exeString $uninstallString
            $uninstallArgs = $parsedString | Select-Object -Skip 1
            $uninstaller = $parsedString[0]
            try {
                Start-Process $uninstaller -ArgumentList $uninstallArgs
                Write-Output "Successfully called EXE Uninstaller for: $displayName"
            }
            catch {
                Write-Output "Failed to call EXE Uninstaller for: $displayName"
                Write-Output "Error: $($_.Exception.Message)"
            }
        }
    }
}

function Invoke-PatternUninstall {
    # Iterates a list of name patterns, finds matching uninstall registry keys,
    # tries UninstallAppFull, then falls back to running the uninstall string directly.
    param (
        [string[]]$Patterns
    )

    $registryPaths = @(
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
        "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"
    )

    foreach ($pattern in $Patterns) {
        Write-Output "Checking for packages matching pattern: $pattern"
        $matchingPackages = @()
        foreach ($registryPath in $registryPaths) {
            $matchingPackages += Get-ItemProperty -Path $registryPath -ErrorAction SilentlyContinue |
                Where-Object { $_.DisplayName -match $pattern }
        }

        if ($matchingPackages.Count -eq 0) {
            Write-Output "No packages found matching pattern: $pattern"
            continue
        }

        Write-Output "Found $($matchingPackages.Count) package(s) matching pattern: $pattern"

        foreach ($package in $matchingPackages) {
            $displayName = $package.DisplayName
            $uninstallString = $package.UninstallString
            $quietUninstallString = $package.QuietUninstallString
            $version = $package.DisplayVersion

            Write-Output "Attempting to uninstall: $displayName (Version: $version)"
            UninstallAppFull -appName $displayName

            if ($quietUninstallString) {
                try {
                    if ($quietUninstallString -match "msiexec") {
                        Start-Process "cmd.exe" -ArgumentList "/c $($quietUninstallString) /quiet" -Wait -NoNewWindow
                    } else {
                        $uninstallParts = $quietUninstallString -split ' ', 2
                        $uninstallExe = $uninstallParts[0].Trim('"')
                        $uninstallArgs = if ($uninstallParts.Count -gt 1) { $uninstallParts[1] } else { "" }
                        Start-Process -FilePath $uninstallExe -ArgumentList $uninstallArgs -Wait -NoNewWindow
                    }
                } catch {
                    Write-Output "Error during quiet uninstall: $_"
                }
            } elseif ($uninstallString) {
                try {
                    if ($uninstallString -match "msiexec") {
                        if ($uninstallString -match "/I{") {
                            $uninstallString = $uninstallString -replace "/I", "/X"
                        }
                        Start-Process "cmd.exe" -ArgumentList "/c $($uninstallString) /quiet" -Wait -NoNewWindow
                    } else {
                        $uninstallParts = $uninstallString -split ' ', 2
                        $uninstallExe = $uninstallParts[0].Trim('"')
                        $uninstallArgs = if ($uninstallParts.Count -gt 1) { $uninstallParts[1] } else { "" }
                        if ($uninstallString -match "uninstall.exe|uninst.exe|setup.exe|installer.exe") {
                            $uninstallArgs += " /S /silent /quiet /uninstall"
                        }
                        Start-Process -FilePath $uninstallExe -ArgumentList $uninstallArgs -Wait -NoNewWindow
                    }
                } catch {
                    Write-Output "Error during standard uninstall: $_"
                }
            } else {
                Write-Output "No uninstall string found for: $displayName"
            }
        }
    }
}

function UninstallApp {
    # Lenovo helper: matches by wildcard and runs the uninstaller silently
    param ([string]$appName)
    $installedApps = Get-ItemProperty HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*,
        HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* |
        Where-Object { $_.DisplayName -like "*$appName*" }
    foreach ($app in $installedApps) {
        Write-Output "Uninstalling: $($app.DisplayName)"
        Start-Process $app.UninstallString -ArgumentList "/VERYSILENT" -Wait
        Write-Output "Uninstalled: $($app.DisplayName)"
    }
}


############################################################################################################
#                                  Build All Uninstall Strings                                             #
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
#                                       Detect Manufacturer                                                #
############################################################################################################

Write-Output "Detecting Manufacturer"
$details = Get-CimInstance -ClassName Win32_ComputerSystem
$manufacturer = $details.Manufacturer


############################################################################################################
#                                              HP Bloat                                                    #
############################################################################################################

if ($manufacturer -like "*HP*") {
    Write-Output "HP detected"

    $UninstallPrograms = @(
        "Poly Lens"
        "HP Client Security Manager"
        "HP Notifications"
        "HP Security Update Service"
        "HP System Default Settings"
        "HP Wolf Security"
        "HP Wolf Security - Console"
        "HP Wolf Security Application Support for Sure Sense"
        "HP Wolf Security Application Support for Windows"
        "HP Wolf Security Application Support for Chrome 122.0.6261.139"
        "AD2F1837.HPPCHardwareDiagnosticsWindows"
        "AD2F1837.HPPowerManager"
        "AD2F1837.HPPrivacySettings"
        "AD2F1837.HPQuickDrop"
        "AD2F1837.HPSupportAssistant"
        "AD2F1837.HPSystemInformation"
        "AD2F1837.myHP"
        "RealtekSemiconductorCorp.HPAudioControl"
        "HP Sure Recover"
        "HP Sure Run Module"
        "RealtekSemiconductorCorp.HPAudioControl_2.39.280.0_x64__dt26b99r8h8gj"
        "Windows Driver Package - HP Inc. sselam_4_4_2_453 AntiVirus  (11/01/2022 4.4.2.453)"
        "HP Insights"
        "HP Insights Analytics"
        "HP Insights Analytics Service"
        "HP Insights Analytics - Dependencies"
        "HP Performance Advisor"
        "HP Presence Video"
        "HP Audio Control"
        "HP Documentation"
        "AD2F1837.HPAudioControl"
        "HP Connect Optimizer"
    )
    $UninstallPrograms = $UninstallPrograms | Where-Object { $appstoignore -notcontains $_ }

    foreach ($app in $UninstallPrograms) {
        if (Get-AppxProvisionedPackage -Online | Where-Object DisplayName -like $app -ErrorAction SilentlyContinue) {
            Get-AppxProvisionedPackage -Online | Where-Object DisplayName -like $app | Remove-AppxProvisionedPackage -Online
            Write-Output "Removed provisioned package for $app."
        }
        if (Get-AppxPackage -allusers -Name $app -ErrorAction SilentlyContinue) {
            Get-AppxPackage -allusers -Name $app | Remove-AppxPackage -AllUsers
            Write-Output "Removed $app."
        }
        if (Get-Package -scope allusers -Name $app -ErrorAction SilentlyContinue) {
            Get-Package -scope allusers -Name $app | Uninstall-Package -scope AllUsers
            Write-Output "Removed $app via Get-Package."
        }
        UninstallAppFull -appName $app
    }

    if (Test-Path -Path "C:\Program Files\HP\Documentation\Doc_uninstall.cmd") {
        Start-Process -FilePath "C:\Program Files\HP\Documentation\Doc_uninstall.cmd" -Wait -PassThru -NoNewWindow
    }

    if (Test-Path -Path 'C:\Program Files (x86)\InstallShield Installation Information\{6468C4A5-E47E-405F-B675-A70A70983EA6}\setup.exe') {
        Invoke-WebRequest -Uri "https://raw.githubusercontent.com/andrew-s-taylor/public/main/De-Bloat/HPConnOpt.iss" -OutFile "C:\Windows\Temp\HPConnOpt.iss"
        & 'C:\Program Files (x86)\InstallShield Installation Information\{6468C4A5-E47E-405F-B675-A70A70983EA6}\setup.exe' @('-s', '-f1C:\Windows\Temp\HPConnOpt.iss')
    }

    if (Test-Path -Path 'C:\Program Files\HP\Z By HP Data Science Stack Manager\Uninstall Z by HP Data Science Stack Manager.exe') {
        & 'C:\Program Files\HP\Z By HP Data Science Stack Manager\Uninstall Z by HP Data Science Stack Manager.exe' @('/allusers', '/S')
    }

    foreach ($p in @(
        "C:\Program Files (x86)\HP\Shared",
        "C:\Program Files (x86)\Online Services",
        "C:\ProgramData\HP\TCO"
    )) {
        if (Test-Path -Path $p -PathType Container) { Remove-Item -Path $p -Recurse -Force }
    }
    foreach ($f in @(
        "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Amazon.com.lnk",
        "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Angebote.lnk",
        "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\TCO Certified.lnk",
        "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Booking.com.lnk",
        "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Adobe offers.lnk",
        "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Miro Offer.lnk"
    )) {
        if (Test-Path -Path $f -PathType Leaf) { Remove-Item -Path $f -Force }
    }

    Write-Output "Starting HP security package uninstallation process"
    Invoke-PatternUninstall -Patterns @(
        "HP Client Security Manager",
        "HP Wolf Security(?!.*Console)",
        "HP Wolf Security.*Console",
        "HP Security Update Service"
    )
}


############################################################################################################
#                                             Dell Bloat                                                   #
############################################################################################################

if ($manufacturer -like "*Dell*") {
    Write-Output "Dell detected"

    $UninstallPrograms = @(
        "Dell Power Manager"
        "DellOptimizerUI"
        "Dell SupportAssist OS Recovery"
        "Dell SupportAssist"
        "DellInc.PartnerPromo"
        "DellInc.DellOptimizer"
        "DellInc.DellCommandUpdate"
        "DellInc.DellPowerManager"
        "DellInc.DellDigitalDelivery"
        "DellInc.DellSupportAssistforPCs"
        "Dell Command | Update"
        "Dell Command | Update for Windows Universal"
        "Dell Command | Update for Windows 10"
        "Dell Command | Power Manager"
        "Dell Digital Delivery Service"
        "Dell Digital Delivery"
        "Dell Peripheral Manager"
        "Dell Power Manager Service"
        "Dell SupportAssist Remediation"
        "SupportAssist Recovery Assistant"
        "Dell SupportAssist OS Recovery Plugin for Dell Update"
        "Dell SupportAssistAgent"
        "Dell Update - SupportAssist Update Plugin"
        "Dell Core Services"
        "Dell Pair"
        "Dell Display Manager 2.0"
        "Dell Display Manager 2.1"
        "Dell Display Manager 2.2"
        "Dell Trusted Device"
    )
    $UninstallPrograms = $UninstallPrograms | Where-Object { $appstoignore -notcontains $_ }

    foreach ($app in $UninstallPrograms) {
        if (Get-AppxProvisionedPackage -Online | Where-Object DisplayName -like $app -ErrorAction SilentlyContinue) {
            Get-AppxProvisionedPackage -Online | Where-Object DisplayName -like $app | Remove-AppxProvisionedPackage -Online
            Write-Output "Removed provisioned package for $app."
        }
        if (Get-AppxPackage -allusers -Name $app -ErrorAction SilentlyContinue) {
            Get-AppxPackage -allusers -Name $app | Remove-AppxPackage -AllUsers
            Write-Output "Removed $app."
        }
        UninstallAppFull -appName $app
    }

    Invoke-PatternUninstall -Patterns $UninstallPrograms

    # Dell Optimizer Core
    Get-ChildItem -Path HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall, HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall |
        Get-ItemProperty | Where-Object { $_.DisplayName -like "Dell*Optimizer*Core" } |
        ForEach-Object { if ($_.UninstallString) { try { cmd.exe /c $_.UninstallString -silent } catch { Write-Warning "Failed to uninstall Dell Optimizer Core" } } }

    # Dell Optimizer
    Get-ChildItem -Path HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall, HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall |
        Get-ItemProperty | Where-Object { $_.DisplayName -like "Dell*Optimizer" } |
        ForEach-Object { if ($_.UninstallString) { try { cmd.exe /c $_.UninstallString -silent } catch { Write-Warning "Failed to uninstall Dell Optimizer" } } }

    # Dell SupportAssist Remediation
    Get-ChildItem -Path HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall, HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall |
        Get-ItemProperty | Where-Object { $_.DisplayName -match "Dell SupportAssist Remediation" } |
        ForEach-Object { if ($_.QuietUninstallString) { try { cmd.exe /c $_.QuietUninstallString } catch { Write-Warning "Failed to uninstall Dell Support Assist Remediation" } } }

    # Dell SupportAssist OS Recovery Plugin for Dell Update
    Get-ChildItem -Path HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall, HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall |
        Get-ItemProperty | Where-Object { $_.DisplayName -match "Dell SupportAssist OS Recovery Plugin for Dell Update" } |
        ForEach-Object { if ($_.QuietUninstallString) { try { cmd.exe /c $_.QuietUninstallString } catch { Write-Warning "Failed to uninstall Dell Support OS Recovery Plugin" } } }

    # Dell Display Manager
    Get-ChildItem -Path HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall, HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall |
        Get-ItemProperty | Where-Object { $_.DisplayName -like "Dell*Display*Manager*" } |
        ForEach-Object { if ($_.UninstallString) { try { cmd.exe /c $_.UninstallString /S } catch { Write-Warning "Failed to uninstall Dell Display Manager" } } }

    try { Start-Process c:\windows\system32\cmd.exe '/c "C:\Program Files\Dell\Dell Peripheral Manager\Uninstall.exe" /S' }
    catch { Write-Warning "Failed to uninstall Dell Peripheral Manager" }

    try { Start-Process c:\windows\system32\cmd.exe '/c "C:\Program Files\Dell\Dell Pair\Uninstall.exe" /S' }
    catch { Write-Warning "Failed to uninstall Dell Pair" }
}


############################################################################################################
#                                             Lenovo Bloat                                                 #
############################################################################################################

if ($manufacturer -like "Lenovo") {
    Write-Output "Lenovo detected"

    $processnames = @(
        "SmartAppearanceSVC.exe", "UDClientService.exe", "ModuleCoreService.exe",
        "ProtectedModuleHost.exe", "*lenovo*", "FaceBeautify.exe", "McCSPServiceHost.exe",
        "mcapexe.exe", "MfeAVSvc.exe", "mcshield.exe", "Ammbkproc.exe", "AIMeetingManager.exe",
        "DADUpdater.exe", "CommercialVantage.exe", "lenovo ainow.exe", "lenovo ainow helper.exe",
        "lenovo ainow service.exe", "lenovo ainow utility.exe", "lenovo ainow mini.exe",
        "lenovo ainow oobe.exe", "lenovo ainow safetychecker.exe", "lenovo ainow launcher.exe",
        "lenovoainow.exe"
    )
    foreach ($process in $processnames) {
        Write-Output "Stopping Process $process"
        Get-Process -Name $process | Stop-Process -Force
    }

    $UninstallPrograms = @(
        "E046963F.AIMeetingManager"
        "E0469640.SmartAppearance"
        "MirametrixInc.GlancebyMirametrix"
        "E046963F.LenovoCompanion"
        "E0469640.LenovoUtility"
        "E0469640.LenovoSmartCommunication"
        "E046963F.LenovoSettingsforEnterprise"
        "E046963F.cameraSettings"
        "4505Fortemedia.FMAPOControl2_2.1.37.0_x64__4pejv7q2gmsnr"
        "ElevocTechnologyCo.Ltd.SmartMicrophoneSettings_1.1.49.0_x64__ttaqwwhyt5s6t"
        "Lenovo User Guide"
        "TrackPoint Quick Menu"
        "E0469640.TrackPointQuickMenu"
        "Lenovo AI Now"
        "Lenovo Subscription Marketplace"
    )
    $UninstallPrograms = $UninstallPrograms | Where-Object { $appstoignore -notcontains $_ }

    foreach ($app in $UninstallPrograms) {
        if (Get-AppxProvisionedPackage -Online | Where-Object DisplayName -like $app -ErrorAction SilentlyContinue) {
            Get-AppxProvisionedPackage -Online | Where-Object DisplayName -like $app | Remove-AppxProvisionedPackage -Online
            Write-Output "Removed provisioned package for $app."
        }
        if (Get-AppxPackage -allusers -Name $app -ErrorAction SilentlyContinue) {
            Get-AppxPackage -allusers -Name $app | Remove-AppxPackage -AllUsers
            Write-Output "Removed $app."
        }
        UninstallAppFull -appName $app
    }

    # Lenovo Vantage Service
    $lvs = Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*", "HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*" |
        Where-Object DisplayName -eq "Lenovo Vantage Service"
    if (![string]::IsNullOrEmpty($lvs.QuietUninstallString)) {
        Invoke-Expression ("cmd /c " + $lvs.QuietUninstallString)
    }

    UninstallApp -appName "Lenovo Smart"
    UninstallApp -appName "Ai Meeting Manager"

    # ImController service
    $path = "c:\windows\system32\ImController.InfInstaller.exe"
    if (Test-Path $path) {
        Invoke-Expression ("cmd /c " + $path + " -uninstall")
    }

    Remove-Item 'HKLM:\SOFTWARE\Policies\Lenovo\E046963F.LenovoCompanion_k1h2ywk1493x8' -Recurse -ErrorAction SilentlyContinue
    Remove-Item 'HKLM:\SOFTWARE\Policies\Lenovo\ImController' -Recurse -ErrorAction SilentlyContinue
    Remove-Item 'HKLM:\SOFTWARE\Policies\Lenovo\Lenovo Vantage' -Recurse -ErrorAction SilentlyContinue

    # Silent uninstallers at known paths
    $silentUninstallers = @(
        @{ Path = 'C:\Program Files\Lenovo\Ai Meeting Manager Service\unins000.exe'; Args = '/SILENT' },
        @{ Path = 'C:\Program Files (x86)\Lenovo\LenovoNow\unins000.exe';            Args = '/SILENT' },
        @{ Path = 'C:\Program Files\Lenovo\Ready For Assistant\uninstall.exe';       Args = '/S' },
        @{ Path = 'C:\Program Files\Lenovo\Lenovo Smart Appearance Components\unins000.exe'; Args = '/SILENT' }
    )
    foreach ($u in $silentUninstallers) {
        if (Test-Path -Path $u.Path) {
            try { Start-Process -FilePath $u.Path -ArgumentList $u.Args -Wait }
            catch { Write-Warning "Failed to start uninstaller at $($u.Path)" }
        }
    }

    # Lenovo Vantage Service (versioned path)
    $vantagePath = "C:\Program Files (x86)\Lenovo\VantageService"
    if (Test-Path $vantagePath) {
        $pathname = (Get-ChildItem -Path $vantagePath).Name
        $path = "$vantagePath\$pathname\Uninstall.exe"
        if (Test-Path -Path $path) {
            Start-Process -FilePath $path -ArgumentList '/SILENT' -Wait
        }
    }

    # LenovoWelcome / LenovoNow uninstall.ps1 scripts
    foreach ($folder in @(
        "c:\program files (x86)\lenovo\lenovowelcome\x86",
        "c:\program files (x86)\lenovo\LenovoNow\x86"
    )) {
        if (Test-Path $folder) {
            Set-Location $folder
            try { Invoke-Expression -Command .\uninstall.ps1 -ErrorAction SilentlyContinue }
            catch { Write-Output "Failed to execute uninstall.ps1 in $folder" }
        }
    }

    # Lenovo Start Menu / docs cleanup
    foreach ($f in @(
        "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\User Guide.lnk",
        "C:\Users\All Users\Microsoft\Windows\Start Menu\Programs\Benutzerhandbuch.url",
        "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Benutzerhandbuch.url"
    )) {
        if (Test-Path $f) { Remove-Item -Path $f -Force }
    }
    if (Test-Path "C:\ProgramData\Lenovo\UserGuide") {
        Remove-Item -Path "C:\ProgramData\Lenovo\UserGuide" -Recurse -Force
    }

    # Camera fix for Lenovo E14
    $model = Get-CimInstance -ClassName Win32_ComputerSystem | Select-Object -ExpandProperty Model
    if ($model -eq "21E30001MY") {
        foreach ($keypath in @(
            "HKLM:\SOFTWARE\Microsoft\Windows Media Foundation\Platform",
            "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows Media Foundation\Platform"
        )) {
            if (!(Test-Path $keypath)) { New-Item -Path $keypath -Force | Out-Null }
            Set-ItemProperty -Path $keypath -Name "EnableFrameServerMode" -Value 0 -Type DWord -Force
        }
    }

    # Remove Lenovo theme and background image
    $registryPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes"
    foreach ($name in @("ThemeName", "DesktopBackground")) {
        if (Get-ItemProperty -Path $registryPath -Name $name -ErrorAction SilentlyContinue) {
            Remove-ItemProperty -Path $registryPath -Name $name
        }
    }

    # X-Rite Color Assistant
    $xritePath = "C:\Program Files (x86)\X-Rite Color Assistant\unins000.exe"
    if (Test-Path $xritePath) {
        Start-Process -FilePath $xritePath -ArgumentList "/SILENT" -Wait
        Write-Output "X-Rite Color Assistant uninstalled."
    }

    Write-Output "Stopping and disabling Lenovo UDC Service"
    Stop-Service "UDCService"
    Set-Service "UDCService" -StartupType Disabled
}


############################################################################################################
#                                            Samsung Bloat                                                 #
############################################################################################################

if ($manufacturer -like "*Samsung*") {
    Write-Output "Samsung detected"

    $UninstallPrograms = @(
        "ColorEngine"
        "Display Profile"
        "Galaxy Book Smart Switch service"
        "Live Wallpaper Service"
        "Quick Search Service"
        "Samsung Recovery Service"
        "Samsung Update Service"
        "Studio mode"
        "Bixby"
        "Galaxy Book Experience"
        "Galaxy Book Smart Switch"
        "Goodnotes for GalaxyBook"
        "Live Wallpaper"
        "Multi Control"
        "Quick Search"
        "Quick Share"
        "Samsung Account"
        "Samsung Analytics Agent"
        "Samsung Care+"
        "Samsung Cloud"
        "Samsung Continuity Service"
        "Samsung Device Care"
        "Samsung Flow"
        "Samsung Gallery"
        "Samsung Notes"
        "Samsung Recovery"
        "Samsung Settings"
        "Samsung Settings Runtime"
        "Samsung Studio"
        "Samsung Studio for Gallery"
        "Samsung Update"
        "SamsungPhone"
        "Screen Recorder"
        "Second Screen"
        "SmartThings"
    )
    $UninstallPrograms = $UninstallPrograms | Where-Object { $appstoignore -notcontains $_ }

    foreach ($app in $UninstallPrograms) {
        if (Get-AppxProvisionedPackage -Online | Where-Object DisplayName -like $app -ErrorAction SilentlyContinue) {
            Get-AppxProvisionedPackage -Online | Where-Object DisplayName -like $app | Remove-AppxProvisionedPackage -Online
            Write-Output "Removed provisioned package for $app."
        }
        if (Get-AppxPackage -allusers -Name $app -ErrorAction SilentlyContinue) {
            Get-AppxPackage -allusers -Name $app | Remove-AppxPackage -AllUsers
            Write-Output "Removed $app."
        }
        UninstallAppFull -appName $app
    }

    Invoke-PatternUninstall -Patterns $UninstallPrograms
    Write-Output "Removed Samsung bloat"
}


############################################################################################################
#                                             Acer Bloat                                                   #
############################################################################################################

if ($manufacturer -like "*Acer*") {
    Write-Output "Acer detected"

    foreach ($process in @("ACCSvc.exe", "QASvc.exe", "ProShieldService.exe")) {
        Write-Output "Stopping Process $process"
        Get-Process -Name $process | Stop-Process -Force
    }

    $UninstallPrograms = @(
        "Acer Configuration Manager"
        "Acer Jumpstart"
        "Acer Product Registration"
        "Acer ProShield Plus"
        "Acer ProShield Plus Service"
        "Acer Purified Voice Console"
        "Acer Control Centre"
        "Acer Quick Access"
        "Acer Quick Access Service"
        "Password Generator Tool"
        "Evernote"
        "Dropbox promotion"
        "Acer User Experience Improvement Program Service"
        "DriverSetupUtility"
        "ControlCenter Service"
        "McAfee LiveSafe"
        "Quick Access Service"
        "User Experience Improvement Program Service"
        "McAfee.wps"
        "McAfeeWPSSparsePackage"
        "Evernote.Evernote"
        "C27EB4BA.DropboxOEM"
        "{2B51C83A-465D-4EA9-9CDC-1ED95ED09AC6}"
        "InsydeSoftwareCorp.AcerProShieldPlus"
        "DTSInc.DTSAudioProcessing"
        "AppUp.IntelOptaneMemoryandStorageManagement"
        "AcerIncorporated.QuickAccess"
        "AcerIncorporated.AcerRegistration"
        "AcerIncorporated.4703949AD09F"
        "AcerIncorporated.AcerPurifiedVoiceConsoleR"
        "55121DominqueTerry.PasswordGeneratorTool"
    )
    $UninstallPrograms = $UninstallPrograms | Where-Object { $appstoignore -notcontains $_ }

    foreach ($app in $UninstallPrograms) {
        if (Get-AppxProvisionedPackage -Online | Where-Object DisplayName -like $app -ErrorAction SilentlyContinue) {
            Get-AppxProvisionedPackage -Online | Where-Object DisplayName -like $app | Remove-AppxProvisionedPackage -Online
            Write-Output "Removed provisioned package for $app."
        }
        if (Get-AppxPackage -allusers -Name $app -ErrorAction SilentlyContinue) {
            Get-AppxPackage -allusers -Name $app | Remove-AppxPackage -AllUsers
            Write-Output "Removed $app."
        }
        UninstallAppFull -appName $app
    }

    Invoke-PatternUninstall -Patterns $UninstallPrograms
    Write-Output "Removed Acer bloat"
}


############################################################################################################
#                                             Asus Bloat                                                   #
############################################################################################################

if ($manufacturer -like "*Asus*") {
    Write-Output "Asus detected"

    $UninstallPrograms = @(
        "B9ECED6F.ASUSExpertWidget"                          # F1-F4 hotkeys on Expertbook
        "B9ECED6F.ASUSPCAssistant"                           # MyAsus on Expertbook, Vivobook
        "AppUp.IntelGraphicsExperience"                      # Intel Graphic mgmt utility
        "AppUp.IntelManagementandSecurityStatus"             # Intel Security mgmt utility
        "DolbyLaboratories.DolbyAccess"                      # Dolby sound utilities
        "DolbyLaboratories.DolbyDigitalPlusDecoderOEM"       # Dolby sound utilities
        "DrivewintechTechnologyCo.DiracAudoManager"          # Sound mgmt utility
        "IntelligoTechnologyInc.541271065CCE8"               # Voice/microphone AI suite
    )
    $UninstallPrograms = $UninstallPrograms | Where-Object { $appstoignore -notcontains $_ }

    foreach ($app in $UninstallPrograms) {
        if (Get-AppxProvisionedPackage -Online | Where-Object DisplayName -like $app -ErrorAction SilentlyContinue) {
            Get-AppxProvisionedPackage -Online | Where-Object DisplayName -like $app | Remove-AppxProvisionedPackage -Online
            Write-Output "Removed provisioned package for $app."
        }
        if (Get-AppxPackage -allusers -Name $app -ErrorAction SilentlyContinue) {
            Get-AppxPackage -allusers -Name $app | Remove-AppxPackage -AllUsers
            Write-Output "Removed $app."
        }
        UninstallAppFull -appName $app
    }

    # Remove Asus theme and background image
    $registryPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes"
    foreach ($name in @("ThemeName", "DesktopBackground")) {
        if (Get-ItemProperty -Path $registryPath -Name $name -ErrorAction SilentlyContinue) {
            Remove-ItemProperty -Path $registryPath -Name $name
        }
    }

    # Clear OEM taskbar layout (only if it predates this script run, so we don't touch user customization)
    $tbfile = "C:\Windows\OEM\TaskbarLayoutModification.xml"
    if ((Test-Path -Path $tbfile -PathType Leaf) -and ((Get-Item $tbfile).LastWriteTimeUtc -lt $startUtc)) {
        Remove-Item -Path $tbfile -Force
    }
    $registryPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer"
    $reg = Get-ItemProperty -Path $registryPath -ErrorAction SilentlyContinue
    if (($reg -and $reg.PSObject.Properties.Name -contains "LayoutXMLPath") -and ($reg.LayoutXMLPath -ieq $tbfile)) {
        Remove-ItemProperty -Path $registryPath -Name "LayoutXMLPath" -ErrorAction SilentlyContinue
    }
}


############################################################################################################
#                                              McAfee                                                      #
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

if ($mcafeeinstalled) {
    Write-Output "McAfee detected"

    # Original Mccleanup
    Write-Output "Downloading McAfee Removal Tool"
    $URL = 'https://github.com/andrew-s-taylor/public/raw/main/De-Bloat/mcafeeclean.zip'
    $destination = 'C:\ProgramData\Debloat\mcafee.zip'
    Invoke-WebRequest -Uri $URL -OutFile $destination -Method Get
    Expand-Archive $destination -DestinationPath "C:\ProgramData\Debloat" -Force

    Start-Process "C:\ProgramData\Debloat\Mccleanup.exe" -ArgumentList "-p StopServices,MFSY,PEF,MXD,CSP,Sustainability,MOCP,MFP,APPSTATS,Auth,EMproxy,FWdiver,HW,MAS,MAT,MBK,MCPR,McProxy,McSvcHost,VUL,MHN,MNA,MOBK,MPFP,MPFPCU,MPS,SHRED,MPSCU,MQC,MQCCU,MSAD,MSHR,MSK,MSKCU,MWL,NMC,RedirSvc,VS,REMEDIATION,MSC,YAP,TRUEKEY,LAM,PCB,Symlink,SafeConnect,MGS,WMIRemover,RESIDUEFWDRIVER,Redir,MSHR,WPS,MSSPlus -v -s"

    # Newer Mccleanup
    Write-Output "Downloading McAfee Removal Tool (new)"
    $URL = 'https://github.com/andrew-s-taylor/public/raw/main/De-Bloat/mccleanup.zip'
    $destination = 'C:\ProgramData\Debloat\mcafeenew.zip'
    Invoke-WebRequest -Uri $URL -OutFile $destination -Method Get
    New-Item -Path "C:\ProgramData\Debloat\mcnew" -ItemType Directory -Force | Out-Null
    Expand-Archive $destination -DestinationPath "C:\ProgramData\Debloat\mcnew" -Force

    Start-Process "C:\ProgramData\Debloat\mcnew\Mccleanup.exe" -ArgumentList "-p StopServices,MFSY,PEF,MXD,CSP,Sustainability,MOCP,MFP,APPSTATS,Auth,EMproxy,FWdiver,HW,MAS,MAT,MBK,MCPR,McProxy,McSvcHost,VUL,MHN,MNA,MOBK,MPFP,MPFPCU,MPS,SHRED,MPSCU,MQC,MQCCU,MSAD,MSHR,MSK,MSKCU,MWL,NMC,RedirSvc,VS,REMEDIATION,MSC,YAP,TRUEKEY,LAM,PCB,Symlink,SafeConnect,MGS,WMIRemover,RESIDUE -v -s"

    # Uninstall any McAfee entries left in the registry (excluding WebAdvisor — handled separately)
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

    # McAfee Safe Connect
    Get-ChildItem -Path HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall, HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall |
        Get-ItemProperty | Where-Object { $_.DisplayName -match "McAfee Safe Connect" } |
        ForEach-Object { if ($_.UninstallString) { cmd.exe /c $_.UninstallString /quiet /norestart } }

    # Leftover Start Menu / registry items
    if (Test-Path "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\McAfee") {
        Remove-Item -Path "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\McAfee" -Recurse -Force
    }
    if (Test-Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\McAfee.WPS") {
        Remove-Item -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\McAfee.WPS" -Recurse -Force
    }
    Get-AppxProvisionedPackage -Online | Where-Object DisplayName -eq "McAfeeWPSSparsePackage" | Remove-AppxProvisionedPackage -Online -AllUsers

    # WebAdvisor
    if (Test-Path "${env:ProgramFiles(x86)}\McAfee\SiteAdvisor\Uninstall.exe") {
        Start-Process -FilePath "${env:ProgramFiles(x86)}\McAfee\SiteAdvisor\Uninstall.exe" -ArgumentList "/s" -WorkingDirectory "${env:ProgramFiles(x86)}\McAfee\SiteAdvisor" -Wait -NoNewWindow
    }
    Start-Sleep -Seconds 5
    if (Test-Path "${env:ProgramFiles(x86)}\McAfee") {
        Remove-Item -Path "${env:ProgramFiles(x86)}\McAfee" -Recurse -Force
    }
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
