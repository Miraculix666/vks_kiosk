# Pyinfra Inventory for vks_kiosk Deployment & VM Testing
# Maps target hosts: hypervhost2023 (Hyper-V host for VM testing) and mx (Data Transfer host)

hypervhost = [
    ("HyperVHost2023.lafp.schul.polizei.local", {
        "ip": "192.168.250.15",
        "ssh_user": "root",
        "role": "hyperv_test_host",
    })
]

mx_target = [
    ("mx", {
        "ssh_hostname": "192.168.250.100",
        "ssh_user": "root",
        "role": "data_transfer_kiosk",
        "kiosk_target": "transfer",
    })
]

# Combined inventory groups
my_hosts = hypervhost + mx_target
