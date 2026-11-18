#===============================================================================
# Kids Club PVP relay (server: ServerStuff/handlers/stadium_pvp.js).
#
# While Stadium runs, this passes its PVP events to the server and the party's state
# back (the port: Stadium-mod/port/src/pvp.cpp). Two files in <save folder>/Stadium/pvp:
#   pvp_out.txt  Stadium -> here, one per line:
#                  enter / start / level L / done ROUND WINS GAME / pick ROUND GAME / leave
#   pvp_in.txt   here -> Stadium (rewritten whole on every state):
#                  phase lobby|playing|over, host 1|0, seed N, target N, level L,
#                  round R, selector S (-1 none, 0 me, 1-3 a COM slot: another player or,
#                  after them, a real COM), pick G (-1 none),
#                  slot K WINS NAME (K = 1-3: the other players in join order)
# Offline, nothing answers and Stadium plays an ordinary Who's the Best.
# Everything sent and received is logged to relay_log.txt in the same folder.
#===============================================================================
module PokemonStadiumPVP
  @offset  = 0
  @entered = false
  @handler = nil
  @pending = nil      # pvp_in.txt contents not written yet (the file was busy)
  @party   = nil      # the server's party id (to rejoin after a reconnect)
  @wins    = 0        # my last reported wins / round (for a rejoin)
  @round   = 0
  @was_online = true
  @next_try   = 0     # when to try reconnecting
  @next_status = 0    # when to log the relay's status

  module_function

  def online?
    return defined?(NetworkAuth) && defined?(NetworkClient) && NetworkAuth.logged_in?
  end

  def dir
    d = File.join(PokemonStadium.base_dir, "pvp")
    Dir.mkdir(d) if !File.directory?(d)
    return d
  end

  # before Stadium starts: empty link files, listen for the party's state
  def start
    d = dir
    File.write(File.join(d, "pvp_out.txt"), "")
    File.delete(File.join(d, "pvp_in.txt")) if File.file?(File.join(d, "pvp_in.txt"))
    @offset  = 0
    @entered = false
    @pending = nil
    @party   = nil
    @wins = @round = 0
    @was_online = true
    @next_try = @next_status = 0
    File.write(File.join(d, "relay_log.txt"), "")
    log("start (online: #{online? ? 'yes' : 'no'})")
    if online? && !@handler
      @handler = NetworkClient.on("stadium_pvp_state") { |data| write_state(data) }
    end
    return d
  end

  # every frame while Stadium runs
  def log(text)
    File.open(File.join(dir, "relay_log.txt"), "a") { |f| f.puts("#{Time.now.strftime('%H:%M:%S.%L')} #{text}") }
  rescue StandardError
  end

  def tx(msg)
    NetworkClient.send_msg(msg)
    log("-> #{msg.inspect}")
  end

  # offline: reconnect (lines from Stadium wait in pvp_out.txt and go once back online)
  def reconnect
    now = Time.now.to_f
    if @was_online
      @was_online = false
      log("connection lost - reconnecting")
    end
    return false if now < @next_try
    @next_try = now + 5
    return false if !defined?(NetworkAuth) || !NetworkAuth.auto_connect(silent: true)
    log("reconnected")
    @was_online = true
    NetworkClient.remove("stadium_pvp_state", @handler) if @handler
    @handler = NetworkClient.on("stadium_pvp_state") { |data| write_state(data) }
    tx({ action: "stadium_pvp_rejoin", party: @party, wins: @wins, round: @round }) if @entered && @party
    return true
  rescue StandardError => e
    log("reconnect error: #{e.class}: #{e.message}")
    return false
  end

  def update
    now = Time.now.to_f
    if now >= @next_status
      @next_status = now + 10
      size = File.size(File.join(dir, "pvp_out.txt")) rescue -1
      log("status: online #{online? ? 'yes' : 'no'}, read #{@offset}/#{size}")
    end
    return if !online? && !reconnect
    @was_online = true
    NetworkClient.update
    flush_state
    path = File.join(dir, "pvp_out.txt")
    return if !File.file?(path) || File.size(path) <= @offset
    text = File.open(path, "rb") { |f| f.seek(@offset); f.read }
    last_nl = text.rindex("\n")
    return if !last_nl
    @offset += last_nl + 1
    text[0..last_nl].split("\n").each do |line|
      word, a, b, c = line.strip.split(" ")
      case word
      when "enter"
        @entered = true
        tx({ action: "stadium_pvp_enter" })
      when "start"
        tx({ action: "stadium_pvp_start" }) if @entered
      when "level"
        tx({ action: "stadium_pvp_level", level: a.to_i }) if @entered
      when "done"
        @round = a.to_i
        @wins  = b.to_i
        tx({ action: "stadium_pvp_done", round: a.to_i, wins: b.to_i, game: (c || -1).to_i }) if @entered
      when "pick"
        tx({ action: "stadium_pvp_pick", round: a.to_i, game: b.to_i }) if @entered
      when "leave"
        tx({ action: "stadium_pvp_leave" }) if @entered
        @entered = false
      end
    end
  end

  # after Stadium closed
  def finish
    tx({ action: "stadium_pvp_leave" }) if @entered && online?
    log("Stadium closed")
    @entered = false
    NetworkClient.remove("stadium_pvp_state", @handler) if @handler
    @handler = nil
  end

  def write_state(data)
    log("<- #{data.inspect}")
    @party = data["party"] if data["party"]
    me = NetworkAuth.username.to_s.downcase
    others = (data["players"] || []).reject { |p| p["name"].to_s.downcase == me }.first(3)
    selector = -1
    if data["selector"]
      sel = data["selector"].to_s.downcase
      if sel == "com"
        selector = [others.length + 1, 3].min       # the first real COM slot
      else
        selector = 0 if sel == me
        others.each_with_index { |p, i| selector = i + 1 if p["name"].to_s.downcase == sel }
      end
    end
    lines = ["phase #{data['phase']}",
             "host #{data['host'].to_s.downcase == me ? 1 : 0}",
             "seed #{data['seed'].to_i}", "target #{data['target'].to_i}", "level #{data['level'].to_i}",
             "round #{data['round'].to_i}", "selector #{selector}", "pick #{data['pick'].to_i}"]
    others.each_with_index do |p, i|
      name = p["name"].to_s.gsub(/[

]/, "")[0, 20]
      lines << "slot #{i + 1} #{p['wins'].to_i} #{name}"
    end
    @pending = lines.join("
") + "
"
    flush_state
  rescue StandardError => e
    log("state error: #{e.class}: #{e.message}")
  end

  # write pvp_in.txt whole (Stadium reads it often: if it's busy, try again next frame)
  def flush_state
    return if !@pending
    path = File.join(dir, "pvp_in.txt")
    File.write(path + ".tmp", @pending)
    File.delete(path) if File.file?(path)
    File.rename(path + ".tmp", path)
    @pending = nil
  rescue StandardError => e
    log("write retry: #{e.class}: #{e.message}")
  end
end
