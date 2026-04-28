
#Requires -RunAsAdministrator

<#
.SYNOPSIS
    Silently updates Foxit PDF Reader to the latest version on Windows machines without any user interaction or console output.
    The script will first check if Foxit PDF Reader is installed; if not, it will exit silently.

.DESCRIPTION
    This script checks for the installed version of Foxit PDF Reader, downloads the latest EXE installer
    from Foxit's official servers, and performs a silent upgrade. It attempts to close running Foxit PDF Reader
    processes before updating to prevent issues. All console output has been suppressed for maximum silence.
    Errors will cause the script to exit silently.

.NOTES
    Author: Manus AI
    Version: 1.1
    Date: March 23, 2026
    Requires: PowerShell 5.1 or higher, Administrator privileges

.LINK
    https://www.foxit.com/pdf-reader/
#>

function Update-FoxitPDFReader {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$false)]
        [switch]$Force
    )

    # Check for Administrator privileges
    if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
        exit 1 # Exit silently if not administrator
    }

    # Check if Foxit PDF Reader is installed
    $foxitPath64 = "${env:ProgramFiles}\Foxit Software\Foxit Reader\FoxitReader.exe"
    $foxitPath32 = "${env:ProgramFiles(x86)}\Foxit Software\Foxit Reader\FoxitReader.exe"

    if (-not (Test-Path $foxitPath64) -and -not (Test-Path $foxitPath32)) {
        exit 0 # Exit silently if Foxit PDF Reader is not found
    }

    # Define download URL for the latest Foxit PDF Reader EXE installer
    # This URL typically redirects to the latest version. It might be necessary to periodically verify this link.
    $foxitDownloadUrl = "https://cdn01.foxitsoftware.com/pub/foxit/reader/desktop/win/FoxitPDFReader.exe"
    $downloadPath = "$env:TEMP\FoxitPDFReader_Setup.exe"

    try {
        Invoke-WebRequest -Uri $foxitDownloadUrl -OutFile $downloadPath -UseBasicParsing
    }
    catch {
        exit 1 # Exit silently on download failure
    }

    # Check if Foxit PDF Reader processes are running and attempt to close them
    $foxitProcesses = Get-Process -Name "FoxitReader" -ErrorAction SilentlyContinue
    if ($foxitProcesses) {
        foreach ($process in $foxitProcesses) {
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
        # Use the /silent switch for silent installation of Foxit PDF Reader EXE installer
        # Additional switches like /norestart might be available depending on the installer version.
        $process = Start-Process -FilePath $downloadPath -ArgumentList "/silent /norestart" -Wait -PassThru

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
Update-FoxitPDFReader
