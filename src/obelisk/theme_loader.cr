require "./style"
require "./token"
require "./tmtheme_parser"
require "./chroma_parser"
require "json"

module Obelisk
  # Exception raised when theme loading or parsing fails
  class ThemeError < Exception
  end

  # Handles loading and parsing themes from various formats
  module ThemeLoader
    # Supported theme formats
    enum Format
      JSON      # Native Obelisk JSON format
      TmTheme   # TextMate .tmTheme XML plist format
      VSCode    # VS Code JSON theme format
      Chroma    # Chroma XML stylesheet format
    end

    # Load a theme from a file, auto-detecting format
    def self.load(path : String) : Style
      format = detect_format(path)
      content = File.read(path)
      
      case format
      when .json?
        load_json(content, File.basename(path, ".json"))
      when .tm_theme?
        load_tmtheme(content, File.basename(path, ".tmTheme"))
      when .vs_code?
        load_vscode(content, File.basename(path, ".json"))
      when .chroma?
        load_chroma(content, File.basename(path, ".xml"))
      else
        raise ThemeError.new("Unsupported theme format for file: #{path}")
      end
    end

    # Load theme from string content with explicit format
    def self.load_from_string(content : String, format : Format, name : String) : Style
      case format
      when .json?
        load_json(content, name)
      when .tm_theme?
        load_tmtheme(content, name)
      when .vs_code?
        load_vscode(content, name)
      when .chroma?
        load_chroma(content, name)
      else
        raise ThemeError.new("Unsupported theme format: #{format}")
      end
    end

    # Detect theme format from file extension and content
    private def self.detect_format(path : String) : Format
      ext = File.extname(path).downcase
      
      case ext
      when ".json"
        # Distinguish between VS Code and Obelisk JSON by content
        content = File.read(path)
        if content.includes?("tokenColors") || content.includes?("semanticTokenColors")
          Format::VSCode
        else
          Format::JSON
        end
      when ".tmtheme"
        Format::TmTheme
      when ".xml"
        # Assume XML files are Chroma format
        Format::Chroma
      else
        raise ThemeError.new("Unknown theme file extension: #{ext}")
      end
    end

    # Load native Obelisk JSON theme format
    private def self.load_json(content : String, name : String) : Style
      begin
        data = JSON.parse(content)
      rescue ex : JSON::ParseException
        raise ThemeError.new("Invalid JSON theme: #{ex.message}")
      end
      
      unless data.as_h?
        raise ThemeError.new("Invalid JSON theme: root must be an object")
      end

      theme_name = data["name"]?.try(&.as_s) || name
      background = parse_color(data["background"]?.try(&.as_s) || "#ffffff")
      
      style = Style.new(theme_name, background)
      
      # Load token mappings
      if tokens = data["tokens"]?.try(&.as_h)
        tokens.each do |token_name, token_data|
          token_type = parse_token_type(token_name)
          style_entry = parse_style_entry(token_data)
          style.set(token_type, style_entry)
        end
      end

      style
    end

    # Load TextMate .tmTheme format
    private def self.load_tmtheme(content : String, name : String) : Style
      parser = TmThemeParser.new(content)
      parser.parse(name)
    end

    # Load VS Code JSON theme format
    private def self.load_vscode(content : String, name : String) : Style
      # This will be implemented in the next iteration
      raise ThemeError.new("VS Code theme support not yet implemented")
    end

    # Load Chroma XML stylesheet format
    private def self.load_chroma(content : String, name : String) : Style
      parser = ChromaParser.new(content)
      parser.parse(name)
    end

    # Parse color from string (hex format)
    private def self.parse_color(color_str : String) : Color
      Color.from_hex(color_str)
    rescue
      raise ThemeError.new("Invalid color format: #{color_str}")
    end

    # Parse token type from string name
    private def self.parse_token_type(token_name : String) : TokenType
      # Map string names to TokenType enum values
      case token_name.downcase
      when "text" then TokenType::Text
      when "error" then TokenType::Error
      when "other" then TokenType::Other
      when "keyword" then TokenType::Keyword
      when "keyword.constant" then TokenType::KeywordConstant
      when "keyword.declaration" then TokenType::KeywordDeclaration
      when "keyword.namespace" then TokenType::KeywordNamespace
      when "keyword.pseudo" then TokenType::KeywordPseudo
      when "keyword.reserved" then TokenType::KeywordReserved
      when "keyword.type" then TokenType::KeywordType
      when "name" then TokenType::Name
      when "name.attribute" then TokenType::NameAttribute
      when "name.builtin" then TokenType::NameBuiltin
      when "name.builtin.pseudo" then TokenType::NameBuiltinPseudo
      when "name.class" then TokenType::NameClass
      when "name.constant" then TokenType::NameConstant
      when "name.decorator" then TokenType::NameDecorator
      when "name.entity" then TokenType::NameEntity
      when "name.exception" then TokenType::NameException
      when "name.function" then TokenType::NameFunction
      when "name.function.magic" then TokenType::NameFunctionMagic
      when "name.label" then TokenType::NameLabel
      when "name.namespace" then TokenType::NameNamespace
      when "name.other" then TokenType::NameOther
      when "name.property" then TokenType::NameProperty
      when "name.tag" then TokenType::NameTag
      when "name.variable" then TokenType::NameVariable
      when "name.variable.class" then TokenType::NameVariableClass
      when "name.variable.global" then TokenType::NameVariableGlobal
      when "name.variable.instance" then TokenType::NameVariableInstance
      when "name.variable.magic" then TokenType::NameVariableMagic
      when "literal" then TokenType::Literal
      when "literal.date" then TokenType::LiteralDate
      when "literal.number" then TokenType::LiteralNumber
      when "literal.number.binary" then TokenType::LiteralNumberBin
      when "literal.number.float" then TokenType::LiteralNumberFloat
      when "literal.number.hex" then TokenType::LiteralNumberHex
      when "literal.number.integer" then TokenType::LiteralNumberInteger
      when "literal.number.integer.long" then TokenType::LiteralNumberIntegerLong
      when "literal.number.oct" then TokenType::LiteralNumberOct
      when "literal.string" then TokenType::LiteralString
      when "literal.string.affix" then TokenType::LiteralStringAffix
      when "literal.string.backtick" then TokenType::LiteralStringBacktick
      when "literal.string.char" then TokenType::LiteralStringChar
      when "literal.string.delimiter" then TokenType::LiteralStringDelimiter
      when "literal.string.doc" then TokenType::LiteralStringDoc
      when "literal.string.double" then TokenType::LiteralStringDouble
      when "literal.string.escape" then TokenType::LiteralStringEscape
      when "literal.string.heredoc" then TokenType::LiteralStringHeredoc
      when "literal.string.interpol" then TokenType::LiteralStringInterpol
      when "literal.string.other" then TokenType::LiteralStringOther
      when "literal.string.regex" then TokenType::LiteralStringRegex
      when "literal.string.single" then TokenType::LiteralStringSingle
      when "literal.string.symbol" then TokenType::LiteralStringSymbol
      when "operator" then TokenType::Operator
      when "operator.word" then TokenType::OperatorWord
      when "punctuation" then TokenType::Punctuation
      when "comment" then TokenType::Comment
      when "comment.hashbang" then TokenType::CommentHashbang
      when "comment.multiline" then TokenType::CommentMultiline
      when "comment.preproc" then TokenType::CommentPreproc
      when "comment.preprocfile" then TokenType::CommentPreprocFile
      when "comment.single" then TokenType::CommentSingle
      when "comment.special" then TokenType::CommentSpecial
      when "generic" then TokenType::Generic
      when "generic.deleted" then TokenType::GenericDeleted
      when "generic.emph" then TokenType::GenericEmph
      when "generic.error" then TokenType::GenericError
      when "generic.heading" then TokenType::GenericHeading
      when "generic.inserted" then TokenType::GenericInserted
      when "generic.output" then TokenType::GenericOutput
      when "generic.prompt" then TokenType::GenericPrompt
      when "generic.strong" then TokenType::GenericStrong
      when "generic.subheading" then TokenType::GenericSubheading
      when "generic.traceback" then TokenType::GenericTraceback
      else
        raise ThemeError.new("Unknown token type: #{token_name}")
      end
    end

    # Parse style entry from JSON data
    private def self.parse_style_entry(data) : StyleEntry
      case data
      when JSON::Any
        parse_style_entry_from_json(data)
      else
        raise ThemeError.new("Invalid style entry data type")
      end
    end

    private def self.parse_style_entry_from_json(data : JSON::Any) : StyleEntry
      builder = StyleBuilder.new

      if color = data["color"]?.try(&.as_s)
        builder.color(parse_color(color))
      end

      if background = data["background"]?.try(&.as_s)
        builder.background(parse_color(background))
      end

      if bold = data["bold"]?.try(&.as_bool)
        builder.bold if bold
      end

      if italic = data["italic"]?.try(&.as_bool)
        builder.italic if italic
      end

      if underline = data["underline"]?.try(&.as_bool)
        builder.underline if underline
      end

      if no_inherit = data["noInherit"]?.try(&.as_bool)
        builder.no_inherit if no_inherit
      end

      builder.build
    end
  end
end