<#
.SYNOPSIS
    Interactive SCCM Distribution Point Content Sync Tool

.DESCRIPTION
    User-friendly interactive script that guides you through syncing content from 
    one Distribution Point to another. Lists available DPs and provides detailed 
    progress feedback during content distribution.

.PARAMETER LogPath
    Path for log file. Default: C:\Logs\SCCM-DP-Sync_YYYYMMDD-HHMMSS.log

.EXAMPLE
    .\SCCM-DP-Content-Sync.ps1
    
    Just run the script and follow the prompts!

.NOTES
    Author: SCCM Admin Team
    Version: 3.0
    Requires: SCCM Console installed, Administrative privileges
  
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
    [string]$LogPath = "C:\Logs\SCCM-DP-Sync_$(Get-Date -Format 'yyyyMMdd-HHmmss').log"
)

#region Functions

function Write-Log {
    param(
        [string]$Message,
        [ValidateSet('INFO','SUCCESS','WARNING','ERROR','HEADER')]
        [string]$Level = 'INFO'
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] [$Level] $Message"
    
    # Ensure log directory exists
    $logDir = Split-Path -Path $LogPath -Parent
    if (-not (Test-Path $logDir)) {
        New-Item -Path $logDir -ItemType Directory -Force | Out-Null
    }
    
    # Write to log file
    Add-Content -Path $LogPath -Value $logMessage
    
    # Write to console with color
    switch ($Level) {
        'HEADER'  { Write-Host "`n$Message" -ForegroundColor Cyan }
        'SUCCESS' { Write-Host "  ✓ $Message" -ForegroundColor Green }
        'WARNING' { Write-Host "  ⚠ $Message" -ForegroundColor Yellow }
        'ERROR'   { Write-Host "  ✗ $Message" -ForegroundColor Red }
        default   { Write-Host "  $Message" -ForegroundColor White }
    }
}

function Show-Banner {
    Write-Host ""
    Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║                                                            ║" -ForegroundColor Cyan
    Write-Host "║     SCCM Distribution Point Content Sync Tool v3.0         ║" -ForegroundColor Cyan
    Write-Host "║                                                            ║" -ForegroundColor Cyan
    Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
}

function Read-UserInput {
    param(
        [string]$Prompt,
        [bool]$Mandatory = $true,
        [string]$DefaultValue = ""
    )
    
    do {
        if ($DefaultValue) {
            $input = Read-Host "$Prompt [$DefaultValue]"
            if ([string]::IsNullOrWhiteSpace($input)) {
                $input = $DefaultValue
            }
        } else {
            $input = Read-Host $Prompt
        }
        
        if ($Mandatory -and [string]::IsNullOrWhiteSpace($input)) {
            Write-Host "  ⚠ This field is required. Please enter a value." -ForegroundColor Yellow
        }
    } while ($Mandatory -and [string]::IsNullOrWhiteSpace($input))
    
    return $input.Trim()
}

function Show-Menu {
    param(
        [string]$Title,
        [array]$Options
    )
    
    Write-Host "`n$Title" -ForegroundColor Cyan
    Write-Host ("─" * 60) -ForegroundColor Cyan
    
    for ($i = 0; $i -lt $Options.Count; $i++) {
        Write-Host "  [$($i + 1)] $($Options[$i])" -ForegroundColor White
    }
    
    Write-Host ("─" * 60) -ForegroundColor Cyan
    
    do {
        $selection = Read-Host "Select option (1-$($Options.Count))"
        $valid = $selection -match '^\d+$' -and [int]$selection -ge 1 -and [int]$selection -le $Options.Count
        if (-not $valid) {
            Write-Host "  ⚠ Invalid selection. Please enter a number between 1 and $($Options.Count)" -ForegroundColor Yellow
        }
    } while (-not $valid)
    
    return [int]$selection - 1
}

function Confirm-Action {
    param([string]$Message)
    
    $response = Read-Host "$Message (Y/N)"
    return $response -match '^[Yy]'
}

#endregion

#region Main Script

$scriptStartTime = Get-Date

# Show banner
Show-Banner

Write-Log "Script started" -Level INFO
Write-Log "Log file: $LogPath" -Level INFO

# Step 1: Get Site Code
Write-Host "`n[Step 1/4] SCCM Site Configuration" -ForegroundColor Cyan
Write-Host "─────────────────────────────────────────────────────────────" -ForegroundColor Cyan
$SiteCode = Read-UserInput -Prompt "Enter SCCM Site Code (e.g., CMK, PS1)"

# Step 2: Get Provider Machine Name
$ProviderMachineName = Read-UserInput -Prompt "Enter SCCM Site Server FQDN (e.g., sccm-server.domain.com)"

