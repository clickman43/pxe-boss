# 5. API Ендпойнти
# a. api_auth.py
cat <<'EOF' > "$PROJECT_DIR/app/api/api_auth.py"
from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import OAuth2PasswordRequestForm
from sqlalchemy.orm import Session
from .. import crud, auth, schemas, database
router = APIRouter()
@router.post("/token", response_model=schemas.Token)
async def login(db: Session=Depends(database.get_db), form_data:OAuth2PasswordRequestForm=Depends()):
    user = crud.get_user_by_username(db, username=form_data.username)
    if not user or not auth.verify_password(form_data.password, user.hashed_password):
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Incorrect username or password")
    return {"access_token": auth.create_access_token(data={"sub": user.username}), "token_type": "bearer"}
EOF
# b. api_clients.py
cat <<'EOF' > "$PROJECT_DIR/app/api/api_clients.py"
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List
from .. import crud, schemas, models, auth, database, settings_manager
router = APIRouter()
@router.get("/", response_model=List[schemas.Client])
async def read_clients(db: Session=Depends(database.get_db), user:models.User=Depends(auth.get_current_user)):
    return crud.get_clients(db)
@router.post("/", response_model=schemas.Client, status_code=status.HTTP_201_CREATED)
async def create_client(client_in:schemas.ClientCreate, db:Session=Depends(database.get_db), user:models.User=Depends(auth.get_current_user)):
    if user.role!=models.UserRole.admin: raise HTTPException(status_code=403)
    if crud.get_client_by_mac(db, mac_address=client_in.mac_address): raise HTTPException(status_code=400, detail="MAC exists")
    if client_in.os_image_id is None:
        disk = db.query(models.Disk).filter(models.Disk.name == "Windows 10").first()
        if disk: client_in.os_image_id = disk.id
    new_client = crud.create_client(db=db, client=client_in, owner_id=user.id)
    crud.delete_pending_client(db, mac_address=new_client.mac_address)
    settings_manager.apply_dnsmasq_settings(); return new_client
@router.put("/{client_id}", response_model=schemas.Client)
async def update_client(client_id:int, client_update:schemas.ClientUpdate, db:Session=Depends(database.get_db), user:models.User=Depends(auth.get_current_user)):
    if user.role!=models.UserRole.admin: raise HTTPException(status_code=403)
    db_client = crud.update_client(db, client_id=client_id, client_update=client_update)
    if not db_client: raise HTTPException(status_code=404)
    settings_manager.apply_dnsmasq_settings(); return db_client
@router.delete("/{client_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_client(client_id:int, db:Session=Depends(database.get_db), user:models.User=Depends(auth.get_current_user)):
    if user.role!=models.UserRole.admin: raise HTTPException(status_code=403)
    if not crud.delete_client(db, client_id=client_id): raise HTTPException(status_code=404)
    settings_manager.apply_dnsmasq_settings()
@router.get("/logs", response_model=List[schemas.Log])
async def read_logs(limit: int = 100, db: Session=Depends(database.get_db), user:models.User=Depends(auth.get_current_user)):
    return crud.get_logs(db, limit=limit)
@router.get("/disks", response_model=List[schemas.Disk])
async def read_disks(db: Session=Depends(database.get_db), user:models.User=Depends(auth.get_current_user)):
    return crud.get_disks(db)
@router.get("/pending", response_model=List[schemas.PendingClient])
async def read_pending(db: Session=Depends(database.get_db), user:models.User=Depends(auth.get_current_user)):
    return crud.get_pending_clients(db)
@router.delete("/pending/{mac}", status_code=status.HTTP_204_NO_CONTENT)
async def deny_pending(mac:str, db:Session=Depends(database.get_db), user:models.User=Depends(auth.get_current_user)):
    if user.role!=models.UserRole.admin: raise HTTPException(status_code=403)
    crud.delete_pending_client(db, mac_address=mac)
EOF
# c. api_settings.py
cat <<'EOF' > "$PROJECT_DIR/app/api/api_settings.py"
from fastapi import APIRouter, Depends, HTTPException, status
from .. import schemas, auth, models, settings_manager
router = APIRouter()
@router.get("/", response_model=schemas.NetworkSettings)
async def get_settings(user: models.User = Depends(auth.get_current_user)):
    if user.role != models.UserRole.admin: raise HTTPException(status_code=status.HTTP_403_FORBIDDEN)
    return settings_manager.load_settings()
@router.post("/", response_model=dict)
async def update_settings(settings: schemas.NetworkSettings, user: models.User = Depends(auth.get_current_user)):
    if user.role != models.UserRole.admin: raise HTTPException(status_code=status.HTTP_403_FORBIDDEN)
    settings_manager.save_settings(settings)
    result = settings_manager.apply_dnsmasq_settings()
    if not result["success"]: raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail=result["message"])
    return {"message": "Settings updated and dnsmasq restarted successfully!"}
