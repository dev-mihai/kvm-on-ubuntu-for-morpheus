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

Before running the setup script, ensure you have:

1. Updated the `settings.conf` file with your environment data:

   - HOST_IP
   - HOST_MAC
   - GATEWAY
   - VM_IP
2. If your network subnet differs from `/22`, modify the subnet configuration in:

   - `02-configure-network.sh`
   - `03-create-vm.sh`

## Considerations

The newly created VM on the KVM host will have the following credentials:

- **username**: `mihai`
- **password**: `Password123?`

You can update these credentials in the `04-create-vm.sh` file, in the cloud-init user-data section. The password hash can be generated with   `mkpasswd --method=SHA-512 --rounds=4096` command.

## Installation

1. Create the setup script:

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

This will execute the installation process and set up your KVM environment according to the specified configuration.
