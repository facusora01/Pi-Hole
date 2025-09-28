# Pi-hole Maintenance Menu
# Usage: .\scripts\maintenance.ps1

function Show-Menu {
    Write-Host ""
    Write-Host "=== PI-HOLE MAINTENANCE MENU ===" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "[1] Start Pi-hole - Start Docker container" -ForegroundColor DarkBlue
    Write-Host "[2] Quick Flush - Clear DNS caches (30s)" -ForegroundColor Green
    Write-Host "[3] Complete Optimization - Full system check (3m)" -ForegroundColor DarkYellow
    Write-Host "[4] Full Restart - Complete system restart (5m)" -ForegroundColor Blue
    Write-Host "[5] Process Domains - Handle new domain files" -ForegroundColor Magenta
    Write-Host "[6] Verify System - Test all functionality" -ForegroundColor Cyan
    Write-Host "[7] Diagnose Low Blocking % - Browser DNS issues" -ForegroundColor DarkRed
    Write-Host "[8] Stop and Remove Docker Container" -ForegroundColor Red
    Write-Host "[0] Exit" -ForegroundColor Gray
    Write-Host ""
}

do {
    Show-Menu
    $choice = Read-Host "Select option (0-8)"
    
    switch ($choice) {
        "1" { 
            Write-Host "Starting Pi-hole..." -ForegroundColor Green
            & "$PSScriptRoot/../startup/run-auto-init.ps1"
            Read-Host "Press Enter to continue"
        }
        "2" { 
            Write-Host "Running Quick Flush..." -ForegroundColor Green
            & "$PSScriptRoot/quick-flush.ps1"
            Read-Host "Press Enter to continue"
        }
        "3" { 
            Write-Host "Running Complete Optimization..." -ForegroundColor Yellow
            & "$PSScriptRoot/optimize-pihole.ps1"
            Read-Host "Press Enter to continue"
        }
        "4" { 
            Write-Host "Running Full Restart..." -ForegroundColor Blue
            & "$PSScriptRoot/../restart/restart-pihole-complete.ps1"
            Read-Host "Press Enter to continue"
        }
        "5" { 
            Write-Host "Processing Domains..." -ForegroundColor Magenta
            & "$PSScriptRoot/../domain-processing/process-domains.ps1"
            Read-Host "Press Enter to continue"
        }
        "6" { 
            Write-Host "Verifying System..." -ForegroundColor Cyan
            & "$PSScriptRoot/verify-pihole.ps1"
            Read-Host "Press Enter to continue"
        }
        "7" { 
            Write-Host ""
            Write-Host "=== DIAGNOSIS: LOW BLOCKING PERCENTAGE ===" -ForegroundColor Red
            Write-Host ""
            Write-Host "Your Pi-hole is working correctly." -ForegroundColor Green
            Write-Host "If you see 7% in online tests, it is because:" -ForegroundColor Yellow
            Write-Host ""
            Write-Host "CAUSE #1: DNS-over-HTTPS in browser (most common)" -ForegroundColor Red
            Write-Host "  - Chrome: chrome://settings/security" -ForegroundColor White
            Write-Host "  - Firefox: about:preferences#privacy" -ForegroundColor White  
            Write-Host "  - Edge: edge://settings/privacy" -ForegroundColor White
            Write-Host "  - Look for 'Secure DNS' and DISABLE it" -ForegroundColor Yellow
            Write-Host ""
            Write-Host "CAUSE #2: Test uses dynamic CDN domains" -ForegroundColor Red
            Write-Host "CAUSE #3: Inline JavaScript (not DNS)" -ForegroundColor Red
            Write-Host ""
            Write-Host "QUICK SOLUTION:" -ForegroundColor Green
            Write-Host "1. Disable DNS-over-HTTPS in browser" -ForegroundColor White
            Write-Host "2. Test in incognito mode" -ForegroundColor White
            Write-Host "3. Use another browser to compare" -ForegroundColor White
            Write-Host ""
            Read-Host "Press Enter to continue"
        }
        "8" {
            Write-Host "Stopping and Removing Docker Container..." -ForegroundColor Red
            $runningContainers = docker ps -q
            $allContainers = docker ps -aq

            if (-not $allContainers) {
                Write-Host "No Docker containers found to stop or remove." -ForegroundColor Yellow
            } else {
                if ($runningContainers) {
                    docker stop $runningContainers | Out-Null
                    Write-Host "Stopped running Docker containers." -ForegroundColor Green
                } else {
                    Write-Host "No running Docker containers to stop." -ForegroundColor Yellow
                }

                docker rm $allContainers | Out-Null
                Write-Host "Removed all Docker containers." -ForegroundColor Green
            }

            Read-Host "Press Enter to continue"
        }
        "0" { 
            Write-Host ""
            Write-Host "Goodbye!" -ForegroundColor Cyan
            Write-Host ""
            break
        }
        default { 
            Write-Host "Invalid choice" -ForegroundColor Red
            Start-Sleep 2
        }
    }
} while ($choice -ne "0")