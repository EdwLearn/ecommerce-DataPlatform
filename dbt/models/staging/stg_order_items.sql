WITH source AS (
    SELECT * FROM {{ source('raw', 'order_items') }}
),

cleaned AS (
    SELECT
        order_id,
        order_item_id::INT                 AS order_item_id,
        product_id,
        seller_id,
        shipping_limit_date::TIMESTAMP_NTZ AS shipping_limit_at,
        price::FLOAT                       AS price,
        freight_value::FLOAT               AS freight_value,
        _loaded_at                         AS ingested_at,
        _source_file                       AS source_file
    FROM source
    WHERE order_id IS NOT NULL
      AND product_id IS NOT NULL
),

deduped AS (
    SELECT *
    FROM cleaned
    QUALIFY ROW_NUMBER() OVER (
        PARTITION BY order_id, order_item_id ORDER BY ingested_at DESC
    ) = 1
)

SELECT * FROM deduped
