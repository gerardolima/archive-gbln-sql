DECLARE @threadId AS INT; SET @threadId = 1;

IF NOT EXISTS (SELECT 'x' FROM sys.tables WHERE name = '##MyDeadlockResourceA') BEGIN CREATE TABLE ##MyDeadlockResourceA(foo INT); INSERT ##MyDeadlockResourceA VALUES(1); END
IF NOT EXISTS (SELECT 'x' FROM sys.tables WHERE name = '##MyDeadlockResourceB') BEGIN CREATE TABLE ##MyDeadlockResourceB(foo INT); INSERT ##MyDeadlockResourceB VALUES(5); END

-- TRHEAD 1
IF (@threadId = 1)
BEGIN
	BEGIN TRANSACTION
	UPDATE ##MyDeadlockResourceA SET foo = 10 * foo;
	WAITFOR DELAY '0:0:05'
	UPDATE ##MyDeadlockResourceB SET foo = 20 * foo;
	COMMIT TRANSACTION
END

-- TRHEAD 2
IF (@threadId = 2)
BEGIN
	BEGIN TRANSACTION
	UPDATE ##MyDeadlockResourceB SET foo = 20 * foo;
	WAITFOR DELAY '0:0:05'
	UPDATE ##MyDeadlockResourceA SET foo = 10 * foo;
	COMMIT TRANSACTION
END
