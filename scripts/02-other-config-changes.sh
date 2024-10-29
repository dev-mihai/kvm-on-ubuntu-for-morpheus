#!/bin/bash

# Create morpheus directories
mkdir -p /var/morpheus/kvm/images
chmod 775 /var/morpheus/kvm/images

# Set up libvirt directories
mkdir -p "$VM_DIR"
chown root:root "$VM_DIR"
chmod 755 "$VM_DIR"

# Ensure libvirt-qemu user exists
getent group libvirt-qemu >/dev/null || groupadd -r libvirt-qemu
getent passwd libvirt-qemu >/dev/null || useradd -r -g libvirt-qemu libvirt-qemu

# Configure libvirt
cp /etc/libvirt/qemu.conf "/etc/libvirt/qemu.conf.backup.$(date +%Y%m%d_%H%M%S)"

# Update qemu.conf settings
sed -i 's/^#user = "root"/user = "root"/' /etc/libvirt/qemu.conf
sed -i 's/^#group = "root"/group = "root"/' /etc/libvirt/qemu.conf
sed -i 's/^#.*security_driver.*=.*\[.*\]/security_driver = [ "none" ]/' "/etc/libvirt/qemu.conf"

# Disable AppArmor and restart libvirtd
systemctl stop apparmor
systemctl restart libvirtd