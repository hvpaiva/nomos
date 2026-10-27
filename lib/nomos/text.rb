# frozen_string_literal: true

module Nomos
  # Reading a body and the parts of it the rules look at.
  module Text
    TITLE_MAX = 80
    TITLE_BREAK = /\A\s*(?:#|`{3}|~{3}|>|[-*+]\s|\d+[.)]\s)/
    # A bracketed kind such as [accept] that opens line 1; a Markdown link opening the line is not one.
    TAG = /\A\s*\[[^\]\n]+\](?!\()/
    HUMAN_FOOTER = 'nomos v0 human message'
    # The page's pattern (inbox lib/inbox/nomos.rb FOOTER), so a footer check accepts is one the page strips.
    FOOTER = /\n*^#{HUMAN_FOOTER}[ \t]*\n?\z/

    module_function

    def read(path, max_bytes: nil)
      raise IOError, "not a regular file: #{path}" unless File.file?(path)
      raise IOError, "#{path} exceeds #{max_bytes} bytes" if max_bytes && File.size(path) > max_bytes

      text = String.new(File.open(path, 'rb') { |file| max_bytes ? file.read(max_bytes + 1) : file.read }.to_s)
      text.force_encoding(Encoding::UTF_8)
      raise IOError, "#{path} exceeds #{max_bytes} bytes" if max_bytes && text.bytesize > max_bytes
      raise IOError, "invalid UTF-8: #{path}" unless text.valid_encoding?

      text
    end

    # Why LINE is no plain title (protocol 10.7), or nil.
    def title_problem(line)
      return 'line 1, the title, is blank' if line.strip.empty?
      return "title over #{TITLE_MAX} characters (#{line.length})" if line.length > TITLE_MAX
      return 'title opens a heading, list, quote or fence' if line.match?(TITLE_BREAK)

      nil
    end

    def footer?(body) = body.match?(FOOTER)

    # BODY with fenced code, quoted lines and inline code blanked out, keeping every line break and offset.
    def prose(body)
      fence = nil
      masked = body.lines.map do |line|
        if line.match?(/^\s*>/)
          line.gsub(/[^\n]/, ' ')
        elsif fence
          closing = /^ {0,3}#{Regexp.escape(fence[0])}{#{fence[1]},}\s*$/
          fence = nil if line.match?(closing)
          line.gsub(/[^\n]/, ' ')
        elsif (match = line.match(/^ {0,3}(`{3,}|~{3,})/))
          fence = [match[1][0], match[1].length]
          line.gsub(/[^\n]/, ' ')
        else
          line
        end
      end.join
      boundary = /\A(?:\s*\z| {0,3}\#+(?:\s|\z)| {0,3}(?:=+|-+)\s*\z)/
      masked.lines.slice_when { |before, after| before.match?(boundary) || after.match?(boundary) }.map do |block|
        block.join.gsub(/(?<!`)(`+)(?!`)(.*?)(?<!`)\1(?!`)/m) { |span| span.gsub(/[^\n]/, ' ') }
      end.join
    end
  end
end
