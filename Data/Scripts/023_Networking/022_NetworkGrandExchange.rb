#===============================================================================
# NetworkGrandExchange — Item Grand Exchange
#
# Players post buy/sell orders for any PBS item. Orders are matched at the
# resting (maker) order's price. Filled items/tokens go to a per-player claim
# box; collect from the My Orders tab. All prices are server tokens.
#
# Open from an event NPC/poster:  NetworkGrandExchange.open
#===============================================================================

module NetworkGrandExchange
  @prices       = {}
  @my_orders    = { 'buy_orders' => [], 'sell_orders' => [] }
  @claim_tokens = 0
  @claim_items  = {}

  def self.open
    unless NetworkAuth.logged_in?
      pbMessage(_INTL("You need to be online to access the Grand Exchange."))
      return
    end
    pbFadeOutIn { Scene_GrandExchange.new.main }
  end

  def self.guide_price(item_id)
    (@prices[item_id.to_s.upcase] || 10).to_i
  end

  def self.my_orders
    @my_orders
  end

  def self.claim_tokens
    @claim_tokens
  end

  def self.claim_items
    @claim_items
  end

  def self.has_claims?
    @claim_tokens > 0 || (@claim_items || {}).any? { |_, v| v.to_i > 0 }
  end

  def self._set_prices(hash)
    @prices = (hash || {}).transform_keys { |k| k.to_s.upcase }
  end

  def self._set_my_orders(data)
    @my_orders    = data || { 'buy_orders' => [], 'sell_orders' => [] }
    @claim_tokens = (data['claim_tokens'] || 0).to_i rescue 0
    @claim_items  = data['claim_items'] || {}
    @claim_items  = {} unless @claim_items.is_a?(Hash)
  end

  def self._set_claims(tokens, items)
    @claim_tokens = tokens.to_i
    @claim_items  = items.is_a?(Hash) ? items : {}
  end

  def self._on_order_fill(data)
    return unless data['order_id']
    qty = data['qty_filled'].to_i
    ['buy_orders', 'sell_orders'].each do |k|
      (@my_orders[k] || []).each do |o|
        o['filled'] = (o['filled'].to_i + qty) if o['id'] == data['order_id']
      end
    end
  end

  def self._remove_order(order_id, order_type)
    key = "#{order_type}_orders"
    (@my_orders[key] || []).reject! { |o| o['id'] == order_id }
  end

  def self.register_cancel_handler
    NetworkClient.on('ge_order_cancelled') do |d|
      NetworkGrandExchange._remove_order(d['order_id'], d['order_type'].to_s)
      NetworkTokens.set(d['new_balance']) if d['new_balance']
      next unless d['refund_items'].to_i > 0
      sym = d['item_id'].to_s.upcase.to_sym rescue nil
      next unless sym && GameData::Item.exists?(sym)
      $bag.add(sym, d['refund_items'].to_i) rescue nil
      Game.save(safe: true) rescue nil
    end
  end
end

#===============================================================================
# Global persistent callbacks
#===============================================================================

NetworkClient.on('auth_ok') do |_|
  NetworkClient.send_msg({ action: 'ge_prices_request' })
  NetworkClient.send_msg({ action: 'ge_my_orders' })
end

NetworkClient.on('ge_prices') do |d|
  NetworkGrandExchange._set_prices(d['prices'])
end

NetworkClient.on('ge_my_orders') do |d|
  NetworkGrandExchange._set_my_orders(d)
end

# Fill notification while in the field — update fill counts and claim display.
NetworkClient.on('ge_order_fill') do |d|
  NetworkGrandExchange._on_order_fill(d)
end

# Claim box updated (order matched while online).
NetworkClient.on('ge_claim_update') do |d|
  NetworkGrandExchange._set_claims(d['claim_tokens'], d['claim_items'])
end

NetworkGrandExchange.register_cancel_handler

#===============================================================================
# Scene_GrandExchange
#===============================================================================

