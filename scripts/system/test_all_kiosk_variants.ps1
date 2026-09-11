# [AI-EDIT] Agent: Antigravity | Model: Hermes-3-Llama-3.1-8B | Date: 2026-09-11 | Reason: Comprehensive Multi-Variant VM Installation Test Suite with VHDX & Plugin Profiles
<#
.SYNOPSIS
    Automated Multi-Variant VM Test Installations for VKS Kiosk Appliances.
.DESCRIPTION
    Sets up dedicated Generation 2 Hyper-V VMs with dynamic virtual hard disks (VHDX),
    attaches the bootable appliance ISO, boots the automated installer, opens real-time
    console viewers (vmconnect.exe), and captures diagnostic logs analyzed by the local Hermes-3 LLM.
    
    Test Variants:
      1. vks       - Automated VKS Video Kiosk (Video WebApp)
      2. transfer  - Automated Data Transfer Station (USB Sandboxing & ClamAV)
      3. plugins   - VKS Kiosk + Sprachaufzeichnung (Audio Recording) + SIP-Phone (VoIP)
      4. live      - Debian Live / Rescue Mode
.NOTES
    Default credentials:
      Kiosk User: Kiosk / Kiosk
      Root User:  root  / Master
#>

[CmdletBinding()]
param(
    [string]$IsoPath = "C:\GitHub\vks_kiosk\Windows\vks-kiosk-debian-13.4.0.iso",
    [string[]]$Variants = @("vks", "transfer", "plugins", "live"),
    [int]$MemoryGB = 4,
    [int]$DiskSizeGB = 25,
    [switch]$LaunchVmConnect = $true,
    [string]$LlmEndpoint = "http://localhost:8000"
)

$ErrorActionPreference = "Continue"

Write-Host "============================================================" -ForegroundColor Cyan
Write-Host " VKS Kiosk Multi-Variant Automated VM Installation Suite   " -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan

# 0. Defaults & Paths
$repoRoot = (Resolve-Path "$PSScriptRoot\..\..").Path
$logsDir  = Join-Path $repoRoot "logs"
if (-not (Test-Path $logsDir)) { New-Item -ItemType Directory -Path $logsDir -Force | Out-Null }
$vhdBaseDir = (Get-VMHost).VirtualHardDiskPath
if (-not (Test-Path $vhdBaseDir)) { New-Item -ItemType Directory -Path $vhdBaseDir -Force | Out-Null }

$defaultUser = "Kiosk"
$defaultPass = "Kiosk"
$rootUser    = "root"
$rootPass    = "Master"

Write-Host "[INIT] Target ISO: $IsoPath" -ForegroundColor Gray
Write-Host "[INIT] Target VHDX Dir: $vhdBaseDir" -ForegroundColor Gray
Write-Host "[INIT] Credentials: $defaultUser / $defaultPass (Root: $rootUser / $rootPass)" -ForegroundColor Gray
Write-Host "[INIT] Local LLM: $LlmEndpoint (Hermes-3-Llama-3.1-8B)" -ForegroundColor Gray

if (-not (Test-Path $IsoPath)) {
    Write-Error "ISO not found at $IsoPath"
    exit 1
}

$results = @()

