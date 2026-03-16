# Ecommerce Data Platform — Olist Brasil

End-to-end data engineering platform processing **1.55 million rows** across 9 tables from Brazil's largest e-commerce marketplace. Built to answer one question: *are we delivering on time, and how much money did we make today?*

---

## What Was Built

A production-grade data pipeline that takes raw CSV files and turns them into business-ready metrics — fully automated, validated, and orchestrated.

```
AWS S3 (raw CSVs)
    └── Airflow DAG (daily @ 6am)
            ├── COPY INTO → Snowflake RAW     (1.55M rows, 9 tables)
            ├── Great Expectations             (5 suites, 0 failures)
            ├── dbt run                        (7 staging views + 4 mart tables)
            └── dbt test                       (17 tests passing)
```

---

## Results

| Component | Outcome |
|---|---|
| Raw ingestion | 1,550,922 rows loaded across 9 tables — idempotent, no duplicates |
| dbt staging | 7 views: cleaned, typed, deduplicated, snake_case |
| dbt marts | 4 tables: `fct_orders`, `dim_customers`, `dim_sellers`, `dim_products` |
| dbt tests | 17 tests passing (not_null, unique, relationships) |
| Data quality | 5 GE suites — orders, order_items, order_payments, order_reviews, customers |
| Orchestration | End-to-end Airflow DAG with retry logic and explicit failure on GE errors |

---

## Dataset — Olist Brasil

Real anonymized transactional data from Brazil's largest e-commerce marketplace.

| Table | Rows | Description |
|---|---|---|
| `orders` | 99,441 | Main order record with status and timestamps |
| `order_items` | 112,650 | Line items per order (product, seller, price) |
| `order_payments` | 103,886 | Payment methods and values |
| `order_reviews` | 99,224 | Customer reviews and scores |
| `customers` | 99,441 | Customer data and geolocation |
| `sellers` | 3,095 | Seller data |
| `products` | 32,951 | Product catalog |
| `geolocation` | 1,000,163 | ZIP code coordinates across Brazil |

---

## Architecture

```
┌─────────────────────────────────────────────────────┐
│                  AWS S3 (Landing Zone)               │
│              s3://ecommerce-olist-raw/raw/olist/     │
└──────────────────────┬──────────────────────────────┘
                       │ COPY INTO via External Stage
                       ▼
┌─────────────────────────────────────────────────────┐
│                     Snowflake                        │
│                                                      │
│  RAW schema       STAGING schema      MARTS schema   │
│  ──────────       ─────────────       ────────────   │
│  1:1 CSVs    ──►  Cleaned, typed ──►  fct_orders     │
│  + metadata       dedup, casted       dim_customers  │
│                                       dim_sellers    │
│                                       dim_products   │
└──────────────────────┬──────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────┐
│                  Apache Airflow 2.8                  │
│                                                      │
│  copy_into_snowflake                                 │
│       └── validate_raw (Great Expectations)          │
│               └── dbt_run                            │
│                       └── dbt_test                   │
└─────────────────────────────────────────────────────┘
```

---

## Tech Stack

| Layer | Technology |
|---|---|
| Orchestration | Apache Airflow 2.8 |
| Transformation | dbt-core + dbt-snowflake |
| Data Warehouse | Snowflake |
| Cloud Storage | AWS S3 |
| Data Quality | Great Expectations |
| Containerization | Docker + Docker Compose |
| Language | Python 3.11 |

---

## Business Metrics Delivered

| Metric | Model |
|---|---|
| GMV diario/mensual | `fct_orders` |
| Tasa de entrega exitosa | `fct_orders.delivery_status` |
| Ticket promedio por estado y categoría | `fct_orders` + `dim_products` |
| Score promedio por seller | `dim_sellers` |
| Tiempo de ciclo (purchase → delivery) | `fct_orders.order_cycle_days` |

---

## Key Engineering Decisions

**S3 como landing zone, no carga directa desde disco**
S3 desacopla la ingesta del procesamiento. Cualquier consumidor (Spark, Athena, otro pipeline) puede leer los mismos archivos. Es además el patrón que se usa en producción.

