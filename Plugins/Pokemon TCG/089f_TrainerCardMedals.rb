#==============================================================================
# Pokemon TCG - the Club Masters' medals (engine/menus/print_stats.asm,
# DrawCollectedMedals) as a 3rd badge page on the trainer card.
#   L/R on the badge pages: Johto badges -> Kanto badges -> Medals
#   The Medals page is only there while game switch MEDAL_SWITCH is ON.
#   Like the original, medals not won yet aren't drawn.
#   The page's top shows "Cards" (different cards owned) instead of Money.
# Graphics (made by tools/make_medals.py from the decomp):
#   UI/medals.png                   the 8 medals, 24x24 each, drawn 2x
#   UI/card_medals.png / _f.png     the badge page with the box emptied
#
# Script calls:
#   pbTCGGiveMedal(:grass)          shows "<name> won the Grass Medal!"
#   pbTCGGiveMedal(:grass, show: false)
#   pbTCGRemoveMedal(:grass)
#   pbTCGHasMedal?(:grass)          for a Conditional Branch
#   pbTCGMedalCount                 0-8
#   pbTCGDuel(..., medal: :grass)   gives it on a win
# Medals: :grass :science :fire :water :lightning :psychic :rock :fighting
#==============================================================================
class PokemonGlobalMetadata
  def tcg_medals; @tcg_medals ||= []; end   # medal symbols won
end

module TCG
  MEDAL_SWITCH = 107   # nil = the Medals page is always there
  # order of MedalCoordsAndTilemaps (and of UI/medals.png)
  MEDALS = [:grass, :science, :fire, :water, :lightning, :psychic, :rock, :fighting]
  MEDAL_NAMES = { grass: "Grass", science: "Science", fire: "Fire", water: "Water",
                  lightning: "Lightning", psychic: "Psychic", rock: "Rock", fighting: "Fighting" }
  # x, y on the 320x288 card (the original's 4x2 grid, centred in the box)
  MEDAL_COORDS = [[34, 156], [102, 156], [170, 156], [238, 156],
                  [34, 214], [102, 214], [170, 214], [238, 214]]

  # :grass, "Grass", "grass_medal" or 1-8
  def self.medal_key(m)
    return MEDALS[m - 1] if m.is_a?(Integer) && m.between?(1, MEDALS.size)
    k = m.to_s.downcase.sub(/_?medal\z/, "").to_sym
    MEDALS.include?(k) ? k : raise(ArgumentError, "Unknown TCG medal #{m.inspect}")
  end

  def self.medals; global ? global.tcg_medals : (@test_medals ||= []); end
  def self.medal?(m); medals.include?(medal_key(m)); end
  def self.medal_name(m); MEDAL_NAMES[medal_key(m)]; end

  # returns true if it was new
  def self.give_medal(m, show: true)
    k = medal_key(m)
    return false if medals.include?(k)
    medals << k
    if show
      name = $player ? $player.name : "Player"
      pbMessage(_INTL("\\me[Badge get]{1} won the {2} Medal!", name, medal_name(k)))
    end
    true
  end

  def self.medal_page?
    sw = MEDAL_SWITCH
    !sw || ($game_switches && $game_switches[sw]) ? true : false
  end
end

def pbTCGGiveMedal(medal, show: true); TCG.give_medal(medal, show: show);   end
def pbTCGRemoveMedal(medal);           TCG.medals.delete(TCG.medal_key(medal)); end
def pbTCGHasMedal?(medal);             TCG.medal?(medal);                   end
def pbTCGMedalCount;                   TCG.medals.size;                     end

if defined?(PokemonTrainerCard_Scene)
  class PokemonTrainerCard_Scene
    alias tcg_drawTrainerCardBadges drawTrainerCardBadges unless method_defined?(:tcg_drawTrainerCardBadges)
    def drawTrainerCardBadges
      tcg_drawTrainerCardBadges
      TCG::MEDALS.each_with_index do |_m, i|
        spr = IconSprite.new(*TCG::MEDAL_COORDS[i], @viewport)
        spr.setBitmap(TCG::GFX + "UI/medals")
        spr.src_rect.set(i * 24, 0, 24, 24)
        spr.zoom_x = spr.zoom_y = 2
        spr.z = 2
        spr.visible = false
        @sprites["tcg_medal#{i}"] = spr
      end
    end

    # "badges2" = the Medals page: drawn like the Johto page (same text),
    # then its own background and the medals instead of the badges
    alias tcg_drawTrainerCard drawTrainerCard unless method_defined?(:tcg_drawTrainerCard)
    def drawTrainerCard(trainercard_page)
      medals = (trainercard_page == "badges2")
      tcg_drawTrainerCard(medals ? "badges" : trainercard_page)
      TCG::MEDALS.each_with_index do |m, i|
        @sprites["tcg_medal#{i}"]&.visible = medals && TCG.medal?(m)
      end
      return unless medals
      @sprites.each { |k, s| s.visible = false if k =~ /\Abadge\d+\z/ }
      @sprites["background"].setBitmap(TCG::GFX + "UI/" + ($player.female? ? "card_medals_f" : "card_medals"))
      tcg_draw_medal_page_text
    end

    # same text as the Johto page, but "Cards" (different cards owned)
    # where it says "Money"
    def tcg_draw_medal_page_text
      overlay = @sprites["overlay"].bitmap
      overlay.clear
      base   = Color.new(0, 0, 0)
      shadow = Color.new(248, 248, 248)
      owned = TCG.collection.count { |_id, n| n.to_i > 0 }
      text = [
        [_INTL("Name/"), 32, 32, :left, base, shadow],
        [$player.name, 112, 32, :left, base, shadow],
        [sprintf("%05d", $player.public_ID), 80, 65, :left, base, shadow],
        [_INTL("Cards"), 32, 104, :left, base, shadow],
        [owned.to_s, 222, 104, :right, base, shadow]
      ]
      if defined?(NetworkClient) && NetworkClient.connected?
        text << [_INTL("S-Tokens"), 32, 85, :left, base, shadow]
        text << [NetworkTokens.balance.to_s, 222, 85, :right, base, shadow]
      end
      pbDrawTextPositions(overlay, text)
    end

    def tcg_badge_pages
      pages = ["badges", "badges1"]
      pages << "badges2" if TCG.medal_page?
      pages
    end

    # same as the original, but L/R steps through 3 badge pages
    # (R forward, L back) when the Medals page is on
    def pbTrainerCard
      @last_badge_page = "badges"
      loop do
        Graphics.update
        Input.update
        pbUpdate
        dorefresh = false
        if Input.trigger?(Input::BACK)
          pbPlayCloseMenuSE
          break
        elsif Input.trigger?(Input::USE) || Input.trigger?(Input::RIGHT) || Input.trigger?(Input::LEFT)
          pbPlayDecisionSE
          if @trainercard_page == "front"
            @trainercard_page = @last_badge_page
          else
            @trainercard_page = "front"
          end
          dorefresh = true
        elsif Input.trigger?(Input::L) || Input.trigger?(Input::R)
          pages = tcg_badge_pages
          if (i = pages.index(@trainercard_page))
            pbPlayDecisionSE
            @trainercard_page = pages[(i + (Input.trigger?(Input::L) ? -1 : 1)) % pages.size]
            @last_badge_page = @trainercard_page
            dorefresh = true
          end
        end
        drawTrainerCard(@trainercard_page) if dorefresh
      end
    end
  end
end
