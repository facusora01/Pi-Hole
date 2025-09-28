# Pi-hole Domain Processor - Ultra Compact
param([switch]$DryRun, [switch]$Verbose)

# Configuration
$Root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$Dirs = @{D=Join-Path (Split-Path -Parent $MyInvocation.MyCommand.Path) "input"; W="$Root\..\etc-pihole\whitelist.txt"; B="$Root\..\etc-pihole\blacklist.txt"; L="$Root\domain-processing.log"}

# Logging function
function L($M,$T="INFO"){$E="[$(Get-Date -f 'HH:mm:ss')] [$T] $M";Write-Host $E;Add-Content $Dirs.L $E}

# Domain validation
function V($D){return $D -match '^[a-z0-9]([a-z0-9\-]{0,61}[a-z0-9])?(\.[a-z0-9]([a-z0-9\-]{0,61}[a-z0-9])?)*$'}

# Get existing domains
function E($F){if(!(Test-Path $F)){return @()};return (Get-Content $F)|%{$T=$_.Trim();if($T -and !$T.StartsWith("#")){($T -split '\s+|#')[0].Trim().ToLower()}}|?{$_}}

# Extract domains from files
function X($F,$T){$R=@();if($T -eq ".txt"){$R=(Get-Content $F)|%{$D=$_.Trim().ToLower();if(V $D){$D}}|?{$_}}elseif($T -eq ".json"){try{$J=Get-Content $F -Raw|ConvertFrom-Json;if($J.abt.hosts){$J.abt.hosts.PSObject.Properties|%{$_.Value.PSObject.Properties|%{$_.Value.PSObject.Properties|%{$D=$_.Name.ToLower();if((V $D) -and ($_.Value -eq $true)){$R+=$D}}}}}}catch{L "JSON Error $F" "ERROR"}};return $R}

# Classify file with enhanced menu
function C($F){
    $N=$F.Name
    Write-Host "`n" -F Yellow
    Write-Host ("=" * 60) -F Yellow
    Write-Host "FILE: $N" -F Cyan
    Write-Host ("=" * 60) -F Yellow
    
    if($F.Extension -eq ".txt"){
        $Content = Get-Content $F.FullName -Total 10
        Write-Host "Content (first 10 lines):" -F Green
        $Content | % { Write-Host "  $_" -F White }
        $Total = (Get-Content $F.FullName).Count
        if($Total -gt 10){ Write-Host "  ... and $($Total - 10) more lines" -F Gray }
    } else {
        Write-Host "JSON File - Analyzing structure..." -F Green
        try {
            $J = Get-Content $F.FullName -Raw | ConvertFrom-Json
            if($J.abt.hosts){
                $TotalDoms = 0
                $J.abt.hosts.PSObject.Properties | % {
                    $_.Value.PSObject.Properties | % {
                        $TotalDoms += $_.Value.PSObject.Properties.Count
                    }
                }
                Write-Host "  Contains approximately $TotalDoms ads/tracking domains" -F White
                if($J.date){ Write-Host "  Date: $($J.date)" -F Gray }
            } else {
                Write-Host "  Unrecognized JSON structure" -F Yellow
            }
        } catch {
            Write-Host "  Error reading JSON: $($_.Exception.Message)" -F Red
        }
    }
    
    Write-Host ("=" * 60) -F Yellow
    
    do {
        Write-Host "`nWhat to do with this file?" -F Cyan
        Write-Host "[W] Whitelist (allow domains)" -F Green
        Write-Host "[B] Blacklist (block domains)" -F Red
        Write-Host "[S] Skip (mark as indef_ and ignore)" -F Gray
        Write-Host "[Q] Quit script" -F Yellow
        
        $C = (Read-Host "Select [W/B/S/Q]").ToUpper()
        if($C -eq "Q"){
            L "Script cancelled by user"
            exit
        }
    } while($C -notin @("W","B","S"))
    
    $P=@{"W"="wt_";"B"="bl_";"S"="indef_"}[$C]
    $NN=$P+$N
    $NP=Join-Path (Split-Path $F.FullName) $NN
    
    if(!$DryRun){
        Rename-Item $F.FullName $NP
        $ActionType = @{"W"="WHITELIST"; "B"="BLACKLIST"; "S"="UNDEFINED"}[$C]
        L "File classified as $ActionType : $N → $NN"
    } else {
        $ActionType = @{"W"="WHITELIST"; "B"="BLACKLIST"; "S"="UNDEFINED"}[$C]
        L "[DRY RUN] Would classify as $ActionType : $N → $NN"
    }
    
    return $C -ne "S"
}

