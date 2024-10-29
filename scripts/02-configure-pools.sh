#!/bin/bash
SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
source "${SCRIPT_DIR}/../config/settings.conf"

check_root() {
    if [ "$(id -u)" != "0" ]; then
        echo "This script must be run as root" 1>&2
        exit 1
    fi
}

configure_pools() {
    echo "=== Setting up storage pools ==="
    
    # Create directories if they don't exist
    mkdir -p /guest_images /morph-cloud-init
    chmod 755 /guest_images /morph-cloud-init
    chown root:root /guest_images /morph-cloud-init
    
    # Define morpheus-images pool
    if ! virsh pool-info morpheus-images >/dev/null 2>&1; then
        echo "Creating morpheus-images pool..."
        virsh pool-define-as --name morpheus-images --type dir --target /guest_images
        virsh pool-start --build morpheus-images
        virsh pool-autostart morpheus-images
    else
        echo "morpheus-images pool already exists"
    fi
    
    # Define morpheus-cloud-init pool
    if ! virsh pool-info morpheus-cloud-init >/dev/null 2>&1; then
        echo "Creating morpheus-cloud-init pool..."
        virsh pool-define-as --name morpheus-cloud-init --type dir --target /morph-cloud-init
        virsh pool-start --build morpheus-cloud-init
        virsh pool-autostart morpheus-cloud-init
    else
        echo "morpheus-cloud-init pool already exists"
    fi
    
    # Verify pools
    echo "=== Verifying storage pools ==="
    virsh pool-list --all
}

check_root
configure_pools