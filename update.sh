#!/bin/bash
# ==============================================================================
# PXE-Boss Main Update Script
# Този скрипт изпълнява всички модули за генериране на backend-а.
# ==============================================================================
set -e
PROJECT_DIR="/srv/pxeboss"
MODULES_DIR="$PROJECT_DIR/scripts/modules"

echo "--- Starting PXE-Boss Backend Generation ---"

# 1. Изпълнение на модулите
source "$MODULES_DIR/01_generate_configs.sh"
source "$MODULES_DIR/02_generate_core_files.sh"
source "$MODULES_DIR/03_generate_api_files.sh"
source "$MODULES_DIR/04_generate_scripts.sh"

# 2. Финализиране
echo ">>> Setting final permissions..."
chown -R clickman:clickman "$PROJECT_DIR"

echo "--------------------------------------------------------"
echo "✅ PXE-Boss Backend Update Complete!"
echo "--------------------------------------------------------"
