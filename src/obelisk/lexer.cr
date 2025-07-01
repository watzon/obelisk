require "./token"

module Obelisk
  # Configuration for a lexer
  struct LexerConfig
    getter name : String
    getter aliases : Array(String)
    getter filenames : Array(String)
    getter mime_types : Array(String)
    getter case_insensitive : Bool
    getter dot_all : Bool
    getter not_multiline : Bool
    getter ensure_nl : Bool
    getter priority : Float32

    def initialize(@name : String,
                   @aliases = [] of String,
                   @filenames = [] of String,
                   @mime_types = [] of String,
                   @case_insensitive = false,
                   @dot_all = false,
                   @not_multiline = false,
                   @ensure_nl = false,
                   @priority = 0.0f32)
    end
  end

  # Iterator-like interface for tokens
  alias TokenIterator = Iterator(Token)

  # Base lexer interface
  abstract class Lexer
    abstract def config : LexerConfig
    abstract def tokenize(text : String) : TokenIterator

    # Analyze text to determine if this lexer can handle it
    # Returns a score from 0.0 to 1.0
    def analyze(text : String) : Float32
      0.0f32
    end

    # Get lexer name
    def name : String
      config.name
    end

    # Get lexer aliases
    def aliases : Array(String)
      config.aliases
    end

    # Get supported filenames (patterns)
    def filenames : Array(String)
      config.filenames
    end

    # Get supported MIME types
    def mime_types : Array(String)
      config.mime_types
    end

    # Check if lexer supports a filename
    def matches_filename?(filename : String) : Bool
      config.filenames.any? { |pattern| File.match?(pattern, filename) }
    end

    # Check if lexer supports a MIME type
    def matches_mime_type?(mime_type : String) : Bool
      config.mime_types.includes?(mime_type)
    end
  end

  # Enhanced state for regex-based lexers with advanced mutations
  class LexerState
    getter stack : Array(String)
    getter combined_states : Set(String)
    getter include_stack : Array(String)
    property pos : Int32
    property text : String
    property context : Hash(String, String)

    def initialize(@text : String, @pos = 0, @stack = ["root"])
      @combined_states = Set(String).new
      @include_stack = [] of String
      @context = {} of String => String
    end

    def current_state : String
      @stack.last
    end

    # Basic state operations
    def push_state(state : String) : Nil
      @stack << state
    end

    def pop_state : String?
      @stack.size > 1 ? @stack.pop : nil
    end

    # Advanced state mutations
    def include_state(state : String) : Nil
      @include_stack << state
    end

    def exit_include : String?
      @include_stack.pop?
    end

    def current_include_state : String?
      @include_stack.last?
    end

    def add_combined_state(state : String) : Nil
      @combined_states << state
    end

    def remove_combined_state(state : String) : Nil
      @combined_states.delete(state)
    end

    def clear_combined_states : Nil
      @combined_states.clear
    end

    def active_states : Array(String)
      states = [@stack.last]
      states << @include_stack.last if @include_stack.any?
      states.concat(@combined_states.to_a)
      states
    end

    # Context management
    def set_context(key : String, value : String) : Nil
      @context[key] = value
    end

    def get_context(key : String) : String?
      @context[key]?
    end

    def clear_context : Nil
      @context.clear
    end

    # Position and text operations
    def at_end? : Bool
      @pos >= @text.size
    end

    def remaining : String
      @text[@pos..]
    end

    def advance(count : Int32) : Nil
      @pos += count
    end

    def clone : LexerState
      cloned = LexerState.new(@text, @pos, @stack.dup)
      cloned.combined_states.concat(@combined_states)
      cloned.include_stack.concat(@include_stack)
      cloned.context.merge!(@context)
      cloned
    end

    # State queries
    def in_state?(state : String) : Bool
      active_states.includes?(state)
    end

    def has_combined_state?(state : String) : Bool
      @combined_states.includes?(state)
    end

    def in_include_state? : Bool
      @include_stack.any?
    end
  end

  # Rule for regex lexers
  struct LexerRule
    getter pattern : Regex
    getter action : RuleAction

    def initialize(@pattern : Regex, @action : RuleAction)
    end

    def match(text : String, pos : Int32) : Regex::MatchData?
      @pattern.match(text, pos)
    end
  end

  # Actions that can be performed when a rule matches
  alias RuleAction = TokenType | Proc(String, LexerState, Array(String), Array(Token))

  # Helper to create rule actions
  module RuleActions
    # Emit a single token of the given type
    def self.emit(type : TokenType) : RuleAction
      type
    end

    # Emit tokens for each capture group
    def self.by_groups(*types : TokenType) : RuleAction
      types_array = types.to_a
      ->(match : String, state : LexerState, groups : Array(String)) do
        result = [] of Token
        groups.each_with_index do |group, index|
          if index < types_array.size && !group.empty?
            result << Token.new(types_array[index], group)
          end
        end
        result
      end
    end

    # Basic state operations
    def self.push(state : String, type : TokenType? = nil) : RuleAction
      ->(match : String, lexer_state : LexerState, groups : Array(String)) do
        lexer_state.push_state(state)
        type ? [Token.new(type, match)] : [] of Token
      end
    end

    def self.pop(type : TokenType? = nil) : RuleAction
      ->(match : String, lexer_state : LexerState, groups : Array(String)) do
        lexer_state.pop_state
        type ? [Token.new(type, match)] : [] of Token
      end
    end

    # Advanced state mutations
    def self.include(state : String, type : TokenType? = nil) : RuleAction
      ->(match : String, lexer_state : LexerState, groups : Array(String)) do
        lexer_state.include_state(state)
        type ? [Token.new(type, match)] : [] of Token
      end
    end

    def self.exit_include(type : TokenType? = nil) : RuleAction
      ->(match : String, lexer_state : LexerState, groups : Array(String)) do
        lexer_state.exit_include
        type ? [Token.new(type, match)] : [] of Token
      end
    end

    def self.combine(state : String, type : TokenType? = nil) : RuleAction
      ->(match : String, lexer_state : LexerState, groups : Array(String)) do
        lexer_state.add_combined_state(state)
        type ? [Token.new(type, match)] : [] of Token
      end
    end

    def self.uncombine(state : String, type : TokenType? = nil) : RuleAction
      ->(match : String, lexer_state : LexerState, groups : Array(String)) do
        lexer_state.remove_combined_state(state)
        type ? [Token.new(type, match)] : [] of Token
      end
    end

    def self.clear_combined(type : TokenType? = nil) : RuleAction
      ->(match : String, lexer_state : LexerState, groups : Array(String)) do
        lexer_state.clear_combined_states
        type ? [Token.new(type, match)] : [] of Token
      end
    end

    # Context operations
    def self.set_context(key : String, value : String, type : TokenType? = nil) : RuleAction
      ->(match : String, lexer_state : LexerState, groups : Array(String)) do
        lexer_state.set_context(key, value)
        type ? [Token.new(type, match)] : [] of Token
      end
    end

    def self.set_context_from_match(key : String, type : TokenType? = nil) : RuleAction
      ->(match : String, lexer_state : LexerState, groups : Array(String)) do
        lexer_state.set_context(key, match)
        type ? [Token.new(type, match)] : [] of Token
      end
    end

    def self.clear_context(type : TokenType? = nil) : RuleAction
      ->(match : String, lexer_state : LexerState, groups : Array(String)) do
        lexer_state.clear_context
        type ? [Token.new(type, match)] : [] of Token
      end
    end

    # Compound actions
    def self.push_and_combine(push_state : String, combine_state : String, type : TokenType? = nil) : RuleAction
      ->(match : String, lexer_state : LexerState, groups : Array(String)) do
        lexer_state.push_state(push_state)
        lexer_state.add_combined_state(combine_state)
        type ? [Token.new(type, match)] : [] of Token
      end
    end

    def self.pop_and_uncombine(uncombine_state : String, type : TokenType? = nil) : RuleAction
      ->(match : String, lexer_state : LexerState, groups : Array(String)) do
        lexer_state.pop_state
        lexer_state.remove_combined_state(uncombine_state)
        type ? [Token.new(type, match)] : [] of Token
      end
    end

    # Conditional actions
    def self.conditional(condition : Proc(LexerState, Bool),
                         true_action : RuleAction,
                         false_action : RuleAction? = nil) : RuleAction
      ->(match : String, lexer_state : LexerState, groups : Array(String)) do
        action = condition.call(lexer_state) ? true_action : false_action
        if action
          case action
          when TokenType
            [Token.new(action, match)]
          when Proc
            action.call(match, lexer_state, groups)
          else
            [] of Token
          end
        else
          [] of Token
        end
      end
    end
  end

  # Base class for regex-based lexers
  abstract class RegexLexer < Lexer
    @rules : Hash(String, Array(LexerRule))?

    abstract def rules : Hash(String, Array(LexerRule))

    def tokenize(text : String) : TokenIterator
      RegexTokenIterator.new(self, text)
    end

    # Get rules for the current state
    def state_rules(state : String) : Array(LexerRule)
      rules[state]? || [] of LexerRule
    end

    # Find the first matching rule from all active states
    def find_match(state : LexerState) : {LexerRule, Regex::MatchData}?
      remaining = state.remaining

      # Check rules from all active states in priority order:
      # 1. Include state (highest priority)
      # 2. Combined states
      # 3. Current main state

      # Check include state first (if any)
      if include_state = state.current_include_state
        if rule_match = try_rules_for_state(include_state, remaining)
          return rule_match
        end
      end

      # Check combined states
      state.combined_states.each do |combined_state|
        if rule_match = try_rules_for_state(combined_state, remaining)
          return rule_match
        end
      end

      # Check current main state
      if rule_match = try_rules_for_state(state.current_state, remaining)
        return rule_match
      end

      nil
    end

    private def try_rules_for_state(state_name : String, remaining : String) : {LexerRule, Regex::MatchData}?
      current_rules = state_rules(state_name)

      current_rules.each do |rule|
        if match = rule.match(remaining, 0)
          # Only accept matches that start at position 0
          if match.begin(0) == 0
            return {rule, match}
          end
        end
      end

      nil
    end
  end

  # Token iterator for regex lexers
  class RegexTokenIterator
    include Iterator(Token)

    def initialize(@lexer : RegexLexer, text : String)
      @state = LexerState.new(text)
      @token_queue = Deque(Token).new
      @finished = false
    end

    def next : Token | Iterator::Stop
      loop do
        # Return queued tokens first
        if !@token_queue.empty?
          return @token_queue.shift
        end

        # If we're finished, return stop
        if @finished
          return stop
        end

        # If we're at the end, mark finished and return EOF
        if @state.at_end?
          @finished = true
          return stop
        end

        # Safety check to prevent infinite loops
        start_pos = @state.pos

        # Find a matching rule
        if match_data = @lexer.find_match(@state)
          rule, match = match_data
          matched_text = match[0]

          # Safety check: ensure we got a valid match
          if matched_text.empty?
            # Empty match, advance by one character to prevent infinite loop
            if !@state.at_end?
              char = @state.remaining[0]
              @state.advance(1)
              return Token.new(TokenType::Error, char.to_s)
            else
              @finished = true
              return stop
            end
          end

          # Execute the rule action
          groups = begin
            match.to_a[1..].map(&.to_s)
          rescue
            [] of String # Handle potential array access errors
          end

          tokens = execute_action(rule.action, matched_text, groups)

          # Advance the position
          @state.advance(matched_text.size)

          # Safety check: ensure we made progress
          if @state.pos == start_pos
            # No progress made, force advance to prevent infinite loop
            if !@state.at_end?
              char = @state.remaining[0]
              @state.advance(1)
              return Token.new(TokenType::Error, char.to_s)
            else
              @finished = true
              return stop
            end
          end

          # Queue additional tokens and return the first one
          if tokens.empty?
            # No tokens generated, try again
            next
          else
            first_token = tokens.shift
            if !tokens.empty?
              @token_queue.concat(tokens)
            end
            return first_token
          end
        else
          # No rule matched, emit error token for current character
          if !@state.at_end?
            char = @state.remaining[0]
            @state.advance(1)
            return Token.new(TokenType::Error, char.to_s)
          else
            @finished = true
            return stop
          end
        end
      end
    end

    private def execute_action(action : RuleAction, matched_text : String, groups : Array(String)) : Array(Token)
      begin
        case action
        when TokenType
          [Token.new(action, matched_text)]
        when Proc
          result = action.call(matched_text, @state, groups)
          result.is_a?(Array(Token)) ? result : [] of Token
        else
          [] of Token
        end
      rescue
        # If action execution fails, return a basic token
        [Token.new(TokenType::Error, matched_text)]
      end
    end
  end

  # Represents a region of text that should be delegated to another lexer
  struct EmbeddedRegion
    getter start_pos : Int32
    getter end_pos : Int32
    getter lexer : Lexer
    getter start_token : Token?
    getter end_token : Token?

    def initialize(@start_pos : Int32, @end_pos : Int32, @lexer : Lexer,
                   @start_token : Token? = nil, @end_token : Token? = nil)
    end

    def content(text : String) : String
      text[start_pos...end_pos]
    end

    def size : Int32
      end_pos - start_pos
    end
  end

  # Interface for detecting embedded regions in text
  abstract class RegionDetector
    abstract def detect_regions(text : String, state : LexerState) : Array(EmbeddedRegion)
  end

  # Regex-based region detector for simple cases
  class RegexRegionDetector < RegionDetector
    def initialize(@start_pattern : Regex, @end_pattern : Regex, @lexer : Lexer,
                   @start_token_type : TokenType? = nil, @end_token_type : TokenType? = nil)
    end

    def detect_regions(text : String, state : LexerState) : Array(EmbeddedRegion)
      regions = [] of EmbeddedRegion
      pos = state.pos

      while pos < text.size
        # Find start pattern
        if start_match = @start_pattern.match(text, pos)
          start_pos = start_match.begin(0)
          start_end = start_match.end(0)

          # Find corresponding end pattern
          if end_match = @end_pattern.match(text, start_end)
            end_start = end_match.begin(0)
            end_pos = end_match.end(0)

            # Create tokens for start/end delimiters if specified
            start_token = @start_token_type ? Token.new(@start_token_type.not_nil!, start_match[0]) : nil
            end_token = @end_token_type ? Token.new(@end_token_type.not_nil!, end_match[0]) : nil

            # Create region for the content between delimiters
            regions << EmbeddedRegion.new(start_end, end_start, @lexer, start_token, end_token)
            pos = end_pos
          else
            # No end found, stop looking
            break
          end
        else
          # No more start patterns found
          break
        end
      end

      regions
    end
  end

  # Lexer that can delegate regions to other lexers
  abstract class DelegatingLexer < Lexer
    @region_detectors : Array(RegionDetector)

    def initialize
      @region_detectors = [] of RegionDetector
    end

    abstract def base_lexer : RegexLexer

    def add_region_detector(detector : RegionDetector) : Nil
      @region_detectors << detector
    end

    def tokenize(text : String) : TokenIterator
      DelegatingTokenIterator.new(self, text)
    end

    def detect_all_regions(text : String, state : LexerState) : Array(EmbeddedRegion)
      all_regions = [] of EmbeddedRegion

      @region_detectors.each do |detector|
        regions = detector.detect_regions(text, state)
        all_regions.concat(regions)
      end

      # Sort regions by start position
      all_regions.sort_by!(&.start_pos)
      all_regions
    end
  end

  # Simple iterator for single tokens (avoids Crystal bug with [token].each.as())
  class SingleTokenIterator
    include Iterator(Token)

    def initialize(@token : Token)
      @yielded = false
    end

    def next : Token | Iterator::Stop
      if @yielded
        stop
      else
        @yielded = true
        @token
      end
    end
  end

  # Safe adapter to work around Crystal bug #14317 with RegexTokenIterator
  # This pre-fetches tokens to avoid memory corruption when iterating
  class SafeTokenIteratorAdapter
    include Iterator(Token)

    def initialize(lexer : Lexer, text : String)
      @tokens = [] of Token
      @index = 0

      # Pre-fetch all tokens to avoid iterator issues
      begin
        iter = lexer.tokenize(text)
        # Limit to prevent infinite loops
        10000.times do
          case token = iter.next
          when Token
            @tokens << token
          when Iterator::Stop
            break
          end
        end
      rescue
        # If tokenization fails, leave tokens empty
      end
    end

    def next : Token | Iterator::Stop
      if @index < @tokens.size
        token = @tokens[@index]
        @index += 1
        token
      else
        stop
      end
    end
  end

  # Token iterator for delegating lexers
  class DelegatingTokenIterator
    include Iterator(Token)

    @segments : Array({iterator: TokenIterator, delimiter: Token?})
    @finished : Bool

    def initialize(@lexer : DelegatingLexer, @text : String)
      @pos = 0
      @finished = false
      @regions = [] of EmbeddedRegion
      @current_region_index = 0
      @segments = [] of {iterator: TokenIterator, delimiter: Token?}
      @current_segment_index = 0
      @current_iterator = nil.as(TokenIterator?)

      begin
        @regions = @lexer.detect_all_regions(@text, LexerState.new(@text))
        @segments = build_segments
      rescue ex
        # If initialization fails, create a fallback segment
        @segments = [{
          iterator:  SafeTokenIteratorAdapter.new(@lexer.base_lexer, @text).as(TokenIterator),
          delimiter: nil.as(Token?),
        }]
        @finished = false # We still have one segment to process
      end
    end

    def next : Token | Iterator::Stop
      return stop if @finished

      loop do
        # If we don't have a current iterator, get the next segment
        unless @current_iterator
          if @current_segment_index >= @segments.size
            @finished = true
            return stop
          end

          begin
            segment = @segments[@current_segment_index]
            @current_iterator = segment[:iterator]
            @current_segment_index += 1

            # Emit delimiter token if present
            if delimiter = segment[:delimiter]
              return delimiter
            end
          rescue
            # If segment access fails, mark as finished
            @finished = true
            return stop
          end
        end

        # Get the next token from the current iterator
        if iterator = @current_iterator
          begin
            case token = iterator.next
            when Token
              return token
            when Iterator::Stop
              @current_iterator = nil
              next # Move to next segment
            end
          rescue
            # If iterator fails, move to next segment
            @current_iterator = nil
            next
          end
        else
          # This shouldn't happen, but handle it gracefully
          @finished = true
          return stop
        end
      end
    end

    private def build_segments
      segments = [] of {iterator: TokenIterator, delimiter: Token?}
      last_pos = 0

      begin
        @regions.each do |region|
          # Validate region bounds
          next if region.start_pos < 0 || region.start_pos >= @text.size
          next if region.end_pos && (region.end_pos.not_nil! <= region.start_pos || region.end_pos.not_nil! > @text.size)

          # Add base lexer segment before the region
          if region.start_pos > last_pos
            begin
              base_content = @text[last_pos...region.start_pos]
              unless base_content.empty?
                # Use safe adapter for all lexers to avoid Crystal bug #14317
                segments << {
                  iterator:  SafeTokenIteratorAdapter.new(@lexer.base_lexer, base_content).as(TokenIterator),
                  delimiter: nil.as(Token?),
                }
              end
            rescue
              # Skip this segment if string slicing fails
            end
          end

          # Add start delimiter if present
          if start_token = region.start_token
            begin
              segments << {
                iterator:  SingleTokenIterator.new(start_token).as(TokenIterator),
                delimiter: nil.as(Token?),
              }
            rescue
              # Skip if iterator creation fails
            end
          end

          # Add embedded region
          begin
            content = region.content(@text)
            unless content.empty?
              # Use safe adapter for all lexers to avoid Crystal bug #14317
              segments << {
                iterator:  SafeTokenIteratorAdapter.new(region.lexer, content).as(TokenIterator),
                delimiter: nil.as(Token?),
              }
            end
          rescue
            # Skip if content extraction or tokenization fails
          end

          # Add end delimiter if present
          if end_token = region.end_token
            begin
              segments << {
                iterator:  SingleTokenIterator.new(end_token).as(TokenIterator),
                delimiter: nil.as(Token?),
              }
            rescue
              # Skip if iterator creation fails
            end
          end

          last_pos = region.end_pos || region.start_pos
        end

        # Add remaining base content
        if last_pos < @text.size
          begin
            remaining_content = @text[last_pos..]
            unless remaining_content.empty?
              # Use safe adapter for all lexers to avoid Crystal bug #14317
              segments << {
                iterator:  SafeTokenIteratorAdapter.new(@lexer.base_lexer, remaining_content).as(TokenIterator),
                delimiter: nil.as(Token?),
              }
            end
          rescue
            # Skip if remaining content processing fails
          end
        end
      rescue
        # If any major error occurs, create a fallback segment with the entire text
        segments = [{
          iterator:  SafeTokenIteratorAdapter.new(@lexer.base_lexer, @text).as(TokenIterator),
          delimiter: nil.as(Token?),
        }]
      end

      segments
    end
  end

  # Helper for creating common embedded language patterns
  module EmbeddedLanguageHelpers
    # Create a detector for code blocks (like Markdown)
    def self.code_block_detector(language : String, lexer : Lexer) : RegionDetector
      start_pattern = /^```#{Regex.escape(language)}\s*\n/m
      end_pattern = /^```\s*$/m
      RegexRegionDetector.new(
        start_pattern,
        end_pattern,
        lexer,
        TokenType::Punctuation, # ```language
        TokenType::Punctuation  # ```
      )
    end

    # Create a detector for template expressions
    def self.template_expression_detector(start_delim : String, end_delim : String, lexer : Lexer) : RegionDetector
      start_pattern = Regex.new(Regex.escape(start_delim))
      end_pattern = Regex.new(Regex.escape(end_delim))
      RegexRegionDetector.new(
        start_pattern,
        end_pattern,
        lexer,
        TokenType::Punctuation, # start delimiter
        TokenType::Punctuation  # end delimiter
      )
    end

    # Create a detector for tag-based embedding (like script tags)
    def self.tag_based_detector(tag_name : String, lexer : Lexer) : RegionDetector
      start_pattern = /<#{Regex.escape(tag_name)}[^>]*>/i
      end_pattern = /<\/#{Regex.escape(tag_name)}\s*>/i
      RegexRegionDetector.new(
        start_pattern,
        end_pattern,
        lexer,
        TokenType::NameTag, # opening tag
        TokenType::NameTag  # closing tag
      )
    end
  end

  # Simple lexer that treats all input as text
  class PlainTextLexer < Lexer
    def config : LexerConfig
      LexerConfig.new(
        name: "text",
        aliases: ["text", "plain"],
        filenames: ["*.txt"],
        mime_types: ["text/plain"]
      )
    end

    def tokenize(text : String) : TokenIterator
      PlainTextIterator.new(text)
    end
  end

  # Iterator for plain text lexer
  class PlainTextIterator
    include Iterator(Token)

    @text : String
    @yielded : Bool

    def initialize(text : String)
      # Make a copy of the string to avoid reference issues
      @text = text.dup
      @yielded = false
    end

    def next : Token | Iterator::Stop
      if @yielded
        stop
      else
        @yielded = true
        Token.new(TokenType::Text, @text)
      end
    end
  end

  # Strategies for combining multiple lexers
  enum CompositionStrategy
    # First matching lexer wins
    FirstMatch
    # Highest confidence lexer wins
    HighestConfidence
    # Merge tokens from all matching lexers
    MergeAll
    # Layer lexers with priority order
    Layered
  end

  # Framework for composing multiple lexers together
  class ComposedLexer < Lexer
    @lexers : Array(Lexer)
    @strategy : CompositionStrategy

    def initialize(@name : String, lexers : Array(Lexer), @strategy = CompositionStrategy::FirstMatch)
      # Create a new array to ensure proper typing without using problematic methods
      temp_lexers = [] of Lexer
      lexers.each do |lexer|
        temp_lexers << lexer
      end
      @lexers = temp_lexers
    end

    def config : LexerConfig
      # Use the first lexer's config as base, combining other properties
      base_config = @lexers.first.config

      combined_aliases = @lexers.flat_map(&.aliases).uniq
      combined_filenames = @lexers.flat_map(&.filenames).uniq
      combined_mimes = @lexers.flat_map(&.mime_types).uniq

      LexerConfig.new(
        name: @name,
        aliases: combined_aliases,
        filenames: combined_filenames,
        mime_types: combined_mimes,
        priority: base_config.priority
      )
    end

    def analyze(text : String) : Float32
      case @strategy
      when .first_match?
        @lexers.each do |lexer|
          score = lexer.analyze(text)
          return score if score > 0.5f32
        end
        0.0f32
      when .highest_confidence?
        @lexers.map(&.analyze(text)).max
      when .merge_all?, .layered?
        # For merge/layered strategies, return average confidence
        scores = @lexers.map(&.analyze(text))
        scores.empty? ? 0.0f32 : scores.sum / scores.size
      else
        0.0f32
      end
    end

    def tokenize(text : String) : TokenIterator
      case @strategy
      when .first_match?
        # Use first lexer that has confidence > 0.5
        selected_lexer = @lexers.find { |l| l.analyze(text) > 0.5f32 }
        selected_lexer ||= @lexers.first
        selected_lexer.tokenize(text)
      when .highest_confidence?
        # Use lexer with highest confidence
        best_lexer = @lexers.max_by(&.analyze(text))
        best_lexer.tokenize(text)
      when .merge_all?
        MergingTokenIterator.new(@lexers.map(&.tokenize(text)))
      when .layered?
        LayeredTokenIterator.new(@lexers.map(&.tokenize(text)))
      else
        @lexers.first.tokenize(text)
      end
    end
  end

  # Token iterator that merges tokens from multiple lexers
  class MergingTokenIterator
    include Iterator(Token)

    @iterators : Array(TokenIterator)
    @current_tokens : Deque(Tuple(Token, Int32))
    @positions : Array(Int32)
    @finished : Array(Bool)

    def initialize(iterators : Array(TokenIterator))
      @iterators = iterators.map(&.as(TokenIterator))
      @current_tokens = Deque(Tuple(Token, Int32)).new # token with source iterator index
      @positions = Array.new(@iterators.size, 0)
      @finished = Array.new(@iterators.size, false)
      prime_tokens
    end

    def next : Token | Iterator::Stop
      return stop if @current_tokens.empty?

      # Get the next token (sorted by position, then by iterator priority)
      @current_tokens.to_a.sort_by! { |token_info| token_info[0].value.size }
      @current_tokens = Deque.new(@current_tokens.to_a.sort_by! { |token_info| token_info[0].value.size })

      if @current_tokens.empty?
        return stop
      end

      token, iterator_index = @current_tokens.shift

      # Prime the next token from the same iterator
      advance_iterator(iterator_index)

      token
    end

    private def prime_tokens
      @iterators.each_with_index do |iterator, index|
        advance_iterator(index)
      end
    end

    private def advance_iterator(index : Int32)
      return if index >= @finished.size || @finished[index]

      begin
        case token = @iterators[index].next
        when Token
          @current_tokens << {token, index}
          @positions[index] += token.value.size
        when Iterator::Stop
          @finished[index] = true
        end
      rescue
        # Mark as finished if there's an error
        @finished[index] = true
      end
    end
  end

  # Token iterator that layers tokens from multiple lexers with priority
  class LayeredTokenIterator
    include Iterator(Token)

    @iterators : Array(TokenIterator)
    @current_iterators : Array(TokenIterator)
    @current_index : Int32

    def initialize(iterators : Array(TokenIterator))
      @iterators = iterators.map(&.as(TokenIterator))
      @current_iterators = @iterators.dup
      @current_index = 0
    end

    def next : Token | Iterator::Stop
      while @current_index < @current_iterators.size
        iterator = @current_iterators[@current_index]

        case token = iterator.next
        when Token
          return token
        when Iterator::Stop
          @current_index += 1
          next
        end
      end

      stop
    end
  end

  # Framework for chaining lexers in sequence
  class ChainedLexer < Lexer
    @chain : Array(Lexer)

    def initialize(@name : String, chain : Array(Lexer))
      # Create a new array to ensure proper typing
      temp_chain = [] of Lexer
      chain.each do |lexer|
        temp_chain << lexer
      end
      @chain = temp_chain
    end

    def config : LexerConfig
      # Use the last lexer's config as it represents the final output
      last_config = @chain.last.config

      LexerConfig.new(
        name: @name,
        aliases: [last_config.name] + last_config.aliases,
        filenames: last_config.filenames,
        mime_types: last_config.mime_types,
        priority: last_config.priority
      )
    end

    def analyze(text : String) : Float32
      # Chain analysis: each lexer in sequence must have confidence
      total_confidence = 1.0f32

      @chain.each do |lexer|
        confidence = lexer.analyze(text)
        total_confidence *= confidence
        break if confidence == 0.0f32
      end

      total_confidence
    end

    def tokenize(text : String) : TokenIterator
      ChainedTokenIterator.new(@chain, text)
    end
  end

  # Token iterator that processes tokens through a chain of lexers
  class ChainedTokenIterator
    include Iterator(Token)

    @current_iterator : TokenIterator

    def initialize(@chain : Array(Lexer), @text : String)
      @current_iterator = build_chain_iterator
    end

    def next : Token | Iterator::Stop
      @current_iterator.next
    end

    private def build_chain_iterator
      # Start with the first lexer
      current_iterator = @chain.first.tokenize(@text)

      # Process through each subsequent lexer in the chain
      @chain[1..].each do |lexer|
        current_iterator = process_through_lexer(current_iterator, lexer)
      end

      current_iterator
    end

    private def process_through_lexer(source : TokenIterator, lexer : Lexer) : TokenIterator
      TokenTransformIterator.new(source, lexer)
    end
  end

  # Iterator that transforms tokens through another lexer
  class TokenTransformIterator
    include Iterator(Token)

    def initialize(@source : TokenIterator, @lexer : Lexer)
      @buffer = Deque(Token).new
      @source_finished = false
    end

    def next : Token | Iterator::Stop
      # Return buffered tokens first
      if !@buffer.empty?
        return @buffer.shift
      end

      # Get next source token and process it
      begin
        case source_token = @source.next
        when Token
          # Process the token's value through the target lexer
          processed_tokens = @lexer.tokenize(source_token.value).to_a

          if processed_tokens.empty?
            # If no tokens produced, return original
            source_token
          else
            # Return first processed token, buffer the rest
            first_token = processed_tokens.shift
            if !processed_tokens.empty?
              @buffer.concat(processed_tokens)
            end
            first_token
          end
        when Iterator::Stop
          stop
        else
          # This should never happen, but satisfies Crystal's type checker
          stop
        end
      rescue
        # If any error occurs, return stop
        stop
      end
    end
  end

  # Helper module for creating lexer compositions
  module LexerComposition
    # Create a composed lexer with multiple strategies
    def self.compose(name : String, lexers : Array(Lexer), strategy = CompositionStrategy::FirstMatch) : ComposedLexer
      ComposedLexer.new(name, lexers, strategy)
    end

    # Create a chained lexer that processes through multiple stages
    def self.chain(name : String, lexers : Array(Lexer)) : ChainedLexer
      ChainedLexer.new(name, lexers)
    end

    # Create a fallback lexer that tries lexers in order until one succeeds
    def self.fallback(name : String, lexers : Array(Lexer)) : ComposedLexer
      ComposedLexer.new(name, lexers, CompositionStrategy::FirstMatch)
    end

    # Create a confidence-based selector
    def self.best_match(name : String, lexers : Array(Lexer)) : ComposedLexer
      ComposedLexer.new(name, lexers, CompositionStrategy::HighestConfidence)
    end

    # Create a merging lexer that combines tokens from multiple lexers
    def self.merge(name : String, lexers : Array(Lexer)) : ComposedLexer
      ComposedLexer.new(name, lexers, CompositionStrategy::MergeAll)
    end

    # Create a layered lexer with priority ordering
    def self.layer(name : String, lexers : Array(Lexer)) : ComposedLexer
      ComposedLexer.new(name, lexers, CompositionStrategy::Layered)
    end
  end

  # Selection criteria for priority-based lexer selection
  struct SelectionCriteria
    getter priority_weight : Float32
    getter confidence_weight : Float32
    getter filename_weight : Float32
    getter mime_type_weight : Float32
    getter content_weight : Float32
    getter fallback_enabled : Bool

    def initialize(@priority_weight = 0.3f32, @confidence_weight = 0.4f32,
                   @filename_weight = 0.2f32, @mime_type_weight = 0.1f32,
                   @content_weight = 0.0f32, @fallback_enabled = true)
    end
  end

  # Result from lexer selection with score breakdown
  struct SelectionResult
    getter lexer : Lexer
    getter total_score : Float32
    getter priority_score : Float32
    getter confidence_score : Float32
    getter filename_score : Float32
    getter mime_type_score : Float32
    getter content_score : Float32

    def initialize(@lexer : Lexer, @total_score : Float32, @priority_score : Float32,
                   @confidence_score : Float32, @filename_score : Float32,
                   @mime_type_score : Float32, @content_score : Float32)
    end
  end

  # Priority-based lexer selection system
  class PriorityLexerSelector
    @criteria : SelectionCriteria

    def initialize(@criteria = SelectionCriteria.new)
    end

    # Select the best lexer for the given parameters
    def select(lexers : Array(Lexer), text : String, filename : String? = nil,
               mime_type : String? = nil) : SelectionResult?
      return nil if lexers.empty?

      # Score all lexers
      scored_lexers = lexers.compact_map { |lexer| score_lexer(lexer, text, filename, mime_type) }

      # Return the highest scoring lexer
      scored_lexers.max_by?(&.total_score)
    end

    # Select multiple lexers ranked by score
    def select_ranked(lexers : Array(Lexer), text : String, filename : String? = nil,
                      mime_type : String? = nil, limit : Int32? = nil) : Array(SelectionResult)
      return [] of SelectionResult if lexers.empty?

      # Score all lexers and sort by descending score
      scored_lexers = lexers.compact_map { |lexer| score_lexer(lexer, text, filename, mime_type) }
      ranked = scored_lexers.sort_by(&.total_score).reverse

      limit ? ranked.first(limit) : ranked
    end

    # Check if a lexer meets minimum threshold
    def meets_threshold?(lexer : Lexer, text : String, threshold : Float32 = 0.5f32,
                         filename : String? = nil, mime_type : String? = nil) : Bool
      result = score_lexer(lexer, text, filename, mime_type)
      result ? result.total_score >= threshold : false
    end

    private def score_lexer(lexer : Lexer, text : String, filename : String?,
                            mime_type : String?) : SelectionResult?
      config = lexer.config

      # Calculate individual scores (0.0 to 1.0)
      priority_score = calculate_priority_score(config.priority)
      confidence_score = lexer.analyze(text)
      filename_score = filename ? calculate_filename_score(lexer, filename) : 0.0f32
      mime_type_score = mime_type ? calculate_mime_type_score(lexer, mime_type) : 0.0f32
      content_score = @criteria.content_weight > 0 ? calculate_content_score(lexer, text) : 0.0f32

      # Calculate weighted total score
      total_score = (
        priority_score * @criteria.priority_weight +
        confidence_score * @criteria.confidence_weight +
        filename_score * @criteria.filename_weight +
        mime_type_score * @criteria.mime_type_weight +
        content_score * @criteria.content_weight
      )

      SelectionResult.new(
        lexer, total_score, priority_score, confidence_score,
        filename_score, mime_type_score, content_score
      )
    end

    private def calculate_priority_score(priority : Float32) : Float32
      # Normalize priority to 0.0-1.0 range
      # Assuming priorities typically range from 0.0 to 10.0
      Math.min(priority / 10.0f32, 1.0f32)
    end

    private def calculate_filename_score(lexer : Lexer, filename : String) : Float32
      return 1.0f32 if lexer.matches_filename?(filename)

      # Partial scoring for similar extensions
      lexer_extensions = lexer.filenames.compact_map do |pattern|
        pattern.starts_with?("*.") ? pattern[2..] : nil
      end

      file_extension = File.extname(filename).lchop('.')

      if file_extension.empty?
        0.0f32
      else
        # Check for partial matches (e.g., "cpp" matches "cxx", "c++")
        partial_match = lexer_extensions.any? do |ext|
          ext.includes?(file_extension) || file_extension.includes?(ext)
        end
        partial_match ? 0.3f32 : 0.0f32
      end
    end

    private def calculate_mime_type_score(lexer : Lexer, mime_type : String) : Float32
      return 1.0f32 if lexer.matches_mime_type?(mime_type)

      # Partial scoring for related MIME types
      lexer_types = lexer.mime_types

      # Check for parent type matches (e.g., "text/*" matches "text/plain")
      base_type = mime_type.split('/')[0]? || ""
      parent_match = lexer_types.any? { |type| type.starts_with?(base_type + "/") }

      parent_match ? 0.4f32 : 0.0f32
    end

    private def calculate_content_score(lexer : Lexer, text : String) : Float32
      # This is application-specific and could analyze content patterns
      # For now, just return the confidence score
      lexer.analyze(text)
    end
  end

  # Enhanced lexer registry with priority-based selection
  class PriorityLexerRegistry
    @lexers = {} of String => Lexer
    @aliases = {} of String => String
    @selector : PriorityLexerSelector

    def initialize(@selector = PriorityLexerSelector.new)
    end

    def register(lexer : Lexer) : Nil
      name = lexer.name
      @lexers[name] = lexer

      # Register aliases
      lexer.aliases.each do |alias_name|
        @aliases[alias_name] = name
      end
    end

    def get(name : String) : Lexer?
      # Try direct lookup first
      if lexer = @lexers[name]?
        return lexer
      end

      # Try alias lookup
      if real_name = @aliases[name]?
        return @lexers[real_name]?
      end

      nil
    end

    def all : Array(Lexer)
      @lexers.values
    end

    def names : Array(String)
      @lexers.keys
    end

    # Priority-based selection methods
    def select_best(text : String, filename : String? = nil,
                    mime_type : String? = nil) : SelectionResult?
      @selector.select(all, text, filename, mime_type)
    end

    def select_ranked(text : String, filename : String? = nil, mime_type : String? = nil,
                      limit : Int32? = nil) : Array(SelectionResult)
      @selector.select_ranked(all, text, filename, mime_type, limit)
    end

    def select_by_name_or_auto(name_or_alias : String?, text : String,
                               filename : String? = nil, mime_type : String? = nil) : Lexer?
      # If name provided, try to get specific lexer
      if name_or_alias && !name_or_alias.empty?
        return get(name_or_alias)
      end

      # Otherwise use automatic selection
      result = select_best(text, filename, mime_type)
      result ? result.lexer : nil
    end

    def get_candidates(filename : String? = nil, mime_type : String? = nil) : Array(Lexer)
      candidates = all

      # Filter by filename if provided
      if filename
        filename_matches = candidates.select(&.matches_filename?(filename))
        candidates = filename_matches unless filename_matches.empty?
      end

      # Filter by MIME type if provided
      if mime_type
        mime_matches = candidates.select(&.matches_mime_type?(mime_type))
        candidates = mime_matches unless mime_matches.empty?
      end

      candidates
    end

    def meets_threshold?(lexer_name : String, text : String, threshold : Float32 = 0.5f32,
                         filename : String? = nil, mime_type : String? = nil) : Bool
      lexer = get(lexer_name)
      return false unless lexer

      @selector.meets_threshold?(lexer, text, threshold, filename, mime_type)
    end
  end

  # Selection strategy for different use cases
  enum SelectionStrategy
    # Automatic selection based on all criteria
    Auto
    # Filename-based selection only
    Filename
    # MIME type-based selection only
    MimeType
    # Content analysis only
    Content
    # Manual selection by name
    Manual
    # Fallback to plain text
    Fallback
  end

  # High-level lexer selector with multiple strategies
  class SmartLexerSelector
    @registry : PriorityLexerRegistry
    @fallback_lexer : Lexer

    def initialize(@registry : PriorityLexerRegistry, @fallback_lexer : Lexer)
    end

    def select(text : String, strategy : SelectionStrategy = SelectionStrategy::Auto,
               lexer_name : String? = nil, filename : String? = nil,
               mime_type : String? = nil) : Lexer
      case strategy
      when .auto?
        auto_select(text, filename, mime_type)
      when .filename?
        filename_select(filename) || @fallback_lexer
      when .mime_type?
        mime_type_select(mime_type) || @fallback_lexer
      when .content?
        content_select(text) || @fallback_lexer
      when .manual?
        manual_select(lexer_name) || @fallback_lexer
      when .fallback?
        @fallback_lexer
      else
        @fallback_lexer
      end
    end

    private def auto_select(text : String, filename : String?, mime_type : String?) : Lexer
      result = @registry.select_best(text, filename, mime_type)
      result ? result.lexer : @fallback_lexer
    end

    private def filename_select(filename : String?) : Lexer?
      return nil unless filename

      candidates = @registry.get_candidates(filename: filename)
      candidates.max_by?(&.config.priority)
    end

    private def mime_type_select(mime_type : String?) : Lexer?
      return nil unless mime_type

      candidates = @registry.get_candidates(mime_type: mime_type)
      candidates.max_by?(&.config.priority)
    end

    private def content_select(text : String) : Lexer?
      # Use content analysis only
      criteria = SelectionCriteria.new(
        priority_weight: 0.0f32,
        confidence_weight: 1.0f32,
        filename_weight: 0.0f32,
        mime_type_weight: 0.0f32
      )
      selector = PriorityLexerSelector.new(criteria)

      result = selector.select(@registry.all, text)
      result ? result.lexer : nil
    end

    private def manual_select(lexer_name : String?) : Lexer?
      return nil unless lexer_name
      @registry.get(lexer_name)
    end
  end

  # Embedded language context management
  class LanguageContext
    getter language : String
    getter start_pos : Int32
    getter end_pos : Int32?
    getter parent_context : LanguageContext?
    getter nesting_level : Int32
    getter context_data : Hash(String, String)

    def initialize(@language : String, @start_pos : Int32, @end_pos : Int32? = nil,
                   @parent_context : LanguageContext? = nil, @nesting_level = 0,
                   @context_data = {} of String => String)
    end

    def active? : Bool
      @end_pos.nil?
    end

    def size : Int32
      return 0 unless end_pos = @end_pos
      end_pos - @start_pos
    end

    def content(text : String) : String
      return "" unless end_pos = @end_pos
      text[@start_pos...end_pos]
    end

    def close(end_pos : Int32) : LanguageContext
      LanguageContext.new(@language, @start_pos, end_pos, @parent_context,
        @nesting_level, @context_data)
    end
  end

  # Language nesting rules and patterns
  class LanguageNestingRule
    getter parent_language : String
    getter embedded_language : String
    getter start_pattern : Regex
    getter end_pattern : Regex
    getter max_nesting_level : Int32
    getter context_extractor : Proc(String, Hash(String, String))?

    def initialize(@parent_language : String, @embedded_language : String,
                   @start_pattern : Regex, @end_pattern : Regex,
                   @max_nesting_level = 10, @context_extractor = nil)
    end

    def matches_parent?(language : String) : Bool
      @parent_language == language || @parent_language == "*"
    end

    def can_nest?(current_level : Int32) : Bool
      current_level < @max_nesting_level
    end

    def extract_context(match_text : String) : Hash(String, String)
      extractor = @context_extractor
      extractor ? extractor.call(match_text) : {} of String => String
    end
  end

  # Comprehensive embedded language support architecture
  class EmbeddedLanguageArchitecture
    @nesting_rules = [] of LanguageNestingRule
    @language_lexers = {} of String => Lexer
    @fallback_lexer : Lexer

    def initialize(@fallback_lexer : Lexer)
    end

    def register_lexer(language : String, lexer : Lexer) : Nil
      @language_lexers[language] = lexer
    end

    def add_nesting_rule(rule : LanguageNestingRule) : Nil
      @nesting_rules << rule
    end

    def get_lexer(language : String) : Lexer
      @language_lexers[language]? || @fallback_lexer
    end

    # Analyze text and build language context hierarchy
    def analyze_contexts(text : String, base_language : String = "text") : Array(LanguageContext)
      contexts = [] of LanguageContext
      current_contexts = [] of LanguageContext
      pos = 0

      # Start with base language context
      base_context = LanguageContext.new(base_language, 0)
      current_contexts << base_context

      while pos < text.size
        # Look for nesting patterns in current language contexts
        match_found = false

        current_contexts.each do |context|
          next unless context.active?

          # Check for end patterns first (to close contexts)
          if end_match = find_end_pattern(text, pos, context)
            # Close the current context
            closed_context = context.close(end_match.begin(0))
            contexts << closed_context

            # Remove from current contexts
            current_contexts.delete(context)

            pos = end_match.end(0)
            match_found = true
            break
          end

          # Check for new nesting patterns
          if start_match = find_start_pattern(text, pos, context)
            start_pos = start_match.begin(0)
            match_end = start_match.end(0)

            # Find the rule that matched
            rule = find_matching_rule(context.language, text[start_match.begin(0)...match_end])
            next unless rule

            # Extract context data
            context_data = rule.extract_context(start_match[0])

            # Create new embedded context
            nesting_level = context.nesting_level + 1
            embedded_context = LanguageContext.new(
              rule.embedded_language,
              match_end,
              nil,
              context,
              nesting_level,
              context_data
            )

            current_contexts << embedded_context
            pos = match_end
            match_found = true
            break
          end
        end

        # If no patterns matched, advance position
        unless match_found
          pos += 1
        end
      end

      # Close any remaining open contexts at end of text
      current_contexts.each do |context|
        if context.active?
          closed_context = context.close(text.size)
          contexts << closed_context
        end
      end

      contexts
    end

    # Create a multi-language lexer for complex documents
    def create_document_lexer(base_language : String) : DocumentLexer
      DocumentLexer.new(self, base_language)
    end

    private def find_end_pattern(text : String, pos : Int32, context : LanguageContext) : Regex::MatchData?
      # Find rules that can end this context
      @nesting_rules.each do |rule|
        if rule.embedded_language == context.language
          if match = rule.end_pattern.match(text, pos)
            return match if match.begin(0) == pos
          end
        end
      end
      nil
    end

    private def find_start_pattern(text : String, pos : Int32, context : LanguageContext) : Regex::MatchData?
      # Find rules that can start new contexts from current language
      @nesting_rules.each do |rule|
        if rule.matches_parent?(context.language) && rule.can_nest?(context.nesting_level)
          if match = rule.start_pattern.match(text, pos)
            return match if match.begin(0) == pos
          end
        end
      end
      nil
    end

    private def find_matching_rule(parent_language : String, match_text : String) : LanguageNestingRule?
      @nesting_rules.find do |rule|
        rule.matches_parent?(parent_language) && rule.start_pattern.match(match_text)
      end
    end
  end

  # Multi-language document lexer
  class DocumentLexer < Lexer
    @architecture : EmbeddedLanguageArchitecture
    @base_language : String

    def initialize(@architecture : EmbeddedLanguageArchitecture, @base_language : String)
    end

    def config : LexerConfig
      LexerConfig.new(
        name: "document-#{@base_language}",
        aliases: ["doc-#{@base_language}"],
        filenames: [] of String,
        mime_types: [] of String,
        priority: 5.0f32
      )
    end

    def analyze(text : String) : Float32
      # Analyze based on base language and embedded complexity
      base_lexer = @architecture.get_lexer(@base_language)
      base_score = base_lexer.analyze(text)

      # Boost score if we detect embedded languages
      contexts = @architecture.analyze_contexts(text, @base_language)
      embedded_count = contexts.count(&.language.!= @base_language)

      # Boost score for documents with embedded languages
      boost = embedded_count > 0 ? 0.2f32 : 0.0f32
      Math.min(base_score + boost, 1.0f32)
    end

    def tokenize(text : String) : TokenIterator
      DocumentTokenIterator.new(@architecture, text, @base_language)
    end
  end

  # Token iterator for multi-language documents
  class DocumentTokenIterator
    include Iterator(Token)

    @architecture : EmbeddedLanguageArchitecture
    @text : String
    @base_language : String
    @contexts : Array(LanguageContext)
    @current_context_index : Int32
    @current_iterator : TokenIterator?
    @current_position : Int32

    def initialize(@architecture : EmbeddedLanguageArchitecture, @text : String, @base_language : String)
      @contexts = @architecture.analyze_contexts(@text, @base_language)
        .reject(&.language.== @base_language) # Don't process base language contexts separately
        .sort_by(&.start_pos)                 # Process in document order
      @current_context_index = 0
      @current_iterator = nil
      @current_position = 0
    end

    def next : Token | Iterator::Stop
      loop do
        # Get current iterator or advance to next context
        unless @current_iterator
          if @current_context_index >= @contexts.size
            # Handle any remaining text after all contexts
            if @current_position < @text.size
              remaining_content = @text[@current_position..]
              base_lexer = @architecture.get_lexer(@base_language)
              @current_iterator = base_lexer.tokenize(remaining_content)
              @current_position = @text.size
            else
              return stop
            end
          else
            advance_to_next_context
          end
          next
        end

        # Get next token from current iterator
        case token = @current_iterator.not_nil!.next
        when Token
          return token
        when Iterator::Stop
          @current_iterator = nil
          @current_context_index += 1
          next
        end
      end
    end

    private def advance_to_next_context
      return if @current_context_index >= @contexts.size

      context = @contexts[@current_context_index]

      # Handle gap between contexts (base language content)
      if context.start_pos > @current_position
        gap_content = @text[@current_position...context.start_pos]
        unless gap_content.empty?
          base_lexer = @architecture.get_lexer(@base_language)
          @current_iterator = base_lexer.tokenize(gap_content)
          @current_position = context.start_pos
          return
        end
      end

      # Handle current context content
      content = context.content(@text)
      unless content.empty?
        lexer = @architecture.get_lexer(context.language)
        @current_iterator = lexer.tokenize(content)
        @current_position = context.end_pos || @text.size
        return
      end

      # Move to next context if current one is empty
      @current_context_index += 1
      advance_to_next_context
    end
  end

  # Pre-built nesting rules for common scenarios
  module CommonNestingRules
    # HTML with embedded CSS and JavaScript
    def self.html_css_js : Array(LanguageNestingRule)
      [
        LanguageNestingRule.new(
          "html", "css",
          /<style[^>]*>/i, /<\/style>/i,
          context_extractor: ->(text : String) {
            # Extract attributes like type, media, etc.
            attrs = {} of String => String
            if match = /type\s*=\s*["']?([^"'>\s]+)/i.match(text)
              attrs["type"] = match[1]
            end
            attrs
          }
        ),
        LanguageNestingRule.new(
          "html", "javascript",
          /<script[^>]*>/i, /<\/script>/i,
          context_extractor: ->(text : String) {
            attrs = {} of String => String
            if match = /type\s*=\s*["']?([^"'>\s]+)/i.match(text)
              attrs["type"] = match[1]
            end
            if match = /src\s*=\s*["']?([^"'>\s]+)/i.match(text)
              attrs["src"] = match[1]
            end
            attrs
          }
        ),
      ]
    end

    # Markdown with code blocks
    def self.markdown_code_blocks : Array(LanguageNestingRule)
      [
        LanguageNestingRule.new(
          "markdown", "*", # Any language in code blocks
          /^```(\w+)\s*$/m, /^```\s*$/m,
          context_extractor: ->(text : String) {
            attrs = {} of String => String
            if match = /^```(\w+)/m.match(text)
              attrs["language"] = match[1]
            end
            attrs
          }
        ),
      ]
    end

    # Template languages (ERB, EJS, etc.)
    def self.template_expressions(template_lang : String, embedded_lang : String) : Array(LanguageNestingRule)
      [
        LanguageNestingRule.new(
          template_lang, embedded_lang,
          /<%=?/, /%>/,
          max_nesting_level: 3
        ),
        LanguageNestingRule.new(
          template_lang, embedded_lang,
          /\{\{/, /\}\}/,
          max_nesting_level: 3
        ),
      ]
    end

    # Vue.js single file components
    def self.vue_sfc : Array(LanguageNestingRule)
      [
        LanguageNestingRule.new(
          "vue", "html",
          /<template[^>]*>/i, /<\/template>/i
        ),
        LanguageNestingRule.new(
          "vue", "javascript",
          /<script[^>]*>/i, /<\/script>/i
        ),
        LanguageNestingRule.new(
          "vue", "css",
          /<style[^>]*>/i, /<\/style>/i
        ),
      ]
    end

    # SQL with embedded languages (stored procedures, etc.)
    def self.sql_embedded : Array(LanguageNestingRule)
      [
        LanguageNestingRule.new(
          "sql", "javascript",
          /BEGIN\s+JAVASCRIPT/i, /END\s+JAVASCRIPT/i
        ),
        LanguageNestingRule.new(
          "sql", "python",
          /\$\$PYTHON\$/i, /\$\$\/PYTHON\$/i
        ),
      ]
    end
  end
end
