/* 1. Report the fin_id, dpd_type, year and month of date of each loan in the tracking_payment_dpd table.
 dpd_type is defined as:
 1. If a fin_id has dpd>30: dpd_type1
 2. If a fin_id has dpd<=30 in current month, and it had dpd>0 in immediately preceding (previous) month: dpd_type2
 3. If a fin_id has dpd<=30 in current month, but no dpd in immediately preceding (previous) month: dpd_type3
 Return the result table ordered in ascending order by fin_id,year and month.
*/
WITH temp_table AS (
	SELECT
		*,
		ISNULL(DATEDIFF(MONTH, LAG(date_extract) OVER(PARTITION BY fin_id ORDER BY date_extract), date_extract),0) AS ym_diff,
		LAG(max_dpd) OVER(PARTITION BY fin_id ORDER BY date_extract) pre_dpd
	FROM (
		SELECT
			fin_id,
			MAX(dpd) max_dpd,
			DATEFROMPARTS(YEAR([date]), MONTH([date]), 1) AS date_extract
		FROM Jenfi_ques1
		GROUP BY  fin_id, DATEFROMPARTS(YEAR([date]), MONTH([date]), 1)
	) AS t1
)

SELECT 
	j.fin_id,
	CASE 
		WHEN dpd > 30 THEN 1
		WHEN ym_diff = 1 AND pre_dpd > 0 THEN 2
		ELSE 3
	END AS dpd_type,
	DATEPART(year,[date]) _year,
	DATEPART(month, [date]) _month
FROM Jenfi_ques1 j
LEFT JOIN temp_table t
	ON j.fin_id = t.fin_id AND DATEFROMPARTS(YEAR([date]), MONTH([date]), 1) = t.date_extract
GROUP BY 
	j.fin_id,
	CASE 
		WHEN dpd > 30 THEN 1
		WHEN ym_diff = 1 AND pre_dpd > 0 THEN 2
		ELSE 3
	END,
	DATEPART(year,[date]),
	DATEPART(month, [date])
ORDER BY fin_id, _year, _month

-- 2. Report the fin_id, average not due amount in cents & maximum total amount due in cents for dates in Oct'2022 from tracking_performance table. For fin_ids with no dates in Oct’22, return null values for both average not due amount and maximum of not due amount.
WITH t1 AS (
	SELECT 
		fin_id,
		AVG(not_due_amount) avg_not_due_amount,
		MAX(due_amount) max_due_amount
	FROM tracking_performance
	WHERE [date] > '2022-09-30'
	GROUP BY fin_id
)

SELECT 
	t2.fin_id, 
	avg_not_due_amount, 
	max_due_amount
FROM t1
RIGHT JOIN (
	SELECT DISTINCT fin_id
	FROM tracking_performance
) t2
ON t1.fin_id = t2.fin_id
