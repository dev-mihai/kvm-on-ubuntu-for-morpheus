#!/bin/bash
SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
source "${SCRIPT_DIR}/config/settings.conf"

check_root() {
    if [ "$(id -u)" != "0" ]; then
        echo "This script must be run as root" 1>&2
        exit 1
    fi
}

echo "KVM Setup Suite"
echo "==============="
echo "This script will run all setup scripts in order."
echo "Current settings:"
echo "  Host IP: $HOST_IP"
echo "  Host MAC: $HOST_MAC"
echo "  VM IP: $VM_IP"
echo "  VM RAM: $VM_RAM MB"
echo "  VM CPUs: $VM_VCPUS"
echo "  VM Size: $VM_SIZE"
echo "  Ubuntu Version: $UBUNTU_RELEASE"
echo ""
echo "Please verify these settings in config/settings.conf before continuing."
echo ""
read -p "Continue? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]
then
    exit 1
fi

chmod +x scripts/*.sh

echo "1. Installing KVM..."
if ! ./scripts/01-install-kvm.sh; then
    echo "KVM installation failed!"
    exit 1
fi

echo "2. Configuring Storage Pools..."
if ! ./scripts/02-configure-pools.sh; then
    echo "Storage pool configuration failed!"
    exit 1
fi

echo "3. Configuring Network..."
if ! ./scripts/03-configure-network.sh; then
    echo "Network configuration failed!"
    exit 1
fi

echo "4. Creating VM..."
if ! ./scripts/04-create-vm.sh; then
    echo "VM creation failed!"
    exit 1
fi

echo "Setup Complete!"
EOF

# Make all scripts executable
chmod +x setup.sh scripts/*.sh

echo "KVM setup scripts have been created in the kvm-setup directory"
echo "Please review and edit config/settings.conf before running the scripts"
echo "To start the setup, run: cd kvm-setup && sudo ./setup.sh"
