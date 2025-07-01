require "./registry"
require "./coalescing_iterator"

module Obelisk
  # Quick and convenient methods for common syntax highlighting tasks
  module Quick
    # Options for highlighting
    struct HighlightOptions
      property coalesce_tokens : Bool = true
      property max_token_size : Int32? = 32768 # 32KB default max size per token

      def initialize(@coalesce_tokens = true, @max_token_size = 32768)
      end
    end

    # Highlight source code with specified language, formatter, and style
    def self.highlight(source : String,
                       language : String,
                       formatter_name : String = "html",
                       style_name : String = "github",
                       options : HighlightOptions = HighlightOptions.new) : String
      # Get lexer
      lexer = Registry.lexers.get_with_fallback(language)

      # Get formatter
      formatter = Registry.formatters.get_with_fallback(formatter_name)

      # Get style
      style = Registry.styles.get_with_fallback(style_name)

      # Tokenize and format
      tokens = lexer.tokenize(source)

      # Apply coalescing if enabled
      if options.coalesce_tokens
        tokens = CoalescingIterator.wrap(tokens, options.max_token_size)
      end

      formatter.format(tokens, style)
    end

    # Highlight to IO
    def self.highlight(source : String,
                       io : IO,
                       language : String,
                       formatter_name : String = "html",
                       style_name : String = "github",
                       options : HighlightOptions = HighlightOptions.new) : Nil
      # Get lexer
      lexer = Registry.lexers.get_with_fallback(language)

      # Get formatter
      formatter = Registry.formatters.get_with_fallback(formatter_name)

      # Get style
      style = Registry.styles.get_with_fallback(style_name)

      # Tokenize and format
      tokens = lexer.tokenize(source)

      # Apply coalescing if enabled
      if options.coalesce_tokens
        tokens = CoalescingIterator.wrap(tokens, options.max_token_size)
      end

      formatter.format(tokens, style, io)
    end

    # Highlight file by auto-detecting language from filename
    def self.highlight_file(filename : String,
                            formatter_name : String = "html",
                            style_name : String = "github",
                            options : HighlightOptions = HighlightOptions.new) : String
      # Read file content
      source = File.read(filename)

      # Auto-detect lexer from filename
      lexer = Registry.lexers.by_filename(filename) || Registry.lexers.get_with_fallback("text")

      # Get formatter and style
      formatter = Registry.formatters.get_with_fallback(formatter_name)
      style = Registry.styles.get_with_fallback(style_name)

      # Tokenize and format
      tokens = lexer.tokenize(source)

      # Apply coalescing if enabled
      if options.coalesce_tokens
        tokens = CoalescingIterator.wrap(tokens, options.max_token_size)
      end

      formatter.format(tokens, style)
    end

    # Get list of available languages
    def self.languages : Array(String)
      Registry.lexers.names
    end

    # Get list of available formatters
    def self.formatters : Array(String)
      Registry.formatters.names
    end

    # Get list of available styles
    def self.styles : Array(String)
      Registry.styles.names
    end

    # Detect language from content
    def self.detect_language(source : String) : String?
      if lexer = Registry.lexers.analyze(source)
        lexer.name
      end
    end

    # Generate CSS for a style (when using HTML formatter with classes)
    def self.css(style_name : String = "github", class_prefix : String = "") : String
      style = Registry.styles.get_with_fallback(style_name)
      formatter = HTMLFormatter.new(with_classes: true, class_prefix: class_prefix)
      formatter.css(style)
    end
  end
end
