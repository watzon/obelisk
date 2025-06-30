# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Obelisk is a Crystal syntax highlighting library inspired by Chroma (Go) and Pygments (Python). It provides fast, extensible syntax highlighting for multiple programming languages with support for various output formats.

## Development Commands

```bash
# Install dependencies
shards install

# Run all tests
crystal spec

# Run specific test file
crystal spec spec/lexer_spec.cr

# Run examples (10+ examples available)
crystal run examples/00_quickstart.cr
crystal run examples/01_basic_usage.cr
crystal run examples/02_file_highlighting.cr
# etc.

# Build demo
crystal run example.cr

# Type check without running
crystal build src/obelisk.cr --no-codegen
```

## Architecture Overview

### Core System Design

The library follows a modular architecture with five main components:

1. **Token System** (`src/obelisk/token.cr`) - Hierarchical token types using Crystal enums
2. **Lexer System** (`src/obelisk/lexer.cr`) - Abstract base classes for language lexers
3. **Formatter System** (`src/obelisk/formatter.cr`) - Output formatters (HTML, ANSI, JSON, Plain)
4. **Style System** (`src/obelisk/style.cr`) - Theme system with RGB color support
5. **Registry Pattern** (`src/obelisk/registry.cr`) - Centralized component management

### Key Patterns

- **Registry Pattern**: All lexers, formatters, and styles are managed through centralized registries
- **Iterator Pattern**: Uses `Iterator(Token)` for memory-efficient streaming
- **Strategy Pattern**: Pluggable lexers and formatters for extensibility
- **Template Method**: Abstract base classes with concrete implementations

### Token Type System

Uses Crystal enums instead of symbols (proper Crystal idiom):
```crystal
# Good (Crystal way)
TokenType::Keyword

# Avoid (Ruby way - not idiomatic in Crystal)
:keyword
```

Token types follow hierarchical relationships:
- `TokenType::Text` → parent types
- `TokenType::Error` → for invalid syntax
- Specific types like `TokenType::KeywordReserved`, `TokenType::StringDouble`

## Directory Structure

```
src/obelisk/
├── token.cr              # Token types and Token class
├── lexer.cr              # Abstract lexer interfaces  
├── formatter.cr          # Formatter base classes
├── formatters.cr         # Concrete formatter implementations
├── style.cr              # Style and color system
├── registry.cr           # Component registries
├── quick.cr              # Convenience one-liner API
├── coalescing_iterator.cr # Token stream optimization
├── lexers/               # Language-specific lexers
│   ├── crystal.cr        # Crystal language support
│   ├── json.cr           # JSON support
│   └── yaml.cr           # YAML support
└── styles/               # Built-in themes
    ├── github.cr         # GitHub light theme
    ├── monokai.cr        # Monokai dark theme
    └── bw.cr            # Black & white theme
```

## API Usage Patterns

### Quick API (recommended for simple use)
```crystal
# One-liner highlighting
html = Obelisk.highlight("puts 'hello'", "crystal", "html")
```

### Manual API (for advanced control)
```crystal
# Manual tokenization and formatting
lexer = Obelisk.get_lexer("crystal")
formatter = Obelisk.get_formatter("html")
tokens = lexer.tokenize(source)
output = formatter.format(tokens)
```

## Adding New Components

### New Language Lexer
1. Create `src/obelisk/lexers/language_name.cr`
2. Inherit from `RegexLexer`
3. Define `@@rules` with regex patterns and token types
4. Register with aliases: `register_lexer("language", aliases: ["lang"], lexer: LanguageLexer)`

### New Formatter
1. Create class inheriting from `Formatter`
2. Implement `format(io, tokens, **options)`
3. Register: `register_formatter("format_name", MyFormatter)`

### New Style/Theme
1. Create `src/obelisk/styles/theme_name.cr`
2. Define style mappings for token types
3. Register: `register_style("theme_name", theme_hash)`

## Testing Conventions

- Uses Crystal's built-in `spec` framework
- Test files follow `*_spec.cr` naming
- Helper methods in `spec/spec_helper.cr`
- Tests cover lexer tokenization, formatter output, and integration

## Code Quality Standards

- 2-space indentation (enforced by .editorconfig)
- UTF-8 encoding, LF line endings
- No external dependencies (pure Crystal)
- Comprehensive error handling with fallbacks
- Memory-efficient iterator-based processing
- Type safety leveraging Crystal's type system

## Theme Serialization and External Formats

### Supported Theme Formats

- **Native JSON Format**: Direct mapping to internal Style/StyleEntry system
- **TextMate .tmTheme**: XML plist format used by TextMate, Sublime Text, VS Code
- **VS Code JSON**: Future support planned for native VS Code theme format

### Theme Loading and Saving

```crystal
# Load themes from files (auto-detects format)
style = Obelisk.load_theme("path/to/theme.json")
style = Obelisk.load_theme("path/to/theme.tmtheme")

# Load from string with explicit format
style = Obelisk.load_theme_from_string(content, Obelisk::ThemeLoader::Format::JSON, "theme_name")

# Export themes to different formats
json_export = Obelisk.export_theme_json(style, pretty: true)
tmtheme_export = Obelisk.export_theme_tmtheme(style)

# Save themes to files
Obelisk.save_theme(style, "exported_theme.json")
Obelisk.save_theme(style, "exported_theme.tmtheme")
```

### Theme Components Architecture

- **ThemeLoader**: Handles loading from JSON and tmTheme formats
- **ThemeExporter**: Handles exporting to JSON and tmTheme formats  
- **TmThemeParser**: Specialized XML plist parser for TextMate themes
- **TmThemeExporter**: Specialized XML plist generator for TextMate themes

### Token Type Mapping

The system maintains bidirectional mappings between:
- Obelisk TokenType enums ↔ JSON string names
- Obelisk TokenType enums ↔ TextMate scope names

Examples:
- `TokenType::Comment` ↔ `"comment"` ↔ `"comment"`
- `TokenType::LiteralStringDouble` ↔ `"literal.string.double"` ↔ `"string.quoted.double"`
- `TokenType::KeywordReserved` ↔ `"keyword.reserved"` ↔ `"keyword.control"`

## Performance Considerations

- Lexers use lazy compilation of regex patterns
- Token streaming prevents loading entire token arrays into memory
- Coalescing iterator optimizes consecutive identical token types
- Registry caching prevents repeated component lookups
- Theme loading/saving uses efficient streaming parsers