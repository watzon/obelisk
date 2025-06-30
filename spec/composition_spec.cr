require "./spec_helper"

# Test lexers for composition testing
class TestLexerA < Obelisk::RegexLexer
  def config : Obelisk::LexerConfig
    Obelisk::LexerConfig.new(
      name: "test-a",
      aliases: ["testa"],
      filenames: ["*.ta"]
    )
  end

  def rules : Hash(String, Array(Obelisk::LexerRule))
    {
      "root" => [
        Obelisk::LexerRule.new(/foo/, Obelisk::TokenType::Keyword),
        Obelisk::LexerRule.new(/\w+/, Obelisk::TokenType::Name),
        Obelisk::LexerRule.new(/\s+/, Obelisk::TokenType::Text),
      ]
    }
  end

  def analyze(text : String) : Float32
    text.includes?("foo") ? 0.8f32 : 0.1f32
  end
end

class TestLexerB < Obelisk::RegexLexer
  def config : Obelisk::LexerConfig
    Obelisk::LexerConfig.new(
      name: "test-b", 
      aliases: ["testb"],
      filenames: ["*.tb"]
    )
  end

  def rules : Hash(String, Array(Obelisk::LexerRule))
    {
      "root" => [
        Obelisk::LexerRule.new(/bar/, Obelisk::TokenType::Keyword),
        Obelisk::LexerRule.new(/\w+/, Obelisk::TokenType::Name),
        Obelisk::LexerRule.new(/\s+/, Obelisk::TokenType::Text),
      ]
    }
  end

  def analyze(text : String) : Float32
    text.includes?("bar") ? 0.9f32 : 0.1f32
  end
end

class TestLexerC < Obelisk::RegexLexer
  def config : Obelisk::LexerConfig
    Obelisk::LexerConfig.new(
      name: "test-c",
      aliases: ["testc"],
      filenames: ["*.tc"]
    )
  end

  def rules : Hash(String, Array(Obelisk::LexerRule))
    {
      "root" => [
        Obelisk::LexerRule.new(/baz/, Obelisk::TokenType::Keyword),
        Obelisk::LexerRule.new(/\w+/, Obelisk::TokenType::Name),
        Obelisk::LexerRule.new(/\s+/, Obelisk::TokenType::Text),
      ]
    }
  end

  def analyze(text : String) : Float32
    text.includes?("baz") ? 0.7f32 : 0.1f32
  end
end

describe Obelisk::ComposedLexer do
  describe "FirstMatch strategy" do
    it "uses first lexer with high confidence" do
      lexer_a = TestLexerA.new
      lexer_b = TestLexerB.new
      lexers = [lexer_a, lexer_b] of Obelisk::Lexer
      composed = Obelisk::ComposedLexer.new("composed", lexers, Obelisk::CompositionStrategy::FirstMatch)
      
      # Text that both lexers can handle, but A comes first
      text = "foo bar hello"
      tokens = composed.tokenize(text).to_a
      
      # Should use lexer A (first with high confidence)
      keyword_tokens = tokens.select(&.type.== Obelisk::TokenType::Keyword)
      keyword_tokens.size.should eq(1)
      keyword_tokens[0].value.should eq("foo")
    end
    
    it "falls back to second lexer if first has low confidence" do
      lexer_a = TestLexerA.new
      lexer_b = TestLexerB.new
      lexers = [lexer_a, lexer_b] of Obelisk::Lexer
      composed = Obelisk::ComposedLexer.new("composed", lexers, Obelisk::CompositionStrategy::FirstMatch)
      
      # Text that only lexer B can handle well
      text = "bar hello world"
      tokens = composed.tokenize(text).to_a
      
      # Should use lexer B
      keyword_tokens = tokens.select(&.type.== Obelisk::TokenType::Keyword)
      keyword_tokens.size.should eq(1)
      keyword_tokens[0].value.should eq("bar")
    end
  end

  describe "HighestConfidence strategy" do
    it "selects lexer with highest confidence score" do
      lexer_a = TestLexerA.new  # 0.8 confidence for "foo"
      lexer_b = TestLexerB.new  # 0.9 confidence for "bar"
      lexer_c = TestLexerC.new  # 0.7 confidence for "baz"
      
      lexers = [lexer_a, lexer_b, lexer_c] of Obelisk::Lexer
      composed = Obelisk::ComposedLexer.new("composed", lexers, Obelisk::CompositionStrategy::HighestConfidence)
      
      # Text with all keywords - lexer B should win with 0.9 confidence
      text = "foo bar baz"
      
      composed.analyze(text).should eq(0.9f32)
      
      tokens = composed.tokenize(text).to_a
      keyword_tokens = tokens.select(&.type.== Obelisk::TokenType::Keyword)
      keyword_tokens.size.should eq(1)
      keyword_tokens[0].value.should eq("bar")
    end
  end

  describe "configuration combining" do
    it "combines aliases, filenames, and mime types from all lexers" do
      lexer_a = TestLexerA.new
      lexer_b = TestLexerB.new
      lexers = [lexer_a, lexer_b] of Obelisk::Lexer
      composed = Obelisk::ComposedLexer.new("composed", lexers)
      
      config = composed.config
      config.name.should eq("composed")
      config.aliases.should contain("testa")
      config.aliases.should contain("testb")
      config.filenames.should contain("*.ta")
      config.filenames.should contain("*.tb")
    end
  end
