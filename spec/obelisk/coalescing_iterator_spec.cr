require "../spec_helper"
require "../../src/obelisk/coalescing_iterator"

describe Obelisk::CoalescingIterator do
  it "coalesces consecutive tokens of the same type" do
    tokens = [
      Obelisk::Token.new(Obelisk::TokenType::TextWhitespace, " "),
      Obelisk::Token.new(Obelisk::TokenType::TextWhitespace, " "),
      Obelisk::Token.new(Obelisk::TokenType::TextWhitespace, " "),
      Obelisk::Token.new(Obelisk::TokenType::Keyword, "def"),
      Obelisk::Token.new(Obelisk::TokenType::TextWhitespace, " "),
      Obelisk::Token.new(Obelisk::TokenType::Name, "foo"),
    ].each

    coalesced = Obelisk::CoalescingIterator.new(tokens).to_a

    coalesced.size.should eq 4
    coalesced[0].type.should eq Obelisk::TokenType::TextWhitespace
    coalesced[0].value.should eq "   "
    coalesced[1].type.should eq Obelisk::TokenType::Keyword
    coalesced[1].value.should eq "def"
    coalesced[2].type.should eq Obelisk::TokenType::TextWhitespace
    coalesced[2].value.should eq " "
    coalesced[3].type.should eq Obelisk::TokenType::Name
    coalesced[3].value.should eq "foo"
  end

  it "respects max_size limit" do
    tokens = [
      Obelisk::Token.new(Obelisk::TokenType::TextWhitespace, "  "),
      Obelisk::Token.new(Obelisk::TokenType::TextWhitespace, "  "),
      Obelisk::Token.new(Obelisk::TokenType::TextWhitespace, "  "),
    ].each

    coalesced = Obelisk::CoalescingIterator.new(tokens, max_size: 4).to_a

    coalesced.size.should eq 2
    coalesced[0].value.should eq "    " # First two tokens (2+2=4)
    coalesced[1].value.should eq "  "   # Last token alone
  end

  it "handles single tokens without coalescing" do
    tokens = [
      Obelisk::Token.new(Obelisk::TokenType::Keyword, "def"),
      Obelisk::Token.new(Obelisk::TokenType::Name, "foo"),
      Obelisk::Token.new(Obelisk::TokenType::Operator, "="),
    ].each

    coalesced = Obelisk::CoalescingIterator.new(tokens).to_a

    coalesced.size.should eq 3
    coalesced[0].value.should eq "def"
    coalesced[1].value.should eq "foo"
    coalesced[2].value.should eq "="
  end

  it "handles empty iterator" do
    tokens = [] of Obelisk::Token
    coalesced = Obelisk::CoalescingIterator.new(tokens.each).to_a
    coalesced.should be_empty
  end

  it "coalesces string literals" do
    tokens = [
      Obelisk::Token.new(Obelisk::TokenType::LiteralString, "\"Hello"),
      Obelisk::Token.new(Obelisk::TokenType::LiteralString, " "),
      Obelisk::Token.new(Obelisk::TokenType::LiteralString, "World\""),
    ].each

    coalesced = Obelisk::CoalescingIterator.new(tokens).to_a

    coalesced.size.should eq 1
    coalesced[0].value.should eq "\"Hello World\""
  end

  it "works with direct constructor" do
    tokens = [
      Obelisk::Token.new(Obelisk::TokenType::Comment, "# This"),
      Obelisk::Token.new(Obelisk::TokenType::Comment, " is"),
      Obelisk::Token.new(Obelisk::TokenType::Comment, " a comment"),
    ].each

    coalescing = Obelisk::CoalescingIterator.new(tokens)
    coalesced = coalescing.to_a

    coalesced.size.should eq 1
    coalesced[0].value.should eq "# This is a comment"
  end
end
