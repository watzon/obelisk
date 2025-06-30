require "./src/obelisk"

# Minimal test to isolate the exact crash in delegation
puts "Minimal delegating lexer test..."

# Simple base lexer
class SimpleLexer < Obelisk::RegexLexer
  def config : Obelisk::LexerConfig
    Obelisk::LexerConfig.new(name: "simple")
  end

  def rules : Hash(String, Array(Obelisk::LexerRule))
    {
      "root" => [
        Obelisk::LexerRule.new(/\w+/, Obelisk::TokenType::Name),
        Obelisk::LexerRule.new(/\s+/, Obelisk::TokenType::Text),
        Obelisk::LexerRule.new(/./, Obelisk::TokenType::Text),
      ]
    }
  end
end

# Simple delegating lexer
class SimpleDelegatingLexer < Obelisk::DelegatingLexer
  def config : Obelisk::LexerConfig
    Obelisk::LexerConfig.new(name: "simple-delegating")
  end

  def base_lexer : Obelisk::RegexLexer
    SimpleLexer.new
  end
end

begin
  puts "Creating simple delegating lexer..."
  delegating = SimpleDelegatingLexer.new
  
  puts "Testing with empty text..."
  tokens = delegating.tokenize("").to_a
  puts "✓ Empty text: #{tokens.size} tokens"
  
  puts "Testing with simple text..."
  tokens = delegating.tokenize("hello world").to_a
  puts "✓ Simple text: #{tokens.size} tokens"
  
  puts "Testing step by step..."
  iter = delegating.tokenize("hello")
  puts "Created iterator"
  
  token1 = iter.next
  puts "Got token 1: #{token1}"
  
  token2 = iter.next 
  puts "Got token 2: #{token2}"
  
  token3 = iter.next
  puts "Got token 3: #{token3}"
  
rescue ex
  puts "ERROR: #{ex.message}"
  puts "Backtrace:"
  ex.backtrace.each { |line| puts "  #{line}" }
end