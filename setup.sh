#!/bin/bash

set -e

# =================================================================================
# НАСТРОЙКИ
# =================================================================================
INTERFACE="ens160"
DHCP_RANGE="10.5.50.100,10.5.50.200,255.255.255.0,12h"
SERVER_IP="10.5.50.3"
TFTP_ROOT="/var/lib/tftpboot"
# =================================================================================

echo "================================================="
echo "Starting PXE-Boss Server Setup"
echo "================================================="

# Стъпка 1: Актуализация на системата
sudo apt-get update && sudo apt-get upgrade -y

# Стъпка 2: Инсталация на основните компоненти
# ----> ТУК Е ПОПРАВКАТА - добавяме pxelinux и syslinux-common <----
sudo apt-get install -y dnsmasq tgt postgresql python3-pip python3-venv syslinux-common pxelinux

# Стъпка 3: Конфигурация на Dnsmasq
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

# Стъпка 4: Копиране на PXELINUX файловете
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

echo "================================================="
echo "Setup script finished successfully!"
echo "================================================="
