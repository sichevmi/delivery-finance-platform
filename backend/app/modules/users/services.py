from sqlalchemy.orm import Session
from app.modules.users.models import User, RefreshToken
from app.modules.users.schemas import UserCreate
from app.core.security import get_password_hash, verify_password, create_access_token, create_refresh_token
from datetime import datetime, timedelta
from jose import jwt, JWTError
from app.core.config import settings
from fastapi import HTTPException, status

def get_user_by_email(db: Session, email: str) -> User | None:
    user = db.query(User).filter(User.email == email).first()
    print(f"🔍 Checking email {email}, found: {user}")
    return user

def get_user_by_id(db: Session, user_id: int) -> User | None:
    return db.query(User).filter(User.id == user_id).first()

def create_user(db: Session, user_data: UserCreate) -> User:
    hashed = get_password_hash(user_data.password)
    db_user = User(email=user_data.email, hashed_password=hashed)
    db.add(db_user)
    db.commit()
    db.refresh(db_user)
    return db_user

def authenticate_user(db: Session, email: str, password: str) -> User | None:
    user = get_user_by_email(db, email)
    if not user or not verify_password(password, user.hashed_password):
        return None
    return user

def create_tokens_for_user(user: User, db: Session) -> dict:
    access_token = create_access_token(data={"sub": str(user.id), "email": user.email})
    refresh_token = create_refresh_token(data={"sub": str(user.id)})

    # Сохраняем refresh token в БД
    expires_at = datetime.utcnow() + timedelta(days=settings.REFRESH_TOKEN_EXPIRE_DAYS)
    db_refresh = RefreshToken(
        token=refresh_token,
        user_id=user.id,
        expires_at=expires_at
    )
    db.add(db_refresh)
    db.commit()

    return {"access_token": access_token, "refresh_token": refresh_token}

def refresh_access_token(db: Session, refresh_token: str) -> str:
    # Проверяем refresh token
    try:
        payload = jwt.decode(refresh_token, settings.REFRESH_SECRET_KEY, algorithms=[settings.JWT_ALGORITHM])
        user_id = payload.get("sub")
        if user_id is None:
            raise HTTPException(status_code=401, detail="Invalid refresh token")
    except JWTError:
        raise HTTPException(status_code=401, detail="Invalid refresh token")

    # Проверяем, существует ли токен в БД и не отозван
    db_token = db.query(RefreshToken).filter(
        RefreshToken.token == refresh_token,
        RefreshToken.revoked == False,
        RefreshToken.expires_at > datetime.utcnow()
    ).first()
    if not db_token:
        raise HTTPException(status_code=401, detail="Refresh token expired or revoked")

    # Генерируем новый access token
    user = get_user_by_id(db, int(user_id))
    if not user or not user.is_active:
        raise HTTPException(status_code=401, detail="User inactive or not found")

    new_access = create_access_token(data={"sub": str(user.id), "email": user.email})
    return new_access

def revoke_refresh_token(db: Session, refresh_token: str):
    db_token = db.query(RefreshToken).filter(RefreshToken.token == refresh_token).first()
    if db_token:
        db_token.revoked = True
        db.commit()