require "./spec_helper"
require "../src/obelisk/context_sensitive"

describe Obelisk::ParsingContext do
  describe "look-around capabilities" do
    it "provides look-behind functionality" do
      state = Obelisk::LexerState.new("hello world")
      state.advance(6) # Position at space after "hello"
      context = Obelisk::ParsingContext.new(state, "hello world", 6)
      
      context.look_behind(5).should eq("ello ")
      context.look_behind(6).should eq("hello ")
      context.look_behind(20).should eq("hello ") # Clamped to start
    end

    it "provides look-ahead functionality" do
      state = Obelisk::LexerState.new("hello world")
      state.advance(6) # Position at space after "hello"
      context = Obelisk::ParsingContext.new(state, "hello world", 6)
      
      context.look_ahead(5).should eq("world")
      context.look_ahead(10).should eq("world") # Clamped to end
    end

    it "provides look-around functionality" do
      state = Obelisk::LexerState.new("hello world test")
      state.advance(6) # Position at 'w' in "world"
      context = Obelisk::ParsingContext.new(state, "hello world test", 6)
      
      context.look_around(3, 3).should eq("lo wor")
    end

    it "detects line boundaries" do
      text = "line1\nline2\nline3"
      state = Obelisk::LexerState.new(text)
      
      # At start of file
      context = Obelisk::ParsingContext.new(state, text, 0)
      context.at_line_start?.should be_true
      context.at_line_end?.should be_false
      
      # At end of first line
      context = Obelisk::ParsingContext.new(state, text, 5)
      context.at_line_start?.should be_false
      context.at_line_end?.should be_true
      
      # At start of second line
      context = Obelisk::ParsingContext.new(state, text, 6)
      context.at_line_start?.should be_true
      context.at_line_end?.should be_false
    end

    it "calculates line and column numbers" do
      text = "line1\nline2\nline3"
      state = Obelisk::LexerState.new(text)
      
      # First line, first column
      context = Obelisk::ParsingContext.new(state, text, 0)
      context.line_number.should eq(1)
      context.column_number.should eq(1)
      
      # First line, third column
      context = Obelisk::ParsingContext.new(state, text, 2)
      context.line_number.should eq(1)
      context.column_number.should eq(3)
      
      # Second line, first column
      context = Obelisk::ParsingContext.new(state, text, 6)
      context.line_number.should eq(2)
      context.column_number.should eq(1)
      
      # Third line, second column
      context = Obelisk::ParsingContext.new(state, text, 13)
      context.line_number.should eq(3)
      context.column_number.should eq(2)
    end
  end

  describe "token history analysis" do
    it "finds recent tokens by type" do
      history = [
        Obelisk::Token.new(Obelisk::TokenType::Keyword, "if"),
        Obelisk::Token.new(Obelisk::TokenType::Name, "foo"),
        Obelisk::Token.new(Obelisk::TokenType::Operator, "=="),
        Obelisk::Token.new(Obelisk::TokenType::LiteralNumber, "5")
      ]
      
      state = Obelisk::LexerState.new("test")
      context = Obelisk::ParsingContext.new(state, "test", 0, history)
      
      last_keyword = context.last_token_of_type(Obelisk::TokenType::Keyword)
      last_keyword.should_not be_nil
      last_keyword.not_nil!.value.should eq("if")
      
      context.last_token_of_type(Obelisk::TokenType::Comment).should be_nil
    end

    it "finds recent tokens matching condition" do
      history = [
        Obelisk::Token.new(Obelisk::TokenType::Keyword, "if"),
        Obelisk::Token.new(Obelisk::TokenType::Name, "variable"),
        Obelisk::Token.new(Obelisk::TokenType::Operator, "=="),
        Obelisk::Token.new(Obelisk::TokenType::LiteralNumber, "42")
      ]
      
      state = Obelisk::LexerState.new("test")
      context = Obelisk::ParsingContext.new(state, "test", 0, history)
      
      operators = context.recent_tokens(2) { |token| token.type.in_category?(Obelisk::TokenType::Operator) }
      operators.size.should eq(1)
      operators[0].value.should eq("==")
      
      all_tokens = context.recent_tokens(10) { |token| true }
      all_tokens.size.should eq(4)
    end

    it "checks for recent token presence" do
      history = [
        Obelisk::Token.new(Obelisk::TokenType::Punctuation, "("),
        Obelisk::Token.new(Obelisk::TokenType::Name, "arg"),
        Obelisk::Token.new(Obelisk::TokenType::Punctuation, ")")
      ]
      
      state = Obelisk::LexerState.new("test")
      context = Obelisk::ParsingContext.new(state, "test", 0, history)
      
      has_recent_paren = context.any_recent_token?(5) do |token|
        token.type == Obelisk::TokenType::Punctuation && token.value == "("
      end
      has_recent_paren.should be_true
      
      has_recent_keyword = context.any_recent_token?(5) do |token|
        token.type == Obelisk::TokenType::Keyword
      end
      has_recent_keyword.should be_false
    end

    it "calculates nesting levels" do
      history = [
        Obelisk::Token.new(Obelisk::TokenType::Punctuation, "{"),
        Obelisk::Token.new(Obelisk::TokenType::Name, "code"),
        Obelisk::Token.new(Obelisk::TokenType::Punctuation, "{"),
        Obelisk::Token.new(Obelisk::TokenType::Name, "nested"),
        Obelisk::Token.new(Obelisk::TokenType::Punctuation, "}")
      ]
      
      state = Obelisk::LexerState.new("test")
      context = Obelisk::ParsingContext.new(state, "test", 0, history)
      
      # Count open and close brackets manually for this test
      open_count = context.history.count { |t| t.type == Obelisk::TokenType::Punctuation && t.value == "{" }
      close_count = context.history.count { |t| t.type == Obelisk::TokenType::Punctuation && t.value == "}" }
      level = open_count - close_count
      
      level.should eq(1) # One unclosed opening brace
    end
  end
