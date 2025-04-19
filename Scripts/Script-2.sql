WITH monthly_metrics AS (
SELECT
	DATE_TRUNC('month', ca.orderdate):: DATE AS order_month,
	COUNT(DISTINCT ca.customerkey) AS total_customers,
	ROUND(SUM(total_net_revenue)) AS total_revenue,
	ROUND(SUM(total_net_revenue) / COUNT(DISTINCT ca.customerkey)) AS avg_revenue
FROM cohort_analysis ca 
GROUP BY order_month 
ORDER BY order_month 
)
SELECT 
	order_month,
	total_revenue,
	AVG(total_revenue) OVER (
		ORDER BY order_month 
		ROWS BETWEEN 1 PRECEDING AND 1 FOLLOWING) AS rolling_3mo_total_revenue,
	AVG(total_customers) OVER (
		ORDER BY order_month 
		ROWS BETWEEN 1 PRECEDING AND 1 FOLLOWING) AS rolling_3mo_total_customers,
	AVG(avg_revenue) OVER (
		ORDER BY order_month 
		ROWS BETWEEN 1 PRECEDING AND 1 FOLLOWING) AS rolling_3mo_total_avg_revenue
FROM monthly_metrics 
ORDER BY
	order_month