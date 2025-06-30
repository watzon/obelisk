require "./spec_helper"

# Test lexers with different priorities for testing selection
class HighPriorityLexer < Obelisk::RegexLexer
  def config : Obelisk::LexerConfig
    Obelisk::LexerConfig.new(
      name: "high-priority",
      aliases: ["hp"],
      filenames: ["*.hp"],
      priority: 8.0f32
    )
  end

  def rules : Hash(String, Array(Obelisk::LexerRule))
    {
      "root" => [
        Obelisk::LexerRule.new(/high/, Obelisk::TokenType::Keyword),
        Obelisk::LexerRule.new(/\w+/, Obelisk::TokenType::Name),
        Obelisk::LexerRule.new(/\s+/, Obelisk::TokenType::Text),
      ]
    }
  end

  def analyze(text : String) : Float32
    text.includes?("high") ? 0.6f32 : 0.2f32
  end
end

class MediumPriorityLexer < Obelisk::RegexLexer
  def config : Obelisk::LexerConfig
    Obelisk::LexerConfig.new(
      name: "medium-priority",
      aliases: ["mp"], 
      filenames: ["*.mp", "*.med"],
      mime_types: ["text/medium"],
      priority: 5.0f32
    )
  end

  def rules : Hash(String, Array(Obelisk::LexerRule))
    {
      "root" => [
        Obelisk::LexerRule.new(/medium/, Obelisk::TokenType::Keyword),
        Obelisk::LexerRule.new(/\w+/, Obelisk::TokenType::Name),
        Obelisk::LexerRule.new(/\s+/, Obelisk::TokenType::Text),
      ]
    }
  end

  def analyze(text : String) : Float32
    text.includes?("medium") ? 0.8f32 : 0.3f32
  end
end

class LowPriorityLexer < Obelisk::RegexLexer
  def config : Obelisk::LexerConfig
    Obelisk::LexerConfig.new(
      name: "low-priority",
      aliases: ["lp"],
      filenames: ["*.lp", "*.low"],
      mime_types: ["text/low", "text/plain"],
      priority: 2.0f32
    )
  end

  def rules : Hash(String, Array(Obelisk::LexerRule))
    {
      "root" => [
        Obelisk::LexerRule.new(/low/, Obelisk::TokenType::Keyword),
        Obelisk::LexerRule.new(/\w+/, Obelisk::TokenType::Name),
        Obelisk::LexerRule.new(/\s+/, Obelisk::TokenType::Text),
      ]
    }
  end

  def analyze(text : String) : Float32
    text.includes?("low") ? 0.9f32 : 0.1f32
  end
end

describe Obelisk::SelectionCriteria do
  describe "initialization" do
    it "uses default weights" do
      criteria = Obelisk::SelectionCriteria.new
      
      criteria.priority_weight.should eq(0.3f32)
      criteria.confidence_weight.should eq(0.4f32)
      criteria.filename_weight.should eq(0.2f32)
      criteria.mime_type_weight.should eq(0.1f32)
      criteria.content_weight.should eq(0.0f32)
      criteria.fallback_enabled.should be_true
    end
    
    it "accepts custom weights" do
      criteria = Obelisk::SelectionCriteria.new(
        priority_weight: 0.5f32,
        confidence_weight: 0.3f32,
        filename_weight: 0.1f32,
        mime_type_weight: 0.1f32
      )
      
      criteria.priority_weight.should eq(0.5f32)
      criteria.confidence_weight.should eq(0.3f32)
    end
  end
end

