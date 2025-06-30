require "../src/obelisk"

# Example demonstrating line number alignment with wrapped lines

code = <<-'CODE'
# This is a very long comment line that should wrap when displayed in a narrow container to test if line numbers stay aligned
def process_complex_data_structure_with_very_long_method_name(parameter_one : String, parameter_two : Int32, parameter_three : Bool)
  # Another long line with a very detailed comment about what this method does and why it needs such a long name
  result = parameter_one.split(',').map { |item| item.strip.upcase }.select { |item| item.size > parameter_two }.join(" - ")
  
  if parameter_three && result.includes?("IMPORTANT")
    puts "Processing important data: #{result}"
    return result
  end
  
  # Short line
  nil
end

# Test data with mixed line lengths
data = {
  "short" => 1,
  "medium_length_key" => 2,
  "very_long_key_name_that_might_cause_wrapping_issues_in_display" => 3,
  "another_extremely_long_key_to_test_line_wrapping_behavior_in_the_formatter" => 4
}
CODE

lexer = Obelisk::Registry.lexers.get!("crystal")
style = Obelisk::Registry.styles.get!("github")

# Test 1: Inline line numbers with wrapping enabled
puts "=== Test 1: Inline Line Numbers with Wrap ==="
formatter = Obelisk::HTMLFormatter.new(
  with_classes: true,
  with_line_numbers: true,
  line_numbers_in_table: false,
  wrap_long_lines: true,
  line_anchors: true,
  highlight_lines: Set{2, 4, 8}
)

html = formatter.format(lexer.tokenize(code), style)
css = formatter.css(style)

# Write to file for testing
File.write("test_inline_wrap.html", <<-HTML)
<!DOCTYPE html>
<html>
<head>
<style>
body { font-family: monospace; max-width: 800px; margin: 0 auto; padding: 20px; }
.test-container { border: 1px solid #ccc; overflow-x: auto; margin: 20px 0; }
#{css}
</style>
</head>
<body>
<h2>Inline Line Numbers with Wrapping</h2>
<div class="test-container">
#{html}
</div>
</body>
</html>
HTML

# Test 2: Table-based line numbers
puts "\n=== Test 2: Table-based Line Numbers ==="
formatter2 = Obelisk::HTMLFormatter.new(
  with_classes: true,
  with_line_numbers: true,
  line_numbers_in_table: true,
  wrap_long_lines: false,
  line_anchors: true,
  highlight_lines: Set{2, 4, 8}
)

html2 = formatter2.format(lexer.tokenize(code), style)

# Write to file for testing
File.write("test_table_nowrap.html", <<-HTML)
<!DOCTYPE html>
<html>
<head>
<style>
body { font-family: monospace; max-width: 800px; margin: 0 auto; padding: 20px; }
.test-container { border: 1px solid #ccc; overflow-x: auto; margin: 20px 0; }
#{css}
</style>
</head>
<body>
<h2>Table-based Line Numbers (No Wrapping)</h2>
<div class="test-container">
#{html2}
</div>
</body>
</html>
HTML

# Test 3: No line numbers for comparison
puts "\n=== Test 3: No Line Numbers ==="
formatter3 = Obelisk::HTMLFormatter.new(
  with_classes: true,
  with_line_numbers: false,
  highlight_lines: Set{2, 4, 8}
)

html3 = formatter3.format(lexer.tokenize(code), style)

# Write to file for testing
File.write("test_no_numbers.html", <<-HTML)
<!DOCTYPE html>
<html>
<head>
<style>
body { font-family: monospace; max-width: 800px; margin: 0 auto; padding: 20px; }
.test-container { border: 1px solid #ccc; overflow-x: auto; margin: 20px 0; }
#{css}
</style>
</head>
<body>
<h2>No Line Numbers</h2>
<div class="test-container">
#{html3}
</div>
</body>
</html>
HTML

puts "\nGenerated test files:"
puts "- test_inline_wrap.html (inline line numbers with wrapping)"
puts "- test_table_nowrap.html (table-based line numbers)"
puts "- test_no_numbers.html (no line numbers)"
puts "\nOpen these files in a browser to verify line number alignment."