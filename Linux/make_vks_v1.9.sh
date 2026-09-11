#!/usr/bin/env bash
# ==============================================================================
# VKS-Kiosk & Data Transfer Appliance - Setup Script v1.9
# Supported OS: Debian 12 (Bookworm) / Ubuntu 24.04 LTS (x86_64 & ARM64)
# ==============================================================================
set -euo pipefail

CONFIG_FILE="/etc/vks_kiosk.conf"
KIOSK_USER="vksuser"

echo "=== Installing Unified VKS-Kiosk & Data Transfer Appliance v1.9 ==="

apt-get update
apt-get install -y --no-install-recommends     xfce4     lightdm     x11-xserver-utils     whiptail     clamscan     clamav-daemon     udisks2     rsync     curl     ca-certificates

if ! id "$KIOSK_USER" &>/dev/null; then
    useradd -m -s /bin/bash "$KIOSK_USER"
    echo "$KIOSK_USER:vkskiosk" | chpasswd
fi

if [ ! -f "$CONFIG_FILE" ]; then
    cat << 'EOF_CONF' > "$CONFIG_FILE"
# Unified VKS Appliance Configuration
KIOSK_MODE="vks"
KIOSK_URL="https://vks.bayern.de"
AUTO_SCAN_USB="true"
XFCE_HARDEN="true"
EOF_CONF
fi

AUTOSTART_DIR="/home/$KIOSK_USER/.config/autostart"
mkdir -p "$AUTOSTART_DIR"
chown -R "$KIOSK_USER:$KIOSK_USER" "/home/$KIOSK_USER/.config"

cat << 'EOF_START' > "/home/$KIOSK_USER/start.sh"
#!/usr/bin/env bash
source /etc/vks_kiosk.conf

if [ "$KIOSK_MODE" = "transfer" ]; then
    x-terminal-emulator -e /usr/local/bin/data_transfer_station.sh
else
    BROWSER_BIN=$(command -v vivaldi || command -v chromium || command -v firefox)
    if [ -n "$BROWSER_BIN" ]; then
        exec "$BROWSER_BIN"             --app="$KIOSK_URL"             --kiosk             --incognito             --use-fake-ui-for-media-stream             --autoplay-policy=no-user-gesture-required             --check-for-update-interval=31536000             --enable-gpu             --no-first-run
    fi
fi
EOF_START

chmod +x "/home/$KIOSK_USER/start.sh"
cp /home/vksuser/data_transfer_station.sh /usr/local/bin/data_transfer_station.sh 2>/dev/null || true
chmod +x /usr/local/bin/data_transfer_station.sh 2>/dev/null || true

echo "=== VKS Appliance v1.9 Setup Complete ==="
