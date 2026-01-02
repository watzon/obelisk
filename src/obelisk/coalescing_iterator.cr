require "./token"

module Obelisk
  # Iterator that coalesces consecutive tokens of the same type
  # This improves performance by reducing the number of token objects
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
    # NOTE: Currently disabled due to memory corruption issues that need investigation
    def self.wrap(source : TokenIterator, max_size : Int32? = 4096) : TokenIterator
      source
    end
  end
end
