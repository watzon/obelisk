#!/usr/bin/env crystal

# Chroma XML Theme Example
# This example demonstrates how to load, use, and export Chroma XML stylesheets.
# Chroma is the syntax highlighting library used by many Go applications.

require "../src/obelisk"

# Sample Chroma XML content (simplified VS Code Dark+ theme)
CHROMA_XML = <<-XML
<style name="VSCode Dark">
  <entry type="Background" style="#d4d4d4 bg:#1e1e1e"/>
  <entry type="Keyword" style="#569cd6 bold"/>
  <entry type="KeywordConstant" style="#569cd6"/>
  <entry type="KeywordDeclaration" style="#569cd6"/>
  <entry type="NameClass" style="#4ec9b0"/>
  <entry type="NameFunction" style="#dcdcaa"/>
  <entry type="NameVariable" style="#9cdcfe"/>
  <entry type="LiteralString" style="#ce9178"/>
  <entry type="LiteralStringDoc" style="#608b4e"/>
  <entry type="LiteralNumber" style="#b5cea8"/>
  <entry type="Comment" style="#6a9955 italic"/>
  <entry type="CommentSingle" style="#6a9955 italic"/>
  <entry type="CommentMultiline" style="#6a9955 italic"/>
  <entry type="Operator" style="#d4d4d4"/>
  <entry type="Punctuation" style="#d4d4d4"/>
  <entry type="Error" style="#f44747 bold"/>
</style>
XML

# Sample Crystal code to highlight
CRYSTAL_CODE = %{# Crystal example with various syntax elements
class Calculator
  def initialize(@name : String)
    @operations = [] of String
  end

  def add(a : Int32, b : Int32) : Int32
    result = a + b
    puts "Adding: \#{a} + \#{b} = \#{result}"
    result
  end

  def divide(a : Float64, b : Float64) : Float64?
    return nil if b == 0.0
    result = a / b
    puts "Dividing: \#{a} / \#{b} = \#{result}"
    result
  end

  private def log_operation(operation : String)
    @operations << operation
    puts "Operation: \#{operation}"
  end
end

# Usage example
calc = Calculator.new("Scientific")
puts calc.add(10, 5)
puts calc.divide(10.0, 3.0)}

puts "=== Chroma XML Theme Example ==="
puts

# 1. Load the Chroma XML theme
puts "1. Loading Chroma XML theme..."
style = Obelisk::ThemeLoader.load_from_string(CHROMA_XML, Obelisk::ThemeLoader::Format::Chroma, "vscode-dark")
puts "   Theme name: #{style.name}"
puts "   Background: #{style.background.to_hex}"
puts

# 2. Highlight code using the loaded theme
puts "2. Highlighting Crystal code with Chroma theme..."
highlighted = Obelisk.highlight(CRYSTAL_CODE, "crystal", "html", style.name)

# Register the loaded style so it can be used by name
Obelisk::Registry.styles.register(style)

# Generate HTML with the theme
puts "   Generated HTML (first 200 chars):"
puts "   #{highlighted[0..200]}..."
puts

# 3. Export the theme to different formats
puts "3. Exporting theme to different formats..."

# Export back to Chroma XML (round-trip test)
chroma_xml = Obelisk.export_theme_chroma(style)
puts "   Chroma XML export (first 200 chars):"
puts "   #{chroma_xml[0..200]}..."
puts

# Export to JSON format
json_export = Obelisk.export_theme_json(style, true)
puts "   JSON export (first 200 chars):"
puts "   #{json_export[0..200]}..."
puts

# Export to tmTheme format
tmtheme_export = Obelisk.export_theme_tmtheme(style)
puts "   tmTheme export (first 200 chars):"
puts "   #{tmtheme_export[0..200]}..."
puts

# 4. Demonstrate loading from file
puts "4. Saving and loading from file..."
File.write("vscode_dark.xml", chroma_xml)
loaded_style = Obelisk.load_theme("vscode_dark.xml")
puts "   Loaded theme from file: #{loaded_style.name}"
puts "   Background matches: #{loaded_style.background == style.background}"

# 5. Show some specific token colors
puts
puts "5. Token color examples from the theme:"
tokens_to_show = [
  Obelisk::TokenType::Keyword,
  Obelisk::TokenType::NameFunction,
  Obelisk::TokenType::LiteralString,
  Obelisk::TokenType::Comment,
  Obelisk::TokenType::LiteralNumber,
]

tokens_to_show.each do |token_type|
  if entry = style.get_direct(token_type)
    color = entry.color ? entry.color.not_nil!.to_hex : "inherit"
    attrs = [] of String
    attrs << "bold" if entry.bold?
    attrs << "italic" if entry.italic?
    attrs << "underline" if entry.underline?
    style_info = attrs.empty? ? "" : " (#{attrs.join(", ")})"
    puts "   #{token_type}: #{color}#{style_info}"
  end
end

# 6. Create a minimal Chroma theme example
puts
puts "6. Creating a minimal custom Chroma theme..."
minimal_theme = Obelisk::Style.new("Minimal Dark", Obelisk::Color.from_hex("#000000"))

# Set basic colors
minimal_theme.set(Obelisk::TokenType::Text, 
  Obelisk::StyleBuilder.new.color("#ffffff").build)
minimal_theme.set(Obelisk::TokenType::Keyword,
  Obelisk::StyleBuilder.new.color("#ff6b6b").bold.build)
minimal_theme.set(Obelisk::TokenType::LiteralString,
  Obelisk::StyleBuilder.new.color("#51cf66").build)
minimal_theme.set(Obelisk::TokenType::Comment,
  Obelisk::StyleBuilder.new.color("#868e96").italic.build)

# Export the minimal theme
minimal_xml = Obelisk.export_theme_chroma(minimal_theme)
puts "   Minimal theme XML:"
puts minimal_xml
puts

# Save the minimal theme
File.write("minimal_dark.xml", minimal_xml)
puts "   Saved minimal theme to minimal_dark.xml"

# 7. Show format detection
puts
puts "7. Demonstrating format auto-detection..."
auto_loaded = Obelisk.load_theme("vscode_dark.xml")
puts "   Auto-detected format: Chroma XML"
puts "   Theme name: #{auto_loaded.name}"

# Clean up
File.delete("vscode_dark.xml") if File.exists?("vscode_dark.xml")
File.delete("minimal_dark.xml") if File.exists?("minimal_dark.xml")

puts
puts "=== Chroma XML Example Complete ==="
puts
puts "Key features demonstrated:"
puts "• Loading Chroma XML stylesheets"
puts "• Using Chroma themes for syntax highlighting"
puts "• Exporting themes to multiple formats (XML, JSON, tmTheme)"
puts "• Round-trip theme conversion"
puts "• Auto-detection of Chroma XML format"
puts "• Creating custom Chroma themes programmatically"
puts
puts "Chroma XML format supports:"
puts "• Colors (foreground and background)"
puts "• Font styles (bold, italic, underline)"
puts "• Comprehensive token type mapping"
puts "• Compatible with Go's Chroma highlighter"