import logging
from datetime import datetime, timedelta

from app.core.config import settings
from app.core.security import (
    create_access_token,
    create_refresh_token,
    get_password_hash,
    verify_password,
)
from app.modules.users.models import RefreshToken, User
from app.modules.users.schemas import UserCreate
from fastapi import HTTPException
from jose import JWTError, jwt
from sqlalchemy.orm import Session

logger = logging.getLogger(__name__)


def get_user_by_email(db: Session, email: str) -> User | None:
    user = db.query(User).filter(User.email == email).first()
    logger.info(f"🔍 Checking email {email}, found: {user is not None}")
    return user


def get_user_by_id(db: Session, user_id: int) -> User | None:
    return db.query(User).filter(User.id == user_id).first()


def create_user(db: Session, user_data: UserCreate) -> User:
    logger.info(f"📝 Creating user: {user_data.email}")
    hashed = get_password_hash(user_data.password)
    db_user = User(
        email=user_data.email, 
        hashed_password=hashed,
        name=user_data.name if hasattr(user_data, 'name') else None
    )
    db.add(db_user)
    db.commit()
    db.refresh(db_user)
    logger.info(f"✅ User {user_data.email} created with id {db_user.id}")
    return db_user


def authenticate_user(db: Session, email: str, password: str) -> User | None:
    logger.info(f"🔐 Authenticating user: {email}")
    user = get_user_by_email(db, email)
    if not user:
        logger.warning(f"❌ User {email} not found")
        return None
    if not verify_password(password, user.hashed_password):
        logger.warning(f"❌ Invalid password for {email}")
        return None
    logger.info(f"✅ User {email} authenticated")
    return user


def create_tokens_for_user(user: User, db: Session) -> dict:
    access_token = create_access_token(data={"sub": str(user.id), "email": user.email})
    refresh_token = create_refresh_token(data={"sub": str(user.id)})

    # Сохраняем refresh token в БД
    expires_at = datetime.utcnow() + timedelta(days=settings.REFRESH_TOKEN_EXPIRE_DAYS)
    db_refresh = RefreshToken(token=refresh_token, user_id=user.id, expires_at=expires_at)
    db.add(db_refresh)
    db.commit()
    logger.info(f"✅ Tokens created for user {user.email}")

    return {"access_token": access_token, "refresh_token": refresh_token, "token_type": "bearer"}


def refresh_access_token(db: Session, refresh_token: str) -> str:
    logger.info("🔄 Refreshing access token")
    
    # Проверяем refresh token
    try:
        payload = jwt.decode(
            refresh_token, settings.REFRESH_SECRET_KEY, algorithms=[settings.JWT_ALGORITHM]
        )
        user_id = payload.get("sub")
        if user_id is None:
            logger.warning("❌ Refresh token missing 'sub'")
            raise HTTPException(status_code=401, detail="Invalid refresh token")
    except JWTError as e:
        logger.warning(f"❌ Refresh token decode error: {e}")
        raise HTTPException(status_code=401, detail="Invalid refresh token")

    # Проверяем, существует ли токен в БД и не отозван
    db_token = (
        db.query(RefreshToken)
        .filter(
            RefreshToken.token == refresh_token,
            RefreshToken.revoked.is_(False),
            RefreshToken.expires_at > datetime.utcnow(),
        )
        .first()
    )
    if not db_token:
        logger.warning("❌ Refresh token expired or revoked")
        raise HTTPException(status_code=401, detail="Refresh token expired or revoked")

    # Генерируем новый access token
    user = get_user_by_id(db, int(user_id))
    if not user or not user.is_active:
        logger.warning(f"❌ User {user_id} inactive or not found")
        raise HTTPException(status_code=401, detail="User inactive or not found")

    new_access = create_access_token(data={"sub": str(user.id), "email": user.email})
    logger.info(f"✅ New access token created for user {user.email}")
    return new_access


def revoke_refresh_token(db: Session, refresh_token: str):
    logger.info("🚪 Revoking refresh token")
    db_token = db.query(RefreshToken).filter(RefreshToken.token == refresh_token).first()
    if db_token:
        db_token.revoked = True
        db.commit()
        logger.info("✅ Refresh token revoked")