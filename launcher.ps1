# Windows Setup Script Launcher
# Run on a fresh Windows machine with:
#   iex (irm https://raw.githubusercontent.com/stphnvldhzn/windows-setup-scripts/main/launcher.ps1)

$ErrorActionPreference = 'Stop'

$repoOwner = 'stphnvldhzn'
$repoName  = 'windows-setup-scripts'
$branch    = 'main'

# 1. Self-elevate to administrator if not already
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "Not running as administrator -- relaunching in elevated window..." -ForegroundColor Yellow
    $bootstrap = "iex (irm https://raw.githubusercontent.com/$repoOwner/$repoName/$branch/launcher.ps1)"
    Start-Process powershell -Verb RunAs -ArgumentList '-NoExit','-Command',$bootstrap
    return
}

# 2. Allow downloaded scripts to run for the lifetime of this process only
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force

# 3. List .ps1 files in the repo root via the GitHub API (public repo, no auth)
Write-Host "Fetching script list from $repoOwner/$repoName ($branch)..." -ForegroundColor Cyan
$apiUrl = "https://api.github.com/repos/$repoOwner/$repoName/contents?ref=$branch"
$entries = Invoke-RestMethod -Uri $apiUrl -Headers @{ 'User-Agent' = 'wss-launcher' }

$scripts = $entries |
    Where-Object { $_.type -eq 'file' -and $_.name -like '*.ps1' -and $_.name -ne 'launcher.ps1' } |
    Sort-Object name

if (-not $scripts) {
    Write-Host "No .ps1 scripts found in the repo." -ForegroundColor Red
    return
}

Write-Host "Found $($scripts.Count) script(s). Opening selection window..." -ForegroundColor Cyan

# 4. Build a name->URL lookup, then show a multi-select grid
$urlMap = @{}
foreach ($s in $scripts) { $urlMap[$s.name] = $s.download_url }

$selected = $scripts |
    Select-Object @{N='Name';E={$_.name}}, @{N='Size (KB)';E={[math]::Round($_.size/1024, 1)}} |
    Out-GridView -Title "Select scripts to run (Ctrl/Shift-click for multi-select, then OK)" -PassThru

if (-not $selected) {
    Write-Host "No scripts selected. Exiting." -ForegroundColor Yellow
    return
}

# 5. Run each selected script in alphabetical order, in a child PowerShell process
$tempDir = Join-Path $env:TEMP "wss-launcher-$([guid]::NewGuid().Guid.Substring(0,8))"
New-Item -ItemType Directory -Path $tempDir -Force | Out-Null

$results = foreach ($sel in ($selected | Sort-Object Name)) {
    $name = $sel.Name
    $url  = $urlMap[$name]

    Write-Host ""
    Write-Host "==================================================" -ForegroundColor Cyan
    Write-Host "Running: $name" -ForegroundColor Cyan
    Write-Host "==================================================" -ForegroundColor Cyan

    $tempPath = Join-Path $tempDir $name
    try {
        Invoke-WebRequest -Uri $url -OutFile $tempPath -UseBasicParsing
        & powershell.exe -ExecutionPolicy Bypass -File $tempPath 2>&1 | Out-Host
        $exitCode = $LASTEXITCODE
        if ($exitCode -in @($null, 0)) {
            [pscustomobject]@{ Name = $name; Success = $true;  Error = $null }
        } else {
            [pscustomobject]@{ Name = $name; Success = $false; Error = "exit code $exitCode" }
        }
    } catch {
        [pscustomobject]@{ Name = $name; Success = $false; Error = $_.Exception.Message }
    }
}

Remove-Item $tempDir -Recurse -Force -ErrorAction SilentlyContinue

# 6. Summary
Write-Host ""
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "Summary" -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan
foreach ($r in $results) {
    if ($r.Success) {
        Write-Host "  [ OK ] $($r.Name)" -ForegroundColor Green
    } else {
        Write-Host "  [FAIL] $($r.Name)  -- $($r.Error)" -ForegroundColor Red
    }
}
$okCount   = ($results | Where-Object Success).Count
$failCount = ($results | Where-Object { -not $_.Success }).Count
Write-Host ""
Write-Host "$okCount succeeded, $failCount failed." -ForegroundColor $(if ($failCount -gt 0) { 'Yellow' } else { 'Green' })
