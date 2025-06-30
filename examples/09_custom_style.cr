require "../src/obelisk"

# Example 09: Creating a Custom Style
# This example shows how to create and register your own syntax highlighting style

# Create a custom "ocean" style with blue/green colors
ocean_style = Obelisk::Style.new("ocean", Obelisk::Color.from_hex("#001f3f")).tap do |style|
  # Base text color - light blue
  style.set(Obelisk::TokenType::Text, Obelisk::StyleBuilder.new.color("#7FDBFF").build)
  
  # Errors - bright red
  style.set(Obelisk::TokenType::Error, Obelisk::StyleBuilder.new.color("#FF4136").build)
  
  # Comments - muted aqua
  style.set(Obelisk::TokenType::Comment, Obelisk::StyleBuilder.new.color("#39CCCC").italic.build)
  
  # Keywords - bright blue
  style.set(Obelisk::TokenType::Keyword, Obelisk::StyleBuilder.new.color("#0074D9").bold.build)
  style.set(Obelisk::TokenType::KeywordType, Obelisk::StyleBuilder.new.color("#0074D9").build)
  
  # Names and functions - green
  style.set(Obelisk::TokenType::Name, Obelisk::StyleBuilder.new.color("#7FDBFF").build)
  style.set(Obelisk::TokenType::NameClass, Obelisk::StyleBuilder.new.color("#2ECC40").bold.build)
  style.set(Obelisk::TokenType::NameFunction, Obelisk::StyleBuilder.new.color("#2ECC40").build)
  
  # Strings - yellow
  style.set(Obelisk::TokenType::LiteralString, Obelisk::StyleBuilder.new.color("#FFDC00").build)
  
  # Numbers - orange
  style.set(Obelisk::TokenType::LiteralNumber, Obelisk::StyleBuilder.new.color("#FF851B").build)
  
  # Operators and punctuation
  style.set(Obelisk::TokenType::Operator, Obelisk::StyleBuilder.new.color("#7FDBFF").build)
  style.set(Obelisk::TokenType::Punctuation, Obelisk::StyleBuilder.new.color("#7FDBFF").build)
end

# Register the custom style
Obelisk::Registry.styles.register(ocean_style)

# Now we can use it!
code = %q(
# Ocean-themed syntax highlighting
class Wave
  def initialize(@amplitude : Float64, @frequency : Float64)
  end
  
  def height_at(time : Float64) : Float64
    @amplitude * Math.sin(2 * Math::PI * @frequency * time)
  end
end

wave = Wave.new(1.5, 0.5)
puts "Wave height at t=1: #{wave.height_at(1.0)}"
)

puts "=== Ocean Style (Terminal) ==="
highlighted = Obelisk.highlight(code, "crystal", "terminal", "ocean")
puts highlighted

puts "\n=== Ocean Style (HTML) ==="
html = Obelisk.highlight(code, "crystal", "html", "ocean")
puts html

puts "\n=== List All Available Styles ==="
puts "Available styles: #{Obelisk.style_names.join(", ")}"

# You can also save a custom style to a file for reuse
puts "\n=== Creating a Reusable Style File ==="
puts "To make this style permanent, create a file at:"
puts "  src/obelisk/styles/ocean.cr"
puts "\nWith this content:"
puts <<-CRYSTAL
require "../style"

module Obelisk::Styles
  OCEAN = Style.new("ocean", Color.from_hex("#001f3f")).tap do |style|
    # ... style definitions here ...
  end
end

# Register the style
Obelisk::Registry.styles.register(Obelisk::Styles::OCEAN)
CRYSTAL