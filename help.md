# VKS-Kiosk Appliance & Data Transfer Station — Help & Operations Guide

## Overview

The `vks_kiosk` repository delivers a self-contained Debian / Raspberry Pi OS kiosk appliance, supporting both **VKS Video Conference Mode** and **Data Transfer Station Mode** (secure USB scanning and transfer).

---

## Configuration File Specifications (`/etc/vks_kiosk.conf`)

| Parameter | Type | Default Value | Description |
| :--- | :--- | :--- | :--- |
| `KIOSK_TARGET` | string | `vks` | Operating mode: `vks` (Video Kiosk), `transfer` (Data Station), or `selection` (Whiptail dialog). |
| `KIOSK_URL` | string | `https://vks.bayern.de` | Target web conference URL launched in Vivaldi/Chromium kiosk mode. |
| `AUTO_SCAN_USB` | boolean | `true` | Enables automatic ClamAV malware scanning upon USB drive insertion. |

---

## Justfile Command Reference

```bash
# Display available automation recipes
just

# Run unit tests across all OS submodules
just test-unit

# Run shell and python syntax validation
just lint

# Build the Debian Live ISO with Calamares graphical installer
just build-iso

# Trigger Hyper-V automated test VM
just test-vm host="HyperVHost2023.lafp.schul.polizei.local" target="vks"
```

---

## Troubleshooting & Diagnostics

- **Vivaldi / Chromium blank screen**:
  Ensure GPU acceleration flags are enabled and verify display server state via `xset q`.
- **ClamAV daemon failure**:
  Update virus signatures via `freshclam` and check `/var/log/clamav/clamav.log`.
- **USB mount permissions**:
  Verify user is member of `plugdev` group: `usermod -aG plugdev vksuser`.
