import logging
from app.core.config import settings
from app.core.database import get_db
from app.modules.users.models import User
from app.modules.users.services import get_user_by_id
from fastapi import Depends, HTTPException
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from jose import JWTError, jwt
from sqlalchemy.orm import Session

logger = logging.getLogger(__name__)
security = HTTPBearer()


async def get_current_user(
    credentials: HTTPAuthorizationCredentials = Depends(security), 
    db: Session = Depends(get_db)
) -> User:
    token = credentials.credentials
    try:
        payload = jwt.decode(token, settings.SECRET_KEY, algorithms=[settings.JWT_ALGORITHM])
        user_id: str = payload.get("sub")
        if user_id is None:
            logger.warning("❌ Token missing 'sub' claim")
            raise HTTPException(status_code=401, detail="Invalid token")
    except JWTError as e:
        logger.warning(f"❌ JWT decode error: {e}")
        raise HTTPException(status_code=401, detail="Invalid token")

    user = get_user_by_id(db, int(user_id))
    if user is None or not user.is_active:
        logger.warning(f"❌ User {user_id} not found or inactive")
        raise HTTPException(status_code=401, detail="User not found or inactive")
    
    logger.info(f"✅ User {user.email} authenticated")
    return user