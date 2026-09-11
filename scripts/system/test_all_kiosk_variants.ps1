# [AI-EDIT] Agent: Antigravity | Model: Hermes-3-Llama-3.1-8B | Date: 2026-09-11 | Reason: Automated Multi-Variant Hyper-V VM Testing & Auto-Debugging
<#
.SYNOPSIS
    Automated Multi-Variant VM Testing and Auto-Debugging for VKS Kiosk Appliances.
.DESCRIPTION
    Provisions, configures, and boots test VMs for each kiosk variant:
      1. VKS Video Kiosk (vks)
      2. Data Transfer Station (transfer)
      3. Debian Live / Rescue (live)
    Opens interactive VM windows (vmconnect.exe) so the administrator can see the VMs live,
    logs diagnostic telemetry, and runs local AI auto-debugging via Hermes-3 on port 8000.
.NOTES
    Default credentials:
      Kiosk User: Kiosk / Kiosk
      Root User:  root  / Master
#>

[CmdletBinding()]
param(
    [string]$IsoPath = "C:\GitHub\vks_kiosk\Windows\vks-kiosk-debian-13.4.0.iso",
    [string[]]$Variants = @("vks", "transfer", "live"),
    [int]$MemoryGB = 4,
    [switch]$LaunchVmConnect = $true,
    [string]$LlmEndpoint = "http://localhost:8000"
)

$ErrorActionPreference = "Continue"

Write-Host "============================================================" -ForegroundColor Cyan
Write-Host " VKS Kiosk Multi-Variant Automated VM Test Suite " -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan

# 0. Defaults & Paths
$repoRoot = (Resolve-Path "$PSScriptRoot\..\..").Path
$logsDir  = Join-Path $repoRoot "logs"
if (-not (Test-Path $logsDir)) { New-Item -ItemType Directory -Path $logsDir -Force | Out-Null }

$defaultUser = "Kiosk"
$defaultPass = "Kiosk"
$rootUser    = "root"
$rootPass    = "Master"

Write-Host "[INIT] Target ISO: $IsoPath" -ForegroundColor Gray
Write-Host "[INIT] Credentials: $defaultUser / $defaultPass (Root: $rootUser / $rootPass)" -ForegroundColor Gray
Write-Host "[INIT] Local LLM: $LlmEndpoint (Hermes-3-Llama-3.1-8B)" -ForegroundColor Gray

# Verify ISO exists
if (-not (Test-Path $IsoPath)) {
    Write-Error "ISO not found at $IsoPath"
    exit 1
}

$results = @()

foreach ($variant in $Variants) {
    $vmName = "VKS-Kiosk-Test-$($variant.ToUpper())"
    $logFile = Join-Path $logsDir "vm_debug_$variant.log"
    
    Write-Host "`n------------------------------------------------------------" -ForegroundColor Yellow
    Write-Host "[TEST] Starting Test for Variant: $variant ($vmName)" -ForegroundColor Yellow
    Write-Host "------------------------------------------------------------" -ForegroundColor Yellow

    # 1. Provision VM if not existing
    $existingVm = Get-VM -Name $vmName -ErrorAction SilentlyContinue
    if (-not $existingVm) {
        Write-Host "  -> Creating Generation 2 VM '$vmName' ($MemoryGB GB RAM)..." -ForegroundColor Cyan
        New-VM -Name $vmName -MemoryStartupBytes ([int64]$MemoryGB * 1GB) -Generation 2 | Out-Null
    } else {
        Write-Host "  -> VM '$vmName' exists. Re-verifying configuration..." -ForegroundColor Cyan
    }

    # 2. Configure UEFI Firmware & DVD
    Set-VMFirmware -VMName $vmName -EnableSecureBoot Off
    $dvd = Get-VMDvdDrive -VMName $vmName
    if (-not $dvd) {
        $dvd = Add-VMDvdDrive -VMName $vmName -Path $IsoPath -Passthru
    } else {
        Set-VMDvdDrive -VMName $vmName -Path $IsoPath
    }
    Set-VMFirmware -VMName $vmName -FirstBootDevice $dvd

    # Connect to virtual switch
    Connect-VMNetworkAdapter -VMName $vmName -SwitchName "Default Switch" -ErrorAction SilentlyContinue

    # 3. Start VM
    $vmState = (Get-VM -Name $vmName).State
    if ($vmState -ne 'Running') {
        Write-Host "  -> Powering on VM '$vmName'..." -ForegroundColor Green
        Start-VM -Name $vmName
    } else {
        Write-Host "  -> VM '$vmName' is already running." -ForegroundColor Green
    }

    # 4. Open VM Console GUI (vmconnect.exe) so user can see it
    if ($LaunchVmConnect) {
        Write-Host "  -> Launching VM Connection Window (vmconnect.exe)..." -ForegroundColor Magenta
        Start-Process -FilePath "vmconnect.exe" -ArgumentList "localhost", $vmName -WindowStyle Normal
    }

    # 5. Collect Diagnostics & Telemetry
    Start-Sleep -Seconds 6
    $vmInfo = Get-VM -Name $vmName | Select-Object Name, State, CpuUsage, MemoryAssigned, Uptime, Status

    $logContent = @"
=== VKS Kiosk Appliance VM Test Log ===
Timestamp: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
VM Name: $vmName
Variant: $variant
State: $($vmInfo.State)
CPU Usage: $($vmInfo.CpuUsage)%
Memory Assigned: $([math]::Round($vmInfo.MemoryAssigned / 1MB, 2)) MB
Uptime: $($vmInfo.Uptime)
Status: $($vmInfo.Status)
ISO Path: $IsoPath
Default Login Accounts:
  - User: $defaultUser (Password: $defaultPass)
  - Root: $rootUser (Password: $rootPass)
Network Adapters:
$((Get-VMNetworkAdapter -VMName $vmName | Select-Object Name, IPAddresses, Status) | Out-String)
Firmware:
$((Get-VMFirmware -VMName $vmName | Select-Object SecureBoot, FirstBootDevice) | Out-String)
=== End Telemetry ===
"@
    Set-Content -Path $logFile -Value $logContent -Encoding utf8
    Write-Host "  -> Telemetry recorded to $logFile" -ForegroundColor Gray

    # 6. Execute Local LLM Auto-Debug using Hermes-3
    Write-Host "  -> Running AI Auto-Debugger (Hermes-3 @ port 8000)..." -ForegroundColor Cyan
    $autoDebugScript = Join-Path $repoRoot "infra\auto_debug.py"
    $debugResult = & python $autoDebugScript $logFile $variant 2>&1
    Write-Host "  $debugResult" -ForegroundColor Gray

    $results += [PSCustomObject]@{
        Variant = $variant
        VMName  = $vmName
        State   = $vmInfo.State
        CPU     = "$($vmInfo.CpuUsage)%"
        Memory  = "$([math]::Round($vmInfo.MemoryAssigned / 1MB, 0)) MB"
        LogFile = $logFile
        Suggestions = (Join-Path $logsDir "debug_suggestions_$variant.md")
    }
}

Write-Host "`n============================================================" -ForegroundColor Green
Write-Host " Test Execution Completed " -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Green
$results | Format-Table -AutoSize
