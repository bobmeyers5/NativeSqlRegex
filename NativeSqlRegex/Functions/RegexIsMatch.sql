CREATE FUNCTION dbo.RegexIsMatch(
	@input nvarchar(max),
	@pattern nvarchar(max)
)
RETURNS bit AS
BEGIN
	RETURN CASE WHEN dbo.RegexMatch(@input, @pattern) IS NOT NULL THEN 1 ELSE 0 END;
END
