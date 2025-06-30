require "../spec_helper"

describe Obelisk::Color do
  describe ".from_hex" do
    it "parses 6-digit hex colors" do
      color = Obelisk::Color.from_hex("#ff0000")
      color.red.should eq 255
      color.green.should eq 0
      color.blue.should eq 0
    end

    it "parses 3-digit hex colors" do
      color = Obelisk::Color.from_hex("#f00")
      color.red.should eq 255
      color.green.should eq 0
      color.blue.should eq 0
    end

    it "parses hex colors without #" do
      color = Obelisk::Color.from_hex("00ff00")
      color.red.should eq 0
      color.green.should eq 255
      color.blue.should eq 0
    end
  end

  describe "#to_hex" do
    it "converts to hex string" do
      color = Obelisk::Color.new(255u8, 128u8, 64u8)
      color.to_hex.should eq "#ff8040"
    end
  end

  describe "#transparent?" do
    it "returns true for black" do
      Obelisk::Color::TRANSPARENT.transparent?.should be_true
    end

    it "returns false for non-black colors" do
      Obelisk::Color::RED.transparent?.should be_false
    end
  end

  describe "#brightness" do
    it "calculates brightness correctly" do
      Obelisk::Color::BLACK.brightness.should eq 0.0
      Obelisk::Color::WHITE.brightness.should eq 1.0
    end
  end

  describe "#brighten" do
    it "brightens the color" do
      color = Obelisk::Color.new(100u8, 100u8, 100u8)
      brighter = color.brighten(0.5)
      brighter.red.should be > color.red
      brighter.green.should be > color.green
      brighter.blue.should be > color.blue
    end
  end

  describe "#darken" do
    it "darkens the color" do
      color = Obelisk::Color.new(200u8, 200u8, 200u8)
      darker = color.darken(0.5)
      darker.red.should be < color.red
      darker.green.should be < color.green
      darker.blue.should be < color.blue
    end
  end
end

describe Obelisk::StyleEntry do
  describe "#has_styles?" do
    it "returns false for empty entry" do
      entry = Obelisk::StyleEntry.new
      entry.has_styles?.should be_false
    end

    it "returns true when color is set" do
      entry = Obelisk::StyleEntry.new(color: Obelisk::Color::RED)
      entry.has_styles?.should be_true
    end

    it "returns true when bold is set" do
      entry = Obelisk::StyleEntry.new(bold: Obelisk::Trilean::Yes)
      entry.has_styles?.should be_true
    end
  end

  describe "#merge" do
    it "merges two entries correctly" do
      entry1 = Obelisk::StyleEntry.new(color: Obelisk::Color::RED, bold: Obelisk::Trilean::Yes)
      entry2 = Obelisk::StyleEntry.new(background: Obelisk::Color::BLUE, italic: Obelisk::Trilean::Yes)
      
      merged = entry1.merge(entry2)
      merged.color.should eq Obelisk::Color::RED
      merged.background.should eq Obelisk::Color::BLUE
      merged.bold?.should be_true
      merged.italic?.should be_true
    end

    it "allows second entry to override first" do
      entry1 = Obelisk::StyleEntry.new(color: Obelisk::Color::RED)
      entry2 = Obelisk::StyleEntry.new(color: Obelisk::Color::BLUE)
      
      merged = entry1.merge(entry2)
      merged.color.should eq Obelisk::Color::BLUE
    end
  end
end

describe Obelisk::Style do
  describe "#get" do
    it "returns exact match if available" do
      style = Obelisk::Style.new("test")
      entry = Obelisk::StyleEntry.new(color: Obelisk::Color::RED)
      style.set(Obelisk::TokenType::Keyword, entry)
      
      result = style.get(Obelisk::TokenType::Keyword)
      result.color.should eq Obelisk::Color::RED
    end

    it "inherits from parent category" do
      style = Obelisk::Style.new("test")
      parent_entry = Obelisk::StyleEntry.new(color: Obelisk::Color::RED)
      style.set(Obelisk::TokenType::Keyword, parent_entry)
      
      result = style.get(Obelisk::TokenType::KeywordConstant)
      result.color.should eq Obelisk::Color::RED
    end

    it "applies Text default for unknown types" do
      style = Obelisk::Style.new("test")
      text_entry = Obelisk::StyleEntry.new(color: Obelisk::Color::BLACK)
      style.set(Obelisk::TokenType::Text, text_entry)
      
      result = style.get(Obelisk::TokenType::Error)
      result.color.should eq Obelisk::Color::BLACK
    end
  end
end

describe "Built-in Styles" do
  describe "github style" do
    it "creates GitHub style" do
      style = Obelisk::Registry.styles.get!("github")
      style.name.should eq "github"
      style.background.should eq Obelisk::Color.from_hex("#ffffff")
    end

    it "has appropriate keyword styling" do
      style = Obelisk::Registry.styles.get!("github")
      entry = style.get(Obelisk::TokenType::Keyword)
      entry.color.should eq Obelisk::Color.from_hex("#d73a49")
      entry.bold?.should be_true
    end
  end

  describe ".monokai" do
    it "creates Monokai style" do
      style = Obelisk::Registry.styles.get!("monokai")
      style.name.should eq "monokai"
      style.background.should eq Obelisk::Color.from_hex("#272822")
    end

    it "has appropriate text styling" do
      style = Obelisk::Registry.styles.get!("monokai")
      entry = style.get(Obelisk::TokenType::Text)
      entry.color.should eq Obelisk::Color.from_hex("#f8f8f2")
    end
  end
end