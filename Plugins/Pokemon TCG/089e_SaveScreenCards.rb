#==============================================================================
# Pokemon TCG - "Cards" line on the save screen, under "Pokédex": how many
# different cards the player owns (like the Pokédex's owned count).
# Only shown while game switch SAVE_SCREEN_SWITCH is ON (set after the
# player gets their first deck); otherwise the screen is unchanged.
# The Continue screen is left alone (it reads the save file before the
# game, and the collection, is loaded).
#==============================================================================
module TCG
  SAVE_SCREEN_SWITCH = 107   # nil = always show the line
end

if defined?(pbDisplayPlayerDataWindow)
  alias tcg_pbDisplayPlayerDataWindow pbDisplayPlayerDataWindow unless defined?(tcg_pbDisplayPlayerDataWindow)

  def pbDisplayPlayerDataWindow(player, totalsec, map_id, viewport, y = 0)
    win = tcg_pbDisplayPlayerDataWindow(player, totalsec, map_id, viewport, y)
    return win unless player && $player && player.equal?($player) && $PokemonGlobal
    sw = TCG::SAVE_SCREEN_SWITCH
    return win if sw && !($game_switches && $game_switches[sw])
    owned = TCG.collection.select { |_id, n| n.to_i > 0 }.keys.map { |id| TCG.base_id(id) }.uniq.size
    time = _INTL("Time") + "<r>"
    i = win.text.index(time) or return win
    text = win.text.dup.insert(i, _INTL("Cards") + "<r>" + owned.to_s + "<br>")
    win.text = text
    win.resizeToFit(text, Graphics.width)
    win.width = 228 if win.width < 228
    win.x = Graphics.width - win.width
    win.y = y < 0 ? Graphics.height - win.height : y
    win
  end
end
