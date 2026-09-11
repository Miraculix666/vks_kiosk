$isoPath = "C:\GitHub\vks_kiosk\Windows\vks-kiosk-debian-13.4.0.iso"
$vmName = "USB"

Write-Host "Configuring VM $vmName..."
$dvd = Get-VMDvdDrive -VMName $vmName
if ($null -eq $dvd) {
    Write-Host "Adding DVD Drive..."
    Add-VMDvdDrive -VMName $vmName -Path $isoPath
} else {
    Write-Host "Updating DVD Drive Path to $isoPath..."
    Set-VMDvdDrive -VMName $vmName -Path $isoPath
}

# Ensure Secure Boot is off for Linux Netinst/Live ISO
Set-VMFirmware -VMName $vmName -EnableSecureBoot Off

# Ensure First Boot device is DVD Drive
$dvdDrive = Get-VMDvdDrive -VMName $vmName
Set-VMFirmware -VMName $vmName -FirstBootDevice $dvdDrive

# Connect to Default Switch
Connect-VMNetworkAdapter -VMName $vmName -SwitchName "Default Switch" -ErrorAction SilentlyContinue

# Start VM
Write-Host "Starting VM $vmName..."
Start-VM -Name $vmName

Start-Sleep -Seconds 5
Get-VM -Name $vmName | Select-Object Name, State, CpuUsage, MemoryAssigned, Uptime, Status
