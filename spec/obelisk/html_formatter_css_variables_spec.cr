require "../spec_helper"

describe Obelisk::HTMLFormatter do
  describe "CSS Variables" do
    it "generates CSS with variables when use_css_variables is true" do
      formatter = Obelisk::HTMLFormatter.new(with_classes: true, use_css_variables: true)
      style = Obelisk::Style.new("test", background: Obelisk::Color.new(255, 255, 255))
      
      css = formatter.css(style)
      
      # Check for CSS variable definitions
      css.should contain("--obelisk-min-width:")
      css.should contain("--obelisk-max-width:")
      css.should contain("--obelisk-border-width:")
      css.should contain("--obelisk-font-family:")
      css.should contain("--obelisk-line-numbers-color:")
      css.should contain("--obelisk-bg:")
      
      # Check that it uses var() references
      css.should contain("var(--obelisk-")
    end
    
    it "generates CSS variables for all token types" do
      formatter = Obelisk::HTMLFormatter.new(with_classes: true, use_css_variables: true)
      style = Obelisk::Style.new("test", 
        background: Obelisk::Color.new(255, 255, 255),
        entries: {
          Obelisk::TokenType::Keyword => Obelisk::StyleEntry.new(
            color: Obelisk::Color.new(255, 0, 0)
          ),
          Obelisk::TokenType::LiteralString => Obelisk::StyleEntry.new(
            color: Obelisk::Color.new(0, 255, 0)
          )
        }
      )
      
      css = formatter.css(style)
      
      # Should generate variables for ALL token types, not just defined ones
      css.should contain("--obelisk-color-k:")  # keyword
      css.should contain("--obelisk-color-s:")  # string
      css.should contain("--obelisk-color-c:")  # comment
      css.should contain("--obelisk-color-m:")  # number
      
      # Check that CSS rules use the variables
      css.should contain(".k { color: var(--obelisk-color-k)")
      css.should contain(".s { color: var(--obelisk-color-s)")
    end
    
    it "handles token color inheritance properly" do
      formatter = Obelisk::HTMLFormatter.new(with_classes: true, use_css_variables: true)
      style = Obelisk::Style.new("test",
        background: Obelisk::Color.new(255, 255, 255),
        entries: {
          Obelisk::TokenType::Text => Obelisk::StyleEntry.new(
            color: Obelisk::Color.new(0, 0, 0)
          ),
          # Don't define Keyword color - it should inherit from Text
        }
      )
      
      css = formatter.css(style)
      
      # Should define color variable for keyword using inherited value
      css.should contain("--obelisk-color-k: #000000")
    end
    
    it "pre-registered html-css-vars formatter works correctly" do
      formatter = Obelisk::Registry.formatters.get!("html-css-vars").as(Obelisk::HTMLFormatter)
      
      formatter.@with_classes.should be_true
      formatter.@use_css_variables.should be_true
    end
    
    it "generates both legacy and CSS variable formatters" do
      # Regular HTML formatter
      regular = Obelisk::Registry.formatters.get!("html").as(Obelisk::HTMLFormatter)
      regular.@use_css_variables.should be_false
      
      # CSS variables formatter
      css_vars = Obelisk::Registry.formatters.get!("html-css-vars").as(Obelisk::HTMLFormatter)
      css_vars.@use_css_variables.should be_true
    end
  end
end