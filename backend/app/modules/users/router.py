from app.core.database import get_db
from app.modules.users import schemas, services
from app.modules.users.dependencies import get_current_user
from app.modules.users.models import User
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

router = APIRouter(prefix="/auth", tags=["auth"])


@router.post("/register", response_model=schemas.UserInDB)
def register(user_data: schemas.UserCreate, db: Session = Depends(get_db)):
    # Проверяем, существует ли пользователь
    print(f"📩 Register called with: {user_data.email}")
    existing = services.get_user_by_email(db, user_data.email)
    if existing:
        print(f"❌ User found: {existing.email}")
        raise HTTPException(status_code=400, detail="Email already registered")
    user = services.create_user(db, user_data)
    return user


@router.post("/login", response_model=schemas.Token)
def login(login_data: schemas.LoginRequest, db: Session = Depends(get_db)):
    user = services.authenticate_user(db, login_data.email, login_data.password)
    if not user:
        raise HTTPException(status_code=401, detail="Incorrect email or password")
    tokens = services.create_tokens_for_user(user, db)
    return tokens


@router.post("/refresh", response_model=schemas.Token)
def refresh_token(refresh_data: schemas.RefreshTokenRequest, db: Session = Depends(get_db)):
    new_access = services.refresh_access_token(db, refresh_data.refresh_token)
    # Возвращаем новый access и старый refresh (можно вернуть только access)
    # Для простоты возвращаем только access, но можно и новый refresh выдать.
    # Мы вернём тот же refresh, чтобы клиент мог использовать его для повторного обновления,
    # но обычно refresh обновляется. Оставим так.
    return {"access_token": new_access, "refresh_token": refresh_data.refresh_token}


@router.post("/logout")
def logout(refresh_data: schemas.RefreshTokenRequest, db: Session = Depends(get_db)):
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
