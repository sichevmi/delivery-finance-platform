#!/bin/sh
set -e  # Прерываем выполнение при ошибке

# Проверяем, нужно ли выполнять миграции
if [ "$RUN_MIGRATIONS" = "true" ]; then
    echo "Running database migrations..."
    # alembic использует те же переменные окружения, что и приложение
    # (мы уже настроили загрузку .env в config.py и env.py)
    alembic upgrade head
    echo "Migrations completed."
else
    echo "Skipping migrations (RUN_MIGRATIONS is not set to 'true')."
fi

# Запускаем основную команду (переданную в CMD)
exec "$@"