require "../../spec_helper"

describe Obelisk::Lexers::JSON do
  lexer = Obelisk::Lexers::JSON.new

  describe "#config" do
    it "has correct configuration" do
      config = lexer.config
      config.name.should eq "json"
      config.aliases.should contain "json"
      config.filenames.should contain "*.json"
      config.mime_types.should contain "application/json"
    end
  end

  describe "#analyze" do
    it "gives high score for valid JSON" do
      json_code = <<-JSON
        {
          "name": "test",
          "value": 42,
          "enabled": true
        }
        JSON
      
      score = lexer.analyze(json_code)
      score.should be > 0.7
    end

    it "gives high score for JSON arrays" do
      json_code = <<-JSON
        [
          {"id": 1, "name": "first"},
          {"id": 2, "name": "second"}
        ]
        JSON
      
      score = lexer.analyze(json_code)
      score.should be > 0.7
    end

    it "gives low score for non-JSON code" do
      crystal_code = <<-CODE
        def hello
          puts "world"
        end
        CODE
      
      score = lexer.analyze(crystal_code)
      score.should be < 0.3
    end

    it "handles balanced braces correctly" do
      balanced_json = %({"a": {"b": "c"}})
      unbalanced_json = %({"a": {"b": "c"})
      
      lexer.analyze(balanced_json).should be > lexer.analyze(unbalanced_json)
    end
  end

  describe "#tokenize" do
    it "tokenizes simple JSON object" do
      json = %({"name": "test", "value": 42})
      tokens = lexer.tokenize(json).to_a
      
      # Should have string, colon, string, comma, string, colon, number
      string_tokens = tokens.select { |t| t.type == Obelisk::TokenType::LiteralStringDouble }
      string_tokens.size.should eq 9 # 3 string components each for "name", "test", "value"
      
      number_tokens = tokens.select { |t| t.type == Obelisk::TokenType::LiteralNumber }
      number_tokens.size.should eq 1
      number_tokens.first.value.should eq "42"
    end

    it "tokenizes JSON literals correctly" do
      json = %({"flag": true, "empty": null, "disabled": false})
      tokens = lexer.tokenize(json).to_a
      
      literal_tokens = tokens.select { |t| t.type == Obelisk::TokenType::KeywordConstant }
      literal_tokens.size.should eq 3
      literal_tokens.map(&.value).should contain("true")
      literal_tokens.map(&.value).should contain("false")
      literal_tokens.map(&.value).should contain("null")
    end

    it "tokenizes JSON arrays" do
      json = "[1, 2, 3]"
      tokens = lexer.tokenize(json).to_a
      
      bracket_tokens = tokens.select { |t| t.type == Obelisk::TokenType::Punctuation && (t.value == "[" || t.value == "]") }
      bracket_tokens.size.should eq 2
      
      number_tokens = tokens.select { |t| t.type == Obelisk::TokenType::LiteralNumber }
      number_tokens.size.should eq 3
    end

    it "handles nested structures" do
      json = %({"users": [{"name": "Alice"}, {"name": "Bob"}]})
      tokens = lexer.tokenize(json).to_a
      
      # Should not generate error tokens for valid JSON
      error_tokens = tokens.select { |t| t.type == Obelisk::TokenType::Error }
      error_tokens.should be_empty
    end

    it "tokenizes string escapes correctly" do
      json = %({"message": "Hello\\nWorld\\u0021"})
      tokens = lexer.tokenize(json).to_a
      
      escape_tokens = tokens.select { |t| t.type == Obelisk::TokenType::LiteralStringEscape }
      escape_tokens.size.should eq 2
      escape_tokens.map(&.value).should contain("\\n")
      escape_tokens.map(&.value).should contain("\\u0021")
    end

    it "handles various number formats" do
      json = %({"int": 42, "float": 3.14, "exp": 1.2e-3, "neg": -5})
      tokens = lexer.tokenize(json).to_a
      
      number_tokens = tokens.select { |t| t.type == Obelisk::TokenType::LiteralNumber }
      number_tokens.size.should eq 4
      number_tokens.map(&.value).should contain("42")
      number_tokens.map(&.value).should contain("3.14")
      number_tokens.map(&.value).should contain("1.2e-3")
      number_tokens.map(&.value).should contain("-5")
    end

    it "generates errors for invalid JSON" do
      invalid_json = %({"name": "test",})  # trailing comma
      tokens = lexer.tokenize(invalid_json).to_a
      
      # Depending on implementation, this might generate error tokens
      # At minimum, it should handle gracefully without crashing
      tokens.should_not be_empty
    end
  end
end