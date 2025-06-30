require "../src/obelisk"

# Example 01: Basic Usage
# This example shows the simplest way to use Obelisk for syntax highlighting

code = %q(
def greet(name : String) : String
  "Hello, #{name}!"
end

puts greet("World")
)

# Highlight code with default settings (HTML formatter, GitHub style)
highlighted = Obelisk.highlight(code, "crystal")
puts highlighted

puts "\n" + "="*50 + "\n"

# You can also specify formatter and style explicitly
highlighted = Obelisk.highlight(code, "crystal", "html", "monokai")
puts highlighted

puts "\n" + "="*50 + "\n"

# List available components
puts "Available languages: #{Obelisk.lexer_names.join(", ")}"
puts "Available formatters: #{Obelisk.formatter_names.join(", ")}"
puts "Available styles: #{Obelisk.style_names.join(", ")}"