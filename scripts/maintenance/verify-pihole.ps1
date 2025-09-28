# Verification script to check whitelist and blacklist functionality

# Get Pi-hole IP and Port from environment variables or use defaults
$piHoleServer = $env:PIHOLE_SERVER_IP
$webPort = $env:WEB_PORT
if (-not $piHoleServer -or -not $webPort) {
    # Try to read from .env file if available
    $envFile = Join-Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) ".env"
    if (Test-Path $envFile) {
        $envContent = Get-Content $envFile
        if (-not $piHoleServer) {
            $ipLine = $envContent | Where-Object { $_ -match "^PIHOLE_SERVER_IP=" }
            if ($ipLine) { $piHoleServer = ($ipLine -split "=")[1].Trim('"').Trim("'") }
        }
        if (-not $webPort) {
            $portLine = $envContent | Where-Object { $_ -match "^WEB_PORT=" }
            if ($portLine) { $webPort = ($portLine -split "=")[1].Trim('"').Trim("'") }
        }
    }
    # Final fallbacks
    if (-not $piHoleServer) { $piHoleServer = "192.168.1.100" }
    if (-not $webPort) { $webPort = "8080" }
}

Write-Host "=== PI-HOLE FUNCTIONALITY VERIFICATION ===" -ForegroundColor Cyan
Write-Host "Using Pi-hole IP: $piHoleServer, Port: $webPort" -ForegroundColor Cyan
Write-Host ""

Write-Host "1. TESTING WHITELISTED DOMAINS (should be ALLOWED):" -ForegroundColor Green
Write-Host "==================================================="

$whitelistDomains = @("supercell.com", "clashroyale.com", "clashofclans.com")
foreach ($domain in $whitelistDomains) {
    try {
        $result = Resolve-DnsName -Name $domain -Server $piHoleServer -ErrorAction Stop
        $blocked = $result.IPAddress -contains "0.0.0.0" -or $result.IPAddress -contains "::"
        
        if ($blocked) {
            Write-Host "  [ERROR] $domain -> BLOCKED (should be allowed)" -ForegroundColor Red
        } else {
            Write-Host "  [OK] $domain -> ALLOWED" -ForegroundColor Green
        }
    } catch {
        Write-Host "  [ERROR] $domain -> Query error" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "2. TESTING BLACKLISTED DOMAINS (should be BLOCKED):" -ForegroundColor Red
Write-Host "==================================================="

$blacklistDomains = @("doubleclick.net", "googleadservices.com", "google-analytics.com")
foreach ($domain in $blacklistDomains) {
    try {
        $result = Resolve-DnsName -Name $domain -Server $piHoleServer -ErrorAction Stop
        $blocked = $result.IPAddress -contains "0.0.0.0" -or $result.IPAddress -contains "::"
        
        if ($blocked) {
            Write-Host "  [OK] $domain -> BLOCKED" -ForegroundColor Green
        } else {
            Write-Host "  [ERROR] $domain -> ALLOWED (should be blocked)" -ForegroundColor Red
        }
    } catch {
        Write-Host "  [ERROR] $domain -> Query error" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "3. TESTING NEUTRAL DOMAIN:" -ForegroundColor Yellow
Write-Host "=========================="

try {
    $result = Resolve-DnsName -Name "google.com" -Server $piHoleServer -ErrorAction Stop
    $blocked = $result.IPAddress -contains "0.0.0.0" -or $result.IPAddress -contains "::"
    
    if ($blocked) {
        Write-Host "  [INFO] google.com -> BLOCKED" -ForegroundColor Yellow
    } else {
        Write-Host "  [OK] google.com -> ALLOWED" -ForegroundColor Green
    }
} catch {
    Write-Host "  [ERROR] google.com -> Query error" -ForegroundColor Red
}

Write-Host ""
Write-Host "ADDITIONAL VERIFICATION:" -ForegroundColor Cyan
Write-Host "  * Web interface: http://$piHoleServer:$webPort/admin/login" -ForegroundColor White
Write-Host "  * Whitelist: Domains -> Allow list" -ForegroundColor White  
Write-Host "  * Blacklist: Domains -> Deny list" -ForegroundColor White
Write-Host "  * Query log: Tools -> Query Log" -ForegroundColor White
Write-Host ""