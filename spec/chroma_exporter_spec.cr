require "./spec_helper"

describe Obelisk::ChromaExporter do
  describe "#export" do
    it "exports a simple style to Chroma XML" do
      style = Obelisk::Style.new("test-theme", Obelisk::Color.from_hex("#ffffff"))
      
      # Add some token styles
      style.set(Obelisk::TokenType::Comment, 
        Obelisk::StyleBuilder.new
          .color(Obelisk::Color.from_hex("#6a737d"))
          .italic
          .build)
      
      style.set(Obelisk::TokenType::Keyword,
        Obelisk::StyleBuilder.new
          .color(Obelisk::Color.from_hex("#d73a49"))
          .bold
          .build)

      exporter = Obelisk::ChromaExporter.new(style)
      xml = exporter.export
      
      # Check structure
      xml.should contain("<style name=\"test-theme\">")
      xml.should contain("</style>")
      xml.should contain("<entry type=\"Background\" style=\"bg:#ffffff\"/>")
      xml.should contain("<entry type=\"Comment\" style=\"italic #6a737d\"/>")
      xml.should contain("<entry type=\"Keyword\" style=\"bold #d73a49\"/>")
    end

    it "exports complex styles with all attributes" do
      style = Obelisk::Style.new("complex-theme", Obelisk::Color.from_hex("#1e1e1e"))
      
      # Add a style with all possible attributes
      style.set(Obelisk::TokenType::NameFunction,
        Obelisk::StyleBuilder.new
          .color(Obelisk::Color.from_hex("#dcdcaa"))
          .background(Obelisk::Color.from_hex("#2d2d30"))
          .bold
          .italic
          .underline
          .build)

      exporter = Obelisk::ChromaExporter.new(style)
      xml = exporter.export
      
      xml.should contain("<style name=\"complex-theme\">")
      xml.should contain("<entry type=\"Background\" style=\"bg:#1e1e1e\"/>")
      xml.should contain("<entry type=\"NameFunction\" style=\"bold italic underline #dcdcaa bg:#2d2d30\"/>")
    end

    it "only exports styles that have attributes" do
      style = Obelisk::Style.new("minimal-theme", Obelisk::Color.from_hex("#ffffff"))
      
      # Add a style with only color
      style.set(Obelisk::TokenType::Comment,
        Obelisk::StyleBuilder.new
          .color(Obelisk::Color.from_hex("#008000"))
          .build)

      # Add an empty style (should not be exported)
      style.set(Obelisk::TokenType::Keyword, Obelisk::StyleBuilder.new.build)

      exporter = Obelisk::ChromaExporter.new(style)
      xml = exporter.export
      
      xml.should contain("<entry type=\"Comment\" style=\"#008000\"/>")
      xml.should_not contain("Keyword")
    end

    it "handles styles with only background colors" do
      style = Obelisk::Style.new("bg-theme", Obelisk::Color.from_hex("#000000"))
      
      style.set(Obelisk::TokenType::LiteralString,
        Obelisk::StyleBuilder.new
          .background(Obelisk::Color.from_hex("#2d2d30"))
          .build)

      exporter = Obelisk::ChromaExporter.new(style)
      xml = exporter.export
      
      xml.should contain("<entry type=\"LiteralString\" style=\"bg:#2d2d30\"/>")
    end

    it "handles styles with only font attributes" do
      style = Obelisk::Style.new("font-theme", Obelisk::Color.from_hex("#ffffff"))
      
      style.set(Obelisk::TokenType::Generic,
        Obelisk::StyleBuilder.new
          .bold
          .italic
          .underline
          .build)

      exporter = Obelisk::ChromaExporter.new(style)
      xml = exporter.export
      
      xml.should contain("<entry type=\"Generic\" style=\"bold italic underline\"/>")
    end

    it "escapes XML special characters in style name" do
      style = Obelisk::Style.new("theme<with>&\"special\"'chars", Obelisk::Color.from_hex("#ffffff"))

      exporter = Obelisk::ChromaExporter.new(style)
      xml = exporter.export
      
      xml.should contain("<style name=\"theme&lt;with&gt;&amp;&quot;special&quot;&apos;chars\">")
    end

    it "exports styles in sorted order for consistency" do
      style = Obelisk::Style.new("sorted-theme", Obelisk::Color.from_hex("#ffffff"))
      
      # Add styles out of alphabetical order
      style.set(Obelisk::TokenType::Operator,
        Obelisk::StyleBuilder.new.color(Obelisk::Color.from_hex("#ff0000")).build)
      style.set(Obelisk::TokenType::Comment,
        Obelisk::StyleBuilder.new.color(Obelisk::Color.from_hex("#00ff00")).build)
      style.set(Obelisk::TokenType::Keyword,
        Obelisk::StyleBuilder.new.color(Obelisk::Color.from_hex("#0000ff")).build)

      exporter = Obelisk::ChromaExporter.new(style)
      xml = exporter.export
      
      # Comment should come before Keyword which should come before Operator
      comment_pos = xml.index("Comment")
      keyword_pos = xml.index("Keyword")
      operator_pos = xml.index("Operator")
      
      comment_pos.should_not be_nil
      keyword_pos.should_not be_nil
      operator_pos.should_not be_nil
      
      comment_pos.not_nil!.should be < keyword_pos.not_nil!
      keyword_pos.not_nil!.should be < operator_pos.not_nil!
    end

    it "skips Text token type (handled by Background)" do
      style = Obelisk::Style.new("text-theme", Obelisk::Color.from_hex("#ffffff"))
      
      style.set(Obelisk::TokenType::Text,
        Obelisk::StyleBuilder.new
          .color(Obelisk::Color.from_hex("#000000"))
          .build)
      
      style.set(Obelisk::TokenType::Comment,
        Obelisk::StyleBuilder.new
          .color(Obelisk::Color.from_hex("#008000"))
          .build)

      exporter = Obelisk::ChromaExporter.new(style)
      xml = exporter.export
      
      # Should not contain Text token entry
      xml.should_not contain("type=\"Text\"")
      # But should contain Comment
      xml.should contain("type=\"Comment\"")
    end

    it "handles comprehensive token type mapping" do
      style = Obelisk::Style.new("comprehensive-theme", Obelisk::Color.from_hex("#000000"))
      
      # Add styles for various token types
      style.set(Obelisk::TokenType::Error,
        Obelisk::StyleBuilder.new.color(Obelisk::Color.from_hex("#ff0000")).build)
      style.set(Obelisk::TokenType::KeywordConstant,
        Obelisk::StyleBuilder.new.color(Obelisk::Color.from_hex("#569cd6")).build)
      style.set(Obelisk::TokenType::NameClass,
        Obelisk::StyleBuilder.new.color(Obelisk::Color.from_hex("#4ec9b0")).build)
      style.set(Obelisk::TokenType::LiteralNumberHex,
        Obelisk::StyleBuilder.new.color(Obelisk::Color.from_hex("#b5cea8")).build)

      exporter = Obelisk::ChromaExporter.new(style)
      xml = exporter.export
      
      # Check that all token types are mapped correctly
      xml.should contain("type=\"Error\"")
      xml.should contain("type=\"KeywordConstant\"")
      xml.should contain("type=\"NameClass\"")
      xml.should contain("type=\"LiteralNumberHex\"")
    end

    it "produces valid XML structure" do
      style = Obelisk::Style.new("valid-xml", Obelisk::Color.from_hex("#ffffff"))
      
      style.set(Obelisk::TokenType::Comment,
        Obelisk::StyleBuilder.new.color(Obelisk::Color.from_hex("#008000")).build)

      exporter = Obelisk::ChromaExporter.new(style)
      xml = exporter.export
      
      # Should be parseable as XML
      parsed = XML.parse(xml)
      parsed.should_not be_nil
      
      # Check structure
      root = parsed.first_element_child
      root.should_not be_nil
      root.not_nil!.name.should eq("style")
      root.not_nil!["name"].should eq("valid-xml")
      
      # Should have at least background entry
      entries = root.not_nil!.children.select(&.name.== "entry")
      entries.size.should be >= 1
      
      # Background entry should be first
      background_entry = entries.first
      background_entry["type"].should eq("Background")
      background_entry["style"].should eq("bg:#ffffff")
    end
  end
end