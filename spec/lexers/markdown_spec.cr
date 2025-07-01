require "../spec_helper"

describe Obelisk::Lexers::Markdown do
  lexer = Obelisk::Lexers::Markdown.new
  
  describe "#config" do
    it "has correct configuration" do
      config = lexer.config
      config.name.should eq("markdown")
      config.aliases.should eq(["markdown", "md", "mkd"])
      config.filenames.should eq(["*.md", "*.markdown", "*.mkd", "*.mdown"])
      config.mime_types.should eq(["text/markdown", "text/x-markdown"])
    end
  end
  
  describe "#analyze" do
    it "recognizes markdown headers" do
      text = "# Header 1\n## Header 2\n### Header 3"
      lexer.analyze(text).should be > 0.5
    end
    
    it "recognizes markdown lists" do
      text = "- Item 1\n- Item 2\n* Item 3\n+ Item 4\n1. Numbered"
      lexer.analyze(text).should be > 0.5
    end
    
    it "recognizes markdown code blocks" do
      text = "```ruby\nputs 'hello'\n```\n\n    indented code"
      lexer.analyze(text).should be > 0.3
    end
    
    it "recognizes markdown inline elements" do
      text = "This is **bold** and *italic* with `code` and [links](url)"
      lexer.analyze(text).should be > 0.2
    end
    
    it "gives low score to non-markdown" do
      text = "{\"key\": \"value\", \"number\": 123}"
      lexer.analyze(text).should be < 0.2
    end
  end
  
  describe "#tokenize" do
    it "tokenizes headers correctly" do
      text = "# Header 1\n## Header 2"
      tokens = lexer.tokenize(text).to_a
      
      tokens.select(&.type.generic_heading?).should_not be_empty
    end
    
    it "tokenizes bold text" do
      text = "This is **bold** text"
      tokens = lexer.tokenize(text).to_a
      
      tokens.select(&.type.generic_strong?).should_not be_empty
      tokens.find(&.type.generic_strong?).try(&.value).should eq("**bold**")
    end
    
    it "tokenizes italic text" do
      text = "This is *italic* text"
      tokens = lexer.tokenize(text).to_a
      
      tokens.select(&.type.generic_emph?).should_not be_empty
      tokens.find(&.type.generic_emph?).try(&.value).should eq("*italic*")
    end
    
    it "tokenizes inline code" do
      text = "Use `puts` method"
      tokens = lexer.tokenize(text).to_a
      
      tokens.select(&.type.literal_string_backtick?).should_not be_empty
      tokens.find(&.type.literal_string_backtick?).try(&.value).should eq("`puts`")
    end
    
    it "tokenizes links" do
      text = "Visit [Crystal](https://crystal-lang.org)"
      tokens = lexer.tokenize(text).to_a
      
      # Should have punctuation for brackets and parens
      tokens.select(&.type.punctuation?).should_not be_empty
      # Should have name attribute for link text
      tokens.select(&.type.name_attribute?).should_not be_empty
      # Should have literal string for URL
      tokens.select(&.type.literal_string?).should_not be_empty
    end
    
    it "tokenizes images" do
      text = "![Alt text](image.png)"
      tokens = lexer.tokenize(text).to_a
      
      # Should have punctuation for brackets and parens
      tokens.select(&.type.punctuation?).should_not be_empty
      # Should have tokens for alt text and URL
      tokens.select(&.type.name_attribute?).should_not be_empty
      tokens.select(&.type.literal_string?).should_not be_empty
    end
    
    it "tokenizes code blocks" do
      text = "```ruby\nputs 'hello'\n```"
      tokens = lexer.tokenize(text).to_a
      
      # Should have backticks for the fences
      tokens.select(&.type.literal_string_backtick?).should_not be_empty
      # Should have Ruby code content (with nested language highlighting)
      tokens.select { |t| t.type.literal_string? || t.type.literal_string_single? }.should_not be_empty
      # Should have Ruby built-in function
      tokens.select(&.type.name_builtin?).should_not be_empty
    end
    
    it "tokenizes lists" do
      text = "- Item 1\n* Item 2\n1. Item 3"
      tokens = lexer.tokenize(text).to_a
      
      # Should have punctuation for list markers
      tokens.select(&.type.punctuation?).should_not be_empty
      # Should have number for ordered list
      tokens.select(&.type.literal_number_integer?).should_not be_empty
    end
    
    it "tokenizes blockquotes" do
      text = "> This is a quote"
      tokens = lexer.tokenize(text).to_a
      
      # Should have punctuation for >
      tokens.select(&.type.punctuation?).should_not be_empty
    end
    
    it "tokenizes horizontal rules" do
      text = "---\n***\n___"
      tokens = lexer.tokenize(text).to_a
      
      # Should have punctuation for rules
      tokens.select(&.type.punctuation?).size.should be >= 3
    end
    
    it "tokenizes tables" do
      text = "| Header | Value |\n|--------|-------|\n| Cell   | Data  |"
      tokens = lexer.tokenize(text).to_a
      
      # Should have many punctuation tokens for pipes
      tokens.select(&.type.punctuation?).select { |t| t.value == "|" }.should_not be_empty
    end
    
    it "handles mixed formatting" do
      text = "# Title\n\nThis has **bold** and *italic* and `code`.\n\n- List item with [link](url)"
      tokens = lexer.tokenize(text).to_a
      
      # Should have various token types
      tokens.select(&.type.generic_heading?).should_not be_empty
      tokens.select(&.type.generic_strong?).should_not be_empty
      tokens.select(&.type.generic_emph?).should_not be_empty
      tokens.select(&.type.literal_string_backtick?).should_not be_empty
    end
    
    it "handles YAML frontmatter" do
      text = "---\ntitle: Test\n---\n# Content"
      tokens = lexer.tokenize(text).to_a
      
      # Should have comment tokens for frontmatter
      tokens.select(&.type.comment_preproc?).should_not be_empty
    end
  end
end