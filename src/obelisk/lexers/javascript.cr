require "../lexer"

module Obelisk::Lexers
  # JavaScript/TypeScript language lexer
  class JavaScript < RegexLexer
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
          LexerRule.new(/\s+/, TokenType::Text),

          # Comments
          LexerRule.new(/\/\/.*?(?=\n|$)/, TokenType::CommentSingle),
          LexerRule.new(/\/\*/, RuleActions.push("multiline_comment", TokenType::CommentMultiline)),

          # Keywords
          LexerRule.new(/\b(?:break|case|catch|class|const|continue|debugger|default|delete|do|else|export|extends|finally|for|function|if|import|in|instanceof|let|new|return|super|switch|this|throw|try|typeof|var|void|while|with|yield)\b/, TokenType::Keyword),

          # TypeScript keywords
          LexerRule.new(/\b(?:abstract|as|async|await|constructor|declare|enum|from|get|implements|interface|is|keyof|module|namespace|never|private|protected|public|readonly|require|set|static|type|of)\b/, TokenType::Keyword),

          # Reserved words
          LexerRule.new(/\b(?:arguments|eval)\b/, TokenType::KeywordReserved),

          # Constants
          LexerRule.new(/\b(?:true|false|null|undefined|Infinity|NaN)\b/, TokenType::KeywordConstant),

          # Built-in objects
          LexerRule.new(/\b(?:Array|ArrayBuffer|BigInt|BigInt64Array|BigUint64Array|Boolean|DataView|Date|Error|EvalError|Float32Array|Float64Array|Function|Generator|GeneratorFunction|Int8Array|Int16Array|Int32Array|Map|Number|Object|Promise|Proxy|RangeError|ReferenceError|Reflect|RegExp|Set|SharedArrayBuffer|String|Symbol|SyntaxError|TypeError|URIError|Uint8Array|Uint8ClampedArray|Uint16Array|Uint32Array|WeakMap|WeakSet)\b/, TokenType::NameBuiltin),

          # Global functions
          LexerRule.new(/\b(?:decodeURI|decodeURIComponent|encodeURI|encodeURIComponent|escape|eval|isFinite|isNaN|parseFloat|parseInt|unescape)\b/, TokenType::NameBuiltin),

          # Console object
          LexerRule.new(/\bconsole\b/, TokenType::NameBuiltin),

          # Numbers
          LexerRule.new(/0[bB][01]+(_[01]+)*n?/, TokenType::LiteralNumberBin),
          LexerRule.new(/0[oO][0-7]+(_[0-7]+)*n?/, TokenType::LiteralNumberOct),
          LexerRule.new(/0[xX][0-9a-fA-F]+(_[0-9a-fA-F]+)*n?/, TokenType::LiteralNumberHex),
          LexerRule.new(/\d+\.\d*([eE][+-]?\d+)?/, TokenType::LiteralNumberFloat),
          LexerRule.new(/\.\d+([eE][+-]?\d+)?/, TokenType::LiteralNumberFloat),
          LexerRule.new(/\d+[eE][+-]?\d+/, TokenType::LiteralNumberFloat),
          LexerRule.new(/\d+(_\d+)*n?/, TokenType::LiteralNumberInteger),

          # Strings
          LexerRule.new(/"/, RuleActions.push("string_double", TokenType::LiteralStringDouble)),
          LexerRule.new(/'/, RuleActions.push("string_single", TokenType::LiteralStringSingle)),
          LexerRule.new(/`/, RuleActions.push("template_string", TokenType::LiteralStringBacktick)),

          # Regular expressions
          # This is simplified - real JS regex detection is context-sensitive
          LexerRule.new(/\/(?:[^\/\\\n]|\\.)+\/[gimsuvy]*/, TokenType::LiteralStringRegex),

          # JSX/TSX tags
          LexerRule.new(/<([A-Z][a-zA-Z0-9_]*)/, RuleActions.by_groups(TokenType::NameTag)),
          LexerRule.new(/<\/([A-Z][a-zA-Z0-9_]*)>/, RuleActions.by_groups(TokenType::NameTag)),

          # Type annotations (TypeScript)
          LexerRule.new(/:\s*([a-zA-Z_]\w*)/, RuleActions.by_groups(TokenType::KeywordType)),

          # Class names
          LexerRule.new(/\b[A-Z][a-zA-Z0-9_]*\b/, TokenType::NameClass),

          # Function/method definitions
          LexerRule.new(/\b(function)(\s+)([a-zA-Z_]\w*)/, RuleActions.by_groups(TokenType::Keyword, TokenType::Text, TokenType::NameFunction)),
          LexerRule.new(/\b(async)(\s+)(function)(\s+)([a-zA-Z_]\w*)/, RuleActions.by_groups(TokenType::Keyword, TokenType::Text, TokenType::Keyword, TokenType::Text, TokenType::NameFunction)),

          # Arrow functions
          LexerRule.new(/([a-zA-Z_]\w*)(\s*)(=>)/, RuleActions.by_groups(TokenType::Name, TokenType::Text, TokenType::Operator)),

          # Method calls and property access
          LexerRule.new(/\.([a-zA-Z_]\w*)/, RuleActions.by_groups(TokenType::NameAttribute)),

          # Function calls and names
          LexerRule.new(/[a-zA-Z_$][\w$]*(?=\s*\()/, TokenType::NameFunction),
          LexerRule.new(/[a-zA-Z_$][\w$]*/, TokenType::Name),

          # Operators
          LexerRule.new(/\+\+|--|&&|\|\||<<|>>>?|[+\-*\/%<>=!&|^~]+/, TokenType::Operator),
          LexerRule.new(/[?:]/, TokenType::Operator),   # Ternary
          LexerRule.new(/\.\.\./, TokenType::Operator), # Spread
          LexerRule.new(/=>/, TokenType::Operator),     # Arrow
          LexerRule.new(/[.,;()\[\]{}]/, TokenType::Punctuation),
        ],

        "multiline_comment" => [
          LexerRule.new(/\*\//, RuleActions.pop(TokenType::CommentMultiline)),
          LexerRule.new(/[^*]+/, TokenType::CommentMultiline),
          LexerRule.new(/\*/, TokenType::CommentMultiline),
        ],

        "string_double" => [
          LexerRule.new(/"/, RuleActions.pop(TokenType::LiteralStringDouble)),
          LexerRule.new(/\\[\\\"'nrtbfv]/, TokenType::LiteralStringEscape),
          LexerRule.new(/\\x[0-9a-fA-F]{2}/, TokenType::LiteralStringEscape),
          LexerRule.new(/\\u[0-9a-fA-F]{4}/, TokenType::LiteralStringEscape),
          LexerRule.new(/\\u\{[0-9a-fA-F]+\}/, TokenType::LiteralStringEscape),
          LexerRule.new(/\\[0-7]{1,3}/, TokenType::LiteralStringEscape),
          LexerRule.new(/\\./, TokenType::LiteralStringEscape),
          LexerRule.new(/[^"\\]+/, TokenType::LiteralStringDouble),
        ],

        "string_single" => [
          LexerRule.new(/'/, RuleActions.pop(TokenType::LiteralStringSingle)),
          LexerRule.new(/\\[\\\'nrtbfv]/, TokenType::LiteralStringEscape),
          LexerRule.new(/\\x[0-9a-fA-F]{2}/, TokenType::LiteralStringEscape),
          LexerRule.new(/\\u[0-9a-fA-F]{4}/, TokenType::LiteralStringEscape),
          LexerRule.new(/\\u\{[0-9a-fA-F]+\}/, TokenType::LiteralStringEscape),
          LexerRule.new(/\\[0-7]{1,3}/, TokenType::LiteralStringEscape),
          LexerRule.new(/\\./, TokenType::LiteralStringEscape),
          LexerRule.new(/[^'\\]+/, TokenType::LiteralStringSingle),
        ],

        "template_string" => [
          LexerRule.new(/`/, RuleActions.pop(TokenType::LiteralStringBacktick)),
          LexerRule.new(/\\[\\`nrtbfv]/, TokenType::LiteralStringEscape),
          LexerRule.new(/\\x[0-9a-fA-F]{2}/, TokenType::LiteralStringEscape),
          LexerRule.new(/\\u[0-9a-fA-F]{4}/, TokenType::LiteralStringEscape),
          LexerRule.new(/\\u\{[0-9a-fA-F]+\}/, TokenType::LiteralStringEscape),
          LexerRule.new(/\\./, TokenType::LiteralStringEscape),
          LexerRule.new(/\$\{/, RuleActions.push("template_interpolation", TokenType::LiteralStringInterpol)),
          LexerRule.new(/[^`\\$]+/, TokenType::LiteralStringBacktick),
          LexerRule.new(/\$/, TokenType::LiteralStringBacktick),
        ],

        "template_interpolation" => [
          LexerRule.new(/\}/, RuleActions.pop(TokenType::LiteralStringInterpol)),
          # Simplified - in reality we'd recursively parse JavaScript expressions
          LexerRule.new(/[^}]+/, TokenType::Text),
        ],
      }
    end
  end
end
