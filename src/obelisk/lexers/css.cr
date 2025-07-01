require "../lexer"

module Obelisk::Lexers
  # CSS language lexer
  class CSS < RegexLexer
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
        score += 0.2 if line =~ /^\s*\.[a-zA-Z][\w-]*\s*\{/  # Class selector
        score += 0.2 if line =~ /^\s*#[a-zA-Z][\w-]*\s*\{/   # ID selector
        score += 0.2 if line =~ /^\s*[a-zA-Z]+\s*\{/         # Element selector
        score += 0.15 if line =~ /^\s*@(media|import|keyframes|font-face|charset|namespace|supports|page)\b/
        score += 0.1 if line =~ /:\s*[^;]+;/                 # Property: value;
        score += 0.1 if line =~ /\{[^}]*\}/                  # Inline rules
        
        # CSS-specific properties
        score += 0.05 if line =~ /\b(color|background|margin|padding|border|font|display|position|width|height):/
        score += 0.05 if line =~ /\b(px|em|rem|%|vh|vw|pt|cm|mm|in|pc|ex|ch|vmin|vmax)\b/
        score += 0.05 if line =~ /#[0-9a-fA-F]{3,6}\b/       # Hex colors
        score += 0.05 if line =~ /\brgba?\(/                 # RGB/RGBA colors
        score += 0.05 if line =~ /\bhsla?\(/                 # HSL/HSLA colors
        
        # Pseudo-classes and pseudo-elements
        score += 0.05 if line =~ /:(hover|active|focus|visited|first-child|last-child|nth-child|before|after|not)/
        score += 0.05 if line =~ /::(before|after|first-letter|first-line|selection|backdrop)/
      end
      
      # Negative indicators (not CSS)
      score -= 0.2 if text =~ /\bfunction\s+\w+/    # JavaScript
      score -= 0.2 if text =~ /<\w+>/               # HTML tags
      score -= 0.2 if text =~ /\bdef\s+\w+/         # Python/Ruby
      
      # Cap the score at 1.0
      [score, 1.0f32].min
    end

    def rules : Hash(String, Array(LexerRule))
      {
        "root" => [
          # Whitespace
          LexerRule.new(/\s+/, TokenType::Text),
          
          # Comments
          LexerRule.new(/\/\*/, RuleActions.push("comment", TokenType::CommentMultiline)),
          
          # @rules
          LexerRule.new(/@(charset|namespace)\s+/, RuleActions.push("string_or_url", TokenType::KeywordNamespace)),
          LexerRule.new(/@(import|font-face|page|media|keyframes|supports|document|viewport|font-feature-values|counter-style|namespace|layer|container|scope|starting-style)\b/, TokenType::KeywordNamespace),
          
          # Selectors
          # ID selector
          LexerRule.new(/#[a-zA-Z][\w-]*/, TokenType::NameTag),
          
          # Class selector
          LexerRule.new(/\.[a-zA-Z][\w-]*/, TokenType::NameClass),
          
          # Attribute selectors
          LexerRule.new(/\[/, RuleActions.push("attribute_selector", TokenType::Punctuation)),
          
          # Pseudo-classes and pseudo-elements
          LexerRule.new(/::?[a-zA-Z-]+(?:\([^)]*\))?/, TokenType::KeywordPseudo),
          
          # Element selectors (tags)
          LexerRule.new(/[a-zA-Z][\w-]*(?=\s*[,{])/, TokenType::NameTag),
          LexerRule.new(/[a-zA-Z][\w-]*/, TokenType::NameTag),
          
          # Universal selector
          LexerRule.new(/\*/, TokenType::NameTag),
          
          # Combinators
          LexerRule.new(/[>+~]/, TokenType::Operator),
          
          # Start of rule block
          LexerRule.new(/\{/, RuleActions.push("rule_block", TokenType::Punctuation)),
          
          # Semicolon outside of rule block (for @import, etc.)
          LexerRule.new(/;/, TokenType::Punctuation),
          
          # Comma (selector separator)
          LexerRule.new(/,/, TokenType::Punctuation),
        ],
        
        "comment" => [
          LexerRule.new(/\*\//, RuleActions.pop(TokenType::CommentMultiline)),
          LexerRule.new(/[^*]+/, TokenType::CommentMultiline),
          LexerRule.new(/\*+(?!\/)/, TokenType::CommentMultiline),
          LexerRule.new(/\*/, TokenType::CommentMultiline),
        ],
        
        "rule_block" => [
          # Whitespace
          LexerRule.new(/\s+/, TokenType::Text),
          
          # Comments
          LexerRule.new(/\/\*/, RuleActions.push("comment", TokenType::CommentMultiline)),
          
          # End of rule block
          LexerRule.new(/\}/, RuleActions.pop(TokenType::Punctuation)),
          
          # Nested rule blocks (for @media, etc.)
          LexerRule.new(/\{/, RuleActions.push("rule_block", TokenType::Punctuation)),
          
          # Property names
          LexerRule.new(/([a-zA-Z-]+)(\s*)(:)/, RuleActions.by_groups(TokenType::NameProperty, TokenType::Text, TokenType::Punctuation)),
          
          # Property values
          # Important flag
          LexerRule.new(/!\s*important/, TokenType::KeywordReserved),
          
          # URLs
          LexerRule.new(/url\(/, RuleActions.push("url", TokenType::NameFunction)),
          
          # Functions
          LexerRule.new(/[a-zA-Z-]+(?=\()/, TokenType::NameFunction),
          
          # Numbers with units
          LexerRule.new(/-?\d+\.?\d*(?:px|em|rem|%|vh|vw|pt|cm|mm|in|pc|ex|ch|vmin|vmax|fr|deg|rad|grad|turn|s|ms|Hz|kHz|dpi|dpcm|dppx)?\b/, TokenType::LiteralNumber),
          
          # Colors
          LexerRule.new(/#[0-9a-fA-F]{3}(?:[0-9a-fA-F]{3})?(?:[0-9a-fA-F]{2})?\b/, TokenType::LiteralNumberHex),
          LexerRule.new(/\b(?:rgb|rgba|hsl|hsla|hwb|lab|lch|oklab|oklch|color)\(/, RuleActions.push("function", TokenType::NameFunction)),
          
          # Color keywords
          LexerRule.new(/\b(?:transparent|currentcolor|aliceblue|antiquewhite|aqua|aquamarine|azure|beige|bisque|black|blanchedalmond|blue|blueviolet|brown|burlywood|cadetblue|chartreuse|chocolate|coral|cornflowerblue|cornsilk|crimson|cyan|darkblue|darkcyan|darkgoldenrod|darkgray|darkgreen|darkgrey|darkkhaki|darkmagenta|darkolivegreen|darkorange|darkorchid|darkred|darksalmon|darkseagreen|darkslateblue|darkslategray|darkslategrey|darkturquoise|darkviolet|deeppink|deepskyblue|dimgray|dimgrey|dodgerblue|firebrick|floralwhite|forestgreen|fuchsia|gainsboro|ghostwhite|gold|goldenrod|gray|green|greenyellow|grey|honeydew|hotpink|indianred|indigo|ivory|khaki|lavender|lavenderblush|lawngreen|lemonchiffon|lightblue|lightcoral|lightcyan|lightgoldenrodyellow|lightgray|lightgreen|lightgrey|lightpink|lightsalmon|lightseagreen|lightskyblue|lightslategray|lightslategrey|lightsteelblue|lightyellow|lime|limegreen|linen|magenta|maroon|mediumaquamarine|mediumblue|mediumorchid|mediumpurple|mediumseagreen|mediumslateblue|mediumspringgreen|mediumturquoise|mediumvioletred|midnightblue|mintcream|mistyrose|moccasin|navajowhite|navy|oldlace|olive|olivedrab|orange|orangered|orchid|palegoldenrod|palegreen|paleturquoise|palevioletred|papayawhip|peachpuff|peru|pink|plum|powderblue|purple|rebeccapurple|red|rosybrown|royalblue|saddlebrown|salmon|sandybrown|seagreen|seashell|sienna|silver|skyblue|slateblue|slategray|slategrey|snow|springgreen|steelblue|tan|teal|thistle|tomato|turquoise|violet|wheat|white|whitesmoke|yellow|yellowgreen)\b/, TokenType::NameBuiltin),
          
          # Strings
          LexerRule.new(/"/, RuleActions.push("string_double", TokenType::LiteralStringDouble)),
          LexerRule.new(/'/, RuleActions.push("string_single", TokenType::LiteralStringSingle)),
          
          # Keywords
          LexerRule.new(/\b(?:inherit|initial|unset|revert|revert-layer|auto|none|normal|hidden|visible|scroll|solid|dotted|dashed|double|groove|ridge|inset|outset|block|inline|inline-block|flex|grid|table|table-row|table-cell|absolute|relative|fixed|sticky|static|bold|italic|underline|line-through|nowrap|pre|pre-wrap|pre-line|break-all|break-word|uppercase|lowercase|capitalize|left|right|center|justify|top|bottom|middle|baseline|pointer|default|crosshair|move|text|wait|help|not-allowed|all|ease|ease-in|ease-out|ease-in-out|linear|step-start|step-end|start|end|both|forwards|backwards|infinite|alternate|reverse|running|paused|flat|preserve-3d)\b/, TokenType::KeywordConstant),
          
          # Operators
          LexerRule.new(/[+\-*\/]/, TokenType::Operator),
          
          # Punctuation
          LexerRule.new(/[;,()]/, TokenType::Punctuation),
          
          # Generic identifiers
          LexerRule.new(/[a-zA-Z-]+/, TokenType::Name),
        ],
        
        "string_or_url" => [
          # URL
          LexerRule.new(/url\(/, RuleActions.push("url", TokenType::NameFunction)),
          
          # Strings
          LexerRule.new(/"/, RuleActions.push("string_double", TokenType::LiteralStringDouble)),
          LexerRule.new(/'/, RuleActions.push("string_single", TokenType::LiteralStringSingle)),
          
          # Semicolon ends the statement
          LexerRule.new(/;/, RuleActions.pop(TokenType::Punctuation)),
          
          # Whitespace
          LexerRule.new(/\s+/, TokenType::Text),
        ],
        
        "url" => [
          LexerRule.new(/\)/, RuleActions.pop(TokenType::NameFunction)),
          LexerRule.new(/"/, RuleActions.push("string_double_url", TokenType::LiteralStringDouble)),
          LexerRule.new(/'/, RuleActions.push("string_single_url", TokenType::LiteralStringSingle)),
          LexerRule.new(/[^)'"\s]+/, TokenType::LiteralString),
          LexerRule.new(/\s+/, TokenType::Text),
        ],
        
        "function" => [
          LexerRule.new(/\)/, RuleActions.pop(TokenType::NameFunction)),
          LexerRule.new(/,/, TokenType::Punctuation),
          LexerRule.new(/\s+/, TokenType::Text),
          
          # Numbers
          LexerRule.new(/-?\d+\.?\d*%?/, TokenType::LiteralNumber),
          
          # Keywords in functions
          LexerRule.new(/\b(?:from|to|at)\b/, TokenType::Keyword),
          
          # Nested functions
          LexerRule.new(/[a-zA-Z-]+(?=\()/, TokenType::NameFunction),
          LexerRule.new(/\(/, RuleActions.push("function", TokenType::Punctuation)),
          
          # Generic identifiers
          LexerRule.new(/[a-zA-Z-]+/, TokenType::Name),
        ],
        
        "attribute_selector" => [
          LexerRule.new(/\]/, RuleActions.pop(TokenType::Punctuation)),
          LexerRule.new(/\s+/, TokenType::Text),
          
          # Attribute name
          LexerRule.new(/[a-zA-Z][\w-]*/, TokenType::NameAttribute),
          
          # Operators
          LexerRule.new(/[~|^$*]?=/, TokenType::Operator),
          
          # Strings
          LexerRule.new(/"/, RuleActions.push("string_double_attr", TokenType::LiteralStringDouble)),
          LexerRule.new(/'/, RuleActions.push("string_single_attr", TokenType::LiteralStringSingle)),
          
          # Flags
          LexerRule.new(/\s*[iIsS]\b/, TokenType::NameBuiltin),
        ],
        
        "string_double" => [
          LexerRule.new(/"/, RuleActions.pop(TokenType::LiteralStringDouble)),
          LexerRule.new(/\\[\\"]/, TokenType::LiteralStringEscape),
          LexerRule.new(/\\./, TokenType::LiteralStringEscape),
          LexerRule.new(/[^"\\]+/, TokenType::LiteralStringDouble),
        ],
        
        "string_single" => [
          LexerRule.new(/'/, RuleActions.pop(TokenType::LiteralStringSingle)),
          LexerRule.new(/\\[\\']/, TokenType::LiteralStringEscape),
          LexerRule.new(/\\./, TokenType::LiteralStringEscape),
          LexerRule.new(/[^'\\]+/, TokenType::LiteralStringSingle),
        ],
        
        "string_double_url" => [
          LexerRule.new(/"/, RuleActions.pop(TokenType::LiteralStringDouble)),
          LexerRule.new(/\\[\\"]/, TokenType::LiteralStringEscape),
          LexerRule.new(/\\./, TokenType::LiteralStringEscape),
          LexerRule.new(/[^"\\]+/, TokenType::LiteralStringDouble),
        ],
        
        "string_single_url" => [
          LexerRule.new(/'/, RuleActions.pop(TokenType::LiteralStringSingle)),
          LexerRule.new(/\\[\\']/, TokenType::LiteralStringEscape),
          LexerRule.new(/\\./, TokenType::LiteralStringEscape),
          LexerRule.new(/[^'\\]+/, TokenType::LiteralStringSingle),
        ],
        
        "string_double_attr" => [
          LexerRule.new(/"/, RuleActions.pop(TokenType::LiteralStringDouble)),
          LexerRule.new(/\\[\\"]/, TokenType::LiteralStringEscape),
          LexerRule.new(/\\./, TokenType::LiteralStringEscape),
          LexerRule.new(/[^"\\]+/, TokenType::LiteralStringDouble),
        ],
        
        "string_single_attr" => [
          LexerRule.new(/'/, RuleActions.pop(TokenType::LiteralStringSingle)),
          LexerRule.new(/\\[\\']/, TokenType::LiteralStringEscape),
          LexerRule.new(/\\./, TokenType::LiteralStringEscape),
          LexerRule.new(/[^'\\]+/, TokenType::LiteralStringSingle),
        ],
      }
    end
  end
end