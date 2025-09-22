#!/bin/bash

set -e

# =================================================================================
# НАСТРОЙКИ
# =================================================================================
INTERFACE="ens160"
DHCP_RANGE="10.5.50.100,10.5.50.200,255.255.255.0,12h"
SERVER_IP="10.5.50.3"
TFTP_ROOT="/var/lib/tftpboot"
IMAGES_DIR="/var/lib/pxe-boss/images"
API_DIR="/opt/pxe-boss-api" # Ново: Папка за нашия API сървър
# =================================================================================

echo "================================================="
echo "Starting PXE-Boss Server Setup"
echo "================================================="

# Стъпки 1-5 ... (няма промяна)
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
    TEXT HELP The PXE boot loader is working. ENDTEXT
    KERNEL menu.c32
EOF

echo "--> Configuring iSCSI Target..."
sudo mkdir -p ${IMAGES_DIR}
if [ ! -f "${IMAGES_DIR}/dummy.img" ]; then
    echo "--> Creating a dummy 1GB image file for iSCSI..."
    sudo truncate -s 1G ${IMAGES_DIR}/dummy.img
fi
sudo tee /etc/tgt/conf.d/pxe-boss.conf > /dev/null <<-EOF
<target iqn.2025-09.world.pxe-boss:default>
    driver iscsi
    backing-store ${IMAGES_DIR}/dummy.img
</target>
EOF
sudo systemctl restart tgt

# Стъпка 6: Настройка на FastAPI сървъра
echo "--> Setting up FastAPI application..."

# Създаваме системен потребител, който ще изпълнява приложението
if ! id -u pxe-boss-api > /dev/null 2>&1; then
    sudo useradd --system --no-create-home --shell /bin/false pxe-boss-api
fi

# Създаваме директорията за приложението и задаваме права
sudo mkdir -p ${API_DIR}
sudo chown -R pxe-boss-api:pxe-boss-api ${API_DIR}

# Създаваме виртуална среда и инсталираме зависимости
sudo -u pxe-boss-api python3 -m venv ${API_DIR}/venv
sudo ${API_DIR}/venv/bin/pip install fastapi uvicorn psycopg2-binary

# Създаваме примерен "Hello World" API файл
sudo tee ${API_DIR}/main.py > /dev/null <<-EOF
from fastapi import FastAPI

app = FastAPI()

@app.get("/")
def read_root():
    return {"message": "PXE-Boss API is running!"}
EOF

# Създаваме systemd service файл, за да управляваме API-то като услуга
sudo tee /etc/systemd/system/pxe-boss-api.service > /dev/null <<-EOF
[Unit]
Description=PXE-Boss API Server
After=network.target

[Service]
User=pxe-boss-api
Group=pxe-boss-api
WorkingDirectory=${API_DIR}
ExecStart=${API_DIR}/venv/bin/uvicorn main:app --host 0.0.0.0 --port 8000

[Install]
WantedBy=multi-user.target
EOF

echo "--> Enabling and starting FastAPI service..."
sudo systemctl daemon-reload
sudo systemctl enable pxe-boss-api.service
sudo systemctl start pxe-boss-api.service

echo "================================================="
echo "Setup script finished successfully!"
echo "================================================="
