# vks_kiosk Changelog

## [2.1.0] - 2026-09-11
### Added
- **Modular GRUB Boot Option (`boot_option.cfg`):** Externalized default boot choice to an easily accessible file on the USB stick root. Can be edited from Windows without modifying complex GRUB syntax.
- **Multi-Variant Boot Menu & Submenus:** Explicit options for VKS Video Kiosk, Data Transfer Station, Debian Live/Rescue, plus an Advanced/Debug Submenu with verbose logging and expert installation.
- **Dynamic Variant Detection:** Appliance installer script `make_vks_v1.9.sh` automatically detects `kiosk_variant` from kernel cmdline or `/cdrom/preconfig.conf`.
- **Preconfig Template (`preconfig.example.conf`):** Template for zero-touch configuration via USB stick file.
- **Local AI Auto-Debugger (Hermes-3-Llama-3.1-8B):** Replaced basic base models with Hermes 3 Q4_K_M on port 8000 for structured log analysis and automated debugging.
- **Automated Multi-Variant VM Test Suite (`scripts/system/test_all_kiosk_variants.ps1`):** End-to-end PowerShell script provisioning Gen2 Hyper-V VMs for all variants, launching `vmconnect.exe` console windows, capturing telemetry, and running local AI diagnostics.
- **Windows Credential Manager Integration:** Secured Hyper-V remoting credentials (`nw0b4746`) in Windows Credential Vault.

## [2.0.0] - 2024
### Added
- **Central `.env` File:** All core variables (`MAX_USB_SIZE_GB`, `DEBIAN_ISO_URL`, etc.) are now centralized in `.env`.
- **`shared_build.sh`:** Extracted the duplicate logic from Linux and Windows builder scripts into a single, unified backend script. This ensures consistency and easier maintenance.
- **Modern Terminal UI:** Integrated `whiptail` (with standard Bash read fallbacks) for visually appealing, fast, and secure user menus, particularly during the critical USB selection phase.
- **Cross-Distribution Support:** Improved dependency resolution logic. Future updates will extend the package manager support beyond `apt` to `dnf` (Fedora) and `zypper` (SUSE).
- **Explicit Boot Menu Options:** Updated `grub.cfg` to explicitly distinguish between "Install vks_kiosk (Automated)" and "Debian Live/Rescue (Manual)".

### Changed
- **Script Refactoring:** Rewrote `Linux/make_install.sh` and `Windows/make_install_wsl.sh` to act as simple wrappers that source `shared_build.sh`. This removes 90% of redundant code.
- **Safety First:** Enhanced device querying (`lsblk`) now explicitly filters out loop/ram devices, shows the device model, validates against `MAX_USB_SIZE_GB`, and strictly requires a `yesno` confirmation before running `dd` or `sfdisk`.
- **WSL Path Handling:** Kept the Windows-specific WSL to `C:\` path translation logic in `make_install_wsl.sh` for user convenience.

### Why these changes were made:
- **Portability:** The user requested that the scripts run on nearly any Linux (Debian, Suse, Fedora, Ubuntu) and Win (WSL). Centralizing logic and providing fallbacks ensures it works universally.
- **Safety & Clarity:** Flashing drives is dangerous. Clear, undeniable UI prompts (`whiptail`) prevent catastrophic data loss (e.g., wiping the internal drive).

