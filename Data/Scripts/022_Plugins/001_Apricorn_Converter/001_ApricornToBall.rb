# =============================================================================
# =====================  Apricorn Charm / Kurt Script =========================
# Adds a Kurt - The Apricorn Ball Crafter, now supporting multi-apricorn batches.
# Call with "apricornToBall"
# Essentials v21.1
# =============================================================================
class Player
  # Old fields kept for backward-compat; new system uses kurt_jobs
  attr_accessor :ball_for_apricorn
  attr_accessor :next_run
  attr_accessor :kurt_jobs   # Array of {ball: Symbol, qty: Integer, ready_at: Time}
end

class KurtEventPage
  MAX_KURT_WAIT = 7 * 24 * 3600  # hard cap: 1 week regardless of batch size

  # ==========  Messages for easy modification ========== #

  # Use Essentials' in-game clock (UnrealTime) if available
def now_time
  return pbGetTimeNow
end

  def greet
    pbMessage(_INTL("Hello! I'm Kurt!"))
    pbMessage(_INTL("I specialize in turning Apricorns into Poké Balls."))
    pbMessage(_INTL("Which Apricorns would you like me to convert?"))
  end

  def stillMaking(next_seconds)
    pbMessage(_INTL("Sorry, I'm still making your Poké Balls."))
    formatted_time_left = format_time(next_seconds)
    pbMessage(_INTL("Come back in {1}.", formatted_time_left))
  end

  def ballDone
    pbMessage(_INTL("I've been waiting for you."))
    pbMessage(_INTL("I've completed some of the Poké Balls you asked me to make."))
  end

  def nothingQueued
    pbMessage(_INTL("You don't have any conversions queued right now."))
  end

  def noThanks
    pbMessage(_INTL("No worries. Come back if you want me to convert more Apricorns."))
    return
  end
  # ==========  End Messages ========== #

  def initialize
    @@per_ball_hours = Settings::APRICORN_TO_BALL_TIME # hours per one Apricorn → one Ball
    $player.kurt_jobs ||= []
    # Back-compat cleanup: migrate old single-job fields if present
    if $player.ball_for_apricorn && $player.next_run
      $player.kurt_jobs << {
        ball: $player.ball_for_apricorn,
        qty: 1,
        ready_at: $player.next_run
      }
      $player.ball_for_apricorn = nil
      $player.next_run = nil
    end

    # Map all valid apricorns to their balls
    @conversion_hash = {
      :REDAPRICORN    => :LEVELBALL,
      :YELLOWAPRICORN => :MOONBALL,
      :BLUEAPRICORN   => :LUREBALL,
      :GREENAPRICORN  => :FRIENDBALL,
      :PINKAPRICORN   => :LOVEBALL,
      :WHITEAPRICORN  => :FASTBALL,
      :BLACKAPRICORN  => :HEAVYBALL,
      :PURPLEAPRICORN    => :RIFTBALL,
      # Short tags
      :YLWAPRICORN    => :MOONBALL,
      :BLUAPRICORN    => :LUREBALL,
      :GRNAPRICORN    => :FRIENDBALL,
      :PNKAPRICORN    => :LOVEBALL,
      :WHTAPRICORN    => :FASTBALL,
      :BLKAPRICORN    => :HEAVYBALL,
      :PRLAPRICORN    => :RIFTBALL
    }
  end

  def call
    now = now_time

    # 1) Hand over any completed jobs
    completed, pending = $player.kurt_jobs.partition { |job| job[:ready_at] <= now }
    if completed.any?
      ballDone
      give_completed_jobs(completed)
      # Keep only the still-pending ones
      $player.kurt_jobs = pending
    end

    # 2) If still have pending jobs, show time to the soonest ready and offer
    #    a Server Token instant-finish for the whole order
    if $player.kurt_jobs.any?
      next_ready = $player.kurt_jobs.min_by { |j| j[:ready_at] }
      seconds_left = (next_ready[:ready_at] - now).to_i
      stillMaking(seconds_left)
      offer_instant_finish
    end

    # 3) Queue more conversions
    if $player.kurt_jobs.empty?
    # No current jobs → start fresh with greeting
    greet
    queued_any = convert_apricorns_multi
    if queued_any
        pbMessage(_INTL("Got it. I'll get started right away!"))
        pbMessage(_INTL("I'll let you know when they're done."))
    else
        noThanks
    end
    else
    # Existing jobs → ask if they want to add more
    if pbConfirmMessage(_INTL("Would you like to queue more Apricorn conversions?"))
        greet
        queued_any = convert_apricorns_multi
        if queued_any
        pbMessage(_INTL("Got it. I'll add them to your queue!"))
        pbMessage(_INTL("I'll let you know when they're done."))
        else
        noThanks
        end
    end
  end
