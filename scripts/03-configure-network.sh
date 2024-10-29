#!/bin/bash
SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
source "${SCRIPT_DIR}/../config/settings.conf"

check_root() {
    if [ "$(id -u)" != "0" ]; then
        echo "This script must be run as root" 1>&2
        exit 1
    fi
}

verify_mac_address() {
    if [[ ! $HOST_MAC =~ ^([0-9A-Fa-f]{2}:){5}[0-9A-Fa-f]{2}$ ]]; then
        echo "Invalid MAC address format in settings.conf: $HOST_MAC"
        exit 1
    fi
    
    CURRENT_MAC=$(ip link show eth0 | grep -Po 'ether \K[^ ]*')
    if [ "$HOST_MAC" != "$CURRENT_MAC" ]; then
        echo "WARNING: MAC address in settings ($HOST_MAC) doesn't match eth0 ($CURRENT_MAC)"
        echo "Updating settings.conf with correct MAC address"
        HOST_MAC=$CURRENT_MAC
        sed -i "s/HOST_MAC=.*/HOST_MAC=\"$CURRENT_MAC\"/" "${SCRIPT_DIR}/../config/settings.conf"
    fi
}

backup_network_config() {
    echo "=== Backing up current network configuration ==="
    BACKUP_DIR="/root/network-backup-$(date +%Y%m%d_%H%M%S)"
    mkdir -p $BACKUP_DIR
    cp -r /etc/netplan/* $BACKUP_DIR/
    ip a > $BACKUP_DIR/ip_a_output.txt
    ip route > $BACKUP_DIR/ip_route_output.txt
    echo "Network configuration backed up to $BACKUP_DIR"
}

setup_network() {
    echo "=== Verifying MAC address ==="
    verify_mac_address

    echo "=== Creating backup of current network configuration ==="
    backup_network_config

    echo "=== Disabling cloud-init network configuration ==="
    echo "network: {config: disabled}" | tee /etc/cloud/cloud.cfg.d/99-disable-network-config.cfg

    echo "=== Backing up existing netplan configuration ==="
    mkdir -p /etc/netplan/backup
    cp /etc/netplan/*.yaml /etc/netplan/backup/ 2>/dev/null || true
    rm -f /etc/netplan/*.yaml

    echo "=== Creating bridge network configuration ==="
    tee /etc/netplan/00-installer-config.yaml <<NETEOF
network:
    version: 2
    renderer: networkd
    ethernets:
        eth0:
            match:
                macaddress: $HOST_MAC
            set-name: eth0
            optional: true
            dhcp4: no
            dhcp6: no
    bridges:
        br0:
            interfaces:
                - eth0
            addresses: [$HOST_IP/22]
            mtu: 1500
            nameservers:
                addresses:
                    - $DNS1
                    - $DNS2
            routes:
                - to: 0.0.0.0/0
                  via: $GATEWAY
            dhcp4: no
            dhcp6: no
NETEOF

    chmod 600 /etc/netplan/00-installer-config.yaml

    echo "=== Creating libvirt bridge network ==="
    cat > bridge-network.xml <<BRIDGEEOF
<network>
  <name>br0</name>
  <forward mode="bridge"/>
  <bridge name="br0"/>
</network>
BRIDGEEOF

    virsh net-define bridge-network.xml
    virsh net-start br0
    virsh net-autostart br0

    echo "=== Configuring QEMU bridge permissions ==="
    mkdir -p /etc/qemu
    echo "allow br0" | tee /etc/qemu/bridge.conf
    chmod 750 /etc/qemu
    chmod 640 /etc/qemu/bridge.conf

    echo "=== Applying network configuration ==="
    netplan generate
    netplan apply

    echo "=== Waiting for network to stabilize ==="
    sleep 10

    # Verify connectivity
    if ! ping -c 1 $GATEWAY > /dev/null 2>&1; then
        echo "Cannot reach gateway. Network configuration failed."
        exit 1
    fi

    echo "Network configuration successful"
    ip a show br0
    ip route
}

check_root
setup_network
