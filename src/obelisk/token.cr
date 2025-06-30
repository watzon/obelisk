module Obelisk
  # Token types organized hierarchically like Chroma
  # Uses Crystal enums with methods for better type safety
  enum TokenType
    # Root types
    Error
    Other
    Keyword
    KeywordConstant
    KeywordDeclaration
    KeywordNamespace
    KeywordPseudo
    KeywordReserved
    KeywordType
    Name
    NameAttribute
    NameBuiltin
    NameBuiltinPseudo
    NameClass
    NameConstant
    NameDecorator
    NameEntity
    NameException
    NameFunction
    NameFunctionMagic
    NameLabel
    NameNamespace
    NameOther
    NameProperty
    NameTag
    NameVariable
    NameVariableClass
    NameVariableGlobal
    NameVariableInstance
    NameVariableMagic
    Literal
    LiteralDate
    LiteralString
    LiteralStringAffix
    LiteralStringBacktick
    LiteralStringChar
    LiteralStringDelimiter
    LiteralStringDoc
    LiteralStringDouble
    LiteralStringEscape
    LiteralStringHeredoc
    LiteralStringInterpol
    LiteralStringOther
    LiteralStringRegex
    LiteralStringSingle
    LiteralStringSymbol
    LiteralNumber
    LiteralNumberBin
    LiteralNumberFloat
    LiteralNumberHex
    LiteralNumberInteger
    LiteralNumberIntegerLong
    LiteralNumberOct
    Operator
    OperatorWord
    Punctuation
    Comment
    CommentHashbang
    CommentMultiline
    CommentSingle
    CommentSpecial
    CommentPreproc
    CommentPreprocFile
    Generic
    GenericDeleted
    GenericEmph
    GenericError
    GenericHeading
    GenericInserted
    GenericOutput
    GenericPrompt
    GenericStrong
    GenericSubheading
    GenericTraceback
    Text
    TextWhitespace
    TextSymbol
    TextPunctuation

    # Get the parent category of this token type
    def parent : TokenType
      case self
      when .keyword_constant?, .keyword_declaration?, .keyword_namespace?, .keyword_pseudo?, .keyword_reserved?, .keyword_type?
        TokenType::Keyword
      when .name_attribute?, .name_builtin?, .name_builtin_pseudo?, .name_class?, .name_constant?, .name_decorator?, .name_entity?, .name_exception?, .name_function?, .name_function_magic?, .name_label?, .name_namespace?, .name_other?, .name_property?, .name_tag?, .name_variable?, .name_variable_class?, .name_variable_global?, .name_variable_instance?, .name_variable_magic?
        TokenType::Name
      when .literal_string_affix?, .literal_string_backtick?, .literal_string_char?, .literal_string_delimiter?, .literal_string_doc?, .literal_string_double?, .literal_string_escape?, .literal_string_heredoc?, .literal_string_interpol?, .literal_string_other?, .literal_string_regex?, .literal_string_single?, .literal_string_symbol?
        TokenType::LiteralString
      when .literal_number_bin?, .literal_number_float?, .literal_number_hex?, .literal_number_integer?, .literal_number_integer_long?, .literal_number_oct?
        TokenType::LiteralNumber
      when .literal_date?, .literal_string?, .literal_number?
        TokenType::Literal
      when .operator_word?
        TokenType::Operator
      when .comment_hashbang?, .comment_multiline?, .comment_single?, .comment_special?, .comment_preproc?, .comment_preproc_file?
        TokenType::Comment
      when .generic_deleted?, .generic_emph?, .generic_error?, .generic_heading?, .generic_inserted?, .generic_output?, .generic_prompt?, .generic_strong?, .generic_subheading?, .generic_traceback?
        TokenType::Generic
      when .text_whitespace?, .text_symbol?, .text_punctuation?
        TokenType::Text
      else
        self
      end
    end

    # Get the CSS class name for this token type
    def css_class : String
      case self
      when .error?
        "err"
      when .keyword?
        "k"
      when .keyword_constant?
        "kc"
      when .keyword_declaration?
        "kd"
      when .keyword_namespace?
        "kn"
      when .keyword_pseudo?
        "kp"
      when .keyword_reserved?
        "kr"
      when .keyword_type?
        "kt"
      when .name?
        "n"
      when .name_attribute?
        "na"
      when .name_builtin?
        "nb"
      when .name_builtin_pseudo?
        "bp"
      when .name_class?
        "nc"
      when .name_constant?
        "no"
      when .name_decorator?
        "nd"
      when .name_entity?
        "ni"
      when .name_exception?
        "ne"
      when .name_function?
        "nf"
      when .name_function_magic?
        "fm"
      when .name_label?
        "nl"
      when .name_namespace?
        "nn"
      when .name_other?
        "nx"
      when .name_property?
        "py"
      when .name_tag?
        "nt"
      when .name_variable?
        "nv"
      when .name_variable_class?
        "vc"
      when .name_variable_global?
        "vg"
      when .name_variable_instance?
        "vi"
      when .name_variable_magic?
        "vm"
      when .literal?
        "l"
      when .literal_date?
        "ld"
      when .literal_string?
        "s"
      when .literal_string_affix?
        "sa"
      when .literal_string_backtick?
        "sb"
      when .literal_string_char?
        "sc"
      when .literal_string_delimiter?
        "dl"
      when .literal_string_doc?
        "sd"
      when .literal_string_double?
        "s2"
      when .literal_string_escape?
        "se"
      when .literal_string_heredoc?
        "sh"
      when .literal_string_interpol?
        "si"
      when .literal_string_other?
        "sx"
      when .literal_string_regex?
        "sr"
      when .literal_string_single?
        "s1"
      when .literal_string_symbol?
        "ss"
      when .literal_number?
        "m"
      when .literal_number_bin?
        "mb"
      when .literal_number_float?
        "mf"
      when .literal_number_hex?
        "mh"
      when .literal_number_integer?
        "mi"
      when .literal_number_integer_long?
        "il"
      when .literal_number_oct?
        "mo"
      when .operator?
        "o"
      when .operator_word?
        "ow"
      when .punctuation?
        "p"
      when .comment?
        "c"
      when .comment_hashbang?
        "ch"
      when .comment_multiline?
        "cm"
      when .comment_single?
        "c1"
      when .comment_special?
        "cs"
      when .comment_preproc?
        "cp"
      when .comment_preproc_file?
        "cpf"
      when .generic?
        "g"
      when .generic_deleted?
        "gd"
      when .generic_emph?
        "ge"
      when .generic_error?
        "gr"
      when .generic_heading?
        "gh"
      when .generic_inserted?
        "gi"
      when .generic_output?
        "go"
      when .generic_prompt?
        "gp"
      when .generic_strong?
        "gs"
      when .generic_subheading?
        "gu"
      when .generic_traceback?
        "gt"
      when .text?
        ""
      when .text_whitespace?
        "w"
      when .text_symbol?
        ""
      when .text_punctuation?
        "p"
      else
        ""
      end
    end

    # Check if this token type is in a specific category
    def in_category?(category : TokenType) : Bool
      current = self
      while current != current.parent  # Avoid infinite loop
        return true if current == category
        current = current.parent
      end
      current == category
    end
  end

  # Represents a single token with its type and value
  class Token
    getter type : TokenType
    getter value : String

    def initialize(@type : TokenType, @value : String)
    end

    # Clone this token
    def clone : Token
      Token.new(@type, @value)
    end

    # Check if this is an EOF token
    def eof? : Bool
      @value.empty? && @type == TokenType::Text
    end

    # Get the CSS class for this token
    def css_class : String
      @type.css_class
    end

    def to_s(io : IO) : Nil
      io << "Token(#{@type}, #{@value.inspect})"
    end
  end

  # Special EOF token
  EOF_TOKEN = Token.new(TokenType::Text, "")
end