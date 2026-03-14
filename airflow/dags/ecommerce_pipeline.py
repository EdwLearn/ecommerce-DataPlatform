"""
DAG: ecommerce_pipeline
Pipeline end-to-end diario: S3 → Snowflake RAW → GE → dbt → dbt test
"""
from datetime import datetime, timedelta
from airflow import DAG
from airflow.operators.bash import BashOperator
from airflow.operators.python import PythonOperator
from airflow.utils.dates import days_ago

# ---------------------------------------------------------------------------
# Configuración base
# ---------------------------------------------------------------------------
DBT_DIR = "/opt/airflow/dbt"
GX_DIR = "/opt/airflow/gx"
INGESTION_DIR = "/opt/airflow/ingestion/scripts"

default_args = {
    "owner": "data-engineering",
    "retries": 1,
    "retry_delay": timedelta(minutes=5),
    "email_on_failure": False,
}

# ---------------------------------------------------------------------------
# DAG
# ---------------------------------------------------------------------------
with DAG(
    dag_id="ecommerce_pipeline",
    description="Pipeline diario: S3 → RAW → GE → dbt staging → dbt marts → tests",
    default_args=default_args,
    schedule_interval="0 6 * * *",  # 6am diario
    start_date=days_ago(1),
    catchup=False,
    tags=["ecommerce", "olist", "snowflake", "dbt"],
) as dag:

    # -----------------------------------------------------------------------
    # Task 1: COPY INTO — carga CSVs desde S3 a Snowflake RAW
    # -----------------------------------------------------------------------
    copy_into_snowflake = BashOperator(
        task_id="copy_into_snowflake",
        bash_command=f"python {INGESTION_DIR}/load_raw.py",
    )

    # -----------------------------------------------------------------------
    # Task 2: Great Expectations — valida tablas RAW
    # -----------------------------------------------------------------------
    def run_ge_checkpoint():
        import sys
        sys.path = [p for p in sys.path if "ecommerce-data-platform" not in p]
        from great_expectations.data_context import DataContext

        context = DataContext(context_root_dir=GX_DIR)
        result = context.run_checkpoint(checkpoint_name="raw_validation_checkpoint")
        context.build_data_docs()

        if not result["success"]:
            stats = result.run_results
            failed = [
                r["validation_result"]["meta"]["expectation_suite_name"]
                for r in stats.values()
                if not r["validation_result"]["success"]
            ]
            raise ValueError(f"GE validation failed for suites: {failed}")

    validate_raw = PythonOperator(
        task_id="validate_raw",
        python_callable=run_ge_checkpoint,
    )

    # -----------------------------------------------------------------------
    # Task 3: dbt run — staging + marts
    # -----------------------------------------------------------------------
    dbt_run = BashOperator(
        task_id="dbt_run",
        bash_command=f"cd {DBT_DIR} && dbt run --profiles-dir {DBT_DIR}",
    )

    # -----------------------------------------------------------------------
    # Task 4: dbt test — valida modelos transformados
    # -----------------------------------------------------------------------
    dbt_test = BashOperator(
        task_id="dbt_test",
        bash_command=f"cd {DBT_DIR} && dbt test --profiles-dir {DBT_DIR}",
    )

    # -----------------------------------------------------------------------
    # Dependencias
    # -----------------------------------------------------------------------
    copy_into_snowflake >> validate_raw >> dbt_run >> dbt_test
