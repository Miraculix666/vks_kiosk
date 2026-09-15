# [AI-EDIT] Agent: Antigravity | Model: Claude Sonnet 4.6 | Date: 2026-09-11 11:47 | Reason: Add credential defaults and kiosk_target per host
# Pyinfra Inventory for vks_kiosk Deployment & VM Testing
# Maps target hosts: hypervhost2023 (Hyper-V host for VM testing) and mx (Data Transfer host)
#
# Default credentials (baked in here; override via .env or --data):
#   VM_KIOSK_USER=Kiosk  VM_KIOSK_PASSWORD=Kiosk
#   VM_ROOT_USER=root    VM_ROOT_PASSWORD=Master

hypervhost = [
    ("HyperVHost2023.lafp.schul.polizei.local", {
        "ip":                 "192.168.250.15",
        "ssh_user":           "root",
        "role":               "hyperv_test_host",
        # Kiosk variant to test (can be overridden via --data kiosk_target=transfer)
        "kiosk_target":       "vks",
        # VM login defaults
        "vm_kiosk_user":      "Kiosk",
        "vm_kiosk_password":  "Kiosk",
        "vm_root_user":       "root",
        "vm_root_password":   "Master",
    })
]


mx_target = [
    ("mx", {
        "ssh_hostname":       "192.168.250.24",
        "ssh_user":           "root",
        "role":               "data_transfer_kiosk",
        "kiosk_target":       "transfer",
        "mac_address":        "E4-46-B0-18-93-78",
        # VM / Host login defaults
        "vm_kiosk_user":      "Kiosk",
        "vm_kiosk_password":  "Kiosk",
        "vm_root_user":       "root",
        "vm_root_password":   "Master",
    })
]

# Combined inventory groups
my_hosts = hypervhost + mx_target
