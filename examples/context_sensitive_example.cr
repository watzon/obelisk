require "../src/obelisk"

# Example: Creating a context-sensitive lexer for a simple template language
class SimpleTemplateLexer < Obelisk::ConditionalLexer
  def config : Obelisk::LexerConfig
    Obelisk::LexerConfig.new(
      name: "simple-template",
      aliases: ["tmpl"],
      filenames: ["*.tmpl"],
      mime_types: ["text/x-template"]
    )
  end

  def initialize
    super()
    setup_rules
  end

  private def setup_rules
    # Template expression delimiters
    add_context_rule("root", Obelisk::ContextAwareRule.new(
      /\{\{/,
      Obelisk::RuleActions.push("expression", Obelisk::TokenType::LiteralStringInterpol),
      priority: 100
    ))

    add_context_rule("expression", Obelisk::ContextAwareRule.new(
      /\}\}/,
      Obelisk::RuleActions.pop(Obelisk::TokenType::LiteralStringInterpol),
      priority: 100
    ))

    # Variables in expressions
    add_context_rule("expression", Obelisk::ContextAwareRule.new(
      /[a-zA-Z_][a-zA-Z0-9_.]*/,
      Obelisk::TokenType::NameVariable,
      priority: 80
    ))

    # Keywords in expressions  
    add_context_rule("expression", Obelisk::ContextAwareRule.new(
      /\b(if|else|endif|for|endfor)\b/,
      Obelisk::TokenType::Keyword,
      priority: 90
    ))

    # Comments (only outside expressions)
    comment_condition = Obelisk::ContextConditions.not_in_state("expression")
    add_context_rule("root", Obelisk::ContextAwareRule.new(
      /{#.*?#}/m,
      Obelisk::TokenType::Comment,
      comment_condition,
      priority: 85
    ))

    # String literals in expressions
    add_context_rule("expression", Obelisk::ContextAwareRule.new(
      /"([^"\\]|\\.)*"/,
      Obelisk::TokenType::LiteralString,
      priority: 85
    ))

    # Numbers in expressions
    add_context_rule("expression", Obelisk::ContextAwareRule.new(
      /\d+(\.\d+)?/,
      Obelisk::TokenType::LiteralNumber,
      priority: 85
    ))

    # Operators in expressions
    add_context_rule("expression", Obelisk::ContextAwareRule.new(
      /[+\-*\/=<>!]+/,
      Obelisk::TokenType::Operator,
      priority: 70
    ))

    # Fallback rules
    add_fallback_rule("root", Obelisk::LexerRule.new(/[^{]+/, Obelisk::TokenType::Text))
    add_fallback_rule("expression", Obelisk::LexerRule.new(/\s+/, Obelisk::TokenType::Text))
    add_fallback_rule("expression", Obelisk::LexerRule.new(/[(),]/, Obelisk::TokenType::Punctuation))
  end
end

# Example usage
def demonstrate_template_lexer
  lexer = SimpleTemplateLexer.new

  template = <<-TEMPLATE
  <h1>Welcome {{ user.name }}!</h1>
  {# This is a comment #}
  {{ if user.age > 18 }}
    <p>You can vote!</p>
  {{ else }}
    <p>Too young to vote.</p>
  {{ endif }}

  <ul>
  {{ for item in items }}
    <li>{{ item.title }}: ${{ item.price }}</li>
  {{ endfor }}
  </ul>
  TEMPLATE

  puts "=== Template Source ==="
  puts template
  puts "\n=== Tokens ==="

  tokens = lexer.tokenize(template).to_a
  tokens.each_with_index do |token, i|
    next if token.type == Obelisk::TokenType::Text && token.value.strip.empty?
    
    type_name = token.type.to_s.split("::").last
    puts "%3d: %-20s %s" % [i, type_name, token.value.inspect]
  end

  puts "\n=== Context Statistics ==="
  stats = lexer.context_manager.stats
  stats.each { |key, value| puts "#{key}: #{value}" }
end

# Run the demonstration
demonstrate_template_lexer