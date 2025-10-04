from fastapi import APIRouter, Depends
from typing import List
from .. import crud, schemas, auth, models
router = APIRouter()
@router.get("/", response_model=List[schemas.ImageFile])
async def read_image_files(user: models.User = Depends(auth.get_current_user)):
    return crud.get_image_files()
