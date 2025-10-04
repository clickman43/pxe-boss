#!/bin/bash
PORT=8000; PID=$(lsof -t -i:$PORT)
if [ -z "$PID" ]; then echo ">>> No process found on port $PORT."; else
echo ">>> Stopping process with PID: $PID..."; kill -9 $PID; echo ">>> Process stopped."; fi
