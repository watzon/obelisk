require "../src/obelisk"

# Example 05: Custom Formatter
# This example shows how to create your own formatter

# Create a custom formatter that outputs Markdown with syntax info
class MarkdownFormatter < Obelisk::Formatter
  def name : String
    "markdown"
  end

  def format(tokens : Obelisk::TokenIterator, style : Obelisk::Style, io : IO) : Nil
    io << "```crystal\n"

    current_line = [] of {Obelisk::Token, String}

    tokens.each do |token|
      if token.value.includes?("\n")
        # Handle tokens with newlines
        lines = token.value.split('\n', remove_empty: false)

        lines.each_with_index do |line, idx|
          if idx > 0
            # Output current line and start new one
            output_line(io, current_line)
            io << '\n'
            current_line.clear
          end

          unless line.empty?
            # Generate markdown formatting
            formatted = format_token(token, line)
            current_line << {token, formatted}
          end
        end
      else
        # Single line token
        formatted = format_token(token, token.value)
        current_line << {token, formatted}
      end
    end

    # Output final line
    output_line(io, current_line) unless current_line.empty?

    io << "\n```"
  end

  private def format_token(token : Obelisk::Token, text : String) : String
    case token.type
    when .keyword?, .keyword_declaration?, .keyword_type?
      "**#{text}**" # Bold for keywords
    when .comment?, .comment_single?
      "_#{text}_" # Italic for comments
    when .literal_string?, .literal_string_double?
      "`#{text}`" # Code style for strings
    when .name_function?, .name_class?
      "**`#{text}`**" # Bold code for functions/classes
    else
      text
    end
  end

  private def output_line(io : IO, line : Array({Obelisk::Token, String}))
    line.each do |(token, formatted)|
      io << formatted
    end
  end
end

# Create a custom formatter that outputs a simple token list
class TokenListFormatter < Obelisk::Formatter
  def name : String
    "tokenlist"
  end

  def format(tokens : Obelisk::TokenIterator, style : Obelisk::Style, io : IO) : Nil
    io << "Token List:\n"
    io << "-" * 50 << '\n'

    tokens.each_with_index do |token, idx|
      io << sprintf("%3d: %-25s %s\n", idx, token.type.to_s, token.value.inspect)
    end
  end
end

# Create a custom formatter that generates BBCode for forums
class BBCodeFormatter < Obelisk::Formatter
  def name : String
    "bbcode"
  end

  def format(tokens : Obelisk::TokenIterator, style : Obelisk::Style, io : IO) : Nil
    io << "[code]\n"

    tokens.each do |token|
      text = token.value

      formatted = case token.type
                  when .keyword?, .keyword_declaration?
                    "[color=red][b]#{text}[/b][/color]"
                  when .comment?, .comment_single?
                    "[color=gray][i]#{text}[/i][/color]"
                  when .literal_string?, .literal_string_double?
                    "[color=green]#{text}[/color]"
                  when .literal_number?
                    "[color=blue]#{text}[/color]"
                  when .name_function?, .name_class?
                    "[color=purple]#{text}[/color]"
                  else
                    text
                  end

      io << formatted
    end

    io << "\n[/code]"
  end
end

# Test code
code = %q(
# A simple greeting function
def greet(name : String) : String
  message = "Hello, #{name}!"
  puts message
  return message
end

greet("World")
)

# Get lexer and tokenize
lexer = Obelisk.lexer("crystal")
style = Obelisk.style("github")

if lexer && style
  puts "=== Markdown Formatter ==="
  formatter = MarkdownFormatter.new
  tokens = lexer.tokenize(code)
  output = formatter.format(tokens, style)
  puts output

  puts "\n=== Token List Formatter ==="
  formatter = TokenListFormatter.new
  tokens = lexer.tokenize(code)
  output = formatter.format(tokens, style)
  puts output

  puts "\n=== BBCode Formatter ==="
  formatter = BBCodeFormatter.new
  tokens = lexer.tokenize(code)
  output = formatter.format(tokens, style)
  puts output
end

# Register custom formatter for use with Obelisk.highlight
puts "\n=== Registering Custom Formatter ==="
Obelisk::Registry.formatters.register("markdown", MarkdownFormatter.new)

# Now we can use it directly
highlighted = Obelisk.highlight(code, "crystal", "markdown", "github")
puts highlighted
