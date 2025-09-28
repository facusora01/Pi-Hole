# System Pre-Check Script
# Run this before installing Pi-hole to verify your system is ready

Write-Host "=== Pi-hole System Pre-Check ===" -ForegroundColor Cyan
Write-Host ""

# Check Docker installation
Write-Host "1. Checking Docker..." -ForegroundColor Yellow
try {
    $dockerVersion = docker --version 2>$null
    if ($dockerVersion) {
        Write-Host "   [OK] Docker found: $dockerVersion" -ForegroundColor Green
    } else {
        Write-Host "   [ERROR] Docker not found. Please install Docker Desktop" -ForegroundColor Red
        Write-Host "      Download from: https://docker.com/products/docker-desktop" -ForegroundColor White
    }
} catch {
    Write-Host "   [ERROR] Docker not accessible" -ForegroundColor Red
}

# Check Docker Compose
Write-Host "2. Checking Docker Compose..." -ForegroundColor Yellow
try {
    $composeVersion = docker-compose --version 2>$null
    if ($composeVersion) {
        Write-Host "   [OK] Docker Compose found: $composeVersion" -ForegroundColor Green
    } else {
        Write-Host "   [ERROR] Docker Compose not found" -ForegroundColor Red
    }
} catch {
    Write-Host "   [ERROR] Docker Compose not accessible" -ForegroundColor Red
}

# Check if Docker is running
Write-Host "3. Checking if Docker is running..." -ForegroundColor Yellow
try {
    docker ps 2>$null | Out-Null
    Write-Host "   [OK] Docker daemon is running" -ForegroundColor Green
} catch {
    Write-Host "   [ERROR] Docker daemon not running. Please start Docker Desktop" -ForegroundColor Red
}

# Check PowerShell version
Write-Host "4. Checking PowerShell version..." -ForegroundColor Yellow
$psVersion = $PSVersionTable.PSVersion
if ($psVersion.Major -ge 5) {
    Write-Host "   [OK] PowerShell $($psVersion.Major).$($psVersion.Minor) is compatible" -ForegroundColor Green
} else {
    Write-Host "   [WARNING] PowerShell $($psVersion.Major).$($psVersion.Minor) - recommend upgrading to 5.1+" -ForegroundColor Yellow
}

# Check current IP address
Write-Host "5. Detecting your IP address..." -ForegroundColor Yellow
try {
    $ip = (Get-NetIPAddress -AddressFamily IPv4 -InterfaceAlias "Ethernet*","Wi-Fi*" | Where-Object {$_.IPAddress -like "192.168.*" -or $_.IPAddress -like "10.*" -or $_.IPAddress -like "172.*"})[0].IPAddress
    if ($ip) {
        Write-Host "   [OK] Local IP detected: $ip" -ForegroundColor Green
        Write-Host "      Use this IP in your .env file: PIHOLE_SERVER_IP=$ip" -ForegroundColor White
    } else {
        Write-Host "   [WARNING] No local IP detected. Check your network connection" -ForegroundColor Yellow
    }
} catch {
    Write-Host "   [WARNING] Could not detect IP automatically" -ForegroundColor Yellow
}

# Check if ports are available
Write-Host "6. Checking required ports..." -ForegroundColor Yellow

$ports = @(53, 8080)
foreach ($port in $ports) {
    try {
        $connection = Test-NetConnection -ComputerName localhost -Port $port -InformationLevel Quiet -WarningAction SilentlyContinue
        if ($connection) {
            Write-Host "   [WARNING] Port $port is in use - may cause conflicts" -ForegroundColor Yellow
        } else {
            Write-Host "   [OK] Port $port is available" -ForegroundColor Green
        }
    } catch {
        Write-Host "   [OK] Port $port appears available" -ForegroundColor Green
    }
}

# Check admin privileges
Write-Host "7. Checking admin privileges..." -ForegroundColor Yellow
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if ($isAdmin) {
    Write-Host "   [OK] Running with admin privileges" -ForegroundColor Green
} else {
    Write-Host "   [WARNING] Not running as admin - may be needed for Docker" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "=== Pre-Check Complete ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "Next steps:" -ForegroundColor White
Write-Host "1. Fix any [ERROR] items above" -ForegroundColor White
Write-Host "2. Copy .env.example to .env" -ForegroundColor White
Write-Host "3. Edit .env with your settings" -ForegroundColor White
Write-Host "4. Run: .\scripts\maintenance.ps1" -ForegroundColor White