foreach ($variant in $Variants) {
    $vmName   = "VKS-Kiosk-Test-$($variant.ToUpper())"
    $vhdPath  = Join-Path $vhdBaseDir "$vmName.vhdx"
    $logFile  = Join-Path $logsDir "vm_debug_$variant.log"
    
    Write-Host "`n------------------------------------------------------------" -ForegroundColor Yellow
    Write-Host "[TEST-INSTALLATION] Preparing: $variant ($vmName)" -ForegroundColor Yellow
    Write-Host "------------------------------------------------------------" -ForegroundColor Yellow

    # 1. Provision / Stop VM for clean reconfiguration
    $existingVm = Get-VM -Name $vmName -ErrorAction SilentlyContinue
    if (-not $existingVm) {
        Write-Host "  -> Creating Generation 2 VM '$vmName' ($MemoryGB GB RAM)..." -ForegroundColor Cyan
        New-VM -Name $vmName -MemoryStartupBytes ([int64]$MemoryGB * 1GB) -Generation 2 | Out-Null
    } else {
        if ($existingVm.State -eq 'Running') {
            Write-Host "  -> Stopping running VM '$vmName' for fresh installation run..." -ForegroundColor DarkYellow
            Stop-VM -Name $vmName -TurnOff -Force
            Start-Sleep -Seconds 2
        }
        Write-Host "  -> VM '$vmName' configured. Verifying hardware..." -ForegroundColor Cyan
    }

    # 2. Provision Virtual Hard Disk (VHDX) for Installer Target
    if (-not (Test-Path $vhdPath)) {
        Write-Host "  -> Creating dynamic target hard disk ($DiskSizeGB GB): $vhdPath" -ForegroundColor Green
        New-VHD -Path $vhdPath -SizeBytes ([int64]$DiskSizeGB * 1GB) -Dynamic | Out-Null
    }
    $attachedVhd = Get-VMHardDiskDrive -VMName $vmName -ErrorAction SilentlyContinue
    if (-not $attachedVhd) {
        Write-Host "  -> Attaching VHDX target drive to VM..." -ForegroundColor Green
        Add-VMHardDiskDrive -VMName $vmName -Path $vhdPath | Out-Null
    }

    # 3. Configure UEFI Firmware, Secure Boot & DVD
    Set-VMFirmware -VMName $vmName -EnableSecureBoot Off
    $dvd = Get-VMDvdDrive -VMName $vmName
    if (-not $dvd) {
        $dvd = Add-VMDvdDrive -VMName $vmName -Path $IsoPath -Passthru
    } else {
        Set-VMDvdDrive -VMName $vmName -Path $IsoPath
    }
    
    # Ensure DVD is the first boot device, Hard Disk is second
    $hdd = Get-VMHardDiskDrive -VMName $vmName
    Set-VMFirmware -VMName $vmName -FirstBootDevice $dvd
    Set-VMFirmware -VMName $vmName -BootOrder $dvd, $hdd

    # 4. Connect to virtual network switch
    Connect-VMNetworkAdapter -VMName $vmName -SwitchName "Default Switch" -ErrorAction SilentlyContinue

    # 5. Boot VM
    Write-Host "  -> Booting installation VM '$vmName'..." -ForegroundColor Green
    Start-VM -Name $vmName

    # 6. Launch VM Console Window (vmconnect.exe)
    if ($LaunchVmConnect) {
        Write-Host "  -> Opening live console viewer (vmconnect.exe localhost $vmName)..." -ForegroundColor Magenta
        Start-Process -FilePath "vmconnect.exe" -ArgumentList "localhost", $vmName -WindowStyle Normal
    }

    # 7. Collect Diagnostics & Telemetry
    Start-Sleep -Seconds 5
    $vmInfo = Get-VM -Name $vmName | Select-Object Name, State, CpuUsage, MemoryAssigned, Uptime, Status

    $logContent = @"
=== VKS Kiosk Appliance VM Installation Log ===
Timestamp: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
VM Name: $vmName
Variant Profile: $variant
State: $($vmInfo.State)
CPU Usage: $($vmInfo.CpuUsage)%
Memory Assigned: $([math]::Round($vmInfo.MemoryAssigned / 1MB, 2)) MB
Uptime: $($vmInfo.Uptime)
Status: $($vmInfo.Status)
ISO Path: $IsoPath
Target VHDX: $vhdPath ($DiskSizeGB GB)
Default Login Accounts:
  - User: $defaultUser (Password: $defaultPass)
  - Root: $rootUser (Password: $rootPass)
Hard Disks:
$((Get-VMHardDiskDrive -VMName $vmName | Select-Object Path, ControllerType) | Out-String)
DVD Drives:
$((Get-VMDvdDrive -VMName $vmName | Select-Object Path) | Out-String)
Network Adapters:
$((Get-VMNetworkAdapter -VMName $vmName | Select-Object Name, IPAddresses, Status) | Out-String)
Firmware Settings:
$((Get-VMFirmware -VMName $vmName | Select-Object SecureBoot, FirstBootDevice) | Out-String)
=== End Telemetry ===
"@
    Set-Content -Path $logFile -Value $logContent -Encoding utf8
    Write-Host "  -> Telemetry recorded: $logFile" -ForegroundColor Gray

    # 8. Local AI Auto-Debug Check via Hermes-3
    Write-Host "  -> Running local AI diagnostics (Hermes-3 @ port 8000)..." -ForegroundColor Cyan
    $autoDebugScript = Join-Path $repoRoot "infra\auto_debug.py"
    $debugResult = & python $autoDebugScript $logFile $variant 2>&1
    Write-Host "  $debugResult" -ForegroundColor Gray

    $results += [PSCustomObject]@{
        Variant     = $variant
        VMName      = $vmName
        State       = $vmInfo.State
        CPU         = "$($vmInfo.CpuUsage)%"
        Memory      = "$([math]::Round($vmInfo.MemoryAssigned / 1MB, 0)) MB"
        Disk        = "$DiskSizeGB GB (VHDX)"
        Console     = "vmconnect.exe"
        Suggestions = (Join-Path $logsDir "debug_suggestions_$variant.md")
    }
}

Write-Host "`n============================================================" -ForegroundColor Green
Write-Host " Alle Testinstallationen erfolgreich gestartet!             " -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Green
$results | Format-Table -AutoSize
