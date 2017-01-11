-- ------------------------------------------------------------------------------------------------
-- DESCRIPTION
-- This script generates update statements for tables that have columns as double-byte characters.
-- This script can be used as an initial step to generate code from a given schema (see variables
-- @TPL_formula and @TPL_filter and the filter on step #2.1)
--
-- HOW TO USE
-- Run this script on the target database and copy the script it generates to stdout. Due to the
-- limit of the PRINT command, tables with many columns will produce invalid SQL bacause of a
-- line break; parse the statement before use and, if there's a parse error, it should be easy
-- to correct.
--
-- DETAILS
-- It iterates over all double byte char columns of all tables within the given schemas and
-- generates update statements for each table to apply the SanitizeCodepage to these columns
-- if the result of the function is different from its current value.
--
-- gerardo lima 2013-06-06
-- ------------------------------------------------------------------------------------------------

-- ----------------------------------------------------------------------
-- PRINT
-- ----------------------------------------------------------------------
SET NOCOUNT ON;
SET ANSI_WARNINGS OFF;

-- "constants"
DECLARE @C_NEW_LINE			NVARCHAR(2) = CHAR(10);
DECLARE @C_RUN_COMMAND		BIT = 0;
DECLARE @C_RUN_VERBOSE		BIT = 1;

-- variables for TAB_CURSOR
DECLARE @TAB$schema			SYSNAME;
DECLARE @TAB$name			SYSNAME;
DECLARE @TAB$object_id		INT;

-- variables to iterate on TAB_CURSOR scope
DECLARE @TAB_command		NVARCHAR(MAX);
DECLARE @TAB_filter			NVARCHAR(MAX);
DECLARE @TAB_assign 		NVARCHAR(MAX);
DECLARE @TAB_rowcount		INT;
DECLARE @TAB_column_index	SMALLINT;

-- variables for COL_CURSOR
DECLARE @COL$name			SYSNAME;
DECLARE @COL$type			SYSNAME;
DECLARE @COL$maxchar		SYSNAME;

-- variables to iterate on COL_CURSOR scope
DECLARE @COL_field			NVARCHAR(MAX);
DECLARE @COL_assign			NVARCHAR(MAX);
DECLARE @COL_filter			NVARCHAR(MAX);

-- other variables
DECLARE @TPL_formula		NVARCHAR(MAX);
DECLARE @TPL_filter			NVARCHAR(MAX);

-- ----------------------------------------------------------------------------
-- 1. CREATE THE FORMULA TEMPLATE
-- ----------------------------------------------------------------------------
-- prolog
SET @TPL_formula = '$field$ = SUBSTRING($field$, 1, 17) + ''...''';           -- implement the 
SET @TPL_filter  = 'LEN($field$) > 20)';

IF(@C_RUN_VERBOSE=1)
BEGIN
	PRINT '-- ' + @TPL_formula;
	PRINT '-- ' + @TPL_filter;
	PRINT '-- ==========================================================';
	PRINT 'USE [' + DB_NAME() + '];'
	PRINT 'SET NOCOUNT OFF;'
	PRINT 'SET ANSI_WARNINGS ON;'
	PRINT '-- ==========================================================';
	PRINT '';
END

-- ----------------------------------------------------------------------------
-- 2. ITERATE OVER THE USER TABLES
-- ----------------------------------------------------------------------------
DECLARE TAB_CURSOR CURSOR LOCAL FORWARD_ONLY FAST_FORWARD READ_ONLY FOR
	SELECT sch.name	AS [schema_name]
	, tab.name		AS [table_name]
	, tab.object_id
	FROM sys.tables tab
	JOIN sys.schemas sch ON (tab.schema_id = sch.schema_id)
	WHERE 1=1
	-- filter schemas and tables
	AND NOT (1=2
		OR (tab.name LIKE 'sys%')
		OR (tab.name = 'AttachmentFileContent')
	)
	ORDER BY [schema_name], [table_name];

OPEN TAB_CURSOR;
FETCH NEXT FROM TAB_CURSOR INTO @TAB$schema, @TAB$name, @TAB$object_id;

WHILE (@@FETCH_STATUS = 0)
BEGIN
	-- set initial values for 'TAB_' variables
	SET @TAB_assign			= '';
	SET @TAB_filter			= '';
	SET @TAB_column_index	= 0;

	-- ----------------------------------------------------------------------------
	-- 2.1 ITERATE OVER THIS TABLES' COLUMNS
	-- ----------------------------------------------------------------------------
	DECLARE COL_CURSOR CURSOR LOCAL FORWARD_ONLY FAST_FORWARD READ_ONLY FOR
		SELECT col.name, typ.name AS [type]
		, CASE typ.name
			WHEN 'NCHAR'	THEN col.max_length / 2
			WHEN 'NVARCHAR'	THEN col.max_length / 2
			ELSE -1
		END AS [max_chars]
		FROM sys.columns	col
		JOIN sys.types		typ ON (col.system_type_id = typ.system_type_id)
		WHERE col.object_id = @TAB$object_id
		AND col.is_computed = 0
		AND  typ.name IN ('NCHAR', 'NVARCHAR', 'NTEXT')
		ORDER BY col.name;

	OPEN COL_CURSOR;
	FETCH NEXT FROM COL_CURSOR INTO @COL$name, @COL$type, @COL$maxchar;

	WHILE @@FETCH_STATUS = 0
	BEGIN
		SET @TAB_column_index = @TAB_column_index +1;

		-- separators are different for first element
		DECLARE @separator_assign NVARCHAR(10) = CASE WHEN (@TAB_column_index = 1) THEN '' ELSE @C_NEW_LINE + ', '    END;
		DECLARE @separator_filter NVARCHAR(10) = CASE WHEN (@TAB_column_index = 1) THEN '' ELSE @C_NEW_LINE + 'OR ' END;

		-- add type coertion if column is text or can hold strings bigger than allowed
		SET @COL_field  = '[' + @COL$name + ']';

		SET @COL_assign = REPLACE(@TPL_formula, '$field$', @COL_field);
		SET @COL_filter = REPLACE(@TPL_filter, '$field$', @COL_field);

		-- concatenate column to WHERE and SET clauses
		SET @TAB_assign	= @TAB_assign + @separator_assign + @COL_assign;
		SET @TAB_filter	= @TAB_filter + @separator_filter + @COL_filter;


	FETCH NEXT FROM COL_CURSOR INTO @COL$name, @COL$type, @COL$maxchar;
	END
	
	-- ----------------------------------------------------------------------------
	-- 2.2 IF ANY COLUMN MET THE CRITERIA (2-BYTE-CHAR-BASED), RUN THE COMMAND
	-- ----------------------------------------------------------------------------
	IF (@TAB_column_index > 0)
	BEGIN

		DECLARE @PRT_max INT = 4000;
		DECLARE @PRT_err BIT = 0;
		DECLARE @PRT_len INT;
		DECLARE @PRT_pos INT;

		SET @TAB_command = 'UPDATE [' + @TAB$schema + '].[' + @TAB$name + '] ' + @C_NEW_LINE
			+ 'SET ' + @TAB_assign + @C_NEW_LINE
			+ 'WHERE ' + @TAB_filter + ';' + @C_NEW_LINE;

		IF (RIGHT(@TAB_command, 1) != ';')
		BEGIN
			PRINT 'COMMAND OVERFLOW FOR TABLE [' + @TAB$schema + '].[' + @TAB$name + ']';
			SET @PRT_err = 1;
		END

		SET @PRT_len = LEN(@TAB_command);
		SET @PRT_pos = 1;
		WHILE ((@PRT_err=1 OR @C_RUN_VERBOSE=1) AND (@PRT_pos <= @PRT_len))
		BEGIN
			PRINT SUBSTRING(@TAB_command, @PRT_pos, @PRT_max);
			SET @PRT_pos = @PRT_pos + @PRT_max;
		END

		IF(@PRT_err=0 AND @C_RUN_COMMAND=1)
		BEGIN
			RAISERROR('-- running command for [%s].[%s].', 0, 0, @TAB$schema, @TAB$name) WITH NOWAIT;
			EXEC(@TAB_command);
			SET @TAB_rowcount = @@ROWCOUNT
			RAISERROR('-- %i updated rows.', 0, 0, @TAB_rowcount) WITH NOWAIT;
		END
		PRINT '----------------------------------------------------'
	END

	CLOSE COL_CURSOR;
	DEALLOCATE COL_CURSOR;

FETCH NEXT FROM TAB_CURSOR INTO @TAB$schema, @TAB$name, @TAB$object_id;
END

CLOSE TAB_CURSOR;
DEALLOCATE TAB_CURSOR;
--RETURN 0
-- */