-- Total bottles sold per year
SELECT 
	YEAR([Date]) AS Year, 
	SUM(Bottles_Sold) AS Total_Bottles
FROM FACT_SALE
GROUP BY YEAR(Date)
ORDER BY YEAR(Date)

-- Top 3 vendors per city (Co nen exclude null?)
SELECT 
	Vendor_Name,
	city,
	Total_Bottles
FROM
	(SELECT
		v.Vendor_Name,
		s.city,
		SUM(f.Bottles_Sold) AS Total_Bottles,
		DENSE_RANK() OVER(PARTITION BY s.city ORDER BY SUM(f.Bottles_Sold) DESC) AS rank_sale
	FROM FACT_SALE f
		LEFT JOIN DIM_VENDOR v
		ON v.Vendor_Number = f.Vendor_Number
		LEFT JOIN DIM_STORE s
		ON s.Store_Number = f.Store_Number
	GROUP BY city, v.Vendor_Name
	) z
WHERE rank_sale <= 3

-- Sales Analysis by Category
-- 1. Identify top-selling categories (Assuming top 3 highest sales share)
SELECT
	c.Category_Name,
	SUM(f.Bottles_Sold)*100.0/(SELECT SUM(Bottles_Sold) FROM FACT_SALE) AS sales_share
FROM FACT_SALE f
	LEFT JOIN DIM_Category c
	ON f.Category_Number = c.Category_Number
GROUP BY Category_Name
ORDER BY 2 DESC

-- 2. Analyze sales trends for AMERICAN VODKAS, WHISKEY LIQUEUR, CANADIAN WHISKIES year by year
SELECT
	YEAR(f.[Date]) AS [Year],
	c.Category_Name,
	SUM(f.Bottles_Sold) AS Total_Bottles
FROM FACT_SALE f
	LEFT JOIN DIM_Category c
	ON f.Category_Number = c.Category_Number
WHERE c.Category_Name IN ('AMERICAN VODKAS','WHISKEY LIQUEUR','CANADIAN WHISKIES')
GROUP BY YEAR([Date]), c.Category_Name
ORDER BY 1

-- Top Stores by Sales per City in 2023
SELECT
	City,
	Store_Name,
	Total_Bottles
FROM
	(SELECT
		s.Store_Name,
		s.City,
		SUM(f.Bottles_Sold) AS Total_Bottles,
		DENSE_RANK() OVER(PARTITION BY s.City ORDER BY SUM(f.Bottles_Sold) DESC) AS rank_sale
	FROM FACT_SALE f
		LEFT JOIN DIM_STORE s
		ON f.Store_Number = s.Store_Number
	WHERE YEAR([Date]) = 2023
	GROUP BY s.City, s.Store_Name
	) z
WHERE rank_sale = 1

-- Vendor Sales Share
SELECT
	d.Vendor_Name,
	ROUND(SUM(f.Bottles_Sold)*100.0/(SELECT SUM(Bottles_Sold) FROM FACT_SALE),2) AS Vendor_sales_share
FROM FACT_SALE f
	LEFT JOIN DIM_VENDOR d
	ON f.Vendor_Number = d.Vendor_Number
GROUP BY Vendor_Name
ORDER BY 2 DESC
