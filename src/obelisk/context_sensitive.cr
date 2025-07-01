require "./lexer"

module Obelisk
  # Represents the parsing context with look-ahead and look-behind capabilities
  struct ParsingContext
    getter state : LexerState
    getter text : String
    getter position : Int32
    getter history : Array(Token)
    getter look_ahead_cache : Hash(Int32, String?)

    def initialize(@state : LexerState, @text : String, @position : Int32,
                   @history = [] of Token, @look_ahead_cache = {} of Int32 => String?)
    end

    # Get text before current position (look-behind)
    def look_behind(count : Int32) : String
      start_pos = Math.max(0, @position - count)
      @text[start_pos...@position]
    end

    # Get text after current position (look-ahead)
    def look_ahead(count : Int32) : String
      end_pos = Math.min(@text.size, @position + count)
      @text[@position...end_pos]
    end

    # Get text around current position
    def look_around(before : Int32, after : Int32) : String
      start_pos = Math.max(0, @position - before)
      end_pos = Math.min(@text.size, @position + after)
      @text[start_pos...end_pos]
    end

    # Check if we're at the beginning of a line
    def at_line_start? : Bool
      @position == 0 || @text[@position - 1] == '\n'
    end

    # Check if we're at the end of a line
    def at_line_end? : Bool
      @position >= @text.size || @text[@position] == '\n'
    end

    # Get current line number (1-based)
    def line_number : Int32
      @text[0...@position].count('\n') + 1
    end

    # Get current column number (1-based)
    def column_number : Int32
      return @position + 1 if @position == 0

      last_newline = @text.rindex('\n', @position - 1)
      if last_newline
        @position - last_newline
      else
        @position + 1
      end
    end

    # Get the most recent token of a specific type from history
    def last_token_of_type(type : TokenType) : Token?
      @history.reverse_each { |token| return token if token.type == type }
      nil
    end

    # Get recent tokens matching a condition
    def recent_tokens(count : Int32, &block : Token -> Bool) : Array(Token)
      result = [] of Token
      @history.reverse_each do |token|
        result << token if yield(token)
        break if result.size >= count
      end
      result.reverse
    end

    # Check if any recent token matches a condition
    def any_recent_token?(max_lookback : Int32, &block : Token -> Bool) : Bool
      checked = 0
      @history.reverse_each do |token|
        return true if yield(token)
        checked += 1
        break if checked >= max_lookback
      end
      false
    end

    # Get nesting level of specific token types (like brackets)
    def nesting_level(open_types : Array(TokenType), close_types : Array(TokenType)) : Int32
      level = 0
      @history.each do |token|
        level += 1 if open_types.includes?(token.type)
        level -= 1 if close_types.includes?(token.type)
      end
      Math.max(0, level)
    end

    # Clone context with updated position
    def advance(new_position : Int32, new_token : Token? = nil) : ParsingContext
      new_history = @history.dup
      new_history << new_token if new_token
      ParsingContext.new(@state, @text, new_position, new_history, @look_ahead_cache)
    end
  end

  # Context-aware rule that can make decisions based on parsing context
  class ContextAwareRule
    getter pattern : Regex
    getter condition : Proc(ParsingContext, Bool)?
    getter action : RuleAction
    getter priority : Int32
    getter description : String

    def initialize(@pattern : Regex, @action : RuleAction,
                   @condition : Proc(ParsingContext, Bool)? = nil,
                   @priority = 0, @description = "")
    end

    # Check if this rule matches at the current context
    def match(context : ParsingContext) : Regex::MatchData?
      remaining = context.state.remaining
      return nil unless match_data = @pattern.match(remaining, 0)
      return nil unless match_data.begin(0) == 0

      # Check context condition if present
      if condition = @condition
        return nil unless condition.call(context)
      end

      match_data
    end

    # Check if the rule is applicable in the current context
    def applicable?(context : ParsingContext) : Bool
      return true unless condition = @condition
      condition.call(context)
    end
  end

  # Utilities for creating common context conditions
  module ContextConditions
    # Create condition that checks if we're in a specific state
    def self.in_state(state_name : String) : Proc(ParsingContext, Bool)
      ->(context : ParsingContext) { context.state.in_state?(state_name) }
    end

    # Create condition that checks context data
    def self.context_equals(key : String, value : String) : Proc(ParsingContext, Bool)
      ->(context : ParsingContext) { context.state.get_context(key) == value }
    end

    # Create condition that checks look-behind text
    def self.preceded_by(pattern : Regex) : Proc(ParsingContext, Bool)
      ->(context : ParsingContext) {
        look_behind = context.look_behind(50)
        if match = pattern.match(look_behind)
          match.end(0) == look_behind.size
        else
          false
        end
      }
    end

    # Create condition that checks look-ahead text
    def self.followed_by(pattern : Regex) : Proc(ParsingContext, Bool)
      ->(context : ParsingContext) {
        look_ahead = context.look_ahead(50)
        if match = pattern.match(look_ahead)
          match.begin(0) == 0
        else
          false
        end
      }
    end

    # Create condition that checks if we're at line start
    def self.at_line_start : Proc(ParsingContext, Bool)
      ->(context : ParsingContext) { context.at_line_start? }
    end

    # Create condition that checks if we're at line end
    def self.at_line_end : Proc(ParsingContext, Bool)
      ->(context : ParsingContext) { context.at_line_end? }
    end

    # Create condition that checks recent token history
    def self.recent_token_type(type : TokenType, max_lookback = 5) : Proc(ParsingContext, Bool)
      ->(context : ParsingContext) {
        context.any_recent_token?(max_lookback) { |token| token.type == type }
      }
    end

    # Create condition that checks nesting level
    def self.nesting_level_equals(level : Int32, open_types : Array(TokenType), close_types : Array(TokenType)) : Proc(ParsingContext, Bool)
      ->(context : ParsingContext) {
        context.nesting_level(open_types, close_types) == level
      }
    end

    # Create condition that checks if NOT in a specific state
    def self.not_in_state(state_name : String) : Proc(ParsingContext, Bool)
      ->(context : ParsingContext) { !context.state.in_state?(state_name) }
    end

    # Combine multiple conditions with AND logic
    def self.all_of(*conditions : Proc(ParsingContext, Bool)) : Proc(ParsingContext, Bool)
      ->(context : ParsingContext) {
        conditions.all? { |condition| condition.call(context) }
      }
    end

    # Combine multiple conditions with OR logic
    def self.any_of(*conditions : Proc(ParsingContext, Bool)) : Proc(ParsingContext, Bool)
      ->(context : ParsingContext) {
        conditions.any? { |condition| condition.call(context) }
      }
    end

    # Negate a condition
    def self.not(condition : Proc(ParsingContext, Bool)) : Proc(ParsingContext, Bool)
      ->(context : ParsingContext) { !condition.call(context) }
    end
  end

  # Context manager for tracking parsing context and state transitions
  class ContextManager
    @history : Array(Token)
    @state_transition_log : Array({from: String, to: String, position: Int32})
    @max_history_size : Int32

    def initialize(@max_history_size = 1000)
      @history = [] of Token
      @state_transition_log = [] of {from: String, to: String, position: Int32}
    end

    # Add a token to the history
    def add_token(token : Token) : Nil
      @history << token

      # Trim history if it gets too large
      if @history.size > @max_history_size
        @history.shift(@history.size - @max_history_size)
      end
    end

    # Log a state transition
    def log_transition(from : String, to : String, position : Int32) : Nil
      @state_transition_log << {from: from, to: to, position: position}

      # Keep transition log reasonable size
      if @state_transition_log.size > @max_history_size
        @state_transition_log.shift(@state_transition_log.size - @max_history_size)
      end
    end

    # Create parsing context for current state
    def create_context(state : LexerState, text : String, position : Int32) : ParsingContext
      ParsingContext.new(state, text, position, @history.dup)
    end

    # Get recent state transitions
    def recent_transitions(count : Int32) : Array({from: String, to: String, position: Int32})
      start_index = Math.max(0, @state_transition_log.size - count)
      @state_transition_log[start_index..]
    end

    # Clear history (useful for document boundaries)
    def clear_history : Nil
      @history.clear
      @state_transition_log.clear
    end

    # Get statistics about the parsing session
    def stats : Hash(String, Int32)
      {
        "total_tokens"      => @history.size,
        "total_transitions" => @state_transition_log.size,
        "unique_states"     => @state_transition_log.map(&.[:to]).uniq.size,
      }
    end
  end

  # Look-ahead and look-behind utilities
  module LookAroundUtils
    # Check if pattern matches at specific offset from current position
    def self.matches_at_offset(text : String, position : Int32, offset : Int32, pattern : Regex) : Bool
      target_pos = position + offset
      return false if target_pos < 0 || target_pos >= text.size

      if match = pattern.match(text, target_pos)
        match.begin(0) == target_pos
      else
        false
      end
    end

    # Find all occurrences of pattern in look-ahead window
    def self.find_in_window(text : String, position : Int32, window_size : Int32, pattern : Regex) : Array(Regex::MatchData)
      end_pos = Math.min(text.size, position + window_size)
      window = text[position...end_pos]

      matches = [] of Regex::MatchData
      pos = 0
      while pos < window.size
        if match = pattern.match(window, pos)
          matches << match
          pos = match.end(0)
        else
          break
        end
      end
      matches
    end

    # Check if we're inside balanced delimiters
    def self.inside_balanced?(text : String, position : Int32, open_char : Char, close_char : Char) : Bool
      balance = 0
      (0...position).each do |i|
        char = text[i]
        balance += 1 if char == open_char
        balance -= 1 if char == close_char
      end
      balance > 0
    end

    # Find the matching closing delimiter
    def self.find_matching_close(text : String, position : Int32, open_char : Char, close_char : Char) : Int32?
      return nil unless text[position] == open_char

      balance = 1
      pos = position + 1

      while pos < text.size && balance > 0
        char = text[pos]
        balance += 1 if char == open_char
        balance -= 1 if char == close_char
        return pos if balance == 0
        pos += 1
      end

      nil
    end

    # Get the content between balanced delimiters
    def self.extract_balanced_content(text : String, position : Int32, open_char : Char, close_char : Char) : String?
      close_pos = find_matching_close(text, position, open_char, close_char)
      return nil unless close_pos

      text[(position + 1)...close_pos]
    end
  end

  # Conditional lexer that switches behavior based on context
  abstract class ConditionalLexer < RegexLexer
    @base_rules : Hash(String, Array(ContextAwareRule))
    @context_manager : ContextManager
    @fall_through_rules : Hash(String, Array(LexerRule))

    def initialize(@context_manager = ContextManager.new)
      @base_rules = {} of String => Array(ContextAwareRule)
      @fall_through_rules = {} of String => Array(LexerRule)
    end

    abstract def config : LexerConfig

    # Add context-aware rule to a state
    def add_context_rule(state : String, rule : ContextAwareRule) : Nil
      @base_rules[state] ||= [] of ContextAwareRule
      @base_rules[state] << rule
      # Sort by priority (higher priority first)
      @base_rules[state].sort_by! { |r| -r.priority }
    end

    # Add traditional rule as fallback
    def add_fallback_rule(state : String, rule : LexerRule) : Nil
      @fall_through_rules[state] ||= [] of LexerRule
      @fall_through_rules[state] << rule
    end

    # Get rules (implements abstract method from RegexLexer)
    def rules : Hash(String, Array(LexerRule))
      # Convert context-aware rules to regular rules for compatibility
      result = {} of String => Array(LexerRule)

      @base_rules.each do |state, context_rules|
        result[state] = context_rules.map do |context_rule|
          LexerRule.new(context_rule.pattern, context_rule.action)
        end
      end

      # Add fallback rules
      @fall_through_rules.each do |state, fallback_rules|
        result[state] ||= [] of LexerRule
        result[state].concat(fallback_rules)
      end

      result
    end

    # Enhanced tokenizer with context awareness
    def tokenize(text : String) : TokenIterator
      ConditionalTokenIterator.new(self, text, @context_manager)
    end

    # Find matching rule considering context
    def find_context_match(context : ParsingContext) : {ContextAwareRule, Regex::MatchData}?
      state_name = context.state.current_state
      context_rules = @base_rules[state_name]? || [] of ContextAwareRule

      # Try context-aware rules first (already sorted by priority)
      context_rules.each do |rule|
        if match = rule.match(context)
          return {rule, match}
        end
      end

      nil
    end

    # Get context manager for external access
    def context_manager : ContextManager
      @context_manager
    end
  end

  # Token iterator for conditional lexer with context awareness
  class ConditionalTokenIterator
    include Iterator(Token)

    @lexer : ConditionalLexer
    @state : LexerState
    @context_manager : ContextManager
    @token_queue : Array(Token)

    def initialize(@lexer : ConditionalLexer, text : String, @context_manager : ContextManager)
      @state = LexerState.new(text)
      @token_queue = [] of Token
    end

    def next : Token | Iterator::Stop
      loop do
        # Return queued tokens first
        unless @token_queue.empty?
          return @token_queue.shift
        end

        # If we're at the end, return EOF
        if @state.at_end?
          return stop
        end

        # Create current parsing context
        context = @context_manager.create_context(@state, @state.text, @state.pos)

        # Try context-aware rules first
        if context_match = @lexer.find_context_match(context)
          rule, match = context_match
          matched_text = match[0]

          # Execute the rule action
          groups = match.to_a[1..].map(&.to_s)
          tokens = execute_action(rule.action, matched_text, groups)

          # Advance the position
          @state.advance(matched_text.size)

          # Add tokens to history and queue
          if tokens.empty?
            next # No tokens generated, try again
          else
            first_token = tokens.shift
            @context_manager.add_token(first_token)
            tokens.each { |token| @context_manager.add_token(token) }
            @token_queue.concat(tokens)
            return first_token
          end
          # Fall back to regular lexer rules
        elsif match_data = @lexer.find_match(@state)
          rule, match = match_data
          matched_text = match[0]

          # Execute the rule action
          groups = match.to_a[1..].map(&.to_s)
          tokens = execute_action(rule.action, matched_text, groups)

          # Advance the position
          @state.advance(matched_text.size)

          # Add tokens to history and queue
          if tokens.empty?
            next # No tokens generated, try again
          else
            first_token = tokens.shift
            @context_manager.add_token(first_token)
            tokens.each { |token| @context_manager.add_token(token) }
            @token_queue.concat(tokens)
            return first_token
          end
        else
          # No rule matched, emit error token for current character
          char = @state.remaining[0]
          @state.advance(1)
          error_token = Token.new(TokenType::Error, char.to_s)
          @context_manager.add_token(error_token)
          return error_token
        end
      end
    end

    private def execute_action(action : RuleAction, matched_text : String, groups : Array(String)) : Array(Token)
      case action
      when TokenType
        [Token.new(action, matched_text)]
      when Proc
        action.call(matched_text, @state, groups)
      else
        [] of Token
      end
    end
  end

  # Helper module for creating common context-aware rules
  module ContextRuleHelpers
    # Create rule for string interpolation
    def self.string_interpolation_rule(start_pattern : Regex, state_to_push : String,
                                       token_type : TokenType = TokenType::LiteralStringInterpol) : ContextAwareRule
      condition = ContextConditions.in_state("string")
      action = RuleActions.push(state_to_push, token_type)

      ContextAwareRule.new(
        start_pattern,
        action,
        condition,
        priority: 100,
        description: "String interpolation start"
      )
    end

    # Create rule for comment that varies by language context
    def self.contextual_comment_rule(pattern : Regex,
                                     context_conditions : Hash(String, TokenType)) : ContextAwareRule
      condition = ->(context : ParsingContext) {
        context_conditions.any? do |state, _|
          context.state.in_state?(state)
        end
      }

      action = ->(match : String, state : LexerState, groups : Array(String)) {
        # Determine token type based on current state
        token_type = TokenType::Comment
        context_conditions.each do |state_name, type|
          if state.in_state?(state_name)
            token_type = type
            break
          end
        end
        [Token.new(token_type, match)]
      }

      ContextAwareRule.new(
        pattern,
        action,
        condition,
        priority: 50,
        description: "Context-dependent comment"
      )
    end

    # Create rule for balanced bracket tracking
    def self.bracket_tracking_rule(open_pattern : Regex, close_pattern : Regex,
                                   open_type : TokenType, close_type : TokenType,
                                   state_to_push : String? = nil) : Array(ContextAwareRule)
      rules = [] of ContextAwareRule

      # Opening bracket rule
      open_action = if state_to_push
                      RuleActions.push(state_to_push, open_type)
                    else
                      open_type
                    end

      rules << ContextAwareRule.new(
        open_pattern,
        open_action,
        priority: 90,
        description: "Opening bracket"
      )

      # Closing bracket rule
      close_action = if state_to_push
                       RuleActions.pop(close_type)
                     else
                       close_type
                     end

      rules << ContextAwareRule.new(
        close_pattern,
        close_action,
        priority: 90,
        description: "Closing bracket"
      )

      rules
    end

    # Create rule for template language expressions
    def self.template_expression_rule(start_delim : String, end_delim : String,
                                      template_state : String, expr_state : String) : Array(ContextAwareRule)
      rules = [] of ContextAwareRule

      start_pattern = Regex.new(Regex.escape(start_delim))
      end_pattern = Regex.new(Regex.escape(end_delim))

      # Start expression rule
      start_condition = ContextConditions.in_state(template_state)
      start_action = RuleActions.push(expr_state, TokenType::LiteralStringInterpol)

      rules << ContextAwareRule.new(
        start_pattern,
        start_action,
        start_condition,
        priority: 100,
        description: "Template expression start"
      )

      # End expression rule
      end_condition = ContextConditions.in_state(expr_state)
      end_action = RuleActions.pop(TokenType::LiteralStringInterpol)

      rules << ContextAwareRule.new(
        end_pattern,
        end_action,
        end_condition,
        priority: 100,
        description: "Template expression end"
      )

      rules
    end

    # Create rule that depends on recent token history
    def self.history_dependent_rule(pattern : Regex, required_recent_type : TokenType,
                                    success_type : TokenType, failure_type : TokenType,
                                    max_lookback = 5) : ContextAwareRule
      condition = ContextConditions.recent_token_type(required_recent_type, max_lookback)

      action = RuleActions.conditional(
        condition,
        success_type,
        failure_type
      )

      ContextAwareRule.new(
        pattern,
        action,
        priority: 75,
        description: "History-dependent rule"
      )
    end
  end

  # Pre-built context-sensitive lexer for common scenarios
  class ContextSensitiveLexer < ConditionalLexer
    def initialize(name : String, @config_data : LexerConfig, context_manager = ContextManager.new)
      super(context_manager)
      setup_common_rules
    end

    def config : LexerConfig
      @config_data
    end

    # Set up common context-sensitive patterns
    private def setup_common_rules
      # String interpolation in double quotes
      add_context_rule("root", ContextAwareRule.new(
        /"/,
        RuleActions.push("string", TokenType::LiteralStringDouble),
        priority: 100
      ))

      add_context_rule("string", ContextAwareRule.new(
        /"/,
        RuleActions.pop(TokenType::LiteralStringDouble),
        priority: 100
      ))

      # String interpolation
      add_context_rule("string", ContextAwareRule.new(
        /\$\{/,
        RuleActions.push("interpolation", TokenType::LiteralStringInterpol),
        priority: 100
      ))

      add_context_rule("interpolation", ContextAwareRule.new(
        /\}/,
        RuleActions.pop(TokenType::LiteralStringInterpol),
        priority: 100
      ))

      # Context-aware comments
      comment_condition = ContextConditions.not_in_state("string")
      add_context_rule("root", ContextAwareRule.new(
        /\/\/[^\n]*/,
        TokenType::CommentSingle,
        comment_condition,
        priority: 80
      ))

      add_context_rule("root", ContextAwareRule.new(
        /\/\*.*?\*\//m,
        TokenType::CommentMultiline,
        comment_condition,
        priority: 80
      ))

      # Bracket matching with context (simple punctuation, no state changes)
      add_context_rule("root", ContextAwareRule.new(
        /\{/,
        TokenType::Punctuation,
        priority: 90
      ))

      add_context_rule("root", ContextAwareRule.new(
        /\}/,
        TokenType::Punctuation,
        priority: 90
      ))

      # Also add rules for block state in case we get there
      add_context_rule("block", ContextAwareRule.new(
        /\{/,
        TokenType::Punctuation,
        priority: 90
      ))

      add_context_rule("block", ContextAwareRule.new(
        /\}/,
        TokenType::Punctuation,
        priority: 90
      ))

      # Fall-through rules for basic tokenization
      add_fallback_rule("root", LexerRule.new(/[a-zA-Z_][a-zA-Z0-9_]*/, TokenType::Name))
      add_fallback_rule("root", LexerRule.new(/\s+/, TokenType::Text))
      add_fallback_rule("string", LexerRule.new(/[^"$\\]+/, TokenType::LiteralStringDouble))
      add_fallback_rule("interpolation", LexerRule.new(/\w+/, TokenType::Name))
      add_fallback_rule("block", LexerRule.new(/\w+/, TokenType::Name))
      add_fallback_rule("block", LexerRule.new(/\s+/, TokenType::Text))
    end
  end
end
