require "./style"
require "./token"
require "./theme_loader"

module Obelisk
  # Exports themes to Chroma XML format
  class ChromaExporter
    # Obelisk TokenType to Chroma TokenType mapping (reverse of parser mapping)
    TOKEN_TO_CHROMA = {
      TokenType::Error => "Error",
      TokenType::Other => "Other",
      TokenType::Text  => "Text",

      # Keywords
      TokenType::Keyword            => "Keyword",
      TokenType::KeywordConstant    => "KeywordConstant",
      TokenType::KeywordDeclaration => "KeywordDeclaration",
      TokenType::KeywordNamespace   => "KeywordNamespace",
      TokenType::KeywordPseudo      => "KeywordPseudo",
      TokenType::KeywordReserved    => "KeywordReserved",
      TokenType::KeywordType        => "KeywordType",

      # Names
      TokenType::Name                 => "Name",
      TokenType::NameAttribute        => "NameAttribute",
      TokenType::NameBuiltin          => "NameBuiltin",
      TokenType::NameBuiltinPseudo    => "NameBuiltinPseudo",
      TokenType::NameClass            => "NameClass",
      TokenType::NameConstant         => "NameConstant",
      TokenType::NameDecorator        => "NameDecorator",
      TokenType::NameEntity           => "NameEntity",
      TokenType::NameException        => "NameException",
      TokenType::NameFunction         => "NameFunction",
      TokenType::NameFunctionMagic    => "NameFunctionMagic",
      TokenType::NameLabel            => "NameLabel",
      TokenType::NameNamespace        => "NameNamespace",
      TokenType::NameOther            => "NameOther",
      TokenType::NameProperty         => "NameProperty",
      TokenType::NameTag              => "NameTag",
      TokenType::NameVariable         => "NameVariable",
      TokenType::NameVariableClass    => "NameVariableClass",
      TokenType::NameVariableGlobal   => "NameVariableGlobal",
      TokenType::NameVariableInstance => "NameVariableInstance",
      TokenType::NameVariableMagic    => "NameVariableMagic",

      # Literals
      TokenType::Literal                  => "Literal",
      TokenType::LiteralDate              => "LiteralDate",
      TokenType::LiteralString            => "LiteralString",
      TokenType::LiteralStringAffix       => "LiteralStringAffix",
      TokenType::LiteralStringBacktick    => "LiteralStringBacktick",
      TokenType::LiteralStringChar        => "LiteralStringChar",
      TokenType::LiteralStringDelimiter   => "LiteralStringDelimiter",
      TokenType::LiteralStringDoc         => "LiteralStringDoc",
      TokenType::LiteralStringDouble      => "LiteralStringDouble",
      TokenType::LiteralStringEscape      => "LiteralStringEscape",
      TokenType::LiteralStringHeredoc     => "LiteralStringHeredoc",
      TokenType::LiteralStringInterpol    => "LiteralStringInterpol",
      TokenType::LiteralStringOther       => "LiteralStringOther",
      TokenType::LiteralStringRegex       => "LiteralStringRegex",
      TokenType::LiteralStringSingle      => "LiteralStringSingle",
      TokenType::LiteralStringSymbol      => "LiteralStringSymbol",
      TokenType::LiteralNumber            => "LiteralNumber",
      TokenType::LiteralNumberBin         => "LiteralNumberBin",
      TokenType::LiteralNumberFloat       => "LiteralNumberFloat",
      TokenType::LiteralNumberHex         => "LiteralNumberHex",
      TokenType::LiteralNumberInteger     => "LiteralNumberInteger",
      TokenType::LiteralNumberIntegerLong => "LiteralNumberIntegerLong",
      TokenType::LiteralNumberOct         => "LiteralNumberOct",

      # Operators and punctuation
      TokenType::Operator     => "Operator",
      TokenType::OperatorWord => "OperatorWord",
      TokenType::Punctuation  => "Punctuation",

      # Comments
      TokenType::Comment            => "Comment",
      TokenType::CommentHashbang    => "CommentHashbang",
      TokenType::CommentMultiline   => "CommentMultiline",
      TokenType::CommentSingle      => "CommentSingle",
      TokenType::CommentSpecial     => "CommentSpecial",
      TokenType::CommentPreproc     => "CommentPreproc",
      TokenType::CommentPreprocFile => "CommentPreprocFile",

      # Generics
      TokenType::Generic           => "Generic",
      TokenType::GenericDeleted    => "GenericDeleted",
      TokenType::GenericEmph       => "GenericEmph",
      TokenType::GenericError      => "GenericError",
      TokenType::GenericHeading    => "GenericHeading",
      TokenType::GenericInserted   => "GenericInserted",
      TokenType::GenericOutput     => "GenericOutput",
      TokenType::GenericPrompt     => "GenericPrompt",
      TokenType::GenericStrong     => "GenericStrong",
      TokenType::GenericSubheading => "GenericSubheading",
      TokenType::GenericTraceback  => "GenericTraceback",

      # Text subtypes
      TokenType::TextWhitespace  => "TextWhitespace",
      TokenType::TextSymbol      => "TextSymbol",
      TokenType::TextPunctuation => "TextPunctuation",
    }

    def initialize(@style : Style)
    end

    def export : String
      String.build do |xml|
        xml << %{<style name="#{escape_xml(@style.name)}">\n}

        # Export background entry first (special handling)
        export_background_entry(xml)

        # Export all other token-specific entries
        export_token_entries(xml)

        xml << %{</style>\n}
      end
    end

    private def export_background_entry(xml)
      # Chroma Background entry contains the theme background color
      xml << %{  <entry type="Background" style="bg:#{@style.background.to_hex}"/>\n}
    end

    private def export_token_entries(xml)
      TokenType.values.sort_by(&.to_s).each do |token_type|
        next if token_type.text? # Text is handled via Background

        if entry = @style.get_direct(token_type)
          if chroma_type = TOKEN_TO_CHROMA[token_type]?
            export_token_entry(xml, chroma_type, entry)
          end
        end
      end
    end

    private def export_token_entry(xml, chroma_type : String, entry : StyleEntry)
      style_parts = [] of String

      # Build style definition
      if entry.bold?
        style_parts << "bold"
      end

      if entry.italic?
        style_parts << "italic"
      end

      if entry.underline?
        style_parts << "underline"
      end

      if color = entry.color
        style_parts << color.to_hex
      end

      if background = entry.background
        style_parts << "bg:#{background.to_hex}"
      end

      # Only output if there are style attributes
      unless style_parts.empty?
        style_def = style_parts.join(" ")
        xml << %{  <entry type="#{chroma_type}" style="#{style_def}"/>\n}
      end
    end

    private def escape_xml(text : String) : String
      text.gsub('&', "&amp;")
        .gsub('<', "&lt;")
        .gsub('>', "&gt;")
        .gsub('"', "&quot;")
        .gsub('\'', "&apos;")
    end
  end
end
