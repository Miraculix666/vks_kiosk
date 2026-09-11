#!/usr/bin/env bash
# ==============================================================================
# Disk Selection and Deployment Installer Script (make_install.sh)
# ==============================================================================
set -euo pipefail

echo "=== VKS Appliance Disk Installer & Target Selector ==="
echo ""
echo "Available Storage Disks and Partitions:"
echo "--------------------------------------------------------"
lsblk -p -o NAME,SIZE,MODEL,TRAN,FSTYPE,LABEL
echo "--------------------------------------------------------"
echo ""

read -rp "Enter target disk device for installation (e.g. /dev/sda or /dev/nvme0n1): " TARGET_DISK

if [ -b "$TARGET_DISK" ]; then
    echo "Selected target disk: $TARGET_DISK"
    read -rp "Are you sure you want to write to $TARGET_DISK? ALL DATA WILL BE ERASED! (y/N): " CONFIRM
    if [[ "$CONFIRM" =~ ^[Yy]$ ]]; then
        echo "Starting deployment to $TARGET_DISK..."
    else
        echo "Aborted by user."
    fi
else
    echo "Error: Device $TARGET_DISK does not exist or is not a block device." >&2
    exit 1
fi
