# frozen_string_literal: true

require 'date'
require 'time'

module Nomos
  # Times written in a body: the absolute times with a zone that advice compares with the clock, the deadline a
  # request's text states (protocol 10.7), and the deadline the composer writes in the human's zone and format.
  module Clock
    ZONE = /(?:Z|UTC|GMT)(?:[+-]\d{2}(?::?\d{2})?)?|[+-]\d{2}(?::?\d{2})?/
    TIME = /(?<![\w:])(?!\d{2}:\d{2}-\d{2}:\d{2})(?:(\d{4}-\d{2}-\d{2})[T ])?(\d{2}):(\d{2})(?::(\d{2})(\.\d+)?)?\s*(#{ZONE})(?![\w:+-])/
    DURATION = /\A(?:\d+[dhms])+\z/
    UNITS = { 'd' => 86_400, 'h' => 3600, 'm' => 60, 's' => 1 }.freeze
    OFFSET = /\A[+-](?:0\d|1[0-4]):[0-5]\d\z/
    WRITTEN = %r{
      (?<![\p{L}\p{N}_/:.-])
      (?!\d{1,2}:\d{2}-\d{1,2}:\d{2})
      (?:(?:(?<iso>\d{4}-\d{2}-\d{2})|(?<day>\d{1,2})/(?<month>\d{1,2})(?:/(?<year>\d{4}))?)
         (?:T|,?[ \t]+(?:\p{L}{1,6}[ \t]+)?))?
      (?<hour>\d{1,2})(?::(?<minute>\d{2})(?::(?<second>\d{2})(?:\.\d+)?)?|h(?<hminute>\d{2})?)
      (?:[ \t]*\(?(?<zone>#{ZONE})\)?)?
      (?![\p{L}\p{N}_:])
    }x

    module_function

    # Seconds in keryx's --within form, such as 30m or 1h30m, or nil.
    def duration(text)
      return nil unless text.is_a?(String) && text.match?(DURATION)

      text.scan(/(\d+)([dhms])/).sum { |amount, unit| amount.to_i * UNITS.fetch(unit) }
    end

    # A zone as written (Z, UTC, GMT, UTC-3, -03, -0300, -03:00) as an offset such as -03:00, or nil.
    def offset(zone)
      text = zone.to_s.sub(/\A(?:UTC|GMT|Z)/, '')
      text = '+00:00' if text.empty?
      text += ':00' if text.match?(/\A[+-]\d{2}\z/)
      text = "#{text[0..2]}:#{text[3..4]}" if text.match?(/\A[+-]\d{4}\z/)
      text.match?(OFFSET) ? text : nil
    end

    # The Time a TIME match names; a match without a date takes NOW's date in its zone.
    def timestamp(match, now)
      date, hour, minute, second, fraction, zone = match.captures
      zone = offset(zone) or return nil
      return nil unless hour.to_i < 24 && minute.to_i < 60 && second.to_i < 60

      date ||= now.getlocal(zone).strftime('%Y-%m-%d')
      Date.iso8601(date)
      Time.iso8601("#{date}T#{hour}:#{minute}:#{second || '00'}#{fraction}#{zone}")
    rescue ArgumentError
      nil
    end

    # Every time TEXT states as a person writes one, with its offset in TEXT. A time without a zone is read in
    # ZONE, and one without a date on REFERENCE's date in that zone.
    def written(text, zone:, reference:)
      text.to_enum(:scan, WRITTEN).filter_map do
        match = Regexp.last_match
        time = read(match, zone, reference)
        [time, match.begin(0)] if time
      end
    end

    def read(match, zone, reference)
      at = match[:zone] ? offset(match[:zone]) : zone
      return nil unless at

      local = reference.getlocal(at)
      year, month, day =
        if match[:iso] then match[:iso].split('-').map(&:to_i)
        elsif match[:day] then [(match[:year] || local.year).to_i, match[:month].to_i, match[:day].to_i]
        else [local.year, local.month, local.day]
        end
      hour = match[:hour].to_i
      minute = (match[:minute] || match[:hminute]).to_i
      second = match[:second].to_i
      return nil unless hour < 24 && minute < 60 && second < 60 && Date.valid_date?(year, month, day)

      Time.new(year, month, day, hour, minute, second, at)
    end

    # TIME written in ZONE with CLOCK, a strftime format.
    def write(time, clock:, zone:) = time.getlocal(zone).strftime(clock)

    # Whether what CLOCK writes reads back as the same minute, so a deadline the composer writes is one the check
    # finds.
    def readable?(clock, zone)
      sample = Time.utc(2026, 1, 2, 3, 4, 0)
      written(write(sample, clock: clock, zone: zone), zone: zone, reference: sample).any? { |time, _| time == sample }
    end
  end
end
