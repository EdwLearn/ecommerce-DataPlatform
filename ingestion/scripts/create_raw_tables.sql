-- =============================================================================
-- Ecommerce Data Platform — DDL capa RAW
-- Tablas 1:1 con los CSVs de Olist. Todo VARCHAR, sin transformaciones.
-- Ejecutar antes del primer load.
-- =============================================================================

USE DATABASE ECOMMERCE_DB;
USE SCHEMA RAW;

-- -----------------------------------------------------------------------------
-- orders
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS orders (
    order_id                        VARCHAR,
    customer_id                     VARCHAR,
    order_status                    VARCHAR,
    order_purchase_timestamp        VARCHAR,
    order_approved_at               VARCHAR,
    order_delivered_carrier_date    VARCHAR,
    order_delivered_customer_date   VARCHAR,
    order_estimated_delivery_date   VARCHAR,
    -- metadata de ingesta
    _loaded_at                      TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    _source_file                    VARCHAR
);

-- -----------------------------------------------------------------------------
-- order_items
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS order_items (
    order_id                VARCHAR,
    order_item_id           VARCHAR,
    product_id              VARCHAR,
    seller_id               VARCHAR,
    shipping_limit_date     VARCHAR,
    price                   VARCHAR,
    freight_value           VARCHAR,
    _loaded_at              TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    _source_file            VARCHAR
);

-- -----------------------------------------------------------------------------
-- order_payments
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS order_payments (
    order_id                VARCHAR,
    payment_sequential      VARCHAR,
    payment_type            VARCHAR,
    payment_installments    VARCHAR,
    payment_value           VARCHAR,
    _loaded_at              TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    _source_file            VARCHAR
);

-- -----------------------------------------------------------------------------
-- order_reviews
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS order_reviews (
    review_id               VARCHAR,
    order_id                VARCHAR,
    review_score            VARCHAR,
    review_comment_title    VARCHAR,
    review_comment_message  VARCHAR,
    review_creation_date    VARCHAR,
    review_answer_timestamp VARCHAR,
    _loaded_at              TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    _source_file            VARCHAR
);

-- -----------------------------------------------------------------------------
-- customers
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS customers (
    customer_id             VARCHAR,
    customer_unique_id      VARCHAR,
    customer_zip_code_prefix VARCHAR,
    customer_city           VARCHAR,
    customer_state          VARCHAR,
    _loaded_at              TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    _source_file            VARCHAR
);

-- -----------------------------------------------------------------------------
-- sellers
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS sellers (
    seller_id               VARCHAR,
    seller_zip_code_prefix  VARCHAR,
    seller_city             VARCHAR,
    seller_state            VARCHAR,
    _loaded_at              TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    _source_file            VARCHAR
);

-- -----------------------------------------------------------------------------
-- products
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS products (
    product_id                      VARCHAR,
    product_category_name           VARCHAR,
    product_name_lenght             VARCHAR,
    product_description_lenght      VARCHAR,
    product_photos_qty              VARCHAR,
    product_weight_g                VARCHAR,
    product_length_cm               VARCHAR,
    product_height_cm               VARCHAR,
    product_width_cm                VARCHAR,
    _loaded_at                      TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    _source_file                    VARCHAR
);

-- -----------------------------------------------------------------------------
-- product_category_name_translation
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS product_category_name_translation (
    product_category_name           VARCHAR,
    product_category_name_english   VARCHAR,
    _loaded_at                      TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    _source_file                    VARCHAR
);

-- -----------------------------------------------------------------------------
-- geolocation
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS geolocation (
    geolocation_zip_code_prefix     VARCHAR,
    geolocation_lat                 VARCHAR,
    geolocation_lng                 VARCHAR,
    geolocation_city                VARCHAR,
    geolocation_state               VARCHAR,
    _loaded_at                      TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    _source_file                    VARCHAR
);