describe Obelisk::PriorityLexerSelector do
  describe "basic selection" do
    it "selects lexer based on weighted scores" do
      high_lexer = HighPriorityLexer.new
      medium_lexer = MediumPriorityLexer.new 
      low_lexer = LowPriorityLexer.new
      
      lexers = [high_lexer, medium_lexer, low_lexer] of Obelisk::Lexer
      selector = Obelisk::PriorityLexerSelector.new
      
      # Text that matches "low" lexer perfectly (0.9 confidence)
      # but low lexer has lowest priority
      result = selector.select(lexers, "low priority text")
      
      result.should_not be_nil
      result.not_nil!.lexer.name.should eq("low-priority")
      result.not_nil!.confidence_score.should eq(0.9f32)
    end
    
    it "factors in filename matches" do
      high_lexer = HighPriorityLexer.new
      medium_lexer = MediumPriorityLexer.new
      
      lexers = [high_lexer, medium_lexer] of Obelisk::Lexer
      selector = Obelisk::PriorityLexerSelector.new
      
      # File with extension that matches medium lexer
      result = selector.select(lexers, "hello world", "test.mp")
      
      result.should_not be_nil
      # Should prefer medium lexer due to filename match
      result.not_nil!.lexer.name.should eq("medium-priority")
      result.not_nil!.filename_score.should eq(1.0f32)
    end
    
    it "factors in MIME type matches" do
      medium_lexer = MediumPriorityLexer.new
      low_lexer = LowPriorityLexer.new
      
      lexers = [medium_lexer, low_lexer] of Obelisk::Lexer
      selector = Obelisk::PriorityLexerSelector.new
      
      # MIME type that matches medium lexer exactly
      result = selector.select(lexers, "hello world", nil, "text/medium")
      
      result.should_not be_nil
      result.not_nil!.lexer.name.should eq("medium-priority")
      result.not_nil!.mime_type_score.should eq(1.0f32)
    end
  end
  
  describe "ranked selection" do
    it "returns lexers ranked by score" do
      high_lexer = HighPriorityLexer.new
      medium_lexer = MediumPriorityLexer.new
      low_lexer = LowPriorityLexer.new
      
      lexers = [high_lexer, medium_lexer, low_lexer] of Obelisk::Lexer
      selector = Obelisk::PriorityLexerSelector.new
      
      results = selector.select_ranked(lexers, "medium priority text")
      
      results.size.should eq(3)
      # Should be ranked by total score (descending)
      results[0].total_score.should be >= results[1].total_score
      results[1].total_score.should be >= results[2].total_score
    end
    
    it "respects limit parameter" do
      high_lexer = HighPriorityLexer.new
      medium_lexer = MediumPriorityLexer.new
      low_lexer = LowPriorityLexer.new
      
      lexers = [high_lexer, medium_lexer, low_lexer] of Obelisk::Lexer
      selector = Obelisk::PriorityLexerSelector.new
      
      results = selector.select_ranked(lexers, "test text", limit: 2)
      
      results.size.should eq(2)
    end
  end
  
  describe "threshold checking" do
    it "checks if lexer meets minimum threshold" do
      high_lexer = HighPriorityLexer.new
      selector = Obelisk::PriorityLexerSelector.new
      
      # Text that gives high confidence to high_lexer
      meets_threshold = selector.meets_threshold?(high_lexer, "high priority", 0.4f32)
      meets_threshold.should be_true
      
      # Text that gives low confidence
      fails_threshold = selector.meets_threshold?(high_lexer, "unrelated", 0.4f32)
      fails_threshold.should be_false
    end
  end
  
  describe "scoring calculations" do
    it "calculates priority scores correctly" do
      high_lexer = HighPriorityLexer.new
      low_lexer = LowPriorityLexer.new
      
      lexers = [high_lexer, low_lexer] of Obelisk::Lexer
      selector = Obelisk::PriorityLexerSelector.new
      
      results = selector.select_ranked(lexers, "test")
      
      high_result = results.find(&.lexer.name.== "high-priority").not_nil!
      low_result = results.find(&.lexer.name.== "low-priority").not_nil!
      
      # High priority lexer should have higher priority score
      high_result.priority_score.should be > low_result.priority_score
    end
    
    it "handles partial filename matches" do
      medium_lexer = MediumPriorityLexer.new
      lexers = [medium_lexer] of Obelisk::Lexer
      selector = Obelisk::PriorityLexerSelector.new
      
      # File extension that partially matches (mp vs med)
      result = selector.select(lexers, "test", "file.med")
      
      result.should_not be_nil
      # Should get exact match score for .med extension
      result.not_nil!.filename_score.should eq(1.0f32)
    end
    
    it "handles partial MIME type matches" do
      low_lexer = LowPriorityLexer.new
      lexers = [low_lexer] of Obelisk::Lexer
      selector = Obelisk::PriorityLexerSelector.new
      
      # MIME type that partially matches (text/*)
      result = selector.select(lexers, "test", nil, "text/unknown")
      
      result.should_not be_nil
      # Should get partial match score for text/* family
      result.not_nil!.mime_type_score.should eq(0.4f32)
    end
  end
end

