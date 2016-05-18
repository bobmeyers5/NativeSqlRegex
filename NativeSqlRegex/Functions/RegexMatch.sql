CREATE FUNCTION dbo.RegexMatch(
	@input nvarchar(max),
	@pattern nvarchar(max)
)
RETURNS nvarchar(max) AS
BEGIN
	RETURN 
		(SELECT [Value] 
		FROM dbo.RegexMatches(@input, @pattern)
		where MatchIndex = 1
			and GroupIndex = 0);
END
