#!/usr/bin/env bash
# ==============================================================================
# Live-Build ISO Creation Script for Unified VKS & Data Transfer Appliance
# ==============================================================================
set -euo pipefail

BUILD_DIR="build_live"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "=== Initializing Debian Live-Build Configuration ==="
mkdir -p "$BUILD_DIR"
cd "$BUILD_DIR"

# Configure Debian Live Image
lb config \
    --architectures amd64 \
    --distribution bookworm \
    --binary-images iso-hybrid \
    --archive-areas "main contrib non-free non-free-firmware" \
    --apt-indices false \
    --memtest none \
    --bootappend-live "boot=live components quiet splash splash-theme=vks"

# Package lists
mkdir -p config/package-lists
cat << 'EOF_PKG' > config/package-lists/vks.list.chroot
xfce4
xfce4-terminal
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
pulseaudio
pavucontrol
firefox-esr
plymouth
plymouth-themes
EOF_PKG

# Include custom scripts & files in chroot
mkdir -p config/includes.chroot/usr/local/bin
mkdir -p config/includes.chroot/home/vksuser/Desktop
mkdir -p config/includes.chroot/etc
mkdir -p config/includes.chroot/usr/share/backgrounds/vks
mkdir -p config/includes.binary/boot/grub/themes/vks-modern
mkdir -p config/includes.binary/isolinux

if [ -f "$SCRIPT_DIR/data_transfer_station.sh" ]; then
    cp "$SCRIPT_DIR/data_transfer_station.sh" config/includes.chroot/usr/local/bin/data_transfer_station.sh
    chmod +x config/includes.chroot/usr/local/bin/data_transfer_station.sh
fi

# Copy GRUB Theme & Wallpaper Assets
if [ -d "$SCRIPT_DIR/theme" ]; then
    cp -r "$SCRIPT_DIR/theme/"* config/includes.binary/boot/grub/themes/vks-modern/ 2>/dev/null || true
    cp "$SCRIPT_DIR/theme/background.png" config/includes.chroot/usr/share/backgrounds/vks/vks-wallpaper.png 2>/dev/null || true
    cp "$SCRIPT_DIR/theme/splash.png" config/includes.binary/isolinux/splash.png 2>/dev/null || true
fi

# Copy grub.cfg and preseed.cfg to binary includes
mkdir -p config/includes.binary/boot/grub
if [ -f "$SCRIPT_DIR/grub.cfg" ]; then
    cp "$SCRIPT_DIR/grub.cfg" config/includes.binary/boot/grub/grub.cfg
fi
if [ -f "$SCRIPT_DIR/preseed.cfg" ]; then
    cp "$SCRIPT_DIR/preseed.cfg" config/includes.binary/preseed.cfg
fi

# Default config in chroot
cat << 'EOF_CONF' > config/includes.chroot/etc/vks_kiosk.conf
KIOSK_TARGET="vks"
KIOSK_URL="https://vks.bayern.de"
AUTO_SCAN_USB="true"
XFCE_HARDEN="true"
EOF_CONF

# Desktop Calamares Installer shortcut
cat << 'EOF_DESK' > config/includes.chroot/home/vksuser/Desktop/install.desktop
[Desktop Entry]
Type=Application
Name=VKS Appliance Installer (Calamares)
Comment=Grafische Installation auf SSD / eMMC starten
Exec=sudo calamares
Icon=system-software-install
Terminal=false
Categories=System;
EOF_DESK

chmod +x config/includes.chroot/home/vksuser/Desktop/install.desktop

echo "=== Live-Build ISO Framework Ready ==="
echo "To build the production ISO, run: sudo lb build"
