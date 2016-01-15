
; WITH cte AS (
	SELECT CAST(NULL AS INT) [evtClass], CAST(NULL AS VARCHAR(128)) [evtName]
	UNION ALL SELECT 33, 'Exception'
	UNION ALL SELECT 40, 'SQL:StmtStating'
	UNION ALL SELECT 41, 'SQL:Completed'
	UNION ALL SELECT 60, 'Lock:Escalation'
	UNION ALL SELECT 162, 'User Error Message'
	UNION ALL SELECT 65533, 'Trace Stop'
	UNION ALL SELECT 65528, 'Trace Init (?)'
	UNION ALL SELECT 65534, 'Trace Start (?)'
)
SELECT [evtName], (duration / (1000. * 1000.)) [secs], trc.*
FROM dbtrace trc
JOIN cte ON trc.[EventClass] = cte.[evtClass]
ORDER BY duration DESC



-- select distinct trc.eventClass from dbtrace trc;
--select distinct trc.databasename from dbtrace trc 
/*
; WITH cte AS (
	SELECT CAST(NULL AS INT) [evtClass], CAST(NULL AS VARCHAR(128)) [evtName]
	UNION ALL SELECT 33, 'Exception'
	UNION ALL SELECT 40, 'SQL:StmtStating'
	UNION ALL SELECT 41, 'SQL:Completed'
	UNION ALL SELECT 60, 'Lock:Escalation'
	UNION ALL SELECT 162, 'User Error Message'
	UNION ALL SELECT 65533, 'Trace Stop'
	UNION ALL SELECT 65528, 'Trace Init (?)'
	UNION ALL SELECT 65534, 'Trace Start (?)'
)
SELECT *
FROM dbtrace trc
WHERE trc.[EventClass] NOT IN (SELECT [evtClass] FROM cte WHERE [evtClass] IS NOT NULL);
--*/

/*
SELECT CONVERT(NVARCHAR(MAX), CONVERT(VARBINARY(MAX), BinaryData)), CONVERT(VARBINARY(MAX), BinaryData), DATALENGTH(BinaryData)
FROM dbtrace trc
WHERE rownumber = 0
-- */