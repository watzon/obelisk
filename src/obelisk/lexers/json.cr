require "../lexer"

module Obelisk::Lexers
  # JSON lexer
  class JSON < RegexLexer
    def config : LexerConfig
      LexerConfig.new(
        name: "json",
        aliases: ["json"],
        filenames: ["*.json"],
        mime_types: ["application/json", "text/json"],
        priority: 1.0f32
      )
    end

    def analyze(text : String) : Float32
      score = 0.0f32
      trimmed = text.strip
      
      # Strong indicators for JSON with proper balance checking
      if trimmed.starts_with?('{') && trimmed.ends_with?('}')
        # Check if braces are actually balanced
        if balanced_braces?(trimmed, '{', '}')
          score += 0.4
        else
          score += 0.1  # Partial credit for starting correctly
        end
      elsif trimmed.starts_with?('[') && trimmed.ends_with?(']')
        # Check if brackets are actually balanced
        if balanced_braces?(trimmed, '[', ']')
          score += 0.4
        else
          score += 0.1  # Partial credit for starting correctly
        end
      end
      
      # Check for JSON patterns
      lines = text.lines.first(30)
      lines.each do |line|
        # Key-value pairs with quotes (more flexible matching)
        score += 0.1 if line =~ /"[^"]+"\s*:\s*/
        
        # JSON values
        score += 0.05 if line =~ /:\s*(true|false|null)\b/
        score += 0.05 if line =~ /:\s*"[^"]*"/
        score += 0.05 if line =~ /:\s*-?\d+(\.\d+)?([eE][+-]?\d+)?/
        score += 0.05 if line =~ /:\s*\{/
        score += 0.05 if line =~ /:\s*\[/
        
        # Structural elements
        score += 0.02 if line =~ /^\s*\{/
        score += 0.02 if line =~ /^\s*\}/
        score += 0.02 if line =~ /^\s*\[/
        score += 0.02 if line =~ /^\s*\]/
        score += 0.02 if line =~ /,\s*$/
      end
      
      # Negative indicators (not JSON)
      score -= 0.5 if text =~ /^\s*<\?xml/  # XML
      score -= 0.5 if text =~ /^\s*<!DOCTYPE/  # HTML
      score -= 0.8 if text =~ /^---(\s|$)/  # YAML document start
      score -= 0.3 if lines.any? { |l| l =~ /^\s*-\s+\w/ }  # YAML lists
      
      # Cap the score
      [[score, 0.0f32].max, 1.0f32].min
    end

    private def balanced_braces?(text : String, open : Char, close : Char) : Bool
      count = 0
      in_string = false
      escaped = false
      
      text.each_char do |char|
        if escaped
          escaped = false
          next
        end
        
        case char
        when '\\'
          escaped = true if in_string
        when '"'
          in_string = !in_string
        when open
          count += 1 unless in_string
        when close
          count -= 1 unless in_string
          return false if count < 0
        end
      end
      
      count == 0
    end

    def rules : Hash(String, Array(LexerRule))
      {
        "root" => [
          # Whitespace
          LexerRule.new(/\s+/, TokenType::Text),
          
          # Strings
          LexerRule.new(/\"/, RuleActions.push("string", TokenType::LiteralStringDouble)),
          
          # Numbers
          LexerRule.new(/-?(?:0|[1-9]\d*)(?:\.\d+)?(?:[eE][+-]?\d+)?/, TokenType::LiteralNumber),
          
          # Literals
          LexerRule.new(/\btrue\b/, TokenType::KeywordConstant),
          LexerRule.new(/\bfalse\b/, TokenType::KeywordConstant),
          LexerRule.new(/\bnull\b/, TokenType::KeywordConstant),
          
          # Punctuation
          LexerRule.new(/[{}]/, TokenType::Punctuation),
          LexerRule.new(/[\[\]]/, TokenType::Punctuation),
          LexerRule.new(/:/, TokenType::Punctuation),
          LexerRule.new(/,/, TokenType::Punctuation),
          
          # Error for anything else
          LexerRule.new(/./, TokenType::Error),
        ],
        
        "string" => [
          LexerRule.new(/\"/, RuleActions.pop(TokenType::LiteralStringDouble)),
          LexerRule.new(/\\["\\\/bfnrt]/, TokenType::LiteralStringEscape),
          LexerRule.new(/\\u[0-9a-fA-F]{4}/, TokenType::LiteralStringEscape),
          LexerRule.new(/\\./, TokenType::Error), # Invalid escape
          LexerRule.new(/[^\"\\]+/, TokenType::LiteralStringDouble),
        ],
      }
    end

  end
end