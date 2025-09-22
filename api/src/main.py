from fastapi import FastAPI, Depends, HTTPException
from sqlalchemy.orm import Session
from pydantic import BaseModel

# Импортираме нещата, които дефинирахме в предишната стъпка
from database import SessionLocal, engine, Base, Client

# =================================================================================
# PYDANTIC MODELS (SCHEMAS)
# =================================================================================

# Този модел дефинира какви данни трябва да подадем, за да създадем клиент
class ClientCreate(BaseModel):
    hostname: str
    mac_address: str

# Този модел дефинира какви данни ще връща API-то, когато четем клиент
class ClientResponse(BaseModel):
    id: int
    hostname: str
    mac_address: str
    is_enabled: bool

    class Config:
        orm_mode = True # Позволява на Pydantic да чете данни от SQLAlchemy обекти

# =================================================================================
# API APPLICATION
# =================================================================================

app = FastAPI(title="PXE-Boss API")

# Създаваме таблиците в базата данни
Base.metadata.create_all(bind=engine)

# Dependency to get a DB session
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

@app.get("/")
def read_root():
    return {"message": "PXE-Boss API is running! Database connection is configured."}

# --- НОВ ENDPOINT ---
@app.post("/api/v1/clients", response_model=ClientResponse)
def create_client(client: ClientCreate, db: Session = Depends(get_db)):
    # Проверяваме дали клиент с такъв MAC адрес вече съществува
    db_client = db.query(Client).filter(Client.mac_address == client.mac_address).first()
    if db_client:
        raise HTTPException(status_code=400, detail="Client with this MAC address already exists")
    
    # Създаваме нов обект по SQLAlchemy модела
    new_client = Client(hostname=client.hostname, mac_address=client.mac_address)
    
    # Добавяме го в сесията и го записваме в базата
    db.add(new_client)
    db.commit()
    db.refresh(new_client)
    
    return new_client

@app.get("/api/v1/clients", response_model=list[ClientResponse])
def get_clients(db: Session = Depends(get_db)):
    clients = db.query(Client).all()
    return clients
