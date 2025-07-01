require "../lexer"

module Obelisk::Lexers
  # Python language lexer
  class Python < RegexLexer
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
      lines = text.lines.first(50) # Analyze first 50 lines
      
      # Python-specific patterns
      lines.each do |line|
        # Strong indicators
        score += 0.2 if line =~ /^\s*import\s+\w+/
        score += 0.2 if line =~ /^\s*from\s+\w+\s+import/
        score += 0.2 if line =~ /^\s*def\s+\w+\s*\(/
        score += 0.2 if line =~ /^\s*class\s+\w+/
        score += 0.15 if line =~ /^\s*async\s+def/
        score += 0.1 if line =~ /^\s*@\w+/ # Decorators
        score += 0.1 if line =~ /^\s*if\s+__name__\s*==\s*["']__main__["']:/
        
        # Python-specific syntax
        score += 0.1 if line =~ /:\s*$/  # Colon at end of line
        score += 0.05 if line =~ /\bprint\s*\(/
        score += 0.05 if line =~ /\b(True|False|None)\b/
        score += 0.05 if line =~ /\b(and|or|not|is|in)\b/
        score += 0.05 if line =~ /"""/ # Triple quotes
        score += 0.05 if line =~ /'''/ # Triple quotes
        score += 0.05 if line =~ /\bself\b/ # self parameter
        score += 0.05 if line =~ /f["']/ # f-strings
      end
      
      # Negative indicators (not Python)
      score -= 0.2 if text =~ /\bfunction\s+\w+/  # JavaScript
      score -= 0.2 if text =~ /\bfunc\s+\w+/      # Go
      score -= 0.2 if text =~ /\bvoid\s+\w+/      # C/C++/Java
      score -= 0.2 if text =~ /\{\s*$/ && !(text =~ /:\s*$/) # Braces without colons
      
      # Cap the score at 1.0
      [score, 1.0f32].min
    end

    def rules : Hash(String, Array(LexerRule))
      {
        "root" => [
          # Whitespace
          LexerRule.new(/\s+/, TokenType::Text),
          
          # Comments
          LexerRule.new(/#.*?(?=\n|$)/, TokenType::CommentSingle),
          
          # Shebang
          LexerRule.new(/^#!/, TokenType::CommentHashbang),
          
          # Keywords
          LexerRule.new(/\b(?:False|None|True|and|as|assert|async|await|break|class|continue|def|del|elif|else|except|finally|for|from|global|if|import|in|is|lambda|nonlocal|not|or|pass|raise|return|try|while|with|yield)\b/, TokenType::Keyword),
          
          # Built-in functions
          LexerRule.new(/\b(?:abs|all|any|ascii|bin|bool|bytearray|bytes|callable|chr|classmethod|compile|complex|delattr|dict|dir|divmod|enumerate|eval|exec|filter|float|format|frozenset|getattr|globals|hasattr|hash|help|hex|id|input|int|isinstance|issubclass|iter|len|list|locals|map|max|memoryview|min|next|object|oct|open|ord|pow|print|property|range|repr|reversed|round|set|setattr|slice|sorted|staticmethod|str|sum|super|tuple|type|vars|zip|__import__)\b/, TokenType::NameBuiltin),
          
          # Magic methods
          LexerRule.new(/__(?:init|new|del|repr|str|bytes|format|lt|le|eq|ne|gt|ge|hash|bool|getattr|getattribute|setattr|delattr|dir|get|set|delete|call|len|length_hint|getitem|setitem|delitem|iter|reversed|contains|add|sub|mul|matmul|truediv|floordiv|mod|divmod|pow|lshift|rshift|and|xor|or|radd|rsub|rmul|rmatmul|rtruediv|rfloordiv|rmod|rdivmod|rpow|rlshift|rrshift|rand|rxor|ror|iadd|isub|imul|imatmul|itruediv|ifloordiv|imod|ipow|ilshift|irshift|iand|ixor|ior|neg|pos|abs|invert|complex|int|float|index|round|trunc|floor|ceil|enter|exit|await|aiter|anext|aenter|aexit)__/, TokenType::NameFunctionMagic),
          
          # Exceptions
          LexerRule.new(/\b(?:BaseException|Exception|ArithmeticError|BufferError|LookupError|AssertionError|AttributeError|EOFError|FloatingPointError|GeneratorExit|ImportError|ModuleNotFoundError|IndexError|KeyError|KeyboardInterrupt|MemoryError|NameError|NotImplementedError|OSError|OverflowError|RecursionError|ReferenceError|RuntimeError|StopIteration|StopAsyncIteration|SyntaxError|IndentationError|TabError|SystemError|SystemExit|TypeError|UnboundLocalError|UnicodeError|UnicodeEncodeError|UnicodeDecodeError|UnicodeTranslateError|ValueError|ZeroDivisionError|EnvironmentError|IOError|WindowsError)\b/, TokenType::NameException),
          
          # Decorators
          LexerRule.new(/@[\w.]+/, TokenType::NameDecorator),
          
          # Class names
          LexerRule.new(/\b[A-Z][a-zA-Z0-9_]*\b/, TokenType::NameClass),
          
          # Function/method definitions
          LexerRule.new(/\b(def)(\s+)([a-zA-Z_]\w*)/, RuleActions.by_groups(TokenType::Keyword, TokenType::Text, TokenType::NameFunction)),
          LexerRule.new(/\b(class)(\s+)([a-zA-Z_]\w*)/, RuleActions.by_groups(TokenType::Keyword, TokenType::Text, TokenType::NameClass)),
          
          # Numbers
          LexerRule.new(/0[bB][01]+(_[01]+)*/, TokenType::LiteralNumberBin),
          LexerRule.new(/0[oO][0-7]+(_[0-7]+)*/, TokenType::LiteralNumberOct),
          LexerRule.new(/0[xX][0-9a-fA-F]+(_[0-9a-fA-F]+)*/, TokenType::LiteralNumberHex),
          LexerRule.new(/\d+\.\d*([eE][+-]?\d+)?/, TokenType::LiteralNumberFloat),
          LexerRule.new(/\.\d+([eE][+-]?\d+)?/, TokenType::LiteralNumberFloat),
          LexerRule.new(/\d+[eE][+-]?\d+/, TokenType::LiteralNumberFloat),
          LexerRule.new(/\d+(_\d+)*/, TokenType::LiteralNumberInteger),
          
          # Complex numbers
          LexerRule.new(/\d+\.\d*([eE][+-]?\d+)?[jJ]/, TokenType::LiteralNumber),
          LexerRule.new(/\.\d+([eE][+-]?\d+)?[jJ]/, TokenType::LiteralNumber),
          LexerRule.new(/\d+[eE][+-]?\d+[jJ]/, TokenType::LiteralNumber),
          LexerRule.new(/\d+[jJ]/, TokenType::LiteralNumber),
          
          # Strings
          # Triple quoted strings first (they can span multiple lines)
          LexerRule.new(/"""/, RuleActions.push("string_triple_double", TokenType::LiteralStringDouble)),
          LexerRule.new(/'''/, RuleActions.push("string_triple_single", TokenType::LiteralStringSingle)),
          
          # F-strings
          LexerRule.new(/[fF]"/, RuleActions.push("fstring_double", TokenType::LiteralStringDouble)),
          LexerRule.new(/[fF]'/, RuleActions.push("fstring_single", TokenType::LiteralStringSingle)),
          
          # Raw strings
          LexerRule.new(/[rR]"/, RuleActions.push("raw_string_double", TokenType::LiteralStringDouble)),
          LexerRule.new(/[rR]'/, RuleActions.push("raw_string_single", TokenType::LiteralStringSingle)),
          
          # Byte strings
          LexerRule.new(/[bB]"/, RuleActions.push("byte_string_double", TokenType::LiteralStringOther)),
          LexerRule.new(/[bB]'/, RuleActions.push("byte_string_single", TokenType::LiteralStringOther)),
          
          # Regular strings
          LexerRule.new(/"/, RuleActions.push("string_double", TokenType::LiteralStringDouble)),
          LexerRule.new(/'/, RuleActions.push("string_single", TokenType::LiteralStringSingle)),
          
          # Function calls and names
          LexerRule.new(/[a-zA-Z_]\w*(?=\s*\()/, TokenType::NameFunction),
          LexerRule.new(/[a-zA-Z_]\w*/, TokenType::Name),
          
          # Operators
          LexerRule.new(/[+\-*\/%<>=!&|^~]+/, TokenType::Operator),
          LexerRule.new(/\/\//, TokenType::Operator), # Floor division
          LexerRule.new(/\*\*/, TokenType::Operator), # Exponentiation
          LexerRule.new(/<<|>>/, TokenType::Operator), # Bit shift
          LexerRule.new(/<=|>=|==|!=/, TokenType::Operator),
          LexerRule.new(/[.,;:()\[\]{}]/, TokenType::Punctuation),
          LexerRule.new(/->/, TokenType::Punctuation), # Function annotation
        ],
        
        "string_double" => [
          LexerRule.new(/"/, RuleActions.pop(TokenType::LiteralStringDouble)),
          LexerRule.new(/\\[\\\"'nrtbfav]/, TokenType::LiteralStringEscape),
          LexerRule.new(/\\[0-7]{1,3}/, TokenType::LiteralStringEscape),
          LexerRule.new(/\\x[0-9a-fA-F]{2}/, TokenType::LiteralStringEscape),
          LexerRule.new(/\\u[0-9a-fA-F]{4}/, TokenType::LiteralStringEscape),
          LexerRule.new(/\\U[0-9a-fA-F]{8}/, TokenType::LiteralStringEscape),
          LexerRule.new(/\\N\{[^}]+\}/, TokenType::LiteralStringEscape),
          LexerRule.new(/\\./, TokenType::LiteralStringEscape),
          LexerRule.new(/[^"\\]+/, TokenType::LiteralStringDouble),
        ],
        
        "string_single" => [
          LexerRule.new(/'/, RuleActions.pop(TokenType::LiteralStringSingle)),
          LexerRule.new(/\\[\\\'nrtbfav]/, TokenType::LiteralStringEscape),
          LexerRule.new(/\\[0-7]{1,3}/, TokenType::LiteralStringEscape),
          LexerRule.new(/\\x[0-9a-fA-F]{2}/, TokenType::LiteralStringEscape),
          LexerRule.new(/\\u[0-9a-fA-F]{4}/, TokenType::LiteralStringEscape),
          LexerRule.new(/\\U[0-9a-fA-F]{8}/, TokenType::LiteralStringEscape),
          LexerRule.new(/\\N\{[^}]+\}/, TokenType::LiteralStringEscape),
          LexerRule.new(/\\./, TokenType::LiteralStringEscape),
          LexerRule.new(/[^'\\]+/, TokenType::LiteralStringSingle),
        ],
        
        "string_triple_double" => [
          LexerRule.new(/"""/, RuleActions.pop(TokenType::LiteralStringDouble)),
          LexerRule.new(/\\[\\\"'nrtbfav]/, TokenType::LiteralStringEscape),
          LexerRule.new(/\\./, TokenType::LiteralStringEscape),
          LexerRule.new(/[^"\\]+/, TokenType::LiteralStringDouble),
          LexerRule.new(/"(?!"")/, TokenType::LiteralStringDouble),
        ],
        
        "string_triple_single" => [
          LexerRule.new(/'''/, RuleActions.pop(TokenType::LiteralStringSingle)),
          LexerRule.new(/\\[\\\'nrtbfav]/, TokenType::LiteralStringEscape),
          LexerRule.new(/\\./, TokenType::LiteralStringEscape),
          LexerRule.new(/[^'\\]+/, TokenType::LiteralStringSingle),
          LexerRule.new(/'(?!'')/, TokenType::LiteralStringSingle),
        ],
        
        "fstring_double" => [
          LexerRule.new(/"/, RuleActions.pop(TokenType::LiteralStringDouble)),
          LexerRule.new(/\\[\\\"'nrtbfav]/, TokenType::LiteralStringEscape),
          LexerRule.new(/\\./, TokenType::LiteralStringEscape),
          LexerRule.new(/\{/, RuleActions.push("fstring_interpolation", TokenType::LiteralStringInterpol)),
          LexerRule.new(/[^"\\{]+/, TokenType::LiteralStringDouble),
        ],
        
        "fstring_single" => [
          LexerRule.new(/'/, RuleActions.pop(TokenType::LiteralStringSingle)),
          LexerRule.new(/\\[\\\'nrtbfav]/, TokenType::LiteralStringEscape),
          LexerRule.new(/\\./, TokenType::LiteralStringEscape),
          LexerRule.new(/\{/, RuleActions.push("fstring_interpolation", TokenType::LiteralStringInterpol)),
          LexerRule.new(/[^'\\{]+/, TokenType::LiteralStringSingle),
        ],
        
        "fstring_interpolation" => [
          LexerRule.new(/\}/, RuleActions.pop(TokenType::LiteralStringInterpol)),
          LexerRule.new(/\{/, RuleActions.push("fstring_interpolation", TokenType::LiteralStringInterpol)), # Nested
          # Simplified - in reality we'd recursively parse Python expressions
          LexerRule.new(/[^}]+/, TokenType::Text),
        ],
        
        "raw_string_double" => [
          LexerRule.new(/"/, RuleActions.pop(TokenType::LiteralStringDouble)),
          LexerRule.new(/[^"]+/, TokenType::LiteralStringDouble),
        ],
        
        "raw_string_single" => [
          LexerRule.new(/'/, RuleActions.pop(TokenType::LiteralStringSingle)),
          LexerRule.new(/[^']+/, TokenType::LiteralStringSingle),
        ],
        
        "byte_string_double" => [
          LexerRule.new(/"/, RuleActions.pop(TokenType::LiteralStringOther)),
          LexerRule.new(/\\[\\\"'nrtbfav]/, TokenType::LiteralStringEscape),
          LexerRule.new(/\\[0-7]{1,3}/, TokenType::LiteralStringEscape),
          LexerRule.new(/\\x[0-9a-fA-F]{2}/, TokenType::LiteralStringEscape),
          LexerRule.new(/\\./, TokenType::LiteralStringEscape),
          LexerRule.new(/[^"\\]+/, TokenType::LiteralStringOther),
        ],
        
        "byte_string_single" => [
          LexerRule.new(/'/, RuleActions.pop(TokenType::LiteralStringOther)),
          LexerRule.new(/\\[\\\'nrtbfav]/, TokenType::LiteralStringEscape),
          LexerRule.new(/\\[0-7]{1,3}/, TokenType::LiteralStringEscape),
          LexerRule.new(/\\x[0-9a-fA-F]{2}/, TokenType::LiteralStringEscape),
          LexerRule.new(/\\./, TokenType::LiteralStringEscape),
          LexerRule.new(/[^'\\]+/, TokenType::LiteralStringOther),
        ],
      }
    end
  end
end