**Snowflake Storage Integration en lugar de access keys en SQL**
La confianza se establece a nivel IAM Role con External ID. Las credenciales AWS nunca tocan Snowflake — significativamente más seguro que `AWS_KEY_ID` en un stage.

**COPY INTO idempotente + flag `--truncate` para limpiar duplicados**
`FORCE=FALSE` garantiza que re-runs no generen duplicados (Snowflake trackea el historial de carga por archivo). Si los datos ya tienen duplicados, `--truncate` limpia la tabla y recarga con `FORCE=TRUE` — operación segura y trazable.

**dbt con 3 capas explícitas (RAW → STAGING → MARTS)**
Cada capa tiene un propósito claro y un contrato con la siguiente. Nada de transformaciones de negocio en staging, nada de limpieza en marts. La linaje es completa y los tests validan cada capa.

**GE falla el DAG explícitamente**
Si una suite de expectativas falla, el pipeline se detiene. No hay datos corruptos llegando a marts silenciosamente.

---

## What I Learned

**Snowflake & SQL**
- Storage Integration con IAM Role para conectar S3 sin credenciales en queries
- External Stages y el comportamiento de `COPY INTO` (load history, FORCE flag, ON_ERROR)
- Diferencia entre `TRUNCATE` y `DELETE` en contexto de COPY INTO history
- Materialización de modelos: views vs tables según la capa

**dbt**
- Arquitectura de 3 capas con contratos explícitos entre ellas
- `QUALIFY ROW_NUMBER()` para deduplicación en staging
- `sources.yml` como contrato de upstream — no hardcodear nombres de tabla
- Tests nativos: `not_null`, `unique`, `relationships` como primera línea de defensa

**Great Expectations**
- Suites por tabla con expectativas críticas vs informativas
- Checkpoints como unidad de ejecución del pipeline
- Separación entre validación (pass/fail) y reporting (Data Docs)
- Comportamiento de `build_data_docs()` cuando hay archivos con permisos de root

**Airflow**
- DAG con 4 tasks atómicas y dependencias lineales
- `PythonOperator` para lógica con contexto Python (GE checkpoint)
- `BashOperator` para comandos externos (dbt, scripts de ingesta)
- Diferencia entre `schedule_interval` y `catchup` para pipelines diarios

**Python & ingeniería de datos**
- `@contextmanager` para manejar conexiones de forma limpia
- Separación de responsabilidades: `snowflake_client.py` no sabe de negocio
- Flags CLI (`--truncate`, `--dry-run`, `--table`) para operaciones de mantenimiento

**Infraestructura**
- Docker multi-stage para imagen custom de Airflow con dbt + GE
- `.env` + `.env.example` como patrón para credenciales en repos públicos
- Idempotencia como propiedad de diseño, no un feature extra

---

## Project Structure

```
ecommerce-data-platform/
├── airflow/
│   └── dags/
│       └── ecommerce_pipeline.py   # DAG end-to-end
├── dbt/
│   ├── models/
│   │   ├── staging/                # stg_orders, stg_customers, ...
│   │   └── marts/                  # fct_orders, dim_customers, ...
│   ├── profiles.yml
│   └── dbt_project.yml
├── gx/
│   ├── expectations/               # 5 suites JSON
│   ├── checkpoints/
│   ├── create_suites.py
│   └── run_checkpoint.py
├── ingestion/
│   └── scripts/
│       ├── upload_to_s3.py         # CSVs locales → S3
│       ├── load_raw.py             # S3 → Snowflake RAW (COPY INTO)
│       ├── snowflake_client.py     # Conexión reutilizable
│       └── setup_snowflake.sql     # DDL inicial
├── docker/
│   ├── Dockerfile
│   └── docker-compose.yml
├── Makefile
└── requirements.txt
```

---

## Author

**Edwin** — Data Engineer
[GitHub](https://github.com/EdwLearn) · [LinkedIn](https://linkedin.com/in/edwlearn)
