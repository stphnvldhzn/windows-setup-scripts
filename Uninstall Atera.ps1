<#
.SYNOPSIS
    Uninstalls the Atera Agent and the Splashtop components it bundles.

.DESCRIPTION
    Forcibly terminates Atera processes, then uninstalls AteraAgent,
    Splashtop for RMM, and Splashtop Streamer via msiexec. Stops and
    deletes the related services, removes registry keys, and cleans up
    leftover program directories.

    Combined from two SharePoint-hosted helpers:
      - AteraTaskKill.bat   (process termination)
      - ateraremoval.ps1    (uninstall + cleanup)
#>

# Self-elevate the script if required
if (-Not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] 'Administrator')) {
    if ([int](Get-CimInstance -Class Win32_OperatingSystem | Select-Object -ExpandProperty BuildNumber) -ge 6000) {
        $CommandLine = "-File `"" + $MyInvocation.MyCommand.Path + "`" " + $MyInvocation.UnboundArguments
        Start-Process -FilePath PowerShell.exe -Verb Runas -ArgumentList $CommandLine
        Exit
    }
}

############################################################################################################
#                                          Helper Functions                                                #
############################################################################################################

Function Get-UninstallCodes ([string]$DisplayName) {
    'HKLM:SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall', 'HKLM:SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall' | ForEach-Object {
        Get-ChildItem -Path $_ -ErrorAction SilentlyContinue | ForEach-Object {
            If ( $(Get-ItemProperty -Path $_.PSPath -Name 'DisplayName' -ErrorAction SilentlyContinue) -and ($(Get-ItemPropertyValue -Path $_.PSPath -Name 'DisplayName' -ErrorAction SilentlyContinue) -eq $DisplayName) ) {
                $str = (Get-ItemPropertyValue -Path $_.PSPath -Name 'UninstallString')
                $UninstallCodes.Add($str.Substring(($str.Length - 37), 36)) | Out-Null
            }
        }
    }
}

Function Get-ProductKeys ([string]$ProductName) {
    Get-ChildItem -Path 'HKCR:Installer\Products' | ForEach-Object {
        If ( $(Get-ItemProperty -Path $_.PSPath -Name 'ProductName' -ErrorAction SilentlyContinue) -and ($(Get-ItemPropertyValue -Path $_.PSPath -Name 'ProductName' -ErrorAction SilentlyContinue) -eq $ProductName) ) {
            $ProductKeys.Add($_.PSPath.Substring(($_.PSPath.Length - 32))) | Out-Null
        }
    }
}

Function Get-ServiceStatus ([string]$Name) { (Get-Service -Name $Name -ErrorAction SilentlyContinue).Status }

Function Stop-RunningService ([string]$Name) {
    If ( $(Get-ServiceStatus -Name $Name) -eq "Running" ) {
        Write-Output "Stopping : ${Name} service"
        Stop-Service -Name $Name -Force
    }
}

Function Remove-StoppedService ([string]$Name) {
    $s = (Get-ServiceStatus -Name $Name)
    If ( $s ) {
        If ( $s -eq "Stopped" ) {
            Write-Output "Deleting : ${Name} service"
            Start-Process "sc.exe" -ArgumentList "delete ${Name}" -Wait
        }
    } Else { Write-Output "Not Found: ${Name} service" }
}

Function Stop-RunningProcess ([string]$Name) {
    $p = (Get-Process -Name $Name -ErrorAction SilentlyContinue)
    If ( $p ) {
        Write-Output "Stopping : ${Name}.exe"
        $p | Stop-Process -Force
    } Else {
        Write-Output "Not Found: ${Name}.exe is not running"
    }
}

Function Remove-Path ([string]$Path) {
    If ( Test-Path $Path ) {
        Write-Output "Deleting : ${Path}"
        Remove-Item $Path -Recurse -Force
    } Else { Write-Output "Not Found: ${Path}" }
}

Function Get-AllExeFiles ([string]$Path) {
    If ( Test-Path $Path ) {
        Get-ChildItem -Path $Path -Filter *.exe -Recurse | ForEach-Object { $ExeFiles.Add($_.BaseName) | Out-Null }
    }
}

# Mount HKEY_CLASSES_ROOT registry hive
New-PSDrive -Name HKCR -PSProvider Registry -Root HKEY_CLASSES_ROOT | Out-Null


############################################################################################################
#                          Kill known Atera processes (from AteraTaskKill.bat)                             #
############################################################################################################

$KnownProcesses = @(
    'AteraAgent',
    'Agent.Package.Availability',
    'TicketingTray',
    'AgentPackageMonitoring',
    'AgentPackageInformation',
    'AgentPackageRunCommandInteractive',
    'AgentPackageEventViewer',
    'AgentPackageSTRemote',
    'AgentPackageInternalPoller',
    'AgentPackageWindowsUpdate',
    'AgentPackageSystemTools',
    'AgentPackageHeartbeat',
    'AgentPackageUpgradeAgent',
    'AgentPackageProgramManagement',
    'AgentPackageRegistryExplorer'
)
$KnownProcesses | ForEach-Object { Stop-RunningProcess -Name $_ }


############################################################################################################
#                                       Information Gathering                                             #
############################################################################################################

# MSI package codes from the uninstall key
$UninstallCodes = New-Object System.Collections.ArrayList
'AteraAgent', 'Splashtop for RMM', 'Splashtop Streamer' | ForEach-Object { Get-UninstallCodes -DisplayName $_ }

# Product keys from the list of installed products
$ProductKeys = New-Object System.Collections.ArrayList
'AteraAgent', 'Splashtop for RMM', 'Splashtop Streamer' | ForEach-Object { Get-ProductKeys -ProductName $_ }

# Directories to clean up at the end
$Directories = @(
    "${Env:ProgramFiles}\ATERA Networks",
    "${Env:ProgramFiles(x86)}\ATERA Networks",
    "${Env:ProgramFiles}\Splashtop\Splashtop Remote\Server",
    "${Env:ProgramFiles(x86)}\Splashtop\Splashtop Remote\Server",
    "${Env:ProgramFiles}\Splashtop\Splashtop Software Updater",
    "${Env:ProgramFiles(x86)}\Splashtop\Splashtop Software Updater",
    "${Env:ProgramData}\Splashtop\Splashtop Software Updater"
)

# Any other relevant exe files in the install dir, so we can make sure they're closed later
$ExeFiles = New-Object System.Collections.ArrayList
"${Env:ProgramFiles}\ATERA Networks" | ForEach-Object { Get-AllExeFiles -Path $_ }

# Services to stop and delete
$ServiceList = @(
    'AteraAgent',
    'SplashtopRemoteService',
    'SSUService'
)

# Registry keys to delete
$RegistryKeys = @(
    'HKLM:SOFTWARE\ATERA Networks',
    'HKLM:SOFTWARE\Splashtop Inc.',
    'HKLM:SOFTWARE\WOW6432Node\Splashtop Inc.'
)


############################################################################################################
#                                              Uninstall                                                   #
############################################################################################################

# Uninstall each MSI package code
$UninstallCodes | ForEach-Object {
    Write-Output "Uninstall: ${_}"
    Start-Process "msiexec.exe" -ArgumentList "/X{${_}} /qn" -Wait
}

# Stop services if still running
$ServiceList | ForEach-Object { Stop-RunningService -Name $_ }

# Terminate any remaining processes from the install dir
$ExeFiles.Add('reg') | Out-Null
$ExeFiles | ForEach-Object { Stop-RunningProcess -Name $_ }

# Delete services if still present
$ServiceList | ForEach-Object { Remove-StoppedService -Name $_ }

# Delete products from MSI installer registry
$ProductKeys | ForEach-Object { Remove-Path -Path "HKCR:Installer\Products\${_}" }

# Unmount HKEY_CLASSES_ROOT
Remove-PSDrive -Name HKCR

# Delete registry keys
$RegistryKeys | ForEach-Object { Remove-Path -Path $_ }

# Delete remaining directories
$Directories | ForEach-Object { Remove-Path -Path $_ }
