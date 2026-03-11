"""
Script de ingesta: S3 → Snowflake RAW schema.
Patrón: COPY INTO desde external stage S3 (sin PUT, sin internal stage).
Idempotente: FORCE=FALSE evita duplicados en re-runs.

Uso:
    python ingestion/scripts/load_raw.py
    python ingestion/scripts/load_raw.py --table orders
"""

import argparse
import sys
from dataclasses import dataclass
from pathlib import Path

from dotenv import load_dotenv
from loguru import logger
from snowflake_client import SnowflakeConfig, get_connection

load_dotenv()

S3_STAGE = "@ECOMMERCE_DB.RAW.s3_stage"

# Mapeo: tabla → (archivo CSV en S3, columnas de datos sin metadata)
TABLE_CONFIG: dict[str, tuple[str, int]] = {
    "orders":                            ("olist_orders_dataset.csv",              8),
    "order_items":                       ("olist_order_items_dataset.csv",         7),
    "order_payments":                    ("olist_order_payments_dataset.csv",      5),
    "order_reviews":                     ("olist_order_reviews_dataset.csv",       7),
    "customers":                         ("olist_customers_dataset.csv",           5),
    "sellers":                           ("olist_sellers_dataset.csv",             4),
    "products":                          ("olist_products_dataset.csv",            9),
    "product_category_name_translation": ("product_category_name_translation.csv", 2),
    "geolocation":                       ("olist_geolocation_dataset.csv",         5),
}


@dataclass
class LoadResult:
    table: str
    rows_loaded: int
    status: str


def create_raw_tables(conn) -> None:
    """Ejecuta el DDL de creación de tablas si no existen."""
    ddl_path = Path(__file__).parent / "create_raw_tables.sql"
    sql = ddl_path.read_text()

    with conn.cursor() as cur:
        cur.execute("USE DATABASE ECOMMERCE_DB")
        cur.execute("USE SCHEMA RAW")
        for statement in sql.split(";"):
            lines = [l for l in statement.splitlines() if not l.strip().startswith("--")]
            clean = "\n".join(lines).strip()
            if clean and not clean.upper().startswith("USE"):
                cur.execute(clean)

    logger.info("Tablas RAW verificadas / creadas")


def build_select_columns(n_cols: int, filename: str) -> str:
    """Construye la lista de columnas $1..$n + metadata para el COPY INTO."""
    cols = ", ".join(f"${i}" for i in range(1, n_cols + 1))
    return f"{cols}, CURRENT_TIMESTAMP(), '{filename}'"


def load_table(conn, table: str, filename: str, n_cols: int) -> LoadResult:
    """
    COPY INTO desde el external stage S3.
    No necesita PUT — los archivos ya están en S3 (subidos por upload_to_s3.py).
    """
    select_cols = build_select_columns(n_cols, filename)
    stage_path = f"{S3_STAGE}/{filename}"

    with conn.cursor() as cur:
        cur.execute("USE DATABASE ECOMMERCE_DB")
        cur.execute("USE SCHEMA RAW")

        logger.info(f"[{table}] COPY INTO desde s3 → {filename}")
        cur.execute(f"""
            COPY INTO {table}
            FROM (SELECT {select_cols} FROM '{stage_path}')
            FORCE = FALSE
            ON_ERROR = CONTINUE
        """)

        result = cur.fetchall()
        rows_loaded = sum(int(r[3]) for r in result) if result else 0
        status = "loaded" if rows_loaded > 0 else "skipped (already loaded)"
        logger.success(f"[{table}] {rows_loaded:,} filas — {status}")

    return LoadResult(table=table, rows_loaded=rows_loaded, status=status)


def load_all(tables: list[str] | None = None) -> list[LoadResult]:
    targets = {
        k: v for k, v in TABLE_CONFIG.items()
        if tables is None or k in tables
    }
    results: list[LoadResult] = []
    config = SnowflakeConfig.from_env()

    with get_connection(config) as conn:
        create_raw_tables(conn)

        for table, (filename, n_cols) in targets.items():
            try:
                results.append(load_table(conn, table, filename, n_cols))
            except Exception as e:
                logger.error(f"[{table}] {e}")
                results.append(LoadResult(table, 0, f"ERROR: {e}"))

    return results


def print_summary(results: list[LoadResult]) -> None:
    logger.info("\n=== Resumen de ingesta ===")
    total = 0
    errors = 0
    for r in results:
        is_err = r.status.startswith("ERROR")
        fn = logger.error if is_err else logger.success
        fn(f"  {r.table:<45} {r.rows_loaded:>10,} filas  [{r.status}]")
        total += r.rows_loaded
        errors += int(is_err)
    logger.info(f"\nTotal: {total:,} filas | {errors} errores")
    if errors:
        sys.exit(1)


def main() -> None:
    parser = argparse.ArgumentParser(description="Carga S3 → Snowflake RAW via external stage")
    parser.add_argument("--table", nargs="+", help="Tablas a cargar (default: todas)")
    args = parser.parse_args()

    logger.info("=== Ingesta S3 → Snowflake RAW ===")
    results = load_all(tables=args.table)
    print_summary(results)


if __name__ == "__main__":
    main()
