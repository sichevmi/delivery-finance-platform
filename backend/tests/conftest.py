import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent.parent))

import asyncio
import os
from typing import AsyncGenerator, Generator

import pytest
from fastapi.testclient import TestClient
from httpx import AsyncClient
from sqlalchemy import create_engine
from sqlalchemy.orm import Session, sessionmaker
from sqlalchemy.pool import StaticPool

from app.core.database import Base, get_db
from app.core.config import settings
from app.main import app


# Создаём тестовую БД (SQLite в памяти для скорости)
# Если нужна реальная PostgreSQL, можно создать отдельную тестовую БД,
# но для простоты оставим SQLite.
TEST_DATABASE_URL = "sqlite:///:memory:"

engine = create_engine(
    TEST_DATABASE_URL,
    connect_args={"check_same_thread": False},
    poolclass=StaticPool,
)
TestingSessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

# Переопределяем зависимость get_db для тестов
def override_get_db():
    db = TestingSessionLocal()
    try:
        yield db
    finally:
        db.close()

app.dependency_overrides[get_db] = override_get_db


@pytest.fixture(scope="function")
def test_db():
    """Создаёт свежую схему БД перед каждым тестом и удаляет после."""
    Base.metadata.create_all(bind=engine)
    yield
    Base.metadata.drop_all(bind=engine)


@pytest.fixture(scope="function")
def db_session(test_db):
    """Возвращает сессию БД для тестов."""
    db = TestingSessionLocal()
    try:
        yield db
    finally:
        db.close()


@pytest.fixture(scope="function")
def client(test_db) -> Generator:
    """Тестовый клиент FastAPI (синхронный) для эндпоинтов."""
    with TestClient(app) as c:
        yield c


@pytest.fixture(scope="function")
async def async_client(test_db) -> AsyncGenerator:
    """Асинхронный клиент для тестов (используется редко, но может пригодиться)."""
    async with AsyncClient(app=app, base_url="http://test") as ac:
        yield ac


@pytest.fixture
def test_user_data():
    """Данные тестового пользователя."""
    return {"email": "test@example.com", "password": "securepassword123"}


@pytest.fixture
def create_test_user(db_session, test_user_data):
    """Создаёт тестового пользователя в БД (хеширует пароль)."""
    from app.core.security import get_password_hash
    from app.modules.users.models import User

    user = User(
        email=test_user_data["email"],
        hashed_password=get_password_hash(test_user_data["password"]),
        is_active=True,
        role="user",
    )
    db_session.add(user)
    db_session.commit()
    db_session.refresh(user)
    return user