CREATE FUNCTION dbo.RegexMatchGroup(
	@input nvarchar(max), 
	@pattern nvarchar(max), 
	@matchIndex int, 
	@groupIndex int
) 
RETURNS nvarchar(max) AS
BEGIN
	RETURN 
		(SELECT [Value] 
		FROM dbo.RegexMatches(@pattern, @input)
		where MatchIndex = @matchIndex
			and GroupIndex = @groupIndex);
END
