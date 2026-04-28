# Chrome is locked to the guest account
reg add "HKLM\Software\Policies\Google\Chrome" /v BrowserGuestModeEnforced /t REG_DWORD /D 1 /f