require "../src/obelisk"

# This example demonstrates theme serialization and deserialization features

puts "=== Obelisk Theme Serialization Demo ==="
puts

# 1. Load an existing theme
puts "1. Loading existing Monokai theme:"
monokai = Obelisk.style("monokai")
if monokai
  puts "   Theme loaded: #{monokai.name}"
  puts "   Background: #{monokai.background.to_hex}"
  puts
else
  puts "   Error: Monokai theme not found"
  exit 1
end

# 2. Export to JSON format
puts "2. Exporting to JSON format:"
json_export = Obelisk.export_theme_json(monokai, pretty: true)
puts "   JSON size: #{json_export.size} characters"
puts "   First few lines:"
json_export.lines[0..5].each_with_index do |line, i|
  puts "   #{i + 1}: #{line}"
end
puts "   ..."
puts

# 3. Export to tmTheme format
puts "3. Exporting to tmTheme format:"
tmtheme_export = Obelisk.export_theme_tmtheme(monokai)
puts "   tmTheme size: #{tmtheme_export.size} characters"
puts "   First few lines:"
tmtheme_export.lines[0..3].each_with_index do |line, i|
  puts "   #{i + 1}: #{line}"
end
puts "   ..."
puts

# 4. Save themes to files
puts "4. Saving themes to files:"
begin
  Obelisk.save_theme(monokai, "monokai_export.json")
  puts "   ✓ Saved to monokai_export.json"
  
  Obelisk.save_theme(monokai, "monokai_export.tmtheme")
  puts "   ✓ Saved to monokai_export.tmtheme"
rescue ex
  puts "   ✗ Error saving: #{ex.message}"
end
puts

# 5. Load theme from JSON
puts "5. Loading theme from JSON file:"
begin
  if File.exists?("monokai_export.json")
    loaded_theme = Obelisk.load_theme("monokai_export.json")
    puts "   ✓ Loaded theme: #{loaded_theme.name}"
    puts "   Background: #{loaded_theme.background.to_hex}"
    
    # Test that styles are preserved
    comment_style = loaded_theme.get(Obelisk::TokenType::Comment)
    if comment_style
      puts "   Comment color: #{comment_style.color.try(&.to_hex) || "none"}"
    end
  else
    puts "   ✗ JSON file not found"
  end
rescue ex
  puts "   ✗ Error loading: #{ex.message}"
end
puts

# 6. Create a custom theme and export it
puts "6. Creating custom theme:"
custom_theme = Obelisk::Style.new("My Custom Theme", Obelisk::Color.from_hex("#1a1a1a"))

# Add some custom styles
custom_theme.set(Obelisk::TokenType::Text,
  Obelisk::StyleBuilder.new
    .color("#e0e0e0")
    .build)

custom_theme.set(Obelisk::TokenType::Comment,
  Obelisk::StyleBuilder.new
    .color("#7c7c7c")
    .italic
    .build)

custom_theme.set(Obelisk::TokenType::Keyword,
  Obelisk::StyleBuilder.new
    .color("#569cd6")
    .bold
    .build)

custom_theme.set(Obelisk::TokenType::LiteralString,
  Obelisk::StyleBuilder.new
    .color("#ce9178")
    .build)

custom_theme.set(Obelisk::TokenType::LiteralNumber,
  Obelisk::StyleBuilder.new
    .color("#b5cea8")
    .build)

custom_theme.set(Obelisk::TokenType::NameFunction,
  Obelisk::StyleBuilder.new
    .color("#dcdcaa")
    .build)

puts "   ✓ Created custom theme: #{custom_theme.name}"
puts "   Background: #{custom_theme.background.to_hex}"

# Export custom theme
begin
  Obelisk.save_theme(custom_theme, "custom_theme.json")
  puts "   ✓ Saved custom theme to custom_theme.json"
  
  Obelisk.save_theme(custom_theme, "custom_theme.tmtheme")
  puts "   ✓ Saved custom theme to custom_theme.tmtheme"
rescue ex
  puts "   ✗ Error saving custom theme: #{ex.message}"
end
puts

# 7. Test the custom theme by highlighting some code
puts "7. Testing custom theme with code highlighting:"
sample_code = <<-CRYSTAL
# A simple Crystal function
def fibonacci(n : Int32) : Int32
  if n <= 1
    return n
  else
    return fibonacci(n - 1) + fibonacci(n - 2)
  end
end

puts fibonacci(10)  # Output: 55
CRYSTAL

# Register the custom theme
Obelisk::Registry.styles.register(custom_theme)

# Highlight using the custom theme
highlighted = Obelisk.highlight(sample_code, "crystal", "html", "My Custom Theme")
puts "   ✓ Code highlighted with custom theme"
puts "   HTML size: #{highlighted.size} characters"
puts

# 8. Theme format conversion
puts "8. Theme format conversion:"
if File.exists?("custom_theme.json")
  puts "   JSON → tmTheme conversion:"
  
  # Load from JSON
  json_theme = Obelisk.load_theme("custom_theme.json")
  puts "   ✓ Loaded from JSON: #{json_theme.name}"
  
  # Export to tmTheme
  tmtheme_content = Obelisk.export_theme_tmtheme(json_theme)
  File.write("converted_theme.tmtheme", tmtheme_content)
  puts "   ✓ Converted and saved as converted_theme.tmTheme"
  
  # Verify the conversion
  if File.exists?("converted_theme.tmtheme")
    file_size = File.size("converted_theme.tmtheme")
    puts "   File size: #{file_size} bytes"
  end
end
puts

# 9. Load and test a tmTheme file
puts "9. Loading tmTheme file:"
if File.exists?("custom_theme.tmtheme")
  begin
    tmtheme_loaded = Obelisk.load_theme("custom_theme.tmtheme")
    puts "   ✓ Loaded tmTheme: #{tmtheme_loaded.name}"
    puts "   Background: #{tmtheme_loaded.background.to_hex}"
    
    # Compare with original
    if tmtheme_loaded.background == custom_theme.background
      puts "   ✓ Background color preserved"
    else
      puts "   ⚠ Background color differs"
    end
  rescue ex
    puts "   ✗ Error loading tmTheme: #{ex.message}"
  end
end
puts

# Cleanup
puts "Cleaning up temporary files..."
["monokai_export.json", "monokai_export.tmtheme", 
 "custom_theme.json", "custom_theme.tmtheme", 
 "converted_theme.tmtheme"].each do |file|
  if File.exists?(file)
    File.delete(file)
    puts "   Deleted #{file}"
  end
end

puts
puts "=== Demo Complete ==="
puts
puts "Key features demonstrated:"
puts "• Export themes to JSON and tmTheme formats"
puts "• Load themes from files with auto-format detection"
puts "• Create custom themes programmatically"
puts "• Convert between theme formats"
puts "• Preserve styling attributes during serialization"