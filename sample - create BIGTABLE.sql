
-- --------------------------------------------------------------------------------------
-- SECTION 1: GENERATE DATA
-- --------------------------------------------------------------------------------------
/*
drop TABLE #bigtable_base
drop TABLE #bigtable_simple
drop TABLE #bigtable_entropy
*/
-- STEP 1.1: TABLE STRUCTURES
CREATE TABLE #bigtable_base    (myId BIGINT UNIQUE CLUSTERED, myValue NVARCHAR(MAX));
CREATE TABLE #bigtable_simple  (myId BIGINT UNIQUE CLUSTERED, myValue NVARCHAR(MAX));
CREATE TABLE #bigtable_entropy (myId BIGINT UNIQUE CLUSTERED, myValue NVARCHAR(MAX));

-- STEP 1.2: GENERATE #bigtable_base
DECLARE @xEx   NVARCHAR(3) = CONVERT(NVARCHAR(MAX), 0x780080007800); -- 'x€x'
DECLARE @ch10  NVARCHAR(10)  = N'123ABCabc.';

INSERT #bigtable_base (myId, myValue)
SELECT  1,  NULL							UNION ALL
SELECT  2,  N''								UNION ALL
SELECT  3,  REPLICATE(@ch10, 2)				UNION ALL
SELECT  4,  REPLICATE(@ch10, 3)				UNION ALL
SELECT  5,  REPLICATE(@ch10, 10)			UNION ALL
SELECT  6,  REPLICATE(@ch10, 50)			UNION ALL
SELECT  7,  REPLICATE(@ch10, 99)			UNION ALL
SELECT  8,  N'€'							UNION ALL
SELECT  9,  N'€' + REPLICATE(@ch10, 2)		UNION ALL
SELECT 10,  N'€' + REPLICATE(@ch10, 3)		UNION ALL
SELECT 11,  N'€' + REPLICATE(@ch10, 10)		UNION ALL
SELECT 12,  N'€' + REPLICATE(@ch10, 50)		UNION ALL
SELECT 13,  N'€' + REPLICATE(@ch10, 99)		UNION ALL
SELECT 14,  REPLICATE(@ch10, 2) + N'€'		UNION ALL
SELECT 15,  REPLICATE(@ch10, 3) + N'€'		UNION ALL
SELECT 16,  REPLICATE(@ch10, 10) + N'€'		UNION ALL
SELECT 17,  REPLICATE(@ch10, 50) + N'€'		UNION ALL
SELECT 18,  REPLICATE(@ch10, 99) + N'€'		UNION ALL
SELECT 19,  N'?'							UNION ALL
SELECT 20,  N'?' + REPLICATE(@ch10, 2)		UNION ALL
SELECT 21,  N'?' + REPLICATE(@ch10, 3)		UNION ALL
SELECT 22,  N'?' + REPLICATE(@ch10, 10)		UNION ALL
SELECT 23,  N'?' + REPLICATE(@ch10, 50)		UNION ALL
SELECT 24,  N'?' + REPLICATE(@ch10, 99)		UNION ALL
SELECT 25,  REPLICATE(@ch10, 2) + N'?'		UNION ALL
SELECT 26,  REPLICATE(@ch10, 3) + N'?'		UNION ALL
SELECT 27,  REPLICATE(@ch10, 10) + N'?'		UNION ALL
SELECT 28,  REPLICATE(@ch10, 50) + N'?'		UNION ALL
SELECT 29,  REPLICATE(@ch10, 99) + N'?';

-- STEP 1.3: GENERATE #bigtable_simple BY REPEATING #bigtable_base
DECLARE @count INT = 0;
WHILE @count < 100000
BEGIN
	INSERT #bigtable_simple (myId, myValue)
	SELECT myId + (100 * @count), myValue
	FROM #bigtable_base;
	
	SET @count = @count+1;
END

-- STEP 1.4: GENERATE #bigtable_entropy BY COPYING FROM #bigtable_simple AND MODIFING myValue to avoid repetition
INSERT #bigtable_entropy (myId, myValue)
SELECT myId, CASE WHEN (LEN(myValue) > 0) THEN CONVERT(VARCHAR(20), myId) + myValue ELSE myValue END
FROM #bigtable_simple;

SELECT COUNT(*) FROM #bigtable_entropy
SELECT COUNT(*) FROM #bigtable_simple