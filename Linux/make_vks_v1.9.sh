#!/usr/bin/env bash
# ==============================================================================
# Unified VKS-Kiosk & Data Transfer Appliance - Setup & Hardening Script v1.9
# Supported OS: Debian 12 (Bookworm) / Ubuntu 24.04 LTS (x86_64 & ARM64)
# ==============================================================================
set -euo pipefail

CONFIG_FILE="/etc/vks_kiosk.conf"
KIOSK_USER="vksuser"

echo "=== Installing Unified VKS-Kiosk & Data Transfer Appliance v1.9 ==="

# 1. Update and install packages
apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    xfce4 \
    xfce4-terminal \
    lightdm \
    x11-xserver-utils \
    whiptail \
    clamav \
    clamav-daemon \
    udisks2 \
    rsync \
    curl \
    ca-certificates \
    pulseaudio \
    pavucontrol

# 2. Create kiosk user if missing
if ! id "$KIOSK_USER" &>/dev/null; then
    useradd -m -s /bin/bash "$KIOSK_USER"
    echo "$KIOSK_USER:vkskiosk" | chpasswd
    usermod -aG audio,video,plugdev,cdrom "$KIOSK_USER"
fi

# 3. Default Appliance Configuration File
if [ ! -f "$CONFIG_FILE" ]; then
    cat << 'EOF_CONF' > "$CONFIG_FILE"
# ==============================================================================
# Unified VKS Appliance Runtime Configuration
# ==============================================================================
# Operational Modes:
#   "vks"      - Fullscreen Video Conferencing Kiosk (Vivaldi/Chromium)
#   "transfer" - Secure Sandboxed USB Data Transfer Station (TUI / ClamAV)
#   "matrix"   - Dual Mode with Desktop Menu Selector
KIOSK_TARGET="vks"
KIOSK_URL="https://vks.bayern.de"
AUTO_SCAN_USB="true"
XFCE_HARDEN="true"
EOF_CONF
fi

# 4. Copy Data Transfer Station helper
if [ -f "data_transfer_station.sh" ]; then
    cp data_transfer_station.sh /usr/local/bin/data_transfer_station.sh
    chmod +x /usr/local/bin/data_transfer_station.sh
fi

# 5. Configure Kiosk Startup Script
AUTOSTART_DIR="/home/$KIOSK_USER/.config/autostart"
mkdir -p "$AUTOSTART_DIR"

cat << 'EOF_START' > "/home/$KIOSK_USER/start.sh"
#!/usr/bin/env bash
# Runtime Launcher for VKS Kiosk & Data Transfer Station
set -euo pipefail

[ -f /etc/vks_kiosk.conf ] && source /etc/vks_kiosk.conf

# Disable screen blanking and power saving
xset s off 2>/dev/null || true
xset -dpms 2>/dev/null || true
xset s noblank 2>/dev/null || true

# Apply XFCE panel locking & hardening if requested
if [ "${XFCE_HARDEN:-true}" = "true" ] && command -v xfconf-query &>/dev/null; then
    xfconf-query -c xfce4-panel -p /panels/locked -t bool -s true --create 2>/dev/null || true
    xfconf-query -c xfce4-desktop -p /desktop-icons/style -t int -s 0 --create 2>/dev/null || true
fi

case "${KIOSK_TARGET:-vks}" in
    "transfer")
        exec xfce4-terminal --fullscreen -T "Data Transfer Station" -e /usr/local/bin/data_transfer_station.sh
        ;;
    "vks"|*)
        BROWSER_BIN=$(command -v vivaldi || command -v vivaldi-stable || command -v chromium || command -v google-chrome || command -v firefox)
        if [ -n "$BROWSER_BIN" ]; then
            exec "$BROWSER_BIN" \
                --app="${KIOSK_URL:-https://vks.bayern.de}" \
                --kiosk \
                --incognito \
                --use-fake-ui-for-media-stream \
                --autoplay-policy=no-user-gesture-required \
                --check-for-update-interval=31536000 \
                --enable-gpu \
                --ignore-gpu-blocklist \
                --gpu-rasterization \
                --enable-oop-rasterization \
                --no-first-run
        else
            xfce4-terminal --fullscreen -e /usr/local/bin/data_transfer_station.sh
        fi
        ;;
esac
EOF_START

chmod +x "/home/$KIOSK_USER/start.sh"
chown -R "$KIOSK_USER:$KIOSK_USER" "/home/$KIOSK_USER"

# 6. Configure Autostart Entry
cat << EOF_DESK > "$AUTOSTART_DIR/vks-kiosk.desktop"
[Desktop Entry]
Type=Application
Name=VKS Kiosk Launcher
Exec=/home/$KIOSK_USER/start.sh
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
EOF_DESK
chown -R "$KIOSK_USER:$KIOSK_USER" "$AUTOSTART_DIR"

# 7. Configure LightDM Autologin
if [ -d "/etc/lightdm/lightdm.conf.d" ]; then
    cat << EOF_LIGHTDM > "/etc/lightdm/lightdm.conf.d/10-vks-autologin.conf"
[Seat:*]
autologin-user=$KIOSK_USER
autologin-user-timeout=0
user-session=xfce
EOF_LIGHTDM
fi

# 8. Console & TTY Hardening
mkdir -p /etc/X11/xorg.conf.d
cat << 'EOF_XORG' > /etc/X11/xorg.conf.d/10-kiosk-hardening.conf
Section "ServerFlags"
    Option "DontVTSwitch" "true"
EndSection
EOF_XORG

echo "=== VKS Appliance v1.9 Setup & Hardening Complete ==="
