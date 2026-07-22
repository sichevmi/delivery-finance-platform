# ==================================================
# FinFlow — управление инфраструктурой
# ==================================================

COMPOSE = docker-compose
DEV_ENV = infrastructure/.env.dev
TEST_ENV = infrastructure/.env.test
PROD_ENV = infrastructure/.env.prod

.PHONY: help
help:
	@echo "=============================================="
	@echo "  FinFlow Makefile"
	@echo "=============================================="
	@echo ""
	@echo "  dev-up          - Start local containers (dev)"
	@echo "  dev-down        - Stop local containers"
	@echo "  dev-logs        - Show backend logs"
	@echo "  dev-build       - Rebuild images"
	@echo "  dev-restart     - Restart backend"
	@echo ""
	@echo "  migrate         - Apply migrations"
	@echo "  migrate-create  - Create new migration"
	@echo "  db-shell        - Open psql shell"
	@echo ""
	@echo "  test            - Run backend tests"
	@echo "  test-cov        - Run tests with coverage"
	@echo ""
	@echo "  apk-debug       - Build debug APK"
	@echo "  apk-release     - Build release APK"
	@echo ""
	@echo "  deploy-test     - Deploy to test server (finflow.ru)"
	@echo ""
	@echo "  clean           - Clean Docker cache"
	@echo "  clean-all       - Full Docker cleanup"
	@echo ""
	@echo "  init            - Initialize project (create .env files, build images)"
	@echo ""

dev-up:
	@echo "Starting local environment..."
	cd infrastructure && $(COMPOSE) --env-file .env.dev up -d

dev-down:
	@echo "Stopping local environment..."
	cd infrastructure && $(COMPOSE) --env-file .env.dev down

dev-logs:
	cd infrastructure && $(COMPOSE) --env-file .env.dev logs -f backend

dev-build:
	@echo "Rebuilding images..."
	cd infrastructure && $(COMPOSE) --env-file .env.dev build

dev-restart:
	@echo "Restarting backend..."
	cd infrastructure && $(COMPOSE) --env-file .env.dev restart backend

migrate:
	@echo "Applying migrations..."
	docker exec delivery_backend alembic upgrade head

migrate-create:
	@echo "Creating new migration..."
	@read -p "Enter migration message: " msg; \
	docker exec delivery_backend alembic revision --autogenerate -m "$$msg"

db-shell:
	@echo "Connecting to database (psql)..."
	docker exec -it delivery_db psql -U $$(grep POSTGRES_USER $(DEV_ENV) | cut -d '=' -f2) -d $$(grep POSTGRES_DB $(DEV_ENV) | cut -d '=' -f2)

test:
	@echo "Running backend tests..."
	docker exec delivery_backend pytest tests/

test-cov:
	@echo "Running tests with coverage..."
	docker exec delivery_backend pytest tests/ --cov=app --cov-report=html
	@echo "Coverage report: backend/htmlcov/index.html"

apk-debug:
	@echo "Building debug APK..."
	cd mobile/delivery_app && flutter build apk --debug
	@echo "APK: mobile/delivery_app/build/app/outputs/flutter-apk/app-debug.apk"

apk-release:
	@echo "Building release APK..."
	cd mobile/delivery_app && flutter build apk --release
	@echo "APK: mobile/delivery_app/build/app/outputs/flutter-apk/app-release.apk"



deploy-test:
	@echo "Deploying to test server (finflow.ru)..."
	ssh -i ~/.ssh/id_ed25519 root@195.19.20.178 "cd /var/www/delivery-finance-platform && git pull origin develop && cd infrastructure && docker-compose --env-file .env.test down && docker-compose --env-file .env.test up -d && sleep 5 && docker exec delivery_backend alembic upgrade head"
	@echo "Deployment finished."

clean:
	@echo "Cleaning Docker cache..."
	docker system prune -f

clean-all:
	@echo "Full Docker cleanup..."
	docker system prune -a -f && docker volume prune -f && docker network prune -f

init:
	@echo "Initializing project..."
	@test -f $(DEV_ENV) || (echo "Creating $(DEV_ENV) from template..."; cp infrastructure/.env.example $(DEV_ENV))
	@test -f $(TEST_ENV) || (echo "Creating $(TEST_ENV) from template..."; cp infrastructure/.env.example $(TEST_ENV))
	@echo "Building images..."
	cd infrastructure && $(COMPOSE) --env-file .env.dev build
	@echo "Done. Please edit .env files if needed."

# ------------------------------
# Тестовый стенд (finflow.ru)
# ------------------------------

test-logs:
	@echo "📋 Логи бэкенда на тестовом сервере..."
	ssh -i ~/.ssh/id_ed25519 root@finflow.ru 'docker logs delivery_backend --tail=50'

test-upgrade-deps:
	@echo "⬆️ Обновление bcrypt и passlib в контейнере на тестовом сервере..."
	ssh -i ~/.ssh/id_ed25519 root@finflow.ru 'docker exec delivery_backend pip install --upgrade bcrypt passlib'
	@echo "✅ Зависимости обновлены. Перезапустите бэкенд: make test-restart"

test-restart:
	@echo "🔄 Перезапуск бэкенда на тестовом сервере..."
	ssh -i ~/.ssh/id_ed25519 root@finflow.ru 'docker restart delivery_backend'
	@echo "✅ Бэкенд перезапущен."

test-rebuild:
	@echo "🔨 Пересборка образа бэкенда на тестовом сервере..."
	ssh -i ~/.ssh/id_ed25519 root@finflow.ru 'cd /var/www/delivery-finance-platform/infrastructure && docker-compose --env-file .env.test build backend && docker-compose --env-file .env.test up -d'
	@echo "✅ Образ пересобран и контейнеры перезапущены."