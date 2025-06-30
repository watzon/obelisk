require "../style"

module Obelisk::Styles
  # GitHub-like style
  GITHUB = Style.new("github", Color.from_hex("#ffffff")).tap do |style|
    style.set(TokenType::Text, StyleBuilder.new.color("#24292e").build)
    style.set(TokenType::Error, StyleBuilder.new.color("#ff0000").build)
    style.set(TokenType::Comment, StyleBuilder.new.color("#6a737d").italic.build)
    style.set(TokenType::CommentSingle, StyleBuilder.new.color("#6a737d").italic.build)
    style.set(TokenType::CommentMultiline, StyleBuilder.new.color("#6a737d").italic.build)
    style.set(TokenType::Keyword, StyleBuilder.new.color("#d73a49").bold.build)
    style.set(TokenType::KeywordDeclaration, StyleBuilder.new.color("#d73a49").bold.build)
    style.set(TokenType::KeywordType, StyleBuilder.new.color("#d73a49").bold.build)
    style.set(TokenType::KeywordConstant, StyleBuilder.new.color("#d73a49").bold.build)
    style.set(TokenType::Name, StyleBuilder.new.color("#24292e").build)
    style.set(TokenType::NameClass, StyleBuilder.new.color("#6f42c1").build)
    style.set(TokenType::NameFunction, StyleBuilder.new.color("#6f42c1").build)
    style.set(TokenType::NameVariable, StyleBuilder.new.color("#e36209").build)
    style.set(TokenType::NameVariableInstance, StyleBuilder.new.color("#e36209").build)
    style.set(TokenType::NameVariableClass, StyleBuilder.new.color("#e36209").build)
    style.set(TokenType::NameVariableGlobal, StyleBuilder.new.color("#e36209").build)
    style.set(TokenType::NameConstant, StyleBuilder.new.color("#005cc5").build)
    style.set(TokenType::LiteralString, StyleBuilder.new.color("#032f62").build)
    style.set(TokenType::LiteralStringDouble, StyleBuilder.new.color("#032f62").build)
    style.set(TokenType::LiteralStringSingle, StyleBuilder.new.color("#032f62").build)
    style.set(TokenType::LiteralStringBacktick, StyleBuilder.new.color("#032f62").build)
    style.set(TokenType::LiteralStringSymbol, StyleBuilder.new.color("#032f62").build)
    style.set(TokenType::LiteralStringInterpol, StyleBuilder.new.color("#032f62").build)
    style.set(TokenType::LiteralStringEscape, StyleBuilder.new.color("#032f62").bold.build)
    style.set(TokenType::LiteralNumber, StyleBuilder.new.color("#005cc5").build)
    style.set(TokenType::LiteralNumberInteger, StyleBuilder.new.color("#005cc5").build)
    style.set(TokenType::LiteralNumberFloat, StyleBuilder.new.color("#005cc5").build)
    style.set(TokenType::LiteralNumberHex, StyleBuilder.new.color("#005cc5").build)
    style.set(TokenType::LiteralNumberBin, StyleBuilder.new.color("#005cc5").build)
    style.set(TokenType::LiteralNumberOct, StyleBuilder.new.color("#005cc5").build)
    style.set(TokenType::Operator, StyleBuilder.new.color("#24292e").build)
    style.set(TokenType::Punctuation, StyleBuilder.new.color("#24292e").build)
  end
end

# Register the style
Obelisk::Registry.styles.register(Obelisk::Styles::GITHUB)