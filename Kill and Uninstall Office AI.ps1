# Close Outlook & Kill AI
taskkill /f /im outlook.exe
taskkill /IM ai.exe /F 

# Remove AI (x86)
cd "C:\Program Files (x86)\Microsoft Office\root\vfs\ProgramFilesCommonX64\Microsoft Shared\OFFICE16"
Del ai.exe
Del ai.dll
Del aimgr.exe
Del aitrx.dll
cd "C:\Program Files (x86)\Microsoft Office\root\vfs\ProgramFilesCommonX86\Microsoft Shared\OFFICE16"
Del ai.exe
Del ai.dll
Del aimgr.exe
Del aitrx.dll


#Remove AI (x64)
cd "C:\Program Files\Microsoft Office\root\vfs\ProgramFilesCommonX64\Microsoft Shared\OFFICE16"
Del ai.exe
Del ai.dll
Del aimgr.exe
Del aitrx.dll
cd "C:\Program Files\Microsoft Office\root\vfs\ProgramFilesCommonX86\Microsoft Shared\OFFICE16"
Del ai.exe
Del ai.dll
Del aimgr.exe
Del aitrx.dll