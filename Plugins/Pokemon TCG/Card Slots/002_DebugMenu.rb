# Debug menu: play Card Slots for testing (no Coin Case needed)
MenuHandlers.add(:debug_menu, :card_slots, {
  "name"        => _INTL("Card Slots"),
  "parent"      => :main,
  "description" => _INTL("Play the Card Slots machine (20 Coins a spin)."),
  "always_show" => true,
  "effect"      => proc {
    pbFadeOutIn do
      scene = CardSlots::Scene.new
      begin
        scene.main
      ensure
        scene.dispose
      end
    end
  }
})
