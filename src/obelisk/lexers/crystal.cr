require "../lexer"

module Obelisk::Lexers
  # Crystal language lexer
  # Optimized with regex constants and consolidated string handling
  class Crystal < RegexLexer
    # ==========================================================================
    # Regex Pattern Constants
    # ==========================================================================

    # Whitespace and comments
    WHITESPACE = /\s+/
    LINE_COMMENT = /#.*?(?=\n|$)/

    # String delimiters
    DOUBLE_QUOTE = /"/
    SINGLE_QUOTE = /'/
    BACKTICK = /`/
    SYMBOL_DOUBLE = /:\"/
    SYMBOL_SINGLE = /:\'/

    # Escape sequences (consolidated for all string types)
    ESCAPE_SIMPLE = /\\[\\\"'nrtbfav0]/
    ESCAPE_UNICODE = /\\u\{[0-9a-fA-F]+\}/
    ESCAPE_HEX = /\\x[0-9a-fA-F]{2}/
    ESCAPE_ANY = /\\./

    # String content patterns
    STRING_DOUBLE_CONTENT = /[^\"\\#]+/
    STRING_SINGLE_CONTENT = /[^\'\\]+/
    STRING_BACKTICK_CONTENT = /[^`\\]+/

    # Interpolation
    INTERPOLATION_START = /#\{/
    INTERPOLATION_END = /\}/

    # Numbers
    NUMBER_BIN = /0b[01]+(_[01]+)*([ui](8|16|32|64))?/
    NUMBER_OCT = /0o[0-7]+(_[0-7]+)*([ui](8|16|32|64))?/
    NUMBER_HEX = /0x[0-9a-fA-F]+(_[0-9a-fA-F]+)*([ui](8|16|32|64))?/
    NUMBER_FLOAT = /\d+(\.\d+)?([eE][+-]?\d+)?(f32|f64)?/
    NUMBER_INT = /\d+(_\d+)*([ui](8|16|32|64))?/

    # Heredoc
    HEREDOC_START = /<<-([A-Z_]+)/

    # Keywords
    KEYWORDS = /\b(?:abstract|alias|annotation|as|asm|begin|break|case|class|def|do|else|elsif|end|ensure|enum|extend|false|for|fun|if|in|include|instance_sizeof|is_a\?|lib|macro|module|next|nil|of|out|pointerof|private|protected|require|rescue|return|select|self|sizeof|struct|super|then|true|type|typeof|uninitialized|union|unless|until|when|while|with|yield)\b/

    # Built-in types
    BUILTIN_TYPES = /\b(?:Array|Bool|Char|Float32|Float64|Hash|Int8|Int16|Int32|Int64|Nil|Number|Object|Proc|Range|Regex|Set|String|Symbol|Time|Tuple|UInt8|UInt16|UInt32|UInt64|Void)\b/

    # Constants and class names
    CONSTANT = /\b[A-Z][A-Z0-9_]*\b/
    CLASS_NAME = /\b[A-Z][a-zA-Z0-9_]*\b/

    # Variables
    INSTANCE_VAR = /@[a-zA-Z_][a-zA-Z0-9_]*/
    CLASS_VAR = /@@[a-zA-Z_][a-zA-Z0-9_]*/
    GLOBAL_VAR = /\$[a-zA-Z_][a-zA-Z0-9_]*/

    # Symbols
    SYMBOL_SIMPLE = /:(?:[a-zA-Z_][a-zA-Z0-9_]*[!?]?|[+\-*\/%<>=!&|^~]+)/

    # Regular expressions
    REGEX_LITERAL = /\/(?:[^\/\\\n]|\\.)+\/[imx]*/

    # Method definitions and calls
    METHOD_DEF = /\b(def)(\s+)([a-zA-Z_][a-zA-Z0-9_]*[!?]?)/
    FUNCTION_CALL = /[a-zA-Z_][a-zA-Z0-9_]*[!?]?(?=\s*\()/
    IDENTIFIER = /[a-zA-Z_][a-zA-Z0-9_]*[!?]?/

    # Operators
    OPERATORS = /[+\-*\/%<>=!&|^~]+/

    # Punctuation
    PUNCTUATION = /[.,;:()\[\]{}]/

    # Character literals
    CHAR_LITERAL = /'(?:[^'\\]|\\.)'/

    # Annotations
    ANNOTATION_START = /@\[/
    ANNOTATION_END = /\]/

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

      # Strong indicators
      score += 0.3 if text =~ /\bdef\s+\w+/
      score += 0.2 if text =~ /\bclass\s+\w+/
      score += 0.2 if text =~ /\bmodule\s+\w+/
      score += 0.15 if text =~ /\bmacro\s+\w+/
      score += 0.1 if text =~ /^\s*require\s+["']/
      score += 0.2 if text =~ /:\s*(?:String|Int32|Int64|Float32|Float64|Bool|Array|Hash)\b/
      score += 0.15 if text =~ /@\w+\*:/
      score += 0.15 if text =~ /@\[/

      # Crystal-specific syntax
      score += 0.1 if text =~ /&\.\w+/      # Block shorthand
      score += 0.1 if text =~ /\{\s*\|.*\|/ # Block with parameters
      score += 0.05 if text =~ /\.\w+\?!$/   # Method ending with ?
      score += 0.05 if text =~ /\.\w+!$/    # Method ending with !
      score += 0.05 if text =~ /#\{/        # String interpolation
      score += 0.05 if text =~ /\bproperty\s+/

      # Penalty for non-Crystal patterns
      score -= 0.3 if text =~ /\bfunction\s+\w+/
      score -= 0.3 if text =~ /\bvar\s+\w+/
      score -= 0.3 if text =~ /\bfunc\s+\w+/

      [[score, 0.0f32].max, 1.0f32].min
    end

    # Helper to get string escape rules (shared across all string states)
    private def string_escape_rules(token_type : TokenType) : Array(LexerRule)
      [
        LexerRule.new(ESCAPE_SIMPLE, token_type),
        LexerRule.new(ESCAPE_UNICODE, token_type),
        LexerRule.new(ESCAPE_HEX, token_type),
        LexerRule.new(ESCAPE_ANY, token_type),
      ]
    end

    def rules : Hash(String, Array(LexerRule))
      {
        "root" => [
          LexerRule.new(WHITESPACE, TokenType::Text),
          LexerRule.new(LINE_COMMENT, TokenType::CommentSingle),
          LexerRule.new(KEYWORDS, TokenType::Keyword),
          LexerRule.new(BUILTIN_TYPES, TokenType::KeywordType),
          LexerRule.new(CONSTANT, TokenType::NameConstant),
          LexerRule.new(CLASS_NAME, TokenType::NameClass),
          LexerRule.new(INSTANCE_VAR, TokenType::NameVariableInstance),
          LexerRule.new(CLASS_VAR, TokenType::NameVariableClass),
          LexerRule.new(GLOBAL_VAR, TokenType::NameVariableGlobal),
          LexerRule.new(SYMBOL_SIMPLE, TokenType::LiteralStringSymbol),
          LexerRule.new(SYMBOL_DOUBLE, RuleActions.push("string_symbol", TokenType::LiteralStringSymbol)),
          LexerRule.new(SYMBOL_SINGLE, RuleActions.push("string_symbol_single", TokenType::LiteralStringSymbol)),
          LexerRule.new(NUMBER_BIN, TokenType::LiteralNumberBin),
          LexerRule.new(NUMBER_OCT, TokenType::LiteralNumberOct),
          LexerRule.new(NUMBER_HEX, TokenType::LiteralNumberHex),
          LexerRule.new(NUMBER_FLOAT, TokenType::LiteralNumberFloat),
          LexerRule.new(NUMBER_INT, TokenType::LiteralNumberInteger),
          LexerRule.new(DOUBLE_QUOTE, RuleActions.push("string_double", TokenType::LiteralStringDouble)),
          LexerRule.new(SINGLE_QUOTE, RuleActions.push("string_single", TokenType::LiteralStringSingle)),
          LexerRule.new(BACKTICK, RuleActions.push("string_backtick", TokenType::LiteralStringBacktick)),
          LexerRule.new(HEREDOC_START, ->(match : String, state : LexerState, groups : Array(String)) {
            delimiter = groups[0]
            state.push_state("heredoc_#{delimiter}")
            [Token.new(TokenType::LiteralStringHeredoc, match)]
          }),
          LexerRule.new(REGEX_LITERAL, TokenType::LiteralStringRegex),
          LexerRule.new(METHOD_DEF, RuleActions.by_groups(TokenType::Keyword, TokenType::Text, TokenType::NameFunction)),
          LexerRule.new(FUNCTION_CALL, TokenType::NameFunction),
          LexerRule.new(IDENTIFIER, TokenType::Name),
          LexerRule.new(OPERATORS, TokenType::Operator),
          LexerRule.new(PUNCTUATION, TokenType::Punctuation),
          LexerRule.new(CHAR_LITERAL, TokenType::LiteralStringChar),
          LexerRule.new(ANNOTATION_START, RuleActions.push("annotation", TokenType::NameDecorator)),
        ],

        "string_double" => [
          LexerRule.new(DOUBLE_QUOTE, RuleActions.pop(TokenType::LiteralStringDouble)),
          LexerRule.new(INTERPOLATION_START, RuleActions.push("string_interpolation", TokenType::LiteralStringInterpol)),
          *string_escape_rules(TokenType::LiteralStringEscape),
          LexerRule.new(STRING_DOUBLE_CONTENT, TokenType::LiteralStringDouble),
          LexerRule.new(/#(?!\{)/, TokenType::LiteralStringDouble),
        ],

        "string_single" => [
          LexerRule.new(SINGLE_QUOTE, RuleActions.pop(TokenType::LiteralStringSingle)),
          *string_escape_rules(TokenType::LiteralStringEscape),
          LexerRule.new(STRING_SINGLE_CONTENT, TokenType::LiteralStringSingle),
        ],

        "string_backtick" => [
          LexerRule.new(BACKTICK, RuleActions.pop(TokenType::LiteralStringBacktick)),
          LexerRule.new(/\\[\\`]/, TokenType::LiteralStringEscape),
          LexerRule.new(STRING_BACKTICK_CONTENT, TokenType::LiteralStringBacktick),
        ],

        "string_symbol" => [
          LexerRule.new(DOUBLE_QUOTE, RuleActions.pop(TokenType::LiteralStringSymbol)),
          *string_escape_rules(TokenType::LiteralStringEscape),
          LexerRule.new(/[^\"\\]+/, TokenType::LiteralStringSymbol),
        ],

        "string_symbol_single" => [
          LexerRule.new(SINGLE_QUOTE, RuleActions.pop(TokenType::LiteralStringSymbol)),
          *string_escape_rules(TokenType::LiteralStringEscape),
          LexerRule.new(/[^\'\\]+/, TokenType::LiteralStringSymbol),
        ],

        "string_interpolation" => [
          LexerRule.new(INTERPOLATION_END, RuleActions.pop(TokenType::LiteralStringInterpol)),
          LexerRule.new(/[^}]+/, TokenType::Text),
        ],

        "annotation" => [
          LexerRule.new(ANNOTATION_END, RuleActions.pop(TokenType::NameDecorator)),
          LexerRule.new(/[^\]]+/, TokenType::NameDecorator),
        ],
      }
    end
  end
end
