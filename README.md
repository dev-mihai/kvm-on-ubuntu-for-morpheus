

kvm-setup/
├── config/
│   └── settings.conf
├── scripts/
│   ├── 01-install-kvm.sh
│   ├── 02-configure-network.sh
│   └── 03-create-vm.sh
└── setup.sh

To use this script:

1. Create a bash file:

   ```bash
   nano create-kvm-scripts.sh
   ```
2. Make it executable:

```bash
chmod +x create-kvm-scripts.sh
```

3. Run it to create the script suite:

```bash
./create-kvm-scripts.sh
```

4. Navigate to kvm-setup and run the setup:

```bash
cd kvm-setup && sudo ./setup.sh
```
