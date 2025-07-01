require "../src/obelisk"

# Example 02: HTML Output Options
# This example demonstrates different HTML output configurations

code = %q(
class User
  property name : String
  property email : String

  def initialize(@name, @email)
  end

  def valid?
    !@name.empty? && @email.includes?("@")
  end
end

user = User.new("Alice", "alice@example.com")
puts user.valid? # => true
)

puts "=== HTML with Inline Styles (default) ==="
# This is the default - generates HTML with inline style attributes
html = Obelisk.highlight(code, "crystal", "html", "github")
puts html

puts "\n=== HTML with CSS Classes ==="
# Generate HTML with CSS classes instead of inline styles
formatter = Obelisk::HTMLFormatter.new(with_classes: true)
lexer = Obelisk.lexer("crystal")
style = Obelisk.style("github")

if lexer && style
  tokens = lexer.tokenize(code)
  html_with_classes = formatter.format(tokens, style)
  puts html_with_classes
end

puts "\n=== HTML with Custom Class Prefix ==="
# Use a custom prefix for CSS classes to avoid conflicts
formatter = Obelisk::HTMLFormatter.new(
  with_classes: true,
  class_prefix: "hl-"
)

if lexer && style
  tokens = lexer.tokenize(code)
  html_custom_prefix = formatter.format(tokens, style)
  puts html_custom_prefix
end

puts "\n=== HTML with Line Numbers ==="
# Enable line numbers in the output
formatter = Obelisk::HTMLFormatter.new(
  with_line_numbers: true,
  line_number_start: 1
)

if lexer && style
  tokens = lexer.tokenize(code)
  html_with_lines = formatter.format(tokens, style)
  puts html_with_lines
end

puts "\n=== Standalone HTML Page ==="
# Generate a complete HTML page with embedded styles
formatter = Obelisk::HTMLFormatter.new(with_classes: false)
if lexer && style
  tokens = lexer.tokenize(code)
  highlighted_code = formatter.format(tokens, style)

  html_page = <<-HTML
  <!DOCTYPE html>
  <html>
  <head>
    <title>Obelisk Syntax Highlighting Example</title>
    <style>
      body { 
        font-family: 'Monaco', 'Consolas', monospace; 
        margin: 20px;
        background-color: #f5f5f5;
      }
      h1 { color: #333; }
    </style>
  </head>
  <body>
    <h1>Crystal Code Example</h1>
    #{highlighted_code}
  </body>
  </html>
  HTML

  puts html_page
end
