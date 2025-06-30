require "./src/obelisk"

puts "Testing basic highlight functionality..."

begin
  puts "Testing with text lexer..."
  result = Obelisk.highlight("hello world", "text")
  puts "✓ Text highlight successful: #{result.size} characters"
  
  puts "Testing with Crystal lexer..."
  result = Obelisk.highlight("puts 'hello'", "crystal")
  puts "✓ Crystal highlight successful: #{result.size} characters"
  
  puts "Testing with JSON lexer..."
  result = Obelisk.highlight("{\"key\": \"value\"}", "json")
  puts "✓ JSON highlight successful: #{result.size} characters"
  
rescue ex
  puts "✗ ERROR: #{ex.message}"
  puts "Backtrace:"
  ex.backtrace.each { |line| puts "  #{line}" }
end