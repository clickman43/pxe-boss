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
