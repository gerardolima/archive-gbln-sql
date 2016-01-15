/*
-- example:
	DECLARE @T VARCHAR(MAX) = REPLICATE('123456789A', 600);
	EXEC [##PRINT] @t, 0, 'лл'
*/
CREATE PROCEDURE [##PRINT] (
	@message	NVARCHAR(MAX),
	@useRaise	BIT				= 0,
	@endOfPage	NVARCHAR(10)	= ''
) AS
BEGIN
	SET NOCOUNT ON;

	-- INFORMATION @pageSize is based on existing limits for the underlying printing method
	-- . RAISERROR limits message to 2,047 characters
	-- . PRINT     limits to 4000 NVARCHAR characters

	-- sanityze parameters
	IF(@endOfPage IS NULL) SET @endOfPage = '';

	-- convenience variables (for LENGTH)
	DECLARE @messageLen		INT;		SET @messageLen		= LEN(@message);
	DECLARE @endOfPageLen	TINYINT;	SET @endOfPageLen	= LEN(@endOfPage);

	-- main variables
	DECLARE @pageSize		SMALLINT;	SET @pageSize	= (CASE WHEN @useRaise = 1 THEN 2000 ELSE 4000 END) - @endOfPageLen;
	DECLARE @pageCount		SMALLINT;	SET @pageCount	= FLOOR(@messageLen / @pageSize) + CASE WHEN @messageLen % @pageSize = 0 THEN 0 ELSE 1 END;
	DECLARE @pageOffset		SMALLINT;	SET @pageOffset	= 0;

	-- print message as "pages"
	WHILE (@pageOffset < @pageCount)
	BEGIN
		DECLARE @pageContent NVARCHAR(4000); SET @pageContent = SUBSTRING(@message, @pageOffset * @pageSize, @pageSize) + @endOfPage;

		IF (@useRaise = 1) RAISERROR(@pageContent, 0, 1) WITH NOWAIT;
		ELSE PRINT @pageContent;

	SET @pageOffset = @pageOffset + 1
	END

END
