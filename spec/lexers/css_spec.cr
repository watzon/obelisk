require "../spec_helper"

describe Obelisk::Lexers::CSS do
  lexer = Obelisk::Lexers::CSS.new

  describe "#tokenize" do
    it "tokenizes CSS selectors" do
      code = <<-CSS
      body { }
      .class { }
      #id { }
      div.class#id { }
      CSS
      
      tokens = lexer.tokenize(code).to_a
      
      # Element selector
      tag_tokens = tokens.select { |t| t.type == Obelisk::TokenType::NameTag }
      tag_tokens.map(&.value).should contain("body")
      tag_tokens.map(&.value).should contain("div")
      
      # Class selector
      class_tokens = tokens.select { |t| t.type == Obelisk::TokenType::NameClass }
      class_tokens.map(&.value).should contain(".class")
      
      # ID selector
      id_tokens = tokens.select { |t| t.type == Obelisk::TokenType::NameTag && t.value.starts_with?("#") }
      id_tokens.map(&.value).should contain("#id")
    end

    it "tokenizes CSS properties and values" do
      code = <<-CSS
      body {
        color: #333;
        background-color: rgb(255, 255, 255);
        margin: 10px 20px;
        font-size: 1.5rem;
      }
      CSS
      
      tokens = lexer.tokenize(code).to_a
      
      # Properties
      prop_tokens = tokens.select { |t| t.type == Obelisk::TokenType::NameProperty }
      prop_values = prop_tokens.map(&.value)
      prop_values.should contain("color")
      prop_values.should contain("background-color")
      prop_values.should contain("margin")
      prop_values.should contain("font-size")
      
      # Numbers with units
      number_tokens = tokens.select { |t| t.type == Obelisk::TokenType::LiteralNumber }
      number_values = number_tokens.map(&.value)
      number_values.should contain("10px")
      number_values.should contain("20px")
      number_values.should contain("1.5rem")
    end

    it "tokenizes colors" do
      code = <<-CSS
      .colors {
        color: #fff;
        background: #123456;
        border-color: rgb(255, 0, 0);
        box-shadow: 0 0 10px rgba(0, 0, 0, 0.5);
        fill: hsl(120, 100%, 50%);
      }
      CSS
      
      tokens = lexer.tokenize(code).to_a
      
      # Hex colors
      hex_tokens = tokens.select { |t| t.type == Obelisk::TokenType::LiteralNumberHex }
      hex_values = hex_tokens.map(&.value)
      hex_values.should contain("#fff")
      hex_values.should contain("#123456")
      
      # Color functions
      func_tokens = tokens.select { |t| t.type == Obelisk::TokenType::NameFunction }
      func_values = func_tokens.map(&.value)
      func_values.should contain("rgb")
      func_values.should contain("rgba")
      func_values.should contain("hsl")
    end

    it "tokenizes pseudo-classes and pseudo-elements" do
      code = <<-CSS
      a:hover { }
      p:first-child { }
      li:nth-child(2n+1) { }
      div::before { }
      input::placeholder { }
      CSS
      
      tokens = lexer.tokenize(code).to_a
      
      pseudo_tokens = tokens.select { |t| t.type == Obelisk::TokenType::KeywordPseudo }
      pseudo_values = pseudo_tokens.map(&.value)
      pseudo_values.should contain(":hover")
      pseudo_values.should contain(":first-child")
      pseudo_values.should contain(":nth-child(2n+1)")
      pseudo_values.should contain("::before")
      pseudo_values.should contain("::placeholder")
    end

    it "tokenizes @rules" do
      code = <<-CSS
      @import url("styles.css");
      @media (max-width: 600px) {
        body { font-size: 14px; }
      }
      @keyframes fadeIn {
        from { opacity: 0; }
        to { opacity: 1; }
      }
      CSS
      
      tokens = lexer.tokenize(code).to_a
      
      at_rule_tokens = tokens.select { |t| t.type == Obelisk::TokenType::KeywordNamespace }
      at_rule_values = at_rule_tokens.map(&.value)
      at_rule_values.should contain("@import")
      at_rule_values.should contain("@media")
      at_rule_values.should contain("@keyframes")
    end

    it "tokenizes CSS comments" do
      code = <<-CSS
      /* This is a comment */
      body {
        /* Another comment */
        color: red;
      }
      CSS
      
      tokens = lexer.tokenize(code).to_a
      
      comment_tokens = tokens.select { |t| t.type == Obelisk::TokenType::CommentMultiline }
      comment_tokens.should_not be_empty
      # Comments are tokenized as multiple tokens, check if any contain the text
      comment_values = comment_tokens.map(&.value).join
      comment_values.should contain("This is a comment")
    end

    it "tokenizes attribute selectors" do
      code = <<-CSS
      input[type="text"] { }
      a[href^="https"] { }
      div[class*="container"] { }
      [data-value='test'] { }
      CSS
      
      tokens = lexer.tokenize(code).to_a
      
      # Attribute names
      attr_tokens = tokens.select { |t| t.type == Obelisk::TokenType::NameAttribute }
      attr_values = attr_tokens.map(&.value)
      attr_values.should contain("type")
      attr_values.should contain("href")
      attr_values.should contain("class")
      attr_values.should contain("data-value")
    end

    it "tokenizes CSS functions" do
      code = <<-CSS
      .element {
        transform: rotate(45deg) scale(1.5);
        background: linear-gradient(to right, #000, #fff);
        width: calc(100% - 20px);
        content: url("image.png");
      }
      CSS
      
      tokens = lexer.tokenize(code).to_a
      
      func_tokens = tokens.select { |t| t.type == Obelisk::TokenType::NameFunction }
      func_values = func_tokens.map(&.value)
      func_values.should contain("rotate")
      func_values.should contain("scale")
      func_values.should contain("linear-gradient")
      func_values.should contain("calc")
      func_values.should contain("url(")
    end

    it "tokenizes !important" do
      code = ".test { color: red !important; }"
      tokens = lexer.tokenize(code).to_a
      
      important_tokens = tokens.select { |t| t.type == Obelisk::TokenType::KeywordReserved }
      important_tokens.should_not be_empty
      important_tokens.first.value.should match(/!\s*important/)
    end

    it "tokenizes CSS strings" do
      code = <<-CSS
      .element {
        content: "Hello World";
        font-family: 'Arial', sans-serif;
        background: url("path/to/image.jpg");
      }
      CSS
      
      tokens = lexer.tokenize(code).to_a
      
      string_tokens = tokens.select { |t| t.type == Obelisk::TokenType::LiteralStringDouble || t.type == Obelisk::TokenType::LiteralStringSingle }
      string_tokens.should_not be_empty
    end
  end

  describe "#analyze" do
    it "scores CSS content highly" do
      css = <<-CSS
      body {
        margin: 0;
        padding: 0;
      }
      .container {
        max-width: 1200px;
      }
      CSS
      
      score = lexer.analyze(css)
      score.should be > 0.7
    end

    it "scores non-CSS content low" do
      code = "<html><body>Hello</body></html>"
      score = lexer.analyze(code)
      score.should be < 0.3
    end
  end
end