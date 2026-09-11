# VKS-Kiosk & Data Transfer Station Appliance Justfile
# Powered by pyinfra & just

default:
    @just --list

# Run all unit tests across all platform modules
test-unit:
    @echo "Executing unit tests for overlay and kiosk components..."
    python -m unittest discover -s Linux -p "test_*.py"
    python -m unittest discover -s Windows -p "test_*.py"
    python -m unittest discover -s Raspi -p "test_*.py"
    @echo "  -> Unit Tests PASSED"

# Lint all scripts, pyinfra playbooks, and python files
lint: test-unit
    @echo "Running syntax checks on shell scripts and pyinfra playbooks..."
    bash -n Linux/make_live_iso.sh
    bash -n Linux/make_install.sh
    bash -n Linux/make_vks_v1.9.sh
    bash -n Linux/data_transfer_station.sh
    bash -n Windows/make_install_wsl.sh
    python -m py_compile Linux/overlay.py infra/inventory.py infra/deploy_kiosk.py infra/test_vm_hyperv.py
    @echo "  -> Syntax OK"

# Build the VKS-Kiosk & Data Transfer Station Live ISO
build-iso:
    @echo "Building VKS-Kiosk & Data Transfer Station Live ISO..."
    sudo bash Linux/make_live_iso.sh

# Run automated VM test for a specific kiosk variant
# Defaults: kiosk_target=vks | login: Kiosk:Kiosk / root:Master
test-vm host="HyperVHost2023.lafp.schul.polizei.local" target="vks":
    @echo "Triggering Hyper-V VM test on {{host}} — variant: {{target}}"
    pyinfra -y infra/inventory.py infra/test_vm_hyperv.py --limit {{host}} --data kiosk_target={{target}}

# Test the VKS kiosk variant (login: Kiosk:Kiosk, root:Master)
test-vm-vks host="HyperVHost2023.lafp.schul.polizei.local":
    @echo "Testing VKS kiosk variant..."
    pyinfra -y infra/inventory.py infra/test_vm_hyperv.py --limit {{host}} --data kiosk_target=vks
    @echo "  -> VKS VM test complete. See logs/vm_debug_vks.log & logs/debug_suggestions_vks.md"

# Test the Data Transfer Station kiosk variant (login: Kiosk:Kiosk, root:Master)
test-vm-transfer host="HyperVHost2023.lafp.schul.polizei.local":
    @echo "Testing Transfer kiosk variant..."
    pyinfra -y infra/inventory.py infra/test_vm_hyperv.py --limit {{host}} --data kiosk_target=transfer
    @echo "  -> Transfer VM test complete. See logs/vm_debug_transfer.log & logs/debug_suggestions_transfer.md"

# Run ALL kiosk variant tests sequentially
test-vm-all host="HyperVHost2023.lafp.schul.polizei.local":
    @echo "Running ALL kiosk variant tests..."
    just test-vm-vks host={{host}}
    just test-vm-transfer host={{host}}
    @echo "  -> All variant tests complete."

# Rollout Data Transfer Station configuration to target host mx
deploy-mx host="mx":
    @echo "Deploying Data Transfer Station configuration to target host mx ({{host}})..."
    pyinfra -y infra/inventory.py infra/deploy_kiosk.py --limit {{host}}
