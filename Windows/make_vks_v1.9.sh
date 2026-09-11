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
    pavucontrol \
    alsa-utils \
    pulseaudio-utils \
    ffmpeg \
    libnotify-bin

# Optional softphone package if available in repo
DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends baresip 2>/dev/null || true

# 2. Create kiosk user if missing
if ! id "$KIOSK_USER" &>/dev/null; then
    useradd -m -s /bin/bash "$KIOSK_USER"
    echo "$KIOSK_USER:vkskiosk" | chpasswd
    usermod -aG audio,video,plugdev,cdrom "$KIOSK_USER"
fi

# 3. Dynamic Appliance Configuration (Detect variant & plugins from cmdline or preconfig)
DETECTED_TARGET="vks"
DETECTED_VOICE_REC="false"
DETECTED_SIP_PHONE="false"
DETECTED_SIP_SERVER="192.168.250.2"

# A. Evaluate Kernel Commandline (/proc/cmdline)
if grep -q "kiosk_variant=transfer" /proc/cmdline 2>/dev/null || grep -q "kiosk_target=transfer" /proc/cmdline 2>/dev/null; then
    DETECTED_TARGET="transfer"
elif grep -q "kiosk_variant=matrix" /proc/cmdline 2>/dev/null; then
    DETECTED_TARGET="matrix"
elif grep -q "kiosk_variant=vks" /proc/cmdline 2>/dev/null || grep -q "kiosk_target=vks" /proc/cmdline 2>/dev/null; then
    DETECTED_TARGET="vks"
fi

if grep -q "enable_voice_recording=true" /proc/cmdline 2>/dev/null; then
    DETECTED_VOICE_REC="true"
fi
if grep -q "enable_sip_phone=true" /proc/cmdline 2>/dev/null; then
    DETECTED_SIP_PHONE="true"
fi

# B. Evaluate /cdrom/preconfig.conf if present
if [ -f "/cdrom/preconfig.conf" ]; then
    PRE_TARGET=$(grep -E "^KIOSK_TARGET=" /cdrom/preconfig.conf 2>/dev/null | cut -d= -f2 | tr -d '"' | tr -d "'" || true)
    [ -n "$PRE_TARGET" ] && DETECTED_TARGET="$PRE_TARGET"
    PRE_VREC=$(grep -E "^ENABLE_VOICE_RECORDING=" /cdrom/preconfig.conf 2>/dev/null | cut -d= -f2 | tr -d '"' | tr -d "'" || true)
    [ -n "$PRE_VREC" ] && DETECTED_VOICE_REC="$PRE_VREC"
    PRE_SIP=$(grep -E "^ENABLE_SIP_PHONE=" /cdrom/preconfig.conf 2>/dev/null | cut -d= -f2 | tr -d '"' | tr -d "'" || true)
    [ -n "$PRE_SIP" ] && DETECTED_SIP_PHONE="$PRE_SIP"
    PRE_SIP_SRV=$(grep -E "^SIP_SERVER=" /cdrom/preconfig.conf 2>/dev/null | cut -d= -f2 | tr -d '"' | tr -d "'" || true)
    [ -n "$PRE_SIP_SRV" ] && DETECTED_SIP_SERVER="$PRE_SIP_SRV"
fi

if [ ! -f "$CONFIG_FILE" ]; then
    cat << EOF_CONF > "$CONFIG_FILE"
# ==============================================================================
# Unified VKS Appliance Runtime Configuration
# ==============================================================================
KIOSK_TARGET="$DETECTED_TARGET"
KIOSK_URL="https://vks.bayern.de"
AUTO_SCAN_USB="true"
XFCE_HARDEN="true"

# Plugins
ENABLE_VOICE_RECORDING="$DETECTED_VOICE_REC"
VOICE_RECORDING_PATH="/home/$KIOSK_USER/Aufzeichnungen"
ENABLE_SIP_PHONE="$DETECTED_SIP_PHONE"
SIP_SERVER="$DETECTED_SIP_SERVER"
EOF_CONF
fi

# 4. Copy Data Transfer Station helper
if [ -f "data_transfer_station.sh" ]; then
    cp data_transfer_station.sh /usr/local/bin/data_transfer_station.sh
    chmod +x /usr/local/bin/data_transfer_station.sh
fi

# 5. Create Plugin Helper Scripts
# 5.1 Voice Recorder Plugin
cat << 'EOF_VREC' > /usr/local/bin/vks_voice_recorder.sh
#!/usr/bin/env bash
# VKS Voice Recording Helper
OUT_DIR="${VOICE_RECORDING_PATH:-/home/vksuser/Aufzeichnungen}"
mkdir -p "$OUT_DIR"
PID_FILE="/tmp/vks_recording.pid"

