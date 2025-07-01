require "../lexer"

module Obelisk::Lexers
  # Ruby language lexer
  class Ruby < RegexLexer
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
      lines = text.lines.first(50) # Analyze first 50 lines

      # Ruby-specific patterns
      lines.each do |line|
        # Strong indicators
        score += 0.2 if line =~ /^\s*require\s+["']/
        score += 0.2 if line =~ /^\s*class\s+[A-Z]\w*/
        score += 0.2 if line =~ /^\s*module\s+[A-Z]\w*/
        score += 0.15 if line =~ /^\s*def\s+\w+/
        score += 0.1 if line =~ /^\s*attr_(reader|writer|accessor)/
        score += 0.1 if line =~ /^\s*gem\s+["']/

        # Ruby-specific syntax
        score += 0.1 if line =~ /@\w+/           # Instance variables
        score += 0.1 if line =~ /@@\w+/          # Class variables
        score += 0.1 if line =~ /\$\w+/          # Global variables
        score += 0.05 if line =~ /:[a-zA-Z_]\w*/ # Symbols
        score += 0.05 if line =~ /\b(elsif|unless|rescue|ensure)\b/
        score += 0.05 if line =~ /\b(nil|true|false)\b/
        score += 0.05 if line =~ /\bdo\s*\|.*\|/ # Blocks with parameters
        score += 0.05 if line =~ /\{\s*\|.*\|/   # Block with parameters
        score += 0.05 if line =~ /\bend\b/       # end keyword
      end

      # Negative indicators (not Ruby)
      score -= 0.2 if text =~ /\bfunction\s+\w+/ # JavaScript
      score -= 0.2 if text =~ /\bfunc\s+\w+/     # Go
      score -= 0.2 if text =~ /\bvoid\s+\w+/     # C/C++/Java

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
          LexerRule.new(/\b(?:BEGIN|END|alias|begin|break|case|class|def|defined\?|do|else|elsif|end|ensure|for|if|in|module|next|nil|redo|rescue|retry|return|self|super|then|undef|unless|until|when|while|yield)\b/, TokenType::Keyword),

          # Special keywords
          LexerRule.new(/\b(?:and|not|or)\b/, TokenType::OperatorWord),

          # Pseudo-variables
          LexerRule.new(/\b(?:__FILE__|__LINE__|__ENCODING__)\b/, TokenType::NameBuiltinPseudo),

          # Built-in functions
          LexerRule.new(/\b(?:abort|at_exit|autoload|binding|callcc|caller|caller_locations|catch|chomp|chop|eval|exec|exit|exit!|fail|fork|format|gets|global_variables|gsub|lambda|load|local_variables|open|p|print|printf|proc|putc|puts|raise|rand|readline|readlines|require|require_relative|select|set_trace_func|sleep|spawn|sprintf|srand|sub|syscall|system|test|throw|trace_var|trap|untrace_var|warn)\b/, TokenType::NameBuiltin),

          # Constants (uppercase identifiers)
          LexerRule.new(/\b[A-Z][A-Z0-9_]*\b/, TokenType::NameConstant),

          # Class/Module names (PascalCase)
          LexerRule.new(/\b[A-Z][a-zA-Z0-9_]*\b/, TokenType::NameClass),

          # Instance variables
          LexerRule.new(/@[a-zA-Z_]\w*/, TokenType::NameVariableInstance),

          # Class variables
          LexerRule.new(/@@[a-zA-Z_]\w*/, TokenType::NameVariableClass),

          # Global variables
          LexerRule.new(/\$[a-zA-Z_]\w*/, TokenType::NameVariableGlobal),
          LexerRule.new(/\$[!@&`'+~=\/\\,;.<>_*$?:"]/, TokenType::NameVariableGlobal), # Special globals
          LexerRule.new(/\$-[0adFiIlpvw]/, TokenType::NameVariableGlobal),             # Special globals
          LexerRule.new(/\$\d+/, TokenType::NameVariableGlobal),                       # Numbered groups

          # Symbols
          LexerRule.new(/:(?:[a-zA-Z_]\w*[!?]?|[+\-*\/%<>=!&|^~]+)/, TokenType::LiteralStringSymbol),
          LexerRule.new(/:'/, RuleActions.push("string_symbol_single", TokenType::LiteralStringSymbol)),
          LexerRule.new(/:"/, RuleActions.push("string_symbol_double", TokenType::LiteralStringSymbol)),

          # Numbers
          LexerRule.new(/0b[01_]+/, TokenType::LiteralNumberBin),
          LexerRule.new(/0o[0-7_]+/, TokenType::LiteralNumberOct),
          LexerRule.new(/0x[0-9a-fA-F_]+/, TokenType::LiteralNumberHex),
          LexerRule.new(/\d+\.\d+([eE][+-]?\d+)?/, TokenType::LiteralNumberFloat),
          LexerRule.new(/\d+[eE][+-]?\d+/, TokenType::LiteralNumberFloat),
          LexerRule.new(/\d+(_\d+)*/, TokenType::LiteralNumberInteger),

          # Strings
          LexerRule.new(/"/, RuleActions.push("string_double", TokenType::LiteralStringDouble)),
          LexerRule.new(/'/, RuleActions.push("string_single", TokenType::LiteralStringSingle)),
          LexerRule.new(/`/, RuleActions.push("string_backtick", TokenType::LiteralStringBacktick)),

          # Regular expressions
          LexerRule.new(/\/(?:[^\/\\\n]|\\.)+\/[mixounse]*/, TokenType::LiteralStringRegex),

          # Percent strings
          LexerRule.new(/%[qQ]?\{/, RuleActions.push("percent_string_curly", TokenType::LiteralStringOther)),
          LexerRule.new(/%[qQ]?\[/, RuleActions.push("percent_string_square", TokenType::LiteralStringOther)),
          LexerRule.new(/%[qQ]?\(/, RuleActions.push("percent_string_paren", TokenType::LiteralStringOther)),
          LexerRule.new(/%[qQ]?</, RuleActions.push("percent_string_angle", TokenType::LiteralStringOther)),
          LexerRule.new(/%[qQ]?([^\w\s])/, ->(match : String, state : LexerState, groups : Array(String)) {
            delimiter = groups[0]
            state.push_state("percent_string_other")
            state.set_context("delimiter", delimiter)
            [Token.new(TokenType::LiteralStringOther, match)]
          }),

          # Method definitions
          LexerRule.new(/\b(def)(\s+)([a-zA-Z_]\w*[!?=]?)/, RuleActions.by_groups(TokenType::Keyword, TokenType::Text, TokenType::NameFunction)),

          # Function calls and method names
          LexerRule.new(/[a-zA-Z_]\w*[!?]?(?=\s*\()/, TokenType::NameFunction),
          LexerRule.new(/[a-zA-Z_]\w*[!?]?/, TokenType::Name),

          # Operators
          LexerRule.new(/[+\-*\/%<>=!&|^~]+/, TokenType::Operator),
          LexerRule.new(/[.,;:()\[\]{}]/, TokenType::Punctuation),

          # Range operators
          LexerRule.new(/\.\.\.?/, TokenType::Operator),

          # Hash rockets
          LexerRule.new(/=>/, TokenType::Operator),

          # Heredocs
          LexerRule.new(/<<[-~]?(['"]?)([A-Z_]+)\1/, ->(match : String, state : LexerState, groups : Array(String)) {
            delimiter = groups[1]
            state.push_state("heredoc")
            state.set_context("heredoc_delimiter", delimiter)
            [Token.new(TokenType::LiteralStringHeredoc, match)]
          }),
        ],

        "string_double" => [
          LexerRule.new(/"/, RuleActions.pop(TokenType::LiteralStringDouble)),
          LexerRule.new(/\\[\\\"'nrtbfav0]/, TokenType::LiteralStringEscape),
          LexerRule.new(/\\u\{[0-9a-fA-F]+\}/, TokenType::LiteralStringEscape),
          LexerRule.new(/\\u[0-9a-fA-F]{4}/, TokenType::LiteralStringEscape),
          LexerRule.new(/\\x[0-9a-fA-F]{2}/, TokenType::LiteralStringEscape),
          LexerRule.new(/\\[0-7]{1,3}/, TokenType::LiteralStringEscape),
          LexerRule.new(/\\./, TokenType::LiteralStringEscape),
          LexerRule.new(/#\{/, RuleActions.push("string_interpolation", TokenType::LiteralStringInterpol)),
          LexerRule.new(/#@@?\w+/, TokenType::LiteralStringInterpol), # Simple interpolation
          LexerRule.new(/#\$\w+/, TokenType::LiteralStringInterpol),  # Simple interpolation
          LexerRule.new(/[^"\\#]+/, TokenType::LiteralStringDouble),
          LexerRule.new(/#(?!\{|[@$])/, TokenType::LiteralStringDouble),
        ],

        "string_single" => [
          LexerRule.new(/'/, RuleActions.pop(TokenType::LiteralStringSingle)),
          LexerRule.new(/\\[\\']/, TokenType::LiteralStringEscape),
          LexerRule.new(/[^'\\]+/, TokenType::LiteralStringSingle),
          LexerRule.new(/\\/, TokenType::LiteralStringSingle),
        ],

        "string_backtick" => [
          LexerRule.new(/`/, RuleActions.pop(TokenType::LiteralStringBacktick)),
          LexerRule.new(/\\[\\`]/, TokenType::LiteralStringEscape),
          LexerRule.new(/#\{/, RuleActions.push("string_interpolation", TokenType::LiteralStringInterpol)),
          LexerRule.new(/#@@?\w+/, TokenType::LiteralStringInterpol), # Simple interpolation
          LexerRule.new(/#\$\w+/, TokenType::LiteralStringInterpol),  # Simple interpolation
          LexerRule.new(/[^`\\#]+/, TokenType::LiteralStringBacktick),
          LexerRule.new(/#(?!\{|[@$])/, TokenType::LiteralStringBacktick),
        ],

        "string_symbol_single" => [
          LexerRule.new(/'/, RuleActions.pop(TokenType::LiteralStringSymbol)),
          LexerRule.new(/\\[\\']/, TokenType::LiteralStringEscape),
          LexerRule.new(/[^'\\]+/, TokenType::LiteralStringSymbol),
          LexerRule.new(/\\/, TokenType::LiteralStringSymbol),
        ],

        "string_symbol_double" => [
          LexerRule.new(/"/, RuleActions.pop(TokenType::LiteralStringSymbol)),
          LexerRule.new(/\\[\\\"'nrtbfav0]/, TokenType::LiteralStringEscape),
          LexerRule.new(/\\u\{[0-9a-fA-F]+\}/, TokenType::LiteralStringEscape),
          LexerRule.new(/\\u[0-9a-fA-F]{4}/, TokenType::LiteralStringEscape),
          LexerRule.new(/\\x[0-9a-fA-F]{2}/, TokenType::LiteralStringEscape),
          LexerRule.new(/\\./, TokenType::LiteralStringEscape),
          LexerRule.new(/#\{/, RuleActions.push("string_interpolation", TokenType::LiteralStringInterpol)),
          LexerRule.new(/#@@?\w+/, TokenType::LiteralStringInterpol),
          LexerRule.new(/#\$\w+/, TokenType::LiteralStringInterpol),
          LexerRule.new(/[^"\\#]+/, TokenType::LiteralStringSymbol),
          LexerRule.new(/#(?!\{|[@$])/, TokenType::LiteralStringSymbol),
        ],

        "string_interpolation" => [
          LexerRule.new(/\}/, RuleActions.pop(TokenType::LiteralStringInterpol)),
          # This is simplified - in reality we'd recursively parse Ruby code
          LexerRule.new(/[^}]+/, TokenType::Text),
        ],

        "percent_string_curly" => [
          LexerRule.new(/\}/, RuleActions.pop(TokenType::LiteralStringOther)),
          LexerRule.new(/\{/, RuleActions.push("percent_string_curly", TokenType::LiteralStringOther)), # Nested
          LexerRule.new(/[^{}]+/, TokenType::LiteralStringOther),
        ],

        "percent_string_square" => [
          LexerRule.new(/\]/, RuleActions.pop(TokenType::LiteralStringOther)),
          LexerRule.new(/\[/, RuleActions.push("percent_string_square", TokenType::LiteralStringOther)), # Nested
          LexerRule.new(/[^\[\]]+/, TokenType::LiteralStringOther),
        ],

        "percent_string_paren" => [
          LexerRule.new(/\)/, RuleActions.pop(TokenType::LiteralStringOther)),
          LexerRule.new(/\(/, RuleActions.push("percent_string_paren", TokenType::LiteralStringOther)), # Nested
          LexerRule.new(/[^()]+/, TokenType::LiteralStringOther),
        ],

        "percent_string_angle" => [
          LexerRule.new(/>/, RuleActions.pop(TokenType::LiteralStringOther)),
          LexerRule.new(/</, RuleActions.push("percent_string_angle", TokenType::LiteralStringOther)), # Nested
          LexerRule.new(/[^<>]+/, TokenType::LiteralStringOther),
        ],

        "percent_string_other" => [
          LexerRule.new(/./, ->(match : String, state : LexerState, groups : Array(String)) {
            delimiter = state.get_context("delimiter")
            if delimiter && match == delimiter
              state.pop_state
              [Token.new(TokenType::LiteralStringOther, match)]
            else
              [Token.new(TokenType::LiteralStringOther, match)]
            end
          }),
        ],

        "heredoc" => [
          LexerRule.new(/^(\s*)(\w+)$/, ->(match : String, state : LexerState, groups : Array(String)) {
            delimiter = state.get_context("heredoc_delimiter")
            if delimiter && groups[1] == delimiter
              state.pop_state
              [Token.new(TokenType::LiteralStringHeredoc, match)]
            else
              [Token.new(TokenType::LiteralStringHeredoc, match)]
            end
          }),
          LexerRule.new(/.+/, TokenType::LiteralStringHeredoc),
        ],
      }
    end
  end
end
