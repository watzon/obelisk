# Context-Sensitive Parsing Framework

This document demonstrates the comprehensive context-sensitive parsing capabilities added to the Obelisk lexer system.

## Overview

The context-sensitive parsing framework enhances the existing lexer architecture with:

- **Context-aware rule selection** based on parse state and history
- **Look-ahead and look-behind capabilities** for better tokenization decisions
- **Conditional parsing rules** that depend on surrounding context
- **Context stack management** for complex nested structures
- **State-dependent tokenization** that changes behavior based on current context

## Core Components

### 1. ParsingContext

The `ParsingContext` struct provides comprehensive information about the current parsing state:

```crystal
context = ParsingContext.new(state, text, position, history)

# Look-around capabilities
context.look_behind(5)     # Get previous 5 characters
context.look_ahead(10)     # Get next 10 characters
context.look_around(3, 7)  # Get 3 chars before and 7 after

# Position information
context.at_line_start?     # Check if at beginning of line
context.at_line_end?       # Check if at end of line
context.line_number        # Current line (1-based)
context.column_number      # Current column (1-based)

# Token history analysis
context.last_token_of_type(TokenType::Keyword)
context.recent_tokens(5) { |token| token.type == TokenType::Operator }
context.any_recent_token?(3) { |token| token.value == "(" }
```

### 2. ContextAwareRule

Rules that can make decisions based on parsing context:

```crystal
# Rule that only matches comments outside of strings
comment_condition = ContextConditions.not_in_state("string")
rule = ContextAwareRule.new(
  /\/\/[^\n]*/,                    # Pattern
  TokenType::CommentSingle,        # Action
  comment_condition,               # Condition
  priority: 80,                    # Priority
  description: "Single-line comment"
)
```

### 3. ContextConditions

Pre-built conditions for common scenarios:

```crystal
# State-based conditions
ContextConditions.in_state("string")
ContextConditions.not_in_state("comment")
ContextConditions.context_equals("quote_type", "double")

# Position-based conditions
ContextConditions.at_line_start
ContextConditions.preceded_by(/if\s+/)
ContextConditions.followed_by(/\{/)

# History-based conditions
ContextConditions.recent_token_type(TokenType::Keyword, 5)

# Compound conditions
ContextConditions.all_of(condition1, condition2)
ContextConditions.any_of(condition1, condition2)
ContextConditions.not(condition)
```

### 4. ContextManager

Tracks parsing history and context transitions:

```crystal
manager = ContextManager.new
manager.add_token(token)
manager.log_transition("root", "string", position)
manager.stats  # Get parsing statistics
```

### 5. LookAroundUtils

Advanced pattern matching utilities:

```crystal
# Check pattern at specific offset
LookAroundUtils.matches_at_offset(text, pos, offset, /pattern/)

# Find patterns in window
LookAroundUtils.find_in_window(text, pos, window_size, /pattern/)

# Balanced delimiter handling
LookAroundUtils.inside_balanced?(text, pos, '{', '}')
LookAroundUtils.find_matching_close(text, pos, '(', ')')
LookAroundUtils.extract_balanced_content(text, pos, '[', ']')
```

## Practical Examples

### 1. String Interpolation

```crystal
text = "\"Hello \${name} world\""
tokens = lexer.tokenize(text).to_a

# Produces:
# LiteralStringDouble: "\""
# LiteralStringDouble: "Hello "
# LiteralStringInterpol: "${"
# Name: "name"
# LiteralStringInterpol: "}"
# LiteralStringDouble: " world"
# LiteralStringDouble: "\""
```

### 2. Context-Aware Comments

```crystal
text = "// This is a comment\n\"This is // not a comment\""
tokens = lexer.tokenize(text).to_a

# The '//' outside strings becomes CommentSingle
# The '//' inside strings remains as string content
```

### 3. Template Language Parsing

```crystal
# Configure template expression rules
template_rules = ContextRuleHelpers.template_expression_rule(
  "{{", "}}", "template", "expression"
)

text = "Hello {{ user.name }} welcome!"
# Properly tokenizes template delimiters and expressions
```

### 4. Bracket Matching with Context

```crystal
text = "{ outer { inner } more }"
tokens = lexer.tokenize(text).to_a

# All brackets are properly identified as Punctuation tokens
# Context tracking enables proper nesting analysis
```

## Advanced Features

### Conditional Rule Actions

```crystal
# Different behavior based on context
action = RuleActions.conditional(
  ->(state : LexerState) { state.get_context("mode") == "strict" },
  TokenType::Keyword,    # Action when condition is true
  TokenType::Name        # Action when condition is false
)
```

### History-Dependent Rules

```crystal
# Rule behavior depends on recent tokens
rule = ContextRuleHelpers.history_dependent_rule(
  /\w+/,                           # Pattern
  TokenType::Keyword,              # Required recent token type
  TokenType::KeywordReserved,      # Success token type
  TokenType::Name,                 # Failure token type
  max_lookback: 5
)
```

### Custom Context Extractors

```crystal
# Extract context information from matches
rule = LanguageNestingRule.new(
  "html", "javascript",
  /<script[^>]*>/i, /<\/script>/i,
  context_extractor: ->(text : String) {
    attrs = {} of String => String
    if match = /type\s*=\s*["']?([^"'>\s]+)/i.match(text)
      attrs["type"] = match[1]
    end
    attrs
  }
)
```

## Integration with Existing Architecture

The context-sensitive framework seamlessly integrates with:

- **RegexLexer**: Extends functionality without breaking compatibility
- **LexerState**: Leverages existing state management
- **Token system**: Uses standard token types and structures
- **Composition framework**: Works with lexer composition strategies
- **Priority selection**: Integrates with priority-based lexer selection

## Performance Considerations

- **Look-around operations** are optimized with configurable window sizes
- **Token history** is automatically trimmed to prevent memory growth
- **Context rules** are sorted by priority for efficient matching
- **Fallback rules** provide graceful degradation for unmatched patterns

## Testing

The framework includes comprehensive tests covering:

- Look-around functionality and edge cases
- Context condition evaluation
- Rule priority and ordering
- State transitions and history tracking
- Integration with real-world parsing scenarios
- Error handling and malformed input

## Future Enhancements

The architecture is designed to support:

- **Semantic analysis integration**: Connect to AST building
- **Error recovery**: Intelligent error correction based on context
- **Performance profiling**: Context-aware optimization hints
- **Language server protocol**: Rich editing support
- **Incremental parsing**: Efficient re-parsing of changed regions

This context-sensitive parsing framework significantly enhances Obelisk's capability to handle complex, real-world lexing scenarios while maintaining the simplicity and performance of the core architecture.