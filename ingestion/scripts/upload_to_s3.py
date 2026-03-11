"""
Script de upload: CSVs locales → S3 bucket (landing zone).

Uso:
    python ingestion/scripts/upload_to_s3.py
    python ingestion/scripts/upload_to_s3.py --table orders
    python ingestion/scripts/upload_to_s3.py --dry-run
"""

import argparse
import os
from pathlib import Path

import boto3
from dotenv import load_dotenv
from loguru import logger

load_dotenv()

DATA_DIR = Path(__file__).parents[2] / "data" / "raw"

S3_BUCKET = os.environ["S3_BUCKET"]
S3_PREFIX = os.environ.get("S3_PREFIX", "raw/olist/")

TABLE_FILES: dict[str, str] = {
    "orders":                            "olist_orders_dataset.csv",
    "order_items":                       "olist_order_items_dataset.csv",
    "order_payments":                    "olist_order_payments_dataset.csv",
    "order_reviews":                     "olist_order_reviews_dataset.csv",
    "customers":                         "olist_customers_dataset.csv",
    "sellers":                           "olist_sellers_dataset.csv",
    "products":                          "olist_products_dataset.csv",
    "product_category_name_translation": "product_category_name_translation.csv",
    "geolocation":                       "olist_geolocation_dataset.csv",
}


def get_s3_client():
    return boto3.client(
        "s3",
        aws_access_key_id=os.environ["AWS_ACCESS_KEY_ID"],
        aws_secret_access_key=os.environ["AWS_SECRET_ACCESS_KEY"],
        region_name=os.environ.get("AWS_REGION", "us-east-1"),
    )


def upload_file(s3, local_path: Path, s3_key: str, dry_run: bool) -> bool:
    size_mb = local_path.stat().st_size / 1_048_576
    if dry_run:
        logger.info(f"[dry-run] {local_path.name} → s3://{S3_BUCKET}/{s3_key} ({size_mb:.1f} MB)")
        return True

    logger.info(f"Subiendo {local_path.name} ({size_mb:.1f} MB) → s3://{S3_BUCKET}/{s3_key}")
    s3.upload_file(str(local_path), S3_BUCKET, s3_key)
    logger.success(f"OK — s3://{S3_BUCKET}/{s3_key}")
    return True


def upload_all(tables: list[str] | None = None, dry_run: bool = False) -> dict[str, bool]:
    targets = {
        k: v for k, v in TABLE_FILES.items()
        if tables is None or k in tables
    }

    s3 = get_s3_client()
    results: dict[str, bool] = {}

    for table, filename in targets.items():
        local_path = DATA_DIR / filename
        if not local_path.exists():
            logger.error(f"[{table}] Archivo no encontrado: {local_path}")
            results[table] = False
            continue

        s3_key = f"{S3_PREFIX}{filename}"
        try:
            results[table] = upload_file(s3, local_path, s3_key, dry_run)
        except Exception as e:
            logger.error(f"[{table}] Error al subir: {e}")
            results[table] = False

    return results


def main() -> None:
    parser = argparse.ArgumentParser(description="Sube CSVs de Olist a S3")
    parser.add_argument("--table", nargs="+", help="Tablas a subir (default: todas)")
    parser.add_argument("--dry-run", action="store_true", help="Simula sin subir nada")
    args = parser.parse_args()

    logger.info(f"=== Upload Olist → s3://{S3_BUCKET}/{S3_PREFIX} ===")
    if args.dry_run:
        logger.warning("Modo dry-run activado — no se subirá nada")

    results = upload_all(tables=args.table, dry_run=args.dry_run)

    ok = sum(v for v in results.values())
    errors = len(results) - ok
    logger.info(f"\nTotal: {ok} OK | {errors} errores")

    if errors:
        raise SystemExit(1)


if __name__ == "__main__":
    main()
