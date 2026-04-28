# Users can't add or log on with Microsoft accounts
reg add "HKLM\Software\Policies\Microsoft\Windows\CurrentVersion\AccountNotifications" /v NoConnectedUser /t REG_DWORD /D 3 /f