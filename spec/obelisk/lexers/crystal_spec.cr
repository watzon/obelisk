require "../../spec_helper"

describe Obelisk::Lexers::Crystal do
  lexer = Obelisk::Lexers::Crystal.new

  describe "#config" do
    it "has correct configuration" do
      config = lexer.config
      config.name.should eq "crystal"
      config.aliases.should contain "crystal"
      config.aliases.should contain "cr"
      config.filenames.should contain "*.cr"
    end
  end

  describe "#analyze" do
    it "gives high score for Crystal code" do
      crystal_code = <<-CODE
        def hello(name : String) : String
          "Hello, \#{name}!"
        end
        CODE

      score = lexer.analyze(crystal_code)
      score.should be > 0.5
    end

    it "gives low score for non-Crystal code" do
      javascript_code = <<-CODE
        function hello(name) {
          return "Hello, " + name + "!";
        }
        CODE

      score = lexer.analyze(javascript_code)
      score.should be < 0.3
    end

    it "recognizes Crystal-specific syntax" do
      crystal_code = <<-CODE
        @[JSON::Field(key: "user_name")]
        property username : String
        CODE

      score = lexer.analyze(crystal_code)
      score.should be > 0.3
    end
  end

  describe "#tokenize" do
    it "tokenizes keywords correctly" do
      code = "def class module"
      tokens = lexer.tokenize(code).to_a

      keyword_tokens = tokens.select { |t| t.type == Obelisk::TokenType::Keyword }
      keyword_tokens.size.should eq 3
      keyword_tokens.map(&.value).should eq ["def", "class", "module"]
    end

    it "tokenizes strings correctly" do
      code = %("Hello, world!")
      tokens = lexer.tokenize(code).to_a

      string_tokens = tokens.select { |t| t.type == Obelisk::TokenType::LiteralStringDouble }
      string_tokens.size.should be >= 1
    end

    it "tokenizes numbers correctly" do
      code = "42 3.14 0x1a 0b101"
      tokens = lexer.tokenize(code).to_a

      number_tokens = tokens.select { |t| t.type.in_category?(Obelisk::TokenType::LiteralNumber) }
      number_tokens.size.should eq 4
    end

    it "tokenizes instance variables" do
      code = "@name @age"
      tokens = lexer.tokenize(code).to_a

      ivar_tokens = tokens.select { |t| t.type == Obelisk::TokenType::NameVariableInstance }
      ivar_tokens.size.should eq 2
      ivar_tokens.map(&.value).should eq ["@name", "@age"]
    end

    it "tokenizes class variables" do
      code = "@@count @@total"
      tokens = lexer.tokenize(code).to_a

      cvar_tokens = tokens.select { |t| t.type == Obelisk::TokenType::NameVariableClass }
      cvar_tokens.size.should eq 2
      cvar_tokens.map(&.value).should eq ["@@count", "@@total"]
    end

    it "tokenizes symbols" do
      code = ":name :+ :\"complex symbol\""
      tokens = lexer.tokenize(code).to_a

      symbol_tokens = tokens.select { |t| t.type == Obelisk::TokenType::LiteralStringSymbol }
      symbol_tokens.size.should be >= 2
    end

    it "tokenizes comments" do
      code = "# This is a comment\ncode # inline comment"
      tokens = lexer.tokenize(code).to_a

      comment_tokens = tokens.select { |t| t.type == Obelisk::TokenType::CommentSingle }
      comment_tokens.size.should eq 2
    end

    it "handles string interpolation" do
      code = %("Hello, \#{name}!")
      tokens = lexer.tokenize(code).to_a

      # Should have string parts and interpolation markers
      interp_tokens = tokens.select { |t| t.type == Obelisk::TokenType::LiteralStringInterpol }
      interp_tokens.size.should be >= 1
    end

    it "tokenizes Crystal-specific types" do
      code = "Array(String) Hash(String, Int32)"
      tokens = lexer.tokenize(code).to_a

      type_tokens = tokens.select { |t| t.type == Obelisk::TokenType::KeywordType }
      type_tokens.map(&.value).should contain("Array")
      type_tokens.map(&.value).should contain("String")
      type_tokens.map(&.value).should contain("Hash")
      type_tokens.map(&.value).should contain("Int32")
    end
  end
end
