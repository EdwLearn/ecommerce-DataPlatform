# Ecommerce Data Platform — Olist Brasil

> End-to-end data engineering platform processing **100,000+ real orders** from Brazil's largest e-commerce marketplace. Built to answer one question: *are we delivering on time, and how much money did we make today?*

---

## The Problem

Raw transactional data is useless for business decisions. It lives in S3 as flat CSVs, has no type safety, contains duplicates, and lacks any business context. A data analyst can't answer "what's our GMV this month by product category?" from a raw CSV dump.

This platform solves that — from raw files to production-ready business metrics, fully automated.

---

## North Star Metric

**GMV (Gross Merchandise Value) processed per day with a successful delivery rate ≥ 95%**

---

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        AWS S3 (Landing Zone)                    │
│                    s3://ecommerce-olist-raw/                     │
└────────────────────────────┬────────────────────────────────────┘
                             │ COPY INTO (External Stage)
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│                         Snowflake                               │
│                                                                 │
│  RAW schema          STAGING schema         MARTS schema        │
│  ───────────         ─────────────          ────────────        │
│  1:1 with CSVs  ──►  Cleaned, typed,   ──►  fct_orders         │
│  No transforms       snake_case, dedup      dim_customers        │
│                                             dim_sellers          │
│                                             dim_products         │
└─────────────────────────────────────────────────────────────────┘
                             │
                             │ Orchestrated by
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│                       Apache Airflow 2.8                        │
│                                                                 │
│  ingest_raw ──► validate_raw ──► dbt_staging ──► dbt_marts     │
│                                       │               │         │
│                                 Great Expectations   dbt test   │
└─────────────────────────────────────────────────────────────────┘
```

---

## Tech Stack

| Layer | Technology | Why |
|---|---|---|
| Orchestration | Apache Airflow 2.8 | Industry standard, DAG-based, great for backfill |
| Transformation | dbt-core + dbt-snowflake | SQL-first, testable, version-controlled transforms |
| Data Warehouse | Snowflake | Scalable, separation of compute/storage, native S3 integration |
| Cloud Storage | AWS S3 | Decoupled landing zone, durability, cost-effective |
| Data Quality | Great Expectations | Programmatic validation with auto-generated Data Docs |
| Containerization | Docker + Docker Compose | Reproducible local Airflow environment |
| Language | Python 3.11 | Type hints, modern syntax, ecosystem |

---

## Dataset

**Olist Brasil** — real anonymized transactional data from Brazil's largest e-commerce marketplace.

| Table | Rows | Description |
|---|---|---|
| `orders` | ~100k | Main order record with status and timestamps |
| `order_items` | ~112k | Line items per order (product, seller, price) |
| `order_payments` | ~103k | Payment methods and values |
| `order_reviews` | ~99k | Customer reviews and scores |
| `customers` | ~99k | Customer data and geolocation |
| `sellers` | ~3k | Seller data |
| `products` | ~33k | Product catalog |
| `geolocation` | ~1M | ZIP code coordinates for Brazil |

---

## Data Pipeline in Detail

### 1. Ingestion — S3 → Snowflake RAW

- CSVs land in S3 as the immutable source of truth
- Snowflake **Storage Integration** connects to S3 via IAM Role (no credentials in SQL)
- `COPY INTO` loads data idempotently — re-runs are safe, no duplicates
- Metadata columns added at load time: `ingested_at`, `source_file`

```python
# Idempotent load — FORCE=FALSE skips already-loaded files
COPY INTO orders
FROM (SELECT $1,$2,...,$8, CURRENT_TIMESTAMP(), 'olist_orders_dataset.csv'
      FROM @RAW.s3_stage/olist_orders_dataset.csv)
FORCE = FALSE
ON_ERROR = CONTINUE
```

### 2. Transformation — dbt (3 layers)

```
RAW → STAGING → MARTS
```

**Staging**: type casting, snake_case renaming, null handling, deduplication
**Marts**: dimensional model — fact tables + dimension tables ready for BI

```sql
-- Example: stg_orders.sql
SELECT
    order_id,
    customer_id,
    order_status,
    order_purchase_timestamp::TIMESTAMP AS purchased_at,
    order_delivered_customer_date::TIMESTAMP AS delivered_at,
    ...
