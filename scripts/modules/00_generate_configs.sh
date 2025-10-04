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

# III. Генериране на Python Проекта
# =========================================================
echo ">>> Generating Python project structure and files..."
# 1. Зависимости и среда
cat <<'EOF' > "$PROJECT_DIR/requirements.txt"
fastapi
uvicorn[standard]
sqlalchemy
psycopg2-binary
python-jose[cryptography]
passlib==1.7.4
bcrypt==4.0.1
python-multipart
jinja2
python-dotenv
aiofiles
psutil
EOF
cat <<EOF > "$PROJECT_DIR/.env"
DATABASE_URL=postgresql://$DB_USER:$DB_PASS@localhost/$DB_NAME
SECRET_KEY=$JWT_SECRET_KEY
ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=30
SERVER_IP=$SERVER_IP
IMAGE_DIR=$IMAGE_DIR
PROJECT_DIR=$PROJECT_DIR
EOF
# 2. Инициализиращи файлове
touch "$PROJECT_DIR/app/__init__.py"; touch "$PROJECT_DIR/app/api/__init__.py"; touch "$PROJECT_DIR/app/web/__init__.py"

# 3. НОВ ФАЙЛ за споделени променливи
cat <<'EOF' > "$PROJECT_DIR/app/shared.py"
from datetime import datetime
# Тази променлива се задава еднократно при стартиране на процеса
APP_START_TIME = datetime.now()
EOF

# 4. Основни Python файлове
# a. database.py
cat <<EOF > "$PROJECT_DIR/app/database.py"
from sqlalchemy import create_engine
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker
import os
from dotenv import load_dotenv
load_dotenv(dotenv_path="$PROJECT_DIR/.env")
DATABASE_URL = os.getenv("DATABASE_URL")
engine = create_engine(DATABASE_URL)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()
def get_db():
    db = SessionLocal()
    try: yield db
    finally: db.close()
EOF
# b. models.py
cat <<'EOF' > "$PROJECT_DIR/app/models.py"
from sqlalchemy import Boolean, Column, Integer, String, ForeignKey, DateTime, Enum
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
import enum
from .database import Base
class UserRole(str, enum.Enum):
    admin = "admin"; reseller = "reseller"
class User(Base):
    __tablename__ = "users"; id = Column(Integer, primary_key=True, index=True)
    username = Column(String, unique=True, index=True, nullable=False)
    hashed_password = Column(String, nullable=False)
    role = Column(Enum(UserRole), nullable=False, default=UserRole.reseller)
    is_active = Column(Boolean, default=True)
class Client(Base):
    __tablename__ = "clients"; id = Column(Integer, primary_key=True, index=True)
    mac_address = Column(String, unique=True, index=True, nullable=False)
    name = Column(String, index=True, default="New Client")
    bootloader = Column(String, nullable=False, default="ipxe.pxe")
    is_enabled = Column(Boolean, default=True)
    os_image_id = Column(Integer, ForeignKey("disks.id"), nullable=True)
    owner_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    os_image = relationship("Disk"); owner = relationship("User")
class Disk(Base):
    __tablename__ = "disks"; id = Column(Integer, primary_key=True, index=True)
    name = Column(String, unique=True, nullable=False)
    filename = Column(String, unique=True, nullable=False)
    is_system_image = Column(Boolean, default=False)
class Log(Base):
    __tablename__ = "logs"; id = Column(Integer, primary_key=True, index=True)
    timestamp = Column(DateTime(timezone=True), server_default=func.now())
    level = Column(String, nullable=False, default="INFO")
    message = Column(String, nullable=False); client_mac = Column(String, nullable=True)
class PendingClient(Base):
    __tablename__ = "pending_clients"; id = Column(Integer, primary_key=True, index=True)
    mac_address = Column(String, unique=True, index=True, nullable=False)
    first_seen = Column(DateTime(timezone=True), server_default=func.now())
    last_seen = Column(DateTime(timezone=True), onupdate=func.now(), server_default=func.now())
