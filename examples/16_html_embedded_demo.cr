require "../src/obelisk"

# Demonstrate HTML lexer with embedded CSS and JavaScript

html = <<-HTML
<!DOCTYPE html>
<html>
<head>
    <style>
        /* CSS in style tag */
        body { 
            background: #f0f0f0; 
            font-family: Arial, sans-serif;
        }
        
        .highlight { 
            color: #ff6b6b;
            font-weight: bold;
        }
        
        #main:hover {
            transform: scale(1.1);
            transition: all 0.3s ease;
        }
        
        @media (max-width: 600px) {
            body { font-size: 14px; }
        }
    </style>
</head>
<body>
    <h1 class="highlight">HTML with Embedded Languages</h1>
    
    <!-- HTML comment -->
    <p>This demonstrates &lt;HTML&gt; with embedded CSS and JavaScript.</p>
    
    <div id="main">
        <p>HTML entities: &amp; &copy; &#169; &#x2764;</p>
    </div>
    
    <script>
        // JavaScript in script tag
        const greeting = "Hello, World!";
        console.log(greeting);
        
        class Demo {
            constructor(name) {
                this.name = name;
            }
            
            greet() {
                return `Hello from ${this.name}!`;
            }
        }
        
        const demo = new Demo("Obelisk");
        document.getElementById('main').innerHTML += demo.greet();
    </script>
    
    <!-- Inline styles and scripts -->
    <button style="background: blue; color: white;" onclick="alert('Clicked!')">
        Click Me
    </button>
</body>
</html>
HTML

# Highlight with different themes and formats
puts "HTML with Embedded CSS and JavaScript Demo"
puts "=" * 60

# 1. Show with GitHub theme
puts "\n1. GitHub Theme (Light):"
puts "-" * 40
github_html = Obelisk.highlight(html, "html", "html", "github")
# Show just the style part
style_section = github_html.match(/<style>.*?<\/style>/m)
if style_section
  puts "CSS Section Preview:"
  puts style_section[0][0..300] + "..."
end

# 2. Show with Monokai theme
puts "\n\n2. Monokai Theme (Dark):"
puts "-" * 40
monokai_ansi = Obelisk.highlight(html[0..600], "html", "ansi", "monokai")
puts monokai_ansi

# 3. Analyze tokens in each embedded section
puts "\n\n3. Token Analysis by Section:"
puts "-" * 40

lexer = Obelisk::Registry.lexers.get!("html")
tokens = lexer.tokenize(html).to_a

# Track what section we're in
in_style = false
in_script = false
style_tokens = 0
script_tokens = 0
html_tokens = 0

tokens.each do |token|
  if token.type == Obelisk::TokenType::NameTag
    case token.value.downcase
    when "<style", "<style>"
      in_style = true
    when "</style>"
      in_style = false
    when "<script", "<script>"
      in_script = true
    when "</script>"
      in_script = false
    end
  end

  if in_style
    style_tokens += 1
  elsif in_script
    script_tokens += 1
  else
    html_tokens += 1
  end
end

puts "HTML tokens: #{html_tokens}"
puts "CSS tokens (in <style>): #{style_tokens}"
puts "JavaScript tokens (in <script>): #{script_tokens}"
puts "Total tokens: #{tokens.size}"

# 4. Show specific token types found
puts "\n\n4. Token Types Found:"
puts "-" * 40

token_types = tokens.map(&.type).uniq.sort_by(&.to_s)
css_types = [] of Obelisk::TokenType
js_types = [] of Obelisk::TokenType
html_types = [] of Obelisk::TokenType

token_types.each do |type|
  case type
  when .name_property?, .name_class?, .keyword_pseudo?
    css_types << type
  when .keyword?, .name_function?, .literal_string_backtick?, .literal_string_interpol?
    js_types << type
  when .name_tag?, .name_attribute?, .name_entity?, .comment_preproc?
    html_types << type
  end
end

puts "HTML-specific tokens: #{html_types.join(", ")}"
puts "CSS-specific tokens: #{css_types.join(", ")}"
puts "JS-specific tokens: #{js_types.join(", ")}"

# 5. Show inline style/script handling
puts "\n\n5. Inline Attributes:"
puts "-" * 40

inline_style = tokens.find { |t| t.value.includes?("background: blue") }
inline_script = tokens.find { |t| t.value.includes?("alert('Clicked!')") }

puts "Found inline style: #{inline_style.try(&.value).try(&.inspect) || "not found"}"
puts "Found inline script: #{inline_script.try(&.value).try(&.inspect) || "not found"}"
