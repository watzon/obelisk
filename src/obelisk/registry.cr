require "./lexer"
require "./formatter"
require "./style"

module Obelisk
  # Generic registry for managing collections of named items
  abstract class BaseRegistry(T)
    @items = {} of String => T
    @aliases = {} of String => String

    # Register an item with optional aliases
    def register(name : String, item : T, aliases : Array(String) = [] of String) : Nil
      @items[name] = item
      aliases.each { |alias_name| @aliases[alias_name] = name }
    end

    # Get an item by name or alias
    def get(name : String) : T?
      real_name = @aliases[name]? || name
      @items[real_name]?
    end

    # Get an item by name or alias, raising if not found
    def get!(name : String) : T
      get(name) || raise "Item not found: #{name}"
    end

    # Get all names
    def names : Array(String)
      @items.keys.sort
    end

    # Get all aliases
    def aliases : Array(String)
      @aliases.keys.sort
    end

    # Check if an item exists
    def has?(name : String) : Bool
      real_name = @aliases[name]? || name
      @items.has_key?(real_name)
    end

    # Get all items
    def all : Array(T)
      @items.values
    end

    # Clear all items
    def clear : Nil
      @items.clear
      @aliases.clear
    end
  end

  # Registry for lexers with additional functionality
  class LexerRegistry < BaseRegistry(Lexer)
    # Register a lexer using its config
    def register(lexer : Lexer) : Nil
      config = lexer.config
      register(config.name, lexer, config.aliases)

      # Also register by filenames for quick lookup
      config.filenames.each do |pattern|
        # Extract extension from pattern for alias registration
        if match = pattern.match(/\*\.(\w+)$/)
          extension = match[1]
          @aliases[extension] = config.name unless @aliases.has_key?(extension)
        end
      end
    end

    # Find lexer by filename
    def by_filename(filename : String) : Lexer?
      # Try direct extension lookup first
      if ext = File.extname(filename).lstrip('.')
        if lexer = get(ext)
          return lexer
        end
      end

      # Try pattern matching
      @items.values.find do |lexer|
        lexer.matches_filename?(filename)
      end
    end

    # Find lexer by MIME type
    def by_mime_type(mime_type : String) : Lexer?
      @items.values.find do |lexer|
        lexer.matches_mime_type?(mime_type)
      end
    end

    # Analyze text to find best lexer
    def analyze(text : String) : Lexer?
      best_lexer = nil
      best_score = 0.0f32

      @items.values.each do |lexer|
        score = lexer.analyze(text)
        if score > best_score
          best_score = score
          best_lexer = lexer
        end
      end

      # Return best lexer if score is above threshold
      best_score > 0.1f32 ? best_lexer : nil
    end

    # Get lexer with fallback chain
    def get_with_fallback(name_or_filename : String) : Lexer
      # Try by name first
      if lexer = get(name_or_filename)
        return lexer
      end

      # Try by filename
      if lexer = by_filename(name_or_filename)
        return lexer
      end

      # Return plain text lexer as fallback
      PlainTextLexer.new
    end
  end

  # Registry for formatters
  class FormatterRegistry < BaseRegistry(Formatter)
    # Register a formatter using its name
    def register(formatter : Formatter) : Nil
      register(formatter.name, formatter)
    end

    # Get formatter with fallback
    def get_with_fallback(name : String) : Formatter
      get(name) || PlainFormatter.new
    end
  end

  # Registry for styles
  class StyleRegistry < BaseRegistry(Style)
    # Register a style using its name
    def register(style : Style) : Nil
      register(style.name, style)
    end

    # Get style with fallback
    def get_with_fallback(name : String) : Style
      get(name) || get!("github")
    end
  end

  # Global registry instance
  module Registry
    @@lexers = LexerRegistry.new
    @@formatters = FormatterRegistry.new
    @@styles = StyleRegistry.new

    def self.lexers : LexerRegistry
      @@lexers
    end

    def self.formatters : FormatterRegistry
      @@formatters
    end

    def self.styles : StyleRegistry
      @@styles
    end
  end
end
