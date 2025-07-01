require "../lexer"

module Obelisk::Lexers
  # Base Markdown lexer for non-code content
  class MarkdownBase < RegexLexer
    def config : LexerConfig
      LexerConfig.new(
        name: "markdown",
        aliases: ["markdown", "md", "mkd"],
        filenames: ["*.md", "*.markdown", "*.mkd", "*.mdown"],
        mime_types: ["text/markdown", "text/x-markdown"],
        priority: 1.0f32
      )
    end

    def analyze(text : String) : Float32
      score = 0.0f32
      lines = text.lines.first(50) # Analyze first 50 lines

      # Markdown-specific patterns
      lines.each do |line|
        # Strong indicators
        score += 0.2 if line =~ /^\#{1,6}\s+/   # Headers
        score += 0.15 if line =~ /^\s*[-*+]\s+/ # Unordered lists
        score += 0.15 if line =~ /^\s*\d+\.\s+/ # Ordered lists
        score += 0.15 if line =~ /^\s*>\s+/     # Blockquotes
        score += 0.1 if line =~ /^```/          # Code blocks
        score += 0.1 if line =~ /^\s{4,}\S/     # Indented code blocks
        score += 0.1 if line =~ /^---+$/        # Horizontal rules
        score += 0.1 if line =~ /^\*\*\*+$/     # Horizontal rules
        score += 0.1 if line =~ /^___+$/        # Horizontal rules

        # Inline elements
        score += 0.05 if line =~ /\*\*[^*]+\*\*/        # Bold with **
        score += 0.05 if line =~ /__[^_]+__/            # Bold with __
        score += 0.05 if line =~ /\*[^*]+\*/            # Italic with *
        score += 0.05 if line =~ /_[^_]+_/              # Italic with _
        score += 0.05 if line =~ /`[^`]+`/              # Inline code
        score += 0.05 if line =~ /\[[^\]]+\]\([^)]+\)/  # Links
        score += 0.05 if line =~ /!\[[^\]]*\]\([^)]+\)/ # Images
        score += 0.05 if line =~ /\[[^\]]+\]:\s+\S+/    # Reference links

        # Tables
        score += 0.1 if line =~ /^\|.*\|/        # Table rows
        score += 0.15 if line =~ /^\|[\s:|-]+\|/ # Table separator
      end

      # YAML frontmatter
      if lines.first? == "---"
        score += 0.2
      end

      # Negative indicators (not Markdown)
      score -= 0.3 if text =~ /^\s*<\?xml/      # XML
      score -= 0.3 if text =~ /^\s*<!DOCTYPE/   # HTML (though MD can contain HTML)
      score -= 0.2 if text =~ /^\s*\{/          # JSON
      score -= 0.2 if text =~ /^\s*function\s+/ # JavaScript
      score -= 0.2 if text =~ /^\s*def\s+/      # Python/Ruby

      # Cap the score at 1.0
      [score, 1.0f32].min
    end

    def rules : Hash(String, Array(LexerRule))
      {
        "root" => [
          # YAML frontmatter (check state for document start AND that there's a closing ---)
          LexerRule.new(/^---[ \t]*(?=\n|$)/, ->(match : String, state : LexerState, groups : Array(String)) {
            # Only treat as frontmatter if:
            # 1. We're at the very beginning (position 0 or only whitespace before)
            # 2. There's a closing --- somewhere later in the text
            if (state.pos == 0 || state.text[0...state.pos].strip.empty?) &&
               state.text[state.pos + match.size..].includes?("\n---")
              state.push_state("frontmatter")
              [Token.new(TokenType::CommentPreproc, match)]
            else
              # Otherwise treat as horizontal rule
              [Token.new(TokenType::Punctuation, match)]
            end
          }),

          # ATX Headers (# through ######)
          LexerRule.new(/^(\#{1,6})(\s+)/, RuleActions.by_groups(
            TokenType::GenericHeading,
            TokenType::Text
          )),

          # Code blocks (fenced with ``` or ~~~) - handled by delegating lexer
          # Note: Fenced code blocks are excluded from base lexer processing

          # Horizontal rules (must have at least 3 characters and not be frontmatter)
          LexerRule.new(/^[ \t]*(-{3,}|\*{3,}|_{3,})[ \t]*$/, TokenType::Punctuation),

          # Ordered lists
          LexerRule.new(/^(\s*)(\d+\.)(\s+)/, RuleActions.by_groups(
            TokenType::Text,
            TokenType::LiteralNumberInteger,
            TokenType::Text
          )),

          # Unordered lists (-, *, +)
          LexerRule.new(/^(\s*)([-*+])(\s+)/, RuleActions.by_groups(
            TokenType::Text,
            TokenType::Punctuation,
            TokenType::Text
          )),

          # Blockquotes
          LexerRule.new(/^(\s*)(>)(\s*)/, RuleActions.by_groups(
            TokenType::Text,
            TokenType::Punctuation,
            TokenType::Text
          )),

          # Indented code blocks (4 spaces or tab)
          LexerRule.new(/^(    |\t)/, TokenType::Text),

          # Table separator lines
          LexerRule.new(/^\|([\s:|-]+)\|/, RuleActions.by_groups(TokenType::Punctuation)),

          # Table row start
          LexerRule.new(/^\|/, TokenType::Punctuation),

          # Reference-style links/images definitions
          LexerRule.new(/^\[([^\]]+)\]:(\s*)(.+)$/, RuleActions.by_groups(
            TokenType::NameLabel,
            TokenType::Text,
            TokenType::LiteralString
          )),

          # Bold text **text** or __text__
          LexerRule.new(/\*\*([^*]+)\*\*/, TokenType::GenericStrong),
          LexerRule.new(/__([^_]+)__/, TokenType::GenericStrong),

          # Italic text *text* or _text_
          LexerRule.new(/\*([^*\n]+)\*/, TokenType::GenericEmph),
          LexerRule.new(/_([^_\n]+)_/, TokenType::GenericEmph),

          # Inline code `code`
          LexerRule.new(/`([^`]+)`/, TokenType::LiteralStringBacktick),

          # Images ![alt](url)
          LexerRule.new(/!\[([^\]]*)\]\(([^)]+)\)/, ->(match : String, state : LexerState, groups : Array(String)) {
            tokens = [] of Token
            tokens << Token.new(TokenType::Punctuation, "![")
            tokens << Token.new(TokenType::NameAttribute, groups[0])
            tokens << Token.new(TokenType::Punctuation, "](")
            tokens << Token.new(TokenType::LiteralString, groups[1])
            tokens << Token.new(TokenType::Punctuation, ")")
            tokens
          }),

          # Links [text](url)
          LexerRule.new(/\[([^\]]+)\]\(([^)]+)\)/, ->(match : String, state : LexerState, groups : Array(String)) {
            tokens = [] of Token
            tokens << Token.new(TokenType::Punctuation, "[")
            tokens << Token.new(TokenType::NameAttribute, groups[0])
            tokens << Token.new(TokenType::Punctuation, "](")
            tokens << Token.new(TokenType::LiteralString, groups[1])
            tokens << Token.new(TokenType::Punctuation, ")")
            tokens
          }),

          # Reference links [text][ref] or [text]
          LexerRule.new(/\[([^\]]+)\](\[([^\]]*)\])?/, RuleActions.by_groups(
            TokenType::NameAttribute,
            TokenType::NameLabel
          )),

          # HTML tags (basic support)
          LexerRule.new(/<[^>]+>/, TokenType::NameTag),

          # Autolinks <http://example.com> or <email@example.com>
          LexerRule.new(/<(https?:\/\/[^>]+|[^@\s>]+@[^@\s>]+\.[^@\s>]+)>/, TokenType::LiteralString),

          # Table cell separators
          LexerRule.new(/\|/, TokenType::Punctuation),

          # Whitespace
          LexerRule.new(/\s+/, TokenType::Text),

          # Regular text
          LexerRule.new(/[^\s*_`[\]<>|#-]+/, TokenType::Text),
          LexerRule.new(/[*_`[\]<>|#-]/, TokenType::Text),
        ],

        "frontmatter" => [
          LexerRule.new(/^---[ \t]*(?=\n|$)/, RuleActions.pop(TokenType::CommentPreproc)),
          LexerRule.new(/[^\n]+/, TokenType::CommentPreproc),
          LexerRule.new(/\n/, TokenType::Text),
        ],

      }
    end
  end

  # Region detector for Markdown code blocks
  class MarkdownCodeBlockDetector < RegionDetector
    def detect_regions(text : String, state : LexerState) : Array(EmbeddedRegion)
      regions = [] of EmbeddedRegion
      lines = text.lines
      current_pos = 0

      lines.each_with_index do |line, line_index|
        line_start_pos = current_pos

        # Look for fenced code block start
        if match = /^(```|~~~)([a-zA-Z0-9_+-]*).*$/.match(line)
          fence_type = match[1]
          language = match[2]?.try(&.downcase) || ""

          # Skip if no language specified
          if language.empty?
            current_pos += line.bytesize + 1 # +1 for newline
            next
          end

          # Try to get the appropriate lexer
          lexer = get_lexer_for_language(language)
          unless lexer
            current_pos += line.bytesize + 1 # +1 for newline
            next
          end

          # Code content starts after this line
          content_start_pos = current_pos + line.bytesize + 1
          start_token = Token.new(TokenType::LiteralStringBacktick, match[0])

          # Find the closing fence
          content_end_pos = nil
          end_token = nil
          closing_pattern = /^#{Regex.escape(fence_type)}[ \t]*$/
          search_pos = content_start_pos

          (line_index + 1...lines.size).each do |end_line_index|
            end_line = lines[end_line_index]
            if closing_match = closing_pattern.match(end_line)
              content_end_pos = search_pos
              end_token = Token.new(TokenType::LiteralStringBacktick, closing_match[0])
              break
            end
            search_pos += end_line.bytesize + 1 # +1 for newline
          end

          if content_end_pos && content_end_pos > content_start_pos
            regions << EmbeddedRegion.new(content_start_pos, content_end_pos, lexer, start_token, end_token)
          end
        end

        current_pos += line.bytesize + 1 # +1 for newline
      end

      regions
    end

    private def get_lexer_for_language(language : String) : Lexer?
      # Map common language names to lexer names
      language_map = {
        "rb"   => "ruby",
        "py"   => "python",
        "js"   => "javascript",
        "ts"   => "typescript",
        "jsx"  => "javascript",
        "tsx"  => "javascript",
        "rs"   => "rust",
        "cpp"  => "c",
        "c++"  => "c",
        "cxx"  => "c",
        "cc"   => "c",
        "h"    => "c",
        "hpp"  => "c",
        "sh"   => "shell",
        "bash" => "shell",
        "zsh"  => "shell",
        "fish" => "shell",
        "yml"  => "yaml",
        "htm"  => "html",
      }

      # Try direct lookup first
      lexer_name = language_map[language]? || language
      Registry.lexers.get(lexer_name)
    end
  end

  # Main Markdown lexer with embedded language support
  class Markdown < DelegatingLexer
    def initialize
      super()
      add_region_detector(MarkdownCodeBlockDetector.new)
    end

    def config : LexerConfig
      LexerConfig.new(
        name: "markdown",
        aliases: ["markdown", "md", "mkd"],
        filenames: ["*.md", "*.markdown", "*.mkd", "*.mdown"],
        mime_types: ["text/markdown", "text/x-markdown"],
        priority: 1.0f32
      )
    end

    def base_lexer : RegexLexer
      MarkdownBase.new
    end

    def analyze(text : String) : Float32
      # Use the same analysis as the base lexer
      base_lexer.analyze(text)
    end
  end
end
