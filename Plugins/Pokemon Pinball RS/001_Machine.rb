#==============================================================================
# Pokémon Pinball: Ruby & Sapphire (GBA) - the machine the translated game
# runs on (Pinball-mod/tools/rs/transpile.py turns the decomp's C into Ruby
# methods of this class: f_<C name>).
#   Memory: EWRAM / IWRAM / IO / palettes / VRAM / OAM / ROM / SRAM as
#   binary Strings, read and written by r8/r16/r32 (rs8.. signed), w8/w16/w32.
#   The game runs in a Fiber: VBlankIntrWait (the BIOS call every frame
#   waits on) runs the rest of the frame -- VCount interrupts at their line,
#   the picture, the VBlank interrupt -- and yields to the player.
#   Display registers are snapshotted at each VCount interrupt, so the
#   screen is drawn in bands (the score bar, the shop panel...).
#   BIOS calls, memcpy/memset and the sound engine's entry points are native.
#==============================================================================
module PinballRS
  class Machine
    INTR_CHECK = 0x03007FF8
    SP_TOP     = 0x03007F00
    # interrupt bits, in IntrMain's order (gIntrTable index = position)
    IRQ_ORDER = [0x80, 0x40, 0x1, 0x2, 0x4, 0x8, 0x10, 0x20, 0x100, 0x200, 0x400, 0x800, 0x1000, 0x2000]
    IRQ_VBLANK = 0x1
    IRQ_VCOUNT = 0x4
    # display registers kept per band (DISPCNT .. BLDY)
    DISP_REGS = 0x56

    attr_reader :ew, :iw, :io, :pal, :vram, :oam, :sram, :rom, :frames, :bands
    attr_accessor :buttons, :vram_dirty, :pal_dirty, :sram_dirty, :hooks

    def initialize(rom)
      @rom = rom
      @rom_size = rom.bytesize
      @ew = "\0".b * 0x40000
      @iw = "\0".b * 0x8000
      @io = "\0".b * 0x400
      @pal = "\0".b * 0x400
      @vram = "\0".b * 0x18000
      @oam = "\0".b * 0x400
      @sram = "\xff".b * 0x10000
      @sp = SP_TOP
      @buttons = 0
      @line = 0
      @frames = 0
      @hblank_toggle = 0
      @vram_dirty = Array.new(0x18000 >> 5, true)
      @pal_dirty = true
      @sram_dirty = false
      @vblank_dma = []
      @hooks = {}
      @bands = []
      @no_wait_loops = 0
    end

    #--------------------------------------------------------------------------
    # running
    #--------------------------------------------------------------------------
    def start
      @fiber = Fiber.new do
        f_AgbMain
      end
    end

    # one frame: the game runs until its next VBlankIntrWait
    def step_frame
      @fiber.resume
    end

    #--------------------------------------------------------------------------
    # memory
    #--------------------------------------------------------------------------
    def r8(a)
      case a >> 24
      when 2 then @ew.getbyte(a & 0x3FFFF)
      when 3 then @iw.getbyte(a & 0x7FFF)
      when 8, 9 then @rom.getbyte(a & 0x1FFFFFF) || 0
      when 4 then (io_read(a & 0x3FE) >> ((a & 1) << 3)) & 0xFF
      when 6 then @vram.getbyte(vaddr(a))
      when 5 then @pal.getbyte(a & 0x3FF)
      when 7 then @oam.getbyte(a & 0x3FF)
      when 0xE then @sram.getbyte(a & 0xFFFF)
      else 0
      end
    end

    def r16(a)
      case a >> 24
      when 2 then o = a & 0x3FFFE; @ew.getbyte(o) | (@ew.getbyte(o + 1) << 8)
      when 3 then o = a & 0x7FFE; @iw.getbyte(o) | (@iw.getbyte(o + 1) << 8)
      when 8, 9 then o = a & 0x1FFFFFE; o < @rom_size ? @rom.getbyte(o) | (@rom.getbyte(o + 1) << 8) : 0
      when 4 then io_read(a & 0x3FE)
      when 6 then o = vaddr(a) & ~1; @vram.getbyte(o) | (@vram.getbyte(o + 1) << 8)
      when 5 then o = a & 0x3FE; @pal.getbyte(o) | (@pal.getbyte(o + 1) << 8)
      when 7 then o = a & 0x3FE; @oam.getbyte(o) | (@oam.getbyte(o + 1) << 8)
      when 0xE then v = @sram.getbyte(a & 0xFFFF); v | (v << 8)
      else 0
      end
    end

    def r32(a)
      case a >> 24
      when 2
        o = a & 0x3FFFC
        @ew.getbyte(o) | (@ew.getbyte(o + 1) << 8) | (@ew.getbyte(o + 2) << 16) | (@ew.getbyte(o + 3) << 24)
      when 3
        o = a & 0x7FFC
        @iw.getbyte(o) | (@iw.getbyte(o + 1) << 8) | (@iw.getbyte(o + 2) << 16) | (@iw.getbyte(o + 3) << 24)
      when 8, 9
        o = a & 0x1FFFFFC
        return 0 if o >= @rom_size
        @rom.getbyte(o) | (@rom.getbyte(o + 1) << 8) | (@rom.getbyte(o + 2) << 16) | (@rom.getbyte(o + 3) << 24)
      else
        r16(a & ~3) | (r16((a & ~3) + 2) << 16)
      end
    end

    def r64(a) = r32(a) | (r32(a + 4) << 32)
    def rs8(a) = (r8(a) ^ 0x80) - 0x80
    def rs16(a) = (r16(a) ^ 0x8000) - 0x8000
    def rs32(a) = (r32(a) ^ 0x80000000) - 0x80000000
    def rs64(a) = (r64(a) ^ (1 << 63)) - (1 << 63)

    def w8(a, v)
      case a >> 24
      when 2 then @ew.setbyte(a & 0x3FFFF, v & 0xFF)
      when 3 then @iw.setbyte(a & 0x7FFF, v & 0xFF)
      when 4
        o = a & 0x3FF
        old = io_read(o & ~1)
        io_write(o & ~1, (o & 1) == 0 ? (old & 0xFF00) | (v & 0xFF) : (old & 0xFF) | ((v & 0xFF) << 8))
      when 6
        # 8-bit VRAM writes store the byte twice (BG area)
        o = vaddr(a) & ~1
        @vram.setbyte(o, v & 0xFF)
        @vram.setbyte(o + 1, v & 0xFF)
        @vram_dirty[o >> 5] = true
      when 5
        o = a & 0x3FE
        @pal.setbyte(o, v & 0xFF)
        @pal.setbyte(o + 1, v & 0xFF)
        @pal_dirty = true
      when 0xE
        @sram.setbyte(a & 0xFFFF, v & 0xFF)
        @sram_dirty = true
      end
    end

    def w16(a, v)
      case a >> 24
      when 2 then o = a & 0x3FFFE; @ew.setbyte(o, v & 0xFF); @ew.setbyte(o + 1, (v >> 8) & 0xFF)
      when 3 then o = a & 0x7FFE; @iw.setbyte(o, v & 0xFF); @iw.setbyte(o + 1, (v >> 8) & 0xFF)
      when 4 then io_write(a & 0x3FE, v & 0xFFFF)
      when 6
        o = vaddr(a) & ~1
        @vram.setbyte(o, v & 0xFF)
        @vram.setbyte(o + 1, (v >> 8) & 0xFF)
        @vram_dirty[o >> 5] = true
      when 5 then o = a & 0x3FE; @pal.setbyte(o, v & 0xFF); @pal.setbyte(o + 1, (v >> 8) & 0xFF); @pal_dirty = true
      when 7 then o = a & 0x3FE; @oam.setbyte(o, v & 0xFF); @oam.setbyte(o + 1, (v >> 8) & 0xFF)
      when 0xE then w8(a, v)
      end
    end

    def w32(a, v)
      case a >> 24
      when 2
        o = a & 0x3FFFC
        @ew.setbyte(o, v & 0xFF); @ew.setbyte(o + 1, (v >> 8) & 0xFF)
        @ew.setbyte(o + 2, (v >> 16) & 0xFF); @ew.setbyte(o + 3, (v >> 24) & 0xFF)
      when 3
        o = a & 0x7FFC
        @iw.setbyte(o, v & 0xFF); @iw.setbyte(o + 1, (v >> 8) & 0xFF)
        @iw.setbyte(o + 2, (v >> 16) & 0xFF); @iw.setbyte(o + 3, (v >> 24) & 0xFF)
      else
        w16(a & ~3, v & 0xFFFF)
        w16((a & ~3) + 2, (v >> 16) & 0xFFFF)
      end
    end

    def w64(a, v)
      w32(a, v & 0xFFFFFFFF)
      w32(a + 4, (v >> 32) & 0xFFFFFFFF)
    end

    def vaddr(a)
      o = a & 0x1FFFF
      o >= 0x18000 ? o - 0x8000 : o
    end

    # region String + offset for a plain-memory address (nil: IO / unmapped)
    def region(a)
      case a >> 24
      when 2 then [@ew, a & 0x3FFFF, 0x40000]
      when 3 then [@iw, a & 0x7FFF, 0x8000]
      when 8, 9 then [@rom, a & 0x1FFFFFF, @rom_size]
      when 5 then [@pal, a & 0x3FF, 0x400]
      when 6 then [@vram, vaddr(a), 0x18000]
      when 7 then [@oam, a & 0x3FF, 0x400]
      when 0xE then [@sram, a & 0xFFFF, 0x10000]
      end
    end

    def touched(a, n)
      case a >> 24
      when 5 then @pal_dirty = true
      when 6
        o = vaddr(a)
        (o >> 5).upto([(o + n - 1) >> 5, (0x18000 >> 5) - 1].min) { |i| @vram_dirty[i] = true }
      when 0xE then @sram_dirty = true
      end
    end

    # n bytes from src to dst (forward, like the GBA's copies)
    def copy_bytes(dst, src, n)
      return if n <= 0
      d, doff, dsize = region(dst)
      s, soff, ssize = region(src)
      if d && s && doff + n <= dsize && soff + n <= ssize && d != @rom
        if d.equal?(s) && doff > soff && doff < soff + n
          n.times { |i| d.setbyte(doff + i, s.getbyte(soff + i)) }   # overlapping: byte by byte, forward
        else
          d[doff, n] = s.byteslice(soff, n)
        end
        touched(dst, n)
      else
        i = 0
        while i < n
          w8(dst + i, r8(src + i))
          i += 1
        end
      end
    end

    def fill_bytes(dst, pattern, n)
      return if n <= 0
      d, doff, dsize = region(dst)
      if d && doff + n <= dsize && d != @rom
        reps = n / pattern.bytesize + 1
        d[doff, n] = (pattern * reps).byteslice(0, n)
        touched(dst, n)
      else
        n.times { |i| w8(dst + i, pattern.getbyte(i % pattern.bytesize)) }
      end
    end

    #--------------------------------------------------------------------------
    # C helpers
    #--------------------------------------------------------------------------
    def cdiv(a, b)
      return 0 if b == 0
      q = a.abs / b.abs
      (a < 0) != (b < 0) ? -q : q
    end

    def cmod(a, b)
      return a if b == 0
      a - cdiv(a, b) * b
    end

    def call_ptr(addr, *args)
      name = FUNCS[addr & ~1] || NATIVE_FUNCS[addr & ~1]
      raise "PinballRS: call to #{format('%08X', addr)} (no function there)" unless name
      send(name, *args)
    end

    def memcpy(dst, src, n)
      copy_bytes(dst, src, n)
      dst
    end

    def memset(dst, v, n)
      fill_bytes(dst, (v & 0xFF).chr.b, n)
      dst
    end

    def f_memcpy(d, s, n) = memcpy(d, s, n)
    def f_memset(d, v, n) = memset(d, v, n)

    def f_strlen(s)
      n = 0
      n += 1 while r8(s + n) != 0
      n
    end

    def sym(name) = SYMS.fetch(name)

    #--------------------------------------------------------------------------
    # IO registers
    #--------------------------------------------------------------------------
    def io_get(o) = @io.getbyte(o) | (@io.getbyte(o + 1) << 8)

    def io_set(o, v)
      @io.setbyte(o, v & 0xFF)
      @io.setbyte(o + 1, (v >> 8) & 0xFF)
    end

    def io_read(o)
      case o
      when 0x004    # DISPSTAT: vblank / hblank / vcount match + settings
        v = io_get(4) & 0xFFF8
        v |= 1 if @line >= 160 && @line < 227
        @hblank_toggle ^= 2
        v |= @hblank_toggle
        v |= 4 if @line == (v >> 8)
        v
      when 0x006 then @line
      when 0x130 then ~@buttons & 0x3FF
      when 0x100, 0x104, 0x108, 0x10C then timer_count((o - 0x100) >> 2)
      else io_get(o)
      end
    end

    def io_write(o, v)
      case o
      when 0x004 then io_set(4, (io_get(4) & 7) | (v & 0xFFF8))
      when 0x006, 0x130 then nil
      when 0x202 then io_set(0x202, io_get(0x202) & ~v)   # IF: write 1 to acknowledge
      when 0x0BA, 0x0C6, 0x0D2, 0x0DE
        io_set(o, v)
        dma_control((o - 0xBA) / 12, v)
      when 0x102, 0x106, 0x10A, 0x10E
        n = (o - 0x102) >> 2
        if v & 0x80 != 0 && io_get(o) & 0x80 == 0
          @timer_start ||= []
          @timer_start[n] = timer_clock
        end
        io_set(o, v)
      when 0x100, 0x104, 0x108, 0x10C
        @timer_reload ||= []
        @timer_reload[(o - 0x100) >> 2] = v
      else
        io_set(o, v)
      end
    end

    # timers: counted from a clock of 280896 cycles a frame (the game only
    # reads them for seeds / timeouts)
    def timer_clock = @frames * 280_896 + @line * 1232

    def timer_count(n)
      cnt = io_get(0x102 + n * 4)
      return (@timer_reload || [])[n].to_i if cnt & 0x80 == 0
      prescale = [1, 64, 256, 1024][cnt & 3]
      ticks = (timer_clock - ((@timer_start || [])[n] || 0)) / prescale
      ((@timer_reload || [])[n].to_i + ticks) & 0xFFFF
    end

    def dma_control(ch, cnt)
      return if cnt & 0x8000 == 0
      timing = (cnt >> 12) & 3
      if timing == 0
        run_dma(ch)
        io_set(0xBA + ch * 12, cnt & 0x7FFF)
      elsif timing == 1
        @vblank_dma << ch unless @vblank_dma.include?(ch)
      end
      # HBlank / sound FIFO DMAs: not used by the translated game
    end

    def run_dma(ch)
      base = 0xB0 + ch * 12
      src = io_get(base) | (io_get(base + 2) << 16)
      dst = io_get(base + 4) | (io_get(base + 6) << 16)
      count = io_get(base + 8)
      cnt = io_get(base + 10)
      count = (ch == 3 ? 0x10000 : 0x4000) if count == 0
      unit = cnt & 0x400 != 0 ? 4 : 2
      dmode = (cnt >> 5) & 3
      smode = (cnt >> 7) & 3
      n = count * unit
      if smode == 0 && (dmode == 0 || dmode == 3)
        copy_bytes(dst, src, n)
      elsif smode == 2 && (dmode == 0 || dmode == 3)
        v = unit == 4 ? r32(src) : r16(src)
        fill_bytes(dst, [v].pack(unit == 4 ? "V" : "v"), n)
      else
        sstep = [unit, -unit, 0, unit][smode]
        dstep = [unit, -unit, 0, unit][dmode]
        count.times do
          unit == 4 ? w32(dst, r32(src)) : w16(dst, r16(src))
          src += sstep
          dst += dstep
        end
      end
    end

    #--------------------------------------------------------------------------
    # interrupts and frames
    #--------------------------------------------------------------------------
    # IntrMain (crt0.s): the first pending and enabled interrupt in its order
    def irq(bit)
      io_set(0x202, io_get(0x202) | bit)
      return if io_get(0x208) & 1 == 0 || io_get(0x200) & bit == 0
      i = IRQ_ORDER.index(bit)
      ie = io_get(0x200)
      ime = io_get(0x208)
      io_set(0x202, io_get(0x202) & ~bit)
      io_set(0x200, ie & ~bit & 0x20C0)
      io_set(0x208, 1)
      handler = r32(sym("gIntrTable") + i * 4)
      call_ptr(handler) if handler != 0
      io_set(0x200, ie)
      io_set(0x208, ime)
    end

    def display_regs = @io.byteslice(0, DISP_REGS)

    # the rest of this frame: VCount interrupts on their lines, the picture,
    # then VBlank
    def finish_frame
      @bands = []
      fired = {}
      loop do
        stat = io_get(4)
        lyc = stat >> 8
        break unless stat & 0x20 != 0 && io_get(0x200) & IRQ_VCOUNT != 0 && io_get(0x208) & 1 != 0
        break unless lyc >= @line && lyc < 160 && !fired[lyc]
        @bands << [@line, display_regs]
        fired[lyc] = true
        @line = lyc
        irq(IRQ_VCOUNT)
      end
      @bands << [@line, display_regs]
      @bands[0][0] = 0
      @line = 160
      @no_wait_loops = 0
      @frames += 1
      Fiber.yield
      @vblank_dma.each { |ch| run_dma(ch) }
      @vblank_dma.clear
      irq(IRQ_VBLANK) if io_get(4) & 0x8 != 0
      @line = 0
    end

    # BIOS VBlankIntrWait: until the VBlank handler has flagged INTR_CHECK
    def f_VBlankIntrWait
      w16(INTR_CHECK, r16(INTR_CHECK) & ~1)
      8.times do
        finish_frame
        break if r16(INTR_CHECK) & 1 != 0
      end
    end

    # a main loop that never waits for VBlank (interrupts off) still shows frames
    def frame_guard
      @no_wait_loops += 1
      return if @no_wait_loops < 3
      @no_wait_loops = 0
      @bands = [[0, display_regs]]
      @frames += 1
      Fiber.yield
    end

    #--------------------------------------------------------------------------
    # BIOS
    #--------------------------------------------------------------------------
    def f_RegisterRamReset(flags)
      @ew[0, 0x40000] = "\0".b * 0x40000 if flags & 1 != 0
      @iw[0, 0x7E00] = "\0".b * 0x7E00 if flags & 2 != 0
      if flags & 4 != 0
        @pal[0, 0x400] = "\0".b * 0x400
        @pal_dirty = true
      end
      if flags & 8 != 0
        @vram[0, 0x18000] = "\0".b * 0x18000
        @vram_dirty.fill(true)
      end
      @oam[0, 0x400] = "\0".b * 0x400 if flags & 0x10 != 0
    end

    def f_CpuSet(src, dst, cnt)
      n = cnt & 0x1FFFFF
      unit = cnt & 0x4000000 != 0 ? 4 : 2
      if cnt & 0x1000000 != 0
        v = unit == 4 ? r32(src) : r16(src)
        fill_bytes(dst, [v].pack(unit == 4 ? "V" : "v"), n * unit)
      else
        copy_bytes(dst, src, n * unit)
      end
    end

    def f_CpuFastSet(src, dst, cnt)
      n = ((cnt & 0x1FFFFF) + 7) & ~7
      if cnt & 0x1000000 != 0
        fill_bytes(dst, [r32(src)].pack("V"), n * 4)
      else
        copy_bytes(dst, src, n * 4)
      end
    end

    def lz77(src, dst)
      size = r32(src) >> 8
      out = String.new(capacity: size).b
      s, o, = region(src)
      raise "LZ77 source #{format('%08X', src)}" unless s
      o += 4
      while out.bytesize < size
        flags = s.getbyte(o)
        o += 1
        8.times do
          break if out.bytesize >= size
          if flags & 0x80 != 0
            b1 = s.getbyte(o)
            b2 = s.getbyte(o + 1)
            o += 2
            len = (b1 >> 4) + 3
            disp = (((b1 & 0xF) << 8) | b2) + 1
            len.times { out << out.getbyte(out.bytesize - disp) }
          else
            out << s.getbyte(o)
            o += 1
          end
          flags <<= 1
        end
      end
      out = out.byteslice(0, size)
      d, doff, = region(dst)
      d[doff, size] = out
      touched(dst, size)
    end

    def f_LZ77UnCompVram(src, dst) = lz77(src, dst)
    def f_LZ77UnCompWram(src, dst) = lz77(src, dst)

    def rl(src, dst)
      size = r32(src) >> 8
      out = String.new.b
      o = src + 4
      while out.bytesize < size
        flag = r8(o)
        o += 1
        if flag & 0x80 != 0
          v = r8(o)
          o += 1
          ((flag & 0x7F) + 3).times { out << v }
        else
          ((flag & 0x7F) + 1).times { out << r8(o); o += 1 }
        end
      end
      d, doff, = region(dst)
      d[doff, size] = out.byteslice(0, size)
      touched(dst, size)
    end

    def f_RLUnCompVram(src, dst) = rl(src, dst)
    def f_RLUnCompWram(src, dst) = rl(src, dst)

    def f_Sqrt(n) = Integer.sqrt(n & 0xFFFFFFFF)

    # BIOS ArcTan2(x, y): 0..0xFFFF
    def f_ArcTan2(x, y)
      a = Math.atan2(y, x)
      a += 2 * Math::PI if a < 0
      (a * 0x8000 / Math::PI).to_i & 0xFFFF
    end

    def bios_sin(angle) = (Math.sin(angle * Math::PI / 0x8000) * 0x4000).round
    def bios_cos(angle) = (Math.cos(angle * Math::PI / 0x8000) * 0x4000).round

    # ObjAffineSet(src {s16 xScale, yScale; u16 rotation}, dest, count, offset)
    def f_ObjAffineSet(src, dst, count, offset)
      count.times do
        sx = rs16(src)
        sy = rs16(src + 2)
        th = r16(src + 4) >> 8 << 8
        c = bios_cos(th)
        s = bios_sin(th)
        w16(dst, (sx * c) >> 14)
        w16(dst + offset, -(sx * s) >> 14)
        w16(dst + offset * 2, (sy * s) >> 14)
        w16(dst + offset * 3, (sy * c) >> 14)
        src += 8
        dst += offset * 4
      end
    end

    # BgAffineSet(src {s32 texX, texY; s16 scrX, scrY, sx, sy; u16 alpha}, dest {pa pb pc pd; x y}, count)
    def f_BgAffineSet(src, dst, count)
      count.times do
        tx = rs32(src)
        ty = rs32(src + 4)
        cx = rs16(src + 8)
        cy = rs16(src + 10)
        sx = rs16(src + 12)
        sy = rs16(src + 14)
        th = r16(src + 16) >> 8 << 8
        c = bios_cos(th)
        s = bios_sin(th)
        pa = (sx * c) >> 14
        pb = -(sx * s) >> 14
        pc = (sy * s) >> 14
        pd = (sy * c) >> 14
        w16(dst, pa)
        w16(dst + 2, pb)
        w16(dst + 4, pc)
        w16(dst + 6, pd)
        w32(dst + 8, tx - (pa * cx + pb * cy))
        w32(dst + 12, ty - (pc * cx + pd * cy))
        src += 20
        dst += 16
      end
    end

    def f_SoftReset(*) = raise(SoftReset)
    def f_MultiBoot(*) = 1
    def f_umul3232H32(a, b) = ((a & 0xFFFFFFFF) * (b & 0xFFFFFFFF)) >> 32

    class SoftReset < StandardError; end

    #--------------------------------------------------------------------------
    # no Game Boy Player, no rumble, no link cable, no debug print
    #--------------------------------------------------------------------------
    def f_InitGameBoyPlayer = nil
    def f_IsGbPlayerReady = 1

    def f_RestoreDefaultInterrupts
      w32(sym("gIntrTable"), Machine::FUNCS.key(:f_SerialIntr))
      w32(sym("gIntrTable") + 4, Machine::FUNCS.key(:f_Timer3Intr))
    end
    def f_InitSio32Hardware = nil

    # natives without an implementation do nothing (called once the
    # translated code is loaded)
    def self.define_native_stubs
      NATIVE_FUNCS.each_value do |name|
        next if method_defined?(name)
        define_method(name) { |*_| 0 }
      end
    end
  end

  # translated functions the machine replaces or wraps
  module MachineOverrides
    def f_MainLoopIter
      frame_guard
      super
    end

    # the SRAM routines the game copies into RAM: called where they are
    def f_SetSramFastFunc
      w32(sym("ReadSramFast"), Machine::FUNCS.key(:f_ReadSramFast_Core))
      w32(sym("VerifySramFast"), Machine::FUNCS.key(:f_VerifySramFast_Core))
    end
  end
  Machine.prepend(MachineOverrides)
end
