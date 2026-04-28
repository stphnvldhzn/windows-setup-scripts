# =========================
# AppLocker – Add DEFAULT rules only (EXE, MSI, Script, Appx). No DLL.
# Merges into current policy. Tested to avoid -DefaultRule / -Local switches.
# Run as Administrator.
# =========================

# 1) Ensure AppLocker engine can run (service must be Automatic + Running)
Start-Process -FilePath sc.exe -ArgumentList 'config appidsvc start= auto' -WindowStyle Hidden -Wait
Start-Process -FilePath sc.exe -ArgumentList 'start appidsvc' -WindowStyle Hidden -Wait

# 2) Build a default-rules-only policy (four collections). DLL is omitted.
$adminsSid   = 'S-1-5-32-544'  # BUILTIN\Administrators
$everyoneSid = 'S-1-1-0'       # Everyone

# Helper for new GUIDs inside the XML
function New-G { [guid]::NewGuid().ToString() }

$defaultXml = @"
<AppLockerPolicy Version="1">
  <!-- Executable defaults -->
  <RuleCollection Type="Exe" EnforcementMode="Enabled">
    <FilePathRule Id="{$(New-G)}" Name="(Default Rule) All files" UserOrGroupSid="$adminsSid" Action="Allow">
      <Conditions><FilePathCondition Path="*" /></Conditions>
    </FilePathRule>
    <FilePathRule Id="{$(New-G)}" Name="(Default Rule) All files located in the Windows folder" UserOrGroupSid="$everyoneSid" Action="Allow">
      <Conditions><FilePathCondition Path="%WINDIR%\*" /></Conditions>
    </FilePathRule>
    <FilePathRule Id="{$(New-G)}" Name="(Default Rule) All files located in the Program Files folder" UserOrGroupSid="$everyoneSid" Action="Allow">
      <Conditions><FilePathCondition Path="%PROGRAMFILES%\*" /></Conditions>
    </FilePathRule>
  </RuleCollection>

  <!-- Windows Installer (MSI/MST/MSP) defaults -->
  <RuleCollection Type="Msi" EnforcementMode="Enabled">
    <FilePathRule Id="{$(New-G)}" Name="(Default Rule) All Windows Installer files" UserOrGroupSid="$adminsSid" Action="Allow">
      <Conditions><FilePathCondition Path="*" /></Conditions>
    </FilePathRule>
    <FilePublisherRule Id="{$(New-G)}" Name="(Default Rule) All digitally signed Windows Installer files" UserOrGroupSid="$everyoneSid" Action="Allow">
      <Conditions><FilePublisherCondition PublisherName="*" ProductName="*" BinaryName="*" /></Conditions>
    </FilePublisherRule>
    <FilePathRule Id="{$(New-G)}" Name="(Default Rule) All Windows Installer files in %systemdrive%\Windows\Installer" UserOrGroupSid="$everyoneSid" Action="Allow">
      <Conditions><FilePathCondition Path="%WINDIR%\Installer\*" /></Conditions>
    </FilePathRule>
  </RuleCollection>

  <!-- Script defaults (.ps1 .bat .cmd .vbs .js) -->
  <RuleCollection Type="Script" EnforcementMode="Enabled">
    <FilePathRule Id="{$(New-G)}" Name="(Default Rule) All scripts" UserOrGroupSid="$adminsSid" Action="Allow">
      <Conditions><FilePathCondition Path="*" /></Conditions>
    </FilePathRule>
    <FilePathRule Id="{$(New-G)}" Name="(Default Rule) All scripts located in the Windows folder" UserOrGroupSid="$everyoneSid" Action="Allow">
      <Conditions><FilePathCondition Path="%WINDIR%\*" /></Conditions>
    </FilePathRule>
    <FilePathRule Id="{$(New-G)}" Name="(Default Rule) All scripts located in the Program Files folder" UserOrGroupSid="$everyoneSid" Action="Allow">
      <Conditions><FilePathCondition Path="%PROGRAMFILES%\*" /></Conditions>
    </FilePathRule>
  </RuleCollection>

  <!-- Packaged apps (Appx) defaults -->
  <RuleCollection Type="Appx" EnforcementMode="Enabled">
    <FilePublisherRule Id="{$(New-G)}" Name="(Default Rule) All signed packaged apps" UserOrGroupSid="$everyoneSid" Action="Allow">
      <Conditions>
        <FilePublisherCondition PublisherName="*" ProductName="*" BinaryName="*" />
      </Conditions>
    </FilePublisherRule>
    <FilePublisherRule Id="{$(New-G)}" Name="(Default Rule) All packaged apps (Administrators)" UserOrGroupSid="$adminsSid" Action="Allow">
      <Conditions>
        <FilePublisherCondition PublisherName="*" ProductName="*" BinaryName="*" />
      </Conditions>
    </FilePublisherRule>
  </RuleCollection>
</AppLockerPolicy>
"@

# 3) Write the XML to disk, then merge into local policy
New-Item -ItemType Directory -Path "C:\temp" -Force | Out-Null
$defaultXml | Out-File -FilePath "C:\temp\defaultapplockerpolicy.xml" -Encoding UTF8 -Force
Set-AppLockerPolicy -XmlPolicy "C:\temp\defaultapplockerpolicy.xml" -Merge

Write-Host "Default AppLocker rules added for EXE, MSI, Script, and Appx (DLL untouched)."
Write-Host "AppIDSvc is set to Auto and started. Sign out/in (or reboot) for full effect."