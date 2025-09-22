#!/bin/bash

set -e

# =================================================================================
# НАСТРОЙКИ
# =================================================================================
INTERFACE="ens160"
DHCP_RANGE="10.5.50.100,10.5.50.200,255.255.255.0,12h"
SERVER_IP="10.5.50.3"
TFTP_ROOT="/var/lib/tftpboot"
IMAGES_DIR="/var/lib/pxe-boss/images" # Ново: Папка за нашите OS имиджи
# =================================================================================

echo "================================================="
echo "Starting PXE-Boss Server Setup"
echo "================================================="

# Стъпки 1-4 ... (няма промяна)
sudo apt-get update && sudo apt-get upgrade -y
sudo apt-get install -y dnsmasq tgt postgresql python3-pip python3-venv syslinux-common pxelinux

echo "--> Configuring Dnsmasq..."
sudo tee /etc/dnsmasq.d/pxe-boss.conf > /dev/null <<-EOF
port=0
interface=${INTERFACE}
dhcp-range=${DHCP_RANGE}
dhcp-boot=pxelinux.0,,${SERVER_IP}
dhcp-option=3,${SERVER_IP}
dhcp-option=6,8.8.8.8
enable-tftp
tftp-root=${TFTP_ROOT}
EOF
sudo mkdir -p ${TFTP_ROOT}
sudo chmod -R 777 ${TFTP_ROOT}
sudo systemctl restart dnsmasq

echo "--> Copying PXELINUX bootloader files..."
sudo cp /usr/lib/PXELINUX/pxelinux.0 ${TFTP_ROOT}
sudo cp /usr/lib/syslinux/modules/bios/{libutil.c32,menu.c32,ldlinux.c32,libcom32.c32} ${TFTP_ROOT}
sudo mkdir -p ${TFTP_ROOT}/pxelinux.cfg
sudo tee ${TFTP_ROOT}/pxelinux.cfg/default > /dev/null <<-EOF
DEFAULT menu.c32
PROMPT 0
TIMEOUT 300
ONTIMEOUT local
MENU TITLE PXE-Boss Boot Menu
LABEL pxe-boss-ok
    MENU LABEL PXE-Boss Server is running...
    TEXT HELP
        The PXE boot loader is working.
    ENDTEXT
    KERNEL menu.c32
EOF

# Стъпка 5: Конфигурация на iSCSI Target (tgt)
echo "--> Configuring iSCSI Target..."
# Създаваме папката за имиджите, ако не съществува
sudo mkdir -p ${IMAGES_DIR}

# Създаваме един примерен (dummy) имидж файл, ако не съществува
# Това е нужно, за да може tgt услугата да стартира успешно
if [ ! -f "${IMAGES_DIR}/dummy.img" ]; then
    echo "--> Creating a dummy 1GB image file for iSCSI..."
    sudo truncate -s 1G ${IMAGES_DIR}/dummy.img
fi

# Създаваме конфигурационен файл за нашия iSCSI Target
sudo tee /etc/tgt/conf.d/pxe-boss.conf > /dev/null <<-EOF
# Default target for PXE-Boss clients
# This will be managed by the API later
<target iqn.2025-09.world.pxe-boss:default>
    # 1 means this target is ready to be used
    driver iscsi
    backing-store ${IMAGES_DIR}/dummy.img
</target>
EOF

echo "--> Restarting iSCSI Target service (tgt)..."
sudo systemctl restart tgt

echo "================================================="
echo "Setup script finished successfully!"
echo "================================================="
