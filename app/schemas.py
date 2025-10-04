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
