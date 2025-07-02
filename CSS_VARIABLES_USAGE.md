# CSS Variables Usage Guide

Obelisk supports CSS variables for flexible theming without regenerating CSS. This guide shows how to use this feature.

## Quick Start

```crystal
require "obelisk"

# Use the CSS variables formatter
formatter = Obelisk::Registry.formatters.get!("html-css-vars").as(Obelisk::HTMLFormatter)
# Or create your own:
# formatter = Obelisk::HTMLFormatter.new(with_classes: true, use_css_variables: true)

style = Obelisk::Registry.styles.get!("github")
lexer = Obelisk::Registry.lexers.get!("crystal")

# Generate CSS and HTML
css = formatter.css(style)
html = formatter.format(lexer.tokenize(your_code), style)
```

## Available CSS Variables

### Layout Variables
- `--obelisk-min-width` - Minimum width (default: `auto`)
- `--obelisk-max-width` - Maximum width (default: `100%`)
- `--obelisk-margin` - Margin (default: `0`)
- `--obelisk-padding` - Padding (default: `0`)
- `--obelisk-border-width` - Border width (default: `0`)
- `--obelisk-border-style` - Border style (default: `solid`)
- `--obelisk-border-color` - Border color (default: `transparent`)
- `--obelisk-border-radius` - Border radius (default: `0`)

### Typography Variables
- `--obelisk-font-family` - Font family (default: `inherit`)
- `--obelisk-font-size` - Font size (default: `inherit`)
- `--obelisk-line-height` - Line height (default: `1.2`)
- `--obelisk-tab-size` - Tab size (default: configured tab width)

### Line Numbers
- `--obelisk-line-numbers-color` - Color (default: `#999999`)
- `--obelisk-line-numbers-bg` - Background (default: `transparent`)
- `--obelisk-line-numbers-width` - Width (default: `2em`)
- `--obelisk-line-numbers-padding` - Padding (default: `0`)
- `--obelisk-line-numbers-margin-right` - Right margin (default: `0.8em`)
- `--obelisk-line-numbers-text-align` - Text alignment (default: `right`)
- `--obelisk-line-numbers-border-right` - Right border (default: `none`)

### Code Block Styling
- `--obelisk-pre-margin` - Pre element margin (default: `0`)
- `--obelisk-pre-padding` - Pre element padding (default: `0`)
- `--obelisk-pre-bg` - Pre element background (default: `var(--obelisk-bg)`)
- `--obelisk-pre-border` - Pre element border (default: `none`)
- `--obelisk-pre-border-radius` - Pre element border radius (default: `0`)
- `--obelisk-pre-white-space` - White space handling (default: `pre` or `pre-wrap` if wrap enabled)
- `--obelisk-pre-overflow` - Overflow handling (default: `auto`)

### Highlighting
- `--obelisk-highlight-bg` - Background for highlighted lines (default: `rgba(255, 255, 0, 0.2)`)
- `--obelisk-highlight-border` - Border for highlighted lines (default: `none`)
- `--obelisk-highlight-margin` - Margin for highlighted lines (default: `0 -0.8em`)
- `--obelisk-highlight-padding` - Padding for highlighted lines (default: `0 0.8em`)

### Theme Colors
- `--obelisk-bg` - Main background color
- `--obelisk-color-{token}` - Token foreground colors
- `--obelisk-bg-{token}` - Token background colors (if any)

Token types include: `keyword`, `string`, `comment`, `number`, etc.

## Common Use Cases

### 1. Add Border and Padding

```css
.highlight {
  --obelisk-border-width: 1px;
  --obelisk-border-color: #e1e4e8;
  --obelisk-border-radius: 6px;
  --obelisk-padding: 16px;
}
```

### 2. Dark Mode Support

```css
@media (prefers-color-scheme: dark) {
  .highlight {
    --obelisk-bg: #0d1117;
    --obelisk-border-color: #30363d;
    
    /* Keywords */
    --obelisk-color-keyword: #ff7b72;
    --obelisk-color-k: #ff7b72;
    
    /* All string types */
    --obelisk-color-string: #a5d6ff;
    --obelisk-color-s: #a5d6ff;
    --obelisk-color-s1: #a5d6ff;
    --obelisk-color-s2: #a5d6ff;
    --obelisk-color-ss: #79c0ff;  /* Symbols */
    
    /* Comments */
    --obelisk-color-comment: #8b949e;
    --obelisk-color-c: #8b949e;
    --obelisk-color-c1: #8b949e;
    
    /* Names */
    --obelisk-color-n: #c9d1d9;
    --obelisk-color-nf: #d2a8ff;  /* Functions */
    --obelisk-color-nc: #f85149;  /* Classes */
    
    /* Numbers */
    --obelisk-color-m: #79c0ff;
    --obelisk-color-mf: #79c0ff;
    
    /* Operators */
    --obelisk-color-o: #ff7b72;
    --obelisk-color-p: #c9d1d9;
  }
}
```

### 3. Compact Code Blocks

```css
.code-compact .highlight {
  --obelisk-font-size: 13px;
  --obelisk-line-height: 1.3;
  --obelisk-padding: 8px;
  --obelisk-line-numbers-width: 1.5em;
}
```

### 4. Hide Line Numbers

```css
.no-line-numbers .highlight {
  --obelisk-line-numbers-width: 0;
  --obelisk-line-numbers-margin-right: 0;
}
```

### 5. Terminal Style

```css
.terminal .highlight {
  --obelisk-bg: #1e1e1e;
  --obelisk-border-radius: 4px;
  --obelisk-padding: 20px;
  --obelisk-font-family: 'Monaco', 'Consolas', monospace;
  --obelisk-color-keyword: #569cd6;
  --obelisk-color-string: #ce9178;
}
```

## Framework Integration

### Bootstrap

```html
<style>
  .highlight {
    --obelisk-border-color: var(--bs-border-color);
    --obelisk-border-radius: var(--bs-border-radius);
    --obelisk-font-family: var(--bs-font-monospace);
  }
</style>
```

### Tailwind CSS

```html
<div class="highlight" style="
  --obelisk-border-radius: 0.5rem;
  --obelisk-padding: 1rem;
  --obelisk-bg: rgb(var(--tw-bg-code));
">
  <!-- highlighted code -->
</div>
```

### React Component

```jsx
function CodeBlock({ code, dark = false }) {
  const style = {
    '--obelisk-padding': '16px',
    '--obelisk-border-radius': '8px',
    ...(dark && {
      '--obelisk-bg': '#0d1117',
      '--obelisk-color-keyword': '#ff7b72'
    })
  };
  
  return <div className="highlight" style={style} 
              dangerouslySetInnerHTML={{__html: highlightedCode}} />;
}
```

## Tips

1. **CSS Variables cascade** - You can set variables at any level (`:root`, `.highlight`, or inline)
2. **Use CSS custom properties** - Combine with your existing design system variables
3. **Override selectively** - Only override the variables you need to change
4. **Browser support** - CSS variables work in all modern browsers (IE 11 not supported)
5. **Performance** - No JavaScript required, pure CSS theming

## Full Example

See `examples/16_css_variables_usage.cr` for a complete working example with multiple themes and interactive demos.