#!/bin/bash
SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
source "${SCRIPT_DIR}/../config/settings.conf"

check_root() {
   if [ "$(id -u)" != "0" ]; then
       echo "This script must be run as root" 1>&2
       exit 1
   fi
}

setup_network() {
   # Backup current network config
   BACKUP_DIR="/root/network-backup-$(date +%Y%m%d_%H%M%S)"
   mkdir -p $BACKUP_DIR
   cp -r /etc/netplan/* $BACKUP_DIR/
   
   # Disable cloud-init network configuration
   echo "network: {config: disabled}" > /etc/cloud/cloud.cfg.d/99-disable-network-config.cfg
   
   # Backup and clean netplan configs
   mkdir -p /etc/netplan/backup
   cp /etc/netplan/*.yaml /etc/netplan/backup/ 2>/dev/null || true
   rm -f /etc/netplan/*.yaml

   # Create bridge network configuration
   cat > /etc/netplan/00-installer-config.yaml <<NETEOF
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
     addresses: [$HOST_IP/$NETWORK_CIDR]
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

   # Configure libvirt bridge network
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

   # Configure QEMU bridge permissions
   mkdir -p /etc/qemu
   echo "allow br0" > /etc/qemu/bridge.conf
   chmod 750 /etc/qemu
   chmod 640 /etc/qemu/bridge.conf

   # Apply network configuration
   netplan generate
   netplan apply
   sleep 10

   # Show network status
   ip a show br0
   ip route
}

check_root
setup_network