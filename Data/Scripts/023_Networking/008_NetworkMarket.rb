#===============================================================================
# NetworkMarket — Online Pokémon Market (Grand Exchange style)
#
# Usage (from map events / NPC scripts):
#   NetworkMarket.open   # browse / buy listings
#   NetworkMarket.sell   # list one of your party Pokémon for sale
#===============================================================================

module NetworkMarket
  # Opens the browse scene. Listings are fetched lazily inside the scene so
  # the scene opens immediately (no pre-open lag).
  def self.open
    unless NetworkAuth.logged_in?
      pbMessage(_INTL("You need to be online to access the market."))
      return
    end
    pbFadeOutIn { Scene_NetworkMarket.new.main }
  end

  def self.sell
    unless NetworkAuth.logged_in?
      pbMessage(_INTL("You need to be online to sell Pokémon."))
      return
    end
    if $player.party.length <= 1
      pbMessage(_INTL("You need at least 2 Pokémon to sell one."))
      return
    end

    slot = _pick_pokemon_to_sell
    return unless slot
    pkmn = $player.party[slot]

    price = _enter_price
    return unless price

    return if pbMessage(
      _INTL("List {1} for {2} token(s)?", pkmn.name, price),
      [_INTL("Yes"), _INTL("No")], 2
    ) != 0

    result = nil
    NetworkClient.on('market_new_listing') { |_d| result = :ok }
    NetworkClient.on('market_error')       { |d|  result = d['message'] }
    NetworkClient.send_msg({ action: 'market_sell',
                             pokemon: NetworkTrade.serialize_pokemon(pkmn), price: price })
    300.times { Graphics.update; Input.update; NetworkClient.update; break if result }
    NetworkClient.off('market_new_listing')
    NetworkClient.off('market_error')

    if result == :ok
      $player.party.delete_at(slot)
      Game.save(safe: true)  # prevent duplication if player quits before the game auto-saves
      pbMessage(_INTL("{1} has been listed on the market!", pkmn.name))
    else
      pbMessage(_INTL("Could not list Pokémon: {1}", result.is_a?(String) ? result : "Server error."))
    end
  end

  private

  # Number-spinner overlay — returns chosen price or nil if cancelled.
  def self._enter_price
    price     = 1
    max_val   = 99999
    confirmed = false

    vp = Viewport.new(0, 0, Graphics.width, Graphics.height)
    vp.z = 999999

    dim = Sprite.new(vp)
    dim.bitmap = Bitmap.new(Graphics.width, Graphics.height)
    dim.bitmap.fill_rect(0, 0, Graphics.width, Graphics.height, Color.new(0, 0, 0, 160))

    bw = 256; bh = 106
    box = Sprite.new(vp)
    box.bitmap = Bitmap.new(bw, bh)
    box.x = Graphics.width / 2 - bw / 2
    box.y = Graphics.height / 2 - bh / 2

    draw = lambda do
      b = box.bitmap; b.clear
      b.fill_rect(0, 0, bw, bh, Color.new(20, 20, 52))
      b.fill_rect(0, 0, bw, 2, Color.new(90, 90, 190))
      b.fill_rect(0, bh - 2, bw, 2, Color.new(90, 90, 190))
      b.fill_rect(0, 0, 2, bh, Color.new(90, 90, 190))
      b.fill_rect(bw - 2, 0, 2, bh, Color.new(90, 90, 190))
      b.font.bold = false; b.font.size = 15
      pbDrawShadowText(b, 0, 7, bw, 20, "Set price (tokens):",
                       Color.new(200, 200, 225), Color.new(0, 0, 0), 1)
      pbDrawShadowText(b, 0, 26, bw, 18, "▲",
                       Color.new(150, 150, 200), Color.new(0, 0, 0), 1)
      b.font.bold = true; b.font.size = 32
      pbDrawShadowText(b, 0, 38, bw, 36, price.to_s,
                       Color.new(255, 200, 50), Color.new(0, 0, 0), 1)
      b.font.bold = false; b.font.size = 15
      pbDrawShadowText(b, 0, 74, bw, 18, "▼",
                       Color.new(150, 150, 200), Color.new(0, 0, 0), 1)
      b.font.size = 11
      pbDrawShadowText(b, 0, 91, bw, 14, "Up/Dn ±1   Left/Right ±10   A: OK   B: Cancel",
                       Color.new(130, 130, 155), Color.new(0, 0, 0), 1)
    end

    draw.call
    loop do
      Graphics.update; Input.update
      prev = price
      price = [price + 1,  max_val].min if Input.repeat?(Input::UP)
      price = [price - 1,  1].max       if Input.repeat?(Input::DOWN)
      price = [price + 10, max_val].min if Input.repeat?(Input::RIGHT)
      price = [price - 10, 1].max       if Input.repeat?(Input::LEFT)
      draw.call if price != prev
      if Input.trigger?(Input::USE); confirmed = true; break; end
      break if Input.trigger?(Input::BACK)
    end

    dim.dispose; box.dispose; vp.dispose
    confirmed ? price : nil
  end

  def self._pick_pokemon_to_sell
    chosen = nil
    pbFadeOutIn do
      scene  = PokemonParty_Scene.new
      screen = PokemonPartyScreen.new(scene, $player.party)
      screen.pbStartScene(_INTL("Choose a Pokémon to sell."), false)
      chosen = screen.pbChoosePokemon
      screen.pbEndScene
    end
    return nil if chosen.nil? || chosen < 0
    return nil if $player.party[chosen].egg?
    chosen
  end
