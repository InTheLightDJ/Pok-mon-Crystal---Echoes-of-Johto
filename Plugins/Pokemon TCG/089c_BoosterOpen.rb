#==============================================================================
# Pokemon TCG - receiving a booster pack (GiveBoosterPack + _OpenBoosterPack,
# engine/menus/give_booster_pack.asm / booster_pack.asm)
#   The pack's scene (CGB tilemap + logo, Graphics/.../Boosters, made by
#   tools/make_booster_art.py) at tile 6,0 after a white flash,
#   "PLAYER received a Booster\nPack: COLOSSEUM." ("...And another Booster
#   Pack:" for the next one in the same reward), "PLAYER checked the cards\n
#   in the Booster Pack!!", then the "Booster Pack" card list (A / START show
#   the card page, B leaves).
#
#   pbTCGOpenBooster(pack, another = false) -> array of the card ids received
#==============================================================================
module TCG
  BOOSTER_SCENE_NAMES = { :COLOSSEUM => "COLOSSEUM", :EVOLUTION => "EVOLUTION",
                          :MYSTERY => "MYSTERY", :LABORATORY => "LABORATORY", :GENESIS => "GENESIS",
                          :REVELATION => "REVELATION", :DISCOVERY => "DISCOVERY",
                          :DESTINY => "DESTINY" }

  # the booster's cards seen as a "duelist" for the card list screen
  class BoosterCards
    def initialize(ids); @ids = ids; end
    def card(i); TCG.card(@ids[i]); end
    def card_id(i); @ids[i]; end
    def name; ""; end
  end

  class DuelScene
    def booster_pack_screen(pack, cards, another)
      set = pack.is_a?(DestinyPack) ? :DESTINY : (BOOSTER_PACKS[pack] && BOOSTER_PACKS[pack][:set]) || :COLOSSEUM
      set = :COLOSSEUM unless BOOSTER_SCENE_NAMES[set]
      player = $player ? $player.name : "PLAYER"
      # InitMenuScreen + LoadBoosterGfx (scene at 6,0) + FlashWhiteScreen
      @map.clear
      @map.picture(6, 0, "Boosters/#{set.to_s.downcase}", 8, 12)
      @map.flash = true
      render
      8.times { frame }
      @map.flash = false
      render
      text = if another
               "...And another Booster Pack:\n#{BOOSTER_SCENE_NAMES[set]}."
             else
               "#{player} received a Booster\nPack: #{BOOSTER_SCENE_NAMES[set]}."
             end
      message(text, keep: true)
      message("#{player} checked the cards\nin the Booster Pack!!", keep: true)
      # _OpenBoosterPack: DisplayCardList with the Booster Pack header
      list = BoosterCards.new(cards)
      card_list_screen(list, (0...cards.size).to_a, "Booster Pack",
                       "Choose the card\nyou wish to examine.", menu: :view)
    end
  end
end

def pbTCGOpenBooster(pack, another = false)
  pack = pack.to_sym unless pack.is_a?(TCG::DestinyPack)
  cards = TCG.generate_booster(pack)
  TCG.add_cards(cards)
  pbFadeOutIn do
    scene = TCG::DuelScene.new
    begin
      scene.booster_pack_screen(pack, cards, another)
    ensure
      scene.dispose
    end
  end
  cards
end
