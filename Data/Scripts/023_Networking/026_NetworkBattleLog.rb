#===============================================================================
# NetworkBattleLog — per-battle plaintext transcript, kept purely to help
# diagnose PvP desyncs between the two clients in a networked battle.
#
# Data/battle_log_<username>.txt (see log_path) is truncated and rewritten
# fresh at the start of every network battle, so it always holds the most
# recent fight for that player on this machine. It captures every message the
# battle engine displays (moves used, damage, status, fainting — see the
# pbDisplay* overrides in Battle::NetworkPvP) plus an HP/status line dump
# after each round, and notes whenever the server's round-sync reconciliation
# had to correct something.
#
# The \issue chat command asks both clients currently in a battle to upload
# this file's current contents so a dev can diff the two screens on Discord.
# That request (battle_log_request) is answered directly from NetworkClient's
# background receive thread (see _reply_battle_log_request in
# 001_NetworkClient.rb) rather than through the normal main-thread callback
# dispatch — deliberately, so a report still goes out even if the main thread
# is completely hung inside a frozen/desynced battle, which is exactly the
# scenario a battle log report exists to diagnose.
#===============================================================================
module NetworkBattleLog
  # Per-player, not a fixed name — two clients launched from the same install
  # folder (e.g. testing multiplayer locally on one PC) would otherwise both
  # write "Data/battle_log.txt" and physically corrupt each other's file with
  # interleaved writes (which is exactly what was happening: two garbled,
  # interleaved team listings from both sides landing in one file).
  def self.log_path
    name = NetworkAuth.username.to_s.gsub(/[^A-Za-z0-9_\-]/, '_')
    name = "unknown" if name.empty?
    "Data/battle_log_#{name}.txt"
  end

  # my_party/opp_party are arrays of Pokemon (may contain nils for empty
  # slots) — logged in full (species, level, held item, ability, moves) so a
  # dev diffing two clients' logs can see whether they even started the
  # battle with the same data, not just how HP/status drifted mid-fight.
  def self.start(my_name, opp_name, my_party = nil, opp_party = nil)
    @active = true
    begin
      File.open(log_path, "wb") { |f| }
    rescue
      nil
    end
    _write_line("=== Battle started: #{my_name} vs #{opp_name} (#{Time.now.strftime('%Y-%m-%d %H:%M:%S')}) ===")
    _log_team("#{my_name}'s Team", my_party) if my_party
    _log_team("#{opp_name}'s Team", opp_party) if opp_party
  end

  # Captures a narrative battle message (move used, damage, status, fainting...).
  def self.write(msg)
    return unless @active
    clean = _sanitize(msg)
    _write_line(clean) unless clean.empty?
  end

  # A dev-facing annotation — sync corrections, timeouts, etc. Prefixed so
  # it's easy to spot among the narrative battle text.
  def self.note(text)
    return unless @active
    _write_line("*** #{text}")
  end

  def self.round_summary(battlers)
    return unless @active
    parts = battlers.compact.map do |b|
      status = (b.status && b.status != :NONE) ? b.status.to_s : "OK"
      "#{b.name} #{b.hp}/#{b.totalhp}HP [#{status}]"
    end
    _write_line("-- End of round: " + parts.join(" | "))
  end

  def self.close(result_text)
    return unless @active
    _write_line("=== Battle ended: #{result_text} ===")
    @active = false
  end

  # Reads the current on-disk log back out for the \issue upload flow.
  # Works even if called outside an active battle (e.g. right after one ends).
  def self.read_current
    return "" unless FileTest.exist?(log_path)
    File.open(log_path, "rb") { |f| f.read } rescue ""
  end

  def self._log_team(label, party)
    _write_line("-- #{label} --")
    party.compact.each_with_index do |pkmn, i|
      # pkmn.item/.ability return a ":None" placeholder object rather than nil
      # when unset — check the raw ids (nil = no held item) instead.
      item_text    = pkmn.item_id ? " @ #{pkmn.item.name}" : ""
      ability_text = pkmn.ability_id ? " [#{pkmn.ability.name}]" : ""
      moves_text   = pkmn.moves.compact.map { |m|
        GameData::Move.try_get(m.id)&.name || m.id.to_s
      }.join(", ")
      moves_text   = "(no moves)" if moves_text.empty?
      _write_line("#{i + 1}. #{pkmn.name} (#{pkmn.species}) Lv.#{pkmn.level}#{item_text}#{ability_text}")
      _write_line("   Moves: #{moves_text}")
    end
  rescue StandardError => e
    _write_line("*** Failed to log #{label}: #{e.message}")
  end

  def self._write_line(text)
    File.open(log_path, "a+b") { |f| f.write(text + "\r\n") }
  rescue
    nil
  end

  # Strips RGSS/Essentials text codes (\c[n], \se[...], \wtnp[n], etc.) so the
  # log reads as plain text.
  def self._sanitize(msg)
    msg.to_s.gsub(/\\[a-zA-Z]+\[[^\]]*\]/, "").gsub(/\s+/, " ").strip
  end
end
