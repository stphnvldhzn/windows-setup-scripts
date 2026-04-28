# Variables
$key1 = "SLRToggleReplaceTeachingCalloutID"
$key2 = "UseTighterSpacingTeachingCallout"

# Run Command
reg add "HKEY_CURRENT_USER\SOFTWARE\Microsoft\Office\16.0\Common\TeachingCallouts" /v $key1 /t REG_DWORD /d 2 /f
reg add "HKEY_CURRENT_USER\SOFTWARE\Microsoft\Office\16.0\Common\TeachingCallouts" /v $key2 /t REG_DWORD /d 2 /f