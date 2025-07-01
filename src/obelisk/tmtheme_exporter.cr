require "./style"
require "./token"
require "./theme_loader"

module Obelisk
  # Exports themes to TextMate .tmTheme XML plist format
  class TmThemeExporter
    # TokenType to TextMate scope mapping
    TOKEN_TO_SCOPE = {
      TokenType::Comment          => "comment",
      TokenType::CommentSingle    => "comment.line",
      TokenType::CommentMultiline => "comment.block",
      TokenType::CommentHashbang  => "comment.line.shebang",
      TokenType::CommentPreproc   => "comment.block.preprocessor",
      TokenType::CommentSpecial   => "comment.block.documentation",

      TokenType::LiteralString         => "string",
      TokenType::LiteralStringSingle   => "string.quoted.single",
      TokenType::LiteralStringDouble   => "string.quoted.double",
      TokenType::LiteralStringBacktick => "string.quoted.other",
      TokenType::LiteralStringHeredoc  => "string.unquoted.heredoc",
      TokenType::LiteralStringInterpol => "string.interpolated",
      TokenType::LiteralStringRegex    => "string.regexp",
      TokenType::LiteralStringEscape   => "constant.character.escape",
      TokenType::LiteralStringSymbol   => "constant.other.symbol",

      TokenType::LiteralNumber        => "constant.numeric",
      TokenType::LiteralNumberInteger => "constant.numeric.integer",
      TokenType::LiteralNumberFloat   => "constant.numeric.float",
      TokenType::LiteralNumberHex     => "constant.numeric.hex",
      TokenType::LiteralNumberOct     => "constant.numeric.octal",
      TokenType::LiteralNumberBin     => "constant.numeric.binary",

      TokenType::Keyword            => "keyword",
      TokenType::KeywordConstant    => "keyword.other",
      TokenType::KeywordDeclaration => "storage.type",
      TokenType::KeywordNamespace   => "keyword.other",
      TokenType::KeywordPseudo      => "keyword.other",
      TokenType::KeywordReserved    => "keyword.control",
      TokenType::KeywordType        => "storage.type",

      TokenType::NameVariable         => "variable",
      TokenType::NameVariableClass    => "variable.other.class",
      TokenType::NameVariableGlobal   => "variable.other.global",
      TokenType::NameVariableInstance => "variable.other.instance",
      TokenType::NameVariableMagic    => "variable.language",

      TokenType::NameFunction      => "entity.name.function",
      TokenType::NameFunctionMagic => "entity.name.function.magic",
      TokenType::NameClass         => "entity.name.class",
      TokenType::NameNamespace     => "entity.name.namespace",
      TokenType::NameTag           => "entity.name.tag",
      TokenType::NameAttribute     => "entity.other.attribute-name",
      TokenType::NameConstant      => "constant.other",
      TokenType::NameBuiltin       => "support.function",
      TokenType::NameBuiltinPseudo => "support.function",
      TokenType::NameDecorator     => "entity.name.decorator",
      TokenType::NameEntity        => "entity.name",
      TokenType::NameException     => "entity.name.exception",
      TokenType::NameLabel         => "entity.name.label",
      TokenType::NameProperty      => "variable.other.property",

      TokenType::Operator     => "keyword.operator",
      TokenType::OperatorWord => "keyword.operator",
      TokenType::Punctuation  => "punctuation",

      TokenType::Error => "invalid.illegal",
      TokenType::Other => "source",
      TokenType::Text  => "text",

      TokenType::GenericHeading    => "markup.heading",
      TokenType::GenericSubheading => "markup.heading",
      TokenType::GenericStrong     => "markup.bold",
      TokenType::GenericEmph       => "markup.italic",
      TokenType::GenericDeleted    => "markup.deleted",
      TokenType::GenericInserted   => "markup.inserted",
      TokenType::GenericError      => "markup.error",
      TokenType::GenericOutput     => "markup.output",
      TokenType::GenericPrompt     => "markup.prompt",
      TokenType::GenericTraceback  => "markup.traceback",
    }

    def initialize(@style : Style)
    end

    def export : String
      String.build do |xml|
        xml << %{<?xml version="1.0" encoding="UTF-8"?>\n}
        xml << %{<!DOCTYPE plist PUBLIC "-//Apple Computer//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">\n}
        xml << %{<plist version="1.0">\n}
        xml << %{<dict>\n}

        # Theme name
        xml << %{\t<key>name</key>\n}
        xml << %{\t<string>#{escape_xml(@style.name)}</string>\n}

        # Settings array
        xml << %{\t<key>settings</key>\n}
        xml << %{\t<array>\n}

        # Global settings
        export_global_settings(xml)

        # Token-specific settings
        export_token_settings(xml)

        xml << %{\t</array>\n}

        # UUID (generate a random one)
        uuid = Random::Secure.hex(16).insert(8, '-').insert(13, '-').insert(18, '-').insert(23, '-')
        xml << %{\t<key>uuid</key>\n}
        xml << %{\t<string>#{uuid.upcase}</string>\n}

        xml << %{</dict>\n}
        xml << %{</plist>\n}
      end
    end

    private def export_global_settings(xml)
      xml << %{\t\t<dict>\n}
      xml << %{\t\t\t<key>settings</key>\n}
      xml << %{\t\t\t<dict>\n}
      xml << %{\t\t\t\t<key>background</key>\n}
      xml << %{\t\t\t\t<string>#{@style.background.to_hex}</string>\n}

      # Try to get foreground from Text token
      if text_style = @style.get_direct(TokenType::Text)
        if color = text_style.color
          xml << %{\t\t\t\t<key>foreground</key>\n}
          xml << %{\t\t\t\t<string>#{color.to_hex}</string>\n}
        end
      end

      # Add some default UI colors based on background brightness
      if @style.background.brightness < 0.5
        # Dark theme defaults
        xml << %{\t\t\t\t<key>caret</key>\n}
        xml << %{\t\t\t\t<string>#FFFFFF</string>\n}
        xml << %{\t\t\t\t<key>selection</key>\n}
        xml << %{\t\t\t\t<string>#404040</string>\n}
        xml << %{\t\t\t\t<key>invisibles</key>\n}
        xml << %{\t\t\t\t<string>#404040</string>\n}
        xml << %{\t\t\t\t<key>lineHighlight</key>\n}
        xml << %{\t\t\t\t<string>#2F2F2F</string>\n}
      else
        # Light theme defaults
        xml << %{\t\t\t\t<key>caret</key>\n}
        xml << %{\t\t\t\t<string>#000000</string>\n}
        xml << %{\t\t\t\t<key>selection</key>\n}
        xml << %{\t\t\t\t<string>#D3D3D3</string>\n}
        xml << %{\t\t\t\t<key>invisibles</key>\n}
        xml << %{\t\t\t\t<string>#BFBFBF</string>\n}
        xml << %{\t\t\t\t<key>lineHighlight</key>\n}
        xml << %{\t\t\t\t<string>#F0F0F0</string>\n}
      end

      xml << %{\t\t\t</dict>\n}
      xml << %{\t\t</dict>\n}
    end

    private def export_token_settings(xml)
      TokenType.values.each do |token_type|
        next if token_type.text? # Skip text token as it's handled in global settings

        if entry = @style.get_direct(token_type)
          if scope = TOKEN_TO_SCOPE[token_type]?
            export_token_setting(xml, scope, entry, humanize_token_name(token_type))
          end
        end
      end
    end

    private def export_token_setting(xml, scope : String, entry : StyleEntry, name : String)
      xml << %{\t\t<dict>\n}
      xml << %{\t\t\t<key>name</key>\n}
      xml << %{\t\t\t<string>#{escape_xml(name)}</string>\n}
      xml << %{\t\t\t<key>scope</key>\n}
      xml << %{\t\t\t<string>#{scope}</string>\n}
      xml << %{\t\t\t<key>settings</key>\n}
      xml << %{\t\t\t<dict>\n}

      if color = entry.color
        xml << %{\t\t\t\t<key>foreground</key>\n}
        xml << %{\t\t\t\t<string>#{color.to_hex}</string>\n}
      end

      if background = entry.background
        xml << %{\t\t\t\t<key>background</key>\n}
        xml << %{\t\t\t\t<string>#{background.to_hex}</string>\n}
      end

      # Build font style string
      font_styles = [] of String
      font_styles << "bold" if entry.bold?
      font_styles << "italic" if entry.italic?
      font_styles << "underline" if entry.underline?

      if !font_styles.empty?
        xml << %{\t\t\t\t<key>fontStyle</key>\n}
        xml << %{\t\t\t\t<string>#{font_styles.join(" ")}</string>\n}
      end

      xml << %{\t\t\t</dict>\n}
      xml << %{\t\t</dict>\n}
    end

    private def humanize_token_name(token_type : TokenType) : String
      # Convert TokenType enum name to human readable format
      token_type.to_s.gsub(/([a-z])([A-Z])/, "\\1 \\2")
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
