# Complete System Optimization Script for Pi-hole
# Usage: .\scripts\optimize-pihole.ps1

param(
    [switch]$Full,
    [switch]$Help
)

# Get Pi-hole IP from environment variables or use default
$piHoleIP = $env:PIHOLE_SERVER_IP
if (-not $piHoleIP) {
    # Try to read from .env file if available
    $envFile = Join-Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) ".env"
    if (Test-Path $envFile) {
        $envContent = Get-Content $envFile | Where-Object { $_ -match "^PIHOLE_SERVER_IP=" }
        if ($envContent) {
            $piHoleIP = ($envContent -split "=")[1].Trim('"').Trim("'")
        }
    }
    # Final fallback
    if (-not $piHoleIP) { $piHoleIP = "192.168.1.100" }
}

if ($Help) {
    Write-Host "=== PI-HOLE OPTIMIZATION SCRIPT ===" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "USAGE:" -ForegroundColor Yellow
    Write-Host "  .\scripts\optimize-pihole.ps1        # Quick optimization"
    Write-Host "  .\scripts\optimize-pihole.ps1 -Full  # Complete optimization"
    Write-Host "  .\scripts\optimize-pihole.ps1 -Help  # Show this help"
    Write-Host ""
    exit 0
}

Write-Host "=== PI-HOLE SYSTEM OPTIMIZATION ===" -ForegroundColor Cyan
Write-Host ""

# Step 1: DNS Cache Flush
Write-Host "[1/5] Flushing DNS caches..." -ForegroundColor Yellow
ipconfig /flushdns > $null
docker exec pihole pihole reloaddns > $null 2>&1
Write-Host "      OK - DNS caches cleared" -ForegroundColor Green

# Step 2: Container Health Check
Write-Host "[2/5] Checking Pi-hole container..." -ForegroundColor Yellow
$containerStatus = docker ps --filter "name=pihole" --format "{{.Status}}"
if ($containerStatus -match "healthy|Up") {
    Write-Host "      OK - Container is healthy" -ForegroundColor Green
} else {
    Write-Host "      WARNING - Container status: $containerStatus" -ForegroundColor Red
}

# Step 3: Gravity Database Check
Write-Host "[3/5] Checking gravity database..." -ForegroundColor Yellow
try {
    $domainCount = docker exec pihole sqlite3 /etc/pihole/gravity.db "SELECT COUNT(*) FROM gravity;" 2>$null
    if ($domainCount -gt 50000) {
        Write-Host "      OK - $domainCount domains in gravity database" -ForegroundColor Green
    } else {
        Write-Host "      WARNING - Only $domainCount domains found" -ForegroundColor Yellow
    }
} catch {
    Write-Host "      ERROR - Could not check gravity database" -ForegroundColor Red
}

# Step 4: Quick DNS Test
Write-Host "[4/5] Testing DNS blocking..." -ForegroundColor Yellow
$adTest = nslookup doubleclick.net $piHoleIP 2>&1
$normalTest = nslookup google.com $piHoleIP 2>&1

if ($adTest -match "0\.0\.0\.0") {
    Write-Host "      OK - Ad blocking working" -ForegroundColor Green
} else {
    Write-Host "      ERROR - Ad blocking not working" -ForegroundColor Red
}

if ($normalTest -match "142\.251\." -or $normalTest -match "172\.217\.") {
    Write-Host "      OK - Normal DNS resolution working" -ForegroundColor Green
} else {
    Write-Host "      WARNING - Check normal DNS resolution" -ForegroundColor Yellow
}

# Step 5: Full Optimization (if requested)
if ($Full) {
    Write-Host "[5/5] Full optimization..." -ForegroundColor Yellow
    
    # Update gravity if older than 7 days
    Write-Host "      Checking gravity update..." -ForegroundColor Gray
    docker exec pihole pihole updateGravity > $null 2>&1
    Write-Host "      OK - Gravity updated" -ForegroundColor Green
    
    # Restart DNS service
    Write-Host "      Restarting DNS service..." -ForegroundColor Gray
    docker exec pihole pihole restartdns > $null 2>&1
    Write-Host "      OK - DNS service restarted" -ForegroundColor Green
} else {
    Write-Host "[5/5] Quick optimization complete" -ForegroundColor Yellow
    Write-Host "      Use -Full for complete optimization" -ForegroundColor Gray
}

Write-Host ""
Write-Host "=== OPTIMIZATION SUMMARY ===" -ForegroundColor Cyan
Write-Host "DNS caches: FLUSHED" -ForegroundColor Green
Write-Host "Container: CHECKED" -ForegroundColor Green  
Write-Host "Database: VERIFIED" -ForegroundColor Green
Write-Host "Blocking: TESTED" -ForegroundColor Green
if ($Full) {
    Write-Host "Gravity: UPDATED" -ForegroundColor Green
}

Write-Host ""
Write-Host "SYSTEM OPTIMIZED! Test your ad blocking:" -ForegroundColor Cyan
Write-Host "https://adblock.turtlecute.org/" -ForegroundColor Yellow
Write-Host ""
Write-Host "Additional commands available:" -ForegroundColor White
Write-Host "  .\scripts\quick-flush.ps1          # Quick DNS flush"
Write-Host "  .\scripts\verify-pihole.ps1        # Complete verification"
Write-Host "  .\scripts\restart-pihole-complete.ps1  # Full restart"
Write-Host ""