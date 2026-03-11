WITH source AS (
    SELECT * FROM {{ source('raw', 'sellers') }}
),

cleaned AS (
    SELECT
        seller_id,
        seller_zip_code_prefix,
        seller_city,
        seller_state,
        _loaded_at   AS ingested_at,
        _source_file AS source_file
    FROM source
    WHERE seller_id IS NOT NULL
),

deduped AS (
    SELECT *
    FROM cleaned
    QUALIFY ROW_NUMBER() OVER (PARTITION BY seller_id ORDER BY ingested_at DESC) = 1
)

SELECT * FROM deduped
