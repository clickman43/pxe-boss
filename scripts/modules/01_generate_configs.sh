#!/bin/bash
# ==============================================================================
# PXE-Boss Update Script (update.sh) - ПЪЛНА ФИНАЛНА ВЕРСИЯ
# ==============================================================================
set -e
# I. Конфигурационни Променливи
# =========================================================
SERVER_IP="10.5.50.3"; INTERFACE="ens160"; GATEWAY_IP="10.5.50.1"; DNS_SERVER="10.5.50.1"
DHCP_RANGE_START="10.5.50.100"; DHCP_RANGE_END="10.5.50.200"; DHCP_MODE="authoritative"
AUTO_ADD_CLIENTS="true"; APP_USER="clickman"; PROJECT_DIR="/srv/pxeboss"
IMAGE_DIR="$PROJECT_DIR/images"; TFTP_ROOT="$PROJECT_DIR/tftpboot"
ADMIN_USER="admin"; ADMIN_PASS="StrongAdminPass123!"; DB_USER="pxeboss_user"
DB_PASS="StrongDbPass123!"; DB_NAME="pxeboss"; JWT_SECRET_KEY=$(openssl rand -hex 32)
echo "--- PXE-Boss Backend Generation (FINAL VERSION) ---"

# II. Генериране на Конфигурационни Файлове
# =========================================================
echo ">>> Generating application and system config files..."
if [ ! -f "$PROJECT_DIR/configs/settings.json" ]; then
    echo ">>> Creating initial settings file..."
    cat <<EOF > "$PROJECT_DIR/configs/settings.json"
{"server_ip":"$SERVER_IP","gateway_ip":"$GATEWAY_IP","dns_server":"$DNS_SERVER","interface":"$INTERFACE","dhcp_mode":"$DHCP_MODE","dhcp_range_start":"$DHCP_RANGE_START","dhcp_range_end":"$DHCP_RANGE_END","auto_add_pending_clients": $AUTO_ADD_CLIENTS}
EOF
fi
touch "$PROJECT_DIR/configs/dnsmasq.conf"
cat <<EOF > /etc/resolv.conf
nameserver $GATEWAY_IP
nameserver 8.8.8.8
EOF
cat <<EOF > /etc/tgt/targets.conf
default-driver iscsi
<target iqn.2025-09.com.pxeboss:system-windows>
    backing-store $IMAGE_DIR/system-windows.img
</target>
<target iqn.2025-09.com.pxeboss:windows>
    backing-store $IMAGE_DIR/windows.img
</target>
<target iqn.2025-09.com.pxeboss:ubuntu>
    backing-store $IMAGE_DIR/ubuntu.img
</target>
<target iqn.2025-09.com.pxeboss:game-disk>
    backing-store $IMAGE_DIR/game-disk.img
</target>
EOF
