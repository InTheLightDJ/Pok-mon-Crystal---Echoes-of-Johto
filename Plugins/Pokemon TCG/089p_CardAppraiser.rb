#==============================================================================
# Pokemon TCG - Card Appraiser (not in the original; the grades: 089o)
#
# pbTCGAppraiser (from an NPC, online):
#   Appraise   pick a holo copy; for Grades::APPRAISE_COST Server Tokens a
#              magnifying glass looks it over and it comes back in a graded
#              case with its PSA grade, which shows from then on
#   Refurbish  an appraised copy up one grade (to 10) for
#              Grades::REFURBISH_COST Server Tokens (PSA 9 -> 10:
#              Grades::REFURBISH_COST_TO_10)
# The pick screens are the Card Shop's (089l): the picked copy large on top,
# every holo copy below with its grade ("?" before it's appraised). The
# appraisal and the graded case are drawn on a sprite over the whole screen.
#==============================================================================
module TCG
  module Appraiser
    module_function

    def open
      unless NetPvP.online?
        pbMessage(_INTL("You need to be connected online to use the Card Appraiser."))
        return
      end
      run = lambda do
        pbFadeOutIn do
          scene = DuelScene.new
          begin
            scene.appraiser_screen
          ensure
            scene.dispose
          end
        end
      end
      # it keeps the connection going: server messages wait until it's closed
      defined?(HeldServerMessages) ? HeldServerMessages.during(&run) : run.call
    end
  end

  class DuelScene
    def appraiser_screen
      with_shop_layer { appraiser_front }
    end

    #--------------------------------------------------------------------------
    # the front: prices and tokens; Appraise / Refurbish / Leave
    #--------------------------------------------------------------------------
    def appraiser_front
      pos = 0
      loop do
        appraiser_draw_front
        @map.wide_text_box
        [[2, 14, _INTL("Appraise")], [12, 14, _INTL("Refurbish")], [2, 16, _INTL("Leave")]].each { |x, y, t| @map.text(x, y, t) }
        pos = check_menu_cursor(pos, [0, 1, 2])
        case pos
        when 0 then appraiser_pick(:appraise)
        when 1 then appraiser_pick(:refurbish)
        else break
        end
      end
    end

    def appraiser_draw_front
      @map.clear
      @shop[:pics] = []
      @map.text(4, 0, _INTL("CARD APPRAISER"))
      @map.text(1, 2, _INTL("I grade holo cards from"))
      @map.text(1, 3, _INTL("PSA 1 (poor) to PSA 10 (mint)."))
      @map.text(1, 4, _INTL("Cards wear down in duels!"))
      @map.text(1, 6, _INTL("Appraise: {1} Token", Grades::APPRAISE_COST))
      @map.text(1, 7, _INTL("Refurbish: {1} Tokens", Grades::REFURBISH_COST))
      @map.text(2, 8, _INTL("(+1 grade, appraised only)"))
      @map.text(2, 9, _INTL("PSA 9 to 10: {1} Tokens", Grades::REFURBISH_COST_TO_10))
      @map.text(1, 10, _INTL("Tokens: {1}", CardShop.tokens))
      render
      shop_draw_pics
    end

    #--------------------------------------------------------------------------
    # picking a copy: every holo copy you have, in pages of 12
    #--------------------------------------------------------------------------
    def appraiser_pick(mode)
      cur = 0
      loop do
        entries = Grades.all_entries
        if entries.empty?
          shop_say(_INTL("You don't have any holo cards to look at."))
          return
        end
        cur = cur.clamp(0, entries.size - 1)
        appraiser_draw_pick(entries, cur, mode)
        key = shop_wait_key
        case key
        when Input::BACK then pbPlayCancelSE; return
        when Input::USE
          pbPlayDecisionSE
          appraiser_use(mode, *entries[cur])
        else
          n = shop_move(cur, key, entries.size)
          if n != cur
            cur = n
            pbPlayCursorSE
          end
        end
      end
    end

    def appraiser_draw_pick(entries, cur, mode)
      @map.clear
      @shop[:pics] = []
      page = cur / CardShop::GRID_CELLS
      pages = (entries.size + CardShop::GRID_CELLS - 1) / CardShop::GRID_CELLS
      title = mode == :appraise ? _INTL("Appraise {1}/{2}", page + 1, pages) : _INTL("Refurbish {1}/{2}", page + 1, pages)
      @map.text(1, 0, title)
      t = _INTL("Tokens: {1}", CardShop.tokens)
      @map.text(19 - Screens.text_tiles(t), 0, t) if Screens.text_tiles(title) + Screens.text_tiles(t) < 18
      id, copy = entries[cur]
      shop_draw_big_card(id)
      r = Grades.record(id, copy)
      if r[Grades::APPRAISED]
        @map.text(10, 4, _INTL("PSA {1}", r[Grades::GRADE]))
        @map.text(10, 5, Grades.name(r[Grades::GRADE]))
      else
        @map.text(10, 4, _INTL("Not appraised"))
      end
      @map.text(10, 6, _INTL("In a deck")) if Grades.in_deck?(id, copy)
      @map.box(0, 7, 20, 11)
      first = page * CardShop::GRID_CELLS
      entries[first, CardShop::GRID_CELLS].each_with_index do |(x, c), i|
        shop_pic(CardShop::GRID_X[i % 4], CardShop::GRID_Y[i / 4], :gfx => TCG.card(x).gfx,
                 :sel => first + i == cur, :label => Grades.label(x, c) || "?")
      end
      render
      shop_draw_pics
    end

    def appraiser_use(mode, id, copy)
      r = Grades.record(id, copy) or return
      name = TCG.card(id).name
      g = r[Grades::GRADE]
      if mode == :appraise
        if r[Grades::APPRAISED]
          shop_say(_INTL("I've seen this {1} already: PSA {2}, {3}.", name, g, Grades.name(g)))
          return
        end
        cost = Grades::APPRAISE_COST
        return unless shop_yes_no(_INTL("Appraise this {1} for {2} Server Token?", name, cost))
        if (err = Grades.spend_tokens(cost, "tcg appraisal"))
          shop_say(err)
          return
        end
        r[Grades::APPRAISED] = true
        CardShop.changed!
        appraisal_show(id, r, :appraise)
      else
        unless r[Grades::APPRAISED]
          shop_say(_INTL("I only refurbish cards I've appraised. Have this {1} appraised first!", name))
          return
        end
        if g >= 10
          shop_say(_INTL("This {1} is GEM MINT 10. It can't get any better!", name))
          return
        end
        cost = Grades.refurbish_cost(g)
        return unless shop_yes_no(_INTL("Refurbish this {1} from PSA {2} to PSA {3} for {4} Server Tokens?",
                                        name, g, g + 1, cost))
        if (err = Grades.spend_tokens(cost, "tcg refurbish"))
          shop_say(err)
          return
        end
        r[Grades::GRADE] = g + 1
        r[Grades::DUELS] = 0
        CardShop.changed!
        appraisal_show(id, r, :refurbish, g)
      end
    end

    #--------------------------------------------------------------------------
    # the show: the card looked over (magnifying glass / polishing shine),
    # a flash, then the graded case. A closes it. Text uses the game font at
    # 18 (8 px letters), 36 (16 px) and 72 (32 px); pictures scale by whole
    # numbers.
    #--------------------------------------------------------------------------
    def appraisal_show(id, rec, mode, old_grade = nil)
      w = Graphics.width
      h = Graphics.height
      card = TCG.card(id)
      grade = rec[Grades::GRADE]
      @appr = {
        :card  => card,
        :art   => (RPG::Cache.load_bitmap(GFX + "Cards/", card.gfx.to_s.split("*", 2)[0]) rescue nil),
        :sheet => (TCG.holo_sheet(card.gfx) && (RPG::Cache.load_bitmap(GFX + "UI/", TCG.holo_sheet(card.gfx)) rescue nil)),
        :bg    => appraisal_background(w, h)
      }
      spr = Sprite.new(@viewport)
      spr.z = 50
      spr.bitmap = Bitmap.new(w, h)
      flash = Sprite.new(@viewport)
      flash.z = 51
      flash.bitmap = Bitmap.new(w, h)
      flash.bitmap.fill_rect(0, 0, w, h, Color.new(255, 255, 255))
      flash.opacity = 0
      bmp = spr.bitmap
      # the look-over
      s = [[w * 0.62 / 64, h * 0.5 / 48].min.floor, 1].max
      aw = 64 * s
      ah = 48 * s
      art_rect = Rect.new((w - aw) / 2, (h - ah) / 2 - h / 12, aw, ah)
      t0 = System.uptime
      length = mode == :appraise ? 2.6 : 2.2
      loop do
        t = System.uptime - t0
        break if t >= length
        bmp.blt(0, 0, @appr[:bg], @appr[:bg].rect)
        appraisal_card(bmp, art_rect)
        dots = "." * (1 + (t * 3).to_i % 3)
        if mode == :appraise
          cx = art_rect.x + aw / 2 + Math.sin(t * 2.4) * aw * 0.34
          cy = art_rect.y + ah / 2 + Math.sin(t * 4.8) * ah * 0.26
          appraisal_lens(bmp, art_rect, s, cx.round, cy.round, h / 10)
          appraisal_caption(bmp, _INTL("Appraising") + dots, art_rect.y + ah + 14)
        else
          appraisal_shine(bmp, art_rect, t / length)
          appraisal_caption(bmp, _INTL("Refurbishing") + dots, art_rect.y + ah + 14)
          bar = Rect.new(art_rect.x, art_rect.y + ah + 46, aw, 6)
          bmp.fill_rect(bar, Color.new(40, 44, 70))
          bmp.fill_rect(bar.x, bar.y, (bar.width * t / length).round, bar.height, Color.new(120, 220, 255))
        end
        Graphics.update
        Input.update
      end
      # the case
      if grade >= 9
        pbMEPlay("Slots big win")
      elsif grade <= 3
        pbPlayBuzzerSE
      else
        pbMEPlay("Item get")
      end
      stars = Array.new(grade >= 9 ? 26 : (grade >= 7 ? 10 : 0)) { [rand(w), rand(h), rand * 6.28] }
      t0 = System.uptime
      loop do
        t = System.uptime - t0
        bmp.blt(0, 0, @appr[:bg], @appr[:bg].rect)
        appraisal_slab(bmp, rec, t, old_grade, mode)
        appraisal_stars(bmp, stars, t)
        flash.opacity = t < 0.35 ? (255 * (1 - t / 0.35)).round : 0
        appraisal_caption(bmp, _INTL("A: OK"), h - 19, small: true) if t > 0.9 && (t * 2).to_i.even?
        Graphics.update
        Input.update
        break if t > 0.9 && (Input.trigger?(Input::USE) || Input.trigger?(Input::BACK))
      end
      pbPlayDecisionSE
    ensure
      flash&.bitmap&.dispose
      flash&.dispose
      spr&.bitmap&.dispose
      spr&.dispose
      @appr&.dig(:bg)&.dispose
      @appr&.dig(:shine)&.dispose
      @appr = nil
    end

    # dark blue fading down to black
    def appraisal_background(w, h)
      b = Bitmap.new(w, h)
      bands = 48
      bands.times do |i|
        f = i / (bands - 1.0)
        b.fill_rect(0, (h * i / bands.to_f).floor, w, (h / bands.to_f).ceil + 1,
                    Color.new((28 - 20 * f).round, (30 - 20 * f).round, (72 - 52 * f).round))
      end
      b
    end

    MAX_FONT_SIZE = 96   # mkxp refuses bigger ("bad value for size")

    # the game font at `size` (36 is the normal text)
    def appraisal_font(bmp, size)
      size = size.clamp(6, MAX_FONT_SIZE)
      pbSetSystemFont(bmp)
      bmp.font.size = size
      bmp.text_offset_y = (MessageConfig::FONT_Y_OFFSET * size / 36.0).round if bmp.respond_to?(:text_offset_y=)
    end

    def appraisal_text(bmp, x, y, w, hgt, str, align, color, shadow = Color.new(20, 20, 30))
      bmp.font.color = shadow
      bmp.draw_text(x + 1, y + 1, w, hgt, str, align)
      bmp.font.color = color
      bmp.draw_text(x, y, w, hgt, str, align)
    end

    def appraisal_caption(bmp, str, y, small: false)
      appraisal_font(bmp, small ? 18 : 36)
      appraisal_text(bmp, 0, y, bmp.width, small ? 16 : 28, str, 1,
                     small ? Color.new(200, 200, 220) : Color.new(248, 232, 160))
    end

    # the card's picture in a white border, with its holo sparkle
    def appraisal_card(bmp, r)
      bmp.fill_rect(r.x - 6, r.y - 6, r.width + 12, r.height + 12, Color.new(10, 10, 20))
      bmp.fill_rect(r.x - 4, r.y - 4, r.width + 8, r.height + 8, Color.new(240, 240, 248))
      art = @appr[:art]
      art ? bmp.stretch_blt(r, art, art.rect) : bmp.fill_rect(r, Color.new(90, 90, 110))
      sheet = @appr[:sheet] or return
      frames = sheet.width / 64
      bmp.stretch_blt(r, sheet, Rect.new((TCG.holo_tick % frames) * 64, 0, 64, 48)) if frames > 0
    end

    # a magnifying glass at cx, cy (lens radius rad) showing the picture
    # twice as big under it
    def appraisal_lens(bmp, r, scale, cx, cy, rad)
      art = @appr[:art]
      zoom = 2.0
      ux = (cx - r.x) / scale.to_f
      uy = (cy - r.y) / scale.to_f
      glass = Color.new(200, 220, 240)
      (-rad..rad).each do |dy|
        half = Math.sqrt(rad * rad - dy * dy).to_i
        next if half <= 0
        y = cy + dy
        bmp.fill_rect(cx - half, y, half * 2, 1, glass)
        next unless art
        v = uy + dy / (scale * zoom)
        next if v < 0 || v >= art.height
        sx = ux - half / (scale * zoom)
        sw = half * 2 / (scale * zoom)
        bmp.stretch_blt(Rect.new(cx - half, y, half * 2, 1), art, Rect.new(sx.floor, v.floor, [sw.ceil, 1].max, 1))
      end
      # the rim, a glint and the handle
      ring = [rad / 7, 3].max
      rim = Color.new(212, 168, 64)
      rim_dark = Color.new(120, 84, 24)
      (-(rad + ring)..(rad + ring)).each do |dy|
        outer = Math.sqrt([(rad + ring)**2 - dy * dy, 0].max).to_i
        inner = dy.abs < rad ? Math.sqrt(rad * rad - dy * dy).to_i : 0
        y = cy + dy
        c = dy < 0 ? rim : rim_dark
        bmp.fill_rect(cx - outer, y, outer - inner, 1, c)
        bmp.fill_rect(cx + inner, y, outer - inner, 1, c)
      end
      g = [rad / 6, 2].max
      bmp.fill_rect(cx - rad / 2, cy - rad / 2, g * 2, g, Color.new(255, 255, 255))
      bmp.fill_rect(cx - rad / 2, cy - rad / 2, g, g * 2, Color.new(255, 255, 255))
      thick = [rad / 4, 4].max
      steps = (rad * 1.3).to_i
      steps.times do |i|
        d = rad + ring + i * 0.7
        hx = (cx + d * 0.707).round
        hy = (cy + d * 0.707).round
        bmp.fill_rect(hx - thick / 2, hy - thick / 2, thick, thick, i < steps / 5 ? rim_dark : Color.new(70, 40, 24))
      end
    end

    # a shine band sweeping across the picture (refurbishing)
    def appraisal_shine(bmp, r, f)
      @appr[:shine] ||= begin
        b = Bitmap.new(48, 1)
        48.times { |i| b.fill_rect(i, 0, 1, 1, Color.new(255, 255, 255, (200 * Math.sin(Math::PI * i / 47.0)).round)) }
        b
      end
      shine = @appr[:shine]
      pos = r.x - r.width / 2 + ((f * 2.5) % 1.0) * (r.width * 2)
      r.height.times do |dy|
        x = (pos + dy * 0.6).round
        from = [r.x - x, 0].max
        to = [r.x + r.width - x, 48].min
        next if to <= from
        bmp.blt(x + from, r.y + dy, shine, Rect.new(from, 0, to - from, 1))
      end
    end

    # twinkling 4-point stars
    def appraisal_stars(bmp, stars, t)
      stars.each do |x, y, ph|
        a = Math.sin(t * 5 + ph)
        next if a <= 0
        size = (2 + a * 5).round
        c = Color.new(255, 240, 160)
        bmp.fill_rect(x - size, y, size * 2 + 1, 1, c)
        bmp.fill_rect(x, y - size, 1, size * 2 + 1, c)
        bmp.fill_rect(x - 1, y - 1, 3, 3, Color.new(255, 255, 255))
      end
    end

    # the graded case: a red label (name, tier, grade name | PSA and the big
    # grade) over the card in its window, the cert number under it
    def appraisal_slab(bmp, rec, t, old_grade, mode)
      w = bmp.width
      h = bmp.height
      card = @appr[:card]
      grade = rec[Grades::GRADE]
      rise = t < 0.3 ? ((0.3 - t) / 0.3 * h * 0.15).round : 0   # slides up into place
      sw = (w * 0.8).round
      sh = (h * 0.84).round
      sx = (w - sw) / 2
      sy = (h - sh) / 2 - 8 + rise
      bmp.fill_rect(sx - 3, sy - 3, sw + 6, sh + 6, Color.new(60, 66, 86))
      bmp.fill_rect(sx, sy, sw, sh, Color.new(196, 206, 222))
      bmp.fill_rect(sx + 5, sy + 5, sw - 10, sh - 10, Color.new(228, 234, 244))
      # label
      lx = sx + 9
      ly = sy + 8
      lw = sw - 18
      lh = 60
      bmp.fill_rect(lx, ly, lw, lh, Color.new(150, 16, 28))
      bmp.fill_rect(lx + 2, ly + 2, lw - 4, lh - 4, Color.new(206, 36, 48))
      bmp.fill_rect(lx + 4, ly + 4, lw - 8, 1, Color.new(240, 120, 128))
      white = Color.new(255, 255, 255)
      gold  = Color.new(255, 216, 72)
      pink  = Color.new(255, 210, 214)
      dark  = Color.new(100, 8, 18)
      num_w = 72
      tx = lx + 8
      tw = lw - num_w - 12
      appraisal_font(bmp, 18)
      appraisal_text(bmp, tx, ly + 5, tw, 14, card.name, 0, white, dark)
      appraisal_text(bmp, tx, ly + 19, tw, 14, _INTL("{1} Holo", TCG.holo_name(card.holo_tier)), 0, pink, dark)
      appraisal_text(bmp, tx, ly + 40, tw, 14, Grades.name(grade), 0, grade >= 10 ? gold : white, dark)
      nx = lx + lw - num_w - 4
      bmp.fill_rect(nx - 4, ly + 6, 1, lh - 12, Color.new(150, 16, 28))
      appraisal_text(bmp, nx, ly + 5, num_w, 14, "PSA", 1, pink, dark)
      if mode == :refurbish && old_grade
        appraisal_text(bmp, nx, ly + 46, num_w, 14, _INTL("was {1}", old_grade), 1, pink, dark)
      end
      # the number pops in (from 96, the biggest font size the game allows)
      pop = t < 0.45 ? 1.0 + (0.45 - t) / 0.45 * (MAX_FONT_SIZE / 72.0 - 1) : 1.0
      big_h = (38 * pop).round
      appraisal_font(bmp, (72 * pop).round)
      appraisal_text(bmp, nx, ly + 29 - big_h / 2, num_w, big_h, grade.to_s, 1, grade >= 10 ? gold : white, dark)
      # the card in its window
      wy = ly + lh + 8
      scale = [[(sy + sh - 18 - wy) / 48, (lw - 12) / 64].min, 1].max
      win = Rect.new(sx + (sw - 64 * scale) / 2, wy, 64 * scale, 48 * scale)
      bmp.fill_rect(win.x - 6, win.y - 6, win.width + 12, win.height + 12, Color.new(150, 160, 178))
      appraisal_card(bmp, win)
      # glare on the plastic, the cert number
      bmp.fill_rect(sx + 8, sy + sh / 2, 2, sh / 3, Color.new(250, 252, 255))
      cert = format("%08d", (card.id.to_s.sum * 7919 + grade * 104_729) % 100_000_000)
      appraisal_font(bmp, 18)
      appraisal_text(bmp, sx, sy + sh - 16, sw, 14, _INTL("CERT No. {1}", cert), 1, Color.new(80, 90, 110),
                     Color.new(250, 252, 255))
    end
  end
end

# the Card Appraiser NPC
def pbTCGAppraiser; TCG::Appraiser.open; end
