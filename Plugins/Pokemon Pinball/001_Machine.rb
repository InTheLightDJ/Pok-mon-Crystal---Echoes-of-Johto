#==============================================================================
# Pokémon Pinball (GBC) - the machine the recompiled game code runs on.
#
# The game's code is Pinball-mod/tools/recompile_gbc.py's translation of the
# pokepinball decomp (module PinballGBC::Code, loaded from Data/Pinball when
# the minigame opens). This file is the Game Boy Color around it:
#   CPU state      @a @b @c @d @e @h @l @sp, flags @fz @fn @fh @fc, @ime
#   memory         ROM (MBC5 banks), VRAM x2, cartridge RAM, WRAM x8, OAM,
#                  I/O registers, HRAM
#   timing         @cyc counts CPU cycles; service(pc) runs at block starts
#                  when the next scanline / timer event is due: LY, LYC STAT
#                  and VBlank interrupts, the timer interrupt, and at line 144
#                  the frame is handed to the screen (#on_frame) and the
#                  machine's Fiber yields until the next frame.
#   calls          generated methods return the popped return address, or
#                  TAIL + key for a tail jump (run_key / tramp follow those)
# Plain Ruby: no RGSS classes, so it also runs headless for tests.
#==============================================================================
module PinballGBC
  class MachineError < StandardError; end

  TAIL = 1 << 24   # a function's result >= TAIL: tail jump to key (result - TAIL)
  # filled in by the generated code (Data/Pinball), loaded when the game opens
  module Code; end

  # a return address that no caller expected (e.g. the soft reset that the
  # VBlank handler forces by rewriting the stack): execution continues there
  class ControlTransfer < StandardError
    attr_reader :addr
    def initialize(addr); @addr = addr; super("control transfer to $%04x" % addr); end
  end

  LINE_CYCLES  = 456
  FRAME_LINES  = 154
  FRAME_CYCLES = LINE_CYCLES * FRAME_LINES   # 70224
  VBLANK_LINE  = 144

  # I/O register numbers ($ff00 + n)
  R_P1 = 0x00; R_DIV = 0x04; R_TIMA = 0x05; R_TMA = 0x06; R_TAC = 0x07; R_IF = 0x0f
  R_LCDC = 0x40; R_STAT = 0x41; R_SCY = 0x42; R_SCX = 0x43; R_LY = 0x44; R_LYC = 0x45
  R_DMA = 0x46; R_WY = 0x4a; R_WX = 0x4b; R_KEY1 = 0x4d; R_VBK = 0x4f
  R_HDMA1 = 0x51; R_HDMA5 = 0x55; R_BCPS = 0x68; R_BCPD = 0x69; R_OCPS = 0x6a; R_OCPD = 0x6b; R_SVBK = 0x70

  # joypad bits (pressed = 1 here; the register shows them inverted)
  BTN_A = 0x01; BTN_B = 0x02; BTN_SELECT = 0x04; BTN_START = 0x08
  BTN_RIGHT = 0x10; BTN_LEFT = 0x20; BTN_UP = 0x40; BTN_DOWN = 0x80

  class Machine
    include Code

    attr_reader :vram, :oam, :io, :bg_pal, :obj_pal, :line_regs, :cyc, :frames, :wram, :hram, :sram, :tile_dirty
    attr_accessor :buttons, :frame_handler, :sram_dirty, :hooks, :pal_dirty
    attr_accessor :snd_log    # [cycle, register, value] of sound register writes (offline audio rendering)

    def initialize(rom)
      @rom = rom.b
      @rom_banks = @rom.bytesize / 0x4000
      @vram = Array.new(0x4000, 0)
      @sram = Array.new(0x8000, 0)
      @wram = Array.new(0x8000, 0)
      @oam  = Array.new(0xa0, 0)
      @io   = Array.new(0x80, 0)
      @hram = Array.new(0x7f, 0)
      @bg_pal  = Array.new(64, 0xff)    # CGB palette RAM (8 palettes x 4 colors x 2 bytes)
      @obj_pal = Array.new(64, 0xff)
      @tile_dirty = Array.new(768, true)  # tile data changed since the screen last drew it (2 banks x 384)
      @pal_dirty = true
      @ie = 0
      @buttons = 0
      @hooks = {}                       # key => proc(machine) -> returns like a function (pop16)
      @frames = 0
      reset
    end

    def reset
      # CGB state after the boot ROM
      @a = 0x11; @b = 0x00; @c = 0x00; @d = 0xff; @e = 0x56; @h = 0x00; @l = 0x0d
      @fz = true; @fn = false; @fh = false; @fc = false
      @sp = 0xfffe
      @ime = false
      @rom_bank = 1; @romx = 0x4000
      @ram_bank = 0; @ram_on = false
      @vbank = 0
      @wbank = 0x1000
      @cyc = 0
      @frame_start = 0
      @line = 0
      @next_line = LINE_CYCLES
      @timer_next = nil
      @next_ev = @next_line
      @io.fill(0)
      @io[R_LCDC] = 0x91
      @io[R_STAT] = 0x85
      @io[R_TAC] = 0xf8
      @io[R_IF] = 0xe1
      @line_regs = []
      start_frame_regs
    end

    #--------------------------------------------------------------------------
    # memory
    #--------------------------------------------------------------------------
    def rd(a)
      if a < 0x4000
        @rom.getbyte(a)
      elsif a < 0x8000
        @rom.getbyte(@romx + a - 0x4000)
      elsif a < 0xa000
        @vram[@vbank + a - 0x8000]
      elsif a < 0xc000
        @ram_on ? @sram[@ram_bank * 0x2000 + a - 0xa000] : 0xff
      elsif a < 0xd000
        @wram[a - 0xc000]
      elsif a < 0xe000
        @wram[@wbank + a - 0xd000]
      elsif a < 0xfe00
        rd(a - 0x2000)
      elsif a < 0xfea0
        @oam[a - 0xfe00]
      elsif a < 0xff00
        0xff
      elsif a < 0xff80
        io_rd(a & 0x7f)
      elsif a < 0xffff
        @hram[a - 0xff80]
      else
        @ie
      end
    end

    def wr(a, v)
      if a < 0x8000
        mbc_wr(a, v)
      elsif a < 0xa000
        @vram[@vbank + a - 0x8000] = v
        @tile_dirty[(@vbank >> 13) * 384 + ((a - 0x8000) >> 4)] = true if a < 0x9800
      elsif a < 0xc000
        if @ram_on
          @sram[@ram_bank * 0x2000 + a - 0xa000] = v
          @sram_dirty = true
        end
      elsif a < 0xd000
        @wram[a - 0xc000] = v
      elsif a < 0xe000
        @wram[@wbank + a - 0xd000] = v
      elsif a < 0xfe00
        wr(a - 0x2000, v)
      elsif a < 0xfea0
        @oam[a - 0xfe00] = v
      elsif a < 0xff00
        nil
      elsif a < 0xff80
        io_wr(a & 0x7f, v)
      elsif a < 0xffff
        @hram[a - 0xff80] = v
      else
        @ie = v
        recalc_next
      end
    end

    # MBC5
    def mbc_wr(a, v)
      if a < 0x2000
        @ram_on = (v & 0x0f) == 0x0a
      elsif a < 0x3000
        @rom_bank = (@rom_bank & 0x100) | v
        set_romx
      elsif a < 0x4000
        @rom_bank = (@rom_bank & 0xff) | ((v & 1) << 8)
        set_romx
      elsif a < 0x6000
        @ram_bank = v & 0x03       # bit 3 is the rumble motor
        @rumble = (v & 0x08) != 0
      end
    end

    def set_romx
      @romx = (@rom_bank % @rom_banks) * 0x4000
    end

    def push16(v)
      @sp = (@sp - 1) & 0xffff
      wr(@sp, v >> 8)
      @sp = (@sp - 1) & 0xffff
      wr(@sp, v & 0xff)
    end

    def pop16
      lo = rd(@sp)
      hi = rd((@sp + 1) & 0xffff)
      @sp = (@sp + 2) & 0xffff
      (hi << 8) | lo
    end

    def f_pack
      (@fz ? 0x80 : 0) | (@fn ? 0x40 : 0) | (@fh ? 0x20 : 0) | (@fc ? 0x10 : 0)
    end

    def f_unpack(f)
      @fz = f[7] == 1; @fn = f[6] == 1; @fh = f[5] == 1; @fc = f[4] == 1
    end

    def daa
      a = @a
      if !@fn
        if @fc || a > 0x99
          a += 0x60
          @fc = true
        end
        a += 0x06 if @fh || (a & 0x0f) > 0x09
      else
        a -= 0x60 if @fc
        a -= 0x06 if @fh
      end
      @a = a & 0xff
      @fz = @a == 0
      @fh = false
    end

    def ei
      @ime = true
      @next_ev = @cyc   # a pending interrupt is taken at the next block
    end

    #--------------------------------------------------------------------------
    # I/O registers
    #--------------------------------------------------------------------------
    def io_rd(r)
      case r
      when R_P1
        p1 = @io[R_P1]
        v = 0x0f
        v &= ~(@buttons >> 4) & 0x0f if (p1 & 0x10) == 0
        v &= ~@buttons & 0x0f if (p1 & 0x20) == 0
        0xc0 | (p1 & 0x30) | v
      when R_DIV then (@cyc >> 8) & 0xff
      when R_TIMA then update_timer; @io[R_TIMA]
      when R_LY then lcd_on? ? line_now : 0
      when R_STAT
        ly = line_now
        mode = !lcd_on? ? 0 : ly >= VBLANK_LINE ? 1 : (pos = (@cyc - @frame_start) % LINE_CYCLES) < 80 ? 2 : pos < 252 ? 3 : 0
        0x80 | (@io[R_STAT] & 0x78) | (ly == @io[R_LYC] ? 4 : 0) | mode
      when R_IF then 0xe0 | @io[R_IF]
      when R_VBK then 0xfe | (@vbank >> 13)
      when R_SVBK then 0xf8 | (@wbank >> 12)
      when R_KEY1 then 0x7e
      when R_HDMA5 then 0xff
      when R_BCPD then @bg_pal[@io[R_BCPS] & 0x3f]
      when R_OCPD then @obj_pal[@io[R_OCPS] & 0x3f]
      else @io[r]
      end
    end

    def io_wr(r, v)
      @snd_log << [@cyc, r, v] if @snd_log && r >= 0x10 && r < 0x40
      case r
      when R_DIV then @io[R_DIV] = 0
      when R_TIMA, R_TMA then update_timer; @io[r] = v
      when R_TAC
        update_timer
        @io[R_TAC] = v
        @timer_next = (v & 4) != 0 ? @cyc + timer_period : nil
        recalc_next
      when R_IF then @io[R_IF] = v & 0x1f; recalc_next
      when R_LCDC
        was = lcd_on?
        @io[R_LCDC] = v
        if !was && lcd_on?           # LCD switched on: line 0 starts now
          @frame_start = @cyc
          @line = 0
          @next_line = @cyc + LINE_CYCLES
          start_frame_regs
          recalc_next
        end
        note_reg_change
      when R_SCY, R_SCX, R_WY, R_WX, 0x47, 0x48, 0x49
        @io[r] = v
        note_reg_change
      when R_LYC then @io[R_LYC] = v
      when R_DMA
        src = v << 8
        0xa0.times { |i| @oam[i] = rd(src + i) }
      when R_VBK then @vbank = (v & 1) * 0x2000
      when R_SVBK
        b = v & 7
        @wbank = (b == 0 ? 1 : b) * 0x1000
      when R_HDMA5
        src = ((@io[R_HDMA1] << 8) | @io[R_HDMA1 + 1]) & 0xfff0
        dst = 0x8000 | ((((@io[R_HDMA1 + 2] << 8) | @io[R_HDMA1 + 3]) & 0x1ff0))
        len = ((v & 0x7f) + 1) * 16
        len.times do |i|
          o = (dst + i) & 0x1fff
          @vram[@vbank + o] = rd(src + i)
          @tile_dirty[(@vbank >> 13) * 384 + (o >> 4)] = true if o < 0x1800
        end
        @io[R_HDMA5] = 0xff
      when R_BCPD
        i = @io[R_BCPS]
        @bg_pal[i & 0x3f] = v
        @pal_dirty = true
        @io[R_BCPS] = (i & 0x80) | ((i + 1) & 0x3f) if i[7] == 1
      when R_OCPD
        i = @io[R_OCPS]
        @obj_pal[i & 0x3f] = v
        @pal_dirty = true
        @io[R_OCPS] = (i & 0x80) | ((i + 1) & 0x3f) if i[7] == 1
      else
        @io[r] = v
      end
    end

    def lcd_on?; @io[R_LCDC][7] == 1; end

    def line_now
      l = (@cyc - @frame_start) / LINE_CYCLES
      l < FRAME_LINES ? l : FRAME_LINES - 1
    end

    #--------------------------------------------------------------------------
    # timer
    #--------------------------------------------------------------------------
    def timer_period
      [1024, 16, 64, 256][@io[R_TAC] & 3]
    end

    def update_timer
      return unless @timer_next
      while @cyc >= @timer_next
        t = @io[R_TIMA] + 1
        if t > 0xff
          t = @io[R_TMA]
          @io[R_IF] |= 0x04
        end
        @io[R_TIMA] = t
        @timer_next += timer_period
      end
    end

    #--------------------------------------------------------------------------
    # mid-frame register changes (status bar splits): the renderer draws each
    # band of lines with the registers that were set for it
    #--------------------------------------------------------------------------
    def start_frame_regs
      @line_regs = [[0, @io[R_LCDC], @io[R_SCX], @io[R_SCY], @io[R_WX], @io[R_WY]]]
    end

    def note_reg_change
      return unless lcd_on?
      ly = line_now
      return if ly >= VBLANK_LINE
      regs = [ly, @io[R_LCDC], @io[R_SCX], @io[R_SCY], @io[R_WX], @io[R_WY]]
      if @line_regs.last[0] == ly
        @line_regs[-1] = regs
      else
        @line_regs << regs
      end
    end

    #--------------------------------------------------------------------------
    # events and interrupts
    #--------------------------------------------------------------------------
    def recalc_next
      n = @next_line
      n = @timer_next if @timer_next && @timer_next < n
      @next_ev = n
    end

    # at a block start (pc) when @cyc >= @next_ev
    def service(pc)
      while @cyc >= @next_line
        advance_line
      end
      update_timer
      recalc_next
      take_interrupt(pc) if @ime && (@ie & @io[R_IF] & 0x1f) != 0
    end

    def advance_line
      @next_line += LINE_CYCLES
      if !lcd_on?
        # no LCD: keep a frame rhythm so the game loop still gets frames
        if @next_line - @frame_start >= FRAME_CYCLES
          @frame_start += FRAME_CYCLES
          end_frame(false)
        end
        return
      end
      @line += 1
      if @line == VBLANK_LINE
        @io[R_IF] |= 0x01
        end_frame(true)
      elsif @line >= FRAME_LINES
        @line = 0
        @frame_start += FRAME_CYCLES
        start_frame_regs
      end
      if @line == @io[R_LYC] && @io[R_STAT][6] == 1
        @io[R_IF] |= 0x02
      end
    end

    def end_frame(visible)
      @frames += 1
      @frame_handler&.call(self, visible)
      Fiber.yield if @fiber
    end

    def take_interrupt(pc)
      pending = @ie & @io[R_IF] & 0x1f
      bit = (0..4).find { |i| pending[i] == 1 }
      @io[R_IF] &= ~(1 << bit)
      @ime = false
      @irq_count = (@irq_count || 0) + 1
      push16(pc)
      @cyc += 20
      r = run_key(0x40 + bit * 8)
      raise ControlTransfer.new(r) if r != pc
    end

    def halt_wait(pc)
      start = @irq_count || 0
      loop do
        if (@ie & @io[R_IF] & 0x1f) != 0
          service(pc)
          return
        end
        @cyc = @next_ev if @cyc < @next_ev
        service(pc)
        return if (@irq_count || 0) != start
      end
    end

    #--------------------------------------------------------------------------
    # calls
    #--------------------------------------------------------------------------
    def dyn_key(addr)
      if addr < 0x4000 then addr
      elsif addr < 0x8000 then (@rom_bank << 16) | addr
      else (0xff << 16) | addr
      end
    end

    def tramp(r)
      r >= TAIL ? run_key(r - TAIL) : r
    end

    def run_key(k)
      loop do
        h = @hooks[k]
        r = if h
              h.call(self)
            elsif (m = FUNCS[k])
              send(m)
            elsif k == 0xffff80
              n_hpushsprite
            else
              # an address the tracer never saw as an entry (a computed jump
              # into the middle of code): run it instruction by instruction
              interp(k & 0xffff)
            end
        return r if r < TAIL
        k = r - TAIL
      end
    end

    # hPushSprite: OAM DMA from wSpriteBuffer (its address is the routine's
    # first operand), then the wait loop
    def n_hpushsprite
      io_wr(R_DMA, @hram[1])
      @a = 0; @fz = true; @fn = true
      @cyc += 16 + 0x28 * 16
      pop16
    end

    #--------------------------------------------------------------------------
    # running: the game runs in a Fiber that yields once per frame
    #--------------------------------------------------------------------------
    def start
      @fiber = Fiber.new do
        key = 0x100
        loop do
          begin
            r = run_key(key)
            key = dyn_key(r)
          rescue ControlTransfer => e
            key = dyn_key(e.addr)
          end
        end
      end
    end

    # runs one frame (until the next line 144 / frame boundary)
    def step_frame
      @fiber.resume
    end

    # hooks for registers / cpu state (audio hooks, saving)
    attr_accessor :a, :b, :c, :d, :e, :h, :l, :sp, :rom_bank
  end
end
