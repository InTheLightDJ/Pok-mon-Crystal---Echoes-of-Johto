module GameData
  class Species
    def self.check_graphic_file(path, species, gender = 0, shiny = false, back = false, form = 0, shadow = false)
      try_species = species
      try_gender  = (gender == 1) ? "f" : ""
      try_shiny   = (shiny) ? "s" : ""
      try_back    = (back) ? "b" : ""
      try_form    = (form > 0) ? sprintf("_%d", form) : ""
      try_shadow  = (shadow) ? "_shadow" : ""
      factors = []
      factors.push([5, try_shadow, ""]) if shadow
      factors.push([4, try_form, ""]) if form > 0
      factors.push([3, try_back, ""]) if back
      factors.push([2, try_shiny, ""]) if shiny
      factors.push([1, try_gender, ""]) if gender == 1
      factors.push([0, try_species, "000"])
      # Go through each combination of parameters in turn to find an existing sprite
      (2**factors.length).times do |i|
        # Set try_ parameters for this combination
        factors.each_with_index do |factor, index|
          value = ((i / (2**index)).even?) ? factor[1] : factor[2]
          case factor[0]
          when 0 then try_species   = value
          when 1 then try_gender    = value
          when 2 then try_shiny     = value
          when 3 then try_back      = value
          when 4 then try_form      = value
          when 5 then try_shadow    = value   # Shadow
          end
        end
        # Look for a graphic matching this combination's parameters
        try_species_text = try_species
        ret = pbResolveBitmap(sprintf("%s%s%s%s%s%s", path, try_species_text,
                                      try_gender, try_shiny, try_back, try_form, try_shadow))
        return ret if ret
      end
      return nil
    end

    def self.check_egg_graphic_file(path, species, form, suffix = "")
      species_data = self.get_species_form(species, form)
      return nil if species_data.nil?
      if form > 0
        ret = pbResolveBitmap(sprintf("%s%s_%d%s", path, species_data.species, form, suffix))
        return ret if ret
      end
      return pbResolveBitmap(sprintf("%s%s%s", path, species_data.species, suffix))
    end

    def self.front_sprite_filename(species, gender = 0, shiny = false, back = false, form = 0, shadow = false)
      return self.check_graphic_file("Graphics/Pokemon/", species, gender, shiny, back, form, shadow)
    end

    def self.back_sprite_filename(species, gender = 0, shiny = false, back = true, form = 0, shadow = false)
      return self.check_graphic_file("Graphics/Pokemon/", species, gender, shiny, back, form, shadow)
    end

    def self.egg_sprite_filename(species, form)
      ret = self.check_egg_graphic_file("Graphics/Pokemon/Eggs/", species, form)
      return (ret) ? ret : pbResolveBitmap("Graphics/Pokemon/Eggs/000")
    end

    def self.egg_cracks_sprite_filename(species, form)
      ret = self.check_egg_graphic_file("Graphics/Pokemon/Eggs/", species, form, "_cracks")
      return (ret) ? ret : pbResolveBitmap("Graphics/Pokemon/Eggs/000_cracks")
    end

    def self.sprite_filename(species, gender = 0, shiny = false, back = false, form = 0, shadow = false, egg = false)
      return self.egg_sprite_filename(species, form) if egg
      return self.back_sprite_filename(species, gender, shiny, back = true, form, shadow) if back
      return self.front_sprite_filename(species, gender, shiny, back = false, form, shadow)
    end

    def self.front_sprite_bitmap(species, gender = 0, shiny = false, back = false, form = 0, shadow = false)
      filename = self.front_sprite_filename(species, gender, shiny, back, form, shadow)
      return (filename) ? AnimatedBitmap.new(filename) : nil
    end

    def self.back_sprite_bitmap(species, gender = 0, shiny = false, back = true, form = 0, shadow = false)
      filename = self.back_sprite_filename(species, gender, shiny, back, form, shadow)
      return (filename) ? AnimatedBitmap.new(filename) : nil
    end

    def self.egg_sprite_bitmap(species, form = 0)
      filename = self.egg_sprite_filename(species, form)
      return (filename) ? AnimatedBitmap.new(filename) : nil
    end

    def self.sprite_bitmap(species, gender = 0, shiny = false, back = false, form = 0, shadow = false, egg = false)
      return self.egg_sprite_bitmap(species, form) if egg
      return self.back_sprite_bitmap(species, gender, shiny, back, form, shadow) if back
      return self.front_sprite_bitmap(species, gender, shiny, back, form, shadow)
    end

    def self.sprite_bitmap_from_pokemon(pkmn, back = false, species = nil)
      species = pkmn.species if !species
      species = GameData::Species.get(species).species   # Just to be sure it's a symbol
      return self.egg_sprite_bitmap(species, pkmn.form) if pkmn.egg?
      if back
        ret = self.back_sprite_bitmap(species, pkmn.gender, pkmn.shiny?, back = true, pkmn.form, pkmn.shadowPokemon?)
      else
        ret = self.front_sprite_bitmap(species, pkmn.gender, pkmn.shiny?, back = false, pkmn.form, pkmn.shadowPokemon?)
      end
      alter_bitmap_function = MultipleForms.getFunction(species, "alterBitmap")
      if ret && alter_bitmap_function
        new_ret = ret.copy
        ret.dispose
        new_ret.each { |bitmap| alter_bitmap_function.call(pkmn, bitmap) }
        ret = new_ret
      end
      return ret
    end

    #===========================================================================

    def self.egg_icon_filename(species, form)
      ret = self.check_egg_graphic_file("Graphics/Pokemon/Eggs/", species, form, "_icon")
      return (ret) ? ret : pbResolveBitmap("Graphics/Pokemon/Eggs/000_icon")
    end

    def self.icon_filename(species, gender = 0, shiny = false, back = false, form = 0, shadow = false, egg = false)
      return self.egg_icon_filename(species, form) if egg
      return self.check_graphic_file("Graphics/Pokemon/Icons/", species, gender, shiny, back, form, shadow)
    end

    def self.icon_filename_from_pokemon(pkmn)
      return self.icon_filename(pkmn.species, pkmn.gender, pkmn.shiny?, back = false, pkmn.form, pkmn.shadowPokemon?, pkmn.egg?)
    end

    def self.egg_icon_bitmap(species, form)
      filename = self.egg_icon_filename(species, form)
      return (filename) ? AnimatedBitmap.new(filename).deanimate : nil
    end

    def self.icon_bitmap(species, gender = 0, shiny = false, form = 0, shadow = false, egg = false)
      return self.egg_icon_bitmap(species, form) if egg
      filename = self.icon_filename(species, gender, shiny, form, shadow)
      return (filename) ? AnimatedBitmap.new(filename).deanimate : nil
    end

    def self.icon_bitmap_from_pokemon(pkmn)
      return self.icon_bitmap(pkmn.species, pkmn.gender, pkmn.shiny?, pkmn.form, pkmn.shadowPokemon?, pkmn.egg?)
    end

    #===========================================================================

    def self.footprint_filename(species, form = 0)
      species_data = self.get_species_form(species, form)
      return nil if species_data.nil?
      if form > 0
        ret = pbResolveBitmap(sprintf("Graphics/Pokemon/Footprints/%s_%d", species_data.species, form))
        return ret if ret
      end
      return pbResolveBitmap(sprintf("Graphics/Pokemon/Footprints/%s", species_data.species))
    end

    #===========================================================================

    def self.shadow_filename(species, form = 0)
      species_data = self.get_species_form(species, form)
      return nil if species_data.nil?
      # Look for species-specific shadow graphic
      if form > 0
        ret = pbResolveBitmap(sprintf("Graphics/Pokemon/Shadow/%s_%d", species_data.species, form))
        return ret if ret
      end
      ret = pbResolveBitmap(sprintf("Graphics/Pokemon/Shadow/%s", species_data.species))
      return ret if ret
      # Use general shadow graphic
      metrics_data = GameData::SpeciesMetrics.get_species_form(species_data.species, form)
      return pbResolveBitmap(sprintf("Graphics/Pokemon/Shadow/%d", metrics_data.shadow_size))
    end

    def self.shadow_bitmap(species, form = 0)
      filename = self.shadow_filename(species, form)
      return (filename) ? AnimatedBitmap.new(filename) : nil
    end

    def self.shadow_bitmap_from_pokemon(pkmn)
      filename = self.shadow_filename(pkmn.species, pkmn.form)
      return (filename) ? AnimatedBitmap.new(filename) : nil
    end

    #===========================================================================

    def self.check_cry_file(species, form, suffix = "")
      species_data = self.get_species_form(species, form)
      return nil if species_data.nil?
      if form > 0
        ret = sprintf("Cries/%s_%d%s", species_data.species, form, suffix)
        return ret if pbResolveAudioSE(ret)
      end
      ret = sprintf("Cries/%s%s", species_data.species, suffix)
      return (pbResolveAudioSE(ret)) ? ret : nil
    end

    def self.cry_filename(species, form = 0, suffix = "")
      return self.check_cry_file(species, form || 0, suffix)
    end

    def self.cry_filename_from_pokemon(pkmn, suffix = "")
      return self.check_cry_file(pkmn.species, pkmn.form, suffix)
    end

    def self.play_cry_from_species(species, form = 0, volume = 90, pitch = 100)
      filename = self.cry_filename(species, form)
      return if !filename
      pbSEPlay(RPG::AudioFile.new(filename, volume, pitch)) rescue nil
    end

    def self.play_cry_from_pokemon(pkmn, volume = 90, pitch = 100)
      return if !pkmn || pkmn.egg?
      filename = self.cry_filename_from_pokemon(pkmn)
      return if !filename
      pitch ||= 100
      pbSEPlay(RPG::AudioFile.new(filename, volume, pitch)) rescue nil
    end

    def self.play_cry(pkmn, volume = 90, pitch = 100)
      if pkmn.is_a?(Pokemon)
        self.play_cry_from_pokemon(pkmn, volume, pitch)
      else
        self.play_cry_from_species(pkmn, 0, volume, pitch)
      end
    end

    def self.cry_length(species, form = 0, pitch = 100, suffix = "")
      pitch ||= 100
      return 0 if !species || pitch <= 0
      pitch = pitch.to_f / 100
      ret = 0.0
      if species.is_a?(Pokemon)
        if !species.egg?
          filename = self.cry_filename_from_pokemon(species, suffix)
          filename = self.cry_filename_from_pokemon(species) if !filename && !nil_or_empty?(suffix)
          filename = pbResolveAudioSE(filename)
          ret = getPlayTime(filename) if filename
        end
      else
        filename = self.cry_filename(species, form, suffix)
        filename = self.cry_filename(species, form) if !filename && !nil_or_empty?(suffix)
        filename = pbResolveAudioSE(filename)
        ret = getPlayTime(filename) if filename
      end
      ret /= pitch   # Sound played at a lower pitch lasts longer
      return ret
    end
  end
end
