-- SEARCH FOR TABLE
SELECT LEFT(sch.name + '.' + tab.name, 50)
FROM sys.tables		tab
JOIN sys.schemas	sch ON (sch.schema_id = tab.schema_id)
WHERE 1=1
AND tab.name LIKE '%log%' AND tab.name NOT LIKE '%blog%' AND tab.name NOT LIKE '%catalog%'
ORDER BY 1


-- SEARCH FOR COLUMN
/*
SELECT LEFT(sch.name + '.' + tab.name, 50), col.name
FROM sys.tables		tab
JOIN sys.schemas	sch ON (sch.schema_id = tab.schema_id)
JOIN sys.columns	col ON (col.object_id = tab.object_id)
WHERE 1=1
AND tab.name LIKE '%'
AND col.name LIKE '%name%'
AND sch.name IN ('dom', '')
-- */