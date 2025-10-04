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
class ImageFi
