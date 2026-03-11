.PHONY: help up down restart logs airflow-init dbt-run dbt-test dbt-docs ge-validate fernet-key

DOCKER_COMPOSE = docker compose -f docker/docker-compose.yml

help:
	@echo ""
	@echo "Ecommerce Data Platform — Comandos disponibles"
	@echo "================================================"
	@echo ""
	@echo "  Infraestructura:"
	@echo "    make up            Levantar todos los servicios (Airflow + Postgres)"
	@echo "    make down          Bajar todos los servicios"
	@echo "    make restart       Reiniciar todos los servicios"
	@echo "    make logs          Ver logs de Airflow"
	@echo "    make airflow-init  Inicializar DB y usuario admin de Airflow"
	@echo ""
	@echo "  dbt:"
	@echo "    make dbt-run       Ejecutar todos los modelos dbt"
	@echo "    make dbt-test      Ejecutar tests dbt"
	@echo "    make dbt-docs      Generar y servir documentación dbt"
	@echo ""
	@echo "  Great Expectations:"
	@echo "    make ge-validate   Ejecutar validaciones de calidad de datos"
	@echo ""
	@echo "  Snowflake:"
	@echo "    make snowflake-validate  Verificar conexión y schemas"
	@echo ""
	@echo "  Utilidades:"
	@echo "    make fernet-key    Generar Fernet key para Airflow"
	@echo "    make env-setup     Copiar .env.example a .env"
	@echo ""

# ── Infraestructura ──────────────────────────────────────────────────────────

up:
	$(DOCKER_COMPOSE) up -d

down:
	$(DOCKER_COMPOSE) down

restart:
	$(DOCKER_COMPOSE) restart

logs:
	$(DOCKER_COMPOSE) logs -f airflow-webserver airflow-scheduler

airflow-init:
	$(DOCKER_COMPOSE) run --rm airflow-init

# ── dbt ──────────────────────────────────────────────────────────────────────

dbt-run:
	cd dbt && dbt run

dbt-test:
	cd dbt && dbt test

dbt-staging:
	cd dbt && dbt run --select staging

dbt-marts:
	cd dbt && dbt run --select marts

dbt-docs:
	cd dbt && dbt docs generate && dbt docs serve

# ── Great Expectations ────────────────────────────────────────────────────────

ge-validate:
	python great_expectations/checkpoints/run_checkpoints.py

# ── Utilidades ────────────────────────────────────────────────────────────────

snowflake-validate:
	cd ingestion/scripts && python validate_connection.py

ingest:
	cd ingestion/scripts && python load_raw.py

ingest-table:
	cd ingestion/scripts && python load_raw.py --table $(TABLE)

fernet-key:
	@python -c "from cryptography.fernet import Fernet; print(Fernet.generate_key().decode())"

env-setup:
	@if [ ! -f .env ]; then \
		cp .env.example .env; \
		echo ".env creado desde .env.example — completa los valores antes de continuar"; \
	else \
		echo ".env ya existe — no se sobreescribió"; \
	fi
