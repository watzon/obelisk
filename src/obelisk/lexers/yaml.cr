require "../lexer"

module Obelisk::Lexers
  # YAML lexer
  # Optimized with regex constants
  class YAML < RegexLexer
    # ==========================================================================
    # Regex Pattern Constants
    # ==========================================================================

    # Document markers
    DOC_START = /^---/
    DOC_END = /^\.\.\./

    # Whitespace and comments
    WHITESPACE = /\s+/
    COMMENT = /#.*$/

    # String delimiters
    DOUBLE_QUOTE = /"/
    SINGLE_QUOTE = /'/

    # Escape sequences
    ESCAPE_SIMPLE = /\\[\"\\\/bfnrt]/
    ESCAPE_UNICODE = /\\u[0-9a-fA-F]{4}/
    ESCAPE_UNICODE_LONG = /\\U[0-9a-fA-F]{8}/
    ESCAPE_HEX = /\\x[0-9a-fA-F]{2}/
    ESCAPE_ANY = /\\./

    # String content patterns
    STRING_DOUBLE_CONTENT = /[^\"\\]+/
    STRING_SINGLE_CONTENT = /[^\']+/
    ESCAPED_SINGLE_QUOTE = /\'\'/

    # Multi-line indicators
    MULTILINE_INDICATOR = /[|>][-+]?/

    # Keys (before colon)
    KEY_WITH_COLON = /^(\s*)([^#\s][^:]*?)(\s*)(:)(\s|$)/

    # Array indicators
    ARRAY_INDICATOR = /^(\s*)(-)(\s)/

    # Boolean values
    BOOLEAN = /\b(?:true|false|yes|no|on|off)\b/i

    # Null values
    NULL = /\b(?:null|~)\b/i

    # Numbers
    NUMBER = /-?(?:0|[1-9]\d*)(?:\.\d+)?(?:[eE][+-]?\d+)?/
    NUMBER_HEX = /0x[0-9a-fA-F]+/
    NUMBER_OCT = /0o[0-7]+/

    # Timestamps
    TIMESTAMP = /\d{4}-\d{2}-\d{2}(?:[Tt]\d{2}:\d{2}:\d{2}(?:\.\d+)?(?:[Zz]|[+-]\d{2}:\d{2})?)?/

    # Tags
    TAG_SIMPLE = /![a-zA-Z_][a-zA-Z0-9_]*/
    TAG_URI = /!<[^>]*>/

    # Anchors and aliases
    ANCHOR =/&[a-zA-Z_][a-zA-Z0-9_]*/
    ALIAS = /\*[a-zA-Z_][a-zA-Z0-9_]*/

    # Punctuation
    BRACES = /[\[\]{}]/
    COMMA = /,/

    # Plain scalars (unquoted strings)
    PLAIN_SCALAR = /[^\s#,\[\]{}]+/

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
      if text =~ /^\s*\{.*\}\s*$/m # Single line JSON
        score = [score - 0.5, 0.0f32].max
      end
      if text =~ /^\s*<\?xml/ # XML
        score = [score - 0.5, 0.0f32].max
      end
      if text.strip.starts_with?('<') && text.strip.ends_with?('>') # HTML/XML
        score = [score - 0.3, 0.0f32].max
      end

      # Cap the score
      [[score, 0.0f32].max, 1.0f32].min
    end

    # Helper to get string escape rules
    private def string_escape_rules(token_type : TokenType) : Array(LexerRule)
      [
        LexerRule.new(ESCAPE_SIMPLE, token_type),
        LexerRule.new(ESCAPE_UNICODE, token_type),
        LexerRule.new(ESCAPE_UNICODE_LONG, token_type),
        LexerRule.new(ESCAPE_HEX, token_type),
        LexerRule.new(ESCAPE_ANY, token_type),
      ]
    end

    def rules : Hash(String, Array(LexerRule))
      {
        "root" => [
          # YAML document markers
          LexerRule.new(DOC_START, TokenType::NameTag),
          LexerRule.new(DOC_END, TokenType::NameTag),

          # Comments
          LexerRule.new(COMMENT, TokenType::CommentSingle),

          # Strings with quotes
          LexerRule.new(DOUBLE_QUOTE, RuleActions.push("string_double", TokenType::LiteralStringDouble)),
          LexerRule.new(SINGLE_QUOTE, RuleActions.push("string_single", TokenType::LiteralStringSingle)),

          # Multi-line strings
          LexerRule.new(MULTILINE_INDICATOR, TokenType::Punctuation),

          # Keys (before colon)
          LexerRule.new(KEY_WITH_COLON, RuleActions.by_groups(
            TokenType::Text,
            TokenType::NameAttribute,
            TokenType::Text,
            TokenType::Punctuation,
            TokenType::Text
          )),

          # Array indicators
          LexerRule.new(ARRAY_INDICATOR, RuleActions.by_groups(
            TokenType::Text,
            TokenType::Punctuation,
            TokenType::Text
          )),

          # Boolean values
          LexerRule.new(BOOLEAN, TokenType::KeywordConstant),

          # Null values
          LexerRule.new(NULL, TokenType::KeywordConstant),

          # Numbers
          LexerRule.new(NUMBER, TokenType::LiteralNumber),
          LexerRule.new(NUMBER_HEX, TokenType::LiteralNumberHex),
          LexerRule.new(NUMBER_OCT, TokenType::LiteralNumberOct),

          # Timestamps
          LexerRule.new(TIMESTAMP, TokenType::LiteralDate),

          # Tags
          LexerRule.new(TAG_SIMPLE, TokenType::NameTag),
          LexerRule.new(TAG_URI, TokenType::NameTag),

          # Anchors and aliases
          LexerRule.new(ANCHOR, TokenType::NameLabel),
          LexerRule.new(ALIAS, TokenType::NameVariable),

          # Special characters
          LexerRule.new(BRACES, TokenType::Punctuation),
          LexerRule.new(COMMA, TokenType::Punctuation),

          # Plain scalars (unquoted strings)
          LexerRule.new(PLAIN_SCALAR, TokenType::LiteralString),

          # Whitespace
          LexerRule.new(WHITESPACE, TokenType::Text),
        ],

        "string_double" => [
          LexerRule.new(DOUBLE_QUOTE, RuleActions.pop(TokenType::LiteralStringDouble)),
          *string_escape_rules(TokenType::LiteralStringEscape),
          LexerRule.new(STRING_DOUBLE_CONTENT, TokenType::LiteralStringDouble),
        ],

        "string_single" => [
          LexerRule.new(SINGLE_QUOTE, RuleActions.pop(TokenType::LiteralStringSingle)),
          LexerRule.new(ESCAPED_SINGLE_QUOTE, TokenType::LiteralStringEscape),
          LexerRule.new(STRING_SINGLE_CONTENT, TokenType::LiteralStringSingle),
        ],
      }
    end
  end
end
