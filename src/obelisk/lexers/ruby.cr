require "../lexer"

module Obelisk::Lexers
  # Ruby language lexer
  # Optimized with regex constants and consolidated string handling
  class Ruby < RegexLexer
    # ==========================================================================
    # Regex Pattern Constants
    # ==========================================================================

    # Whitespace and comments
    WHITESPACE = /\s+/
    LINE_COMMENT = /#.*?(?=\n|$)/
    SHEBANG = /^!/

    # String delimiters
    DOUBLE_QUOTE = /"/
    SINGLE_QUOTE = /'/
    BACKTICK = /`/
    SYMBOL_DOUBLE = /:"/
    SYMBOL_SINGLE = /:'/

    # Escape sequences (consolidated for all string types)
    ESCAPE_SIMPLE = /\\[\\\"'nrtbfav0]/
    ESCAPE_UNICODE = /\\u\{[0-9a-fA-F]+\}/
    ESCAPE_UNICODE_SHORT = /\\u[0-9a-fA-F]{4}/
    ESCAPE_HEX = /\\x[0-9a-fA-F]{2}/
    ESCAPE_OCTAL = /\\[0-7]{1,3}/
    ESCAPE_ANY = /\\./
    ESCAPE_SINGLE_BACKSLASH = /\\[\\']/

    # Interpolation
    INTERPOLATION_START = /#\{/
    INTERPOLATION_SIMPLE_IVAR = /#@@?\w+/
    INTERPOLATION_SIMPLE_GVAR = /#\$\w+/
    INTERPOLATION_END = /\}/

    # String content patterns
    STRING_DOUBLE_CONTENT = /[^"\\#]+/
    STRING_SINGLE_CONTENT = /[^'\\]+/
    STRING_BACKTICK_CONTENT = /[^`\\#]+/

    # Numbers
    NUMBER_BIN = /0b[01_]+/
    NUMBER_OCT = /0o[0-7_]+/
    NUMBER_HEX = /0x[0-9a-fA-F_]+/
    NUMBER_FLOAT = /\d+\.\d+([eE][+-]?\d+)?/
    NUMBER_EXP = /\d+[eE][+-]?\d+/
    NUMBER_INT = /\d+(_\d+)*/

    # Keywords
    KEYWORDS = /\b(?:BEGIN|END|alias|begin|break|case|class|def|defined\?|do|else|elsif|end|ensure|for|if|in|module|next|nil|redo|rescue|retry|return|self|super|then|undef|unless|until|when|while|yield)\b/

    # Operator words
    OPERATOR_WORDS = /\b(?:and|not|or)\b/

    # Pseudo-variables
    PSEUDO_VARIABLES = /\b(?:__FILE__|__LINE__|__ENCODING__)\b/

    # Built-in functions (simplified from ~60 to most common)
    BUILTINS = /\b(?:abort|at_exit|autoload|binding|caller|catch|chomp|chop|eval|exec|exit|fail|fork|gets|global_variables|gsub|lambda|load|local_variables|open|p|print|printf|proc|putc|puts|raise|rand|readline|readlines|require|require_relative|sleep|spawn|sprintf|srand|sub|syscall|system|test|throw|trap|warn)\b/

    # Constants and class names
    CONSTANT = /\b[A-Z][A-Z0-9_]*\b/
    CLASS_NAME = /\b[A-Z][a-zA-Z0-9_]*\b/

    # Variables
    INSTANCE_VAR = /@[a-zA-Z_]\w*/
    CLASS_VAR = /@@[a-zA-Z_]\w*/
    GLOBAL_VAR = /\$[a-zA-Z_]\w*/
    GLOBAL_VAR_SPECIAL = /\$[!@&`'+~=\/\\,;.<>_*$?:"]/
    GLOBAL_VAR_OPTION = /\$-[0adFiIlpvw]/
    GLOBAL_VAR_NUMBERED = /\$\d+/

    # Symbols
    SYMBOL_SIMPLE = /:(?:[a-zA-Z_]\w*[!?]?|[+\-*\/%<>=!&|^~]+)/

    # Regular expressions
    REGEX_LITERAL = /\/(?:[^\/\\\n]|\\.)+\/[mixounse]*/

    # Percent strings
    PERCENT_CURLY_START = /%[qQ]?\{/
    PERCENT_SQUARE_START = /%[qQ]?\[/
    PERCENT_PAREN_START = /%[qQ]?\(/
    PERCENT_ANGLE_START = /%[qQ]?</
    PERCENT_OTHER_START = /%[qQ]?([^\w\s])/

    # Method definitions and calls
    METHOD_DEF = /\b(def)(\s+)([a-zA-Z_]\w*[!?=]?)/
    FUNCTION_CALL = /[a-zA-Z_]\w*[!?]?(?=\s*\()/
    IDENTIFIER = /[a-zA-Z_]\w*[!?]?/

    # Operators
    OPERATORS = /[+\-*\/%<>=!&|^~]+/
    RANGE_OPERATOR = /\.\.\.?/
    HASH_ROCKET = /=>/

    # Punctuation
    PUNCTUATION = /[.,;:()\[\]{}]/

    # Heredoc
    HEREDOC_START = /<<[-~]?(['"]?)([A-Z_]+)\1/

    def config : LexerConfig
      LexerConfig.new(
        name: "ruby",
        aliases: ["ruby", "rb"],
        filenames: ["*.rb", "*.rbw", "Rakefile", "*.rake", "*.gemspec", "*.rbx", "Gemfile", "Vagrantfile"],
        mime_types: ["text/x-ruby", "application/x-ruby"],
        priority: 1.0f32
      )
    end

    def analyze(text : String) : Float32
      score = 0.0f32

      # Strong indicators
      score += 0.2 if text =~ /^\s*require\s+["']/
      score += 0.2 if text =~ /^\s*class\s+[A-Z]\w*/
      score += 0.2 if text =~ /^\s*module\s+[A-Z]\w*/
      score += 0.15 if text =~ /^\s*def\s+\w+/
      score += 0.1 if text =~ /^\s*attr_(?:reader|writer|accessor)/
      score += 0.1 if text =~ /^\s*gem\s+["']/

      # Ruby-specific syntax
      score += 0.1 if text =~ /@\w+/           # Instance variables
      score += 0.1 if text =~ /@@\w+/          # Class variables
      score += 0.1 if text =~ /\$\w+/          # Global variables
      score += 0.05 if text =~ /:[a-zA-Z_]\w*/ # Symbols
      score += 0.05 if text =~ /\b(?:elsif|unless|rescue|ensure)\b/
      score += 0.05 if text =~ /\b(?:nil|true|false)\b/
      score += 0.05 if text =~ /\bdo\s*\|.*\|/ # Blocks with parameters
      score += 0.05 if text =~ /\{\s*\|.*\|/   # Block with parameters
      score += 0.05 if text =~ /\bend\b/       # end keyword

      # Negative indicators (not Ruby)
      score -= 0.2 if text =~ /\bfunction\s+\w+/
      score -= 0.2 if text =~ /\bfunc\s+\w+/
      score -= 0.2 if text =~ /\bvoid\s+\w+/

      [[score, 0.0f32].max, 1.0f32].min
    end

    # Helper to get full escape rules (for double-quoted style strings)
    private def full_escape_rules(token_type : TokenType) : Array(LexerRule)
      [
        LexerRule.new(ESCAPE_SIMPLE, token_type),
        LexerRule.new(ESCAPE_UNICODE, token_type),
        LexerRule.new(ESCAPE_UNICODE_SHORT, token_type),
        LexerRule.new(ESCAPE_HEX, token_type),
        LexerRule.new(ESCAPE_OCTAL, token_type),
        LexerRule.new(ESCAPE_ANY, token_type),
      ]
    end

    def rules : Hash(String, Array(LexerRule))
      {
        "root" => [
          LexerRule.new(WHITESPACE, TokenType::Text),
          LexerRule.new(LINE_COMMENT, TokenType::CommentSingle),
          LexerRule.new(SHEBANG, TokenType::CommentHashbang),
          LexerRule.new(KEYWORDS, TokenType::Keyword),
          LexerRule.new(OPERATOR_WORDS, TokenType::OperatorWord),
          LexerRule.new(PSEUDO_VARIABLES, TokenType::NameBuiltinPseudo),
          LexerRule.new(BUILTINS, TokenType::NameBuiltin),
          LexerRule.new(CONSTANT, TokenType::NameConstant),
          LexerRule.new(CLASS_NAME, TokenType::NameClass),
          LexerRule.new(INSTANCE_VAR, TokenType::NameVariableInstance),
          LexerRule.new(CLASS_VAR, TokenType::NameVariableClass),
          LexerRule.new(GLOBAL_VAR, TokenType::NameVariableGlobal),
          LexerRule.new(GLOBAL_VAR_SPECIAL, TokenType::NameVariableGlobal),
          LexerRule.new(GLOBAL_VAR_OPTION, TokenType::NameVariableGlobal),
          LexerRule.new(GLOBAL_VAR_NUMBERED, TokenType::NameVariableGlobal),
          LexerRule.new(SYMBOL_SIMPLE, TokenType::LiteralStringSymbol),
          LexerRule.new(SYMBOL_DOUBLE, RuleActions.push("string_symbol_double", TokenType::LiteralStringSymbol)),
          LexerRule.new(SYMBOL_SINGLE, RuleActions.push("string_symbol_single", TokenType::LiteralStringSymbol)),
          LexerRule.new(NUMBER_BIN, TokenType::LiteralNumberBin),
          LexerRule.new(NUMBER_OCT, TokenType::LiteralNumberOct),
          LexerRule.new(NUMBER_HEX, TokenType::LiteralNumberHex),
          LexerRule.new(NUMBER_FLOAT, TokenType::LiteralNumberFloat),
          LexerRule.new(NUMBER_EXP, TokenType::LiteralNumberFloat),
          LexerRule.new(NUMBER_INT, TokenType::LiteralNumberInteger),
          LexerRule.new(DOUBLE_QUOTE, RuleActions.push("string_double", TokenType::LiteralStringDouble)),
          LexerRule.new(SINGLE_QUOTE, RuleActions.push("string_single", TokenType::LiteralStringSingle)),
          LexerRule.new(BACKTICK, RuleActions.push("string_backtick", TokenType::LiteralStringBacktick)),
          LexerRule.new(REGEX_LITERAL, TokenType::LiteralStringRegex),
          LexerRule.new(PERCENT_CURLY_START, RuleActions.push("percent_string_curly", TokenType::LiteralStringOther)),
          LexerRule.new(PERCENT_SQUARE_START, RuleActions.push("percent_string_square", TokenType::LiteralStringOther)),
          LexerRule.new(PERCENT_PAREN_START, RuleActions.push("percent_string_paren", TokenType::LiteralStringOther)),
          LexerRule.new(PERCENT_ANGLE_START, RuleActions.push("percent_string_angle", TokenType::LiteralStringOther)),
          LexerRule.new(PERCENT_OTHER_START, ->(match : LexerMatch, state : LexerState) {
            delimiter = match.groups[0]
            state.push_state("percent_string_other")
            state.set_context("delimiter", delimiter)
            [match.make_token(TokenType::LiteralStringOther)]
          }),
          LexerRule.new(METHOD_DEF, RuleActions.by_groups(TokenType::Keyword, TokenType::Text, TokenType::NameFunction)),
          LexerRule.new(FUNCTION_CALL, TokenType::NameFunction),
          LexerRule.new(IDENTIFIER, TokenType::Name),
          LexerRule.new(OPERATORS, TokenType::Operator),
          LexerRule.new(PUNCTUATION, TokenType::Punctuation),
          LexerRule.new(RANGE_OPERATOR, TokenType::Operator),
          LexerRule.new(HASH_ROCKET, TokenType::Operator),
          LexerRule.new(HEREDOC_START, ->(match : LexerMatch, state : LexerState) {
            delimiter = match.groups[1]
            state.push_state("heredoc")
            state.set_context("heredoc_delimiter", delimiter)
            [match.make_token(TokenType::LiteralStringHeredoc)]
          }),
        ],

        "string_double" => [
          LexerRule.new(DOUBLE_QUOTE, RuleActions.pop(TokenType::LiteralStringDouble)),
          LexerRule.new(INTERPOLATION_START, RuleActions.push("string_interpolation", TokenType::LiteralStringInterpol)),
          LexerRule.new(INTERPOLATION_SIMPLE_IVAR, TokenType::LiteralStringInterpol),
          LexerRule.new(INTERPOLATION_SIMPLE_GVAR, TokenType::LiteralStringInterpol),
          *full_escape_rules(TokenType::LiteralStringEscape),
          LexerRule.new(STRING_DOUBLE_CONTENT, TokenType::LiteralStringDouble),
          LexerRule.new(/#(?!\{|[@$])/, TokenType::LiteralStringDouble),
        ],

        "string_single" => [
          LexerRule.new(SINGLE_QUOTE, RuleActions.pop(TokenType::LiteralStringSingle)),
          LexerRule.new(ESCAPE_SINGLE_BACKSLASH, TokenType::LiteralStringEscape),
          LexerRule.new(STRING_SINGLE_CONTENT, TokenType::LiteralStringSingle),
          LexerRule.new(/\\/, TokenType::LiteralStringSingle),
        ],

        "string_backtick" => [
          LexerRule.new(BACKTICK, RuleActions.pop(TokenType::LiteralStringBacktick)),
          LexerRule.new(INTERPOLATION_START, RuleActions.push("string_interpolation", TokenType::LiteralStringInterpol)),
          LexerRule.new(INTERPOLATION_SIMPLE_IVAR, TokenType::LiteralStringInterpol),
          LexerRule.new(INTERPOLATION_SIMPLE_GVAR, TokenType::LiteralStringInterpol),
          LexerRule.new(/\\[\\`]/, TokenType::LiteralStringEscape),
          LexerRule.new(STRING_BACKTICK_CONTENT, TokenType::LiteralStringBacktick),
          LexerRule.new(/#(?!\{|[@$])/, TokenType::LiteralStringBacktick),
        ],

        "string_symbol_single" => [
          LexerRule.new(SINGLE_QUOTE, RuleActions.pop(TokenType::LiteralStringSymbol)),
          LexerRule.new(ESCAPE_SINGLE_BACKSLASH, TokenType::LiteralStringEscape),
          LexerRule.new(/[^'\\]+/, TokenType::LiteralStringSymbol),
          LexerRule.new(/\\/, TokenType::LiteralStringSymbol),
        ],

        "string_symbol_double" => [
          LexerRule.new(DOUBLE_QUOTE, RuleActions.pop(TokenType::LiteralStringSymbol)),
          LexerRule.new(INTERPOLATION_START, RuleActions.push("string_interpolation", TokenType::LiteralStringInterpol)),
          LexerRule.new(INTERPOLATION_SIMPLE_IVAR, TokenType::LiteralStringInterpol),
          LexerRule.new(INTERPOLATION_SIMPLE_GVAR, TokenType::LiteralStringInterpol),
          *full_escape_rules(TokenType::LiteralStringEscape),
          LexerRule.new(/[^"\\#]+/, TokenType::LiteralStringSymbol),
          LexerRule.new(/#(?!\{|[@$])/, TokenType::LiteralStringSymbol),
        ],

        "string_interpolation" => [
          LexerRule.new(INTERPOLATION_END, RuleActions.pop(TokenType::LiteralStringInterpol)),
          LexerRule.new(/[^}]+/, TokenType::Text),
        ],

        "percent_string_curly" => [
          LexerRule.new(/\}/, RuleActions.pop(TokenType::LiteralStringOther)),
          LexerRule.new(/\{/, RuleActions.push("percent_string_curly", TokenType::LiteralStringOther)),
          LexerRule.new(/[^{}]+/, TokenType::LiteralStringOther),
        ],

        "percent_string_square" => [
          LexerRule.new(/\]/, RuleActions.pop(TokenType::LiteralStringOther)),
          LexerRule.new(/\[/, RuleActions.push("percent_string_square", TokenType::LiteralStringOther)),
          LexerRule.new(/[^\[\]]+/, TokenType::LiteralStringOther),
        ],

        "percent_string_paren" => [
          LexerRule.new(/\)/, RuleActions.pop(TokenType::LiteralStringOther)),
          LexerRule.new(/\(/, RuleActions.push("percent_string_paren", TokenType::LiteralStringOther)),
          LexerRule.new(/[^()]+/, TokenType::LiteralStringOther),
        ],

        "percent_string_angle" => [
          LexerRule.new(/>/, RuleActions.pop(TokenType::LiteralStringOther)),
          LexerRule.new(/</, RuleActions.push("percent_string_angle", TokenType::LiteralStringOther)),
          LexerRule.new(/[^<>]+/, TokenType::LiteralStringOther),
        ],

        "percent_string_other" => [
          LexerRule.new(/./, ->(match : LexerMatch, state : LexerState) {
            delimiter = state.get_context("delimiter")
            if delimiter && match.text == delimiter
              state.pop_state
              [match.make_token(TokenType::LiteralStringOther)]
            else
              [match.make_token(TokenType::LiteralStringOther)]
            end
          }),
        ],

        "heredoc" => [
          LexerRule.new(/^(\s*)(\w+)$/, ->(match : LexerMatch, state : LexerState) {
            delimiter = state.get_context("heredoc_delimiter")
            if delimiter && match.groups[1] == delimiter
              state.pop_state
              [match.make_token(TokenType::LiteralStringHeredoc)]
            else
              [match.make_token(TokenType::LiteralStringHeredoc)]
            end
          }),
          LexerRule.new(/.+/, TokenType::LiteralStringHeredoc),
        ],
      }
    end
  end
end
