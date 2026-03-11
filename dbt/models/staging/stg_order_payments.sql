WITH source AS (
    SELECT * FROM {{ source('raw', 'order_payments') }}
),

cleaned AS (
    SELECT
        order_id,
        payment_sequential::INT   AS payment_sequential,
        payment_type,
        payment_installments::INT AS payment_installments,
        payment_value::FLOAT      AS payment_value,
        _loaded_at                AS ingested_at,
        _source_file              AS source_file
    FROM source
    WHERE order_id IS NOT NULL
),

deduped AS (
    SELECT *
    FROM cleaned
    QUALIFY ROW_NUMBER() OVER (
        PARTITION BY order_id, payment_sequential ORDER BY ingested_at DESC
    ) = 1
)

SELECT * FROM deduped
