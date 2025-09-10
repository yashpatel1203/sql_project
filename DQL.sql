

-- Report of tenants who paid three month rent
SELECT * FROM LeasePaymentSummary
WHERE total_paid >= monthly_rent * 3;



-- Rank within cities and global rank on rent affordability
WITH CityRentalStats AS (
    SELECT 
        p.property_id,
        loc.city,
        p.rental_price,
        RANK() OVER (PARTITION BY loc.city ORDER BY p.rental_price DESC) AS city_price_rank,
        DENSE_RANK() OVER (ORDER BY p.rental_price DESC) AS global_rank
    FROM Property p
    JOIN Location loc ON p.property_id = loc.property_id
)
SELECT 
    loc.address,
    loc.city,
    p.rental_price,
    crs.city_price_rank AS 'Rank_in_City',
    crs.global_rank AS 'Global_Rank',
    CASE WHEN p.is_affordable_housing THEN 'Yes' ELSE 'No' END AS affordable_housing
FROM Property p
JOIN Location loc ON p.property_id = loc.property_id
JOIN CityRentalStats crs ON p.property_id = crs.property_id
Order by Global_Rank, Rank_in_City;



-- Report of Underperforming properties
SELECT * FROM (
	SELECT
		p.property_id,
		loc.address,
		loc.city,
		loc.province,
		loc.postal_code,
		p.rental_price,
		COUNT(DISTINCT CASE WHEN l.status = 'Active' THEN l.lease_id END) AS active_leases,
		COALESCE(SUM(py.amount_paid), 0) AS total_income,
		COUNT(mr.request_id) AS maintenance_count,
		ROUND(COALESCE(SUM(py.amount_paid), 0) / NULLIF(p.rental_price, 0), 1) AS occupancy_rate
	FROM Property p
	JOIN Location loc ON p.property_id = loc.property_id
	LEFT JOIN Lease_Agreement l ON p.property_id = l.property_id
	LEFT JOIN Payment py ON l.lease_id = py.lease_id
	LEFT JOIN Maintenance_Request mr ON p.property_id = mr.property_id
	GROUP BY p.property_id, loc.address, loc.city, loc.province, loc.postal_code, p.rental_price
	) A
WHERE occupancy_rate < 5 AND maintenance_count > 2;



-- Comparing tenant payment behavior using UDFs
SELECT 
    tenant_id,
    CalculateTotalRentPaid(tenant_id) AS total_paid, -- user defined function
    IsConsistentPayer(tenant_id) AS consistency -- user defined function
FROM Tenant
WHERE income > 50000;



-- Property Rental Price Analysis
SELECT
    p.property_id,
    loc.address,
    loc.city,
    loc.province,
    loc.postal_code,
    p.rental_price,
    (SELECT AVG(p2.rental_price) 
     FROM Property p2 
     JOIN Location loc2 ON p2.property_id = loc2.property_id
     WHERE loc2.city = loc.city) AS avg_city_price,
    p.rental_price - (SELECT AVG(p3.rental_price) 
                      FROM Property p3 
                      JOIN Location loc3 ON p3.property_id = loc3.property_id
                      WHERE loc3.city = loc.city) AS price_deviation,
    RANK() OVER (PARTITION BY loc.city 
                 ORDER BY p.rental_price DESC) AS city_price_rank,
    COUNT(mr.request_id) OVER (PARTITION BY p.property_id) AS maintenance_count
FROM Property p
JOIN Location loc ON p.property_id = loc.property_id
LEFT JOIN Maintenance_Request mr ON p.property_id = mr.property_id;



-- Tenant Payment Behavior Prediction
WITH PaymentFeatures AS (
    SELECT 
        t.tenant_id,
        t.income,
        AVG(DATEDIFF(p.payment_date, la.start_date)) AS avg_payment_delay,
        COUNT(DISTINCT p.payment_id) AS total_payments,
        COUNT(mr.request_id) AS maintenance_requests,
        DATEDIFF(CURDATE(), MAX(p.payment_date)) AS days_since_last_payment,
        CASE WHEN DATEDIFF(CURDATE(), MAX(p.payment_date)) > 30 THEN 1 ELSE 0 END AS is_delinquent
    FROM Tenant t
    JOIN Lease_Agreement la ON t.tenant_id = la.tenant_id
    LEFT JOIN Payment p ON la.lease_id = p.lease_id
    LEFT JOIN Maintenance_Request mr ON t.tenant_id = mr.tenant_id
    GROUP BY t.tenant_id
)
SELECT 
    *,
    ROUND(income / la.monthly_rent, 2) AS rent_to_income_ratio
FROM PaymentFeatures
JOIN Lease_Agreement la USING (tenant_id);