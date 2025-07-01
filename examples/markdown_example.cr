require "../src/obelisk"

markdown_content = <<-MD
# Markdown Example

This document demonstrates the **Markdown lexer** capabilities.

## Features

- Headers (ATX style with `#`)
- **Bold text** and *italic text*
- `Inline code` formatting
- [Links to websites](https://example.com)
- ![Images](image.png)

## Code Blocks

```crystal
def fibonacci(n : Int32) : Int32
  return n if n <= 1
  fibonacci(n - 1) + fibonacci(n - 2)
end

puts fibonacci(10)
```

## Lists

1. First item
2. Second item
   - Nested bullet
   - Another nested item
3. Third item

## Tables

| Language | Extension | Type       |
|----------|-----------|------------|
| Crystal  | .cr       | Compiled   |
| Ruby     | .rb       | Interpreted|
| Markdown | .md       | Markup     |

## Blockquotes

> Markdown is a lightweight markup language
> that you can use to add formatting elements
> to plaintext text documents.

---

*That's all, folks!*
MD

puts "=== Markdown to HTML ==="
html_output = Obelisk.highlight(markdown_content, "markdown", "html", "github")
puts html_output

puts "\n=== Token Analysis ==="
lexer = Obelisk.lexer("markdown")
if lexer
  tokens = lexer.tokenize(markdown_content).to_a
  puts "Total tokens: #{tokens.size}"

  # Show some interesting token statistics
  token_types = tokens.map(&.type).tally
  puts "\nToken distribution:"
  token_types.to_a.sort_by(&.[1]).reverse.each do |type, count|
    puts "  #{type}: #{count}"
  end

  # Show some example tokens
  puts "\nExample tokens:"
  tokens.first(20).each do |token|
    puts "  #{token.type}: #{token.value.inspect}"
  end
else
  puts "Markdown lexer not found!"
end
