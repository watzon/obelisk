require "../src/obelisk"

# Example demonstrating CSS Variables support for flexible theming

code = <<-'CODE'
# A simple Crystal web server
require "http/server"

server = HTTP::Server.new do |context|
  context.response.content_type = "text/html"
  context.response.print "Hello world! The time is #{Time.local}"
end

address = server.bind_tcp 8080
puts "Listening on http://#{address}"
server.listen
CODE

lexer = Obelisk::Registry.lexers.get!("crystal")
style = Obelisk::Registry.styles.get!("github")

# Create formatter with CSS variables enabled
formatter = Obelisk::HTMLFormatter.new(
  with_classes: true,
  use_css_variables: true,
  with_line_numbers: true
)

# Generate the CSS and HTML
css = formatter.css(style)
html = formatter.format(lexer.tokenize(code), style)

# Create an HTML document showcasing CSS variable overrides
File.write("css_variables_demo.html", <<-HTML)
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Obelisk CSS Variables Demo</title>
<style>
/* Base Obelisk CSS with Variables */
#{css}

/* Demo Styles */
body {
  font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Helvetica, Arial, sans-serif;
  line-height: 1.6;
  color: #333;
  max-width: 1200px;
  margin: 0 auto;
  padding: 2rem;
  background: #f6f8fa;
}

h1, h2, h3 {
  margin-top: 2rem;
  margin-bottom: 1rem;
}

.example {
  margin: 2rem 0;
}

.description {
  color: #666;
  margin-bottom: 1rem;
}

/* Theme Variations */
.theme-default .highlight {
  /* Default theme - no overrides needed */
}

.theme-bordered .highlight {
  --obelisk-border-width: 1px;
  --obelisk-border-color: #e1e4e8;
  --obelisk-border-radius: 6px;
  --obelisk-padding: 1rem;
  --obelisk-margin: 1rem 0;
}

.theme-dark .highlight {
  /* GitHub Dark theme colors */
  --obelisk-bg: #0d1117;
  --obelisk-color-keyword: #ff7b72;
  --obelisk-color-string: #a5d6ff;
  --obelisk-color-comment: #8b949e;
  --obelisk-color-n: #c9d1d9;
  --obelisk-color-nf: #d2a8ff;
  --obelisk-color-nc: #f85149;
  --obelisk-color-no: #79c0ff;
  --obelisk-color-si: #a5d6ff;
  --obelisk-line-numbers-color: #6e7681;
  --obelisk-highlight-bg: rgba(56, 139, 253, 0.15);
  --obelisk-border-width: 1px;
  --obelisk-border-color: #30363d;
  --obelisk-padding: 1rem;
}

.theme-compact .highlight {
  --obelisk-max-width: 600px;
  --obelisk-font-size: 14px;
  --obelisk-line-height: 1.4;
  --obelisk-padding: 0.5rem;
  --obelisk-line-numbers-width: 1.5em;
  --obelisk-line-numbers-margin-right: 0.5em;
}

.theme-no-line-numbers .highlight {
  --obelisk-line-numbers-color: transparent;
  --obelisk-line-numbers-width: 0;
  --obelisk-line-numbers-margin-right: 0;
}

/* Dark mode for the entire page */
@media (prefers-color-scheme: dark) {
  body {
    background: #0d1117;
    color: #c9d1d9;
  }
  
  .description {
    color: #8b949e;
  }
  
  /* Automatically use dark theme in dark mode */
  .theme-default .highlight {
    --obelisk-bg: #0d1117;
    --obelisk-color-keyword: #ff7b72;
    --obelisk-color-string: #a5d6ff;
    --obelisk-color-comment: #8b949e;
    --obelisk-color-n: #c9d1d9;
    --obelisk-color-nf: #d2a8ff;
    --obelisk-color-nc: #f85149;
    --obelisk-color-no: #79c0ff;
    --obelisk-color-si: #a5d6ff;
    --obelisk-line-numbers-color: #6e7681;
  }
}
</style>
</head>
<body>
  <h1>Obelisk CSS Variables Demo</h1>
  
  <p>This demo shows how CSS variables enable flexible theming without regenerating CSS.</p>
  
  <div class="example theme-default">
    <h2>Default Theme</h2>
    <p class="description">The standard GitHub light theme with no customizations.</p>
    #{html}
  </div>
  
  <div class="example theme-bordered">
    <h2>Bordered Theme</h2>
    <p class="description">Added border, border-radius, padding, and margin using CSS variables.</p>
    #{html}
  </div>
  
  <div class="example theme-dark">
    <h2>Dark Theme</h2>
    <p class="description">GitHub dark theme colors applied via CSS variable overrides.</p>
    #{html}
  </div>
  
  <div class="example theme-compact">
    <h2>Compact Theme</h2>
    <p class="description">Reduced font size, line height, and spacing for a more compact view.</p>
    #{html}
  </div>
  
  <div class="example theme-no-line-numbers">
    <h2>Hidden Line Numbers</h2>
    <p class="description">Line numbers hidden using CSS variables (no formatter changes needed).</p>
    #{html}
  </div>
  
  <h2>Available CSS Variables</h2>
  
  <h3>Layout Variables</h3>
  <ul>
    <li><code>--obelisk-min-width</code> - Minimum width of the code block</li>
    <li><code>--obelisk-max-width</code> - Maximum width of the code block</li>
    <li><code>--obelisk-margin</code> - Outer margin</li>
    <li><code>--obelisk-padding</code> - Inner padding</li>
    <li><code>--obelisk-border-width</code> - Border width</li>
    <li><code>--obelisk-border-style</code> - Border style (solid, dashed, etc.)</li>
    <li><code>--obelisk-border-color</code> - Border color</li>
    <li><code>--obelisk-border-radius</code> - Border radius for rounded corners</li>
  </ul>
  
  <h3>Typography Variables</h3>
  <ul>
    <li><code>--obelisk-font-family</code> - Font family for code</li>
    <li><code>--obelisk-font-size</code> - Font size</li>
    <li><code>--obelisk-line-height</code> - Line height</li>
    <li><code>--obelisk-tab-size</code> - Tab character width</li>
  </ul>
  
  <h3>Line Number Variables</h3>
  <ul>
    <li><code>--obelisk-line-numbers-color</code> - Line number text color</li>
    <li><code>--obelisk-line-numbers-bg</code> - Line number background color</li>
    <li><code>--obelisk-line-numbers-width</code> - Line number column width</li>
    <li><code>--obelisk-line-numbers-padding</code> - Line number padding</li>
    <li><code>--obelisk-line-numbers-margin-right</code> - Space between line numbers and code</li>
  </ul>
  
  <h3>Theme Color Variables</h3>
  <p>Each token type gets its own color variable following the pattern:</p>
  <ul>
    <li><code>--obelisk-color-{token-type}</code> - Foreground color</li>
    <li><code>--obelisk-bg-{token-type}</code> - Background color (if applicable)</li>
  </ul>
  
  <p>For example: <code>--obelisk-color-keyword</code>, <code>--obelisk-color-string</code>, etc.</p>
</body>
</html>
HTML

puts "Generated css_variables_demo.html"
puts "\nCSS Variables feature allows users to:"
puts "- Customize layout (borders, padding, margins)"
puts "- Switch between light/dark themes"
puts "- Adjust typography settings"
puts "- Hide/style line numbers"
puts "- Respond to system dark mode preference"
puts "\nAll without regenerating the CSS!"