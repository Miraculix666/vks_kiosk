#!/usr/bin/env bash
# ==============================================================================
# VKS Appliance Disk Installer & Target Selector (make_install.sh)
# Deploys VKS-Kiosk / Data Transfer Station ISO to target block devices.
# ==============================================================================
set -euo pipefail

TITLE="VKS Appliance Disk Installer"

echo "=========================================================="
echo "   $TITLE"
echo "=========================================================="
echo ""

# Ensure root privileges
if [ "$(id -u)" -ne 0 ]; then
    echo "Error: This script must be run as root (e.g. sudo $0)." >&2
    exit 1
fi

# Locate ISO image candidate
ISO_CANDIDATE=""
POSSIBLE_ISOS=(
    "$(dirname "$0")/vks-kiosk-debian-13.4.0.iso"
    "$(dirname "$0")/../Windows/vks-kiosk-debian-13.4.0.iso"
    "/mnt/c/GitHub/vks_kiosk/Windows/vks-kiosk-debian-13.4.0.iso"
    "$(dirname "$0")/build_live/live-image-amd64.hybrid.iso"
)

for iso in "${POSSIBLE_ISOS[@]}"; do
    if [ -f "$iso" ]; then
        ISO_CANDIDATE="$iso"
        break
    fi
done

if [ -n "$ISO_CANDIDATE" ]; then
    echo "Found appliance image: $ISO_CANDIDATE"
    read -rp "Use this image? [Y/n]: " USE_DEFAULT
    if [[ "$USE_DEFAULT" =~ ^[Nn]$ ]]; then
        ISO_CANDIDATE=""
    fi
fi

if [ -z "$ISO_CANDIDATE" ]; then
    read -rp "Enter path to ISO image file: " ISO_CANDIDATE
    if [ ! -f "$ISO_CANDIDATE" ]; then
        echo "Error: File '$ISO_CANDIDATE' not found." >&2
        exit 1
    fi
fi

echo ""
echo "Available Storage Disks and Partitions:"
echo "------------------------------------------------------------------------------"
lsblk -p -o NAME,SIZE,MODEL,TRAN,FSTYPE,LABEL,MOUNTPOINT
echo "------------------------------------------------------------------------------"
echo ""

read -rp "Enter target disk device (e.g. /dev/sdb, /dev/sdc - NOT partition like sdb1): " TARGET_DISK

# Sanity checks
if [ ! -b "$TARGET_DISK" ]; then
    echo "Error: Device '$TARGET_DISK' does not exist or is not a valid block device." >&2
    exit 1
fi

# Prevent accidental overwrite of the system root drive
ROOT_DEV=$(findmnt -n -o SOURCE / | sed -r 's/p?[0-9]+$//')
if [ "$TARGET_DISK" = "$ROOT_DEV" ]; then
    echo "CRITICAL WARNING: $TARGET_DISK appears to be the current root drive ($ROOT_DEV)!" >&2
    echo "Operation blocked to prevent catastrophic system destruction." >&2
    exit 1
fi

echo ""
echo "=========================================================="
echo " TARGET DISK : $TARGET_DISK"
echo " SOURCE IMAGE: $ISO_CANDIDATE"
echo "=========================================================="
echo "WARNING: ALL EXISTING DATA ON $TARGET_DISK WILL BE COMPLETELY DESTROYED!"
echo ""
read -rp "Type 'YES' (all uppercase) to confirm and flash image: " CONFIRM

if [ "$CONFIRM" != "YES" ]; then
    echo "Deployment aborted by user."
    exit 0
fi

echo ""
echo "-> Unmounting any active partitions on $TARGET_DISK..."
umount "${TARGET_DISK}"* 2>/dev/null || true

echo "-> Writing image to $TARGET_DISK..."
if command -v pv &>/dev/null; then
    pv -tpreb "$ISO_CANDIDATE" | dd of="$TARGET_DISK" bs=4M oflag=direct conv=fsync
else
    dd if="$ISO_CANDIDATE" of="$TARGET_DISK" bs=4M status=progress oflag=direct conv=fsync
fi

echo "-> Flushing filesystem buffers..."
sync

if command -v partprobe &>/dev/null; then
    partprobe "$TARGET_DISK" 2>/dev/null || true
fi

echo ""
echo "=========================================================="
echo " [OK] Appliance Deployment Successfully Completed!"
echo " Target device $TARGET_DISK is now ready for boot."
echo "=========================================================="
