from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from datetime import datetime, timedelta
from .. import crud, auth, models, database
from ..shared import APP_START_TIME
import psutil, time
router = APIRouter()
last_net_check = None; last_net_io = None
def format_uptime(delta: timedelta) -> str:
    days, rem = divmod(delta.total_seconds(), 86400)
    hours, rem = divmod(rem, 3600)
    minutes, _ = divmod(rem, 60)
    parts = []
    if int(days) > 0: parts.append(f"{int(days)}d")
    if int(hours) > 0: parts.append(f"{int(hours)}h")
    if int(minutes) > 0: parts.append(f"{int(minutes)}m")
    return " ".join(parts) if parts else "< 1m"
@router.get("/stats")
async def get_dashboard_stats(db: Session=Depends(database.get_db), user: models.User = Depends(auth.get_current_user)):
    return {"active_clients":crud.get_active_clients_count(db), "images":crud.get_image_files_count(), "pending":crud.get_pending_clients_count(db), "alarms":crud.get_alarms_count(db)}
@router.get("/monitor")
async def get_system_monitor_stats(user: models.User = Depends(auth.get_current_user)):
    global last_net_check, last_net_io
    now = datetime.now()
    system_boot_time = datetime.fromtimestamp(psutil.boot_time())
    system_uptime_delta = now - system_boot_time
    app_uptime_delta = now - APP_START_TIME
    cpu = psutil.cpu_percent(interval=None); ram = psutil.virtual_memory().percent; disk = psutil.disk_usage('/').percent
    net_io = psutil.net_io_counters(); current_time = time.time(); network_mbps = 0.0
    if last_net_check and last_net_io:
        time_diff = current_time - last_net_check
        bytes_diff = (net_io.bytes_sent - last_net_io.bytes_sent) + (net_io.bytes_recv - last_net_io.bytes_recv)
        if time_diff > 0: network_mbps = round(((bytes_diff * 8) / time_diff) / 1_000_000, 2)
    last_net_check = current_time; last_net_io = net_io
    return {"server_time": now.strftime("%Y-%m-%d %H:%M:%S"), "system_uptime": format_uptime(system_uptime_delta), "app_uptime": format_uptime(app_uptime_delta), "cpu_percent": cpu, "ram_percent": ram, "disk_percent": disk, "network_mbps": network_mbps}
