# Ecommerce Data Platform — CLAUDE.md

## Proyecto

Plataforma de datos end-to-end para un e-commerce latinoamericano usando el dataset real **Olist Brasil** (100k órdenes). Ingesta raw desde S3, transforma con dbt en 3 capas, orquesta con Airflow, valida con Great Expectations, y expone métricas de negocio listas para BI.

---

## North Star Metric

> **GMV (Gross Merchandise Value) procesado por día con tasa de entrega exitosa ≥ 95%**

---

## Stack tecnológico

| Componente | Tecnología |
|---|---|
| Lenguaje | Python 3.11 |
| Orquestación | Apache Airflow 2.8 |
| Transformación | dbt-core + dbt-snowflake |
| Data Warehouse | Snowflake |
| Cloud Storage | AWS S3 |
| Calidad de datos | Great Expectations |
| Contenerización | Docker + Docker Compose |
| Formato de config | YAML + .env |

---

## Arquitectura

```
S3 (raw CSVs)
    └── Airflow DAG (diario)
            ├── Great Expectations — validar raw
            ├── Snowflake COPY INTO — raw schema
            ├── dbt run — staging
            ├── dbt run — marts
            └── dbt test + GE — validar marts
```

### Capas de datos en Snowflake

| Schema | Propósito |
|---|---|
| `RAW` | Tablas 1:1 con los CSVs originales, sin transformar |
| `STAGING` | Limpieza, tipado, renaming, deduplicación |
| `MARTS` | Modelos de negocio listos para BI (facts + dims) |

---

## Dataset Olist

| Tabla fuente | Filas aprox | Descripción |
|---|---|---|
| `orders` | 100k | Orden principal con status y timestamps |
| `order_items` | 112k | Ítems por orden (producto, seller, precio) |
| `order_payments` | 103k | Métodos y valores de pago |
| `order_reviews` | 99k | Reseñas y scores de clientes |
| `customers` | 99k | Datos de clientes y geolocalización |
| `sellers` | 3k | Datos de vendedores |
| `products` | 33k | Catálogo de productos |
| `product_category_name_translation` | 71 | Traducción categorías PT→EN |
| `geolocation` | 1M | Coordenadas por zip code BR |

---

## Objetivos

### O1 — Ingesta confiable
- Pipeline idempotente: re-runs seguros sin duplicados
- COPY INTO desde S3 a Snowflake schema RAW
- Metadata de ingesta: timestamp, rows cargadas, archivo fuente

### O2 — Transformación dbt en 3 capas
- **Raw**: materialización como tablas, sin lógica
- **Staging**: limpieza, tipado correcto, snake_case, dedup
- **Marts**: modelos dimensionales (fct_orders, dim_customers, dim_sellers, etc.)

### O3 — Calidad de datos con Great Expectations
- Validaciones en staging: nulls, rangos, referential integrity
- Data Docs publicados como artefacto del pipeline
- El DAG falla explícitamente si expectativas críticas no se cumplen

### O4 — Orquestación con Airflow
- DAG end-to-end: ingest → validate → transform → test
- Schedule diario con soporte a backfill histórico
- Alertas configuradas en caso de fallo

### O5 — Métricas de negocio
- GMV diario y mensual
- Tasa de entrega exitosa (on-time delivery rate)
- Ticket promedio por estado / categoría de producto
- Score promedio de reviews por seller
- Tiempo de ciclo de orden (purchase → delivery)

### O6 — Infraestructura reproducible
- Docker Compose para Airflow local
- Makefile con comandos del proyecto
- `.env.example` documentado con todas las variables

---

## Estructura de carpetas

```
ecommerce-data-platform/
├── airflow/
│   ├── dags/                  # DAGs de Airflow
│   └── plugins/               # Operadores y hooks custom
├── dbt/
│   ├── models/
│   │   ├── raw/               # Capa raw (1:1 con fuentes)
│   │   ├── staging/           # Capa staging (limpieza)
│   │   └── marts/             # Capa marts (negocio)
│   ├── tests/                 # Tests dbt custom
│   ├── macros/                # Macros reutilizables
│   └── dbt_project.yml
├── great_expectations/
│   ├── expectations/          # Suites de expectativas por tabla
│   └── checkpoints/           # Checkpoints del pipeline
├── ingestion/
│   └── scripts/               # Scripts de carga S3 → Snowflake
├── docker/
│   └── docker-compose.yml
├── .env.example
├── Makefile
├── requirements.txt
└── CLAUDE.md
```

---

## Convenciones de código

- Python: snake_case, type hints, no lógica en scripts de ingesta que no sea copiar datos
- dbt: prefijos `stg_`, `fct_`, `dim_` en modelos; fuentes definidas en `sources.yml`
- SQL: uppercase para keywords, lowercase para columnas y tablas
- Airflow: un DAG por dominio, tasks atómicas, sin lógica de negocio en DAGs
- Git: commits en inglés, convención `feat:`, `fix:`, `chore:`

---

## Variables de entorno requeridas

```
# Snowflake
SNOWFLAKE_ACCOUNT=
SNOWFLAKE_USER=
SNOWFLAKE_PASSWORD=
SNOWFLAKE_DATABASE=
SNOWFLAKE_WAREHOUSE=
SNOWFLAKE_ROLE=

# AWS
AWS_ACCESS_KEY_ID=
AWS_SECRET_ACCESS_KEY=
AWS_REGION=
S3_BUCKET=

# Airflow
AIRFLOW__CORE__FERNET_KEY=
AIRFLOW__CORE__EXECUTOR=LocalExecutor
```

---

## Orden de implementación

1. Estructura de carpetas + Docker Compose (Airflow)
2. Conexión Snowflake + schemas RAW/STAGING/MARTS
3. Scripts de ingesta S3 → Snowflake (raw layer)
4. Proyecto dbt: sources → staging → marts
5. Great Expectations: suites + checkpoints
6. DAG Airflow end-to-end
7. Makefile + documentación

---

## LinkedIn Content

Cada vez que se resuelva un reto interesante durante el proyecto, generar contenido para LinkedIn siguiendo este proceso:

### Criterios para identificar un reto interesante
- Un problema técnico no obvio que requirió investigación o razonamiento
- Una decisión de arquitectura con trade-offs reales
- Un concepto de Data Engineering que vale la pena explicar con contexto práctico
- Un bug o comportamiento inesperado con una lección aprendida

### Proceso de creación de contenido

**1. Entendimiento — ¿Qué pasó?**
- Describir el contexto del problema
- Explicar por qué era un reto (qué lo hacía difícil o no obvio)
- Qué se intentó antes de encontrar la solución

**2. Creación — ¿Cuál es la historia?**
- Conectar el reto técnico con un concepto de valor para la audiencia DE/analytics
- Estructurar como: problema → insight → solución → aprendizaje
- Incluir código, diagrama o ejemplo concreto cuando aporte valor

**3. Redacción — Post LinkedIn**
- Gancho en la primera línea (sin "Hoy aprendí" genérico)
- Máximo 1200 caracteres o formato carrusel si el tema lo merece
- Hashtags al final: #DataEngineering #Python #dbt #Snowflake #Airflow (según aplique)
- Tono: técnico pero accesible, primera persona, honesto sobre errores

### Formato de entrega
Cuando se identifique un reto, entregar:
```
## LinkedIn Post — [título del reto]

**Contexto:** ...
**El reto:** ...
**La solución:** ...

---
[POST REDACTADO LISTO PARA COPIAR]
---

Hashtags: #...
```
