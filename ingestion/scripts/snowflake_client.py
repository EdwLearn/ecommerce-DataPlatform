"""
Módulo de conexión a Snowflake.
Usado por scripts de ingesta, validaciones y el DAG de Airflow.
"""

import os
from contextlib import contextmanager
from dataclasses import dataclass

import snowflake.connector
from dotenv import load_dotenv
from loguru import logger
from snowflake.connector import DictCursor, SnowflakeConnection

load_dotenv()


@dataclass
class SnowflakeConfig:
    account: str
    user: str
    password: str
    database: str
    warehouse: str
    role: str
    schema: str = "RAW"

    @classmethod
    def from_env(cls) -> "SnowflakeConfig":
        required = [
            "SNOWFLAKE_ACCOUNT",
            "SNOWFLAKE_USER",
            "SNOWFLAKE_PASSWORD",
            "SNOWFLAKE_DATABASE",
            "SNOWFLAKE_WAREHOUSE",
            "SNOWFLAKE_ROLE",
        ]
        missing = [var for var in required if not os.getenv(var)]
        if missing:
            raise EnvironmentError(f"Variables de entorno faltantes: {missing}")

        return cls(
            account=os.environ["SNOWFLAKE_ACCOUNT"],
            user=os.environ["SNOWFLAKE_USER"],
            password=os.environ["SNOWFLAKE_PASSWORD"],
            database=os.environ["SNOWFLAKE_DATABASE"],
            warehouse=os.environ["SNOWFLAKE_WAREHOUSE"],
            role=os.environ["SNOWFLAKE_ROLE"],
        )


@contextmanager
def get_connection(config: SnowflakeConfig | None = None) -> SnowflakeConnection:
    """
    Context manager que abre y cierra la conexión a Snowflake.

    Uso:
        with get_connection() as conn:
            cursor = conn.cursor()
            cursor.execute("SELECT CURRENT_VERSION()")
    """
    cfg = config or SnowflakeConfig.from_env()

    logger.info(f"Conectando a Snowflake — account={cfg.account} db={cfg.database}")
    conn = snowflake.connector.connect(
        account=cfg.account,
        user=cfg.user,
        password=cfg.password,
        database=cfg.database,
        warehouse=cfg.warehouse,
        role=cfg.role,
        schema=cfg.schema,
        session_parameters={"QUERY_TAG": "ecommerce-data-platform"},
    )
    try:
        yield conn
        logger.info("Conexión Snowflake cerrada correctamente")
    except Exception:
        logger.exception("Error durante la sesión de Snowflake")
        raise
    finally:
        conn.close()


def execute_query(sql: str, config: SnowflakeConfig | None = None) -> list[dict]:
    """Ejecuta una query y retorna los resultados como lista de dicts."""
    with get_connection(config) as conn:
        with conn.cursor(DictCursor) as cur:
            cur.execute(sql)
            return cur.fetchall()


def execute_statement(sql: str, config: SnowflakeConfig | None = None) -> None:
    """Ejecuta un statement DDL/DML sin retornar resultados."""
    with get_connection(config) as conn:
        with conn.cursor() as cur:
            cur.execute(sql)
            logger.info(f"Statement ejecutado: {sql[:80]}...")
