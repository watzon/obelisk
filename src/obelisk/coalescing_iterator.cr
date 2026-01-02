require "./token"

module Obelisk
  # Iterator that coalesces consecutive tokens of the same type
  # This improves performance by reducing the number of token objects
  #
  # NOTE: This iterator is currently DISABLED due to a Crystal compiler bug.
  # When SafeTokenIteratorAdapter instances created via lexer.tokenize() on
  # lexers stored in the Registry Hash are wrapped in CoalescingIterator,
  # calling next() causes an EXC_BREAKPOINT crash.
  #
  # The bug only occurs when:
  # 1. Lexer is stored in a Hash (like the Registry)
  # 2. SafeTokenIteratorAdapter is created via lexer.tokenize() method
  # 3. The iterator is wrapped in another iterator (like CoalescingIterator)
  # 4. next() is called on the wrapper
  #
  # Workaround: Use SafeTokenIteratorAdapter directly (already done by default)
  #
  # TODO: File bug report with Crystal team and re-enable when fixed
  class CoalescingIterator
    include Iterator(Token)

    @peeked_token : Token?
    @peeked_is_stop : Bool
    @done : Bool

    def initialize(@source : TokenIterator, @max_size : Int32? = nil)
      @peeked_token = nil
      @peeked_is_stop = false
      @done = false
    end

    def next : Token | Iterator::Stop
      return stop if @done

      # If we have a saved token, return it
      if token = @peeked_token
        @peeked_token = nil
        @peeked_is_stop = false
        return token
      end

      if @peeked_is_stop
        @peeked_is_stop = false
        return stop
      end

      # Get the first token
      first_token = @source.next
      if first_token.is_a?(Iterator::Stop)
        @done = true
        return stop
      end

      # Start building the coalesced value
      current_type = first_token.type
      current_value = first_token.value
      current_size = current_value.size

      # Look ahead to coalesce more tokens of the same type
      loop do
        peek_result = @source.next

        if peek_result.is_a?(Iterator::Stop)
          @done = true
          break
        end

        peek_token = peek_result.as(Token)

        if peek_token.type == current_type
          new_size = current_size + peek_token.value.size
          max_size = @max_size
          if !max_size || new_size <= max_size
            # Coalesce: append the value
            current_value += peek_token.value
            current_size = new_size
          else
            # Size limit hit - save for next iteration
            @peeked_token = peek_token
            break
          end
        else
          # Different type - save for next iteration
          @peeked_token = peek_token
          break
        end
      end

      Token.new(current_type, current_value)
    end

    # Static helper to wrap any iterator with coalescing
    # Default max_size of 4KB prevents unbounded growth while still
    # providing significant performance benefits for typical code
    #
    # NOTE: Currently disabled (returns source unchanged) due to Crystal compiler bug
    def self.wrap(source : TokenIterator, max_size : Int32? = 4096) : TokenIterator
      source  # Disabled - returns source unchanged
    end
  end
end
