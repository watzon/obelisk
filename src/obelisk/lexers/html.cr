require "../lexer"

module Obelisk::Lexers
  # HTML language lexer with support for embedded CSS and JavaScript
  class HTML < DelegatingLexer
    @html_lexer : HTMLBase

    def initialize
      super()
      @html_lexer = HTMLBase.new

      # Add region detectors for embedded languages
      add_region_detector(StyleTagDetector.new)
      add_region_detector(ScriptTagDetector.new)
    end

    def config : LexerConfig
      @html_lexer.config
    end

    def base_lexer : RegexLexer
      @html_lexer
    end

    def analyze(text : String) : Float32
      @html_lexer.analyze(text)
    end
  end

  # Base HTML lexer (without embedded language support)
  class HTMLBase < RegexLexer
    def config : LexerConfig
      LexerConfig.new(
        name: "html",
        aliases: ["html", "htm", "xhtml"],
        filenames: ["*.html", "*.htm", "*.xhtml"],
        mime_types: ["text/html", "application/xhtml+xml"],
        priority: 1.0f32
      )
    end

    def analyze(text : String) : Float32
      score = 0.0f32
      lines = text.lines.first(50) # Analyze first 50 lines

      # HTML-specific patterns
      lines.each do |line|
        # Strong indicators
        score += 0.3 if line =~ /<!DOCTYPE\s+html/i
        score += 0.2 if line =~ /<html[^>]*>/i
        score += 0.2 if line =~ /<head[^>]*>/i
        score += 0.2 if line =~ /<body[^>]*>/i
        score += 0.15 if line =~ /<meta[^>]*>/i
        score += 0.15 if line =~ /<title[^>]*>/i
        score += 0.1 if line =~ /<(div|span|p|a|img|h[1-6]|ul|ol|li|table|tr|td|th)[^>]*>/i

        # HTML entities
        score += 0.05 if line =~ /&[a-zA-Z]+;/
        score += 0.05 if line =~ /&#\d+;/
        score += 0.05 if line =~ /&#x[0-9a-fA-F]+;/

        # Comments
        score += 0.05 if line =~ /<!--.*-->/

        # Attributes
        score += 0.05 if line =~ /\s(class|id|style|href|src|alt|title)="/
      end

      # Negative indicators (not HTML)
      score -= 0.2 if text =~ /^\s*\{/       # JSON/CSS
      score -= 0.2 if text =~ /^\s*function/ # JavaScript
      score -= 0.2 if text =~ /^\s*def\s+/   # Python/Ruby

      # Cap the score at 1.0
      [score, 1.0f32].min
    end

    def rules : Hash(String, Array(LexerRule))
      {
        "root" => [
          # Whitespace
          LexerRule.new(/\s+/, TokenType::Text),

          # Doctype
          LexerRule.new(/<!DOCTYPE[^>]+>/, TokenType::CommentPreproc),

          # Comments
          LexerRule.new(/<!--/, RuleActions.push("comment", TokenType::CommentMultiline)),

          # CDATA sections
          LexerRule.new(/<!\[CDATA\[/, RuleActions.push("cdata", TokenType::CommentPreproc)),

          # Processing instructions
          LexerRule.new(/<\?.*?\?>/, TokenType::CommentPreproc),

          # Tags
          LexerRule.new(/<\/([a-zA-Z][a-zA-Z0-9:\-]*)(\s*)(>)/,
            RuleActions.by_groups(TokenType::NameTag, TokenType::Text, TokenType::Punctuation)),

          # Opening tags
          LexerRule.new(/<([a-zA-Z][a-zA-Z0-9:\-]*)/, ->(match : String, state : LexerState, groups : Array(String)) {
            tag_name = groups[0].downcase
            state.set_context("current_tag", tag_name)
            state.push_state("tag")
            [Token.new(TokenType::NameTag, match)]
          }),

          # HTML entities
          LexerRule.new(/&[a-zA-Z]+;/, TokenType::NameEntity),
          LexerRule.new(/&#\d+;/, TokenType::NameEntity),
          LexerRule.new(/&#x[0-9a-fA-F]+;/, TokenType::NameEntity),

          # Text content
          LexerRule.new(/[^<&]+/, TokenType::Text),
          LexerRule.new(/[<&]/, TokenType::Text),
        ],

        "comment" => [
          LexerRule.new(/-->/, RuleActions.pop(TokenType::CommentMultiline)),
          LexerRule.new(/[^-]+/, TokenType::CommentMultiline),
          LexerRule.new(/-+(?!->)/, TokenType::CommentMultiline),
          LexerRule.new(/-/, TokenType::CommentMultiline),
        ],

        "cdata" => [
          LexerRule.new(/\]\]>/, RuleActions.pop(TokenType::CommentPreproc)),
          LexerRule.new(/[^\]]+/, TokenType::Text),
          LexerRule.new(/\]/, TokenType::Text),
        ],

        "tag" => [
          # Whitespace
          LexerRule.new(/\s+/, TokenType::Text),

          # End of tag
          LexerRule.new(/>/, ->(match : String, state : LexerState, groups : Array(String)) {
            state.clear_context
            state.pop_state
            [Token.new(TokenType::Punctuation, match)]
          }),

          # Self-closing tag
          LexerRule.new(/\/>/, ->(match : String, state : LexerState, groups : Array(String)) {
            state.clear_context
            state.pop_state
            [Token.new(TokenType::Punctuation, match)]
          }),

          # Attribute names
          LexerRule.new(/([a-zA-Z][a-zA-Z0-9:\-]*)(\s*)(=)/,
            RuleActions.by_groups(TokenType::NameAttribute, TokenType::Text, TokenType::Operator)),

          # Attribute without value
          LexerRule.new(/[a-zA-Z][a-zA-Z0-9:\-]*/, TokenType::NameAttribute),

          # Attribute values
          LexerRule.new(/"/, RuleActions.push("attr_double", TokenType::LiteralStringDouble)),
          LexerRule.new(/'/, RuleActions.push("attr_single", TokenType::LiteralStringSingle)),

          # Unquoted attribute values
          LexerRule.new(/[^\s>]+/, TokenType::LiteralString),
        ],

        "attr_double" => [
          LexerRule.new(/"/, RuleActions.pop(TokenType::LiteralStringDouble)),

          # HTML entities in attributes
          LexerRule.new(/&[a-zA-Z]+;/, TokenType::NameEntity),
          LexerRule.new(/&#\d+;/, TokenType::NameEntity),
          LexerRule.new(/&#x[0-9a-fA-F]+;/, TokenType::NameEntity),

          LexerRule.new(/[^"&]+/, TokenType::LiteralStringDouble),
          LexerRule.new(/[&]/, TokenType::LiteralStringDouble),
        ],

        "attr_single" => [
          LexerRule.new(/'/, RuleActions.pop(TokenType::LiteralStringSingle)),

          # HTML entities in attributes
          LexerRule.new(/&[a-zA-Z]+;/, TokenType::NameEntity),
          LexerRule.new(/&#\d+;/, TokenType::NameEntity),
          LexerRule.new(/&#x[0-9a-fA-F]+;/, TokenType::NameEntity),

          LexerRule.new(/[^'&]+/, TokenType::LiteralStringSingle),
          LexerRule.new(/[&]/, TokenType::LiteralStringSingle),
        ],
      }
    end
  end

  # Detector for <style> tags with embedded CSS
  class StyleTagDetector < RegionDetector
    def detect_regions(text : String, state : LexerState) : Array(EmbeddedRegion)
      regions = [] of EmbeddedRegion
      pos = 0

      # Find all <style> tags
      style_regex = /<style[^>]*>/i
      end_regex = /<\/style\s*>/i

      while pos < text.size
        if match = style_regex.match(text, pos)
          start_tag_begin = match.begin(0)
          start_tag_end = match.end(0)

          # Find the closing tag
          if end_match = end_regex.match(text, start_tag_end)
            end_tag_begin = end_match.begin(0)
            end_tag_end = end_match.end(0)

            # Create tokens for the tags
            start_token = Token.new(TokenType::NameTag, match[0])
            end_token = Token.new(TokenType::NameTag, end_match[0])

            # Get or create CSS lexer
            css_lexer = CSS.new

            # Create region for CSS content
            regions << EmbeddedRegion.new(
              start_tag_end,
              end_tag_begin,
              css_lexer,
              start_token,
              end_token
            )

            pos = end_tag_end
          else
            # No closing tag found
            break
          end
        else
          # No more style tags
          break
        end
      end

      regions
    end
  end

  # Detector for <script> tags with embedded JavaScript
  class ScriptTagDetector < RegionDetector
    def detect_regions(text : String, state : LexerState) : Array(EmbeddedRegion)
      regions = [] of EmbeddedRegion
      pos = 0

      # Find all <script> tags
      script_regex = /<script[^>]*>/i
      end_regex = /<\/script\s*>/i

      while pos < text.size
        if match = script_regex.match(text, pos)
          start_tag_begin = match.begin(0)
          start_tag_end = match.end(0)

          # Check if it's an external script (has src attribute)
          if match[0] =~ /\ssrc\s*=/
            # External script, skip to closing tag
            if end_match = end_regex.match(text, start_tag_end)
              pos = end_match.end(0)
            else
              break
            end
            next
          end

          # Find the closing tag
          if end_match = end_regex.match(text, start_tag_end)
            end_tag_begin = end_match.begin(0)
            end_tag_end = end_match.end(0)

            # Create tokens for the tags
            start_token = Token.new(TokenType::NameTag, match[0])
            end_token = Token.new(TokenType::NameTag, end_match[0])

            # Get or create JavaScript lexer
            js_lexer = JavaScript.new

            # Create region for JavaScript content
            regions << EmbeddedRegion.new(
              start_tag_end,
              end_tag_begin,
              js_lexer,
              start_token,
              end_token
            )

            pos = end_tag_end
          else
            # No closing tag found
            break
          end
        else
          # No more script tags
          break
        end
      end

      regions
    end
  end
end
