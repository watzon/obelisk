require "./token"

module Obelisk
  # Represents a color with RGB values
  struct Color
    getter red : UInt8
    getter green : UInt8
    getter blue : UInt8

    def initialize(@red : UInt8, @green : UInt8, @blue : UInt8)
    end

    # Create color from hex string
    def self.from_hex(hex : String) : Color
      hex = hex.lstrip('#')

      case hex.size
      when 3
        # Short hex format: #RGB -> #RRGGBB
        r = hex[0].to_u8(16) * 17
        g = hex[1].to_u8(16) * 17
        b = hex[2].to_u8(16) * 17
      when 6
        # Full hex format: #RRGGBB
        r = hex[0..1].to_u8(16)
        g = hex[2..3].to_u8(16)
        b = hex[4..5].to_u8(16)
      else
        raise "Invalid hex color format: #{hex}"
      end

      new(r, g, b)
    end

    # Convert to hex string
    def to_hex : String
      "#%02x%02x%02x" % [@red, @green, @blue]
    end

    # Check if color is transparent (all zeros)
    def transparent? : Bool
      @red == 0 && @green == 0 && @blue == 0
    end

    # Calculate brightness (0.0 to 1.0)
    def brightness : Float64
      # Use relative luminance formula
      (0.299 * @red + 0.587 * @green + 0.114 * @blue) / 255.0
    end

    # Brighten the color by a factor
    def brighten(factor : Float64) : Color
      new_r = (@red * (1.0 + factor)).clamp(0, 255).to_u8
      new_g = (@green * (1.0 + factor)).clamp(0, 255).to_u8
      new_b = (@blue * (1.0 + factor)).clamp(0, 255).to_u8
      Color.new(new_r, new_g, new_b)
    end

    # Darken the color by a factor
    def darken(factor : Float64) : Color
      new_r = (@red * (1.0 - factor)).clamp(0, 255).to_u8
      new_g = (@green * (1.0 - factor)).clamp(0, 255).to_u8
      new_b = (@blue * (1.0 - factor)).clamp(0, 255).to_u8
      Color.new(new_r, new_g, new_b)
    end

    def to_s(io : IO) : Nil
      io << to_hex
    end

    # Common colors
    BLACK       = Color.new(0u8, 0u8, 0u8)
    WHITE       = Color.new(255u8, 255u8, 255u8)
    RED         = Color.new(255u8, 0u8, 0u8)
    GREEN       = Color.new(0u8, 255u8, 0u8)
    BLUE        = Color.new(0u8, 0u8, 255u8)
    TRANSPARENT = Color.new(0u8, 0u8, 0u8)
  end

  # Trilean for style inheritance
  enum Trilean
    Pass
    Yes
    No

    def true? : Bool
      self == Yes
    end

    def false? : Bool
      self == No
    end

    def pass? : Bool
      self == Pass
    end
  end

  # Style entry for a token type
  class StyleEntry
    getter color : Color?
    getter background : Color?
    getter bold : Trilean
    getter italic : Trilean
    getter underline : Trilean
    getter no_inherit : Bool

    def initialize(@color : Color? = nil,
                   @background : Color? = nil,
                   @bold : Trilean = Trilean::Pass,
                   @italic : Trilean = Trilean::Pass,
                   @underline : Trilean = Trilean::Pass,
                   @no_inherit : Bool = false)
    end

    # Check if this entry has any styling
    def has_styles? : Bool
      !!@color || !!@background || !@bold.pass? || !@italic.pass? || !@underline.pass?
    end

    # Check if bold is enabled
    def bold? : Bool
      @bold.true?
    end

    # Check if italic is enabled
    def italic? : Bool
      @italic.true?
    end

    # Check if underline is enabled
    def underline? : Bool
      @underline.true?
    end

    # Merge with another style entry (other takes precedence)
    def merge(other : StyleEntry) : StyleEntry
      StyleEntry.new(
        color: other.color || @color,
        background: other.background || @background,
        bold: other.bold.pass? ? @bold : other.bold,
        italic: other.italic.pass? ? @italic : other.italic,
        underline: other.underline.pass? ? @underline : other.underline,
        no_inherit: other.no_inherit || @no_inherit
      )
    end
  end

  # Builder for creating style entries
  class StyleBuilder
    @color : Color?
    @background : Color?
    @bold : Trilean = Trilean::Pass
    @italic : Trilean = Trilean::Pass
    @underline : Trilean = Trilean::Pass
    @no_inherit : Bool = false

    def color(color : Color) : self
      @color = color
      self
    end

    def color(hex : String) : self
      @color = Color.from_hex(hex)
      self
    end

    def background(color : Color) : self
      @background = color
      self
    end

    def background(hex : String) : self
      @background = Color.from_hex(hex)
      self
    end

    def bold(value : Bool = true) : self
      @bold = value ? Trilean::Yes : Trilean::No
      self
    end

    def italic(value : Bool = true) : self
      @italic = value ? Trilean::Yes : Trilean::No
      self
    end

    def underline(value : Bool = true) : self
      @underline = value ? Trilean::Yes : Trilean::No
      self
    end

    def no_inherit(value : Bool = true) : self
      @no_inherit = value
      self
    end

    def build : StyleEntry
      StyleEntry.new(@color, @background, @bold, @italic, @underline, @no_inherit)
    end
  end

  # Complete style/theme definition
  class Style
    getter name : String
    getter background : Color
    getter entries : Hash(TokenType, StyleEntry)

    def initialize(@name : String, @background : Color = Color::WHITE, @entries = {} of TokenType => StyleEntry)
    end

    # Get style entry for a token type with inheritance
    def get(token_type : TokenType) : StyleEntry
      # Check if the specific token has no_inherit flag
      specific_entry = @entries[token_type]?
      if specific_entry && specific_entry.no_inherit
        # Return only the specific entry without any inheritance
        return specific_entry
      end

      # Build inherited style
      result = StyleEntry.new

      # Start with background/text defaults
      if base_entry = @entries[TokenType::Text]?
        result = result.merge(base_entry)
      end

      # Apply parent category styles
      current_type = token_type
      hierarchy = [] of TokenType

      # Build hierarchy chain
      while current_type != current_type.parent
        hierarchy << current_type.parent
        current_type = current_type.parent
      end

      # Apply styles from most general to most specific
      hierarchy.reverse.each do |type|
        if entry = @entries[type]?
          result = result.merge(entry)
          # Don't break on no_inherit here - that only applies to the specific token
        end
      end

      # Apply specific style if available
      if specific_entry
        result = result.merge(specific_entry)
      end

      result
    end

    # Get direct style entry for a token type (without inheritance)
    def get_direct(token_type : TokenType) : StyleEntry?
      @entries[token_type]?
    end

    # Set style for a token type
    def set(token_type : TokenType, entry : StyleEntry) : Nil
      @entries[token_type] = entry
    end

    # Create a new style with the given entry added
    def with(token_type : TokenType, entry : StyleEntry) : Style
      new_entries = @entries.dup
      new_entries[token_type] = entry
      Style.new(@name, @background, new_entries)
    end

    # Builder method for creating styles
    def self.build(name : String, background : Color = Color::WHITE, &block : StyleBuilder -> Nil) : Style
      style = Style.new(name, background)
      yield StyleBuilder.new
      style
    end
  end
end