class Scene_GrandExchange
  HEADER_H = 28
  TAB_H    = 22
  FOOTER_H = 20
  LIST_W   = 212
  ICON_H   = 28
  MAX_QTY  = 9999

  VK_BACK     = 8
  VK_ENTER    = 13
  VK_SPACE    = 32
  VK_A_KEY    = 65
  VK_Z_KEY    = 90
  VK_LBUTTON  = 0x01

  CLOSE_BTN_X = Graphics.width - 58
  CLOSE_BTN_Y = 5
  CLOSE_BTN_W = 52
  CLOSE_BTN_H = 18

  TABS = [[:search, "Search"], [:my_orders, "My Orders"]].freeze

  def initialize
    @tab            = :search
    @search_str     = ""
    @search_focused = false
    @results        = []
    @result_idx     = 0
    @result_top     = 0
    @max_vis        = 8
    @selected_item  = nil
    @item_detail    = nil
    @order_list     = []
    @order_idx      = 0
    @order_top      = 0
    @running        = true
    @icon_cache     = {}
    @key_curr       = {}
    @key_prev       = {}
    @kb = begin
      Win32API.new('user32', 'GetAsyncKeyState', ['i'], 'i')
    rescue
      nil
    end
    _setup_mouse
  end

  def _setup_mouse
    @cursor_pos_api   = Win32API.new('user32', 'GetCursorPos',     'P',  'L') rescue nil
    @screen_to_client = Win32API.new('user32', 'ScreenToClient',   'LP', 'L') rescue nil
    @get_client_rect  = Win32API.new('user32', 'GetClientRect',    'LP', 'L') rescue nil
    @get_fg_window    = Win32API.new('user32', 'GetForegroundWindow', '', 'L') rescue nil
  end

  def _mouse_game_pos
    return [-1, -1] unless @cursor_pos_api && @screen_to_client && @get_client_rect && @get_fg_window
    hwnd = @get_fg_window.call
    return [-1, -1] if hwnd == 0
    pt = [0, 0].pack('l2')
    @cursor_pos_api.call(pt)
    @screen_to_client.call(hwnd, pt)
    raw_x, raw_y = pt.unpack('l2')
    cr = "\0" * 16
    @get_client_rect.call(hwnd, cr)
    _l, _t, cw, ch = cr.unpack('l4')
    return [-1, -1] if cw <= 0 || ch <= 0
    gx = (raw_x.to_f / cw * Graphics.width).to_i
    gy = (raw_y.to_f / ch * Graphics.height).to_i
    [gx, gy]
  rescue
    [-1, -1]
  end

  def _click_in?(rx, ry, rw, rh)
    return false unless _just_pressed?(VK_LBUTTON)
    mx, my = _mouse_game_pos
    mx >= rx && mx < rx + rw && my >= ry && my < ry + rh
  end

  def main
    _create_sprites
    _filter_results
    _update_all

    NetworkClient.on('ge_item_info')    { |d| _on_item_info(d) }
    NetworkClient.on('ge_order_placed') { |d| _on_order_placed(d) }
    NetworkClient.on('ge_error')        { |d| pbMessage(_INTL("GE: {1}", d['message'].to_s)) }
    NetworkClient.on('ge_order_fill') do |d|
      NetworkGrandExchange._on_order_fill(d)
      _update_list if @tab == :my_orders
    end
    NetworkClient.on('ge_my_orders') do |d|
      NetworkGrandExchange._set_my_orders(d)
      _update_list if @tab == :my_orders
      _update_detail
    end
    NetworkClient.on('ge_claim_update') do |d|
      NetworkGrandExchange._set_claims(d['claim_tokens'], d['claim_items'])
      _update_list if @tab == :my_orders
      _update_detail
    end

    _main_loop

    NetworkClient.off('ge_item_info')
    NetworkClient.off('ge_order_placed')
    NetworkClient.off('ge_error')
    NetworkClient.off('ge_order_fill')
    NetworkClient.off('ge_my_orders')
    NetworkClient.off('ge_claim_update')
    NetworkClient.on('ge_order_fill')   { |d| NetworkGrandExchange._on_order_fill(d) }
    NetworkClient.on('ge_my_orders')    { |d| NetworkGrandExchange._set_my_orders(d) }
    NetworkClient.on('ge_claim_update') { |d| NetworkGrandExchange._set_claims(d['claim_tokens'], d['claim_items']) }

    _dispose
  end

  #=============================================================================
  # Keyboard / mouse (Win32API edge-detect)
  #=============================================================================

  def _update_key_states
    return unless @kb
    (VK_A_KEY..VK_Z_KEY).each { |vk| @key_curr[vk] = (@kb.call(vk) & 0x8000) != 0 }
    [VK_BACK, VK_ENTER, VK_SPACE, VK_LBUTTON].each { |vk| @key_curr[vk] = (@kb.call(vk) & 0x8000) != 0 }
  end

  def _commit_key_states
    @key_prev = @key_curr.dup
  end

  def _just_pressed?(vk)
    return false unless @kb
    @key_curr[vk] == true && @key_prev[vk] != true
  end

  def _process_search_keys
    changed = false
    (VK_A_KEY..VK_Z_KEY).each do |vk|
      if _just_pressed?(vk)
        @search_str += vk.chr
        changed = true
      end
    end
    if _just_pressed?(VK_SPACE) && !@search_str.empty?
      @search_str += ' '
      changed = true
    end
    if _just_pressed?(VK_BACK) && !@search_str.empty?
      @search_str.chop!
      changed = true
    end
    if _just_pressed?(VK_ENTER)
      @search_focused = false
    end
    changed
  end

  #=============================================================================
  # Item filtering (client-side — all GameData::Item objects)
  #=============================================================================

  def _filter_results
    q = @search_str.strip.downcase
    all = []
    GameData::Item.each { |item| all << item }
    @results = if q.empty?
      all.sort_by(&:name)
    else
      all.select { |item| item.name.downcase.include?(q) }
         .sort_by { |i| [i.name.downcase.index(q) || 999, i.name] }
    end
    @result_idx    = 0
    @result_top    = 0
    @selected_item = @results.first
    @item_detail   = nil
    _request_item_detail if @selected_item
  end

  #=============================================================================
  # Sprites
  #=============================================================================

  def _create_sprites
    w      = Graphics.width
    h      = Graphics.height
    list_h = h - HEADER_H - TAB_H - FOOTER_H
    pv_x   = LIST_W + 2
    pv_w   = w - pv_x - 2

    @vp = Viewport.new(0, 0, w, h)
    @vp.z = 99999

    @bg = Sprite.new(@vp)
    @bg.bitmap = Bitmap.new(w, h)
    b = @bg.bitmap
    b.fill_rect(0, 0, w, h, Color.new(10, 10, 26))
    b.fill_rect(0, 0, w, HEADER_H, Color.new(20, 20, 56))
    b.fill_rect(LIST_W, HEADER_H + TAB_H, 2, h - HEADER_H - TAB_H, Color.new(55, 55, 95))
    b.font.size = 17; b.font.bold = true
    pbDrawShadowText(b, 8, 5, w / 2, HEADER_H - 6,
                     "Grand Exchange", Color.new(255, 210, 50), Color.new(0, 0, 0))
    # Close button
    b.fill_rect(CLOSE_BTN_X, CLOSE_BTN_Y, CLOSE_BTN_W, CLOSE_BTN_H, Color.new(120, 30, 30))
    b.fill_rect(CLOSE_BTN_X, CLOSE_BTN_Y, CLOSE_BTN_W, 1, Color.new(200, 60, 60))
    b.fill_rect(CLOSE_BTN_X, CLOSE_BTN_Y + CLOSE_BTN_H - 1, CLOSE_BTN_W, 1, Color.new(200, 60, 60))
    b.fill_rect(CLOSE_BTN_X, CLOSE_BTN_Y, 1, CLOSE_BTN_H, Color.new(200, 60, 60))
    b.fill_rect(CLOSE_BTN_X + CLOSE_BTN_W - 1, CLOSE_BTN_Y, 1, CLOSE_BTN_H, Color.new(200, 60, 60))
    b.font.size = 12; b.font.bold = true
    pbDrawShadowText(b, CLOSE_BTN_X + 2, CLOSE_BTN_Y + 2, CLOSE_BTN_W - 4, CLOSE_BTN_H - 4,
                     "CLOSE", Color.new(255, 150, 150), Color.new(0, 0, 0), 1)
    b.font.size = 11; b.font.bold = false
    pbDrawShadowText(b, 4, h - 18, w - 8, 16,
                     "▲▼:Navigate   Enter:Select   B:Back   Type:Search",
                     Color.new(130, 130, 155), Color.new(0, 0, 0))

    @header_bmp = Sprite.new(@vp)
    @header_bmp.bitmap = Bitmap.new(w, HEADER_H)
    @header_bmp.z = 1
    _redraw_header

    @tab_bmp = Sprite.new(@vp)
    @tab_bmp.bitmap = Bitmap.new(w, TAB_H)
    @tab_bmp.y = HEADER_H

    @search_bmp = Sprite.new(@vp)
    @search_bmp.bitmap = Bitmap.new(LIST_W, 26)
    @search_bmp.x = 0
    @search_bmp.y = HEADER_H + TAB_H + 1

    remaining_h = list_h - 28
    @list_bmp = Sprite.new(@vp)
    @list_bmp.bitmap = Bitmap.new(LIST_W, remaining_h)
    @list_bmp.x = 0
    @list_bmp.y = HEADER_H + TAB_H + 29
    @max_vis = [remaining_h / ICON_H, 1].max

    @detail_bmp = Sprite.new(@vp)
    @detail_bmp.bitmap = Bitmap.new(pv_w, list_h)
    @detail_bmp.x = pv_x
    @detail_bmp.y = HEADER_H + TAB_H
  end

  def _redraw_header
    b = @header_bmp.bitmap; b.clear
    b.font.size = 15; b.font.bold = true
    # Draw only up to the close button area
    pbDrawShadowText(b, 0, 6, CLOSE_BTN_X - 8, HEADER_H - 8,
                     "Tokens: #{NetworkTokens.balance}",
                     Color.new(255, 200, 50), Color.new(0, 0, 0), 2)
  end

  def _update_all
    _update_tabs
    _update_search_field
    _update_list
    _update_detail
  end

  #=============================================================================
  # Tabs
  #=============================================================================

  def _update_tabs
    b = @tab_bmp.bitmap; b.clear
    w = Graphics.width
    b.fill_rect(0, 0, w, TAB_H, Color.new(16, 16, 42))
    b.fill_rect(0, TAB_H - 1, w, 1, Color.new(55, 55, 95))
    b.font.size = 12; b.font.bold = false
    x = 6
    TABS.each do |key, label|
      lbl = label
      lbl = "#{label} (!)" if key == :my_orders && NetworkGrandExchange.has_claims?
      tw = b.text_size(lbl).width + 18
      active = @tab == key
      if active
        b.fill_rect(x, 0, tw, TAB_H - 1, Color.new(38, 38, 85))
        b.fill_rect(x, TAB_H - 2, tw, 2, Color.new(90, 170, 255))
      end
      color = active ? Color.new(255, 255, 255) : Color.new(120, 120, 150)
      pbDrawShadowText(b, x + 5, 3, tw - 10, TAB_H - 6, lbl, color, Color.new(0, 0, 0))
      x += tw + 4
    end
  end

  def _switch_tab(new_tab)
    @tab = new_tab
    @search_focused = false
    _update_tabs; _update_search_field; _update_list; _update_detail
  end

  #=============================================================================
  # Search field
  #=============================================================================

  def _update_search_field
    b = @search_bmp.bitmap; b.clear
    if @tab == :my_orders
      b.fill_rect(0, 0, LIST_W, 26, Color.new(12, 12, 32))
      return
    end
    b.fill_rect(0, 0, LIST_W, 26, Color.new(18, 18, 46))
    bc = @search_focused ? Color.new(90, 160, 255) : Color.new(50, 50, 90)
    b.fill_rect(0, 0, LIST_W, 1, bc); b.fill_rect(0, 25, LIST_W, 1, bc)
    b.fill_rect(0, 0, 1, 26, bc);    b.fill_rect(LIST_W - 1, 0, 1, 26, bc)
    if @search_focused
      display = @search_str + "_"
      color   = Color.new(220, 220, 245)
    elsif @search_str.empty?
      display = "Type to search..."
      color   = Color.new(70, 70, 100)
    else
      display = @search_str
      color   = Color.new(200, 200, 230)
    end
    b.font.size = 12; b.font.bold = false
    pbDrawShadowText(b, 6, 5, LIST_W - 12, 16, display, color, Color.new(0, 0, 0))
  end

  #=============================================================================
  # Results / Orders list
  #=============================================================================

  def _update_list
    b = @list_bmp.bitmap; b.clear
    @tab == :my_orders ? _draw_orders_list(b) : _draw_results_list(b)
  end

  def _draw_results_list(b)
    if @results.empty?
      b.font.size = 12
      msg = @search_str.empty? ? "All items — type to filter." : "No items found."
      pbDrawShadowText(b, 4, 6, LIST_W - 8, 18, msg, Color.new(90, 90, 120), Color.new(0, 0, 0))
      return
    end
    @results.each_with_index do |item, i|
      next if i < @result_top || i >= @result_top + @max_vis
      row = i - @result_top; y = row * ICON_H
      if i == @result_idx
        b.fill_rect(0, y, LIST_W, ICON_H - 1, Color.new(42, 42, 96))
      elsif row.odd?
        b.fill_rect(0, y, LIST_W, ICON_H - 1, Color.new(16, 16, 38))
      end
      _blit_icon(b, 3, y + 2, item)
      b.font.size = 12; b.font.bold = false
      pbDrawShadowText(b, 29, y + 7, LIST_W - 74, 14,
                       item.name, Color.new(215, 215, 235), Color.new(0, 0, 0))
      gp = NetworkGrandExchange.guide_price(item.id.to_s)
      pbDrawShadowText(b, LIST_W - 44, y + 7, 40, 14,
                       "#{gp}T", Color.new(255, 200, 50), Color.new(0, 0, 0), 2)
    end
    _draw_scrollbar(b, @results.length, @result_top)
  end

  def _draw_orders_list(b)
    all = []
    # Claim box always appears first when there are pending claims
    if NetworkGrandExchange.has_claims?
      all << { 'otype' => 'claim',
               'claim_tokens' => NetworkGrandExchange.claim_tokens,
               'claim_items'  => NetworkGrandExchange.claim_items }
    end
    o = NetworkGrandExchange.my_orders
    (o['buy_orders']  || []).each { |x| all << x.merge('otype' => 'buy') }
    (o['sell_orders'] || []).each { |x| all << x.merge('otype' => 'sell') }
    # Sort: claim first, then newest orders first
    all.sort_by! { |x| x['otype'] == 'claim' ? 0 : -(x['ts'].to_i) }
    @order_list = all

    if all.empty?
      b.font.size = 12
      pbDrawShadowText(b, 4, 6, LIST_W - 8, 18,
                       "No open orders.", Color.new(90, 90, 120), Color.new(0, 0, 0))
      return
    end
    @order_top = @order_top.clamp(0, [all.length - @max_vis, 0].max)
    all.each_with_index do |x, i|
      next if i < @order_top || i >= @order_top + @max_vis
      row = i - @order_top; y = row * ICON_H

      if x['otype'] == 'claim'
        bg_col = i == @order_idx ? Color.new(80, 62, 8) : Color.new(50, 38, 5)
        b.fill_rect(0, y, LIST_W, ICON_H - 1, bg_col)
        b.font.size = 11; b.font.bold = true
        pbDrawShadowText(b, 3, y + 3, LIST_W - 6, 12,
                         "CLAIM BOX", Color.new(255, 200, 50), Color.new(0, 0, 0))
        tokens = x['claim_tokens'].to_i
        items  = x['claim_items'] || {}
        parts  = []
        parts << "#{tokens}T" if tokens > 0
        items.each { |_, q| parts << "x#{q.to_i}" if q.to_i > 0 }
        b.font.bold = false
        pbDrawShadowText(b, 3, y + 15, LIST_W - 6, 11,
                         parts.join("  "), Color.new(210, 175, 80), Color.new(0, 0, 0))
      else
        if i == @order_idx
          b.fill_rect(0, y, LIST_W, ICON_H - 1, Color.new(42, 42, 96))
        elsif row.odd?
          b.fill_rect(0, y, LIST_W, ICON_H - 1, Color.new(16, 16, 38))
        end
        lbl  = x['otype'] == 'buy' ? "BUY" : "SELL"
        lclr = x['otype'] == 'buy' ? Color.new(80, 200, 80) : Color.new(200, 90, 90)
        sym   = x['item_id'].to_s.upcase.to_sym
        iname = GameData::Item.exists?(sym) ? GameData::Item.get(sym).name : x['item_id'].to_s
        short = iname.length > 14 ? iname[0..13] + "." : iname
        b.font.size = 11; b.font.bold = true
        pbDrawShadowText(b, 3, y + 3, 30, 12, lbl, lclr, Color.new(0, 0, 0))
        b.font.bold = false
        pbDrawShadowText(b, 35, y + 3, LIST_W - 40, 12,
                         "#{x['qty'].to_i}x #{short}", Color.new(205, 205, 225), Color.new(0, 0, 0))
        pbDrawShadowText(b, 35, y + 15, LIST_W - 40, 11,
                         "@#{x['price_each'].to_i}T  #{x['filled'].to_i}/#{x['qty'].to_i} filled",
                         Color.new(140, 140, 165), Color.new(0, 0, 0))
      end
    end
    _draw_scrollbar(b, all.length, @order_top)
  end

  def _draw_scrollbar(bmp, total, top)
    return unless total > @max_vis
    th = bmp.height
    bh = (th.to_f * @max_vis / total).to_i.clamp(6, th)
    by = (top.to_f / [total - @max_vis, 1].max * (th - bh)).to_i
    bmp.fill_rect(LIST_W - 3, by, 3, bh, Color.new(75, 75, 155))
  end

  #=============================================================================
  # Detail panel (right side)
  #=============================================================================

  def _update_detail
    b = @detail_bmp.bitmap; b.clear
    pw = b.width
    @tab == :my_orders ? _draw_order_detail(b, pw) : _draw_item_detail(b, pw)
  end

  def _draw_item_detail(b, pw)
    return unless @selected_item
    item = @selected_item
    gp   = @item_detail ? @item_detail['guide_price'].to_i : NetworkGrandExchange.guide_price(item.id.to_s)

    b.font.size = 15; b.font.bold = true
    pbDrawShadowText(b, 4, 4, pw - 8, 20, item.name,
                     Color.new(255, 255, 255), Color.new(0, 0, 0))

    icon = _item_icon(item)
    if icon
      src = Rect.new(0, 0, [icon.width, 32].min, [icon.height, 32].min)
      b.stretch_blt(Rect.new(pw / 2 - 20, 28, 40, 40), icon, src) rescue nil
    end

    b.font.size = 15; b.font.bold = true
    pbDrawShadowText(b, 4, 72, pw - 8, 20,
                     "Guide: #{gp}T", Color.new(255, 200, 50), Color.new(0, 0, 0))

    bag_qty = ($bag.quantity(item.id) rescue 0)
    b.font.size = 11; b.font.bold = false
    b.fill_rect(4, b.height - 38, pw - 8, 1, Color.new(50, 50, 85))
    pbDrawShadowText(b, 4, b.height - 34, pw - 8, 12,
                     "In bag: x#{bag_qty}", Color.new(150, 150, 175), Color.new(0, 0, 0))
    pbDrawShadowText(b, 4, b.height - 22, pw - 8, 12,
                     "Enter: Buy / Sell", Color.new(130, 130, 155), Color.new(0, 0, 0))
  end

  def _draw_order_detail(b, pw)
    ol = @order_list || []
    return if ol.empty? || @order_idx >= ol.length
    x = ol[@order_idx]

    if x['otype'] == 'claim'
      _draw_claim_detail(b, pw, x)
      return
    end

    ot     = x['otype']
    sym    = x['item_id'].to_s.upcase.to_sym
    iname  = GameData::Item.exists?(sym) ? GameData::Item.get(sym).name : x['item_id'].to_s
    filled = x['filled'].to_i; total = x['qty'].to_i; price = x['price_each'].to_i
    remain = total - filled

    b.font.size = 14; b.font.bold = true
    lc = ot == 'buy' ? Color.new(80, 200, 80) : Color.new(200, 90, 90)
    pbDrawShadowText(b, 4, 4, pw - 8, 18,
                     "#{ot == 'buy' ? 'BUY' : 'SELL'}: #{iname}", lc, Color.new(0, 0, 0))
    b.font.size = 12; b.font.bold = false
    pbDrawShadowText(b, 4, 26, pw - 8, 14, "Qty: #{total}   @#{price}T each",
                     Color.new(200, 200, 220), Color.new(0, 0, 0))
    pbDrawShadowText(b, 4, 42, pw - 8, 14, "Filled: #{filled}/#{total}",
                     Color.new(160, 160, 185), Color.new(0, 0, 0))
    if remain > 0
      pbDrawShadowText(b, 4, 58, pw - 8, 14, "Remaining: #{remain}",
                       Color.new(160, 160, 185), Color.new(0, 0, 0))
      b.font.size = 11
      b.fill_rect(4, b.height - 22, pw - 8, 1, Color.new(50, 50, 85))
      pbDrawShadowText(b, 4, b.height - 18, pw - 8, 14,
                       "Enter: Cancel Order", Color.new(130, 130, 155), Color.new(0, 0, 0))
    end
  end

  def _draw_claim_detail(b, pw, x)
    tokens = x['claim_tokens'].to_i
    items  = x['claim_items'] || {}

    b.font.size = 15; b.font.bold = true
    pbDrawShadowText(b, 4, 4, pw - 8, 20, "Claim Box",
                     Color.new(255, 200, 50), Color.new(0, 0, 0))

    b.font.size = 12; b.font.bold = false
    y = 28
    if tokens > 0
      pbDrawShadowText(b, 4, y, pw - 8, 14, "Tokens: #{tokens}T",
                       Color.new(255, 215, 80), Color.new(0, 0, 0))
      y += 16
    end
    items.each do |item_id, qty|
      sym   = item_id.to_s.upcase.to_sym rescue nil
      iname = (GameData::Item.exists?(sym) ? GameData::Item.get(sym).name : item_id.to_s) rescue item_id.to_s
      pbDrawShadowText(b, 4, y, pw - 8, 14, "#{qty.to_i}x #{iname}",
                       Color.new(200, 200, 220), Color.new(0, 0, 0))
      y += 14
    end

    b.font.size = 11
    b.fill_rect(4, b.height - 22, pw - 8, 1, Color.new(50, 50, 85))
    pbDrawShadowText(b, 4, b.height - 18, pw - 8, 14,
                     "Enter: Collect all", Color.new(130, 130, 155), Color.new(0, 0, 0))
  end

  #=============================================================================
  # Icon helpers
  #=============================================================================

  def _item_icon(item)
    return @icon_cache[item.id] if @icon_cache.key?(item.id)
    bmp = nil
    begin
      fname = item.icon_filename
      if fname && !fname.empty?
        bmp = RPG::Cache.load_bitmap("Graphics/Items/", fname) rescue nil
        bmp ||= Bitmap.new("Graphics/Items/#{fname}.png") rescue nil
      end
    rescue
    end
    @icon_cache[item.id] = bmp
    bmp
  end

  def _blit_icon(bitmap, x, y, item)
    icon = _item_icon(item)
    return unless icon
    src = Rect.new(0, 0, [icon.width, 24].min, [icon.height, 24].min)
    bitmap.blt(x, y, icon, src)
  rescue
  end

  #=============================================================================
  # Server interaction
  #=============================================================================

  def _request_item_detail
    return unless @selected_item
    NetworkClient.send_msg({ action: 'ge_item_info', item_id: @selected_item.id.to_s })
  end

  def _on_item_info(d)
    return unless @selected_item
    return unless d['item_id'].to_s.upcase == @selected_item.id.to_s.upcase
    @item_detail = d
    _update_detail
  end

  def _on_order_placed(d)
    NetworkClient.send_msg({ action: 'ge_my_orders' })
    _request_item_detail if @selected_item
    _redraw_header
  end

  def _item_changed
    @selected_item = @results[@result_idx]
    @item_detail   = nil
    _update_list; _update_detail
    _request_item_detail if @selected_item
  end

  #=============================================================================
  # Order placement
  #=============================================================================

  def _show_action_menu
    return unless @selected_item
    choice = pbMessage(_INTL("{1}", @selected_item.name),
                       [_INTL("Buy"), _INTL("Sell"), _INTL("Cancel")], 3)
    _place_order_flow(:buy)  if choice == 0
    _place_order_flow(:sell) if choice == 1
    _update_detail
  end

  def _place_order_flow(type)
    item = @selected_item; return unless item
    bag_qty = ($bag.quantity(item.id) rescue 0)
    if type == :sell && bag_qty <= 0
      pbMessage(_INTL("You have no {1} to sell.", item.name)); return
    end

    max_qty = type == :sell ? bag_qty : MAX_QTY
    gp      = @item_detail ? @item_detail['guide_price'].to_i : NetworkGrandExchange.guide_price(item.id.to_s)

    qty   = _spinner("How many to #{type}?#{type == :sell ? " (max: #{max_qty})" : ""}", 1, max_qty, 1)
    return unless qty
    price = _spinner("Price per unit (tokens):", gp.clamp(1, 99999), 99999, gp.clamp(1, 99999))
    return unless price

    total    = qty * price
    type_str = type == :buy ? "Buy" : "Sell"

    if type == :buy && NetworkTokens.balance < total
      pbMessage(_INTL("Need {1}T but you only have {2}T.", total, NetworkTokens.balance)); return
    end

    return if pbMessage(
      _INTL("{1} x{2} {3} @ {4}T each?", type_str, qty, item.name, price),
      [_INTL("Confirm"), _INTL("Cancel")], 2
    ) != 0

    if type == :sell
      actual_qty = ($bag.quantity(item.id) rescue 0)
      if actual_qty < qty
        pbMessage(_INTL("Not enough {1} in bag.", item.name)); return
      end
      $bag.remove(item.id, qty) rescue nil
    end

    _submit_order(type, item.id.to_s, qty, price)
  end

  def _submit_order(type, item_id, qty, price)
    result = nil
    NetworkClient.on('ge_order_placed') { |_d| result ||= :ok }
    NetworkClient.on('ge_error')        { |d|  result ||= d['message'].to_s }
    NetworkClient.send_msg({ action: type == :buy ? 'ge_place_buy' : 'ge_place_sell',
                             item_id: item_id, qty: qty, price_each: price })
    300.times { Graphics.update; Input.update; NetworkClient.update; break if result }
    NetworkClient.off('ge_order_placed')
    NetworkClient.off('ge_error')
    NetworkClient.on('ge_order_placed') { |d| _on_order_placed(d) }
    NetworkClient.on('ge_error')        { |d| pbMessage(_INTL("GE: {1}", d['message'].to_s)) }

    if result == :ok
      pbMessage(_INTL("Order placed! Check My Orders to collect when filled."))
    else
      msg = result.is_a?(String) ? result : "No response from server."
      pbMessage(_INTL("Order failed: {1}", msg))
      $bag.add(item_id.to_sym, qty) rescue nil if type == :sell
    end
    _redraw_header
  end

  def _cancel_selected_order
    ol = @order_list || []; return if ol.empty? || @order_idx >= ol.length
    x      = ol[@order_idx]
    return if x['otype'] == 'claim'
    remain = x['qty'].to_i - x['filled'].to_i
    return if remain <= 0

    sym   = x['item_id'].to_s.upcase.to_sym
    iname = GameData::Item.exists?(sym) ? GameData::Item.get(sym).name : x['item_id'].to_s
    return if pbMessage(
      _INTL("Cancel {1} order?\n{2}x {3} ({4} unfilled)",
            x['otype'], x['qty'].to_i, iname, remain),
      [_INTL("Yes"), _INTL("No")], 2
    ) != 0

    result = nil
    NetworkClient.on('ge_order_cancelled') { |_d| result ||= :ok }
    NetworkClient.on('ge_error')           { |d|  result ||= d['message'].to_s }
    NetworkClient.send_msg({ action: 'ge_cancel_order',
                             order_id: x['id'], order_type: x['otype'] })
    300.times { Graphics.update; Input.update; NetworkClient.update; break if result }
    NetworkClient.off('ge_order_cancelled')
    NetworkClient.off('ge_error')
    NetworkGrandExchange.register_cancel_handler
    NetworkClient.on('ge_error') { |d| pbMessage(_INTL("GE: {1}", d['message'].to_s)) }

    if result == :ok
      msg = x['otype'] == 'buy' ? "Order cancelled. Tokens refunded." : "Order cancelled. Items returned."
      pbMessage(_INTL(msg))
      NetworkClient.send_msg({ action: 'ge_my_orders' })
      @order_idx = [@order_idx - 1, 0].max
    else
      pbMessage(_INTL("Failed: {1}", result.is_a?(String) ? result : "No response."))
    end
    _redraw_header
  end

  def _collect_claims
    return unless NetworkGrandExchange.has_claims?

    claim_data = nil
    err_msg    = nil
    NetworkClient.on('ge_claim_result') { |d| claim_data ||= d }
    NetworkClient.on('ge_error')        { |d| err_msg    ||= d['message'].to_s }
    NetworkClient.send_msg({ action: 'ge_claim' })
    300.times { Graphics.update; Input.update; NetworkClient.update; break if claim_data || err_msg }
    NetworkClient.off('ge_claim_result')
    NetworkClient.off('ge_error')
    NetworkClient.on('ge_error') { |d| pbMessage(_INTL("GE: {1}", d['message'].to_s)) }

    if claim_data
      tokens = claim_data['tokens'].to_i
      items  = claim_data['items'] || {}
      items.each do |item_id, qty|
        sym = item_id.to_s.upcase.to_sym rescue nil
        next unless sym && GameData::Item.exists?(sym)
        $bag.add(sym, qty.to_i) rescue nil
      end
      Game.save(safe: true) rescue nil
      NetworkGrandExchange._set_claims(0, {})

      parts = []
      parts << "#{tokens}T" if tokens > 0
      items.each do |item_id, qty|
        sym   = item_id.to_s.upcase.to_sym rescue nil
        iname = (GameData::Item.exists?(sym) ? GameData::Item.get(sym).name : item_id.to_s) rescue item_id.to_s
        parts << "#{qty.to_i}x #{iname}"
      end
      pbMessage(_INTL("Collected: {1}!", parts.join(", "))) if parts.any?

      _redraw_header
      _update_tabs
      NetworkClient.send_msg({ action: 'ge_my_orders' })
      @order_idx = 0
    else
      pbMessage(_INTL("Failed: {1}", err_msg || "No response."))
    end
  end

  #=============================================================================
  # Spinner overlay (quantity or price)
  #=============================================================================

  def _spinner(label, start_val, max_val, default_val = nil)
    val       = (default_val || start_val).clamp(1, max_val)
    confirmed = false
    bw = 270; bh = 100

    vp  = Viewport.new(0, 0, Graphics.width, Graphics.height)
    vp.z = @vp.z + 1
    dim = Sprite.new(vp)
    dim.bitmap = Bitmap.new(Graphics.width, Graphics.height)
    dim.bitmap.fill_rect(0, 0, Graphics.width, Graphics.height, Color.new(0, 0, 0, 160))
    box = Sprite.new(vp)
    box.bitmap = Bitmap.new(bw, bh)
    box.x = Graphics.width / 2 - bw / 2
    box.y = Graphics.height / 2 - bh / 2

    draw = lambda do
      b = box.bitmap; b.clear
      b.fill_rect(0, 0, bw, bh, Color.new(18, 18, 50))
      [[0, 0, bw, 2], [0, bh - 2, bw, 2], [0, 0, 2, bh], [bw - 2, 0, 2, bh]].each do |rx, ry, rw, rh|
        b.fill_rect(rx, ry, rw, rh, Color.new(80, 80, 180))
      end
      b.font.bold = false; b.font.size = 13
      pbDrawShadowText(b, 4, 6, bw - 8, 18, label,
                       Color.new(190, 190, 215), Color.new(0, 0, 0), 1)
      pbDrawShadowText(b, 0, 20, bw, 14, "▲",
                       Color.new(130, 130, 175), Color.new(0, 0, 0), 1)
      b.font.bold = true; b.font.size = 30
      pbDrawShadowText(b, 0, 34, bw, 32, val.to_s,
                       Color.new(255, 200, 50), Color.new(0, 0, 0), 1)
      b.font.bold = false; b.font.size = 11
      pbDrawShadowText(b, 0, 82, bw, 14, "▲▼:+/-1  ◄►:+/-10  Enter:OK  B:Cancel",
                       Color.new(120, 120, 145), Color.new(0, 0, 0), 1)
    end
    draw.call

    loop do
      Graphics.update; Input.update
      prev = val
      val = [val + 1,   max_val].min if Input.repeat?(Input::UP)
      val = [val - 1,   1].max       if Input.repeat?(Input::DOWN)
      val = [val + 10,  max_val].min if Input.repeat?(Input::RIGHT)
      val = [val - 10,  1].max       if Input.repeat?(Input::LEFT)
      draw.call if val != prev
      if Input.trigger?(Input::USE);  confirmed = true; break; end
      break if Input.trigger?(Input::BACK)
    end
    dim.dispose; box.dispose; vp.dispose
    confirmed ? val : nil
  end

  #=============================================================================
  # Main loop
  #=============================================================================

  def _main_loop
    @running = true
    while @running
      Graphics.update
      Input.update
      NetworkClient.update if NetworkClient.connected?
      _update_key_states

      # Mouse click on close button — always works, even while search focused
      if _click_in?(CLOSE_BTN_X, CLOSE_BTN_Y, CLOSE_BTN_W, CLOSE_BTN_H)
        @running = false
        _commit_key_states
        break
      end

      if @search_focused
        changed = _process_search_keys
        if changed
          _filter_results
          _update_list; _update_detail
        end
        _update_search_field
      else
        if @tab == :search
          letter = (VK_A_KEY..VK_Z_KEY).find { |vk| _just_pressed?(vk) }
          if letter
            @search_focused = true
            @search_str    += letter.chr
            _filter_results
            _update_search_field; _update_list; _update_detail
          end
        end
        _handle_navigation unless @search_focused
      end

      _commit_key_states
    end
  end

  def _handle_navigation
    if Input.trigger?(Input::LEFT) || Input.trigger?(Input::RIGHT)
      idx = TABS.index { |k, _| k == @tab } || 0
      _switch_tab(TABS[(idx + 1) % TABS.length][0])
      return
    end
    @tab == :my_orders ? _handle_orders_nav : _handle_search_nav
    @running = false if Input.trigger?(Input::BACK)
  end

  def _handle_search_nav
    if Input.repeat?(Input::UP) && @result_idx > 0
      @result_idx -= 1
      @result_top  = @result_idx if @result_idx < @result_top
      _item_changed
    elsif Input.repeat?(Input::DOWN) && @result_idx < @results.length - 1
      @result_idx += 1
      @result_top  = @result_idx - @max_vis + 1 if @result_idx >= @result_top + @max_vis
      _item_changed
    elsif Input.trigger?(Input::USE)
      if @results.empty?
        @search_focused = true
        _update_search_field
      else
        _show_action_menu
      end
    end
  end

  def _handle_orders_nav
    list = @order_list || []
    if Input.repeat?(Input::UP) && @order_idx > 0
      @order_idx -= 1
      @order_top  = @order_idx if @order_idx < @order_top
      _update_list; _update_detail
    elsif Input.repeat?(Input::DOWN) && @order_idx < list.length - 1
      @order_idx += 1
      @order_top  = @order_idx - @max_vis + 1 if @order_idx >= @order_top + @max_vis
      _update_list; _update_detail
    elsif Input.trigger?(Input::USE) && !list.empty?
      x = list[@order_idx]
      if x && x['otype'] == 'claim'
        _collect_claims
      else
        _cancel_selected_order
      end
    end
  end

  #=============================================================================
  # Cleanup
  #=============================================================================

  def _dispose
    @icon_cache.each_value { |bmp| bmp&.dispose rescue nil }
    @bg.dispose; @header_bmp.dispose; @tab_bmp.dispose
    @search_bmp.dispose; @list_bmp.dispose; @detail_bmp.dispose
    @vp.dispose
  end
end
