require "../lexer"

module Obelisk::Lexers
  # Shell/Bash language lexer
  class Shell < RegexLexer
    def config : LexerConfig
      LexerConfig.new(
        name: "shell",
        aliases: ["shell", "bash", "sh", "zsh", "fish"],
        filenames: ["*.sh", "*.bash", "*.zsh", "*.fish", ".bashrc", ".zshrc", ".profile"],
        mime_types: ["application/x-sh", "application/x-shellscript"],
        priority: 1.0f32
      )
    end

    def analyze(text : String) : Float32
      score = 0.0f32
      lines = text.lines.first(50) # Analyze first 50 lines

      # Shell-specific patterns
      lines.each do |line|
        # Strong indicators
        score += 0.3 if line =~ /^#!/ && line.includes?("sh")
        score += 0.2 if line =~ /^\s*if\s+.*;\s*then/
        score += 0.2 if line =~ /^\s*for\s+\w+\s+in\s+/
        score += 0.2 if line =~ /^\s*while\s+.*;\s*do/
        score += 0.15 if line =~ /^\s*function\s+\w+/
        score += 0.15 if line =~ /^\s*\w+\(\)\s*\{/
        score += 0.1 if line =~ /^\s*(echo|printf|read|export|source|cd|ls|grep|sed|awk)\b/

        # Shell-specific syntax
        score += 0.1 if line =~ /\$\{?\w+\}?/               # Variables
        score += 0.1 if line =~ /\$\d+/                     # Positional parameters
        score += 0.1 if line =~ /\$[@*#?$!]/                # Special variables
        score += 0.05 if line =~ /&&|\|\|/                  # Logical operators
        score += 0.05 if line =~ /\|\s*\w+/                 # Pipes
        score += 0.05 if line =~ /\bfi\b|\bdone\b|\besac\b/ # End keywords
        score += 0.05 if line =~ /<<\s*\w+/                 # Heredocs
      end

      # Negative indicators
      score -= 0.2 if text =~ /\bfunction\s+\w+\s*\(/ # JavaScript
      score -= 0.2 if text =~ /\bdef\s+\w+\s*\(/      # Python
      score -= 0.2 if text =~ /\bclass\s+\w+/         # OOP languages

      [score, 1.0f32].min
    end

    def rules : Hash(String, Array(LexerRule))
      {
        "root" => [
          # Whitespace
          LexerRule.new(/\s+/, TokenType::Text),

          # Shebang
          LexerRule.new(/^#!.*$/, TokenType::CommentHashbang),

          # Comments
          LexerRule.new(/#.*$/, TokenType::CommentSingle),

          # Keywords
          LexerRule.new(/\b(?:if|then|else|elif|fi|case|esac|for|while|until|do|done|break|continue|function|return|in|select|time)\b/, TokenType::Keyword),

          # Built-in commands
          LexerRule.new(/\b(?:echo|printf|read|cd|pwd|ls|mkdir|rmdir|rm|cp|mv|ln|chmod|chown|grep|sed|awk|sort|uniq|head|tail|cat|less|more|find|locate|which|whereis|man|info|help|history|alias|unalias|type|command|builtin|enable|source|exec|eval|exit|logout|export|unset|declare|readonly|local|set|unset|shift|getopts|test|true|false|kill|jobs|fg|bg|wait|trap|ulimit|umask|times)\b/, TokenType::NameBuiltin),

          # Variables
          LexerRule.new(/\$\{[^}]+\}/, TokenType::NameVariable),
          LexerRule.new(/\$[a-zA-Z_][a-zA-Z0-9_]*/, TokenType::NameVariable),
          LexerRule.new(/\$\d+/, TokenType::NameVariable),
          LexerRule.new(/\$[@*#?$!0-]/, TokenType::NameVariable),

          # Command substitution
          LexerRule.new(/\$\(/, RuleActions.push("command_substitution", TokenType::LiteralStringBacktick)),
          LexerRule.new(/`/, RuleActions.push("backtick_substitution", TokenType::LiteralStringBacktick)),

          # Heredocs
          LexerRule.new(/<<-?\s*(['"]?)(\w+)\1/, ->(match : LexerMatch, state : LexerState) {
            delimiter = match.groups[1]
            state.push_state("heredoc")
            state.set_context("heredoc_delimiter", delimiter)
            [match.make_token(TokenType::Operator)]
          }),

          # Strings
          LexerRule.new(/"/, RuleActions.push("string_double", TokenType::LiteralStringDouble)),
          LexerRule.new(/'/, RuleActions.push("string_single", TokenType::LiteralStringSingle)),

          # Function definitions
          LexerRule.new(/\b([a-zA-Z_][a-zA-Z0-9_]*)\(\)/, RuleActions.by_groups(TokenType::NameFunction)),
          LexerRule.new(/\b(function)(\s+)([a-zA-Z_][a-zA-Z0-9_]*)/, RuleActions.by_groups(TokenType::Keyword, TokenType::Text, TokenType::NameFunction)),

          # Numbers
          LexerRule.new(/\d+\.\d+/, TokenType::LiteralNumberFloat),
          LexerRule.new(/\d+/, TokenType::LiteralNumberInteger),

          # Operators
          LexerRule.new(/&&|\|\||>>|<<|>=|<=|==|!=|=~|!~/, TokenType::Operator),
          LexerRule.new(/[+\-*\/%<>=!&|^~]/, TokenType::Operator),

          # Punctuation
          LexerRule.new(/[.,;:()\[\]{}]/, TokenType::Punctuation),

          # Commands and identifiers
          LexerRule.new(/[a-zA-Z_][a-zA-Z0-9_]*/, TokenType::Name),
        ],

        "string_double" => [
          LexerRule.new(/"/, RuleActions.pop(TokenType::LiteralStringDouble)),
          LexerRule.new(/\\./, TokenType::LiteralStringEscape),
          LexerRule.new(/\$\{[^}]+\}/, TokenType::NameVariable),
          LexerRule.new(/\$[a-zA-Z_][a-zA-Z0-9_]*/, TokenType::NameVariable),
          LexerRule.new(/\$\d+/, TokenType::NameVariable),
          LexerRule.new(/\$[@*#?$!0-]/, TokenType::NameVariable),
          LexerRule.new(/\$\(/, RuleActions.push("command_substitution", TokenType::LiteralStringBacktick)),
          LexerRule.new(/`/, RuleActions.push("backtick_substitution", TokenType::LiteralStringBacktick)),
          LexerRule.new(/[^"\\$`]+/, TokenType::LiteralStringDouble),
        ],

        "string_single" => [
          LexerRule.new(/'/, RuleActions.pop(TokenType::LiteralStringSingle)),
          LexerRule.new(/[^']+/, TokenType::LiteralStringSingle),
        ],

        "command_substitution" => [
          LexerRule.new(/\)/, RuleActions.pop(TokenType::LiteralStringBacktick)),
          LexerRule.new(/[^)]+/, TokenType::LiteralStringBacktick),
        ],

        "backtick_substitution" => [
          LexerRule.new(/`/, RuleActions.pop(TokenType::LiteralStringBacktick)),
          LexerRule.new(/[^`]+/, TokenType::LiteralStringBacktick),
        ],

        "heredoc" => [
          LexerRule.new(/^(\w+)$/, ->(match : LexerMatch, state : LexerState) {
            delimiter = state.get_context("heredoc_delimiter")
            if delimiter && match.groups[0] == delimiter
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
