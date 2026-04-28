reg add HKLM\SOFTWARE\Policies\Google\Chrome\ClearBrowsingDataOnExitList /v 1 /t REG_SZ /D browsing_history /f
reg add HKLM\SOFTWARE\Policies\Google\Chrome\ClearBrowsingDataOnExitList /v 2 /t REG_SZ /D download_history /f
reg add HKLM\SOFTWARE\Policies\Google\Chrome\ClearBrowsingDataOnExitList /v 3 /t REG_SZ /D cookies_and_other_site_data /f
reg add HKLM\SOFTWARE\Policies\Google\Chrome\ClearBrowsingDataOnExitList /v 4 /t REG_SZ /D cached_images_and_files /f
reg add HKLM\SOFTWARE\Policies\Google\Chrome\ClearBrowsingDataOnExitList /v 5 /t REG_SZ /D password_signin /f
reg add HKLM\SOFTWARE\Policies\Google\Chrome\ClearBrowsingDataOnExitList /v 6 /t REG_SZ /D autofill /f
reg add HKLM\SOFTWARE\Policies\Google\Chrome\ClearBrowsingDataOnExitList /v 7 /t REG_SZ /D site_settings /f
reg add HKLM\SOFTWARE\Policies\Google\Chrome\ClearBrowsingDataOnExitList /v 8 /t REG_SZ /D hosted_app_data /f