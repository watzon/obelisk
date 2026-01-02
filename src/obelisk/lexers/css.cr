require "../lexer"

module Obelisk::Lexers
  # CSS language lexer
  # Optimized for performance using Chroma-like simple patterns
  class CSS < RegexLexer
    # ==========================================================================
    # Regex Pattern Constants
    # ==========================================================================

    # Whitespace and comments
    WHITESPACE = /\s+/
    COMMENT_START = /\/\*/
    COMMENT_END = /\*\//

    # String delimiters
    DOUBLE_QUOTE = /"/
    SINGLE_QUOTE = /'/

    # Escape sequences (shared across string states)
    ESCAPE_SEQUENCE = /\\[\\"]|\\./

    # String content patterns
    STRING_DOUBLE_CONTENT = /[^"\\]+/
    STRING_SINGLE_CONTENT = /[^'\\]+/

    # At-rules
    AT_RULES = /@(charset|namespace|import|font-face|page|media|keyframes|supports|document|viewport|font-feature-values|counter-style|layer|container|scope|starting-style)\b/

    # Selectors
    ID_SELECTOR = /#[a-zA-Z][\w-]*/
    CLASS_SELECTOR = /\.[a-zA-Z][\w-]*/
    PSEUDO_SELECTOR = /::?[a-zA-Z-]+(?:\([^)]*\))?/
    TAG_SELECTOR = /[a-zA-Z][\w-]*/
    UNIVERSAL_SELECTOR = /\*/

    # Combinators
    COMBINATORS = /[>+~]/

    # Punctuation
    PUNCTUATION = /[;,(){}\[\]]/
    COMMA = /,/

    # Property names
    PROPERTY_NAME = /[a-zA-Z-]+/

    # Property values
    IMPORTANT_FLAG = /!\s*important\b/
    URL_FUNCTION = /url\(/

    # Functions
    FUNCTION_NAME = /[a-zA-Z-]+(?=\()/

    # Color functions (matched in root, before generic functions)
    COLOR_FUNCTION_CALL = /\b(rgb|rgba|hsl|hsla|hwb|lab|lch|oklab|oklch|color)\(/

    # Numbers (simplified - unit is handled separately)
    NUMBER = /-?\d+\.?\d*/

    # Units
    UNIT = /(?:px|em|rem|%|vh|vw|pt|cm|mm|in|pc|ex|ch|vmin|vmax|fr|deg|rad|grad|turn|s|ms|Hz|kHz|dpi|dpcm|dppx)?\b/

    # Colors
    HEX_COLOR = /#[0-9a-fA-F]{3}(?:[0-9a-fA-F]{3})?(?:[0-9a-fA-F]{2})?\b/

    # Simplified color keywords (most common ones, not all 150+)
    COLOR_KEYWORDS = /\b(?:transparent|black|white|red|green|blue|yellow|cyan|magenta|gray|grey|orange|purple|pink|brown|beige|gold|indigo|lime|maroon|navy|olive|teal|violet|turquoise|silver)\b/

    # Common CSS keywords
    CSS_KEYWORDS = /\b(?:inherit|initial|unset|auto|none|normal|hidden|visible|scroll|block|inline|flex|grid|absolute|relative|fixed|static|bold|italic|left|right|center|top|bottom)\b/

    # Operators
    OPERATORS = /[+\-*\/~|^$]?=/

    # Attribute operators
    ATTR_OP = /[~|^$*]?=/

    def config : LexerConfig
      LexerConfig.new(
        name: "css",
        aliases: ["css"],
        filenames: ["*.css"],
        mime_types: ["text/css"],
        priority: 1.0f32
      )
    end

    def analyze(text : String) : Float32
      score = 0.0f32
      lines = text.lines.first(50) # Analyze first 50 lines

      # CSS-specific patterns
      lines.each do |line|
        # Strong indicators
        score += 0.2 if line =~ /^\s*\.[a-zA-Z][\w-]*\s*\{/ # Class selector
        score += 0.2 if line =~ /^\s*#[a-zA-Z][\w-]*\s*\{/  # ID selector
        score += 0.2 if line =~ /^\s*[a-zA-Z]+\s*\{/        # Element selector
        score += 0.15 if line =~ /^\s*@(media|import|keyframes|font-face|charset|namespace|supports|page)\b/
        score += 0.1 if line =~ /:\s*[^;]+;/ # Property: value;
        score += 0.1 if line =~ /\{[^}]*\}/  # Inline rules

        # CSS-specific properties
        score += 0.05 if line =~ /\b(color|background|margin|padding|border|font|display|position|width|height):/
        score += 0.05 if line =~ /\b(px|em|rem|%|vh|vw|pt|cm|mm|in|pc|ex|ch|vmin|vmax)\b/
        score += 0.05 if line =~ /#[0-9a-fA-F]{3,6}\b/ # Hex colors
        score += 0.05 if line =~ /\brgba?\(/           # RGB/RGBA colors
        score += 0.05 if line =~ /\bhsla?\(/           # HSL/HSLA colors

        # Pseudo-classes and pseudo-elements
        score += 0.05 if line =~ /:(hover|active|focus|visited|first-child|last-child|nth-child|before|after|not)/
        score += 0.05 if line =~ /::(before|after|first-letter|first-line|selection|backdrop)/
      end

      # Negative indicators (not CSS)
      score -= 0.2 if text =~ /\bfunction\s+\w+/ # JavaScript
      score -= 0.2 if text =~ /<\w+>/            # HTML tags
      score -= 0.2 if text =~ /\bdef\s+\w+/      # Python/Ruby

      # Cap the score at 1.0
      [score, 1.0f32].min
    end

    def rules : Hash(String, Array(LexerRule))
      {
        "root" => [
          # Whitespace
          LexerRule.new(WHITESPACE, TokenType::Text),

          # Comments
          LexerRule.new(COMMENT_START, RuleActions.push("comment", TokenType::CommentMultiline)),

          # @rules
          LexerRule.new(AT_RULES, TokenType::KeywordNamespace),

          # Selectors
          LexerRule.new(ID_SELECTOR, TokenType::NameTag),
          LexerRule.new(CLASS_SELECTOR, TokenType::NameClass),
          LexerRule.new(PSEUDO_SELECTOR, TokenType::KeywordPseudo),
          LexerRule.new(TAG_SELECTOR, TokenType::NameTag),
          LexerRule.new(UNIVERSAL_SELECTOR, TokenType::NameTag),
          LexerRule.new(COMBINATORS, TokenType::Operator),

          # Start of rule block
          LexerRule.new(/\{/, RuleActions.push("rule_block", TokenType::Punctuation)),
          LexerRule.new(/;/, TokenType::Punctuation),
          LexerRule.new(COMMA, TokenType::Punctuation),

          # Attribute selectors
          LexerRule.new(/\[/, RuleActions.push("attribute_selector", TokenType::Punctuation)),
        ],

        "comment" => [
          LexerRule.new(COMMENT_END, RuleActions.pop(TokenType::CommentMultiline)),
          LexerRule.new(/[^*]+/, TokenType::CommentMultiline),
          LexerRule.new(/\*+(?!\/)/, TokenType::CommentMultiline),
          LexerRule.new(/\*/, TokenType::CommentMultiline),
        ],

        "rule_block" => [
          # Whitespace
          LexerRule.new(WHITESPACE, TokenType::Text),

          # Comments
          LexerRule.new(COMMENT_START, RuleActions.push("comment", TokenType::CommentMultiline)),

          # End of rule block
          LexerRule.new(/\}/, RuleActions.pop(TokenType::Punctuation)),

          # Nested rule blocks (for @media, etc.)
          LexerRule.new(/\{/, RuleActions.push("rule_block", TokenType::Punctuation)),

          # Property names
          LexerRule.new(/([a-zA-Z-]+)(\s*)(:)/, RuleActions.by_groups(TokenType::NameProperty, TokenType::Text, TokenType::Punctuation)),

          # Property values (simplified - Chroma approach)
          LexerRule.new(IMPORTANT_FLAG, TokenType::KeywordReserved),
          LexerRule.new(HEX_COLOR, TokenType::LiteralNumberHex),
          LexerRule.new(COLOR_FUNCTION_CALL, RuleActions.push("function", TokenType::NameFunction)),
          LexerRule.new(COLOR_KEYWORDS, TokenType::NameBuiltin),
          LexerRule.new(CSS_KEYWORDS, TokenType::KeywordConstant),
          LexerRule.new(URL_FUNCTION, RuleActions.push("url", TokenType::NameFunction)),
          LexerRule.new(FUNCTION_NAME, TokenType::NameFunction),
          LexerRule.new(/#{NUMBER}#{UNIT}/, TokenType::LiteralNumber),
          LexerRule.new(NUMBER, TokenType::LiteralNumber),

          # Strings
          LexerRule.new(DOUBLE_QUOTE, RuleActions.push("string_double", TokenType::LiteralStringDouble)),
          LexerRule.new(SINGLE_QUOTE, RuleActions.push("string_single", TokenType::LiteralStringSingle)),

          # Operators and punctuation
          LexerRule.new(OPERATORS, TokenType::Operator),
          LexerRule.new(PUNCTUATION, TokenType::Punctuation),

          # Generic identifiers
          LexerRule.new(/[a-zA-Z-]+/, TokenType::Name),
        ],

        "url" => [
          LexerRule.new(/\)/, RuleActions.pop(TokenType::NameFunction)),
          LexerRule.new(DOUBLE_QUOTE, RuleActions.push("string_double", TokenType::LiteralStringDouble)),
          LexerRule.new(SINGLE_QUOTE, RuleActions.push("string_single", TokenType::LiteralStringSingle)),
          LexerRule.new(/[^)'"\s]+/, TokenType::LiteralString),
          LexerRule.new(WHITESPACE, TokenType::Text),
        ],

        "function" => [
          LexerRule.new(/\)/, RuleActions.pop(TokenType::NameFunction)),
          LexerRule.new(/,/, TokenType::Punctuation),
          LexerRule.new(WHITESPACE, TokenType::Text),
          LexerRule.new(/-?\d+\.?\d*%?/, TokenType::LiteralNumber),
          LexerRule.new(/\b(?:from|to|at)\b/, TokenType::Keyword),
          LexerRule.new(/[a-zA-Z-]+(?=\()/, TokenType::NameFunction),
          LexerRule.new(/\(/, RuleActions.push("function", TokenType::Punctuation)),
          LexerRule.new(/[a-zA-Z-]+/, TokenType::Name),
        ],

        # Consolidated string states using shared escape pattern
        "string_double" => [
          LexerRule.new(DOUBLE_QUOTE, RuleActions.pop(TokenType::LiteralStringDouble)),
          LexerRule.new(ESCAPE_SEQUENCE, TokenType::LiteralStringEscape),
          LexerRule.new(STRING_DOUBLE_CONTENT, TokenType::LiteralStringDouble),
        ],

        "string_single" => [
          LexerRule.new(SINGLE_QUOTE, RuleActions.pop(TokenType::LiteralStringSingle)),
          LexerRule.new(ESCAPE_SEQUENCE, TokenType::LiteralStringEscape),
          LexerRule.new(STRING_SINGLE_CONTENT, TokenType::LiteralStringSingle),
        ],

        "attribute_selector" => [
          LexerRule.new(/\]/, RuleActions.pop(TokenType::Punctuation)),
          LexerRule.new(WHITESPACE, TokenType::Text),
          LexerRule.new(/[a-zA-Z][\w-]*/, TokenType::NameAttribute),
          LexerRule.new(ATTR_OP, TokenType::Operator),
          LexerRule.new(DOUBLE_QUOTE, RuleActions.push("string_double", TokenType::LiteralStringDouble)),
          LexerRule.new(SINGLE_QUOTE, RuleActions.push("string_single", TokenType::LiteralStringSingle)),
          LexerRule.new(/\s*[iIsS]\b/, TokenType::NameBuiltin),
        ],
      }
    end
  end
end
