# frozen_string_literal: true

require 'json'
require 'time'
require_relative 'flag'
require_relative 'rules'

module Nomos
  # The object keryx writes on the checker's stdin before it writes a message (envelope version 1): check, event
  # (send or receive), host, command (null on receive) and message, as keryx would store it.
  class Envelope
    class Invalid < StandardError; end

    VERSION = 1
    EVENTS = %w[send receive].freeze
    KINDS = %w[message request reply withdrawal].freeze
    MAX_BYTES = 1024 * 1024

    attr_reader :event, :host, :command, :message

    def self.read(io)
      io.binmode
      text = String.new(io.read(MAX_BYTES + 1).to_s)
      raise Invalid, 'the envelope is empty' if text.strip.empty?
      raise Invalid, "the envelope exceeds #{MAX_BYTES} bytes" if text.bytesize > MAX_BYTES

      text.force_encoding(Encoding::UTF_8)
      raise Invalid, 'the envelope is not UTF-8' unless text.valid_encoding?

      data = begin
        JSON.parse(text)
      rescue JSON::ParserError => e
        raise Invalid, "the envelope is not JSON: #{e.message.lines.first.to_s.strip[0, 120]}"
      end
      new(data)
    end

    def initialize(data)
      raise Invalid, 'the envelope is not a JSON object' unless data.is_a?(Hash)
      raise Invalid, "unknown envelope version #{echo(data['check'])}" unless data['check'] == VERSION

      @event = data['event']
      raise Invalid, "unknown event #{echo(@event)}" unless EVENTS.include?(@event)

      @host = data['host']
      @command = data['command']
      raise Invalid, 'command is a string or null' unless @command.nil? || @command.is_a?(String)

      @message = data['message']
      raise Invalid, 'message is not an object' unless @message.is_a?(Hash)

      validate_message
    end

    def to_message
      due = @message['due_at'] && Time.iso8601(@message['due_at'])
      Message.new(body: @message['body'], kind: @message['kind'], from: @message['from'], to: @message['to'],
                  due: due, human: Rules.human?(@message['to']))
    end

    private

    def echo(value) = value.inspect[0, 60]

    def validate_message
      raise Invalid, "unknown message kind #{echo(@message['kind'])}" unless KINDS.include?(@message['kind'])

      %w[from to body].each do |key|
        raise Invalid, "message #{key} is not a string" unless @message[key].is_a?(String)
      end
      raise Invalid, 'message body is not UTF-8' unless @message['body'].valid_encoding?

      due = @message['due_at']
      return if due.nil?

      raise Invalid, 'message due_at is not an ISO 8601 time' unless due.is_a?(String)

      Time.iso8601(due)
    rescue ArgumentError
      raise Invalid, 'message due_at is not an ISO 8601 time'
    end
  end
end
