USE tempdb;
GO
CREATE FUNCTION NumberGenerator(@count BIGINT)
RETURNS TABLE
WITH SCHEMABINDING
AS
    -- based on Itzik Ben-Gan's implementation
    -- [http://sqlmag.com/sql-server/virtual-auxiliary-table-numbers]
	RETURN
    WITH E01(N) AS (SELECT 1 UNION ALL SELECT 1),			-- 2^1
         E02(N) AS (SELECT 1 FROM E01 a CROSS JOIN E01 b),	-- 2^2
         E04(N) AS (SELECT 1 FROM E02 a CROSS JOIN E02 b),	-- 2^4
         E08(N) AS (SELECT 1 FROM E04 a CROSS JOIN E04 b),	-- 2^8
         E16(N) AS (SELECT 1 FROM E08 a CROSS JOIN E08 b),	-- 2^16
         E32(N) AS (SELECT 1 FROM E16 a CROSS JOIN E16 b),	-- 2^32
         cteTally(N) AS (SELECT ROW_NUMBER() OVER (ORDER BY N) FROM E32)
    SELECT TOP(@count) N FROM cteTally;
GO

