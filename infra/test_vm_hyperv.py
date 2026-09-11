# Pyinfra Playbook for Automated VM Testing on HyperVHost2023
from pyinfra.operations import server, files

VM_NAME = "VKS-Kiosk-Test-VM"
ISO_PATH = "C:\\vks_kiosk_test\\vks_kiosk-true-live.iso"

# 1. Provision Test VM on Hyper-V Host using PowerShell
server.shell(
    name="Provision Hyper-V Test VM on HyperVHost2023",
    commands=[
        f"powershell -Command \"if (-not (Get-VM -Name '{VM_NAME}' -ErrorAction SilentlyContinue)) {{ New-VM -Name '{VM_NAME}' -MemoryStartupBytes 2GB -Generation 2 }}\"",
        f"powershell -Command \"Set-VMDvdDrive -VMName '{VM_NAME}' -Path '{ISO_PATH}' -ErrorAction SilentlyContinue\"",
        f"powershell -Command \"Start-VM -Name '{VM_NAME}' -ErrorAction SilentlyContinue\"",
    ],
)

# 2. Verify VM Status
server.shell(
    name="Verify Hyper-V Test VM Runtime State",
    commands=[
        f"powershell -Command \"Get-VM -Name '{VM_NAME}' | Select-Object Name, State, CpuUsage, MemoryAssigned\"",
    ],
)
