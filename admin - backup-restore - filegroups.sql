-- ----------------------------------------------------------------------------
-- create backup
-- ----------------------------------------------------------------------------

	-- IMPORTANT: set filegroup B as read-only
	ALTER DATABASE [SourcingDevelopment] MODIFY FILEGROUP [BINARYFILES] READONLY;

	-- create backup for all filegroups
	BACKUP DATABASE [SourcingDevelopment]
		FILEGROUP = 'PRIMARY',
		FILEGROUP = 'BINARYFILES'
		TO DISK = 'D:\tmp\SNET-11534.bak' WITH FORMAT, INIT, CHECKSUM, COMPRESSION;

	ALTER DATABASE [SourcingDevelopment] MODIFY FILEGROUP [BINARYFILES] READWRITE;
GO

-- ----------------------------------------------------------------------------
-- restore read-write filegroups 
-- ----------------------------------------------------------------------------
	-- restore data from read-write filegroups (use when this data must be returned to a previous state)
	RESTORE DATABASE [SourcingDevelopment] FILEGROUP='PRIMARY'     FROM DISK = 'D:\tmp\SNET-11534.bak' WITH REPLACE, NORECOVERY;
	RESTORE DATABASE [SourcingDevelopment] WITH RECOVERY;

	-- IMPORTANT: revert BINARYFILES as read-write
	ALTER DATABASE [SourcingDevelopment] MODIFY FILEGROUP [BINARYFILES] READWRITE;
GO
