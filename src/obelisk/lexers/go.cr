require "../lexer"

module Obelisk::Lexers
  # Go language lexer
  class Go < RegexLexer
    def config : LexerConfig
      LexerConfig.new(
        name: "go",
        aliases: ["go", "golang"],
        filenames: ["*.go"],
        mime_types: ["text/x-gosrc"],
        priority: 1.0f32
      )
    end

    def analyze(text : String) : Float32
      score = 0.0f32

      # Go-specific patterns
      score += 0.5 if text.includes?("fmt.") && text.includes?("package ")
      score += 0.1 if text.includes?("package ")

      lines = text.lines.first(50)
      lines.each do |line|
        # Strong indicators
        score += 0.2 if line =~ /^\s*package\s+\w+/
        score += 0.2 if line =~ /^\s*import\s+\(/
        score += 0.2 if line =~ /^\s*import\s+"[^"]+"/
        score += 0.2 if line =~ /^\s*func\s+\w+/
        score += 0.15 if line =~ /^\s*type\s+\w+\s+struct/
        score += 0.15 if line =~ /^\s*type\s+\w+\s+interface/
        score += 0.1 if line =~ /^\s*var\s+\w+/
        score += 0.1 if line =~ /^\s*const\s+\w+/

        # Go-specific syntax
        score += 0.1 if line =~ /:=/ # Short variable declaration
        score += 0.05 if line =~ /\bfmt\./
        score += 0.05 if line =~ /\bgo\s+\w+/ # Goroutine
        score += 0.05 if line =~ /\bchan\s+/
        score += 0.05 if line =~ /\bdefer\s+/
        score += 0.05 if line =~ /\<-/ # Channel operator
      end

      # Negative indicators
      score -= 0.2 if text =~ /\bclass\s+\w+/    # Not in Go
      score -= 0.2 if text =~ /\bdef\s+\w+:/     # Python
      score -= 0.2 if text =~ /\bfunction\s+\w+/ # JavaScript

      [score, 1.0f32].min
    end

    def rules : Hash(String, Array(LexerRule))
      {
        "root" => [
          # Whitespace and line continuations
          LexerRule.new(/\n/, TokenType::Text),
          LexerRule.new(/\s+/, TokenType::Text),
          LexerRule.new(/\\\n/, TokenType::Text),

          # Comments
          LexerRule.new(/\/\/[^\n\r]*/, TokenType::CommentSingle),
          LexerRule.new(/\/\*/, RuleActions.push("multiline_comment", TokenType::CommentMultiline)),

          # Package and import
          LexerRule.new(/\b(import|package)\b/, TokenType::KeywordNamespace),

          # Declarations
          LexerRule.new(/\b(var|func|struct|map|chan|type|interface|const)\b/, TokenType::KeywordDeclaration),

          # Keywords
          LexerRule.new(/\b(?:break|default|select|case|defer|go|else|goto|switch|fallthrough|if|range|continue|for|return)\b/, TokenType::Keyword),

          # Predeclared constants
          LexerRule.new(/\b(true|false|iota|nil)\b/, TokenType::KeywordConstant),

          # Built-in types
          LexerRule.new(/\b(?:uint|uint8|uint16|uint32|uint64|int|int8|int16|int32|int64|float|float32|float64|complex64|complex128|byte|rune|string|bool|error|uintptr|any)\b/, TokenType::KeywordType),

          # Built-in functions
          LexerRule.new(/\b(?:uint|uint8|uint16|uint32|uint64|int|int8|int16|int32|int64|float|float32|float64|complex64|complex128|byte|rune|string|bool|error|uintptr|print|println|panic|recover|close|complex|real|imag|len|cap|append|copy|delete|new|make|clear|min|max)(?=\s*\()/, RuleActions.by_groups(TokenType::NameBuiltin, TokenType::Punctuation)),

          # Numbers
          # Imaginary numbers
          LexerRule.new(/\d+i/, TokenType::LiteralNumber),
          LexerRule.new(/\d+\.\d*([Ee][-+]\d+)?i/, TokenType::LiteralNumber),
          LexerRule.new(/\.\d+([Ee][-+]\d+)?i/, TokenType::LiteralNumber),
          LexerRule.new(/\d+[Ee][-+]\d+i/, TokenType::LiteralNumber),

          # Floats
          LexerRule.new(/\d+(\.\d+[eE][+\-]?\d+|\.\d*|[eE][+\-]?\d+)/, TokenType::LiteralNumberFloat),
          LexerRule.new(/\.\d+([eE][+\-]?\d+)?/, TokenType::LiteralNumberFloat),

          # Integers
          LexerRule.new(/0[0-7]+/, TokenType::LiteralNumberOct),
          LexerRule.new(/0[xX][0-9a-fA-F_]+/, TokenType::LiteralNumberHex),
          LexerRule.new(/0b[01_]+/, TokenType::LiteralNumberBin),
          LexerRule.new(/(0|[1-9][0-9_]*)/, TokenType::LiteralNumberInteger),

          # Character literals
          LexerRule.new(/'(\\['"\\abfnrtv]|\\x[0-9a-fA-F]{2}|\\[0-7]{1,3}|\\u[0-9a-fA-F]{4}|\\U[0-9a-fA-F]{8}|[^\\])'/, TokenType::LiteralStringChar),

          # Strings
          LexerRule.new(/"/, RuleActions.push("string", TokenType::LiteralString)),
          LexerRule.new(/`/, RuleActions.push("raw_string", TokenType::LiteralString)),

          # Operators
          LexerRule.new(/<<=|>>=|<<|>>|<=|>=|&\^=|&\^|\+=|-=|\*=|\/=|%=|&=|\|=|&&|\|\||<-|\+\+|--|==|!=|:=|\.\.\.|[+\-*\/%&]/, TokenType::Operator),

          # Punctuation
          LexerRule.new(/[|^<>=!()\[\]{}.,;:~]/, TokenType::Punctuation),

          # Function calls and names
          LexerRule.new(/([a-zA-Z_]\w*)(\s*)(\()/, RuleActions.by_groups(TokenType::NameFunction, TokenType::Text, TokenType::Punctuation)),

          # Identifiers
          LexerRule.new(/[a-zA-Z_]\w*/, TokenType::Name),
        ],

        "multiline_comment" => [
          LexerRule.new(/\*\//, RuleActions.pop(TokenType::CommentMultiline)),
          LexerRule.new(/[^*]+/, TokenType::CommentMultiline),
          LexerRule.new(/\*/, TokenType::CommentMultiline),
        ],

        "string" => [
          LexerRule.new(/"/, RuleActions.pop(TokenType::LiteralString)),
          LexerRule.new(/\\\\|\\"|\\[abfnrtv]/, TokenType::LiteralStringEscape),
          LexerRule.new(/\\x[0-9a-fA-F]{2}/, TokenType::LiteralStringEscape),
          LexerRule.new(/\\[0-7]{3}/, TokenType::LiteralStringEscape),
          LexerRule.new(/\\u[0-9a-fA-F]{4}/, TokenType::LiteralStringEscape),
          LexerRule.new(/\\U[0-9a-fA-F]{8}/, TokenType::LiteralStringEscape),
          LexerRule.new(/[^"\\]+/, TokenType::LiteralString),
          LexerRule.new(/\\/, TokenType::LiteralString),
        ],

        "raw_string" => [
          LexerRule.new(/`/, RuleActions.pop(TokenType::LiteralString)),
          LexerRule.new(/[^`]+/, TokenType::LiteralString),
        ],
      }
    end
  end
end
