require "./spec_helper"

describe Obelisk::ThemeLoader do
  describe ".load_json" do
    it "loads a simple JSON theme" do
      json = {
        "name" => "Test Theme",
        "background" => "#ffffff",
        "tokens" => {
          "comment" => {
            "color" => "#6a737d",
            "italic" => true
          },
          "keyword" => {
            "color" => "#d73a49",
            "bold" => true
          }
        }
      }.to_json

      style = Obelisk::ThemeLoader.load_from_string(json, Obelisk::ThemeLoader::Format::JSON, "test")
      
      style.name.should eq("Test Theme")
      style.background.should eq(Obelisk::Color.from_hex("#ffffff"))
      
      comment_style = style.get_direct(Obelisk::TokenType::Comment)
      comment_style.should_not be_nil
      comment_style.not_nil!.color.should eq(Obelisk::Color.from_hex("#6a737d"))
      comment_style.not_nil!.italic?.should be_true

      keyword_style = style.get_direct(Obelisk::TokenType::Keyword)
      keyword_style.should_not be_nil
      keyword_style.not_nil!.color.should eq(Obelisk::Color.from_hex("#d73a49"))
      keyword_style.not_nil!.bold?.should be_true
    end

    it "handles missing optional fields" do
      json = {
        "background" => "#000000",
        "tokens" => {
          "text" => {
            "color" => "#ffffff"
          }
        }
      }.to_json

      style = Obelisk::ThemeLoader.load_from_string(json, Obelisk::ThemeLoader::Format::JSON, "minimal")
      
      style.name.should eq("minimal")
      style.background.should eq(Obelisk::Color.from_hex("#000000"))
    end

    it "raises error for invalid JSON" do
      expect_raises(Obelisk::ThemeError, /Invalid JSON theme/) do
        Obelisk::ThemeLoader.load_from_string("invalid json", Obelisk::ThemeLoader::Format::JSON, "test")
      end
    end

    it "raises error for unknown token type" do
      json = {
        "background" => "#ffffff",
        "tokens" => {
          "unknown_token" => {
            "color" => "#ff0000"
          }
        }
      }.to_json

      expect_raises(Obelisk::ThemeError, /Unknown token type/) do
        Obelisk::ThemeLoader.load_from_string(json, Obelisk::ThemeLoader::Format::JSON, "test")
      end
    end
  end

  describe ".load_chroma" do
    it "loads a Chroma XML theme" do
      xml = <<-XML
        <style name="chroma-test">
          <entry type="Background" style="bg:#ffffff"/>
          <entry type="Comment" style="#6a737d italic"/>
          <entry type="Keyword" style="#d73a49 bold"/>
          <entry type="LiteralString" style="#032f62"/>
        </style>
        XML

      style = Obelisk::ThemeLoader.load_from_string(xml, Obelisk::ThemeLoader::Format::Chroma, "test")
      
      style.name.should eq("chroma-test")
      style.background.should eq(Obelisk::Color.from_hex("#ffffff"))
      
      comment_style = style.get_direct(Obelisk::TokenType::Comment)
      comment_style.should_not be_nil
      comment_style.not_nil!.color.should eq(Obelisk::Color.from_hex("#6a737d"))
      comment_style.not_nil!.italic?.should be_true

      keyword_style = style.get_direct(Obelisk::TokenType::Keyword)
      keyword_style.should_not be_nil
      keyword_style.not_nil!.color.should eq(Obelisk::Color.from_hex("#d73a49"))
      keyword_style.not_nil!.bold?.should be_true

      string_style = style.get_direct(Obelisk::TokenType::LiteralString)
      string_style.should_not be_nil
      string_style.not_nil!.color.should eq(Obelisk::Color.from_hex("#032f62"))
    end

    it "handles Chroma background with foreground color" do
      xml = <<-XML
        <style name="chroma-bg-test">
          <entry type="Background" style="#000000 bg:#ffffff"/>
        </style>
        XML

      style = Obelisk::ThemeLoader.load_from_string(xml, Obelisk::ThemeLoader::Format::Chroma, "test")
      
      style.background.should eq(Obelisk::Color.from_hex("#ffffff"))
      
      # Background entry should set Text token
      text_style = style.get_direct(Obelisk::TokenType::Text)
      text_style.should_not be_nil
      text_style.not_nil!.color.should eq(Obelisk::Color.from_hex("#000000"))
    end

    it "raises error for invalid Chroma XML" do
      expect_raises(Obelisk::ThemeError, /Invalid Chroma style/) do
        xml = <<-XML
          <theme name="wrong-root">
            <entry type="Background" style="bg:#ffffff"/>
          </theme>
          XML
        Obelisk::ThemeLoader.load_from_string(xml, Obelisk::ThemeLoader::Format::Chroma, "test")
      end
    end
  end

  describe ".detect_format" do
    it "detects JSON format for .json files with Obelisk structure" do
      File.write("test_theme.json", {
        "name" => "Test",
        "background" => "#ffffff",
        "tokens" => {} of String => String
      }.to_json)

      style = Obelisk::ThemeLoader.load("test_theme.json")
      style.name.should eq("Test")

      File.delete("test_theme.json")
    end

    it "detects Chroma format for .xml files" do
      xml = <<-XML
        <style name="xml-test">
          <entry type="Background" style="bg:#000000"/>
          <entry type="Keyword" style="#ff0000"/>
        </style>
        XML
      
      File.write("test_theme.xml", xml)

      style = Obelisk::ThemeLoader.load("test_theme.xml")
      style.name.should eq("xml-test")
      style.background.should eq(Obelisk::Color.from_hex("#000000"))

      File.delete("test_theme.xml")
    end

    it "raises error for unknown extensions" do
      expect_raises(Obelisk::ThemeError, /Unknown theme file extension/) do
        Obelisk::ThemeLoader.load("test.unknown")
      end
    end
  end

  describe "token type parsing" do
    it "maps all supported token types correctly" do
      # Test a few key mappings
      json = {
        "background" => "#ffffff",
        "tokens" => {
          "comment.single" => {"color" => "#ff0000"},
          "literal.string.double" => {"color" => "#00ff00"},
          "keyword.reserved" => {"color" => "#0000ff"},
          "name.function" => {"color" => "#ffff00"},
          "literal.number.hex" => {"color" => "#ff00ff"}
        }
      }.to_json

      style = Obelisk::ThemeLoader.load_from_string(json, Obelisk::ThemeLoader::Format::JSON, "test")
      
      style.get_direct(Obelisk::TokenType::CommentSingle).should_not be_nil
      style.get_direct(Obelisk::TokenType::LiteralStringDouble).should_not be_nil
      style.get_direct(Obelisk::TokenType::KeywordReserved).should_not be_nil
      style.get_direct(Obelisk::TokenType::NameFunction).should_not be_nil
      style.get_direct(Obelisk::TokenType::LiteralNumberHex).should_not be_nil
    end
  end
end