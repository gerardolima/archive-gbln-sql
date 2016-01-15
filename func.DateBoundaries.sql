USE tempdb;
GO

CREATE FUNCTION [FisrtDayOfMonth] (@dt DATETIME)
RETURNS DATETIME
AS BEGIN
	RETURN dateadd(month, datediff(month, 0, @dt), 0);
END
GO

CREATE FUNCTION [LastDayOfMonth] (@dt DATETIME)
RETURNS DATETIME
AS BEGIN
	RETURN dateadd(month, datediff(month, 0, @dt)+1, -1);
END