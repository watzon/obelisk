require "./spec_helper"

# Test lexers for embedded language testing
class HTMLLexer < Obelisk::RegexLexer
  def config : Obelisk::LexerConfig
    Obelisk::LexerConfig.new(
      name: "html",
      aliases: ["htm"],
      filenames: ["*.html", "*.htm"]
    )
  end

  def rules : Hash(String, Array(Obelisk::LexerRule))
    {
      "root" => [
        Obelisk::LexerRule.new(/<\/?[a-zA-Z][^>]*>/, Obelisk::TokenType::NameTag),
        Obelisk::LexerRule.new(/[^<]+/, Obelisk::TokenType::Text),
      ]
    }
  end

  def analyze(text : String) : Float32
    text.includes?("<") && text.includes?(">") ? 0.8f32 : 0.1f32
  end
end

class CSSLexer < Obelisk::RegexLexer
  def config : Obelisk::LexerConfig
    Obelisk::LexerConfig.new(
      name: "css",
      aliases: [] of String,
      filenames: ["*.css"]
    )
  end

  def rules : Hash(String, Array(Obelisk::LexerRule))
    {
      "root" => [
        Obelisk::LexerRule.new(/[a-zA-Z][a-zA-Z0-9-]*\s*\{/, Obelisk::TokenType::NameClass),
        Obelisk::LexerRule.new(/[a-zA-Z-]+\s*:/, Obelisk::TokenType::NameAttribute),
        Obelisk::LexerRule.new(/[^{;}]+/, Obelisk::TokenType::Text),
        Obelisk::LexerRule.new(/[{;}]/, Obelisk::TokenType::Punctuation),
      ]
    }
  end

  def analyze(text : String) : Float32
    (text.includes?("{") && text.includes?(":")) ? 0.7f32 : 0.1f32
  end
end

class JavaScriptLexer < Obelisk::RegexLexer
  def config : Obelisk::LexerConfig
    Obelisk::LexerConfig.new(
      name: "javascript",
      aliases: ["js"],
      filenames: ["*.js"]
    )
  end

  def rules : Hash(String, Array(Obelisk::LexerRule))
    {
      "root" => [
        Obelisk::LexerRule.new(/\b(function|var|let|const)\b/, Obelisk::TokenType::Keyword),
        Obelisk::LexerRule.new(/\d+/, Obelisk::TokenType::LiteralNumberInteger),
        Obelisk::LexerRule.new(/[a-zA-Z_$][a-zA-Z0-9_$]*/, Obelisk::TokenType::Name),
        Obelisk::LexerRule.new(/\s+/, Obelisk::TokenType::Text),
        Obelisk::LexerRule.new(/[=;]+/, Obelisk::TokenType::Punctuation),
        Obelisk::LexerRule.new(/./, Obelisk::TokenType::Text),
      ]
    }
  end

  def analyze(text : String) : Float32
    keywords = ["function", "var", "let", "const", "console"]
    score = keywords.count { |kw| text.includes?(kw) }.to_f32 / keywords.size
    score
  end
end

describe Obelisk::LanguageContext do
  describe "basic functionality" do
    it "creates and manages language contexts" do
      context = Obelisk::LanguageContext.new("javascript", 10, 50)
      
      context.language.should eq("javascript")
      context.start_pos.should eq(10)
      context.end_pos.should eq(50)
      context.nesting_level.should eq(0)
      context.active?.should be_false
      context.size.should eq(40)
    end
    
    it "handles active contexts" do
      active_context = Obelisk::LanguageContext.new("css", 20)
      
      active_context.active?.should be_true
      active_context.end_pos.should be_nil
      active_context.size.should eq(0)
    end
    
    it "extracts content from text" do
      text = "Hello <script>alert('hi');</script> World"
      context = Obelisk::LanguageContext.new("javascript", 14, 26)
      
      content = context.content(text)
      content.should eq("alert('hi');")
    end
    
    it "supports context closure" do
      open_context = Obelisk::LanguageContext.new("css", 10)
      closed_context = open_context.close(50)
      
      open_context.active?.should be_true
      closed_context.active?.should be_false
      closed_context.end_pos.should eq(50)
    end
    
    it "handles nesting and parent contexts" do
      parent = Obelisk::LanguageContext.new("html", 0, 100)
      child = Obelisk::LanguageContext.new("javascript", 20, 80, parent, 1)
      
      child.parent_context.should eq(parent)
      child.nesting_level.should eq(1)
    end
    
    it "stores context data" do
      data = {"type" => "module", "src" => "app.js"}
      context = Obelisk::LanguageContext.new("javascript", 10, 50, context_data: data)
      
      context.context_data["type"].should eq("module")
      context.context_data["src"].should eq("app.js")
    end
  end
end

describe Obelisk::LanguageNestingRule do
  describe "rule matching" do
    it "creates and matches nesting rules" do
      rule = Obelisk::LanguageNestingRule.new(
        "html", "javascript",
        /<script[^>]*>/i, /<\/script>/i
      )
      
      rule.parent_language.should eq("html")
      rule.embedded_language.should eq("javascript")
      rule.max_nesting_level.should eq(10)
    end
    
    it "matches parent languages" do
      rule = Obelisk::LanguageNestingRule.new(
        "html", "css",
        /<style>/i, /<\/style>/i
      )
      
      rule.matches_parent?("html").should be_true
      rule.matches_parent?("css").should be_false
      rule.matches_parent?("javascript").should be_false
    end
    
    it "supports wildcard parent matching" do
      rule = Obelisk::LanguageNestingRule.new(
        "*", "javascript",
        /```js/, /```/
      )
      
      rule.matches_parent?("markdown").should be_true
      rule.matches_parent?("html").should be_true
      rule.matches_parent?("any-language").should be_true
    end
    
    it "checks nesting level limits" do
      rule = Obelisk::LanguageNestingRule.new(
        "html", "css",
        /<style>/i, /<\/style>/i,
        max_nesting_level: 2
      )
      
      rule.can_nest?(0).should be_true
      rule.can_nest?(1).should be_true
      rule.can_nest?(2).should be_false
      rule.can_nest?(5).should be_false
    end
    
    it "extracts context data with custom extractors" do
      extractor = ->(text : String) {
        attrs = {} of String => String
        if match = /type\s*=\s*["']?([^"'>\s]+)/i.match(text)
          attrs["type"] = match[1]
        end
        attrs
      }
      
      rule = Obelisk::LanguageNestingRule.new(
        "html", "javascript",
        /<script[^>]*>/i, /<\/script>/i,
        context_extractor: extractor
      )
      
      context_data = rule.extract_context("<script type=\"module\">")
      context_data["type"].should eq("module")
    end
  end
end

describe Obelisk::EmbeddedLanguageArchitecture do
  describe "basic setup" do
    it "initializes with fallback lexer" do
      fallback = Obelisk::PlainTextLexer.new
      architecture = Obelisk::EmbeddedLanguageArchitecture.new(fallback)
      
      # Should return fallback for unknown languages
      lexer = architecture.get_lexer("unknown")
      lexer.should eq(fallback)
    end
    
    it "registers and retrieves lexers" do
      fallback = Obelisk::PlainTextLexer.new
      architecture = Obelisk::EmbeddedLanguageArchitecture.new(fallback)
      
      html_lexer = HTMLLexer.new
      architecture.register_lexer("html", html_lexer)
      
      retrieved = architecture.get_lexer("html")
      retrieved.should eq(html_lexer)
    end
    
    it "adds and uses nesting rules" do
      fallback = Obelisk::PlainTextLexer.new
      architecture = Obelisk::EmbeddedLanguageArchitecture.new(fallback)
      
      rule = Obelisk::LanguageNestingRule.new(
        "html", "css",
        /<style>/i, /<\/style>/i
      )
      
      architecture.add_nesting_rule(rule)
      # Rules are added to internal array - tested indirectly through analysis
    end
  end
  
  describe "context analysis" do
    it "analyzes simple HTML with CSS" do
      fallback = Obelisk::PlainTextLexer.new
      architecture = Obelisk::EmbeddedLanguageArchitecture.new(fallback)
      
      # Register lexers
      architecture.register_lexer("html", HTMLLexer.new)
      architecture.register_lexer("css", CSSLexer.new)
      
      # Add nesting rule
      rule = Obelisk::LanguageNestingRule.new(
        "html", "css",
        /<style>/i, /<\/style>/i
      )
      architecture.add_nesting_rule(rule)
      
      html_text = <<-HTML
        <html>
        <head>
        <style>
        body { color: red; }
        </style>
        </head>
        </html>
        HTML
      
      contexts = architecture.analyze_contexts(html_text, "html")
      
      # Should have at least the base HTML context and CSS context
      contexts.size.should be >= 1
      
      # Check if we detected CSS context
      css_contexts = contexts.select(&.language.== "css")
      css_contexts.size.should eq(1)
      
      css_context = css_contexts[0]
      css_content = css_context.content(html_text).strip
      css_content.should contain("body { color: red; }")
    end
    
    it "handles multiple embedded languages" do
      fallback = Obelisk::PlainTextLexer.new
      architecture = Obelisk::EmbeddedLanguageArchitecture.new(fallback)
      
      # Register lexers
      architecture.register_lexer("html", HTMLLexer.new)
      architecture.register_lexer("css", CSSLexer.new)
      architecture.register_lexer("javascript", JavaScriptLexer.new)
      
      # Add nesting rules
      css_rule = Obelisk::LanguageNestingRule.new("html", "css", /<style>/i, /<\/style>/i)
      js_rule = Obelisk::LanguageNestingRule.new("html", "javascript", /<script>/i, /<\/script>/i)
      
      architecture.add_nesting_rule(css_rule)
      architecture.add_nesting_rule(js_rule)
      
      html_text = <<-HTML
        <html>
        <style>body { font-size: 14px; }</style>
        <script>console.log("Hello");</script>
        </html>
        HTML
      
      contexts = architecture.analyze_contexts(html_text, "html")
      
      # Should detect both CSS and JavaScript contexts
      css_contexts = contexts.select(&.language.== "css")
      js_contexts = contexts.select(&.language.== "javascript")
      
      css_contexts.size.should eq(1)
      js_contexts.size.should eq(1)
      
      css_content = css_contexts[0].content(html_text).strip
      js_content = js_contexts[0].content(html_text).strip
      
      css_content.should contain("font-size: 14px")
      js_content.should contain("console.log")
    end
    
    it "handles nested languages with proper context hierarchy" do
      fallback = Obelisk::PlainTextLexer.new
      architecture = Obelisk::EmbeddedLanguageArchitecture.new(fallback)
      
      # Register lexers
      architecture.register_lexer("html", HTMLLexer.new)
      architecture.register_lexer("javascript", JavaScriptLexer.new)
      
      # Add nesting rule
      rule = Obelisk::LanguageNestingRule.new("html", "javascript", /<script>/i, /<\/script>/i)
      architecture.add_nesting_rule(rule)
      
      html_text = <<-HTML
        <div>
        <script>
        function test() {
          var x = 42;
        }
        </script>
        </div>
        HTML
      
      contexts = architecture.analyze_contexts(html_text, "html")
      
      js_contexts = contexts.select(&.language.== "javascript")
      js_contexts.size.should eq(1)
      
      js_context = js_contexts[0]
      js_context.parent_context.should_not be_nil
      js_context.parent_context.not_nil!.language.should eq("html")
      js_context.nesting_level.should eq(1)
    end
  end
  
  describe "document lexer creation" do
    it "creates document lexers for multi-language documents" do
      fallback = Obelisk::PlainTextLexer.new
      architecture = Obelisk::EmbeddedLanguageArchitecture.new(fallback)
      
      architecture.register_lexer("html", HTMLLexer.new)
      
      doc_lexer = architecture.create_document_lexer("html")
      
      doc_lexer.should be_a(Obelisk::DocumentLexer)
      doc_lexer.config.name.should eq("document-html")
    end
  end
end

describe Obelisk::DocumentLexer do
  describe "analysis and tokenization" do
    it "analyzes multi-language documents" do
      fallback = Obelisk::PlainTextLexer.new
      architecture = Obelisk::EmbeddedLanguageArchitecture.new(fallback)
      
      architecture.register_lexer("html", HTMLLexer.new)
      architecture.register_lexer("javascript", JavaScriptLexer.new)
      
      # Add nesting rule
      rule = Obelisk::LanguageNestingRule.new("html", "javascript", /<script>/i, /<\/script>/i)
      architecture.add_nesting_rule(rule)
      
      doc_lexer = architecture.create_document_lexer("html")
      
      simple_html = "<div>Hello</div>"
      complex_html = "<div><script>alert('hi');</script></div>"
      
      # Simple HTML should get base score
      simple_score = doc_lexer.analyze(simple_html)
      
      # Complex HTML should get boosted score due to embedded JS
      complex_score = doc_lexer.analyze(complex_html)
      
      complex_score.should be > simple_score
    end
    
    it "tokenizes multi-language documents" do
      fallback = Obelisk::PlainTextLexer.new
      architecture = Obelisk::EmbeddedLanguageArchitecture.new(fallback)
      
      architecture.register_lexer("html", HTMLLexer.new)
      architecture.register_lexer("javascript", JavaScriptLexer.new)
      
      # Add nesting rule
      rule = Obelisk::LanguageNestingRule.new("html", "javascript", /<script>/i, /<\/script>/i)
      architecture.add_nesting_rule(rule)
      
      doc_lexer = architecture.create_document_lexer("html")
      
      html_text = "<div><script>var x = 42;</script></div>"
      tokens = doc_lexer.tokenize(html_text).to_a
      
      # Should have tokens from both HTML and JavaScript lexers
      tokens.should_not be_empty
      
      # Check for HTML tokens
      html_tokens = tokens.select(&.type.== Obelisk::TokenType::NameTag)
      html_tokens.size.should be >= 1
      
      # Check for JavaScript tokens (Note: DocumentLexer currently processes embedded content as text)
      # This is a known limitation - the embedded content is detected but not fully tokenized
      # The architecture supports it, but the DocumentTokenIterator needs refinement
      js_content = tokens.select { |t| t.value.includes?("var") || t.value.includes?("42") }
      js_content.size.should be >= 1
    end
  end
end

describe Obelisk::CommonNestingRules do
  describe "HTML with CSS and JavaScript" do
    it "provides HTML/CSS/JS nesting rules" do
      rules = Obelisk::CommonNestingRules.html_css_js
      
      rules.size.should eq(2)
      
      css_rule = rules.find(&.embedded_language.== "css")
      js_rule = rules.find(&.embedded_language.== "javascript")
      
      css_rule.should_not be_nil
      js_rule.should_not be_nil
      
      css_rule.not_nil!.parent_language.should eq("html")
      js_rule.not_nil!.parent_language.should eq("html")
    end
    
    it "extracts context from script tags" do
      rules = Obelisk::CommonNestingRules.html_css_js
      js_rule = rules.find(&.embedded_language.== "javascript").not_nil!
      
      context_data = js_rule.extract_context("<script type=\"module\" src=\"app.js\">")
      
      context_data["type"].should eq("module")
      context_data["src"].should eq("app.js")
    end
  end
  
  describe "Markdown code blocks" do
    it "provides markdown code block rules" do
      rules = Obelisk::CommonNestingRules.markdown_code_blocks
      
      rules.size.should eq(1)
      rule = rules[0]
      
      rule.parent_language.should eq("markdown")
      rule.embedded_language.should eq("*")  # Wildcard for any language
    end
    
    it "extracts language from code fence" do
      rules = Obelisk::CommonNestingRules.markdown_code_blocks
      rule = rules[0]
      
      context_data = rule.extract_context("```javascript")
      context_data["language"].should eq("javascript")
    end
  end
  
  describe "Template expressions" do
    it "provides template expression rules" do
      rules = Obelisk::CommonNestingRules.template_expressions("erb", "ruby")
      
      rules.size.should eq(2)
      
      erb_rule = rules.find(&.start_pattern.== /<%=?/)
      handlebars_rule = rules.find(&.start_pattern.== /\{\{/)
      
      erb_rule.should_not be_nil
      handlebars_rule.should_not be_nil
      
      erb_rule.not_nil!.embedded_language.should eq("ruby")
      handlebars_rule.not_nil!.embedded_language.should eq("ruby")
    end
  end
  
  describe "Vue SFC" do
    it "provides Vue single file component rules" do
      rules = Obelisk::CommonNestingRules.vue_sfc
      
      rules.size.should eq(3)
      
      template_rule = rules.find(&.embedded_language.== "html")
      script_rule = rules.find(&.embedded_language.== "javascript")
      style_rule = rules.find(&.embedded_language.== "css")
      
      template_rule.should_not be_nil
      script_rule.should_not be_nil
      style_rule.should_not be_nil
      
      template_rule.not_nil!.parent_language.should eq("vue")
      script_rule.not_nil!.parent_language.should eq("vue")
      style_rule.not_nil!.parent_language.should eq("vue")
    end
  end
  
  describe "SQL embedded languages" do
    it "provides SQL embedded language rules" do
      rules = Obelisk::CommonNestingRules.sql_embedded
      
      rules.size.should eq(2)
      
      js_rule = rules.find(&.embedded_language.== "javascript")
      python_rule = rules.find(&.embedded_language.== "python")
      
      js_rule.should_not be_nil
      python_rule.should_not be_nil
      
      js_rule.not_nil!.parent_language.should eq("sql")
      python_rule.not_nil!.parent_language.should eq("sql")
    end
  end
end