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

  # State for regex-based lexers
  class LexerState
    getter stack : Array(String)
    property pos : Int32
    property text : String

    def initialize(@text : String, @pos = 0, @stack = ["root"])
    end

    def current_state : String
      @stack.last
    end

    def push_state(state : String) : Nil
      @stack << state
    end

    def pop_state : String?
      @stack.size > 1 ? @stack.pop : nil
    end

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
      LexerState.new(@text, @pos, @stack.dup)
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

    # Push a new state onto the stack
    def self.push(state : String, type : TokenType? = nil) : RuleAction
      ->(match : String, lexer_state : LexerState, groups : Array(String)) do
        lexer_state.push_state(state)
        type ? [Token.new(type, match)] : [] of Token
      end
    end

    # Pop a state from the stack
    def self.pop(type : TokenType? = nil) : RuleAction
      ->(match : String, lexer_state : LexerState, groups : Array(String)) do
        lexer_state.pop_state
        type ? [Token.new(type, match)] : [] of Token
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

    # Find the first matching rule
    def find_match(state : LexerState) : {LexerRule, Regex::MatchData}?
      current_rules = state_rules(state.current_state)
      remaining = state.remaining

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

        # Find a matching rule
        if match_data = @lexer.find_match(@state)
          rule, match = match_data
          matched_text = match[0]
          
          # Execute the rule action
          groups = match.to_a[1..].map(&.to_s)
          tokens = execute_action(rule.action, matched_text, groups)
          
          # Advance the position
          @state.advance(matched_text.size)
          
          # Queue additional tokens and return the first one
          if tokens.empty?
            # No tokens generated, try again
            next
          else
            first_token = tokens.shift
            @token_queue.concat(tokens)
            return first_token
          end
        else
          # No rule matched, emit error token for current character
          char = @state.remaining[0]
          @state.advance(1)
          return Token.new(TokenType::Error, char.to_s)
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

    def initialize(@text : String)
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
end