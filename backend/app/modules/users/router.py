import logging
  
from app.core.database import get_db
from app.modules.users import schemas, services
from app.modules.users.dependencies import get_current_user
from app.modules.users.models import User
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

# Настраиваем логгер
logger = logging.getLogger(__name__)

router = APIRouter(prefix="/auth", tags=["auth"])


@router.post("/register", response_model=schemas.UserInDB)
def register(user_data: schemas.UserCreate, db: Session = Depends(get_db)):
    # Проверяем, существует ли пользователь
    logger.info(f"📩 Register called with: {user_data.email}")
    existing = services.get_user_by_email(db, user_data.email)
    if existing:
        logger.warning(f"❌ User found: {existing.email}")
        raise HTTPException(status_code=400, detail="Email already registered")
    user = services.create_user(db, user_data)
    logger.info(f"✅ User {user_data.email} created successfully")
    return user


@router.post("/login", response_model=schemas.Token)
def login(login_data: schemas.LoginRequest, db: Session = Depends(get_db)):
    logger.info(f"🔐 Login attempt for: {login_data.email}")
    user = services.authenticate_user(db, login_data.email, login_data.password)
    if not user:
        logger.warning(f"❌ Failed login for: {login_data.email}")
        raise HTTPException(status_code=401, detail="Incorrect email or password")
    tokens = services.create_tokens_for_user(user, db)
    logger.info(f"✅ User {login_data.email} logged in successfully")
    return tokens


@router.post("/refresh", response_model=schemas.Token)
def refresh_token(refresh_data: schemas.RefreshTokenRequest, db: Session = Depends(get_db)):
    logger.info("🔄 Token refresh requested")
    new_access = services.refresh_access_token(db, refresh_data.refresh_token)
    return {"access_token": new_access, "refresh_token": refresh_data.refresh_token}


@router.post("/logout")
def logout(refresh_data: schemas.RefreshTokenRequest, db: Session = Depends(get_db)):
    logger.info("🚪 Logout requested")
    services.revoke_refresh_token(db, refresh_data.refresh_token)
    return {"message": "Logged out"}


# Защищённый эндпоинт /hello
@router.get("/hello")
def hello_world(current_user: User = Depends(get_current_user)):
    return {
        "message": "Hello World",
        "user": {
            "id": current_user.id,
            "email": current_user.email,
            "role": current_user.role,
            "is_active": current_user.is_active,
        },
    }