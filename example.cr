require "./src/obelisk"

# Simple demonstration of the Obelisk syntax highlighting library

# 1. Basic usage with the plain text lexer
puts "=== Basic Plain Text Highlighting ==="
simple_text = "Hello, world!"
result = Obelisk.highlight(simple_text, "text", "html", "github")
puts result

puts "\n=== Available Components ==="
puts "Lexers: #{Obelisk.lexer_names.join(", ")}"
puts "Formatters: #{Obelisk.formatter_names.join(", ")}"
puts "Styles: #{Obelisk.style_names.join(", ")}"

puts "\n=== Token System Demo ==="
# Show token types and CSS classes
tokens = [
  Obelisk::TokenType::Keyword,
  Obelisk::TokenType::NameFunction,
  Obelisk::TokenType::LiteralString,
  Obelisk::TokenType::Comment,
]

tokens.each do |token_type|
  puts "#{token_type} -> CSS class: '#{token_type.css_class}'"
end

puts "\n=== Style System Demo ==="
# Show different styles
["github", "monokai", "bw"].each do |style_name|
  style = Obelisk.style(style_name)
  if style
    puts "Style '#{style_name}': background = #{style.background.to_hex}"
    keyword_entry = style.get(Obelisk::TokenType::Keyword)
    puts "  Keyword color: #{keyword_entry.color.try(&.to_hex) || "none"}"
  end
end

puts "\n=== Manual Token Creation ==="
# Create some tokens manually and format them
manual_tokens = [
  Obelisk::Token.new(Obelisk::TokenType::Keyword, "def"),
  Obelisk::Token.new(Obelisk::TokenType::Text, " "),
  Obelisk::Token.new(Obelisk::TokenType::NameFunction, "hello"),
  Obelisk::Token.new(Obelisk::TokenType::Punctuation, "("),
  Obelisk::Token.new(Obelisk::TokenType::Name, "name"),
  Obelisk::Token.new(Obelisk::TokenType::Punctuation, ")"),
  Obelisk::Token.new(Obelisk::TokenType::Text, "\n  "),
  Obelisk::Token.new(Obelisk::TokenType::LiteralString, "\"Hello\""),
  Obelisk::Token.new(Obelisk::TokenType::Text, "\n"),
  Obelisk::Token.new(Obelisk::TokenType::Keyword, "end"),
]

# Convert to iterator
token_iterator = manual_tokens.each

# Format with HTML
html_formatter = Obelisk::HTMLFormatter.new(with_classes: true)
github_style = Obelisk::Registry.styles.get!("github")

html_output = html_formatter.format(token_iterator, github_style)
puts "HTML output:"
puts html_output

# Format with ANSI
puts "\n=== ANSI Terminal Output ==="
ansi_formatter = Obelisk::ANSIFormatter.new
ansi_output = ansi_formatter.format(manual_tokens.each, github_style)
puts "ANSI output:"
puts ansi_output

puts "\n=== CSS Generation ==="
css = html_formatter.css(github_style)
puts "Generated CSS:"
puts css
