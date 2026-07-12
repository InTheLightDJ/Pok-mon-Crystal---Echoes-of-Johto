#===============================================================================
# NetworkLeaderboard — world ranking board.
#
# NPC script command:  pbShowLeaderboard
#
# Score (computed server-side, see handlers/leaderboard.js on the server):
#   +1 per Server Token, +1 per Pokédex species seen, +1 per species caught,
#   +2 per PvP win, -1 per PvP loss.
#
# The server is authoritative — it returns the full board already sorted
# highest-to-lowest. Players who haven't logged in with a leaderboard-aware
# client yet simply sit at their existing token count (their dex/PvP columns
# default to 0 in the database until their client reports real data).
#===============================================================================

# Called from NPC events: pbShowLeaderboard
def pbShowLeaderboard
  unless NetworkAuth.logged_in?
    pbMessage(_INTL("You must be connected to the server to view the World Rankings."))
    return
  end

  entries = nil
  NetworkClient.on('leaderboard_data') { |d| entries ||= (d['entries'] || []) }
  NetworkClient.send_msg({ action: 'leaderboard_request' })
  200.times { Graphics.update; Input.update; NetworkClient.update; break if entries }
  NetworkClient.off('leaderboard_data')

  unless entries
    pbMessage(_INTL("No response from the server. Please try again."))
    return
  end

  scene = Scene_Leaderboard.new(entries)
  scene.main
end

#===============================================================================
# Scene_Leaderboard — scrollable, ranked list with a "jump to me" shortcut.
#===============================================================================
class Scene_Leaderboard
  ROW_H   = 20
  VISIBLE = 14
  PANEL_W = 280
  PANEL_H = 34 + ROW_H * VISIBLE + 24

  GOLD       = Color.new(255, 215, 0)
  SELF_BG    = Color.new(70, 55, 15)
  ROW_BG_A   = Color.new(24, 24, 60)
  ROW_BG_B   = Color.new(18, 18, 50)
  TEXT_COLOR = Color.new(220, 220, 235)
  DIM_COLOR  = Color.new(150, 150, 175)

  def initialize(entries)
    @entries = entries
    my_name  = NetworkAuth.username.to_s
    @my_index = @entries.index { |e| e['username'].to_s.casecmp?(my_name) }
  end

  def main
    _create_ui
    @top = @my_index ? [@my_index - VISIBLE / 2, 0].max : 0
    _clamp_top
    _draw_rows
    _draw_footer

    loop do
      Graphics.update
      Input.update
      NetworkClient.update
      break if Input.trigger?(Input::BACK)

      if Input.trigger?(Input::DOWN)
        @top += 1; _clamp_top; _draw_rows
      elsif Input.trigger?(Input::UP)
        @top -= 1; _clamp_top; _draw_rows
      elsif Input.trigger?(Input::AUX2)
        @top += VISIBLE; _clamp_top; _draw_rows
      elsif Input.trigger?(Input::AUX1)
        @top -= VISIBLE; _clamp_top; _draw_rows
      elsif Input.trigger?(Input::ACTION) && @my_index
        @top = [@my_index - VISIBLE / 2, 0].max; _clamp_top; _draw_rows
      end
    end
  ensure
    _dispose
  end

  private

  def _clamp_top
    max_top = [@entries.length - VISIBLE, 0].max
    @top = @top.clamp(0, max_top)
  end

  def _create_ui
    sw = Settings::SCREEN_WIDTH
    sh = Settings::SCREEN_HEIGHT
    @panel_x = (sw - PANEL_W) / 2
    @panel_y = (sh - PANEL_H) / 2

    @vp = Viewport.new(0, 0, sw, sh)
    @vp.z = 100000

    @bg_sp = Sprite.new(@vp)
    bmp = Bitmap.new(sw, sh)
    bmp.fill_rect(0, 0, sw, sh, Color.new(0, 0, 0, 160))
    bmp.fill_rect(@panel_x - 2, @panel_y - 2, PANEL_W + 4, PANEL_H + 4, Color.new(200, 180, 60))
    bmp.fill_rect(@panel_x, @panel_y, PANEL_W, PANEL_H, Color.new(18, 18, 55))
    bmp.fill_rect(@panel_x, @panel_y, PANEL_W, 30, Color.new(30, 30, 90))
    bmp.font.size  = 15
    bmp.font.bold  = true
    bmp.font.color = GOLD
    bmp.draw_text(@panel_x, @panel_y + 5, PANEL_W, 20, "World Rankings", 1)
    @bg_sp.bitmap = bmp

    @rows_bmp = Bitmap.new(PANEL_W - 12, ROW_H * VISIBLE)
    @rows_sp  = Sprite.new(@vp)
    @rows_sp.bitmap = @rows_bmp
    @rows_sp.x = @panel_x + 6
    @rows_sp.y = @panel_y + 34

    @footer_bmp = Bitmap.new(PANEL_W - 12, 20)
    @footer_sp  = Sprite.new(@vp)
    @footer_sp.bitmap = @footer_bmp
    @footer_sp.x = @panel_x + 6
    @footer_sp.y = @panel_y + PANEL_H - 22
  end

  def _dispose
    @bg_sp.bitmap.dispose
    @bg_sp.dispose
    @rows_bmp.dispose
    @rows_sp.dispose
    @footer_bmp.dispose
    @footer_sp.dispose
    @vp.dispose
  end

  def _draw_rows
    @rows_bmp.clear
    VISIBLE.times do |i|
      idx = @top + i
      next if idx >= @entries.length
      e     = @entries[idx]
      y     = i * ROW_H
      is_me = (idx == @my_index)

      @rows_bmp.fill_rect(0, y, @rows_bmp.width, ROW_H, is_me ? SELF_BG : (i.even? ? ROW_BG_A : ROW_BG_B))

      @rows_bmp.font.size  = 13
      @rows_bmp.font.bold  = is_me
      @rows_bmp.font.color = is_me ? GOLD : TEXT_COLOR
      @rows_bmp.draw_text(4, y + 2, 36, ROW_H - 4, "##{idx + 1}", 0)
      @rows_bmp.draw_text(44, y + 2, @rows_bmp.width - 44 - 44, ROW_H - 4, e['username'].to_s, 0)
      @rows_bmp.draw_text(@rows_bmp.width - 44, y + 2, 40, ROW_H - 4, e['score'].to_s, 2)
    end
  end

  def _draw_footer
    @footer_bmp.clear
    @footer_bmp.font.size  = 11
    @footer_bmp.font.bold  = false
    @footer_bmp.font.color = DIM_COLOR
    text = if @my_index
      "You: ##{@my_index + 1} / #{@entries.length}   A: Jump to me   B: Close"
    else
      "#{@entries.length} players ranked   B: Close"
    end
    @footer_bmp.draw_text(0, 1, @footer_bmp.width, 18, text, 1)
  end
end
