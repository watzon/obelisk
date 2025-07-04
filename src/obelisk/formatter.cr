require "json"
require "html"
require "./token"
require "./style"

module Obelisk
  # Base formatter interface
  abstract class Formatter
    abstract def format(tokens : TokenIterator, style : Style, io : IO) : Nil
    abstract def name : String

    # Format tokens to a string
    def format(tokens : TokenIterator, style : Style) : String
      String.build do |str|
        format(tokens, style, str)
      end
    end

    # Helper method to handle formatter errors gracefully
    protected def with_error_recovery(io : IO, &block)
      yield
    rescue ex
      io << "<!-- Formatter error: #{ex.message} -->"
    end
  end

  # HTML formatter
  class HTMLFormatter < Formatter
    property name : String = "html"

    @with_classes : Bool
    @class_prefix : String
    @standalone : Bool
    @with_line_numbers : Bool
    @line_number_start : Int32
    @tab_width : Int32
    @highlight_lines : Set(Int32)?
    @line_anchors : Bool
    @line_numbers_in_table : Bool
    @wrap_long_lines : Bool

    def initialize(@with_classes = false,
                   @class_prefix = "",
                   @standalone = false,
                   @with_line_numbers = false,
                   @line_number_start = 1,
                   @tab_width = 4,
                   @highlight_lines : Set(Int32)? = nil,
                   @line_anchors = false,
                   @line_numbers_in_table = false,
                   @wrap_long_lines = false)
    end

    def format(tokens : TokenIterator, style : Style, io : IO) : Nil
      with_error_recovery(io) do
        if @standalone
          write_standalone_html(tokens, style, io)
        else
          write_html_fragment(tokens, style, io)
        end
      end
    end

    # Generate CSS for the given style
    def css(style : Style) : String
      return "" unless @with_classes

      String.build do |css|
        css << "/* Generated by Obelisk */\n"
        # Line-based styles
        css << ".highlight { background: #{style.background.to_hex}; display: inline-block; }\n"
        css << ".highlight pre { line-height: 1.2; margin: 0; font-size: inherit; font-family: inherit; }\n"
        css << ".line { display: flex; margin: 0; align-items: baseline; }\n"
        css << ".line-numbers { white-space: pre; -webkit-user-select: none; user-select: none; margin-right: 0.8em; color: #999999; line-height: 1.2; min-width: 2em; text-align: right; font-family: inherit; }\n"
        css << ".line-numbers a { color: inherit; text-decoration: none; }\n"
        css << ".line-numbers a:hover { text-decoration: underline; }\n"
        css << ".code-line { flex: 1; line-height: 1.2; white-space: pre; padding-right: 0.8em; font-family: inherit; }\n"

        # Highlighted lines
        css << ".line.highlighted { background-color: rgba(255, 255, 0, 0.2); margin-left: -0.8em; margin-right: -0.8em; padding-left: 0.8em; padding-right: 0.8em; }\n"

        # Table-based styles (when using line numbers in table)
        css << ".highlighttable { border-spacing: 0; width: 100%; font-family: inherit; }\n"
        css << ".highlighttable td { padding: 0; vertical-align: baseline; }\n"
        css << ".highlighttable .linenos { text-align: right; padding-right: 0.8em; }\n"
        css << ".highlighttable .linenos pre { line-height: 1.2; margin: 0; font-family: inherit; }\n"
        css << ".highlighttable .code { width: 100%; }\n"
        css << ".highlighttable .code pre { line-height: 1.2; margin: 0; padding-right: 0.8em; font-family: inherit; }\n"

        # Wrap long lines if enabled
        if @wrap_long_lines
          css << ".highlight pre { white-space: pre-wrap; word-break: break-word; }\n"
        end

        style.entries.each do |token_type, entry|
          css_class = token_type.css_class
          next if css_class.empty?

          full_class = @class_prefix.empty? ? css_class : "#{@class_prefix}#{css_class}"
          css_rules = [] of String

          if color = entry.color
            unless color.transparent?
              css_rules << "color: #{color.to_hex}"
            end
          end

          if background = entry.background
            unless background.transparent?
              css_rules << "background-color: #{background.to_hex}"
            end
          end

          css_rules << "font-weight: bold" if entry.bold?
          css_rules << "font-style: italic" if entry.italic?
          css_rules << "text-decoration: underline" if entry.underline?

          unless css_rules.empty?
            css << ".#{full_class} { #{css_rules.join("; ")} }\n"
          end
        end
      end
    end

    private def write_standalone_html(tokens : TokenIterator, style : Style, io : IO)
      io << "<!DOCTYPE html>\n"
      io << "<html>\n<head>\n"
      io << "<meta charset=\"UTF-8\">\n"
      io << "<title>Syntax Highlighted Code</title>\n"

      if @with_classes
        io << "<style>\n"
        io << css(style)
        io << "</style>\n"
      end

      io << "</head>\n<body>\n"
      write_html_fragment(tokens, style, io)
      io << "</body>\n</html>\n"
    end

    private def write_html_fragment(tokens : TokenIterator, style : Style, io : IO)
      # Split tokens into lines first
      lines = split_tokens_into_lines(tokens, style)

      if @with_line_numbers && @line_numbers_in_table
        write_html_table_with_line_numbers(lines, style, io)
      else
        write_html_with_inline_formatting(lines, style, io)
      end
    end

    # Split tokens into lines, preserving token information
    private def split_tokens_into_lines(tokens : TokenIterator, style : Style) : Array(Array(Tuple(String, TokenType)))
      lines = [] of Array(Tuple(String, TokenType))
      current_line = [] of Tuple(String, TokenType)
      first_non_whitespace_seen = false

      tokens.each do |token|
        escaped_value = HTML.escape(token.value.gsub("\t", " " * @tab_width))

        # Skip leading whitespace-only tokens before we see any real content
        if !first_non_whitespace_seen && token.value.strip.empty?
          next
        end
        first_non_whitespace_seen = true

        if token.value.includes?('\n')
          parts = escaped_value.split('\n', remove_empty: false)

          # Add first part to current line (even if empty, to preserve content)
          current_line << {parts.first, token.type} unless parts.first.empty?

          # Complete current line and add it
          lines << current_line

          # Handle middle parts (complete lines)
          (1...parts.size - 1).each do |i|
            if parts[i].empty?
              lines << [] of Tuple(String, TokenType)
            else
              lines << [{parts[i], token.type}]
            end
          end

          # Start new line with last part
          current_line = [] of Tuple(String, TokenType)
          current_line << {parts.last, token.type} unless parts.last.empty?
        elsif !token.value.empty?
          current_line << {escaped_value, token.type}
        end
      end

      # Only add the final line if it has content
      if !current_line.empty?
        lines << current_line
      end

      # Remove any empty lines at the start and end
      while !lines.empty? && lines.first.empty?
        lines.shift
      end
      while !lines.empty? && lines.last.empty?
        lines.pop
      end

      # Ensure we have at least one line
      if lines.empty?
        lines << [] of Tuple(String, TokenType)
      end

      lines
    end

    # Write HTML with inline formatting (line numbers inline with each line)
    private def write_html_with_inline_formatting(lines : Array(Array(Tuple(String, TokenType))), style : Style, io : IO)
      io << "<div class=\"highlight\"><pre>"

      line_digits = (@line_number_start + lines.size - 1).to_s.size

      lines.each_with_index do |line_tokens, index|
        line_num = @line_number_start + index
        highlight_lines = @highlight_lines
        is_highlighted = highlight_lines && highlight_lines.includes?(line_num)

        # Start line container
        if @with_line_numbers || is_highlighted
          io << "<span class=\"line"
          io << " highlighted" if is_highlighted
          io << "\">"
        end

        # Add line number if enabled
        if @with_line_numbers
          io << "<span class=\"line-numbers\">"
          if @line_anchors
            io << "<a id=\"L#{line_num}\" href=\"#L#{line_num}\">#{line_num.to_s.rjust(line_digits)}</a>"
          else
            io << line_num.to_s.rjust(line_digits)
          end
          io << "</span>"

          # Add code line container
          io << "<span class=\"code-line\">"
        end

        # Output the actual code tokens
        line_tokens.each do |text, token_type|
          if @with_classes
            css_class = token_type.css_class
            if css_class.empty?
              io << text
            else
              full_class = @class_prefix.empty? ? css_class : "#{@class_prefix}#{css_class}"
              io << "<span class=\"#{full_class}\">#{text}</span>"
            end
          else
            entry = style.get(token_type)
            if entry.has_styles?
              style_attr = build_style_attribute(entry)
              io << "<span style=\"#{style_attr}\">#{text}</span>"
            else
              io << text
            end
          end
        end

        # Close code line container if we opened it
        if @with_line_numbers
          io << "</span>"
        end

        # Close line container if we opened it
        if @with_line_numbers || is_highlighted
          io << "</span>"
        end
      end

      io << "</pre></div>"
    end

    # Write HTML table with line numbers in separate column
    private def write_html_table_with_line_numbers(lines : Array(Array(Tuple(String, TokenType))), style : Style, io : IO)
      io << "<div class=\"highlight\">"
      io << "<table class=\"highlighttable\"><tr>"

      # Line numbers column
      io << "<td class=\"linenos\"><pre>"
      line_digits = (@line_number_start + lines.size - 1).to_s.size
      lines.each_with_index do |_, index|
        line_num = @line_number_start + index
        if @line_anchors
          io << "<a id=\"L#{line_num}\" href=\"#L#{line_num}\">#{line_num.to_s.rjust(line_digits)}</a>"
        else
          io << line_num.to_s.rjust(line_digits)
        end
        io << "\n" if index < lines.size - 1
      end
      io << "</pre></td>"

      # Code column
      io << "<td class=\"code\"><pre>"
      lines.each_with_index do |line_tokens, index|
        line_num = @line_number_start + index
        highlight_lines = @highlight_lines
        is_highlighted = highlight_lines && highlight_lines.includes?(line_num)

        # Start line span if highlighted
        io << "<span class=\"highlighted\">" if is_highlighted

        # Output tokens
        line_tokens.each do |text, token_type|
          if @with_classes
            css_class = token_type.css_class
            if css_class.empty?
              io << text
            else
              full_class = @class_prefix.empty? ? css_class : "#{@class_prefix}#{css_class}"
              io << "<span class=\"#{full_class}\">#{text}</span>"
            end
          else
            entry = style.get(token_type)
            if entry.has_styles?
              style_attr = build_style_attribute(entry)
              io << "<span style=\"#{style_attr}\">#{text}</span>"
            else
              io << text
            end
          end
        end

        # End line span if highlighted
        io << "</span>" if is_highlighted

        # Add newline except for last line
        io << "\n" if index < lines.size - 1
      end
      io << "</pre></td>"

      io << "</tr></table>"
      io << "</div>"
    end

    private def append_token_html(io : String::Builder, token_type : TokenType, value : String, style : Style)
      if @with_classes
        css_class = token_type.css_class
        if css_class.empty?
          io << value
        else
          full_class = @class_prefix.empty? ? css_class : "#{@class_prefix}#{css_class}"
          io << "<span class=\"#{full_class}\">#{value}</span>"
        end
      else
        entry = style.get(token_type)
        if entry.has_styles?
          style_attr = build_style_attribute(entry)
          io << "<span style=\"#{style_attr}\">#{value}</span>"
        else
          io << value
        end
      end
    end

    private def write_line_numbered_html(lines : Array(String), io : IO)
      io << "<div class=\"highlight\"><table class=\"highlighttable\"><tr>"

      # Line numbers column
      io << "<td class=\"linenos\"><div class=\"linenodiv\"><pre>"
      lines.each_with_index do |_, index|
        line_num = @line_number_start + index
        if @line_anchors
          io << "<a id=\"L#{line_num}\" href=\"#L#{line_num}\">#{line_num}</a>\n"
        else
          io << "#{line_num}\n"
        end
      end
      io << "</pre></div></td>"

      # Code column
      io << "<td class=\"code\"><div class=\"highlight\"><pre>"
      lines.each_with_index do |line, index|
        line_num = @line_number_start + index
        highlight_lines = @highlight_lines
        if highlight_lines && highlight_lines.includes?(line_num)
          io << "<span class=\"highlighted-line\">#{line}</span>\n"
        else
          io << line << "\n"
        end
      end
      io << "</pre></div></td>"

      io << "</tr></table></div>"
    end

    private def build_style_attribute(entry : StyleEntry) : String
      styles = [] of String

      if color = entry.color
        unless color.transparent?
          styles << "color: #{color.to_hex}"
        end
      end

      if background = entry.background
        unless background.transparent?
          styles << "background-color: #{background.to_hex}"
        end
      end

      styles << "font-weight: bold" if entry.bold?
      styles << "font-style: italic" if entry.italic?
      styles << "text-decoration: underline" if entry.underline?

      styles.join("; ")
    end
  end

  # Terminal ANSI formatter
  class ANSIFormatter < Formatter
    getter name : String = "terminal"

    def format(tokens : TokenIterator, style : Style, io : IO) : Nil
      with_error_recovery(io) do
        tokens.each do |token|
          next if token.value.empty?

          entry = style.get(token.type)
          if entry.has_styles?
            ansi_codes = build_ansi_codes(entry)
            io << ansi_codes << token.value << "\e[0m"
          else
            io << token.value
          end
        end
      end
    end

    private def build_ansi_codes(entry : StyleEntry) : String
      codes = [] of String

      if color = entry.color
        unless color.transparent?
          codes << "38;2;#{color.red};#{color.green};#{color.blue}"
        end
      end

      if background = entry.background
        unless background.transparent?
          codes << "48;2;#{background.red};#{background.green};#{background.blue}"
        end
      end

      codes << "1" if entry.bold?
      codes << "3" if entry.italic?
      codes << "4" if entry.underline?

      codes.empty? ? "" : "\e[#{codes.join(";")}m"
    end
  end

  # Plain text formatter (strips all formatting)
  class PlainFormatter < Formatter
    getter name : String = "text"

    def format(tokens : TokenIterator, style : Style, io : IO) : Nil
      tokens.each do |token|
        io << token.value
      end
    end
  end

  # JSON formatter for debugging
  class JSONFormatter < Formatter
    getter name : String = "json"

    def format(tokens : TokenIterator, style : Style, io : IO) : Nil
      token_array = [] of Hash(String, String)

      tokens.each do |token|
        token_array << {
          "type"  => token.type.to_s,
          "value" => token.value,
        }
      end

      JSON.build(io) do |json|
        json.array do
          token_array.each do |token_hash|
            json.object do
              token_hash.each do |key, value|
                json.field key, value
              end
            end
          end
        end
      end
    end
  end
end
