#!/usr/bin/env bash
# ==============================================================================
# Live-Build ISO Creation Script for VKS Appliance & Data Transfer Station
# ==============================================================================
set -euo pipefail

BUILD_DIR="build_live"
mkdir -p "$BUILD_DIR"
cd "$BUILD_DIR"

echo "=== Initializing Debian Live-Build Configuration ==="
lb config     --architectures amd64     --distribution bookworm     --binary-images iso-hybrid     --archive-areas "main contrib non-free non-free-firmware"     --apt-indices false     --memtest none

mkdir -p config/package-lists
cat << 'EOF_PKG' > config/package-lists/vks.list.chroot
xfce4
lightdm
calamares
calamares-settings-debian
whiptail
clamav
clamav-daemon
udisks2
rsync
curl
ca-certificates
EOF_PKG

mkdir -p config/includes.chroot/usr/local/bin
mkdir -p config/includes.chroot/home/vksuser/Desktop

cp ../data_transfer_station.sh config/includes.chroot/usr/local/bin/data_transfer_station.sh 2>/dev/null || true
chmod +x config/includes.chroot/usr/local/bin/data_transfer_station.sh 2>/dev/null || true

cat << 'EOF_DESK' > config/includes.chroot/home/vksuser/Desktop/install.desktop
[Desktop Entry]
Type=Application
Name=Install VKS Appliance
Comment=Launch Calamares Disk Installer
Exec=sudo calamares
Icon=system-software-install
Terminal=false
Categories=System;
EOF_DESK

chmod +x config/includes.chroot/home/vksuser/Desktop/install.desktop 2>/dev/null || true

echo "=== ISO Configuration Ready ==="
