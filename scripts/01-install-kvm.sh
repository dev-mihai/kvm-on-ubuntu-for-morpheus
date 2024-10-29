#!/bin/bash
SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
source "${SCRIPT_DIR}/../config/settings.conf"

check_root() {
    if [ "$(id -u)" != "0" ]; then
        echo "This script must be run as root" 1>&2
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
    apt install -y \
        qemu-kvm \
        libvirt-daemon-system \
        libvirt-clients \
        bridge-utils \
        virtinst \
        virt-manager \
        cloud-image-utils \
        netplan.io

    echo "=== Adding user to required groups ==="
    if [ -n "$SUDO_USER" ]; then
        usermod -aG libvirt "$SUDO_USER"
        usermod -aG kvm "$SUDO_USER"
        usermod -aG libvirt-qemu "$SUDO_USER"
    fi

    echo "=== Verifying KVM installation ==="
    systemctl enable --now libvirtd
    systemctl status libvirtd --no-pager
    virsh list --all
}

check_root
install_kvm