#!/bin/bash

# Check if running as root
check_root() {
    if [ "$(id -u)" != "0" ]; then
        echo "This script must be run as root" 1>&2
        exit 1
    fi
}

# Function to clone repository
clone_repo() {
    local repo_url="https://github.com/dev-mihai/kvm-on-ubuntu-for-morpheus.git"
    local clone_dir="kvm-on-ubuntu-for-morpheus"
    
    # Check if directory already exists
    if [ -d "$clone_dir" ]; then
        echo "Directory $clone_dir already exists. Removing it..."
        rm -rf "$clone_dir"
    fi
    
    echo "Cloning repository..."
    if ! git clone "$repo_url"; then
        echo "Failed to clone repository!"
        exit 1
    fi
    
    cd "$clone_dir" || exit 1
}

# Main execution
check_root

# Clone the repository and change to its directory
clone_repo

# Source the settings file
source "config/settings.conf"

echo "KVM Setup Suite"
echo "==============="
echo "This script will run all setup scripts in order."
echo "Current settings:"
echo " Host IP: $HOST_IP"
echo " NETWORK CIDR: $NETWORK_CIDR"
echo " Host MAC: $HOST_MAC"
echo " VM IP: $VM_IP"
echo " VM RAM: $VM_RAM MB"
echo " VM CPUs: $VM_VCPUS"
echo " VM Size: $VM_SIZE"
echo " VM Username: $VM_USERNAME"
echo " VM Password (hashed): $VM_PASSWORD"
echo " Ubuntu Version: $UBUNTU_RELEASE"
echo ""
echo "Please verify these settings in config/settings.conf before continuing."
echo ""
read -p "Continue? (y/n) " -n 1 -r
echo

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    exit 1
fi

# Make all scripts executable
chmod +x scripts/*.sh

echo "1. Installing KVM..."
if ! ./scripts/01-install-kvm.sh; then
    echo "KVM installation failed!"
    exit 1
fi

echo "2. Configuring the Environment..."
if ! ./scripts/02-other-config-changes.sh; then
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
