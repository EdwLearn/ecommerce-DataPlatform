"""
Crea las Expectation Suites para las tablas RAW de Olist.
Ejecutar: python3.10 gx/create_suites.py
"""
import sys
sys.path = [p for p in sys.path if "ecommerce-data-platform" not in p]

import os
from dotenv import load_dotenv
from great_expectations.data_context import DataContext
from great_expectations.core.batch import BatchRequest

load_dotenv()

context = DataContext(context_root_dir="gx")


def get_batch_request(table: str) -> BatchRequest:
    return BatchRequest(
        datasource_name="snowflake_datasource",
        data_connector_name="default_inferred_data_connector",
        data_asset_name=f"raw.{table}",
    )


# ---------------------------------------------------------------------------
# 1. ORDERS
# ---------------------------------------------------------------------------
suite = context.add_or_update_expectation_suite("orders_suite")
validator = context.get_validator(
    batch_request=get_batch_request("orders"),
    expectation_suite_name="orders_suite",
)

validator.expect_column_values_to_not_be_null("order_id")
validator.expect_column_values_to_be_unique("order_id")
validator.expect_column_values_to_not_be_null("customer_id")
validator.expect_column_values_to_not_be_null("order_status")
validator.expect_column_values_to_be_in_set(
    "order_status",
    ["created", "approved", "invoiced", "processing",
     "shipped", "delivered", "unavailable", "canceled"],
)
validator.expect_column_values_to_not_be_null("order_purchase_timestamp")
validator.expect_table_row_count_to_be_between(min_value=90_000, max_value=120_000)

validator.save_expectation_suite(discard_failed_expectations=False)
print("✅ orders_suite creada")


# ---------------------------------------------------------------------------
# 2. ORDER_ITEMS
# ---------------------------------------------------------------------------
suite = context.add_or_update_expectation_suite("order_items_suite")
validator = context.get_validator(
    batch_request=get_batch_request("order_items"),
    expectation_suite_name="order_items_suite",
)

validator.expect_column_values_to_not_be_null("order_id")
validator.expect_column_values_to_not_be_null("product_id")
validator.expect_column_values_to_not_be_null("seller_id")
validator.expect_column_values_to_be_between("price", min_value=0.01)
validator.expect_column_values_to_be_between("freight_value", min_value=0)
validator.expect_table_row_count_to_be_between(min_value=100_000, max_value=130_000)

validator.save_expectation_suite(discard_failed_expectations=False)
print("✅ order_items_suite creada")


# ---------------------------------------------------------------------------
# 3. ORDER_PAYMENTS
# ---------------------------------------------------------------------------
suite = context.add_or_update_expectation_suite("order_payments_suite")
validator = context.get_validator(
    batch_request=get_batch_request("order_payments"),
    expectation_suite_name="order_payments_suite",
)

validator.expect_column_values_to_not_be_null("order_id")
validator.expect_column_values_to_not_be_null("payment_type")
validator.expect_column_values_to_be_in_set(
    "payment_type",
    ["credit_card", "boleto", "voucher", "debit_card", "not_defined"],
)
validator.expect_column_values_to_be_between("payment_value", min_value=0)
validator.expect_column_values_to_be_between(
    "payment_installments", min_value=0, max_value=24
)
validator.expect_table_row_count_to_be_between(min_value=95_000, max_value=120_000)

validator.save_expectation_suite(discard_failed_expectations=False)
print("✅ order_payments_suite creada")


# ---------------------------------------------------------------------------
# 4. ORDER_REVIEWS
# ---------------------------------------------------------------------------
suite = context.add_or_update_expectation_suite("order_reviews_suite")
validator = context.get_validator(
    batch_request=get_batch_request("order_reviews"),
    expectation_suite_name="order_reviews_suite",
)

validator.expect_column_values_to_not_be_null("review_id")
validator.expect_column_values_to_not_be_null("order_id")
validator.expect_column_values_to_be_between(
    "review_score", min_value=1, max_value=5
)
validator.expect_table_row_count_to_be_between(min_value=90_000, max_value=110_000)

validator.save_expectation_suite(discard_failed_expectations=False)
print("✅ order_reviews_suite creada")


# ---------------------------------------------------------------------------
# 5. CUSTOMERS
# ---------------------------------------------------------------------------
suite = context.add_or_update_expectation_suite("customers_suite")
validator = context.get_validator(
    batch_request=get_batch_request("customers"),
    expectation_suite_name="customers_suite",
)

validator.expect_column_values_to_not_be_null("customer_id")
validator.expect_column_values_to_be_unique("customer_id")
validator.expect_column_values_to_not_be_null("customer_state")
validator.expect_column_value_lengths_to_equal("customer_state", 2)
validator.expect_table_row_count_to_be_between(min_value=90_000, max_value=110_000)

validator.save_expectation_suite(discard_failed_expectations=False)
print("✅ customers_suite creada")


print("\n🎉 Todas las suites creadas en gx/expectations/")
