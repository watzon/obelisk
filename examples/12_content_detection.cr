require "../src/obelisk"

# Example 12: Content-based Language Detection
# This example demonstrates automatic language detection from code content

# Sample code snippets in different languages
crystal_code = %q(
require "http/server"

class HelloWorld
  def initialize(@name : String)
  end

  def greet
    puts "Hello, #{@name}!"
  end
end

server = HTTP::Server.new do |context|
  context.response.content_type = "text/plain"
  context.response.print "Hello world!"
end

server.bind_tcp 8080
server.listen
)

json_code = %q({
  "name": "obelisk",
  "version": "0.1.0",
  "description": "A syntax highlighting library",
  "keywords": ["syntax", "highlighting", "lexer"],
  "dependencies": {
    "crystal": "^1.0.0"
  },
  "scripts": {
    "test": "crystal spec",
    "build": "crystal build src/obelisk.cr"
  }
})

yaml_code = %q(---
name: obelisk
version: 0.1.0
description: A syntax highlighting library
keywords:
  - syntax
  - highlighting
  - lexer
dependencies:
  crystal: ^1.0.0
scripts:
  test: crystal spec
  build: crystal build src/obelisk.cr
)

ambiguous_code = %q(
# Configuration
name: example
type: service
enabled: true
port: 8080
)

puts "=== Content-based Language Detection ==="

# Test each code snippet
samples = {
  "Crystal code"   => crystal_code,
  "JSON code"      => json_code,
  "YAML code"      => yaml_code,
  "Ambiguous code" => ambiguous_code,
}

samples.each do |name, code|
  puts "\n--- #{name} ---"

  # Try to detect the language
  if detected_lexer = Obelisk::Registry.lexers.analyze(code)
    puts "Detected language: #{detected_lexer.name}"

    # Show the confidence scores from each lexer
    puts "\nConfidence scores:"
    Obelisk::Registry.lexers.all.each do |lexer|
      score = lexer.analyze(code)
      if score > 0
        puts "  #{lexer.name}: #{(score * 100).round(1)}%"
      end
    end

    # Highlight with detected language
    highlighted = Obelisk.highlight(code, detected_lexer.name, "terminal", "github")
    puts "\nHighlighted output:"
    puts highlighted
  else
    puts "Could not detect language (scores too low)"

    # Show all scores anyway
    puts "\nAll scores:"
    Obelisk::Registry.lexers.all.each do |lexer|
      score = lexer.analyze(code)
      puts "  #{lexer.name}: #{(score * 100).round(1)}%"
    end
  end
end

puts "\n=== Using detect_language from Quick module ==="

# Demonstrate the Quick module's detect_language method
if lang = Obelisk::Quick.detect_language(crystal_code)
  puts "Quick.detect_language identified: #{lang}"
else
  puts "Quick.detect_language could not identify the language"
end

puts "\n=== Language Detection with Mixed Content ==="

# Test with code that could be multiple languages
mixed_code = %q(
def process(data)
  return {
    "status": "ok",
    "count": data.size,
    "items": data.map { |x| x * 2 }
  }
end
)

puts "\nMixed code that could be Ruby or Crystal:"
if detected = Obelisk::Registry.lexers.analyze(mixed_code)
  puts "Detected as: #{detected.name}"

  # Show why it was detected as that language
  puts "\nAnalysis breakdown:"
  Obelisk::Registry.lexers.all.each do |lexer|
    score = lexer.analyze(mixed_code)
    if score > 0
      puts "  #{lexer.name}: #{(score * 100).round(1)}%"
    end
  end
end

puts "\n=== Practical Use Case: Auto-detect and Highlight ==="

# Function to auto-detect and highlight
def auto_highlight(code : String, formatter = "terminal", style = "github")
  if lexer = Obelisk::Registry.lexers.analyze(code)
    puts "Auto-detected: #{lexer.name}"
    Obelisk.highlight(code, lexer.name, formatter, style)
  else
    puts "Using plain text fallback"
    Obelisk.highlight(code, "text", formatter, style)
  end
end

# Test with various snippets
test_snippet = %q(
{
  "users": [
    {"id": 1, "name": "Alice"},
    {"id": 2, "name": "Bob"}
  ]
}
)

puts "\nAuto-highlighting JSON:"
result = auto_highlight(test_snippet)
puts result
