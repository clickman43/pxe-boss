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
