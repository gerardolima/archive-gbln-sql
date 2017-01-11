PRINT 'READ THIS SCRIPT BEFORE EXECUTING'
GOTO ENDOFSCRIPT

SET NOCOUNT ON;
USE [tempdb];

-- ============================================================================
-- check if the server is running in windows-authentication-only mode
-- ============================================================================
CREATE TABLE #TMP(value VARCHAR(128), data INT);
INSERT #TMP EXEC xp_instance_regread N'HKEY_LOCAL_MACHINE', N'Software\Microsoft\MSSQLServer\MSSQLServer', N'LoginMode';

SELECT * FROM #TMP
IF NOT EXISTS(SELECT * FROM #TMP WHERE value='LoginMode' AND data=2)
BEGIN
	PRINT 'ATTENTION: this server is running in windows only authentication mode; the service must be RESTARTED after changing this setting';
	EXEC xp_instance_regwrite N'HKEY_LOCAL_MACHINE', N'Software\Microsoft\MSSQLServer\MSSQLServer', N'LoginMode', REG_DWORD, 2;
END
DROP TABLE #TMP;


-- ============================================================================
-- create login for windows group for developers
-- ============================================================================
--USE [master]
--CREATE LOGIN [] FROM WINDOWS WITH DEFAULT_DATABASE=[master]
--ALTER SERVER ROLE [sysadmin] ADD MEMBER [DOMAIN\DEVELOPERS]

-- ============================================================================
-- create sql login (re-creates if exists)
-- ============================================================================
IF EXISTS(SELECT * FROM sys.syslogins WHERE name = 'myUser')
DROP LOGIN [myUser];

CREATE LOGIN [myUser] WITH PASSWORD=N'myPassword', DEFAULT_DATABASE=[tempdb], DEFAULT_LANGUAGE=[us_english], CHECK_EXPIRATION=OFF, CHECK_POLICY=OFF

-- ============================================================================
-- create database user
-- ============================================================================
USE [myDatabase]

IF  EXISTS (SELECT * FROM sys.database_principals WHERE name = N'myUser')
DROP USER [myUser];

CREATE USER [myUser] FOR LOGIN [myUser] WITH DEFAULT_SCHEMA=[dbo];
EXEC sp_addrolemember N'db_owner', N'myUser';

ENDOFSCRIPT:
PRINT 'END'
