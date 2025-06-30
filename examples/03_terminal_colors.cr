require "../src/obelisk"

# Example 03: Terminal Colors (ANSI)
# This example shows how to output syntax-highlighted code to the terminal

code = %q(
# Example: Fibonacci sequence generator
def fibonacci(n : Int32) : Array(Int64)
  return [] of Int64 if n <= 0
  return [0_i64] if n == 1
  
  sequence = [0_i64, 1_i64]
  
  (2...n).each do |i|
    sequence << sequence[i-1] + sequence[i-2]
  end
  
  sequence
end

# Generate first 10 Fibonacci numbers
puts "First 10 Fibonacci numbers:"
fibonacci(10).each_with_index do |num, index|
  puts "F(#{index}) = #{num}"
end
)

puts "=== Terminal Output with GitHub Style ==="
# Use the terminal formatter for colored output in the console
ansi_github = Obelisk.highlight(code, "crystal", "terminal", "github")
puts ansi_github

puts "\n=== Terminal Output with Monokai Style ==="
# Different style for dark terminals
ansi_monokai = Obelisk.highlight(code, "crystal", "terminal", "monokai")
puts ansi_monokai

puts "\n=== Terminal Output with Black & White Style ==="
# Minimal style for terminals without color support
ansi_bw = Obelisk.highlight(code, "crystal", "terminal", "bw")
puts ansi_bw

puts "\n=== Custom Terminal Formatting ==="
# Create custom ANSI formatter with specific settings
formatter = Obelisk::ANSIFormatter.new
lexer = Obelisk.lexer("crystal")
style = Obelisk.style("monokai")

if lexer && style
  tokens = lexer.tokenize(code)
  custom_ansi = formatter.format(tokens, style)
  puts custom_ansi
end

# Demonstrate terminal colors for different token types
puts "\n=== Token Type Color Examples ==="
sample_tokens = [
  Obelisk::Token.new(Obelisk::TokenType::Keyword, "def"),
  Obelisk::Token.new(Obelisk::TokenType::NameFunction, "fibonacci"),
  Obelisk::Token.new(Obelisk::TokenType::LiteralNumberInteger, "42"),
  Obelisk::Token.new(Obelisk::TokenType::LiteralString, "\"Hello\""),
  Obelisk::Token.new(Obelisk::TokenType::Comment, "# Comment"),
  Obelisk::Token.new(Obelisk::TokenType::NameClass, "MyClass"),
  Obelisk::Token.new(Obelisk::TokenType::Operator, "+="),
]

formatter = Obelisk::ANSIFormatter.new
monokai_style = Obelisk::Registry.styles.get!("monokai")

puts "Monokai theme colors:"
sample_tokens.each do |token|
  colored = formatter.format([token].each, monokai_style)
  puts "  #{token.type}: #{colored.strip} (raw: #{token.value})"
end