Write-Log "Site Code: $SiteCode" -Level INFO
Write-Log "Provider: $ProviderMachineName" -Level INFO

# Step 3: Connect to SCCM
Write-Host "`n[Step 2/4] Connecting to SCCM" -ForegroundColor Cyan
Write-Host "─────────────────────────────────────────────────────────────" -ForegroundColor Cyan

# Import SCCM module
Write-Host "  → Importing SCCM PowerShell module..." -ForegroundColor Gray
try {
    $modulePath = "$($ENV:SMS_ADMIN_UI_PATH)\..\ConfigurationManager.psd1"
    
    if (-not (Test-Path $modulePath)) {
        throw "SCCM Console not found at: $modulePath"
    }
    
    Import-Module $modulePath -ErrorAction Stop
    Write-Log "SCCM module imported successfully" -Level SUCCESS
}
catch {
    Write-Log "Failed to import SCCM module: $($_.Exception.Message)" -Level ERROR
    exit 1
}

# Connect to site
Write-Host "  → Connecting to site $SiteCode..." -ForegroundColor Gray
try {
    if ((Get-PSDrive -Name $SiteCode -PSProvider CMSite -ErrorAction SilentlyContinue) -eq $null) {
        New-PSDrive -Name $SiteCode -PSProvider CMSite -Root $ProviderMachineName -ErrorAction Stop | Out-Null
    }
    $originalLocation = Get-Location
    Set-Location "$($SiteCode):\" -ErrorAction Stop
    Write-Log "Connected to site drive: $($SiteCode):\" -Level SUCCESS
}
catch {
    Write-Log "Failed to connect to SCCM site: $($_.Exception.Message)" -Level ERROR
    exit 1
}

# Step 4: Get and display available Distribution Points
Write-Host "`n[Step 3/4] Available Distribution Points" -ForegroundColor Cyan
Write-Host "─────────────────────────────────────────────────────────────" -ForegroundColor Cyan
Write-Host "  → Retrieving Distribution Points..." -ForegroundColor Gray

try {
    $allDPs = Get-CMDistributionPoint | Select-Object -Property NetworkOSPath, @{Name='ServerName';Expression={$_.NetworkOSPath -replace '\\\\', ''}}
    
    if ($allDPs.Count -eq 0) {
        Write-Log "No Distribution Points found in site $SiteCode" -Level ERROR
        exit 1
    }
    
    Write-Host ""
    Write-Host "  Found $($allDPs.Count) Distribution Point(s):" -ForegroundColor Green
    Write-Host ""
    
    for ($i = 0; $i -lt $allDPs.Count; $i++) {
        Write-Host "    [$($i + 1)] $($allDPs[$i].ServerName)" -ForegroundColor White
    }
    Write-Host ""
    
    Write-Log "Found $($allDPs.Count) Distribution Points" -Level SUCCESS
}
catch {
    Write-Log "Failed to retrieve Distribution Points: $($_.Exception.Message)" -Level ERROR
    exit 1
}

# Select Source DP
Write-Host "─────────────────────────────────────────────────────────────" -ForegroundColor Cyan
do {
    $sourceIndex = Read-Host "Select SOURCE Distribution Point number (1-$($allDPs.Count))"
    $validSource = $sourceIndex -match '^\d+$' -and [int]$sourceIndex -ge 1 -and [int]$sourceIndex -le $allDPs.Count
    if (-not $validSource) {
        Write-Host "  ⚠ Invalid selection" -ForegroundColor Yellow
    }
} while (-not $validSource)

$SourceDP = $allDPs[[int]$sourceIndex - 1].ServerName
Write-Host "  ✓ Source DP: $SourceDP" -ForegroundColor Green
Write-Log "Source DP selected: $SourceDP" -Level INFO

# Select Target DP
Write-Host ""
do {
    $targetIndex = Read-Host "Select TARGET Distribution Point number (1-$($allDPs.Count))"
    $validTarget = $targetIndex -match '^\d+$' -and [int]$targetIndex -ge 1 -and [int]$targetIndex -le $allDPs.Count
    
    if (-not $validTarget) {
        Write-Host "  ⚠ Invalid selection" -ForegroundColor Yellow
    } elseif ($targetIndex -eq $sourceIndex) {
        Write-Host "  ⚠ Source and Target cannot be the same!" -ForegroundColor Yellow
        $validTarget = $false
    }
} while (-not $validTarget)

$TargetDP = $allDPs[[int]$targetIndex - 1].ServerName
Write-Host "  ✓ Target DP: $TargetDP" -ForegroundColor Green
Write-Log "Target DP selected: $TargetDP" -Level INFO