# Process domain list
function P($D,$F,$T){if(!$D){L "No domains for $T";return};$Ex=E $F;$A=$D|?{$_ -notin $Ex}|Sort -U;if($A){if(!$DryRun){Add-Content $F $A;L "Added $($A.Count) to $T"}else{L "[DRY] Would add $($A.Count) to $T"};if($Verbose){$A|%{L "  + $_"}}}else{L "No new domains for $T"}}

# Load adlists from adlists.list
function LoadAdlists() {
    $AdlistsFile = "$Root\etc-pihole\adlists.list"
    if (!(Test-Path $AdlistsFile)) {
        L "No adlists.list file found" "WARNING"
        return
    }
    
    L "=== Processing adlists.list ===" "INFO"
    
    # Read current adlists in database
    $ExistingLists = @()
    try {
        $DbResult = & docker exec pihole sqlite3 /etc/pihole/gravity.db "SELECT address FROM adlist WHERE enabled=1;" 2>$null
        if ($DbResult) {
            $ExistingLists = $DbResult -split "`n" | ForEach-Object { $_.Trim() } | Where-Object { $_ }
        }
    } catch {
        L "Could not query existing adlists" "WARNING"
    }
    
    # Read adlists.list file
    $NewLists = Get-Content $AdlistsFile | ForEach-Object {
        $Line = $_.Trim()
        if ($Line -and !$Line.StartsWith("#") -and $Line.StartsWith("http")) {
            $Line
        }
    } | Where-Object { $_ }
    
    if (!$NewLists) {
        L "No valid URLs found in adlists.list" "WARNING"
        return
    }
    
    # Add new lists to database
    $AddedCount = 0
    foreach ($Url in $NewLists) {
        if ($Url -notin $ExistingLists) {
            if (!$DryRun) {
                try {
                    $Comment = "Added by process-domains $(Get-Date -f 'yyyy-MM-dd')"
                    & docker exec pihole sqlite3 /etc/pihole/gravity.db "INSERT INTO adlist (address, enabled, comment) VALUES ('$Url', 1, '$Comment');" 2>$null
                    L "Added adlist: $Url"
                    $AddedCount++
                } catch {
                    L "Failed to add adlist: $Url" "ERROR"
                }
            } else {
                L "[DRY RUN] Would add adlist: $Url"
                $AddedCount++
            }
        }
    }
    
    if ($AddedCount -gt 0) {
        L "Added $AddedCount new adlists"
        if (!$DryRun) {
            L "Updating gravity database..."
            & docker exec pihole pihole -g 2>&1 | Out-Null
            L "Gravity database updated"
        } else {
            L "[DRY RUN] Would update gravity database"
        }
    } else {
        L "No new adlists to add"
    }
}

# Main execution
L "=== DOMAIN PROCESSING START ==="

# Step 1: Load adlists from adlists.list
LoadAdlists

# Step 2: Process domain files in input directory
L "=== Processing domain files ===" "INFO"
if(!(Test-Path $Dirs.D)){L "Input directory not found" "ERROR";return}
$Files=Get-ChildItem $Dirs.D|?{$_.Extension -in @(".txt",".json")}

if (!$Files) {
    L "No domain files found in input directory"
} else {
    $WL=@();$BL=@()
    foreach($File in $Files){$N=$File.Name;$Should=$true;if($N.StartsWith("wt_")){$Type="W"}elseif($N.StartsWith("bl_")){$Type="B"}elseif($N.StartsWith("indef_")){L "Ignoring: $N";continue}else{L "No prefix: $N";$Should=C $File;if(!$Should){continue};$New=Get-ChildItem $Dirs.D|?{$_.Name.EndsWith($N)}|select -First 1;if($New.Name.StartsWith("wt_")){$Type="W";$File=$New}elseif($New.Name.StartsWith("bl_")){$Type="B";$File=$New}};$Doms=X $File.FullName $File.Extension;L "Extracted $($Doms.Count) from $N";if($Type -eq "W"){$WL+=$Doms}else{$BL+=$Doms}}
    P $WL $Dirs.W "WHITELIST"
    P $BL $Dirs.B "BLACKLIST"
}

L "=== DOMAIN PROCESSING COMPLETE ==="
if(!$DryRun -and (Test-Path "restart-pihole-complete.ps1")){L "Restarting Pi-hole...";& ".\restart-pihole-complete.ps1"}