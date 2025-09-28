# Script rapido para reiniciar Pi-hole
# Version simplificada con sleep automatico

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

Write-Host "=== REINICIO RAPIDO PI-HOLE ===" -ForegroundColor Cyan
Write-Host "Using Pi-hole IP: $piHoleIP, Port: $webPort" -ForegroundColor Cyan

# Reiniciar Pi-hole
Write-Host "Reiniciando Pi-hole..." -ForegroundColor Yellow
docker-compose restart

# Espera inteligente
Write-Host "Esperando que Pi-hole este listo..." -ForegroundColor Yellow
$waited = 0
do {
    Start-Sleep 3
    $waited += 3
    try {
        $test = Invoke-WebRequest -Uri "http://$piHoleIP:$webPort" -TimeoutSec 2 -ErrorAction Stop
        break
    } catch {
        if ($waited -ge 30) { break }
    }
} while ($waited -lt 30)

# Aplicar configuracion automatica
Write-Host "Aplicando configuracion..." -ForegroundColor Yellow
docker exec pihole /usr/local/bin/auto-init-pihole.sh | Out-Null

# Verificacion rapida
Write-Host "Verificando..." -ForegroundColor Yellow
try {
    $blocked = Resolve-DnsName -Name "doubleclick.net" -Server "$piHoleIP" -ErrorAction Stop
    if ($blocked.IPAddress -contains "0.0.0.0") {
        Write-Host "SUCCESS: Pi-hole funcionando correctamente!" -ForegroundColor Green
    } else {
        Write-Host "WARNING: Verificacion manual requerida" -ForegroundColor Yellow
    }
} catch {
    Write-Host "WARNING: No se pudo verificar automaticamente" -ForegroundColor Yellow
}

Write-Host "Panel: http://$piHoleIP:$webPort/admin/login" -ForegroundColor Cyan