FROM {{ source('raw', 'orders') }}
WHERE order_id IS NOT NULL
QUALIFY ROW_NUMBER() OVER (PARTITION BY order_id ORDER BY ingested_at DESC) = 1
```

### 3. Data Quality — Great Expectations

- Validation suites per table at staging layer
- Critical expectations: no nulls on PKs, valid date ranges, referential integrity
- DAG fails explicitly if critical expectations are not met
- Data Docs auto-generated as pipeline artifact

### 4. Orchestration — Airflow

- Daily DAG with full backfill support
- Atomic tasks — each step is independently retriable
- Alerts on failure

---

## Business Metrics Delivered

| Metric | Description |
|---|---|
| **GMV diario/mensual** | Total revenue processed per day and month |
| **Delivery rate** | % of orders delivered successfully and on time |
| **Avg ticket** | Average order value by state and product category |
| **Seller score** | Average review score per seller |
| **Order cycle time** | Time from purchase to delivery |

---

## Project Structure

```
ecommerce-data-platform/
├── airflow/
│   ├── dags/              # End-to-end pipeline DAG
│   └── plugins/           # Custom operators
├── dbt/
│   ├── models/
│   │   ├── raw/           # Source definitions
│   │   ├── staging/       # stg_orders, stg_customers, ...
│   │   └── marts/         # fct_orders, dim_customers, ...
│   ├── tests/             # Custom dbt tests
│   └── macros/
├── great_expectations/
│   ├── expectations/      # Validation suites per table
│   └── checkpoints/       # Pipeline checkpoints
├── ingestion/
│   └── scripts/
│       ├── upload_to_s3.py          # Bootstrap: local CSVs → S3
│       ├── load_raw.py              # S3 → Snowflake via COPY INTO
│       ├── setup_snowflake.sql      # One-time Snowflake setup
│       └── setup_s3_integration.sql # External stage configuration
├── docker/
│   └── docker-compose.yml  # Airflow local environment
├── .env.example
├── Makefile
└── requirements.txt
```

---

## Getting Started

### Prerequisites

- Python 3.11+
- Docker + Docker Compose
- Snowflake account
- AWS account with S3 access

### Setup

```bash
# 1. Clone the repo
git clone https://github.com/EdwLearn/ecommerce-DataPlatform.git
cd ecommerce-DataPlatform

# 2. Configure environment
cp .env.example .env
# Fill in your Snowflake and AWS credentials

# 3. Set up Snowflake (run once)
# Execute ingestion/scripts/setup_snowflake.sql in Snowflake Worksheets
# Execute ingestion/scripts/setup_s3_integration.sql

# 4. Upload source data to S3
python ingestion/scripts/upload_to_s3.py

# 5. Load RAW layer
python ingestion/scripts/load_raw.py

# 6. Start Airflow
make airflow-up
```

### Makefile commands

```bash
make airflow-up       # Start Airflow with Docker Compose
make airflow-down     # Stop Airflow
make dbt-run          # Run all dbt models
make dbt-test         # Run dbt tests
make validate         # Run Great Expectations checkpoints
```

---

## Key Engineering Decisions

**Why S3 as landing zone instead of loading CSVs directly?**
S3 decouples ingestion from loading. Multiple consumers (Spark, Athena, other pipelines) can read the same raw files. It's also the production pattern — data arrives in S3, not on your laptop.

**Why Snowflake Storage Integration instead of access keys?**
IAM Role assumption with External ID is significantly more secure than storing AWS credentials in Snowflake. The trust is established at the AWS IAM level, not at the query level.

**Why dbt for transformations?**
SQL transformations need to be version-controlled, testable, and documented. dbt brings software engineering practices to SQL — lineage, tests, and docs out of the box.

---

## Author

**Edwin** — Data Engineer
[GitHub](https://github.com/EdwLearn) · [LinkedIn](https://linkedin.com/in/edwlearn)
