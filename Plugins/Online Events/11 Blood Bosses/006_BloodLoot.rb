#===============================================================================
# Blood boss loot (server: handlers/blood_loot.js) and the Blood Ball crafter
#
# The server rolls the loot when a blood boss or a blood god goes down and
# keeps it until this game has handed it over (so a player who was offline
# gets theirs at their next login). It's handed over on the map, when nothing
# else is going on:
#   blood bosses: one item off the boss's own list, and a chance at each Blood
#                 Ball piece (Blood Ball Top 1/5, Blood Ball Bottom 1/5, Blood Shard 1/20)
#   blood gods:   a Blood Shard, 10 Server Tokens (the server adds those), 1/100
#                 a glitch Pokémon's Egg; one player of the fight also gets a random item
# (The lists and chances are on the server: BOSS_LOOT, BALL_PARTS, GOD_*.)
#
# The crafter: an event (a workbench, an NPC...) with
#           Script: pbBloodBallCrafter
# fuses a Blood Ball Top, a Blood Ball Bottom and a Blood Shard into a Blood
# Ball, as many as the player wants and has the pieces for. True if it made any.
#===============================================================================
BLOOD_BALL_PARTS    = [:BLOODBALLTOP, :BLOODBALLBOTTOM, :BLOODSHARD]
BLOOD_LOOT_EGG_STEPS = 5120        # a glitch Egg hatches after this many steps (their own data says 99999)

module BloodLoot
  @queue = []
  @hello = false

  class << self
    def logged_in
      @hello = false
      @queue.clear
    end

    def receive(d)
      return if @queue.any? { |q| q["id"] == d["id"] }
      @queue << d
    end

    def tick
      return unless BloodMewtwo.online?
      unless @hello
        @hello = true
        NetworkClient.send_msg({ action: "blood_loot_hello" })
      end
      return if @queue.empty? || !BloodGod.free? || $game_player.moving?
      hand_over(@queue.shift)
    end

    def hand_over(d)
      sp = d["boss"].to_s.to_sym
      boss = GameData::Species.exists?(sp) ? GameData::Species.get(sp).name : d["boss"].to_s
      pbMessage(_INTL("{1} left something behind!", boss))
      (d["items"] || []).each do |item, qty|
        sym = item.to_s.to_sym
        pbReceiveItem(sym, [qty.to_i, 1].max) if GameData::Item.exists?(sym)
      end
      give_egg(d["egg"].to_s.to_sym) if d["egg"]
      give_random_item if d["random_item"]
      if d["tokens"].to_i > 0
        pbMessage(_INTL("You received {1} Server Tokens!", d["tokens"].to_i))
      end
    ensure
      NetworkClient.send_msg({ action: "blood_loot_ack", id: d["id"] })
    end

    def give_egg(species)
      return unless GameData::Species.exists?(species)
      egg = Pokemon.new(species, Settings::EGG_LEVEL)
      egg.name = _INTL("Egg")
      egg.steps_to_hatch = BLOOD_LOOT_EGG_STEPS
      egg.calc_stats
      pbMessage(_INTL("\\me[Egg get]A strange Egg was left behind, glitching in and out of sight!"))
      if $player.party_full?
        $PokemonStorage.pbStoreCaught(egg)
        pbMessage(_INTL("The Egg was sent to the PC."))
      else
        $player.party.push(egg)
      end
    end

    # any item at all, but no Key Items, HMs or TRs
    def give_random_item
      pool = []
      GameData::Item.each do |it|
        next if it.is_key_item? || it.is_HM? || (it.respond_to?(:is_TR?) && it.is_TR?)
        pool << it.id
      end
      return if pool.empty?
      pbMessage(_INTL("You were the lucky one! Something else was left behind just for you..."))
      pbReceiveItem(pool.sample)
    end
  end
end

#===============================================================================
# Event command: the Blood Ball crafter (see the top of this file)
#===============================================================================
def pbBloodBallCrafter
  have = BLOOD_BALL_PARTS.map { |p| GameData::Item.exists?(p) ? $bag.quantity(p) : 0 }.min
  if have <= 0
    pbMessage(_INTL("A Blood Ball takes a Blood Ball Top, a Blood Ball Bottom and a Blood Shard."))
    return false
  end
  qty = 1
  if have > 1
    params = ChooseNumberParams.new
    params.setRange(0, have)
    params.setDefaultValue(have)
    params.setCancelValue(0)
    qty = pbMessageChooseNumber(_INTL("How many Blood Balls will you make? (You have enough for {1}.)", have), params)
  elsif !pbConfirmMessage(_INTL("Fuse a Blood Ball Top, a Blood Ball Bottom and a Blood Shard into a Blood Ball?"))
    qty = 0
  end
  return false if qty <= 0
  BLOOD_BALL_PARTS.each { |p| $bag.remove(p, qty) }
  pbSEPlay("Battle critical catch throw") if FileTest.audio_exist?("Audio/SE/Battle critical catch throw")
  pbMessage(_INTL("The pieces fused together in a flash of red!"))
  pbReceiveItem(BLOOD_MEWTWO_BALL, qty)
  true
end

#===============================================================================
# Server messages and hooks
#===============================================================================
NetworkClient.on("blood_loot") { |d| BloodLoot.receive(d) }
NetworkClient.on("login_ok") { |_d| BloodLoot.logged_in }

EventHandlers.add(:on_frame_update, :blood_loot, proc { BloodLoot.tick })