EOF
# c. schemas.py
cat <<'EOF' > "$PROJECT_DIR/app/schemas.py"
from pydantic import BaseModel
from typing import Optional, List
from datetime import datetime
from .models import UserRole
class NetworkSettings(BaseModel):
    server_ip:str; gateway_ip:str; dns_server:str; interface:str; dhcp_mode:str
    dhcp_range_start:str; dhcp_range_end:str; auto_add_pending_clients:bool
class User(BaseModel):
    id: int; username: str; is_active: bool; role: UserRole
    class Config: from_attributes = True
class UserCreate(BaseModel):
    username: str; password: str; role: UserRole = UserRole.reseller
class Disk(BaseModel):
    id: int; name: str; filename: str; is_system_image: bool
    class Config: from_attributes = True
class Client(BaseModel):
    id:int; name:str; mac_address:str; is_enabled:bool; bootloader:str; os_image:Optional[Disk]=None
    class Config: from_attributes = True
class ClientCreate(BaseModel):
    name: str; mac_address: str; os_image_id: Optional[int] = None; bootloader: str
class ClientUpdate(BaseModel):
    name: Optional[str]=None; is_enabled:Optional[bool]=None; os_image_id:Optional[int]=None; bootloader:Optional[str]=None
class PendingClient(BaseModel):
    id: int; mac_address: str; first_seen: datetime; last_seen: datetime
    class Config: from_attributes = True
class Log(BaseModel):
    id: int; timestamp: datetime; message: str; level: str; client_mac: Optional[str] = None
    class Config: from_attributes = True
class ImageFile(BaseModel):
    name: str; size_mb: float; modified_date: datetime
class Token(BaseModel):
    access_token: str; token_type: str
class TokenData(BaseModel):
    username: Optional[str] = None
EOF
# d. crud.py
cat <<'EOF' > "$PROJECT_DIR/app/crud.py"
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
EOF
# e. auth.py
cat <<'EOF' > "$PROJECT_DIR/app/auth.py"
from fastapi import Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer
from sqlalchemy.orm import Session
from jose import JWTError, jwt
from passlib.context import CryptContext
from datetime import datetime, timedelta
import os
from . import crud, schemas, database
SECRET_KEY = os.getenv("SECRET_KEY"); ALGORITHM = os.getenv("ALGORITHM")
ACCESS_TOKEN_EXPIRE_MINUTES = int(os.getenv("ACCESS_TOKEN_EXPIRE_MINUTES", 30))
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/api/auth/token")
def verify_password(plain_password, hashed_password):
    return pwd_context.verify(plain_password, hashed_password)
def get_password_hash(password):
    return pwd_context.hash(password)
def create_access_token(data: dict):
    to_encode = data.copy()
    expire = datetime.utcnow() + timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
    to_encode.update({"exp": expire})
    return jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)
async def get_current_user(token: str=Depends(oauth2_scheme), db: Session=Depends(database.get_db)):
    credentials_exception = HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Could not validate credentials", headers={"WWW-Authenticate": "Bearer"})
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        username: str = payload.get("sub")
        if username is None: raise credentials_exception
    except JWTError: raise credentials_exception
    user = crud.get_user_by_username(db, username=username)
    if user is None: raise credentials_exception
    return user
EOF
# f. settings_manager.py
cat <<'EOF' > "$PROJECT_DIR/app/settings_manager.py"
import json, os, subprocess
from .schemas import NetworkSettings
PROJECT_DIR = os.getenv("PROJECT_DIR", "/srv/pxeboss")
SETTINGS_PATH = os.path.join(PROJECT_DIR, "configs/settings.json")
DNSMASQ_CONF_PATH = os.path.join(PROJECT_DIR, "configs/dnsmasq.conf")
TFTP_ROOT = os.path.join(PROJECT_DIR, "tftpboot")
def load_settings() -> dict:
    if not os.path.exists(SETTINGS_PATH): return {}
    with open(SETTINGS_PATH, "r") as f: return json.load(f)
