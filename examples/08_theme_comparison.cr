require "../src/obelisk"

# Example 08: Theme Comparison
# This example shows how different themes render the same code

# Sample code with various syntax elements
code = %q(
# Crystal web framework example
require "kemal"

class User
  include JSON::Serializable
  
  property id : Int32
  property name : String
  property email : String
  property active : Bool = true
  
  def initialize(@id, @name, @email)
  end
  
  def to_h
    {
      "id" => @id,
      "name" => @name,
      "email" => @email,
      "active" => @active
    }
  end
end

# In-memory user storage
USERS = {} of Int32 => User

# API routes
get "/api/users" do |env|
  env.response.content_type = "application/json"
  USERS.values.map(&.to_h).to_json
end

get "/api/users/:id" do |env|
  id = env.params.url["id"].to_i
  user = USERS[id]?
  
  if user
    env.response.content_type = "application/json"
    user.to_h.to_json
  else
    halt env, status_code: 404, response: "User not found"
  end
end

post "/api/users" do |env|
  user = User.from_json(env.request.body.not_nil!)
  USERS[user.id] = user
  
  env.response.status_code = 201
  env.response.content_type = "application/json"
  user.to_h.to_json
end

# Seed some data
USERS[1] = User.new(1, "Alice", "alice@example.com")
USERS[2] = User.new(2, "Bob", "bob@example.com")

Kemal.run
)

# Available themes
themes = ["github", "monokai", "bw"]

puts "=== Terminal Output Comparison ==="
themes.each do |theme|
  puts "\n### #{theme.upcase} Theme ###"
  highlighted = Obelisk.highlight(code, "crystal", "terminal", theme)
  
  # Show first 15 lines to keep output manageable
  lines = highlighted.lines
  puts lines.first(15).join('\n')
  puts "... (truncated)" if lines.size > 15
end

puts "\n=== HTML Output Comparison ==="
# Generate HTML with each theme
themes.each do |theme|
  puts "\n### #{theme.upcase} Theme ###"
  style = Obelisk.style(theme)
  next unless style
  
  formatter = Obelisk::HTMLFormatter.new(with_classes: true)
  
  # Show CSS snippet
  css = formatter.css(style)
  css_lines = css.lines.first(5)
  puts "CSS Preview:"
  puts css_lines.join
  puts "... (#{css.lines.size - 5} more lines)" if css.lines.size > 5
  
  # Show background color
  puts "Background: #{style.background.to_hex}"
end

puts "\n=== Side-by-Side Comparison HTML ==="
# Generate an HTML page showing all themes side by side
formatter = Obelisk::HTMLFormatter.new(with_classes: true)

html_parts = themes.map do |theme|
  style = Obelisk.style(theme)
  next unless style
  
  lexer = Obelisk.lexer("crystal")
  next unless lexer
  
  tokens = lexer.tokenize(code)
  highlighted = formatter.format(tokens, style)
  css = formatter.css(style)
  
  # Prefix CSS rules with theme name to avoid conflicts
  prefixed_css = css.gsub(/\.(\w+)/, ".#{theme}-\\1")
  prefixed_html = highlighted.gsub(/class="(\w+)"/, "class=\"#{theme}-\\1\"")
  
  {theme: theme, html: prefixed_html, css: prefixed_css, background: style.background.to_hex}
end.compact

comparison_html = <<-HTML
<!DOCTYPE html>
<html>
<head>
  <title>Obelisk Theme Comparison</title>
  <style>
    body {
      font-family: -apple-system, system-ui, sans-serif;
      margin: 0;
      padding: 20px;
      background: #f0f0f0;
    }
    
    h1 {
      text-align: center;
      color: #333;
      margin-bottom: 30px;
    }
    
    .themes-container {
      display: flex;
      gap: 20px;
      flex-wrap: wrap;
      justify-content: center;
    }
    
    .theme-box {
      flex: 1;
      min-width: 400px;
      max-width: 600px;
      border-radius: 8px;
      overflow: hidden;
      box-shadow: 0 2px 10px rgba(0,0,0,0.1);
    }
    
    .theme-header {
      padding: 10px 15px;
      font-weight: bold;
      text-transform: uppercase;
      background: #333;
      color: white;
    }
    
    .theme-content {
      padding: 15px;
      overflow-x: auto;
      font-family: 'Monaco', 'Consolas', monospace;
      font-size: 12px;
      line-height: 1.4;
    }
    
    /* Theme-specific styles */
#{html_parts.map { |part| part[:css].lines.map { |line| "    #{line}" }.join }.join("\n")}
  </style>
</head>
<body>
  <h1>Obelisk Syntax Highlighting - Theme Comparison</h1>
  
  <div class="themes-container">
#{html_parts.map do |part|
  <<-THEME
    <div class="theme-box">
      <div class="theme-header">#{part[:theme]} Theme</div>
      <div class="theme-content" style="background: #{part[:background]}">
        #{part[:html]}
      </div>
    </div>
  THEME
end.join("\n")}
  </div>
  
  <p style="text-align: center; margin-top: 30px; color: #666;">
    Generated with Obelisk - Crystal Syntax Highlighting Library
  </p>
</body>
</html>
HTML

puts comparison_html

puts "\n=== Theme Color Analysis ==="
# Analyze color usage in each theme
themes.each do |theme_name|
  style = Obelisk.style(theme_name)
  next unless style
  
  puts "\n#{theme_name.upcase}:"
  puts "  Background: #{style.background.to_hex}"
  
  # Count how many token types have custom styles
  styled_count = 0
  total_count = 0
  
  {% for member in Obelisk::TokenType.constants %}
    total_count += 1
    entry = style.get(Obelisk::TokenType::{{member}})
    styled_count += 1 if entry.has_styles?
  {% end %}
  
  puts "  Styled tokens: #{styled_count}/#{total_count}"
  
  # Show a few key token colors
  key_tokens = [
    {Obelisk::TokenType::Keyword, "Keywords"},
    {Obelisk::TokenType::LiteralString, "Strings"},
    {Obelisk::TokenType::Comment, "Comments"},
    {Obelisk::TokenType::NameFunction, "Functions"},
    {Obelisk::TokenType::LiteralNumber, "Numbers"}
  ]
  
  key_tokens.each do |token_type, label|
    entry = style.get(token_type)
    if entry.color
      puts "  #{label}: #{entry.color.not_nil!.to_hex}"
    end
  end
end