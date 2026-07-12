#===============================================================================
# NetworkTokens — client-side Server Token balance.
#
# Tokens are earned by:
#   - 1 token per 30 minutes of continuous server play
#   - 1 token for finding the roaming Gen 3 spawn
#   - 1 token for catching or defeating the roaming spawn in battle
#
# The server is authoritative. Balance is synced on login and updated
# live via token_update events. Not stored in the save file.
#
# Read the balance anywhere with:
#   NetworkTokens.balance   # => Integer
#===============================================================================

module NetworkTokens
  @balance         = 0
  @daily_available = false

  def self.balance;           @balance;         end
  def self.daily_available;   @daily_available; end
  def self.daily_available=(v); @daily_available = (v == true); end

  def self.set(amount)
    @balance = amount.to_i
  end

  def self.add(amount)
    @balance += amount.to_i
  end

  # Spends Server Tokens to add one more Pokémon storage box, up to
  # Settings::MAX_STORAGE_BOXES. Returns true if a box was bought.
  def self.buy_storage_box
    unless NetworkAuth.logged_in?
      pbMessage(_INTL("You need to be online to buy storage boxes."))
      return false
    end
    if $PokemonStorage.maxBoxes >= Settings::MAX_STORAGE_BOXES
      pbMessage(_INTL("Storage is already at the maximum of {1} boxes.", Settings::MAX_STORAGE_BOXES))
      return false
    end
    cost = Settings::STORAGE_BOX_TOKEN_COST
    if @balance < cost
      pbMessage(_INTL("Not enough tokens.\nYou have {1}, need {2}.", @balance, cost))
      return false
    end
    return false if pbMessage(
      _INTL("Buy 1 more Pokémon Box for {1} token(s)?\n({2}/{3} boxes)",
            cost, $PokemonStorage.maxBoxes, Settings::MAX_STORAGE_BOXES),
      [_INTL("Yes"), _INTL("No")], 2
    ) != 0

    result = nil
    NetworkClient.on('storage_box_bought') { |d| result = d }
    NetworkClient.on('storage_box_error')  { |d| result = { '_err' => d['message'] } }
    NetworkClient.send_msg({ action: 'buy_storage_box' })
    300.times { Graphics.update; Input.update; NetworkClient.update; break if result }
    NetworkClient.off('storage_box_bought'); NetworkClient.off('storage_box_error')

    if result.is_a?(Hash) && !result['_err']
      NetworkTokens.set(result['new_tokens'])
      $PokemonStorage.addBox
      Game.save(safe: true) rescue nil
      pbMessage(_INTL("Box added! You now have {1} boxes.", $PokemonStorage.maxBoxes))
      pbGiveAchievementOnce(16) if $PokemonStorage.maxBoxes >= Settings::MAX_STORAGE_BOXES
      return true
    else
      pbMessage(_INTL("Purchase failed: {1}",
                      result.is_a?(Hash) ? (result['_err'] || "Unknown error.") : "No response."))
      return false
    end
  end

  # Spends Server Tokens to have the server confirm payment for an instant
  # finish of the player's whole queued Kurt Ball order. Only the token spend
  # is server-authoritative here — actually marking the jobs ready is local
  # save data, handled by the caller (see KurtEventPage#call in
  # 022_Plugins/001_Apricorn_Converter/001_ApricornToBall.rb) once this
  # returns true.
  def self.buy_instant_kurt
    unless NetworkAuth.logged_in?
      pbMessage(_INTL("You need to be online to do this."))
      return false
    end
    cost = Settings::KURT_INSTANT_TOKEN_COST
    if @balance < cost
      pbMessage(_INTL("Not enough tokens.\nYou have {1}, need {2}.", @balance, cost))
      return false
    end
    return false if pbMessage(
      _INTL("Pay {1} token(s) to finish your entire order right now?", cost),
      [_INTL("Yes"), _INTL("No")], 2
    ) != 0

    result = nil
    NetworkClient.on('kurt_instant_bought') { |d| result = d }
    NetworkClient.on('kurt_instant_error')  { |d| result = { '_err' => d['message'] } }
    NetworkClient.send_msg({ action: 'buy_instant_kurt' })
    300.times { Graphics.update; Input.update; NetworkClient.update; break if result }
    NetworkClient.off('kurt_instant_bought'); NetworkClient.off('kurt_instant_error')

    if result.is_a?(Hash) && !result['_err']
      NetworkTokens.set(result['new_tokens'])
      return true
    else
      pbMessage(_INTL("Purchase failed: {1}",
                      result.is_a?(Hash) ? (result['_err'] || "Unknown error.") : "No response."))
      return false
    end
  end
