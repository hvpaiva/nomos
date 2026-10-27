# frozen_string_literal: true

module Nomos
  module PreSend
    ROOT = File.expand_path('../..', __dir__)
    CONFIRMATION = 'NOMOS_PRESEND_CONFIRMED'
    KINDS = { 'ask' => 'request', 'send' => 'message', 'reply' => 'reply' }.freeze
    Flag = Nomos::Flag
    Context = Data.define(:action, :recipient, :within, :human)
    Message = Data.define(:body, :action, :recipient, :within, :sender, :confirmed)

    def self.read_text(path, max_bytes: nil)
      raise IOError, "not a regular file: #{path}" unless File.file?(path)

      raise IOError, 'body file exceeds 64 KiB' if max_bytes && File.size(path) > max_bytes

      text = File.open(path, 'rb') { |file| max_bytes ? file.read(max_bytes + 1) : file.read }.force_encoding('UTF-8')
      raise IOError, 'body file exceeds 64 KiB' if max_bytes && text.bytesize > max_bytes
      raise IOError, "invalid UTF-8: #{path}" unless text.valid_encoding?

      text
    end

    def self.strict_json(text) = Nomos.strict_json(text)

    def self.vocabulary(lines) = Nomos::Vocabulary.parse(lines)

    def self.prose(body) = Nomos::Text.prose(body)
  end
end
