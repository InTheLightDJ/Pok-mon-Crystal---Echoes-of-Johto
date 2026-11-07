#==============================================================================
# Pokemon TCG - card text in the player's language (not in the original)
#
# The card data (001_CardData.rb ...) is English. On screen, a card's name,
# its Pokémon's pre-evolution, its attack / Pokémon Power names and effect
# texts, the Glossary and the coin toss texts come from the game's
# translations (Data/messages_<lang>_game.dat, SCRIPT_TEXTS), looked up
# under a "TCG_<KIND>|" prefix so a card called "Switch" or "Potion" never
# takes the translation of the same word in a menu:
#   TCG_NAME|Charizard   TCG_ATTACK|Fire Spin   TCG_TEXT|<effect text>
#   TCG_COIN|<coin toss text>   TCG_GLOSSARY|<title or page text>
# (Translation/tools/extract.rb collects them from
# Translation/tcg_card_text.json, made by
# PokeTCG-mod/tools/card_text/export_card_text.rb.)
# Effect texts are translated as one paragraph; the screens wrap them
# (GB.wrap), so the data's line breaks don't matter.
#
# Card#name / #preevo and Attack#name / #desc give the translated text, so
# comparing two cards still works in any language. Anything compared with
# English text or with the raw data (CARDS[...][:name]) uses Card#en_name /
# #en_preevo / Attack#en_name.
#==============================================================================
module TCG
  module CardText
    KINDS = %i[NAME ATTACK TEXT COIN GLOSSARY]

    @cache = {}

    module_function

    def language
      defined?($PokemonSystem) && $PokemonSystem ? $PokemonSystem.language.to_i : 0
    end

    # the text in the current language (the English text when there's none)
    def tr(kind, text)
      return text if text.nil? || text.empty? || !defined?(MessageTypes)
      (@cache[[language, kind, text]] ||= begin
        key = "TCG_#{kind}|#{text}"
        t = (MessageTypes.getFromHash(MessageTypes::SCRIPT_TEXTS, key) rescue key)
        t.nil? || t.empty? || t.start_with?("TCG_") ? text : t
      end)
    end

    def clear_cache; @cache.clear; end

    # a coin toss box text (2 lines of 36 half-width characters)
    def coin(text)
      return text if text.nil?
      t = tr(:COIN, text)
      t == text ? text : GB.wrap(t, 36).first(2).join("\n")
    end
  end

  # a Glossary page's lines as one paragraph (its translation key)
  def self.glossary_text(lines)
    lines.map(&:strip).join(" ").squeeze(" ")
  end

  class Attack
    def en_name; @name; end
    def en_desc; @desc; end
    def name; CardText.tr(:ATTACK, @name); end
    def desc; CardText.tr(:TEXT, @desc); end
  end

  class Card
    def en_name;   @name;   end
    def en_preevo; @preevo; end
    def en_desc;   @desc;   end
    def name;   CardText.tr(:NAME, @name);   end
    def preevo; @preevo && CardText.tr(:NAME, @preevo); end
    # the name evolutions compare with #preevo (an event card evolves like its normal card, 001e)
    def evo_name; CardText.tr(:NAME, TCG.evolves_as(@name)); end
    def desc;   CardText.tr(:TEXT, @desc);   end
  end

  # a card name from the data (CARDS[id][:name], a :preevo) on screen
  def self.tr_name(name); CardText.tr(:NAME, name); end
end
