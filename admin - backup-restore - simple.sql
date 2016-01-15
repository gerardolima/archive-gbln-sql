-- ==================================================================
-- parameters
-- ==================================================================
DECLARE @action		AS nVARCHAR(100) = NULL;
DECLARE @folder		AS nVARCHAR(250) = NULL;
DECLARE @database	AS nVARCHAR(250) = NULL;
DECLARE @filename	AS nVARCHAR(250) = NULL;
DECLARE @filepath	AS nVARCHAR(250) = NULL;


IF (@action IS NULL)	SET @action = N'VERIFY'; 
IF (@folder IS NULL)	SET @folder = N'd:\backups\';
IF (@database IS NULL)	SET @database = DB_NAME();
IF (@filename IS NULL)	SET @filename = @database + '.bak'
IF (@filepath IS NULL)	SET @filepath = @folder + @filename;

-- SELECT @action [@action], @folder [@folder], @database [@database], @filename [@filename], @filepath [@filepath]

-- ==================================================================
-- run
-- ==================================================================

-- backup
IF (@action IN (N'BACKUP'))
BEGIN
	RAISERROR('>> WILL BACKUP ''%s'' TO ''%s''.', 0, 0, @database, @filepath) WITH NOWAIT;
	BACKUP DATABASE @database TO DISK = @filepath WITH FORMAT, INIT, COPY_ONLY, CHECKSUM, SKIP, NOREWIND, NOUNLOAD, COMPRESSION,  STATS = 10
END

-- verify (will allways verify for 'BACKUP')
IF (@action IN ('VERIFY', 'BACKUP'))
BEGIN
	RAISERROR('>> WILL VERIFY BACKUP ''%s'' TO ''%s''.', 0, 0, @database, @filepath) WITH NOWAIT;
	RESTORE VERIFYONLY FROM  DISK = @filepath WITH  FILE = 1,  NOUNLOAD,  NOREWIND
END

-- restore
IF (@action IN ('RESTORE'))
BEGIN
	USE tempdb;
	RAISERROR('>> WILL RESTORE ''%s'' FROM ''%s''.', 0, 0, @database, @filepath) WITH NOWAIT;
	EXEC('ALTER DATABASE [' + @database + '] SET SINGLE_USER WITH ROLLBACK IMMEDIATE;');
	RESTORE DATABASE @database FROM  DISK = @filepath WITH  FILE = 1,  NOUNLOAD,  REPLACE,  STATS = 10
	EXEC('ALTER DATABASE [' + @database + '] SET MULTI_USER;');
END
