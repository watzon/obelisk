require "./spec_helper"

describe Obelisk::ChromaParser do
  describe "#parse" do
    it "parses a simple Chroma XML style" do
      xml = <<-XML
        <style name="test-theme">
          <entry type="Background" style="bg:#ffffff"/>
          <entry type="Comment" style="#6a737d italic"/>
          <entry type="Keyword" style="#d73a49 bold"/>
          <entry type="LiteralString" style="#032f62"/>
        </style>
        XML

      parser = Obelisk::ChromaParser.new(xml)
      style = parser.parse("test")
      
      style.name.should eq("test-theme")
      style.background.should eq(Obelisk::Color.from_hex("#ffffff"))
      
      # Check comment style
      comment_style = style.get_direct(Obelisk::TokenType::Comment)
      comment_style.should_not be_nil
      comment_style.not_nil!.color.should eq(Obelisk::Color.from_hex("#6a737d"))
      comment_style.not_nil!.italic?.should be_true

      # Check keyword style
      keyword_style = style.get_direct(Obelisk::TokenType::Keyword)
      keyword_style.should_not be_nil
      keyword_style.not_nil!.color.should eq(Obelisk::Color.from_hex("#d73a49"))
      keyword_style.not_nil!.bold?.should be_true

      # Check string style
      string_style = style.get_direct(Obelisk::TokenType::LiteralString)
      string_style.should_not be_nil
      string_style.not_nil!.color.should eq(Obelisk::Color.from_hex("#032f62"))
    end

    it "handles background entry with foreground color" do
      xml = <<-XML
        <style name="test-theme">
          <entry type="Background" style="#000000 bg:#ffffff"/>
          <entry type="Keyword" style="#ff0000"/>
        </style>
        XML

      parser = Obelisk::ChromaParser.new(xml)
      style = parser.parse("test")
      
      style.background.should eq(Obelisk::Color.from_hex("#ffffff"))
      
      # Background entry should set Text token with foreground color
      text_style = style.get_direct(Obelisk::TokenType::Text)
      text_style.should_not be_nil
      text_style.not_nil!.color.should eq(Obelisk::Color.from_hex("#000000"))
    end

    it "parses complex style attributes" do
      xml = <<-XML
        <style name="complex-theme">
          <entry type="Background" style="bg:#1e1e1e"/>
          <entry type="NameFunction" style="#dcdcaa bold underline"/>
          <entry type="CommentSingle" style="#6a9955 italic bg:#2d2d30"/>
          <entry type="LiteralNumber" style="#b5cea8 bold italic underline"/>
        </style>
        XML

      parser = Obelisk::ChromaParser.new(xml)
      style = parser.parse("test")
      
      style.background.should eq(Obelisk::Color.from_hex("#1e1e1e"))
      
      # Check function name style
      func_style = style.get_direct(Obelisk::TokenType::NameFunction)
      func_style.should_not be_nil
      func_style.not_nil!.color.should eq(Obelisk::Color.from_hex("#dcdcaa"))
      func_style.not_nil!.bold?.should be_true
      func_style.not_nil!.underline?.should be_true

      # Check comment style with background
      comment_style = style.get_direct(Obelisk::TokenType::CommentSingle)
      comment_style.should_not be_nil
      comment_style.not_nil!.color.should eq(Obelisk::Color.from_hex("#6a9955"))
      comment_style.not_nil!.background.should eq(Obelisk::Color.from_hex("#2d2d30"))
      comment_style.not_nil!.italic?.should be_true

      # Check number style with all attributes
      number_style = style.get_direct(Obelisk::TokenType::LiteralNumber)
      number_style.should_not be_nil
      number_style.not_nil!.color.should eq(Obelisk::Color.from_hex("#b5cea8"))
      number_style.not_nil!.bold?.should be_true
      number_style.not_nil!.italic?.should be_true
      number_style.not_nil!.underline?.should be_true
    end

    it "handles missing style name" do
      xml = <<-XML
        <style>
          <entry type="Background" style="bg:#ffffff"/>
          <entry type="Keyword" style="#ff0000"/>
        </style>
        XML

      parser = Obelisk::ChromaParser.new(xml)
      style = parser.parse("fallback-name")
      
      style.name.should eq("fallback-name")
    end

    it "ignores unknown token types" do
      xml = <<-XML
        <style name="test-theme">
          <entry type="Background" style="bg:#ffffff"/>
          <entry type="UnknownTokenType" style="#ff0000"/>
          <entry type="Keyword" style="#0000ff"/>
        </style>
        XML

      parser = Obelisk::ChromaParser.new(xml)
      style = parser.parse("test")
      
      # Should parse successfully, ignoring unknown types
      style.name.should eq("test-theme")
      
      keyword_style = style.get_direct(Obelisk::TokenType::Keyword)
      keyword_style.should_not be_nil
      keyword_style.not_nil!.color.should eq(Obelisk::Color.from_hex("#0000ff"))
    end

    it "handles entries without style attributes" do
      xml = <<-XML
        <style name="test-theme">
          <entry type="Background" style="bg:#ffffff"/>
          <entry type="Keyword"/>
          <entry type="Comment" style="#008000"/>
        </style>
        XML

      parser = Obelisk::ChromaParser.new(xml)
      style = parser.parse("test")
      
      # Should parse successfully, ignoring entries without style
      style.name.should eq("test-theme")
      
      comment_style = style.get_direct(Obelisk::TokenType::Comment)
      comment_style.should_not be_nil
      comment_style.not_nil!.color.should eq(Obelisk::Color.from_hex("#008000"))
    end

    it "handles 3-digit hex colors" do
      xml = <<-XML
        <style name="test-theme">
          <entry type="Background" style="bg:#fff"/>
          <entry type="Keyword" style="#f00 bold"/>
          <entry type="Comment" style="#080 bg:#ccc"/>
        </style>
        XML

      parser = Obelisk::ChromaParser.new(xml)
      style = parser.parse("test")
      
      style.background.should eq(Obelisk::Color.from_hex("#fff"))
      
      keyword_style = style.get_direct(Obelisk::TokenType::Keyword)
      keyword_style.should_not be_nil
      keyword_style.not_nil!.color.should eq(Obelisk::Color.from_hex("#f00"))
      keyword_style.not_nil!.bold?.should be_true

      comment_style = style.get_direct(Obelisk::TokenType::Comment)
      comment_style.should_not be_nil
      comment_style.not_nil!.color.should eq(Obelisk::Color.from_hex("#080"))
      comment_style.not_nil!.background.should eq(Obelisk::Color.from_hex("#ccc"))
    end

    it "raises error for invalid XML structure" do
      expect_raises(Obelisk::ThemeError) do
        parser = Obelisk::ChromaParser.new("<invalid><nested>missing</invalid>")
        parser.parse("test")
      end
    end

    it "raises error for wrong root element" do
      xml = <<-XML
        <theme name="test-theme">
          <entry type="Background" style="bg:#ffffff"/>
        </theme>
        XML

      expect_raises(Obelisk::ThemeError, /Invalid Chroma style: root element must be 'style'/) do
        parser = Obelisk::ChromaParser.new(xml)
        parser.parse("test")
      end
    end

    it "handles default white background when no Background entry" do
      xml = <<-XML
        <style name="test-theme">
          <entry type="Keyword" style="#ff0000"/>
        </style>
        XML

      parser = Obelisk::ChromaParser.new(xml)
      style = parser.parse("test")
      
      style.background.should eq(Obelisk::Color::WHITE)
    end

    it "maps comprehensive token types correctly" do
      xml = <<-XML
        <style name="comprehensive-theme">
          <entry type="Background" style="bg:#000000"/>
          <entry type="Error" style="#ff0000"/>
          <entry type="Other" style="#ffffff"/>
          <entry type="KeywordConstant" style="#569cd6"/>
          <entry type="KeywordDeclaration" style="#569cd6"/>
          <entry type="NameClass" style="#4ec9b0"/>
          <entry type="NameFunction" style="#dcdcaa"/>
          <entry type="NameVariable" style="#9cdcfe"/>
          <entry type="LiteralString" style="#ce9178"/>
          <entry type="LiteralNumber" style="#b5cea8"/>
          <entry type="Operator" style="#d4d4d4"/>
          <entry type="Punctuation" style="#d4d4d4"/>
          <entry type="Comment" style="#6a9955"/>
          <entry type="Generic" style="#d4d4d4"/>
        </style>
        XML

      parser = Obelisk::ChromaParser.new(xml)
      style = parser.parse("test")
      
      # Verify a selection of mappings
      style.get_direct(Obelisk::TokenType::Error).should_not be_nil
      style.get_direct(Obelisk::TokenType::Other).should_not be_nil
      style.get_direct(Obelisk::TokenType::KeywordConstant).should_not be_nil
      style.get_direct(Obelisk::TokenType::KeywordDeclaration).should_not be_nil
      style.get_direct(Obelisk::TokenType::NameClass).should_not be_nil
      style.get_direct(Obelisk::TokenType::NameFunction).should_not be_nil
      style.get_direct(Obelisk::TokenType::NameVariable).should_not be_nil
      style.get_direct(Obelisk::TokenType::LiteralString).should_not be_nil
      style.get_direct(Obelisk::TokenType::LiteralNumber).should_not be_nil
      style.get_direct(Obelisk::TokenType::Operator).should_not be_nil
      style.get_direct(Obelisk::TokenType::Punctuation).should_not be_nil
      style.get_direct(Obelisk::TokenType::Comment).should_not be_nil
      style.get_direct(Obelisk::TokenType::Generic).should_not be_nil
    end
  end
end