end

describe Obelisk::ChainedLexer do
  describe "sequential processing" do
    it "processes text through multiple lexers in sequence" do
      lexer_a = TestLexerA.new
      lexer_b = TestLexerB.new
      lexers = [lexer_a, lexer_b] of Obelisk::Lexer
      chained = Obelisk::ChainedLexer.new("chained", lexers)
      
      text = "foo"
      
      # Chain analysis should multiply confidences
      confidence = chained.analyze(text)
      # lexer_a: 0.8, lexer_b: 0.1 -> 0.8 * 0.1 = 0.08
      confidence.should be_close(0.08f32, 0.01f32)
    end
    
    it "stops chain analysis at zero confidence" do
      lexer_a = TestLexerA.new
      lexer_b = TestLexerB.new
      lexers = [lexer_a, lexer_b] of Obelisk::Lexer
      chained = Obelisk::ChainedLexer.new("chained", lexers)
      
      # Text that neither lexer handles well
      text = "xyz"
      confidence = chained.analyze(text)
      
      # Should be very low or zero
      confidence.should be < 0.2f32
    end
  end

  describe "configuration" do
    it "uses last lexer's configuration" do
      lexer_a = TestLexerA.new
      lexer_b = TestLexerB.new
      lexers = [lexer_a, lexer_b] of Obelisk::Lexer
      chained = Obelisk::ChainedLexer.new("chained", lexers)
      
      config = chained.config
      config.name.should eq("chained")
      config.filenames.should eq(["*.tb"])  # From lexer B (last in chain)
    end
  end
end

describe Obelisk::LexerComposition do
  describe "helper methods" do
    it "creates fallback lexer" do
      lexer_a = TestLexerA.new
      lexer_b = TestLexerB.new
      lexers = [lexer_a, lexer_b] of Obelisk::Lexer
      fallback = Obelisk::LexerComposition.fallback("fallback", lexers)
      
      fallback.should be_a(Obelisk::ComposedLexer)
      # Should use FirstMatch strategy
      text = "bar"
      tokens = fallback.tokenize(text).to_a
      
      keyword_tokens = tokens.select(&.type.== Obelisk::TokenType::Keyword)
      keyword_tokens.size.should eq(1)
      keyword_tokens[0].value.should eq("bar")
    end
    
    it "creates best_match lexer" do
      lexer_a = TestLexerA.new
      lexer_b = TestLexerB.new
      lexers = [lexer_a, lexer_b] of Obelisk::Lexer
      best_match = Obelisk::LexerComposition.best_match("best", lexers)
      
      best_match.should be_a(Obelisk::ComposedLexer)
      
      # Should select lexer with highest confidence
      text = "foo bar"  # Both have keywords, but B has higher confidence for "bar"
      tokens = best_match.tokenize(text).to_a
      
      keyword_tokens = tokens.select(&.type.== Obelisk::TokenType::Keyword)
      keyword_tokens.size.should eq(1)
      keyword_tokens[0].value.should eq("bar")
    end
    
    it "creates chained lexer" do
      lexer_a = TestLexerA.new
      lexer_b = TestLexerB.new
      lexers = [lexer_a, lexer_b] of Obelisk::Lexer
      chained = Obelisk::LexerComposition.chain("chained", lexers)
      
      chained.should be_a(Obelisk::ChainedLexer)
      chained.config.name.should eq("chained")
    end
  end
end

describe Obelisk::MergingTokenIterator do
  describe "token merging" do
    it "merges tokens from multiple iterators" do
      lexer_a = TestLexerA.new
      lexer_b = TestLexerB.new
      
      text = "foo bar"
      iterators = [lexer_a.tokenize(text), lexer_b.tokenize(text)]
      
      merging_iterator = Obelisk::MergingTokenIterator.new(iterators)
      tokens = merging_iterator.to_a
      
      # Should have tokens from both lexers
      tokens.size.should be > 2
      
      # Should have both "foo" and "bar" as keywords
      keyword_tokens = tokens.select(&.type.== Obelisk::TokenType::Keyword)
      keyword_values = keyword_tokens.map(&.value)
      keyword_values.should contain("foo")
      keyword_values.should contain("bar")
    end
  end
end

describe Obelisk::LayeredTokenIterator do
  describe "layered processing" do
    it "processes tokens in layer priority order" do
      lexer_a = TestLexerA.new
      lexer_b = TestLexerB.new
      
      text = "foo"
      iterators = [lexer_a.tokenize(text), lexer_b.tokenize(text)]
      
      layered_iterator = Obelisk::LayeredTokenIterator.new(iterators)
      tokens = layered_iterator.to_a
      
      # Should start with tokens from first lexer
      tokens.should_not be_empty
      first_keyword = tokens.find(&.type.== Obelisk::TokenType::Keyword)
      first_keyword.should_not be_nil
      first_keyword.not_nil!.value.should eq("foo")
    end
  end
end