require "../src/obelisk"

# Example 04: Multiple Language Support
# This example demonstrates syntax highlighting for different languages

puts "=== Crystal Code ==="
crystal_code = %q(
# Crystal example with various features
class Point
  getter x : Float64
  getter y : Float64

  def initialize(@x : Float64, @y : Float64)
  end

  def distance_to(other : Point) : Float64
    Math.sqrt((other.x - @x) ** 2 + (other.y - @y) ** 2)
  end
end

origin = Point.new(0.0, 0.0)
point = Point.new(3.0, 4.0)
puts "Distance: #{origin.distance_to(point)}"
)

puts Obelisk.highlight(crystal_code, "crystal", "terminal", "monokai")

puts "\n=== JSON Data ==="
json_code = %q({
  "user": {
    "id": 12345,
    "name": "Alice Smith",
    "email": "alice@example.com",
    "active": true,
    "roles": ["admin", "developer"],
    "metadata": {
      "created_at": "2023-01-15T10:30:00Z",
      "last_login": null
    }
  }
})

puts Obelisk.highlight(json_code, "json", "terminal", "github")

puts "\n=== YAML Configuration ==="
yaml_code = %q(
# Application configuration
app:
  name: "My Crystal App"
  version: 1.2.3
  environment: production

database:
  host: localhost
  port: 5432
  name: myapp_prod
  credentials: &db_creds
    username: app_user
    password: ${DB_PASSWORD}

cache:
  driver: redis
  connection:
    <<: *db_creds
    host: cache.example.com
    port: 6379

features:
  - authentication
  - api_v2
  - real_time_updates
)

puts Obelisk.highlight(yaml_code, "yaml", "terminal", "monokai")

puts "\n=== Plain Text ==="
plain_text = %q(
This is plain text without any syntax highlighting.
It will be rendered as-is, preserving formatting:
  - Indentation
  - Line breaks
  - Special characters: <>&"'

But no syntax coloring will be applied.
)

puts Obelisk.highlight(plain_text, "text", "terminal", "github")

puts "\n=== Language Detection Example ==="
# Show how to detect language based on file extension
files = {
  "app.cr"       => "crystal",
  "config.json"  => "json",
  "settings.yml" => "yaml",
  "readme.txt"   => "text",
}

files.each do |filename, expected_lang|
  # Find lexer by filename
  lexer = Obelisk::Registry.lexers.all.find do |l|
    l.matches_filename?(filename)
  end

  detected = lexer ? lexer.name : "unknown"
  status = detected == expected_lang ? "✓" : "✗"
  puts "#{status} #{filename} -> #{detected}"
end

puts "\n=== HTML Output Comparison ==="
# Generate HTML for each language
sample_code = {
  "crystal" => "def hello\n  puts \"Hello!\"\nend",
  "json"    => "{\"message\": \"Hello!\"}",
  "yaml"    => "message: Hello!\ncount: 42",
}

sample_code.each do |lang, code|
  puts "\n#{lang.upcase}:"
  html = Obelisk.highlight(code, lang, "html", "github")
  puts html
end
