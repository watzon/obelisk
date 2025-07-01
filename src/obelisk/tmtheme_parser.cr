require "xml"
require "./style"
require "./token"
require "./theme_loader"

module Obelisk
  # Parses TextMate .tmTheme files (XML plist format)
  class TmThemeParser
    # Scope to TokenType mapping for common TextMate scopes
    SCOPE_MAPPINGS = {
      # Comments
      "comment"       => TokenType::Comment,
      "comment.line"  => TokenType::CommentSingle,
      "comment.block" => TokenType::CommentMultiline,

      # Strings
      "string"               => TokenType::LiteralString,
      "string.quoted.single" => TokenType::LiteralStringSingle,
      "string.quoted.double" => TokenType::LiteralStringDouble,
      "string.unquoted"      => TokenType::LiteralStringOther,
      "string.interpolated"  => TokenType::LiteralStringInterpol,
      "string.regexp"        => TokenType::LiteralStringRegex,

      # Numbers
      "constant.numeric"         => TokenType::LiteralNumber,
      "constant.numeric.integer" => TokenType::LiteralNumberInteger,
      "constant.numeric.float"   => TokenType::LiteralNumberFloat,
      "constant.numeric.hex"     => TokenType::LiteralNumberHex,
      "constant.numeric.octal"   => TokenType::LiteralNumberOct,
      "constant.numeric.binary"  => TokenType::LiteralNumberBin,

      # Keywords
      "keyword"          => TokenType::Keyword,
      "keyword.control"  => TokenType::KeywordReserved,
      "keyword.operator" => TokenType::OperatorWord,
      "keyword.other"    => TokenType::Keyword,

      # Variables and names
      "variable"           => TokenType::NameVariable,
      "variable.parameter" => TokenType::NameVariable,
      "variable.language"  => TokenType::NameBuiltin,
      "variable.other"     => TokenType::NameVariable,

      # Functions
      "entity.name.function"        => TokenType::NameFunction,
      "entity.name.class"           => TokenType::NameClass,
      "entity.name.type"            => TokenType::NameClass,
      "entity.name.namespace"       => TokenType::NameNamespace,
      "entity.name.tag"             => TokenType::NameTag,
      "entity.other.attribute-name" => TokenType::NameAttribute,

      # Constants
      "constant"                  => TokenType::NameConstant,
      "constant.language"         => TokenType::NameBuiltin,
      "constant.character.escape" => TokenType::LiteralStringEscape,

      # Storage (types, modifiers)
      "storage"          => TokenType::KeywordType,
      "storage.type"     => TokenType::KeywordType,
      "storage.modifier" => TokenType::KeywordReserved,

      # Support (built-ins)
      "support"          => TokenType::NameBuiltin,
      "support.function" => TokenType::NameBuiltin,
      "support.class"    => TokenType::NameBuiltin,
      "support.type"     => TokenType::NameBuiltin,
      "support.constant" => TokenType::NameBuiltin,

      # Operators and punctuation
      "keyword.operator"       => TokenType::Operator,
      "punctuation"            => TokenType::Punctuation,
      "punctuation.separator"  => TokenType::Punctuation,
      "punctuation.terminator" => TokenType::Punctuation,

      # Invalid/illegal
      "invalid"            => TokenType::Error,
      "invalid.illegal"    => TokenType::Error,
      "invalid.deprecated" => TokenType::Error,

      # Markup (for markdown, etc.)
      "markup.heading"   => TokenType::GenericHeading,
      "markup.bold"      => TokenType::GenericStrong,
      "markup.italic"    => TokenType::GenericEmph,
      "markup.underline" => TokenType::GenericEmph,
      "markup.deleted"   => TokenType::GenericDeleted,
      "markup.inserted"  => TokenType::GenericInserted,
    }

    def initialize(@content : String)
    end

    def parse(name : String) : Style
      document = XML.parse(@content)
      plist = document.first_element_child

      unless plist && plist.name == "plist"
        raise ThemeError.new("Invalid tmTheme: root element must be 'plist'")
      end

      dict = plist.first_element_child
      unless dict && dict.name == "dict"
        raise ThemeError.new("Invalid tmTheme: plist must contain a dict")
      end

      # Parse the main dictionary
      theme_data = parse_dict(dict)

      # Extract theme name
      theme_name = theme_data["name"]?.try(&.as(String)) || name

      # Extract settings array
      settings = theme_data["settings"]?.try(&.as(Array))
      unless settings
        raise ThemeError.new("Invalid tmTheme: missing 'settings' array")
      end

      # First settings entry should be global settings
      global_settings = settings[0]?.try(&.as(Hash))
      unless global_settings
        raise ThemeError.new("Invalid tmTheme: first settings entry must be global settings")
      end

      # Extract background color
      global = global_settings["settings"]?.try(&.as(Hash))
      background_str = global.try(&.["background"]?).try(&.as(String)) || "#ffffff"
      background = Color.from_hex(background_str)

      # Create style
      style = Style.new(theme_name, background)

      # Process remaining settings entries
      settings[1..].each do |setting|
        next unless setting.is_a?(Hash)
        process_scope_setting(style, setting)
      end

      style
    end

    private def parse_dict(dict : XML::Node) : Hash(String, PlistValue)
      result = {} of String => PlistValue
      current_key = nil

      dict.children.each do |child|
        case child.name
        when "key"
          current_key = child.content
        when "string"
          if key = current_key
            result[key] = child.content
            current_key = nil
          end
        when "array"
          if key = current_key
            result[key] = parse_array(child)
            current_key = nil
          end
        when "dict"
          if key = current_key
            result[key] = parse_dict(child)
            current_key = nil
          end
        when "true"
          if key = current_key
            result[key] = true
            current_key = nil
          end
        when "false"
          if key = current_key
            result[key] = false
            current_key = nil
          end
        end
      end

      result
    end

    private def parse_array(array : XML::Node) : Array(PlistValue)
      result = [] of PlistValue

      array.children.each do |child|
        case child.name
        when "string"
          result << child.content
        when "dict"
          result << parse_dict(child)
        when "array"
          result << parse_array(child)
        when "true"
          result << true
        when "false"
          result << false
        end
      end

      result
    end

    private def process_scope_setting(style : Style, setting : Hash)
      scope = setting["scope"]?.try(&.as(String))
      settings_data = setting["settings"]?.try(&.as(Hash))

      return unless scope && settings_data

      # Map scope to token type
      token_type = map_scope_to_token_type(scope)
      return unless token_type

      # Create style entry
      style_entry = create_style_entry(settings_data)
      style.set(token_type, style_entry)
    end

    private def map_scope_to_token_type(scope : String) : TokenType?
      # Try exact match first
      if token_type = SCOPE_MAPPINGS[scope]?
        return token_type
      end

      # Try partial matches (longest first)
      sorted_scopes = SCOPE_MAPPINGS.keys.sort_by(&.size).reverse
      sorted_scopes.each do |mapped_scope|
        if scope.starts_with?(mapped_scope)
          return SCOPE_MAPPINGS[mapped_scope]
        end
      end

      # Default fallback
      case scope
      when .starts_with?("comment")
        TokenType::Comment
      when .starts_with?("string")
        TokenType::LiteralString
      when .starts_with?("constant.numeric")
        TokenType::LiteralNumber
      when .starts_with?("keyword")
        TokenType::Keyword
      when .starts_with?("entity.name")
        TokenType::Name
      when .starts_with?("variable")
        TokenType::NameVariable
      when .starts_with?("invalid")
        TokenType::Error
      else
        nil
      end
    end

    private def create_style_entry(settings : Hash) : StyleEntry
      builder = StyleBuilder.new

      if foreground = settings["foreground"]?.try(&.as(String))
        builder.color(Color.from_hex(foreground))
      end

      if background = settings["background"]?.try(&.as(String))
        builder.background(Color.from_hex(background))
      end

      if font_style = settings["fontStyle"]?.try(&.as(String))
        if font_style.includes?("bold")
          builder.bold
        end
        if font_style.includes?("italic")
          builder.italic
        end
        if font_style.includes?("underline")
          builder.underline
        end
      end

      builder.build
    end
  end

  # Union type for plist values
  alias PlistValue = String | Bool | Array(PlistValue) | Hash(String, PlistValue)
end
