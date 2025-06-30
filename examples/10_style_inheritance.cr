require "../src/obelisk"
require "../src/obelisk/styles/github_improved"

# Example demonstrating style inheritance through token hierarchy

code = <<-'CODE'
# This is a single-line comment
/* This is a
   multiline comment */

# Keywords of different types
class MyClass
  def method
    if true
      return nil
    end
  end
end

# Variables of different types
local_var = 1
@instance_var = 2
@@class_var = 3
$global_var = 4

# Strings of different types
str1 = "double quoted string"
str2 = 'single quoted string'
str3 = `backtick string`
str4 = :symbol
str5 = "string with \n escape"

# Numbers of different types
num1 = 42         # integer
num2 = 3.14       # float
num3 = 0xFF       # hex
num4 = 0b1010     # binary
num5 = 0o755      # octal
CODE

lexer = Obelisk::Registry.lexers.get!("crystal")

# Compare original GitHub style vs improved version
puts "=== Comparing Style Definitions ==="
puts "\nOriginal GitHub style entries: #{Obelisk::Registry.styles.get!("github").entries.size}"
puts "Improved GitHub style entries: #{Obelisk::Registry.styles.get!("github-improved").entries.size}"

# Show which tokens are explicitly defined vs inherited
github_style = Obelisk::Registry.styles.get!("github")
github_improved = Obelisk::Registry.styles.get!("github-improved")

puts "\n=== Token Style Comparison ==="
tokens_to_check = [
  Obelisk::TokenType::Comment,
  Obelisk::TokenType::CommentSingle,
  Obelisk::TokenType::CommentMultiline,
  Obelisk::TokenType::Keyword,
  Obelisk::TokenType::KeywordDeclaration,
  Obelisk::TokenType::KeywordType,
  Obelisk::TokenType::LiteralString,
  Obelisk::TokenType::LiteralStringDouble,
  Obelisk::TokenType::LiteralStringSingle,
  Obelisk::TokenType::LiteralNumber,
  Obelisk::TokenType::LiteralNumberInteger,
  Obelisk::TokenType::LiteralNumberFloat,
]

tokens_to_check.each do |token_type|
  original_defined = github_style.entries.has_key?(token_type)
  improved_defined = github_improved.entries.has_key?(token_type)
  
  original_style = github_style.get(token_type)
  improved_style = github_improved.get(token_type)
  
  # Check if styles are effectively the same
  same_color = original_style.color.try(&.to_hex) == improved_style.color.try(&.to_hex)
  same_style = same_color && original_style.bold? == improved_style.bold? && 
               original_style.italic? == improved_style.italic?
  
  puts "\n#{token_type}:"
  puts "  Original: #{original_defined ? "explicitly defined" : "inherited"}"
  puts "  Improved: #{improved_defined ? "explicitly defined" : "inherited"}"
  puts "  Same result: #{same_style ? "✓" : "✗"}"
end

# Generate HTML to visually compare
formatter = Obelisk::HTMLFormatter.new(
  with_classes: true,
  standalone: true
)

# Original style
html1 = formatter.format(lexer.tokenize(code), github_style)
File.write("test_original_style.html", html1)

# Improved style
html2 = formatter.format(lexer.tokenize(code), github_improved)
File.write("test_improved_style.html", html2)

puts "\n=== Generated Files ==="
puts "- test_original_style.html (using original GitHub style)"
puts "- test_improved_style.html (using inheritance-based style)"
puts "\nBoth files should look identical, demonstrating that inheritance works correctly."

# Show inheritance chain for a specific token
puts "\n=== Inheritance Chain Example ==="
token = Obelisk::TokenType::LiteralStringDouble
puts "Token: #{token}"
puts "Inheritance chain:"
current = token
while current != current.parent
  puts "  → #{current.parent}"
  current = current.parent
end

# Demonstrate custom inheritance breaking
puts "\n=== Custom Style with Inheritance Breaking ==="
custom_style = Obelisk::Style.new("custom", Obelisk::Color::WHITE).tap do |style|
  # Set base literal style
  style.set(Obelisk::TokenType::Literal, Obelisk::StyleBuilder.new.color("#808080").build)
  
  # Strings inherit from Literal
  style.set(Obelisk::TokenType::LiteralString, Obelisk::StyleBuilder.new.italic.build)
  
  # But escape sequences don't inherit (no_inherit flag)
  style.set(Obelisk::TokenType::LiteralStringEscape, 
    Obelisk::StyleBuilder.new.color("#FF0000").bold.no_inherit.build)
end

# Check inheritance
literal_style = custom_style.get(Obelisk::TokenType::Literal)
string_style = custom_style.get(Obelisk::TokenType::LiteralString)
escape_style = custom_style.get(Obelisk::TokenType::LiteralStringEscape)

puts "Literal color: #{literal_style.color.try(&.to_hex) || "none"}"
puts "String color: #{string_style.color.try(&.to_hex) || "none"} (should be #808080 inherited from Literal)"
puts "String italic: #{string_style.italic?}"
puts "Escape color: #{escape_style.color.try(&.to_hex) || "none"} (no_inherit breaks chain)"
puts "Escape inherits italic from String: #{escape_style.italic?} (should be false)"