from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import OAuth2PasswordRequestForm
from sqlalchemy.orm import Session
from .. import crud, auth, schemas, database
router = APIRouter()
@router.post("/token", response_model=schemas.Token)
async def login(db: Session=Depends(database.get_db), form_data:OAuth2PasswordRequestForm=Depends()):
    user = crud.get_user_by_username(db, username=form_data.username)
    if not user or not auth.verify_password(form_data.password, user.hashed_password):
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Incorrect username or password")
    return {"access_token": auth.create_access_token(data={"sub": user.username}), "token_type": "bearer"}
