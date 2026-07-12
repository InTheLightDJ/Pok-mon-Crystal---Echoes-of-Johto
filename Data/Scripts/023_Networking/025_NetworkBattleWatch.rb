#===============================================================================
# NetworkBattleWatch — read-only admin spectator view for a live PvP battle.
#
# Triggered by the server after a mod/admin runs `WatchBattle.Username` via the
# web/chat command bar (see ServerStuff/chat_server.js + handlers/battle.js
# registerSpectator). This client never sends anything into the battle itself —
# there is no message path from spectator back to either combatant, so it is
# structurally impossible for watching to affect the match.
#
# The view opens automatically once it's safe to do so (overworld, no event
# running) and shows both Pokémon's name/species/level/HP/status, refreshed
# every round via admin_battle_update. It closes when:
#   - the admin presses B (sends admin_stop_watching so the server drops the
#     spectator slot immediately), or
#   - the battle ends naturally (admin_battle_ended).
#===============================================================================
module NetworkBattleWatch
  @pending = nil   # snapshot waiting for a safe moment to open
  @active  = false

  def self.active?
    @active
  end

  def self.queue_snapshot(data)
    @pending = data
  end

  # Called every frame; opens the view the moment it's safe to do so.
  def self.tick
    return if @active
    return unless @pending
    return unless $scene.is_a?(Scene_Map)
    return if $game_system.map_interpreter.running?
    snapshot = @pending
    @pending = nil
    _run(snapshot)
  end

  def self._run(snapshot)
    @active = true
    Scene_BattleWatch.new(snapshot).main
  ensure
    @active = false
  end
end

NetworkClient.on('admin_battle_snapshot') { |d| NetworkBattleWatch.queue_snapshot(d) }

EventHandlers.add(:on_frame_update, :network_battle_watch_tick,
  proc { NetworkBattleWatch.tick if NetworkClient.connected? }
)

