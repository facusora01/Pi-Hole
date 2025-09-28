# Script to run auto-init after restarting Pi-hole
# Use it after docker-compose restart or docker-compose up -d

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

Write-Host ""
Write-Host "=== PI-HOLE STARTUP MANAGER ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "Using Pi-hole IP: $piHoleIP, Port: $webPort" -ForegroundColor Cyan
Write-Host ""

# Check if Pi-hole container is already running
Write-Host "Checking Pi-hole container status..." -ForegroundColor Yellow
$runningPihole = docker ps --filter "name=pihole" --format "{{.Names}}" | Select-String "pihole"

if ($runningPihole) {
    Write-Host ""
    Write-Host " Pi-hole is already running!" -ForegroundColor Green
    Write-Host ""
    
    # Show container status
    Write-Host "Container Status:" -ForegroundColor Cyan
    docker ps --filter "name=pihole" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
    Write-Host ""
    
    Write-Host 'Container is healthy. Options:' -ForegroundColor Yellow
    Write-Host ""
    Write-Host "   - Access web interface: http://${piHoleIP}:${webPort}/admin" -ForegroundColor White
    Write-Host '   - Run verification: .\scripts\maintenance\verify-pihole.ps1' -ForegroundColor White
    Write-Host '   - For full restart: .\scripts\restart\restart-pihole-complete.ps1' -ForegroundColor White
    Write-Host ""
    
    return
}

# Start Pi-hole container if not running
Write-Host "Starting Pi-hole container..." -ForegroundColor Green
$startResult = docker compose up -d 2>&1

if ($LASTEXITCODE -ne 0) {
    Write-Host ""
    Write-Host " Error starting Pi-hole:" -ForegroundColor Red
    Write-Host $startResult -ForegroundColor Yellow
    Write-Host ""
    Write-Host " Troubleshooting tips:" -ForegroundColor Yellow
    Write-Host "   - Make sure Docker Desktop is running" -ForegroundColor White
    Write-Host "   - Check if ports 53 and 8080 are available" -ForegroundColor White
    Write-Host "   - Verify .env file configuration" -ForegroundColor White
    Write-Host ""
    exit 1
}

Write-Host " Pi-hole container started successfully!" -ForegroundColor Green

# Wait for container to be fully started
Write-Host "Waiting for Pi-hole to initialize completely..." -ForegroundColor Yellow
Start-Sleep 10

# Verify container is running
$containerStatus = docker ps --filter "name=pihole" --format "{{.Status}}"
if (-not $containerStatus) {
    Write-Host "ERROR: Pi-hole container is not running" -ForegroundColor Red
    exit 1
}

Write-Host "Container running: $containerStatus" -ForegroundColor Green

# Execute auto-init script inside container
Write-Host ""
Write-Host "Executing auto-init-pihole.sh..." -ForegroundColor Yellow

try {
    # Execute the script
    docker exec pihole /usr/local/bin/auto-init-pihole.sh
    
    Write-Host ""
    Write-Host "SUCCESS: Auto-init executed successfully" -ForegroundColor Green
    
    # Check if completion mark file was created
    docker exec pihole test -f /etc/pihole/.auto-init-completed
    if ($LASTEXITCODE -eq 0) {
        $markInfo = docker exec pihole cat /etc/pihole/.auto-init-completed
        Write-Host "Completion mark: $markInfo" -ForegroundColor Green
    }
    
} catch {
    Write-Host "ERROR: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host 'SUCCESS: PI-HOLE STARTUP COMPLETED!' -ForegroundColor Green
Write-Host ""
Write-Host 'Access your Pi-hole:' -ForegroundColor Cyan
Write-Host "   Web Interface: http://${piHoleIP}:${webPort}/admin" -ForegroundColor White
Write-Host "   Configure your router's DNS to: $piHoleIP" -ForegroundColor White
Write-Host ""
Write-Host 'Next steps:' -ForegroundColor Yellow
Write-Host '   - Run verification: .\scripts\maintenance\verify-pihole.ps1' -ForegroundColor White
Write-Host '   - Open maintenance menu: .\scripts\maintenance\maintenance.ps1' -ForegroundColor White
Write-Host ""