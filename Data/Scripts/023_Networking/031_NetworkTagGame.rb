#===============================================================================
# NetworkTagGame — real-time multiplayer Tag minigame.
#
# NPC script (Ruby):  NetworkTagGame.show_npc_dialogue
#
# All game logic (roster, roles, timers, tag detection, scoring, prizes) is
# server-authoritative — see ServerStuff/handlers/tag.js. This file just:
#   - lets the player sign up via the NPC,
#   - reacts to server-pushed role changes (shows a small on-screen HUD,
#     and force-freezes the player for 3 seconds when they get tagged),
#   - shows the final result when the game ends.
#
# Map transfers (to the game map and to spawn points) reuse the existing
# generic 'teleport' event already handled by NetworkOverworld.tick — no new
# transfer code needed here.
#===============================================================================

module NetworkTagGame
  @active          = false
  @my_role         = nil
  @my_score        = 0
  @game_start_time = nil
  @game_seconds    = 600
  @timer_display   = nil
  @role_display    = nil

  def self.active?
    @active
  end

  #=============================================================================
  # NPC entry point
  #=============================================================================
  def self.show_npc_dialogue
    unless NetworkAuth.logged_in?
      pbMessage(_INTL("You need to be online to join a game of Tag."))
      return
    end

    return unless pbConfirmMessage(_INTL("\"Wanna play some Tag? We need at least 3 players, and a round runs for 10 minutes!\""))

    result = nil
    NetworkClient.on('tag_signup_result') { |d| result = d }
    NetworkClient.send_msg({ action: 'tag_signup' })
    300.times { Graphics.update; Input.update; NetworkClient.update; break if result }
    NetworkClient.off('tag_signup_result')

    if result.is_a?(Hash)
      pbMessage(result['message'] || (result['ok'] ? _INTL("You're signed up!") : _INTL("Couldn't sign you up.")))
    else
      pbMessage(_INTL("No response from the server. Try again in a moment."))
    end
  end

  #=============================================================================
  # HUD
  #=============================================================================
  def self._role_label(role, score)
    return _INTL("IT! ({1} pts)", score) if role == 'it'
    _INTL("RUN! ({1} pts)", score)
  end

  def self._update_role_text(text)
    return unless @role_display && !@role_display.disposed?
    @role_display.text = text
  end

  def self._start(game_seconds)
    @active          = true
    @game_start_time = System.uptime
    @game_seconds    = game_seconds.to_i
  end

  def self._stop
    @active   = false
    @my_role  = nil
    @my_score = 0
    @timer_display&.dispose unless @timer_display&.disposed?
    @role_display&.dispose  unless @role_display&.disposed?
    @timer_display = nil
    @role_display  = nil
  end

  # A small always-on-screen label showing the player's current Tag role and
  # score. Mirrors TimerDisplay's Window_AdvancedTextPokemon approach (see
  # 018_Alternate battle modes/002_BugContest.rb) but for role text instead
  # of a countdown.
  class RoleDisplay
    def initialize(text)
      @win = Window_AdvancedTextPokemon.newWithSize("", 0, 0, 120, 64)
      @win.z = 99999
      self.text = text
    end

    def text=(str)
      @win.text = _INTL("<ac>{1}", str)
    end

    def update; end

    def dispose
      @win.dispose
    end

    def disposed?
      @win.disposed?
    end
  end

  # Recreate the HUD (timer + role label) whenever the spriteset changes,
  # exactly like the Lake Fishing Contest's countdown timer.
  EventHandlers.add(:on_map_or_spriteset_change, :show_tag_hud,
    proc { |scene, _map_changed|
      next unless NetworkTagGame.active?
      @timer_display = TimerDisplay.new(@game_start_time, @game_seconds)
      @role_display  = RoleDisplay.new(NetworkTagGame._role_label(@my_role || 'not_it', @my_score))
      scene.spriteset.addUserSprite(@timer_display)
      scene.spriteset.addUserSprite(@role_display)
    }
  )

  # ── Server → client ────────────────────────────────────────────────────────
  NetworkClient.on('tag_role_update') do |d|
    role  = d['role']
    score = d['score'].to_i
    NetworkTagGame._start(d['game_seconds']) if d['game_seconds']
    @my_role  = role
    @my_score = score
    NetworkTagGame._update_role_text(NetworkTagGame._role_label(role, score))

    if d['was_tagged']
      # The Wait move command's parameter is in 1/20-second units, not real
      # frames (Game_Character#move_type_custom does `parameters[0] / 20.0`
      # and compares that against real elapsed seconds) — using
      # Graphics.frame_rate here would both mistime the freeze and, worse,
      # a default RPG::MoveRoute has repeat=true, which was the real cause
      # of the freeze never ending (it just looped the Wait forever).
      wait_units = ((d['frozen_seconds'] || 3).to_f * 20).round
      route = RPG::MoveRoute.new
      route.repeat = false
      route.list.push(RPG::MoveCommand.new(PBMoveRoute::WAIT, [wait_units]))
      route.list.push(RPG::MoveCommand.new(0))
      $game_player&.force_move_route(route)
    end
  end

  NetworkClient.on('tag_game_end') do |d|
    NetworkTagGame._stop
    if d['you_won']
      pbMessage(_INTL("Tag's over! You won with {1} points! A prize is waiting for you.", d['your_score']))
    else
      pbMessage(_INTL("Tag's over! You scored {1} points. {2} won with {3} points.",
                      d['your_score'], d['winner'], d['winner_score']))
    end
    NetworkAuction.show_prize_claim_dialog if NetworkAuth.logged_in?
  end
end
