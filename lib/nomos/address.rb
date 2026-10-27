# frozen_string_literal: true

module Nomos
  # A transport address, MEMBER.TEAM@HOST/SESSION (protocol 3). Whether it names a person is read from its form
  # alone: the team segment local, or a full address with no team segment, such as an older MEMBER@HOST.
  module Address
    FORM = %r{\A(?<member>[^.@/\s]+)(?:\.(?<team>[^@/\s]+))?(?:@(?<host>[^/\s]+))?(?:/(?<session>\S+))?\z}
    PERSON_TEAM = 'local'

    module_function

    def parse(address) = FORM.match(address.to_s)

    def team(address) = parse(address)&.[](:team)

    # :person, :agent, or :unknown for a bare member or a string that is no address.
    def form(address)
      match = parse(address) or return :unknown
      return :person if match[:team] == PERSON_TEAM
      return :agent if match[:team]

      match[:host] ? :person : :unknown
    end

    def person?(address) = form(address) == :person
  end
end