EOF
# d. api_boot.py
cat <<'EOF' > "$PROJECT_DIR/app/api/api_boot.py"
from fastapi import APIRouter, Depends, Response
from sqlalchemy.orm import Session
import os
from .. import crud, database, settings_manager
router = APIRouter()
@router.get("/script/{mac}", response_class=Response)
def get_ipxe_script(mac: str, db: Session = Depends(database.get_db)):
    mac_clean = mac.replace("-", ":").lower()
    client = crud.get_client_by_mac(db, mac_address=mac_clean)
    crud.create_log(db, message=f"Boot request from {mac_clean}", client_mac=mac_clean)
    if not client:
        if settings_manager.load_settings().get("auto_add_pending_clients", True):
            crud.upsert_pending_client(db, mac_address=mac_clean)
        script = f"#!ipxe\\necho Client {mac_clean} is not registered.\\nsleep 10\\nreboot"
        crud.create_log(db, level="WARN", message=f"Boot denied for {mac_clean}", client_mac=mac_clean)
        return Response(content=script, media_type="text/plain")
    if not client.is_enabled or not client.os_image:
        script = f"#!ipxe\\necho Client {client.name} is disabled or has no OS image.\\nsleep 10\\nreboot"
        crud.create_log(db, level="WARN", message=f"Boot denied for disabled {client.name}", client_mac=mac_clean)
        return Response(content=script, media_type="text/plain")
    crud.create_log(db, message=f"Providing boot script for {client.name}", client_mac=mac_clean)
    server_ip = os.getenv("SERVER_IP"); iqn_base = "iqn.2025-09.com.pxeboss"
    sys_iqn = f"{iqn_base}:{client.os_image.filename.split('.')[0]}"
    game_iqn = f"{iqn_base}:game-disk"; cache_iqn = f"{iqn_base}:cache-{mac_clean.replace(':', '')}"
    script = f"""#!ipxe
echo Booting client: {client.name}
sanhook --drive 0x80 iscsi:{server_ip}::::{sys_iqn} || goto error
sanhook iscsi:{server_ip}::::{game_iqn} || echo Failed to attach Game Disk
sanhook iscsi:{server_ip}::::{cache_iqn} || echo Failed to attach Cache Disk
sanboot --no-describe --drive 0x80 || goto error
:error
echo Boot failed! && sleep 10 && reboot
"""
    return Response(content=script, media_type="text/plain")
EOF
# e. api_images.py
cat <<'EOF' > "$PROJECT_DIR/app/api/api_images.py"
from fastapi import APIRouter, Depends
from typing import List
from .. import crud, schemas, auth, models
router = APIRouter()
@router.get("/", response_model=List[schemas.ImageFile])
async def read_image_files(user: models.User = Depends(auth.get_current_user)):
    return crud.get_image_files()
EOF
# f. api_dashboard.py -- КОРИГИРАНА ВЕРСИЯ
cat <<'EOF' > "$PROJECT_DIR/app/api/api_dashboard.py"
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
EOF
# g. web_admin.py
cat <<'EOF' > "$PROJECT_DIR/app/web/web_admin.py"
from fastapi import APIRouter, Request
from fastapi.responses import HTMLResponse
from fastapi.templating import Jinja2Templates
router = APIRouter()
templates = Jinja2Templates(directory="app/web/templates")
@router.get("/", response_class=HTMLResponse)
async def read_root(request: Request):
    return templates.TemplateResponse("dashboard.html", {"request": request})
@router.get("/login", response_class=HTMLResponse)
async def login_page(request: Request):
    return templates.TemplateResponse("login.html", {"request": request})
EOF
