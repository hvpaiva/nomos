# frozen_string_literal: true

require 'json'
require 'open3'

module Nomos
  module PreSend
    class Recipients
      COMMAND = %w[keryx who --all -o json].freeze
      RESERVED = %w[local system].freeze

      def initialize(source: nil, command: COMMAND, timeout: 2)
        @source = source
        @command = command
        @timeout = timeout
      end

      def rows
        return @rows if defined?(@rows)

        @rows = begin
          rows = @source ? @source.call : fetch
          rows.is_a?(Array) ? rows.grep(Hash) : nil
        rescue StandardError
          nil
        end
      end

      # The address form decides as nomos check does (a person is the team segment local, or a full address with
      # no team segment); keryx who only resolves a bare member's team.
      def human?(address, sender: nil, session_id: nil)
        form = Nomos::Address.form(address)
        return form == :person unless form == :unknown

        member = address.to_s.split('/', 2).first.split('@', 2).first.to_s
        return nil if member.empty? || member.include?('.')

        team = team_of(sender) || session_team(session_id) || only(member)
        team && Nomos::Address.form("#{member}.#{team}") == :person
      end

      private

      def team_of(sender)
        team = sender.to_s.split(/[@\/]/, 2).first.to_s.split('.', 2)[1]
        team unless RESERVED.include?(team)
      end

      def session_team(session_id)
        return unless session_id.is_a?(String) && !session_id.empty?

        team_of(rows&.find { |entry| entry['join'].is_a?(Hash) && entry['join']['session_id'] == session_id }&.fetch('address', nil))
      end

      def only(member)
        teams = (rows || []).select { |entry| entry['member'] == member && entry['team'] }.map { |entry| entry['team'] }.uniq
        teams.first if teams.one?
      end

      def fetch
        deadline = Process.clock_gettime(Process::CLOCK_MONOTONIC) + @timeout
        stdin, stdout, stderr, thread = Open3.popen3(*@command, pgroup: true)
        stdin.close
        output = Thread.new { stdout.read }
        Thread.new { stderr.read }
        done = thread.join(@timeout) && output.join([deadline - Process.clock_gettime(Process::CLOCK_MONOTONIC), 0].max)
        unless done
          begin
            Process.kill('KILL', -thread.pid)
          rescue SystemCallError
            nil
          end
          return nil
        end
        return nil unless thread.value.success?

        data = JSON.parse(output.value)
        data.is_a?(Hash) && data['addresses'].is_a?(Array) ? data['addresses'] : nil
      rescue SystemCallError, IOError, JSON::ParserError
        nil
      end
    end
  end
end
