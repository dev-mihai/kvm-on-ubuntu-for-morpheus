#!/bin/bash
SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
source "${SCRIPT_DIR}/../config/settings.conf"

check_root() {
    if [ "$(id -u)" != "0" ]; then
        echo "This script must be run as root" 1>&2
        exit 1
    fi
}

setup_permissions() {
    echo "=== Setting up permissions ==="
    
    # Set up libvirt directories
    mkdir -p $VM_DIR
    chown root:root $VM_DIR
    chmod 755 $VM_DIR

    # Ensure libvirt-qemu user exists
    if ! getent group libvirt-qemu >/dev/null; then
        groupadd -r libvirt-qemu
    fi
    if ! getent passwd libvirt-qemu >/dev/null; then
        useradd -r -g libvirt-qemu libvirt-qemu
    fi
}

configure_libvirt() {
    echo "=== Configuring libvirt ==="
    
    # Backup original config
    cp /etc/libvirt/qemu.conf /etc/libvirt/qemu.conf.backup.$(date +%Y%m%d_%H%M%S)
    
    # Uncomment and set user/group to root
    sed -i 's/^#user = "root"/user = "root"/' /etc/libvirt/qemu.conf
    sed -i 's/^#group = "root"/group = "root"/' /etc/libvirt/qemu.conf
    sed -i 's/^#.*security_driver.*=.*\[.*\]/security_driver = [ "none" ]/' "/etc/libvirt/qemu.conf"
    
    # Verify changes
    if ! grep -q '^user = "root"' /etc/libvirt/qemu.conf || ! grep -q '^group = "root"' /etc/libvirt/qemu.conf; then
        echo "ERROR: Failed to configure libvirt"
        exit 1
    fi
    
    # Restart libvirtd
    systemctl restart libvirtd
    if [ $? -ne 0 ]; then
        echo "ERROR: Failed to restart libvirtd"
        exit 1
    fi
}

install_kvm() {
    echo "=== Checking virtualization support ==="
    if [ $(egrep -c '(vmx|svm)' /proc/cpuinfo) -eq 0 ]; then
        echo "ERROR: CPU virtualization not supported or not enabled in BIOS"
        exit 1
    fi

    echo "=== Installing KVM and required packages ==="
    apt update
    apt install -y qemu-kvm libvirt-daemon-system libvirt-clients bridge-utils \
        virtinst virt-manager cloud-image-utils netplan.io
    
    # Verify installation
    if [ $? -ne 0 ]; then
        echo "ERROR: Package installation failed"
        exit 1
    fi

    setup_permissions
    configure_libvirt

    echo "=== Adding user to required groups ==="
    adduser $SUDO_USER libvirt
    adduser $SUDO_USER kvm
    adduser $SUDO_USER libvirt-qemu

    echo "=== Verifying KVM installation ==="
    systemctl enable --now libvirtd
    systemctl status libvirtd --no-pager
    virsh list --all
}

check_root
install_kvm
