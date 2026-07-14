.PHONY: up down logs migrate test

up:
	docker-compose -f infrastructure/docker-compose.yml up -d

down:
	docker-compose -f infrastructure/docker-compose.yml down

logs:
	docker-compose -f infrastructure/docker-compose.yml logs -f

migrate:
	docker-compose -f infrastructure/docker-compose.yml exec backend alembic upgrade head

test:
	docker-compose -f infrastructure/docker-compose.yml exec backend pytest