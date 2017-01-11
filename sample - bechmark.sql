-- test performance
GO
CHECKPOINT;
GO
DBCC DROPCLEANBUFFERS;
GO

DECLARE @d1 DATETIME = GETDATE();

--
-- INSERT STATEMENT GROUP A
--
WAITFOR DELAY '00:00:00.001'
SELECT DATEDIFF(MILLISECOND, @D1, GETDATE());

GO
CHECKPOINT;
GO
DBCC DROPCLEANBUFFERS;
GO

DECLARE @d1 DATETIME = GETDATE();

--
-- INSERT STATEMENT GROUP B
--
WAITFOR DELAY '00:00:00.001'
SELECT DATEDIFF(MILLISECOND, @D1, GETDATE());

GO
CHECKPOINT;
GO
DBCC DROPCLEANBUFFERS;
GO

DECLARE @d1 DATETIME = GETDATE();

--
-- INSERT STATEMENT GROUP C
--
WAITFOR DELAY '00:00:00.001'
SELECT DATEDIFF(MILLISECOND, @D1, GETDATE());