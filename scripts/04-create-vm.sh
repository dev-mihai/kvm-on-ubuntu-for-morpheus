#!/bin/bash
SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
source "${SCRIPT_DIR}/../config/settings.conf"

check_root() {
    if [ "$(id -u)" != "0" ]; then
        echo "This script must be run as root" 1>&2
        exit 1
    fi
}

verify_bridge() {
    if ! ip a show br0 >/dev/null 2>&1; then
        echo "ERROR: Bridge br0 not found. Please run network configuration first."
        exit 1
    fi
}

check_memory() {
    local total_mem=$(free -m | awk '/^Mem:/{print $2}')
    if [ $VM_RAM -gt $((total_mem/2)) ]; then
        echo "WARNING: Requested VM memory ($VM_RAM MB) is more than half of system memory ($total_mem MB)"
        read -p "Continue anyway? (y/n) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi
}

setup_storage_pools() {
    echo "=== Setting up storage pools ==="
    
    # Create directories if they don't exist
    mkdir -p "$VM_DIR"
    chmod 755 "$VM_DIR"
    chown root:root "$VM_DIR"
    
    # Define default storage pool if it doesn't exist
    if ! virsh pool-info default >/dev/null 2>&1; then
        virsh pool-define-as --name default --type dir --target "$VM_DIR"
        virsh pool-build default
        virsh pool-start default
        virsh pool-autostart default
    fi
    
    # Verify pool is active
    echo "=== Verifying storage pool ==="
    virsh pool-list --all
}

create_vm() {
    # Verify bridge exists
    verify_bridge
    
    # Check memory requirements
    check_memory
    
    # Setup storage pools correctly
    setup_storage_pools
    
    echo "=== Setting up environment variables ==="
    MAC_ADDR=$(printf '52:54:00:%02x:%02x:%02x' $((RANDOM%256)) $((RANDOM%256)) $((RANDOM%256)))
    INTERFACE=eth0
    
    # Define paths
    CLOUD_IMAGE="$VM_DIR/focal-server-cloudimg-amd64.img"
    VM_DISK="$VM_DIR/$VM_NAME.qcow2"
    CLOUD_INIT_DISK="$VM_DIR/$VM_NAME-seed.qcow2"

    echo "=== Downloading Ubuntu cloud image ==="
    if [ ! -f "$CLOUD_IMAGE" ]; then
        wget -O "$CLOUD_IMAGE" "https://cloud-images.ubuntu.com/$UBUNTU_RELEASE/current/focal-server-cloudimg-amd64.img"
        if [ $? -ne 0 ]; then
            echo "Failed to download Ubuntu cloud image"
            exit 1
        fi
        chown root:root "$CLOUD_IMAGE"
        chmod 644 "$CLOUD_IMAGE"
    fi

    echo "=== Creating VM disk ==="
    qemu-img create -F qcow2 -b "$CLOUD_IMAGE" -f qcow2 "$VM_DISK" "$VM_SIZE"
    if [ $? -ne 0 ]; then
        echo "Failed to create VM disk"
        exit 1
    fi

    chown libvirt-qemu:libvirt-qemu "$VM_DISK"
    chmod 644 "$VM_DISK"

    echo "=== Creating cloud-init configurations ==="
    # Create cloud-init configs in a temporary directory
    TEMP_DIR=$(mktemp -d)
    cd "$TEMP_DIR" || exit 1
    
    cat > network-config <<NETCONFIG
network:
    version: 2
    ethernets:
        $INTERFACE:
            addresses:
            - $VM_IP/$NETWORK_CIDR
            dhcp4: false
            routes:
            -   to: default
                via: $GATEWAY
            match:
                macaddress: $MAC_ADDR
            nameservers:
                addresses:
                - $DNS1
                - $DNS2
            set-name: $INTERFACE
NETCONFIG

cat > user-data <<USERDATA
#cloud-config
hostname: $VM_NAME
manage_etc_hosts: true
# Install QEMU Guest Agent
packages:
  - qemu-guest-agent
# Enable and start QEMU Guest Agent
runcmd:
  - [ systemctl, enable, qemu-guest-agent ]
  - [ systemctl, start, qemu-guest-agent ]
users:
  - name: $VM_USERNAME
    sudo: ALL=(ALL) NOPASSWD:ALL
    groups: users, admin
    home: /home/$VM_USERNAME
    shell: /bin/bash
    lock_passwd: false
    passwd: $VM_PASSWORD
ssh_pwauth: true
disable_root: false

USERDATA

    touch meta-data

    echo "=== Creating cloud-init disk ==="
    cloud-localds -v --network-config=network-config "$CLOUD_INIT_DISK" user-data meta-data
    if [ $? -ne 0 ]; then
        echo "Failed to create cloud-init disk"
        rm -rf "$TEMP_DIR"
        exit 1
    fi

    # Set proper permissions for seed disk
    chown libvirt-qemu:libvirt-qemu "$CLOUD_INIT_DISK"
    chmod 644 "$CLOUD_INIT_DISK"

    # Clean up temporary directory
    rm -rf "$TEMP_DIR"

    echo "=== Creating VM ==="
    virt-install --connect qemu:///system \
      --virt-type kvm \
      --name "$VM_NAME" \
      --ram "$VM_RAM" \
      --vcpus "$VM_VCPUS" \
      --os-variant ubuntu20.04 \
      --disk path="$VM_DISK",device=disk,format=qcow2 \
      --disk path="$CLOUD_INIT_DISK",device=disk \
      --import \
      --network bridge=br0,model=virtio,mac="$MAC_ADDR" \
      --channel unix,target_type=virtio,name=org.qemu.guest_agent.0 \
      --noautoconsole

    if [ $? -ne 0 ]; then
        echo "Failed to create VM"
        exit 1
    fi

    echo "=== VM Creation Complete ==="
    echo "Waiting for VM to initialize..."
    sleep 20
    virsh list --all
    virsh domifaddr "$VM_NAME"

    echo ""
    echo "VM Creation completed successfully!"
    echo "You can connect to the VM using:"
    echo "ssh $VM_USERNAME@$VM_IP"
    echo "Password: [Using password from settings.conf]"}

check_root
create_vm

