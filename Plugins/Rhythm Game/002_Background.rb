#==============================================================================
# Rhythm Game - the background: a Ruins of Alph tile puzzle picture, 4x4
# tiles drawn 1.5x so it fills the screen's height, that keeps mixing itself
# up on the beat. Each move is like the Ruins of Alph puzzles' (Data/Scripts/
# 017_Minigames/007_Minigame_TilePuzzles.rb): two tiles side by side slide
# into each other's place (0.3 s), or a tile turns a quarter (0.25 s). Here
# the tiles shake first, from one beat to the next, and move on the beat
# after. Halfway through the song the picture fades into another one, which
# starts whole too.
#==============================================================================
module RhythmGame
  class PuzzleBackground
    DIR       = "Graphics/UI/Tile Puzzle/"
    PICTURES  = %w[Absol Aerodactyl Arcanine Ash Beedrill Blastoise Charizard Dusknoir
                   Gardevior Golem Groudon Hooh Jessie Jolteon Kabuto Kyogre Lapras
                   Larvatar Lopunny Lugia Magikarp Metagross Mew MewTwo Miltank Omanyte
                   Pikachu Quilfish Rayquazza Sneasel Suicune Togepi Venasaur]
    SIZE      = 4        # tiles a side
    TILE      = 48       # a tile in the picture
    ZOOM      = 1.5
    CELL      = (TILE * ZOOM).to_i
    MOVE_CHANCE = 0.7    # a beat starts a move this often (if two tiles are free)
    ROTATE_CHANCE = 0.4  # of the moves, turns (the rest are swaps)
    SHAKE_MAX = 0.45     # seconds of shaking at most (when beats are slow)
    SWAP_TIME = 0.3
    TURN_TIME = 0.25
    FADE_TIME = 0.6
    TONE      = Tone.new(-50, -50, -50, 40)   # pushed back behind the track

    def initialize(viewport)
      @viewport = viewport
      @back = Sprite.new(viewport)
      @back.bitmap = RPG::Cache.load_bitmap(DIR, "bg") rescue nil
      @back.tone = TONE
      @pictures = PICTURES.shuffle
      @bitmap = load_picture(@pictures.shift)
      @cell = (0...SIZE * SIZE).to_a   # tile => the cell it's in
      @turn = Array.new(SIZE * SIZE, 0) # tile => quarter turns
      @busy = []
      @moves = []
      @tiles = Array.new(SIZE * SIZE) do |k|
        s = Sprite.new(viewport)
        show_piece(s, k)
        s.ox = s.oy = TILE / 2
        s.zoom_x = s.zoom_y = ZOOM
        s.tone = TONE
        s.z = 1
        s
      end
      @tiles.each_index { |k| place(k) }
      @last_beat = nil
    end

    # tile k's piece of the picture
    def show_piece(sprite, k)
      sprite.bitmap = @bitmap
      sprite.src_rect.set((k % SIZE) * TILE, (k / SIZE) * TILE, TILE, TILE)
    end

    def load_picture(name)
      RPG::Cache.load_bitmap(DIR, "tiles#{name}")
    end

    # (the screen's size is only set after the plugins are loaded)
    def center(cell)
      left = (Graphics.width - (CELL * SIZE)) / 2
      top = (Graphics.height - (CELL * SIZE)) / 2
      [left + ((cell % SIZE) * CELL) + (CELL / 2), top + ((cell / SIZE) * CELL) + (CELL / 2)]
    end

    def place(k)
      @tiles[k].x, @tiles[k].y = center(@cell[k])
      @tiles[k].angle = @turn[k] * -90
    end

    def free?(k) = !@busy.include?(k)

    def tile_at(cell) = @cell.index(cell)

    # the next beat: tiles that were shaking start moving, and maybe a new
    # move starts shaking
    def beat(now)
      gap = @last_beat ? now - @last_beat : SHAKE_MAX
      @last_beat = now
      @moves.each { |m| m[:move_at] ||= now if m[:phase] == :shake }
      start_move(now, gap.clamp(0.1, SHAKE_MAX)) if rand < MOVE_CHANCE
    end

    def start_move(now, shake)
      if rand < ROTATE_CHANCE
        k = (0...SIZE * SIZE).select { |i| free?(i) }.sample or return
        tiles = [k]
        kind = :turn
      else
        k = (0...SIZE * SIZE).select { |i| free?(i) }.shuffle.find do |i|
          neighbours(@cell[i]).any? { |c| free?(tile_at(c)) }
        end or return
        other = tile_at(neighbours(@cell[k]).select { |c| free?(tile_at(c)) }.sample)
        tiles = [k, other]
        kind = :swap
      end
      @busy.concat(tiles)
      tiles.each { |t| @tiles[t].z = 2 }
      @moves << { kind: kind, tiles: tiles, phase: :shake, start: now, shake: shake, move_at: nil }
    end

    def neighbours(cell)
      x, y = cell % SIZE, cell / SIZE
      [[x - 1, y], [x + 1, y], [x, y - 1], [x, y + 1]]
        .select { |a, b| a.between?(0, SIZE - 1) && b.between?(0, SIZE - 1) }
        .map { |a, b| (b * SIZE) + a }
    end

    def update(now)
      @moves.each do |m|
        if m[:phase] == :shake
          # shaking harder as the move gets close; on the next beat (or after
          # the longest shake) it moves
          if (m[:move_at] && now >= m[:move_at]) || now - m[:start] >= SHAKE_MAX * 2
            m[:phase] = :move
            m[:start] = now
            m[:tiles].each { |t| place(t) }
          else
            power = 1 + (2 * [(now - m[:start]) / m[:shake], 1].min)
            m[:tiles].each do |t|
              x, y = center(@cell[t])
              @tiles[t].x = x + (rand(-1.0..1.0) * power).round
              @tiles[t].y = y + (rand(-1.0..1.0) * power).round
              @tiles[t].angle = (@turn[t] * -90) + (rand(-1.0..1.0) * power * 1.5)
            end
          end
        end
        animate(m, now) if m[:phase] == :move
      end
      @moves.reject! { |m| m[:done] }
      update_fade(now)
    end

    def animate(m, now)
      if m[:kind] == :turn
        t = m[:tiles][0]
        @tiles[t].angle = lerp(@turn[t] * -90, (@turn[t] * -90) - 90, TURN_TIME, m[:start], now)
        return unless now - m[:start] >= TURN_TIME
        @turn[t] = (@turn[t] + 1) % 4
        finish(m)
      else
        a, b = m[:tiles]
        (ax, ay), (bx, by) = center(@cell[a]), center(@cell[b])
        @tiles[a].x = lerp(ax, bx, SWAP_TIME, m[:start], now)
        @tiles[a].y = lerp(ay, by, SWAP_TIME, m[:start], now)
        @tiles[b].x = lerp(bx, ax, SWAP_TIME, m[:start], now)
        @tiles[b].y = lerp(by, ay, SWAP_TIME, m[:start], now)
        return unless now - m[:start] >= SWAP_TIME
        @cell[a], @cell[b] = @cell[b], @cell[a]
        finish(m)
      end
    end

    def finish(m)
      m[:tiles].each do |t|
        place(t)
        @tiles[t].z = 1
      end
      @busy -= m[:tiles]
      m[:done] = true
    end

    # fades into the next picture
    def change_picture(now)
      return if @fade || @pictures.empty?
      @fade = { start: now, next: load_picture(@pictures.shift), swapped: false }
    end

    def update_fade(now)
      return unless @fade
      d = now - @fade[:start]
      if d < FADE_TIME
        op = lerp(255, 0, FADE_TIME, @fade[:start], now)
      else
        unless @fade[:swapped]
          @fade[:swapped] = true
          @bitmap = @fade[:next]
          # (a new bitmap resets a sprite's src_rect to all of it)
          @tiles.each_with_index { |s, k| show_piece(s, k) }
          # the new picture starts whole, like the first one
          @moves.clear
          @busy.clear
          @cell = (0...SIZE * SIZE).to_a
          @turn = Array.new(SIZE * SIZE, 0)
          @tiles.each_index do |k|
            place(k)
            @tiles[k].z = 1
          end
        end
        op = lerp(0, 255, FADE_TIME, @fade[:start] + FADE_TIME, now)
        @fade = nil if d >= FADE_TIME * 2
      end
      @tiles.each { |s| s.opacity = op }
    end

    def dispose
      @tiles.each(&:dispose)
      @back.dispose
    end
  end
end
