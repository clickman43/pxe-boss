from sqlalchemy.orm import Session
from sqlalchemy import func
from . import models, schemas, auth
import os
from datetime import datetime
IMAGE_DIR = os.getenv("IMAGE_DIR", "/srv/pxeboss/images")
def get_user_by_username(db: Session, username: str):
    return db.query(models.User).filter(models.User.username == username).first()
def create_user(db: Session, user: schemas.UserCreate):
    hashed_password = auth.get_password_hash(user.password)
    db_user = models.User(username=user.username, hashed_password=hashed_password, role=user.role)
    db.add(db_user); db.commit(); db.refresh(db_user); return db_user
def get_client(db: Session, client_id: int):
    return db.query(models.Client).filter(models.Client.id == client_id).first()
def get_client_by_mac(db: Session, mac_address: str):
    return db.query(models.Client).filter(models.Client.mac_address == mac_address).first()
def get_clients(db: Session, skip: int = 0, limit: int = 100):
    return db.query(models.Client).order_by(models.Client.name).offset(skip).limit(limit).all()
def create_client(db: Session, client: schemas.ClientCreate, owner_id: int):
    db_client = models.Client(**client.dict(), owner_id=owner_id)
    db.add(db_client); db.commit(); db.refresh(db_client); return db_client
def update_client(db: Session, client_id: int, client_update: schemas.ClientUpdate):
    db_client = get_client(db, client_id)
    if db_client:
        update_data = client_update.dict(exclude_unset=True)
        for key, value in update_data.items(): setattr(db_client, key, value)
        db.commit(); db.refresh(db_client)
    return db_client
def delete_client(db: Session, client_id: int):
    db_client = get_client(db, client_id)
    if db_client: db.delete(db_client); db.commit()
    return db_client
def get_disks(db: Session):
    return db.query(models.Disk).all()
def get_or_create_disk(db: Session, name: str, filename: str, is_system: bool):
    db_disk = db.query(models.Disk).filter(models.Disk.filename == filename).first()
    if not db_disk:
        db_disk = models.Disk(name=name, filename=filename, is_system_image=is_system)
        db.add(db_disk); db.commit(); db.refresh(db_disk)
    return db_disk
def create_log(db: Session, message: str, level: str = "INFO", client_mac: str = None):
    db_log = models.Log(message=message, level=level, client_mac=client_mac)
    db.add(db_log); db.commit(); return db_log
def get_logs(db: Session, skip: int = 0, limit: int = 100):
    return db.query(models.Log).order_by(models.Log.timestamp.desc()).offset(skip).limit(limit).all()
def get_pending_clients(db: Session):
    return db.query(models.PendingClient).order_by(models.PendingClient.last_seen.desc()).all()
def upsert_pending_client(db: Session, mac_address: str):
    db_pending = db.query(models.PendingClient).filter(models.PendingClient.mac_address == mac_address).first()
    if db_pending: db_pending.last_seen = func.now()
    else: db.add(models.PendingClient(mac_address=mac_address))
    db.commit()
def delete_pending_client(db: Session, mac_address: str):
    db_pending = db.query(models.PendingClient).filter(models.PendingClient.mac_address == mac_address).first()
    if db_pending: db.delete(db_pending); db.commit()
def get_image_files() -> list[schemas.ImageFile]:
    files = []
    if not os.path.exists(IMAGE_DIR): return files
    for f in os.listdir(IMAGE_DIR):
        path = os.path.join(IMAGE_DIR, f)
        if os.path.isfile(path):
            stat = os.stat(path)
            files.append(schemas.ImageFile(name=f, size_mb=round(stat.st_size/(1024*1024),2), modified_date=datetime.fromtimestamp(stat.st_mtime)))
    return sorted(files, key=lambda x: x.modified_date, reverse=True)
def get_active_clients_count(db: Session) -> int:
    return db.query(models.Client).filter(models.Client.is_enabled == True).count()
def get_pending_clients_count(db: Session) -> int:
    return db.query(models.PendingClient).count()
def get_image_files_count() -> int:
    if not os.path.exists(IMAGE_DIR): return 0
    return len([name for name in os.listdir(IMAGE_DIR) if os.path.isfile(os.path.join(IMAGE_DIR, name))])
def get_alarms_count(db: Session) -> int:
    return db.query(models.Log).filter(models.Log.level.in_(["WARN", "ERROR"])).count()
