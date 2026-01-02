#!/usr/bin/env crystal
# Crystal Compiler Bug: EXC_BREAKPOINT when using iterators from Registry-stored objects
#
# REPRODUCTION:
# 1. Create a JavaScript lexer
# 2. Register it in Obelisk::Registry
# 3. Retrieve it via registry.get()
# 4. Call tokenize() to get SafeTokenIteratorAdapter
# 5. Wrap in CoalescingIterator
# 6. Call next() -> EXC_BREAKPOINT crash
#
# KEY FINDING: The SAME lexer instance works fine BEFORE being retrieved
# from the Registry, but crashes AFTER being retrieved via .get()!
#
# Crystal version: 1.18.2
# Platform: Darwin (arm64)
# Test date: 2026-01-02
#
# To debug with lldb:
#   crystal build crystal_hash_iterator_bug.cr -o bug_test
#   lldb --batch -o run -o bt ./bug_test

require "./src/obelisk"

puts "=" * 70
puts "Crystal Compiler Bug: EXC_BREAKPOINT with Registry-retrieved lexers"
puts "=" * 70
puts "Crystal version: #{Crystal::VERSION}"
puts

registry = Obelisk::Registry.lexers

# TEST 1: Fresh lexer (works)
puts "TEST 1: Fresh lexer (not in Registry)"
puts "-" * 70
fresh_lexer = Obelisk::Lexers::JavaScript.new
puts "  Created: #{fresh_lexer.class} (oid: #{fresh_lexer.object_id})"

iter1 = fresh_lexer.tokenize("x")
puts "  tokenize() -> #{iter1.class}"

wrap1 = Obelisk::CoalescingIterator.new(iter1)
puts "  CoalescingIterator.wrap() -> #{wrap1.class}"

result1 = wrap1.next
puts "  next() -> #{result1.class} ✓ WORKS"

# TEST 2: Same lexer after registration (still works with direct reference)
puts "\nTEST 2: Same lexer after registration (direct reference)"
puts "-" * 70
registry.register(fresh_lexer)
puts "  Registered to Registry"

iter2 = fresh_lexer.tokenize("y")
wrap2 = Obelisk::CoalescingIterator.new(iter2)
result2 = wrap2.next
puts "  next() -> #{result2.class} ✓ WORKS (same object, still works)"

# TEST 3: Lexer retrieved from Registry (CRASHES!)
puts "\nTEST 3: Lexer retrieved from Registry via .get()"
puts "-" * 70
retrieved = registry.get("javascript")
if retrieved
  puts "  Retrieved: #{retrieved.class} (oid: #{retrieved.object_id})"
  puts "  Same object? #{retrieved.object_id == fresh_lexer.object_id}"

  iter3 = retrieved.tokenize("z")
  puts "  tokenize() -> #{iter3.class}"

  wrap3 = Obelisk::CoalescingIterator.new(iter3)
  puts "  CoalescingIterator.wrap() -> #{wrap3.class}"

  puts "  Calling next()..."
  result3 = wrap3.next
  puts "  next() -> #{result3.class} ✓ WORKS"
else
  puts "  ERROR: Could not retrieve lexer from Registry"
end

puts "\n" + "=" * 70
puts "RESULT: If you see this message, the bug has been FIXED!"
puts "        If it crashed with EXC_BREAKPOINT above, the bug still exists."
puts "=" * 70
