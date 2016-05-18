select * from RegexMatches('',				'\s')
select * from RegexMatches(' ',				'\s')
select * from RegexMatches('ab12',			'\s')
select * from RegexMatches('123',			'\d+')
select * from RegexMatches('1',				'\d\d?')
select * from RegexMatches('12',			'\d\d?')
select * from RegexMatches('123',			'\d\d?')
select * from RegexMatches('',				'\d*')
select * from RegexMatches('123',			'\d*')
select * from RegexMatches('',				'\d+')
select * from RegexMatches('123',			'\d+')
select * from RegexMatches('ab123 #',		'\d+')
select * from RegexMatches('.123-45x6',		'\d+')
select * from RegexMatches('abc ABC 123 aB-c2-D5', '[a-zA-Z0-9-]+')
select * from RegexMatches('xx 123ab xx',	'\s*(\d+)')
select * from RegexMatches('xx 123ab xx',	'(\d+)\s*')
select * from RegexMatches('[].*+',			'\[\].\*\+')

select dbo.RegexIsMatch('abc123', '\w+')


declare @values table (x nvarchar(50));

WITH n1 (x) AS
(
	SELECT 1 UNION ALL SELECT 1 UNION ALL SELECT 1 UNION ALL SELECT 1 UNION ALL SELECT 1 UNION ALL 
	SELECT 1 UNION ALL SELECT 1 UNION ALL SELECT 1 UNION ALL SELECT 1 UNION ALL SELECT 1
),										-- 10^1 or 10 rows
n2 (x) AS (SELECT 1 FROM n1 a CROSS JOIN n1 b),	-- 10^2 or 100 rows
n4 (x) AS (SELECT 1 FROM n2 a CROSS JOIN n2 b),	-- 10^4 or 10,000 rows
n8 (x) AS (SELECT 1 FROM n4 a CROSS JOIN n4 b),	-- 10^8 or 100,000,000 rows
Tally AS (SELECT ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS Value FROM n8)
insert @values (x)
select 
	'  ' + CAST(ABS(CHECKSUM(NEWID())) % 100000 AS nvarchar(max)) + 'abcdef'
from Tally t
where t.Value < 1000

--select * from @values

declare @start datetime2 = SYSUTCDATETIME();

declare @n int = (select count(*) --v.x, mv.Value
from @values v
	cross apply (select top 1 m.Value from dbo.RegexMatches(v.x, '\s+(\d+)\w') m where m.MatchIndex = 1 and m.GroupIndex = 1) mv)

declare @elapsed float = DATEDIFF(MICROSECOND, @start, SYSUTCDATETIME()) / 1000.0;

select @n Iterations, @elapsed Elapsed, @n / (@elapsed / 1000) IterationsPerSecond;
