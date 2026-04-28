<#
.SYNOPSIS
    Silently deletes all contents from OfficeFileCache directory.
.DESCRIPTION
    Removes all files and subfolders from Office 365's OfficeFileCache location.
    Runs with no output or error messages.
.NOTES
    Version: 1.0
    Works with: Office 365 (16.0)
#>

# Set all preferences to silent
$ErrorActionPreference = 'SilentlyContinue'
$ProgressPreference = 'SilentlyContinue'
$WarningPreference = 'SilentlyContinue'
$VerbosePreference = 'SilentlyContinue'
$DebugPreference = 'SilentlyContinue'
$InformationPreference = 'SilentlyContinue'

# Hide the PowerShell window completely
$null = (Add-Type -MemberDefinition '
[DllImport("user32.dll")] 
public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);
[DllImport("kernel32.dll")] 
public static extern IntPtr GetConsoleWindow();
' -Name 'Win32Functions' -Namespace 'Win32' -PassThru)::ShowWindow(
    (Add-Type -MemberDefinition '
    [DllImport("kernel32.dll")] 
    public static extern IntPtr GetConsoleWindow();
    ' -Name 'ConsoleWindow' -Namespace 'Win32' -PassThru)::GetConsoleWindow(),
    0)  # 0 = SW_HIDE

# Define the target directory
$officeFileCachePath = Join-Path -Path $env:LOCALAPPDATA -ChildPath "Microsoft\Office\16.0\OfficeFileCache"

# Delete all contents silently
if (Test-Path -Path $officeFileCachePath) {
    # Delete all files and subdirectories
    Get-ChildItem -Path $officeFileCachePath -Force | ForEach-Object {
        try {
            if ($_.PSIsContainer) {
                Remove-Item $_.FullName -Recurse -Force
            } else {
                Remove-Item $_.FullName -Force
            }
        } catch {}
    }
}

# Exit silently
exit 0