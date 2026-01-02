require "../lexer"

module Obelisk::Lexers
  # ==========================================================================
  # HTML Lexer Pattern Constants
  # All patterns are defined as constants to avoid recompilation and enable reuse
  # ==========================================================================
  module HTMLPatterns
    # Common patterns
    WHITESPACE = /\s+/
    DOCTYPE = /<!DOCTYPE[^>]+>/
    COMMENT_START = /<!--/
    COMMENT_END = /-->/
    CDATA_START = /<!\[CDATA\[/
    CDATA_END = /\]\]>/
    PROCESSING_INSTRUCTION = /<\?.*?\?>/

    # Tags
    TAG_CLOSE = /<\/([a-zA-Z][a-zA-Z0-9:\-]*)(\s*)(>)/
    TAG_OPEN = /<([a-zA-Z][a-zA-Z0-9:\-]*)/
    TAG_END = />/
    TAG_SELF_CLOSE = /\/>/

    # HTML entities (used across multiple states)
    ENTITY_NAMED = /[a-zA-Z]+;/
    ENTITY_DECIMAL = /#\d+;/
    ENTITY_HEXADECIMAL = /#x[0-9a-fA-F]+;/
    ENTITY_PREFIX = /&/

    # Attribute patterns
    ATTR_NAME = /[a-zA-Z][a-zA-Z0-9:\-]*/
    ATTR_NAME_WITH_VALUE = /([a-zA-Z][a-zA-Z0-9:\-]*)(\s*)(=)/
    ATTR_UNQUOTED_VALUE = /[^\s>]+/
    ATTR_DOUBLE_QUOTE = /"/
    ATTR_SINGLE_QUOTE = /'/

    # Content patterns
    TEXT_CONTENT = /[^<&]+/
    TEXT_SPECIAL = /[<&]/
    COMMENT_CONTENT = /[^-]+/
    COMMENT_HYPHENS = /-+(?!->)/
    COMMENT_HYPHEN = /-/
    CDATA_CONTENT = /[^\]]+/
    CDATA_BRACKET = /\]/

    # Attribute value content
    ATTR_DOUBLE_CONTENT = /[^"&]+/
    ATTR_DOUBLE_AMP = /[&]/
    ATTR_SINGLE_CONTENT = /[^'&]+/
    ATTR_SINGLE_AMP = /[&]/

    # Analysis patterns
    DOCTYPE_ANALYSIS = /<!DOCTYPE\s+html/i
    HTML_TAG_OPEN = /<html[^>]*>/i
    HEAD_TAG = /<head[^>]*>/i
    BODY_TAG = /<body[^>]*>/i
    META_TAG = /<meta[^>]*>/i
    TITLE_TAG = /<title[^>]*>/i
    COMMON_TAGS = /<(div|span|p|a|img|h[1-6]|ul|ol|li|table|tr|td|th)[^>]*>/i

    # Region detector patterns
    STYLE_TAG_START = /<style[^>]*>/i
    STYLE_TAG_END = /<\/style\s*>/i
    SCRIPT_TAG_START = /<script[^>]*>/i
    SCRIPT_TAG_END = /<\/script\s*>/i
    SCRIPT_SRC_ATTR = /\ssrc\s*=/
  end

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
    include HTMLPatterns

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
        score += 0.3 if line =~ DOCTYPE_ANALYSIS
        score += 0.2 if line =~ HTML_TAG_OPEN
        score += 0.2 if line =~ HEAD_TAG
        score += 0.2 if line =~ BODY_TAG
        score += 0.15 if line =~ META_TAG
        score += 0.15 if line =~ TITLE_TAG
        score += 0.1 if line =~ COMMON_TAGS

        # HTML entities
        score += 0.05 if line =~ /&#{ENTITY_NAMED.source}/
        score += 0.05 if line =~ /&#{ENTITY_DECIMAL.source}/
        score += 0.05 if line =~ /&#{ENTITY_HEXADECIMAL.source}/

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

    # Helper to generate HTML entity rules (shared across states)
    private def html_entity_rules : Array(LexerRule)
      [
        LexerRule.new(/&#{ENTITY_NAMED.source}/, TokenType::NameEntity),
        LexerRule.new(/&#{ENTITY_DECIMAL.source}/, TokenType::NameEntity),
        LexerRule.new(/&#{ENTITY_HEXADECIMAL.source}/, TokenType::NameEntity),
      ]
    end

    def rules : Hash(String, Array(LexerRule))
      {
        "root" => [
          # Whitespace
          LexerRule.new(WHITESPACE, TokenType::Text),

          # Doctype
          LexerRule.new(DOCTYPE, TokenType::CommentPreproc),

          # Comments
          LexerRule.new(COMMENT_START, RuleActions.push("comment", TokenType::CommentMultiline)),

          # CDATA sections
          LexerRule.new(CDATA_START, RuleActions.push("cdata", TokenType::CommentPreproc)),

          # Processing instructions
          LexerRule.new(PROCESSING_INSTRUCTION, TokenType::CommentPreproc),

          # Tags
          LexerRule.new(TAG_CLOSE,
            RuleActions.by_groups(TokenType::NameTag, TokenType::Text, TokenType::Punctuation)),

          # Opening tags
          LexerRule.new(TAG_OPEN, ->(match : String, state : LexerState, groups : Array(String)) {
            tag_name = groups[0].downcase
            state.set_context("current_tag", tag_name)
            state.push_state("tag")
            [Token.new(TokenType::NameTag, match)]
          }),

          # HTML entities (using helper for consolidation)
          *html_entity_rules,

          # Text content
          LexerRule.new(TEXT_CONTENT, TokenType::Text),
          LexerRule.new(TEXT_SPECIAL, TokenType::Text),
        ],

        "comment" => [
          LexerRule.new(COMMENT_END, RuleActions.pop(TokenType::CommentMultiline)),
          LexerRule.new(COMMENT_CONTENT, TokenType::CommentMultiline),
          LexerRule.new(COMMENT_HYPHENS, TokenType::CommentMultiline),
          LexerRule.new(COMMENT_HYPHEN, TokenType::CommentMultiline),
        ],

        "cdata" => [
          LexerRule.new(CDATA_END, RuleActions.pop(TokenType::CommentPreproc)),
          LexerRule.new(CDATA_CONTENT, TokenType::Text),
          LexerRule.new(CDATA_BRACKET, TokenType::Text),
        ],

        "tag" => [
          # Whitespace
          LexerRule.new(WHITESPACE, TokenType::Text),

          # End of tag
          LexerRule.new(TAG_END, ->(match : String, state : LexerState, groups : Array(String)) {
            state.clear_context
            state.pop_state
            [Token.new(TokenType::Punctuation, match)]
          }),

          # Self-closing tag
          LexerRule.new(TAG_SELF_CLOSE, ->(match : String, state : LexerState, groups : Array(String)) {
            state.clear_context
            state.pop_state
            [Token.new(TokenType::Punctuation, match)]
          }),

          # Attribute names
          LexerRule.new(ATTR_NAME_WITH_VALUE,
            RuleActions.by_groups(TokenType::NameAttribute, TokenType::Text, TokenType::Operator)),

          # Attribute without value
          LexerRule.new(ATTR_NAME, TokenType::NameAttribute),

          # Attribute values
          LexerRule.new(ATTR_DOUBLE_QUOTE, RuleActions.push("attr_double", TokenType::LiteralStringDouble)),
          LexerRule.new(ATTR_SINGLE_QUOTE, RuleActions.push("attr_single", TokenType::LiteralStringSingle)),

          # Unquoted attribute values
          LexerRule.new(ATTR_UNQUOTED_VALUE, TokenType::LiteralString),
        ],

        "attr_double" => [
          LexerRule.new(ATTR_DOUBLE_QUOTE, RuleActions.pop(TokenType::LiteralStringDouble)),
          # HTML entities in attributes (using helper for consolidation)
          *html_entity_rules,
          LexerRule.new(ATTR_DOUBLE_CONTENT, TokenType::LiteralStringDouble),
          LexerRule.new(ATTR_DOUBLE_AMP, TokenType::LiteralStringDouble),
        ],

        "attr_single" => [
          LexerRule.new(ATTR_SINGLE_QUOTE, RuleActions.pop(TokenType::LiteralStringSingle)),
          # HTML entities in attributes (using helper for consolidation)
          *html_entity_rules,
          LexerRule.new(ATTR_SINGLE_CONTENT, TokenType::LiteralStringSingle),
          LexerRule.new(ATTR_SINGLE_AMP, TokenType::LiteralStringSingle),
        ],
      }
    end
  end

  # Detector for <style> tags with embedded CSS
  class StyleTagDetector < RegionDetector
    include HTMLPatterns

    def detect_regions(text : String, state : LexerState) : Array(EmbeddedRegion)
      regions = [] of EmbeddedRegion
      pos = 0

      # Find all <style> tags using compiled constants
      while pos < text.size
        if match = STYLE_TAG_START.match(text, pos)
          start_tag_begin = match.begin(0)
          start_tag_end = match.end(0)

          # Find the closing tag
          if end_match = STYLE_TAG_END.match(text, start_tag_end)
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
    include HTMLPatterns

    def detect_regions(text : String, state : LexerState) : Array(EmbeddedRegion)
      regions = [] of EmbeddedRegion
      pos = 0

      # Find all <script> tags using compiled constants
      while pos < text.size
        if match = SCRIPT_TAG_START.match(text, pos)
          start_tag_begin = match.begin(0)
          start_tag_end = match.end(0)

          # Check if it's an external script (has src attribute)
          if match[0] =~ SCRIPT_SRC_ATTR
            # External script, skip to closing tag
            if end_match = SCRIPT_TAG_END.match(text, start_tag_end)
              pos = end_match.end(0)
            else
              break
            end
            next
          end

          # Find the closing tag
          if end_match = SCRIPT_TAG_END.match(text, start_tag_end)
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
