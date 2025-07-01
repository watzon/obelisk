require "../spec_helper"

describe Obelisk::Lexers::HTML do
  lexer = Obelisk::Lexers::HTML.new

  describe "#tokenize" do
    it "tokenizes basic HTML" do
      code = "<html><body><h1>Hello</h1></body></html>"
      tokens = lexer.tokenize(code).to_a
      
      tokens.should_not be_empty
      
      # Check for HTML tags
      tag_tokens = tokens.select { |t| t.type == Obelisk::TokenType::NameTag }
      tag_values = tag_tokens.map(&.value)
      tag_values.should contain("<html")
      tag_values.should contain("<body")
      tag_values.should contain("<h1")
    end

    it "tokenizes HTML attributes" do
      code = %(<a href="https://example.com" class="link">Link</a>)
      tokens = lexer.tokenize(code).to_a
      
      attr_tokens = tokens.select { |t| t.type == Obelisk::TokenType::NameAttribute }
      attr_values = attr_tokens.map(&.value)
      attr_values.should contain("href")
      attr_values.should contain("class")
    end

    it "tokenizes HTML entities" do
      code = "<p>&amp; &lt; &gt; &quot; &#169; &#x2764;</p>"
      tokens = lexer.tokenize(code).to_a
      
      entity_tokens = tokens.select { |t| t.type == Obelisk::TokenType::NameEntity }
      entity_values = entity_tokens.map(&.value)
      entity_values.should contain("&amp;")
      entity_values.should contain("&lt;")
      entity_values.should contain("&gt;")
      entity_values.should contain("&quot;")
      entity_values.should contain("&#169;")
      entity_values.should contain("&#x2764;")
    end

    it "tokenizes HTML comments" do
      code = "<!-- This is a comment -->"
      tokens = lexer.tokenize(code).to_a
      
      comment_tokens = tokens.select { |t| t.type == Obelisk::TokenType::CommentMultiline }
      comment_tokens.should_not be_empty
      # Comments are tokenized as multiple tokens, check if any contain the text
      comment_values = comment_tokens.map(&.value).join
      comment_values.should contain("This is a comment")
    end

    it "tokenizes DOCTYPE" do
      code = "<!DOCTYPE html>"
      tokens = lexer.tokenize(code).to_a
      
      doctype_tokens = tokens.select { |t| t.type == Obelisk::TokenType::CommentPreproc }
      doctype_tokens.should_not be_empty
      doctype_tokens.first.value.should eq("<!DOCTYPE html>")
    end

    it "delegates CSS in style tags" do
      code = <<-HTML
      <style>
        body { background: #fff; }
        .class { color: red; }
      </style>
      HTML
      
      tokens = lexer.tokenize(code).to_a
      
      # Should have CSS-specific tokens
      css_class_tokens = tokens.select { |t| t.type == Obelisk::TokenType::NameClass }
      css_class_tokens.should_not be_empty
      css_class_tokens.first.value.should eq(".class")
      
      property_tokens = tokens.select { |t| t.type == Obelisk::TokenType::NameProperty }
      property_tokens.map(&.value).should contain("background")
      property_tokens.map(&.value).should contain("color")
    end

    it "delegates JavaScript in script tags" do
      code = <<-HTML
      <script>
        const message = "Hello";
        function greet() {
          console.log(message);
        }
      </script>
      HTML
      
      tokens = lexer.tokenize(code).to_a
      
      # Should have JavaScript-specific tokens
      keyword_tokens = tokens.select { |t| t.type == Obelisk::TokenType::Keyword }
      keyword_values = keyword_tokens.map(&.value)
      keyword_values.should contain("const")
      keyword_values.should contain("function")
      
      func_tokens = tokens.select { |t| t.type == Obelisk::TokenType::NameFunction }
      func_tokens.map(&.value).should contain("greet")
    end

    it "handles self-closing tags" do
      code = %(<img src="image.jpg" alt="Test" />)
      tokens = lexer.tokenize(code).to_a
      
      tokens.should_not be_empty
      tag_tokens = tokens.select { |t| t.type == Obelisk::TokenType::NameTag }
      tag_tokens.first.value.should eq("<img")
    end

    it "handles CDATA sections" do
      code = "<![CDATA[<some><xml>data</xml></some>]]>"
      tokens = lexer.tokenize(code).to_a
      
      tokens.should_not be_empty
      # CDATA content should be treated as text
      text_tokens = tokens.select { |t| t.type == Obelisk::TokenType::Text }
      text_tokens.map(&.value).join.should contain("<some><xml>data</xml></some>")
    end
  end

  describe "#analyze" do
    it "scores HTML content highly" do
      html = <<-HTML
      <!DOCTYPE html>
      <html>
      <head><title>Test</title></head>
      <body>
        <h1>Hello</h1>
        <p>World</p>
      </body>
      </html>
      HTML
      
      score = lexer.analyze(html)
      score.should be > 0.7
    end

    it "scores non-HTML content low" do
      code = "function test() { return true; }"
      score = lexer.analyze(code)
      score.should be < 0.3
    end
  end
end