require "./spec_helper"

describe Obelisk::ThemeExporter do
  describe ".to_json" do
    it "exports a style to JSON format" do
      # Create a test style
      style = Obelisk::Style.new("Test Theme", Obelisk::Color.from_hex("#ffffff"))
      style.set(Obelisk::TokenType::Comment, 
        Obelisk::StyleBuilder.new
          .color("#6a737d")
          .italic
          .build)
      style.set(Obelisk::TokenType::Keyword,
        Obelisk::StyleBuilder.new
          .color("#d73a49")
          .bold
          .build)

      json_string = Obelisk::ThemeExporter.to_json(style, false)
      json_data = JSON.parse(json_string)

      json_data["name"].as_s.should eq("Test Theme")
      json_data["background"].as_s.should eq("#ffffff")
      
      tokens = json_data["tokens"].as_h
      comment = tokens["comment"].as_h
      comment["color"].as_s.should eq("#6a737d")
      comment["italic"].as_bool.should be_true

      keyword = tokens["keyword"].as_h
      keyword["color"].as_s.should eq("#d73a49")
      keyword["bold"].as_bool.should be_true
    end

    it "exports pretty JSON when requested" do
      style = Obelisk::Style.new("Test", Obelisk::Color.from_hex("#000000"))
      
      pretty_json = Obelisk::ThemeExporter.to_json(style, true)
      compact_json = Obelisk::ThemeExporter.to_json(style, false)
      
      pretty_json.should contain("\n")
      pretty_json.should contain("  ")
      compact_json.should_not contain("\n")
    end

    it "handles all style attributes" do
      style = Obelisk::Style.new("Complete", Obelisk::Color.from_hex("#ffffff"))
      style.set(Obelisk::TokenType::Text,
        Obelisk::StyleBuilder.new
          .color("#000000")
          .background("#ffffff")
          .bold
          .italic
          .underline
          .no_inherit
          .build)

      json_string = Obelisk::ThemeExporter.to_json(style, false)
      json_data = JSON.parse(json_string)
      
      text_style = json_data["tokens"]["text"].as_h
      text_style["color"].as_s.should eq("#000000")
      text_style["background"].as_s.should eq("#ffffff")
      text_style["bold"].as_bool.should be_true
      text_style["italic"].as_bool.should be_true
      text_style["underline"].as_bool.should be_true
      text_style["noInherit"].as_bool.should be_true
    end
  end

  describe ".to_tmtheme" do
    it "exports a style to tmTheme XML format" do
      style = Obelisk::Style.new("Test Theme", Obelisk::Color.from_hex("#272822"))
      style.set(Obelisk::TokenType::Text,
        Obelisk::StyleBuilder.new
          .color("#f8f8f2")
          .build)
      style.set(Obelisk::TokenType::Comment,
        Obelisk::StyleBuilder.new
          .color("#75715e")
          .italic
          .build)

      xml = Obelisk::ThemeExporter.to_tmtheme(style)
      
      xml.should contain("<?xml version=\"1.0\" encoding=\"UTF-8\"?>")
      xml.should contain("<plist version=\"1.0\">")
      xml.should contain("<key>name</key>")
      xml.should contain("<string>Test Theme</string>")
      xml.should contain("<key>background</key>")
      xml.should contain("<string>#272822</string>")
      xml.should contain("comment")
      xml.should contain("#75715e")
      xml.should contain("italic")
    end

    it "includes UUID in exported tmTheme" do
      style = Obelisk::Style.new("Test", Obelisk::Color.from_hex("#ffffff"))
      xml = Obelisk::ThemeExporter.to_tmtheme(style)
      
      xml.should contain("<key>uuid</key>")
      # Should contain a UUID pattern (8-4-4-4-12 hex digits with dashes)
      xml.should match(/<string>[A-F0-9]{8}-[A-F0-9]{4}-[A-F0-9]{4}-[A-F0-9]{4}-[A-F0-9]{12}<\/string>/)
    end

    it "escapes XML characters in theme name" do
      style = Obelisk::Style.new("Test & <Special> \"Theme\"", Obelisk::Color.from_hex("#ffffff"))
      xml = Obelisk::ThemeExporter.to_tmtheme(style)
      
      xml.should contain("Test &amp; &lt;Special&gt; &quot;Theme&quot;")
      xml.should_not contain("Test & <Special> \"Theme\"")
    end
  end

  describe ".to_chroma" do
    it "exports a style to Chroma XML format" do
      style = Obelisk::Style.new("Test Theme", Obelisk::Color.from_hex("#ffffff"))
      style.set(Obelisk::TokenType::Comment,
        Obelisk::StyleBuilder.new
          .color("#6a737d")
          .italic
          .build)
      style.set(Obelisk::TokenType::Keyword,
        Obelisk::StyleBuilder.new
          .color("#d73a49")
          .bold
          .build)

      xml = Obelisk::ThemeExporter.to_chroma(style)
      
      xml.should contain("<style name=\"Test Theme\">")
      xml.should contain("</style>")
      xml.should contain("<entry type=\"Background\" style=\"bg:#ffffff\"/>")
      xml.should contain("<entry type=\"Comment\" style=\"italic #6a737d\"/>")
      xml.should contain("<entry type=\"Keyword\" style=\"bold #d73a49\"/>")
    end

    it "handles complex Chroma style attributes" do
      style = Obelisk::Style.new("Complex", Obelisk::Color.from_hex("#1e1e1e"))
      style.set(Obelisk::TokenType::NameFunction,
        Obelisk::StyleBuilder.new
          .color("#dcdcaa")
          .background("#2d2d30")
          .bold
          .italic
          .underline
          .build)

      xml = Obelisk::ThemeExporter.to_chroma(style)
      
      xml.should contain("<style name=\"Complex\">")
      xml.should contain("<entry type=\"Background\" style=\"bg:#1e1e1e\"/>")
      xml.should contain("<entry type=\"NameFunction\" style=\"bold italic underline #dcdcaa bg:#2d2d30\"/>")
    end
  end

  describe ".save" do
    it "saves JSON format to file" do
      style = Obelisk::Style.new("Save Test", Obelisk::Color.from_hex("#ffffff"))
      
      Obelisk::ThemeExporter.save(style, "test_save.json")
      
      File.exists?("test_save.json").should be_true
      content = File.read("test_save.json")
      content.should contain("Save Test")
      content.should contain("#ffffff")
      
      File.delete("test_save.json")
    end

    it "saves tmTheme format to file" do
      style = Obelisk::Style.new("tmTheme Test", Obelisk::Color.from_hex("#000000"))
      
      Obelisk::ThemeExporter.save(style, "test_save.tmtheme")
      
      File.exists?("test_save.tmtheme").should be_true
      content = File.read("test_save.tmtheme")
      content.should contain("<?xml version")
      content.should contain("tmTheme Test")
      
      File.delete("test_save.tmtheme")
    end

    it "saves Chroma XML format to file" do
      style = Obelisk::Style.new("Chroma Test", Obelisk::Color.from_hex("#000000"))
      style.set(Obelisk::TokenType::Comment,
        Obelisk::StyleBuilder.new.color("#008000").build)
      
      Obelisk::ThemeExporter.save(style, "test_save.xml")
      
      File.exists?("test_save.xml").should be_true
      content = File.read("test_save.xml")
      content.should contain("<style name=\"Chroma Test\">")
      content.should contain("bg:#000000")
      content.should contain("Comment")
      
      File.delete("test_save.xml")
    end

    it "auto-detects format from file extension" do
      style = Obelisk::Style.new("Auto Detect", Obelisk::Color.from_hex("#ffffff"))
      
      # Test different extensions
      Obelisk::ThemeExporter.save(style, "auto.json")
      File.read("auto.json").should contain("\"name\"")
      File.delete("auto.json")
      
      Obelisk::ThemeExporter.save(style, "auto.tmtheme")
      File.read("auto.tmtheme").should contain("<?xml version")
      File.delete("auto.tmtheme")
      
      Obelisk::ThemeExporter.save(style, "auto.xml")
      File.read("auto.xml").should contain("<style name=")
      File.delete("auto.xml")
    end

    it "overrides auto-detection with explicit format" do
      style = Obelisk::Style.new("Override", Obelisk::Color.from_hex("#ffffff"))
      
      # Save as JSON even though extension is .xml
      Obelisk::ThemeExporter.save(style, "override.xml", Obelisk::ThemeLoader::Format::JSON)
      content = File.read("override.xml")
      content.should contain("\"name\"")
      content.should_not contain("<style")
      
      File.delete("override.xml")
    end
  end

  describe "token type string conversion" do
    it "converts all TokenType values to correct strings" do
      style = Obelisk::Style.new("Mapping Test", Obelisk::Color.from_hex("#ffffff"))
      
      # Test a few key token types
      style.set(Obelisk::TokenType::CommentSingle, 
        Obelisk::StyleBuilder.new.color("#ff0000").build)
      style.set(Obelisk::TokenType::LiteralStringDouble,
        Obelisk::StyleBuilder.new.color("#00ff00").build)
      style.set(Obelisk::TokenType::KeywordReserved,
        Obelisk::StyleBuilder.new.color("#0000ff").build)

      json_string = Obelisk::ThemeExporter.to_json(style, false)
      json_data = JSON.parse(json_string)
      
      tokens = json_data["tokens"].as_h
      tokens.has_key?("comment.single").should be_true
      tokens.has_key?("literal.string.double").should be_true
      tokens.has_key?("keyword.reserved").should be_true
    end
  end
end