require "../style"

module Obelisk::Styles
  # Simple black and white theme
  BW = Style.new("bw", Color::WHITE).tap do |style|
    style.set(TokenType::Text, StyleBuilder.new.color("#000000").build)
    style.set(TokenType::Error, StyleBuilder.new.color("#000000").underline.build)
    style.set(TokenType::Comment, StyleBuilder.new.color("#808080").italic.build)
    style.set(TokenType::CommentSingle, StyleBuilder.new.color("#808080").italic.build)
    style.set(TokenType::CommentMultiline, StyleBuilder.new.color("#808080").italic.build)
    style.set(TokenType::Keyword, StyleBuilder.new.color("#000000").bold.build)
    style.set(TokenType::KeywordDeclaration, StyleBuilder.new.color("#000000").bold.build)
    style.set(TokenType::KeywordType, StyleBuilder.new.color("#000000").bold.build)
    style.set(TokenType::KeywordConstant, StyleBuilder.new.color("#000000").bold.build)
    style.set(TokenType::Name, StyleBuilder.new.color("#000000").build)
    style.set(TokenType::NameClass, StyleBuilder.new.color("#000000").bold.build)
    style.set(TokenType::NameFunction, StyleBuilder.new.color("#000000").bold.build)
    style.set(TokenType::NameConstant, StyleBuilder.new.color("#000000").bold.build)
    style.set(TokenType::LiteralString, StyleBuilder.new.color("#000000").italic.build)
    style.set(TokenType::LiteralStringDouble, StyleBuilder.new.color("#000000").italic.build)
    style.set(TokenType::LiteralStringSingle, StyleBuilder.new.color("#000000").italic.build)
    style.set(TokenType::LiteralStringBacktick, StyleBuilder.new.color("#000000").italic.build)
    style.set(TokenType::LiteralStringSymbol, StyleBuilder.new.color("#000000").italic.build)
    style.set(TokenType::LiteralNumber, StyleBuilder.new.color("#000000").build)
    style.set(TokenType::Operator, StyleBuilder.new.color("#000000").build)
    style.set(TokenType::Punctuation, StyleBuilder.new.color("#000000").build)
  end
end

# Register the style
Obelisk::Registry.styles.register(Obelisk::Styles::BW)
