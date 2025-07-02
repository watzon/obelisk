require "../src/obelisk"

# Example: Real-world usage of CSS Variables with Obelisk

# Sample code to highlight
crystal_code = <<-'CODE'
class TodoApp
  @todos = [] of Todo
  
  def add_todo(title : String, priority = :normal)
    todo = Todo.new(title, priority)
    @todos << todo
    puts "Added: #{todo}"
  end
  
  def list_todos
    @todos.each_with_index do |todo, i|
      puts "#{i + 1}. #{todo}"
    end
  end
end
CODE

# Get lexer and formatter with CSS variables enabled
lexer = Obelisk::Registry.lexers.get!("crystal")
formatter = Obelisk::Registry.formatters.get!("html-css-vars").as(Obelisk::HTMLFormatter)  # Pre-registered formatter with CSS variables
style = Obelisk::Registry.styles.get!("github")

# Generate CSS and HTML
css = formatter.css(style)
html = formatter.format(lexer.tokenize(crystal_code), style)

# Create a complete HTML example showing practical usage
File.write("obelisk_css_vars_usage.html", <<-HTML)
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Obelisk CSS Variables - Practical Usage</title>
<style>
/* 1. Include the generated Obelisk CSS */
#{css}

/* 2. Global styles for your application */
:root {
  --app-bg-light: #ffffff;
  --app-bg-dark: #0d1117;
  --app-text-light: #24292e;
  --app-text-dark: #c9d1d9;
  --app-border-light: #e1e4e8;
  --app-border-dark: #30363d;
}

body {
  font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
  line-height: 1.6;
  margin: 0;
  padding: 20px;
  background: var(--app-bg-light);
  color: var(--app-text-light);
}

.container {
  max-width: 1200px;
  margin: 0 auto;
}

/* 3. Custom code block styling using CSS variables */
.code-block {
  margin: 20px 0;
}

.code-block .highlight {
  /* Layout customization */
  --obelisk-max-width: 100%;
  --obelisk-border-width: 1px;
  --obelisk-border-color: var(--app-border-light);
  --obelisk-border-radius: 8px;
  --obelisk-padding: 16px;
  
  /* Typography */
  --obelisk-font-family: 'Consolas', 'Monaco', 'Courier New', monospace;
  --obelisk-font-size: 14px;
  --obelisk-line-height: 1.5;
  
  /* Make it a block element */
  display: block;
  overflow-x: auto;
}

/* 4. Theme variations */
.theme-minimal .highlight {
  --obelisk-line-numbers-color: transparent;
  --obelisk-line-numbers-width: 0;
  --obelisk-line-numbers-margin-right: 0;
  --obelisk-border-width: 0;
  --obelisk-padding: 0;
}

.theme-card .highlight {
  --obelisk-border-width: 0;
  --obelisk-padding: 24px;
  --obelisk-margin: 16px 0;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);
}

