# frozen_string_literal: true

module Nomos
  module PreSend
    class ToolInput
      def initialize(input)
        raise ArgumentError, 'tool_input must not be null' if input.nil?

        @strings = []
        @arrays = []
        walk(input, 0)
      end

      def occurrence?
        return false unless @strings.any? { |text| text.match?(/\bkeryx\b/i) }
        raise Command::Limit, 'tool input exceeds 64 KiB' if @strings.sum(&:bytesize) > Command::Budget::MAX_BYTES

        (@strings + @arrays.map { |array| array.grep(String).join(' ') }).any? do |text|
          remaining = 0
          text.split(/(?:\\\r?\n|[\s'"`])+/).any? do |word|
            found = remaining.positive? && word.match?(/\A(?:send|ask|reply)\b/i)
            remaining -= 1
            remaining = 4 if word.match?(/\bkeryx(?:\.exe)?\b/i)
            found
          end
        end
      end

      private

      def walk(input, depth)
        raise Command::Limit, 'tool input nesting exceeds 32 levels' if depth > Command::Budget::MAX_DEPTH

        case input
        when String
          @strings << input
        when Hash
          input.each { |key, value| walk(key, depth + 1); walk(value, depth + 1) }
        when Array
          @arrays << input
          input.each { |value| walk(value, depth + 1) }
        end
      end
    end
  end
end
