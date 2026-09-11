#!/usr/bin/env bash
# ==============================================================================
# VKS-Kiosk & Data Transfer Appliance - Raspberry Pi ARM64 Deployment Script
# Supported OS: Raspberry Pi OS / Debian Bookworm ARM64
# ==============================================================================
set -euo pipefail

CONFIG_FILE="/etc/vks_kiosk.conf"
KIOSK_USER="vksuser"

echo "=== Installing VKS Kiosk Appliance for Raspberry Pi ARM64 ==="

apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    chromium-browser \
    whiptail \
    clamav \
    clamav-daemon \
    udisks2 \
    rsync \
    curl \
    ca-certificates

if ! id "$KIOSK_USER" &>/dev/null; then
    useradd -m -s /bin/bash "$KIOSK_USER"
    echo "$KIOSK_USER:vkskiosk" | chpasswd
    usermod -aG audio,video,plugdev,input "$KIOSK_USER"
fi

if [ ! -f "$CONFIG_FILE" ]; then
    cat << 'EOF_CONF' > "$CONFIG_FILE"
KIOSK_TARGET="vks"
KIOSK_URL="https://vks.bayern.de"
AUTO_SCAN_USB="true"
EOF_CONF
fi

AUTOSTART_DIR="/home/$KIOSK_USER/.config/autostart"
mkdir -p "$AUTOSTART_DIR"

cat << 'EOF_START' > "/home/$KIOSK_USER/start.sh"
#!/usr/bin/env bash
source /etc/vks_kiosk.conf

# Disable DPMS & Screen Blanking
xset s off 2>/dev/null || true
xset -dpms 2>/dev/null || true
xset s noblank 2>/dev/null || true

if [ "${KIOSK_TARGET:-vks}" = "transfer" ]; then
    x-terminal-emulator -e /usr/local/bin/data_transfer_station.sh
else
    exec chromium-browser \
        --app="${KIOSK_URL:-https://vks.bayern.de}" \
        --kiosk \
        --incognito \
        --use-fake-ui-for-media-stream \
        --autoplay-policy=no-user-gesture-required \
        --check-for-update-interval=31536000 \
        --enable-gpu \
        --enable-features=VaapiVideoDecoder,OverlayScrollbar \
        --no-first-run
fi
EOF_START

chmod +x "/home/$KIOSK_USER/start.sh"
chown -R "$KIOSK_USER:$KIOSK_USER" "/home/$KIOSK_USER"

echo "=== Raspberry Pi ARM64 Setup Complete ==="
