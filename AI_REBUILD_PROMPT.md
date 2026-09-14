# AI Reconstruction & Context Prompt — VKS Kiosk & Appliance

> **Role & Task Description for AI Agents:**
> You are tasked with reconstructing or extending the **VKS-Kiosk Appliance & Data Transfer Station** codebase from scratch or migrating it to a new environment.

## 1. System Vision & Purpose
The `vks_kiosk` system is a hardened, public video-conferencing and secure data transfer appliance operating on Linux (Debian 12), Windows, and Raspberry Pi ARM64.

## 2. Core Architecture Rules
- **Multi-OS Parity**: Provide symmetric deployment scripts (`Linux/make_vks_v1.9.sh`, `Windows/make_install_wsl.sh` / `Windows/ichwillaberwindows.ps1`, `Raspi/make_vks.sh`).
- **Orchestration**: All build actions and tests MUST be callable via `Justfile` and `pyinfra` (`infra/deploy_kiosk.py`).
- **Security & Privacy**:
  - Browser launches in `--kiosk --incognito --use-fake-ui-for-media-stream` mode.
  - Automated virus scanning (`clamdscan` / `rsync`) for Data Transfer mode.
  - XFCE panel locking and desktop hardening to prevent unauthorized access.

## 3. Directory Layout
- `Linux/`: Shell scripts, Live ISO generator (`make_live_iso.sh`), preseed & GRUB configs.
- `Windows/`: PowerShell deployment scripts (`ichwillaberwindows.ps1`) and WSL build tools.
- `Raspi/`: Raspberry Pi ARM64 specific setup scripts (`make_vks.sh`).
- `infra/`: `pyinfra` playbooks (`inventory.py`, `deploy_kiosk.py`, `test_vm_hyperv.py`).
- `examples/`: Reference invocation scripts.
- `preconfigs/`: Configuration templates.
