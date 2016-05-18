CREATE FUNCTION dbo.RegexMatchCharExpr (
	@input nvarchar(max),
	@pattern nvarchar(max),
	@charExpr nvarchar(max),
	@likeExpr nvarchar(max),
	@patPos int,
	@inputPos int
)
RETURNS @result TABLE (
	ExprFound bit,
	InputPos int,
	PatternPos int,
	MatchRequired bit,
	MatchFound bit
) AS
BEGIN
	DECLARE @debugMsg nvarchar(max);

	DECLARE @exprFound bit = 0;
	DECLARE @matchRequired bit = 0;
	DECLARE @matchFound bit = 0;

	IF SUBSTRING(@pattern, @patPos, DATALENGTH(@charExpr) / 2) = @charExpr
	BEGIN
		-- Consume the character expression
		SET @exprFound = 1;
		SET @patPos += DATALENGTH(@charExpr) / 2;

		-- Consume quantifier IF present
		DECLARE @qnt nvarchar(max) = SUBSTRING(@pattern, @patPos, 1);
		DECLARE @min int = case when @qnt in (N'?', N'*') then 0 else 1 END;
		DECLARE @max int = case when @qnt in (N'*', N'+') then 999999 else 1 END;
		IF @qnt in (N'?', N'*', N'+')
			SET @patPos += 1;
		else 
			SET @qnt = '';

		-- SET output param indicating whether a string match is required
		IF @min > 0
			SET @matchRequired = 1;

		SET @debugMsg = CONCAT('Matching char expr ''', @charExpr, @qnt, ''' at position ', @inputPos);

		-- Try to match the character expression
		SET @likeExpr = CONCAT(@likeExpr, N'%');
		DECLARE @exprMatchLen int = 0;
		WHILE @inputPos + @exprMatchLen <= (DATALENGTH(@input) / 2) and @exprMatchLen < @max
		BEGIN
			IF SUBSTRING(@input, @inputPos + @exprMatchLen, 1) like @likeExpr escape '\'
				SET @exprMatchLen += 1;
			else 
				break;
		END

		IF @exprMatchLen > 0
		BEGIN
			SET @debugMsg = CONCAT('Match for char expr ''', @charExpr, @qnt, ''' found at position ', @inputPos, ': ''', SUBSTRING(@input, @inputPos, @exprMatchLen), ''' (n=', @exprMatchLen, ')');
			SET @matchFound = 1;
		END

		-- Consume matching characters
		SET @inputPos += @exprMatchLen;
	END

	-- Return result
	INSERT @result (ExprFound, InputPos, PatternPos, MatchRequired, MatchFound)
	VALUES (@exprFound, @inputPos, @patPos, @matchRequired, @matchFound);
	RETURN;
END
