require "./src/obelisk"

puts "Testing highlight pipeline step by step..."

begin
  puts "Step 1: Get lexer..."
  lexer = Obelisk::Registry.lexers.get_with_fallback("text")
  puts "✓ Got lexer: #{lexer.name}"
  
  puts "Step 2: Get formatter..."
  formatter = Obelisk::Registry.formatters.get_with_fallback("html")
  puts "✓ Got formatter: #{formatter.class}"
  
  puts "Step 3: Get style..."
  style = Obelisk::Registry.styles.get_with_fallback("github")
  puts "✓ Got style: #{style.name}"
  
  puts "Step 4: Tokenize..."
  tokens = lexer.tokenize("hello world")
  puts "✓ Created token iterator"
  
  puts "Step 5: Get first token..."
  first_token = tokens.next
  puts "✓ Got first token: #{first_token}"
  
  puts "Step 6: Convert to array..."
  fresh_tokens = lexer.tokenize("hello world").to_a
  puts "✓ Converted to array: #{fresh_tokens.size} tokens"
  
  puts "Step 7: Apply coalescing..."
  coalesced = Obelisk::CoalescingIterator.wrap(lexer.tokenize("hello world"))
  coalesced_tokens = coalesced.to_a
  puts "✓ Coalesced tokens: #{coalesced_tokens.size} tokens"
  
  puts "Step 8: Format..."
  formatted = formatter.format(lexer.tokenize("hello world"), style)
  puts "✓ Formatted: #{formatted.size} characters"
  
rescue ex
  puts "✗ ERROR: #{ex.message}"
  puts "Backtrace:"
  ex.backtrace.each { |line| puts "  #{line}" }
end