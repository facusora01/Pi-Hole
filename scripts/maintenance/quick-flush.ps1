# Quick DNS Flush Script for Pi-hole
# Usage: .\scripts\quick-flush.ps1

Write-Host "=== QUICK DNS FLUSH ===" -ForegroundColor Cyan
Write-Host ""

Write-Host "[1/4] Flushing Windows DNS cache..." -ForegroundColor Yellow
ipconfig /flushdns > $null
Write-Host "      OK - Windows DNS cache cleared" -ForegroundColor Green

Write-Host "[2/4] Reloading Pi-hole DNS..." -ForegroundColor Yellow  
docker exec pihole pihole reloaddns > $null 2>&1
Write-Host "      OK - Pi-hole DNS reloaded" -ForegroundColor Green

Write-Host "[3/4] Clearing browser caches..." -ForegroundColor Yellow

$browsersFound = @()

# Check and clear Chrome cache
$chromeUserData = "$env:LOCALAPPDATA\Google\Chrome\User Data"
if (Test-Path $chromeUserData) {
    $chromePaths = @(
        "$chromeUserData\Default\Cache\*",
        "$chromeUserData\Default\Code Cache\*"
    )
    foreach ($path in $chromePaths) {
        if (Test-Path $path) {
            try {
                Remove-Item -Path $path -Recurse -Force -ErrorAction SilentlyContinue
            } catch {}
        }
    }
    $browsersFound += "Chrome"
}

# Check and clear Edge cache
$edgeUserData = "$env:LOCALAPPDATA\Microsoft\Edge\User Data"
if (Test-Path $edgeUserData) {
    $edgePaths = @(
        "$edgeUserData\Default\Cache\*",
        "$edgeUserData\Default\Code Cache\*"
    )
    foreach ($path in $edgePaths) {
        if (Test-Path $path) {
            try {
                Remove-Item -Path $path -Recurse -Force -ErrorAction SilentlyContinue
            } catch {}
        }
    }
    $browsersFound += "Edge"
}

# Check and clear Firefox cache
$firefoxPath = "$env:APPDATA\Mozilla\Firefox\Profiles"
if (Test-Path $firefoxPath) {
    Get-ChildItem -Path $firefoxPath -Directory | ForEach-Object {
        $cachePath = Join-Path $_.FullName "cache2\*"
        if (Test-Path $cachePath) {
            try {
                Remove-Item -Path $cachePath -Recurse -Force -ErrorAction SilentlyContinue
            } catch {}
        }
    }
    $browsersFound += "Firefox"
}

# Check and clear Opera cache
$operaPath = "$env:APPDATA\Opera Software\Opera Stable"
if (Test-Path $operaPath) {
    $operaCachePaths = @(
        "$operaPath\Cache\*",
        "$operaPath\Code Cache\*"
    )
    foreach ($path in $operaCachePaths) {
        if (Test-Path $path) {
            try {
                Remove-Item -Path $path -Recurse -Force -ErrorAction SilentlyContinue
            } catch {}
        }
    }
    $browsersFound += "Opera"
}

# Check and clear Brave cache
$bravePath = "$env:LOCALAPPDATA\BraveSoftware\Brave-Browser\User Data"
if (Test-Path $bravePath) {
    $braveCachePaths = @(
        "$bravePath\Default\Cache\*",
        "$bravePath\Default\Code Cache\*"
    )
    foreach ($path in $braveCachePaths) {
        if (Test-Path $path) {
            try {
                Remove-Item -Path $path -Recurse -Force -ErrorAction SilentlyContinue
            } catch {}
        }
    }
    $browsersFound += "Brave"
}

if ($browsersFound.Count -gt 0) {
    $browserList = $browsersFound -join ", "
    Write-Host "      OK - Cache cleared for: $browserList" -ForegroundColor Green
} else {
    Write-Host "      INFO - No common browsers found" -ForegroundColor DarkYellow
}

Write-Host "[4/4] System ready..." -ForegroundColor Yellow
Write-Host "      OK - All caches flushed" -ForegroundColor Green

Write-Host ""
Write-Host "COMPLETED! Test your ad blocking at:" -ForegroundColor Cyan
Write-Host "https://adblock.turtlecute.org/" -ForegroundColor Yellow
Write-Host ""
Write-Host "NOTE: Close and reopen browsers for full effect" -ForegroundColor DarkYellow
Write-Host ""