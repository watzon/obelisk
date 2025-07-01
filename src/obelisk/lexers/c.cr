require "../lexer"

module Obelisk::Lexers
  # C/C++ language lexer
  class C < RegexLexer
    def config : LexerConfig
      LexerConfig.new(
        name: "c",
        aliases: ["c", "cpp", "c++", "cc", "cxx"],
        filenames: ["*.c", "*.h", "*.cpp", "*.hpp", "*.cc", "*.hh", "*.cxx", "*.hxx", "*.C", "*.H", "*.cp", "*.CPP"],
        mime_types: ["text/x-chdr", "text/x-csrc", "text/x-c++hdr", "text/x-c++src"],
        priority: 1.0f32
      )
    end

    def analyze(text : String) : Float32
      score = 0.0f32
      lines = text.lines.first(50) # Analyze first 50 lines
      
      # C/C++ specific patterns
      lines.each do |line|
        # Strong indicators
        score += 0.3 if line =~ /^\s*#include\s*[<"]/
        score += 0.2 if line =~ /^\s*#define\s+\w+/
        score += 0.15 if line =~ /^\s*(class|struct)\s+\w+/
        score += 0.15 if line =~ /^\s*namespace\s+\w+/
        score += 0.1 if line =~ /^\s*template\s*</
        score += 0.1 if line =~ /^\s*typedef\s+/
        score += 0.1 if line =~ /^\s*using\s+namespace\s+/
        
        # Function definitions - more flexible pattern
        score += 0.15 if line =~ /\b(?:void|int|char|float|double|bool|auto)\s+\w+\s*\(/
        score += 0.1 if line =~ /\bmain\s*\(/  # main function is very C/C++ specific
        
        # C++ specific
        score += 0.05 if line =~ /\b(?:virtual|override|nullptr|constexpr|noexcept)\b/
        score += 0.05 if line =~ /::/  # Scope resolution operator
        score += 0.05 if line =~ /->/ # Member pointer operator
        score += 0.05 if line =~ /\bnew\s+\w+/
        score += 0.05 if line =~ /\bdelete\s+/
        
        # Common patterns
        score += 0.03 if line =~ /;\s*$/
        score += 0.02 if line =~ /\{$/
        score += 0.02 if line =~ /^\s*\}/
        score += 0.05 if line =~ /\breturn\s+\d+\s*;/  # return statements with numbers
        
        # C library functions
        score += 0.1 if line =~ /\b(?:printf|scanf|malloc|free|strcmp|strcpy|strlen)\s*\(/
        score += 0.1 if line =~ /\bstd::/  # C++ standard library
      end
      
      # Cap the score at 1.0
      [score, 1.0f32].min
    end

    def rules : Hash(String, Array(LexerRule))
      {
        "root" => [
          # Whitespace
          LexerRule.new(/\s+/, TokenType::Text),
          
          # Preprocessor directives
          LexerRule.new(/^\s*#\s*(?:include|define|undef|ifdef|ifndef|if|elif|else|endif|line|error|warning|pragma)\b/, RuleActions.push("preprocessor", TokenType::CommentPreproc)),
          
          # Comments
          LexerRule.new(/\/\/.*?(?=\n|$)/, TokenType::CommentSingle),
          LexerRule.new(/\/\*/, RuleActions.push("multiline_comment", TokenType::CommentMultiline)),
          
          # Keywords - C
          LexerRule.new(/\b(?:auto|break|case|const|continue|default|do|else|enum|extern|for|goto|if|register|restrict|return|sizeof|static|struct|switch|typedef|union|volatile|while|_Alignas|_Alignof|_Atomic|_Bool|_Complex|_Generic|_Imaginary|_Noreturn|_Static_assert|_Thread_local)\b/, TokenType::Keyword),
          
          # Keywords - C++
          LexerRule.new(/\b(?:alignas|alignof|and|and_eq|asm|atomic_cancel|atomic_commit|atomic_noexcept|bitand|bitor|catch|class|compl|concept|consteval|constexpr|constinit|const_cast|co_await|co_return|co_yield|decltype|delete|dynamic_cast|explicit|export|friend|inline|mutable|namespace|new|noexcept|not|not_eq|operator|or|or_eq|override|private|protected|public|reflexpr|reinterpret_cast|requires|static_assert|static_cast|synchronized|template|this|thread_local|throw|try|typeid|typename|using|virtual|xor|xor_eq)\b/, TokenType::Keyword),
          
          # Built-in types
          LexerRule.new(/\b(?:void|char|short|int|long|float|double|signed|unsigned|bool|wchar_t|char8_t|char16_t|char32_t|size_t|ptrdiff_t|nullptr_t|max_align_t|auto)\b/, TokenType::KeywordType),
          
          # Standard library types (common ones)
          LexerRule.new(/\b(?:FILE|std::string|std::vector|std::map|std::set|std::pair|std::unique_ptr|std::shared_ptr|std::weak_ptr)\b/, TokenType::NameClass),
          
          # Constants
          LexerRule.new(/\b(?:true|false|NULL|nullptr)\b/, TokenType::KeywordConstant),
          LexerRule.new(/\b[A-Z_][A-Z0-9_]*\b/, TokenType::NameConstant),
          
          # Hexadecimal numbers
          LexerRule.new(/0[xX][0-9a-fA-F]+(?:[uU](?:ll|LL|l|L)?|(?:ll|LL|l|L)[uU]?)?/, TokenType::LiteralNumberHex),
          
          # Octal numbers
          LexerRule.new(/0[0-7]+(?:[uU](?:ll|LL|l|L)?|(?:ll|LL|l|L)[uU]?)?/, TokenType::LiteralNumberOct),
          
          # Binary numbers (C++14)
          LexerRule.new(/0[bB][01]+(?:[uU](?:ll|LL|l|L)?|(?:ll|LL|l|L)[uU]?)?/, TokenType::LiteralNumberBin),
          
          # Floating point numbers
          LexerRule.new(/(?:\d+\.\d*|\.\d+)(?:[eE][+-]?\d+)?[fFlL]?/, TokenType::LiteralNumberFloat),
          LexerRule.new(/\d+[eE][+-]?\d+[fFlL]?/, TokenType::LiteralNumberFloat),
          
          # Integer numbers
          LexerRule.new(/\d+(?:[uU](?:ll|LL|l|L)?|(?:ll|LL|l|L)[uU]?)?/, TokenType::LiteralNumberInteger),
          
          # Character literals
          LexerRule.new(/L?'(?:[^'\\]|\\.)'/, TokenType::LiteralStringChar),
          LexerRule.new(/u8?'(?:[^'\\]|\\.)'/, TokenType::LiteralStringChar),
          LexerRule.new(/(?:u|U|L)'(?:[^'\\]|\\.)'/, TokenType::LiteralStringChar),
          
          # String literals
          LexerRule.new(/L?"/, RuleActions.push("string", TokenType::LiteralStringDouble)),
          LexerRule.new(/u8?"/, RuleActions.push("string", TokenType::LiteralStringDouble)),
          LexerRule.new(/(?:u|U|L)"/, RuleActions.push("string", TokenType::LiteralStringDouble)),
          
          # Raw string literals (C++11)
          LexerRule.new(/R"([^(]*)\(/, ->(match : String, state : LexerState, groups : Array(String)) {
            delimiter = groups[0]
            state.push_state("raw_string_#{delimiter}")
            state.set_context("raw_delimiter", delimiter)
            [Token.new(TokenType::LiteralStringDouble, match)]
          }),
          
          # Scope resolution operator
          LexerRule.new(/::/, TokenType::Operator),
          
          # Operators
          LexerRule.new(/\+\+|--|\+=|-=|\*=|\/=|%=|&=|\|=|\^=|<<=|>>=/, TokenType::Operator),
          LexerRule.new(/->\*|\.\*|<<|>>|->/, TokenType::Operator),  # Put ->* first to match before ->
          LexerRule.new(/&&|\|\||<=|>=|==|!=/, TokenType::Operator),
          LexerRule.new(/[+\-*\/%&|^~<>=!?:]/, TokenType::Operator),
          
          # Punctuation
          LexerRule.new(/[.,;()\[\]{}]/, TokenType::Punctuation),
          
          # Identifiers and function calls
          LexerRule.new(/[a-zA-Z_]\w*(?=\s*\()/, TokenType::NameFunction),
          LexerRule.new(/[a-zA-Z_]\w*/, TokenType::Name),
        ],
        
        "preprocessor" => [
          # Include statements
          LexerRule.new(/<[^>]+>/, TokenType::LiteralString),
          LexerRule.new(/"[^"]+?"/, TokenType::LiteralString),
          
          # Macros and identifiers
          LexerRule.new(/[a-zA-Z_]\w*/, TokenType::Name),
          
          # Numbers in preprocessor
          LexerRule.new(/\d+/, TokenType::LiteralNumberInteger),
          
          # Line continuation
          LexerRule.new(/\\$/, TokenType::CommentPreproc),
          
          # End of line
          LexerRule.new(/\n/, RuleActions.pop(TokenType::Text)),
          
          # Comments within preprocessor
          LexerRule.new(/\/\/.*?(?=\n|$)/, TokenType::CommentSingle),
          LexerRule.new(/\/\*/, RuleActions.push("multiline_comment", TokenType::CommentMultiline)),
          
          # Other preprocessor content
          LexerRule.new(/./, TokenType::CommentPreproc),
        ],
        
        "multiline_comment" => [
          LexerRule.new(/\*\//, RuleActions.pop(TokenType::CommentMultiline)),
          LexerRule.new(/[^*]+/, TokenType::CommentMultiline),
          LexerRule.new(/\*/, TokenType::CommentMultiline),
        ],
        
        "string" => [
          LexerRule.new(/"/, RuleActions.pop(TokenType::LiteralStringDouble)),
          LexerRule.new(/\\[\\'"abfnrtv0]/, TokenType::LiteralStringEscape),
          LexerRule.new(/\\x[0-9a-fA-F]{2}/, TokenType::LiteralStringEscape),
          LexerRule.new(/\\u[0-9a-fA-F]{4}/, TokenType::LiteralStringEscape),
          LexerRule.new(/\\U[0-9a-fA-F]{8}/, TokenType::LiteralStringEscape),
          LexerRule.new(/\\[0-7]{1,3}/, TokenType::LiteralStringEscape),
          LexerRule.new(/\\./, TokenType::LiteralStringEscape),
          LexerRule.new(/[^"\\]+/, TokenType::LiteralStringDouble),
        ],
      }
    end

    # Override to handle raw string literals dynamically
    def state_rules(state : String) : Array(LexerRule)
      if state.starts_with?("raw_string_")
        # Dynamic raw string state
        delimiter = state[11..-1]  # Remove "raw_string_" prefix
        [
          LexerRule.new(/.*?\)#{Regex.escape(delimiter)}"/, RuleActions.pop(TokenType::LiteralStringDouble)),
          LexerRule.new(/.+/, TokenType::LiteralStringDouble),
        ]
      else
        super
      end
    end
  end
end