#===============================================================================
# Signature moves
# These learn their signature move at level 1, and a Pokémon made at a higher
# level only knows its last 4 level-up moves, so a wild Meloetta never had
# Relic Song (or Keldeo Secret Sword, which its Resolute Form needs). A new
# one of these now always knows it, in place of its oldest move. Ones already
# owned can learn it from the Move Relearner.
#===============================================================================
SIGNATURE_MOVES = {
  :MELOETTA  => :RELICSONG,
  :KELDEO    => :SECRETSWORD,
  :TORNADUS  => :BLEAKWINDSTORM,
  :THUNDURUS => :WILDBOLTSTORM,
  :LANDORUS  => :SANDSEARSTORM,
  :CRESSELIA => :LUNARBLESSING
}

class Pokemon
  alias __signature_reset_moves reset_moves unless method_defined?(:__signature_reset_moves)

  def reset_moves
    __signature_reset_moves
    move = SIGNATURE_MOVES[@species]
    learn_move(move) if move && GameData::Move.exists?(move) && !hasMove?(move)
  end

  # Leader's Crest (Bisharp -> Kingambit): Data/Scripts' set_evo_crest_count
  # calls init_crest_count, which doesn't exist, so it crashed right after
  # the evolution
  def set_evo_crest_count(item, value)
    init_evo_crest_count(item)
    @evo_crest_count[item] = value
  end
end
