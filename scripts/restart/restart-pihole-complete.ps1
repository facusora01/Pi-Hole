# Complete script to restart Pi-hole with auto-configuration
# This script restarts Pi-hole and automatically applies whitelist and blacklist

param(
    [switch]$Help
)

# Get Pi-hole IP and Port from environment variables or use defaults
$piHoleIP = $env:PIHOLE_SERVER_IP
$webPort = $env:WEB_PORT
if (-not $piHoleIP -or -not $webPort) {
    # Try to read from .env file if available
    $envFile = Join-Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) ".env"
    if (Test-Path $envFile) {
        $envContent = Get-Content $envFile
        if (-not $piHoleIP) {
            $ipLine = $envContent | Where-Object { $_ -match "^PIHOLE_SERVER_IP=" }
            if ($ipLine) { $piHoleIP = ($ipLine -split "=")[1].Trim('"').Trim("'") }
        }
        if (-not $webPort) {
            $portLine = $envContent | Where-Object { $_ -match "^WEB_PORT=" }
            if ($portLine) { $webPort = ($portLine -split "=")[1].Trim('"').Trim("'") }
        }
    }
    # Final fallbacks
    if (-not $piHoleIP) { $piHoleIP = "192.168.1.100" }
    if (-not $webPort) { $webPort = "8080" }
}
Write-Host "Using Pi-hole IP: $piHoleIP, Port: $webPort" -ForegroundColor Cyan

if ($Help) {
    Write-Host "=== PI-HOLE COMPLETE RESTART SCRIPT ===" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "This script:" -ForegroundColor Yellow
    Write-Host "  1. Restarts the Pi-hole container" -ForegroundColor White
    Write-Host "  2. Automatically executes auto-init" -ForegroundColor White
    Write-Host "  3. Applies whitelist.txt and blacklist.txt" -ForegroundColor White
    Write-Host "  4. Verifies everything works correctly" -ForegroundColor White
    Write-Host ""
    Write-Host "Usage:" -ForegroundColor Yellow
    Write-Host "  .\restart-pihole-complete.ps1        # Complete restart" -ForegroundColor White
    Write-Host "  .\restart-pihole-complete.ps1 -Help  # This help" -ForegroundColor White
    exit 0
}

Write-Host "=== PI-HOLE COMPLETE RESTART WITH AUTO-CONFIGURATION ===" -ForegroundColor Cyan
Write-Host ""

# Step 1: Restart container
Write-Host "1. Restarting Pi-hole container..." -ForegroundColor Yellow
docker-compose restart
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Could not restart container" -ForegroundColor Red
    exit 1
}
Write-Host "   OK: Container restarted" -ForegroundColor Green

# Step 2: Wait for complete initialization
Write-Host ""
Write-Host "2. Waiting for complete initialization..." -ForegroundColor Yellow

# Smart wait - verify Pi-hole is ready
$maxWaitTime = 60 # Maximum 60 seconds
$checkInterval = 3 # Check every 3 seconds
$waited = 0

do {
    Start-Sleep $checkInterval
    $waited += $checkInterval
    
    # Check if container is running
    $containerStatus = docker ps --filter "name=pihole" --format "{{.Status}}"
    if (-not $containerStatus) {
        Write-Host "ERROR: Container is not running" -ForegroundColor Red
        exit 1
    }
    
    # Try to connect to Pi-hole service
    try {
        $testConnection = Invoke-WebRequest -Uri "http://$piHoleIP:$webPort" -TimeoutSec 2 -ErrorAction Stop
        Write-Host "   OK: Pi-hole responding (waited $waited seconds)" -ForegroundColor Green
        break
    } catch {
        Write-Host "   Waiting... ($waited/$maxWaitTime seconds)" -ForegroundColor Yellow
    }
    
    if ($waited -ge $maxWaitTime) {
        Write-Host "WARNING: Pi-hole taking time to respond, continuing..." -ForegroundColor Yellow
        break
    }
} while ($waited -lt $maxWaitTime)

# Small additional pause to ensure everything is ready
Start-Sleep 3
Write-Host "   Status: $containerStatus" -ForegroundColor Green

# Step 3: Execute auto-init with retries
Write-Host ""
Write-Host "3. Executing auto-configuration..." -ForegroundColor Yellow

$maxRetries = 3
$retryCount = 0

