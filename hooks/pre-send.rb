#!/usr/bin/env ruby
# frozen_string_literal: true

require 'date'
require 'json'
require 'open3'
require 'optparse'
require 'shellwords'
require 'strscan'
require 'time'
require 'uri'

module Nomos
  module PreSend
    CURSOR_PASS = { permission: 'allow' }.freeze

    def self.warning(message, harness:, output:, error:, check: false)
      text = "NOMOS pre-send warning: #{message}; #{check ? 'check incomplete' : 'command passed unchecked'}."
      text += ' Run --check on the resolved body file.' unless check
      begin
        error.puts text
      rescue IOError, SystemCallError
        nil
      end
      begin
        if !check && harness == 'cursor'
          output.puts JSON.generate(CURSOR_PASS.merge(agent_message: text, user_message: text))
        elsif !check && %w[claude codex].include?(harness)
          output.puts JSON.generate(hookSpecificOutput: { hookEventName: 'PreToolUse', additionalContext: text })
        end
      rescue IOError, SystemCallError
        nil
      end
      check ? 2 : 0
    end

    major, minor = RUBY_VERSION.split('.').map(&:to_i)
    if major < 3 || (major == 3 && minor < 2)
      harness_arg = ARGV.find { |arg| arg.start_with?('--harness=') }
      harness_index = ARGV.index('--harness')
      harness = harness_arg ? harness_arg.split('=', 2).last : (harness_index && ARGV[harness_index + 1])
      check = ARGV.any? { |arg| arg == '--check' || arg.start_with?('--check=') }
      exit warning("Ruby 3.2 or later is required (running #{RUBY_VERSION})",
                   harness: harness, output: $stdout, error: $stderr, check: check)
    end

    require_relative '../lib/nomos/rules'
    require_relative '../lib/nomos/vocabulary'
    require_relative 'pre_send/support'
    require_relative 'pre_send/checker'
    require_relative 'pre_send/recipients'
    require_relative 'pre_send/command'
    require_relative 'pre_send/shell_scan'
    require_relative 'pre_send/reader'
    require_relative 'pre_send/accounting'
    require_relative 'pre_send/tool_input'
    require_relative 'pre_send/runner'
  end
end

exit Nomos::PreSend::Runner.new.run(ARGV) if $PROGRAM_NAME == __FILE__
