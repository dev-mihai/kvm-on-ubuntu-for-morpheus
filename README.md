# KVM on Ubuntu for Morpheus

## Repository Structure

```
kvm-on-ubuntu-for-morpheus/
├── config/
│   └── settings.conf
├── scripts/
│   ├── 01-install-kvm.sh
│   ├── 02-configure-network.sh
│   └── 03-create-vm.sh
└── setup.sh
```

## Prerequisites

Before running the setup script, ensure you have updated the `settings.conf` file with your environment data:

### Network Configuration

- HOST_IP
- HOST_MAC
- GATEWAY
- DNS1
- DNS2
- NETWORK_CIDR

### VM Configuration

- VM_NAME
- VM_IP
- VM_RAM
- VM_VCPUS
- VM_SIZE
- VM_USERNAME
- VM_PASSWORD (hashed)

### Other Configuration

- VM_DIR

## Considerations

### Default Credentials

The VM credentials are configured in `settings.conf`. The default values are:

- **Username**: `yourusername`
- **Password**: `Password123?`

### Password Configuration

To update the VM password:

1. Generate a new password hash:
   ```bash
   mkpasswd --method=SHA-512 --rounds=4096
   ```
2. Update the `VM_PASSWORD` variable in `settings.conf` with the generated hash

## Installation

1. Create the setup script and copy the content from `setup.sh` file:

   ```bash
   nano setup.sh
   ```
2. Make the script executable:

   ```bash
   chmod +x setup.sh
   ```
3. Run the setup script to configure the KVM environment and create a VM:

   ```bash
   ./setup.sh
   ```
