# IV. Генериране на Помощни Скриптове
# =========================================================
cat <<'EOF' > "$PROJECT_DIR/scripts/start.sh"
#!/bin/bash
PROJECT_DIR="/srv/pxeboss"; cd "$PROJECT_DIR"
echo ">>> Activating Python virtual environment..."
source "venv/bin/activate"
echo ">>> Starting Uvicorn server on http://0.0.0.0:8000..."
uvicorn app.main:app --host 0.0.0.0 --port 8000
EOF
cat <<'EOF' > "$PROJECT_DIR/scripts/stop.sh"
#!/bin/bash
PORT=8000; PID=$(lsof -t -i:$PORT)
if [ -z "$PID" ]; then echo ">>> No process found on port $PORT."; else
echo ">>> Stopping process with PID: $PID..."; kill -9 $PID; echo ">>> Process stopped."; fi
EOF

# V. Финализиране
# =========================================================
chmod +x "$PROJECT_DIR/scripts/start.sh"; chmod +x "$PROJECT_DIR/scripts/stop.sh"
chown -R $APP_USER:$APP_USER "$PROJECT_DIR"
echo "--------------------------------------------------------"
echo "✅ PXE-Boss Backend Update Complete! (FINAL ARCHITECTURE)"
echo "--------------------------------------------------------"
echo "To start the application, use the start.sh script:"
echo "sudo -u $APP_USER $PROJECT_DIR/scripts/start.sh"
echo "--------------------------------------------------------"