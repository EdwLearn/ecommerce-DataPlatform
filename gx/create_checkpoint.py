"""
Crea el checkpoint que ejecuta todas las suites RAW y genera el reporte HTML.
Ejecutar: python3.10 gx/create_checkpoint.py
"""
import sys
sys.path = [p for p in sys.path if "ecommerce-data-platform" not in p]

from dotenv import load_dotenv
from great_expectations.data_context import DataContext
from great_expectations.core.batch import BatchRequest

load_dotenv()

context = DataContext(context_root_dir="gx")

checkpoint_config = {
    "name": "raw_validation_checkpoint",
    "config_version": 1,
    "class_name": "SimpleCheckpoint",
    "run_name_template": "%Y%m%d-%H%M%S-raw-validation",
    "validations": [
        {
            "batch_request": {
                "datasource_name": "snowflake_datasource",
                "data_connector_name": "default_inferred_data_connector",
                "data_asset_name": "raw.orders",
            },
            "expectation_suite_name": "orders_suite",
        },
        {
            "batch_request": {
                "datasource_name": "snowflake_datasource",
                "data_connector_name": "default_inferred_data_connector",
                "data_asset_name": "raw.order_items",
            },
            "expectation_suite_name": "order_items_suite",
        },
        {
            "batch_request": {
                "datasource_name": "snowflake_datasource",
                "data_connector_name": "default_inferred_data_connector",
                "data_asset_name": "raw.order_payments",
            },
            "expectation_suite_name": "order_payments_suite",
        },
        {
            "batch_request": {
                "datasource_name": "snowflake_datasource",
                "data_connector_name": "default_inferred_data_connector",
                "data_asset_name": "raw.order_reviews",
            },
            "expectation_suite_name": "order_reviews_suite",
        },
        {
            "batch_request": {
                "datasource_name": "snowflake_datasource",
                "data_connector_name": "default_inferred_data_connector",
                "data_asset_name": "raw.customers",
            },
            "expectation_suite_name": "customers_suite",
        },
    ],
}

context.add_or_update_checkpoint(**checkpoint_config)
print("✅ Checkpoint 'raw_validation_checkpoint' creado")
print("\nPara ejecutarlo:")
print("  python3.10 gx/run_checkpoint.py")