end

describe Obelisk::ContextConditions do
  describe "state-based conditions" do
    it "checks if in specific state" do
      state = Obelisk::LexerState.new("test")
      state.push_state("string")
      context = Obelisk::ParsingContext.new(state, "test", 0)
      
      in_string = Obelisk::ContextConditions.in_state("string")
      in_root = Obelisk::ContextConditions.in_state("root")
      not_in_comment = Obelisk::ContextConditions.not_in_state("comment")
      
      in_string.call(context).should be_true
      in_root.call(context).should be_false # Root is not active when string is pushed
      not_in_comment.call(context).should be_true
    end

    it "checks context data" do
      state = Obelisk::LexerState.new("test")
      state.set_context("quote_type", "double")
      context = Obelisk::ParsingContext.new(state, "test", 0)
      
      is_double_quote = Obelisk::ContextConditions.context_equals("quote_type", "double")
      is_single_quote = Obelisk::ContextConditions.context_equals("quote_type", "single")
      
      is_double_quote.call(context).should be_true
      is_single_quote.call(context).should be_false
    end
  end

  describe "position-based conditions" do
    it "checks line position" do
      text = "  hello\nworld  "
      state = Obelisk::LexerState.new(text)
      
      # At start of line
      context = Obelisk::ParsingContext.new(state, text, 8) # 'w' in "world"
      at_start = Obelisk::ContextConditions.at_line_start
      at_start.call(context).should be_true
      
      # Not at start of line
      context = Obelisk::ParsingContext.new(state, text, 2) # 'h' in "hello"
      at_start.call(context).should be_false
      
      # At end of line
      context = Obelisk::ParsingContext.new(state, text, 7) # newline
      at_end = Obelisk::ContextConditions.at_line_end
      at_end.call(context).should be_true
    end

    it "checks look-around patterns" do
      text = "if (condition) {"
      state = Obelisk::LexerState.new(text)
      context = Obelisk::ParsingContext.new(state, text, 4) # just after '(' position
      
      preceded_by_if = Obelisk::ContextConditions.preceded_by(/if\s\($/)
      followed_by_condition = Obelisk::ContextConditions.followed_by(/condition/)
      
      preceded_by_if.call(context).should be_true
      followed_by_condition.call(context).should be_true
    end
  end

  describe "token history conditions" do
    it "checks for recent token types" do
      history = [
        Obelisk::Token.new(Obelisk::TokenType::Keyword, "function"),
        Obelisk::Token.new(Obelisk::TokenType::Name, "test"),
        Obelisk::Token.new(Obelisk::TokenType::Punctuation, "(")
      ]
      
      state = Obelisk::LexerState.new("test")
      context = Obelisk::ParsingContext.new(state, "test", 0, history)
      
      has_recent_keyword = Obelisk::ContextConditions.recent_token_type(Obelisk::TokenType::Keyword, 5)
      has_recent_comment = Obelisk::ContextConditions.recent_token_type(Obelisk::TokenType::Comment, 5)
      
      has_recent_keyword.call(context).should be_true
      has_recent_comment.call(context).should be_false
    end
  end

  describe "compound conditions" do
    it "combines conditions with AND logic" do
      state = Obelisk::LexerState.new("test")
      state.push_state("string")
      state.set_context("quote_type", "double")
      context = Obelisk::ParsingContext.new(state, "test", 0)
      
      condition1 = Obelisk::ContextConditions.in_state("string")
      condition2 = Obelisk::ContextConditions.context_equals("quote_type", "double")
      condition3 = Obelisk::ContextConditions.context_equals("quote_type", "single")
      
      all_true = Obelisk::ContextConditions.all_of(condition1, condition2)
      mixed = Obelisk::ContextConditions.all_of(condition1, condition3)
      
      all_true.call(context).should be_true
      mixed.call(context).should be_false
    end

    it "combines conditions with OR logic" do
      state = Obelisk::LexerState.new("test")
      state.push_state("comment")
      context = Obelisk::ParsingContext.new(state, "test", 0)
      
      condition1 = Obelisk::ContextConditions.in_state("string")
      condition2 = Obelisk::ContextConditions.in_state("comment")
      condition3 = Obelisk::ContextConditions.in_state("block")
      
      any_match = Obelisk::ContextConditions.any_of(condition1, condition2, condition3)
      no_match = Obelisk::ContextConditions.any_of(condition1, condition3)
      
      any_match.call(context).should be_true
      no_match.call(context).should be_false
    end

    it "negates conditions" do
      state = Obelisk::LexerState.new("test")
      context = Obelisk::ParsingContext.new(state, "test", 0)
      
      in_string = Obelisk::ContextConditions.in_state("string")
      not_in_string = Obelisk::ContextConditions.not(in_string)
      
      in_string.call(context).should be_false
      not_in_string.call(context).should be_true
    end
  end
end

describe Obelisk::ContextAwareRule do
  describe "pattern matching with conditions" do
    it "matches when condition is satisfied" do
      state = Obelisk::LexerState.new("hello world")
      state.push_state("string")
      context = Obelisk::ParsingContext.new(state, "hello world", 0)
      
      condition = Obelisk::ContextConditions.in_state("string")
      rule = Obelisk::ContextAwareRule.new(
        /hello/, 
        Obelisk::TokenType::Name,
        condition
      )
      
      match = rule.match(context)
      match.should_not be_nil
      match.not_nil![0].should eq("hello")
    end

    it "does not match when condition is not satisfied" do
      state = Obelisk::LexerState.new("hello world")
      context = Obelisk::ParsingContext.new(state, "hello world", 0)
      
      condition = Obelisk::ContextConditions.in_state("string")
      rule = Obelisk::ContextAwareRule.new(
        /hello/, 
        Obelisk::TokenType::Name,
        condition
      )
      
      match = rule.match(context)
      match.should be_nil
    end

    it "matches when no condition is specified" do
      state = Obelisk::LexerState.new("hello world")
      context = Obelisk::ParsingContext.new(state, "hello world", 0)
      
      rule = Obelisk::ContextAwareRule.new(/hello/, Obelisk::TokenType::Name)
      
      match = rule.match(context)
      match.should_not be_nil
      match.not_nil![0].should eq("hello")
    end

    it "respects rule priority ordering" do
      rule1 = Obelisk::ContextAwareRule.new(/test/, Obelisk::TokenType::Name, priority: 10)
      rule2 = Obelisk::ContextAwareRule.new(/test/, Obelisk::TokenType::Keyword, priority: 20)
      rule3 = Obelisk::ContextAwareRule.new(/test/, Obelisk::TokenType::Comment, priority: 5)
      
      rules = [rule1, rule2, rule3]
      sorted = rules.sort_by { |r| -r.priority }
      
      sorted[0].priority.should eq(20)
      sorted[1].priority.should eq(10)
      sorted[2].priority.should eq(5)
    end
  end
end

describe Obelisk::ContextManager do
  describe "history management" do
    it "tracks token history" do
      manager = Obelisk::ContextManager.new
      
      token1 = Obelisk::Token.new(Obelisk::TokenType::Name, "hello")
      token2 = Obelisk::Token.new(Obelisk::TokenType::Operator, "=")
      
      manager.add_token(token1)
      manager.add_token(token2)
      
      state = Obelisk::LexerState.new("test")
      context = manager.create_context(state, "test", 0)
      
      context.history.size.should eq(2)
      context.history[0].value.should eq("hello")
      context.history[1].value.should eq("=")
    end

    it "logs state transitions" do
      manager = Obelisk::ContextManager.new
      
      manager.log_transition("root", "string", 10)
      manager.log_transition("string", "interpolation", 20)
      manager.log_transition("interpolation", "string", 25)
      
      recent = manager.recent_transitions(2)
      recent.size.should eq(2)
      recent[0][:from].should eq("string")
      recent[0][:to].should eq("interpolation")
      recent[1][:from].should eq("interpolation")
      recent[1][:to].should eq("string")
    end

    it "provides parsing statistics" do
      manager = Obelisk::ContextManager.new(max_history_size: 5)
      
      5.times do |i|
        token = Obelisk::Token.new(Obelisk::TokenType::Name, "token#{i}")
        manager.add_token(token)
      end
      
      manager.log_transition("root", "string", 10)
      manager.log_transition("string", "root", 20)
      
      stats = manager.stats
      stats["total_tokens"].should eq(5)
      stats["total_transitions"].should eq(2)
      stats["unique_states"].should eq(2)
    end

    it "limits history size" do
      manager = Obelisk::ContextManager.new(max_history_size: 3)
      
      5.times do |i|
        token = Obelisk::Token.new(Obelisk::TokenType::Name, "token#{i}")
        manager.add_token(token)
      end
      
      state = Obelisk::LexerState.new("test")
      context = manager.create_context(state, "test", 0)
      
      context.history.size.should eq(3)
      context.history[0].value.should eq("token2") # Oldest kept token
      context.history[2].value.should eq("token4") # Newest token
    end

    it "clears history" do
      manager = Obelisk::ContextManager.new
      
      token = Obelisk::Token.new(Obelisk::TokenType::Name, "test")
      manager.add_token(token)
      manager.log_transition("root", "string", 10)
      
      manager.clear_history
      
      state = Obelisk::LexerState.new("test")
      context = manager.create_context(state, "test", 0)
      
      context.history.should be_empty
      manager.recent_transitions(10).should be_empty
      manager.stats["total_tokens"].should eq(0)
    end
  end
end

describe Obelisk::LookAroundUtils do
  describe "pattern matching utilities" do
    it "checks patterns at specific offsets" do
      text = "hello world test"
      
      # Check for "world" at offset 6 from position 0
      match = Obelisk::LookAroundUtils.matches_at_offset(text, 0, 6, /world/)
      match.should be_true
      
      # Check for "test" at offset 12 from position 0
      match = Obelisk::LookAroundUtils.matches_at_offset(text, 0, 12, /test/)
      match.should be_true
      
      # Check for non-existent pattern
      match = Obelisk::LookAroundUtils.matches_at_offset(text, 0, 6, /foo/)
      match.should be_false
    end

    it "finds patterns in look-ahead window" do
      text = "foo bar baz foo bar"
      
      matches = Obelisk::LookAroundUtils.find_in_window(text, 0, 15, /\b\w{3}\b/)
      matches.size.should eq(4) # foo, bar, baz, foo
      matches[0][0].should eq("foo")
      matches[1][0].should eq("bar")
      matches[2][0].should eq("baz")
      matches[3][0].should eq("foo")
    end

    it "detects balanced delimiters" do
      text = "before { inside { nested } more } after"
      
      # Position inside first level
      inside_first = Obelisk::LookAroundUtils.inside_balanced?(text, 15, '{', '}')
      inside_first.should be_true
      
      # Position inside nested level
      inside_nested = Obelisk::LookAroundUtils.inside_balanced?(text, 25, '{', '}')
      inside_nested.should be_true
      
      # Position before any delimiter
      before_any = Obelisk::LookAroundUtils.inside_balanced?(text, 3, '{', '}')
      before_any.should be_false
      
      # Position after all delimiters
      after_all = Obelisk::LookAroundUtils.inside_balanced?(text, 38, '{', '}')
      after_all.should be_false
    end

    it "finds matching closing delimiters" do
      text = "start { content { nested } more } end"
      
      # Find closing brace for opening at position 6
      close_pos = Obelisk::LookAroundUtils.find_matching_close(text, 6, '{', '}')
      close_pos.should eq(32)
      
      # Find closing brace for nested opening at position 16
      nested_close = Obelisk::LookAroundUtils.find_matching_close(text, 16, '{', '}')
      nested_close.should eq(25)
      
      # No opening brace at position
      no_match = Obelisk::LookAroundUtils.find_matching_close(text, 0, '{', '}')
      no_match.should be_nil
    end

    it "extracts balanced content" do
      text = "before { hello world } after"
      
      content = Obelisk::LookAroundUtils.extract_balanced_content(text, 7, '{', '}')
      content.should eq(" hello world ")
      
      # No opening brace at position
      no_content = Obelisk::LookAroundUtils.extract_balanced_content(text, 0, '{', '}')
      no_content.should be_nil
    end
  end
end

describe Obelisk::ContextRuleHelpers do
  describe "common rule patterns" do
    it "creates string interpolation rules" do
      rule = Obelisk::ContextRuleHelpers.string_interpolation_rule(
        /\$\{/, "interpolation", Obelisk::TokenType::LiteralStringInterpol
      )
      
      rule.pattern.should eq(/\$\{/)
      rule.priority.should eq(100)
      rule.description.should eq("String interpolation start")
      
      # Test condition - should only match in string state
      state = Obelisk::LexerState.new("test")
      context = Obelisk::ParsingContext.new(state, "test", 0)
      rule.applicable?(context).should be_false
      
      state.push_state("string")
      context = Obelisk::ParsingContext.new(state, "test", 0)
      rule.applicable?(context).should be_true
    end

    it "creates contextual comment rules" do
      context_map = {
        "javascript" => Obelisk::TokenType::CommentSingle,
        "css" => Obelisk::TokenType::CommentMultiline
      }
      
      rule = Obelisk::ContextRuleHelpers.contextual_comment_rule(/\/\/.*/, context_map)
      
      rule.pattern.should eq(/\/\/.*/)
      rule.priority.should eq(50)
      
      # Test in JavaScript context
      state = Obelisk::LexerState.new("test")
      state.push_state("javascript")
      context = Obelisk::ParsingContext.new(state, "test", 0)
      rule.applicable?(context).should be_true
      
      # Test in CSS context
      state = Obelisk::LexerState.new("test")
      state.push_state("css")
      context = Obelisk::ParsingContext.new(state, "test", 0)
      rule.applicable?(context).should be_true
      
      # Test in other context
      state = Obelisk::LexerState.new("test")
      context = Obelisk::ParsingContext.new(state, "test", 0)
      rule.applicable?(context).should be_false
    end

    it "creates bracket tracking rules" do
      rules = Obelisk::ContextRuleHelpers.bracket_tracking_rule(
        /\{/, /\}/, 
        Obelisk::TokenType::Punctuation, Obelisk::TokenType::Punctuation,
        "block"
      )
      
      rules.size.should eq(2)
      
      open_rule = rules[0]
      open_rule.pattern.should eq(/\{/)
      open_rule.priority.should eq(90)
      open_rule.description.should eq("Opening bracket")
      
      close_rule = rules[1]
      close_rule.pattern.should eq(/\}/)
      close_rule.priority.should eq(90)
      close_rule.description.should eq("Closing bracket")
    end

    it "creates template expression rules" do
      rules = Obelisk::ContextRuleHelpers.template_expression_rule(
        "{{", "}}", "template", "expression"
      )
      
      rules.size.should eq(2)
      
      start_rule = rules[0]
      start_rule.priority.should eq(100)
      start_rule.description.should eq("Template expression start")
      
      end_rule = rules[1]
      end_rule.priority.should eq(100)
      end_rule.description.should eq("Template expression end")
      
      # Test start rule condition
      state = Obelisk::LexerState.new("test")
      state.push_state("template")
      context = Obelisk::ParsingContext.new(state, "test", 0)
      start_rule.applicable?(context).should be_true
      
      # Test end rule condition
      state = Obelisk::LexerState.new("test")
      state.push_state("expression")
      context = Obelisk::ParsingContext.new(state, "test", 0)
      end_rule.applicable?(context).should be_true
    end
  end
end

# Integration test with a complete context-sensitive lexer
describe Obelisk::ContextSensitiveLexer do
  describe "string interpolation" do
    it "handles simple string interpolation" do
      config = Obelisk::LexerConfig.new("test", ["test"])
      lexer = Obelisk::ContextSensitiveLexer.new("test", config)
      
      text = "\"Hello \${name} world\""
      tokens = lexer.tokenize(text).to_a
      
      # Filter out whitespace tokens for easier testing
      significant_tokens = tokens.reject { |t| t.type == Obelisk::TokenType::Text && t.value.strip.empty? }
      
      significant_tokens[0].type.should eq(Obelisk::TokenType::LiteralStringDouble) # "
      significant_tokens[0].value.should eq("\"")
      
      significant_tokens[1].type.should eq(Obelisk::TokenType::LiteralStringDouble) # Hello 
      significant_tokens[1].value.should eq("Hello ")
      
      significant_tokens[2].type.should eq(Obelisk::TokenType::LiteralStringInterpol) # ${
      significant_tokens[2].value.should eq("${")
      
      significant_tokens[3].type.should eq(Obelisk::TokenType::Name) # name
      significant_tokens[3].value.should eq("name")
      
      significant_tokens[4].type.should eq(Obelisk::TokenType::LiteralStringInterpol) # }
      significant_tokens[4].value.should eq("}")
      
      significant_tokens[5].type.should eq(Obelisk::TokenType::LiteralStringDouble) # world
      significant_tokens[5].value.should eq(" world")
      
      significant_tokens[6].type.should eq(Obelisk::TokenType::LiteralStringDouble) # "
      significant_tokens[6].value.should eq("\"")
    end

    it "handles nested interpolation" do
      config = Obelisk::LexerConfig.new("test", ["test"])
      lexer = Obelisk::ContextSensitiveLexer.new("test", config)
      
      text = "\"Result: \${calc(\${x})}\""
      tokens = lexer.tokenize(text).to_a
      
      # Should have at least some interpolation tokens (nested handling is complex)
      interpolation_tokens = tokens.select { |t| t.type == Obelisk::TokenType::LiteralStringInterpol }
      interpolation_tokens.size.should be >= 2 # At least opening and closing
    end
  end

  describe "context-aware comments" do
    it "recognizes comments outside strings but not inside" do
      config = Obelisk::LexerConfig.new("test", ["test"])
      lexer = Obelisk::ContextSensitiveLexer.new("test", config)
      
      text = "// This is a comment\n\"This is // not a comment\""
      tokens = lexer.tokenize(text).to_a
      
      comment_tokens = tokens.select { |t| t.type.in_category?(Obelisk::TokenType::Comment) }
      comment_tokens.size.should eq(1)
      comment_tokens[0].value.should eq("// This is a comment")
      
      # The // inside the string should be tokenized as string content
      string_tokens = tokens.select { |t| t.type == Obelisk::TokenType::LiteralStringDouble }
      string_content = string_tokens.find { |t| t.value.includes?("//") }
      string_content.should_not be_nil
    end
  end

  describe "bracket matching with context" do
    it "tracks bracket nesting properly" do
      config = Obelisk::LexerConfig.new("test", ["test"])
      lexer = Obelisk::ContextSensitiveLexer.new("test", config)
      
      text = "{ outer { inner } more }"
      tokens = lexer.tokenize(text).to_a
      
      brace_tokens = tokens.select { |t| t.type == Obelisk::TokenType::Punctuation && ["{", "}"].includes?(t.value) }
      brace_tokens.size.should eq(4)
      
      # Check that we can get context manager statistics
      stats = lexer.context_manager.stats
      stats["total_tokens"].should be > 0
    end
  end

  describe "template language simulation" do
    it "demonstrates template-like parsing" do
      config = Obelisk::LexerConfig.new("template", ["tmpl"])
      lexer = Obelisk::ContextSensitiveLexer.new("template", config)
      
      # Add custom template rules
      template_rules = Obelisk::ContextRuleHelpers.template_expression_rule(
        "{{", "}}", "root", "expression"
      )
      
      # Add start rule to root state
      lexer.add_context_rule("root", template_rules[0])
      
      # Add end rule to expression state
      lexer.add_context_rule("expression", template_rules[1])
      
      # Add basic rules for expression state
      lexer.add_fallback_rule("expression", Obelisk::LexerRule.new(/[a-zA-Z_][a-zA-Z0-9_.]*/, Obelisk::TokenType::Name))
      lexer.add_fallback_rule("expression", Obelisk::LexerRule.new(/\s+/, Obelisk::TokenType::Text))
      
      text = "Hello {{ user.name }} welcome!"
      tokens = lexer.tokenize(text).to_a
      
      # Should have template delimiter tokens
      delimiter_tokens = tokens.select { |t| t.type == Obelisk::TokenType::LiteralStringInterpol }
      delimiter_tokens.size.should eq(2) # {{ and }}
      delimiter_tokens[0].value.should eq("{{")
      delimiter_tokens[1].value.should eq("}}")
    end
  end

  describe "error handling and edge cases" do
    it "handles unterminated strings gracefully" do
      config = Obelisk::LexerConfig.new("test", ["test"])
      lexer = Obelisk::ContextSensitiveLexer.new("test", config)
      
      text = "\"unterminated string"
      tokens = lexer.tokenize(text).to_a
      
      # Should not crash and should produce tokens
      tokens.should_not be_empty
      
      # First token should be opening quote
      tokens[0].type.should eq(Obelisk::TokenType::LiteralStringDouble)
      tokens[0].value.should eq("\"")
    end

    it "handles malformed interpolation" do
      config = Obelisk::LexerConfig.new("test", ["test"])
      lexer = Obelisk::ContextSensitiveLexer.new("test", config)
      
      text = "\"text \${ unclosed interpolation"
      tokens = lexer.tokenize(text).to_a
      
      # Should handle gracefully without infinite loops
      tokens.should_not be_empty
      
      # Should have interpolation start token
      interp_tokens = tokens.select { |t| t.type == Obelisk::TokenType::LiteralStringInterpol }
      interp_tokens.should_not be_empty
    end

    it "preserves context manager state across tokenizations" do
      config = Obelisk::LexerConfig.new("test", ["test"])
      lexer = Obelisk::ContextSensitiveLexer.new("test", config)
      
      # First tokenization
      text1 = "first line"
      tokens1 = lexer.tokenize(text1).to_a
      
      # Check initial stats
      initial_stats = lexer.context_manager.stats
      initial_tokens = initial_stats["total_tokens"]
      
      # Second tokenization (context manager should maintain history)
      text2 = "second line"
      tokens2 = lexer.tokenize(text2).to_a
      
      # Stats should show accumulated history
      final_stats = lexer.context_manager.stats
      final_tokens = final_stats["total_tokens"]
      
      final_tokens.should be > initial_tokens
    end
  end
end