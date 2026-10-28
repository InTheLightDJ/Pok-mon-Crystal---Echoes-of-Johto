#==============================================================================
# Pokemon TCG - card album and booster opening.
#
#   pbTCGCardAlbum             -> browse every card by set; owned counts,
#                                 unowned cards shown as "?????"; USE opens
#                                 the card page (art, HP, attacks, text)
#   pbTCGOpenBooster(pack)     -> opens a pack (TCG::BOOSTER_PACKS key) into
#                                 the collection, showing each card; returns ids
#   pbTCGShowCard(id)          -> the card page on its own (original layout)
#==============================================================================
module TCG
  ALBUM_SETS = [
    [:COLOSSEUM,   _INTL("Colosseum")],  [:EVOLUTION,  _INTL("Evolution")],
    [:MYSTERY,     _INTL("Mystery")],    [:LABORATORY, _INTL("Laboratory")],
    [:PROMOTIONAL, _INTL("Promotional")], [:ENERGY,    _INTL("Energy")],
    [:NEO,         _INTL("Neo")]   # custom cards, 001b_NeoCards.rb
  ]

  def self.cards_in_set(set)
    CARD_ORDER.select { |id| CARDS[id][:sets].first.to_s == set.to_s }
  end

  PAGE_WRAP = 36   # characters per line beside the card art

  def self.wrap_text(text, width = PAGE_WRAP)
    text.split("
").flat_map do |para|
      lines = [""]
      para.split(" ").each do |w|
        if !lines[-1].empty? && lines[-1].size + 1 + w.size > width
          lines << w
        else
          lines[-1] = lines[-1].empty? ? w : "#{lines[-1]} #{w}"
        end
      end
      lines
    end
  end

  # text lines of a card's page
  def self.card_page_lines(id)
    h = CARDS[id]
    c = Card.get(id)
    lines = []
    if c.pokemon?
      lines << _INTL("{1}  HP {2}  {3}", c.name, c.hp, h[:stage].to_s.capitalize)
      lines << _INTL("Evolves from {1}", h[:preevo]) if h[:preevo]
      (h[:attacks] || []).each do |a|
        cost = (a[:cost] || {}).map { |t, n| "#{t.capitalize[0, 3]}x#{n}" }.join(" ")
        dmg  = a[:damage].to_i > 0 ? "  #{a[:damage]}" : ""
        lines << ""
        lines << "#{a[:name]}#{dmg}   #{cost}"
        lines.concat(TCG.wrap_text(TCG.plain_text(a[:desc].to_s))) if a[:desc]
      end
      lines << ""
      lines << _INTL("Weakness: {1}", (h[:weakness] || []).join(" ").capitalize)
      lines << _INTL("Resistance: {1}", (h[:resistance] || []).join(" ").capitalize)
      lines << _INTL("Retreat cost: {1}", h[:retreat].to_i)
    else
      lines << c.name
      lines << ""
      lines.concat(TCG.wrap_text(TCG.plain_text(h[:desc].to_s)))
    end
    lines
  end

  #----------------------------------------------------------------------------
  class CardPageScene
    def initialize(id); @id = id; end

    def show
      vp = Viewport.new(0, 0, Graphics.width, Graphics.height)
      vp.z = 100_000
      bg = Sprite.new(vp)
      bg.bitmap = Bitmap.new(Graphics.width, Graphics.height)
      bg.bitmap.fill_rect(0, 0, Graphics.width, Graphics.height, Color.new(248, 248, 232))
      pbSetSmallFont(bg.bitmap)
      art = Sprite.new(vp)
      art.bitmap = RPG::Cache.load_bitmap(GFX + "Cards/", CARDS[@id][:gfx].to_s.split("*", 2)[0]) rescue nil
      x0 = 8
      if art.bitmap
        art.zoom_x = art.zoom_y = [(Graphics.height - 16).to_f / art.bitmap.height, 2.0].min
        art.x = 8
        art.y = 8
        x0 = 16 + (art.bitmap.width * art.zoom_x).to_i
      end
      lines = TCG.card_page_lines(@id)
      text = Sprite.new(vp)
      text.x = x0
      text.y = 8
      text.bitmap = Bitmap.new(Graphics.width - x0 - 8, [lines.size * 18 + 8, 32].max)
      pbSetSmallFont(text.bitmap)
      lines.each_with_index do |l, n|
        pbDrawTextPositions(text.bitmap, [[l, 0, n * 18, :left, Color.new(40, 40, 40), Color.new(208, 208, 200)]])
      end
      view_h = Graphics.height - 16
      max_scroll = [text.bitmap.height - view_h, 0].max
      scroll = 0
      text.src_rect.set(0, 0, text.bitmap.width, view_h)
      loop do
        Graphics.update
        Input.update
        break if Input.trigger?(Input::BACK) || Input.trigger?(Input::USE)
        if Input.repeat?(Input::DOWN) then scroll = [scroll + 18, max_scroll].min
        elsif Input.repeat?(Input::UP) then scroll = [scroll - 18, 0].max
        end
        text.src_rect.y = scroll
      end
    ensure
      text&.bitmap&.dispose
      text&.dispose
      bg&.bitmap&.dispose
      bg&.dispose
      art&.dispose
      vp&.dispose
    end
  end
end

# the original card page (OpenCardPage, 070_Scene.rb)
def pbTCGShowCard(id)
  scene = TCG::DuelScene.new
  scene.show_card_page(id.to_sym)
ensure
  scene&.dispose
end

def pbTCGCardAlbum
  owned = ->(id) { TCG.versions(id).any? { |v| TCG.card_count(v) > 0 } }
  loop do
    sets = TCG::ALBUM_SETS.map do |set, label|
      ids = TCG.cards_in_set(set)
      _INTL("{1}  {2}/{3}", label, ids.count { |i| owned.call(i) }, ids.size)
    end
    s = pbShowCommands(nil, sets + [_INTL("Exit")], sets.size + 1)
    return if s < 0 || s >= sets.size
    ids = TCG.cards_in_set(TCG::ALBUM_SETS[s][0])
    idx = 0
    loop do
      # one line per card, then a gold line per holo version owned
      # (011b_HoloCards.rb)
      rows = []
      ids.each_with_index do |id, n|
        cnt = TCG.card_count(id)
        if owned.call(id)
          rows << [id, _INTL("{1}. {2} x{3}", n + 1, TCG.card_name(id), cnt)]
          TCG.versions(id).drop(1).each do |v|
            next if TCG.card_count(v) == 0
            text = _INTL("{1} Holo x{2}", TCG.holo_name(TCG.holo_tier(v)), TCG.card_count(v))
            rows << [v, "      " + shadowc3tag(TCG::HOLO_NAME_BASE, TCG::HOLO_NAME_SHADOW) + text]
          end
        else
          rows << [nil, _INTL("{1}. ?????", n + 1)]
        end
      end
      idx = TCG.show_formatted_commands(rows.map { |r| r[1] }, idx)
      break if idx < 0
      id = rows[idx][0]
      if id && TCG.card_count(id) > 0
        pbTCGShowCard(id)
      elsif id
        pbMessage(_INTL("You don't have the normal version of this card."))
      else
        pbMessage(_INTL("You don't have this card yet."))
      end
    end
  end
end

module TCG
  HOLO_NAME_BASE   = Color.new(200, 140, 0) if defined?(Color)
  HOLO_NAME_SHADOW = Color.new(248, 216, 128) if defined?(Color)

  # pbShowCommands with formatted lines (<c3=...> colors); -1 for B
  def self.show_formatted_commands(commands, index = 0)
    win = Window_AdvancedCommandPokemonEx.new(commands)
    win.z = 99_999
    win.resizeToFit(commands)
    win.width = Graphics.width if win.width > Graphics.width
    win.height = Graphics.height if win.height > Graphics.height
    win.x = Graphics.width - win.width
    win.index = index.clamp(0, commands.size - 1)
    ret = -1
    loop do
      Graphics.update
      Input.update
      win.update
      if Input.trigger?(Input::BACK)
        ret = -1
        break
      elsif Input.trigger?(Input::USE)
        ret = win.index
        break
      end
      pbUpdateSceneMap
    end
    ret
  ensure
    win&.dispose
    Input.update
  end
end

# pbTCGOpenBooster: see 089c_BoosterOpen.rb (the original booster screens)