#===============================================================================
# Scene_BattleWatch — renders the spectator HUD.
#===============================================================================
class Scene_BattleWatch
  PANEL_W = 260
  PANEL_H = 150

  STATUS_ABBR = {
    'SLEEP'     => 'SLP', 'POISON' => 'PSN', 'BURN'  => 'BRN',
    'PARALYSIS' => 'PAR', 'FROZEN' => 'FRZ', 'FAINT' => 'FNT',
  }

  def initialize(snapshot)
    @battle_id       = snapshot['battle_id']
    @challenger_name = snapshot['challenger_name'] || '?'
    @opponent_name   = snapshot['opponent_name']   || '?'
    @hp              = snapshot['hp']   # [{ 'hp','totalhp','status','name','species','level' }, ...] or nil
    @ended           = false
  end

  def main
    _create_ui
    _draw

    @update_cb = NetworkClient.on('admin_battle_update') do |d|
      @hp = d['hp'] if d['battle_id'] == @battle_id
      _draw
    end
    @ended_cb = NetworkClient.on('admin_battle_ended') do |_d|
      @ended = true
      _draw
    end

    loop do
      Graphics.update
      Input.update
      NetworkClient.update
      if Input.trigger?(Input::BACK)
        NetworkClient.send_msg({ action: 'admin_stop_watching' })
        break
      end
      break if @ended && Input.trigger?(Input::USE)
    end
  ensure
    NetworkClient.remove('admin_battle_update', @update_cb) if @update_cb
    NetworkClient.remove('admin_battle_ended',  @ended_cb)  if @ended_cb
    _dispose
  end

  private

  def _create_ui
    sw = Settings::SCREEN_WIDTH
    sh = Settings::SCREEN_HEIGHT
    @panel_x = (sw - PANEL_W) / 2
    @panel_y = (sh - PANEL_H) / 2

    @vp = Viewport.new(0, 0, sw, sh)
    @vp.z = 100000

    @bmp_sp = Sprite.new(@vp)
    @bmp_sp.bitmap = Bitmap.new(sw, sh)
  end

  def _dispose
    @bmp_sp.bitmap.dispose
    @bmp_sp.dispose
    @vp.dispose
  end

  def _status_text(raw)
    return nil if raw.nil? || raw.empty? || raw == 'NONE'
    STATUS_ABBR[raw] || raw[0, 3]
  end

  def _hp_color(ratio)
    return Color.new(80, 220, 80)  if ratio > 0.5
    return Color.new(240, 210, 60) if ratio > 0.2
    Color.new(220, 70, 70)
  end

  def _draw_row(bmp, y, side_label, info)
    x = @panel_x + 8
    w = PANEL_W - 16
    bmp.font.size  = 12
    bmp.font.bold  = true
    bmp.font.color = Color.new(180, 200, 255)
    bmp.draw_text(x, y, w, 16, side_label)

    unless info
      bmp.font.bold  = false
      bmp.font.color = Color.new(160, 160, 160)
      bmp.draw_text(x, y + 16, w, 16, "(waiting for first turn...)")
      return
    end

    name    = info['name']    || '???'
    species = info['species'] || ''
    level   = info['level']   || '?'
    hp      = info['hp'].to_i
    totalhp = [info['totalhp'].to_i, 1].max
    status  = _status_text(info['status'])
    ratio   = hp / totalhp.to_f

    bmp.font.bold  = false
    bmp.font.color = Color.new(230, 230, 230)
    label = (name.to_s.casecmp?(species.to_s) || name.to_s.empty?) ? species.to_s : "#{name} (#{species})"
    bmp.draw_text(x, y + 15, w - 44, 15, "#{label}  Lv#{level}")

    if status
      bmp.font.color = Color.new(255, 150, 90)
      bmp.draw_text(x + w - 40, y + 15, 40, 15, status, 2)
    end

    # HP bar
    bar_y = y + 32
    bmp.fill_rect(x, bar_y, w, 8, Color.new(40, 40, 40))
    fill_w = (w * [ratio, 0].max).round
    bmp.fill_rect(x, bar_y, fill_w, 8, _hp_color(ratio))
    bmp.font.size  = 11
    bmp.font.color = Color.new(255, 255, 255)
    bmp.draw_text(x, bar_y + 9, w, 14, "#{hp} / #{totalhp}", 1)
  end

  def _draw
    bmp = @bmp_sp.bitmap
    bmp.clear
    bmp.fill_rect(0, 0, Settings::SCREEN_WIDTH, Settings::SCREEN_HEIGHT, Color.new(0, 0, 0, 140))
    bmp.fill_rect(@panel_x - 2, @panel_y - 2, PANEL_W + 4, PANEL_H + 4, Color.new(200, 180, 60))
    bmp.fill_rect(@panel_x, @panel_y, PANEL_W, PANEL_H, Color.new(18, 18, 55))
    bmp.fill_rect(@panel_x, @panel_y, PANEL_W, 24, Color.new(30, 30, 90))

    bmp.font.size  = 13
    bmp.font.bold  = true
    bmp.font.color = Color.new(255, 215, 0)
    bmp.draw_text(@panel_x, @panel_y + 4, PANEL_W, 18, "Watching Battle", 1)

    row0 = @hp ? @hp[0] : nil
    row1 = @hp ? @hp[1] : nil
    _draw_row(bmp, @panel_y + 30, "#{@challenger_name}'s Pokémon", row0)
    _draw_row(bmp, @panel_y + 90, "#{@opponent_name}'s Pokémon",   row1)

    bmp.font.size  = 11
    bmp.font.bold  = false
    bmp.font.color = Color.new(170, 170, 170)
    footer = @ended ? "Battle has ended. Press Z to close." : "B: Stop watching"
    bmp.draw_text(@panel_x, @panel_y + PANEL_H - 16, PANEL_W, 16, footer, 1)

    Graphics.update
  end
end
