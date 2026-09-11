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

# Run fully automated VM testing on HyperVHost2023
test-vm host="HyperVHost2023.lafp.schul.polizei.local":
    @echo "Triggering automated Hyper-V VM test on HyperVHost2023 ({{host}})..."
    pyinfra -y infra/inventory.py infra/test_vm_hyperv.py --limit {{host}}

# Rollout Data Transfer Station configuration to target host mx
deploy-mx host="mx":
    @echo "Deploying Data Transfer Station configuration to target host mx ({{host}})..."
    pyinfra -y infra/inventory.py infra/deploy_kiosk.py --limit {{host}}
