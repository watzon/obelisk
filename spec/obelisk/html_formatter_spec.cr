require "../spec_helper"

describe Obelisk::HTMLFormatter do
  describe "line highlighting" do
    it "highlights specified lines" do
      formatter = Obelisk::HTMLFormatter.new(
        with_classes: true,
        with_line_numbers: true,
        highlight_lines: Set{2, 3}
      )

      tokens = [
        Obelisk::Token.new(Obelisk::TokenType::Keyword, "def"),
        Obelisk::Token.new(Obelisk::TokenType::TextWhitespace, " "),
        Obelisk::Token.new(Obelisk::TokenType::Name, "foo"),
        Obelisk::Token.new(Obelisk::TokenType::TextWhitespace, "\n"),
        Obelisk::Token.new(Obelisk::TokenType::TextWhitespace, "  "),
        Obelisk::Token.new(Obelisk::TokenType::LiteralNumber, "42"),
        Obelisk::Token.new(Obelisk::TokenType::TextWhitespace, "\n"),
        Obelisk::Token.new(Obelisk::TokenType::Keyword, "end"),
      ].each

      style = Obelisk::Styles::GITHUB
      output = formatter.format(tokens, style)

      output.should contain("<span class=\"line highlighted\">")
      output.should contain("2</span>")
      output.should contain("3</span>")
    end

    it "adds line anchors when enabled" do
      formatter = Obelisk::HTMLFormatter.new(
        with_classes: true,
        with_line_numbers: true,
        line_anchors: true
      )

      tokens = [
        Obelisk::Token.new(Obelisk::TokenType::Keyword, "def"),
        Obelisk::Token.new(Obelisk::TokenType::TextWhitespace, " "),
        Obelisk::Token.new(Obelisk::TokenType::Name, "foo"),
      ].each

      style = Obelisk::Styles::GITHUB
      output = formatter.format(tokens, style)

      output.should contain("<a id=\"L1\" href=\"#L1\">1</a>")
    end

    it "generates CSS for highlighted lines" do
      formatter = Obelisk::HTMLFormatter.new(with_classes: true)
      style = Obelisk::Styles::GITHUB
      css = formatter.css(style)

      css.should contain(".line.highlighted")
      css.should contain("background-color: rgba(255, 255, 0, 0.2)")
    end
  end

  describe "basic formatting" do
    it "formats tokens with inline styles" do
      formatter = Obelisk::HTMLFormatter.new(with_classes: false)
      tokens = [
        Obelisk::Token.new(Obelisk::TokenType::Keyword, "def"),
        Obelisk::Token.new(Obelisk::TokenType::TextWhitespace, " "),
        Obelisk::Token.new(Obelisk::TokenType::Name, "hello"),
      ].each

      style = Obelisk::Styles::GITHUB
      output = formatter.format(tokens, style)

      output.should contain("<div class=\"highlight\">")
      output.should contain("<pre>")
      output.should contain("style=")
    end

    it "formats tokens with CSS classes" do
      formatter = Obelisk::HTMLFormatter.new(with_classes: true)
      tokens = [
        Obelisk::Token.new(Obelisk::TokenType::Keyword, "def"),
        Obelisk::Token.new(Obelisk::TokenType::TextWhitespace, " "),
        Obelisk::Token.new(Obelisk::TokenType::NameFunction, "hello"),
      ].each

      style = Obelisk::Styles::GITHUB
      output = formatter.format(tokens, style)

      output.should contain("<span class=\"k\">")
      output.should contain("<span class=\"nf\">")
      output.should_not contain("style=")
    end
  end
end
