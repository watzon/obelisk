require "../lexer"

module Obelisk::Lexers
  # JavaScript/TypeScript language lexer
  # Optimized for performance using Chroma-like simple patterns
  class JavaScript < RegexLexer
    # ==========================================================================
    # Regex Pattern Constants
    # Simplified patterns matching Chroma's approach for better performance
    # ==========================================================================

    # Whitespace and comments
    WHITESPACE = /\s+/
    LINE_COMMENT = /\/\/.*?(?=\n|$)/
    BLOCK_COMMENT_START = /\/\*/
    BLOCK_COMMENT_END = /\*\//

    # String delimiters
    DOUBLE_QUOTE = /"/
    SINGLE_QUOTE = /'/
    BACKTICK = /`/

    # Escape sequences (shared across string states)
    ESCAPE_SEQUENCE = /\\[\\\"'nrtbfv]|\\x[0-9a-fA-F]{2}|\\u[0-9a-fA-F]{4}|\\u\{[0-9a-fA-F]+\}|\\[0-7]{1,3}|\\./

    # String content patterns (excluding escape sequences and quotes)
    STRING_DOUBLE_CONTENT = /[^"\\]+/
    STRING_SINGLE_CONTENT = /[^'\\]+/
    STRING_BACKTICK_CONTENT = /[^`\\$]+/

    # Numbers (simplified from 7 to 3 patterns, matching Chroma)
    NUMBER_FLOAT = /[0-9][0-9]*\.[0-9]+([eE][0-9]+)?[fd]?/
    NUMBER_HEX = /0x[0-9a-fA-F]+/
    NUMBER_INT = /[0-9]+/

    # Keywords (simplified - one pattern vs Chroma's multiple patterns)
    KEYWORDS = /\b(?:break|case|catch|class|const|continue|debugger|default|delete|do|else|export|extends|finally|for|function|if|import|in|instanceof|let|new|return|super|switch|this|throw|try|typeof|var|void|while|with|yield)\b/

    # TypeScript keywords
    TYPESCRIPT_KEYWORDS = /\b(?:abstract|async|await|constructor|declare|enum|from|get|implements|interface|namespace|readonly|set)\b/

    # Reserved/declaration keywords
    KEYWORDS_RESERVED = /\b(?:abstract|async|boolean|class|const|debugger|enum|export|extends|from|get|global|goto|implements|import|interface|package|private|protected|public|readonly|require|set|static|super|type)\b/

    # Constants (simplified from Obelisk's pattern)
    CONSTANTS = /\b(?:true|false|null|NaN|Infinity|undefined)\b/

    # Builtin objects (simplified to ~24 names like Chroma, vs Obelisk's 40+)
    # Note: Chroma includes: Array, Boolean, Date, Error, Function, Math, Number,
    # Object, RegExp, String, decodeURI, decodeURIComponent, encodeURI,
    # encodeURIComponent, eval, isFinite, isNaN, parseFloat, parseInt, document, this, window
    BUILTIN_OBJECTS = /\b(?:Array|Boolean|Date|Error|Function|Math|Number|Object|RegExp|String|decodeURI|decodeURIComponent|encodeURI|encodeURIComponent|eval|isFinite|isNaN|parseFloat|parseInt|document|this|window)\b/

    # Operators - must include compound operators before single chars
    # Note: ? is NOT in single-char class as it's only used in ??, ??= operators
    # Order matters: longer patterns first to avoid splitting
    OPERATORS = /\+\+|--|\*\*|\.\?|\?\?|\?\?=|&&|\|\||<<|>>>?|===|!==|==|!=|<=|>=|\+=|-=|\*=|\/=|%=|<<=|>>=|>>>=|&=|\|=|\^=|=>|[+\-*\/%<>=!&|^~.]/

    # Punctuation (dot is handled separately to support optional chaining ?. operator)
    PUNCTUATION = /[,;:()\[\]{}|]/

    # Template literal interpolation
    INTERPOLATION_START = /\$\{/
    INTERPOLATION_END = /\}/
    LONE_DOLLAR = /\$/

    # Generic identifier (Chroma approach - most identifiers are just "names")
    IDENTIFIER = /[a-zA-Z_$][a-zA-Z0-9_$]*/

    # Regular expression literal (simplified - not context-aware like a real parser)
    # This may have false positives but is much faster than full context tracking
    REGEX_LITERAL = /\/(?:[^\/\\\n]|\\.)+\/[gimsuvy]*/

    def config : LexerConfig
      LexerConfig.new(
        name: "javascript",
        aliases: ["javascript", "js", "typescript", "ts", "jsx", "tsx"],
        filenames: ["*.js", "*.mjs", "*.cjs", "*.jsx", "*.ts", "*.tsx", "*.d.ts"],
        mime_types: ["text/javascript", "application/javascript", "text/typescript", "application/typescript"],
        priority: 1.0f32
      )
    end

    def analyze(text : String) : Float32
      score = 0.0f32
      lines = text.lines.first(50) # Analyze first 50 lines

      # JavaScript/TypeScript-specific patterns
      lines.each do |line|
        # Strong indicators
        score += 0.2 if line =~ /^\s*function\s+\w+/
        score += 0.2 if line =~ /^\s*const\s+\w+\s*=/
        score += 0.2 if line =~ /^\s*let\s+\w+\s*=/
        score += 0.2 if line =~ /^\s*var\s+\w+\s*=/
        score += 0.2 if line =~ /^\s*class\s+\w+/
        score += 0.15 if line =~ /^\s*import\s+.+\s+from\s+["']/
        score += 0.15 if line =~ /^\s*export\s+(default\s+)?/
        score += 0.15 if line =~ /^\s*async\s+function/
        score += 0.1 if line =~ /^\s*interface\s+\w+/ # TypeScript
        score += 0.1 if line =~ /^\s*type\s+\w+\s*=/  # TypeScript
        score += 0.1 if line =~ /^\s*enum\s+\w+/      # TypeScript

        # JavaScript-specific syntax
        score += 0.1 if line =~ /=>/ # Arrow functions
        score += 0.05 if line =~ /\bconsole\.\w+/
        score += 0.05 if line =~ /\b(true|false|null|undefined)\b/
        score += 0.05 if line =~ /\b(typeof|instanceof)\b/
        score += 0.05 if line =~ /\$\{.*\}/ # Template literals
        score += 0.05 if line =~ /`.*`/     # Template literals
        score += 0.05 if line =~ /\bawait\s+/
        score += 0.05 if line =~ /\bnew\s+\w+/
      end

      # Negative indicators (not JavaScript)
      score -= 0.2 if text =~ /\bdef\s+\w+:/                         # Python
      score -= 0.2 if text =~ /\bfunc\s+\w+/                         # Go
      score -= 0.2 if text =~ /\bend\b/ && !(text =~ /\bfunction\b/) # Ruby

      # Cap the score at 1.0
      [score, 1.0f32].min
    end

    # Cache rules to avoid recreating the Hash on every token
    @@rules : Hash(String, Array(LexerRule))?

    def rules : Hash(String, Array(LexerRule))
      @@rules ||= {
        "root" => [
          # Whitespace
          LexerRule.new(WHITESPACE, TokenType::Text),

          # Comments
          LexerRule.new(LINE_COMMENT, TokenType::CommentSingle),
          LexerRule.new(BLOCK_COMMENT_START, RuleActions.push("multiline_comment", TokenType::CommentMultiline)),

          # Keywords
          LexerRule.new(KEYWORDS, TokenType::Keyword),

          # TypeScript keywords
          LexerRule.new(TYPESCRIPT_KEYWORDS, TokenType::Keyword),

          # Reserved words
          LexerRule.new(KEYWORDS_RESERVED, TokenType::KeywordReserved),

          # Constants
          LexerRule.new(CONSTANTS, TokenType::KeywordConstant),

          # Built-in objects
          # NOTE: Large alternations like this contribute to slow performance
          LexerRule.new(BUILTIN_OBJECTS, TokenType::NameBuiltin),

          # Numbers
          LexerRule.new(NUMBER_HEX, TokenType::LiteralNumberHex),
          LexerRule.new(NUMBER_FLOAT, TokenType::LiteralNumberFloat),
          LexerRule.new(NUMBER_INT, TokenType::LiteralNumberInteger),

          # Strings
          LexerRule.new(DOUBLE_QUOTE, RuleActions.push("string_double", TokenType::LiteralStringDouble)),
          LexerRule.new(SINGLE_QUOTE, RuleActions.push("string_single", TokenType::LiteralStringSingle)),
          LexerRule.new(BACKTICK, RuleActions.push("template_string", TokenType::LiteralStringBacktick)),

          # Regular expressions (simplified - not truly context-aware)
          LexerRule.new(REGEX_LITERAL, TokenType::LiteralStringRegex),

          # Generic identifier (Chroma's approach - keeps it simple)
          LexerRule.new(IDENTIFIER, TokenType::Name),

          # Operators
          LexerRule.new(OPERATORS, TokenType::Operator),
          LexerRule.new(PUNCTUATION, TokenType::Punctuation),
        ],

        "multiline_comment" => [
          LexerRule.new(BLOCK_COMMENT_END, RuleActions.pop(TokenType::CommentMultiline)),
          LexerRule.new(/[^*]+/, TokenType::CommentMultiline),
          LexerRule.new(/\*/, TokenType::CommentMultiline),
        ],

        "string_double" => [
          LexerRule.new(DOUBLE_QUOTE, RuleActions.pop(TokenType::LiteralStringDouble)),
          LexerRule.new(ESCAPE_SEQUENCE, TokenType::LiteralStringEscape),
          LexerRule.new(STRING_DOUBLE_CONTENT, TokenType::LiteralStringDouble),
        ],

        "string_single" => [
          LexerRule.new(SINGLE_QUOTE, RuleActions.pop(TokenType::LiteralStringSingle)),
          LexerRule.new(ESCAPE_SEQUENCE, TokenType::LiteralStringEscape),
          LexerRule.new(STRING_SINGLE_CONTENT, TokenType::LiteralStringSingle),
        ],

        "template_string" => [
          LexerRule.new(BACKTICK, RuleActions.pop(TokenType::LiteralStringBacktick)),
          LexerRule.new(ESCAPE_SEQUENCE, TokenType::LiteralStringEscape),
          LexerRule.new(INTERPOLATION_START, RuleActions.push("template_interpolation", TokenType::LiteralStringInterpol)),
          LexerRule.new(STRING_BACKTICK_CONTENT, TokenType::LiteralStringBacktick),
          LexerRule.new(LONE_DOLLAR, TokenType::LiteralStringBacktick),
        ],

        "template_interpolation" => [
          LexerRule.new(INTERPOLATION_END, RuleActions.pop(TokenType::LiteralStringInterpol)),
          # Simplified - in reality we'd recursively parse JavaScript expressions
          LexerRule.new(/[^}]+/, TokenType::Text),
        ],
      }
    end
  end
end
