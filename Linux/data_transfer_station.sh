#!/usr/bin/env bash
# ==============================================================================
# Data Transfer Station (Datenübertragungsstation) Helper Script
# Part of Unified VKS-Kiosk & Data Transfer Appliance
# ==============================================================================
set -euo pipefail

TITLE="VKS Secure Data Transfer Station"
SCAN_LOG="/var/log/data_transfer_scan.log"
TEMP_MOUNT="/mnt/transfer_source"

mkdir -p "$TEMP_MOUNT" 2>/dev/null || true

check_deps() {
    for cmd in lsblk whiptail clamscan udisksctl; do
        if ! command -v "$cmd" &>/dev/null; then
            echo "Error: Required command '$cmd' is missing." >&2
            exit 1
        fi
    done
}

list_usb_devices() {
    lsblk -p -n -o NAME,SIZE,TRAN,MODEL,FSTYPE,LABEL | grep -i "usb" || true
}

scan_device() {
    local dev="$1"
    whiptail --title "$TITLE" --infobox "Scanning device $dev with ClamAV... Please wait." 8 60
    
    mkdir -p "$TEMP_MOUNT"
    if udisksctl mount -b "$dev" --no-user-interaction &>/dev/null; then
        local mnt
        mnt=$(lsblk -no MOUNTPOINT "$dev" | head -n 1)
        if [ -n "$mnt" ]; then
            if clamscan -r -i "$mnt" > "$SCAN_LOG" 2>&1; then
                whiptail --title "$TITLE" --msgbox "Virus Scan PASSED cleanly!

No threats detected on $dev." 10 60
            else
                whiptail --title "$TITLE" --msgbox "WARNING: Potential threats detected on $dev!

Check log at $SCAN_LOG" 10 60
            fi
        fi
        udisksctl unmount -b "$dev" --no-user-interaction || true
    else
        whiptail --title "$TITLE" --msgbox "Failed to mount device $dev." 8 50
    fi
}

main_menu() {
    check_deps
    while true; do
        CHOICE=$(whiptail --title "$TITLE" --menu "Select an action:" 15 65 4             "1" "List Connected USB Storage Devices"             "2" "Scan USB Device with ClamAV"             "3" "Mount Device Read-Only for Inspection"             "4" "Exit" 3>&1 1>&2 2>&3)

        case "$CHOICE" in
            1)
                DEVS=$(list_usb_devices)
                if [ -z "$DEVS" ]; then
                    DEVS="No USB storage devices detected."
                fi
                whiptail --title "Connected USB Devices" --msgbox "$DEVS" 15 75
                ;;
            2)
                DEV_LIST=$(lsblk -p -n -o NAME,SIZE,MODEL | grep -v "loop" | awk '{print $1 " " $2 "_" $3}')
                if [ -z "$DEV_LIST" ]; then
                    whiptail --title "$TITLE" --msgbox "No storage devices available for scanning." 8 50
                    continue
                fi
                MENU_OPTS=()
                while read -r name desc; do
                    MENU_OPTS+=("$name" "$desc")
                done <<< "$DEV_LIST"
                
                TARGET_DEV=$(whiptail --title "Select Device to Scan" --menu "Choose device:" 15 65 6 "${MENU_OPTS[@]}" 3>&1 1>&2 2>&3 || true)
                if [ -n "$TARGET_DEV" ]; then
                    scan_device "$TARGET_DEV"
                fi
                ;;
            3)
                whiptail --title "$TITLE" --msgbox "Read-only mount helper active at /mnt/transfer_source" 8 60
                ;;
            4|*)
                break
                ;;
        esac
    done
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main_menu
fi
