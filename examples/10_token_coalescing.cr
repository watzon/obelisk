require "../src/obelisk"

# Example 10: Token Coalescing Performance
# This example demonstrates how token coalescing improves performance
# by merging consecutive tokens of the same type

# Code with many whitespace and punctuation tokens
code = %q(
def fibonacci(n : Int32) : Int32
  return n if n <= 1

  # Initialize array for memoization
  fib = Array(Int32).new(n + 1, 0)
  fib[0] = 0
  fib[1] = 1

  # Calculate fibonacci numbers
  (2..n).each do |i|
    fib[i] = fib[i - 1] + fib[i - 2]
  end

  fib[n]
end

# Test the function
puts "Fibonacci sequence:"
(0..10).each do |i|
  puts "F(#{i}) = #{fibonacci(i)}"
end
)

# First, let's see how many tokens are generated without coalescing
lexer = Obelisk.lexer("crystal")
tokens_without_coalescing = nil
if lexer
  tokens_without_coalescing = lexer.tokenize(code).to_a
  puts "Without coalescing: #{tokens_without_coalescing.size} tokens"

  # Count consecutive tokens of same type
  consecutive_count = 0
  prev_type = nil
  tokens_without_coalescing.each do |token|
    if token.type == prev_type
      consecutive_count += 1
    end
    prev_type = token.type
  end
  puts "Consecutive tokens of same type: #{consecutive_count}"
end

puts "\n=== Highlighting WITH Token Coalescing (default) ==="
start_time = Time.monotonic
options = Obelisk::Quick::HighlightOptions.new(coalesce_tokens: true)
html_coalesced = Obelisk::Quick.highlight(code, "crystal", "html", "github", options)
coalesce_time = Time.monotonic - start_time
puts "Time with coalescing: #{coalesce_time.total_milliseconds.round(2)}ms"
puts "Output size: #{html_coalesced.size} bytes"

puts "\n=== Highlighting WITHOUT Token Coalescing ==="
start_time = Time.monotonic
options_no_coalesce = Obelisk::Quick::HighlightOptions.new(coalesce_tokens: false)
html_no_coalesce = Obelisk::Quick.highlight(code, "crystal", "html", "github", options_no_coalesce)
no_coalesce_time = Time.monotonic - start_time
puts "Time without coalescing: #{no_coalesce_time.total_milliseconds.round(2)}ms"
puts "Output size: #{html_no_coalesce.size} bytes"

# Show the difference
puts "\n=== Performance Comparison ==="
time_improvement = ((no_coalesce_time - coalesce_time) / no_coalesce_time * 100).round(2)
puts "Performance improvement: #{time_improvement}%"

# Demonstrate with coalescing iterator directly
puts "\n=== Direct Coalescing Iterator Usage ==="
if lexer && tokens_without_coalescing
  tokens = lexer.tokenize(code)
  coalesced_tokens = Obelisk::CoalescingIterator.wrap(tokens).to_a
  puts "After coalescing: #{coalesced_tokens.size} tokens"
  reduction = ((tokens_without_coalescing.size - coalesced_tokens.size).to_f / tokens_without_coalescing.size * 100).round(2)
  puts "Token count reduction: #{reduction}%"

  # Show some examples of coalesced tokens
  puts "\nExamples of coalesced tokens:"
  coalesced_tokens.select { |t| t.value.size > 2 && t.type == Obelisk::TokenType::TextWhitespace }.first(3).each do |token|
    puts "  - #{token.type}: #{token.value.inspect} (#{token.value.size} chars)"
  end
end

# Custom max token size
puts "\n=== Custom Token Size Limit ==="
options_small = Obelisk::Quick::HighlightOptions.new(coalesce_tokens: true, max_token_size: 10)
if lexer
  tokens = lexer.tokenize(code)
  small_coalesced = Obelisk::CoalescingIterator.wrap(tokens, 10).to_a
  puts "With 10-char limit: #{small_coalesced.size} tokens"
end
