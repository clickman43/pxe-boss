from fastapi import FastAPI, Depends
from sqlalchemy import create_engine, Column, Integer, String, Boolean
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker, Session

# =================================================================================
# DATABASE CONFIGURATION
# =================================================================================

# Тук въведи паролата, която създаде по-рано
DATABASE_URL = "postgresql://pxe_boss_user:MySuperSecretPassword123@localhost/pxe_boss_db"

engine = create_engine(DATABASE_URL)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()

# =================================================================================
# DATABASE MODELS (TABLES)
# =================================================================================

class Client(Base):
    __tablename__ = "clients"

    id = Column(Integer, primary_key=True, index=True)
    hostname = Column(String, unique=True, index=True, nullable=False)
    mac_address = Column(String, unique=True, index=True, nullable=False)
    is_enabled = Column(Boolean, default=True)
    # По-късно ще добавим връзки към имиджи, групи и т.н.

# =================================================================================
# API APPLICATION
# =================================================================================

app = FastAPI(title="PXE-Boss API")

# Създаваме всички таблици в базата данни (ако не съществуват)
# Това е само за целите на разработката, по-късно ще използваме Alembic
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

@app.get("/api/v1/clients")
def get_clients(db: Session = Depends(get_db)):
    clients = db.query(Client).all()
    return clients
