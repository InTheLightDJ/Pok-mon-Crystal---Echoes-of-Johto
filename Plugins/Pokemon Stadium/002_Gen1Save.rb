#===============================================================================
# Gen 1 (Red/Blue/Yellow) save file, built from the player's Pokémon and read back.
#
# Pokémon Stadium takes Pokémon from a Game Boy cartridge in a Transfer Pak. The port's
# emulated Transfer Pak uses a cartridge image (pN.gb) and its battery save (pN.sav);
# this writes that save from the player's party and PC, so the Pokémon show up in
# Stadium like a real cart's would.
#
# Only what Gen 1 can hold goes over: species #1-151 (regular form), Gen 1 moves,
# levels, DVs (IVs / 2), stat experience (from EVs), nicknames and OT. Eggs, Shadow
# Pokémon, other species and forms stay behind.
#
# SRAM layout (bank 1 = 0x2000-0x3FFF is the main data, checksummed):
#   0x2598 player name   0x25A3 dex owned  0x25B6 dex seen  0x25C9 bag
#   0x25F3 money (BCD)   0x25F6 rival name 0x2601 options   0x2602 badges
#   0x2605 player ID     0x27E6 PC items   0x284C current box (bit 7: boxes set up)
#   0x2F2C party         0x30C0 current box copy            0x3523 checksum
#   bank 2 (0x4000) boxes 1-6, bank 3 (0x6000) boxes 7-12, 0x462 bytes each;
#   checksum of the whole bank at +0x1A4C, then one per box.
#===============================================================================
module StadiumGen1
  SAVE_SIZE   = 0x8000
  PARTY_ADDR  = 0x2F2C
  CURBOX_ADDR = 0x30C0
  BOX_SIZE    = 0x462
  BOX_COUNT   = 12
  BOX_SLOTS   = 20
  MON_PARTY   = 44
  MON_BOX     = 33
  NAME_LEN    = 11

  SPECIES_BY_SYM   = {}
  SPECIES_BY_INDEX = {}
  SPECIES.each_with_index do |row, i|
    entry = { :sym => row[0], :dex => i + 1, :index => row[1], :base => row[2, 5],
              :types => row[7, 2], :catch => row[9], :growth => row[10] }
    SPECIES_BY_SYM[row[0]]   = entry
    SPECIES_BY_INDEX[row[1]] = entry
  end
  MOVE_INDEX = {}
  MOVES.each_with_index { |m, i| MOVE_INDEX[m[0]] = i + 1 }

  #-----------------------------------------------------------------------------
  # Text
  #-----------------------------------------------------------------------------
  CHARSET = { " " => 0x7F, "(" => 0x9A, ")" => 0x9B, ":" => 0x9C, ";" => 0x9D,
              "[" => 0x9E, "]" => 0x9F, "'" => 0xE0, "’" => 0xE0, "-" => 0xE3,
              "?" => 0xE6, "!" => 0xE7, "." => 0xE8, "♂" => 0xEF, "♀" => 0xF5,
              "/" => 0xF3, "," => 0xF4, "×" => 0xF1 }
  ("A".."Z").each_with_index { |c, i| CHARSET[c] = 0x80 + i }
  ("a".."z").each_with_index { |c, i| CHARSET[c] = 0xA0 + i }
  ("0".."9").each_with_index { |c, i| CHARSET[c] = 0xF6 + i }
  DECODE = CHARSET.invert.merge(0xE0 => "'")
  ACCENTS = { "é" => "e", "É" => "E", "è" => "e", "ê" => "e", "à" => "a", "á" => "a",
              "í" => "i", "ó" => "o", "ú" => "u", "ñ" => "n", "ü" => "u", "ö" => "o" }

  # nil when the text can't be written (empty after dropping unknown characters)
  def self.encode_text(text, max = 10)
    out = []
    text.to_s.each_char do |c|
      c = ACCENTS[c] || c
      code = CHARSET[c]
      out << code if code
      break if out.length >= max
    end
    return nil if out.empty?
    return out
  end

  def self.decode_text(bytes)
    s = ""
    bytes.each do |b|
      break if b == 0x50
      s << (DECODE[b] || "?")
    end
    return s
  end

  def self.species_text(sym)
    name = GameData::Species.get(sym).name.upcase
    name = name.delete(" ") if sym == :MRMIME   # MR.MIME
    return name
  end

  #-----------------------------------------------------------------------------
  # Stats
  #-----------------------------------------------------------------------------
  def self.exp_for_level(growth, level)
    n = level
    v = case growth
        when 3 then (6 * n**3) / 5 - 15 * n**2 + 100 * n - 140   # medium slow
        when 4 then (4 * n**3) / 5                                # fast
        when 5 then (5 * n**3) / 4                                # slow
        else        n**3                                          # medium fast
        end
    return [v, 0].max
  end

  def self.stat_bonus(stat_exp)
    return Math.sqrt(stat_exp).ceil.clamp(0, 255) / 4
  end

  # dvs = [atk, def, spd, spc]; stat_exp = [hp, atk, def, spd, spc]
  def self.calc_stats(info, level, dvs, stat_exp)
    hp_dv = ((dvs[0] & 1) << 3) | ((dvs[1] & 1) << 2) | ((dvs[2] & 1) << 1) | (dvs[3] & 1)
    all_dvs = [hp_dv] + dvs
    stats = (0...5).map do |i|
      ((info[:base][i] + all_dvs[i]) * 2 + stat_bonus(stat_exp[i])) * level / 100
    end
    stats[0] += level + 10
    (1...5).each { |i| stats[i] += 5 }
    return stats
  end

  #-----------------------------------------------------------------------------
  # Essentials Pokémon -> Gen 1 record
  #-----------------------------------------------------------------------------
  # A Gen 1 record: { :bytes => 44-byte party struct, :ot => [..], :nick => [..] }, or nil
  def self.from_pokemon(pkmn)
    return nil if !pkmn || pkmn.egg?
    return nil if pkmn.respond_to?(:shadowPokemon?) && pkmn.shadowPokemon?
    info = SPECIES_BY_SYM[pkmn.species]
    return nil if !info || pkmn.form != 0
    level = pkmn.level.clamp(2, 100)
    moves = pkmn.moves.map { |m| [MOVE_INDEX[m.id], m] }.select { |idx, _m| idx }
    moves = fallback_moves(pkmn, level) if moves.empty?
    return nil if moves.empty?
    dvs = [:ATTACK, :DEFENSE, :SPEED, :SPECIAL_ATTACK].map { |s| (pkmn.iv[s] || 0).clamp(0, 31) / 2 }
    stat_exp = [:HP, :ATTACK, :DEFENSE, :SPEED, :SPECIAL_ATTACK].map do |s|
      [(pkmn.ev[s] || 0) * 257, 65535].min
    end
    stats = calc_stats(info, level, dvs, stat_exp)
    hp = pkmn.fainted? ? 0 : (pkmn.hp * stats[0] / [pkmn.totalhp, 1].max).clamp(1, stats[0])
    exp_min = exp_for_level(info[:growth], level)
    exp_max = level >= 100 ? exp_min : exp_for_level(info[:growth], level + 1) - 1
    exp = pkmn.exp.clamp(exp_min, exp_max)
    b = Array.new(MON_PARTY, 0)
    b[0] = info[:index]
    b[1] = hp >> 8; b[2] = hp & 0xFF
    b[3] = level
    b[4] = status_byte(pkmn)
    b[5], b[6] = info[:types]
    b[7] = info[:catch]
    moves.first(4).each_with_index do |(idx, m), i|
      b[8 + i] = idx
      base_pp = MOVES[idx - 1][1]
      ppup = m ? m.ppup.clamp(0, 3) : 0
      pp = m ? m.pp.clamp(0, base_pp + base_pp * ppup / 5) : base_pp
      b[29 + i] = (ppup << 6) | pp.clamp(0, 63)
    end
    ot_id = pkmn.owner.public_id
    b[12] = ot_id >> 8; b[13] = ot_id & 0xFF
    b[14] = (exp >> 16) & 0xFF; b[15] = (exp >> 8) & 0xFF; b[16] = exp & 0xFF
    stat_exp.each_with_index { |v, i| b[17 + i * 2] = v >> 8; b[18 + i * 2] = v & 0xFF }
    b[27] = (dvs[0] << 4) | dvs[1]
    b[28] = (dvs[2] << 4) | dvs[3]
    b[33] = level
    stats.each_with_index { |v, i| b[34 + i * 2] = v >> 8; b[35 + i * 2] = v & 0xFF }
    nick = (pkmn.nicknamed? && encode_text(pkmn.name)) || encode_text(species_text(pkmn.species))
    ot = encode_text(pkmn.owner.name, 7) || encode_text("ETHAN", 7)
    return { :bytes => b, :ot => ot, :nick => nick }
  end

  # Gen 1 moves the species learns by level (latest four), for a Pokémon whose
  # moves are all from later generations
  def self.fallback_moves(pkmn, level)
    list = GameData::Species.get(pkmn.species).moves.select { |lv, mv| lv <= level && MOVE_INDEX[mv] }
    return list.map { |_lv, mv| mv }.uniq.last(4).map { |mv| [MOVE_INDEX[mv], nil] }
  end

  def self.status_byte(pkmn)
    case pkmn.status
    when :SLEEP     then (pkmn.statusCount || 1).clamp(1, 7)
    when :POISON    then 0x08
    when :BURN      then 0x10
    when :FROZEN    then 0x20
    when :PARALYSIS then 0x40
    else                 0
    end
  end

  # identifies a record when it comes back (HP, status and PP left out: they change)
  def self.fingerprint(bytes, ot, nick)
    keep = [0, 3] + (5..28).to_a
    return (keep.map { |i| bytes[i] } + [0xFE] + ot + [0xFE] + nick).pack("C*")
  end

  #-----------------------------------------------------------------------------
  # Writing the save
  #-----------------------------------------------------------------------------
  def self.put_text(buf, addr, codes, len = NAME_LEN)
    len.times { |i| buf[addr + i] = 0x50 }
    codes.each_with_index { |c, i| buf[addr + i] = c if i < len - 1 }
  end

  # party: up to 6 records; boxes: up to 12 arrays of up to 20 records
  def self.write_list(buf, addr, records, capacity, mon_size)
    buf[addr] = records.length
    records.each_with_index { |r, i| buf[addr + 1 + i] = r[:bytes][0] }
    buf[addr + 1 + records.length] = 0xFF
    mons  = addr + 2 + capacity
    ots   = mons + capacity * mon_size
    nicks = ots + capacity * NAME_LEN
    records.each_with_index do |r, i|
      mon_size.times { |k| buf[mons + i * mon_size + k] = r[:bytes][k] }
      put_text(buf, ots + i * NAME_LEN, r[:ot])
      put_text(buf, nicks + i * NAME_LEN, r[:nick])
    end
  end

  def self.bcd(value, digits)
    s = value.clamp(0, 10**digits - 1).to_s.rjust(digits, "0")
    return s.scan(/../).map { |pair| (pair[0].to_i << 4) | pair[1].to_i }
  end

  # Returns [save bytes (String), fingerprints of every Pokémon written]
  def self.build_save(player, party, boxes)
    buf = Array.new(SAVE_SIZE, 0)
    put_text(buf, 0x2598, encode_text(player.name, 7) || encode_text("ETHAN", 7))
    put_text(buf, 0x25F6, encode_text("BLUE", 7))
    buf[0x25C9] = 0; buf[0x25CA] = 0xFF            # bag: empty
    buf[0x27E6] = 0; buf[0x27E7] = 0xFF            # PC items: empty
    bcd(player.money, 6).each_with_index { |v, i| buf[0x25F3 + i] = v }
    buf[0x2601] = 0x03                             # options: text speed
    badges = 0
    8.times { |i| badges |= (1 << i) if player.badges[i] }
    buf[0x2602] = badges
    pid = player.public_ID
    buf[0x2605] = (pid >> 8) & 0xFF
    buf[0x2606] = pid & 0xFF
    buf[0x284C] = 0x80                             # current box 1, boxes set up
    all = party + boxes.flatten
    all.each do |r|
      dex = SPECIES_BY_INDEX[r[:bytes][0]][:dex] - 1
      [0x25A3, 0x25B6].each { |a| buf[a + dex / 8] |= 1 << (dex % 8) }
    end
    write_list(buf, PARTY_ADDR, party, 6, MON_PARTY)
    BOX_COUNT.times do |n|
      addr = (n < 6 ? 0x4000 : 0x6000) + (n % 6) * BOX_SIZE
      write_list(buf, addr, boxes[n] || [], BOX_SLOTS, MON_BOX)
    end
    BOX_SIZE.times { |i| buf[CURBOX_ADDR + i] = buf[0x4000 + i] }   # box 1 is current
    fix_checksums(buf)
    prints = all.map { |r| fingerprint(r[:bytes], r[:ot], r[:nick]) }
    return [buf.pack("C*"), prints]
  end

  def self.fix_checksums(buf)
    buf[0x3523] = (~buf[0x2598...0x3523].sum) & 0xFF
    [0x4000, 0x6000].each do |bank|
      buf[bank + 0x1A4C] = (~buf[bank...(bank + 0x1A4C)].sum) & 0xFF
      6.times do |n|
        box = bank + n * BOX_SIZE
        buf[bank + 0x1A4D + n] = (~buf[box...(box + BOX_SIZE)].sum) & 0xFF
      end
    end
  end

  #-----------------------------------------------------------------------------
  # Reading the save back
  #-----------------------------------------------------------------------------
  def self.read_list(buf, addr, capacity, mon_size)
    count = buf[addr].clamp(0, capacity)
    mons  = addr + 2 + capacity
    ots   = mons + capacity * mon_size
    nicks = ots + capacity * NAME_LEN
    out = []
    count.times do |i|
      bytes = buf[mons + i * mon_size, mon_size]
      next if !SPECIES_BY_INDEX[bytes[0]]
      bytes += Array.new(MON_PARTY - mon_size, 0)
      bytes[33] = bytes[3] if mon_size == MON_BOX
      ot   = buf[ots + i * NAME_LEN, NAME_LEN]
      nick = buf[nicks + i * NAME_LEN, NAME_LEN]
      ot   = ot[0, ot.index(0x50) || NAME_LEN]
      nick = nick[0, nick.index(0x50) || NAME_LEN]
      out << { :bytes => bytes, :ot => ot, :nick => nick }
    end
    return out
  end

  # Every Pokémon on the cart: party, then boxes 1-12
  def self.read_save(data)
    buf = data.unpack("C*")
    return [] if buf.length < SAVE_SIZE
    list = read_list(buf, PARTY_ADDR, 6, MON_PARTY)
    current = buf[0x284C] & 0x7F
    BOX_COUNT.times do |n|
      addr = (n == current) ? CURBOX_ADDR : (n < 6 ? 0x4000 : 0x6000) + (n % 6) * BOX_SIZE
      list.concat(read_list(buf, addr, BOX_SLOTS, MON_BOX))
    end
    return list
  end

  #-----------------------------------------------------------------------------
  # Gen 1 record -> Essentials Pokémon
  #-----------------------------------------------------------------------------
  def self.to_pokemon(r)
    b = r[:bytes]
    info = SPECIES_BY_INDEX[b[0]]
    level = (b[33] > 0 ? b[33] : b[3]).clamp(1, 100)
    pkmn = Pokemon.new(info[:sym], level, $player, false)
    ot_name = decode_text(r[:ot])
    ot_id = (b[12] << 8) | b[13]
    pkmn.owner = Pokemon::Owner.new(ot_id, ot_name.empty? ? "?" : ot_name, 2, $player.language)
    dvs = [b[27] >> 4, b[27] & 0xF, b[28] >> 4, b[28] & 0xF]
    hp_dv = ((dvs[0] & 1) << 3) | ((dvs[1] & 1) << 2) | ((dvs[2] & 1) << 1) | (dvs[3] & 1)
    iv = ->(dv) { (dv * 2 + 1).clamp(0, 31) }
    pkmn.iv[:HP]              = iv.call(hp_dv)
    pkmn.iv[:ATTACK]          = iv.call(dvs[0])
    pkmn.iv[:DEFENSE]         = iv.call(dvs[1])
    pkmn.iv[:SPEED]           = iv.call(dvs[2])
    pkmn.iv[:SPECIAL_ATTACK]  = iv.call(dvs[3])
    pkmn.iv[:SPECIAL_DEFENSE] = iv.call(dvs[3])
    stat_exp = (0...5).map { |i| (b[17 + i * 2] << 8) | b[18 + i * 2] }
    evs = stat_exp.map { |v| (v / 257).clamp(0, 252) }
    evs << evs[4]                                  # Special -> Sp. Atk and Sp. Def
    total = evs.sum
    evs.map! { |v| v * 510 / total } if total > 510
    [:HP, :ATTACK, :DEFENSE, :SPEED, :SPECIAL_ATTACK, :SPECIAL_DEFENSE].each_with_index do |s, i|
      pkmn.ev[s] = evs[i]
    end
    moves = []
    4.times do |i|
      idx = b[8 + i]
      next if idx == 0 || idx > MOVES.length
      sym = MOVES[idx - 1][0]
      next if !GameData::Move.exists?(sym)
      m = Pokemon::Move.new(sym)
      m.ppup = (b[29 + i] >> 6).clamp(0, 3)
      moves << m
    end
    pkmn.moves.clear
    moves.each { |m| pkmn.moves << m }
    pkmn.learn_move(:TACKLE) if pkmn.moves.empty?
    pkmn.exp = (b[14] << 16) | (b[15] << 8) | b[16]
    nick = decode_text(r[:nick])
    pkmn.name = nick if !nick.empty? && nick != species_text(info[:sym])
    pkmn.obtain_text = _INTL("Pokémon Stadium") if pkmn.respond_to?(:obtain_text=)
    pkmn.calc_stats
    pkmn.heal
    pkmn.record_first_moves
    return pkmn
  end
end
