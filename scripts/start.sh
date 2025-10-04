#!/bin/bash
PROJECT_DIR="/srv/pxeboss"; cd "$PROJECT_DIR"
echo ">>> Activating Python virtual environment..."
source "venv/bin/activate"
echo ">>> Starting Uvicorn server on http://0.0.0.0:8000..."
uvicorn app.main:app --host 0.0.0.0 --port 8000
