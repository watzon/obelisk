require "./src/obelisk"

# Test the composition functionality that was disabled
puts "Testing composition functionality..."

begin
  # Test basic composed lexer
  puts "Creating composed lexer..."
  lexers = [Obelisk::PlainTextLexer.new, Obelisk::Lexers::Crystal.new]
  composed = Obelisk::ComposedLexer.new("test-composed", lexers)
  puts "✓ Created composed lexer"
  
  # Test tokenization
  puts "Testing basic tokenization..."
  tokens = composed.tokenize("hello world").to_a
  puts "✓ Basic tokenization: #{tokens.size} tokens"
  
  # Test merging iterator
  puts "Testing merging iterator..."
  merging = Obelisk::MergingTokenIterator.new([
    Obelisk::PlainTextLexer.new.tokenize("hello"),
    Obelisk::Lexers::Crystal.new.tokenize("world")
  ])
  
  merged_tokens = merging.to_a
  puts "✓ Merging iterator: #{merged_tokens.size} tokens"
  
  # Test layered iterator
  puts "Testing layered iterator..."
  layered = Obelisk::LayeredTokenIterator.new([
    Obelisk::PlainTextLexer.new.tokenize("hello"),
    Obelisk::Lexers::Crystal.new.tokenize("world")
  ])
  
  layered_tokens = layered.to_a
  puts "✓ Layered iterator: #{layered_tokens.size} tokens"
  
  # Test chained lexer
  puts "Testing chained lexer..."
  chained = Obelisk::ChainedLexer.new("test-chained", [
    Obelisk::PlainTextLexer.new,
    Obelisk::Lexers::Crystal.new
  ])
  
  chained_tokens = chained.tokenize("hello").to_a
  puts "✓ Chained lexer: #{chained_tokens.size} tokens"
  
  puts "\n✅ All composition tests passed!"
  
rescue ex
  puts "✗ ERROR: #{ex.message}"
  puts "Backtrace:"
  ex.backtrace.each { |line| puts "  #{line}" }
end