def save_settings(settings: NetworkSettings):
    with open(SETTINGS_PATH, "w") as f: json.dump(settings.dict(), f, indent=2)
    generate_dnsmasq_conf(settings)
def generate_dnsmasq_conf(settings: NetworkSettings):
    conf = [f"interface={settings.interface}", "no-hosts", "no-resolv", f"dhcp-option=3,{settings.gateway_ip}", f"dhcp-option=6,{settings.dns_server}", "enable-tftp", f"tftp-root={TFTP_ROOT}", "log-dhcp"]
    if settings.dhcp_mode == "authoritative":
        conf.insert(1, "dhcp-authoritative")
        conf.append(f"dhcp-range={settings.dhcp_range_start},{settings.dhcp_range_end},255.255.255.0,12h")
    elif settings.dhcp_mode == "proxy": conf.append(f"dhcp-range={settings.server_ip},proxy")
    conf.append("dhcp-userclass=set:is_ipxe,iPXE")
    conf.append(f"dhcp-boot=tag:is_ipxe,http://{settings.server_ip}:8000/api/boot/script/${{net0/mac}}")
    conf.append("dhcp-boot=net:!is_ipxe,ipxe.pxe")
    with open(DNSMASQ_CONF_PATH, "w") as f: f.write("# Auto-generated by PXE-Boss\n" + "\n".join(conf) + "\n")
def apply_dnsmasq_settings():
    try:
        settings = load_settings(); generate_dnsmasq_conf(NetworkSettings(**settings))
        subprocess.run(["sudo", "systemctl", "restart", "dnsmasq.service"], check=True, capture_output=True, text=True)
        return {"success": True, "message": "dnsmasq service restarted successfully."}
    except Exception as e: return {"success": False, "message": f"An unexpected error occurred: {str(e)}"}
EOF
# g. main.py -- КОРИГИРАНА ВЕРСИЯ
cat <<EOF > "$PROJECT_DIR/app/main.py"
from fastapi import FastAPI
from .database import engine, get_db, Base
from . import models, crud, schemas, shared
from .api import api_auth, api_clients, api_boot, api_settings, api_images, api_dashboard
from .web import web_admin
from .settings_manager import apply_dnsmasq_settings

Base.metadata.create_all(bind=engine)
app = FastAPI(title="PXE-Boss")

@app.on_event("startup")
async def startup_event():
    print(f"Application starting at: {shared.APP_START_TIME}")
    print("Applying initial dnsmasq settings...")
    result = apply_dnsmasq_settings()
    print(result["message"])
    db = next(get_db())
    try:
        if not crud.get_user_by_username(db, username="admin"):
            print("Creating default admin user...")
            crud.create_user(db, user=schemas.UserCreate(username="admin", password="StrongAdminPass123!", role=models.UserRole.admin))
            print("Default admin user created.")
            crud.get_or_create_disk(db, name="Windows 10", filename="system-windows.img", is_system=True)
            crud.get_or_create_disk(db, name="Game Disk", filename="game-disk.img", is_system=False)
            print("Default disk entries created.")
    finally: db.close()

app.include_router(web_admin.router)
app.include_router(api_auth.router, prefix="/api/auth", tags=["Authentication"])
app.include_router(api_clients.router, prefix="/api/clients", tags=["Clients"])
app.include_router(api_boot.router, prefix="/api/boot", tags=["PXE Boot"])
app.include_router(api_settings.router, prefix="/api/settings", tags=["Settings"])
app.include_router(api_images.router, prefix="/api/images", tags=["Images"])
app.include_router(api_dashboard.router, prefix="/api/dashboard", tags=["Dashboard"])
EOF
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