-- ------------------------------------------------------------------------------------------------
--
-- This file contains statements to inspect foreign keys constraints
-- 1. GENERAL OVERVIEW  simple data dependency between tables                   (a->b, b->c)
-- 2. FULL DEPTH        full depth data dependency between tables               (c, b->c, a->b->c)
-- 3. FULL DEPTH(2)     full depth data dependency between tables WITH columns  (c, b->c, a->b->c)
-- 3. ROOT TABLES       fisrt to INSERT / do not depend on any other table      (a->null)
-- 4. LEAF TABLES       fisrt to DELETE / are not referenced by any other table (null->a)
-- 5. ANSI/ISO          SQL standard defined INFORMATION_SCHEMA tables          (oracle, mysql, ...)
--
-- gerardo.lima 2013.09.20
-- ------------------------------------------------------------------------------------------------
--
-- further resources:
--    http://sqlfromhell.wordpress.com/tag/sys-foreign_keys/
--    http://blog.sqlauthority.com/2009/02/26/
-- ------------------------------------------------------------------------------------------------

-- ------------------------------------------------------------------------------------------------
-- 1. GENERAL OVERVIEW
-- ------------------------------------------------------------------------------------------------
; WITH meta_info AS (
	SELECT tab.object_id, col.column_id
	, '[' + scm.name + '].[' + tab.name + ']' AS table_name
	, col.name AS [column_name]
	FROM sys.tables  tab 
	JOIN sys.columns col ON (col.object_id = tab.object_id)
	JOIN sys.schemas scm ON (tab.schema_id = scm.schema_id)
)
SELECT fkey.name [foreign_key]
, refs.object_id  [refs_table_id], refs.column_id [refs_column_id]
, refs.table_name [refs_table], refs.column_name  [refs_column]
, owns.object_id  [owns_table_id], owns.column_id [owns_column_id]
, owns.table_name [owns_table], owns.column_name  [owns_column]
FROM sys.foreign_keys			fkey
JOIN sys.foreign_key_columns	fcol ON (fcol.[constraint_object_id] = fkey.[object_id])
JOIN meta_info					refs ON (refs.[object_id] = fcol.[parent_object_id]     AND refs.[column_id] = fcol.[parent_column_id])
JOIN meta_info					owns ON (owns.[object_id] = fcol.[referenced_object_id] AND owns.[column_id] = fcol.[referenced_column_id])
ORDER BY [refs_table], [refs_column], [owns_table], [owns_column]
-- */

-- ------------------------------------------------------------------------------------------------
-- 2. FULL DEPTH
-- ------------------------------------------------------------------------------------------------
; WITH cte ([depth], [object_id], [schema_id], [name], [path]) AS (
	-- root tables (don't reference any other table)
	SELECT 0, tab.object_id, tab.schema_id, tab.name
	, CONVERT(VARCHAR(MAX), '[' + tab.name + ']')
	FROM sys.tables tab
	WHERE tab.object_id NOT IN (SELECT fke.parent_object_id FROM sys.foreign_keys fke)
	UNION ALL
	-- these tables referer to previous depth tables
	SELECT cte.depth +1, tab.object_id, tab.schema_id, tab.name
	, CONVERT(VARCHAR(MAX), cte.[path] + '/[' + tab.name + ']')
	FROM sys.tables					tab
	JOIN sys.foreign_keys			fke ON (tab.object_id = fke.parent_object_id)
	JOIN cte							ON (cte.object_id = fke.referenced_object_id)
	WHERE cte.object_id != tab.object_id
)
SELECT * -- MAX(depth) AS [max_depth], object_id
FROM cte
WHERE cte.schema_id IN (SELECT schema_id FROM sys.schemas WHERE name LIKE 'hh%')
-- */

-- ------------------------------------------------------------------------------------------------
-- 3. FULL DEPTH WITH COLUMNS
-- ------------------------------------------------------------------------------------------------
; WITH cte ([depth], [object_id], [schema_id], [name], [columns], [path]) AS (
	-- root tables (don't reference any other table)
	SELECT 0, tab.object_id, tab.schema_id, tab.name
	, CONVERT(VARCHAR(MAX), '')
	, CONVERT(VARCHAR(MAX), '[' + tab.name + ']')
	FROM sys.tables tab
	WHERE tab.object_id NOT IN (SELECT fke.parent_object_id FROM sys.foreign_keys fke)
	UNION ALL
	-- these tables referer to previous depth tables
	SELECT cte.depth +1, tab.object_id, tab.schema_id, tab.name
	, CONVERT(VARCHAR(MAX), tab.name + '(' + ctb.name +') REFERS ' + cte.name + '('+ cre.name +')')
	, CONVERT(VARCHAR(MAX), cte.[path] + '/[' + tab.name + ']')
	FROM sys.tables					tab
	JOIN sys.foreign_keys			fke ON (tab.object_id = fke.parent_object_id)
	JOIN sys.foreign_key_columns	fco ON (fco.constraint_object_id = fke.object_id)
	JOIN sys.columns				ctb ON (ctb.object_id = fke.parent_object_id AND ctb.column_id = fco.parent_column_id)
	JOIN sys.columns				cre ON (cre.object_id = fke.referenced_object_id AND cre.column_id = fco.referenced_column_id)
	JOIN cte							ON (cte.object_id = fke.referenced_object_id)
	WHERE cte.object_id != tab.object_id
)
SELECT cte.* FROM cte
WHERE cte.schema_id IN (SELECT schema_id FROM sys.schemas WHERE name LIKE 'hh%')
ORDER BY cte.[depth], cte.[path]
-- */

-- ------------------------------------------------------------------------------------------------
-- 4. ROOT TABLES
-- ------------------------------------------------------------------------------------------------
SELECT tab.[object_id], tab.[name]
FROM sys.tables tab
WHERE tab.[object_id] NOT IN (SELECT fkey.[parent_object_id] FROM sys.foreign_keys fkey);
-- */

-- ------------------------------------------------------------------------------------------------
-- 5. LEAF TABLES
-- ------------------------------------------------------------------------------------------------
SELECT tab.[object_id], tab.[name]
FROM sys.tables tab
WHERE tab.[object_id] NOT IN (SELECT fkey.[referenced_object_id] FROM sys.foreign_keys fkey);
-- */

-- ------------------------------------------------------------------------------------------------
-- 6. ANSI/ISO
-- ------------------------------------------------------------------------------------------------
SELECT
	FK.CONSTRAINT_NAME	FKey_Name,
	KU2.TABLE_NAME		Parent_Table,
	KU.COLUMN_NAME		Parent_Col,
	KU.TABLE_NAME		Child_Table,
	KU2.COLUMN_NAME		Child_Col
FROM INFORMATION_SCHEMA.REFERENTIAL_CONSTRAINTS FK
JOIN INFORMATION_SCHEMA.KEY_COLUMN_USAGE		KU  ON KU.CONSTRAINT_NAME = FK.CONSTRAINT_NAME
JOIN INFORMATION_SCHEMA.KEY_COLUMN_USAGE		KU2 ON KU2.CONSTRAINT_NAME = FK.UNIQUE_CONSTRAINT_NAME AND KU.ORDINAL_POSITION = KU2.ORDINAL_POSITION
-- */