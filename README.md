# Delivery & Finance Platform

Монорепозиторий для системы управления доставками и личными финансами с интеграцией между модулями.

## Структура
- `backend/` – FastAPI + Celery (Python)
- `web/` – React + TypeScript веб-приложение
- `mobile/` – Flutter приложения (доставки и финансы)
- `infrastructure/` – Docker, Nginx, мониторинг
- `docs/` – документация

## Быстрый старт
1. Скопируйте `.env.example` в `.env` и заполните.
2. Запустите `make up` для поднятия инфраструктуры.
3. Перейдите на `http://localhost:8000/docs` для API документации.

Подробнее в [документации](docs/).