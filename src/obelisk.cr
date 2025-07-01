require "./obelisk/token"
require "./obelisk/lexer"
require "./obelisk/context_sensitive"
require "./obelisk/coalescing_iterator"
require "./obelisk/formatter"
require "./obelisk/style"
require "./obelisk/registry"
require "./obelisk/quick"
require "./obelisk/theme_loader"
require "./obelisk/theme_exporter"
require "./obelisk/lexers/*"
require "./obelisk/formatters"
require "./obelisk/styles/*"

module Obelisk
  VERSION = "0.1.0"

  # Convenience method for quick syntax highlighting
  def self.highlight(source : String, language : String, formatter : String = "html", style : String = "github") : String
    Quick.highlight(source, language, formatter, style)
  end

  # Get a lexer by name or language
  def self.lexer(name : String) : Lexer?
    Registry.lexers.get(name)
  end

  # Get a formatter by name
  def self.formatter(name : String) : Formatter?
    Registry.formatters.get(name)
  end

  # Get a style/theme by name
  def self.style(name : String) : Style?
    Registry.styles.get(name)
  end

  # List all available lexer names
  def self.lexer_names : Array(String)
    Registry.lexers.names
  end

  # List all available formatter names
  def self.formatter_names : Array(String)
    Registry.formatters.names
  end

  # List all available style names
  def self.style_names : Array(String)
    Registry.styles.names
  end

  # Load a theme from a file
  def self.load_theme(path : String) : Style
    ThemeLoader.load(path)
  end

  # Load a theme from string content with explicit format
  def self.load_theme_from_string(content : String, format : ThemeLoader::Format, name : String) : Style
    ThemeLoader.load_from_string(content, format, name)
  end

  # Export a style to JSON format
  def self.export_theme_json(style : Style, pretty : Bool = true) : String
    ThemeExporter.to_json(style, pretty)
  end

  # Export a style to tmTheme format
  def self.export_theme_tmtheme(style : Style) : String
    ThemeExporter.to_tmtheme(style)
  end

  # Export a style to Chroma XML format
  def self.export_theme_chroma(style : Style) : String
    ThemeExporter.to_chroma(style)
  end

  # Save a style to a file
  def self.save_theme(style : Style, path : String, format : ThemeLoader::Format? = nil) : Nil
    ThemeExporter.save(style, path, format)
  end
end

# Register the lexers after everything is loaded
Obelisk::Registry.lexers.register(Obelisk::PlainTextLexer.new)
Obelisk::Registry.lexers.register(Obelisk::Lexers::Crystal.new)
Obelisk::Registry.lexers.register(Obelisk::Lexers::JSON.new)
Obelisk::Registry.lexers.register(Obelisk::Lexers::YAML.new)
Obelisk::Registry.lexers.register(Obelisk::Lexers::Ruby.new)
Obelisk::Registry.lexers.register(Obelisk::Lexers::Python.new)
Obelisk::Registry.lexers.register(Obelisk::Lexers::JavaScript.new)
Obelisk::Registry.lexers.register(Obelisk::Lexers::Go.new)
Obelisk::Registry.lexers.register(Obelisk::Lexers::Rust.new)
Obelisk::Registry.lexers.register(Obelisk::Lexers::C.new)
Obelisk::Registry.lexers.register(Obelisk::Lexers::HTML.new)
Obelisk::Registry.lexers.register(Obelisk::Lexers::CSS.new)
Obelisk::Registry.lexers.register(Obelisk::Lexers::Markdown.new)
Obelisk::Registry.lexers.register(Obelisk::Lexers::SQL.new)
Obelisk::Registry.lexers.register(Obelisk::Lexers::Shell.new)
