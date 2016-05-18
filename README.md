# NativeSqlRegex
Basic regular expression support implemented in native T-SQL. Useful for environments where CLR integration is not an option.

### Examples:
```
IF dbo.RegexIsMatch('234-567-8901', '\d+-\d+-d+') = 1 ...

SET @areaCode = dbo.RegexMatchGroup('234-567-8901', '(\d+)-\d+-d+', 1);
```

### Supported constructs
* Character escapes: **\**
* Character classes: **\s \d \w .**
* Anchors: _not supported yet_
* Grouping: **(**_subexpression_**)**
* Quantifiers: **? * +** _(exact and/or lazy quantifiers not supported yet)_
* Backreference: _not supported yet_
* Alternation: _not supported yet_
* Substitution: _not supported yet_

### References
https://msdn.microsoft.com/en-us/library/az24scfc
