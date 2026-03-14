WITH source AS (
    SELECT * FROM {{ source('raw', 'orders') }}
),

cleaned AS (
    SELECT
        order_id,
        customer_id,
        order_status,
        order_purchase_timestamp::TIMESTAMP_NTZ      AS purchased_at,
        order_approved_at::TIMESTAMP_NTZ             AS approved_at,
        order_delivered_carrier_date::TIMESTAMP_NTZ  AS shipped_at,
        order_delivered_customer_date::TIMESTAMP_NTZ AS delivered_at,
        order_estimated_delivery_date::TIMESTAMP_NTZ AS estimated_delivery_at,
        _loaded_at                                   AS ingested_at,
        _source_file                                 AS source_file
    FROM source
    WHERE order_id IS NOT NULL
),

deduped AS (
    SELECT *
    FROM cleaned
    QUALIFY ROW_NUMBER() OVER (PARTITION BY order_id ORDER BY ingested_at DESC) = 1
)

SELECT * FROM deduped
