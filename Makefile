.PHONY: up down logs migrate test

up-dev:
	docker-compose -f infrastructure/docker-compose.yml --env-file infrastructure/.env.dev up -d

up-test:
	docker-compose -f infrastructure/docker-compose.yml --env-file infrastructure/.env.test up -d

up-prod:
	docker-compose -f infrastructure/docker-compose.prod.yml --env-file infrastructure/.env.prod up -d

down:
	docker-compose -f infrastructure/docker-compose.yml down

logs:
	docker-compose -f infrastructure/docker-compose.yml logs -f

migrate:
	docker-compose -f infrastructure/docker-compose.yml exec backend alembic upgrade head

test:
	docker-compose -f infrastructure/docker-compose.yml exec backend pytest