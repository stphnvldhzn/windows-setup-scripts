# Self-elevate the script if required
if (-Not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] 'Administrator')) {
 if ([int](Get-CimInstance -Class Win32_OperatingSystem | Select-Object -ExpandProperty BuildNumber) -ge 6000) {
  $CommandLine = "-File `"" + $MyInvocation.MyCommand.Path + "`" " + $MyInvocation.UnboundArguments
  Start-Process -FilePath PowerShell.exe -Verb Runas -ArgumentList $CommandLine
  Exit
 }
}

# Remainder of script here
#
#Start of Script
Add-MpPreference -ExclusionPath "C:\Program Files\ATERA Networks\AteraAgent"
Add-MpPreference -ExclusionPath "C:\Program Files(X86)\ATERA Networks\AteraAgent"
Add-MpPreference -ExclusionPath "C:\Windows\Temp\AteraUpgradeAgentPackage"