#===============================================================================
# Pokémon Sprite Recolor — hue + desaturation tool from the Summary screen.
#   HUE  (0-359) : rotates all colours around the colour wheel.
#   GRAY (0-255) : 0 = full colour, 255 = fully greyscale.
# Controls:  ← → adjust   L hold for ×10   ↓ switch slider   ↑ reset active
#            A confirm     B cancel
#===============================================================================

# Converts a hue value (0-359) to an approximate RGB Color for display.
def pbHueToColor(hue)
  h = (hue.to_i % 360) / 60.0
  i = h.floor % 6
  f = h - h.floor
  v = 210
  q_val = (v * (1 - f)).round
  t_val = (v * f).round
  case i
  when 0 then Color.new(v,     t_val, 0)
  when 1 then Color.new(q_val, v,     0)
  when 2 then Color.new(0,     v,     t_val)
  when 3 then Color.new(0,     q_val, v)
  when 4 then Color.new(t_val, 0,     v)
  when 5 then Color.new(v,     0,     q_val)
  else        Color.new(128,   128,   128)
  end
end

# Blends two Color objects by factor t (0.0 = a, 1.0 = b).
def pbBlendColors(a, b, t)
  Color.new(
    (a.red   + (b.red   - a.red)   * t).round,
    (a.green + (b.green - a.green) * t).round,
    (a.blue  + (b.blue  - a.blue)  * t).round
  )
end

# Draws a full hue-spectrum gradient strip into a Bitmap region.
def pbDrawHueGradient(bitmap, x, y, w, h)
  w.times do |i|
    bitmap.fill_rect(x + i, y, 1, h, pbHueToColor(i * 360 / w))
  end
end

# Draws a strip going from the given hue colour (left) to neutral grey (right).
def pbDrawSatGradient(bitmap, x, y, w, h, hue)
  full_color = pbHueToColor(hue)
  gray_color = Color.new(128, 128, 128)
  w.times do |i|
    bitmap.fill_rect(x + i, y, 1, h, pbBlendColors(full_color, gray_color, i.to_f / (w - 1)))
  end
end

