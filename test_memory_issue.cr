require "./src/obelisk"

# Minimal reproduction test for memory access violation
puts "Testing memory issue..."

# Create a simple text lexer
lexer = Obelisk::PlainTextLexer.new
puts "Created lexer: #{lexer.name}"

# Test 1: Basic tokenization
puts "\nTest 1: Basic tokenization"
begin
  tokens = lexer.tokenize("hello world")
  puts "Created token iterator"
  
  # This should work
  first_token = tokens.next
  puts "Got first token: #{first_token}"
  
  # Try to_a which triggers the memory issue
  puts "Attempting to_a conversion..."
  all_tokens = lexer.tokenize("test").to_a
  puts "Success: Got #{all_tokens.size} tokens"
rescue ex
  puts "ERROR: #{ex.message}"
  puts "Backtrace:"
  ex.backtrace.each { |line| puts "  #{line}" }
end

# Test 2: RegexTokenIterator with simple lexer
puts "\nTest 2: Testing with Crystal lexer (uses RegexTokenIterator)"
begin
  crystal_lexer = Obelisk::Lexers::Crystal.new
  puts "Created Crystal lexer"
  
  # Simple Crystal code
  code = "puts \"hello\""
  tokens = crystal_lexer.tokenize(code)
  puts "Created token iterator for Crystal code"
  
  # Try to iterate manually
  count = 0
  loop do
    token = tokens.next
    break if token.is_a?(Iterator::Stop)
    count += 1
    puts "Token #{count}: #{token.type} - '#{token.value}'"
    break if count > 10  # Safety limit
  end
  
  puts "Manual iteration successful, got #{count} tokens"
  
  # Now try to_a which should trigger the memory issue
  puts "Attempting to_a on fresh iterator..."
  all_tokens = crystal_lexer.tokenize(code).to_a
  puts "Success: Got #{all_tokens.size} tokens via to_a"
  
rescue ex
  puts "ERROR: #{ex.message}"
  puts "Backtrace:"
  ex.backtrace.each { |line| puts "  #{line}" }
end

puts "\nTest completed."