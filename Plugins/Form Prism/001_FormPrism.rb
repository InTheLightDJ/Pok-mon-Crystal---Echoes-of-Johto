#===============================================================================
# Form Prism - used on a Pokémon that has other forms (Alolan, Galarian, Unown
# letters, Vivillon patterns...), it changes it into a random one of them.
#
# Skipped: forms the Pokémon can't stay in outside battle (Mega, Primal, Zen
# Mode, Crowned...), forms set by a held item, the time or the map (Arceus,
# Giratina, Deerling...), fusions (Kyurem, Necrozma, Calyrex) and forms with
# no sprite of their own.
#
# Give it from an event:  pbReceiveItem(:FORMPRISM)
#===============================================================================
module FormPrism
  # Primal forms only exist in battle; fused forms need the partner Pokémon
  # stored inside them
  SKIP_SPECIES = [:KYOGRE, :GROUDON, :KYUREM, :NECROZMA, :CALYREX]

  def self.forms_for(pkmn)
    return [] if pkmn.egg? || SKIP_SPECIES.include?(pkmn.species)
    ret = []
    GameData::Species.each do |sp|
      next if sp.species != pkmn.species || sp.form == pkmn.form
      ret << sp.form if keeps_form?(pkmn, sp)
    end
    ret
  end

  def self.keeps_form?(pkmn, sp)
    return false if sp.mega_stone || sp.mega_move
    return false if sp.form > 0 && !pbResolveBitmap(sprintf("Graphics/Pokemon/%s_%d", sp.species, sp.form))
    test = pkmn.clone
    test.forced_form = nil
    test.form_simple = sp.form
    [["getForm"], ["getFormOnLeavingBattle", nil, false, true]].each do |args|
      f = MultipleForms.call(args[0], test, *args[1..])
      return false if !f.nil? && f != sp.form
    end
    true
  rescue StandardError
    false
  end
end

ItemHandlers::UseOnPokemon.add(:FORMPRISM, proc { |item, qty, pkmn, scene|
  forms = FormPrism.forms_for(pkmn)
  if forms.empty?
    scene.pbDisplay(_INTL("It had no effect."))
    next false
  end
  pkmn.setForm(forms.sample) do
    scene.pbRefresh
    scene.pbDisplay(_INTL("{1} changed Forme!", pkmn.name))
  end
  next true
})
