# frozen_string_literal: true

require 'json'
require 'optparse'
require 'time'

module Nomos
  module PreSend
    class Runner
      def initialize(input: $stdin, output: $stdout, error: $stderr, directory: nil)
        @input = input
        @output = output
        @error = error
        @directory = directory
      end

      def run(argv)
        @harness = nil
        contract = true
        words_paths = []
        check = nil
        manual = {}
        parser = OptionParser.new do |options|
          options.banner = 'Usage: pre-send.rb (--harness claude|codex|cursor | --check FILE [--action send|ask|reply] ' \
                           '[--to ADDRESS] [--within DURATION] [--now TIME] [--who FILE]) [--words FILE]'
          options.on('--harness NAME') do |name|
            @harness = nil
            raise ArgumentError, 'unknown --harness' unless %w[claude codex cursor].include?(name)

            @harness = name
          end
          options.on('--check FILE') { |path| check = path }
          options.on('--words FILE') { |path| words_paths << path }
          options.on('--action ACTION') do |action|
            raise ArgumentError, 'unknown --action' unless %w[send ask reply].include?(action)

            manual[:action] = action
          end
          options.on('--to ADDRESS') { |address| manual[:to] = address }
          options.on('--within DURATION') do |duration|
            manual[:within] = Nomos::Clock.duration(duration) or raise ArgumentError, "invalid --within #{duration}"
          end
          options.on('--now TIME') { |time| manual[:now] = Time.iso8601(time) }
          options.on('--who FILE') { |path| manual[:who] = path }
          options.on('-h', '--help') { @output.puts options; return 0 }
        end
        parser.parse!(argv)
        raise ArgumentError, parser.banner unless argv.empty? && (!!check ^ !!@harness) && (check || manual.empty?)

        vocabulary = PreSend.vocabulary(words_paths.flat_map { |path| PreSend.read_text(path).lines })
        checker = Checker.new(now: manual[:now] || Time.now, vocabulary: vocabulary)
        if check
          rows = manual[:who] && JSON.parse(PreSend.read_text(manual[:who])).fetch('addresses')
          human = manual[:to] && Recipients.new(source: -> { rows }).human?(manual[:to])
          context = Context.new(action: manual[:action] || 'reply', recipient: manual[:to], within: manual[:within], human: human)
          flags = checker.check(PreSend.read_text(check, max_bytes: Command::Budget::MAX_BYTES), context)
          flag_lines(flags).each { |line| @output.puts line }
          return flags.empty? ? 0 : 1
        end
        data = JSON.parse(@input.read)
        raise ArgumentError, 'hook input must be an object' unless data.is_a?(Hash)

        if @harness == 'cursor'
          return pass if data['hook_event_name'] && data['hook_event_name'] != 'beforeShellExecution'

          command = data.fetch('command')
        else
          return pass if data['hook_event_name'] && data['hook_event_name'] != 'PreToolUse'

          known = @harness == 'claude' ? %w[Bash Monitor] : %w[Bash]
          tool_input = data.fetch('tool_input')
          command = tool_input['command'] if tool_input.is_a?(Hash)
          if (data['tool_name'] && !known.include?(data['tool_name'])) || !command.is_a?(String)
            input = ToolInput.new(tool_input)
            contract = false
            return pass unless input.occurrence?

            return PreSend.warning('tool input is not supported POSIX shell', harness: @harness, output: @output, error: @error)
          end
        end
        raise ArgumentError, 'command must be a string' unless command.is_a?(String)
        contract = false
        raise Command::Limit, 'command exceeds 64 KiB' if command.bytesize > Command::Budget::MAX_BYTES

        occurrences = Command.occurrences(command)
        return pass if occurrences.empty?

        budget = Command::Budget.new(command)
        accounting = Command::Accounting.new(command, budget: budget)
        parsed = Command.new(command, cwd: data.fetch('cwd', Dir.pwd), budget: budget, accounting: accounting)
        parse_error = nil
        begin
          bodies = parsed.bodies
        rescue ArgumentError, IOError => error
          parse_error = error.message
        end
        checked = parse_error ? [] : parsed.checked_ranges
        if accounting.unresolved?(occurrences, checked: checked)
          return PreSend.warning(parse_error || 'unaccounted keryx send, ask or reply occurrence',
                                 harness: @harness, output: @output, error: @error)
        end
        recipients = Recipients.new(source: @directory)
        flags = bodies ? parsed.messages.flat_map { |message| message_flags(checker, message, recipients, data) } : []
        return pass if flags.empty?

        musts = flags.select(&:must?).map(&:kind).uniq
        reason = "NOMOS pre-send found:\n#{flag_lines(flags).join("\n")}\n" +
                 if musts.empty?
                   "Check these flags. To confirm, resend the same command prefixed with #{CONFIRMATION}=1."
                 else
                   "These flags break a MUST of the protocol and no confirmation passes them: #{musts.join(', ')}. " \
                     "Correct the body; #{CONFIRMATION}=1 confirms only the other flags."
                 end
        if @harness == 'cursor'
          @output.puts JSON.generate(permission: 'deny', user_message: reason, agent_message: reason)
        else
          @output.puts JSON.generate(hookSpecificOutput: {
            hookEventName: 'PreToolUse', permissionDecision: 'deny', permissionDecisionReason: reason
          })
        end
        0
      rescue Exception => error
        raise if error.is_a?(SystemExit) || error.is_a?(SignalException)

        message = contract && !check ? "Repair the pre-send hook or its wiring and tell the human: #{error.message}" : error.message
        PreSend.warning(message, harness: @harness, output: @output, error: @error, check: !!check)
      end

      private

      def context(message, recipients, data)
        human = message.recipient && recipients.human?(message.recipient, sender: message.sender || ENV['KERYX_AS'], session_id: data['session_id'])
        Context.new(action: message.action, recipient: message.recipient, within: message.within, human: human)
      end

      def message_flags(checker, message, recipients, data)
        flags = checker.check(message.body, context(message, recipients, data))
        message.confirmed ? flags.select(&:must?) : flags
      end

      def flag_lines(flags)
        lines = flags.first(50).map(&:to_s)
        lines << "#{flags.length - 50} more flags omitted." if flags.length > 50
        lines
      end

      def pass
        @output.puts JSON.generate(CURSOR_PASS) if @harness == 'cursor'
        0
      end
    end
  end
end
