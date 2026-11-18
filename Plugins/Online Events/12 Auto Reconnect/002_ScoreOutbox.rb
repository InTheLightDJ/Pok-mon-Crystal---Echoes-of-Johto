#===============================================================================
# Score Outbox - a score made while the connection is down still counts.
# By InTheLight
# The tunnel drops the connection now and then, and a minigame that ends during
# a drop used to throw its score away (every score report only goes out while
# logged in). Now, while Auto Reconnect is still trying to get back, the score
# waits here and goes out as soon as the game is logged in again.
# Covers: Tower Defense, Bug-Catching Contest, Lake Fishing. Kept until the
# next login if Auto Reconnect gives up (the PC reconnect counts too); lost
# only if the game is closed before that.
# Pinball (GBC + RS) and the Rhythm Game go further: their scores are kept
# until the server says it has them (ScoreReceipts below).
#===============================================================================
module AutoReconnect
  class << self
    # dropped, and the game will log back in by itself
    def waiting?
      !@online_as.nil? && !deliberate? && !NetworkAuth.logged_in?
    end
  end
end

module ScoreOutbox
  @queue = []

  class << self
    def pending?; !@queue.empty?; end

    # true if the message was held for later
    def hold?(msg)
      return false if NetworkAuth.logged_in? || !AutoReconnect.waiting?
      @queue << msg
      puts "[ScoreOutbox] offline, holding #{msg[:action]}"
      true
    end

    def flush
      return if @queue.empty? || !NetworkAuth.logged_in?
      puts "[ScoreOutbox] sending #{@queue.size} held score(s)"
      @queue.each { |m| NetworkClient.send_msg(m) }
      @queue.clear
    end
  end
end

EventHandlers.add(:on_frame_update, :score_outbox, proc { ScoreOutbox.flush })

#-------------------------------------------------------------------------------
# Score Receipts - a result is kept (and saved to a file in the save folder)
# until the server says it has it (<action>_ok { id }). A tunnel drop can
# swallow a message without the game noticing, so a result with no answer
# after RESEND_AFTER seconds goes out again, and every one goes out again after
# a reconnect. The server counts each result id once. Offline results wait for
# the next login (also after closing the game). The Rhythm Game has its own
# copy of this (Plugins/Rhythm Game/005_Online.rb).
#-------------------------------------------------------------------------------
class ScoreReceipts
  RESEND_AFTER = 20      # seconds without an answer
  SLOW_AFTER   = 10      # sends; after that, only every SLOW_RESEND seconds
  SLOW_RESEND  = 300     # (never dropped: a server that doesn't answer may be an old one, updated later)

  def initialize(file, ok_event)
    @file = file
    @list = nil
    NetworkClient.on(ok_event) { |d| received(d["id"].to_s) }
    EventHandlers.add(:on_frame_update, :"receipts_#{file}", proc { send_pending rescue nil })
  end

  def path = File.join((RTP.getSaveFolder rescue nil) || ".", @file)

  # [{ msg:, sends:, sent_at:, conn: }]
  def list
    return @list if @list
    @list = (File.exist?(path) ? Marshal.load(File.binread(path)) : []) rescue []
    @list = [] unless @list.is_a?(Array)
    @list.each { |p| p[:conn] = nil }
    @list
  end

  def save
    if list.empty?
      File.delete(path) if File.exist?(path)
    else
      File.binwrite(path, Marshal.dump(list.map { |p| { msg: p[:msg], sends: p[:sends] } }))
    end
  rescue StandardError => e
    puts "[ScoreReceipts] couldn't save #{@file}: #{e.message}"
  end

  def add(msg)
    msg = msg.merge(id: "#{Time.now.to_i.to_s(36)}#{rand(36**6).to_s(36)}")
    list << { msg: msg, sends: 0, sent_at: nil, conn: nil }
    save
    send_pending
  end

  def send_pending
    return if list.empty? || !NetworkAuth.logged_in?
    conn = NetworkClient.instance_variable_get(:@socket)&.object_id
    now = System.unscaled_uptime
    changed = false
    list.delete_if do |p|
      wait = p[:sends] >= SLOW_AFTER ? SLOW_RESEND : RESEND_AFTER
      next false if p[:conn] == conn && p[:sent_at] && now - p[:sent_at] < wait
      NetworkClient.send_msg(p[:msg])
      p[:sends] += 1
      p[:sent_at] = now
      p[:conn] = conn
      changed = true
      false
    end
    save if changed
  end

  def received(id)
    before = list.length
    list.reject! { |p| p[:msg][:id] == id }
    save if list.length != before
  end
end

#-------------------------------------------------------------------------------
# Pinball (both): every score goes through the receipts (the server answers
# pinball_result_ok), online or not
#-------------------------------------------------------------------------------
PINBALL_RECEIPTS = ScoreReceipts.new("PinballPending.dat", "pinball_result_ok")

[[:PinballGBC, "gbc"], [:PinballRS, "rs"]].each do |mod, game|
  next unless Object.const_defined?(mod)
  Object.const_get(mod).singleton_class.class_eval do
    define_method(:report_score) do |score, field|
      return if score <= 0
      PINBALL_RECEIPTS.add({ action: "pinball_result", game: game, field: field, score: score })
    rescue StandardError => e
      puts "[Pinball] report_score: #{e.message}"
    end
  end
end

#-------------------------------------------------------------------------------
# Rhythm Game
#-------------------------------------------------------------------------------
# Not here any more: the Rhythm Game keeps its own results until the server
# answers that it has them (Plugins/Rhythm Game/005_Online.rb, RhythmGame.pending),
# which also covers a drop the game hasn't noticed yet.

#-------------------------------------------------------------------------------
# Tower Defense (the server remembers td_start by player name, so a result
# from after the reconnect still matches the game that was started)
#-------------------------------------------------------------------------------
if defined?(TowerDefense)
  class << TowerDefense
    alias _outbox_net_send net_send unless method_defined?(:_outbox_net_send)
    def net_send(msg)
      return if msg[:action] == "td_result" && !online? && ScoreOutbox.hold?(msg)
      _outbox_net_send(msg)
    end
  end
end

#-------------------------------------------------------------------------------
# Bug-Catching Contest (same rule as 023_Networking/021: only a 1st place)
#-------------------------------------------------------------------------------
class BugContestState
  alias _outbox_pbEnd pbEnd unless method_defined?(:_outbox_pbEnd)
  def pbEnd(interrupted = false)
    won_first = !interrupted && @places && @places.any? && place == 0
    score     = won_first ? @places[0][2] : nil
    offline   = !NetworkAuth.logged_in?
    _outbox_pbEnd(interrupted)
    if won_first && score && offline
      ScoreOutbox.hold?({ action: "bug_contest_score", score: score, display_name: $player.name })
    end
  end
end

#-------------------------------------------------------------------------------
# Lake Fishing
#-------------------------------------------------------------------------------
if defined?(LakeFishingMinigame)
  class << LakeFishingMinigame
    alias _outbox_finish _finish unless method_defined?(:_outbox_finish)
    def _finish(result)
      if !NetworkAuth.logged_in? && AutoReconnect.waiting?
        if result[:catches] && result[:catches].any?
          ScoreOutbox.hold?({ action: "lake_fishing_catches", catches: result[:catches] })
        end
        ScoreOutbox.hold?({ action: "lake_fishing_score", score: result[:weight], display_name: $player.name })
      end
      _outbox_finish(result)
    end
  end
end