.theme-terminal .highlight {
  --obelisk-bg: #1e1e1e;
  --obelisk-border-radius: 4px;
  --obelisk-padding: 20px;
  --obelisk-font-family: 'SF Mono', 'Monaco', 'Inconsolata', monospace;
  
  /* Terminal-like colors - VS Code Dark+ theme */
  --obelisk-color-keyword: #569cd6;
  --obelisk-color-k: #569cd6;
  --obelisk-color-kd: #569cd6;
  --obelisk-color-kt: #569cd6;
  
  --obelisk-color-string: #ce9178;
  --obelisk-color-s: #ce9178;
  --obelisk-color-s1: #ce9178;
  --obelisk-color-s2: #ce9178;
  --obelisk-color-sb: #ce9178;
  --obelisk-color-sc: #ce9178;
  --obelisk-color-sd: #ce9178;
  --obelisk-color-se: #d7ba7d;
  --obelisk-color-sh: #ce9178;
  --obelisk-color-si: #ce9178;
  --obelisk-color-sx: #ce9178;
  --obelisk-color-sr: #d16969;
  --obelisk-color-ss: #9cdcfe;
  
  --obelisk-color-comment: #6a9955;
  --obelisk-color-c: #6a9955;
  --obelisk-color-c1: #6a9955;
  --obelisk-color-cm: #6a9955;
  
  --obelisk-color-n: #d4d4d4;
  --obelisk-color-nf: #dcdcaa;
  --obelisk-color-nc: #4ec9b0;
  --obelisk-color-no: #9cdcfe;
  --obelisk-color-nv: #9cdcfe;
  --obelisk-color-vi: #9cdcfe;
  
  --obelisk-color-m: #b5cea8;
  --obelisk-color-mf: #b5cea8;
  --obelisk-color-mi: #b5cea8;
  --obelisk-color-mb: #b5cea8;
  --obelisk-color-mh: #b5cea8;
  
  --obelisk-color-o: #d4d4d4;
  --obelisk-color-p: #d4d4d4;
}

/* 5. Dark mode support */
@media (prefers-color-scheme: dark) {
  body {
    background: var(--app-bg-dark);
    color: var(--app-text-dark);
  }
  
  .code-block .highlight {
    --obelisk-border-color: var(--app-border-dark);
    
    /* GitHub Dark theme colors - complete set */
    --obelisk-bg: #161b22;
    
    /* Keywords */
    --obelisk-color-keyword: #ff7b72;
    --obelisk-color-k: #ff7b72;
    --obelisk-color-kd: #ff7b72;
    --obelisk-color-kt: #ff7b72;
    --obelisk-color-kc: #ff7b72;
    
    /* Strings */
    --obelisk-color-string: #a5d6ff;
    --obelisk-color-s: #a5d6ff;
    --obelisk-color-s1: #a5d6ff;
    --obelisk-color-s2: #a5d6ff;
    --obelisk-color-sb: #a5d6ff;
    --obelisk-color-sc: #a5d6ff;
    --obelisk-color-sd: #a5d6ff;
    --obelisk-color-se: #a5d6ff;
    --obelisk-color-sh: #a5d6ff;
    --obelisk-color-si: #a5d6ff;
    --obelisk-color-sx: #a5d6ff;
    --obelisk-color-sr: #a5d6ff;
    --obelisk-color-ss: #79c0ff;
    
    /* Comments */
    --obelisk-color-comment: #8b949e;
    --obelisk-color-c: #8b949e;
    --obelisk-color-c1: #8b949e;
    --obelisk-color-cm: #8b949e;
    
    /* Names */
    --obelisk-color-n: #c9d1d9;
    --obelisk-color-nf: #d2a8ff;
    --obelisk-color-nc: #f85149;
    --obelisk-color-no: #79c0ff;
    --obelisk-color-nv: #ffa657;
    --obelisk-color-vi: #ffa657;
    
    /* Numbers */
    --obelisk-color-m: #79c0ff;
    --obelisk-color-mf: #79c0ff;
    --obelisk-color-mi: #79c0ff;
    --obelisk-color-mb: #79c0ff;
    --obelisk-color-mh: #79c0ff;
    
    /* Operators and punctuation */
    --obelisk-color-o: #ff7b72;
    --obelisk-color-p: #c9d1d9;
    
    --obelisk-line-numbers-color: #6e7681;
  }
  
  .theme-card .highlight {
    box-shadow: 0 2px 8px rgba(0, 0, 0, 0.3);
  }
}

/* 6. Responsive adjustments */
@media (max-width: 768px) {
  .code-block .highlight {
    --obelisk-font-size: 12px;
    --obelisk-padding: 12px;
    --obelisk-border-radius: 4px;
  }
}

/* 7. Utility classes for quick styling */
.code-compact .highlight {
  --obelisk-font-size: 13px;
  --obelisk-line-height: 1.3;
  --obelisk-padding: 8px 12px;
}

