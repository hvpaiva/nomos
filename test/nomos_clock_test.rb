# frozen_string_literal: true

require 'tmpdir'
require_relative 'nomos_support'

class NomosClockTest < Minitest::Test
  include NomosSupport

  def test_duration_takes_keryx_form_only
    assert_equal 5400, Nomos::Clock.duration('1h30m')
    assert_equal 90_061, Nomos::Clock.duration('1d1h1m1s')
    [nil, '', '30', '1x', '1h30', '1.5h', '-1h', '1H', ' 1h'].each { |text| assert_nil Nomos::Clock.duration(text), text.inspect }
  end

  def test_offset_reads_each_written_zone
    { 'Z' => '+00:00', 'UTC' => '+00:00', 'GMT' => '+00:00', 'UTC-03' => '-03:00', '-03' => '-03:00', '-0300' => '-03:00',
      '+05:30' => '+05:30' }.each { |zone, offset| assert_equal offset, Nomos::Clock.offset(zone), zone }
    assert_nil Nomos::Clock.offset('+25:00')
  end

  def test_written_reads_dates_clocks_and_zones
    reference = Time.utc(2026, 10, 26, 11, 0, 0)
    read = ->(text, zone = '+00:00') { Nomos::Clock.written(text, zone: zone, reference: reference).map(&:first) }
    assert_equal [reference], read.call('by 2026-10-26T11:00:00Z.')
    assert_equal [reference], read.call('26/10 08:00 (-03)')
    assert_equal [reference], read.call('26/10/2026 08h00 -0300')
    assert_equal [reference], read.call('at 08h', '-03:00')
    assert_equal [reference], read.call('26/10 klo 08h00', '-03:00')
    assert_empty read.call('from 08:00-09:00 only')
    assert_empty read.call('version 1.10:00 and path a/08:00')
    assert_empty read.call('31/02 10:00 UTC')
  end

  def test_write_and_read_back
    due = Time.utc(2026, 10, 27, 13, 0, 0)
    assert_equal '27/10 klo 10h00', Nomos::Clock.write(due, clock: '%d/%m klo %Hh%M', zone: '-03:00')
    assert Nomos::Clock.readable?('%Y-%m-%d %H:%M %:z', '+00:00')
    assert Nomos::Clock.readable?('%d/%m klo %Hh%M', '-03:00')
    refute Nomos::Clock.readable?('%B the %d', '+00:00')
  end

  def test_vocabulary_sections_and_validation
    vocabulary = words
    assert_equal ['Answer zuntil %{time}.'], vocabulary['deadline-sentence']
    assert_equal '-03:00', Nomos::Vocabulary.setting(vocabulary, 'zone')
    assert_equal '+00:00', Nomos::Vocabulary.setting({}, 'zone')
    ["[zone]\n-3\n", "[zone]\n+00:00\n-03:00\n", "[clock]\n%B\n", "[deadline-sentence]\nAnswer.\n", "[other]\nx\n",
     "[headings]\nA\n"].each do |text|
      assert_raises(Nomos::Vocabulary::Invalid, text) { Nomos::Vocabulary.parse(text.lines) }
    end
  end

  def test_installed_vocabulary_reads_a_given_path_or_falls_back
    Dir.mktmpdir('nomos-words-') do |dir|
      path = File.join(dir, 'words')
      assert_equal [], Nomos::Vocabulary.installed(path)['zone']
      File.write(path, WORDS)
      assert_equal ['-03:00'], Nomos::Vocabulary.installed(path)['zone']
      File.write(path, "[zone]\nnope\n")
      assert_raises(Nomos::Vocabulary::Invalid) { Nomos::Vocabulary.installed(path) }
    end
  end
end
