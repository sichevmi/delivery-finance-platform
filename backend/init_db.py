#!/usr/bin/env python
import os
import sys

from app.core.database import Base
from dotenv import load_dotenv
from sqlalchemy import create_engine, text

load_dotenv()

DATABASE_URL = os.getenv("DATABASE_URL")
if not DATABASE_URL:
    print("❌ DATABASE_URL не задан")
    sys.exit(1)

# Очищаем
DATABASE_URL = DATABASE_URL.strip()
if DATABASE_URL.startswith("postgresql://"):
    DATABASE_URL = DATABASE_URL.replace("postgresql://", "postgresql+pg8000://")

print(f"🔗 Подключение: {DATABASE_URL}")

engine = create_engine(DATABASE_URL)

# Проверка подключения
try:
    with engine.connect() as conn:
        conn.execute(text("SELECT 1"))
    print("✅ Подключение успешно")
except Exception as e:
    print(f"❌ Ошибка подключения: {e}")
    sys.exit(1)

# Создаём таблицы
print("📦 Создание таблиц...")
Base.metadata.create_all(bind=engine)
print("✅ Таблицы созданы (или уже существуют)")

# Показываем список таблиц
with engine.connect() as conn:
    result = conn.execute(
        text("SELECT table_name FROM information_schema.tables WHERE table_schema='public'")
    )
    tables = [row[0] for row in result]
    print(f"📋 Таблицы: {', '.join(tables)}")
