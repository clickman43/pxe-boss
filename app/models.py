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
