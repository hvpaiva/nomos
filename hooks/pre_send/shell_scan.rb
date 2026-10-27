# frozen_string_literal: true

module Nomos
  module PreSend
    class Command
      class ShellScan
        attr_reader :segments, :nested, :index, :comments, :depth, :output_consumer

        def initialize(text, index: 0, closing: nil, expansions_only: false, budget: Budget.new(text), depth: 0, mapping: nil, output_consumer: false)
          budget.check(depth)
          @depth = depth
          @output_consumer = output_consumer
          @segments = [{ words: [], tokens: [], input: [], separator: nil }]
          @nested = []
          @comments = []
          @index = index
          chars = text.chars
          mapping ||= (0...chars.length).to_a
          word = +''
          offsets = []
          children = []
          literal = true
          word_start = nil
          quote = nil
          escaped = false
          target = nil
          heredocs = []
          parentheses = 0
          flush = lambda do
            if word_start
              budget.token
              token = { value: word, map: offsets, range: [mapping[word_start], mapping[@index - 1].to_i + 1],
                        literal: literal, children: children }
              if target == :input
                @segments.last[:input] << token
              elsif target == :write
                (@segments.last[:writes] ||= []) << token
              elsif target != :discard
                @segments.last[:words] << word
                @segments.last[:tokens] << token
              end
              @segments.last[:children] ||= []
              @segments.last[:children].concat(children)
              target = nil
            end
            word = +''
            offsets = []
            children = []
            literal = true
            word_start = nil
          end
          while @index < chars.length
            budget.check(depth) if (@index & 255).zero?
            char = chars[@index]
            if escaped
              unless char == "\n"
                word << char
                offsets << mapping[@index]
              end
              escaped = false
            elsif char == '\\' && quote != "'"
              escaped = true
              word_start ||= @index
            elsif closing && char == closing && !quote && parentheses.zero?
              flush.call unless expansions_only
              @index += 1
              return
            elsif quote != "'" && ((char == '$' && chars[@index + 1] == '(') || char == '`' || (!quote && %w[< >].include?(char) && chars[@index + 1] == '('))
              word_start ||= @index
              child = self.class.new(text, index: @index + (char == '`' ? 1 : 2), closing: char == '`' ? '`' : ')',
                                     budget: budget, depth: depth + 1, mapping: mapping, output_consumer: char == '>')
              @nested << child
              children << child
              literal = false
              word << '?'
              offsets << mapping[@index]
              @index = child.index
              next
            elsif expansions_only
              @index += 1
              next
            elsif quote
              if char == quote
                quote = nil
              else
                literal = false if quote == '"' && char == '$'
                word << char
                offsets << mapping[@index]
              end
            elsif ["'", '"'].include?(char)
              word_start ||= @index
              quote = char
            elsif char == '#' && !word_start
              ending = text.index("\n", @index) || chars.length
              @comments << [mapping[@index], mapping[ending - 1].to_i + 1]
              @index = ending
              next
            elsif char == '<' || char == '>' || (char == '&' && chars[@index + 1] == '>')
              if word.match?(/\A\d+\z/)
                word_start = nil
              end
              flush.call
              if (descriptor = /\G[<>]&(?:\d+|-)/.match(text, @index))
                @index = descriptor.end(0)
                next
              elsif chars[@index, 3].join == '<<<'
                target = :input
                @index += 3
                next
              elsif (header = /\G<<(-?)[ \t]*(?:'([^'\n]+)'|"([^"\n]+)"|([A-Za-z_][A-Za-z0-9_]*))(?=\s|[;&|<>)]|\z)/.match(text, @index))
                heredocs << [@segments.last, header[2] || header[3] || header[4], header[1] == '-', !header[4].nil?]
                @index = header.end(0)
                next
              end
              target = char == '<' ? :discard : :write
              if char == '&'
                @index += 1
                char = '>'
              end
              @index += 1 while chars[@index + 1] == char
            elsif char.match?(/[\s;&|()]/)
              flush.call
              unless char.match?(/[ \t\r]/)
                target = nil
                parentheses += 1 if char == '(' && closing == ')'
                parentheses -= 1 if char == ')' && parentheses.positive?
                operator = char
                if %w[& |].include?(char) && chars[@index + 1] == char
                  operator += char
                  @index += 1
                elsif char == '|' && chars[@index + 1] == '&'
                  @index += 1
                end
                @segments.last[:separator] = operator
                @segments << { words: [], tokens: [], input: [], separator: nil }
              end
              if char == "\n" && !heredocs.empty?
                @index += 1
                heredocs.each do |segment, delimiter, tabs, expand|
                  start = @index
                  ending = start
                  complete = false
                  while @index < chars.length
                    budget.check(depth)
                    ending = text.index("\n", @index) || chars.length
                    line = text[@index...ending]
                    line = line.sub(/\A\t+/, '') if tabs
                    if line == delimiter
                      complete = true
                      ending = @index
                      @index = [text.index("\n", @index).to_i + 1, chars.length].min
                      @index = chars.length if @index <= ending
                      break
                    end
                    @index = [ending + 1, chars.length].min
                  end
                  ending = chars.length unless complete
                  value = text[start...ending]
                  body = { value: value, map: mapping[start...ending], range: [mapping[start] || mapping.last.to_i + 1, mapping[ending - 1].to_i + 1],
                           literal: complete && (!expand || !value.match?(/[$`]/)), children: [] }
                  if expand
                    child = self.class.new(value, expansions_only: true, budget: budget, depth: depth + 1, mapping: body[:map])
                    body[:children] << child
                    @nested << child
                  end
                  segment[:input] << body
                end
                heredocs.clear
                next
              end
            else
              word_start ||= @index
              literal = false if char == '$'
              word << char
              offsets << mapping[@index]
            end
            @index += 1
          end
          literal = false if quote || escaped
          flush.call unless expansions_only
          @segments.last[:children] = children if expansions_only
        end
      end
    end
  end
end
