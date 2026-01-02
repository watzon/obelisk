require "../lexer"

module Obelisk::Lexers
  # JavaScript/TypeScript language lexer
  class JavaScript < RegexLexer
    # ==========================================================================
    # Regex Pattern Constants
    # All patterns are defined as constants to avoid recompilation and enable reuse
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

    # Number literals
    NUMBER_BIN = /0[bB][01]+(_[01]+)*n?/
    NUMBER_OCT = /0[oO][0-7]+(_[0-7]+)*n?/
    NUMBER_HEX = /0[xX][0-9a-fA-F]+(_[0-9a-fA-F]+)*n?/
    NUMBER_FLOAT = /\d+\.\d*([eE][+-]?\d+)?/
    NUMBER_FLOAT_LEADING = /\.\d+([eE][+-]?\d+)?/
    NUMBER_EXP = /\d+[eE][+-]?\d+/
    NUMBER_INT = /\d+(_\d+)*n?/

    # Keywords
    KEYWORDS = /\b(?:break|case|catch|class|const|continue|debugger|default|delete|do|else|export|extends|finally|for|function|if|import|in|instanceof|let|new|return|super|switch|this|throw|try|typeof|var|void|while|with|yield)\b/

    # TypeScript keywords
    TYPESCRIPT_KEYWORDS = /\b(?:abstract|as|async|await|constructor|declare|enum|from|get|implements|interface|is|keyof|module|namespace|never|private|protected|public|readonly|require|set|static|type|of)\b/

    # Reserved words
    RESERVED_WORDS = /\b(?:arguments|eval)\b/

    # Constants
    CONSTANTS = /\b(?:true|false|null|undefined|Infinity|NaN)\b/

    # Built-in objects
    BUILTIN_OBJECTS = /\b(?:Array|ArrayBuffer|BigInt|BigInt64Array|BigUint64Array|Boolean|DataView|Date|Error|EvalError|Float32Array|Float64Array|Function|Generator|GeneratorFunction|Int8Array|Int16Array|Int32Array|Map|Number|Object|Promise|Proxy|RangeError|ReferenceError|Reflect|RegExp|Set|SharedArrayBuffer|String|Symbol|SyntaxError|TypeError|URIError|Uint8Array|Uint8ClampedArray|Uint16Array|Uint32Array|WeakMap|WeakSet)\b/

    # Global functions
    GLOBAL_FUNCTIONS = /\b(?:decodeURI|decodeURIComponent|encodeURI|encodeURIComponent|escape|eval|isFinite|isNaN|parseFloat|parseInt|unescape)\b/

    # Console
    CONSOLE = /\bconsole\b/

    # Regular expression literal (simplified - real JS regex detection is context-sensitive)
    REGEX_LITERAL = /\/(?:[^\/\\\n]|\\.)+\/[gimsuvy]*/

    # JSX/TSX tags
    JSX_OPEN_TAG = /<([A-Z][a-zA-Z0-9_]*)/
    JSX_CLOSE_TAG = /<\/([A-Z][a-zA-Z0-9_]*)>/

    # Type annotations
    TYPE_ANNOTATION = /:\s*([a-zA-Z_]\w*)/

    # Class names
    CLASS_NAME = /\b[A-Z][a-zA-Z0-9_]*\b/

    # Function definitions
    FUNCTION_DEF = /\b(function)(\s+)([a-zA-Z_]\w*)/
    ASYNC_FUNCTION_DEF = /\b(async)(\s+)(function)(\s+)([a-zA-Z_]\w*)/

    # Arrow functions
    ARROW_FUNCTION = /([a-zA-Z_]\w*)(\s*)(=>)/
    ARROW_OPERATOR = /=>/

    # Method calls and property access
    PROPERTY_ACCESS = /\.([a-zA-Z_]\w*)/

    # Function calls (with lookahead - note: expensive but required for functionality)
    FUNCTION_CALL = /[a-zA-Z_$][\w$]*(?=\s*\()/

    # Identifiers
    IDENTIFIER = /[a-zA-Z_$][\w$]*/

    # Operators
    OPERATORS = /\+\+|--|&&|\|\||<<|>>>?|[+\-*\/%<>=!&|^~]+/
    TERNARY = /[?:]/
    SPREAD = /\.\.\./

    # Punctuation
    PUNCTUATION = /[.,;()\[\]{}]/

    # Template literal interpolation
    INTERPOLATION_START = /\$\{/
    INTERPOLATION_END = /\}/
    LONE_DOLLAR = /\$/

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

    def rules : Hash(String, Array(LexerRule))
      {
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
          LexerRule.new(RESERVED_WORDS, TokenType::KeywordReserved),

          # Constants
          LexerRule.new(CONSTANTS, TokenType::KeywordConstant),

          # Built-in objects
          # NOTE: Large alternations like this contribute to slow performance
          LexerRule.new(BUILTIN_OBJECTS, TokenType::NameBuiltin),

          # Global functions
          # NOTE: Large alternations like this contribute to slow performance
          LexerRule.new(GLOBAL_FUNCTIONS, TokenType::NameBuiltin),

          # Console object
          LexerRule.new(CONSOLE, TokenType::NameBuiltin),

          # Numbers
          LexerRule.new(NUMBER_BIN, TokenType::LiteralNumberBin),
          LexerRule.new(NUMBER_OCT, TokenType::LiteralNumberOct),
          LexerRule.new(NUMBER_HEX, TokenType::LiteralNumberHex),
          LexerRule.new(NUMBER_FLOAT, TokenType::LiteralNumberFloat),
          LexerRule.new(NUMBER_FLOAT_LEADING, TokenType::LiteralNumberFloat),
          LexerRule.new(NUMBER_EXP, TokenType::LiteralNumberFloat),
          LexerRule.new(NUMBER_INT, TokenType::LiteralNumberInteger),

          # Strings
          LexerRule.new(DOUBLE_QUOTE, RuleActions.push("string_double", TokenType::LiteralStringDouble)),
          LexerRule.new(SINGLE_QUOTE, RuleActions.push("string_single", TokenType::LiteralStringSingle)),
          LexerRule.new(BACKTICK, RuleActions.push("template_string", TokenType::LiteralStringBacktick)),

          # Regular expressions (simplified - real JS regex detection is context-sensitive)
          LexerRule.new(REGEX_LITERAL, TokenType::LiteralStringRegex),

          # JSX/TSX tags
          LexerRule.new(JSX_OPEN_TAG, RuleActions.by_groups(TokenType::NameTag)),
          LexerRule.new(JSX_CLOSE_TAG, RuleActions.by_groups(TokenType::NameTag)),

          # Type annotations (TypeScript)
          LexerRule.new(TYPE_ANNOTATION, RuleActions.by_groups(TokenType::KeywordType)),

          # Class names
          LexerRule.new(CLASS_NAME, TokenType::NameClass),

          # Function/method definitions
          LexerRule.new(FUNCTION_DEF, RuleActions.by_groups(TokenType::Keyword, TokenType::Text, TokenType::NameFunction)),
          LexerRule.new(ASYNC_FUNCTION_DEF, RuleActions.by_groups(TokenType::Keyword, TokenType::Text, TokenType::Keyword, TokenType::Text, TokenType::NameFunction)),

          # Arrow functions
          LexerRule.new(ARROW_FUNCTION, RuleActions.by_groups(TokenType::Name, TokenType::Text, TokenType::Operator)),

          # Method calls and property access
          LexerRule.new(PROPERTY_ACCESS, RuleActions.by_groups(TokenType::NameAttribute)),

          # Function calls
          LexerRule.new(FUNCTION_CALL, TokenType::NameFunction),
          LexerRule.new(IDENTIFIER, TokenType::Name),

          # Operators
          LexerRule.new(OPERATORS, TokenType::Operator),
          LexerRule.new(TERNARY, TokenType::Operator),
          LexerRule.new(SPREAD, TokenType::Operator),
          LexerRule.new(ARROW_OPERATOR, TokenType::Operator),
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
