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
