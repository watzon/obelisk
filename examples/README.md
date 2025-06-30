# Obelisk Examples

This directory contains examples demonstrating various features of the Obelisk syntax highlighting library.

## Running Examples

All examples can be run directly with Crystal:

```bash
crystal run examples/01_basic_usage.cr
```

## Example Overview

### 01_basic_usage.cr
Basic syntax highlighting with minimal configuration. Shows how to:
- Highlight code with default settings
- Specify formatter and style
- List available components

### 02_html_output.cr
HTML output options and configurations:
- Inline styles vs CSS classes
- Custom CSS class prefixes
- Line numbers
- Complete HTML page generation

### 03_terminal_colors.cr
Terminal/ANSI color output for console applications:
- Different styles for terminal output
- Token type color examples
- Custom ANSI formatting

### 04_multi_language.cr
Support for multiple programming languages:
- Crystal syntax highlighting
- JSON data highlighting
- YAML configuration highlighting
- Language detection by filename

### 05_custom_formatter.cr
Creating custom output formatters:
- Markdown formatter
- Token list formatter
- BBCode formatter for forums
- Registering custom formatters

### 06_css_generation.cr
CSS stylesheet generation:
- Generate CSS for different styles
- Custom CSS prefixes
- Complete HTML pages with external CSS
- CSS statistics and analysis

### 07_file_highlighting.cr
Working with source files:
- Language detection from filenames
- Batch file processing
- Generating HTML files from source
- Directory processing examples

### 08_theme_comparison.cr
Comparing different syntax highlighting themes:
- Side-by-side theme comparison
- HTML comparison page generation
- Theme color analysis
- Style statistics

### 09_custom_style.cr
Creating custom syntax highlighting styles:
- Building a custom style from scratch
- Registering styles with the registry
- Using custom styles for highlighting
- Creating reusable style files

## Quick Start

For the simplest usage:

```crystal
require "obelisk"

code = "def hello\n  puts \"Hello, World!\"\nend"
highlighted = Obelisk.highlight(code, "crystal")
puts highlighted
```

## Advanced Usage

For more control, work with lexers and formatters directly:

```crystal
lexer = Obelisk.lexer("crystal")
formatter = Obelisk::HTMLFormatter.new(with_classes: true)
style = Obelisk.style("monokai")

if lexer && style
  tokens = lexer.tokenize(code)
  output = formatter.format(tokens, style)
  css = formatter.css(style)
end
```

## Creating Custom Components

- **Custom Lexer**: Extend `Obelisk::RegexLexer` and define token rules
- **Custom Formatter**: Extend `Obelisk::Formatter` and implement the `format` method
- **Custom Style**: Create an `Obelisk::Style` instance and define token colors

See example 05 for custom formatter implementation.