# SQL Project - Sales Analysis

## Overview
Analysis of customer behavior, retention, and lifetime value for an e-commerce company to improve customer retention and maximize revenue.

## Business Questions
1. **Customer Segmentation** Who are our most valuable customer?
2. **Cohort Analysis:** How do different customer groups generate revenue?
3. **Retention Analysis** Which customer haven't pruchased recently?


## Analysis Approach

### 1. Customer Segmentation Analysis
- Categorized customers based on total lifetime value (LTV)
- Assigned customers to High, Mid, and Low-value segment_values
- Calculated key metrics: total revenue

🖥️ Query: 

```sql
WITH customer_ltv AS (
SELECT
	customerkey,
	full_name,
	ROUND(SUM(total_net_revenue)) AS total_ltv
FROM cohort_analysis 
GROUP BY 
	customerkey,
	full_name
), customer_segments AS (
SELECT 
	PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY total_ltv) AS ltv_25th_percentile,
	PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY total_ltv) AS ltv_75th_percentile
FROM customer_ltv
), segment_values AS (
SELECT 
	c.*,
	CASE 
		WHEN c.total_ltv < cs.ltv_25th_percentile THEN '1 - Low-Value'
		WHEN c.total_ltv <= cs.ltv_75th_percentile THEN '2 - Mid-Value'
		ELSE '3 - High-Value'
	END AS customer_segment
	
FROM customer_ltv c,
	customer_segments cs
)
SELECT
	customer_segment,
	SUM(total_ltv) AS total_ltv,
	COUNT(customerkey) AS customer_count,
	SUM(total_ltv) / COUNT(customerkey) AS avg_ltv
FROM segment_values 
GROUP BY
	customer_segment 
ORDER BY 
	customer_segment DESC
```

**📈 Visualization:**

![value.png](/images/value.png)

📊 **Key Findings:**
- High-value segment (25% of customers) drives 66% of revenue ($135.6M)
- Mid-value segment (50% of customers) generates 32% of revenue ($66.4M)
- Low-value segment (25% of customers) accounts for 2% of revenue ($4.3M)

**Business Insights**
- High-value (66% of revenue): Offer premium membership program to 12,368 VIP customers, as losing one customer significantly impacts revenue
- Mid-value (32% of revenue): Create upgrade path through personalized promotions, with potential $66.4M -> $135.6M revenue opportunity
- Low-value (2% of revenue): Design re-engagement campaigns and price-sensitive promotions to increase purchase frequency

### 2. Cohort Analysis
- Tracked revenue and customer count per cohorts
- Cohorts were grouped by year of first purchase
- Analyzed customer retention at a cohort level

🖥️ Query: 

```sql
SELECT
	cohort_year,
	COUNT(DISTINCT customerkey) AS total_customers,
	ROUND(SUM(total_net_revenue)) AS total_revenue,
	ROUND(SUM(total_net_revenue) / COUNT(DISTINCT customerkey)) AS customer_revenue
FROM cohort_analysis 
WHERE 
	orderdate = first_purchase_date 
GROUP BY 
	cohort_year
```

**📈 Visualization:**

![trendline.png](/images/trendline.png)

📊 **Key Findings:**
- Revenue per customer shows an alarming decreasing trend over time
- 2022-2024 cohorts are consistently performing worse than earlier cohorts
- NOTE: Although net revenue is increasing, this is likely due to a larger customer base, which is not reflective of customer value

**Business Insights**
- Value extracted from customers is decreasing over time and needs further investigation
- In 2023 we saw a drop in the number of customers acquired, which is of concern
- With both lowering LTV and decreasing customer acquisition, the company is facing a potential revenue decline

### 3. Customer Retention
- Identified customers at risk of churning
- Analyzed last purchase patterns
- Calculated customer-specific metrics

🖥️ Query: 

```sql
WITH customer_last_purchase AS (
    SELECT
        customerkey,
        orderdate,
        ROW_NUMBER() OVER (PARTITION BY customerkey ORDER BY orderdate DESC) AS rn,
        first_purchase_date,
        cohort_year
    FROM cohort_analysis
),
churned_customers AS (
    SELECT
        customerkey,
        orderdate AS last_purchase_date,
        cohort_year,
        CASE
            WHEN orderdate < (SELECT MAX(orderdate) FROM sales) - INTERVAL '6 months' THEN 'Churned'
            ELSE 'Active'
        END AS customer_status
    FROM customer_last_purchase
    WHERE rn = 1
        AND first_purchase_date < (SELECT MAX(orderdate) FROM sales) - INTERVAL '6 months'
)
SELECT
    cohort_year,
    customer_status,
    COUNT(customerkey) AS num_customers,
    SUM(COUNT(customerkey)) OVER(PARTITION BY cohort_year) AS total_customers,
    ROUND(COUNT(customerkey) / SUM(COUNT(customerkey)) OVER(PARTITION BY cohort_year), 2) AS cohort_percentage
FROM churned_customers
GROUP BY
    cohort_year,
    customer_status
ORDER BY
    cohort_year,
    customer_status;
```

**📈 Visualization:**

![customer_churn.png](/images/customer_churn.png)

![churn.png](/images/churn.png)

📊 **Key Findings:**
- Cohort churn stabilizes at -90% after 2-3 years, indicating a predictable long-term retention pattern
- Retention rates are consistently low (8-10%) across all cohorts, suggesting retention issues are systemic rather than specific to certain years
- Newer cohorts (2022-2023) show similar churn trajectories, signaling that without intervention, future cohorts will follow the same pattern

**Business Insights**
- Strengthen early engagement strategies to target the first 1-2 years with onboarding incentives, loyalty rewards, and personalized offers to improve long-term retention
- Re-engage high-value churned customers by focusing on targeted win-back campaigns rather than broad retention efforts, as reactivating valuable users may yield higher ROI 
- Predict & prempt churn risk and use customer-specific warning indicators to proactively intervene with at-risk users before they lapse

## Strategic Recommendations

1. **Customer Value Optimization** (Customer Segmentation)
	- Launch VIP program for 12,368 high-value customers (66% revenue)
	- Create personalized upgrade paths for mid-value segment ($66.4M -> $135.6M opportunity)
	- Design price-sensitive promotions for low-value segment to increase purchase frequency

2. **Cohort Performance Strategy** (Customer Revenue by Cohort)
	- Target 2022-2024 cohorts with personalized re-engagement offers
	- Implement loyalty/subscription programs to stabilize revenue fluctuations
	- Apply successful strategies from high-spending 2016-2018 cohorts to newer customers

3. **Retention & Churn Prevention** (Customer Retention)
	- Strengthen first 1-2 year engagement with onboarding incentives and loyalty rewards
	- Focus on targeted win-back campaigns for high-value churned customers
	- Implement proactive intervention system for at-risk customers before they lapse

## Technical Details
- **Database:** PostgreSQL
- **Analysis Tools:** PostgreSQL, DBeaver, PGadmin
- **Visualization:** Tableau
