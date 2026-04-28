# Make local drive the default save path
reg add "HKLM\SOFTWARE\Policies\Microsoft\Office\16.0\Common\General" /v PreferCloudSaveLocations /t REG_DWORD /d 0 /f

# Use classic File Explorer instead of the cloud Save experience
reg add "HKLM\SOFTWARE\Policies\Microsoft\Office\16.0\Common\General" /v UseOfficeForCloudSaveExperience /t REG_DWORD /d 0 /f

# Skip Backstage on Save (show File Explorer directly)
reg add "HKLM\SOFTWARE\Policies\Microsoft\Office\16.0\Common\Open Find" /v DisableBackstageSave /t REG_DWORD /d 1 /f
