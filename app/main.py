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
