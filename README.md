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
   nano setup.sh
   ```
2. Make it executable:

```bash
chmod +x setup.sh
```

3. Run it to create the script suite:

```bash
./setup.sh
```