# Opens the recolor UI for a Pokémon. Writes recolor_hue / recolor_gray on confirm.
def pbPokemonRecolor(pokemon)
  return if !pokemon || pokemon.egg?

  viewport = Viewport.new(0, 0, Graphics.width, Graphics.height)
  viewport.z = 99999

  bg = Sprite.new(viewport)
  bg.bitmap = Bitmap.new(Graphics.width, Graphics.height)
  bg.bitmap.fill_rect(0, 0, Graphics.width, Graphics.height, Color.new(0, 0, 0, 180))
  bg.z = 0

  overlay = BitmapSprite.new(Graphics.width, Graphics.height, viewport)
  pbSetSystemFont(overlay.bitmap)
  overlay.z = 10

  pkmnSprite = PokemonSprite.new(viewport)
  pkmnSprite.setOffset(PictureOrigin::CENTER)
  pkmnSprite.x = Graphics.width / 4
  pkmnSprite.y = Graphics.height / 2 + 10
  pkmnSprite.z = 5

  # Working copies — only written to pokemon on A confirm.
  hue  = pokemon.recolor_hue.to_i
  gray = pokemon.recolor_gray.to_i

  # :hue or :gray — which slider the d-pad is currently editing.
  active = :hue

  # Panel geometry (right half).
  px = Graphics.width / 2 + 8
  pw = Graphics.width / 2 - 16
  bh = 16   # gradient bar height

  # Rows: hue label, hue bar, gap, gray label, gray bar.
  hue_label_y = Graphics.height / 2 - 70
  hue_bar_y   = hue_label_y + 22
  gray_label_y = hue_bar_y + bh + 12
  gray_bar_y   = gray_label_y + 22

  # Load the raw sprite once with no hue applied, then snapshot it.
  # hue_change mutates the bitmap in-place and stacks on repeated calls,
  # so we always clone the clean original and apply once from scratch.
  _saved_hue  = pokemon.recolor_hue
  _saved_gray = pokemon.recolor_gray
  pokemon.recolor_hue  = nil
  pokemon.recolor_gray = nil
  pkmnSprite.setPokemonBitmap(pokemon)
  pokemon.recolor_hue  = _saved_hue
  pokemon.recolor_gray = _saved_gray
  _orig_bmp = pkmnSprite.bitmap ? pkmnSprite.bitmap.clone : nil

  refresh_sprite = proc {
    if _orig_bmp && !_orig_bmp.disposed?
      fresh = _orig_bmp.clone
      fresh.hue_change(hue) if hue != 0
      pkmnSprite.bitmap = fresh
    end
    pkmnSprite.tone = gray > 0 ? Tone.new(0, 0, 0, gray) : Tone.new(0, 0, 0, 0)
  }

  refresh_hud = proc {
    bmp = overlay.bitmap
    bmp.clear

    # Title
    bmp.font.bold  = true
    bmp.font.size  = 20
    bmp.font.color = Color.new(255, 255, 255)
    bmp.draw_text(0, 8, Graphics.width, 28, "RECOLOR: #{pokemon.name}", 1)
    bmp.font.bold = false

    # ── HUE ROW ──────────────────────────────────────────────
    hue_active = active == :hue
    bmp.font.size  = 16
    bmp.font.color = hue_active ? Color.new(255, 255, 100) : Color.new(180, 180, 180)
    bmp.draw_text(px, hue_label_y, pw, 20,
                  "#{hue_active ? "► " : "  "}HUE: #{hue == 0 ? "0 (original)" : hue}", 0)

    pbDrawHueGradient(bmp, px, hue_bar_y, pw, bh)
    # Cursor
    cx = px + (hue * pw / 360.0).round
    bmp.fill_rect(cx - 1, hue_bar_y - 4, 3, bh + 8, Color.new(255, 255, 255))
    bmp.fill_rect(cx,     hue_bar_y - 4, 1, bh + 8, Color.new(0, 0, 0))

    # ── GRAY / SATURATION ROW ────────────────────────────────
    gray_active = active == :gray
    bmp.font.color = gray_active ? Color.new(255, 255, 100) : Color.new(180, 180, 180)
    gray_label = gray == 0 ? "0 (full colour)" : gray.to_s
    bmp.draw_text(px, gray_label_y, pw, 20,
                  "#{gray_active ? "► " : "  "}GRAY: #{gray_label}", 0)

    pbDrawSatGradient(bmp, px, gray_bar_y, pw, bh, hue)
    cx2 = px + (gray * pw / 255.0).round
    bmp.fill_rect(cx2 - 1, gray_bar_y - 4, 3, bh + 8, Color.new(255, 255, 255))
    bmp.fill_rect(cx2,     gray_bar_y - 4, 1, bh + 8, Color.new(0, 0, 0))

    # ── Instructions ─────────────────────────────────────────
    bmp.font.size  = 13
    bmp.font.color = Color.new(180, 180, 180)
    bmp.draw_text(0, Graphics.height - 44, Graphics.width, 18,
                  "←→: Adjust   L: \xC3\x9710   ↑: Reset active   ↓: Switch slider", 1)
    bmp.draw_text(0, Graphics.height - 24, Graphics.width, 18,
                  "A: Confirm   B: Cancel", 1)
  }

  refresh_sprite.call
  refresh_hud.call

  loop do
    Graphics.update
    Input.update

    changed = false
    step    = Input.press?(Input::L) ? 10 : 1

    if Input.repeat?(Input::LEFT)
      if active == :hue
        hue = (hue - step + 360) % 360
      else
        gray = (gray - step * 5).clamp(0, 255)
      end
      changed = true
    elsif Input.repeat?(Input::RIGHT)
      if active == :hue
        hue = (hue + step) % 360
      else
        gray = (gray + step * 5).clamp(0, 255)
      end
      changed = true
    elsif Input.trigger?(Input::UP)
      active == :hue ? hue = 0 : gray = 0
      changed = true
    elsif Input.trigger?(Input::DOWN)
      active  = (active == :hue) ? :gray : :hue
      changed = true
    end

    if changed
      refresh_sprite.call
      refresh_hud.call
    end

    if Input.trigger?(Input::USE)
      pokemon.recolor_hue  = hue  > 0 ? hue  : nil
      pokemon.recolor_gray = gray > 0 ? gray : nil
      pbPlayDecisionSE
      break
    elsif Input.trigger?(Input::BACK)
      pbPlayCancelSE
      break
    end
  end

  _orig_bmp.dispose if _orig_bmp && !_orig_bmp.disposed?
  pkmnSprite.dispose
  overlay.bitmap.dispose
  overlay.dispose
  bg.bitmap.dispose
  bg.dispose
  viewport.dispose
end
