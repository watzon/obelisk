require "../src/obelisk"

# Example 06: CSS Generation
# This example shows how to generate CSS stylesheets for syntax highlighting

puts "=== Generate CSS for GitHub Style ==="
formatter = Obelisk::HTMLFormatter.new(with_classes: true)
github_style = Obelisk::Registry.styles.get!("github")
css = formatter.css(github_style)
puts css

puts "\n=== Generate CSS for Monokai Style ==="
monokai_style = Obelisk::Registry.styles.get!("monokai")
css = formatter.css(monokai_style)
puts css

puts "\n=== Generate CSS with Custom Prefix ==="
# Use a custom prefix to avoid CSS conflicts
formatter = Obelisk::HTMLFormatter.new(
  with_classes: true,
  class_prefix: "syntax-"
)
css = formatter.css(github_style)
puts css

puts "\n=== Complete HTML Page with External CSS ==="
# Generate a complete HTML page with separate CSS

# First, generate the CSS file content
css_content = formatter.css(github_style)

# Then generate the highlighted HTML with classes
code = %q(
require "http/server"

server = HTTP::Server.new do |context|
  context.response.content_type = "text/html"
  context.response.print <<-HTML
    <h1>Hello from Crystal!</h1>
    <p>The time is #{Time.local}</p>
  HTML
end

address = server.bind_tcp 8080
puts "Listening on http://#{address}"
server.listen
)

lexer = Obelisk.lexer("crystal")
if lexer
  tokens = lexer.tokenize(code)
  highlighted_html = formatter.format(tokens, github_style)

  # Create the complete HTML page
  html_page = <<-HTML
  <!DOCTYPE html>
  <html>
  <head>
    <meta charset="UTF-8">
    <title>Crystal Web Server Example</title>
    <style>
      body {
        font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Helvetica, Arial, sans-serif;
        line-height: 1.6;
        max-width: 900px;
        margin: 0 auto;
        padding: 20px;
        background-color: #f6f8fa;
      }
      
      h1 {
        color: #24292e;
        border-bottom: 1px solid #e1e4e8;
        padding-bottom: 0.3em;
      }
      
      .code-container {
        background-color: #ffffff;
        border: 1px solid #e1e4e8;
        border-radius: 6px;
        padding: 16px;
        overflow-x: auto;
      }
      
      /* Syntax highlighting styles */
  #{css_content.lines.map { |line| "    #{line}" }.join}
    </style>
  </head>
  <body>
    <h1>Crystal Web Server Example</h1>
    <p>Here's a simple HTTP server written in Crystal:</p>
    
    <div class="code-container">
      #{highlighted_html}
    </div>
    
    <h2>How to run:</h2>
    <ol>
      <li>Save the code to a file (e.g., <code>server.cr</code>)</li>
      <li>Run with: <code>crystal run server.cr</code></li>
      <li>Open your browser to <code>http://localhost:8080</code></li>
    </ol>
  </body>
  </html>
  HTML

  puts html_page
end

puts "\n=== Inline CSS for Email ==="
# For HTML emails, you might want inline styles
# This example shows how to create a minified version

formatter_inline = Obelisk::HTMLFormatter.new(with_classes: false)
simple_code = %q(puts "Hello, World!")

highlighted_inline = Obelisk.highlight(simple_code, "crystal", "html", "github")
email_html = <<-HTML
<div style="font-family: monospace; background-color: #f6f8fa; padding: 10px; border-radius: 4px;">
  #{highlighted_inline}
</div>
HTML

puts email_html

puts "\n=== CSS Statistics ==="
# Show information about the generated CSS
styles = ["github", "monokai", "bw"]
formatter = Obelisk::HTMLFormatter.new(with_classes: true)

styles.each do |style_name|
  style = Obelisk.style(style_name)
  next unless style

  css = formatter.css(style)
  rules = css.scan(/\.\w+\s*\{[^}]+\}/).size
  size = css.bytesize

  puts "#{style_name}:"
  puts "  Rules: #{rules}"
  puts "  Size: #{size} bytes"
  puts "  Background: #{style.background.to_hex}"
end
