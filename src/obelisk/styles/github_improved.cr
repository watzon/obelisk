require "../style"

module Obelisk::Styles
  # GitHub-like style using token hierarchy inheritance
  # This demonstrates how to use inheritance to reduce repetition
  GITHUB_IMPROVED = Style.new("github-improved", Color.from_hex("#ffffff")).tap do |style|
    # Base styles
    style.set(TokenType::Text, StyleBuilder.new.color("#24292e").build)
    style.set(TokenType::Error, StyleBuilder.new.color("#ff0000").build)
    
    # Comment category - all comment types inherit this
    style.set(TokenType::Comment, StyleBuilder.new.color("#6a737d").italic.build)
    # No need to set CommentSingle, CommentMultiline - they inherit from Comment
    
    # Keyword category - all keyword types inherit this
    style.set(TokenType::Keyword, StyleBuilder.new.color("#d73a49").bold.build)
    # No need to set KeywordDeclaration, KeywordType, KeywordConstant - they inherit
    
    # Name category
    style.set(TokenType::Name, StyleBuilder.new.color("#24292e").build)
    style.set(TokenType::NameClass, StyleBuilder.new.color("#6f42c1").build)
    style.set(TokenType::NameFunction, StyleBuilder.new.color("#6f42c1").build)
    
    # Variable names inherit a common style
    style.set(TokenType::NameVariable, StyleBuilder.new.color("#e36209").build)
    # NameVariableInstance, NameVariableClass, NameVariableGlobal inherit from NameVariable
    
    style.set(TokenType::NameConstant, StyleBuilder.new.color("#005cc5").build)
    
    # String literals - base style
    style.set(TokenType::LiteralString, StyleBuilder.new.color("#032f62").build)
    # All string subtypes inherit from LiteralString
    # Only override escape sequences
    style.set(TokenType::LiteralStringEscape, StyleBuilder.new.color("#032f62").bold.build)
    
    # Number literals - base style
    style.set(TokenType::LiteralNumber, StyleBuilder.new.color("#005cc5").build)
    # All number subtypes (Integer, Float, Hex, Bin, Oct) inherit from LiteralNumber
    
    # Operators and punctuation
    style.set(TokenType::Operator, StyleBuilder.new.color("#24292e").build)
    style.set(TokenType::Punctuation, StyleBuilder.new.color("#24292e").build)
  end
end

# Register the improved style
Obelisk::Registry.styles.register(Obelisk::Styles::GITHUB_IMPROVED)