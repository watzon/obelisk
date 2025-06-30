require "./spec_helper"

describe Obelisk::ComposedLexer do
  it "creates composed lexers with different strategies" do
    lexers = [Obelisk::PlainTextLexer.new, Obelisk::Lexers::Crystal.new]
    composed = Obelisk::ComposedLexer.new("test", lexers, Obelisk::CompositionStrategy::FirstMatch)
    
    composed.name.should eq("test")
    composed.config.name.should eq("test")
  end

  it "analyzes text using composition strategies" do
    lexers = [Obelisk::PlainTextLexer.new, Obelisk::Lexers::Crystal.new]
    composed = Obelisk::ComposedLexer.new("test", lexers, Obelisk::CompositionStrategy::HighestConfidence)
    
    # Should return some confidence score
    score = composed.analyze("puts 'hello'")
    score.should be >= 0.0
    score.should be <= 1.0
  end

  it "tokenizes using first match strategy" do
    lexers = [Obelisk::PlainTextLexer.new, Obelisk::Lexers::Crystal.new]
    composed = Obelisk::ComposedLexer.new("test", lexers, Obelisk::CompositionStrategy::FirstMatch)
    
    tokens = composed.tokenize("hello").to_a
    tokens.should_not be_empty
    tokens.first.should be_a(Obelisk::Token)
  end
end

describe Obelisk::ChainedLexer do  
  it "creates chained lexers" do
    chain = [Obelisk::PlainTextLexer.new, Obelisk::Lexers::Crystal.new]
    chained = Obelisk::ChainedLexer.new("test-chain", chain)
    
    chained.name.should eq("test-chain")
  end

  it "analyzes text through chain" do
    chain = [Obelisk::PlainTextLexer.new, Obelisk::Lexers::Crystal.new]
    chained = Obelisk::ChainedLexer.new("test-chain", chain)
    
    score = chained.analyze("hello")
    score.should be >= 0.0
    score.should be <= 1.0
  end
end

describe Obelisk::LexerComposition do
  it "provides composition helper methods" do
    lexers = [Obelisk::PlainTextLexer.new]
    
    composed = Obelisk::LexerComposition.compose("test", lexers)
    composed.should be_a(Obelisk::ComposedLexer)
    
    chained = Obelisk::LexerComposition.chain("test-chain", lexers)
    chained.should be_a(Obelisk::ChainedLexer)
  end
end

describe Obelisk::MergingTokenIterator do
  pending "token merging implementation needs review"
end

describe Obelisk::LayeredTokenIterator do
  it "creates layered token iterators" do
    iterators = [
      Obelisk::PlainTextLexer.new.tokenize("hello"),
      Obelisk::PlainTextLexer.new.tokenize("world")
    ]
    
    layered = Obelisk::LayeredTokenIterator.new(iterators)
    layered.should be_a(Obelisk::LayeredTokenIterator)
    
    # Should be able to get at least one token
    token = layered.next
    token.should be_a(Obelisk::Token)
  end
end