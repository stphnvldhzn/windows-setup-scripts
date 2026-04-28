# Self-elevate the script if required
if (-Not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] 'Administrator')) {
 if ([int](Get-CimInstance -Class Win32_OperatingSystem | Select-Object -ExpandProperty BuildNumber) -ge 6000) {
  $CommandLine = "-File `"" + $MyInvocation.MyCommand.Path + "`" " + $MyInvocation.UnboundArguments
  Start-Process -FilePath PowerShell.exe -Verb Runas -ArgumentList $CommandLine
  Exit
 }
}

# Remainder of script here

# remove provisioning packages
Get-AppProvisionedPackage -online | Where-Object {$_.packagename -Like "*Clipchamp*"} | Remove-AppxProvisionedPackage -online
Get-AppProvisionedPackage -online | Where-Object {$_.packagename -Like "*connectedexperience*"} | Remove-AppxProvisionedPackage -online
Get-AppProvisionedPackage -online | Where-Object {$_.packagename -Like "*BingNews*"} | Remove-AppxProvisionedPackage -online
Get-AppProvisionedPackage -online | Where-Object {$_.packagename -Like "*BingWeather*"} | Remove-AppxProvisionedPackage -online
Get-AppProvisionedPackage -online | Where-Object {$_.packagename -Like "*GamingApp*"} | Remove-AppxProvisionedPackage -online
Get-AppProvisionedPackage -online | Where-Object {$_.packagename -Like "*GetHelp*"} | Remove-AppxProvisionedPackage -online
Get-AppProvisionedPackage -online | Where-Object {$_.packagename -Like "*GetStarted*"} | Remove-AppxProvisionedPackage -online
Get-AppProvisionedPackage -online | Where-Object {$_.packagename -Like "*MicrosoftStickyNotes*"} | Remove-AppxProvisionedPackage -online
Get-AppProvisionedPackage -online | Where-Object {$_.packagename -Like "*communicationsapps*"} | Remove-AppxProvisionedPackage -online
Get-AppProvisionedPackage -online | Where-Object {$_.packagename -Like "*officehub*"} | Remove-AppxProvisionedPackage -online
Get-AppProvisionedPackage -online | Where-Object {$_.packagename -Like "*solitairecollection*"} | Remove-AppxProvisionedPackage -online
Get-AppProvisionedPackage -online | Where-Object {$_.packagename -Like "*people*"} | Remove-AppxProvisionedPackage -online
Get-AppProvisionedPackage -online | Where-Object {$_.packagename -Like "*todos*"} | Remove-AppxProvisionedPackage -online
Get-AppProvisionedPackage -online | Where-Object {$_.packagename -Like "*feedbackhub*"} | Remove-AppxProvisionedPackage -online
Get-AppProvisionedPackage -online | Where-Object {$_.packagename -Like "*windowsmaps*"} | Remove-AppxProvisionedPackage -online
Get-AppProvisionedPackage -online | Where-Object {$_.packagename -Like "*SoundRecorder*"} | Remove-AppxProvisionedPackage -online
Get-AppProvisionedPackage -online | Where-Object {$_.packagename -Like "*xboxgameoverlay*"} | Remove-AppxProvisionedPackage -online
Get-AppProvisionedPackage -online | Where-Object {$_.packagename -Like "*xboxgamingoverlay*"} | Remove-AppxProvisionedPackage -online
Get-AppProvisionedPackage -online | Where-Object {$_.packagename -Like "*xboxidentityprovider*"} | Remove-AppxProvisionedPackage -online
Get-AppProvisionedPackage -online | Where-Object {$_.packagename -Like "*xboxspeechtotextoverlay*"} | Remove-AppxProvisionedPackage -online
Get-AppProvisionedPackage -online | Where-Object {$_.packagename -Like "*xbox*"} | Remove-AppxProvisionedPackage -online
Get-AppProvisionedPackage -online | Where-Object {$_.packagename -Like "*Microsoft.Xbox.TCUI*"} | Remove-AppxProvisionedPackage -online
Get-AppProvisionedPackage -online | Where-Object {$_.packagename -Like "*zunemusic*"} | Remove-AppxProvisionedPackage -online
Get-AppProvisionedPackage -online | Where-Object {$_.packagename -Like "*zunevideo*"} | Remove-AppxProvisionedPackage -online
Get-AppProvisionedPackage -online | Where-Object {$_.packagename -Like "*quickassist*"} | Remove-AppxProvisionedPackage -online
Get-AppProvisionedPackage -online | Where-Object {$_.packagename -Like "*webexperience*"} | Remove-AppxProvisionedPackage -online
Get-AppProvisionedPackage -online | Where-Object {$_.packagename -Like "*MicrosoftTeams*"} | Remove-AppxProvisionedPackage -online
Get-AppProvisionedPackage -online | Where-Object {$_.packagename -Like "*PowerAutomate*"} | Remove-AppxProvisionedPackage -online
Get-AppProvisionedPackage -online | Where-Object {$_.packagename -Like "*PeopleExperienceHost*"} | Remove-AppxProvisionedPackage -online
Get-AppProvisionedPackage -online | Where-Object {$_.packagename -Like "*XboxGameCallableUI*"} | Remove-AppxProvisionedPackage -online
Get-AppProvisionedPackage -online | Where-Object {$_.packagename -Like "*Whatsapp*"} | Remove-AppxProvisionedPackage -online
Get-AppProvisionedPackage -online | Where-Object {$_.packagename -Like "*spotify*"} | Remove-AppxProvisionedPackage -online
Get-AppProvisionedPackage -online | Where-Object {$_.packagename -Like "*instagram*"} | Remove-AppxProvisionedPackage -online
Get-AppProvisionedPackage -online | Where-Object {$_.packagename -Like "*linkedin*"} | Remove-AppxProvisionedPackage -online
Get-AppProvisionedPackage -online | Where-Object {$_.packagename -Like "*Disney*"} | Remove-AppxProvisionedPackage -online
Get-AppProvisionedPackage -online | Where-Object {$_.packagename -Like "*Messenger*"} | Remove-AppxProvisionedPackage -online
Get-AppProvisionedPackage -online | Where-Object {$_.packagename -Like "*Facebook*"} | Remove-AppxProvisionedPackage -online
Get-AppProvisionedPackage -online | Where-Object {$_.packagename -Like "*DevHome*"} | Remove-AppxProvisionedPackage -online
Get-AppProvisionedPackage -online | Where-Object {$_.packagename -Like "*Copilot*"} | Remove-AppxProvisionedPackage -online
Get-AppProvisionedPackage -online | Where-Object {$_.packagename -Like "*DevHome*"} | Remove-AppxProvisionedPackage -online
Get-AppProvisionedPackage -online | Where-Object {$_.packagename -Like "*549981C3F5F10*"} | Remove-AppxProvisionedPackage -online
Get-AppProvisionedPackage -online | Where-Object {$_.packagename -Like "*bing*"} | Remove-AppxProvisionedPackage -online
Get-AppProvisionedPackage -online | Where-Object {$_.packagename -Like "*netflix*"} | Remove-AppxProvisionedPackage -online
Get-AppProvisionedPackage -online | Where-Object {$_.packagename -Like "*skype*"} | Remove-AppxProvisionedPackage -online
Get-AppProvisionedPackage -online | Where-Object {$_.packagename -Like "*oneconnect*"} | Remove-AppxProvisionedPackage -online
Get-AppProvisionedPackage -online | Where-Object {$_.packagename -Like "*HPJumpStart*"} | Remove-AppxProvisionedPackage -online
Get-AppProvisionedPackage -online | Where-Object {$_.packagename -Like "*HPSupportAssistant*"} | Remove-AppxProvisionedPackage -online
Get-AppProvisionedPackage -online | Where-Object {$_.packagename -Like "*Wallet*"} | Remove-AppxProvisionedPackage -online
Get-AppProvisionedPackage -online | Where-Object {$_.packagename -Like "*teams*"} | Remove-AppxProvisionedPackage -online



# remove packages
Get-AppxPackage Clipchamp.Clipchamp -AllUsers | Remove-AppxPackage
Get-AppxPackage Microsoft.549981C3F5F10 -AllUsers | Remove-AppxPackage
Get-AppxPackage Microsoft.BingNews -AllUsers | Remove-AppxPackage
Get-AppxPackage Microsoft.BingWeather -AllUsers | Remove-AppxPackage
Get-AppxPackage Microsoft.GamingApp -AllUsers | Remove-AppxPackage
Get-AppxPackage Microsoft.GetHelp -AllUsers | Remove-AppxPackage
Get-AppxPackage Microsoft.Getstarted -AllUsers | Remove-AppxPackage
Get-AppxPackage Microsoft.MicrosoftStickyNotes -AllUsers | Remove-AppxPackage
Get-AppxPackage Microsoft.Windows.Photos -AllUsers | Remove-AppxPackage
Get-AppxPackage microsoft.windowscommunicationsapps -AllUsers | Remove-AppxPackage
Get-AppxPackage Microsoft.MicrosoftOfficeHub -AllUsers | Remove-AppxPackage
Get-AppxPackage Microsoft.MicrosoftSolitaireCollection -AllUsers | Remove-AppxPackage
Get-AppxPackage Microsoft.People -AllUsers | Remove-AppxPackage
Get-AppxPackage Microsoft.Todos -AllUsers | Remove-AppxPackage
Get-AppxPackage Microsoft.WindowsFeedbackHub -AllUsers | Remove-AppxPackage 
Get-AppxPackage Microsoft.WindowsMaps  -AllUsers | Remove-AppxPackage
Get-AppXPackage Microsoft.WindowsSoundRecorder -AllUsers | Remove-AppxPackage
Get-AppXPackage Microsoft.WindowsStore -AllUsers | Remove-AppxPackage
Get-AppxPackage Microsoft.XboxGameOverlay   -AllUsers | Remove-AppxPackage
Get-AppxPackage Microsoft.XboxGamingOverlay -AllUsers | Remove-AppxPackage
Get-AppxPackage Microsoft.XboxIdentityProvider -AllUsers | Remove-AppxPackage
Get-AppxPackage Microsoft.XboxSpeechToTextOverlay   -AllUsers | Remove-AppxPackage
Get-AppxPackage Microsoft.Xbox.TCUI   -AllUsers | Remove-AppxPackage
Get-AppxPackage Microsoft.ZuneMusic -AllUsers | Remove-AppxPackage
Get-AppxPackage Microsoft.ZuneVideo -AllUsers | Remove-AppxPackage
Get-AppxPackage MicrosoftCorporationII.QuickAssist -AllUsers | Remove-AppxPackage
Get-AppxPackage MicrosoftWindows.Client.WebExperience -AllUsers | Remove-AppxPackage 
Get-AppxPackage MicrosoftTeams -AllUsers | Remove-AppxPackage
Get-AppxPackage Microsoft.PowerAutomateDesktop -AllUsers | Remove-AppxPackage
Get-AppxPackage Microsoft.Windows.PeopleExperienceHost -AllUsers | Remove-AppxPackage
Get-AppxPackage Microsoft.XboxGameCallableUI -AllUsers | Remove-AppxPackage
Get-AppxPackage *spotify* -Allusers | Remove-AppxPackage
Get-AppxPackage *DevHome* -Allusers | Remove-AppxPackage
Get-AppxPackage Microsoft.Windows.Ai.Copilot.Provider_8wekyb3d8bbwe -Allusers | Remove-AppxPackage
Get-AppxPackage Microsoft.Windows.Ai.Copilot.Provider -Allusers | Remove-AppxPackage
Get-AppxPackage *webexperience* | Remove-Appxpackage -allusers
Get-AppxPackage *copilot* | Remove-Appxpackage -allusers
Get-AppxPackage *officehub* | Remove-Appxpackage -allusers
Get-AppxPackage *xbox* | Remove-Appxpackage -allusers
Get-AppxPackage *bing* | Remove-Appxpackage -allusers
Get-AppxPackage *netflix* | Remove-Appxpackage -allusers
Get-AppxPackage *skype* | Remove-Appxpackage -allusers
Get-AppxPackage *oneconnect* | Remove-Appxpackage -allusers
Get-AppxPackage *HPJumpStart* | Remove-Appxpackage -allusers
Get-AppxPackage *HPSupportAssistant* | Remove-Appxpackage -allusers
Get-AppxPackage *Wallet* | Remove-Appxpackage -allusers
Get-AppxPackage *copilot* | Remove-Appxpackage -allusers
Get-AppxPackage *teams* | Remove-Appxpackage -allusers