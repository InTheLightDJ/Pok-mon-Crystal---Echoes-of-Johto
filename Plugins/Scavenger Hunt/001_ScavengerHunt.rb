#===============================================================================
# Shadow Pokémon Scavenger Hunt
# (server: handlers/scavenger_hunt.js, which picks where everything hides)
#
# The hunt NPC's event:   Script: pbScavengerHunt
# Starts a hunt for everyone online. Each Shadow Pokémon hides in one secret
# location; a wild encounter there has a 1 in 10 chance to be it (overworld
# spawns and grass/cave/water encounters alike). It can't be caught: running
# into it finds it for everyone. A box on the map shows how many are left and
# the time left. All found: confetti for everyone online, and the server
# makes the next Mythical / legendary shiny and hands out the prizes.
# All found also brings out the hunt's boss, Shadow Lugia or on a holiday one
# of that holiday's Pokémon: a race to catch it (002_ShadowLugia.rb). A
# holiday one keeps its holiday look for good.
#
# Their pictures (without a back picture, the back is the normal one):
#   Graphics/Pokemon/<SPECIES> SHADOW.png
#   Graphics/Pokemon/<SPECIES> HALLOWEEN.png (THANKSGIVING, EASTER, CHRISTMAS)
#   Graphics/Pokemon/<SPECIES> HALLOWEENb.png ... (its back)
#===============================================================================
module ScavengerHunt
  @hunt     = nil   # { total:, found:, ends:, chance:, targets: { SPECIES => [map ids] } }
  @pending  = nil   # [species, look] of the encounter just turned into one
  @asked    = false # the status was asked for this login
  @messages = []    # shown once the player is free on the map
  @confetti = nil   # :winner / :everyone once the hunt is complete
  @start_result = nil

  # a holiday look => a Pokémon's name with it (_INTL(HOLIDAY_NAMES[...], name))
  HOLIDAY_NAMES = { HALLOWEEN: "Halloween {1}", THANKSGIVING: "Thanksgiving {1}",
                    EASTER: "Easter {1}", CHRISTMAS: "Christmas {1}" }

  class << self
    attr_accessor :hunt, :pending, :asked, :confetti, :start_result
    attr_reader :messages

    def online?
      defined?(NetworkAuth) && NetworkAuth.logged_in? && NetworkClient.connected?
    end

    def seconds_left(h)
      [(h[:ends] - System.uptime).ceil, 0].max
    end

    def time_text(secs)
      format("%d:%02d:%02d", secs / 3600, secs / 60 % 60, secs % 60)
    end

    def species_name(id)
      GameData::Species.try_get(id)&.name || id.to_s
    end

    # [species, look] to turn an encounter on this map into, or nil
    def spawn_for(map_id)
      if @hunt && seconds_left(@hunt) > 0
        @hunt[:targets].each do |species, maps|
          return [species, "SHADOW"] if maps.include?(map_id) && rand(@hunt[:chance]) == 0
        end
      end
      nil
    end

    # a wild battle with these foes starts
    def battle_started(foes)
      foes.each do |pkmn|
        next unless pkmn.respond_to?(:event_look) && pkmn.event_look == "SHADOW"
        next unless @hunt&.dig(:targets, pkmn.species)
        @hunt[:targets].delete(pkmn.species)   # found: no more of it here
        NetworkClient.send_msg({ action: "scavenger_found", species: pkmn.species.to_s,
                                 map_id: $game_map.map_id }) if online?
        @messages << _INTL("You found Shadow {1} for the Scavenger Hunt!", species_name(pkmn.species))
      end
    end

    # "Christmas Sudowoodo" for a holiday look, else the species' name
    def look_name(species, look)
      return species_name(species) unless look && HOLIDAY_NAMES[look.to_sym]
      _INTL(HOLIDAY_NAMES[look.to_sym], species_name(species))
    end

    # the picture for a Shadow / holiday Pokémon (<SPECIES> <LOOK>, its back
    # <SPECIES> <LOOK>b), or nil for the normal one
    def graphic(pkmn, back)
      return nil if !pkmn.respond_to?(:event_look) || !pkmn.event_look || pkmn.egg?
      pbResolveBitmap("Graphics/Pokemon/#{GameData::Species.get(pkmn.species).species} #{pkmn.event_look}#{back ? 'b' : ''}")
    end
  end
end

class Pokemon
  attr_accessor :event_look   # "SHADOW", "CHRISTMAS"...: its picture
end

#-------------------------------------------------------------------------------
# Server messages
#-------------------------------------------------------------------------------
NetworkClient.on("scavenger_state") do |d|
  if d["active"]
    targets = {}
    (d["targets"] || []).each { |t| targets[t["species"].to_sym] = t["maps"].map(&:to_i) }
    ScavengerHunt.hunt = { total: d["total"].to_i, found: d["found"].to_i, chance: [d["chance"].to_i, 1].max,
                           ends: System.uptime + d["seconds_left"].to_i, targets: targets }
  else
    ScavengerHunt.hunt = nil
  end
