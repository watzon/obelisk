require "./src/obelisk"

# Comprehensive test to identify memory issue patterns
puts "Running comprehensive memory tests..."

def test_lexer(lexer : Obelisk::Lexer, name : String, test_cases : Array(String))
  puts "\n=== Testing #{name} lexer ==="
  
  test_cases.each_with_index do |test_case, i|
    puts "\nTest case #{i + 1}: #{test_case[0...50]}..."
    
    begin
      # Test basic iteration
      tokens = lexer.tokenize(test_case)
      first_result = tokens.next
      puts "  ✓ Basic iteration successful: #{first_result}"
      
      # Test manual complete iteration
      count = 0
      fresh_tokens = lexer.tokenize(test_case)
      loop do
        result = fresh_tokens.next
        break if result.is_a?(Iterator::Stop)
        count += 1
        # Safety limit to prevent infinite loops
        if count > 1000
          puts "  ⚠ Hit safety limit at #{count} tokens"
          break
        end
      end
      puts "  ✓ Manual iteration: #{count} tokens"
      
      # Test to_a (this often triggers memory issues)
      all_tokens = lexer.tokenize(test_case).to_a
      puts "  ✓ to_a conversion: #{all_tokens.size} tokens"
      
      # Test multiple iterators
      iter1 = lexer.tokenize(test_case)
      iter2 = lexer.tokenize(test_case)
      iter1.next
      iter2.next
      puts "  ✓ Multiple iterators: OK"
      
      # Test GC pressure
      10.times { lexer.tokenize(test_case).to_a }
      GC.collect
      puts "  ✓ GC pressure test: OK"
      
    rescue ex
      puts "  ✗ ERROR: #{ex.message}"
      puts "  Backtrace (first 5 lines):"
      ex.backtrace.first(5).each { |line| puts "    #{line}" }
    end
  end
end

# Test cases that might trigger different code paths
basic_cases = [
  "",
  "a",
  "hello world",
  "x" * 1000,  # Large simple string
]

crystal_cases = [
  "puts \"hello\"",
  "class Foo\n  def bar\n    42\n  end\nend",
  "# comment\nrequire \"foo\"\nmodule Bar\nend",
  "\"string with \#{interpolation} here\"",
  "@instance_var = 123\n@@class_var = \"test\"",
  "def complex_method(x : Int32, y : String = \"default\") : Bool\n  x > 0 && !y.empty?\nend",
  "macro generate_method(name)\n  def {{name}}\n    puts \"{{name}}\"\n  end\nend",
  ":symbol_literal",
  ":\"symbol with spaces\"",
  "/regex.*pattern/imx",
  "0x1234_5678_u64",
  "3.14159_f32",
  "<<-EOF\nheredoc content\nEOF",
]

# Test with different lexers
lexers = [
  {Obelisk::PlainTextLexer.new, "PlainText"},
  {Obelisk::Lexers::Crystal.new, "Crystal"},
  {Obelisk::Lexers::JSON.new, "JSON"},
]

# Run tests
lexers.each do |lexer, name|
  case name
  when "PlainText"
    test_lexer(lexer, name, basic_cases)
  when "Crystal"
    test_lexer(lexer, name, basic_cases + crystal_cases)
  when "JSON"
    json_cases = [
      "{}",
      "{\"key\": \"value\"}",
      "[1, 2, 3, true, false, null]",
      "{\"nested\": {\"array\": [1, 2, {\"deep\": true}]}}",
    ]
    test_lexer(lexer, name, basic_cases + json_cases)
  end
end

# Test edge cases that might cause memory issues
puts "\n=== Testing Edge Cases ==="

# Test with uninitialized or corrupted state
puts "\nTesting potential state corruption..."
begin
  lexer = Obelisk::Lexers::Crystal.new
  tokens = lexer.tokenize("puts \"test\"")
  
  # Get some tokens
  token1 = tokens.next
  token2 = tokens.next
  
  # Try to continue after some tokens
  remaining = tokens.to_a
  puts "✓ Partial consumption then to_a: OK"
rescue ex
  puts "✗ Partial consumption issue: #{ex.message}"
end

# Test concurrent access (potential race condition)
puts "\nTesting concurrent access patterns..."
begin
  lexer = Obelisk::Lexers::Crystal.new
  text = "puts \"hello\""
  
  # Create multiple iterators and interleave their usage
  iterators = Array.new(5) { lexer.tokenize(text) }
  
  # Interleave token consumption
  results = [] of Array(Obelisk::Token)
  iterators.each do |iter|
    results << iter.to_a
  end
  
  puts "✓ Multiple iterators: All completed successfully"
  results.each_with_index do |tokens, i|
    puts "  Iterator #{i}: #{tokens.size} tokens"
  end
rescue ex
  puts "✗ Concurrent access issue: #{ex.message}"
end

puts "\nComprehensive test completed."