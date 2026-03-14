WITH source AS (
    SELECT * FROM {{ source('raw', 'order_reviews') }}
),

cleaned AS (
    SELECT
        review_id,
        order_id,
        review_score::INT                        AS review_score,
        review_comment_title,
        review_comment_message,
        review_creation_date::TIMESTAMP_NTZ      AS review_created_at,
        review_answer_timestamp::TIMESTAMP_NTZ   AS review_answered_at,
        _loaded_at                               AS ingested_at,
        _source_file                             AS source_file
    FROM source
    WHERE review_id IS NOT NULL
      AND order_id IS NOT NULL
),

deduped AS (
    SELECT *
    FROM cleaned
    QUALIFY ROW_NUMBER() OVER (PARTITION BY review_id ORDER BY ingested_at DESC) = 1
)

SELECT * FROM deduped
