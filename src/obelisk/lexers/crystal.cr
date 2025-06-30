require "../lexer"

module Obelisk::Lexers
  # Crystal language lexer
  class Crystal < RegexLexer
    def config : LexerConfig
      LexerConfig.new(
        name: "crystal",
        aliases: ["crystal", "cr"],
        filenames: ["*.cr"],
        mime_types: ["text/x-crystal"],
        priority: 1.0f32
      )
    end

    def analyze(text : String) : Float32
      score = 0.0f32
      lines = text.lines.first(50) # Analyze first 50 lines
      
      # Crystal-specific patterns
      lines.each do |line|
        # Strong indicators
        score += 0.2 if line =~ /^\s*require\s+["']/
        score += 0.2 if line =~ /^\s*class\s+\w+/
        score += 0.2 if line =~ /^\s*module\s+\w+/
        score += 0.15 if line =~ /^\s*def\s+\w+/
        score += 0.15 if line =~ /^\s*macro\s+\w+/
        score += 0.1 if line =~ /^\s*struct\s+\w+/
        score += 0.1 if line =~ /^\s*enum\s+\w+/
        
        # Type annotations
        score += 0.1 if line =~ /:\s*(String|Int32|Int64|Float32|Float64|Bool|Array|Hash)/
        score += 0.1 if line =~ /@\w+\s*:/
        
        # Crystal-specific keywords
        score += 0.05 if line =~ /\b(abstract|alias|annotation|as\?|as|ensure|forall|fun|in|is_a\?|lib|of|out|pointerof|private|protected|rescue|sizeof|typeof|uninitialized|when)\b/
        
        # Crystal-specific syntax
        score += 0.05 if line =~ /\.\w+\?$/  # Method ending with ?
        score += 0.05 if line =~ /\.\w+!$/   # Method ending with !
        score += 0.05 if line =~ /&\.\w+/    # Block shorthand
        score += 0.05 if line =~ /\{\s*\|.*\|/ # Block with parameters
      end
      
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
          
          # Keywords
          LexerRule.new(/\b(?:abstract|alias|annotation|as|asm|begin|break|case|class|def|do|else|elsif|end|ensure|enum|extend|false|for|fun|if|in|include|instance_sizeof|is_a\?|lib|macro|module|next|nil|of|out|pointerof|private|protected|require|rescue|return|select|self|sizeof|struct|super|then|true|type|typeof|uninitialized|union|unless|until|when|while|with|yield)\b/, TokenType::Keyword),
          
          # Built-in types
          LexerRule.new(/\b(?:Array|Bool|Char|Float32|Float64|Hash|Int8|Int16|Int32|Int64|Nil|Number|Object|Proc|Range|Regex|Set|String|Symbol|Time|Tuple|UInt8|UInt16|UInt32|UInt64|Void)\b/, TokenType::KeywordType),
          
          # Constants (uppercase identifiers)
          LexerRule.new(/\b[A-Z][A-Z0-9_]*\b/, TokenType::NameConstant),
          
          # Class names (PascalCase)
          LexerRule.new(/\b[A-Z][a-zA-Z0-9_]*\b/, TokenType::NameClass),
          
          # Instance variables
          LexerRule.new(/@[a-zA-Z_][a-zA-Z0-9_]*/, TokenType::NameVariableInstance),
          
          # Class variables
          LexerRule.new(/@@[a-zA-Z_][a-zA-Z0-9_]*/, TokenType::NameVariableClass),
          
          # Global variables
          LexerRule.new(/\$[a-zA-Z_][a-zA-Z0-9_]*/, TokenType::NameVariableGlobal),
          
          # Symbols
          LexerRule.new(/:(?:[a-zA-Z_][a-zA-Z0-9_]*[!?]?|[+\-*\/%<>=!&|^~]+)/, TokenType::LiteralStringSymbol),
          LexerRule.new(/:\"/, RuleActions.push("string_symbol", TokenType::LiteralStringSymbol)),
          LexerRule.new(/:\'/, RuleActions.push("string_symbol_single", TokenType::LiteralStringSymbol)),
          
          # Numbers
          LexerRule.new(/0b[01]+(_[01]+)*([ui](8|16|32|64))?/, TokenType::LiteralNumberBin),
          LexerRule.new(/0o[0-7]+(_[0-7]+)*([ui](8|16|32|64))?/, TokenType::LiteralNumberOct),
          LexerRule.new(/0x[0-9a-fA-F]+(_[0-9a-fA-F]+)*([ui](8|16|32|64))?/, TokenType::LiteralNumberHex),
          LexerRule.new(/\d+(\.\d+)?([eE][+-]?\d+)?(f32|f64)?/, TokenType::LiteralNumberFloat),
          LexerRule.new(/\d+(_\d+)*([ui](8|16|32|64))?/, TokenType::LiteralNumberInteger),
          
          # Strings
          LexerRule.new(/\"/, RuleActions.push("string_double", TokenType::LiteralStringDouble)),
          LexerRule.new(/\'/, RuleActions.push("string_single", TokenType::LiteralStringSingle)),
          LexerRule.new(/`/, RuleActions.push("string_backtick", TokenType::LiteralStringBacktick)),
          
          # Heredocs
          LexerRule.new(/<<-([A-Z_]+)/, ->(match : String, state : LexerState, groups : Array(String)) {
            delimiter = groups[0]
            state.push_state("heredoc_#{delimiter}")
            [Token.new(TokenType::LiteralStringHeredoc, match)]
          }),
          
          # Regular expressions
          LexerRule.new(/\/(?:[^\/\\\n]|\\.)+\/[imx]*/, TokenType::LiteralStringRegex),
          
          # Method definitions
          LexerRule.new(/\bdef\s+([a-zA-Z_][a-zA-Z0-9_]*[!?]?)/, RuleActions.by_groups(TokenType::Keyword, TokenType::NameFunction)),
          
          # Function calls and method names
          LexerRule.new(/[a-zA-Z_][a-zA-Z0-9_]*[!?]?(?=\s*\()/, TokenType::NameFunction),
          LexerRule.new(/[a-zA-Z_][a-zA-Z0-9_]*[!?]?/, TokenType::Name),
          
          # Operators
          LexerRule.new(/[+\-*\/%<>=!&|^~]+/, TokenType::Operator),
          LexerRule.new(/[.,;:()\[\]{}]/, TokenType::Punctuation),
          
          # Character literals
          LexerRule.new(/'(?:[^'\\]|\\.)'/, TokenType::LiteralStringChar),
          
          # Annotations
          LexerRule.new(/@\[/, RuleActions.push("annotation", TokenType::NameDecorator)),
        ],
        
        "string_double" => [
          LexerRule.new(/\"/, RuleActions.pop(TokenType::LiteralStringDouble)),
          LexerRule.new(/\\[\\\"'nrtbfav0]/, TokenType::LiteralStringEscape),
          LexerRule.new(/\\u\{[0-9a-fA-F]+\}/, TokenType::LiteralStringEscape),
          LexerRule.new(/\\x[0-9a-fA-F]{2}/, TokenType::LiteralStringEscape),
          LexerRule.new(/\\./, TokenType::LiteralStringEscape),
          LexerRule.new(/#\{/, RuleActions.push("string_interpolation", TokenType::LiteralStringInterpol)),
          LexerRule.new(/[^\"\\#]+/, TokenType::LiteralStringDouble),
          LexerRule.new(/#(?!\{)/, TokenType::LiteralStringDouble),
        ],
        
        "string_single" => [
          LexerRule.new(/\'/, RuleActions.pop(TokenType::LiteralStringSingle)),
          LexerRule.new(/\\[\\\'nrtbfav0]/, TokenType::LiteralStringEscape),
          LexerRule.new(/\\./, TokenType::LiteralStringEscape),
          LexerRule.new(/[^\'\\]+/, TokenType::LiteralStringSingle),
        ],
        
        "string_backtick" => [
          LexerRule.new(/`/, RuleActions.pop(TokenType::LiteralStringBacktick)),
          LexerRule.new(/\\[\\`]/, TokenType::LiteralStringEscape),
          LexerRule.new(/[^`\\]+/, TokenType::LiteralStringBacktick),
        ],
        
        "string_symbol" => [
          LexerRule.new(/\"/, RuleActions.pop(TokenType::LiteralStringSymbol)),
          LexerRule.new(/\\[\\\"'nrtbfav0]/, TokenType::LiteralStringEscape),
          LexerRule.new(/\\./, TokenType::LiteralStringEscape),
          LexerRule.new(/[^\"\\]+/, TokenType::LiteralStringSymbol),
        ],
        
        "string_symbol_single" => [
          LexerRule.new(/\'/, RuleActions.pop(TokenType::LiteralStringSymbol)),
          LexerRule.new(/\\[\\\'nrtbfav0]/, TokenType::LiteralStringEscape),
          LexerRule.new(/\\./, TokenType::LiteralStringEscape),
          LexerRule.new(/[^\'\\]+/, TokenType::LiteralStringSymbol),
        ],
        
        "string_interpolation" => [
          LexerRule.new(/\}/, RuleActions.pop(TokenType::LiteralStringInterpol)),
          LexerRule.new(/[^}]+/, TokenType::Text), # Simplified - could recursively parse Crystal code
        ],
        
        "annotation" => [
          LexerRule.new(/\]/, RuleActions.pop(TokenType::NameDecorator)),
          LexerRule.new(/[^\]]+/, TokenType::NameDecorator),
        ],
      }
    end

    # Analyze Crystal code to determine confidence
    def analyze(text : String) : Float32
      score = 0.0f32
      
      # Look for Crystal-specific patterns
      score += 0.3f32 if text.includes?("def ")
      score += 0.2f32 if text.includes?("class ")
      score += 0.2f32 if text.includes?("module ")
      score += 0.1f32 if text.includes?("require ")
      score += 0.1f32 if text.includes?("end")
      score += 0.1f32 if text.match(/\b(?:Int32|String|Array|Hash)\b/)
      
      # Crystal-specific syntax
      score += 0.2f32 if text.includes?(" : ")  # Type annotations
      score += 0.1f32 if text.includes?("#" + "{")   # String interpolation
      score += 0.1f32 if text.includes?("@" + "[")   # Annotations
      
      # Penalty for non-Crystal patterns
      score -= 0.1f32 if text.includes?("var ")     # JavaScript
      score -= 0.1f32 if text.includes?("func ")    # Go
      score -= 0.1f32 if text.includes?("function ") # JavaScript
      
      score.clamp(0.0f32, 1.0f32)
    end
  end
end