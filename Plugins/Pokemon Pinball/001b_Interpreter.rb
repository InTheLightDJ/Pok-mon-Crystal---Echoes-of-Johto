#==============================================================================
# Pokémon Pinball (GBC) - fallback SM83 interpreter.
#
# The recompiled code covers every function and jump target the tracer saw.
# A few places jump into the middle of code at run time (e.g. the Pokédex
# jumps into an unrolled `ld [hl+], a` run to fill a computed length). For
# such an address Machine#run_key calls #interp, which runs instructions one
# by one with the same conventions as the generated methods: it returns the
# popped address on `ret`, TAIL + key to jump into a known function, and a
# call that gets back an address it didn't push returns that upward.
#==============================================================================
module PinballGBC
  class Machine
    R8 = %i[@b @c @d @e @h @l hl @a].freeze

    def interp(pc)
      loop do
        service(pc) if @cyc >= @next_ev
        op = rd(pc)
        case op
        when 0x00 then @cyc += 4; pc += 1
        when 0x76 then @cyc += 4; halt_wait(pc + 1); pc += 1
        when 0x40..0x7f
          v = r8_get(op & 7)
          r8_set((op >> 3) & 7, v)
          @cyc += ((op & 7) == 6 || ((op >> 3) & 7) == 6) ? 8 : 4
          pc += 1
        when 0x80..0xbf
          alu((op >> 3) & 7, r8_get(op & 7))
          @cyc += (op & 7) == 6 ? 8 : 4
          pc += 1
        when 0xc6, 0xce, 0xd6, 0xde, 0xe6, 0xee, 0xf6, 0xfe
          alu((op >> 3) & 7, rd(pc + 1))
          @cyc += 8
          pc += 2
        when 0x04, 0x0c, 0x14, 0x1c, 0x24, 0x2c, 0x34, 0x3c, 0x05, 0x0d, 0x15, 0x1d, 0x25, 0x2d, 0x35, 0x3d
          r = (op >> 3) & 7
          x = r8_get(r)
          if op & 1 == 0
            @fh = (x & 0xf) == 0xf; x = (x + 1) & 0xff; @fn = false
          else
            @fh = (x & 0xf) == 0; x = (x - 1) & 0xff; @fn = true
          end
          @fz = x == 0
          r8_set(r, x)
          @cyc += r == 6 ? 12 : 4
          pc += 1
        when 0x06, 0x0e, 0x16, 0x1e, 0x26, 0x2e, 0x36, 0x3e
          r8_set((op >> 3) & 7, rd(pc + 1))
          @cyc += op == 0x36 ? 12 : 8
          pc += 2
        when 0x01, 0x11, 0x21, 0x31
          r16_set(op >> 4, rd(pc + 1) | (rd(pc + 2) << 8))
          @cyc += 12
          pc += 3
        when 0x03, 0x13, 0x23, 0x33, 0x0b, 0x1b, 0x2b, 0x3b
          i = (op >> 4) & 3
          r16_set(i, (r16_get(i) + (op & 8 == 0 ? 1 : -1)) & 0xffff)
          @cyc += 8
          pc += 1
        when 0x09, 0x19, 0x29, 0x39
          hl = (@h << 8) | @l
          x = r16_get((op >> 4) & 3)
          v = hl + x
          @fn = false; @fh = (hl & 0xfff) + (x & 0xfff) > 0xfff; @fc = v > 0xffff
          v &= 0xffff
          @h = v >> 8; @l = v & 0xff
          @cyc += 8
          pc += 1
        when 0x02 then wr((@b << 8) | @c, @a); @cyc += 8; pc += 1
        when 0x12 then wr((@d << 8) | @e, @a); @cyc += 8; pc += 1
        when 0x0a then @a = rd((@b << 8) | @c); @cyc += 8; pc += 1
        when 0x1a then @a = rd((@d << 8) | @e); @cyc += 8; pc += 1
        when 0x22, 0x32, 0x2a, 0x3a
          hl = (@h << 8) | @l
          op & 8 == 0 ? wr(hl, @a) : (@a = rd(hl))
          hl = (hl + (op & 0x10 == 0 ? 1 : -1)) & 0xffff
          @h = hl >> 8; @l = hl & 0xff
          @cyc += 8
          pc += 1
        when 0x07 then @fc = @a >= 0x80; @a = ((@a << 1) | (@a >> 7)) & 0xff; @fz = @fn = @fh = false; @cyc += 4; pc += 1
        when 0x0f then @fc = @a.odd?; @a = (@a >> 1) | ((@a & 1) << 7); @fz = @fn = @fh = false; @cyc += 4; pc += 1
        when 0x17 then cy = @fc ? 1 : 0; @fc = @a >= 0x80; @a = ((@a << 1) | cy) & 0xff; @fz = @fn = @fh = false; @cyc += 4; pc += 1
        when 0x1f then cy = @fc ? 0x80 : 0; @fc = @a.odd?; @a = (@a >> 1) | cy; @fz = @fn = @fh = false; @cyc += 4; pc += 1
        when 0x27 then daa; @cyc += 4; pc += 1
        when 0x2f then @a ^= 0xff; @fn = @fh = true; @cyc += 4; pc += 1
        when 0x37 then @fn = @fh = false; @fc = true; @cyc += 4; pc += 1
        when 0x3f then @fn = @fh = false; @fc = !@fc; @cyc += 4; pc += 1
        when 0x08
          a = rd(pc + 1) | (rd(pc + 2) << 8)
          wr(a, @sp & 0xff); wr(a + 1, @sp >> 8)
          @cyc += 20
          pc += 3
        when 0x18, 0x20, 0x28, 0x30, 0x38
          e = rd(pc + 1)
          e -= 256 if e >= 128
          if op == 0x18 || cond?((op >> 3) & 3)
            @cyc += 12
            r = jump_to(pc + 2 + e)
            return r if r
            pc = (pc + 2 + e) & 0xffff
          else
            @cyc += 8
            pc += 2
          end
        when 0xc3, 0xc2, 0xca, 0xd2, 0xda
          t = rd(pc + 1) | (rd(pc + 2) << 8)
          if op == 0xc3 || cond?((op >> 3) & 3)
            @cyc += 16
            r = jump_to(t)
            return r if r
            pc = t
          else
            @cyc += 12
            pc += 3
          end
        when 0xe9 then @cyc += 4; return TAIL + dyn_key((@h << 8) | @l)
        when 0xcd, 0xc4, 0xcc, 0xd4, 0xdc
          t = rd(pc + 1) | (rd(pc + 2) << 8)
          if op == 0xcd || cond?((op >> 3) & 3)
            @cyc += 24
            ret = pc + 3
            push16(ret)
            r = run_key(dyn_key(t))
            return r if r != ret
            pc = ret
          else
            @cyc += 12
            pc += 3
          end
        when 0xc7, 0xcf, 0xd7, 0xdf, 0xe7, 0xef, 0xf7, 0xff
          @cyc += 16
          ret = pc + 1
          push16(ret)
          r = run_key(op & 0x38)
          return r if r != ret
          pc = ret
        when 0xc9 then @cyc += 16; return pop16
        when 0xd9 then @cyc += 16; @ime = true; return pop16
        when 0xc0, 0xc8, 0xd0, 0xd8
          if cond?((op >> 3) & 3)
            @cyc += 20
            return pop16
          end
          @cyc += 8
          pc += 1
        when 0xc1, 0xd1, 0xe1, 0xf1
          v = pop16
          if op == 0xf1
            @a = v >> 8; f_unpack(v & 0xff)
          else
            r16_set((op >> 4) & 3, v)
          end
          @cyc += 12
          pc += 1
        when 0xc5, 0xd5, 0xe5, 0xf5
          push16(op == 0xf5 ? (@a << 8) | f_pack : r16_get((op >> 4) & 3))
          @cyc += 16
          pc += 1
        when 0xe0 then wr(0xff00 | rd(pc + 1), @a); @cyc += 12; pc += 2
        when 0xf0 then @a = rd(0xff00 | rd(pc + 1)); @cyc += 12; pc += 2
        when 0xe2 then wr(0xff00 | @c, @a); @cyc += 8; pc += 1
        when 0xf2 then @a = rd(0xff00 | @c); @cyc += 8; pc += 1
        when 0xea then wr(rd(pc + 1) | (rd(pc + 2) << 8), @a); @cyc += 16; pc += 3
        when 0xfa then @a = rd(rd(pc + 1) | (rd(pc + 2) << 8)); @cyc += 16; pc += 3
        when 0xe8, 0xf8
          e = rd(pc + 1)
          @fz = @fn = false
          @fh = (@sp & 0xf) + (e & 0xf) > 0xf
          @fc = (@sp & 0xff) + e > 0xff
          v = (@sp + (e >= 128 ? e - 256 : e)) & 0xffff
          if op == 0xe8
            @sp = v; @cyc += 16
          else
            @h = v >> 8; @l = v & 0xff; @cyc += 12
          end
          pc += 2
        when 0xf9 then @sp = (@h << 8) | @l; @cyc += 8; pc += 1
        when 0xf3 then @ime = false; @cyc += 4; pc += 1
        when 0xfb then ei; @cyc += 4; pc += 1
        when 0xcb then cb_op(rd(pc + 1)); pc += 2
        else
          raise MachineError, "bad opcode %02x at %02x:%04x" % [op, pc >= 0x4000 ? @rom_bank : 0, pc]
        end
      end
    end

    private

    # a jump target that is a known function: hand over to its compiled code
    def jump_to(t)
      k = dyn_key(t & 0xffff)
      FUNCS.key?(k) ? TAIL + k : nil
    end

    def cond?(c)
      case c
      when 0 then !@fz
      when 1 then @fz
      when 2 then !@fc
      else @fc
      end
    end

    def r8_get(r)
      r == 6 ? rd((@h << 8) | @l) : instance_variable_get(R8[r])
    end

    def r8_set(r, v)
      r == 6 ? wr((@h << 8) | @l, v) : instance_variable_set(R8[r], v)
    end

    def r16_get(i)
      case i & 3
      when 0 then (@b << 8) | @c
      when 1 then (@d << 8) | @e
      when 2 then (@h << 8) | @l
      else @sp
      end
    end

    def r16_set(i, v)
      case i & 3
      when 0 then @b = v >> 8; @c = v & 0xff
      when 1 then @d = v >> 8; @e = v & 0xff
      when 2 then @h = v >> 8; @l = v & 0xff
      else @sp = v
      end
    end

    def alu(k, x)
      case k
      when 0, 1
        cy = k == 1 && @fc ? 1 : 0
        v = @a + x + cy
        @fh = (@a & 0xf) + (x & 0xf) + cy > 0xf; @fc = v > 0xff; @fn = false
        @a = v & 0xff; @fz = @a == 0
      when 2, 3, 7
        cy = k == 3 && @fc ? 1 : 0
        v = @a - x - cy
        @fh = (@a & 0xf) < (x & 0xf) + cy; @fc = v < 0; @fn = true
        if k == 7
          @fz = (v & 0xff) == 0
        else
          @a = v & 0xff; @fz = @a == 0
        end
      when 4 then @a &= x; @fz = @a == 0; @fn = false; @fh = true; @fc = false
      when 5 then @a ^= x; @fz = @a == 0; @fn = @fh = @fc = false
      when 6 then @a |= x; @fz = @a == 0; @fn = @fh = @fc = false
      end
    end

    def cb_op(op)
      r = op & 7
      x = r8_get(r)
      y = (op >> 3) & 7
      case op >> 6
      when 0
        case y
        when 0 then @fc = x >= 0x80; x = ((x << 1) | (x >> 7)) & 0xff
        when 1 then @fc = x.odd?; x = (x >> 1) | ((x & 1) << 7)
        when 2 then cy = @fc ? 1 : 0; @fc = x >= 0x80; x = ((x << 1) | cy) & 0xff
        when 3 then cy = @fc ? 0x80 : 0; @fc = x.odd?; x = (x >> 1) | cy
        when 4 then @fc = x >= 0x80; x = (x << 1) & 0xff
        when 5 then @fc = x.odd?; x = (x >> 1) | (x & 0x80)
        when 6 then @fc = false; x = ((x << 4) | (x >> 4)) & 0xff
        else @fc = x.odd?; x >>= 1
        end
        @fz = x == 0; @fn = @fh = false
        r8_set(r, x)
        @cyc += r == 6 ? 16 : 8
      when 1
        @fz = (x >> y) & 1 == 0; @fn = false; @fh = true
        @cyc += r == 6 ? 12 : 8
      when 2
        r8_set(r, x & ~(1 << y) & 0xff)
        @cyc += r == 6 ? 16 : 8
      else
        r8_set(r, x | (1 << y))
        @cyc += r == 6 ? 16 : 8
      end
    end
  end
end
