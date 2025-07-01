require "./spec_helper"

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

describe Obelisk::DelegatingLexer do
  describe "region detection" do
    it "detects embedded regions" do
      markdown = TestMarkdownLexer.new
      
      # Add a detector for Crystal code blocks
      crystal_lexer = Obelisk::Registry.lexers.get("crystal").not_nil!
      detector = Obelisk::EmbeddedLanguageHelpers.code_block_detector("crystal", crystal_lexer)
      markdown.add_region_detector(detector)
      
      text = <<-TEXT
        # Test Document
        
        Some regular text.
        
        ```crystal
        def hello
          puts "Hello, World!"
        end
        ```
        
        More regular text.
        TEXT
      
      state = Obelisk::LexerState.new(text)
      regions = markdown.detect_all_regions(text, state)
      
      regions.size.should eq(1)
      region = regions[0]
      
      content = region.content(text)
      content.should contain("def hello")
      content.should contain("puts \"Hello, World!\"")
      content.should_not contain("```")
    end
  end

  describe "delegation" do
    pending "delegates to embedded lexers # FIXME: This test triggers debugger breakpoint" do
      markdown = TestMarkdownLexer.new
      
      # Add a detector for Crystal code blocks
      crystal_lexer = Obelisk::Registry.lexers.get("crystal").not_nil!
      detector = Obelisk::EmbeddedLanguageHelpers.code_block_detector("crystal", crystal_lexer)
      markdown.add_region_detector(detector)
      
      text = <<-TEXT
        # Header
        
        ```crystal
        def test
          puts "hello"
        end
        ```
        TEXT
      
      tokens = markdown.tokenize(text).to_a
      
      # Should have tokens from both markdown and crystal lexers
      heading_tokens = tokens.select(&.type.== Obelisk::TokenType::GenericHeading)
      heading_tokens.size.should be >= 1
      
      # Should have crystal tokens
      keyword_tokens = tokens.select(&.type.== Obelisk::TokenType::Keyword)
      keyword_tokens.size.should be >= 1
      
      # Should have delimiter tokens
      punctuation_tokens = tokens.select(&.type.== Obelisk::TokenType::Punctuation)
      punctuation_tokens.size.should be >= 2 # ```crystal and ```
    end
  end
end

describe Obelisk::EmbeddedLanguageHelpers do
  describe "code block detector" do
    it "creates detectors for code blocks" do
      lexer = Obelisk::PlainTextLexer.new
      detector = Obelisk::EmbeddedLanguageHelpers.code_block_detector("ruby", lexer)
      
      text = <<-TEXT
        Some text
        
        ```ruby
        puts "hello"
        ```
        
        More text
        TEXT
      
      state = Obelisk::LexerState.new(text)
      regions = detector.detect_regions(text, state)
      
      regions.size.should eq(1)
      region = regions[0]
      
      content = region.content(text)
      content.should eq("puts \"hello\"\n")
    end
  end

  describe "template expression detector" do
    it "creates detectors for template expressions" do
      lexer = Obelisk::PlainTextLexer.new
      detector = Obelisk::EmbeddedLanguageHelpers.template_expression_detector("{{", "}}", lexer)
      
      text = "Hello {{ name }}, welcome to {{ site }}!"
      
      state = Obelisk::LexerState.new(text)
      regions = detector.detect_regions(text, state)
      
      regions.size.should eq(2)
      
      regions[0].content(text).should eq(" name ")
      regions[1].content(text).should eq(" site ")
    end
  end

  describe "tag-based detector" do
    it "creates detectors for tag-based embedding" do
      lexer = Obelisk::PlainTextLexer.new
      detector = Obelisk::EmbeddedLanguageHelpers.tag_based_detector("script", lexer)
      
      text = <<-HTML
        <div>
          <script>
            console.log("hello");
          </script>
        </div>
        HTML
      
      state = Obelisk::LexerState.new(text)
      regions = detector.detect_regions(text, state)
      
      regions.size.should eq(1)
      region = regions[0]
      
      content = region.content(text).strip
      content.should eq("console.log(\"hello\");")
    end
  end
end