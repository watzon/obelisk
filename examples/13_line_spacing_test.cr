require "../src/obelisk"

# Test for line spacing and formatting issues
code = <<-'CODE'
class Test
  def hello
    puts "Hello"
  end
end
CODE

lexer = Obelisk::Registry.lexers.get!("crystal")
style = Obelisk::Registry.styles.get!("github")

# Test with line numbers and highlighting
formatter = Obelisk::HTMLFormatter.new(
  with_classes: true,
  with_line_numbers: true,
  standalone: true,
  highlight_lines: Set{2, 3}
)

html = formatter.format(lexer.tokenize(code), style)
File.write("line_spacing_test.html", html)

puts "Generated line_spacing_test.html to test:"
puts "1. No extra line at beginning"
puts "2. Compact width (not full page)"
puts "3. Tight line spacing"
puts "4. Proper line highlighting"
