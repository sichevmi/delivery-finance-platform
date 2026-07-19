import os
from dotenv import load_dotenv
import pg8000

load_dotenv()
url = os.getenv("DATABASE_URL")
print("Connecting to:", url)

# Попробуем подключиться вручную
try:
    conn = pg8000.connect(
        host="localhost",
        port=5438,  # или 5432 – подставьте свой реальный порт
        user="postgres",
        password="postgres",
        database="delivery"
    )
    print("✅ Подключение успешно!")
    conn.close()
except Exception as e:
    print("❌ Ошибка:", e)