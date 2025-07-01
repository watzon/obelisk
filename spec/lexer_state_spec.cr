require "./spec_helper"

describe Obelisk::LexerState do
  describe "basic state operations" do
    it "initializes with root state" do
      state = Obelisk::LexerState.new("test")
      state.current_state.should eq("root")
      state.stack.should eq(["root"])
    end

    it "supports push and pop operations" do
      state = Obelisk::LexerState.new("test")

      state.push_state("string")
      state.current_state.should eq("string")
      state.stack.should eq(["root", "string"])

      popped = state.pop_state
      popped.should eq("string")
      state.current_state.should eq("root")
    end

    it "cannot pop root state" do
      state = Obelisk::LexerState.new("test")
      popped = state.pop_state
      popped.should be_nil
      state.current_state.should eq("root")
    end
  end

  describe "include state operations" do
    it "supports include state operations" do
      state = Obelisk::LexerState.new("test")

      state.include_state("interpolation")
      state.current_include_state.should eq("interpolation")
      state.in_include_state?.should be_true

      exited = state.exit_include
      exited.should eq("interpolation")
      state.current_include_state.should be_nil
      state.in_include_state?.should be_false
    end

    it "supports nested include states" do
      state = Obelisk::LexerState.new("test")

      state.include_state("first")
      state.include_state("second")

      state.current_include_state.should eq("second")

      state.exit_include.should eq("second")
      state.current_include_state.should eq("first")

      state.exit_include.should eq("first")
      state.current_include_state.should be_nil
    end
  end

  describe "combined state operations" do
    it "supports adding and removing combined states" do
      state = Obelisk::LexerState.new("test")

      state.add_combined_state("tag")
      state.add_combined_state("attribute")

      state.has_combined_state?("tag").should be_true
      state.has_combined_state?("attribute").should be_true
      state.combined_states.size.should eq(2)

      state.remove_combined_state("tag")
      state.has_combined_state?("tag").should be_false
      state.has_combined_state?("attribute").should be_true

      state.clear_combined_states
      state.combined_states.size.should eq(0)
    end
  end

  describe "active states" do
    it "returns all active states in priority order" do
      state = Obelisk::LexerState.new("test")
      state.push_state("string")
      state.add_combined_state("interpolation")
      state.include_state("expression")

      active = state.active_states
      active.should contain("string")        # main state
      active.should contain("expression")    # include state
      active.should contain("interpolation") # combined state

      # Include state should be present
      state.in_state?("expression").should be_true
      state.in_state?("string").should be_true
      state.in_state?("interpolation").should be_true
      state.in_state?("nonexistent").should be_false
    end
  end

  describe "context management" do
    it "supports setting and getting context" do
      state = Obelisk::LexerState.new("test")

      state.set_context("quote_type", "double")
      state.get_context("quote_type").should eq("double")
      state.get_context("nonexistent").should be_nil

      state.set_context("delimiter", "}")
      state.get_context("delimiter").should eq("}")

      state.clear_context
      state.get_context("quote_type").should be_nil
      state.get_context("delimiter").should be_nil
    end
  end

  describe "cloning" do
    it "creates a deep copy with all state" do
      state = Obelisk::LexerState.new("test", 10)
      state.push_state("string")
      state.add_combined_state("interpolation")
      state.include_state("expression")
      state.set_context("key", "value")

      cloned = state.clone

      # Position and text should match
      cloned.pos.should eq(10)
      cloned.text.should eq("test")

      # State stacks should be independent copies
      cloned.stack.should eq(state.stack)
      cloned.stack.should_not be(state.stack)

      cloned.combined_states.should eq(state.combined_states)
      cloned.combined_states.should_not be(state.combined_states)

      cloned.include_stack.should eq(state.include_stack)
      cloned.include_stack.should_not be(state.include_stack)

      cloned.context.should eq(state.context)
      cloned.context.should_not be(state.context)

      # Modifications to clone shouldn't affect original
      cloned.push_state("new")
      state.current_state.should eq("string")
      cloned.current_state.should eq("new")
    end
  end
end

describe Obelisk::RuleActions do
  describe "advanced state mutations" do
    it "supports include actions" do
      state = Obelisk::LexerState.new("test")
      action = Obelisk::RuleActions.include("interpolation", Obelisk::TokenType::Punctuation)

      tokens = action.call("${", state, [] of String)

      tokens.size.should eq(1)
      tokens[0].type.should eq(Obelisk::TokenType::Punctuation)
      tokens[0].value.should eq("${")
      state.current_include_state.should eq("interpolation")
    end

    it "supports exit_include actions" do
      state = Obelisk::LexerState.new("test")
      state.include_state("interpolation")

      action = Obelisk::RuleActions.exit_include(Obelisk::TokenType::Punctuation)
      tokens = action.call("}", state, [] of String)

      tokens.size.should eq(1)
      tokens[0].type.should eq(Obelisk::TokenType::Punctuation)
      state.current_include_state.should be_nil
    end

    it "supports combine actions" do
      state = Obelisk::LexerState.new("test")
      action = Obelisk::RuleActions.combine("tag")

      tokens = action.call("<", state, [] of String)

      tokens.size.should eq(0)
      state.has_combined_state?("tag").should be_true
    end

    it "supports context actions" do
      state = Obelisk::LexerState.new("test")
      action = Obelisk::RuleActions.set_context("quote", "single")

      tokens = action.call("'", state, [] of String)

      tokens.size.should eq(0)
      state.get_context("quote").should eq("single")
    end

    it "supports conditional actions" do
      state = Obelisk::LexerState.new("test")
      state.set_context("mode", "strict")

      condition = ->(s : Obelisk::LexerState) { s.get_context("mode") == "strict" }
      action = Obelisk::RuleActions.conditional(
        condition,
        Obelisk::TokenType::Keyword,
        Obelisk::TokenType::Name
      )

      tokens = action.call("var", state, [] of String)

      tokens.size.should eq(1)
      tokens[0].type.should eq(Obelisk::TokenType::Keyword)
    end
  end
end
