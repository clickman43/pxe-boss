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
