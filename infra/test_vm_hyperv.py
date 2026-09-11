# [AI-EDIT] Agent: Antigravity | Model: Claude Sonnet 4.6 | Date: 2026-09-11 11:47 | Reason: Add variant support, credential defaults, full logging, local-model auto-debug
# Pyinfra Playbook for Automated VM Testing on HyperVHost2023
# Tests both kiosk variants: vks and transfer
# Defaults: VM_KIOSK_USER=Kiosk / VM_KIOSK_PASSWORD=Kiosk / VM_ROOT_USER=root / VM_ROOT_PASSWORD=Master
#
# Usage:
#   pyinfra -y infra/inventory.py infra/test_vm_hyperv.py --data kiosk_target=vks
#   pyinfra -y infra/inventory.py infra/test_vm_hyperv.py --data kiosk_target=transfer
import os
import pathlib
from pyinfra.operations import server

# ---------------------------------------------------------------------------
# Read defaults from .env (fallback values baked in)
# ---------------------------------------------------------------------------
_ENV = {}
_ENV_PATH = pathlib.Path(__file__).parent.parent / ".env"
if _ENV_PATH.exists():
    for _line in _ENV_PATH.read_text(encoding="utf-8").splitlines():
        _line = _line.strip()
        if not _line or _line.startswith("#") or "=" not in _line:
            continue
        _k, _, _v = _line.partition("=")
        _ENV[_k.strip()] = _v.strip().strip('"').strip("'")

def _e(key, default):
    return os.environ.get(key, _ENV.get(key, default))

# ---------------------------------------------------------------------------
# Config with baked-in defaults
# ---------------------------------------------------------------------------
# kiosk_target injected via --data; falls back to "vks"
try:
    KIOSK_TARGET = host.data.get("kiosk_target", "vks")  # noqa: F821
except Exception:
    KIOSK_TARGET = _e("KIOSK_TARGET", "vks")

KIOSK_USER      = _e("VM_KIOSK_USER",     "Kiosk")
KIOSK_PASSWORD  = _e("VM_KIOSK_PASSWORD", "Kiosk")
ROOT_USER       = _e("VM_ROOT_USER",      "root")
ROOT_PASSWORD   = _e("VM_ROOT_PASSWORD",  "Master")

LLM_ENDPOINT    = _e("LLM_ENDPOINT", "http://localhost:8080")
LLM_MODEL       = _e("LLM_MODEL",    "qwen2.5-coder-7b-instruct-q4_k_m.gguf")

# ISO selection per variant
ISO_MAP = {
    "vks":      "C:\\GitHub\\vks_kiosk\\Windows\\vks-kiosk-debian-13.4.0.iso",
    "transfer": "C:\\GitHub\\vks_kiosk\\Windows\\transfer-kiosk-debian-13.4.0.iso",
}
ISO_PATH = ISO_MAP.get(KIOSK_TARGET, ISO_MAP["vks"])

VM_NAME  = f"VKS-Kiosk-Test-{KIOSK_TARGET.upper()}"
LOG_PATH = f"C:\\GitHub\\vks_kiosk\\logs\\vm_debug_{KIOSK_TARGET}.log"

# ---------------------------------------------------------------------------
# Helper: PowerShell with full logging
# ---------------------------------------------------------------------------
def _ps(cmd: str) -> str:
    """Wrap a PowerShell command so stdout+stderr are tee'd to the log file."""
    escaped = cmd.replace('"', '\\"')
    return (
        f'powershell -Command "'
        f'try {{ {escaped} }} catch {{ Write-Output $_.Exception.Message }}'
        f' 2>&1 | Tee-Object -FilePath \'{LOG_PATH}\' -Append"'
    )

# ---------------------------------------------------------------------------
# Step 0 – Prepare log directory
# ---------------------------------------------------------------------------
server.shell(
    name=f"[{KIOSK_TARGET}] Prepare log directory",
    commands=[
        _ps(f"New-Item -ItemType Directory -Force -Path 'C:\\GitHub\\vks_kiosk\\logs' | Out-Null"),
        _ps(f"Set-Content -Path '{LOG_PATH}' -Value '=== VM Test: {VM_NAME} | Target: {KIOSK_TARGET} | $(Get-Date) ==='"),
    ],
)

# ---------------------------------------------------------------------------
# Step 1 – Provision / reconfigure the test VM
# ---------------------------------------------------------------------------
server.shell(
    name=f"[{KIOSK_TARGET}] Provision Hyper-V test VM",
    commands=[
        _ps(f"if (-not (Get-VM -Name '{VM_NAME}' -ErrorAction SilentlyContinue)) {{ New-VM -Name '{VM_NAME}' -MemoryStartupBytes 2GB -Generation 2; Write-Output 'VM created: {VM_NAME}' }} else {{ Write-Output 'VM already exists: {VM_NAME}' }}"),
        _ps(f"Set-VMFirmware -VMName '{VM_NAME}' -EnableSecureBoot Off"),
        _ps(f"if (-not (Get-VMDvdDrive -VMName '{VM_NAME}' -ErrorAction SilentlyContinue)) {{ Add-VMDvdDrive -VMName '{VM_NAME}' -Path '{ISO_PATH}' }} else {{ Set-VMDvdDrive -VMName '{VM_NAME}' -Path '{ISO_PATH}' }}"),
        _ps(f"$dvd = Get-VMDvdDrive -VMName '{VM_NAME}'; Set-VMFirmware -VMName '{VM_NAME}' -FirstBootDevice $dvd"),
        _ps(f"Connect-VMNetworkAdapter -VMName '{VM_NAME}' -SwitchName 'Default Switch' -ErrorAction SilentlyContinue"),
    ],
)

# ---------------------------------------------------------------------------
# Step 2 – Boot the VM
# ---------------------------------------------------------------------------
server.shell(
    name=f"[{KIOSK_TARGET}] Start VM",
    commands=[
        _ps(f"if ((Get-VM -Name '{VM_NAME}').State -ne 'Running') {{ Start-VM -Name '{VM_NAME}'; Write-Output 'VM started' }} else {{ Write-Output 'VM already running' }}"),
        _ps(f"Start-Sleep -Seconds 10"),
    ],
)

# ---------------------------------------------------------------------------
# Step 3 – Verify VM runtime state
# ---------------------------------------------------------------------------
server.shell(
    name=f"[{KIOSK_TARGET}] Verify VM state",
    commands=[
        _ps(f"Get-VM -Name '{VM_NAME}' | Select-Object Name, State, CpuUsage, MemoryAssigned, Uptime | Format-List"),
    ],
)

# ---------------------------------------------------------------------------
# Step 4 – Auto-debug using local Qwen 2.5 Coder model
# ---------------------------------------------------------------------------
server.shell(
    name=f"[{KIOSK_TARGET}] Run local-model auto-debug (Qwen 2.5 Coder @ llama.cpp)",
    commands=[
        f"python C:\\GitHub\\vks_kiosk\\infra\\auto_debug.py \"{LOG_PATH}\" \"{KIOSK_TARGET}\"",
    ],
)