end

#-------------------------------------------------------------------------------
# Server event: balance sent on login_ok (handled in NetworkAuth).
# Server event: token_update — server awarded us tokens.
#-------------------------------------------------------------------------------
NetworkClient.on('token_update') do |data|
  NetworkTokens.set(data['tokens'])
  puts "[Tokens] +#{data['amount']} (#{data['reason']}) → balance: #{NetworkTokens.balance}"
end

#-------------------------------------------------------------------------------
# Persistent market_sold handler — keeps the token balance in sync whenever
# another player buys one of our listings, even outside the market scene.
# Scene_NetworkMarket calls off('market_sold') on exit and then calls this
# method to restore the global handler.
#-------------------------------------------------------------------------------
def NetworkTokens.register_market_sold_handler
  NetworkClient.on('market_sold') { |d| NetworkTokens.set(d['new_tokens']) }
end
NetworkTokens.register_market_sold_handler

#===============================================================================
# Scene_DailyWheel — spinning drum reward picker for the daily login bonus.
#
# Opened automatically from NetworkAuth._try_login when login_ok includes
# daily_available: true. The server picks the winning segment and awards
# tokens/item immediately; the client animates to that segment then shows
# a collect confirmation.
#===============================================================================
class Scene_DailyWheel
  # Must match WHEEL array in handlers/dailylogin.js (same index order).
  WHEEL = [
    { type: :tokens, amount: 1  },   # 0
    { type: :tokens, amount: 5  },   # 1
    { type: :tokens, amount: 1  },   # 2
    { type: :tokens, amount: 10 },   # 3
    { type: :item                },  # 4
    { type: :tokens, amount: 1  },   # 5
    { type: :tokens, amount: 5  },   # 6
    { type: :tokens, amount: 25 },   # 7
    { type: :tokens, amount: 1  },   # 8
    { type: :tokens, amount: 10 },   # 9
    { type: :tokens, amount: 5  },   # 10
    { type: :tokens, amount: 1  },   # 11
  ].freeze

  SLOT_H  = 30
  VISIBLE = 5
  DRUM_W  = 180
  PANEL_W = 240
  PANEL_H = 220
  DRUM_H  = SLOT_H * VISIBLE
  REPEATS = 7

  attr_reader :result

  def main
    _create_ui
    @state       = :idle
    @scroll      = 0.0
    @target      = 0.0
    @spin_frames = 0
    @total_spin  = 150
    @result      = nil
    @drum_list   = _build_drum_list

    _draw_drum(0)
    _draw_footer("Press Enter to Spin!")

    loop do
      Graphics.update
      Input.update
      NetworkClient.update

      case @state
      when :idle
        _request_spin if Input.trigger?(Input::USE)
      when :spinning
        _update_spin
      when :done
        if Input.trigger?(Input::USE)
          _collect_result
          break
        end
      end
    end
  rescue StandardError => e
    # Logged (unconditionally, not just in $DEBUG) rather than left for the
    # caller's blanket `rescue nil` to silently swallow — that swallow is
    # exactly why a real-network-only failure here was invisible before.
    _log_error("main", e)
  ensure
    _dispose
  end

  private

  # ── UI construction ─────────────────────────────────────────────────────────

  def _create_ui
    # Use Settings constants (not Graphics.width/height) — avoids DPI-scale mismatch
    # where Graphics.width may return the physical pixel size at class-load time vs
    # the logical game size at runtime.
    sw = Settings::SCREEN_WIDTH
    sh = Settings::SCREEN_HEIGHT
    @panel_x = (sw - PANEL_W) / 2
    @panel_y = (sh - PANEL_H) / 2 - 5
    @drum_x  = @panel_x + (PANEL_W - DRUM_W) / 2
    @drum_y  = @panel_y + 46

    @vp = Viewport.new(0, 0, sw, sh)
    @vp.z = 100000  # above the pause menu's viewport (z=99999) so it's never drawn behind it

    # Dark overlay + panel
    @bg_sp = Sprite.new(@vp)
    bmp = Bitmap.new(sw, sh)
    bmp.fill_rect(0, 0, sw, sh, Color.new(0, 0, 0, 160))
    # Panel border (gold)
    bmp.fill_rect(@panel_x - 2, @panel_y - 2, PANEL_W + 4, PANEL_H + 4, Color.new(200, 180, 60))
    # Panel body
    bmp.fill_rect(@panel_x, @panel_y, PANEL_W, PANEL_H, Color.new(18, 18, 55))
    # Title bar
    bmp.fill_rect(@panel_x, @panel_y, PANEL_W, 34, Color.new(30, 30, 90))
    bmp.font.size  = 15
    bmp.font.bold  = true
    bmp.font.color = Color.new(255, 215, 0)
    bmp.draw_text(@panel_x, @panel_y + 7, PANEL_W, 20, "Daily Login Bonus!", 1)
    @bg_sp.bitmap = bmp

    # Drum sprite (redrawn each frame during spin)
    @drum_bmp = Bitmap.new(DRUM_W, DRUM_H)
    @drum_sp  = Sprite.new(@vp)
    @drum_sp.bitmap = @drum_bmp
    @drum_sp.x = @drum_x
    @drum_sp.y = @drum_y

    # Gold pointer lines flanking the center slot
    [@drum_y + SLOT_H * 2, @drum_y + SLOT_H * 3].each do |line_y|
      s = Sprite.new(@vp)
      s.bitmap = Bitmap.new(DRUM_W + 12, 2)
      s.bitmap.fill_rect(0, 0, DRUM_W + 12, 2, Color.new(255, 215, 0))
      s.x = @drum_x - 6
      s.y = line_y
      (@ptr_lines ||= []) << s
    end

    # Footer bar
    @footer_bmp = Bitmap.new(PANEL_W - 12, 22)
    @footer_sp  = Sprite.new(@vp)
    @footer_sp.bitmap = @footer_bmp
    @footer_sp.x = @panel_x + 6
    @footer_sp.y = @panel_y + PANEL_H - 30
  end

  # Defensive on two counts: (1) @vp.dispose goes FIRST so the full-screen
  # overlay actually disappears immediately even if a later line below raises;
  # with the old bottom-of-the-method ordering, any exception partway through
  # (e.g. because _create_ui itself never finished and left something nil)
  # meant @vp.dispose never ran at all, leaving a dead, unresponsive overlay
  # stuck on screen forever. (2) every dispose is nil/already-disposed safe,
  # since this runs from an `ensure` and can't assume a clean prior state.
  def _dispose
    @vp&.dispose
    @bg_sp&.bitmap&.dispose
    @bg_sp&.dispose
    @drum_bmp&.dispose
    @drum_sp&.dispose
    (@ptr_lines || []).each { |s| s&.bitmap&.dispose; s&.dispose }
    @footer_bmp&.dispose
    @footer_sp&.dispose
  rescue StandardError => e
    _log_error("_dispose", e)
  end

  # Unconditional (not gated behind $DEBUG) so a real cross-device failure is
  # actually visible in production, not just in dev/test builds.
  def _log_error(where, e)
    File.open("Data/network_error_log.txt", "a+b") do |f|
      f.write("[#{Time.now.strftime('%Y-%m-%d %H:%M:%S')}] Scene_DailyWheel##{where}: #{e.class}: #{e.message}\r\n")
      f.write(e.backtrace.join("\r\n") + "\r\n") if e.backtrace
    end
  rescue StandardError
    nil
  end

  # ── Drum drawing ─────────────────────────────────────────────────────────────

  def _seg_label(seg)
    return "+#{seg[:amount]} Token#{seg[:amount] == 1 ? '' : 's'}" if seg[:type] == :tokens
    "Random Item"
  end

  def _build_drum_list
    (REPEATS * WHEEL.size).times.map { |i| WHEEL[i % WHEEL.size] }
  end

  def _draw_drum(scroll)
    offset    = scroll.to_i
    first_idx = offset / SLOT_H
    pixel_off = offset % SLOT_H

    @drum_bmp.clear
    @drum_bmp.fill_rect(0, 0, DRUM_W, DRUM_H, Color.new(12, 12, 45))
    # Center-slot highlight band
    @drum_bmp.fill_rect(0, SLOT_H * 2, DRUM_W, SLOT_H, Color.new(35, 35, 100))

    (VISIBLE + 1).times do |i|
      idx = first_idx + i
      next if idx >= @drum_list.size
      y = i * SLOT_H - pixel_off
      next if y + SLOT_H <= 0 || y >= DRUM_H

      seg   = @drum_list[idx]
      label = _seg_label(seg)
      in_center = (y + SLOT_H > SLOT_H * 2) && (y < SLOT_H * 3)

      @drum_bmp.font.size  = 14
      @drum_bmp.font.bold  = in_center
      @drum_bmp.font.color = in_center ? Color.new(255, 240, 80) : Color.new(190, 190, 210)
      @drum_bmp.draw_text(4, y + 7, DRUM_W - 8, SLOT_H - 10, label, 1)
    end
  end

  # ── Footer ────────────────────────────────────────────────────────────────────

  def _draw_footer(text)
    @footer_bmp.clear
    @footer_bmp.font.size  = 12
    @footer_bmp.font.bold  = false
    @footer_bmp.font.color = Color.new(190, 190, 210)
    @footer_bmp.draw_text(0, 2, @footer_bmp.width, 18, text, 1)
  end

  # ── Spin flow ─────────────────────────────────────────────────────────────────

  def _request_spin
    @state = :waiting
    _draw_footer("Connecting to server...")

    result = nil
    NetworkClient.on('daily_spin_result') { |d| result ||= d }
    NetworkClient.send_msg({ action: 'daily_spin' })

    # 300 frames (~5s), matching the wait used everywhere else in this
    # codebase (login, market, battle sync). 120 (~2s) was too tight for a
    # real cross-device round trip plus the server's DB write.
    300.times { Graphics.update; Input.update; NetworkClient.update; break if result }
    NetworkClient.off('daily_spin_result')

    unless result
      _draw_footer("No server response. Try again.")
      @state = :idle
      return
    end

    if result['error']
      _draw_footer("#{result['error']}")
      @state = :done
      return
    end

    @result = result
    _start_spin(result['segment'].to_i)
  end

  def _start_spin(winning_segment)
    # 5 full rotations, then land winner at center (slot index 2)
    target_item_idx = 5 * WHEEL.size + winning_segment
    @target      = (target_item_idx - 2) * SLOT_H
    @scroll      = 0.0
    @spin_frames = 0
    @state       = :spinning
    _draw_footer("Spinning...")
  end

  def _update_spin
    @spin_frames += 1
    progress = [@spin_frames.to_f / @total_spin, 1.0].min
    # Cubic ease-out: fast start, smooth landing
    ease    = 1.0 - (1.0 - progress) ** 3
    @scroll = @target * ease
    _draw_drum(@scroll)

    if @spin_frames >= @total_spin
      @scroll = @target
      _draw_drum(@scroll)
      @state = :done
      _draw_result_footer
    end
  end

  def _draw_result_footer
    r = @result
    return unless r
    if r['item_id']
      sym  = r['item_id'].to_s.upcase.to_sym rescue nil
      name = (sym && GameData::Item.exists?(sym)) ? GameData::Item.get(sym).name : r['item_id'].to_s
      _draw_footer("Won a #{name}! Press Enter.")
    elsif r['tokens'].to_i > 0
      t = r['tokens'].to_i
      _draw_footer("Won +#{t} Token#{t == 1 ? '' : 's'}! Press Enter.")
    else
      _draw_footer("Press Enter to close.")
    end
  end

  # ── Collect & close ───────────────────────────────────────────────────────────

  def _collect_result
    r = @result
    NetworkTokens.daily_available = false
    return unless r && !r['error']
    # Apply item reward to bag silently. Token reward is already credited by the
    # server's token_update event. The pbMessage confirmation is shown by the
    # caller (_try_login) after this scene is fully disposed — calling pbMessage
    # here while @vp (z=9000) is still active hides the dialog behind the wheel.
    if r['item_id']
      sym = r['item_id'].to_s.upcase.to_sym rescue nil
      if sym && GameData::Item.exists?(sym)
        $bag.add(sym, 1) rescue nil
        Game.save(safe: true) rescue nil
      end
    end
  end
end
