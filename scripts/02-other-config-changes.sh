#!/bin/bash

# Making some changes to set the environment correclty for morpheus

# Create directories if they don't exist
sudo mkdir -p /var/morpheus/kvm/images
sudo chmod 775 /var/morpheus/kvm/images
     
# Verify pools
echo "=== Verifying storage pools ==="
virsh pool-list --all


#Disabled AppArmor which was preventing VM startup
sudo systemctl stop apparmor

# Restarting libvirtd service
sudo systemctl restart libvirtd