require "../lexer"

module Obelisk::Lexers
  # Rust language lexer
  class Rust < RegexLexer
    def config : LexerConfig
      LexerConfig.new(
        name: "rust",
        aliases: ["rust", "rs"],
        filenames: ["*.rs", "*.rs.in"],
        mime_types: ["text/rust", "text/x-rust"],
        priority: 1.0f32
      )
    end

    def analyze(text : String) : Float32
      score = 0.0f32
      lines = text.lines.first(50) # Analyze first 50 lines
      
      # Rust-specific patterns
      lines.each do |line|
        # Strong indicators
        score += 0.2 if line =~ /^\s*fn\s+\w+/                    # Function definitions
        score += 0.2 if line =~ /^\s*use\s+\w+/                   # Use statements
        score += 0.15 if line =~ /^\s*impl\s+/                    # Impl blocks
        score += 0.15 if line =~ /^\s*struct\s+\w+/               # Struct definitions
        score += 0.15 if line =~ /^\s*enum\s+\w+/                 # Enum definitions
        score += 0.15 if line =~ /^\s*trait\s+\w+/                # Trait definitions
        score += 0.1 if line =~ /^\s*mod\s+\w+/                   # Module declarations
        score += 0.1 if line =~ /^\s*let\s+(mut\s+)?\w+/          # Let bindings
        score += 0.1 if line =~ /^\s*const\s+\w+/                 # Const definitions
        
        # Type annotations
        score += 0.1 if line =~ /:\s*(i8|i16|i32|i64|u8|u16|u32|u64|f32|f64|bool|char|str|String|Vec|Option|Result)/
        score += 0.1 if line =~ /->\s*(i8|i16|i32|i64|u8|u16|u32|u64|f32|f64|bool|char|str|String|Vec|Option|Result)/
        
        # Rust-specific syntax
        score += 0.1 if line =~ /\w+!\s*\(/                       # Macro invocations
        score += 0.1 if line =~ /\w+!\s*\[/                       # Macro invocations with brackets
        score += 0.1 if line =~ /\w+!\s*\{/                       # Macro invocations with braces
        score += 0.05 if line =~ /#\[.*\]/                        # Attributes
        score += 0.05 if line =~ /#!\[.*\]/                       # Inner attributes
        score += 0.05 if line =~ /::/                             # Path separator
        score += 0.05 if line =~ /'\w+/                           # Lifetime annotations
        score += 0.05 if line =~ /&(mut\s+)?/                     # References
        score += 0.05 if line =~ /\bmatch\s+.*\s*\{/              # Match expressions
        score += 0.05 if line =~ /\|.*\|/                         # Closures
        
        # Rust-specific keywords
        score += 0.05 if line =~ /\b(async|await|dyn|move|ref|unsafe|where)\b/
      end
      
      # Negative indicators (not Rust)
      score -= 0.2 if text.includes?("function ")              # JavaScript
      score -= 0.2 if text.includes?("func ")                  # Go
      score -= 0.2 if text.includes?("public class ")          # Java
      score -= 0.2 if text.includes?("def ")                   # Python/Ruby
      score -= 0.2 if text.includes?("#include ")              # C/C++
      
      # Cap the score at 1.0
      [score, 1.0f32].min
    end

    def rules : Hash(String, Array(LexerRule))
      {
        "root" => [
          # Whitespace
          LexerRule.new(/\s+/, TokenType::Text),
          
          # Shebang and inner attributes
          LexerRule.new(/#![^\[\r\n].*$/, TokenType::CommentPreproc),
          
          # Doc comments
          LexerRule.new(/\/\/!.*?\n/, TokenType::LiteralStringDoc),
          LexerRule.new(/\/\/\/(\n|[^\/].*?\n)/, TokenType::LiteralStringDoc),
          LexerRule.new(/\/\*\*(\n|[^\/\*])/, RuleActions.push("doccomment", TokenType::LiteralStringDoc)),
          LexerRule.new(/\/\*!/, RuleActions.push("doccomment", TokenType::LiteralStringDoc)),
          
          # Regular comments
          LexerRule.new(/\/\/.*?\n/, TokenType::CommentSingle),
          LexerRule.new(/\/\*/, RuleActions.push("comment", TokenType::CommentMultiline)),
          
          # Keywords (excluding ones that have special handling)
          LexerRule.new(/\b(as|async|await|break|const|continue|crate|dyn|else|extern|false|for|if|impl|in|let|loop|match|move|mut|pub|ref|return|self|Self|static|super|trait|true|unsafe|use|where|while)\b/, TokenType::Keyword),
          
          # Reserved keywords
          LexerRule.new(/\b(abstract|become|box|do|final|macro|override|priv|try|typeof|unsized|virtual|yield)\b/, TokenType::KeywordReserved),
          
          # Built-in types
          LexerRule.new(/\b(bool|char|f32|f64|i8|i16|i32|i64|i128|isize|str|u8|u16|u32|u64|u128|usize)\b/, TokenType::KeywordType),
          
          # Built-in traits and types
          LexerRule.new(/\b(AsRef|AsMut|Box|Clone|Copy|Default|DoubleEndedIterator|Drop|Eq|Err|ExactSizeIterator|Extend|Fn|FnMut|FnOnce|From|IntoIterator|Into|Iterator|None|Ok|Option|Ord|PartialEq|PartialOrd|Result|Send|Sized|Some|String|Sync|ToOwned|ToString|Unpin|Vec|drop)\b/, TokenType::NameBuiltin),
          
          # Function declarations
          LexerRule.new(/\bfn\b/, RuleActions.push("funcname", TokenType::Keyword)),
          
          # Type declarations
          LexerRule.new(/\b(struct|enum|type|union)\b/, RuleActions.push("typename", TokenType::Keyword)),
          
          # Module declarations
          LexerRule.new(/\bmod\b/, RuleActions.push("modname", TokenType::Keyword)),
          
          # Lifetimes
          LexerRule.new(/'static\b/, TokenType::NameBuiltin),
          LexerRule.new(/'_\b/, TokenType::NameBuiltin),
          LexerRule.new(/'[a-zA-Z_]\w*\b/, TokenType::NameAttribute),
          
          # Attributes
          LexerRule.new(/#!?\[/, RuleActions.push("attribute", TokenType::NameDecorator)),
          
          # Macros with format strings
          LexerRule.new(/\b(println!|print!|eprintln!|eprint!|format!|format_args!|panic!|todo!|unreachable!|unimplemented!)\s*\(\s*"/, ->(match : String, state : LexerState, groups : Array(String)) {
            # Extract macro name
            macro_name = match[/\w+!/]
            state.push_state("formatted_string")
            [
              Token.new(TokenType::NameFunctionMagic, macro_name),
              Token.new(TokenType::Text, match[macro_name.size..-2]),
              Token.new(TokenType::LiteralStringDouble, "\"")
            ]
          }),
          
          # Regular macros
          LexerRule.new(/[a-zA-Z_]\w*!\s*[\(\[\{]/, ->(match : String, state : LexerState, groups : Array(String)) {
            macro_name = match[/\w+!/]
            rest = match[macro_name.size..-1]
            [
              Token.new(TokenType::NameFunctionMagic, macro_name),
              Token.new(TokenType::Text, rest[0..-2]),
              Token.new(TokenType::Punctuation, rest[-1].to_s)
            ]
          }),
          
          # Constants (all caps)
          LexerRule.new(/\b(r#)?[A-Z][A-Z0-9_]+\b/, TokenType::NameConstant),
          
          # Character literals
          LexerRule.new(/'(\\['"\\nrt]|\\x[0-7][0-9a-fA-F]|\\0|\\u\{[0-9a-fA-F]{1,6}\}|.)'/, TokenType::LiteralStringChar),
          
          # Byte character literals
          LexerRule.new(/b'(\\['"\\nrt]|\\x[0-9a-fA-F]{2}|\\0|.)'/, TokenType::LiteralStringChar),
          
          # Numbers with type suffixes
          LexerRule.new(/0b[01_]+([ui](8|16|32|64|128|size))?/, TokenType::LiteralNumberBin),
          LexerRule.new(/0o[0-7_]+([ui](8|16|32|64|128|size))?/, TokenType::LiteralNumberOct),
          LexerRule.new(/0x[0-9a-fA-F_]+([ui](8|16|32|64|128|size))?/, TokenType::LiteralNumberHex),
          LexerRule.new(/[0-9][0-9_]*(\.[0-9_]+)?([eE][+-]?[0-9_]+)?(f32|f64)?/, TokenType::LiteralNumberFloat),
          LexerRule.new(/[0-9][0-9_]*([ui](8|16|32|64|128|size))?/, TokenType::LiteralNumberInteger),
          
          # Raw strings
          LexerRule.new(/r#+"/, ->(match : String, state : LexerState, groups : Array(String)) {
            # Count the number of # symbols
            hash_count = match.count('#') - 1
            state.push_state("rawstring_#{hash_count}")
            [Token.new(TokenType::LiteralString, match)]
          }),
          
          # Byte strings
          LexerRule.new(/b"/, RuleActions.push("bytestring", TokenType::LiteralString)),
          
          # Regular strings
          LexerRule.new(/"/, RuleActions.push("string", TokenType::LiteralStringDouble)),
          
          # Operators and punctuation
          LexerRule.new(/::/, TokenType::Operator),
          LexerRule.new(/->/, TokenType::Operator),
          LexerRule.new(/\.\.=?/, TokenType::Operator),
          LexerRule.new(/[+\-*\/%&|<>=!^~@]+/, TokenType::Operator),
          LexerRule.new(/[{}()\[\],.;:]/, TokenType::Punctuation),
          
          # Raw identifiers
          LexerRule.new(/r#[a-zA-Z_]\w*/, TokenType::Name),
          
          # Regular identifiers
          LexerRule.new(/[a-zA-Z_]\w*/, TokenType::Name),
        ],
        
        "string" => [
          LexerRule.new(/"/, RuleActions.pop(TokenType::LiteralStringDouble)),
          LexerRule.new(/\\['"\\nrt]|\\(?=\n)|\\x[0-7][0-9a-fA-F]|\\0|\\u\{[0-9a-fA-F]{1,6}\}/, TokenType::LiteralStringEscape),
          LexerRule.new(/[^\\"]+/, TokenType::LiteralStringDouble),
          LexerRule.new(/\\/, TokenType::LiteralStringDouble),
        ],
        
        "formatted_string" => [
          LexerRule.new(/"/, RuleActions.pop(TokenType::LiteralStringDouble)),
          LexerRule.new(/\\['"\\nrt]|\\(?=\n)|\\x[0-7][0-9a-fA-F]|\\0|\\u\{[0-9a-fA-F]{1,6}\}|\{\{|\}\}/, TokenType::LiteralStringEscape),
          LexerRule.new(/\{[^}]*\}/, TokenType::LiteralStringInterpol),
          LexerRule.new(/[^\\"{}]+/, TokenType::LiteralStringDouble),
          LexerRule.new(/\\/, TokenType::LiteralStringDouble),
        ],
        
        "bytestring" => [
          LexerRule.new(/"/, RuleActions.pop(TokenType::LiteralString)),
          LexerRule.new(/\\x[89a-fA-F][0-9a-fA-F]/, TokenType::LiteralStringEscape),
          LexerRule.new(/\\['"\\nrt]|\\(?=\n)|\\x[0-7][0-9a-fA-F]|\\0/, TokenType::LiteralStringEscape),
          LexerRule.new(/[^\\"]+/, TokenType::LiteralString),
          LexerRule.new(/\\/, TokenType::LiteralString),
        ],
        
        "comment" => [
          LexerRule.new(/[^*\/]+/, TokenType::CommentMultiline),
          LexerRule.new(/\/\*/, RuleActions.push("comment", TokenType::CommentMultiline)),
          LexerRule.new(/\*\//, RuleActions.pop(TokenType::CommentMultiline)),
          LexerRule.new(/[*\/]/, TokenType::CommentMultiline),
        ],
        
        "doccomment" => [
          LexerRule.new(/[^*\/]+/, TokenType::LiteralStringDoc),
          LexerRule.new(/\/\*/, RuleActions.push("doccomment", TokenType::LiteralStringDoc)),
          LexerRule.new(/\*\//, RuleActions.pop(TokenType::LiteralStringDoc)),
          LexerRule.new(/[*\/]/, TokenType::LiteralStringDoc),
        ],
        
        "attribute" => [
          LexerRule.new(/\]/, RuleActions.pop(TokenType::NameDecorator)),
          LexerRule.new(/"/, RuleActions.push("string", TokenType::LiteralStringDouble)),
          LexerRule.new(/\[/, RuleActions.push("attribute", TokenType::NameDecorator)),
          LexerRule.new(/[^\]"\[]+/, TokenType::NameDecorator),
        ],
        
        "funcname" => [
          LexerRule.new(/\s+/, TokenType::Text),
          LexerRule.new(/[a-zA-Z_]\w*/, RuleActions.pop(TokenType::NameFunction)),
          LexerRule.new(//, RuleActions.pop),
        ],
        
        "typename" => [
          LexerRule.new(/\s+/, TokenType::Text),
          LexerRule.new(/[a-zA-Z_]\w*/, RuleActions.pop(TokenType::NameClass)),
          LexerRule.new(//, RuleActions.pop),
        ],
        
        "modname" => [
          LexerRule.new(/\s+/, TokenType::Text),
          LexerRule.new(/[a-zA-Z_]\w*/, RuleActions.pop(TokenType::NameNamespace)),
          LexerRule.new(//, RuleActions.pop),
        ],
      }.tap do |rules|
        # Add dynamic raw string states
        (0..10).each do |n|
          closing = "\"" + "#" * n
          rules["rawstring_#{n}"] = [
            LexerRule.new(/.*?#{Regex.escape(closing)}/, ->(match : String, state : LexerState, groups : Array(String)) {
              state.pop_state
              [Token.new(TokenType::LiteralString, match)]
            }),
            LexerRule.new(/.+/, TokenType::LiteralString),
          ]
        end
      end
    end
  end
end