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
