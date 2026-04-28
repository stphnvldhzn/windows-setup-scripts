
#Requires -RunAsAdministrator

<#
.SYNOPSIS
    Silently updates Mozilla Firefox to the latest version on Windows machines without any user interaction or console output.
    The script will first check if Firefox is installed; if not, it will exit silently.

.DESCRIPTION
    This script checks for the installed version of Mozilla Firefox, downloads the latest MSI installer
    from Mozilla's official servers, and performs a silent upgrade. It handles both 32-bit and 64-bit
    installations and attempts to close running Firefox processes before updating to prevent issues.
    All console output has been suppressed for maximum silence. Errors will cause the script to exit.

.NOTES
    Author: Manus AI
    Version: 1.2
    Date: March 23, 2026
    Requires: PowerShell 5.1 or higher, Administrator privileges

.LINK
    https://www.mozilla.org/firefox/enterprise/
#>

function Update-Firefox {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$false)]
        [switch]$Force
    )

    # Check for Administrator privileges
    if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
        exit 1 # Exit silently if not administrator
    }

    # Check if Firefox is installed
    $firefoxPath64 = "${env:ProgramFiles}\Mozilla Firefox\firefox.exe"
    $firefoxPath32 = "${env:ProgramFiles(x86)}\Mozilla Firefox\firefox.exe"

    if (-not (Test-Path $firefoxPath64) -and -not (Test-Path $firefoxPath32)) {
        exit 0 # Exit silently if Firefox is not found
    }

    # Define download URL for the latest Firefox MSI (64-bit and 32-bit)
    $firefoxMsi64bitUrl = "https://download.mozilla.org/?product=firefox-msi-latest-ssl&os=win64&lang=en-US"
    $firefoxMsi32bitUrl = "https://download.mozilla.org/?product=firefox-msi-latest-ssl&os=win32&lang=en-US"
    $downloadPath = "$env:TEMP\FirefoxSetup.msi"

    # Determine system architecture
    $architecture = (Get-WmiObject Win32_OperatingSystem).OSArchitecture

    $downloadUrl = if ($architecture -eq "64-bit") { $firefoxMsi64bitUrl } else { $firefoxMsi32bitUrl }

    try {
        Invoke-WebRequest -Uri $downloadUrl -OutFile $downloadPath -UseBasicParsing
    }
    catch {
        exit 1 # Exit silently on download failure
    }

    # Check if Firefox processes are running and attempt to close them
    $firefoxProcesses = Get-Process -Name "firefox" -ErrorAction SilentlyContinue
    if ($firefoxProcesses) {
        foreach ($process in $firefoxProcesses) {
            try {
                Stop-Process -Id $process.Id -Force -ErrorAction SilentlyContinue
            }
            catch {
                # Silently ignore if process cannot be closed
            }
        }
        Start-Sleep -Seconds 5 # Give processes some time to terminate
    }

    try {
        # Use msiexec for silent installation. /i for install, /qn for quiet no UI, /norestart to prevent automatic reboot.
        $process = Start-Process -FilePath "msiexec.exe" -ArgumentList "/i `"$downloadPath`" /qn /norestart" -Wait -PassThru

        if ($process.ExitCode -ne 0) {
            exit 1 # Exit silently on installation failure
        }
    }
    catch {
        exit 1 # Exit silently on general installation error
    }

    # Clean up downloaded installer
    if (Test-Path $downloadPath) {
        Remove-Item $downloadPath -Force
    }
}

# Call the function to execute the update
Update-Firefox