end

NetworkClient.on("scavenger_complete") do |d|
  me = NetworkAuth.username.to_s.downcase
  ScavengerHunt.confetti = (d["winners"] || []).any? { |u| u.to_s.downcase == me } ? :winner : :everyone
end

NetworkClient.on("scavenger_failed") do |d|
  ScavengerHunt.messages << _INTL("The Scavenger Hunt is over... {1} Shadow Pokémon were never found.", d["left"].to_i)
end

NetworkClient.on("scavenger_start_result") { |d| ScavengerHunt.start_result = d }

#-------------------------------------------------------------------------------
# Wild encounters
#-------------------------------------------------------------------------------
EventHandlers.add(:on_wild_species_chosen, :scavenger_hunt,
  proc { |encounter|
    ScavengerHunt.pending = nil   # a blocked encounter (Repel...) doesn't carry over
    next unless encounter.is_a?(Array) && $game_map
    next if $PokemonGlobal.roamEncounter || pbInBugContest? || pbInSafari?
    pick = ScavengerHunt.spawn_for($game_map.map_id)
    next unless pick
    encounter[0] = pick[0]
    ScavengerHunt.pending = pick
  }
)

EventHandlers.add(:on_wild_pokemon_created, :scavenger_hunt,
  proc { |pkmn|
    species, look = ScavengerHunt.pending
    next unless species && pkmn.species == species
    pkmn.event_look = look
    pkmn.name = _INTL("Shadow {1}", pkmn.speciesName) if look == "SHADOW"
    ScavengerHunt.pending = nil
  }
)

# Shadow Pokémon can't be caught; meeting one finds it
module ScavengerHuntBattle
  def initialize(scene, p1, p2, player, opponent)
    super
    return if opponent
    foes = Array(p2).compact
    @disablePokeBalls = true if foes.any? { |p| p.respond_to?(:event_look) && p.event_look == "SHADOW" }
    ScavengerHunt.battle_started(foes)
  end
end
Battle.prepend(ScavengerHuntBattle)

module GameData
  class Species
    class << self
      alias scavenger_sprite_bitmap_from_pokemon sprite_bitmap_from_pokemon
      def sprite_bitmap_from_pokemon(pkmn, back = false, species = nil)
        file = !species && ScavengerHunt.graphic(pkmn, back)
        return AnimatedBitmap.new(file) if file
        scavenger_sprite_bitmap_from_pokemon(pkmn, back, species)
      end
    end
  end
end

#-------------------------------------------------------------------------------
# The box on the map: how many are left and the time left. Clicking it or
# pressing H shrinks it to just "N left" (and back); the save remembers which.
#-------------------------------------------------------------------------------
class PokemonGlobalMetadata
  attr_accessor :scavenger_hud_small
end

module ScavengerHunt
  class Hud
    W, H = 128, 56          # full box (wider if its text needs it)
    SMALL_H = 24            # shrunk: one line, as wide as its text
    MAX_W = 200
    TOGGLE_KEY = :H

    def initialize
      @vp = Viewport.new(Graphics.width - W, 0, W, H)
      @vp.z = 99_000   # under messages, menus and battles
      @sprite = Sprite.new(@vp)
      @sprite.bitmap = Bitmap.new(MAX_W, H)
      pbSetSystemFont(@sprite.bitmap)
      @text = nil
      @w = W
    end

    def disposed?; @vp.disposed?; end

    def dispose
      @sprite.bitmap.dispose
      @sprite.dispose
      @vp.dispose
    end

    def self.small?; $PokemonGlobal&.scavenger_hud_small ? true : false; end

    def height; Hud.small? ? SMALL_H : H; end

    # a click on the box or H on the free overworld
    def toggle_pressed?
      if Input.trigger?(Input::MOUSELEFT) && Input.mouse_in_window
        x, y = Input.mouse_x, Input.mouse_y
        return true if x >= Graphics.width - @w && y < height
      end
      HeldServerMessages.overworld_free? && Input.triggerex?(TOGGLE_KEY)
    rescue StandardError   # no mouse / raw keys
      false
    end

    def update(hunt)
      if $PokemonGlobal && toggle_pressed?
        $PokemonGlobal.scavenger_hud_small = !Hud.small?
        pbPlayCursorSE
      end
      left = hunt[:total] - hunt[:found]
      text = [Hud.small?, _INTL("{1} left", left), ScavengerHunt.time_text(ScavengerHunt.seconds_left(hunt))]
      return if text == @text
      @text = text
      b = @sprite.bitmap
      tw = ->(t) { b.text_size(t).width }
      w = Hud.small? ? tw.(text[1]) + 26 : [W, tw.(text[1]) + 40, tw.(text[2]) + 16].max
      w = [w, MAX_W].min
      @w, h = w, height
      @vp.rect = Rect.new(Graphics.width - w, 0, w, h)
      b.clear
      red, cream = Color.new(*Confetti::RED), Color.new(*Confetti::CREAM)
      dark, grey = Color.new(*Confetti::DARK), Color.new(*Confetti::GREY)
      b.fill_rect(0, 0, w, h, red)
      b.fill_rect(2, 2, w - 4, h - 4, cream)
      if Hud.small?
        pbDrawTextPositions(b, [[text[1], 6, 2, :left, red, Color.new(248, 160, 144)]])
        b.fill_rect(w - 15, 11, 9, 3, dark)   # "+": tap to open
        b.fill_rect(w - 12, 8, 3, 9, dark)
      else
        pbDrawTextPositions(b, [[text[1], w / 2, 4, :center, red, Color.new(248, 160, 144)],
                                [text[2], w / 2, 26, :center, dark, grey]])
        b.fill_rect(w - 15, 8, 9, 3, dark)    # "-": tap to shrink
      end
    end
  end

  @hud = nil

  def self.update_hud
    show = @hunt && seconds_left(@hunt) > 0 && $scene.is_a?(Scene_Map)
    if show
      @hud = Hud.new if !@hud || @hud.disposed?
      @hud.update(@hunt)
    elsif @hud
      @hud.dispose unless @hud.disposed?
      @hud = nil
    end
  end
