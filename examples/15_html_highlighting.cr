require "../src/obelisk"

# Example of HTML syntax highlighting with embedded CSS and JavaScript

html_code = <<-HTML
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Obelisk HTML Example</title>
    
    <!-- CSS styles -->
    <style type="text/css">
        /* Reset styles */
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }
        
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            line-height: 1.6;
            color: #333;
            background-color: #f4f4f4;
        }
        
        /* Header styles */
        .header {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            padding: 2rem 0;
            text-align: center;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
        }
        
        .header h1 {
            font-size: 2.5rem;
            margin-bottom: 0.5rem;
        }
        
        /* Container */
        .container {
            max-width: 1200px;
            margin: 0 auto;
            padding: 0 20px;
        }
        
        /* Button styles */
        .btn {
            display: inline-block;
            padding: 10px 20px;
            background-color: #007bff;
            color: white;
            text-decoration: none;
            border-radius: 5px;
            transition: background-color 0.3s ease;
        }
        
        .btn:hover {
            background-color: #0056b3;
        }
        
        /* Pseudo-elements */
        .feature::before {
            content: "✓ ";
            color: #28a745;
            font-weight: bold;
        }
        
        /* Media queries */
        @media (max-width: 768px) {
            .header h1 {
                font-size: 2rem;
            }
            
            .container {
                padding: 0 10px;
            }
        }
        
        /* Animations */
        @keyframes fadeIn {
            from {
                opacity: 0;
                transform: translateY(20px);
            }
            to {
                opacity: 1;
                transform: translateY(0);
            }
        }
        
        .fade-in {
            animation: fadeIn 0.5s ease-out;
        }
    </style>
