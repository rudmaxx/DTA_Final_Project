1.1
SELECT o.order_year,
       c.region,
       SUM(o.net_amount) AS total_revenue,
       COUNT(o.order_id) As total_orders,
       ROUND(AVG(o.net_amount),3) AS average_order
FROM orders o
JOIN customers c USING (customer_id)
GROUP BY o.order_year, c.region 
ORDER BY c.region, o.order_year;

1.2
SELECT c.customer_id,
       c.region,
       c.acquisition_chan,
       COUNT(o.order_id) As total_orders,
       SUM(o.net_amount) AS total_spent
FROM customers c
JOIN orders o USING (customer_id)
GROUP BY c.customer_id, c.region, c.acquisition_chan
ORDER BY total_spent DESC
LIMIT 10;

1.3
SELECT p.category, 
       ROUND(SUM(oi.line_total),2) AS total_revenue,
       AVG(p.margin_pct) as average_margin,
       ROUND(COUNT(DISTINCT CASE 
             WHEN o.is_returned = 1 
             THEN o.order_id
             END) * 100.0 / COUNT(DISTINCT o.order_id),2) AS return_rate
FROM orders o
JOIN order_items oi USING (order_id)
JOIN products p USING (product_id)
GROUP BY p.category;

1.4
SELECT COUNT(customer_id) AS customer_count,
       ROUND(
          SUM(total_spent) * 100.0 /
          (SELECT SUM(net_amount) 
           FROM orders),2
       ) AS revenue_share_pct
FROM (
    SELECT customer_id,
           ROUND(SUM(net_amount), 2) AS total_spent
    FROM orders
    GROUP BY customer_id
    ) AS customer_spent
WHERE total_spent > (
    SELECT AVG(total_spent)
    FROM (
        SELECT customer_id,
               ROUND(SUM(net_amount), 2) AS total_spent
        FROM orders
        GROUP BY customer_id
    ) AS all_customer_spent
);

1.5
SELECT channel,
       SUM(budget) AS total_budget,
       SUM(attributed_reven) AS total_revenue,
       ROUND(SUM(attributed_reven) * 1.0 / SUM(budget), 2) AS roi
FROM marketing
GROUP BY channel
ORDER by roi DESC;

2.1
SELECT strftime('%Y-%m', order_date) AS year_month,
       SUM(net_amount) AS total_revenue
FROM orders
GROUP BY strftime('%Y-%m', order_date)
ORDER BY strftime('%Y-%m', order_date);

2.5
SELECT CASE
           WHEN customer_group = 1 THEN 'Top 5%'
           ELSE 'Rest'
       END AS customer_segment,
       SUM(total_spent) AS segment_revenue,
       ROUND(
           SUM(total_spent) / SUM(SUM(total_spent)) OVER (),4
       ) AS segment_pct
FROM(SELECT customer_id,
            SUM(net_amount) AS total_spent,
            NTILE(20) OVER (order BY SUM(net_amount) DESC) AS customer_group
	 FROM orders
	 GROUP BY customer_id
	) AS t
GROUP BY customer_segment
ORDER BY segment_revenue 
_____________________________________________________________________________
Task p
WITH customer_groups AS (
    SELECT customer_group,
           SUM(total_spent) AS group_revenue
    FROM (
        SELECT customer_id,
               SUM(net_amount) AS total_spent,
               NTILE(20) OVER (
                   ORDER BY SUM(net_amount) DESC
               ) AS customer_group
        FROM orders
        GROUP BY customer_id
    ) AS t
    GROUP BY customer_group
)

SELECT customer_group,
       group_revenue,
       SUM(group_revenue) OVER (
           ORDER BY customer_group
       ) AS cumulative_revenue,
       ROUND(
           SUM(group_revenue) OVER (
               ORDER BY customer_group
           ) * 100.0
           / SUM(group_revenue) OVER (),
           2
       ) AS cumulative_pct
FROM customer_groups
ORDER BY customer_group;

2.6
SELECT acquisition_chan,
       COUNT(customer_id) AS customers,
       SUM(total_spent) AS total_revenue,
       ROUND(AVG(total_spent), 2) AS avg_revenue_per_customer
FROM (
    SELECT c.acquisition_chan,
           c.customer_id,
           SUM(o.net_amount) AS total_spent
    FROM customers c
    JOIN orders o USING (customer_id)
    GROUP BY c.acquisition_chan,
             c.customer_id
) AS t
GROUP BY acquisition_chan
ORDER BY avg_revenue_per_customer DESC;

3.1
SELECT
    SUM(net_amount) AS total_revenue,
    COUNT(order_id) AS total_orders,
    ROUND(AVG(net_amount), 2) AS avg_order_value,
    ROUND(
        COUNT(CASE WHEN is_returned = 1 THEN 1 END) * 100.0
        / COUNT(order_id),
        2
    ) AS return_rate
FROM orders;

8
WITH customer_stats AS (
    SELECT customer_id,
           AVG(discount_pct) AS avg_discount,
           COUNT(order_id) AS total_orders
    FROM orders
    GROUP BY customer_id
)

SELECT
    CASE
        WHEN avg_discount > 20 THEN 'Discount Buyers'
        ELSE 'Regular Buyers'
    END AS customer_group,
    COUNT(customer_id) AS customers,
    ROUND(AVG(total_orders),2) AS avg_orders_per_customer
FROM customer_stats
GROUP BY customer_group;

9
WITH customer_spending AS (
    SELECT
        c.customer_id,
        c.region,
        c.acquisition_chan,
        SUM(o.net_amount) AS total_spent,
        NTILE(20) OVER (
            ORDER BY SUM(o.net_amount) DESC
        ) AS customer_group
    FROM customers c
    JOIN orders o USING (customer_id)
    GROUP BY
        c.customer_id,
        c.region,
        c.acquisition_chan
)

SELECT
    region,
    acquisition_chan,
    COUNT(customer_id) AS top_customers,
    ROUND(SUM(total_spent), 2) AS top_customer_revenue,
    ROUND(AVG(total_spent), 2) AS avg_spent_per_customer
FROM customer_spending
WHERE customer_group = 1
GROUP BY
    region,
    acquisition_chan
ORDER BY
    top_customers DESC,
    top_customer_revenue DESC;

10
SELECT
    ab_variant,
    COUNT(*) AS total_orders,
    ROUND(AVG(net_amount), 2) AS avg_order_value
FROM orders
WHERE ab_variant IN ('A', 'B')
GROUP BY ab_variant
ORDER BY ab_variant;

11
WITH first_order AS (
    SELECT
        customer_id,
        MIN(order_date) AS first_order_date
    FROM orders
    GROUP BY customer_id
)

SELECT
    o.ab_variant,
    CASE
        WHEN julianday(f.first_order_date) - julianday(c.signup_date) <= 60
        THEN 'New'
        ELSE 'Returning'
    END AS customer_type,
    COUNT(*) AS total_orders,
    ROUND(AVG(o.net_amount), 2) AS avg_order_value
FROM orders o
JOIN customers c
    ON o.customer_id = c.customer_id
JOIN first_order f
    ON o.customer_id = f.customer_id
WHERE o.ab_variant IN ('A','B')
GROUP BY
    o.ab_variant,
    customer_type
ORDER BY
    customer_type,
    o.ab_variant;

