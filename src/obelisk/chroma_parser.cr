require "xml"
require "./style"
require "./token"
require "./theme_loader"

module Obelisk
  # Parses Chroma XML style files
  class ChromaParser
    # Chroma TokenType to Obelisk TokenType mapping
    TOKEN_MAPPINGS = {
      # Basic types
      "Error"      => TokenType::Error,
      "Other"      => TokenType::Other,
      "Text"       => TokenType::Text,
      "Background" => TokenType::Text, # Background is handled specially

      # Keywords
      "Keyword"            => TokenType::Keyword,
      "KeywordConstant"    => TokenType::KeywordConstant,
      "KeywordDeclaration" => TokenType::KeywordDeclaration,
      "KeywordNamespace"   => TokenType::KeywordNamespace,
      "KeywordPseudo"      => TokenType::KeywordPseudo,
      "KeywordReserved"    => TokenType::KeywordReserved,
      "KeywordType"        => TokenType::KeywordType,

      # Names
      "Name"                 => TokenType::Name,
      "NameAttribute"        => TokenType::NameAttribute,
      "NameBuiltin"          => TokenType::NameBuiltin,
      "NameBuiltinPseudo"    => TokenType::NameBuiltinPseudo,
      "NameClass"            => TokenType::NameClass,
      "NameConstant"         => TokenType::NameConstant,
      "NameDecorator"        => TokenType::NameDecorator,
      "NameEntity"           => TokenType::NameEntity,
      "NameException"        => TokenType::NameException,
      "NameFunction"         => TokenType::NameFunction,
      "NameFunctionMagic"    => TokenType::NameFunctionMagic,
      "NameLabel"            => TokenType::NameLabel,
      "NameNamespace"        => TokenType::NameNamespace,
      "NameOther"            => TokenType::NameOther,
      "NameProperty"         => TokenType::NameProperty,
      "NameTag"              => TokenType::NameTag,
      "NameVariable"         => TokenType::NameVariable,
      "NameVariableClass"    => TokenType::NameVariableClass,
      "NameVariableGlobal"   => TokenType::NameVariableGlobal,
      "NameVariableInstance" => TokenType::NameVariableInstance,
      "NameVariableMagic"    => TokenType::NameVariableMagic,

      # Literals
      "Literal"                  => TokenType::Literal,
      "LiteralDate"              => TokenType::LiteralDate,
      "LiteralString"            => TokenType::LiteralString,
      "LiteralStringAffix"       => TokenType::LiteralStringAffix,
      "LiteralStringBacktick"    => TokenType::LiteralStringBacktick,
      "LiteralStringChar"        => TokenType::LiteralStringChar,
      "LiteralStringDelimiter"   => TokenType::LiteralStringDelimiter,
      "LiteralStringDoc"         => TokenType::LiteralStringDoc,
      "LiteralStringDouble"      => TokenType::LiteralStringDouble,
      "LiteralStringEscape"      => TokenType::LiteralStringEscape,
      "LiteralStringHeredoc"     => TokenType::LiteralStringHeredoc,
      "LiteralStringInterpol"    => TokenType::LiteralStringInterpol,
      "LiteralStringOther"       => TokenType::LiteralStringOther,
      "LiteralStringRegex"       => TokenType::LiteralStringRegex,
      "LiteralStringSingle"      => TokenType::LiteralStringSingle,
      "LiteralStringSymbol"      => TokenType::LiteralStringSymbol,
      "LiteralNumber"            => TokenType::LiteralNumber,
      "LiteralNumberBin"         => TokenType::LiteralNumberBin,
      "LiteralNumberFloat"       => TokenType::LiteralNumberFloat,
      "LiteralNumberHex"         => TokenType::LiteralNumberHex,
      "LiteralNumberInteger"     => TokenType::LiteralNumberInteger,
      "LiteralNumberIntegerLong" => TokenType::LiteralNumberIntegerLong,
      "LiteralNumberOct"         => TokenType::LiteralNumberOct,

      # Operators and punctuation
      "Operator"     => TokenType::Operator,
      "OperatorWord" => TokenType::OperatorWord,
      "Punctuation"  => TokenType::Punctuation,

      # Comments
      "Comment"            => TokenType::Comment,
      "CommentHashbang"    => TokenType::CommentHashbang,
      "CommentMultiline"   => TokenType::CommentMultiline,
      "CommentSingle"      => TokenType::CommentSingle,
      "CommentSpecial"     => TokenType::CommentSpecial,
      "CommentPreproc"     => TokenType::CommentPreproc,
      "CommentPreprocFile" => TokenType::CommentPreprocFile,

      # Generics
      "Generic"           => TokenType::Generic,
      "GenericDeleted"    => TokenType::GenericDeleted,
      "GenericEmph"       => TokenType::GenericEmph,
      "GenericError"      => TokenType::GenericError,
      "GenericHeading"    => TokenType::GenericHeading,
      "GenericInserted"   => TokenType::GenericInserted,
      "GenericOutput"     => TokenType::GenericOutput,
      "GenericPrompt"     => TokenType::GenericPrompt,
      "GenericStrong"     => TokenType::GenericStrong,
      "GenericSubheading" => TokenType::GenericSubheading,
      "GenericTraceback"  => TokenType::GenericTraceback,
      "GenericUnderline"  => TokenType::GenericEmph, # Map to existing type

      # Text subtypes
      "TextWhitespace"  => TokenType::TextWhitespace,
      "TextSymbol"      => TokenType::TextSymbol,
      "TextPunctuation" => TokenType::TextPunctuation,
    }

    def initialize(@content : String)
    end

    def parse(name : String) : Style
      document = XML.parse(@content)
      style_element = document.first_element_child

      unless style_element && style_element.name == "style"
        raise ThemeError.new("Invalid Chroma style: root element must be 'style'")
      end

      # Extract style name
      style_name = style_element["name"]? || name

      # First pass: find background color
      background_color = Color::WHITE
      style_element.children.each do |child|
        next unless child.name == "entry"
        type_attr = child["type"]?
        style_attr = child["style"]?

        if type_attr == "Background" && style_attr
          parsed_style = parse_style_definition(style_attr)
          if bg_color = parsed_style[:background]
            background_color = bg_color
          end
          break
        end
      end

      # Create style with determined background
      style = Style.new(style_name, background_color)

      # Second pass: process all entries
      style_element.children.each do |child|
        next unless child.name == "entry"
        process_entry(child, style)
      end

      style
    end

    private def process_entry(entry : XML::Node, style : Style)
      type_attr = entry["type"]?
      style_attr = entry["style"]?

      return unless type_attr && style_attr

      # Handle Background token specially
      if type_attr == "Background"
        parsed_style = parse_style_definition(style_attr)
        # Set Text token style if foreground color is specified
        if fg_color = parsed_style[:color]
          text_entry = create_style_entry(parsed_style)
          style.set(TokenType::Text, text_entry)
        end
        return
      end

      # Map Chroma token type to Obelisk token type
      token_type = TOKEN_MAPPINGS[type_attr]?
      return unless token_type

      # Parse style and create entry
      parsed_style = parse_style_definition(style_attr)
      style_entry = create_style_entry(parsed_style)
      style.set(token_type, style_entry)
    end

    private def parse_style_definition(style_def : String)
      color = nil.as(Color?)
      background = nil.as(Color?)
      bold = false
      italic = false
      underline = false

      # Split by spaces to handle multiple style attributes
      parts = style_def.split(/\s+/)

      parts.each do |part|
        case part
        when /^#[0-9a-fA-F]{3,6}$/
          # Foreground color
          color = Color.from_hex(part)
        when /^bg:#[0-9a-fA-F]{3,6}$/
          # Background color
          bg_color = part[3..] # Remove "bg:" prefix
          background = Color.from_hex(bg_color)
        when "bold"
          bold = true
        when "italic"
          italic = true
        when "underline"
          underline = true
        when /^border:#[0-9a-fA-F]{3,6}$/
          # Border colors are not supported in Obelisk, ignore
        end
      end

      {
        color:      color,
        background: background,
        bold:       bold,
        italic:     italic,
        underline:  underline,
      }
    end

    private def create_style_entry(parsed_style)
      builder = StyleBuilder.new

      if color = parsed_style[:color]
        builder.color(color)
      end

      if background = parsed_style[:background]
        builder.background(background)
      end

      if parsed_style[:bold]
        builder.bold
      end

      if parsed_style[:italic]
        builder.italic
      end

      if parsed_style[:underline]
        builder.underline
      end

      builder.build
    end
  end
end
