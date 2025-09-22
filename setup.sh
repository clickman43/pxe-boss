#!/bin/bash

# Скриптът ще спре, ако някоя команда даде грешка. Задължително е!
set -e

echo "================================================="
echo "Starting PXE-Boss Server Setup"
echo "================================================="

# Стъпка 1: Актуализация на системата
echo "--> Updating system packages..."
sudo apt-get update && sudo apt-get upgrade -y

# Стъпка 2: Инсталация на основните компоненти
# Dnsmasq: DHCP/TFTP сървър
# Tgt: iSCSI сървър
# PostgreSQL: База данни
# Python: За API-то и CLI инструмента
echo "--> Installing core components (Dnsmasq, Tgt, PostgreSQL, Python)..."
sudo apt-get install -y dnsmasq tgt postgresql python3-pip python3-venv

echo "================================================="
echo "Core components installed successfully."
echo "Setup script finished for now."
echo "================================================="
# =================================================================================
# НАСТРОЙКИ - Промени ги според твоята мрежа
# =================================================================================
INTERFACE="eth0"                             # Провери с 'ip a' дали това е името на мрежовата ти карта
DHCP_RANGE="10.5.50.100,10.5.50.200,12h" # DHCP обхват: от 100 до 200
SERVER_IP="10.5.50.3"                      # Статичният IP адрес на този PXE сървър
TFTP_ROOT="/var/lib/tftpboot"                # Папка за TFTP файловете
# =================================================================================
