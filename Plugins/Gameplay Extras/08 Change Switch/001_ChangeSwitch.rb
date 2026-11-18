#===============================================================================
# pbChangeSwitch(event, map, switch): flips another event's self switch (on
# becomes off, off becomes on), e.g. pbChangeSwitch(4, 159, A) for event 4's
# self switch A on map 159. The switch can be A / B / C / D bare, or "A" / :A.
# Like pbSetSelfSwitch, the map is refreshed so the event shows its new page.
#
# Several events at once: pbChangeSwitch(4-10, 100, A) flips events 4 to 10
# (each one on its own: an on one goes off, an off one goes on). Also
# 4..10, [4, 7, 9] or "4-10".
#
# Returns the switch's new value (true = on); for several events, an array
# of them in order.
#===============================================================================
class Interpreter
  SELF_SWITCH_LETTERS = %w[A B C D]
  # "pbChangeSwitch(4-10," in an event script: Ruby would make 4-10 into -6,
  # so it's turned into 4..10 before the script runs
  CHANGE_SWITCH_DASH = /(pbChangeSwitch\(\s*)(\d+)\s*-\s*(\d+)(?=\s*,)/

  def pbChangeSwitch(events, mapid, switch_name)
    switch_name = switch_name.to_s.upcase
    unless SELF_SWITCH_LETTERS.include?(switch_name)
      raise ArgumentError, "pbChangeSwitch: self switch must be A, B, C or D (got #{switch_name})"
    end
    ids = change_switch_events(events)
    values = ids.map do |eventid|
      value = !$game_self_switches[[mapid, eventid, switch_name]]
      pbSetSelfSwitch(eventid, switch_name, value, mapid)
      value
    end
    return events.is_a?(Integer) ? values[0] : values
  end

  def change_switch_events(events)
    case events
    when Integer then [events]
    when Range, Array then events.to_a.flatten.map(&:to_i)
    when /\A\s*(\d+)\s*-\s*(\d+)\s*\z/ then ($1.to_i..$2.to_i).to_a
    when /\A\s*\d+\s*\z/ then [events.to_i]
    else raise ArgumentError, "pbChangeSwitch: events must be like 4, 4-10, 4..10 or [4, 7] (got #{events.inspect})"
    end
  end

  alias _change_switch_execute_script execute_script unless method_defined?(:_change_switch_execute_script)
  def execute_script(script)
    script = script.gsub(CHANGE_SWITCH_DASH) { "#{$1}#{$2}..#{$3}" } if script.is_a?(String) && script.include?("pbChangeSwitch")
    _change_switch_execute_script(script)
  end

  # a bare A / B / C / D in an event script is that self switch's letter
  def self.const_missing(name)
    return name.to_s if SELF_SWITCH_LETTERS.include?(name.to_s)
    super
  end
end