end

  private

  def give_completed_jobs(completed)
    # Combine same balls into a single grant for nicer popups
    totals = Hash.new(0)
    completed.each { |job| totals[job[:ball]] += job[:qty] }
    totals.each do |ball_sym, qty|
      pbReceiveItem(ball_sym, qty)
    end
  end

  # Lets the player pay Server Tokens to skip the wait on their whole current
  # queue at once, rather than per job — Kurt just finishes the lot early.
  # Only reachable online; NetworkTokens.buy_instant_kurt handles the actual
  # token cost confirmation and server round trip.
  def offer_instant_finish
    return unless NetworkAuth.logged_in?
    pbMessage(_INTL("...If you're in a hurry, I could finish the whole order right now for a fee."))
    return unless NetworkTokens.buy_instant_kurt
    ballDone
    give_completed_jobs($player.kurt_jobs)
    $player.kurt_jobs = []
  end

  def format_time(seconds)
    seconds = seconds.to_i
    hours, remainder = seconds.divmod(3600)
    minutes, seconds = remainder.divmod(60)
    parts = []
    parts << _INTL("{1} hour(s)", hours) if hours > 0
    parts << _INTL("{1} minute(s)", minutes) if minutes > 0
    parts << _INTL("{1} second(s)", seconds) if seconds > 0 || parts.empty?
    parts.join(" ")
  end

  # Let the player add multiple batches (different apricorns and quantities)
  def convert_apricorns_multi
    added_any = false
    loop do
      apricorn = ask_for_apricorn
      break if apricorn.nil?

      aprBall = @conversion_hash[apricorn]
      apricorn_data = GameData::Item.get(apricorn)
      aprBall_data  = GameData::Item.get(aprBall)

      max_qty = $bag.quantity(apricorn)
      if max_qty <= 0
        pbMessage(_INTL("You don't have any {1}.", apricorn_data.name))
        next
      end

    params = ChooseNumberParams.new
    params.setRange(1, max_qty)               # min..max allowed
    params.setDefaultValue([1, max_qty].min)  # initial value
    qty = pbMessageChooseNumber(
            _INTL("How many {1} to convert? (Max {2})", apricorn_data.name, max_qty),
            params
        )
    next if !qty || qty <= 0

      # Confirm
      if pbConfirmMessage(_INTL("Convert {1} × {2} into {3} × {2}?",
                                apricorn_data.name, qty, aprBall_data.name))
        # Remove apricorns
        if $bag.remove(apricorn, qty)
          # Schedule job — time scales by qty, hard cap at 1 week
          raw_seconds = @@per_ball_hours * 3600 * qty
          ready_at = now_time + [raw_seconds, MAX_KURT_WAIT].min
          $player.kurt_jobs << { ball: aprBall, qty: qty, ready_at: ready_at }
          pbMessage(_INTL("Okay. I'll turn {1} × {2} into {3} × {2}.",
                          apricorn_data.name, qty, aprBall_data.name))
          added_any = true
        else
          pbMessage(_INTL("Hmm, looks like you don't have enough {1}.", apricorn_data.name))
        end
      end

      break unless pbConfirmMessage(_INTL("Add another batch to the queue?"))
    end
    return added_any
  end

  # Uses your existing chooser pattern (variable 8) but returns a Symbol or nil
  def ask_for_apricorn
    pbChooseApricorn(8)
    return nil if pbGet(8) == :NONE
    apricorn = pbGet(8)
    unless @conversion_hash.has_key?(apricorn)
      pbMessage(_INTL("{1} can't be converted here.", GameData::Item.get(apricorn).name))
      return nil
    end
    return apricorn
  end
end

def apricornToBall
  apricorn_guy ||= KurtEventPage.new
  apricorn_guy.call
end
