#!/usr/bin/env crystal

# Quickstart Example - The simplest way to use Obelisk
require "../src/obelisk"

# Example 1: One-liner syntax highlighting
puts Obelisk.highlight("puts \"Hello, World!\"", "crystal")

puts "\n" + "="*50 + "\n"

# Example 2: Highlight a small Crystal program
code = <<-CRYSTAL
# Calculate factorial
def factorial(n)
  return 1 if n <= 1
  n * factorial(n - 1)
end

puts factorial(5)  # => 120
CRYSTAL

puts Obelisk.highlight(code, "crystal")

puts "\n" + "="*50 + "\n"

# Example 3: Terminal colors for console output
puts "Terminal output with colors:"
puts Obelisk.highlight(code, "crystal", "terminal", "monokai")

puts "\n" + "="*50 + "\n"

# Example 4: Quick JSON highlighting
json = %q({"name": "Obelisk", "version": "1.0.0", "awesome": true})
puts "JSON highlighting:"
puts Obelisk.highlight(json, "json", "terminal", "monokai")
