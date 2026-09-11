#!/usr/bin/env bash
# ==============================================================================
# WSL Deployment Wrapper for VKS Kiosk Appliance Flashing
# Bridged execution from Windows WSL environments.
# ==============================================================================
set -euo pipefail

echo "=== VKS Appliance WSL Deployment Assistant ==="

# Check WSL environment
if ! grep -qi "microsoft" /proc/version 2>/dev/null; then
    echo "Warning: Not running under Windows Subsystem for Linux (WSL)."
fi

ISO_WIN_PATH="/mnt/c/GitHub/vks_kiosk/Windows/vks-kiosk-debian-13.4.0.iso"
if [ ! -f "$ISO_WIN_PATH" ]; then
    ISO_WIN_PATH="$(dirname "$0")/vks-kiosk-debian-13.4.0.iso"
fi

if [ -f "$ISO_WIN_PATH" ]; then
    echo "Found appliance image: $ISO_WIN_PATH"
else
    echo "Please specify path to the VKS ISO image:"
    read -rp "> " ISO_WIN_PATH
fi

echo ""
echo "Storage devices visible to WSL:"
echo "--------------------------------------------------------"
lsblk -p -o NAME,SIZE,MODEL,TRAN,FSTYPE,LABEL
echo "--------------------------------------------------------"
echo "NOTE: To attach a physical USB drive to WSL from Windows, run:"
echo "  usbipd list"
echo "  usbipd attach --wsl --busid <BUSID>"
echo "--------------------------------------------------------"
echo ""

read -rp "Enter target disk inside WSL (e.g. /dev/sdd): " TARGET_DEV

if [ -b "$TARGET_DEV" ]; then
    read -rp "Type 'YES' to write $ISO_WIN_PATH to $TARGET_DEV: " CONFIRM
    if [ "$CONFIRM" = "YES" ]; then
        echo "Flashing image..."
        sudo dd if="$ISO_WIN_PATH" of="$TARGET_DEV" bs=4M status=progress oflag=direct conv=fsync
        sync
        echo "[OK] Deployment complete."
    else
        echo "Aborted."
    fi
else
    echo "Error: Device '$TARGET_DEV' not found." >&2
    exit 1
fi