end

EventHandlers.add(:on_frame_update, :scavenger_hunt,
  proc {
    if ScavengerHunt.online?
      unless ScavengerHunt.asked
        ScavengerHunt.asked = true
        NetworkClient.send_msg({ action: "scavenger_status" })
      end
    else
      ScavengerHunt.asked = false
    end
    ScavengerHunt.update_hud
    next unless HeldServerMessages.overworld_free?
    if (who = ScavengerHunt.confetti)
      ScavengerHunt.confetti = nil
      pbConfetti(_INTL("Scavenger Hunt Complete!"),
                 who == :winner ? _INTL("You got a prize!") : _INTL("A shiny is coming!"))
      pbMessage(_INTL("All the Shadow Pokémon were found! The next Mythical or legendary Pokémon to appear will be shiny!"))
      pbMessage(_INTL("You helped find them, so you got a prize! Collect it at the Auction House.")) if who == :winner
      pbMessage(_INTL("But something stirs... Drawn out by the Shadow Pokémon, {1} has appeared! Wear it down together: the first to catch it keeps it!",
                      ShadowLugia.name)) if defined?(ShadowLugia) && ShadowLugia.active?
    elsif (msg = ScavengerHunt.messages.shift)
      pbMessage(msg)
    end
  }
)

#-------------------------------------------------------------------------------
# The hunt NPC:   Script: pbScavengerHunt
#-------------------------------------------------------------------------------
def pbScavengerHunt
  unless ScavengerHunt.online?
    pbMessage(_INTL("You need to be online to join a Scavenger Hunt."))
    return false
  end
  if (h = ScavengerHunt.hunt) && ScavengerHunt.seconds_left(h) > 0
    pbMessage(_INTL("The Scavenger Hunt is on! {1} Shadow Pokémon left to find, and {2} to go.",
                    h[:total] - h[:found], ScavengerHunt.time_text(ScavengerHunt.seconds_left(h))))
    pbMessage(_INTL("Each one hides on a route or in a cave somewhere in Johto or Kanto. Keep looking in wild encounters!"))
    return false
  end
  pbMessage(_INTL("Shadow Pokémon have been spotted all over Johto and Kanto!"))
  pbMessage(_INTL("Each one hides on its own route or in its own cave. They can't be caught, but every one you run into counts."))
  pbMessage(_INTL("If everyone finds them all within 5 hours, the next Mythical or legendary Pokémon will be shiny, and everyone who found one gets a prize!"))
  pbMessage(_INTL("And find them all to draw out a rare Pokémon! Wear it down together: the first to catch it keeps it!"))
  return false unless pbConfirmMessage(_INTL("Start a Scavenger Hunt for everyone?"))
  ScavengerHunt.start_result = nil
  NetworkClient.send_msg({ action: "scavenger_start" })
  300.times do
    Graphics.update
    Input.update
    NetworkClient.update
    break if ScavengerHunt.start_result
  end
  r = ScavengerHunt.start_result
  if r && r["ok"]
    pbMessage(_INTL("The hunt is on! Good luck!"))
    return true
  end
  pbMessage(r ? r["message"].to_s : _INTL("The server didn't answer. Try again in a moment."))
  false
end