# Confirmation
Write-Host "`n[Step 4/4] Confirmation" -ForegroundColor Cyan
Write-Host "─────────────────────────────────────────────────────────────" -ForegroundColor Cyan
Write-Host ""
Write-Host "  Configuration Summary:" -ForegroundColor White
Write-Host "  ├─ Site Code      : $SiteCode" -ForegroundColor Gray
Write-Host "  ├─ Site Server    : $ProviderMachineName" -ForegroundColor Gray
Write-Host "  ├─ Source DP      : $SourceDP" -ForegroundColor Gray
Write-Host "  └─ Target DP      : $TargetDP" -ForegroundColor Gray
Write-Host ""

if (-not (Confirm-Action "  Do you want to proceed with content distribution?")) {
    Write-Log "Operation cancelled by user" -Level WARNING
    Set-Location $originalLocation
    exit 0
}

# Initialize statistics
$stats = @{
    Packages = @{Success=0; Failed=0; Total=0}
    Applications = @{Success=0; Failed=0; Total=0}
    BootImages = @{Success=0; Failed=0; Total=0}
    OSImages = @{Success=0; Failed=0; Total=0}
    DriverPackages = @{Success=0; Failed=0; Total=0}
    SoftwareUpdates = @{Success=0; Failed=0; Total=0}
    TaskSequences = @{Success=0; Failed=0; Total=0}
}

Write-Host "`n" 
Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║            Starting Content Distribution                   ║" -ForegroundColor Green
Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Green

# Function to distribute content with detailed output
function Distribute-ContentType {
    param(
        [string]$TypeName,
        [scriptblock]$GetContent,
        [scriptblock]$DistributeAction,
        [string]$StatsKey
    )
    
    Write-Host "`n┌─────────────────────────────────────────────────────────┐" -ForegroundColor Cyan
    Write-Host "│ $($TypeName.PadRight(55)) │" -ForegroundColor Cyan
    Write-Host "└─────────────────────────────────────────────────────────┘" -ForegroundColor Cyan
    
    Write-Host "  → Retrieving $TypeName..." -ForegroundColor Gray
    
    try {
        $items = & $GetContent
        $stats[$StatsKey].Total = $items.Count
        
        if ($items.Count -eq 0) {
            Write-Host "  ⊘ No $TypeName found" -ForegroundColor DarkGray
            Write-Log "No $TypeName to distribute" -Level INFO
            return
        }
        
        Write-Host "  → Found $($items.Count) item(s)" -ForegroundColor Gray
        Write-Log "Processing $($items.Count) $TypeName" -Level INFO
        Write-Host ""
        
        $current = 0
        foreach ($item in $items) {
            $current++
            $itemName = if ($item.LocalizedDisplayName) { $item.LocalizedDisplayName } 
                       elseif ($item.Name) { $item.Name } 
                       else { $item.PackageID }
            
            $progress = "[$current/$($items.Count)]"
            Write-Host "  $progress " -NoNewline -ForegroundColor DarkGray
            Write-Host "$itemName" -NoNewline -ForegroundColor White
            
            try {
                & $DistributeAction -Item $item
                Write-Host " ✓" -ForegroundColor Green
                Write-Log "$TypeName distributed: $itemName" -Level SUCCESS
                $stats[$StatsKey].Success++
            }
            catch {
                Write-Host " ✗" -ForegroundColor Red
                Write-Host "      └─ Error: $($_.Exception.Message)" -ForegroundColor Red
                Write-Log "$TypeName failed: $itemName - $($_.Exception.Message)" -Level ERROR
                $stats[$StatsKey].Failed++
            }
            
            Start-Sleep -Milliseconds 50
        }
    }
    catch {
        Write-Host "  ✗ Failed to retrieve $TypeName : $($_.Exception.Message)" -ForegroundColor Red
        Write-Log "Failed to retrieve $TypeName : $($_.Exception.Message)" -Level ERROR
    }
}

# 1. Packages
Distribute-ContentType -TypeName "Packages" -StatsKey "Packages" `
    -GetContent { Get-CMPackage } `
    -DistributeAction { param($Item) Start-CMContentDistribution -PackageId $Item.PackageID -DistributionPointName $TargetDP -ErrorAction Stop }

# 2. Applications
Distribute-ContentType -TypeName "Applications" -StatsKey "Applications" `
    -GetContent { Get-CMApplication } `
    -DistributeAction { param($Item) Start-CMContentDistribution -ApplicationName $Item.LocalizedDisplayName -DistributionPointName $TargetDP -ErrorAction Stop }

# 3. Boot Images
Distribute-ContentType -TypeName "Boot Images" -StatsKey "BootImages" `
    -GetContent { Get-CMBootImage } `
    -DistributeAction { param($Item) Start-CMContentDistribution -BootImageId $Item.PackageID -DistributionPointName $TargetDP -ErrorAction Stop }