.code-large .highlight {
  --obelisk-font-size: 16px;
  --obelisk-line-height: 1.8;
}

/* UI Components */
.example {
  margin: 40px 0;
}

.example h3 {
  margin-bottom: 10px;
}

.example p {
  color: #666;
  margin-bottom: 16px;
}

@media (prefers-color-scheme: dark) {
  .example p {
    color: #8b949e;
  }
  
  /* Fix integration example code blocks (only plain pre blocks, not Obelisk output) */
  .example > pre,
  .example h4 + pre {
    background: #161b22 !important;
    color: #c9d1d9 !important;
    border: 1px solid #30363d;
  }
  
  .example > pre code,
  .example h4 + pre code {
    color: #c9d1d9 !important;
  }
}

button {
  background: #0969da;
  color: white;
  border: none;
  padding: 8px 16px;
  border-radius: 6px;
  cursor: pointer;
  margin-right: 8px;
  font-size: 14px;
}

button:hover {
  background: #0860ca;
}

@media (prefers-color-scheme: dark) {
  button {
    background: #238636;
  }
  
  button:hover {
    background: #2ea043;
  }
}
</style>
</head>
<body>
  <div class="container">
    <h1>Obelisk CSS Variables - Practical Usage Examples</h1>
    
    <div class="example">
      <h3>Default Styling</h3>
      <p>Standard code block with border and padding customized via CSS variables:</p>
      <div class="code-block">
        #{html}
      </div>
    </div>
    
    <div class="example">
      <h3>Minimal Style</h3>
      <p>Clean, borderless code without line numbers:</p>
      <div class="code-block theme-minimal">
        #{html}
      </div>
    </div>
    
    <div class="example">
      <h3>Card Style</h3>
      <p>Code presented as a card with shadow:</p>
      <div class="code-block theme-card">
        #{html}
      </div>
    </div>
    
    <div class="example">
      <h3>Terminal Style</h3>
      <p>Terminal-like appearance with custom colors:</p>
      <div class="code-block theme-terminal">
        #{html}
      </div>
    </div>
    
    <div class="example">
      <h3>Size Variations</h3>
      <p>Compact size for inline documentation:</p>
      <div class="code-block code-compact">
        #{html}
      </div>
      
      <p style="margin-top: 20px;">Large size for presentations:</p>
      <div class="code-block code-large">
        #{html}
      </div>
    </div>
    
    <div class="example">
      <h3>Dynamic Theme Switching</h3>
      <p>Click to toggle different themes dynamically:</p>
      
      <button onclick="applyTheme('')">Default</button>
      <button onclick="applyTheme('theme-minimal')">Minimal</button>
      <button onclick="applyTheme('theme-card')">Card</button>
      <button onclick="applyTheme('theme-terminal')">Terminal</button>
      
      <div id="dynamic-code" class="code-block" style="margin-top: 16px;">
        #{html}
      </div>
    </div>
    
    <div class="example">
      <h3>Integration Tips</h3>
      <h4>1. Using with a CSS Framework (Bootstrap, Tailwind, etc.)</h4>
      <pre style="background: #f6f8fa; padding: 16px; border-radius: 6px; overflow-x: auto;"><code>&lt;div class="code-block"&gt;
  &lt;style&gt;
    .code-block .highlight {
      /* Override Obelisk defaults to match your framework */
      --obelisk-font-family: var(--bs-font-monospace);
      --obelisk-border-color: var(--bs-border-color);
      --obelisk-border-radius: var(--bs-border-radius);
    }
  &lt;/style&gt;
  &lt;!-- Your highlighted code here --&gt;
&lt;/div&gt;</code></pre>
      
      <h4>2. React/Vue/Angular Component</h4>
      <pre style="background: #f6f8fa; padding: 16px; border-radius: 6px; overflow-x: auto;"><code>// CodeBlock.jsx
