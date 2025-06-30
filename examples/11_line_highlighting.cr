require "../src/obelisk"

# Example 11: Line Highlighting
# This example demonstrates how to highlight specific lines in HTML output

code = %q(
class Person
  getter name : String
  getter age : Int32

  def initialize(@name : String, @age : Int32)
    validate_age!
  end

  def validate_age!
    raise ArgumentError.new("Age must be positive") if @age < 0
  end

  def birthday
    @age += 1
    puts "Happy birthday, #{@name}! You are now #{@age}."
  end

  def can_vote?
    @age >= 18
  end
end

person = Person.new("Alice", 17)
person.birthday
puts "Can vote? #{person.can_vote?}"
)

puts "=== Basic Line Highlighting ==="
# Create formatter with line numbers and specific lines highlighted
formatter = Obelisk::HTMLFormatter.new(
  with_classes: true,
  with_line_numbers: true,
  highlight_lines: Set{9, 10, 11, 14, 15}  # Highlight validation method
)

lexer = Obelisk.lexer("crystal")
style = Obelisk.style("github")

if lexer && style
  tokens = lexer.tokenize(code)
  html = formatter.format(tokens, style)
  
  # Generate CSS including highlight styles
  css = formatter.css(style)
  
  # Write to an HTML file
  File.write("highlighted_lines.html", <<-HTML)
<!DOCTYPE html>
<html>
<head>
  <title>Line Highlighting Example</title>
  <style>
    body { font-family: monospace; }
    #{css}
  </style>
</head>
<body>
  <h1>Line Highlighting Example</h1>
  <p>Lines 9-11 and 14-15 are highlighted (the validation method):</p>
  #{html}
</body>
</html>
HTML
  
  puts "HTML with highlighted lines written to highlighted_lines.html"
  puts "Open the file in a browser to see the highlighted lines!"
end

puts "\n=== Line Highlighting with Anchors ==="
# Create formatter with line anchors for linking
formatter_with_anchors = Obelisk::HTMLFormatter.new(
  with_classes: true,
  with_line_numbers: true,
  line_anchors: true,
  highlight_lines: Set{19, 20, 21}  # Highlight birthday method
)

if lexer && style
  tokens = lexer.tokenize(code)
  html = formatter_with_anchors.format(tokens, style)
  puts "With line anchors, you can link to specific lines:"
  puts "  - Link to line 19: #L19"
  puts "  - Link to line 20: #L20"
end

puts "\n=== Range-based Line Highlighting ==="
# Helper to create ranges
def line_range(start : Int32, finish : Int32) : Set(Int32)
  (start..finish).to_set
end

# Highlight multiple ranges
highlight_ranges = line_range(6, 11) + line_range(18, 21)
formatter_ranges = Obelisk::HTMLFormatter.new(
  with_classes: true,
  with_line_numbers: true,
  highlight_lines: highlight_ranges
)

if lexer && style
  tokens = lexer.tokenize(code)
  html = formatter_ranges.format(tokens, style)
  puts "Highlighted ranges: lines 6-11 (constructor) and 18-21 (birthday method)"
end

puts "\n=== Inline Style Line Highlighting ==="
# Without CSS classes, using inline styles
formatter_inline = Obelisk::HTMLFormatter.new(
  with_classes: false,
  with_line_numbers: true,
  highlight_lines: Set{24, 25}  # Highlight can_vote? method
)

if lexer && style
  tokens = lexer.tokenize(code)
  html = formatter_inline.format(tokens, style)
  puts "Line highlighting also works with inline styles (no CSS needed)"
end