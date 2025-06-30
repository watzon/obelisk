require "../lexer"

module Obelisk::Lexers
  # YAML lexer
  class YAML < RegexLexer
    def config : LexerConfig
      LexerConfig.new(
        name: "yaml",
        aliases: ["yaml", "yml"],
        filenames: ["*.yaml", "*.yml"],
        mime_types: ["text/yaml", "text/x-yaml", "application/yaml"],
        priority: 1.0f32
      )
    end

    def analyze(text : String) : Float32
      score = 0.0f32
      lines = text.lines.first(50)
      
      # Return early if clearly not YAML
      return 0.0f32 if lines.empty?
      
      # Check for YAML document start first - strong indicator
      if lines.any? { |line| line =~ /^---(\s|$)/ }
        score += 0.5
      end
      
      # Strong indicators
      lines.each do |line|
        # YAML document markers (already counted start above)
        score += 0.2 if line =~ /^\.\.\.(\s|$)/
        score += 0.2 if line =~ /^%YAML\s+/
        
        # Key-value pairs (unquoted keys) - more specific to avoid false positives
        score += 0.15 if line =~ /^[a-zA-Z_][a-zA-Z0-9_-]*:\s+[^\{\[]/
        score += 0.15 if line =~ /^\s+[a-zA-Z_][a-zA-Z0-9_-]*:\s+[^\{\[]/
        
        # Lists
        score += 0.05 if line =~ /^\s*-\s+/
        
        # YAML-specific values
        score += 0.05 if line =~ /:\s*(true|false|yes|no|on|off|null|~)\s*$/
        
        # Multi-line indicators
        score += 0.05 if line =~ /:\s*[|>]\s*$/
        
        # Anchors and aliases
        score += 0.1 if line =~ /&[a-zA-Z_][a-zA-Z0-9_]*/
        score += 0.1 if line =~ /\*[a-zA-Z_][a-zA-Z0-9_]*/
        
        # Tags
        score += 0.05 if line =~ /!![a-zA-Z]+/
        score += 0.05 if line =~ /![a-zA-Z]+/
      end
      
      # Negative indicators - only apply if they actually match
      if text =~ /^\s*\{.*\}\s*$/m  # Single line JSON
        score = [score - 0.5, 0.0f32].max
      end
      if text =~ /^\s*<\?xml/  # XML
        score = [score - 0.5, 0.0f32].max
      end
      if text.strip.starts_with?('<') && text.strip.ends_with?('>')  # HTML/XML
        score = [score - 0.3, 0.0f32].max
      end
      
      # Cap the score
      [[score, 0.0f32].max, 1.0f32].min
    end

    def rules : Hash(String, Array(LexerRule))
      {
        "root" => [
          # YAML document markers
          LexerRule.new(/^---/, TokenType::NameTag),
          LexerRule.new(/^\.\.\./, TokenType::NameTag),
          
          # Comments
          LexerRule.new(/#.*$/, TokenType::CommentSingle),
          
          # Strings with quotes
          LexerRule.new(/\"/, RuleActions.push("string_double", TokenType::LiteralStringDouble)),
          LexerRule.new(/\'/, RuleActions.push("string_single", TokenType::LiteralStringSingle)),
          
          # Multi-line strings
          LexerRule.new(/[|>][-+]?/, TokenType::Punctuation),
          
          # Keys (before colon)
          LexerRule.new(/^(\s*)([^#\s][^:]*?)(\s*)(:)(\s|$)/, RuleActions.by_groups(
            TokenType::Text,
            TokenType::NameAttribute,
            TokenType::Text,
            TokenType::Punctuation,
            TokenType::Text
          )),
          
          # Array indicators
          LexerRule.new(/^(\s*)(-)(\s)/, RuleActions.by_groups(
            TokenType::Text,
            TokenType::Punctuation,
            TokenType::Text
          )),
          
          # Boolean values
          LexerRule.new(/\b(?:true|false|yes|no|on|off)\b/i, TokenType::KeywordConstant),
          
          # Null values
          LexerRule.new(/\b(?:null|~)\b/i, TokenType::KeywordConstant),
          
          # Numbers
          LexerRule.new(/-?(?:0|[1-9]\d*)(?:\.\d+)?(?:[eE][+-]?\d+)?/, TokenType::LiteralNumber),
          LexerRule.new(/0x[0-9a-fA-F]+/, TokenType::LiteralNumberHex),
          LexerRule.new(/0o[0-7]+/, TokenType::LiteralNumberOct),
          
          # Timestamps
          LexerRule.new(/\d{4}-\d{2}-\d{2}(?:[Tt]\d{2}:\d{2}:\d{2}(?:\.\d+)?(?:[Zz]|[+-]\d{2}:\d{2})?)?/, TokenType::LiteralDate),
          
          # Tags
          LexerRule.new(/![a-zA-Z_][a-zA-Z0-9_]*/, TokenType::NameTag),
          LexerRule.new(/!<[^>]*>/, TokenType::NameTag),
          
          # Anchors and aliases
          LexerRule.new(/&[a-zA-Z_][a-zA-Z0-9_]*/, TokenType::NameLabel),
          LexerRule.new(/\*[a-zA-Z_][a-zA-Z0-9_]*/, TokenType::NameVariable),
          
          # Special characters
          LexerRule.new(/[\[\]{}]/, TokenType::Punctuation),
          LexerRule.new(/,/, TokenType::Punctuation),
          
          # Plain scalars (unquoted strings)
          LexerRule.new(/[^\s#,\[\]{}]+/, TokenType::LiteralString),
          
          # Whitespace
          LexerRule.new(/\s+/, TokenType::Text),
        ],
        
        "string_double" => [
          LexerRule.new(/\"/, RuleActions.pop(TokenType::LiteralStringDouble)),
          LexerRule.new(/\\[\"\\\/bfnrt]/, TokenType::LiteralStringEscape),
          LexerRule.new(/\\u[0-9a-fA-F]{4}/, TokenType::LiteralStringEscape),
          LexerRule.new(/\\U[0-9a-fA-F]{8}/, TokenType::LiteralStringEscape),
          LexerRule.new(/\\x[0-9a-fA-F]{2}/, TokenType::LiteralStringEscape),
          LexerRule.new(/\\./, TokenType::LiteralStringEscape),
          LexerRule.new(/[^\"\\]+/, TokenType::LiteralStringDouble),
        ],
        
        "string_single" => [
          LexerRule.new(/\'/, RuleActions.pop(TokenType::LiteralStringSingle)),
          LexerRule.new(/\'\'/, TokenType::LiteralStringEscape), # Escaped quote in single quotes
          LexerRule.new(/[^\']+/, TokenType::LiteralStringSingle),
        ],
      }
    end

  end
end