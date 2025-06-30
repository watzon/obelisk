require "./token"

module Obelisk
  # Iterator that coalesces consecutive tokens of the same type
  # This improves performance by reducing the number of token objects
  class CoalescingIterator
    include Iterator(Token)

    @buffer : Deque(Token)
    @next_buffer : Token?
    @done : Bool

    def initialize(@source : TokenIterator, @max_size : Int32? = nil)
      @buffer = Deque(Token).new
      @next_buffer = nil
      @done = false
    end

    def next : Token | Iterator::Stop
      return stop if @done

      begin
        # Fill buffer with first token if empty
        if @buffer.empty?
          # Use next_buffer if available, otherwise get from source
          if nb = @next_buffer
            @buffer << nb
            @next_buffer = nil
          else
            first_token = @source.next
            return stop if first_token.is_a?(Iterator::Stop)
            @buffer << first_token
          end
        end

        # Safety check
        if @buffer.empty?
          @done = true
          return stop
        end

        # Keep collecting tokens while they have the same type
        current_type = @buffer.first.type
        current_size = @buffer.sum(&.value.size)
        
        loop do
          # Check if we have a next_buffer token
          next_token = if nb = @next_buffer
            @next_buffer = nil
            nb
          else
            source_token = @source.next
            if source_token.is_a?(Iterator::Stop)
              @done = true
              break
            else
              source_token
            end
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
          return @buffer.shift
        else
          coalesced_value = String.build do |str|
            @buffer.each { |t| str << t.value }
          end
          @buffer.clear
          Token.new(current_type, coalesced_value)
        end
      rescue
        # If any error occurs, mark as done and return stop
        @done = true
        stop
      end
    end

    # Static helper to wrap any iterator with coalescing
    def self.wrap(source : TokenIterator, max_size : Int32? = nil) : TokenIterator
      # Temporarily disable coalescing to avoid memory issues
      source
    end
  end
end