"""
Script de validación de conexión y setup de Snowflake.
Ejecutar después de correr setup_snowflake.sql para verificar que todo está en orden.

Uso:
    python ingestion/scripts/validate_connection.py
"""

from loguru import logger
from snowflake_client import execute_query


EXPECTED_SCHEMAS = {"RAW", "STAGING", "MARTS"}


def check_connection() -> bool:
    logger.info("Verificando conexión a Snowflake...")
    rows = execute_query("SELECT CURRENT_VERSION() AS version, CURRENT_USER() AS user, CURRENT_ROLE() AS role")
    row = rows[0]
    logger.success(f"Conectado — versión={row['VERSION']} usuario={row['USER']} rol={row['ROLE']}")
    return True


def check_schemas() -> bool:
    logger.info("Verificando schemas...")
    rows = execute_query("SHOW SCHEMAS IN DATABASE ECOMMERCE_DB")
    existing = {row["name"].upper() for row in rows}

    missing = EXPECTED_SCHEMAS - existing
    if missing:
        logger.error(f"Schemas faltantes: {missing}")
        return False

    for schema in EXPECTED_SCHEMAS:
        logger.success(f"Schema OK: {schema}")
    return True


def check_warehouse() -> bool:
    logger.info("Verificando warehouse...")
    rows = execute_query("SHOW WAREHOUSES LIKE 'COMPUTE_WH'")
    if not rows:
        logger.error("Warehouse COMPUTE_WH no encontrado")
        return False
    logger.success("Warehouse COMPUTE_WH OK")
    return True


def main() -> None:
    logger.info("=== Validación de setup Snowflake ===")
    checks = [
        ("Conexión", check_connection),
        ("Warehouse", check_warehouse),
        ("Schemas", check_schemas),
    ]

    results = []
    for name, check_fn in checks:
        try:
            passed = check_fn()
        except Exception as e:
            logger.error(f"Error en check '{name}': {e}")
            passed = False
        results.append((name, passed))

    logger.info("\n=== Resultado ===")
    all_passed = True
    for name, passed in results:
        status = "PASS" if passed else "FAIL"
        log_fn = logger.success if passed else logger.error
        log_fn(f"[{status}] {name}")
        if not passed:
            all_passed = False

    if not all_passed:
        raise SystemExit(1)

    logger.success("Setup de Snowflake verificado correctamente.")


if __name__ == "__main__":
    main()
