require "./style"
require "./token"
require "./theme_loader"
require "./tmtheme_exporter"
require "./chroma_exporter"
require "json"

module Obelisk
  # Handles exporting themes to various formats
  module ThemeExporter
    # Export a style to JSON format (native Obelisk format)
    def self.to_json(style : Style, pretty : Bool = true) : String
      tokens = {} of String => JSON::Any
      
      # Export all token styles
      TokenType.values.each do |token_type|
        if entry = style.get_direct(token_type)
          tokens[token_type_to_string(token_type)] = style_entry_to_json(entry)
        end
      end

      data = {
        "name" => style.name,
        "background" => style.background.to_hex,
        "tokens" => tokens
      }

      if pretty
        data.to_pretty_json
      else
        data.to_json
      end
    end

    # Export a style to tmTheme XML format
    def self.to_tmtheme(style : Style) : String
      exporter = TmThemeExporter.new(style)
      exporter.export
    end

    # Export a style to VS Code JSON theme format
    def self.to_vscode(style : Style) : String
      # This will be implemented in the next iteration
      raise ThemeError.new("VS Code theme export not yet implemented")
    end

    # Export a style to Chroma XML format
    def self.to_chroma(style : Style) : String
      exporter = ChromaExporter.new(style)
      exporter.export
    end

    # Save a style to a file with format auto-detection
    def self.save(style : Style, path : String, format : ThemeLoader::Format? = nil) : Nil
      format ||= detect_format_from_path(path)
      
      content = case format
      when .json?
        to_json(style)
      when .tm_theme?
        to_tmtheme(style)
      when .vs_code?
        to_vscode(style)
      when .chroma?
        to_chroma(style)
      else
        raise ThemeError.new("Unsupported export format")
      end

      File.write(path, content)
    end

    # Convert TokenType enum to string representation
    private def self.token_type_to_string(token_type : TokenType) : String
      case token_type
      when .text? then "text"
      when .error? then "error"
      when .other? then "other"
      when .keyword? then "keyword"
      when .keyword_constant? then "keyword.constant"
      when .keyword_declaration? then "keyword.declaration"
      when .keyword_namespace? then "keyword.namespace"
      when .keyword_pseudo? then "keyword.pseudo"
      when .keyword_reserved? then "keyword.reserved"
      when .keyword_type? then "keyword.type"
      when .name? then "name"
      when .name_attribute? then "name.attribute"
      when .name_builtin? then "name.builtin"
      when .name_builtin_pseudo? then "name.builtin.pseudo"
      when .name_class? then "name.class"
      when .name_constant? then "name.constant"
      when .name_decorator? then "name.decorator"
      when .name_entity? then "name.entity"
      when .name_exception? then "name.exception"
      when .name_function? then "name.function"
      when .name_function_magic? then "name.function.magic"
      when .name_label? then "name.label"
      when .name_namespace? then "name.namespace"
      when .name_other? then "name.other"
      when .name_property? then "name.property"
      when .name_tag? then "name.tag"
      when .name_variable? then "name.variable"
      when .name_variable_class? then "name.variable.class"
      when .name_variable_global? then "name.variable.global"
      when .name_variable_instance? then "name.variable.instance"
      when .name_variable_magic? then "name.variable.magic"
      when .literal? then "literal"
      when .literal_date? then "literal.date"
      when .literal_number? then "literal.number"
      when .literal_number_bin? then "literal.number.binary"
      when .literal_number_float? then "literal.number.float"
      when .literal_number_hex? then "literal.number.hex"
      when .literal_number_integer? then "literal.number.integer"
      when .literal_number_integer_long? then "literal.number.integer.long"
      when .literal_number_oct? then "literal.number.oct"
      when .literal_string? then "literal.string"
      when .literal_string_affix? then "literal.string.affix"
      when .literal_string_backtick? then "literal.string.backtick"
      when .literal_string_char? then "literal.string.char"
      when .literal_string_delimiter? then "literal.string.delimiter"
      when .literal_string_doc? then "literal.string.doc"
      when .literal_string_double? then "literal.string.double"
      when .literal_string_escape? then "literal.string.escape"
      when .literal_string_heredoc? then "literal.string.heredoc"
      when .literal_string_interpol? then "literal.string.interpol"
      when .literal_string_other? then "literal.string.other"
      when .literal_string_regex? then "literal.string.regex"
      when .literal_string_single? then "literal.string.single"
      when .literal_string_symbol? then "literal.string.symbol"
      when .operator? then "operator"
      when .operator_word? then "operator.word"
      when .punctuation? then "punctuation"
      when .comment? then "comment"
      when .comment_hashbang? then "comment.hashbang"
      when .comment_multiline? then "comment.multiline"
      when .comment_preproc? then "comment.preproc"
      when .comment_preproc_file? then "comment.preprocfile"
      when .comment_single? then "comment.single"
      when .comment_special? then "comment.special"
      when .generic? then "generic"
      when .generic_deleted? then "generic.deleted"
      when .generic_emph? then "generic.emph"
      when .generic_error? then "generic.error"
      when .generic_heading? then "generic.heading"
      when .generic_inserted? then "generic.inserted"
      when .generic_output? then "generic.output"
      when .generic_prompt? then "generic.prompt"
      when .generic_strong? then "generic.strong"
      when .generic_subheading? then "generic.subheading"
      when .generic_traceback? then "generic.traceback"
      else
        token_type.to_s.downcase
      end
    end

    # Convert StyleEntry to JSON representation
    private def self.style_entry_to_json(entry : StyleEntry) : JSON::Any
      json_data = {} of String => JSON::Any

      if color = entry.color
        json_data["color"] = JSON::Any.new(color.to_hex)
      end

      if background = entry.background
        json_data["background"] = JSON::Any.new(background.to_hex)
      end

      case entry.bold
      when .yes?
        json_data["bold"] = JSON::Any.new(true)
      when .no?
        json_data["bold"] = JSON::Any.new(false)
      end

      case entry.italic
      when .yes?
        json_data["italic"] = JSON::Any.new(true)
      when .no?
        json_data["italic"] = JSON::Any.new(false)
      end

      case entry.underline
      when .yes?
        json_data["underline"] = JSON::Any.new(true)
      when .no?
        json_data["underline"] = JSON::Any.new(false)
      end

      if entry.no_inherit
        json_data["noInherit"] = JSON::Any.new(true)
      end

      JSON::Any.new(json_data)
    end

    # Detect export format from file path
    private def self.detect_format_from_path(path : String) : ThemeLoader::Format
      case File.extname(path).downcase
      when ".json"
        ThemeLoader::Format::JSON
      when ".tmtheme"
        ThemeLoader::Format::TmTheme
      when ".xml"
        ThemeLoader::Format::Chroma
      else
        raise ThemeError.new("Cannot determine format from file extension: #{path}")
      end
    end
  end
end