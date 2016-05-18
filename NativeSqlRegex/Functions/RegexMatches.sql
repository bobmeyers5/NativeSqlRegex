CREATE FUNCTION dbo.RegexMatches (
	@input AS nvarchar(max),
	@pattern AS nvarchar(max)
)
RETURNS @patternMatches TABLE (
	MatchIndex int, 
	GroupIndex int, 
	[Start] int, 
	[Count] int, 
	[Value] nvarchar(max)
) AS
BEGIN
	DECLARE @error int;

	DECLARE @inputPos int = 1;
	DECLARE @patPos int = 1;
	DECLARE @patMatchStart int = 1;
	DECLARE @grpMatchStart int = 0;
	DECLARE @grpIndex int = 0;
	DECLARE @patMatchIndex int = 0;

	WHILE @inputPos <= DATALENGTH(@input) / 2 or @patPos > 1
	BEGIN
		DECLARE @charExpr nvarchar(max);
		DECLARE @exprFound bit = 0;
		DECLARE @matchRequired bit = 0;
		DECLARE @matchFound bit = 0;
		DECLARE @matchLen int;
		DECLARE @value nvarchar(max);

		-- Check for the start of a group
		IF SUBSTRING(@pattern, @patPos, 1) = N'('
		BEGIN
			IF @grpMatchStart > 0
				SET @error = CAST('Nested groups are not allowed' AS int); -- throws

			SET @exprFound = 1;
			SET @patPos += 1;
			SET @grpMatchStart = @inputPos;
			SET @grpIndex += 1;
		END

		-- Check for the END of a group
		IF @exprFound = 0 and SUBSTRING(@pattern, @patPos, 1) = N')'
		BEGIN
			IF @grpMatchStart = 0
				SET @error = CAST('Close paren with no matching open paren' AS int); -- throws

			SET @exprFound = 1;
			SET @patPos += 1;
			SET @matchLen = @inputPos - @grpMatchStart;
			SET @value = SUBSTRING(@input, @grpMatchStart, @matchLen);
	
			INSERT @patternMatches (MatchIndex, GroupIndex, [Start], [Count], [Value])
			VALUES (0, @grpIndex, @grpMatchStart, @matchLen, @value) -- 0 indicates group matches are pending full pattern match

			SET @grpMatchStart = 0;
		END

		-- Try to match supported character expressions (including quantifiers)
		IF @exprFound = 0
			SELECT @exprFound = ExprFound, @inputPos = InputPos, @patPos = PatternPos, @matchRequired = MatchRequired, @matchFound = MatchFound
			FROM dbo.RegexMatchCharExpr(@input, @pattern, N'\s', ' ', @patPos, @inputPos); -- TODO: match other whitespace characters

		IF @exprFound = 0 
			SELECT @exprFound = ExprFound, @inputPos = InputPos, @patPos = PatternPos, @matchRequired = MatchRequired, @matchFound = MatchFound
			FROM dbo.RegexMatchCharExpr(@input, @pattern, N'\d', '[0-9]', @patPos, @inputPos);

		IF @exprFound = 0 
			SELECT @exprFound = ExprFound, @inputPos = InputPos, @patPos = PatternPos, @matchRequired = MatchRequired, @matchFound = MatchFound
			FROM dbo.RegexMatchCharExpr(@input, @pattern, N'\w', '[a-zA-Z_0-9]', @patPos, @inputPos); -- ECMAScript definition of a word character

		IF @exprFound = 0 
			SELECT @exprFound = ExprFound, @inputPos = InputPos, @patPos = PatternPos, @matchRequired = MatchRequired, @matchFound = MatchFound
			FROM dbo.RegexMatchCharExpr(@input, @pattern, N'\w', '[^a-zA-Z_0-9]', @patPos, @inputPos); -- ECMAScript definition of a non-word character

		-- NOTE: This expr is needed for a specific project. Would be nice to fully support positive/negative character groups
		IF @exprFound = 0 
			SELECT @exprFound = ExprFound, @inputPos = InputPos, @patPos = PatternPos, @matchRequired = MatchRequired, @matchFound = MatchFound
			FROM dbo.RegexMatchCharExpr(@input, @pattern, N'[a-zA-Z0-9-]', '[a-zA-Z0-9-]', @patPos, @inputPos);

		-- NOTE: This expr is needed for a specific project. Would be nice to fully support positive/negative character groups
		IF @exprFound = 0 
			SELECT @exprFound = ExprFound, @inputPos = InputPos, @patPos = PatternPos, @matchRequired = MatchRequired, @matchFound = MatchFound
			FROM dbo.RegexMatchCharExpr(@input, @pattern, N'[^\]]', '[^\]]', @patPos, @inputPos);

		IF @exprFound = 0 
			SELECT @exprFound = ExprFound, @inputPos = InputPos, @patPos = PatternPos, @matchRequired = MatchRequired, @matchFound = MatchFound
			FROM dbo.RegexMatchCharExpr(@input, @pattern, N'.', '_', @patPos, @inputPos);

		IF @exprFound = 0
		BEGIN
			SET @charExpr = SUBSTRING(@pattern, @patPos, 2);
			IF @charExpr like '\_' -- character escape
				SELECT @exprFound = ExprFound, @inputPos = InputPos, @patPos = PatternPos, @matchRequired = MatchRequired, @matchFound = MatchFound
				FROM dbo.RegexMatchCharExpr(@input, @pattern, @charExpr, @charExpr, @patPos, @inputPos);
		END

		IF @exprFound = 0
		BEGIN
			SET @charExpr = SUBSTRING(@pattern, @patPos, 1);
			IF CHARINDEX(@charExpr, N'?*+[]^{}$()|') = 0 -- special regex characters that should be escaped
				SELECT @exprFound = ExprFound, @inputPos = InputPos, @patPos = PatternPos, @matchRequired = MatchRequired, @matchFound = MatchFound
				FROM dbo.RegexMatchCharExpr(@input, @pattern, @charExpr, @charExpr, @patPos, @inputPos);
		END

		IF @exprFound = 0 
			SET @error = CAST('Unknown char expression' AS int); -- throws

		-- Check if required match not found -OR- full pattern match to empty string
		SET @matchLen = @inputPos - @patMatchStart;
		IF (@matchRequired = 1 and @matchFound = 0) or (@patPos > DATALENGTH(@pattern) / 2 and @matchLen = 0)
		BEGIN
			-- Consume non-matching character
			SET @inputPos += 1;

			-- Delete pending group matches since the full pattern match failed
			IF @grpIndex > 0
				DELETE FROM @patternMatches WHERE MatchIndex = 0;

			-- Reset pattern matching
			SET @patPos = 1;
			SET @patMatchStart = @inputPos;
			SET @grpMatchStart = 0;
			SET @grpIndex = 0;
			CONTINUE;
		END

		-- Check if full pattern matched to a non-empty string
		IF @patPos > DATALENGTH(@pattern) / 2
		BEGIN
			IF @grpMatchStart > 0
				SET @error = CAST('Open paren with no matching close paren' AS int); -- throws
				
			SET @value = SUBSTRING(@input, @patMatchStart, @matchLen);
			SET @patMatchIndex += 1;

			-- Add pattern match to results
			INSERT @patternMatches (MatchIndex, GroupIndex, [Start], [Count], [Value])
			VALUES (@patMatchIndex, 0, @patMatchStart, @matchLen, @value);

			-- Update match index for pending group matches
			update @patternMatches
			SET MatchIndex = @patMatchIndex
			where MatchIndex = 0;

			-- Reset pattern matching
			SET @patPos = 1;
			SET @patMatchStart = @inputPos;
			SET @grpMatchStart = 0;
			SET @grpIndex = 0;
		END
	END

	RETURN;
END