do {
    try {
        $retryCount++
        if ($retryCount -gt 1) {
            Write-Host "   Attempt $retryCount/$maxRetries..." -ForegroundColor Yellow
            Start-Sleep 5
        }
        
        # Execute auto-init script
        $output = docker exec pihole /usr/local/bin/auto-init-pihole.sh 2>&1
        
        # Show relevant output
        $output | Where-Object { $_ -match "Adding|Removing|Applying|ERROR|OK" } | Out-Host
        
        # Check for critical errors
        if ($output -match "ERROR" -and $output -notmatch "Already exists") {
            throw "Critical errors found in auto-configuration"
        }
        
        Write-Host "   OK: Auto-configuration completed (attempt $retryCount)" -ForegroundColor Green
        break
        
    } catch {
        Write-Host "   WARNING: Attempt $retryCount failed: $($_.Exception.Message)" -ForegroundColor Yellow
        
        if ($retryCount -ge $maxRetries) {
            Write-Host "   ERROR: Auto-configuration failed after $maxRetries attempts" -ForegroundColor Red
            Write-Host "   Continuing with verification..." -ForegroundColor Yellow
            break
        }
    }
} while ($retryCount -lt $maxRetries)

# Step 4: Verify functionality
Write-Host ""
Write-Host "4. Verifying functionality..." -ForegroundColor Yellow

# Quick tests
$testResults = @{
    whitelist = 0
    blacklist = 0
    neutral = 0
}

# Test whitelist
try {
    $result = Resolve-DnsName -Name "supercell.com" -Server "$piHoleIP" -ErrorAction Stop
    $blocked = $result.IPAddress -contains "0.0.0.0"
    if (-not $blocked) { $testResults.whitelist = 1 }
} catch { }

# Test blacklist
try {
    $result = Resolve-DnsName -Name "doubleclick.net" -Server "$piHoleIP" -ErrorAction Stop
    $blocked = $result.IPAddress -contains "0.0.0.0"
    if ($blocked) { $testResults.blacklist = 1 }
} catch { }

# Test neutral
try {
    $result = Resolve-DnsName -Name "google.com" -Server "$piHoleIP" -ErrorAction Stop
    $blocked = $result.IPAddress -contains "0.0.0.0"
    if (-not $blocked) { $testResults.neutral = 1 }
} catch { }

# Show results
Write-Host "   Whitelist: $(if ($testResults.whitelist) { 'OK' } else { 'ERROR' })" -ForegroundColor $(if ($testResults.whitelist) { 'Green' } else { 'Red' })
Write-Host "   Blacklist: $(if ($testResults.blacklist) { 'OK' } else { 'ERROR' })" -ForegroundColor $(if ($testResults.blacklist) { 'Green' } else { 'Red' })
Write-Host "   Neutral:   $(if ($testResults.neutral) { 'OK' } else { 'ERROR' })" -ForegroundColor $(if ($testResults.neutral) { 'Green' } else { 'Red' })

$totalPassed = $testResults.whitelist + $testResults.blacklist + $testResults.neutral

Write-Host ""
if ($totalPassed -eq 3) {
    Write-Host "SUCCESS: ALL TESTS PASSED!" -ForegroundColor Green
    Write-Host ""
    Write-Host "CONFIGURATION COMPLETED:" -ForegroundColor Cyan
    Write-Host "  * Pi-hole working correctly" -ForegroundColor White
    Write-Host "  * Whitelist and blacklist automatically applied" -ForegroundColor White
    Write-Host "  * Configuration persistent across restarts" -ForegroundColor White
    Write-Host ""
    Write-Host "WEB INTERFACE:" -ForegroundColor Cyan
    Write-Host "  * Panel: http://$piHoleIP:$webPort/admin/login" -ForegroundColor White
    Write-Host "  * Password: Mondongo123" -ForegroundColor White
    Write-Host ""
    Write-Host "IMPORTANT FILES:" -ForegroundColor Cyan
    Write-Host "  * ./etc-pihole/whitelist.txt - Domains to allow" -ForegroundColor White
    Write-Host "  * ./etc-pihole/blacklist.txt - Domains to block" -ForegroundColor White
    Write-Host "  * After editing them, run this script to apply changes" -ForegroundColor White
} else {
    Write-Host "WARNING: $($3 - $totalPassed) tests failed" -ForegroundColor Yellow
    Write-Host "Run: .\verify-pihole.ps1 for detailed diagnostics" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "NOTE: In future restarts, just run this script to" -ForegroundColor Yellow
Write-Host "      automatically apply your custom lists." -ForegroundColor Yellow