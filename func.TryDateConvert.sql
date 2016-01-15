
CREATE FUNCTION [TryDateConvert]
(
	@value			NVARCHAR(20),
	@format			TINYINT = 121
)
RETURNS  DATETIME
BEGIN
	-- this function tries to convert a NVARCHAR @value strictly using
	-- the given @format; if it's not possible returns null


	-- this function could be replaced for TRY_CONVERT, since
	-- version 2012  (compatibility level 110 and higher)
	-- [https://msdn.microsoft.com/en-us/library/hh230993.aspx]

	-- local variables
	DECLARE @result		DATETIME;
	DECLARE @roundtrip	NVARCHAR(20);

	-- this quick check avoids error for CONVERT function
	IF (ISDATE(@value) = 0) RETURN NULL;

	SET @result		= CONVERT(DATETIME, @value, @format);
	SET @roundtrip	= CONVERT(NVARCHAR(20), @result, @format);


	-- @roundtrip is the @result converted back to NVARCHAR, using the
	-- same @format; this check prevents conversions that use fallback
	-- formats, that SQL uses when the given @format is not possible;
	-- the @value is verified as substring of @roundtrip to ignore
	-- optional time parts, when they are not provided
	IF NOT (@roundtrip LIKE @value + '%') SET @result = NULL;

	RETURN @result;
END

