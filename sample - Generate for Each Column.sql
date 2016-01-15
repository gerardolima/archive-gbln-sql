-- ----------------------------------------------------------------------
-- This tool generates a script that runs 'SanitizeCodepageCheck' for
-- every row of every 2-byte char-based column and saves its results
-- in a table; its main goal is to create statistics of the changes for
-- the data, inregarding to UTF-8 correctness
-- gerardo.lima 2013-07-11
-- ----------------------------------------------------------------------

SET NOCOUNT ON;
SET ANSI_WARNINGS OFF;

-- special cases
-- "constants"
DECLARE @C_NEW_LINE			NVARCHAR(2) = CHAR(10);
DECLARE @C_TEMPLATE			NVARCHAR(MAX);

-- variables for TAB_CURSOR
DECLARE @COL$schema			SYSNAME;
DECLARE @COL$table			SYSNAME;
DECLARE @COL$column			SYSNAME;

-- other variables
DECLARE @COL_STMT			NVARCHAR(MAX);

-- ----------------------------------------------------------------------------
-- 1. PROLOG
-- ----------------------------------------------------------------------------
PRINT '-- ==========================================================';
PRINT 'USE [' + DB_NAME() + '];'
PRINT 'SET NOCOUNT ON;'
PRINT 'SET ANSI_WARNINGS OFF;'
PRINT '-- ==========================================================';
PRINT '';

PRINT 'DECLARE @NOW NVARCHAR(20);';
PRINT 'CREATE TABLE #RESULTS (';
PRINT '  [schema_name] NVARCHAR(10),';
PRINT '  [table_name]  NVARCHAR(50),';
PRINT '  [column_name] NVARCHAR(50),';
PRINT '  [row_count]   INT,';
PRINT '  [qtd_00]      INT,';
PRINT '  [qtd_11]      INT,';
PRINT '  [qtd_12]      INT,';
PRINT '  [qtd_14]      INT,';
PRINT '  [qtd_21]      INT,';
PRINT '  [qtd_22]      INT,';
PRINT '  [now]         DATETIME';
PRINT ');';
PRINT 'CREATE UNIQUE CLUSTERED INDEX IX ON #RESULTS ([schema_name], [table_name], [column_name]);';
PRINT '';

-- ----------------------------------------------------------------------------
-- 2. BUILD TEMPLATE
-- ----------------------------------------------------------------------------

SET @C_TEMPLATE = 'SET @NOW = CONVERT(NVARCHAR(20), GETDATE(), 120);' + @C_NEW_LINE
+ 'RAISERROR(''%s running %s.%s.%s'', 0, 1, @NOW, ''$schema$'', ''$table$'', ''$column$'') WITH NOWAIT;' + @C_NEW_LINE
+ 'INSERT #RESULTS ' + @C_NEW_LINE
+ 'SELECT ''$schema$'', ''$table$'', ''$column$'', COUNT(*) AS [row_count]' + @C_NEW_LINE
+ ', SUM(CASE WHEN SanitizeCodepageCheck([$column$]) =  0 THEN 1 ELSE 0 END) AS [qtd_00]' + @C_NEW_LINE
+ ', SUM(CASE WHEN SanitizeCodepageCheck([$column$]) = 11 THEN 1 ELSE 0 END) AS [qtd_11]' + @C_NEW_LINE
+ ', SUM(CASE WHEN SanitizeCodepageCheck([$column$]) = 12 THEN 1 ELSE 0 END) AS [qtd_12]' + @C_NEW_LINE
+ ', SUM(CASE WHEN SanitizeCodepageCheck([$column$]) = 14 THEN 1 ELSE 0 END) AS [qtd_14]' + @C_NEW_LINE
+ ', SUM(CASE WHEN SanitizeCodepageCheck([$column$]) = 21 THEN 1 ELSE 0 END) AS [qtd_21]' + @C_NEW_LINE
+ ', SUM(CASE WHEN SanitizeCodepageCheck([$column$]) = 22 THEN 1 ELSE 0 END) AS [qtd_22]' + @C_NEW_LINE
+ ', @NOW' + @C_NEW_LINE
+ 'FROM [$schema$].[$table$];'  + @C_NEW_LINE

-- ----------------------------------------------------------------------------
-- 3. ITERATE OVER THE 2-BYTE CHAR-BASED COLUMNS AND GENERATE SQL SCRIPT
-- ----------------------------------------------------------------------------
DECLARE TAB_CURSOR CURSOR LOCAL FORWARD_ONLY FAST_FORWARD READ_ONLY FOR
	SELECT sch.name	AS [schema_name]
	, tab.name		AS [table_name]
	, col.name		AS [column_name]
	FROM sys.schemas	sch
	JOIN sys.tables		tab ON (sch.schema_id = tab.schema_id)
	JOIN sys.columns	col ON (col.object_id = tab.object_id)
	JOIN sys.types		typ ON (col.system_type_id = typ.system_type_id)
	WHERE 1=1
	-- get all 2-byte char-based columns
	AND col.is_computed = 0
	AND typ.name IN (N'NCHAR', N'NVARCHAR', N'NTEXT')
	-- filter schemas and tables
--	AND sch.name IN ('')
	AND NOT (1=2
		OR (tab.name LIKE 'sys%')
		OR (tab.name = 'AttachmentFileContent')
	)
	ORDER BY [schema_name], [table_name], [column_name];

OPEN TAB_CURSOR;
FETCH NEXT FROM TAB_CURSOR INTO @COL$schema, @COL$table, @COL$column;
WHILE (@@FETCH_STATUS = 0)
BEGIN
	SET @COL_STMT = @C_TEMPLATE;
	SET @COL_STMT = REPLACE(@COL_STMT, '$schema$', @COL$schema);
	SET @COL_STMT = REPLACE(@COL_STMT, '$table$', @COL$table);
	SET @COL_STMT = REPLACE(@COL_STMT, '$column$', @COL$column);
	PRINT @COL_STMT;

FETCH NEXT FROM TAB_CURSOR INTO @COL$schema, @COL$table, @COL$column;
END

CLOSE TAB_CURSOR;
DEALLOCATE TAB_CURSOR;

-- ----------------------------------------------------------------------------
-- 4. EPILOG
-- ----------------------------------------------------------------------------

PRINT '';
PRINT 'SELECT * FROM #RESULTS ORDER BY [schema_name], [table_name], [column_name];'