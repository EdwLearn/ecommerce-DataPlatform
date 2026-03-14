WITH sellers AS (
    SELECT * FROM {{ ref('stg_sellers') }}
),

seller_metrics AS (
    SELECT
        oi.seller_id,
        COUNT(DISTINCT oi.order_id)  AS total_orders,
        SUM(oi.price)                AS total_revenue,
        AVG(r.review_score)          AS avg_review_score
    FROM {{ ref('stg_order_items') }} oi
    LEFT JOIN {{ ref('stg_orders') }} o
        ON oi.order_id = o.order_id
    LEFT JOIN {{ ref('stg_order_reviews') }} r
        ON oi.order_id = r.order_id
    GROUP BY oi.seller_id
)

SELECT
    s.seller_id,
    s.seller_zip_code_prefix,
    s.seller_city,
    s.seller_state,
    COALESCE(m.total_orders, 0)      AS total_orders,
    COALESCE(m.total_revenue, 0)     AS total_revenue,
    ROUND(m.avg_review_score, 2)     AS avg_review_score
FROM sellers s
LEFT JOIN seller_metrics m ON s.seller_id = m.seller_id
