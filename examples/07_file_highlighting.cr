require "../src/obelisk"

# Example 07: File Highlighting
# This example shows how to highlight source files

# Function to detect language from filename
def detect_language(filename : String) : String?
  lexers = Obelisk::Registry.lexers.all
  
  # Try to find a lexer that matches the filename
  lexer = lexers.find { |l| l.matches_filename?(filename) }
  lexer.try(&.name)
end

# Function to highlight a file
def highlight_file(path : String, formatter = "html", style = "github") : String?
  # Detect language from filename
  language = detect_language(path)
  
  unless language
    puts "Warning: Could not detect language for #{path}"
    return nil
  end
  
  # Read file content
  begin
    content = File.read(path)
  rescue ex
    puts "Error reading file: #{ex.message}"
    return nil
  end
  
  # Highlight the content
  Obelisk.highlight(content, language, formatter, style)
end

# Example 1: Highlight this script itself
puts "=== Highlighting This Script ==="
script_path = __FILE__
highlighted = highlight_file(script_path, "terminal", "monokai")
if highlighted
  # Show first 20 lines
  lines = highlighted.lines
  puts lines.first(20).join('\n')
  puts "... (#{lines.size - 20} more lines)" if lines.size > 20
end

# Example 2: Create sample files and highlight them
puts "\n=== Creating and Highlighting Sample Files ==="

# Create a temporary directory for examples
temp_dir = File.tempname("obelisk_examples")
Dir.mkdir(temp_dir)

# Create sample files
samples = {
  "example.cr" => %q(
class Example
  def initialize(@name : String)
  end
  
  def greet
    puts "Hello, #{@name}!"
  end
end

Example.new("Obelisk").greet
),
  "config.json" => %q({
  "name": "obelisk",
  "version": "1.0.0",
  "dependencies": {
    "crystal": "^1.0.0"
  },
  "scripts": {
    "test": "crystal spec",
    "build": "shards build"
  }
}),
  "settings.yml" => %q(
application:
  name: Obelisk
  version: 1.0.0
  
features:
  - syntax-highlighting
  - multiple-languages
  - custom-themes
  
database:
  host: localhost
  port: 5432
)
}

# Write sample files
samples.each do |filename, content|
  path = File.join(temp_dir, filename)
  File.write(path, content.strip)
  puts "\nCreated: #{path}"
end

# Highlight each file
samples.keys.each do |filename|
  path = File.join(temp_dir, filename)
  
  puts "\n### #{filename} ###"
  
  # Detect language
  language = detect_language(filename)
  puts "Detected language: #{language || "unknown"}"
  
  # Highlight with terminal colors
  highlighted = highlight_file(path, "terminal", "github")
  puts highlighted if highlighted
end

# Clean up
samples.keys.each do |filename|
  File.delete(File.join(temp_dir, filename))
end
Dir.delete(temp_dir)

# Example 3: Batch processing
puts "\n=== Batch File Processing ==="

# Simulate batch processing of multiple files
file_list = [
  "src/main.cr",
  "config/database.yml", 
  "package.json",
  "README.md",
  "data.xml"
]

puts "Language detection for common files:"
file_list.each do |file|
  language = detect_language(file)
  status = language ? "✓" : "✗"
  puts "  #{status} #{file} -> #{language || "not supported"}"
end

# Example 4: Generate HTML files for a directory
puts "\n=== Generating HTML for Source Files ==="

def generate_html_file(source_path : String, output_path : String, style = "github")
  language = detect_language(source_path)
  return false unless language
  
  begin
    content = File.read(source_path)
    formatter = Obelisk::HTMLFormatter.new(
      with_classes: true,
      with_line_numbers: true
    )
    
    lexer = Obelisk.lexer(language)
    style_obj = Obelisk.style(style)
    
    if lexer && style_obj
      tokens = lexer.tokenize(content)
      highlighted = formatter.format(tokens, style_obj)
      css = formatter.css(style_obj)
      
      html = <<-HTML
      <!DOCTYPE html>
      <html>
      <head>
        <title>#{File.basename(source_path)}</title>
        <style>
          body { 
            font-family: monospace; 
            margin: 20px;
            background: #f5f5f5;
          }
          .source-file {
            background: white;
            border: 1px solid #ddd;
            border-radius: 4px;
            padding: 10px;
          }
          h1 { 
            color: #333;
            font-size: 18px;
            margin-bottom: 10px;
          }
          #{css}
        </style>
      </head>
      <body>
        <h1>#{File.basename(source_path)}</h1>
        <div class="source-file">
          #{highlighted}
        </div>
      </body>
      </html>
      HTML
      
      File.write(output_path, html)
      return true
    end
  rescue ex
    puts "Error: #{ex.message}"
  end
  
  false
end

# Example of how you would use it
puts "\nTo generate HTML for a source file:"
puts "  generate_html_file(\"src/app.cr\", \"output/app.html\", \"monokai\")"