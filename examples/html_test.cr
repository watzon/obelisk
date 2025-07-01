require "../src/obelisk"

# Test HTML with embedded CSS and JavaScript
html_code = <<-HTML
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Test Page</title>
    
    <style>
        /* CSS styles */
        body {
            font-family: Arial, sans-serif;
            background-color: #f0f0f0;
            margin: 0;
            padding: 20px;
        }
        
        .container {
            max-width: 800px;
            margin: 0 auto;
            background: white;
            padding: 30px;
            border-radius: 10px;
            box-shadow: 0 2px 10px rgba(0, 0, 0, 0.1);
        }
        
        h1 {
            color: #333;
            border-bottom: 2px solid #007bff;
            padding-bottom: 10px;
        }
        
        #special {
            color: #007bff;
            font-weight: bold;
        }
        
        a:hover {
            text-decoration: underline;
        }
        
        @media (max-width: 600px) {
            .container {
                padding: 15px;
            }
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>Welcome to My Page</h1>
        <p id="special">This is a special paragraph with an ID.</p>
        <p>This page demonstrates HTML with embedded CSS and JavaScript.</p>
        
        <!-- HTML Comment -->
        <p>Some HTML entities: &amp; &lt; &gt; &quot; &#169; &#x2764;</p>
        
        <button onclick="showAlert()">Click Me!</button>
        
        <script>
            // JavaScript code
            function showAlert() {
                const message = "Hello from embedded JavaScript!";
                alert(message);
            }
            
            // More complex JavaScript
            class Person {
                constructor(name, age) {
                    this.name = name;
                    this.age = age;
                }
                
                greet() {
                    return `Hello, my name is ${this.name} and I'm ${this.age} years old.`;
                }
            }
            
            const person = new Person("Alice", 30);
            console.log(person.greet());
            
            // Async function example
            async function fetchData() {
                try {
                    const response = await fetch('/api/data');
                    const data = await response.json();
                    return data;
                } catch (error) {
                    console.error('Error:', error);
                }
            }
        </script>
    </div>
</body>
</html>
HTML

# Test the HTML lexer
puts "Testing HTML lexer with embedded CSS and JavaScript:\n\n"

# Get the HTML lexer
lexer = Obelisk::Registry.lexers.get!("html")

# Tokenize the HTML
tokens = lexer.tokenize(html_code)

# Display some tokens to verify it's working
token_count = 0
token_samples = [] of String

tokens.each do |token|
  token_count += 1

  # Collect some sample tokens
  if token_count <= 50 || token.type != Obelisk::TokenType::Text
    case token.type
    when Obelisk::TokenType::NameTag
      token_samples << "TAG: #{token.value}"
    when Obelisk::TokenType::NameAttribute
      token_samples << "ATTR: #{token.value}"
    when Obelisk::TokenType::CommentMultiline
      token_samples << "COMMENT: #{token.value[0..20]}..." if token.value.size > 20
    when Obelisk::TokenType::NameClass
      token_samples << "CSS_CLASS: #{token.value}"
    when Obelisk::TokenType::NameProperty
      token_samples << "CSS_PROP: #{token.value}"
    when Obelisk::TokenType::Keyword
      token_samples << "JS_KEYWORD: #{token.value}"
    when Obelisk::TokenType::NameFunction
      token_samples << "JS_FUNC: #{token.value}"
    when Obelisk::TokenType::LiteralStringDouble, Obelisk::TokenType::LiteralStringSingle
      token_samples << "STRING: #{token.value}"
    when Obelisk::TokenType::NameEntity
      token_samples << "ENTITY: #{token.value}"
    end
  end
end

puts "Total tokens: #{token_count}\n"
puts "Sample tokens (first 50 and non-text tokens):\n"
token_samples.first(30).each do |sample|
  puts "  #{sample}"
end

# Also test highlighting
puts "\n\nHighlighted HTML (first 500 chars):"
highlighted = Obelisk.highlight(html_code[0..500], "html", "ansi")
puts highlighted
