WITH source AS (
    SELECT * FROM {{ source('raw', 'products') }}
),

translations AS (
    SELECT * FROM {{ source('raw', 'product_category_name_translation') }}
),

cleaned AS (
    SELECT
        p.product_id,
        p.product_category_name,
        COALESCE(t.product_category_name_english, p.product_category_name) AS product_category_name_en,
        p.product_name_lenght::INT        AS product_name_length,
        p.product_description_lenght::INT AS product_description_length,
        p.product_photos_qty::INT         AS product_photos_qty,
        p.product_weight_g::FLOAT         AS product_weight_g,
        p.product_length_cm::FLOAT        AS product_length_cm,
        p.product_height_cm::FLOAT        AS product_height_cm,
        p.product_width_cm::FLOAT         AS product_width_cm,
        p._loaded_at                      AS ingested_at,
        p._source_file                    AS source_file
    FROM source p
    LEFT JOIN translations t
        ON p.product_category_name = t.product_category_name
    WHERE p.product_id IS NOT NULL
),

deduped AS (
    SELECT *
    FROM cleaned
    QUALIFY ROW_NUMBER() OVER (PARTITION BY product_id ORDER BY ingested_at DESC) = 1
)

SELECT * FROM deduped
