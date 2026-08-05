import os

import pg8000
from dotenv import load_dotenv

load_dotenv()
url = os.getenv("DATABASE_URL")
logMessage("Connecting to:", url)

# Попробуем подключиться вручную
try:
    conn = pg8000.connect(
        host="localhost",
        port=5438,  # или 5432 – подставьте свой реальный порт
        user="postgres",
        password="postgres",
        database="delivery",
    )
    logMessage("✅ Подключение успешно!")
    conn.close()
except Exception as e:
    logMessage("❌ Ошибка:", e)