export function CodeBlock({ code, theme = 'default' }) {
  const style = {
    '--obelisk-border-radius': '8px',
    '--obelisk-padding': '16px',
    ...(theme === 'dark' && {
      '--obelisk-bg': '#0d1117',
      '--obelisk-color-keyword': '#ff7b72',
      // ... other dark theme overrides
    })
  };
  
  return (
    &lt;div className="highlight" style={style}&gt;
      {/* Rendered Obelisk HTML */}
    &lt;/div&gt;
  );
}</code></pre>
      
      <h4>3. CSS-in-JS (Emotion, Styled Components)</h4>
      <pre style="background: #f6f8fa; padding: 16px; border-radius: 6px; overflow-x: auto;"><code>const StyledCodeBlock = styled.div\`
  .highlight {
    --obelisk-max-width: 100%;
    --obelisk-border-width: \${props => props.bordered ? '1px' : '0'};
    --obelisk-bg: \${props => props.theme.colors.codeBg};
    --obelisk-color-keyword: \${props => props.theme.colors.keyword};
  }
\`;</code></pre>
    </div>
  </div>
  
  <script>
    function applyTheme(theme) {
      const codeBlock = document.getElementById('dynamic-code');
      codeBlock.className = 'code-block ' + theme;
    }
  </script>
</body>
</html>
HTML

puts "Generated: obelisk_css_vars_usage.html"
puts "\nThis example demonstrates:"
puts "✓ Basic CSS variable usage"
puts "✓ Multiple theme variations"
puts "✓ Dark mode support"
puts "✓ Responsive design"
puts "✓ Dynamic theme switching"
puts "✓ Framework integration patterns"

# Also generate a minimal example for quick reference
minimal_example = <<-'CRYSTAL'
require "obelisk"

# 1. Get the CSS variables formatter
formatter = Obelisk::Registry.formatters.get!("html-css-vars")
style = Obelisk::Registry.styles.get!("github")

# 2. Generate CSS (includes variable definitions)
css = formatter.css(style)

# 3. Highlight your code
code = File.read("my_code.cr")
lexer = Obelisk::Registry.lexers.get!("crystal")
html = formatter.format(lexer.tokenize(code), style)

# 4. Use in your HTML with custom overrides
html_output = <<-HTML
<style>
  /* Include generated CSS */
  #{css}
  
  /* Customize with CSS variables */
  .highlight {
    --obelisk-max-width: 800px;
    --obelisk-border-width: 1px;
    --obelisk-border-color: #e1e4e8;
    --obelisk-border-radius: 6px;
    --obelisk-padding: 16px;
  }
  
  /* Dark mode support */
  @media (prefers-color-scheme: dark) {
    .highlight {
      --obelisk-bg: #0d1117;
      --obelisk-border-color: #30363d;
      
      /* Override token colors for visibility */
      --obelisk-color-k: #ff7b72;
      --obelisk-color-s: #a5d6ff;
      --obelisk-color-s1: #a5d6ff;
      --obelisk-color-s2: #a5d6ff;
      --obelisk-color-ss: #79c0ff;
      --obelisk-color-si: #a5d6ff;
      --obelisk-color-c: #8b949e;
      --obelisk-color-c1: #8b949e;
      --obelisk-color-n: #c9d1d9;
      --obelisk-color-nf: #d2a8ff;
      --obelisk-color-nc: #f85149;
      --obelisk-color-no: #79c0ff;
      --obelisk-color-m: #79c0ff;
      --obelisk-color-mf: #79c0ff;
      --obelisk-color-o: #ff7b72;
      --obelisk-color-p: #c9d1d9;
    }
  }
</style>

<div class="highlight">
  #{html}
</div>
HTML
CRYSTAL

File.write("minimal_css_vars_example.cr", minimal_example)
puts "\nAlso generated: minimal_css_vars_example.cr (quick reference)"