require "../lexer"

module Obelisk::Lexers
  # SQL language lexer with support for multiple dialects
  class SQL < RegexLexer
    def config : LexerConfig
      LexerConfig.new(
        name: "sql",
        aliases: ["sql", "mysql", "postgresql", "postgres", "sqlite", "mssql", "tsql", "plsql", "oracle"],
        filenames: ["*.sql", "*.ddl", "*.dml"],
        mime_types: ["text/x-sql", "application/x-sql"],
        priority: 1.0f32
      )
    end

    def analyze(text : String) : Float32
      score = 0.0f32
      lines = text.lines.first(50) # Analyze first 50 lines

      # SQL-specific patterns
      lines.each do |line|
        upper_line = line.upcase.strip

        # Strong indicators - SQL statements
        score += 0.4 if upper_line =~ /^\s*(SELECT|INSERT|UPDATE|DELETE|CREATE|DROP|ALTER)\s+/
        score += 0.3 if upper_line =~ /\b(FROM|WHERE|JOIN|ON|GROUP BY|ORDER BY|HAVING)\b/
        score += 0.2 if upper_line =~ /\b(TABLE|VIEW|INDEX|PROCEDURE|FUNCTION|TRIGGER)\b/

        # SQL-specific patterns
        score += 0.2 if upper_line =~ /\b(LIMIT|TOP|OFFSET)\s+\d+/ # LIMIT/TOP clauses
        score += 0.15 if upper_line =~ /\*\s+FROM/                 # SELECT * FROM pattern

        # SQL functions
        score += 0.1 if upper_line =~ /\b(COUNT|SUM|AVG|MAX|MIN|COALESCE|CAST|CONVERT)\s*\(/

        # SQL data types
        score += 0.1 if upper_line =~ /\b(INT|INTEGER|VARCHAR|TEXT|DATE|TIMESTAMP|FLOAT|DECIMAL|BOOLEAN|BLOB)\b/

        # SQL operators and keywords
        score += 0.05 if upper_line =~ /\b(AND|OR|NOT|NULL|IS|IN|EXISTS|BETWEEN|LIKE|AS)\b/

        # SQL comments
        score += 0.05 if line =~ /^\s*--/
        score += 0.05 if line =~ /\/\*/

        # Common SQL patterns
        score += 0.05 if line =~ /;\s*$/  # Statement terminator
        score += 0.02 if line =~ /\(\s*$/ # Opening parenthesis at end of line
        score += 0.02 if line =~ /^\s*\)/ # Closing parenthesis at start of line
      end

      # Negative indicators
      score -= 0.2 if text =~ /\bfunction\s+\w+\s*\(/ # JavaScript/other languages
      score -= 0.2 if text =~ /\bdef\s+\w+/           # Python/Ruby
      score -= 0.2 if text =~ /\bclass\s+\w+/         # OOP languages
      score -= 0.1 if text =~ /\{[\s\S]*\}/           # Curly braces (not typical in SQL)

      # Cap the score at 1.0 and ensure it's at least 0
      [[score, 0.0f32].max, 1.0f32].min
    end

    def rules : Hash(String, Array(LexerRule))
      {
        "root" => [
          # Whitespace
          LexerRule.new(/\s+/, TokenType::TextWhitespace),

          # Comments
          LexerRule.new(/--.*?(?=\n|$)/, TokenType::CommentSingle),
          LexerRule.new(/\/\*/, RuleActions.push("multiline_comment", TokenType::CommentMultiline)),

          # String literals (single quotes)
          LexerRule.new(/'/, RuleActions.push("string_single", TokenType::LiteralStringSingle)),

          # Identifiers with quotes
          LexerRule.new(/"/, RuleActions.push("identifier_double", TokenType::NameOther)),
          LexerRule.new(/`/, RuleActions.push("identifier_backtick", TokenType::NameOther)),
          LexerRule.new(/\[/, RuleActions.push("identifier_bracket", TokenType::NameOther)),

          # Numbers
          LexerRule.new(/\d+\.\d+([eE][+-]?\d+)?/, TokenType::LiteralNumberFloat),
          LexerRule.new(/\d+([eE][+-]?\d+)/, TokenType::LiteralNumberFloat),
          LexerRule.new(/\d+/, TokenType::LiteralNumberInteger),

          # Keywords - Data Definition Language (DDL)
          LexerRule.new(/\b(?i:CREATE|DROP|ALTER|TRUNCATE|RENAME|COMMENT)\b/, TokenType::KeywordReserved),

          # Keywords - Data Manipulation Language (DML)
          LexerRule.new(/\b(?i:SELECT|INSERT|UPDATE|DELETE|MERGE|UPSERT|REPLACE)\b/, TokenType::KeywordReserved),

          # Keywords - Data Control Language (DCL)
          LexerRule.new(/\b(?i:GRANT|REVOKE|DENY)\b/, TokenType::KeywordReserved),

          # Keywords - Transaction Control
          LexerRule.new(/\b(?i:BEGIN|COMMIT|ROLLBACK|SAVEPOINT|START|TRANSACTION|WORK)\b/, TokenType::KeywordReserved),

          # Keywords - Clauses
          LexerRule.new(/\b(?i:FROM|WHERE|JOIN|ON|USING|GROUP\s+BY|ORDER\s+BY|HAVING|LIMIT|OFFSET|FETCH|FOR|UNION|INTERSECT|EXCEPT|MINUS)\b/, TokenType::Keyword),
          LexerRule.new(/\b(?i:INNER|LEFT|RIGHT|FULL|OUTER|CROSS|NATURAL)\b/, TokenType::Keyword),
          LexerRule.new(/\b(?i:ASC|DESC|FIRST|LAST|NULLS)\b/, TokenType::Keyword),

          # Keywords - Object types
          LexerRule.new(/\b(?i:TABLE|VIEW|INDEX|SEQUENCE|TRIGGER|FUNCTION|PROCEDURE|PACKAGE|TYPE|DOMAIN|CONSTRAINT|SCHEMA|DATABASE|TABLESPACE|ROLE|USER)\b/, TokenType::Keyword),

          # Keywords - Constraints and properties
          LexerRule.new(/\b(?i:PRIMARY\s+KEY|FOREIGN\s+KEY|UNIQUE|CHECK|DEFAULT|NOT\s+NULL|NULL|REFERENCES|CASCADE|RESTRICT|NO\s+ACTION|SET\s+NULL|SET\s+DEFAULT)\b/, TokenType::Keyword),

          # Keywords - Other common keywords
          LexerRule.new(/\b(?i:AS|IN|IS|EXISTS|BETWEEN|LIKE|ILIKE|SIMILAR\s+TO|REGEXP|ALL|ANY|SOME|WITH|RECURSIVE|INTO|VALUES|SET|RETURNING|DISTINCT|CASE|WHEN|THEN|ELSE|END)\b/, TokenType::Keyword),

          # Data types
          LexerRule.new(/\b(?i:INT|INTEGER|SMALLINT|BIGINT|DECIMAL|NUMERIC|FLOAT|REAL|DOUBLE\s+PRECISION|MONEY|SMALLMONEY)\b/, TokenType::KeywordType),
          LexerRule.new(/\b(?i:CHAR|VARCHAR|TEXT|NCHAR|NVARCHAR|NTEXT|CHARACTER\s+VARYING|CHARACTER|CLOB|NCLOB)\b/, TokenType::KeywordType),
          LexerRule.new(/\b(?i:DATE|TIME|DATETIME|TIMESTAMP|TIMESTAMPTZ|INTERVAL|YEAR|MONTH|DAY|HOUR|MINUTE|SECOND)\b/, TokenType::KeywordType),
          LexerRule.new(/\b(?i:BOOLEAN|BOOL|BIT|BINARY|VARBINARY|BLOB|BYTEA|UUID|XML|JSON|JSONB|ARRAY|HSTORE)\b/, TokenType::KeywordType),
          LexerRule.new(/\b(?i:SERIAL|BIGSERIAL|SMALLSERIAL|IDENTITY|AUTO_INCREMENT|AUTOINCREMENT)\b/, TokenType::KeywordType),

          # Boolean and null literals
          LexerRule.new(/\b(?i:TRUE|FALSE|NULL|UNKNOWN)\b/, TokenType::KeywordConstant),

          # Bind parameters (must come before operators to match ? correctly)
          LexerRule.new(/\?/, TokenType::NameVariable),    # JDBC style
          LexerRule.new(/:\w+/, TokenType::NameVariable),  # Named parameters
          LexerRule.new(/@\w+/, TokenType::NameVariable),  # SQL Server style
          LexerRule.new(/\$\d+/, TokenType::NameVariable), # PostgreSQL style

          # Operators
          LexerRule.new(/\b(?i:AND|OR|NOT)\b/, TokenType::OperatorWord),
          LexerRule.new(/[+\-*\/%]/, TokenType::Operator),
          LexerRule.new(/[<>=!]+/, TokenType::Operator),
          LexerRule.new(/\|\|/, TokenType::Operator),                    # String concatenation
          LexerRule.new(/::/, TokenType::Operator),                      # PostgreSQL cast
          LexerRule.new(/->|#>|@>|<@|&&|\?\?|\?&/, TokenType::Operator), # JSON/Array operators (removed single ?)

          # Built-in functions
          LexerRule.new(/\b(?i:COUNT|SUM|AVG|MAX|MIN|STDDEV|VARIANCE)\b/, TokenType::NameBuiltin),
          LexerRule.new(/\b(?i:COALESCE|NULLIF|GREATEST|LEAST|NVL|NVL2|DECODE)\b/, TokenType::NameBuiltin),
          LexerRule.new(/\b(?i:CAST|CONVERT|TRY_CAST|TRY_CONVERT|PARSE|TRY_PARSE)\b/, TokenType::NameBuiltin),
          LexerRule.new(/\b(?i:SUBSTRING|SUBSTR|LENGTH|LEN|CHAR_LENGTH|CHARACTER_LENGTH|POSITION|INSTR|LOCATE)\b/, TokenType::NameBuiltin),
          LexerRule.new(/\b(?i:UPPER|LOWER|INITCAP|CONCAT|REPLACE|TRIM|LTRIM|RTRIM|LPAD|RPAD|REVERSE)\b/, TokenType::NameBuiltin),
          LexerRule.new(/\b(?i:ROUND|FLOOR|CEIL|CEILING|ABS|SIGN|MOD|POWER|POW|SQRT|EXP|LOG|LOG10|LN)\b/, TokenType::NameBuiltin),
          LexerRule.new(/\b(?i:NOW|CURRENT_DATE|CURRENT_TIME|CURRENT_TIMESTAMP|GETDATE|SYSDATE|SYSDATETIME)\b/, TokenType::NameBuiltin),
          LexerRule.new(/\b(?i:DATEADD|DATEDIFF|DATEPART|DATE_ADD|DATE_SUB|DATE_DIFF|EXTRACT|DATE_TRUNC)\b/, TokenType::NameBuiltin),
          LexerRule.new(/\b(?i:ROW_NUMBER|RANK|DENSE_RANK|NTILE|LAG|LEAD|FIRST_VALUE|LAST_VALUE)\b/, TokenType::NameBuiltin),
          LexerRule.new(/\b(?i:STRING_AGG|LISTAGG|GROUP_CONCAT|ARRAY_AGG|JSON_AGG|XMLAGG)\b/, TokenType::NameBuiltin),

          # Schema-qualified names (table.column, schema.table, etc.)
          LexerRule.new(/([a-zA-Z_][a-zA-Z0-9_]*)(\.)([ a-zA-Z_][a-zA-Z0-9_]*)/,
            RuleActions.by_groups(TokenType::Name, TokenType::Punctuation, TokenType::Name)),

          # Regular identifiers
          LexerRule.new(/[a-zA-Z_][a-zA-Z0-9_]*/, TokenType::Name),

          # Punctuation
          LexerRule.new(/[().,;]/, TokenType::Punctuation),

          # Everything else is an error
          LexerRule.new(/./, TokenType::Error),
        ],

        "string_single" => [
          LexerRule.new(/'/, RuleActions.pop(TokenType::LiteralStringSingle)),
          LexerRule.new(/''/, TokenType::LiteralStringEscape), # Escaped single quote
          LexerRule.new(/[^']+/, TokenType::LiteralStringSingle),
        ],

        "identifier_double" => [
          LexerRule.new(/"/, RuleActions.pop(TokenType::NameOther)),
          LexerRule.new(/""/, TokenType::LiteralStringEscape), # Escaped double quote
          LexerRule.new(/[^"]+/, TokenType::NameOther),
        ],

        "identifier_backtick" => [
          LexerRule.new(/`/, RuleActions.pop(TokenType::NameOther)),
          LexerRule.new(/``/, TokenType::LiteralStringEscape), # Escaped backtick
          LexerRule.new(/[^`]+/, TokenType::NameOther),
        ],

        "identifier_bracket" => [
          LexerRule.new(/\]/, RuleActions.pop(TokenType::NameOther)),
          LexerRule.new(/\]\]/, TokenType::LiteralStringEscape), # Escaped bracket
          LexerRule.new(/[^\]]+/, TokenType::NameOther),
        ],

        "multiline_comment" => [
          LexerRule.new(/\*\//, RuleActions.pop(TokenType::CommentMultiline)),
          LexerRule.new(/[^*]+/, TokenType::CommentMultiline),
          LexerRule.new(/\*/, TokenType::CommentMultiline),
        ],
      }
    end
  end
end
