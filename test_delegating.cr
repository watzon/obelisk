require "./src/obelisk"

puts "Testing delegating lexer..."

# Simple test lexer for testing delegation
class TestMarkdownLexer < Obelisk::DelegatingLexer
  def config : Obelisk::LexerConfig
    Obelisk::LexerConfig.new(
      name: "test-markdown",
      aliases: ["testmd"],
      filenames: ["*.testmd"]
    )
  end

  def base_lexer : Obelisk::RegexLexer
    TestMarkdownBaseLexer.new
  end
end

# Base lexer for markdown (handles non-code content)
class TestMarkdownBaseLexer < Obelisk::RegexLexer
  def config : Obelisk::LexerConfig
    Obelisk::LexerConfig.new(
      name: "test-markdown-base",
      aliases: ["testmd-base"]
    )
  end

  def rules : Hash(String, Array(Obelisk::LexerRule))
    {
      "root" => [
        Obelisk::LexerRule.new(/^#[^\n]*/, Obelisk::TokenType::GenericHeading),
        Obelisk::LexerRule.new(/\*\*.*?\*\*/, Obelisk::TokenType::GenericStrong),
        Obelisk::LexerRule.new(/\*.*?\*/, Obelisk::TokenType::GenericEmph),
        Obelisk::LexerRule.new(/[^\n]+/, Obelisk::TokenType::Text),
        Obelisk::LexerRule.new(/\n/, Obelisk::TokenType::Text),
      ]
    }
  end
end

# Test delegating lexer basic functionality
begin
  puts "Creating delegating lexer..."
  markdown = TestMarkdownLexer.new
  puts "✓ Created successfully"
  
  # Add a detector for Crystal code blocks
  puts "Getting crystal lexer..."
  crystal_lexer = Obelisk::Registry.lexers.get("crystal")
  if crystal_lexer.nil?
    puts "✗ Could not get crystal lexer"
    exit 1
  end
  puts "✓ Got crystal lexer: #{crystal_lexer.name}"
  
  puts "Creating detector..."
  detector = Obelisk::EmbeddedLanguageHelpers.code_block_detector("crystal", crystal_lexer)
  puts "✓ Created detector"
  
  puts "Adding detector to markdown lexer..."
  markdown.add_region_detector(detector)
  puts "✓ Added detector"
  
  text = <<-TEXT
    # Header
    
    ```crystal
    def test
      puts "hello"
    end
    ```
    TEXT
  
  puts "Testing basic tokenization..."
  tokens_iter = markdown.tokenize(text)
  puts "✓ Created token iterator"
  
  puts "Getting first token manually..."
  first_token = tokens_iter.next
  puts "✓ Got first token: #{first_token}"
  
  puts "Testing to_a conversion (this might fail)..."
  fresh_iter = markdown.tokenize(text)
  tokens = fresh_iter.to_a
  puts "✓ to_a successful: Got #{tokens.size} tokens"
  
  # Print some tokens for verification
  puts "\nFirst 10 tokens:"
  tokens.first(10).each_with_index do |token, i|
    puts "  #{i+1}: #{token.type} - '#{token.value.inspect}'"
  end
  
rescue ex
  puts "✗ ERROR: #{ex.message}"
  puts "Backtrace:"
  ex.backtrace.each { |line| puts "  #{line}" }
end

puts "\nDelegating lexer test completed."