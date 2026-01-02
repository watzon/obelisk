require "../lexer"

module Obelisk::Lexers
  # JSON lexer
  # Optimized with regex constants following Chroma-like patterns
  class JSON < RegexLexer
    # ==========================================================================
    # Regex Pattern Constants
    # ==========================================================================

    # Whitespace
    WHITESPACE = /\s+/

    # String delimiters
    DOUBLE_QUOTE = /"/

    # Escape sequences (shared pattern)
    ESCAPE_SIMPLE = /\\["\\\/bfnrt]/
    ESCAPE_UNICODE = /\\u[0-9a-fA-F]{4}/
    ESCAPE_INVALID = /\\./

    # String content (excluding quotes and escapes)
    STRING_CONTENT = /[^"\\]+/

    # Numbers (Chroma pattern: -?(0|[1-9]\d*)(\.\d+)?([eE][+-]?\d+)?)
    NUMBER = /-?(?:0|[1-9]\d*)(?:\.\d+)?(?:[eE][+-]?\d+)?/

    # Constants
    TRUE = /\btrue\b/
    FALSE = /\bfalse\b/
    NULL = /\bnull\b/

    # Punctuation
    BRACES = /[{}]/
    BRACKETS = /[\[\]]/
    COLON = /:/
    COMMA = /,/

    # Error
    ANY_CHAR = /./

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
        if balanced_braces?(trimmed, '{', '}')
          score += 0.4
        else
          score += 0.1
        end
      elsif trimmed.starts_with?('[') && trimmed.ends_with?(']')
        if balanced_braces?(trimmed, '[', ']')
          score += 0.4
        else
          score += 0.1
        end
      end

      # Check for JSON patterns
      lines = text.lines.first(30)
      lines.each do |line|
        score += 0.1 if line =~ /"[^"]+"\s*:\s*/
        score += 0.05 if line =~ /:\s*(true|false|null)\b/
        score += 0.05 if line =~ %r(/:\s*"[^"]*"//)
        score += 0.05 if line =~ /:\s*-?[\d.]+/
        score += 0.05 if line =~ /:\s*\{/
        score += 0.05 if line =~ /:\s*\[/
        score += 0.02 if line =~ /^\s*\{/
        score += 0.02 if line =~ /^\s*\}/
        score += 0.02 if line =~ /^\s*\[/
        score += 0.02 if line =~ /^\s*\]/
        score += 0.02 if line =~ /,\s*$/
      end

      # Negative indicators (not JSON)
      score -= 0.5 if text =~ /^\s*<\?xml/
      score -= 0.5 if text =~ /^\s*<!DOCTYPE/
      score -= 0.8 if text =~ /^---(\s|$)/
      score -= 0.3 if lines.any? { |l| l =~ /^\s*-\s+\w/ }

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
          LexerRule.new(WHITESPACE, TokenType::Text),

          # Strings
          LexerRule.new(DOUBLE_QUOTE, RuleActions.push("string", TokenType::LiteralStringDouble)),

          # Numbers
          LexerRule.new(NUMBER, TokenType::LiteralNumber),

          # Constants
          LexerRule.new(TRUE, TokenType::KeywordConstant),
          LexerRule.new(FALSE, TokenType::KeywordConstant),
          LexerRule.new(NULL, TokenType::KeywordConstant),

          # Punctuation
          LexerRule.new(BRACES, TokenType::Punctuation),
          LexerRule.new(BRACKETS, TokenType::Punctuation),
          LexerRule.new(COLON, TokenType::Punctuation),
          LexerRule.new(COMMA, TokenType::Punctuation),

          # Error for anything else
          LexerRule.new(ANY_CHAR, TokenType::Error),
        ],

        "string" => [
          LexerRule.new(DOUBLE_QUOTE, RuleActions.pop(TokenType::LiteralStringDouble)),
          LexerRule.new(ESCAPE_SIMPLE, TokenType::LiteralStringEscape),
          LexerRule.new(ESCAPE_UNICODE, TokenType::LiteralStringEscape),
          LexerRule.new(ESCAPE_INVALID, TokenType::Error),
          LexerRule.new(STRING_CONTENT, TokenType::LiteralStringDouble),
        ],
      }
    end
  end
end