describe Obelisk::PriorityLexerRegistry do
  describe "registration and lookup" do
    it "registers lexers and aliases" do
      registry = Obelisk::PriorityLexerRegistry.new
      high_lexer = HighPriorityLexer.new
      
      registry.register(high_lexer)
      
      registry.get("high-priority").should eq(high_lexer)
      registry.get("hp").should eq(high_lexer)  # alias
      registry.get("nonexistent").should be_nil
    end
    
    it "lists all lexers and names" do
      registry = Obelisk::PriorityLexerRegistry.new
      high_lexer = HighPriorityLexer.new
      medium_lexer = MediumPriorityLexer.new
      
      registry.register(high_lexer)
      registry.register(medium_lexer)
      
      registry.all.size.should eq(2)
      registry.names.should contain("high-priority")
      registry.names.should contain("medium-priority")
    end
  end
  
  describe "priority-based selection" do
    it "selects best lexer automatically" do
      registry = Obelisk::PriorityLexerRegistry.new
      high_lexer = HighPriorityLexer.new
      medium_lexer = MediumPriorityLexer.new
      
      registry.register(high_lexer)
      registry.register(medium_lexer)
      
      result = registry.select_best("medium priority text", "test.mp")
      
      result.should_not be_nil
      result.not_nil!.lexer.name.should eq("medium-priority")
    end
    
    it "selects by name or falls back to auto" do
      registry = Obelisk::PriorityLexerRegistry.new
      high_lexer = HighPriorityLexer.new
      
      registry.register(high_lexer)
      
      # Manual selection by name
      manual_lexer = registry.select_by_name_or_auto("high-priority", "test")
      manual_lexer.should eq(high_lexer)
      
      # Auto selection when no name provided
      auto_lexer = registry.select_by_name_or_auto(nil, "high priority")
      auto_lexer.should eq(high_lexer)
    end
  end
  
  describe "candidate filtering" do
    it "filters candidates by filename" do
      registry = Obelisk::PriorityLexerRegistry.new
      high_lexer = HighPriorityLexer.new
      medium_lexer = MediumPriorityLexer.new
      
      registry.register(high_lexer)
      registry.register(medium_lexer)
      
      candidates = registry.get_candidates(filename: "test.mp")
      candidates.size.should eq(1)
      candidates[0].name.should eq("medium-priority")
    end
    
    it "filters candidates by MIME type" do
      registry = Obelisk::PriorityLexerRegistry.new
      medium_lexer = MediumPriorityLexer.new
      low_lexer = LowPriorityLexer.new
      
      registry.register(medium_lexer)
      registry.register(low_lexer)
      
      candidates = registry.get_candidates(mime_type: "text/medium")
      candidates.size.should eq(1)
      candidates[0].name.should eq("medium-priority")
    end
  end
  
  describe "threshold checking" do
    it "checks if named lexer meets threshold" do
      registry = Obelisk::PriorityLexerRegistry.new
      high_lexer = HighPriorityLexer.new
      
      registry.register(high_lexer)
      
      meets = registry.meets_threshold?("high-priority", "high confidence", 0.4f32)
      meets.should be_true
      
      fails = registry.meets_threshold?("high-priority", "low confidence", 0.8f32)
      fails.should be_false
      
      missing = registry.meets_threshold?("nonexistent", "test", 0.5f32)
      missing.should be_false
    end
  end
end

describe Obelisk::SmartLexerSelector do
  describe "strategy-based selection" do
    it "uses auto strategy by default" do
      registry = Obelisk::PriorityLexerRegistry.new
      fallback = Obelisk::PlainTextLexer.new
      selector = Obelisk::SmartLexerSelector.new(registry, fallback)
      
      high_lexer = HighPriorityLexer.new
      registry.register(high_lexer)
      
      selected = selector.select("high priority text")
      selected.name.should eq("high-priority")
    end
    
    it "uses filename strategy" do
      registry = Obelisk::PriorityLexerRegistry.new
      fallback = Obelisk::PlainTextLexer.new
      selector = Obelisk::SmartLexerSelector.new(registry, fallback)
      
      medium_lexer = MediumPriorityLexer.new
      registry.register(medium_lexer)
      
      selected = selector.select("random text", Obelisk::SelectionStrategy::Filename, 
                               filename: "test.mp")
      selected.name.should eq("medium-priority")
    end
    
    it "uses MIME type strategy" do
      registry = Obelisk::PriorityLexerRegistry.new
      fallback = Obelisk::PlainTextLexer.new
      selector = Obelisk::SmartLexerSelector.new(registry, fallback)
      
      medium_lexer = MediumPriorityLexer.new
      registry.register(medium_lexer)
      
      selected = selector.select("random text", Obelisk::SelectionStrategy::MimeType,
                               mime_type: "text/medium")
      selected.name.should eq("medium-priority")
    end
    
    it "uses content strategy" do
      registry = Obelisk::PriorityLexerRegistry.new
      fallback = Obelisk::PlainTextLexer.new
      selector = Obelisk::SmartLexerSelector.new(registry, fallback)
      
      low_lexer = LowPriorityLexer.new
      registry.register(low_lexer)
      
      selected = selector.select("low priority text", Obelisk::SelectionStrategy::Content)
      selected.name.should eq("low-priority")
    end
    
    it "uses manual strategy" do
      registry = Obelisk::PriorityLexerRegistry.new
      fallback = Obelisk::PlainTextLexer.new
      selector = Obelisk::SmartLexerSelector.new(registry, fallback)
      
      high_lexer = HighPriorityLexer.new
      registry.register(high_lexer)
      
      selected = selector.select("unrelated text", Obelisk::SelectionStrategy::Manual,
                               lexer_name: "high-priority")
      selected.name.should eq("high-priority")
    end
    
    it "falls back when strategy fails" do
      registry = Obelisk::PriorityLexerRegistry.new
      fallback = Obelisk::PlainTextLexer.new
      selector = Obelisk::SmartLexerSelector.new(registry, fallback)
      
      # No lexers registered, should fall back
      selected = selector.select("test text", Obelisk::SelectionStrategy::Filename,
                               filename: "test.unknown")
      selected.should eq(fallback)
    end
    
    it "uses fallback strategy" do
      registry = Obelisk::PriorityLexerRegistry.new
      fallback = Obelisk::PlainTextLexer.new
      selector = Obelisk::SmartLexerSelector.new(registry, fallback)
      
      selected = selector.select("test text", Obelisk::SelectionStrategy::Fallback)
      selected.should eq(fallback)
    end
  end
end