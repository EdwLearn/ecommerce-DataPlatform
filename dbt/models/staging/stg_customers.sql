WITH source AS (
    SELECT * FROM {{ source('raw', 'customers') }}
),

cleaned AS (
    SELECT
        customer_id,
        customer_unique_id,
        customer_zip_code_prefix,
        customer_city,
        customer_state,
        _loaded_at   AS ingested_at,
        _source_file AS source_file
    FROM source
    WHERE customer_id IS NOT NULL
),

deduped AS (
    SELECT *
    FROM cleaned
    QUALIFY ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY ingested_at DESC) = 1
)

SELECT * FROM deduped
