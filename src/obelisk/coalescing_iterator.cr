require "./token"

module Obelisk
  # Iterator that coalesces consecutive tokens of the same type
  # This improves performance by reducing the number of token objects
  class CoalescingIterator
    include Iterator(Token)

    @buffer : Array(Token)
    @next_buffer : Token?
    @done : Bool

    def initialize(@source : TokenIterator, @max_size : Int32? = nil)
      @buffer = [] of Token
      @next_buffer = nil
      @done = false
    end

    def next : Token | Iterator::Stop
      return stop if @done

      # Fill buffer with first token if empty
      if @buffer.empty?
        first_token = @source.next
        return stop if first_token.is_a?(Iterator::Stop)
        @buffer << first_token
      end

      # Keep collecting tokens while they have the same type
      current_type = @buffer.first.type
      current_size = @buffer.first.value.size
      
      loop do
        next_token = @source.next
        
        if next_token.is_a?(Iterator::Stop)
          @done = true
          break
        end

        # If types match and we haven't hit size limit, keep collecting
        max_size = @max_size
        if next_token.type == current_type
          new_size = current_size + next_token.value.size
          if !max_size || new_size <= max_size
            @buffer << next_token
            current_size = new_size
          else
            # Size limit hit - save for next iteration
            @next_buffer = next_token
            break
          end
        else
          # Different type - save for next iteration
          @next_buffer = next_token
          break
        end
      end

      # Coalesce all tokens in buffer
      if @buffer.size == 1
        token = @buffer.shift
        # Add next_buffer to buffer for next iteration if present
        if nb = @next_buffer
          @buffer << nb
          @next_buffer = nil
        end
        return token
      else
        coalesced_value = String.build do |str|
          @buffer.each { |t| str << t.value }
        end
        @buffer.clear
        # Add next_buffer to buffer for next iteration if present
        if nb = @next_buffer
          @buffer << nb
          @next_buffer = nil
        end
        Token.new(current_type, coalesced_value)
      end
    end

    # Static helper to wrap any iterator with coalescing
    def self.wrap(source : TokenIterator, max_size : Int32? = nil) : TokenIterator
      CoalescingIterator.new(source, max_size)
    end
  end
end