</head>
<body>
    <header class="header">
        <div class="container">
            <h1>Welcome to Obelisk</h1>
            <p>A powerful syntax highlighting library for Crystal</p>
        </div>
    </header>
    
    <main class="container">
        <section id="features">
            <h2>Features</h2>
            <ul>
                <li class="feature">Fast and efficient tokenization</li>
                <li class="feature">Support for 10+ programming languages</li>
                <li class="feature">Multiple output formats (HTML, ANSI, etc.)</li>
                <li class="feature">Embedded language support</li>
            </ul>
        </section>
        
        <!-- HTML entities and special characters -->
        <section>
            <h2>Special Characters</h2>
            <p>HTML entities: &amp; &lt; &gt; &quot; &apos; &copy; &#169; &#x00A9;</p>
            <p>Emojis via entities: &#128512; &#x1F600; &#10084;</p>
        </section>
        
        <!-- Interactive elements -->
        <section>
            <h2>Interactive Demo</h2>
            <button id="demo-btn" class="btn" onclick="showDemo()">Click for Demo</button>
            <div id="demo-output"></div>
        </section>
    </main>
    
    <!-- JavaScript -->
    <script>
        // Modern JavaScript with ES6+ features
        const APP_CONFIG = {
            name: 'Obelisk Demo',
            version: '1.0.0',
            features: ['highlighting', 'themes', 'languages']
        };
        
        // Arrow functions and template literals
        const showDemo = () => {
            const output = document.getElementById('demo-output');
            const message = `Hello from ${APP_CONFIG.name} v${APP_CONFIG.version}!`;
            
            output.innerHTML = `
                <div class="fade-in" style="margin-top: 20px; padding: 20px; background: #e9ecef; border-radius: 5px;">
                    <h3>${message}</h3>
                    <p>Features: ${APP_CONFIG.features.join(', ')}</p>
                    <p>Timestamp: ${new Date().toLocaleString()}</p>
                </div>
            `;
        };
        
        // Classes and async/await
        class SyntaxHighlighter {
            constructor(options = {}) {
                this.theme = options.theme || 'github';
                this.language = options.language || 'auto';
                this.lineNumbers = options.lineNumbers ?? true;
            }
            
            async highlight(code) {
                try {
                    // Simulated API call
                    const response = await this.fetchHighlightedCode(code);
                    return response;
                } catch (error) {
                    console.error('Highlighting failed:', error);
                    return this.fallbackHighlight(code);
                }
            }
            
            async fetchHighlightedCode(code) {
                // Simulated delay
                return new Promise((resolve) => {
                    setTimeout(() => {
                        resolve(`<pre class="highlighted">${this.escapeHtml(code)}</pre>`);
                    }, 100);
                });
            }
            
            escapeHtml(text) {
                const map = {
                    '&': '&amp;',
                    '<': '&lt;',
                    '>': '&gt;',
                    '"': '&quot;',
                    "'": '&#39;'
                };
                return text.replace(/[&<>"']/g, m => map[m]);
            }
            
            fallbackHighlight(code) {
                return `<pre>${this.escapeHtml(code)}</pre>`;
            }
        }
        
        // Initialize on DOM ready
        document.addEventListener('DOMContentLoaded', () => {
            console.log('Page loaded!');
            
            // Create highlighter instance
            const highlighter = new SyntaxHighlighter({
                theme: 'monokai',
                lineNumbers: true
            });
            
            // Example usage
            const codeExample = 'console.log("Hello, World!");';
            highlighter.highlight(codeExample).then(result => {
                console.log('Highlighted:', result);
            });
        });
        
        // Regular expressions and advanced patterns
        const patterns = {
            email: /^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+.[a-zA-Z]{2,}$/,
            url: /https?://(www.)?[-a-zA-Z0-9@:%._+~#=]{1,256}.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_+.~#?&//=]*)/,
            hex: /#([A-Fa-f0-9]{6}|[A-Fa-f0-9]{3})/
        };
        
        // Destructuring and spread syntax
        const { email, url } = patterns;
        const allPatterns = { ...patterns, phone: /d{3}-d{3}-d{4}/ };
        
        // Generator function
        function* idGenerator() {
            let id = 1;
            while (true) {
                yield id++;
            }
        }
        
        const gen = idGenerator();
        console.log(gen.next().value); // 1
        console.log(gen.next().value); // 2
    </script>
</body>
</html>
HTML

# Demonstrate different output formats
puts "HTML Syntax Highlighting Examples\n"
puts "=" * 50

# 1. HTML format with Monokai theme
puts "\n1. HTML format (Monokai theme):"
puts "-" * 30
html_output = Obelisk.highlight(html_code[0..800], "html", "html", "monokai")
puts html_output[0..500] + "..."

# 2. ANSI format for terminal
puts "\n\n2. ANSI format (terminal colors):"
puts "-" * 30
ansi_output = Obelisk.highlight(html_code[0..800], "html", "ansi")
puts ansi_output

# 3. Show token counts for different sections
puts "\n\n3. Token Analysis:"
puts "-" * 30

lexer = Obelisk::Registry.lexers.get!("html")
tokens = lexer.tokenize(html_code).to_a

# Count tokens by type
token_counts = Hash(Obelisk::TokenType, Int32).new(0)
tokens.each do |token|
  token_counts[token.type] += 1
end

# Show top token types
puts "Total tokens: #{tokens.size}"
puts "\nTop token types:"
token_counts.to_a.sort_by { |_, count| -count }.first(15).each do |type, count|
  puts "  #{type}: #{count}"
end

# 4. Extract and highlight just the CSS
puts "\n\n4. Extracted CSS highlighting:"
puts "-" * 30
css_match = html_code.match(/<style[^>]*>(.*?)<\/style>/m)
if css_match
  css_code = css_match[1]
  css_highlighted = Obelisk.highlight(css_code[0..400], "css", "ansi")
  puts css_highlighted
end

# 5. Extract and highlight just the JavaScript
puts "\n\n5. Extracted JavaScript highlighting:"
puts "-" * 30
js_match = html_code.match(/<script[^>]*>(.*?)<\/script>/m)
if js_match
  js_code = js_match[1]
  js_highlighted = Obelisk.highlight(js_code[0..400], "javascript", "ansi")
  puts js_highlighted
end
