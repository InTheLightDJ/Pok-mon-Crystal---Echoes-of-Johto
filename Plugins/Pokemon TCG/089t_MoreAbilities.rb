#==============================================================================
# Pokemon TCG - more duel abilities (not in the original): Token, 8 Start,
# Holo Boost, Spikes, Restore, Potion Plus. Their names, descriptions and
# rules are in 089r_DuelAbilities.rb; this file loads after every card
# effect file so its wrappers sit outside theirs.
#==============================================================================
module TCG
  module DuelAbilities
    EXTRA_START_CARDS = 1     # 8 Start
    HOLO_BOOST_PER_ENERGY = 10
    SPIKES_DAMAGE = 10
    POTION_BONUS = 10
    # attacks that already add damage per Energy (Hydro Pump, Water Gun,
    # Energy Cannon, Power Blow...): Holo Boost only adds what's over that
    ENERGY_SCALING_TEXT = /plus 10 (more )?damage for each .{0,30}Energy (card )?attached to/i
  end

  #----------------------------------------------------------------------------
  # Token: Server Tokens for the rarest holos (packs and the Card Slots)
  #----------------------------------------------------------------------------
  # the rarest holo tiers in cards (ids) => tokens to ask the server for
  def self.holo_tokens_for(cards)
    return 0 unless duel_ability == :TOKEN
    Array(cards).count { |id| HOLO_PULL_POINTS.key?(holo_tier(id)) }
  end

  # asks the server for one token per rare holo; returns how many were asked
  # for (0 when offline: the server keeps the balance)
  def self.give_holo_tokens(cards)
    n = holo_tokens_for(cards)
    return 0 if n == 0 || !(defined?(NetworkClient) && NetworkClient.connected?)
    Array(cards).each do |id|
      tier = holo_tier(id)
      next unless HOLO_PULL_POINTS.key?(tier)
      NetworkClient.send_msg({ action: "tcg_holo_token", tier: tier.to_s })
    end
    n
  rescue StandardError
    0
  end

  def self.last_holo_tokens; @last_holo_tokens.to_i; end

  class << self
    alias token_pack_pulled pack_pulled unless method_defined?(:token_pack_pulled)
    def pack_pulled(cards)
      @last_holo_tokens = give_holo_tokens(cards)
      token_pack_pulled(cards)
    end

    alias token_pull_message pull_message unless method_defined?(:token_pull_message)
    def pull_message(pts)
      token_pull_message(pts)
      holo_token_message
    end

    # "Token! +N Server Token(s)!" after the last pack (once)
    def holo_token_message(say = nil)
      n = @last_holo_tokens.to_i
      @last_holo_tokens = 0
      return if n <= 0
      text = _INTL("Token! +{1} Server Token(s)!", n)
      say ? say.call(text) : pbMessage(text)
    end
  end

  #----------------------------------------------------------------------------
  # Double Reward: a duel's booster packs twice (card rewards once)
  #----------------------------------------------------------------------------
  class << self
    alias more_give_reward give_reward unless method_defined?(:more_give_reward)
    def give_reward(reward)
      return more_give_reward(reward) unless duel_ability == :REWARD
      list = reward.is_a?(Array) ? reward : [reward]
      pack = ->(r) { r.is_a?(DestinyPack) || BOOSTER_PACKS[r.to_sym] || RANDOM_PACKS[r.to_sym] }
      more_give_reward(list.flat_map { |r| pack.(r) ? [r, r] : [r] })
    end
  end

  #----------------------------------------------------------------------------
  # PSA Shield: no wear from duels
  #----------------------------------------------------------------------------
  module Grades
    class << self
      alias more_wear wear unless method_defined?(:more_wear)
      def wear(deck)
        return if TCG.duel_ability == :PSA
        more_wear(deck)
      end
    end
  end

  #----------------------------------------------------------------------------
  # the duel
  #----------------------------------------------------------------------------
  class Duelist
    attr_accessor :on_switch_in   # called after a new Pokémon becomes Active

    alias spikes_swap_arena_with_bench_pokemon swap_arena_with_bench_pokemon unless method_defined?(:spikes_swap_arena_with_bench_pokemon)
    def swap_arena_with_bench_pokemon(e)
      before = arena
      r = spikes_swap_arena_with_bench_pokemon(e)
      @on_switch_in&.call(self) if arena && arena != before
      r
    end
  end

  class Duel
    alias more_set_up_abilities set_up_abilities unless method_defined?(:more_set_up_abilities)
    def set_up_abilities
      more_set_up_abilities
      @duelists.each { |d| d.on_switch_in = ->(x) { spikes_hit(x) } }
    end

    # 8 Start: one more card in the opening hand (Basic check included)
    alias more_shuffle_deck_and_draw_seven_cards shuffle_deck_and_draw_seven_cards unless method_defined?(:more_shuffle_deck_and_draw_seven_cards)
    def shuffle_deck_and_draw_seven_cards(d)
      ok = more_shuffle_deck_and_draw_seven_cards(d)
      return ok unless ability?(@duelists.index(d), :EIGHT_START)
      DuelAbilities::EXTRA_START_CARDS.times { d.add_card_to_hand(d.draw_card_from_deck) if d.cards_in_deck > 0 }
      d.hand.any? { |i| d.card(i).basic? }
    end

    # Spikes: the opponent's new Active takes 10 (leaves it at 10 HP at least,
    # so it's never knocked out outside the knock-out checks)
    def spikes_hit(d)
      side = @duelists.index(d)
      return unless side && ability?(1 - side, :SPIKES) && d.arena
      dmg = [DuelAbilities::SPIKES_DAMAGE, d.slot_hp[PLAY_AREA_ARENA] - 10].min
      return if dmg <= 0
      d.slot_hp[PLAY_AREA_ARENA] -= dmg
      @ui.message(_INTL("Spikes! {1} takes {2} damage!", d.card(d.arena).name, dmg))
      @ui.refresh(self)
    end

    alias more_replace_knocked_out_pokemon replace_knocked_out_pokemon unless method_defined?(:more_replace_knocked_out_pokemon)
    def replace_knocked_out_pokemon
      d = turn_duelist
      before = d.arena
      r = more_replace_knocked_out_pokemon
      spikes_hit(d) if !r && d.arena && d.arena != before
      r
    end

    # Restore: 1 Energy of each knocked out Pokémon goes to the hand
    alias more_move_all_knocked_out_pokemon_to_discard_pile move_all_knocked_out_pokemon_to_discard_pile unless method_defined?(:more_move_all_knocked_out_pokemon_to_discard_pile)
    def move_all_knocked_out_pokemon_to_discard_pile(d)
      back = []
      if ability?(@duelists.index(d), :RESTORE)
        (0...MAX_PLAY_AREA_POKEMON).each do |e|
          idx = d.play_area[e]
          next if idx.nil? || d.slot_hp[e] > 0 || d.card(idx).trainer?
          en = d.energy_cards_in_slot(e)
          pick = en.find { |i| !d.card(i).basic_energy? } || en.first
          back << pick if pick
        end
      end
      more_move_all_knocked_out_pokemon_to_discard_pile(d)
      back.each do |i|
        d.move_discard_pile_card_to_hand(i)
        d.add_card_to_hand(i)
        @ui.message(_INTL("Restore! {1} returned to {2}'s hand.", d.card(i).name, d.name))
      end
    end

    # Holo Boost: before Weakness / Resistance, after the attack's effects
    alias more_apply_damage_modifiers_damage_to_target apply_damage_modifiers_damage_to_target unless method_defined?(:more_apply_damage_modifiers_damage_to_target)
    def apply_damage_modifiers_damage_to_target
      holo_boost
      dmg = more_apply_damage_modifiers_damage_to_target
      # 1HKO: any damage is enough to knock the Defending Pokémon out
      if dmg > 0 && any_ability?(:ONE_HKO) && (nd = non_turn_duelist).arena
        dmg = [dmg, nd.slot_hp[PLAY_AREA_ARENA]].max
      end
      dmg
    end

    # the side whose attack is dealing damage (nil outside attacks), for
    # Sturdy and Knock Off
    alias more_play_attack_animation_deal_attack_damage play_attack_animation_deal_attack_damage unless method_defined?(:more_play_attack_animation_deal_attack_damage)
    def play_attack_animation_deal_attack_damage
      @attack_side = @turn
      more_play_attack_animation_deal_attack_damage
    ensure
      @attack_side = nil
    end

    alias more_subtract_hp subtract_hp unless method_defined?(:more_subtract_hp)
    def subtract_hp(d, e, dmg)
      side = @duelists.index(d)
      hit = @attack_side && side && side != @attack_side && dmg > 0 && d.play_area[e]
      return more_subtract_hp(d, e, dmg) unless hit
      # Sturdy: a full HP Pokémon keeps 10 HP
      hp = d.slot_hp[e]
      if ability?(side, :STURDY) && hp > 10 && dmg >= hp && hp >= card_damage_and_max_hp(d, e)[1]
        dmg = hp - 10
        @ui.message(_INTL("Sturdy! {1} held on!", d.card(d.play_area[e]).name))
      end
      r = more_subtract_hp(d, e, dmg)
      # Knock Off: the damaged Pokémon loses 1 Energy card
      if dmg > 0 && any_ability?(:KNOCKOFF) && (i = d.energy_cards_in_slot(e).first)
        d.put_card_in_discard_pile(i)
        @ui.message(_INTL("Knock Off! {1}'s {2} was discarded.", d.card(d.play_area[e]).name, d.card(i).name))
      end
      r
    end

    def holo_boost
      return unless @atk && @atk.attack && !@atk.pokemon_power? && !@atk.is_damage_to_self
      return unless ability?(@turn, :HOLO_BOOST)
      d = turn_duelist
      return unless @atk.card_index == d.arena && TCG.holo?(d.display_id(@atk.card_index))
      base = @atk.attack.damage.to_i
      return if base <= 0 || @atk.damage.to_i <= 0
      extra = d.attached_energies(PLAY_AREA_ARENA)[1] - @atk.attack.cost.sum
      bonus = DuelAbilities::HOLO_BOOST_PER_ENERGY * extra
      if d.card(d.arena).en_desc.to_s.tr("\n", " ") =~ DuelAbilities::ENERGY_SCALING_TEXT ||
         @atk.attack.en_desc.to_s.tr("\n", " ") =~ DuelAbilities::ENERGY_SCALING_TEXT
        bonus -= [@atk.damage - base, 0].max
      end
      return if bonus <= 0
      @atk.damage += bonus
      @ui.message(_INTL("Holo Boost! +{1} damage!", bonus))
    end

    # Potion Plus: the holder's Potions heal 10 more (up to the damage there)
    POTION_CARDS = [:POTION, :SUPER_POTION, :POTION_NEO, :HYPER_POTION]

    alias more_play_trainer_card play_trainer_card unless method_defined?(:more_play_trainer_card)
    def play_trainer_card(idx)
      d = turn_duelist
      @potion_plus = ability?(@turn, :POTION) && POTION_CARDS.include?(d.card_id(idx))
      more_play_trainer_card(idx)
    ensure
      @potion_plus = false
    end

    alias more_heal_play_area_card_hp heal_play_area_card_hp unless method_defined?(:more_heal_play_area_card_hp)
    def heal_play_area_card_hp(e, n)
      if @potion_plus
        @potion_plus = false   # once per Potion
        n += [DuelAbilities::POTION_BONUS, card_damage_and_max_hp(turn_duelist, e)[0] - n].min.clamp(0, DuelAbilities::POTION_BONUS)
      end
      more_heal_play_area_card_hp(e, n)
    end
  end
end
