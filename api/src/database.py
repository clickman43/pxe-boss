from sqlalchemy import create_engine
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker

# Тук въведи паролата, която създаде по-рано
DATABASE_URL = "postgresql://pxe_boss_user:MySuperSecretPassword123@localhost/pxe_boss_db"

engine = create_engine(DATABASE_URL)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()

# Този код дефинира нашата таблица. Преместихме го тук от main.py
from sqlalchemy import Column, Integer, String, Boolean

class Client(Base):
    __tablename__ = "clients"

    id = Column(Integer, primary_key=True, index=True)
    hostname = Column(String, unique=True, index=True, nullable=False)
    mac_address = Column(String, unique=True, index=True, nullable=False)
    is_enabled = Column(Boolean, default=True)