end

#===============================================================================
# Scene_NetworkMarket
#===============================================================================

class Scene_NetworkMarket
  LIST_W     = 220
  ENTRY_H    = 34
  HEADER_H   = 28
  TAB_H      = 22
  FOOTER_H   = 20
  TYPE_ORDER = [:NORMAL, :FIRE, :WATER, :ELECTRIC, :GRASS, :ICE, :FIGHTING,
                :POISON, :GROUND, :FLYING, :PSYCHIC, :BUG, :ROCK, :GHOST,
                :DRAGON, :DARK, :STEEL, :FAIRY].freeze

  def initialize
    @listings      = nil   # nil = still fetching
    @index         = 0
    @top_row       = 0
    @visible_count = 0
    @active_tab    = :all
    @tabs          = []
    @filtered      = []
    @tab_scroll    = 0
  end

  def main
    _create_sprites
    _build_tabs
    _update_tabs
    _update_list           # shows "Loading..." initially
    _request_listings      # sends request; callback populates @listings when ready
    _register_live_callbacks
    _main_loop
    _unregister_live_callbacks
    _dispose_all
  end

  private

  #-----------------------------------------------------------------------------
  # Sprite setup
  #-----------------------------------------------------------------------------
  def _create_sprites
    w    = Graphics.width
    h    = Graphics.height
    pv_x = LIST_W + 2
    pv_w = w - pv_x

    @viewport = Viewport.new(0, 0, w, h)
    @viewport.z = 99999

    @static_bmp = Sprite.new(@viewport)
    @static_bmp.bitmap = Bitmap.new(w, h)
    b = @static_bmp.bitmap
    b.fill_rect(0, 0, w, h, Color.new(15, 15, 30))
    b.fill_rect(0, 0, w, HEADER_H, Color.new(25, 25, 70))
    b.fill_rect(LIST_W, HEADER_H + TAB_H, 2, h - HEADER_H - TAB_H, Color.new(70, 70, 110))
    b.font.size = 18; b.font.bold = true
    pbDrawShadowText(b, 8, 4, w / 2 - 8, HEADER_H - 4,
                     "Online Market", Color.new(255, 255, 255), Color.new(0, 0, 0))
    b.font.size = 13; b.font.bold = false
    pbDrawShadowText(b, 4, h - 18, w - 8, 16,
                     "◄►: Tab   Up/Dn: Browse   A: Select   B: Close",
                     Color.new(140, 140, 160), Color.new(0, 0, 0))
    _draw_token_count

    # Tab bar strip
    @tab_bmp = Sprite.new(@viewport)
    @tab_bmp.bitmap = Bitmap.new(w, TAB_H)
    @tab_bmp.x = 0; @tab_bmp.y = HEADER_H

    # Scrollable list canvas
    @list_bmp = Sprite.new(@viewport)
    @list_bmp.bitmap = Bitmap.new(LIST_W, h - HEADER_H - TAB_H - FOOTER_H)
    @list_bmp.x = 0; @list_bmp.y = HEADER_H + TAB_H
    @visible_count = @list_bmp.bitmap.height / ENTRY_H

    # Preview panel
    @preview_bmp = Sprite.new(@viewport)
    @preview_bmp.bitmap = Bitmap.new(pv_w, 90)
    @preview_bmp.x = pv_x; @preview_bmp.y = HEADER_H + TAB_H + 4

    # Pokémon front sprite
    @pkmn_sprite = Sprite.new(@viewport)
    @pkmn_sprite.x = pv_x + pv_w / 2 - 64
    @pkmn_sprite.y = HEADER_H + TAB_H + 100
  end

  def _draw_token_count
    b = @static_bmp.bitmap; w = Graphics.width
    b.fill_rect(w / 2, 0, w / 2, HEADER_H, Color.new(25, 25, 70))
    b.font.size = 18; b.font.bold = true
    pbDrawShadowText(b, 0, 4, w - 8, HEADER_H - 4,
                     "Tokens: #{NetworkTokens.balance}", Color.new(255, 200, 50), Color.new(0, 0, 0), 2)
  end

  #-----------------------------------------------------------------------------
  # Tab helpers
  #-----------------------------------------------------------------------------
  def _build_tabs
    @tabs = [
      { key: :all,       label: 'All' },
      { key: :shiny,     label: "★ Shiny" },
      { key: :legendary, label: 'Legendary' },
    ]
    return unless @listings

    present = {}
    @listings.each do |l|
      _species_types(l['pokemon']['species']).each { |t| present[t] = true }
    end

    TYPE_ORDER.each do |t|
      next unless present[t]
      name = begin; GameData::Type.get(t).name; rescue; t.to_s.capitalize; end
      @tabs << { key: t, label: name }
    end

    # Fall back to :all if the current tab was removed
    unless @tabs.any? { |tab| tab[:key] == @active_tab }
      @active_tab = :all
    end
  end

  def _apply_filter
    src = @listings || []
    @filtered = case @active_tab
    when :all       then src
    when :shiny     then src.select { |l| l['pokemon']['shiny'] == true }
    when :legendary then src.select { |l| _legendary?(l['pokemon']['species']) }
    else            src.select { |l| _species_types(l['pokemon']['species']).include?(@active_tab) }
    end
    @index   = 0
    @top_row = 0
  end

  def _update_tabs
    bmp = @tab_bmp.bitmap; bmp.clear
    bmp.font.size = 11; bmp.font.bold = false
    sw = Graphics.width

    widths = @tabs.map { |t| [bmp.text_size(t[:label]).width + 14, 44].max }
    total  = widths.sum

    # Scroll so the active tab is always fully visible
    ai = @tabs.index { |t| t[:key] == @active_tab } || 0
    ax = widths[0...ai].sum
    if ax < @tab_scroll
      @tab_scroll = ax
    elsif ax + widths[ai] > @tab_scroll + sw
      @tab_scroll = ax + widths[ai] - sw
    end
    @tab_scroll = @tab_scroll.clamp(0, [total - sw, 0].max)

    bmp.fill_rect(0, 0, sw, TAB_H, Color.new(18, 18, 45))
    bmp.fill_rect(0, TAB_H - 1, sw, 1, Color.new(70, 70, 110))

    x = -@tab_scroll
    @tabs.each_with_index do |tab, i|
      tw = widths[i]
      next if x + tw < 0
      break if x >= sw
      active = (tab[:key] == @active_tab)
      if active
        bmp.fill_rect(x, 0, tw, TAB_H - 1, Color.new(50, 50, 100))
        bmp.fill_rect(x, TAB_H - 1, tw, 1, Color.new(94, 200, 240))
      end
      color = active ? Color.new(255, 255, 255) : Color.new(140, 140, 170)
      pbDrawShadowText(bmp, x + 4, 3, tw - 8, TAB_H - 6,
                       tab[:label], color, Color.new(0, 0, 0), 1)
      x += tw
    end
  end

  def _prev_tab
    i = @tabs.index { |t| t[:key] == @active_tab } || 0
    @active_tab = @tabs[(i - 1 + @tabs.length) % @tabs.length][:key]
    _apply_filter; _update_tabs; _update_list; _update_preview
  end

  def _next_tab
    i = @tabs.index { |t| t[:key] == @active_tab } || 0
    @active_tab = @tabs[(i + 1) % @tabs.length][:key]
    _apply_filter; _update_tabs; _update_list; _update_preview
  end

  def _species_types(species_str)
    sym = species_str.to_sym
    return [] unless GameData::Species.exists?(sym)
    GameData::Species.get(sym).types
  rescue
    []
  end

  def _legendary?(species_str)
    sym = species_str.to_sym
    return false unless GameData::Species.exists?(sym)
    GameData::Species.get(sym).catch_rate <= 3
  rescue
    false
  end

  #-----------------------------------------------------------------------------
  # Fetch listings from server
  #-----------------------------------------------------------------------------
  def _request_listings
    NetworkClient.on('market_listings') do |d|
      NetworkClient.off('market_listings')
      @listings = d['listings']
      _build_tabs; _apply_filter; _update_tabs
      _update_list; _update_preview
    end
    NetworkClient.send_msg({ action: 'market_list' })
  end

  #-----------------------------------------------------------------------------
  # List drawing
  #-----------------------------------------------------------------------------
  def _update_list
    bmp = @list_bmp.bitmap; bmp.clear
    bmp.font.bold = false

    if @listings.nil?
      bmp.font.size = 15
      pbDrawShadowText(bmp, 4, 8, LIST_W - 8, 24,
                       "Loading...", Color.new(160, 160, 200), Color.new(0, 0, 0))
      return
    end

    if @filtered.empty?
      bmp.font.size = 15
      msg = @listings.empty? ? "No listings yet." : "None in this category."
      pbDrawShadowText(bmp, 4, 8, LIST_W - 8, 24,
                       msg, Color.new(160, 160, 160), Color.new(0, 0, 0))
      return
    end

    @filtered.each_with_index do |listing, i|
      next if i < @top_row || i >= @top_row + @visible_count
      row = i - @top_row; y = row * ENTRY_H

      if i == @index
        bmp.fill_rect(0, y, LIST_W, ENTRY_H - 1, Color.new(55, 55, 105))
      elsif row.odd?
        bmp.fill_rect(0, y, LIST_W, ENTRY_H - 1, Color.new(22, 22, 45))
      end

      pokemon  = listing['pokemon']
      shiny    = pokemon['shiny'] == true
      name     = pokemon['nickname'] || pokemon['species'].to_s
      bmp.font.size = 15
      pbDrawShadowText(bmp, 6, y + 5, LIST_W - 72, ENTRY_H - 10, "#{name} Lv.#{pokemon['level']}",
                       shiny ? Color.new(255, 215, 0) : Color.new(235, 235, 235), Color.new(0, 0, 0))
      pbDrawShadowText(bmp, LIST_W - 70, y + 5, 64, ENTRY_H - 10, "#{listing['price']}T",
                       Color.new(255, 200, 50), Color.new(0, 0, 0), 2)
    end

    if @filtered.length > @visible_count
      total_h = bmp.height
      bar_h   = (total_h * @visible_count.to_f / @filtered.length).to_i.clamp(10, total_h)
      bar_y   = (@top_row.to_f / [@filtered.length - @visible_count, 1].max * (total_h - bar_h)).to_i
      bmp.fill_rect(LIST_W - 4, bar_y, 4, bar_h, Color.new(100, 100, 180))
    end
  end

  #-----------------------------------------------------------------------------
  # Preview panel (right side)
  #-----------------------------------------------------------------------------
  def _update_preview
    bmp = @preview_bmp.bitmap; bmp.clear
    @pkmn_sprite.bitmap&.dispose; @pkmn_sprite.bitmap = nil

    return if @listings.nil? || @filtered.empty?
    listing = @filtered[@index]; return unless listing
    pokemon = listing['pokemon']

    bmp.font.bold = true; bmp.font.size = 20
    pbDrawShadowText(bmp, 4, 2, bmp.width - 8, 28,
                     "#{listing['price']} Tokens", Color.new(255, 200, 50), Color.new(0, 0, 0))
    bmp.font.bold = false; bmp.font.size = 14
    pbDrawShadowText(bmp, 4, 32, bmp.width - 8, 20,
                     "Seller: #{listing['seller']}", Color.new(170, 170, 200), Color.new(0, 0, 0))
    name = pokemon['nickname'] || pokemon['species'].to_s
    bmp.font.size = 13
    pbDrawShadowText(bmp, 4, 54, bmp.width - 8, 18,
                     "#{name}  Lv.#{pokemon['level']}", Color.new(200, 200, 200), Color.new(0, 0, 0))

    begin
      sym = pokemon['species'].to_sym
      if GameData::Species.exists?(sym)
        sp    = GameData::Species.get(sym)
        fname = sp.front_sprite_filename(pokemon['form'].to_i,
                                         pokemon['gender'].to_i == 1,
                                         pokemon['shiny'] == true)
        @pkmn_sprite.bitmap = RPG::Cache.battler(fname, 0).clone
      end
    rescue
    end
  end

  #-----------------------------------------------------------------------------
  # Real-time updates while browsing
  #-----------------------------------------------------------------------------
  def _register_live_callbacks
    NetworkClient.on('market_new_listing') do |d|
      next unless @listings
      @listings.unshift(d['listing'])
      _build_tabs; _apply_filter; _update_tabs; _update_list
    end

    NetworkClient.on('market_listing_removed') do |d|
      next unless @listings
      idx = @listings.index { |l| l['id'] == d['listing_id'] }
      next unless idx
      @listings.delete_at(idx)
      _build_tabs; _apply_filter; _update_tabs; _update_list; _update_preview
    end

    NetworkClient.on('market_sold') do |d|
      pbMessage(_INTL("{1} bought your {2} for {3} token(s)!",
                      d['buyer'], d['pokemon']['species'], d['price']))
      NetworkTokens.set(d['new_tokens'])
      _draw_token_count
    end
  end

  def _unregister_live_callbacks
    NetworkClient.off('market_new_listing')
    NetworkClient.off('market_listing_removed')
    NetworkClient.off('market_listings')  # cancel pending fetch if still open
    # off('market_sold') removes ALL handlers including the global one in NetworkTokens,
    # so we remove it then immediately restore the persistent balance-sync handler.
    NetworkClient.off('market_sold')
    NetworkTokens.register_market_sold_handler
  end

  #-----------------------------------------------------------------------------
  # Main loop
  #-----------------------------------------------------------------------------
  def _main_loop
    loop do
      Graphics.update; Input.update
      NetworkClient.update if NetworkClient.connected?

      tabs_ready = !@tabs.empty?
      list_ready = !@filtered.empty?

      if Input.trigger?(Input::LEFT) && tabs_ready
        _prev_tab

      elsif Input.trigger?(Input::RIGHT) && tabs_ready
        _next_tab

      elsif Input.trigger?(Input::UP) && list_ready && @index > 0
        @index -= 1; @top_row = @index if @index < @top_row
        _update_list; _update_preview

      elsif Input.trigger?(Input::DOWN) && list_ready && @index < @filtered.length - 1
        @index += 1; @top_row = @index - @visible_count + 1 if @index >= @top_row + @visible_count
        _update_list; _update_preview

      elsif Input.trigger?(Input::USE) && list_ready
        _show_detail_menu(@filtered[@index])

      elsif Input.trigger?(Input::BACK)
        break
      end
    end
  end

  #-----------------------------------------------------------------------------
  # Detail menu
  #-----------------------------------------------------------------------------
  def _show_detail_menu(listing)
    pokemon   = listing['pokemon']
    my_own    = listing['seller'] == NetworkAuth.username
    name      = pokemon['nickname'] || pokemon['species'].to_s
    shiny_tag = (pokemon['shiny'] == true) ? " ★" : ""
    prompt    = _INTL("{1}{2}  Lv.{3}\nSeller: {4}  —  {5} token(s)",
                      name, shiny_tag, pokemon['level'], listing['seller'], listing['price'])

    if my_own
      choice = pbMessage(prompt, [_INTL("Take Back"), _INTL("Stats"), _INTL("Cancel")], 3)
      _do_cancel_listing(listing) if choice == 0
      _show_stats(pokemon)        if choice == 1
    else
      choice = pbMessage(prompt, [_INTL("Buy"), _INTL("Stats"), _INTL("Cancel")], 3)
      _do_buy(listing)     if choice == 0
      _show_stats(pokemon) if choice == 1
    end
  end

  def _do_buy(listing)
    if NetworkTokens.balance < listing['price'].to_i
      pbMessage(_INTL("Not enough tokens.\nYou have {1}, need {2}.",
                      NetworkTokens.balance, listing['price']))
      return
    end
    return if pbMessage(
      _INTL("Buy {1} for {2} token(s)?", listing['pokemon']['species'], listing['price']),
      [_INTL("Yes"), _INTL("No")], 2
    ) != 0

    result = nil
    NetworkClient.on('market_buy_ok') { |d| result = d }
    NetworkClient.on('market_error')  { |d| result = { '_err' => d['message'] } }
    NetworkClient.send_msg({ action: 'market_buy', listing_id: listing['id'] })
    300.times { Graphics.update; Input.update; NetworkClient.update; break if result }
    NetworkClient.off('market_buy_ok'); NetworkClient.off('market_error')

    if result.is_a?(Hash) && result['pokemon']
      pkmn = NetworkTrade.deserialize_pokemon(result['pokemon'])
      if pkmn
        NetworkTokens.set(result['new_tokens']); _draw_token_count
        pbStorePokemon(pkmn)
        pbMessage(_INTL("You got {1}!", pkmn.name))
      end
    else
      pbMessage(_INTL("Purchase failed: {1}",
                      result.is_a?(Hash) ? (result['_err'] || "Unknown error.") : "No response."))
    end
  end

  def _do_cancel_listing(listing)
    return if pbMessage(
      _INTL("Take back {1}?", listing['pokemon']['species']),
      [_INTL("Yes"), _INTL("No")], 2
    ) != 0

    result = nil
    NetworkClient.on('market_cancel_ok') { |d| result = d }
    NetworkClient.on('market_error')     { |d| result = { '_err' => d['message'] } }
    NetworkClient.send_msg({ action: 'market_cancel', listing_id: listing['id'] })
    300.times { Graphics.update; Input.update; NetworkClient.update; break if result }
    NetworkClient.off('market_cancel_ok'); NetworkClient.off('market_error')

    if result.is_a?(Hash) && result['pokemon']
      pkmn = NetworkTrade.deserialize_pokemon(result['pokemon'])
      if pkmn
        pbStorePokemon(pkmn)
        pbMessage(_INTL("{1} has been returned to you.", pkmn.name))
      end
    else
      pbMessage(_INTL("Failed: {1}",
                      result.is_a?(Hash) ? (result['_err'] || "Unknown error.") : "No response."))
    end
  end

  def _show_stats(pokemon_data)
    pkmn = NetworkTrade.deserialize_pokemon(pokemon_data)
    return unless pkmn
    pbFadeOutIn do
      scene  = PokemonSummary_Scene.new
      screen = PokemonSummaryScreen.new(scene)
      screen.pbStartScreen([pkmn], 0)
    end
  end

  #-----------------------------------------------------------------------------
  # Helpers
  #-----------------------------------------------------------------------------
  def _clamp_top_row
    @top_row = @top_row.clamp(0, [@filtered.length - @visible_count, 0].max)
  end

  def _dispose_all
    @static_bmp.dispose; @tab_bmp.dispose; @list_bmp.dispose; @preview_bmp.dispose
    @pkmn_sprite.bitmap&.dispose; @pkmn_sprite.dispose
    @viewport.dispose
  end
end
