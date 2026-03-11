WITH orders AS (
    SELECT * FROM {{ ref('stg_orders') }}
),

order_items AS (
    SELECT
        order_id,
        COUNT(*)            AS items_count,
        SUM(price)          AS items_revenue,
        SUM(freight_value)  AS freight_total
    FROM {{ ref('stg_order_items') }}
    GROUP BY order_id
),

order_payments AS (
    SELECT
        order_id,
        SUM(payment_value)                                              AS total_paid,
        COUNT(DISTINCT payment_type)                                    AS payment_methods_count,
        LISTAGG(DISTINCT payment_type, ', ') WITHIN GROUP (ORDER BY payment_type) AS payment_types
    FROM {{ ref('stg_order_payments') }}
    GROUP BY order_id
),

order_reviews AS (
    SELECT
        order_id,
        review_score,
        review_comment_message
    FROM {{ ref('stg_order_reviews') }}
    QUALIFY ROW_NUMBER() OVER (PARTITION BY order_id ORDER BY review_created_at DESC) = 1
)

SELECT
    o.order_id,
    o.customer_id,
    o.order_status,

    -- Timestamps
    o.purchased_at,
    o.approved_at,
    o.shipped_at,
    o.delivered_at,
    o.estimated_delivery_at,

    -- Ciclo de orden (días)
    DATEDIFF('day', o.purchased_at, o.delivered_at)          AS days_to_deliver,
    DATEDIFF('day', o.estimated_delivery_at, o.delivered_at) AS days_vs_estimate,

    -- Financiero
    COALESCE(i.items_count, 0)      AS items_count,
    COALESCE(i.items_revenue, 0)    AS items_revenue,
    COALESCE(i.freight_total, 0)    AS freight_total,
    COALESCE(p.total_paid, 0)       AS total_paid,

    -- Pago
    p.payment_methods_count,
    p.payment_types,

    -- Review
    r.review_score,
    r.review_comment_message,

    -- Flags de negocio
    CASE WHEN o.order_status = 'delivered' THEN TRUE ELSE FALSE END                               AS is_delivered,
    CASE WHEN o.delivered_at <= o.estimated_delivery_at THEN TRUE ELSE FALSE END                  AS is_on_time,
    DATE_TRUNC('day', o.purchased_at)                                                             AS order_date,
    DATE_TRUNC('month', o.purchased_at)                                                           AS order_month

FROM orders o
LEFT JOIN order_items i    ON o.order_id = i.order_id
LEFT JOIN order_payments p ON o.order_id = p.order_id
LEFT JOIN order_reviews r  ON o.order_id = r.order_id
