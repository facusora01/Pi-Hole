#requires -Version 5.1
Add-Type -AssemblyName System.Windows.Forms

# Ensure STA for reliable WinForms behavior
if ([System.Threading.Thread]::CurrentThread.ApartmentState -ne 'STA') {
  $self = $MyInvocation.MyCommand.Path
  powershell -NoProfile -ExecutionPolicy Bypass -STA -File "$self"
  exit $LASTEXITCODE
}

# Project root = parent of this script directory
$scriptDir  = Split-Path -Parent $MyInvocation.MyCommand.Path
$projectDir = Split-Path -Parent $scriptDir
Set-Location $projectDir

# Combine the two confirmation prompts into one
$ans = [System.Windows.Forms.MessageBox]::Show(
    "Would you like to start Pi-hole?",
    "Pi-hole Initialization",
    [System.Windows.Forms.MessageBoxButtons]::YesNo,
    [System.Windows.Forms.MessageBoxIcon]::Question
)
if ($ans -ne [System.Windows.Forms.DialogResult]::Yes) {
    exit 0
}

# Check if Docker is already running
$dockerStatus = docker ps -q 2>$null
if ($dockerStatus) {
    [System.Windows.Forms.MessageBox]::Show("Pi-hole is already running.", "Docker Status", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information) | Out-Null
    exit 0
}

# Discover first service from compose (v2, fallback v1)
$service = (docker compose config --services 2>$null | Select-Object -First 1)
if (-not $service) { $service = (docker-compose config --services 2>$null | Select-Object -First 1) }
if (-not $service) {
  if ($env:POPUP_SILENT -eq '1') { Write-Host "No service found in docker-compose.yml."; exit 1 }
  [System.Windows.Forms.MessageBox]::Show("No service found in docker-compose.yml.","Compose") | Out-Null
  exit 1
}

# Label to show (container_name if present, else service)
$label = $service
try {
  $json = docker compose config --format json 2>$null; if (-not $json) { $json = docker-compose config --format json 2>$null }
  if ($json) {
    $cfg = $json | ConvertFrom-Json
    if ($cfg.services.$service.container_name) { $label = $cfg.services.$service.container_name }
  }
} catch { }

# DRY-RUN: allow previewing UI without touching Docker
if ($env:DRY_RUN -eq '1') {
  if ($env:POPUP_SILENT -eq '1') { Write-Host "Dry-run: would start '$label' now." } else { [System.Windows.Forms.MessageBox]::Show("Dry-run: would start '$label' now.","Compose") | Out-Null }
  exit 0
}

# Wait for Docker Desktop readiness (max ~4 min)
for ($i=0; $i -lt 120; $i++) { docker info >$null 2>&1; if ($LASTEXITCODE -eq 0) { break }; Start-Sleep 2 }
if ($LASTEXITCODE -ne 0) {
  if ($env:POPUP_SILENT -eq '1') { Write-Host "Docker is not ready."; exit 1 }
  [System.Windows.Forms.MessageBox]::Show("Docker is not ready.","Compose") | Out-Null; exit 1 }

# Start service (compose v2, fallback v1)
 docker compose up -d --no-build $service 2>$null
if ($LASTEXITCODE -ne 0) { docker-compose up -d --no-build $service 2>$null }

# Notify result
if ($LASTEXITCODE -eq 0) {
  if ($env:POPUP_SILENT -eq '1') { Write-Host "'$label' is starting in the background." } else { [System.Windows.Forms.MessageBox]::Show("'$label' is starting in the background.","Compose") | Out-Null }
} else {
  if ($env:POPUP_SILENT -eq '1') { Write-Host "Failed to start '$label'." } else { [System.Windows.Forms.MessageBox]::Show("Failed to start '$label'.","Compose") | Out-Null }
}
