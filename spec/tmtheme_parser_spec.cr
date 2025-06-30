require "./spec_helper"

describe Obelisk::TmThemeParser do
  describe "#parse" do
    it "parses a basic tmTheme XML file" do
      xml_content = %{<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple Computer//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>name</key>
  <string>Test Theme</string>
  <key>settings</key>
  <array>
    <dict>
      <key>settings</key>
      <dict>
        <key>background</key>
        <string>#272822</string>
        <key>foreground</key>
        <string>#F8F8F2</string>
        <key>caret</key>
        <string>#F8F8F0</string>
        <key>selection</key>
        <string>#49483E</string>
      </dict>
    </dict>
    <dict>
      <key>name</key>
      <string>Comment</string>
      <key>scope</key>
      <string>comment</string>
      <key>settings</key>
      <dict>
        <key>foreground</key>
        <string>#75715E</string>
        <key>fontStyle</key>
        <string>italic</string>
      </dict>
    </dict>
    <dict>
      <key>name</key>
      <string>String</string>
      <key>scope</key>
      <string>string</string>
      <key>settings</key>
      <dict>
        <key>foreground</key>
        <string>#E6DB74</string>
      </dict>
    </dict>
  </array>
  <key>uuid</key>
  <string>D8D5E82E-3D5B-46B5-B38E-8C841C21347D</string>
</dict>
</plist>}

      parser = Obelisk::TmThemeParser.new(xml_content)
      style = parser.parse("test")

      style.name.should eq("Test Theme")
      style.background.should eq(Obelisk::Color.from_hex("#272822"))

      comment_style = style.get_direct(Obelisk::TokenType::Comment)
      comment_style.should_not be_nil
      comment_style.not_nil!.color.should eq(Obelisk::Color.from_hex("#75715E"))
      comment_style.not_nil!.italic?.should be_true

      string_style = style.get_direct(Obelisk::TokenType::LiteralString)
      string_style.should_not be_nil
      string_style.not_nil!.color.should eq(Obelisk::Color.from_hex("#E6DB74"))
    end

    it "handles multiple font styles" do
      xml_content = %{<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple Computer//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>name</key>
  <string>Multi Style Test</string>
  <key>settings</key>
  <array>
    <dict>
      <key>settings</key>
      <dict>
        <key>background</key>
        <string>#ffffff</string>
      </dict>
    </dict>
    <dict>
      <key>name</key>
      <string>Bold Italic Underline</string>
      <key>scope</key>
      <string>keyword</string>
      <key>settings</key>
      <dict>
        <key>foreground</key>
        <string>#ff0000</string>
        <key>fontStyle</key>
        <string>bold italic underline</string>
      </dict>
    </dict>
  </array>
</dict>
</plist>}

      parser = Obelisk::TmThemeParser.new(xml_content)
      style = parser.parse("multi_style")

      keyword_style = style.get_direct(Obelisk::TokenType::Keyword)
      keyword_style.should_not be_nil
      keyword_style.not_nil!.bold?.should be_true
      keyword_style.not_nil!.italic?.should be_true
      keyword_style.not_nil!.underline?.should be_true
    end

    it "maps complex scopes to token types" do
      xml_content = %{<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple Computer//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>name</key>
  <string>Scope Test</string>
  <key>settings</key>
  <array>
    <dict>
      <key>settings</key>
      <dict>
        <key>background</key>
        <string>#000000</string>
      </dict>
    </dict>
    <dict>
      <key>scope</key>
      <string>string.quoted.double</string>
      <key>settings</key>
      <dict>
        <key>foreground</key>
        <string>#00ff00</string>
      </dict>
    </dict>
    <dict>
      <key>scope</key>
      <string>constant.numeric.integer</string>
      <key>settings</key>
      <dict>
        <key>foreground</key>
        <string>#0000ff</string>
      </dict>
    </dict>
    <dict>
      <key>scope</key>
      <string>entity.name.function</string>
      <key>settings</key>
      <dict>
        <key>foreground</key>
        <string>#ffff00</string>
      </dict>
    </dict>
  </array>
</dict>
</plist>}

      parser = Obelisk::TmThemeParser.new(xml_content)
      style = parser.parse("scope_test")

      string_style = style.get_direct(Obelisk::TokenType::LiteralStringDouble)
      string_style.should_not be_nil
      string_style.not_nil!.color.should eq(Obelisk::Color.from_hex("#00ff00"))

      number_style = style.get_direct(Obelisk::TokenType::LiteralNumberInteger)
      number_style.should_not be_nil
      number_style.not_nil!.color.should eq(Obelisk::Color.from_hex("#0000ff"))

      function_style = style.get_direct(Obelisk::TokenType::NameFunction)
      function_style.should_not be_nil
      function_style.not_nil!.color.should eq(Obelisk::Color.from_hex("#ffff00"))
    end

    it "handles partial scope matches" do
      xml_content = %{<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple Computer//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>name</key>
  <string>Partial Match Test</string>
  <key>settings</key>
  <array>
    <dict>
      <key>settings</key>
      <dict>
        <key>background</key>
        <string>#000000</string>
      </dict>
    </dict>
    <dict>
      <key>scope</key>
      <string>comment.line.double-slash.crystal</string>
      <key>settings</key>
      <dict>
        <key>foreground</key>
        <string>#888888</string>
      </dict>
    </dict>
    <dict>
      <key>scope</key>
      <string>string.quoted.double.crystal</string>
      <key>settings</key>
      <dict>
        <key>foreground</key>
        <string>#98C379</string>
      </dict>
    </dict>
  </array>
</dict>
</plist>}

      parser = Obelisk::TmThemeParser.new(xml_content)
      style = parser.parse("partial_test")

      # Should map to CommentSingle based on "comment.line" prefix
      comment_style = style.get_direct(Obelisk::TokenType::CommentSingle)
      comment_style.should_not be_nil
      comment_style.not_nil!.color.should eq(Obelisk::Color.from_hex("#888888"))

      # Should map to LiteralStringDouble based on "string.quoted.double" prefix
      string_style = style.get_direct(Obelisk::TokenType::LiteralStringDouble)
      string_style.should_not be_nil
      string_style.not_nil!.color.should eq(Obelisk::Color.from_hex("#98C379"))
    end

    it "raises error for invalid XML" do
      expect_raises(Obelisk::ThemeError, /Invalid tmTheme/) do
        parser = Obelisk::TmThemeParser.new("<invalid>xml</invalid>")
        parser.parse("test")
      end
    end

    it "raises error for missing settings array" do
      xml_content = %{<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple Computer//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>name</key>
  <string>No Settings</string>
</dict>
</plist>}

      expect_raises(Obelisk::ThemeError, /missing 'settings' array/) do
        parser = Obelisk::TmThemeParser.new(xml_content)
        parser.parse("test")
      end
    end
  end
end