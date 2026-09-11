# Pyinfra Declarative In-Place Deployment Playbook for VKS-Kiosk & Data Transfer Station
# Targets an existing Debian host (e.g. host mx) and configures it in-place.
from pyinfra.operations import apt, files, server, systemd

# 1. Ensure user vksuser exists
server.user(
    name="Ensure vksuser system account exists",
    user="vksuser",
    ensure_home=True,
    shell="/bin/bash",
)

# 2. Ensure required APT dependencies are present
apt.packages(
    name="Install Kiosk & Data Transfer Station dependencies",
    packages=[
        "xfce4",
        "net-tools",
        "xdotool",
        "lldpd",
        "snmpd",
        "curl",
        "gnupg",
        "ca-certificates",
        "nftables",
        "isc-dhcp-client",
        "rsync",
        "python3",
        "python3-tk",
        "sudo",
        "whiptail",
        "clamav",
        "clamav-daemon",
        "udisks2",
    ],
    update=True,
)

# 3. Add Vivaldi APT Repository & Install Browser
server.shell(
    name="Setup Vivaldi Repository Key & Source",
    commands=[
        "curl -fsSL https://repo.vivaldi.com/archive/linux_signing_key.pub | gpg --dearmor -o /usr/share/keyrings/vivaldi.gpg --yes",
        "echo 'deb [signed-by=/usr/share/keyrings/vivaldi.gpg] https://repo.vivaldi.com/stable/deb/ stable main' > /etc/apt/sources.list.d/vivaldi.list",
    ],
)

apt.packages(
    name="Install Vivaldi Stable Browser",
    packages=["vivaldi-stable"],
    update=True,
)

# 4. Deploy Appliance Configuration (/etc/vks_kiosk.conf)
files.file(
    name="Deploy /etc/vks_kiosk.conf",
    path="/etc/vks_kiosk.conf",
    content="""# VKS Kiosk / Data Transfer Station Configuration
KIOSK_TARGET="transfer"
KIOSK_URL="https://join.hipos-vks.polizei.nrw"
MATRIX_URL="https://app.element.io"
""",
    mode="644",
)

# 5. Deploy Data Transfer Station Helper Script
files.put(
    name="Deploy /usr/local/bin/data_transfer_station.sh",
    src="Linux/data_transfer_station.sh",
    dest="/usr/local/bin/data_transfer_station.sh",
    mode="755",
)

# 6. Deploy System & Desktop Launchers
files.file(
    name="Create Desktop Shortcut for Data Transfer Station",
    path="/home/vksuser/Desktop/transfer.desktop",
    content="""[Desktop Entry]
Version=1.0
Type=Application
Name=Datenübertragungsstation
Comment=Sicherer USB-Medien-Scan und Datenübertragung
Exec=sudo /usr/local/bin/data_transfer_station.sh
Icon=system-file-manager
Terminal=true
Categories=System;
""",
    mode="755",
    user="vksuser",
)

# 7. Enable & Start Services
systemd.service(
    name="Enable ClamAV Daemon Service",
    service="clamav-daemon",
    running=True,
    enabled=True,
)

# 8. XFCE Kiosk UI Hardening
server.shell(
    name="Apply XFCE Kiosk Hardening for vksuser",
    commands=[
        "su - vksuser -c 'mkdir -p ~/.config/xfce4/xfconf/xfceperchannel-xml/' || true",
        "su - vksuser -c 'xfconf-query -c xfce4-desktop -p /desktop-icons/style -s 0' || true",
    ],
)