# 4. OS Images
Distribute-ContentType -TypeName "OS Images" -StatsKey "OSImages" `
    -GetContent { Get-CMOperatingSystemImage } `
    -DistributeAction { param($Item) Start-CMContentDistribution -OperatingSystemImageId $Item.PackageID -DistributionPointName $TargetDP -ErrorAction Stop }

# 5. Driver Packages
Distribute-ContentType -TypeName "Driver Packages" -StatsKey "DriverPackages" `
    -GetContent { Get-CMDriverPackage } `
    -DistributeAction { param($Item) Start-CMContentDistribution -DriverPackageId $Item.PackageID -DistributionPointName $TargetDP -ErrorAction Stop }

# 6. Software Update Packages
Distribute-ContentType -TypeName "Software Update Packages" -StatsKey "SoftwareUpdates" `
    -GetContent { Get-CMSoftwareUpdateDeploymentPackage } `
    -DistributeAction { param($Item) Start-CMContentDistribution -DeploymentPackageId $Item.PackageID -DistributionPointName $TargetDP -ErrorAction Stop }

# 7. Task Sequences
Distribute-ContentType -TypeName "Task Sequences" -StatsKey "TaskSequences" `
    -GetContent { Get-CMTaskSequence } `
    -DistributeAction { param($Item) Start-CMContentDistribution -TaskSequenceId $Item.PackageID -DistributionPointName $TargetDP -ErrorAction Stop }

# Calculate totals
$totalItems = ($stats.Values | ForEach-Object { $_.Total } | Measure-Object -Sum).Sum
$totalSuccess = ($stats.Values | ForEach-Object { $_.Success } | Measure-Object -Sum).Sum
$totalFailed = ($stats.Values | ForEach-Object { $_.Failed } | Measure-Object -Sum).Sum

$scriptEndTime = Get-Date
$duration = $scriptEndTime - $scriptStartTime

# Final Summary
Write-Host "`n"
Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║                    DISTRIBUTION SUMMARY                    ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

foreach ($key in $stats.Keys | Sort-Object) {
    $stat = $stats[$key]
    if ($stat.Total -gt 0) {
        $successRate = [math]::Round(($stat.Success / $stat.Total) * 100, 1)
        $statusColor = if ($stat.Failed -eq 0) { "Green" } elseif ($stat.Success -eq 0) { "Red" } else { "Yellow" }
        
        Write-Host "  $($key.PadRight(25)): " -NoNewline
        Write-Host "$($stat.Success)/$($stat.Total) " -NoNewline -ForegroundColor $statusColor
        Write-Host "($successRate%)" -ForegroundColor Gray
        
        if ($stat.Failed -gt 0) {
            Write-Host "    └─ Failed: $($stat.Failed)" -ForegroundColor Red
        }
    }
}

Write-Host ""
Write-Host "  ─────────────────────────────────────────────────────────" -ForegroundColor Gray
Write-Host "  Total Items   : $totalItems" -ForegroundColor White
Write-Host "  Successful    : " -NoNewline
Write-Host "$totalSuccess" -ForegroundColor Green
Write-Host "  Failed        : " -NoNewline
Write-Host "$totalFailed" -ForegroundColor $(if ($totalFailed -eq 0) { "Green" } else { "Red" })
Write-Host "  Success Rate  : " -NoNewline
$overallRate = if ($totalItems -gt 0) { [math]::Round(($totalSuccess / $totalItems) * 100, 1) } else { 0 }
Write-Host "$overallRate%" -ForegroundColor $(if ($overallRate -eq 100) { "Green" } elseif ($overallRate -ge 80) { "Yellow" } else { "Red" })
Write-Host "  Duration      : $($duration.Hours)h $($duration.Minutes)m $($duration.Seconds)s" -ForegroundColor Gray
Write-Host ""

if ($totalFailed -eq 0) {
    Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Green
    Write-Host "║          ✓ Content Distribution Completed Successfully!    ║" -ForegroundColor Green
    Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Green
} else {
    Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Yellow
    Write-Host "║      ⚠ Content Distribution Completed with Errors          ║" -ForegroundColor Yellow
    Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "  Monitor progress in:" -ForegroundColor Cyan
Write-Host "  SCCM Console > Monitoring > Distribution Status > Content Status" -ForegroundColor Gray
Write-Host ""
Write-Host "  Log file: $LogPath" -ForegroundColor Gray
Write-Host ""

Write-Log "Script completed - Success: $totalSuccess, Failed: $totalFailed, Duration: $($duration.TotalMinutes) minutes" -Level INFO

# Return to original location
Set-Location $originalLocation

# Exit with appropriate code
exit $(if ($totalFailed -eq 0) { 0 } else { 1 })

#endregion