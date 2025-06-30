require "../spec_helper"

describe Obelisk::TokenType do
  describe "#parent" do
    it "returns correct parent for keyword types" do
      Obelisk::TokenType::KeywordConstant.parent.should eq Obelisk::TokenType::Keyword
      Obelisk::TokenType::KeywordDeclaration.parent.should eq Obelisk::TokenType::Keyword
    end

    it "returns correct parent for name types" do
      Obelisk::TokenType::NameClass.parent.should eq Obelisk::TokenType::Name
      Obelisk::TokenType::NameFunction.parent.should eq Obelisk::TokenType::Name
    end

    it "returns correct parent for literal types" do
      Obelisk::TokenType::LiteralString.parent.should eq Obelisk::TokenType::Literal
      Obelisk::TokenType::LiteralNumber.parent.should eq Obelisk::TokenType::Literal
    end

    it "returns itself for root types" do
      Obelisk::TokenType::Keyword.parent.should eq Obelisk::TokenType::Keyword
      Obelisk::TokenType::Name.parent.should eq Obelisk::TokenType::Name
    end
  end

  describe "#css_class" do
    it "returns correct CSS classes for common types" do
      Obelisk::TokenType::Keyword.css_class.should eq "k"
      Obelisk::TokenType::KeywordConstant.css_class.should eq "kc"
      Obelisk::TokenType::Name.css_class.should eq "n"
      Obelisk::TokenType::NameClass.css_class.should eq "nc"
      Obelisk::TokenType::LiteralString.css_class.should eq "s"
      Obelisk::TokenType::Comment.css_class.should eq "c"
    end

    it "returns empty string for Text" do
      Obelisk::TokenType::Text.css_class.should eq ""
    end
  end

  describe "#in_category?" do
    it "returns true for same type" do
      Obelisk::TokenType::Keyword.in_category?(Obelisk::TokenType::Keyword).should be_true
    end

    it "returns true for parent category" do
      Obelisk::TokenType::KeywordConstant.in_category?(Obelisk::TokenType::Keyword).should be_true
      Obelisk::TokenType::NameClass.in_category?(Obelisk::TokenType::Name).should be_true
    end

    it "returns false for unrelated category" do
      Obelisk::TokenType::Keyword.in_category?(Obelisk::TokenType::Name).should be_false
      Obelisk::TokenType::LiteralString.in_category?(Obelisk::TokenType::Keyword).should be_false
    end
  end
end

describe Obelisk::Token do
  describe "#initialize" do
    it "creates token with type and value" do
      token = Obelisk::Token.new(Obelisk::TokenType::Keyword, "def")
      token.type.should eq Obelisk::TokenType::Keyword
      token.value.should eq "def"
    end
  end

  describe "#clone" do
    it "creates a copy of the token" do
      original = Obelisk::Token.new(Obelisk::TokenType::Name, "test")
      cloned = original.clone
      
      cloned.type.should eq original.type
      cloned.value.should eq original.value
      cloned.should_not be original
    end
  end

  describe "#eof?" do
    it "returns true for EOF token" do
      Obelisk::EOF_TOKEN.eof?.should be_true
    end

    it "returns false for regular tokens" do
      token = Obelisk::Token.new(Obelisk::TokenType::Keyword, "def")
      token.eof?.should be_false
    end
  end

  describe "#css_class" do
    it "delegates to token type" do
      token = Obelisk::Token.new(Obelisk::TokenType::Keyword, "def")
      token.css_class.should eq "k"
    end
  end
end