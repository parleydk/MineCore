#!/bin/bash
set -e

# Detect host distro
distro=$(grep '^ID=' /etc/os-release | cut -d= -f2 | tr -d '"')
echo "🧭 Host distro detected: $distro"

# Check for required tools
required_tools=(debootstrap qemu-img curl jq)
missing=()
for tool in "${required_tools[@]}"; do
    command -v $tool >/dev/null || missing+=($tool)
done

if [ ${#missing[@]} -ne 0 ]; then
    echo "⚠️ Missing tools: ${missing[*]}"
    read -p "Install missing tools manually and re-run. Press Enter to exit." _
    exit 1
fi

# Create rootfs
read -p "➡️ Create Debian rootfs in ./minecore-root? [y/N] " confirm
[[ "$confirm" == "y" || "$confirm" == "Y" ]] || exit 1

mkdir -p minecore-root
sudo debootstrap --variant=minbase --arch=amd64 stable ./minecore-root http://deb.debian.org/debian

# Inject files
echo "📦 Injecting config files and scripts..."
sudo cp -r ./inject/* ./minecore-root/

# Optional: Launch chroot or VM
read -p "➡️ Enter chroot now to run minecore-configure.sh? [y/N] " confirm
if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
    sudo cp /etc/resolv.conf ./minecore-root/etc/
    sudo mount --bind /dev ./minecore-root/dev
    sudo mount --bind /proc ./minecore-root/proc
    sudo mount --bind /sys ./minecore-root/sys
    sudo chroot ./minecore-root /bin/bash
fi

echo "🎉 MineCore base system built successfully."