case "${1:-toggle}" in
    start)
        if [ -f "$PID_FILE" ] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
            echo "Recording already running."
            exit 0
        fi
        REC_FILE="$OUT_DIR/Session_$(date +%Y%m%d_%H%M%S).wav"
        arecord -f cd -t wav "$REC_FILE" &
        echo $! > "$PID_FILE"
        notify-send -i audio-input-microphone "VKS Sprachaufzeichnung" "Aufnahme gestartet:\n$(basename "$REC_FILE")" 2>/dev/null || true
        ;;
    stop)
        if [ -f "$PID_FILE" ]; then
            kill "$(cat "$PID_FILE")" 2>/dev/null || true
            rm -f "$PID_FILE"
            notify-send -i media-playback-stop "VKS Sprachaufzeichnung" "Aufnahme beendet und gespeichert." 2>/dev/null || true
        fi
        ;;
    toggle)
        if [ -f "$PID_FILE" ] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
            $0 stop
        else
            $0 start
        fi
        ;;
    status)
        if [ -f "$PID_FILE" ] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
            echo "RECORDING (PID $(cat "$PID_FILE"))"
        else
            echo "STOPPED"
        fi
        ;;
esac
EOF_VREC
chmod +x /usr/local/bin/vks_voice_recorder.sh

# 5.2 SIP Phone Launcher
cat << 'EOF_SIPLAUNCH' > /usr/local/bin/vks_sip_phone.sh
#!/usr/bin/env bash
# VKS SIP Phone Softphone Launcher
[ -f /etc/vks_kiosk.conf ] && source /etc/vks_kiosk.conf
echo "Starting VKS SIP Phone client to ${SIP_SERVER:-192.168.250.2}..."
if command -v baresip &>/dev/null; then
    exec baresip
elif command -v linphone &>/dev/null; then
    exec linphone
else
    # Fallback to Cisco DX80 / WebRTC SIP dialer webview
    exec xdg-open "http://${SIP_SERVER:-192.168.250.2}:8080/dialer" 2>/dev/null || true
fi
EOF_SIPLAUNCH
chmod +x /usr/local/bin/vks_sip_phone.sh

# 6. Configure Kiosk Startup Script
AUTOSTART_DIR="/home/$KIOSK_USER/.config/autostart"
mkdir -p "$AUTOSTART_DIR"
DESKTOP_DIR="/home/$KIOSK_USER/Desktop"
mkdir -p "$DESKTOP_DIR"

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

# Plugin Setup: Voice Recording
if [ "${ENABLE_VOICE_RECORDING:-false}" = "true" ]; then
    mkdir -p "${VOICE_RECORDING_PATH:-/home/vksuser/Aufzeichnungen}"
    cat << EOF_REC_DESK > /home/vksuser/Desktop/Sprachaufzeichnung.desktop
[Desktop Entry]
Type=Application
Name=Sprachaufzeichnung (Start/Stop)
Exec=/usr/local/bin/vks_voice_recorder.sh toggle
Icon=audio-input-microphone
Terminal=false
EOF_REC_DESK
    chmod +x /home/vksuser/Desktop/Sprachaufzeichnung.desktop 2>/dev/null || true
fi

# Plugin Setup: SIP Phone
if [ "${ENABLE_SIP_PHONE:-false}" = "true" ]; then
    cat << EOF_SIP_DESK > /home/vksuser/Desktop/SIP-Telefon.desktop
[Desktop Entry]
Type=Application
Name=SIP Telefon (VoIP)
Exec=/usr/local/bin/vks_sip_phone.sh
Icon=call-start
Terminal=true
EOF_SIP_DESK
    chmod +x /home/vksuser/Desktop/SIP-Telefon.desktop 2>/dev/null || true
fi

case "${KIOSK_TARGET:-vks}" in
    "transfer")
        exec xfce4-terminal --fullscreen -T "Data Transfer Station" -e /usr/local/bin/data_transfer_station.sh
        ;;
    "matrix")
        # Dual mode: launch desktop with selection dialog
        CHOICE=$(whiptail --title "VKS Multi-Station" --menu "Waehlen Sie den Betriebsmodus:" 15 60 2 \
            "1" "VKS Video-Kiosk (Konferenz)" \
            "2" "Datentransfer-Station (USB/Scan)" 3>&1 1>&2 2>&3 || echo "1")
        if [ "$CHOICE" = "2" ]; then
            exec xfce4-terminal --fullscreen -T "Data Transfer Station" -e /usr/local/bin/data_transfer_station.sh
        else
            BROWSER_BIN=$(command -v vivaldi || command -v chromium || command -v firefox)
            exec "$BROWSER_BIN" --app="${KIOSK_URL:-https://vks.bayern.de}" --kiosk --no-first-run
        fi
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

# 7. Configure Autostart Entry
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

# 8. Configure LightDM Autologin
if [ -d "/etc/lightdm/lightdm.conf.d" ]; then
    cat << EOF_LIGHTDM > "/etc/lightdm/lightdm.conf.d/10-vks-autologin.conf"
[Seat:*]
autologin-user=$KIOSK_USER
autologin-user-timeout=0
user-session=xfce
EOF_LIGHTDM
fi

# 9. Console & TTY Hardening
mkdir -p /etc/X11/xorg.conf.d
cat << 'EOF_XORG' > /etc/X11/xorg.conf.d/10-kiosk-hardening.conf
Section "ServerFlags"
    Option "DontVTSwitch" "true"
EndSection
EOF_XORG

echo "=== VKS Appliance v1.9 Setup & Hardening Complete ==="
