from fastapi import FastAPI, Depends, HTTPException
from sqlalchemy.orm import Session
from pydantic import BaseModel
from typing import Optional

from database import SessionLocal, engine, Base, Client

# =================================================================================
# PYDANTIC MODELS (SCHEMAS)
# =================================================================================

class ClientCreate(BaseModel):
    hostname: str
    mac_address: str

class ClientUpdate(BaseModel):
    hostname: Optional[str] = None
    mac_address: Optional[str] = None
    is_enabled: Optional[bool] = None

class ClientResponse(BaseModel):
    id: int
    hostname: str
    mac_address: str
    is_enabled: bool
    class Config:
        from_attributes = True # <--- ПОПРАВКА 1: orm_mode е преименуван

# =================================================================================
# API APPLICATION
# =================================================================================

app = FastAPI(title="PXE-Boss API")
Base.metadata.create_all(bind=engine)

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

@app.get("/")
def read_root():
    return {"message": "PXE-Boss API is running!"}

# --- ENDPOINTS ЗА КЛИЕНТИ ---

@app.post("/api/v1/clients", response_model=ClientResponse, status_code=201)
def create_client(client: ClientCreate, db: Session = Depends(get_db)):
    db_client = db.query(Client).filter(Client.mac_address == client.mac_address).first()
    if db_client:
        raise HTTPException(status_code=400, detail="Client with this MAC address already exists")
    new_client = Client(hostname=client.hostname, mac_address=client.mac_address)
    db.add(new_client)
    db.commit()
    db.refresh(new_client)
    return new_client

@app.get("/api/v1/clients", response_model=list[ClientResponse])
def get_clients(db: Session = Depends(get_db)):
    clients = db.query(Client).all()
    return clients

@app.get("/api/v1/clients/{client_id}", response_model=ClientResponse)
def get_client(client_id: int, db: Session = Depends(get_db)):
    db_client = db.query(Client).filter(Client.id == client_id).first()
    if db_client is None:
        raise HTTPException(status_code=404, detail="Client not found")
    return db_client

@app.put("/api/v1/clients/{client_id}", response_model=ClientResponse)
def update_client(client_id: int, client_update: ClientUpdate, db: Session = Depends(get_db)):
    db_client = get_client(client_id, db)
    # <--- ПОПРАВКА 2: .dict() е преименуван на .model_dump()
    update_data = client_update.model_dump(exclude_unset=True)
    for key, value in update_data.items():
        setattr(db_client, key, value)
    db.commit()
    db.refresh(db_client)
    return db_client

@app.delete("/api/v1/clients/{client_id}", status_code=204)
def delete_client(client_id: int, db: Session = Depends(get_db)):
    db_client = get_client(client_id, db)
    db.delete(db_client)
    db.commit()
    return
