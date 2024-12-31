/* Change Data Type for Date & Bottles_Sold */
ALTER TABLE HMD_TABLE ALTER COLUMN [Date] DATE
ALTER TABLE HMD_TABLE ALTER COLUMN Bottles_Sold INT

/* Create Index */
CREATE CLUSTERED COLUMNSTORE INDEX CCSI_HMD ON HMD_TABLE

/* Normalization: DIM_STORE */
-- Split Store Name
-- Assume the right of the last slash "/" is city name
;
WITH DIM_Store1 AS (
	SELECT 
		[Date],
		Store_Number,
		Part1 Store_Name,
		CASE 
			WHEN City IS NULL THEN Part2 
			ELSE City 
		END AS City
	FROM (
		SELECT 
			[Date], 
			Store_Number, 
			City,
			CASE 
				WHEN CHARINDEX('/', Store_Name) > 0 THEN LEFT(Store_Name, CHARINDEX('/', Store_Name) - 1) 
				ELSE Store_Name 
			END AS Part1,
			CASE 
				WHEN CHARINDEX('/', Store_Name) > 0 THEN RIGHT(Store_Name, CHARINDEX('/', REVERSE(Store_Name)) - 1) 
			END AS Part2
		FROM HMD_TABLE
	) t2
)

-- Standardization
SELECT
	Store_Number,
	Store_Name,
	City
INTO DIM_STORE
FROM (
	SELECT 
		Store_Number,
		TRIM(Store_Name) Store_Name,
		TRIM(City) City,
		ROW_NUMBER() OVER(PARTITION BY Store_Number ORDER BY [Date] DESC) AS row_n
	FROM DIM_Store1 
) Z
WHERE row_n = 1

-- Handle misspelled cities & Null Values
UPDATE DIM_STORE 
SET City = 
	CASE
		WHEN store_number = '3808' THEN 'LA PORTE CITY'
		WHEN City = 'CLEARLAKE' THEN 'CLEAR LAKE'
		WHEN City = 'ARNOLD''S PARK' THEN 'ARNOLDS PARK'
		WHEN City = 'LECLAIRE' THEN 'LE CLAIRE'
		WHEN City = 'ROCKWELL CITY' THEN 'ROCKWELL'
		ELSE City
	END

SELECT *
FROM DIM_VENDOR

ALTER TABLE DIM_STORE ALTER COLUMN City nvarchar(255)
ALTER TABLE DIM_STORE ALTER COLUMN Store_Name nvarchar(255)
ALTER TABLE DIM_STORE ALTER COLUMN Store_Number int NOT NULL

ALTER TABLE DIM_STORE
ADD PRIMARY KEY (Store_Number)

/* Normalization: DIM_VENDOR */
SELECT
	Vendor_Number,
	Vendor_Name
INTO DIM_VENDOR
FROM (
	SELECT 
		Vendor_Number,
		Vendor_Name,
		ROW_NUMBER() OVER(PARTITION BY Vendor_Number ORDER BY [Date] DESC) AS row_n
	FROM HMD_TABLE 
) Z
WHERE row_n = 1 
	AND Vendor_Number IS NOT NULL

ALTER TABLE DIM_VENDOR ALTER COLUMN Vendor_Name nvarchar(255)
ALTER TABLE DIM_VENDOR ALTER COLUMN Vendor_Number bigint NOT NULL

ALTER TABLE DIM_VENDOR
ADD PRIMARY KEY (Vendor_Number)

/* Normalization: DIM_Category */
SELECT 
	ROW_NUMBER() OVER(ORDER BY CATEGORY_NAME) Category_Number,
	Category_Name
INTO DIM_Category
FROM (
	SELECT DISTINCT CATEGORY_NAME
	FROM HMD_TABLE
	WHERE CATEGORY_NAME IS NOT NULL
) Z
ORDER BY 1

ALTER TABLE DIM_CATEGORY ALTER COLUMN Category_Name nvarchar(255)
----------------------------------------------------------------
ALTER TABLE HMD_TABLE
ADD Category_Number INT

UPDATE A
SET A.Category_Number=B.Category_Number
FROM HMD_TABLE A
JOIN DIM_Category B ON A.Category_Name=B.Category_Name

ALTER TABLE DIM_CATEGORY ALTER COLUMN Category_Number int NOT NULL

ALTER TABLE DIM_Category
ADD PRIMARY KEY (Category_Number)

/* Create DIM_DATE */
CREATE TABLE DIM_DATE 
(
  [DATEID] DATE,
  [YEAR] INT,
  [MONTHIDX] INT,
  [MONTH] NVARCHAR(3),
  [DAY] INT,
  [WEEK] INT,
  [WDAYIDX] INT,
  [WEEKDAY] NVARCHAR(3),
  [QUARTER] NVARCHAR(2),
  PRIMARY KEY ([DATEID])
)

DECLARE 
	@dIncr DATE = '2017-01-01',
	@dEnd  DATE = '2023-12-31'

WHILE ( @dIncr <= @dEnd )
BEGIN
	INSERT INTO DIM_DATE 
	VALUES (
		@dIncr,
		YEAR(@dIncr),
		MONTH(@dIncr),
		FORMAT(@dIncr,'MMM'),
		DAY(@dIncr),
		DATEPART(WEEK,@dIncr),
		DATEPART(WEEKDAY,@dIncr),
		FORMAT(@dIncr,'ddd'),
		'Q'+CAST(DATEPART(QUARTER,@dIncr) AS NVARCHAR)
	)

	SET @dIncr = DATEADD(DAY, 1, @dIncr )
END

SELECT * FROM DIM_DATE

/* Create FACT_SALE table */
SELECT
	[Date],
	Store_Number,
	Vendor_Number,
	Category_Number,
	Bottles_Sold
INTO FACT_SALE
FROM HMD_TABLE

ALTER TABLE FACT_SALE ALTER COLUMN Vendor_Number int

CREATE CLUSTERED COLUMNSTORE INDEX CCSI_FACT_SALE ON FACT_SALE
