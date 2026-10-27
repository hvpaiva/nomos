# frozen_string_literal: true

require 'json'
require 'strscan'

module Nomos
  JSON_STRING = %r{"(?:[^"\\\x00-\x1f]|\\(?:["\\/bfnrt]|u\h{4}))*"}
  JSON_NUMBER = /-?(?:0|[1-9]\d*)(?:\.\d+)?(?:[eE][+-]?\d+)?/
  JSON_SPACE = /[ \t\n\r]*/

  # Parses one JSON text by RFC 8259 alone, refusing repeated keys, comments and invalid escapes whichever json gem
  # is loaded, so every reader of a block reads the same object; raises JSON::ParserError like JSON.parse.
  def self.strict_json(text)
    scanner = StringScanner.new(text)
    value = lambda do |depth|
      raise JSON::ParserError, 'nesting over 100' if depth > 100

      scanner.skip(JSON_SPACE)
      if scanner.skip(/\{/)
        keys = {}
        scanner.skip(JSON_SPACE)
        unless scanner.skip(/\}/)
          loop do
            scanner.skip(JSON_SPACE)
            key = scanner.scan(JSON_STRING) or raise JSON::ParserError, 'expected a key'
            name = JSON.parse("[#{key}]").first
            raise JSON::ParserError, "repeated key #{key}" if keys.key?(name)

            keys[name] = true
            scanner.skip(JSON_SPACE)
            scanner.skip(/:/) or raise JSON::ParserError, 'expected :'
            value.call(depth + 1)
            scanner.skip(JSON_SPACE)
            next if scanner.skip(/,/)
            break if scanner.skip(/\}/)

            raise JSON::ParserError, 'expected , or }'
          end
        end
      elsif scanner.skip(/\[/)
        scanner.skip(JSON_SPACE)
        unless scanner.skip(/\]/)
          loop do
            value.call(depth + 1)
            scanner.skip(JSON_SPACE)
            next if scanner.skip(/,/)
            break if scanner.skip(/\]/)

            raise JSON::ParserError, 'expected , or ]'
          end
        end
      elsif !(scanner.skip(JSON_STRING) || scanner.skip(JSON_NUMBER) || scanner.skip(/true|false|null/))
        raise JSON::ParserError, 'unexpected token'
      end
    end
    value.call(1)
    scanner.skip(JSON_SPACE)
    raise JSON::ParserError, 'text after the value' unless scanner.eos?

    JSON.parse(text)
  end
end
