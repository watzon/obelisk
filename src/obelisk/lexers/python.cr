require "../lexer"

module Obelisk::Lexers
  # Python language lexer
  # Optimized with regex constants and consolidated string handling
  class Python < RegexLexer
    # ==========================================================================
    # Regex Pattern Constants
    # ==========================================================================

    # Whitespace and comments
    WHITESPACE = /\s+/
    LINE_COMMENT = /#.*?(?=\n|$)/
    SHEBANG = /^#!/

    # String delimiters
    DOUBLE_QUOTE = /"/
    SINGLE_QUOTE = /'/
    TRIPLE_DOUBLE = /"""/
    TRIPLE_SINGLE = /'''/

    # String prefixes
    F_PREFIX = /[fF]/
    R_PREFIX = /[rR]/
    B_PREFIX = /[bB]/

    # Escape sequences (consolidated for all string types)
    ESCAPE_SIMPLE = /\\[\\\"'nrtbfav]/
    ESCAPE_OCTAL = /\\[0-7]{1,3}/
    ESCAPE_HEX = /\\x[0-9a-fA-F]{2}/
    ESCAPE_UNICODE = /\\u[0-9a-fA-F]{4}/
    ESCAPE_UNICODE_LONG = /\\U[0-9a-fA-F]{8}/
    ESCAPE_UNICODE_NAME = /\\N\{[^}]+\}/
    ESCAPE_ANY = /\\./

    # String content patterns
    STRING_DOUBLE_CONTENT = /[^"\\]+/
    STRING_SINGLE_CONTENT = /[^'\\]+/
    STRING_DOUBLE_CONTENT_NO_BRACE = /[^"\\{]+/
    STRING_SINGLE_CONTENT_NO_BRACE = /[^'\\{]+/

    # F-string interpolation
    INTERPOLATION_START = /\{/
    INTERPOLATION_END = /\}/

    # Keywords
    KEYWORDS = /\b(?:False|None|True|and|as|assert|async|await|break|class|continue|def|del|elif|else|except|finally|for|from|global|if|import|in|is|lambda|nonlocal|not|or|pass|raise|return|try|while|with|yield)\b/

    # Built-in functions (simplified from ~80 to most common)
    BUILTINS = /\b(?:abs|all|any|ascii|bin|bool|bytes|callable|chr|classmethod|compile|complex|delattr|dict|dir|divmod|enumerate|eval|filter|float|format|frozenset|getattr|globals|hash|help|hex|id|input|int|isinstance|issubclass|iter|len|list|locals|map|max|min|next|object|oct|open|ord|pow|print|range|repr|reversed|round|set|setattr|slice|sorted|staticmethod|str|sum|super|tuple|type|vars|zip)\b/

    # Magic methods (simplified to most common)
    MAGIC_METHODS = /__(?:init|new|del|repr|str|eq|ne|lt|le|gt|ge|hash|bool|getattr|setattr|iter|len|getitem|setitem|delitem|call|add|sub|mul|truediv|floordiv|mod|pow|neg|pos|abs|invert|int|float|enter|exit|await|aenter|aexit|contains|format|bytes|hash|size|length|getitem|setitem|missing|iter|next|bool|nonzero|index|getitem|setitem|delitem|init|call|reduce|reduce_ex|copy|deepcopy|cmp|rcmp|eq|ne|lt|le|gt|ge|cmp|hash|nonzero|unicode|trunc|floor|ceil|floor|ceil|round|trunc|radd|rsub|rmul|rtruediv|rfloordiv|rmod|rdivmod|rpow|rlshift|rrshift|rand|rxor|ror|iadd|isub|imul|itruediv|ifloordiv|imod|ipow|ilshift|irshift|iand|ixor|ior|concat|repeat|inplace_add|inplace_sub|inplace_multiply|inplace_mod|inplace_truediv|inplace_floordiv|inplace_pow|inplace_lshift|inplace_rshift|inplace_and|inplace_xor|inplace_or|native|getattr_handle|getattribute|setattr|delattr)__/

    # Exceptions (simplified)
    EXCEPTIONS = /\b(?:BaseException|Exception|ArithmeticError|AssertionError|AttributeError|EOFError|FloatingPointError|GeneratorExit|ImportError|IndentationError|IndexError|KeyError|KeyboardInterrupt|MemoryError|ModuleNotFoundError|NameError|NotImplementedError|OSError|OverflowError|RecursionError|ReferenceError|RuntimeError|StopIteration|StopAsyncIteration|SyntaxError|SystemError|TypeError|UnboundLocalError|ValueError|ZeroDivisionError|IOError)\b/

    # Numbers
    NUMBER_BIN = /0[bB][01]+(_[01]+)*/
    NUMBER_OCT = /0[oO][0-7]+(_[0-7]+)*/
    NUMBER_HEX = /0[xX][0-9a-fA-F]+(_[0-9a-fA-F]+)*/
    NUMBER_FLOAT = /\d+\.\d*([eE][+-]?\d+)?/
    NUMBER_FLOAT_LEADING = /\.\d+([eE][+-]?\d+)?/
    NUMBER_EXP = /\d+[eE][+-]?\d+/
    NUMBER_INT = /\d+(_\d+)*/

    # Complex numbers
    NUMBER_COMPLEX = /[jJ]/

    # Decorators
    DECORATOR = /@[\w.]+/

    # Class names (CapitalizedWords)
    CLASS_NAME = /\b[A-Z][a-zA-Z0-9_]*\b/

    # Identifiers
    IDENTIFIER = /[a-zA-Z_]\w*/

    # Function call pattern (lookahead)
    FUNCTION_CALL = /[a-zA-Z_]\w*(?=\s*\()/

    # Operators (ordered: longer patterns first)
    OPERATORS = /[+\-*\/%<>=!&|^~]+|\/\/|\*\*|<<|>>|<=|>=|==|!=/

    # Punctuation
    PUNCTUATION = /[.,;:()\[\]{}|]/
    ARROW = /->/

    def config : LexerConfig
      LexerConfig.new(
        name: "python",
        aliases: ["python", "py", "python3", "py3"],
        filenames: ["*.py", "*.pyw", "*.pyi", "*.pyc", "*.pyo"],
        mime_types: ["text/x-python", "application/x-python"],
        priority: 1.0f32
      )
    end

    def analyze(text : String) : Float32
      score = 0.0f32
      lines = text.lines.first(50)

      lines.each do |line|
        score += 0.2 if line =~ /^\s*import\s+\w+/
        score += 0.2 if line =~ /^\s*from\s+\w+\s+import/
        score += 0.2 if line =~ /^\s*def\s+\w+\s*\(/
        score += 0.2 if line =~ /^\s*class\s+\w+/
        score += 0.15 if line =~ /^\s*async\s+def/
        score += 0.1 if line =~ /^\s*@\w+/
        score += 0.1 if line =~ /^\s*if\s+__name__\s*==\s*["']__main__["']/
        score += 0.1 if line =~ /:\s*$/
        score += 0.05 if line =~ /\bprint\s*\(/
        score += 0.05 if line =~ /\b(True|False|None)\b/
        score += 0.05 if line =~ /\b(and|or|not|is|in)\b/
        score += 0.05 if line =~ /"""/ || line =~ /'''/
        score += 0.05 if line =~ /\bself\b/
        score += 0.05 if line =~ /f["']/
      end

      score -= 0.2 if text =~ /\bfunction\s+\w+/
      score -= 0.2 if text =~ /\bfunc\s+\w+/
      score -= 0.2 if text =~ /\bvoid\s+\w+/
      score -= 0.2 if text =~ /\{\s*$/ && !(text =~ /:\s*$/)

      [score, 1.0f32].min
    end

    # Helper to get common string escape rules
    private def string_escape_rules(token_type : TokenType) : Array(LexerRule)
      [
        LexerRule.new(ESCAPE_SIMPLE, token_type),
        LexerRule.new(ESCAPE_OCTAL, token_type),
        LexerRule.new(ESCAPE_HEX, token_type),
        LexerRule.new(ESCAPE_UNICODE, token_type),
        LexerRule.new(ESCAPE_UNICODE_LONG, token_type),
        LexerRule.new(ESCAPE_UNICODE_NAME, token_type),
        LexerRule.new(ESCAPE_ANY, token_type),
      ]
    end

    # Helper to get f-string rules with interpolation
    private def fstring_rules(quote_token : Regex, quote_type : TokenType, content_pattern : Regex)
      [
        LexerRule.new(quote_token, RuleActions.pop(quote_type)),
        *string_escape_rules(TokenType::LiteralStringEscape),
        LexerRule.new(INTERPOLATION_START, RuleActions.push("fstring_interpolation", TokenType::LiteralStringInterpol)),
        LexerRule.new(content_pattern, quote_type),
      ]
    end

    def rules : Hash(String, Array(LexerRule))
      {
        "root" => [
          LexerRule.new(WHITESPACE, TokenType::Text),
          LexerRule.new(LINE_COMMENT, TokenType::CommentSingle),
          LexerRule.new(SHEBANG, TokenType::CommentHashbang),
          LexerRule.new(KEYWORDS, TokenType::Keyword),
          LexerRule.new(BUILTINS, TokenType::NameBuiltin),
          LexerRule.new(MAGIC_METHODS, TokenType::NameFunctionMagic),
          LexerRule.new(EXCEPTIONS, TokenType::NameException),
          LexerRule.new(DECORATOR, TokenType::NameDecorator),
          LexerRule.new(CLASS_NAME, TokenType::NameClass),
          LexerRule.new(/\b(def)(\s+)([a-zA-Z_]\w*)/, RuleActions.by_groups(TokenType::Keyword, TokenType::Text, TokenType::NameFunction)),
          LexerRule.new(/\b(class)(\s+)([a-zA-Z_]\w*)/, RuleActions.by_groups(TokenType::Keyword, TokenType::Text, TokenType::NameClass)),
          LexerRule.new(NUMBER_BIN, TokenType::LiteralNumberBin),
          LexerRule.new(NUMBER_OCT, TokenType::LiteralNumberOct),
          LexerRule.new(NUMBER_HEX, TokenType::LiteralNumberHex),
          LexerRule.new(NUMBER_FLOAT, TokenType::LiteralNumberFloat),
          LexerRule.new(NUMBER_FLOAT_LEADING, TokenType::LiteralNumberFloat),
          LexerRule.new(NUMBER_EXP, TokenType::LiteralNumberFloat),
          LexerRule.new(NUMBER_INT, TokenType::LiteralNumberInteger),

          # Strings (ordered to match prefixes first)
          LexerRule.new(TRIPLE_DOUBLE, RuleActions.push("string_triple_double", TokenType::LiteralStringDouble)),
          LexerRule.new(TRIPLE_SINGLE, RuleActions.push("string_triple_single", TokenType::LiteralStringSingle)),
          LexerRule.new(/#{F_PREFIX}#{DOUBLE_QUOTE.source}/, RuleActions.push("fstring_double", TokenType::LiteralStringDouble)),
          LexerRule.new(/#{F_PREFIX}#{SINGLE_QUOTE.source}/, RuleActions.push("fstring_single", TokenType::LiteralStringSingle)),
          LexerRule.new(/#{R_PREFIX}#{DOUBLE_QUOTE.source}/, RuleActions.push("raw_string_double", TokenType::LiteralStringDouble)),
          LexerRule.new(/#{R_PREFIX}#{SINGLE_QUOTE.source}/, RuleActions.push("raw_string_single", TokenType::LiteralStringSingle)),
          LexerRule.new(/#{B_PREFIX}#{DOUBLE_QUOTE.source}/, RuleActions.push("byte_string_double", TokenType::LiteralStringOther)),
          LexerRule.new(/#{B_PREFIX}#{SINGLE_QUOTE.source}/, RuleActions.push("byte_string_single", TokenType::LiteralStringOther)),
          LexerRule.new(DOUBLE_QUOTE, RuleActions.push("string_double", TokenType::LiteralStringDouble)),
          LexerRule.new(SINGLE_QUOTE, RuleActions.push("string_single", TokenType::LiteralStringSingle)),

          LexerRule.new(FUNCTION_CALL, TokenType::NameFunction),
          LexerRule.new(IDENTIFIER, TokenType::Name),
          LexerRule.new(OPERATORS, TokenType::Operator),
          LexerRule.new(PUNCTUATION, TokenType::Punctuation),
          LexerRule.new(ARROW, TokenType::Punctuation),
        ],

        "string_double" => [
          LexerRule.new(DOUBLE_QUOTE, RuleActions.pop(TokenType::LiteralStringDouble)),
          *string_escape_rules(TokenType::LiteralStringEscape),
          LexerRule.new(STRING_DOUBLE_CONTENT, TokenType::LiteralStringDouble),
        ],

        "string_single" => [
          LexerRule.new(SINGLE_QUOTE, RuleActions.pop(TokenType::LiteralStringSingle)),
          *string_escape_rules(TokenType::LiteralStringEscape),
          LexerRule.new(STRING_SINGLE_CONTENT, TokenType::LiteralStringSingle),
        ],

        "string_triple_double" => [
          LexerRule.new(TRIPLE_DOUBLE, RuleActions.pop(TokenType::LiteralStringDouble)),
          LexerRule.new(ESCAPE_SIMPLE, TokenType::LiteralStringEscape),
          LexerRule.new(ESCAPE_ANY, TokenType::LiteralStringEscape),
          LexerRule.new(STRING_DOUBLE_CONTENT, TokenType::LiteralStringDouble),
          LexerRule.new(/"(?!"")/, TokenType::LiteralStringDouble),
        ],

        "string_triple_single" => [
          LexerRule.new(TRIPLE_SINGLE, RuleActions.pop(TokenType::LiteralStringSingle)),
          LexerRule.new(ESCAPE_SIMPLE, TokenType::LiteralStringEscape),
          LexerRule.new(ESCAPE_ANY, TokenType::LiteralStringEscape),
          LexerRule.new(STRING_SINGLE_CONTENT, TokenType::LiteralStringSingle),
          LexerRule.new(/'(?!'')/, TokenType::LiteralStringSingle),
        ],

        "fstring_double" => [
          LexerRule.new(DOUBLE_QUOTE, RuleActions.pop(TokenType::LiteralStringDouble)),
          LexerRule.new(ESCAPE_SIMPLE, TokenType::LiteralStringEscape),
          LexerRule.new(ESCAPE_ANY, TokenType::LiteralStringEscape),
          LexerRule.new(INTERPOLATION_START, RuleActions.push("fstring_interpolation", TokenType::LiteralStringInterpol)),
          LexerRule.new(STRING_DOUBLE_CONTENT_NO_BRACE, TokenType::LiteralStringDouble),
        ],

        "fstring_single" => [
          LexerRule.new(SINGLE_QUOTE, RuleActions.pop(TokenType::LiteralStringSingle)),
          LexerRule.new(ESCAPE_SIMPLE, TokenType::LiteralStringEscape),
          LexerRule.new(ESCAPE_ANY, TokenType::LiteralStringEscape),
          LexerRule.new(INTERPOLATION_START, RuleActions.push("fstring_interpolation", TokenType::LiteralStringInterpol)),
          LexerRule.new(STRING_SINGLE_CONTENT_NO_BRACE, TokenType::LiteralStringSingle),
        ],

        "fstring_interpolation" => [
          LexerRule.new(INTERPOLATION_END, RuleActions.pop(TokenType::LiteralStringInterpol)),
          LexerRule.new(INTERPOLATION_START, RuleActions.push("fstring_interpolation", TokenType::LiteralStringInterpol)),
          LexerRule.new(/[^}]+/, TokenType::Text),
        ],

        "raw_string_double" => [
          LexerRule.new(DOUBLE_QUOTE, RuleActions.pop(TokenType::LiteralStringDouble)),
          LexerRule.new(/[^"]+/, TokenType::LiteralStringDouble),
        ],

        "raw_string_single" => [
          LexerRule.new(SINGLE_QUOTE, RuleActions.pop(TokenType::LiteralStringSingle)),
          LexerRule.new(/[^']+/, TokenType::LiteralStringSingle),
        ],

        "byte_string_double" => [
          LexerRule.new(DOUBLE_QUOTE, RuleActions.pop(TokenType::LiteralStringOther)),
          LexerRule.new(ESCAPE_SIMPLE, TokenType::LiteralStringEscape),
          LexerRule.new(ESCAPE_OCTAL, TokenType::LiteralStringEscape),
          LexerRule.new(ESCAPE_HEX, TokenType::LiteralStringEscape),
          LexerRule.new(ESCAPE_ANY, TokenType::LiteralStringEscape),
          LexerRule.new(STRING_DOUBLE_CONTENT, TokenType::LiteralStringOther),
        ],

        "byte_string_single" => [
          LexerRule.new(SINGLE_QUOTE, RuleActions.pop(TokenType::LiteralStringOther)),
          LexerRule.new(ESCAPE_SIMPLE, TokenType::LiteralStringEscape),
          LexerRule.new(ESCAPE_OCTAL, TokenType::LiteralStringEscape),
          LexerRule.new(ESCAPE_HEX, TokenType::LiteralStringEscape),
          LexerRule.new(ESCAPE_ANY, TokenType::LiteralStringEscape),
          LexerRule.new(STRING_SINGLE_CONTENT, TokenType::LiteralStringOther),
        ],
      }
    end
  end
end
